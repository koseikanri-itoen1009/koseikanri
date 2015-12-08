CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A06C (body)
 * Description      : �����u�c�|���쐬
 * MD.050           : �����u�c�|���쐬 MD050_COS_004_A06
 * Version          : 1.19
 *
 * Program List
 * -------------------------  ----------------------------------------------------------
 *  Name                        Description
 * -------------------------  ----------------------------------------------------------
 *  init                        ��������(A-0)
 *  chk_parameter               �p�����[�^�`�F�b�N(A-1)
 *  lock_hdrs_lns_data          ����VD�p�����v�Z�w�b�_�A���׃f�[�^���b�N����(A-2-1)
 *  del_tt_vd_digestion         ����VD�����v�Z���̍���f�[�^�폜 (A-3)
 *  ini_header                  �w�b�_�P�ʏ��������� (A-4)
 *  get_cust_trx                AR������擾���� (A-5)
 *  get_vd_column               VD�R�����ʎ�����擾���� (A-7)
 *  ins_vd_digestion_ln         ����VD�ʗp�����v�Z���דo�^���� (A-9)
 *  upd_vd_column_hdr           VD�R�����ʎ���w�b�_���X�V���� (A-11)
 *  ins_vd_digestion_hdr        ����VD�ʗp�����v�Z�w�b�_�o�^���� (A-12)
 *  get_operation_day           �ғ������擾���� (A-13)
 *  get_non_operation_day       ��ғ������擾���� (A-14)
 *  del_blt_vd_digestion        ����VD�����v�Z���̑O�X��f�[�^�폜 (A-15)
 *  calc_due_day                �����Z�o���� (A-16)
 *  calc_pre_diges_due_dt       �O������v�Z���N�����Z�o���� (A-18)
 *  upd_pre_not_digestion_due   �O�񖢌v�Z�f�[�^�X�V����(A-20)
 *  chk_pre_not_digestion_due   �O�񖢌v�Z�f�[�^�`�F�b�N����(A-21)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/03    1.1   T.Kitajima       [COS_009]�x���I�����Ƀ��b�Z�[�W���\������Ȃ�
 *  2009/02/04    1.2   K.Kakishita      [COS_012]���z�v�Z���̊|�����}�X�^�|���łȂ�
 *  2009/02/04    1.3   K.Kakishita      [COS_018]������s�̏ꍇ�A�����v�Z���ߓ��R�̎擾�~�X
 *  2009/02/06    1.4   K.Kakishita      [COS_037]AR����^�C�v�}�X�^�̒��o�����ɉc�ƒP�ʂ�ǉ�
 *  2009/02/20    1.5   K.Kakishita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/19    1.6   T.Kitajima       [T1_0098]�ۊǏꏊ���o�����C��
 *  2009/04/13    1.7   N.Maeda          [T1_0496]VD�R�����ʎ����񖾍ׂ̐��ʎg�p��
 *                                                  ��VD�R�����ʎ����񖾍ׂ̕�[���֕ύX
 *  2009/05/01    1.8   N.Maeda          [T1_0496]���J�o���p�p�����[�^�ǉ�
 *  2009/07/16    1.9   M.Sano           [0000319]DISC�i�ڕύX�����A�h�I���̒艿���擾���Ȃ�
 *                                       [0000432]PT�̍l��
 *  2009/08/04    1.10  N.Maeda          [0000922]PT�̍l��
 *  2009/08/05    1.10  N.Maeda          [0000922]���r���[�w�E�Ή�
 *  2009/08/06    1.10  N.Maeda          [0000922]�ă��r���[�w�E�Ή�
 *  2010/01/19    1.11  K.Atsushiba      [E_�{�ғ�_00622]�����v�Z���N�������o�����C��
 *  2010/01/25    1.12  K.Atsushiba      [E_�{�ғ�_01386]�O�X��f�[�^���폜���Ȃ悤�ɏC��
 *  2010/02/15    1.13  K.Hosoi          [E_�{�ғ�_01394]����i���ւ��j���[�h�̒ǉ��B����VD�p
 *                                       �����v�Z�w�b�_�A���׃f�[�^���b�N�����̒ǉ��B
 *                                       [E_�{�ғ�_01396]���v�Z�̃f�[�^���c���Ă����ꍇ�A����
 *                                       �����ł����Ă��v�Z���Ȃ��悤�C���B
 *                                       [E_�{�ғ�_01397]�|���ɑ΂���臒l�`�F�b�N�����̒ǉ��B
 *  2010/03/24    1.14  K.Atsushiba      [E_�{�ғ�_01805]�ڋq�ڍs�Ή�
 *  2010/04/05    1.15  H.Sasaki         [E_�{�ғ�_01688]�W��t���O��ǉ�
 *  2010/05/02    1.16  T.Ishiwata       [E_�{�ғ�_02552]�o�s�Ή�
 *  2010/05/06    1.17  M.Sano           [E_�{�ғ�_02565]�O������v�Z���N�������擾�ł��Ȃ��ꍇ��
 *                                                       �l���R��Ή�
 *  2010/05/07    1.18  M.Sano           [E_�{�ғ�_02575]VD�R�����ʎ�����̕ʖ��ׂŏd���폜�����
 *                                                       ���ۂ̏C��
 *  2015/10/19    1.19  K.Kiriu          [E_�{�ғ�_13355]�ۊǏꏊ�G���[�X�L�b�v�Ή�
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
  global_data_lock_expt     EXCEPTION;                                --���b�N�擾�G���[��O
  global_target_nodata_expt EXCEPTION;                                --�Ώۃf�[�^�����G���[��O
  global_get_profile_expt   EXCEPTION;                                --�v���t�@�C���擾�G���[��O
  global_require_param_expt EXCEPTION;                                --�K�{���̓p�����[�^���ݒ�G���[��O
  global_insert_data_expt   EXCEPTION;                                --�f�[�^�o�^�G���[��O
  global_update_data_expt   EXCEPTION;                                --�f�[�^�X�V�G���[��O
  global_delete_data_expt   EXCEPTION;                                --�f�[�^�폜�G���[��O
  global_select_data_expt   EXCEPTION;                                --�f�[�^�擾�G���[��O
  global_proc_date_err_expt EXCEPTION;                                --�Ɩ����t�擾�G���[��O
  global_call_api_expt      EXCEPTION;                                --API�ďo�G���[��O
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS004A06C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name      CONSTANT fnd_application.application_short_name%TYPE
                                         := 'XXCOS';                --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00001';     --���b�N�擾�G���[���b�Z�[�W
  ct_msg_target_nodata_err      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00003';     --�Ώۃf�[�^�����G���[
  ct_msg_get_profile_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00004';     --�v���t�@�C���擾�G���[
  ct_msg_require_param_err      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00006';     --�K�{���̓p�����[�^���ݒ�G���[
  ct_msg_insert_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00010';     --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_update_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00011';     --�f�[�^�X�V�G���[���b�Z�[�W
  ct_msg_delete_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00012';     --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_select_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00013';     --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err       CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00014';     --�Ɩ����t�擾�G���[
  ct_msg_call_api_err           CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00017';     --API�ďo�G���[���b�Z�[�W
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_msg_thrshld_chk_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14004';     --臒l�`�F�b�N�G���[���b�Z�[�W
  ct_msg_lock_error_skip        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14005';     --���b�N�G���[���b�Z�[�W
  ct_msg_lock_error             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14006';     --���b�N�G���[���b�Z�[�W
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --������p
  ct_msg_request                CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00042';     --�v���h�c
  ct_msg_org_id                 CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00047';     --MO:�c�ƒP��
  ct_msg_get_organization_code  CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00048';     --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_item_mst               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00050';     --�i�ڃ}�X�^
  ct_msg_subinv_mst             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00052';     --�ۊǏꏊ�}�X�^
  ct_msg_base_code              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00055';     --���_�R�[�h
  ct_msg_max_date               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00056';     --XXCOS:MAX���t
  ct_msg_min_date               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00120';     --XXCOS:MIN���t
  ct_msg_diges_calc_delay_day   CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00140';     --XXCOS:����VD�|���쐬�P�\��
  ct_msg_parameter              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11151';     --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_target_count           CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11152';     --�Ώی������b�Z�[�W
  ct_msg_warning_count          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11153';     --�x���������b�Z�[�W
  ct_msg_reg_any_cls_tblnm      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11154';     --��������敪�N�C�b�N�R�[�h�}�X�^
  ct_msg_get_organization_id    CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11155';     --�݌ɑg�DID�̎擾
  ct_msg_get_calendar_code      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11156';     --�J�����_�R�[�h�̎擾
  ct_msg_tt_diges_info_tblnm    CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11157';     --�����u�c�p�����v�Z���i����f�[�^�j
  ct_msg_tt_xvdh_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11158';     --�����u�c�p�����v�Z�w�b�_�e�[�u���i����f�[�^�j
  ct_msg_tt_xvdl_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11159';     --�����u�c�p�����v�Z���׃e�[�u���i����f�[�^�j
  ct_msg_blt_diges_info_tblnm   CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11160';     --�����u�c�p�����v�Z���i�O�X��f�[�^�j
  ct_msg_blt_xvdh_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11161';     --�����u�c�p�����v�Z�w�b�_�e�[�u���i�O�X��f�[�^�j
  ct_msg_blt_xvdl_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11162';     --�����u�c�p�����v�Z���׃e�[�u���i�O�X��f�[�^�j
  ct_msg_key_info1              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11163';     --�L�[���i�����v�Z���N�����A�ڋq�R�[�h�j
  ct_msg_key_info2              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11164';     --�L�[���i���_�R�[�h�A�݌ɑg�D�R�[�h�j
  ct_msg_key_info3              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11165';     --�L�[���i�i�ڃR�[�h�A�K�p���j
  ct_msg_key_info4              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11166';     --�L�[���i��No(HHT)�A�}�ԁj
  ct_msg_xvdh_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11167';     --�����u�c�p�����v�Z�w�b�_�e�[�u��
  ct_msg_xvdl_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11168';     --�����u�c�p�����v�Z���׃e�[�u��
  ct_msg_xvch_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11169';     --�u�c�R�����ʎ���w�b�_�e�[�u��
--ct_msg_ar_info_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11170';     --AR������
--ct_msg_ar_tax_info_tblnm      CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11171';     --AR������i�ŋ��f�[�^�j
--ct_msg_vdc_info_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11172';     --VD�R�����ʎ�����
  ct_msg_operation_day          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11173';     --�̔��p�ғ����`�F�b�N�֐��i�ғ����j
  ct_msg_nonoperation_day       CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11174';     --�̔��p�ғ����`�F�b�N�֐��i��ғ����j
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_msg_max_thrshld            CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14002';     --XXCOS:�ő�臒l(����VD)
  ct_msg_min_thrshld            CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14003';     --XXCOS:�ŏ�臒l(����VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --�g�[�N��
  cv_tkn_table                  CONSTANT VARCHAR2(100) := 'TABLE';                --�e�[�u��
  cv_tkn_profile                CONSTANT VARCHAR2(100) := 'PROFILE';              --�v���t�@�C��
  cv_tkn_table_name             CONSTANT VARCHAR2(100) := 'TABLE_NAME';           --�e�[�u������
  cv_tkn_key_data               CONSTANT VARCHAR2(100) := 'KEY_DATA';             --�L�[�f�[�^
  cv_tkn_in_param               CONSTANT VARCHAR2(100) := 'IN_PARAM';             --�L�[�f�[�^
  cv_tkn_api_name               CONSTANT VARCHAR2(100) := 'API_NAME';             --�`�o�h����
  cv_tkn_param1                 CONSTANT VARCHAR2(100) := 'PARAM1';               --��P���̓p�����[�^
  cv_tkn_param2                 CONSTANT VARCHAR2(100) := 'PARAM2';               --��Q���̓p�����[�^
  cv_tkn_param3                 CONSTANT VARCHAR2(100) := 'PARAM3';               --��R���̓p�����[�^
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
  cv_tkn_param4                 CONSTANT VARCHAR2(100) := 'PARAM4';               --��S���̓p�����[�^
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
  cv_tkn_count1                 CONSTANT VARCHAR2(100) := 'COUNT1';               --�����P
  cv_tkn_count2                 CONSTANT VARCHAR2(100) := 'COUNT2';               --�����Q
  cv_tkn_count3                 CONSTANT VARCHAR2(100) := 'COUNT3';               --�����R
  cv_tkn_diges_due_dt           CONSTANT VARCHAR2(100) := 'DIGES_DUE_DT';         --�����v�Z���N����
  cv_tkn_cust_code              CONSTANT VARCHAR2(100) := 'CUST_CODE';            --�ڋq�R�[�h
  cv_tkn_base_code              CONSTANT VARCHAR2(100) := 'BASE_CODE';            --���_�R�[�h
  cv_tkn_organization_code      CONSTANT VARCHAR2(100) := 'ORGANIZATION_CODE';    --�݌ɑg�D�R�[�h
  cv_tkn_item_code              CONSTANT VARCHAR2(100) := 'ITEM_CODE';            --���_�R�[�h
  cv_tkn_apply_date             CONSTANT VARCHAR2(100) := 'APPLY_DATE';           --�K�p��
  cv_tkn_order_no_hht           CONSTANT VARCHAR2(100) := 'ORDER_NO_HHT';         --��No(HHT)
  cv_tkn_digestion_ln_number    CONSTANT VARCHAR2(100) := 'DIGESTION_LN_NUMBER';  --�}��
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  cv_tkn_max_thrshld            CONSTANT VARCHAR2(100) := 'MAX_THRESHOLD';        --�ő�臒l
  cv_tkn_min_thrshld            CONSTANT VARCHAR2(100) := 'MIN_THRESHOLD';        --�ŏ�臒l
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --�v���t�@�C������
  ct_prof_org_id                CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'ORG_ID';                             --MO:�c�ƒP��
  ct_prof_min_date              CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MIN_DATE';                    --XXCOS:MIN���t
  ct_prof_max_date              CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MAX_DATE';                    --XXCOS:MAX���t
  ct_prof_organization_code     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOI1_ORGANIZATION_CODE';           --XXCOI:�݌ɑg�D�R�[�h
  ct_prof_diges_calc_delay_day  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_DIGESTION_CALC_DELAY_DAY';    --XXCOS:����VD�|���쐬�P�\����
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_prof_max_threshold_vd      CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MAX_THRESHOLD_VD';            --XXCOS:�ő�臒l(����VD)
  ct_prof_min_threshold_vd      CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MIN_THRESHOLD_VD';            --XXCOS:�ŏ�臒l(����VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_regular_any_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_REGULAR_ANY_CLASS';           --��������敪�}�X�^
  ct_qct_customer_trx_type      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_AR_TRX_TYPE_MST_004_A06';     --�`�q����^�C�v����}�X�^_004_A06
  ct_qct_hokan_type_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_HOKAN_TYPE_MST_004_A06';      --�ۊǏꏊ���ޓ���}�X�^_004_A06
  ct_qct_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_GYOTAI_SHO_MST_004_A06';      --�Ƒԏ����ޓ���}�X�^_004_A06
  ct_qct_cus_class_mst          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_CUS_CLASS_MST_004_A06';       --�ڋq�敪����}�X�^_004_A06
  --�N�C�b�N�R�[�h
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--  ct_qcc_customer_trx_type1     CONSTANT fnd_lookup_types.lookup_type%TYPE
--                                         := 'XXCOS_004_A06_1%';                   --�`�q����^�C�v����}�X�^(�ʏ�)
--  ct_qcc_customer_trx_type2     CONSTANT fnd_lookup_types.lookup_type%TYPE
--                                         := 'XXCOS_004_A06_2%';                   --�`�q����^�C�v����}�X�^(�N������)
-- 2009/07/16 Ver.1.9 M.Sano Del End
-- 2009/07/16 Ver.1.9 M.Sano Add Start
  ct_qcc_customer_trx_type      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06%';                     --�`�q����^�C�v����}�X�^
-- 2009/07/16 Ver.1.9 M.Sano Add End
  ct_qcc_hokan_type_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_%';                    --�ۊǏꏊ���ޓ���}�X�^
  ct_qcc_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_%';                    --�Ƒԏ����ޓ���}�X�^
  ct_qcc_cus_class_mst1         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_1%';                   --�ڋq�敪����}�X�^�i���_�j
  ct_qcc_cus_class_mst2         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_2%';                   --�ڋq�敪����}�X�^�i�ڋq�j
--
  --��������敪
  ct_regular_any_class_any      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '0';                      --����
  ct_regular_any_class_reg      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '1';                      --���
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_regular_any_class_rplc     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '2';                      --����i���ւ��j
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes           CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                         := 'Y';                      --�g�p�\
  --�̔����э쐬�σt���O
  ct_sr_creation_flag_yes       CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                         := 'Y';                      --�쐬��
  ct_sr_creation_flag_no        CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                         := 'N';                      --���쐬
  --���݃t���O
  cv_exists_flag_yes            CONSTANT VARCHAR2(1) := 'Y';          --���݂���
  cv_exists_flag_no             CONSTANT VARCHAR2(1) := 'N';          --���݂Ȃ�
  --���׃^�C�v
  ct_line_type_line             CONSTANT ra_customer_trx_lines_all.line_type%TYPE
                                         := 'LINE';                   --LINE
  ct_line_type_tax              CONSTANT ra_customer_trx_lines_all.line_type%TYPE
                                         := 'TAX';                    --TAX
  --�����t���O
  ct_complete_flag_yes          CONSTANT ra_customer_trx_all.complete_flag%TYPE
                                         := 'Y';                      --����
  --���v�Z�^�C�v
  cv_uncalculate_type_init      CONSTANT VARCHAR2(1) := '0';          --INIT
  cv_uncalculate_type_nof       CONSTANT VARCHAR2(1) := '1';          --NOF
  cv_uncalculate_type_zero      CONSTANT VARCHAR2(1) := '2';          --ZERO
  --���v�Z�敪
  ct_uncalculate_class_fnd      CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '0';                      --�f�[�^����
  ct_uncalculate_class_both_nof CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '1';                      --����NOF
  ct_uncalculate_class_ar_nof   CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '2';                      --AR_NOF
  ct_uncalculate_class_vdc_nof  CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '3';                      --VDC_NOF
  --�ғ����X�e�[�^�X
  cn_sales_oprtn_day_normal     CONSTANT NUMBER       := 0;           --�ғ���
  cn_sales_oprtn_day_non        CONSTANT NUMBER       := 1;           --��ғ���
  cn_sales_oprtn_day_error      CONSTANT NUMBER       := 2;           --�G���[
  --�[�N����p
  cv_month_february             CONSTANT VARCHAR2(2)  := '02';        --�Q��
  cv_last_day_28                CONSTANT VARCHAR2(2)  := '28';        --�Q�W��
  cv_last_day_29                CONSTANT VARCHAR2(2)  := '29';        --�Q�X��
  cv_last_day_30                CONSTANT VARCHAR2(2)  := '30';        --�R�O��
  --���z�f�t�H���g
  cn_amount_default             CONSTANT NUMBER       := 0;           --���z
  --1����
  cn_one_day                    CONSTANT NUMBER       := 1;
  --�t�H�[�}�b�g
  cv_fmt_date                   CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';
  --�|���[�������̈�
  cn_rate_fraction_place        CONSTANT NUMBER       := 2;
  --�[������
  cv_zero                       CONSTANT VARCHAR2(1)  := '0';
  --�K�p�t���O
  ct_apply_flag_yes             CONSTANT xxcmm_system_items_b_hst.apply_flag%TYPE
                                                      := 'Y';         --�K�p�ς�
-- 2009/07/16 Ver.1.9 M.Sano Add Start
  --����R�[�h
  ct_lang                       CONSTANT fnd_lookup_values.language%TYPE
                                                      := USERENV('LANG');
-- 2009/07/16 Ver.1.9 M.Sano Add End
--
/* 2010/01/25 Ver1.11 Add Start */
  cv_delete_flag                CONSTANT VARCHAR2(1) := 'D';          -- �폜�t���O
/* 2010/01/25 Ver1.11 Add End */
-- == 2010/04/05 V1.15 Added START ===============================================================
  cv_skip_flag                  CONSTANT VARCHAR2(1)  :=  'S';        --  �X�L�b�v�t���O
  cv_y                          CONSTANT VARCHAR2(1)  :=  'Y';
  cv_n                          CONSTANT VARCHAR2(1)  :=  'N';
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
-- 2010/03/24 Ver.1.14 Add Start
  cv_dya_fmt_month              CONSTANT VARCHAR2(2) := 'MM';         -- ��
-- 2010/03/24 Ver.1.14 Add End
--
-- 2010/05/02 Ver.1.16 T.Ishiwata Add Start
  --�Ƒԏ�����27:����VD
  cv_buz_type27                 CONSTANT VARCHAR2(2)  := '27';
-- 2010/05/02 Ver.1.16 T.Ishiwata Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --����VD�ʏ����v�Z�w�b�_�p
  TYPE g_xvdh_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_hdrs%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
  --����VD�ʏ����v�Z���חp
  TYPE g_xvdl_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_lns%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
  --�����v�Z���N�����p
  TYPE g_diges_due_dt_ttype
  IS
    TABLE OF
      DATE
    INDEX BY PLS_INTEGER
    ;
  --�ۊǏꏊ�}�X�^�`�F�b�N�p
  TYPE g_subinv_ttype
  IS
    TABLE OF
      mtl_secondary_inventories.secondary_inventory_name%TYPE
    INDEX BY VARCHAR2(10)
    ;
  --�i�ڃ}�X�^�`�F�b�N�p
  TYPE g_fixed_price_ttype
  IS
    TABLE OF
      xxcmm_system_items_b_hst.fixed_price%TYPE
    INDEX BY VARCHAR2(40)
    ;
  --�O������v�Z���N�����擾�p
  TYPE g_pre_diges_due_dt_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE
    INDEX BY PLS_INTEGER
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �Ώی���
  gn_target_cnt1                        NUMBER;                       -- �Ώی����P
  gn_target_cnt2                        NUMBER;                       -- �Ώی����Q
  gn_target_cnt3                        NUMBER;                       -- �Ώی����R
  -- �x������
  gn_warn_cnt1                          NUMBER;                       -- �X�L�b�v�����P
  gn_warn_cnt2                          NUMBER;                       -- �X�L�b�v�����Q
  gn_warn_cnt3                          NUMBER;                       -- �X�L�b�v�����R
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  gn_thrshld_chk_cnt                    NUMBER;                       -- 臒l�`�F�b�N�G���[����
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --�p�����[�^
  gt_regular_any_class                  fnd_lookup_values.lookup_code%TYPE;
                                                                      -- ��������敪
  gt_base_code                          hz_cust_accounts.account_number%TYPE;
                                                                      -- ���_�R�[�h
  gt_customer_number                    hz_cust_accounts.account_number%TYPE;
                                                                      -- �ڋq�R�[�h
  --�����擾
  gd_process_date                       DATE;                         -- �Ɩ����t
  gn_org_id                             NUMBER;                       -- �c�ƒP��
  gd_min_date                           DATE;                         -- MIN���t
  gd_max_date                           DATE;                         -- MAX���t
  gt_organization_code                  mtl_parameters.organization_code%TYPE;
                                                                      -- �݌ɑg�D�R�[�h
  gt_organization_id                    mtl_parameters.organization_id%TYPE;
                                                                      -- �݌ɑg�DID
  gt_calendar_code                      bom_calendars.calendar_code%TYPE;
                                                                      -- �J�����_�R�[�h
  gn_diges_calc_delay_day               NUMBER;                       -- ����VD�|���쐬�P�\����
  gd_temp_digestion_due_date            DATE;                         -- ������VD���N����
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  gn_max_threshold                      NUMBER;                       -- �ő�臒l(����VD)
  gn_min_threshold                      NUMBER;                       -- �ŏ�臒l(����VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --
  gt_vd_digestion_hdr_id                xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE;
                                                                      -- ����VD�����v�Z�w�b�_ID
  --�o�^�A�X�V�p�����e�[�u��
  gn_xvch_idx                           NUMBER;
  gn_tt_xvdh_idx                        NUMBER;
  gn_xvdh_idx                           NUMBER;
  gn_xvdl_idx                           NUMBER;
  g_xvch_tab                            g_xvdh_ttype;                 -- VD�R�����ʎ���w�b�_
  g_tt_xvdh_tab                         g_xvdh_ttype;                 -- ����f�[�^�폜�p����VD�ʏ����v�Z�w�b�_
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  g_tt_xvdh_work_tab                    g_xvdh_ttype;                 -- ����f�[�^�폜�p����VD�ʏ����v�Z�w�b�_���[�N
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  g_xvdh_tab                            g_xvdh_ttype;                 -- ����VD�ʏ����v�Z�w�b�_
  g_xvdl_tab                            g_xvdl_ttype;                 -- ����VD�ʏ����v�Z����
  g_diges_due_dt_tab                    g_diges_due_dt_ttype;         -- �����v�Z���N����
  --�ғ����v�Z�p�����v�Z���N����
  gd_calc_digestion_due_date            DATE;
  --�`�F�b�N�p�����e�[�u��
  g_chk_subinv_tab                      g_subinv_ttype;
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--  g_chk_fixed_price_tab                 g_fixed_price_ttype;
-- 2009/07/16 Ver.1.9 M.Sano End Start
  g_get_pre_diges_due_dt_tab            g_pre_diges_due_dt_ttype;
--
-- == 2010/04/05 V1.15 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : chk_pre_not_digestion_due
   * Description      : �O�񖢌v�Z�f�[�^�`�F�b�N����(A-21)
   ***********************************************************************************/
  PROCEDURE chk_pre_not_digestion_due(
    iv_customer_code        IN  VARCHAR2,     --  �ڋq�R�[�h
    od_pre_digest_due_date  OUT DATE,         --  �O������v�Z���N����
    ov_errbuf               OUT VARCHAR2,     --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_pre_not_digestion_due'; -- �v���O������
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
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    od_pre_digest_due_date  :=  NULL;
    --
    IF  (gt_regular_any_class IN(ct_regular_any_class_any, ct_regular_any_class_rplc))  THEN
      -- �����܂��́A����i���ցj�̏ꍇ
      BEGIN
        SELECT    xvdh.pre_digestion_due_date
        INTO      od_pre_digest_due_date
        FROM      xxcos_vd_digestion_hdrs       xvdh
        WHERE     xvdh.customer_number      =   iv_customer_code
        AND       xvdh.summary_data_flag    =   cv_y
        AND       ROWNUM = 1;
        --
        IF (od_pre_digest_due_date IS NULL) THEN
          od_pre_digest_due_date  :=  gd_min_date;
        END IF;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          NULL;
      END;
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
  END chk_pre_not_digestion_due;
  --
  /**********************************************************************************
   * Procedure Name   : upd_pre_not_digestion_due
   * Description      : �O�񖢌v�Z�f�[�^�X�V����(A-20)
   ***********************************************************************************/
  PROCEDURE upd_pre_not_digestion_due(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_pre_not_digestion_due'; -- �v���O������
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
    lv_str_table_name   VARCHAR2(50);
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  cur_lock_xvdh(iv_customer_number  IN  VARCHAR2)
    IS
      SELECT  xvdh.vd_digestion_hdr_id
      FROM    xxcos_vd_digestion_hdrs     xvdh
      WHERE   xvdh.summary_data_flag    =   cv_y
      AND     xvdh.customer_number      =   iv_customer_number
      FOR UPDATE  NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    rec_lock_xvdh     cur_lock_xvdh%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    <<xvdh_lock_loop>>
    FOR i IN   1 .. g_xvdh_tab.COUNT  LOOP
      --  �����u�c�p�����v�Z�w�b�_���b�N
      OPEN  cur_lock_xvdh(iv_customer_number  =>  g_xvdh_tab(i).customer_number);
      --
      <<xvdh_upd_loop>>
      LOOP
        FETCH cur_lock_xvdh INTO  rec_lock_xvdh;
        EXIT  WHEN  cur_lock_xvdh%NOTFOUND;
        --
        --  �W��t���O�X�V
        UPDATE  xxcos_vd_digestion_hdrs
        SET     sales_result_creation_flag    =   cv_skip_flag
              , sales_amount                  =   0
              , ar_sales_amount               =   0
              , summary_data_flag             =   cv_n
              , last_updated_by               =   cn_last_updated_by
              , last_update_date              =   cd_last_update_date
              , last_update_login             =   cn_last_update_login
              , request_id                    =   cn_request_id
              , program_application_id        =   cn_program_application_id
              , program_id                    =   cn_program_id
              , program_update_date           =   cd_program_update_date
        WHERE   vd_digestion_hdr_id   =   rec_lock_xvdh.vd_digestion_hdr_id;
      END LOOP  xvdh_upd_loop;
      --
      CLOSE cur_lock_xvdh;
    END LOOP  xvdh_lock_loop;
--
  EXCEPTION
--
    WHEN  global_data_lock_expt THEN
      --  ���b�N�G���[�̏ꍇ
      IF  (cur_lock_xvdh%ISOPEN)  THEN
        CLOSE cur_lock_xvdh;
      END IF;
      --  �e�[�u�����̎擾
      lv_str_table_name :=  xxccp_common_pkg.get_msg(
                                iv_application        => ct_xxcos_appl_short_name
                              , iv_name               => ct_msg_xvdh_tblnm
                            );
      --  �G���[���b�Z�[�W�擾
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                                iv_application    =>  ct_xxcos_appl_short_name
                              , iv_name           =>  ct_msg_lock_error
                              , iv_token_name1    =>  cv_tkn_table
                              , iv_token_value1   =>  lv_str_table_name
                            );
      ov_errmsg         :=  lv_errmsg;
      ov_errbuf         :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode        :=  cv_status_error;
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
      IF  (cur_lock_xvdh%ISOPEN)  THEN
        CLOSE cur_lock_xvdh;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_pre_not_digestion_due;
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_regular_any_class      IN      VARCHAR2,         -- 1.��������敪
    iv_base_code              IN      VARCHAR2,         -- 2.���_�R�[�h
    iv_customer_number        IN      VARCHAR2,         -- 3.�ڋq�R�[�h
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2,         -- 4.�Ɩ����t
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_parameter,
                                   iv_token_name1        => cv_tkn_param1,
                                   iv_token_value1       => iv_regular_any_class,
                                   iv_token_name2        => cv_tkn_param2,
                                   iv_token_value2       => iv_base_code,
                                   iv_token_name3        => cv_tkn_param3,
                                   iv_token_value3       => iv_customer_number,
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
                                   iv_token_name4        => cv_tkn_param4,
                                   iv_token_value4       => iv_process_date
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => lv_errmsg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => NULL
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- ���b�Z�[�W���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    --==================================
    -- 2.�p�����[�^�ϊ�
    --==================================
    gt_regular_any_class      := iv_regular_any_class;
    gt_base_code              := iv_base_code;
    gt_customer_number        := iv_customer_number;
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    IF ( iv_process_date IS NOT NULL ) THEN
      gd_process_date           := TRUNC ( TO_DATE ( iv_process_date , cv_fmt_date ) );
    END IF;
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : �p�����[�^�`�F�b�N����(A-1)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter';        -- �v���O������
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
    lv_org_id                     VARCHAR2(5000);
    lv_min_date                   VARCHAR2(5000);
    lv_max_date                   VARCHAR2(5000);
    lt_organization_id            mtl_parameters.organization_id%TYPE;
                                                                      --�݌ɑg�DID
    lt_organization_code          mtl_parameters.organization_code%TYPE;
                                                                      --�݌ɑg�D�R�[�h
    lv_diges_calc_delay_day       VARCHAR2(5000);                     --����VD�|���쐬�P�\����
    lt_regular_any_class_name     fnd_lookup_values.meaning%TYPE;     --��������敪����
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    lv_max_threshold              VARCHAR2(5000);                     --MAX臒l(VD)
    lv_min_threshold              VARCHAR2(5000);                     --MIN臒l(VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    --�G���[���b�Z�[�W�p
    lv_str_profile_name           VARCHAR2(5000);                     --�v���t�@�C����
    lv_str_api_name               VARCHAR2(5000);                     --�֐���
    lv_str_in_param               VARCHAR2(5000);                     --���̓p�����[�^��
    lv_str_table_name             VARCHAR2(5000);                     --�e�[�u����
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
    --============================================
    -- 1.�Ɩ����t�擾
    --============================================
--******************************** 2009/05/01 1.8 N.Maeda MOD START **************************************************
--    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--    --gd_process_date           := TO_DATE( '2009/03/03', 'YYYY/MM/DD' ); --debug
    IF ( gd_process_date IS NULL ) THEN
      gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
    END IF;
--******************************** 2009/05/01 1.8 N.Maeda MOD END   **************************************************
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --============================================
    -- 2.MO:�c�ƒP��
    --============================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --============================================
    -- 3.XXCOS:MIN���t
    --============================================
    lv_min_date := FND_PROFILE.VALUE( ct_prof_min_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_min_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_min_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_min_date               := TO_DATE( lv_min_date, cv_fmt_date );
--
    --============================================
    -- 4.XXCOS:MAX���t
    --============================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --============================================
    -- 5.XXCOI:�݌ɑg�D�R�[�h
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_organization_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_organization_code
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 6. �݌ɑg�DID�̎擾
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );                      -- �݌ɑg�DID�擾
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 7. �̔��p�J�����_�R�[�h�擾
    --============================================
    lt_organization_id        := gt_organization_id;
    --
    xxcos_common_pkg.get_sales_calendar_code(
      ion_organization_id     => lt_organization_id,             -- �݌ɑg�D�h�c
      iov_organization_code   => lt_organization_code,           -- �݌ɑg�D�R�[�h
      ov_calendar_code        => gt_calendar_code,               -- �J�����_�R�[�h
      ov_errbuf               => lv_errbuf,                      -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
      ov_retcode              => lv_retcode,                     -- ���^�[���E�R�[�h               #�Œ�#
      ov_errmsg               => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- �J�����_�R�[�h�擾
      RAISE global_call_api_expt;
    END IF;
    --
    IF ( gt_calendar_code IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- �J�����_�R�[�h�擾
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 8.XXCOS:����VD�|���쐬�P�\�����̎擾
    --============================================
    lv_diges_calc_delay_day   := FND_PROFILE.VALUE( ct_prof_diges_calc_delay_day );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_diges_calc_delay_day IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_diges_calc_delay_day
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_diges_calc_delay_day   := TO_NUMBER( lv_diges_calc_delay_day );
--
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --============================================
    -- 9.XXCOS:�ő�臒l�擾
    --============================================
    lv_max_threshold      := FND_PROFILE.VALUE( ct_prof_max_threshold_vd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_threshold IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_thrshld
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_max_threshold          := TO_NUMBER( lv_max_threshold );
--
    --============================================
    -- 10.XXCOS:�ŏ�臒l�擾
    --============================================
    lv_min_threshold      := FND_PROFILE.VALUE( ct_prof_min_threshold_vd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_min_threshold IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_min_thrshld
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_min_threshold          := TO_NUMBER( lv_min_threshold );
--
--    --============================================
--    -- 9.��������p�����[�^�`�F�b�N
--    --============================================
    --============================================
    -- 11.��������p�����[�^�`�F�b�N
    --============================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    BEGIN
      SELECT
        flv.meaning                     regular_any_class_name
      INTO
        lt_regular_any_class_name
      FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--        fnd_application                 fa,
--        fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
        fnd_lookup_values               flv
      WHERE
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--        fa.application_id               = flt.application_id
--      AND flt.lookup_type               = flv.lookup_type
--      AND fa.application_short_name     = ct_xxcos_appl_short_name
--      AND flt.lookup_type               = ct_qct_regular_any_class
        flv.lookup_type               = ct_qct_regular_any_class
-- 2009/07/16 Ver.1.9 M.Sano Del End
      AND flv.lookup_code               = gt_regular_any_class
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--      AND flv.language                  = USERENV( 'LANG' )
      AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_str_table_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_reg_any_cls_tblnm
                                 );
        RAISE global_select_data_expt;
    END;
--
    --============================================
    -- 10.����̏ꍇ�A������VD���N�������Z�o
    --============================================
    IF ( gt_regular_any_class = ct_regular_any_class_reg ) THEN
      gd_temp_digestion_due_date := gd_process_date - gn_diges_calc_delay_day;
    END IF;
--
    --============================================
    -- 11.�����̏ꍇ�A���_�K�{�`�F�b�N
    --============================================
    IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      IF ( gt_base_code IS NULL ) THEN
        --���̓p�����[�^��������擾
        lv_str_in_param         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_base_code
                                   );
        RAISE global_require_param_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_str_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐��G���[��O�n���h�� ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �K�{���̓p�����[�^���ݒ��O�n���h�� ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_require_param_err,
                                   iv_token_name1        => cv_tkn_in_param,
                                   iv_token_value1       => lv_str_in_param
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�}�X�^��O�n���h�� ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
  END chk_parameter;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
  /**********************************************************************************
   * Procedure Name   : lock_hdrs_lns_data
   * Description      : ����VD�p�����v�Z�w�b�_�A���׃f�[�^���b�N����(A-2-1)
   ***********************************************************************************/
  PROCEDURE lock_hdrs_lns_data(
    it_vd_dgstn_hdr_id  IN  xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
    iv_customer_num     IN  VARCHAR2,     --   �ڋq�R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_hdrs_lns_data'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur(
     it_vd_digestion_hdr_id       xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    )
    IS
      SELECT
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id
      FROM
        xxcos_vd_digestion_hdrs           xvdh,                             --����VD�p�����v�Z�w�b�_�e�[�u��
        xxcos_vd_digestion_lns            xvdl                              --����VD�p�����v�Z���׃e�[�u��
      WHERE
        xvdh.vd_digestion_hdr_id          = it_vd_digestion_hdr_id
      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id (+)
      AND xvdh.sales_result_creation_flag <> cv_delete_flag
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ���[�J���E�֐� ***
--
    -- *** ���[�J���E��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.����VD���f�[�^���b�N
    --==================================
    BEGIN
      OPEN lock_cur( it_vd_digestion_hdr_id => it_vd_dgstn_hdr_id );
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --�e�[�u�����擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_diges_info_tblnm
                                 );
--
      IF ( gt_regular_any_class = ct_regular_any_class_reg ) 
        OR ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      --�p�����[�^���s�敪���A�u����v�܂��́u����i���ւ��j�v�̏ꍇ
        ov_errmsg               := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_lock_error_skip,
                                     iv_token_name1        => cv_tkn_table,
                                     iv_token_value1       => lv_str_table_name,
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => iv_customer_num
                                   );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_warn;
      ELSIF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      --�p�����[�^���s�敪���A�u�����v�̏ꍇ
        ov_errmsg               := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_lock_error,
                                     iv_token_name1        => cv_tkn_table,
                                     iv_token_value1       => lv_str_table_name
                                   );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_error;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_hdrs_lns_data;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
  /**********************************************************************************
   * Procedure Name   : del_tt_vd_digestion
   * Description      : ����VD�p�����v�Z���̍���f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE del_tt_vd_digestion(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_tt_vd_digestion'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    CURSOR lock_cur(
--     it_vd_digestion_hdr_id       xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
--    )
--    IS
--      SELECT
--        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id
--      FROM
--        xxcos_vd_digestion_hdrs           xvdh,                             --����VD�p�����v�Z�w�b�_�e�[�u��
--        xxcos_vd_digestion_lns            xvdl                              --����VD�p�����v�Z���׃e�[�u��
--      WHERE
--        xvdh.vd_digestion_hdr_id          = it_vd_digestion_hdr_id
--      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id (+)
--/* 2010/01/25 Ver1.11 Add Start */
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
--/* 2010/01/25 Ver1.11 Add Start */
--      FOR UPDATE NOWAIT
--      ;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** ���[�J���E���R�[�h ***
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    l_lock_rec lock_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** ���[�J���E�֐� ***
--
    -- *** ���[�J���E��O ***
/* 2010/01/25 Ver1.11 Add Start */
    update_data_expt            EXCEPTION;
/* 2010/01/25 Ver1.11 Add End */

--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<tt_xvdh_tab_loop>>
    FOR i IN 1..g_tt_xvdh_tab.COUNT LOOP
      ln_idx := i;
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      --==================================
--      -- 1.����VD���f�[�^���b�N
--      --==================================
--      BEGIN
--        OPEN lock_cur( it_vd_digestion_hdr_id => g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id );
--        CLOSE lock_cur;
--      EXCEPTION
--        WHEN global_data_lock_expt THEN
--          RAISE global_data_lock_expt;
--      END;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
/* 2010/01/25 Ver1.11 Add Start */
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--      IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
--      -- �����̏ꍇ
      IF ( gt_regular_any_class = ct_regular_any_class_any )
        OR ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      -- �������́A����i���ւ��j�̏ꍇ
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
/* 2010/01/25 Ver1.11 Add End */
      --======================================================
      -- 2.����VD�ʏ����v�Z�w�b�_�e�[�u���폜
      --======================================================
      BEGIN
        DELETE FROM
          xxcos_vd_digestion_hdrs         xvdh
        WHERE
          xvdh.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --����VD�ʏ����v�Z�w�b�_�e�[�u��������擾
          lv_str_table_name   := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_xvdh_tblnm
                                 );
          --�L�[��񕶎���擾
          lv_str_key_data     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info1,
                                   iv_token_name1        => cv_tkn_diges_due_dt,
                                   iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                              cv_fmt_date
                                                            ),
                                   iv_token_name2        => cv_tkn_cust_code,
                                   iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                 );
          --
          RAISE global_delete_data_expt;
          --
      END;
      --
      --======================================================
      -- 3.����VD�ʏ����v�Z���׃e�[�u���폜
      --======================================================
      BEGIN
        DELETE FROM
          xxcos_vd_digestion_lns          xvdl
        WHERE
          xvdl.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --����VD�ʏ����v�Z���׃e�[�u��������擾
          lv_str_table_name   := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_xvdl_tblnm
                                 );
          --�L�[��񕶎���擾
          lv_str_key_data     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info1,
                                   iv_token_name1        => cv_tkn_diges_due_dt,
                                   iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                              cv_fmt_date
                                                            ),
                                   iv_token_name2        => cv_tkn_cust_code,
                                   iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                 );
          --
          RAISE global_delete_data_expt;
          --
      END;
/* 2010/01/25 Ver1.11 Add Start */
      ELSE
        -- ����̏ꍇ
        BEGIN
        UPDATE
           xxcos_vd_digestion_hdrs         xvdh
        SET
           xvdh.sales_result_creation_flag      = cv_delete_flag,              -- �̔����э쐬�ς݃t���O
           xvdh.last_updated_by                 = cn_last_updated_by,
           xvdh.last_update_date                = cd_last_update_date,
           xvdh.last_update_login               = cn_last_update_login,
           xvdh.request_id                      = cn_request_id,
           xvdh.program_application_id          = cn_program_application_id,
           xvdh.program_id                      = cn_program_id,
           xvdh.program_update_date             = cd_program_update_date
        WHERE
           xvdh.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
        EXCEPTION
          WHEN OTHERS THEN
            -- �X�V�G���[�̏ꍇ
            --����VD�ʏ����v�Z�w�b�_�e�[�u��������擾
            lv_str_table_name   := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_tt_xvdh_tblnm
                                   );
            --�L�[��񕶎���擾
            lv_str_key_data     := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                                cv_fmt_date
                                                              ),
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                   );
            --
            RAISE update_data_expt;
            --
        END;
      END IF;
/* 2010/01/25 Ver1.11 Add Start */
      --
    END LOOP tt_xvdh_tab_loop;
--
  EXCEPTION
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
--    WHEN global_data_lock_expt THEN
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
--      --�e�[�u�����擾
--      lv_str_table_name       := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_tt_diges_info_tblnm
--                                 );
----
--      ov_errmsg               := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_lock_err,
--                                   iv_token_name1        => cv_tkn_table,
--                                   iv_token_value1       => lv_str_table_name
--                                 );
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--      ov_retcode := cv_status_error;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_delete_data_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
/* 2010/01/25 Ver1.11 Add Start */
    WHEN update_data_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_update_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2010/01/25 Ver1.11 Add End */
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_tt_vd_digestion;
--
  /**********************************************************************************
   * Procedure Name   : ini_header
   * Description      : �w�b�_�P�ʏ���������(A-4)
   ***********************************************************************************/
  PROCEDURE ini_header(
    ot_vd_digestion_hdr_id         OUT     xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
                                                                      --  1.����VD�p�����v�Z�w�b�_ID
    ov_ar_uncalculate_type         OUT     VARCHAR2,                  --  2.AR���v�Z�敪
    ov_vdc_uncalculate_type        OUT     VARCHAR2,                  --  3.VD�R�����ʖ��v�Z�敪
    on_ar_amount                   OUT     NUMBER,                    --  4.������z���v
    on_tax_amount                  OUT     NUMBER,                    --  5.����Ŋz���v
    on_vdc_amount                  OUT     NUMBER,                    --  6.�̔����z���v
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ini_header'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.����VD�p�����v�Z�w�b�_ID�̎擾
    --==================================
    BEGIN
      SELECT
        xxcos_vd_digestion_hdrs_s01.NEXTVAL       vd_digestion_hdr_id
      INTO
        ot_vd_digestion_hdr_id
      FROM
        dual
      ;
    END;
--
    --==================================
    -- 2.�e��ϐ��N���A����
    --==================================
    ov_ar_uncalculate_type    := cv_uncalculate_type_init;
    ov_vdc_uncalculate_type   := cv_uncalculate_type_init;
    on_ar_amount              := cn_amount_default;
    on_tax_amount             := cn_amount_default;
    on_vdc_amount             := cn_amount_default;
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
  END ini_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_trx
   * Description      : AR������擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_cust_trx(
    it_cust_account_id             IN      xxcos_vd_digestion_hdrs.cust_account_id%TYPE,
                                                                      --  1.�ڋqID
    it_customer_number             IN      xxcos_vd_digestion_hdrs.customer_number%TYPE,
                                                                      --  2.�ڋq�R�[�h
    id_start_gl_date               IN      DATE,                      --  3.�J�nGL�L����
    id_end_gl_date                 IN      DATE,                      --  4.�I��GL�L����
    ov_ar_uncalculate_type         OUT     VARCHAR2,                  --  5.AR�R�����ʖ��v�Z�敪
    on_ar_amount                   OUT     NUMBER,                    --  6.������z���v
    on_tax_amount                  OUT     NUMBER,                    --  7.����Ŋz���v
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx'; -- �v���O������
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
    lv_ar_exists_flag                   VARCHAR2(1);                  --���݃t���O
    ln_ar_amount                        NUMBER;                       --������z���v
    ln_tax_amount                       NUMBER;                       --����Ŋz���v
    ln_work_tax_amount                  NUMBER;                       --���[�N�p����Ŋz
--
    -- *** ���[�J���E�J�[�\�� ***
    -- AR������擾����(A-5-1)
    CURSOR ar_cur
    IS
      SELECT
-- == 2010/04/05 V1.15 Added START ===============================================================
      /*+
        USE_NL (rcta,rctta)
      */
-- == 2010/04/05 V1.15 Added END ===============================================================
        rctlgda.gl_date                     gl_date,                        --����v���
        rctla.extended_amount               extended_amount,                --�{�̋��z
        rctla.customer_trx_line_id          customer_trx_line_id            --�������ID
      FROM
        ra_customer_trx_all                 rcta,                           --����������e�[�u��
        ra_customer_trx_lines_all           rctla,                          --����������׃e�[�u��
        ra_cust_trx_line_gl_dist_all        rctlgda,                        --����������׉�v�z���e�[�u��
        ra_cust_trx_types_all               rctta                           --��������^�C�v�}�X�^
      WHERE
        rcta.ship_to_customer_id            = it_cust_account_id
      AND rcta.customer_trx_id              = rctla.customer_trx_id
      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
      AND rctla.line_type                   = ct_line_type_line
      AND rcta.complete_flag                = ct_complete_flag_yes
      AND rctlgda.gl_date                   >= id_start_gl_date
      AND rctlgda.gl_date                   <= id_end_gl_date
      AND rcta.org_id                       = gn_org_id
      AND rcta.org_id                       = rctta.org_id
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--              fnd_application               fa,
--              fnd_lookup_types              flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
              fnd_lookup_values             flv
            WHERE
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--              fa.application_id             = flt.application_id
--            AND flt.lookup_type             = flv.lookup_type
--            AND fa.application_short_name   = ct_xxcos_appl_short_name
--            AND flv.lookup_type             = ct_qct_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Del End
              flv.lookup_type             = ct_qct_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Mod End
            AND flv.meaning                 = rctta.name
            AND rctlgda.gl_date             >= flv.start_date_active
            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--            AND flv.language                = USERENV( 'LANG' )
            AND flv.language                = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- *********** 2009/08/04 N.Maeda 1.10 DEL START *******************--
--            AND ROWNUM                      = 1
-- *********** 2009/08/04 N.Maeda 1.10 DEL  END  *******************--
          )
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--      UNION ALL
--      SELECT
--        rctlgda.gl_date                     gl_date,                        --����v���
--        rctla.extended_amount               extended_amount,                --�{�̋��z
--        rctla.customer_trx_line_id          customer_trx_line_id            --�������ID
--      FROM
--        ra_customer_trx_all                 rcta,                           --����������e�[�u��
--        ra_customer_trx_lines_all           rctla,                          --����������׃e�[�u��
--        ra_cust_trx_line_gl_dist_all        rctlgda,                        --����������׉�v�z���e�[�u��
--        ra_cust_trx_types_all               rctta                           --��������^�C�v�}�X�^
--      WHERE
--        rcta.ship_to_customer_id            = it_cust_account_id
--      AND rcta.customer_trx_id              = rctla.customer_trx_id
--      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--      AND rctla.line_type                   = ct_line_type_line
--      AND rcta.complete_flag                = ct_complete_flag_yes
--      AND rctlgda.gl_date                   >= id_start_gl_date
--      AND rctlgda.gl_date                   <= id_end_gl_date
--      AND rcta.org_id                       = gn_org_id
--      AND rcta.org_id                       = rctta.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Del End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--            AND flv.meaning                 = rctta.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
--      AND rcta.previous_customer_trx_id     IS NULL
--      UNION ALL
--      SELECT
--        rctlgda.gl_date                     gl_date,                        --����v���
--        rctla.extended_amount               extended_amount,                --�{�̋��z
--        rctla.customer_trx_line_id          customer_trx_line_id            --�������ID
--      FROM
--        ra_customer_trx_all                 rcta,                           --����������e�[�u��
--        ra_customer_trx_lines_all           rctla,                          --����������׃e�[�u��
--        ra_cust_trx_line_gl_dist_all        rctlgda,                        --����������׉�v�z���e�[�u��
--        ra_cust_trx_types_all               rctta,                          --��������^�C�v�}�X�^
--        ra_customer_trx_all                 rcta2,                          --����������e�[�u��(��)
--        ra_cust_trx_types_all               rctta2                          --��������^�C�v�}�X�^(��)
--      WHERE
--        rcta.ship_to_customer_id            = it_cust_account_id
--      AND rcta.customer_trx_id              = rctla.customer_trx_id
--      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--      AND rctla.line_type                   = ct_line_type_line
--      AND rcta.complete_flag                = ct_complete_flag_yes
--      AND rctlgda.gl_date                   >= id_start_gl_date
--      AND rctlgda.gl_date                   <= id_end_gl_date
--      AND rcta.org_id                       = gn_org_id
--      AND rcta.org_id                       = rctta.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Del End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--            AND flv.meaning                 = rctta.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
--      AND rcta.previous_customer_trx_id     = rcta2.customer_trx_id
--      AND rcta2.cust_trx_type_id            = rctta2.cust_trx_type_id
--      AND rcta2.org_id                      = rctta2.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
--            AND flv.meaning                 = rctta2.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
-- 2009/07/16 Ver.1.9 M.Sano Del End
      ;
    -- AR������ ���R�[�h�^
    l_ar_rec ar_cur%ROWTYPE;
--
    -- AR������(�ŋ��z�j�擾����(A-5-2)
    CURSOR tax_cur
    IS
      SELECT
        NVL( SUM ( rctla.extended_amount ), 0 )
                                          tax_amount                       --�ŋ��z
      FROM
        ra_customer_trx_lines_all         rctla                            --����������׃e�[�u��
      WHERE
        rctla.line_type                   = ct_line_type_tax
      AND rctla.link_to_cust_trx_line_id  = l_ar_rec.customer_trx_line_id
      GROUP BY
        rctla.link_to_cust_trx_line_id
      ;
    -- AR������(�ŋ��z�j ���R�[�h�^
    l_tax_rec tax_cur%ROWTYPE;
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
    -- ������
    lv_ar_exists_flag         := cv_exists_flag_no;
    ov_ar_uncalculate_type    := cv_uncalculate_type_init;
    on_ar_amount              := cn_amount_default;
    on_tax_amount             := cn_amount_default;
    ln_ar_amount              := cn_amount_default;
    ln_tax_amount             := cn_amount_default;
    --
    -- ===================================================
    --1.AR������
    -- ===================================================
    <<ar_loop>>
    FOR ar_rec IN ar_cur
    LOOP
      --�Z�b�g
      l_ar_rec                := ar_rec;
      -- ���݃t���O
      lv_ar_exists_flag       := cv_exists_flag_yes;
      -- ���[�N�p����Ŋz
      ln_work_tax_amount      := cn_amount_default;
      -- ===================================================
      --2.AR������(�ŋ��z�j
      -- ===================================================
      <<tax_loop>>
      FOR tax_rec IN tax_cur
      LOOP
        --
        l_tax_rec             := tax_rec;
        ln_work_tax_amount    := ln_work_tax_amount + l_tax_rec.tax_amount;
        --
      END LOOP tax_loop;
      -- ===================================================
      -- A-6  ������z�W�v����
      -- ===================================================
      ln_ar_amount            := ln_ar_amount + l_ar_rec.extended_amount + ln_work_tax_amount;
      ln_tax_amount           := ln_tax_amount + ln_work_tax_amount;
    --
    END LOOP ar_loop;
    -- ===================================================
    -- AR������v�Z�敪�Z�b�g
    -- AR����Ώی������Z
    -- ===================================================
    IF ( lv_ar_exists_flag = cv_exists_flag_no ) THEN
      ov_ar_uncalculate_type        := cv_uncalculate_type_nof;
    ELSE
      -- �Ώی����Q
      gn_target_cnt2                := gn_target_cnt2 + 1;
      --
      IF ( ln_ar_amount = cn_amount_default ) THEN
        ov_ar_uncalculate_type      := cv_uncalculate_type_zero;
      END IF;
    END IF;
    -- �ԋp
    on_ar_amount              := ln_ar_amount;
    on_tax_amount             := ln_tax_amount;
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
  END get_cust_trx;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_column
   * Description      : VD�R�����ʎ�����擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_vd_column(
    it_cust_account_id        IN      xxcos_vd_digestion_hdrs.cust_account_id%TYPE,
                                                                      --  1.�ڋqID
    it_customer_number        IN      xxcos_vd_digestion_hdrs.customer_number%TYPE,
                                                                      --  2.�ڋq�R�[�h
    it_digestion_due_date     IN      xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,
                                                                      --  3.�����v�Z���N����
    it_pre_digestion_due_date IN      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE,
                                                                      --  4.�O������v�Z���N����
    it_delivery_base_code     IN      xxcmm_cust_accounts.delivery_base_code%TYPE,
                                                                      --  5.�[�i���_�R�[�h
    it_vd_digestion_hdr_id    IN      xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
                                                                      --  6.����VD�����v�Z�w�b�_ID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
    it_sales_base_code        IN      xxcos_vd_digestion_hdrs.sales_base_code%TYPE,
                                                                      --  7.���㋒�_�R�[�h
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
    ov_vdc_uncalculate_type   OUT     VARCHAR2,                       --  8.VD�R�����ʖ��v�Z�敪
    on_vdc_amount             OUT     NUMBER,                         --  9.�̔����z���v
    ot_delivery_date          OUT     xxcos_vd_column_headers.dlv_date%TYPE,
                                                                      -- 10.�[�i���i�ŐV�f�[�^�j
    ot_dlv_time               OUT     xxcos_vd_column_headers.dlv_time%TYPE,
                                                                      -- 11.�[�i���ԁi�ŐV�f�[�^�j
    ot_performance_by_code    OUT     xxcos_vd_column_headers.performance_by_code%TYPE,
                                                                      -- 12.���ю҃R�[�h�i�ŐV�f�[�^�j
    ot_change_out_time_100    OUT     xxcos_vd_column_headers.change_out_time_100%TYPE,
                                                                      -- 13.��K�؂ꎞ��100�~�i�ŐV�f�[�^�j
    ot_change_out_time_10     OUT     xxcos_vd_column_headers.change_out_time_10%TYPE,
                                                                      -- 14.��K�؂ꎞ��10�~�i�ŐV�f�[�^�j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vd_column'; -- �v���O������
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
    lv_str_table_name                   VARCHAR2(5000);
    lv_str_key_data                     VARCHAR2(5000);
    --
    lv_vdc_exists_flag                  VARCHAR2(1);                  --���݃t���O
    ln_vdc_amount                       NUMBER;                       --�̔����z���v
    ln_idx1                             NUMBER;                       --�Y���P
    --
    lt_vd_digestion_ln_id               xxcos_vd_digestion_lns.vd_digestion_ln_id%TYPE;
                                                                      --����VD�ʏ����v�Z����ID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- VD�R�����ʎ�����擾����(A-7-1)
    CURSOR vdc_cur
    IS
-- == 2010/04/05 V1.15 Modified START ===============================================================
--      SELECT
---- ******************************* 2009/08/06 1.10 N.Maeda ADD START ******************************* --
--        /*+
--          INDEX( xvch XXCOS_VD_COLUMN_HEADERS_N04)
--        */
---- ******************************* 2009/08/06 1.10 N.Maeda ADD  END  ******************************* --
--        xvch.performance_by_code            performance_by_code,           --���ю҃R�[�h
--        xvch.dlv_date                       dlv_date,                      --�[�i��
--        xvch.dlv_time                       dlv_time,                      --����
--        xvcl.inventory_item_id              inventory_item_id,             --�i��ID
--        xvcl.item_code_self                 item_code_self,                --�i���R�[�h(����)
--        xvcl.standard_unit                  standard_unit,                 --��P��
--        xvcl.wholesale_unit_ploce           wholesale_unit_ploce,          --���P��
----******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
----        xvcl.quantity                       quantity,                      --����
--        xvcl.replenish_number               replenish_number,              --��[��
----******************************** 2009/04/13 1.7 N.Maeda MOD END   **************************************************
--        xvcl.h_and_c                        h_and_c,                       --H/C
--        xvcl.column_no                      column_no,                     --�R����No.
--        xvch.order_no_hht                   order_no_hht,                  --��No.(HHT)
--        xvch.digestion_ln_number            digestion_ln_number,           --�}��
--        xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date,  --����VD�|���쐬�ϔN����
--        xvch.change_out_time_100            change_out_time_100,           --��K�؂ꎞ��100�~
--        xvch.change_out_time_10             change_out_time_10,            --��K�؂ꎞ��10�~
--        xvcl.sold_out_class                 sold_out_class,                --���؋敪
--        xvcl.sold_out_time                  sold_out_time,                 --���؎���
----******************************** 2009/05/01 1.8 N.Maeda ADD START **************************************************
--        xvch.customer_number                customer_number                --�ڋq�R�[�h
----******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
--      FROM
--        xxcos_vd_column_headers             xvch,                          --VD�R�����ʎ���w�b�_�e�[�u��
--        xxcos_vd_column_lines               xvcl                           --VD�R�����ʎ���w�b�_���׃e�[�u��
--      WHERE
--        xvch.order_no_hht                   = xvcl.order_no_hht
--      AND xvch.digestion_ln_number          = xvcl.digestion_ln_number
----******************************** 2009/05/01 1.8 N.Maeda MOD START **************************************************
----      AND xvch.customer_number              = it_customer_number
---- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--      AND xvch.customer_number              = it_customer_number
----      AND xvch.customer_number              = NVL( it_customer_number , xvch.customer_number )
---- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
----******************************** 2009/05/01 1.8 N.Maeda MOD END   **************************************************
---- 2010/03/24 Ver.1.14 Add Start
--      AND xvch.base_code                    = it_sales_base_code       -- ���㋒�_�R�[�h
---- 2010/03/24 Ver.1.14 Add End
--      AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL)
--        AND ( xvch.dlv_date <= it_digestion_due_date) )
--        OR ( ( xvch.digestion_vd_rate_maked_date >= it_pre_digestion_due_date )
--        AND ( xvch.digestion_vd_rate_maked_date <= it_digestion_due_date ) ) )
--      ORDER BY
--        xvch.customer_number,                                              --�ڋq�R�[�h
--        xvch.dlv_date                                                      --�[�i��
--      ;
      SELECT  sub.performance_by_code           performance_by_code                 --  ���ю҃R�[�h
            , sub.dlv_date                      dlv_date                            --  �[�i��
            , sub.dlv_time                      dlv_time                            --  ����
            , sub.inventory_item_id             inventory_item_id                   --  �i��ID
            , sub.item_code_self                item_code_self                      --  �i���R�[�h(����)
            , sub.standard_unit                 standard_unit                       --  ��P��
            , sub.wholesale_unit_ploce          wholesale_unit_ploce                --  ���P��
            , sub.replenish_number              replenish_number                    --  ��[��
            , sub.h_and_c                       h_and_c                             --  H/C
            , sub.column_no                     column_no                           --  �R����No.
            , sub.order_no_hht                  order_no_hht                        --  ��No.(HHT)
            , sub.digestion_ln_number           digestion_ln_number                 --  �}��
            , sub.digestion_vd_rate_maked_date  digestion_vd_rate_maked_date        --  ����VD�|���쐬�ϔN����
            , sub.change_out_time_100           change_out_time_100                 --  ��K�؂ꎞ��100�~
            , sub.change_out_time_10            change_out_time_10                  --  ��K�؂ꎞ��10�~
            , sub.sold_out_class                sold_out_class                      --  ���؋敪
            , sub.sold_out_time                 sold_out_time                       --  ���؎���
            , sub.customer_number               customer_number                     --  �ڋq�R�[�h
      FROM  (
              SELECT  /*+ INDEX(xvch XXCOS_VD_COLUMN_HEADERS_N04) */
                xvch.performance_by_code            performance_by_code,            --  ���ю҃R�[�h
                xvch.dlv_date                       dlv_date,                       --  �[�i��
                xvch.dlv_time                       dlv_time,                       --  ����
                xvcl.inventory_item_id              inventory_item_id,              --  �i��ID
                xvcl.item_code_self                 item_code_self,                 --  �i���R�[�h(����)
                xvcl.standard_unit                  standard_unit,                  --  ��P��
                xvcl.wholesale_unit_ploce           wholesale_unit_ploce,           --  ���P��
                xvcl.replenish_number               replenish_number,               --  ��[��
                xvcl.h_and_c                        h_and_c,                        --  H/C
                xvcl.column_no                      column_no,                      --  �R����No.
                xvch.order_no_hht                   order_no_hht,                   --  ��No.(HHT)
                xvch.digestion_ln_number            digestion_ln_number,            --  �}��
-- 2010/05/07 Ver1.18 Add Start
                xvcl.line_no_hht                    line_no_hht,                    --  �sNo.(HHT)
-- 2010/05/07 Ver1.18 Add End
                xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date,   --  ����VD�|���쐬�ϔN����
                xvch.change_out_time_100            change_out_time_100,            --  ��K�؂ꎞ��100�~
                xvch.change_out_time_10             change_out_time_10,             --  ��K�؂ꎞ��10�~
                xvcl.sold_out_class                 sold_out_class,                 --  ���؋敪
                xvcl.sold_out_time                  sold_out_time,                  --  ���؎���
                xvch.customer_number                customer_number                 --  �ڋq�R�[�h
              FROM
                xxcos_vd_column_headers             xvch,                           --  VD�R�����ʎ���w�b�_�e�[�u��
                xxcos_vd_column_lines               xvcl                            --  VD�R�����ʎ���w�b�_���׃e�[�u��
              WHERE
                xvch.order_no_hht                   = xvcl.order_no_hht
              AND xvch.digestion_ln_number          = xvcl.digestion_ln_number
              AND xvch.customer_number              = it_customer_number
              AND xvch.base_code                    = it_sales_base_code            -- ���㋒�_�R�[�h
              AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL)
                AND ( xvch.dlv_date <= it_digestion_due_date) )
                OR ( ( xvch.digestion_vd_rate_maked_date >= it_pre_digestion_due_date )
                AND ( xvch.digestion_vd_rate_maked_date <= it_digestion_due_date ) ) )
              UNION
              SELECT  /*+ INDEX(xvch XXCOS_VD_COLUMN_HEADERS_N04) */
                  xvch.performance_by_code            performance_by_code             --  ���ю҃R�[�h
                , xvch.dlv_date                       dlv_date                        --  �[�i��
                , xvch.dlv_time                       dlv_time                        --  ����
                , xvcl.inventory_item_id              inventory_item_id               --  �i��ID
                , xvcl.item_code_self                 item_code_self                  --  �i���R�[�h(����)
                , xvcl.standard_unit                  standard_unit                   --  ��P��
                , xvcl.wholesale_unit_ploce           wholesale_unit_ploce            --  ���P��
                , xvcl.replenish_number               replenish_number                --  ��[��
                , xvcl.h_and_c                        h_and_c                         --  H/C
                , xvcl.column_no                      column_no                       --  �R����No.
                , xvch.order_no_hht                   order_no_hht                    --  ��No.(HHT)
                , xvch.digestion_ln_number            digestion_ln_number             --  �}��
-- 2010/05/07 Ver1.18 Add Start
                , xvcl.line_no_hht                    line_no_hht                     --  �sNo.(HHT)
-- 2010/05/07 Ver1.18 Add End
                , xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date    --  ����VD�|���쐬�ϔN����
                , xvch.change_out_time_100            change_out_time_100             --  ��K�؂ꎞ��100�~
                , xvch.change_out_time_10             change_out_time_10              --  ��K�؂ꎞ��10�~
                , xvcl.sold_out_class                 sold_out_class                  --  ���؋敪
                , xvcl.sold_out_time                  sold_out_time                   --  ���؎���
                , xvch.customer_number                customer_number                 --  �ڋq�R�[�h
              FROM
                  xxcos_vd_column_headers             xvch                            --  VD�R�����ʎ���w�b�_�e�[�u��
                , xxcos_vd_column_lines               xvcl                            --  VD�R�����ʎ���w�b�_���׃e�[�u��
                , xxcos_vd_digestion_hdrs             xvdh                            --  ����VD�p�����v�Z�w�b�_�e�[�u��
              WHERE   xvch.order_no_hht                   =   xvcl.order_no_hht
              AND     xvch.digestion_ln_number            =   xvcl.digestion_ln_number
              AND     xvdh.summary_data_flag              =   cv_y
              AND     xvdh.customer_number                =   it_customer_number
              AND     xvdh.sales_base_code                =   it_sales_base_code            -- ���㋒�_�R�[�h
              AND     xvch.customer_number                =   xvdh.customer_number
              AND     xvch.base_code                      =   xvdh.sales_base_code
              AND     xvch.digestion_vd_rate_maked_date   =   xvdh.digestion_due_date
            )     sub
      ORDER BY
              sub.customer_number       --  �ڋq�R�[�h
            , sub.dlv_date              --  �[�i��
      ;
-- == 2010/04/05 V1.15 Modified END   ===============================================================
    -- VD�R�����ʎ����� ���R�[�h�^
    l_vdc_rec vdc_cur%ROWTYPE;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�v���V�[�W�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_vdc_exists_flag              := cv_exists_flag_no;
    ov_vdc_uncalculate_type         := cv_uncalculate_type_init;
    on_vdc_amount                   := cn_amount_default;
    ot_delivery_date                := NULL;
    ot_dlv_time                     := NULL;
    ot_performance_by_code          := NULL;
    ot_change_out_time_100          := NULL;
    ot_change_out_time_10           := NULL;
    --
    ln_vdc_amount                   := cn_amount_default;
    ln_idx1                         := 0;
    --
    -- ===================================================
    -- A-8  ����VD�p�����v�Z���擾����
    -- ===================================================
    --1.�ۊǏꏊ���
    IF ( ( g_chk_subinv_tab.COUNT = 0 )
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      OR ( g_chk_subinv_tab.EXISTS( it_delivery_base_code ) = FALSE ) )
      OR ( g_chk_subinv_tab.EXISTS( it_sales_base_code ) = FALSE ) )
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
    THEN
      BEGIN
        SELECT
-- ************** 2009/08/04 N.Maeda 1.10 ADD START ***************************** --
          /*+ INDEX( msi XXCOI_MSI_N02 ) */
-- ************** 2009/08/04 N.Maeda 1.10 ADD  END  ***************************** --
          msi.secondary_inventory_name        secondary_inventory_name       --�ۊǏꏊ
        INTO
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--          g_chk_subinv_tab(it_delivery_base_code)
          g_chk_subinv_tab(it_sales_base_code)
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        FROM
          mtl_secondary_inventories           msi                            --�ۊǏꏊ�}�X�^
        WHERE
          msi.organization_id                 = gt_organization_id
        AND EXISTS(
              SELECT
                cv_exists_flag_yes            exists_flag
              FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                fnd_application               fa,
--                fnd_lookup_types              flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                fnd_lookup_values             flv
              WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod End
--                fa.application_id             = flt.application_id
--              AND flt.lookup_type             = flv.lookup_type
--              AND fa.application_short_name   = ct_xxcos_appl_short_name
--              AND flv.lookup_type             = ct_qct_hokan_type_mst
                flv.lookup_type             = ct_qct_hokan_type_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
              AND flv.lookup_code             LIKE ct_qcc_hokan_type_mst
              AND flv.meaning                 = msi.attribute13
              AND it_digestion_due_date       >= flv.start_date_active
              AND it_digestion_due_date       <= NVL( flv.end_date_active, gd_max_date )
              AND flv.enabled_flag            = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--              AND flv.language                = USERENV( 'LANG' )
              AND flv.language                = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ***************************** --
--              AND ROWNUM                      = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ***************************** --
            )
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--        AND msi.attribute7                    = it_delivery_base_code
        AND msi.attribute7                    = it_sales_base_code
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        AND it_digestion_due_date             < NVL( msi.disable_date, gd_max_date )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --�ۊǏꏊ�}�X�^������擾
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_subinv_mst
                                     );
          --�L�[��񕶎���擾
          lv_str_key_data         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info2,
                                       iv_token_name1       => cv_tkn_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--                                       iv_token_value1      => it_delivery_base_code,
                                       iv_token_value1      => it_sales_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
                                       iv_token_name2       => cv_tkn_organization_code,
                                       iv_token_value2      => gt_organization_code
                                     );
          RAISE global_select_data_expt;
      END;
    ELSE
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      IF ( g_chk_subinv_tab(it_delivery_base_code) IS NULL ) THEN
      IF ( g_chk_subinv_tab(it_sales_base_code) IS NULL ) THEN
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        --�ۊǏꏊ�}�X�^������擾
        lv_str_table_name         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_subinv_mst
                                     );
        --�L�[��񕶎���擾
        lv_str_key_data           := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info2,
                                       iv_token_name1       => cv_tkn_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--                                       iv_token_value1      => it_delivery_base_code,
                                       iv_token_value1      => it_sales_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
                                       iv_token_name2       => cv_tkn_organization_code,
                                       iv_token_value2      => gt_organization_code
                                     );
        RAISE global_select_data_expt;
      END IF;
    END IF;
    --
    -- ===================================================
    --1.VD�R�����ʎ�����
    -- ===================================================
    <<get_vdc_loop>>
    FOR vdc_rec IN vdc_cur
    LOOP
      --
      l_vdc_rec                         := vdc_rec;
      --���݃t���O
      lv_vdc_exists_flag                := cv_exists_flag_yes;
      --�ŐV���Z�b�g
      ot_delivery_date                  := l_vdc_rec.dlv_date;
      ot_dlv_time                       := l_vdc_rec.dlv_time;
      ot_performance_by_code            := l_vdc_rec.performance_by_code;
      ot_change_out_time_100            := l_vdc_rec.change_out_time_100;
      ot_change_out_time_10             := l_vdc_rec.change_out_time_10;
      --
      -- ===================================================
      -- A-8  ����VD�p�����v�Z���擾����
      -- ===================================================
      --2.�i�ڃ}�X�^���
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--      IF ( ( g_chk_fixed_price_tab.COUNT = 0 )
--        OR ( g_chk_fixed_price_tab.EXISTS( l_vdc_rec.item_code_self ) = FALSE ) )
--      THEN
--        BEGIN
--          SELECT
--            xsibh.fixed_price                     fixed_price                      --�艿
--          INTO
--            g_chk_fixed_price_tab(l_vdc_rec.item_code_self)
--          FROM
--            (
--              SELECT
--                xsibh.fixed_price                 fixed_price                      --�艿
--              FROM
--                xxcmm_system_items_b_hst          xsibh                            --�i�ډc�Ɨ����A�h�I���}�X�^
--              WHERE
--                xsibh.item_code                   = l_vdc_rec.item_code_self
--              AND xsibh.apply_date                <= it_digestion_due_date
--              AND xsibh.apply_flag                = ct_apply_flag_yes
--              AND xsibh.fixed_price               IS NOT NULL
--              ORDER BY
--                xsibh.apply_date                  desc
--            ) xsibh
--          WHERE
--            ROWNUM                                = 1
--          ;
--        EXCEPTION
--          WHEN OTHERS THEN
--            --�i�ڃ}�X�^������擾
--            lv_str_table_name           := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_item_mst
--                                           );
--            --�L�[��񕶎���擾
--            lv_str_key_data             := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_key_info3,
--                                             iv_token_name1       => cv_tkn_item_code,
--                                             iv_token_value1      => l_vdc_rec.item_code_self,
--                                             iv_token_name2       => cv_tkn_apply_date,
--                                             iv_token_value2      => TO_CHAR( it_digestion_due_date , cv_fmt_date )
--                                           );
--            RAISE global_select_data_expt;
--        END;
--        --
--      ELSE
--        IF ( g_chk_fixed_price_tab(l_vdc_rec.item_code_self) IS NULL ) THEN
--          --�i�ڃ}�X�^������擾
--          lv_str_table_name             := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_item_mst
--                                           );
--          --�L�[��񕶎���擾
--          lv_str_key_data               := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_key_info2,
--                                             iv_token_name1       => cv_tkn_item_code,
--                                             iv_token_value1      => l_vdc_rec.item_code_self,
--                                             iv_token_name2       => cv_tkn_apply_date,
--                                             iv_token_value2      => TO_CHAR( it_digestion_due_date , cv_fmt_date )
--                                           );
--          RAISE global_select_data_expt;
--        END IF;
--      END IF;
-- 2009/07/16 Ver.1.9 M.Sano Del End
      -- ===================================================
      -- ����VD�p�����v�Z���דo�^�p�Z�b�g����
      -- ===================================================
      ln_idx1                           := ln_idx1 + 1;
      gn_xvdl_idx                       := gn_xvdl_idx + 1;
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
          xxcos_vd_digestion_lns_s01.NEXTVAL      vd_digestion_ln_id
        INTO
          lt_vd_digestion_ln_id
        FROM
          dual
        ;
      END;
      --
      g_xvdl_tab(gn_xvdl_idx).vd_digestion_ln_id      := lt_vd_digestion_ln_id;
      g_xvdl_tab(gn_xvdl_idx).vd_digestion_hdr_id     := it_vd_digestion_hdr_id;
--******************************** 2009/05/01 1.8 N.Maeda ADD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).customer_number         := it_customer_number;
      g_xvdl_tab(gn_xvdl_idx).customer_number         := l_vdc_rec.customer_number;
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      g_xvdl_tab(gn_xvdl_idx).digestion_due_date      := it_digestion_due_date;
      g_xvdl_tab(gn_xvdl_idx).digestion_ln_number     := ln_idx1;
      g_xvdl_tab(gn_xvdl_idx).item_code               := l_vdc_rec.item_code_self;
      g_xvdl_tab(gn_xvdl_idx).inventory_item_id       := l_vdc_rec.inventory_item_id;
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--      g_xvdl_tab(gn_xvdl_idx).item_price              := g_chk_fixed_price_tab(l_vdc_rec.item_code_self);
      g_xvdl_tab(gn_xvdl_idx).item_price              := NULL;
-- 2009/07/16 Ver.1.9 M.Sano Mod End
      g_xvdl_tab(gn_xvdl_idx).unit_price              := l_vdc_rec.wholesale_unit_ploce;
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).item_sales_amount       := l_vdc_rec.wholesale_unit_ploce
--                                                         * l_vdc_rec.quantity;
      g_xvdl_tab(gn_xvdl_idx).item_sales_amount       := l_vdc_rec.wholesale_unit_ploce
                                                        * l_vdc_rec.replenish_number;
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).uom_code                := l_vdc_rec.standard_unit;
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).sales_quantity          := l_vdc_rec.quantity;
      g_xvdl_tab(gn_xvdl_idx).sales_quantity          := l_vdc_rec.replenish_number;
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).hot_cold_type           := l_vdc_rec.h_and_c;
      g_xvdl_tab(gn_xvdl_idx).column_no               := l_vdc_rec.column_no;
      g_xvdl_tab(gn_xvdl_idx).delivery_base_code      := it_delivery_base_code;
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).ship_from_subinventory_code
--                                                      := g_chk_subinv_tab(it_delivery_base_code);
      g_xvdl_tab(gn_xvdl_idx).ship_from_subinventory_code
                                                      := g_chk_subinv_tab(it_sales_base_code);
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).sold_out_class          := l_vdc_rec.sold_out_class;
      g_xvdl_tab(gn_xvdl_idx).sold_out_time           := l_vdc_rec.sold_out_time;
      --WHO�J����
      g_xvdl_tab(gn_xvdl_idx).created_by              := cn_created_by;
      g_xvdl_tab(gn_xvdl_idx).creation_date           := cd_creation_date;
      g_xvdl_tab(gn_xvdl_idx).last_updated_by         := cn_last_updated_by;
      g_xvdl_tab(gn_xvdl_idx).last_update_date        := cd_last_update_date;
      g_xvdl_tab(gn_xvdl_idx).last_update_login       := cn_last_update_login;
      g_xvdl_tab(gn_xvdl_idx).request_id              := cn_request_id;
      g_xvdl_tab(gn_xvdl_idx).program_application_id  := cn_program_application_id;
      g_xvdl_tab(gn_xvdl_idx).program_id              := cn_program_id;
      g_xvdl_tab(gn_xvdl_idx).program_update_date     := cd_program_update_date;
      --
      -- ===================================================
      -- A-10 �`�F�b�N�p������z�W�v����
      -- ===================================================
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      ln_vdc_amount := ln_vdc_amount + ( l_vdc_rec.quantity * l_vdc_rec.wholesale_unit_ploce );
      ln_vdc_amount := ln_vdc_amount + ( l_vdc_rec.replenish_number * l_vdc_rec.wholesale_unit_ploce );
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      --
    END LOOP get_vdc_loop;
    -- ===================================================
    -- VD�R�����ʎ�����v�Z�敪�Z�b�g
    -- VD�R�����ʎ���Ώی������Z
    -- ===================================================
    IF ( lv_vdc_exists_flag = cv_exists_flag_no ) THEN
      ov_vdc_uncalculate_type       := cv_uncalculate_type_nof;
    ELSE
      -- �Ώی����R
      gn_target_cnt3                := gn_target_cnt3 + 1;
      --
      IF ( ln_vdc_amount = cn_amount_default ) THEN
        ov_vdc_uncalculate_type     := cv_uncalculate_type_zero;
      END IF;
    END IF;
    -- �ԋp
    on_vdc_amount              := ln_vdc_amount;
--
  EXCEPTION
    -- *** �ۊǏꏊ�}�X�^�擾��O�n���h�� ***
    -- *** �i�ڃ}�X�^�擾��O�n���h�� ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
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
  END get_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_digestion_hdrs
   * Description      : ����VD�����v�Z�w�b�_�o�^����(A-12)
   ***********************************************************************************/
  PROCEDURE ins_vd_digestion_hdrs(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_digestion_hdrs'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
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
    --==================================
    -- 1.����VD�����v�Z�w�b�_�o�^����
    --==================================
    BEGIN
      FORALL i IN 1..g_xvdh_tab.COUNT
      INSERT INTO
        xxcos_vd_digestion_hdrs
      VALUES
        g_xvdh_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt := gn_normal_cnt + g_xvdh_tab.COUNT;
--
  EXCEPTION
    -- *** ����VD�����v�Z�w�b�_�e�[�u���o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      --����VD�p�����v�Z�w�b�_�e�[�u��������擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvdh_tblnm
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_vd_digestion_hdrs;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_digestion_lns
   * Description      : ����VD�����v�Z���דo�^����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_vd_digestion_lns(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_digestion_lns'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
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
    --==================================
    -- 1.����VD�����v�Z���דo�^����
    --==================================
    BEGIN
      FORALL i IN 1..g_xvdl_tab.COUNT
      INSERT INTO
        xxcos_vd_digestion_lns
      VALUES
        g_xvdl_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
  EXCEPTION
    -- *** ����VD�����v�Z���׃e�[�u���o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      --����VD�p�����v�Z���׃e�[�u��������擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvdl_tblnm
                                 );
      --�L�[��񕶎���擾
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_vd_digestion_lns;
--
  /**********************************************************************************
   * Procedure Name   : upd_vd_column_hdr
   * Description      : VD�J�����ʎ���w�b�_�X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE upd_vd_column_hdr(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vd_column_hdr'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- VD�R�����ʎ���w�b�_�e�[�u�� �J�[�\��
    --
    CURSOR xvch_cur(
      it_customer_number          IN    xxcos_vd_digestion_hdrs.customer_number%TYPE,
      id_digestion_due_date       IN    DATE,
      id_pre_digestion_due_date   IN    DATE
-- 2010/03/24 Ver.1.14 Add Start
      ,iv_sales_base_code         IN    xxcos_vd_digestion_hdrs.sales_base_code%TYPE
-- 2010/03/24 Ver.1.14 Add End
    )
    IS
      SELECT
        xvch.order_no_hht                 order_no_hht,                    --��No.(hht)
        xvch.digestion_ln_number          digestion_ln_number              --�}��
      FROM
        xxcos_vd_column_headers           xvch                             --VD�R�����ʎ���w�b�_�e�[�u��
      WHERE
        xvch.customer_number                    = it_customer_number
-- 2010/03/24 Ver.1.14 Add Start
      AND xvch.base_code                     = iv_sales_base_code
-- 2010/03/24 Ver.1.14 Add End
      AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL )
        AND ( id_digestion_due_date             >= xvch.dlv_date ) )
        OR ( ( NVL( id_pre_digestion_due_date + cn_one_day, gd_min_date )
                                                <= xvch.digestion_vd_rate_maked_date )
          AND ( id_digestion_due_date           >= xvch.digestion_vd_rate_maked_date ) ) )
      FOR UPDATE NOWAIT;
    -- VD�R�����ʎ���w�b�_�e�[�u�� ���R�[�h�^
    l_xvch_rec xvch_cur%ROWTYPE;
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
    <<xvch_tab_loop>>
    FOR i IN 1..g_xvch_tab.COUNT LOOP
      ln_idx := i;
      --VD�R�����ʎ���w�b�_�e�[�u��
      <<xvch_loop>>
      FOR xvch_rec IN xvch_cur(
                        it_customer_number        => g_xvch_tab(ln_idx).customer_number,
                        id_digestion_due_date     => g_xvch_tab(ln_idx).digestion_due_date,
                        id_pre_digestion_due_date => g_xvch_tab(ln_idx).pre_digestion_due_date
-- 2010/03/24 Ver.1.14 Add Start
                        ,iv_sales_base_code        => g_xvch_tab(ln_idx).sales_base_code
-- 2010/03/24 Ver.1.14 Add End
                      )
      LOOP
        --
        l_xvch_rec := xvch_rec;
        --VD�R�����ʎ���w�b�_�e�[�u�� �X�V
        BEGIN
          UPDATE
            xxcos_vd_column_headers              xvch
          SET
            xvch.digestion_vd_rate_maked_date    = g_xvch_tab(ln_idx).digestion_due_date,
            xvch.last_updated_by                 = cn_last_updated_by,
            xvch.last_update_date                = cd_last_update_date,
            xvch.last_update_login               = cn_last_update_login,
            xvch.request_id                      = cn_request_id,
            xvch.program_application_id          = cn_program_application_id,
            xvch.program_id                      = cn_program_id,
            xvch.program_update_date             = cd_program_update_date
          WHERE
            xvch.order_no_hht                    = l_xvch_rec.order_no_hht
          AND xvch.digestion_ln_number           = l_xvch_rec.digestion_ln_number
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --VD�J�����ʎ���w�b�_�e�[�u��������擾
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_xvch_tblnm
                                       );
            --�L�[��񕶎���擾
            lv_str_key_data         := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_key_info3,
                                         iv_token_name1        => cv_tkn_order_no_hht,
                                         iv_token_value1       => TO_NUMBER( l_xvch_rec.order_no_hht ),
                                         iv_token_name2        => cv_tkn_digestion_ln_number,
                                         iv_token_value2       => TO_NUMBER( l_xvch_rec.digestion_ln_number )
                                       );
            RAISE global_update_data_expt;
        END;
      --
      END LOOP xvch_loop;
    --
    END LOOP xvch_tab_loop;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      --�e�[�u�����擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvch_tblnm
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** VD�J�����ʎ���w�b�_�e�[�u���X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_update_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END upd_vd_column_hdr;
  /**********************************************************************************
   * Procedure Name   : get_operation_day
   * Description      : �ғ������擾���� (A-13)
   ***********************************************************************************/
  PROCEDURE get_operation_day(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_operation_day'; -- �v���O������
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
    lv_str_api_name               VARCHAR2(5000);
    --
    ln_idx                        NUMBER;
    ln_sales_oprtn_day            NUMBER;
/* 2010/01/19 Ver1.11 Add Start */
    ln_process_oprtn_flag         NUMBER;    -- �ғ����t���O(�Ɩ����t)
    ld_process_date_work           DATE;     -- ��Ɨp�Ɩ����t
/* 2010/01/19 Ver1.11 Add End */
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
    --������
    ln_idx                              := g_diges_due_dt_tab.COUNT;
    gd_calc_digestion_due_date          := gd_temp_digestion_due_date;
/* 2010/01/19 Ver1.11 Add Start */
    -- �Ɩ����t�̉ғ����`�F�b�N
    ln_process_oprtn_flag               := xxcos_common_pkg.check_sales_oprtn_day(
                                              id_check_target_date     => gd_process_date,
                                              iv_calendar_code         => gt_calendar_code
                                            );
    --
    -- �Ɩ����t�̉ғ�������
    IF ( ln_process_oprtn_flag = cn_sales_oprtn_day_non ) THEN
      -- ��ғ����̏ꍇ�A���߉ߋ����t�̋Ɩ����t���擾
      ld_process_date_work   := gd_process_date;
      <<oprtn_process_day_loop>>
      WHILE ( ln_process_oprtn_flag = cn_sales_oprtn_day_non ) LOOP
        ld_process_date_work := ld_process_date_work - 1;
        -- �ғ����`�F�b�N
        ln_process_oprtn_flag               := xxcos_common_pkg.check_sales_oprtn_day(
                                                  id_check_target_date     => ld_process_date_work,
                                                  iv_calendar_code         => gt_calendar_code
                                                );
        IF ( ( ln_process_oprtn_flag != cn_sales_oprtn_day_normal )
             AND ( ln_process_oprtn_flag != cn_sales_oprtn_day_non)
           )
        THEN
          -- �G���[�̏ꍇ
          RAISE global_call_api_expt;
        END IF;
      END LOOP oprtn_process_day_loop;
      --
      -- �����v�Z���N�������Đݒ�
      gd_calc_digestion_due_date := ld_process_date_work - gn_diges_calc_delay_day;
    ELSIF ( ln_process_oprtn_flag = cn_sales_oprtn_day_normal ) THEN
      --�ғ����̏ꍇ
      ld_process_date_work   := gd_process_date;
    ELSE
      --�G���[�̏ꍇ
      RAISE global_call_api_expt;
    END IF;
    --
/* 2010/01/19 Ver1.11 Add End */
    --�ғ����`�F�b�N
    ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                             id_check_target_date     => gd_calc_digestion_due_date,
                                             iv_calendar_code         => gt_calendar_code
                                           );
    --�ғ�������
    IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
      --�ғ����̏ꍇ
      ln_idx                            := ln_idx + 1;
      g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
/* 2010/01/19 Ver1.11 Del Start */
--      --==========================================
--      --��ғ����������e�[�u���ɃZ�b�g����B
--      --==========================================
--      --������
--      ln_sales_oprtn_day := cn_sales_oprtn_day_non;
--      --
--      <<oprtn_day_loop>>
--      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
--         --�O�������߂�B
--        gd_calc_digestion_due_date      := gd_calc_digestion_due_date - 1;
--         --�ғ����`�F�b�N
--        ln_sales_oprtn_day              := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--        --�ғ�������
--        IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--          --�ғ����̏ꍇ
--          NULL;
--        ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--          --��ғ����̏ꍇ
--          ln_idx                        := ln_idx + 1;
--          g_diges_due_dt_tab(ln_idx)    := gd_calc_digestion_due_date;
--        ELSE
--          --�G���[�̏ꍇ
--          RAISE global_call_api_expt;
--        END IF;
--      --
--      END LOOP oprtn_day_loop;
/* 2010/01/19 Ver1.11 Del End */
      --
    ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
      --��ғ����̏ꍇ
/* 2010/01/19 Ver1.11 Mod Start */
      --============================================================
      --��ғ������܂ߒ��߉ߋ��ғ����܂ł�����e�[�u���ɃZ�b�g����B
      --============================================================
      ln_idx                            := ln_idx + 1;
      g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
      --
      <<oprtn_day_loop>>
      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
        -- �O�������߂�
        gd_calc_digestion_due_date        := gd_calc_digestion_due_date - 1;
        ln_idx                            := ln_idx + 1;
        g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
        --
        -- �ғ����`�F�b�N
        ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                                 id_check_target_date     => gd_calc_digestion_due_date,
                                                 iv_calendar_code         => gt_calendar_code
                                               );
        IF ( ( ln_sales_oprtn_day != cn_sales_oprtn_day_normal )
             AND ( ln_sales_oprtn_day != cn_sales_oprtn_day_non)
           )
        THEN
          -- �G���[�̏ꍇ
          RAISE global_call_api_expt;
        END IF;
      END LOOP oprtn_day_loop;
      --
--      NULL;
/* 2010/01/19 Ver1.11 Mod Start */
    ELSE
      --�G���[�̏ꍇ
      RAISE global_call_api_expt;
    END IF;
/* 2010/01/19 Ver1.11 Mod End */
--
  EXCEPTION
    -- *** ���ʊ֐��G���[��O�n���h�� ***
    WHEN global_call_api_expt THEN
      --�̔��p�ғ����`�F�b�N���ʊ֐�������擾
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                   iv_application           => ct_xxcos_appl_short_name,
                                   iv_name                  => ct_msg_operation_day
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_operation_day;
--
/* 2010/01/19 Ver1.11 Del Start */
--  /**********************************************************************************
--   * Procedure Name   : get_non_operation_day
--   * Description      : ��ғ������擾���� (A-14)
--   ***********************************************************************************/
--  PROCEDURE get_non_operation_day(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_non_operation_day'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    lv_str_api_name               VARCHAR2(5000);
--    --
--    ln_idx                        NUMBER;
--    ln_sales_oprtn_day            NUMBER;
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    --������
--    ln_idx                              := g_diges_due_dt_tab.COUNT;
--    --�ғ����`�F�b�N
--    ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--    --�ғ�������
--    IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--      --�ғ����̏ꍇ
--      NULL;
--    ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--      --��ғ����̏ꍇ
--      --==========================================
--      --��ғ�����ǂݔ�΂��B
--      --==========================================
--      --������
--      ln_sales_oprtn_day := cn_sales_oprtn_day_non;
--      --
--      <<non_oprtn_day_loop>>
--      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
--         --�O�������߂�B
--        gd_calc_digestion_due_date      := gd_calc_digestion_due_date - 1;
--         --�ғ����`�F�b�N
--        ln_sales_oprtn_day              := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--        --�ғ�������
--        IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--          --�ғ����̏ꍇ
--          ln_idx                        := ln_idx + 1;
--          g_diges_due_dt_tab(ln_idx)    := gd_calc_digestion_due_date;
--        ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--          --��ғ����̏ꍇ
--          NULL;
--        ELSE
--          --�G���[�̏ꍇ
--          RAISE global_call_api_expt;
--        END IF;
--      --
--      END LOOP non_oprtn_day_loop;
--      --
--    ELSE
--      --�G���[�̏ꍇ
--      RAISE global_call_api_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** ���ʊ֐��G���[��O�n���h�� ***
--    WHEN global_call_api_expt THEN
--      --�̔��p�ғ����`�F�b�N���ʊ֐�������擾
--      lv_str_api_name         := xxccp_common_pkg.get_msg(
--                                   iv_application           => ct_xxcos_appl_short_name,
--                                   iv_name                  => ct_msg_operation_day
--                                 );
--      --
--      ov_errmsg               := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_call_api_err,
--                                   iv_token_name1        => cv_tkn_api_name,
--                                   iv_token_value1       => lv_str_api_name
--                                 );
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--      ov_retcode := cv_status_error;
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END get_non_operation_day;
/* 2010/01/19 Ver1.11 Del End */
--
  /**********************************************************************************
   * Procedure Name   : del_blt_vd_digestion
   * Description      : ����VD�p�����v�Z���̑O�X��f�[�^�폜(A-15)
   ***********************************************************************************/
  PROCEDURE del_blt_vd_digestion(
    it_digestion_due_date     IN      xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,
                                                                      --  1.�����v�Z���N����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_blt_vd_digestion'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    --�L�[����
    lt_key_customer_number        xxcos_vd_digestion_hdrs.customer_number%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    --======================================================
    -- �f�[�^���o
    --======================================================
    CURSOR blt_cur
    IS
      SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
        /*+
          INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
        */
-- ***************** 2009/08/06 1.10 N.Maeda END START ************************** --
        xvdh.customer_number              customer_number,            -- �ڋq�R�[�h
        xvdh.digestion_due_date           digestion_due_date,         -- �����v�Z���N����
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id,        -- ����VD�p�����v�Z�w�b�_ID
        xvdh.cust_account_id              cust_account_id             -- �ڋqID
      FROM
        xxcos_vd_digestion_hdrs           xvdh                        -- ����VD�p�����v�Z�w�b�_�e�[�u��
      WHERE
        xvdh.digestion_due_date           < it_digestion_due_date
-- == 2010/04/05 V1.15 Modified START ===============================================================
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
      AND xvdh.sales_result_creation_flag NOT IN(cv_skip_flag, cv_delete_flag)
-- == 2010/04/05 V1.15 Modified END   ===============================================================
      AND xvdh.sales_result_creation_flag = ct_sr_creation_flag_yes
      ORDER BY
        xvdh.customer_number              asc,                        -- �ڋq�R�[�h
        xvdh.digestion_due_date           desc                        -- �����v�Z���N����
      FOR UPDATE NOWAIT
      ;
    --
    --======================================================
    -- 1.����VD���f�[�^���b�N
    --======================================================
    CURSOR lock_cur(
      it_vd_digestion_hdr_id            xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    )
    IS
      SELECT
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id         -- ����VD�p�����v�Z�w�b�_ID
      FROM
        xxcos_vd_digestion_hdrs           xvdh,                       -- ����VD�p�����v�Z�w�b�_�e�[�u��
        xxcos_vd_digestion_lns            xvdl                        -- ����VD�p�����v�Z���׃e�[�u��
      WHERE
          xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id  (+)
-- == 2010/04/05 V1.15 Modified START ===============================================================
--/* 2010/01/25 Ver1.11 Add Start */
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
--/* 2010/01/25 Ver1.11 Add Start */
      AND xvdh.sales_result_creation_flag NOT IN(cv_skip_flag, cv_delete_flag)
-- == 2010/04/05 V1.15 Modified END   ===============================================================
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_blt_rec  blt_cur%ROWTYPE;
--
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ���[�J���E�֐� ***
--
    --======================================================
    -- 2.����VD�ʏ����v�Z�w�b�_�e�[�u���폜
    --======================================================
    PROCEDURE del_vd_digestion_hdrs(
      it_vd_digestion_hdr_id            xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
      it_customer_number                xxcos_vd_digestion_hdrs.customer_number%TYPE,
      it_digestion_due_date             xxcos_vd_digestion_hdrs.digestion_due_date%TYPE
    )
    AS
    BEGIN
/* 2010/01/25 Ver1.11 Mod Start */
      UPDATE
        xxcos_vd_digestion_hdrs         xvdh
      SET
        xvdh.sales_result_creation_flag      = cv_delete_flag,              -- �̔����э쐬�ς݃t���O
        xvdh.last_updated_by                 = cn_last_updated_by,
        xvdh.last_update_date                = cd_last_update_date,
        xvdh.last_update_login               = cn_last_update_login,
        xvdh.request_id                      = cn_request_id,
        xvdh.program_application_id          = cn_program_application_id,
        xvdh.program_id                      = cn_program_id,
        xvdh.program_update_date             = cd_program_update_date
      WHERE
        xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
      ;
--      DELETE FROM
--        xxcos_vd_digestion_hdrs         xvdh
--      WHERE
--        xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
--      ;
/* 2010/01/25 Ver1.11 Mod End */
    EXCEPTION
      WHEN OTHERS THEN
        --����VD�ʏ����v�Z�w�b�_�e�[�u��������擾
        lv_str_table_name       := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_blt_xvdh_tblnm
                                   );
        --�L�[��񕶎���擾
        lv_str_key_data         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( it_digestion_due_date, cv_fmt_date ),
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => it_customer_number
                                   );
        --
        RAISE global_delete_data_expt;
    --
    END;
--
/* 2010/01/25 Ver1.11 Del Start */
--    --======================================================
--    -- 3.����VD�ʏ����v�Z���׃e�[�u���폜
--    --======================================================
--    PROCEDURE del_vd_digestion_lns(
--      it_vd_digestion_hdr_id            xxcos_vd_digestion_lns.vd_digestion_hdr_id%TYPE,
--      it_customer_number                xxcos_vd_digestion_hdrs.customer_number%TYPE,
--      it_digestion_due_date             xxcos_vd_digestion_hdrs.digestion_due_date%TYPE
--    )
--    AS
--    BEGIN
--      DELETE FROM
--        xxcos_vd_digestion_lns          xvdl
--      WHERE
--        xvdl.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        --����VD�ʏ����v�Z���׃e�[�u��������擾
--        lv_str_table_name       := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => ct_msg_blt_xvdl_tblnm
--                                   );
--        --�L�[��񕶎���擾
--        lv_str_key_data         := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => ct_msg_key_info1,
--                                     iv_token_name1        => cv_tkn_diges_due_dt,
--                                     iv_token_value1       => TO_CHAR( it_digestion_due_date, cv_fmt_date ),
--                                     iv_token_name2        => cv_tkn_cust_code,
--                                     iv_token_value2       => it_customer_number
--                                   );
--        --
--        RAISE global_delete_data_expt;
--    --
--    END;
/* 2010/01/25 Ver1.11 Del End */
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- �f�[�^���o
    --==================================
    lt_key_customer_number              := NULL;
    --
    <<blt_loop>>
    FOR blt_rec IN blt_cur LOOP
      --
      l_blt_rec := blt_rec;
      --
      IF ( lt_key_customer_number IS NULL ) THEN
        lt_key_customer_number        := l_blt_rec.customer_number;
      ELSIF ( lt_key_customer_number = l_blt_rec.customer_number ) THEN
        --================================================
        -- 1.����VD���f�[�^���b�N
        --================================================
        BEGIN
          OPEN lock_cur( it_vd_digestion_hdr_id => l_blt_rec.vd_digestion_hdr_id );
          CLOSE lock_cur;
        EXCEPTION
          WHEN global_data_lock_expt THEN
            RAISE global_data_lock_expt;
        END;
        --
        --================================================
        -- 2.����VD�ʏ����v�Z�w�b�_�e�[�u���폜
        --================================================
        del_vd_digestion_hdrs(
          it_vd_digestion_hdr_id      => l_blt_rec.vd_digestion_hdr_id,
          it_customer_number          => l_blt_rec.customer_number,
          it_digestion_due_date       => it_digestion_due_date
        );
/* 2010/01/25 Ver1.11 Del Start */
--        --================================================
--        -- 3.����VD�ʏ����v�Z���׃e�[�u���폜
--        --================================================
--        del_vd_digestion_lns(
--          it_vd_digestion_hdr_id      => l_blt_rec.vd_digestion_hdr_id,
--          it_customer_number          => l_blt_rec.customer_number,
--          it_digestion_due_date       => it_digestion_due_date
--        );
/* 2010/01/25 Ver1.11 Del End */
      ELSE
        lt_key_customer_number        := l_blt_rec.customer_number;
      END IF;
    --
    END LOOP blt_loop;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      --�e�[�u�����擾
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_blt_diges_info_tblnm
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
/* 2010/01/25 Ver1.11 Mod Start */
                                   iv_name               => ct_msg_update_data_err,
--                                   iv_name               => ct_msg_delete_data_err,
/* 2010/01/25 Ver1.11 Mod End */
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_blt_vd_digestion;
--
  /**********************************************************************************
   * Procedure Name   : calc_due_day
   * Description      : �����Z�o����(A-16)
   ***********************************************************************************/
  PROCEDURE calc_due_day(
    id_digestion_due_date     IN      DATE,                           --  1.�����v�Z���N����
    ov_due_day                OUT     VARCHAR2,                       --  2.����
    ov_last_day               OUT     VARCHAR2,                       --  3.������
    ov_leap_year_due_day      OUT     VARCHAR2,                       --  4.�[�N����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_due_day'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.�����̎Z�o
    --==================================
    ov_due_day                := TO_CHAR( id_digestion_due_date, 'DD' );
    --
    --==================================
    -- 2.�������̎Z�o
    --==================================
    ov_last_day               := TO_CHAR( LAST_DAY( id_digestion_due_date ), 'DD' );
    --
    --==================================
    -- 1.�[�N�����̎Z�o
    --==================================
    IF ( ( TO_CHAR( id_digestion_due_date, 'MM' ) = cv_month_february )
      AND ( ov_last_day = cv_last_day_29 ) )
    THEN
      ov_leap_year_due_day    := cv_last_day_29;
    ELSIF ( ( TO_CHAR( id_digestion_due_date, 'MM' ) = cv_month_february )
      AND ( ov_last_day = cv_last_day_28 ) )
    THEN
      ov_leap_year_due_day    := cv_last_day_28;
    ELSE
      ov_leap_year_due_day    := cv_last_day_29;
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
  END calc_due_day;
--
  /**********************************************************************************
   * Procedure Name   : calc_pre_diges_due_dt
   * Description      : �O������v�Z���N�����Z�o����(A-18)
   ***********************************************************************************/
  PROCEDURE calc_pre_diges_due_dt(
    it_cust_account_id        IN      hz_cust_accounts.cust_account_id%TYPE,
                                                                      --  1.�ڋqID
    it_customer_number        IN      hz_cust_accounts.account_number%TYPE,
                                                                      --  2.�ڋq�R�[�h
    id_digestion_due_date     IN      DATE,                           --  3.�����v�Z���N����
    id_stop_approval_date     IN      DATE,                           --  4.���~���ٓ�
    od_pre_digestion_due_date OUT     DATE,                           --  5.�O������v�Z���N����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_pre_diges_due_dt'; -- �v���O������
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
--
    ld_pre_digestion_due_date    DATE;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --
    ld_pre_digestion_due_date          := NULL;
    --
    IF ( ( g_get_pre_diges_due_dt_tab.COUNT = 0 )
      OR ( g_get_pre_diges_due_dt_tab.EXISTS( it_cust_account_id ) = FALSE ) )
    THEN
      --============================================
      -- 1.����VD�ʏ����v�Z�w�b�_�e�[�u�����
      --   �O������v�Z���N�����擾
      --============================================
      BEGIN
        SELECT
-- == 2010/04/05 V1.15 Modified START ===============================================================
          MAX(xvdh.digestion_due_date)                 last_digestion_due_date
--          xvdh.digestion_due_date                 last_digestion_due_date
-- == 2010/04/05 V1.15 Modified END ===============================================================
        INTO
          g_get_pre_diges_due_dt_tab(it_cust_account_id)
        FROM
          (
            -- �����v�Z���ꂽ�����v�Z���N����
            SELECT
              xvdh.digestion_due_date             digestion_due_date
            FROM
              xxcos_vd_digestion_hdrs             xvdh
            WHERE
              xvdh.cust_account_id                = it_cust_account_id
            AND xvdh.digestion_due_date           < id_digestion_due_date
-- == 2010/04/05 V1.15 Added START ===============================================================
            AND xvdh.sales_result_creation_flag   NOT IN(cv_skip_flag, cv_n)
-- == 2010/04/05 V1.15 Added END   ===============================================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--            AND xvdh.sales_result_creation_flag   = ct_sr_creation_flag_yes
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            ORDER BY
--              xvdh.digestion_due_date             desc
            UNION
            -- ���v�Z�ŏW��t���O�������Ă��Ȋ|���f�[�^�̏����v�Z���N����
            SELECT
              xvdh.digestion_due_date             digestion_due_date
            FROM
              xxcos_vd_digestion_hdrs             xvdh
            WHERE
              xvdh.cust_account_id                = it_cust_account_id
            AND xvdh.digestion_due_date           < id_digestion_due_date
            AND xvdh.sales_result_creation_flag   = cv_n
            AND xvdh.summary_data_flag            = cv_n
-- == 2010/04/05 V1.15 Modified END ===============================================================
          ) xvdh
-- == 2010/04/05 V1.15 Deleted START ===============================================================
--        WHERE
--          ROWNUM                                  = 1
-- == 2010/04/05 V1.15 Deleted END ===============================================================
        ;
-- == 2010/05/06 V1.17 Added START ===================================================================
        -- �擾���ʂ�NULL�̏ꍇ�A NO_DATA_FOUND��O���X���[
        IF ( g_get_pre_diges_due_dt_tab(it_cust_account_id) IS NULL ) THEN
          RAISE NO_DATA_FOUND;
        END IF;
-- == 2010/05/06 V1.17 Added END ===================================================================
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          g_get_pre_diges_due_dt_tab(it_cust_account_id)    := gd_min_date;
        WHEN OTHERS THEN
          ---����VD�ʏ����v�Z�w�b�_�e�[�u��������擾
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_xvdh_tblnm
                                     );
          --�L�[��񕶎���擾
          lv_str_key_data         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info1,
                                       iv_token_name1       => cv_tkn_diges_due_dt,
                                       iv_token_value1      => TO_CHAR( id_digestion_due_date, cv_fmt_date ),
                                       iv_token_name2       => cv_tkn_cust_code,
                                       iv_token_value2      => it_customer_number
                                     );
          RAISE global_select_data_expt;
      END;
    END IF;
    --
    --============================================
    -- �O������v�Z���N�����{�P��
    --============================================
    ld_pre_digestion_due_date :=  CASE
                                    WHEN ( g_get_pre_diges_due_dt_tab(it_cust_account_id) = gd_min_date )
                                    THEN
                                      gd_min_date
                                    ELSE
                                      g_get_pre_diges_due_dt_tab(it_cust_account_id) + cn_one_day
                                  END;
    --
    --============================================
    -- 2.���~���ٔ���
    --============================================
    IF ( id_stop_approval_date IS NULL ) THEN
      NULL;
    ELSE
      IF ( ( ld_pre_digestion_due_date <= id_stop_approval_date )
        AND ( id_digestion_due_date >= id_stop_approval_date ) )
      THEN
        NULL;
      ELSE
        ld_pre_digestion_due_date       := NULL;
      END IF;
    END IF;
--
    --============================================
    -- 3.�ԋp
    --============================================
    od_pre_digestion_due_date           := CASE
                                             WHEN ( ld_pre_digestion_due_date IS NULL )
                                             THEN
                                               NULL
                                             ELSE
                                               g_get_pre_diges_due_dt_tab(it_cust_account_id)
                                           END;
--
  EXCEPTION
    -- *** �i�ڃ}�X�^�擾��O�n���h�� ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END calc_pre_diges_due_dt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_regular_any_class      IN      VARCHAR2,         -- 1.��������敪
    iv_base_code              IN      VARCHAR2,         -- 2.���_�R�[�h
    iv_customer_number        IN      VARCHAR2,         -- 3.�ڋq�R�[�h
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2,        -- 4.�Ɩ����t
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    ct_bsinss_lw_tp_svd                 CONSTANT xxcmm_cust_accounts.business_low_type%TYPE  := '27'; -- �Ƒԏ����ށF27(����VD)
    cv_uncalc_cls_4                     CONSTANT VARCHAR2(1) := '4';  -- ���v�Z�敪'4'
    cv_yes                              CONSTANT VARCHAR2(1) := 'Y';  -- �`�F�b�N�t���O'Y'
    cv_no                               CONSTANT VARCHAR2(1) := 'N';  -- �`�F�b�N�t���O'N'
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- *** ���[�J���ϐ� ***
    --�f�[�^���݃t���O
    lv_xvdh_exists_flag                 VARCHAR2(1);                  -- ����VD�w�b�_���݃t���O
    lv_cust_exists_flag1                VARCHAR2(1);                  -- �ڋq�}�X�^���݃t���O�i1�����j
    lv_cust_exists_flag2                VARCHAR2(1);                  -- �ڋq�}�X�^���݃t���O�i���������j
    --����VD�ʏ����v�Z�w�b�_ID
    lt_vd_digestion_hdr_id              xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE;
    --���v�Z�^�C�v
    lv_ar_uncalculate_type              VARCHAR2(1);                  -- AR���v�Z�^�C�v
    lv_vdc_uncalculate_type             VARCHAR2(1);                  -- VD�R�����ʖ��v�Z�^�C�v
    --�W�v
    ln_ar_amount                        NUMBER;                       -- ������z���v
    ln_tax_amount                       NUMBER;                       -- ����Ŋz���v
    ln_vdc_amount                       NUMBER;                       -- �̔����z���v
    --�ŐV�f�[�^
    lt_delivery_date                    xxcos_vd_column_headers.dlv_date%TYPE;
                                                                      -- �[�i��
    lt_dlv_time                         xxcos_vd_column_headers.dlv_time%TYPE;
                                                                      -- �[�i����
    lt_performance_by_code              xxcos_vd_column_headers.performance_by_code%TYPE;
                                                                      -- ���ю҃R�[�h
    lt_change_out_time_100              xxcos_vd_column_headers.change_out_time_100%TYPE;
                                                                      -- ��K�؂ꎞ��100�~
    lt_change_out_time_10               xxcos_vd_column_headers.change_out_time_10%TYPE;
                                                                      -- ��K�؂ꎞ��10�~
    --�Y��
    ln_idx                              NUMBER;
    --���t�i���j
    lv_due_day                          VARCHAR2(2);                  -- �����v�Z���N����
    lv_last_day                         VARCHAR2(2);                  -- ����
    lv_leap_year_due_day                VARCHAR2(2);                  -- ������
    --�O������v�Z���N����
    ld_pre_digestion_due_date           DATE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --���b�N�擾�G���[�t���O
    lv_lock_data_err_flg                VARCHAR2(1);
    --臒l�`�F�b�N�G���[�t���O
    lv_thrshld_chk_err_flg              VARCHAR2(1);
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
-- == 2010/04/05 V1.15 Added START ===============================================================
    ld_pre_digest_due_date              DATE;
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --============================================
    -- ����VD�p�����v�Z�w�b�_���擾����(A-2)
    --============================================
    CURSOR xvdh_cur
    IS
      SELECT
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id,          --����VD�p�����v�Z�w�b�_ID
        xvdh.customer_number                      customer_number,              --�ڋq�R�[�h
        xvdh.digestion_due_date                   digestion_due_date,           --�����v�Z���N����
        xvdh.sales_base_code                      sales_base_code,              --�O�����㋒�_�R�[�h
        xvdh.cust_account_id                      cust_account_id,              --�ڋqID
        xvdh.master_rate                          master_rate,                  --�}�X�^�|��
        xvdh.cust_gyotai_sho                      cust_gyotai_sho,              --�Ƒԏ�����
        xvdh.pre_digestion_due_date               pre_digestion_due_date,       --�O������v�Z���N����
        xvdh.delivery_base_code                   delivery_base_code            --�[�i���_�R�[�h
      FROM
        (
          SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
            /*+
              INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
            */
-- ***************** 2009/08/06 1.10 N.Maeda ADD  END  ************************** --
            xvdh.vd_digestion_hdr_id              vd_digestion_hdr_id,          --����VD�p�����v�Z�w�b�_ID
            xvdh.customer_number                  customer_number,              --�ڋq�R�[�h
            xvdh.digestion_due_date               digestion_due_date,           --�����v�Z���N����
            xvdh.sales_base_code                  sales_base_code,              --�O�����㋒�_�R�[�h
            xvdh.cust_account_id                  cust_account_id,              --�ڋqID
            xvdh.master_rate                      master_rate,                  --�}�X�^�|��
            xvdh.cust_gyotai_sho                  cust_gyotai_sho,              --�Ƒԏ�����
            xvdh.pre_digestion_due_date           pre_digestion_due_date,       --�O������v�Z���N����
            xca.delivery_base_code                delivery_base_code            --�[�i���_�R�[�h
          FROM
            xxcos_vd_digestion_hdrs               xvdh,                         --����VD�p�����v�Z�w�b�_�e�[�u��
            hz_cust_accounts                      hca,                          --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca                           --�A�J�E���g�A�h�I��
          WHERE
            xvdh.cust_account_id                  = hca.cust_account_id
          AND hca.cust_account_id                 = xca.customer_id
          AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
          AND xvdh.sales_base_code                = NVL( gt_base_code, xvdh.sales_base_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND xvdh.customer_number = gt_customer_number ) )
--          AND xvdh.customer_number                = NVL( gt_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- == 2010/04/05 V1.15 Added START ===============================================================
          AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
          UNION
          SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
            /*+
              INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
            */
-- ***************** 2009/08/06 1.10 N.Maeda ADD  END  ************************** --
            xvdh.vd_digestion_hdr_id              vd_digestion_hdr_id,          --����VD�p�����v�Z�w�b�_ID
            xvdh.customer_number                  customer_number,              --�ڋq�R�[�h
            xvdh.digestion_due_date               digestion_due_date,           --�����v�Z���N����
            xvdh.sales_base_code                  sales_base_code,              --�O�����㋒�_�R�[�h
            xvdh.cust_account_id                  cust_account_id,              --�ڋqID
            xvdh.master_rate                      master_rate,                  --�}�X�^�|��
            xvdh.cust_gyotai_sho                  cust_gyotai_sho,              --�Ƒԏ�����
            xvdh.pre_digestion_due_date           pre_digestion_due_date,       --�O������v�Z���N����
            xca.delivery_base_code                delivery_base_code            --�[�i���_�R�[�h
          FROM
            xxcos_vd_digestion_hdrs               xvdh,                         --����VD�p�����v�Z�w�b�_�e�[�u��
            hz_cust_accounts                      hca,                          --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca,                          --�A�J�E���g�A�h�I��
            hz_cust_accounts                      hca2,                         --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca2                          --�A�J�E���g�A�h�I��
          WHERE
            xvdh.cust_account_id                  = hca.cust_account_id
          AND hca.cust_account_id                 = xca.customer_id
          AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
          AND xvdh.sales_base_code                = hca2.account_number
          AND hca2.cust_account_id                = xca2.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst1
                AND flv.meaning                   = hca2.customer_class_code
                AND xvdh.digestion_due_date       >= flv.start_date_active
                AND xvdh.digestion_due_date       <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
          AND xca2.management_base_code           = NVL( gt_base_code, xca2.management_base_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND xvdh.customer_number = gt_customer_number ) )
--          AND xvdh.customer_number                = NVL( gt_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- == 2010/04/05 V1.15 Added START ===============================================================
          AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
       ) xvdh
     ORDER BY
       xvdh.digestion_due_date,
       xvdh.customer_number
     ;
    -- ����VD�p�����v�Z�w�b�_��� ���R�[�h�^
    l_xvdh_rec xvdh_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    --============================================
    -- ����VD�p�����v�Z�w�b�_���擾����(���(���ւ�))(A-2)
    --============================================
    CURSOR xvdh_cur2
    IS
      SELECT
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id,          --����VD�p�����v�Z�w�b�_ID
        xvdh.customer_number                      customer_number,              --�ڋq�R�[�h
        xvdh.digestion_due_date                   digestion_due_date,           --�����v�Z���N����
        xvdh.sales_base_code                      sales_base_code,              --�O�����㋒�_�R�[�h
        xvdh.cust_account_id                      cust_account_id,              --�ڋqID
        xvdh.master_rate                          master_rate,                  --�}�X�^�|��
        xvdh.cust_gyotai_sho                      cust_gyotai_sho,              --�Ƒԏ�����
        xvdh.pre_digestion_due_date               pre_digestion_due_date,       --�O������v�Z���N����
        xca.delivery_base_code                    delivery_base_code            --�[�i���_�R�[�h
      FROM
        xxcos_vd_digestion_hdrs               xvdh,                         --����VD�p�����v�Z�w�b�_�e�[�u��
        xxcmm_cust_accounts                   xca                           --�A�J�E���g�A�h�I��
      WHERE
        xvdh.cust_account_id                  = xca.customer_id
      AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
      AND xca.business_low_type               = ct_bsinss_lw_tp_svd
-- == 2010/04/05 V1.15 Added START ===============================================================
      AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
      ORDER BY
        xvdh.digestion_due_date,
        xvdh.customer_number
    ;
--
    -- ����VD�p�����v�Z�w�b�_��� ���R�[�h�^(���(���ւ�))
    l_xvdh_rec2 xvdh_cur2%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    --============================================
    -- ����VD�p�����v�Z�w�b�_���(����f�[�^�j�擾
    --============================================
    CURSOR tt_xvdh_cur(
      it_customer_number      xxcos_vd_digestion_hdrs.customer_number%TYPE
    )
    IS
      SELECT
-- ************** 2009/08/06 N.Maeda 1.10 MOD START ********************* --
        /*+ INDEX( XVDH XXCOS_VD_DIGESTION_HDRS_N03) */
-- ************** 2009/08/06 N.Maeda 1.10 MOD  END  ********************* --
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id           --����VD�p�����v�Z�w�b�_ID
      FROM
        xxcos_vd_digestion_hdrs                   xvdh                          --����VD�p�����v�Z�w�b�_�e�[�u��
      WHERE
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
         ( ( it_customer_number IS NULL )
        OR ( it_customer_number IS NOT NULL AND it_customer_number = xvdh.customer_number ) )
--          xvdh.customer_number                    = NVL( it_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
      AND xvdh.sales_result_creation_flag         = ct_sr_creation_flag_no
      ;
    -- ����VD�p�����v�Z�w�b�_��� ���R�[�h�^
    l_tt_xvdh_rec tt_xvdh_cur%ROWTYPE;
--
    --============================================
    -- �ڋq�}�X�^�擾����(A-17)
    --============================================
    CURSOR cust_cur(
      id_digestion_due_date             DATE,                              -- 1.�����v�Z���N����
      iv_due_day                        VARCHAR2,                          -- 2.����
      iv_last_day                       VARCHAR2,                          -- 3.������
      iv_leap_year_due_day              VARCHAR2                           -- 4.�[�N����
    )
    IS
      SELECT
        cust.cust_account_id            cust_account_id,              --�ڋqID
        cust.customer_number            customer_number,              --�ڋq�R�[�h
        cust.party_id                   party_id,                     --�p�[�e�BID
        cust.master_rate                master_rate,                  --�}�X�^�|��
        cust.sale_base_code             sales_base_code,              --�O�����㋒�_�R�[�h
        cust.cust_gyotai_sho            cust_gyotai_sho,              --�Ƒԏ�����
        cust.delivery_base_code         delivery_base_code,           --�[�i���_�R�[�h
        cust.stop_approval_date         stop_approval_date,           --���~���ٓ�
        cust.conclusion_day1            conclusion_day1,              --�����v�Z���ߓ��P
        cust.conclusion_day2            conclusion_day2,              --�����v�Z���ߓ��Q
        cust.conclusion_day3            conclusion_day3               --�����v�Z���ߓ��R
      FROM
        (
          SELECT
-- *********** 2009/08/05 N.Maeda 1.10 ADD START *******************--
            /*+ INDEX (xca XXCMM_CUST_ACCOUNTS_N09 ) */
-- *********** 2009/08/05 N.Maeda 1.10 ADD  END  *******************--
            hca.cust_account_id                   cust_account_id,              --�ڋqID
            hca.account_number                    customer_number,              --�ڋq�R�[�h
            hca.party_id                          party_id,                     --�p�[�e�BID
            ( xca.rate * 100 )                    master_rate,                  --�}�X�^�|��
-- 2010/03/24 Ver.1.14 Mod Start
            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca.sale_base_code
              ELSE  xca.past_sale_base_code
            END
--            NVL( xca.past_sale_base_code, xca.sale_base_code )
-- 2010/03/24 Ver.1.14 Mod End
                                                  sale_base_code,               --���㋒�_�R�[�h
            xca.business_low_type                 cust_gyotai_sho,              --�Ƒԏ�����
            xca.delivery_base_code                delivery_base_code,           --�[�i���_�R�[�h
            xca.stop_approval_date                stop_approval_date,           --���~���ٓ�
            xca.conclusion_day1                   conclusion_day1,              --�����v�Z���ߓ��P
            xca.conclusion_day2                   conclusion_day2,              --�����v�Z���ߓ��Q
            xca.conclusion_day3                   conclusion_day3               --�����v�Z���ߓ��R
          FROM
            hz_cust_accounts                      hca,                          --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca                           --�A�J�E���g�A�h�I��
          WHERE
            hca.cust_account_id                   = xca.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst2
                AND flv.meaning                   = hca.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--
          AND (
                ( gt_base_code IS NULL )
              OR
                ( gt_base_code IS NOT NULL 
-- == 2010/04/05 V1.15 Modified START ===============================================================
                  AND (  gt_base_code IN ( xca.past_sale_base_code, xca.sale_base_code ) ) )
--                  AND NVL( xca.past_sale_base_code, xca.sale_base_code )
--                = gt_base_code )
-- == 2010/04/05 V1.15 Modified END ===============================================================
              )
--          AND NVL( xca.past_sale_base_code, xca.sale_base_code )
--                                                  = NVL( gt_base_code,
--                                                      NVL( xca.past_sale_base_code,
--                                                        xca.sale_base_code
--                                                      )
--                                                    )
          AND ( ( gt_customer_number IS NULL )
                OR ( gt_customer_number IS NOT NULL
              AND hca.account_number = gt_customer_number )
              )
--          AND hca.account_number                  = NVL( gt_customer_number, hca.account_number )
--
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del Start
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_gyotai_sho_mst
                  flv.lookup_type               = ct_qct_gyotai_sho_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_gyotai_sho_mst
                AND flv.meaning                   = xca.business_low_type
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
          AND iv_due_day                          IN (
                                                       DECODE(
                                                         xca.conclusion_day1,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day1 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day1 ),
                                                           xca.conclusion_day1
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca.conclusion_day2,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day2 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day2 ),
                                                           xca.conclusion_day2
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca.conclusion_day3,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day3 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day3 ),
                                                           xca.conclusion_day3
                                                         )
                                                       )
                                                     )
          UNION
          SELECT
-- *********** 2009/08/05 N.Maeda 1.10 ADD START *******************--
            /*+ INDEX (xca2 XXCMM_CUST_ACCOUNTS_N09 ) */
-- *********** 2009/08/05 N.Maeda 1.10 ADD  END  *******************--
            hca2.cust_account_id                  cust_account_id,              --�ڋqID
            hca2.account_number                   customer_number,              --�ڋq�R�[�h
            hca2.party_id                         party_id,                     --�p�[�e�BID
            ( xca2.rate * 100 )                   master_rate,                  --�}�X�^�|��
-- 2010/03/24 Ver.1.14 Mod Start
-- == 2010/04/05 V1.15 Modified START ===============================================================
            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca2.sale_base_code
              ELSE  xca2.past_sale_base_code
            END
--            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
--              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca.sale_base_code
--              ELSE  xca.past_sale_base_code
--            END
-- == 2010/04/05 V1.15 Modified END ===============================================================
--            NVL( xca2.past_sale_base_code, xca2.sale_base_code )
-- 2010/03/24 Ver.1.14 Mod End
                                                  sale_base_code,               --���㋒�_�R�[�h
            xca2.business_low_type                cust_gyotai_sho,              --�Ƒԏ�����
            xca2.delivery_base_code               delivery_base_code,           --�[�i���_�R�[�h
            xca2.stop_approval_date               stop_approval_date,           --���~���ٓ�
            xca2.conclusion_day1                  conclusion_day1,              --�����v�Z���ߓ��P
            xca2.conclusion_day2                  conclusion_day2,              --�����v�Z���ߓ��Q
            xca2.conclusion_day3                  conclusion_day3               --�����v�Z���ߓ��R
          FROM
            hz_cust_accounts                      hca,                          --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca,                          --�A�J�E���g�A�h�I��
            hz_cust_accounts                      hca2,                         --�ڋq�}�X�^
            xxcmm_cust_accounts                   xca2                          --�A�J�E���g�A�h�I��
          WHERE
            hca.cust_account_id                   = xca.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst1
                AND flv.meaning                   = hca.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--
          AND ( ( gt_base_code IS NULL )
            OR ( gt_base_code IS NOT NULL 
              AND xca.management_base_code = gt_base_code ) )
--          AND xca.management_base_code            = NVL( gt_base_code, hca.customer_class_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
          AND hca2.cust_account_id                = xca2.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del Start
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst2
                AND flv.meaning                   = hca2.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- == 2010/04/05 V1.15 Modified START ===============================================================
          AND hca.account_number IN ( xca2.past_sale_base_code, xca2.sale_base_code )
--          AND NVL( xca2.past_sale_base_code, xca2.sale_base_code )
--                                                  = hca.account_number
-- == 2010/04/05 V1.15 Modified END ===============================================================
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND gt_customer_number = hca2.account_number ) )
--          AND hca2.account_number                 = NVL( gt_customer_number, hca2.account_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- 2010/05/02 Ver.1.16 T.Ishiwata Mod Start
          AND xca2.business_low_type  =  cv_buz_type27     -- �Ƒԏ����ނQ�V�̂�
--          AND EXISTS(
--                SELECT
--                  cv_exists_flag_yes              exists_flag
--                FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----                  fnd_application                 fa,
----                  fnd_lookup_types                flt,
---- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_lookup_values               flv
--                WHERE
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----                  fa.application_id               = flt.application_id
----                AND flt.lookup_type               = flv.lookup_type
----                AND fa.application_short_name     = ct_xxcos_appl_short_name
----                AND flv.lookup_type               = ct_qct_gyotai_sho_mst
--                  flv.lookup_type               = ct_qct_gyotai_sho_mst
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--                AND flv.lookup_code               LIKE ct_qcc_gyotai_sho_mst
--                AND flv.meaning                   = xca2.business_low_type
--                AND id_digestion_due_date         >= flv.start_date_active
--                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
--                AND flv.enabled_flag              = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----                AND flv.language                  = USERENV( 'LANG' )
--                AND flv.language                  = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
---- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
----                AND ROWNUM                        = 1
---- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
--              )
-- 2010/05/02 Ver.1.16 T.Ishiwata Mod End
          AND iv_due_day                          IN (
                                                       DECODE(
                                                         xca2.conclusion_day1,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day1 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day1 ),
                                                           xca2.conclusion_day1
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca2.conclusion_day2,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day2 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day2 ),
                                                           xca2.conclusion_day2
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca2.conclusion_day3,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day3 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day3 ),
                                                           xca2.conclusion_day3
                                                         )
                                                       )
                                                     )
        ) cust
-- == 2010/04/05 V1.15 Added START ===============================================================
      WHERE NOT EXISTS( SELECT  1
                        FROM    xxcos_vd_digestion_hdrs       xvdh
                        WHERE   xvdh.customer_number      =   cust.customer_number
                        AND     xvdh.digestion_due_date   =   id_digestion_due_date
                        AND     ROWNUM = 1
                )
-- == 2010/04/05 V1.15 Added END   ===============================================================
      ORDER BY
        cust.customer_number
      ;
    -- �ڋq�}�X�^ ���R�[�h�^
    l_cust_rec cust_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    -- *** ���[�J����O ***
    skip_error_expt     EXCEPTION;
    thrshld_chk_expt    EXCEPTION;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- *** ���[�J���E�֐� ***
    --==================================
    --���v�Z�敪�擾
    --==================================
    FUNCTION get_uncalculate_class(
      iv_ar_uncalculate_type            VARCHAR2,
      iv_vdc_uncalculate_type           VARCHAR2
    )
    RETURN   xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
    IS
      lt_uncalculate_flag     xxcos_vd_digestion_hdrs.uncalculate_class%TYPE;
    BEGIN
      IF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_both_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type <> cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_ar_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_zero )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_init ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_ar_nof;
      ELSIF ( ( iv_ar_uncalculate_type <> cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_vdc_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_init )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_zero ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_vdc_nof;
      ELSE
        lt_uncalculate_flag   := ct_uncalculate_class_fnd;
      END IF;
      --
      RETURN lt_uncalculate_flag;
    END;
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
    gn_target_cnt := 0;                 --���g�p
    gn_normal_cnt := 0;                 --�w�b�_�P�ʂ̌����Ŏg�p
    gn_error_cnt  := 0;                 --���g�p
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--    gn_warn_cnt   := 0;                 --���g�p
    gn_warn_cnt   := 0;                 --���b�N�擾���s�ŃX�L�b�v����
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
    --�Ώی���
    gn_target_cnt1 := 0;                --�ڋq�}�X�^�Ώی���
    gn_target_cnt2 := 0;                --AR����Ώی���
    gn_target_cnt3 := 0;                --VD�R�����ʎ���Ώی���
    --�x������
    gn_warn_cnt1 := 0;                  --����NOF
    gn_warn_cnt2 := 0;                  --AR���NOF
    gn_warn_cnt3 := 0;                  --VD�R�����ʎ��NOF
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --臒l�`�F�b�N�G���[����
    gn_thrshld_chk_cnt := 0;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- ===================================================
    -- A-0  ��������
    -- ===================================================
    init(
      iv_regular_any_class    => iv_regular_any_class,       -- 1.��������敪
      iv_base_code            => iv_base_code,               -- 2.���_�R�[�h
      iv_customer_number      => iv_customer_number,         -- 3.�ڋq�R�[�h
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
      iv_process_date         => iv_process_date,            -- 4.�Ɩ����t
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      ov_errbuf               => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- A-1  �p�����[�^�`�F�b�N
    -- ===================================================
    chk_parameter(
      ov_errbuf               => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- ��������̔���
    -- ===================================================
    IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      -- �p�����[�^�̒�������敪���u�����v�̏ꍇ
      -- �����e�[�u��������
      g_xvch_tab.DELETE;
      g_tt_xvdh_tab.DELETE;
      g_xvdh_tab.DELETE;
      g_xvdl_tab.DELETE;
      gn_xvch_idx    := 0;
      gn_tt_xvdh_idx := 0;
      gn_xvdh_idx    := 0;
      gn_xvdl_idx    := 0;
      --
      -- ===================================================
      -- A-2  ����VD�p�����v�Z�w�b�_�擾����
      -- ===================================================
      l_xvdh_rec                        := NULL;
      lv_xvdh_exists_flag               := cv_exists_flag_no;
      --
      <<get_xvdh_loop>>
      FOR xvdh_rec IN xvdh_cur LOOP
        --
        l_xvdh_rec                      := xvdh_rec;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        -- 臒l�`�F�b�N�G���[�t���O�̏�����
        lv_thrshld_chk_err_flg          := cv_no;
        --
        -- ===================================================
        -- ����VD�p�����v�Z�w�b�_�A���׃f�[�^���b�N����(A-2-1)
        -- ===================================================
        lock_hdrs_lns_data(
          it_vd_dgstn_hdr_id                => l_xvdh_rec.vd_digestion_hdr_id,
          iv_customer_num                   => NULL,
          ov_errbuf                         => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                        => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                         => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        -- ===================================================
        -- ����VD�p�����v�Z�w�b�_�Ώی������Z
        -- ===================================================
        gn_target_cnt1                  := gn_target_cnt1 + 1;
        --
        lv_xvdh_exists_flag             := cv_exists_flag_yes;
        -- ===================================================
        -- ����f�[�^�Z�b�g
        -- ===================================================
        gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                        := l_xvdh_rec.vd_digestion_hdr_id;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
                                        := l_xvdh_rec.customer_number;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
                                        := l_xvdh_rec.digestion_due_date;
-- 2010/03/24 Ver.1.14 Add Start
        g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
                                        := l_xvdh_rec.sales_base_code;
-- 2010/03/24 Ver.1.14 Add End
        --
        -- ===================================================
        -- VD�R�����ʎ���w�b�_�f�[�^�Z�b�g
        -- ===================================================
        gn_xvch_idx                     := gn_xvch_idx + 1;
        g_xvch_tab(gn_xvch_idx).customer_number
                                        := l_xvdh_rec.customer_number;
        g_xvch_tab(gn_xvch_idx).digestion_due_date
                                        := l_xvdh_rec.digestion_due_date;
        g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                        := NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date );
-- 2010/03/24 Ver.1.14 Add Start
        g_xvch_tab(gn_xvch_idx).sales_base_code
                                        := l_xvdh_rec.sales_base_code;
-- 2010/03/24 Ver.1.14 Add End
        --
        -- ===================================================
        -- A-4  �w�b�_�P�ʏ���������
        -- ===================================================
        ini_header(
          ot_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  1.����VD�p�����v�Z�w�b�_ID
          ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  2.AR���v�Z�敪
          ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  3.VD�R�����ʖ��v�Z�敪
          on_ar_amount                  => ln_ar_amount,                      --  4.������z���v
          on_tax_amount                 => ln_tax_amount,                     --  5.����Ŋz���v
          on_vdc_amount                 => ln_vdc_amount,                     --  6.�̔����z���v
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-21 �O�񖢌v�Z�f�[�^�`�F�b�N����
        -- ===================================================
        chk_pre_not_digestion_due(
            iv_customer_code          =>    l_xvdh_rec.customer_number
          , od_pre_digest_due_date    =>    ld_pre_digest_due_date
          , ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
        -- ===================================================
        -- A-5  AR������擾����
        -- ===================================================
        -- ������
        lv_ar_uncalculate_type          := cv_uncalculate_type_init;
        --
        get_cust_trx(
          it_cust_account_id            => l_xvdh_rec.cust_account_id,        --  1.�ڋqID
          it_customer_number            => l_xvdh_rec.customer_number,        --  2.�ڋq�R�[�h
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          id_start_gl_date              => NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date ),
          id_start_gl_date              => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                              --  3.�J�nGL�L����
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          id_end_gl_date                => l_xvdh_rec.digestion_due_date,     --  4.�I��GL�L����
          ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  5.AR������v�Z�敪
          on_ar_amount                  => ln_ar_amount,                      --  6.������z���v
          on_tax_amount                 => ln_tax_amount,                     --  7.����Ŋz���v
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-7  VD�R�����ʎ�����擾����
        -- ===================================================
        -- ������
        lv_vdc_uncalculate_type         := cv_uncalculate_type_init;
        lt_delivery_date                := NULL;                 -- �[�i��
        lt_dlv_time                     := NULL;                 -- �[�i����
        lt_performance_by_code          := NULL;                 -- ���ю҃R�[�h
        lt_change_out_time_100          := NULL;                 -- ��K�؂ꎞ��100�~
        lt_change_out_time_10           := NULL;                 -- ��K�؂ꎞ��10�~
        --
        get_vd_column(
          it_cust_account_id            => l_xvdh_rec.cust_account_id,        --  1.�ڋqID
          it_customer_number            => l_xvdh_rec.customer_number,        --  2.�ڋq�R�[�h
          it_digestion_due_date         => l_xvdh_rec.digestion_due_date,     --  3.�����v�Z���N����
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          it_pre_digestion_due_date     => NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date ),
          it_pre_digestion_due_date     => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                              --  4.�O������v�Z���N����
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          it_delivery_base_code         => l_xvdh_rec.delivery_base_code,     --  5.�[�i���_�R�[�h
          it_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  6.����VD�����v�Z�w�b�_ID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
          it_sales_base_code            => l_xvdh_rec.sales_base_code,        --  7.���㋒�_�R�[�h
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
          ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  8.VD�R�����ʎ�����v�Z�t���O
          on_vdc_amount                 => ln_vdc_amount,                     --  9.�̔����z���v
          ot_delivery_date              => lt_delivery_date,                  -- 10.�[�i���i�ŐV�f�[�^�j
          ot_dlv_time                   => lt_dlv_time,                       -- 11.�[�i���ԁi�ŐV�f�[�^�j
          ot_performance_by_code        => lt_performance_by_code,            -- 12.���ю҃R�[�h�i�ŐV�f�[�^�j
          ot_change_out_time_100        => lt_change_out_time_100,            -- 13.��K�؂ꎞ��100�~�i�ŐV�f�[�^�j
          ot_change_out_time_10         => lt_change_out_time_10,             -- 14.��K�؂ꎞ��10�~�i�ŐV�f�[�^�j
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- ����VD�p�����v�Z�w�b�_�o�^�p�Z�b�g����
        -- ===================================================
        gn_xvdh_idx := gn_xvdh_idx + 1;
        --����VD�p�����v�Z�w�b�_ID
        g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id         := lt_vd_digestion_hdr_id;
        --�ڋq�R�[�h
        g_xvdh_tab(gn_xvdh_idx).customer_number             := l_xvdh_rec.customer_number;
        --�����v�Z���N����
        g_xvdh_tab(gn_xvdh_idx).digestion_due_date          := l_xvdh_rec.digestion_due_date;
        --���㋒�_�R�[�h
        g_xvdh_tab(gn_xvdh_idx).sales_base_code             := l_xvdh_rec.sales_base_code;
        --�ڋq�h�c
        g_xvdh_tab(gn_xvdh_idx).cust_account_id             := l_xvdh_rec.cust_account_id;
        --�����v�Z���s��
        g_xvdh_tab(gn_xvdh_idx).digestion_exe_date          := gd_process_date;
        --������z
        g_xvdh_tab(gn_xvdh_idx).ar_sales_amount             := ROUND( ln_ar_amount );
        --�̔����z
        g_xvdh_tab(gn_xvdh_idx).sales_amount                := ROUND( ln_vdc_amount );
        --�����v�Z�|��
        IF ( ( ln_ar_amount = cn_amount_default )
          OR ( ln_vdc_amount = cn_amount_default ) )
        THEN
          g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := 0;
        ELSE
          g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := ROUND(
                                                                 ln_ar_amount / ln_vdc_amount * 100,
                                                                 cn_rate_fraction_place
                                                               );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          -- �Z�o�����|���ɑ΂���臒l�̃`�F�b�N
          IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
            OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
            --
            lv_thrshld_chk_err_flg := cv_yes;
            gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
          END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        END IF;
        --�}�X�^�|��
        g_xvdh_tab(gn_xvdh_idx).master_rate                 := l_xvdh_rec.master_rate;
        --���z
        g_xvdh_tab(gn_xvdh_idx).balance_amount              := ROUND(
                                                                 ln_ar_amount - ( ln_vdc_amount *
                                                                 g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                 cn_rate_fraction_place
                                                               );
        --�Ƒԏ�����
        g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho             := l_xvdh_rec.cust_gyotai_sho;
        --����Ŋz
        g_xvdh_tab(gn_xvdh_idx).tax_amount                  := ln_tax_amount;
        --�[�i��
        g_xvdh_tab(gn_xvdh_idx).delivery_date               := lt_delivery_date;
        --����
        g_xvdh_tab(gn_xvdh_idx).dlv_time                    := lt_dlv_time;
        --���ю҃R�[�h
        g_xvdh_tab(gn_xvdh_idx).performance_by_code         := lt_performance_by_code;
        --�̔����ѓo�^��
        g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date  := NULL;
        --�̔����э쐬�σt���O
        g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag  := ct_sr_creation_flag_no;
        --�O������v�Z���N����
-- == 2010/04/05 V1.15 Modified START ===============================================================
--        g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := l_xvdh_rec.pre_digestion_due_date;
        g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := NVL(ld_pre_digest_due_date, l_xvdh_rec.pre_digestion_due_date);
-- == 2010/04/05 V1.15 Modified END   ===============================================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
          g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
        ELSE
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
          --���v�Z�敪(���[�J���֐��g�p�j
          g_xvdh_tab(gn_xvdh_idx).uncalculate_class           := get_uncalculate_class(
                                                                   iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                   iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                 );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        --��K�؂ꎞ��100�~
        g_xvdh_tab(gn_xvdh_idx).change_out_time_100         := lt_change_out_time_100;
        --��K�؂ꎞ��10�~
        g_xvdh_tab(gn_xvdh_idx).change_out_time_10          := lt_change_out_time_10;
        --WHO�J����
        g_xvdh_tab(gn_xvdh_idx).created_by                  := cn_created_by;
        g_xvdh_tab(gn_xvdh_idx).creation_date               := cd_creation_date;
        g_xvdh_tab(gn_xvdh_idx).last_updated_by             := cn_last_updated_by;
        g_xvdh_tab(gn_xvdh_idx).last_update_date            := cd_last_update_date;
        g_xvdh_tab(gn_xvdh_idx).last_update_login           := cn_last_update_login;
        g_xvdh_tab(gn_xvdh_idx).request_id                  := cn_request_id;
        g_xvdh_tab(gn_xvdh_idx).program_application_id      := cn_program_application_id;
        g_xvdh_tab(gn_xvdh_idx).program_id                  := cn_program_id;
        g_xvdh_tab(gn_xvdh_idx).program_update_date         := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
        g_xvdh_tab(gn_xvdh_idx).summary_data_flag           :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
        -- ===================================================
        -- �x�������p�J�E���g
        -- ===================================================
        IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
          gn_warn_cnt1                  := gn_warn_cnt1 + 1;
        ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
          gn_warn_cnt2                  := gn_warn_cnt2 + 1;
        ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
          gn_warn_cnt3                  := gn_warn_cnt3 + 1;
        END IF;
        --
      END LOOP get_xvdh_loop;
      --
      IF ( lv_xvdh_exists_flag = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      ELSE
        -- ===================================================
        -- A-3  ����VD�p�����v�Z���̍���f�[�^�폜
        -- ===================================================
        del_tt_vd_digestion(
          ov_errbuf                       => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                      => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                       => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-11 VD�R�����ʎ���w�b�_�X�V����
        -- ===================================================
        upd_vd_column_hdr(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-12 ����VD�p�����v�Z�w�b�_�o�^����
        -- ===================================================
        ins_vd_digestion_hdrs(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-10 ����VD�p�����v�Z���דo�^����
        -- ===================================================
        ins_vd_digestion_lns(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-20 �O�񖢌v�Z�f�[�^�X�V����
        -- ===================================================
        upd_pre_not_digestion_due(
            ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
      END IF;
      --
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    ELSIF ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      -- �p�����[�^�̒�������敪���u����i���ւ��j�v�̏ꍇ
      -- �����e�[�u��������
      g_xvch_tab.DELETE;
      g_tt_xvdh_tab.DELETE;
      g_xvdh_tab.DELETE;
      g_xvdl_tab.DELETE;
      gn_xvch_idx    := 0;
      gn_tt_xvdh_idx := 0;
      gn_xvdh_idx    := 0;
      gn_xvdl_idx    := 0;
      --
      -- ===================================================
      -- A-2  ����VD�p�����v�Z�w�b�_�擾����
      -- ===================================================
      l_xvdh_rec2                       := NULL;
      lv_xvdh_exists_flag               := cv_exists_flag_no;
      --
      <<get_xvdh_loop2>>
      FOR xvdh_rec2 IN xvdh_cur2 LOOP
        --
        BEGIN
          --
          l_xvdh_rec2                     := xvdh_rec2;
          -- 臒l�`�F�b�N�G���[�t���O�̏�����
          lv_thrshld_chk_err_flg          := cv_no;
          --
          -- ===================================================
          -- ����VD�p�����v�Z�w�b�_�Ώی������Z
          -- ===================================================
          gn_target_cnt1                  := gn_target_cnt1 + 1;
          --
          lv_xvdh_exists_flag             := cv_exists_flag_yes;
          -- ===================================================
          -- ����VD�p�����v�Z�w�b�_�A���׃f�[�^���b�N����(A-2-1)
          -- ===================================================
          lock_hdrs_lns_data(
            it_vd_dgstn_hdr_id                => l_xvdh_rec2.vd_digestion_hdr_id,
            iv_customer_num                   => l_xvdh_rec2.customer_number,
            ov_errbuf                         => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                        => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                         => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE skip_error_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Del Start
--          --
--          -- ===================================================
--          -- ����f�[�^�Z�b�g
--          -- ===================================================
--          gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
--                                          := l_xvdh_rec2.vd_digestion_hdr_id;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
--                                          := l_xvdh_rec2.customer_number;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
--                                          := l_xvdh_rec2.digestion_due_date;
---- 2010/03/24 Ver.1.14 Add Start
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
--                                          := l_xvdh_rec2.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
--          --
--          -- ===================================================
--          -- VD�R�����ʎ���w�b�_�f�[�^�Z�b�g
--          -- ===================================================
--          gn_xvch_idx                     := gn_xvch_idx + 1;
--          g_xvch_tab(gn_xvch_idx).customer_number
--                                          := l_xvdh_rec2.customer_number;
--          g_xvch_tab(gn_xvch_idx).digestion_due_date
--                                          := l_xvdh_rec2.digestion_due_date;
--          g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
--                                          := NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date );
---- 2010/03/24 Ver.1.14 Add Start
--          g_xvch_tab(gn_xvch_idx).sales_base_code
--                                          := l_xvdh_rec2.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
-- 2015/10/19 Ver.1.19 K.Kiriu Del End
          --
          -- ===================================================
          -- A-4  �w�b�_�P�ʏ���������
          -- ===================================================
          ini_header(
            ot_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  1.����VD�p�����v�Z�w�b�_ID
            ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  2.AR���v�Z�敪
            ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  3.VD�R�����ʖ��v�Z�敪
            on_ar_amount                  => ln_ar_amount,                      --  4.������z���v
            on_tax_amount                 => ln_tax_amount,                     --  5.����Ŋz���v
            on_vdc_amount                 => ln_vdc_amount,                     --  6.�̔����z���v
            ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added START ===============================================================
          -- ===================================================
          -- A-21 �O�񖢌v�Z�f�[�^�`�F�b�N����
          -- ===================================================
          chk_pre_not_digestion_due(
              iv_customer_code          =>    l_xvdh_rec2.customer_number
            , od_pre_digest_due_date    =>    ld_pre_digest_due_date
            , ov_errbuf                 =>    lv_errbuf
            , ov_retcode                =>    lv_retcode
            , ov_errmsg                 =>    lv_errmsg
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added END   ===============================================================
          -- ===================================================
          -- A-5  AR������擾����
          -- ===================================================
          -- ������
          lv_ar_uncalculate_type          := cv_uncalculate_type_init;
          --
          get_cust_trx(
            it_cust_account_id            => l_xvdh_rec2.cust_account_id,        --  1.�ڋqID
            it_customer_number            => l_xvdh_rec2.customer_number,        --  2.�ڋq�R�[�h
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            id_start_gl_date              => NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date ),
            id_start_gl_date              => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                                --  3.�J�nGL�L����
-- == 2010/04/05 V1.15 Modified END   ===============================================================
            id_end_gl_date                => l_xvdh_rec2.digestion_due_date,     --  4.�I��GL�L����
            ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  5.AR������v�Z�敪
            on_ar_amount                  => ln_ar_amount,                      --  6.������z���v
            on_tax_amount                 => ln_tax_amount,                     --  7.����Ŋz���v
            ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-7  VD�R�����ʎ�����擾����
          -- ===================================================
          -- ������
          lv_vdc_uncalculate_type         := cv_uncalculate_type_init;
          lt_delivery_date                := NULL;                 -- �[�i��
          lt_dlv_time                     := NULL;                 -- �[�i����
          lt_performance_by_code          := NULL;                 -- ���ю҃R�[�h
          lt_change_out_time_100          := NULL;                 -- ��K�؂ꎞ��100�~
          lt_change_out_time_10           := NULL;                 -- ��K�؂ꎞ��10�~
          --
          get_vd_column(
            it_cust_account_id            => l_xvdh_rec2.cust_account_id,        --  1.�ڋqID
            it_customer_number            => l_xvdh_rec2.customer_number,        --  2.�ڋq�R�[�h
            it_digestion_due_date         => l_xvdh_rec2.digestion_due_date,     --  3.�����v�Z���N����
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            it_pre_digestion_due_date     => NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date ),
            it_pre_digestion_due_date     => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                                --  4.�O������v�Z���N����
-- == 2010/04/05 V1.15 Modified END   ===============================================================
            it_delivery_base_code         => l_xvdh_rec2.delivery_base_code,     --  5.�[�i���_�R�[�h
            it_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  6.����VD�����v�Z�w�b�_ID
            it_sales_base_code            => l_xvdh_rec2.sales_base_code,        --  7.���㋒�_�R�[�h
            ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  8.VD�R�����ʎ�����v�Z�t���O
            on_vdc_amount                 => ln_vdc_amount,                     --  9.�̔����z���v
            ot_delivery_date              => lt_delivery_date,                  -- 10.�[�i���i�ŐV�f�[�^�j
            ot_dlv_time                   => lt_dlv_time,                       -- 11.�[�i���ԁi�ŐV�f�[�^�j
            ot_performance_by_code        => lt_performance_by_code,            -- 12.���ю҃R�[�h�i�ŐV�f�[�^�j
            ot_change_out_time_100        => lt_change_out_time_100,            -- 13.��K�؂ꎞ��100�~�i�ŐV�f�[�^�j
            ot_change_out_time_10         => lt_change_out_time_10,             -- 14.��K�؂ꎞ��10�~�i�ŐV�f�[�^�j
            ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--          IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE skip_error_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
            RAISE global_process_expt;
          END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Add Start
          --
          -- ===================================================
          -- ����f�[�^�Z�b�g
          -- ===================================================
          gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                          := l_xvdh_rec2.vd_digestion_hdr_id;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
                                          := l_xvdh_rec2.customer_number;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
                                          := l_xvdh_rec2.digestion_due_date;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
                                          := l_xvdh_rec2.sales_base_code;
          --
          -- ===================================================
          -- VD�R�����ʎ���w�b�_�f�[�^�Z�b�g
          -- ===================================================
          gn_xvch_idx                     := gn_xvch_idx + 1;
          g_xvch_tab(gn_xvch_idx).customer_number
                                          := l_xvdh_rec2.customer_number;
          g_xvch_tab(gn_xvch_idx).digestion_due_date
                                          := l_xvdh_rec2.digestion_due_date;
          g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                          := NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date );
          g_xvch_tab(gn_xvch_idx).sales_base_code
                                          := l_xvdh_rec2.sales_base_code;
-- 2015/10/19 Ver.1.19 K.Kiriu Add End
          --
          -- ===================================================
          -- ����VD�p�����v�Z�w�b�_�o�^�p�Z�b�g����
          -- ===================================================
          gn_xvdh_idx := gn_xvdh_idx + 1;
          --����VD�p�����v�Z�w�b�_ID
          g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id         := lt_vd_digestion_hdr_id;
          --�ڋq�R�[�h
          g_xvdh_tab(gn_xvdh_idx).customer_number             := l_xvdh_rec2.customer_number;
          --�����v�Z���N����
          g_xvdh_tab(gn_xvdh_idx).digestion_due_date          := l_xvdh_rec2.digestion_due_date;
          --���㋒�_�R�[�h
          g_xvdh_tab(gn_xvdh_idx).sales_base_code             := l_xvdh_rec2.sales_base_code;
          --�ڋq�h�c
          g_xvdh_tab(gn_xvdh_idx).cust_account_id             := l_xvdh_rec2.cust_account_id;
          --�����v�Z���s��
          g_xvdh_tab(gn_xvdh_idx).digestion_exe_date          := gd_process_date;
          --������z
          g_xvdh_tab(gn_xvdh_idx).ar_sales_amount             := ROUND( ln_ar_amount );
          --�̔����z
          g_xvdh_tab(gn_xvdh_idx).sales_amount                := ROUND( ln_vdc_amount );
          --�����v�Z�|��
          IF ( ( ln_ar_amount = cn_amount_default )
            OR ( ln_vdc_amount = cn_amount_default ) )
          THEN
            g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := 0;
          ELSE
            g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := ROUND(
                                                                   ln_ar_amount / ln_vdc_amount * 100,
                                                                   cn_rate_fraction_place
                                                                 );
            -- �Z�o�����|���ɑ΂���臒l�̃`�F�b�N
            IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
              OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
              --
              lv_thrshld_chk_err_flg := cv_yes;
              gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
            END IF;
          END IF;
          --�}�X�^�|��
          g_xvdh_tab(gn_xvdh_idx).master_rate                 := l_xvdh_rec2.master_rate;
          --���z
          g_xvdh_tab(gn_xvdh_idx).balance_amount              := ROUND(
                                                                   ln_ar_amount - ( ln_vdc_amount *
                                                                   g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                   cn_rate_fraction_place
                                                                 );
          --�Ƒԏ�����
          g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho             := l_xvdh_rec2.cust_gyotai_sho;
          --����Ŋz
          g_xvdh_tab(gn_xvdh_idx).tax_amount                  := ln_tax_amount;
          --�[�i��
          g_xvdh_tab(gn_xvdh_idx).delivery_date               := lt_delivery_date;
          --����
          g_xvdh_tab(gn_xvdh_idx).dlv_time                    := lt_dlv_time;
          --���ю҃R�[�h
          g_xvdh_tab(gn_xvdh_idx).performance_by_code         := lt_performance_by_code;
          --�̔����ѓo�^��
          g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date  := NULL;
          --�̔����э쐬�σt���O
          g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag  := ct_sr_creation_flag_no;
          --�O������v�Z���N����
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := l_xvdh_rec2.pre_digestion_due_date;
          g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := NVL(ld_pre_digest_due_date, l_xvdh_rec2.pre_digestion_due_date);
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
            g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
          ELSE
            --���v�Z�敪(���[�J���֐��g�p�j
            g_xvdh_tab(gn_xvdh_idx).uncalculate_class           := get_uncalculate_class(
                                                                     iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                     iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                   );
          END IF;
          --��K�؂ꎞ��100�~
          g_xvdh_tab(gn_xvdh_idx).change_out_time_100         := lt_change_out_time_100;
          --��K�؂ꎞ��10�~
          g_xvdh_tab(gn_xvdh_idx).change_out_time_10          := lt_change_out_time_10;
          --WHO�J����
          g_xvdh_tab(gn_xvdh_idx).created_by                  := cn_created_by;
          g_xvdh_tab(gn_xvdh_idx).creation_date               := cd_creation_date;
          g_xvdh_tab(gn_xvdh_idx).last_updated_by             := cn_last_updated_by;
          g_xvdh_tab(gn_xvdh_idx).last_update_date            := cd_last_update_date;
          g_xvdh_tab(gn_xvdh_idx).last_update_login           := cn_last_update_login;
          g_xvdh_tab(gn_xvdh_idx).request_id                  := cn_request_id;
          g_xvdh_tab(gn_xvdh_idx).program_application_id      := cn_program_application_id;
          g_xvdh_tab(gn_xvdh_idx).program_id                  := cn_program_id;
          g_xvdh_tab(gn_xvdh_idx).program_update_date         := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
          g_xvdh_tab(gn_xvdh_idx).summary_data_flag           :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
          -- ===================================================
          -- �x�������p�J�E���g
          -- ===================================================
          IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
            gn_warn_cnt1                  := gn_warn_cnt1 + 1;
          ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
            gn_warn_cnt2                  := gn_warn_cnt2 + 1;
          ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
            gn_warn_cnt3                  := gn_warn_cnt3 + 1;
          END IF;
          --
        EXCEPTION
          WHEN skip_error_expt THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
            --
            --���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf --�G���[���b�Z�[�W
            );
            --
          WHEN global_process_expt THEN
            RAISE global_process_expt;
        END;
      END LOOP get_xvdh_loop2;
      --
      IF ( lv_xvdh_exists_flag = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      ELSE
        -- ===================================================
        -- A-3  ����VD�p�����v�Z���̍���f�[�^�폜
        -- ===================================================
        del_tt_vd_digestion(
          ov_errbuf                       => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                      => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                       => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-11 VD�R�����ʎ���w�b�_�X�V����
        -- ===================================================
        upd_vd_column_hdr(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-12 ����VD�p�����v�Z�w�b�_�o�^����
        -- ===================================================
        ins_vd_digestion_hdrs(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-10 ����VD�p�����v�Z���דo�^����
        -- ===================================================
        ins_vd_digestion_lns(
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-20 �O�񖢌v�Z�f�[�^�X�V����
        -- ===================================================
        upd_pre_not_digestion_due(
            ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
      END IF;
      --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    ELSE
      --�p�����[�^�̒�������敪���u����v�̏ꍇ
      lv_cust_exists_flag2              := cv_exists_flag_no;
      -- ===================================================
      -- A-13 �ғ������擾����
      -- ===================================================
      get_operation_day(
        ov_errbuf                       => lv_errbuf,                 -- �G���[�E���b�Z�[�W
        ov_retcode                      => lv_retcode,                -- ���^�[���E�R�[�h
        ov_errmsg                       => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --
/* 2010/01/19 Ver1.11 Del Start */
--      -- ===================================================
--      -- A-14 ��ғ������擾����
--      -- ===================================================
--      get_non_operation_day(
--        ov_errbuf                       => lv_errbuf,                 -- �G���[�E���b�Z�[�W
--        ov_retcode                      => lv_retcode,                -- ���^�[���E�R�[�h
--        ov_errmsg                       => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--      --
--      IF ( lv_retcode <> cv_status_normal ) THEN
--        RAISE global_process_expt;
--      END IF;
/* 2010/01/19 Ver1.11 Del End */
      --
      IF ( g_diges_due_dt_tab.COUNT > 0 ) THEN
        -- ===================================================
        -- A-15 ����VD�ʗp�����v�Z���̑O�X��f�[�^�폜����
        -- ===================================================
        ln_idx                          := g_diges_due_dt_tab.COUNT;
        --
        del_blt_vd_digestion(
          it_digestion_due_date         => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.�����v�Z���N����
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      -- ===================================================
      -- ������s�������[�v
      -- ===================================================
      <<calc_due_loop>>
      FOR i IN 1.. g_diges_due_dt_tab.COUNT LOOP
        ln_idx                := g_diges_due_dt_tab.COUNT - ( i - 1 );
        --
        lv_cust_exists_flag1  := cv_exists_flag_no;
        --�����e�[�u��������
        g_xvch_tab.DELETE;
        g_tt_xvdh_tab.DELETE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        g_tt_xvdh_work_tab.DELETE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        g_xvdh_tab.DELETE;
        g_xvdl_tab.DELETE;
        gn_xvch_idx           := 0;
        gn_tt_xvdh_idx        := 0;
        gn_xvdh_idx           := 0;
        gn_xvdl_idx           := 0;
        --
        -- ===================================================
        -- A-16 �����Z�o����
        -- ===================================================
        calc_due_day(
          id_digestion_due_date         => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.�����v�Z���N����
          ov_due_day                    => lv_due_day,                -- 2.����
          ov_last_day                   => lv_last_day,               -- 3.������
          ov_leap_year_due_day          => lv_leap_year_due_day,      -- 4.�[�N����
          ov_errbuf                     => lv_errbuf,                 -- �G���[�E���b�Z�[�W
          ov_retcode                    => lv_retcode,                -- ���^�[���E�R�[�h
          ov_errmsg                     => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-17 �ڋq�}�X�^�擾����
        -- ===================================================
        <<cust_loop>>
        FOR cust_rec IN cust_cur(
                          id_digestion_due_date   => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.�����v�Z���N����
                          iv_due_day              => lv_due_day,      -- 2.����
                          iv_last_day             => lv_last_day,     -- 3.������
                          iv_leap_year_due_day    => lv_leap_year_due_day
                                                                      -- 4.�[�N����
                        )
        LOOP
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          BEGIN
            -- 臒l�`�F�b�N�G���[�t���O�̏�����
            lv_thrshld_chk_err_flg        := cv_no;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
            --
            l_cust_rec                    := cust_rec;
            --
            -- ===================================================
            -- A-18 �O������v�Z���N�����Z�o����
            -- ===================================================
            calc_pre_diges_due_dt(
              it_cust_account_id          => l_cust_rec.cust_account_id,
                                                                        --  1.�ڋqID
              it_customer_number          => l_cust_rec.customer_number,
                                                                        --  2.�ڋq�R�[�h
              id_digestion_due_date       => g_diges_due_dt_tab(ln_idx),
                                                                        --  3.�����v�Z���N����
              id_stop_approval_date       => l_cust_rec.stop_approval_date,
                                                                        --  4.���~���ٓ�
              od_pre_digestion_due_date   => ld_pre_digestion_due_date,
                                                                        --  5.�O������v�Z���N����
              ov_errbuf                   => lv_errbuf,                 -- �G���[�E���b�Z�[�W
              ov_retcode                  => lv_retcode,                -- ���^�[���E�R�[�h
              ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            --
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
            --
            IF ( ld_pre_digestion_due_date IS NULL ) THEN
              NULL;
            ELSE
              -- ===================================================
              -- �ڋq�}�X�^�Ώی������Z
              -- ===================================================
              gn_target_cnt1              := gn_target_cnt1 + 1;
              --
              lv_cust_exists_flag1        := cv_exists_flag_yes;
              lv_cust_exists_flag2        := cv_exists_flag_yes;
              -- ===================================================
              -- �̔����я�񖢍쐬�̃f�[�^�𒊏o
              -- ===================================================
              <<tt_xvdh_loop>>
              FOR tt_xvdh_rec IN tt_xvdh_cur(
                                   it_customer_number         => l_cust_rec.customer_number
                                 )
              LOOP
                --
                l_tt_xvdh_rec             := tt_xvdh_rec;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
                -- ���b�N�擾�G���[�t���O�̏�����
                lv_lock_data_err_flg      := cv_no;
                --
                -- ===================================================
                -- ����VD�p�����v�Z�w�b�_�A���׃f�[�^���b�N����(A-2-1)
                -- ===================================================
                lock_hdrs_lns_data(
                  it_vd_dgstn_hdr_id                => l_tt_xvdh_rec.vd_digestion_hdr_id,
                  iv_customer_num                   => l_cust_rec.customer_number,
                  ov_errbuf                         => lv_errbuf,                 -- �G���[�E���b�Z�[�W
                  ov_retcode                        => lv_retcode,                -- ���^�[���E�R�[�h
                  ov_errmsg                         => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
                );
                --
                IF ( lv_retcode = cv_status_warn ) THEN
                  lv_lock_data_err_flg := cv_yes;
                  EXIT;
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
                --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--                -- ����f�[�^�Z�b�g
--                gn_tt_xvdh_idx            := gn_tt_xvdh_idx + 1;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
--                                          := l_tt_xvdh_rec.vd_digestion_hdr_id;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
--                                          := l_cust_rec.customer_number;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
--                                          := g_diges_due_dt_tab(ln_idx);
                -- ����f�[�^�����[�N�ϐ��ɃZ�b�g
                gn_tt_xvdh_idx         := gn_tt_xvdh_idx + 1;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                          := l_tt_xvdh_rec.vd_digestion_hdr_id;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).customer_number
                                          := l_cust_rec.customer_number;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).digestion_due_date
                                          := g_diges_due_dt_tab(ln_idx);
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
              END LOOP tt_xvdh_loop;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              IF ( lv_lock_data_err_flg = cv_yes ) THEN
                RAISE skip_error_expt;
              END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Del Start
--              -- ===================================================
--              -- ����f�[�^�Z�b�g
--              -- ===================================================
--              <<tt_xvdh_loop2>>
--              FOR ln_wk_idx IN 1..g_tt_xvdh_work_tab.COUNT LOOP
--                -- ����f�[�^�Z�b�g
--                g_tt_xvdh_tab(ln_wk_idx).vd_digestion_hdr_id
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).vd_digestion_hdr_id;
--                g_tt_xvdh_tab(ln_wk_idx).customer_number
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).customer_number;
--                g_tt_xvdh_tab(ln_wk_idx).digestion_due_date
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).digestion_due_date;
---- 2010/03/24 Ver.1.14 Add Start
--                g_tt_xvdh_tab(ln_wk_idx).sales_base_code
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
--              --
--              END LOOP tt_xvdh_loop2;
---- 2010/02/15 Ver.1.13 K.Hosoi Add End
--              --
--              -- ===================================================
--              -- VD�R�����ʎ���w�b�_�f�[�^�Z�b�g
--              -- ===================================================
--              gn_xvch_idx                 := gn_xvch_idx + 1;
--              g_xvch_tab(gn_xvch_idx).customer_number
--                                          := l_cust_rec.customer_number;
--              g_xvch_tab(gn_xvch_idx).digestion_due_date
--                                          := g_diges_due_dt_tab(ln_idx);
--              g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
--                                          := CASE
--                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
--                                               THEN ld_pre_digestion_due_date
--                                               ELSE ld_pre_digestion_due_date + cn_one_day
--                                             END;
---- 2010/03/24 Ver.1.14 Add Start
--              g_xvch_tab(gn_xvch_idx).sales_base_code
--                                          := l_cust_rec.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
-- 2015/10/19 Ver.1.19 K.Kiriu Del End
              --
              -- ===================================================
              -- A-4  �w�b�_�P�ʏ���������
              -- ===================================================
              ini_header(
                ot_vd_digestion_hdr_id    => lt_vd_digestion_hdr_id,        --  1.����VD�p�����v�Z�w�b�_ID
                ov_ar_uncalculate_type    => lv_ar_uncalculate_type,        --  2.AR���v�Z�敪
                ov_vdc_uncalculate_type   => lv_vdc_uncalculate_type,       --  3.VD�R�����ʖ��v�Z�敪
                on_ar_amount              => ln_ar_amount,                  --  4.������z���v
                on_tax_amount             => ln_tax_amount,                 --  5.����Ŋz���v
                on_vdc_amount             => ln_vdc_amount,                 --  6.�̔����z���v
                ov_errbuf                 => lv_errbuf,               -- �G���[�E���b�Z�[�W
                ov_retcode                => lv_retcode,              -- ���^�[���E�R�[�h
                ov_errmsg                 => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              --
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
              --
              -- ===================================================
              -- A-5  AR������擾����
              -- ===================================================
              -- ������
              lv_ar_uncalculate_type      := cv_uncalculate_type_init;
              --
              get_cust_trx(
                it_cust_account_id        => l_cust_rec.cust_account_id,    --  1.�ڋqID
                it_customer_number        => l_cust_rec.customer_number,    --  2.�ڋq�R�[�h
                id_start_gl_date          => CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END,                           --  3.�J�nGL�L����
                id_end_gl_date            => g_diges_due_dt_tab(ln_idx),    --  4.�I��GL�L����
                ov_ar_uncalculate_type    => lv_ar_uncalculate_type,        --  5.AR���v�Z�敪
                on_ar_amount              => ln_ar_amount,                  --  6.������z���v
                on_tax_amount             => ln_tax_amount,                 --  7.����Ŋz���v
                ov_errbuf                 => lv_errbuf,               -- �G���[�E���b�Z�[�W
                ov_retcode                => lv_retcode,              -- ���^�[���E�R�[�h
                ov_errmsg                 => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              --
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
              --
              -- ===================================================
              -- A-7  VD�R�����ʎ�����擾����
              -- ===================================================
              -- ������
              lv_vdc_uncalculate_type     := cv_uncalculate_type_init;
              lt_delivery_date            := NULL;                    -- �[�i��
              lt_dlv_time                 := NULL;                    -- �[�i����
              lt_performance_by_code      := NULL;                    -- ���ю҃R�[�h
              lt_change_out_time_100      := NULL;                    -- ��K�؂ꎞ��100�~
              lt_change_out_time_10       := NULL;                    -- ��K�؂ꎞ��10�~
              --
              get_vd_column(
                it_cust_account_id        => l_cust_rec.cust_account_id,    --  1.�ڋqID
                it_customer_number        => l_cust_rec.customer_number,    --  2.�ڋq�R�[�h
                it_digestion_due_date     => g_diges_due_dt_tab(ln_idx),    --  3.�����v�Z���N����
                it_pre_digestion_due_date => CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END,                           --  4.�O������v�Z���N����
                it_delivery_base_code     => l_cust_rec.delivery_base_code, --  5.�[�i���_�R�[�h
                it_vd_digestion_hdr_id    => lt_vd_digestion_hdr_id,        --  6.����VD�����v�Z�w�b�_ID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
                it_sales_base_code            => l_cust_rec.sales_base_code,--  7.���㋒�_�R�[�h
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
                ov_vdc_uncalculate_type   => lv_vdc_uncalculate_type,       --  8.VD�R�����ʎ�����v�Z�敪
                on_vdc_amount             => ln_vdc_amount,                 --  9.�̔����z���v
                ot_delivery_date          => lt_delivery_date,              -- 10.�[�i���i�ŐV�f�[�^�j
                ot_dlv_time               => lt_dlv_time,                   -- 11.�[�i���ԁi�ŐV�f�[�^�j
                ot_performance_by_code    => lt_performance_by_code,        -- 12.���ю҃R�[�h�i�ŐV�f�[�^�j
                ot_change_out_time_100    => lt_change_out_time_100,        -- 13.��K�؂ꎞ��100�~�i�ŐV�f�[�^�j
                ot_change_out_time_10     => lt_change_out_time_10,         -- 14.��K�؂ꎞ��10�~�i�ŐV�f�[�^�j
                ov_errbuf                 => lv_errbuf,               -- �G���[�E���b�Z�[�W
                ov_retcode                => lv_retcode,              -- ���^�[���E�R�[�h
                ov_errmsg                 => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              --
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--              IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_retcode = cv_status_warn ) THEN
                RAISE skip_error_expt;
              ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
                RAISE global_process_expt;
              END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Add Start
              -- ===================================================
              -- ����f�[�^�Z�b�g
              -- ===================================================
              <<tt_xvdh_loop2>>
              FOR ln_wk_idx IN 1..g_tt_xvdh_work_tab.COUNT LOOP
                -- ����f�[�^�Z�b�g
                g_tt_xvdh_tab(ln_wk_idx).vd_digestion_hdr_id
                                          := g_tt_xvdh_work_tab(ln_wk_idx).vd_digestion_hdr_id;
                g_tt_xvdh_tab(ln_wk_idx).customer_number
                                          := g_tt_xvdh_work_tab(ln_wk_idx).customer_number;
                g_tt_xvdh_tab(ln_wk_idx).digestion_due_date
                                          := g_tt_xvdh_work_tab(ln_wk_idx).digestion_due_date;
                g_tt_xvdh_tab(ln_wk_idx).sales_base_code
                                          := g_tt_xvdh_work_tab(ln_wk_idx).sales_base_code;
              --
              END LOOP tt_xvdh_loop2;
              --
              -- ===================================================
              -- VD�R�����ʎ���w�b�_�f�[�^�Z�b�g
              -- ===================================================
              gn_xvch_idx                 := gn_xvch_idx + 1;
              g_xvch_tab(gn_xvch_idx).customer_number
                                          := l_cust_rec.customer_number;
              g_xvch_tab(gn_xvch_idx).digestion_due_date
                                          := g_diges_due_dt_tab(ln_idx);
              g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                          := CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END;
              g_xvch_tab(gn_xvch_idx).sales_base_code
                                          := l_cust_rec.sales_base_code;
-- 2015/10/19 Ver.1.19 K.Kiriu Add End
              --
              -- ===================================================
              -- ����VD�p�����v�Z�w�b�_�o�^�p�Z�b�g����
              -- ===================================================
              gn_xvdh_idx := gn_xvdh_idx + 1;
              --����VD�p�����v�Z�w�b�_ID
              g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id     := lt_vd_digestion_hdr_id;
              --�ڋq�R�[�h
              g_xvdh_tab(gn_xvdh_idx).customer_number         := l_cust_rec.customer_number;
              --�����v�Z���N����
              g_xvdh_tab(gn_xvdh_idx).digestion_due_date      := g_diges_due_dt_tab(ln_idx);
              --���㋒�_�R�[�h
              g_xvdh_tab(gn_xvdh_idx).sales_base_code         := l_cust_rec.sales_base_code;
              --�ڋq�h�c
              g_xvdh_tab(gn_xvdh_idx).cust_account_id         := l_cust_rec.cust_account_id;
              --�����v�Z���s��
              g_xvdh_tab(gn_xvdh_idx).digestion_exe_date      := gd_process_date;
              --������z
              g_xvdh_tab(gn_xvdh_idx).ar_sales_amount         := ln_ar_amount;
              --�̔����z
              g_xvdh_tab(gn_xvdh_idx).sales_amount            := ln_vdc_amount;
              --�����v�Z�|��
              IF ( ( ln_ar_amount = cn_amount_default )
                OR ( ln_vdc_amount = cn_amount_default ) )
              THEN
                g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate   := 0;
              ELSE
                g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate   := ROUND(
                                                                   ln_ar_amount / ln_vdc_amount * 100,
                                                                   cn_rate_fraction_place
                                                                 );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
                -- �Z�o�����|���ɑ΂���臒l�̃`�F�b�N
                IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
                  OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
                  --
                  lv_thrshld_chk_err_flg := cv_yes;
                  gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
                END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
              END IF;
              --�}�X�^�|��
              g_xvdh_tab(gn_xvdh_idx).master_rate             := l_cust_rec.master_rate;
              --���z
              g_xvdh_tab(gn_xvdh_idx).balance_amount          := ROUND(
                                                                   ln_ar_amount - ( ln_vdc_amount *
                                                                   g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                   cn_rate_fraction_place
                                                                 );
              --�Ƒԏ�����
              g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho         := l_cust_rec.cust_gyotai_sho;
              --����Ŋz
              g_xvdh_tab(gn_xvdh_idx).tax_amount              := ln_tax_amount;
              --�[�i��
              g_xvdh_tab(gn_xvdh_idx).delivery_date           := lt_delivery_date;
              --����
              g_xvdh_tab(gn_xvdh_idx).dlv_time                := lt_dlv_time;
              --���ю҃R�[�h
              g_xvdh_tab(gn_xvdh_idx).performance_by_code     := lt_performance_by_code;
              --�̔����ѓo�^��
              g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date
                                                              := NULL;
              --�̔����э쐬�σt���O
              g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag
                                                              := ct_sr_creation_flag_no;
              --�O������v�Z���N����
              g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date
                                                              := CASE
                                                                   WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                                                   THEN
                                                                     NULL
                                                                   ELSE
                                                                     ld_pre_digestion_due_date
                                                                 END;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
                g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
              ELSE
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
                --���v�Z�敪(���[�J���֐��g�p�j
                g_xvdh_tab(gn_xvdh_idx).uncalculate_class       := get_uncalculate_class(
                                                                     iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                     iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                   );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
              --��K�؂ꎞ��100�~
              g_xvdh_tab(gn_xvdh_idx).change_out_time_100     := lt_change_out_time_100;
              --��K�؂ꎞ��10�~
              g_xvdh_tab(gn_xvdh_idx).change_out_time_10      := lt_change_out_time_10;
              --WHO�J����
              g_xvdh_tab(gn_xvdh_idx).created_by              := cn_created_by;
              g_xvdh_tab(gn_xvdh_idx).creation_date           := cd_creation_date;
              g_xvdh_tab(gn_xvdh_idx).last_updated_by         := cn_last_updated_by;
              g_xvdh_tab(gn_xvdh_idx).last_update_date        := cd_last_update_date;
              g_xvdh_tab(gn_xvdh_idx).last_update_login       := cn_last_update_login;
              g_xvdh_tab(gn_xvdh_idx).request_id              := cn_request_id;
              g_xvdh_tab(gn_xvdh_idx).program_application_id  := cn_program_application_id;
              g_xvdh_tab(gn_xvdh_idx).program_id              := cn_program_id;
              g_xvdh_tab(gn_xvdh_idx).program_update_date     := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
              g_xvdh_tab(gn_xvdh_idx).summary_data_flag       :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
              -- ===================================================
              --  �x�������p�J�E���g
              -- ===================================================
              IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
                gn_warn_cnt1              := gn_warn_cnt1 + 1;
              ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
                gn_warn_cnt2              := gn_warn_cnt2 + 1;
              ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
                gn_warn_cnt3              := gn_warn_cnt3 + 1;
              END IF;
            --
            END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          EXCEPTION
            WHEN skip_error_expt THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
              --
              IF ( tt_xvdh_cur%ISOPEN ) THEN
                CLOSE tt_xvdh_cur;
              END IF;
              --���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
              );
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errbuf --�G���[���b�Z�[�W
              );
              --
            WHEN global_process_expt THEN
              IF ( tt_xvdh_cur%ISOPEN ) THEN
                CLOSE tt_xvdh_cur;
              END IF;
              RAISE global_process_expt;
          END;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
          --
        END LOOP cust_loop;
        --
        IF ( lv_cust_exists_flag1 = cv_exists_flag_yes ) THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--          -- ===================================================
--          -- A-3  ����VD�p�����v�Z���̍���f�[�^�폜
--          -- ===================================================
--          del_tt_vd_digestion(
--            ov_errbuf                   => lv_errbuf,                 -- �G���[�E���b�Z�[�W
--            ov_retcode                  => lv_retcode,                -- ���^�[���E�R�[�h
--            ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--          );
--          --
--          IF ( lv_retcode <> cv_status_normal ) THEN
--            RAISE global_process_expt;
--          END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
          --
          -- ===================================================
          -- A-11 VD�R�����ʎ���w�b�_�X�V����
          -- ===================================================
          upd_vd_column_hdr(
            ov_errbuf                   => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-12 ����VD�p�����v�Z�w�b�_�o�^����
          -- ===================================================
          ins_vd_digestion_hdrs(
            ov_errbuf                   => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-10 ����VD�p�����v�Z���דo�^����
          -- ===================================================
          ins_vd_digestion_lns(
            ov_errbuf                   => lv_errbuf,                 -- �G���[�E���b�Z�[�W
            ov_retcode                  => lv_retcode,                -- ���^�[���E�R�[�h
            ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added START ===============================================================
          -- ===================================================
          -- A-20 �O�񖢌v�Z�f�[�^�X�V����
          -- ===================================================
          upd_pre_not_digestion_due(
              ov_errbuf                 =>    lv_errbuf
            , ov_retcode                =>    lv_retcode
            , ov_errmsg                 =>    lv_errmsg
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added END   ===============================================================
        END IF;
        --
      END LOOP calc_due_loop;
      --
      IF ( lv_cust_exists_flag2 = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      END IF;
    END IF;
--
    COMMIT;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    IF ( gn_thrshld_chk_cnt > 0) THEN
      RAISE thrshld_chk_expt;
    END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
  EXCEPTION
    -- *** �Ώۃf�[�^������O�n���h�� ***
    WHEN global_target_nodata_expt THEN
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_target_nodata_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    -- *** 臒l�`�F�b�N�L���O�n���h�� ***
    WHEN thrshld_chk_expt THEN
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_thrshld_chk_err,
                                   iv_token_name1        => cv_tkn_max_thrshld,
                                   iv_token_value1       => TO_CHAR(gn_max_threshold),
                                   iv_token_name2        => cv_tkn_min_thrshld,
                                   iv_token_value2       => TO_CHAR(gn_min_threshold)
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_regular_any_class      IN      VARCHAR2,         -- 1.��������敪
    iv_base_code              IN      VARCHAR2,         -- 1.���_�R�[�h
    iv_customer_number        IN      VARCHAR2,          -- 2.�ڋq�R�[�h
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';      -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';         -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_regular_any_class                -- 1.��������敪
      ,iv_base_code                        -- 2.���_�R�[�h
      ,iv_customer_number                  -- 3.�ڋq�R�[�h
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
      ,iv_process_date                     -- 4.�Ɩ����t
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_target_count
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt1 )
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR( gn_target_cnt2 )
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR( gn_target_cnt3 )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
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
    --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application  => ct_xxcos_appl_short_name
                  ,iv_name         => ct_msg_warning_count
                  ,iv_token_name1  => cv_tkn_count1
                  ,iv_token_value1 => TO_CHAR( gn_warn_cnt1 )
                  ,iv_token_name2  => cv_tkn_count2
                  ,iv_token_value2 => TO_CHAR( gn_warn_cnt2 )
                  ,iv_token_name3  => cv_tkn_count3
                  ,iv_token_value3 => TO_CHAR( gn_warn_cnt3 )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS004A06C;
/
