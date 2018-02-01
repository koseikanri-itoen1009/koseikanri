CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A08C (body)
 * Description      : CSV�t�@�C���̎󒍎捞
 * MD.050           : CSV�t�@�C���̎󒍎捞 MD050_COS_005_A08
 * Version          : 1.31
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
 *  get_ship_due_date      �o�ח\����̓��o                            (A-7)
 *  security_check         �Z�L�����e�B�`�F�b�N����                    (A-8)
 *  set_order_data         �f�[�^�ݒ菈��                              (A-9)
 *  data_insert            �f�[�^�o�^����                              (A-9)
 *  call_imp_data          �󒍂̃C���|�[�g�v��                        (A-10)
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.kitaura        �V�K�쐬
 *  2009/2/3      1.1   K.Atsushiba      COS_001 �Ή�
 *                                         �E(A-7)5.�[�i���ғ����`�F�b�N�̉ғ������o�֐��̃p�����[�^�u�ۊǑq�ɃR�[�h�v
 *                                           ��NULL�A�u���[�h�^�C���v��0�ɏC���B
 *                                         �E(A-7)7.�o�ח\����Z�o�̉ғ������o�֐��̃p�����[�^�u�ۊǑq�ɃR�[�h�v��
 *                                           NULL�ɏC���B
 *  2009/2/3      1.2   T.Miyata         COS_008,010,011 �Ή�
 *                                         �E�u2-1.�i�ڃA�h�I���}�X�^�̃`�F�b�N�v
 *                                              Disc�i�ڂ�Disc�i�ڃA�h�I���̌�����������
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              ���ۂ̏ꍇ�̒P�ʂ�NULL�˃v���t�@�C������擾�����P��(CS)�֏C��
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              �v�����Ɏ󒍓��ł͂Ȃ��[�i����ݒ�
 *                                         �E�uset_order_data    �f�[�^�ݒ菈���v
 *                                              �w�b�_�C���ׂ̃R���e�L�X�g�Ɋe�󒍃^�C�v��ݒ�
 *  2009/02/19    1.3   T.kitajima       �󒍃C���|�[�g�Ăяo���Ή�
 *                                       get_msg�̃p�b�P�[�W���C��
 *  2009/2/20     1.4   T.Miyashita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/04/06    1.5   T.Kitajima       [T1_0313]�z����ԍ��̃f�[�^�^�C��
 *                                       [T1_0314]�o�׌��ۊǏꏊ�擾�C��
 *  2009/05/19    1.6   T.Kitajima       [T1_0242]�i�ڎ擾���AOPM�i�ڃ}�X�^.�����i�����j�J�n�������ǉ�
 *                                       [T1_0243]�i�ڎ擾���A�q�i�ڑΏۊO�����ǉ�
 *  2009/07/10    1.7   T.Tominaga       [0000137]Interval,Max_wait��FND_PROFILE���擾
 *  2009/07/14    1.8   T.Miyata         [0000478]�ڋq���ݒn�̒��o�����ɗL���t���O��ǉ�
 *  2009/07/15    1.9   T.Miyata         [0000066]�N������R���J�����g��ύX�F�󒍃C���|�[�g�ˎ󒍃C���|�[�g�G���[���m
 *  2009/07/17    1.10  K.Kiriu          [0000469]�I�[�_�[No�f�[�^�^�s���Ή�
 *  2009/07/21    1.11  T.Miyata         [0000478�w�E�Ή�]TOO_MANY_ROWS��O�擾
 *  2009/08/21    1.12  M.Sano           [0000302]JAN�R�[�h����̕i�ڎ擾���ڋq�i�ڌo�R�ɕύX
 *  2009/10/30    1.13  N.Maeda          [0001113]XXCMN_CUST_ACCT_SITES2_V�̍i���ݎ���OU�ؑ֏�����ǉ�(org_id)
 *  2009/11/18    1.14  N.Maeda          [E_T4_00203]����CSV�u�o�׈˗�No.�v�ǉ��ɔ����C��
 *  2009/12/04    1.15  N.Maeda          [E_�{�ғ�_00330]
 *                                       ����CSV�捞���u���ߎ��ԁv�u�I�[�_�[No�v�u�o�ד��v�̔C�Ӎ��ډ��A�z����R�[�h�擾�����̍폜
 *  2009/12/07          N.Maeda          [E_�{�ғ�_00086] �o�ח\����̓��o�����C��
 *  2009/12/16    1.16  N.Maeda          [E_�{�ғ�_00495] ���ߎ��Ԃ�NULL����pIF���ݒ�ӏ��C��
 *  2009/12/28    1.17  N.Maeda          [E_�{�ғ�_00683]�o�ח\����擾�֐��ɂ�闂�ғ����Z�o�̒ǉ��B
 *  2010/01/12    1.18  M.Uehara         [E_�{�ғ�_01011]�≮CSV�捞���u�o�ד��v���o�^����Ă���ꍇ�A�󒍂̏o�ח\����ɓo�^�B
 *  2010/04/15    1.19  M.Sano           [E_�{�ғ�_02317] ���㋒�_�̔�������C��
 *  2010/04/23    1.20  S.Karikomi       [E_�{�ғ�_01719] �S���c�ƈ��擾�֐��ɂ��ŏ�ʎҏ]�ƈ��擾�̒ǉ�
 *  2010/12/03    1.21  H.Sekine         [E_�{�ғ�_04801] ���{���͂̑Ή��A���ꏤ�i�R�[�h(�q�R�[�h)�̑Ή��B
 *  2011/01/19    1.22  H.Sekine         [E_�{�ғ�_04801] �Z���^�[�R�[�h�̍ő包���ɂ���5����10�ɕύX
 *  2011/01/25    1.23  H.Sekine         [E_�{�ғ�_06397] CSV�t�@�C���̍sNo.�ɂ��Đ��l�^�`�F�b�N���s�Ȃ��悤�ɕύX
 *                                                        �󒍖���OIF�̖��׍s��CSV�t�@�C���̍sNo.���Z�b�g����悤�ɕύX                                                        
 *  2011/02/01    1.24  H.Sekine         [E_�{�ғ�_06457] �≮CSV�ɂ��ĒP����0�ƂȂ��Ă��܂���Q���C��
 *  2011/02/21    1.25  H.Sekine         [E_�{�ғ�_06614] ���ꏤ�i�R�[�h���ݒ肳��Ă���ꍇ�̏o�ח\����̓��o���@�̕ύX
 *  2012/01/10    1.26  Y.Horikawa       [E_�{�ғ�_08893] �≮CSV�捞���A�o�ח\�����NULL�Ƃ���悤�ɕύX
 *  2012/06/25    1.27  D.Sugahara       [E_�{�ғ�_09744]��OIF��肱�ڂ��Ή��i�ďo�R���J�����g��
 *                                                       �󒍃C���|�[�g�G���[���m(CSV�󒍎捞�p�j�ɕύX�j
 *  2015/07/24    1.28  S.Niki           [E_�{�ғ�_12961] �ԕi�A�ԕi�����A�󒍒����A�ϓ��d�C����A�b�v���[�h�\�ɏC��
 *  2015/10/29    1.29  Y.Shoji          [E_�{�ғ�_12961]
 *                                         �E �o�׎w�����ڂ�ǉ�
 *                                         �E�u�ʏ�����v�u�ԕi�����v�u�ԕi�󒍁v�́w�ڋq�����ԍ��x�w�P���x�̕K�{�`�F�b�N���O���A
 *                                            �l�������Ă��Ȃ��ꍇ�͎����œ��o
 *                                         �E�u�ʏ�����v�u�ԕi�����v�u�ԕi�󒍁v�́w�I�[�_�[NO�x�̕K�{�`�F�b�N�ǉ�
 *                                         �E�u�ϓ��d�C��v�́w�I�[�_�[NO�x�ɒl���ݒ肳��Ă����ꍇ��NULL��ݒ�
 *                                         �E�w�f�[�^��ʁx�̕K�{�`�F�b�N���O��
 *                                         �E�u�≮�v�u���ہv�́w����敪�x�̕K�{�`�F�b�N���O��
 *  2017/10/18    1.30  S.Niki           [E_�{�ғ�_14671] �����_�Z�L�����e�B�ύX
 *  2018/01/23    1.31  H.Sasaki         [E_�{�ғ�_14788] �ϓ��d�C��A�b�v���[�h���A�󒍂̃X�e�[�^�X���L���ςō쐬����
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
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  global_proc_date_err_expt         EXCEPTION;                                                       --�Ɩ����t�擾��O�n���h��
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
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
--****************************** 2009/07/21 1.11 T.Miyata ADD  START ******************************--
  global_t_cust_too_many_expt       EXCEPTION;                                                       --�≮�ڋq���TOO_MANY�G���[
  global_k_cust_too_many_expt       EXCEPTION;                                                       --���یڋq���TOO_MANY�G���[
--****************************** 2009/07/21 1.11 T.Miyata ADD  END   ******************************--
  global_cust_check_expt            EXCEPTION;                                                       --�}�X�^���̎擾(�ڋq�}�X�^�`�F�b�N�≮)
  global_item_delivery_mst_expt     EXCEPTION;                                                       --�}�X�^���̎擾(�ڋq�}�X�^�`�F�b�N����)
  global_cus_data_check_expt        EXCEPTION;                                                       --�}�X�^���̎擾(�f�[�^���o�G���[)
  global_item_sale_div_expt         EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڔ���Ώۋ敪�G���[)
  global_item_status_expt           EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڃX�e�[�^�X�G���[)
  global_item_master_chk_expt       EXCEPTION;                                                       --�}�X�^���̎擾(�i�ڃ}�X�^���݃`�F�b�N�G���[)
  global_cus_sej_check_expt         EXCEPTION;                                                       --�}�X�^���̎擾(SEJ���i�R�[�h)
  global_ship_due_date_expt         EXCEPTION;                                                       --�o�ח\����̓��o(�����\���A�h�I���}�X�^)
  global_delivery_code_expt         EXCEPTION;                                                       --�o�ח\����̓��o(�ғ����Z�o�֐�)
  global_security_check_expt        EXCEPTION;                                                       --�Z�L�����e�B�`�F�b�N
  global_ins_order_data_expt        EXCEPTION;                                                       --�f�[�^�o�^
  global_del_order_data_expt        EXCEPTION;                                                       --�f�[�^�폜
  global_select_err_expt            EXCEPTION;                                                       --���o�G���[
  global_operation_day_err_expt     EXCEPTION;                                                       --�ғ����`�F�b�N�G���[
  global_delivery_lt_err_expt       EXCEPTION;                                                       --�z��LT�擾
  global_item_status_code_expt      EXCEPTION;                                                       --�ڋq�󒍉\�G���[
  global_insert_expt                EXCEPTION;                                                       --�o�^�G���[
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  global_get_highest_emp_expt       EXCEPTION;                                                       --�ŏ�ʎҏ]�ƈ��ԍ��擾�n���h��
  global_get_salesrep_expt          EXCEPTION;                                                       --���ʊ֐�(�S���]�ƈ��擾)�G���[��
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- ************** Ver1.28 ADD START *************** --
  global_e_fee_item_cd_expt         EXCEPTION;                                                       --�ϓ��d�C���i�ڃR�[�h�G���[��
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
  global_business_low_type_expt     EXCEPTION;                                                        --  �Ƒԏ����ނ̃`�F�b�N��O
  global_electric_pay_expt          EXCEPTION;                                                        --  �x�������i�d�C��j�̃`�F�b�N��O
-- ************** 2018/01/23 V1.31 Added END      *************** --
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                       CONSTANT VARCHAR2(128) := 'XXCOS005A08C';                        -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCOS';                                             --�̕��Z�k�A�v����
  ct_xxccp_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCCP';                                             --����
--
  --
  ct_prof_org_id                    CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'ORG_ID';                                            --�c�ƒP��
  ct_prod_ou_nm                     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_ITOE_OU_MFG';                                --���Y�c�ƒP��
  ct_inv_org_code                   CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOI1_ORGANIZATION_CODE';                          --�݌ɑg�D�R�[�h
  ct_look_source_type               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_ODR_SRC_MST_005_A08';                        --�N�C�b�N�R�[�h�^�C�v
  ct_look_up_type                   CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_TRAN_TYPE_MST_005_A08';                      --�N�C�b�N�R�[�h�^�C�v
-- ************** Ver1.28 ADD START *************** --
  ct_look_sales_class               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_SALE_CLASS';                                 --�N�C�b�N�R�[�h�^�C�v(����敪)
-- ************** Ver1.28 ADD END   *************** --
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  ct_prof_interval                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_INTERVAL';                                   --�ҋ@�Ԋu
  ct_prof_max_wait                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_MAX_WAIT';                                   --�ő�ҋ@����
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
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
  ct_msg_get_distribution_mstr      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00118';                                 --�����\���A�h�I���}�X�^
  ct_msg_get_format_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11251';                                 --���ڃt�H�[�}�b�g�G���[���b�Z�[�W
  ct_msg_get_cust_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11252';                                 --�ڋq�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_item_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11253';                                 --�i�ڃ}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_ship_due_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11254';                                 --�o�ח\����`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_security_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11255';                                 --�Z�L�����e�B�[�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_master_chk_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11256';                                 --�}�X�^�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_ship_func_chk_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11257';                                 --�o�ח\����`�F�b�N�֐��G���[���b�Z�[�W
  ct_msg_get_item_sale_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11258';                                 --�i�ڔ���Ώۋ敪�G���[
  ct_msg_get_item_status_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11259';                                 --�i�ڃX�e�[�^�X�G���[
  ct_msg_get_lien_no                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11260';                                 --�s�ԍ�(���b�Z�[�W������)
  ct_msg_get_multiple_store_code    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11261';                                 --�`�F�[���X�R�[�h(���b�Z�[�W������)
  ct_msg_get_central_code           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11262';                                 --�Z���^�[�R�[�h(���b�Z�[�W������)
  ct_msg_get_jan_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11263';                                 --JAN�R�[�h(���b�Z�[�W������)
  ct_msg_inv_org_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11264';                                 --�݌ɑg�D�R�[�h(���b�Z�[�W������)
  ct_msg_get_itme_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11265';                                 --�i�ڃR�[�h(���b�Z�[�W������)
  ct_msg_get_delivery_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11266';                                 --�z����R�[�h(���b�Z�[�W������)
  ct_msg_get_delivery_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11267';                                 --�[�i��(���b�Z�[�W������)
  ct_msg_get_warehouse_code         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11268';                                 --�ۊǑq�ɃR�[�h(���b�Z�[�W������)
  ct_msg_delivery_mst_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11269';                                 --�ڋq�}�X�^�`�F�b�N�G���[
  ct_msg_get_item_sej               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11270';                                 --�i�ڃ}�X�^�`�F�b�N�G���[(SEJ���i�R�[�h)
  ct_msg_get_code_division_from     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11271';                                 --�R�[�h�敪FROM(���b�Z�[�W������)
  ct_msg_get_stock_code_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11272';                                 --���o�ɏꏊ�R�[�hFROM(���b�Z�[�W������)
  ct_msg_get_code_division_to       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11273';                                 --�R�[�h�敪TO(���b�Z�[�W������)
  ct_msg_get_stock_place_code_to    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11274';                                 --���o�ɏꏊ�R�[�hTO(���b�Z�[�W������)
  ct_msg_get_shed_id                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11275';                                 --�o�Ɍ`��ID(���b�Z�[�W������)
  ct_msg_get_basic_date             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11276';                                 --���(�K�p�����)(���b�Z�[�W������)
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
  ct_msg_get_ou_nm                  CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11288';                                 --���Y�c�ƒP��
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
  ct_msg_get_delivery_tl_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11298';                                 --�z��TL�G���[���b�Z�[�W
  ct_msg_get_sej_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11299';                                 --SEJ���i�R�[�h
  ct_msg_get_imp_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11300';                                 --�R���J�����g�G���[���b�Z�[�W
--****************************** 2009/07/14 1.8 T.Miyata MOD  START ******************************--
  ct_msg_get_imp_warning            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13851';                                 --�R���J�����g���[�j���O���b�Z�[�W
--****************************** 2009/07/14 1.8 T.Miyata MOD  END   ******************************--
--
--****************************** 2009/07/21 1.11 T.Miyata ADD  START ******************************--
  ct_msg_get_tonya_toomany          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13852';                                 --�≮�ڋqTOO_MANY_ROWS��O�G���[���b�Z�[�W
  ct_msg_get_kokusai_toomany        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13853';                                 --���یڋqTOO_MANY_ROWS��O�G���[���b�Z�[�W
--****************************** 2009/07/21 1.11 T.Miyata ADD  END   ******************************--
--
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  ct_msg_set_emp_highest            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13854';                                 --�S���c�ƈ��ŏ�ʎҐݒ胁�b�Z�[�W
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  ct_msg_get_interval               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11325';                                 --XXCOS:�ҋ@�Ԋu
  ct_msg_get_max_wait               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11326';                                 --XXCOS:�ő�ҋ@����
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  cv_msg_get_login                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11638';                                 --���O�C�����擾�G���[
  cv_msg_get_resp                   CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11639';                                 -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
  cv_msg_get_login_prod             CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11640';                                 -- �ؑ֐惍�O�C�����擾�G���[
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cv_order_qty_err                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11327';
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-00014';                                -- �Ɩ����t�擾�G���[
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
-- ***************************** 2010/12/03 1.21 H.Sekine ADD START  ***************************** --
  ct_msg_child_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-13855';                                -- �q�i�ڃR�[�h�Ó����`�F�b�N�G���[
-- ***************************** 2010/12/03 1.21 H.Sekine ADD END    ***************************** --
-- ************** Ver1.28 ADD START *************** --
  ct_msg_get_e_fee_item_cd  CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13856';                                 -- XXCOS:�ϓ��d�C���i�ڃR�[�h
  ct_msg_e_fee_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13857';                                 -- �ϓ��d�C���i�ڃR�[�h�`�F�b�N�G���[
  ct_msg_subinv_mst_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13858';                                 -- �ۊǏꏊ�}�X�^�`�F�b�N�G���[
  ct_msg_o_l_type_mst_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13859';                                 -- �󒍃^�C�v�}�X�^(����)�`�F�b�N�G���[
  ct_msg_chk_bara_qnt_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13860';                                 -- �ϓ��d�C�㔭���o�����G���[
  ct_msg_data_type_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13861';                                 -- �f�[�^��ʃ`�F�b�N�G���[
  ct_msg_sls_cls_null_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13862';                                 -- ����敪�K�{�`�F�b�N�G���[
  ct_msg_sls_cls_mst_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13863';                                 -- ����敪�`�F�b�N�G���[
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
  ct_msg_chk_bus_low_type_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13864';                                 -- �x���_�[�`�F�b�N�G���[���b�Z�[�W
  ct_msg_chk_electric_pay_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13865';                                 -- �x�������i�d�C��j�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_order_a_oif        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00134';                                 -- �󒍏���OIF(���b�Z�[�W������)
  ct_msg_get_ordup_biz_ctr      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13866';                                 -- XXCOS:�󒍃A�b�v���[�h�����Z���^�[(���b�Z�[�W������)
-- ************** 2018/01/23 V1.31 Added END      *************** --
--
  --�g�[�N��
  cv_tkn_profile                    CONSTANT  VARCHAR2(512) := 'PROFILE';                            --�v���t�@�C����
  cv_tkn_table                      CONSTANT  VARCHAR2(512) := 'TABLE';                              --�e�[�u����
  cv_tkn_key_data                   CONSTANT  VARCHAR2(512) := 'KEY_DATA';                           --�L�[���e���R�����g
  cv_tkn_api_name                   CONSTANT  VARCHAR2(512) := 'API_NAME';                           --���ʊ֐���
  cv_tkn_column                     CONSTANT  VARCHAR2(512) := 'COLMUN';                             --���ږ�
  cv_tkn_store_code                 CONSTANT  VARCHAR2(512) := 'STORE_CODE';                         --�X�܃R�[�h
  cv_tkn_item_code                  CONSTANT  VARCHAR2(512) := 'ITEM_CODE';                          --�i�ڃR�[�h
  cv_tkn_customer_code              CONSTANT  VARCHAR2(512) := 'CUSTOMER_CODE';                      --�ڋq�R�[�h
  cv_tkn_table_name                 CONSTANT  VARCHAR2(512) := 'TABLE_NAME';                         --�e�[�u����
  cv_tkn_line_no                    CONSTANT  VARCHAR2(512) := 'LINE_NO';                            --�s�ԍ�
  cv_tkn_order_no                   CONSTANT  VARCHAR2(512) := 'ORDER_NO';                           --�I�[�_�[NO
  cv_tkn_jan_code                   CONSTANT  VARCHAR2(512) := 'JAN_CODE';                           --JAN�R�[�h
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
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  cv_resp_prod                      CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- �v���t�@�C���F���Y�ւ̐ؑ֗p�E��
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_e_fee_item_cd                  CONSTANT  VARCHAR2(50)  := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';      -- �v���t�@�C���F�ϓ��d�C���i�ڃR�[�h
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
  cv_order_up_bis_center            CONSTANT  VARCHAR2(50)  := 'XXCOS1_ORDER_UPLOAD_BIS_CENTER';  --  �v���t�@�C���F�󒍃A�b�v���[�h�����Z���^�[
-- ************** 2018/01/23 V1.31 Added END      *************** --
--
  cv_normal_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_01';                   --�ʏ��
  cv_normal_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_02';                   --�ʏ�o��
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cv_mihon_order                    CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_03';                   --���{��
  cv_mihon_shipment                 CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_04';                   --���{�o��
  cv_koukoku_order                  CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_05';                   --�L����`��
  cv_koukoku_shipment               CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_06';                   --�L����`�o��
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_return_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_07';                   --�ԕi��
  cv_return_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_08';                   --�ԕi�o��
  cv_revision_nrm_order             CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_09';                   --�ʏ������
  cv_revision_ret_order             CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_10';                   --�ԕi������
  cv_return                         CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_17';                   --�ԕi
-- ************** Ver1.28 ADD END   *************** --
  cv_order_source_store             CONSTANT  VARCHAR2(64)  := 'XXCOS1_ORDER_SOURCE_STORE';          --�≮CSV
  cv_order_source_inter             CONSTANT  VARCHAR2(64)  := 'XXCOS1_ORDER_SOURCE_INTER';          --����CSV
  cv_case_uom_code                  CONSTANT  VARCHAR2(64)  := 'XXCOS1_CASE_UOM_CODE';
  ct_file_up_load_name              CONSTANT  VARCHAR2(64)  := 'XXCCP1_FILE_UPLOAD_OBJ';
  cv_tonya_format                   CONSTANT  VARCHAR2(4)   := '100';                                --�≮CSV
  cv_kokusai_format                 CONSTANT  VARCHAR2(4)   := '101';                                --����CSV
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cv_mihon_format                   CONSTANT  VARCHAR2(4)   := '102';                                --���{CSV
  cv_koukoku_format                 CONSTANT  VARCHAR2(4)   := '103';                                --�L����`CSV
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_revision_nrm_format            CONSTANT  VARCHAR2(4)   := '104';                                --�ʏ����CSV
  cv_revision_ret_format            CONSTANT  VARCHAR2(4)   := '105';                                --�ԕi����CSV
  cv_return_format                  CONSTANT  VARCHAR2(4)   := '106';                                --�ԕiCSV
  cv_electricity_format             CONSTANT  VARCHAR2(4)   := '107';                                --�ϓ��d�C��CSV
-- ************** Ver1.28 ADD END   *************** --
  cv_c_kanma                        CONSTANT  VARCHAR2(1)   := ',';                                  --�J���}
  cv_line_feed                      CONSTANT  VARCHAR2(1)   := CHR(10);                              --���s�R�[�h
  cn_customer_div_cust              CONSTANT  VARCHAR2(4)   := '10';                                 --�ڋq
  cn_customer_div_user              CONSTANT  VARCHAR2(4)   := '12';                                 --��l
--****************************** 2009/08/21 1.12 M.Sano ADD  START ******************************--
  cv_customer_div_chain             CONSTANT  VARCHAR2(4)   := '18';                                 --�`�F�[���X
  cv_cust_item_def_level            CONSTANT  VARCHAR2(1)   := '1';                                  --�ڋq�}�X�^�F��`���x��
  cv_inactive_flag_no               CONSTANT  VARCHAR2(1)   := 'N';                                  --�ڋq�i�ځF�L��
--****************************** 2009/08/21 1.12 M.Sano ADD  END    ******************************--
  cv_item_status_code_y             CONSTANT  VARCHAR2(2)   := 'Y';                                  --�i�ڃX�e�[�^�X(�ڋq�󒍉\�t���O ('Y')(�Œ�l))
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
  cv_cust_status_active             CONSTANT  VARCHAR2(1)   := 'A';                                  --�ڋq�}�X�^�n�̗L���t���O�F�L��
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
  cv_code_div_from                  CONSTANT  VARCHAR2(2)   := '4';                                  --�q��
  cv_code_div_to                    CONSTANT  VARCHAR2(2)   := '9';                                  --�z����
  cv_yyyymmdd_format                CONSTANT  VARCHAR2(64)  := 'YYYYMMDD';                           --���t�t�H�[�}�b�g
  cv_yyyymmdds_format               CONSTANT  VARCHAR2(64)  := 'YYYY/MM/DD';                         --���t�t�H�[�}�b�g
  cv_api_name_calc_lead_time        CONSTANT  VARCHAR2(64)  := 'xxwsh_common910_pkg.calc_lead_time'; --�֐���
  cv_api_name_makeup_key_info       CONSTANT  VARCHAR2(64)  := 'xxwsh_common_pkg.get_oprtn_day';     --�֐���
  cv_order                          CONSTANT  VARCHAR2(64)  := 'ORDER';                              --�I�[�_�[
  cv_line                           CONSTANT  VARCHAR2(64)  := 'LINE';                               --���C��
  cv_item_z                         CONSTANT  VARCHAR2(64)  := 'ZZZZZZZ';                            --�i�ڃR�[�h
  cv_00                             CONSTANT  VARCHAR2(64)  := '00';
--****************************** 2009/07/14 1.8 T.Miyata MOD  START ******************************--
--  cv_con_status_normal              CONSTANT  VARCHAR2(10)  := 'NORMAL';                             -- �X�e�[�^�X�i����j
  cv_con_status_error               CONSTANT  VARCHAR2(10)  := 'ERROR';                              -- �X�e�[�^�X�i�ُ�j
  cv_con_status_warning             CONSTANT  VARCHAR2(10)  := 'WARNING';                            -- �X�e�[�^�X�i�x���j
--****************************** 2009/07/14 1.8 T.Miyata MOD  END   ******************************--
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cv_cons_n                         CONSTANT  VARCHAR2(1)   := 'N';
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
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
-- ************** Ver1.28 ADD END   *************** --
--
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
---- ***************** 2009/11/18 1.14 N.Maeda ADD START ***************** --
----  cn_c_header                       CONSTANT  NUMBER        := 44;                                   --����
--  cn_c_header                       CONSTANT  NUMBER        := 45;                                   --����
---- ***************** 2009/11/18 1.14 N.Maeda ADD  END  ***************** --
-- ************** Ver1.28 MOD START *************** --
--  cn_c_header                       CONSTANT  NUMBER        := 48;                                   --����
-- ************** Ver1.29 MOD START *************** --
--  cn_c_header                       CONSTANT  NUMBER        := 52;                                   --����
  cn_c_header                       CONSTANT  NUMBER        := 53;                                   --����
-- ************** Ver1.29 MOD END   *************** --
-- ************** Ver1.28 MOD END   *************** --                                 --����
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
  cn_begin_line                     CONSTANT  NUMBER        := 2;                                    --�ŏ��̍s
  cn_line_zero                      CONSTANT  NUMBER        := 0;                                    --0�s
  cn_item_header                    CONSTANT  NUMBER        := 1;                                    --���ږ�
  cn_central_code                   CONSTANT  NUMBER        := 3;                                    --�Z���^�[�R�[�h
  cn_jan_code                       CONSTANT  NUMBER        := 26;                                   --JAN�R�[�h
  cn_total_time                     CONSTANT  NUMBER        := 31;                                   --���ߎ���
  cn_order_date                     CONSTANT  NUMBER        := 32;                                   --������
  cn_delivery_date                  CONSTANT  NUMBER        := 33;                                   --�[�i��
  cn_order_number                   CONSTANT  NUMBER        := 34;                                   --�I�[�_�[No.
  cn_line_number                    CONSTANT  NUMBER        := 35;                                   --�sNo.
  cn_order_roses_quantity           CONSTANT  NUMBER        := 37;                                   --�����o����
  cn_multiple_store_code            CONSTANT  NUMBER        := 42;                                   --�`�F�[���X�R�[�h
  cn_sej_article_code               CONSTANT  NUMBER        := 24;                                   --SEJ���i�R�[�h
  cn_order_cases_quantity           CONSTANT  NUMBER        := 36;                                   --�����P�[�X��
  cn_delivery                       CONSTANT  NUMBER        := 43;                                   --�[�i��
  cn_shipping_date                  CONSTANT  NUMBER        := 44;                                   --�o�ד�
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cn_tokushu_item_code              CONSTANT  NUMBER        := 27;                                   --���ꏤ�i�R�[�h
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** 2011/01/19 1.22 H.Sekine MOD START  ************** --
--  cn_central_code_dlength           CONSTANT  NUMBER        := 5;                                    --�Z���^�[�R�[�h
  cn_central_code_dlength           CONSTANT  NUMBER        := 10;                                   --�Z���^�[�R�[�h
-- ************** 2011/01/19 1.22 H.Sekine MOD END    ************** --
  cn_jan_code_dlength               CONSTANT  NUMBER        := 13;                                   --JAN�R�[�h
  cn_total_time_dlength             CONSTANT  NUMBER        := 2;                                    --���ߎ���
  cn_order_date_dlength             CONSTANT  NUMBER        := 8;                                    --������
  cn_delivery_date_dlength          CONSTANT  NUMBER        := 8;                                    --�[�i��
  cn_order_number_dlength           CONSTANT  NUMBER        := 16;                                   --�I�[�_�[No.
  cn_line_number_dlength            CONSTANT  NUMBER        := 2;                                    --�sNo.
  cn_order_roses_qty_dlength        CONSTANT  NUMBER        := 7;                                    --�����o����
  cn_multiple_store_code_dlength    CONSTANT  NUMBER        := 4;                                    --�`�F�[���X�R�[�h
  cn_sej_article_code_dlength       CONSTANT  NUMBER        := 13;                                   --SEJ���i�R�[�h
  cn_order_cases_qty_dlength        CONSTANT  NUMBER        := 7;                                    --�����P�[�X��
  cn_delivery_dlength               CONSTANT  NUMBER        := 12;                                   --�[�i��
  cn_ship_date_dlength              CONSTANT  NUMBER        := 8;                                    --�o�ד�
  cn_priod                          CONSTANT  NUMBER        := 0;                                    --�����_
--****************************** 2010/12/03 1.21 H.Sekine ADD START  ******************************
  cn_order_bara_qty_dlength         CONSTANT  NUMBER        := 9;                                    --�����o����(���{�A�L����`��)
  cn_order_bara_qty_point           CONSTANT  NUMBER        := 2;                                    --�����o���������_�ȉ�����(���{�A�L����`��)
  cn_tokushu_item_code_dlength      CONSTANT  NUMBER        := 16;                                   --���ꏤ�i�R�[�h����
--****************************** 2010/12/03 1.21 H.Sekine ADD END    ******************************
--****************************** 2009/07/10 1.7 T.Tominaga DEL START ******************************
--  cn_interval                       CONSTANT  NUMBER        := 30;                                   --Interval
--  cn_max_wait                       CONSTANT  NUMBER        := 0;                                    --Max_wait
--****************************** 2009/07/10 1.7 T.Tominaga DEL END   ******************************
-- ***************** 2009/11/18 1.14 N.Maeda ADD START ***************** --
  cn_packing_instructions           CONSTANT NUMBER         := 12;                                   -- �o�׈˗�No.(����)
  cn_pack_instructions              CONSTANT NUMBER         := 45;                                   -- �o�׈˗�No.(���ڏ���)
-- ***************** 2009/11/18 1.14 N.Maeda ADD  END  ***************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cn_cust_po_number_digit           CONSTANT NUMBER         := 12;                                   -- �ڋq�����ԍ�(����)
  cn_cust_po_number_stand           CONSTANT NUMBER         := 46;                                   -- �ڋq�����ԍ�(���ڏ���)
  cn_unit_price_digit               CONSTANT NUMBER         := 12;                                   -- �P��(����)
  cn_unit_price_stand               CONSTANT NUMBER         := 47;                                   -- �P��(���ڏ���)
  cn_unit_price_point               CONSTANT NUMBER         := 2;                                    -- �P��(�����_�ȉ�����)
  cn_category_class_digit           CONSTANT NUMBER         := 4;                                    -- ���ދ敪(����)
  cn_category_class_stand           CONSTANT NUMBER         := 48;                                   -- ���ދ敪(���ڏ���)
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
  cn_order_bara_qty_elec            CONSTANT  NUMBER        := 1;                                    --�ϓ��d�C��̔����o����(�Œ�:1)
  cn_data_type_digit                CONSTANT  NUMBER        := 3;                                    --�f�[�^���(����)
  cn_data_type_stand                CONSTANT  NUMBER        := 2;                                    --�f�[�^���(���ڏ���)
  cn_invoice_class_digit            CONSTANT  NUMBER        := 2;                                    --�`�[�敪(����)
  cn_invoice_class_stand            CONSTANT  NUMBER        := 49;                                   --�`�[�敪(���ڏ���)
  cn_subinventory_digit             CONSTANT  NUMBER        := 10;                                   --�ۊǏꏊ(����)
  cn_subinventory_stand             CONSTANT  NUMBER        := 50;                                   --�ۊǏꏊ(���ڏ���)
  cn_line_type_digit                CONSTANT  NUMBER        := 30;                                   --�󒍃^�C�v�i���ׁj(����)
  cn_line_type_stand                CONSTANT  NUMBER        := 51;                                   --�󒍃^�C�v�i���ׁj(���ڏ���)
  cn_sales_class_digit              CONSTANT  NUMBER        := 1;                                    --����敪(����)
  cn_sales_class_stand              CONSTANT  NUMBER        := 52;                                   --����敪(���ڏ���)
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
  cn_ship_instructions_digit        CONSTANT  NUMBER        := 40;                                   --�o�׎w��(����)
  cn_ship_instructions_stand        CONSTANT  NUMBER        := 53;                                   --�o�׎w��(���ڏ���)
-- ************** Ver1.29 ADD END   *************** --
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  cv_trunc_mm                       CONSTANT VARCHAR2(2)    := 'MM';                                 --���t�؎̗p
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
-- ************** 2018/01/23 V1.31 Added START    *************** --
  cv_bis_center                     CONSTANT VARCHAR2(1)    :=  'Y';                                --  �����Z���^�[�E��
  cv_book_order                     CONSTANT VARCHAR2(10)   :=  'BOOK_ORDER';                       --  �L����
  cv_management_status_1            CONSTANT VARCHAR2(1)    :=  '1';                                --  �X�e�[�^�X�F1.�m���
  cv_finish_cooperate               CONSTANT VARCHAR2(1)    :=  '1';                                --  �}�X�^�A�g�t���O�F1.�A�g��
  cv_electricity_type_change        CONSTANT VARCHAR2(1)    :=  '2';                                --  �d�C��敪�F2.�ϓ�
  cv_sp_electric_pay_type_1         CONSTANT VARCHAR2(1)    :=  '1';                                --  �x�������i�d�C��j�F1.�_���
  cv_business_low_type_24           CONSTANT VARCHAR2(2)    :=  '24';                               --  �Ƒԏ����ށF24.�t��VD(����)
  cv_business_low_type_25           CONSTANT VARCHAR2(2)    :=  '25';                               --  �Ƒԏ����ށF25.�t��VD
-- ************** 2018/01/23 V1.31 Added END      *************** --
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
-- ************** 2018/01/23 V1.31 Added START    *************** --
  TYPE g_tab_oif_act_rec            IS TABLE OF oe_actions_iface_all%ROWTYPE INDEX BY PLS_INTEGER;   --�󒍏���OIF
-- ************** 2018/01/23 V1.31 Added END      *************** --
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                  INDEX BY PLS_INTEGER;   --�����_
  gr_order_oif_data                 g_tab_order_oif_rec;                                             --�󒍃w�b�_OIF
  gr_order_line_oif_data            g_tab_t_order_line_oif_rec;                                      --�󒍖���OIF
-- ************** 2018/01/23 V1.31 Added START    *************** --
  gr_oif_act_data                   g_tab_oif_act_rec;                                               --�󒍏���OIF
-- ************** 2018/01/23 V1.31 Added END      *************** --
  gr_g_login_base_info              g_tab_login_base_info_rec;                                       --�����_
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_prod_ou_nm                     VARCHAR2(128);                                                   --���Y�c�ƒP�ʖ���
  gv_inv_org_code                   VARCHAR2(128);                                                   --�c�Ɨp�݌ɑg�D�R�[�h
  gv_get_format                     VARCHAR2(128);                                                   --�󒍃\�[�X�̎擾
  gv_case_uom                       VARCHAR2(128);                                                   --
  gv_lookup_type                    VARCHAR2(128);                                                   --
  gv_meaning                        VARCHAR2(128);                                                   --
  gv_description                    VARCHAR2(128);                                                   --
  gv_f_lookup_type                  VARCHAR2(128);                                                   --�󒍃^�C�v
  gv_f_description                  VARCHAR2(128);                                                   --�󒍃\�[�X��
  gv_csv_file_name                  VARCHAR2(128);                                                   --CSV�t�@�C����
-- ************** Ver1.28 MOD START *************** --
--  gv_seq_no                         VARCHAR2(12);                                                    --�V�[�P���X
  gv_seq_no                         VARCHAR2(29);                                                    --�V�[�P���X
-- ************** Ver1.28 MOD END   *************** --
  gv_temp_oder_no                   VARCHAR2(128);                                                   --�ꎞ�ۊǗp�I�[�_�[No
  gv_temp_line_no                   VARCHAR2(128);                                                   --�ꎞ�ۊǏꏊ�s�ԍ�
  gv_temp_line                      VARCHAR2(128);                                                   --�ꎞ�ۊǏꏊ�sNo
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  gv_get_highest_emp_flg            VARCHAR2(1);                                                     --�ŏ�ʎҏ]�ƈ��ԍ��擾�t���O
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- ************** Ver1.28 ADD START *************** --
  gv_order                          VARCHAR2(128);
-- ************** Ver1.28 ADD END   *************** --
  gn_org_id                         NUMBER;                                                          --�c�ƒP��
  gn_prod_ou_id                     NUMBER;                                                          --���Y�c�ƒP��ID
  gn_get_stock_id_ret               NUMBER;                                                          --�c�Ɨp�݌ɑg�DID(�߂�lNUMBER)
  gn_lookup_code                    NUMBER;                                                          --�Q�ƃR�[�h
  gn_get_counter_data               NUMBER;                                                          --�f�[�^��
  gn_hed_cnt                        NUMBER;                                                          --�w�b�_�J�E���^�[
  gn_line_cnt                       NUMBER;                                                          --���׃J�E���^�[
  gn_hed_Suc_cnt                    NUMBER;                                                          --�����w�b�_�J�E���^�[
  gn_line_Suc_cnt                   NUMBER;                                                          --�������׃J�E���^�[
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  gn_interval                       NUMBER;                                                          --�ҋ@�Ԋu
  gn_max_wait                       NUMBER;                                                          --�ő�ҋ@����
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  gn_user_id                        NUMBER;                                                          --���O�C�����[�U�[ID
  gn_resp_id                        NUMBER;                                                          --���O�C���E��ID
  gn_resp_appl_id                   NUMBER;                                                          --���O�C���E�ӃA�v���P�[�V����ID
  gn_prod_resp_id                   NUMBER;                                                          --�ؑ֐�E��ID
  gn_prod_resp_appl_id              NUMBER;                                                          --�ؑ֐�E�ӃA�v���P�[�V����ID
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
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
  gt_order_no                       OE_HEADERS_IFACE_ALL.ATTRIBUTE19%TYPE;                           --�I�[�_�[No
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* -
  gt_case_num                       ic_item_mst_b.attribute11%TYPE;                                  --�P�[�X����
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  gd_process_date                   DATE;                                                            --�Ɩ����t
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
-- ************** Ver1.28 ADD START *************** --
  gt_e_fee_item_cd                  ic_item_mst_b.item_no%TYPE;                                      --�ϓ��d�C���i�ڃR�[�h
  gt_line_context_unset_flg         fnd_lookup_values.attribute2%TYPE;                               --���׃R���e�L�X�g���ݒ�t���O
  gt_sales_class_must_flg           fnd_lookup_values.attribute3%TYPE;                               --����敪�ݒ�t���O
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
  gt_orig_sys_document_ref   oe_order_headers.orig_sys_document_ref%TYPE; -- �󒍃\�[�X�Q��(�V�[�P���X�ݒ�)
-- ************** Ver1.29 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
  gv_order_up_bis_center            VARCHAR2(1);
  gn_line_act_cnt                   NUMBER;
-- ************** 2018/01/23 V1.31 Added END      *************** --
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
      SELECT flv.lookup_type,
             flv.lookup_code,
             flv.meaning,
             flv.description
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
         AND flv.language               = USERENV( 'LANG' )
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
      SELECT xmf.file_id,                     --�t�@�C��ID
             xmf.last_updated_by,             --�ŏI�X�V��
             xmf.last_update_date             --�ŏI�X�V��
        INTO gt_file_id,                      --�t�@�C��ID
             gt_last_updated_by1,             --�ŏI�X�V��
             gt_last_update_date              --�ŏI�X�V��
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
    in_file_id    IN  NUMBER,    -- 7.<FILE_ID>
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
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
    lt_resp_prod                fnd_profile_option_values.profile_option_value%TYPE;
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
--
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
    lv_order                    VARCHAR2(16);    --��
    lv_shipment                 VARCHAR2(16);    --�o��
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_data_cur
    IS
      SELECT lbi.base_code base_code
-- ************** Ver1.30 MOD START *************** --
--        FROM xxcos_login_base_info_v lbi
        FROM xxcos_all_or_login_base_info_v lbi
-- ************** Ver1.30 MOD END   *************** --
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
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_inv_org_id
                     );
      RAISE global_get_stock_org_id_expt;
    END IF;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    ------------------------------------
    -- 4.�Ɩ����t�擾
    ------------------------------------
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF  ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
    ------------------------------------
    -- 5.�󒍃\�[�X���̎擾
    ------------------------------------
    BEGIN
      --
      SELECT flv.description  --�\�[�X��
        INTO gv_f_description
        FROM fnd_lookup_values flv
       WHERE flv.language    = USERENV( 'LANG' )
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
      SELECT oos.order_source_id --�󒍃\�[�XID
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
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      IF ( iv_get_format = cv_mihon_format ) THEN
        lv_order := cv_mihon_order;
      ELSIF ( iv_get_format = cv_koukoku_format ) THEN
        lv_order := cv_koukoku_order;
-- ************** Ver1.28 ADD START *************** --
      ELSIF ( iv_get_format = cv_revision_nrm_format ) THEN  --�ʏ����CSV
        lv_order := cv_revision_nrm_order;
        gv_order := cv_revision_nrm_order;
      ELSIF ( iv_get_format = cv_revision_ret_format ) THEN  --�ԕi����CSV
        lv_order := cv_revision_ret_order;
        gv_order := cv_revision_ret_order;
      ELSIF ( iv_get_format = cv_return_format ) THEN        --�ԕiCSV
        lv_order := cv_return_order;
-- ************** Ver1.28 ADD END   *************** --
      ELSE
        lv_order := cv_normal_order;
      END IF;
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    --
      SELECT ott.name                      --�󒍃^�C�v��
        INTO gt_order_type_name            --�󒍃^�C�v��
        FROM oe_transaction_types_tl  ott,
             oe_transaction_types_all otl,
             fnd_lookup_values flv
       WHERE flv.lookup_type           = ct_look_up_type
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--         AND flv.lookup_code           = cv_normal_order
         AND flv.lookup_code           = lv_order
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = USERENV( 'LANG' )
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
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      IF ( iv_get_format = cv_mihon_format ) THEN
        lv_shipment := cv_mihon_shipment;
      ELSIF ( iv_get_format = cv_koukoku_format ) THEN
        lv_shipment := cv_koukoku_shipment;
-- ************** Ver1.28 ADD START *************** --
      ELSIF ( iv_get_format = cv_return_format ) THEN  -- �ԕiCSV
        lv_shipment := cv_return_shipment;
-- ************** Ver1.28 ADD END   *************** --
      ELSE
        lv_shipment := cv_normal_shipment;
      END IF;
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    --
      SELECT ott.name                --�󒍃^�C�v��
-- ************** Ver1.28 ADD START *************** --
            ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg
            ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg
-- ************** Ver1.28 ADD END   *************** --
        INTO gt_order_line_type_name --�󒍃^�C�v��
-- ************** Ver1.28 ADD START *************** --
            ,gt_line_context_unset_flg  --���׃R���e�L�X�g���ݒ�t���O
            ,gt_sales_class_must_flg    --����敪�ݒ�t���O
-- ************** Ver1.28 ADD END   *************** --
        FROM oe_transaction_types_tl   ott,
             oe_transaction_types_all  otl, 
             fnd_lookup_values         flv
       WHERE flv.lookup_type           = ct_look_up_type
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--         AND flv.lookup_code           = cv_normal_shipment
         AND flv.lookup_code           = lv_shipment
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = USERENV( 'LANG' )
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
    -- 9.�P�[�X�P��(����CSV)
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
    ------------------------------------
    -- 10.���Y�c�ƒP�ʖ���
    ------------------------------------
    -- �c�ƒP�ʂ̎擾
    gv_prod_ou_nm := FND_PROFILE.VALUE( ct_prod_ou_nm );
--
    -- �c�ƒP�ʂ̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_prod_ou_nm IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_ou_nm
                     );
      RAISE global_get_profile_expt;
    END IF;
    ------------------------------------
    -- 11.���Y�c�ƒP��ID
    ------------------------------------
    BEGIN
      SELECT hou.organization_id organization_id
        INTO gn_prod_ou_id
        FROM hr_operating_units hou
       WHERE hou.name  = gv_prod_ou_nm
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_ou_nm
                       );
        RAISE global_get_profile_expt;
    END;
    ------------------------------------
    -- 12.�����_�擾
    ------------------------------------
    OPEN  get_data_cur;
    -- �o���N�t�F�b�`
    FETCH get_data_cur BULK COLLECT INTO gr_g_login_base_info;
    -- �J�[�\��CLOSE
    CLOSE get_data_cur;
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
    ------------------------------------
    -- 13.�ҋ@�Ԋu�̎擾
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
    -- 14.�ő�ҋ@���Ԃ̎擾
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
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
--
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
    ------------------------------------
    -- 15.���O�C�����[�U���擾
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
    ------------------------------------
    -- 16.�v���t�@�C���uXXCOS:���Y�ւ̐ؑ֗p�E�Ӗ��́v�擾
    ------------------------------------
    lt_resp_prod := FND_PROFILE.VALUE(
      name => cv_resp_prod);
--
--
    IF ( lt_resp_prod IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => ct_xxcos_appl_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- �v���t�@�C��(�ؑ֗p�E��)�擾�G���[
                   );
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------
    -- 17.�ؑ֐惍�O�C�����擾
    ------------------------------------
    BEGIN
      SELECT   frv.responsibility_id    -- �ؑ֐�E��ID
              ,frv.application_id       -- �ؑ֐�E�ӃA�v���P�[�V����ID
      INTO     gn_prod_resp_id
              ,gn_prod_resp_appl_id
      FROM    fnd_responsibility_vl  frv
      WHERE   responsibility_name = lt_resp_prod
      AND     ROWNUM              = 1;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- �ؑ֐惍�O�C�����擾�G���[
                     );
        RAISE global_api_expt;
    END;
--
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- ************** Ver1.28 ADD START *************** --
    ------------------------------------
    -- 18.XXCOS:�ϓ��d�C���i�ڃR�[�h�̎擾
    ------------------------------------
    -- �u�ϓ��d�C��CSV�v�̏ꍇ�̂݃v���t�@�C���l���擾���܂��B
    IF ( iv_get_format = cv_electricity_format ) THEN
      --�ϓ��d�C���i�ڃR�[�h�̎擾
      gt_e_fee_item_cd := FND_PROFILE.VALUE( cv_e_fee_item_cd );
--
      -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      IF ( gt_e_fee_item_cd IS NULL ) THEN
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_e_fee_item_cd
                       );
        RAISE global_get_profile_expt;
      END IF;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
    ------------------------------------
    -- 19.�v���t�@�C���uXXCOS:�󒍃A�b�v���[�h�����Z���^�[�v�擾
    ------------------------------------
    gv_order_up_bis_center  :=  fnd_profile.value( cv_order_up_bis_center );
    --
    IF ( gv_order_up_bis_center IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      lv_key_info :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  ct_xxcos_appl_short_name    --  XXCOS
                        , iv_name         =>  ct_msg_get_ordup_biz_ctr    --  XXCOS:�󒍃A�b�v���[�h�����Z���^�[
                      );
      RAISE global_get_profile_expt;
    END IF;
-- ************** 2018/01/23 V1.31 Added END      *************** --
--
  EXCEPTION
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  ct_xxcos_appl_short_name,
                       iv_name          =>  ct_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
     --***** �v���t�@�C���擾��O�n���h��(MO:�c�ƒP�ʂ̎擾)
     --***** �v���t�@�C���擾��O�n���h��(XXCOI:�݌ɑg�D�R�[�h�̎擾)
     --***** �v���t�@�C���擾��O�n���h��(�󒍃\�[�X�̎擾)
     --***** �v���t�@�C���擾��O�n���h��(XXCOS:�󒍃A�b�v���[�h�����Z���^�[)
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
                     iv_name         => ct_msg_get_api_call_err,
                     iv_token_name1  => cv_tkn_api_name,
                     iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <���ڃ`�F�b�N>(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER,   -- 1.<�f�[�^��>
    iv_get_format           IN  VARCHAR2, -- 2.<�t�H�[�}�b�g�p�^�[��>
    ov_central_code         OUT VARCHAR2, -- 1.<�Z���^�[�R�[�h>
    ov_jan_code             OUT VARCHAR2, -- 2.<JAN�R�[�h>
    ov_total_time           OUT VARCHAR2, -- 3.<���ߎ���>
    od_order_date           OUT DATE,     -- 4.<������>
    od_delivery_date        OUT DATE,     -- 5.<�[�i��>
    ov_order_number         OUT VARCHAR2, -- 6.<�I�[�_�[No.>
    ov_line_number          OUT VARCHAR2, -- 7.<�sNo.>
    on_order_roses_quantity OUT NUMBER,   -- 8.<�����o����>
    ov_multiple_store_code  OUT VARCHAR2, -- 9.<�`�F�[���X�R�[�h>
    ov_sej_article_code     OUT VARCHAR2, -- 10.<SEJ���i�R�[�h>
    on_order_cases_quantity OUT NUMBER,   -- 11.<�����P�[�X��>
    ov_delivery             OUT VARCHAR2, -- 12.<�[�i��>
    od_shipping_date        OUT DATE,     -- 13.<�o�ד�>
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    ov_packing_instructions  OUT VARCHAR2, --14.�o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    ov_cust_po_number       OUT VARCHAR2, --15.�ڋq����No.
    on_unit_price           OUT NUMBER,   --16.�P��
    on_category_class       OUT VARCHAR2,   --17.���ދ敪
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    ov_tokushu_item_code    OUT VARCHAR2,   --18.���ꏤ�i�R�[�h
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    ov_invoice_class        OUT VARCHAR2,  -- �`�[�敪
    ov_subinventory         OUT VARCHAR2,  -- �ۊǏꏊ
    ov_line_type            OUT VARCHAR2,  -- �󒍃^�C�v�i���ׁj�������p
    ov_sales_class          OUT VARCHAR2,  -- ����敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
    ov_ship_instructions    OUT VARCHAR2,  -- �o�׎w��
-- ************** Ver1.29 ADD END   *************** --
    ov_errbuf               OUT VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    cn_tanka_zero           CONSTANT NUMBER := 0;
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    cn_order_cases_qnt_zero CONSTANT NUMBER := 0;
-- ************** Ver1.28 ADD END   *************** --
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    ov_cust_po_number := NULL;    --�ڋq����No.
    on_unit_price     := NULL;    --�P��
    on_category_class := NULL;    --���ދ敪
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    ------------------------------------
    -- 0.�t�H�[�}�b�g�p�^�[���̔���
    ------------------------------------
    IF ( iv_get_format = cv_tonya_format ) THEN
      ------------------------------------
      -- 1.�≮CSV (���ڃ`�F�b�N)
      ------------------------------------
      --�Z���^�[�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_central_code),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_central_code),          -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_central_code_dlength,                              -- 3.���ڂ̒���                 -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_central_code)              --���ږ�
                      ) || cv_line_feed;
         --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_central_code := gr_order_work_data(in_cnt)(cn_central_code) ; -- 1.<�Z���^�[�R�[�h>
      END IF;
--
      --JAN�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_jan_code),       -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_jan_code),               -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_jan_code_dlength,                                   -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                  -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                          -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                         -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_jan_code)                  --���ږ�
                      ) || cv_line_feed;
         --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_jan_code := gr_order_work_data(in_cnt)(cn_jan_code); -- 2.<JAN�R�[�h>
      END IF;
     --
--
      --�����o����
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
        on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<�����o����>
      END IF;
--
      --�`�F�[���X�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_multiple_store_code), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_multiple_store_code),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_multiple_store_code_dlength,                             -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                       -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                               -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_multiple_store_code)       --���ږ�
                      ) || cv_line_feed;
         --
     --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_multiple_store_code := gr_order_work_data(in_cnt)(cn_multiple_store_code) ;-- 9.<�`�F�[���X�R�[�h>
      END IF;
--
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      --���ꏤ�i�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_tokushu_item_code),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_tokushu_item_code),            -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_tokushu_item_code_dlength,                                -- 3.���ڂ̒���                 -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_tokushu_item_code)         --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_tokushu_item_code := gr_order_work_data(in_cnt)(cn_tokushu_item_code);
      END IF;
      --
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
      --�I�[�_�[No.
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
        ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<�I�[�_�[No.>
      END IF;
--
      --�ڋq�����ԍ�
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
--    ------------------------------------
--    -- 2.����CSV (���ڃ`�F�b�N)
--    ------------------------------------
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
    ------------------------------------
    -- 2.����CSV�A���{CSV�A�L����`��CSV�A�ʏ����CSV�A�ԕi����CSV�A�ԕiCSV�A�ϓ��d�C��CSV (���ڃ`�F�b�N)
    ------------------------------------
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
      --SEJ���i�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_sej_article_code), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_sej_article_code),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_sej_article_code_dlength,                             -- 3.���ڂ̒���                 -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_sej_article_code)          --���ږ�
                      ) || cv_line_feed;
         --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_sej_article_code := gr_order_work_data(in_cnt)(cn_sej_article_code);  -- 10.<SEJ���i�R�[�h>
      END IF;
--
      --�����P�[�X��
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_cases_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_cases_quantity),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_order_cases_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
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
-- ************** Ver1.28 MOD START *************** --
--        on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 11.<�����P�[�X��>
        IF ( iv_get_format = cv_electricity_format ) THEN
          --�u�ϓ��d�C��CSV�v�̏ꍇ�A�����P�[�X����0���Z�b�g����B
          on_order_cases_quantity := cn_order_cases_qnt_zero;
        ELSE
          --�u�ϓ��d�C��CSV�v�ȊO�̏ꍇ�A�擾���������P�[�X�����Z�b�g����B
          on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 11.<�����P�[�X��>
        END IF;
-- ************** Ver1.28 MOD END   *************** --
      END IF;
--
      --�[�i��
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery),          -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_delivery_dlength,                              -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                     -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
        ov_delivery             := gr_order_work_data(in_cnt)(cn_delivery);-- 12.<�[�i��>
      END IF;
--
-- ********************* 2010/01/12 1.18 M.Uehara DEL START ********************* --
-- �o�ד��̃`�F�b�N��≮CSV�^����CSV���ʂ̍��ڃ`�F�b�N���Ɉړ�
--      --�o�ד�
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_shipping_date), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_shipping_date),         -- 2.���ڂ̒l                   -- �C��
--        in_item_len     => cn_ship_date_dlength,                                 -- 3.���ڂ̒���                 -- �K�{
--        in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
---- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
---- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --���[�j���O
--      IF ( lv_retcode = cv_status_warn ) THEN
--        --���[�j���O���b�Z�[�W�쐬
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shipping_date)             --���ږ�
--                      ) || cv_line_feed;
--        --
--      --���ʊ֐��G���[
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --����I��
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        od_shipping_date        :=  TO_DATE(gr_order_work_data(in_cnt)(cn_shipping_date),cv_yyyymmdd_format);-- 13.<�o�ד�>
--      END IF;
-- ********************* 2010/01/12 1.18 M.Uehara DEL END ********************* --
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
      --�o�׈˗�No.
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
        ov_packing_instructions := gr_order_work_data(in_cnt)(cn_pack_instructions);
      END IF;
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
-- *********** 2010/12/03 1.21 H.Sekine DEL START***********--
--      --�����o����
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.���ڂ̒l                   -- �C��
--        in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
--        in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --
--      --���[�j���O
--      IF ( lv_retcode = cv_status_warn ) THEN
--        --���[�j���O���b�Z�[�W�쐬
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_roses_quantity)      --���ږ�
--                      ) || cv_line_feed;
--         --
--      --���ʊ֐��G���[
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --����I��
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<�����o����>
--      END IF;
----
--      IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => cv_order_qty_err,                                                --�󒍐��ʃG���[
--                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number) )                      --���ږ�
--                       || cv_line_feed ;
--      END IF;
--
--      --�ڋq�����ԍ�
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
--        in_item_len     => cn_cust_po_number_digit,                              -- 3.���ڂ̒���                 -- �K�{
--        in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --���[�j���O
--      IF ( lv_retcode = cv_status_warn ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)         --���ږ�
--                      ) || cv_line_feed;
--        --
--      --���ʊ֐��G���[
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --����I��
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
--      END IF;
--
-- ************** 2010/12/03 1.21 H.Sekine DEL END    ************** --
--
-- ************** Ver1.28 DEL START *************** --
--      --�P��
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.���ڂ̒l                   -- �C��
--        in_item_len     => cn_unit_price_digit,                                     -- 3.���ڂ̒���                 -- �K�{
--        in_item_decimal => cn_unit_price_point,                                     -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--        ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--        ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--        ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --���[�j���O
--      IF ( lv_retcode = cv_status_warn ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_unit_price_stand)         --���ږ�
--                      ) || cv_line_feed;
--        --
--      --���ʊ֐��G���[
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --����I��
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
---- ************** 2010/12/03 1.21 H.Sekine MOD STRAT  ************** --
----        on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--        IF ( iv_get_format = cv_kokusai_format ) THEN
--          --�u����CSV�v�̏ꍇ�A�擾�����P�����Z�b�g����B
--          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--        ELSE
--          --�u����CSV�v�ȊO�̏ꍇ�A�P����'0'���Z�b�g����B
--          on_unit_price := cn_tanka_zero;
--        END IF;
---- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
--      END IF;
-- ************** Ver1.28 DEL END   *************** --
--
      --���ދ敪
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_category_class_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_category_class_stand),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_category_class_digit,                                     -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => cn_priod,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_category_class_stand)         --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        on_category_class := gr_order_work_data(in_cnt)(cn_category_class_stand);
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
--
-- ************** Ver1.28 ADD START *************** --
      IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      ------------------------------------
      -- ����CSV�A���{CSV�A�L����`��CSV(���ڃ`�F�b�N)
      ------------------------------------
        --�I�[�_�[No.
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
          ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<�I�[�_�[No.>
        END IF;
--
        --�ڋq�����ԍ�
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
                        ) || cv_line_feed;
          --
        --���ʊ֐��G���[
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --����I��
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
--
        --�P��
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
          IF ( iv_get_format = cv_kokusai_format ) THEN
            --�u����CSV�v�̏ꍇ�A�擾�����P�����Z�b�g����B
            on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
          ELSE
            --�u����CSV�v�ȊO�̏ꍇ�A�P����'0'���Z�b�g����B
            on_unit_price := cn_tanka_zero;
          END IF;
        END IF;
      --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
-- ************** Ver1.28 MOD START *************** --
--      IF ( iv_get_format = cv_kokusai_format ) THEN
      IF ( iv_get_format IN ( cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format ) ) THEN
-- ************** Ver1.28 MOD END   *************** --
      ------------------------------------
      -- 3.����CSV�A�ʏ����CSV�A�ԕi����CSV�A�ԕiCSV (���ڃ`�F�b�N)
      ------------------------------------
        --�����o����
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
          on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<�����o����>
        END IF;
--
        IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
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
        END IF;
      END IF;
      --
      --���ꏤ�i�R�[�h
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_tokushu_item_code),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_tokushu_item_code),            -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_tokushu_item_code_dlength,                                -- 3.���ڂ̒���                 -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_tokushu_item_code)         --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_tokushu_item_code := gr_order_work_data(in_cnt)(cn_tokushu_item_code);
      END IF;
      --
      IF ( iv_get_format IN ( cv_mihon_format , cv_koukoku_format ) ) THEN
        ------------------------------------
        -- 4.���{CSV�A�L����`��CSV (���ڃ`�F�b�N)
        ------------------------------------
        --�����o����
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_order_bara_qty_dlength,                                   -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => cn_order_bara_qty_point,                                     -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
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
          on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<�����o����>
      END IF;
    --
    END IF;
--
-- ************** Ver1.28 ADD START *************** --
      IF ( iv_get_format = cv_electricity_format ) THEN
        ------------------------------------
        -- �ϓ��d�C��CSV (���ڃ`�F�b�N)
        ------------------------------------
        --�����o����
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => cn_priod,                                                    -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
--
          --�����o�����`�F�b�N(�Œ�l:1)
          IF ( gr_order_work_data(in_cnt)(cn_order_roses_quantity) = cn_order_bara_qty_elec ) THEN
            on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<�����o����>
          ELSE
            --���[�j���O���b�Z�[�W�쐬
            lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                            iv_application   => ct_xxcos_appl_short_name,
                            iv_name          => ct_msg_chk_bara_qnt_err,
                            iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                            iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                            iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                            iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                            iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                            iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                            iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                            iv_token_value4  => gr_order_work_data(in_cnt)(cn_order_roses_quantity)              --�ݒ�l
                          ) || cv_line_feed;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�����ԍ�
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
                        ) || cv_line_feed;
          --
        --���ʊ֐��G���[
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --����I��
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
      --
-- ************** Ver1.29 ADD START *************** --
        --�P��
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_unit_price_digit,                                     -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => cn_unit_price_point,                                     -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                            -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
        END IF;
-- ************** Ver1.29 ADD END   *************** --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format ) ) THEN
        ------------------------------------
        -- �ʏ����CSV�A�ԕi����CSV�A�ԕiCSV (���ڃ`�F�b�N)
        ------------------------------------
        --�ڋq�����ԍ�
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
-- ************** Ver1.29 MOD START *************** --
--          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
-- ************** Ver1.29 MOD END   *************** --
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
                        ) || cv_line_feed;
          --
        --���ʊ֐��G���[
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --����I��
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
      --
-- ************** Ver1.29 ADD START *************** --
        --�I�[�_�[No.
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
          ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- �I�[�_�[No
        END IF;
--
        --�P��
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
          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
        END IF;
-- ************** Ver1.29 ADD END   *************** --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
        ------------------------------------
        -- �ʏ����CSV�A�ԕi����CSV�A�ԕiCSV�A�ϓ��d�C��CSV (���ڃ`�F�b�N)
        ------------------------------------
-- ************** Ver1.29 DEL START *************** --
--        --�I�[�_�[No.
--        xxccp_common_pkg2.upload_item_check(
--          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
--          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.���ڂ̒l                   -- �C��
--          in_item_len     => cn_order_number_dlength,                              -- 3.���ڂ̒���                 -- �K�{
--          in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--          iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--          iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--          ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        );
--        --
--        --���[�j���O
--        IF ( lv_retcode = cv_status_warn ) THEN
--          --���[�j���O���b�Z�[�W�쐬
--          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                          iv_application   => ct_xxcos_appl_short_name,
--                          iv_name          => ct_msg_get_format_err,
--                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                          iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_number)              --���ږ�
--                        ) || cv_line_feed;
--          --
--        --���ʊ֐��G���[
--        ELSIF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_api_expt;
--        --����I��
--        ELSIF ( lv_retcode = cv_status_normal ) THEN
--          ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- �I�[�_�[No
--        END IF;
----
--        --�P��
--        xxccp_common_pkg2.upload_item_check(
--          iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--          iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.���ڂ̒l                   -- �C��
--          in_item_len     => cn_unit_price_digit,                                     -- 3.���ڂ̒���                 -- �K�{
--          in_item_decimal => cn_unit_price_point,                                     -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                            -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--          iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                           -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--          ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        );
--        --���[�j���O
--        IF ( lv_retcode = cv_status_warn ) THEN
--          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                          iv_application   => ct_xxcos_appl_short_name,
--                          iv_name          => ct_msg_get_format_err,
--                          iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                          iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                          iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                          iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                          iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_unit_price_stand)          --���ږ�
--                        ) || cv_line_feed;
--          --
--        --���ʊ֐��G���[
--        ELSIF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_api_expt;
--        --����I��
--        ELSIF ( lv_retcode = cv_status_normal ) THEN
--          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--        END IF;
----
-- ************** Ver1.29 DEL END   *************** --
        --�`�[�敪
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
          ov_invoice_class := gr_order_work_data(in_cnt)(cn_invoice_class_stand); -- <�`�[�敪>
        END IF;
--
        --�ۊǏꏊ
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
          ov_subinventory  := gr_order_work_data(in_cnt)(cn_subinventory_stand); -- <�ۊǏꏊ>
        END IF;
      --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format ) ) THEN
        ------------------------------------
        -- �ʏ����CSV�A�ԕi����CSV (���ڃ`�F�b�N)
        ------------------------------------
        --�󒍃^�C�v�i���ׁj
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_type_stand),      -- 1.���ږ���(���{�ꖼ)         -- �K�{
          iv_item_value   => gr_order_work_data(in_cnt)(cn_line_type_stand),              -- 2.���ڂ̒l                   -- �C��
          in_item_len     => cn_line_type_digit,                                          -- 3.���ڂ̒���                 -- �K�{
          in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_line_type_stand)           --���ږ�
                        ) || cv_line_feed;
          --
        --���ʊ֐��G���[
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --����I��
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_line_type    := gr_order_work_data(in_cnt)(cn_line_type_stand); -- <�󒍃^�C�v>
        END IF;
      --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    END IF;
-- ************** 2011/02/01 1.24 H.Sekine DEL STRAT  ************** --
---- ************** 2010/12/03 1.21 H.Sekine ADD STRAT  ************** --
--    IF ( iv_get_format = cv_kokusai_format ) THEN
--      --�u����CSV�v�̏ꍇ�A�擾�����P�����Z�b�g����B
--      on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--    ELSE
--      --�u����CSV�v�ȊO�̏ꍇ�A�P����'0'���Z�b�g����B
--      on_unit_price := cn_tanka_zero;
--    END IF;
---- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** 2011/02/01 1.24 H.Sekine DEL END    ************** --
--
-- ************** Ver1.28 ADD START *************** --
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
      ------------------------------------
      -- �≮CSV�A����CSV�A�ʏ����CSV�A�ԕi����CSV�A�ԕiCSV�A�ϓ��d�C��CSV (���ڃ`�F�b�N)
      ------------------------------------
      --����敪
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
        ov_sales_class := gr_order_work_data(in_cnt)(cn_sales_class_stand); -- <����敪>
      END IF;
    END IF;
-- ************** Ver1.28 ADD END *************** --
--
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--    ------------------------------------
--    -- 3.�≮CSV�^����CSV���ʂ̍��ڃ`�F�b�N��
--    ------------------------------------
--
    ------------------------------------
    -- 5.���ʂ̍��ڃ`�F�b�N��
    ------------------------------------
--
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
    --
-- ************** Ver1.28 ADD START *************** --
    --�f�[�^���
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_data_type_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_data_type_stand),         -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_data_type_digit,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                   -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
-- ************** Ver1.29 MOD START *************** --
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                           -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                           -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
-- ************** Ver1.29 MOD END   *************** --
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                          -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
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
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_data_type_stand)           --���ږ�
                    ) || cv_line_feed;
      --
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�f�[�^��ʃ`�F�b�N
      IF ( iv_get_format != gr_order_work_data(in_cnt)(cn_data_type_stand) ) THEN
        --���[�j���O���b�Z�[�W�쐬
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_data_type_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                        iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                        iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
                        iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
                        iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                        iv_token_value4  => gr_order_work_data(in_cnt)(cn_data_type_stand)                   --�ݒ�l
                      ) || cv_line_feed;
      --
      END IF;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
    -- ���ߎ���
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_total_time),    -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_total_time),            -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_total_time_dlength,                                -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => cn_priod,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
      IF ( gr_order_work_data(in_cnt)(cn_total_time) IS NOT NULL ) THEN
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
        --�����ԃ`�F�b�N
        IF ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) >= 0 ) AND
           ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) <= 23 ) THEN
          ov_total_time := to_char(gr_order_work_data(in_cnt)(cn_total_time)) ; -- 3.<���ߎ���>
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    END IF;
--
    --������
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
      od_order_date := TO_DATE(gr_order_work_data(in_cnt)(cn_order_date),cv_yyyymmdd_format);     -- 4.<������>
    END IF;
--
    --�[�i��
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
      od_delivery_date := TO_DATE(gr_order_work_data(in_cnt)(cn_delivery_date),cv_yyyymmdd_format);     -- 5.<�[�i��>
    END IF;
--
-- ************** Ver1.28 DEL START *************** --
--    --�I�[�_�[No.
--    xxccp_common_pkg2.upload_item_check(
--      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.���ږ���(���{�ꖼ)         -- �K�{
--      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.���ڂ̒l                   -- �C��
--      in_item_len     => cn_order_number_dlength,                              -- 3.���ڂ̒���                 -- �K�{
--      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    --
--    --���[�j���O
--    IF ( lv_retcode = cv_status_warn ) THEN
--      --���[�j���O���b�Z�[�W�쐬
--      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                      iv_application   => ct_xxcos_appl_short_name,
--                      iv_name          => ct_msg_get_format_err,
--                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_number)              --���ږ�
--                    ) || cv_line_feed;
--      --
--    --���ʊ֐��G���[
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    --����I��
--    ELSIF ( lv_retcode = cv_status_normal ) THEN
--      ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<�I�[�_�[No.>
--    END IF;
-- ************** Ver1.28 DEL END   *************** --
--
    --�sNo.
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_number),   -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => gr_order_work_data(in_cnt)(cn_line_number),           -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_line_number_dlength,                               -- 3.���ڂ̒���                 -- �K�{
/* 2011/01/25 1.23 H.Sekine Mod Start */
--      in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      in_item_decimal => cn_priod,                                             -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
/* 2011/01/25 1.23 H.Sekine Mod End   */
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
/* 2011/01/25 1.23 H.Sekine Mod Start */
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
/* 2011/01/25 1.23 H.Sekine Mod End   */
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
      ov_line_number := gr_order_work_data(in_cnt)(cn_line_number);   -- 7.<�sNo.>
    END IF;
    --
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
-- ********************* 2010/01/12 1.18 M.Uehara ADD START ********************* --
      --�o�ד�
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_shipping_date), -- 1.���ږ���(���{�ꖼ)         -- �K�{
        iv_item_value   => gr_order_work_data(in_cnt)(cn_shipping_date),         -- 2.���ڂ̒l                   -- �C��
        in_item_len     => cn_ship_date_dlength,                                 -- 3.���ڂ̒���                 -- �K�{
        in_item_decimal => NULL,                                                 -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
        iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shipping_date)             --���ږ�
                      ) || cv_line_feed;
        --
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        od_shipping_date        :=  TO_DATE(gr_order_work_data(in_cnt)(cn_shipping_date),cv_yyyymmdd_format);-- 13.<�o�ד�>
      END IF;
--
-- ************** Ver1.29 ADD START *************** --
    --�o�׎w��
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
      ov_ship_instructions := gr_order_work_data(in_cnt)(cn_ship_instructions_stand);
    END IF;
--
-- ************** Ver1.29 ADD END   *************** --
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
-- ************** Ver1.28 DEL START *************** --
--    --�ڋq�����ԍ�
--    xxccp_common_pkg2.upload_item_check(
--      iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.���ږ���(���{�ꖼ)         -- �K�{
--      iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.���ڂ̒l                   -- �C��
--      in_item_len     => cn_cust_po_number_digit,                                     -- 3.���ڂ̒���                 -- �K�{
--      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
--      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
--      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
--      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    --
--    --���[�j���O
--    IF ( lv_retcode = cv_status_warn ) THEN
--      --���[�j���O���b�Z�[�W�쐬
--      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                      iv_application   => ct_xxcos_appl_short_name,
--                      iv_name          => ct_msg_get_format_err,
--                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
--                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
--                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
--                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --�I�[�_�[NO
--                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
--                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --�sNo
--                      iv_token_name4   => cv_tkn_err_msg ,                                                 --�G���[���b�Z�[�W(�g�[�N��)
--                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --���ږ�
--                    ) || cv_line_feed;
--      --
--    --���ʊ֐��G���[
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    --����I��
--    ELSIF ( lv_retcode = cv_status_normal ) THEN
--      ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
--    END IF;
--    --
-- ************** Ver1.28 DEL END   *************** --
    --�u����CSV�v�A�u���{CSV�v�A�u�L����`CSV�v�A�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�̏ꍇ�A
    -- �����o�����Ɣ����P�[�X���̂����A�����ꂩ�ݒ肳��Ă��邩���`�F�b�N����B
-- ************** Ver1.28 MOD START *************** --
--    IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
      IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
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
      END IF;
    END IF;
--
    --���[�j���O���b�Z�[�W�����邩
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
    --
    --�u���{CSV�v�A�u�L����`CSV�v�̏ꍇ�A���ꏤ�i�R�[�h��NULL��ݒ肷��B
    IF ( iv_get_format IN ( cv_mihon_format , cv_koukoku_format ) ) THEN
      ov_tokushu_item_code := NULL;
    END IF;
    --
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
--
-- ********************* 2010/01/12 1.18 M.Uehara ADD END  ********************* --
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
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <�}�X�^���̎擾����>(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    in_cnt                     IN  NUMBER,   -- �f�[�^��
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
    iv_get_format              IN  VARCHAR2, -- �t�H�[�}�b�g�p�^�[��
    iv_organization_id         IN  VARCHAR2, -- �g�DID
    in_line_no                 IN  NUMBER,   -- �sNO.
    iv_chain_store_code        IN  VARCHAR2, -- �`�F�[���X�R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--    iv_central_code            IN  NUMBER,   -- �Z���^�[�R�[�h
    iv_central_code            IN  VARCHAR2, -- �Z���^�[�R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
    iv_case_jan_code           IN  VARCHAR2, -- �P�[�XJAN�R�[�h
    iv_delivery                IN  VARCHAR2, -- �[�i��(����)
    iv_sej_item_code           IN  VARCHAR2, -- SEJ���i�R�[�h
    id_order_date              IN  DATE,     -- ������
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
    id_request_date            IN  DATE,     -- �v����
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
-- ********************* 2010/12/03 1.21 H.Sekine ADD START********************* --
    iv_tokushu_item_code       IN VARCHAR2,  -- ����i�ڃR�[�h
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
-- ************** Ver1.28 ADD START *************** --
    iv_subinventory            IN  VARCHAR2, -- �ۊǏꏊ
    iv_line_type               IN  VARCHAR2, -- �󒍖��׃^�C�v
    iv_sales_class             IN  VARCHAR2, -- ����敪
-- ************** Ver1.28 ADD END   *************** --
    ov_account_number          OUT VARCHAR2, -- �ڋq�R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--    on_delivery_code           OUT NUMBER,   -- �z����R�[�h
    ov_delivery_code           OUT VARCHAR2, -- �z����R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
    ov_delivery_base_code      OUT VARCHAR2, -- �[�i���_�R�[�h
    ov_salse_base_code         OUT VARCHAR2, -- ���� or �O�� ���_�R�[�h
    ov_item_no                 OUT VARCHAR2, -- �i�ڃR�[�h
    on_primary_unit_of_measure OUT VARCHAR2, -- ��P��
    ov_prod_class_code         OUT VARCHAR2, -- ���i�敪
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    on_salesrep_id             OUT NUMBER,   -- �c�ƒS��ID
    ov_employee_number         OUT VARCHAR2, -- �ŏ�ʎҏ]�ƈ��ԍ�
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
    lv_jan_cd_name    VARCHAR2(50);    --JAN�R�[�h
    lv_stock_name     VARCHAR2(50);    --�݌ɃR�[�h
    lv_sej_cd_name    VARCHAR2(50);    --SEJ���i�R�[�h
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    ld_process_month  DATE;            --�Ɩ����t(���P��)
    ld_request_month  DATE;            --�v�����@(���P��)
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
--****************************** 2010/12/03 1.21 H.Sekine ADD START*******************************--
    ln_item_id        NUMBER;          --�i��ID
    ln_parent_item_id NUMBER;          --�e�i��ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END  *******************************--
-- ************** Ver1.28 ADD START *************** --
    lv_subinv_chk     VARCHAR2(128);   -- �ۊǏꏊ
    lv_sls_cls_chk    VARCHAR2(128);   -- ����敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2018/01/23 V1.31 Added START    *************** --
    ln_dummy          NUMBER;          -- ���݃`�F�b�N�p�_�~�[
-- ************** 2018/01/23 V1.31 Added END      *************** --
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
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    -- �Ɩ����t�����P�ʂɕύX(yyyy/mm/01:�ɕύX)
    ld_process_month := TRUNC(gd_process_date, cv_trunc_mm);
    -- �v�����@�����P�ʂɕύX(yyyy/mm/01:�ɕύX)
    ld_request_month := TRUNC(id_request_date, cv_trunc_mm);
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
    ------------------------------------
    -- 1.�ڋq�ǉ����}�X�^�̃`�F�b�N(�≮CSV)
    --  (�`�F�[���X�R�[�h�ƃZ���^�[�R�[�h�̃`�F�b�N)
    ------------------------------------
    IF ( iv_get_format = cv_tonya_format )  THEN
      BEGIN
--****************************** 2010/04/15 1.19 M.Sano MOD  START *******************************--
--        SELECT  accounts.account_number,                                          -- �ڋq�R�[�h
--                addon.delivery_base_code,                                         -- �[�i���_�R�[�h
--                CASE
----                  WHEN rsv_sale_base_act_date > id_order_date THEN
--                    addon.past_sale_base_code
--                  ELSE
--                    addon.sale_base_code
--                END                                                               -- ���� or �O�� ���_�R�[�h
        SELECT  accounts.account_number    account_number,                        -- �ڋq�R�[�h
                addon.delivery_base_code   delivery_base_code,                    -- �[�i���_�R�[�h
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code                         -- ���� or �O�� ���_�R�[�h
--****************************** 2010/04/15 1.19 M.Sano MOD  END   *******************************--
        INTO    ov_account_number,                                                -- �ڋq�R�[�h
                ov_delivery_base_code,                                            -- �[�i���_�R�[�h
                ov_salse_base_code
        FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
                xxcmm_cust_accounts            addon,                             -- �ڋq�A�h�I��
                hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
                hz_cust_site_uses_all          uses                               -- �ڋq�g�p�ړI
        WHERE   accounts.cust_account_id       = sites.cust_account_id
        AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
        AND     accounts.cust_account_id       = addon.customer_id
        AND     accounts.customer_class_code   = cn_customer_div_cust             -- �ڋq�敪�F10�i�ڋq�j
        AND     addon.chain_store_code         = iv_chain_store_code              -- EDI�`�F�[���X�R�[�h
        AND     addon.store_code               = iv_central_code                  -- �X�R�[�h
        AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
        AND     sites.org_id                   = gn_org_id
        AND     uses.org_id                    = gn_org_id
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
        AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
        ;
        --
        --
        IF ( ov_account_number IS NOT NULL ) THEN
          SELECT  hl.province                                                       -- �z����R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--          INTO    on_delivery_code
          INTO    ov_delivery_code
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
                  hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
                  hz_cust_site_uses_all          uses,                              -- �ڋq�g�p�ړI
                  hz_party_sites                 hps,                               -- �p�[�e�B�T�C�g
                  hz_locations                   hl                                 -- ���P�[�V����
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
                  ,xxcmn_party_sites             xps          -- �p�[�e�B�T�C�g�A�h�I���}�X�^
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
          WHERE   accounts.cust_account_id       = sites.cust_account_id
          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
          AND     accounts.customer_class_code   = cn_customer_div_cust             -- �ڋq�敪�F10�i�ڋq�j
          AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
          AND     sites.org_id                   = gn_prod_ou_id
          AND     uses.org_id                    = gn_prod_ou_id
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
          AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
          AND     sites.party_site_id            = hps.party_site_id
          AND     hps.location_id                = hl.location_id
          AND     accounts.account_number        = ov_account_number
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
          AND    hps.party_id                    =  xps.party_id
          AND    hps.party_site_id               =  xps.party_site_id
          AND    hps.location_id                 =  xps.location_id
          AND    xps.base_code                   =  ov_salse_base_code
          AND    xps.start_date_active           <= id_request_date
          AND    xps.end_date_active             >= id_request_date
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
          ;
        END IF;
        -- �ڋq�ǉ����}�X�^�̃`�F�b�N�̃G���[�ҏW
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--        IF ( on_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
        IF ( ov_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          RAISE global_cust_check_expt; --�}�X�^���̎擾
        END IF;
      EXCEPTION
--****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
        WHEN TOO_MANY_ROWS THEN
          RAISE global_t_cust_too_many_expt; --�≮�ڋq����TOO_MANY_ROWS�G���[
--****************************** 2009/07/21 1.11 T.Miyata ADD  END  ******************************--
        WHEN NO_DATA_FOUND THEN
          RAISE global_cust_check_expt; --�}�X�^���̎擾
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
                           iv_name         => ct_msg_get_multiple_store_code
                         );
          lv_central_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_central_code
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
                                        ,iv_data_value2 =>  iv_central_code
                                        ,iv_data_value3 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
--
--****************************** 2010/12/03 1.21 H.Sekine MOD START*******************************--
--    ------------------------------------
--    -- 2.�ڋq�ǉ����}�X�^�̃`�F�b�N(����CSV)
--    --  (�[�i��)
--    ------------------------------------
--    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
    ------------------------------------
    -- 2.�ڋq�ǉ����}�X�^�̃`�F�b�N(����CSV�A���{CSV�A�L����`CSV)
    --  (�[�i��)
    ------------------------------------
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
          ) THEN
    ------------------------------------
    -- ����CSV�A���{CSV�A�L����`��CSV�A�ʏ����CSV�A�ԕi����CSV�A�ԕiCSV�A�ϓ��d�C��CSV (���ڃ`�F�b�N)
    ------------------------------------
-- ************** Ver1.28 MOD END   *************** --
--****************************** 2010/12/03 1.21 H.Sekine MOD END  *******************************--
      BEGIN
--****************************** 2010/04/15 1.19 M.Sano MOD  START *******************************--
--        SELECT  accounts.account_number,                                          -- �ڋq�R�[�h
--                addon.delivery_base_code,                                         -- �[�i���_�R�[�h
--                CASE
--                  WHEN rsv_sale_base_act_date > id_order_date THEN 
--                    addon.past_sale_base_code
--                  ELSE
--                    addon.sale_base_code
--                END                                                               -- ���� or �O�� ���_�R�[�h
        SELECT  accounts.account_number    account_number,                        -- �ڋq�R�[�h
                addon.delivery_base_code   delivery_base_code,                    -- �[�i���_�R�[�h
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code                         -- ���� or �O�� ���_�R�[�h
--****************************** 2010/04/15 1.19 M.Sano MOD  END   *******************************--
        INTO    ov_account_number,                                                -- �ڋq�R�[�h
                ov_delivery_base_code,                                            -- �[�i���_�R�[�h
                ov_salse_base_code                                                -- ����or�O�����_�R�[�h
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
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
        AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
        AND     accounts.account_number        = iv_delivery
        ;
       --
-- *********** 2009/12/04 1.15 N.Maeda DEL START ***********--
--        IF ( ov_account_number IS NOT NULL ) THEN
--          SELECT  hl.province                                                       -- �z����R�[�h
----****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
----          INTO    on_delivery_code
--          INTO    ov_delivery_code
----****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
--          FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
--                  hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
--                  hz_cust_site_uses_all          uses,                              -- �ڋq�g�p�ړI
--                  hz_party_sites                 hps,
--                  hz_locations                   hl
--          WHERE   accounts.cust_account_id       = sites.cust_account_id
--          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
--          AND     accounts.customer_class_code   = cn_customer_div_cust             -- �ڋq�敪�F10�i�ڋq�j
--          AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
--          AND     sites.org_id                   = gn_prod_ou_id
--          AND     uses.org_id                    = gn_prod_ou_id
----****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
--          AND     sites.status                   = cv_cust_status_active            -- �ڋq���ݒn.�X�e�[�^�X�FA
----****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
--          AND     sites.party_site_id            = hps.party_site_id
--          AND     hps.location_id                = hl.location_id
--          AND     accounts.account_number        = ov_account_number
--          ;
--        END IF;
--        -- �ڋq�ǉ����}�X�^�̃`�F�b�N�̃G���[�ҏW
----****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
----        IF ( on_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
--        IF ( ov_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
----****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
--          lv_key_info := in_line_no;
--          RAISE global_item_delivery_mst_expt; --�}�X�^���̎擾
--        END IF;
-- *********** 2009/12/04 1.15 N.Maeda DEL  END  ***********--
      EXCEPTION
-- *********** 2009/12/04 1.15 N.Maeda DEL START ***********--
----****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
--        WHEN TOO_MANY_ROWS THEN
--          RAISE global_k_cust_too_many_expt; --���یڋq���TOO_MANY�G���[
----****************************** 2009/07/21 1.11 T.Miyata ADD  END  ******************************--
-- *********** 2009/12/04 1.15 N.Maeda DEL  END  ***********--
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
    END IF;
--
-- ************** 2018/01/23 V1.31 Added START    *************** --
    IF  (     iv_get_format = cv_electricity_format
          AND gv_order_up_bis_center = cv_bis_center
        )
    THEN
      ------------------------------------
      -- �Ƒԏ����ނ̃`�F�b�N�̃`�F�b�N(�ϓ��d�C��CSV)  �����Z���^�[�̏ꍇ�̂�
      --  24.�t��VD(����), 25.�t��VD�ȊO��NG
      ------------------------------------
      BEGIN
        SELECT  1       exists_flag
        INTO    ln_dummy
        FROM    xxcmm_cust_accounts   xca       --  �ڋq�A�h�I��
        WHERE   xca.customer_code       =   iv_delivery
        AND     xca.business_low_type   IN( cv_business_low_type_24, cv_business_low_type_25 )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_business_low_type_expt;    --  �Ƒԏ����ނ̃`�F�b�N��O
      END;
      --
      ------------------------------------
      -- �x�������i�d�C��j�̃`�F�b�N(�ϓ��d�C��CSV)  �����Z���^�[�̏ꍇ�̂�
      --  �ŐV�̌_�񂪁A�d�C��敪�u�ϓ��v�A�x�������i�d�C��j�u�_���v�ȊO��NG
      ------------------------------------
      BEGIN
        SELECT  1       exists_flag
        INTO    ln_dummy
        FROM    xxcso_contract_managements    xcm     --  �_��Ǘ��e�[�u��
              , xxcso_sp_decision_headers     xsdh    --  �r�o�ꌈ�w�b�_�e�[�u��
        WHERE   xcm.sp_decision_header_id           =   xsdh.sp_decision_header_id
        AND     xcm.install_account_number          =   iv_delivery
        AND     xcm.status                          =   cv_management_status_1            --  �X�e�[�^�X�F1.�m���
        AND     xcm.cooperate_flag                  =   cv_finish_cooperate               --  �}�X�^�A�g�t���O�F1.�A�g��
        AND     xsdh.electricity_type               =   cv_electricity_type_change        --  �d�C��敪�F2.�ϓ�
        AND     xsdh.electric_payment_type          =   cv_sp_electric_pay_type_1         --  �x�������i�d�C��j�F1.�_���
        AND     xcm.contract_management_id          =   ( --  �m��ρA�A�g�ς̒��ōŐV�̌_��
                                                          SELECT  MAX( sub.contract_management_id )     max_contract_management_id
                                                          FROM    xxcso_contract_managements    sub
                                                          WHERE   sub.install_account_number    =   xcm.install_account_number
                                                          AND     sub.status                    =   cv_management_status_1
                                                          AND     sub.cooperate_flag            =   cv_finish_cooperate
                                                        )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_electric_pay_expt;         --  �x�������i�d�C��j�̃`�F�b�N��O
      END;
    END IF;
-- ************** 2018/01/23 V1.31 Added END      *************** --
    ------------------------------------
    -- 2.�t�H�[�}�b�g�p�^�[���̔���
    ------------------------------------
    --������
    ln_item_chk := 0;
    IF ( iv_get_format = cv_tonya_format )THEN
--****************************** 2009/08/21 1.12 M.Sano Mod Start    ******************************--
--      ------------------------------------
--      -- 2-1.�i�ڃA�h�I���}�X�^�̃`�F�b�N
--      --  (�P�[�XJAN�R�[�h�̃`�F�b�N)
--      ------------------------------------
--      BEGIN
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
----        SELECT xim.item_code,                   --�i�ڃR�[�h
----               mib.primary_unit_of_measure,     --��P��
----               mib.customer_order_enabled_flag, --�i�ڃX�e�[�^�X
----               iim.attribute26,                 --����Ώۋ敪
----               xi5.prod_class_code              --���i�敪�R�[�h
----        INTO   ov_item_no,                      --�i�ڃR�[�h
----               on_primary_unit_of_measure,      --��P��
----               gt_inventory_item_status_code,   --�i�ڃX�e�[�^�X
----               gt_prod_class_code,              --����Ώۋ敪
----               ov_prod_class_code               --���i�敪�R�[�h
----        FROM   mtl_system_items_b         mib,  -- �i�ڃ}�X�^
----               xxcmm_system_items_b       xim,  -- Disc�i�ڃA�h�I���}�X�^
----               ic_item_mst_b              iim,  -- OPM�i�ڃ}�X�^
----               xxcmn_item_categories5_v   xi5   -- ���i�敪View
----        WHERE  mib.segment1          = xim.item_code
----        AND    mib.segment1          = iim.item_no
----        AND    iim.item_no           = xi5.item_no
----        AND    mib.organization_id   = iv_organization_id  --�g�DID
----        AND    xim.case_jan_code     = iv_case_jan_code;   --�P�[�XJAN�R�[�h
----
--        SELECT ims.item_code,
--               ims.primary_unit_of_measure,
--               ims.customer_order_enabled_flag,
--               ims.attribute26,
--               ims.prod_class_code
--        INTO   ov_item_no,                      --�i�ڃR�[�h
--               on_primary_unit_of_measure,      --��P��
--               gt_inventory_item_status_code,   --�i�ڃX�e�[�^�X
--               gt_prod_class_code,              --����Ώۋ敪
--               ov_prod_class_code               --���i�敪�R�[�h
--        FROM   (
----              SELECT xsi.item_code                   item_code,                   --�i�ڃR�[�h
--                       mib.primary_unit_of_measure     primary_unit_of_measure,     --��P��
--                       mib.customer_order_enabled_flag customer_order_enabled_flag, --�i�ڃX�e�[�^�X
--                       iim.attribute26                 attribute26,                 --����Ώۋ敪
--                       xi5.prod_class_code             prod_class_code              --���i�敪�R�[�h
--                FROM   mtl_system_items_b         mib,                              --Disc�i�ڃ}�X�^
--                       xxcmm_system_items_b       xsi,                              --Disc�i�ڃA�h�I���}�X�^
--                       ic_item_mst_b              iim,                              --OPM�i�ڃ}�X�^
--                       xxcmn_item_mst_b           xim,                              --OPM�i�ڃA�h�I���}�X�^
--                       xxcmn_item_categories5_v   xi5                               --���i�敪View
--                WHERE  mib.segment1                                  = xsi.item_code
--                AND    mib.segment1                                  = iim.item_no
--                AND    iim.item_no                                   = xi5.item_no
--                AND    TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date
--                AND    iim.item_id                                   = xim.item_id
--                AND    xim.item_id                                   = xim.parent_item_id
--                AND    mib.organization_id                           = TO_NUMBER( iv_organization_id ) --�g�DID
--                AND    xsi.case_jan_code                             = iv_case_jan_code                --�P�[�XJAN�R�[�h
--                ORDER BY iim.attribute13 DESC
--               ) ims
--        WHERE  ROWNUM  = 1
--        ;
--****************************** 2009/08/21 1.12 M.Sano DEL Start    ******************************--
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
--        -- �i�ڃ}�X�^��񂪎擾�ł��Ȃ��ꍇ
--        IF ( ( ov_item_no IS NULL ) OR
--             ( on_primary_unit_of_measure IS NULL ) OR
--             ( gt_inventory_item_status_code IS NULL ) OR
--             ( gt_prod_class_code IS NULL ) OR
--             ( ov_prod_class_code IS NULL )
--           )
--        THEN
--          ln_item_chk := 1;
--        END IF;
--        --����Ώۋ敪��0
--        IF ( gt_prod_class_code = 0 ) THEN
--          ln_item_chk := 1;
--        END IF;
--        --�ڋq�󒍉\�t���O
--        IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
--          ln_item_chk := 1;
--        END IF;
----
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_item_chk := 1;
--        WHEN OTHERS THEN
--          lv_table_info := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_item_mstr
--                         );
--          lv_lien_no_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_lien_no
--                         );
--          lv_jan_cd_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_jan_code
--                         );
--          lv_stock_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_inv_org_id
--                         );
--          xxcos_common_pkg.makeup_key_info(
--                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
--                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
--                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
--                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
--                                        ,iv_item_name1  =>  lv_jan_cd_name
--                                        ,iv_item_name2  =>  lv_Stock_name
--                                        ,iv_item_name3  =>  lv_lien_no_name
--                                        ,iv_data_value1 =>  iv_case_jan_code
--                                        ,iv_data_value2 =>  iv_organization_id
--                                        ,iv_data_value3 =>  in_line_no
--                                       );
--          IF (lv_retcode = cv_status_normal) THEN
--            RAISE global_select_err_expt;
--          ELSE
--            RAISE global_api_expt;
--          END IF;
--      END;
----
--      ------------------------------------
--      -- 2-2.�i�ڃA�h�I���}�X�^�̃`�F�b�N
--      --  (JAN�R�[�h�̃`�F�b�N)
--      ------------------------------------
--      IF ( ln_item_chk = 1 ) THEN
--        BEGIN
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
----          SELECT iim.item_no,                         --�i�ڃR�[�h
----                 mib.primary_unit_of_measure,         --��P��
----                 mib.customer_order_enabled_flag,     --�ڋq�󒍉\�t���O
----                 iim.attribute26,                     --����Ώۋ敪
----                 xi5.prod_class_code                  --���i�敪�R�[�h
----          INTO   ov_item_no,                          --�i�ڃR�[�h
----                 on_primary_unit_of_measure,          --��P��
----                 gt_inventory_item_status_code,       --�ڋq�󒍉\�t���O
----                 gt_prod_class_code,                  --����Ώۋ敪
----                 ov_prod_class_code                   --���i�敪�R�[�h
----          FROM   mtl_system_items_b         mib,      --�i�ڃ}�X�^
----                 ic_item_mst_b              iim,      --OPM�i�ڃ}�X�^
----                 xxcmn_item_categories5_v   xi5       --���i�敪View
----          WHERE mib.segment1          = iim.item_no
----          AND   iim.item_id           = xi5.item_id
----          AND   mib.organization_id   = iv_organization_id   --�g�DID
----          AND   iim.attribute21       = iv_case_jan_code;    --JAN�R�[�h
----
--          SELECT item_no,
--                 primary_unit_of_measure,
--                 customer_order_enabled_flag,
--                 attribute26,
--                 prod_class_code
--          INTO   ov_item_no,                          --�i�ڃR�[�h
--                 on_primary_unit_of_measure,          --��P��
--                 gt_inventory_item_status_code,       --�ڋq�󒍉\�t���O
--                 gt_prod_class_code,                  --����Ώۋ敪
--                 ov_prod_class_code                   --���i�敪�R�[�h
--          FROM   (
--                  SELECT iim.item_no                     item_no,                         --�i�ڃR�[�h
--                         mib.primary_unit_of_measure     primary_unit_of_measure,         --��P��
--                         mib.customer_order_enabled_flag customer_order_enabled_flag,     --�ڋq�󒍉\�t���O
--                         iim.attribute26                 attribute26,                     --����Ώۋ敪
--                         xi5.prod_class_code             prod_class_code                  --���i�敪�R�[�h
--                  FROM   mtl_system_items_b         mib,      --Disc�i�ڃ}�X�^
--                         ic_item_mst_b              iim,      --OPM�i�ڃ}�X�^
--                         xxcmn_item_mst_b           xim,      --OPM�i�ڃA�h�I���}�X�^
--                         xxcmn_item_categories5_v   xi5       --���i�敪View
--                  WHERE mib.segment1                                  = iim.item_no
--                  AND   iim.item_id                                   = xi5.item_id
--                  AND   mib.organization_id                           = TO_NUMBER( iv_organization_id )   --�g�DID
--                  AND   iim.attribute21                               = iv_case_jan_code                  --JAN�R�[�h
--                  AND   TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date
--                  AND   iim.item_id                                   = xim.item_id
--                  AND   xim.item_id                                   = xim.parent_item_id
--                  ORDER BY iim.attribute13 DESC
--                 ) ims
--          WHERE  ROWNUM  = 1
--          ;
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
      ------------------------------------
      -- 2-1.�i�ڃA�h�I���}�X�^�̃`�F�b�N
      --  (�ڋq�i�ڂ̃`�F�b�N)
      ------------------------------------
      BEGIN
        SELECT ims.item_code                    item_code
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
              ,ims.item_id                      item_id
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
              ,ims.primary_unit_of_measure      primary_unit_of_measure
              ,ims.customer_order_enabled_flag  customer_order_enabled_flag
              ,ims.attribute26                  attribute26
              ,ims.prod_class_code              prod_class_code
        INTO   ov_item_no,                      --�i�ڃR�[�h
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
               ln_item_id,                      --�i��ID
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
               on_primary_unit_of_measure,      --��P��
               gt_inventory_item_status_code,   --�i�ڃX�e�[�^�X
               gt_prod_class_code,              --����Ώۋ敪
               ov_prod_class_code               --���i�敪�R�[�h
        FROM  (
               SELECT iim.item_no                     item_code,                   --�i�ڃR�[�h
                      iim.item_id                     item_id,                     --�i��ID
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--                      mib.primary_unit_of_measure     primary_unit_of_measure,     --��P��
                      mci.attribute1                  primary_unit_of_measure,     --��P��
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
                      mib.customer_order_enabled_flag customer_order_enabled_flag, --�i�ڃX�e�[�^�X
                      iim.attribute26                 attribute26,                 --����Ώۋ敪
                      xi5.prod_class_code             prod_class_code              --���i�敪�R�[�h
               FROM   hz_cust_accounts           hca,                              --�ڋq�}�X�^
                      xxcmm_cust_accounts        xca,                              --�ڋq�A�h�I��
                      mtl_customer_items         mci,                              --�ڋq�i��
                      mtl_customer_item_xrefs    mcx,                              --�ڋq�i�ڑ��ݎQ��
                      mtl_parameters             mpa,                              --�p�����[�^
                      mtl_system_items_b         mib,                              --Disc�i�ڃ}�X�^
                      ic_item_mst_b              iim,                              --OPM�i�ڃ}�X�^
                      xxcmn_item_categories5_v   xi5                               --���i�敪View
               WHERE  xca.edi_chain_code                            = iv_chain_store_code             -- ����:EDI�`�F�[���X�R�[�h
               AND    hca.cust_account_id                           = xca.customer_id                 -- �ڋq�}�X�^
               AND    hca.customer_class_code                       = cv_customer_div_chain           -- ����:�ڋq�敪=18
               AND    mci.customer_id                               = hca.cust_account_id             -- �ڋq�i��
               AND    mci.customer_item_number                      = iv_case_jan_code                -- ����:�ڋq�i��=JAN�R�[�h
               AND    mci.item_definition_level                     = cv_cust_item_def_level          -- ����:��`���x��=�ڋq
               AND    mci.inactive_flag                             = cv_inactive_flag_no             -- ����:�L��
               AND    mcx.customer_item_id                          = mci.customer_item_id            -- �ڋq�i�ڑ��ݎQ��
               AND    mcx.inactive_flag                             = cv_inactive_flag_no             -- ����:�L��
               AND    mcx.master_organization_id                    = mpa.master_organization_id      -- �p�����[�^
               AND    mpa.organization_id                           = TO_NUMBER( iv_organization_id ) -- ����:�g�DID
               AND    mib.inventory_item_id                         = mcx.inventory_item_id           -- Disc�i�ڃ}�X�^
               AND    mib.organization_id                           = TO_NUMBER( iv_organization_id ) -- ����:�g�DID
               AND    mib.segment1                                  = iim.item_no                     -- OPM�i�ڃ}�X�^
               AND    TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date                   -- ����:�̔�(����)�J�n��>�󒍓�
               AND    xi5.item_no                                   = iim.item_no                     -- ���i�敪View
               ORDER BY mcx.preference_number ) ims
        WHERE  ROWNUM = 1
        ;
--****************************** 2009/08/21 1.12 M.Sano Mod End      ******************************--
          -- �i�ڃ}�X�^��񂪎擾�ł��Ȃ��ꍇ�̃G���[�ҏW
        IF ( ( ov_item_no IS NULL ) OR
             ( on_primary_unit_of_measure IS NULL ) OR
             ( gt_inventory_item_status_code IS NULL ) OR
             ( gt_prod_class_code IS NULL ) OR
             ( ov_prod_class_code IS NULL )
           )
        THEN
          lv_key_info := in_line_no;
          RAISE global_cus_data_check_expt;
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
--
      EXCEPTION
        --����Ώۋ敪��0
        WHEN global_item_status_expt THEN
          RAISE global_item_status_expt;
        --�ڋq�󒍉\�t���O
        WHEN global_item_status_code_expt THEN
          RAISE global_item_status_code_expt;
        --�i�ڃ}�X�^��񂪎擾�G���[
        WHEN global_cus_data_check_expt THEN
          RAISE global_cus_data_check_expt;
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_cus_data_check_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_jan_cd_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_jan_code
                         );
          lv_stock_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_inv_org_id
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
                                        ,iv_item_name1  =>  lv_jan_cd_name
                                        ,iv_item_name2  =>  lv_Stock_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_case_jan_code
                                        ,iv_data_value2 =>  iv_organization_id
                                        ,iv_data_value3 =>  in_line_no
                                       );
          IF (lv_retcode = cv_status_normal) THEN
            RAISE global_select_err_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
--****************************** 2009/08/21 1.12 M.Sano DEL Start      ******************************--
--      END IF;
--****************************** 2009/08/21 1.12 M.Sano DEL End        ******************************--
--****************************** 2010/12/03 1.21 H.Sekine MOD START    ******************************--
/* 
    --���ۂ̎��ASEJ���i�R�[�h����
    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
*/
    --�u����CSV�v�A�u���{CSV�v�A�u�L����`��CSV�v�A
    --�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ�ASEJ���i�R�[�h���������܂��B
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
--****************************** 2010/12/03 1.21 H.Sekine MOD END      ******************************--
      BEGIN
        SELECT iim.item_no,                        --�i�ڃR�[�h
--****************************** 2010/12/03 1.21 H.Sekine ADD START    ******************************--
               iim.item_id,                        --�i��ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END      ******************************--
               mib.primary_unit_of_measure,        --��P��
               mib.customer_order_enabled_flag,    --�ڋq�󒍉\�t���O
               iim.attribute26,                    --����Ώۋ敪
               xi5.prod_class_code                 --���i�敪�R�[�h
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
               ,iim.attribute11                    --�P�[�X����
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
        INTO   ov_item_no,                         --�i�ڃR�[�h
--****************************** 2010/12/03 1.21 H.Sekine ADD START    ******************************--
               ln_item_id,                         --�i��ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END      ******************************--
               on_primary_unit_of_measure,         --��P��
               gt_inventory_item_status_code,      --�ڋq�󒍉\�t���O
               gt_prod_class_code,                 --����Ώۋ敪
               ov_prod_class_code                  --���i�敪�R�[�h
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
               ,gt_case_num                        --�P�[�X����
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
        FROM   mtl_system_items_b         mib,     --�i�ڃ}�X�^
               ic_item_mst_b              iim,     --OPM�i�ڃ}�X�^
               xxcmn_item_categories5_v   xi5      --���i�敪View
        WHERE  mib.segment1          = iim.item_no
        AND    iim.item_id           = xi5.item_id
        AND    mib.organization_id   = iv_organization_id  --�g�DID
        AND    iim.item_no           = iv_sej_item_code    --SEJ���i�R�[�h
        ;
        -- �i�ڃ}�X�^��񂪎擾�ł��Ȃ��ꍇ�̃G���[�ҏW
        IF ( ( ov_item_no IS NULL ) OR
             ( on_primary_unit_of_measure IS NULL ) OR
             ( gt_inventory_item_status_code IS NULL ) OR
             ( gt_prod_class_code IS NULL ) OR
             ( ov_prod_class_code IS NULL )
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
             OR ( gt_case_num IS NULL )
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
           )
        THEN
          lv_key_info := in_line_no;
          RAISE global_cus_sej_check_expt;
        END IF;
-- ************** Ver1.28 ADD START *************** --
        -- �ϓ��d�C��̏ꍇ�̕i�ڃR�[�h�`�F�b�N
        IF ( iv_get_format = cv_electricity_format ) THEN
          IF ( ov_item_no != gt_e_fee_item_cd ) THEN
            lv_key_info := in_line_no;
            RAISE global_e_fee_item_cd_expt;
          END IF;
        ELSE
-- ************** Ver1.28 ADD END   *************** --
          --����Ώۋ敪��0
          IF ( gt_prod_class_code = 0 ) THEN
            lv_key_info := in_line_no;
            RAISE global_item_status_expt;
          END IF;
-- ************** Ver1.28 ADD START *************** --
        END IF;
-- ************** Ver1.28 ADD END   *************** --
        --�ڋq�󒍉\�t���O
        IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
          lv_key_info := in_line_no;
          RAISE global_item_status_code_expt;
        END IF;
      EXCEPTION
-- ************** Ver1.28 ADD START *************** --
        --�ϓ��d�C���i�ڃR�[�h�G���[
        WHEN global_e_fee_item_cd_expt THEN
          RAISE global_e_fee_item_cd_expt;
-- ************** Ver1.28 ADD END   *************** --
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
                                        ,iv_data_value1 =>  iv_sej_item_code
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
    END IF;
-- ********************* 2010/12/03 1.21 H.Sekine ADD START   ********************* --
    -- �u�≮CSV�v�A�u����CSV�v�̏ꍇ�A�q�R�[�h�̑Ó����`�F�b�N���s�Ȃ��܂��B
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format ) ) THEN
      IF ( iv_tokushu_item_code IS NOT NULL ) THEN
        --���ꏤ�i�R�[�h��NULL�łȂ��ꍇ�A�`�F�b�N���s���B
        BEGIN
          SELECT xim.item_id
          INTO   ln_parent_item_id
          FROM   ic_item_mst_b              iim     --OPM�i�ڃ}�X�^
                ,xxcmn_item_mst_b           xim     --OPM�i�ڃA�h�I���}�X�^
          WHERE  iim.item_no   = iv_tokushu_item_code
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
                          iv_token_value4  => iv_tokushu_item_code,                                            --����i�ڃR�[�h
                          iv_token_name5   => cv_tkn_param5,                                                   --�p�����[�^5(�g�[�N��)
                          iv_token_value5  => ov_item_no                                                       --�i�ڃR�[�h
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
        END;
      END IF;
    END IF;
-- ********************* 2010/12/03 1.21 H.Sekine ADD END     ********************* --
-- ************** Ver1.28 ADD START *************** --
    -- �u�ʏ����CSV�v�A�u�ԕi����CSV�v�̏ꍇ�A�󒍃^�C�v�i���ׁj�̑Ó����`�F�b�N���s�Ȃ��܂��B
    IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format ) ) THEN
      -----------------
      -- �󒍖��׃^�C�v
      -----------------
      BEGIN
        SELECT /*+ USE_NL(ott flv) */
               ott.name                                  order_line_type_name
              ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg
              ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg
        INTO   gt_order_line_type_name    --�󒍃^�C�v��
              ,gt_line_context_unset_flg  --���׃R���e�L�X�g���ݒ�t���O
              ,gt_sales_class_must_flg    --����敪�ݒ�t���O
        FROM   oe_transaction_types_tl   ott,
               oe_transaction_types_all  otl,
               fnd_lookup_values         flv
        WHERE  flv.lookup_type           = ct_look_up_type
          AND  flv.meaning               = iv_line_type
          AND  flv.attribute1            = gv_order        --�w�b�_�̎󒍃^�C�v(�Q�ƃ^�C�v�o�^�l)
          AND  flv.meaning               = ott.name
          AND  flv.language              = ott.language
          AND  ott.language              = USERENV( 'LANG' )
          AND  ott.transaction_type_id   = otl.transaction_type_id
          AND  otl.transaction_type_code = cv_line
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name,
                         iv_name          => ct_msg_o_l_type_mst_err,
                         iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                         iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                         iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                         iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                         iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                         iv_token_value3  => gv_temp_line,                                                    --�sNo
                         iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                         iv_token_value4  => iv_line_type                                                     --�󒍃^�C�v(����)
                       );
           ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
           ov_retcode := cv_status_warn;
           --�G���[�̏ꍇ��NULL��ݒ�
           gt_order_line_type_name := NULL;
           gt_sales_class_must_flg := cv_sales_class_must_n;
      END;
    END IF;
--
    -- �u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ�A�ۊǏꏊ�̑Ó����`�F�b�N���s���܂��B
    IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
      IF ( iv_subinventory IS NOT NULL ) AND ( gt_order_line_type_name IS NOT NULL ) THEN
        BEGIN
          SELECT msi.secondary_inventory_name  subinv_chk
          INTO   lv_subinv_chk
          FROM   mtl_secondary_inventories     msi
          WHERE  msi.organization_id           = iv_organization_id
          AND    msi.secondary_inventory_name  = iv_subinventory
          AND    NVL(msi.disable_date ,SYSDATE + 1) > SYSDATE
          AND    msi.quantity_tracked          = cn_quantity_tracked_on  --�p���L�^�v��
          -- �����܂��͎����_�ɕR�t���ۊǏꏊ
          AND ( (msi.attribute13  = (SELECT xsecv.attribute1  subinv_type
                                     FROM   xxcos_sale_exp_condition_v  xsecv
                                     WHERE  xsecv.attribute2  = gt_order_type_name       --�󒍃^�C�v(�w�b�_)
                                     AND    xsecv.attribute3  = gt_order_line_type_name  --�󒍃^�C�v(����)
                                    )
                )
            OR  (msi.attribute7  IN (SELECT xlbi.base_code  base_code
-- ************** Ver1.30 MOD START *************** --
--                                     FROM   xxcos_login_base_info_v  xlbi
                                     FROM   xxcos_all_or_login_base_info_v  xlbi
-- ************** Ver1.30 MOD END   *************** --
                                    )
                )
              )
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
    END IF;
--
    --�u�≮CSV�v�A�u����CSV�v�A�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ�A����敪�̑Ó����`�F�b�N���s�Ȃ��܂��B
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
      --����敪�ݒ�t���O��'Y'�̏ꍇ�̂݃`�F�b�N
      IF ( gt_sales_class_must_flg = cv_sales_class_must_y ) THEN
        --�K�{�`�F�b�N
-- ************** Ver1.29 MOD START *************** --
--        IF ( iv_sales_class IS NULL ) THEN
        -- �u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ
        IF (  ( iv_sales_class IS NULL )
          AND ( iv_get_format  IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) ) THEN
-- ************** Ver1.29 MOD END   *************** --
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
                        iv_token_value4  => gt_order_line_type_name                                          --�󒍃^�C�v(����)
                      );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
          ov_retcode := cv_status_warn;
--
-- ************** Ver1.29 ADD START *************** --
        -- �u�≮CSV�v�A�u����CSV�v��NULL�̏ꍇ�A�Ó����`�F�b�N�����Ȃ�
        ELSIF (  ( iv_sales_class IS NULL )
          AND    ( iv_get_format  IN ( cv_tonya_format , cv_kokusai_format ) ) ) THEN
          NULL;
--
-- ************** Ver1.29 ADD END   *************** --
        ELSE
          --�Ó����`�F�b�N
          BEGIN
            SELECT flv.lookup_code  sales_class_chk
            INTO   lv_sls_cls_chk
            FROM   fnd_lookup_values flv
            WHERE  flv.language     = USERENV( 'LANG' )
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
    END IF;
-- ************** Ver1.28 ADD END   *************** --
--
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    -- �c�ƒS���A�܂��͍ŏ�ʎ҂̎擾
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
  EXCEPTION
--****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
    -- �≮�ڋq���TOO_MANY�G���[
    WHEN global_t_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_tonya_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_chain_store_code,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => iv_central_code,
                     iv_token_name3  => cv_tkn_param3,
                     iv_token_value3 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- ���یڋq���TOO_MANY�G���[
    WHEN global_k_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_kokusai_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_delivery,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/07/21 1.11 T.Miyata ADD END   ******************************--
    --�}�X�^���̎擾(�≮)
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
                      iv_token_value5  => iv_central_code                                                  --�Z���^�[�R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --�}�X�^���̎擾(����)
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
    WHEN global_cus_data_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_chk_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
                      iv_token_value3  => gv_temp_line,                                                    --�sNo
                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
                      iv_token_value4  => iv_case_jan_code                                                 --JAN�R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
                      iv_token_value4  => iv_sej_item_code                                                 --SEJ���i�R�[�h
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- ************** Ver1.28 ADD START *************** --
    --***** �ϓ��d�C���i�ڃR�[�h
    WHEN global_e_fee_item_cd_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_e_fee_item_err,
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
-- ************** Ver1.28 ADD END   *************** --
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
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
-- ************** Ver1.28 DEL START *************** --
--      ov_retcode := cv_status_normal;
-- ************** Ver1.28 DEL END   *************** --
    --���ʊ֐�(�S���]�ƈ��擾)�G���[��
    WHEN global_get_salesrep_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
-- ************** 2018/01/23 V1.31 Added START    *************** --
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
    --  �x�������i�d�C��j�̃`�F�b�N��O
    WHEN global_electric_pay_expt THEN
      ov_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  ct_xxcos_appl_short_name
                      , iv_name           =>  ct_msg_chk_electric_pay_err
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
-- ************** 2018/01/23 V1.31 Added END      *************** --
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
  END get_master_data;
--
--****************************** 2012/01/06 1.26 Y.Horikawa DEL START*******************************--
-- del v1.26|  /**********************************************************************************
-- del v1.26|   * Procedure Name   : <get_ship_due_date>
-- del v1.26|   * Description      : <�o�ח\����̓��o>(A-7)
-- del v1.26|   ***********************************************************************************/
-- del v1.26|  PROCEDURE get_ship_due_date(
-- del v1.26|    in_cnt                IN  NUMBER,   -- �f�[�^��
-- del v1.26|    in_line_no            IN  NUMBER,   -- �sNO.
-- del v1.26|    id_delivery_date      IN  DATE,     -- �[�i��
-- del v1.26|    iv_item_no            IN  VARCHAR2, -- �i�ڃR�[�h
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD START **********--
-- del v1.26|    iv_tokushu_item_code  IN  VARCHAR2, -- ���ꏤ�i�R�[�h
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD END   **********--
-- del v1.26|    iv_delivery_code      IN  VARCHAR2, -- �z����R�[�h
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--    iv_delivery_base_code IN  VARCHAR2, -- �[�i���_�R�[�h
-- del v1.26|    iv_sales_base_code    IN  VARCHAR2, -- ���㋒�_�R�[�h
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|    iv_item_class_code    IN  VARCHAR2, -- ���i�敪�R�[�h
-- del v1.26|    iv_account_number     IN  VARCHAR2, -- �ڋq�R�[�h
-- del v1.26|    od_ship_due_date      OUT DATE,     -- �o�ח\���
-- del v1.26|    ov_errbuf             OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
-- del v1.26|    ov_retcode            OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
-- del v1.26|    ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- del v1.26|  IS
-- del v1.26|    -- ===============================
-- del v1.26|    -- �Œ胍�[�J���萔
-- del v1.26|    -- ===============================
-- del v1.26|    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_due_date'; -- �v���O������
-- del v1.26|--
-- del v1.26|--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
-- del v1.26|--
-- del v1.26|    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
-- del v1.26|    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
-- del v1.26|    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- del v1.26|--
-- del v1.26|--###########################  �Œ蕔 END   ####################################
-- del v1.26|--
-- del v1.26|    -- ===============================
-- del v1.26|    -- ���[�U�[�錾��
-- del v1.26|    -- ===============================
-- del v1.26|    -- *** ���[�J���萔 ***
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    cn_type           CONSTANT NUMBER := 1;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|    -- *** ���[�J���ϐ� ***
-- del v1.26|    ln_ret            NUMBER;
-- del v1.26|    --
-- del v1.26|    ld_get_deta       DATE;
-- del v1.26|    ld_oprtn_day      DATE;
-- del v1.26|    --
-- del v1.26|    ln_lead_time      NUMBER;
-- del v1.26|    ln_delivery_lt    NUMBER;
-- del v1.26|    --
-- del v1.26|    lv_key_info          VARCHAR2(5000);  --key���
-- del v1.26|    lv_table_info        VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_lien_no_name      VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_item_name         VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_delivery_name     VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_goods_name        VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_deldate_name      VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_warehous_name     VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_read_name         VARCHAR2(50);    --��Ɨp
-- del v1.26|    lv_item_class_name   VARCHAR2(50);    --��Ɨp
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    ld_work_day     DATE;            --���ғ����t
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|    -- *** ���[�J���E�J�[�\�� ***
-- del v1.26|    -- *** ���[�J���E���R�[�h ***
-- del v1.26|--
-- del v1.26|  BEGIN
-- del v1.26|--
-- del v1.26|--##################  �Œ�X�e�[�^�X�������� START   ###################
-- del v1.26|--
-- del v1.26|    ov_retcode := cv_status_normal;
-- del v1.26|--
-- del v1.26|--###########################  �Œ蕔 END   ############################
-- del v1.26|--
-- del v1.26|    -- ***************************************
-- del v1.26|    -- ***   �o�ח\����̓��o����          ***
-- del v1.26|    -- ***************************************
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima ADD START ******************************--
-- del v1.26|    --�ϐ��̏�����
-- del v1.26|    gt_base_code  :=  NULL;
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima ADD  END  ******************************--
-- del v1.26|    ---------------------------
-- del v1.26|    --1.�����\���A�h�I���}�X�^
-- del v1.26|    --�z����R�[�h
-- del v1.26|    ---------------------------
-- del v1.26|    BEGIN
-- del v1.26|      SELECT
-- del v1.26|        xsr.delivery_whse_code        --�o�׌��ۊǏꏊ
-- del v1.26|      INTO
-- del v1.26|        gt_base_code                  --�o�׌��ۊǏꏊ
-- del v1.26|      FROM  xxcmn_sourcing_rules xsr
-- del v1.26|--****************************** 2011/02/21 1.25 H.Sekine MOD START  ******************************--
-- del v1.26|--      WHERE xsr.item_code          =  iv_item_no        -- 1.<�i�ڃR�[�h>
-- del v1.26|      WHERE xsr.item_code          =  NVL( iv_tokushu_item_code , iv_item_no )   -- 1.<�i�ڃR�[�h>
-- del v1.26|--****************************** 2011/02/21 1.25 H.Sekine MOD END    ******************************--
-- del v1.26|      AND   xsr.ship_to_code       =  iv_delivery_code  -- 2.<�z����R�[�h>
-- del v1.26|      AND   xsr.start_date_active  <= id_delivery_date  -- 3.<�[�i��>
-- del v1.26|      AND   xsr.end_date_active    >= id_delivery_date  -- 4.<�[�i��>
-- del v1.26|      ;
-- del v1.26|    --
-- del v1.26|    EXCEPTION
-- del v1.26|      WHEN NO_DATA_FOUND THEN
-- del v1.26|        NULL;
-- del v1.26|      WHEN OTHERS THEN
-- del v1.26|        lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                       );
-- del v1.26|        lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_lien_no
-- del v1.26|                       );
-- del v1.26|        lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_itme_code
-- del v1.26|                       );
-- del v1.26|        lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_delivery_code
-- del v1.26|                       );
-- del v1.26|        lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_delivery_date
-- del v1.26|                       );
-- del v1.26|        xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                       ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
-- del v1.26|                                      ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
-- del v1.26|                                      ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
-- del v1.26|                                      ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
-- del v1.26|                                      ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                      ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                      ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                      ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                      ,iv_data_value1 =>  in_line_no
-- del v1.26|                                      ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                      ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                      ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                     );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|    END;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --2.�����\���A�h�I���}�X�^
-- del v1.26|    --���㋒�_�R�[�h
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --�o�׌��ۊǏꏊ
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --�o�׌��ۊǏꏊ
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|--************ 2011/02/21 1.25 H.Sekine MOD START***********--
-- del v1.26|--        WHERE xsr.item_code          =  iv_item_no              -- �i�ڃR�[�h = �i�ڃR�[�h
-- del v1.26|        WHERE xsr.item_code          =  NVL( iv_tokushu_item_code , iv_item_no )       -- 1.<�i�ڃR�[�h>
-- del v1.26|--************ 2011/02/21 1.25 H.Sekine MOD END  ***********--
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--        AND   xsr.BASE_CODE          =  iv_delivery_base_code   -- ���_�R�[�h = �[�i���_�R�[�h
-- del v1.26|        AND   xsr.base_code          =  iv_sales_base_code      -- ���_�R�[�h = ���㋒�_�R�[�h
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date        -- �K�p�J�n�����[�i��
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;       -- �K�p�I�������[�i��
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          NULL;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --3.�����\���A�h�I���}�X�^
-- del v1.26|    --�z����R�[�h
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --�o�׌��ۊǏꏊ
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --�o�׌��ۊǏꏊ
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|        WHERE xsr.item_code          =  cv_item_z             -- �i�ڃR�[�h = 'ZZZZZZZ'
-- del v1.26|        AND   xsr.ship_to_code       =  iv_delivery_code      -- <�z����R�[�h>
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date      -- �K�p�J�n���� �[�i��
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;     -- �K�p�I������ �[�i��
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          NULL;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|   ---------------------------
-- del v1.26|    --4.�����\���A�h�I���}�X�^
-- del v1.26|    --�z����R�[�h
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --�o�׌��ۊǏꏊ
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --�o�׌��ۊǏꏊ
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|        WHERE xsr.item_code          =  cv_item_z               -- �i�ڃR�[�h = 'ZZZZZZZ'
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--        AND   xsr.BASE_CODE          =  iv_delivery_base_code   -- ���_�R�[�h = �[�i���_�R�[�h
-- del v1.26|        AND   xsr.base_code          =  iv_sales_base_code      -- ���_�R�[�h = ���㋒�_�R�[�h
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date        -- �K�p�J�n���� �[�i��
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;       -- �K�p�I������ �[�i��
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          RAISE global_ship_due_date_expt;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --���^�[���R�[�h
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --���[�U�E�G���[�E���b�Z�[�W
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --�ҏW���ꂽ�L�[���
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|          IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|            RAISE global_select_err_expt;
-- del v1.26|          ELSE
-- del v1.26|            RAISE global_api_expt;
-- del v1.26|          END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --5.�ғ����`�F�b�N
-- del v1.26|    ---------------------------
-- del v1.26|    --�߂�l
-- del v1.26|    ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|                id_date            => id_delivery_date,   -- 1.<�[�i��         >
-- del v1.26|                iv_whse_code       => NULL,               -- 2.<�ۊǑq�ɃR�[�h >
-- del v1.26|                iv_deliver_to_code => iv_delivery_code,   -- 3.<�z����R�[�h   >
-- del v1.26|                in_lead_time       => 0,                  -- 4.<���[�h�^�C��   >
-- del v1.26|                iv_prod_class      => iv_item_class_code, -- 5.<���i�敪�R�[�h >
-- del v1.26|                od_oprtn_day       => ld_get_deta         -- 6.�ғ������t
-- del v1.26|              );
-- del v1.26|    IF (ln_ret != cv_status_normal )THEN
-- del v1.26|      RAISE global_operation_day_err_expt;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
-- del v1.26|    ---------------------------
-- del v1.26|    --���O�C��OU�ؑ�(�c�Ɓː��Y)
-- del v1.26|    ---------------------------
-- del v1.26|    FND_GLOBAL.APPS_INITIALIZE(
-- del v1.26|       user_id         => gn_user_id                 -- ���[�UID
-- del v1.26|      ,resp_id         => gn_prod_resp_id            -- �E��ID
-- del v1.26|      ,resp_appl_id    => gn_prod_resp_appl_id       -- �A�v���P�[�V����ID
-- del v1.26|    );
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --6.�z��LT�擾
-- del v1.26|    ---------------------------
-- del v1.26|    xxwsh_common910_pkg.calc_lead_time(
-- del v1.26|      iv_code_class1                => cv_code_div_from,   -- 1.<'4' �q��>
-- del v1.26|      iv_entering_despatching_code1 => gt_base_code,       -- 2.<.�o�א�ۊǏꏊ >
-- del v1.26|      iv_code_class2                => cv_code_div_to,     -- 3.<'9' �z����>
-- del v1.26|      iv_entering_despatching_code2 => iv_delivery_code,   -- 4.<�z����R�[�h>
-- del v1.26|      iv_prod_class                 => iv_item_class_code, -- 5.<���i�敪�R�[�h>
-- del v1.26|      in_transaction_type_id        => NULL,               -- 6.<???>
-- del v1.26|      id_standard_date              => id_delivery_date,   -- 7.<�[�i��>
-- del v1.26|      ov_retcode                    => lv_retcode,         -- 1.���^�[���R�[�h
-- del v1.26|      ov_errmsg_code                => lv_errbuf,          -- 2.�G���[���b�Z�[�W�R�[�h
-- del v1.26|      ov_errmsg                     => lv_errmsg,          -- 3.�G���[���b�Z�[�W
-- del v1.26|      on_lead_time                  => ln_lead_time,
-- del v1.26|      on_delivery_lt                => ln_delivery_lt
-- del v1.26|    );
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
-- del v1.26|--    IF ( lv_errbuf != cv_status_normal ) THEN
-- del v1.26|    IF ( lv_retcode != cv_status_normal ) THEN
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
-- del v1.26|      RAISE global_delivery_lt_err_expt;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
-- del v1.26|    ---------------------------
-- del v1.26|    --���O�C��OU�ؑ�(���Y�ˉc��)
-- del v1.26|    ---------------------------
-- del v1.26|    FND_GLOBAL.APPS_INITIALIZE(
-- del v1.26|       user_id         => gn_user_id            -- ���[�UID
-- del v1.26|      ,resp_id         => gn_resp_id            -- �E��ID
-- del v1.26|      ,resp_appl_id    => gn_resp_appl_id       -- �A�v���P�[�V����ID
-- del v1.26|    );
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- del v1.26|--
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|   -- �z��LT��0�ł������ꍇ�A�o�ח\��� = �[�i��
-- del v1.26|    IF ( ln_delivery_lt = 0 ) THEN
-- del v1.26|      od_ship_due_date := id_delivery_date;
-- del v1.26|    ELSE
-- del v1.26|      ---------------------------
-- del v1.26|      -- �o�ח\����Z�o�p���t�擾
-- del v1.26|      ---------------------------
-- del v1.26|      ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|        id_date            => id_delivery_date,   -- 1.<�[�i��>
-- del v1.26|        iv_whse_code       => NULL,               -- 2.<�o�א�ۊǏꏊ >
-- del v1.26|        iv_deliver_to_code => iv_delivery_code,   -- 3.<�z����R�[�h>
-- del v1.26|        in_lead_time       => 0,                  -- 4.<�z��LT >
-- del v1.26|        iv_prod_class      => iv_item_class_code, -- 5.<���i�敪�R�[�h >
-- del v1.26|        in_type            => cn_type,             -- 
-- del v1.26|        od_oprtn_day       => ld_work_day        -- 1.<���ғ������t>
-- del v1.26|        );
-- del v1.26|      IF (ln_ret != cv_status_normal )THEN
-- del v1.26|        RAISE global_operation_day_err_expt;
-- del v1.26|      END IF;
-- del v1.26|--
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|      ---------------------------
-- del v1.26|      --7.�o�ח\���
-- del v1.26|      ---------------------------
-- del v1.26|      ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda MOD START ****** --
-- del v1.26|--        id_date            => id_delivery_date,   -- 1.<�[�i��>
-- del v1.26|        id_date            => ld_work_day     ,   -- 1.<�[�i��>
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda MOD  END  ****** --
-- del v1.26|        iv_whse_code       => NULL,               -- 2.<�o�א�ۊǏꏊ >
-- del v1.26|        iv_deliver_to_code => iv_delivery_code,   -- 3.<�z����R�[�h>
-- del v1.26|        in_lead_time       => ln_delivery_lt,     -- 4.<�z��LT >
-- del v1.26|        iv_prod_class      => iv_item_class_code, -- 5.<���i�敪�R�[�h >
-- del v1.26|        od_oprtn_day       => od_ship_due_date    -- 1.<�o�ח\���    >
-- del v1.26|        );
-- del v1.26|      IF (ln_ret != cv_status_normal )THEN
-- del v1.26|        RAISE global_operation_day_err_expt;
-- del v1.26|      END IF;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    END IF;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|  EXCEPTION
-- del v1.26|    --�����\���A�h�I���}�X�^
-- del v1.26|    WHEN global_ship_due_date_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_ship_due_chk_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --�sNo
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^1(�g�[�N��)
-- del v1.26|                      iv_token_value4  => iv_item_no,                                                      --�i�ڃR�[�h
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,                                                   --�p�����[�^2(�g�[�N��)
-- del v1.26|                      iv_token_value5  => iv_delivery_code,                                                --�z���R�[�h
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,                                                   --�p�����[�^3(�g�[�N��)
-- del v1.26|                      iv_token_value6  => TO_CHAR(id_delivery_date,cv_yyyymmdds_format)                    --�[�i��
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --�ғ����`�F�b�N/�o�ח\����n���h���G���[
-- del v1.26|    WHEN global_operation_day_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_ship_func_chk_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --�sNo
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,                                                   --�p�����[�^4(�g�[�N��)
-- del v1.26|                      iv_token_value4  => TO_CHAR(id_delivery_date,cv_yyyymmdds_format),                   --�[�i��
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,                                                   --�p�����[�^5(�g�[�N��)
-- del v1.26|                      iv_token_value5  => gt_base_code,                                                    --�ۊǑq�ɃR�[�h
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,                                                   --�p�����[�^6(�g�[�N��)
-- del v1.26|                      iv_token_value6  => iv_delivery_code,                                                --�z����R�[�h
-- del v1.26|                      iv_token_name7   => cv_tkn_param7,                                                   --�p�����[�^7(�g�[�N��)
-- del v1.26|                      iv_token_value7  => iv_item_class_code,                                              --���i�敪
-- del v1.26|                      iv_token_name8   => cv_tkn_api_name,                                                 --�p�����[�^8(�g�[�N��)
-- del v1.26|                      iv_token_value8  => cv_api_name_makeup_key_info                                      --API
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --�z��TL�擾�n���h���G���[
-- del v1.26|    WHEN global_delivery_lt_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_delivery_tl_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --�p�����[�^1(�g�[�N��)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --�s�ԍ�
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --�p�����[�^2(�g�[�N��)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --�I�[�_�[NO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --�p�����[�^3(�g�[�N��)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --�sNo
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,
-- del v1.26|                      iv_token_value4  => cv_code_div_from,
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,
-- del v1.26|                      iv_token_value5  => gt_base_code,
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,
-- del v1.26|                      iv_token_value6  => cv_code_div_to,
-- del v1.26|                      iv_token_name7   => cv_tkn_param7,
-- del v1.26|                      iv_token_value7  => iv_delivery_code,
-- del v1.26|                      iv_token_name8   => cv_tkn_param8,
-- del v1.26|                      iv_token_value8  => iv_item_class_code,
-- del v1.26|                      iv_token_name9  => cv_tkn_param9,
-- del v1.26|                      iv_token_value9 => TO_CHAR(id_delivery_date,cv_yyyymmdds_format),
-- del v1.26|                      iv_token_name10  => cv_tkn_api_name,
-- del v1.26|                      iv_token_value10 => cv_api_name_calc_lead_time
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --���o�G���[�n���h��
-- del v1.26|    WHEN global_select_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                     iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                     iv_name         => ct_msg_get_data_err,
-- del v1.26|                     iv_token_name1  => cv_tkn_table_name,
-- del v1.26|                     iv_token_value1 => lv_table_info,
-- del v1.26|                     iv_token_name2  => cv_tkn_key_data,
-- del v1.26|                     iv_token_value2 => lv_key_info
-- del v1.26|                  );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|--
-- del v1.26|--#################################  �Œ��O������ START   ####################################
-- del v1.26|--
-- del v1.26|    -- *** ���ʊ֐���O�n���h�� ***
-- del v1.26|    WHEN global_api_expt THEN
-- del v1.26|      ov_errmsg  := lv_errmsg;
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
-- del v1.26|    WHEN global_api_others_expt THEN
-- del v1.26|      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|    -- *** OTHERS��O�n���h�� ***
-- del v1.26|    WHEN OTHERS THEN
-- del v1.26|      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|--
-- del v1.26|--#####################################  �Œ蕔 END   ##########################################
-- del v1.26|--
-- del v1.26|  END get_ship_due_date;
--****************************** 2012/01/06 1.26 Y.Horikawa DEL END*******************************--
--
  /**********************************************************************************
   * Procedure Name   : <security_checke>
   * Description      : <�Z�L�����e�B�`�F�b�N����>(A-8)
   ***********************************************************************************/
  PROCEDURE security_check(
    iv_delivery_base_code IN  VARCHAR2, -- �[�i���_�R�[�h
    iv_customer_code      IN  VARCHAR2, -- �ڋq�R�[�h
    in_line_no            IN  NUMBER,   -- �sNO.(�s�ԍ�)
/* 2009/07/17 Ver1.10 Del Start */
--    in_order_no           IN  NUMBER,   -- �I�[�_NO.
/* 2009/07/17 Ver1.10 Del End   */
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
   * Description      : <�f�[�^�ݒ菈��>(A-9)
   ***********************************************************************************/
  PROCEDURE set_order_data(
    in_cnt                   IN NUMBER,    -- �f�[�^��
-- ************** Ver1.28 ADD START *************** --
    iv_get_format            IN VARCHAR2,  -- �t�H�[�}�b�g�p�^�[��
-- ************** Ver1.28 ADD END   *************** --
    in_order_source_id       IN NUMBER,    -- �󒍃\�[�XID(�C���|�[�g�\�[�XID)
    iv_orig_sys_document_ref IN VARCHAR2,  -- �󒍃\�[�X�Q��(�I�[�_�[NO)
    in_org_id                IN NUMBER,    -- �g�DID(�c�ƒP��)
    id_ordered_date          IN DATE,      -- �󒍓�(������)
    iv_order_type            IN VARCHAR2,  -- �󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    in_salesrep_id           IN NUMBER,    -- �c�ƒS��ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
/* 2009/07/17 Ver1.10 Mod Start */
--    in_customer_po_number    IN NUMBER,    -- �ڋqPO�ԍ�(�ڋq�����ԍ�)(�I�[�_�[No.)
    iv_customer_po_number    IN VARCHAR2,  -- �ڋqPO�ԍ�(�ڋq�����ԍ�)(�I�[�_�[No.)
/* 2009/07/17 Ver1.10 Mod End   */
    iv_customer_number       IN VARCHAR2,  -- �ڋq�ԍ��i�R�[�h)(�ڋq�R�[�h(SEJ)or�[�i��(����))
    id_request_date          IN DATE,      -- �v����(������"���ݒ�K�v")
    iv_orig_sys_line_ref     IN VARCHAR2,  -- �󒍃\�[�X���׎Q��(�sNo.)
    iv_line_type             IN VARCHAR2,  -- ���׃^�C�v(���׃^�C�v(�ʏ�o��)
    iv_inventory_item        IN VARCHAR2,  -- �݌ɕi��(�i�ڃR�[�h(SEJ) or SEJ���i�R�[�h)
    id_schedule_ship_date    IN DATE,      -- �\��o�ד�(�o�ח\���(SEJ)or �o�ד�(����))
    in_ordered_quantity      IN NUMBER,    -- �󒍐���(�����o����(SEJ) or�P�[�X��(����))
    iv_order_quantity_uom    IN VARCHAR2,  -- �󒍐��ʒP��(��P��(SEJ) or �P�[�X�P��)
    iv_customer_line_number  IN VARCHAR2,  -- �ڋq���הԍ�(�sNo.(���ݒ�K�v))
    iv_attribute9            IN VARCHAR2,  -- �t���b�N�X�t�B�[���h9(���ߎ���)
    iv_salse_base_code       IN VARCHAR2,  -- ���㋒�_�R�[�h
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    iv_set_packing_instructions  IN VARCHAR2,  -- �o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    iv_cust_po_number        IN  VARCHAR2, -- �ڋq����No.
    in_unit_price            IN  NUMBER,   -- �P��
    in_category_class        IN  VARCHAR2,   -- ���ދ敪
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    iv_tokushu_item_code     IN  VARCHAR2,   -- ���ꏤ�i�R�[�h
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    iv_invoice_class         IN  VARCHAR2,     -- �`�[�敪
    iv_subinventory          IN  VARCHAR2,     -- �ۊǏꏊ
    iv_sales_class           IN  VARCHAR2,     -- ����敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
    iv_ship_instructions     IN  VARCHAR2,     -- �o�׎w��
-- ************** Ver1.29 ADD END   *************** --
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    lt_attribute8     VARCHAR2(128); -- ���ߎ���
    lv_cust_po_number VARCHAR2(12);  -- �ڋq�����ԍ�
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    lt_line_context   oe_order_lines.context%TYPE;
    lt_sales_class    oe_order_lines.attribute5%TYPE;  -- ����敪(�󒍖���DFF5)
-- ************** Ver1.28 ADD END   *************** --
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
/* 2009/07/17 Ver1.10 Mod Start */
--    IF ( gt_order_no IS NULL ) OR ( gt_order_no != in_customer_po_number ) THEN
    IF ( gt_order_no IS NULL ) OR ( gt_order_no != iv_customer_po_number ) THEN
/* 2009/07/17 Ver1.10 Mod End */
      --�w�b�_��ݒ肵�܂��B
      --�J�E���gUP
      gn_hed_cnt := gn_hed_cnt + 1;
      --�󒍃w�b�_�[OIF
-- ************** Ver1.29 MOD START *************** --
--      gt_order_no := iv_orig_sys_document_ref;
      -- �ϓ��d�C��ȊO�̏ꍇ
      IF ( iv_get_format <> cv_electricity_format ) THEN
        gt_order_no := iv_orig_sys_document_ref;
      END IF;
--
      -- �O���V�X�e���󒍔ԍ���������
      gt_orig_sys_document_ref := NULL;
--
-- ************** Ver1.29 MOD END   *************** --
-- ************** Ver1.28 ADD START *************** --
      -- 1.�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ
      --   �󒍈ꗗ�̏o�͑ΏۂƂȂ�悤orig_sys_document_ref��ݒ�
      IF iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) THEN
          --�V�[�P���X���擾�B
        SELECT xxcos_orig_sys_doc_ref_s01.NEXTVAL seq_no
        INTO ln_seq_no
        FROM dual
        ;
-- ************** Ver1.29 MOD START *************** --
--        gv_seq_no := cv_pre_orig_sys_doc_ref || TO_CHAR((lpad(ln_seq_no,11,0)));
--      --
--      ELSE
        -- �O���V�X�e���󒍔ԍ��ɍ̔Ԃ����l��ݒ�
        gt_orig_sys_document_ref := cv_pre_orig_sys_doc_ref || TO_CHAR((lpad(ln_seq_no,11,0)));
      END IF;
--
      -- 2.�u�≮CSV�v�u����CSV�v�u���{CSV�v�u�L����`��CSV�v�̏ꍇ
      --   �܂��́AA-4�Ŏ擾�����ڋq�����ԍ���NULL�̏ꍇ
      IF ( ( gt_orig_sys_document_ref IS NULL )
        OR ( iv_cust_po_number        IS NULL ) ) THEN
-- ************** Ver1.29 MOD END   *************** --
-- ************** Ver1.28 ADD END   *************** --
          --�V�[�P���X���擾�B
        SELECT xxcos_cust_po_number_s01.NEXTVAL
        INTO ln_seq_no
        FROM DUAL
        ;
        gv_seq_no := 'I' || TO_CHAR((lpad(ln_seq_no,11,0)));
-- ************** Ver1.29 ADD START *************** --
      END IF;
--
      -- 3.�u�≮CSV�v�u����CSV�v�u���{CSV�v�u�L����`��CSV�v�̏ꍇ
      IF ( gt_orig_sys_document_ref IS NULL ) THEN
        gt_orig_sys_document_ref := gv_seq_no;
-- ************** Ver1.29 ADD END   *************** --
-- ************** Ver1.28 ADD START *************** --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
-- *********** 2009/12/16 1.16 N.Maeda DEL START ***********--
--      IF ( iv_attribute9 IS NOT NULL ) THEN
--        lt_attribute8 := iv_attribute9 || cv_00;
--      ELSE
--        lt_attribute8 := NULL;
--      END IF;
-- *********** 2009/12/16 1.16 N.Maeda DEL  END  ***********--
--
      -- 4.�ڋq�����ԍ����ݒ肳��Ă��Ȃ��ꍇ�̓V�[�P���X�擾�����l��ݒ肷��B
      IF ( iv_cust_po_number IS NOT NULL ) THEN
        lv_cust_po_number := iv_cust_po_number;
      ELSE
        lv_cust_po_number := gv_seq_no;
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
      --�ϐ��ɐݒ�
      gr_order_oif_data(gn_hed_cnt).order_source_id           := in_order_source_id;        --�󒍃\�[�XID(�C���|�[�g�\�[�XID)
-- ************** Ver1.29 MOD START *************** --
--      gr_order_oif_data(gn_hed_cnt).orig_sys_document_ref     := gv_seq_no;                 --�󒍃\�[�X�Q��(�V�[�P���X�ݒ�)
      gr_order_oif_data(gn_hed_cnt).orig_sys_document_ref     := gt_orig_sys_document_ref;  --�󒍃\�[�X�Q��(�V�[�P���X�ݒ�)
-- ************** Ver1.29 MOD END   *************** --
      gr_order_oif_data(gn_hed_cnt).org_id                    := in_org_id;                 --�g�DID(�c�ƒP��)
      gr_order_oif_data(gn_hed_cnt).ordered_date              := id_ordered_date;           --�󒍓�(������)
      gr_order_oif_data(gn_hed_cnt).order_type                := iv_order_type;             --�󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
      gr_order_oif_data(gn_hed_cnt).context                   := iv_order_type;             --�󒍃^�C�v(�󒍃^�C�v�i�ʏ�󒍁j)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
      gr_order_oif_data(gn_hed_cnt).salesrep_id               := in_salesrep_id;            --�c�ƒS��ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      gr_order_oif_data(gn_hed_cnt).customer_po_number        := lv_cust_po_number;                 --�ڋqPO�ԍ�(�ڋq�����ԍ�)
--      gr_order_oif_data(gn_hed_cnt).customer_po_number        := gv_seq_no;                 --�ڋqPO�ԍ�(�ڋq�����ԍ�)(�V�[�P���X�ݒ�)
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
      gr_order_oif_data(gn_hed_cnt).customer_number           := iv_customer_number;        --�ڋq�ԍ�(�ڋq�R�[�h(SEJ)or�[�i��(����))
      gr_order_oif_data(gn_hed_cnt).request_date              := id_request_date;           --�v����(������"���ݒ�K�v")
      gr_order_oif_data(gn_hed_cnt).attribute12               := iv_salse_base_code;        --attribute19(���㋒�_)
      gr_order_oif_data(gn_hed_cnt).attribute19               := gt_order_no;               --attribute19(�I�[�_�[No)
-- ************** Ver1.28 ADD START *************** --
      gr_order_oif_data(gn_hed_cnt).attribute5                := iv_invoice_class;          --�`�[�敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
      gr_order_oif_data(gn_hed_cnt).shipping_instructions     := iv_ship_instructions;      --�o�׎w��
-- ************** Ver1.29 ADD END   *************** --
      gr_order_oif_data(gn_hed_cnt).created_by                := cn_created_by;             --�쐬��
      gr_order_oif_data(gn_hed_cnt).creation_date             := cd_creation_date;          --�쐬��
      gr_order_oif_data(gn_hed_cnt).last_updated_by           := cn_last_updated_by;        --�X�V��
      gr_order_oif_data(gn_hed_cnt).last_update_date          := cd_last_update_date;       --�ŏI�X�V��
      gr_order_oif_data(gn_hed_cnt).last_update_login         := cn_last_update_login;      --�ŏI���O�C��
      gr_order_oif_data(gn_hed_cnt).program_application_id    := cn_program_application_id; --�v���O�����A�v���P�[�V����ID
      gr_order_oif_data(gn_hed_cnt).program_id                := cn_program_id;             --�v���O����ID
      gr_order_oif_data(gn_hed_cnt).program_update_date       := cd_program_update_date;    --�v���O�����X�V��
      gr_order_oif_data(gn_hed_cnt).request_id                := NULL;             --���N�G�X�gID
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      gr_order_oif_data(gn_hed_cnt).attribute20               := in_category_class;         -- ���ދ敪
---- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
--      gr_order_oif_data(gn_hed_cnt).attribute5                := in_category_class;         -- ���ދ敪
---- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
-- ************** 2018/01/23 V1.31 Added START    *************** --
      --  �ϓ��d�C��A���A�����Z���^�[�̏ꍇ
      IF  (     iv_get_format = cv_electricity_format
            AND gv_order_up_bis_center = cv_bis_center
          )
      THEN
        --  �󒍏���OIF���쐬�i�󒍂��L���ςƂ���j
        gr_oif_act_data(gn_hed_cnt).order_source_id       :=  in_order_source_id;
        gr_oif_act_data(gn_hed_cnt).orig_sys_document_ref :=  gt_orig_sys_document_ref;
        gr_oif_act_data(gn_hed_cnt).operation_code        :=  cv_book_order;
      END IF;
-- ************** 2018/01/23 V1.31 Added END      *************** --
    END IF;
--
-- *********** 2009/12/16 1.16 N.Maeda ADD START ***********--]
    -- ���ߎ��Ԕ��菈��NULL�ȊO�̏ꍇ'00'��t�����Đݒ�
    -- (�����ߎ��Ԃ͖{��Attribute8�̈וϐ�����ύX)
    IF ( iv_attribute9 IS NOT NULL ) THEN
      lt_attribute8 := iv_attribute9 || cv_00;
    ELSE
      lt_attribute8 := NULL;
    END IF;
-- *********** 2009/12/16 1.16 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    -- ���׃R���e�L�X�g���ݒ�t���O��'Y'�̏ꍇ��NULL��ݒ�
    IF ( gt_line_context_unset_flg = cv_context_unset_y ) THEN
      lt_line_context := NULL;
    ELSE
      lt_line_context := iv_line_type;
    END IF;
--
    -- ����敪�ݒ�t���O��'N'�̏ꍇ��NULL��ݒ�
    IF ( gt_sales_class_must_flg = cv_sales_class_must_n ) THEN
      lt_sales_class := NULL;
    ELSE
      lt_sales_class := iv_sales_class;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
--
    --�󒍖���OIF
    gn_line_cnt := gn_line_cnt + 1;
    gr_order_line_oif_data(gn_line_cnt).order_source_id            := in_order_source_id;        --�󒍃\�[�XID(�C���|�[�g�\�[�XID)
-- ************** Ver1.29 ADD START *************** --
--    gr_order_line_oif_data(gn_line_cnt).orig_sys_document_ref      := gv_seq_no;                 --�󒍃\�[�X�Q��(�V�[�P���XNo
    gr_order_line_oif_data(gn_line_cnt).orig_sys_document_ref      := gt_orig_sys_document_ref;  --�󒍃\�[�X�Q��(�V�[�P���XNo
-- ************** Ver1.29 ADD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).orig_sys_line_ref          := iv_orig_sys_line_ref;      --�󒍃\�[�X���׎Q��(�sNo.)
/* 2011/01/25 1.23 H.Sekine Add Start */
    gr_order_line_oif_data(gn_line_cnt).line_number                := TO_NUMBER(iv_orig_sys_line_ref); --�󒍖��׍s�ԍ�
/* 2011/01/25 1.23 H.Sekine Add End   */
    gr_order_line_oif_data(gn_line_cnt).org_id                     := in_org_id;                 --�g�DID(�c�ƒP��(���K�v))
    gr_order_line_oif_data(gn_line_cnt).line_type                  := iv_line_type;              --���׃^�C�v(���׃^�C�v(�ʏ�o��)
-- ************** Ver1.28 MOD START *************** --
--    gr_order_line_oif_data(gn_line_cnt).context                    := iv_line_type;              --���׃^�C�v(���׃^�C�v(�ʏ�o��)
    gr_order_line_oif_data(gn_line_cnt).context                    := lt_line_context;           --���׃R���e�L�X�g
-- ************** Ver1.28 MOD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).inventory_item             := iv_inventory_item;         --�݌ɕi��(�i�ڃR�[�h(SEJ) or SEJ���i�R�[�h)
    gr_order_line_oif_data(gn_line_cnt).schedule_ship_date         := id_schedule_ship_date;     --�\��o�ד�(�o�ח\���(SEJ)or �o�ד�(����))
    gr_order_line_oif_data(gn_line_cnt).ordered_quantity           := in_ordered_quantity;       --�󒍐���(�����o����(SEJ) or�P�[�X��(����))
    gr_order_line_oif_data(gn_line_cnt).order_quantity_uom         := iv_order_quantity_uom;     --�󒍐��ʒP��(��P��(SEJ) or �P�[�X�P��)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    gr_order_line_oif_data(gn_line_cnt).salesrep_id                := in_salesrep_id;            --�c�ƒS��ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- ************** Ver1.29 MOD START *************** --
--    gr_order_line_oif_data(gn_line_cnt).customer_po_number         := gv_seq_no;                 --�ڋq�����ԍ�(�V�[�P���X)
    gr_order_line_oif_data(gn_line_cnt).customer_po_number         := gt_orig_sys_document_ref;  --�ڋq�����ԍ�(�V�[�P���X�ݒ�)
-- ************** Ver1.29 MOD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).customer_line_number       := iv_customer_line_number;   --�ڋq���הԍ�(�sNo.(���ݒ�K�v))
-- ************** Ver1.28 ADD START *************** --
    gr_order_line_oif_data(gn_line_cnt).attribute5                 := lt_sales_class;            --�t���b�N�X�t�B�[���h5(����敪)
-- ************** Ver1.28 ADD END *************** --
-- *********** 2010/12/03 1.21 H.Sekine ADDD START***********--
    gr_order_line_oif_data(gn_line_cnt).attribute6                 := iv_tokushu_item_code;      --���ꏤ�i�R�[�h(�q�R�[�h)
-- *********** 2010/12/03 1.21 H.Sekine ADDD END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--    gr_order_line_oif_data(gn_line_cnt).attribute8                 := iv_attribute9 || cv_00;     --�t���b�N�X�t�B�[���h9(���ߎ���)
    gr_order_line_oif_data(gn_line_cnt).attribute8                 := lt_attribute8;             --�t���b�N�X�t�B�[���h8(���ߎ���)
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
    gr_order_line_oif_data(gn_line_cnt).request_date               := id_request_date;           --�v����(�[�i��)
-- ************** Ver1.28 ADD START *************** --
    gr_order_line_oif_data(gn_line_cnt).subinventory               := iv_subinventory;           --�ۊǏꏊ
-- ************** Ver1.28 ADD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).created_by                 := cn_created_by;             --�쐬��
    gr_order_line_oif_data(gn_line_cnt).creation_date              := cd_creation_date;          --�쐬��
    gr_order_line_oif_data(gn_line_cnt).last_updated_by            := cn_last_updated_by;        --�X�V��
    gr_order_line_oif_data(gn_line_cnt).last_update_date           := cd_last_update_date;       --�ŏI�X�V��
    gr_order_line_oif_data(gn_line_cnt).last_update_login          := cn_last_update_login;      --�ŏI���O�C��
    gr_order_line_oif_data(gn_line_cnt).program_application_id     := cn_program_application_id; --�v���O�����A�v���P�[�V����ID
    gr_order_line_oif_data(gn_line_cnt).program_id                 := cn_program_id;             --�v���O����ID
    gr_order_line_oif_data(gn_line_cnt).program_update_date        := cd_program_update_date;    --�v���O�����X�V��
    gr_order_line_oif_data(gn_line_cnt).request_id                 := NULL;             --���N�G�X�gID
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    gr_order_line_oif_data(gn_line_cnt).packing_instructions       := iv_set_packing_instructions; --�o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    IF ( in_unit_price IS NOT NULL ) THEN
      gr_order_line_oif_data(gn_line_cnt).unit_list_price            := in_unit_price;             --�P��
      gr_order_line_oif_data(gn_line_cnt).unit_selling_price         := in_unit_price;             --�̔��P��
      gr_order_line_oif_data(gn_line_cnt).calculate_price_flag       := cv_cons_n;                 --���i�v�Z�t���O
    END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    
--
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
   * Description      : <�f�[�^�o�^����>(A-9)
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
-- ************** 2018/01/23 V1.31 Added START    *************** --
    --  �󒍏���OIF�o�^����
    BEGIN
      FORALL ln_i IN 1 .. gr_oif_act_data.COUNT
        INSERT INTO oe_actions_iface_all VALUES gr_oif_act_data(ln_i);
      --�����J�E���g
      gn_line_act_cnt :=  SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name :=  xxccp_common_pkg.get_msg(
                            iv_application  =>  ct_xxcos_appl_short_name
                          , iv_name         =>  ct_msg_get_order_a_oif
                        );
       RAISE global_insert_expt;
    END;
-- ************** 2018/01/23 V1.31 Added END      *************** --
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
   * Description      : <�󒍂̃C���|�[�g�v��>(A-10)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
-- ************** Ver1.28 ADD START *************** --
    iv_get_format IN         VARCHAR2, -- ���̓t�H�[�}�b�g�p�^�[��
-- ************** Ver1.28 ADD END   *************** --
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
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    cv_application            CONSTANT VARCHAR2(5)   := 'ONT';         -- Application
--    cv_program                CONSTANT VARCHAR2(9)   := 'OEOIMP';      -- Program
--    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
--    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
--    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
--    cv_argument4              CONSTANT VARCHAR2(1)   := 'N';           -- Argument1
--    cv_argument5              CONSTANT VARCHAR2(1)   := '1';           -- Argument1
--    cv_argument6              CONSTANT VARCHAR2(1)   := '4';           -- Argument1
--    cv_argument10             CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
--    cv_argument11             CONSTANT VARCHAR2(1)   := 'N';           -- Argument1
--    cv_argument12             CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
--
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
--2012/06/25 Ver.1.27 Mod Start 
--  �󒍃C���|�[�g�G���[���m(CSV�󒍎捞�p�j���Ăяo���悤�ɂɕύX
--    cv_program                CONSTANT VARCHAR2(12)  := 'XXCOS010A06C';  -- Program
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A061C';  -- Program
--2012/06/25 Ver.1.27 Mod End
-- ************** Ver1.28 ADD START *************** --
    cv_program2               CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- �󒍃C���|�[�g�G���[���m(Online�p�j
-- ************** Ver1.28 ADD END   *************** --
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
    -- *** ���[�J���ϐ� ***
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
-- ************** Ver1.28 ADD START *************** --
    lv_program                VARCHAR2(50);
-- ************** Ver1.28 ADD END   *************** --
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
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    ln_request_id := fnd_request.submit_request(
--                       application  => cv_application,
--                       program      => cv_program,
--                       description  => cv_description,
--                       start_time   => cv_start_time,
--                       sub_request  => cb_sub_request,
--                       argument1    => gt_order_source_id,--�󒍃\�[�XID
--                       argument2    => NULL,              --�����V�X�e�������Q��
--                       argument3    => NULL,              --�H���R�[�h
--                       argument4    => cv_argument4,      --���؂̂݁H
--                       argument5    => cv_argument5,      --�f�o�b�O���x��
--                       argument6    => cv_argument6,      --�󒍃C���|�[�g�C���X�^���X��
--                       argument7    => NULL,              --�̔���g�DID
--                       argument8    => NULL,              --�̔���g�D
--                       argument9    => NULL,              --�ύX����
--                       argument10   => cv_argument10,     --�C���X�^���X�̒P�ꖾ�׃L���[�g�p��
--                       argument11   => cv_argument11,     --�㑱�ɑ����u�����N�̃g����
--                       argument12   => cv_argument12      --�t���t���b�N�X�̃t�B�[���h
--                     );
-- ************** Ver1.28 ADD START *************** --
    -- �t�H�[�}�b�g�p�^�[���ʂɎ󒍃C���|�[�g�G���[���m���N��
    -- �u�≮CSV�v�A�u����CSV�v�A�u���{CSV�v�A�u�L����`��CSV�v�̏ꍇ
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      lv_program := cv_program;
    ELSE
      lv_program := cv_program2;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
-- ************** Ver1.28 MOD START *************** --
--                       program      => cv_program,
                       program      => lv_program,
-- ************** Ver1.28 MOD END   *************** --
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => gv_f_description     --�󒍃\�[�X��
                     );
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
--
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    IF ( ln_request_id IS NULL ) THEN
    IF ( ln_request_id = 0 ) THEN
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
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
--****************************** 2009/07/10 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/10 1.7 T.Tominaga MOD END   ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
--
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    IF ( ( lb_wait_result = FALSE ) 
--      OR ( lv_dev_status <> cv_con_status_normal ) )
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) )
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
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
--****************************** 2009/07/15 1.9 T.Miyata ADD START ******************************
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
--****************************** 2009/07/15 1.9 T.Miyata ADD END   ******************************
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
    lv_central_code            VARCHAR2(128); -- �Z���^�[�R�[�h
    lv_jan_code                VARCHAR2(128); -- JAN�R�[�h
    lv_total_time              VARCHAR2(128); -- ���ߎ���
    ld_order_date              DATE;          -- ������
    lod_delivery_date          DATE;          -- �[�i��
    lv_order_number            VARCHAR2(128); -- �I�[�_�[No.
    lv_line_number             VARCHAR2(128); -- �sNo.
    ln_order_roses_quantity    NUMBER;        -- �����o����
    lv_multiple_store_code     VARCHAR2(128); -- �`�F�[���X�R�[�h
    lv_sej_article_code        VARCHAR2(128); -- SEJ���i�R�[�h
    ln_order_cases_quantity    NUMBER;        -- �����P�[�X��
    lv_delivery                VARCHAR2(128); -- �[�i��
    ld_shipping_date           DATE;          -- �o�ד�
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    lv_packing_instructions    VARCHAR2(128); -- �o�׈˗�No.
    lv_set_packing_instructions    VARCHAR2(128); -- �o�׈˗�No.(�ݒ�p)
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    lv_cust_po_number         VARCHAR2(128); -- �ڋq�����ԍ�
    ln_unit_price             NUMBER;        -- �P��
    ln_category_class         VARCHAR2(128);        -- ���ދ敪
-- *********** 2010/12/03 1.21 H.Sekine ADD START************** --
    lv_tokushu_item_code      VARCHAR2(128);           --���ꏤ�i�R�[�h
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    lv_invoice_class           VARCHAR2(128);     -- �`�[�敪
    lv_subinventory            VARCHAR2(128);     -- �ۊǏꏊ
    lv_line_type               VARCHAR2(128);     -- �󒍃^�C�v�i���ׁj�������p
    lv_sales_class             VARCHAR2(128);     -- ����敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
    lv_ship_instructions       VARCHAR2(2000);    -- �o�׎w��
-- ************** Ver1.29 ADD END   *************** --
--
    lv_account_number          VARCHAR2(40);  -- �ڋq�R�[�h
    lv_delivery_code           VARCHAR2(40);  -- �z����R�[�h
    lv_delivery_base_code      VARCHAR2(40);  -- �[�i���_�R�[�h
    lv_salse_base_code         VARCHAR2(40);  -- ���_�R�[�h
    lv_item_no                 VARCHAR2(40);  -- �i�ڃR�[�h
    lv_primary_unit_of_measure VARCHAR2(40);  -- ��P��
    lv_item_class_code         VARCHAR2(40);  -- ���i�敪�R�[�h
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    ln_salesrep_id             NUMBER;        -- �c�ƒS��ID
    lv_employee_number         VARCHAR2(40);  -- �ŏ�ʎ҉c�ƈ��ԍ�
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
    ld_ship_due_date           DATE;          -- �o�ח\���
--
    lv_customer_number         VARCHAR2(128); -- �ڋq�ԍ��i�R�[�h)�[�i��(����))
    lv_inventory_item          VARCHAR2(128); -- �݌ɕi��        SEJ���i�R�[�h)
    ld_schedule_ship_date      DATE;          -- �\��o�ד�      �o�ד�(����))
    ln_ordered_quantity        NUMBER;        -- �󒍐���        �P�[�X��(����))
    lv_order_quantity_uom      VARCHAR2(128); -- �󒍐��ʒP��    �P�[�X�P��)
    lv_ret_status              VARCHAR2(1);   -- ���^�[���E�X�e�[�^�X
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    gv_get_highest_emp_flg := NULL;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
      in_file_id    => in_get_file_id,    -- file_id
      iv_get_format => iv_get_format_pat, -- �t�H�[�}�b�g�p�^�[��
      ov_errbuf     => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      in_file_id  => in_get_file_id,  -- FILE_ID
      ov_errbuf   => lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      iv_get_format => iv_get_format_pat, -- 1.<�t�H�[�}�b�g�p�^�[��>
      in_file_id    => in_get_file_id,    -- 2.<file_id>
      ov_errbuf     => lv_errbuf,         -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,        -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg          -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * order_item_split �󒍏��f�[�^�̍��ڕ�������                (A-4)
    -- --------------------------------------------------------------------
    order_item_split(
      in_cnt            => gn_get_counter_data, -- �f�[�^��
      ov_errbuf         => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode        => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg         => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --������
    gt_order_no := NULL;
    gn_hed_cnt  := 0;
    gn_line_cnt := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- --------------------------------------------------------------------
      -- * item_check       ���ڃ`�F�b�N                                (A-5)
      -- --------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                       -- �f�[�^�J�E���^
        iv_get_format           => iv_get_format_pat,       -- �t�@�C���t�H�[�}�b�g
        ov_central_code         => lv_central_code,         -- �Z���^�[�R�[�h
        ov_jan_code             => lv_jan_code,             -- JAN�R�[�h
        ov_total_time           => lv_total_time,           -- ���ߎ���
        od_order_date           => ld_order_date,           -- ������
        od_delivery_date        => lod_delivery_date,       -- �[�i��
        ov_order_number         => lv_order_number,         -- �I�[�_�[No.
        ov_line_number          => lv_line_number,          -- �sNo.
        on_order_roses_quantity => ln_order_roses_quantity, -- �����o����
        ov_multiple_store_code  => lv_multiple_store_code,  -- �`�F�[���X�R�[�h
        ov_sej_article_code     => lv_sej_article_code,     -- SEJ���i�R�[�h
        on_order_cases_quantity => ln_order_cases_quantity, -- �����P�[�X��
        ov_delivery             => lv_delivery,             -- �[�i��
        od_shipping_date        => ld_shipping_date,        -- �o�ד�
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
        ov_packing_instructions => lv_packing_instructions,  -- �o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
        ov_cust_po_number       => lv_cust_po_number,        -- �ڋq�����ԍ�
        on_unit_price           => ln_unit_price,            -- �P��
        on_category_class       => ln_category_class,        -- ���ދ敪
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
        ov_tokushu_item_code    => lv_tokushu_item_code,   --���ꏤ�i�R�[�h
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
        ov_invoice_class        => lv_invoice_class,        -- �`�[�敪
        ov_subinventory         => lv_subinventory,         -- �ۊǏꏊ
        ov_line_type            => lv_line_type,            -- �󒍃^�C�v�i���ׁj�������p
        ov_sales_class          => lv_sales_class,          -- ����敪
-- ************** Ver1.29 ADD START *************** --
        ov_ship_instructions    => lv_ship_instructions,    -- �o�׎w��
-- ************** Ver1.29 ADD END   *************** --
        ov_errbuf               => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode              => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          in_cnt                     => i,                          -- �f�[�^�J�E���^
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
          iv_get_format              => iv_get_format_pat,          -- �t�H�[�}�b�g
          iv_organization_id         => gn_get_stock_id_ret,        -- �g�DID
          in_line_no                 => lv_line_number,             -- �sNO.
          iv_chain_store_code        => lv_multiple_store_code,     -- �`�F�[���X�R�[�h
          iv_central_code            => lv_central_code,            -- �Z���^�[�R�[�h
          iv_case_jan_code           => lv_jan_code,                -- JAN�R�[�h
          iv_delivery                => lv_delivery,                -- �[�i��
          iv_sej_item_code           => lv_sej_article_code,        -- SEJ���i�R�[�h
          id_order_date              => ld_order_date,              -- ������
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
          id_request_date            => lod_delivery_date,          -- �v����
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
-- ********************* 2010/12/03 1.21 H.Sekine ADD START********************* --
          iv_tokushu_item_code       => lv_tokushu_item_code,       -- ����i�ڃR�[�h
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
-- ************** Ver1.28 ADD START *************** --
          iv_subinventory            => lv_subinventory,            -- �ۊǏꏊ
          iv_line_type               => lv_line_type,               -- �󒍃^�C�v�i���ׁj�������p
          iv_sales_class             => lv_sales_class,             -- ����敪
-- ************** Ver1.28 ADD END   *************** --
          ov_account_number          => lv_account_number,          -- �ڋq�R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--          on_delivery_code           => lv_delivery_code,           -- �z����R�[�h
          ov_delivery_code           => lv_delivery_code,           -- �z����R�[�h
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          ov_delivery_base_code      => lv_delivery_base_code,      -- �[�i���_�R�[�h
          ov_salse_base_code         => lv_salse_base_code,         -- ���_�R�[�h
          ov_item_no                 => lv_item_no,                 -- �i�ڃR�[�h
          on_primary_unit_of_measure => lv_primary_unit_of_measure, -- ��P��
          ov_prod_class_code         => lv_item_class_code,         -- ���i�敪�R�[�h
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          on_salesrep_id             => ln_salesrep_id,             -- �c�ƒS��ID
          ov_employee_number         => lv_employee_number,         -- �ŏ�ʎ҉c�ƈ��ԍ�
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
          ov_errbuf                  => lv_errbuf,                  -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                 => lv_retcode,                 -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                  => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--****************************** 2012/01/06 1.26 Y.Horikawa DEL START*******************************--
-- del v1.26|      IF ( lv_retcode = cv_status_normal ) AND ( iv_get_format_pat = cv_tonya_format ) THEN
-- del v1.26|        -- --------------------------------------------------------------------
-- del v1.26|        -- * get_ship_due_date �o�ח\����̓��o                           (A-7)
-- del v1.26|        -- --------------------------------------------------------------------
-- del v1.26|        get_ship_due_date(
-- del v1.26|          in_cnt                => gn_get_counter_data,   -- �f�[�^��
-- del v1.26|          in_line_no            => lv_line_number,        -- �sNO.
-- del v1.26|          id_delivery_date      => lod_delivery_date,     -- �[�i��
-- del v1.26|          iv_item_no            => lv_item_no,            -- �i�ڃR�[�h
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD START **********--
-- del v1.26|          iv_tokushu_item_code  => lv_tokushu_item_code,  -- ���ꏤ�i�R�[�h
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD END   **********--
-- del v1.26|          iv_delivery_code      => lv_delivery_code,      -- �z����R�[�h
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--          iv_delivery_base_code => lv_delivery_base_code, -- �[�i���_�R�[�h
-- del v1.26|          iv_sales_base_code    => lv_salse_base_code,
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|          iv_item_class_code    => lv_item_class_code,    -- ���i�敪�R�[�h
-- del v1.26|          iv_account_number     => lv_account_number,     -- �ڋq�R�[�h
-- del v1.26|          od_ship_due_date      => ld_ship_due_date,      -- �o�ח\���
-- del v1.26|          ov_errbuf             => lv_errbuf,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
-- del v1.26|          ov_retcode            => lv_retcode, -- 2.���^�[���E�R�[�h             --# �Œ� #
-- del v1.26|          ov_errmsg             => lv_errmsg   -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- del v1.26|        );
-- del v1.26|        IF ( lv_retcode = cv_status_error ) THEN
-- del v1.26|          gn_error_cnt := 1;
-- del v1.26|          RAISE global_process_expt;
-- del v1.26|        ELSIF ( lv_retcode = cv_status_warn ) THEN
-- del v1.26|          gn_error_cnt := gn_error_cnt + 1;
-- del v1.26|          --���[�j���O�ێ�
-- del v1.26|          lv_ret_status := cv_status_warn;
-- del v1.26|          --�����o��
-- del v1.26|          FND_FILE.PUT_LINE(
-- del v1.26|            which => FND_FILE.OUTPUT,
-- del v1.26|            buff  => lv_errmsg
-- del v1.26|          );
-- del v1.26|        END IF;
-- del v1.26|      END IF;
--****************************** 2012/01/06 1.26 Y.Horikawa DEL END*******************************--
--
      -- --------------------------------------------------------------------
      -- * security_check    �Z�L�����e�B�`�F�b�N����                   (A-8)
      -- --------------------------------------------------------------------
-- *********** 2010/12/03 1.21 H.Sekine MOD START ***********--
--      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat = cv_kokusai_format ) THEN
-- ************** Ver1.28 MOD START *************** --
--      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      --�u����CSV�v�A�u���{CSV�v�A�u�L����`��CSV�v�A�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ
      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                                                                       cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
         ) THEN
-- ************** Ver1.28 MOD END *************** --
-- *********** 2010/12/03 1.12 H.Sekine MOD START ***********--
        security_check(
          iv_delivery_base_code => lv_delivery_base_code,   -- �[�i���_�R�[�h
          iv_customer_code      => lv_account_number,       -- �ڋq�R�[�h
          in_line_no            => lv_line_number,          -- �sNO.(�s�ԍ�)
/* 2009/07/17 Ver1.10 Del Start */
--          in_order_no           => lv_order_number,         -- �I�[�_NO.
/* 2009/07/17 Ver1.10 Del End   */
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
      --
      END IF;
--
      -- --------------------------------------------------------------------
      -- * set_order_data    �f�[�^�ݒ菈��                             (A-9)
      -- --------------------------------------------------------------------
      IF ( lv_ret_status = cv_status_normal ) THEN
        -- 1.�≮CSV
        IF ( iv_get_format_pat = cv_tonya_format )THEN
            lv_customer_number       := lv_account_number;          -- 9.<�ڋq�ԍ��i�R�[�h) (�ڋq�R�[�h(SEJ))>
            lv_inventory_item        := lv_item_no;                 -- 13.<�݌ɕi��         (�i�ڃR�[�h(SEJ))>
--****************************** 2012/01/06 1.26 Y.Horikawa MOD START*******************************--
---- ********************* 2010/01/12 1.18 M.Uehara MOD START ********************* --
----            ld_schedule_ship_date    := ld_ship_due_date;           -- 14.<�\��o�ד�       (�o�ח\���(SEJ))>
--            -- �o�ד������͂���Ă���ꍇ�͏o�ד��A�o�ד���null�̏ꍇ�͏o�ח\������Z�b�g
--            ld_schedule_ship_date    := NVL( ld_shipping_date , ld_ship_due_date);  -- 14.<�\��o�ד�       (�o�ח\���(SEJ))>
---- ********************* 2010/01/12 1.18 M.Uehara MOD END   ********************* --
            ld_schedule_ship_date    := NULL;  -- 14.<�\��o�ד�       (�o�ח\���(SEJ))>
--****************************** 2012/01/06 1.26 Y.Horikawa MOD END*******************************--
            ln_ordered_quantity      := ln_order_roses_quantity;    -- 15.<�󒍐���         (�����o����(SEJ)>
            lv_order_quantity_uom    := lv_primary_unit_of_measure; -- 16.<�󒍐��ʒP��     (��P��(SEJ))>
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
            lv_set_packing_instructions  := NULL;                   -- �o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
        -- 2.����CSV
-- ********************* 2010/12/03 1.21 H.Sekine MOD START********************* --
--        ELSIF ( iv_get_format_pat = cv_kokusai_format ) THEN
-- ************** Ver1.28 MOD START *************** --
--        ELSIF ( iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
        -- �u����CSV�v�A�u���{CSV�v�A�u�L����`��CSV�v�A�u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�̏ꍇ
        ELSIF ( iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                                       cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
              ) THEN
-- ************** Ver1.28 MOD END   *************** --
-- ********************* 2010/12/03 1.21 H.Sekine MOD  END ********************* --
            lv_customer_number       := lv_delivery;             -- 9.<�ڋq�ԍ��i�R�[�h)�[�i��(����))
            lv_inventory_item        := lv_sej_article_code;     -- 13.<�݌ɕi��        SEJ���i�R�[�h)
            ld_schedule_ship_date    := ld_shipping_date;        -- 14.<�\��o�ד�      �o�ד�(����))
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--            ln_ordered_quantity      := ln_order_cases_quantity; -- 15.<�󒍐���        �P�[�X��(����))
--            lv_order_quantity_uom    := gv_case_uom;             -- 16.<�󒍐��ʒP��    �P�[�X�P��)
            -- �������ʃo���Ɣ������ʃP�[�X���ݒ肳��Ă���ꍇ
            IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) THEN
              -- �P�ʐݒ�
              lv_order_quantity_uom    := lv_primary_unit_of_measure;
            ELSE
                lv_order_quantity_uom    := gv_case_uom;
            END IF;
            --
            IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) AND ( NVL( ln_order_cases_quantity , 0 ) <> 0 ) THEN
              -- 
              ln_ordered_quantity      := ( ln_order_cases_quantity * TO_NUMBER( gt_case_num ) ) + ln_order_roses_quantity;
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
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
            lv_set_packing_instructions  := lv_packing_instructions;  -- �o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
        END IF;
-- ************** Ver1.28 ADD START *************** --
        ----------------------------------
        -- �u�ʏ����CSV�v�A�u�ԕi����CSV�v�A�u�ԕiCSV�v�A�u�ϓ��d�C��CSV�v�ȊO�͒ǉ����ڂɐݒ肵�Ȃ�
        ----------------------------------
        IF ( iv_get_format_pat NOT IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
           ) THEN
           lv_invoice_class := NULL;
           lv_subinventory  := NULL;
        END IF;
-- ************** Ver1.28 ADD END   *************** --
        --
        set_order_data(
          in_cnt                   => gn_get_counter_data,     -- �f�[�^��
-- ************** Ver1.28 ADD START *************** --
          iv_get_format            => iv_get_format_pat,       -- �t�H�[�}�b�g
-- ************** Ver1.28 ADD END   *************** --
          in_order_source_id       => gt_order_source_id,      -- �󒍃\�[�XID(�C���|�[�g�\�[�XID
          iv_orig_sys_document_ref => lv_order_number,         -- �󒍃\�[�X�Q��(�I�[�_�[NO
          in_org_id                => gn_org_id,               -- �g�DID(�c�ƒP��
          id_ordered_date          => ld_order_date,           -- �󒍓�(������
          iv_order_type            => gt_order_type_name,      -- �󒍃^�C�v(�󒍃^�C�v(�ʏ��)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          in_salesrep_id           => ln_salesrep_id,          -- �S���c��ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
/* 2009/07/17 Ver1.10 Mod Start */
--          in_customer_po_number    => lv_order_number,         -- �ڋqPO�ԍ�(�ڋq�����ԍ�)(�I�[�_�[No.
          iv_customer_po_number    => lv_order_number,         -- �ڋqPO�ԍ�(�ڋq�����ԍ�)(�I�[�_�[No.
/* 2009/07/17 Ver1.10 Mod End   */
          iv_customer_number       => lv_customer_number,      -- �ڋq�ԍ��i�R�[�h)(�ڋq�R�[�h(SEJ)or �[�i��(����)
          id_request_date          => lod_delivery_date,       -- �v����(�[�i��"���ݒ�K�v"
          iv_orig_sys_line_ref     => lv_line_number,          -- �󒍃\�[�X���׎Q��(�sNo.
          iv_line_type             => gt_order_line_type_name, -- ���׃^�C�v(���׃^�C�v(�ʏ�o��
          iv_inventory_item        => lv_inventory_item ,      -- �݌ɕi��(�i�ڃR�[�h(SEJ) or SEJ���i�R�[�h
          id_schedule_ship_date    => ld_schedule_ship_date,   -- �\��o�ד�(�o�ח\���(SEJ)or �o�ד�(����)
          in_ordered_quantity      => ln_ordered_quantity,     -- �󒍐���(�����o����(SEJ) or�P�[�X��(����)
          iv_order_quantity_uom    => lv_order_quantity_uom,   -- �󒍐��ʒP��(��P��(SEJ) or �P�[�X�P��
          iv_customer_line_number  => lv_line_number,          -- �ڋq���הԍ�(�sNo.(���ݒ�K�v)>
          iv_attribute9            => lv_total_time,           -- �t���b�N�X�t�B�[���h9(���ߎ���>
          iv_salse_base_code       => lv_salse_base_code,      -- ���㋒�_
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
          iv_set_packing_instructions  => lv_set_packing_instructions,  -- �o�׈˗�No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
          iv_cust_po_number       => lv_cust_po_number,        -- �ڋq�����ԍ�
          in_unit_price           => ln_unit_price,            -- �P��
          in_category_class       => ln_category_class,        -- ���ދ敪
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
          iv_tokushu_item_code    => lv_tokushu_item_code,     -- ���ꏤ�i�R�[�h
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
          iv_invoice_class         => lv_invoice_class,        -- �`�[�敪
          iv_subinventory          => lv_subinventory,         -- �ۊǏꏊ
          iv_sales_class           => lv_sales_class,          -- ����敪
-- ************** Ver1.28 ADD END   *************** --
-- ************** Ver1.29 ADD START *************** --
          iv_ship_instructions     => lv_ship_instructions,    -- �o�׎w��
-- ************** Ver1.29 ADD END   *************** --
          ov_errbuf                => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP;
--
    -- --------------------------------------------------------------------
    -- * data_insert       �f�[�^�o�^����(�G���[�̔���)               (A-9)
    -- --------------------------------------------------------------------
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * data_insert       �f�[�^�o�^����                             (A-9)
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
      -- * call_imp_data       �󒍂̃C���|�[�g�v��                    (A-10)
      -- --------------------------------------------------------------------
      call_imp_data(
-- ************** Ver1.28 ADD START *************** --
        iv_get_format => iv_get_format_pat, -- �t�H�[�}�b�g
-- ************** Ver1.28 ADD END   *************** --
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
--****************************** 2009/07/15 1.9 T.Miyata ADD START ******************************
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
--****************************** 2009/07/15 1.9 T.Miyata ADD END   ******************************
      END IF;
    END IF;
--
    --���[�v��̃G���[�X�e�[�^�X���m�[�}���o�Ȃ��ꍇ(���[�j���O)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
    END IF;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    --�ŏ�ʎҏ]�ƈ��ԍ��擾�t���O��'Y'�ł���ꍇ
    IF ( gv_get_highest_emp_flg = 'Y' ) THEN
      ov_retcode := cv_status_warn;
    END IF;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
--    --�G���[�o��
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --�G���[���b�Z�[�W
--      );
--    END IF;
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
/*  �s�K�v
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
*/
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
END XXCOS005A08C;
/
