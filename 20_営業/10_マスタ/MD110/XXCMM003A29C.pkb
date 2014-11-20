CREATE OR REPLACE PACKAGE BODY XXCMM003A29C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A29C(body)
 * Description      : �ڋq�ꊇ�X�V
 * MD.050           : MD050_CMM_003_A29_�ڋq�ꊇ�X�V
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cust_data_make_wk      �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
 *  rock_and_update_cust   �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
 *  close_process          �I������(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ���� �S��        �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --���b�Z�[�W�敪
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --���b�Z�[�W�敪
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_org_id        NUMBER(15)  :=  fnd_global.org_id; --org_id
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
  get_csv_err_expt          EXCEPTION; --�ڋq�ꊇ�X�V�pCSV�擾�G���[
  invalid_data_expt         EXCEPTION; --�ڋq�ꊇ�X�V���s����O
--
  update_cust_err_expt      EXCEPTION; --�ڋq�}�X�^�X�V�G���[
  update_party_err_expt     EXCEPTION; --�p�[�e�B�}�X�^�X�V�G���[
  update_csu_err_expt       EXCEPTION; --�ڋq�g�p�ړI�}�X�^�X�V�G���[
  update_location_err_expt  EXCEPTION; --�ڋq���Ə��}�X�^�X�V�G���[
--
  cust_rock_err_expt        EXCEPTION; --���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(cust_rock_err_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(12)  := 'XXCMM003A29C';                    --�p�b�P�[�W��
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                               --�J���}
  --
  cv_header_str_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00332';                --CSV�t�@�C���w�b�_������
  cv_no_csv_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00312';                --�ڋq�ꊇ�X�V�pCSV�擾���s���b�Z�[�W
  cv_parameter_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';                --���̓p�����[�^�m�[�g
  cv_file_name_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';                --�t�@�C�����m�[�g
  --�G���[���b�Z�[�W
  cv_required_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00342';                --�K�{���ڃG���[
  cv_val_form_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00322';                --�^�E�����G���[���b�Z�[�W
  cv_lookup_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00314';                --�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W
  cv_mst_err_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00316';                --�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  cv_double_byte_kana_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00317';                --�S�p�J�^�J�i�`�F�b�N�G���[���b�Z�[�W
  cv_status_func_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00336';                --�ڋq�X�e�[�^�X�ύX�G���[�i�J�ڕs�j
  cv_status_modify_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00319';                --�ڋq�X�e�[�^�X�ύX�`�F�b�N�G���[���b�Z�[�W
  cv_trust_val_invalid        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00315';                --�l�G���[
  cv_cust_addon_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00320';                --�ڋq�ǉ����}�X�^���݃`�F�b�N�G���[
  cv_corp_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00321';                --�ڋq�@�l���}�X�^���݃`�F�b�N�G���[
  cv_invalid_data_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00337';                --�f�[�^�G���[���o�̓��b�Z�[�W
  cv_invalid_header_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00338';                --�w�b�_�G���[�����b�Z�[�W
  cv_rock_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00313';                --���b�N�G���[�����b�Z�[�W
  cv_update_cust_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00323';                --�ڋq�}�X�^�X�V�G���[�����b�Z�[�W
  cv_update_party_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00324';                --�p�[�e�B�}�X�^�X�V�G���[�����b�Z�[�W
  cv_update_csu_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00325';                --�ڋq�g�p�ړI�G���[�����b�Z�[�W
  cv_update_location_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00326';                --�ڋq���Ə��G���[�����b�Z�[�W
--
  cv_param                    CONSTANT VARCHAR2(5)   := 'PARAM';                           --�p�����[�^�g�[�N��
  cv_value                    CONSTANT VARCHAR2(5)   := 'VALUE';                           --�p�����[�^�l�g�[�N��
  cv_item                     CONSTANT VARCHAR2(4)   := 'ITEM';                            --ITEM�g�[�N��
  cv_file_id                  CONSTANT VARCHAR2(7)   := 'FILE_ID';                         --�p�����[�^�E�t�@�C��ID
  cv_file_content_type        CONSTANT VARCHAR2(17)  := 'FILE_CONTENT_TYPE';               --�p�����[�^�E�t�@�C���^�C�v
  cv_file_name                CONSTANT VARCHAR2(9)   := 'FILE_NAME';                       --�t�@�C�����g�[�N��
  cv_element_vc2              CONSTANT VARCHAR2(1)   := '0';                               --���ڑ����E���؂Ȃ�
  cv_element_num              CONSTANT VARCHAR2(1)   := '1';                               --���ڑ����E���l
  cv_element_dat              CONSTANT VARCHAR2(1)   := '2';                               --���ڑ����E���t
  cv_null_bar                 CONSTANT VARCHAR2(1)   := '-';                               --NULL�X�V����
  cv_null_ng                  CONSTANT VARCHAR2(7)   := 'NULL_NG';                         --�K�{�t���O�E�K�{
  cv_null_ok                  CONSTANT VARCHAR2(7)   := 'NULL_OK';                         --�K�{�t���O�E�C��
  cv_customer_class           CONSTANT VARCHAR2(14)  := 'CUSTOMER CLASS';                  --�Q�ƃ^�C�v�E�ڋq�敪
  cv_cust_code                CONSTANT VARCHAR2(9)   := 'CUST_CODE';                       --�ڋq�R�[�h�g�[�N��
  cv_cust                     CONSTANT VARCHAR2(10)  := '�ڋq�R�[�h';                      --�ڋq�R�[�h
  cv_business_low_type        CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_GYOTAI_SHO';           --�Q�ƃ^�C�v�E�Ƒԁi�����ށj
  cv_bus_low_type             CONSTANT VARCHAR2(14)  := '�Ƒԁi�����ށj';                  --�Ƒԁi�����ށj
  cv_customer_status          CONSTANT VARCHAR2(25)  := 'XXCMM_CUST_KOKYAKU_STATUS';       --�Q�ƃ^�C�v�E�ڋq�X�e�[�^�X
  cv_cust_status              CONSTANT VARCHAR2(14)  := '�ڋq�X�e�[�^�X';                  --�ڋq�X�e�[�^�X
  cv_pre_status               CONSTANT VARCHAR2(10)  := 'PRE_STATUS';                      --�ڋq�X�e�[�^�X�ύX�O�g�[�N��
  cv_will_status              CONSTANT VARCHAR2(11)  := 'WILL_STATUS';                     --�ڋq�X�e�[�^�X�ύX��g�[�N��
  cv_modify_err               CONSTANT VARCHAR2(1)   := '0';                               --�X�e�[�^�X�ύX�`�F�b�N�E�X�e�[�^�X�G���[
  cv_ret_code                 CONSTANT VARCHAR2(8)   := 'RET_CODE';                        --�X�e�[�^�X�ύX�`�F�b�N�E�X�e�[�^�X�g�[�N��
  cv_ret_msg                  CONSTANT VARCHAR2(7)   := 'RET_MSG';                         --�X�e�[�^�X�ύX�`�F�b�N�E���b�Z�[�W�g�[�N��
  cv_stop_approved            CONSTANT VARCHAR2(2)   := '90';                              --�ڋq�X�e�[�^�X�E���~���ύ�
  cv_approval_reason          CONSTANT VARCHAR2(22)  := 'XXCMM_CUST_CHUSHI_RIYU';          --�Q�ƃ^�C�v�E���~���R
  cv_appr_reason              CONSTANT VARCHAR2(8)   := '���~���R';                        --���~���R
  cv_appr_date                CONSTANT VARCHAR2(10)  := '���~���ϓ�';                      --���~���ϓ�
  cv_ar_invoice_code          CONSTANT VARCHAR2(22)  := 'XXCMM_INVOICE_GRP_CODE';          --�Q�ƃR�[�h�E���|�R�[�h�P�i�������j
  cv_ar_invoice               CONSTANT VARCHAR2(22)  := '���|�R�[�h�P�i�������j';          --���|�R�[�h�P�i�������j
  cv_ar_location_code         CONSTANT VARCHAR2(22)  := '���|�R�[�h�Q�i���Ə��j';          --���|�R�[�h�Q�i���Ə��j
  cv_ar_others_code           CONSTANT VARCHAR2(22)  := '���|�R�[�h�R�i���̑��j';          --���|�R�[�h�R�i���̑��j
  cv_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                           --�e�[�u���g�[�N��
  cv_invoice_class            CONSTANT VARCHAR2(29)  := 'XXCMM_CUST_SEKYUSYO_HAKKO_KBN';   --�Q�ƃR�[�h�E���������s�敪
  cv_invoice_kbn              CONSTANT VARCHAR2(14)  := '���������s�敪';                  --���������s�敪
  cv_invoice_issue_cycle      CONSTANT VARCHAR2(25)  := 'XXCMM_INVOICE_ISSUE_CYCLE';       --�Q�ƃR�[�h�E���������s�T�C�N��
  cv_invoice_cycle            CONSTANT VARCHAR2(18)  := '���������s�T�C�N��';              --���������s�T�C�N��
  cv_invoice_form             CONSTANT VARCHAR2(28)  := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';    --�Q�ƃR�[�h�E�������o�͌`��
  cv_invoice_ksk              CONSTANT VARCHAR2(14)  := '�������o�͌`��';                  --�������o�͌`��
  cv_payment_term_id          CONSTANT VARCHAR2(8)   := '�x������';                        --�x������
  cv_payment_term_second      CONSTANT VARCHAR2(11)  := '��2�x������';                     --��2�x������
  cv_payment_term_third       CONSTANT VARCHAR2(11)  := '��3�x������';                     --��3�x������
  cv_payment_term             CONSTANT VARCHAR2(14)  := '�x�������}�X�^';                  --�x������
  cv_xxcmm_chain_code         CONSTANT VARCHAR2(16)  := 'XXCMM_CHAIN_CODE';                --�Q�ƃR�[�h�E�`�F�[���X
  cv_sales_chain_code         CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�̔���j';      --�`�F�[���X�R�[�h�i�̔���j
  cv_delivery_chain_code      CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�[�i��j';      --�`�F�[���X�R�[�h�i�[�i��j
  cv_policy_chain_code        CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�����p�j';      --�`�F�[���X�R�[�h�i�����p�j
  cv_edi_chain                CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�d�c�h�j';      --�`�F�[���X�R�[�h�i�d�c�h�j
  cv_addon_cust_mst           CONSTANT VARCHAR2(18)  := '�ڋq�ǉ����}�X�^';              --�ڋq�ǉ����}�X�^�i������j
  cv_edi_class                CONSTANT VARCHAR2(2)   := '18';                              --�ڋq�敪�E�`�F�[���X
  cv_trust_corp               CONSTANT VARCHAR2(2)   := '13';                              --�ڋq�敪�E�@�l�ڋq�i�^�M�Ǘ���j
  cv_store_code               CONSTANT VARCHAR2(10)  := '�X�܃R�[�h';                      --�X�܃R�[�h
  cv_postal_code              CONSTANT VARCHAR2(8)   := '�X�֔ԍ�';                        --�X�֔ԍ�
  cv_state                    CONSTANT VARCHAR2(8)   := '�s���{��';                        --�s���{��
  cv_city                     CONSTANT VARCHAR2(6)   := '�s�E��';                          --�s�E��
  cv_address1                 CONSTANT VARCHAR2(5)   := '�Z��1';                           --�Z��1
  cv_address2                 CONSTANT VARCHAR2(5)   := '�Z��2';                           --�Z��2
  cv_address3                 CONSTANT VARCHAR2(10)  := '�n��R�[�h';                      --�n��R�[�h
  cv_cust_chiku_code          CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_CHIKU_CODE';           --�Q�ƃR�[�h�E�n��R�[�h
  cv_credit_limit             CONSTANT VARCHAR2(21)  := '�^�M���x�z';                      --�^�M���x�z
  cv_decide_div               CONSTANT VARCHAR2(20)  := 'XXCMM_CUST_SOHYO_KBN';            --�Q�ƃR�[�h�E����敪
  cv_decide                   CONSTANT VARCHAR2(8)   := '����敪';                        --����敪
--
  cv_cust_acct_table          CONSTANT VARCHAR2(16)  := 'HZ_CUST_ACCOUNTS';                --�ڋq�}�X�^
  cv_lookup_values            CONSTANT VARCHAR2(20)  := 'FND_LOOKUP_VALUES_VL';            --�Q�ƕ\�g�[�N��
  cv_col_name                 CONSTANT VARCHAR2(14)  := 'INPUT_COL_NAME';                  --�񖼃g�[�N��
  cv_input_val                CONSTANT VARCHAR2(15)  := 'INPUT_COL_VALUE';                 --�l�g�[�N��
  cv_cust_class               CONSTANT VARCHAR2(8)   := '�ڋq�敪';                        --�ڋq�敪�i�񖼁j
  cv_cust_class_us            CONSTANT VARCHAR2(10)  := 'CUST_CLASS';                      --�ڋq�敪�g�[�N��
  cv_cust_name                CONSTANT VARCHAR2(8)   := '�ڋq����';                        --�ڋq���́i�񖼁j
  cv_cust_name_kana           CONSTANT VARCHAR2(12)  := '�ڋq���̃J�i';                    --�ڋq���̃J�i�i�񖼁j
  cv_ryaku                    CONSTANT VARCHAR2(4)   := '����';                            --����
  cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY-MM-DD';                      --���t����
--
  cv_conc_request_id          CONSTANT VARCHAR2(15)  := 'CONC_REQUEST_ID';                 --�v��ID�擾�p������
  cv_prog_appl_id             CONSTANT VARCHAR2(12)  := 'PROG_APPL_ID';                    --�R���J�����g�E�v���O������A�v���P�[�V����ID�擾�p������
  cv_conc_program_id          CONSTANT VARCHAR2(15)  := 'CONC_PROGRAM_ID';                 --�R���J�����g�E�v���O����ID�擾�p������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : cust_data_make_wk
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
   ***********************************************************************************/
  PROCEDURE cust_data_make_wk(
    in_file_id              IN  NUMBER,       --   �t�@�C��ID
    iv_format_pattern       IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_data_make_wk'; -- �v���O������
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
    -- �\���̐錾
    lr_cust_data_table       xxccp_common_pkg2.g_file_data_tbl;
--
    lv_item_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_item_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_item_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    --�e�i�[�p�ϐ�
    lv_upload_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE := NULL;  --�t�@�C���A�b�v���[�hIF�e�[�u��.�t�@�C����
--
    lv_temp                  VARCHAR2(32767) := NULL;                     --�ڋq�ꊇ�X�V���[�N�e�[�u���o�^�p�ϐ�
    ln_index                 binary_integer;                              --������\���̎Q�Ɨp�Y��
    ln_first_data            NUMBER(1)       := 1;                        --�w�b�_�f�[�^���ʎq
    lr_cust_wk_table         xxcmm_wk_cust_batch_regist%ROWTYPE;          --�t�@�C���A�b�v���[�hIF�e�[�u���^���R�[�h�ϐ�
--
    ln_cust_id               hz_cust_accounts.cust_account_id%TYPE;       --���[�J���ϐ��ڋqID
    ln_party_id              hz_cust_accounts.party_id%TYPE;              --���[�J���ϐ��p�[�e�BID
    lv_customer_code         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�R�[�h
    lv_cust_code_mst         hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h���݊m�F�p�ϐ�
    ln_cust_addon_mst        xxcmm_cust_accounts.customer_id%TYPE;        --�ڋq�ǉ���񑶍݊m�F�p�ϐ�
    ln_cust_corp_mst         xxcmm_mst_corporate.customer_id%TYPE;        --�ڋq�@�l��񑶍݊m�F�p�ϐ�
    lv_customer_class        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�敪
    lv_cust_class_mst        hz_cust_accounts.customer_class_code%TYPE;   --�ڋq�敪���݊m�F�p�ϐ�
    lv_customer_name         VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�ڋq����
    lv_cust_name_kana        VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�ڋq���̃J�i
    lv_cust_name_ryaku       VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E����
    lv_customer_status       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�X�e�[�^�X
    lv_approval_reason       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���R
    lv_appr_reason_mst       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���R
    lv_approval_date         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���ϓ�
    lv_ar_invoice_code       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�P�i�������j
    lv_ar_invoice_code_mst   VARCHAR2(100)   := NULL;                     --���|�R�[�h�P�i�������j���݊m�F�p�ϐ�
    lv_ar_location_code      VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�Q�i���Ə��j
    lv_ar_others_code        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�R�i���̑��j
    lv_invoice_class         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���������s�敪
    lv_invoice_class_mst     VARCHAR2(100)   := NULL;                     --���������s�敪���݊m�F�p�ϐ�
    lv_invoice_cycle         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���������s�T�C�N��
    lv_invoice_cycle_mst     VARCHAR2(100)   := NULL;                     --���������s�T�C�N�����݊m�F�p�ϐ�
    lv_invoice_form          VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�������o�͌`��
    lv_invoice_form_mst      VARCHAR2(100)   := NULL;                     --�������o�͌`�����݊m�F�p�ϐ�
    lv_payment_term_id       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�x������
    lv_payment_term_id_mst   VARCHAR2(100)   := NULL;                     --�x���������݊m�F�p�ϐ�
    lv_payment_term_second   VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��2�x������
    lv_payment_second_mst    VARCHAR2(100)   := NULL;                     --��2�x���������݊m�F�p�ϐ�
    lv_payment_term_third    VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��3�x������
    lv_payment_third_mst     VARCHAR2(100)   := NULL;                     --��3�x���������݊m�F�p�ϐ�
    lv_sales_chain_code      VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�̔���j
    lv_sales_chain_code_mst  VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�̔���j���݊m�F�p�ϐ�
    lv_delivery_chain_code   VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�[�i��j
    lv_deliv_chain_code_mst  VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�̔���j���݊m�F�p�ϐ�
    lv_policy_chain_code     VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�����p�j
    lv_edi_chain_code        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�d�c�h�j
    lv_edi_chain_mst         VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�d�c�h�j���݊m�F�p�ϐ�
    lv_store_code            VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�X�܃R�[�h
    lv_postal_code           VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�X�֔ԍ�
    lv_state                 VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�s���{��
    lv_city                  VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�s�E��
    lv_address1              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�Z��1
    lv_address2              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�Z��2
    lv_address3              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�n��R�[�h
    lv_cust_chiku_code_mst   VARCHAR2(100)   := NULL;                     --�n��R�[�h���݊m�F�p�ϐ�
    lv_credit_limit          VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�^�M���x�z�i�����j
    ln_credit_limit          NUMBER          := NULL;                     --���[�J���ϐ��E�^�M���x�z�i���l�j
    lv_decide_div            VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E����敪
    lv_decide_div_mst        VARCHAR2(100)   := NULL;                     --����敪���݊m�F�p�ϐ�
--
    lv_cust_status_mst       hz_parties.duns_number_c%TYPE;               --�ڋq�X�e�[�^�X���݊m�F�p�ϐ�
    lv_get_cust_status       hz_parties.duns_number_c%TYPE;               --�ڋq�X�e�[�^�X���s�擾�p�ϐ�
--
    lv_business_low_type     VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E������
    lv_business_low_mst      xxcmm_cust_accounts.business_low_type%TYPE;  --�����ޑ��݊m�F�p�ϐ�
--
    lv_check_status          VARCHAR2(1)     := NULL;                     --���ڃ`�F�b�N���ʊi�[�p�ϐ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\��
    CURSOR check_upload_file_cur(
      in_file_id  IN NUMBER,
      iv_format   IN VARCHAR2)
    IS
      SELECT xmf.file_name  file_name
      FROM   xxccp_mrp_file_ul_interface  xmf
      WHERE  xmf.file_id           = in_file_id
      AND    xmf.file_content_type = iv_format
      ;
    -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\�����R�[�h�^
    check_upload_file_rec  check_upload_file_cur%ROWTYPE;
--
    -- �ڋq�R�[�h���݊m�F�J�[�\��
    CURSOR check_cust_code_cur(
      iv_cust_code IN VARCHAR2)
    IS
      SELECT hca.cust_account_id  cust_id,
             hca.account_number   cust_code,
             hca.party_id         party_id
      FROM   hz_cust_accounts     hca
      WHERE  hca.account_number = iv_cust_code
      ;
    -- �ڋq�R�[�h���݊m�F�J�[�\�����R�[�h�^
    check_cust_code_rec  check_cust_code_cur%ROWTYPE;
--
    -- �ڋq�ǉ���񑶍݊m�F�J�[�\��
    CURSOR check_cust_addon_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xca.customer_id      customer_id
      FROM   xxcmm_cust_accounts  xca
      WHERE  xca.customer_id    = in_cust_id
      ;
    -- �ڋq�ǉ���񑶍݊m�F�J�[�\�����R�[�h�^
    check_cust_addon_rec  check_cust_addon_cur%ROWTYPE;
--
    -- �ڋq�@�l��񑶍݊m�F�J�[�\��
    CURSOR check_cust_corp_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xmc.customer_id      customer_id
      FROM   xxcmm_mst_corporate  xmc
      WHERE  xmc.customer_id    = in_cust_id
      ;
    -- �ڋq�@�l��񑶍݊m�F�J�[�\�����R�[�h�^
    check_cust_corp_rec  check_cust_corp_cur%ROWTYPE;
--
    -- �ڋq�敪�`�F�b�N�J�[�\��
    CURSOR check_cust_class_cur(
      iv_cust_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_class
      AND    flvv.lookup_code = iv_cust_class
      ;
    -- �ڋq�敪�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_class_rec  check_cust_class_cur%ROWTYPE;
--
    -- �Ƒԁi�����ށj�`�F�b�N�J�[�\��
    CURSOR check_business_low_cur(
      iv_business_low_type IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      business_low_type
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_business_low_type
      AND    flvv.lookup_code = iv_business_low_type
      ;
    -- �Ƒԁi�����ށj�`�F�b�N�J�[�\�����R�[�h�^
    check_business_low_rec  check_business_low_cur%ROWTYPE;
--
    -- �ڋq�X�e�[�^�X�`�F�b�N�J�[�\��
    CURSOR check_cust_status_cur(
      iv_cust_status IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_status
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_status
      AND    flvv.lookup_code = iv_cust_status
      ;
    -- �ڋq�X�e�[�^�X�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_status_rec  check_cust_status_cur%ROWTYPE;
--
    -- �ڋq�X�e�[�^�X�擾�J�[�\��
    CURSOR get_cust_status_cur(
      in_paty_id IN NUMBER)
    IS
      SELECT duns_number_c  cust_status
      FROM   hz_parties     hp
      WHERE  hp.party_id = in_paty_id
      ;
    -- �ڋq�X�e�[�^�X�擾�J�[�\�����R�[�h�^
    get_cust_status_rec  get_cust_status_cur%ROWTYPE;
--
    -- ���~���R�`�F�b�N�J�[�\��
    CURSOR check_approval_reason_cur(
      iv_approval_reason IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      approval_reason
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_approval_reason
      AND    flvv.lookup_code = iv_approval_reason
      ;
    -- ���~���R�`�F�b�N�J�[�\�����R�[�h�^
    check_approval_reason_rec  check_approval_reason_cur%ROWTYPE;
--
    -- ���|�R�[�h�P�i�������j�`�F�b�N�J�[�\��
    CURSOR check_ar_invoice_code_cur(
      iv_ar_invoice_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      ar_invoice_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_ar_invoice_code
      AND    flvv.lookup_code = iv_ar_invoice_code
      ;
    -- ���|�R�[�h�P�i�������j�`�F�b�N�J�[�\�����R�[�h�^
    check_ar_invoice_code_rec  check_ar_invoice_code_cur%ROWTYPE;
--
    -- ���������s�敪�`�F�b�N�J�[�\��
    CURSOR check_invoice_class_cur(
      iv_invoice_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_class
      AND    flvv.lookup_code = iv_invoice_class
      ;
    -- ���������s�敪�`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_class_rec  check_invoice_class_cur%ROWTYPE;
--
    -- ���������s�T�C�N���`�F�b�N�J�[�\��
    CURSOR check_invoice_cycle_cur(
      iv_invoice_cycle IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_cycle
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_issue_cycle
      AND    flvv.lookup_code = iv_invoice_cycle
      ;
    -- ���������s�T�C�N���`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_cycle_rec  check_invoice_cycle_cur%ROWTYPE;
--
    -- �������o�͌`���`�F�b�N�J�[�\��
    CURSOR check_invoice_form_cur(
      iv_invoice_form IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_form
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_form
      AND    flvv.lookup_code = iv_invoice_form
      ;
    -- �������o�͌`���`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_form_rec  check_invoice_form_cur%ROWTYPE;
--
    -- �x�������`�F�b�N�J�[�\��
    CURSOR check_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.name   payment_term_id
      FROM   ra_terms  rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- �x�������`�F�b�N�J�[�\�����R�[�h�^
    check_payment_term_rec  check_payment_term_cur%ROWTYPE;
--
    -- �`�F�[���X�R�[�h�i�̔���j�`�F�b�N�J�[�\��
    CURSOR check_chain_code_cur(
      iv_chain_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      chain_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_xxcmm_chain_code
      AND    flvv.lookup_code = iv_chain_code
      ;
    -- �`�F�[���X�R�[�h�i�̔���j�`�F�b�N�J�[�\�����R�[�h�^
    check_chain_code_rec  check_chain_code_cur%ROWTYPE;
--
    -- �`�F�[���X�R�[�h�i�d�c�h�j�`�F�b�N�J�[�\��
    CURSOR check_edi_chain_cur(
      iv_edi_chain_code IN VARCHAR2)
    IS
      SELECT xca.edi_chain_code   edi_chain_code
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.customer_class_code = cv_edi_class
      AND    hca.cust_account_id     = xca.customer_id
      AND    xca.edi_chain_code      = iv_edi_chain_code
      AND    ROWNUM = 1
      ;
    -- �`�F�[���X�R�[�h�i�d�c�h�j�`�F�b�N�J�[�\�����R�[�h�^
    check_edi_chain_rec  check_edi_chain_cur%ROWTYPE;
--
    -- �n��R�[�h�`�F�b�N�J�[�\��
    CURSOR check_cust_chiku_code_cur(
      iv_cust_chiku_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_chiku_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_cust_chiku_code
      AND    flvv.lookup_code = iv_cust_chiku_code
      ;
    -- �n��R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_chiku_code_rec  check_cust_chiku_code_cur%ROWTYPE;
--
    -- ����敪�`�F�b�N�J�[�\��
    CURSOR check_decide_div_cur(
      iv_decide_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      decide_div
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_decide_div
      AND    flvv.lookup_code = iv_decide_div
      ;
    -- ����敪�`�F�b�N�J�[�\�����R�[�h�^
    check_decide_div_rec  check_decide_div_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ڋq�ꊇ�X�V�pCSV���擾
    << check_upload_file_loop >>
    FOR check_upload_file_rec IN check_upload_file_cur( in_file_id,
                                                        iv_format_pattern)
    LOOP
      lv_upload_file_name := check_upload_file_rec.file_name;
    END LOOP check_upload_file_loop;
    -- �ڋq�ꊇ�X�V�pCSV���擾���s���A�G���[
    IF (lv_upload_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    --�\���̏�����
    lr_cust_data_table.delete;
--
    --�t�@�C���A�b�v���[�hIF�e�[�u�����ABLOB�f�[�^��ϊ�����������\���̂��擾����
    xxccp_common_pkg2.blob_to_varchar2(in_file_id,
                                       lr_cust_data_table,
                                       lv_errbuf,
                                       lv_retcode,
                                       lv_errmsg);
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    <<cust_data_wk_loop>>
    FOR ln_index IN lr_cust_data_table.first..lr_cust_data_table.last LOOP
      --�G���[�`�F�b�N�ϐ�������
      lv_check_status := cv_status_normal;
      --�擾����������\���̂��G���[�`�F�b�N��A�}��
      lv_temp := lr_cust_data_table(ln_index);
--
      --����̂݃w�b�_�`�F�b�N
      IF (ln_first_data = 1) THEN
        ln_first_data := 0;
        --�ڋq�敪�擾
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
        --�擾����������\���̂̂P�s�P���ږڂ��u�ڋq�敪�v�ȊO�̏ꍇ�̓G���[�Ƃ���
        IF (lv_customer_class <> cv_cust_class) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_invalid_header_msg
                         );
          lv_errmsg := gv_out_msg;
          lv_errbuf := gv_out_msg;
          RAISE invalid_data_expt;
        END IF;
      END IF;
--
      --�w�b�_�f�[�^�ǂݔ�΂�
      IF (lv_customer_class = cv_cust_class) THEN
        ln_first_data := 0;
      ELSE
        --�ڋq�R�[�h�擾
        lv_customer_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,5);
        --�ڋq�R�[�h�̕K�{�`�F�b�N
        IF   (lv_customer_code IS NULL)
          OR (lv_customer_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq�R�[�h�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_code IS NOT NULL) THEN
          --�ڋq�R�[�h���݃`�F�b�N
          << check_cust_code_loop >>
          FOR check_cust_code_rec IN check_cust_code_cur( lv_customer_code )
          LOOP
            lv_cust_code_mst := check_cust_code_rec.cust_code;
            ln_cust_id       := check_cust_code_rec.cust_id;
            ln_party_id      := check_cust_code_rec.party_id;
          END LOOP check_cust_code_loop;
          IF (lv_cust_code_mst IS NULL) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq�R�[�h�}�X�^�[���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_cust_acct_table
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
        END IF;
--
        --�ڋq�ǉ���񑶍݃`�F�b�N
        IF (ln_cust_id IS NOT NULL) THEN
          --�ڋq�ǉ���񑶍݃`�F�b�N
          << check_cust_addon_loop >>
          FOR check_cust_addon_rec IN check_cust_addon_cur( ln_cust_id )
          LOOP
            ln_cust_addon_mst := check_cust_addon_rec.customer_id;
          END LOOP check_cust_addon_loop;
        END IF;
        IF (ln_cust_addon_mst IS NULL) THEN
          --�ڋq�ǉ����G���[
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq�R�[�h�}�X�^�[���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_cust_addon_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
        END IF;
--
        --�ڋq�敪�擾
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
        --�ڋq�敪���݃`�F�b�N
        << check_cust_class_loop >>
        FOR check_cust_class_rec IN check_cust_class_cur( lv_customer_class )
        LOOP
          lv_cust_class_mst := check_cust_class_rec.cust_class;
        END LOOP check_cust_class_loop;
        IF (lv_cust_class_mst IS NULL) THEN
          lv_check_status   := cv_status_error;
          lv_retcode        := cv_status_error;
          --�ڋq�敪�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_lookup_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_class
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_customer_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�ڋq�敪�̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_cust_class      --���ږ���
                                            ,lv_customer_class  --�ڋq�敪
                                            ,2                  --���ڒ�
                                            ,NULL               --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok         --�K�{�t���O
                                            ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf     --�G���[�o�b�t�@
                                            ,lv_item_retcode    --�G���[�R�[�h
                                            ,lv_item_errmsg);   --�G���[���b�Z�[�W
        --�ڋq�敪�����݂��A���^�E�����`�F�b�N�G���[��
        IF (lv_customer_class IS NOT NULL)
          AND (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
--�s�ID007 2007/02/24 add start
          lv_retcode      := cv_status_error;
--add end
          --�ڋq�敪�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_class
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_customer_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
--
        --�ڋq���̎擾
        lv_customer_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,6);
        --�ڋq���̂̕K�{�`�F�b�N
        IF (lv_customer_name = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq���̕K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_name IS NOT NULL) THEN
          --�ڋq���̂̌^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_cust_name      --���ږ���
                                              ,lv_customer_name  --�ڋq����
                                              ,100               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�ڋq���̂����݂��A���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq���̃G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_name
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_name
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg);
          END IF;
        END IF;
--
        --�ڋq���̃J�i�擾
        lv_cust_name_kana := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,7);
        --�ڋq���̃J�i�̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_cust_name_kana  --���ږ��̃J�i
                                            ,lv_cust_name_kana  --�ڋq���̃J�i
                                            ,50                 --���ڒ�
                                            ,NULL               --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok         --�K�{�t���O
                                            ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf     --�G���[�o�b�t�@
                                            ,lv_item_retcode    --�G���[�R�[�h
                                            ,lv_item_errmsg);   --�G���[���b�Z�[�W
        --�ڋq���̃J�i�����݂��A���^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq���̃J�i�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
        --�ڋq���̃J�i�̑S�p�J�^�J�i�`�F�b�N
        IF    (lv_cust_name_kana <> cv_null_bar)
          AND (xxccp_common_pkg.chk_double_byte_kana( lv_cust_name_kana ) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�S�p�J�^�J�i�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_double_byte_kana_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        --���̎擾
        lv_cust_name_ryaku := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,8);
--
        --���̂̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_ryaku            --���ږ��̃J�i
                                            ,lv_cust_name_ryaku  --�ڋq���̃J�i
                                            ,50                  --���ڒ�
                                            ,NULL                --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok          --�K�{�t���O
                                            ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf      --�G���[�o�b�t�@
                                            ,lv_item_retcode     --�G���[�R�[�h
                                            ,lv_item_errmsg);    --�G���[���b�Z�[�W
        --���̌^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���̃G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_ryaku
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_ryaku
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
--
        --�Ƒԁi�����ށj�擾
        lv_business_low_type := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,30);
        --�Ƒԁi�����ށj�̕K�{�`�F�b�N
        IF (lv_business_low_type = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�Ƒԁi�����ށj�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_bus_low_type
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�Ƒԁi�����ށj��-�łȂ��ꍇ
        IF (lv_business_low_type <> cv_null_bar) THEN
          --�Ƒԁi�����ށj���݃`�F�b�N
          << check_business_low_type_loop >>
          FOR check_business_low_rec IN check_business_low_cur( lv_business_low_type )
          LOOP
            lv_business_low_mst := check_business_low_rec.business_low_type;
          END LOOP check_business_low_type_loop;
          IF (lv_business_low_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�Ƒԁi�����ށj�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_bus_low_type
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_business_low_type
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�Ƒԁi�����ށj�`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_bus_low_type       --�Ƒԁi�����ށj
                                              ,lv_business_low_type  --�Ƒԁi�����ށj
                                              ,2                     --���ڒ�
                                              ,NULL                  --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok            --�K�{�t���O
                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf        --�G���[�o�b�t�@
                                              ,lv_item_retcode       --�G���[�R�[�h
                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
          --�Ƒԁi�����ށj�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Ƒԁi�����ށj�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_bus_low_type
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_business_low_type
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�ڋq�X�e�[�^�X�擾
        lv_customer_status := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,9);
        --�ڋq�X�e�[�^�X�̕K�{�`�F�b�N
        IF (lv_customer_status = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq�X�e�[�^�X�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_status
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
        END IF;
        --�ڋq�X�e�[�^�X��-�łȂ��ꍇ
        IF (lv_customer_status <> cv_null_bar) THEN
          --�ڋq�X�e�[�^�X���݃`�F�b�N
          << check_cust_status_loop >>
          FOR check_cust_status_rec IN check_cust_status_cur( lv_customer_status )
          LOOP
            lv_cust_status_mst := check_cust_status_rec.cust_status;
          END LOOP check_cust_status_loop;
          IF (lv_cust_status_mst IS NULL) THEN
            lv_check_status    := cv_status_error;
            lv_retcode         := cv_status_error;
            --�ڋq�X�e�[�^�X�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_status
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_status
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
          --�ڋq�X�e�[�^�X���Q�ƕ\�ɑ��݂���ꍇ�A�ύX�`�F�b�N
          IF (lv_cust_status_mst IS NOT NULL) THEN
            --���s�ڋq�X�e�[�^�X�擾
            << get_cust_status_loop >>
            FOR get_cust_status_rec IN get_cust_status_cur( ln_party_id )
            LOOP
              lv_get_cust_status := get_cust_status_rec.cust_status;
            END LOOP get_cust_status_loop;
            --�X�e�[�^�X���ύX�\���`�F�b�N
            IF (xxcmm_003common_pkg.cust_status_update_allow( lv_customer_class
                                                             ,lv_get_cust_status
                                                             ,lv_customer_status) <> cv_status_normal) THEN
                lv_check_status  := cv_status_error;
                lv_retcode       := cv_status_error;
                --�ύX�s�\�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_func_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_pre_status
                                ,iv_token_value2 => lv_get_cust_status
                                ,iv_token_name3  => cv_will_status
                                ,iv_token_value3 => lv_customer_status
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
            END IF;
            IF (lv_customer_status = cv_stop_approved) THEN
              --�ڋq�X�e�[�^�X�ύX�`�F�b�N
              xxcmm_cust_sts_chg_chk_pkg.main( ln_cust_id
                                              ,lv_customer_status
                                              ,lv_item_retcode
                                              ,lv_item_errmsg);
              IF (lv_item_retcode = cv_modify_err) THEN
--�s�ID007 2007/02/24 modify start
--                lv_cust_status_mst := cv_status_error;
                lv_check_status  := cv_status_error;
--modify end
                lv_retcode       := cv_status_error;
                --�ڋq�X�e�[�^�X�ύX�`�F�b�N�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_modify_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_input_val
                                ,iv_token_value2 => lv_customer_status
                                ,iv_token_name3  => cv_ret_code
                                ,iv_token_value3 => lv_item_retcode
                                ,iv_token_name4  => cv_ret_msg
                                ,iv_token_value4 => lv_item_errmsg
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
        END IF;
--
        --���~���R�擾
        lv_approval_reason := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,10);
        --���~���R��-�łȂ��ꍇ
        IF (lv_approval_reason <> cv_null_bar) THEN
          --���~���R���݃`�F�b�N
          << check_approval_reason_loop >>
          FOR check_approval_reason_rec IN check_approval_reason_cur( lv_approval_reason )
          LOOP
            lv_appr_reason_mst := check_approval_reason_rec.approval_reason;
          END LOOP check_approval_reason_loop;
          IF (lv_appr_reason_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���~���R�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���~���R�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_appr_reason        --���~���R
                                              ,lv_approval_reason    --���~���R
                                              ,1                     --���ڒ�
                                              ,NULL                  --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok            --�K�{�t���O
                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf        --�G���[�o�b�t�@
                                              ,lv_item_retcode       --�G���[�R�[�h
                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
          --���~���R�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���~���R�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���~���ϓ��擾
        lv_approval_date := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,11);
        --���~���ϓ���NULL�łȂ��ꍇ
        IF (lv_approval_date <> cv_null_bar) THEN
          --���~���ϓ��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_appr_date      --���~���ϓ�
                                              ,lv_approval_date  --���~���ϓ�
                                              ,NULL              --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_dat    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --���~���ϓ��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���~���ϓ��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_date
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_date
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���|�R�[�h�P�i�������j�擾
        lv_ar_invoice_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,14);
        --���|�R�[�h�P�i�������j��-�łȂ��ꍇ
        IF (lv_ar_invoice_code <> cv_null_bar) THEN
          --���|�R�[�h�P�i�������j���݃`�F�b�N
          << check_ar_invoice_code_loop >>
          FOR check_ar_invoice_code_rec IN check_ar_invoice_code_cur( lv_ar_invoice_code )
          LOOP
            lv_ar_invoice_code_mst := check_ar_invoice_code_rec.ar_invoice_code;
          END LOOP check_ar_invoice_code_loop;
          IF (lv_ar_invoice_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���|�R�[�h�P�i�������j���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���|�R�[�h�P�i�������j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_invoice       --���|�R�[�h�P�i�������j
                                              ,lv_ar_invoice_code  --���|�R�[�h�P�i�������j
                                              ,12                  --���ڒ�
                                              ,NULL                --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok          --�K�{�t���O
                                              ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf      --�G���[�o�b�t�@
                                              ,lv_item_retcode     --�G���[�R�[�h
                                              ,lv_item_errmsg);    --�G���[���b�Z�[�W
          --���|�R�[�h�P�i�������j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�P�i�������j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���|�R�[�h�Q�i���Ə��j�擾
        lv_ar_location_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,15);
        --���|�R�[�h�Q�i���Ə��j��-�łȂ��ꍇ
        IF (lv_ar_location_code <> cv_null_bar) THEN
          --���|�R�[�h�Q�i���Ə��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_location_code  --���|�R�[�h�Q�i���Ə��j
                                              ,lv_ar_location_code  --���|�R�[�h�Q�i���Ə��j
                                              ,12                   --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --���|�R�[�h�Q�i���Ə��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�Q�i���Ə��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_location_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_location_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���|�R�[�h�R�i���̑��j�擾
        lv_ar_others_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,16);
        --���|�R�[�h�R�i���̑��j��-�łȂ��ꍇ
        IF (lv_ar_others_code <> cv_null_bar) THEN
          --���|�R�[�h�R�i���̑��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_others_code  --���|�R�[�h�R�i���̑��j
                                              ,lv_ar_others_code  --���|�R�[�h�R�i���̑��j
                                              ,12                 --���ڒ�
                                              ,NULL               --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok         --�K�{�t���O
                                              ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf     --�G���[�o�b�t�@
                                              ,lv_item_retcode    --�G���[�R�[�h
                                              ,lv_item_errmsg);   --�G���[���b�Z�[�W
          --���|�R�[�h�R�i���̑��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�R�i���̑��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_others_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_others_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���������s�敪�擾
        lv_invoice_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,17);
        --���������s�敪�̕K�{�`�F�b�N
        IF (lv_invoice_class = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���������s�敪�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_kbn
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        IF (lv_invoice_class <> cv_null_bar) THEN
          --���������s�敪���݃`�F�b�N
          << check_invoice_class_loop >>
          FOR check_invoice_class_rec IN check_invoice_class_cur( lv_invoice_class )
          LOOP
            lv_invoice_class_mst := check_invoice_class_rec.invoice_class;
          END LOOP check_invoice_class_loop;
          IF (lv_invoice_class_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���������s�敪���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_kbn
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_class
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���������s�敪�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_invoice_kbn    --���������s�敪
                                              ,lv_invoice_class  --���������s�敪
                                              ,1                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --���������s�敪�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���������s�敪�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_kbn
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_class
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���������s�T�C�N���擾
        lv_invoice_cycle := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,18);
--
        --���������s�T�C�N����-�łȂ��ꍇ
        IF (lv_invoice_cycle <> cv_null_bar) THEN
          --���������s�T�C�N�����݃`�F�b�N
          << check_invoice_cycle_loop >>
          FOR check_invoice_cycle_rec IN check_invoice_cycle_cur( lv_invoice_cycle )
          LOOP
            lv_invoice_cycle_mst := check_invoice_cycle_rec.invoice_cycle;
          END LOOP check_invoice_cycle_loop;
          IF (lv_invoice_cycle_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���������s�T�C�N�����݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���������s�T�C�N���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_invoice_cycle  --���������s�T�C�N��
                                              ,lv_invoice_cycle  --���������s�T�C�N��
                                              ,1                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --���������s�T�C�N���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���������s�T�C�N���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�������o�͌`���擾
        lv_invoice_form  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,19);
        --�������o�͌`����-�łȂ��ꍇ
        IF (lv_invoice_form <> cv_null_bar) THEN
          --�������o�͌`�����݃`�F�b�N
          << check_invoice_form_loop >>
          FOR check_invoice_form_rec IN check_invoice_form_cur( lv_invoice_form )
          LOOP
            lv_invoice_form_mst := check_invoice_form_rec.invoice_form;
          END LOOP check_invoice_form_loop;
          IF (lv_invoice_form_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�������o�͌`�����݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�������o�͌`���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_invoice_ksk    --�������o�͌`��
                                              ,lv_invoice_form   --�������o�͌`��
                                              ,1                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�������o�͌`���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�������o�͌`���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�x�������擾
        lv_payment_term_id := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,20);
--
        --�x�������̕K�{�`�F�b�N
        IF (lv_payment_term_id = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�x�������K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_payment_term_id
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�x��������-�łȂ��ꍇ
        IF (lv_payment_term_id <> cv_null_bar) THEN
          --�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_id )
          LOOP
            lv_payment_term_id_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_term_id_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_id  --�x������
                                              ,lv_payment_term_id  --�x������
                                              ,8                   --���ڒ�
                                              ,NULL                --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok          --�K�{�t���O
                                              ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf      --�G���[�o�b�t�@
                                              ,lv_item_retcode     --�G���[�R�[�h
                                              ,lv_item_errmsg);    --�G���[���b�Z�[�W
          --�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --��2�x�������擾
        lv_payment_term_second := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,21);
        --��2�x��������-�łȂ��ꍇ
        IF (lv_payment_term_second <> cv_null_bar) THEN
          --��2�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_second )
          LOOP
            lv_payment_second_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_second_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --��2�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --��2�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_second  --��2�x������
                                              ,lv_payment_term_second  --��2�x������
                                              ,8                       --���ڒ�
                                              ,NULL                    --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok              --�K�{�t���O
                                              ,cv_element_vc2          --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf          --�G���[�o�b�t�@
                                              ,lv_item_retcode         --�G���[�R�[�h
                                              ,lv_item_errmsg);        --�G���[���b�Z�[�W
          --��2�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --��2�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --��3�x�������擾
        lv_payment_term_third  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,22);
        --��3�x��������-�łȂ��ꍇ
        IF (lv_payment_term_third <> cv_null_bar) THEN
          --��3�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_third )
          LOOP
            lv_payment_third_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_third_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --��3�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --��3�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_third  --��3�x������
                                              ,lv_payment_term_third  --��3�x������
                                              ,8                      --���ڒ�
                                              ,NULL                   --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok             --�K�{�t���O
                                              ,cv_element_vc2         --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf         --�G���[�o�b�t�@
                                              ,lv_item_retcode        --�G���[�R�[�h
                                              ,lv_item_errmsg);       --�G���[���b�Z�[�W
          --��3�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --��3�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�̔���j�擾
        lv_sales_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,23);
        --�`�F�[���X�R�[�h�i�̔���j�̕K�{�`�F�b�N
        IF (lv_sales_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�`�F�[���X�R�[�h�i�̔���j�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_sales_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�`�F�[���X�R�[�h�i�̔���j��-�łȂ��ꍇ
        IF (lv_sales_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�̔���j���݃`�F�b�N
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_sales_chain_code )
          LOOP
            lv_sales_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_sales_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�̔���j�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�̔���j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_sales_chain_code  --�`�F�[���X�R�[�h�i�̔���j
                                              ,lv_sales_chain_code  --�`�F�[���X�R�[�h�i�̔���j
                                              ,9                    --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�̔���j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�̔���j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�[�i��j�擾
        lv_delivery_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,25);
        --�`�F�[���X�R�[�h�i�[�i��j�̕K�{�`�F�b�N
        IF (lv_delivery_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�`�F�[���X�R�[�h�i�[�i��j�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�`�F�[���X�R�[�h�i�[�i��j��-�łȂ��ꍇ
        IF (lv_delivery_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�[�i��j���݃`�F�b�N
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_delivery_chain_code )
          LOOP
            lv_deliv_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_deliv_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�[�i��j�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�[�i��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_delivery_chain_code  --�`�F�[���X�R�[�h�i�[�i��j
                                              ,lv_delivery_chain_code  --�`�F�[���X�R�[�h�i�[�i��j
                                              ,9                       --���ڒ�
                                              ,NULL                    --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok              --�K�{�t���O
                                              ,cv_element_vc2          --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf          --�G���[�o�b�t�@
                                              ,lv_item_retcode         --�G���[�R�[�h
                                              ,lv_item_errmsg);        --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�[�i��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�[�i��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�����p�j�擾
        lv_policy_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,27);
        --�`�F�[���X�R�[�h�i�����p�j��-�łȂ��ꍇ
        IF (lv_policy_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�����p�j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_policy_chain_code  --�`�F�[���X�R�[�h�i�����p�j
                                              ,lv_policy_chain_code  --�`�F�[���X�R�[�h�i�����p�j
                                              ,30                    --���ڒ�
                                              ,NULL                  --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok            --�K�{�t���O
                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf        --�G���[�o�b�t�@
                                              ,lv_item_retcode       --�G���[�R�[�h
                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�����p�j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�����p�j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_policy_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_policy_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�d�c�h�j�擾
        lv_edi_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,28);
        --�`�F�[���X�R�[�h�i�d�c�h�j��-�łȂ��ꍇ
        IF (lv_edi_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�d�c�h�j���݃`�F�b�N
          << check_edi_chain_loop >>
          FOR check_edi_chain_rec IN check_edi_chain_cur( lv_edi_chain_code )
          LOOP
            lv_edi_chain_mst := check_edi_chain_rec.edi_chain_code;
          END LOOP check_edi_chain_loop;
          IF (lv_edi_chain_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�d�c�h�j���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_addon_cust_mst
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�d�c�h�j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_edi_chain       --�`�F�[���X�R�[�h�i�d�c�h�j
                                              ,lv_edi_chain_code  --�`�F�[���X�R�[�h�i�d�c�h�j
                                              ,4                  --���ڒ�
                                              ,NULL               --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok         --�K�{�t���O
                                              ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf     --�G���[�o�b�t�@
                                              ,lv_item_retcode    --�G���[�R�[�h
                                              ,lv_item_errmsg);   --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�d�c�h�j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�d�c�h�j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�X�܃R�[�h�擾
        lv_store_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
                                                                ,29);
        --�X�܃R�[�h��-�łȂ��ꍇ
        IF (lv_store_code <> cv_null_bar) THEN
          --�X�܃R�[�h�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_store_code     --�X�܃R�[�h
                                              ,lv_store_code     --�X�܃R�[�h
                                              ,10                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�X�܃R�[�h�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�X�܃R�[�h�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_store_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_store_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�X�֔ԍ��擾
        lv_postal_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                 ,cv_comma
                                                                 ,31);
        --�X�֔ԍ��̕K�{�`�F�b�N
        IF (lv_postal_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�X�֔ԍ��K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_postal_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�X�֔ԍ��擾��-�łȂ��ꍇ
        IF (lv_postal_code <> cv_null_bar) THEN
          --�X�֔ԍ��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_postal_code    --�X�֔ԍ�
                                              ,lv_postal_code    --�X�֔ԍ�
                                              ,7                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�X�֔ԍ��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�X�֔ԍ��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_postal_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_postal_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�s���{���擾
        lv_state := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                           ,cv_comma
                                                           ,32);
        --�s���{���̕K�{�`�F�b�N
        IF (lv_state = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�s���{���K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_state
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�s���{���擾��-�łȂ��ꍇ
        IF (lv_state <> cv_null_bar) THEN
          --�s���{���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_state          --�s���{��
                                              ,lv_state          --�s���{��
                                              ,30                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�s���{���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�s���{���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_state
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_state
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�s�E��擾
        lv_city := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                          ,cv_comma
                                                          ,33);
        --�s�E��̕K�{�`�F�b�N
        IF (lv_city = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�s�E��K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_city
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�s�E��擾��-�łȂ��ꍇ
        IF (lv_city <> cv_null_bar) THEN
          --�s�E��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_city           --�s�E��
                                              ,lv_city           --�s�E��
                                              ,30                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�s�E��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�s�E��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_city
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_city
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�Z��1�擾
        lv_address1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
                                                              ,34);
        --�Z��1�̕K�{�`�F�b�N
        IF (lv_address1 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�Z��1�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address1
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�Z��1�擾��-�łȂ��ꍇ
        IF (lv_address1 <> cv_null_bar) THEN
          --�Z��1�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address1       --�Z��1
                                              ,lv_address1       --�Z��1
                                              ,240               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�Z��1�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Z��1�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�Z��2�擾
        lv_address2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
                                                              ,35);
        --�Z��2�擾��-�łȂ��ꍇ
        IF (lv_address2 <> cv_null_bar) THEN
          --�Z��2�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address2       --�Z��2
                                              ,lv_address2       --�Z��2
                                              ,240               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�Z��2�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Z��2�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�n��R�[�h�擾
        lv_address3 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
                                                              ,36);
        --�n��R�[�h�̕K�{�`�F�b�N
        IF (lv_address3 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�n��R�[�h�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address3
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�n��R�[�h��-�łȂ��ꍇ
        IF (lv_address3 <> cv_null_bar) THEN
          --�n��R�[�h���݃`�F�b�N
          << check_cust_chiku_code_loop >>
          FOR check_cust_chiku_code_rec IN check_cust_chiku_code_cur( lv_address3 )
          LOOP
            lv_cust_chiku_code_mst := check_cust_chiku_code_rec.cust_chiku_code;
          END LOOP check_cust_chiku_code_loop;
          IF (lv_cust_chiku_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�n��R�[�h���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�n��R�[�h�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address3       --�n��R�[�h
                                              ,lv_address3       --�n��R�[�h
                                              ,5                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�n��R�[�h�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�n��R�[�h�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        IF (lv_customer_class = cv_trust_corp) THEN
          --�ڋq�@�l���}�X�^���݃`�F�b�N
          IF (ln_cust_id IS NOT NULL) THEN
            --�ڋq�@�l���}�X�^���݃`�F�b�N
            << check_cust_corp_loop >>
            FOR check_cust_corp_rec IN check_cust_corp_cur( ln_cust_id )
            LOOP
              ln_cust_corp_mst := check_cust_corp_rec.customer_id;
            END LOOP check_cust_corp_loop;
          END IF;
          IF (ln_cust_corp_mst IS NULL)THEN
              --�ڋq�@�l���}�X�^���G���[
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --�ڋq�@�l���}�X�^���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_corp_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
          END IF;
          --�^�M���x�z�擾�i�@�l�ڋq�̂݁j
          lv_credit_limit := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,12);
          --�^�M���x�z�̕K�{�`�F�b�N
          IF (lv_credit_limit = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�^�M���x�z�K�{�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_credit_limit
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          ELSE
            --�^�M���x�z�^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_credit_limit   --�^�M���x�z
                                                ,lv_credit_limit   --�^�M���x�z
                                                ,11                --���ڒ�
                                                ,0                 --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok        --�K�{�t���O
                                                ,cv_element_num    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf    --�G���[�o�b�t�@
                                                ,lv_item_retcode   --�G���[�R�[�h
                                                ,lv_item_errmsg);  --�G���[���b�Z�[�W
            --�^�M���x�z�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --�^�M���x�z�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_credit_limit
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_credit_limit
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --�^�E�������펞�̂ݐ��l�Ƃ��Ĉ����A�^�M���x�z���l�͈̓`�F�b�N
              ln_credit_limit := TO_NUMBER(lv_credit_limit);
              IF  ((ln_credit_limit < 0)
                OR (ln_credit_limit > 99999999999)) THEN
                --�^�M���x�z�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_trust_val_invalid
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_credit_limit
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_credit_limit
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
          --����敪�擾�i�@�l�ڋq�̂݁j
          lv_decide_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
                                                                  ,13);
          --����敪�̕K�{�`�F�b�N
          IF (lv_decide_div = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --����敪�K�{�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_decide
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --����敪��-�łȂ��ꍇ
          IF (lv_decide_div <> cv_null_bar) THEN
            --����敪���݃`�F�b�N
            << check_decide_div_loop >>
            FOR check_decide_div_rec IN check_decide_div_cur( lv_decide_div )
            LOOP
              lv_decide_div_mst := check_decide_div_rec.decide_div;
            END LOOP check_decide_div_loop;
            IF (lv_decide_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --����敪���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --����敪�^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_decide         --����敪
                                                ,lv_decide_div     --����敪
                                                ,1                 --���ڒ�
                                                ,NULL              --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok        --�K�{�t���O
                                                ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf    --�G���[�o�b�t�@
                                                ,lv_item_retcode   --�G���[�R�[�h
                                                ,lv_item_errmsg);  --�G���[���b�Z�[�W
            --����敪�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --����敪�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            END IF;
          END IF;
        END IF;
--
        IF (lv_check_status = cv_status_normal) THEN
          BEGIN
            INSERT INTO xxcmm_wk_cust_batch_regist(
               file_id
              ,customer_code
              ,customer_class_code
              ,customer_name
              ,customer_name_kana
              ,customer_name_ryaku
              ,customer_status
              ,approval_reason
              ,approval_date
              ,credit_limit
              ,decide_div
              ,ar_invoice_code
              ,ar_location_code
              ,ar_others_code
              ,invoice_class
              ,invoice_cycle
              ,invoice_form
              ,payment_term_id
              ,payment_term_second
              ,payment_term_third
              ,sales_chain_code
              ,delivery_chain_code
              ,policy_chain_code
              ,chain_store_code
              ,store_code
              ,business_low_type
              ,postal_code
              ,state
              ,city
              ,address1
              ,address2
              ,address3
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            )
            VALUES(
               in_file_id
              ,lv_customer_code
              ,lv_customer_class
              ,lv_customer_name
              ,lv_cust_name_kana
              ,lv_cust_name_ryaku
              ,lv_customer_status
              ,lv_approval_reason
              ,lv_approval_date
              ,ln_credit_limit
              ,lv_decide_div
              ,lv_ar_invoice_code
              ,lv_ar_location_code
              ,lv_ar_others_code
              ,lv_invoice_class
              ,lv_invoice_cycle
              ,lv_invoice_form
              ,lv_payment_term_id
              ,lv_payment_term_second
              ,lv_payment_term_third
              ,lv_sales_chain_code
              ,lv_delivery_chain_code
              ,lv_policy_chain_code
              ,lv_edi_chain_code
              ,lv_store_code
              ,lv_business_low_type
              ,lv_postal_code
              ,lv_state
              ,lv_city
              ,lv_address1
              ,lv_address2
              ,lv_address3
              ,fnd_global.user_id
              ,sysdate
              ,fnd_global.user_id
              ,sysdate
              ,fnd_profile.value(cv_conc_request_id)
              ,fnd_profile.value(cv_prog_appl_id)
              ,fnd_profile.value(cv_conc_program_id)
              ,sysdate
            );
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              lv_retcode := cv_status_error;
              RAISE invalid_data_expt;
          END;
        END IF;
        --�����J�E���g
        gn_target_cnt    := gn_target_cnt + 1;  -- �Ώی���
        IF (lv_check_status = cv_status_normal) THEN
          gn_normal_cnt  := gn_normal_cnt + 1;  -- ���팏��
        ELSE
          gn_error_cnt   := gn_error_cnt +1;    -- �G���[����
        END IF;
      END IF;
      --�e�i�[�p�ϐ�������
      lv_temp                  := NULL;
      lv_item_retcode          := NULL;
      lv_item_errmsg           := NULL;
      lv_customer_code         := NULL;
      lv_cust_code_mst         := NULL;
      ln_cust_id               := NULL;
      ln_party_id              := NULL;
      ln_cust_addon_mst        := NULL;
      lv_business_low_mst      := NULL;
      lv_get_cust_status       := NULL;
      lv_appr_reason_mst       := NULL;
      ln_cust_corp_mst         := NULL;
      lv_customer_class        := NULL;
      lv_cust_class_mst        := NULL;
      lv_cust_status_mst       := NULL;
      lr_cust_wk_table         := NULL;
      lv_ar_invoice_code_mst   := NULL;
      lv_invoice_class_mst     := NULL;
      lv_invoice_cycle_mst     := NULL;
      lv_invoice_form_mst      := NULL;
      lv_payment_term_id_mst   := NULL;
      lv_payment_second_mst    := NULL;
      lv_payment_third_mst     := NULL;
      lv_sales_chain_code_mst  := NULL;
      lv_deliv_chain_code_mst  := NULL;
      lv_edi_chain_mst         := NULL;
      lv_cust_chiku_code_mst   := NULL;
      lv_credit_limit          := NULL;
      ln_credit_limit          := NULL;
      lv_decide_div_mst        := NULL;
    END LOOP cust_data_wk_loop;
--
    --�f�[�^�G���[�����b�Z�[�W�ݒ�i�R���J�����g�o�́j
    IF (lv_retcode <> cv_status_normal) THEN
      --�f�[�^�G���[�����b�Z�[�W�擾
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_xxcmm_msg_kbn
                      ,iv_name         => cv_invalid_data_msg
                     );
      lv_errmsg := gv_out_msg;
      lv_errbuf := gv_out_msg;
      RAISE invalid_data_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    WHEN get_csv_err_expt THEN                         --*** �ڋq�ꊇ�X�V�pCSV�擾���s��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN invalid_data_expt THEN                        --*** �ڋq�ꊇ�X�V���s����O ***
      ov_errmsg  := lv_errmsg;
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
  END cust_data_make_wk;
--
  /**********************************************************************************
   * Procedure Name   : rock_and_update_cust
   * Description      : �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
   ***********************************************************************************/
  PROCEDURE rock_and_update_cust(
    in_file_id              IN  NUMBER,              --   �t�@�C��ID
    ov_errbuf               OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'rock_and_update_cust'; -- �v���O������
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
    cv_bill_to               CONSTANT VARCHAR2(7)     := 'BILL_TO';               --�g�p�ړI�E������
    cv_other_to              CONSTANT VARCHAR2(8)     := 'OTHER_TO';              --�g�p�ړI�E���̑�
    cv_aff_dept              CONSTANT VARCHAR2(15)    := 'XX03_DEPARTMENT';       --AFF����}�X�^�Q�ƃ^�C�v
    cv_chain_code            CONSTANT VARCHAR2(16)    := 'XXCMM_CHAIN_CODE';      --�Q�ƃR�[�h�F�`�F�[���X�Q�ƃ^�C�v
    cv_null_x                CONSTANT VARCHAR2(1)     := 'X';                     --NVL�p�_�~�[������
    cn_zero                  CONSTANT NUMBER(1)       := 0;                       --NVL�p�_�~�[���l
    cv_customer              CONSTANT VARCHAR2(2)     := '10';                    --�ڋq�敪�E�ڋq
    cv_su_customer           CONSTANT VARCHAR2(2)     := '12';                    --�ڋq�敪�E��l�ڋq
    cv_trust_corp            CONSTANT VARCHAR2(2)     := '13';                    --�ڋq�敪�E�@�l�Ǘ���
    cv_ar_manage             CONSTANT VARCHAR2(2)     := '14';                    --�ڋq�敪�E���|�Ǘ���ڋq
    cv_yes_output            CONSTANT VARCHAR2(1)     := 'Y';                     --�o�͗L���E�L
    cv_no_output             CONSTANT VARCHAR2(1)     := 'N';                     --�o�͗L���E��
    cv_corp_no_data          CONSTANT VARCHAR2(20)    := '�ڋq�@�l��񖢓o�^�B';  --�ڋq�@�l��񖢐ݒ�
    cv_addon_cust_no_data    CONSTANT VARCHAR2(20)    := '�ڋq�ǉ���񖢓o�^�B';  --�ڋq�ǉ���񖢐ݒ�
    cv_sales_base_class      CONSTANT VARCHAR2(1)     := '1';                     --�ڋq�敪�E���_
    cv_ignore                CONSTANT VARCHAR2(1)     := 'I';                     --�ڋq�}�X�^�E�X�e�[�^�X����
    cv_ng_word               CONSTANT VARCHAR2(7)     := 'NG_WORD';               --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_err_cust_code_msg     CONSTANT VARCHAR2(16)    := '�G���[�ڋq�R�[�h';      --CSV�o�̓G���[������
    cv_ng_data               CONSTANT VARCHAR2(7)     := 'NG_DATA';               --CSV�o�̓G���[�g�[�N���ENG_DATA
    cv_success_api           CONSTANT VARCHAR2(1)     := 'S';                     --API�������ԋp�X�e�[�^�X
    cv_init_list_api         CONSTANT VARCHAR2(1)     := 'T';                     --API�N���������X�g�ݒ�l
    cv_user_entered          CONSTANT VARCHAR2(12)    := 'USER_ENTERED';          --�p�[�e�B�}�X�^�X�V�`�o�h�R���e���c�\�[�X�^�C�v
--
    -- *** ���[�J���ϐ� ***
    lv_header_str                     VARCHAR2(2000)  := NULL;                    --�w�b�_���b�Z�[�W�i�[�p�ϐ�
    lv_output_str                     VARCHAR2(2047)  := NULL;                    --�o�͕�����i�[�p�ϐ�
    ln_output_cnt                     NUMBER          := 0;                       --�o�͌���
    lv_sales_kigyou_code              fnd_flex_values.attribute1%TYPE;            --��ƃR�[�h�i�̔���j�i�[�p�ϐ�
    lv_delivery_kigyou_code           fnd_flex_values.attribute1%TYPE;            --��ƃR�[�h�i�[�i��j�i�[�p�ϐ�
    lv_output_excute                  VARCHAR2(1)     := 'Y';                     --�o�͗L��
    ln_credit_limit                   xxcmm_mst_corporate.credit_limit%TYPE;      --�ڋq�@�l���.�^�M���x�z
    lv_decide_div                     xxcmm_mst_corporate.decide_div%TYPE;        --�ڋq�@�l���.����敪
    lv_information                    VARCHAR2(100)   := NULL;
    lv_sales_base_name                VARCHAR2(50)    := NULL;
--
    --�ڋq�X�V�`�o�h�p�ϐ�
    p_cust_account_rec                HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    ln_cust_object_version_number     NUMBER;
--
    --�p�[�e�B�X�V�`�o�h�p�ϐ�
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       HZ_PARTY_V2PUB.PARTY_REC_TYPE;
    p_organization_rec                HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
--
    --�ڋq�g�p�ړI�X�V�`�o�h�p�ϐ�
    p_cust_site_use_rec               HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    ln_csu_object_version_number      NUMBER;
    ln_payment_term_id                NUMBER;
    ln_payment_term_second_id         NUMBER;
    ln_payment_term_third_id          NUMBER;
--
    --�ڋq���Ə��X�V�`�o�h�p�ϐ�
    p_location_rec                    HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    ln_location_object_version_num    NUMBER;
--
    --�`�o�h�p�ėp�ϐ�
    lv_return_status                  VARCHAR2(1);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(2000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �ڋq�ꊇ�X�V���J�[�\��
    CURSOR cust_data_cur(
      in_file_id_wk IN NUMBER )
    IS
      SELECT  hca.cust_account_id         customer_id,                --�ڋqID
              hca.account_number          customer_number,            --�ڋq�ԍ�
              hca.object_version_number   cust_ovn,                   --�ڋq�I�u�W�F�N�g����ԍ�
              hca.party_id                party_id,                   --�p�[�e�BID
              hp.object_version_number    party_ovn,                  --�p�[�e�B�I�u�W�F�N�g����ԍ�
              hcsu.site_use_id            site_use_id,                --�ڋq�g�p�ړIID
              hcsu.bill_to_site_use_id    bill_to_site_use_id,        --�ڋq������g�p�ړIID
              hcsu.object_version_number  site_use_ovn,               --�ڋq�g�p�ړI�I�u�W�F�N�g����ԍ�
              hl.location_id              location_id,                --���P�[�V����ID
              hl.object_version_number    location_ovn,               --���P�[�V�����I�u�W�F�N�g����ԍ�
              xca.stop_approval_reason    addon_approval_reason,      --�ڋq�ǉ����E���~���R
              xca.stop_approval_date      addon_approval_date,        --�ڋq�ǉ����E���~���ϓ�
              xca.sales_chain_code        addon_sales_chain_code,     --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�̔���j
              xca.delivery_chain_code     addon_delivery_chain_code,  --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�[�i��j
              xca.policy_chain_code       addon_policy_chain_code,    --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�c�Ɛ����p�j
              xca.business_low_type       addon_business_low_type,    --�ڋq�ǉ����E�Ƒԁi�����ށj
              xca.chain_store_code        addon_chain_store_code,     --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�d�c�h�j
              xca.store_code              addon_store_code,           --�ڋq�ǉ����E���~���ϓ�
              xmc.credit_limit            addon_credit_limit,         --�ڋq�@�l���E�^�M���x�z
              xmc.decide_div              addon_decide_div,           --�ڋq�@�l���E����敪
              xwcbr.customer_name         customer_name,              --�ڋq����
              xwcbr.customer_name_kana    customer_name_kana,         --�ڋq���̃J�i
              xwcbr.customer_name_ryaku   customer_name_ryaku,        --����
              xwcbr.customer_status       customer_status,            --�ڋq�X�e�[�^�X
              xwcbr.ar_invoice_code       ar_invoice_code,            --���|�R�[�h�P�i�������j
              xwcbr.ar_location_code      ar_location_code,           --���|�R�[�h�Q�i���Ə��j
              xwcbr.ar_others_code        ar_others_code,             --���|�R�[�h�R�i���̑��j
              xwcbr.invoice_class         invoice_class,              --���������s�敪
              xwcbr.invoice_cycle         invoice_cycle,              --���������s�T�C�N��
              xwcbr.invoice_form          invoice_form,               --�������o�͌`��
              xwcbr.payment_term_id       payment_term_id,            --�x������
              xwcbr.payment_term_second   payment_term_second,        --��2�x������
              xwcbr.payment_term_third    payment_term_third,         --��3�x������
              xwcbr.postal_code           postal_code,                --�X�֔ԍ�
              xwcbr.state                 state,                      --�s���{��
              xwcbr.city                  city,                       --�s�E��
              xwcbr.address1              address1,                   --�Z��1
              xwcbr.address2              address2,                   --�Z��2
              xwcbr.address3              address3,                   --�n��R�[�h
              xwcbr.approval_reason       approval_reason,            --���~���R
              xwcbr.approval_date         approval_date,              --���~���ϓ�
              xwcbr.sales_chain_code      sales_chain_code,           --�`�F�[���X�R�[�h�i�̔���j
              xwcbr.delivery_chain_code   delivery_chain_code,        --�`�F�[���X�R�[�h�i�[�i��j
              xwcbr.policy_chain_code     policy_chain_code,          --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
              xwcbr.chain_store_code      chain_store_code,           --�`�F�[���X�R�[�h�i�d�c�h�j
              xwcbr.store_code            store_code,                 --�X�܃R�[�h
              xwcbr.business_low_type     business_low_type,          --�Ƒԁi�����ށj
              xwcbr.credit_limit          credit_limit,               --�^�M���x�z
              xwcbr.decide_div            decide_div,                 --����敪
              xwcbr.customer_class_code   customer_class_code         --�ڋq�敪
      FROM    hz_cust_accounts     hca,
              hz_cust_acct_sites   hcas,
              hz_cust_site_uses    hcsu,
              hz_parties           hp,
              hz_party_sites       hps,
              hz_locations         hl,
              xxcmm_cust_accounts  xca,
              xxcmm_mst_corporate  xmc,
              xxcmm_wk_cust_batch_regist xwcbr
      WHERE   hca.cust_account_id       = hcas.cust_account_id
      AND     hcas.cust_acct_site_id    = hcsu.cust_acct_site_id
      AND     ((hcsu.site_use_code      = cv_bill_to
              AND hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage))
      OR      (hcsu.site_use_code       = cv_other_to
              AND hca.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)))
      AND     hca.party_id              = hp.party_id
      AND     hp.party_id               = hps.party_id
      AND     hps.location_id           = hl.location_id
      AND     xca.customer_id           = hca.cust_account_id
      AND     xmc.customer_id (+)       = hca.cust_account_id
      AND     hcas.org_id = gv_org_id
      AND     hcsu.org_id = gv_org_id
      AND     hcas.party_site_id        = hps.party_site_id
      AND     hps.location_id           = (SELECT MIN(hpsiv.location_id)
                                           FROM   hz_cust_acct_sites hcasiv,
                                                  hz_party_sites     hpsiv
                                           WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                           AND    hcasiv.party_site_id   = hpsiv.party_site_id)
      AND     hca.account_number        = xwcbr.customer_code
      AND     xwcbr.file_id             = in_file_id_wk
      FOR UPDATE NOWAIT
      ;
    -- �x�������擾�J�[�\��
    CURSOR get_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.term_id  payment_term_id
      FROM   ra_terms    rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- �x�������`�F�b�N�J�[�\�����R�[�h�^
    get_payment_term_rec  get_payment_term_cur%ROWTYPE;
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
    --�ڋq�ꊇ�X�V���J�[�\���I�[�v��
    << cust_data_loop >>
    FOR cust_data_rec IN cust_data_cur( in_file_id )
    LOOP
      -- ===============================
      -- �ڋq�}�X�^�X�V
      -- ===============================
      --�ڋq�}�X�^�X�V�l�ݒ�
      p_cust_account_rec.cust_account_id  := cust_data_rec.customer_id;
      IF (cust_data_rec.customer_name_ryaku = cv_null_bar) THEN
        p_cust_account_rec.account_name   := CHR(0);                             --����(NULL)
      ELSE
        p_cust_account_rec.account_name   := cust_data_rec.customer_name_ryaku;  --����
      END IF;
      --�ڋq�X�e�[�^�X���u���~���ٍρv�̂Ƃ��A�ڋq�}�X�^�̗L���t���O�𖳌��ɂ���
      IF (cust_data_rec.customer_status = cv_stop_approved) THEN
        p_cust_account_rec.status         := cv_ignore;                          --�ڋq�X�e�[�^�X����
      END IF;
      ln_cust_object_version_number       := cust_data_rec.cust_ovn;
      --�ڋq�}�X�^�X�VAPI�Ăяo��
      hz_cust_account_v2pub.update_cust_account(
                                          cv_init_list_api,
                                          p_cust_account_rec,
                                          ln_cust_object_version_number,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --�ڋq�}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_cust_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_cust_err_expt;
      END IF;
      --�ϐ�������
      p_cust_account_rec.account_name  := NULL;
      p_cust_account_rec.status        := NULL;
      ln_cust_object_version_number    := NULL;
--
      -- ===============================
      -- �p�[�e�B�}�X�^�X�V
      -- ===============================
      --�p�[�e�B�}�X�^�X�V�l�ݒ�
      ln_party_id            := cust_data_rec.party_id;
      lv_content_source_type := cv_user_entered;
      ln_party_object_version_number := cust_data_rec.party_ovn;
      --�g�D���擾API
      hz_party_v2pub.get_organization_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         lv_content_source_type,
                                         p_organization_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B���擾API
      hz_party_v2pub.get_party_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         p_party_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B���X�V�l�ݒ�
      p_organization_rec.organization_name            := cust_data_rec.customer_name;       --�ڋq����
      IF (cust_data_rec.customer_name_kana = cv_null_bar) THEN
        p_organization_rec.organization_name_phonetic := CHR(0);                            --�ڋq���̃J�i(NULL)
      ELSE
        p_organization_rec.organization_name_phonetic := cust_data_rec.customer_name_kana;  --�ڋq���̃J�i
      END IF;
      p_organization_rec.duns_number_c                := cust_data_rec.customer_status;     --�ڋq�X�e�[�^�X
      p_organization_rec.party_rec                    := p_party_rec;
      --�p�[�e�B�}�X�^�X�VAPI�Ăяo��
      hz_party_v2pub.update_organization(
                                         cv_init_list_api,
                                         p_organization_rec,
                                         ln_party_object_version_number,
                                         ln_profile_id,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B�}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_party_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_party_err_expt;
      END IF;
      --�ϐ�������
      p_organization_rec.organization_name           := NULL;
      p_organization_rec.organization_name_phonetic  := NULL;
      p_organization_rec.duns_number_c               := NULL;
      p_organization_rec.party_rec                   := NULL;
      ln_party_object_version_number                 := NULL;
--
      -- ===============================
      -- �ڋq�g�p�ړI�X�V
      -- ===============================
      --�ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�A'14'(���|�Ǘ���ڋq)�̂Ƃ��̂݁A�ڋq�g�p�ړI�X�V
      IF (cust_data_rec.customer_class_code   = cv_customer)
        OR (cust_data_rec.customer_class_code = cv_su_customer)
        OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
        --�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_id )
        LOOP
          ln_payment_term_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --��2�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_second )
        LOOP
          ln_payment_term_second_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --��3�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_third )
        LOOP
          ln_payment_term_third_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --�ڋq�g�p�ړI�X�V�l�ݒ�
        p_cust_site_use_rec.site_use_id          := cust_data_rec.site_use_id;
        p_cust_site_use_rec.bill_to_site_use_id  := cust_data_rec.bill_to_site_use_id;
        IF (cust_data_rec.ar_invoice_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute4 := CHR(0);                          --���|�R�[�h�P�i�������j(NULL)
        ELSE
          p_cust_site_use_rec.attribute4 := cust_data_rec.ar_invoice_code;   --���|�R�[�h�P�i�������j
        END IF;
        IF (cust_data_rec.ar_location_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute5 := CHR(0);                          --���|�R�[�h�Q�i���Ə��j(NULL)
        ELSE
          p_cust_site_use_rec.attribute5 := cust_data_rec.ar_location_code;  --���|�R�[�h�Q�i���Ə��j
        END IF;
        IF (cust_data_rec.ar_others_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute6 := CHR(0);                          --���|�R�[�h�R�i���̑��j(NULL)
        ELSE
          p_cust_site_use_rec.attribute6 := cust_data_rec.ar_others_code;    --���|�R�[�h�R�i���̑��j
        END IF;
        p_cust_site_use_rec.attribute1   := cust_data_rec.invoice_class;     --���������s�敪
        IF (cust_data_rec.invoice_cycle = cv_null_bar) THEN
          p_cust_site_use_rec.attribute8 := CHR(0);                          --���������s�T�C�N��(NULL)
        ELSE
          p_cust_site_use_rec.attribute8 := cust_data_rec.invoice_cycle;     --���������s�T�C�N��
        END IF;
        IF (cust_data_rec.invoice_form = cv_null_bar) THEN
          p_cust_site_use_rec.attribute7 := CHR(0);                          --�������o�͌`��(NULL)
        ELSE
          p_cust_site_use_rec.attribute7 := cust_data_rec.invoice_form;      --�������o�͌`��
        END IF;
        p_cust_site_use_rec.payment_term_id := ln_payment_term_id;           --�x������
        IF (cust_data_rec.payment_term_second = cv_null_bar) THEN
          p_cust_site_use_rec.attribute2 := CHR(0);                          --��2�x������(NULL)
        ELSE
          p_cust_site_use_rec.attribute2 := ln_payment_term_second_id;       --��2�x������
        END IF;
        IF (cust_data_rec.payment_term_third = cv_null_bar) THEN
          p_cust_site_use_rec.attribute3 := CHR(0);                          --��3�x������(NULL)
        ELSE
          p_cust_site_use_rec.attribute3 := ln_payment_term_third_id;        --��3�x������
        END IF;
        ln_csu_object_version_number     := cust_data_rec.site_use_ovn;      --�ڋq�g�p�ړI�I�u�W�F�N�g����ԍ�
        --�ڋq�g�p�ړI�}�X�^�X�VAPI�Ăяo��
        hz_cust_account_site_v2pub.update_cust_site_use(
                                            cv_init_list_api,
                                            p_cust_site_use_rec,
                                            ln_csu_object_version_number,
                                            lv_return_status,
                                            ln_msg_count,
                                            lv_msg_data);
        --�ڋq�g�p�ړI�}�X�^�X�V�G���[���ARAISE
        IF lv_return_status <> cv_success_api THEN
          gv_out_msg  := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcmm_msg_kbn
                           ,iv_name         => cv_update_csu_err_msg
                           ,iv_token_name1  => cv_cust_code
                           ,iv_token_value1 => cust_data_rec.customer_number
                          );
          lv_errmsg := gv_out_msg;
          lv_errbuf := lv_msg_data;
          RAISE update_csu_err_expt;
        END IF;
        --�ϐ�������
        p_cust_site_use_rec.site_use_id          := NULL;
        p_cust_site_use_rec.bill_to_site_use_id  := NULL;
        p_cust_site_use_rec.attribute4           := NULL;
        p_cust_site_use_rec.attribute5           := NULL;
        p_cust_site_use_rec.attribute6           := NULL;
        p_cust_site_use_rec.attribute1           := NULL;
        p_cust_site_use_rec.attribute8           := NULL;
        p_cust_site_use_rec.attribute7           := NULL;
        p_cust_site_use_rec.payment_term_id      := NULL;
        p_cust_site_use_rec.attribute2           := NULL;
        p_cust_site_use_rec.attribute3           := NULL;
        ln_csu_object_version_number             := NULL;
        ln_payment_term_id                       := NULL;
        ln_payment_term_second_id                := NULL;
        ln_payment_term_third_id                 := NULL;
      END IF;
--
      -- ===============================
      -- �ڋq���Ə��X�V
      -- ===============================
      p_location_rec.location_id        := cust_data_rec.location_id;
      p_location_rec.postal_code        := cust_data_rec.postal_code;   --�X�֔ԍ�
      p_location_rec.state              := cust_data_rec.state;         --�s���{��
      p_location_rec.city               := cust_data_rec.city;          --�s�E��
      p_location_rec.address1           := cust_data_rec.address1;      --�Z��1
      IF (cust_data_rec.address2 = cv_null_bar) THEN
        p_location_rec.address2         := CHR(0);                      --�Z��2(NULL)
      ELSE
        p_location_rec.address2         := cust_data_rec.address2;      --�Z��2
      END IF;
      p_location_rec.address3           := cust_data_rec.address3;      --�n��R�[�h
      ln_location_object_version_num    := cust_data_rec.location_ovn;
      --�ڋq���Ə��}�X�^�X�VAPI�Ăяo��
      hz_location_v2pub.update_location(
                                          cv_init_list_api,
                                          p_location_rec,
                                          ln_location_object_version_num,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --�ڋq���Ə��}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_location_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_location_err_expt;
      END IF;
      --�ϐ�������
      p_location_rec.location_id        := NULL;
      p_location_rec.postal_code        := NULL;
      p_location_rec.state              := NULL;
      p_location_rec.city               := NULL;
      p_location_rec.address1           := NULL;
      p_location_rec.address2           := NULL;
      p_location_rec.address3           := NULL;
      ln_location_object_version_num    := NULL;
--
    -- ===============================
    -- �ڋq�ǉ����X�V
    -- ===============================
    --�ڋq�敪��'10'(�ڋq)�A'14'(���|�Ǘ���ڋq)�̂Ƃ��̂݁A�`�F�[���X�R�[�h�i�̔���j�E�`�F�[���X�R�[�h�i�[�i��j�E
    --�`�F�[���X�R�[�h�i�c�Ɛ����p�j�E�`�F�[���X�R�[�h�i�d�c�h�j�E�X�܃R�[�h���X�V
    IF   (cust_data_rec.customer_class_code = cv_customer)
      OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
      UPDATE xxcmm_cust_accounts xca
      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --���~���R
                                                 NULL,
                                                 cust_data_rec.addon_approval_reason,
                                                 cv_null_bar,
                                                 NULL,
                                                 cust_data_rec.approval_reason),
             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --���~���ϓ�
                                                 NULL,
                                                 cust_data_rec.addon_approval_date,
                                                 cv_null_bar,
                                                 NULL,
                                                 TO_DATE(cust_data_rec.approval_date,
                                                         cv_date_format)),
             xca.sales_chain_code       = DECODE(cust_data_rec.sales_chain_code,           --�`�F�[���X�R�[�h�i�̔���j
                                                 NULL,
                                                 cust_data_rec.addon_sales_chain_code,
                                                 cust_data_rec.sales_chain_code),
             xca.delivery_chain_code    = DECODE(cust_data_rec.delivery_chain_code,        --�`�F�[���X�R�[�h�i�[�i��j
                                                 NULL,
                                                 cust_data_rec.addon_delivery_chain_code,
                                                 cust_data_rec.delivery_chain_code),
             xca.policy_chain_code      = DECODE(cust_data_rec.policy_chain_code,          --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
                                                 NULL,
                                                 cust_data_rec.addon_policy_chain_code,
                                                 cv_null_bar,
                                                 NULL,
                                                 cust_data_rec.policy_chain_code),
             xca.chain_store_code       = DECODE(cust_data_rec.chain_store_code,           --�`�F�[���X�R�[�h�i�d�c�h�j
                                                 NULL,
                                                 cust_data_rec.addon_chain_store_code,
                                                 cv_null_bar,
                                                 NULL,
                                                 cust_data_rec.chain_store_code),
             xca.store_code             = DECODE(cust_data_rec.store_code,                 --�X�܃R�[�h
                                                 NULL,
                                                 cust_data_rec.addon_store_code,
                                                 cv_null_bar,
                                                 NULL,
                                                 cust_data_rec.store_code),
             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --�Ƒԁi�����ށj
                                                 NULL,
                                                 cust_data_rec.addon_business_low_type,
                                                 cust_data_rec.business_low_type),
             xca.last_updated_by        = fnd_global.user_id,                              --�ŏI�X�V��
             xca.last_update_date       = sysdate,                                         --�ŏI�X�V��
             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --�v��ID
             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --�R���J�����g�E�v���O������A�v���P�[�V����ID
             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --�R���J�����g�E�v���O����ID
             xca.program_update_date    = sysdate                                          --�v���O�����X�V��
      WHERE  xca.customer_id = cust_data_rec.customer_id
      ;
    --����ȊO�̏ꍇ�A�`�F�[���X�R�[�h�i�̔���j�E�`�F�[���X�R�[�h�i�[�i��j�E�`�F�[���X�R�[�h�i�c�Ɛ����p�j�E
    --�`�F�[���X�R�[�h�i�d�c�h�j�E�X�܃R�[�h�͍X�V���Ȃ�
    ELSE
      UPDATE xxcmm_cust_accounts xca
      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --���~���R
                                                 NULL,
                                                 cust_data_rec.addon_approval_reason,
                                                 cv_null_bar,
                                                 NULL,
                                                 cust_data_rec.approval_reason),
             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --���~���ϓ�
                                                 NULL,
                                                 cust_data_rec.addon_approval_date,
                                                 cv_null_bar,
                                                 NULL,
                                                 TO_DATE(cust_data_rec.approval_date,
                                                         cv_date_format)),
             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --�Ƒԁi�����ށj
                                                 NULL,
                                                 cust_data_rec.addon_business_low_type,
                                                 cust_data_rec.business_low_type),
             xca.last_updated_by        = fnd_global.user_id,                              --�ŏI�X�V��
             xca.last_update_date       = sysdate,                                         --�ŏI�X�V��
             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --�v��ID
             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --�R���J�����g�E�v���O������A�v���P�[�V����ID
             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --�R���J�����g�E�v���O����ID
             xca.program_update_date    = sysdate                                          --�v���O�����X�V��
      WHERE  xca.customer_id = cust_data_rec.customer_id
      ;
    END IF;
--
    -- ===============================
    -- �ڋq�@�l���X�V
    -- ===============================
    --�ڋq�敪��'13'�i�@�l�ڋq�i�^�M�Ǘ���j�j�̂Ƃ��̂݁A�ڋq�@�l���X�V
    IF (cust_data_rec.customer_class_code = cv_trust_corp) THEN
      UPDATE xxcmm_mst_corporate xmc
      SET    xmc.credit_limit           = DECODE(cust_data_rec.credit_limit,        --�^�M���x�z
                                                 NULL,
                                                 cust_data_rec.addon_credit_limit,
                                                 cust_data_rec.credit_limit),
             xmc.decide_div             = DECODE(cust_data_rec.decide_div,          --����敪
                                                 NULL,
                                                 cust_data_rec.addon_decide_div,
                                                 cust_data_rec.decide_div),
             xmc.last_updated_by        = fnd_global.user_id,                       --�ŏI�X�V��
             xmc.last_update_date       = sysdate,                                  --�ŏI�X�V��
             xmc.request_id             = fnd_profile.value(cv_conc_request_id),    --�v��ID
             xmc.program_application_id = fnd_profile.value(cv_prog_appl_id),       --�R���J�����g�E�v���O������A�v���P�[�V����ID
             xmc.program_id             = fnd_profile.value(cv_conc_program_id),    --�R���J�����g�E�v���O����ID
             xmc.program_update_date    = sysdate                                   --�v���O�����X�V��
      WHERE  xmc.customer_id  = cust_data_rec.customer_id
      ;
    END IF;
--
  END LOOP cust_data_loop;
--
  EXCEPTION
    WHEN cust_rock_err_expt THEN                       --*** ���b�N�擾���s��O ***
      --���b�N�G���[�����b�Z�[�W�擾
      gv_out_msg    := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_rock_err_msg
                        );
      lv_errmsg     := gv_out_msg;
      lv_errbuf     := gv_out_msg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --���b�N�擾���s��O���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_cust_err_expt THEN                       --*** �ڋq�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_party_err_expt THEN                      --*** �p�[�e�B�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�p�[�e�B�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_csu_err_expt THEN                        --*** �ڋq�g�p�ړI�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq�g�p�ړI�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_location_err_expt THEN                   --*** �ڋq���Ə��}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq���Ə��}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
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
  END rock_and_update_cust;
--
  /**********************************************************************************
   * Procedure Name   : close_process
   * Description      : �I������(A-5)
   ***********************************************************************************/
  PROCEDURE close_process(
    in_file_id      IN  NUMBER,              --   �t�@�C��ID
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_process'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    DELETE xxcmm_wk_cust_batch_regist;
    DELETE xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id                IN  NUMBER,       --�t�@�C��ID
    iv_format_pattern         IN  VARCHAR2,     --�t�@�C���t�H�[�}�b�g
    ov_errbuf                 OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_real_errbuf   VARCHAR2(5000);  --A-3�EA-4���̃G���[�E���b�Z�[�W
    lv_real_retcode  VARCHAR2(1);     --A-3�EA-4���̃��^�[���E�R�[�h
    lv_real_errmsg   VARCHAR2(5000);  --A-3�EA-4���̃��[�U�[�E�G���[�E���b�Z�[�W
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
    --�p�����[�^�o��
    --�t�@�C��ID
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_id
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => TO_CHAR(in_file_id)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�t�@�C���^�C�v
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_content_type
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_format_pattern
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
    -- ===============================
    cust_data_make_wk(
       in_file_id            -- �t�@�C��ID
      ,iv_format_pattern     -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���擾�����G���[���A
    --���͌ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^�����G���[���͏������X�L�b�v
    IF (lv_retcode = cv_status_error) THEN
      NULL;
    ELSE
      -- ===============================
      -- �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
      -- ===============================
      rock_and_update_cust(
         in_file_id              -- �t�@�C��ID
        ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --�e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)�G���[���A���[���o�b�N
      IF (lv_retcode = cv_status_error) THEN
        --ROLLBACK
        ROLLBACK;
      END IF;
    END IF;
--
    lv_real_errbuf  := lv_errbuf;
    lv_real_retcode := lv_retcode;
    lv_real_errmsg  := lv_errmsg;
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    --�X�e�[�^�X�Ɋւ�炸�A�A�b�v���[�h�e�[�u���ƃ��[�N�e�[�u���͍폜����
    close_process(
       in_file_id              -- �t�@�C��ID
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���擾�����G���[���A
    --���͌ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^�����G���[���A��������
    --�e�[�u�����b�N�����G���[���A
    --�ڋq�ꊇ�X�V�����G���[���ARAISE
    IF (lv_real_retcode = cv_status_error) THEN
      --�G���[����
      lv_errmsg := lv_real_errmsg;
      lv_errbuf := lv_real_errbuf;
      RAISE global_process_expt;
    END IF;
--
    --�I�����������G���[��
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
    errbuf                    OUT    VARCHAR2,  --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,  --�G���[�R�[�h     #�Œ�#
    iv_file_id                IN     VARCHAR2,  --�t�@�C��ID
    iv_format_pattern         IN     VARCHAR2   --�t�@�C���t�H�[�}�b�g
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
       TO_NUMBER(iv_file_id)     --�t�@�C��ID
      ,iv_format_pattern         --�t�@�C���t�H�[�}�b�g
      ,lv_errbuf                 --�G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                --���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCMM003A29C;
/
