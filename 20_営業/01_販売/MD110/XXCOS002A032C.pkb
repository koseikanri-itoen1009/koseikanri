CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A032C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A032C (body)
 * Description      : �c�Ɛ��ѕ\�W�v
 * MD.050           : �c�Ɛ��ѕ\�W�v MD050_COS_002_A03
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(B-1)
 *  ins_jtf_tasks          �^�X�N���2�������o����(B-21)
 *  new_cust_sales_results �V�K�v��������я��W�v���o�^����(B-2)
 *  bus_sales_sum          �ƑԁE�[�i�`�ԕʔ̔����я��W�v���o�^����(B-3)
 *  bus_transfer_sum       �ƑԁE�[�i�`�ԕʎ��ѐU�֏��W�v���o�^����(B-4)
 *  bus_s_group_sum_sales  �c�ƈ��ʁE����Q�ʔ̔����я��W�v���o�^����(B-5)
 *  bus_s_group_sum_trans  �c�ƈ��ʁE����Q�ʎ��ѐU�֏��W�v���o�^����(B-6)
 *  count_results_delete   ���ь����폜����(B-8)
 *  resource_sum           �c�ƈ����o�^����(B-19)
 *  count_customer         �ڋq�������W�v���o�^����(B-9)
 *  count_no_visit         ���K��q�������W�v���o�^����(B-10)
 *  count_no_trade         ������q�������W�v���o�^����(B-11)
 *  count_total_visit      �K����ь������W�v���o�^����(B-12)
 *  count_valid            ���L�����ь������W�v���o�^����(B-13)
 *  count_new_customer     �V�K�������W�v���o�^����(B-14)
 *  count_point            �V�K�l���E���i�|�C���g���W�v���o�^����(B-15)
 *  count_base_code_cust   ���_�v�ڋq�������W�v���o�^����(B-18)
 *  count_delete_invalidity�����؂�W�v�f�[�^�폜����(B-16)
 *  control_count          �e�팏���擾����(B-7)
 *  no_visit_control_cnt   ���K��q�����擾����(B-20)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   T.Nakabayashi    �V�K�쐬
 *  2009/01/27    1.0   T.Nakabayashi    �p�b�P�[�W���C�� XXCOS002A03C -> XXCOS002A032C
 *                                       �\�[�X���r���[�w�E�����C��
 *  2009/02/10    1.1   T.Nakabayashi    [COS_42]B-5 ����Q�W�v�����ɂĔ[�i�`�Ԃ��O���[�s���O�����ɓ����Ă����s����C��
 *  2009/02/20    1.2   T.Nakabayashi    get_msg�̃p�b�P�[�W���C��
 *                                       �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/26    1.3   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *                                       ���ʃ��O�w�b�_�o�͏��� �g�ݍ��ݘR��Ή�
 *  2009/04/28    1.4   K.Kiriu          [T1_0482]�K��f�[�^���o��������Ή�
 *                                       [T1_0718]�V�K�l���|�C���g�����ǉ��Ή�
 *                                       [T1_1146]�Q�R�[�h�擾�����s���Ή�
 *  2009/05/26    1.5   K.Kiriu          [T1_1213]�ڋq�����J�E���g�����}�X�^���������C��
 *  2009/08/31    1.6   K.Kiriu          [0000929]�K�⌬��/�L���K�⌏���̃J�E���g���@�ύX
 *  2009/09/04    1.7   K.Kiriu          [0000900]PT�Ή�
 *  2009/10/30    1.8   M.Sano           [0001373]XXCOS_RS_INFO_V�ύX�ɔ���PT�Ή�
 *  2009/11/12    1.9   N.Maeda          [E_T4_00188]�V�K�l���|�C���g�W�v�����C��
 *  2009/11/18    1.10  T.Nishikawa      [E_�{��_00220]���\�򉻂ɔ����q���g��ǉ�
 *  2009/11/24    1.11  K.Atsushiba      [E_�{��_00347]PT�Ή�
 *  2010/01/19    1.12  T.Nakano         [E_�{�ғ�_01039]�Ή� �V�K�|�C���g���ǉ�
 *  2010/04/16    1.13  D.Abe            [E_�{�ғ�_02270]�Ή� ���_�v�ڋq������ǉ�
 *  2010/05/18    1.14  D.Abe            [E_�{�ғ�_02767]�Ή� PT�Ή��ixxcos_rs_info2_v��ύX�j
 *  2010/12/14    1.15  K.Kiriu          [E_�{�ғ�_05671]�Ή� PT�Ή��i�L���K��r���[�̊֐����O�����ɂ���j
 *  2011/05/17    1.16  H.Sasaki         [E_�{�ғ�_07118]�Ή� �����̕�����s��
 *  2011/07/14    1.17  K.Kubo           [E_�{�ғ�_07885]�Ή� PT�Ή��i�^�X�N���2�������o�����j
 *  2012/12/27    1.18  K.Furuyama       [E_�{�ғ�_10190]�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�v���C�x�[�g�萔�錾�� START   #######################
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
--#######################  �Œ�v���C�x�[�g�ϐ��錾�� START   #######################
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
  exception_name          EXCEPTION;     -- <��O�̃R�����g>
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
  global_update_data_expt       EXCEPTION;
  --  *** �f�[�^�폜�G���[��O�n���h�� ***
  global_delete_data_expt       EXCEPTION;
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                   CONSTANT  VARCHAR2(100) := 'XXCOS002A032C';
--
  --  �A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE := 'XXCOS';
--
  --  �̕����b�Z�[�W
  --  ���b�N�擾�G���[���b�Z�[�W
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';
  --  �v���t�@�C���擾�G���[
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';
  --  �f�[�^�o�^�G���[
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';
  --  �f�[�^�X�V�G���[
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';
  --  �f�[�^�폜�G���[���b�Z�[�W
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';
  --  �Ɩ����t�擾�G���[
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014';
  --  API�ďo�G���[���b�Z�[�W
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00017';
  --  ����0���p���b�Z�[�W
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00018';
  --  �r�u�e�N���`�o�h
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00041';
  --  �v���h�c
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00042';
/* 2012/12/27 Ver1.18 add Start */
  --  �擾�G���[
  ct_msg_get_data_err           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';
/* 2012/12/27 Ver1.18 add End */
--
  --  �@�\�ŗL���b�Z�[�W
  --  �c�Ɛ��ѕ\ �W�v�����p�����[�^�o��
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10552';
  --  �c�Ɛ��ѕ\ �V�K�v������W�v��������
  ct_msg_count_new_cust         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10553';
  --  �c�Ɛ��ѕ\ �ƑԁE�[�i�`�ԕʔ̔����яW�v��������
  ct_msg_count_sales            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10554';
  --  �c�Ɛ��ѕ\ �ƑԁE�[�i�`�ԕʎ��ѐU�֏W�v��������
  ct_msg_count_transfer         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10555';
  --  �c�Ɛ��ѕ\ �c�ƈ��ʁE����Q�ʔ̔����яW�v��������
  ct_msg_count_s_group_sales    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10556';
  --  �c�Ɛ��ѕ\ �c�ƈ��ʁE����Q�ʎ��ѐU�֏W�v��������
  ct_msg_count_s_group_transfer CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10557';
  --  �c�Ɛ��ѕ\ ���яW�v��������
  ct_msg_count_reslut           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10558';
  --  �c�Ɛ��ѕ\ �����؂�W�v���폜����
  ct_msg_delete_invalidity      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10559';
/* 2011/05/17 Ver1.16 Add START */
  --  �c�Ɛ��ѕ\ ���K��q���W�v��������
  ct_msg_count_no_visit         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10591';
/* 2011/05/17 Ver1.16 Add END   */
  --  XXCOS:�ϓ��d�C���i�ڃR�[�h
  ct_msg_electric_fee_item_cd   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10572';
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  ct_msg_dummy_sales_group      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10573';
  --  XXCOS:�c�Ɛ��яW����ۑ�����
  ct_msg_002a03_keeping_period  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10574';
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:�^�X�N�X�e�[�^�XID�i�N���[�Y�j
  ct_msg_task_status_id         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10589';
  --  XXCSO:�K����уf�[�^���ʗp�^�X�N�^�C�v
  ct_msg_task_type_id           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10590';
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Add Start */
  --  XXCOS:��v����ID
  ct_msg_set_of_bks_id          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12755';
/* 2012/12/27 Ver1.18 Add End */
  --  �c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u��
  ct_msg_newcust_tbl            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10575';
  --  �c�Ɛ��ѕ\ ������яW�v�e�[�u��
  ct_msg_sales_sum_tbl          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10576';
  --  �c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u��
  ct_msg_s_group_sum_tbl        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10577';
  --  �c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u��
  ct_msg_cust_counter_tbl       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10578';
/* 2010/05/18 Ver1.14 Add Start */
  --  �c�Ɛ��ѕ\ �c�ƈ����ꎞ�\�e�[�u��
  ct_msg_resource_sum_tbl       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10588';
/* 2010/05/18 Ver1.14 Add End   */
/* 2011/07/14 Ver1.17 Add START */
  --  �c�Ɛ��ѕ\ �^�X�N�Q�����ێ��e�[�u��
  ct_msg_jtf_task_tbl           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10593';
  --  �c�Ɛ��ѕ\ �^�X�N���2�������o��������
  ct_msg_count_ins_tasks        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10592';
/* 2011/07/14 Ver1.17 Add END   */
  --  ���̓p�����[�^
  ct_msg_para_in                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10579';
  --  ���s�p�����[�^
  ct_msg_para_exec              CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10580';
  --  ���s�G���[���b�Z�[�W
  ct_msg_error                  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10581';
  --  �R�~�b�g���b�Z�[�W
  ct_msg_commit                 CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10582';
--
  --  �v���t�@�C������
  --  XXCOS:�ϓ��d�C���i�ڃR�[�h
  ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
--
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  ct_prof_dummy_sales_group
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DUMMY_SALES_GROUP_CODE';
--
  --  XXCOS:�c�Ɛ��яW����ۑ�����
  ct_prof_002a03_keeping_period
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
--
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:�^�X�N�X�e�[�^�XID�i�N���[�Y�j
  ct_prof_task_status_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCSO1_TASK_STATUS_CLOSED_ID';
--
  --  XXCSO:�K����уf�[�^���ʗp�^�X�N�^�C�v
  ct_prof_taks_type_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCSO1_TASK_TYPE_VISIT';
/* 2010/12/14 Ver1.15 Add Start */
/* 2012/12/27 Ver1.18 Add Start */
  -- GL��v����ID
  ct_prof_gl_set_of_bks_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
/* 2012/12/27 Ver1.18 Add End */
  --  �N�C�b�N�R�[�h�i�ڋq�����J�E���g�����}�X�^�j
  ct_qct_customer_count_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CUSTOMER_COUNT';
--
  --  �N�C�b�N�R�[�h�i�l���i�ځj
  ct_qct_discount_item_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DISCOUNT_ITEM_CODE';
--
  --  �N�C�b�N�R�[�h�i�[�i�`�[�敪�j
  ct_qct_dlv_slip_cls_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DELIVERY_SLIP_CLASS';
--
  --  �N�C�b�N�R�[�h�i����敪�j
  ct_qct_sale_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
--
  --  �N�C�b�N�R�[�h�i�V�K�����p  �ڋq�X�e�[�^�X�j
  ct_qct_new_cust_status_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_STATUS_MST_002_A03';
  ct_qcc_new_cust_status_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  �N�C�b�N�R�[�h�i�V�K�����p  �ڋq�敪�j
  ct_qct_new_cust_class_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_CLASS_MST_002_A03';
  ct_qcc_new_cust_class_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  �N�C�b�N�R�[�h�i�V�K�����p  �V�K�|�C���g�敪�j
  ct_qct_new_cust_point_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_POINT_MST_002_A03';
  ct_qcc_new_cust_point_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  �N�C�b�N�R�[�h�i�ڋq�X�e�[�^�X  �l�b���ʗp�j
  ct_qct_mc_cust_status_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_STATUS_MST_002_A03';
  ct_qcc_mc_cust_status_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_MC%';
--
  --  �N�C�b�N�R�[�h�i�u�c���ʗp  �Ƒԏ����ށj
  ct_qct_gyotai_sho_mst_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A03';
  ct_qcc_gyotai_sho_mst_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03%';
--
  --  Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --  �p�����[�^���t�w�菑��
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --  ���b�Z�[�W�p������
  --  �v���t�@�C����
  cv_str_profile_nm             CONSTANT  VARCHAR2(020) := 'profile_name';
--
  --  �g�[�N��
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
  --  �Ɩ����t
  cv_tkn_para_process_date      CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  �����敪
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(020) := 'PARAM2';
  --  �o�^����
  cv_tkn_insert_count           CONSTANT  VARCHAR2(020) := 'INSERT_COUNT';
  --  �X�V����
  cv_tkn_update_count           CONSTANT  VARCHAR2(020) := 'UPDATE_COUNT';
  --  �폜����
  cv_tkn_delete_count           CONSTANT  VARCHAR2(020) := 'DELETE_COUNT';
  --  ���яW�v�����Ώ۔N��
  cv_tkn_object_years           CONSTANT  VARCHAR2(020) := 'OBJECT_YEARS';
  --  �ۑ�����
  cv_tkn_keeping_period         CONSTANT  VARCHAR2(020) := 'KEEPING_PERIOD';
  --  �����؂�폜��N��
  cv_tkn_deletion_object        CONSTANT  VARCHAR2(020) := 'DELETION_OBJECT';
  --  �V�K�v������W�v���폜����
  cv_tkn_new_contribution       CONSTANT  VARCHAR2(020) := 'NEW_CONTRIBUTION';
  --  �ƑԁE�[�i�`�ԏW�v���폜����
  cv_tkn_business_conditions    CONSTANT  VARCHAR2(020) := 'BUSINESS_CONDITIONS';
  --  ����Q�W�v���폜����
  cv_tkn_policy_group           CONSTANT  VARCHAR2(020) := 'POLICY_GROUP';
  --  �e�팏���W�v���폜����
  cv_tkn_counter                CONSTANT  VARCHAR2(020) := 'COUNTER';
/* 2012/12/27 Ver1.18 add Start */
  -- �擾���ږ���
  cv_tkn_data                   CONSTANT  VARCHAR2(020) := 'DATA';
/* 2012/12/27 Ver1.18 add End */
--
  --  �p�����[�^���ʗp
  --  �S��
  cv_para_cls_all               CONSTANT  VARCHAR2(1) := '0';
  --  �V�K�v��������я��W�v���o�^����
  cv_para_cls_new_cust_sales    CONSTANT  VARCHAR2(1) := '1';
  --  �ƑԁE�[�i�`�ԕʔ̔����я��W�v���o�^����
  cv_para_cls_sales_sum         CONSTANT  VARCHAR2(1) := '2';
  --  �ƑԁE�[�i�`�ԕʎ��ѐU�֏��W�v���o�^����
  cv_para_cls_transfer_sum      CONSTANT  VARCHAR2(1) := '3';
  --  �c�ƈ��ʁE����Q�ʔ̔����я��W�v���o�^����
  cv_para_cls_s_group_sum_sales CONSTANT  VARCHAR2(1) := '4';
  --  �c�ƈ��ʁE����Q�ʎ��ѐU�֏��W�v���o�^����
  cv_para_cls_s_group_sum_trans CONSTANT  VARCHAR2(1) := '5';
  --  �e�팏���擾����
  cv_para_cls_control_count     CONSTANT  VARCHAR2(1) := '6';
/* 2011/05/17 Ver1.16 Add START */
  --  ���K��q�����i�O���j�擾����
  cv_para_no_visit_last_month   CONSTANT  VARCHAR2(1) := '7';
  --  ���K��q�����i�����j�擾����
  cv_para_no_visit_this_month   CONSTANT  VARCHAR2(1) := '8';
/* 2011/05/17 Ver1.16 Add END   */
/* 2011/07/14 Ver1.17 Add START */
  --  �^�X�N���2�������o����
  cv_para_ins_tasks             CONSTANT  VARCHAR2(1) := '9';
/* 2011/07/14 Ver1.17 Add END   */
--
  --  ��v���
  --  �`�q
  cv_ar_class                   CONSTANT  VARCHAR2(2) := '02';
  --  �I�[�v��
  cv_open                       CONSTANT  VARCHAR2(4) := 'OPEN';
/* 2012/12/27 Ver1.18 Add Start */
  --  �N���[�Y
  cv_close                      CONSTANT  VARCHAR2(5) := 'CLOSE';
  cv_gl                         CONSTANT  VARCHAR2(5) := 'SQLGL';
/* 2012/12/27 Ver1.18 Add End */
--
  --  �[�i�`�[�敪
  --  �[�i
  cv_cls_dlv_dff1_dlv           CONSTANT  VARCHAR2(1) := '1';
  --  �ԕi
  cv_cls_dlv_dff1_rtn           CONSTANT  VARCHAR2(1) := '2';
--
  --  �ڋq�敪
  --  ���_
  ct_cust_class_base            CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '1';
  --  �ڋq
  ct_cust_class_customer        CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '10';
/* 2009/05/26 Ver1.5 Start */
  -- �K��Ώۋ敪
  -- �K��Ώ�
  ct_vist_target_div_yes        CONSTANT xxcmm_cust_accounts.vist_target_div%TYPE := '1';
  -- ������ѐU��
  -- �U�ւȂ�
  ct_selling_transfer_div_no    CONSTANT xxcmm_cust_accounts.selling_transfer_div%TYPE := '*';
/* 2009/05/26 Ver1.5 End   */
  --  �^�X�N
  --  �p�[�e�B
  ct_task_obj_type_party        CONSTANT  jtf_tasks_b.source_object_type_code%TYPE := 'PARTY';
  --  �c�ƈ�
  ct_task_own_type_employee     CONSTANT  jtf_tasks_b.owner_type_code%TYPE := 'RS_EMPLOYEE';
  --  �L���K��敪(�^�X�N)
  --  �K��
  cv_task_dff11_visit           CONSTANT  VARCHAR2(1) := '0';
  --  �L��
  cv_task_dff11_valid           CONSTANT  VARCHAR2(1) := '1';
  --  �o�^�敪(�^�X�N)
  --  �K��̂�
  cv_task_dff12_only_visit      CONSTANT  VARCHAR2(1) := '1';
  --  �̔��U�֋敪
  --  �̔�����
  ct_sales_sum_sales            CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '0';
  --  ���ѐU��
  ct_sales_sum_transfer         CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '1';
  --  �f�[�^�敪(�V�K�l���|�C���g�ڋq�ʗ����e�[�u��)
  --  ���i
  ct_point_data_cls_qualifi     CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '0';
  --  �V�K�l��
  ct_point_data_cls_new_cust    CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '1';
  --  �Y��iFixture and furniture�j
  ct_point_data_cls_f_and_f     CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '2';
/* 2010/01/19 Ver1.12 Add Start */
  --  �Y��Ԃ牺����iFixture and furniture burasagari�j
  ct_point_data_cls_f_and_f_bur CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '3';
/* 2010/01/19 Ver1.12 Add End   */
/* 2009/04/28 Ver1.4 Add Start */
  --  �V�K�]���Ώۋ敪(�V�K�l���|�C���g�ڋq�ʗ����e�[�u��)
  --  �B��
  ct_evaluration_kbn_acvmt      CONSTANT  xxcsm_new_cust_point_hst.evaluration_kbn%TYPE := '0';
/* 2009/04/28 Ver1.4 Add End   */
/* 2011/05/17 Ver1.16 Add START */
  --  �ďo���v���V�[�W������R�[�h
  cv_process_1                  CONSTANT VARCHAR2(1)  :=  '1';      --  B-7.�e�팏���擾����
  cv_process_2                  CONSTANT VARCHAR2(1)  :=  '2';      --  B-20.���K��q�����擾����
/* 2011/05/17 Ver1.16 Add END   */
--
  --  �����敪
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
/* 2010/04/16 Ver1.13 Add Start */
  --  ���_�v�ڋq����
  ct_counter_cls_base_code_cust CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '12';
/* 2010/04/16 Ver1.13 Add End   */
--
  --  AR��v���i�[�p�z��C���f�b�N�X
  --  �O��
  cn_last_month                 CONSTANT  PLS_INTEGER := 1;
  --  ����
  cn_this_month                 CONSTANT  PLS_INTEGER := 2;
--
  --  ���������J�E���g�p�z��C���f�b�N�X
  --  �V�K�v������
  cn_counter_newcust_sum        CONSTANT  PLS_INTEGER := 1;
  --  �ƑԁE�[�i�`�ԕʔ̔�����
  cn_counter_sales_sum          CONSTANT  PLS_INTEGER := 2;
  --  �ƑԁE�[�i�`�ԕʎ��ѐU��
  cn_counter_transfer_sum       CONSTANT  PLS_INTEGER := 3;
  --  �c�ƈ��ʁE����Q�ʔ̔�����
  cn_counter_s_group_sum_sales  CONSTANT  PLS_INTEGER := 4;
  --  �c�ƈ��ʁE����Q�ʎ��ѐU��
  cn_counter_s_group_sum_trans  CONSTANT  PLS_INTEGER := 5;
  --  �e�팏���i�����j
  cn_counter_count_sum          CONSTANT  PLS_INTEGER := 6;
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�^
  --  ===============================
  --  AR��v���i�[�p
  TYPE g_account_info_rec IS RECORD
    (
      --  ��v���
      base_date                           DATE,
      --  ��v��N��(yyyymm)
      base_years                          VARCHAR(6),
      --  ��v�X�e�[�^�X
      status                              VARCHAR(5),
      --  ��v���ԊJ�n��
      from_date                           DATE,
      --  ��v���ԏI����
      to_date                             DATE,
      --  ��v�N�x�J�n��
      account_period_start                DATE,
      --  ��v�N�x�I����
      account_period_end                  DATE
    );
  TYPE g_account_info_ttype IS TABLE OF g_account_info_rec INDEX BY PLS_INTEGER;
--
  --  ���������J�E���g�p
  TYPE g_counter_rec IS RECORD
    (
      --  �o�^����
      insert_counter                      PLS_INTEGER := 0,
      --  ���o����
      select_counter                      PLS_INTEGER := 0,
      --  �X�V����
      update_counter                      PLS_INTEGER := 0,
      --  �폜����
      delete_counter                      PLS_INTEGER := 0,
      --  �����؂�폜����
      delete_counter_invalidity           PLS_INTEGER := 0
    );
  TYPE g_counter_ttype IS TABLE OF g_counter_rec INDEX BY PLS_INTEGER;
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�ϐ�
  --  ===============================
  --  ���s�p�����[�^
  --  �Ɩ����t
  gd_process_date                         DATE;
  --  �����敪
  gv_processing_class                     VARCHAR2(1);
--
  --  �v���t�@�C���i�[�p
  --  XXCOS:�ϓ��d�C���i�ڃR�[�h
  gt_prof_electric_fee_item_cd            fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:�_�~�[�c�ƃO���[�v�R�[�h
  gt_prof_dummy_sales_group               fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:�c�Ɛ��яW����ۑ�����
  gt_prof_002a03_keeping_period           fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:�^�X�N�X�e�[�^�XID�i�N���[�Y�j
  gt_prof_task_status_id                  jtf_tasks_b.task_status_id%TYPE;
  --  XXCSO:�K����уf�[�^���ʗp�^�X�N�^�C�vF
  gt_prof_task_type_id                    jtf_tasks_b.task_type_id%TYPE;
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Add Start */
  -- GL��v����ID
  gt_set_of_bks_id                        gl_sets_of_books.set_of_books_id%TYPE;
/* 2012/12/27 Ver1.18 Add End */
--
  --  AR��v���i�[�p
  g_account_info_tab                      g_account_info_ttype;
  --  ��v�N�x�J�n��
  gd_account_period_start                 DATE;
  --  ��v�N�x�I����
  gd_account_period_end                   DATE;
--
  --  ���������J�E���g�p
  g_counter_tab                           g_counter_ttype;
--
  --  ===============================
  --  ���[�U�[��`�v���C�x�[�g�E�J�[�\��
  --  ===============================
  --  ���������b�N�擾�p�i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
  CURSOR  lock_bus_newcust_sum_cur      (
                                        icp_regist_bus_date     xxcos_rep_bus_newcust_sum.regist_bus_date%TYPE
                                        )
  IS
    SELECT  rbns.ROWID                  AS  rbns_rowid
    FROM    xxcos_rep_bus_newcust_sum   rbns
    WHERE   rbns.regist_bus_date        =   icp_regist_bus_date
    FOR UPDATE NOWAIT
    ;
--
  --  ���������b�N�擾�p�i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
  CURSOR  lock_bus_sales_sum_cur        (
                                        icp_regist_bus_date     xxcos_rep_bus_sales_sum.regist_bus_date%TYPE,
                                        icp_sales_transfer_div  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE
                                        )
  IS
    SELECT  rbss.ROWID                  AS  rbss_rowid
    FROM    xxcos_rep_bus_sales_sum     rbss
    WHERE   rbss.regist_bus_date        =   icp_regist_bus_date
    AND     rbss.sales_transfer_div     =   icp_sales_transfer_div
    FOR UPDATE NOWAIT
    ;
--
  --  ���������b�N�擾�p�i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
  CURSOR  lock_bus_s_group_sum_cur      (
                                        icp_regist_bus_date     xxcos_rep_bus_s_group_sum.regist_bus_date%TYPE,
                                        icp_sales_transfer_div  xxcos_rep_bus_s_group_sum.sales_transfer_div%TYPE
                                        )
  IS
    SELECT  rbsg.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_s_group_sum   rbsg
    WHERE   rbsg.regist_bus_date        =   icp_regist_bus_date
    AND     rbsg.sales_transfer_div     =   icp_sales_transfer_div
    FOR UPDATE NOWAIT
    ;
--
  --  ���������b�N�擾�p�i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
  CURSOR  lock_rep_bus_count_sum_cur    (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            =   icp_target_date
/* 2011/05/17 Ver1.16 Add START */
    AND     rbcs.counter_class          <>  ct_counter_cls_no_visit
/* 2011/05/17 Ver1.16 Add END   */
    FOR UPDATE NOWAIT
    ;
/* 2011/05/17 Ver1.16 Add START */
  --  ���������b�N�擾�p�i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u��(���K��q���)�j
  CURSOR  lock_rep_bus_no_visit_cur     (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            =   icp_target_date
    AND     rbcs.counter_class          =   ct_counter_cls_no_visit
    FOR UPDATE NOWAIT
    ;
/* 2011/05/17 Ver1.16 Add END   */
--
  --  �����؂��񃍃b�N�擾�p�i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
  CURSOR  lock_newcust_invalidity_cur   (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbns.ROWID                  AS  rbns_rowid
    FROM    xxcos_rep_bus_newcust_sum   rbns
    WHERE   rbns.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  �����؂��񃍃b�N�擾�p�i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
  CURSOR  lock_sales_invalidity_cur     (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbss.ROWID                  AS  rbss_rowid
    FROM    xxcos_rep_bus_sales_sum     rbss
    WHERE   rbss.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  �����؂��񃍃b�N�擾�p�i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
  CURSOR  lock_s_group_invalidity_cur   (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbsg.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_s_group_sum   rbsg
    WHERE   rbsg.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  �����؂��񃍃b�N�擾�p�i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
  CURSOR  lock_count_sum_invalidity_cur (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            <=  icp_target_date
    FOR UPDATE NOWAIT
    ;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_process_date     IN      VARCHAR2,         --  1.�Ɩ����t
    iv_processing_class IN      VARCHAR2,         --  2.�����敪
    ov_errbuf           OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
/* 2012/12/27 Ver1.18 Add Start */
    cv_last_gl_period      CONSTANT VARCHAR2(20)  := 'LAST MONTH GL PERIOD';
    cv_this_gl_period      CONSTANT VARCHAR2(20)  := 'THIS MONTH GL PERIOD';
    cv_o                   CONSTANT VARCHAR2(1)   := 'O';
/* 2012/12/27 Ver1.18 Add End */
--
--
    -- *** ���[�J���ϐ� ***
    --�p�����[�^�o�͗p
    lv_para_note_in             VARCHAR2(5000);
    lv_para_note_exec           VARCHAR2(5000);
    lv_para_msg                 VARCHAR2(5000);
    lv_profile_name             VARCHAR2(5000);
    --
/* 2012/12/27 Ver1.18 Add Start */
    lt_closing_status           gl_period_statuses.closing_status%TYPE;   -- �X�e�[�^�X
    lt_close_date               gl_period_statuses.last_update_date%TYPE; -- �N���[�Y��(�ŏI�X�V��) 
    lv_tkn_data                 VARCHAR2(100);                            -- �g�[�N���l
/* 2012/12/27 Ver1.18 Add End */
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
/* 2012/12/27 Ver1.18 Add Start */
    -- *** ���[�J�����[�U�[��`��O ***
    -- �擾���s�G���[
    select_expt               EXCEPTION;
/* 2012/12/27 Ver1.18 Add End */
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
    lv_para_note_in := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_para_in
      );
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_note,
      iv_token_value1  =>  lv_para_note_in,
      iv_token_name2   =>  cv_tkn_para_process_date,
      iv_token_value2  =>  iv_process_date,
      iv_token_name3   =>  cv_tkn_para_processing_class,
      iv_token_value3  =>  iv_processing_class
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --  1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
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
      ,buff   => lv_para_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    --==================================
    -- 2.�Ɩ����t�擾
    --==================================
    --
    IF  ( iv_process_date IS NULL )  THEN
      gd_process_date := xxccp_common_pkg2.get_process_date;
      --  �擾���ʊm�F
      IF ( gd_process_date IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_process_date_err
          );
        lv_errbuf := ov_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      gd_process_date := TO_DATE(iv_process_date, cv_fmt_date_default);
    END IF;
--
    --  �����敪�Ɏw�肪�Ȃ��ꍇ�́u�S�āv���Z�b�g
    gv_processing_class := NVL(iv_processing_class, cv_para_cls_all);
--
    --==================================
    -- 3.XXCOS:�ϓ��d�C���i�ڃR�[�h
    --==================================
    gt_prof_electric_fee_item_cd := FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_electric_fee_item_cd IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_electric_fee_item_cd
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_electric_fee_item_cd);
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 4.XXCOS:�c�Ɛ��яW����ۑ�����
    --==================================
    gt_prof_002a03_keeping_period := FND_PROFILE.VALUE( ct_prof_002a03_keeping_period );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_prof_002a03_keeping_period IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_002a03_keeping_period
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_002a03_keeping_period);
      RAISE global_get_profile_expt;
    END IF;
--
/* 2010/12/14 Ver1.15 Add Start */
/* 2011/05/17 Ver1.16 Mod START */
    -- ���s�敪��'0'(�S��)��'6'(�e�팏���擾����)
    --  '7'(���K��q�����i�O���j�擾����)�A'8'(���K��q�����i�����j�擾����)�̏ꍇ
--    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_control_count ) ) THEN
    IF  ( gv_processing_class IN  (   cv_para_cls_all
                                    , cv_para_cls_control_count
                                    , cv_para_no_visit_last_month
                                    , cv_para_no_visit_this_month
                                  )
        )
    THEN
/* 2011/05/17 Ver1.16 Mod END   */
      --==================================
      -- 5.XXCSO:�^�X�N�X�e�[�^�XID�i�N���[�Y�j
      --==================================
      gt_prof_task_status_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_task_status_id ) );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gt_prof_task_status_id IS NULL ) THEN
        --�v���t�@�C����������擾
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_task_status_id
          );
--
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_task_status_id);
        RAISE global_get_profile_expt;
      END IF;
--
      --==================================
      -- 6.XXCSO:�K����уf�[�^���ʗp�^�X�N�^�C�v
      --==================================
      gt_prof_task_type_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_taks_type_id ) );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gt_prof_task_type_id IS NULL ) THEN
        --�v���t�@�C����������擾
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_task_type_id
          );
--
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_taks_type_id);
        RAISE global_get_profile_expt;
      END IF;
    END IF;
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Del Start */
--    --==================================
--    -- 7.AR��v���Ԏ擾(�O��) 8.�O���N���擾
--    --==================================
--    -- ���ʊ֐�����v���ԏ��擾��
--    g_account_info_tab(cn_last_month).base_date := LAST_DAY(ADD_MONTHS(gd_process_date, -1));
--    g_account_info_tab(cn_last_month).base_years := TO_CHAR(g_account_info_tab(cn_last_month).base_date, cv_fmt_years);
--    xxcos_common_pkg.get_account_period(
--      --  02:AR
--      cv_ar_class
--      --  ���
--      ,g_account_info_tab(cn_last_month).base_date
--      --  �X�e�[�^�X(OPEN or CLOSE)
--      ,g_account_info_tab(cn_last_month).status
--      --  ��v�iFROM�j
--      ,g_account_info_tab(cn_last_month).from_date
--      --  ��v�iTO�j
--      ,g_account_info_tab(cn_last_month).to_date
--      --  �G���[�E���b�Z�[�W
--      ,lv_errbuf
--      --  ���^�[���E�R�[�h
--      ,lv_retcode
--      --  ���[�U�[�E�G���[�E���b�Z�[�W
--      ,lv_errmsg
--      );
--    --  ���^�[���R�[�h�m�F
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      ov_errmsg := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2012/12/27 Ver1.18 Del End */
/* 2012/12/27 Ver1.18 Add Start */
--    --==================================
--    -- 7.GL��v���Ԏ擾(�O��) 8.�O���N���擾
--    --==================================
      -- GL��v����ID�擾
      gt_set_of_bks_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gt_set_of_bks_id IS NULL ) THEN
        --�v���t�@�C����������擾
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_set_of_bks_id
          );
        --
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_gl_set_of_bks_id);
        RAISE global_get_profile_expt;
      END IF;
--
    --�O����v���ԏ��擾
    g_account_info_tab(cn_last_month).base_date  := LAST_DAY(ADD_MONTHS(gd_process_date, -1));
    g_account_info_tab(cn_last_month).base_years := TO_CHAR(g_account_info_tab(cn_last_month).base_date, cv_fmt_years);
    --
    BEGIN
      SELECT gps.closing_status      closing_status
            ,gps.start_date          start_date
            ,gps.end_date            end_date
            ,gps.last_update_date    last_update_date
      INTO   lt_closing_status                               --  �X�e�[�^�X
            ,g_account_info_tab(cn_last_month).from_date     --  ��v�iFROM�j
            ,g_account_info_tab(cn_last_month).to_date       --  ��v�iTO�j
            ,lt_close_date                                   --  �N���[�Y��(�ŏI�X�V��) 
      FROM   gl_period_statuses  gps
           , fnd_application     fa
      WHERE  gps.application_id           = fa.application_id                            -- �A�v���P�[�V����ID����v
      AND    fa.application_short_name    = cv_gl                                        -- �A�v���P�[�V�����Z�k��
      AND    gps.set_of_books_id          = gt_set_of_bks_id                             -- ��v����ID����v
      AND    gps.adjustment_period_flag   = cv_no                                        -- �����t���O��'N'
      AND    gps.start_date              <= g_account_info_tab(cn_last_month).base_date  -- �J�n��������
      AND    gps.end_date                >= g_account_info_tab(cn_last_month).base_date  -- ������������
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_data := cv_last_gl_period;
        RAISE select_expt;
    END;
    -- �O����v���ԏ��D��v�X�e�[�^�X�̐ݒ�
    -- GL��v���Ԃ��I�[�v�����Ă���ꍇ
    IF lt_closing_status = cv_o THEN
      g_account_info_tab(cn_last_month).status := cv_open;
    -- GL��v���Ԃ��N���[�Y���Ă���ꍇ
    ELSE
      -- �N���[�Y��(�ŏI�X�V��) = �Ɩ����t
      IF TRUNC(lt_close_date) = TRUNC(gd_process_date) THEN
        g_account_info_tab(cn_last_month).status := cv_open;
      -- �N���[�Y��(�ŏI�X�V��) <> �Ɩ����t
      ELSE
        g_account_info_tab(cn_last_month).status := cv_close;
      END IF;
    END IF;
/* 2012/12/27 Ver1.18 Add End */
--
/* 2012/12/27 Ver1.18 Del Start */
--    --==================================
--    -- 9.AR��v���Ԏ擾(����) 10.�����N���擾
--    --==================================
--    -- ���ʊ֐�����v���ԏ��擾��
--    g_account_info_tab(cn_this_month).base_date := gd_process_date;
--    g_account_info_tab(cn_this_month).base_years := TO_CHAR(g_account_info_tab(cn_this_month).base_date, cv_fmt_years);
--    xxcos_common_pkg.get_account_period(
--      --  02:AR
--      cv_ar_class
--      --  ���
--      ,g_account_info_tab(cn_this_month).base_date
--      --  �X�e�[�^�X(OPEN or CLOSE)
--      ,g_account_info_tab(cn_this_month).status
--      --  ��v�iFROM�j
--      ,g_account_info_tab(cn_this_month).from_date
--      --  ��v�iTO�j
--      ,g_account_info_tab(cn_this_month).to_date
--      --  �G���[�E���b�Z�[�W
--      ,lv_errbuf
--      --  ���^�[���E�R�[�h
--      ,lv_retcode
--      --  ���[�U�[�E�G���[�E���b�Z�[�W
--      ,lv_errmsg
--      );
--    --  ���^�[���R�[�h�m�F
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      ov_errmsg := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2012/12/27 Ver1.18 Del End */
/* 2012/12/27 Ver1.18 Add Start */
    --==================================
    -- 9.GL��v���Ԏ擾(����) 10.�����N���擾
    --==================================
    --������v���ԏ��擾
    g_account_info_tab(cn_this_month).base_date := gd_process_date;
    g_account_info_tab(cn_this_month).base_years := TO_CHAR(g_account_info_tab(cn_this_month).base_date, cv_fmt_years);
    --
    BEGIN
      SELECT DECODE(gps.closing_status,cv_o,cv_open,cv_close)      closing_status
            ,gps.start_date          start_date
            ,gps.end_date            end_date
      INTO   g_account_info_tab(cn_this_month).status          --  �X�e�[�^�X
            ,g_account_info_tab(cn_this_month).from_date       --  ��v�iFROM�j
            ,g_account_info_tab(cn_this_month).to_date         --  ��v�iTO�j
      FROM   gl_period_statuses    gps
           , fnd_application       fa
      WHERE  gps.application_id           = fa.application_id                            -- �A�v���P�[�V����ID����v
      AND    fa.application_short_name    = cv_gl                                        -- �A�v���P�[�V�����Z�k��
      AND    gps.set_of_books_id          = gt_set_of_bks_id                             -- ��v����ID����v
      AND    gps.adjustment_period_flag   = cv_no                                        -- �����t���O��'N'
      AND    gps.start_date              <= g_account_info_tab(cn_this_month).base_date  -- �J�n��������
      AND    gps.end_date                >= g_account_info_tab(cn_this_month).base_date  -- ������������
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_data := cv_this_gl_period;
        RAISE select_expt;
    END;
/* 2012/12/27 Ver1.18 Add End */
--
/*
    --==================================
    -- 9.��v�N�x���Ԏ擾
    --==================================
    xxcos_common_pkg.get_period_year(
      --  �쐬�N��
      gd_process_date
      --  ��v�J�n��
      ,gd_account_period_start
      --  ��v�I����
      ,gd_account_period_end
      --  �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_errbuf
      --  ���^�[���E�R�[�h             --# �Œ� #
      ,lv_retcode
      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,lv_errmsg
      );
    --  ���^�[���R�[�h�m�F
    IF ( lv_retcode <> cv_status_normal ) THEN
      ov_errmsg := lv_errmsg;
      RAISE global_api_expt;
    END IF;
*/
--
    --==================================
    -- 11.��v�N�x���Ԏ擾
    --==================================
    <<get_account_period>>
    FOR lp_idx IN g_account_info_tab.FIRST..g_account_info_tab.LAST LOOP
      xxcos_common_pkg.get_period_year(
        --  ���
        g_account_info_tab(lp_idx).base_date
        --  ��v�J�n��
        ,g_account_info_tab(lp_idx).account_period_start
        --  ��v�I����
        ,g_account_info_tab(lp_idx).account_period_end
        --  �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_errbuf
        --  ���^�[���E�R�[�h             --# �Œ� #
        ,lv_retcode
        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ,lv_errmsg
        );
      --  ���^�[���R�[�h�m�F
      IF ( lv_retcode <> cv_status_normal ) THEN
        ov_errmsg := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END LOOP  get_account_period;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
/* 2012/12/27 Ver1.18 add Start */
    --*** �擾���s�G���[ ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => ct_msg_get_data_err           -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_data                   -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_data                   -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
/* 2012/12/27 Ver1.18 add End */
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
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O ***
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
/* 2011/07/14 Ver1.17 Add START */
  /**********************************************************************************
   * Procedure Name   : ins_jtf_tasks
   * Description      : �^�X�N���2�������o����(B-21)
   ***********************************************************************************/
  PROCEDURE ins_jtf_tasks(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_jtf_tasks'; -- �v���O������
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
    ld_ar_from_date    DATE;
    ln_ins_task_count  NUMBER;
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
    -- 1.�������s����
    --==================================
    --  �����敪�u0:�S�āv�u9:�^�X�N���2�������o�����v�̏ꍇ�A���������{
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_ins_tasks ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.��v���ԃI�[�v�������擾
    --==================================
    -- �O���̉�v�X�e�[�^�X��OPEN�Ȃ�A�O���̊J�n��
    IF (g_account_info_tab(cn_last_month).status = cv_open) THEN
      ld_ar_from_date := g_account_info_tab(cn_last_month).from_date;
    -- �O���̉�v�X�e�[�^�X��CLOSE�Ȃ�A�����̊J�n��
    ELSE
      ld_ar_from_date := g_account_info_tab(cn_this_month).from_date;
    END IF;
--
    --==================================
    -- 3.�폜����
    --==================================
    BEGIN
--
      -- �Ώۃe�[�u����S���폜
      EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCOS.XXCOS_JTF_TASKS_B';
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_jtf_task_tbl             -- �c�Ɛ��ѕ\ �^�X�N�Q�����ێ��e�[�u��
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --==================================
    -- 4.�o�^����
    --==================================
    BEGIN
      -- �^�X�N�Q�����ێ��e�[�u���Ƀ^�X�N�f�[�^��o�^
      INSERT INTO xxcos_jtf_tasks_b(
        task_id,                              -- �^�X�NID
        created_by,                           -- �쐬��
        creation_date,                        -- �쐬��
        last_updated_by,                      -- �ŏI�X�V��
        last_update_date,                     -- �ŏI�X�V��
        last_update_login,                    -- �ŏI�X�V���O�C��
        object_version_number,                -- �I�u�W�F�N�g�o�[�W�����ԍ�
        task_number,                          -- �^�X�N�ԍ�
        task_type_id,                         -- �^�X�N�^�C�vID
        task_status_id,                       -- �^�X�N�X�e�[�^�XID
        task_priority_id,                     -- �^�X�N�D��ID
        owner_id,                             -- ���L��ID
        owner_type_code,                      -- ���L�҃^�C�v�R�[�h
        owner_territory_id,                   -- ���L�ҋ��ID
        assigned_by_id,                       -- ������ID
        cust_account_id,                      -- �A�J�E���gID
        customer_id,                          -- �ڋqID
        address_id,                           -- �A�h���XID
        planned_start_date,                   -- �v��J�n��
        planned_end_date,                     -- �v��I����
        scheduled_start_date,                 -- �\��J�n��
        scheduled_end_date,                   -- �\��I����
        actual_start_date,                    -- ���ъJ�n��
        actual_end_date,                      -- ���яI����
        source_object_type_code,              -- �\�[�X�I�u�W�F�N�g�^�C�v�R�[�h
        timezone_id,                          -- ����ID
        source_object_id,                     -- �\�[�X�I�u�W�F�N�gID
        source_object_name,                   -- �\�[�X�I�u�W�F�N�g��
        duration,                             -- ����
        duration_uom,                         -- �����P��
        planned_effort,                       -- �����v��
        planned_effort_uom,                   -- �����v��P��
        actual_effort,                        -- ��������
        actual_effort_uom,                    -- �������ђP��
        percentage_complete,                  -- �i����
        reason_code,                          -- ���R�R�[�h
        private_flag,                         -- �v���C�x�[�g�t���O
        publish_flag,                         -- ���s�t���O
        restrict_closure_flag,                -- �������t���O
        multi_booked_flag,                    -- �}���`�\��t���O
        milestone_flag,                       -- �}�C���X�g�[���t���O
        holiday_flag,                         -- �x���t���O
        billable_flag,                        -- �����\�t���O
        bound_mode_code,                      -- �o�E���h���[�h�R�[�h
        soft_bound_flag,                      -- �\�t�g�o�E���h�t���O
        workflow_process_id,                  -- ���[�N�t���[�v���Z�XID
        notification_flag,                    -- �ʒm�t���O
        notification_period,                  -- �ʒm����
        notification_period_uom,              -- �ʒm���ԒP��
        parent_task_id,                       -- �e�^�X�NID
        recurrence_rule_id,                   -- �Ĕ��K��ID
        alarm_start,                          -- �x���J�n
        alarm_start_uom,                      -- �x���J�n�P��
        alarm_on,                             -- �x����
        alarm_count,                          -- �x���J�E���g
        alarm_fired_count,                    -- ���ٌx���J�E���g
        alarm_interval,                       -- �x���Ԋu
        alarm_interval_uom,                   -- �x���Ԋu�P��
        deleted_flag,                         -- �폜�σt���O
        palm_flag,                            -- �G���t���O
        wince_flag,                           -- �E�B���X�t���O
        laptop_flag,                          -- ���b�v�g�b�v�t���O
        device1_flag,                         -- �f�o�C�X�P
        device2_flag,                         -- �f�o�C�X�Q
        device3_flag,                         -- �f�o�C�X�R
        costs,                                -- �o��
        currency_code,                        -- �ʉ݃R�[�h
        org_id,                               -- �g�DID
        escalation_level,                     -- �G�X�J���[�V�������x��
        attribute1,                           -- �K��敪�P
        attribute2,                           -- �K��敪�Q
        attribute3,                           -- �K��敪�R
        attribute4,                           -- �K��敪�S
        attribute5,                           -- �K��敪�T
        attribute6,                           -- �K��敪�U
        attribute7,                           -- �K��敪�V
        attribute8,                           -- �K��敪�W
        attribute9,                           -- �K��敪�X
        attribute10,                          -- �K��敪�P�O
        attribute11,                          -- �L���K��敪
        attribute12,                          -- �o�^���敪
        attribute13,                          -- �o�^���\�[�X�ԍ�
        attribute14,                          -- �ڋq�X�e�[�^�X
        attribute15,                          --
        attribute_category,                   -- ��������
        security_group_id,                    -- �Z�L�����e�B�O���[�vID
        orig_system_reference,                -- �I���W�i���V�X�e�����t�@�����X
        orig_system_reference_id,             -- �I���W�i���V�X�e�����t�@�����XID
        update_status_flag,                   -- �X�e�[�^�X�X�V�t���O
        calendar_start_date,                  -- �J�����_�[�J�n��
        calendar_end_date,                    -- �J�����_�[�I����
        date_selected,                        -- �I���
        template_id,                          -- �e���v���[�gID
        template_group_id,                    -- �e���v���[�g�O���[�vID
        object_changed_date,                  -- �I�u�W�F�N�g�ύX��
        task_confirmation_status,             -- �^�X�N�m�F�J�n
        task_confirmation_counter,            -- �^�X�N�m�F�J�E���^�[
        task_split_flag,                      -- �^�X�N�����t���O
        open_flag,                            -- �I�[�v���t���O
        entity,                               -- ����
        child_position,                       -- �q�|�W�V����
        child_sequence_num                    -- �q�V�[�P���X�ԍ�
      )
      (SELECT task_id,                        -- �^�X�NID
              created_by,                     -- �쐬��
              creation_date,                  -- �쐬��
              last_updated_by,                -- �ŏI�X�V��
              last_update_date,               -- �ŏI�X�V��
              last_update_login,              -- �ŏI�X�V���O�C��
              object_version_number,          -- �I�u�W�F�N�g�o�[�W�����ԍ�
              task_number,                    -- �^�X�N�ԍ�
              task_type_id,                   -- �^�X�N�^�C�vID
              task_status_id,                 -- �^�X�N�X�e�[�^�XID
              task_priority_id,               -- �^�X�N�D��ID
              owner_id,                       -- ���L��ID
              owner_type_code,                -- ���L�҃^�C�v�R�[�h
              owner_territory_id,             -- ���L�ҋ��ID
              assigned_by_id,                 -- ������ID
              cust_account_id,                -- �A�J�E���gID
              customer_id,                    -- �ڋqID
              address_id,                     -- �A�h���XID
              planned_start_date,             -- �v��J�n��
              planned_end_date,               -- �v��I����
              scheduled_start_date,           -- �\��J�n��
              scheduled_end_date,             -- �\��I����
              actual_start_date,              -- ���ъJ�n��
              actual_end_date,                -- ���яI����
              source_object_type_code,        -- �\�[�X�I�u�W�F�N�g�^�C�v�R�[�h
              timezone_id,                    -- ����ID
              source_object_id,               -- �\�[�X�I�u�W�F�N�gID
              source_object_name,             -- �\�[�X�I�u�W�F�N�g��
              duration,                       -- ����
              duration_uom,                   -- �����P��
              planned_effort,                 -- �����v��
              planned_effort_uom,             -- �����v��P��
              actual_effort,                  -- ��������
              actual_effort_uom,              -- �������ђP��
              percentage_complete,            -- �i����
              reason_code,                    -- ���R�R�[�h
              private_flag,                   -- �v���C�x�[�g�t���O
              publish_flag,                   -- ���s�t���O
              restrict_closure_flag,          -- �������t���O
              multi_booked_flag,              -- �}���`�\��t���O
              milestone_flag,                 -- �}�C���X�g�[���t���O
              holiday_flag,                   -- �x���t���O
              billable_flag,                  -- �����\�t���O
              bound_mode_code,                -- �o�E���h���[�h�R�[�h
              soft_bound_flag,                -- �\�t�g�o�E���h�t���O
              workflow_process_id,            -- ���[�N�t���[�v���Z�XID
              notification_flag,              -- �ʒm�t���O
              notification_period,            -- �ʒm����
              notification_period_uom,        -- �ʒm���ԒP��
              parent_task_id,                 -- �e�^�X�NID
              recurrence_rule_id,             -- �Ĕ��K��ID
              alarm_start,                    -- �x���J�n
              alarm_start_uom,                -- �x���J�n�P��
              alarm_on,                       -- �x����
              alarm_count,                    -- �x���J�E���g
              alarm_fired_count,              -- ���ٌx���J�E���g
              alarm_interval,                 -- �x���Ԋu
              alarm_interval_uom,             -- �x���Ԋu�P��
              deleted_flag,                   -- �폜�σt���O
              palm_flag,                      -- �G���t���O
              wince_flag,                     -- �E�B���X�t���O
              laptop_flag,                    -- ���b�v�g�b�v�t���O
              device1_flag,                   -- �f�o�C�X�P
              device2_flag,                   -- �f�o�C�X�Q
              device3_flag,                   -- �f�o�C�X�R
              costs,                          -- �o��
              currency_code,                  -- �ʉ݃R�[�h
              org_id,                         -- �g�DID
              escalation_level,               -- �G�X�J���[�V�������x��
              attribute1,                     -- �K��敪�P
              attribute2,                     -- �K��敪�Q
              attribute3,                     -- �K��敪�R
              attribute4,                     -- �K��敪�S
              attribute5,                     -- �K��敪�T
              attribute6,                     -- �K��敪�U
              attribute7,                     -- �K��敪�V
              attribute8,                     -- �K��敪�W
              attribute9,                     -- �K��敪�X
              attribute10,                    -- �K��敪�P�O
              attribute11,                    -- �L���K��敪
              attribute12,                    -- �o�^���敪
              attribute13,                    -- �o�^���\�[�X�ԍ�
              attribute14,                    -- �ڋq�X�e�[�^�X
              attribute15,                    --
              attribute_category,             -- ��������
              security_group_id,              -- �Z�L�����e�B�O���[�vID
              orig_system_reference,          -- �I���W�i���V�X�e�����t�@�����X
              orig_system_reference_id,       -- �I���W�i���V�X�e�����t�@�����XID
              update_status_flag,             -- �X�e�[�^�X�X�V�t���O
              calendar_start_date,            -- �J�����_�[�J�n��
              calendar_end_date,              -- �J�����_�[�I����
              date_selected,                  -- �I���
              template_id,                    -- �e���v���[�gID
              template_group_id,              -- �e���v���[�g�O���[�vID
              object_changed_date,            -- �I�u�W�F�N�g�ύX��
              task_confirmation_status,       -- �^�X�N�m�F�J�n
              task_confirmation_counter,      -- �^�X�N�m�F�J�E���^�[
              task_split_flag,                -- �^�X�N�����t���O
              open_flag,                      -- �I�[�v���t���O
              entity,                         -- ����
              child_position,                 -- �q�|�W�V����
              child_sequence_num              -- �q�V�[�P���X�ԍ�
         FROM jtf_tasks_b                                                -- �^�X�N���
        WHERE TRUNC(actual_end_date) >= TRUNC(ld_ar_from_date)           -- (FROM)AR��v���ԃI�[�v�������ȍ~
          AND TRUNC(actual_end_date) <= TRUNC(gd_process_date)           -- (TO)�Ɩ����t
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_jtf_task_tbl             -- �c�Ɛ��ѕ\ �^�X�N�Q�����ێ��e�[�u��
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --�o�^�����J�E���g
    ln_ins_task_count := SQL%ROWCOUNT;
--
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �^�X�N���2�������o���������j
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  ct_xxcos_appl_short_name
                    , iv_name           =>  ct_msg_count_ins_tasks
                    , iv_token_name1    =>  cv_tkn_insert_count
                    , iv_token_value1   =>  ln_ins_task_count
                  );
--
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
--
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errbuf   :=  lv_errbuf;
      ov_errmsg   :=  lv_errmsg;
      ov_retcode  :=  lv_retcode;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_jtf_tasks;
/* 2011/07/14 Ver1.17 Add END   */
--
  /**********************************************************************************
   * Procedure Name   : new_cust_sales_results
   * Description      : �V�K�v��������я��W�v���o�^����(B-2)
   ***********************************************************************************/
  PROCEDURE new_cust_sales_results(
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_cust_sales_results'; -- �v���O������
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
--
    --==================================
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_new_cust_sales ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.���b�N����  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
    --==================================
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_newcust_sum_cur(
                                    gd_process_date
                                    );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_newcust_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_newcust_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.�f�[�^�폜  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_newcust_sum   rbns
      WHERE   rbns.regist_bus_date        =     gd_process_date;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
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
    --  �폜�����J�E���g
    g_counter_tab(cn_counter_newcust_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�f�[�^�o�^  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_newcust_sum
              (
              record_id,
              regist_bus_date,
              sale_base_code,
              results_employee_code,
              dlv_date,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
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
              xxcos_rep_bus_newcust_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.dlv_date                             AS  dlv_date,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/11/24 Ver1.8 Add Start */  
                      /*+ 
                        USE_NL(newc.saeh xlvd)
                      */
/* 2009/11/24 Ver1.8 Add Start */
                      newc.sale_base_code                       AS  sale_base_code,
                      newc.results_employee_code                AS  results_employee_code,
                      newc.dlv_date                             AS  dlv_date,
                      SUM(newc.sale_amount)                     AS  sale_amount,
                      SUM(newc.rtn_amount)                      AS  rtn_amount,
                      SUM(newc.sup_sam_cost)                    AS  sup_sam_cost,
                      SUM(
                          CASE  newc.item_code
                            WHEN  xlvd.lookup_code    THEN  newc.sale_amount
                            ELSE  0
                          END
                          )                                     AS  discount_amount
              FROM    (
                      SELECT
/* 2009/11/24 Ver1.8 Mod Start */
                              /*+
                                LEADING(saeh)
                                INDEX(saeh XXCOS_SALES_EXP_HEADERS_N14)
                                INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                                USE_NL(saeh hzca xcac xlvst hzpt)
                                USE_NL(xcac xlvp )
                                USE_NL(hzca xlvc )
                                USE_NL(saeh xlvm)
                                USE_NL(sael xlvs)
                              */
--/* 2009/09/04 Ver1.7 Add Start */
--                              /*+
--                                USE_NL(saeh)
--                              */
--/* 2009/09/04 Ver1.7 Add End   */
/* 2009/11/24 Ver1.8 Mod End */
                              saeh.sales_base_code                      AS  sale_base_code,
                              saeh.results_employee_code                AS  results_employee_code,
                              saeh.delivery_date                        AS  dlv_date,
                              sael.item_code                            AS  item_code,
                              SUM(sael.pure_amount)                     AS  sale_amount,
                              SUM(
                                  CASE  xlvm.attribute1
                                    WHEN  cv_cls_dlv_dff1_rtn THEN  sael.pure_amount
                                    ELSE  0
                                  END
                                  )                                     AS  rtn_amount,
                              SUM(
                                  CASE  xlvs.attribute5
                                    WHEN  cv_yes              THEN  sael.pure_amount
                                    ELSE  0
                                  END
                                  )                                     AS  sup_sam_cost
                      FROM    xxcos_sales_exp_headers       saeh,
                              hz_cust_accounts              hzca,
                              hz_parties                    hzpt,
                              xxcmm_cust_accounts           xcac,
                              xxcos_sales_exp_lines         sael,
                              xxcos_lookup_values_v         xlvp,
                              xxcos_lookup_values_v         xlvm,
                              xxcos_lookup_values_v         xlvs,
                              xxcos_lookup_values_v         xlvc,
                              xxcos_lookup_values_v         xlvst
                      WHERE   saeh.business_date            =       gd_process_date
                      AND     hzca.account_number           =       saeh.ship_to_customer_code
                      AND     xlvc.lookup_type              =       ct_qct_new_cust_class_type
                      AND     xlvc.lookup_code              LIKE    ct_qcc_new_cust_class_code
                      AND     hzca.customer_class_code      =       xlvc.meaning
                      AND     xcac.customer_id              =       hzca.cust_account_id
                      AND     hzpt.party_id                 =       hzca.party_id
                      AND     xlvst.lookup_type             =       ct_qct_new_cust_status_type
                      AND     xlvst.lookup_code             LIKE    ct_qcc_new_cust_status_code
                      AND
                      (
                          (
                              saeh.delivery_date            BETWEEN g_account_info_tab(cn_this_month).account_period_start
                                                            AND     g_account_info_tab(cn_this_month).account_period_end
                          AND xcac.cnvs_date                BETWEEN g_account_info_tab(cn_this_month).account_period_start
                                                            AND     g_account_info_tab(cn_this_month).account_period_end
                          AND hzpt.duns_number_c            =       xlvst.meaning
                          ) 
                        OR
                          (
                              saeh.delivery_date            BETWEEN g_account_info_tab(cn_last_month).account_period_start
                                                            AND     g_account_info_tab(cn_last_month).account_period_end
                          AND xcac.cnvs_date                BETWEEN g_account_info_tab(cn_last_month).account_period_start
                                                            AND     g_account_info_tab(cn_last_month).account_period_end
                          AND xcac.past_customer_status     =       xlvst.meaning
                          )
                      )
                      AND     xlvp.lookup_type              =       ct_qct_new_cust_point_type
                      AND     xlvp.meaning                  =       xcac.new_point_div
                      AND     saeh.delivery_date            BETWEEN NVL(xlvp.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvp.end_date_active,   saeh.delivery_date)
                      AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
                      AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
                      AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
                      AND     xlvm.lookup_code              =       saeh.dlv_invoice_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvm.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvm.end_date_active,   saeh.delivery_date)
                      AND     xlvs.lookup_type              =       ct_qct_sale_type
                      AND     xlvs.lookup_code              =       sael.sales_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
                      GROUP BY
                              saeh.sales_base_code,
                              saeh.results_employee_code,
                              saeh.delivery_date,
                              sael.item_code
                      )                             newc,
                      xxcos_lookup_values_v         xlvd
              WHERE   xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       newc.item_code
              AND     newc.dlv_date                 BETWEEN NVL(xlvd.start_date_active(+),  newc.dlv_date)
                                                    AND     NVL(xlvd.end_date_active(+),    newc.dlv_date)
              GROUP BY
                      newc.sale_base_code,
                      newc.results_employee_code,
                      newc.dlv_date
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
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
    g_counter_tab(cn_counter_newcust_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
--
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �V�K�v������W�v���������j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_new_cust,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_newcust_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_newcust_sum).insert_counter
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END new_cust_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : bus_sales_sum
   * Description      : �ƑԁE�[�i�`�ԕʔ̔����я��W�v���o�^����(B-3)
   ***********************************************************************************/
  PROCEDURE bus_sales_sum(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_sales_sum'; -- �v���O������
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
--
    --==================================
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_sales_sum ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.���b�N����  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_sales_sum_cur(
                                  gd_process_date,
                                  ct_sales_sum_sales
                                  );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_sales_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.�f�[�^�폜  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_sales_sum     rbss
      WHERE   rbss.regist_bus_date        =     gd_process_date
      AND     rbss.sales_transfer_div     =     ct_sales_sum_sales;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �폜�����J�E���g
    g_counter_tab(cn_counter_sales_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�f�[�^�o�^  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_sales_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              delivery_pattern_code,
              cust_gyotai_sho,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
              sprcial_sale_amount,
              sprcial_rtn_amount,
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
              xxcos_rep_bus_sales_sum_s01.nextval       AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_sales                        AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.delivery_pattern_code                AS  delivery_pattern_code,
              work.cust_gyotai_sho                      AS  cust_gyotai_sho,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              work.sprcial_sale_amount                  AS  sprcial_sale_amount,
              work.sprcial_rtn_amount                   AS  sprcial_rtn_amount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      ssum.dlv_date                             AS  dlv_date,
                      ssum.sale_base_code                       AS  sale_base_code,
                      ssum.results_employee_code                AS  results_employee_code,
                      ssum.delivery_pattern_code                AS  delivery_pattern_code,
                      ssum.cust_gyotai_sho                      AS  cust_gyotai_sho,
                      SUM(ssum.sale_amount)                     AS  sale_amount,
                      SUM(ssum.rtn_amount)                      AS  rtn_amount,
                      SUM(ssum.sup_sam_cost)                    AS  sup_sam_cost,
                      SUM(ssum.sprcial_sale_amount)             AS  sprcial_sale_amount,
                      SUM(ssum.sprcial_rtn_amount)              AS  sprcial_rtn_amount,
                      SUM(
                          CASE  ssum.item_code
                            WHEN  xlvd.lookup_code
                              THEN  ssum.sale_amount
                            ELSE    0
                          END
                          )                                     AS  discount_amount
              FROM    (
                      SELECT
/* 2009/09/04 Ver1.7 Add Start */
                              /*+
                                USE_NL(saeh)
                                USE_NL(sael)
                                USE_NL(xlvm)
                                USE_NL(xlvs)
                              */
/* 2009/09/04 Ver1.7 Add End  */
                              saeh.delivery_date                        AS  dlv_date,
                              saeh.sales_base_code                      AS  sale_base_code,
                              saeh.results_employee_code                AS  results_employee_code,
                              sael.delivery_pattern_class               AS  delivery_pattern_code,
                              saeh.cust_gyotai_sho                      AS  cust_gyotai_sho,
                              sael.item_code                            AS  item_code,
                              SUM(sael.pure_amount)                     AS  sale_amount,
                              SUM(
                                  CASE  xlvm.attribute1
                                    WHEN  cv_cls_dlv_dff1_rtn
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  rtn_amount,
                              SUM(
                                  CASE  xlvs.attribute5
                                    WHEN  cv_yes
                                      THEN  sael.business_cost * sael.standard_qty
                                    ELSE    0
                                  END
                                  )                                     AS  sup_sam_cost,
                              SUM(
                                  CASE  xlvs.attribute4
                                    WHEN  cv_yes
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  sprcial_sale_amount,
                              SUM(
                                  CASE
                                    WHEN  xlvs.attribute4 = cv_yes
                                    AND   xlvm.attribute1 = cv_cls_dlv_dff1_rtn
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  sprcial_rtn_amount
                      FROM    xxcos_sales_exp_headers       saeh,
                              xxcos_sales_exp_lines         sael,
                              xxcos_lookup_values_v         xlvm,
                              xxcos_lookup_values_v         xlvs
                      WHERE   saeh.business_date            =       gd_process_date
                      AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
                      AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
                      AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
                      AND     xlvm.lookup_code              =       saeh.dlv_invoice_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvm.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvm.end_date_active,   saeh.delivery_date)
                      AND     xlvs.lookup_type              =       ct_qct_sale_type
                      AND     xlvs.lookup_code              =       sael.sales_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
                      GROUP BY
                              saeh.delivery_date,
                              saeh.sales_base_code,
                              saeh.results_employee_code,
                              sael.delivery_pattern_class,
                              saeh.cust_gyotai_sho,
                              sael.item_code
                      )                             ssum,
                      xxcos_lookup_values_v         xlvd
              WHERE   xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       ssum.item_code
              AND     ssum.dlv_date                 BETWEEN NVL(xlvd.start_date_active(+),  ssum.dlv_date)
                                                    AND     NVL(xlvd.end_date_active(+),    ssum.dlv_date)
              GROUP BY
                      ssum.dlv_date,
                      ssum.sale_base_code,
                      ssum.results_employee_code,
                      ssum.delivery_pattern_code,
                      ssum.cust_gyotai_sho
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
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
    g_counter_tab(cn_counter_sales_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �ƑԁE�[�i�`�ԕʔ̔����яW�v���������j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_sales,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_sales_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_sales_sum).insert_counter
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_sales_sum;
--
  /**********************************************************************************
   * Procedure Name   : bus_transfer_sum
   * Description      : �ƑԁE�[�i�`�ԕʎ��ѐU�֏��W�v���o�^����(B-4)
   ***********************************************************************************/
  PROCEDURE bus_transfer_sum(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_transfer_sum'; -- �v���O������
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
--
    --==================================
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_transfer_sum ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.���b�N����  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_sales_sum_cur(
                                  gd_process_date,
                                  ct_sales_sum_transfer
                                  );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_sales_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.�f�[�^�폜  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_sales_sum     rbss
      WHERE   rbss.regist_bus_date        =     gd_process_date
      AND     rbss.sales_transfer_div     =     ct_sales_sum_transfer;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_sales_sum_tbl
                                              );
        ov_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_delete_data_err,
                                              iv_token_name1 => cv_tkn_table_name,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> NULL
                                              );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �폜�����J�E���g
    g_counter_tab(cn_counter_transfer_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�f�[�^�o�^  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_sales_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              delivery_pattern_code,
              cust_gyotai_sho,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
              sprcial_sale_amount,
              sprcial_rtn_amount,
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
              xxcos_rep_bus_sales_sum_s01.nextval       AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_transfer                     AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              NULL                                      AS  delivery_pattern_code,
              work.cust_gyotai_sho                      AS  cust_gyotai_sho,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              0                                         AS  sprcial_sale_amount,
              0                                         AS  sprcial_rtn_amount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/09/04 Ver1.7 Add Start */
                      /*+
                        USE_NL(xsti)
                        USE_NL(xlvm)
                        USE_NL(xlvd)
                        USE_NL(xlvs)
                      */
/* 2009/09/04 Ver1.7 Add End   */
                      xsti.selling_date                         AS  dlv_date,
                      xsti.base_code                            AS  sale_base_code,
                      xsti.selling_emp_code                     AS  results_employee_code,
                      xsti.cust_state_type                      AS  cust_gyotai_sho,
                      SUM(xsti.selling_amt_no_tax)              AS  sale_amount,
                      SUM(
                          CASE  xlvm.attribute1
                            WHEN  cv_cls_dlv_dff1_rtn
                              THEN  xsti.selling_amt_no_tax
                            ELSE    0
                          END
                          )                                     AS  rtn_amount,
                      SUM(
                          CASE  xsti.item_code
                            WHEN  xlvd.lookup_code
                              THEN  xsti.selling_amt_no_tax
                            ELSE    0
                          END
                          )                                     AS  discount_amount,
                      SUM(
                          CASE  xlvs.attribute5
                            WHEN  cv_yes
                              THEN  xsti.trading_cost
                            ELSE    0
                          END
                          )                                     AS  sup_sam_cost
              FROM    xxcok_selling_trns_info       xsti,
                      xxcos_lookup_values_v         xlvm,
                      xxcos_lookup_values_v         xlvd,
                      xxcos_lookup_values_v         xlvs
              WHERE   xsti.registration_date        =       gd_process_date
              AND     xsti.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
              AND     xlvm.lookup_code              =       xsti.delivery_slip_type
              AND     xsti.selling_date             BETWEEN NVL(xlvm.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvm.end_date_active,   xsti.selling_date)
              AND     xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       xsti.item_code
              AND     xsti.selling_date             BETWEEN NVL(xlvd.start_date_active(+),  xsti.selling_date)
                                                    AND     NVL(xlvd.end_date_active(+),    xsti.selling_date)
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       xsti.selling_type
              AND     xsti.selling_date             BETWEEN NVL(xlvs.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvs.end_date_active,   xsti.selling_date)
              GROUP BY
                      xsti.selling_date,
                      xsti.base_code,
                      xsti.selling_emp_code,
                      xsti.cust_state_type
              )                                         work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
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
    g_counter_tab(cn_counter_transfer_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �ƑԁE�[�i�`�ԕʎ��ѐU�֏W�v���������j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_transfer,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_transfer_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_transfer_sum).insert_counter
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_transfer_sum;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_sales
   * Description      : �c�ƈ��ʁE����Q�ʔ̔����я��W�v���o�^����(B-5)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_sales(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_sales'; -- �v���O������
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
--
    --==================================
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.���b�N����  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_s_group_sum_cur(
                                    gd_process_date,
                                    ct_sales_sum_sales
                                    );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_s_group_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.�f�[�^�폜  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_s_group_sum   rbsg
      WHERE   rbsg.regist_bus_date        =     gd_process_date
      AND     rbsg.sales_transfer_div     =     ct_sales_sum_sales
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �폜�����J�E���g
    g_counter_tab(cn_counter_s_group_sum_sales).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�f�[�^�o�^  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_s_group_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              policy_group_code,
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
      SELECT
              xxcos_rep_bus_s_group_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_sales                        AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.policy_group_code                    AS  policy_group_code,
              work.sale_amount                          AS  sale_amount,
              work.business_cost                        AS  business_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
--Ver1.10 Add Start
                      /*+  USE_NL(sael iimb) */
--Ver1.10 Add End
                      saeh.delivery_date                        AS  dlv_date,
                      saeh.sales_base_code                      AS  sale_base_code,
                      saeh.results_employee_code                AS  results_employee_code,
                      CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                          THEN  iimb.attribute2
                        ELSE    iimb.attribute1
                      END                                       AS  policy_group_code,
                      SUM(sael.pure_amount)                     AS  sale_amount,
                      SUM(
                          CASE  xlvs.attribute3
                            WHEN  cv_yes
                              THEN  sael.business_cost * sael.standard_qty
                            ELSE    0
                          END
                          )                                     AS  business_cost
              FROM    xxcos_sales_exp_headers       saeh,
                      xxcos_sales_exp_lines         sael,
                      xxcos_lookup_values_v         xlvs,
                      ic_item_mst_b                 iimb
              WHERE   saeh.business_date            =       gd_process_date
              AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
              AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       sael.sales_class
              AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                    AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
              AND     iimb.item_no                  =       sael.item_code
              GROUP BY
                      saeh.delivery_date,
                      saeh.sales_base_code,
                      saeh.results_employee_code,
                      CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                          THEN  iimb.attribute2
                        ELSE    iimb.attribute1
                      END
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
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
    g_counter_tab(cn_counter_s_group_sum_sales).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �c�ƈ��ʁE����Q�ʔ̔����яW�v���������j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_s_group_sales,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_s_group_sum_sales).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_s_group_sum_sales).insert_counter
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_s_group_sum_sales;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_trans
   * Description      : �c�ƈ��ʁE����Q�ʎ��ѐU�֏��W�v���o�^����(B-6)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_trans(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_trans'; -- �v���O������
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
--
    --==================================
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 2.���b�N����  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_bus_s_group_sum_cur(
                                    gd_process_date,
                                    ct_sales_sum_transfer
                                    );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_bus_s_group_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.�f�[�^�폜  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_s_group_sum   rbsg
      WHERE   rbsg.regist_bus_date        =     gd_process_date
      AND     rbsg.sales_transfer_div     =     ct_sales_sum_transfer;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �폜�����J�E���g
    g_counter_tab(cn_counter_s_group_sum_trans).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�f�[�^�o�^  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_s_group_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              policy_group_code,
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
      SELECT
              xxcos_rep_bus_s_group_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_transfer                     AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.policy_group_code                    AS  policy_group_code,
              work.sale_amount                          AS  sale_amount,
              work.business_cost                        AS  business_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/09/04 Ver1.7 Add Start */
                      /*+
--Ver1.10 Mod Start
                 --       USE_NL(xsti)
                        USE_NL(xlvs)
                 --       USE_NL(iimb)
                        USE_NL(xsti iimb)
--Ver1.10 Mod Start
                      */
/* 2009/09/04 Ver1.7 Add End   */
                      xsti.selling_date                         AS  dlv_date,
                      xsti.base_code                            AS  sale_base_code,
                      xsti.selling_emp_code                     AS  results_employee_code,
                      CASE
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date)
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                                                  THEN  iimb.attribute2
                        ELSE                            iimb.attribute1
                      END                                       AS  policy_group_code,
                      SUM(xsti.selling_amt_no_tax)              AS  sale_amount,
                      SUM(
                          CASE  xlvs.attribute3
                            WHEN  cv_yes              THEN  xsti.trading_cost
                            ELSE  0
                          END
                          )                                     AS  business_cost
              FROM    xxcok_selling_trns_info       xsti,
                      xxcos_lookup_values_v         xlvs,
                      ic_item_mst_b                 iimb
              WHERE   xsti.registration_date        =       gd_process_date
              AND     xsti.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       xsti.selling_type
              AND     xsti.selling_date             BETWEEN NVL(xlvs.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvs.end_date_active,   xsti.selling_date)
              AND     iimb.item_no                  =       xsti.item_code
              GROUP BY
                      xsti.selling_date,
                      xsti.base_code,
                      xsti.selling_emp_code,
                      CASE
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date)
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                                                  THEN  iimb.attribute2
                        ELSE                            iimb.attribute1
                      END
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_s_group_sum_tbl
                                              );
        ov_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_insert_data_err,
                                              iv_token_name1 => cv_tkn_table_name,
                                              iv_token_value1=> lv_errmsg,
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
    g_counter_tab(cn_counter_s_group_sum_trans).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �c�ƈ��ʁE����Q�ʎ��ѐU�֏W�v���������j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_s_group_transfer,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_s_group_sum_trans).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_s_group_sum_trans).insert_counter
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END bus_s_group_sum_trans;
--
  /**********************************************************************************
   * Procedure Name   : count_results_delete
   * Description      : ���ь����폜����(B-8)
   ***********************************************************************************/
  PROCEDURE count_results_delete(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
/* 2011/05/17 Ver1.16 Add START */
    iv_process_type     IN  VARCHAR2,             --  2.�ďo���v���V�[�W������
/* 2011/05/17 Ver1.16 Add END   */
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_results_delete'; -- �v���O������
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
--
    --==================================
    -- 1.���b�N����  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
    --==================================
    BEGIN
/* 2011/05/17 Ver1.16 Mod START */
--      --  ���b�N�p�J�[�\���I�[�v��
--      OPEN  lock_rep_bus_count_sum_cur(
--                                      it_account_info.base_years
--                                      );
--      --  ���b�N�p�J�[�\���N���[�Y
--      CLOSE lock_rep_bus_count_sum_cur;
      IF (iv_process_type = cv_process_1) THEN
        -- B-7.�e�팏���擾������R�[�����ꂽ�ꍇ
        OPEN  lock_rep_bus_count_sum_cur(it_account_info.base_years);
        CLOSE lock_rep_bus_count_sum_cur;
      ELSE
        -- B-20.���K��q�����擾������R�[�����ꂽ�ꍇ
        OPEN  lock_rep_bus_no_visit_cur(it_account_info.base_years);
        CLOSE lock_rep_bus_no_visit_cur;
      END IF;
/* 2011/05/17 Ver1.16 Mod END   */
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_cust_counter_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
/* 2011/05/17 Ver1.16 Mod START */
        gn_error_cnt := 1;
/* 2011/05/17 Ver1.16 Mod END   */
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.�Ώۃf�[�^�폜
    --==================================
    BEGIN
/* 2011/05/17 Ver1.16 Mod START */
--      DELETE
--/* 2009/09/04 Ver1.7 Mod Start */
----      FROM    xxcos_rep_bus_count_sum
----      WHERE   target_date = it_account_info.base_years
--      /*+
--        INDEX(xrbcs xxcos_rep_bus_count_sum_n02)
--      */
--      FROM    xxcos_rep_bus_count_sum xrbcs
--      WHERE   xrbcs.target_date = it_account_info.base_years
--/* 2009/09/04 Ver1.7 Mod End   */
--      ;
      IF (iv_process_type = cv_process_1) THEN
        -- B-7.�e�팏���擾������R�[�����ꂽ�ꍇ
        DELETE  /*+ INDEX(xrbcs xxcos_rep_bus_count_sum_n02) */
        FROM    xxcos_rep_bus_count_sum   xrbcs
        WHERE   xrbcs.target_date     =   it_account_info.base_years
        AND     xrbcs.counter_class   <>  ct_counter_cls_no_visit;
      ELSE
        -- B-20.���K��q�����擾������R�[�����ꂽ�ꍇ
        DELETE  /*+ INDEX(xrbcs xxcos_rep_bus_count_sum_n02) */
        FROM    xxcos_rep_bus_count_sum   xrbcs
        WHERE   xrbcs.target_date     =   it_account_info.base_years
        AND     xrbcs.counter_class   =   ct_counter_cls_no_visit;
      END IF;
/* 2011/05/17 Ver1.16 Mod END   */
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �폜�����J�E���g
--    g_counter_tab(cn_counter_count_sum).delete_counter
--      := g_counter_tab(cn_counter_count_sum).delete_counter + SQL%ROWCOUNT;
    g_counter_tab(cn_counter_count_sum).delete_counter := SQL%ROWCOUNT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END count_results_delete;
--
/* 2010/05/18 Ver1.14 Add Start */
  /**********************************************************************************
   * Procedure Name   : resource_sum
   * Description      : �c�ƈ����o�^����(B-19)
   ***********************************************************************************/
  PROCEDURE resource_sum(
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'resource_sum'; -- �v���O������
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
    --==================================
    -- 1.�c�ƈ����o�^����(B-19)
    --==================================
    BEGIN
--
      INSERT
      INTO    xxcos_tmp_rs_info
              (
              resource_id,
              base_code,
              employee_number,
              effective_start_date,
              effective_end_date,
              per_effective_start_date,
              per_effective_end_date,
              paa_effective_start_date,
              paa_effective_end_date,
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
              xrsi.resource_id                          AS  resource_id,
              xrsi.base_code                            AS  base_code,
              xrsi.employee_number                      AS  employee_number,
              xrsi.effective_start_date                 AS  effective_start_date,
              xrsi.effective_end_date                   AS  effective_end_date,
              xrsi.per_effective_start_date             AS  per_effective_start_date,
              xrsi.per_effective_end_date               AS  per_effective_end_date,
              xrsi.paa_effective_start_date             AS  paa_effective_start_date,
              xrsi.paa_effective_end_date               AS  paa_effective_end_date,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    xxcos_rs_info2_v            xrsi
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_resource_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
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
  END resource_sum;
--
/* 2010/05/18 Ver1.14 Add End   */
  /**********************************************************************************
   * Procedure Name   : count_customer
   * Description      : �ڋq�������W�v���o�^����(B-9)
   ***********************************************************************************/
  PROCEDURE count_customer(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_customer'; -- �v���O������
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
--
    --==================================
    -- 1.�ڋq�������W�v���o�^����(B-9)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
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
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                 LEADING(work.xrsi.jrrx_n)
--                 INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                 INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                 INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                 USE_NL(work.xrsi.papf_n)
--                 USE_NL(work.xrsi.pept_n)
--                 USE_NL(work.xrsi.paaf_n)
--                 USE_NL(work.xrsi.jrgm_n)
--                 USE_NL(work.xrsi.jrgb_n)
--                 LEADING(work.xrsi.jrrx_o)
--                 INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                 INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                 INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                 USE_NL(work.xrsi.papf_o)
--                 USE_NL(work.xrsi.pept_o)
--                 USE_NL(work.xrsi.paaf_o)
--                 USE_NL(work.xrsi.jrgm_o)
--                 USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--              --   USE_NL(work.xrsi)
--                 INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                 USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add End   */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_cuntomer
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_cuntomer                   AS  counter_class,
              work.business_low_type                    AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      xbco.d_lookup_code                        AS  business_low_type,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva,
                      xxcos_business_conditions_v xbco
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute5             =       cv_yes
              AND     xbco.s_lookup_code          =       xcac.business_low_type
              AND     it_account_info.base_date   BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number,
                      xbco.d_lookup_code
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_customer;
--
  /**********************************************************************************
   * Procedure Name   : count_no_visit
   * Description      : ���K��q�������W�v���o�^����(B-10)
   ***********************************************************************************/
  PROCEDURE count_no_visit(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_no_visit'; -- �v���O������
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
--
    --==================================
    -- 1.���K��q�������W�v���o�^����(B-10)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
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
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--            --    USE_NL(work.xrsi)
--                INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_no_visit
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_no_visit                   AS  counter_class,
              NULL                                      AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v             xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute6             =       cv_yes
              AND NOT EXISTS  (
--/* 2009/04/28 Ver1.4 Mod Start */
--                              SELECT  task.ROWID
--                              FROM    jtf_tasks_b                   task
                              SELECT  task.task_id
/* 2010/12/14 Ver1.15 Mod Start */
--                              FROM    xxcso_visit_actual_v task
                              FROM    xxcos_visit_actual_v task
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
                              WHERE   task.actual_end_date          >=      it_account_info.from_date
                              AND     task.actual_end_date          <       it_account_info.base_date + 1
/* 2009/04/28 Ver1.4 Del Start */
--                              AND     task.source_object_type_code  =       ct_task_obj_type_party
--                              AND     task.owner_type_code          =       ct_task_own_type_employee
--                              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
/* 2009/04/28 Ver1.4 Mod Start */
--                              AND     task.source_object_id         =       xsal.party_id
                              AND     task.party_id                 =       xsal.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--                              AND     task.owner_id                 =       xsal.resource_id
/* 2010/12/14 Ver1.15 Add Start */
                              AND     task.task_status_id           =       gt_prof_task_status_id
                              AND     task.task_type_id             =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
                              AND     ROWNUM                        =       1
                              )
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_no_visit;
--
  /**********************************************************************************
   * Procedure Name   : count_no_trade
   * Description      : ������q�������W�v���o�^����(B-11)
   ***********************************************************************************/
  PROCEDURE count_no_trade(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_no_trade'; -- �v���O������
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
--
    --==================================
    -- 1.������q�������W�v���o�^����(B-11)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
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
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--            --    USE_NL(work.xrsi)
--                INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_no_trade
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_no_trade                   AS  counter_class,
              NULL                                      AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =       DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                               ,  xcac.past_customer_status)
              AND     xlva.attribute7             =       cv_yes
              AND (
                    (   it_account_idx                =       cn_this_month
                    AND (
                            xcac.final_tran_date      <       it_account_info.from_date
                        OR  xcac.final_tran_date      IS NULL
                        )
                    )
                  OR
                    (   it_account_idx                =       cn_last_month
                    AND (
                            xcac.past_final_tran_date <       it_account_info.from_date
                        OR  xcac.past_final_tran_date IS NULL
                        )
                    )
                  )
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_no_trade;
--
  /**********************************************************************************
   * Procedure Name   : count_total_visit
   * Description      : �K����ь������W�v���o�^����(B-12)
   ***********************************************************************************/
  PROCEDURE count_total_visit(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_total_visit'; -- �v���O������
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
--
    --==================================
    -- 1.�K����ь������W�v���o�^����(B-12)
    --==================================
    BEGIN
      INSERT  ALL
        --  ���K�⌏��
        WHEN total_visit > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_total_visit,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_total_visit,
                business_low_type,
                total_visit,
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
--
        --  ���L������
        WHEN total_valid > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_total_valid,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_total_valid,
                business_low_type,
                total_valid,
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
--
        --  �l�b���K�⌏��
        WHEN total_mc_visit > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_mc_visit,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_mc_visit,
                business_low_type,
                total_mc_visit,
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
--
      SELECT
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi)
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
--                USE_NL(work.task)
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n18)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n18)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
              /*+
                LEADING(work.task)
-- 2011/07/14 Ver1.17 MOD START
                INDEX(work.task.jtb xxcos_jtf_tasks_b_n02)
                INDEX(work.task.jtb2 xxcos_jtf_tasks_b_n02)
              */
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n20)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n20)
-- 2011/07/14 Ver1.17 MOD END
/* 2010/05/18 Ver1.14 Mod End   */
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
/* 2010/04/16 Ver1.13 Mod Start */
--              work.total_visit                          AS  total_visit,
              work.total_visit - work.total_mc_visit    AS  total_visit,
/* 2010/04/16 Ver1.13 Mod End   */
              work.total_valid                          AS  total_valid,
              work.total_mc_visit                       AS  total_mc_visit,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
--Ver1.8 Add Start
/* 2010/05/18 Ver1.14 Del Start */
--                /*+
--                USE_NL(xrsi.jrgm_max.jrgm_m)
--                */
/* 2010/05/18 Ver1.14 Del End   */
--Ver1.8 Add End
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
/* 2009/04/28 Ver1.4 Mod Start */
--                      COUNT(task.ROWID)                         AS  total_visit,
                      COUNT(task.task_id)                         AS  total_visit,
/* 2009/04/28 Ver1.4 Mod End   */
                      SUM(
                          CASE  task.attribute11
                            WHEN  cv_task_dff11_valid
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  total_valid,
                      SUM(
                          CASE  task.attribute14
                            WHEN  xlvm.meaning
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  total_mc_visit
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v               xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v              xrsi,
              FROM    xxcos_tmp_rs_info             xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
/* 2009/08/31 Ver1.6 Del Start */
--                      xxcos_salesreps_v             xsal,
/* 2009/08/31 Ver1.6 Del Start */
/* 2009/04/28 Ver1.4 Mod Start */
--                      jtf_tasks_b                   task,
/* 2010/12/14 Ver1.15 Mod Start */
--                      xxcso_visit_actual_v          task,
                      xxcos_visit_actual_v          task,
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
                      xxcos_lookup_values_v         xlvm
/* 2010/05/18 Ver1.14 Mod Start */
--              WHERE   task.actual_end_date          >=      it_account_info.from_date
--              AND     task.actual_end_date          <       it_account_info.base_date + 1
              WHERE   TRUNC(task.actual_end_date)     >=      it_account_info.from_date
              AND     TRUNC(task.actual_end_date)     <       it_account_info.base_date + 1
/* 2010/12/14 Ver1.15 Add Start */
              AND     task.task_status_id             =       gt_prof_task_status_id
              AND     task.task_type_id               =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
/* 2010/05/18 Ver1.14 Mod End   */
/* 2009/04/28 Ver1.4 Del Start */
--              AND     task.source_object_type_code  =       ct_task_obj_type_party
--              AND     task.owner_type_code          =       ct_task_own_type_employee
--              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
              AND     xrsi.resource_id              =       task.owner_id
              AND     xrsi.effective_start_date     <=      TRUNC(task.actual_end_date)
              AND     xrsi.effective_end_date       >=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_end_date   >=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_end_date   >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del Start */
--              AND     xsal.resource_id              =       task.owner_id
/* 2009/04/28 Ver1.4 Mod Start */
----              AND     xsal.party_id                 =       task.source_object_id
--              AND     xsal.party_id                 =       task.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--              AND     NVL(xsal.effective_start_date,  TRUNC(task.actual_end_date))
--                                                    <=      TRUNC(task.actual_end_date)
--              AND     NVL(xsal.effective_end_date,    TRUNC(task.actual_end_date))
--                                                    >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del End   */
              AND     xlvm.lookup_type(+)           =       ct_qct_mc_cust_status_type
              AND     xlvm.lookup_code(+)           LIKE    ct_qcc_mc_cust_status_code
              AND     xlvm.meaning(+)               =       task.attribute14
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_total_visit;
--
  /**********************************************************************************
   * Procedure Name   : count_valid
   * Description      : ���L�����ь������W�v���o�^����(B-13)
   ***********************************************************************************/
  PROCEDURE count_valid(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_valid'; -- �v���O������
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
--
    --==================================
    -- 1.���L�����ь������W�v���o�^����(B-13)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
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
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi)
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
--                USE_NL(work.task)
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n18)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n18)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
              /*+
                LEADING(work.task)
-- 2011/07/14 Ver1.17 MOD START
                INDEX(work.task.jtb xxcos_jtf_tasks_b_n02)
                INDEX(work.task.jtb2 xxcos_jtf_tasks_b_n02)
              */
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n20)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n20)
-- 2011/07/14 Ver1.17 MOD END
/* 2010/05/18 Ver1.14 Mod End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_valid
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_valid                      AS  counter_class,
              NULL                                      AS  business_low_type,
              work.count_valid                          AS  count_valid,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
/* 2009/04/28 Ver1.4 Mod Start */
--                      COUNT(DISTINCT  task.source_object_id)    AS  count_valid
                      COUNT(DISTINCT  task.party_id)            AS  count_valid
/* 2009/04/28 Ver1.4 Mod End   */
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v               xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v              xrsi,
              FROM    xxcos_tmp_rs_info             xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
/* 2009/08/31 Ver1.6 Del Start */
--                      xxcos_salesreps_v             xsal,
/* 2009/08/31 Ver1.6 Del End   */
/* 2009/04/28 Ver1.4 Mod Start */
--                      jtf_tasks_b                   task
/* 2010/12/14 Ver1.15 Mod Start */
--                      xxcso_visit_actual_v          task
                      xxcos_visit_actual_v          task
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
/* 2010/05/18 Ver1.14 Mod Start */
--              WHERE   task.actual_end_date          >=      it_account_info.from_date
--              AND     task.actual_end_date          <       it_account_info.base_date + 1
              WHERE   TRUNC(task.actual_end_date)     >=      it_account_info.from_date
              AND     TRUNC(task.actual_end_date)     <       it_account_info.base_date + 1
/* 2010/05/18 Ver1.14 Mod End   */
/* 2009/04/28 Ver1.4 Del Start */
--              AND     task.source_object_type_code  =       ct_task_obj_type_party
--              AND     task.owner_type_code          =       ct_task_own_type_employee
--              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
              AND     task.attribute11              =       cv_task_dff11_valid
/* 2010/12/14 Ver1.15 Add Start */
              AND     task.task_status_id           =       gt_prof_task_status_id
              AND     task.task_type_id             =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
              AND     xrsi.resource_id              =       task.owner_id
              AND     xrsi.effective_start_date     <=      TRUNC(task.actual_end_date)
              AND     xrsi.effective_end_date       >=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_end_date   >=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_end_date   >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del Start */
--              AND     xsal.resource_id              =       task.owner_id
/* 2009/04/28 Ver1.4 Mod Start */
----              AND     xsal.party_id                 =       task.source_object_id
--              AND     xsal.party_id                 =       task.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--              AND     NVL(xsal.effective_start_date,  TRUNC(task.actual_end_date))
--                                                    <=      TRUNC(task.actual_end_date)
--              AND     NVL(xsal.effective_end_date,    TRUNC(task.actual_end_date))
--                                                    >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del End   */
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_valid;
--
  /**********************************************************************************
   * Procedure Name   : count_new_customer
   * Description      : �V�K�������W�v���o�^����(B-14)
   ***********************************************************************************/
  PROCEDURE count_new_customer(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_new_customer'; -- �v���O������
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
--
    --==================================
    -- 1.�V�K�������W�v���o�^����(B-14)
    --==================================
    BEGIN
      INSERT  ALL
        --  �V�K����
        WHEN new_customer > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_customer,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_customer,
                business_low_type,
                new_customer,
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
        --  �V�K�����i�u�c�j
        WHEN new_customer_vd > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_customervd,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_customervd,
                business_low_type,
                new_customer_vd,
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
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add End   */
              /*+
              LEADING(work.xcac)
              INDEX(work.xcac xxcmm_cust_accounts_n12)
              */
/* 2010/05/18 Ver1.14 Mod End   */
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
              work.new_customer                         AS  new_customer,
              work.new_customer_vd                      AS  new_customer_vd,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  new_customer,
                      SUM(
                          CASE  xcac.business_low_type
                            WHEN  xlvg.meaning
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  new_customer_vd
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcmm_cust_accounts         xcac,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcos_lookup_values_v       xlvs,
                      xxcos_lookup_values_v       xlvc,
                      xxcos_lookup_values_v       xlvp,
                      xxcos_lookup_values_v       xlvg
              WHERE   xcac.cnvs_date              BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     xcac.cnvs_date              BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     xcac.cnvs_date              BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     xcac.cnvs_date              BETWEEN it_account_info.from_date
                                                  AND     it_account_info.base_date
              AND (
                    (   xcac.cnvs_base_code       =       xrsi.base_code
                    AND xcac.cnvs_business_person =       xrsi.employee_number
                    )
                  OR
                    (   xcac.intro_base_code      =       xrsi.base_code
                    AND xcac.intro_business_person=       xrsi.employee_number
                    )
                  )
              AND     hzca.cust_account_id        =       xcac.customer_id
              AND     hzpt.party_id               =       hzca.party_id
              AND     xlvs.lookup_type            =       ct_qct_new_cust_status_type
              AND     xlvs.lookup_code            LIKE    ct_qcc_new_cust_status_code
              AND     xlvs.meaning                =       
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlvc.lookup_type            =       ct_qct_new_cust_class_type
              AND     xlvc.lookup_code            LIKE    ct_qcc_new_cust_class_code
              AND     xlvc.meaning                =       hzca.customer_class_code
              AND     xlvp.lookup_type            =       ct_qct_new_cust_point_type
              AND     xlvp.lookup_code            LIKE    ct_qcc_new_cust_point_code
              AND     xlvp.meaning                =       xcac.new_point_div
              AND     xlvg.lookup_type(+)         =       ct_qct_gyotai_sho_mst_type
              AND     xlvg.lookup_code(+)         LIKE    ct_qcc_gyotai_sho_mst_code
              AND     xlvg.meaning(+)             =       xcac.business_low_type
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
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
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_new_customer;
--
  /**********************************************************************************
   * Procedure Name   : count_point
   * Description      : �V�K�l���E���i�|�C���g���W�v���o�^����(B-15)
   ***********************************************************************************/
  PROCEDURE count_point(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_point'; -- �v���O������
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
--
    --==================================
    -- 1. �V�K�l���E���i�|�C���g���W�v���o�^����(B-15)
    --==================================
    BEGIN
      INSERT  ALL
        --  �V�K�l���|�C���g
        WHEN new_cust_point > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_point,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_point,
                business_low_type,
                new_cust_point,
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
--
        --  ���i�|�C���g
        WHEN qualifi_point > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
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
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_qualifi_point,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_qualifi_point,
                business_low_type,
                qualifi_point,
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
--
      SELECT
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
              work.new_cust_point                       AS  new_cust_point,
              work.qualifi_point                        AS  qualifi_point,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      ncph.location_cd                          AS  base_code,
                      ncph.employee_number                      AS  employee_num,
                      SUM(
                          CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                            WHEN  ncph.data_kbn = ct_point_data_cls_new_cust
--                            OR    ncph.data_kbn = ct_point_data_cls_f_and_f
-- *********** 2009/11/12 Ver1.9 N.Maeda MOD START *********** --
--                            WHEN  ncph.evaluration_kbn = ct_evaluration_kbn_acvmt
--                            AND   (
                            WHEN  (
-- *********** 2009/11/12 Ver1.9 N.Maeda MOD START *********** --
                                     ncph.data_kbn = ct_point_data_cls_new_cust
                                  OR ncph.data_kbn = ct_point_data_cls_f_and_f
/* 2010/01/19 Ver1.12 Add Start */
                                  OR ncph.data_kbn = ct_point_data_cls_f_and_f_bur
/* 2010/01/19 Ver1.12 Add End   */
                                  )
/* 2009/04/28 Ver1.4 Mod End   */
                              THEN  ncph.point
                            ELSE    0
                          END
                          )                                     AS  new_cust_point,
                      SUM(
                          CASE  ncph.data_kbn
                            WHEN  ct_point_data_cls_qualifi
                              THEN  ncph.point
                            ELSE    0
                          END
                          )                                     AS  qualifi_point
              FROM    xxcsm_new_cust_point_hst      ncph
              WHERE   ncph.year_month               =       it_account_info.base_years
              AND (   ncph.get_custom_date          <=      it_account_info.base_date
                  OR  ncph.data_kbn                 =       ct_point_data_cls_qualifi
                  )
              GROUP BY
                      ncph.location_cd,
                      ncph.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_point;
/* 2010/04/16 Ver1.13 Add Start */
  /**********************************************************************************
   * Procedure Name   : count_base_code_cust
   * Description      : ���_�v�ڋq�������W�v���o�^����(B-18)
   ***********************************************************************************/
  PROCEDURE count_base_code_cust(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    it_account_idx      IN  PLS_INTEGER,          --  2.��v���z��C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_base_code_cust'; -- �v���O������
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
--
    --==================================
    -- 1.���_�v�ڋq�������W�v���o�^����(B-18)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
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
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_base_code_cust
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              NULL                                      AS  employee_num,
              ct_counter_cls_base_code_cust             AS  counter_class,
              work.business_low_type                    AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xcac.sale_base_code                       AS  base_code,
                      xbco.d_lookup_code                        AS  business_low_type,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
              FROM    hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva,
                      xxcos_business_conditions_v xbco
              WHERE   hzpt.party_id               =       hzca.party_id
              AND     xcac.customer_id            =       hzca.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute5             =       cv_yes
              AND     xbco.s_lookup_code          =       xcac.business_low_type
              AND     it_account_info.base_date   BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              GROUP BY
                      xcac.sale_base_code,
                      xbco.d_lookup_code
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  �o�^�����J�E���g
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
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
  END count_base_code_cust;
--
/* 2010/04/16 Ver1.13 Add End   */
  /**********************************************************************************
   * Procedure Name   : count_delete_invalidity
   * Description      : �����؂�W�v�f�[�^�폜����(B-16)
   ***********************************************************************************/
  PROCEDURE count_delete_invalidity(
    it_account_info     IN  g_account_info_rec,   --  1.��v���
    ov_errbuf           OUT VARCHAR2,             --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_delete_invalidity'; -- �v���O������
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
    lt_invalidity_date                    xxcos_rep_bus_newcust_sum.dlv_date%TYPE;
    lt_invalidity_years                   xxcos_rep_bus_count_sum.target_date%TYPE;
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
--
    --  �����؂��N�����Z�o
    lt_invalidity_date
      := LAST_DAY(ADD_MONTHS(it_account_info.base_date, TO_NUMBER(gt_prof_002a03_keeping_period) * -1));
--
    --  �����؂��N���Z�o
    lt_invalidity_years := TO_CHAR(lt_invalidity_date, cv_fmt_years);
--
    --==================================
    -- 1.�����؂�V�K�v������W�v�e�[�u���폜����(B-16)
    --==================================
    --  ���b�N����  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_newcust_invalidity_cur (
                                        lt_invalidity_date
                                        );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_newcust_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_newcust_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  �폜����  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_newcust_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX(xrbns xxcos_rep_bus_newcust_sum_n03)
      */
      FROM    xxcos_rep_bus_newcust_sum xrbns
      WHERE   xrbns.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �����؂�폜�����J�E���g
    g_counter_tab(cn_counter_newcust_sum).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 2.�����؂�c�Ɛ��ѕ\ ������яW�v�e�[�u���폜����(B-16)
    --==================================
    --  ���b�N����  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_sales_invalidity_cur (
                                      lt_invalidity_date
                                      );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_sales_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  �폜����  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_sales_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX (xrbss xxcos_rep_bus_sales_sum_n03)
      */
      FROM    xxcos_rep_bus_sales_sum xrbss
      WHERE   xrbss.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �����؂�폜�����J�E���g
    --  �i�����؂ꌏ���ɂ��Ă͔̔����ё��̃J�E���^�[�Ō����Ǘ��j
    g_counter_tab(cn_counter_sales_sum).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 3.�����؂�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���폜����(B-16)
    --==================================
    --  ���b�N����  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_s_group_invalidity_cur (
                                        lt_invalidity_date
                                        );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_s_group_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  �폜����  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_s_group_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX(xrbsgs xxcos_rep_bus_s_group_sum_n03)
      */
      FROM    xxcos_rep_bus_s_group_sum xrbsgs
      WHERE   xrbsgs.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  �����؂�폜�����J�E���g
    --  �i�����؂ꌏ���ɂ��Ă͔̔����ё��̃J�E���^�[�Ō����Ǘ��j
    g_counter_tab(cn_counter_s_group_sum_sales).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 4.�����؂�c�ƌ����W�v�e�[�u���폜����(B-16)
    --==================================
    --  ���b�N����  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
    BEGIN
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_count_sum_invalidity_cur (
                                          lt_invalidity_years
                                          );
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_count_sum_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  �e�[�u�����擾
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_cust_counter_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  �폜����  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_count_sum
--     WHERE   target_date   <= lt_invalidity_years
      /*+
        INDEX(xrbcs xxcos_rep_bus_count_sum_n02)
      */
      FROM    xxcos_rep_bus_count_sum xrbcs
      WHERE   xrbcs.target_date   <= lt_invalidity_years
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  �㑱�f�[�^�̏����͒��~�ƂȂ�ׁA���ӏ��ł̃G���[�������͏�ɂP��
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;--
--
    --  �����؂�폜�����J�E���g
    g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := SQL%ROWCOUNT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ �����؂�W�v���폜�����j
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_delete_invalidity,
      iv_token_name1 => cv_tkn_keeping_period,
      iv_token_value1=> gt_prof_002a03_keeping_period,
      iv_token_name2 => cv_tkn_deletion_object,
      iv_token_value2=> lt_invalidity_years,
      iv_token_name3 => cv_tkn_new_contribution,
      iv_token_value3=> g_counter_tab(cn_counter_newcust_sum).delete_counter_invalidity,
      iv_token_name4 => cv_tkn_business_conditions,
      iv_token_value4=> g_counter_tab(cn_counter_sales_sum).delete_counter_invalidity,
      iv_token_name5 => cv_tkn_policy_group,
      iv_token_value5=> g_counter_tab(cn_counter_s_group_sum_sales).delete_counter_invalidity,
      iv_token_name6 => cv_tkn_counter,
      iv_token_value6=> g_counter_tab(cn_counter_count_sum).delete_counter_invalidity
      );
    --  �����������b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
--
  EXCEPTION
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END count_delete_invalidity;
--
  /**********************************************************************************
   * Procedure Name   : control_count
   * Description      : �e�팏���擾����(B-7)
   ***********************************************************************************/
  PROCEDURE control_count(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'control_count'; -- �v���O������
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
    --  �z��index��`
    lp_idx                                PLS_INTEGER;
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
    -- 1.�������s����
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_control_count ) ) THEN
      NULL;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
/* 2010/05/18 Ver1.14 Add Start */
    --==================================
    -- 19.�c�ƈ����o�^����
    --==================================
    resource_sum(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --  �����X�e�[�^�X����
      IF ( lv_retcode = cv_status_error ) THEN
        --  (�G���[����)
        RAISE global_process_expt;
      END IF;
--
/* 2010/05/18 Ver1.14 Add End   */
    --==================================
    -- 2.�e�팏���J�E���g����
    --==================================
    <<count_results>>
    FOR lp_idx IN g_account_info_tab.FIRST..g_account_info_tab.LAST LOOP
      --  ����������
      g_counter_tab(cn_counter_count_sum).insert_counter := 0;
      g_counter_tab(cn_counter_count_sum).select_counter := 0;
      g_counter_tab(cn_counter_count_sum).update_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := 0;
--
      --  ��v�X�e�[�^�Xopen���̂ݏ��������s
      IF ( g_account_info_tab(lp_idx).status = cv_open ) THEN
        --  ���ь����폜����(B-8)
        count_results_delete(
          g_account_info_tab(lp_idx),
/* 2011/05/17 Ver1.16 Add START */
          cv_process_1,
/* 2011/05/17 Ver1.16 Add END   */
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
          IF ( lock_rep_bus_count_sum_cur%ISOPEN ) THEN
            CLOSE lock_rep_bus_count_sum_cur;
          END IF;
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  �ڋq�������W�v���o�^����(B-9)
        count_customer(
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
/* 2011/05/17 Ver1.16 Del START */
--        --  ���K��q�������W�v���o�^����(B-10)
--        count_no_visit(
--          g_account_info_tab(lp_idx),
--          lp_idx,
--          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        --  �����X�e�[�^�X����
--        IF ( lv_retcode = cv_status_error ) THEN
--          --  (�G���[����)
--          RAISE global_process_expt;
--        END IF;
/* 2011/05/17 Ver1.16 Del END   */
--
        --  ������q�������W�v���o�^����(B-11)
        count_no_trade(
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  �K����ь������W�v���o�^����(B-12)
        count_total_visit (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  ���L�����ь������W�v���o�^����(B-13)
        count_valid (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  �V�K�������W�v���o�^����(B-14)
        count_new_customer  (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  �V�K�l���E���i�|�C���g���W�v���o�^����(B-15)
        count_point (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
/* 2010/04/16 Ver1.13 Add Start */
        --  ���_�v�ڋq�������W�v���o�^����(B-18)
        count_base_code_cust (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
/* 2010/04/16 Ver1.13 Add End   */
        --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ ���яW�v���������j
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_count_reslut,
          iv_token_name1 => cv_tkn_object_years,
          iv_token_value1=> g_account_info_tab(lp_idx).base_years,
          iv_token_name2 => cv_tkn_delete_count,
          iv_token_value2=> g_counter_tab(cn_counter_count_sum).delete_counter,
          iv_token_name3 => cv_tkn_insert_count,
          iv_token_value3=> g_counter_tab(cn_counter_count_sum).insert_counter
          );
        --  �����������b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_errmsg
        );
      END IF;
    END LOOP  count_results;
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
--
    --  �����؂�W�v�f�[�^�폜����(B-16)
    count_delete_invalidity (
      g_account_info_tab(cn_this_month),
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --  �����X�e�[�^�X����
    IF ( lv_retcode = cv_status_error ) THEN
      --  �f�[�^�J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
      IF ( lock_newcust_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_newcust_invalidity_cur;
      END IF;
      --  �f�[�^�J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
      IF ( lock_sales_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_sales_invalidity_cur;
      END IF;
      --  �f�[�^�J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
      IF ( lock_s_group_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_s_group_invalidity_cur;
      END IF;
      --  �f�[�^�J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
      IF ( lock_count_sum_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_count_sum_invalidity_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errbuf := lv_errbuf;
      ov_errmsg := lv_errmsg;
      ov_retcode := lv_retcode;
    --*** ���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** �f�[�^�폜��O�n���h�� ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END control_count;
--
/* 2011/05/17 Ver1.16 Add START */
  /**********************************************************************************
   * Procedure Name   : no_visit_control_cnt
   * Description      : ���K��q�����擾����(B-20)
   ***********************************************************************************/
  PROCEDURE no_visit_control_cnt(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'no_visit_control_cnt'; -- �v���O������
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
    ln_start_idx    NUMBER;
    ln_end_idx      NUMBER;
--
    --  �z��index��`
    lp_idx                                PLS_INTEGER;
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
    -- 1.�������s����
    --==================================
    IF (gv_processing_class = cv_para_cls_all) THEN
      --  �����敪�u0:�S�āv�̏ꍇ�A�O���A����������
      ln_start_idx  :=  cn_last_month;
      ln_end_idx    :=  cn_this_month;
    ELSIF (gv_processing_class = cv_para_no_visit_last_month) THEN
      --  �����敪�u7:���K��q�����擾�i�O���j�v�̏ꍇ�A�O���̂ݏ���
      ln_start_idx  :=  cn_last_month;
      ln_end_idx    :=  cn_last_month;
    ELSIF (gv_processing_class = cv_para_no_visit_this_month) THEN
      --  �����敪�u8:���K��q�����擾�i�����j�v�̏ꍇ�A�����̂ݏ���
      ln_start_idx  :=  cn_this_month;
      ln_end_idx    :=  cn_this_month;
    ELSE
      --  �{�����̓X�L�b�v
      RETURN;
    END IF;
--
    --==================================
    -- 19.�c�ƈ����o�^����
    --==================================
    resource_sum(
        ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �����X�e�[�^�X����
    IF ( lv_retcode = cv_status_error ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 2.�e�팏���J�E���g����
    --==================================
    <<count_results>>
    FOR lp_idx IN ln_start_idx .. ln_end_idx LOOP
      --  ����������
      g_counter_tab(cn_counter_count_sum).insert_counter := 0;
      g_counter_tab(cn_counter_count_sum).select_counter := 0;
      g_counter_tab(cn_counter_count_sum).update_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := 0;
--
      --  ��v�X�e�[�^�Xopen���̂ݏ��������s
      IF ( g_account_info_tab(lp_idx).status = cv_open ) THEN
        --  ���ь����폜����(B-8)
        count_results_delete(
            it_account_info     =>  g_account_info_tab(lp_idx)
          , iv_process_type     =>  cv_process_2
          , ov_errbuf           =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode          =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg           =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ �c�ƌ����W�v�e�[�u���j
          IF ( lock_rep_bus_no_visit_cur%ISOPEN ) THEN
            CLOSE lock_rep_bus_no_visit_cur;
          END IF;
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  ���K��q�������W�v���o�^����(B-10)
        count_no_visit(
            it_account_info   =>  g_account_info_tab(lp_idx)
          , it_account_idx    =>  lp_idx
          , ov_errbuf         =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode        =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg         =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --  �����X�e�[�^�X����
        IF ( lv_retcode = cv_status_error ) THEN
          --  (�G���[����)
          RAISE global_process_expt;
        END IF;
--
        --  �����������b�Z�[�W�ҏW�i�c�Ɛ��ѕ\ ���яW�v���������j
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  ct_xxcos_appl_short_name
                        , iv_name           =>  ct_msg_count_no_visit
                        , iv_token_name1    =>  cv_tkn_object_years
                        , iv_token_value1   =>  g_account_info_tab(lp_idx).base_years
                        , iv_token_name2    =>  cv_tkn_delete_count
                        , iv_token_value2   =>  g_counter_tab(cn_counter_count_sum).delete_counter
                        , iv_token_name3    =>  cv_tkn_insert_count
                        , iv_token_value3   =>  g_counter_tab(cn_counter_count_sum).insert_counter
                      );
        --  �����������b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_errmsg
        );
      END IF;
    END LOOP  count_results;
--
    --  �R�~�b�g���s
    COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errbuf   :=  lv_errbuf;
      ov_errmsg   :=  lv_errmsg;
      ov_retcode  :=  lv_retcode;
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
  END no_visit_control_cnt;
/* 2011/05/17 Ver1.16 Add END   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_date     IN      VARCHAR2,         --  1.�Ɩ����t
    iv_processing_class IN      VARCHAR2,         --  2.�����敪
    ov_errbuf           OUT     VARCHAR2,         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT     VARCHAR2,         --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT     VARCHAR2)         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �v���C�x�[�g�ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt := 0;
    gn_warn_cnt := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(B-1)
    -- ===============================
    init(
      iv_process_date,
      iv_processing_class,
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
/* 2011/07/14 Ver1.17 Add START */
    -- ===============================
    -- �^�X�N���2�������o����(B-21)
    -- ===============================
    ins_jtf_tasks(
        ov_errbuf     =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
/* 2011/07/14 Ver1.17 Add END   */
    -- ===============================
    -- �V�K�v��������я��W�v���o�^����(B-2)
    -- ===============================
    new_cust_sales_results(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ �V�K�v������W�v�e�[�u���j
      IF  ( lock_bus_newcust_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_newcust_sum_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ƑԁE�[�i�`�ԕʔ̔����я��W�v���o�^����(B-3)
    -- ===============================
    bus_sales_sum(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
      IF ( lock_bus_sales_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_sales_sum_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ƑԁE�[�i�`�ԕʎ��ѐU�֏��W�v���o�^����(B-4)
    -- ===============================
    bus_transfer_sum(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ������яW�v�e�[�u���j
      IF ( lock_bus_sales_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_sales_sum_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �c�ƈ��ʁE����Q�ʔ̔����я��W�v���o�^����(B-5)
    -- ===============================
    bus_s_group_sum_sales(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
      IF ( lock_bus_s_group_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_s_group_sum_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �c�ƈ��ʁE����Q�ʎ��ѐU�֏��W�v���o�^����(B-6)
    -- ===============================
    bus_s_group_sum_trans(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  �J�[�\���N���[�Y  �i�c�Ɛ��ѕ\ ����Q�ʎ��яW�v�e�[�u���j
      IF  ( lock_bus_s_group_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_s_group_sum_cur;
      END IF;
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
    -- ===============================
    -- �e�팏���擾����(B-7)
    -- ===============================
    control_count(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
--
/* 2011/05/17 Ver1.16 Add START */
    -- ===============================
    -- ���K��q�����擾����(B-20)
    -- ===============================
    no_visit_control_cnt(
        ov_errbuf     =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (�G���[����)
      RAISE global_process_expt;
    END IF;
/* 2011/05/17 Ver1.16 Add END   */
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
    errbuf              OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode             OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_process_date     IN      VARCHAR2,         --  1.�Ɩ����t
    iv_processing_class IN      VARCHAR2          --  2.�����敪
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
*/
--###########################  �Œ蕔 END   #############################
--
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_process_date
      ,iv_processing_class
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
/* 2011/05/17 Ver1.16 Add START */
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
/* 2011/05/17 Ver1.16 Add START */
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
/*
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
*/

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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

    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
--      lv_message_code := ct_msg_error;
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
END XXCOS002A032C;
/
