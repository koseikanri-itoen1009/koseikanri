CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A05R(body)
 * Description      : �󒍃G���[���X�g
 * MD.050           : �󒍃G���[���X�g MD050_COS_010_A05
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_parameter          �p�����[�^�`�F�b�N����(A-2)
 *  get_data               �f�[�^�擾(A-3)
 *  insert_report_work     ���[���[�N�e�[�u���f�[�^�o�^(A-4)
 *  delete_edi             EDI�e�[�u���f�[�^�폜(A-5)
 *  execute_svf            SVF�N��(A-6)
 *  delete_report_work     ���[���[�N�e�[�u���f�[�^�폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   K.Kumamoto       �V�K�쐬
 *  2009/02/13    1.1   M.Yamaki         [COS_072]�G���[���X�g��ʃR�[�h�̑Ή�
 *  2009/02/24    1.2   T.Nakamura       [COS_133]���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/06/19    1.3   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/23    1.4   N.Maeda          [0000300]���b�N�����C��
 *  2009/08/03    1.5   M.Sano           [0000902]�󒍃G���[���X�g�̏I���X�e�[�^�X�ύX
 *  2009/09/29    1.6   N.Maeda          [0001338]�v���V�[�W��execute_svf�̓Ɨ��g�����U�N�V������
 *  2010/01/19    1.7   M.Sano           [E_�{�ғ�_01159]
 *                                       �E���̓p�����[�^�̒ǉ�
 *                                         (���s�敪����_��`�F�[���X�EDI��M��(FROM)�EDI��M��(TO))
 *                                       �E�Ĕ��s�̉\��
 *                                       �E�o�͑Ώۂ̃G���[���𐧌䂷��@�\�̒ǉ�
 *                                       �E�`�[�P�ʂ�EDI���[�N�����폜�ł���@�\�̒ǉ�
 *  2012/08/02    1.8   T.Osawa          [E_�{�ғ�_09864]�󒍃G���[���X�g�̃J�i�X�ܖ��̕\��
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
  update_expt               EXCEPTION; --�X�V�G���[
  delete_expt               EXCEPTION; --�폜�G���[
  execute_svf_expt          EXCEPTION; --SVF�N���G���[
  resource_busy_expt        EXCEPTION;     --���b�N�G���[
-- 2010/01/19 M.Sano Ver.1.7 add start
  profile_expt              EXCEPTION; --�v���t�@�C���G���[
-- 2010/01/19 M.Sano Ver.1.7 add end
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS010A05R';                          --�p�b�P�[�W��
  ct_apl_name                     CONSTANT fnd_application.application_short_name%TYPE := 'XXCOS';   --�A�v���P�[�V�����Z�k��
  cv_fmt_date                     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                            --���t����
  cv_fmt_date8                    CONSTANT VARCHAR2(8) := 'YYYYMMDD';                                --���t����(�t�@�C�����p)
--
  --���b�Z�[�W
  ct_msg_err_list_err             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12101'; --�G���[���X�g��ʃG���[
  ct_msg_parameters               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12102'; --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064'; --�擾�G���[
  ct_msg_work_tab_name            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12103'; --������.�󒍃G���[���X�g���[���[�N�e�[�u��
  ct_msg_insert_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010'; --�f�[�^�o�^�G���[
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011'; --�f�[�^�X�V�G���[
  ct_msg_delete_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; --�f�[�^�폜�G���[
  ct_msg_order_work_tab           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00113'; --EDI�󒍏�񃏁[�N�e�[�u��
  ct_msg_dlv_rtn_work_tab         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00117'; --EDI�[�i�ԕi��񃏁[�N�e�[�u��
  ct_msg_edi_err_tab              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00116'; --EDI�G���[���e�[�u��
  ct_msg_request_id               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00088'; --������.�v��ID
  ct_msg_api_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00017'; --API�ďo�G���[���b�Z�[�W
  ct_msg_svf_api                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00041'; --������.SVF�N��API
  ct_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00018'; --����0���p���b�Z�[�W
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; --���b�N�G���[���b�Z�[�W
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
  ct_msg_Processed_other          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12104'; --�������o�͍ς݃��b�Z�[�W
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
-- 2010/01/19 M.Sano Ver.1.7 add start
  cv_msg_profile                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  ct_msg_biz_man_dept_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12105'; --EDI�G���[���X�g�p�Ɩ��Ǘ����R�[�h
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --�g�[�N��
  cv_tkn_param1                   CONSTANT VARCHAR2(6) := 'PARAM1';
-- 2010/01/19 M.Sano Ver.1.7 add start
  cv_tkn_param2                   CONSTANT VARCHAR2(6) := 'PARAM2';
  cv_tkn_param3                   CONSTANT VARCHAR2(6) := 'PARAM3';
  cv_tkn_param4                   CONSTANT VARCHAR2(6) := 'PARAM4';
  cv_tkn_param5                   CONSTANT VARCHAR2(6) := 'PARAM5';
  cv_tkn_param6                   CONSTANT VARCHAR2(6) := 'PARAM6';
  cv_tkn_profile                  CONSTANT VARCHAR2(7) := 'PROFILE';                                 --�g�[�N��.�v���t�@�C��
-- 2010/01/19 M.Sano Ver.1.7 add end
  cv_tkn_data                     CONSTANT VARCHAR2(4) := 'DATA';                                    --�g�[�N��.�f�[�^
  cv_tkn_table_name               CONSTANT VARCHAR2(10) := 'TABLE_NAME';                             --�g�[�N��.�e�[�u����
  cv_tkn_table                    CONSTANT VARCHAR2(10) := 'TABLE';                                  --�g�[�N��.�e�[�u����
  cv_tkn_key                      CONSTANT VARCHAR2(8) := 'KEY_DATA';                                --�g�[�N��.�L�[���
  cv_tkn_api_name                 CONSTANT VARCHAR2(8) := 'API_NAME';                                --�g�[�N��API��
--
  --�N�C�b�N�R�[�h
  ct_qc_err_list_type             CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_EDI_CREATE_CLASS';  --�Q�ƃ^�C�v.EDI�쐬���敪
-- 2010/01/19 M.Sano Ver.1.7 add start
  ct_order_err_list_message       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_ORDER_ERR_LIST_MESSAGE';
                                                                                           --�Q�ƃ^�C�v.�󒍃G���[���X�g�o�̓��b�Z�[�W
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --�v���t�@�C��
  ct_prf_organization_code CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE'; --�݌ɑg�D�R�[�h
-- 2010/01/19 M.Sano Ver.1.7 add start
  ct_prf_biz_man_dept_code CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_ERR_BIZ_MAN_DEPT_CODE'; --EDI�G���[���X�g�p�Ɩ��Ǘ����R�[�h
-- 2010/01/19 M.Sano Ver.1.7 add end
--
  --SVF�֘A
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS010A05R';          -- �R���J�����g��
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS010A05R';          -- ���[�h�c
  cv_extension              CONSTANT VARCHAR2(100) := '.pdf';                  -- �g���q�i�o�c�e�j
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS010A05S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS010A05S.vrq';      -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- �o�͋敪�i�o�c�e�j
--
  --�ڋq�敪
  cv_cust_class_chain       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '18';
  cv_cust_class_store       CONSTANT hz_cust_accounts.customer_class_code%TYPE := '10';
  cv_cust_class_base        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '1';
--
-- 2010/01/19 M.Sano Ver.1.7 add start
  --�Ĕ��s�敪
  cv_exec_type_new          CONSTANT VARCHAR2(1)   := '0';              -- �Ĕ��s�敪�u�V�K�v
--
  --����R�[�h
  cv_default_language       CONSTANT VARCHAR2(10)  := USERENV('LANG');  -- �W������^�C�v
--
  --�t���O
  cv_enabled_flag_yes       CONSTANT VARCHAR2(1)   := 'Y';              -- �L���t���O�u�L���v
  cv_output_flag_yes        CONSTANT VARCHAR2(1)   := 'Y';              -- �Q�ƃ^�C�v.����1�`3(�o�̓t���O)�F�o�͑Ώ�
  cv_err_list_out_flag_yes  CONSTANT VARCHAR2(1)   := 'Y';              -- �G���[���X�g�o�͍σt���O:Yes
  cv_err_list_out_flag_no0  CONSTANT VARCHAR2(2)   := 'N0';             -- �G���[���X�g�o�͍σt���O:No(�V�K)
  cv_attribute4_d_line      CONSTANT VARCHAR2(1)   := '1';              -- ���[�N�e�[�u���폜�敪:�Y���s
  cv_attribute4_d_head      CONSTANT VARCHAR2(1)   := '2';              -- ���[�N�e�[�u���폜�敪:�`�[�P��
--
  --���݃`�F�b�N�o�͗p
  cv_exists_flag            CONSTANT VARCHAR2(1)   := 'Y';
-- 2010/01/19 M.Sano Ver.1.7 add end
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^���
  TYPE g_input_rtype IS RECORD (
    err_list_type        VARCHAR2(100) --�G���[���X�g���
   ,err_list_type_name   fnd_lookup_values.description%TYPE --�G���[���X�g��ʖ�
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,request_type           VARCHAR2(100) --�Ĕ��s�敪
   ,base_code              VARCHAR2(100) --���_�R�[�h
   ,edi_chain_code         VARCHAR2(100) --EDI�`�F�[���X�R�[�h
   ,edi_received_date_from DATE          --EDI��M��(FROM)
   ,edi_received_date_to   DATE          --EDI��M��(TO)
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --�v���t�@�C�����
  TYPE g_prf_rtype IS RECORD (
    organization_code    fnd_profile_option_values.profile_option_value%TYPE --�݌ɑg�D�R�[�h
   ,organization_id      NUMBER --�݌ɑg�DID
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,biz_man_dept_code    fnd_profile_option_values.profile_option_value%TYPE --�Ɩ��Ǘ����R�[�h
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --EDI�G���[���i�[���R�[�h
  TYPE g_edi_err_rtype IS RECORD (
    base_code            hz_cust_accounts.account_number%TYPE     --���_�R�[�h
   ,base_name            hz_parties.party_name%TYPE               --���_����
   ,edi_create_class     xxcos_edi_errors.edi_create_class%TYPE   --EDI�쐬���敪
   ,chain_code           xxcos_edi_errors.chain_code%TYPE         --�`�F�[���X�R�[�h
   ,chain_name           hz_parties.party_name%TYPE               --�`�F�[���X����
   ,dlv_date             VARCHAR2(10)                             --�[�i��
   ,invoice_number       xxcos_edi_errors.invoice_number%TYPE     --�`�[�ԍ�
   ,shop_code            xxcos_edi_errors.shop_code%TYPE          --�X�܃R�[�h
   ,customer_number      hz_cust_accounts.account_number%TYPE     --�ڋq�R�[�h
   ,shop_name            xxcmm_cust_accounts.cust_store_name%TYPE --�X�ܖ���
-- 2012/08/02 T.Osawa Ver.1.8 add start
   ,shop_name_alt        xxcos_edi_errors.shop_name_alt%TYPE      --�X�ܖ��́i�J�i�j
-- 2012/08/02 T.Osawa Ver.1.8 add end
   ,line_no              xxcos_edi_errors.line_no%TYPE            --�sNo
   ,item_code            xxcos_edi_errors.item_code%TYPE          --�i�ڃR�[�h
   ,edi_item_code        xxcos_edi_errors.edi_item_code%TYPE      --EDI���i�R�[�h
-- 2010/01/19 M.Sano Ver.1.7 mod start
--   ,item_name            xxcmn_item_mst_b.item_short_name%TYPE    --�i�ږ���
   ,item_name            xxcos_edi_errors.edi_item_name%TYPE      --�i�ږ���
-- 2010/01/19 M.Sano Ver.1.7 mod end
   ,quantity             xxcos_edi_errors.quantity%TYPE           --�{��
   ,unit_price           xxcos_edi_errors.unit_price%TYPE         --���P��
   ,unit_price_amount    NUMBER                                   --�������z
   ,err_message          xxcos_edi_errors.err_message%TYPE        --�G���[���e
   ,edi_err_id           xxcos_edi_errors.edi_err_id%TYPE         --EDI�G���[ID
   ,delete_flag          xxcos_edi_errors.delete_flag%TYPE        --�폜�t���O
   ,work_id              xxcos_edi_errors.work_id%TYPE            --���[�NID
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,output_flag          fnd_lookup_values.attribute3%TYPE        --�o�̓t���O
-- 2010/01/19 M.Sano Ver.1.7 add end
  );
--
  --EDI�G���[���i�[�e�[�u��
  TYPE g_edi_err_ttype IS TABLE OF g_edi_err_rtype INDEX BY BINARY_INTEGER;
--
  --�󒍃G���[���X�g�o�^�p�e�[�u��
  TYPE g_work_ttype IS TABLE OF xxcos_rep_order_err_list%rowtype INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_input_rec           g_input_rtype; 
  g_input_rec_init      g_input_rtype;
  g_edi_err_tab         g_edi_err_ttype;
  g_process_date        DATE;
-- 2010/01/19 M.Sano Ver.1.7 add start
  g_profile_rec         g_prf_rtype;
-- 2010/01/19 M.Sano Ver.1.7 add end
-- ****************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
  gn_lock_flg           NUMBER := 0;                     -- ���b�N�t���O
-- ****************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ���O�o��
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lb_fnd_file boolean := true;
    lb_out boolean := false;
  BEGIN
    IF (lb_out) THEN
      IF (lb_fnd_file) THEN
        FND_FILE.PUT_LINE(
           which  => which
          ,buff   => buff
        );
      ELSE
        dbms_output.put_line(buff);
      END IF;
    END IF;
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --���b�Z�[�W�p������
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    --���̓p�����[�^�̏o��
    --==============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => ct_apl_name
                  ,iv_name               => ct_msg_parameters
                  ,iv_token_name1        => cv_tkn_param1
                  ,iv_token_value1       => g_input_rec.err_list_type
-- 2010/01/19 M.Sano Ver.1.7 add start
                  ,iv_token_name2        => cv_tkn_param2
                  ,iv_token_value2       => g_input_rec.request_type
                  ,iv_token_name3        => cv_tkn_param3
                  ,iv_token_value3       => g_input_rec.base_code
                  ,iv_token_name4        => cv_tkn_param4
                  ,iv_token_value4       => g_input_rec.edi_chain_code
                  ,iv_token_name5        => cv_tkn_param5
                  ,iv_token_value5       => TO_CHAR(g_input_rec.edi_received_date_from, cv_fmt_date)
                  ,iv_token_name6        => cv_tkn_param6
                  ,iv_token_value6       => TO_CHAR(g_input_rec.edi_received_date_to, cv_fmt_date)
-- 2010/01/19 M.Sano Ver.1.7 add end
                 );
--
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1�s��
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==============================================================
    --�Ɩ����t�̎擾
    --==============================================================
    g_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
-- 2010/01/19 M.Sano Ver.1.7 add start
    --==============================================================
    --�v���t�@�C���̎擾(�Ɩ��Ǘ����R�[�h)
    --==============================================================
    g_profile_rec.biz_man_dept_code := FND_PROFILE.VALUE( ct_prf_biz_man_dept_code );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ �� �v���t�@�C���G���[(�Ɩ��Ǘ����R�[�h)
    IF ( g_profile_rec.biz_man_dept_code IS NULL ) THEN
      lt_tkn := xxccp_common_pkg.get_msg( ct_apl_name, ct_msg_biz_man_dept_code );
      RAISE profile_expt;
    END IF;
--
-- 2010/01/19 M.Sano Ver.1.7 add end
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
-- 2010/01/19 M.Sano Ver.1.7 add start
    -- *** �v���t�@�C���擾�G���[�n���h�� ***
    WHEN profile_expt THEN
      -- ���b�Z�[�W���擾
      lv_errmsg := xxccp_common_pkg.get_msg( ct_apl_name, cv_msg_profile, cv_tkn_profile, lt_tkn );
      lv_errbuf := lv_errmsg;
      -- �o�͍��ڂɃZ�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- 2010/01/19 M.Sano Ver.1.7 add end
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
   * Procedure Name   : delete_report_work
   * Description      : ���[���[�N�e�[�u���폜����(A-7)
   ***********************************************************************************/
  PROCEDURE delete_report_work(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_report_work'; -- �v���O������
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
    lv_table_name VARCHAR2(30);
    lv_key_info VARCHAR2(100);
    lv_errbuf_tmp VARCHAR2(5000);
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
    --�󒍃G���[���X�g���[���[�N�e�[�u���폜
    --==============================================================
    BEGIN
      DELETE FROM xxcos_rep_order_err_list xroel
      WHERE xroel.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE delete_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN delete_expt THEN
      --�L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => ct_apl_name
                        ,iv_name          => ct_msg_work_tab_name
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_delete_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END delete_report_work;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
--
-- ********* 2009/09/29 N.Maeda 1.6 ADD START ********* --
    PRAGMA AUTONOMOUS_TRANSACTION; -- �Ɨ��g�����U�N�V����
-- ********* 2009/09/29 N.Maeda 1.6 ADD  END  ********* --
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_file_name VARCHAR2(1000);
    lt_api_name fnd_new_messages.message_text%TYPE;
    lt_msg_nodata fnd_new_messages.message_text%TYPE;
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
    --0�����b�Z�[�W�擾
    --==============================================================
    lt_msg_nodata := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_nodata
                     );
--
    --==============================================================
    --�t�@�C�����擾
    --==============================================================
    lv_file_name := cv_file_id || TO_CHAR(SYSDATE, cv_fmt_date8) || TO_CHAR(cn_request_id) || cv_extension;
--
    --==============================================================
    --���ʊ֐�.SVF�N��API���s
    --==============================================================
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
      iv_nodata_msg           => lt_msg_nodata,
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
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE execute_svf_expt;
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN execute_svf_expt THEN
      ROLLBACK;
      --API���擾
      lt_api_name := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_svf_api
                     );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_api_err
                    ,cv_tkn_api_name
                    ,lt_api_name
                   );
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_edi
   * Description      : EDI�e�[�u���폜����(A-5)
   ***********************************************************************************/
  PROCEDURE delete_edi(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_edi'; -- �v���O������
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
    cv_delete VARCHAR2(1) := 'Y';
    cv_order VARCHAR2(2) := '01';
    cv_dlv_rtn VARCHAR2(2) := '02';
--
    -- *** ���[�J���ϐ� ***
    lv_table_name VARCHAR2(30);
    lv_key_info VARCHAR2(100);
    lv_errbuf_tmp VARCHAR2(5000);
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
    --EDI�G���[�e�[�u���̃G���[���X�g�o�͍σt���O�̍X�V
    --==============================================================
    BEGIN
      FOR i IN 1..g_edi_err_tab.COUNT LOOP
-- 2010/01/19 M.Sano Ver.1.7 mod start
--        UPDATE xxcos_edi_errors SET request_id = cn_request_id
--        WHERE edi_err_id = g_edi_err_tab(i).edi_err_id;
        -- �G���[���X�g�o�͍σt���O���uY�v�ȊO�̏ꍇ�A�t���O���X�V�B
        UPDATE xxcos_edi_errors
        SET    err_list_out_flag       = cv_err_list_out_flag_yes,   -- �󒍃G���[���X�g�o�͍σt���O
               last_updated_by         = cn_last_updated_by,         -- �ŏI�X�V��
               last_update_date        = cd_last_update_date,        -- �ŏI�X�V��
               last_update_login       = cn_last_update_login,       -- �ŏI�X�V���O�C��
               request_id              = cn_request_id,              -- �v��ID
               program_application_id  = cn_program_application_id,  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               program_id              = cn_program_id,              -- �R���J�����g�E�v���O����ID
               program_update_date     = cd_program_update_date      -- �v���O�����X�V��
        WHERE  edi_err_id              = g_edi_err_tab(i).edi_err_id
        AND  (  err_list_out_flag     <> cv_err_list_out_flag_yes
             OR err_list_out_flag     IS NULL );
-- 2010/01/19 M.Sano Ver.1.7 mod end
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        --�e�[�u�����擾
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application   => ct_apl_name
                          ,iv_name          => ct_msg_edi_err_tab
                         );
        RAISE update_expt;
    END;
--
    --==============================================================
    --EDI�󒍏�񃏁[�N�e�[�u���EEDI�[�i�ԕi��񃏁[�N�e�[�u���̍폜
    --==============================================================
    IF (g_input_rec.err_list_type = cv_order) THEN
--
      BEGIN
        --EDI�󒍏�񃏁[�N�e�[�u���̍폜
        DELETE FROM xxcos_edi_order_work xeow
        WHERE xeow.order_info_work_id IN (
          SELECT xee.work_id
          FROM   xxcos_edi_errors xee
-- 2010/01/19 M.Sano Ver.1.7 add start
               , fnd_lookup_values    flv
-- 2010/01/19 M.Sano Ver.1.7 add end
          WHERE  xee.request_id = cn_request_id
          AND    xee.delete_flag = cv_delete
-- 2010/01/19 M.Sano Ver.1.7 add start
          -- [�N�C�b�N�R�[�h]����
          AND    flv.meaning               = xee.err_message_code                   -- ���b�Z�[�W�R�[�h���T�v�Ɠ���
          AND    flv.lookup_type           = ct_order_err_list_message              -- �^�C�v:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_line                   -- ���[�N�e�[�u���폜�敪�F�Y���s
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
         UNION ALL
          SELECT xeow_d.order_info_work_id
          FROM   xxcos_edi_errors     xee
               , fnd_lookup_values    flv
               , xxcos_edi_order_work xeow_e
               , xxcos_edi_order_work xeow_d
          WHERE  xee.request_id            = cn_request_id                          -- �{�R���J�����g�ōX�V�����v��
          AND    xee.delete_flag           = cv_delete                              -- �폜�Ώ�
          -- [�N�C�b�N�R�[�h]����
          AND    flv.meaning               = xee.err_message_code                   -- ���b�Z�[�W�R�[�h���T�v�Ɠ���
          AND    flv.lookup_type           = ct_order_err_list_message              -- �^�C�v:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_head                   -- ���[�N�e�[�u���폜�敪�F�`�[�P��
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
          -- [EDI���[�NTBL_EDI�G���[���ɕR�t�����R�[�h]����
          AND    xeow_e.order_info_work_id = xee.work_id                            -- ���[�NTBLID
          -- [EDI���[�NTBL_�폜�Ώ�]����
          AND    xeow_d.if_file_name       = xeow_e.if_file_name                    -- IF�t�@�C����������
          AND    TRUNC(xeow_d.creation_date)
                                           = TRUNC(xeow_e.creation_date)            -- �쐬��������
          AND    xeow_d.edi_chain_code     = xeow_e.edi_chain_code                  -- �ڋq������
          AND  (   (  xeow_d.shop_code     = xeow_e.shop_code )
                OR (  xeow_d.shop_code IS NULL AND xeow_e.shop_code IS NULL ))      -- �X�R�[�h������
          AND  (   (  xeow_d.shop_delivery_date = xeow_e.shop_delivery_date )
                OR (  xeow_d.shop_delivery_date IS NULL
                    AND
                      xeow_e.shop_delivery_date IS NULL ) )                         -- �X�ܔ[�i��������
          AND    xeow_d.invoice_number     = xeow_e.invoice_number                  -- �`�[�ԍ�������
-- 2010/01/19 M.Sano Ver.1.7 add end
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          --�e�[�u�����擾
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application   => ct_apl_name
                            ,iv_name          => ct_msg_order_work_tab
                           );
          RAISE delete_expt;
      END;
--
    ELSIF (g_input_rec.err_list_type = cv_dlv_rtn) THEN
--
      BEGIN
        --EDI�[�i�ԕi��񃏁[�N�e�[�u���̍폜
        DELETE FROM xxcos_edi_delivery_work xedw
        WHERE xedw.delivery_return_work_id IN (
          SELECT xee.work_id
          FROM   xxcos_edi_errors xee
-- 2010/01/19 M.Sano Ver.1.7 add start
               , fnd_lookup_values    flv
-- 2010/01/19 M.Sano Ver.1.7 add end
          WHERE  xee.request_id = cn_request_id
          AND    xee.delete_flag = cv_delete
-- 2010/01/19 M.Sano Ver.1.7 add start
          -- [�N�C�b�N�R�[�h]����
          AND    flv.meaning               = xee.err_message_code                   -- ���b�Z�[�W�R�[�h���T�v�Ɠ���
          AND    flv.lookup_type           = ct_order_err_list_message              -- �^�C�v:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_line                   -- ���[�N�e�[�u���폜�敪�F�Y���s
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
         UNION ALL
          SELECT xeow_d.delivery_return_work_id
          FROM   xxcos_edi_errors        xee
               , fnd_lookup_values       flv
               , xxcos_edi_delivery_work xeow_e
               , xxcos_edi_delivery_work xeow_d
          WHERE  xee.request_id            = cn_request_id                          -- �{�R���J�����g�ōX�V�����v��
          AND    xee.delete_flag           = cv_delete                              -- �폜�Ώ�
          -- [�N�C�b�N�R�[�h]����
          AND    flv.meaning               = xee.err_message_code                   -- ���b�Z�[�W�R�[�h���T�v�Ɠ���
          AND    flv.lookup_type           = ct_order_err_list_message              -- �^�C�v:XXCOS1_ORDER_ERR_LIST_MESSAGE
          AND    flv.attribute4            = cv_attribute4_d_head                   -- ���[�N�e�[�u���폜�敪�F�`�[�P��
          AND    flv.enabled_flag          = cv_enabled_flag_yes
          AND    flv.language              = cv_default_language
          AND    g_process_date           >= NVL(flv.start_date_active, g_process_date)
          AND    g_process_date           <= NVL(flv.end_date_active,   g_process_date)
          -- [EDI���[�NTBL_EDI�G���[���ɕR�t�����R�[�h]����
          AND    xeow_e.delivery_return_work_id = xee.work_id                            -- ���[�NTBLID
          -- [EDI���[�NTBL_�폜�Ώ�]����
          AND    xeow_d.if_file_name       = xeow_e.if_file_name                    -- IF�t�@�C����������
          AND    TRUNC(xeow_d.creation_date)
                                           = TRUNC(xeow_e.creation_date)            -- �쐬��������
          AND    xeow_d.edi_chain_code     = xeow_e.edi_chain_code                  -- �ڋq������
          AND  (   (  xeow_d.shop_code     = xeow_e.shop_code )
                OR (  xeow_d.shop_code IS NULL AND xeow_e.shop_code IS NULL ))      -- �X�R�[�h������
          AND  (   (  xeow_d.shop_delivery_date = xeow_e.shop_delivery_date )
                OR (  xeow_d.shop_delivery_date IS NULL
                    AND
                      xeow_e.shop_delivery_date IS NULL ) )                         -- �X�ܔ[�i��������
          AND    xeow_d.invoice_number     = xeow_e.invoice_number                  -- �`�[�ԍ�������
-- 2010/01/19 M.Sano Ver.1.7 add end
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          --�e�[�u�����擾
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application   => ct_apl_name
                            ,iv_name          => ct_msg_dlv_rtn_work_tab
                           );
          RAISE delete_expt;
      END;
    END IF;
--
-- 2010/01/19 M.Sano Ver.1.7 del start
--    --==============================================================
--    --EDI�G���[���e�[�u���̍폜
--    --==============================================================
----
--    BEGIN
--      --EDI�G���[���e�[�u���̍폜
--      DELETE FROM xxcos_edi_errors xee
--      WHERE xee.request_id = cn_request_id
--      ;
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errbuf := SQLERRM;
--        --�e�[�u�����擾
--        lv_table_name := xxccp_common_pkg.get_msg(
--                           iv_application   => ct_apl_name
--                          ,iv_name          => ct_msg_edi_err_tab
--                         );
----
--        RAISE delete_expt;
--    END;
-- 2010/01/19 M.Sano Ver.1.7 del end
--
    out_line(buff => cv_prg_name || ' end');
--
  EXCEPTION
    WHEN update_expt THEN
      --�L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_update_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN delete_expt THEN
      --�L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf_tmp            --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => ct_msg_request_id
       ,iv_data_value1 => cn_request_id
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     ct_apl_name
                    ,ct_msg_delete_err
                    ,cv_tkn_table_name
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END delete_edi;
--
  /**********************************************************************************
   * Procedure Name   : insert_report_work
   * Description      : ���[���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE insert_report_work(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
-- ********* 2009/09/29 N.Maeda 1.6 DEL START ********* --
--    PRAGMA AUTONOMOUS_TRANSACTION;
-- ********* 2009/09/29 N.Maeda 1.6 DEL  END  ********* --
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_report_work'; -- �v���O������
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
    lv_table VARCHAR2(100);
-- 2010/01/19 M.Sano Ver.1.7 add start
    lv_work_idx    NUMBER   := 0;
-- 2010/01/19 M.Sano Ver.1.7 add end
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_work_tab g_work_ttype;
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
    --���[���[�N�e�[�u���̓o�^
    --==============================================================
    FOR i IN 1..g_edi_err_tab.COUNT LOOP
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      SELECT xxcos_rep_order_err_list_s01.NEXTVAL INTO l_work_tab(i).record_id FROM DUAL;
--      l_work_tab(i).base_code                   := SUBSTRB(g_edi_err_tab(i).base_code,1,4);
--      l_work_tab(i).base_name                   := SUBSTRB(g_edi_err_tab(i).base_name,1,20);
--      l_work_tab(i).edi_create_class            := SUBSTRB(g_edi_err_tab(i).edi_create_class,1,1);
--      l_work_tab(i).edi_create_class_name       := SUBSTRB(g_input_rec.err_list_type_name,1,14);
--      l_work_tab(i).chain_code                  := SUBSTRB(g_edi_err_tab(i).chain_code,1,4);
--      l_work_tab(i).chain_name                  := SUBSTRB(g_edi_err_tab(i).chain_name,1,40);
--      l_work_tab(i).dlv_date                    := SUBSTRB(g_edi_err_tab(i).dlv_date,1,10);
--      l_work_tab(i).invoice_number              := SUBSTRB(g_edi_err_tab(i).invoice_number,1,12);
--      l_work_tab(i).shop_code                   := SUBSTRB(g_edi_err_tab(i).shop_code,1,10);
--      l_work_tab(i).customer_number             := SUBSTRB(g_edi_err_tab(i).customer_number,1,9);
--      l_work_tab(i).shop_name                   := SUBSTRB(g_edi_err_tab(i).shop_name,1,20);
--      l_work_tab(i).line_no                     := g_edi_err_tab(i).line_no;
--      l_work_tab(i).item_code                   := SUBSTRB(g_edi_err_tab(i).item_code,1,7);
--      l_work_tab(i).edi_item_code               := SUBSTRB(g_edi_err_tab(i).edi_item_code,1,20);
--      l_work_tab(i).item_name                   := SUBSTRB(g_edi_err_tab(i).item_name,1,20);
--      l_work_tab(i).quantity                    := g_edi_err_tab(i).quantity;
--      l_work_tab(i).unit_price                  := g_edi_err_tab(i).unit_price;
--      l_work_tab(i).unit_price_amount           := g_edi_err_tab(i).unit_price_amount;
--      l_work_tab(i).err_message                 := SUBSTRB(g_edi_err_tab(i).err_message,1,40);
--      l_work_tab(i).created_by                  := cn_created_by;
--      l_work_tab(i).creation_date               := cd_creation_date;
--      l_work_tab(i).last_updated_by             := cn_last_updated_by;
--      l_work_tab(i).last_update_date            := cd_last_update_date;
--      l_work_tab(i).last_update_login           := cn_last_update_login;
--      l_work_tab(i).request_id                  := cn_request_id;
--      l_work_tab(i).program_application_id      := cn_program_application_id;
--      l_work_tab(i).program_id                  := cn_program_id;
--      l_work_tab(i).program_update_date         := cd_program_update_date;
      -- EDI�G���[��񂪏o�͑Ώ�(���[�o�̓t���O��"Y")�̃��R�[�h�̂ݓo�^����B
      IF ( g_edi_err_tab(i).output_flag = cv_output_flag_yes ) THEN
        -- ���������Z
        lv_work_idx := lv_work_idx + 1;
        -- �f�[�^��o�^
        SELECT xxcos_rep_order_err_list_s01.NEXTVAL INTO l_work_tab(lv_work_idx).record_id FROM DUAL;
        l_work_tab(lv_work_idx).base_code                   := SUBSTRB(g_edi_err_tab(i).base_code,1,4);
        l_work_tab(lv_work_idx).base_name                   := SUBSTRB(g_edi_err_tab(i).base_name,1,20);
        l_work_tab(lv_work_idx).edi_create_class            := SUBSTRB(g_edi_err_tab(i).edi_create_class,1,1);
        l_work_tab(lv_work_idx).edi_create_class_name       := SUBSTRB(g_input_rec.err_list_type_name,1,14);
        l_work_tab(lv_work_idx).chain_code                  := SUBSTRB(g_edi_err_tab(i).chain_code,1,4);
        l_work_tab(lv_work_idx).chain_name                  := SUBSTRB(g_edi_err_tab(i).chain_name,1,40);
        l_work_tab(lv_work_idx).dlv_date                    := SUBSTRB(g_edi_err_tab(i).dlv_date,1,10);
        l_work_tab(lv_work_idx).invoice_number              := SUBSTRB(g_edi_err_tab(i).invoice_number,1,12);
        l_work_tab(lv_work_idx).shop_code                   := SUBSTRB(g_edi_err_tab(i).shop_code,1,10);
        l_work_tab(lv_work_idx).customer_number             := SUBSTRB(g_edi_err_tab(i).customer_number,1,9);
        l_work_tab(lv_work_idx).shop_name                   := SUBSTRB(g_edi_err_tab(i).shop_name,1,20);
-- 2012/08/02 T.Osawa Ver.1.8 add start
        l_work_tab(lv_work_idx).shop_name_alt               := SUBSTRB(g_edi_err_tab(i).shop_name_alt,1,20);
-- 2012/08/02 T.Osawa Ver.1.8 add end
        l_work_tab(lv_work_idx).line_no                     := g_edi_err_tab(i).line_no;
        l_work_tab(lv_work_idx).item_code                   := SUBSTRB(g_edi_err_tab(i).item_code,1,7);
        l_work_tab(lv_work_idx).edi_item_code               := SUBSTRB(g_edi_err_tab(i).edi_item_code,1,20);
        l_work_tab(lv_work_idx).item_name                   := SUBSTRB(g_edi_err_tab(i).item_name,1,20);
        l_work_tab(lv_work_idx).quantity                    := g_edi_err_tab(i).quantity;
        l_work_tab(lv_work_idx).unit_price                  := g_edi_err_tab(i).unit_price;
        l_work_tab(lv_work_idx).unit_price_amount           := g_edi_err_tab(i).unit_price_amount;
        l_work_tab(lv_work_idx).err_message                 := SUBSTRB(g_edi_err_tab(i).err_message,1,40);
        l_work_tab(lv_work_idx).created_by                  := cn_created_by;
        l_work_tab(lv_work_idx).creation_date               := cd_creation_date;
        l_work_tab(lv_work_idx).last_updated_by             := cn_last_updated_by;
        l_work_tab(lv_work_idx).last_update_date            := cd_last_update_date;
        l_work_tab(lv_work_idx).last_update_login           := cn_last_update_login;
        l_work_tab(lv_work_idx).request_id                  := cn_request_id;
        l_work_tab(lv_work_idx).program_application_id      := cn_program_application_id;
        l_work_tab(lv_work_idx).program_id                  := cn_program_id;
        l_work_tab(lv_work_idx).program_update_date         := cd_program_update_date;
      END IF;
-- 2010/01/19 M.Sano Ver.1.7 mod end
--
    END LOOP;
--
    BEGIN
      FORALL i IN 1..l_work_tab.COUNT
        INSERT INTO xxcos_rep_order_err_list VALUES l_work_tab(i);
--
      gn_normal_cnt := l_work_tab.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        lv_table  := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_work_tab_name
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_apl_name
                      ,iv_name          => ct_msg_insert_err
                      ,iv_token_name1   => cv_tkn_table_name
                      ,iv_token_value1  => lv_table
                      ,iv_token_name2   => cv_tkn_key
                      ,iv_token_value2  => NULL
                     );
        RAISE global_api_expt;
    END;
--
    COMMIT;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ROLLBACK;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_report_work;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    lt_tkn  fnd_new_messages.message_text%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_err_list(
      i_input_rec g_input_rtype
    )
    IS
      SELECT base.account_number                                 base_code             --���_�R�[�h
            ,base.party_name                                     base_name             --���_����
            ,xee.edi_create_class                                edi_create_class      --EDI�쐬���敪
            ,xee.chain_code                                      chain_code            --�`�F�[���X�R�[�h
            ,chain.party_name                                    chain_name            --�`�F�[���X����
            ,TO_CHAR(xee.dlv_date,cv_fmt_date)                   dlv_date              --�X�ܔ[�i��
            ,xee.invoice_number                                  invoice_number        --�`�[�ԍ�
            ,xee.shop_code                                       shop_code             --�X�܃R�[�h
            ,store.account_number                                customer_number       --�ڋq�R�[�h
            ,store.cust_store_name                               shop_name             --�X�ܖ���
-- 2012/08/02 T.Osawa Ver.1.8 add start
            ,xee.shop_name_alt                                   shop_name_alt         --�X�ܖ��́i�J�i�j
-- 2012/08/02 T.Osawa Ver.1.8 add end
            ,xee.line_no                                         line_no               --�sNo
            ,xee.item_code                                       item_code             --�i�ڃR�[�h
            ,xee.edi_item_code                                   edi_item_code         --EDI���i�R�[�h
-- 2010/01/19 M.Sano Ver.1.7 add start
--            ,ximb.item_short_name                                item_name             --�i�ږ���
            ,xee.edi_item_name                                   item_name             --�i�ږ���
-- 2010/01/19 M.Sano Ver.1.7 add end
            ,xee.quantity                                        quantity              --�{��
            ,xee.unit_price                                      unit_price            --���P��
            ,round(xee.quantity * xee.unit_price,1)              unit_price_amount     --�������z
            ,xee.err_message                                     err_message           --�G���[���e
            ,xee.edi_err_id                                      edi_err_id            --�G���[ID
            ,xee.delete_flag                                     delete_flag           --�폜�t���O
            ,xee.work_id                                         work_id               --���[�NID
-- 2010/01/19 M.Sano Ver.1.7 add start
            ,CASE
               -- ����.�Ĕ��s�敪 �� �V�K                          �� ����1
               WHEN g_input_rec.request_type  = cv_exec_type_new THEN
                 flv.attribute1
               -- ����.�Ĕ��s�敪 �� �V�K, ����.���_ �� �Ɩ��Ǘ��� �� ����2
               WHEN g_input_rec.request_type <> cv_exec_type_new
                AND g_input_rec.base_code     = g_profile_rec.biz_man_dept_code THEN
                 flv.attribute2
               -- ��L�ȊO                                         �� ����3
               ELSE
                 flv.attribute3
             END                                                 output_flag           --���[�o�̓t���O
-- 2010/01/19 M.Sano Ver.1.7 add end
      FROM   xxcos_edi_errors                                    xee                   --EDI�G���[�e�[�u��
-- 2010/01/19 M.Sano Ver.1.7 mod start
--            ,ic_item_mst_b                                       iimb                  --OPM�i�ڃ}�X�^
--            ,xxcmn_item_mst_b                                    ximb                  --OPM�i�ڃ}�X�^�A�h�I��
            -- �N�C�b�N�R�[�h(�󒍃G���[���X�g�o�̓��b�Z�[�W)���
            ,fnd_lookup_values                                   flv
-- 2010/01/19 M.Sano Ver.1.7 mod end
            --�`�F�[���X���
            ,(
              SELECT  xca.chain_store_code                       chain_store_code      --�`�F�[���X�R�[�h(EDI)
                      ,hp.party_name                             party_name            --�ڋq����
              FROM    xxcmm_cust_accounts                        xca                   --�ڋq�}�X�^�A�h�I��
                      ,hz_cust_accounts                          hca                   --�ڋq�}�X�^
                      ,hz_parties                                hp                    --�p�[�e�B�}�X�^
              WHERE   hca.cust_account_id = xca.customer_id
              AND     hca.customer_class_code = cv_cust_class_chain
              AND     hp.party_id = hca.party_id
             )                                                   chain                 --�`�F�[���X���
            --�X�܏��
            ,(
              SELECT  xca.chain_store_code                       chain_store_code      --�`�F�[���X�R�[�h(EDI)
                      ,xca.store_code                            store_code            --�X�܃R�[�h
                      ,hca.account_number                        account_number        --�ڋq�R�[�h
                      ,xca.cust_store_name                       cust_store_name       --�ڋq�X�ܖ���
                      ,xca.delivery_base_code                    delivery_base_code    --�[�i���_�R�[�h
              FROM    xxcmm_cust_accounts                        xca                   --�ڋq�}�X�^�A�h�I��
                      ,hz_cust_accounts                          hca                   --�ڋq�}�X�^
              WHERE   hca.cust_account_id = xca.customer_id
              AND     hca.customer_class_code = cv_cust_class_store
             )                                                   store                 --�X�܏��
            --���_���
            ,(
              SELECT  hca.account_number                         account_number        --�ڋq�R�[�h
                      ,hp.party_name                             party_name            --�ڋq����
              FROM    hz_cust_accounts                           hca                   --�ڋq�}�X�^
                      ,hz_parties                                hp                    --�p�[�e�B�}�X�^
              WHERE   hca.customer_class_code = cv_cust_class_base
              AND     hp.party_id = hca.party_id
             )                                                   base                  --���_���
            --
      WHERE xee.edi_create_class = i_input_rec.err_list_type
      AND   store.chain_store_code(+) = xee.chain_code
      AND   store.store_code(+) = xee.shop_code
      AND   chain.chain_store_code(+) = xee.chain_code
      AND   base.account_number(+) = store.delivery_base_code
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      AND   iimb.item_no(+) = xee.item_code
--      AND   ximb.item_id(+) = iimb.item_id
--      AND   g_process_date
--        BETWEEN NVL(TRUNC(ximb.start_date_active),g_process_date)
--        AND     NVL(TRUNC(ximb.end_date_active),g_process_date)
      -- [�N�C�b�N�R�[�h]����
      AND   flv.meaning            = xee.err_message_code                   -- �T�v��EDI�G���[���.�G���[�R�[�h������
      AND   flv.lookup_type        = ct_order_err_list_message              -- XXCOS1_ORDER_ERR_LIST_MESSAGE
      AND   flv.enabled_flag       = cv_enabled_flag_yes
      AND   g_process_date   BETWEEN NVL(flv.start_date_active, g_process_date)
                                 AND NVL(flv.end_date_active,   g_process_date)
      AND   flv.language           = cv_default_language
      -- [�Ĕ��s�敪]����
      AND ( (    (   xee.err_list_out_flag     = cv_err_list_out_flag_no0   -- �G���[���X�g�o�͍σt���O�FN0 or NULL
                  OR xee.err_list_out_flag    IS NULL )
             AND (   g_input_rec.request_type  = cv_exec_type_new ) )       -- �Ĕ��s�敪�F�V�K
          OR
            (    xee.err_list_out_flag    <> cv_err_list_out_flag_no0       -- �G���[���X�g�o�͍σt���O�FN0�ȊO
             AND g_input_rec.request_type <> cv_exec_type_new )      )      -- �Ĕ��s�敪�F�V�K�ȊO
      -- [���_�R�[�h]����
      AND ( (    g_input_rec.base_code IS NULL )                            -- ����.���_�FNULL
          OR
            (    g_input_rec.base_code  = g_profile_rec.biz_man_dept_code 
             AND flv.attribute2         = cv_output_flag_yes             )  -- ����.���_�F�Ɩ��Ǘ���
          OR
            (    g_input_rec.base_code   <> g_profile_rec.biz_man_dept_code -- ����.���_�F�Ɩ��Ǘ����ȊO
             AND (   base.account_number  = g_input_rec.base_code
                  OR base.account_number IS NULL ) ) )                      -- ���_���.���_�R�[�h : ����.���_ or NULL
      -- [�`�F�[���X]����
      AND (  ( g_input_rec.edi_chain_code IS NULL )
          OR ( g_input_rec.edi_chain_code  = xee.chain_code ) )             -- �G���[.�`�F�[���X : ����.�`�F�[���X or NULL
      -- [EDI��M��]����
      -- ����.EDI��M��(FROM) �� EDI�G���[���.EDI��M�� �� ����.EDI��M��(TO)
      AND TRUNC(xee.edi_received_date) 
            >= NVL( g_input_rec.edi_received_date_from, TRUNC(xee.edi_received_date) )
      AND TRUNC(xee.edi_received_date) 
            <= NVL( g_input_rec.edi_received_date_to,   TRUNC(xee.edi_received_date) )
-- 2010/01/19 M.Sano Ver.1.7 mod end
      ORDER BY base.account_number
              ,xee.chain_code
              ,xee.dlv_date
              ,xee.invoice_number
              ,xee.shop_code
              ,xee.line_no
              ,xee.edi_item_code
      FOR UPDATE OF xee.edi_err_id NOWAIT
      ;
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
    --�f�[�^�擾
    --==============================================================
    OPEN cur_err_list(g_input_rec);
    FETCH cur_err_list BULK COLLECT INTO g_edi_err_tab;
    CLOSE cur_err_list;
--
    gn_target_cnt := g_edi_err_tab.COUNT;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ���b�N�G���[�n���h�� ***
    WHEN resource_busy_expt THEN
-- ******************** 2009/07/23 N.Maeda 1.4 MOD START ******************************* --
      gn_lock_flg := 1; -- ���b�N��
--      lt_tkn := xxccp_common_pkg.get_msg(ct_apl_name, ct_msg_edi_err_tab);
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     ct_apl_name
--                    ,ct_msg_resource_busy_err
--                    ,cv_tkn_table
--                    ,lt_tkn
--                   );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
--      ov_retcode := cv_status_error;
-- ******************** 2009/07/23 N.Maeda 1.4 MOD  END  ******************************* --
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
      IF (cur_err_list%ISOPEN) THEN
        CLOSE cur_err_list;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : �p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- �v���O������
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
    --==============================================================
    --�G���[���X�g��ʃ`�F�b�N
    --==============================================================
    BEGIN
--
      SELECT xlvv.description                               --�G���[���X�g��ʖ���
      INTO   g_input_rec.err_list_type_name
      FROM   xxcos_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = ct_qc_err_list_type         --�Q�ƃ^�C�v
      AND    xlvv.meaning = g_input_rec.err_list_type       --���e
      AND    xlvv.attribute1 = 'Y'                          --�󒍃G���[���X�g���̓t���O
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application        => ct_apl_name
                      ,iv_name               => ct_msg_err_list_err
                     );
        RAISE global_api_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
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
  END chk_parameter;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_err_list_type IN VARCHAR2
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 --   �Ĕ��s�敪
   ,iv_base_code                IN VARCHAR2 --   ���_�R�[�h
   ,iv_edi_chain_code           IN VARCHAR2 --   �`�F�[���X�R�[�h
   ,iv_edi_received_date_from   IN VARCHAR2 --   EDI��M���iFROM�j
   ,iv_edi_received_date_to     IN VARCHAR2 --   EDI��M���iTO)
-- 2010/01/19 M.Sano Ver.1.7 add end
   ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--2009/06/19  Ver1.3 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--2009/06/19  Ver1.3 T1_1437  Add end
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
    --������
    g_input_rec := g_input_rec_init;
    g_input_rec.err_list_type := iv_err_list_type;
-- 2010/01/19 M.Sano Ver.1.7 add start
    g_input_rec.request_type           := NVL(iv_request_type, cv_exec_type_new);
    g_input_rec.base_code              := iv_base_code;
    g_input_rec.edi_chain_code         := iv_edi_chain_code;
    g_input_rec.edi_received_date_from := TO_DATE(iv_edi_received_date_from, cv_fmt_date);
    g_input_rec.edi_received_date_to   := TO_DATE(iv_edi_received_date_to, cv_fmt_date);
-- 2010/01/19 M.Sano Ver.1.7 add end
--
    -- ===============================================
    -- A-1.��������
    -- ===============================================
    init(
      lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,lv_retcode                  -- ���^�[���E�R�[�h
     ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2.�p�����[�^�`�F�b�N����
    -- ===============================================
    chk_parameter(
      lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,lv_retcode                  -- ���^�[���E�R�[�h
     ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3.�f�[�^�擾����
    -- ===============================================
    get_data(
      lv_errbuf                   -- �G���[�E���b�Z�[�W
     ,lv_retcode                  -- ���^�[���E�R�[�h
     ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
    -- ���b�N���Ŗ����ꍇ
    IF ( gn_lock_flg = 0 ) THEN 
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
      IF (gn_target_cnt > 0) THEN
        -- ===============================================
        -- A-4.���[���[�N�e�[�u���o�^����
        -- ===============================================
        insert_report_work(
          lv_errbuf                   -- �G���[�E���b�Z�[�W
         ,lv_retcode                  -- ���^�[���E�R�[�h
         ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- A-5.EDI�e�[�u���폜
        -- ===============================================
        delete_edi(
          lv_errbuf                   -- �G���[�E���b�Z�[�W
         ,lv_retcode                  -- ���^�[���E�R�[�h
         ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ===============================================
      -- A-6.SVF�N��
      -- ===============================================
      execute_svf(
        lv_errbuf                   -- �G���[�E���b�Z�[�W
       ,lv_retcode                  -- ���^�[���E�R�[�h
       ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
-- 2009/06/19  Ver1.3 T1_1437  Mod start
--    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
--    IF (lv_retcode != cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
      --
      --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
--
-- *********** 2009/09/29 N.Maeda 1.6 ADD START ************* --
      IF ( lv_retcode_svf != cv_status_normal  ) THEN
        ROLLBACK;
      END IF;
-- *********** 2009/09/29 N.Maeda 1.6 ADD  END  ************* --
--
-- 2009/06/19  Ver1.3 T1_1437  Mod End
--
      -- ===============================================
      -- A-7.���[���[�N�e�[�u���폜
      -- ===============================================
      IF (gn_target_cnt > 0) THEN
        delete_report_work(
          lv_errbuf                   -- �G���[�E���b�Z�[�W
         ,lv_retcode                  -- ���^�[���E�R�[�h
         ,lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      END IF;
--
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/06/19  Ver1.3 T1_1437  Add start
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
-- 2009/06/19  Ver1.3 T1_1437  Add End
-- 
-- 2009/08/03  Ver1.5 0000902  Mod Start
--      IF (gn_target_cnt = 0) THEN
--        ov_retcode := cv_status_warn;
--      END IF;
-- 2010/01/19 M.Sano Ver.1.7 mod start
--      IF ( gn_target_cnt > 0 ) THEN
      IF ( gn_normal_cnt > 0 ) THEN
-- 2010/01/19 M.Sano Ver.1.7 mod end
        ov_retcode := cv_status_warn;
      END IF;
-- 2009/08/03  Ver1.5 0000902  Mod End
-- ******************** 2009/07/23 N.Maeda 1.4 ADD START ******************************* --
    -- ���b�N���̏ꍇ
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg( ct_apl_name , ct_msg_Processed_other );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    END IF;
-- ******************** 2009/07/23 N.Maeda 1.4 ADD  END  ******************************* --
--
    out_line(buff => cv_prg_name || ' end');
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
    errbuf        OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_err_list_type IN  VARCHAR2   --   �G���[���X�g���
-- 2010/01/19 M.Sano Ver.1.7 add start
   ,iv_request_type             IN VARCHAR2 DEFAULT NULL --   �Ĕ��s�敪
   ,iv_base_code                IN VARCHAR2 DEFAULT NULL --   ���_�R�[�h
   ,iv_edi_chain_code           IN VARCHAR2 DEFAULT NULL --   �`�F�[���X�R�[�h
   ,iv_edi_received_date_from   IN VARCHAR2 DEFAULT NULL --   EDI��M���iFROM�j
   ,iv_edi_received_date_to     IN VARCHAR2 DEFAULT NULL --   EDI��M���iTO)
-- 2010/01/19 M.Sano Ver.1.7 add end
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
    out_line(buff => cv_prg_name || ' start');
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
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
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_err_list_type
-- 2010/01/19 M.Sano Ver.1.7 add start
     ,iv_request_type                             --�Ĕ��s�敪
     ,iv_base_code                                --���_�R�[�h
     ,iv_edi_chain_code                           --�`�F�[���X�R�[�h
     ,iv_edi_received_date_from                   --EDI��M���iFROM�j
     ,iv_edi_received_date_to                     --EDI��M���iTO)
-- 2010/01/19 M.Sano Ver.1.7 add end
     ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
-- ******************** 2009/07/23 N.Maeda 1.4 MOD START ******************************* --
    IF ( gn_lock_flg <> 0 ) THEN
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
    END IF;
-- ******************** 2009/07/23 N.Maeda 1.4 MOD  END  ******************************* --
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_target_cnt;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
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
    --�󔒍s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
    out_line(buff => cv_prg_name || ' end');
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
END XXCOS010A05R;
/
