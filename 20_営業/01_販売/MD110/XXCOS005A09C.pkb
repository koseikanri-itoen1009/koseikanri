CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A09C (body)
 * Description      : CSV�t�@�C���̃f�[�^�A�b�v���[�h
 * MD.050           : CSV�t�@�C���̃f�[�^�A�b�v���[�h MD050_COS_005_A09
 * Version          : 2.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_out               ��������                                    (A-0)
 *  get_ci_data            �t�@�C���A�b�v���[�hIF�ڋq�i�ڃf�[�^�̎擾  (A-1)
 *  init                   ��������                                    (A-2)
 *  cust_item_split        �ڋq�i�ڃf�[�^�̍��ڕ�������                (A-3)
 *  item_check             ���ڃ`�F�b�N                                (A-4)
 *  get_master_data        �}�X�^���̎擾����                        (A-5)
 *  data_check             ������o�^�ς݃f�[�^�`�F�b�N����          (A-6)
 *  set_ci_data            �f�[�^�ݒ菈��                              (A-7)
 *  data_insert            �f�[�^�o�^����                              (A-8)
 *  mtl_customer_items_ins �ڋq�i�ڃ}�X�^�̓o�^����                    (A-9)
 *  mtl_customer_items_xrefs_ins �ڋq�i�ڑ��ݎQ�ƃ}�X�^�̓o�^����      (A-10)
 * ---------------------- ----------------------------------------------------------
 *  submain                �T�u���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   T.Miyashita      �V�K�쐬
 *  2009/2/3      1.1   K.Atsushiba      COS_002�Ή� ���ڃ`�F�b�N�Ōڋq�i�ړE�v�A�����P�ʁA�o�׌��ۊǏꏊ��K�{����
 *                                                   �C�ӂɕύX�B
 *                                       COS_006�Ή� �����P�ʂ�NULL�̏ꍇ�A�u�{�v��ݒ�B
 *                                       COS_007�Ή� �ۊǏꏊ��NULL�̏ꍇ�A�}�X�^���݃`�F�b�N�����Ȃ��悤�ɏC���B
 *  2009/2/17     1.4   T.Miyashita      get_msg�̃p�b�P�[�W���C��
 *  2009/2/20     1.5   T.Miyashita      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/07/01    1.7   T.Tominaga       [0000137]Interval,Max_wait��FND_PROFILE���擾
 *  2009/09/10    1.8   N.Maeda          [0001326]�ڋq�i�ڑ��ݎQ�Əd���`�F�b�N�̏C��
 *  2010/01/07    1.9   M.Sano           [E_�{�ғ�_00739]�w��ڋq�ȊO�ŕۊǏꏊ��ݒ莞�̓G���[�ɂ���悤�ɏC���B
 *                                       [E_�{�ғ�_00740]�q�i�ڃR�[�h��ݒ莞�̓G���[�ɂ���悤�ɏC���B
 *                                                       �i�ڃX�e�[�^�X��20,30,40�ȊO�̕i�ڂ̓G���[�ɂ���悤�ɏC���B
 *  2010/02/12    2.0   T.Nakano         [E_�{�ғ�_01155]�P�ʕs���G���[�ǉ��C��
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
  gn_normal_cnt1   NUMBER;                    -- ���팏��(�ڋq�i�ڃ}�X�^)
  gn_normal_cnt2   NUMBER;                    -- ���팏��(�ڋq�i�ڑ��ݎQ�ƃ}�X�^)
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  global_get_profile_expt        EXCEPTION;  --�v���t�@�C���擾��O�n���h��
  global_get_stock_org_id_expt   EXCEPTION;  --�݌ɑg�DID�̎擾�O�n���h��
  global_get_file_id_data_expt   EXCEPTION;  --�t�@�C��ID�̎擾�n���h��
  global_get_f_uplod_name_expt   EXCEPTION;  --�t�@�C���A�b�v���[�h���̂̎擾�n���h��
  global_get_f_csv_name_expt     EXCEPTION;  --CSV�t�@�C�����̎擾�n���h��
  global_get_cust_item_data_expt EXCEPTION;  --�ڋq�i�ڃf�[�^�擾�n���h��
  global_cut_order_data_expt     EXCEPTION;  --�t�@�C�����R�[�h���ڐ��s��v�n���h��
  global_item_check_expt         EXCEPTION;  --���ڃ`�F�b�N�n���h��
  global_del_order_data_expt     EXCEPTION;  --�f�[�^�폜
  global_insert_expt             EXCEPTION;  --�o�^�G���[
  global_proc_date_err_expt      EXCEPTION;  --�Ɩ����t�G���[
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS005A09C';      -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                          := 'XXCOS';                           --�̕��Z�k�A�v����
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                          := 'XXCCP';                           --����
  --�v���t�@�C��
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'ORG_ID';                          --�c�ƒP��
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOI1_ORGANIZATION_CODE';        --�݌ɑg�D�R�[�h
  ct_ci_commodity_code           CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_CI_COMMODITY_CODE';        --���i�R�[�h
  ct_customer_item_period        CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_CUSTOMER_ITEM_PERIOD';     --�ڋq�i�ڕۑ�����
  ct_hon_uom_code                CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_HON_UOM_CODE';             -- �{�P�ʃR�[�h
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  ct_prof_interval               CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_INTERVAL';                 --�ҋ@�Ԋu
  ct_prof_max_wait               CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_MAX_WAIT';                 --�ő�ҋ@����
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
  --�N�C�b�N�R�[�h�^�C�v
  ct_lookup_type_cus_class       CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUS_CLASS_MST_005_A09';    --�ڋq�敪����}�X�^
  ct_lookup_type_cus_status      CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUS_STATUS_MST_005_A09';   --�ڋq�X�e�[�^�X����}�X�^
  ct_lookup_type_edi_item        CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_EDI_ITEM_MST_005_A09';     --EDI�A�g�i�ڃR�[�h����}�X�^
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_lookup_type_item_chain      CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUST_ITEM_CHAIN_CODE';     --�ڋq�i�ڑΏۃ`�F�[���X�R�[�h
  ct_lookup_type_item_status     CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUST_ITEM_ITEM_STATUS';    --�ڋq�i�ڑΏەi�ڃX�e�[�^�X
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
  ct_file_up_load_name           CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCCP1_FILE_UPLOAD_OBJ';          --�t�@�C���A�b�v���[�h���}�X�^
  --�N�C�b�N�R�[�h
  ct_lookup_code_cus_class       CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --�ڋq�敪����}�X�^�p
  ct_lookup_code_cus_status      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --�ڋq�X�e�[�^�X����}�X�^�p
  ct_lookup_code_edi_item        CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --EDI�A�g�i�ڃR�[�h����}�X�^�p
  --������
  cv_str_file_id                 CONSTANT VARCHAR2(128)
                                          := 'FILE_ID ';                        --FILE_ID
--
  cv_c_kanma                     CONSTANT VARCHAR2(1) := ',';                   --�J���}
  cn_c_header                    CONSTANT NUMBER      := 6;                     --���ڐ�
  --���ڑ���
  cv_item_attribute_var          CONSTANT VARCHAR2(1) := '0';                   --VARCHAR2
  cv_item_attribute_num          CONSTANT VARCHAR2(1) := '1';                   --NUMBER
  cv_item_attribute_date         CONSTANT VARCHAR2(1) := '2';                   --DATE
  cv_line_feed                   CONSTANT VARCHAR2(1) := CHR(10);               --���s�R�[�h
--
  cn_item_header                 CONSTANT NUMBER      := 1;                     --���ږ�
  cn_cust_code                   CONSTANT NUMBER      := 1;                     --�ڋq�R�[�h
  cn_cust_item_code              CONSTANT NUMBER      := 2;                     --�ڋq�i��
  cn_cust_item_summary           CONSTANT NUMBER      := 3;                     --�ڋq�i�ړE�v
  cn_ordering_unit               CONSTANT NUMBER      := 4;                     --�����P��
  cn_item_code                   CONSTANT NUMBER      := 5;                     --�i�ڃR�[�h
  cn_ship_from_space             CONSTANT NUMBER      := 6;                     --�o�׌��ۊǏꏊ
--
  cn_cust_code_dlength           CONSTANT NUMBER      := 9;                     --�ڋq�R�[�h
  cn_cust_item_code_dlength      CONSTANT NUMBER      := 50;                    --�ڋq�i��
  cn_cust_item_summary_dlength   CONSTANT NUMBER      := 240;                   --�ڋq�i�ړE�v
  cn_ordering_unit_dlength       CONSTANT NUMBER      := 3;                     --�����P��
  cn_item_code_dlength           CONSTANT NUMBER      := 7;                     --�i�ڃR�[�h
  cn_ship_from_space_dlength     CONSTANT NUMBER      := 7;                     --�o�׌��ۊǏꏊ
--
  cv_enabled_flag_y              CONSTANT VARCHAR2(2)  := 'Y';                  --�L���t���O
  cv_exists_flag_yes             CONSTANT VARCHAR2(1)  := 'Y';                  --���݃t���O(����j
  cv_exists_flag_no              CONSTANT VARCHAR2(1)  := 'N';                  --���݃t���O(�Ȃ��j
  cv_dummy_data_1                CONSTANT VARCHAR2(1)  := '1';                  --�_�~�[�f�[�^
  cv_dummy_data_2                CONSTANT VARCHAR2(1)  := '2';                  --�_�~�[�f�[�^
  cn_dummy_data_1                CONSTANT NUMBER       := 1;                    --�_�~�[�f�[�^
  cv_character_create            CONSTANT VARCHAR2(10) := 'CREATE';
  cv_character_n                 CONSTANT VARCHAR2(10) := 'N';
  cn_min_2                       CONSTANT NUMBER       := 2;
  cv_character_3                 CONSTANT VARCHAR2(1)  := '3';
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE
                                                       := USERENV('LANG');      --����R�[�h
  ct_inactive_ind_1              CONSTANT VARCHAR2(1)  := '1';                  --�����t���O
--
  cv_customer_class_code_18      CONSTANT VARCHAR2(2)  := '18';                 --�ڋq�敪:18(EDI�`�F�[���X)
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
--
--****************************** 2009/07/01 1.7 T.Tominaga DEL START ******************************
--  cn_interval                    CONSTANT NUMBER       := 15;                   -- Interval
--  cn_max_wait                    CONSTANT NUMBER       := 0;                    -- Max_wait
--****************************** 2009/07/01 1.7 T.Tominaga DEL END   ******************************
--
  cv_format                      CONSTANT VARCHAR2(10) := 'FM00000';            -- �o��
--
  cv_con_status_normal           CONSTANT VARCHAR2(10) := 'NORMAL';             -- �X�e�[�^�X�i����j
--
  --���b�Z�[�W
  ct_msg_get_profile_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00004'; --�E�v���t�@�C���擾�G���[
  ct_msg_get_api_call_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00017'; --�EAPI�ďo�G���[���b�Z�[�W
  ct_msg_get_master_chk_err      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11256'; --�E�}�X�^�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_lock_err            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00001'; --�E���b�N�G���[
  ct_msg_get_inv_org_code        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00048'; --�EXXCOI:�݌ɑg�D�R�[�h
  ct_msg_get_inv_org_id          CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00063'; --�E�݌ɑg�DID
  ct_msg_get_ci_commodity        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00124'; --�EXXCOS:�ڋq�i�ڏ��i�R�[�h(���b�Z�[�W������)
  ct_msg_get_cust_item_period    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00125'; --�EXXCOS:�ڋq�i�ڃf�[�^�ێ�����(���b�Z�[�W������)
  ct_msg_get_rep_h1              CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11289'; --�E�t�@�C��ID : [ PARAM1 ] �t�H�[�}�b�g�p�[�^�� : [ PARAM2 ]
  ct_msg_get_rep_h2              CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11290'; --�E�t�@�C���A�b�v���[�h : [ PARAM3 ]  CSV�t�@�C�� : [ PARAM4 ]
  ct_msg_get_f_uplod_name        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11293'; --[ KEY_DATA ] �t�@�C���A�b�v���[�h���̂̎擾�Ɏ��s���܂����B
  ct_msg_get_f_csv_name          CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11294'; --[ KEY_DATA ] CSV�t�@�C���̎擾�Ɏ��s���܂����B
  ct_msg_get_data_err            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00013'; --�E�f�[�^���o�G���[���b�Z�[�W
  ct_msg_chk_rec_err             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11295'; --�E�t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  ct_msg_get_format_err2         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11302'; --�E�}�X�^�`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_format_err3         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11303'; --�E���ڃt�H�[�}�b�g�G���[���b�Z�[�W
  ct_msg_get_csvitem_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00140'; --�E���ڃG���[���b�Z�[�W
  ct_msg_get_item_chk_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11253'; --�E�i�ڃ}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  ct_msg_get_item_code           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11265'; --�E�i�ڃR�[�h(���b�Z�[�W������)
  ct_msg_get_customer_code       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11278'; --�E�ڋq�R�[�h
  ct_msg_insert_data_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00010'; --�E�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00012'; --�E�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_get_file_up_load        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11282'; --�t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  ct_msg_get_item_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00050'; --�i�ڃ}�X�^
  ct_msg_get_units_of_measr_mstr CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00136'; --�P�ʃ}�X�^
  ct_msg_get_keydata             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11304'; --KEY_DATA
  ct_msg_get_mst_rec_exists_err  CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11322'; --�}�X�^���R�[�h���݃G���[
  ct_msg_get_mci_mstr            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11311'; --�ڋq�i�ڃ}�X�^
  ct_msg_get_mcix_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11312'; --�ڋq�i�ڑ��ݎQ�ƃ}�X�^
  ct_msg_get_mcioif_mstr         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11313'; --�ڋq�i��OIF
  ct_msg_get_mcixoif_mstr        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11314'; --�ڋq�i�ڑ��ݎQ��OIF
  ct_msg_get_fuif_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11315'; --�t�@�C���A�b�v���[�hIF
  ct_msg_get_zaiko_org_para      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-13561'; --�݌ɑg�D�p�����[�^
  ct_msg_get_zaiko_org_code      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10048'; --�݌ɑg�D�R�[�h
  ct_msg_process_date_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00014'; --�Ɩ����t�擾�G���[
  ct_msg_get_comdt_codes         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00127'; --�ڋq�i�ڏ��i�R�[�h�}�X�^
  ct_msg_get_quick_cust_kbn      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00074'; --�Ώیڋq�敪
  ct_msg_get_quick_cust_status   CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-13508'; --�Ώیڋq�X�e�[�^�X
  ct_msg_get_quick_edi_item_kbn  CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00146'; --�ΏۊOEDI�A�g�i�ڃR�[�h�敪
  ct_msg_get_cust_class_code_err CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11308'; --�ڋq�敪�G���[
  ct_msg_get_cust_mst_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00049'; --�ڋq�}�X�^�G���[
  ct_msg_get_duns_number_err     CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11309'; --�ڋq�X�e�[�^�X�G���[
  ct_msg_get_edi_item_cd_div_err CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11310'; --EDI�A�g�i�ڃR�[�h�敪�G���[
  ct_msg_get_ordering_unit       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11316'; --�����敪
  ct_msg_get_sec_inv_name        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11317'; --�o�׌��ۊǏꏊ
  ct_msg_get_sec_inv_mstr        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00052'; --�ۊǏꏊ�}�X�^
  ct_msg_get_con_invciint_err    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11301'; --�R���J�����g�G���[���b�Z�[�W(�ڋq�i�ڃ}�X�^)
  ct_msg_get_con_invciintx_err   CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11318'; --�R���J�����g�G���[���b�Z�[�W(�ڋq�i�ڑ��ݎQ�ƃ}�X�^)
  ct_msg_get_commodity_err       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11319'; --�ڋq�i�ڏ��i�R�[�h
  ct_msg_get_org_code            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-12884'; --�݌ɑg�D�R�[�h
  ct_msg_get_hon_uom             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11323'; --�EXXCOS:�{�P�ʃR�[�h(���b�Z�[�W������)
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  ct_msg_get_interval            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11325'; --XXCOS:�ҋ@�Ԋu
  ct_msg_get_max_wait            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11326'; --XXCOS:�ő�ҋ@����
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_msg_child_item_code_err     CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11328'; --�q�i�ڃG���[
  ct_msg_ship_from_subinv_err    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11329'; --�ۊǏꏊ�ݒ�s�G���[
  ct_msg_item_status_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11330'; --�i�ڃX�e�[�^�X�G���[
--*********** 2010/01/07 1.9 M.Sano ADD END   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
  ct_msg_item_uom_code_err       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11331'; --�P�ʕs���G���[
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
  --
  --�g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            --�E�v���t�@�C����
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              --�E�e�[�u����
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           --�E�L�[���e���R�����g
  cv_tkn_api_name                CONSTANT VARCHAR2(512) := 'API_NAME';           --�E���ʊ֐���
  cv_tkn_column                  CONSTANT VARCHAR2(512) := 'COLUMN';             --�E���ږ�
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          --�E�i�ڃR�[�h
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         --�E�e�[�u����
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            --�E�s�ԍ�
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            --�E�G���[���b�Z�[�W
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               --�E���R�[�h�f�[�^
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             --�E�p�����[�^
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             --�E�p�����[�^
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             --�E�p�����[�^
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             --�E�p�����[�^
  cv_tkn_ordered_uom_code        CONSTANT VARCHAR2(512) := 'ORDERED_UOM_CODE';   --�E�����P��
  cv_tkn_ship_from_subinv        CONSTANT VARCHAR2(512) := 'SHIP_FROM_SUBINV';   --�E�o�׌��ۊǏꏊ
--
  cv_tkn_cust_code               CONSTANT VARCHAR2(512) := 'CUST_CODE';          --�E�ڋq�R�[�h
  cv_tkn_cust_item_code          CONSTANT VARCHAR2(512) := 'CUST_ITEM_CODE';     --�E�ڋq�i��ID
  cv_tkn_commodity_code          CONSTANT VARCHAR2(512) := 'COMMODITY_CODE';     --�E�ڋq�i�ڏ��i�R�[�h
  cv_tkn_request_id              CONSTANT VARCHAR2(512) := 'REQUEST_ID';         --�E�v��ID
  cv_tkn_dev_status              CONSTANT VARCHAR2(512) := 'STATUS';             --�E�X�e�[�^�X
  cv_tkn_message                 CONSTANT VARCHAR2(512) := 'MESSAGE';            --�E���b�Z�[�W
  cv_tkn_org_code                CONSTANT VARCHAR2(512) := 'ORG_CODE';           --�E�݌ɑg�D�R�[�h
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  cv_tkn_parent_item_code        CONSTANT VARCHAR2(512) := 'PARENT_ITEM_CODE';   --�E�e�i�ڃR�[�h
  cv_tkn_item_status             CONSTANT VARCHAR2(512) := 'ITEM_STATUS';        --�E�i�ڃX�e�[�^�X
  cv_tkn_edi_chain_code          CONSTANT VARCHAR2(512) := 'EDI_CHAIN_CODE';     --�EEDI�`�F�[���X�R�[�h
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  TYPE g_ci_interface_ttype       IS TABLE OF mtl_ci_interface%ROWTYPE INDEX BY PLS_INTEGER;       --�ڋq�i��OIF
  TYPE g_ci_xrefs_interface_ttype IS TABLE OF mtl_ci_xrefs_interface%ROWTYPE INDEX BY PLS_INTEGER; --�ڋq�i�ڑ��ݎQ��OIF
--
  TYPE g_sts_ttype IS TABLE OF VARCHAR(1) INDEX BY VARCHAR2(80);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date                 DATE;                                               --�Ɩ����t
  gt_file_id                      xxccp_mrp_file_ul_interface.file_id%TYPE;           --�t�@�C��ID
  gt_last_updated_by1             xxccp_mrp_file_ul_interface.last_updated_by%TYPE;   --�ŏI�X�V��
  gt_last_update_date             xxccp_mrp_file_ul_interface.last_update_date%TYPE;  --�ŏI�X�V��
  gv_inv_org_code                 VARCHAR2(128);                                      --�݌ɑg�D�R�[�h
  gn_get_stock_id_ret             NUMBER;                                             --�݌ɑg�DID
  gv_ci_commodity                 VARCHAR2(128);                                      --�ڋq�i�ڏ��i�R�[�h
  gv_lookup_type                  VARCHAR2(128);                                      --�t�@�C���A�b�v���[�h���̊֘A
  gn_lookup_code                  NUMBER;                                             --�t�@�C���A�b�v���[�h���̊֘A
  gv_meaning                      VARCHAR2(128);                                      --�t�@�C���A�b�v���[�h���̊֘A
  gv_description                  VARCHAR2(128);                                      --�t�@�C���A�b�v���[�h���̊֘A
  gv_f_master_organization_id     VARCHAR2(128);                                      --�}�X�^�݌ɑg�DID
  gv_csv_file_name                VARCHAR2(128);                                      --CSV�t�@�C������
  gn_get_counter_data             NUMBER;                                             --�f�[�^��
  gn_customer_item_period         NUMBER;                                             --�ڋq�i�ڃf�[�^�ێ�����
  gv_hon_uom_code                 VARCHAR2(128);                                      --�{�P�ʃR�[�h
  --
  gt_commodity_code_id            mtl_commodity_codes.commodity_code_id%TYPE;         --���i�R�[�hID
  gt_file_name                    xxccp_mrp_file_ul_interface.file_name%TYPE;         --�t�@�C����
  gt_created_by                   xxccp_mrp_file_ul_interface.created_by%TYPE;        --�쐬��
  gt_creation_date                xxccp_mrp_file_ul_interface.creation_date%TYPE;     --�쐬��
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  gn_interval                     NUMBER;                                             --�ҋ@�Ԋu
  gn_max_wait                     NUMBER;                                             --�ő�ҋ@����
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--
  -- �ڋq�i�ڃf�[�^ BLOB�^
  g_trans_cust_item_tab           xxccp_common_pkg2.g_file_data_tbl;
  g_cust_item_work_tab            g_var2_ttype;
  g_ci_interface_tab              g_ci_interface_ttype;
  g_ci_xrefs_interface_tab        g_ci_xrefs_interface_ttype;
  g_sts_tab1                      g_sts_ttype;
  g_sts_tab2                      g_sts_ttype;
  g_sts_tab3                      g_sts_ttype;
--
  /**********************************************************************************
   * Procedure Name   : para_out
   * Description      : �p�����[�^�o�͏���(A-0)
   *********************************************************************************/
  PROCEDURE para_out(
    in_file_id    IN  NUMBER,              -- FILE_ID
    iv_get_format IN  VARCHAR2,            -- ���̓t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
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
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --
    ------------------------------------
    --0.�p�����[�^�o��
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_rep_h1,
                     iv_token_name1   => cv_tkn_param1,           --�p�����[�^�P
                     iv_token_value1  => TO_CHAR( in_file_id ),   --�t�@�C��ID
                     iv_token_name2   => cv_tkn_param2,           --�p�����[�^�Q
                     iv_token_value2  => iv_get_format            --�t�H�[�}�b�g�p�^�[��
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    ------------------------------------
    --�t�@�C���A�b�v���[�h����
    ------------------------------------
    BEGIN
    --
      SELECT flv.lookup_type            lookup_type,
             flv.lookup_code            lookup_code,
             flv.meaning                meaning,
             flv.description            description
      INTO   gv_lookup_type,
             gn_lookup_code,
             gv_meaning,
             gv_description
      FROM   fnd_lookup_types           flt,
             fnd_application            fa,
             fnd_lookup_values          flv
      WHERE  flt.lookup_type            = flv.lookup_type
      AND    fa.application_short_name  = ct_xxccp_appl_short_name
      AND    flt.application_id         = fa.application_id
      AND    flt.lookup_type            = ct_file_up_load_name
      AND    flv.lookup_code            = iv_get_format
      AND    flv.language               = USERENV( 'LANG' )
      AND    ROWNUM                     = 1
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    ------------------------------------
    --CSV�t�@�C������
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_name                file_name
      INTO   gv_csv_file_name
      FROM   xxccp_mrp_file_ul_interface  xmf
      WHERE  xmf.file_id                  = in_file_id
      AND    ROWNUM                       = 1
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_csv_name_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => ct_xxcos_appl_short_name,
                    iv_name          => ct_msg_get_rep_h2,
                    iv_token_name1   => cv_tkn_param3,            --�t�@�C���A�b�v���[�h����(���b�Z�[�W������)
                    iv_token_value1  => gv_meaning,               --�t�@�C���A�b�v���[�h����
                    iv_token_name2   => cv_tkn_param4,            --CSV�t�@�C����(���b�Z�[�W������)
                    iv_token_value2  => gv_csv_file_name          --CSV�t�@�C����
                  );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
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
                     iv_token_value1 => TO_CHAR( in_file_id )
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
   * Procedure Name   : <get_ci_data>
   * Description      : <�t�@�C���A�b�v���[�hIF�ڋq�i�ڃf�[�^�̎擾>(A-1)
   ***********************************************************************************/
  PROCEDURE get_ci_data (
    in_file_id          IN  NUMBER,   -- 1.<file_id>
    ov_errbuf           OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ci_data'; -- �v���O������
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
    lv_key_info               VARCHAR2(5000); --key���
    lv_tab_name               VARCHAR2(500);  --�e�[�u����
    ln_file_id                NUMBER;         --�t�@�C��ID
    ln_last_updated_by        NUMBER;         --�ŏI�X�V��
    ld_last_update_date       DATE;           --�ŏI�X�V��
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
    -- 1.�ڋq�i�ڃf�[�^�擾
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id,              -- �t�@�C���h�c
      ov_file_data => g_trans_cust_item_tab,   -- �ڋq�i�ڃf�[�^(�z��^)
      ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg    => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ov_errbuf      => lv_errbuf,      --�G���[�E���b�Z�[�W
        ov_retcode     => lv_retcode,     --���^�[���R�[�h
        ov_errmsg      => lv_errmsg,      --���[�U�E�G���[�E���b�Z�[�W
        ov_key_info    => lv_key_info,    --�ҏW���ꂽ�L�[���
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- �ڋq�i�ڃf�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( g_trans_cust_item_tab.COUNT < cn_min_2 ) THEN
      --���b�Z�[�W(�e�[�u���F�t�@�C���A�b�v���[�hIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf,      --�G���[�E���b�Z�[�W
        ov_retcode     => lv_retcode,     --���^�[���R�[�h
        ov_errmsg      => lv_errmsg,      --���[�U�E�G���[�E���b�Z�[�W
        ov_key_info    => lv_key_info,    --�ҏW���ꂽ�L�[���
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- �ڋq�i�ڃf�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( g_trans_cust_item_tab IS NULL ) THEN
      --���b�Z�[�W(�e�[�u���F�t�@�C���A�b�v���[�hIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --�L�[���
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf,      --�G���[�E���b�Z�[�W
        ov_retcode     => lv_retcode,     --���^�[���R�[�h
        ov_errmsg      => lv_errmsg,      --���[�U�E�G���[�E���b�Z�[�W
        ov_key_info    => lv_key_info,    --�ҏW���ꂽ�L�[���
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    ------------------------------------
    -- 2.�f�[�^�������̎擾
    ------------------------------------
    --�f�[�^������
    gn_get_counter_data := g_trans_cust_item_tab.COUNT;
    gn_target_cnt := g_trans_cust_item_tab.COUNT - 1;
    --
    -----------------------------------------
    -- 3.�t�@�C���A�b�v���[�hIF�f�[�^�폜����
    -----------------------------------------
    --
    ------------------------------------
    -- �t�@�C��ID�̎擾(���b�N)
    ------------------------------------
    BEGIN
    --
      SELECT
        xmf.file_id                     file_id,            --�t�@�C��ID
        xmf.last_updated_by             last_updated_by,    --�ŏI�X�V��
        xmf.last_update_date            last_update_date    --�ŏI�X�V��
      INTO
        ln_file_id,
        ln_last_updated_by,
        ld_last_update_date
      FROM xxccp_mrp_file_ul_interface  xmf
      WHERE xmf.file_id                 = in_file_id        --���̓p�����[�^��FILE_ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --***** �t�@�C��ID�̎擾�n���h��(�t�@�C��ID�̎擾(�f�[�^))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_data_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_tab_name,
                         iv_token_name2  => cv_tkn_key_data,
                         iv_token_value2 => NULL
                       );
        RAISE global_api_expt;
      WHEN global_data_lock_expt THEN
        --***** �t�@�C��ID�̎擾�n���h��(���b�N)
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- �f�[�^�폜
    ------------------------------------
    BEGIN
    --
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id                     = in_file_id  -- 1.<���̓p�����[�^��FILE_ID>
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_file_up_load
                       );
        RAISE global_del_order_data_expt;
    --
    END;
  --
  EXCEPTION
  --
    --***** �ڋq�i�ڃf�[�^�擾
    WHEN global_get_cust_item_data_expt THEN
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
  END get_ci_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,    -- 1.<FILE_ID>
    iv_get_format IN  VARCHAR2,  -- 2.<���̓t�H�[�}�b�g�p�^�[��>
    ov_errbuf     OUT NOCOPY VARCHAR2,  -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,  -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)  -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_key_info                         VARCHAR2(5000);     --key���
    lv_table_name                       VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur1
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_cus_class
      AND   flv.lookup_code             LIKE ct_lookup_code_cus_class
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    --
    CURSOR data_cur2
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_cus_status
      AND   flv.lookup_code             LIKE ct_lookup_code_cus_status
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    --
    CURSOR data_cur3
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_edi_item
      AND   flv.lookup_code             LIKE ct_lookup_code_edi_item
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    -- *** ���[�J���E���R�[�h ***
    l_data_rec1                         data_cur1%ROWTYPE;
    l_data_rec2                         data_cur2%ROWTYPE;
    l_data_rec3                         data_cur3%ROWTYPE;
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
    -- 1.�Ɩ����t�擾
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
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
    -- 3.�݌ɑg�DID�̎擾
    ------------------------------------
    --�݌ɑg�DID�̎擾
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
    ------------------------------------
    -- 4.�}�X�^�݌ɑg�DID�̎擾
    ------------------------------------
    BEGIN
      --
      SELECT mpr.master_organization_id master_organization_id        --�}�X�^�݌ɑg�DID
      INTO   gv_f_master_organization_id
      FROM   mtl_parameters             mpr
      WHERE  mpr.organization_id        = gn_get_stock_id_ret
      ;
      -- �}�X�^�݌ɑg�DID�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_zaiko_org_para
                          );
         lv_key_info   := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_org_code,
                            iv_token_name1  => cv_tkn_org_code,
                            iv_token_value1 => gv_inv_org_code
                          );
         lv_errmsg     := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_data_err,
                            iv_token_name1  => cv_tkn_table_name,
                            iv_token_value1 => lv_table_name,
                            iv_token_name2  => cv_tkn_key_data,
                            iv_token_value2 => lv_key_info
                          );
       RAISE global_api_expt;
      --
    END;
--
    ------------------------------------
    -- 5.XXCOS:�ڋq�i�ڏ��i�R�[�h�̎擾
    ------------------------------------
    gv_ci_commodity := FND_PROFILE.VALUE( ct_ci_commodity_code );
--
    -- XXCOS:�ڋq�i�ڏ��i�R�[�h�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_ci_commodity IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_ci_commodity
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 6.���i�R�[�hID�̎擾
    ------------------------------------
    BEGIN
    --
      SELECT mcc.commodity_code_id      commodity_code_id   --���i�R�[�hID
      INTO   gt_commodity_code_id
      FROM   mtl_commodity_codes        mcc
      WHERE  mcc.commodity_code         = gv_ci_commodity
      AND  ( mcc.inactive_date          IS NULL
        OR   mcc.inactive_date          > gd_process_date )
      ;
    --
    EXCEPTION
      --***** ���i�R�[�hID�̎擾�n���h��
       WHEN NO_DATA_FOUND THEN
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_comdt_codes
                           );
          lv_key_info   := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_commodity_err,
                             iv_token_name1  => cv_tkn_commodity_code,
                             iv_token_value1 => gv_ci_commodity
                           );
          lv_errmsg     := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_data_err,
                             iv_token_name1  => cv_tkn_table_name,
                             iv_token_value1 => lv_table_name,
                             iv_token_name2  => cv_tkn_key_data,
                             iv_token_value2 => lv_key_info
                           );
       RAISE global_api_expt;
    END;
--
    ------------------------------------
    -- 7.�ΏۂƂȂ�ڋq�敪�̎擾
    ------------------------------------
    BEGIN
      --==================================
      -- 7-1.�f�[�^�擾
      --==================================
      <<loop_get_data1>>
      FOR l_data_rec1 IN data_cur1
      LOOP
        g_sts_tab1(l_data_rec1.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data1;
      --
      IF ( g_sts_tab1.COUNT = 0 ) THEN
        --***** �t�@�C�����̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_cust_kbn
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
--
    ------------------------------------
    -- 8.�ΏۂƂȂ�ڋq�X�e�[�^�X�̎擾
    ------------------------------------
    BEGIN
      --==================================
      -- 8-1.�f�[�^�擾
      --==================================
      <<loop_get_data2>>
      FOR l_data_rec2 IN data_cur2
      LOOP
        g_sts_tab2(l_data_rec2.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data2;
      --
      IF ( g_sts_tab2.COUNT = 0 ) THEN
        --***** �t�@�C�����̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_cust_status
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
--
    ---------------------------------------------
    -- 9.�ΏۊO�ƂȂ�EDI�A�g�i�ڃR�[�h�敪�̎擾
    ---------------------------------------------
    BEGIN
      --==================================
      -- 9-1.�f�[�^�擾
      --==================================
      <<loop_get_data3>>
      FOR l_data_rec3 IN data_cur3
      LOOP
        g_sts_tab3(l_data_rec3.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data3;
      --
      IF ( g_sts_tab3.COUNT = 0 ) THEN
        --***** �t�@�C�����̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_edi_item_kbn
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
    --
    ------------------------------------
    -- 10.XXCOS:�{�P�ʃR�[�h�̎擾
    ------------------------------------
    gv_hon_uom_code := FND_PROFILE.VALUE( ct_hon_uom_code );
--
    -- XXCOS:�{�P�ʃR�[�h�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_hon_uom_code IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_hon_uom
                     );
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
    ------------------------------------
    -- 11.�ҋ@�Ԋu�̎擾
    ------------------------------------
    -- XXCOS:�ҋ@�Ԋu�̎擾
    gn_interval := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_interval ) );
--
    -- �ҋ@�Ԋu�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gn_interval IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_interval
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
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_max_wait
                     );
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_process_date_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
     --***** �v���t�@�C���擾��O�n���h��(2.XXCOI:�݌ɑg�D�R�[�h�̎擾)
     --***** �v���t�@�C���擾��O�n���h��(5.XXCOS:�ڋq�i�ڏ��i�R�[�h�̎擾)
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
     --***** �݌ɑg�DID�̎擾�O�n���h��(3.�݌ɑg�DID�̎擾)
    WHEN global_get_stock_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_api_call_err,
                     iv_token_name1  => cv_tkn_api_name,
                     iv_token_value1 => lv_key_info
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
   * Procedure Name   : <cust_item_split>
   * Description      : <�ڋq�i�ڃf�[�^�̍��ڕ�������>(A-3)
   ***********************************************************************************/
  PROCEDURE cust_item_split(
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_item_split'; -- �v���O������
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
    <<get_ci_row_loop>>
    FOR i IN 1 .. gn_get_counter_data LOOP
    --
      ------------------------------------
      -- �S���ڐ��`�F�b�N
      ------------------------------------
      IF ( ( NVL( LENGTH( g_trans_cust_item_tab(i) ), 0 )
        - NVL( LENGTH( REPLACE( g_trans_cust_item_tab(i), cv_c_kanma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --�G���[
        lv_rec_data := g_trans_cust_item_tab(i);
        RAISE global_cut_order_data_expt;
      END IF;
      --�J��������
      <<get_ci_col_loop>>
      FOR j IN 1 .. cn_c_header LOOP
      --
        ------------------------------------
        -- ���ڕ���
        ------------------------------------
        g_cust_item_work_tab(i)(j) := xxccp_common_pkg.char_delim_partition(
                                        iv_char     => g_trans_cust_item_tab(i),
                                        iv_delim    => cv_c_kanma,
                                        in_part_num => j
                                      );
      END LOOP get_ci_col_loop;
    --
    END LOOP get_ci_row_loop;
  --
  EXCEPTION
    --�t�@�C�����R�[�h���ڐ��s��v�n���h��
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  => cv_tkn_data,
                     iv_token_value1 => lv_rec_data
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
  END cust_item_split;
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <���ڃ`�F�b�N>(A-4)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER,   -- 1.<�f�[�^��>
    iv_get_format           IN  VARCHAR2, -- 2.<�t�H�[�}�b�g�p�^�[��>
    ov_account_number       OUT NOCOPY VARCHAR2, -- 1.<�ڋq�R�[�h>
    ov_errbuf               OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_errmsg2           VARCHAR2(32767);  --�G���[���b�Z�[�W
    lv_status            VARCHAR2(1);      -- �I���X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***     ���ڂ̃`�F�b�N����          ***
    -- ***************************************
--
    --������
    lv_errmsg2 := NULL;
    ------------------------------------
    -- 1.���ڃ`�F�b�N
    ------------------------------------
    --�ڋq�R�[�h
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_code),          -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_code),                  -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_cust_code_dlength,                                        -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                     --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                       --�sNO
                     iv_token_name2   => cv_tkn_message,                                     --�ڋq�R�[�h(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_code)  --�ڋq�R�[�h
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_account_number := g_cust_item_work_tab(in_cnt)(cn_cust_code);                -- 1.<�ڋq�R�[�h>
    END IF;
--
    --�ڋq�i��
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_item_code),     -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),             -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_cust_item_code_dlength,                                   -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                        -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                         --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                           --�sNO
                     iv_token_name2   => cv_tkn_message,                                         --�ڋq�i��(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_item_code) --�ڋq�i��
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
    --
--
    --�ڋq�i�ړE�v
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_item_summary),   -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_item_summary),           -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_cust_item_summary_dlength,                                 -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                         -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                            --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                              --�sNO
                     iv_token_name2   => cv_tkn_message,                                            --�ڋq�i�ړE�v(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_item_summary) --�ڋq�i�ړE�v
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --�����P��
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_ordering_unit),       -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_ordering_unit),               -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_ordering_unit_dlength,                                     -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                         -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                         --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                           --�sNO
                     iv_token_name2   => cv_tkn_message,                                         --�����P��(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_ordering_unit)  --�����P��
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --�i�ڃR�[�h
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_item_code),           -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_item_code),                   -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_item_code_dlength,                                         -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                         -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                 -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                     --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                       --�sNO
                     iv_token_name2   => cv_tkn_message,                                     --�i�ڃR�[�h(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_item_code)  --�i�ڃR�[�h
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --�o�׌��ۊǏꏊ
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_ship_from_space),     -- 1.���ږ���(���{�ꖼ)         -- �K�{
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_ship_from_space),             -- 2.���ڂ̒l                   -- �C��
      in_item_len     => cn_ship_from_space_dlength,                                   -- 3.���ڂ̒���                 -- �K�{
      in_item_decimal => NULL,                                                         -- 4.���ڂ̒���(�����_�ȉ�)     -- �����t�K�{
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.�K�{�t���O(��L�萔��ݒ�) -- �K�{
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.���ڑ���(��L�萔��ݒ�)   -- �K�{
      ov_errbuf       => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode      => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg       => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --����łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                           --�sNO(�g�[�N��)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                             --�sNO
                     iv_token_name2   => cv_tkn_message,                                           --�o�׌��ۊǏꏊ(�g�[�N��)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_ship_from_space)  --�o�׌��ۊǏꏊ
                   );
      --LOG�����o��
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    IF ( lv_status = cv_status_warn ) THEN
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
  END item_check;
--
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <�}�X�^���̎擾����>(A-5)
   ***********************************************************************************/
  PROCEDURE get_master_data(
    iv_get_format               IN  VARCHAR2,        -- �t�H�[�}�b�g�p�^�[��
    iv_account_number           IN  VARCHAR2,        -- �ڋq�R�[�h
    in_line_no                  IN  NUMBER,          -- �sNO.
    on_cust_account_id          OUT NOCOPY NUMBER,   -- �ڋqID
    ov_account_number           OUT NOCOPY VARCHAR2, -- �ڋq�R�[�h
    on_inventory_item_id        OUT NOCOPY NUMBER,   -- �i��ID
    ov_errbuf                   OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_key_data                     VARCHAR2(5000);  --key���
    lv_table_name                   VARCHAR2(5000);  --�e�[�u����
    lv_account_number               VARCHAR2(50);    --�ڋq�R�[�h
    lv_customer_class_code          VARCHAR2(30);    --�ڋq�敪
    lv_duns_number_c                VARCHAR2(30);    --�ڋq�X�e�[�^�X
    lv_edi_item_code_div            VARCHAR2(50);    --EDI�A�g�i�ڃR�[�h�敪
    lv_segment1                     VARCHAR2(30);    --�i�ڃR�[�h
    lv_uom_code                     VARCHAR2(30);    --UOM�R�[�h
    lv_secondary_inventory_name     VARCHAR2(128);   --�ۊǏꏊ�R�[�h
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    lt_parent_item_no               ic_item_mst_b.item_no%TYPE;
    lt_edi_chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE;  -- EDI�`�F�[���X�R�[�h
    lv_exists_flag                  VARCHAR2(1);     --���݃`�F�b�N�p�ꎞ�ϐ�
    lt_item_status                  xxcmm_system_items_b.item_status%TYPE;   -- �i�ڃX�e�[�^�X
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
    lv_primary_uom_code             VARCHAR2(30);    --��P��
    lv_kansan_exists_flag           VARCHAR2(1);     --�P�ʊ��Z���݃`�F�b�N�p�ꎞ�ϐ�
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
    ------------------------------------
    -- 1.�ڋq�ǉ����}�X�^�̃`�F�b�N
    ------------------------------------
    BEGIN
      SELECT
        hca.cust_account_id           cust_account_id,              --�ڋqID
        hca.account_number            account_number,               --�ڋq�R�[�h
        hca.customer_class_code       customer_class_code,          --�ڋq�敪
        hp.duns_number_c              duns_number_c,                --�ڋq�X�e�[�^�X
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
        xac.edi_chain_code            edi_chain_code,               --EDI�`�F�[���X�R�[�h
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
        xac.edi_item_code_div         edi_item_code_div             --EDI�A�g�i�ڃR�[�h�敪
      INTO
        on_cust_account_id,
        ov_account_number,
        lv_customer_class_code,
        lv_duns_number_c,
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
        lt_edi_chain_code,
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
        lv_edi_item_code_div
      FROM
        xxcmm_cust_accounts       xac,  --�ڋq�ǉ����
        hz_cust_accounts          hca,  --�ڋq�}�X�^
        hz_parties                hp    --�p�[�e�B�}�X�^
      WHERE hca.account_number        = iv_account_number           --�ڋq�R�[�h
      AND   hca.cust_account_id       = xac.customer_id             --�ڋqID
      AND   hca.party_id              = hp.party_id                 --�p�[�e�BID
      ;
    EXCEPTION
      --�ڋq�}�X�^���݃`�F�b�N
      WHEN NO_DATA_FOUND THEN
        --***** �ڋq�R�[�h�̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_cust_mst_err
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_format_err2,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_message,
                           iv_token_value4 => lv_key_data,
                           iv_token_name5  => cv_tkn_item_code,
                           iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    lv_account_number := ov_account_number;
    --�ڋq�敪�`�F�b�N
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab1.EXISTS( lv_customer_class_code ) = FALSE ) )
    THEN
      --***** �ڋq�敪�̎擾�n���h��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_cust_class_code_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    --�ڋq�X�e�[�^�X�`�F�b�N
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab2.EXISTS( lv_duns_number_c ) = FALSE ) )
    THEN
      --***** �ڋq�X�e�[�^�X�̎擾�n���h��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_duns_number_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    --EDI�A�g�i�ڃR�[�h�敪�`�F�b�N
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab3.EXISTS( lv_edi_item_code_div ) = TRUE ) )
    THEN
      --***** EDI�A�g�i�ڃR�[�h�敪�̎擾�n���h��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_edi_item_cd_div_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    ------------------------------------
    -- 2.�i�ڃ}�X�^�̃`�F�b�N
    ------------------------------------
    BEGIN
      SELECT
        mib.segment1             segment1,                     --�i�ڃR�[�h
        mib.inventory_item_id    inventory_item_id,            --�i��ID
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
        mib.primary_uom_code     primary_uom_code              --��P��
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
      INTO
        lv_segment1,
        on_inventory_item_id,
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
        lv_primary_uom_code
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
      FROM
        mtl_system_items_b       mib                           --�i�ڃ}�X�^
      WHERE mib.segment1         = g_cust_item_work_tab(in_line_no)(cn_item_code) --�i�ڃR�[�h
      AND   mib.organization_id  = gn_get_stock_id_ret         --�g�DID
      ;
    EXCEPTION
      --�i�ڃ}�X�^���݃`�F�b�N
      WHEN NO_DATA_FOUND THEN
        --***** �i�ڃR�[�h�̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_format_err2,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_message,
                           iv_token_value4 => lv_key_data,
                           iv_token_name5  => cv_tkn_item_code,
                           iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    ------------------------------------
    -- 3.�q�i�ڃR�[�h�L���`�F�b�N
    ------------------------------------
    IF ( on_inventory_item_id IS NOT NULL ) THEN
      BEGIN
        SELECT
            iimb2.item_no
        INTO
            lt_parent_item_no
        FROM
            mtl_system_items_b      msib
          , ic_item_mst_b           iimb
          , xxcmn_item_mst_b        ximb
          , ic_item_mst_b           iimb2
        WHERE
            msib.inventory_item_id = on_inventory_item_id                         -- �i��ID
        AND msib.organization_id   = gn_get_stock_id_ret                          -- �g�DID
        AND iimb.item_no           = msib.segment1
        AND ximb.item_id           = iimb.item_id
        AND ximb.parent_item_id   <> iimb.item_id
        AND gd_process_date  BETWEEN NVL(ximb.start_date_active, gd_process_date) 
                                 AND NVL(ximb.end_date_active, gd_process_date)
        AND iimb2.item_id          = ximb.parent_item_id
        AND iimb2.inactive_ind    <> ct_inactive_ind_1
        ;
        -- �q�i�ڃR�[�h���݃`�F�b�N�i�G���[�j
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_child_item_code_err,
                       iv_token_name1  => cv_tkn_line_no,
                       iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- �sNo
                       iv_token_name2  => cv_tkn_cust_code,
                       iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- �ڋq�R�[�h
                       iv_token_name3  => cv_tkn_cust_item_code,
                       iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- �ڋq�i�ڃR�[�h
                       iv_token_name4  => cv_tkn_item_code,
                       iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- �i�ڃR�[�h
                       iv_token_name5  => cv_tkn_parent_item_code,
                       iv_token_value5 => lt_parent_item_no                                     -- �e�i�ڃR�[�h
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
    ------------------------------------
    -- 4.�i�ڃX�e�[�^�X�`�F�b�N
    ------------------------------------
    IF ( on_inventory_item_id IS NOT NULL ) THEN
      BEGIN
        SELECT
            xsib.item_status
        INTO
            lt_item_status
        FROM
            mtl_system_items_b      msib
          , xxcmm_system_items_b    xsib
        WHERE
            msib.inventory_item_id = on_inventory_item_id     -- �i��ID
        AND msib.organization_id   = gn_get_stock_id_ret      -- �g�DID
        AND xsib.item_code         = msib.segment1
        AND NOT EXISTS (
              SELECT
                  cv_exists_flag_yes
              FROM
                  fnd_lookup_values flv
              WHERE
                  flv.lookup_type        = ct_lookup_type_item_status
              AND flv.meaning            = xsib.item_status
              AND flv.language           = ct_lang
              AND flv.enabled_flag       = cv_enabled_flag_y
              AND gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date) 
                                       AND NVL(flv.end_date_active, gd_process_date) 
            )
        ;
        -- �i�ڃX�e�[�^�X�`�F�b�N
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_item_status_err,
                       iv_token_name1  => cv_tkn_line_no,
                       iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- �sNo
                       iv_token_name2  => cv_tkn_cust_code,
                       iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- �ڋq�R�[�h
                       iv_token_name3  => cv_tkn_cust_item_code,
                       iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- �ڋq�i�ڃR�[�h
                       iv_token_name4  => cv_tkn_item_code,
                       iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- �i�ڃR�[�h
                       iv_token_name5  => cv_tkn_item_status,
                       iv_token_value5 => lt_item_status                                        -- �i�ڃX�e�[�^�X
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
    ------------------------------------
    -- 5.�P�ʃ}�X�^�̃`�F�b�N
    ------------------------------------
    -- �����P�ʂ�NULL�̏ꍇ�A�u�{�v��ݒ肷��B
    IF ( g_cust_item_work_tab(in_line_no)(cn_ordering_unit) IS NULL ) THEN
      g_cust_item_work_tab(in_line_no)(cn_ordering_unit) := gv_hon_uom_code;
    END IF;
    --
    BEGIN
      SELECT
        mum.uom_code             uom_code            --UOM�R�[�h
      INTO
        lv_uom_code
      FROM
        mtl_units_of_measure_tl  mum                 --�P�ʃ}�X�^
      WHERE  mum.uom_code        = g_cust_item_work_tab(in_line_no)(cn_ordering_unit) --�����P��
      AND    mum.language        = USERENV( 'LANG' )
      AND  ( mum.disable_date    IS NULL
      OR     mum.disable_date    > gd_process_date )
      ;
    EXCEPTION
      --�P�ʃ}�X�^���݃`�F�b�N
      WHEN NO_DATA_FOUND THEN
        --***** �����P�ʂ̎擾�n���h��
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_units_of_measr_mstr
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_ordering_unit,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_ordered_uom_code,
                           iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_ordering_unit),
                           iv_token_name5  => cv_tkn_message,
                           iv_token_value5 => lv_key_data,
                           iv_token_name6  => cv_tkn_item_code,
                           iv_token_value6 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    ------------------------------------
    -- 6.�ۊǏꏊ�}�X�^�̃`�F�b�N
    ------------------------------------
    IF ( g_cust_item_work_tab(in_line_no)(cn_ship_from_space) IS NOT NULL ) THEN
      BEGIN
        SELECT
          msi.secondary_inventory_name       secondary_inventory_name      --�ۊǏꏊ�R�[�h
        INTO
          lv_secondary_inventory_name
        FROM
          mtl_secondary_inventories          msi                           --�ۊǏꏊ�}�X�^
        WHERE  msi.secondary_inventory_name  = g_cust_item_work_tab(in_line_no)(cn_ship_from_space) --�o�׌��ۊǏꏊ
        AND    msi.organization_id           = gn_get_stock_id_ret         --�g�DID
        AND  ( msi.disable_date              IS NULL
        OR     msi.disable_date              > gd_process_date )
        ;
      EXCEPTION
        --�ۊǏꏊ�}�X�^���݃`�F�b�N
        WHEN NO_DATA_FOUND THEN
          --***** �ۊǏꏊ�R�[�h�̎擾�n���h��
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_sec_inv_mstr
                           );
          lv_key_data   := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_data_err,
                             iv_token_name1  => cv_tkn_table_name,
                             iv_token_value1 => lv_table_name,
                             iv_token_name2  => cv_tkn_key_data,
                             iv_token_value2 => NULL
                           );
          lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
          lv_errmsg     := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_sec_inv_name,
                             iv_token_name1  => cv_tkn_line_no,
                             iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                             iv_token_name2  => cv_tkn_cust_code,
                             iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                             iv_token_name3  => cv_tkn_cust_item_code,
                             iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                             iv_token_name4  => cv_tkn_ship_from_subinv,
                             iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_ship_from_space),
                             iv_token_name5  => cv_tkn_message,
                             iv_token_value5 => lv_key_data,
                             iv_token_name6  => cv_tkn_item_code,
                             iv_token_value6 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                           );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    ---------------------------------------------------
    -- 7.�ۊǏꏊ�ݒ�ۃ`�F�b�N
    ---------------------------------------------------
    -- �`�F�b�N�����F�o�׌��ۊǏꏊ�����͍ρA�ڋq�敪��18
    IF (    g_cust_item_work_tab(in_line_no)(cn_ship_from_space) IS NOT NULL
        AND lv_customer_class_code = cv_customer_class_code_18
    ) THEN
      BEGIN
        -- EDI�`�F�[���X�R�[�h��NULL�̏ꍇ�̓G���[
        IF ( lt_edi_chain_code IS NULL ) THEN
          RAISE NO_DATA_FOUND;
        END IF;
        -- �ۊǏꏊ�̐ݒ�\�ȃ`�F�[���X���`�F�b�N
        SELECT
            cv_exists_flag_yes
        INTO
            lv_exists_flag
        FROM
            fnd_lookup_values flv
        WHERE
            flv.lookup_type        = ct_lookup_type_item_chain
        AND flv.language           = ct_lang
        AND flv.enabled_flag       = cv_enabled_flag_y
        AND gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                 AND NVL(flv.end_date_active, gd_process_date)
        AND flv.meaning            = lt_edi_chain_code  -- EDI�`�F�[���X�R�[�h
        ;
      EXCEPTION
        -- �ۊǏꏊ�ݒ�ۃ`�F�b�N
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_ship_from_subinv_err,
                         iv_token_name1  => cv_tkn_line_no,
                         iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- �sNo
                         iv_token_name2  => cv_tkn_cust_code,
                         iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- �ڋq�R�[�h
                         iv_token_name3  => cv_tkn_cust_item_code,
                         iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- �ڋq�i�ڃR�[�h
                         iv_token_name4  => cv_tkn_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- �i�ڃR�[�h
                         iv_token_name5  => cv_tkn_ship_from_subinv,
                         iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_ship_from_space), -- �o�׌��ۊǏꏊ
                         iv_token_name6  => cv_tkn_edi_chain_code,
                         iv_token_value6 => lt_edi_chain_code                                     -- EDI�`�F�[���X�R�[�h
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start   ********** --
    ------------------------------------
    -- 8.�P�ʕs���G���[�`�F�b�N
    ------------------------------------
    -- ��P�ʃ`�F�b�N
    -- (�i�ڃ}�X�^�Ƀf�[�^���݂���ꍇ ���� ��P�ʂ�CSV�t�@�C���Ŏw�肳�ꂽ�P�ʂ��قȂ�ꍇ�Ƀ`�F�b�N���s��)
    IF (on_inventory_item_id IS NOT NULL)
      AND (lv_primary_uom_code <> lv_uom_code)
    THEN
      -- �P�ʊ��Z�`�F�b�N
      BEGIN
        SELECT cv_exists_flag_yes                                                           -- ���݃t���O(����j
        INTO   lv_kansan_exists_flag
        FROM   mtl_uom_class_conversions  mucc                                              -- �P�ʊ��Z�}�X�^
        WHERE  mucc.inventory_item_id   = on_inventory_item_id                              -- �i��ID
        AND   (mucc.from_uom_code       = lv_uom_code
          OR
               mucc.to_uom_code         = lv_uom_code)                                      -- �����P��
        AND    TRUNC(SYSDATE)           < TRUNC(NVL(mucc.disable_date,SYSDATE+1))           -- ������
        AND    ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      -- �P�ʕs���G���[�`�F�b�N
      -- �����P�ʂ��i�ڃ}�X�^�̊�P�ʁA�܂��͒P�ʊ��Z�}�X�^�̊�P�ʂ��ϊ���P�ʂɖ��������ꍇ�͈ȉ��̏��������s
      IF (lv_kansan_exists_flag IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name,
                        iv_name         => ct_msg_item_uom_code_err,
                        iv_token_name1  => cv_tkn_line_no,
                        iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- �sNo
                        iv_token_name2  => cv_tkn_cust_code,
                        iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- �ڋq�R�[�h
                        iv_token_name3  => cv_tkn_cust_item_code,
                        iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- �ڋq�i�ڃR�[�h
                        iv_token_name4  => cv_tkn_item_code,
                        iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- �i�ڃR�[�h
                        iv_token_name5  => cv_tkn_ordered_uom_code,
                        iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_ordering_unit)    -- �P��
                      );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg -- ���[�U�[�E�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
  END get_master_data;
--
--
  /**********************************************************************************
   * Procedure Name   : <data_check>
   * Description      : <������o�^�ς݃f�[�^�`�F�b�N����>(A-6)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_cnt            IN  NUMBER,   -- �f�[�^��
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- �v���O������
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
    lv_rec_data               VARCHAR2(32765);
    lv_message                VARCHAR2(32765);
    lv_exists_flag            VARCHAR2(1);
    lv_table_name             VARCHAR2(5000);
    lv_status                 VARCHAR2(1);
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    ------------------------------------
    -- 0.�ϐ��̏�����
    ------------------------------------
--
    -- ***************************************
    -- ***       �f�[�^�d���`�F�b�N����    ***
    -- ***************************************
--
    <<jyufuku_loop11>>
    FOR i IN 2 .. g_cust_item_work_tab.COUNT LOOP
--
      ------------------------------------
      -- �f�[�^�d���`�F�b�N
      ------------------------------------
      IF ( i <> in_cnt ) --�������m�̃��R�[�h�`�F�b�N���Ȃ�
        AND ( g_cust_item_work_tab(in_cnt)(cn_cust_code) = g_cust_item_work_tab(i)(cn_cust_code)
        AND g_cust_item_work_tab(in_cnt)(cn_cust_item_code) = g_cust_item_work_tab(i)(cn_cust_item_code) )
      THEN
        lv_status := cv_status_warn;
      END IF;
--
    END LOOP jyufuku_loop11;
    --
    IF ( lv_status = cv_status_warn ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name,
                      iv_name         => ct_msg_get_keydata,
                      iv_token_name1  => cv_tkn_line_no,
                      iv_token_value1 => TO_CHAR( in_cnt, cv_format ),
                      iv_token_name2  => cv_tkn_cust_code,
                      iv_token_value2 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                      iv_token_name3  => cv_tkn_cust_item_code,
                      iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                      iv_token_name4  => cv_tkn_item_code,
                      iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    ------------------------------------
    -- �f�[�^�d���`�F�b�N
    ------------------------------------
    BEGIN
      SELECT
        cv_exists_flag_yes            exists_flag
      INTO
        lv_exists_flag
      FROM
        hz_cust_accounts              hca, --�ڋq�}�X�^
        mtl_customer_items            mci  --�ڋq�i�ڃ}�X�^
      WHERE hca.cust_account_id       = mci.customer_id
      AND   hca.account_number        = g_cust_item_work_tab(in_cnt)(cn_cust_code)
      AND   mci.customer_item_number  = g_cust_item_work_tab(in_cnt)(cn_cust_item_code)
      AND   ROWNUM                    = 1
      ;
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_exists_flag := cv_exists_flag_no;
    END;
--
    IF ( lv_exists_flag = cv_exists_flag_yes ) THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mci_mstr
                       );
      lv_message    := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mst_rec_exists_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_table_name,
                         iv_token_name2  => cv_tkn_line_no,
                         iv_token_value2 => TO_CHAR( in_cnt, cv_format ),
                         iv_token_name3  => cv_tkn_cust_code,
                         iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                         iv_token_name4  => cv_tkn_cust_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                         iv_token_name5  => cv_tkn_item_code,
                         iv_token_value5 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                       );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    ------------------------------------
    -- �f�[�^�d���`�F�b�N
    ------------------------------------
    BEGIN
      SELECT
        cv_exists_flag_yes               exists_flag
      INTO
        lv_exists_flag
      FROM
        mtl_customer_item_xrefs          mcix, --�ڋq�i�ڑ��ݎQ�ƃ}�X�^
        hz_cust_accounts                 hca,  --�ڋq�}�X�^
        mtl_customer_items               mci,  --�ڋq�i�ڃ}�X�^
        mtl_system_items_b               msi   --�i�ڃ}�X�^
      WHERE hca.account_number           = g_cust_item_work_tab(in_cnt)(cn_cust_code)
--*********** 2009/09/10 1.8 N.Maeda ADD START ********** --
      AND   hca.cust_account_id          = mci.customer_id
--*********** 2009/09/10 1.8 N.Maeda ADD  END  ********** --
      AND   mci.customer_item_number     = g_cust_item_work_tab(in_cnt)(cn_cust_item_code)
      AND   mci.customer_item_id         = mcix.customer_item_id
      AND   mcix.inventory_item_id       = msi.inventory_item_id
      AND   mcix.master_organization_id  = msi.organization_id
      AND   msi.segment1                 = g_cust_item_work_tab(in_cnt)(cn_item_code)
      AND   ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_exists_flag := cv_exists_flag_no;
    END;
    --
    IF ( lv_exists_flag = cv_exists_flag_yes ) THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcix_mstr
                       );
      lv_message    := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mst_rec_exists_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_table_name,
                         iv_token_name2  => cv_tkn_line_no,
                         iv_token_value2 => TO_CHAR( in_cnt, cv_format ),
                         iv_token_name3  => cv_tkn_cust_code,
                         iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                         iv_token_name4  => cv_tkn_cust_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                         iv_token_name5  => cv_tkn_item_code,
                         iv_token_value5 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                       );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    --�f�[�^�d���n���h��
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  => cv_tkn_data,
                     iv_token_value1 => lv_rec_data
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
  END data_check;
--
  /**********************************************************************************
   * Procedure Name   : <set_ci_data>
   * Description      : <�f�[�^�ݒ菈��>(A-7)
   ***********************************************************************************/
  PROCEDURE set_ci_data(
    in_cnt                   IN NUMBER,    -- 1.<�f�[�^��>
    in_cust_account_id       IN NUMBER,    -- 2.<�ڋqID>
    iv_account_number        IN VARCHAR2,  -- 3.<�ڋq�R�[�h>
    in_inventory_item_id     IN NUMBER,    -- 4.<�i��ID>
    ov_errbuf                OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ci_data'; -- �v���O������
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
  -- ******************************************************
  -- ***  �ڋq�i��OIF/�ڋq�i�ڑ��ݎQ��OIF�f�[�^�ݒ菈�� ***
  -- ******************************************************
--
    --�ڋq�i��OIF�f�[�^��ϐ��ɐݒ�
    g_ci_interface_tab(in_cnt).process_flag               := cv_dummy_data_1;        --�����t���O
    g_ci_interface_tab(in_cnt).process_mode               := cn_dummy_data_1;        --�������[�h
    g_ci_interface_tab(in_cnt).lock_flag                  := cv_dummy_data_1;        --���b�N�t���O
    g_ci_interface_tab(in_cnt).last_updated_by            := cn_last_updated_by;     --�ŏI�X�V��
    g_ci_interface_tab(in_cnt).last_update_date           := cd_last_update_date;    --�ŏI�X�V��
    g_ci_interface_tab(in_cnt).last_update_login          := cn_last_update_login;   --�ŏI�X�V���O�C��
    g_ci_interface_tab(in_cnt).created_by                 := cn_created_by;          --�쐬��
    g_ci_interface_tab(in_cnt).creation_date              := cd_creation_date;       --�쐬��
    g_ci_interface_tab(in_cnt).request_id                 := cn_request_id;          --�v��ID
    g_ci_interface_tab(in_cnt).program_application_id     := cn_program_application_id;
                                                                                     --�ݶ�����۸��ѱ��ع����ID
    g_ci_interface_tab(in_cnt).program_id                 := cn_program_id;          --�ݶ�����۸���ID
    g_ci_interface_tab(in_cnt).program_update_date        := cd_program_update_date; --�v���O�����X�V��
    g_ci_interface_tab(in_cnt).transaction_type           := cv_character_create;    --�g�����U�N�V�����^�C�v
    g_ci_interface_tab(in_cnt).customer_name              := NULL;                   --�ڋq����
    g_ci_interface_tab(in_cnt).customer_number            := iv_account_number;      --�ڋq�R�[�h�i�ڋq�ԍ��j
    g_ci_interface_tab(in_cnt).customer_id                := in_cust_account_id;     --�ڋqID
    g_ci_interface_tab(in_cnt).customer_category_code     := NULL;                   --�ڋq�J�e�S���R�[�h
    g_ci_interface_tab(in_cnt).customer_category          := NULL;                   --�ڋq�J�e�S��
    g_ci_interface_tab(in_cnt).address1                   := NULL;                   --�Z��1
    g_ci_interface_tab(in_cnt).address2                   := NULL;                   --�Z��2
    g_ci_interface_tab(in_cnt).address3                   := NULL;                   --�Z��3
    g_ci_interface_tab(in_cnt).address4                   := NULL;                   --�Z��4
    g_ci_interface_tab(in_cnt).city                       := NULL;                   --�s
    g_ci_interface_tab(in_cnt).state                      := NULL;                   --�B
    g_ci_interface_tab(in_cnt).county                     := NULL;                   --�Q
    g_ci_interface_tab(in_cnt).country                    := NULL;                   --��
    g_ci_interface_tab(in_cnt).postal_code                := NULL;                   --�X�֔ԍ�
    g_ci_interface_tab(in_cnt).address_id                 := NULL;                   --�Z��ID
    g_ci_interface_tab(in_cnt).customer_item_number       := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_code);
                                                                                     --�ڋq�i�ڔԍ�
    g_ci_interface_tab(in_cnt).item_definition_level_desc := NULL;                   --�i�ڒ�`���x���E�v
    g_ci_interface_tab(in_cnt).item_definition_level      := cv_dummy_data_1;        --�i�ڒ�`���x��
    g_ci_interface_tab(in_cnt).customer_item_desc         := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_summary);
                                                                                     --�ڋq�i�ړE�v
    g_ci_interface_tab(in_cnt).model_customer_item_number := NULL;                   --���f���ڋq�i�ڔԍ�
    g_ci_interface_tab(in_cnt).model_customer_item_id     := NULL;                   --���f���ڋq�i��ID
    g_ci_interface_tab(in_cnt).commodity_code             := gv_ci_commodity;        --���i�R�[�h
    g_ci_interface_tab(in_cnt).commodity_code_id          := gt_commodity_code_id;   --���i�R�[�hID
    g_ci_interface_tab(in_cnt).master_container_segment2  := NULL;                   --�}�X�^�R���e�i�Z�O�����g2
    g_ci_interface_tab(in_cnt).master_container_segment3  := NULL;                   --�}�X�^�R���e�i�Z�O�����g3
    g_ci_interface_tab(in_cnt).master_container_segment4  := NULL;                   --�}�X�^�R���e�i�Z�O�����g4
    g_ci_interface_tab(in_cnt).master_container_segment5  := NULL;                   --�}�X�^�R���e�i�Z�O�����g5
    g_ci_interface_tab(in_cnt).master_container_segment6  := NULL;                   --�}�X�^�R���e�i�Z�O�����g6
    g_ci_interface_tab(in_cnt).master_container_segment7  := NULL;                   --�}�X�^�R���e�i�Z�O�����g7
    g_ci_interface_tab(in_cnt).master_container_segment8  := NULL;                   --�}�X�^�R���e�i�Z�O�����g8
    g_ci_interface_tab(in_cnt).master_container_segment9  := NULL;                   --�}�X�^�R���e�i�Z�O�����g9
    g_ci_interface_tab(in_cnt).master_container_segment10 := NULL;                   --�}�X�^�R���e�i�Z�O�����g10
    g_ci_interface_tab(in_cnt).master_container_segment11 := NULL;                   --�}�X�^�R���e�i�Z�O�����g11
    g_ci_interface_tab(in_cnt).master_container_segment12 := NULL;                   --�}�X�^�R���e�i�Z�O�����g12
    g_ci_interface_tab(in_cnt).master_container_segment13 := NULL;                   --�}�X�^�R���e�i�Z�O�����g13
    g_ci_interface_tab(in_cnt).master_container_segment14 := NULL;                   --�}�X�^�R���e�i�Z�O�����g14
    g_ci_interface_tab(in_cnt).master_container_segment15 := NULL;                   --�}�X�^�R���e�i�Z�O�����g15
    g_ci_interface_tab(in_cnt).master_container_segment16 := NULL;                   --�}�X�^�R���e�i�Z�O�����g16
    g_ci_interface_tab(in_cnt).master_container_segment17 := NULL;                   --�}�X�^�R���e�i�Z�O�����g17
    g_ci_interface_tab(in_cnt).master_container_segment18 := NULL;                   --�}�X�^�R���e�i�Z�O�����g18
    g_ci_interface_tab(in_cnt).master_container_segment19 := NULL;                   --�}�X�^�R���e�i�Z�O�����g19
    g_ci_interface_tab(in_cnt).master_container_segment20 := NULL;                   --�}�X�^�R���e�i�Z�O�����g20
    g_ci_interface_tab(in_cnt).master_container           := NULL;                   --�}�X�^�R���e�i
    g_ci_interface_tab(in_cnt).master_container_item_id   := NULL;                   --�}�X�^�R���e�i�i��ID
    g_ci_interface_tab(in_cnt).container_item_org_name    := NULL;                   --�R���e�i�i�ڑg�D����
    g_ci_interface_tab(in_cnt).container_item_org_code    := NULL;                   --�R���e�i�i�ڑg�D�R�[�h
    g_ci_interface_tab(in_cnt).container_item_org_id      := NULL;                   --�R���e�i�i�ڑg�DID
    g_ci_interface_tab(in_cnt).detail_container_segment1  := NULL;                   --�ڍ׃R���e�i�Z�O�����g1
    g_ci_interface_tab(in_cnt).detail_container_segment2  := NULL;                   --�ڍ׃R���e�i�Z�O�����g2
    g_ci_interface_tab(in_cnt).detail_container_segment3  := NULL;                   --�ڍ׃R���e�i�Z�O�����g3
    g_ci_interface_tab(in_cnt).detail_container_segment4  := NULL;                   --�ڍ׃R���e�i�Z�O�����g4
    g_ci_interface_tab(in_cnt).detail_container_segment5  := NULL;                   --�ڍ׃R���e�i�Z�O�����g5
    g_ci_interface_tab(in_cnt).detail_container_segment6  := NULL;                   --�ڍ׃R���e�i�Z�O�����g6
    g_ci_interface_tab(in_cnt).detail_container_segment7  := NULL;                   --�ڍ׃R���e�i�Z�O�����g7
    g_ci_interface_tab(in_cnt).detail_container_segment8  := NULL;                   --�ڍ׃R���e�i�Z�O�����g8
    g_ci_interface_tab(in_cnt).detail_container_segment9  := NULL;                   --�ڍ׃R���e�i�Z�O�����g9
    g_ci_interface_tab(in_cnt).detail_container_segment10 := NULL;                   --�ڍ׃R���e�i�Z�O�����g10
    g_ci_interface_tab(in_cnt).detail_container_segment11 := NULL;                   --�ڍ׃R���e�i�Z�O�����g11
    g_ci_interface_tab(in_cnt).detail_container_segment12 := NULL;                   --�ڍ׃R���e�i�Z�O�����g12
    g_ci_interface_tab(in_cnt).detail_container_segment13 := NULL;                   --�ڍ׃R���e�i�Z�O�����g13
    g_ci_interface_tab(in_cnt).detail_container_segment14 := NULL;                   --�ڍ׃R���e�i�Z�O�����g14
    g_ci_interface_tab(in_cnt).detail_container_segment15 := NULL;                   --�ڍ׃R���e�i�Z�O�����g15
    g_ci_interface_tab(in_cnt).detail_container_segment16 := NULL;                   --�ڍ׃R���e�i�Z�O�����g16
    g_ci_interface_tab(in_cnt).detail_container_segment17 := NULL;                   --�ڍ׃R���e�i�Z�O�����g17
    g_ci_interface_tab(in_cnt).detail_container_segment18 := NULL;                   --�ڍ׃R���e�i�Z�O�����g18
    g_ci_interface_tab(in_cnt).detail_container_segment19 := NULL;                   --�ڍ׃R���e�i�Z�O�����g19
    g_ci_interface_tab(in_cnt).detail_container_segment20 := NULL;                   --�ڍ׃R���e�i�Z�O�����g20
    g_ci_interface_tab(in_cnt).detail_container           := NULL;                   --�ڍ׃R���e�i
    g_ci_interface_tab(in_cnt).detail_container_item_id   := NULL;                   --�ڍ׃R���e�i�i��ID
    g_ci_interface_tab(in_cnt).min_fill_percentage        := NULL;                   --�ŏ��ύڃp�[�Z���g
    g_ci_interface_tab(in_cnt).dep_plan_required_flag     := NULL;                   --�����]�t���O
    g_ci_interface_tab(in_cnt).dep_plan_prior_bld_flag    := NULL;                   --�����]�쐬�t���O
    g_ci_interface_tab(in_cnt).inactive_flag              := cv_dummy_data_2;        --�����t���O
    g_ci_interface_tab(in_cnt).attribute_category         := NULL;                   --�����J�e�S��
    g_ci_interface_tab(in_cnt).attribute1                 := g_cust_item_work_tab(in_cnt+1)(cn_ordering_unit);
                                                                                     --�����P�i�����P�ʁj
    g_ci_interface_tab(in_cnt).attribute2                 := NULL;                   --�����Q
    g_ci_interface_tab(in_cnt).attribute3                 := NULL;                   --�����R
    g_ci_interface_tab(in_cnt).attribute4                 := NULL;                   --�����S
    g_ci_interface_tab(in_cnt).attribute5                 := NULL;                   --�����T
    g_ci_interface_tab(in_cnt).attribute6                 := NULL;                   --�����U
    g_ci_interface_tab(in_cnt).attribute7                 := NULL;                   --�����V
    g_ci_interface_tab(in_cnt).attribute8                 := NULL;                   --�����W
    g_ci_interface_tab(in_cnt).attribute9                 := NULL;                   --�����X
    g_ci_interface_tab(in_cnt).attribute10                := NULL;                   --�����P�O
    g_ci_interface_tab(in_cnt).attribute11                := NULL;                   --�����P�P
    g_ci_interface_tab(in_cnt).attribute12                := NULL;                   --�����P�Q
    g_ci_interface_tab(in_cnt).attribute13                := NULL;                   --�����P�R
    g_ci_interface_tab(in_cnt).attribute14                := NULL;                   --�����P�S
    g_ci_interface_tab(in_cnt).attribute15                := NULL;                   --�����P�T
    g_ci_interface_tab(in_cnt).demand_tolerance_positive  := NULL;                   --���v���e�͈́i���j
    g_ci_interface_tab(in_cnt).demand_tolerance_negative  := NULL;                   --���v���e�͈́i���j
    g_ci_interface_tab(in_cnt).error_code                 := NULL;                   --�G���[�R�[�h
    g_ci_interface_tab(in_cnt).error_explanation          := NULL;                   --�G���[����
    g_ci_interface_tab(in_cnt).master_container_segment1  := NULL;                   --�}�X�^�R���e�i�Z�O�����g�P
--
    --�ڋq�i�ڑ��ݎQ��OIF�f�[�^��ϐ��ɐݒ�
    g_ci_xrefs_interface_tab(in_cnt).process_flag               := cv_dummy_data_1;        --�����t���O
    g_ci_xrefs_interface_tab(in_cnt).process_mode               := cn_dummy_data_1;        --�������[�h
    g_ci_xrefs_interface_tab(in_cnt).lock_flag                  := cv_dummy_data_1;        --���b�N�t���O
    g_ci_xrefs_interface_tab(in_cnt).last_update_date           := cd_last_update_date;    --�ŏI�X�V��
    g_ci_xrefs_interface_tab(in_cnt).last_updated_by            := cn_last_updated_by;     --�ŏI�X�V��
    g_ci_xrefs_interface_tab(in_cnt).created_by                 := cn_created_by;          --�쐬��
    g_ci_xrefs_interface_tab(in_cnt).creation_date              := cd_creation_date;       --�쐬��
    g_ci_xrefs_interface_tab(in_cnt).last_update_login          := cn_last_update_login;   --�ŏI�X�V���O�C��
    g_ci_xrefs_interface_tab(in_cnt).request_id                 := cn_request_id;          --�v��ID
    g_ci_xrefs_interface_tab(in_cnt).program_application_id     := cn_program_application_id;
                                                                                           --�ݶ�����۸��ѱ��ع����ID
    g_ci_xrefs_interface_tab(in_cnt).program_id                 := cn_program_id;          --�ݶ�����۸���ID
    g_ci_xrefs_interface_tab(in_cnt).program_update_date        := cd_program_update_date; --�v���O�����X�V��
    g_ci_xrefs_interface_tab(in_cnt).transaction_type           := cv_character_create;    --�g�����U�N�V�����^�C�v
    g_ci_xrefs_interface_tab(in_cnt).customer_name              := NULL;                   --�ڋq����
    g_ci_xrefs_interface_tab(in_cnt).customer_number            := iv_account_number;      --�ڋq�R�[�h�i�ڋq�ԍ��j
    g_ci_xrefs_interface_tab(in_cnt).customer_id                := in_cust_account_id;     --�ڋqID
    g_ci_xrefs_interface_tab(in_cnt).customer_category_code     := NULL;                   --�ڋq�J�e�S���R�[�h
    g_ci_xrefs_interface_tab(in_cnt).customer_category          := NULL;                   --�ڋq�J�e�S��
    g_ci_xrefs_interface_tab(in_cnt).address1                   := NULL;                   --�Z���P
    g_ci_xrefs_interface_tab(in_cnt).address2                   := NULL;                   --�Z���Q
    g_ci_xrefs_interface_tab(in_cnt).address3                   := NULL;                   --�Z���R
    g_ci_xrefs_interface_tab(in_cnt).address4                   := NULL;                   --�Z���S
    g_ci_xrefs_interface_tab(in_cnt).city                       := NULL;                   --�s
    g_ci_xrefs_interface_tab(in_cnt).state                      := NULL;                   --�B
    g_ci_xrefs_interface_tab(in_cnt).county                     := NULL;                   --�Q
    g_ci_xrefs_interface_tab(in_cnt).country                    := NULL;                   --��
    g_ci_xrefs_interface_tab(in_cnt).postal_code                := NULL;                   --�X�֔ԍ�
    g_ci_xrefs_interface_tab(in_cnt).address_id                 := NULL;                   --�Z��ID
    g_ci_xrefs_interface_tab(in_cnt).customer_item_number       := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_code);
                                                                                           --�ڋq�i�ڔԍ�
    g_ci_xrefs_interface_tab(in_cnt).item_definition_level_desc := NULL;                   --�i�ڒ�`���x���E�v
    g_ci_xrefs_interface_tab(in_cnt).item_definition_level      := cv_dummy_data_1;        --�i�ڒ�`���x��
    g_ci_xrefs_interface_tab(in_cnt).customer_item_id           := NULL;                   --�ڋq�i��ID
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment1    := NULL;                   --�i�ڃZ�O�����g1
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment2    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment3    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment4    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment5    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment6    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment7    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment8    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment9    := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment10   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment11   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment12   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment13   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment14   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment15   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment16   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment17   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment18   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment19   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment20   := NULL;                   --�i�ڃZ�O�����g
    g_ci_xrefs_interface_tab(in_cnt).inventory_item             := NULL;                   --�i��
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_id          := in_inventory_item_id;   --�i��ID
    g_ci_xrefs_interface_tab(in_cnt).master_organization_name   := NULL;                   --�}�X�^�g�D��
    g_ci_xrefs_interface_tab(in_cnt).master_organization_code   := NULL;                   --�}�X�^�g�D�R�[�h
    g_ci_xrefs_interface_tab(in_cnt).master_organization_id     := gv_f_master_organization_id;
                                                                                           --�}�X�^�g�DID
    g_ci_xrefs_interface_tab(in_cnt).preference_number          := cv_dummy_data_1;        --�D��ԍ�
    g_ci_xrefs_interface_tab(in_cnt).inactive_flag              := cv_dummy_data_2;        --�����t���O
    g_ci_xrefs_interface_tab(in_cnt).attribute_category         := NULL;                   --�����J�e�S��
    g_ci_xrefs_interface_tab(in_cnt).attribute1                 := g_cust_item_work_tab(in_cnt+1)(cn_ship_from_space);
                                                                                           --����1
    g_ci_xrefs_interface_tab(in_cnt).attribute2                 := NULL;                   --����2
    g_ci_xrefs_interface_tab(in_cnt).attribute3                 := NULL;                   --����3
    g_ci_xrefs_interface_tab(in_cnt).attribute4                 := NULL;                   --����4
    g_ci_xrefs_interface_tab(in_cnt).attribute5                 := NULL;                   --����5
    g_ci_xrefs_interface_tab(in_cnt).attribute6                 := NULL;                   --����6
    g_ci_xrefs_interface_tab(in_cnt).attribute7                 := NULL;                   --����7
    g_ci_xrefs_interface_tab(in_cnt).attribute8                 := NULL;                   --����8
    g_ci_xrefs_interface_tab(in_cnt).attribute9                 := NULL;                   --����9
    g_ci_xrefs_interface_tab(in_cnt).attribute10                := NULL;                   --����10
    g_ci_xrefs_interface_tab(in_cnt).attribute11                := NULL;                   --����11
    g_ci_xrefs_interface_tab(in_cnt).attribute12                := NULL;                   --����12
    g_ci_xrefs_interface_tab(in_cnt).attribute13                := NULL;                   --����13
    g_ci_xrefs_interface_tab(in_cnt).attribute14                := NULL;                   --����14
    g_ci_xrefs_interface_tab(in_cnt).attribute15                := NULL;                   --����15
    g_ci_xrefs_interface_tab(in_cnt).error_code                 := NULL;                   --�G���[�R�[�h
    g_ci_xrefs_interface_tab(in_cnt).error_explanation          := NULL;                   --�G���[����
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
  END set_ci_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_insert>
   * Description      : <�f�[�^�o�^����>(A-8)
   ***********************************************************************************/
  PROCEDURE data_insert(
    in_cnt        IN NUMBER,   -- 1.<�f�[�^��>
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_table_name        VARCHAR2(5000);
    lv_key_info          VARCHAR2(5000); --�L�[���
    ln_i                 NUMBER;         --�J�E���^�[
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
    -- ****************************************************
    -- ***  �ڋq�i��OIF/�ڋq�i�ڑ��ݎQ��OIF�o�^����     ***
    -- ****************************************************
--
    --�ڋq�i��OIF�o�^����
    BEGIN
      FORALL ln_i in 1..g_ci_interface_tab.COUNT SAVE EXCEPTIONS
        INSERT INTO mtl_ci_interface VALUES g_ci_interface_tab(ln_i);
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcioif_mstr
                       );
        RAISE global_insert_expt;
    END;
--
    --�ڋq�i�ڑ��ݎQ��OIF�o�^����
    BEGIN
      FORALL ln_i in 1..g_ci_xrefs_interface_tab.COUNT SAVE EXCEPTIONS
        INSERT INTO mtl_ci_xrefs_interface VALUES g_ci_xrefs_interface_tab(ln_i);
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_insert_expt;
    END;
--
  EXCEPTION
    --�o�^��O
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => ct_xxcos_appl_short_name,
                     iv_name               => ct_msg_insert_data_err,
                     iv_token_name1        => cv_tkn_table_name,
                     iv_token_value1       => lv_table_name,
                     iv_token_name2        => cv_tkn_key_data,
                     iv_token_value2       => lv_key_info
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
   * Procedure Name   : <mtl_customer_items_ins>
   * Description      : <�ڋq�i�ڃ}�X�^�̓o�^����>(A-9)
   ***********************************************************************************/
  PROCEDURE mtl_customer_items_ins(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mtl_customer_items_ins'; -- �v���O������
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
    cv_application            CONSTANT VARCHAR2(5)   := 'INV';         -- Application
    cv_program                CONSTANT VARCHAR2(9)   := 'INVCIINT';    -- Program
    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
    cv_argument1              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
    cv_argument2              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument2
    -- *** ���[�J���ϐ� ***
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- ***  �ڋq�i�ڃ}�X�^�o�^����     ***
    -- ***********************************
    --�R���J�����g�N��
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => cv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => cv_argument1,
                       argument2    => cv_argument2
                     );
    IF ( ln_request_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciint_err,
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
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status <> cv_con_status_normal ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciint_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
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
  END mtl_customer_items_ins;
--
  /**********************************************************************************
   * Procedure Name   : <mtl_customer_item_xrefs_ins>
   * Description      : <�ڋq�i�ڑ��ݎQ�ƃ}�X�^�̓o�^����>(A-10)
   ***********************************************************************************/
  PROCEDURE mtl_customer_item_xrefs_ins(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mtl_customer_item_xrefs_ins'; -- �v���O������
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
    cv_application            CONSTANT VARCHAR2(3)   := 'INV';         -- Application
    cv_program                CONSTANT VARCHAR2(9)   := 'INVCIINTX';   -- Program
    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
    cv_argument1              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
    cv_argument2              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument2
    -- *** ���[�J���ϐ� ***
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- *******************************************
    -- ***  �ڋq�i�ڑ��ݎQ�ƃ}�X�^�o�^����     ***
    -- *******************************************
    --�R���J�����g�N��
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => cv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => cv_argument1,
                       argument2    => cv_argument2
                     );
    IF ( ln_request_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciintx_err,
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
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/01 1.7 T.Tominaga MOD END   ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status <> cv_con_status_normal ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciintx_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
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
  END mtl_customer_item_xrefs_ins;
--
  /**********************************************************************************
   * Procedure Name   : <data_delete>
   * Description      : <�f�[�^�폜����>
   ***********************************************************************************/
  PROCEDURE data_delete(
    in_file_id    IN  NUMBER  , -- ���̓p�����[�^��FILE_ID
    ov_errbuf     OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_customer_number        VARCHAR2(30);  --�ڋq�R�[�h
    lv_tab_name               VARCHAR2(100); --�e�[�u����
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^    ***
    TYPE l_customer_number_ttype IS TABLE OF mtl_ci_interface.customer_number%TYPE INDEX BY PLS_INTEGER; --�ڋq�i��OIF
    -- *** ���[�J��PL/SQL�\   ***
    l_customer_number_tab     l_customer_number_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- *******************************************************
  -- ***  �ڋq�i��OIF/�ڋq�i�ڑ��ݎQ��OIF�f�[�^�폜����  ***
  -- *******************************************************
    --
    ------------------------------------
    -- 1.�ڋq�i��OIF�f�[�^�폜����
    ------------------------------------
    --
    ------------------------------------
    -- �ڋq�R�[�h�̎擾(���b�N)
    ------------------------------------
    BEGIN
    --
      SELECT
        mci.customer_number             customer_number     --�ڋq�R�[�h
      BULK COLLECT INTO
        l_customer_number_tab
      FROM mtl_ci_interface mci
      WHERE mci.request_id              = cn_request_id     --�v��ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN global_data_lock_expt THEN
        --***** �t�@�C��ID�̎擾�n���h��(7.�t�@�C��ID�̎擾(���b�N))
        lv_tab_name := xxccp_common_pkg.get_msg(
                          iv_application => ct_xxcos_appl_short_name,
                          iv_name        => ct_msg_get_mcioif_mstr
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- �f�[�^�폜
    ------------------------------------
    BEGIN
    --
      DELETE FROM mtl_ci_interface      mci
      WHERE mci.request_id              = cn_request_id    --�v��ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcioif_mstr
                       );
        RAISE global_del_order_data_expt;
      --
    END;
    --
    --------------------------------------
    -- 2.�ڋq�i�ڑ��ݎQ��OIF�f�[�^�폜����
    --------------------------------------
    --
    ------------------------------------
    -- �ڋq�R�[�h�̎擾(���b�N)
    ------------------------------------
    BEGIN
    --
      SELECT
        mci.customer_number             customer_number     --�ڋq�R�[�h
      BULK COLLECT INTO
        l_customer_number_tab
      FROM mtl_ci_xrefs_interface       mci
      WHERE mci.request_id              = cn_request_id     --�v��ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN global_data_lock_expt THEN
        --***** �t�@�C��ID�̎擾�n���h��(7.�t�@�C��ID�̎擾(���b�N))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- �f�[�^�폜
    ------------------------------------
    --
    BEGIN
    --
      DELETE FROM mtl_ci_xrefs_interface  mci
      WHERE mci.request_id                = cn_request_id  --�v��ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_del_order_data_expt;
    END;
  --
  EXCEPTION
    --***** �v���t�@�C���擾��O�n���h��(XXCOS:�ڋq�i�ڃf�[�^�ێ����Ԃ̎擾)
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_profile_err,
                     iv_token_name1  => cv_tkn_profile,
                     iv_token_value1 => lv_tab_name
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
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
  END data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<�t�H�[�}�b�g�p�^�[��>
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_line_number           VARCHAR2(128);  -- 1.<�sNo.>
    ln_cust_account_id       NUMBER;         -- 2.<�ڋqID>
    lv_account_number        VARCHAR2(30);   -- 3.<�ڋq�R�[�h>
    lv_account_number2       VARCHAR2(30);   -- 3.<�ڋq�R�[�h>
    lv_customer_class_code   VARCHAR2(30);   -- 4.<�ڋq�敪>
    lv_duns_number_c         VARCHAR2(30);   -- 5.<�ڋq�X�e�[�^�X>
    lv_cust_item             VARCHAR2(128);  -- 6.<�ڋq�i��>
    lv_cust_item_summary     VARCHAR2(300);  -- 7.<�ڋq�i�ړE�v>
    lv_edi_item_code_div     VARCHAR2(30);   -- 8.<EDI�A�g�i�ڃR�[�h�敪>
    lv_ordering_unit         VARCHAR2(128);  -- 9.<�����P��>
    ln_inventory_item_id     NUMBER;         -- 10.<�i��ID>
    lv_segment1              VARCHAR2(30);   -- 11.<�i�ڃR�[�h>
    lv_uom_code              VARCHAR2(30);   -- 12.<UOM�R�[�h>
    lv_ship_from_space       VARCHAR2(128);  -- 13.<�o�׌��ۊǏꏊ>
    lv_temp_status           VARCHAR2(1);    -- �I���X�e�[�^�X�i�P���R�[�h���p�j
    lv_status                VARCHAR2(1);    -- �I���X�e�[�^�X�i���R�[�h�S�̗p�j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode      := cv_status_normal;
    lv_temp_status  := cv_status_normal;
    lv_status       := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt1 := 0;
    gn_normal_cnt2 := 0;
    gn_error_cnt   := 0;
--
    -- --------------------------------------------------------------------
    -- * para_out         �p�����[�^�o�͏���                          (A-0)
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
    -- * get_ci_data      �t�@�C���A�b�v���[�hIF�ڋq�i�ڃf�[�^�̎擾  (A-1)
    -- --------------------------------------------------------------------
    get_ci_data (
      in_file_id          => in_get_file_id,      -- 1.<file_id>
      ov_errbuf           => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode          => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg           => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * init             ��������                                    (A-2)
    -- --------------------------------------------------------------------
    init(
      in_file_id    => in_get_file_id,    -- 1.<file_id>
      iv_get_format => iv_get_format_pat, -- 2.<�t�H�[�}�b�g�p�^�[��>
      ov_errbuf     => lv_errbuf,         -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode    => lv_retcode,        -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg     => lv_errmsg          -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ------------------------------------------------------------------
    -- * cust_item_split �ڋq�i�ڏ��f�[�^�̍��ڕ�������           (A-3)
    -- ------------------------------------------------------------------
    cust_item_split(
      ov_errbuf         => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode        => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg         => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    FOR i IN cn_min_2 .. gn_get_counter_data LOOP
--
      -- ------------------------------------------------------------------
      -- * item_check       ���ڃ`�F�b�N                              (A-4)
      -- ------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                       -- �f�[�^�J�E���^
        iv_get_format           => iv_get_format_pat,       -- �t�@�C���t�H�[�}�b�g
        ov_account_number       => lv_account_number,       -- �ڋq�R�[�h
        ov_errbuf               => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode              => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        --�x�����G���[�����Ƃ��ăC���N�������g
        gn_error_cnt := gn_error_cnt + 1;
        --�x���I���t���O�̐ݒ�
        lv_temp_status := cv_status_warn;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ----------------------------------------------------------------
        -- * get_master_data   �}�X�^���̎擾����                   (A-5)
        -- ----------------------------------------------------------------
        get_master_data(
          iv_get_format               => iv_get_format_pat,    -- �t�H�[�}�b�g�p�^�[��
          iv_account_number           => lv_account_number,    -- �ڋq�R�[�h
          in_line_no                  => i,                    -- �sNO.
          on_cust_account_id          => ln_cust_account_id,   -- �ڋqID
          ov_account_number           => lv_account_number2,   -- �ڋq�R�[�h
          on_inventory_item_id        => ln_inventory_item_id, -- �i��ID
          ov_errbuf                   => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode                  => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                   => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --�x�����G���[�����Ƃ��ăC���N�������g
          gn_error_cnt := gn_error_cnt + 1;
          --�x���I���t���O�̐ݒ�
          lv_temp_status := cv_status_warn;
        END IF;
      --
      END IF;
--
      -- ------------------------------------------------------------------
      -- * data_check      ������o�^�ς݃f�[�^�`�F�b�N����         (A-6)
      -- ------------------------------------------------------------------
      IF ( lv_retcode = cv_status_normal ) THEN
        data_check(
          in_cnt                => i,            -- �sNO.
          ov_errbuf             => lv_errbuf,    -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode            => lv_retcode,   -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg             => lv_errmsg     -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --�x�����G���[�����Ƃ��ăC���N�������g
          gn_error_cnt := gn_error_cnt + 1;
          --�x���I���t���O�̐ݒ�
          lv_temp_status := cv_status_warn;
        END IF;
      --
      END IF;
--
      -- ------------------------------------------------------------------
      -- * set_ci_data       �f�[�^�ݒ菈��                           (A-7)
      -- ------------------------------------------------------------------
      IF ( lv_retcode = cv_status_normal ) THEN
        --
        set_ci_data(
          in_cnt                   => i-1,                   -- 1.<�f�[�^��>
          in_cust_account_id       => ln_cust_account_id,    -- 2.<�ڋqID>
          iv_account_number        => lv_account_number2,    -- 3.<�ڋq�R�[�h>
          in_inventory_item_id     => ln_inventory_item_id,  -- 4.<�i��ID>
          ov_errbuf                => lv_errbuf,   -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,  -- 2.���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg    -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      --���b�Z�[�W���s����
      IF ( lv_temp_status = cv_status_warn ) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => NULL
        );
        lv_status := cv_status_warn;
        lv_temp_status := cv_status_normal;
      END IF;
    END LOOP;
--
    -- ------------------------------------------------------------------
    -- * data_insert       �f�[�^�o�^����                           (A-8)
    -- ------------------------------------------------------------------
    IF ( lv_status = cv_status_normal ) THEN
      data_insert(
        in_cnt      => gn_get_counter_data, -- 1.<�f�[�^��>
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ------------------------------------------------------------------
    -- * mtl_customer_items_ins       �ڋq�i�ڃ}�X�^�̓o�^����     (A-9)
    -- ------------------------------------------------------------------
    IF ( ( lv_status = cv_status_normal )
      AND ( lv_retcode = cv_status_normal ) )
    THEN
      mtl_customer_items_ins(
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --�����������Z�b�g
        gn_normal_cnt1 := gn_target_cnt;
      END IF;
    END IF;
--
    -- ---------------------------------------------------------------------
    -- * mtl_customer_item_xrefs_ins �ڋq�i�ڑ��ݎQ�ƃ}�X�^�̓o�^���� (A-10)
    -- ---------------------------------------------------------------------
    IF ( ( lv_status = cv_status_normal )
      AND ( lv_retcode = cv_status_normal ) )
    THEN
      mtl_customer_item_xrefs_ins(
        ov_errbuf   => lv_errbuf,           -- 1.�G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,          -- 2.���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg            -- 3.���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --�����������Z�b�g
        gn_normal_cnt2 := gn_target_cnt;
      END IF;
    END IF;
--
    ov_retcode := lv_status;
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
    errbuf            OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg1 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11320'; -- �����������b�Z�[�W(�ڋq�i�ڃ}�X�^)
    cv_success_rec_msg2 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11321'; -- �����������b�Z�[�W(�ڋq�i�ڑ��ݎQ�ƃ}�X�^)
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token        CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out   CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log   CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --
      -- ===============================================
      -- data_delete       �f�[�^�폜����
      -- ===============================================
      data_delete(
        in_file_id  => in_get_file_id,  -- FILE_ID
        ov_errbuf   => lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        --�R�~�b�g
        COMMIT;
        lv_retcode := cv_status_error; --submain�̖߂�l�ɖ߂�
      ELSE
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
    END IF;
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT,
--        buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
--    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --���������o�́i�ڋq�i�ڃ}�X�^�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => cv_success_rec_msg1,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt1 )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --���������o�́i�ڋq�i�ڑ��ݎQ�ƃ}�X�^�j
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => cv_success_rec_msg2,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt2 )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    --�X�e�[�^�X���G���[�̏ꍇ�̓G���[�������P�Ƃ���
    IF ( lv_retcode = cv_status_error ) THEN
       gn_error_cnt := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
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
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    errbuf  := lv_errbuf;
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
END XXCOS005A09C;
/
