CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOS005A10C (body)
 * Description      : CSV�t�@�C����EDI�󒍎捞
 * MD.050           : CSV�t�@�C����EDI�󒍎捞 MD050_COS_005_A10_
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_out               �p�����[�^�o��                              (A-0)
 *  get_order_data         �t�@�C���A�b�v���[�hIF�󒍏��f�[�^�̎擾  (A-1)
 *  data_delete            �f�[�^�폜����                              (A-2)
 *  init                   ��������                                    (A-3)
 *  order_item_split       �󒍏��f�[�^�̍��ڕ�������                (A-4)
 *  item_check             ���ڃ`�F�b�N                                (A-5)
 *  get_master_data        �}�X�^���̎擾����                        (A-6)
 *  security_check         �Z�L�����e�B�`�F�b�N����                    (A-7)
 *  set_order_data         �f�[�^�ݒ菈��                              (A-8)
 *  data_insert            �f�[�^�o�^����                              (A-8)
 *  call_imp_data          �󒍂̃C���|�[�g�v��                        (A-9)
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/10/26    1.0   N.Koyama         �V�K�쐬(E_�{�ғ�_16636)
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
  -- ����
  cv_lang                   CONSTANT VARCHAR2(2) := USERENV( 'LANG' );
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
  global_proc_date_err_expt         EXCEPTION;                                                       --�Ɩ����t�擾��O�n���h��
  global_get_profile_expt           EXCEPTION;                                                       --�v���t�@�C���擾��O�n���h��
  global_get_stock_org_id_expt      EXCEPTION;                                                       --�c�Ɨp�݌ɑg�DID�̎擾�O�n���h��
  global_get_order_source_expt      EXCEPTION;                                                       --�󒍃\�[�X���̎擾�n���h��
  global_get_order_type_expt        EXCEPTION;                                                       --�󒍃^�C�v���̎擾�n���h��
  global_get_file_id_lock_expt      EXCEPTION;                                                       --�t�@�C��ID�̎擾�n���h��
  global_get_file_id_data_expt      EXCEPTION;                                                       --�t�@�C��ID�̎擾�n���h��
  global_get_f_uplod_name_expt      EXCEPTION;                                                       --�t�@�C���A�b�v���[�h���̂̎擾�n���h��
  global_get_f_csv_name_expt        EXCEPTION;                                                       --CSV�t�@�C�����̎擾�n���h��
  global_get_order_data_expt        EXCEPTION;                                                       --�󒍏��f�[�^�擾�n���h��
  global_cut_order_data_expt        EXCEPTION;                                                       --�t�@�C�����R�[�h���ڐ��s��v�n���h��
  global_item_check_expt            EXCEPTION;                                                       --���ڃ`�F�b�N�n���h��
  global_t_cust_too_many_expt       EXCEPTION;                                                       --�ڋq���TOO_MANY�G���[
  global_cust_check_expt            EXCEPTION;                                                       --�}�X�^���̎擾(�ڋq�}�X�^�`�F�b�N�P)
  global_item_delivery_mst_expt     EXCEPTION;                                                       --�}�X�^���̎擾(�ڋq�}�X�^�`�F�b�N�Q)
  global_cus_data_check_expt        EXCEPTION;                                                       --�}�X�^���̎擾(�f�[�^���o�G���[)
  global_item_sale_div_expt         EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڔ���Ώۋ敪�G���[)
  global_item_status_expt           EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڃX�e�[�^�X�G���[)
  global_item_master_chk_expt       EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڃ}�X�^���݃`�F�b�N�G���[)
  global_cus_sej_check_expt         EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڃR�[�h)
  global_security_check_expt        EXCEPTION;                                                       --�Z�L�����e�B�`�F�b�N
  global_ins_order_data_expt        EXCEPTION;                                                       --�f�[�^�o�^
  global_del_order_data_expt        EXCEPTION;                                                       --�f�[�^�폜
  global_select_err_expt            EXCEPTION;                                                       --���o�G���[
  global_item_status_code_expt      EXCEPTION;                                                       --�ڋq�󒍉\�G���[
  global_insert_expt                EXCEPTION;                                                       --�o�^�G���[
  global_get_highest_emp_expt       EXCEPTION;                                                       --�ŏ�ʎҏ]�ƈ��ԍ��擾�n���h��
  global_get_salesrep_expt          EXCEPTION;                                                       --���ʊ֐�(�S���]�ƈ��擾)�G���[��
  global_business_low_type_expt     EXCEPTION;                                                       --�Ƒԏ����ނ̃`�F�b�N��O
  global_cust_null_expt             EXCEPTION;                                                       --�ڋq�L�[���K�{�`�F�b�N�G���[
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                       CONSTANT VARCHAR2(128) := 'XXCOS005A10C';                        -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCOS';                                             --�̕��Z�k�A�v����
  ct_xxccp_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCCP';                                             --����
--
  ct_prof_org_id                    CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'ORG_ID';                                            --�c�ƒP��
  ct_prod_ou_nm                     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_ITOE_OU_MFG';                                --���Y�c�ƒP��
  ct_inv_org_code                   CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOI1_ORGANIZATION_CODE';                          --�݌ɑg�D�R�[�h
  ct_look_source_type               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_ODR_SRC_MST_005_A10';                        --�N�C�b�N�R�[�h�^�C�v
  ct_look_up_type                   CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_TRAN_TYPE_MST_005_A10';                      --�N�C�b�N�R�[�h�^�C�v
  ct_look_sales_class               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_SALE_CLASS';                                 --�N�C�b�N�R�[�h�^�C�v(����敪)
  ct_prof_interval                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_INTERVAL';                                   --�ҋ@�Ԋu
  ct_prof_max_wait                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_MAX_WAIT';                                   --�ő�ҋ@����
--
  --���b�Z�[�W
  ct_msg_get_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00001';                                 --���b�N�G���[
  ct_msg_get_profile_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00004';                                 --�v���t�@�C���擾�G���[
  ct_msg_insert_data_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00010';                                 --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00012';                                 --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_get_data_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00013';                                 --�f�[�^���o�G���[���b�Z�[�W
  ct_msg_get_api_call_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00017';                                 --API�ďo�G���[���b�Z�[�W
  ct_msg_get_org_id                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00047';                                 --MO:�c�ƒP��
  ct_msg_get_inv_org_code           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00048';                                 --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_get_item_mstr              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00050';                                 --�i�ڃ}�X�^
  ct_msg_get_case_uom               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00057';                                 --XXCOS:�P�[�X�P�ʃR�[�h(���b�Z�[�W������)
  ct_msg_get_inv_org_id             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00063';                                 --�݌ɑg�DID
  ct_msg_get_inv_org                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00091';                                 --�݌ɑg�DID�擾�G���[
  ct_msg_get_format_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11251';                                 --���ڃt�H�[�}�b�g�G���[���b�Z�[�W
  ct_msg_get_cust_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11252';                                 --�ڋq�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_cust_null_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-15351';                                 --�[�i��K�{�G���[���b�Z�[�W
  ct_msg_get_item_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11253';                                 --�i�ڃ}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_security_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11255';                                 --�Z�L�����e�B�[�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_master_chk_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11256';                                 --�}�X�^�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_item_sale_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11258';                                 --�i�ڔ���Ώۋ敪�G���[
  ct_msg_get_item_status_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11259';                                 --�i�ڃX�e�[�^�X�G���[
  ct_msg_get_lien_no                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11260';                                 --�s�ԍ�(���b�Z�[�W������)
  ct_msg_get_chain_code             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11261';                                 --�`�F�[���X�R�[�h(���b�Z�[�W������)
  ct_msg_get_shop_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-15353';                                 --�X�܃R�[�h(���b�Z�[�W������)
  ct_msg_inv_org_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11264';                                 --�݌ɑg�D�R�[�h(���b�Z�[�W������)
  ct_msg_get_itme_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11265';                                 --�i�ڃR�[�h(���b�Z�[�W������)
  ct_msg_get_delivery_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11267';                                 --�[�i��(���b�Z�[�W������)
  ct_msg_delivery_mst_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11269';                                 --�ڋq�}�X�^�`�F�b�N�G���[
  ct_msg_get_item_sej               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11270';                                 --�i�ڃ}�X�^�`�F�b�N�G���[(SEJ���i�R�[�h)
  ct_msg_get_order_on               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11277';                                 --�I�[�_�[NO(���b�Z�[�W������)
  ct_msg_get_customer_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11278';                                 --�ڋq�R�[�h
  ct_msg_get_delivery_loc_code      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11279';                                 --�[�i���_�R�[�h(���b�Z�[�W������)
  ct_msg_get_order_h_oif            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11280';                                 --�󒍃w�b�_�[OIF(���b�Z�[�W������)
  ct_msg_get_order_l_oif            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11281';                                 --�󒍖���OIF(���b�Z�[�W������)
  ct_msg_get_file_up_load           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11282';                                 --�t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  ct_msg_get_order_sorce            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11283';                                 --�󒍃\�[�X(���b�Z�[�W������)
  ct_msg_get_sorce_name             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11284';                                 --�󒍃\�[�X��(���b�Z�[�W������)
  ct_msg_get_order_type             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11285';                                 --�󒍃^�C�v(���b�Z�[�W������)
  ct_msg_get_order_type_name        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11286';                                 --�󒍃^�C�v��(���b�Z�[�W������)
  ct_msg_get_h_count                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11287';                                 --�������b�Z�[�W
  ct_msg_get_rep_h1                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11289';                                 --�t�H�[�}�b�g�p�^�[�����b�Z�[�W
  ct_msg_get_rep_h2                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11290';                                 --CSV�t�@�C�������b�Z�[�W
  ct_msg_get_file_uplod_name        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11291';                                 --�t�@�C���A�b�v���[�h����(���b�Z�[�W������)
  ct_msg_get_file_csv_name          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11292';                                 --CSV�t�@�C����(���b�Z�[�W������)
  ct_msg_get_f_uplod_name           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11293';                                 --�t�@�C���A�b�v���[�h���̎擾�G���[
  ct_msg_get_f_csv_name             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11294';                                 --CSV�t�@�C�����擾�G���[
  ct_msg_chk_rec_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11295';                                 --�t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  ct_msg_chk_time_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11296';                                 --���ߎ��Ԏw��G���[
  ct_msg_get_add_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11297';                                 --�ڋq�ǉ����}�X�^
  ct_msg_get_sej_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11299';                                 --SEJ���i�R�[�h
  ct_msg_get_imp_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11300';                                 --�R���J�����g�G���[���b�Z�[�W
  ct_msg_get_imp_warning            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13851';                                 --�R���J�����g���[�j���O���b�Z�[�W
  ct_msg_get_tonya_toomany          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13852';                                 --�ڋqTOO_MANY_ROWS��O�G���[���b�Z�[�W
  ct_msg_set_emp_highest            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13854';                                 --�S���c�ƈ��ŏ�ʎҐݒ胁�b�Z�[�W
  ct_msg_get_interval               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11325';                                 --XXCOS:�ҋ@�Ԋu
  ct_msg_get_max_wait               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11326';                                 --XXCOS:�ő�ҋ@����
  cv_msg_get_login                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11638';                                 --���O�C�����擾�G���[
  cv_msg_get_resp                   CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11639';                                 --�v���t�@�C��(�ؑ֗p�E��)�擾�G���[
  cv_order_qty_err                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11327';                                 --�󒍐��ʃG���[ 
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-00014';                                --�Ɩ����t�擾�G���[
  ct_msg_child_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-13855';                                --�q�i�ڃR�[�h�Ó����`�F�b�N�G���[
  ct_msg_subinv_mst_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13858';                                 --�ۊǏꏊ�}�X�^�`�F�b�N�G���[
  ct_msg_o_l_type_mst_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13859';                                 --�󒍃^�C�v�}�X�^(����)�`�F�b�N�G���[
  ct_msg_sls_cls_null_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13862';                                 --����敪�K�{�`�F�b�N�G���[
  ct_msg_sls_cls_mst_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13863';                                 --����敪�`�F�b�N�G���[
  ct_msg_chk_bus_low_type_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13864';                                 --�x���_�[�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_order_a_oif        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00134';                                 --�󒍏���OIF(���b�Z�[�W������)
--
  --�g�[�N��
  cv_tkn_profile                    CONSTANT  VARCHAR2(512) := 'PROFILE';                            --�v���t�@�C����
  cv_tkn_table                      CONSTANT  VARCHAR2(512) := 'TABLE';                              --�e�[�u����
  cv_tkn_key_data                   CONSTANT  VARCHAR2(512) := 'KEY_DATA';                           --�L�[���e���R�����g
  cv_tkn_api_name                   CONSTANT  VARCHAR2(512) := 'API_NAME';                           --���ʊ֐���
  cv_tkn_column                     CONSTANT  VARCHAR2(512) := 'COLMUN';                             --���ږ�
  cv_tkn_org_code                   CONSTANT  VARCHAR(512)  := 'ORG_CODE_TOK';                       --�݌ɑg�D�R�[�h
  cv_tkn_store_code                 CONSTANT  VARCHAR2(512) := 'STORE_CODE';                         --�X�܃R�[�h
  cv_tkn_item_code                  CONSTANT  VARCHAR2(512) := 'ITEM_CODE';                          --�i�ڃR�[�h
  cv_tkn_customer_code              CONSTANT  VARCHAR2(512) := 'CUSTOMER_CODE';                      --�ڋq�R�[�h
  cv_tkn_table_name                 CONSTANT  VARCHAR2(512) := 'TABLE_NAME';                         --�e�[�u����
  cv_tkn_line_no                    CONSTANT  VARCHAR2(512) := 'LINE_NO';                            --�s�ԍ�
  cv_tkn_order_no                   CONSTANT  VARCHAR2(512) := 'ORDER_NO';                           --�I�[�_�[NO
  cv_tkn_err_msg                    CONSTANT  VARCHAR2(512) := 'ERR_MSG';                            --�G���[���b�Z�[�W
  cv_tkn_data                       CONSTANT  VARCHAR2(512) := 'DATA';                               --���R�[�h�f�[�^
  cv_tkn_time                       CONSTANT  VARCHAR2(512) := 'TIME';                               --���ߎ���
  cv_tkn_param1                     CONSTANT  VARCHAR2(512) := 'PARAM1';                             --�p�����[�^
  cv_tkn_param2                     CONSTANT  VARCHAR2(512) := 'PARAM2';                             --�p�����[�^
  cv_tkn_param3                     CONSTANT  VARCHAR2(512) := 'PARAM3';                             --�p�����[�^
  cv_tkn_param4                     CONSTANT  VARCHAR2(512) := 'PARAM4';                             --�p�����[�^
  cv_tkn_param5                     CONSTANT  VARCHAR2(512) := 'PARAM5';                             --�p�����[�^
  cv_tkn_param6                     CONSTANT  VARCHAR2(512) := 'PARAM6';                             --�p�����[�^
  cv_tkn_param7                     CONSTANT  VARCHAR2(512) := 'PARAM7';                             --�p�����[�^
  cv_tkn_param8                     CONSTANT  VARCHAR2(512) := 'PARAM8';                             --�p�����[�^
  cv_tkn_param9                     CONSTANT  VARCHAR2(512) := 'PARAM9';                             --�p�����[�^
  cv_tkn_param10                    CONSTANT  VARCHAR2(512) := 'PARAM10';                            --�p�����[�^
  cv_cust_site_use_code             CONSTANT  VARCHAR2(10)  := 'SHIP_TO';                            --�ڋq�g�p�ړI�F�o�א�
  cv_tkn_request_id                 CONSTANT  VARCHAR2(512) := 'REQUEST_ID';                         --�v��ID
  cv_tkn_dev_status                 CONSTANT  VARCHAR2(512) := 'STATUS';                             --�X�e�[�^�X
  cv_tkn_message                    CONSTANT  VARCHAR2(512) := 'MESSAGE';                            --���b�Z�[�W
  --
  cv_str_file_id                    CONSTANT  VARCHAR2(128) := 'FILE_ID ';                           --FILE_ID
  cv_tkn_file_name                  CONSTANT  VARCHAR2(512) := 'FILE_NAME';                          --�t�@�C����
  cv_tkn_upload_date_time           CONSTANT  VARCHAR2(512) := 'UPLOAD_DATE_TIME';                   --�A�b�v���[�h����
  cv_tkn_file_upload_name           CONSTANT  VARCHAR2(512) := 'FILE_UPLOAD_NAME';                   --�t�@�C���A�b�v���[�h��
  cv_tkn_format_pattern             CONSTANT  VARCHAR2(512) := 'FORMAT_PATTERN';                     --�t�H�[�}�b�g�p�^�[��
--
  cv_normal_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A10_01';                   --�ʏ��
  cv_normal_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A10_02';                   --�ʏ�o��
  cv_case_uom_code                  CONSTANT  VARCHAR2(64)  := 'XXCOS1_CASE_UOM_CODE';
  ct_file_up_load_name              CONSTANT  VARCHAR2(64)  := 'XXCCP1_FILE_UPLOAD_OBJ';
  cv_c_kanma                        CONSTANT  VARCHAR2(1)   := ',';                                  --�J���}
  cv_line_feed                      CONSTANT  VARCHAR2(1)   := CHR(10);                              --���s�R�[�h
  cn_customer_div_cust              CONSTANT  VARCHAR2(4)   := '10';                                 --�ڋq
  cv_customer_div_chain             CONSTANT  VARCHAR2(4)   := '18';                                 --�`�F�[���X
  cv_item_status_code_y             CONSTANT  VARCHAR2(2)   := 'Y';                                  --�i�ڃX�e�[�^�X(�ڋq�󒍉\�t���O ('Y')(�Œ�l))
  cv_cust_status_active             CONSTANT  VARCHAR2(1)   := 'A';                                  --�ڋq�}�X�^�n�̗L���t���O�F�L��
  cv_yyyymmdd_format                CONSTANT  VARCHAR2(64)  := 'YYYYMMDD';                           --���t�t�H�[�}�b�g
  cv_yyyymmdds_format               CONSTANT  VARCHAR2(64)  := 'YYYY/MM/DD';                         --���t�t�H�[�}�b�g
  cv_order                          CONSTANT  VARCHAR2(64)  := 'ORDER';                              --�I�[�_�[
  cv_line                           CONSTANT  VARCHAR2(64)  := 'LINE';                               --���C��
  cv_00                             CONSTANT  VARCHAR2(64)  := '00';
  cv_con_status_error               CONSTANT  VARCHAR2(10)  := 'ERROR';                              -- �X�e�[�^�X�i�ُ�j
  cv_con_status_warning             CONSTANT  VARCHAR2(10)  := 'WARNING';                            -- �X�e�[�^�X�i�x���j
  cv_cons_n                         CONSTANT  VARCHAR2(1)   := 'N';
  cv_pre_orig_sys_doc_ref           CONSTANT  VARCHAR2(18)  := 'OE_ORDER_HEADERS_C';                 --orig_sys_document_ref
  cv_context_unset_y                CONSTANT  VARCHAR2(1)   := 'Y';                                  --�R���e�L�X�g���ݒ�'Y'
  cv_context_unset_n                CONSTANT  VARCHAR2(1)   := 'N';                                  --�R���e�L�X�g���ݒ�'N'
  cv_sales_class_must_y             CONSTANT  VARCHAR2(1)   := 'Y';                                  --����敪�ݒ�'Y'
  cv_sales_class_must_n             CONSTANT  VARCHAR2(1)   := 'N';                                  --����敪�ݒ�'N'
  cv_enabled_flag_y                 CONSTANT  VARCHAR2(1)   := 'Y';                                  --�L���t���O'Y'
  cv_line_dff_disp_y                CONSTANT  VARCHAR2(1)   := 'Y';                                  --�󒍖���DFF�\��'Y'
  cv_toku_chain_code                CONSTANT  VARCHAR2(4)   := 'TK00';                               --���̕��ڋq�i��
  cv_subinv_type_5                  CONSTANT  VARCHAR2(1)   := '5';                                  --�ۊǏꏊ�F�c�Ǝ�
  cv_subinv_type_6                  CONSTANT  VARCHAR2(1)   := '6';                                  --�ۊǏꏊ�F�t��VD
  cv_subinv_type_7                  CONSTANT  VARCHAR2(1)   := '7';                                  --�ۊǏꏊ�F����VD
  cn_quantity_tracked_on            CONSTANT  NUMBER        := 1;                                    --�p���L�^�v��
--
  cn_c_header                       CONSTANT  NUMBER        := 22;                                   --���ڐ�
  cn_begin_line                     CONSTANT  NUMBER        := 2;                                    --�ŏ��̍s
  cn_line_zero                      CONSTANT  NUMBER        := 0;                                    --0�s
  cn_item_header                    CONSTANT  NUMBER        := 1;                                    --���ږ�
-- ���ڏ����ԍ�
  cn_chain_code                     CONSTANT  NUMBER        := 1;                                    --�`�F�[���X�R�[�h
  cn_shop_code                      CONSTANT  NUMBER        := 2;                                    --�X�܃R�[�h
  cn_delivery                       CONSTANT  NUMBER        := 3;                                    --�[�i��
  cn_item_code                      CONSTANT  NUMBER        := 4;                                    --�i�ڃR�[�h
  cn_child_item_code                CONSTANT  NUMBER        := 6;                                    --�q�i�ڃR�[�h
  cn_total_time                     CONSTANT  NUMBER        := 7;                                    --���ߎ���
  cn_order_date                     CONSTANT  NUMBER        := 8;                                    --������
  cn_delivery_date                  CONSTANT  NUMBER        := 9;                                    --�[�i��
  cn_order_number                   CONSTANT  NUMBER        := 10;                                   --�I�[�_�[No.
  cn_line_number                    CONSTANT  NUMBER        := 11;                                   --�sNo.
  cn_order_cases_quantity           CONSTANT  NUMBER        := 12;                                   --�����P�[�X��
  cn_order_roses_quantity           CONSTANT  NUMBER        := 13;                                   --�����o����
  cn_pack_instructions              CONSTANT  NUMBER        := 14;                                   --�o�׈˗�No.
  cn_cust_po_number_stand           CONSTANT  NUMBER        := 15;                                   --�ڋq�����ԍ�
  cn_unit_price_stand               CONSTANT  NUMBER        := 16;                                   --�P��
  cn_selling_price_stand            CONSTANT  NUMBER        := 17;                                   --���P��
  cn_category_class_stand           CONSTANT NUMBER         := 18;                                   --���ދ敪
  cn_invoice_class_stand            CONSTANT  NUMBER        := 19;                                   --�`�[�敪
  cn_subinventory_stand             CONSTANT  NUMBER        := 20;                                   --�ۊǏꏊ
  cn_sales_class_stand              CONSTANT  NUMBER        := 21;                                   --����敪
  cn_ship_instructions_stand        CONSTANT  NUMBER        := 22;                                   --�o�׎w��
-- �ő�f�[�^�T�C�Y
  cn_chain_code_dlength             CONSTANT  NUMBER        := 4;                                    --�`�F�[���X�R�[�h
  cn_shop_code_dlength              CONSTANT  NUMBER        := 10;                                   --�X�܃R�[�h
  cn_delivery_dlength               CONSTANT  NUMBER        := 12;                                   --�[�i��
  cn_item_code_dlength              CONSTANT  NUMBER        := 8;                                    --�i�ڃR�[�h
  cn_child_item_code_dlength        CONSTANT  NUMBER        := 8;                                    --�q�i�ڃR�[�h
  cn_total_time_dlength             CONSTANT  NUMBER        := 2;                                    --���ߎ���
  cn_order_date_dlength             CONSTANT  NUMBER        := 8;                                    --������
  cn_delivery_date_dlength          CONSTANT  NUMBER        := 8;                                    --�[�i��
  cn_order_number_dlength           CONSTANT  NUMBER        := 16;                                   --�I�[�_�[No.
  cn_line_number_dlength            CONSTANT  NUMBER        := 2;                                    --�sNo.
  cn_order_cases_qty_dlength        CONSTANT  NUMBER        := 7;                                    --�����P�[�X��
  cn_order_roses_qty_dlength        CONSTANT  NUMBER        := 7;                                    --�����o����
  cn_packing_instructions           CONSTANT NUMBER         := 12;                                   --�o�׈˗�No.
  cn_cust_po_number_digit           CONSTANT NUMBER         := 12;                                   --�ڋq�����ԍ�
  cn_unit_price_digit               CONSTANT NUMBER         := 12;                                   --�P��(�S��)
  cn_unit_price_point               CONSTANT NUMBER         := 2;                                    --�P��(�����_�ȉ�)
  cn_selling_price_digit            CONSTANT NUMBER         := 10;                                   --���P��
  cn_category_class_digit           CONSTANT NUMBER         := 4;                                    --���ދ敪
  cn_invoice_class_digit            CONSTANT  NUMBER        := 2;                                    --�`�[�敪
  cn_subinventory_digit             CONSTANT  NUMBER        := 10;                                   --�ۊǏꏊ
  cn_sales_class_digit              CONSTANT  NUMBER        := 1;                                    --����敪
  cn_ship_instructions_digit        CONSTANT  NUMBER        := 40;                                   --�o�׎w��
  cn_priod                          CONSTANT  NUMBER        := 0;                                    --�����_
--
  cv_trunc_mm                       CONSTANT VARCHAR2(2)    := 'MM';                                 --���t�؎̗p
  cv_business_low_type_24           CONSTANT VARCHAR2(2)    :=  '24';                                --�Ƒԏ����ށF24.�t��VD(����)
  cv_business_low_type_25           CONSTANT VARCHAR2(2)    :=  '25';                                --�Ƒԏ����ށF25.�t��VD
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �󒍃f�[�^ BLOB�^
  gt_trans_order_data               xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;              --1�����z��
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;                --2�����z��
  gr_order_work_data                gt_var_data2;                                                    --�����p�ϐ�
--
  TYPE g_tab_order_oif_rec          IS TABLE OF oe_headers_iface_all%ROWTYPE INDEX BY PLS_INTEGER;   --�󒍃w�b�_OIF
  TYPE g_tab_t_order_line_oif_rec   IS TABLE OF oe_lines_iface_all%ROWTYPE   INDEX BY PLS_INTEGER;   --�󒍖���OIF
  TYPE g_tab_oif_act_rec            IS TABLE OF oe_actions_iface_all%ROWTYPE INDEX BY PLS_INTEGER;   --�󒍏���OIF
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                  INDEX BY PLS_INTEGER;   --�����_
  gr_order_oif_data                 g_tab_order_oif_rec;                                             --�󒍃w�b�_OIF
  gr_order_line_oif_data            g_tab_t_order_line_oif_rec;                                      --�󒍖���OIF
  gr_oif_act_data                   g_tab_oif_act_rec;                                               --�󒍏���OIF
  gr_g_login_base_info              g_tab_login_base_info_rec;                                       --�����_
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_inv_org_code                   VARCHAR2(128);                                                   --�c�Ɨp�݌ɑg�D�R�[�h
  gv_get_format                     VARCHAR2(128);                                                   --�󒍃\�[�X�̎擾
  gv_case_uom                       VARCHAR2(128);                                                   --
  gv_lookup_type                    VARCHAR2(128);                                                   --
  gv_meaning                        VARCHAR2(128);                                                   --
  gv_description                    VARCHAR2(128);                                                   --
  gv_f_lookup_type                  VARCHAR2(128);                                                   --�󒍃^�C�v
  gv_f_description                  VARCHAR2(128);                                                   --�󒍃\�[�X��
  gv_csv_file_name                  VARCHAR2(128);                                                   --CSV�t�@�C����
  gv_seq_no                         VARCHAR2(29);                                                    --�V�[�P���X
  gv_temp_oder_no                   VARCHAR2(128);                                                   --�ꎞ�ۊǗp�I�[�_�[No
  gv_temp_line_no                   VARCHAR2(128);                                                   --�ꎞ�ۊǏꏊ�s�ԍ�
  gv_temp_line                      VARCHAR2(128);                                                   --�ꎞ�ۊǏꏊ�sNo
  gv_get_highest_emp_flg            VARCHAR2(1);                                                     --�ŏ�ʎҏ]�ƈ��ԍ��擾�t���O
  gv_order                          VARCHAR2(128);
  gn_org_id                         NUMBER;                                                          --�c�ƒP��
  gn_get_stock_id_ret               NUMBER;                                                          --�c�Ɨp�݌ɑg�DID(�߂�lNUMBER)
  gn_lookup_code                    NUMBER;                                                          --�Q�ƃR�[�h
  gn_get_counter_data               NUMBER;                                                          --�f�[�^��
  gn_hed_cnt                        NUMBER;                                                          --�w�b�_�J�E���^�[
  gn_line_cnt                       NUMBER;                                                          --���׃J�E���^�[
  gn_hed_Suc_cnt                    NUMBER;                                                          --�����w�b�_�J�E���^�[
  gn_line_Suc_cnt                   NUMBER;                                                          --�������׃J�E���^�[
  gn_interval                       NUMBER;                                                          --�ҋ@�Ԋu
  gn_max_wait                       NUMBER;                                                          --�ő�ҋ@����
  gn_user_id                        NUMBER;                                                          --���O�C�����[�U�[ID
  gn_resp_id                        NUMBER;                                                          --���O�C���E��ID
  gn_resp_appl_id                   NUMBER;                                                          --���O�C���E�ӃA�v���P�[�V����ID
--
  gt_order_source_id                oe_order_sources.order_source_id%TYPE;                           --�󒍃\�[�XID
  gt_order_source_name              oe_order_sources.name%TYPE;                                      --�󒍃\�[�X��
  gt_order_type_name                oe_transaction_types_tl.name%TYPE;                               --�󒍃^�C�v
  gt_order_line_type_name           oe_lines_iface_all.line_type%TYPE;                               --�󒍖��׃^�C�v
  gt_file_id                        xxccp_mrp_file_ul_interface.file_id%TYPE;                        --�t�@�C��ID
  gt_order_data                     xxccp_mrp_file_ul_interface.file_data%TYPE;                      --�󒍃f�[�^
  gt_last_updated_by1               xxccp_mrp_file_ul_interface.created_by%TYPE;                     --�ŏI�X�V��
  gt_last_update_date               xxccp_mrp_file_ul_interface.creation_date%TYPE;                  --�ŏI�X�V��
  gt_customer_id                    xxcmm_cust_accounts.customer_id%TYPE;                            --�ڋqID
  gt_account_number                 hz_cust_accounts.account_number%TYPE;                            --�ڋq�R�[�h
  gt_delivery_base_code             xxcmm_cust_accounts.delivery_base_code%TYPE;                     --�[�i���_�R�[�h
  gt_item_code                      xxcmm_system_items_b.item_code%TYPE;                             --�i�ڃR�[�h
  gt_primary_unit_of_measure        mtl_system_items_b.primary_unit_of_measure%TYPE;                 --��P��
  gt_inventory_item_status_code     mtl_system_items_b.inventory_item_status_code%TYPE;              --�i�ڃX�e�[�^�X
  gt_prod_class_code                xxcmn_item_categories5_v.prod_class_code%TYPE;                   --����Ώۋ敪
  gt_item_class_code                xxcmn_item_categories5_v.item_class_code%TYPE;                   --���i�敪�R�[�h
  gt_item_no                        ic_item_mst_b.item_no%TYPE;                                      --�i�ڃR�[�h
  gt_base_code                      xxcmn_sourcing_rules.base_code%TYPE;                             --�o�׌��ۊǏꏊ
  gt_location_id                    per_all_assignments_f.location_id%TYPE;                          --���_�R�[�h1
  gt_cust_account_id                hz_cust_accounts.cust_account_id%TYPE;                           --���_�R�[�h2
  gt_cust_po_number                 oe_order_headers_all.cust_po_number%TYPE;                        --�ڋq�����ԍ�
  gt_case_num                       ic_item_mst_b.attribute11%TYPE;                                  --�P�[�X����
  gd_process_date                   DATE;                                                            --�Ɩ����t
  gt_line_context_unset_flg         fnd_lookup_values.attribute2%TYPE;                               --���׃R���e�L�X�g���ݒ�t���O
  gt_sales_class_must_flg           fnd_lookup_values.attribute3%TYPE;                               --����敪�ݒ�t���O
  gt_orig_sys_document_ref          oe_order_headers.orig_sys_document_ref%TYPE;                     --�󒍃\�[�X�Q��(�V�[�P���X�ݒ�)
--
  /**********************************************************************************
   * Procedure Name   : para_out
   * Description      : �p�����[�^�o��(A-0)
   ***********************************************************************************/
  PROCEDURE para_out(
    in_file_id    IN  NUMBER,    -- FILE_ID
    iv_get_format IN  VARCHAR2,  -- ���̓t�H�[�}�b�g�p�^�[��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'para_out'; -- �v���O������
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
    lv_key_info_file_uplod_name VARCHAR2(5000);  --key���
    lv_key_info_file_csv_name   VARCHAR2(5000);  --key���
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
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    ------------------------------------
    --�t�@�C���A�b�v���[�h����
    ------------------------------------
    BEGIN
    --
      SELECT flv.lookup_type     lookup_type,
             flv.lookup_code     lookup_code,
             flv.meaning         meaning,
             flv.description     description
        INTO gv_lookup_type,
             gn_lookup_code,
             gv_meaning,
             gv_description
        FROM fnd_lookup_types  flt,
             fnd_application   fa,
             fnd_lookup_values flv
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = ct_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = ct_file_up_load_name
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = cv_lang
         AND flv.enabled_flag           = cv_enabled_flag_y
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    --CSV�t�@�C������
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf
       WHERE xmf.file_id = in_file_id
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE global_get_f_csv_name_expt;
    END;
--
    ------------------------------------
    --0.�p�����[�^�o��
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name,
                   iv_name          => ct_msg_get_rep_h1,
                   iv_token_name1   => cv_tkn_param1,                  --�p�����[�^�P
                   iv_token_value1  => in_file_id,                     --�t�@�C��ID
                   iv_token_name2   => cv_tkn_param2,                  --�p�����[�^�Q
                   iv_token_value2  => iv_get_format                   --�t�H�[�}�b�g�p�^�[��
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name,
                   iv_name          => ct_msg_get_rep_h2,
                   iv_token_name1   => cv_tkn_param3,                 --�t�@�C���A�b�v���[�h����(���b�Z�[�W������)
                   iv_token_value1  => gv_meaning,                    --�t�@�C���A�b�v���[�h����
                   iv_token_name2   => cv_tkn_param4,                 --CSV�t�@�C����(���b�Z�[�W������)
                   iv_token_value2  => gv_csv_file_name               --CSV�t�@�C����
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1�s��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
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
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
  EXCEPTION
    --***** �t�@�C���A�b�v���[�h���̂̎擾�n���h��
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_f_uplod_name,
                     iv_token_name1  => cv_tkn_key_data,
                     iv_token_value1 => iv_get_format
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --***** CSV�t�@�C�����̎擾�n���h��
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_f_csv_name,
                     iv_token_name1  => cv_tkn_key_data,
                     iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 START ##########################################
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
  END para_out;
--
  /**********************************************************************************
   * Procedure Name   : <get_order_data>
   * Description      : <�t�@�C���A�b�v���[�hIF�󒍏��f�[�^�̎擾>(A-1)
   ***********************************************************************************/
   PROCEDURE get_order_data (
     in_file_id          IN  NUMBER,            -- 1.<file_id>
     on_get_counter_data OUT NUMBER,            -- 2.<�f�[�^��>
     ov_errbuf           OUT VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
     ov_retcode          OUT VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
     ov_errmsg           OUT VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_data'; -- �v���O������
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
    ln_conter     NUMBER := 0;
    ln_trans_data NUMBER := 0;
    ln_recep_data NUMBER := 0;
--
    -- *** ���[�J���ϐ� ***
--
    lv_key_info   VARCHAR2(5000);  --key���
    lv_tab_name   VARCHAR2(500);  --�e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***     BLOB�f�[�^�擾�֐�          ***
    -- ***************************************
    ------------------------------------
    -- 0.�ϐ��̏�����
    ------------------------------------
--    g_get_order_data_tab.delete;
    ln_conter      := 0;
    ln_trans_data  := 0;
    ln_recep_data  := 0;
--
    --
    ------------------------------------
    -- �t�@�C��ID�̎擾(���b�N)
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_id          file_id,           --�t�@�C��ID
             xmf.last_updated_by  last_updated_by,   --�ŏI�X�V��
             xmf.last_update_date last_update_date   --�ŏI�X�V��
        INTO gt_file_id,                             --�t�@�C��ID
             gt_last_updated_by1,                    --�ŏI�X�V��
             gt_last_update_date                     --�ŏI�X�V��
        FROM xxccp_mrp_file_ul_interface xmf
       WHERE xmf.file_id = in_file_id         --���̓p�����[�^��FILE_ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --***** �t�@�C��ID�̎擾�n���h��(�t�@�C��ID�̎擾(�f�[�^))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        --�L�[���̕ҏW����
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1  => cv_str_file_id, -- 1.�t�@�C��ID
          iv_data_value1 => in_file_id,     -- 1.�t�@�C��ID
          ov_key_info    => lv_key_info,    --�ҏW��L�[���
          ov_errbuf      => lv_errbuf,      --�G���[�E���b�Z�[�W
          ov_retcode     => lv_retcode,     --���^�[���R�[�h
          ov_errmsg      => lv_errmsg       --���[�U�E�G���[�E���b�Z�[�W
        );
        RAISE global_get_file_id_data_expt;
      WHEN global_data_lock_expt THEN
        --***** �t�@�C��ID�̎擾�n���h��(7.�t�@�C��ID�̎擾(���b�N))
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => ct_xxcos_appl_short_name,
                                 iv_name        => ct_msg_get_file_up_load
                               );
        RAISE global_data_lock_expt;

    END;
    ------------------------------------
    -- 1.�󒍏��f�[�^�擾
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id,          -- �t�@�C���h�c
      ov_file_data => gt_trans_order_data, -- �󒍃f�[�^(�z��^)
      ov_errbuf    => lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode   => lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --�߂�l�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      --�G���[�̏ꍇ
      --���b�Z�[�W(�e�[�u���F�t�@�C���A�b�v���[�hIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                       ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                       ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                       ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
       IF (lv_retcode = cv_status_normal) THEN
         RAISE global_get_order_data_expt;
       ELSE
         RAISE global_api_expt;
       END IF;
    END IF;
    --
    -- �󒍃f�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gt_trans_order_data.LAST < cn_begin_line ) THEN
      --���b�Z�[�W(�e�[�u���F�t�@�C���A�b�v���[�hIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                       ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                       ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                       ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
      IF (lv_retcode = cv_status_normal) THEN
        RAISE global_get_order_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �󒍃f�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gt_trans_order_data.COUNT = cn_line_zero ) THEN
      --���b�Z�[�W(�e�[�u���F�t�@�C���A�b�v���[�hIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                       ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                       ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                       ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
      IF (lv_retcode = cv_status_normal) THEN
        RAISE global_get_order_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    ------------------------------------
    -- 2.�f�[�^�������̎擾
    ------------------------------------
    --�f�[�^������
    on_get_counter_data := gt_trans_order_data.COUNT;
    gn_target_cnt := gt_trans_order_data.COUNT - 1;
--
--
  EXCEPTION
--
    --***** �󒍏��f�[�^�擾(1.�󒍏��f�[�^�擾)
    WHEN global_get_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�t�@�C��ID�̎擾�n���h��
    WHEN global_get_file_id_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --***** �t�@�C��ID�̎擾�n���h��
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_lock_err,
                     iv_token_name1  => cv_tkn_table,
                     iv_token_value1 => lv_tab_name
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
  END get_order_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_delete>
   * Description      : <�f�[�^�폜����>(A-2)
   ***********************************************************************************/
  PROCEDURE data_delete(
    in_file_id    IN  NUMBER  , -- ���̓p�����[�^��FILE_ID
    ov_errbuf     OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_delete'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_tab_name VARCHAR2(100); --�e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
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
  -- ***  �󒍏��f�[�^�폜����         ***
  -- ***************************************
--
  ------------------------------------
  -- 1.�󒍏��f�[�^�폜����
  ------------------------------------
    BEGIN
      DELETE 
        FROM xxccp_mrp_file_ul_interface xmf
        WHERE xmf.file_id = in_file_id
      ;                                      --   ���̓p�����[�^��FILE_ID
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_file_up_load
                     );
        RAISE global_del_order_data_expt;
    END;
--
  EXCEPTION
    --�폜�G���[�n���h��
    WHEN global_del_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_delete_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => NULL
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
  END data_delete;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-3)
   ***********************************************************************************/
  PROCEDURE init(
    iv_get_format IN  VARCHAR2,  -- 1.<���̓t�H�[�}�b�g�p�^�[��>
    in_file_id    IN  NUMBER,    -- 2.<FILE_ID>
    ov_errbuf     OUT VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
--
    lv_key_info                 VARCHAR2(5000);  --key���
    lv_key_info_order           VARCHAR2(5000);  --key���
    lv_key_info_sorec           VARCHAR2(5000);  --key���
    lv_key_info_file_if         VARCHAR2(5000);  --key���
    lv_get_format               VARCHAR2(128);   --�t�H�[�}�b�g�p�^�[��
--
    lv_order                    VARCHAR2(16);    --��
    lv_shipment                 VARCHAR2(16);    --�o��
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_data_cur
    IS
      SELECT lbi.base_code base_code
        FROM xxcos_all_or_login_base_info_v lbi
    ;
    -- *** ���[�J���E���R�[�h ***
    l_data_rec               get_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------
    -- 1.MO:�c�ƒP�ʂ̎擾
    ------------------------------------
    -- �c�ƒP�ʂ̎擾
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- �c�ƒP�ʂ̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gn_org_id IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_org_id
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 2.XXCOI:�݌ɑg�D�R�[�h�̎擾
    ------------------------------------
    --�݌ɑg�D�R�[�h�̎擾
    gv_inv_org_code := FND_PROFILE.VALUE( ct_inv_org_code );
--
    -- �݌ɑg�D�R�[�h�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_inv_org_code
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 3.�c�Ɨp�݌ɑg�DID�̎擾
    ------------------------------------
    --�c�Ɨp�݌ɑg�DID�̎擾
    gn_get_stock_id_ret := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_inv_org_code
                           );
    IF ( gn_get_stock_id_ret IS NULL ) THEN
      RAISE global_get_stock_org_id_expt;
    END IF;
--
    ------------------------------------
    -- 4.�Ɩ����t�擾
    ------------------------------------
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF  ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    ------------------------------------
    -- 5.�󒍃\�[�X���̎擾
    ------------------------------------
    BEGIN
      --
      SELECT flv.description   description  --�\�[�X��
        INTO gv_f_description
        FROM fnd_lookup_values flv
       WHERE flv.language    = cv_lang
         AND flv.lookup_type = ct_look_source_type
         AND flv.meaning     = iv_get_format
      ;
      -- �󒍃\�[�X�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_sorce
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_sorce_name
                             );
      RAISE global_get_order_source_expt;
      --
    END;
--
    ------------------------------------
    -- 6.�󒍃\�[�XID�̎擾
    ------------------------------------
    BEGIN
    --
      SELECT oos.order_source_id  order_source_id  --�󒍃\�[�XID
        INTO gt_order_source_id  --�󒍃\�[�XID
        FROM ont.oe_order_sources oos
       WHERE oos.name = gv_f_description
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_sorce
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_sorce_name
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 7.�󒍃^�C�v���̎擾(�w�b�_�[)
    ------------------------------------
    BEGIN
    --
      SELECT ott.name                 order_type_name     --�󒍃^�C�v��
        INTO gt_order_type_name                           --�󒍃^�C�v��
        FROM oe_transaction_types_tl  ott,
             oe_transaction_types_all otl,
             fnd_lookup_values flv
       WHERE flv.lookup_type           = ct_look_up_type
         AND flv.lookup_code           = cv_normal_order
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = cv_lang
         AND ott.transaction_type_id   = otl.transaction_type_id
         AND otl.transaction_type_code = cv_order
      ;
    --
    EXCEPTION
      --***** �󒍃^�C�v���̎擾�n���h��(6.�󒍃^�C�v���̎擾)
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type_name
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 8.�󒍃^�C�v���̎擾(����)
    ------------------------------------
    BEGIN
    --
      SELECT ott.name                                  order_line_type_name   --�󒍃^�C�v��
            ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg --���׃R���e�L�X�g���ݒ�t���O
            ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg   --����敪�ݒ�t���O
        INTO gt_order_line_type_name                                          --�󒍃^�C�v��
            ,gt_line_context_unset_flg                                        --���׃R���e�L�X�g���ݒ�t���O
            ,gt_sales_class_must_flg                                          --����敪�ݒ�t���O
        FROM oe_transaction_types_tl   ott,
             oe_transaction_types_all  otl, 
             fnd_lookup_values         flv
       WHERE flv.lookup_type           = ct_look_up_type
         AND flv.lookup_code           = cv_normal_shipment
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = cv_lang
         AND ott.transaction_type_id   = otl.transaction_type_id
         AND otl.transaction_type_code = cv_line
      ;
    --
    EXCEPTION
      --***** �󒍃^�C�v���̎擾�n���h��(6.�󒍃^�C�v���̎擾)
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type_name
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 9.�P�[�X�P��
    ------------------------------------
    gv_case_uom := FND_PROFILE.VALUE( cv_case_uom_code );
--
    -- �P�[�X�P�ʂ̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_case_uom IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_case_uom
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 10.�����_�擾
    ------------------------------------
    OPEN  get_data_cur;
    -- �o���N�t�F�b�`
    FETCH get_data_cur BULK COLLECT INTO gr_g_login_base_info;
    -- �J�[�\��CLOSE
    CLOSE get_data_cur;
--
    ------------------------------------
    -- 11.�ҋ@�Ԋu�̎擾
    ------------------------------------
    -- XXCOS:�ҋ@�Ԋu�̎擾
    gn_interval := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_interval ) );
--
    -- �ҋ@�Ԋu�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gn_interval IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_interval
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 12.�ő�ҋ@���Ԃ̎擾
    ------------------------------------
    -- XXCOS:�ő�ҋ@���Ԃ̎擾
    gn_max_wait := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_max_wait ) );
--
    -- �ő�ҋ@���Ԃ̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gn_max_wait IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_max_wait
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 13.���O�C�����[�U���擾
    ------------------------------------
    BEGIN
      SELECT    fnd_global.user_id       -- ���O�C�����[�UID
               ,fnd_global.resp_id       -- ���O�C���E��ID
               ,fnd_global.resp_appl_id  -- ���O�C���E�ӃA�v���P�[�V����ID
      INTO      gn_user_id
               ,gn_resp_id
               ,gn_resp_appl_id
      FROM      dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login             -- ���O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
    --
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  ct_xxcos_appl_short_name,
                       iv_name          =>  ct_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
     --***** �v���t�@�C���擾��O�n���h��(MO:�c�ƒP�ʂ̎擾)
     --***** �v���t�@�C���擾��O�n���h��(XXCOI:�݌ɑg�D�R�[�h�̎擾)
     --***** �v���t�@�C���擾��O�n���h��(�󒍃\�[�X�̎擾)
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_profile_err,
                     iv_token_name1  => cv_tkn_profile,
                     iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
     --***** �c�Ɨp�݌ɑg�DID�̎擾�O�n���h��(�c�Ɨp�݌ɑg�DID�̎擾)
    WHEN global_get_stock_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_inv_org,
                     iv_token_name1  => cv_tkn_org_code,
                     iv_token_value1 => gv_inv_org_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --***** �󒍃\�[�X���̎擾�n���h��(�󒍃\�[�X���̎擾)
    WHEN global_get_order_source_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_master_chk_err,
                     iv_token_name1  => cv_tkn_column,
                     iv_token_value1 => lv_key_info_sorec,
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => lv_key_info_order
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : <order_item_split>
   * Description      : <�󒍏��f�[�^�̍��ڕ�������>(A-4)
   ***********************************************************************************/
  PROCEDURE order_item_split(
    in_cnt            IN  NUMBER,            -- �f�[�^��
    ov_errbuf         OUT VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_item_split'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_rec_data     VARCHAR2(32765);
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    ------------------------------------
    -- 0.�ϐ��̏�����
    ------------------------------------
--
    -- ***************************************
    -- ***       ���ڕ�������              ***
    -- ***************************************
--
    <<get_tonya_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- �S���ڐ��`�F�b�N
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_trans_order_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_trans_order_data(i), cv_c_kanma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --�G���[
        lv_rec_data := gt_trans_order_data(i);
        RAISE global_cut_order_data_expt;
      END IF;
      --�J��������
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- ���ڕ���
        ------------------------------------
        gr_order_work_data(i)(j) := xxccp_common_pkg.char_delim_partition(
                                 iv_char     => gt_trans_order_data(i),
                                 iv_delim    => cv_c_kanma,
                                 in_part_num => j
                               );
      END LOOP;
--
    END LOOP get_tonya_loop;
--
  EXCEPTION
    --�t�@�C�����R�[�h���ڐ��s��v�n���h��
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  =>  cv_tkn_data,
                     iv_token_value1  =>  lv_rec_data
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
  END order_item_split;
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <���ڃ`�F�b�N>(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                   IN  NUMBER,    -- 1.<�f�[�^��>
    ov_chain_code            OUT VARCHAR2,  -- 1.<�`�F�[���X�R�[�h>
    ov_shop_code             OUT VARCHAR2,  -- 2.<�X�܃R�[�h>
    ov_delivery              OUT VARCHAR2,  -- 3.<�[�i��>
    ov_item_code             OUT VARCHAR2,  -- 4.<�i�ڃR�[�h>
    ov_child_item_code       OUT VARCHAR2,  -- 5.<�q�i�ڃR�[�h>
    ov_total_time            OUT VARCHAR2,  -- 6.<���ߎ���>
    od_order_date            OUT DATE,      -- 7.<������>
    od_delivery_date         OUT DATE,      -- 8.<�[�i��>
    ov_order_number          OUT VARCHAR2,  -- 9.<�I�[�_�[No.>
    ov_line_number           OUT VARCHAR2,  -- 10.<�sNo.>
    on_order_cases_quantity  OUT NUMBER,    -- 11.<�����P�[�X��>
    on_order_roses_quantity  OUT NUMBER,    -- 12.<�����o����>
    ov_packing_instructions  OUT VARCHAR2,  -- 13.�o�׈˗�No.
    ov_cust_po_number        OUT VARCHAR2,  -- 14.�ڋq����No.
    on_unit_price            OUT NUMBER,    -- 15.�P��
    on_selling_price         OUT NUMBER,    -- 16.���P��
    ov_category_class        OUT VARCHAR2,  -- 17.���ދ敪
    ov_invoice_class         OUT VARCHAR2,  -- 18.�`�[�敪
    ov_subinventory          OUT VARCHAR2,  -- 19.�ۊǏꏊ
    ov_sales_class           OUT VARCHAR2,  -- 20.����敪
    ov_ship_instructions     OUT VARCHAR2,  -- 21.�o�׎w��
    ov_errbuf                OUT VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_check'; -- �v���O������
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
    cn_tanka_zero           CONSTANT NUMBER := 0;
    cn_order_cases_qnt_zero CONSTANT NUMBER := 0;
    -- *** ���[�J���ϐ� ***
--
    lv_key_info   VARCHAR2(5000);  --key���
    ln_time       NUMBER;
    lv_err_msg    VARCHAR2(32767);  --�G���[���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***     ���ڂ̃`�F�b�N����          ***
    -- ***************************************
--
    --������
    lv_err_msg := NULL;
    gv_temp_oder_no := gr_order_work_data(in_cnt)(cn_order_number);
    gv_temp_line_no := TO_CHAR(lpad(TO_CHAR(in_cnt),5,0));
    gv_temp_line    := gr_order_work_data(in_cnt)(cn_line_number);
--
    ov_cust_po_number := NULL;    --�ڋq����No.
    on_unit_price     := NULL;    --�P��
    ov_category_class := NULL;    --���ދ敪
--
--------------------------
--  �`�F�[���X�R�[�h
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_chain_code),          -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_chain_code),                  -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_chain_code_dlength,                                      -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                       -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                               -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                              -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_chain_code)                --���ږ�
                    ) || cv_line_feed;
       --
   --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_chain_code := gr_order_work_data(in_cnt)(cn_chain_code) ;-- 1.<�`�F�[���X�R�[�h>
    END IF;
--
--------------------------
--  �X�܃R�[�h
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_shop_code),     -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_shop_code),             -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_shop_code_dlength,                                 -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shop_code)                 --���ږ�
                    ) || cv_line_feed;
       --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_shop_code := gr_order_work_data(in_cnt)(cn_shop_code) ; -- 2.<�X�܃R�[�h>
    END IF;
--
--------------------------
--  �[�i��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery),          -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_delivery_dlength,                              -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                     -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                    -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_delivery)                  --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_delivery             := gr_order_work_data(in_cnt)(cn_delivery);-- 3.<�[�i��>
    END IF;
--
--------------------------
--  �i�ڃR�[�h
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_item_code),        -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_item_code),                -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_item_code_dlength,                                    -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                            -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                           -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_item_code)                 --���ږ�
                    ) || cv_line_feed;
       --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_item_code := gr_order_work_data(in_cnt)(cn_item_code);  -- 4.<�i�ڃR�[�h>
    END IF;
--
--------------------------
--  �q�i�ڃR�[�h
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_child_item_code),      -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_child_item_code),              -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_child_item_code_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_child_item_code)           --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_child_item_code := gr_order_work_data(in_cnt)(cn_child_item_code);  -- 6.<�i�ڃR�[�h>
    END IF;
--
--------------------------
--  ���ߎ���
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_total_time),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_total_time),            -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_total_time_dlength,                                -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_total_time)                --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      IF ( gr_order_work_data(in_cnt)(cn_total_time) IS NOT NULL ) THEN
        --�����ԃ`�F�b�N
        IF ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) >= 0 ) AND
           ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) <= 23 ) THEN
          ov_total_time := to_char(gr_order_work_data(in_cnt)(cn_total_time)) ; -- 7.<���ߎ���>
        ELSE
          --���[�j���O���b�Z�[�W�쐬
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_chk_time_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                          iv_token_name4   => cv_tkn_time ,                                                    --���ߎ���(�g�[�N��)
                          iv_token_value4  => gr_order_work_data(in_cnt)(cn_total_time)                        --���ߎ���
                        ) || cv_line_feed;
        --
        END IF;
      END IF;
    END IF;
--
--------------------------
--  ������
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_date),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_date),            -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_order_date_dlength,                                -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_date)                --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      od_order_date := TO_DATE(gr_order_work_data(in_cnt)(cn_order_date),cv_yyyymmdd_format);     -- 8.<������>
    END IF;
--
--------------------------
--  �[�i��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery_date), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery_date),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_delivery_date_dlength,                             -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_delivery_date)             --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      od_delivery_date := TO_DATE(gr_order_work_data(in_cnt)(cn_delivery_date),cv_yyyymmdd_format);     -- 9.<�[�i��>
    END IF;
--
--------------------------
--  �I�[�_�[No.
--------------------------
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_order_number_dlength,                              -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      --���[�j���O
      IF ( lv_retcode = cv_status_warn ) THEN
        --���[�j���O���b�Z�[�W�쐬
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_get_format_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_number)              --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 10.<�I�[�_�[No.>
      END IF;
--
--------------------------
--  �sNo.
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_number),   -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_line_number),           -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_line_number_dlength,                               -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_line_number)               --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_line_number := gr_order_work_data(in_cnt)(cn_line_number);   -- 11.<�sNo.>
    END IF;
    --
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �����P�[�X��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_cases_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_cases_quantity),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_order_cases_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_cases_quantity)      --���ږ�
                    ) || cv_line_feed;
       --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 12.<�����P�[�X��>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �����o����
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_roses_quantity)      --���ږ�
                    ) || cv_line_feed;
       --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 13.<�����o����>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------------------
--  �����P�[�X���E�o�����K�{�`�F�b�N
--------------------------------------
    -- �����P�[�X���A�o�����̗��������ݒ�̏ꍇ
    IF ( NVL(on_order_cases_quantity,0) = 0 ) AND
       ( NVL(on_order_roses_quantity,0) = 0 ) THEN
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => cv_order_qty_err,                                                --�󒍐��ʃG���[
                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number) )                     --���ږ�
                         || cv_line_feed ;
       --
      lv_retcode := cv_status_warn;
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �o�׈˗�No.
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_pack_instructions), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_pack_instructions),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_packing_instructions,                              -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_pack_instructions)         --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_packing_instructions := gr_order_work_data(in_cnt)(cn_pack_instructions);  --14.<�o�׈˗�No.>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �ڋq�����ԍ�
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);   --15.<�ڋq�����ԍ�>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �P��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_unit_price_digit,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_unit_price_point,                                     -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                            -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                           -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_unit_price_stand)          --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);           --16.<�P��>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  ���P��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_selling_price_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_selling_price_stand),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_selling_price_digit,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                                   -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                               -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                              -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_selling_price_stand)       --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_selling_price := gr_order_work_data(in_cnt)(cn_selling_price_stand);           --17.<���P��>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  ���ދ敪
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_category_class_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_category_class_stand),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_category_class_digit,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_category_class_stand)      --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_category_class := gr_order_work_data(in_cnt)(cn_category_class_stand);    --18.<���ދ敪>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �`�[�敪
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_invoice_class_stand),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_invoice_class_stand),          -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_invoice_class_digit,                                      -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_invoice_class_stand)       --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_invoice_class := gr_order_work_data(in_cnt)(cn_invoice_class_stand); -- 19.<�`�[�敪>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �ۊǏꏊ
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_subinventory_stand),   -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_subinventory_stand),           -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_subinventory_digit,                                       -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_subinventory_stand)        --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_subinventory  := gr_order_work_data(in_cnt)(cn_subinventory_stand); --  20.<�ۊǏꏊ>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  ����敪
--------------------------
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_sales_class_stand),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_sales_class_stand),            -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_sales_class_digit,                                        -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      --���[�j���O
      IF ( lv_retcode = cv_status_warn ) THEN
        --���[�j���O���b�Z�[�W�쐬
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_get_format_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_sales_class_stand)         --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_sales_class := gr_order_work_data(in_cnt)(cn_sales_class_stand); -- 21.<����敪>
      END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  �o�׎w��
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_ship_instructions_stand),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_ship_instructions_stand),          -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_ship_instructions_digit,                                      -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                            -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                    -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                   -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      --���[�j���O���b�Z�[�W�쐬
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_ship_instructions_stand)   --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_ship_instructions := gr_order_work_data(in_cnt)(cn_ship_instructions_stand); -- 22.<�o�׎w��>
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
    WHEN global_item_check_expt THEN
      ov_errmsg := RTRIM(lv_err_msg, cv_line_feed);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <�}�X�^���̎擾����>(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
    in_cnt                     IN  NUMBER,   -- �f�[�^��
    iv_organization_id         IN  VARCHAR2, -- �g�DID
    in_line_no                 IN  NUMBER,   -- �sNO.
    iv_chain_store_code        IN  VARCHAR2, -- �`�F�[���X�R�[�h
    iv_shop_code               IN  VARCHAR2, -- �X�܃R�[�h
    iv_delivery                IN  VARCHAR2, -- �[�i��
    iv_item_code               IN  VARCHAR2, -- �i�ڃR�[�h
    id_request_date            IN  DATE,     -- �v����
    iv_child_item_code         IN VARCHAR2,  -- �q�i�ڃR�[�h
    iv_subinventory            IN  VARCHAR2, -- �ۊǏꏊ
    iv_sales_class             IN  VARCHAR2, -- ����敪
    ov_account_number          OUT VARCHAR2, -- �ڋq�R�[�h
    ov_delivery_base_code      OUT VARCHAR2, -- �[�i���_�R�[�h
    ov_salse_base_code         OUT VARCHAR2, -- ���� or �O�� ���_�R�[�h
    ov_item_no                 OUT VARCHAR2, -- �i�ڃR�[�h
    on_primary_unit_of_measure OUT VARCHAR2, -- ��P��
    ov_prod_class_code         OUT VARCHAR2, -- ���i�敪
    on_salesrep_id             OUT NUMBER,   -- �c�ƒS��ID
    ov_employee_number         OUT VARCHAR2, -- �ŏ�ʎҏ]�ƈ��ԍ�
    ov_errbuf                  OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_master_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    lv_key_info       VARCHAR2(5000);  --key���
    lv_get_format     VARCHAR2(128);   --�t�H�[�}�b�g�p�^�[��
    ln_item_chk       NUMBER;          --�i�ڃR�[�h�`�F�b�N
    lv_table_info     VARCHAR2(50);    --�e�[�u����
    lv_lien_no_name   VARCHAR2(50);    --�s
    lv_store_name     VARCHAR2(50);    --�Z���^�[
    lv_central_name   VARCHAR2(50);    --�`�F�[���X
    lv_delivery_name  VARCHAR2(50);    --�[�i��
    lv_stock_name     VARCHAR2(50);    --�݌ɃR�[�h
    lv_sej_cd_name    VARCHAR2(50);    --�i�ڃR�[�h
    ld_process_month  DATE;            --�Ɩ����t(���P��)
    ld_request_month  DATE;            --�v�����@(���P��)
    ln_item_id        NUMBER;          --�i��ID
    ln_parent_item_id NUMBER;          --�e�i��ID
    lv_subinv_chk     VARCHAR2(128);   --�ۊǏꏊ
    lv_sls_cls_chk    VARCHAR2(128);   --����敪
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***   �}�X�^�f�[�^�`�F�b�N����      ***
    -- ***************************************
--
    -- �Ɩ����t�����P�ʂɕύX(yyyy/mm/01:�ɕύX)
    ld_process_month := TRUNC(gd_process_date, cv_trunc_mm);
    -- �v�����@�����P�ʂɕύX(yyyy/mm/01:�ɕύX)
    ld_request_month := TRUNC(id_request_date, cv_trunc_mm);
--
--  ------------------------------------
--  -- 1.�ڋq�ǉ����}�X�^�̃`�F�b�N
--  ------------------------------------
    IF ( iv_delivery IS NOT NULL ) THEN
--    ------------------------------------
--    -- 1-1.�ڋq�ǉ����}�X�^�̃`�F�b�N
--    --  (�[�i��)
--    ------------------------------------
      BEGIN
        SELECT  accounts.account_number    account_number,                        -- �ڋq�R�[�h
                addon.delivery_base_code   delivery_base_code,                    -- �[�i���_�R�[�h
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code,                        -- ���� or �O�� ���_�R�[�h
                addon.ship_storage_code                                           -- �o�׌��ۊǏꏊ(EDI)                
        INTO    ov_account_number,                                                -- �ڋq�R�[�h
                ov_delivery_base_code,                                            -- �[�i���_�R�[�h
                ov_salse_base_code,                                               -- ����or�O�����_�R�[�h
                lv_subinv_chk                                                     -- �o�׌��ۊǏꏊ(EDI)
        FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
                xxcmm_cust_accounts            addon,                             -- �ڋq�A�h�I��
                hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
                hz_cust_site_uses_all          uses                               -- �ڋq�g�p�ړI
        WHERE   accounts.cust_account_id       = sites.cust_account_id
        AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
        AND     accounts.cust_account_id       = addon.customer_id
        AND     accounts.customer_class_code   = cn_customer_div_cust             -- �ڋq�敪�F10�i�ڋq�j
        AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
        AND     sites.org_id                   = gn_org_id
        AND     uses.org_id                    = gn_org_id
        AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
        AND     accounts.account_number        = iv_delivery
        ;
       --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_item_delivery_mst_expt; --�}�X�^���̎擾
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_add_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_delivery_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_customer_code
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  lv_delivery_name
                                        ,iv_item_name2  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_delivery
                                        ,iv_data_value2 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
--
    ELSE

--    ------------------------------------
--    -- 1-2.�ڋq�ǉ����}�X�^�̃`�F�b�N
--    --  (�`�F�[���X�R�[�h�ƓX�܃R�[�h�̃`�F�b�N)
--    ------------------------------------
      BEGIN
        IF ( iv_chain_store_code IS NULL ) AND ( iv_shop_code IS NULL ) THEN
          lv_key_info := in_line_no;
          RAISE global_cust_null_expt;
        ELSE
          SELECT  accounts.account_number    account_number,                        -- �ڋq�R�[�h
                  addon.delivery_base_code   delivery_base_code,                    -- �[�i���_�R�[�h
                  CASE
                    WHEN ld_process_month > ld_request_month THEN
                      addon.past_sale_base_code
                    ELSE
                      addon.sale_base_code
                  END                        sale_base_code,                        -- ���� or �O�� ���_�R�[�h
                  addon.ship_storage_code                                           -- �o�׌��ۊǏꏊ(EDI)
          INTO    ov_account_number,                                                -- �ڋq�R�[�h
                  ov_delivery_base_code,                                            -- �[�i���_�R�[�h
                  ov_salse_base_code,                                               -- ���� or �O�� ���_�R�[�h
                  lv_subinv_chk                                                     -- �o�׌��ۊǏꏊ(EDI)
          FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
                  xxcmm_cust_accounts            addon,                             -- �ڋq�A�h�I��
                  hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
                  hz_cust_site_uses_all          uses                               -- �ڋq�g�p�ړI
          WHERE   accounts.cust_account_id       = sites.cust_account_id
          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
          AND     accounts.cust_account_id       = addon.customer_id
          AND     accounts.customer_class_code   = cn_customer_div_cust             -- �ڋq�敪�F10�i�ڋq�j
          AND     addon.chain_store_code         = iv_chain_store_code              -- EDI�`�F�[���X�R�[�h
          AND     addon.store_code               = iv_shop_code                     -- �X�܃R�[�h
          AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
          AND     sites.org_id                   = gn_org_id
          AND     uses.org_id                    = gn_org_id
          AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
          ;
        END IF;
--
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          RAISE global_t_cust_too_many_expt; --�ڋq����TOO_MANY_ROWS�G���[
        WHEN NO_DATA_FOUND THEN
          RAISE global_cust_check_expt; --�}�X�^���̎擾
        --�ڋq�L�[���NULL
        WHEN global_cust_null_expt THEN
          RAISE global_cust_null_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_add_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_store_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_chain_code
                         );
          lv_central_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_shop_code
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  lv_store_name
                                        ,iv_item_name2  =>  lv_central_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_chain_store_code
                                        ,iv_data_value2 =>  iv_shop_code
                                        ,iv_data_value3 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
    END IF;
--
--  ------------------------------------
--  -- 2.�i�ڃ}�X�^�̃`�F�b�N(�i�ڃR�[�h)
--  ------------------------------------
    --������
    ln_item_chk := 0;
    BEGIN
      SELECT iim.item_no,                        --�i�ڃR�[�h
             iim.item_id,                        --�i��ID
             mib.primary_unit_of_measure,        --��P��
             mib.customer_order_enabled_flag,    --�ڋq�󒍉\�t���O
             iim.attribute26,                    --����Ώۋ敪
             xi5.prod_class_code,                --���i�敪�R�[�h
             iim.attribute11                     --�P�[�X����
      INTO   ov_item_no,                         --�i�ڃR�[�h
             ln_item_id,                         --�i��ID
             on_primary_unit_of_measure,         --��P��
             gt_inventory_item_status_code,      --�ڋq�󒍉\�t���O
             gt_prod_class_code,                 --����Ώۋ敪
             ov_prod_class_code,                 --���i�敪�R�[�h
             gt_case_num                         --�P�[�X����
      FROM   mtl_system_items_b         mib,     --�i�ڃ}�X�^
             ic_item_mst_b              iim,     --OPM�i�ڃ}�X�^
             xxcmn_item_categories5_v   xi5      --���i�敪View
      WHERE  mib.segment1          = iim.item_no
      AND    iim.item_id           = xi5.item_id
      AND    mib.organization_id   = iv_organization_id  --�g�DID
      AND    iim.item_no           = iv_item_code    --�i�ڃR�[�h
      ;
      -- �i�ڃ}�X�^��񂪎擾�ł��Ȃ��ꍇ�̃G���[�ҏW
      IF ( ( ov_item_no IS NULL ) OR
           ( on_primary_unit_of_measure IS NULL ) OR
           ( gt_inventory_item_status_code IS NULL ) OR
           ( gt_prod_class_code IS NULL ) OR
           ( ov_prod_class_code IS NULL )
           OR ( gt_case_num IS NULL )
         )
      THEN
        lv_key_info := in_line_no;
        RAISE global_cus_sej_check_expt;
      END IF;
    --����Ώۋ敪��0
      IF ( gt_prod_class_code = 0 ) THEN
            lv_key_info := in_line_no;
            RAISE global_item_status_expt;
      END IF;
    --�ڋq�󒍉\�t���O
      IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
        lv_key_info := in_line_no;
        RAISE global_item_status_code_expt;
      END IF;
    EXCEPTION
        --����Ώۋ敪��0
        WHEN global_item_status_expt THEN
          RAISE global_item_status_expt;
        --�ڋq�󒍉\�t���O
        WHEN global_item_status_code_expt THEN
          RAISE global_item_status_code_expt;
        --�i�ڃ}�X�^��񂪎擾�G���[
        WHEN global_cus_sej_check_expt THEN
          RAISE global_cus_sej_check_expt;
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_cus_sej_check_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_sej_cd_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_sej_mstr
                         );
          lv_Stock_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_inv_org_id
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  lv_sej_cd_name
                                        ,iv_item_name2  =>  lv_Stock_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_item_code
                                        ,iv_data_value2 =>  iv_organization_id
                                        ,iv_data_value3 =>  in_line_no
                                       );
          IF (lv_retcode = cv_status_normal) THEN
            RAISE global_select_err_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
    END;
--
--  ------------------------------------
--  -- 3.�i�ڃ}�X�^�̃`�F�b�N(�q�i�ڃR�[�h)
--  ------------------------------------
    IF ( iv_child_item_code IS NOT NULL ) THEN
      --�q�i�ڃR�[�h��NULL�łȂ��ꍇ�A�`�F�b�N���s���B
      BEGIN
        SELECT xim.item_id
        INTO   ln_parent_item_id
        FROM   ic_item_mst_b              iim     --OPM�i�ڃ}�X�^
              ,xxcmn_item_mst_b           xim     --OPM�i�ڃA�h�I���}�X�^
        WHERE  iim.item_no   = iv_child_item_code
        AND    xim.item_id   = iim.item_id
        AND    id_request_date >= xim.start_date_active
        AND    id_request_date <= xim.end_date_active
        AND    xim.parent_item_id   = ln_item_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_child_item_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                        iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                        iv_token_value3  => gv_temp_line,                                                    --�sNo
                        iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                        iv_token_value4  => iv_child_item_code,                                              --�q�i�ڃR�[�h
                        iv_token_name5   => cv_tkn_param5,                                                   --�p�����[�^5(�g�[�N��)
                        iv_token_value5  => ov_item_no                                                       --�i�ڃR�[�h
                      );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
          ov_retcode := cv_status_warn;
      END;
    END IF;
--  ------------------------------------
--  -- 4.�ۊǏꏊ�}�X�^�̃`�F�b�N
--  ------------------------------------
    IF ( iv_subinventory IS NOT NULL ) THEN
      BEGIN
        SELECT msi.secondary_inventory_name  subinv_chk
        INTO   lv_subinv_chk
        FROM   mtl_secondary_inventories     msi
        WHERE  msi.organization_id           = iv_organization_id
        AND    msi.secondary_inventory_name  = iv_subinventory
        AND    NVL(msi.disable_date ,SYSDATE + 1) > SYSDATE
        AND    msi.quantity_tracked          = cn_quantity_tracked_on  --�p���L�^�v��
        -- �����܂��͎����_�ɕR�t���ۊǏꏊ
--        AND ( (msi.attribute13  = (SELECT xsecv.attribute1  subinv_type
--                                   FROM   xxcos_sale_exp_condition_v  xsecv
--                                   WHERE  xsecv.attribute2  = gt_order_type_name       --�󒍃^�C�v(�w�b�_)
--                                   AND    xsecv.attribute3  = gt_order_line_type_name  --�󒍃^�C�v(����)
--                                  )
--              )
--          OR  (msi.attribute7  IN (SELECT xlbi.base_code  base_code
--                                   FROM   xxcos_all_or_login_base_info_v  xlbi
--                                  )
--              )
--            )
        -- EDI�󒍌ڋq�̏ꍇ�A�u6�F�t��VD�v�u7�F����VD�v�ȊO
        -- ��L�ȊO�́u5�F�c�Ǝԁv�u6�F�t��VD�v�u7�F����VD�v�ȊO
        AND  ( (EXISTS (SELECT 1
                        FROM   xxcmm_cust_accounts  xca1
                        WHERE  xca1.chain_store_code  IS NOT NULL
                        AND    xca1.chain_store_code != cv_toku_chain_code --���̕��ڋq�i��
                        AND    xca1.store_code        IS NOT NULL
                        AND    xca1.customer_code     = ov_account_number
                       )
                AND     msi.attribute13 NOT IN ( cv_subinv_type_6 , cv_subinv_type_7 )
               )
          OR   (EXISTS (SELECT 1
                        FROM   xxcmm_cust_accounts  xca2
                        WHERE (xca2.chain_store_code  IS NULL
                        OR     xca2.chain_store_code  = cv_toku_chain_code --���̕��ڋq�i��
                        OR     xca2.store_code        IS NULL)
                        AND    xca2.customer_code     = ov_account_number
                       )
                AND     msi.attribute13 NOT IN ( cv_subinv_type_5 , cv_subinv_type_6 , cv_subinv_type_7 )
               )
             )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_subinv_mst_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                          iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                          iv_token_value3  => gv_temp_line,                                                    --�sNo
                          iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                          iv_token_value4  => iv_subinventory                                                  --�ۊǏꏊ
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
      END;
    END IF;
--  ------------------------------------
--  -- 5.����敪�̃`�F�b�N
--  ------------------------------------
    --����敪�ݒ�t���O��'Y'�̏ꍇ�̂݃`�F�b�N
    IF ( gt_sales_class_must_flg = cv_sales_class_must_y ) THEN
      --�K�{�`�F�b�N
      IF ( iv_sales_class IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_sls_cls_null_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => gt_sales_class_must_flg                                          --�󒍃^�C�v(����)
                    );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_warn;
      ELSE
        --�Ó����`�F�b�N
        BEGIN
          SELECT flv.lookup_code  sales_class_chk
          INTO   lv_sls_cls_chk
          FROM   fnd_lookup_values flv
          WHERE  flv.language     = cv_lang
          AND    flv.lookup_type  = ct_look_sales_class
          AND    flv.lookup_code  = iv_sales_class
          AND    flv.enabled_flag = cv_enabled_flag_y
          AND    flv.attribute6   = cv_line_dff_disp_y  --�󒍖���DFF�\���i���^�����j
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_sls_cls_mst_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                          iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                          iv_token_value3  => gv_temp_line,                                                    --�sNo
                          iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                          iv_token_value4  => iv_sales_class                                                   --����敪
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
        END;
      END IF;
    END IF;
--
--  ------------------------------------
--  -- 6.�c�ƒS���A�܂��͍ŏ�ʎ҂̎擾
--  ------------------------------------
    xxcos_common2_pkg.get_salesrep_id(
                                    on_salesrep_id     =>  on_salesrep_id      --�c�ƒS��ID
                                   ,ov_employee_number =>  ov_employee_number  --�ŏ�ʎҏ]�ƈ��ԍ�
                                   ,ov_errbuf          =>  lv_errbuf           --�G���[�E���b�Z�[�W
                                   ,ov_retcode         =>  lv_retcode          --���^�[���R�[�h
                                   ,ov_errmsg          =>  lv_errmsg           --���[�U�E�G���[�E���b�Z�[�W
                                   ,iv_account_number  =>  ov_account_number   --�ڋq�R�[�h
                                   ,id_target_date     =>  id_request_date     --���
                                   ,in_org_id          =>  gn_org_id           --�c�ƒP��ID
                                  );
    -- �ŏ�ʎ҂��擾�����ꍇ
    IF ( ov_employee_number IS NOT NULL ) THEN
      gv_get_highest_emp_flg := 'Y';
      RAISE global_get_highest_emp_expt;
    END IF;
    -- ���ʊ֐��̃��^�[���R�[�h������ȊO�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_get_salesrep_expt;
    END IF;
--
  EXCEPTION
    -- �ڋq���TOO_MANY�G���[
    WHEN global_t_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_tonya_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_chain_store_code,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => iv_shop_code,
                     iv_token_name3  => cv_tkn_param3,
                     iv_token_value3 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�}�X�^���̎擾
    WHEN global_cust_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_cust_chk_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => iv_chain_store_code,                                             --�`�F�[���X�R�[�h
                      iv_token_name5   => cv_tkn_param5,                                                   --�p�����[�^5(�g�[�N��)
                      iv_token_value5  => iv_shop_code                                                     --�X�܃R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --�}�X�^���̎擾
    WHEN global_item_delivery_mst_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_delivery_mst_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => iv_delivery                                                      --�[�i��R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --�f�[�^���o�G���[
    WHEN global_cus_sej_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_sej,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => iv_item_code                                                     --�i�ڃR�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --***** �ڋq�L�[���NULL
    WHEN global_cust_null_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_cust_null_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line                                                     --�sNo
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --***** ����Ώۋ敪
    WHEN global_item_status_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_sale_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => ov_item_no                                                       --�i�ڃR�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
     --***** �ڋq�󒍉\
    WHEN global_item_status_code_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_status_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => ov_item_no                                                       --�i�ڃR�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --���o�G���[
    WHEN global_select_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_table_info,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --�ŏ�ʎҏ]�ƈ��ԍ��擾��
    WHEN global_get_highest_emp_expt THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_set_emp_highest,
                      iv_token_name1   => cv_tkn_param1,                                --�p�����[�^�P(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                              --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                --�p�����[�^�Q(�g�[�N��)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),  --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                --�p�����[�^�R(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                 --�sNo    
                      iv_token_name4   => cv_tkn_err_msg,                               --�G���[���b�Z�[�W(�g�[�N��)
                      iv_token_value4  => lv_errmsg                                     --���ʊ֐��̃G���[���b�Z�[�W
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    --���ʊ֐�(�S���]�ƈ��擾)�G���[��
    WHEN global_get_salesrep_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
    --  �Ƒԏ����ނ̃`�F�b�N��O
    WHEN global_business_low_type_expt THEN
      ov_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  ct_xxcos_appl_short_name
                      , iv_name           =>  ct_msg_chk_bus_low_type_err
                      , iv_token_name1    =>  cv_tkn_param1                                               --  �p�����[�^1(�g�[�N��)
                      , iv_token_value1   =>  gv_temp_line_no                                             --  �s�ԍ�
                      , iv_token_name2    =>  cv_tkn_param2                                               --  �p�����[�^2(�g�[�N��)
                      , iv_token_value2   =>  gv_temp_oder_no                                             --  �I�[�_�[NO
                      , iv_token_name3    =>  cv_tkn_param3                                               --  �p�����[�^3(�g�[�N��)
                      , iv_token_value3   =>  gv_temp_line                                                --  �sNo
                      , iv_token_name4    =>  cv_tkn_param4                                               --  �p�����[�^4(�g�[�N��)
                      , iv_token_value4   =>  iv_delivery                                                 --  �[�i��R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_master_data;
--
  /**********************************************************************************
   * Procedure Name   : <security_checke>
   * Description      : <�Z�L�����e�B�`�F�b�N����>(A-7)
   ***********************************************************************************/
  PROCEDURE security_check(
    iv_delivery_base_code IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_customer_code      IN  VARCHAR2, -- �ڋq�R�[�h
    in_line_no            IN  NUMBER,   -- �sNO.(�s�ԍ�)
    ov_errbuf             OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'security_check'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_key_info          VARCHAR2(5000);  --key���
    lv_table_info        VARCHAR2(5000);  --�e�[�u����
    ln_flg               NUMBER;          --���[�J���t���O
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***  �Z�L�����e�B�`�F�b�N����       ***
    -- ***************************************
    ln_flg := 0;
    <<for_loop>>
    FOR i IN 1 .. gr_g_login_base_info.COUNT LOOP
      IF ( gr_g_login_base_info(i) = iv_delivery_base_code ) THEN
        ln_flg := 1;
      END IF;
    END LOOP for_loop;
--
    --�[�i���_�R�[�h�Ǝ����_�R�[�h�����Ⴀ��ꍇ
    IF ( ln_flg = 0 ) THEN
      RAISE global_security_check_expt;
    END IF;
--
  EXCEPTION
    --�Z�L�����e�B�`�F�b�N�G���[
    WHEN global_security_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => ct_xxcos_appl_short_name,
                    iv_name        => ct_msg_get_security_chk_err,
                    iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                    iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                    iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                    iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                    iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                    iv_token_value3  => gv_temp_line,                                                    --�sNo
                    iv_token_name4   => cv_tkn_param4,
                    iv_token_value4  => iv_customer_code,
                    iv_token_name5   => cv_tkn_param5,
                    iv_token_value5  => iv_delivery_base_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END security_check;
--
  /**********************************************************************************
   * Procedure Name   : <set_order_data>
   * Description      : <�f�[�^�ݒ菈��>(A-8)
   ***********************************************************************************/
  PROCEDURE set_order_data(
    in_cnt                   IN NUMBER,    -- �f�[�^��
    in_order_source_id       IN NUMBER,    -- �󒍃\�[�XID(�C���|�[�g�\�[�XID)
    iv_order_number          IN VARCHAR2,  -- �I�[�_�[NO.
    in_org_id                IN NUMBER,    -- �g�DID(�c�ƒP��)
    id_ordered_date          IN DATE,      -- �󒍓�(������)
    iv_order_type            IN VARCHAR2,  -- �󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
    in_salesrep_id           IN NUMBER,    -- �c�ƒS��ID
    iv_customer_po_number    IN VARCHAR2,  -- �ڋqPO�ԍ�(�ڋq�����ԍ�),�󒍃\�[�X�Q��
    iv_customer_number       IN VARCHAR2,  -- �ڋq�ԍ�
    id_request_date          IN DATE,      -- �v����(�[�i��)
    iv_orig_sys_line_ref     IN VARCHAR2,  -- �󒍃\�[�X���׎Q��(�sNo.)
    iv_line_type             IN VARCHAR2,  -- ���׃^�C�v(���׃^�C�v(�ʏ�o��)
    iv_inventory_item        IN VARCHAR2,  -- �i�ڃR�[�h
    in_ordered_quantity      IN NUMBER,    -- �󒍐���
    iv_order_quantity_uom    IN VARCHAR2,  -- �󒍐��ʒP��
    iv_customer_line_number  IN VARCHAR2,  -- �ڋq���הԍ�(�sNo.)
    iv_attribute9            IN VARCHAR2,  -- �t���b�N�X�t�B�[���h9(���ߎ���)
    iv_salse_base_code       IN VARCHAR2,  -- ���㋒�_�R�[�h
    iv_packing_instructions  IN VARCHAR2,  -- �o�׈˗�No.
    iv_cust_po_number        IN VARCHAR2,  -- �ڋq����No.
    in_unit_price            IN NUMBER,    -- �P��
    in_selling_price         IN NUMBER,    -- ���P��
    iv_category_class        IN VARCHAR2,  -- ���ދ敪
    iv_child_item_code       IN  VARCHAR2, -- �q�i�ڃR�[�h
    iv_invoice_class         IN  VARCHAR2, -- �`�[�敪
    iv_subinventory          IN  VARCHAR2, -- �ۊǏꏊ
    iv_sales_class           IN  VARCHAR2, -- ����敪
    iv_ship_instructions     IN  VARCHAR2, -- �o�׎w��
    ov_errbuf                OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_seq_no    NUMBER; --�V�[�P���X
    lt_attribute8     VARCHAR2(128); -- ���ߎ���
    lv_cust_po_number VARCHAR2(12);  -- �ڋq�����ԍ�
    lt_line_context   oe_order_lines.context%TYPE;
    lt_sales_class    oe_order_lines.attribute5%TYPE;  -- ����敪(�󒍖���DFF5)
    -- *** ���[�J���E�J�[�\�� ***
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
  -- *****************************************
  -- ***  �󒍃w�b�_/����OIF�f�[�^�ݒ菈�� ***
  -- *****************************************
--
    --�ۊǗp�̃I�[�_�[NO���󂩁A�ۊǗp�̃I�[�_�[NO�ƌ����R�[�h�̃I�[�_�[NO�ɑ��Ⴀ��ꍇ
    IF ( gt_cust_po_number IS NULL ) OR ( gt_cust_po_number != iv_customer_po_number )
     OR ( gt_account_number IS NULL ) OR ( gt_account_number != iv_customer_number )  THEN
      gt_cust_po_number := iv_customer_po_number;
      gt_account_number := iv_customer_number;
      -- �O���V�X�e���󒍔ԍ���������
      gt_orig_sys_document_ref := NULL;
--
      --�V�[�P���X���擾�B
      SELECT xxcos_orig_sys_doc_ref_s01.NEXTVAL seq_no
        INTO ln_seq_no
       FROM dual
      ;
      -- �O���V�X�e���󒍔ԍ��ɍ̔Ԃ����l��ݒ�
      gt_orig_sys_document_ref := cv_pre_orig_sys_doc_ref || TO_CHAR((lpad(ln_seq_no,11,0)));
      --�w�b�_��ݒ肵�܂��B
      --�J�E���gUP
      gn_hed_cnt := gn_hed_cnt + 1;
      --�󒍃w�b�_�[OIF
--
      --�ϐ��ɐݒ�
      gr_order_oif_data(gn_hed_cnt).order_source_id           := in_order_source_id;        --�󒍃\�[�XID(�C���|�[�g�\�[�XID)
      gr_order_oif_data(gn_hed_cnt).orig_sys_document_ref     := gt_orig_sys_document_ref;  --�󒍃\�[�X�Q��
      gr_order_oif_data(gn_hed_cnt).org_id                    := in_org_id;                 --�g�DID(�c�ƒP��)
      gr_order_oif_data(gn_hed_cnt).ordered_date              := id_ordered_date;           --�󒍓�(������)
      gr_order_oif_data(gn_hed_cnt).order_type                := iv_order_type;             --�󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
      gr_order_oif_data(gn_hed_cnt).context                   := iv_order_type;             --�󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
      gr_order_oif_data(gn_hed_cnt).salesrep_id               := in_salesrep_id;            --�c�ƒS��ID
      gr_order_oif_data(gn_hed_cnt).customer_po_number        := gt_cust_po_number;         --�ڋqPO�ԍ�(�ڋq�����ԍ�)
      gr_order_oif_data(gn_hed_cnt).customer_number           := gt_account_number;         --�ڋq�ԍ�
      gr_order_oif_data(gn_hed_cnt).request_date              := id_request_date;           --�v����
      gr_order_oif_data(gn_hed_cnt).attribute12               := iv_salse_base_code;        --attribute12(���㋒�_)
      gr_order_oif_data(gn_hed_cnt).attribute19               := iv_order_number;           --attribute19(�I�[�_�[No)
      gr_order_oif_data(gn_hed_cnt).attribute5                := iv_invoice_class;          --�`�[�敪
      gr_order_oif_data(gn_hed_cnt).shipping_instructions     := iv_ship_instructions;      --�o�׎w��
      gr_order_oif_data(gn_hed_cnt).created_by                := cn_created_by;             --�쐬��
      gr_order_oif_data(gn_hed_cnt).creation_date             := cd_creation_date;          --�쐬��
      gr_order_oif_data(gn_hed_cnt).last_updated_by           := cn_last_updated_by;        --�X�V��
      gr_order_oif_data(gn_hed_cnt).last_update_date          := cd_last_update_date;       --�ŏI�X�V��
      gr_order_oif_data(gn_hed_cnt).last_update_login         := cn_last_update_login;      --�ŏI���O�C��
      gr_order_oif_data(gn_hed_cnt).program_application_id    := cn_program_application_id; --�v���O�����A�v���P�[�V����ID
      gr_order_oif_data(gn_hed_cnt).program_id                := cn_program_id;             --�v���O����ID
      gr_order_oif_data(gn_hed_cnt).program_update_date       := cd_program_update_date;    --�v���O�����X�V��
      gr_order_oif_data(gn_hed_cnt).request_id                := NULL;                      --���N�G�X�gID
      gr_order_oif_data(gn_hed_cnt).attribute20               := iv_category_class;         --���ދ敪
    END IF;
--
    -- ���ߎ��Ԕ��菈��NULL�ȊO�̏ꍇ'00'��t�����Đݒ�
    -- (�����ߎ��Ԃ͖{��Attribute8�̈וϐ�����ύX)
    IF ( iv_attribute9 IS NOT NULL ) THEN
      lt_attribute8 := iv_attribute9 || cv_00;
    ELSE
      lt_attribute8 := NULL;
    END IF;
    lt_line_context := iv_line_type;
--
    -- ����敪�ݒ�t���O��'N'�̏ꍇ��NULL��ݒ�
    IF ( gt_sales_class_must_flg = cv_sales_class_must_n ) THEN
      lt_sales_class := NULL;
    ELSE
      lt_sales_class := iv_sales_class;
    END IF;
--
    --�󒍖���OIF
    gn_line_cnt := gn_line_cnt + 1;
    gr_order_line_oif_data(gn_line_cnt).order_source_id            := in_order_source_id;              --�󒍃\�[�XID(�C���|�[�g�\�[�XID)
    gr_order_line_oif_data(gn_line_cnt).orig_sys_document_ref      := gt_orig_sys_document_ref;        --�󒍃\�[�X�Q��
    gr_order_line_oif_data(gn_line_cnt).orig_sys_line_ref          := iv_orig_sys_line_ref;            --�󒍃\�[�X���׎Q��(�sNo.)
    gr_order_line_oif_data(gn_line_cnt).line_number                := TO_NUMBER(iv_orig_sys_line_ref); --�󒍖��׍s�ԍ�
    gr_order_line_oif_data(gn_line_cnt).org_id                     := in_org_id;                       --�g�DID(�c�ƒP��)
    gr_order_line_oif_data(gn_line_cnt).line_type                  := iv_line_type;                    --���׃^�C�v(���׃^�C�v(�ʏ�o��)
    gr_order_line_oif_data(gn_line_cnt).context                    := lt_line_context;                 --���׃R���e�L�X�g
    gr_order_line_oif_data(gn_line_cnt).inventory_item             := iv_inventory_item;               --�i�ڃR�[�h
    gr_order_line_oif_data(gn_line_cnt).ordered_quantity           := in_ordered_quantity;             --�󒍐���
    gr_order_line_oif_data(gn_line_cnt).order_quantity_uom         := iv_order_quantity_uom;           --�󒍐��ʒP��
    gr_order_line_oif_data(gn_line_cnt).salesrep_id                := in_salesrep_id;                  --�c�ƒS��ID
    gr_order_line_oif_data(gn_line_cnt).customer_po_number         := gt_cust_po_number;               --�ڋq�����ԍ�
    gr_order_line_oif_data(gn_line_cnt).customer_line_number       := iv_customer_line_number;         --�ڋq���הԍ�(�sNo.)
    gr_order_line_oif_data(gn_line_cnt).attribute5                 := lt_sales_class;                  --�t���b�N�X�t�B�[���h5(����敪)
    gr_order_line_oif_data(gn_line_cnt).attribute6                 := iv_child_item_code;              --�q�i�ڃR�[�h
    gr_order_line_oif_data(gn_line_cnt).attribute8                 := lt_attribute8;                   --�t���b�N�X�t�B�[���h8(���ߎ���)
    gr_order_line_oif_data(gn_line_cnt).request_date               := id_request_date;                 --�v����(�[�i��)
    gr_order_line_oif_data(gn_line_cnt).subinventory               := iv_subinventory;                 --�ۊǏꏊ
    gr_order_line_oif_data(gn_line_cnt).created_by                 := cn_created_by;                   --�쐬��
    gr_order_line_oif_data(gn_line_cnt).creation_date              := cd_creation_date;                --�쐬��
    gr_order_line_oif_data(gn_line_cnt).last_updated_by            := cn_last_updated_by;              --�X�V��
    gr_order_line_oif_data(gn_line_cnt).last_update_date           := cd_last_update_date;             --�ŏI�X�V��
    gr_order_line_oif_data(gn_line_cnt).last_update_login          := cn_last_update_login;            --�ŏI���O�C��
    gr_order_line_oif_data(gn_line_cnt).program_application_id     := cn_program_application_id;       --�v���O�����A�v���P�[�V����ID
    gr_order_line_oif_data(gn_line_cnt).program_id                 := cn_program_id;                   --�v���O����ID
    gr_order_line_oif_data(gn_line_cnt).program_update_date        := cd_program_update_date;          --�v���O�����X�V��
    gr_order_line_oif_data(gn_line_cnt).request_id                 := NULL;                            --���N�G�X�gID
    gr_order_line_oif_data(gn_line_cnt).packing_instructions       := iv_packing_instructions;         --�o�׈˗�No.
    gr_order_line_oif_data(gn_line_cnt).attribute10                := in_selling_price;                --���P��
    IF ( in_unit_price IS NOT NULL ) THEN
      gr_order_line_oif_data(gn_line_cnt).unit_list_price            := in_unit_price;                 --�P��
      gr_order_line_oif_data(gn_line_cnt).unit_selling_price         := in_unit_price;                 --�̔��P��
      gr_order_line_oif_data(gn_line_cnt).calculate_price_flag       := cv_cons_n;                     --���i�v�Z�t���O
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
  END set_order_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_insert>
   * Description      : <�f�[�^�o�^����>(A-8)
   ***********************************************************************************/
  PROCEDURE data_insert(
    ov_errbuf     OUT VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_insert'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_i        NUMBER;        --�J�E���^�[
    lv_tab_name VARCHAR2(100); --�e�[�u����
    ln_cnt      NUMBER;
    lv_key_info VARCHAR2(100); --�L�[���
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***  �󒍃w�b�_/����OIF�o�^����     ***
    -- ***************************************
--
    --�󒍃w�b�_OIF�o�^����
    BEGIN
      FORALL ln_i in 1..gr_order_oif_data.COUNT SAVE EXCEPTIONS
        INSERT INTO oe_headers_iface_all VALUES gr_order_oif_data(ln_i);
      --�����J�E���g
      gn_hed_Suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_order_h_oif
                     );
       RAISE global_insert_expt;
     END;
--
    --�󒍖���OIF�o�^����
    BEGIN
      FORALL ln_i in 1..gr_order_line_oif_data.COUNT
        INSERT INTO oe_lines_iface_all VALUES gr_order_line_oif_data(ln_i);
      --�����J�E���g
      gn_line_Suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_order_l_oif
                     );
       RAISE global_insert_expt;
    END;
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => ct_xxcos_appl_short_name
                     ,iv_name               => ct_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
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
  END data_insert;
--
  /**********************************************************************************
   * Procedure Name   : <call_imp_data>
   * Description      : <�󒍂̃C���|�[�g�v��>(A-9)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_imp_data'; -- �v���O������
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
    --�e�[�u���萔
    --�R���J�����g�萔
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
    cv_program2               CONSTANT VARCHAR2(13)  := 'XXCOS010A062C'; -- �󒍃C���|�[�g�G���[���m(Online�p�j
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
    -- *** ���[�J���ϐ� ***
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
    lv_program                VARCHAR2(50);
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***********************************
    -- ***  �󒍃f�[�^�o�^����         ***
    -- ***********************************
    --�R���J�����g�N��
--
    lv_program := cv_program2;
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => lv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => gv_f_description     --�󒍃\�[�X��
                     );
--
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_imp_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => NULL,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => NULL
                   );
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id   => ln_request_id,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
--
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) )
    THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_imp_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
    ELSIF ( lv_dev_status = cv_con_status_warning )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_imp_warning,
                       iv_token_name1  => cv_tkn_request_id,
                       iv_token_value1 => TO_CHAR( ln_request_id ),
                       iv_token_name2  => cv_tkn_dev_status,
                       iv_token_value2 => lv_dev_status,
                       iv_token_name3  => cv_tkn_message,
                       iv_token_value3 => lv_message
                     );
--
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
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
  END call_imp_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<�t�H�[�}�b�g�p�^�[��>
    ov_errbuf         OUT VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_cnt NUMBER;
    lv_shop_code               VARCHAR2(128);  -- �X�܃R�[�h
    lv_total_time              VARCHAR2(128);  -- ���ߎ���
    ld_order_date              DATE;           -- ������
    lod_delivery_date          DATE;           -- �[�i��
    lv_order_number            VARCHAR2(128);  -- �I�[�_�[No.
    lv_line_number             VARCHAR2(128);  -- �sNo.
    ln_order_roses_quantity    NUMBER;         -- �����o����
    lv_chain_code              VARCHAR2(128);  -- �`�F�[���X�R�[�h
    lv_item_code               VARCHAR2(128);  -- �i�ڃR�[�h
    ln_order_cases_quantity    NUMBER;         -- �����P�[�X��
    lv_delivery                VARCHAR2(128);  -- �[�i��
    lv_packing_instructions    VARCHAR2(128);  -- �o�׈˗�No.
    lv_cust_po_number          VARCHAR2(128);  -- �ڋq�����ԍ�
    ln_unit_price              NUMBER;         -- �P��
    ln_selling_price           NUMBER;         -- ���P��
    lv_category_class          VARCHAR2(128);  -- ���ދ敪
    lv_child_item_code         VARCHAR2(128);  -- �q�i�ڃR�[�h
    lv_invoice_class           VARCHAR2(128);  -- �`�[�敪
    lv_subinventory            VARCHAR2(128);  -- �ۊǏꏊ
    lv_sales_class             VARCHAR2(128);  -- ����敪
    lv_ship_instructions       VARCHAR2(2000); -- �o�׎w��
    lv_account_number          VARCHAR2(40);   -- �ڋq�R�[�h
    lv_delivery_base_code      VARCHAR2(40);   -- �[�i���_�R�[�h
    lv_salse_base_code         VARCHAR2(40);   -- ���_�R�[�h
    lv_item_no                 VARCHAR2(40);   -- �i�ڃR�[�h
    lv_primary_unit_of_measure VARCHAR2(40);   -- ��P��
    lv_item_class_code         VARCHAR2(40);   -- ���i�敪�R�[�h
    ln_salesrep_id             NUMBER;         -- �c�ƒS��ID
    lv_employee_number         VARCHAR2(40);   -- �ŏ�ʎ҉c�ƈ��ԍ�
    lv_customer_number         VARCHAR2(128);  -- �ڋq�ԍ�
    lv_inventory_item          VARCHAR2(128);  -- �i�ڃR�[�h
    ln_ordered_quantity        NUMBER;         -- �󒍐���
    lv_order_quantity_uom      VARCHAR2(128);  -- �󒍐��ʒP��
    lv_ret_status              VARCHAR2(1);    -- ���^�[���E�X�e�[�^�X
--
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
    gn_hed_Suc_cnt  := 0;
    gn_line_Suc_cnt := 0;
    gv_get_highest_emp_flg := NULL;
--
    ------------------------------------
    -- 0.���[�J���ϐ��̏�����
    ------------------------------------
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- --------------------------------------------------------------------
    -- * para_out         ��������                                    (A-0)
    -- --------------------------------------------------------------------
    para_out(
      in_file_id    => in_get_file_id,            -- 1.<file_id>
      iv_get_format => iv_get_format_pat,         -- 2.<�t�H�[�}�b�g�p�^�[��>
      ov_errbuf     => lv_errbuf,                 -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,                -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg                  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * get_order_data   �t�@�C���A�b�v���[�hIF�󒍏��f�[�^�̎擾  (A-1)
    -- --------------------------------------------------------------------
    get_order_data (
      in_file_id          => in_get_file_id,      -- 1.<file_id>
      on_get_counter_data => gn_get_counter_data, -- 2.<�f�[�^��>
      ov_errbuf           => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode          => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg           => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * data_delete       �f�[�^�폜����                             (A-2)
    -- --------------------------------------------------------------------
    data_delete(
      in_file_id  => in_get_file_id,              -- 1.<file_id>
      ov_errbuf   => lv_errbuf,                   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,                  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg                    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --�R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
    -- --------------------------------------------------------------------
    -- * init             ��������                                    (A-3)
    -- --------------------------------------------------------------------
    init(
      iv_get_format => iv_get_format_pat,         -- 1.<�t�H�[�}�b�g�p�^�[��>
      in_file_id    => in_get_file_id,            -- 2.<file_id>
      ov_errbuf     => lv_errbuf,                 -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,                -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg                  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * order_item_split �󒍏��f�[�^�̍��ڕ�������                (A-4)
    -- --------------------------------------------------------------------
    order_item_split(
      in_cnt            => gn_get_counter_data,   -- 1.<�f�[�^��>
      ov_errbuf         => lv_errbuf,             -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode        => lv_retcode,            -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg         => lv_errmsg              -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
--
    --������
    gt_cust_po_number := NULL;
    gn_hed_cnt        := 0;
    gn_line_cnt       := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- --------------------------------------------------------------------
      -- * item_check       ���ڃ`�F�b�N                                (A-5)
      -- --------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                                 -- 1.<�f�[�^��>
        ov_chain_code           => lv_chain_code,                     -- 1.<�`�F�[���X�R�[�h>
        ov_shop_code            => lv_shop_code,                      -- 2.<�X�܃R�[�h>
        ov_delivery             => lv_delivery,                       -- 3.<�[�i��>
        ov_item_code            => lv_item_code,                      -- 4.<�i�ڃR�[�h>
        ov_child_item_code      => lv_child_item_code,                -- 5.<�q�i�ڃR�[�h>
        ov_total_time           => lv_total_time,                     -- 6.<���ߎ���>
        od_order_date           => ld_order_date,                     -- 7.<������>
        od_delivery_date        => lod_delivery_date,                 -- 8.<�[�i��>
        ov_order_number         => lv_order_number,                   -- 9.<�I�[�_�[No.>
        ov_line_number          => lv_line_number,                    -- 10.<�sNo.>
        on_order_cases_quantity => ln_order_cases_quantity,           -- 11.<�����P�[�X��>
        on_order_roses_quantity => ln_order_roses_quantity,           -- 12.<�����o����>
        ov_packing_instructions => lv_packing_instructions,           -- 13.<�o�׈˗�No.>
        ov_cust_po_number       => lv_cust_po_number,                 -- 14.<�ڋq����No.>
        on_unit_price           => ln_unit_price,                     -- 15.<�P��>
        on_selling_price        => ln_selling_price,                  -- 16.<���P��>
        ov_category_class       => lv_category_class,                 -- 17.<���ދ敪>
        ov_invoice_class        => lv_invoice_class,                  -- 18.<�`�[�敪>
        ov_subinventory         => lv_subinventory,                   -- 19.<�ۊǏꏊ>
        ov_sales_class          => lv_sales_class,                    -- 20.<����敪>
        ov_ship_instructions    => lv_ship_instructions,              -- 21.<�o�׎w��>
        ov_errbuf               => lv_errbuf,                         -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode              => lv_retcode,                        -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg               => lv_errmsg                          -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --���[�j���O�ێ�
        lv_ret_status := cv_status_warn;
        --�����o��
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- --------------------------------------------------------------------
        -- * get_master_data   �}�X�^���̎擾����                       (A-6)
        -- --------------------------------------------------------------------
        get_master_data(
          in_cnt                     => i,                            -- 1.<�f�[�^��>
          iv_organization_id         => gn_get_stock_id_ret,          -- 2.<�g�DID>
          in_line_no                 => lv_line_number,               -- 3.<�sNO.>
          iv_chain_store_code        => lv_chain_code,                -- 4.<�`�F�[���X�R�[�h>
          iv_shop_code               => lv_shop_code,                 -- 5.<�X�܃R�[�h>
          iv_delivery                => lv_delivery,                  -- 6.<�[�i��>
          iv_item_code               => lv_item_code,                 -- 7.<�i�ڃR�[�h>
          id_request_date            => lod_delivery_date,            -- 8.<�v����>
          iv_child_item_code         => lv_child_item_code,           -- 9.<�q�i�ڃR�[�h>
          iv_subinventory            => lv_subinventory,              -- 10.<�ۊǏꏊ>
          iv_sales_class             => lv_sales_class,               -- 11.<����敪>
          ov_account_number          => lv_account_number,            -- 1.<�ڋq�R�[�h>
          ov_delivery_base_code      => lv_delivery_base_code,        -- 2.<�[�i���_�R�[�h>
          ov_salse_base_code         => lv_salse_base_code,           -- 3.<���_�R�[�h>
          ov_item_no                 => lv_item_no,                   -- 4.<�i�ڃR�[�h>
          on_primary_unit_of_measure => lv_primary_unit_of_measure,   -- 5.<��P��>
          ov_prod_class_code         => lv_item_class_code,           -- 6.<���i�敪�R�[�h>
          on_salesrep_id             => ln_salesrep_id,               -- 7.<�c�ƒS��ID>
          ov_employee_number         => lv_employee_number,           -- 8.<�ŏ�ʎ҉c�ƈ��ԍ�>
          ov_errbuf                  => lv_errbuf,                    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                 => lv_retcode,                   -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                  => lv_errmsg                     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --���[�j���O�ێ�
          lv_ret_status := cv_status_warn;
          --�����o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
        END IF;
      --
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * security_check    �Z�L�����e�B�`�F�b�N����                   (A-7)
      -- --------------------------------------------------------------------
        security_check(
          iv_delivery_base_code => lv_delivery_base_code,   -- 1.<�[�i���_�R�[�h>
          iv_customer_code      => lv_account_number,       -- 2.<�ڋq�R�[�h>
          in_line_no            => lv_line_number,          -- 3.<�sNO.>
          ov_errbuf             => lv_errbuf,               -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode            => lv_retcode,              -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg             => lv_errmsg                -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --���[�j���O�ێ�
          lv_ret_status := cv_status_warn;
          --�����o��
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
        END IF;
      END IF;
      --
--
      -- --------------------------------------------------------------------
      -- * set_order_data    �f�[�^�ݒ菈��                             (A-8)
      -- --------------------------------------------------------------------
      IF ( lv_ret_status = cv_status_normal ) THEN
        lv_customer_number       := lv_account_number;          -- �ڋq�ԍ�(�ڋq�R�[�h)
        lv_inventory_item        := lv_item_no;                 -- �݌ɕi��(�i�ڃR�[�h)
        ln_ordered_quantity      := ln_order_roses_quantity;    -- �󒍐���(�����o����)
        lv_order_quantity_uom    := lv_primary_unit_of_measure; -- �󒍐��ʒP��(��P��)
        IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) THEN
        -- �������ʃo�����ݒ肳��Ă���ꍇ
          -- �P�ʐݒ�
          lv_order_quantity_uom    := lv_primary_unit_of_measure;  -- �󒍐��ʒP��(��P��)
        ELSE
          lv_order_quantity_uom    := gv_case_uom;                 -- �󒍐��ʒP��(��P��)
        END IF;
        --
        IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) AND ( NVL( ln_order_cases_quantity , 0 ) <> 0 ) THEN
        -- �������ʃo���Ɣ������ʃP�[�X���ݒ肳��Ă���ꍇ
          -- 
          ln_ordered_quantity      := ( ln_order_cases_quantity * TO_NUMBER( gt_case_num ) ) + ln_order_roses_quantity;  -- �󒍐���(�����o����)
        ELSE
          -- 
          IF ( ln_order_cases_quantity = 0 ) THEN
            ln_order_cases_quantity := NULL;
          END IF;
          IF ( ln_order_roses_quantity = 0 ) THEN
            ln_order_roses_quantity := NULL;
          END IF;
          --
          ln_ordered_quantity    := NVL( ln_order_cases_quantity , ln_order_roses_quantity );
        END IF;
        --
        set_order_data(
          in_cnt                       => gn_get_counter_data,          -- 1.<�f�[�^��>
          in_order_source_id           => gt_order_source_id,           -- 1.<�󒍃\�[�XID(�C���|�[�g�\�[�XID)>
          iv_order_number              => lv_order_number,              -- 2.<�I�[�_�[NO.>
          in_org_id                    => gn_org_id,                    -- 3.<�g�DID(�c�ƒP��)>
          id_ordered_date              => ld_order_date,                -- 4.<�󒍓�(������)>
          iv_order_type                => gt_order_type_name,           -- 5.<�󒍃^�C�v(�󒍃^�C�v(�ʏ��)>
          in_salesrep_id               => ln_salesrep_id,               -- 6.<�S���c��ID>
          iv_customer_po_number        => lv_cust_po_number,            -- 7.<�ڋqPO�ԍ�(�ڋq�����ԍ�),�󒍃\�[�X�Q��>
          iv_customer_number           => lv_customer_number,           -- 8.<�ڋq�ԍ�>
          id_request_date              => lod_delivery_date,            -- 9.<�v����(�[�i��)>
          iv_orig_sys_line_ref         => lv_line_number,               -- 10.<�󒍃\�[�X���׎Q��(�sNo.)>
          iv_line_type                 => gt_order_line_type_name,      -- 11.<���׃^�C�v(���׃^�C�v(�ʏ�o��)>
          iv_inventory_item            => lv_inventory_item ,           -- 12.<�i�ڃR�[�h>
          in_ordered_quantity          => ln_ordered_quantity,          -- 13.<�󒍐���>
          iv_order_quantity_uom        => lv_order_quantity_uom,        -- 14.<�󒍐��ʒP��>
          iv_customer_line_number      => lv_line_number,               -- 15.<�ڋq���הԍ�(�sNo.)>
          iv_attribute9                => lv_total_time,                -- 16.<�t���b�N�X�t�B�[���h9(���ߎ���)>
          iv_salse_base_code           => lv_salse_base_code,           -- 17.<���㋒�_�R�[�h>
          iv_packing_instructions      => lv_packing_instructions,      -- 18.<�o�׈˗�No.>
          iv_cust_po_number            => lv_cust_po_number,            -- 19.<�ڋq�����ԍ�>
          in_unit_price                => ln_unit_price,                -- 20.<�P��>
          in_selling_price             => ln_selling_price,             -- 21.<���P��>
          iv_category_class            => lv_category_class,            -- 22.<���ދ敪>
          iv_child_item_code           => lv_child_item_code,           -- 23.<�q�i�ڃR�[�h>
          iv_invoice_class             => lv_invoice_class,             -- 24.<�`�[�敪>
          iv_subinventory              => lv_subinventory,              -- 25.<�ۊǏꏊ>
          iv_sales_class               => lv_sales_class,               -- 26.<����敪>
          iv_ship_instructions         => lv_ship_instructions,         -- 27.<�o�׎w��>
          ov_errbuf                    => lv_errbuf,                    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                   => lv_retcode,                   -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                    => lv_errmsg                     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP;
--
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * data_insert       �f�[�^�o�^����                             (A-8)
      -- --------------------------------------------------------------------
      data_insert(
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      END IF;
      -- --------------------------------------------------------------------
      -- * call_imp_data       �󒍂̃C���|�[�g�v��                    (A-9)
      -- --------------------------------------------------------------------
      call_imp_data(
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --���[�v��̃G���[�X�e�[�^�X���m�[�}���o�Ȃ��ꍇ(���[�j���O)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
    END IF;
    --�ŏ�ʎҏ]�ƈ��ԍ��擾�t���O��'Y'�ł���ꍇ
    IF ( gv_get_highest_emp_flg = 'Y' ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf            OUT VARCHAR2, --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    in_get_file_id    IN  NUMBER,   --   file_id
    iv_get_format_pat IN  VARCHAR2  --   �t�H�[�}�b�g�p�^�[��
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      in_get_file_id,     -- 1.<file_id>
      iv_get_format_pat,  -- 2.<�t�H�[�}�b�g�p�^�[��>
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
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
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_Suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_Suc_cnt)
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
END XXCOS005A10C;
/
