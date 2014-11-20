CREATE OR REPLACE PACKAGE BODY XXCMM003A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMM003A41C(body)
 * Description      : �ڋq�֘A�ꊇ�X�V
 * MD.050           : �ڋq�֘A�ꊇ�X�V MD050_CMM_003_A41
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  validate_cust_wrel     �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�Ó����`�F�b�N(A-4)
 *  proc_party_rel_inact   �p�[�e�B�֘A�������f�[�^�X�V����(A-5)
 *  proc_party_rel_active  �p�[�e�B�֘A�L�����f�[�^�o�^����(A-6)
 *  proc_cust_rel_inact    �ڋq�֘A�������f�[�^�X�V����(A-7)
 *  proc_cust_rel_active   �ڋq�֘A�L�����f�[�^�o�^����(A-8)
 *  loop_main              �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�擾(A-3)
 *  get_if_data            �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-2)
 *  proc_comp              �I������(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/26    1.0   M.Takasaki       �V�K�쐬
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
  --*** ���b�N�G���[��O ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';           -- �A�v���P�[�V�����Z�k��
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM003A41C';    -- �p�b�P�[�W��
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';               -- �J���}
  -- �e��R�[�h�l
  cv_file_format_pa      CONSTANT VARCHAR2(3)   := '505';             -- �t�@�C���t�H�[�}�b�g:�p�[�e�B�֘A
  cv_file_format_cu      CONSTANT VARCHAR2(3)   := '506';             -- �t�@�C���t�H�[�}�b�g:�ڋq�֘A
  --
  cv_cu_customer         CONSTANT VARCHAR2(2)   := '10';              -- �ڋq�敪:�ڋq
  cv_cu_trust_corp       CONSTANT VARCHAR2(2)   := '13';              -- �ڋq�敪:�@�l�Ǘ���
  cv_cu_ar_manage        CONSTANT VARCHAR2(2)   := '14';              -- �ڋq�敪:���|�Ǘ���ڋq
  --
  cv_rel_bill            CONSTANT VARCHAR2(1)   := '1';               -- �֘A����:���� �R�[�h
  cv_rel_bill_name       CONSTANT VARCHAR2(10)  := '�����֘A';        -- �֘A����:���� ����
  cv_rel_cash            CONSTANT VARCHAR2(1)   := '2';               -- �֘A����:���� �R�[�h
  cv_rel_cash_name       CONSTANT VARCHAR2(10)  := '�����֘A';        -- �֘A����:���� ����
  --
  cv_active_csv          CONSTANT VARCHAR2(1)   := 'Y';               -- �o�^�X�e�[�^�X:�L��(CSV)
  cv_active_set          CONSTANT VARCHAR2(1)   := 'A';               -- �o�^�X�e�[�^�X:�L��(�ݒ�l)
  cv_inactive_csv        CONSTANT VARCHAR2(1)   := 'N';               -- �o�^�X�e�[�^�X:����(CSV)
  cv_inactive_set        CONSTANT VARCHAR2(1)   := 'I';               -- �o�^�X�e�[�^�X:����(�ݒ�l)
  --
  cv_hr_type_org         CONSTANT VARCHAR2(30)  := 'ORGANIZATION';    -- �p�[�e�B�֘A�I�u�W�F�N�g�^�C�v
  cv_hr_table_name       CONSTANT VARCHAR2(30)  := 'HZ_PARTIES';      -- �p�[�e�B�֘A�e�[�u����
  cv_hr_rel_type_credit  CONSTANT VARCHAR2(30)  := '�^�M�֘A';        -- �p�[�e�B�֘A�^�C�v
  cv_hr_rel_code_urikake CONSTANT VARCHAR2(30)  := '���|�Ǘ���';      -- �p�[�e�B�֘A�R�[�h
  --
  cv_lookup_yes          CONSTANT VARCHAR2(1)   := 'Y';               -- LOOKUP�\ YES
  cv_site_use_bill_to    CONSTANT VARCHAR2(10)  := 'BILL_TO';         -- �g�p�ړI:'������'
  cv_site_use_ship_to    CONSTANT VARCHAR2(10)  := 'SHIP_TO';         -- �g�p�ړI:'�o�א�'
  cv_acc_yes             CONSTANT VARCHAR2(1)   := 'Y';
  cv_acc_no              CONSTANT VARCHAR2(1)   := 'N';
  cv_relationship_type_all    hz_cust_acct_relate.relationship_type%TYPE := 'ALL';
  -- �f�[�^���ڒ�`DECODE�p
  cv_varchar             CONSTANT VARCHAR2(10)  := 'VARCHAR2';                                          -- ������     LOOKUP�\
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := '0';                                                 -- ������     ���ʊ֐��p�R�[�h
  cv_number              CONSTANT VARCHAR2(10)  := 'NUMBER';                                            -- ���l       LOOKUP�\
  cv_number_cd           CONSTANT VARCHAR2(1)   := '1';                                                 -- ���l       ���ʊ֐��p�R�[�h
  cv_date                CONSTANT VARCHAR2(10)  := 'DATE';                                              -- ���t       LOOKUP�\
  cv_date_cd             CONSTANT VARCHAR2(1)   := '2';                                                 -- ���t       ���ʊ֐��p�R�[�h
  cv_not_null            CONSTANT VARCHAR2(1)   := '1';                                                 -- �K�{�t���O LOOKUP�\
  cv_null_ok             CONSTANT VARCHAR2(10)  := 'NULL_OK';                                           -- �C�Ӎ���   ���ʊ֐��p�R�[�h
  cv_null_ng             CONSTANT VARCHAR2(10)  := 'NULL_NG';                                           -- �K�{����   ���ʊ֐��p�R�[�h
  -- �v���t�@�C����
  cv_prf_org_id          CONSTANT VARCHAR2(10)  := 'ORG_ID';                                            -- MO:�c�ƒP�ʎ擾�p�R�[�h
  cv_prf_item_num_cu     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A41_CUST_REL_NUM';                        -- �v���t�@�C���u�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�ڋq�֘A�j�v
  cv_prf_item_num_pa     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A41_PARTY_REL_NUM';                       -- �v���t�@�C���u�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�p�[�e�B�֘A�j�v
  --  LOOKUP�\
  cv_lookup_file_up_obj  CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';                            -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_lookup_curel_def_pa CONSTANT VARCHAR2(30)  := 'XXCMM1_003A41_PARTY_REL_DEF';                       -- LOOKUP:�ڋq�֘A�ꊇ�X�V�f�[�^���ڒ�`(�p�[�e�B�֘A)
  cv_lookup_curel_def_cu CONSTANT VARCHAR2(30)  := 'XXCMM1_003A41_CUST_REL_DEF';                        -- LOOKUP:�ڋq�֘A�ꊇ�X�V�f�[�^���ڒ�`(�ڋq�֘A)
  cv_lookup_relate_class CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KANREN_BUNRUI';                          -- LOOKUP:�ڋq�֘A�ꊇ�X�V�f�[�^���ڒ�`(�p�[�e�B�֘A)
  --  ���b�Z�[�W
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                                  -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00008     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';                                  -- ���b�N�G���[
  cv_msg_xxcmm_00012     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';                                  -- �e�[�u���폜�G���[
  cv_msg_xxcmm_00018     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';                                  -- �Ɩ����t�擾�G���[
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                                  -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                                  -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                                  -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                                  -- �t�H�[�}�b�g�m�[�g
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                                  -- �f�[�^���ڐ��G���[
  cv_msg_xxcmm_10323     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10323';                                  -- �p�����[�^NULL�G���[
  cv_msg_xxcmm_10324     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10324';                                  -- �擾���s�G���[
  cv_msg_xxcmm_10328     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10328';                                  -- �l�`�F�b�N�G���[
  cv_msg_xxcmm_10330     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10330';                                  -- �Q�ƃR�[�h���݃`�F�b�N�G���[
  cv_msg_xxcmm_10335     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10335';                                  -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_10337     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10337';                                  -- IF���b�N�擾�G���[
  cv_msg_xxcmm_10338     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10338';                                  -- ���ڒ�`�G���[
  cv_msg_xxcmm_10347     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10347';                                  -- �ڋq�}�X�^�`�F�b�N�G���[
  cv_msg_xxcmm_10348     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10348';                                  -- CSV���e�d���G���[
  cv_msg_xxcmm_10349     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10349';                                  -- �p�[�e�B�֘A�������`�F�b�N�G���[
  cv_msg_xxcmm_10350     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10350';                                  -- �p�[�e�B�֘A�L�����������`�F�b�N�G���[
  cv_msg_xxcmm_10351     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10351';                                  -- �p�[�e�B�֘A�L�����`�F�b�N�G���[
  cv_msg_xxcmm_10352     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10352';                                  -- �ڋq�֘A�������`�F�b�N�G���[
  cv_msg_xxcmm_10353     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10353';                                  -- �ڋq�֘A�L�����`�F�b�N�G���[
  cv_msg_xxcmm_10354     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10354';                                  -- �W��API�G���[
  cv_msg_xxcmm_10355     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10355';                                  -- �֘A�K�p���`�F�b�N�G���[
  -- �g�[�N����
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                            -- �t�@�C��ID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                             -- �t�H�[�}�b�g
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                         -- �v���t�@�C����
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                        -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                          -- �t�@�C����
  cv_tkn_param_name      CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                                         -- �p�����[�^��
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                              -- �l
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                              -- �e�[�u��
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                              -- ����
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                      -- �s�ԍ�
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                              -- ����
  cv_tkn_cust_class      CONSTANT VARCHAR2(20)  := 'CUST_CLASS';                                         -- �ڋq�敪
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                                          -- �ڋq�R�[�h
  cv_tkn_rep_cont        CONSTANT VARCHAR2(20)  := 'REP_CONT';                                           -- �d�����e
  cv_tkn_rel_cust_code   CONSTANT VARCHAR2(20)  := 'REL_CUST_CODE';                                      -- �֘A��ڋq�R�[�h
  cv_tkn_apply_date      CONSTANT VARCHAR2(20)  := 'APPLY_DATE';                                         -- �֘A�K�p��
  cv_tkn_rel_cls_name    CONSTANT VARCHAR2(20)  := 'REL_CLS_NAME';                                       -- �֘A���ޖ���
  cv_tkn_api_step        CONSTANT VARCHAR2(20)  := 'API_STEP';                                           -- API �����X�e�b�v��
  cv_tkn_api_name        CONSTANT VARCHAR2(20)  := 'API_NAME';                                           -- API ������
  cv_tkn_seq_num         CONSTANT VARCHAR2(20)  := 'SEQ_NUM';                                            -- �V�[�P���X�ԍ�
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                            -- �G���[���e
  cv_tkn_ng_table        CONSTANT VARCHAR2(20)  := 'NG_TABLE';                                           -- ���b�N�擾NG�e�[�u����
  -- �g�[�N���l
  --
  cv_tkv_file_id         CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkv_format          CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';
  --
  cv_tkv_prf_item_num_cu CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ�(�ڋq�֘A)';       -- �v���t�@�C���u�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�ڋq�֘A�j�v����
  cv_tkv_prf_item_num_pa CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ�(�p�[�e�B�֘A)';   -- �v���t�@�C���u�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�p�[�e�B�֘A�j�v����
  cv_tkv_prf_org_id      CONSTANT VARCHAR2(30)  := 'MO:�c�ƒP��';                                        -- MO:�c�ƒP��
  --
  cv_tkv_rel_def         CONSTANT VARCHAR2(40)  := '�ڋq�֘A�ꊇ�X�V���[�N��`���';
  cv_tkv_upload_name     CONSTANT VARCHAR2(40)  := '�t�@�C���A�b�v���[�h����';
  cv_tkv_table_xwk_cust  CONSTANT VARCHAR2(40)  := '�ڋq�֘A�ꊇ�X�V���[�N';
  cv_tkv_table_file_if   CONSTANT VARCHAR2(40)  := '�t�@�C���A�b�v���[�hIF';
  cv_tkv_cu_class_code   CONSTANT VARCHAR2(40)  := '�ڋq�敪';
  cv_tkv_recu_class_code CONSTANT VARCHAR2(40)  := '�֘A��ڋq�敪';
  cv_tkv_status          CONSTANT VARCHAR2(40)  := '�o�^�X�e�[�^�X';
  cv_tkv_relate_class    CONSTANT VARCHAR2(40)  := '�ڋq�֘A����';
  cv_tkv_rep_cont_pa     CONSTANT VARCHAR2(40)  := '�֘A��ڋq,�o�^�X�e�[�^�X';                          -- CSV�d�����e�F�p�[�e�B�֘A
  cv_tkv_rep_cont_cu1    CONSTANT VARCHAR2(40)  := '�֘A��ڋq,�o�^�X�e�[�^�X,�ڋq�֘A����';             -- CSV�d�����e�F�ڋq�֘A1
  cv_tkv_rep_cont_cu2    CONSTANT VARCHAR2(40)  := '�֘A��ڋq,�o�^�X�e�[�^�X,�ڋq';                     -- CSV�d�����e�F�ڋq�֘A2
  cv_tkv_lock_party      CONSTANT VARCHAR2(30)  := '�p�[�e�B';                                           -- ���b�N�e�[�u��
  cv_tkv_lock_party_rel  CONSTANT VARCHAR2(30)  := '�p�[�e�B�֘A';                                       -- ���b�N�e�[�u��
  cv_tkv_lock_cust_rel   CONSTANT VARCHAR2(30)  := '�ڋq�֘A';                                           -- ���b�N�e�[�u��
  cv_tkv_lock_cust_site  CONSTANT VARCHAR2(30)  := '�ڋq�T�C�g';                                         -- ���b�N�e�[�u��
  cv_tkv_lock_cust_uses  CONSTANT VARCHAR2(30)  := '�ڋq���Ə�';                                         -- ���b�N�e�[�u��
  cv_tkv_apinm_pa_get    CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.get_relationship_rec';         -- �W��API�F�p�[�e�B�֘A�擾
  cv_tkv_apinm_pa_upload CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.update_relationship';          -- �W��API�F�p�[�e�B�֘A�X�V
  cv_tkv_apinm_pa_create CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.create_relationship';          -- �W��API�F�p�[�e�B�֘A�o�^
  cv_tkv_apinm_cu_get    CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.get_cust_acct_relate_rec';     -- �W��API�F�ڋq�֘A�擾
  cv_tkv_apinm_cu_upload CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.update_cust_acct_relate';      -- �W��API�F�ڋq�֘A�X�V
  cv_tkv_apinm_cu_create CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.create_cust_acct_relate';      -- �W��API�F�ڋq�֘A�o�^
  cv_tkv_apinm_suse_get  CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.get_cust_site_use_rec';   -- �W��API�F�ڋq�g�p�ړI���R�[�h�擾
  cv_tkv_apinm_suse_upld CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.update_cust_site_use';    -- �W��API�F�ڋq�g�p�ړI���R�[�h�X�V
  cv_tkv_apist_pa_get    CONSTANT VARCHAR2(30)  := '�p�[�e�B�֘A�擾';                                   -- �W��API�F�p�[�e�B�֘A�擾
  cv_tkv_apist_pa_upload CONSTANT VARCHAR2(30)  := '�p�[�e�B�֘A�X�V';                                   -- �W��API�F�p�[�e�B�֘A�X�V
  cv_tkv_apist_pa_create CONSTANT VARCHAR2(30)  := '�p�[�e�B�֘A�o�^';                                   -- �W��API�F�p�[�e�B�֘A�o�^
  cv_tkv_apist_cu_get    CONSTANT VARCHAR2(30)  := '�ڋq�֘A�擾';                                       -- �W��API�F�ڋq�֘A�擾
  cv_tkv_apist_cu_upload CONSTANT VARCHAR2(30)  := '�ڋq�֘A�X�V';                                       -- �W��API�F�ڋq�֘A�X�V
  cv_tkv_apist_cu_create CONSTANT VARCHAR2(30)  := '�ڋq�֘A�o�^';                                       -- �W��API�F�ڋq�֘A�o�^
  cv_tkv_apist_suse_get  CONSTANT VARCHAR2(30)  := '�ڋq�g�p�ړI�擾';                                   -- �W��API�F�ڋq�g�p�ړI���R�[�h�擾
  cv_tkv_apist_suse_upld CONSTANT VARCHAR2(30)  := '�ڋq�g�p�ړI�X�V';                                   -- �W��API�F�ڋq�g�p�ړI���R�[�h�X�V
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڒ�`�̏��
  TYPE g_item_def_rtype IS RECORD(
       item_name            VARCHAR2(100)                                                                -- ���ږ�
     , item_attribute       VARCHAR2(100)                                                                -- ���ڑ���
     , item_essential       VARCHAR2(100)                                                                -- �K�{�t���O
     , int_length           NUMBER                                                                       -- ���ڂ̒���(��������)
     , dec_length           NUMBER                                                                       -- ���ڂ̒���(�����_�ȉ�)
  );
  TYPE g_item_def_ttype  IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;
  --
  -- �L�����E�������p�̃L�[���
  TYPE g_keys_in_act_rtype IS RECORD(
       cust_class_code        xxcmm_wk_cust_relate_upload.customer_class_code%TYPE                       -- �֘A�� �ڋq�敪
     , cust_code              xxcmm_wk_cust_relate_upload.customer_code%TYPE                             -- �֘A�� �ڋq�R�[�h
     , cust_party_id          hz_parties.party_id%TYPE                                                   -- �֘A�� �p�[�e�BID
     , cust_account_id        hz_cust_accounts.cust_account_id%TYPE                                      -- �֘A�� �ڋq�A�J�E���gID
     , rel_cust_class_code    xxcmm_wk_cust_relate_upload.rel_customer_class_code%TYPE                   -- �֘A�� �ڋq�敪
     , rel_cust_code          xxcmm_wk_cust_relate_upload.rel_customer_code%TYPE                         -- �֘A�� �ڋq�R�[�h
     , rel_cust_party_id      hz_parties.party_id%TYPE                                                   -- �֘A�� �p�[�e�BID
     , rel_cust_account_id    hz_cust_accounts.cust_account_id%TYPE                                      -- �֘A�� �ڋq�A�J�E���gID
     , relate_class           xxcmm_wk_cust_relate_upload.relate_class%TYPE                              -- �ڋq�֘A����
     , rel_apply_date         xxcmm_wk_cust_relate_upload.relate_apply_date%TYPE                         -- �֘A�K�p��
     , line_no                xxcmm_wk_cust_relate_upload.line_no%TYPE                                   -- �s�ԍ�
  );
  TYPE g_keys_ia_ttype   IS TABLE OF g_keys_in_act_rtype   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                    NUMBER;                            -- �p�����[�^�i�[�p�ϐ�:�t�@�C��ID
  gv_format                     VARCHAR2(100);                     -- �p�����[�^�i�[�p�ϐ�:�t�H�[�}�b�g�p�^�[��
  gd_process_date               DATE;                              -- �Ɩ����t
  gd_system_date                DATE;                              -- �V�X�e�����t
  gn_item_num                   NUMBER;                            -- �ڋq�֘A�ꊇ�X�V�f�[�^���ڐ�
  gv_org_id                     VARCHAR2(50);                      -- MO:�c�ƒP��
  gn_inact_cnt                  NUMBER;                            -- �������p�̃L�[Index
  gn_active_cnt                 NUMBER;                            -- �L�����p�̃L�[Index
--
  --�e�[�u���`
  g_cust_rel_def_tab            g_item_def_ttype;                  -- �e�[�u���^�ϐ��̐錾
  g_inact_keys_tab              g_keys_ia_ttype;                   -- �e�[�u���^�ϐ��̐錾(�������p�̃L�[�ޔ�)
  g_act_keys_tab                g_keys_ia_ttype;                   -- �e�[�u���^�ϐ��̐錾(�L�����p�̃L�[�ޔ�)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    -- �ڋq�֘A�ꊇ�X�V�p���[�N �擾
    CURSOR get_wk_cust_rel_cur
    IS
      SELECT xwcup.file_id                  AS file_id                 -- �t�@�C��ID
           , xwcup.line_no                  AS line_no                 -- �s�ԍ�
           , xwcup.customer_class_code      AS cust_class_code         -- �ڋq�敪
           , xwcup.customer_code            AS cust_code               -- �ڋq�R�[�h
           , xwcup.rel_customer_class_code  AS rel_cust_class_code     -- �֘A��ڋq�敪
           , xwcup.rel_customer_code        AS rel_cust_code           -- �֘A��ڋq�R�[�h
           , xwcup.relate_class             AS relate_class            -- �ڋq�֘A����
           , xwcup.status                   AS status                  -- �o�^�X�e�[�^�X
           , xwcup.relate_apply_date        AS rel_apply_date          -- �֘A�K�p��
           , xwcup.created_by               AS created_by              -- WHO:�쐬��
           , xwcup.creation_date            AS creation_date           -- WHO:�쐬��
           , xwcup.last_updated_by          AS last_updated_by         -- WHO:�ŏI�X�V��
           , xwcup.last_update_date         AS last_update_date        -- WHO:�ŏI�X�V��
           , xwcup.last_update_login        AS last_update_login       -- WHO:�ŏI�X�V���O�C��
           , xwcup.request_id               AS request_id              -- WHO:�v��ID
           , xwcup.program_application_id   AS program_application_id  -- WHO:�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           , xwcup.program_id               AS program_id              -- WHO:�R���J�����g�E�v���O����ID
           , xwcup.program_update_date      AS program_update_date     -- WHO:�v���O�����X�V��
        FROM xxcmm_wk_cust_relate_upload xwcup     -- �ڋq�֘A�ꊇ�X�V�p���[�N
       WHERE xwcup.request_id = cn_request_id      -- �v��ID
      ORDER BY xwcup.line_no                       -- �s�ԍ�
      ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2          -- �t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                                    -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    ln_cnt                    NUMBER;                                           -- �J�E���^
    lv_upload_obj             VARCHAR2(100);                                    -- �t�@�C���A�b�v���[�h����
    -- �t�@�C���A�b�v���[�hIF�e�[�u������
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- �t�@�C�����i�[�p
    lt_created_by             xxccp_mrp_file_ul_interface.created_by%TYPE;      -- �쐬�Ҋi�[�p
    lt_creation_date          xxccp_mrp_file_ul_interface.creation_date%TYPE;   -- �쐬���i�[�p
    -- IN�p�����[�^�o�͗p
    lv_up_name                VARCHAR2(1000);                                   -- �A�b�v���[�h����
    lv_file_name              VARCHAR2(1000);                                   -- �t�@�C����
    lv_file_id                VARCHAR2(1000);                                   -- �t�@�C��ID
    lv_file_format            VARCHAR2(1000);                                   -- �t�H�[�}�b�g
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR     get_cust_rel_def_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- ���e
              ,DECODE(flv.attribute1
                    , cv_varchar ,cv_varchar_cd
                    , cv_number  ,cv_number_cd
                    , cv_date_cd)                  AS item_attribute            -- ���ڑ���
              ,DECODE(flv.attribute2
                    , cv_not_null, cv_null_ng
                    , cv_null_ok)                  AS item_essential            -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)           AS int_length                -- ���ڂ̒���(��������)
              ,TO_NUMBER(flv.attribute4)           AS dec_length                -- ���ڂ̒���(�����_�ȉ�)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP�\
      WHERE  (
               ( -- �t�H�[�}�b�g�p�^�[���u�p�[�e�B�֘A�v�̏ꍇ
                      gv_format       = cv_file_format_pa  
                 AND flv.lookup_type  = cv_lookup_curel_def_pa
               ) OR
               ( -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v�̏ꍇ
                     gv_format        = cv_file_format_cu 
                 AND flv.lookup_type  = cv_lookup_curel_def_cu
               )
             )
      AND      flv.enabled_flag = cv_lookup_yes                                 -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- �K�p�I����
      ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;                              -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;                              -- �v���t�@�C���擾�G���[
    process_date_expt         EXCEPTION;                              -- �Ɩ����t�擾���s�G���[
    select_expt               EXCEPTION;                              -- �擾���s�G���[
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
    -- A-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j��NULL�`�F�b�N
    --==============================================================
    lv_step := 'A-1.1';
    -- ���̓p�����[�^.FILE_ID��NULL�̏ꍇ
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_tkv_file_id;
      RAISE get_param_expt;
    END IF;
    -- ���̓p�����[�^.�t�H�[�}�b�g��NULL�̏ꍇ
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_tkv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 �v���t�@�C���擾
    --==============================================================
    lv_step := 'A-1.2';
    -- �t�H�[�}�b�g�p�^�[���u�p�[�e�B�֘A�v�̏ꍇ
    IF ( gv_format = cv_file_format_pa ) THEN
      -- XXCMM:�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�p�[�e�B�֘A�j
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_pa));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_tkv_prf_item_num_pa;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v�̏ꍇ
    IF ( gv_format = cv_file_format_cu ) THEN
      -- XXCMM:�ڋq�֘A�ꊇ�X�V�f�[�^���ڐ��i�ڋq�֘A�j
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_cu));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_tkv_prf_item_num_cu;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    --MO:�c�ƒP�� �擾
    gv_org_id := FND_PROFILE.VALUE( cv_prf_org_id );
    IF ( gv_org_id IS NULL ) THEN
      lv_tkn_value := cv_tkv_prf_org_id;
      RAISE get_profile_expt;
    END IF;
    --==============================================================
    -- A-1.3 �Ɩ����t�擾
    --==============================================================
    lv_step := 'A-1.3';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULL�`�F�b�N
    IF ( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.4 �ڋq�֘A�ꊇ�X�V���[�N��`���̎擾
    --==============================================================
    lv_step := 'A-1.4';
    -- �J�E���^�[������
    ln_cnt := 0;
    -- �e�[�u����`�擾LOOP
    <<rel_def_loop>>
    FOR get_cust_rel_def_rec IN get_cust_rel_def_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_cust_rel_def_tab(ln_cnt).item_name      := get_cust_rel_def_rec.item_name;       -- ���ږ�
      g_cust_rel_def_tab(ln_cnt).item_attribute := get_cust_rel_def_rec.item_attribute;  -- ���ڑ���
      g_cust_rel_def_tab(ln_cnt).item_essential := get_cust_rel_def_rec.item_essential;  -- �K�{�t���O
      g_cust_rel_def_tab(ln_cnt).int_length     := get_cust_rel_def_rec.int_length;      -- ���ڂ̒���(��������)
      g_cust_rel_def_tab(ln_cnt).dec_length     := get_cust_rel_def_rec.dec_length;      -- ���ڂ̒���(�����_�ȉ�)
    END LOOP rel_def_loop
    ;
    IF ( ln_cnt = 0 ) THEN
      lv_tkn_value := cv_tkv_rel_def;
      RAISE select_expt;
    END IF;
    --
    --==============================================================
    -- A-1.5 �t�@�C���A�b�v���[�h���̎擾
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT flv.meaning      AS meaning
        INTO lv_upload_obj
        FROM fnd_lookup_values_vl flv                                         -- LOOKUP�\
       WHERE flv.lookup_type  = cv_lookup_file_up_obj                         -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
         AND flv.lookup_code  = gv_format                                     -- �t�@�C���t�H�[�}�b�g
         AND flv.enabled_flag = cv_lookup_yes                                 -- �g�p�\�t���O
         AND NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
         AND NVL(flv.end_date_active  , gd_process_date) >= gd_process_date   -- �K�p�I����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_tkv_upload_name;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.6 �ڋq�֘A�ꊇ�X�V�p�b�r�u�t�@�C�����擾
    --==============================================================
    lv_step := 'A-1.6';
    SELECT   fui.file_name      AS file_name                                    -- �t�@�C����
            ,fui.created_by     AS created_by                                   -- �쐬��
            ,fui.creation_date  AS creation_date                                -- �쐬��
    INTO     lt_csv_file_name
            ,lt_created_by
            ,lt_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                                   -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE    fui.file_id           = gn_file_id                                 -- �t�@�C��ID
      AND    fui.file_content_type = gv_format                                  -- �t�@�C���t�H�[�}�b�g
    FOR UPDATE NOWAIT
    ;
    --
    --==============================================================
    -- A-1.7 IN�p�����[�^�̏o��
    --==============================================================
    lv_step := 'A-1.7';
    -- �t�@�C���A�b�v���[�h����
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00021                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_upload_obj                        -- �g�[�N���l1
                      );
    -- CSV�t�@�C����
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- CSV�t�@�C�����̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00022                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name                     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lt_csv_file_name                     -- �g�[�N���l1
                      );
    -- �t�@�C��ID
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00023                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- �g�[�N���l1
                      );
    -- �t�H�[�}�b�g�p�^�[��
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format                    -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format                             -- �g�[�N���l1
                      );
    -- �o�͂ɕ\��
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    -- ���O�ɕ\��
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10323            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �Ɩ����t�擾���s�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00018            -- ���b�Z�[�W
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �擾���s�G���[ ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10324            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10337            -- ���b�Z�[�W
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
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
   * Procedure Name   : validate_cust_wrel
   * Description      : �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE validate_cust_wrel(
    i_cust_rel_rec     IN  get_wk_cust_rel_cur%ROWTYPE,       -- �ڋq�֘A�ꊇ�X�V�p���[�N���
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  -- # �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h                    -- # �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_cust_wrel'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_un_search  CONSTANT VARCHAR2(1) := '0';                       -- CSV�t�@�C�����������f�[�^����:�L
    cv_search     CONSTANT VARCHAR2(1) := '1';                       -- CSV�t�@�C�����������f�[�^����:��
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);
    lv_step_status            VARCHAR2(1);                           -- STEP�`�F�b�N
    lv_check_status           VARCHAR2(1);                           -- �Ó����`�F�b�N�X�e�[�^�X
    ln_chk_cnt                NUMBER;                                -- ���݃`�F�b�N�J�E���g�p
    lv_csv_inact_search       VARCHAR2(1);                           -- CSV�t�@�C�����������f�[�^�����t���O
    lv_rel_cls_name           VARCHAR2(10);                          -- �ڋq�֘A���ޖ���
    lv_char_rel_date          VARCHAR2(10);                          -- YYYY/MM/DD�`���̊֘A�K�p��
    --
    lt_cust_party_id          hz_parties.party_id%TYPE;              -- �֘A�� �p�[�e�BID
    lt_cust_account_id        hz_cust_accounts.cust_account_id%TYPE; -- �֘A�� �ڋq�A�J�E���gID
    lt_rel_cust_party_id      hz_parties.party_id%TYPE;              -- �֘A�� �p�[�e�BID
    lt_rel_cust_account_id    hz_cust_accounts.cust_account_id%TYPE; -- �֘A�� �ڋq�A�J�E���gID
    --
    lv_pa_chk_cust_code       VARCHAR2(9);                           -- �p�[�e�B�֘A�`�F�b�N�p �ŐV�L���ڋq�R�[�h
    ld_pa_chk_start_date      DATE;                                  -- �p�[�e�B�֘A�`�F�b�N�p �ŐV�L���J�n��
    ld_pa_chk_end_date        DATE;                                  -- �p�[�e�B�֘A�`�F�b�N�p �ŐV�L���I����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- *** �ڋq�}�X�^�擾�J�[�\�� *** --
    CURSOR get_cust_id_cur (
      p_customer_class_code  IN VARCHAR2,  -- �ڋq�敪
      p_account_number       IN VARCHAR2   -- �ڋq�R�[�h
    )IS
      SELECT hca.party_id            AS party_id               -- �p�[�e�BID
           , hca.cust_account_id     AS cust_account_id        -- �ڋqID
        FROM hz_cust_accounts hca   --�W��:�ڋq�}�X�^
       WHERE hca.customer_class_code = p_customer_class_code   -- �ڋq�敪
         AND hca.account_number      = p_account_number        -- �ڋq�R�[�h
    ;
    --
    -- *** �p�[�e�B�֘A CSV�d���`�F�b�N�p�J�[�\�� *** --
    CURSOR party_rel_csv_repeat_check_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- �ڋq�֘A�ꊇ�X�V���[�N
       WHERE xwcru.request_id              = cn_request_id                      --  �v��ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  �s�ԍ�
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  �֘A��ڋq�敪
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  �֘A��ڋq�R�[�h
         AND xwcru.status                  = i_cust_rel_rec.status              --  �o�^�X�e�[�^�X
    ;
    --
    -- *** �p�[�e�B�֘A �������f�[�^ �`�F�b�N�p�J�[�\�� *** --
    CURSOR party_rel_inact_check_cur
    IS
      SELECT MAX(TRUNC( hr.start_date ))  AS start_date
           , MAX(TRUNC( hr.end_date ))    AS end_date
        FROM hz_relationships  hr                           -- �p�[�e�B�֘A
       WHERE -- �֘A���ڋq���
             hr.subject_type       = cv_hr_type_org         --  �T�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  �T�u�W�F�N�g�e�[�u����:HZ_PARTIES
         AND hr.subject_id         = lt_cust_party_id       --  �T�u�W�F�N�gID:�֘A���p�[�e�BID
             -- �֘A��ڋq���
         AND hr.object_type        = cv_hr_type_org         --  �I�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  �I�u�W�F�N�g�^�C�v:HZ_PARTIES
         AND hr.object_id          = lt_rel_cust_party_id   --  �I�u�W�F�N�gID:�֘A��p�[�e�BID
             --
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  �p�[�e�B�֘A�^�C�v:�^�M�֘A
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  �p�[�e�B�֘A�R�[�h:���|�Ǘ���
         AND hr.status             = cv_active_set          --  �X�e�[�^�X:A(�L��)
    ;
    --
    -- *** �p�[�e�B�֘A �L�����f�[�^ �`�F�b�N�p�J�[�\�� *** --
    CURSOR party_rel_active_check_cur
    IS
      SELECT hca.account_number           AS cust_code
           , MAX(TRUNC( hr.start_date ))  AS start_date
           , MAX(TRUNC( hr.end_date ))    AS end_date
        FROM hz_relationships  hr             -- �p�[�e�B�֘A
           , Hz_cust_accounts  hca            -- �֘A���ڋq�}�X�^
           , ( -- �C�����C���r���[:�ŐV���t
                SELECT MAX(TRUNC( hr.start_date )) AS max_start_date
                  FROM hz_relationships  hr   -- �p�[�e�B�֘A
                 WHERE -- �֘A���ڋq���
                       hr.subject_type       = cv_hr_type_org         --  �T�u�W�F�N�g�^�C�v:ORGANIZATION
                   AND hr.subject_table_name = cv_hr_table_name       --  �T�u�W�F�N�g�e�[�u����:HZ_PARTIES
                       -- �֘A��ڋq���
                   AND hr.object_type        = cv_hr_type_org         --  �I�u�W�F�N�g�^�C�v:ORGANIZATION
                   AND hr.object_table_name  = cv_hr_table_name       --  �I�u�W�F�N�g�^�C�v:HZ_PARTIES
                   AND hr.object_id          = lt_rel_cust_party_id   --  �I�u�W�F�N�gID:�֘A��p�[�e�BID
                       --
                   AND hr.relationship_type  = cv_hr_rel_type_credit  --  �p�[�e�B�֘A�^�C�v:�^�M�֘A
                   AND hr.relationship_code  = cv_hr_rel_code_urikake --  �p�[�e�B�֘A�R�[�h:���|�Ǘ���
                   AND hr.status             = cv_active_set          --  �X�e�[�^�X:A(�L��)
             ) hr_max
       WHERE -- �֘A���ڋq���
             hr.subject_type       = cv_hr_type_org         --  �T�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  �T�u�W�F�N�g�e�[�u����:HZ_PARTIES
         AND hr.subject_id         = hca.party_id           --  �T�u�W�F�N�gID = �֘A���ڋq�}�X�^.�p�[�e�BID
             -- �֘A��ڋq���
         AND hr.object_type        = cv_hr_type_org         --  �I�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  �I�u�W�F�N�g�^�C�v:HZ_PARTIES
         AND hr.object_id          = lt_rel_cust_party_id   --  �I�u�W�F�N�gID:�֘A��p�[�e�BID
             --
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  �p�[�e�B�֘A�^�C�v:�^�M�֘A
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  �p�[�e�B�֘A�R�[�h:���|�Ǘ���
         AND hr.status             = cv_active_set          --  �X�e�[�^�X:A(�L��)
         AND TRUNC( hr.start_date) = hr_max.max_start_date  --  �J�n�� = �ŐV�J�n��
      GROUP BY hca.account_number
    ;
    --
    -- *** �ڋq�֘A���� CSV�d���`�F�b�N�p�J�[�\��1 *** --
    CURSOR cust_rel_csv_repeat_check1_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- �ڋq�֘A�ꊇ�X�V���[�N
       WHERE xwcru.request_id              = cn_request_id                      --  �v��ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  �s�ԍ�
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  �֘A��ڋq�敪
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  �֘A��ڋq�R�[�h
         AND xwcru.status                  = i_cust_rel_rec.status              --  �o�^�X�e�[�^�X
         AND xwcru.relate_class            = i_cust_rel_rec.relate_class        --  �ڋq�֘A����
    ;
    -- *** �ڋq�֘A���� CSV�d���`�F�b�N�p�J�[�\��2 *** --
    CURSOR cust_rel_csv_repeat_check2_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- �ڋq�֘A�ꊇ�X�V���[�N
       WHERE xwcru.request_id              = cn_request_id                      --  �v��ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  �s�ԍ�
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  �֘A��ڋq�敪
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  �֘A��ڋq�R�[�h
         AND xwcru.status                  = i_cust_rel_rec.status              --  �o�^�X�e�[�^�X
         AND xwcru.customer_class_code     = i_cust_rel_rec.cust_class_code     --  �ڋq�敪
         AND xwcru.customer_code           = i_cust_rel_rec.cust_code           --  �ڋq�R�[�h
    ;
    --
    -- *** �ڋq�֘A �������f�[�^ �`�F�b�N�p�J�[�\�� *** --
    CURSOR cust_rel_inact_check_cur
    IS
      SELECT COUNT(1)
        FROM hz_cust_acct_relate_all hcarel                                     -- �ڋq�֘A�}�X�^
       WHERE hcarel.org_id                  = gv_org_id                         --  �g�DID
         AND hcarel.attribute1              = i_cust_rel_rec.relate_class       --  �֘A����
         AND hcarel.status                  = cv_active_set                     --  �X�e�[�^�X:A(�L��)
         AND hcarel.related_cust_account_id = lt_rel_cust_account_id            --  �֘A��ڋqID
         AND hcarel.cust_account_id         = lt_cust_account_id                --  �ڋqID
    ;
    --
    -- *** �ڋq�֘A �L�����f�[�^ �`�F�b�N�p�J�[�\�� *** --
    CURSOR cust_rel_active_check_cur
    IS
      -- ����1:�֘A���Ɗ֘A��ŗL���Ȋ֘A����(�����E����)
      SELECT hca1.account_number     AS cust_code              -- �֘A���ڋq�R�[�h
           , hca2.account_number     AS rel_cust_code          -- �֘A��ڋq�R�[�h
           , hcarel.attribute1       AS relate_class           -- �ڋq�֘A����
        FROM hz_cust_accounts hca1          --�W��:�ڋq�}�X�^ �֘A��
           , hz_cust_accounts hca2          --�W��:�ڋq�}�X�^ �֘A��
           , hz_cust_acct_relate_all hcarel --�W��:�ڋq�֘A�}�X�^
       WHERE hcarel.org_id                  = gv_org_id                         --  �g�DID
         AND hcarel.attribute1              IN ( cv_rel_bill , cv_rel_cash )    --  �֘A����(����or����)
         AND hcarel.status                  = cv_active_set                     --  �X�e�[�^�X:A(�L��)
         AND hcarel.related_cust_account_id = hca2.cust_account_id              --  �֘A��ڋqID
         AND hcarel.cust_account_id         = hca1.cust_account_id              --  �ڋqID
         AND hca2.account_number            = i_cust_rel_rec.rel_cust_code      --  �֘A��ڋq�R�[�h
         AND hca1.account_number            = i_cust_rel_rec.cust_code          --  �֘A���ڋq�R�[�h
      UNION ALL
      -- ����2:�֘A��ɑ΂���L���Ȋ֘A����(�֘A���ȊO�Ŏw�肵���֘A����)
      SELECT hca1.account_number     AS cust_code              -- �֘A���ڋq�R�[�h
           , hca2.account_number     AS rel_cust_code          -- �֘A��ڋq�R�[�h
           , hcarel.attribute1       AS relate_class           -- �ڋq�֘A����
        FROM hz_cust_accounts hca1          --�W��:�ڋq�}�X�^ �֘A��
           , hz_cust_accounts hca2          --�W��:�ڋq�}�X�^ �֘A��
           , hz_cust_acct_relate_all hcarel --�W��:�ڋq�֘A�}�X�^
       WHERE hcarel.org_id                  = gv_org_id                         --  �g�DID
         AND hcarel.attribute1              = i_cust_rel_rec.relate_class       --  �֘A����(����or����)
         AND hcarel.status                  = cv_active_set                     --  �X�e�[�^�X:A(�L��)
         AND hcarel.related_cust_account_id = hca2.cust_account_id              --  �֘A��ڋqID
         AND hcarel.cust_account_id         = hca1.cust_account_id              --  �ڋqID
         AND hca2.account_number            = i_cust_rel_rec.rel_cust_code      --  �֘A��ڋq�R�[�h
         AND hca1.account_number           <> i_cust_rel_rec.cust_code          --  �֘A���ڋq�R�[�h
    ;
    TYPE cust_rel_active_rec_ttype IS TABLE OF cust_rel_active_check_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    cust_rel_active_rec_tab  cust_rel_active_rec_ttype;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N�X�e�[�^�X�̏�����
    lv_check_status := cv_status_normal;
--
    --==============================================================
    -- A-4.1 �ڋq�敪�`�F�b�N
    --==============================================================
    lv_step := 'A-4.1';
    lv_step_status := cv_status_normal;
    -- �t�H�[�}�b�g�p�^�[���u�p�[�e�B�֘A�v��� �ڋq�敪���u13:�@�l�ڋq�v
    -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v    ��� �ڋq�敪���u14:���|�Ǘ���ڋq�v
    IF ( ( gv_format = cv_file_format_pa AND i_cust_rel_rec.cust_class_code <> cv_cu_trust_corp )
      OR ( gv_format = cv_file_format_cu AND i_cust_rel_rec.cust_class_code <> cv_cu_ar_manage  ) )
      THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- �l�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm               -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10328               -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                     -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkv_cu_class_code             -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                     -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.cust_class_code   -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no             -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_cust_rel_rec.line_no           -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.2 �ڋq�R�[�h���݃`�F�b�N
    --==============================================================
    IF ( lv_step_status = cv_status_normal ) THEN
      lv_step := 'A-4.2';
      -- �p�����[�^�J�[�\�����擾
      OPEN get_cust_id_cur(
          i_cust_rel_rec.cust_class_code
        , i_cust_rel_rec.cust_code
      );
      FETCH get_cust_id_cur INTO lt_cust_party_id, lt_cust_account_id;
      CLOSE get_cust_id_cur;
      -- �擾�ł��Ȃ������ꍇ�A�G���[
      IF lt_cust_party_id IS NULL THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- �ڋq�}�X�^���݃`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10347             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_cust_class              -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_cust_rel_rec.cust_class_code -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_cust_code               -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.cust_code       -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no           -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_cust_rel_rec.line_no         -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.3 �֘A��ڋq�敪�`�F�b�N
    --==============================================================
    lv_step := 'A-4.3';
    lv_step_status := cv_status_normal;
    -- �t�H�[�}�b�g�p�^�[���u�p�[�e�B�֘A�v��� �֘A��ڋq�敪���u10:�ڋq�v�u14:���|�Ǘ���ڋq�v�̂����ꂩ�ł��邱��
    -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v    ��� �֘A��ڋq�敪���u10:�ڋq�v�ł��邱��
    IF ( ( gv_format = cv_file_format_pa AND i_cust_rel_rec.rel_cust_class_code NOT IN ( cv_cu_customer , cv_cu_ar_manage ) )
      OR ( gv_format = cv_file_format_cu AND i_cust_rel_rec.rel_cust_class_code <> cv_cu_customer ) )
      THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- �l�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10328                   -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                         -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkv_recu_class_code               -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                         -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.rel_cust_class_code   -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                 -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_cust_rel_rec.line_no               -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.4 �֘A��ڋq�R�[�h���݃`�F�b�N
    --==============================================================
    IF ( lv_step_status = cv_status_normal ) THEN
      lv_step := 'A-4.4';
      -- �p�����[�^�J�[�\�����擾
      OPEN get_cust_id_cur(
          i_cust_rel_rec.rel_cust_class_code
        , i_cust_rel_rec.rel_cust_code
      );
      FETCH get_cust_id_cur INTO lt_rel_cust_party_id, lt_rel_cust_account_id;
      CLOSE get_cust_id_cur;
      -- �擾�ł��Ȃ������ꍇ�A�G���[
      IF lt_rel_cust_party_id IS NULL THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- �ڋq�}�X�^���݃`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                 -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10347                 -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_cust_class                  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => i_cust_rel_rec.rel_cust_class_code -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_cust_code                   -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.rel_cust_code       -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no               -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_cust_rel_rec.line_no             -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.5 �o�^�X�e�[�^�X�`�F�b�N
    --==============================================================
    -- �o�^�X�e�[�^�X���uY:�L�����v�uN:�������v�̂����ꂩ�ł��邱��
    lv_step := 'A-4.5';
    lv_step_status := cv_status_normal;
    IF ( i_cust_rel_rec.status NOT IN ( cv_active_csv , cv_inactive_csv ) ) THEN
      lv_step_status  := cv_status_error;
      lv_check_status := cv_status_error;
      -- �l�`�F�b�N�G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10328                   -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_input                         -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_tkv_status                        -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_value                         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_cust_rel_rec.status                -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_line_no                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_cust_rel_rec.line_no               -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg);
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.6 �֘A�K�p���`�F�b�N
    --==============================================================
    -- �t�H�[�}�b�g�p�^�[�����u�p�[�e�B�֘A�v�̏ꍇ�A
    -- �֘A�K�p�����Ɩ����t��薢�����t�ł͂Ȃ�����
    IF ( gv_format = cv_file_format_pa ) THEN
      lv_step := 'A-4.6';
      lv_step_status := cv_status_normal;
      lv_char_rel_date := TO_CHAR(i_cust_rel_rec.rel_apply_date , 'YYYY/MM/DD');
      -- �֘A�K�p�����Ɩ����t��薢�����t�̏ꍇ
      IF ( TRUNC( i_cust_rel_rec.rel_apply_date ) > TRUNC( gd_process_date ) ) THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        --�֘A�K�p���`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10355                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_apply_date                     -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_char_rel_date                      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.line_no                -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.7 �ڋq�֘A���ނ̑��݃`�F�b�N
    --==============================================================
    -- �t�H�[�}�b�g�p�^�[�����u�ڋq�֘A�v�̏ꍇ�A
    -- �ڋq�֘A���ނ��Q�ƃR�[�h�}�X�^��ɑ��݂��邱��
    IF ( gv_format = cv_file_format_cu ) THEN
      lv_step := 'A-4.7';
      lv_step_status := cv_status_normal;
      -- Lookup�\�̑��݃`�F�b�N
      SELECT COUNT(1)
        INTO ln_chk_cnt
        FROM fnd_lookup_values_vl flv                                             -- LOOKUP�\
       WHERE flv.lookup_type        = cv_lookup_relate_class                      -- �ڋq�֘A����
         AND flv.lookup_code        = i_cust_rel_rec.relate_class                 -- CSV.�ڋq�֘A����
         AND flv.enabled_flag       = cv_lookup_yes                               -- �g�p�\�t���O
         AND NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
         AND NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date     -- �K�p�I����
      ;
      -- �擾���ʔ���
      IF (ln_chk_cnt = 0) THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        --�Q�ƃR�[�h���݃`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkv_relate_class                   -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_cust_rel_rec.relate_class           -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_cust_rel_rec.line_no                -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.8 �p�[�e�B�֘A�̃`�F�b�N����
    --==============================================================
    -- �t�H�[�}�b�g�p�^�[�����u�p�[�e�B�֘A�v�̏ꍇ
    IF ( ( gv_format       = cv_file_format_pa ) AND 
         ( lv_check_status = cv_status_normal  ) )
      THEN
        -- ***  A-4.8.1 CSV�t�@�C�����d���`�F�b�N  *** --
        lv_step := 'A-4.8.1';
        lv_step_status := cv_status_normal;
        lv_char_rel_date := TO_CHAR(i_cust_rel_rec.rel_apply_date , 'YYYY/MM/DD');
        -- CSV���d���`�F�b�N
        OPEN party_rel_csv_repeat_check_cur;
        FETCH party_rel_csv_repeat_check_cur INTO ln_chk_cnt;
        CLOSE party_rel_csv_repeat_check_cur;
        -- �擾���ʔ���
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --�ڋq�֘A�ꊇ�X�VCSV���e�d���G���[ 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10348                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkv_rep_cont_pa                    -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --
        -- ***  A-4.8.2 �������f�[�^�`�F�b�N  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_inactive_csv  ) )
          THEN
            lv_step := 'A-4.8.2';
            -- �֘A���E�֘A��Ԃ̍ŐV�L���p�[�e�B�֘A �擾
            OPEN party_rel_inact_check_cur;
            FETCH party_rel_inact_check_cur INTO ld_pa_chk_start_date , ld_pa_chk_end_date;
            CLOSE party_rel_inact_check_cur;
            -- �擾���ʔ���
            IF ( ( ld_pa_chk_start_date IS NULL ) OR
                 ( NOT( i_cust_rel_rec.rel_apply_date BETWEEN ld_pa_chk_start_date AND ld_pa_chk_end_date ) ) )
              THEN
                lv_step_status  := cv_status_error;
                lv_check_status := cv_status_error;
                --�p�[�e�B�֘A�������f�[�^�`�F�b�N�G���[ 
                gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_xxcmm_10349                    -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_cust_code                      -- �g�[�N���R�[�h1
                              ,iv_token_value1 => i_cust_rel_rec.cust_code              -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_rel_cust_code                  -- �g�[�N���R�[�h2
                              ,iv_token_value2 => i_cust_rel_rec.rel_cust_code          -- �g�[�N���l2
                              ,iv_token_name3  => cv_tkn_apply_date                     -- �g�[�N���R�[�h3
                              ,iv_token_value3 => lv_char_rel_date                      -- �g�[�N���l3
                              ,iv_token_name4  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h4
                              ,iv_token_value4 => i_cust_rel_rec.line_no                -- �g�[�N���l4
                             );
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg);
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
            END IF;
        END IF;
        --
        -- ***  A-4.8.3 �L�����f�[�^�`�F�b�N  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_active_csv    ) )
          THEN
            lv_step := 'A-4.8.3';
            lv_csv_inact_search := cv_un_search;
            -- �֘A��ɑ΂���ŐV�̗L���p�[�e�B�֘A �擾
            OPEN party_rel_active_check_cur;
            FETCH party_rel_active_check_cur INTO lv_pa_chk_cust_code , ld_pa_chk_start_date , ld_pa_chk_end_date;
            CLOSE party_rel_active_check_cur;
            -- �擾���ʔ���
            IF ( lv_pa_chk_cust_code IS NULL ) THEN
              -- �L���ȃp�[�e�B�֘A���� �� �b�r�u�����s�v��OK
              lv_csv_inact_search := cv_un_search;
            ELSE
              -- �L���ȃp�[�e�B�֘A�L��
              IF ( ( ld_pa_chk_start_date < i_cust_rel_rec.rel_apply_date ) AND
                   ( ld_pa_chk_end_date   < i_cust_rel_rec.rel_apply_date ) )
                THEN
                  -- �J�n���E�I���� �� �֘A�K�p��   �� �b�r�u�����s�v��OK
                  lv_csv_inact_search := cv_un_search;
              ELSIF ( (i_cust_rel_rec.rel_apply_date >  ld_pa_chk_start_date ) AND
                      (i_cust_rel_rec.rel_apply_date <= ld_pa_chk_end_date   ) )
                THEN
                  -- �J�n�� �� �֘A�K�p�� �� �I���� �� �b�r�u�����v
                  lv_csv_inact_search := cv_search;
              ELSE
                --  �֘A�K�p�� �� �J�n��  �� �b�r�u�����s�v��NG
                lv_step_status  := cv_status_error;
                lv_check_status := cv_status_error;
                --�p�[�e�B�֘A�L�����f�[�^�`�F�b�N�������G���[ 
                gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_xxcmm_10350              -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_cust_code                -- �g�[�N���R�[�h1
                              ,iv_token_value1 => i_cust_rel_rec.cust_code        -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_apply_date               -- �g�[�N���R�[�h2
                              ,iv_token_value2 => lv_char_rel_date                -- �g�[�N���l2
                              ,iv_token_name3  => cv_tkn_input_line_no            -- �g�[�N���R�[�h3
                              ,iv_token_value3 => i_cust_rel_rec.line_no          -- �g�[�N���l3
                              ,iv_token_name4  => cv_tkn_rel_cust_code            -- �g�[�N���R�[�h4
                              ,iv_token_value4 => lv_pa_chk_cust_code             -- �g�[�N���l4
                             );
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg);
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
            END IF;
            --
            -- ***  A-4.8.4 �b�r�u�t�@�C�����������f�[�^����  *** --
            IF (( lv_step_status      = cv_status_normal ) AND
                ( lv_csv_inact_search = cv_search        ) )
               THEN
                 lv_step := 'A-4.8.4';
                 --
                 SELECT COUNT(1)
                   INTO ln_chk_cnt
                   FROM xxcmm_wk_cust_relate_upload xwcru                                  -- �ڋq�֘A�ꊇ�X�V���[�N
                  WHERE xwcru.request_id              = cn_request_id                      -- �v��ID
                    AND xwcru.status                  = cv_inactive_csv                    -- �o�^�X�e�[�^�X:N
                    AND xwcru.customer_code           = lv_pa_chk_cust_code                -- �֘A���ڋq�R�[�h
                    AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       -- �֘A��ڋq�R�[�h
                    AND xwcru.relate_apply_date       < i_cust_rel_rec.rel_apply_date      -- �֘A�K�p��
                 ;
                 -- �擾���ʔ���
                 IF (ln_chk_cnt = 0) THEN
                   lv_step_status  := cv_status_error;
                   lv_check_status := cv_status_error;
                   --�p�[�e�B�֘A�L�����f�[�^�`�F�b�N�G���[ 
                   gv_out_msg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                                 ,iv_name         => cv_msg_xxcmm_10351                    -- ���b�Z�[�W�R�[�h
                                 ,iv_token_name1  => cv_tkn_cust_code                      -- �g�[�N���R�[�h1
                                 ,iv_token_value1 => i_cust_rel_rec.cust_code              -- �g�[�N���l1
                                 ,iv_token_name2  => cv_tkn_apply_date                     -- �g�[�N���R�[�h2
                                 ,iv_token_value2 => lv_char_rel_date                      -- �g�[�N���l2
                                 ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                                 ,iv_token_value3 => i_cust_rel_rec.line_no                -- �g�[�N���l3
                                 ,iv_token_name4  => cv_tkn_rel_cust_code                  -- �g�[�N���R�[�h4
                                 ,iv_token_value4 => lv_pa_chk_cust_code                   -- �g�[�N���l4
                                );
                   -- ���b�Z�[�W�o��
                   FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg);
                   --
                   FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg);
                 END IF;
            END IF;
        END IF;
    END IF;
    --
    --==============================================================
    -- A-4.9 �ڋq�֘A�̃`�F�b�N����
    --==============================================================
    -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v�̏ꍇ
    IF ( ( gv_format       = cv_file_format_cu ) AND
         ( lv_check_status = cv_status_normal  ) )
      THEN
        -- ***  A-4.9.1 CSV�t�@�C�����d���`�F�b�N  *** --
        lv_step := 'A-4.9.1';
        lv_step_status := cv_status_normal;
        -- CSV���d���`�F�b�N1
        OPEN cust_rel_csv_repeat_check1_cur;
        FETCH cust_rel_csv_repeat_check1_cur INTO ln_chk_cnt;
        CLOSE cust_rel_csv_repeat_check1_cur;
        -- �擾���ʔ���
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --�ڋq�֘A�ꊇ�X�VCSV���e�d���G���[ 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10348                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkv_rep_cont_cu1                   -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        -- CSV���d���`�F�b�N2
        OPEN cust_rel_csv_repeat_check2_cur;
        FETCH cust_rel_csv_repeat_check2_cur INTO ln_chk_cnt;
        CLOSE cust_rel_csv_repeat_check2_cur;
        -- �擾���ʔ���
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --�ڋq�֘A�ꊇ�X�VCSV���e�d���G���[ 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10348                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkv_rep_cont_cu2                   -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --
        -- ***  A-4.9.2 �������f�[�^�`�F�b�N  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_inactive_csv  ) )
          THEN
            lv_step := 'A-4.9.2';
            -- �֘A���E�֘A��Ԃ̗L���Ȍڋq�֘A �擾
            OPEN cust_rel_inact_check_cur;
            FETCH cust_rel_inact_check_cur INTO ln_chk_cnt;
            CLOSE cust_rel_inact_check_cur;
            -- �擾���ʔ���
            IF (ln_chk_cnt = 0) THEN
              lv_step_status  := cv_status_error;
              lv_check_status := cv_status_error;
              -- �֘A���ޖ��Ƀ��b�Z�[�W�g�[�N����ݒ�
              IF ( i_cust_rel_rec.relate_class = cv_rel_bill ) THEN
                 lv_rel_cls_name := cv_rel_bill_name;
              ELSE
                 lv_rel_cls_name := cv_rel_cash_name;
              END IF;
              -- �ڋq�֘A�������f�[�^�`�F�b�N�G���[
              gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_xxcmm_10352                    -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_cust_code                      -- �g�[�N���R�[�h1
                            ,iv_token_value1 => i_cust_rel_rec.cust_code              -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_rel_cust_code                  -- �g�[�N���R�[�h2
                            ,iv_token_value2 => i_cust_rel_rec.rel_cust_code          -- �g�[�N���l2
                            ,iv_token_name3  => cv_tkn_rel_cls_name                   -- �g�[�N���R�[�h3
                            ,iv_token_value3 => lv_rel_cls_name                       -- �g�[�N���l3
                            ,iv_token_name4  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h4
                            ,iv_token_value4 => i_cust_rel_rec.line_no                -- �g�[�N���l4
                           );
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg);
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
        END IF;
        --
        -- ***  A-4.9.3 �L�����f�[�^�`�F�b�N  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_active_csv    ) )
          THEN
            lv_step := 'A-4.9.3';
            -- ���ݗL���Ȍڋq�֘A���ނ��擾
            OPEN cust_rel_active_check_cur;
            FETCH cust_rel_active_check_cur BULK COLLECT INTO cust_rel_active_rec_tab;
            CLOSE cust_rel_active_check_cur;
            --
            -- ���ɗL���ȏ�񂪂���ꍇ�̂݁A�b�r�u�t�@�C���̒����疳�����f�[�^������
            <<csv_inact_loop>>
            FOR ln_cnt IN 1..cust_rel_active_rec_tab.COUNT LOOP
               -- ***  A-4.9.4 �b�r�u�t�@�C�����������f�[�^����  *** --
               lv_step := 'A-4.9.4';
               --
               SELECT COUNT(1)
                 INTO ln_chk_cnt
                 FROM xxcmm_wk_cust_relate_upload xwcru                                         -- �ڋq�֘A�ꊇ�X�V���[�N
                WHERE xwcru.request_id          = cn_request_id                                 -- �v��ID
                  AND xwcru.status              = cv_inactive_csv                               -- �o�^�X�e�[�^�X:N
                  AND xwcru.customer_code       = cust_rel_active_rec_tab(ln_cnt).cust_code     -- �֘A���ڋq�R�[�h
                  AND xwcru.rel_customer_code   = cust_rel_active_rec_tab(ln_cnt).rel_cust_code -- �֘A��ڋq�R�[�h
                  AND xwcru.relate_class        = cust_rel_active_rec_tab(ln_cnt).relate_class  -- �ڋq�֘A
               ;
               -- �擾���ʔ���
               IF (ln_chk_cnt = 0) THEN
                 lv_step_status  := cv_status_error;
                 lv_check_status := cv_status_error;
                 IF ( cust_rel_active_rec_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
                    lv_rel_cls_name := cv_rel_bill_name;
                 ELSE
                    lv_rel_cls_name := cv_rel_cash_name;
                 END IF;
                 -- �ڋq�֘A�L�����f�[�^�`�F�b�N�G���[ 
                 gv_out_msg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_msg_xxcmm_10353                    -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_rel_cust_code                  -- �g�[�N���R�[�h1
                               ,iv_token_value1 => i_cust_rel_rec.rel_cust_code          -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_rel_cls_name                   -- �g�[�N���R�[�h2
                               ,iv_token_value2 => lv_rel_cls_name                       -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                               ,iv_token_value3 => i_cust_rel_rec.line_no                -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_cust_code                      -- �g�[�N���R�[�h4
                               ,iv_token_value4 => cust_rel_active_rec_tab(ln_cnt).cust_code -- �g�[�N���l4
                              );
                 -- ���b�Z�[�W�o��
                 FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT
                   ,buff   => gv_out_msg);
                 --
                 FND_FILE.PUT_LINE(
                    which  => FND_FILE.LOG
                   ,buff   => gv_out_msg);
               END IF;
            END LOOP csv_inact_loop;
        END IF;
    END IF;
    --
    -- �S�ẴG���[�`�F�b�N��OK�̏ꍇ�̂݁A�o�^�X�e�[�^�X���ɒl��ޔ��B
    IF ( lv_check_status = cv_status_normal ) THEN
      -- �o�^�X�e�[�^�X�ɉ����Ēl��ޔ�
      IF ( i_cust_rel_rec.status = cv_active_csv ) THEN
        -- �L�����f�[�^�̑ޔ�
        gn_active_cnt := gn_active_cnt + 1;
        -- �֘A�����
        g_act_keys_tab(gn_active_cnt).cust_class_code      := i_cust_rel_rec.cust_class_code;
        g_act_keys_tab(gn_active_cnt).cust_code            := i_cust_rel_rec.cust_code;
        g_act_keys_tab(gn_active_cnt).cust_party_id        := lt_cust_party_id;
        g_act_keys_tab(gn_active_cnt).cust_account_id      := lt_cust_account_id;
        -- �֘A����
        g_act_keys_tab(gn_active_cnt).rel_cust_class_code  := i_cust_rel_rec.rel_cust_class_code;
        g_act_keys_tab(gn_active_cnt).rel_cust_code        := i_cust_rel_rec.rel_cust_code;
        g_act_keys_tab(gn_active_cnt).rel_cust_party_id    := lt_rel_cust_party_id;
        g_act_keys_tab(gn_active_cnt).rel_cust_account_id  := lt_rel_cust_account_id;
        --
        g_act_keys_tab(gn_active_cnt).relate_class         := i_cust_rel_rec.relate_class;
        g_act_keys_tab(gn_active_cnt).rel_apply_date       := i_cust_rel_rec.rel_apply_date;
        g_act_keys_tab(gn_active_cnt).line_no              := i_cust_rel_rec.line_no;
      ELSE
        -- �������f�[�^�̑ޔ�
        gn_inact_cnt  := gn_inact_cnt + 1;
        -- �֘A�����
        g_inact_keys_tab(gn_inact_cnt).cust_class_code     := i_cust_rel_rec.cust_class_code;
        g_inact_keys_tab(gn_inact_cnt).cust_code           := i_cust_rel_rec.cust_code;
        g_inact_keys_tab(gn_inact_cnt).cust_party_id       := lt_cust_party_id;
        g_inact_keys_tab(gn_inact_cnt).cust_account_id     := lt_cust_account_id;
        -- �֘A����
        g_inact_keys_tab(gn_inact_cnt).rel_cust_class_code := i_cust_rel_rec.rel_cust_class_code;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_code       := i_cust_rel_rec.rel_cust_code;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_party_id   := lt_rel_cust_party_id;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_account_id := lt_rel_cust_account_id;
        --
        g_inact_keys_tab(gn_inact_cnt).relate_class        := i_cust_rel_rec.relate_class;
        g_inact_keys_tab(gn_inact_cnt).rel_apply_date      := i_cust_rel_rec.rel_apply_date;
        g_inact_keys_tab(gn_inact_cnt).line_no             := i_cust_rel_rec.line_no;
      END IF;
    END IF;
    --
    ov_retcode := lv_check_status;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_cust_wrel;
--
  /**********************************************************************************
   * Procedure Name   : proc_party_rel_inact
   * Description      : �p�[�e�B�֘A�������f�[�^�X�V����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_party_rel_inact(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_rel_inact'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- �p�[�e�B�֘A �X�V�p
    lt_relationship_id        hz_relationships.relationship_id%TYPE;            -- �����[�V�����V�b�vID
    lt_prel_obj_v_number      hz_relationships.object_version_number%TYPE;      -- �I�u�W�F�N�g�o�[�W�����ԍ�
    lt_party_obj_v_number     hz_parties.object_version_number%TYPE;            -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- �W��API�ďo�p
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                    -- �������b�Z�[�W
    l_relationship_rec        hz_relationship_v2pub.relationship_rec_type;      -- �p�[�e�B�֘A�X�V�p���R�[�h
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �p�[�e�B�֘A��� �擾�J�[�\��
    CURSOR party_relate_cur(
      p_cust_party_id      NUMBER ,  -- �֘A���ڋq �p�[�e�CID
      p_rel_cust_party_id  NUMBER ,  -- �֘A��ڋq �p�[�e�BID
      p_rel_apply_date     DATE      -- �֘A�K�p��
    )IS
      SELECT hr.relationship_id       AS relationship_id
           , hr.object_version_number AS prel_obj_v_number
           , hp.object_version_number AS party_obj_v_number
        FROM hz_relationships  hr                           -- �p�[�e�B�֘A
           , hz_parties  hp                                 -- �p�[�e�B
       WHERE -- �֘A���ڋq���
             hr.subject_type       = cv_hr_type_org         --  �T�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  �T�u�W�F�N�g�e�[�u����:HZ_PARTIES
         AND hr.subject_id         = p_cust_party_id        --  �T�u�W�F�N�gID:�֘A���p�[�e�BID
             -- �֘A��ڋq���
         AND hr.object_type        = cv_hr_type_org         --  �I�u�W�F�N�g�^�C�v:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  �I�u�W�F�N�g�^�C�v:HZ_PARTIES
         AND hr.object_id          = p_rel_cust_party_id    --  �I�u�W�F�N�gID:�֘A��p�[�e�BID
             --
         AND hr.party_id           = hp.party_id            --  �p�[�e�BID
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  �p�[�e�B�֘A�^�C�v:�^�M�֘A
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  �p�[�e�B�֘A�R�[�h:���|�Ǘ���
         AND hr.status             = cv_active_set          --  �X�e�[�^�X:A(�L��)
         AND hr.start_date        <= p_rel_apply_date       --  �J�n��
         AND hr.end_date          >= p_rel_apply_date       --  �I����
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J�����[�U�[��`��O ***
    v2pub_err_expt                 EXCEPTION;               -- �W��API�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- �������f�[�^�S�Ă��X�V
    <<party_inact_loop>>
    FOR ln_cnt IN 1..g_inact_keys_tab.COUNT LOOP
      --==============================================================
      -- A-5.1 �p�[�e�B�֘A ���擾�����b�N
      --==============================================================
      lv_step := 'A-5.1';
      BEGIN 
        -- �������̃L�[�����Ɏ擾
        OPEN party_relate_cur(
          g_inact_keys_tab(ln_cnt).cust_party_id ,
          g_inact_keys_tab(ln_cnt).rel_cust_party_id ,
          g_inact_keys_tab(ln_cnt).rel_apply_date
        );
        FETCH party_relate_cur INTO lt_relationship_id, lt_prel_obj_v_number, lt_party_obj_v_number;
        CLOSE party_relate_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_lock_table := cv_tkv_lock_party_rel || cv_msg_comma || cv_tkv_lock_party;
          RAISE global_check_lock_expt;
      END;
      --
      --==============================================================
      -- A-5.2 �p�[�e�B�֘A �X�V�p���R�[�h�擾
      --==============================================================
      lv_step := 'A-5.2';
      -- �W��API:�p�[�e�B�֘A�擾
      hz_relationship_v2pub.get_relationship_rec(
        p_init_msg_list               =>  lv_init_msg_list         -- 1.�������b�Z�[�W���X�g
       ,p_relationship_id             =>  lt_relationship_id       -- 2.�����[�V�����V�b�vID
       ,x_rel_rec                     =>  l_relationship_rec
       ,x_return_status               =>  lv_return_status
       ,x_msg_count                   =>  ln_msg_count
       ,x_msg_data                    =>  lv_msg_data
      );
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        lv_api_name := cv_tkv_apinm_pa_get;
        lv_api_step := cv_tkv_apist_pa_get;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      --==============================================================
      -- A-5.3 �p�[�e�B�֘A �X�V�p���R�[�h�ҏW���X�V
      --==============================================================
      lv_step := 'A-5.3';
      -- �l�̕ҏW
      l_relationship_rec.subject_type        := cv_hr_type_org;                     -- 'ORGANIZATION'
      l_relationship_rec.subject_table_name  := cv_hr_table_name;                   -- 'HZ_PARTIES'
      l_relationship_rec.object_type         := cv_hr_type_org;                     -- 'ORGANIZATION'
      l_relationship_rec.object_table_name   := cv_hr_table_name;                   -- 'HZ_PARTIES'
      l_relationship_rec.relationship_code   := cv_hr_rel_code_urikake;             -- '���|�Ǘ���'
      l_relationship_rec.relationship_type   := cv_hr_rel_type_credit;              -- '�^�M�֘A'
      l_relationship_rec.status              := cv_active_set;                      -- �o�^�X�e�[�^�X:'A'(�L��)
      l_relationship_rec.end_date            := g_inact_keys_tab(ln_cnt).rel_apply_date;      -- �I����
      l_relationship_rec.comments            := g_inact_keys_tab(ln_cnt).rel_cust_class_code || '_' || 
                                                g_inact_keys_tab(ln_cnt).rel_cust_code; -- ����
      --
      -- �W��API:�p�[�e�B�֘A�X�V
      hz_relationship_v2pub.update_relationship(
        p_init_msg_list               => lv_init_msg_list        -- 1.�������b�Z�[�W���X�g
       ,p_relationship_rec            => l_relationship_rec      -- 2.�p�[�e�B�֘A�X�V�p���R�[�h
       ,p_object_version_number       => lt_prel_obj_v_number    -- 3.�p�[�e�B�֘A�I�u�W�F�N�g�o�[�W�����ԍ�
       ,p_party_object_version_number => lt_party_obj_v_number   -- 4.�p�[�e�B�I�u�W�F�N�g�o�[�W�����ԍ�
       ,x_return_status               => lv_return_status
       ,x_msg_count                   => ln_msg_count
       ,x_msg_data                    => lv_msg_data
      );
      --
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_pa_upload;
        lv_api_step := cv_tkv_apist_pa_upload;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
    END LOOP party_inact_loop;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00008      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_ng_table         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_lock_table           -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      --
    -- *** �W��API ��O�n���h�� ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10354       -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_api_step          -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_api_step              -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name          -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_name              -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num           -- �g�[�N���R�[�h3
                    ,iv_token_value3 => ln_line_no               -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg            -- �g�[�N���R�[�h4
                    ,iv_token_value4 => SQLERRM                  -- �g�[�N���l4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_party_rel_inact;
--
  /**********************************************************************************
   * Procedure Name   : proc_party_rel_active
   * Description      : �p�[�e�B�֘A�L�����f�[�^�o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_party_rel_active(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_rel_active'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    ln_line_no                NUMBER;
    -- �W��API�ďo�p
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                    -- �������b�Z�[�W
    l_relationship_rec        hz_relationship_v2pub.relationship_rec_type;      -- �p�[�e�B�֘A�o�^�p���R�[�h
    lt_relationship_id        hz_relationships.relationship_id%TYPE;            -- �����[�V�����V�b�vID
    lt_party_id               hz_parties.party_id%TYPE;
    lt_party_number           hz_parties.party_number%TYPE;
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- *** ���[�J�����[�U�[��`��O ***
    v2pub_err_expt                 EXCEPTION;               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- �L�����f�[�^�S�Ă��X�V
    <<party_active_loop>>
    FOR ln_cnt IN 1..g_act_keys_tab.COUNT LOOP
      --==============================================================
      -- A-6.1 �p�[�e�B�֘A �o�^�p���R�[�h�ҏW���o�^
      --==============================================================
      lv_step := 'A-6.1';
      -- �֘A�����
      l_relationship_rec.subject_id          := g_act_keys_tab(ln_cnt).cust_party_id;     -- �p�[�e�B�h�c
      l_relationship_rec.subject_type        := cv_hr_type_org;                           -- 'ORGANIZATION'
      l_relationship_rec.subject_table_name  := cv_hr_table_name;                         -- 'HZ_PARTIES'
      -- �֘A����
      l_relationship_rec.object_id           := g_act_keys_tab(ln_cnt).rel_cust_party_id; -- �p�[�e�B�h�c
      l_relationship_rec.object_type         := cv_hr_type_org;                           -- 'ORGANIZATION'
      l_relationship_rec.object_table_name   := cv_hr_table_name;                         -- 'HZ_PARTIES'
      --
      l_relationship_rec.relationship_code   := cv_hr_rel_code_urikake;                   -- '���|�Ǘ���'
      l_relationship_rec.relationship_type   := cv_hr_rel_type_credit;                    -- '�^�M�֘A'
      l_relationship_rec.status              := cv_active_set;                            -- �o�^�X�e�[�^�X:'A'(�L��)
      l_relationship_rec.start_date          := g_act_keys_tab(ln_cnt).rel_apply_date;    -- �J�n��
      l_relationship_rec.end_date            := NULL;                                     -- �I����
      l_relationship_rec.comments            := g_act_keys_tab(ln_cnt).rel_cust_class_code || '_' || 
                                                g_act_keys_tab(ln_cnt).rel_cust_code;     -- ����
      l_relationship_rec.created_by_module   := cv_pkg_name;                              -- WHO�J����.�v���O����ID
      --
      -- �W��API:�p�[�e�B�֘A�o�^
      hz_relationship_v2pub.create_relationship(
        p_init_msg_list               => lv_init_msg_list        -- 1.�������b�Z�[�W���X�g
       ,p_relationship_rec            => l_relationship_rec      -- 2.�p�[�e�B�֘A�X�V�p���R�[�h
       ,x_relationship_id             => lt_relationship_id
       ,x_party_id                    => lt_party_id
       ,x_party_number                => lt_party_number
       ,x_return_status               => lv_return_status
       ,x_msg_count                   => ln_msg_count
       ,x_msg_data                    => lv_msg_data
      );
      --
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_pa_create;
        lv_api_step := cv_tkv_apist_pa_create;
        ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
    END LOOP party_active_loop;
--
  EXCEPTION
    -- *** �W��API ��O�n���h�� ***
    WHEN v2pub_err_expt THEN                   --*** <��O�R�����g> ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10354            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_api_step               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_api_step                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_name                   -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => ln_line_no                    -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- �g�[�N���R�[�h4
                    ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_party_rel_active;
--
  /**********************************************************************************
   * Procedure Name   : proc_cust_rel_inact
   * Description      : �ڋq�֘A�������f�[�^�X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE proc_cust_rel_inact(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_rel_inact'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- �ڋq�֘A �X�V�p
    l_cust_rel_rowid          ROWID;                                                -- ROWID
    lt_cust_rel_obj_v_number  hz_cust_acct_relate_all.object_version_number%TYPE;   -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- �ڋq�g�p�ړI �X�V�p
    lt_ship_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;               -- �ڋq���Ə�(�֘A��) �o�א�.�g�p�ړIID
    lt_ship_suse_obj_v_number hz_cust_site_uses_all.object_version_number%TYPE;     -- �ڋq���Ə�(�֘A��) �o�א�.�I�u�W�F�N�g�o�[�W�����ԍ�
    lt_bill_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;               -- �ڋq���Ə�(�֘A��) ������.�g�p�ړIID
    -- �W��API�ďo�p
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                        -- �������b�Z�[�W
    l_cust_acct_relate_rec    hz_cust_account_v2pub.cust_acct_relate_rec_type;      -- �ڋq�֘A�X�V�p���R�[�h
    l_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;    -- �ڋq�g�p�ړI�擾�p���R�[�h
    l_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;  -- �ڋq�v���t�@�C���擾�p���R�[�h
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --
    -- �ڋq�֘A��� �擾�J�[�\��
    CURSOR customer_relate_cur(
      p_cust_account_id       NUMBER ,    -- �֘A���ڋq �ڋqID
      p_rel_cust_account_id   NUMBER ,    -- �֘A��ڋq �ڋqID
      p_relate_class          VARCHAR2    -- �֘A����
    )IS
      SELECT hcarel.rowid                    AS row_id                  -- ROWID
           , hcarel.object_version_number    AS object_version_number   -- �I�u�W�F�N�g�o�[�W����No
        FROM hz_cust_acct_relate_all         hcarel                     -- �ڋq�֘A
       WHERE hcarel.org_id                  = gv_org_id                 -- �g�DID
         AND hcarel.attribute1              = p_relate_class            -- �֘A����
         AND hcarel.status                  = cv_active_set             -- �X�e�[�^�X:A(�L��)
         AND hcarel.related_cust_account_id = p_rel_cust_account_id     -- �֘A��ڋqID
         AND hcarel.cust_account_id         = p_cust_account_id         -- �ڋqID
      FOR UPDATE NOWAIT
      ;
    --
    -- *** ������o�א掖�Ə���� �擾�J�[�\�� *** --
    CURSOR get_inact_site_uses_cur(
      p_rel_cust_account_id   NUMBER      -- �֘A��ڋq �ڋqID
    )IS
      SELECT hcsua_rel_ship.site_use_id           AS ship_site_use_id             -- �ڋq���Ə�(�֘A��) �o�א�.�g�p�ړI�h�c
           , hcsua_rel_ship.object_version_number AS ship_obj_ver_number          -- �ڋq���Ə�(�֘A��) �o�א�.�I�u�W�F�N�g�o�[�W����No
           , hcsua_rel_bill.site_use_id           AS bill_site_use_id             -- �ڋq���Ə�(�֘A��) ������.�g�p�ړI�h�c
        FROM hz_cust_acct_sites_all          hcasa_rel_ship                       -- �֘A�� �o�א�:�ڋq�T�C�g
           , hz_cust_site_uses_all           hcsua_rel_ship                       -- �֘A�� �o�א�:�ڋq���Ə�
           , hz_cust_acct_sites_all          hcasa_rel_bill                       -- �֘A�� ������:�ڋq�T�C�g
           , hz_cust_site_uses_all           hcsua_rel_bill                       -- �֘A�� ������:�ڋq���Ə�
       WHERE -- �o�א�擾
             hcasa_rel_ship.cust_account_id    = p_rel_cust_account_id            -- �ڋq�A�J�E���g�h�c
         AND hcasa_rel_ship.org_id             = gv_org_id                        -- �g�D�h�c
         AND hcasa_rel_ship.cust_acct_site_id  = hcsua_rel_ship.cust_acct_site_id -- �ڋq�T�C�g�h�c
         AND hcsua_rel_ship.site_use_code      = cv_site_use_ship_to              -- �g�p�ړI:'�o�א�'
             -- ������擾
         AND hcasa_rel_bill.cust_account_id    = p_rel_cust_account_id            -- �ڋq�A�J�E���g�h�c
         AND hcasa_rel_bill.org_id             = gv_org_id                        -- �g�D�h�c
         AND hcasa_rel_bill.cust_acct_site_id  = hcsua_rel_bill.cust_acct_site_id -- �ڋq�T�C�g�h�c
         AND hcsua_rel_bill.site_use_code      = cv_site_use_bill_to              -- �g�p�ړI:'������'
             --
         AND hcasa_rel_ship.cust_account_id    = hcasa_rel_bill.cust_account_id
         AND ROWNUM                            = 1
      FOR UPDATE NOWAIT
      ;
    -- *** ���[�J�����[�U�[��`��O ***
    v2pub_err_expt                 EXCEPTION;               -- �W��API�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- �������f�[�^�S�Ă��X�V
    <<custrel_inact_loop>>
    FOR ln_cnt IN 1..g_inact_keys_tab.COUNT LOOP
      --==============================================================
      -- A-7.1 �ڋq�֘A ���擾�����b�N
      --==============================================================
      lv_step := 'A-7.1';
      -- �������̃L�[�����Ɏ擾
      BEGIN
        OPEN customer_relate_cur(
          g_inact_keys_tab(ln_cnt).cust_account_id ,
          g_inact_keys_tab(ln_cnt).rel_cust_account_id , 
          g_inact_keys_tab(ln_cnt).relate_class
        );
        FETCH customer_relate_cur INTO l_cust_rel_rowid, lt_cust_rel_obj_v_number;
        CLOSE customer_relate_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_lock_table := cv_tkv_lock_cust_rel;
          RAISE global_check_lock_expt;
      END;
      --
      --==============================================================
      -- A-7.2 �ڋq�֘A �X�V�p���R�[�h�擾
      --==============================================================
      lv_step := 'A-7.2';
      -- �W��API:�ڋq�֘A�擾
      hz_cust_account_v2pub.get_cust_acct_relate_rec(
        p_init_msg_list            =>  lv_init_msg_list                             -- 1.�������b�Z�[�W���X�g
       ,p_cust_account_id          =>  g_inact_keys_tab(ln_cnt).cust_account_id     -- 2.�ڋqID
       ,p_related_cust_account_id  =>  g_inact_keys_tab(ln_cnt).rel_cust_account_id -- 3.�֘A�ڋqID
       ,p_rowid                    =>  l_cust_rel_rowid                             -- 4.ROWID
       ,x_cust_acct_relate_rec     =>  l_cust_acct_relate_rec
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        lv_api_name := cv_tkv_apinm_cu_get;
        lv_api_step := cv_tkv_apist_cu_get;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      --==============================================================
      -- A-7.3 �ڋq�֘A �X�V�p���R�[�h�ҏW���X�V
      --==============================================================
      lv_step := 'A-7.3';
      l_cust_acct_relate_rec.relationship_type         := cv_relationship_type_all;              -- �֘A�ڋq�^�C�v
      l_cust_acct_relate_rec.attribute1                := g_inact_keys_tab(ln_cnt).relate_class; -- DFF1(�֘A����)
      l_cust_acct_relate_rec.customer_reciprocal_flag  := cv_acc_no;                             -- ���݊֘A�L��:'N'(����)
      l_cust_acct_relate_rec.status                    := cv_inactive_set;                       -- �X�e�[�^�X:'I'(����)
      l_cust_acct_relate_rec.bill_to_flag              := cv_acc_yes;                            -- �g�p�ړI(������):'Y'(�L��)
      l_cust_acct_relate_rec.ship_to_flag              := cv_acc_yes;                            -- �g�p�ړI(�o�א�):'Y'(�L��)
      --
      -- �W��API:�ڋq�֘A�X�V
      hz_cust_account_v2pub.update_cust_acct_relate(
        p_init_msg_list            =>  lv_init_msg_list            -- 1.�������b�Z�[�W���X�g
       ,p_cust_acct_relate_rec     =>  l_cust_acct_relate_rec      -- 2.�ڋq�֘A�X�V�p���R�[�h
       ,p_object_version_number    =>  lt_cust_rel_obj_v_number    -- 3.�I�u�W�F�N�g�o�[�W�����ԍ�
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_cu_upload;
        lv_api_step := cv_tkv_apist_cu_upload;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      -- �֘A���ނ��u�����v�̏ꍇ�A�����掖�Ə����X�V
      IF ( g_inact_keys_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
         --==============================================================
         -- A-7.4.1 �o�א掖�Ə� ���擾�����b�N
         --==============================================================
         lv_step := 'A-7.4.1';
         -- �������̃L�[�����Ɏ擾
         BEGIN
           OPEN get_inact_site_uses_cur(
             g_inact_keys_tab(ln_cnt).rel_cust_account_id
           );
           FETCH get_inact_site_uses_cur INTO lt_ship_site_use_id , lt_ship_suse_obj_v_number , lt_bill_site_use_id;
           CLOSE get_inact_site_uses_cur;
         EXCEPTION
           WHEN OTHERS THEN
             lv_lock_table := cv_tkv_lock_cust_rel || cv_msg_comma || cv_tkv_lock_cust_site || cv_msg_comma || cv_tkv_lock_cust_uses;
             RAISE global_check_lock_expt;
         END;
         --
         --==============================================================
         -- A-7.4.2 �o�א掖�Ə� �X�V�p���R�[�h�擾
         --==============================================================
         lv_step := 'A-7.4.2';
         -- �W��API:�ڋq�g�p�ړI �擾
         hz_cust_account_site_v2pub.get_cust_site_use_rec(
           p_init_msg_list            =>  lv_init_msg_list          -- 1.�������b�Z�[�W���X�g
          ,p_site_use_id              =>  lt_ship_site_use_id       -- 2.�֘A��_�g�p�ړI�h�c
          ,x_cust_site_use_rec        =>  l_cust_site_use_rec
          ,x_customer_profile_rec     =>  l_customer_profile_rec
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --�X�e�[�^�X�m�F
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_get;
           lv_api_step := cv_tkv_apist_suse_get;
           ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
         --
         --==============================================================
         -- A-7.4.3 �o�א掖�Ə� �X�V�p���R�[�h�ҏW���X�V
         --==============================================================
         lv_step := 'A-7.4.3';
         l_cust_site_use_rec.bill_to_site_use_id := lt_bill_site_use_id;
         --
         -- �W��API:�ڋq�g�p�ړI �X�V
         hz_cust_account_site_v2pub.update_cust_site_use(
           p_init_msg_list            =>  lv_init_msg_list            -- 1.�������b�Z�[�W���X�g
          ,p_cust_site_use_rec        =>  l_cust_site_use_rec         -- 2.�ڋq�g�p�ړI�i�o�א�j�X�V�p���R�[�h
          ,p_object_version_number    =>  lt_ship_suse_obj_v_number   -- 3.�֘A��_�I�u�W�F�N�g�o�[�W����No
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --�X�e�[�^�X�m�F
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_upld;
           lv_api_step := cv_tkv_apist_suse_upld;
           ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
      END IF;
    END LOOP custrel_inact_loop;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00008          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_ng_table             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_lock_table               -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --
    -- *** �W��API ��O�n���h�� ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10354            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_api_step               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_api_step                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_name                   -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => ln_line_no                    -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- �g�[�N���R�[�h4
                    ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_cust_rel_inact;
--
  /**********************************************************************************
   * Procedure Name   : proc_cust_rel_active
   * Description      : �ڋq�֘A�L�����f�[�^�o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE proc_cust_rel_active(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_rel_active'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- �ڋq�g�p�ړI �X�V�p
    lt_site_use_id            hz_cust_site_uses_all.site_use_id%TYPE;               -- �ڋq���Ə�(�֘A��).�g�p�ړIID
    lt_suse_obj_v_number      hz_cust_site_uses_all.object_version_number%TYPE;     -- �ڋq���Ə�(�֘A��).�I�u�W�F�N�g�o�[�W�����ԍ�
    lt_rel_site_use_id        hz_cust_site_uses_all.site_use_id%TYPE;               -- �ڋq���Ə�(�֘A��).�g�p�ړIID
    lt_rel_suse_obj_v_number  hz_cust_site_uses_all.object_version_number%TYPE;     -- �ڋq���Ə�(�֘A��).�I�u�W�F�N�g�o�[�W�����ԍ�
    -- �W��API�ďo�p
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                        -- �������b�Z�[�W
    l_cust_acct_relate_rec    hz_cust_account_v2pub.cust_acct_relate_rec_type;      -- �ڋq�֘A�o�^�p���R�[�h
    l_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;    -- �ڋq�g�p�ړI�擾�p���R�[�h
    l_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;  -- �ڋq�v���t�@�C���擾�p���R�[�h
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ������o�א掖�Ə���� �擾
    CURSOR get_act_site_uses_cur(
      p_cust_account_id       NUMBER ,    -- �֘A���ڋq �ڋqID
      p_rel_cust_account_id   NUMBER      -- �֘A��ڋq �ڋqID
    )IS
      SELECT hcsua.site_use_id               AS site_use_id               -- �ڋq���Ə�(�֘A��).�g�p�ړI�h�c
           , hcsua.object_version_number     AS obj_ver_number            -- �ڋq���Ə�(�֘A��).�I�u�W�F�N�g�o�[�W����No
           , hcsua_rel.site_use_id           AS rel_site_use_id           -- �ڋq���Ə�(�֘A��).�g�p�ړI�h�c
           , hcsua_rel.object_version_number AS rel_obj_ver_number        -- �ڋq���Ə�(�֘A��).�I�u�W�F�N�g�o�[�W����No
        FROM hz_cust_acct_relate_all         hcara                        -- �ڋq�֘A
           , hz_cust_acct_sites_all          hcasa                        -- �֘A�� �ڋq�T�C�g
           , hz_cust_acct_sites_all          hcasa_rel                    -- �֘A�� �ڋq�T�C�g
           , hz_cust_site_uses_all           hcsua                        -- �֘A�� �ڋq���Ə�
           , hz_cust_site_uses_all           hcsua_rel                    -- �֘A�� �ڋq���Ə�
       WHERE -- �֘A�����
             hcara.cust_account_id         = p_cust_account_id            -- �ڋq�A�J�E���g�h�c
         AND hcara.cust_account_id         = hcasa.cust_account_id        -- �ڋq�A�J�E���g�h�c
         AND hcasa.org_id                  = gv_org_id                    -- �g�D�h�c
         AND hcasa.cust_acct_site_id       = hcsua.cust_acct_site_id      -- �ڋq�T�C�g�h�c
         AND hcsua.site_use_code           = cv_site_use_bill_to          -- �g�p�ړI:'������'
            -- �֘A����
         AND hcara.related_cust_account_id = p_rel_cust_account_id        -- �ڋq�֘A_�A�J�E���g�h�c
         AND hcara.related_cust_account_id = hcasa_rel.cust_account_id    -- �ڋq�A�J�E���g�h�c
         AND hcasa_rel.org_id              = gv_org_id                    -- �g�D�h�c
         AND hcasa_rel.cust_acct_site_id   = hcsua_rel.cust_acct_site_id  -- �ڋq�T�C�g�h�c
         AND hcsua_rel.site_use_code       = cv_site_use_ship_to          -- �g�p�ړI:'�o�א�'
         AND ROWNUM                        = 1
      FOR UPDATE NOWAIT
      ;
    -- *** ���[�J�����[�U�[��`��O ***
    v2pub_err_expt                 EXCEPTION;               -- �W��API�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- �L�����f�[�^�S�Ă��X�V
    <<custrel_active_loop>>
    FOR ln_cnt IN 1..g_act_keys_tab.COUNT LOOP
      --==============================================================
      -- A-8.1 �ڋq�֘A �o�^�p���R�[�h�ҏW���o�^
      --==============================================================
      lv_step := 'A-8.1';
      l_cust_acct_relate_rec.cust_account_id           := g_act_keys_tab(ln_cnt).cust_account_id;     -- �ڋq�A�J�E���gID
      l_cust_acct_relate_rec.related_cust_account_id   := g_act_keys_tab(ln_cnt).rel_cust_account_id; -- �֘A�ڋq�A�J�E���gID
      l_cust_acct_relate_rec.relationship_type         := cv_relationship_type_all;                   -- �֘A�ڋq�^�C�v
      l_cust_acct_relate_rec.attribute1                := g_act_keys_tab(ln_cnt).relate_class;        -- DFF1(�֘A����)
      l_cust_acct_relate_rec.customer_reciprocal_flag  := cv_acc_no;                                  -- ���݊֘A�L��:'N'(����)
      l_cust_acct_relate_rec.status                    := cv_active_set;                              -- �X�e�[�^�X:'A'(�L��)
      l_cust_acct_relate_rec.bill_to_flag              := cv_acc_yes;                                 -- �g�p�ړI(������):'Y'(�L��)
      l_cust_acct_relate_rec.ship_to_flag              := cv_acc_yes;                                 -- �g�p�ړI(�o�א�):'Y'(�L��)
      l_cust_acct_relate_rec.created_by_module         := cv_pkg_name;                                -- WHO�J����.�v���O����ID
      --
      -- �W��API:�ڋq�֘A�o�^
      hz_cust_account_v2pub.create_cust_acct_relate(
        p_init_msg_list            =>  lv_init_msg_list             -- 1.�������b�Z�[�W���X�g
       ,p_cust_acct_relate_rec     =>  l_cust_acct_relate_rec       -- 2.�ڋq�֘A�o�^�p���R�[�h
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --�X�e�[�^�X�m�F
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_cu_create;
        lv_api_step := cv_tkv_apist_cu_create;
        ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      -- �֘A���ނ��u�����v�̏ꍇ�A�����掖�Ə����X�V
      IF ( g_act_keys_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
         --==============================================================
         -- A-8.2.1 �o�א掖�Ə� ���擾�����b�N
         --==============================================================
         lv_step := 'A-8.2.1';
         -- �L�����̃L�[�����Ɏ擾
         BEGIN
           OPEN get_act_site_uses_cur(
             g_act_keys_tab(ln_cnt).cust_account_id ,
             g_act_keys_tab(ln_cnt).rel_cust_account_id
           );
           FETCH get_act_site_uses_cur INTO lt_site_use_id , lt_suse_obj_v_number , lt_rel_site_use_id , lt_rel_suse_obj_v_number;
           CLOSE get_act_site_uses_cur;
         EXCEPTION
           WHEN OTHERS THEN
             lv_lock_table := cv_tkv_lock_cust_rel || cv_msg_comma || cv_tkv_lock_cust_site || cv_msg_comma || cv_tkv_lock_cust_uses;
             RAISE global_check_lock_expt;
         END;
         --
         --==============================================================
         -- A-8.2.2 �o�א掖�Ə� �X�V�p���R�[�h�擾
         --==============================================================
         lv_step := 'A-8.2.2';
         -- �W��API:�ڋq�g�p�ړI �擾
         hz_cust_account_site_v2pub.get_cust_site_use_rec(
           p_init_msg_list            =>  lv_init_msg_list          -- 1.�������b�Z�[�W���X�g
          ,p_site_use_id              =>  lt_rel_site_use_id        -- 2.�֘A��_�g�p�ړI�h�c
          ,x_cust_site_use_rec        =>  l_cust_site_use_rec
          ,x_customer_profile_rec     =>  l_customer_profile_rec
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --�X�e�[�^�X�m�F
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_get;
           lv_api_step := cv_tkv_apist_suse_get;
           ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
         --
         --==============================================================
         -- A-8.2.3 �o�א掖�Ə� �X�V�p���R�[�h�ҏW���X�V
         --==============================================================
         lv_step := 'A-8.2.3';
         l_cust_site_use_rec.bill_to_site_use_id := lt_site_use_id;
         --
         -- �W��API:�ڋq�g�p�ړI �X�V
         hz_cust_account_site_v2pub.update_cust_site_use(
           p_init_msg_list            =>  lv_init_msg_list            -- 1.�������b�Z�[�W���X�g
          ,p_cust_site_use_rec        =>  l_cust_site_use_rec         -- 2.�ڋq�g�p�ړI�i�o�א�j�X�V�p���R�[�h
          ,p_object_version_number    =>  lt_rel_suse_obj_v_number    -- 3.�֘A��_�I�u�W�F�N�g�o�[�W����No
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --�X�e�[�^�X�m�F
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_upld;
           lv_api_step := cv_tkv_apist_suse_upld;
           ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
      END IF;
    END LOOP custrel_active_loop;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00008          -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_ng_table             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_lock_table               -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      --
    -- *** �W��API ��O�n���h�� ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10354            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_api_step               -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_api_step                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_name                   -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => ln_line_no                    -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- �g�[�N���R�[�h4
                    ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_cust_rel_active;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                         -- �X�e�b�v
    lv_check_status           VARCHAR2(1);                          -- �X�e�[�^�X
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
    lv_check_status := cv_status_normal;
    --
    --==============================================================
    -- LOOP B:�ڋq�֘A���R�[�hLOOP START
    --==============================================================
    <<main_loop>>
    FOR get_wk_cust_rel_rec IN get_wk_cust_rel_cur LOOP
      --==============================================================
      -- A-4  �f�[�^�Ó����`�F�b�N
      --==============================================================
      lv_step := 'A-4';
      validate_cust_wrel(
        i_cust_rel_rec     => get_wk_cust_rel_rec      -- �ڋq�ꊇ�o�^���[�N���
       ,ov_errbuf          => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ���팏�����Z
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- �f�[�^�Ó����`�F�b�N�G���[�̏ꍇ�A�G���[�X�e�[�^�X�ޔ�
        lv_check_status := cv_status_error;
        -- �G���[�������Z
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --
    END LOOP main_loop;
    --==============================================================
    -- LOOP B:�ڋq�֘A���R�[�hLOOP END
    --==============================================================
    -- �Ó����A�o�^�G���[�̏ꍇ�A�G���[���Z�b�g
    IF ( lv_check_status = cv_status_error ) THEN
       ov_retcode := cv_status_error;
    END IF;
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
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J�� ���[�U�[��`�^ ***
    TYPE l_check_data_ttype  IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_step_status            VARCHAR2(1);                            -- STEP�`�F�b�N
    ln_line_cnt               NUMBER;                                 -- �s�J�E���^
    ln_column_cnt             NUMBER;                                 -- ���ڐ��J�E���^
    ln_ins_cnt                NUMBER;                                 -- �o�^�����J�E���^
    ln_item_num               NUMBER;                                 -- ���ڐ�
    lv_tkn_value              VARCHAR2(100);                          -- �g�[�N���l
--
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- IF�e�[�u���擾�p
    l_wk_item_tab             l_check_data_ttype;                     -- �e�[�u���^�ϐ���錾(���ڕ���)
    -- *** ���[�J�����[�U�[��`��O ***
    get_if_data_expt               EXCEPTION;                         -- �f�[�^���ڐ��G���[
    wk_cust_rel_ins_expt           EXCEPTION;                         -- �f�[�^�o�^�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --������
    ln_ins_cnt := 0;
    --
    --==============================================================
    -- A-2.1 �t�@�C���A�b�v���[�hIF�e�[�u���擾
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id                 -- �t�@�C��ID
     ,ov_file_data => l_if_data_tab              -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- LOOP A:���R�[�hLOOP START ��1�s�ڂ̓w�b�_���ׁ̈A2�s�ڈȍ~���擾
    --==============================================================
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
      ln_ins_cnt := ln_ins_cnt + 1;
      --==============================================================
      -- A-2.2 ���ڐ��̃`�F�b�N
      --==============================================================
      lv_step := 'A-2.2';
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt) )
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        lv_tkn_value := TO_CHAR(ln_item_num);
        RAISE get_if_data_expt;
      END IF;
      --==============================================================
      -- A-2.3  ���ڂ̕������`�F�b�N
      --==============================================================
      lv_step := 'A-2.3';
      lv_step_status := cv_status_normal;
      <<get_column_loop>>
      FOR ln_column_cnt IN 1..gn_item_num LOOP
        -- �ϐ��ɍ��ڂ̒l���i�[
        l_wk_item_tab(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(        -- �f���~�^�����ϊ����ʊ֐�
                                          iv_char     => l_if_data_tab(ln_line_cnt)   -- ������������
                                         ,iv_delim    => cv_msg_comma                 -- �f���~�^
                                         ,in_part_num => ln_column_cnt                -- �擾�Ώۂ̍���Index
                                        );
        -- ���ڂ̃`�F�b�N
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_cust_rel_def_tab(ln_column_cnt).item_name         -- ���ږ���
         ,iv_item_value   => l_wk_item_tab(ln_column_cnt)                        -- ���ڂ̒l
         ,in_item_len     => g_cust_rel_def_tab(ln_column_cnt).int_length        -- ���ڂ̒���(��������)
         ,in_item_decimal => g_cust_rel_def_tab(ln_column_cnt).dec_length        -- ���ڂ̒���(�����_�ȉ�)
         ,iv_item_nullflg => g_cust_rel_def_tab(ln_column_cnt).item_essential    -- �K�{�t���O
         ,iv_item_attr    => g_cust_rel_def_tab(ln_column_cnt).item_attribute    -- ���ڂ̑���
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- ���ڃ`�F�b�N���ʂ�����ȊO�̏ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN 
          lv_step_status := cv_status_error;
          -- �l�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_10338          -- ���b�Z�[�W
                      ,iv_token_name1   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_errmsg               -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
      END LOOP get_column_loop;
      -- �߂�l�X�V
      IF ( lv_step_status = cv_status_error ) THEN
         ov_retcode := cv_status_error;
      END IF;
      --==============================================================
      -- A-2.4   �ڋq�֘A�ꊇ�X�V�p���[�N�e�[�u���֓o�^
      --==============================================================
      IF ( lv_step_status = cv_status_normal ) THEN 
        lv_step := 'A-2.4';
        BEGIN
          -- �t�H�[�}�b�g�p�^�[���u�p�[�e�B�֘A�v�̏ꍇ
          IF ( gv_format = cv_file_format_pa ) THEN
              INSERT INTO xxcmm_wk_cust_relate_upload(
                 file_id                                -- �t�@�C��ID
                ,line_no                                -- �s�ԍ�
                ,customer_class_code                    -- �ڋq�敪
                ,customer_code                          -- �ڋq�R�[�h
                ,rel_customer_class_code                -- �֘A��ڋq�敪
                ,rel_customer_code                      -- �֘A��ڋq�R�[�h
                ,relate_class                           -- �ڋq�֘A����
                ,status                                 -- �o�^�X�e�[�^�X
                ,relate_apply_date                      -- �֘A�K�p��
                ,created_by                             -- WHO:�쐬��
                ,creation_date                          -- WHO:�쐬��
                ,last_updated_by                        -- WHO:�ŏI�X�V��
                ,last_update_date                       -- WHO:�ŏI�X�V��
                ,last_update_login                      -- WHO:�ŏI�X�V���O�C��
                ,request_id                             -- WHO:�v��ID
                ,program_application_id                 -- WHO:�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                             -- WHO:�R���J�����g�E�v���O����ID
                ,program_update_date                    -- WHO:�v���O�����X�V��
              ) VALUES (
                gn_file_id                              -- �t�@�C��ID
               ,ln_ins_cnt                              -- �t�@�C��SEQ
               ,l_wk_item_tab(1)                        -- �ڋq�敪
               ,l_wk_item_tab(2)                        -- �ڋq�R�[�h
               ,l_wk_item_tab(3)                        -- �֘A��ڋq�敪
               ,l_wk_item_tab(4)                        -- �֘A��ڋq�R�[�h
               ,NULL                                    -- �ڋq�֘A����
               ,l_wk_item_tab(5)                        -- �o�^�X�e�[�^�X
               ,TO_DATE(l_wk_item_tab(6),'YYYY/MM/DD')  -- �֘A�K�p��
               ,cn_created_by                           -- WHO:�쐬��
               ,cd_creation_date                        -- WHO:�쐬��
               ,cn_last_updated_by                      -- WHO:�ŏI�X�V��
               ,cd_last_update_date                     -- WHO:�ŏI�X�V��
               ,cn_last_update_login                    -- WHO:�ŏI�X�V���O�C��
               ,cn_request_id                           -- WHO:�v��ID
               ,cn_program_application_id               -- WHO:�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,cn_program_id                           -- WHO:�R���J�����g�E�v���O����ID
               ,cd_program_update_date                  -- WHO:�v���O�����ɂ��X�V��
              );
          END IF;
          -- �t�H�[�}�b�g�p�^�[���u�ڋq�֘A�v�̏ꍇ
          IF ( gv_format = cv_file_format_cu ) THEN
              INSERT INTO xxcmm_wk_cust_relate_upload(
                 file_id                                -- �t�@�C��ID
                ,line_no                                -- �s�ԍ�
                ,customer_class_code                    -- �ڋq�敪
                ,customer_code                          -- �ڋq�R�[�h
                ,rel_customer_class_code                -- �֘A��ڋq�敪
                ,rel_customer_code                      -- �֘A��ڋq�R�[�h
                ,relate_class                           -- �ڋq�֘A����
                ,status                                 -- �o�^�X�e�[�^�X
                ,relate_apply_date                      -- �֘A�K�p��
                ,created_by                             -- WHO:�쐬��
                ,creation_date                          -- WHO:�쐬��
                ,last_updated_by                        -- WHO:�ŏI�X�V��
                ,last_update_date                       -- WHO:�ŏI�X�V��
                ,last_update_login                      -- WHO:�ŏI�X�V���O�C��
                ,request_id                             -- WHO:�v��ID
                ,program_application_id                 -- WHO:�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                             -- WHO:�R���J�����g�E�v���O����ID
                ,program_update_date                    -- WHO:�v���O�����X�V��
              ) VALUES (
                gn_file_id                              -- �t�@�C��ID
               ,ln_ins_cnt                              -- �t�@�C��SEQ
               ,l_wk_item_tab(1)                        -- �ڋq�敪
               ,l_wk_item_tab(2)                        -- �ڋq�R�[�h
               ,l_wk_item_tab(3)                        -- �֘A��ڋq�敪
               ,l_wk_item_tab(4)                        -- �֘A��ڋq�R�[�h
               ,l_wk_item_tab(5)                        -- �ڋq�֘A����
               ,l_wk_item_tab(6)                        -- �o�^�X�e�[�^�X
               ,NULL                                    -- �֘A�K�p��
               ,cn_created_by                           -- WHO:�쐬��
               ,cd_creation_date                        -- WHO:�쐬��
               ,cn_last_updated_by                      -- WHO:�ŏI�X�V��
               ,cd_last_update_date                     -- WHO:�ŏI�X�V��
               ,cn_last_update_login                    -- WHO:�ŏI�X�V���O�C��
               ,cn_request_id                           -- WHO:�v��ID
               ,cn_program_application_id               -- WHO:�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,cn_program_id                           -- WHO:�R���J�����g�E�v���O����ID
               ,cd_program_update_date                  -- WHO:�v���O�����ɂ��X�V��
              );
          END IF;
        EXCEPTION
          -- *** �f�[�^�o�^��O�n���h�� ***
          WHEN OTHERS THEN
            lv_tkn_value := TO_CHAR( ln_ins_cnt );
            RAISE wk_cust_rel_ins_expt;
        END;
      END IF;
    END LOOP ins_wk_loop;
    --
    --==============================================================
    -- LOOP A:���R�[�hLOOP END
    --==============================================================
    -- �����Ώی������i�[(�w�b�_����������)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
--
  EXCEPTION
    -- *** �f�[�^���ڐ��G���[��O�n���h�� ***
    WHEN get_if_data_expt THEN                   --*** <��O�R�����g> ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00028            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_tkv_table_xwk_cust         -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_count                  -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_tkn_value                  -- �g�[�N���l2
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�o�^�G���[�n���h�� ****
    WHEN wk_cust_rel_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm           -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_10335           -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkv_table_xwk_cust        -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_input_line_no         -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_tkn_value                 -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h4
                     ,iv_token_value3 => SQLERRM                      -- �g�[�N���l4
                    );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������(A-9)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_check_status           VARCHAR2(1);                            -- �`�F�b�N�X�e�[�^�X
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
    -- �`�F�b�N�X�e�[�^�X�̏�����
    lv_check_status := cv_status_normal;
    --
    --==============================================================
    -- A-9.1 �ڋq�֘A�ꊇ�X�V�f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_cust_relate_upload xwcru
       WHERE xwcru.request_id = cn_request_id    --�v��ID
      ;
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �f�[�^�폜�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00012          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkv_table_xwk_cust       -- �g�[�N���l1
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
    --==============================================================
    -- A-9.2 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-9.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �f�[�^�폜�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00012          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tkv_table_file_if        -- �g�[�N���l1
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2      -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2      -- 2.�t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    --
    -- *** ���[�J�����[�U�[��`��O ***
    sub_proc_expt             EXCEPTION;                              -- �T�u�v���O�����G���[
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
    gn_inact_cnt  := 0;
    gn_active_cnt := 0;
--
    --==============================================================
    -- A-1.  ��������
    --==============================================================
    lv_step := 'A-1';
    init(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g�p�^�[��
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �ُ팏���ݒ�
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_data���R�[��
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �ُ팏���ݒ�
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-3  �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�擾
    --  A-4  �ڋq�֘A�ꊇ�X�V�p���[�N�f�[�^�Ó����`�F�b�N
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �ُ팏���̐ݒ�͖���(A-4�̒��ňُ팏���̃J�E���g��������)
      RAISE sub_proc_expt;
    END IF;
--    
    -- �t�H�[�}�b�g�p�^�[�����p�[�e�B�֘A�̏ꍇ
    IF ( gv_format = cv_file_format_pa ) THEN
      --==============================================================
      -- A-5  �p�[�e�B�֘A�������f�[�^�X�V����
      --==============================================================
      lv_step := 'A-5'; 
      proc_party_rel_inact(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �ُ팏���ݒ�
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
      --==============================================================
      -- A-6  �p�[�e�B�֘A�L�����f�[�^�o�^����
      --==============================================================
      lv_step := 'A-6'; 
      proc_party_rel_active(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �ُ팏���ݒ�
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
    END IF;
--
    -- �t�H�[�}�b�g�p�^�[�����ڋq�֘A�̏ꍇ
    IF ( gv_format = cv_file_format_cu ) THEN
      --==============================================================
      -- A-7  �ڋq�֘A�������f�[�^�X�V����
      --==============================================================
      lv_step := 'A-7'; 
      proc_cust_rel_inact(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �ُ팏���ݒ�
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
      --==============================================================
      -- A-8  �ڋq�֘A�L�����f�[�^�o�^����
      --==============================================================
      lv_step := 'A-8'; 
      proc_cust_rel_active(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �ُ팏���ݒ�
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- A-7  �I������
    --==============================================================
    lv_step := 'A-9';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �ُ팏���ݒ�
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
  EXCEPTION
    -- *** �T�u�v���O�����G���[ ****
    WHEN sub_proc_expt THEN
      gn_normal_cnt := 0;           -- �G���[�������͐��팏��=0���ŕԂ��܂��B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf                  OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                 OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_file_id              IN  VARCHAR2      --   �t�@�C��ID
   ,iv_format               IN  VARCHAR2      --   �t�H�[�}�b�g�p�^�[��
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
      iv_file_id            => iv_file_id               -- �t�@�C��ID
     ,iv_format             => iv_format                -- �t�H�[�}�b�g�p�^�[��
     ,ov_errbuf             => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
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
    --
    -- �G���[������ΐ��팏����0���ŕԂ��܂�
    IF ( gn_error_cnt > 0 ) THEN
      gn_normal_cnt := 0;
    END IF;
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X������ȊO�̏ꍇ��ROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
      ROLLBACK;
    ELSE
      -- COMMIT���s
      COMMIT;
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
END XXCMM003A41C;
/
