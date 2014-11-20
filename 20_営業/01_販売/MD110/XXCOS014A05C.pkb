CREATE OR REPLACE PACKAGE BODY XXCOS014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A05C (body)
 * Description      : ���[���s���(�A�h�I��)�Ŏw�肵������������EDI�o�R�Ŏ�荞�񂾍݌ɏ����A
 *                    ���[�T�[�o�����Ƀt�@�C�����o�͂��܂��B
 * MD.050           : �݌ɏ��f�[�^�쐬 MD050_COS_014_A05
 * Version          : 1.7
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
 *  2009/01/06    1.0   M.Takano         �V�K�쐬
 *  2009/02/12    1.1   T.Nakamura       [��QCOS_061] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/13    1.2   T.Nakamura       [��QCOS_065] ���O�o�̓v���V�[�W��out_line�̖�����
 *  2009/02/16    1.3   T.Nakamura       [��QCOS_079] �v���t�@�C���ǉ��A�[�i���_���擾�������C
 *  2009/02/17    1.4   T.Nakamura       [��QCOS_094] CSV�o�͍��ڂ̏C��
 *  2009/02/19    1.5   T.Nakamura       [��QCOS_109] ���O�o�͂ɃG���[���b�Z�[�W���o�͓�
 *  2009/02/20    1.6   T.Nakamura       [��QCOS_110] �t�b�^���R�[�h�쐬�������s���̃G���[�n���h�����O��ǉ�
 *  2009/04/02    1.7   T.Kitajima       [T1_0114] �[�i���_���擾���@�ύX
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A05C'; -- �p�b�P�[�W��
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --�A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:�f�[�^���R�[�h���ʎq
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_INV';         --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(EBS�݌ɊǗ�)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:��Ж�
  ct_prf_company_name_kana        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME_KANA';            --XXCOS:��Ж��J�i
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX�s�T�C�Y
  ct_prf_organization_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';            --XXCOI:�݌ɑg�D�R�[�h
  ct_prf_case_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CASE_UOM_CODE';                --XXCOS:�P�[�X�P�ʃR�[�h
  ct_prf_bowl_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BALL_UOM_CODE';                --XXCOS:�{�[���P�ʃR�[�h
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  --
  --���b�Z�[�W
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:�w�b�_���R�[�h���ʎq
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:�f�[�^���R�[�h���ʎq
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:�t�b�^���R�[�h���ʎq
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00112';                    --XXCOS:���[OUTBOUND�o�̓f�B���N�g��
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:��Ж�
  ct_msg_company_name_kana        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00098';                    --XXCOS:��Ж��J�i
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX�s�T�C�Y
  ct_msg_organization_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00048';                    --XXCOI:�݌ɑg�D�R�[�h
  ct_msg_case_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00057';                    --XXCOS:�P�[�X�P�ʃR�[�h
  ct_msg_bowl_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00059';                    --XXCOS:�{�[���P�ʃR�[�h

  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --�v���t�@�C���擾�G���[
  ct_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00063';                    --���b�Z�[�W�p������.�݌ɑg�DID
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --���b�Z�[�W�p������.�ڋq�}�X�^
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --���b�Z�[�W�p������.�i�ڃ}�X�^
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --�擾�G���[
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --�}�X�^���o�^
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13101';                    --�p�����[�^�o�̓��b�Z�[�W1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13102';                    --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --�t�@�C���I�[�v���G���[���b�Z�[�W
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --���b�Z�[�W�p������.�ʏ��
  ct_msg_line_type                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --���b�Z�[�W�p������.�ʏ�o��
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --�Ώۃf�[�^�Ȃ����b�Z�[�W

  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --�t�@�C�����o�̓��b�Z�[�W
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --���b�Z�[�W�p������.�`�[�ԍ�
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --���b�Z�[�W�p������.MO:�c�ƒP��
-- 2009/02/16 T.Nakamura Ver.1.3 add end
--
  --�g�[�N��
  cv_tkn_data                     CONSTANT VARCHAR2(4)   := 'DATA';                               --�f�[�^
  cv_tkn_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                              --�e�[�u��
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';                             --���̓p�����[�^1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';                             --���̓p�����[�^2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6)   := 'PARAM3';                             --���̓p�����[�^3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6)   := 'PARAM4';                             --���̓p�����[�^4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6)   := 'PARAM5';                             --���̓p�����[�^5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6)   := 'PARAM6';                             --���̓p�����[�^6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6)   := 'PARAM7';                             --���̓p�����[�^7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6)   := 'PARAM8';                             --���̓p�����[�^8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6)   := 'PARAM9';                             --���̓p�����[�^9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7)   := 'PARAM10';                            --���̓p�����[�^10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7)   := 'PARAM11';                            --���̓p�����[�^11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7)   := 'PARAM12';                            --���̓p�����[�^12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7)   := 'PARAM13';                            --���̓p�����[�^13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7)   := 'PARAM14';                            --���̓p�����[�^14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7)   := 'PARAM15';                            --���̓p�����[�^15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7)   := 'PARAM16';                            --���̓p�����[�^16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7)   := 'PARAM17';                            --���̓p�����[�^17
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                          --�t�@�C����
  cv_tkn_prf                      CONSTANT VARCHAR2(7)   := 'PROFILE';                            --�v���t�@�C��
  cv_tkn_order_no                 CONSTANT VARCHAR2(8)   := 'ORDER_NO';                           --�`�[�ԍ�
  cv_tkn_key                      CONSTANT VARCHAR2(8)   := 'KEY_DATA';                           --�L�[���
--
  --���̑�
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                  --UTL_FILE.�I�[�v�����[�h
  cv_date_fmt                     CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                            --���t����
  cv_time_fmt                     CONSTANT VARCHAR2(8)  := 'HH24MISS';                            --��������
  cv_cust_class_base              CONSTANT VARCHAR2(1)  := '1';                                   --�ڋq�敪.���_
  cv_cust_class_chain             CONSTANT VARCHAR2(2)  := '18';                                  --�ڋq�敪.�`�F�[���X
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)  := '10';                                  --�ڋq�敪.�X��
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)  := '12';                                  --�ڋq�敪.��l
  cv_prod_class_all               CONSTANT VARCHAR2(1)  := '0';                                   --���i�敪.�S��
  cv_item_div_h_code_A            CONSTANT VARCHAR2(1)  := 'A';                                   --�w�b�_�R�[�h
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
   ,data_type_code           xxcos_report_forms_register.data_type_code%TYPE      --���[��ʃR�[�h
   ,ebs_business_series_code VARCHAR2(100)                                       --EBS�Ɩ��n��R�[�h
   ,info_class               VARCHAR2(100)                                       --���敪
   ,report_code              xxcos_report_forms_register.report_code%TYPE         --���[�R�[�h
   ,report_name              xxcos_report_forms_register.report_name%TYPE         --���[�l��
   ,item_class               VARCHAR2(100)                                       --���i�敪
   ,edi_date_from            VARCHAR2(100)                                       --EDI�捞��(FROM)
   ,edi_date_to              VARCHAR2(100)                                       --EDI�捞��(TO)
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
-- 2009/02/16 T.Nakamura Ver.1.3 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
  );
  --�[�i���_���i�[���R�[�h
  TYPE g_base_rtype IS RECORD (
    base_name                hz_parties.party_name%TYPE                          --���_��
   ,base_name_kana           hz_parties.organization_name_phonetic%TYPE          --���_���J�i
   ,customer_code            xxcmm_cust_accounts.torihikisaki_code%TYPE          --�����R�[�h
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
  );
  --���̑����i�[���R�[�h
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --������
   ,proc_time                VARCHAR2(6)                                         --��������
   ,organization_id          NUMBER                                              --�݌ɑg�DID
   ,csv_header               VARCHAR2(32767)                                     --CSV�w�b�_
   ,process_date             DATE                                                --�Ɩ����t
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
                                                                                 --�ϒ�
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable;
                                                                                 --�݌�
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_stock;
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := false;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_debug) THEN
--      dbms_output.put_line(buff);
--    ELSE
--      FND_FILE.PUT_LINE(
--         which  => which
--        ,buff   => buff
--      );
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
                                          ,cv_tkn_prm2 , g_input_rec.chain_code
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
    --���̓p�����[�^11�`15�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.info_class
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.edi_date_from
                                          ,cv_tkn_prm14, g_input_rec.edi_date_to
                                          ,cv_tkn_prm15, g_input_rec.item_class
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
--
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
--
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
    ov_errbuf     OUT NOCOPY VARCHAR2        --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2        --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2        --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ov_errbuf     OUT NOCOPY VARCHAR2      --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2      --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
     ,g_input_rec.chain_code                      --�`�F�[���X�R�[�h
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
    out_line(buff => 'if_header:' || lv_if_header);
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
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
    i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_data_record         VARCHAR2(32767);
    lv_table_name  all_tables.table_name%TYPE;
    lv_key_info            VARCHAR2(100);
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
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : �t�b�^���R�[�h�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    ln_rec_cnt       NUMBER;
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
--
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
     ,ln_rec_cnt                  --���R�[�h����(+ CSV�w�b�_���R�[�h)
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_tkn                fnd_new_messages.message_text%TYPE;                 --���b�Z�[�W�p������
    lv_break_key_old                   VARCHAR2(100);                         --���u���C�N�L�[
    lv_break_key_new                   VARCHAR2(100);                         --�V�u���C�N�L�[
    lt_cust_po_number     oe_order_headers_all.cust_po_number%TYPE;           --�󒍃w�b�_�i�ڋq�����j
    lt_line_number        oe_order_lines_all.line_number%TYPE;                --�󒍖��ׁ@�i���הԍ��j
    lt_bargain_class                   VARCHAR2(100);
    lt_last_invoice_number             VARCHAR2(100);
    lt_outbound_flag                   VARCHAR2(100);
    lt_last_bargain_class              VARCHAR2(100);
    lb_error                           BOOLEAN;
  --�e�[�u����`
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;              --�o�̓f�[�^���
  --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
      SELECT
      ------------------------------------------------------�w�b�_���------------------------------------------------------------
             xei.medium_class                                                 medium_class                   --�}�̋敪
            ,xei.data_type_code                                               data_type_code                 --�f�[�^��R�[�h
            ,xei.file_no                                                      file_no                        --�t�@�C���m��
            ,xei.info_class                                                   info_class                     --���敪
            ,i_other_rec.proc_date                                            process_date                   --������
            ,i_other_rec.proc_time                                            process_time                   --��������
--******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
--            ,i_input_rec.base_code                                              base_code                     --���_�i����j�R�[�h
--            ,i_base_rec.base_name                                               base_name                     --���_���i�������j
--            ,i_base_rec.base_name_kana                                          base_name_alt                 --���_���i�J�i�j
            ,cdm.account_number                                                 base_code                     --���_�i����j�R�[�h
            ,DECODE( cdm.account_number
                    ,NULL
                    ,g_msg_rec.customer_notfound
                    ,cdm.base_name
             )                                                                  base_name                     --���_���i�������j
            ,cdm.base_name_kana                                                 base_name_alt                 --���_���i�J�i�j
--******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
            ,xei.edi_chain_code                                               edi_chain_code                 --�d�c�h�`�F�[���X�R�[�h
            ,i_chain_rec.chain_name                                           edi_chain_name                 --�d�c�h�`�F�[���X���i�����j
            ,i_chain_rec.chain_name_kana                                      edi_chain_name_alt             --�d�c�h�`�F�[���X���i�J�i�j
            ,i_input_rec.report_code                                          report_code                    --���[�R�[�h
            ,i_input_rec.report_name                                          report_show_name               --���[�\����
            ,hca.account_number                                               customer_code                  --�ڋq�R�[�h
            ,hp.party_name                                                    customer_name                  --�ڋq���i�����j
            ,hp.organization_name_phonetic                                    customer_name_alt              --�ڋq���i�J�i�j
            ,xei.company_code                                                 company_code                   --�ЃR�[�h
            ,xei.company_name_alt                                             company_name_alt               --�Ж��i�J�i�j
            ,xei.shop_code                                                    shop_code                      --�X�R�[�h
            ,NVL2( xei.shop_name_alt
                  ,xei.shop_name_alt
                  ,hp.organization_name_phonetic )                            shop_name_alt                  --�X���i�J�i�j
            ,NVL2( xei.delivery_center_code
                  ,xei.delivery_center_code
                  ,xca.deli_center_code )                                     delivery_center_code           --�[���Z���^�[�R�[�h
            ,NVL2( xei.delivery_center_name
                  ,xei.delivery_center_name
                  ,xca.deli_center_name )                                     delivery_center_name           --�[���Z���^�[���i�����j
            ,xei.delivery_center_name_alt                                     delivery_center_name_alt       --�[���Z���^�[���i�J�i�j
            ,xei.whse_code                                                    whse_code                      --�q�ɃR�[�h
            ,xei.whse_name                                                    whse_name                      --�q�ɖ�
            ,xei.inspect_charge_name                                          inspect_charge_name            --���i�S���Җ��i�����j
            ,xei.inspect_charge_name_alt                                      inspect_charge_name_alt        --���i�S���Җ��i�J�i�j
            ,xei.return_charge_name                                           return_charge_name             --�ԕi�S���Җ��i�����j
            ,xei.return_charge_name_alt                                       return_charge_name_alt         --�ԕi�S���Җ��i�J�i�j
            ,xei.receive_charge_name                                          receive_charge_name            --��̒S���Җ��i�����j
            ,xei.receive_charge_name_alt                                      receive_charge_name_alt        --��̒S���Җ��i�J�i�j
            ,TO_CHAR( xei.order_date,cv_date_fmt )                            order_date                     --������
            ,TO_CHAR( xei.center_delivery_date,cv_date_fmt )                  center_delivery_date           --�Z���^�[�[�i��
            ,TO_CHAR( xei.center_result_delivery_date,cv_date_fmt )           center_result_delivery_date    --�Z���^�[���[�i��
            ,TO_CHAR( xei.center_shipping_date,cv_date_fmt )                  center_shipping_date           --�Z���^�[�o�ɓ�
            ,TO_CHAR( xei.center_result_shipping_date,cv_date_fmt )           center_result_shipping_date    --�Z���^�[���o�ɓ�
            ,TO_CHAR( xei.data_creation_date_edi_data,cv_date_fmt )           data_creation_date_edi_data    --�f�[�^�쐬���i�d�c�h�f�[�^���j
            ,xei.data_creation_time_edi_data                                  data_creation_time_edi_data    --�f�[�^�쐬�����i�d�c�h�f�[�^���j
            ,TO_CHAR( xei.stk_date,cv_date_fmt )                              stk_date                       --�݌ɓ��t
            ,xei.offer_vendor_code_class                                      offer_vendor_code_class        --�񋟊�Ǝ����R�[�h�敪
            ,xei.whse_vendor_code_class                                       whse_vendor_code_class         --�q�Ɏ����R�[�h�敪
            ,xei.offer_cycle_class                                            offer_cycle_class              --�񋟃T�C�N���敪
            ,xei.stk_type                                                     stk_type                       --�݌Ɏ��
            ,xei.japanese_class                                               japanese_class                 --���{��敪
            ,xei.whse_class                                                   whse_class                     --�q�ɋ敪
            ,NVL2( xei.vendor_code
                  ,xei.vendor_code
                  ,xca.torihikisaki_code )                                    vendor_code                    --�����R�[�h
--******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
--            ,i_prf_rec.company_name || i_base_rec.base_name                   vendor_name                    --����於�i�����j
--            ,NVL2( xei.vendor_name_alt
--                  ,xei.vendor_name_alt
--                  ,i_prf_rec.company_name_kana || i_base_rec.base_name_kana ) vendor_name_alt                --����於�i�J�i�j
            ,i_prf_rec.company_name || cdm.base_name                          vendor_name                    --����於�i�����j
            ,NVL2( xei.vendor_name_alt
                  ,xei.vendor_name_alt
                  ,i_prf_rec.company_name_kana || cdm.base_name_kana )        vendor_name_alt                --����於�i�J�i�j
--******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
            ,xei.check_digit_class                                            check_digit_class              --�`�F�b�N�f�W�b�g�L���敪
            ,xei.invoice_number                                               invoice_number                 --�`�[�ԍ�
            ,xei.check_digit                                                  check_digit                    --�`�F�b�N�f�W�b�g
            ,xei.chain_peculiar_area_header                                   chain_peculiar_area_header     --�`�F�[���X�ŗL�G���A�i�w�b�_�j
      ------------------------------------------------------���׏��-------------------------------------------------------------
            ,xei.product_code_itouen                                          product_code_itouen            --���i�R�[�h�i�ɓ����j
            ,xei.product_code_other_party                                     product_code_other_party       --���i�R�[�h�i����j
            ,CASE
-- 2009/02/17 T.Nakamura Ver.1.4 mod start
--               WHEN ( xei.uom_code  = i_prf_rec.case_uom_code ) THEN
               WHEN ( xei.ebs_uom_code  = i_prf_rec.case_uom_code ) THEN
-- 2009/02/17 T.Nakamura Ver.1.4 mod end
                 xsib.case_jan_code
               ELSE
                 iimb.attribute21
             END                                                              jan_code                       --�i�`�m�R�[�h
            ,iimb.attribute22                                                 itf_code                       --�h�s�e�R�[�h
            ,NVL( ximb.item_name,i_msg_rec.item_notfound )                    product_name                   --���i���i�����j
            --,ximb.item_name                                                   product_name                   --���i���i�����j
            ,NVL2( xei.product_name_alt
                  ,xei.product_name_alt
                  ,ximb.item_name_alt )                                       product_name_alt               --���i���i�J�i�j
            ,xhpcv.item_div_h_code                                            prod_class                     --���i�敪
            ,xei.active_quality_class                                         active_quality_class           --�K�p�i���敪
            ,xei.qty_in_case                                                  qty_in_case                    --����
-- 2009/02/17 T.Nakamura Ver.1.4 mod start
--            ,xei.uom_code                                                     uom_code                       --�P��
            ,xei.ebs_uom_code                                                 uom_code                       --�P��
-- 2009/02/17 T.Nakamura Ver.1.4 mod end
            ,xei.day_average_shipping_qty                                     day_average_shipping_qty       --������Ϗo�א���
            ,xei.stk_type_code                                                stk_type_code                  --�݌Ɏ�ʃR�[�h
            ,TO_CHAR( xei.last_arrival_date,cv_date_fmt )                     last_arrival_date              --�ŏI���ד�
            ,TO_CHAR( xei.use_by_date,cv_date_fmt )                           use_by_date                    --�ܖ�����
            ,TO_CHAR( xei.product_date,cv_date_fmt )                          product_date                   --������
            ,xei.upper_limit_stk_case                                         upper_limit_stk_case           --����݌Ɂi�P�[�X�j
            ,xei.upper_limit_stk_indv                                         upper_limit_stk_indv           --����݌Ɂi�o���j
            ,xei.indv_order_point                                             indv_order_point               --�����_�i�o���j
            ,xei.case_order_point                                             case_order_point               --�����_�i�P�[�X�j
            ,xei.indv_prev_month_stk_qty                                      indv_prev_month_stk_qty        --�O�����݌ɐ��ʁi�o���j
            ,xei.case_prev_month_stk_qty                                      case_prev_month_stk_qty        --�O�����݌ɐ��ʁi�P�[�X�j
            ,xei.sum_prev_month_stk_qty                                       sum_prev_month_stk_qty         --�O���݌ɐ��ʁi���v�j
            ,xei.day_indv_order_qty                                           day_indv_order_qty             --�������ʁi�����A�o���j
            ,xei.day_case_order_qty                                           day_case_order_qty             --�������ʁi�����A�P�[�X�j
            ,xei.day_sum_order_qty                                            day_sum_order_qty              --�������ʁi�����A���v�j
            ,xei.month_indv_order_qty                                         month_indv_order_qty           --�������ʁi�����A�o���j
            ,xei.month_case_order_qty                                         month_case_order_qty           --�������ʁi�����A�P�[�X�j
            ,xei.month_sum_order_qty                                          month_sum_order_qty            --�������ʁi�����A���v�j
            ,xei.day_indv_arrival_qty                                         day_indv_arrival_qty           --���ɐ��ʁi�����A�o���j
            ,xei.day_case_arrival_qty                                         day_case_arrival_qty           --���ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_arrival_qty                                          day_sum_arrival_qty            --���ɐ��ʁi�����A���v�j
            ,xei.month_arrival_count                                          month_arrival_count            --�������׉�
            ,xei.month_indv_arrival_qty                                       month_indv_arrival_qty         --���ɐ��ʁi�����A�o���j
            ,xei.month_case_arrival_qty                                       month_case_arrival_qty         --���ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_arrival_qty                                        month_sum_arrival_qty          --���ɐ��ʁi�����A���v�j
            ,xei.day_indv_shipping_qty                                        day_indv_shipping_qty          --�o�ɐ��ʁi�����A�o���j
            ,xei.day_case_shipping_qty                                        day_case_shipping_qty          --�o�ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_shipping_qty                                         day_sum_shipping_qty           --�o�ɐ��ʁi�����A���v�j
            ,xei.month_indv_shipping_qty                                      month_indv_shipping_qty        --�o�ɐ��ʁi�����A�o���j
            ,xei.month_case_shipping_qty                                      month_case_shipping_qty        --�o�ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_shipping_qty                                       month_sum_shipping_qty         --�o�ɐ��ʁi�����A���v�j
            ,xei.day_indv_destroy_loss_qty                                    day_indv_destroy_loss_qty      --�j���A���X���ʁi�����A�o���j
            ,xei.day_case_destroy_loss_qty                                    day_case_destroy_loss_qty      --�j���A���X���ʁi�����A�P�[�X�j
            ,xei.day_sum_destroy_loss_qty                                     day_sum_destroy_loss_qty       --�j���A���X���ʁi�����A���v�j
            ,xei.month_indv_destroy_loss_qty                                  month_indv_destroy_loss_qty    --�j���A���X���ʁi�����A�o���j
            ,xei.month_case_destroy_loss_qty                                  month_case_destroy_loss_qty    --�j���A���X���ʁi�����A�P�[�X�j
            ,xei.month_sum_destroy_loss_qty                                   month_sum_destroy_loss_qty     --�j���A���X���ʁi�����A���v�j
            ,xei.day_indv_defect_stk_qty                                      day_indv_defect_stk_qty        --�s�Ǎ݌ɐ��ʁi�����A�o���j
            ,xei.day_case_defect_stk_qty                                      day_case_defect_stk_qty        --�s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_defect_stk_qty                                       day_sum_defect_stk_qty         --�s�Ǎ݌ɐ��ʁi�����A���v�j
            ,xei.month_indv_defect_stk_qty                                    month_indv_defect_stk_qty      --�s�Ǎ݌ɐ��ʁi�����A�o���j
            ,xei.month_case_defect_stk_qty                                    month_case_defect_stk_qty      --�s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_defect_stk_qty                                     month_sum_defect_stk_qty       --�s�Ǎ݌ɐ��ʁi�����A���v�j
            ,xei.day_indv_defect_return_qty                                   day_indv_defect_return_qty     --�s�Ǖԕi���ʁi�����A�o���j
            ,xei.day_case_defect_return_qty                                   day_case_defect_return_qty     --�s�Ǖԕi���ʁi�����A�P�[�X�j
            ,xei.day_sum_defect_return_qty                                    day_sum_defect_return_qty      --�s�Ǖԕi���ʁi�����A���v�j
            ,xei.month_indv_defect_return_qty                                 month_indv_defect_return_qty   --�s�Ǖԕi���ʁi�����A�o���j
            ,xei.month_case_defect_return_qty                                 month_case_defect_return_qty   --�s�Ǖԕi���ʁi�����A�P�[�X�j
            ,xei.month_sum_defect_return_qty                                  month_sum_defect_return_qty    --�s�Ǖԕi���ʁi�����A���v�j
            ,xei.day_indv_defect_return_rcpt                                  day_indv_defect_return_rcpt    --�s�Ǖԕi����i�����A�o���j
            ,xei.day_case_defect_return_rcpt                                  day_case_defect_return_rcpt    --�s�Ǖԕi����i�����A�P�[�X�j
            ,xei.day_sum_defect_return_rcpt                                   day_sum_defect_return_rcpt     --�s�Ǖԕi����i�����A���v�j
            ,xei.month_indv_defect_return_rcpt                                month_indv_defect_return_rcpt  --�s�Ǖԕi����i�����A�o���j
            ,xei.month_case_defect_return_rcpt                                month_case_defect_return_rcpt  --�s�Ǖԕi����i�����A�P�[�X�j
            ,xei.month_sum_defect_return_rcpt                                 month_sum_defect_return_rcpt   --�s�Ǖԕi����i�����A���v�j
            ,xei.day_indv_defect_return_send                                  day_indv_defect_return_send    --�s�Ǖԕi�����i�����A�o���j
            ,xei.day_case_defect_return_send                                  day_case_defect_return_send    --�s�Ǖԕi�����i�����A�P�[�X�j
            ,xei.day_sum_defect_return_send                                   day_sum_defect_return_send     --�s�Ǖԕi�����i�����A���v�j
            ,xei.month_indv_defect_return_send                                month_indv_defect_return_send  --�s�Ǖԕi�����i�����A�o���j
            ,xei.month_case_defect_return_send                                month_case_defect_return_send  --�s�Ǖԕi�����i�����A�P�[�X�j
            ,xei.month_sum_defect_return_send                                 month_sum_defect_return_send   --�s�Ǖԕi�����i�����A���v�j
            ,xei.day_indv_quality_return_rcpt                                 day_indv_quality_return_rcpt   --�Ǖi�ԕi����i�����A�o���j
            ,xei.day_case_quality_return_rcpt                                 day_case_quality_return_rcpt   --�Ǖi�ԕi����i�����A�P�[�X�j
            ,xei.day_sum_quality_return_rcpt                                  day_sum_quality_return_rcpt    --�Ǖi�ԕi����i�����A���v�j
            ,xei.month_indv_quality_return_rcpt                               month_indv_quality_return_rcpt --�Ǖi�ԕi����i�����A�o���j
            ,xei.month_case_quality_return_rcpt                               month_case_quality_return_rcpt --�Ǖi�ԕi����i�����A�P�[�X�j
            ,xei.month_sum_quality_return_rcpt                                month_sum_quality_return_rcpt  --�Ǖi�ԕi����i�����A���v�j
            ,xei.day_indv_quality_return_send                                 day_indv_quality_return_send   --�Ǖi�ԕi�����i�����A�o���j
            ,xei.day_case_quality_return_send                                 day_case_quality_return_send   --�Ǖi�ԕi�����i�����A�P�[�X�j
            ,xei.day_sum_quality_return_send                                  day_sum_quality_return_send    --�Ǖi�ԕi�����i�����A���v�j
            ,xei.month_indv_quality_return_send                               month_indv_quality_return_send --�Ǖi�ԕi�����i�����A�o���j
            ,xei.month_case_quality_return_send                               month_case_quality_return_send --�Ǖi�ԕi�����i�����A�P�[�X�j
            ,xei.month_sum_quality_return_send                                month_sum_quality_return_send  --�Ǖi�ԕi�����i�����A���v�j
            ,xei.day_indv_invent_difference                                   day_indv_invent_difference     --�I�����فi�����A�o���j
            ,xei.day_case_invent_difference                                   day_case_invent_difference     --�I�����فi�����A�P�[�X�j
            ,xei.day_sum_invent_difference                                    day_sum_invent_difference      --�I�����فi�����A���v�j
            ,xei.month_indv_invent_difference                                 month_indv_invent_difference   --�I�����فi�����A�o���j
            ,xei.month_case_invent_difference                                 month_case_invent_difference   --�I�����فi�����A�P�[�X�j
            ,xei.month_sum_invent_difference                                  month_sum_invent_difference    --�I�����فi�����A���v�j
            ,xei.day_indv_stk_qty                                             day_indv_stk_qty               --�݌ɐ��ʁi�����A�o���j
            ,xei.day_case_stk_qty                                             day_case_stk_qty               --�݌ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_stk_qty                                              day_sum_stk_qty                --�݌ɐ��ʁi�����A���v�j
            ,xei.month_indv_stk_qty                                           month_indv_stk_qty             --�݌ɐ��ʁi�����A�o���j
            ,xei.month_case_stk_qty                                           month_case_stk_qty             --�݌ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_stk_qty                                            month_sum_stk_qty              --�݌ɐ��ʁi�����A���v�j
            ,xei.day_indv_reserved_stk_qty                                    day_indv_reserved_stk_qty      --�ۗ��݌ɐ��i�����A�o���j
            ,xei.day_case_reserved_stk_qty                                    day_case_reserved_stk_qty      --�ۗ��݌ɐ��i�����A�P�[�X�j
            ,xei.day_sum_reserved_stk_qty                                     day_sum_reserved_stk_qty       --�ۗ��݌ɐ��i�����A���v�j
            ,xei.month_indv_reserved_stk_qty                                  month_indv_reserved_stk_qty    --�ۗ��݌ɐ��i�����A�o���j
            ,xei.month_case_reserved_stk_qty                                  month_case_reserved_stk_qty    --�ۗ��݌ɐ��i�����A�P�[�X�j
            ,xei.month_sum_reserved_stk_qty                                   month_sum_reserved_stk_qty     --�ۗ��݌ɐ��i�����A���v�j
            ,xei.day_indv_cd_stk_qty                                          day_indv_cd_stk_qty            --�����݌ɐ��ʁi�����A�o���j
            ,xei.day_case_cd_stk_qty                                          day_case_cd_stk_qty            --�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_cd_stk_qty                                           day_sum_cd_stk_qty             --�����݌ɐ��ʁi�����A���v�j
            ,xei.month_indv_cd_stk_qty                                        month_indv_cd_stk_qty          --�����݌ɐ��ʁi�����A�o���j
            ,xei.month_case_cd_stk_qty                                        month_case_cd_stk_qty          --�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_cd_stk_qty                                         month_sum_cd_stk_qty           --�����݌ɐ��ʁi�����A���v�j
            ,xei.day_indv_cargo_stk_qty                                       day_indv_cargo_stk_qty         --�ϑ��݌ɐ��ʁi�����A�o���j
            ,xei.day_case_cargo_stk_qty                                       day_case_cargo_stk_qty         --�ϑ��݌ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_cargo_stk_qty                                        day_sum_cargo_stk_qty          --�ϑ��݌ɐ��ʁi�����A���v�j
            ,xei.month_indv_cargo_stk_qty                                     month_indv_cargo_stk_qty       --�ϑ��݌ɐ��ʁi�����A�o���j
            ,xei.month_case_cargo_stk_qty                                     month_case_cargo_stk_qty       --�ϑ��݌ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_cargo_stk_qty                                      month_sum_cargo_stk_qty        --�ϑ��݌ɐ��ʁi�����A���v�j
            ,xei.day_indv_adjustment_stk_qty                                  day_indv_adjustment_stk_qty    --�����݌ɐ��ʁi�����A�o���j
            ,xei.day_case_adjustment_stk_qty                                  day_case_adjustment_stk_qty    --�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.day_sum_adjustment_stk_qty                                   day_sum_adjustment_stk_qty     --�����݌ɐ��ʁi�����A���v�j
            ,xei.month_indv_adjustment_stk_qty                                month_indv_adjustment_stk_qty  --�����݌ɐ��ʁi�����A�o���j
            ,xei.month_case_adjustment_stk_qty                                month_case_adjustment_stk_qty  --�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.month_sum_adjustment_stk_qty                                 month_sum_adjustment_stk_qty   --�����݌ɐ��ʁi�����A���v�j
            ,xei.day_indv_still_shipping_qty                                  day_indv_still_shipping_qty    --���o�א��ʁi�����A�o���j
            ,xei.day_case_still_shipping_qty                                  day_case_still_shipping_qty    --���o�א��ʁi�����A�P�[�X�j
            ,xei.day_sum_still_shipping_qty                                   day_sum_still_shipping_qty     --���o�א��ʁi�����A���v�j
            ,xei.month_indv_still_shipping_qty                                month_indv_still_shipping_qty  --���o�א��ʁi�����A�o���j
            ,xei.month_case_still_shipping_qty                                month_case_still_shipping_qty  --���o�א��ʁi�����A�P�[�X�j
            ,xei.month_sum_still_shipping_qty                                 month_sum_still_shipping_qty   --���o�א��ʁi�����A���v�j
            ,xei.indv_all_stk_qty                                             indv_all_stk_qty               --���݌ɐ��ʁi�o���j
            ,xei.case_all_stk_qty                                             case_all_stk_qty               --���݌ɐ��ʁi�P�[�X�j
            ,xei.sum_all_stk_qty                                              sum_all_stk_qty                --���݌ɐ��ʁi���v�j
            ,xei.month_draw_count                                             month_draw_count               --����������
            ,xei.day_indv_draw_possible_qty                                   day_indv_draw_possible_qty     --�����\���ʁi�����A�o���j
            ,xei.day_case_draw_possible_qty                                   day_case_draw_possible_qty     --�����\���ʁi�����A�P�[�X�j
            ,xei.day_sum_draw_possible_qty                                    day_sum_draw_possible_qty      --�����\���ʁi�����A���v�j
            ,xei.month_indv_draw_possible_qty                                 month_indv_draw_possible_qty   --�����\���ʁi�����A�o���j
            ,xei.month_case_draw_possible_qty                                 month_case_draw_possible_qty   --�����\���ʁi�����A�P�[�X�j
            ,xei.month_sum_draw_possible_qty                                  month_sum_draw_possible_qty    --�����\���ʁi�����A���v�j
            ,xei.day_indv_draw_impossible_qty                                 day_indv_draw_impossible_qty   --�����s�\���i�����A�o���j
            ,xei.day_case_draw_impossible_qty                                 day_case_draw_impossible_qty   --�����s�\���i�����A�P�[�X�j
            ,xei.day_sum_draw_impossible_qty                                  day_sum_draw_impossible_qty    --�����s�\���i�����A���v�j
            ,xei.day_stk_amt                                                  day_stk_amt                    --�݌ɋ��z�i�����j
            ,xei.month_stk_amt                                                month_stk_amt                  --�݌ɋ��z�i�����j
            ,xei.remarks                                                      remarks                        --���l
            ,xei.chain_peculiar_area_line                                     chain_peculiar_area_line       --�`�F�[���X�ŗL�G���A�i���ׁj
      ------------------------------------------------------�t�b�^���------------------------------------------------------------
            ,xei.invoice_day_indv_sum_stk_qty                                 invoice_day_indv_sum_stk_qty   --�i�v�j�݌ɐ��ʍ��v�i�����A�o���j
            ,xei.invoice_day_case_sum_stk_qty                                 invoice_day_case_sum_stk_qty   --�i�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
            ,xei.invoice_day_sum_sum_stk_qty                                  invoice_day_sum_sum_stk_qty    --�i�v�j�݌ɐ��ʍ��v�i�����A���v�j
            ,xei.invoice_month_indv_sum_stk_qty                               invoice_month_indv_sum_stk_qty --�i�v�j�݌ɐ��ʍ��v�i�����A�o���j
            ,xei.invoice_month_case_sum_stk_qty                               invoice_month_case_sum_stk_qty --�i�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
            ,xei.invoice_month_sum_sum_stk_qty                                invoice_month_sum_sum_stk_qty  --�i�v�j�݌ɐ��ʍ��v�i�����A���v�j
            ,xei.invoice_day_indv_cd_stk_qty                                  invoice_day_indv_cd_stk_qty    --�i�v�j�����݌ɐ��ʁi�����A�o���j
            ,xei.invoice_day_case_cd_stk_qty                                  invoice_day_case_cd_stk_qty    --�i�v�j�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.invoice_day_sum_cd_stk_qty                                   invoice_day_sum_cd_stk_qty     --�i�v�j�����݌ɐ��ʁi�����A���v�j
            ,xei.invoice_month_indv_cd_stk_qty                                invoice_month_indv_cd_stk_qty  --�i�v�j�����݌ɐ��ʁi�����A�o���j
            ,xei.invoice_month_case_cd_stk_qty                                invoice_month_case_cd_stk_qty  --�i�v�j�����݌ɐ��ʁi�����A�P�[�X�j
            ,xei.invoice_month_sum_cd_stk_qty                                 invoice_month_sum_cd_stk_qty   --�i�v�j�����݌ɐ��ʁi�����A���v�j
            ,xei.invoice_day_stk_amt                                          invoice_day_stk_amt            --�i�v�j�݌ɋ��z�i�����j
            ,xei.invoice_month_stk_amt                                        invoice_month_stk_amt          --�i�v�j�݌ɋ��z�i�����j
            ,xei.regular_sell_amt_sum                                         regular_sell_amt_sum           --���̋��z���v
            ,xei.rebate_amt_sum                                               rebate_amt_sum                 --���߂����z���v
            ,xei.collect_bottle_amt_sum                                       collect_bottle_amt_sum         --����e����z���v
            ,xei.chain_peculiar_area_footer                                   chain_peculiar_area_footer     --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      --���o����
      FROM   xxcos_edi_inventory                                              xei                            --EDI�݌ɏ��e�[�u��
            ,xxcmm_cust_accounts                                              xca                            --�ڋq�}�X�^�A�h�I��
            ,hz_cust_accounts                                                 hca                            --�ڋq�}�X�^
            ,hz_parties                                                       hp                             --�p�[�e�B�}�X�^
            ,ic_item_mst_b                                                    iimb                           --OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b                                                 ximb                           --OPM�i�ڃ}�X�^�A�h�I��
            ,mtl_system_items_b                                               msib                           --DISC�i�ڃ}�X�^
            ,xxcmm_system_items_b                                             xsib                           --DISC�i�ڃ}�X�^�A�h�I��
            ,xxcos_head_prod_class_v                                          xhpcv                          --�{�Џ��i�敪�r���[
            ,xxcos_chain_store_security_v                                     xcss                           --�`�F�[���X�X�܃Z�L�����e�B�r���[
--******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
            ,(
              SELECT hca.account_number                                         account_number               --�ڋq�R�[�h
                    ,hp.party_name                                              base_name                    --�ڋq����
                    ,hp.organization_name_phonetic                              base_name_kana               --�ڋq����(�J�i)
              FROM   hz_cust_accounts                                           hca                          --�ڋq�}�X�^
                    ,xxcmm_cust_accounts                                        xca                          --�ڋq�}�X�^�A�h�I��
                    ,hz_parties                                                 hp                           --�p�[�e�B�}�X�^
              WHERE  hca.customer_class_code = cv_cust_class_base
              AND    xca.customer_id         = hca.cust_account_id
              AND    hp.party_id             = hca.party_id
             )                                                                  cdm
--******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
    --EDI�݌ɏ��e�[�u��
    WHERE  xei.data_type_code             = i_input_rec.data_type_code                                       --�f�[�^��R�[�h
      AND  ( i_input_rec.info_class        IS NOT NULL                                                       --���敪
         AND xei.info_class               = i_input_rec.info_class
         OR  i_input_rec.info_class        IS NULL
      )
      AND  ( xei.edi_chain_code           = i_input_rec.chain_code )                                         --�`�F�[���X�R�[�h
--******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
--      AND  ( i_input_rec.store_code        IS NOT NULL                                                       --�X�܃R�[�h
--         AND  xei.shop_code               = i_input_rec.store_code
--         AND  xei.shop_code = xcss.chain_store_code
--         OR   i_input_rec.store_code       IS NULL
--         AND  xei.shop_code               = xcss.chain_store_code
--      )
      AND  xei.shop_code                  = NVL( i_input_rec.store_code, xei.shop_code )                     --�X�܃R�[�h
--******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
      AND   TRUNC(xei.data_creation_date_edi_data)                                                           --�f�[�^�쐬��
             BETWEEN TO_DATE(i_input_rec.edi_date_from, cv_date_fmt )
             AND     TO_DATE(i_input_rec.edi_date_to  , cv_date_fmt )
      AND  ( i_input_rec.item_class      != cv_prod_class_all                                                --���i�敪
         AND NVL( xhpcv.item_div_h_code,cv_item_div_h_code_A )
                                          = i_input_rec.item_class
         OR  i_input_rec.item_class       = cv_prod_class_all )
    --�ڋq�A�h�I��
      AND  xca.chain_store_code(+)        = xei.edi_chain_code                                               --�`�F�[���X�R�[�h
      AND  xca.store_code(+)              = xei.shop_code                                                    --�X�܃R�[�h
    --�ڋq�}�X�^
      AND  ( hca.cust_account_id(+)       = xca.customer_id )                                                --�ڋqID
      AND   ( hca.cust_account_id IS NOT NULL
        AND   hca.customer_class_code IN ( cv_cust_class_chain_store, cv_cust_class_uesama )
        OR    hca.cust_account_id IS NULL
             )                                                                                               --�ڋq�敪
    --�p�[�e�B�}�X�^
      AND hp.party_id(+) = hca.party_id
    --OPM�i�ڃ}�X�^
      AND  iimb.item_no(+)                = xei.item_code                                                    --�i�ڃR�[�h
    --OPM�i�ڃA�h�I��
      AND  ximb.item_id(+)                = iimb.item_id                                                     --�i��ID
      AND  NVL( xei.center_delivery_date
              ,NVL( xei.order_date
                   ,data_creation_date_edi_data ) )
              BETWEEN ( NVL( ximb.start_date_active                                                          --�K�p�J�n��
                                  ,NVL( xei.center_delivery_date
                                       ,NVL( xei.order_date
                                             ,data_creation_date_edi_data  ) ) ) )
              AND     ( NVL( ximb.end_date_active                                                            --�K�p�I����
                                   ,NVL( xei.center_delivery_date
                                         ,NVL( xei.order_date
                                             ,data_creation_date_edi_data  ) ) ) )
    --DISC�i�ڃ}�X�^
      AND  msib.segment1(+)               = xei.item_code
      AND  msib.organization_id(+)        = i_other_rec.organization_id                                      --�݌ɑg�DID
    --DISC�i�ڃA�h�I��
      AND  xsib.item_code(+)              = msib.segment1                                                    --�i�ڃR�[�h
    --���i�敪VIEW
      AND  xhpcv.segment1(+)              = iimb.item_no                                                     --�i��ID
    --�X�܃Z�L�����e�BVIEW
--******************************************* 2009/04/02 1.7 T.Kitajima MOD START *************************************
--      AND  xcss.chain_code                = i_input_rec.chain_code                                         --�`�F�[���X�R�[�h
--      AND  xcss.user_id                   = i_input_rec.user_id                                            --���[�UID
      AND  xcss.chain_code(+)             = xei.edi_chain_code                                               --�`�F�[���X�R�[�h
      AND  xcss.chain_store_code(+)       = xei.shop_code                                                    --�X�R�[�h
      AND  xcss.user_id(+)                = i_input_rec.user_id                                              --���[�UID
--******************************************* 2009/04/02 1.7 T.Kitajima MOD  END  *************************************
--******************************************* 2009/04/02 1.7 T.Kitajima ADD START *************************************
      AND xca.delivery_base_code          = cdm.account_number(+)
--******************************************* 2009/04/02 1.7 T.Kitajima ADD  END  *************************************
      ;
    -- *** ���[�J���E���R�[�h ***
    l_base_rec                 g_base_rtype;                                                                 --�[�i���_���
    l_chain_rec                g_chain_rtype;                                                                --EDI�`�F�[���X���
    l_other_rec                g_other_rtype;                                                                --���̑����
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
--
--******************************************* 2009/04/02 1.7 T.Kitajima DEL START *************************************
--    --==============================================================
--    --�[�i���_���擾
--    --==============================================================
--    BEGIN
--      SELECT hp.party_name                                                    base_name                      --�ڋq����
--            ,hp.organization_name_phonetic                                    base_name_kana                 --�ڋq����(�J�i)
--            ,xca.torihikisaki_code                                            customer_code                  --�����R�[�h
--      INTO   l_base_rec.base_name
--            ,l_base_rec.base_name_kana
--            ,l_base_rec.customer_code
--      FROM   hz_cust_accounts                                                 hca                            --�ڋq�}�X�^
--            ,xxcmm_cust_accounts                                              xca                            --�ڋq�}�X�^�A�h�I��
--            ,hz_parties                                                       hp                             --�p�[�e�B�}�X�^
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--            ,hz_cust_acct_sites_all                                           hcas                           --�ڋq���ݒn
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--            ,hz_party_sites                                                   hps                            --�p�[�e�B�T�C�g�}�X�^
--            ,hz_locations                                                     hl                             --���Ə��}�X�^
--      --�ڋq�}�X�^���o����
--      WHERE  hca.account_number      = g_input_rec.base_code
--      AND    hca.customer_class_code = cv_cust_class_base
--      --�ڋq�}�X�^�A�h�I�����o����
--      AND    xca.customer_id         = hca.cust_account_id
--      --�p�[�e�B�}�X�^���o����
--      AND    hp.party_id             = hca.party_id
--     --�p�[�e�B�T�C�g���o����
--      AND    hps.party_id            = hca.party_id
--      --�ڋq���Ə��}�X�^���o����
--      AND    hl.location_id          = hps.location_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND    hcas.cust_account_id    = hca.cust_account_id
--      AND    hps.party_site_id       = hcas.party_site_id
--      AND    hcas.org_id             = g_prf_rec.org_id
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--      ;
--
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_base_rec.base_name := g_msg_rec.customer_notfound;
--    END;
--******************************************* 2009/04/02 1.7 T.Kitajima DEL  END  *************************************
--
    --==============================================================
    --�`�F�[���X���擾
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                    chain_name                     --�`�F�[���X����
            ,hp.organization_name_phonetic                                    chain_name_kana                --�`�F�[���X����(�J�i)
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana
      FROM   xxcmm_cust_accounts                                              xca                            --�ڋq�}�X�^�A�h�I��
            ,hz_cust_accounts                                                 hca                            --�ڋq�}�X�^
            ,hz_parties                                                       hp                             --�p�[�e�B�}�X�^
      WHERE  xca.edi_chain_code      = g_input_rec.chain_code
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id             = hca.party_id
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
            ------------------------------------------------�w�b�_���------------------------------------------------
        l_data_tab('MEDIUM_CLASS')                                            --�}�̋敪
       ,l_data_tab('DATA_TYPE_CODE')                                          --�f�[�^��R�[�h
       ,l_data_tab('FILE_NO')                                                 --�t�@�C���m��
       ,l_data_tab('INFO_CLASS')                                              --���敪
       ,l_data_tab('PROCESS_DATE')                                            --������
       ,l_data_tab('PROCESS_TIME')                                            --��������
       ,l_data_tab('BASE_CODE')                                               --���_�i����j�R�[�h
       ,l_data_tab('BASE_NAME')                                               --���_���i�������j
       ,l_data_tab('BASE_NAME_ALT')                                           --���_���i�J�i�j
       ,l_data_tab('EDI_CHAIN_CODE')                                          --�d�c�h�`�F�[���X�R�[�h
       ,l_data_tab('EDI_CHAIN_NAME')                                          --�d�c�h�`�F�[���X���i�����j
       ,l_data_tab('EDI_CHAIN_NAME_ALT')                                      --�d�c�h�`�F�[���X���i�J�i�j
       ,l_data_tab('REPORT_CODE')                                             --���[�R�[�h
       ,l_data_tab('REPORT_SHOW_NAME')                                        --���[�\����
       ,l_data_tab('CUSTOMER_CODE')                                           --�ڋq�R�[�h
       ,l_data_tab('CUSTOMER_NAME')                                           --�ڋq���i�����j
       ,l_data_tab('CUSTOMER_NAME_ALT')                                       --�ڋq���i�J�i�j
       ,l_data_tab('COMPANY_CODE')                                            --�ЃR�[�h
       ,l_data_tab('COMPANY_NAME_ALT')                                        --�Ж��i�J�i�j
       ,l_data_tab('SHOP_CODE')                                               --�X�R�[�h
       ,l_data_tab('SHOP_NAME_ALT')                                           --�X���i�J�i�j
       ,l_data_tab('DELIVERY_CENTER_CODE')                                    --�[���Z���^�[�R�[�h
       ,l_data_tab('DELIVERY_CENTER_NAME')                                    --�[���Z���^�[���i�����j
       ,l_data_tab('DELIVERY_CENTER_NAME_ALT')                                --�[���Z���^�[���i�J�i�j
       ,l_data_tab('WHSE_CODE')                                               --�q�ɃR�[�h
       ,l_data_tab('WHSE_NAME')                                               --�q�ɖ�
       ,l_data_tab('INSPECT_CHARGE_NAME')                                     --���i�S���Җ��i�����j
       ,l_data_tab('INSPECT_CHARGE_NAME_ALT')                                 --���i�S���Җ��i�J�i�j
       ,l_data_tab('RETURN_CHARGE_NAME')                                      --�ԕi�S���Җ��i�����j
       ,l_data_tab('RETURN_CHARGE_NAME_ALT')                                  --�ԕi�S���Җ��i�J�i�j
       ,l_data_tab('RECEIVE_CHARGE_NAME')                                     --��̒S���Җ��i�����j
       ,l_data_tab('RECEIVE_CHARGE_NAME_ALT')                                 --��̒S���Җ��i�J�i�j
       ,l_data_tab('ORDER_DATE')                                              --������
       ,l_data_tab('CENTER_DELIVERY_DATE')                                    --�Z���^�[�[�i��
       ,l_data_tab('CENTER_RESULT_DELIVERY_DATE')                             --�Z���^�[���[�i��
       ,l_data_tab('CENTER_SHIPPING_DATE')                                    --�Z���^�[�o�ɓ�
       ,l_data_tab('CENTER_RESULT_SHIPPING_DATE')                             --�Z���^�[���o�ɓ�
       ,l_data_tab('DATA_CREATION_DATE_EDI_DATA')                             --�f�[�^�쐬���i�d�c�h�f�[�^���j
       ,l_data_tab('DATA_CREATION_TIME_EDI_DATA')                             --�f�[�^�쐬�����i�d�c�h�f�[�^���j
       ,l_data_tab('STK_DATE')                                                --�݌ɓ��t
       ,l_data_tab('OFFER_VENDOR_CODE_CLASS')                                 --�񋟊�Ǝ����R�[�h�敪
       ,l_data_tab('WHSE_VENDOR_CODE_CLASS')                                  --�q�Ɏ����R�[�h�敪
       ,l_data_tab('OFFER_CYCLE_CLASS')                                       --�񋟃T�C�N���敪
       ,l_data_tab('STK_TYPE')                                                --�݌Ɏ��
       ,l_data_tab('JAPANESE_CLASS')                                          --���{��敪
       ,l_data_tab('WHSE_CLASS')                                              --�q�ɋ敪
       ,l_data_tab('VENDOR_CODE')                                             --�����R�[�h
       ,l_data_tab('VENDOR_NAME')                                             --����於�i�����j
       ,l_data_tab('VENDOR_NAME_ALT')                                         --����於�i�J�i�j
       ,l_data_tab('CHECK_DIGIT_CLASS')                                       --�`�F�b�N�f�W�b�g�L���敪
       ,l_data_tab('INVOICE_NUMBER')                                          --�`�[�ԍ�
       ,l_data_tab('CHECK_DIGIT')                                             --�`�F�b�N�f�W�b�g
       ,l_data_tab('CHAIN_PECULIAR_AREA_HEADER')                              --�`�F�[���X�ŗL�G���A�i�w�b�_�j
            -------------------------------------------------���׏��-------------------------------------------------
       ,l_data_tab('PRODUCT_CODE_ITOUEN')                                     --���i�R�[�h�i�ɓ����j
       ,l_data_tab('PRODUCT_CODE_OTHER_PARTY')                                --���i�R�[�h�i����j
       ,l_data_tab('JAN_CODE')                                                --�i�`�m�R�[�h
       ,l_data_tab('ITF_CODE')                                                --�h�s�e�R�[�h
       ,l_data_tab('PRODUCT_NAME')                                            --���i���i�����j
       ,l_data_tab('PRODUCT_NAME_ALT')                                        --���i���i�J�i�j
       ,l_data_tab('PROD_CLASS')                                              --���i�敪
       ,l_data_tab('ACTIVE_QUALITY_CLASS')                                    --�K�p�i���敪
       ,l_data_tab('QTY_IN_CASE')                                             --����
       ,l_data_tab('UOM_CODE')                                                --�P��
       ,l_data_tab('DAY_AVERAGE_SHIPPING_QTY')                                --������Ϗo�א���
       ,l_data_tab('STK_TYPE_CODE')                                           --�݌Ɏ�ʃR�[�h
       ,l_data_tab('LAST_ARRIVAL_DATE')                                       --�ŏI���ד�
       ,l_data_tab('USE_BY_DATE')                                             --�ܖ�����
       ,l_data_tab('PRODUCT_DATE')                                            --������
       ,l_data_tab('UPPER_LIMIT_STK_CASE')                                    --����݌Ɂi�P�[�X�j
       ,l_data_tab('UPPER_LIMIT_STK_INDV')                                    --����݌Ɂi�o���j
       ,l_data_tab('INDV_ORDER_POINT')                                        --�����_�i�o���j
       ,l_data_tab('CASE_ORDER_POINT')                                        --�����_�i�P�[�X�j
       ,l_data_tab('INDV_PREV_MONTH_STK_QTY')                                 --�O�����݌ɐ��ʁi�o���j
       ,l_data_tab('CASE_PREV_MONTH_STK_QTY')                                 --�O�����݌ɐ��ʁi�P�[�X�j
       ,l_data_tab('SUM_PREV_MONTH_STK_QTY')                                  --�O���݌ɐ��ʁi���v�j
       ,l_data_tab('DAY_INDV_ORDER_QTY')                                      --�������ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_ORDER_QTY')                                      --�������ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_ORDER_QTY')                                       --�������ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_ORDER_QTY')                                    --�������ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_ORDER_QTY')                                    --�������ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_ORDER_QTY')                                     --�������ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_ARRIVAL_QTY')                                    --���ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_ARRIVAL_QTY')                                    --���ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_ARRIVAL_QTY')                                     --���ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_ARRIVAL_COUNT')                                     --�������׉�
       ,l_data_tab('MONTH_INDV_ARRIVAL_QTY')                                  --���ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_ARRIVAL_QTY')                                  --���ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_ARRIVAL_QTY')                                   --���ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_SHIPPING_QTY')                                   --�o�ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_SHIPPING_QTY')                                   --�o�ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_SHIPPING_QTY')                                    --�o�ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_SHIPPING_QTY')                                 --�o�ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_SHIPPING_QTY')                                 --�o�ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_SHIPPING_QTY')                                  --�o�ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_DESTROY_LOSS_QTY')                               --�j���A���X���ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_DESTROY_LOSS_QTY')                               --�j���A���X���ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DESTROY_LOSS_QTY')                                --�j���A���X���ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_DESTROY_LOSS_QTY')                             --�j���A���X���ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_DESTROY_LOSS_QTY')                             --�j���A���X���ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DESTROY_LOSS_QTY')                              --�j���A���X���ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_DEFECT_STK_QTY')                                 --�s�Ǎ݌ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_DEFECT_STK_QTY')                                 --�s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DEFECT_STK_QTY')                                  --�s�Ǎ݌ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_DEFECT_STK_QTY')                               --�s�Ǎ݌ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_DEFECT_STK_QTY')                               --�s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DEFECT_STK_QTY')                                --�s�Ǎ݌ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_QTY')                              --�s�Ǖԕi���ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_QTY')                              --�s�Ǖԕi���ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_QTY')                               --�s�Ǖԕi���ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_QTY')                            --�s�Ǖԕi���ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_QTY')                            --�s�Ǖԕi���ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_QTY')                             --�s�Ǖԕi���ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_RCPT')                             --�s�Ǖԕi����i�����A�o���j
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_RCPT')                             --�s�Ǖԕi����i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_RCPT')                              --�s�Ǖԕi����i�����A���v�j
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_RCPT')                           --�s�Ǖԕi����i�����A�o���j
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_RCPT')                           --�s�Ǖԕi����i�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_RCPT')                            --�s�Ǖԕi����i�����A���v�j
       ,l_data_tab('DAY_INDV_DEFECT_RETURN_SEND')                             --�s�Ǖԕi�����i�����A�o���j
       ,l_data_tab('DAY_CASE_DEFECT_RETURN_SEND')                             --�s�Ǖԕi�����i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DEFECT_RETURN_SEND')                              --�s�Ǖԕi�����i�����A���v�j
       ,l_data_tab('MONTH_INDV_DEFECT_RETURN_SEND')                           --�s�Ǖԕi�����i�����A�o���j
       ,l_data_tab('MONTH_CASE_DEFECT_RETURN_SEND')                           --�s�Ǖԕi�����i�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DEFECT_RETURN_SEND')                            --�s�Ǖԕi�����i�����A���v�j
       ,l_data_tab('DAY_INDV_QUALITY_RETURN_RCPT')                            --�Ǖi�ԕi����i�����A�o���j
       ,l_data_tab('DAY_CASE_QUALITY_RETURN_RCPT')                            --�Ǖi�ԕi����i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_QUALITY_RETURN_RCPT')                             --�Ǖi�ԕi����i�����A���v�j
       ,l_data_tab('MONTH_INDV_QUALITY_RETURN_RCPT')                          --�Ǖi�ԕi����i�����A�o���j
       ,l_data_tab('MONTH_CASE_QUALITY_RETURN_RCPT')                          --�Ǖi�ԕi����i�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_QUALITY_RETURN_RCPT')                           --�Ǖi�ԕi����i�����A���v�j
       ,l_data_tab('DAY_INDV_QUALITY_RETURN_SEND')                            --�Ǖi�ԕi�����i�����A�o���j
       ,l_data_tab('DAY_CASE_QUALITY_RETURN_SEND')                            --�Ǖi�ԕi�����i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_QUALITY_RETURN_SEND')                             --�Ǖi�ԕi�����i�����A���v�j
       ,l_data_tab('MONTH_INDV_QUALITY_RETURN_SEND')                          --�Ǖi�ԕi�����i�����A�o���j
       ,l_data_tab('MONTH_CASE_QUALITY_RETURN_SEND')                          --�Ǖi�ԕi�����i�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_QUALITY_RETURN_SEND')                           --�Ǖi�ԕi�����i�����A���v�j
       ,l_data_tab('DAY_INDV_INVENT_DIFFERENCE')                              --�I�����فi�����A�o���j
       ,l_data_tab('DAY_CASE_INVENT_DIFFERENCE')                              --�I�����فi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_INVENT_DIFFERENCE')                               --�I�����فi�����A���v�j
       ,l_data_tab('MONTH_INDV_INVENT_DIFFERENCE')                            --�I�����فi�����A�o���j
       ,l_data_tab('MONTH_CASE_INVENT_DIFFERENCE')                            --�I�����فi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_INVENT_DIFFERENCE')                             --�I�����فi�����A���v�j
       ,l_data_tab('DAY_INDV_STK_QTY')                                        --�݌ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_STK_QTY')                                        --�݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_STK_QTY')                                         --�݌ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_STK_QTY')                                      --�݌ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_STK_QTY')                                      --�݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_STK_QTY')                                       --�݌ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_RESERVED_STK_QTY')                               --�ۗ��݌ɐ��i�����A�o���j
       ,l_data_tab('DAY_CASE_RESERVED_STK_QTY')                               --�ۗ��݌ɐ��i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_RESERVED_STK_QTY')                                --�ۗ��݌ɐ��i�����A���v�j
       ,l_data_tab('MONTH_INDV_RESERVED_STK_QTY')                             --�ۗ��݌ɐ��i�����A�o���j
       ,l_data_tab('MONTH_CASE_RESERVED_STK_QTY')                             --�ۗ��݌ɐ��i�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_RESERVED_STK_QTY')                              --�ۗ��݌ɐ��i�����A���v�j
       ,l_data_tab('DAY_INDV_CD_STK_QTY')                                     --�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_CD_STK_QTY')                                     --�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_CD_STK_QTY')                                      --�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_CD_STK_QTY')                                   --�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_CD_STK_QTY')                                   --�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_CD_STK_QTY')                                    --�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_CARGO_STK_QTY')                                  --�ϑ��݌ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_CARGO_STK_QTY')                                  --�ϑ��݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_CARGO_STK_QTY')                                   --�ϑ��݌ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_CARGO_STK_QTY')                                --�ϑ��݌ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_CARGO_STK_QTY')                                --�ϑ��݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_CARGO_STK_QTY')                                 --�ϑ��݌ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_ADJUSTMENT_STK_QTY')                             --�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_ADJUSTMENT_STK_QTY')                             --�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_ADJUSTMENT_STK_QTY')                              --�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_ADJUSTMENT_STK_QTY')                           --�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_ADJUSTMENT_STK_QTY')                           --�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_ADJUSTMENT_STK_QTY')                            --�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_STILL_SHIPPING_QTY')                             --���o�א��ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_STILL_SHIPPING_QTY')                             --���o�א��ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_STILL_SHIPPING_QTY')                              --���o�א��ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_STILL_SHIPPING_QTY')                           --���o�א��ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_STILL_SHIPPING_QTY')                           --���o�א��ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_STILL_SHIPPING_QTY')                            --���o�א��ʁi�����A���v�j
       ,l_data_tab('INDV_ALL_STK_QTY')                                        --���݌ɐ��ʁi�o���j
       ,l_data_tab('CASE_ALL_STK_QTY')                                        --���݌ɐ��ʁi�P�[�X�j
       ,l_data_tab('SUM_ALL_STK_QTY')                                         --���݌ɐ��ʁi���v�j
       ,l_data_tab('MONTH_DRAW_COUNT')                                        --����������
       ,l_data_tab('DAY_INDV_DRAW_POSSIBLE_QTY')                              --�����\���ʁi�����A�o���j
       ,l_data_tab('DAY_CASE_DRAW_POSSIBLE_QTY')                              --�����\���ʁi�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DRAW_POSSIBLE_QTY')                               --�����\���ʁi�����A���v�j
       ,l_data_tab('MONTH_INDV_DRAW_POSSIBLE_QTY')                            --�����\���ʁi�����A�o���j
       ,l_data_tab('MONTH_CASE_DRAW_POSSIBLE_QTY')                            --�����\���ʁi�����A�P�[�X�j
       ,l_data_tab('MONTH_SUM_DRAW_POSSIBLE_QTY')                             --�����\���ʁi�����A���v�j
       ,l_data_tab('DAY_INDV_DRAW_IMPOSSIBLE_QTY')                            --�����s�\���i�����A�o���j
       ,l_data_tab('DAY_CASE_DRAW_IMPOSSIBLE_QTY')                            --�����s�\���i�����A�P�[�X�j
       ,l_data_tab('DAY_SUM_DRAW_IMPOSSIBLE_QTY')                             --�����s�\���i�����A���v�j
       ,l_data_tab('DAY_STK_AMT')                                             --�݌ɋ��z�i�����j
       ,l_data_tab('MONTH_STK_AMT')                                           --�݌ɋ��z�i�����j
       ,l_data_tab('REMARKS')                                                 --���l
       ,l_data_tab('CHAIN_PECULIAR_AREA_LINE')                                --�`�F�[���X�ŗL�G���A�i���ׁj
            ------------------------------------------------�t�b�^���------------------------------------------------
       ,l_data_tab('INVOICE_DAY_INDV_SUM_STK_QTY')                            --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
       ,l_data_tab('INVOICE_DAY_CASE_SUM_STK_QTY')                            --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
       ,l_data_tab('INVOICE_DAY_SUM_SUM_STK_QTY')                             --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
       ,l_data_tab('INVOICE_MONTH_INDV_SUM_STK_QTY')                          --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
       ,l_data_tab('INVOICE_MONTH_CASE_SUM_STK_QTY')                          --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
       ,l_data_tab('INVOICE_MONTH_SUM_SUM_STK_QTY')                           --�i�`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
       ,l_data_tab('INVOICE_DAY_INDV_CD_STK_QTY')                             --�i�`�[�v�j�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('INVOICE_DAY_CASE_CD_STK_QTY')                             --�i�`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('INVOICE_DAY_SUM_CD_STK_QTY')                              --�i�`�[�v�j�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('INVOICE_MONTH_INDV_CD_STK_QTY')                           --�i�`�[�v�j�����݌ɐ��ʁi�����A�o���j
       ,l_data_tab('INVOICE_MONTH_CASE_CD_STK_QTY')                           --�i�`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
       ,l_data_tab('INVOICE_MONTH_SUM_CD_STK_QTY')                            --�i�`�[�v�j�����݌ɐ��ʁi�����A���v�j
       ,l_data_tab('INVOICE_DAY_STK_AMT')                                     --�i�`�[�v�j�݌ɋ��z�i�����j
       ,l_data_tab('INVOICE_MONTH_STK_AMT')                                   --�i�`�[�v�j�݌ɋ��z�i�����j
       ,l_data_tab('REGULAR_SELL_AMT_SUM')                                    --���̋��z���v
       ,l_data_tab('REBATE_AMT_SUM')                                          --���߂����z���v
       ,l_data_tab('COLLECT_BOTTLE_AMT_SUM')                                  --����e����z���v
       ,l_data_tab('CHAIN_PECULIAR_AREA_FOOTER')                              --�`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
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
      --==============================================================
      --�f�[�^���R�[�h�쐬����
      --==============================================================
      proc_out_data_record(
                   l_data_tab
                  ,lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                           );
     IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--      RAISE global_process_expt;
       RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
     END IF;
--
    END LOOP data_record_loop;
--
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
    --�Ώۃf�[�^������
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => cv_msg_nodata
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
--
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
--
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
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode     := lv_retcode;
    out_line(buff   => cv_prg_name || ' end');
--
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
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name                IN     VARCHAR2,  --  1.�t�@�C����
    iv_chain_code               IN     VARCHAR2,  --  2.�`�F�[���X�R�[�h
    iv_report_code              IN     VARCHAR2,  --  3.���[�R�[�h
    in_user_id                  IN     NUMBER,    --  4.���[�UID
    iv_chain_name               IN     VARCHAR2,  --  5.�`�F�[���X��
    iv_store_code               IN     VARCHAR2,  --  6.�X�܃R�[�h
    iv_base_code                IN     VARCHAR2,  --  7.���_�R�[�h
    iv_base_name                IN     VARCHAR2,  --  8.���_��
    iv_data_type_code           IN     VARCHAR2,  --  9.���[��ʃR�[�h
    iv_ebs_business_series_code IN     VARCHAR2,  -- 10.�Ɩ��n��R�[�h
    iv_info_class               IN     VARCHAR2,  -- 11.���敪
    iv_report_name              IN     VARCHAR2,  -- 12.���[�l��
    iv_edi_date_from            IN     VARCHAR2,  -- 13.EDI�捞��(FROM)
    iv_edi_date_to              IN     VARCHAR2,  -- 14.EDI�捞��(TO)
    iv_item_class               IN     VARCHAR2   -- 15.���i�敪
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out         CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log         CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
    l_input_rec.user_id                  := in_user_id;                       --  1.���[�UID
    l_input_rec.chain_code               := iv_chain_code;                    --  2.�`�F�[���X�R�[�h
    l_input_rec.chain_name               := iv_chain_name;                    --  3.�`�F�[���X��
    l_input_rec.store_code               := iv_store_code;                    --  4.�X�܃R�[�h
    l_input_rec.base_code                := iv_base_code;                     --  5.���_�R�[�h
    l_input_rec.base_name                := iv_base_name;                     --  6.���_��
    l_input_rec.file_name                := iv_file_name;                     --  7.�t�@�C����
    l_input_rec.data_type_code           := iv_data_type_code;                --  8.���[��ʃR�[�h
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;      --  9.�Ɩ��n��R�[�h
    l_input_rec.info_class               := iv_info_class;                    -- 10.���敪
    l_input_rec.report_code              := iv_report_code;                   -- 11.���[�R�[�h
    l_input_rec.report_name              := iv_report_name;                   -- 12.���[�l��
    l_input_rec.item_class               := iv_item_class;                    -- 13.���i�敪
    l_input_rec.edi_date_from            := iv_edi_date_from;                 -- 14.EDI�捞��(FROM)
    l_input_rec.edi_date_to              := iv_edi_date_to;                   -- 15.EDI�捞��(TO)
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
                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
END XXCOS014A05C;
/
