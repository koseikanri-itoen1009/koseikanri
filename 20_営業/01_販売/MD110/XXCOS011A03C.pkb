CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS011A03C (body)
 * Description      : �[�i�\��f�[�^�̍쐬���s��
 * MD.050           : �[�i�\��f�[�^�쐬 (MD050_COS_011_A03)
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_param            �p�����[�^�`�F�b�N(A-1)
 *  init                   ��������(A-2)
 *  get_manual_order       ����̓f�[�^�o�^(A-3)
 *  output_header          �t�@�C����������(A-4)
 *  input_edi_order        EDI�󒍏�񒊏o(A-5)
 *  format_data            �f�[�^���`(A-7)
 *  edit_data              �f�[�^�ҏW(A-6)
 *  output_data            �t�@�C���o��(A-8)
 *  output_footer          �t�@�C���I������(A-9)
 *  update_edi_order       EDI�󒍏��X�V(A-10)
 *  generate_edi_trans     EDI�[�i�\�著�M�t�@�C���쐬(A-3...A-10)
 *  release_edi_trans      EDI�[�i�\�著�M�ς݉���(A-12)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   H.Fujimoto       �V�K�쐬
 *  2009/02/20    1.1   H.Fujimoto       �����s�No.106
 *  2009/02/24    1.2   H.Fujimoto       �����s�No.126,134
 *  2009/02/25    1.3   H.Fujimoto       �����s�No.135
 *  2009/02/25    1.4   H.Fujimoto       �����s�No.141
 *  2009/02/27    1.5   H.Fujimoto       �����s�No.146,149
 *  2009/03/04    1.6   H.Fujimoto       �����s�No.154
 *  2009/04/28    1.7   K.Kiriu          [T1_0756]���R�[�h���ύX�Ή�
 *  2009/05/12    1.8   K.Kiriu          [T1_0677]���x���쐬�Ή�
 *                                       [T1_0937]�폜���̌����J�E���g�Ή�
 *  2009/05/22    1.9   M.Sano           [T1_1073]�_�~�[�i�ڎ��̐��ʍ��ڕύX�Ή�
 *  2009/06/11    1.10  T.Kitajima       [T1_1348]�sNo�̌��������ύX
 *  2009/06/12    1.10  T.Kitajima       [T1_1350]���C���J�[�\���\�[�g�����ύX
 *  2009/06/12    1.10  T.Kitajima       [T1_1356]�t�@�C��No���ڋq�A�h�I��.EDI�`���ǔ�
 *  2009/06/12    1.10  T.Kitajima       [T1_1357]�`�[�ԍ����l�`�F�b�N
 *  2009/06/12    1.10  T.Kitajima       [T1_1358]��ԓ����敪0��00,1��01,2��02
 *  2009/06/19    1.10  T.Kitajima       [T1_1436]�󒍃f�[�^�A�c�ƒP�ʍi���ݒǉ�
 *  2009/06/24    1.10  T.Kitajima       [T1_1359]���ʊ��Z�Ή�
 *  2009/07/08    1.10  M.Sano           [T1_1357]���r���[�w�E�����Ή�
 *  2009/07/10    1.10  N.Maeda          [000063]���敪�ɂ��f�[�^�쐬�Ώۂ̐���ǉ�
 *                                       [000064]��DFF���ڒǉ��ɔ����A�A�g���ڒǉ�
 *  2009/07/13    1.10  N.Maeda          [T1_1359]���r���[�w�E�����Ή�
 *  2009/07/21    1.11  K.Kiriu          [0000644]�������z�̒[�������Ή�
 *  2009/07/24    1.11  K.Kiriu          [T1_1359]���r���[�w�E�����Ή�
 *  2009/08/10    1.11  K.Kiriu          [0000438]�w�E�����Ή�
 *  2009/09/03    1.12  N.Maeda          [0001065]�wXXCOS_HEAD_PROD_CLASS_V�x��MainSQL�捞
 *  2009/09/25    1.13  N.Maeda          [0001306]�`�[�v�W�v�P�ʏC��
 *                                       [0001307]�o�א��ʎ擾���e�[�u���C��
 *  2009/10/05    1.14  N.Maeda          [0001464]�󒍖��ו����ɂ��e���Ή�
 *  2010/03/01    1.15  S.Karikomi       [E_�{�ғ�_01635]�w�b�_�o�͋��_�C��
 *                                                       �����J�E���g�P�ʂ̓����Ή�
 *
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  global_data_check_expt    EXCEPTION;      -- �f�[�^�`�F�b�N���̃G���[
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�G���[
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  global_number_err_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_number_err_expt, -6502 );
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A03C'; -- �p�b�P�[�W��
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';        -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';            -- XXCCP:IF���R�[�h�敪_�w�b�_
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';              -- XXCCP:IF���R�[�h�敪_�f�[�^
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';            -- XXCCP:IF���R�[�h�敪_�t�b�^
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';     -- XXCOS:UTL_MAX�s�T�C�Y
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_OM_DIR';  -- XXCOS:EDI�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_prf_company_name   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME';         -- XXCOS:��Ж�
  cv_prf_company_kana   CONSTANT VARCHAR2(50)  := 'XXCOS1_COMPANY_NAME_KANA';    -- XXCOS:��Ж��J�i
  cv_prf_case_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';        -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prf_ball_uom_code  CONSTANT VARCHAR2(50)  := 'XXCOS1_BALL_UOM_CODE';        -- XXCOS:�{�[���P�ʃR�[�h
  cv_prf_organization   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';    -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_max_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';             -- XXCOS:MAX���t
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';            -- GL��v����ID
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                      -- MO:�c�ƒP��
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_item_div_h         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H'; -- XXCOS1:�{�А��i�敪
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- 2009/05/22 Ver1.9 Add Start
  cv_prf_dum_stock_out  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DUMMY_STOCK_OUT';  -- XXCOS:EDI�[�i�\��_�~�[���i�敪
-- 2009/05/22 Ver1.9 Add End
  -- ���b�Z�[�W�R�[�h
  cv_msg_param_null     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';  -- ���̓p�����[�^�s���G���[���b�Z�[�W
  cv_msg_date_reverse   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00005';  -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_mast_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IF�t�@�C�����C�A�E�g��`���擾�G���[���b�Z�[�W
  cv_msg_org_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_com_fnuc_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';  -- EDI���ʊ֐��G���[���b�Z�[�W
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_base_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00035';  -- ���_���擾�G���[���b�Z�[�W
  cv_msg_chain_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- �`�F�[���X���擾�G���[���b�Z�[�W
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_product_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12253';  -- ���i�R�[�h�G���[���b�Z�[�W
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- �o�͏��ҏW�G���[���b�Z�[�W
  cv_msg_data_upd_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_param1         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12251';  -- �p�����[�^�o�͂P���b�Z�[�W
  cv_msg_param2         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12264';  -- �p�����[�^�o�͂P���b�Z�[�W
  cv_msg_param3         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12252';  -- �p�����[�^�o�͂Q���b�Z�[�W
  -- ���b�Z�[�W�p������
  cv_msg_tkn_param1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12254';  -- �쐬�敪
  cv_msg_tkn_param2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12255';  -- EDI�`�F�[���X�R�[�h
  cv_msg_tkn_param3     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00109';  -- �t�@�C����
  cv_msg_tkn_param4     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12256';  -- EDI�`���ǔ�(�t�@�C�����p)
  cv_msg_tkn_param5     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12257';  -- �X�ܔ[�i��From
  cv_msg_tkn_param6     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12258';  -- �X�ܔ[�i��To
  cv_msg_tkn_param7     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12259';  -- ������
  cv_msg_tkn_param8     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12260';  -- ��������
  cv_msg_tkn_param9     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12262';  -- �Z���^�[�[�i��
  cv_msg_tkn_prf1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- XXCCP:IF���R�[�h�敪_�w�b�_
  cv_msg_tkn_prf2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- XXCCP:IF���R�[�h�敪_�f�[�^
  cv_msg_tkn_prf3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- XXCCP:IF���R�[�h�敪_�t�b�^
  cv_msg_tkn_prf4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00099';  -- XXCOS:UTL_MAX�s�T�C�Y
  cv_msg_tkn_prf5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00145';  -- XXCOS:EDI�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X
  cv_msg_tkn_prf6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00058';  -- XXCOS:��Ж�
  cv_msg_tkn_prf7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00098';  -- XXCOS:��Ж��J�i
  cv_msg_tkn_prf8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';  -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_msg_tkn_prf9       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00059';  -- XXCOS:�{�[���P�ʃR�[�h
  cv_msg_tkn_prf10      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_msg_tkn_prf11      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX���t
  cv_msg_tkn_prf12      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';  -- GL��v����ID
  cv_msg_tkn_prf13      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- �c�ƒP��
-- 2009/05/22 Ver1.9 Add Start
  cv_msg_tkn_prf14      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12266';  -- XXCOS:EDI�[�i�\��_�~�[���i�敪
-- 2009/05/22 Ver1.9 Add End
  cv_msg_tkn_column1    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12261';  -- �f�[�^��R�[�h
  cv_msg_l_meaning2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12263';  -- �N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
  cv_msg_tkn_column2    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- EDI�}�̋敪
  cv_msg_tkn_tbl1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- �N�C�b�N�R�[�h
  cv_msg_tkn_tbl2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';  -- EDI�w�b�_���e�[�u��
  cv_msg_tkn_tbl3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00115';  -- EDI���׏��e�[�u��
  cv_msg_tkn_layout     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';  -- �󒍌n���ڃ��C�A�E�g
  cv_msg_file_nmae      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- �t�@�C�����o��
/* 2009/05/12 Ver1.8 Add Start */
  cv_msg_tkn_param10    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12265';  -- EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Add End   */
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
  cv_msg_slip_no_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12267';  -- �`�[�ԍ����l�G���[
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  cv_msg_category_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --�J�e�S���Z�b�gID�擾�G���[���b�Z�[�W
  cv_msg_item_div_h     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --�{�Џ��i�敪
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_get_order_source_id_err CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12268';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
  -- �g�[�N���R�[�h
  cv_tkn_in_param       CONSTANT VARCHAR2(8)   := 'IN_PARAM';          -- ���̓p�����[�^��
  cv_tkn_date_from      CONSTANT VARCHAR2(9)   := 'DATE_FROM';         -- ���t���ԃ`�F�b�N�̊J�n��
  cv_tkn_date_to        CONSTANT VARCHAR2(7)   := 'DATE_TO';           -- ���t���ԃ`�F�b�N�̏I����
  cv_tkn_profile        CONSTANT VARCHAR2(7)   := 'PROFILE';           -- �v���t�@�C����
  cv_tkn_column         CONSTANT VARCHAR2(6)   := 'COLMUN';            -- ���ږ�
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';             -- �e�[�u�����i�_�����j
  cv_tkn_layout         CONSTANT VARCHAR2(6)   := 'LAYOUT';            -- �t�@�C����`���C�A�E�g��
  cv_tkn_org_code       CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';      -- �݌ɑg�D�R�[�h
  cv_tkn_err_msg        CONSTANT VARCHAR2(6)   := 'ERRMSG';            -- ���ʊ֐��̃G���[���b�Z�[�W
  cv_tkn_file_name      CONSTANT VARCHAR2(9)   := 'FILE_NAME';         -- �[�i�\��t�@�C����
  cv_tkn_code           CONSTANT VARCHAR2(4)   := 'CODE';              -- ���_�R�[�h
  cv_tkn_chain_code     CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';   -- �`�F�[���X�R�[�h
  cv_tkn_item_code      CONSTANT VARCHAR2(9)   := 'ITEM_CODE';         -- �i�ڃR�[�h
  cv_tkn_table_name     CONSTANT VARCHAR2(10)  := 'TABLE_NAME';        -- �e�[�u�����i�_�����j
  cv_tkn_key_data       CONSTANT VARCHAR2(8)   := 'KEY_DATA';          -- �L�[���
  cv_tkn_count          CONSTANT VARCHAR2(5)   := 'COUNT';             -- �Ώی���
  cv_tkn_param01        CONSTANT VARCHAR2(7)   := 'PARAME1';           -- ���̓p�����[�^�l
  cv_tkn_param02        CONSTANT VARCHAR2(7)   := 'PARAME2';           -- ���̓p�����[�^�l
  cv_tkn_param03        CONSTANT VARCHAR2(7)   := 'PARAME3';           -- ���̓p�����[�^�l
  cv_tkn_param04        CONSTANT VARCHAR2(7)   := 'PARAME4';           -- ���̓p�����[�^�l
  cv_tkn_param05        CONSTANT VARCHAR2(7)   := 'PARAME5';           -- ���̓p�����[�^�l
  cv_tkn_param06        CONSTANT VARCHAR2(7)   := 'PARAME6';           -- ���̓p�����[�^�l
  cv_tkn_param07        CONSTANT VARCHAR2(7)   := 'PARAME7';           -- ���̓p�����[�^�l
  cv_tkn_param08        CONSTANT VARCHAR2(7)   := 'PARAME8';           -- ���̓p�����[�^�l
  cv_tkn_param09        CONSTANT VARCHAR2(7)   := 'PARAME9';           -- ���̓p�����[�^�l
  cv_tkn_param10        CONSTANT VARCHAR2(8)   := 'PARAME10';          -- ���̓p�����[�^�l
  cv_tkn_param11        CONSTANT VARCHAR2(8)   := 'PARAME11';          -- ���̓p�����[�^�l
/* 2009/05/12 Ver1.8 Add Start */
  cv_tkn_param12        CONSTANT VARCHAR2(8)   := 'PARAME12';          -- ���̓p�����[�^�l
/* 2009/05/12 Ver1.8 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_order_source            CONSTANT VARCHAR2(20) := 'ORDER_SOURCE';
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
  -- ���t
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            -- �V�X�e�����t
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; -- �Ɩ�������
  -- �f�[�^�擾/�ҏW�p�Œ�l
  cv_cust_code_base     CONSTANT VARCHAR2(1)   := '1';                 -- �ڋq�敪:���_
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                -- �ڋq�敪:�ڋq
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- �ڋq�敪:�`�F�[���X
  cv_cust_status_30     CONSTANT VARCHAR2(2)   := '30';                -- �ڋq�X�e�[�^�X:���F��
  cv_cust_status_40     CONSTANT VARCHAR2(2)   := '40';                -- �ڋq�X�e�[�^�X:�ڋq
  cv_cust_status_90     CONSTANT VARCHAR2(2)   := '90';                -- �ڋq�X�e�[�^�X:���~���ٍ�
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- �X�e�[�^�X:�ڋq�L��
  cv_tukzik_div_tuk     CONSTANT VARCHAR2(2)   := '11';                -- �ʉߍ݌Ɍ^�敪:�Z���^�[�[�i(�ʉߌ^�E��)
  cv_tukzik_div_zik     CONSTANT VARCHAR2(2)   := '12';                -- �ʉߍ݌Ɍ^�敪:�Z���^�[�[�i(�݌Ɍ^�E��)
  cv_tukzik_div_tnp     CONSTANT VARCHAR2(2)   := '24';                -- �ʉߍ݌Ɍ^�敪:�X�ܔ[�i
  cv_data_type_edi      CONSTANT VARCHAR2(2)   := '11';                -- �f�[�^��R�[�h:��EDI
  cv_medium_class_edi   CONSTANT VARCHAR2(2)   := '00';                -- �}�̋敪:EDI
  cv_medium_class_mnl   CONSTANT VARCHAR2(2)   := '01';                -- �}�̋敪:�����
  cv_position           CONSTANT VARCHAR2(3)   := '002';               -- �E��:�x�X��
  cv_stockout_class_00  CONSTANT VARCHAR2(2)   := '00';                -- ���i�敪:���i�Ȃ�
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--  cv_sale_class_all     CONSTANT VARCHAR2(1)   := '0';                 -- ��ԓ����敪:����
  cv_sale_class_all     CONSTANT VARCHAR2(2)   := '00';                -- ��ԓ����敪:����
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
  cv_entity_code_line   CONSTANT VARCHAR2(4)   := 'LINE';              -- �G���e�B�e�B�R�[�h:LINE
  cv_reason_type        CONSTANT VARCHAR2(11)  := 'CANCEL_CODE';       -- ���R�^�C�v:���
  cv_err_reason_code    CONSTANT VARCHAR2(2)   := 'XX';                -- �G���[������R
  -- �N�C�b�N�R�[�h�^�C�v
  cv_edi_shipping_exp_t CONSTANT VARCHAR2(28)  := 'XXCOS1_EDI_SHIPPING_EXP_TYPE';  -- �쐬�敪
  cv_edi_media_class_t  CONSTANT VARCHAR2(22)  := 'XXCOS1_EDI_MEDIA_CLASS';        -- EDI�}�̋敪
  cv_data_type_code_t   CONSTANT VARCHAR2(21)  := 'XXCOS1_DATA_TYPE_CODE';         -- �f�[�^��
  cv_edi_item_err_t     CONSTANT VARCHAR2(24)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';      -- EDI�i�ڃG���[�^�C�v
  cv_edi_create_class   CONSTANT VARCHAR2(23)  := 'XXCOS1_EDI_CREATE_CLASS';       -- EDI�쐬���敪
  -- �N�C�b�N�R�[�h
  cv_data_type_code_c   CONSTANT VARCHAR2(3)   := '040';               -- �f�[�^��(�[�i�\��)
/* 2009/05/12 Ver1.8 Del Start */
/* 2009/02/27 Ver1.5 Add Start */
--  cv_data_type_code_l   CONSTANT VARCHAR2(3)   := '200';               -- �f�[�^��(�[�i�\��(���x��))
/* 2009/02/27 Ver1.5 Add  End  */
/* 2009/05/12 Ver1.8 Del  End  */
  cv_edi_create_class_c CONSTANT VARCHAR2(2)   := '10';                -- EDI�쐬���敪(��)
  -- �쐬�敪
  cv_make_class_transe  CONSTANT VARCHAR2(1)   := '1';                 -- ���M
  cv_make_class_label   CONSTANT VARCHAR2(1)   := '2';                 -- ���x���쐬
  cv_make_class_release CONSTANT VARCHAR2(1)   := '9';                 -- ����
  -- ���̑��Œ�l
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g(��)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';          -- ���t�t�H�[�}�b�g(����)
  cv_max_date_format    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- MAX���t�t�H�[�}�b�g
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- �Œ�l:0(VARCHAR2)
  cn_0                  CONSTANT NUMBER        := 0;                   -- �Œ�l:0(NUMBER)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- �Œ�l:1(VARCHAR2)
  cn_1                  CONSTANT NUMBER        := 1;                   -- �Œ�l:1(NUMBER)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- �Œ�l:2
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- �Œ�l:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- �Œ�l:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- �Œ�l:W
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := USERENV('LANG'); --LANG
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
  -- �f�[�^�ҏW���ʊ֐��p
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  -- �}�̋敪
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                -- �f�[�^��R�[�h
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       -- �t�@�C��No
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    -- ���敪
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  -- ������
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  -- ��������
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     -- ���_(����)�R�[�h
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     -- ���_��(������)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 -- ���_��(�J�i)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                -- EDI�`�F�[���X�R�[�h
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                -- EDI�`�F�[���X��(����)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            -- EDI�`�F�[���X��(�J�i)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    -- �`�F�[���X�R�[�h
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    -- �`�F�[���X��(����)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                -- �`�F�[���X��(�J�i)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   -- ���[�R�[�h
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              -- ���[�\����
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 -- �ڋq�R�[�h
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 -- �ڋq��(����)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             -- �ڋq��(�J�i)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  -- �ЃR�[�h
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  -- �Ж�(����)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              -- �Ж�(�J�i)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     -- �X�R�[�h
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     -- �X��(����)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 -- �X��(�J�i)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          -- �[���Z���^�[�R�[�h
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          -- �[���Z���^�[��(����)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      -- �[����Z���^�[��(�J�i)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    -- ������
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          -- �Z���^�[�[�i��
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          -- ���[�i��
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            -- �X�ܔ[�i��
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   -- �f�[�^�쐬��(EDI�f�[�^��)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   -- �f�[�^�쐬����(EDI�f�[�^��)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 -- �`�[�敪
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     -- �����ރR�[�h
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     -- �����ޖ�
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    -- �����ރR�[�h
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    -- �����ޖ�
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       -- �啪�ރR�[�h
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       -- �啪�ޖ�
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   -- ����敔��R�[�h
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      -- ����攭���ԍ�
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             -- �`�F�b�N�f�W�b�g�L���敪
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                -- �`�[�ԍ�
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   -- �`�F�b�N�f�W�b�g
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    -- ����
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  -- ��No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 -- �����敪
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               -- �z���敪
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                -- ��No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    -- �A����
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   -- ���[�g�Z�[���X
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                -- �@�l�R�[�h
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    -- ���[�J�[��
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     -- �n��R�[�h
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     -- �n�於(����)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 -- �n�於(�J�i)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   -- �����R�[�h
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   -- ����於(����)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              -- ����於1(�J�i)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              -- ����於2(�J�i)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    -- �����TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 -- �����S����
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                -- �����Z��(����)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        -- �͂���R�[�h(�ɓ���)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         -- �͂���R�[�h(�`�F�[���X)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    -- �͂���(����)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               -- �͂���1(�J�i)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               -- �͂���2(�J�i)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            -- �͂���Z��(����)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        -- �͂���Z��(�J�i)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                -- �͂���TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         -- ������R�[�h
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; -- ������ЃR�[�h
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    -- ������X�R�[�h
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         -- �����於(����)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     -- �����於(�J�i)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      -- ������Z��(����)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  -- ������Z��(�J�i)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          -- ������TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           -- �󒍉\��
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      -- ���e�\��
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 -- ����N����
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       -- �x�����ϓ�
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    -- �`���V�J�n��
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              -- ��������
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 -- �o�׎���
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        -- �[�i�\�莞��
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    -- ��������
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            -- �ėp���t����1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            -- �ėp���t����2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            -- �ėp���t����3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            -- �ėp���t����4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            -- �ėp���t����5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        -- ���o�׋敪
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  -- �����敪
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        -- �`�[����敪
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          -- �P���g�p�敪
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  -- �T�u�����Z���^�[�R�[�h
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  -- �T�u�����Z���^�[�R�[�h��
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        -- �Z���^�[�[�i���@
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              -- �Z���^�[���p�敪
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             -- �Z���^�[�q�ɋ敪
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             -- �Z���^�[�n��敪
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          -- �Z���^�[���׋敪
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   -- �f�|�敪
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    -- TCDC�敪
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      -- UPC�t���O
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          -- ��ċ敪
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   -- �Ɩ�ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           -- �q���敪
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          -- ���ڎ��
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     -- �i�i���ߋ敪
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        -- �߉ƐH�敪
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     -- ���݋敪
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     -- �݌ɋ敪
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        -- �ŏI�C���ꏊ�敪
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  -- ���[�敪
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           -- �ǉ��E�v��敪
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            -- �o�^�敪
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                -- ����敪
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                -- ����敪
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   -- �����敪
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                -- �W�v���׋敪
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       -- �o�׈ē��ȊO�敪
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                -- �o�׋敪
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        -- ���i�R�[�h�g�p�敪
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              -- �ϑ��i�敪
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      -- T�^A�敪
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     -- ��溰��
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 -- �J�e�S���[�R�[�h
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                -- �J�e�S���[�敪
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 -- �^����i
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  -- ����R�[�h
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     -- �ړ��T�C��
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         -- EOS�E�菑�敪
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      -- �[�i��ۃR�[�h
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              -- �`�[����
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    -- �Y�t��
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             -- �t���A
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       -- TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 -- �C���X�g�A�R�[�h
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      -- �^�O
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              -- ����
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 -- ��������
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              -- �`�F�[���X�g�A�[�R�[�h
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        -- ���ݽı����ޗ�������
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      -- ���z���^���旿
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     -- ��`���
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   -- �E�v1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 -- �����R�[�h
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  -- ������� �[�i�J�e�S���[
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 -- �d���`��
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          -- �[�i�ꏊ��(�J�i)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              -- �X�o�ꏊ
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  -- ���ꖼ
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              -- �����ԍ�
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   -- �S���Җ�
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     -- �l�D
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      -- �Ŏ�
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         -- ����ŋ敪
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   -- BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       -- ID�R�[�h
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               -- �S�ݓX�R�[�h
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               -- �S�ݓX��
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              -- �i�ʔԍ�
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        -- �E�v2
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              -- �l�D���@
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 -- ���R��
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               -- A���w�b�_
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               -- D���w�b�_
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    -- �u�����h�R�[�h
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     -- ���C���R�[�h
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    -- �N���X�R�[�h
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     -- A�|1��
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     -- B�|1��
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     -- C�|1��
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     -- D�|1��
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     -- E�|1��
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     -- A�|2��
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     -- B�|2��
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     -- C�|2��
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     -- D�|2��
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     -- E�|2��
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     -- A�|3��
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     -- B�|3��
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     -- C�|3��
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     -- D�|3��
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     -- E�|3��
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     -- F�|1��
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     -- G�|1��
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     -- H�|1��
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     -- I�|1��
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     -- J�|1��
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     -- K�|1��
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     -- L�|1��
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     -- F�|2��
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     -- G�|2��
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     -- H�|2��
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     -- I�|2��
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     -- J�|2��
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     -- K�|2��
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     -- L�|2��
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     -- F�|3��
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     -- G�|3��
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     -- H�|3��
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     -- I�|3��
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     -- J�|3��
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     -- K�|3��
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     -- L�|3��
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    -- �`�F�[���X�ŗL�G���A(�w�b�_)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       -- �󒍊֘A�ԍ�(��)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       -- �sNo
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                -- ���i�敪
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               -- ���i���R
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           -- ���i�R�[�h(�ɓ���)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 -- ���i�R�[�h1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 -- ���i�R�[�h2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      -- JAN�R�[�h
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      -- ITF�R�[�h
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            -- ����ITF�R�[�h
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             -- �P�[�X���i�R�[�h
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             -- �{�[�����i�R�[�h
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        -- ���i�R�[�h�i��
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    -- ���i�敪
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  -- ���i��(����)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             -- ���i��1(�J�i)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             -- ���i��2(�J�i)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                -- �K�i1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                -- �K�i2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   -- ����
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  -- �P�[�X����
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   -- �{�[������
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    -- �F
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     -- �T�C�Y
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               -- �ܖ�������
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  -- ������
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 -- �����P�ʐ�
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              -- �o�גP�ʐ�
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               -- ����P�ʐ�
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     -- ����
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    -- �����敪
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                -- �ƍ�
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      -- �P��
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              -- �P���敪
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         -- �e����ԍ�
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                -- ����ԍ�
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            -- ���i�Q�R�[�h
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           -- �P�[�X��̕s�t���O
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    -- �P�[�X�敪
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                -- ��������(�o��)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                -- ��������(�P�[�X)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                -- ��������(�{�[��)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 -- ��������(���v�A�o��)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             -- �o�א���(�o��)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             -- �o�א���(�P�[�X)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             -- �o�א���(�{�[��)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           -- �o�א���(�p���b�g)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              -- �o�א���(���v�A�o��)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             -- ���i����(�o��)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             -- ���i����(�P�[�X)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             -- ���i����(�{�[��)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              -- ���i����(���v�A�o��)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      -- �P�[�X����
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       -- �I���R��(�o��)����
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              -- ���P��(����)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           -- ���P��(�o��)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                -- �������z(����)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             -- �������z(�o��)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             -- �������z(���i)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 -- ���P��
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               -- �������z(����)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            -- �������z(�o��)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            -- �������z(���i)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           -- A��(�S�ݓX)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           -- D��(�S�ݓX)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           -- �K�i���E���s��
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          -- �K�i���E����
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           -- �K�i���E��
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          -- �K�i���E�d��
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       -- �ėp���p������1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       -- �ėp���p������2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       -- �ėp���p������3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       -- �ėp���p������4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       -- �ėp���p������5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       -- �ėp���p������6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       -- �ėp���p������7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       -- �ėp���p������8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       -- �ėp���p������9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      -- �ėp���p������10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             -- �ėp�t������1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             -- �ėp�t������2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             -- �ėp�t������3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             -- �ėp�t������4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             -- �ėp�t������5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             -- �ėp�t������6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             -- �ėp�t������7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             -- �ėp�t������8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             -- �ėp�t������9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            -- �ėp�t������10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      -- �`�F�[���X�ŗL�G���A(����)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        -- (�`�[�v)��������(�o��)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        -- (�`�[�v)��������(�P�[�X)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        -- (�`�[�v)��������(�{�[��)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         -- (�`�[�v)��������(���v�A�o��)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     -- (�`�[�v)�o�א���(�o��)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     -- (�`�[�v)�o�א���(�P�[�X)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     -- (�`�[�v)�o�א���(�{�[��)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   -- (�`�[�v)�o�א���(�p���b�g)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      -- (�`�[�v)�o�א���(���v�A�o��)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     -- (�`�[�v)���i����(�o��)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     -- (�`�[�v)���i����(�P�[�X)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     -- (�`�[�v)���i����(�{�[��)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      -- (�`�[�v)���i����(���v�A�o��)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              -- (�`�[�v)�P�[�X����
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    -- (�`�[�v)�I���R��(�o��)����
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        -- (�`�[�v)�������z(����)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     -- (�`�[�v)�������z(�o��)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     -- (�`�[�v)�������z(���i)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       -- (�`�[�v)�������z(����)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    -- (�`�[�v)�������z(�o��)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    -- (�`�[�v)�������z(���i)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          -- (�����v)��������(�o��)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          -- (�����v)��������(�P�[�X)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          -- (�����v)��������(�{�[��)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           -- (�����v)��������(���v�A�o��)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       -- (�����v)�o�א���(�o��)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       -- (�����v)�o�א���(�P�[�X)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       -- (�����v)�o�א���(�{�[��)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     -- (�����v)�o�א���(�p���b�g)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        -- (�����v)�o�א���(���v�A�o��)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       -- (�����v)���i����(�o��)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       -- (�����v)���i����(�P�[�X)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       -- (�����v)���i����(�{�[��)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        -- (�����v)���i����(���v�A�o��)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                -- (�����v)�P�[�X����
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      -- (�����v)�I���R��(�o��)����
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          -- (�����v)�������z(����)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       -- (�����v)�������z(�o��)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       -- (�����v)�������z(���i)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         -- (�����v)�������z(����)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      -- (�����v)�������z(�o��)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      -- (�����v)�������z(���i)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                -- �g�[�^���s��
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             -- �g�[�^���`�[����
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    -- �`�F�[���X�ŗL�G���A(�t�b�^)
/* 2009/04/28 Ver1.7 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     -- �\���G���A
/* 2009/04/28 Ver1.7 Add End   */
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
  cv_online                   CONSTANT VARCHAR2(50)  := 'Online';                        -- �󒍃\�[�X(ONLINE)
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gt_f_handle           UTL_FILE.FILE_TYPE;                            -- �t�@�C���n���h��
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;       -- �t�@�C�����C�A�E�g
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���o�͍��ڗp
  gv_f_o_date           CHAR(8);                                       -- ������
  gv_f_o_time           CHAR(6);                                       -- ��������
  gn_organization_id    NUMBER;                                        -- �݌ɑg�DID
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;                -- �ŗ�
  gt_edi_media_class    fnd_lookup_values_vl.lookup_code%TYPE;         -- EDI�}�̋敪
  gt_data_type_code     fnd_lookup_values_vl.lookup_code%TYPE;         -- �f�[�^��R�[�h
  -- �e�[�u���J�E���^
  gn_dat_rec_cnt        NUMBER;                                        -- �o�̓f�[�^�p
  gn_head_cnt           NUMBER;                                        -- EDI�w�b�_���p
  gn_line_cnt           NUMBER;                                        -- EDI���׏��p
  -- ��������A���ʊ֐��p
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    -- EDI�A�g�i�ڃR�[�h�敪
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         -- �ڋqID(�`�F�[���X)
  gt_from_series        fnd_lookup_values_vl.attribute1%TYPE;          -- IF���Ɩ��n��R�[�h
  gt_edi_c_code         xxcos_edi_headers.edi_chain_code%TYPE;         -- EDI�`�F�[���X�R�[�h
  gt_edi_f_number       xxcmm_cust_accounts.edi_forward_number%TYPE;   -- EDI�`���ǔ�
  gt_shop_date_from     xxcos_edi_headers.shop_delivery_date%TYPE;     -- �X�ܔ[�i��From
  gt_shop_date_to       xxcos_edi_headers.shop_delivery_date%TYPE;     -- �X�ܔ[�i��To
  gt_sale_class         xxcos_edi_headers.ar_sale_class%TYPE;          -- ��ԓ����敪
  gt_area_code          xxcmm_cust_accounts.edi_district_code%TYPE;    -- �n��R�[�h
  -- �v���t�@�C���l
  gv_if_header          VARCHAR2(2);                                   -- �w�b�_���R�[�h�敪
  gv_if_data            VARCHAR2(2);                                   -- �f�[�^���R�[�h�敪
  gv_if_footer          VARCHAR2(2);                                   -- �t�b�^���R�[�h�敪
  gv_utl_m_line         VARCHAR2(100);                                 -- UTL_MAX�s�T�C�Y
  gv_outbound_d         VARCHAR2(100);                                 -- �A�E�g�o�E���h�p�f�B���N�g���p�X
  gv_company_name       VARCHAR2(100);                                 -- ��Ж�
  gv_company_kana       VARCHAR2(100);                                 -- ��Ж��J�i
  gv_case_uom_code      VARCHAR2(3);                                   -- �P�[�X�P�ʃR�[�h
  gv_ball_uom_code      VARCHAR2(3);                                   -- �{�[���P�ʃR�[�h
  gv_organization       VARCHAR2(3);                                   -- �݌ɑg�D�R�[�h
  gd_max_date           DATE;                                          -- MAX���t
  gn_bks_id             NUMBER;                                        -- ��v����ID
  gn_org_id             NUMBER;                                        -- �c�ƒP��
-- 2009/05/22 Ver1.9 Add Start
  gn_dum_stock_out      VARCHAR2(3);                                   -- EDI�[�i�\��_�~�[���i�敪
-- 2009/05/22 Ver1.9 Add End
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
   gt_category_set_id      mtl_category_sets_tl.category_set_id%TYPE;          --�J�e�S���Z�b�gID
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    gt_order_source_online oe_order_sources.order_source_id%TYPE;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\���錾
  -- ===============================
  -- EDI�󒍃f�[�^
  CURSOR edi_order_cur
  IS
    SELECT 
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
           /*+ USE_NL(XEH) */
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
           xeh.edi_header_info_id               edi_header_info_id             -- EDI�w�b�_���.EDI�w�b�_���ID
          ,xeh.medium_class                     medium_class                   -- EDI�w�b�_���.�}�̋敪
          ,xeh.data_type_code                   data_type_code                 -- EDI�w�b�_���.�f�[�^��R�[�h
          ,xeh.file_no                          file_no                        -- EDI�w�b�_���.�t�@�C��No
          ,xeh.info_class                       info_class                     -- EDI�w�b�_���.���敪
          ,xca3.delivery_base_code              delivery_base_code             -- �ڋq�}�X�^.�[�i���_�R�[�h
          ,hp1.party_name                       base_name                      -- ���_�}�X�^.�ڋq����
          ,hp1.organization_name_phonetic       base_name_phonetic             -- ���_�}�X�^.�ڋq����(�J�i)
          ,xeh.edi_chain_code                   edi_chain_code                 -- EDI�w�b�_���.�d�c�h�`�F�[���X�R�[�h
          ,hp2.party_name                       edi_chain_name                 -- �`�F�[���X�}�X�^.�ڋq����
          ,xeh.edi_chain_name_alt               edi_chain_name_alt             -- EDI�w�b�_���.�d�c�h�`�F�[���X��(�J�i)
          ,hp2.organization_name_phonetic       edi_chain_name_phonetic        -- �`�F�[���X�}�X�^.�ڋq����(�J�i)
          ,xca3.chain_store_code                edi_chain_store_code           -- �ڋq�}�X�^.�`�F�[���X�R�[�h(EDI)
          ,hca3.account_number                  account_number                 -- �ڋq�}�X�^.�ڋq�R�[�h
          ,hp3.party_name                       customer_name                  -- �ڋq�}�X�^.�ڋq����
          ,hp3.organization_name_phonetic       customer_name_phonetic         -- �ڋq�}�X�^.�ڋq����(�J�i)
          ,xeh.company_code                     company_code                   -- EDI�w�b�_���.�ЃR�[�h
          ,xeh.company_name                     company_name                   -- EDI�w�b�_���.�Ж�(����)
          ,xeh.company_name_alt                 company_name_alt               -- EDI�w�b�_���.�Ж�(�J�i)
          ,xeh.shop_code                        shop_code                      -- EDI�w�b�_���.�X�R�[�h
          ,xca3.cust_store_name                 cust_store_name                -- �ڋq�}�X�^.�ڋq�X�ܖ���
          ,xeh.shop_name_alt                    shop_name_alt                  -- EDI�w�b�_���.�X��(�J�i)
          ,hp3.organization_name_phonetic       shop_name_phonetic             -- �ڋq�}�X�^.�ڋq����(�J�i)
          ,xeh.delivery_center_code             delivery_center_code           -- EDI�w�b�_���.�[���Z���^�[�R�[�h
          ,xeh.delivery_center_name             delivery_center_name           -- EDI�w�b�_���.�[���Z���^�[��(����)
          ,xeh.delivery_center_name_alt         delivery_center_name_alt       -- EDI�w�b�_���.�[���Z���^�[��(�J�i)
          ,xeh.order_date                       order_date                     -- EDI�w�b�_���.������
          ,xeh.center_delivery_date             center_delivery_date           -- EDI�w�b�_���.�Z���^�[�[�i��
          ,xeh.result_delivery_date             result_delivery_date           -- EDI�w�b�_���.���[�i��
          ,xeh.shop_delivery_date               shop_delivery_date             -- EDI�w�b�_���.�X�ܔ[�i��
          ,xeh.data_creation_date_edi_data      data_creation_date_edi_data    -- EDI�w�b�_���.�f�[�^�쐬��(�d�c�h�f�[�^��)
          ,xeh.data_creation_time_edi_data      data_creation_time_edi_data    -- EDI�w�b�_���.�f�[�^�쐬����(�d�c�h�f�[�^��)
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute5,xeh.invoice_class) invoice_class                  -- EDI�w�b�_���.�`�[�敪
--          ,xeh.invoice_class                    invoice_class                  -- EDI�w�b�_���.�`�[�敪
-- ****************************** 2009/07/10 1.10 N.Maeda   MOD  END  *****************************--
          ,xeh.small_classification_code        small_classification_code      -- EDI�w�b�_���.�����ރR�[�h
          ,xeh.small_classification_name        small_classification_name      -- EDI�w�b�_���.�����ޖ�
          ,xeh.middle_classification_code       middle_classification_code     -- EDI�w�b�_���.�����ރR�[�h
          ,xeh.middle_classification_name       middle_classification_name     -- EDI�w�b�_���.�����ޖ�
-- ***************************** 2009/07/10 1.10 N.Maeda    MOD START ******************************--
          ,NVL(ooha.attribute20,xeh.big_classification_code) big_classification_code  -- EDI�w�b�_���.�啪�ރR�[�h
          ,CASE
             WHEN  ( xeh.big_classification_code = ooha.attribute20 ) THEN
               xeh.big_classification_name
             ELSE
               NULL
           END
                                                big_classification_name        -- EDI�w�b�_���.�啪�ޖ�
--          ,xeh.big_classification_code          big_classification_code        -- EDI�w�b�_���.�啪�ރR�[�h
--          ,xeh.big_classification_name          big_classification_name        -- EDI�w�b�_���.�啪�ޖ�
-- ****************************** 2009/07/10 1.10 N.Maeda    MOD  END  *****************************--
          ,xeh.other_party_department_code      other_party_department_code    -- EDI�w�b�_���.����敔��R�[�h
          ,xeh.other_party_order_number         other_party_order_number       -- EDI�w�b�_���.����攭���ԍ�
          ,xeh.check_digit_class                check_digit_class              -- EDI�w�b�_���.�`�F�b�N�f�W�b�g�L���敪
          ,xeh.invoice_number                   invoice_number                 -- EDI�w�b�_���.�`�[�ԍ�
          ,xeh.check_digit                      check_digit                    -- EDI�w�b�_���.�`�F�b�N�f�W�b�g
          ,xeh.close_date                       close_date                     -- EDI�w�b�_���.����
          ,ooha.order_number                    order_number                   -- �󒍃w�b�_.�󒍔ԍ�
          ,xeh.ar_sale_class                    ar_sale_class                  -- EDI�w�b�_���.�����敪
          ,xeh.delivery_classe                  delivery_classe                -- EDI�w�b�_���.�z���敪
          ,xeh.opportunity_no                   opportunity_no                 -- EDI�w�b�_���.�ւm��
          ,xeh.contact_to                       contact_to                     -- EDI�w�b�_���.�A����
          ,xeh.route_sales                      route_sales                    -- EDI�w�b�_���.���[�g�Z�[���X
          ,xeh.corporate_code                   corporate_code                 -- EDI�w�b�_���.�@�l�R�[�h
          ,xeh.maker_name                       maker_name                     -- EDI�w�b�_���.���[�J�[��
          ,xeh.area_code                        area_code                      -- EDI�w�b�_���.�n��R�[�h
          ,xca3.edi_district_code               edi_district_code              -- �ڋq�}�X�^.EDI�n��R�[�h
          ,xeh.area_name                        area_name                      -- EDI�w�b�_���.�n�於(����)
          ,xca3.edi_district_name               edi_district_name              -- �ڋq�}�X�^.EDI�n�於
          ,xeh.area_name_alt                    area_name_alt                  -- EDI�w�b�_���.�n�於(�J�i)
          ,xca3.edi_district_kana               edi_district_kana              -- �ڋq�}�X�^.EDI�n�於�J�i
          ,xeh.vendor_code                      vendor_code                    -- EDI�w�b�_���.�����R�[�h
          ,xca3.torihikisaki_code               torihikisaki_code              -- �ڋq�}�X�^.�����R�[�h
          ,xeh.vendor_name1_alt                 vendor_name1_alt               -- EDI�w�b�_���.����於�P(�J�i)
          ,xeh.vendor_name2_alt                 vendor_name2_alt               -- EDI�w�b�_���.����於�Q(�J�i)
          ,papf.last_name                       last_name                      -- �]�ƈ��}�X�^.�J�i��
          ,papf.first_name                      first_name                     -- �]�ƈ��}�X�^.�J�i��
          ,hl1.state                            state                          -- ���_�}�X�^.�s���{��
          ,hl1.city                             city                           -- ���_�}�X�^.�s�E��
          ,hl1.address1                         address1                       -- ���_�}�X�^.�Z���P
          ,hl1.address2                         address2                       -- ���_�}�X�^.�Z���Q
          ,hl1.address_lines_phonetic           address_lines_phonetic         -- ���_�}�X�^.�d�b�ԍ�
          ,xeh.deliver_to_code_itouen           deliver_to_code_itouen         -- EDI�w�b�_���.�͂���R�[�h(�ɓ���)
          ,xeh.deliver_to_code_chain            deliver_to_code_chain          -- EDI�w�b�_���.�͂���R�[�h(�`�F�[���X)
          ,xeh.deliver_to                       deliver_to                     -- EDI�w�b�_���.�͂���(����)
          ,xeh.deliver_to1_alt                  deliver_to1_alt                -- EDI�w�b�_���.�͂���P(�J�i)
          ,xeh.deliver_to2_alt                  deliver_to2_alt                -- EDI�w�b�_���.�͂���Q(�J�i)
          ,xeh.deliver_to_address               deliver_to_address             -- EDI�w�b�_���.�͂���Z��(����)
          ,xeh.deliver_to_address_alt           deliver_to_address_alt         -- EDI�w�b�_���.�͂���Z��(�J�i)
          ,xeh.deliver_to_tel                   deliver_to_tel                 -- EDI�w�b�_���.�͂���s�d�k
          ,xeh.balance_accounts_code            balance_accounts_code          -- EDI�w�b�_���.������R�[�h
          ,xeh.balance_accounts_company_code    balance_accounts_company_code  -- EDI�w�b�_���.������ЃR�[�h
          ,xeh.balance_accounts_shop_code       balance_accounts_shop_code     -- EDI�w�b�_���.������X�R�[�h
          ,xeh.balance_accounts_name            balance_accounts_name          -- EDI�w�b�_���.�����於(����)
          ,xeh.balance_accounts_name_alt        balance_accounts_name_alt      -- EDI�w�b�_���.�����於(�J�i)
          ,xeh.balance_accounts_address         balance_accounts_address       -- EDI�w�b�_���.������Z��(����)
          ,xeh.balance_accounts_address_alt     balance_accounts_address_alt   -- EDI�w�b�_���.������Z��(�J�i)
          ,xeh.balance_accounts_tel             balance_accounts_tel           -- EDI�w�b�_���.������s�d�k
          ,xeh.order_possible_date              order_possible_date            -- EDI�w�b�_���.�󒍉\��
          ,xeh.permission_possible_date         permission_possible_date       -- EDI�w�b�_���.���e�\��
          ,xeh.forward_month                    forward_month                  -- EDI�w�b�_���.����N����
          ,xeh.payment_settlement_date          payment_settlement_date        -- EDI�w�b�_���.�x�����ϓ�
          ,xeh.handbill_start_date_active       handbill_start_date_active     -- EDI�w�b�_���.�`���V�J�n��
          ,xeh.billing_due_date                 billing_due_date               -- EDI�w�b�_���.��������
          ,xeh.shipping_time                    shipping_time                  -- EDI�w�b�_���.�o�׎���
          ,xeh.delivery_schedule_time           delivery_schedule_time         -- EDI�w�b�_���.�[�i�\�莞��
          ,xeh.order_time                       order_time                     -- EDI�w�b�_���.��������
          ,xeh.general_date_item1               general_date_item1             -- EDI�w�b�_���.�ėp���t���ڂP
          ,xeh.general_date_item2               general_date_item2             -- EDI�w�b�_���.�ėp���t���ڂQ
          ,xeh.general_date_item3               general_date_item3             -- EDI�w�b�_���.�ėp���t���ڂR
          ,xeh.general_date_item4               general_date_item4             -- EDI�w�b�_���.�ėp���t���ڂS
          ,xeh.general_date_item5               general_date_item5             -- EDI�w�b�_���.�ėp���t���ڂT
          ,xeh.arrival_shipping_class           arrival_shipping_class         -- EDI�w�b�_���.���o�׋敪
          ,xeh.vendor_class                     vendor_class                   -- EDI�w�b�_���.�����敪
          ,xeh.invoice_detailed_class           invoice_detailed_class         -- EDI�w�b�_���.�`�[����敪
          ,xeh.unit_price_use_class             unit_price_use_class           -- EDI�w�b�_���.�P���g�p�敪
          ,xeh.sub_distribution_center_code     sub_distribution_center_code   -- EDI�w�b�_���.�T�u�����Z���^�[�R�[�h
          ,xeh.sub_distribution_center_name     sub_distribution_center_name   -- EDI�w�b�_���.�T�u�����Z���^�[�R�[�h��
          ,xeh.center_delivery_method           center_delivery_method         -- EDI�w�b�_���.�Z���^�[�[�i���@
          ,xeh.center_use_class                 center_use_class               -- EDI�w�b�_���.�Z���^�[���p�敪
          ,xeh.center_whse_class                center_whse_class              -- EDI�w�b�_���.�Z���^�[�q�ɋ敪
          ,xeh.center_area_class                center_area_class              -- EDI�w�b�_���.�Z���^�[�n��敪
          ,xeh.center_arrival_class             center_arrival_class           -- EDI�w�b�_���.�Z���^�[���׋敪
          ,xeh.depot_class                      depot_class                    -- EDI�w�b�_���.�f�|�敪
          ,xeh.tcdc_class                       tcdc_class                     -- EDI�w�b�_���.�s�b�c�b�敪
          ,xeh.upc_flag                         upc_flag                       -- EDI�w�b�_���.�t�o�b�t���O
          ,xeh.simultaneously_class             simultaneously_class           -- EDI�w�b�_���.��ċ敪
          ,xeh.business_id                      business_id                    -- EDI�w�b�_���.�Ɩ��h�c
          ,xeh.whse_directly_class              whse_directly_class            -- EDI�w�b�_���.�q���敪
          ,xeh.premium_rebate_class             premium_rebate_class           -- EDI�w�b�_���.�i�i���ߋ敪
          ,xeh.item_type                        item_type                      -- EDI�w�b�_���.���ڎ��
          ,xeh.cloth_house_food_class           cloth_house_food_class         -- EDI�w�b�_���.�߉ƐH�敪
          ,xeh.mix_class                        mix_class                      -- EDI�w�b�_���.���݋敪
          ,xeh.stk_class                        stk_class                      -- EDI�w�b�_���.�݌ɋ敪
          ,xeh.last_modify_site_class           last_modify_site_class         -- EDI�w�b�_���.�ŏI�C���ꏊ�敪
          ,xeh.report_class                     report_class                   -- EDI�w�b�_���.���[�敪
          ,xeh.addition_plan_class              addition_plan_class            -- EDI�w�b�_���.�ǉ��E�v��敪
          ,xeh.registration_class               registration_class             -- EDI�w�b�_���.�o�^�敪
          ,xeh.specific_class                   specific_class                 -- EDI�w�b�_���.����敪
          ,xeh.dealings_class                   dealings_class                 -- EDI�w�b�_���.����敪
          ,xeh.order_class                      order_class                    -- EDI�w�b�_���.�����敪
          ,xeh.sum_line_class                   sum_line_class                 -- EDI�w�b�_���.�W�v���׋敪
          ,xeh.shipping_guidance_class          shipping_guidance_class        -- EDI�w�b�_���.�o�׈ē��ȊO�敪
          ,xeh.shipping_class                   shipping_class                 -- EDI�w�b�_���.�o�׋敪
          ,xeh.product_code_use_class           product_code_use_class         -- EDI�w�b�_���.���i�R�[�h�g�p�敪
          ,xeh.cargo_item_class                 cargo_item_class               -- EDI�w�b�_���.�ϑ��i�敪
          ,xeh.ta_class                         ta_class                       -- EDI�w�b�_���.�s�^�`�敪
          ,xeh.plan_code                        plan_code                      -- EDI�w�b�_���.���R�[�h
          ,xeh.category_code                    category_code                  -- EDI�w�b�_���.�J�e�S���[�R�[�h
          ,xeh.category_class                   category_class                 -- EDI�w�b�_���.�J�e�S���[�敪
          ,xeh.carrier_means                    carrier_means                  -- EDI�w�b�_���.�^����i
          ,xeh.counter_code                     counter_code                   -- EDI�w�b�_���.����R�[�h
          ,xeh.move_sign                        move_sign                      -- EDI�w�b�_���.�ړ��T�C��
          ,xeh.eos_handwriting_class            eos_handwriting_class          -- EDI�w�b�_���.�d�n�r�E�菑�敪
          ,xeh.delivery_to_section_code         delivery_to_section_code       -- EDI�w�b�_���.�[�i��ۃR�[�h
          ,xeh.invoice_detailed                 invoice_detailed               -- EDI�w�b�_���.�`�[����
          ,xeh.attach_qty                       attach_qty                     -- EDI�w�b�_���.�Y�t��
          ,xeh.other_party_floor                other_party_floor              -- EDI�w�b�_���.�t���A
          ,xeh.text_no                          text_no                        -- EDI�w�b�_���.�s�d�w�s�m��
          ,xeh.in_store_code                    in_store_code                  -- EDI�w�b�_���.�C���X�g�A�R�[�h
          ,xeh.tag_data                         tag_data                       -- EDI�w�b�_���.�^�O
          ,xeh.competition_code                 competition_code               -- EDI�w�b�_���.����
          ,xeh.billing_chair                    billing_chair                  -- EDI�w�b�_���.��������
          ,xeh.chain_store_code                 chain_store_code               -- EDI�w�b�_���.�`�F�[���X�g�A�[�R�[�h
          ,xeh.chain_store_short_name           chain_store_short_name         -- EDI�w�b�_���.�`�F�[���X�g�A�[�R�[�h��������
          ,xeh.direct_delivery_rcpt_fee         direct_delivery_rcpt_fee       -- EDI�w�b�_���.���z���^���旿
          ,xeh.bill_info                        bill_info                      -- EDI�w�b�_���.��`���
          ,xeh.description                      description                    -- EDI�w�b�_���.�E�v
          ,xeh.interior_code                    interior_code                  -- EDI�w�b�_���.�����R�[�h
          ,xeh.order_info_delivery_category     order_info_delivery_category   -- EDI�w�b�_���.�������@�[�i�J�e�S���[
          ,xeh.purchase_type                    purchase_type                  -- EDI�w�b�_���.�d���`��
          ,xeh.delivery_to_name_alt             delivery_to_name_alt           -- EDI�w�b�_���.�[�i�ꏊ��(�J�i)
          ,xeh.shop_opened_site                 shop_opened_site               -- EDI�w�b�_���.�X�o�ꏊ
          ,xeh.counter_name                     counter_name                   -- EDI�w�b�_���.���ꖼ
          ,xeh.extension_number                 extension_number               -- EDI�w�b�_���.�����ԍ�
          ,xeh.charge_name                      charge_name                    -- EDI�w�b�_���.�S���Җ�
          ,xeh.price_tag                        price_tag                      -- EDI�w�b�_���.�l�D
          ,xeh.tax_type                         tax_type                       -- EDI�w�b�_���.�Ŏ�
          ,xeh.consumption_tax_class            consumption_tax_class          -- EDI�w�b�_���.����ŋ敪
          ,xeh.brand_class                      brand_class                    -- EDI�w�b�_���.�a�q
          ,xeh.id_code                          id_code                        -- EDI�w�b�_���.�h�c�R�[�h
          ,xeh.department_code                  department_code                -- EDI�w�b�_���.�S�ݓX�R�[�h
          ,xeh.department_name                  department_name                -- EDI�w�b�_���.�S�ݓX��
          ,xeh.item_type_number                 item_type_number               -- EDI�w�b�_���.�i�ʔԍ�
          ,xeh.description_department           description_department         -- EDI�w�b�_���.�E�v(�S�ݓX)
          ,xeh.price_tag_method                 price_tag_method               -- EDI�w�b�_���.�l�D���@
          ,xeh.reason_column                    reason_column                  -- EDI�w�b�_���.���R��
          ,xeh.a_column_header                  a_column_header                -- EDI�w�b�_���.�`���w�b�_
          ,xeh.d_column_header                  d_column_header                -- EDI�w�b�_���.�c���w�b�_
          ,xeh.brand_code                       brand_code                     -- EDI�w�b�_���.�u�����h�R�[�h
          ,xeh.line_code                        line_code                      -- EDI�w�b�_���.���C���R�[�h
          ,xeh.class_code                       class_code                     -- EDI�w�b�_���.�N���X�R�[�h
          ,xeh.a1_column                        a1_column                      -- EDI�w�b�_���.�`�|�P��
          ,xeh.b1_column                        b1_column                      -- EDI�w�b�_���.�a�|�P��
          ,xeh.c1_column                        c1_column                      -- EDI�w�b�_���.�b�|�P��
          ,xeh.d1_column                        d1_column                      -- EDI�w�b�_���.�c�|�P��
          ,xeh.e1_column                        e1_column                      -- EDI�w�b�_���.�d�|�P��
          ,xeh.a2_column                        a2_column                      -- EDI�w�b�_���.�`�|�Q��
          ,xeh.b2_column                        b2_column                      -- EDI�w�b�_���.�a�|�Q��
          ,xeh.c2_column                        c2_column                      -- EDI�w�b�_���.�b�|�Q��
          ,xeh.d2_column                        d2_column                      -- EDI�w�b�_���.�c�|�Q��
          ,xeh.e2_column                        e2_column                      -- EDI�w�b�_���.�d�|�Q��
          ,xeh.a3_column                        a3_column                      -- EDI�w�b�_���.�`�|�R��
          ,xeh.b3_column                        b3_column                      -- EDI�w�b�_���.�a�|�R��
          ,xeh.c3_column                        c3_column                      -- EDI�w�b�_���.�b�|�R��
          ,xeh.d3_column                        d3_column                      -- EDI�w�b�_���.�c�|�R��
          ,xeh.e3_column                        e3_column                      -- EDI�w�b�_���.�d�|�R��
          ,xeh.f1_column                        f1_column                      -- EDI�w�b�_���.�e�|�P��
          ,xeh.g1_column                        g1_column                      -- EDI�w�b�_���.�f�|�P��
          ,xeh.h1_column                        h1_column                      -- EDI�w�b�_���.�g�|�P��
          ,xeh.i1_column                        i1_column                      -- EDI�w�b�_���.�h�|�P��
          ,xeh.j1_column                        j1_column                      -- EDI�w�b�_���.�i�|�P��
          ,xeh.k1_column                        k1_column                      -- EDI�w�b�_���.�j�|�P��
          ,xeh.l1_column                        l1_column                      -- EDI�w�b�_���.�k�|�P��
          ,xeh.f2_column                        f2_column                      -- EDI�w�b�_���.�e�|�Q��
          ,xeh.g2_column                        g2_column                      -- EDI�w�b�_���.�f�|�Q��
          ,xeh.h2_column                        h2_column                      -- EDI�w�b�_���.�g�|�Q��
          ,xeh.i2_column                        i2_column                      -- EDI�w�b�_���.�h�|�Q��
          ,xeh.j2_column                        j2_column                      -- EDI�w�b�_���.�i�|�Q��
          ,xeh.k2_column                        k2_column                      -- EDI�w�b�_���.�j�|�Q��
          ,xeh.l2_column                        l2_column                      -- EDI�w�b�_���.�k�|�Q��
          ,xeh.f3_column                        f3_column                      -- EDI�w�b�_���.�e�|�R��
          ,xeh.g3_column                        g3_column                      -- EDI�w�b�_���.�f�|�R��
          ,xeh.h3_column                        h3_column                      -- EDI�w�b�_���.�g�|�R��
          ,xeh.i3_column                        i3_column                      -- EDI�w�b�_���.�h�|�R��
          ,xeh.j3_column                        j3_column                      -- EDI�w�b�_���.�i�|�R��
          ,xeh.k3_column                        k3_column                      -- EDI�w�b�_���.�j�|�R��
          ,xeh.l3_column                        l3_column                      -- EDI�w�b�_���.�k�|�R��
          ,xeh.chain_peculiar_area_header       chain_peculiar_area_header     -- EDI�w�b�_���.�`�F�[���X�ŗL�G���A(�w�b�_�[)
          ,xeh.total_line_qty                   total_line_qty                 -- EDI�w�b�_���.�g�[�^���s��
          ,xeh.total_invoice_qty                total_invoice_qty              -- EDI�w�b�_���.�g�[�^���`�[����
          ,xeh.chain_peculiar_area_footer       chain_peculiar_area_footer     -- EDI�w�b�_���.�`�F�[���X�ŗL�G���A(�t�b�^�[)
          ,xeh.order_forward_flag               order_forward_flag             -- EDI�w�b�_���.�󒍘A�g�σt���O
          ,xeh.creation_class                   creation_class                 -- EDI�w�b�_���.�쐬���敪
          ,xeh.edi_delivery_schedule_flag       edi_delivery_schedule_flag     -- EDI�w�b�_���.EDI�[�i�\�著�M�σt���O
          ,xeh.price_list_header_id             price_list_header_id           -- EDI�w�b�_���.���i�\�w�b�_ID
          ,xel.edi_line_info_id                 edi_line_info_id               -- EDI���׏��.EDI���׏��ID
          ,xel.line_no                          line_no                        -- EDI���׏��.�s�m��
          ,DECODE(flvv1.attribute1, cv_y, ore.reason_code,
                                          cv_err_reason_code)
                                                stockout_class                 -- �ύX���R.���i�敪
          ,xel.stockout_reason                  stockout_reason                -- EDI���׏��.���i���R
          ,oola.ordered_item                    ordered_item                   -- �󒍖���.�󒍕i��
          ,xel.product_code1                    product_code1                  -- EDI���׏��.���i�R�[�h�P
          ,xel.product_code2                    product_code2                  -- EDI���׏��.���i�R�[�h�Q
          ,iimb.attribute21                     opf_jan_code                   -- �n�o�l�i�ڃ}�X�^.JAN�R�[�h
          ,xsib.case_jan_code                   case_jan_code                  -- Disc�i�ڃA�h�I��.�P�[�XJAN�R�[�h
          ,xel.itf_code                         itf_code                       -- EDI���׏��.�h�s�e�R�[�h
          ,iimb.attribute22                     opm_itf_code                   -- �n�o�l�i�ڃ}�X�^.ITF�R�[�h
          ,xel.extension_itf_code               extension_itf_code             -- EDI���׏��.�����h�s�e�R�[�h
          ,xel.case_product_code                case_product_code              -- EDI���׏��.�P�[�X���i�R�[�h
          ,xel.ball_product_code                ball_product_code              -- EDI���׏��.�{�[�����i�R�[�h
          ,xel.product_code_item_type           product_code_item_type         -- EDI���׏��.���i�R�[�h�i��
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--          ,xhpcv.item_div_h_code                item_div_h_code                -- �{�Џ��i�敪�r���[.�{�Џ��i�敪
          ,mcb.segment1                         item_div_h_code                -- �{�Џ��i�敪�r���[.�{�Џ��i�敪
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
          ,xel.product_name                     product_name                   -- EDI���׏��.���i��(����)
/* 2009/03/04 Ver1.6 Add Start */
          ,msib.description                     item_name                      -- Disc�i��.�E�v
/* 2009/03/04 Ver1.6 Add  End  */
          ,xel.product_name1_alt                product_name1_alt              -- EDI���׏��.���i���P(�J�i)
          ,xel.product_name2_alt                product_name2_alt              -- EDI���׏��.���i���Q(�J�i)
          ,SUBSTRB(ximb.item_name_alt, 1, 15)   item_name_alt                  -- �i��_���i���Q�i�J�i�j
          ,xel.item_standard1                   item_standard1                 -- EDI���׏��.�K�i�P
          ,xel.item_standard2                   item_standard2                 -- EDI���׏��.�K�i�Q
          ,SUBSTRB(ximb.item_name_alt, 16, 15)  item_name_alt2                 -- �i��_�K�i�Q
          ,xel.qty_in_case                      qty_in_case                    -- EDI���׏��.����
          ,iimb.attribute11                     num_of_case                    -- �n�o�l�i�ڃ}�X�^.�P�[�X����
          ,xel.num_of_ball                      num_of_ball                    -- EDI���׏��.�{�[������
          ,xsib.bowl_inc_num                    bowl_inc_num                   -- Disc�i�ڃA�h�I��.�{�[������
          ,xel.item_color                       item_color                     -- EDI���׏��.�F
          ,xel.item_size                        item_size                      -- EDI���׏��.�T�C�Y
          ,xel.expiration_date                  expiration_date                -- EDI���׏��.�ܖ�������
          ,xel.product_date                     product_date                   -- EDI���׏��.������
          ,xel.order_uom_qty                    order_uom_qty                  -- EDI���׏��.�����P�ʐ�
          ,xel.shipping_uom_qty                 shipping_uom_qty               -- EDI���׏��.�o�גP�ʐ�
          ,xel.packing_uom_qty                  packing_uom_qty                -- EDI���׏��.����P�ʐ�
          ,xel.deal_code                        deal_code                      -- EDI���׏��.����
          ,xel.deal_class                       deal_class                     -- EDI���׏��.�����敪
          ,xel.collation_code                   collation_code                 -- EDI���׏��.�ƍ�
          ,xel.uom_code                         uom_code                       -- EDI���׏��.�P��
          ,xel.unit_price_class                 unit_price_class               -- EDI���׏��.�P���敪
          ,xel.parent_packing_number            parent_packing_number          -- EDI���׏��.�e����ԍ�
          ,xel.packing_number                   packing_number                 -- EDI���׏��.����ԍ�
          ,xel.product_group_code               product_group_code             -- EDI���׏��.���i�Q�R�[�h
          ,xel.case_dismantle_flag              case_dismantle_flag            -- EDI���׏��.�P�[�X��̕s�t���O
          ,xel.case_class                       case_class                     -- EDI���׏��.�P�[�X�敪
          ,xel.indv_order_qty                   indv_order_qty                 -- EDI���׏��.��������(�o��)
          ,xel.case_order_qty                   case_order_qty                 -- EDI���׏��.��������(�P�[�X)
          ,xel.ball_order_qty                   ball_order_qty                 -- EDI���׏��.��������(�{�[��)
          ,xel.sum_order_qty                    sum_order_qty                  -- EDI���׏��.��������(���v�A�o��)
          ,xel.indv_shipping_qty                indv_shipping_qty              -- EDI���׏��.�o�א���(�o��)
          ,xel.case_shipping_qty                case_shipping_qty              -- EDI���׏��.�o�א���(�P�[�X)
          ,xel.ball_shipping_qty                ball_shipping_qty              -- EDI���׏��.�o�א���(�{�[��)
          ,xel.pallet_shipping_qty              pallet_shipping_qty            -- EDI���׏��.�o�א���(�p���b�g)
          ,xel.sum_shipping_qty                 sum_shipping_qty               -- EDI���׏��.�o�א���(���v�A�o��)
          ,xel.indv_stockout_qty                indv_stockout_qty              -- EDI���׏��.���i����(�o��)
          ,xel.case_stockout_qty                case_stockout_qty              -- EDI���׏��.���i����(�P�[�X)
          ,xel.ball_stockout_qty                ball_stockout_qty              -- EDI���׏��.���i����(�{�[��)
          ,xel.sum_stockout_qty                 sum_stockout_qty               -- EDI���׏��.���i����(���v�A�o��)
          ,xel.case_qty                         case_qty                       -- EDI���׏��.�P�[�X����
          ,xel.fold_container_indv_qty          fold_container_indv_qty        -- EDI���׏��.�I���R��(�o��)����
          ,xel.order_unit_price                 order_unit_price               -- EDI���׏��.���P��(����)
          ,oola.unit_selling_price              unit_selling_price             -- �󒍖���.�̔��P��
          ,xel.order_cost_amt                   order_cost_amt                 -- EDI���׏��.�������z(����)
          ,xel.shipping_cost_amt                shipping_cost_amt              -- EDI���׏��.�������z(�o��)
          ,xel.stockout_cost_amt                stockout_cost_amt              -- EDI���׏��.�������z(���i)
          ,xel.selling_price                    selling_price                  -- EDI���׏��.���P��
          ,xel.order_price_amt                  order_price_amt                -- EDI���׏��.�������z(����)
          ,xel.shipping_price_amt               shipping_price_amt             -- EDI���׏��.�������z(�o��)
          ,xel.stockout_price_amt               stockout_price_amt             -- EDI���׏��.�������z(���i)
          ,xel.a_column_department              a_column_department            -- EDI���׏��.�`��(�S�ݓX)
          ,xel.d_column_department              d_column_department            -- EDI���׏��.�c��(�S�ݓX)
          ,xel.standard_info_depth              standard_info_depth            -- EDI���׏��.�K�i���E���s��
          ,xel.standard_info_height             standard_info_height           -- EDI���׏��.�K�i���E����
          ,xel.standard_info_width              standard_info_width            -- EDI���׏��.�K�i���E��
          ,xel.standard_info_weight             standard_info_weight           -- EDI���׏��.�K�i���E�d��
          ,xel.general_succeeded_item1          general_succeeded_item1        -- EDI���׏��.�ėp���p�����ڂP
          ,xel.general_succeeded_item2          general_succeeded_item2        -- EDI���׏��.�ėp���p�����ڂQ
          ,xel.general_succeeded_item3          general_succeeded_item3        -- EDI���׏��.�ėp���p�����ڂR
          ,xel.general_succeeded_item4          general_succeeded_item4        -- EDI���׏��.�ėp���p�����ڂS
          ,xel.general_succeeded_item5          general_succeeded_item5        -- EDI���׏��.�ėp���p�����ڂT
          ,xel.general_succeeded_item6          general_succeeded_item6        -- EDI���׏��.�ėp���p�����ڂU
          ,xel.general_succeeded_item7          general_succeeded_item7        -- EDI���׏��.�ėp���p�����ڂV
          ,xel.general_succeeded_item8          general_succeeded_item8        -- EDI���׏��.�ėp���p�����ڂW
          ,xel.general_succeeded_item9          general_succeeded_item9        -- EDI���׏��.�ėp���p�����ڂX
          ,xel.general_succeeded_item10         general_succeeded_item10       -- EDI���׏��.�ėp���p�����ڂP�O
          ,xel.general_add_item1                general_add_item1              -- EDI���׏��.�ėp�t�����ڂP
          ,xel.general_add_item2                general_add_item2              -- EDI���׏��.�ėp�t�����ڂQ
          ,xel.general_add_item3                general_add_item3              -- EDI���׏��.�ėp�t�����ڂR
          ,xel.general_add_item4                general_add_item4              -- EDI���׏��.�ėp�t�����ڂS
          ,xel.general_add_item5                general_add_item5              -- EDI���׏��.�ėp�t�����ڂT
          ,xel.general_add_item6                general_add_item6              -- EDI���׏��.�ėp�t�����ڂU
          ,xel.general_add_item7                general_add_item7              -- EDI���׏��.�ėp�t�����ڂV
          ,xel.general_add_item8                general_add_item8              -- EDI���׏��.�ėp�t�����ڂW
          ,xel.general_add_item9                general_add_item9              -- EDI���׏��.�ėp�t�����ڂX
          ,xel.general_add_item10               general_add_item10             -- EDI���׏��.�ėp�t�����ڂP�O
          ,xel.chain_peculiar_area_line         chain_peculiar_area_line       -- EDI���׏��.�`�F�[���X�ŗL�G���A(����)
          ,xel.item_code                        item_code                      -- EDI���׏��.�i�ڃR�[�h
          ,xel.line_uom                         line_uom                       -- EDI���׏��.���גP��
          ,xel.order_connection_line_number     order_connection_line_number   -- EDI���׏��.�󒍊֘A���הԍ�
-- ******* 2009/10/05 1.14 N.Maeda MOD START ******* --
--          ,oola.ordered_quantity                ordered_quantity               -- �󒍖���.�󒍐���
          ,CASE
             WHEN ( ooha.order_source_id = gt_order_source_online ) THEN
               oola.ordered_quantity
             ELSE
               ( SELECT SUM ( oola_ilv.ordered_quantity ) ordered_quantity
                 FROM   oe_order_lines_all oola_ilv
                 WHERE  oola_ilv.header_id    = oola.header_id
                 AND    oola_ilv.org_id       = oola.org_id
                 AND    NVL ( oola_ilv.global_attribute3 , oola_ilv.line_id ) = oola.line_id
                 AND    NVL ( oola_ilv.global_attribute4 , oola_ilv.orig_sys_line_ref ) = oola.orig_sys_line_ref
               )
           END                                  ordered_quantity
-- ******* 2009/10/05 1.14 N.Maeda MOD  END  ******* --
          ,xtrv.tax_rate                        tax_rate                       -- ����ŗ��r���[.����ŗ�
--****************************** 2009/06/11 1.10 T.Kitajima ADD START ******************************--
          ,xca3.edi_forward_number              edi_forward_number             -- �ڋq�ǉ����.EDI�`���ǔ�
--****************************** 2009/06/11 1.10 T.Kitajima ADD  END ******************************--
--****************************** 2009/06/24 1.10 T.Kitajima ADD START ******************************--
          ,oola.order_quantity_uom              order_quantity_uom             -- �󒍖���.�P��
--****************************** 2009/06/24 1.10 T.Kitajima ADD  END ******************************--
    FROM   xxcos_edi_headers                    xeh    -- EDI�w�b�_���
          ,xxcos_edi_lines                      xel    -- EDI���׏��
          ,oe_order_headers_all                 ooha   -- �󒍃w�b�_
          ,oe_order_lines_all                   oola   -- �󒍖���
          ,hz_cust_accounts                     hca1   -- ���_�}�X�^
          ,xxcmm_cust_accounts                  xca1   -- ���_�ǉ����
          ,hz_parties                           hp1    -- ���_�p�[�e�B
          ,hz_party_sites                       hps1   -- ���_�p�[�e�B�T�C�g
          ,hz_locations                         hl1    -- ���_���Ə�
          ,hz_cust_acct_sites_all               hcas1  -- ���_���ݒn
          ,hz_cust_accounts                     hca2   -- �`�F�[���X�}�X�^
          ,xxcmm_cust_accounts                  xca2   -- �`�F�[���X�ǉ����
          ,hz_parties                           hp2    -- �`�F�[���X�p�[�e�B
          ,hz_cust_accounts                     hca3   -- �ڋq�}�X�^
          ,xxcmm_cust_accounts                  xca3   -- �ڋq�ǉ����
          ,hz_parties                           hp3    -- �ڋq�p�[�e�B
          ,xxcos_tax_rate_v                     xtrv   -- ����ŗ��r���[
          ,xxcos_login_base_info_v              xlbiv  -- ���_(�Ǘ���)�r���[
          ,per_all_people_f                     papf   -- �]�ƈ��}�X�^
          ,per_all_assignments_f                paaf   -- �]�ƈ������}�X�^
          ,ic_item_mst_b                        iimb   -- �n�o�l�i�ڃ}�X�^
          ,xxcmn_item_mst_b                     ximb   -- �n�o�l�i�ڃA�h�I��
          ,mtl_system_items_b                   msib   -- Disc�i�ڃ}�X�^
          ,xxcmm_system_items_b                 xsib   -- Disc�i�ڃA�h�I��
-- ******* 2009/09/03 1.12 N.Maeda DEL START ******* --
--          ,xxcos_head_prod_class_v              xhpcv  -- �{�Џ��i�敪�r���[
-- ******* 2009/09/03 1.12 N.Maeda DEL  END  ******* --
          ,(SELECT ore1.reason_code             reason_code
                  ,ore1.entity_id               entity_id
            FROM   oe_reasons                   ore1
/* 2009/08/10 Ver1.11 Mod Start */
--                  ,(SELECT ore2.entity_id           entity_id
                  ,(SELECT /*+ INDEX( ore2 xxcos_oe_reasons_n04 ) */
                           ore2.entity_id           entity_id
/* 2009/08/10 Ver1.11 Mod Start */
                          ,MAX(ore2.creation_date)  creation_date
                    FROM   oe_reasons               ore2
                    WHERE  ore2.reason_type = cv_reason_type
                    AND    ore2.entity_code = cv_entity_code_line
                    GROUP BY ore2.entity_id
                   )                            ore_max
            WHERE  ore1.entity_id     = ore_max.entity_id
            AND    ore1.creation_date = ore_max.creation_date
           )                                    ore    -- �ύX���R
          ,fnd_lookup_values_vl                 flvv1  -- ���R�R�[�h�}�X�^
-- ******* 2009/09/03 1.12 N.Maeda ADD START ******* --
          ,mtl_item_categories            mic
          ,mtl_categories_b               mcb
-- ******* 2009/09/03 1.12 N.Maeda ADD  END  ******* --
    WHERE  xeh.edi_header_info_id         = xel.edi_header_info_id            -- EDIͯ�ޏ��.EDIͯ�ޏ��ID=EDI���׏��.EDIͯ�ޏ��ID
    AND    xeh.creation_class             =                                   -- EDIͯ�ޏ��.�쐬���敪='01'(���ް�)
         ( SELECT flvv.meaning   creation_class
           FROM   fnd_lookup_values_vl  flvv
           WHERE  flvv.lookup_type        = cv_edi_create_class
           AND    flvv.lookup_code        = cv_edi_create_class_c
           AND    flvv.enabled_flag       = cv_y                -- �L��
           AND (( flvv.start_date_active IS NULL )
           OR   ( flvv.start_date_active <= cd_process_date ))
           AND (( flvv.end_date_active   IS NULL )
           OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
         )
    AND    xeh.edi_delivery_schedule_flag = cv_n                              -- EDIͯ�ޏ��.EDI�[�i�\�著�M���׸�='N'(�����M)
    AND    xeh.data_type_code             = cv_data_type_edi                  -- EDIͯ�ޏ��.�ް�����='11'(��EDI)
    AND    xeh.edi_chain_code             = gt_edi_c_code                     -- EDIͯ�ޏ��.EDI���ݓX����=in���Ұ�.EDI���ݓX����
    AND    TRUNC(xeh.shop_delivery_date)    BETWEEN gt_shop_date_from         -- EDIͯ�ޏ��.�X�ܔ[�i�� BETWEEN in���Ұ�.�X�ܔ[�i��From
                                                AND gt_shop_date_to           --                            AND in���Ұ�.�X�ܔ[�i��To
    AND  ( gt_sale_class                 IS NULL                              -- in���Ұ�.��ԓ����敪 IS NULL
    OR     gt_sale_class                  = cv_sale_class_all                 -- in���Ұ�.��ԓ����敪='0'(����)
    OR     xeh.ar_sale_class              = gt_sale_class )                   -- EDIͯ�ޏ��.�����敪=in���Ұ�.��ԓ����敪
    AND    ooha.sold_to_org_id            = hca3.cust_account_id              -- ��ͯ��.�ڋqID=�ڋqϽ�.�ڋqID
    AND    hca3.customer_class_code       = cv_cust_code_cust                 -- �ڋqϽ�.�ڋq�敪='10'(�ڋq)
    AND    xca3.tsukagatazaiko_div       IN (cv_tukzik_div_tuk,               -- �ڋqϽ�.�ʉߍ݌Ɍ^�敪 IN ('11'(�����[�i(�ʉߌ^���)),
                                             cv_tukzik_div_zik,               --                            '12'(�����[�i(�݌Ɍ^���)),
                                             cv_tukzik_div_tnp)               --                            '24'(�X�ܔ[�i))
    AND    xca3.chain_store_code          = gt_edi_c_code                     -- �ڋqϽ�.���ݓX����(EDI)=in���Ұ�.EDI���ݓX����
    AND    xca3.edi_forward_number        = gt_edi_f_number                   -- �ڋqϽ�.EDI�`���ǔ�=in���Ұ�.EDI�`���ǔ�
    AND  ( gt_area_code                  IS NULL                              -- in���Ұ�.�n�溰�� IS NULL
    OR     xca3.edi_district_code         = gt_area_code )                    -- �ڋqϽ�.�n�溰��=in���Ұ�.�n�溰��
    AND    hca3.cust_account_id           = xtrv.cust_account_id              -- �ڋqϽ�.�ڋqID=����ŗ��ޭ�.�ڋqID
    AND    xca3.tax_div                   = xtrv.tax_div                      -- �ڋqϽ�.����ŋ敪=����ŗ��ޭ�.����ŋ敪
    AND    xtrv.set_of_books_id           = gn_bks_id                         -- ����ŗ��ޭ�.GL��v����ID=[A-2].GL��v����ID
    AND    TRUNC(oola.request_date)      >= xtrv.start_date_active            -- �󒍖���.�v����>=����ŗ��ޭ�.�K�p�J�n��
    AND    TRUNC(oola.request_date)      <= NVL(xtrv.end_date_active,         -- �󒍖���.�v����<=NVL(����ŗ��ޭ�.�K�p�I����,
                                                gd_max_date)                  --                      [A-2].MAX���t)
/* 2009/02/25 Ver1.3 Add Start */
    AND    TRUNC(oola.request_date)      >= xtrv.tax_start_date               -- �󒍖���.�v����>=����ŗ��ޭ�.�ŊJ�n��
    AND    TRUNC(oola.request_date)      <= NVL(xtrv.tax_end_date,            -- �󒍖���.�v����<=NVL(����ŗ��ޭ�.�ŏI����,
                                                gd_max_date)                  --                      [A-2].MAX���t)
/* 2009/02/25 Ver1.3 Add  End  */
    AND    xeh.edi_chain_code             = xca2.chain_store_code             -- EDIͯ�ޏ��.EDI���ݓX����=���ݓXϽ�.���ݓX����(EDI)
    AND    hca2.customer_class_code       = cv_cust_code_chain                -- ���ݓXϽ�.�ڋq�敪='18'(���ݓX)
/* 2009/02/20 Ver1.1 Mod Start */
--  AND (( xca2.handwritten_slip_div      = cv_n                              -- ���ݓXϽ�.�菑�`�[�`���敪='N'(�菑���M�ΏۊO)
    AND (( xca2.handwritten_slip_div      = cv_2                              -- ���ݓXϽ�.�菑�`�[�`���敪='2'(�菑���M�ΏۊO)
    AND    xeh.medium_class               = cv_medium_class_edi )             -- EDIͯ�ޏ��.�}�̋敪='00'(EDI)
--  OR     xca2.handwritten_slip_div      = cv_y )                            -- ���ݓXϽ�.�菑�`�[�`���敪='Y'(�菑���M�Ώ�)
    OR     xca2.handwritten_slip_div      = cv_1 )                            -- ���ݓXϽ�.�菑�`�[�`���敪='1'(�菑���M�Ώ�)
/* 2009/02/20 Ver1.1 Mod  End  */
    AND    hca2.cust_account_id           = xca2.customer_id                  -- ���ݓXϽ�.�ڋqID=���ݓX�ǉ����.�ڋqID
    AND    hca1.account_number            = xca3.delivery_base_code           -- ���_Ͻ�.�ڋq����=�ڋqϽ�.�[�i���_����
    AND    hca1.customer_class_code       = cv_cust_code_base                 -- ���_Ͻ�.�ڋq�敪='1'(���_)
    AND    hca1.party_id                  = hp1.party_id                      -- ���_Ͻ�.�߰èID=���_�߰è.�߰èID
    AND    hcas1.cust_account_id          = hca1.cust_account_id              -- ���_���ݒn.�ڋqID=�ڋqϽ�.�ڋqID
    AND    hps1.location_id               = hl1.location_id                   -- ���_�߰è���.���ݒnID=���_���Ə�.���ݒnID
    AND    hps1.party_site_id             = hcas1.party_site_id               -- ���_�߰è���.�߰è���ID=���_���ݒn.�߰è���ID
    AND    hcas1.org_id                   = gn_org_id                         -- ���_���ݒn.�g�DID=[A-2].�c�ƒP��
    AND    hca1.cust_account_id           = xca1.customer_id                  -- ���_Ͻ�.�ڋqID=���_�ǉ����.�ڋqID
    AND    hca3.cust_account_id           = xca3.customer_id                  -- �ڋqϽ�.�ڋqID=�ڋq�ǉ����.�ڋqID
    AND    hca2.party_id                  = hp2.party_id                      -- ���ݓXϽ�.�߰èID=���ݓX�߰è.�߰èID
    AND    hp2.duns_number_c             <> cv_cust_status_90                 -- ���ݓX�߰è.�ڋq�ð��<>'90'(���~���ٍ�)
    AND    hca3.party_id                  = hp3.party_id                      -- �ڋqϽ�.�߰èID=�ڋq�߰è.�߰èID
    AND    xca3.delivery_base_code        = xlbiv.base_code                   -- �ڋq�ǉ����.�[�i���_����=���_(�Ǘ���)�ޭ�.���_����
    AND    xca3.delivery_base_code        = paaf.ass_attribute5               -- �ڋq�ǉ����.�[�i���_����=�]�ƈ�����Ͻ�.��������
    AND    paaf.effective_start_date     <= cd_process_date                   -- �]�ƈ�����Ͻ�.�K�p�J�n��<=�Ɩ����t
    AND    paaf.effective_end_date       >= cd_process_date                   -- �]�ƈ�����Ͻ�.�K�p�I����>=�Ɩ����t
    AND    papf.person_id                 = paaf.person_id                    -- �]�ƈ�Ͻ�.�]�ƈ�ID=�]�ƈ�����Ͻ�.�]�ƈ�ID
    AND    papf.attribute11               = cv_position                       -- �]�ƈ�Ͻ�.�E��(�V)='002'(�x�X��)
    AND    papf.effective_start_date     <= cd_process_date                   -- �]�ƈ�Ͻ�.�K�p�J�n��<=�Ɩ����t
    AND    papf.effective_end_date       >= cd_process_date                   -- �]�ƈ�Ͻ�.�K�p�I����>=�Ɩ����t
--****************************** 2009/06/19 1.10 T.Kitajima MOD START ******************************--
    AND    ooha.org_id                    = gn_org_id                         -- ��ͯ��.�g�DID=[A-2].�c�ƒP��
--****************************** 2009/06/19 1.10 T.Kitajima MOD  END  ******************************--
    AND    ooha.header_id                 = oola.header_id                    -- ��ͯ��.��ͯ��ID=�󒍖���.��ͯ��ID
    AND    ooha.orig_sys_document_ref     = xeh.order_connection_number       -- ��ͯ��.�O�����ю󒍊֘A�ԍ�=EDIͯ�ޏ��.�󒍊֘A�ԍ�
    AND    oola.orig_sys_line_ref         = xel.order_connection_line_number  -- �󒍖���.�O�����ю󒍖��הԍ�=EDI���׏��.�󒍊֘A���הԍ�
--****************************** 2009/06/11 1.10 T.Kitajima MOD START ******************************--
--    AND    xel.line_no                    = oola.line_number                  -- EDI���׏��.�sNo=�󒍖���.���הԍ�
    AND    xel.order_connection_line_number
                                          = oola.orig_sys_line_ref            -- EDI���׏��.�󒍊֘A���הԍ� = �󒍖���.�O�����ю󒍖��הԍ�
--****************************** 2009/06/11 1.10 T.Kitajima MOD  END  ******************************--
    AND    oola.inventory_item_id         = msib.inventory_item_id            -- �󒍖���.�i��ID=Disc�i��Ͻ�.�i��ID
    AND    msib.segment1                  = iimb.item_no                      -- Disc�i��Ͻ�.�i�ں���=OPM�i��Ͻ�.�i�ں���
    AND    iimb.item_id                   = ximb.item_id                      -- OPM�i��Ͻ�.�i��ID=OPM�i�ڱ�޵�.�i��ID
    AND    ximb.start_date_active        <= cd_process_date                   -- OPM�i�ڱ�޵�.�K�p�J�n��<=�Ɩ����t
    AND    ximb.end_date_active          >= cd_process_date                   -- OPM�i�ڱ�޵�.�K�p�I����>=�Ɩ����t
    AND    msib.organization_id           = gn_organization_id                -- Disc�i��Ͻ�.�g�DID=[A-2].�݌ɑg�DID
    AND    msib.segment1                  = xsib.item_code                    -- Disc�i��Ͻ�.�i�ں���=Disc�i�ڱ�޵�.�i�ں���
-- ******* 2009/09/03 1.12 N.Maeda MOD START ******* --
--    AND    msib.inventory_item_id         = xhpcv.inventory_item_id           -- Disc�i��Ͻ�.�i��ID=�{�Џ��i�敪�ޭ�.�i��ID
    AND msib.organization_id = gn_organization_id
    AND gn_organization_id = mic.organization_id
    AND msib.inventory_item_id = mic.inventory_item_id
    AND mic.category_set_id    = gt_category_set_id
    AND mic.category_id        = mcb.category_id
    AND ( mcb.disable_date IS NULL OR mcb.disable_date > cd_process_date )
    AND   mcb.enabled_flag   = 'Y'      -- �J�e�S���L���t���O
    AND   cd_process_date BETWEEN NVL(mcb.start_date_active, cd_process_date)
                                     AND   NVL(mcb.end_date_active, cd_process_date)
    AND   msib.enabled_flag  = 'Y'      -- �i�ڃ}�X�^�L���t���O
    AND   cd_process_date BETWEEN NVL(msib.start_date_active, cd_process_date)
                                     AND  NVL(msib.end_date_active, cd_process_date)
-- ******* 2009/09/03 1.12 N.Maeda MOD  END  ******* --
    AND    ore.entity_id(+)               = oola.line_id                      -- �ύX���R.ID=�󒍖���.����ID
    AND    flvv1.lookup_type(+)           = cv_reason_type                    -- ���R����Ͻ�.����=�ύX���R
    AND    flvv1.lookup_code(+)           = ore.reason_code                   -- ���R����Ͻ�.����=�ύX���R.���R����
    AND (( flvv1.start_date_active IS NULL )
    OR   ( flvv1.start_date_active <= cd_process_date ))
    AND (( flvv1.end_date_active   IS NULL )
    OR   ( flvv1.end_date_active   >= cd_process_date ))                      -- �Ɩ����t��FROM-TO��
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD START ******************************--
    AND (( ooha.global_attribute3 IS NULL )
    OR   ( ooha.global_attribute3 = '02' ) )
-- ***************************** 2009/07/10 1.10 N.Maeda    ADD  END  ******************************--
    ORDER BY
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--           xeh.invoice_number                 -- EDI�w�b�_���.�`�[�ԍ�
--          ,xel.line_no                        -- EDI���׏��.�s�m��
           xeh.delivery_center_code            --1.EDI�w�b�_���.�[���Z���^�[�R�[�h
          ,xeh.shop_code                       --2.EDI�w�b�_���.�X�R�[�h
          ,xeh.invoice_number                  --3.EDI�w�b�_���.�`�[�ԍ�
-- ********* 2009/09/25 1.13 N.Maeda ADD START ********* --
          ,xeh.edi_header_info_id              -- EDI�w�b�_���.EDI�w�b�_���ID
-- ********* 2009/09/25 1.13 N.Maeda ADD  END  ********* --
          ,xel.line_no                         --4.EDI���׏��.�sNo
          ,xel.packing_number                  --5.EDI���׏��.����ԍ�
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
    FOR UPDATE OF
           xeh.edi_header_info_id             -- EDI�w�b�_���
          ,xel.edi_header_info_id             -- EDI���׏��
          NOWAIT
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===============================
  -- �w�b�_���
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        xxcmm_cust_accounts.delivery_base_code%TYPE  -- �[�i���_�R�[�h
   ,delivery_base_name        hz_parties.party_name%TYPE                   -- �[�i���_��
   ,delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE   -- �[�i���_�J�i
   ,edi_chain_name            hz_parties.party_name%TYPE                   -- EDI�`�F�[���X��
   ,edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE   -- EDI�`�F�[���X�J�i
  );
--
  -- �`�[�ʍ��v
  TYPE g_invoice_total_rtype IS RECORD(
    indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- ��������(�o��)
   ,case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- ��������(�P�[�X)
   ,ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- ��������(�{�[��)
   ,sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- ��������(���v�A�o��)
   ,indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- �o�א���(�o��)
   ,case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- �o�א���(�P�[�X)
   ,ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- �o�א���(�{�[��)
   ,pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- �o�א���(�p���b�g)
   ,sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- �o�א���(���v�A�o��)
   ,indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- ���i����(�o��)
   ,case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- ���i����(�P�[�X)
   ,ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- ���i����(�{�[��)
   ,sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- ���i����(���v�A�o��)
   ,case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- �P�[�X����
   ,order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- �������z(����)
   ,shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- �������z(�o��)
   ,stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- �������z(���i)
   ,order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- �������z(����)
   ,shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- �������z(�o��)
   ,stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- �������z(���i)
  );
--
  -- EDI�w�b�_���
  TYPE g_edi_header_rtype IS RECORD(
    edi_header_info_id           xxcos_edi_headers.edi_header_info_id%TYPE           -- EDI�w�b�_���ID
   ,process_date                 xxcos_edi_headers.process_date%TYPE                 -- ������
   ,process_time                 xxcos_edi_headers.process_time%TYPE                 -- ��������
   ,base_code                    xxcos_edi_headers.base_code%TYPE                    -- ���_(����)�R�[�h
   ,base_name                    xxcos_edi_headers.base_name%TYPE                    -- ���_��(������)
   ,base_name_alt                xxcos_edi_headers.base_name_alt%TYPE                -- ���_��(�J�i)
   ,customer_code                xxcos_edi_headers.customer_code%TYPE                -- �ڋq�R�[�h
   ,customer_name                xxcos_edi_headers.customer_name%TYPE                -- �ڋq��(����)
   ,customer_name_alt            xxcos_edi_headers.customer_name_alt%TYPE            -- �ڋq��(�J�i)
   ,shop_code                    xxcos_edi_headers.shop_code%TYPE                    -- �X�R�[�h
   ,shop_name                    xxcos_edi_headers.shop_name%TYPE                    -- �X��(����)
   ,shop_name_alt                xxcos_edi_headers.shop_name_alt%TYPE                -- �X��(�J�i)
   ,center_delivery_date         xxcos_edi_headers.center_delivery_date%TYPE         -- �Z���^�[�[�i��
   ,order_no_ebs                 xxcos_edi_headers.order_no_ebs%TYPE                 -- ��No(EBS)
   ,contact_to                   xxcos_edi_headers.contact_to%TYPE                   -- �A����
   ,area_code                    xxcos_edi_headers.area_code%TYPE                    -- �n��R�[�h
   ,area_name                    xxcos_edi_headers.area_name%TYPE                    -- �n�於(����)
   ,area_name_alt                xxcos_edi_headers.area_name_alt%TYPE                -- �n�於(�J�i)
   ,vendor_code                  xxcos_edi_headers.vendor_code%TYPE                  -- �����R�[�h
   ,vendor_name                  xxcos_edi_headers.vendor_name%TYPE                  -- ����於(����)
   ,vendor_name1_alt             xxcos_edi_headers.vendor_name1_alt%TYPE             -- ����於1(�J�i)
   ,vendor_name2_alt             xxcos_edi_headers.vendor_name2_alt%TYPE             -- ����於2(�J�i)
   ,vendor_tel                   xxcos_edi_headers.vendor_tel%TYPE                   -- �����TEL
   ,vendor_charge                xxcos_edi_headers.vendor_charge%TYPE                -- �����S����
   ,vendor_address               xxcos_edi_headers.vendor_address%TYPE               -- �����Z��(����)
   ,delivery_schedule_time       xxcos_edi_headers.delivery_schedule_time%TYPE       -- �[�i�\�莞��
   ,carrier_means                xxcos_edi_headers.carrier_means%TYPE                -- �^����i
   ,eos_handwriting_class        xxcos_edi_headers.eos_handwriting_class%TYPE        -- EOS��菑�敪
   ,invoice_indv_order_qty       xxcos_edi_headers.invoice_indv_order_qty%TYPE       -- (�`�[�v)��������(�o��)
   ,invoice_case_order_qty       xxcos_edi_headers.invoice_case_order_qty%TYPE       -- (�`�[�v)��������(�P�[�X)
   ,invoice_ball_order_qty       xxcos_edi_headers.invoice_ball_order_qty%TYPE       -- (�`�[�v)��������(�{�[��)
   ,invoice_sum_order_qty        xxcos_edi_headers.invoice_sum_order_qty%TYPE        -- (�`�[�v)��������(���v�A�o��)
   ,invoice_indv_shipping_qty    xxcos_edi_headers.invoice_indv_shipping_qty%TYPE    -- (�`�[�v)�o�א���(�o��)
   ,invoice_case_shipping_qty    xxcos_edi_headers.invoice_case_shipping_qty%TYPE    -- (�`�[�v)�o�א���(�P�[�X)
   ,invoice_ball_shipping_qty    xxcos_edi_headers.invoice_ball_shipping_qty%TYPE    -- (�`�[�v)�o�א���(�{�[��)
   ,invoice_pallet_shipping_qty  xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE  -- (�`�[�v)�o�א���(�p���b�g)
   ,invoice_sum_shipping_qty     xxcos_edi_headers.invoice_sum_shipping_qty%TYPE     -- (�`�[�v)�o�א���(���v�A�o��)
   ,invoice_indv_stockout_qty    xxcos_edi_headers.invoice_indv_stockout_qty%TYPE    -- (�`�[�v)���i����(�o��)
   ,invoice_case_stockout_qty    xxcos_edi_headers.invoice_case_stockout_qty%TYPE    -- (�`�[�v)���i����(�P�[�X)
   ,invoice_ball_stockout_qty    xxcos_edi_headers.invoice_ball_stockout_qty%TYPE    -- (�`�[�v)���i����(�{�[��)
   ,invoice_sum_stockout_qty     xxcos_edi_headers.invoice_sum_stockout_qty%TYPE     -- (�`�[�v)���i����(���v�A�o��)
   ,invoice_case_qty             xxcos_edi_headers.invoice_case_qty%TYPE             -- (�`�[�v)�P�[�X����
   ,invoice_fold_container_qty   xxcos_edi_headers.invoice_fold_container_qty%TYPE   -- (�`�[�v)�I���R��(�o��)����
   ,invoice_order_cost_amt       xxcos_edi_headers.invoice_order_cost_amt%TYPE       -- (�`�[�v)�������z(����)
   ,invoice_shipping_cost_amt    xxcos_edi_headers.invoice_shipping_cost_amt%TYPE    -- (�`�[�v)�������z(�o��)
   ,invoice_stockout_cost_amt    xxcos_edi_headers.invoice_stockout_cost_amt%TYPE    -- (�`�[�v)�������z(���i)
   ,invoice_order_price_amt      xxcos_edi_headers.invoice_order_price_amt%TYPE      -- (�`�[�v)�������z(����)
   ,invoice_shipping_price_amt   xxcos_edi_headers.invoice_shipping_price_amt%TYPE   -- (�`�[�v)�������z(�o��)
   ,invoice_stockout_price_amt   xxcos_edi_headers.invoice_stockout_price_amt%TYPE   -- (�`�[�v)�������z(���i)
   ,edi_delivery_schedule_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE   -- EDI�[�i�\�著�M�σt���O
  );
--
  -- EDI���׏��
  TYPE g_edi_line_rtype IS RECORD(
    edi_line_info_id     xxcos_edi_lines.edi_line_info_id%TYPE     -- EDI���׏��ID
   ,edi_header_info_id   xxcos_edi_lines.edi_header_info_id%TYPE   -- EDI�w�b�_���ID
   ,line_no              xxcos_edi_lines.line_no%TYPE              -- �sNo
   ,stockout_class       xxcos_edi_lines.stockout_class%TYPE       -- ���i�敪
   ,stockout_reason      xxcos_edi_lines.stockout_reason%TYPE      -- ���i���R
   ,product_code_itouen  xxcos_edi_lines.product_code_itouen%TYPE  -- ���i�R�[�h(�ɓ���)
   ,jan_code             xxcos_edi_lines.jan_code%TYPE             -- JAN�R�[�h
   ,itf_code             xxcos_edi_lines.itf_code%TYPE             -- ITF�R�[�h
   ,prod_class           xxcos_edi_lines.prod_class%TYPE           -- ���i�敪
   ,product_name         xxcos_edi_lines.product_name%TYPE         -- ���i��(����)
   ,product_name2_alt    xxcos_edi_lines.product_name2_alt%TYPE    -- ���i��2(�J�i)
   ,item_standard2       xxcos_edi_lines.item_standard2%TYPE       -- �K�i2
   ,num_of_cases         xxcos_edi_lines.num_of_cases%TYPE         -- �P�[�X����
   ,num_of_ball          xxcos_edi_lines.num_of_ball%TYPE          -- �{�[������
   ,indv_order_qty       xxcos_edi_lines.indv_order_qty%TYPE       -- ��������(�o��)
   ,case_order_qty       xxcos_edi_lines.case_order_qty%TYPE       -- ��������(�P�[�X)
   ,ball_order_qty       xxcos_edi_lines.ball_order_qty%TYPE       -- ��������(�{�[��)
   ,sum_order_qty        xxcos_edi_lines.sum_order_qty%TYPE        -- ��������(���v�A�o��)
   ,indv_shipping_qty    xxcos_edi_lines.indv_shipping_qty%TYPE    -- �o�א���(�o��)
   ,case_shipping_qty    xxcos_edi_lines.case_shipping_qty%TYPE    -- �o�א���(�P�[�X)
   ,ball_shipping_qty    xxcos_edi_lines.ball_shipping_qty%TYPE    -- �o�א���(�{�[��)
   ,pallet_shipping_qty  xxcos_edi_lines.pallet_shipping_qty%TYPE  -- �o�א���(�p���b�g)
   ,sum_shipping_qty     xxcos_edi_lines.sum_shipping_qty%TYPE     -- �o�א���(���v�A�o��)
   ,indv_stockout_qty    xxcos_edi_lines.indv_stockout_qty%TYPE    -- ���i����(�o��)
   ,case_stockout_qty    xxcos_edi_lines.case_stockout_qty%TYPE    -- ���i����(�P�[�X)
   ,ball_stockout_qty    xxcos_edi_lines.ball_stockout_qty%TYPE    -- ���i����(�{�[��)
   ,sum_stockout_qty     xxcos_edi_lines.sum_stockout_qty%TYPE     -- ���i����(���v�A�o��)
   ,shipping_unit_price  xxcos_edi_lines.shipping_unit_price%TYPE  -- ���P��(�o��)
   ,shipping_cost_amt    xxcos_edi_lines.shipping_cost_amt%TYPE    -- �������z(�o��)
   ,stockout_cost_amt    xxcos_edi_lines.stockout_cost_amt%TYPE    -- �������z(���i)
   ,shipping_price_amt   xxcos_edi_lines.shipping_price_amt%TYPE   -- �������z(�o��)
   ,stockout_price_amt   xxcos_edi_lines.stockout_price_amt%TYPE   -- �������z(���i)
   ,general_add_item1    xxcos_edi_lines.general_add_item1%TYPE    -- �ėp�t������1
   ,general_add_item2    xxcos_edi_lines.general_add_item2%TYPE    -- �ėp�t������2
   ,general_add_item3    xxcos_edi_lines.general_add_item3%TYPE    -- �ėp�t������3
   ,item_code            xxcos_edi_lines.item_code%TYPE            -- �i�ڃR�[�h
  );
--
  -- ���R�[�h��`
  gt_header_data        g_header_data_rtype;    -- �w�b�_���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^�錾
  -- ===============================
  TYPE g_edi_order_cur_ttype  IS TABLE OF edi_order_cur%ROWTYPE  INDEX BY BINARY_INTEGER;  -- EDI�󒍃f�[�^
  TYPE g_edi_header_ttype     IS TABLE OF g_edi_header_rtype     INDEX BY BINARY_INTEGER;  -- EDI�w�b�_���
  TYPE g_edi_line_ttype       IS TABLE OF g_edi_line_rtype       INDEX BY BINARY_INTEGER;  -- EDI���׏��
  TYPE g_data_record_ttype    IS TABLE OF VARCHAR2(32767)        INDEX BY BINARY_INTEGER;  -- �ҏW��̃f�[�^�擾�p
  TYPE g_data_ttype           IS TABLE OF xxcos_common2_pkg.g_layout_ttype  INDEX BY BINARY_INTEGER;  -- �[�i�\��f�[�^
--
  -- �e�[�u����`
  gt_edi_order_tab    g_edi_order_cur_ttype;  -- EDI�󒍃f�[�^
  gt_edi_header_tab   g_edi_header_ttype;     -- EDI�w�b�_���
  gt_edi_line_tab     g_edi_line_ttype;       -- EDI���׏��
  gt_data_record_tab  g_data_record_ttype;    -- �ҏW��̃f�[�^�擾�p
  gt_data_tab         g_data_ttype;           -- �[�i�\��f�[�^
--
  /**********************************************************************************
   * Procedure Name   : check_param
   * Description      : �p�����[�^�`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE check_param(
    iv_file_name        IN  VARCHAR2,     --   1.�t�@�C����
    iv_make_class       IN  VARCHAR2,     --   2.�쐬�敪
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI�`���ǔ�
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI�`���ǔ�(�t�@�C�����p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,     --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,     --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,     --   9.�n��R�[�h
    iv_center_date      IN  VARCHAR2,     --  10.�Z���^�[�[�i��
    iv_delivery_time    IN  VARCHAR2,     --  11.�[�i����
    iv_delivery_charge  IN  VARCHAR2,     --  12.�[�i�S����
    iv_carrier_means    IN  VARCHAR2,     --  13.�A����i
    iv_proc_date        IN  VARCHAR2,     --  14.������
    iv_proc_time        IN  VARCHAR2,     --  15.��������
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param'; -- �v���O������
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
    lv_param_msg   VARCHAR2(5000);  -- �p�����[�^�[�o�͗p
    lv_tkn_value1  VARCHAR2(50);    -- �g�[�N���擾�p1
    lv_tkn_value2  VARCHAR2(50);    -- �g�[�N���擾�p2
    ln_err_chk     NUMBER(1);       -- �G���[�`�F�b�N�p
    lv_err_msg     VARCHAR2(5000);  -- �G���[�o�͗p
    lt_make_class  fnd_lookup_values_vl.meaning%TYPE;  -- �쐬�敪
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
    --==============================================================
    -- �R���J�����g�̋��ʂ̏����o��
    --==============================================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �u�쐬�敪�v���A'���M'��'���x���쐬'�̏ꍇ
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- �p�����[�^�o�̓��b�Z�[�W�擾
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_param1      -- �p�����[�^�[�o��
                        ,iv_token_name1  => cv_tkn_param01     -- �g�[�N���R�[�h�P
                        ,iv_token_value1 => iv_make_class      -- �쐬�敪
                        ,iv_token_name2  => cv_tkn_param02     -- �g�[�N���R�[�h�Q
                        ,iv_token_value2 => iv_edi_c_code      -- EDI�`�F�[���X�R�[�h
                        ,iv_token_name3  => cv_tkn_param03     -- �g�[�N���R�[�h�R
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_value3 => iv_edi_f_number    -- EDI�`���ǔ�
--                        ,iv_token_name4  => cv_tkn_param04     -- �g�[�N���R�[�h�S
--                        ,iv_token_value4 => iv_shop_date_from  -- �X�ܔ[�i��From
--                        ,iv_token_name5  => cv_tkn_param05     -- �g�[�N���R�[�h�T
--                        ,iv_token_value5 => iv_shop_date_to    -- �X�ܔ[�i��To
--                        ,iv_token_name6  => cv_tkn_param06     -- �g�[�N���R�[�h�U
--                        ,iv_token_value6 => iv_sale_class      -- ��ԓ����敪
--                        ,iv_token_name7  => cv_tkn_param07     -- �g�[�N���R�[�h�V
--                        ,iv_token_value7 => iv_area_code       -- �n��R�[�h
--                        ,iv_token_name8  => cv_tkn_param08     -- �g�[�N���R�[�h�W
--                        ,iv_token_value8 => iv_center_date     -- �Z���^�[�[�i��
                        ,iv_token_value3 => iv_edi_f_number_f  -- EDI�`���ǔ�(�t�@�C�����p)
                        ,iv_token_name4  => cv_tkn_param04     -- �g�[�N���R�[�h�S
                        ,iv_token_value4 => iv_edi_f_number_s  -- EDI�`���ǔ�(���o�����p)
                        ,iv_token_name5  => cv_tkn_param05     -- �g�[�N���R�[�h�T
                        ,iv_token_value5 => iv_shop_date_from  -- �X�ܔ[�i��From
                        ,iv_token_name6  => cv_tkn_param06     -- �g�[�N���R�[�h�U
                        ,iv_token_value6 => iv_shop_date_to    -- �X�ܔ[�i��To
                        ,iv_token_name7  => cv_tkn_param07     -- �g�[�N���R�[�h�V
                        ,iv_token_value7 => iv_sale_class      -- ��ԓ����敪
                        ,iv_token_name8  => cv_tkn_param08     -- �g�[�N���R�[�h�W
                        ,iv_token_value8 => iv_area_code       -- �n��R�[�h
                        ,iv_token_name9  => cv_tkn_param09     -- �g�[�N���R�[�h�X
                        ,iv_token_value9 => iv_center_date     -- �Z���^�[�[�i��
/* 2009/05/12 Ver1.8 Mod End   */
                      );
      lv_param_msg := lv_param_msg ||
                      xxccp_common_pkg.get_msg(
                         iv_application  => cv_application      -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_param2       -- �p�����[�^�[�o��
/* 2009/05/12 Ver1.8 Mod Start */
--                        ,iv_token_name1  => cv_tkn_param09      -- �g�[�N���R�[�h�X
                        ,iv_token_name1  => cv_tkn_param10      -- �g�[�N���R�[�h�P�O
                        ,iv_token_value1 => iv_delivery_time    -- �[�i����
--                        ,iv_token_name2  => cv_tkn_param10      -- �g�[�N���R�[�h�P�O
                        ,iv_token_name2  => cv_tkn_param11      -- �g�[�N���R�[�h�P�P
                        ,iv_token_value2 => iv_delivery_charge  -- �[�i�S����
--                        ,iv_token_name3  => cv_tkn_param11      -- �g�[�N���R�[�h�P�P
                        ,iv_token_name3  => cv_tkn_param12      -- �g�[�N���R�[�h�P�Q
                        ,iv_token_value3 => iv_carrier_means    -- �A����i
/* 2009/05/12 Ver1.8 Mod End   */
                      );
    -- �u�쐬�敪�v���A'����'�̏ꍇ
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- �p�����[�^�o�̓��b�Z�[�W�擾
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_param3      -- �p�����[�^�[�o��
                        ,iv_token_name1  => cv_tkn_param01     -- �g�[�N���R�[�h�P
                        ,iv_token_value1 => iv_make_class      -- �쐬�敪
                        ,iv_token_name2  => cv_tkn_param02     -- �g�[�N���R�[�h�Q
                        ,iv_token_value2 => iv_edi_c_code      -- EDI�`�F�[���X�R�[�h
                        ,iv_token_name3  => cv_tkn_param03     -- �g�[�N���R�[�h�R
                        ,iv_token_value3 => iv_proc_date       -- ������
                        ,iv_token_name4  => cv_tkn_param04     -- �g�[�N���R�[�h�S
                        ,iv_token_value4 => iv_proc_time       -- ��������
                      );
    END IF;
    -- �p�����[�^�����b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- �p�����[�^�����O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add Start */
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
    -- �t�@�C�������b�Z�[�W�擾
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_file_nmae   -- �t�@�C�����o��
                      ,iv_token_name1  => cv_tkn_file_name   -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => iv_file_name       -- �t�@�C����
                    );
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    ln_err_chk := cn_0;  -- �G���[�`�F�b�N�p�ϐ��̏�����
--
    --==============================================================
    -- �K�{�`�F�b�N
    --==============================================================
    -- �u�쐬�敪�v���ANULL�̏ꍇ
    IF ( iv_make_class IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_param1  -- �쐬�敪
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                      ,iv_token_value1 => lv_tkn_value1      -- �쐬�敪
                     );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �uEDI�`�F�[���X�R�[�h�v���ANULL�̏ꍇ
    IF ( iv_edi_c_code IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_param2  -- EDI�`�F�[���X�R�[�h
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                      ,iv_token_value1 => lv_tkn_value1      -- EDI�`�F�[���X�R�[�h
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    --==============================================================
    -- �쐬�敪���e�`�F�b�N
    --==============================================================
    BEGIN
      SELECT flvv.meaning     meaning     -- �쐬�敪
      INTO   lt_make_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_shipping_exp_t
      AND    flvv.lookup_code        = iv_make_class
      AND    flvv.enabled_flag       = cv_y                -- �L��
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_param1  -- �쐬�敪
                         );
        -- ���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application    -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_param_err  -- ���̓p�����[�^�s���G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_in_param   -- ���̓p�����[�^��
                        ,iv_token_value1 => lv_tkn_value1     -- �쐬�敪
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- �u�쐬�敪�v���A'���M'��'���x���쐬'�̏ꍇ�̃`�F�b�N
    --==============================================================
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- �u�t�@�C�����v�uEDI�`���ǔ�(�t�@�C�����p)�v�uEDI�`���ǔ�(���o�����p)�v�u�X�ܔ[�i��From�v�u�X�ܔ[�i��To�v�̂����ꂩ���ANull�̏ꍇ
      IF ( iv_file_name      IS NULL )
/* 2009/05/12 Ver1.8 Mod Start */
--      OR ( iv_edi_f_number   IS NULL )
      OR ( iv_edi_f_number_f IS NULL )
      OR ( iv_edi_f_number_s IS NULL )
/* 2009/05/12 Ver1.8 Mod End   */
      OR ( iv_shop_date_from IS NULL )
      OR ( iv_shop_date_to   IS NULL )
      THEN
        -- �u�t�@�C�����v���ANULL�̏ꍇ
        IF ( iv_file_name IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param3  -- �t�@�C����
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- �t�@�C����
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- �uEDI�`���ǔ�(�t�@�C�����p)�v���ANULL�̏ꍇ
/* 2009/05/12 Ver1.8 Mod Start */
--        IF ( iv_edi_f_number IS NULL ) THEN
        IF ( iv_edi_f_number_f IS NULL ) THEN
/* 2009/05/12 Ver1.8 Mod End   */
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param4  -- EDI�`���ǔ�(�t�@�C�����p)
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- EDI�`���ǔ�(�t�@�C�����p)
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
/* 2009/05/12 Ver1.8 Add Start */
        -- �uEDI�`���ǔ�(���o�����p)�v���ANULL�̏ꍇ
        IF ( iv_edi_f_number_s IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param10 -- EDI�`���ǔ�(���o�����p)
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- EDI�`���ǔ�(���o�����p)
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
/* 2009/05/12 Ver1.8 Add End   */
--
        -- �u�X�ܔ[�i��From�v���ANULL�̏ꍇ
        IF ( iv_shop_date_from IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param5  -- �X�ܔ[�i��From
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- �X�ܔ[�i��From
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- �u�X�ܔ[�i��To�v���ANULL�̏ꍇ
        IF ( iv_shop_date_to IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param6  -- �X�ܔ[�i��To
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- �X�ܔ[�i��To
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
--
      -- �u�X�ܔ[�i��From�v���u�X�ܔ[�i��To�v��薢�����t�̏ꍇ
      IF ( iv_shop_date_from > iv_shop_date_to ) THEN
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_param5  -- �X�ܔ[�i��From
                         );
        -- �g�[�N���擾
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_param6  -- �X�ܔ[�i��To
                         );
        -- ���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_date_reverse  -- ���t�t�]�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_date_from     -- ���t���ԃ`�F�b�N�̊J�n��
                        ,iv_token_value1 => lv_tkn_value1        -- �X�ܔ[�i��From
                        ,iv_token_name2  => cv_tkn_date_to       -- ���t���ԃ`�F�b�N�̏I����
                        ,iv_token_value2 => lv_tkn_value2        -- �X�ܔ[�i��To
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- �G���[�L��
      END IF;
--
      -- �u�Z���^�[�[�i���v�����͂���Ă��āA
      -- �u�Z���^�[�[�i���v���u�X�ܔ[�i��To�v��薢�����t�̏ꍇ
      IF  ( iv_center_date IS NOT NULL )
      AND ( iv_center_date > iv_shop_date_to )
      THEN
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_param9  -- �Z���^�[�[�i��
                         );
        -- �g�[�N���擾
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_param6  -- �X�ܔ[�i��To
                         );
        -- ���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_date_reverse  -- ���t�t�]�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_date_from     -- ���t���ԃ`�F�b�N�̊J�n��
                        ,iv_token_value1 => lv_tkn_value1        -- �Z���^�[�[�i��
                        ,iv_token_name2  => cv_tkn_date_to       -- ���t���ԃ`�F�b�N�̏I����
                        ,iv_token_value2 => lv_tkn_value2        -- �X�ܔ[�i��To
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- �G���[�L��
      END IF;
    END IF;
--
    --==============================================================
    -- �u�쐬�敪�v���A'����'�̏ꍇ�̃`�F�b�N
    --==============================================================
    IF ( iv_make_class = cv_make_class_release ) THEN
      -- �u�������v�u���������v�̂����ꂩ���ANull�̏ꍇ
      IF ( iv_proc_date IS NULL )
      OR ( iv_proc_time IS NULL )
      THEN
        -- �u�������v���ANULL�̏ꍇ
        IF ( iv_proc_date IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param7  -- ������
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- ������
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        -- �u���������v���ANULL�̏ꍇ
        IF ( iv_proc_time IS NULL ) THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application     -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_param8  -- ��������
                           );
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_param_null  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_in_param    -- ���̓p�����[�^��
                          ,iv_token_value1 => lv_tkn_value1      -- ��������
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
        END IF;
--
        RAISE global_api_others_expt;
--
      END IF;
    END IF;
--
    --==============================================================
    -- �G���[�̏ꍇ
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
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
  END check_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    iv_make_class IN  VARCHAR2,     --   �쐬�敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn_value1  VARCHAR2(50);    -- �g�[�N���擾�p1
    lv_tkn_value2  VARCHAR2(50);    -- �g�[�N���擾�p2
    ln_err_chk     NUMBER(1);       -- �G���[�`�F�b�N�p
    lv_err_msg     VARCHAR2(5000);  -- �G���[�o�͗p
    lv_l_meaning   fnd_lookup_values_vl.meaning%TYPE;  -- �N�C�b�N�R�[�h�����擾�p
    lv_dummy       VARCHAR2(1);     -- ���C�A�E�g��`��CSV�w�b�_�[�p(�t�@�C���^�C�v���Œ蒷�Ȃ̂Ŏg�p����Ȃ�)
-- ************ 2009/09/03 N.Maeda 1.12 ADD START ***************** --
    lt_item_div_h  fnd_profile_option_values.profile_option_value%TYPE;  -- �{�А��i�敪
-- ************ 2009/09/03 N.Maeda 1.12 ADD  END  ***************** --
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
    -- �u�쐬�敪�v���A'����'�̏ꍇ
    IF ( iv_make_class = cv_make_class_release ) THEN
      RETURN;
    END IF;
--
    ln_err_chk     := cn_0;  -- �G���[�`�F�b�N�p�ϐ��̏�����
    -- �J�E���^�̏�����
    gn_dat_rec_cnt := cn_0;  -- �o�̓f�[�^�p
    gn_head_cnt    := cn_0;  -- EDI�w�b�_���p
    gn_line_cnt    := cn_0;  -- EDI���׏��p
--
    --==============================================================
    -- �V�X�e�����t�擾
    --==============================================================
    gv_f_o_date := TO_CHAR( cd_sysdate, cv_date_format );  -- ������
    gv_f_o_time := TO_CHAR( cd_sysdate, cv_time_format );  -- ��������
--
    --==============================================================
    -- �v���t�@�C�����擾
    --==============================================================
    -- �w�b�_���R�[�h�敪
    gv_if_header := FND_PROFILE.VALUE( cv_prf_if_header );
    IF ( gv_if_header IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf1  -- XXCCP:IF���R�[�h�敪_�w�b�_
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �f�[�^���R�[�h�敪
    gv_if_data := FND_PROFILE.VALUE( cv_prf_if_data );
    IF ( gv_if_data IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf2  -- XXCCP:IF���R�[�h�敪_�f�[�^
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �t�b�^���R�[�h�敪
    gv_if_footer := FND_PROFILE.VALUE( cv_prf_if_footer );
    IF ( gv_if_footer IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf3  -- XXCCP:IF���R�[�h�敪_�t�b�^
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- UTL_MAX�s�T�C�Y
    gv_utl_m_line := FND_PROFILE.VALUE( cv_prf_utl_m_line );
    IF ( gv_utl_m_line IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf4  -- XXCOS:UTL_MAX�s�T�C�Y
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �A�E�g�o�E���h�p�f�B���N�g���p�X
    gv_outbound_d := FND_PROFILE.VALUE( cv_prf_outbound_d );
    IF ( gv_outbound_d IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf5  -- XXCOS:EDI�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- ��Ж�
    gv_company_name := FND_PROFILE.VALUE( cv_prf_company_name );
    IF ( gv_company_name IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf6  -- XXCOS:��Ж�
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- ��Ж��J�i
    gv_company_kana := FND_PROFILE.VALUE( cv_prf_company_kana );
    IF ( gv_company_kana IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf7  -- XXCOS:��Ж��J�i
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �P�[�X�P�ʃR�[�h
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom_code );
    IF ( gv_case_uom_code IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf8  -- XXCOS:�P�[�X�P�ʃR�[�h
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �{�[���P�ʃR�[�h
    gv_ball_uom_code := FND_PROFILE.VALUE( cv_prf_ball_uom_code );
    IF ( gv_ball_uom_code IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf9  -- XXCOS:�{�[���P�ʃR�[�h
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �݌ɑg�D�R�[�h
    gv_organization := FND_PROFILE.VALUE( cv_prf_organization );
    IF ( gv_organization IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf10  -- XXCOI:�݌ɑg�D�R�[�h
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- MAX���t
    gd_max_date := TO_DATE( FND_PROFILE.VALUE( cv_prf_max_date ), cv_max_date_format );
    IF ( gd_max_date IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf11  -- XXCOS:MAX���t
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- ��v����ID
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    IF ( gn_bks_id IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf12  -- GL��v����ID
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    -- �c�ƒP��
    gn_org_id      := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf13  -- �c�ƒP��
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
-- 2009/05/22 Ver1.9 Add Start
    gn_dum_stock_out := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_dum_stock_out ) );
    IF ( gn_dum_stock_out IS NULL ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_prf14  -- EDI�[�i�\��_�~�[���i�敪
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
-- 2009/05/22 Ver1.9 Add End
    --==============================================================
    -- �}�X�^���擾
    --==============================================================
    -- �f�[�^����
    BEGIN
      SELECT flvv.meaning     meaning     -- �f�[�^��
            ,flvv.attribute1  attribute1  -- IF���Ɩ��n��R�[�h
      INTO   gt_data_type_code
            ,gt_from_series
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_data_type_code_t
/* 2009/05/12 Ver1.8 Mod Start */
/* 2009/02/27 Ver1.5 Mod Start */
      AND    flvv.lookup_code        = cv_data_type_code_c
--      AND (( iv_make_class           = cv_make_class_transe
--      AND    flvv.lookup_code        = cv_data_type_code_c )
--      OR   ( iv_make_class           = cv_make_class_label
--     AND    flvv.lookup_code        = cv_data_type_code_l ))
/* 2009/02/27 Ver1.5 Mod  End  */
/* 2009/05/12 Ver1.8 Mod  End  */
      AND    flvv.enabled_flag       = cv_y                -- �L��
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_tbl1  -- �N�C�b�N�R�[�h
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_column1  -- �f�[�^��R�[�h
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_mast_err  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_value1    -- �N�C�b�N�R�[�h
                        ,iv_token_name2  => cv_tkn_column    -- �g�[�N���R�[�h�Q
                        ,iv_token_value2 => lv_tkn_value2    -- �f�[�^��R�[�h
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- �G���[�L��
    END;
--
    -- EDI�}�̋敪
    BEGIN
      -- ���b�Z�[�W�����e���擾
      lv_l_meaning := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_l_meaning2  -- �N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
                      );
      -- �N�C�b�N�R�[�h�擾
      SELECT flvv.lookup_code      lookup_code
      INTO   gt_edi_media_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_media_class_t
      AND    flvv.meaning            = lv_l_meaning
      AND    flvv.enabled_flag       = cv_y                -- �L��
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_tbl1  -- �N�C�b�N�R�[�h
                         );
        lv_tkn_value2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application      -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_column2  -- EDI�}�̋敪
                         );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application   -- �A�v���P�[�V����
                        ,iv_name         => cv_msg_mast_err  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_value1    -- �N�C�b�N�R�[�h
                        ,iv_token_name2  => cv_tkn_column    -- �g�[�N���R�[�h�Q
                        ,iv_token_value2 => lv_tkn_value2    -- EDI�}�̋敪
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        lv_errbuf  := SQLERRM;
        ln_err_chk := cn_1;  -- �G���[�L��
    END;
--
    --==============================================================
    -- �t�@�C�����C�A�E�g���擾
    --==============================================================
    -- ���C�A�E�g��`���
    xxcos_common2_pkg.get_layout_info(
       iv_file_type        =>  cv_0                -- �t�@�C���`��(�Œ蒷)
      ,iv_layout_class     =>  cv_0                -- ���敪(�󒍌n)
      ,ov_data_type_table  =>  gt_data_type_table  -- �f�[�^�^�\
      ,ov_csv_header       =>  lv_dummy            -- CSV�w�b�_
      ,ov_errbuf           =>  lv_errbuf           -- �G���[���b�Z�[�W
      ,ov_retcode          =>  lv_retcode          -- ���^�[���R�[�h
      ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_layout  -- �󒍌n���ڃ��C�A�E�g
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application       -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_file_inf_err  -- IF�t�@�C�����C�A�E�g��`���擾�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_layout        -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1        -- �󒍌n���ڃ��C�A�E�g
                   );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
    --==============================================================
    -- �݌ɑg�DID�擾
    --==============================================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_organization  -- �݌ɑg�D�R�[�h
                          );
    IF ( gn_organization_id IS NULL ) THEN
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application   -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_org_err   -- �݌ɑg�DID�擾�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_org_code  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => gv_organization  -- �݌ɑg�D�R�[�h
                   );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      ln_err_chk := cn_1;  -- �G���[�L��
    END IF;
--
-- ********** 2009/09/03 1.12 N.Maeda ADD START ********** --
    -- =============================================================
    -- �v���t�@�C���uXXCOS:�{�Џ��i�敪�v�擾
    -- =============================================================
    lt_item_div_h := FND_PROFILE.VALUE(ct_item_div_h);
--
    IF ( lt_item_div_h IS NULL ) THEN
--
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application    -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_item_div_h  -- �{�А��i�敪
                       );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application  -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_prf_err  -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile  -- �g�[�N���R�[�h�P
                      ,iv_token_value1 => lv_tkn_value1   -- �v���t�@�C����
                    );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
      lv_errbuf  := lv_err_msg;
      ln_err_chk := cn_1;  -- �G���[�L��
--
    ELSE
      -- =============================================================
      -- �J�e�S���Z�b�gID�擾
      -- =============================================================
      BEGIN
        SELECT  mcst.category_set_id
        INTO    gt_category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
      EXCEPTION
        WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_msg_category_err
                           );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- �G���[�L��
      END;
--
    END IF;
-- ********** 2009/09/03 1.12 N.Maeda ADD  END  ********** --
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
    BEGIN
      SELECT oos.order_source_id     order_source_id    -- �󒍃\�[�XID
      INTO   gt_order_source_online
      FROM   oe_order_sources        oos                -- �󒍃\�[�X�e�[�u��
      WHERE  oos.name                = cv_online
      AND    oos.enabled_flag        = cv_y;
    EXCEPTION
      WHEN OTHERS THEN
          lv_err_msg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application,
                           iv_name         =>  cv_get_order_source_id_err,
                           iv_token_name1  =>  cv_order_source,
                           iv_token_value1 =>  cv_online
                           );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          lv_errbuf  := lv_err_msg;
          ln_err_chk := cn_1;  -- �G���[�L��
      END;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--
    --==============================================================
    -- �G���[�̏ꍇ
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_data_check_expt;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�`�F�b�N�G���[ ***
    WHEN global_data_check_expt THEN
      -- �l��NULL�A�������͑ΏۊO
      IF ( lv_errbuf IS NULL ) THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- ���̑���O
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
   * Procedure Name   : get_manual_order
   * Description      : ����̓f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE get_manual_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI�`���ǔ�(���o�����p)
    iv_shop_date_from   IN  VARCHAR2,     --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,     --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,     --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,     --   9.�n��R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_manual_order'; -- �v���O������
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
    lv_tkn_value1  VARCHAR2(50);    -- �g�[�N���擾�p1
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
    --==============================================================
    -- ����̓f�[�^�o�^
    --==============================================================
    xxcos_edi_common_pkg.edi_manual_order_acquisition(
       iv_edi_chain_code          => iv_edi_c_code                               -- EDI�`�F�[���X�R�[�h
      ,iv_edi_forward_number      => iv_edi_f_number                             -- EDI�`���ǔ�
      ,id_shop_delivery_date_from => TO_DATE(iv_shop_date_from, cv_date_format)  -- �X�ܔ[�i��(From)
      ,id_shop_delivery_date_to   => TO_DATE(iv_shop_date_to, cv_date_format)    -- �X�ܔ[�i��(To)
      ,iv_regular_ar_sale_class   => iv_sale_class                               -- ��ԓ����敪
      ,iv_area_code               => iv_area_code                                -- �n��R�[�h
      ,id_center_delivery_date    => NULL                                        -- �Z���^�[�[�i��
      ,in_organization_id         => gn_organization_id                          -- �݌ɑg�DID
      ,ov_errbuf                  => lv_errbuf                                   -- �G���[�E���b�Z�[�W
      ,ov_retcode                 => lv_retcode                                  -- ���^�[���E�R�[�h
      ,ov_errmsg                  => lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_err_msg       -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_errmsg            -- �G���[�E���b�Z�[�W
                   );
      RAISE global_api_others_expt;
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
  END get_manual_order;
--
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : �t�@�C����������(A-4)
   ***********************************************************************************/
  PROCEDURE output_header(
    iv_file_name        IN  VARCHAR2,     --   1.�t�@�C����
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI�`���ǔ�(�t�@�C�����p)
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header'; -- �v���O������
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
/* 2009/04/28 Ver1.7 Mod Start */
--    lv_header_output  VARCHAR2(1000);  -- �w�b�_�[�o�͗p
    lv_header_output  VARCHAR2(5000);  -- �w�b�_�[�o�͗p
/* 2009/04/28 Ver1.7 Mod End   */
    ln_dummy          NUMBER;          -- �w�b�_�o�͂̃��R�[�h�����p(�g�p����Ȃ�)
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���_���
    CURSOR cust_base_cur
    IS
      SELECT  hca.account_number             delivery_base_code      -- �[�i���_�R�[�h
             ,hp.party_name                  delivery_base_name      -- �[�i���_��
             ,hp.organization_name_phonetic  delivery_base_phonetic  -- �[�i���_���J�i
      FROM    hz_cust_accounts        hca   -- ���_(�ڋq)
             ,hz_parties              hp    -- ���_(�p�[�e�B)
             ,hz_party_sites          hps   -- �p�[�e�B�T�C�g
             ,hz_cust_acct_sites_all  hcas  -- �ڋq���ݒn
      WHERE   hcas.party_site_id  = hps.party_site_id     -- ����(�ڋq���ݒn = �p�[�e�B�T�C�g)
      AND     hca.cust_account_id = hcas.cust_account_id  -- ����(���_(�ڋq) = �ڋq���ݒn)
      AND     hca.party_id        = hp.party_id           -- ����(���_(�ڋq) = ���_(�p�[�e�B))
      AND     hcas.org_id         = gn_org_id             -- �c�ƒP��
      AND     hca.account_number  =
/* 2010/02/26 Ver1.15 Mod Start */
--                ( SELECT  xca1.delivery_base_code
--                  FROM    hz_cust_accounts     hca1  -- �ڋq
--                         ,hz_parties           hp1   -- �p�[�e�B
--                         ,xxcmm_cust_accounts  xca1  -- �ڋq�ǉ����
--                  WHERE   hp1.duns_number_c       IN (cv_cust_status_30   -- �ڋq�X�e�[�^�X(���F��)
--                                                     ,cv_cust_status_40)  -- �ڋq�X�e�[�^�X(�ڋq)
--                  AND     hca1.party_id            =  hp1.party_id        -- ����(�ڋq = �p�[�e�B)
--                  AND     hca1.status              =  cv_status_a         -- �X�e�[�^�X(�ڋq�L��)
--                  AND     hca1.customer_class_code =  cv_cust_code_cust   -- �ڋq�敪(�ڋq)
--                  AND     hca1.cust_account_id     =  xca1.customer_id    -- ����(�ڋq = �ڋq�ǉ�)
--                  AND     xca1.chain_store_code    =  iv_edi_c_code       -- EDI�`�F�[���X�R�[�h
--                  AND     ROWNUM                   =  cn_1
--                )
                ( SELECT xuif.base_code  AS base_code     -- ���O�C�����[�U�[�̋��_�R�[�h(�V)
                  FROM   xxcos_user_info_v xuif           -- ���[�U���r���[
                  WHERE  xuif.user_id = cn_created_by     -- ���O�C�����[�U�[
                )
/* 2010/02/26 Ver1.15 Mod  End  */
      ;
    -- EDI�`�F�[���X���
    CURSOR edi_chain_cur
    IS
      SELECT  hp.party_name                  edi_chain_name      -- EDI�`�F�[���X��
             ,hp.organization_name_phonetic  edi_chain_phonetic  -- EDI�`�F�[���X���J�i
      FROM    hz_parties           hp    -- �p�[�e�B
             ,hz_cust_accounts     hca   -- �ڋq
             ,xxcmm_cust_accounts  xca   -- �ڋq�ǉ����
      WHERE   hca.party_id            = hp.party_id         -- ����(�ڋq = �p�[�e�B)
      AND     hca.customer_class_code = cv_cust_code_chain  -- �ڋq�敪(�`�F�[���X)
      AND     hca.cust_account_id     = xca.customer_id     -- ����(�ڋq = �ڋq�ǉ�)
      AND     hca.status              = cv_status_a         -- �X�e�[�^�X(�ڋq�L��)
      AND     xca.chain_store_code    = iv_edi_c_code       -- EDI�`�F�[���X�R�[�h
      ;
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
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                        location      =>  gv_outbound_d  -- �A�E�g�o�E���h�p�f�B���N�g���p�X
                       ,filename      =>  iv_file_name   -- �t�@�C����
                       ,open_mode     =>  cv_w           -- �I�[�v�����[�h
                       ,max_linesize  =>  gv_utl_m_line  -- MAX�T�C�Y
                     );
    EXCEPTION
      WHEN OTHERS THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- �A�v���P�[�V����
                       ,iv_name         => cv_msg_file_o_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_file_name   -- �g�[�N���R�[�h�P
                       ,iv_token_value1 => iv_file_name       -- �t�@�C����
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- �w�b�_���R�[�h�o��
    --==============================================================
    -- ���_���擾
    OPEN  cust_base_cur;
    FETCH cust_base_cur
      INTO  gt_header_data.delivery_base_code        -- �[�i���_�R�[�h
           ,gt_header_data.delivery_base_name        -- �[�i���_��
           ,gt_header_data.delivery_base_phonetic    -- �[�i���_���J�i
    ;
    -- �f�[�^���擾�ł��Ȃ��ꍇ�G���[
    IF ( cust_base_cur%NOTFOUND )THEN
      CLOSE cust_base_cur;
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_base_inf_err  -- ���_���擾�G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_code          -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => iv_edi_c_code        -- EDI�`�F�[���X�R�[�h
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE cust_base_cur;
--
    -- EDI�`�F�[���X���擾
    OPEN  edi_chain_cur;
    FETCH edi_chain_cur
      INTO  gt_header_data.edi_chain_name           -- EDI�`�F�[���X��
           ,gt_header_data.edi_chain_name_phonetic  -- EDI�`�F�[���X�J�i
    ;
    -- �f�[�^���擾�ł��Ȃ��ꍇ�G���[
    IF ( edi_chain_cur%NOTFOUND )THEN
      CLOSE edi_chain_cur;
      -- ���b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_chain_inf_err -- �`�F�[���X���擾�G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_chain_code    -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => iv_edi_c_code        -- EDI�`�F�[���X�R�[�h
                   );
      RAISE global_api_others_expt;
    END IF;
    CLOSE edi_chain_cur;
--
    --==============================================================
    -- EDI�w�b�_�t�^
    --==============================================================
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_header    -- �t�^�敪
      ,iv_from_series     =>  gt_from_series  -- IF���Ɩ��n��R�[�h
      ,iv_base_code       =>  gt_header_data.delivery_base_code
/* 2009/02/24 Ver1.2 Mod Start */
--    ,iv_base_name       =>  gt_header_data.delivery_base_name
      ,iv_base_name       =>  SUBSTRB(gt_header_data.delivery_base_name, 1, 40)
      ,iv_chain_code      =>  iv_edi_c_code
--    ,iv_chain_name      =>  gt_header_data.edi_chain_name
      ,iv_chain_name      =>  SUBSTRB(gt_header_data.edi_chain_name, 1, 40)
/* 2009/02/24 Ver1.2 Mod  End  */
      ,iv_data_kind       =>  gt_data_type_code
      ,iv_row_number      =>  iv_edi_f_number
      ,in_num_of_records  =>  ln_dummy
      ,ov_retcode         =>  lv_retcode
      ,ov_output          =>  lv_header_output
      ,ov_errbuf          =>  lv_errbuf
      ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_err_msg       -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_errmsg            -- �G���[�E���b�Z�[�W
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C���o��
    --==============================================================
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- �t�@�C���n���h��
      ,buffer => lv_header_output  -- �o�͕���(�w�b�_)
    );
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
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : input_edi_order
   * Description      : EDI�󒍃f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE input_edi_order(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
    iv_edi_f_number     IN  VARCHAR2,     --   5.EDI�`���ǔ�(���o�����p)
    iv_shop_date_from   IN  VARCHAR2,     --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,     --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,     --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,     --   9.�n��R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_edi_order'; -- �v���O������
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
    lv_tkn_value1  VARCHAR2(50);    -- �g�[�N���擾�p1
    lv_tkn_value2  VARCHAR2(50);    -- �g�[�N���擾�p2
    lv_err_msg     VARCHAR2(5000);  -- �G���[�o�͗p
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
    --==============================================================
    -- ���̓p�����[�^�������֐ݒ�
    --==============================================================
    gt_edi_c_code     := iv_edi_c_code;                               -- EDI�`�F�[���X�R�[�h
    gt_edi_f_number   := iv_edi_f_number;                             -- EDI�`���ǔ�
    gt_shop_date_from := TO_DATE(iv_shop_date_from, cv_date_format);  -- �X�ܔ[�i��From
    gt_shop_date_to   := TO_DATE(iv_shop_date_to, cv_date_format);    -- �X�ܔ[�i��To
    gt_sale_class     := iv_sale_class;                               -- ��ԓ����敪
    gt_area_code      := iv_area_code;                                -- �n��R�[�h
--
    --==============================================================
    -- EDI�󒍃f�[�^���o
    --==============================================================
    BEGIN
      OPEN  edi_order_cur;
      FETCH edi_order_cur BULK COLLECT INTO gt_edi_order_tab;
      CLOSE edi_order_cur;
    EXCEPTION
      -- *** ���b�N�G���[ ***
      WHEN lock_expt THEN
        -- �J�[�\���N���[�Y
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDI�w�b�_���e�[�u��
                         );
        -- ���b�Z�[�W�擾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- �A�v���P�[�V����
                       ,iv_name         => cv_msg_lock_err    -- ���b�N�G���[���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_value1      -- EDI�w�b�_���e�[�u��
                     );
        RAISE global_api_others_expt;
--
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �J�[�\���N���[�Y
        IF ( edi_order_cur%ISOPEN ) THEN
          CLOSE edi_order_cur;
        END IF;
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDI�w�b�_���e�[�u��
                         );
        -- ���b�Z�[�W�擾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V����
                       ,iv_name         => cv_msg_data_get_err  -- �f�[�^���o�G���[���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_value1        -- EDI�w�b�_���e�[�u��
                       ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                       ,iv_token_value2 => iv_edi_c_code        -- EDI�`�F�[���X�R�[�h
                     );
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    -- �����Ώۃ��R�[�h�����擾
    --==============================================================
    gn_target_cnt := gt_edi_order_tab.COUNT;
    IF ( gn_target_cnt = cn_0 ) THEN
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application    -- �A�v���P�[�V����
                      ,iv_name         => cv_msg_no_target  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
                   );
      -- ���b�Z�[�W�ɏo��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
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
  END input_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : format_data
   * Description      : �f�[�^���`(A-7)
   ***********************************************************************************/
  PROCEDURE format_data(
    iv_make_class       IN  VARCHAR2,               --   2.�쐬�敪
    ir_total_rec        IN  g_invoice_total_rtype,  -- �`�[�v
    it_head_id          IN  xxcos_edi_headers.edi_header_info_id%TYPE,          -- EDI�w�b�_���ID
    it_delivery_flag    IN  xxcos_edi_headers.edi_delivery_schedule_flag%TYPE,  -- EDI�[�i�\�著�M�σt���O
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'format_data'; -- �v���O������
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
    --==============================================================
    -- EDI�w�b�_���ҏW
    --==============================================================
    gn_head_cnt := gn_head_cnt + cn_1;
    gt_edi_header_tab(gn_head_cnt).edi_header_info_id          := it_head_id;                                     -- EDI�w�b�_���ID
    gt_edi_header_tab(gn_head_cnt).process_date                := TO_DATE(gv_f_o_date, cv_date_format);           -- ������
    gt_edi_header_tab(gn_head_cnt).process_time                := gv_f_o_time;                                    -- ��������
    gt_edi_header_tab(gn_head_cnt).base_code                   := gt_data_tab(cn_1)(cv_base_code);                -- ���_(����)�R�[�h
/* 2009/02/24 Ver1.2 Mod Start */
--  gt_edi_header_tab(gn_head_cnt).base_name                   := gt_data_tab(cn_1)(cv_base_name);                -- ���_��(������)
--  gt_edi_header_tab(gn_head_cnt).base_name_alt               := gt_data_tab(cn_1)(cv_base_name_alt);            -- ���_��(�J�i)
    gt_edi_header_tab(gn_head_cnt).base_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_base_name), 1, 40);      -- ���_��(������)
    gt_edi_header_tab(gn_head_cnt).base_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_base_name_alt), 1, 25);  -- ���_��(�J�i)
    gt_edi_header_tab(gn_head_cnt).customer_code               := gt_data_tab(cn_1)(cv_cust_code);                -- �ڋq�R�[�h
--  gt_edi_header_tab(gn_head_cnt).customer_name               := gt_data_tab(cn_1)(cv_cust_name);                -- �ڋq��(����)
--  gt_edi_header_tab(gn_head_cnt).customer_name_alt           := gt_data_tab(cn_1)(cv_cust_name_alt);            -- �ڋq��(�J�i)
    gt_edi_header_tab(gn_head_cnt).customer_name               := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name), 1, 100);     -- �ڋq��(����)
    gt_edi_header_tab(gn_head_cnt).customer_name_alt           := SUBSTRB(gt_data_tab(cn_1)(cv_cust_name_alt), 1, 50);  -- �ڋq��(�J�i)
    gt_edi_header_tab(gn_head_cnt).shop_code                   := gt_data_tab(cn_1)(cv_shop_code);                -- �X�R�[�h
--  gt_edi_header_tab(gn_head_cnt).shop_name                   := gt_data_tab(cn_1)(cv_shop_name);                -- �X��(����)
--  gt_edi_header_tab(gn_head_cnt).shop_name_alt               := gt_data_tab(cn_1)(cv_shop_name_alt);            -- �X��(�J�i)
    gt_edi_header_tab(gn_head_cnt).shop_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name), 1, 40);      -- �X��(����)
    gt_edi_header_tab(gn_head_cnt).shop_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_shop_name_alt), 1, 20);  -- �X��(�J�i)
    gt_edi_header_tab(gn_head_cnt).center_delivery_date        := TO_DATE(gt_data_tab(cn_1)(cv_cent_delv_date), cv_date_format);  -- �Z���^�[�[�i��
    gt_edi_header_tab(gn_head_cnt).order_no_ebs                := gt_data_tab(cn_1)(cv_order_no_ebs);             -- ��No(EBS)
    gt_edi_header_tab(gn_head_cnt).contact_to                  := gt_data_tab(cn_1)(cv_contact_to);               -- �A����
    gt_edi_header_tab(gn_head_cnt).area_code                   := gt_data_tab(cn_1)(cv_area_code);                -- �n��R�[�h
--  gt_edi_header_tab(gn_head_cnt).area_name                   := gt_data_tab(cn_1)(cv_area_name);                -- �n�於(����)
--  gt_edi_header_tab(gn_head_cnt).area_name_alt               := gt_data_tab(cn_1)(cv_area_name_alt);            -- �n�於(�J�i)
    gt_edi_header_tab(gn_head_cnt).area_name                   := SUBSTRB(gt_data_tab(cn_1)(cv_area_name), 1, 40);      -- �n�於(����)
    gt_edi_header_tab(gn_head_cnt).area_name_alt               := SUBSTRB(gt_data_tab(cn_1)(cv_area_name_alt), 1, 20);  -- �n�於(�J�i)
    gt_edi_header_tab(gn_head_cnt).vendor_code                 := gt_data_tab(cn_1)(cv_vendor_code);              -- �����R�[�h
--  gt_edi_header_tab(gn_head_cnt).vendor_name                 := gt_data_tab(cn_1)(cv_vendor_name);              -- ����於(����)
--  gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := gt_data_tab(cn_1)(cv_vendor_name1_alt);         -- ����於1(�J�i)
--  gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := gt_data_tab(cn_1)(cv_vendor_name2_alt);         -- ����於2(�J�i)
    gt_edi_header_tab(gn_head_cnt).vendor_name                 := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name), 1, 40);       -- ����於(����)
    gt_edi_header_tab(gn_head_cnt).vendor_name1_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name1_alt), 1, 20);  -- ����於1(�J�i)
    gt_edi_header_tab(gn_head_cnt).vendor_name2_alt            := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_name2_alt), 1, 20);  -- ����於2(�J�i)
--  gt_edi_header_tab(gn_head_cnt).vendor_tel                  := gt_data_tab(cn_1)(cv_vendor_tel);               -- �����TEL
--  gt_edi_header_tab(gn_head_cnt).vendor_charge               := gt_data_tab(cn_1)(cv_vendor_charge);            -- �����S����
--  gt_edi_header_tab(gn_head_cnt).vendor_address              := gt_data_tab(cn_1)(cv_vendor_address);           -- �����Z��(����)
    gt_edi_header_tab(gn_head_cnt).vendor_tel                  := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_tel), 1, 12);      -- �����TEL
    gt_edi_header_tab(gn_head_cnt).vendor_charge               := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_charge), 1, 12);   -- �����S����
    gt_edi_header_tab(gn_head_cnt).vendor_address              := SUBSTRB(gt_data_tab(cn_1)(cv_vendor_address), 1, 40);  -- �����Z��(����)
/* 2009/02/24 Ver1.2 Mod  End  */
    gt_edi_header_tab(gn_head_cnt).delivery_schedule_time      := gt_data_tab(cn_1)(cv_delv_schedule_time);       -- �[�i�\�莞��
    gt_edi_header_tab(gn_head_cnt).carrier_means               := gt_data_tab(cn_1)(cv_carrier_means);            -- �^����i
    gt_edi_header_tab(gn_head_cnt).eos_handwriting_class       := gt_data_tab(cn_1)(cv_eos_handwriting_class);    -- EOS��菑�敪
    gt_edi_header_tab(gn_head_cnt).invoice_indv_order_qty      := ir_total_rec.indv_order_qty;                    -- (�`�[�v)��������(�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_case_order_qty      := ir_total_rec.case_order_qty;                    -- (�`�[�v)��������(�P�[�X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_order_qty      := ir_total_rec.ball_order_qty;                    -- (�`�[�v)��������(�{�[��)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_order_qty       := ir_total_rec.sum_order_qty;                     -- (�`�[�v)��������(���v�A�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_shipping_qty   := ir_total_rec.indv_shipping_qty;                 -- (�`�[�v)�o�א���(�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_case_shipping_qty   := ir_total_rec.case_shipping_qty;                 -- (�`�[�v)�o�א���(�P�[�X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_shipping_qty   := ir_total_rec.ball_shipping_qty;                 -- (�`�[�v)�o�א���(�{�[��)
    gt_edi_header_tab(gn_head_cnt).invoice_pallet_shipping_qty := ir_total_rec.pallet_shipping_qty;               -- (�`�[�v)�o�א���(�p���b�g)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_shipping_qty    := ir_total_rec.sum_shipping_qty;                  -- (�`�[�v)�o�א���(���v�A�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_indv_stockout_qty   := ir_total_rec.indv_stockout_qty;                 -- (�`�[�v)���i����(�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_case_stockout_qty   := ir_total_rec.case_stockout_qty;                 -- (�`�[�v)���i����(�P�[�X)
    gt_edi_header_tab(gn_head_cnt).invoice_ball_stockout_qty   := ir_total_rec.ball_stockout_qty;                 -- (�`�[�v)���i����(�{�[��)
    gt_edi_header_tab(gn_head_cnt).invoice_sum_stockout_qty    := ir_total_rec.sum_stockout_qty;                  -- (�`�[�v)���i����(���v�A�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_case_qty            := ir_total_rec.case_qty;                          -- (�`�[�v)�P�[�X����
    gt_edi_header_tab(gn_head_cnt).invoice_fold_container_qty  := gt_data_tab(cn_1)(cv_invc_fold_container_qty);  -- (�`�[�v)�I���R��(�o��)����
    gt_edi_header_tab(gn_head_cnt).invoice_order_cost_amt      := ir_total_rec.order_cost_amt;                    -- (�`�[�v)�������z(����)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_cost_amt   := ir_total_rec.shipping_cost_amt;                 -- (�`�[�v)�������z(�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_cost_amt   := ir_total_rec.stockout_cost_amt;                 -- (�`�[�v)�������z(���i)
    gt_edi_header_tab(gn_head_cnt).invoice_order_price_amt     := ir_total_rec.order_price_amt;                   -- (�`�[�v)�������z(����)
    gt_edi_header_tab(gn_head_cnt).invoice_shipping_price_amt  := ir_total_rec.shipping_price_amt;                -- (�`�[�v)�������z(�o��)
    gt_edi_header_tab(gn_head_cnt).invoice_stockout_price_amt  := ir_total_rec.stockout_price_amt;                -- (�`�[�v)�������z(���i)
    -- �u�쐬�敪�v���A'���M'�̏ꍇ
    IF ( iv_make_class = cv_make_class_transe ) THEN
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := cv_y;                                         -- EDI�[�i�\�著�M�σt���O
    ELSE
      gt_edi_header_tab(gn_head_cnt).edi_delivery_schedule_flag  := it_delivery_flag;                             -- EDI�[�i�\�著�M�σt���O
    END IF;
--
    <<format_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_tab.COUNT LOOP
      --==============================================================
      -- �`�[�v�ҏW
      --==============================================================
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_order_qty)   := ir_total_rec.indv_order_qty;       -- (�`�[�v)��������(�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_order_qty)   := ir_total_rec.case_order_qty;       -- (�`�[�v)��������(�P�[�X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_order_qty)   := ir_total_rec.ball_order_qty;       -- (�`�[�v)��������(�{�[��)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_order_qty)    := ir_total_rec.sum_order_qty;        -- (�`�[�v)��������(���v�A�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_ship_qty)    := ir_total_rec.indv_shipping_qty;    -- (�`�[�v)�o�א���(�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_ship_qty)    := ir_total_rec.case_shipping_qty;    -- (�`�[�v)�o�א���(�P�[�X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_ship_qty)    := ir_total_rec.ball_shipping_qty;    -- (�`�[�v)�o�א���(�{�[��)
      gt_data_tab(ln_loop_cnt)(cv_invc_pallet_ship_qty)  := ir_total_rec.pallet_shipping_qty;  -- (�`�[�v)�o�א���(�p���b�g)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_ship_qty)     := ir_total_rec.sum_shipping_qty;     -- (�`�[�v)�o�א���(���v�A�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_indv_stkout_qty)  := ir_total_rec.indv_stockout_qty;    -- (�`�[�v)���i����(�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_stkout_qty)  := ir_total_rec.case_stockout_qty;    -- (�`�[�v)���i����(�P�[�X)
      gt_data_tab(ln_loop_cnt)(cv_invc_ball_stkout_qty)  := ir_total_rec.ball_stockout_qty;    -- (�`�[�v)���i����(�{�[��)
      gt_data_tab(ln_loop_cnt)(cv_invc_sum_stkout_qty)   := ir_total_rec.sum_stockout_qty;     -- (�`�[�v)���i����(���v�A�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_case_qty)         := ir_total_rec.case_qty;             -- (�`�[�v)�P�[�X����
      gt_data_tab(ln_loop_cnt)(cv_invc_order_cost_amt)   := ir_total_rec.order_cost_amt;       -- (�`�[�v)�������z(����)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_cost_amt)    := ir_total_rec.shipping_cost_amt;    -- (�`�[�v)�������z(�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_cost_amt)  := ir_total_rec.stockout_cost_amt;    -- (�`�[�v)�������z(���i)
      gt_data_tab(ln_loop_cnt)(cv_invc_order_price_amt)  := ir_total_rec.order_price_amt;      -- (�`�[�v)�������z(����)
      gt_data_tab(ln_loop_cnt)(cv_invc_ship_price_amt)   := ir_total_rec.shipping_price_amt;   -- (�`�[�v)�������z(�o��)
      gt_data_tab(ln_loop_cnt)(cv_invc_stkout_price_amt) := ir_total_rec.stockout_price_amt;   -- (�`�[�v)�������z(���i)
--
      --==============================================================
      -- �f�[�^���`
      --==============================================================
      gn_dat_rec_cnt := gn_dat_rec_cnt + cn_1;
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
           iv_edit_data        =>  gt_data_tab(ln_loop_cnt)            -- �o�̓f�[�^���
          ,iv_file_type        =>  cv_0                                -- �t�@�C���`��(�Œ蒷)
          ,iv_data_type_table  =>  gt_data_type_table                  -- ���C�A�E�g��`���
          ,iv_record_type      =>  gv_if_data                          -- �f�[�^���R�[�h���ʎq
          ,ov_data_record      =>  gt_data_record_tab(gn_dat_rec_cnt)  -- �f�[�^���R�[�h
          ,ov_errbuf           =>  lv_errbuf                           -- �G���[���b�Z�[�W
          ,ov_retcode          =>  lv_retcode                          -- ���^�[���R�[�h
          ,ov_errmsg           =>  lv_errmsg                           -- ���[�U�E�G���[���b�Z�[�W
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�Z�[�W�擾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_err_msg       -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_errmsg            -- �G���[�E���b�Z�[�W
                       );
          RAISE global_api_others_expt;
      END;
--
    END LOOP format_loop;
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
  END format_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_data
   * Description      : �f�[�^�ҏW(A-6)
   ***********************************************************************************/
  PROCEDURE edit_data(
    iv_make_class       IN  VARCHAR2,     --   2.�쐬�敪
    iv_center_date      IN  VARCHAR2,     --   9.�Z���^�[�[�i��
    iv_delivery_time    IN  VARCHAR2,     --  10.�[�i����
    iv_delivery_charge  IN  VARCHAR2,     --  11.�[�i�S����
    iv_carrier_means    IN  VARCHAR2,     --  12.�A����i
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_data'; -- �v���O������
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
    lv_tkn_value1      VARCHAR2(50);    -- �g�[�N���擾�p1
    lv_tkn_value2      VARCHAR2(50);    -- �g�[�N���擾�p2
    lv_err_msg         VARCHAR2(5000);  -- �G���[�o�͗p
    ln_err_chk         NUMBER(1);       -- �G���[�`�F�b�N�p
    ln_data_cnt        NUMBER;          -- �f�[�^����
    lv_product_code    VARCHAR2(16);    -- ���i�R�[�h
    lv_jan_code        VARCHAR2(16);    -- JAN�R�[�h
    lv_case_jan_code   VARCHAR2(16);    -- �P�[�XJAN�R�[�h
    ln_dummy_item      NUMBER;          -- DUMMY�i��
    lt_invoice_number  xxcos_edi_headers.invoice_number%TYPE;              -- �`�[�ԍ�
    lt_header_id       xxcos_edi_headers.edi_header_info_id%TYPE;          -- EDI�w�b�_���ID
    lt_delivery_flag   xxcos_edi_headers.edi_delivery_schedule_flag%TYPE;  -- EDI�[�i�\�著�M�σt���O
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
    ln_invoice_number  NUMBER;          -- ���l�`�F�b�N�p
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR dummy_item_cur
    IS
      SELECT flvv.lookup_code      dummy_item_code  -- �_�~�[�i�ڃR�[�h
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type        = cv_edi_item_err_t
      AND    flvv.enabled_flag       = cv_y                -- �L��
      AND (( flvv.start_date_active IS NULL )
      OR   ( flvv.start_date_active <= cd_process_date ))
      AND (( flvv.end_date_active   IS NULL )
      OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_invoice_total_rec  g_invoice_total_rtype;
--
    -- *** ���[�J���E�e�[�u�� ***
    TYPE lt_dummy_item_ttype  IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE  INDEX BY BINARY_INTEGER;  -- DUMMY�i��
    lt_dummy_item_tab  lt_dummy_item_ttype;
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
    --==============================================================
    -- ������
    --==============================================================
    ln_err_chk        := cn_0;
    ln_data_cnt       := cn_0;
    lt_invoice_number := gt_edi_order_tab(cn_1).invoice_number;
    lt_header_id      := gt_edi_order_tab(cn_1).edi_header_info_id;
    lt_delivery_flag  := gt_edi_order_tab(cn_1).edi_delivery_schedule_flag;
    -- �`�[�ʍ��v
    l_invoice_total_rec.indv_order_qty      := cn_0;  -- ��������(�o��)
    l_invoice_total_rec.case_order_qty      := cn_0;  -- ��������(�P�[�X)
    l_invoice_total_rec.ball_order_qty      := cn_0;  -- ��������(�{�[��)
    l_invoice_total_rec.sum_order_qty       := cn_0;  -- ��������(���v�A�o��)
    l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- �o�א���(�o��)
    l_invoice_total_rec.case_shipping_qty   := cn_0;  -- �o�א���(�P�[�X)
    l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- �o�א���(�{�[��)
    l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- �o�א���(�p���b�g)
    l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- �o�א���(���v�A�o��)
    l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- ���i����(�o��)
    l_invoice_total_rec.case_stockout_qty   := cn_0;  -- ���i����(�P�[�X)
    l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- ���i����(�{�[��)
    l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- ���i����(���v�A�o��)
    l_invoice_total_rec.case_qty            := cn_0;  -- �P�[�X����
    l_invoice_total_rec.order_cost_amt      := cn_0;  -- �������z(����)
    l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- �������z(�o��)
    l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- �������z(���i)
    l_invoice_total_rec.order_price_amt     := cn_0;  -- �������z(����)
    l_invoice_total_rec.shipping_price_amt  := cn_0;  -- �������z(�o��)
    l_invoice_total_rec.stockout_price_amt  := cn_0;  -- �������z(���i)
--
    -- DUMMY�i�ڎ擾
    OPEN  dummy_item_cur;
    FETCH dummy_item_cur BULK COLLECT INTO lt_dummy_item_tab;
    CLOSE dummy_item_cur;
--
    <<edit_loop>>
    FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
-- ******* 2009/10/05 1.14 N.Maeda ADD START ******* --
      lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
-- ******* 2009/10/05 1.14 N.Maeda ADD  END  ******* --
--****************************** 2009/06/12 1.10 T.Kitajima ADD START ******************************--
      --���l�`�F�b�N
      BEGIN
        IF INSTR( lt_invoice_number , '.' ) > 0 THEN
          RAISE global_number_err_expt;
        END IF;
        ln_invoice_number := TO_NUMBER( SUBSTRB( lt_invoice_number, 1,1) );
        ln_invoice_number := TO_NUMBER( lt_invoice_number );
      EXCEPTION
        WHEN global_number_err_expt THEN
--****************************** 2009/07/08 1.10 M.Sano     ADD START ******************************--
          gn_error_cnt := gn_error_cnt + 1;
          gn_warn_cnt  := gn_target_cnt - gn_error_cnt;
--****************************** 2009/07/08 1.10 M.Sano     ADD  END  ******************************--
          ov_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application                                -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_slip_no_err                            -- �`�[�ԍ����l�G���[
                          ,iv_token_name1  => cv_tkn_param01                                -- ���̓p�����[�^��
                          ,iv_token_value1 => lt_invoice_number                             -- �`�[�ԍ�
                          ,iv_token_name2  => cv_tkn_param02                                -- ���̓p�����[�^��
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).order_number    -- �󒍔ԍ�
                        );
          RAISE global_api_others_expt;
      END;
--****************************** 2009/06/12 1.10 T.Kitajima ADD  END  ******************************--
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      -- �uEDI�w�b�_���ID�v���u���C�N�����ꍇ
      IF ( lt_header_id <> gt_edi_order_tab(ln_loop_cnt).edi_header_info_id ) THEN
--      -- �u�`�[�ԍ��v���u���C�N�����ꍇ
--      IF ( lt_invoice_number <> gt_edi_order_tab(ln_loop_cnt).invoice_number ) THEN
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
        --==============================================================
        -- �f�[�^���`(A-7)
        --==============================================================
        format_data(
           iv_make_class        -- 2.�쐬�敪
          ,l_invoice_total_rec  -- �`�[�v
          ,lt_header_id         -- EDI�w�b�_���ID
          ,lt_delivery_flag     -- EDI�[�i�\�著�M�σt���O
          ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- �N���A
        --==============================================================
        gt_data_tab.DELETE;
        ln_data_cnt       := cn_0;
        lt_invoice_number := gt_edi_order_tab(ln_loop_cnt).invoice_number;
        lt_header_id      := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;
        lt_delivery_flag  := gt_edi_order_tab(ln_loop_cnt).edi_delivery_schedule_flag;
        -- �`�[�ʍ��v
        l_invoice_total_rec.indv_order_qty      := cn_0;  -- ��������(�o��)
        l_invoice_total_rec.case_order_qty      := cn_0;  -- ��������(�P�[�X)
        l_invoice_total_rec.ball_order_qty      := cn_0;  -- ��������(�{�[��)
        l_invoice_total_rec.sum_order_qty       := cn_0;  -- ��������(���v�A�o��)
        l_invoice_total_rec.indv_shipping_qty   := cn_0;  -- �o�א���(�o��)
        l_invoice_total_rec.case_shipping_qty   := cn_0;  -- �o�א���(�P�[�X)
        l_invoice_total_rec.ball_shipping_qty   := cn_0;  -- �o�א���(�{�[��)
        l_invoice_total_rec.pallet_shipping_qty := cn_0;  -- �o�א���(�p���b�g)
        l_invoice_total_rec.sum_shipping_qty    := cn_0;  -- �o�א���(���v�A�o��)
        l_invoice_total_rec.indv_stockout_qty   := cn_0;  -- ���i����(�o��)
        l_invoice_total_rec.case_stockout_qty   := cn_0;  -- ���i����(�P�[�X)
        l_invoice_total_rec.ball_stockout_qty   := cn_0;  -- ���i����(�{�[��)
        l_invoice_total_rec.sum_stockout_qty    := cn_0;  -- ���i����(���v�A�o��)
        l_invoice_total_rec.case_qty            := cn_0;  -- �P�[�X����
        l_invoice_total_rec.order_cost_amt      := cn_0;  -- �������z(����)
        l_invoice_total_rec.shipping_cost_amt   := cn_0;  -- �������z(�o��)
        l_invoice_total_rec.stockout_cost_amt   := cn_0;  -- �������z(���i)
        l_invoice_total_rec.order_price_amt     := cn_0;  -- �������z(����)
        l_invoice_total_rec.shipping_price_amt  := cn_0;  -- �������z(�o��)
        l_invoice_total_rec.stockout_price_amt  := cn_0;  -- �������z(���i)
      END IF;
--
      ln_data_cnt := ln_data_cnt + cn_1;
      --==============================================================
      -- �[�i�\��f�[�^�ҏW
      --==============================================================
      -- �w�b�_
      gt_data_tab(ln_data_cnt)(cv_medium_class)             := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- �}�̋敪
      gt_data_tab(ln_data_cnt)(cv_data_type_code)           := gt_data_type_code;                                               -- �ް�����
--****************************** 2009/06/12 1.10 T.Kitajima MOD START ******************************--
--      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).file_no;                           -- ̧��No
      gt_data_tab(ln_data_cnt)(cv_file_no)                  := gt_edi_order_tab(ln_loop_cnt).edi_forward_number;                -- ̧��No
--****************************** 2009/06/12 1.10 T.Kitajima MOD  END  ******************************--
      gt_data_tab(ln_data_cnt)(cv_info_class)               := gt_edi_order_tab(ln_loop_cnt).info_class;                        -- ���敪
      gt_data_tab(ln_data_cnt)(cv_process_date)             := gv_f_o_date;                                                     -- ������
      gt_data_tab(ln_data_cnt)(cv_process_time)             := gv_f_o_time;                                                     -- ������
      gt_data_tab(ln_data_cnt)(cv_base_code)                := gt_edi_order_tab(ln_loop_cnt).delivery_base_code;                -- ���_(����)����
/* 2009/02/24 Ver1.2 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_base_name)                := gt_edi_order_tab(ln_loop_cnt).base_name;                         -- ���_��(������)
--    gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := gt_edi_order_tab(ln_loop_cnt).base_name_phonetic;                -- ���_��(��)
      gt_data_tab(ln_data_cnt)(cv_base_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);           -- ���_��(������)
      gt_data_tab(ln_data_cnt)(cv_base_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).base_name_phonetic, 1, 100);  -- ���_��(��)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_code)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_code;                    -- EDI���ݓX����
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := gt_edi_order_tab(ln_loop_cnt).edi_chain_name;                    -- EDI���ݓX��(����)
--    gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic);      -- EDI���ݓX��(��)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name)           := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).edi_chain_name, 1, 100);   -- EDI���ݓX��(����)
      gt_data_tab(ln_data_cnt)(cv_edi_chain_name_alt)       := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).edi_chain_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).edi_chain_name_phonetic), 1, 100); -- EDI���ݓX��(��)
      gt_data_tab(ln_data_cnt)(cv_chain_code)               := NULL;                                                            -- ���ݓX����
      gt_data_tab(ln_data_cnt)(cv_chain_name)               := NULL;                                                            -- ���ݓX��(����)
      gt_data_tab(ln_data_cnt)(cv_chain_name_alt)           := NULL;                                                            -- ���ݓX��(��)
      gt_data_tab(ln_data_cnt)(cv_report_code)              := NULL;                                                            -- ���[����
      gt_data_tab(ln_data_cnt)(cv_report_show_name)         := NULL;                                                            -- ���[�\����
      gt_data_tab(ln_data_cnt)(cv_cust_code)                := gt_edi_order_tab(ln_loop_cnt).account_number;                    -- �ڋq����
--    gt_data_tab(ln_data_cnt)(cv_cust_name)                := gt_edi_order_tab(ln_loop_cnt).customer_name;                     -- �ڋq��(����)
--    gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic;            -- �ڋq��(��)
      gt_data_tab(ln_data_cnt)(cv_cust_name)                := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name, 1, 100);           -- �ڋq��(����)
      gt_data_tab(ln_data_cnt)(cv_cust_name_alt)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).customer_name_phonetic, 1, 100);  -- �ڋq��(��)
      gt_data_tab(ln_data_cnt)(cv_comp_code)                := gt_edi_order_tab(ln_loop_cnt).company_code;                      -- �к���
      gt_data_tab(ln_data_cnt)(cv_comp_name)                := gt_edi_order_tab(ln_loop_cnt).company_name;                      -- �Ж�(����)
      gt_data_tab(ln_data_cnt)(cv_comp_name_alt)            := gt_edi_order_tab(ln_loop_cnt).company_name_alt;                  -- �Ж�(��)
      gt_data_tab(ln_data_cnt)(cv_shop_code)                := gt_edi_order_tab(ln_loop_cnt).shop_code;                         -- �X����
      gt_data_tab(ln_data_cnt)(cv_shop_name)                := gt_edi_order_tab(ln_loop_cnt).cust_store_name;                   -- �X��(����)
--    gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic);           -- �X��(��)
      gt_data_tab(ln_data_cnt)(cv_shop_name_alt)            := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).shop_name_alt,
                                                               gt_edi_order_tab(ln_loop_cnt).shop_name_phonetic), 1, 100);      -- �X��(��)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_code)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_code;              -- �[����������
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name)           := gt_edi_order_tab(ln_loop_cnt).delivery_center_name;              -- �[��������(����)
      gt_data_tab(ln_data_cnt)(cv_delv_cent_name_alt)       := gt_edi_order_tab(ln_loop_cnt).delivery_center_name_alt;          -- �[���������(��)
      gt_data_tab(ln_data_cnt)(cv_order_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_date, cv_date_format);                   -- ������
      gt_data_tab(ln_data_cnt)(cv_cent_delv_date)           := NVL(iv_center_date,
                                                               TO_CHAR(gt_edi_order_tab(ln_loop_cnt).center_delivery_date, cv_date_format));        -- �����[�i��
      gt_data_tab(ln_data_cnt)(cv_result_delv_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).result_delivery_date, cv_date_format);         -- ���[�i��
      gt_data_tab(ln_data_cnt)(cv_shop_delv_date)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).shop_delivery_date, cv_date_format);           -- �X�ܔ[�i��
      gt_data_tab(ln_data_cnt)(cv_dc_date_edi_data)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).data_creation_date_edi_data, cv_date_format);  -- �ް��쐬��(EDI�ް���)
      gt_data_tab(ln_data_cnt)(cv_dc_time_edi_data)         := gt_edi_order_tab(ln_loop_cnt).data_creation_time_edi_data;       -- �ް��쐬����(EDI�ް���)
      gt_data_tab(ln_data_cnt)(cv_invc_class)               := gt_edi_order_tab(ln_loop_cnt).invoice_class;                     -- �`�[�敪
      gt_data_tab(ln_data_cnt)(cv_small_classif_code)       := gt_edi_order_tab(ln_loop_cnt).small_classification_code;         -- �����޺���
      gt_data_tab(ln_data_cnt)(cv_small_classif_name)       := gt_edi_order_tab(ln_loop_cnt).small_classification_name;         -- �����ޖ�
      gt_data_tab(ln_data_cnt)(cv_middle_classif_code)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_code;        -- �����޺���
      gt_data_tab(ln_data_cnt)(cv_middle_classif_name)      := gt_edi_order_tab(ln_loop_cnt).middle_classification_name;        -- �����ޖ�
      gt_data_tab(ln_data_cnt)(cv_big_classif_code)         := gt_edi_order_tab(ln_loop_cnt).big_classification_code;           -- �啪�޺���
      gt_data_tab(ln_data_cnt)(cv_big_classif_name)         := gt_edi_order_tab(ln_loop_cnt).big_classification_name;           -- �啪�ޖ�
      gt_data_tab(ln_data_cnt)(cv_op_department_code)       := gt_edi_order_tab(ln_loop_cnt).other_party_department_code;       -- ����敔�庰��
      gt_data_tab(ln_data_cnt)(cv_op_order_number)          := gt_edi_order_tab(ln_loop_cnt).other_party_order_number;          -- ����攭���ԍ�
      gt_data_tab(ln_data_cnt)(cv_check_digit_class)        := gt_edi_order_tab(ln_loop_cnt).check_digit_class;                 -- �����޼ޯėL���敪
      gt_data_tab(ln_data_cnt)(cv_invc_number)              := gt_edi_order_tab(ln_loop_cnt).invoice_number;                    -- �`�[�ԍ�
      gt_data_tab(ln_data_cnt)(cv_check_digit)              := gt_edi_order_tab(ln_loop_cnt).check_digit;                       -- �����޼ޯ�
      gt_data_tab(ln_data_cnt)(cv_close_date)               := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).close_date, cv_date_format);  -- ����
      gt_data_tab(ln_data_cnt)(cv_order_no_ebs)             := gt_edi_order_tab(ln_loop_cnt).order_number;                      -- ��No(EBS)
      gt_data_tab(ln_data_cnt)(cv_ar_sale_class)            := gt_edi_order_tab(ln_loop_cnt).ar_sale_class;                     -- �����敪
      gt_data_tab(ln_data_cnt)(cv_delv_classe)              := gt_edi_order_tab(ln_loop_cnt).delivery_classe;                   -- �z���敪
      gt_data_tab(ln_data_cnt)(cv_opportunity_no)           := gt_edi_order_tab(ln_loop_cnt).opportunity_no;                    -- ��No
      gt_data_tab(ln_data_cnt)(cv_contact_to)               := NVL(gt_edi_order_tab(ln_loop_cnt).contact_to,
                                                                   gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic);       -- �A����
      gt_data_tab(ln_data_cnt)(cv_route_sales)              := gt_edi_order_tab(ln_loop_cnt).route_sales;                       -- ٰľ�ٽ
      gt_data_tab(ln_data_cnt)(cv_corporate_code)           := gt_edi_order_tab(ln_loop_cnt).corporate_code;                    -- �@�l����
      gt_data_tab(ln_data_cnt)(cv_maker_name)               := gt_edi_order_tab(ln_loop_cnt).maker_name;                        -- Ұ����
      gt_data_tab(ln_data_cnt)(cv_area_code)                := NVL(gt_edi_order_tab(ln_loop_cnt).area_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_code);            -- �n�溰��
      gt_data_tab(ln_data_cnt)(cv_area_name)                := gt_edi_order_tab(ln_loop_cnt).edi_district_name;                 -- �n�於(����)
      gt_data_tab(ln_data_cnt)(cv_area_name_alt)            := NVL(gt_edi_order_tab(ln_loop_cnt).area_name_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).edi_district_kana);            -- �n�於(��)
      gt_data_tab(ln_data_cnt)(cv_vendor_code)              := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).torihikisaki_code);            -- ����溰��
--    gt_data_tab(ln_data_cnt)(cv_vendor_name)              := gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name;      -- ����於(����)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
--                                                                 gv_company_kana);                                            -- ����於1(��)
--    gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
--                                                                 gt_edi_order_tab(ln_loop_cnt).base_name_phonetic);           -- ����於2(��)
      gt_data_tab(ln_data_cnt)(cv_vendor_name)              := SUBSTRB(gv_company_name || gt_edi_order_tab(ln_loop_cnt).base_name, 1, 100);  -- ����於(����)
      gt_data_tab(ln_data_cnt)(cv_vendor_name1_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name1_alt,
                                                                   gv_company_kana), 1, 100);                                   -- ����於1(��)
      gt_data_tab(ln_data_cnt)(cv_vendor_name2_alt)         := SUBSTRB(NVL(gt_edi_order_tab(ln_loop_cnt).vendor_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).base_name_phonetic), 1, 100);  -- ����於2(��)
      gt_data_tab(ln_data_cnt)(cv_vendor_tel)               := gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic;            -- �����TEL
      gt_data_tab(ln_data_cnt)(cv_vendor_charge)            := NVL(iv_delivery_charge,
                                                                   gt_edi_order_tab(ln_loop_cnt).last_name ||
                                                                   gt_edi_order_tab(ln_loop_cnt).first_name);                   -- �����S����
--    gt_data_tab(ln_data_cnt)(cv_vendor_address)           := gt_edi_order_tab(ln_loop_cnt).state    ||
--                                                             gt_edi_order_tab(ln_loop_cnt).city     ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address1 ||
--                                                             gt_edi_order_tab(ln_loop_cnt).address2;                          -- �����Z��(����)
      gt_data_tab(ln_data_cnt)(cv_vendor_address)           := SUBSTRB(
                                                               gt_edi_order_tab(ln_loop_cnt).state    ||
                                                               gt_edi_order_tab(ln_loop_cnt).city     ||
                                                               gt_edi_order_tab(ln_loop_cnt).address1 ||
                                                               gt_edi_order_tab(ln_loop_cnt).address2, 1, 100);                 -- �����Z��(����)
/* 2009/02/24 Ver1.2 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_itouen)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_itouen;            -- �͂��溰��(�ɓ���)
      gt_data_tab(ln_data_cnt)(cv_delv_to_code_chain)       := gt_edi_order_tab(ln_loop_cnt).deliver_to_code_chain;             -- �͂��溰��(���ݓX)
      gt_data_tab(ln_data_cnt)(cv_delv_to)                  := gt_edi_order_tab(ln_loop_cnt).deliver_to;                        -- �͂���(����)
      gt_data_tab(ln_data_cnt)(cv_delv_to1_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to1_alt;                   -- �͂���1(��)
      gt_data_tab(ln_data_cnt)(cv_delv_to2_alt)             := gt_edi_order_tab(ln_loop_cnt).deliver_to2_alt;                   -- �͂���2(��)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address)          := gt_edi_order_tab(ln_loop_cnt).deliver_to_address;                -- �͂���Z��(����)
      gt_data_tab(ln_data_cnt)(cv_delv_to_address_alt)      := gt_edi_order_tab(ln_loop_cnt).deliver_to_address_alt;            -- �͂���Z��(��)
      gt_data_tab(ln_data_cnt)(cv_delv_to_tel)              := gt_edi_order_tab(ln_loop_cnt).deliver_to_tel;                    -- �͂���TEL
      gt_data_tab(ln_data_cnt)(cv_bal_acc_code)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_code;             -- �����溰��
      gt_data_tab(ln_data_cnt)(cv_bal_acc_comp_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_company_code;     -- ������к���
      gt_data_tab(ln_data_cnt)(cv_bal_acc_shop_code)        := gt_edi_order_tab(ln_loop_cnt).balance_accounts_shop_code;        -- ������X����
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name)             := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name;             -- �����於(����)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_name_alt)         := gt_edi_order_tab(ln_loop_cnt).balance_accounts_name_alt;         -- �����於(��)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address)          := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address;          -- ������Z��(����)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_address_alt)      := gt_edi_order_tab(ln_loop_cnt).balance_accounts_address_alt;      -- ������Z��(��)
      gt_data_tab(ln_data_cnt)(cv_bal_acc_tel)              := gt_edi_order_tab(ln_loop_cnt).balance_accounts_tel;              -- ������TEL
      gt_data_tab(ln_data_cnt)(cv_order_possible_date)      := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).order_possible_date, cv_date_format);         -- �󒍉\��
      gt_data_tab(ln_data_cnt)(cv_perm_possible_date)       := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).permission_possible_date, cv_date_format);    -- ���e�\��
      gt_data_tab(ln_data_cnt)(cv_forward_month)            := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).forward_month, cv_date_format);               -- ����N����
      gt_data_tab(ln_data_cnt)(cv_payment_settlement_date)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).payment_settlement_date, cv_date_format);     -- �x�����ϓ�
      gt_data_tab(ln_data_cnt)(cv_handbill_start_date_act)  := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).handbill_start_date_active, cv_date_format);  -- �׼�J�n��
      gt_data_tab(ln_data_cnt)(cv_billing_due_date)         := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).billing_due_date, cv_date_format);            -- ��������
      gt_data_tab(ln_data_cnt)(cv_ship_time)                := gt_edi_order_tab(ln_loop_cnt).shipping_time;                     -- �o�׎���
      gt_data_tab(ln_data_cnt)(cv_delv_schedule_time)       := iv_delivery_time;                                                -- �[�i�\�莞��
      gt_data_tab(ln_data_cnt)(cv_order_time)               := gt_edi_order_tab(ln_loop_cnt).order_time;                        -- ��������
      gt_data_tab(ln_data_cnt)(cv_gen_date_item1)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item1, cv_date_format);  -- �ėp���t����1
      gt_data_tab(ln_data_cnt)(cv_gen_date_item2)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item2, cv_date_format);  -- �ėp���t����2
      gt_data_tab(ln_data_cnt)(cv_gen_date_item3)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item3, cv_date_format);  -- �ėp���t����3
      gt_data_tab(ln_data_cnt)(cv_gen_date_item4)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item4, cv_date_format);  -- �ėp���t����4
      gt_data_tab(ln_data_cnt)(cv_gen_date_item5)           := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).general_date_item5, cv_date_format);  -- �ėp���t����5
      gt_data_tab(ln_data_cnt)(cv_arrival_ship_class)       := gt_edi_order_tab(ln_loop_cnt).arrival_shipping_class;            -- ���o�׋敪
      gt_data_tab(ln_data_cnt)(cv_vendor_class)             := gt_edi_order_tab(ln_loop_cnt).vendor_class;                      -- �����敪
      gt_data_tab(ln_data_cnt)(cv_invc_detailed_class)      := gt_edi_order_tab(ln_loop_cnt).invoice_detailed_class;            -- �`�[����敪
      gt_data_tab(ln_data_cnt)(cv_unit_price_use_class)     := gt_edi_order_tab(ln_loop_cnt).unit_price_use_class;              -- �P���g�p�敪
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_code)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_code;      -- ��ޕ�����������
      gt_data_tab(ln_data_cnt)(cv_sub_distb_cent_name)      := gt_edi_order_tab(ln_loop_cnt).sub_distribution_center_name;      -- ��ޕ����������ޖ�
      gt_data_tab(ln_data_cnt)(cv_cent_delv_method)         := gt_edi_order_tab(ln_loop_cnt).center_delivery_method;            -- �����[�i���@
      gt_data_tab(ln_data_cnt)(cv_cent_use_class)           := gt_edi_order_tab(ln_loop_cnt).center_use_class;                  -- �������p�敪
      gt_data_tab(ln_data_cnt)(cv_cent_whse_class)          := gt_edi_order_tab(ln_loop_cnt).center_whse_class;                 -- �����q�ɋ敪
      gt_data_tab(ln_data_cnt)(cv_cent_area_class)          := gt_edi_order_tab(ln_loop_cnt).center_area_class;                 -- �����n��敪
      gt_data_tab(ln_data_cnt)(cv_cent_arrival_class)       := gt_edi_order_tab(ln_loop_cnt).center_arrival_class;              -- �������׋敪
      gt_data_tab(ln_data_cnt)(cv_depot_class)              := gt_edi_order_tab(ln_loop_cnt).depot_class;                       -- ���ߋ敪
      gt_data_tab(ln_data_cnt)(cv_tcdc_class)               := gt_edi_order_tab(ln_loop_cnt).tcdc_class;                        -- TCDC�敪
      gt_data_tab(ln_data_cnt)(cv_upc_flag)                 := gt_edi_order_tab(ln_loop_cnt).upc_flag;                          -- UPC�׸�
      gt_data_tab(ln_data_cnt)(cv_simultaneously_class)     := gt_edi_order_tab(ln_loop_cnt).simultaneously_class;              -- ��ċ敪
      gt_data_tab(ln_data_cnt)(cv_business_id)              := gt_edi_order_tab(ln_loop_cnt).business_id;                       -- �Ɩ�ID
      gt_data_tab(ln_data_cnt)(cv_whse_directly_class)      := gt_edi_order_tab(ln_loop_cnt).whse_directly_class;               -- �q���敪
      gt_data_tab(ln_data_cnt)(cv_premium_rebate_class)     := gt_edi_order_tab(ln_loop_cnt).premium_rebate_class;              -- ���ڎ��
      gt_data_tab(ln_data_cnt)(cv_item_type)                := gt_edi_order_tab(ln_loop_cnt).item_type;                         -- �i�i���ߋ敪
      gt_data_tab(ln_data_cnt)(cv_cloth_house_food_class)   := gt_edi_order_tab(ln_loop_cnt).cloth_house_food_class;            -- �߉ƐH�敪
      gt_data_tab(ln_data_cnt)(cv_mix_class)                := gt_edi_order_tab(ln_loop_cnt).mix_class;                         -- ���݋敪
      gt_data_tab(ln_data_cnt)(cv_stk_class)                := gt_edi_order_tab(ln_loop_cnt).stk_class;                         -- �݌ɋ敪
      gt_data_tab(ln_data_cnt)(cv_last_modify_site_class)   := gt_edi_order_tab(ln_loop_cnt).last_modify_site_class;            -- �ŏI�C���ꏊ�敪
      gt_data_tab(ln_data_cnt)(cv_report_class)             := gt_edi_order_tab(ln_loop_cnt).report_class;                      -- ���[�敪
      gt_data_tab(ln_data_cnt)(cv_addition_plan_class)      := gt_edi_order_tab(ln_loop_cnt).addition_plan_class;               -- �ǉ���v��敪
      gt_data_tab(ln_data_cnt)(cv_registration_class)       := gt_edi_order_tab(ln_loop_cnt).registration_class;                -- �o�^�敪
      gt_data_tab(ln_data_cnt)(cv_specific_class)           := gt_edi_order_tab(ln_loop_cnt).specific_class;                    -- ����敪
      gt_data_tab(ln_data_cnt)(cv_dealings_class)           := gt_edi_order_tab(ln_loop_cnt).dealings_class;                    -- ����敪
      gt_data_tab(ln_data_cnt)(cv_order_class)              := gt_edi_order_tab(ln_loop_cnt).order_class;                       -- �����敪
      gt_data_tab(ln_data_cnt)(cv_sum_line_class)           := gt_edi_order_tab(ln_loop_cnt).sum_line_class;                    -- �W�v���׋敪
      gt_data_tab(ln_data_cnt)(cv_ship_guidance_class)      := gt_edi_order_tab(ln_loop_cnt).shipping_guidance_class;           -- �o�׈ē��ȊO�敪
      gt_data_tab(ln_data_cnt)(cv_ship_class)               := gt_edi_order_tab(ln_loop_cnt).shipping_class;                    -- �o�׋敪
      gt_data_tab(ln_data_cnt)(cv_prod_code_use_class)      := gt_edi_order_tab(ln_loop_cnt).product_code_use_class;            -- ���i���ގg�p�敪
      gt_data_tab(ln_data_cnt)(cv_cargo_item_class)         := gt_edi_order_tab(ln_loop_cnt).cargo_item_class;                  -- �ϑ��i�敪
      gt_data_tab(ln_data_cnt)(cv_ta_class)                 := gt_edi_order_tab(ln_loop_cnt).ta_class;                          -- T/A�敪
      gt_data_tab(ln_data_cnt)(cv_plan_code)                := gt_edi_order_tab(ln_loop_cnt).plan_code;                         -- ��溰��
      gt_data_tab(ln_data_cnt)(cv_category_code)            := gt_edi_order_tab(ln_loop_cnt).category_code;                     -- �ú�ذ����
      gt_data_tab(ln_data_cnt)(cv_category_class)           := gt_edi_order_tab(ln_loop_cnt).category_class;                    -- �ú�ذ�敪
      gt_data_tab(ln_data_cnt)(cv_carrier_means)            := iv_carrier_means;                                                -- �^����i
      gt_data_tab(ln_data_cnt)(cv_counter_code)             := gt_edi_order_tab(ln_loop_cnt).counter_code;                      -- ���꺰��
      gt_data_tab(ln_data_cnt)(cv_move_sign)                := gt_edi_order_tab(ln_loop_cnt).move_sign;                         -- �ړ����
      gt_data_tab(ln_data_cnt)(cv_eos_handwriting_class)    := gt_edi_order_tab(ln_loop_cnt).medium_class;                      -- EOS��菑�敪
      gt_data_tab(ln_data_cnt)(cv_delv_to_section_code)     := gt_edi_order_tab(ln_loop_cnt).delivery_to_section_code;          -- �[�i��ۺ���
      gt_data_tab(ln_data_cnt)(cv_invc_detailed)            := gt_edi_order_tab(ln_loop_cnt).invoice_detailed;                  -- �`�[����
      gt_data_tab(ln_data_cnt)(cv_attach_qty)               := gt_edi_order_tab(ln_loop_cnt).attach_qty;                        -- �Y�t��
      gt_data_tab(ln_data_cnt)(cv_op_floor)                 := gt_edi_order_tab(ln_loop_cnt).other_party_floor;                 -- �۱
      gt_data_tab(ln_data_cnt)(cv_text_no)                  := gt_edi_order_tab(ln_loop_cnt).text_no;                           -- TEXTNo
      gt_data_tab(ln_data_cnt)(cv_in_store_code)            := gt_edi_order_tab(ln_loop_cnt).in_store_code;                     -- �ݽı����
      gt_data_tab(ln_data_cnt)(cv_tag_data)                 := gt_edi_order_tab(ln_loop_cnt).tag_data;                          -- ���
      gt_data_tab(ln_data_cnt)(cv_competition_code)         := gt_edi_order_tab(ln_loop_cnt).competition_code;                  -- ����
      gt_data_tab(ln_data_cnt)(cv_billing_chair)            := gt_edi_order_tab(ln_loop_cnt).billing_chair;                     -- ��������
      gt_data_tab(ln_data_cnt)(cv_chain_store_code)         := gt_edi_order_tab(ln_loop_cnt).chain_store_code;                  -- ���ݽı�����
      gt_data_tab(ln_data_cnt)(cv_chain_store_short_name)   := gt_edi_order_tab(ln_loop_cnt).chain_store_short_name;            -- ���ݽı����ޗ�������
      gt_data_tab(ln_data_cnt)(cv_direct_delv_rcpt_fee)     := gt_edi_order_tab(ln_loop_cnt).direct_delivery_rcpt_fee;          -- ���z��/���旿
      gt_data_tab(ln_data_cnt)(cv_bill_info)                := gt_edi_order_tab(ln_loop_cnt).bill_info;                         -- ��`���
      gt_data_tab(ln_data_cnt)(cv_description)              := gt_edi_order_tab(ln_loop_cnt).description;                       -- �E�v1
      gt_data_tab(ln_data_cnt)(cv_interior_code)            := gt_edi_order_tab(ln_loop_cnt).interior_code;                     -- ��������
      gt_data_tab(ln_data_cnt)(cv_order_info_delv_category) := gt_edi_order_tab(ln_loop_cnt).order_info_delivery_category;      -- ������� �[�i�ú�ذ
      gt_data_tab(ln_data_cnt)(cv_purchase_type)            := gt_edi_order_tab(ln_loop_cnt).purchase_type;                     -- �d���`��
      gt_data_tab(ln_data_cnt)(cv_delv_to_name_alt)         := gt_edi_order_tab(ln_loop_cnt).delivery_to_name_alt;              -- �[�i�ꏊ��(��)
      gt_data_tab(ln_data_cnt)(cv_shop_opened_site)         := gt_edi_order_tab(ln_loop_cnt).shop_opened_site;                  -- �X�o�ꏊ
      gt_data_tab(ln_data_cnt)(cv_counter_name)             := gt_edi_order_tab(ln_loop_cnt).counter_name;                      -- ���ꖼ
      gt_data_tab(ln_data_cnt)(cv_extension_number)         := gt_edi_order_tab(ln_loop_cnt).extension_number;                  -- �����ԍ�
      gt_data_tab(ln_data_cnt)(cv_charge_name)              := gt_edi_order_tab(ln_loop_cnt).charge_name;                       -- �S���Җ�
      gt_data_tab(ln_data_cnt)(cv_price_tag)                := gt_edi_order_tab(ln_loop_cnt).price_tag;                         -- �l�D
      gt_data_tab(ln_data_cnt)(cv_tax_type)                 := gt_edi_order_tab(ln_loop_cnt).tax_type;                          -- �Ŏ�
      gt_data_tab(ln_data_cnt)(cv_consumption_tax_class)    := gt_edi_order_tab(ln_loop_cnt).consumption_tax_class;             -- ����ŋ敪
      gt_data_tab(ln_data_cnt)(cv_brand_class)              := gt_edi_order_tab(ln_loop_cnt).brand_class;                       -- BR
      gt_data_tab(ln_data_cnt)(cv_id_code)                  := gt_edi_order_tab(ln_loop_cnt).id_code;                           -- ID����
      gt_data_tab(ln_data_cnt)(cv_department_code)          := gt_edi_order_tab(ln_loop_cnt).department_code;                   -- �S�ݓX����
      gt_data_tab(ln_data_cnt)(cv_department_name)          := gt_edi_order_tab(ln_loop_cnt).department_name;                   -- �S�ݓX��
      gt_data_tab(ln_data_cnt)(cv_item_type_number)         := gt_edi_order_tab(ln_loop_cnt).item_type_number;                  -- �i�ʔԍ�
      gt_data_tab(ln_data_cnt)(cv_description_department)   := gt_edi_order_tab(ln_loop_cnt).description_department;            -- �E�v2
      gt_data_tab(ln_data_cnt)(cv_price_tag_method)         := gt_edi_order_tab(ln_loop_cnt).price_tag_method;                  -- �l�D���@
      gt_data_tab(ln_data_cnt)(cv_reason_column)            := gt_edi_order_tab(ln_loop_cnt).reason_column;                     -- ���R��
      gt_data_tab(ln_data_cnt)(cv_a_column_header)          := gt_edi_order_tab(ln_loop_cnt).a_column_header;                   -- A��ͯ��
      gt_data_tab(ln_data_cnt)(cv_d_column_header)          := gt_edi_order_tab(ln_loop_cnt).d_column_header;                   -- D��ͯ��
      gt_data_tab(ln_data_cnt)(cv_brand_code)               := gt_edi_order_tab(ln_loop_cnt).brand_code;                        -- �����޺���
      gt_data_tab(ln_data_cnt)(cv_line_code)                := gt_edi_order_tab(ln_loop_cnt).line_code;                         -- ײݺ���
      gt_data_tab(ln_data_cnt)(cv_class_code)               := gt_edi_order_tab(ln_loop_cnt).class_code;                        -- �׽����
      gt_data_tab(ln_data_cnt)(cv_a1_column)                := gt_edi_order_tab(ln_loop_cnt).a1_column;                         -- A-1��
      gt_data_tab(ln_data_cnt)(cv_b1_column)                := gt_edi_order_tab(ln_loop_cnt).b1_column;                         -- B-1��
      gt_data_tab(ln_data_cnt)(cv_c1_column)                := gt_edi_order_tab(ln_loop_cnt).c1_column;                         -- C-1��
      gt_data_tab(ln_data_cnt)(cv_d1_column)                := gt_edi_order_tab(ln_loop_cnt).d1_column;                         -- D-1��
      gt_data_tab(ln_data_cnt)(cv_e1_column)                := gt_edi_order_tab(ln_loop_cnt).e1_column;                         -- E-1��
      gt_data_tab(ln_data_cnt)(cv_a2_column)                := gt_edi_order_tab(ln_loop_cnt).a2_column;                         -- A-2��
      gt_data_tab(ln_data_cnt)(cv_b2_column)                := gt_edi_order_tab(ln_loop_cnt).b2_column;                         -- B-2��
      gt_data_tab(ln_data_cnt)(cv_c2_column)                := gt_edi_order_tab(ln_loop_cnt).c2_column;                         -- C-2��
      gt_data_tab(ln_data_cnt)(cv_d2_column)                := gt_edi_order_tab(ln_loop_cnt).d2_column;                         -- D-2��
      gt_data_tab(ln_data_cnt)(cv_e2_column)                := gt_edi_order_tab(ln_loop_cnt).e2_column;                         -- E-2��
      gt_data_tab(ln_data_cnt)(cv_a3_column)                := gt_edi_order_tab(ln_loop_cnt).a3_column;                         -- A-3��
      gt_data_tab(ln_data_cnt)(cv_b3_column)                := gt_edi_order_tab(ln_loop_cnt).b3_column;                         -- B-3��
      gt_data_tab(ln_data_cnt)(cv_c3_column)                := gt_edi_order_tab(ln_loop_cnt).c3_column;                         -- C-3��
      gt_data_tab(ln_data_cnt)(cv_d3_column)                := gt_edi_order_tab(ln_loop_cnt).d3_column;                         -- D-3��
      gt_data_tab(ln_data_cnt)(cv_e3_column)                := gt_edi_order_tab(ln_loop_cnt).e3_column;                         -- E-3��
      gt_data_tab(ln_data_cnt)(cv_f1_column)                := gt_edi_order_tab(ln_loop_cnt).f1_column;                         -- F-1��
      gt_data_tab(ln_data_cnt)(cv_g1_column)                := gt_edi_order_tab(ln_loop_cnt).g1_column;                         -- G-1��
      gt_data_tab(ln_data_cnt)(cv_h1_column)                := gt_edi_order_tab(ln_loop_cnt).h1_column;                         -- H-1��
      gt_data_tab(ln_data_cnt)(cv_i1_column)                := gt_edi_order_tab(ln_loop_cnt).i1_column;                         -- I-1��
      gt_data_tab(ln_data_cnt)(cv_j1_column)                := gt_edi_order_tab(ln_loop_cnt).j1_column;                         -- J-1��
      gt_data_tab(ln_data_cnt)(cv_k1_column)                := gt_edi_order_tab(ln_loop_cnt).k1_column;                         -- K-1��
      gt_data_tab(ln_data_cnt)(cv_l1_column)                := gt_edi_order_tab(ln_loop_cnt).l1_column;                         -- L-1��
      gt_data_tab(ln_data_cnt)(cv_f2_column)                := gt_edi_order_tab(ln_loop_cnt).f2_column;                         -- F-2��
      gt_data_tab(ln_data_cnt)(cv_g2_column)                := gt_edi_order_tab(ln_loop_cnt).g2_column;                         -- G-2��
      gt_data_tab(ln_data_cnt)(cv_h2_column)                := gt_edi_order_tab(ln_loop_cnt).h2_column;                         -- H-2��
      gt_data_tab(ln_data_cnt)(cv_i2_column)                := gt_edi_order_tab(ln_loop_cnt).i2_column;                         -- I-2��
      gt_data_tab(ln_data_cnt)(cv_j2_column)                := gt_edi_order_tab(ln_loop_cnt).j2_column;                         -- J-2��
      gt_data_tab(ln_data_cnt)(cv_k2_column)                := gt_edi_order_tab(ln_loop_cnt).k2_column;                         -- K-2��
      gt_data_tab(ln_data_cnt)(cv_l2_column)                := gt_edi_order_tab(ln_loop_cnt).l2_column;                         -- L-2��
      gt_data_tab(ln_data_cnt)(cv_f3_column)                := gt_edi_order_tab(ln_loop_cnt).f3_column;                         -- F-3��
      gt_data_tab(ln_data_cnt)(cv_g3_column)                := gt_edi_order_tab(ln_loop_cnt).g3_column;                         -- G-3��
      gt_data_tab(ln_data_cnt)(cv_h3_column)                := gt_edi_order_tab(ln_loop_cnt).h3_column;                         -- H-3��
      gt_data_tab(ln_data_cnt)(cv_i3_column)                := gt_edi_order_tab(ln_loop_cnt).i3_column;                         -- I-3��
      gt_data_tab(ln_data_cnt)(cv_j3_column)                := gt_edi_order_tab(ln_loop_cnt).j3_column;                         -- J-3��
      gt_data_tab(ln_data_cnt)(cv_k3_column)                := gt_edi_order_tab(ln_loop_cnt).k3_column;                         -- K-3��
      gt_data_tab(ln_data_cnt)(cv_l3_column)                := gt_edi_order_tab(ln_loop_cnt).l3_column;                         -- L-3��
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_header)    := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_header;        -- ���ݓX�ŗL�ر(ͯ��)
      gt_data_tab(ln_data_cnt)(cv_order_connection_number)  := NULL;                                                            -- �󒍊֘A�ԍ�
--
      -- ����
      gt_data_tab(ln_data_cnt)(cv_line_no)                  := gt_edi_order_tab(ln_loop_cnt).line_no;                      -- �sNo
      -- �_�~�[�i�ڃ`�F�b�N
      ln_dummy_item := cn_0;
      <<dummy_item_loop>>
      FOR ln_dummy_item_loop_cnt IN 1 .. lt_dummy_item_tab.COUNT LOOP
        IF ( gt_edi_order_tab(ln_loop_cnt).ordered_item = lt_dummy_item_tab(ln_dummy_item_loop_cnt) ) THEN
          ln_dummy_item := cn_1;
          EXIT;
        END IF;
      END LOOP dummy_item_loop;
      -- �u���i�R�[�h(�ɓ���)�v���A�_�~�[�i�ڂ̏ꍇ
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := NULL;                                                       -- ���i����(�ɓ���)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := NULL;                                                       -- ���i��(����)
/* 2009/03/04 Ver1.6 Add  End  */
      -- ��L�ȊO�̏ꍇ
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code_itouen)       := gt_edi_order_tab(ln_loop_cnt).ordered_item;                 -- ���i����(�ɓ���)
/* 2009/03/04 Ver1.6 Add Start */
        gt_data_tab(ln_data_cnt)(cv_prod_name)              := gt_edi_order_tab(ln_loop_cnt).item_name;                    -- ���i��(����)
/* 2009/03/04 Ver1.6 Add  End  */
      END IF;
      gt_data_tab(ln_data_cnt)(cv_prod_code1)               := gt_edi_order_tab(ln_loop_cnt).product_code1;                -- ���i����1
      -- �u�}�̋敪�v���A'�����'�ł��A�u���i�R�[�h�Q�v���ANULL�̏ꍇ
      IF  ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl )
      AND ( gt_edi_order_tab(ln_loop_cnt).product_code2 IS NULL )
      THEN
        --�i�ڃR�[�h�ϊ��iEBS��EDI)
        xxcos_common2_pkg.conv_edi_item_code(
           iv_edi_chain_code   =>  gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDI�`�F�[���X�R�[�h
          ,iv_item_code        =>  gt_edi_order_tab(ln_loop_cnt).item_code       -- �i�ڃR�[�h
          ,iv_organization_id  =>  gn_organization_id                            -- �݌ɑg�DID
          ,iv_uom_code         =>  gt_edi_order_tab(ln_loop_cnt).line_uom        -- �P�ʃR�[�h
          ,ov_product_code2    =>  lv_product_code                               -- ���i�R�[�h�Q
          ,ov_jan_code         =>  lv_jan_code                                   -- JAN�R�[�h
          ,ov_case_jan_code    =>  lv_case_jan_code                              -- �P�[�XJAN�R�[�h
          ,ov_errbuf           =>  lv_errbuf                                     -- �G���[���b�Z�[�W
          ,ov_retcode          =>  lv_retcode                                    -- ���^�[���R�[�h
          ,ov_errmsg           =>  lv_errmsg                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ���b�Z�[�W�擾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_com_fnuc_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_err_msg       -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_errmsg            -- �G���[�E���b�Z�[�W
                       );
          RAISE global_api_others_expt;
        END IF;
        -- �擾�������i�R�[�h���ANULL�̏ꍇ
        IF ( lv_product_code IS NULL ) THEN
          -- ���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      -- �A�v���P�[�V����
                          ,iv_name         => cv_msg_product_err  -- ���i�R�[�h�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_chain_code   -- �g�[�N���R�[�h�P
                          ,iv_token_value1 => gt_edi_order_tab(ln_loop_cnt).edi_chain_code  -- EDI�`�F�[���X�R�[�h
                          ,iv_token_name2  => cv_tkn_item_code    -- �g�[�N���R�[�h�Q
                          ,iv_token_value2 => gt_edi_order_tab(ln_loop_cnt).item_code       -- �i�ڃR�[�h
                        );
          -- ���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  -- �G���[�L��
        END IF;
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := lv_product_code;                                            -- ���i����2
      -- ��L�ȊO�̏ꍇ
      ELSE
        gt_data_tab(ln_data_cnt)(cv_prod_code2)             := gt_edi_order_tab(ln_loop_cnt).product_code2;                -- ���i����2
      END IF;
      -- �u���גP�ʁv���A'�P�[�X�P�ʃR�[�h'�̏ꍇ
      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).case_jan_code;                -- JAN����
      -- ��L�ȊO�̏ꍇ
      ELSE
        gt_data_tab(ln_data_cnt)(cv_jan_code)               := gt_edi_order_tab(ln_loop_cnt).opf_jan_code;                 -- JAN����
      END IF;
      gt_data_tab(ln_data_cnt)(cv_itf_code)                 := NVL(gt_edi_order_tab(ln_loop_cnt).itf_code,
                                                                   gt_edi_order_tab(ln_loop_cnt).opm_itf_code);            -- ITF����
      gt_data_tab(ln_data_cnt)(cv_extension_itf_code)       := gt_edi_order_tab(ln_loop_cnt).extension_itf_code;           -- ����ITF����
      gt_data_tab(ln_data_cnt)(cv_case_prod_code)           := gt_edi_order_tab(ln_loop_cnt).case_product_code;            -- ������i����
      gt_data_tab(ln_data_cnt)(cv_ball_prod_code)           := gt_edi_order_tab(ln_loop_cnt).ball_product_code;            -- �ްُ��i����
      gt_data_tab(ln_data_cnt)(cv_prod_code_item_type)      := gt_edi_order_tab(ln_loop_cnt).product_code_item_type;       -- ���i���ޕi��
      gt_data_tab(ln_data_cnt)(cv_prod_class)               := gt_edi_order_tab(ln_loop_cnt).item_div_h_code;              -- ���i�敪
/* 2009/03/04 Ver1.6 Del Start */
--    gt_data_tab(ln_data_cnt)(cv_prod_name)                := gt_edi_order_tab(ln_loop_cnt).product_name;                 -- ���i��(����)
/* 2009/03/04 Ver1.6 Del  End  */
      gt_data_tab(ln_data_cnt)(cv_prod_name1_alt)           := gt_edi_order_tab(ln_loop_cnt).product_name1_alt;            -- ���i��1(��)
      gt_data_tab(ln_data_cnt)(cv_prod_name2_alt)           := NVL(gt_edi_order_tab(ln_loop_cnt).product_name2_alt,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt);           -- ���i��2(��)
      gt_data_tab(ln_data_cnt)(cv_item_standard1)           := gt_edi_order_tab(ln_loop_cnt).item_standard1;               -- �K�i1
      gt_data_tab(ln_data_cnt)(cv_item_standard2)           := NVL(gt_edi_order_tab(ln_loop_cnt).item_standard2,
                                                                   gt_edi_order_tab(ln_loop_cnt).item_name_alt2);          -- �K�i2
      gt_data_tab(ln_data_cnt)(cv_qty_in_case)              := gt_edi_order_tab(ln_loop_cnt).qty_in_case;                  -- ����
      gt_data_tab(ln_data_cnt)(cv_num_of_cases)             := gt_edi_order_tab(ln_loop_cnt).num_of_case;                  -- �������
      gt_data_tab(ln_data_cnt)(cv_num_of_ball)              := NVL(gt_edi_order_tab(ln_loop_cnt).num_of_ball,
                                                                   gt_edi_order_tab(ln_loop_cnt).bowl_inc_num);            -- �ްٓ���
      gt_data_tab(ln_data_cnt)(cv_item_color)               := gt_edi_order_tab(ln_loop_cnt).item_color;                   -- �F
      gt_data_tab(ln_data_cnt)(cv_item_size)                := gt_edi_order_tab(ln_loop_cnt).item_size;                    -- ����
      gt_data_tab(ln_data_cnt)(cv_expiration_date)          := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).expiration_date, cv_date_format);  -- �ܖ�������
      gt_data_tab(ln_data_cnt)(cv_prod_date)                := TO_CHAR(gt_edi_order_tab(ln_loop_cnt).product_date, cv_date_format);     -- ������
      gt_data_tab(ln_data_cnt)(cv_order_uom_qty)            := gt_edi_order_tab(ln_loop_cnt).order_uom_qty;                -- �����P�ʐ�
      gt_data_tab(ln_data_cnt)(cv_ship_uom_qty)             := gt_edi_order_tab(ln_loop_cnt).shipping_uom_qty;             -- �o�גP�ʐ�
      gt_data_tab(ln_data_cnt)(cv_packing_uom_qty)          := gt_edi_order_tab(ln_loop_cnt).packing_uom_qty;              -- ����P�ʐ�
      gt_data_tab(ln_data_cnt)(cv_deal_code)                := gt_edi_order_tab(ln_loop_cnt).deal_code;                    -- ����
      gt_data_tab(ln_data_cnt)(cv_deal_class)               := gt_edi_order_tab(ln_loop_cnt).deal_class;                   -- �����敪
      gt_data_tab(ln_data_cnt)(cv_collation_code)           := gt_edi_order_tab(ln_loop_cnt).collation_code;               -- �ƍ�
      gt_data_tab(ln_data_cnt)(cv_uom_code)                 := gt_edi_order_tab(ln_loop_cnt).uom_code;                     -- �P��
      gt_data_tab(ln_data_cnt)(cv_unit_price_class)         := gt_edi_order_tab(ln_loop_cnt).unit_price_class;             -- �P���敪
      gt_data_tab(ln_data_cnt)(cv_parent_packing_number)    := gt_edi_order_tab(ln_loop_cnt).parent_packing_number;        -- �e����ԍ�
      gt_data_tab(ln_data_cnt)(cv_packing_number)           := gt_edi_order_tab(ln_loop_cnt).packing_number;               -- ����ԍ�
      gt_data_tab(ln_data_cnt)(cv_prod_group_code)          := gt_edi_order_tab(ln_loop_cnt).product_group_code;           -- ���i�Q����
      gt_data_tab(ln_data_cnt)(cv_case_dismantle_flag)      := gt_edi_order_tab(ln_loop_cnt).case_dismantle_flag;          -- �����̕s���׸�
      gt_data_tab(ln_data_cnt)(cv_case_class)               := gt_edi_order_tab(ln_loop_cnt).case_class;                   -- ����敪
      -- �u�}�̋敪�v���A'�����'�̏ꍇ
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        -- �u���גP�ʁv���A'�P�[�X�P�ʃR�[�h'�̏ꍇ
        IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- ��������(�ް�)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(���v����)
        -- �u���גP�ʁv���A'�{�[���P�ʃR�[�h'�̏ꍇ
        ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := cn_0;                                                       -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(�ް�)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(���v����)
        -- ��L�ȊO�̏ꍇ
        ELSE
          gt_data_tab(ln_data_cnt)(cv_indv_order_qty)       := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_case_order_qty)       := cn_0;                                                       -- ��������(���)
          gt_data_tab(ln_data_cnt)(cv_ball_order_qty)       := cn_0;                                                       -- ��������(�ް�)
          gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- ��������(���v����)
        END IF;
      -- ��L�ȊO�̏ꍇ
      ELSE
        gt_data_tab(ln_data_cnt)(cv_indv_order_qty)         := gt_edi_order_tab(ln_loop_cnt).indv_order_qty;               -- ��������(���)
        gt_data_tab(ln_data_cnt)(cv_case_order_qty)         := gt_edi_order_tab(ln_loop_cnt).case_order_qty;               -- ��������(���)
        gt_data_tab(ln_data_cnt)(cv_ball_order_qty)         := gt_edi_order_tab(ln_loop_cnt).ball_order_qty;               -- ��������(�ް�)
        gt_data_tab(ln_data_cnt)(cv_sum_order_qty)          := gt_edi_order_tab(ln_loop_cnt).sum_order_qty;                -- ��������(���v����)
      END IF;
--
--****************************** 2009/06/24 1.10 T.Kitajima MOD START ******************************--
--      -- �u���גP�ʁv���A'�P�[�X�P�ʃR�[�h'�̏ꍇ
--      IF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_case_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- �o�א���(�ް�)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���v����)
--      -- �u���גP�ʁv���A'�{�[���P�ʃR�[�h'�̏ꍇ
--      ELSIF ( gt_edi_order_tab(ln_loop_cnt).line_uom = gv_ball_uom_code ) THEN
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(�ް�)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���v����)
--      -- ��L�ȊO�̏ꍇ
--      ELSE
--        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- �o�א���(���)
--        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- �o�א���(�ް�)
--        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���v����)
--      END IF;
--
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���v����)
-- ********* 2009/09/25 1.13 N.Maeda MOD START ********* --
      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).ordered_quantity;             -- �o�א���(���v����)
--      gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)             := gt_edi_order_tab(ln_loop_cnt).sum_shipping_qty;             -- �o�א���(���v����)
-- ********* 2009/09/25 1.13 N.Maeda MOD  END  ********* --
--
      xxcos_common2_pkg.convert_quantity(
/* 2009/07/24 Ver1.11 Mod Start */
--               iv_uom_code             => gt_data_tab(ln_data_cnt)(cv_uom_code)               --IN :�P�ʃR�[�h
               iv_uom_code             => gt_edi_order_tab(ln_loop_cnt).order_quantity_uom --IN :�P�ʃR�[�h
/* 2009/07/24 Ver1.11 Mod End   */
              ,in_case_qty             => gt_data_tab(ln_data_cnt)(cv_num_of_cases)        --IN :�P�[�X����
              ,in_ball_qty             => NVL( gt_edi_order_tab(ln_loop_cnt).num_of_ball
                                              ,gt_edi_order_tab(ln_loop_cnt).bowl_inc_num
                                             )                                             --IN :�{�[������
              ,in_sum_indv_order_qty   => gt_data_tab(ln_data_cnt)(cv_sum_order_qty)        --IN :��������(���v�E�o��)
              ,in_sum_shipping_qty     => gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)        --IN :�o�א���(���v�E�o��)
              ,on_indv_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)       --OUT:�o�א���(�o��)
              ,on_case_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_case_ship_qty)       --OUT:�o�א���(�P�[�X)
              ,on_ball_shipping_qty    => gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)       --OUT:�o�א���(�{�[��)
              ,on_indv_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)     --OUT:���i����(�o��)
              ,on_case_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)     --OUT:���i����(�P�[�X)
              ,on_ball_stockout_qty    => gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)     --OUT:���i����(�{�[��)
              ,on_sum_stockout_qty     => gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)      --OUT:���i����(���v�E�o��)
              ,ov_errbuf               => lv_errbuf                                        --OUT:�G���[�E���b�Z�[�W�G���[ #�Œ�#
              ,ov_retcode              => lv_retcode                                       --OUT:���^�[���E�R�[�h         #�Œ�#
              ,ov_errmsg               => lv_errmsg                                        --���[�U�[�E�G���[�E���b�Z�[�W #�Œ�#
              );
      IF ( lv_retcode = cv_status_error ) THEN
--        lv_errmsg := lv_errbuf;
        RAISE global_api_expt;
      END IF;
--****************************** 2009/06/24 1.10 T.Kitajima MOD  END  ******************************--
-- 2009/05/22 Ver1.9 Add Start
      -- ���i�R�[�h(�ɓ���)�v���A�_�~�[�i�ڂ̏ꍇ�A�S��"0"�ɕύX
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_indv_ship_qty)          := cn_0;                                                       -- �o�א���(���)
        gt_data_tab(ln_data_cnt)(cv_case_ship_qty)          := cn_0;                                                       -- �o�א���(���)
        gt_data_tab(ln_data_cnt)(cv_ball_ship_qty)          := cn_0;                                                       -- �o�א���(�ް�)
        gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)           := cn_0;                                                       -- �o�א���(���v����)
      END IF;
-- 2009/05/22 Ver1.9 Add End
      gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty)          := NULL;                                                       -- �o�א���(��گ�)
--****************************** 2009/06/24 1.10 T.Kitajima DEL START ******************************--
--/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_indv_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);                 -- ���i����(���)
--    gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_case_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_case_ship_qty);                 -- ���i����(���)
--    gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := gt_data_tab(ln_data_cnt)(cv_ball_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);                 -- ���i����(�ް�)
--    gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := gt_data_tab(ln_data_cnt)(cv_sum_order_qty)
--                                                           - gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);                  -- ���i����(���v����)
--      gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);         -- ���i����(���)
--      gt_data_tab(ln_data_cnt)(cv_case_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);         -- ���i����(���)
--      gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty)          := NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);         -- ���i����(�ް�)
--      gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0)
--                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);          -- ���i����(���v����)
--/* 2009/02/25 Ver1.4 Mod  End  */
--****************************** 2009/06/24 1.10 T.Kitajima DEL  END  ******************************--
      -- ���i����(�󒍐��ʁ|�o�א���)���O�̏ꍇ
      IF ( gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty) = cn_0 ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := cv_stockout_class_00;                                       -- ���i�敪
      ELSE
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gt_edi_order_tab(ln_loop_cnt).stockout_class;               -- ���i�敪
      END IF;
-- 2009/05/22 Ver1.9 Mod Start
      -- ���i�R�[�h(�ɓ���)�v���A�_�~�[�i�ڂ̏ꍇ�A�v���t�@�C���l�ɏC��
      IF ( ln_dummy_item = cn_1) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_class)           := gn_dum_stock_out;                                           -- ���i�敪
      END IF;
-- 2009/05/22 Ver1.9 Mod End
      gt_data_tab(ln_data_cnt)(cv_stkout_reason)            := NULL;                                                       -- ���i���R
      gt_data_tab(ln_data_cnt)(cv_case_qty)                 := gt_edi_order_tab(ln_loop_cnt).case_qty;                     -- �������
      gt_data_tab(ln_data_cnt)(cv_fold_container_indv_qty)  := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;      -- �غ�(���)����
      gt_data_tab(ln_data_cnt)(cv_order_unit_price)         := gt_edi_order_tab(ln_loop_cnt).order_unit_price;             -- ���P��(����)
      gt_data_tab(ln_data_cnt)(cv_ship_unit_price)          := gt_edi_order_tab(ln_loop_cnt).unit_selling_price;           -- ���P��(�o��)
      gt_data_tab(ln_data_cnt)(cv_order_cost_amt)           := gt_edi_order_tab(ln_loop_cnt).order_cost_amt;               -- �������z(����)
/* 2009/02/25 Ver1.4 Mod Start */
--    gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_ship_unit_price);               -- �������z(�o��)
--    gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)          := gt_data_tab(ln_data_cnt)(cv_order_cost_amt)
--                                                           - gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);                 -- �������z(���i)
/* 2009/07/21 Ver1.11 Mod Start */
--      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
--                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0);       -- �������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_ship_cost_amt)            := TRUNC(NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_ship_unit_price), 0));      -- �������z(�o��)
/* 2009/07/21 Ver1.11 Mod End   */
/* 2009/02/27 Ver1.5 Mod Start */
      -- �u�}�̋敪�v���A'�����'�̏ꍇ
      IF ( gt_edi_order_tab(ln_loop_cnt).medium_class = cv_medium_class_mnl ) THEN
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := cn_0;                                                       -- �������z(���i)
      ELSE
        gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt)        := NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0)
                                                             - NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);         -- �������z(���i)
      END IF;
/* 2009/02/27 Ver1.5 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_selling_price)            := gt_edi_order_tab(ln_loop_cnt).selling_price;                -- ���P��
      gt_data_tab(ln_data_cnt)(cv_order_price_amt)          := gt_edi_order_tab(ln_loop_cnt).order_price_amt;              -- �������z(����)
--    gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- �������z(�o��)
--    gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty)
--                                                           * gt_data_tab(ln_data_cnt)(cv_selling_price);                 -- �������z(���i)
      gt_data_tab(ln_data_cnt)(cv_ship_price_amt)           := NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- �������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_stkout_price_amt)         := NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0)
                                                             * NVL(gt_data_tab(ln_data_cnt)(cv_selling_price), 0);         -- �������z(���i)
/* 2009/02/25 Ver1.4 Mod  End  */
      gt_data_tab(ln_data_cnt)(cv_a_column_department)      := gt_edi_order_tab(ln_loop_cnt).a_column_department;          -- A��(�S�ݓX)
      gt_data_tab(ln_data_cnt)(cv_d_column_department)      := gt_edi_order_tab(ln_loop_cnt).d_column_department;          -- D��(�S�ݓX)
      gt_data_tab(ln_data_cnt)(cv_standard_info_depth)      := gt_edi_order_tab(ln_loop_cnt).standard_info_depth;          -- �K�i��񥉜�s��
      gt_data_tab(ln_data_cnt)(cv_standard_info_height)     := gt_edi_order_tab(ln_loop_cnt).standard_info_height;         -- �K�i��񥍂��
      gt_data_tab(ln_data_cnt)(cv_standard_info_width)      := gt_edi_order_tab(ln_loop_cnt).standard_info_width;          -- �K�i��񥕝
      gt_data_tab(ln_data_cnt)(cv_standard_info_weight)     := gt_edi_order_tab(ln_loop_cnt).standard_info_weight;         -- �K�i���d��
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item1)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item1;      -- �ėp���p������1
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item2)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item2;      -- �ėp���p������2
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item3)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item3;      -- �ėp���p������3
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item4)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item4;      -- �ėp���p������4
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item5)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item5;      -- �ėp���p������5
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item6)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item6;      -- �ėp���p������6
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item7)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item7;      -- �ėp���p������7
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item8)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item8;      -- �ėp���p������8
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item9)            := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item9;      -- �ėp���p������9
      gt_data_tab(ln_data_cnt)(cv_gen_suc_item10)           := gt_edi_order_tab(ln_loop_cnt).general_succeeded_item10;     -- �ėp���p������10
      gt_data_tab(ln_data_cnt)(cv_gen_add_item1)            := gt_edi_order_tab(ln_loop_cnt).tax_rate;                     -- �ėp�t������1
      gt_data_tab(ln_data_cnt)(cv_gen_add_item2)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 1, 10);
                                                                                                                           -- �ėp�t������2
      gt_data_tab(ln_data_cnt)(cv_gen_add_item3)            := SUBSTRB(gt_edi_order_tab(ln_loop_cnt).address_lines_phonetic, 11, 10);
                                                                                                                           -- �ėp�t������3
      gt_data_tab(ln_data_cnt)(cv_gen_add_item4)            := gt_edi_order_tab(ln_loop_cnt).general_add_item4;            -- �ėp�t������4
      gt_data_tab(ln_data_cnt)(cv_gen_add_item5)            := gt_edi_order_tab(ln_loop_cnt).general_add_item5;            -- �ėp�t������5
      gt_data_tab(ln_data_cnt)(cv_gen_add_item6)            := gt_edi_order_tab(ln_loop_cnt).general_add_item6;            -- �ėp�t������6
      gt_data_tab(ln_data_cnt)(cv_gen_add_item7)            := gt_edi_order_tab(ln_loop_cnt).general_add_item7;            -- �ėp�t������7
      gt_data_tab(ln_data_cnt)(cv_gen_add_item8)            := gt_edi_order_tab(ln_loop_cnt).general_add_item8;            -- �ėp�t������8
      gt_data_tab(ln_data_cnt)(cv_gen_add_item9)            := gt_edi_order_tab(ln_loop_cnt).general_add_item9;            -- �ėp�t������9
      gt_data_tab(ln_data_cnt)(cv_gen_add_item10)           := gt_edi_order_tab(ln_loop_cnt).general_add_item10;           -- �ėp�t������10
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_line)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_line;     -- ���ݓX�ŗL�ر(����)
--
      -- �t�b�^
      gt_data_tab(ln_data_cnt)(cv_invc_indv_order_qty)        := NULL;  -- (�`�[�v)��������(���)
      gt_data_tab(ln_data_cnt)(cv_invc_case_order_qty)        := NULL;  -- (�`�[�v)��������(���)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_order_qty)        := NULL;  -- (�`�[�v)��������(�ް�)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_order_qty)         := NULL;  -- (�`�[�v)��������(���v����)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_ship_qty)         := NULL;  -- (�`�[�v)�o�א���(���)
      gt_data_tab(ln_data_cnt)(cv_invc_case_ship_qty)         := NULL;  -- (�`�[�v)�o�א���(���)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_ship_qty)         := NULL;  -- (�`�[�v)�o�א���(�ް�)
      gt_data_tab(ln_data_cnt)(cv_invc_pallet_ship_qty)       := NULL;  -- (�`�[�v)�o�א���(��گ�)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_ship_qty)          := NULL;  -- (�`�[�v)�o�א���(���v����)
      gt_data_tab(ln_data_cnt)(cv_invc_indv_stkout_qty)       := NULL;  -- (�`�[�v)���i����(���)
      gt_data_tab(ln_data_cnt)(cv_invc_case_stkout_qty)       := NULL;  -- (�`�[�v)���i����(���)
      gt_data_tab(ln_data_cnt)(cv_invc_ball_stkout_qty)       := NULL;  -- (�`�[�v)���i����(�ް�)
      gt_data_tab(ln_data_cnt)(cv_invc_sum_stkout_qty)        := NULL;  -- (�`�[�v)���i����(���v����)
      gt_data_tab(ln_data_cnt)(cv_invc_case_qty)              := NULL;  -- (�`�[�v)�������
      gt_data_tab(ln_data_cnt)(cv_invc_fold_container_qty)    := gt_edi_order_tab(ln_loop_cnt).fold_container_indv_qty;     -- (�`�[�v)�غ�(���)����
      gt_data_tab(ln_data_cnt)(cv_invc_order_cost_amt)        := NULL;  -- (�`�[�v)�������z(����)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_cost_amt)         := NULL;  -- (�`�[�v)�������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_cost_amt)       := NULL;  -- (�`�[�v)�������z(���i)
      gt_data_tab(ln_data_cnt)(cv_invc_order_price_amt)       := NULL;  -- (�`�[�v)�������z(����)
      gt_data_tab(ln_data_cnt)(cv_invc_ship_price_amt)        := NULL;  -- (�`�[�v)�������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_invc_stkout_price_amt)      := NULL;  -- (�`�[�v)�������z(���i)
      gt_data_tab(ln_data_cnt)(cv_t_indv_order_qty)           := NULL;  -- (�����v)��������(���)
      gt_data_tab(ln_data_cnt)(cv_t_case_order_qty)           := NULL;  -- (�����v)��������(���)
      gt_data_tab(ln_data_cnt)(cv_t_ball_order_qty)           := NULL;  -- (�����v)��������(�ް�)
      gt_data_tab(ln_data_cnt)(cv_t_sum_order_qty)            := NULL;  -- (�����v)��������(���v����)
      gt_data_tab(ln_data_cnt)(cv_t_indv_ship_qty)            := NULL;  -- (�����v)�o�א���(���)
      gt_data_tab(ln_data_cnt)(cv_t_case_ship_qty)            := NULL;  -- (�����v)�o�א���(���)
      gt_data_tab(ln_data_cnt)(cv_t_ball_ship_qty)            := NULL;  -- (�����v)�o�א���(�ް�)
      gt_data_tab(ln_data_cnt)(cv_t_pallet_ship_qty)          := NULL;  -- (�����v)�o�א���(��گ�)
      gt_data_tab(ln_data_cnt)(cv_t_sum_ship_qty)             := NULL;  -- (�����v)�o�א���(���v����)
      gt_data_tab(ln_data_cnt)(cv_t_indv_stkout_qty)          := NULL;  -- (�����v)���i����(���)
      gt_data_tab(ln_data_cnt)(cv_t_case_stkout_qty)          := NULL;  -- (�����v)���i����(���)
      gt_data_tab(ln_data_cnt)(cv_t_ball_stkout_qty)          := NULL;  -- (�����v)���i����(�ް�)
      gt_data_tab(ln_data_cnt)(cv_t_sum_stkout_qty)           := NULL;  -- (�����v)���i����(���v����)
      gt_data_tab(ln_data_cnt)(cv_t_case_qty)                 := NULL;  -- (�����v)�������
      gt_data_tab(ln_data_cnt)(cv_t_fold_container_qty)       := NULL;  -- (�����v)�غ�(���)����
      gt_data_tab(ln_data_cnt)(cv_t_order_cost_amt)           := NULL;  -- (�����v)�������z(����)
      gt_data_tab(ln_data_cnt)(cv_t_ship_cost_amt)            := NULL;  -- (�����v)�������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_cost_amt)          := NULL;  -- (�����v)�������z(���i)
      gt_data_tab(ln_data_cnt)(cv_t_order_price_amt)          := NULL;  -- (�����v)�������z(����)
      gt_data_tab(ln_data_cnt)(cv_t_ship_price_amt)           := NULL;  -- (�����v)�������z(�o��)
      gt_data_tab(ln_data_cnt)(cv_t_stkout_price_amt)         := NULL;  -- (�����v)�������z(���i)
      gt_data_tab(ln_data_cnt)(cv_t_line_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_line_qty;              -- İ�ٍs��
      gt_data_tab(ln_data_cnt)(cv_t_invc_qty)                 := gt_edi_order_tab(ln_loop_cnt).total_invoice_qty;           -- İ�ٓ`�[����
      gt_data_tab(ln_data_cnt)(cv_chain_pec_area_footer)      := gt_edi_order_tab(ln_loop_cnt).chain_peculiar_area_footer;  -- ���ݓX�ŗL�ر(̯�)
/* 2009/04/28 Ver1.7 Add Start */
      gt_data_tab(ln_data_cnt)(cv_attribute)                  := NULL;  -- �\���G���A
/* 2009/04/28 Ver1.7 Add End   */
--
      --==============================================================
      -- �`�[�ʍ��v�Z�o
      --==============================================================
/* 2009/02/25 Ver1.4 Mod Start */
/*
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_order_qty);    -- ��������(�o��)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_order_qty);    -- ��������(�P�[�X)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_order_qty);    -- ��������(�{�[��)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_order_qty);     -- ��������(���v�A�o��)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);     -- �o�א���(�o��)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_ship_qty);     -- �o�א���(�P�[�X)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);     -- �o�א���(�{�[��)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);   -- �o�א���(�p���b�g)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);      -- �o�א���(���v�A�o��)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);   -- ���i����(�o��)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);   -- ���i����(�P�[�X)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);   -- ���i����(�{�[��)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);    -- ���i����(���v�A�o��)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + gt_data_tab(ln_data_cnt)(cv_case_qty);          -- �P�[�X����
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_cost_amt);    -- �������z(����)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);     -- �������z(�o��)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);   -- �������z(���i)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_order_price_amt);   -- �������z(����)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_ship_price_amt);    -- �������z(�o��)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);  -- �������z(���i)
*/
      l_invoice_total_rec.indv_order_qty      := l_invoice_total_rec.indv_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_order_qty), 0);    -- ��������(�o��)
      l_invoice_total_rec.case_order_qty      := l_invoice_total_rec.case_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_order_qty), 0);    -- ��������(�P�[�X)
      l_invoice_total_rec.ball_order_qty      := l_invoice_total_rec.ball_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_order_qty), 0);    -- ��������(�{�[��)
      l_invoice_total_rec.sum_order_qty       := l_invoice_total_rec.sum_order_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_order_qty), 0);     -- ��������(���v�A�o��)
      l_invoice_total_rec.indv_shipping_qty   := l_invoice_total_rec.indv_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_ship_qty), 0);     -- �o�א���(�o��)
      l_invoice_total_rec.case_shipping_qty   := l_invoice_total_rec.case_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_ship_qty), 0);     -- �o�א���(�P�[�X)
      l_invoice_total_rec.ball_shipping_qty   := l_invoice_total_rec.ball_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_ship_qty), 0);     -- �o�א���(�{�[��)
      l_invoice_total_rec.pallet_shipping_qty := l_invoice_total_rec.pallet_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty), 0);   -- �o�א���(�p���b�g)
      l_invoice_total_rec.sum_shipping_qty    := l_invoice_total_rec.sum_shipping_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_ship_qty), 0);      -- �o�א���(���v�A�o��)
      l_invoice_total_rec.indv_stockout_qty   := l_invoice_total_rec.indv_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty), 0);   -- ���i����(�o��)
      l_invoice_total_rec.case_stockout_qty   := l_invoice_total_rec.case_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_stkout_qty), 0);   -- ���i����(�P�[�X)
      l_invoice_total_rec.ball_stockout_qty   := l_invoice_total_rec.ball_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty), 0);   -- ���i����(�{�[��)
      l_invoice_total_rec.sum_stockout_qty    := l_invoice_total_rec.sum_stockout_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty), 0);    -- ���i����(���v�A�o��)
      l_invoice_total_rec.case_qty            := l_invoice_total_rec.case_qty
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_case_qty), 0);          -- �P�[�X����
      l_invoice_total_rec.order_cost_amt      := l_invoice_total_rec.order_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_cost_amt), 0);    -- �������z(����)
      l_invoice_total_rec.shipping_cost_amt   := l_invoice_total_rec.shipping_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_cost_amt), 0);     -- �������z(�o��)
      l_invoice_total_rec.stockout_cost_amt   := l_invoice_total_rec.stockout_cost_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt), 0);   -- �������z(���i)
      l_invoice_total_rec.order_price_amt     := l_invoice_total_rec.order_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_order_price_amt), 0);   -- �������z(����)
      l_invoice_total_rec.shipping_price_amt  := l_invoice_total_rec.shipping_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_ship_price_amt), 0);    -- �������z(�o��)
      l_invoice_total_rec.stockout_price_amt  := l_invoice_total_rec.stockout_price_amt
                                               + NVL(gt_data_tab(ln_data_cnt)(cv_stkout_price_amt), 0);  -- �������z(���i)
/* 2009/02/25 Ver1.4 Mod  End  */
--
      --==============================================================
      -- EDI���׏��ҏW
      --==============================================================
      gt_edi_line_tab(ln_loop_cnt).edi_line_info_id    := gt_edi_order_tab(ln_loop_cnt).edi_line_info_id;     -- EDI���׏��ID
      gt_edi_line_tab(ln_loop_cnt).edi_header_info_id  := gt_edi_order_tab(ln_loop_cnt).edi_header_info_id;   -- EDI�w�b�_���ID
      gt_edi_line_tab(ln_loop_cnt).line_no             := gt_data_tab(ln_data_cnt)(cv_line_no);               -- �s�m��
      gt_edi_line_tab(ln_loop_cnt).stockout_class      := gt_data_tab(ln_data_cnt)(cv_stkout_class);          -- ���i�敪
      gt_edi_line_tab(ln_loop_cnt).stockout_reason     := gt_data_tab(ln_data_cnt)(cv_stkout_reason);         -- ���i���R
      gt_edi_line_tab(ln_loop_cnt).product_code_itouen := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- ���i�R�[�h(�ɓ���)
      gt_edi_line_tab(ln_loop_cnt).jan_code            := gt_data_tab(ln_data_cnt)(cv_jan_code);              -- JAN�R�[�h
      gt_edi_line_tab(ln_loop_cnt).itf_code            := gt_data_tab(ln_data_cnt)(cv_itf_code);              -- ITF�R�[�h
      gt_edi_line_tab(ln_loop_cnt).prod_class          := gt_data_tab(ln_data_cnt)(cv_prod_class);            -- ���i�敪
      gt_edi_line_tab(ln_loop_cnt).product_name        := gt_data_tab(ln_data_cnt)(cv_prod_name);             -- ���i��(����)
      gt_edi_line_tab(ln_loop_cnt).product_name2_alt   := gt_data_tab(ln_data_cnt)(cv_prod_name2_alt);        -- ���i��2(�J�i)
      gt_edi_line_tab(ln_loop_cnt).item_standard2      := gt_data_tab(ln_data_cnt)(cv_item_standard2);        -- �K�i2
      gt_edi_line_tab(ln_loop_cnt).num_of_cases        := gt_data_tab(ln_data_cnt)(cv_num_of_cases);          -- �P�[�X����
      gt_edi_line_tab(ln_loop_cnt).num_of_ball         := gt_data_tab(ln_data_cnt)(cv_num_of_ball);           -- �{�[������
      gt_edi_line_tab(ln_loop_cnt).indv_order_qty      := gt_data_tab(ln_data_cnt)(cv_indv_order_qty);        -- ��������(�o��)
      gt_edi_line_tab(ln_loop_cnt).case_order_qty      := gt_data_tab(ln_data_cnt)(cv_case_order_qty);        -- ��������(�P�[�X)
      gt_edi_line_tab(ln_loop_cnt).ball_order_qty      := gt_data_tab(ln_data_cnt)(cv_ball_order_qty);        -- ��������(�{�[��)
      gt_edi_line_tab(ln_loop_cnt).sum_order_qty       := gt_data_tab(ln_data_cnt)(cv_sum_order_qty);         -- ��������(���v�A�o��)
      gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_indv_ship_qty);         -- �o�א���(�o��)
      gt_edi_line_tab(ln_loop_cnt).case_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_case_ship_qty);         -- �o�א���(�P�[�X)
      gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty   := gt_data_tab(ln_data_cnt)(cv_ball_ship_qty);         -- �o�א���(�{�[��)
      gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty := gt_data_tab(ln_data_cnt)(cv_pallet_ship_qty);       -- �o�א���(�p���b�g)
      gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty    := gt_data_tab(ln_data_cnt)(cv_sum_ship_qty);          -- �o�א���(���v�A�o��)
      gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_indv_stkout_qty);       -- ���i����(�o��)
      gt_edi_line_tab(ln_loop_cnt).case_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_case_stkout_qty);       -- ���i����(�P�[�X)
      gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty   := gt_data_tab(ln_data_cnt)(cv_ball_stkout_qty);       -- ���i����(�{�[��)
      gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty    := gt_data_tab(ln_data_cnt)(cv_sum_stkout_qty);        -- ���i����(���v�A�o��)
      gt_edi_line_tab(ln_loop_cnt).shipping_unit_price := gt_data_tab(ln_data_cnt)(cv_ship_unit_price);       -- ���P��(�o��)
      gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt   := gt_data_tab(ln_data_cnt)(cv_ship_cost_amt);         -- �������z(�o��)
      gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt   := gt_data_tab(ln_data_cnt)(cv_stkout_cost_amt);       -- �������z(���i)
      gt_edi_line_tab(ln_loop_cnt).shipping_price_amt  := gt_data_tab(ln_data_cnt)(cv_ship_price_amt);        -- �������z(�o��)
      gt_edi_line_tab(ln_loop_cnt).stockout_price_amt  := gt_data_tab(ln_data_cnt)(cv_stkout_price_amt);      -- �������z(���i)
      gt_edi_line_tab(ln_loop_cnt).general_add_item1   := gt_data_tab(ln_data_cnt)(cv_gen_add_item1);         -- �ėp�t������1
      gt_edi_line_tab(ln_loop_cnt).general_add_item2   := gt_data_tab(ln_data_cnt)(cv_gen_add_item2);         -- �ėp�t������2
      gt_edi_line_tab(ln_loop_cnt).general_add_item3   := gt_data_tab(ln_data_cnt)(cv_gen_add_item3);         -- �ėp�t������3
      gt_edi_line_tab(ln_loop_cnt).item_code           := gt_data_tab(ln_data_cnt)(cv_prod_code_itouen);      -- �i�ڃR�[�h
    END LOOP edit_loop;
--
    --==============================================================
    -- �G���[�̏ꍇ
    --==============================================================
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- �f�[�^���`(A-7)
    --==============================================================
    format_data(
       iv_make_class        -- 2.�쐬�敪
      ,l_invoice_total_rec  -- �`�[�v
      ,lt_header_id         -- EDI�w�b�_���ID
      ,lt_delivery_flag     -- EDI�[�i�\�著�M�σt���O
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
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
  END edit_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �t�@�C���o��(A-8)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    --==============================================================
    -- �t�@�C���o��
    --==============================================================
    <<output_loop>>
    FOR ln_loop_cnt IN 1 .. gt_data_record_tab.COUNT LOOP
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
         file   => gt_f_handle                      -- �t�@�C���n���h��
        ,buffer => gt_data_record_tab(ln_loop_cnt)  -- �o�͕���(�f�[�^)
      );
      -- ���폈�������J�E���g
      gn_normal_cnt := gn_normal_cnt + cn_1;
    END LOOP output_loop;
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : �t�@�C���I������(A-9)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer'; -- �v���O������
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
/* 2009/04/28 Ver1.7 Mod Start */
--    lv_footer_output  VARCHAR2(1000);  -- �t�b�^�o�͗p
    lv_footer_output  VARCHAR2(5000);  -- �t�b�^�o�͗p
/* 2009/04/28 Ver1.7 Mod End   */
    lv_dummy1         VARCHAR2(1);     -- IF���Ɩ��n��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy2         VARCHAR2(1);     -- ���_�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy3         VARCHAR2(1);     -- ���_����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy4         VARCHAR2(1);     -- �`�F�[���X�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy5         VARCHAR2(1);     -- �`�F�[���X����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy6         VARCHAR2(1);     -- �f�[�^��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy7         VARCHAR2(1);     -- ���񏈗��ԍ�(�t�b�^�ł͎g�p���Ȃ�)
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
    --==============================================================
    -- ���ʊ֐��Ăяo��
    --==============================================================
    -- EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
       iv_add_area        =>  gv_if_footer      -- �t�^�敪
      ,iv_from_series     =>  lv_dummy1         -- IF���Ɩ��n��R�[�h
      ,iv_base_code       =>  lv_dummy2         -- ���_�R�[�h
      ,iv_base_name       =>  lv_dummy3         -- ���_����
      ,iv_chain_code      =>  lv_dummy4         -- �`�F�[���X�R�[�h
      ,iv_chain_name      =>  lv_dummy5         -- �`�F�[���X����
      ,iv_data_kind       =>  lv_dummy6         -- �f�[�^��R�[�h
      ,iv_row_number      =>  lv_dummy7         -- ���񏈗��ԍ�
      ,in_num_of_records  =>  gn_target_cnt     -- ���R�[�h����
      ,ov_retcode         =>  lv_retcode        -- ���^�[���R�[�h
      ,ov_output          =>  lv_footer_output  -- �t�b�^���R�[�h
      ,ov_errbuf          =>  lv_errbuf         -- �G���[���b�Z�[�W
      ,ov_errmsg          =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_com_fnuc_err  -- EDI���ʊ֐��G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_err_msg       -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_errmsg            -- �G���[�E���b�Z�[�W
                   );
      RAISE global_api_others_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C���o��
    --==============================================================
    -- �t�b�^�o��
    UTL_FILE.PUT_LINE(
       file   => gt_f_handle       -- �t�@�C���n���h��
      ,buffer => lv_footer_output  -- �o�͕���(�t�b�^)
    );
--
    --==============================================================
    -- �t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(
       file => gt_f_handle
    );
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
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : update_edi_order
   * Description      : EDI�󒍏��X�V(A-10)
   ***********************************************************************************/
  PROCEDURE update_edi_order(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_edi_order'; -- �v���O������
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
    lv_tkn_value1      VARCHAR2(50);    -- �g�[�N���擾�p1
    lv_tkn_value2      VARCHAR2(50);    -- �g�[�N���擾�p2
    lv_err_msg         VARCHAR2(5000);  -- �G���[�o�͗p
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
    --==============================================================
    -- EDI�w�b�_���X�V
    --==============================================================
    <<update_header_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_header_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_headers  xeh
        SET    xeh.process_date                = gt_edi_header_tab(ln_loop_cnt).process_date                 -- ������
              ,xeh.process_time                = gt_edi_header_tab(ln_loop_cnt).process_time                 -- ��������
              ,xeh.base_code                   = gt_edi_header_tab(ln_loop_cnt).base_code                    -- ���_(����)�R�[�h
              ,xeh.base_name                   = gt_edi_header_tab(ln_loop_cnt).base_name                    -- ���_��(������)
              ,xeh.base_name_alt               = gt_edi_header_tab(ln_loop_cnt).base_name_alt                -- ���_��(�J�i)
              ,xeh.customer_code               = gt_edi_header_tab(ln_loop_cnt).customer_code                -- �ڋq�R�[�h
              ,xeh.customer_name               = gt_edi_header_tab(ln_loop_cnt).customer_name                -- �ڋq��(����)
              ,xeh.customer_name_alt           = gt_edi_header_tab(ln_loop_cnt).customer_name_alt            -- �ڋq��(�J�i)
              ,xeh.shop_name                   = gt_edi_header_tab(ln_loop_cnt).shop_name                    -- �X��(����)
              ,xeh.shop_name_alt               = gt_edi_header_tab(ln_loop_cnt).shop_name_alt                -- �X��(�J�i)
              ,xeh.center_delivery_date        = gt_edi_header_tab(ln_loop_cnt).center_delivery_date         -- �Z���^�[�[�i��
              ,xeh.order_no_ebs                = gt_edi_header_tab(ln_loop_cnt).order_no_ebs                 -- ��No(EBS)
              ,xeh.contact_to                  = gt_edi_header_tab(ln_loop_cnt).contact_to                   -- �A����
              ,xeh.area_code                   = gt_edi_header_tab(ln_loop_cnt).area_code                    -- �n��R�[�h
              ,xeh.area_name                   = gt_edi_header_tab(ln_loop_cnt).area_name                    -- �n�於(����)
              ,xeh.area_name_alt               = gt_edi_header_tab(ln_loop_cnt).area_name_alt                -- �n�於(�J�i)
              ,xeh.vendor_code                 = gt_edi_header_tab(ln_loop_cnt).vendor_code                  -- �����R�[�h
              ,xeh.vendor_name                 = gt_edi_header_tab(ln_loop_cnt).vendor_name                  -- ����於(����)
              ,xeh.vendor_name1_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name1_alt             -- ����於1(�J�i)
              ,xeh.vendor_name2_alt            = gt_edi_header_tab(ln_loop_cnt).vendor_name2_alt             -- ����於2(�J�i)
              ,xeh.vendor_tel                  = gt_edi_header_tab(ln_loop_cnt).vendor_tel                   -- �����TEL
              ,xeh.vendor_charge               = gt_edi_header_tab(ln_loop_cnt).vendor_charge                -- �����S����
              ,xeh.vendor_address              = gt_edi_header_tab(ln_loop_cnt).vendor_address               -- �����Z��(����)
              ,xeh.delivery_schedule_time      = gt_edi_header_tab(ln_loop_cnt).delivery_schedule_time       -- �[�i�\�莞��
              ,xeh.carrier_means               = gt_edi_header_tab(ln_loop_cnt).carrier_means                -- �^����i
              ,xeh.eos_handwriting_class       = gt_edi_header_tab(ln_loop_cnt).eos_handwriting_class        -- EOS��菑�敪
              ,xeh.invoice_indv_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_indv_order_qty       -- (�`�[�v)��������(�o��)
              ,xeh.invoice_case_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_case_order_qty       -- (�`�[�v)��������(�P�[�X)
              ,xeh.invoice_ball_order_qty      = gt_edi_header_tab(ln_loop_cnt).invoice_ball_order_qty       -- (�`�[�v)��������(�{�[��)
              ,xeh.invoice_sum_order_qty       = gt_edi_header_tab(ln_loop_cnt).invoice_sum_order_qty        -- (�`�[�v)��������(���v�A�o��)
              ,xeh.invoice_indv_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_shipping_qty    -- (�`�[�v)�o�א���(�o��)
              ,xeh.invoice_case_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_shipping_qty    -- (�`�[�v)�o�א���(�P�[�X)
              ,xeh.invoice_ball_shipping_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_shipping_qty    -- (�`�[�v)�o�א���(�{�[��)
              ,xeh.invoice_pallet_shipping_qty = gt_edi_header_tab(ln_loop_cnt).invoice_pallet_shipping_qty  -- (�`�[�v)�o�א���(�p���b�g)
              ,xeh.invoice_sum_shipping_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_shipping_qty     -- (�`�[�v)�o�א���(���v�A�o��)
              ,xeh.invoice_indv_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_indv_stockout_qty    -- (�`�[�v)���i����(�o��)
              ,xeh.invoice_case_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_case_stockout_qty    -- (�`�[�v)���i����(�P�[�X)
              ,xeh.invoice_ball_stockout_qty   = gt_edi_header_tab(ln_loop_cnt).invoice_ball_stockout_qty    -- (�`�[�v)���i����(�{�[��)
              ,xeh.invoice_sum_stockout_qty    = gt_edi_header_tab(ln_loop_cnt).invoice_sum_stockout_qty     -- (�`�[�v)���i����(���v�A�o��)
              ,xeh.invoice_case_qty            = gt_edi_header_tab(ln_loop_cnt).invoice_case_qty             -- (�`�[�v)�P�[�X����
              ,xeh.invoice_fold_container_qty  = gt_edi_header_tab(ln_loop_cnt).invoice_fold_container_qty   -- (�`�[�v)�I���R��(�o��)����
              ,xeh.invoice_order_cost_amt      = gt_edi_header_tab(ln_loop_cnt).invoice_order_cost_amt       -- (�`�[�v)�������z(����)
              ,xeh.invoice_shipping_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_cost_amt    -- (�`�[�v)�������z(�o��)
              ,xeh.invoice_stockout_cost_amt   = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_cost_amt    -- (�`�[�v)�������z(���i)
              ,xeh.invoice_order_price_amt     = gt_edi_header_tab(ln_loop_cnt).invoice_order_price_amt      -- (�`�[�v)�������z(����)
              ,xeh.invoice_shipping_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_shipping_price_amt   -- (�`�[�v)�������z(�o��)
              ,xeh.invoice_stockout_price_amt  = gt_edi_header_tab(ln_loop_cnt).invoice_stockout_price_amt   -- (�`�[�v)�������z(���i)
              ,xeh.edi_delivery_schedule_flag  = gt_edi_header_tab(ln_loop_cnt).edi_delivery_schedule_flag   -- EDI�[�i�\�著�M�σt���O
              ,xeh.last_updated_by             = cn_last_updated_by                                          -- �ŏI�X�V��
              ,xeh.last_update_date            = cd_last_update_date                                         -- �ŏI�X�V��
              ,xeh.last_update_login           = cn_last_update_login                                        -- �ŏI�X�V۸޲�
              ,xeh.request_id                  = cn_request_id                                               -- �v��ID
              ,xeh.program_application_id      = cn_program_application_id                                   -- �ݶ��ĥ��۸��ѥ���ع����ID
              ,xeh.program_id                  = cn_program_id                                               -- �ݶ��ĥ��۸���ID
              ,xeh.program_update_date         = cd_program_update_date                                      -- ��۸��эX�V��
        WHERE  xeh.edi_header_info_id          = gt_edi_header_tab(ln_loop_cnt).edi_header_info_id           -- EDI�w�b�_���ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_tbl2  -- EDI�w�b�_���e�[�u��
                           );
          -- ���b�Z�[�W�擾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_data_upd_err  -- �f�[�^�X�V�G���[���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_value1        -- EDI�w�b�_���e�[�u��
                         ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_header_loop;
--
    --==============================================================
    -- EDI���׏��X�V
    --==============================================================
    <<update_line_loop>>
    FOR ln_loop_cnt IN 1 .. gt_edi_line_tab.COUNT LOOP
      BEGIN
        UPDATE xxcos_edi_lines  xel
        SET    xel.stockout_class          = gt_edi_line_tab(ln_loop_cnt).stockout_class       -- ���i�敪
              ,xel.stockout_reason         = gt_edi_line_tab(ln_loop_cnt).stockout_reason      -- ���i���R
              ,xel.product_code_itouen     = gt_edi_line_tab(ln_loop_cnt).product_code_itouen  -- ���i�R�[�h(�ɓ���)
              ,xel.jan_code                = gt_edi_line_tab(ln_loop_cnt).jan_code             -- JAN�R�[�h
              ,xel.itf_code                = gt_edi_line_tab(ln_loop_cnt).itf_code             -- ITF�R�[�h
              ,xel.prod_class              = gt_edi_line_tab(ln_loop_cnt).prod_class           -- ���i�敪
              ,xel.product_name            = gt_edi_line_tab(ln_loop_cnt).product_name         -- ���i��(����)
              ,xel.product_name2_alt       = gt_edi_line_tab(ln_loop_cnt).product_name2_alt    -- ���i��2(�J�i)
              ,xel.item_standard2          = gt_edi_line_tab(ln_loop_cnt).item_standard2       -- �K�i2
              ,xel.num_of_cases            = gt_edi_line_tab(ln_loop_cnt).num_of_cases         -- �P�[�X����
              ,xel.num_of_ball             = gt_edi_line_tab(ln_loop_cnt).num_of_ball          -- �{�[������
              ,xel.indv_order_qty          = gt_edi_line_tab(ln_loop_cnt).indv_order_qty       -- ��������(�o��)
              ,xel.case_order_qty          = gt_edi_line_tab(ln_loop_cnt).case_order_qty       -- ��������(�P�[�X)
              ,xel.ball_order_qty          = gt_edi_line_tab(ln_loop_cnt).ball_order_qty       -- ��������(�{�[��)
              ,xel.sum_order_qty           = gt_edi_line_tab(ln_loop_cnt).sum_order_qty        -- ��������(���v�A�o��)
              ,xel.indv_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).indv_shipping_qty    -- �o�א���(�o��)
              ,xel.case_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).case_shipping_qty    -- �o�א���(�P�[�X)
              ,xel.ball_shipping_qty       = gt_edi_line_tab(ln_loop_cnt).ball_shipping_qty    -- �o�א���(�{�[��)
              ,xel.pallet_shipping_qty     = gt_edi_line_tab(ln_loop_cnt).pallet_shipping_qty  -- �o�א���(�p���b�g)
              ,xel.sum_shipping_qty        = gt_edi_line_tab(ln_loop_cnt).sum_shipping_qty     -- �o�א���(���v�A�o��)
              ,xel.indv_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).indv_stockout_qty    -- ���i����(�o��)
              ,xel.case_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).case_stockout_qty    -- ���i����(�P�[�X)
              ,xel.ball_stockout_qty       = gt_edi_line_tab(ln_loop_cnt).ball_stockout_qty    -- ���i����(�{�[��)
              ,xel.sum_stockout_qty        = gt_edi_line_tab(ln_loop_cnt).sum_stockout_qty     -- ���i����(���v�A�o��)
              ,xel.shipping_unit_price     = gt_edi_line_tab(ln_loop_cnt).shipping_unit_price  -- ���P��(�o��)
              ,xel.shipping_cost_amt       = gt_edi_line_tab(ln_loop_cnt).shipping_cost_amt    -- �������z(�o��)
              ,xel.stockout_cost_amt       = gt_edi_line_tab(ln_loop_cnt).stockout_cost_amt    -- �������z(���i)
              ,xel.shipping_price_amt      = gt_edi_line_tab(ln_loop_cnt).shipping_price_amt   -- �������z(�o��)
              ,xel.stockout_price_amt      = gt_edi_line_tab(ln_loop_cnt).stockout_price_amt   -- �������z(���i)
              ,xel.general_add_item1       = gt_edi_line_tab(ln_loop_cnt).general_add_item1    -- �ėp�t������1
              ,xel.general_add_item2       = gt_edi_line_tab(ln_loop_cnt).general_add_item2    -- �ėp�t������2
              ,xel.general_add_item3       = gt_edi_line_tab(ln_loop_cnt).general_add_item3    -- �ėp�t������3
              ,xel.item_code               = gt_edi_line_tab(ln_loop_cnt).item_code            -- �i�ڃR�[�h
              ,xel.last_updated_by         = cn_last_updated_by                                -- �ŏI�X�V��
              ,xel.last_update_date        = cd_last_update_date                               -- �ŏI�X�V��
              ,xel.last_update_login       = cn_last_update_login                              -- �ŏI�X�V۸޲�
              ,xel.request_id              = cn_request_id                                     -- �v��ID
              ,xel.program_application_id  = cn_program_application_id                         -- �ݶ��ĥ��۸��ѥ���ع����ID
              ,xel.program_id              = cn_program_id                                     -- �ݶ��ĥ��۸���ID
              ,xel.program_update_date     = cd_program_update_date                            -- ��۸��эX�V��
        WHERE  xel.edi_line_info_id        = gt_edi_line_tab(ln_loop_cnt).edi_line_info_id     -- EDI���׏��ID
        AND    xel.edi_header_info_id      = gt_edi_line_tab(ln_loop_cnt).edi_header_info_id   -- EDI�w�b�_���ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_tkn_value1 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application   -- �A�v���P�[�V����
                             ,iv_name         => cv_msg_tkn_tbl3  -- EDI�w�b�_���e�[�u��
                           );
          -- ���b�Z�[�W�擾
          ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application       -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_data_upd_err  -- �f�[�^�X�V�G���[���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_value1        -- EDI�w�b�_���e�[�u��
                         ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL                 -- NULL
                       );
          RAISE global_api_others_expt;
      END;
    END LOOP update_line_loop;
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
  END update_edi_order;
--
  /**********************************************************************************
   * Procedure Name   : generate_edi_trans
   * Description      : EDI�[�i�\�著�M�t�@�C���쐬(A-3...A-10)
   ***********************************************************************************/
  PROCEDURE generate_edi_trans(
    iv_file_name        IN  VARCHAR2,     --   1.�t�@�C����
    iv_make_class       IN  VARCHAR2,     --   2.�쐬�敪
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI�`���ǔ�
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI�`���ǔ�(�t�@�C�����p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,     --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,     --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,     --   9.�n��R�[�h
    iv_center_date      IN  VARCHAR2,     --  10.�Z���^�[�[�i��
    iv_delivery_time    IN  VARCHAR2,     --  11.�[�i����
    iv_delivery_charge  IN  VARCHAR2,     --  12.�[�i�S����
    iv_carrier_means    IN  VARCHAR2,     --  13.�A����i
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'generate_edi_trans'; -- �v���O������
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
    --==============================================================
    -- ����̓f�[�^�o�^(A-3)
    --==============================================================
    get_manual_order(
       iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI�`���ǔ�
      ,iv_edi_f_number_s   --  5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.�X�ܔ[�i��From
      ,iv_shop_date_to     --  7.�X�ܔ[�i��To
      ,iv_sale_class       --  8.��ԓ����敪
      ,iv_area_code        --  9.�n��R�[�h
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �t�@�C����������(A-4)
    --==============================================================
    output_header(
       iv_file_name        --  1.�t�@�C����
      ,iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI�`���ǔ�
      ,iv_edi_f_number_f   --  4.EDI�`���ǔ�(�t�@�C�����p)
/* 2009/05/12 Ver1.8 Mod End   */
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- EDI�󒍏�񒊏o(A-5)
    --==============================================================
    input_edi_order(
       iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI�`���ǔ�
      ,iv_edi_f_number_s   --  5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.�X�ܔ[�i��From
      ,iv_shop_date_to     --  7.�X�ܔ[�i��To
      ,iv_sale_class       --  8.��ԓ����敪
      ,iv_area_code        --  9.�n��R�[�h
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
      --==============================================================
      -- �f�[�^�ҏW(A-6)
      --==============================================================
      edit_data(
         iv_make_class       --  2.�쐬�敪
        ,iv_center_date      --  9.�Z���^�[�[�i��
        ,iv_delivery_time    -- 10.�[�i����
        ,iv_delivery_charge  -- 11.�[�i�S����
        ,iv_carrier_means    -- 12.�A����i
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      -- �t�@�C���o��(A-8)
      --==============================================================
      output_data(
         lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- �t�@�C���I������(A-9)
    --==============================================================
    output_footer(
       lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    IF ( gn_target_cnt <> cn_0 ) THEN
    --==============================================================
    -- EDI�󒍏��X�V(A-10)
    --==============================================================
      update_edi_order(
         lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
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
  END generate_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : release_edi_trans
   * Description      : EDI�[�i�\�著�M�ς݉���(A-12)
   ***********************************************************************************/
  PROCEDURE release_edi_trans(
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
    iv_proc_date        IN  VARCHAR2,     --  13.������
    iv_proc_time        IN  VARCHAR2,     --  14.��������
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'release_edi_trans'; -- �v���O������
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
    lv_tkn_value1  VARCHAR2(50);    -- �g�[�N���擾�p1
--
/* 2009/05/12 Ver1.8 Add Start */
    -- *** ���[�J��TABLE�^ ***
    TYPE l_header_id_ttype IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE INDEX BY BINARY_INTEGER;
    lt_update_header_id    l_header_id_ttype;
/* 2009/05/12 Ver1.8 Add Start */
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR edi_header_lock_cur
    IS
      SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDI�w�b�_���.EDI�w�b�_���ID
      FROM   xxcos_edi_headers       xeh                                             -- EDI�w�b�_���
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- ���̓p�����[�^�̏�����
      AND    xeh.process_time               = iv_proc_time                           -- ���̓p�����[�^�̏�������
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- ���̓p�����[�^��EDI�`�F�[���X�R�[�h
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- ���M��
      FOR UPDATE OF
             xeh.edi_header_info_id  NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
/* 2009/05/12 Ver1.8 Del Start */
--    lt_edi_header_lock  edi_header_lock_cur%ROWTYPE;
/* 2009/05/12 Ver1.8 Del End   */
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
    -- EDI�w�b�_���e�[�u�����s���b�N
    OPEN  edi_header_lock_cur;
/* 2009/05/12 Ver1.8 Mod Start */
--    FETCH edi_header_lock_cur INTO lt_edi_header_lock;
    FETCH edi_header_lock_cur BULK COLLECT INTO lt_update_header_id;
    -- ���o�����擾
/* 2010/03/01 Ver1.15 Del Start */
--    gn_target_cnt := edi_header_lock_cur%ROWCOUNT;
/* 2010/03/01 Ver1.15 Del  End  */
/* 2009/05/12 Ver1.8 Mod End */
    CLOSE edi_header_lock_cur;
/* 2010/03/01 Ver1.15 Add Start */
    SELECT COUNT(1)                                                                 -- ���׌���
    INTO   gn_target_cnt                                                            -- �Ώی���
    FROM   xxcos_edi_lines  xel                                                     -- EDI���׏��e�[�u��
    WHERE  xel.edi_header_info_id IN (
                                       SELECT xeh.edi_header_info_id  edi_header_info_id                              -- EDI�w�b�_���.EDI�w�b�_���ID
                                       FROM   xxcos_edi_headers       xeh                                             -- EDI�w�b�_���
                                       WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- ���̓p�����[�^�̏�����
                                       AND    xeh.process_time               = iv_proc_time                           -- ���̓p�����[�^�̏�������
                                       AND    xeh.edi_chain_code             = iv_edi_c_code                          -- ���̓p�����[�^��EDI�`�F�[���X�R�[�h
                                       AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- ���M��
                                     );                                              -- EDI�w�b�_���ID = ���b�N���擾����EDI�w�b�_���ID
/* 2010/03/01 Ver1.15 Add  End  */
--
    -- EDI�w�b�_���e�[�u�����X�V
    BEGIN
      UPDATE xxcos_edi_headers  xeh                                                  -- EDI�w�b�_���
      SET    xeh.edi_delivery_schedule_flag = cv_n                                   -- EDI�[�i�\�著�M�σt���O
            ,xeh.last_updated_by            = cn_last_updated_by                     -- �ŏI�X�V��
            ,xeh.last_update_date           = cd_last_update_date                    -- �ŏI�X�V��
            ,xeh.last_update_login          = cn_last_update_login                   -- �ŏI�X�V۸޲�
            ,xeh.request_id                 = cn_request_id                          -- �v��ID
            ,xeh.program_application_id     = cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
            ,xeh.program_id                 = cn_program_id                          -- �ݶ��ĥ��۸���ID
            ,xeh.program_update_date        = cd_program_update_date                 -- ��۸��эX�V��
      WHERE  TRUNC(xeh.process_date)        = TO_DATE(iv_proc_date, cv_date_format)  -- ���̓p�����[�^�̏�����
      AND    xeh.process_time               = iv_proc_time                           -- ���̓p�����[�^�̏�������
      AND    xeh.edi_chain_code             = iv_edi_c_code                          -- ���̓p�����[�^��EDI�`�F�[���X�R�[�h
      AND    xeh.edi_delivery_schedule_flag = cv_y                                   -- ���M��
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_tkn_value1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application   -- �A�v���P�[�V����
                           ,iv_name         => cv_msg_tkn_tbl2  -- EDI�w�b�_���e�[�u��
                         );
        -- ���b�Z�[�W�擾
        ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V����
                       ,iv_name         => cv_msg_data_upd_err  -- �f�[�^�X�V�G���[���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_value1        -- EDI�w�b�_���e�[�u��
                       ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                       ,iv_token_value2 => iv_edi_c_code        -- ���̓p�����[�^��EDI�`�F�[���X�R�[�h
                     );
        RAISE global_api_others_expt;
    END;
--
/* 2009/05/12 Ver1.8 Add Start */
    -- ���팏���擾
    gn_normal_cnt := gn_target_cnt;
/* 2009/05/12 Ver1.8 Add End */
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( edi_header_lock_cur%ISOPEN ) THEN
        CLOSE edi_header_lock_cur;
      END IF;
      -- �g�[�N���擾
      lv_tkn_value1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application   -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_tkn_tbl2  -- EDI�w�b�_���e�[�u��
                       );
      -- ���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     -- �A�v���P�[�V����
                     ,iv_name         => cv_msg_lock_err    -- ���b�N�G���[���b�Z�[�W
                     ,iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_value1      -- EDI�w�b�_���e�[�u��
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
  END release_edi_trans;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name        IN  VARCHAR2,     --   1.�t�@�C����
    iv_make_class       IN  VARCHAR2,     --   2.�쐬�敪
    iv_edi_c_code       IN  VARCHAR2,     --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,     --   4.EDI�`���ǔ�
    iv_edi_f_number_f   IN  VARCHAR2,     --   4.EDI�`���ǔ�(�t�@�C�����p)
    iv_edi_f_number_s   IN  VARCHAR2,     --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,     --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,     --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,     --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,     --   9.�n��R�[�h
    iv_center_date      IN  VARCHAR2,     --  10.�Z���^�[�[�i��
    iv_delivery_time    IN  VARCHAR2,     --  11.�[�i����
    iv_delivery_charge  IN  VARCHAR2,     --  12.�[�i�S����
    iv_carrier_means    IN  VARCHAR2,     --  13.�A����i
    iv_proc_date        IN  VARCHAR2,     --  14.������
    iv_proc_time        IN  VARCHAR2,     --  15.��������
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �p�����[�^�`�F�b�N(A-1)
    -- ===============================
    check_param(
       iv_file_name        --  1.�t�@�C����
      ,iv_make_class       --  2.�쐬�敪
      ,iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --  4.EDI�`���ǔ�
      ,iv_edi_f_number_f   --  4.EDI�`���ǔ�(�t�@�C�����p)
      ,iv_edi_f_number_s   --  5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --  6.�X�ܔ[�i��From
      ,iv_shop_date_to     --  7.�X�ܔ[�i��To
      ,iv_sale_class       --  8.��ԓ����敪
      ,iv_area_code        --  9.�n��R�[�h
      ,iv_center_date      -- 10.�Z���^�[�[�i��
      ,iv_delivery_time    -- 11.�[�i����
      ,iv_delivery_charge  -- 12.�[�i�S����
      ,iv_carrier_means    -- 13.�A����i
      ,iv_proc_date        -- 14.������
      ,iv_proc_time        -- 15.��������
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��������(A-2)
    -- ===============================
    init(
       iv_make_class       --  2.�쐬�敪
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �u�쐬�敪�v���A'���M'��'���x���쐬'�̏ꍇ
    IF ( iv_make_class = cv_make_class_transe )
    OR ( iv_make_class = cv_make_class_label )
    THEN
      -- ===============================
      -- EDI�[�i�\�著�M�t�@�C���쐬(A-3...A-10)
      -- ===============================
      generate_edi_trans(
         iv_file_name        --  1.�t�@�C����
        ,iv_make_class       --  2.�쐬�敪
        ,iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--        ,iv_edi_f_number     --  4.EDI�`���ǔ�
        ,iv_edi_f_number_f   --  4.EDI�`���ǔ�(�t�@�C�����p)
        ,iv_edi_f_number_s   --  5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
        ,iv_shop_date_from   --  6.�X�ܔ[�i��From
        ,iv_shop_date_to     --  7.�X�ܔ[�i��To
        ,iv_sale_class       --  8.��ԓ����敪
        ,iv_area_code        --  9.�n��R�[�h
        ,iv_center_date      -- 10.�Z���^�[�[�i��
        ,iv_delivery_time    -- 11.�[�i����
        ,iv_delivery_charge  -- 12.�[�i�S����
        ,iv_carrier_means    -- 13.�A����i
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �t�@�C����OPEN����Ă���ꍇ�N���[�Y
        IF ( UTL_FILE.IS_OPEN( file => gt_f_handle )) THEN
          UTL_FILE.FCLOSE( file => gt_f_handle );
        END IF;
        RAISE global_process_expt;
      END IF;
--
    -- �u�쐬�敪�v���A'����'�̏ꍇ
    ELSIF ( iv_make_class = cv_make_class_release ) THEN
      -- ===============================
      -- EDI�[�i�\�著�M�ς݉���(A-12)
      -- ===============================
      release_edi_trans(
         iv_edi_c_code       --  3.EDI�`�F�[���X�R�[�h
        ,iv_proc_date        -- 13.������
        ,iv_proc_time        -- 14.��������
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name        IN  VARCHAR2,      --   1.�t�@�C����
    iv_make_class       IN  VARCHAR2,      --   2.�쐬�敪
    iv_edi_c_code       IN  VARCHAR2,      --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--    iv_edi_f_number     IN  VARCHAR2,      --   4.EDI�`���ǔ�
    iv_edi_f_number_f   IN  VARCHAR2,      --   4.EDI�`���ǔ�(�t�@�C�����p)
    iv_edi_f_number_s   IN  VARCHAR2,      --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
    iv_shop_date_from   IN  VARCHAR2,      --   6.�X�ܔ[�i��From
    iv_shop_date_to     IN  VARCHAR2,      --   7.�X�ܔ[�i��To
    iv_sale_class       IN  VARCHAR2,      --   8.��ԓ����敪
    iv_area_code        IN  VARCHAR2,      --   9.�n��R�[�h
    iv_center_date      IN  VARCHAR2,      --  10.�Z���^�[�[�i��
    iv_delivery_time    IN  VARCHAR2,      --  11.�[�i����
    iv_delivery_charge  IN  VARCHAR2,      --  12.�[�i�S����
    iv_carrier_means    IN  VARCHAR2,      --  13.�A����i
    iv_proc_date        IN  VARCHAR2,      --  14.������
    iv_proc_time        IN  VARCHAR2       --  15.��������
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
       iv_file_name        --   1.�t�@�C����
      ,iv_make_class       --   2.�쐬�敪
      ,iv_edi_c_code       --   3.EDI�`�F�[���X�R�[�h
/* 2009/05/12 Ver1.8 Mod Start */
--      ,iv_edi_f_number     --   4.EDI�`���ǔ�
      ,iv_edi_f_number_f   --   4.EDI�`���ǔ�(�t�@�C�����p)
      ,iv_edi_f_number_s   --   5.EDI�`���ǔ�(���o�����p)
/* 2009/05/12 Ver1.8 Mod End   */
      ,iv_shop_date_from   --   6.�X�ܔ[�i��From
      ,iv_shop_date_to     --   7.�X�ܔ[�i��To
      ,iv_sale_class       --   8.��ԓ����敪
      ,iv_area_code        --   9.�n��R�[�h
      ,iv_center_date      --  10.�Z���^�[�[�i��
      ,iv_delivery_time    --  11.�[�i����
      ,iv_delivery_charge  --  12.�[�i�S����
      ,iv_carrier_means    --  13.�A����i
      ,iv_proc_date        --  14.������
      ,iv_proc_time        --  15.��������
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
/* 2009/02/24 Ver1.2 Mod Start */
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
--  END IF;
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
/* 2009/02/24 Ver1.2 Mod  End  */
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/02/24 Ver1.2 Add Start */
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
/* 2009/02/24 Ver1.2 Add  End  */
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
END XXCOS011A03C;
/
