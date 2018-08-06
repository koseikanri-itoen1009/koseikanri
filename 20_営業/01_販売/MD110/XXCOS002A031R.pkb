CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A031R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A031R(body)
 * Description      : �c�Ɛ��ѕ\
 * MD.050           : �c�Ɛ��ѕ\ MD050_COS_002_A03
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  entry_sales_plan       �c�ƈ��v��f�[�^���o���o�^(A-2)
 *  update_business_conditions
 *                         �Ƒԕʔ������ �W�v�����A���f����(A-3,A-4)
 *                         �[�i�`�ԕʔ̔����я��W�v�����f����(A-7)
 *                         ���ѐU�֏��W�v�����f����(A-8)
 *  update_policy_group    ����Q�� ������� �W�v�A���f����(A-5,A-6)
 *  update_new_cust_sales_results
 *                         �V�K�v��������я��W�v�����f����(A-9)
 *  update_results_of_business
 *                         �e�팏���擾�����f����(A-10)
 *  update_policy_group_py ����Q�� �O�N������� �W�v�A���f����(A-17,A-18)
 *  insert_section_total   �ۏW�v��񐶐�(A-11)
 *  insert_base_total      ���_�W�v��񐶐�(A-12)
 *  delete_off_the_subject_info
 *                         �o�͑ΏۊO���폜(A-13)
 *  execute_svf            �r�u�e�N��(A-14)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-15)
 *  end_process            �I������(A-16)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/09    1.0   T.Nakabayashi    �V�K�쐬
 *  2009/02/23    1.1   T.Nakabayashi    [COS_123]A-2 �O���[�v�R�[�h���ݒ�ł��ʂ̐��ѕ\�͏o�͉\�Ƃ���
 *  2009/02/26    1.2   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *  2009/02/27    1.3   T.Nakabayashi    ���[���[�N�e�[�u���폜���� �R�����g�A�E�g����
 *  2009/06/09    1.4   T.Tominaga       ���[���[�N�e�[�u���폜����"delete_rpt_wrk_data" �R�����g�A�E�g����
 *  2009/06/18    1.5   K.Kiriu          [T1_1446]PT�Ή�
 *  2009/06/22    1.6   K.Kiriu          [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/07    1.7   K.Kiriu          [0000418]�폜�����擾�s��Ή�
 *  2009/09/03    1.8   K.Kiriu          [0000866]PT�Ή�
 *  2010/04/16    1.9   D.Abe            [E_�{�ғ�_02251,02270]�J�����_,���_�v�ڋq�����Ή�
 *  2011/02/15    1.10  H.Sasaki         [E_�{�ғ�_01730]���т̂Ȃ��f�[�^���o�͑Ώۂ��珜�O����
 *  2011/02/21    1.11  H.Sasaki         [E_�{�ғ�_05896]����Q���̂Q�d�\���}�~
 *  2011/04/04    1.12  H.Sasaki         [E_�{�ғ�_02252]�ސE�҃f�[�^�̏o�͐���
 *  2015/03/16    1.13  K.Nakamura       [E_�{�ғ�_12906]�݌Ɋm�蕶���̒ǉ�
 *  2016/04/15    1.14  K.Kiriu          [E_�{�ғ�_13586]�c�Ɛ��ѕ\�ɑO�N�̔���Ƒe������ǉ�
 *  2018/07/25    1.15  K.Kiriu          [E_�{�ғ�_15105]�Ƒԑ啪�ނ̕ύX�Ή�
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
  --  ===============================
  --  ���[�U�[��`��O
  --  ===============================
  --  *** �v���t�@�C���擾��O�n���h�� ***
  global_get_profile_expt       EXCEPTION;
  --  *** ���b�N�G���[��O�n���h�� ***
  global_data_lock_expt         EXCEPTION;
  --  *** �Ώۃf�[�^�����G���[��O�n���h�� ***
  global_no_data_warm_expt      EXCEPTION;
  --  *** �f�[�^�o�^�G���[��O�n���h�� ***
  global_insert_data_expt       EXCEPTION;
  --  *** �f�[�^�X�V�G���[��O�n���h�� ***
  global_update_data_expt       EXCEPTION;--
  --  *** �f�[�^�폜�G���[��O�n���h�� ***
  global_delete_data_expt       EXCEPTION;--
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�萔
  -- ===============================
--  �p�b�P�[�W��
  cv_pkg_name                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
--
  --�����[�֘A
  --  �R���J�����g��
  cv_conc_name                  CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
  --  ���[�h�c
  cv_file_id                    CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
  --  �g���q�i�o�c�e�j
  cv_extension_pdf              CONSTANT  VARCHAR2(100)                                   :=  '.pdf';
  --  �t�H�[���l���t�@�C����
  cv_frm_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A03S.xml';
  --  �N�G���[�l���t�@�C����
  cv_vrq_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A03S.vrq';
  --  �o�͋敪�i�o�c�e�j
  cv_output_mode_pdf            CONSTANT  VARCHAR2(1)                                     :=  '1';
--
  --���A�v���P�[�V�����Z�k��
  --  �̕��Z�k�A�v����
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOS';
-- == 2015/03/16 V1.13 Added START =================================================================
  --  �݌ɒZ�k�A�v����
  ct_xxcoi_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOI';
-- == 2015/03/16 V1.13 Added END   =================================================================
--
  --���̕����b�Z�[�W
  --  ���b�N�擾�G���[���b�Z�[�W
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00001';
  --  �v���t�@�C���擾�G���[
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00004';
  --  �f�[�^�o�^�G���[
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00010';
  --  �f�[�^�X�V�G���[
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00011';
  --  �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00012';
  --  API�ďo�G���[���b�Z�[�W
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00017';
  --  ����0���p���b�Z�[�W
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00018';
  --  �r�u�e�N���`�o�h
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00041';
  --  �v���h�c
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00042';
--
  --���@�\�ŗL���b�Z�[�W
  --  �p�����[�^�o��
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10560';
  --  �c�Ɛ��ѕ\���[���[�N�e�[�u��
  ct_msg_rpt_wrk_tbl            CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10587';
--
  --  �c�Ɛ��ѕ\ �c�ƈ��v��f�[�^�o�^����
  ct_msg_entry_sales_plan       CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10561';
  --  �c�Ɛ��ѕ\ �Ƒԕʔ�����яW�v����
  ct_msg_update_biz_conditions  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10562';
  --  �c�Ɛ��ѕ\ ����Q�� ������яW�v����
  ct_msg_update_policy_group    CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10563';
  --  �c�Ɛ��ѕ\ �V�K�v��������я��W�v����
  ct_msg_update_new_cust_sales  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10566';
  --  �c�Ɛ��ѕ\ �e��c�ƌ���
  ct_msg_update_results_of_biz  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10567';
  --  �c�Ɛ��ѕ\ �ۏW�v��񏈗�����
  ct_msg_insert_section_total   CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10568';
  --  �c�Ɛ��ѕ\ ���_�W�v��񏈗�����
  ct_msg_insert_base_total      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10569';
  --  �c�Ɛ��ѕ\ �o�͑ΏۊO���폜����
  ct_msg_delete_off_the_subject CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10570';
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  ct_msg_dummy_sales_group      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10573';
  --  �ۃR�[�h�K�{���̓G���[
  ct_msg_must_section_cd        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10583';
  --  �c�ƈ��K�{���̓G���[
  ct_msg_must_employee          CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10584';
  --  XXCOI:�݌ɑg�D�R�[�h
  ct_msg_organization_code      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10585';
  --  �ғ������擾�G���[
  ct_msg_operating_days         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10586';
-- == 2015/03/16 V1.13 Added START =================================================================
  --  ��v���Ԗ��擾�G���[���b�Z�[�W
  ct_msg_xxcoi1_10399           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOI1-10399';
-- == 2015/03/16 V1.13 Added END   =================================================================
/* 2016/04/15 Ver1.14 Add Start */
  --  �c�Ɛ��ѕ\ ����Q�� �O�N������яW�v����
  ct_msg_update_policy_group_py CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10596';
  --  �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_proc_date_err          CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00014';
/* 2016/04/15 Ver1.14 Add End   */
--
  --���v���t�@�C������
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  ct_prof_dummy_sales_group
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DUMMY_SALES_GROUP_CODE';
/* 2010/04/16 Ver1.9 Mod Start */
--  --  XXCOI:�݌ɑg�D�R�[�h
--  ct_prof_organization_code
--    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';
  --  XXCOS:�J�����_�R�[�h
  ct_prof_business_calendar_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
/* 2010/04/16 Ver1.9 Mod End   */
-- == 2015/03/16 V1.13 Added START =================================================================
  --  GL��v����ID
  ct_prof_gl_set_of_bks_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
  --  XXCOI:�݌Ɋm��󎚕���
  ct_prof_inv_cl_char
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_INV_CL_CHARACTER';
-- == 2015/03/16 V1.13 Added END   =================================================================
--
  --���N�C�b�N�R�[�h
  --  �N�C�b�N�R�[�h�i����Q�R�[�h�j
  ct_qct_s_group_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_BAND_CODE';
--
  --  �N�C�b�N�R�[�h�i���_ �ڔ���j
  ct_qct_base_suffix_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_BASE_SUFFIX';
  ct_qcc_base_suffix_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03';
--
  --  �N�C�b�N�R�[�h�i�� �ڔ���j
  ct_qct_section_suffix_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SECTION_SUFFIX';
  ct_qcc_section_suffix_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03';
--
--
  --��Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --���p�����[�^���t�w�菑��
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --���g�[�N��
  --  �e�[�u������
  cv_tkn_table                  CONSTANT  VARCHAR2(020) := 'TABLE';
  --  �������t
  cv_tkn_para_date              CONSTANT  VARCHAR2(020) := 'PARA_DATE';
  --  �v���t�@�C����
  cv_tkn_profile                CONSTANT  VARCHAR2(020) := 'PROFILE';
  --  �L�[���
  cv_tkn_key_data               CONSTANT  VARCHAR2(020) := 'KEY_DATA';
  --  �e�[�u������
  cv_tkn_table_name             CONSTANT  VARCHAR2(020) := 'TABLE_NAME';
  --  API����
  cv_tkn_api_name               CONSTANT  VARCHAR2(020) := 'API_NAME';
  --  �v���h�c
  cv_tkn_request                CONSTANT  VARCHAR2(020) := 'REQUEST';
  --  �p�����[�^���e
  cv_tkn_para_note              CONSTANT  VARCHAR2(020) := 'PARAM_NOTE';
  --  �o�͒P��
  cv_tkn_unit_of_output         CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  �[�i��
  cv_tkn_para_delivery_date     CONSTANT  VARCHAR2(020) := 'PARAM2';
  --  ���_
  cv_tkn_para_delivery_base_cd  CONSTANT  VARCHAR2(020) := 'PARAM3';
  --  ��
  cv_tkn_para_section_code      CONSTANT  VARCHAR2(020) := 'PARAM4';
  --  �c�ƈ�
  cv_tkn_para_employee_code     CONSTANT  VARCHAR2(020) := 'PARAM5';
  --  �o�^����
  cv_tkn_insert_count           CONSTANT  VARCHAR2(020) := 'INSERT_COUNT';
  --  �X�V����
  cv_tkn_update_count           CONSTANT  VARCHAR2(020) := 'UPDATE_COUNT';
  --  �폜����
  cv_tkn_delete_count           CONSTANT  VARCHAR2(020) := 'DELETE_COUNT';
-- == 2015/03/16 V1.13 Added START ==============================================================
  -- �Ώۓ�
  cv_tkn_date                   CONSTANT  VARCHAR2(20)  := 'DATE';
-- == 2015/03/16 V1.13 Added END   ==============================================================
--
  --���p�����[�^���ʗp
  --  �u0�F�c�ƈ��̂݁i�c�ƈ��X�j�v
  cv_para_unit_emplyee_only     CONSTANT  VARCHAR2(1) := '0';
  --  �u1�F�S�āi�e�c�ƈ��A�ۏW�v�A���_�W�v�j�v
  cv_para_unit_all              CONSTANT  VARCHAR2(1) := '1';
  --  �u2�F�ۏW�v�i�e�c�ƈ��A�ۏW�v�j�v
  cv_para_unit_section_sum      CONSTANT  VARCHAR2(1) := '2';
  --  �u3�F���_�W�v�i���_�W�v�̂݁j�v
  cv_para_unit_base_only        CONSTANT  VARCHAR2(1) := '3';
  --  �u4�F�ۏW�v�i�ۏW�v�̂݁j�v
  cv_para_unit_section_only     CONSTANT  VARCHAR2(1) := '4';
--
  --���p�����[�^�⊮�p
  --  �O���[�v�R�[�h(��)
  cv_para_dummy_section_code    CONSTANT  VARCHAR2(1) := '@';--
--
  --���W�v�f�[�^�敪
  --  �u0:�c�ƈ��v
  ct_sum_data_cls_employee      CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '0';
  --  �u1:�ہv
  ct_sum_data_cls_section       CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '1';
  --  �u2:���_�v
  ct_sum_data_cls_base          CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '2';
--
  --������v��J���敪
  --  �u1�F�ڕW����v��v
  ct_rel_div_target_plan        CONSTANT  xxcso_dept_monthly_plans.sales_plan_rel_div%TYPE := '1';
  --  �u2�F��{����v��v
  ct_rel_div_basic_plan         CONSTANT  xxcso_dept_monthly_plans.sales_plan_rel_div%TYPE := '2';
--
  --�����̔��U�֋敪
  --  �̔�����
  ct_sales_sum_sales            CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '0';
  --  ���ѐU��
  ct_sales_sum_transfer         CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '1';
--
  --���ڋq�敪
  --  ���_
  ct_cust_class_base            CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '1';
  --  �ڋq
  ct_cust_class_customer        CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '10';
--
  --���Ƒԑ啪��
  --  �ʔ̓X
  ct_biz_shop                   CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '01';
  --  �b�u�r
  ct_biz_cvs                    CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '02';
-- Ver1.15 Del Start
--  --  �≮
--  ct_biz_wholesale              CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '03';
-- Ver1.15 Del End
  --  ���̑�
  ct_biz_others                 CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '04';
  --  �u�c
  ct_biz_vd                     CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '05';
-- Ver1.15 Add Start
  -- �h���b�O�X�g�A
  ct_biz_drugstore              CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '06';
-- Ver1.15 Add End
--
  --���[�i�`�ԋ敪
  --  �c�Ǝ�
  ct_dlv_ptn_business_car       CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '1';
  --  �H�꒼��
  ct_dlv_ptn_factory_send       CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '2';
  --  ���C���q��
  ct_dlv_ptn_main_whse          CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '3';
  --  ���̑��q��
  ct_dlv_ptn_others_whse        CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '4';
  --  �����_�U��
  ct_dlv_ptn_others_base_whse   CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '5';
--
  --������Q�R�[�h�W�v���x��
  --  ����Q�R�[�h�W�v���x���iLV1 ��Q�j
  cv_band_dff2_lv1              CONSTANT  VARCHAR2(1) := '1';
  --  ����Q�R�[�h�W�v���x���iLV2 ���Q[�ꕔ���Q]�j
  cv_band_dff2_lv2              CONSTANT  VARCHAR2(1) := '2';
  --  ����Q�R�[�h�W�v���x���iLV3 �׌Q�j
  cv_band_dff2_lv3              CONSTANT  VARCHAR2(1) := '3';
--
  --�������敪
  --  �ڋq����
  ct_counter_cls_cuntomer       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '1';
  --  ���K�⌬��
  ct_counter_cls_no_visit       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '2';
  --  ���������
  ct_counter_cls_no_trade       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '3';
  --  ���K�⌏��
  ct_counter_cls_total_visit    CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '4';
  --  ���L������
  ct_counter_cls_total_valid    CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '5';
  --  ���L������
  ct_counter_cls_valid          CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '6';
  --  �V�K����
  ct_counter_cls_new_customer   CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '7';
  --  �V�K�����i�u�c�j
  ct_counter_cls_new_customervd CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '8';
  --  �V�K�|�C���g
  ct_counter_cls_new_point      CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '9';
  --  �l�b�K�⌏��
  ct_counter_cls_mc_visit       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '10';
  --  ���i�|�C���g
  ct_counter_cls_qualifi_point  CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '11';
/* 2010/04/16 Ver1.9 Add Start */
  --  ���_�v�ڋq����
  ct_counter_cls_base_code_cust CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '12';
/* 2010/04/16 Ver1.9 Add End   */
--
  --��limit
  --  ���_����
  cn_limit_base_name            CONSTANT  PLS_INTEGER := 40;
  --  �ۖ���(���O���[�v)
  cn_limit_sention_name         CONSTANT  PLS_INTEGER := 40;
  --  �c�ƈ�����
  cn_limit_employee_name        CONSTANT  PLS_INTEGER := 40;
  --  �ڋq����
  cn_limit_party_name           CONSTANT  PLS_INTEGER := 40;
--
-- == 2015/03/16 V1.13 Added START ==============================================================
  --  GL��v����
  cv_gl                         CONSTANT  VARCHAR2(5) := 'SQLGL';
  --  �N���[�Y
  cv_c                          CONSTANT  VARCHAR2(1) := 'C';
-- == 2015/03/16 V1.13 Added END   ==============================================================
/* 2016/04/15 Ver1.14 Add Start */
  --�� 1�N�O
  cn_previous_year              CONSTANT  PLS_INTEGER := 12;
/* 2016/04/15 Ver1.14 Add End   */
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�^
  --  ===============================
  --�����������J�E���g�p
  TYPE g_counter_rtype IS RECORD
    (
      --  �o�^����
      insert_entry_sales_plan             PLS_INTEGER := 0,
      --  �X�V����(�Ƒԕʔ������)
      update_business_conditions          PLS_INTEGER := 0,
      --  �X�V����(����Q�ʔ������)
      update_policy_group                 PLS_INTEGER := 0,
      --  �X�V����(�V�K�v���������)
      update_new_cust_sales_results       PLS_INTEGER := 0,
      --  �X�V����(�e��c�ƌ���)
      update_results_of_business          PLS_INTEGER := 0,
      --  �o�^����(�� �W�v���)
/* 2016/04/15 Ver1.14 Mod Start */
      --  �X�V����(����Q�ʔ�����ёO�N)
      update_policy_group_py              PLS_INTEGER := 0,
/* 2016/04/15 Ver1.14 Mod End   */
      insert_section_total                PLS_INTEGER := 0,
      --  �o�^����(���_ �W�v���)
      insert_base_total                   PLS_INTEGER := 0,
      --  �o�^����(���_ �W�v���)
      delete_off_the_subject_info         PLS_INTEGER := 0
    );
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�ϐ�
  --  ===============================
  --���J�E���^�[
  g_counter_rec                           g_counter_rtype;
  --���v���t�@�C���i�[�p
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  gt_prof_dummy_sales_group               fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/04/16 Ver1.9 Mod Start */
--  --  XXCOI:�݌ɑg�D�R�[�h
--  gt_prof_organization_code               fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:�J�����_�R�[�h
  gt_prof_business_calendar_code          fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/04/16 Ver1.9 Mod End   */
-- == 2015/03/16 V1.13 Added START =================================================================
  -- GL��v����ID
  gt_set_of_bks_id                        gl_sets_of_books.set_of_books_id%TYPE               DEFAULT NULL;
  --  XXCOI:�݌Ɋm��󎚕���
  gt_prof_inv_cl_char                     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;
-- == 2015/03/16 V1.13 Added END   =================================================================
--
  --�����ʃf�[�^�i�[�p
  --  ���ʃf�[�^�D���o���(date�^)
  gd_common_base_date                     DATE;
  --  ���ʃf�[�^�D���o�N���iyyyymm�j
  gv_common_base_years                    VARCHAR2(06);
  --  ���ʃf�[�^�D���o�N������(date�^)
  gd_common_first_date                    DATE;
  --  ���ʃf�[�^�D���o�N������(date�^)
  gd_common_last_date                     DATE;
  --  ���ʃf�[�^�D�ғ�����
  gn_common_operating_days                PLS_INTEGER;
  --  ���ʃf�[�^�D�o�ߓ���
  gn_common_lapsed_days                   PLS_INTEGER;
/* 2016/04/15 Ver1.14 Add Start */
  -- �Ɩ����t
  gd_process_date                         DATE;
/* 2016/04/15 Ver1.14 Add End   */
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�E�J�[�\��
  --  ===============================
  --  ���b�N�擾�p
  CURSOR  lock_cur
  IS
    SELECT  rbpe.ROWID
    FROM    xxcos_rep_bus_perf        rbpe
    WHERE   rbpe.request_id           = cn_request_id
    FOR UPDATE NOWAIT
    ;
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�^
  --  ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_date          IN      VARCHAR2,         --  2.�[�i��
    iv_delivery_base_code     IN      VARCHAR2,         --  3.���_
    iv_section_code           IN      VARCHAR2,         --  4.��
    iv_results_employee_code  IN      VARCHAR2,         --  5.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �L�[���
    lv_key_info                 VARCHAR2(5000);
    --�p�����[�^�o�͗p
    lv_para_msg                 VARCHAR2(5000);
    --
    lv_profile_name             VARCHAR2(5000);
-- == 2015/03/16 V1.13 Added START =================================================================
    -- ��v���ԃX�e�[�^�X
    lt_closing_status           gl_period_statuses.closing_status%TYPE              DEFAULT NULL;
-- == 2015/03/16 V1.13 Added END   =================================================================
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
    --==================================
    -- 1.���̓p�����[�^�o��
    --==================================
    lv_para_msg     :=  xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_unit_of_output,
      iv_token_value1  =>  iv_unit_of_output,
      iv_token_name2   =>  cv_tkn_para_delivery_date,
      iv_token_value2  =>  TO_CHAR(TO_DATE(iv_delivery_date, cv_fmt_date_default), cv_fmt_date_profile),
      iv_token_name3   =>  cv_tkn_para_delivery_base_cd,
      iv_token_value3  =>  iv_delivery_base_code,
      iv_token_name4   =>  cv_tkn_para_section_code,
      iv_token_value4  =>  iv_section_code,
      iv_token_name5   =>  cv_tkn_para_employee_code,
      iv_token_value5  =>  iv_results_employee_code
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --  1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.���̓p�����[�^�`�F�b�N
    --==================================
    --  �o�͒P�ʂ��u2�F�ۏW�v�i�e�c�ƈ��A�ۏW�v�j�v�A�u4�F�ۏW�v�i�ۏW�v�̂݁j�v�̎��A�ۂ̎w�肪�����ꍇ�̓G���[
    IF  ( iv_unit_of_output         IN (cv_para_unit_section_sum, cv_para_unit_section_only)
    AND   iv_section_code           IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_must_section_cd
        );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --  �o�͒P�ʂ��u0�F�c�ƈ��̂݁i�c�ƈ��X�j�v�̎��A�c�ƈ��̎w�肪�����ꍇ�̓G���[
    IF  ( iv_unit_of_output         =  cv_para_unit_emplyee_only
    AND   iv_results_employee_code  IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_must_employee
        );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 3.�v���t�@�C���l�擾
    --==================================
/* 2016/04/15 Ver1.14 Add Start */
    -- �Ɩ����t
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => ct_xxcos_appl_short_name
                    ,iv_name        => cv_msg_proc_date_err
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/* 2016/04/15 Ver1.14 Add End   */
    --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
    gt_prof_dummy_sales_group := FND_PROFILE.VALUE( ct_prof_dummy_sales_group );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_dummy_sales_group IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_dummy_sales_group
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_dummy_sales_group);
      RAISE global_get_profile_expt;
    END IF;
--
/* 2010/04/16 Ver1.9 Mod Start */
--    --  XXCOI:�݌ɑg�D�R�[�h
--    gt_prof_organization_code := FND_PROFILE.VALUE( ct_prof_organization_code );
----
--    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
--    IF ( gt_prof_organization_code IS NULL ) THEN
--      --�v���t�@�C����������擾
--      lv_profile_name := xxccp_common_pkg.get_msg(
--        iv_application        => ct_xxcos_appl_short_name,
--        iv_name               => ct_msg_organization_code
--        );
----
--      lv_profile_name :=  NVL(lv_profile_name, ct_prof_organization_code);
--      RAISE global_get_profile_expt;
--    END IF;
    --  XXCOS:�J�����_�R�[�h
    gt_prof_business_calendar_code := FND_PROFILE.VALUE( ct_prof_business_calendar_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_business_calendar_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_prof_business_calendar_code
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_business_calendar_code);
      RAISE global_get_profile_expt;
    END IF;
/* 2010/04/16 Ver1.9 Mod End   */
--
    --==================================
    -- 4.����t�擾
    --==================================
    gd_common_base_date   :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
    gv_common_base_years  :=  TO_CHAR(gd_common_base_date, cv_fmt_years);
    gd_common_first_date  :=  LAST_DAY(ADD_MONTHS(gd_common_base_date, -1)) + 1;
    gd_common_last_date   :=  LAST_DAY(gd_common_base_date);
--
    --  �ғ����A�o�ߓ����擾
    SELECT
            SUM(CASE 
                  WHEN  cal.seq_num IS NOT NULL
                  THEN  1
                  ELSE  0
                END)                    AS  operating_days,
            SUM(CASE 
                  WHEN  cal.seq_num IS NOT NULL
                  AND   cal.calendar_date <=  gd_common_base_date
                  THEN  1
                  ELSE  0
                END)                    AS  lapsed_days
    INTO    gn_common_operating_days,
            gn_common_lapsed_days
/* 2010/04/16 Ver1.9 Mod Start */
--    FROM    mtl_parameters      par,
--            bom_calendar_dates  cal
--    WHERE   par.organization_code   =       gt_prof_organization_code
--    AND     cal.calendar_code       =       par.calendar_code
    FROM    bom_calendar_dates  cal
    WHERE   cal.calendar_code       =       gt_prof_business_calendar_code
/* 2010/04/16 Ver1.9 Mod End   */
    AND     cal.calendar_date       BETWEEN gd_common_first_date
                                    AND     gd_common_last_date
    ;
--
    --  �����̉ғ��������[���̏ꍇ�͉ғ����J�����_�[�̎擾�Ɏ��s�����Ɣ��f
    --  SQL�̓s����i�W�v�֐��jno_data_found�͔������Ȃ�
    IF  ( NVL(gn_common_operating_days, 0) = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_operating_days
          );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
-- == 2015/03/16 V1.13 Added START =================================================================
    --========================================
    -- GL��v����ID�擾
    --========================================
    gt_set_of_bks_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
    --
    IF ( gt_set_of_bks_id IS NULL ) THEN
      lv_profile_name := ct_prof_gl_set_of_bks_id;
      RAISE global_get_profile_expt;
    END IF;
--
    --====================================
    -- ��v���ԃ`�F�b�N
    --====================================
    BEGIN
      SELECT gps.closing_status  AS closing_status
      INTO   lt_closing_status
      FROM   gl_period_statuses  gps
           , fnd_application     fa
      WHERE  gps.application_id          = fa.application_id
      AND    fa.application_short_name   = cv_gl
      AND    gps.set_of_books_id         = gt_set_of_bks_id
      AND    gps.adjustment_period_flag  = cv_no
      AND    gps.start_date             <= gd_common_base_date
      AND    gps.end_date               >= gd_common_base_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcoi_appl_short_name
                     , iv_name         => ct_msg_xxcoi1_10399
                     , iv_token_name1  => cv_tkn_date
                     , iv_token_value1 => TO_CHAR(gd_common_base_date, cv_fmt_date_profile)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
    --
    --====================================
    -- ���[�󎚕����擾
    -- ����v���ԃ`�F�b�N��GL�ł��邪�A�o�͂���l�̓v���t�@�C���F�݌Ɋm��󎚕����Ɠ���
    --====================================
    IF ( lt_closing_status = cv_c ) THEN
      gt_prof_inv_cl_char := FND_PROFILE.VALUE(ct_prof_inv_cl_char);
      --
      IF ( gt_prof_inv_cl_char IS NULL ) THEN
        lv_profile_name := ct_prof_inv_cl_char;
        RAISE global_get_profile_expt;
      END IF;
    END IF;
-- == 2015/03/16 V1.13 Added END   =================================================================
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_profile_name
      );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : entry_sales_plan
   * Description      : �c�ƈ��v��f�[�^���o���o�^(A-2)
   ***********************************************************************************/
  PROCEDURE entry_sales_plan(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_sales_plan'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�f�[�^�o�^  �i�c�ƈ��v��f�[�^�j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
-- == 2015/03/16 V1.13 Added START =================================================================
              gl_cl_char,
-- == 2015/03/16 V1.13 Added END   =================================================================
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
              sale_amount,
              business_cost,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
/* 2011/02/21 Ver1.11 Mod START */
--      SELECT
--/* 2009/09/03 Ver1.8 Add Start */
--              /*+
--                LEADING(rsid.jrrx_n)
--                INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
--                INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(rsid.jrrx_n xxcso_jrre_n02)
--                USE_NL(rsid.papf_n)
--                USE_NL(rsid.pept_n)
--                USE_NL(rsid.paaf_n)
--                USE_NL(rsid.jrgm_n)
--                USE_NL(rsid.jrgb_n)
--                LEADING(rsid.jrrx_o)
--                INDEX(rsid.jrrx_o xxcso_jrre_n02)
--                INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
--                INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(rsid.papf_o)
--                USE_NL(rsid.pept_o)
--                USE_NL(rsid.paaf_o)
--                USE_NL(rsid.jrgm_o)
--                USE_NL(rsid.jrgb_o)
--                USE_NL(rsid)
--                LEADING(rsig.jrrx_n)
--                INDEX(rsig.jrgm_n jtf_rs_group_members_n2)
--                INDEX(rsig.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(rsig.jrrx_n xxcso_jrre_n02)
--                USE_NL(rsig.papf_n)
--                USE_NL(rsig.pept_n)
--                USE_NL(rsig.paaf_n)
--                USE_NL(rsig.jrgm_n)
--                USE_NL(rsig.jrgb_n)
--                LEADING(rsig.jrrx_o)
--                INDEX(rsig.jrrx_o xxcso_jrre_n02)
--                INDEX(rsig.jrgm_o jtf_rs_group_members_n2)
--                INDEX(rsig.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(rsig.papf_o)
--                USE_NL(rsig.pept_o)
--                USE_NL(rsig.paaf_o)
--                USE_NL(rsig.jrgm_o)
--                USE_NL(rsig.jrgb_o)
--                USE_NL(rsig)
--                USE_NL(lvsg_lv2)
--              */
--/* 2009/09/03 Ver1.8 Add End   */
--              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
--              ct_sum_data_cls_employee                                              AS  sum_data_class,
--              gd_common_base_date                                                   AS  target_date,
--              rsid.base_code                                                        AS  base_code,
--              SUBSTRB(hzpb.party_name, 1, cn_limit_base_name)                       AS  base_name,
--              rsid.group_code                                                       AS  section_code,
--              SUBSTRB(rsig.employee_name || lvsc.meaning, 1, cn_limit_sention_name) AS  section_name,
--              rsid.group_in_sequence                                                AS  group_in_sequence,
--              rsid.employee_number                                                  AS  employee_num,
--              SUBSTRB(rsid.employee_name, 1, cn_limit_employee_name)                AS  employee_name,
--              NVL(DECODE(dmpl.sales_plan_rel_div, ct_rel_div_basic_plan, spmp.bsc_sls_prsn_total_amt
--                                                                       , spmp.tgt_sales_prsn_total_amt)
--                 , 0)                                                               AS  norma,
--              gn_common_operating_days                                              AS  actual_date_quantity,
--              gn_common_lapsed_days                                                 AS  course_date_quantity,
--              0                                                                     AS  sale_shop_date_total,
--              0                                                                     AS  sale_shop_total,
--              0                                                                     AS  rtn_shop_date_total,
--              0                                                                     AS  rtn_shop_total,
--              0                                                                     AS  discount_shop_date_total,
--              0                                                                     AS  discount_shop_total,
--              0                                                                     AS  sup_sam_shop_date_total,
--              0                                                                     AS  sup_sam_shop_total,
--              0                                                                     AS  keep_shop_quantity,
--              0                                                                     AS  sale_cvs_date_total,
--              0                                                                     AS  sale_cvs_total,
--              0                                                                     AS  rtn_cvs_date_total,
--              0                                                                     AS  rtn_cvs_total,
--              0                                                                     AS  discount_cvs_date_total,
--              0                                                                     AS  discount_cvs_total,
--              0                                                                     AS  sup_sam_cvs_date_total,
--              0                                                                     AS  sup_sam_cvs_total,
--              0                                                                     AS  keep_shop_cvs,
--              0                                                                     AS  sale_wholesale_date_total,
--              0                                                                     AS  sale_wholesale_total,
--              0                                                                     AS  rtn_wholesale_date_total,
--              0                                                                     AS  rtn_wholesale_total,
--              0                                                                     AS  discount_whol_date_total,
--              0                                                                     AS  discount_whol_total,
--              0                                                                     AS  sup_sam_whol_date_total,
--              0                                                                     AS  sup_sam_whol_total,
--              0                                                                     AS  keep_shop_wholesale,
--              0                                                                     AS  sale_others_date_total,
--              0                                                                     AS  sale_others_total,
--              0                                                                     AS  rtn_others_date_total,
--              0                                                                     AS  rtn_others_total,
--              0                                                                     AS  discount_others_date_total,
--              0                                                                     AS  discount_others_total,
--              0                                                                     AS  sup_sam_others_date_total,
--              0                                                                     AS  sup_sam_others_total,
--              0                                                                     AS  keep_shop_others,
--              0                                                                     AS  sale_vd_date_total,
--              0                                                                     AS  sale_vd_total,
--              0                                                                     AS  rtn_vd_date_total,
--              0                                                                     AS  rtn_vd_total,
--              0                                                                     AS  discount_vd_date_total,
--              0                                                                     AS  discount_vd_total,
--              0                                                                     AS  sup_sam_vd_date_total,
--              0                                                                     AS  sup_sam_vd_total,
--              0                                                                     AS  keep_shop_vd,
--              0                                                                     AS  sale_business_car,
--              0                                                                     AS  rtn_business_car,
--              0                                                                     AS  discount_business_car,
--              0                                                                     AS  sup_sam_business_car,
--              0                                                                     AS  drop_ship_fact_send_directly,
--              0                                                                     AS  rtn_factory_send_directly,
--              0                                                                     AS  discount_fact_send_directly,
--              0                                                                     AS  sup_fact_send_directly,
--              0                                                                     AS  sale_main_whse,
--              0                                                                     AS  rtn_main_whse,
--              0                                                                     AS  discount_main_whse,
--              0                                                                     AS  sup_sam_main_whse,
--              0                                                                     AS  sale_others_whse,
--              0                                                                     AS  rtn_others_whse,
--              0                                                                     AS  discount_others_whse,
--              0                                                                     AS  sup_sam_others_whse,
--              0                                                                     AS  sale_others_base_whse_sale,
--              0                                                                     AS  rtn_others_base_whse_sale,
--              0                                                                     AS  discount_oth_base_whse_sale,
--              0                                                                     AS  sup_sam_oth_base_whse_sale,
--              0                                                                     AS  sale_actual_transfer,
--              0                                                                     AS  rtn_actual_transfer,
--              0                                                                     AS  discount_actual_transfer,
--              0                                                                     AS  sup_sam_actual_transfer,
--              0                                                                     AS  sprcial_sale,
--              0                                                                     AS  rtn_asprcial_sale,
--              0                                                                     AS  sale_new_contribution_sale,
--              0                                                                     AS  rtn_new_contribution_sale,
--              0                                                                     AS  discount_new_contr_sale,
--              0                                                                     AS  sup_sam_new_contr_sale,
--              0                                                                     AS  count_yet_visit_party,
--              0                                                                     AS  count_yet_dealings_party,
--              0                                                                     AS  count_delay_visit_count,
--              0                                                                     AS  count_delay_valid_count,
--              0                                                                     AS  count_valid_count,
--              0                                                                     AS  count_new_count,
--              0                                                                     AS  count_new_vendor_count,
--              0                                                                     AS  count_new_point,
--              0                                                                     AS  count_mc_party,
--              lvsg_lv1.lookup_code                                                  AS  policy_sum_code,
--              lvsg_lv1.attribute3                                                   AS  policy_sum_name,
--              lvsg_lv2.lookup_code                                                  AS  policy_group,
--              lvsg_lv2.attribute3                                                   AS  group_name,
--              0                                                                     AS  sale_amount,
--              0                                                                     AS  business_cost,
--              cn_created_by                                                         AS  created_by,
--              cd_creation_date                                                      AS  creation_date,
--              cn_last_updated_by                                                    AS  last_updated_by,
--              cd_last_update_date                                                   AS  last_update_date,
--              cn_last_update_login                                                  AS  last_update_login,
--              cn_request_id                                                         AS  request_id,
--              cn_program_application_id                                             AS  program_application_id,
--              cn_program_id                                                         AS  program_id,
--              cd_program_update_date                                                AS  program_update_date
--      FROM    xxcos_rs_info_v               rsid,
--              xxcos_rs_info_v               rsig,
--              hz_cust_accounts              base,
--              hz_parties                    hzpb,
--              xxcso_dept_monthly_plans      dmpl,
--              xxcso_sls_prsn_mnthly_plns    spmp,
--              xxcos_lookup_values_v         lvsg_lv1,
--              xxcos_lookup_values_v         lvsg_lv2,
--              xxcos_lookup_values_v         lvsc
--      WHERE   rsid.base_code                =       iv_delivery_base_code
--      AND     NVL(rsid.group_code, cv_para_dummy_section_code)
--                                            =       NVL(iv_section_code, NVL(rsid.group_code, 
--                                                                             cv_para_dummy_section_code)
--                                                       )
--/* 2009/09/03 Ver1.8 Mod Start */
----      AND     rsid.employee_number          =       NVL(iv_results_employee_code, rsid.employee_number)
--      AND     (
--                ( iv_results_employee_code IS NULL )
--                OR
--                ( iv_results_employee_code IS NOT NULL AND rsid.employee_number = iv_results_employee_code )
--              )
--/* 2009/09/03 Ver1.8 Mod End   */
--      AND     rsid.effective_start_date     <=      gd_common_base_date
--      AND     rsid.effective_end_date       >=      gd_common_first_date
--      AND     gd_common_base_date           BETWEEN rsid.per_effective_start_date
--                                            AND     rsid.per_effective_end_date
--      AND     gd_common_base_date           BETWEEN rsid.paa_effective_start_date
--                                            AND     rsid.paa_effective_end_date
--      AND     rsig.base_code(+)             =       rsid.base_code
--      AND     rsig.group_code(+)            =       rsid.group_code
--      AND     rsig.group_chief_flag(+)      =       cv_yes
--      AND     gd_common_base_date           BETWEEN rsig.effective_start_date(+)
--                                            AND     rsig.effective_end_date(+)
--      AND     gd_common_base_date           BETWEEN rsig.per_effective_start_date(+)
--                                            AND     rsig.per_effective_end_date(+)
--      AND     gd_common_base_date           BETWEEN rsig.paa_effective_start_date(+)
--                                            AND     rsig.paa_effective_end_date(+)
--      AND     base.account_number           =       rsid.base_code
--      AND     base.customer_class_code      =       ct_cust_class_base
--      AND     hzpb.party_id                 =       base.party_id
--      AND     dmpl.base_code                =       iv_delivery_base_code
--      AND     dmpl.year_month               =       gv_common_base_years
--      AND     spmp.base_code(+)             =       rsid.base_code
--      AND     spmp.employee_number(+)       =       rsid.employee_number
--      AND     spmp.year_month(+)            =       gv_common_base_years
--      AND     lvsg_lv2.lookup_type          =       ct_qct_s_group_type
--      AND     lvsg_lv2.attribute2           =       cv_band_dff2_lv2
--      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv2.start_date_active, gd_common_base_date)
--                                            AND     NVL(lvsg_lv2.end_date_active,   gd_common_base_date)
--      AND     lvsg_lv1.lookup_type          =       ct_qct_s_group_type
--      AND     lvsg_lv1.lookup_code          =       lvsg_lv2.attribute1
--      AND     lvsg_lv1.attribute2           =       cv_band_dff2_lv1
--      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv1.start_date_active, gd_common_base_date)
--                                            AND     NVL(lvsg_lv1.end_date_active,   gd_common_base_date)
--      AND     lvsc.lookup_type              =       ct_qct_section_suffix_type
--      AND     lvsc.lookup_code              =       ct_qcc_section_suffix_code
--      AND     gd_common_base_date           BETWEEN NVL(lvsc.start_date_active, gd_common_base_date)
--                                            AND     NVL(lvsc.end_date_active,   gd_common_base_date)
--      ;
      SELECT  /*+ USE_NL(sub lvsg_lv2)
                  USE_NL(sub lvsc)
              */
              xxcos_rep_bus_perf_s01.NEXTVAL        AS  record_id                       --  ���R�[�hID
            , ct_sum_data_cls_employee              AS  sum_data_class                  --  �W�v�f�[�^�敪
            , gd_common_base_date                   AS  target_date                     --  ���t
            , sub.base_code                         AS  base_code                       --  ���_�R�[�h
            , sub.base_name                         AS  base_name                       --  ���_����
-- == 2015/03/16 V1.13 Added START =================================================================
            , gt_prof_inv_cl_char                   AS  gl_cl_char                      --  GL�m��󎚕���
-- == 2015/03/16 V1.13 Added END   =================================================================
            , sub.section_code                      AS  section_code                    --  �ۃR�[�h
            , SUBSTRB(sub.section_name || lvsc.meaning, 1, cn_limit_sention_name)
                                                    AS  section_name                    --  �ۖ���
            , sub.group_in_sequence                 AS  group_in_sequence               --  �O���[�v������
            , sub.employee_num                      AS  employee_num                    --  �c�ƈ��R�[�h
            , sub.employee_name                     AS  employee_name                   --  �c�ƈ�����
            , sub.norma                             AS  norma                           --  �����m���}
            , gn_common_operating_days              AS  actual_date_quantity            --  ��������
            , gn_common_lapsed_days                 AS  course_date_quantity            --  �o�ߓ���
            , 0                                     AS  sale_shop_date_total            --  ������ʔ̓X���v
            , 0                                     AS  sale_shop_total                 --  ������ʔ̓X�݌v
            , 0                                     AS  rtn_shop_date_total             --  �ԕi�ʔ̓X���v
            , 0                                     AS  rtn_shop_total                  --  �ԕi�ʔ̓X�݌v
            , 0                                     AS  discount_shop_date_total        --  �l���ʔ̓X���v
            , 0                                     AS  discount_shop_total             --  �l���ʔ̓X�݌v
            , 0                                     AS  sup_sam_shop_date_total         --  ���^���{�ʔ̓X���v
            , 0                                     AS  sup_sam_shop_total              --  ���^���{�ʔ̓X�݌v
            , 0                                     AS  keep_shop_quantity              --  �������ʔ̓X
            , 0                                     AS  sale_cvs_date_total             --  ������CVS���v
            , 0                                     AS  sale_cvs_total                  --  ������CVS�݌v
            , 0                                     AS  rtn_cvs_date_total              --  �ԕiCVS���v
            , 0                                     AS  rtn_cvs_total                   --  �ԕiCVS�݌v
            , 0                                     AS  discount_cvs_date_total         --  �l��CVS���v
            , 0                                     AS  discount_cvs_total              --  �l��CVS�݌v
            , 0                                     AS  sup_sam_cvs_date_total          --  ���^���{CVS���v
            , 0                                     AS  sup_sam_cvs_total               --  ���^���{CVS�݌v
            , 0                                     AS  keep_shop_cvs                   --  ������CVS
            , 0                                     AS  sale_wholesale_date_total       --  ������h���b�O�X�g�A���v
            , 0                                     AS  sale_wholesale_total            --  ������h���b�O�X�g�A�݌v
            , 0                                     AS  rtn_wholesale_date_total        --  �ԕi�h���b�O�X�g�A���v
            , 0                                     AS  rtn_wholesale_total             --  �ԕi�h���b�O�X�g�A�݌v
            , 0                                     AS  discount_whol_date_total        --  �l���h���b�O�X�g�A���v
            , 0                                     AS  discount_whol_total             --  �l���h���b�O�X�g�A�݌v
            , 0                                     AS  sup_sam_whol_date_total         --  ���^���{�h���b�O�X�g�A���v
            , 0                                     AS  sup_sam_whol_total              --  ���^���{�h���b�O�X�g�A�݌v
            , 0                                     AS  keep_shop_wholesale             --  �������h���b�O�X�g�A
            , 0                                     AS  sale_others_date_total          --  �����セ�̑����v
            , 0                                     AS  sale_others_total               --  �����セ�̑��݌v
            , 0                                     AS  rtn_others_date_total           --  �ԕi���̑����v
            , 0                                     AS  rtn_others_total                --  �ԕi���̑��݌v
            , 0                                     AS  discount_others_date_total      --  �l�����̑����v
            , 0                                     AS  discount_others_total           --  �l�����̑��݌v
            , 0                                     AS  sup_sam_others_date_total       --  ���^���{���̑����v
            , 0                                     AS  sup_sam_others_total            --  ���^���{���̑��݌v
            , 0                                     AS  keep_shop_others                --  ���������̑�
            , 0                                     AS  sale_vd_date_total              --  ������VD���v
            , 0                                     AS  sale_vd_total                   --  ������VD�݌v
            , 0                                     AS  rtn_vd_date_total               --  �ԕiVD���v
            , 0                                     AS  rtn_vd_total                    --  �ԕiVD�݌v
            , 0                                     AS  discount_vd_date_total          --  �l��VD���v
            , 0                                     AS  discount_vd_total               --  �l��VD�݌v
            , 0                                     AS  sup_sam_vd_date_total           --  ���^���{VD���v
            , 0                                     AS  sup_sam_vd_total                --  ���^���{VD�݌v
            , 0                                     AS  keep_shop_vd                    --  ������VD
            , 0                                     AS  sale_business_car               --  ������c�Ǝ�
            , 0                                     AS  rtn_business_car                --  �ԕi�c�Ǝ�
            , 0                                     AS  discount_business_car           --  �l���c�Ǝ�
            , 0                                     AS  sup_sam_business_car            --  ���^���{�c�Ǝ�
            , 0                                     AS  drop_ship_fact_send_directly    --  ������H�꒼��
            , 0                                     AS  rtn_factory_send_directly       --  �ԕi�H�꒼��
            , 0                                     AS  discount_fact_send_directly     --  �l���H�꒼��
            , 0                                     AS  sup_fact_send_directly          --  ���^���{�H�꒼��
            , 0                                     AS  sale_main_whse                  --  �����チ�C���q��
            , 0                                     AS  rtn_main_whse                   --  �ԕi���C���q��
            , 0                                     AS  discount_main_whse              --  �l�����C���q��
            , 0                                     AS  sup_sam_main_whse               --  ���^���{���C���q��
            , 0                                     AS  sale_others_whse                --  �����セ�̑��q��
            , 0                                     AS  rtn_others_whse                 --  �ԕi���̑��q��
            , 0                                     AS  discount_others_whse            --  �l�����̑��q��
            , 0                                     AS  sup_sam_others_whse             --  ���^���{���̑��q��
            , 0                                     AS  sale_others_base_whse_sale      --  �����㑼���_�q�ɔ���
            , 0                                     AS  rtn_others_base_whse_sale       --  �ԕi�����_�q�ɔ���
            , 0                                     AS  discount_oth_base_whse_sale     --  �l�������_�q�ɔ���
            , 0                                     AS  sup_sam_oth_base_whse_sale      --  ���^���{�����_�q�ɔ���
            , 0                                     AS  sale_actual_transfer            --  ��������ѐU��
            , 0                                     AS  rtn_actual_transfer             --  �ԕi���ѐU��
            , 0                                     AS  discount_actual_transfer        --  �l�����ѐU��
            , 0                                     AS  sup_sam_actual_transfer         --  ���^���{���ѐU��
            , 0                                     AS  sprcial_sale                    --  �������������
            , 0                                     AS  rtn_asprcial_sale               --  �ԕi��������
            , 0                                     AS  sale_new_contribution_sale      --  ������V�K�v������
            , 0                                     AS  rtn_new_contribution_sale       --  �ԕi�V�K�v������
            , 0                                     AS  discount_new_contr_sale         --  �l���V�K�v������
            , 0                                     AS  sup_sam_new_contr_sale          --  ���^���{�V�K�v������
            , 0                                     AS  count_yet_visit_party           --  �������K��q
            , 0                                     AS  count_yet_dealings_party        --  ����������q
            , 0                                     AS  count_delay_visit_count         --  �������K�⌏��
            , 0                                     AS  count_delay_valid_count         --  �������L������
            , 0                                     AS  count_valid_count               --  �������L������
            , 0                                     AS  count_new_count                 --  �����V�K����
            , 0                                     AS  count_new_vendor_count          --  �����V�K�x���_�[����
            , 0                                     AS  count_new_point                 --  �����V�K�|�C���g
            , 0                                     AS  count_mc_party                  --  ����MC�K��
            , lvsg_lv1.lookup_code                  AS  policy_sum_code                 --  ����Q�W��R�[�h
            , lvsg_lv1.attribute3                   AS  policy_sum_name                 --  ����Q�W�񖼏�
            , lvsg_lv2.lookup_code                  AS  policy_group                    --  ����Q�R�[�h
            , lvsg_lv2.attribute3                   AS  group_name                      --  ����Q����
            , 0                                     AS  sale_amount                     --  ������z
            , 0                                     AS  business_cost                   --  �c�ƌ���
            , cn_created_by                         AS  created_by                      --  �쐬��
            , cd_creation_date                      AS  creation_date                   --  �쐬��
            , cn_last_updated_by                    AS  last_updated_by                 --  �ŏI�X�V��
            , cd_last_update_date                   AS  last_update_date                --  �ŏI�X�V��
            , cn_last_update_login                  AS  last_update_login               --  �ŏI�X�V���O�C��
            , cn_request_id                         AS  request_id                      --  �v��ID
            , cn_program_application_id             AS  program_application_id          --  �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , cn_program_id                         AS  program_id                      --  �R���J�����g�E�v���O����ID
            , cd_program_update_date                AS  program_update_date             --  �v���O�����X�V��
      FROM    (
                SELECT
                        /*+
                          LEADING(rsid.jrrx_n)
                          INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
                          INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
                          INDEX(rsid.jrrx_n xxcso_jrre_n02)
                          USE_NL(rsid.papf_n)
                          USE_NL(rsid.pept_n)
                          USE_NL(rsid.paaf_n)
                          USE_NL(rsid.jrgm_n)
                          USE_NL(rsid.jrgb_n)
                          LEADING(rsid.jrrx_o)
                          INDEX(rsid.jrrx_o xxcso_jrre_n02)
                          INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
                          INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
                          USE_NL(rsid.papf_o)
                          USE_NL(rsid.pept_o)
                          USE_NL(rsid.paaf_o)
                          USE_NL(rsid.jrgm_o)
                          USE_NL(rsid.jrgb_o)
                          USE_NL(rsid)
                          LEADING(rsig.jrrx_n)
                          INDEX(rsig.jrgm_n jtf_rs_group_members_n2)
                          INDEX(rsig.jrgb_n jtf_rs_groups_b_u1)
                          INDEX(rsig.jrrx_n xxcso_jrre_n02)
                          USE_NL(rsig.papf_n)
                          USE_NL(rsig.pept_n)
                          USE_NL(rsig.paaf_n)
                          USE_NL(rsig.jrgm_n)
                          USE_NL(rsig.jrgb_n)
                          LEADING(rsig.jrrx_o)
                          INDEX(rsig.jrrx_o xxcso_jrre_n02)
                          INDEX(rsig.jrgm_o jtf_rs_group_members_n2)
                          INDEX(rsig.jrgb_o jtf_rs_groups_b_u1)
                          USE_NL(rsig.papf_o)
                          USE_NL(rsig.pept_o)
                          USE_NL(rsig.paaf_o)
                          USE_NL(rsig.jrgm_o)
                          USE_NL(rsig.jrgb_o)
                          USE_NL(rsig)
                        */
                        DISTINCT
                        rsid.base_code                                                        AS  base_code
                      , SUBSTRB(hzpb.party_name, 1, cn_limit_base_name)                       AS  base_name
                      , rsid.group_code                                                       AS  section_code
                      , rsig.employee_name                                                    AS  section_name
                      , NVL(
                          DECODE(dmpl.sales_plan_rel_div, ct_rel_div_basic_plan, spmp.bsc_sls_prsn_total_amt
                                                                               , spmp.tgt_sales_prsn_total_amt
                          ), 0
                        )                                                                     AS  norma
                      , rsid.group_in_sequence                                                AS  group_in_sequence
                      , rsid.employee_number                                                  AS  employee_num
                      , SUBSTRB(rsid.employee_name, 1, cn_limit_employee_name)                AS  employee_name
                FROM    xxcos_rs_info_v                   rsid                      --  �c�ƈ����VIEW
                      , xxcos_rs_info_v                   rsig                      --  �O���[�v�}�X�^
                      , hz_cust_accounts                  base                      --  �ڋq�}�X�^
                      , hz_parties                        hzpb                      --  �p�[�e�B�}�X�^
                      , xxcso_sls_prsn_mnthly_plns        spmp                      --  �c�ƈ��v��
                      , xxcso_dept_monthly_plans          dmpl                      --  ����v��J���敪
                WHERE   rsid.base_code                =       iv_delivery_base_code
                AND     NVL(rsid.group_code, cv_para_dummy_section_code)
                                                      =       NVL(iv_section_code, NVL(rsid.group_code, cv_para_dummy_section_code))
                AND     (
                          ( iv_results_employee_code IS NULL )
                          OR
                          ( iv_results_employee_code IS NOT NULL AND rsid.employee_number = iv_results_employee_code )
                        )
                AND     rsid.effective_start_date     <=      gd_common_base_date
                AND     rsid.effective_end_date       >=      gd_common_first_date
/* 2011/04/04 Ver.1.12 Mod START */
--                AND     gd_common_base_date           BETWEEN rsid.per_effective_start_date
--                                                      AND     rsid.per_effective_end_date
--                AND     gd_common_base_date           BETWEEN rsid.paa_effective_start_date
--                                                      AND     rsid.paa_effective_end_date
                AND     gd_common_base_date           >=      TO_DATE(TO_CHAR(rsid.per_effective_start_date, cv_fmt_years) || '01', cv_fmt_date)
                AND     gd_common_base_date           <=      TRUNC(LAST_DAY(rsid.per_effective_end_date))
                AND     gd_common_base_date           >=      TO_DATE(TO_CHAR(rsid.paa_effective_start_date, cv_fmt_years) || '01', cv_fmt_date)
                AND     gd_common_base_date           <=      TRUNC(LAST_DAY(rsid.paa_effective_end_date))
/* 2011/04/04 Ver.1.12 Mod END   */
                AND     rsig.base_code(+)             =       rsid.base_code
                AND     rsig.group_code(+)            =       rsid.group_code
                AND     rsig.group_chief_flag(+)      =       cv_yes
                AND     gd_common_base_date           BETWEEN rsig.effective_start_date(+)
                                                      AND     rsig.effective_end_date(+)
                AND     gd_common_base_date           BETWEEN rsig.per_effective_start_date(+)
                                                      AND     rsig.per_effective_end_date(+)
                AND     gd_common_base_date           BETWEEN rsig.paa_effective_start_date(+)
                                                      AND     rsig.paa_effective_end_date(+)
                AND     base.account_number           =       rsid.base_code
                AND     base.customer_class_code      =       ct_cust_class_base
                AND     hzpb.party_id                 =       base.party_id
                AND     spmp.base_code(+)             =       rsid.base_code
                AND     spmp.employee_number(+)       =       rsid.employee_number
                AND     spmp.year_month(+)            =       gv_common_base_years
                AND     dmpl.base_code                =       iv_delivery_base_code
                AND     dmpl.year_month               =       gv_common_base_years
              )   sub
            , xxcos_lookup_values_v         lvsc
            , xxcos_lookup_values_v         lvsg_lv1
            , xxcos_lookup_values_v         lvsg_lv2
      WHERE   lvsc.lookup_type              =       ct_qct_section_suffix_type
      AND     lvsc.lookup_code              =       ct_qcc_section_suffix_code
      AND     gd_common_base_date           BETWEEN NVL(lvsc.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsc.end_date_active,   gd_common_base_date)
      AND     lvsg_lv2.lookup_type          =       ct_qct_s_group_type
      AND     lvsg_lv2.attribute2           =       cv_band_dff2_lv2
      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv2.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsg_lv2.end_date_active,   gd_common_base_date)
      AND     lvsg_lv1.lookup_type          =       ct_qct_s_group_type
      AND     lvsg_lv1.lookup_code          =       lvsg_lv2.attribute1
      AND     lvsg_lv1.attribute2           =       cv_band_dff2_lv1
      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv1.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsg_lv1.end_date_active,   gd_common_base_date)
      ;
/* 2011/02/21 Ver1.11 Mod END   */
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  �o�^�����J�E���g
    g_counter_rec.insert_entry_sales_plan := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END entry_sales_plan;
--
  /**********************************************************************************
   * Procedure Name   : update_business_conditions
   * Description      : �Ƒԕʔ������ �W�v�����A���f����(A-3,A-4)
   *                    �[�i�`�ԕʔ̔����я��W�v�����f����(A-7)
   *                    ���ѐU�֏��W�v�����f����(A-8)
   ***********************************************************************************/
  PROCEDURE update_business_conditions(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_business_conditions'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�f�[�^�X�V  �i�Ƒԕʔ�����сA�[�i�`�ԕʔ̔����сA���ѐU�֏��j
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- discount store
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              -- cvs
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              -- wholesale store
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              -- others store
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              -- vendor
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              -- business car
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              -- factory send directly
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              -- main whse
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              -- others whse
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              -- others base whse sale
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              -- transfer sales
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              -- sprcial sales
              sprcial_sale,
              rtn_asprcial_sale,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- discount store
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_shop_total,
              -- cvs
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_cvs_total,
              -- wholesale store -> drug stoer
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_wholesale_date_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_wholesale_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_wholesale_date_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_wholesale_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_whol_date_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_whol_total,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Mod End
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_whol_date_total,
                      SUM(CASE
-- Ver1.15 Add Start
--                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            WHEN  xbco.d_lookup_code          = ct_biz_drugstore
-- Ver1.15 Add End
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_whol_total,
              -- others store
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_total,
              -- vendor
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_vd_total,
              -- business car
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_business_car,
              -- factory send directly
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  drop_ship_fact_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_factory_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_fact_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_fact_send_directly,
              -- main whse
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_main_whse,
              -- others whse
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_whse,
              -- others base whse sale
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_oth_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_oth_base_whse_sale,
              -- transfer sales
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_actual_transfer,
              -- sprcial sales
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sprcial_sale_amount
                            ELSE  0
                          END)                                                      AS  sprcial_sale,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sprcial_rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_asprcial_sale,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_sales_sum       rbss,
                      xxcos_business_conditions_v   xbco
              WHERE   rbss.sale_base_code         =       xrbp.base_code
              AND     rbss.results_employee_code  =       xrbp.employee_num
              AND     rbss.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              AND     xbco.s_lookup_code          =       rbss.cust_gyotai_sho
              AND     gd_common_base_date         BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     gd_common_base_date         BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     gd_common_base_date         BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  �X�V�����J�E���g
    g_counter_rec.update_business_conditions := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_business_conditions;
--
  /**********************************************************************************
   * Procedure Name   : update_policy_group
   * Description      : ����Q�� ������� �W�v�A���f����(A-5,A-6)
   ***********************************************************************************/
  PROCEDURE update_policy_group(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_policy_group'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�f�[�^�X�V  �i����Q�� ������сj
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- policy group
              sale_amount,
              business_cost,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- policy group
                      NVL(SUM(rbgs.sale_amount), 0)                                 AS  sale_amount,
                      NVL(SUM(rbgs.business_cost), 0)                               AS  business_cost,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_s_group_sum     rbgs,
                      xxcos_lookup_values_v         lvsg_lv3
              WHERE   lvsg_lv3.lookup_type        =       ct_qct_s_group_type
              AND     lvsg_lv3.attribute2         =       cv_band_dff2_lv3
              AND     lvsg_lv3.attribute1         =       xrbp.policy_group
              AND     gd_common_base_date         BETWEEN NVL(lvsg_lv3.start_date_active, gd_common_base_date)
                                                  AND     NVL(lvsg_lv3.end_date_active,   gd_common_base_date)
              AND     rbgs.sale_base_code         =       xrbp.base_code
              AND     rbgs.results_employee_code  =       xrbp.employee_num
              AND     rbgs.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              AND     rbgs.policy_group_code      =       lvsg_lv3.lookup_code
                      )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  �X�V�����J�E���g
    g_counter_rec.update_policy_group := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_policy_group;
--
  /**********************************************************************************
   * Procedure Name   : update_new_cust_sales_results
   * Description      : �V�K�v��������я��W�v�����f����(A-9)
   ***********************************************************************************/
  PROCEDURE update_new_cust_sales_results(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_new_cust_sales_results'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�f�[�^�X�V  �i�V�K�v������j
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- new customer sales results
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- new customer sales results
                      SUM(rbns.sale_amount)                                         AS  sale_new_contribution_sale,
                      SUM(rbns.rtn_amount)                                          AS  rtn_new_contribution_sale,
                      SUM(rbns.discount_amount)                                     AS  discount_new_contr_sale,
                      SUM(rbns.sup_sam_cost)                                        AS  sup_sam_new_contr_sale,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_newcust_sum   rbns
              WHERE   rbns.sale_base_code         =       xrbp.base_code
              AND     rbns.results_employee_code  =       xrbp.employee_num
              AND     rbns.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  �X�V�����J�E���g
    g_counter_rec.update_new_cust_sales_results := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_new_cust_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : update_results_of_business
   * Description      : �e�팏���擾�����f����(A-10)
   ***********************************************************************************/
  PROCEDURE update_results_of_business(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_results_of_business'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�f�[�^�X�V  �i�e��c�ƌ����j
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- customer counter
              keep_shop_quantity,
              keep_shop_cvs,
              keep_shop_wholesale,
              keep_shop_others,
              keep_shop_vd,
              -- results of business
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- new customer sales results
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_shop
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_quantity,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_cvs
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_cvs,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
-- Ver1.15 Mod Start
--                            AND   rbcs.business_low_type      = ct_biz_wholesale
                            AND   rbcs.business_low_type      = ct_biz_drugstore
-- Ver1.15 Mod End
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_wholesale,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_others
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_others,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_vd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_vd,
              -- results of business
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_no_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_yet_visit_party,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_no_trade
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_yet_dealings_party,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_total_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_delay_visit_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_total_valid
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_delay_valid_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_valid
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_valid_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_customer
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_customervd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_vendor_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_point
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_point,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_mc_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_mc_party,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_count_sum     rbcs
              WHERE   rbcs.base_code              =       xrbp.base_code
              AND     rbcs.employee_num           =       xrbp.employee_num
              AND     rbcs.target_date            =       gv_common_base_years
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  �X�V�����J�E���g
    g_counter_rec.update_results_of_business := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_results_of_business;
--
/* 2016/04/15 Ver1.14 Add Start */
  /**********************************************************************************
   * Procedure Name   : update_policy_group_py
   * Description      : ����Q�� �O�N������� �W�v�A���f����(A-17,A-18)
   ***********************************************************************************/
  PROCEDURE update_policy_group_py(
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_policy_group_py'; -- �v���O������
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
    lv_previous_year_month   VARCHAR2(6);                      -- �p�����[�^�[�i���̑O�N����
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
    -- �p�����[�^�[�i���̑O�N�������擾
    lv_previous_year_month :=  TO_CHAR( ADD_MONTHS(gd_common_base_date, - cn_previous_year), cv_fmt_years);
--
    --==================================
    -- 2.�f�[�^�X�V  �i����Q�� �O�N������сj
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- previous year policy group
              prev_year_sale_amount,
              prev_year_business_cost,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT /*+
                       LEADING( xcrv.fa xcrv.efdfce lvsg_lv3 xcrv.hopeb xcrv.hop xcrv.hp xcrv.hca  rbsgsp )
                       USE_NL( xcrv.fa xcrv.efdfce lvsg_lv3 xcrv.hopeb xcrv.hop xcrv.hp xcrv.hca  rbsgsp )
                       INDEX( rbsgsp xxcos_rep_bus_s_sum_py_n02 )
                     */
                     SUM(rbsgsp.sale_amount)    AS  sale_amount
                    ,SUM(rbsgsp.business_cost)  AS  business_cost
                    ,cn_last_updated_by         AS  last_updated_by
                    ,cd_last_update_date        AS  last_update_date
                    ,cn_last_update_login       AS  last_update_login
                    ,cn_request_id              AS  request_id
                    ,cn_program_application_id  AS  program_application_id
                    ,cn_program_id              AS  program_id
                    ,cd_program_update_date     AS  program_update_date
              FROM   xxcso_cust_resources_v       xcrv
                    ,xxcos_rep_bus_s_group_sum_py rbsgsp
                    ,xxcos_lookup_values_v        lvsg_lv3
              WHERE  lvsg_lv3.lookup_type        =       ct_qct_s_group_type
              AND    lvsg_lv3.attribute2         =       cv_band_dff2_lv3
              AND    lvsg_lv3.attribute1         =       xrbp.policy_group
              AND    gd_process_date             BETWEEN NVL(lvsg_lv3.start_date_active, gd_process_date)
                                                 AND     NVL(lvsg_lv3.end_date_active,   gd_process_date)
              AND    xcrv.employee_number        =       xrbp.employee_num
              AND    gd_process_date             BETWEEN xcrv.start_date_active
                                                 AND     NVL(xcrv.end_date_active, gd_process_date)
              AND    xcrv.account_number         =       rbsgsp.customer_code
              AND    rbsgsp.dlv_month            =       lv_previous_year_month  -- �p�����[�^�[�i���̑O�N����
              AND    rbsgsp.work_days           <=       gn_common_lapsed_days   -- �p�����[�^�[�i���̌o�ߓ���
              AND    rbsgsp.policy_group_code    =       lvsg_lv3.lookup_code
              )
      WHERE   xrbp.request_id                    = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        -- ���b�Z�[�W����
        ov_errmsg    := SUBSTRB( xxccp_common_pkg.get_msg(
                                  iv_application => ct_xxcos_appl_short_name,
                                  iv_name        => ct_msg_update_data_err,
                                  iv_token_name1 => cv_tkn_table_name,
                                  iv_token_value1=> ct_msg_rpt_wrk_tbl,
                                  iv_token_name2 => cv_tkn_key_data,
                                  iv_token_value2=> lv_errbuf
                               ), 1, 5000);
        --  �㑱�f�[�^�� �����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        RAISE global_update_data_expt;
    END;
--
    --  �X�V�����J�E���g
    g_counter_rec.update_policy_group_py := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END update_policy_group_py;

/* 2016/04/15 Ver1.14 Add End   */
  /**********************************************************************************
   * Procedure Name   : insert_section_total
   * Description      : �ۏW�v��񐶐�(A-11)
   ***********************************************************************************/
  PROCEDURE insert_section_total(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_section_total'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.�������s����
    --==================================
    IF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_section_sum, cv_para_unit_section_only ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.�f�[�^�o�^  �i�ۏW�v���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
-- == 2015/03/16 V1.13 Added START =================================================================
              gl_cl_char,
-- == 2015/03/16 V1.13 Added END   =================================================================
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
              sale_amount,
              business_cost,
/* 2016/04/15 Ver1.14 Add Start */
              prev_year_sale_amount,
              prev_year_business_cost,
/* 2016/04/15 Ver1.14 Add End   */
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
              ct_sum_data_cls_section                                               AS  sum_data_class,
              gd_common_base_date                                                   AS  target_date,
              work.base_code                                                        AS  base_code,
              work.base_name                                                        AS  base_name,
-- == 2015/03/16 V1.13 Added START =================================================================
              gt_prof_inv_cl_char                                                   AS  gl_cl_char,
-- == 2015/03/16 V1.13 Added END   =================================================================
              work.section_code                                                     AS  section_code,
              work.section_name                                                     AS  section_name,
              work.group_in_sequence                                                AS  group_in_sequence,
              work.employee_num                                                     AS  employee_num,
              work.employee_name                                                    AS  employee_name,
              work.norma                                                            AS  norma,
              gn_common_operating_days                                              AS  actual_date_quantity,
              gn_common_lapsed_days                                                 AS  course_date_quantity,
              work.sale_shop_date_total                                             AS  sale_shop_date_total,
              work.sale_shop_total                                                  AS  sale_shop_total,
              work.rtn_shop_date_total                                              AS  rtn_shop_date_total,
              work.rtn_shop_total                                                   AS  rtn_shop_total,
              work.discount_shop_date_total                                         AS  discount_shop_date_total,
              work.discount_shop_total                                              AS  discount_shop_total,
              work.sup_sam_shop_date_total                                          AS  sup_sam_shop_date_total,
              work.sup_sam_shop_total                                               AS  sup_sam_shop_total,
              work.keep_shop_quantity                                               AS  keep_shop_quantity,
              work.sale_cvs_date_total                                              AS  sale_cvs_date_total,
              work.sale_cvs_total                                                   AS  sale_cvs_total,
              work.rtn_cvs_date_total                                               AS  rtn_cvs_date_total,
              work.rtn_cvs_total                                                    AS  rtn_cvs_total,
              work.discount_cvs_date_total                                          AS  discount_cvs_date_total,
              work.discount_cvs_total                                               AS  discount_cvs_total,
              work.sup_sam_cvs_date_total                                           AS  sup_sam_cvs_date_total,
              work.sup_sam_cvs_total                                                AS  sup_sam_cvs_total,
              work.keep_shop_cvs                                                    AS  keep_shop_cvs,
              work.sale_wholesale_date_total                                        AS  sale_wholesale_date_total,
              work.sale_wholesale_total                                             AS  sale_wholesale_total,
              work.rtn_wholesale_date_total                                         AS  rtn_wholesale_date_total,
              work.rtn_wholesale_total                                              AS  rtn_wholesale_total,
              work.discount_whol_date_total                                         AS  discount_whol_date_total,
              work.discount_whol_total                                              AS  discount_whol_total,
              work.sup_sam_whol_date_total                                          AS  sup_sam_whol_date_total,
              work.sup_sam_whol_total                                               AS  sup_sam_whol_total,
              work.keep_shop_wholesale                                              AS  keep_shop_wholesale,
              work.sale_others_date_total                                           AS  sale_others_date_total,
              work.sale_others_total                                                AS  sale_others_total,
              work.rtn_others_date_total                                            AS  rtn_others_date_total,
              work.rtn_others_total                                                 AS  rtn_others_total,
              work.discount_others_date_total                                       AS  discount_others_date_total,
              work.discount_others_total                                            AS  discount_others_total,
              work.sup_sam_others_date_total                                        AS  sup_sam_others_date_total,
              work.sup_sam_others_total                                             AS  sup_sam_others_total,
              work.keep_shop_others                                                 AS  keep_shop_others,
              work.sale_vd_date_total                                               AS  sale_vd_date_total,
              work.sale_vd_total                                                    AS  sale_vd_total,
              work.rtn_vd_date_total                                                AS  rtn_vd_date_total,
              work.rtn_vd_total                                                     AS  rtn_vd_total,
              work.discount_vd_date_total                                           AS  discount_vd_date_total,
              work.discount_vd_total                                                AS  discount_vd_total,
              work.sup_sam_vd_date_total                                            AS  sup_sam_vd_date_total,
              work.sup_sam_vd_total                                                 AS  sup_sam_vd_total,
              work.keep_shop_vd                                                     AS  keep_shop_vd,
              work.sale_business_car                                                AS  sale_business_car,
              work.rtn_business_car                                                 AS  rtn_business_car,
              work.discount_business_car                                            AS  discount_business_car,
              work.sup_sam_business_car                                             AS  sup_sam_business_car,
              work.drop_ship_fact_send_directly                                     AS  drop_ship_fact_send_directly,
              work.rtn_factory_send_directly                                        AS  rtn_factory_send_directly,
              work.discount_fact_send_directly                                      AS  discount_fact_send_directly,
              work.sup_fact_send_directly                                           AS  sup_fact_send_directly,
              work.sale_main_whse                                                   AS  sale_main_whse,
              work.rtn_main_whse                                                    AS  rtn_main_whse,
              work.discount_main_whse                                               AS  discount_main_whse,
              work.sup_sam_main_whse                                                AS  sup_sam_main_whse,
              work.sale_others_whse                                                 AS  sale_others_whse,
              work.rtn_others_whse                                                  AS  rtn_others_whse,
              work.discount_others_whse                                             AS  discount_others_whse,
              work.sup_sam_others_whse                                              AS  sup_sam_others_whse,
              work.sale_others_base_whse_sale                                       AS  sale_others_base_whse_sale,
              work.rtn_others_base_whse_sale                                        AS  rtn_others_base_whse_sale,
              work.discount_oth_base_whse_sale                                      AS  discount_oth_base_whse_sale,
              work.sup_sam_oth_base_whse_sale                                       AS  sup_sam_oth_base_whse_sale,
              work.sale_actual_transfer                                             AS  sale_actual_transfer,
              work.rtn_actual_transfer                                              AS  rtn_actual_transfer,
              work.discount_actual_transfer                                         AS  discount_actual_transfer,
              work.sup_sam_actual_transfer                                          AS  sup_sam_actual_transfer,
              work.sprcial_sale                                                     AS  sprcial_sale,
              work.rtn_asprcial_sale                                                AS  rtn_asprcial_sale,
              work.sale_new_contribution_sale                                       AS  sale_new_contribution_sale,
              work.rtn_new_contribution_sale                                        AS  rtn_new_contribution_sale,
              work.discount_new_contr_sale                                          AS  discount_new_contr_sale,
              work.sup_sam_new_contr_sale                                           AS  sup_sam_new_contr_sale,
              work.count_yet_visit_party                                            AS  count_yet_visit_party,
              work.count_yet_dealings_party                                         AS  count_yet_dealings_party,
              work.count_delay_visit_count                                          AS  count_delay_visit_count,
              work.count_delay_valid_count                                          AS  count_delay_valid_count,
              work.count_valid_count                                                AS  count_valid_count,
              work.count_new_count                                                  AS  count_new_count,
              work.count_new_vendor_count                                           AS  count_new_vendor_count,
              work.count_new_point                                                  AS  count_new_point,
              work.count_mc_party                                                   AS  count_mc_party,
              work.policy_sum_code                                                  AS  policy_sum_code,
              work.policy_sum_name                                                  AS  policy_sum_name,
              work.policy_group                                                     AS  policy_group,
              work.group_name                                                       AS  group_name,
              work.sale_amount                                                      AS  sale_amount,
              work.business_cost                                                    AS  business_cost,
/* 2016/04/15 Ver1.14 Add Start */
              work.prev_year_sale_amount                                            AS  prev_year_sale_amount,
              work.prev_year_business_cost                                          AS  prev_year_business_cost,
/* 2016/04/15 Ver1.14 Add End   */
              cn_created_by                                                         AS  created_by,
              cd_creation_date                                                      AS  creation_date,
              cn_last_updated_by                                                    AS  last_updated_by,
              cd_last_update_date                                                   AS  last_update_date,
              cn_last_update_login                                                  AS  last_update_login,
              cn_request_id                                                         AS  request_id,
              cn_program_application_id                                             AS  program_application_id,
              cn_program_id                                                         AS  program_id,
              cd_program_update_date                                                AS  program_update_date
        FROM  (
              SELECT
                      xrbp.base_code                                                AS  base_code,
                      xrbp.base_name                                                AS  base_name,
                      xrbp.section_code                                             AS  section_code,
                      xrbp.section_name                                             AS  section_name,
                      NULL                                                          AS  group_in_sequence,
                      xrbp.section_code                                             AS  employee_num,
                      xrbp.section_name                                             AS  employee_name,
                      sum(xrbp.norma)                                               AS  norma,
                      sum(xrbp.sale_shop_date_total)                                AS  sale_shop_date_total,
                      sum(xrbp.sale_shop_total)                                     AS  sale_shop_total,
                      sum(xrbp.rtn_shop_date_total)                                 AS  rtn_shop_date_total,
                      sum(xrbp.rtn_shop_total)                                      AS  rtn_shop_total,
                      sum(xrbp.discount_shop_date_total)                            AS  discount_shop_date_total,
                      sum(xrbp.discount_shop_total)                                 AS  discount_shop_total,
                      sum(xrbp.sup_sam_shop_date_total)                             AS  sup_sam_shop_date_total,
                      sum(xrbp.sup_sam_shop_total)                                  AS  sup_sam_shop_total,
                      sum(xrbp.keep_shop_quantity)                                  AS  keep_shop_quantity,
                      sum(xrbp.sale_cvs_date_total)                                 AS  sale_cvs_date_total,
                      sum(xrbp.sale_cvs_total)                                      AS  sale_cvs_total,
                      sum(xrbp.rtn_cvs_date_total)                                  AS  rtn_cvs_date_total,
                      sum(xrbp.rtn_cvs_total)                                       AS  rtn_cvs_total,
                      sum(xrbp.discount_cvs_date_total)                             AS  discount_cvs_date_total,
                      sum(xrbp.discount_cvs_total)                                  AS  discount_cvs_total,
                      sum(xrbp.sup_sam_cvs_date_total)                              AS  sup_sam_cvs_date_total,
                      sum(xrbp.sup_sam_cvs_total)                                   AS  sup_sam_cvs_total,
                      sum(xrbp.keep_shop_cvs)                                       AS  keep_shop_cvs,
                      sum(xrbp.sale_wholesale_date_total)                           AS  sale_wholesale_date_total,
                      sum(xrbp.sale_wholesale_total)                                AS  sale_wholesale_total,
                      sum(xrbp.rtn_wholesale_date_total)                            AS  rtn_wholesale_date_total,
                      sum(xrbp.rtn_wholesale_total)                                 AS  rtn_wholesale_total,
                      sum(xrbp.discount_whol_date_total)                            AS  discount_whol_date_total,
                      sum(xrbp.discount_whol_total)                                 AS  discount_whol_total,
                      sum(xrbp.sup_sam_whol_date_total)                             AS  sup_sam_whol_date_total,
                      sum(xrbp.sup_sam_whol_total)                                  AS  sup_sam_whol_total,
                      sum(xrbp.keep_shop_wholesale)                                 AS  keep_shop_wholesale,
                      sum(xrbp.sale_others_date_total)                              AS  sale_others_date_total,
                      sum(xrbp.sale_others_total)                                   AS  sale_others_total,
                      sum(xrbp.rtn_others_date_total)                               AS  rtn_others_date_total,
                      sum(xrbp.rtn_others_total)                                    AS  rtn_others_total,
                      sum(xrbp.discount_others_date_total)                          AS  discount_others_date_total,
                      sum(xrbp.discount_others_total)                               AS  discount_others_total,
                      sum(xrbp.sup_sam_others_date_total)                           AS  sup_sam_others_date_total,
                      sum(xrbp.sup_sam_others_total)                                AS  sup_sam_others_total,
                      sum(xrbp.keep_shop_others)                                    AS  keep_shop_others,
                      sum(xrbp.sale_vd_date_total)                                  AS  sale_vd_date_total,
                      sum(xrbp.sale_vd_total)                                       AS  sale_vd_total,
                      sum(xrbp.rtn_vd_date_total)                                   AS  rtn_vd_date_total,
                      sum(xrbp.rtn_vd_total)                                        AS  rtn_vd_total,
                      sum(xrbp.discount_vd_date_total)                              AS  discount_vd_date_total,
                      sum(xrbp.discount_vd_total)                                   AS  discount_vd_total,
                      sum(xrbp.sup_sam_vd_date_total)                               AS  sup_sam_vd_date_total,
                      sum(xrbp.sup_sam_vd_total)                                    AS  sup_sam_vd_total,
                      sum(xrbp.keep_shop_vd)                                        AS  keep_shop_vd,
                      sum(xrbp.sale_business_car)                                   AS  sale_business_car,
                      sum(xrbp.rtn_business_car)                                    AS  rtn_business_car,
                      sum(xrbp.discount_business_car)                               AS  discount_business_car,
                      sum(xrbp.sup_sam_business_car)                                AS  sup_sam_business_car,
                      sum(xrbp.drop_ship_fact_send_directly)                        AS  drop_ship_fact_send_directly,
                      sum(xrbp.rtn_factory_send_directly)                           AS  rtn_factory_send_directly,
                      sum(xrbp.discount_fact_send_directly)                         AS  discount_fact_send_directly,
                      sum(xrbp.sup_fact_send_directly)                              AS  sup_fact_send_directly,
                      sum(xrbp.sale_main_whse)                                      AS  sale_main_whse,
                      sum(xrbp.rtn_main_whse)                                       AS  rtn_main_whse,
                      sum(xrbp.discount_main_whse)                                  AS  discount_main_whse,
                      sum(xrbp.sup_sam_main_whse)                                   AS  sup_sam_main_whse,
                      sum(xrbp.sale_others_whse)                                    AS  sale_others_whse,
                      sum(xrbp.rtn_others_whse)                                     AS  rtn_others_whse,
                      sum(xrbp.discount_others_whse)                                AS  discount_others_whse,
                      sum(xrbp.sup_sam_others_whse)                                 AS  sup_sam_others_whse,
                      sum(xrbp.sale_others_base_whse_sale)                          AS  sale_others_base_whse_sale,
                      sum(xrbp.rtn_others_base_whse_sale)                           AS  rtn_others_base_whse_sale,
                      sum(xrbp.discount_oth_base_whse_sale)                         AS  discount_oth_base_whse_sale,
                      sum(xrbp.sup_sam_oth_base_whse_sale)                          AS  sup_sam_oth_base_whse_sale,
                      sum(xrbp.sale_actual_transfer)                                AS  sale_actual_transfer,
                      sum(xrbp.rtn_actual_transfer)                                 AS  rtn_actual_transfer,
                      sum(xrbp.discount_actual_transfer)                            AS  discount_actual_transfer,
                      sum(xrbp.sup_sam_actual_transfer)                             AS  sup_sam_actual_transfer,
                      sum(xrbp.sprcial_sale)                                        AS  sprcial_sale,
                      sum(xrbp.rtn_asprcial_sale)                                   AS  rtn_asprcial_sale,
                      sum(xrbp.sale_new_contribution_sale)                          AS  sale_new_contribution_sale,
                      sum(xrbp.rtn_new_contribution_sale)                           AS  rtn_new_contribution_sale,
                      sum(xrbp.discount_new_contr_sale)                             AS  discount_new_contr_sale,
                      sum(xrbp.sup_sam_new_contr_sale)                              AS  sup_sam_new_contr_sale,
                      sum(xrbp.count_yet_visit_party)                               AS  count_yet_visit_party,
                      sum(xrbp.count_yet_dealings_party)                            AS  count_yet_dealings_party,
                      sum(xrbp.count_delay_visit_count)                             AS  count_delay_visit_count,
                      sum(xrbp.count_delay_valid_count)                             AS  count_delay_valid_count,
                      sum(xrbp.count_valid_count)                                   AS  count_valid_count,
                      sum(xrbp.count_new_count)                                     AS  count_new_count,
                      sum(xrbp.count_new_vendor_count)                              AS  count_new_vendor_count,
                      sum(xrbp.count_new_point)                                     AS  count_new_point,
                      sum(xrbp.count_mc_party)                                      AS  count_mc_party,
                      xrbp.policy_sum_code                                          AS  policy_sum_code,
                      xrbp.policy_sum_name                                          AS  policy_sum_name,
                      xrbp.policy_group                                             AS  policy_group,
                      xrbp.group_name                                               AS  group_name,
                      sum(xrbp.sale_amount)                                         AS  sale_amount,
/* 2016/04/15 Ver1.14 Mod Start */
--                      sum(xrbp.business_cost)                                       AS  business_cost
                      sum(xrbp.business_cost)                                       AS  business_cost,
                      sum(xrbp.prev_year_sale_amount)                               AS  prev_year_sale_amount,
                      sum(xrbp.prev_year_business_cost)                             AS  prev_year_business_cost
/* 2016/04/15 Ver1.14 Mod End   */
              FROM    xxcos_rep_bus_perf            xrbp
              WHERE   xrbp.request_id               =       cn_request_id
              AND     xrbp.sum_data_class           =       ct_sum_data_cls_employee
              GROUP BY
                      xrbp.base_code,
                      xrbp.base_name,
                      xrbp.section_code,
                      xrbp.section_name,
                      xrbp.policy_sum_code,
                      xrbp.policy_sum_name,
                      xrbp.policy_group,
                      xrbp.group_name
              ) WORK
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  �o�^�����J�E���g
    g_counter_rec.insert_section_total := SQL%ROWCOUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END insert_section_total;
--
  /**********************************************************************************
   * Procedure Name   : insert_base_total
   * Description      : ���_�W�v��񐶐�(A-12)
   ***********************************************************************************/
  PROCEDURE insert_base_total(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_base_total'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==================================
    -- 1.�������s����
    --==================================
    IF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_base_only ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.�f�[�^�o�^  �i���_�W�v���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
-- == 2015/03/16 V1.13 Added START =================================================================
              gl_cl_char,
-- == 2015/03/16 V1.13 Added END   =================================================================
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
              sale_amount,
              business_cost,
/* 2016/04/15 Ver1.14 Add Start */
              prev_year_sale_amount,
              prev_year_business_cost,
/* 2016/04/15 Ver1.14 Add End   */
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
              ct_sum_data_cls_base                                                  AS  sum_data_class,
              gd_common_base_date                                                   AS  target_date,
              work.base_code                                                        AS  base_code,
              SUBSTRB(work.base_name || xlbs.meaning, 1, cn_limit_base_name)        AS  base_name,
-- == 2015/03/16 V1.13 Added START =================================================================
              gt_prof_inv_cl_char                                                   AS  gl_cl_char,
-- == 2015/03/16 V1.13 Added END   =================================================================
              work.section_code                                                     AS  section_code,
              work.section_name                                                     AS  section_name,
              work.group_in_sequence                                                AS  group_in_sequence,
              work.employee_num                                                     AS  employee_num,
              work.employee_name                                                    AS  employee_name,
              work.norma                                                            AS  norma,
              gn_common_operating_days                                              AS  actual_date_quantity,
              gn_common_lapsed_days                                                 AS  course_date_quantity,
              work.sale_shop_date_total                                             AS  sale_shop_date_total,
              work.sale_shop_total                                                  AS  sale_shop_total,
              work.rtn_shop_date_total                                              AS  rtn_shop_date_total,
              work.rtn_shop_total                                                   AS  rtn_shop_total,
              work.discount_shop_date_total                                         AS  discount_shop_date_total,
              work.discount_shop_total                                              AS  discount_shop_total,
              work.sup_sam_shop_date_total                                          AS  sup_sam_shop_date_total,
              work.sup_sam_shop_total                                               AS  sup_sam_shop_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_quantity                                               AS  keep_shop_quantity,
              NULL                                                                  AS  keep_shop_quantity,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_cvs_date_total                                              AS  sale_cvs_date_total,
              work.sale_cvs_total                                                   AS  sale_cvs_total,
              work.rtn_cvs_date_total                                               AS  rtn_cvs_date_total,
              work.rtn_cvs_total                                                    AS  rtn_cvs_total,
              work.discount_cvs_date_total                                          AS  discount_cvs_date_total,
              work.discount_cvs_total                                               AS  discount_cvs_total,
              work.sup_sam_cvs_date_total                                           AS  sup_sam_cvs_date_total,
              work.sup_sam_cvs_total                                                AS  sup_sam_cvs_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_cvs                                                    AS  keep_shop_cvs,
              NULL                                                                  AS  keep_shop_cvs,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_wholesale_date_total                                        AS  sale_wholesale_date_total,
              work.sale_wholesale_total                                             AS  sale_wholesale_total,
              work.rtn_wholesale_date_total                                         AS  rtn_wholesale_date_total,
              work.rtn_wholesale_total                                              AS  rtn_wholesale_total,
              work.discount_whol_date_total                                         AS  discount_whol_date_total,
              work.discount_whol_total                                              AS  discount_whol_total,
              work.sup_sam_whol_date_total                                          AS  sup_sam_whol_date_total,
              work.sup_sam_whol_total                                               AS  sup_sam_whol_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_wholesale                                              AS  keep_shop_wholesale,
              NULL                                                                  AS  keep_shop_wholesale,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_others_date_total                                           AS  sale_others_date_total,
              work.sale_others_total                                                AS  sale_others_total,
              work.rtn_others_date_total                                            AS  rtn_others_date_total,
              work.rtn_others_total                                                 AS  rtn_others_total,
              work.discount_others_date_total                                       AS  discount_others_date_total,
              work.discount_others_total                                            AS  discount_others_total,
              work.sup_sam_others_date_total                                        AS  sup_sam_others_date_total,
              work.sup_sam_others_total                                             AS  sup_sam_others_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_others                                                 AS  keep_shop_others,
              NULL                                                                  AS  keep_shop_others,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_vd_date_total                                               AS  sale_vd_date_total,
              work.sale_vd_total                                                    AS  sale_vd_total,
              work.rtn_vd_date_total                                                AS  rtn_vd_date_total,
              work.rtn_vd_total                                                     AS  rtn_vd_total,
              work.discount_vd_date_total                                           AS  discount_vd_date_total,
              work.discount_vd_total                                                AS  discount_vd_total,
              work.sup_sam_vd_date_total                                            AS  sup_sam_vd_date_total,
              work.sup_sam_vd_total                                                 AS  sup_sam_vd_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_vd                                                     AS  keep_shop_vd,
              NULL                                                                  AS  keep_shop_vd,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_business_car                                                AS  sale_business_car,
              work.rtn_business_car                                                 AS  rtn_business_car,
              work.discount_business_car                                            AS  discount_business_car,
              work.sup_sam_business_car                                             AS  sup_sam_business_car,
              work.drop_ship_fact_send_directly                                     AS  drop_ship_fact_send_directly,
              work.rtn_factory_send_directly                                        AS  rtn_factory_send_directly,
              work.discount_fact_send_directly                                      AS  discount_fact_send_directly,
              work.sup_fact_send_directly                                           AS  sup_fact_send_directly,
              work.sale_main_whse                                                   AS  sale_main_whse,
              work.rtn_main_whse                                                    AS  rtn_main_whse,
              work.discount_main_whse                                               AS  discount_main_whse,
              work.sup_sam_main_whse                                                AS  sup_sam_main_whse,
              work.sale_others_whse                                                 AS  sale_others_whse,
              work.rtn_others_whse                                                  AS  rtn_others_whse,
              work.discount_others_whse                                             AS  discount_others_whse,
              work.sup_sam_others_whse                                              AS  sup_sam_others_whse,
              work.sale_others_base_whse_sale                                       AS  sale_others_base_whse_sale,
              work.rtn_others_base_whse_sale                                        AS  rtn_others_base_whse_sale,
              work.discount_oth_base_whse_sale                                      AS  discount_oth_base_whse_sale,
              work.sup_sam_oth_base_whse_sale                                       AS  sup_sam_oth_base_whse_sale,
              work.sale_actual_transfer                                             AS  sale_actual_transfer,
              work.rtn_actual_transfer                                              AS  rtn_actual_transfer,
              work.discount_actual_transfer                                         AS  discount_actual_transfer,
              work.sup_sam_actual_transfer                                          AS  sup_sam_actual_transfer,
              work.sprcial_sale                                                     AS  sprcial_sale,
              work.rtn_asprcial_sale                                                AS  rtn_asprcial_sale,
              work.sale_new_contribution_sale                                       AS  sale_new_contribution_sale,
              work.rtn_new_contribution_sale                                        AS  rtn_new_contribution_sale,
              work.discount_new_contr_sale                                          AS  discount_new_contr_sale,
              work.sup_sam_new_contr_sale                                           AS  sup_sam_new_contr_sale,
              work.count_yet_visit_party                                            AS  count_yet_visit_party,
              work.count_yet_dealings_party                                         AS  count_yet_dealings_party,
              work.count_delay_visit_count                                          AS  count_delay_visit_count,
              work.count_delay_valid_count                                          AS  count_delay_valid_count,
              work.count_valid_count                                                AS  count_valid_count,
              work.count_new_count                                                  AS  count_new_count,
              work.count_new_vendor_count                                           AS  count_new_vendor_count,
              work.count_new_point                                                  AS  count_new_point,
              work.count_mc_party                                                   AS  count_mc_party,
              work.policy_sum_code                                                  AS  policy_sum_code,
              work.policy_sum_name                                                  AS  policy_sum_name,
              work.policy_group                                                     AS  policy_group,
              work.group_name                                                       AS  group_name,
              work.sale_amount                                                      AS  sale_amount,
              work.business_cost                                                    AS  business_cost,
/* 2016/04/15 Ver1.14 Add Start */
              work.prev_year_sale_amount                                            AS  prev_year_sale_amount,
              work.prev_year_business_cost                                          AS  prev_year_business_cost,
/* 2016/04/15 Ver1.14 Add End   */
              cn_created_by                                                         AS  created_by,
              cd_creation_date                                                      AS  creation_date,
              cn_last_updated_by                                                    AS  last_updated_by,
              cd_last_update_date                                                   AS  last_update_date,
              cn_last_update_login                                                  AS  last_update_login,
              cn_request_id                                                         AS  request_id,
              cn_program_application_id                                             AS  program_application_id,
              cn_program_id                                                         AS  program_id,
              cd_program_update_date                                                AS  program_update_date
        FROM  (
              SELECT
                      xrbp.base_code                                                AS  base_code,
                      xrbp.base_name                                                AS  base_name,
                      NULL                                                          AS  section_code,
                      NULL                                                          AS  section_name,
                      NULL                                                          AS  group_in_sequence,
                      NULL                                                          AS  employee_num,
                      NULL                                                          AS  employee_name,
                      sum(xrbp.norma)                                               AS  norma,
                      sum(xrbp.sale_shop_date_total)                                AS  sale_shop_date_total,
                      sum(xrbp.sale_shop_total)                                     AS  sale_shop_total,
                      sum(xrbp.rtn_shop_date_total)                                 AS  rtn_shop_date_total,
                      sum(xrbp.rtn_shop_total)                                      AS  rtn_shop_total,
                      sum(xrbp.discount_shop_date_total)                            AS  discount_shop_date_total,
                      sum(xrbp.discount_shop_total)                                 AS  discount_shop_total,
                      sum(xrbp.sup_sam_shop_date_total)                             AS  sup_sam_shop_date_total,
                      sum(xrbp.sup_sam_shop_total)                                  AS  sup_sam_shop_total,
                      sum(xrbp.keep_shop_quantity)                                  AS  keep_shop_quantity,
                      sum(xrbp.sale_cvs_date_total)                                 AS  sale_cvs_date_total,
                      sum(xrbp.sale_cvs_total)                                      AS  sale_cvs_total,
                      sum(xrbp.rtn_cvs_date_total)                                  AS  rtn_cvs_date_total,
                      sum(xrbp.rtn_cvs_total)                                       AS  rtn_cvs_total,
                      sum(xrbp.discount_cvs_date_total)                             AS  discount_cvs_date_total,
                      sum(xrbp.discount_cvs_total)                                  AS  discount_cvs_total,
                      sum(xrbp.sup_sam_cvs_date_total)                              AS  sup_sam_cvs_date_total,
                      sum(xrbp.sup_sam_cvs_total)                                   AS  sup_sam_cvs_total,
                      sum(xrbp.keep_shop_cvs)                                       AS  keep_shop_cvs,
                      sum(xrbp.sale_wholesale_date_total)                           AS  sale_wholesale_date_total,
                      sum(xrbp.sale_wholesale_total)                                AS  sale_wholesale_total,
                      sum(xrbp.rtn_wholesale_date_total)                            AS  rtn_wholesale_date_total,
                      sum(xrbp.rtn_wholesale_total)                                 AS  rtn_wholesale_total,
                      sum(xrbp.discount_whol_date_total)                            AS  discount_whol_date_total,
                      sum(xrbp.discount_whol_total)                                 AS  discount_whol_total,
                      sum(xrbp.sup_sam_whol_date_total)                             AS  sup_sam_whol_date_total,
                      sum(xrbp.sup_sam_whol_total)                                  AS  sup_sam_whol_total,
                      sum(xrbp.keep_shop_wholesale)                                 AS  keep_shop_wholesale,
                      sum(xrbp.sale_others_date_total)                              AS  sale_others_date_total,
                      sum(xrbp.sale_others_total)                                   AS  sale_others_total,
                      sum(xrbp.rtn_others_date_total)                               AS  rtn_others_date_total,
                      sum(xrbp.rtn_others_total)                                    AS  rtn_others_total,
                      sum(xrbp.discount_others_date_total)                          AS  discount_others_date_total,
                      sum(xrbp.discount_others_total)                               AS  discount_others_total,
                      sum(xrbp.sup_sam_others_date_total)                           AS  sup_sam_others_date_total,
                      sum(xrbp.sup_sam_others_total)                                AS  sup_sam_others_total,
                      sum(xrbp.keep_shop_others)                                    AS  keep_shop_others,
                      sum(xrbp.sale_vd_date_total)                                  AS  sale_vd_date_total,
                      sum(xrbp.sale_vd_total)                                       AS  sale_vd_total,
                      sum(xrbp.rtn_vd_date_total)                                   AS  rtn_vd_date_total,
                      sum(xrbp.rtn_vd_total)                                        AS  rtn_vd_total,
                      sum(xrbp.discount_vd_date_total)                              AS  discount_vd_date_total,
                      sum(xrbp.discount_vd_total)                                   AS  discount_vd_total,
                      sum(xrbp.sup_sam_vd_date_total)                               AS  sup_sam_vd_date_total,
                      sum(xrbp.sup_sam_vd_total)                                    AS  sup_sam_vd_total,
                      sum(xrbp.keep_shop_vd)                                        AS  keep_shop_vd,
                      sum(xrbp.sale_business_car)                                   AS  sale_business_car,
                      sum(xrbp.rtn_business_car)                                    AS  rtn_business_car,
                      sum(xrbp.discount_business_car)                               AS  discount_business_car,
                      sum(xrbp.sup_sam_business_car)                                AS  sup_sam_business_car,
                      sum(xrbp.drop_ship_fact_send_directly)                        AS  drop_ship_fact_send_directly,
                      sum(xrbp.rtn_factory_send_directly)                           AS  rtn_factory_send_directly,
                      sum(xrbp.discount_fact_send_directly)                         AS  discount_fact_send_directly,
                      sum(xrbp.sup_fact_send_directly)                              AS  sup_fact_send_directly,
                      sum(xrbp.sale_main_whse)                                      AS  sale_main_whse,
                      sum(xrbp.rtn_main_whse)                                       AS  rtn_main_whse,
                      sum(xrbp.discount_main_whse)                                  AS  discount_main_whse,
                      sum(xrbp.sup_sam_main_whse)                                   AS  sup_sam_main_whse,
                      sum(xrbp.sale_others_whse)                                    AS  sale_others_whse,
                      sum(xrbp.rtn_others_whse)                                     AS  rtn_others_whse,
                      sum(xrbp.discount_others_whse)                                AS  discount_others_whse,
                      sum(xrbp.sup_sam_others_whse)                                 AS  sup_sam_others_whse,
                      sum(xrbp.sale_others_base_whse_sale)                          AS  sale_others_base_whse_sale,
                      sum(xrbp.rtn_others_base_whse_sale)                           AS  rtn_others_base_whse_sale,
                      sum(xrbp.discount_oth_base_whse_sale)                         AS  discount_oth_base_whse_sale,
                      sum(xrbp.sup_sam_oth_base_whse_sale)                          AS  sup_sam_oth_base_whse_sale,
                      sum(xrbp.sale_actual_transfer)                                AS  sale_actual_transfer,
                      sum(xrbp.rtn_actual_transfer)                                 AS  rtn_actual_transfer,
                      sum(xrbp.discount_actual_transfer)                            AS  discount_actual_transfer,
                      sum(xrbp.sup_sam_actual_transfer)                             AS  sup_sam_actual_transfer,
                      sum(xrbp.sprcial_sale)                                        AS  sprcial_sale,
                      sum(xrbp.rtn_asprcial_sale)                                   AS  rtn_asprcial_sale,
                      sum(xrbp.sale_new_contribution_sale)                          AS  sale_new_contribution_sale,
                      sum(xrbp.rtn_new_contribution_sale)                           AS  rtn_new_contribution_sale,
                      sum(xrbp.discount_new_contr_sale)                             AS  discount_new_contr_sale,
                      sum(xrbp.sup_sam_new_contr_sale)                              AS  sup_sam_new_contr_sale,
                      sum(xrbp.count_yet_visit_party)                               AS  count_yet_visit_party,
                      sum(xrbp.count_yet_dealings_party)                            AS  count_yet_dealings_party,
                      sum(xrbp.count_delay_visit_count)                             AS  count_delay_visit_count,
                      sum(xrbp.count_delay_valid_count)                             AS  count_delay_valid_count,
                      sum(xrbp.count_valid_count)                                   AS  count_valid_count,
                      sum(xrbp.count_new_count)                                     AS  count_new_count,
                      sum(xrbp.count_new_vendor_count)                              AS  count_new_vendor_count,
                      sum(xrbp.count_new_point)                                     AS  count_new_point,
                      sum(xrbp.count_mc_party)                                      AS  count_mc_party,
                      xrbp.policy_sum_code                                          AS  policy_sum_code,
                      xrbp.policy_sum_name                                          AS  policy_sum_name,
                      xrbp.policy_group                                             AS  policy_group,
                      xrbp.group_name                                               AS  group_name,
                      sum(xrbp.sale_amount)                                         AS  sale_amount,
/* 2016/04/15 Ver1.14 Mod Start */
--                      sum(xrbp.business_cost)                                       AS  business_cost
                      sum(xrbp.business_cost)                                       AS  business_cost,
                      sum(xrbp.prev_year_sale_amount)                               AS  prev_year_sale_amount,
                      sum(xrbp.prev_year_business_cost)                             AS  prev_year_business_cost
/* 2016/04/15 Ver1.14 Mod End   */
              FROM    xxcos_rep_bus_perf            xrbp
              WHERE   xrbp.request_id               =       cn_request_id
              AND     xrbp.sum_data_class           =       ct_sum_data_cls_employee
              GROUP BY
                      xrbp.base_code,
                      xrbp.base_name,
                      xrbp.policy_sum_code,
                      xrbp.policy_sum_name,
                      xrbp.policy_group,
                      xrbp.group_name
              )                           work,
              xxcos_lookup_values_v       xlbs
        WHERE xlbs.lookup_type            =       ct_qct_base_suffix_type
        AND   xlbs.lookup_code            =       ct_qcc_base_suffix_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  �o�^�����J�E���g
    g_counter_rec.insert_base_total := SQL%ROWCOUNT;
--
/* 2010/04/16 Ver1.9 Add Start */
    --==================================
    -- 3.�f�[�^�X�V  �i���_�W�v���j
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              keep_shop_quantity,
              keep_shop_cvs,
              keep_shop_wholesale,
              keep_shop_others,
              keep_shop_vd
              )
              =
              (
              SELECT
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_shop
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_quantity,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_cvs
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_cvs,
                      SUM(CASE
-- Ver1.15 Mod Start
--                            WHEN  rbcs.business_low_type      = ct_biz_wholesale
                            WHEN  rbcs.business_low_type      = ct_biz_drugstore
-- Ver1.15 Mod End
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_wholesale,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_others
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_others,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_vd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_vd
              FROM    xxcos_rep_bus_count_sum     rbcs
              WHERE   rbcs.base_code              =       xrbp.base_code
              AND     rbcs.target_date            =       gv_common_base_years
              AND     rbcs.counter_class          =       ct_counter_cls_base_code_cust
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      AND     xrbp.sum_data_class                 =       ct_sum_data_cls_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
/* 2010/04/16 Ver1.9 Add End   */
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
/* 2010/04/16 Ver1.9 Add Start */
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
/* 2010/04/16 Ver1.9 Add End   */
    --*** �f�[�^�o�^��O�n���h�� ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END insert_base_total;
--
  /**********************************************************************************
   * Procedure Name   : delete_off_the_subject_info
   * Description      : �o�͑ΏۊO���폜(A-13)
   ***********************************************************************************/
  PROCEDURE delete_off_the_subject_info(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_base_code     IN      VARCHAR2,         --  2.���_
    iv_section_code           IN      VARCHAR2,         --  3.��
    iv_results_employee_code  IN      VARCHAR2,         --  4.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_off_the_subject_info'; -- �v���O������
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
/* 2011/02/15 Ver1.10 Add START */
    --  �������K�⌏���A�����V�K�����A������z���S��0�̃f�[�^�͎��тȂ��Ɣ��f����
    CURSOR  del_data_cur
    IS
      SELECT  xrbp.base_code                                          base_code       --  ���_�R�[�h
            , NVL(xrbp.section_code, cv_para_dummy_section_code)      section_code    --  �ۃR�[�h
            , xrbp.employee_num                                       employee_num    --  �c�ƈ��R�[�h
      FROM    xxcos_rep_bus_perf      xrbp
      WHERE   xrbp.request_id         =   cn_request_id
      AND     xrbp.sum_data_class     =   ct_sum_data_cls_employee
      HAVING  (     SUM(NVL(xrbp.count_delay_visit_count, 0))   =   0
                AND SUM(NVL(xrbp.count_new_count, 0))           =   0
                AND SUM(NVL(xrbp.sale_amount, 0))               =   0
              )
      GROUP BY    xrbp.base_code
                , xrbp.section_code
                , xrbp.employee_num;
    --
    del_data_rec    del_data_cur%ROWTYPE;
/* 2011/02/15 Ver1.10 Add END   */
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==================================
    -- 1.�f�[�^�폜  �i�o�͑ΏۊO���폜�j
    --==================================
    --  �폜�����P
    --  �p�����[�^�D�o�͒P�ʂɁu3�F���_�W�v�i���_�W�v�̂݁j�v�A�u4�F�ۏW�v�i�ۏW�v�̂݁j�v��
    --  �w�肳�ꂽ�ꍇ�͖������ɑS�c�ƈ��̌l�ʂ̃f�[�^���폜���܂��B
    --  
    --  �폜�����Q
    --  �p�����[�^�D�o�͒P�ʂɁu1�F�S�āi�e�c�ƈ��A�ۏW�v�A���_�W�v�j�v�A�u2�F�ۏW�v�i�e�c�ƈ��A�ۏW�v�j�v��
    --  �w�肳�ꂽ�ꍇ�͉�(�O���[�v)�����ʃf�[�^�D�_�~�[�c�ƃO���[�v�R�[�h�ƈ�v����l�ʐ��ѕ\�̂ݍ폜���܂��B
    BEGIN
/* 2009/06/18 Ver1.5 Mod Start */
--      DELETE
--      FROM      xxcos_rep_bus_perf            xrbp
--      WHERE (   iv_unit_of_output             IN      (cv_para_unit_base_only, cv_para_unit_section_only)
--            AND xrbp.sum_data_class           =       ct_sum_data_cls_employee
--            AND xrbp.request_id               =       cn_request_id
--            )
--      OR    (   iv_unit_of_output             IN      (cv_para_unit_all, cv_para_unit_section_sum)
--            AND xrbp.section_code             =       gt_prof_dummy_sales_group
--            AND xrbp.request_id               =       cn_request_id
--            )
--      ;
      IF ( iv_unit_of_output IN ( cv_para_unit_base_only, cv_para_unit_section_only ) ) THEN
        DELETE
        FROM   xxcos_rep_bus_perf  xrbp
        WHERE  xrbp.sum_data_class  = ct_sum_data_cls_employee
        AND    xrbp.request_id      = cn_request_id
        ;
/* 2009/07/07 Ver1.7 Add Start */
        --  �o�^�����J�E���g
        g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Add End   */
      ELSIF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_section_sum ) ) THEN
        DELETE
        FROM   xxcos_rep_bus_perf  xrbp
        WHERE  xrbp.section_code    = gt_prof_dummy_sales_group
        AND    xrbp.request_id      = cn_request_id
        ;
/* 2009/07/07 Ver1.7 Add Start */
        --  �o�^�����J�E���g
        g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Add End   */
      END IF;
/* 2009/06/18 Ver1.5 Mod End */
/* 2011/02/15 Ver1.10 Add START */
      FOR del_data_rec  IN  del_data_cur LOOP
        --  ���_�A�ہA�c�ƈ����x���ŁA���т̖����c�ƈ������폜
        DELETE
        FROM    xxcos_rep_bus_perf  xrbp
        WHERE   xrbp.sum_data_class                                   =   ct_sum_data_cls_employee
        AND     xrbp.request_id                                       =   cn_request_id
        AND     xrbp.base_code                                        =   del_data_rec.base_code
        AND     NVL(xrbp.section_code, cv_para_dummy_section_code)    =   del_data_rec.section_code
        AND     xrbp.employee_num                                     =   del_data_rec.employee_num;
        --
        g_counter_rec.delete_off_the_subject_info := g_counter_rec.delete_off_the_subject_info + SQL%ROWCOUNT;
      END LOOP;
/* 2011/02/15 Ver1.10 Add END   */
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
/* 2009/07/07 Ver1.7 Del Start */
--    --  �o�^�����J�E���g
--    g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Del End   */
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END delete_off_the_subject_info;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : �r�u�e�N��(A-14)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
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
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.����0���p���b�Z�[�W�擾
    --==================================
    lv_nodata_msg             :=  xxccp_common_pkg.get_msg(
                                                          iv_application          => ct_xxcos_appl_short_name,
                                                          iv_name                 => ct_msg_nodata_err
                                                          );
    --�o�̓t�@�C���ҏW
    lv_file_name              :=  cv_file_id
                              ||  TO_CHAR(SYSDATE, cv_fmt_date)
                              ||  TO_CHAR(cn_request_id)
                              ||  cv_extension_pdf
                              ;
    --==================================
    -- 2.SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
                                          ov_retcode              => lv_retcode,
                                          ov_errbuf               => lv_errbuf,
                                          ov_errmsg               => lv_errmsg,
                                          iv_conc_name            => cv_conc_name,
                                          iv_file_name            => lv_file_name,
                                          iv_file_id              => cv_file_id,
                                          iv_output_mode          => cv_output_mode_pdf,
                                          iv_frm_file             => cv_frm_file,
                                          iv_vrq_file             => cv_vrq_file,
                                          iv_org_id               => NULL,
                                          iv_user_name            => NULL,
                                          iv_resp_name            => NULL,
                                          iv_doc_name             => NULL,
                                          iv_printer_name         => NULL,
                                          iv_request_id           => TO_CHAR( cn_request_id ),
                                          iv_nodata_msg           => lv_nodata_msg,
                                          iv_svf_param1           => NULL,
                                          iv_svf_param2           => NULL,
                                          iv_svf_param3           => NULL,
                                          iv_svf_param4           => NULL,
                                          iv_svf_param5           => NULL,
                                          iv_svf_param6           => NULL,
                                          iv_svf_param7           => NULL,
                                          iv_svf_param8           => NULL,
                                          iv_svf_param9           => NULL,
                                          iv_svf_param10          => NULL,
                                          iv_svf_param11          => NULL,
                                          iv_svf_param12          => NULL,
                                          iv_svf_param13          => NULL,
                                          iv_svf_param14          => NULL,
                                          iv_svf_param15          => NULL
                                          );
--
    IF  ( lv_retcode  <>  cv_status_normal  ) THEN
      --  �Ǘ��җp���b�Z�[�W�ޔ�
      lv_errbuf               :=  SUBSTRB(lv_errmsg ||  lv_errbuf, 5000);
--
      --  ���[�U�[�p���b�Z�[�W�擾
      lv_api_name             :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_svf_api
                                                          );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_call_api_err,
                                                          iv_token_name1        => cv_tkn_api_name,
                                                          iv_token_value1       => lv_api_name
                                                          );
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-15)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
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
    -- 1.���[���[�N�e�[�u���f�[�^���b�N
    --==================================
--
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_cur;
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lv_table_name           :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_rpt_wrk_tbl
                                                            );
--
        ov_errmsg               :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_lock_err,
                                                            iv_token_name1        => cv_tkn_table,
                                                            iv_token_value1       => lv_table_name
                                                            );
        RAISE global_data_lock_expt;
    END;
--
--
    --==================================
    -- 2.���[���[�N�e�[�u���폜
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_perf        xrbp
      WHERE   xrbp.request_id           =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�v��ID������擾
        lv_key_info           :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_request,
                                                          iv_token_name1        => cv_tkn_request,
                                                          iv_token_value1       => TO_CHAR(cn_request_id)
                                                          );
        --  ���ʊ֐��X�e�[�^�X�`�F�b�N
        IF  ( lv_retcode  <>  cv_status_normal  ) THEN
          RAISE global_api_expt;
        END IF;
--
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
--
        ov_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_delete_data_err,
                                              iv_token_name1 => cv_tkn_table,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> lv_key_info
                                              );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    WHEN global_data_lock_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** �f�[�^�X�V��O�n���h�� ***
    WHEN global_delete_data_expt THEN
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : end_process
   * Description      : �I������(A-16)
   ***********************************************************************************/
  PROCEDURE end_process(
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_process'; -- �v���O������
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
    --==================================
    -- 1.�����������b�Z�[�W�ҏW  �i�c�ƈ��v��f�[�^�o�^�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_entry_sales_plan,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_entry_sales_plan
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 2.�����������b�Z�[�W�ҏW  �i�Ƒԕʔ�����яW�v�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_biz_conditions,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_business_conditions
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 3.�����������b�Z�[�W�ҏW  �i����Q�ʔ�����яW�v�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_policy_group,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_policy_group
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
/* 2016/04/15 Ver1.14 Add Start */
    --==================================
    -- 3-2.�����������b�Z�[�W�ҏW  �i����Q�ʑO�N������яW�v�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_policy_group_py,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_policy_group_py
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
/* 2016/04/15 Ver1.14 Add End   */
--
    --==================================
    -- 4.�����������b�Z�[�W�ҏW  �i�V�K�v��������я��W�v�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_new_cust_sales,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_new_cust_sales_results
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 5.�����������b�Z�[�W�ҏW  �i�e�팏���擾�����f�W�v�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_results_of_biz,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_results_of_business
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 6.�����������b�Z�[�W�ҏW  �i�ۏW�v��񏈗������j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_insert_section_total,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_section_total
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 7.�����������b�Z�[�W�ҏW  �i���_�W�v��񏈗������j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_insert_base_total,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_base_total
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 8.�����������b�Z�[�W�ҏW  �i�o�͑ΏۊO���폜�����j
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_delete_off_the_subject,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_rec.delete_off_the_subject_info
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --  ���[���[�N�e�[�u���ւ̓o�^������Ώی����Ƃ��Ĉ���
    gn_target_cnt :=  g_counter_rec.insert_entry_sales_plan
                  +   g_counter_rec.insert_section_total
                  +   g_counter_rec.insert_base_total
                  -   g_counter_rec.delete_off_the_subject_info
    ;
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
  END end_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_date          IN      VARCHAR2,         --  2.�[�i��
    iv_delivery_base_code     IN      VARCHAR2,         --  3.���_
    iv_section_code           IN      VARCHAR2,         --  4.��
    iv_results_employee_code  IN      VARCHAR2,         --  5.�c�ƈ�
    ov_errbuf                 OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT     VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
/* 2009/06/22 Ver1.6 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
/* 2009/06/22 Ver1.6 Add End   */

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
    --  ===============================
    --  <�������A���[�v����> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    --  ===============================
    init(
      iv_unit_of_output
      ,iv_delivery_date
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �c�ƈ��v��f�[�^���o���o�^(A-2)
    --  ===============================
    entry_sales_plan(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �Ƒԕʔ������ �W�v�����A���f����(A-3,A-4)
    --  �[�i�`�ԕʔ̔����я��W�v�����f����(A-7)
    --  ���ѐU�֏��W�v�����f����(A-8)
    --  ===============================
    update_business_conditions(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  ����Q�� ������� �W�v�A���f����(A-5,A-6)
    --  ===============================
    update_policy_group(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �V�K�v��������я��W�v�����f����(A-9)
    --  ===============================
    update_new_cust_sales_results(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �e�팏���擾�����f����(A-10)
    --  ===============================
    update_results_of_business(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
/* 2016/04/15 Ver1.14 Add Start */
    --  ===============================
    --  ����Q�� ������� �O�N�W�v�A���f����(A-17,A-18)
    --  ===============================
    update_policy_group_py(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
/* 2016/04/15 Ver1.14 Add End   */
    --  ===============================
    --  �ۏW�v��񐶐�(A-11)
    --  ===============================
    insert_section_total(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  ���_�W�v��񐶐�(A-12)
    --  ===============================
    insert_base_total(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �o�͑ΏۊO���폜(A-13)
    --  ===============================
    delete_off_the_subject_info(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  �R�~�b�g���s
    COMMIT;
--
    -- ===============================
    -- �r�u�e�N��(A-14)
    -- ===============================
    execute_svf(
      lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
/* 2009/06/22 Ver1.6 Mod Start */
--    IF  ( lv_retcode = cv_status_error  ) THEN
--     --(�G���[����)
--      RAISE global_process_expt;
--    END IF;
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/22 Ver1.6 Mod End   */
--
    -- ===============================
    -- ���[���[�N�e�[�u���폜(A-15)
    -- ===============================
    delete_rpt_wrk_data(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --(�G���[����)
--
      --  ���b�N�J�[�\���N���[�Y
      IF  ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/22 Ver1.6 Add Start */
    --�G���[�̏ꍇ�A���[���o�b�N����̂ł����ŃR�~�b�g
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/22 Ver1.6 Add Start */
--
    --  ===============================
    --  �I������(A-16)
    --  ===============================
    end_process(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  ���[�͑Ώی��������팏���Ƃ���
    gn_normal_cnt :=  gn_target_cnt;
--
    --���ׂO�����̌x���I������
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
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
    errbuf                    OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_unit_of_output         IN      VARCHAR2,         --  1.�o�͒P��
    iv_delivery_date          IN      VARCHAR2,         --  2.�[�i��
    iv_delivery_base_code     IN      VARCHAR2,         --  3.���_
    iv_section_code           IN      VARCHAR2,         --  4.��
    iv_results_employee_code  IN      VARCHAR2          --  5.�c�ƈ�
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
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
/*
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
*/
--###########################  �Œ蕔 END   #############################
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_unit_of_output
      ,iv_delivery_date
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
END XXCOS002A031R;
/
