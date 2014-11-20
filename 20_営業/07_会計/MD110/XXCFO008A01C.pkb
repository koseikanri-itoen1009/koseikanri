CREATE OR REPLACE PACKAGE BODY XXCFO008A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO008A01C
 * Description     : �ڋq�}�X�^VD�ޑK��z�̍X�V
 * MD.050          : MD050_CFO_008_A01_�ڋq�}�X�^VD�ޑK��z�̍X�V
 * MD.070          : MD050_CFO_008_A01_�ڋq�}�X�^VD�ޑK��z�̍X�V
 * Version         : 1.2
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        ���̓p�����[�^�l���O�o�͏���     (A-1)
 *  get_system_value  P        �e��V�X�e���l�擾����           (A-2)
 *  get_process_date  P        �������E������v���Ԏ擾����     (A-3)
 *  get_customer_change_balance P �ڋq�ʒޑK�c�����o����        (A-4)
 *  get_change_unpaid P        �������E����t�x���f�[�^���o���� (A-5)
 *  get_change_back   P        �ޑK�߂�����t�f�[�^���o����     (A-6)
 *  update_xxcmm_cust_accounts P �ޑK���z�X�V����               (A-7)
 *  get_other_vd_cust P        VD�ȊO�̌ڋq���擾����         (A-8)
 *  set_other_vd_cust P        VD�ȊO�̌ڋq���ێ�����         (A-9)
 *  out_other_vd_cust_header P VD�ȊO�̌ڋq���w�b�_�o�͏���   (A-10)
 *  out_other_vd_cust_detail P VD�ȊO�̌ڋq��񖾍׏o�͏���     (A-11)
 *  submain           P        ���C�������v���V�[�W��
 *  main              P        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-07    1.0  SCS ���� ��   ����쐬
 *  2009-06-26    1.1  SCS ���X��    [0000018]�p�t�H�[�}���X���P
 *  2009-11-24    1.2  SCS ����      [E_�{�ғ�_00017]�p�t�H�[�}���X���P
 ************************************************************************/
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--
  lock_expt                 EXCEPTION;      -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO008A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';        -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_008a01_001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_008a01_002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015'; --�������擾�G���[���b�Z�[�W
  cv_msg_008a01_003  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00016'; --��v���Ԏ擾�G���[���b�Z�[�W
  cv_msg_008a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00017'; --�O����v���Ԏ擾�G���[���b�Z�[�W
  cv_msg_008a01_005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00006'; --VD�ȊO�̌ڋq�ɒޑK�c�������݂���ꍇ�̌x�����b�Z�[�W(�w�b�_)
  cv_msg_008a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00007'; --VD�ȊO�̌ڋq�ɒޑK�c�������݂���ꍇ�̌x�����b�Z�[�W(����)
  cv_msg_008a01_007  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00018'; --�l�Z�b�g�擾�G���[���b�Z�[�W
  cv_msg_008a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; --���b�N�G���[���b�Z�[�W
  cv_msg_008a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020'; --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_008a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; --�Ώۃf�[�^��0��
  cv_msg_008a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032'; --�f�[�^�擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof             CONSTANT VARCHAR2(20) := 'PROF_NAME';                 -- �v���t�@�C����
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';                     -- �e�[�u����
  cv_tkn_target_date      CONSTANT VARCHAR2(20) := 'TARGET_DATE';               -- ������
  cv_tkn_customer_number  CONSTANT VARCHAR2(20) := 'CUSTOMER_NUMBER';           -- �ڋq�R�[�h
  cv_tkn_customer_name    CONSTANT VARCHAR2(20) := 'CUSTOMER_NAME';             -- �ڋq����
  cv_tkn_kyoten_code      CONSTANT VARCHAR2(20) := 'KYOTEN_CODE';               -- ���㋒�_�R�[�h
  cv_tkn_kyoten_name      CONSTANT VARCHAR2(20) := 'KYOTEN_NAME';               -- ���㋒�_��
  cv_tkn_flex_value       CONSTANT VARCHAR2(20) := 'FLEX_VALUE';                -- �l�Z�b�g��
  cv_tkn_flex_value_set   CONSTANT VARCHAR2(20) := 'FLEX_VALUE_SET_NAME';       -- �l�Z�b�g�l
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERRMSG';                    -- ORACLE�G���[�̓��e
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';                        -- �G���[�f�[�^�̐���
--
  -- ���{�ꎫ��
  cv_dict_aplid_sqlgl     CONSTANT VARCHAR2(100) := 'CFO000A00001';               -- "�A�v���P�[�V����ID�FSQLGL"
--
  -- �v���t�@�C��
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- ��v����ID
  cv_gyotai_chu_vd        CONSTANT VARCHAR2(30) := 'XXCFO1_CUST_GYOTAI_CHU_VD'; -- XXCFO:VD�ƑԒ����ރR�[�h
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_shrt_name_gl    CONSTANT fnd_application.application_short_name%TYPE := 'SQLGL'; -- �A�v���P�[�V�����Z�k��(��ʉ�v)
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_type_change_account  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFO1_CHANGE_ACCOUNT'; -- �ޑK����ȖڃR�[�h
  cv_type_cust_gyotai_sho CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMM_CUST_GYOTAI_SHO'; -- �Ƒԕ���(������)
--
  -- �g�pDB��
  gv_tkn_xxca_tab         CONSTANT VARCHAR2(50) := 'XXCMM_CUST_ACCOUNTS';       -- �e�[�u�����F�ڋq�ǉ����e�[�u��
--
  cv_adj_period_flag_n    CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N'; -- �������ԃt���O(�ʏ����)
  cv_actual_flag_a        CONSTANT gl_balances.actual_flag%TYPE := 'A';        -- ���уt���O(����)
  cv_enabled_flag_y       CONSTANT fnd_lookup_values.enabled_flag%TYPE := 'Y'; -- �L���t���O(�L��)
  cv_currency_code        CONSTANT gl_balances.currency_code%TYPE := 'JPY';    -- �ʉ݃R�[�h(�~)
  cv_status_p             CONSTANT gl_je_headers.status%TYPE := 'P';           -- �d��X�e�[�^�X(�]�L��)
  cv_je_source_pay        CONSTANT gl_je_headers.je_source%TYPE := 'Payables'; -- �d��\�[�X�R�[�h(���|�Ǘ�)
  cv_je_category_purinv   CONSTANT gl_je_headers.je_category%TYPE := 'Purchase Invoices'; -- �d��J�e�S���R�[�h(�d��������)
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �ڋq�ʒޑK�c�����z��
  TYPE g_segment5_ttype         IS TABLE OF gl_code_combinations.segment5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_cust_account_id_ttype  IS TABLE OF hz_cust_accounts.cust_account_id%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_sale_base_code_ttype   IS TABLE OF xxcmm_cust_accounts.sale_base_code%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_attribute1_ttype       IS TABLE OF fnd_lookup_values.attribute1%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_change_balance_ttype   IS TABLE OF NUMBER
                                            INDEX BY PLS_INTEGER;
  gt_segment5                   g_segment5_ttype;                     -- �ڋq�R�[�h
  gt_cust_account_id            g_cust_account_id_ttype;              -- �ڋqID
  gt_sale_base_code             g_sale_base_code_ttype;               -- ���㋒�_�R�[�h
  gt_attribute1                 g_attribute1_ttype;                   -- �Ƒԕ��ށi�����ށj
  gt_change_balance             g_change_balance_ttype;               -- �������ޑK�c��
--
  -- VD�ȊO�ڋq���z��
  TYPE g_other_vd_cust_rtype    IS RECORD(
    flex_value_partner          fnd_flex_values_vl.flex_value%TYPE,   -- �ڋq�R�[�h
    description_partner         fnd_flex_values_vl.description%TYPE,  -- �ڋq��
    flex_value_department       fnd_flex_values_vl.flex_value%TYPE,   -- ���㋒�_�R�[�h
    description_department      fnd_flex_values_vl.description%TYPE   -- ���㋒�_��
  );
  TYPE g_other_vd_cust_ttype    IS TABLE OF g_other_vd_cust_rtype
                                            INDEX BY PLS_INTEGER;
  gt_other_vd_cust              g_other_vd_cust_ttype;                -- VD�ȊO�ڋq���z��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_set_of_bks_id            NUMBER;                                 -- ��v����ID
  gn_gyotai_chu_vd            NUMBER;                                 -- XXCFO:VD�ƑԒ����ރR�[�h
  gn_appl_id_gl               fnd_application.application_id%TYPE;    -- �A�v���P�[�V����ID(��ʉ�v)
  gd_operation_date           DATE;                                   -- ������
  gv_this_period_name         gl_period_statuses.period_name%TYPE;    -- ������v����
  gv_last_period_name         gl_period_statuses.period_name%TYPE;    -- �O����v����
  gn_change_unpaid            NUMBER;                                 -- �ޑK���������z
  gn_change_back              NUMBER;                                 -- �ޑK�߂�����t���z
  gv_flex_value_partner       fnd_flex_values_vl.flex_value%TYPE;     -- �ڋq�R�[�h
  gv_description_partner      fnd_flex_values_vl.description%TYPE;    -- �ڋq��
  gv_flex_value_department    fnd_flex_values_vl.flex_value%TYPE;     -- ���㋒�_�R�[�h
  gv_description_department   fnd_flex_values_vl.description%TYPE;    -- ���㋒�_��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_operation_date   IN  VARCHAR2,     --   �^�p��
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out     -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_operation_date    -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ���O�o��
      ,iv_conc_param1  => iv_operation_date    -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_system_value
   * Description      : �e��V�X�e���l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_system_value(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_system_value'; -- �v���O������
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
    -- �v���t�@�C������GL��v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �擾�G���[��
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                       -- GL��v����ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFO:VD�ƑԒ����ރR�[�h�擾
    gn_gyotai_chu_vd := TO_NUMBER(FND_PROFILE.VALUE( cv_gyotai_chu_vd ));
    -- �擾�G���[��
    IF ( gn_gyotai_chu_vd IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_001 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_gyotai_chu_vd ))
                                                                       -- XXCFO:VD�ƑԒ����ރR�[�h
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u��ʉ�v�v�̃A�v���P�[�V����ID���擾
    gn_appl_id_gl := xxccp_common_pkg.get_application( cv_appl_shrt_name_gl );
    -- �擾���ʂ�NULL�Ȃ�΃G���[
    IF ( gn_appl_id_gl IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_008a01_011 -- �f�[�^�擾�G���[
                                                    ,cv_tkn_data       -- �g�[�N��'DATA'
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfo
                                                      ,cv_dict_aplid_sqlgl 
                                                     ))
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
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
  END get_system_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : �������E������v���Ԏ擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    iv_operation_date   IN  VARCHAR2,     --   �^�p��
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    -- �������Ŏg�p���鏈�������m�肷��
    IF ( iv_operation_date IS NULL ) THEN
      -- �Ɩ��������t�擾����
      gd_operation_date := xxccp_common_pkg2.get_process_date;
      --�擾���ʂ�NULL�Ȃ�΃G���[
      IF ( gd_operation_date IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_008a01_002 ) -- �������擾�G���[
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      gd_operation_date := TO_DATE(iv_operation_date,'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    -- ������v���Ԃ��擾����
    BEGIN
      SELECT glps.period_name period_name
      INTO gv_this_period_name
      FROM gl_period_statuses glps
      WHERE glps.application_id         = gn_appl_id_gl
        AND glps.set_of_books_id        = gn_set_of_bks_id
        AND glps.adjustment_period_flag = cv_adj_period_flag_n
        AND gd_operation_date BETWEEN glps.start_date AND glps.end_date
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_008a01_003  -- ��v���Ԏ擾�G���[
                                                      ,cv_tkn_target_date -- �g�[�N��'TARGET_DATE'
                                                      ,TO_CHAR( gd_operation_date,'YYYY/MM/DD' )) -- ������
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- �O����v���Ԃ��擾����
    BEGIN
      SELECT glps.period_name period_name
      INTO gv_last_period_name
      FROM gl_period_statuses glps
      WHERE glps.application_id         = gn_appl_id_gl
        AND glps.set_of_books_id        = gn_set_of_bks_id
        AND glps.adjustment_period_flag = cv_adj_period_flag_n
        AND ADD_MONTHS( gd_operation_date,-1 ) BETWEEN glps.start_date AND glps.end_date
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                      ,cv_msg_008a01_004  -- �O����v���Ԏ擾�G���[
                                                      ,cv_tkn_target_date -- �g�[�N��'TARGET_DATE'
                                                      ,TO_CHAR( gd_operation_date,'YYYY/MM/DD' )) -- ������
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_customer_change_balance
   * Description      : �ڋq�ʒޑK�c�����o���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_customer_change_balance(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_customer_change_balance'; -- �v���O������
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
    -- �ڋq�ʒޑK�c�����o
    CURSOR get_customer_change_cur
    IS
      SELECT /*+ LEADING(fnac glcc glbl)
                 USE_NL (fnac glcc glbl)
             */
             glcc.segment5                segment5,         -- �ڋq�R�[�h
             hzca.cust_account_id         cust_account_id,  -- �ڋqID
             xxca.sale_base_code          sale_base_code,   -- ���㋒�_�R�[�h
             fnlt.attribute1              attribute1,       -- �Ƒԕ���(������)
             SUM( glbl.begin_balance_dr -
                  glbl.begin_balance_cr +
                  glbl.period_net_dr -
                  glbl.period_net_cr )    change_balance    -- �������ޑK�c��
      FROM  gl_code_combinations glcc
           ,gl_balances          glbl
           ,fnd_lookup_values    fnac                       -- �N�C�b�N�R�[�h(�ޑK����ȖڃR�[�h)
           ,fnd_lookup_values    fnlt                       -- �N�C�b�N�R�[�h(�Ƒԕ���(������))
           ,hz_cust_accounts     hzca
           ,xxcmm_cust_accounts  xxca
-- == 2009/06/26 V1.1 Added START ===============================================================
           ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE glbl.set_of_books_id      = gn_set_of_bks_id
        AND glbl.period_name          = gv_this_period_name
        AND glbl.actual_flag          = cv_actual_flag_a
        AND glbl.currency_code        = cv_currency_code
        AND glcc.code_combination_id  = glbl.code_combination_id
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id      = gn_set_of_bks_id
-- == 2009/06/26 V1.1 Added END   ===============================================================
        AND fnac.lookup_type          = cv_type_change_account
        AND fnac.language             = USERENV( 'LANG' )
        AND fnac.enabled_flag         = cv_enabled_flag_y
        AND NVL( fnac.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnac.end_date_active,gd_operation_date )   >= gd_operation_date
        AND glcc.segment3             = fnac.lookup_code
        AND glcc.segment5             = hzca.account_number
        AND xxca.customer_id          = hzca.cust_account_id
        AND fnlt.lookup_type          = cv_type_cust_gyotai_sho
        AND fnlt.language             = USERENV( 'LANG' )
        AND fnlt.enabled_flag         = cv_enabled_flag_y
        AND NVL( fnlt.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnlt.end_date_active,gd_operation_date )   >= gd_operation_date
        AND xxca.business_low_type   = fnlt.lookup_code
        AND EXISTS (
            SELECT /*+ INDEX(glblmv GL_BALANCES_N1) */
                   'X'
            FROM gl_balances glblmv
            WHERE glblmv.set_of_books_id     = gn_set_of_bks_id
              AND glblmv.currency_code       = cv_currency_code
              AND glblmv.actual_flag         = cv_actual_flag_a
              AND glblmv.period_name         IN ( gv_this_period_name,
                                                  gv_last_period_name )
              AND glblmv.code_combination_id = glbl.code_combination_id
              AND ( glblmv. period_net_dr    <> 0
                 OR glblmv. period_net_cr    <> 0 )
            )
      GROUP BY glcc.segment5,         -- �ڋq�R�[�h
               hzca.cust_account_id,  -- �ڋqID
               xxca.sale_base_code,   -- ���㋒�_�R�[�h
               fnlt.attribute1        -- �Ƒԕ���(������)
    ;
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
    -- �J�[�\���I�[�v��
    OPEN get_customer_change_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_customer_change_cur BULK COLLECT INTO
          gt_segment5,
          gt_cust_account_id,
          gt_sale_base_code,
          gt_attribute1,
          gt_change_balance;
--
    -- �Ώی����̃Z�b�g
    gn_target_cnt := gt_segment5.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_customer_change_cur;
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
  END get_customer_change_balance;
--
  /**********************************************************************************
   * Procedure Name   : get_change_unpaid
   * Description      : �������E����t�x���f�[�^���o���� (A-5)
   ***********************************************************************************/
  PROCEDURE get_change_unpaid(
    in_loop_cnt         IN  NUMBER,       --   �J�����g���R�[�h�C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_change_unpaid'; -- �v���O������
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
    cv_payment_status_y     CONSTANT ap_invoices_all.payment_status_flag%TYPE := 'Y'; -- �x���X�e�[�^�X(�x����)
    cv_payment_status_n     CONSTANT ap_invoices_all.payment_status_flag%TYPE := 'N'; -- �x���X�e�[�^�X(����)
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ޑK���������z���擾����
    BEGIN
      SELECT SUM( NVL( gljl.entered_dr,0 ) -
                  NVL( gljl.entered_cr,0 )) change_unpaid
      INTO gn_change_unpaid
      FROM gl_code_combinations glcc,
           fnd_lookup_values    fnac,
           gl_je_headers        gljh,
           gl_je_lines          gljl,
           ap_invoices_all      apia
-- == 2009/06/26 V1.1 Added START ===============================================================
          ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE gljh.set_of_books_id        = gn_set_of_bks_id
        AND gljh.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
        AND gljh.je_source              = cv_je_source_pay      -- ���|�Ǘ�
        AND gljh.je_category            = cv_je_category_purinv -- �d��������
        AND gljh.actual_flag            = cv_actual_flag_a
        AND gljh.currency_code          = cv_currency_code
        AND gljh.status                 = cv_status_p
        AND gljh.je_header_id           = gljl.je_header_id
        AND fnac.lookup_type            = cv_type_change_account
        AND fnac.language               = USERENV( 'LANG' )
        AND fnac.enabled_flag           = cv_enabled_flag_y
        AND NVL( fnac.start_date_active,gd_operation_date ) <= gd_operation_date
        AND NVL( fnac.end_date_active,gd_operation_date )   >= gd_operation_date
        AND glcc.segment3               = fnac.lookup_code
        AND glcc.segment5               = gt_segment5( in_loop_cnt )
        AND gljl.code_combination_id    = glcc.code_combination_id
        AND gljl.reference_2            = apia.invoice_id
        AND apia.cancelled_date         IS NULL
        AND (( apia.payment_status_flag = cv_payment_status_n )
          OR ( apia.payment_status_flag = cv_payment_status_y
            AND EXISTS (
                SELECT 'X'
                FROM ap_invoice_payments_all apipa,
                     ap_checks_all           apca
                WHERE apipa.invoice_id = apia.invoice_id
                  AND apca.check_id    = apipa.check_id
                  AND apca.check_date  > gd_operation_date )))
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        = gn_set_of_bks_id
        AND gljl.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
-- == 2009/06/26 V1.1 Added END   ===============================================================
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^���擾�ł��Ȃ��ꍇ�A�ޑK���������z��0�Ƃ���
        gn_change_unpaid := 0;
    END;
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
  END get_change_unpaid;
--
  /**********************************************************************************
   * Procedure Name   : get_change_back
   * Description      : �ޑK�߂�����t�f�[�^���o���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_change_back(
    in_loop_cnt         IN  NUMBER,       --   �J�����g���R�[�h�C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_change_back'; -- �v���O������
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
    -- �ޑK�߂�����t���z���擾����
    BEGIN
      SELECT SUM( NVL( gljl.entered_cr,0 ) -
                  NVL( gljl.entered_dr,0 )) change_back
      INTO gn_change_back
      FROM gl_code_combinations glcc,
           fnd_lookup_values    fnac,
           gl_je_headers        gljh,
           gl_je_lines          gljl
-- == 2009/06/26 V1.1 Added START ===============================================================
          ,gl_sets_of_books     gsob
-- == 2009/06/26 V1.1 Added END   ===============================================================
      WHERE gljh.set_of_books_id     = gn_set_of_bks_id
        AND gljh.period_name         = gv_this_period_name
        AND gljh.je_source           <> cv_je_source_pay      -- ���|�Ǘ�
        AND gljh.je_category         <> cv_je_category_purinv -- �d��������
        AND gljh.actual_flag         = cv_actual_flag_a
        AND gljh.currency_code       = cv_currency_code
        AND gljh.status              = cv_status_p
        AND gljh.je_header_id        = gljl.je_header_id
        AND fnac.lookup_type         = cv_type_change_account
        AND fnac.language            = USERENV( 'LANG' )
        AND fnac.enabled_flag        = cv_enabled_flag_y
        AND NVL(fnac.start_date_active,gd_operation_date) <= gd_operation_date
        AND NVL(fnac.end_date_active,gd_operation_date)   >= gd_operation_date
        AND glcc.segment3            = fnac.lookup_code
        AND glcc.segment5            = gt_segment5( in_loop_cnt )
        AND gljl.code_combination_id = glcc.code_combination_id
        AND gljl.effective_date      > gd_operation_date
-- == 2009/06/26 V1.1 Added START ===============================================================
        AND glcc.chart_of_accounts_id   = gsob.chart_of_accounts_id
        AND gsob.set_of_books_id        = gn_set_of_bks_id
        AND gljl.period_name            IN ( gv_this_period_name,
                                             gv_last_period_name )
-- == 2009/06/26 V1.1 Added END   ===============================================================
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^���擾�ł��Ȃ��ꍇ�A�ޑK�߂�����t���z��0�Ƃ���
        gn_change_back := 0;
    END;
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
  END get_change_back;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcmm_cust_accounts
   * Description      : �ޑK���z�X�V���� (A-7)
   ***********************************************************************************/
  PROCEDURE update_xxcmm_cust_accounts(
    in_loop_cnt         IN  NUMBER,       --   �J�����g���R�[�h�C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xxcmm_cust_accounts'; -- �v���O������
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
    -- �e�[�u�����b�N�J�[�\��
    CURSOR upd_table_lock_cur
    IS
      SELECT xxca.customer_id  customer_id
      FROM xxcmm_cust_accounts xxca
      WHERE xxca.customer_id = gt_cust_account_id( in_loop_cnt )
      FOR UPDATE OF xxca.customer_id NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_table_lock_rec      upd_table_lock_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ڋq�ǉ���񃍃b�N���s��
    OPEN upd_table_lock_cur;
    FETCH upd_table_lock_cur INTO upd_table_lock_rec;
--
    BEGIN
      UPDATE xxcmm_cust_accounts xxca
      SET xxca.change_amount          = gt_change_balance( in_loop_cnt )
                                      - NVL( gn_change_unpaid,0 )
                                      + NVL( gn_change_back,0 )      -- �ޑK
        , xxca.last_updated_by        = cn_last_updated_by           -- �ŏI�ύX�҂̃��[�U�[ID
        , xxca.last_update_date       = cd_last_update_date          -- �ŏI�ύX����
        , xxca.last_update_login      = cn_last_update_login         -- �ŏI���O�C��ID
        , xxca.request_id             = cn_request_id                -- �R���J�����g�̃��N�G�X�gID
        , xxca.program_application_id = cn_program_application_id    -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        , xxca.program_id             = cn_program_id                -- �R���J�����g�E�v���O�����̃v���O����ID
        , xxca.program_update_date    = cd_program_update_date       -- �R���J�����g�E�v���O�����ɂ��ŏI�ύX����
      WHERE CURRENT OF upd_table_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_008a01_009 -- �f�[�^�X�V�G���[
                                                      ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                      ,xxcfr_common_pkg.get_table_comment(gv_tkn_xxca_tab) --�ڋq�ǉ����e�[�u��
                                                      ,cv_tkn_errmsg     -- �g�[�N��'ERRMSG'
                                                      ,SQLERRM )
                                                     ,1
                                                     ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_table_lock_cur;
--
  EXCEPTION
--
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                     ,cv_msg_008a01_008 -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table      -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(gv_tkn_xxca_tab)) --�ڋq�ǉ����e�[�u��
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
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
  END update_xxcmm_cust_accounts;
--
  /**********************************************************************************
   * Procedure Name   : get_other_vd_cust
   * Description      : VD�ȊO�̌ڋq���擾���� (A-8)
   ***********************************************************************************/
  PROCEDURE get_other_vd_cust(
    in_loop_cnt         IN  NUMBER,       --   �J�����g���R�[�h�C���f�b�N�X
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_vd_cust'; -- �v���O������
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
    cv_flex_value_set_partner     CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE := 'XX03_PARTNER';
                                                                      -- �l�Z�b�g��(AFF�ڋq)
    cv_flex_value_set_department  CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE := 'XX03_DEPARTMENT';
                                                                      -- �l�Z�b�g��(AFF����)
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �l�Z�b�g���o
    CURSOR get_other_vd_cust_cur(
      iv_flex_value_set_name in fnd_flex_value_sets.flex_value_set_name%TYPE,
      iv_flex_value          in fnd_flex_values_vl.flex_value%TYPE)
    IS
      SELECT ffvf.flex_value   flex_value,
             ffvf.description  description
      FROM fnd_flex_value_sets ffvs,
           fnd_flex_values_vl  ffvf
      WHERE ffvs.flex_value_set_name = iv_flex_value_set_name
        AND ffvs.flex_value_set_id   = ffvf.flex_value_set_id
        AND ffvf.flex_value          = iv_flex_value
    ;
--
    -- *** ���[�J���E���R�[�h ***
    get_other_vd_cust_rec   get_other_vd_cust_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ڋq�����擾����
    OPEN get_other_vd_cust_cur( cv_flex_value_set_partner,   -- �l�Z�b�g��(AFF�ڋq)
                                gt_segment5( in_loop_cnt )); -- �ڋq�R�[�h
    FETCH get_other_vd_cust_cur INTO get_other_vd_cust_rec;
--
    IF ( get_other_vd_cust_cur%FOUND ) THEN
      gv_flex_value_partner  := get_other_vd_cust_rec.flex_value;
      gv_description_partner := get_other_vd_cust_rec.description;
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo              -- 'XXCFO'
                                                    ,cv_msg_008a01_007           -- �l�Z�b�g�擾�G���[
                                                    ,cv_tkn_flex_value           -- �g�[�N��'FLEX_VALUE'
                                                    ,gt_segment5( in_loop_cnt )  -- �ڋq�R�[�h
                                                    ,cv_tkn_flex_value_set       -- �g�[�N��'FLEX_VALUE_SET_NAME'
                                                    ,cv_flex_value_set_partner)  -- �l�Z�b�g��(AFF�ڋq)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE get_other_vd_cust_cur;
--
    -- ���㋒�_�����擾����
    OPEN get_other_vd_cust_cur( cv_flex_value_set_department,         -- �l�Z�b�g��(AFF����)
                                gt_sale_base_code( in_loop_cnt )); -- ���㋒�_�R�[�h
    FETCH get_other_vd_cust_cur INTO get_other_vd_cust_rec;
--
    IF ( get_other_vd_cust_cur%FOUND ) THEN
      gv_flex_value_department  := get_other_vd_cust_rec.flex_value;
      gv_description_department := get_other_vd_cust_rec.description;
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                    -- 'XXCFO'
                                                    ,cv_msg_008a01_007                 -- �l�Z�b�g�擾�G���[
                                                    ,cv_tkn_flex_value                 -- �g�[�N��'FLEX_VALUE'
                                                    ,gt_sale_base_code( in_loop_cnt )  -- ���㋒�_�R�[�h
                                                    ,cv_tkn_flex_value_set             -- �g�[�N��'FLEX_VALUE_SET_NAME'
                                                    ,cv_flex_value_set_department)     -- �l�Z�b�g��(AFF����)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE get_other_vd_cust_cur;
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
  END get_other_vd_cust;
--
  /**********************************************************************************
   * Procedure Name   : set_other_vd_cust
   * Description      : VD�ȊO�̌ڋq���ێ����� (A-9)
   ***********************************************************************************/
  PROCEDURE set_other_vd_cust(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_other_vd_cust'; -- �v���O������
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
    ln_tab_index    NUMBER;     -- VD�ȊO�ڋq���z��i�[������ԍ�
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
    -- VD�ȊO�ڋq���z��i�[������ԍ����Z�o
    ln_tab_index := gt_other_vd_cust.COUNT + 1;
    -- VD�ȊO�ڋq���z��֊i�[
    gt_other_vd_cust( ln_tab_index ).flex_value_partner     := gv_flex_value_partner;     -- �ڋq�R�[�h
    gt_other_vd_cust( ln_tab_index ).description_partner    := gv_description_partner;    -- �ڋq��
    gt_other_vd_cust( ln_tab_index ).flex_value_department  := gv_flex_value_department;  -- ���㋒�_�R�[�h
    gt_other_vd_cust( ln_tab_index ).description_department := gv_description_department; -- ���㋒�_��
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
  END set_other_vd_cust;
--
  /**********************************************************************************
   * Procedure Name   : out_other_vd_cust_header
   * Description      : VD�ȊO�̌ڋq���w�b�_�o�͏��� (A-10)
   ***********************************************************************************/
  PROCEDURE out_other_vd_cust_header(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_other_vd_cust_header'; -- �v���O������
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
    -- VD�ȊO�̌ڋq�ɒޑK�c�������݂���ꍇ�̌x�����b�Z�[�W(�w�b�_)
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                  ,cv_msg_008a01_005)
                                                 ,1
                                                 ,5000);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
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
  END out_other_vd_cust_header;
--
  /**********************************************************************************
   * Procedure Name   : out_other_vd_cust_detail
   * Description      : VD�ȊO�̌ڋq��񖾍׏o�͏��� (A-10)
   ***********************************************************************************/
  PROCEDURE out_other_vd_cust_detail(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_other_vd_cust_detail'; -- �v���O������
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
    ln_loop_cnt     NUMBER;     -- ���[�v�J�E���^
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
    <<cust_data_loop>>
    FOR ln_loop_cnt IN gt_other_vd_cust.FIRST..gt_other_vd_cust.LAST LOOP
--
      -- VD�ȊO�̌ڋq�ɒޑK�c�������݂���ꍇ�̌x�����b�Z�[�W(����)
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo         -- 'XXCFO'
                                                    ,cv_msg_008a01_006
                                                    ,cv_tkn_customer_number -- �g�[�N��'CUSTOMER_NUMBER'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).flex_value_partner      -- �ڋq�R�[�h
                                                    ,cv_tkn_customer_name   -- �g�[�N��'CUSTOMER_NAME'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).description_partner     -- �ڋq��
                                                    ,cv_tkn_kyoten_code     -- �g�[�N��'KYOTEN_CODE'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).flex_value_department   -- ���㋒�_�R�[�h
                                                    ,cv_tkn_kyoten_name     -- �g�[�N��'KYOTEN_NAME'
                                                    ,gt_other_vd_cust( ln_loop_cnt ).description_department) -- ���㋒�_��
                                                   ,1
                                                   ,5000);
--
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
--
    END LOOP cust_data_loop;
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
  END out_other_vd_cust_detail;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_operation_date   IN  VARCHAR2,     --   �^�p��
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_normal_cnt   NUMBER;         -- ���팏��
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- PL/SQL�\�̏�����
    gt_segment5.DELETE;         -- �ڋq�R�[�h
    gt_cust_account_id.DELETE;  -- �ڋqID
    gt_sale_base_code.DELETE;   -- ���㋒�_�R�[�h
    gt_attribute1.DELETE;       -- �Ƒԕ��ށi�����ށj
    gt_change_balance.DELETE;   -- �������ޑK�c��
    gt_other_vd_cust.DELETE;    -- VD�ȊO�ڋq���z��
--
    -- ���[�J���ϐ��̏�����
    ln_normal_cnt := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       iv_operation_date     -- �^�p��
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �e��V�X�e���l�擾����(A-2)
    -- =====================================================
    get_system_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������E������v���Ԏ擾����(A-3)
    -- =====================================================
    get_process_date(
       iv_operation_date     -- �^�p��
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �ڋq�ʒޑK�c�����o����(A-4)
    -- =====================================================
    get_customer_change_balance(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    IF ( gn_target_cnt > 0 ) THEN
      <<cust_data_loop>>
      FOR ln_loop_cnt IN gt_segment5.FIRST..gt_segment5.LAST LOOP
--
        -- VD�ڋq�Ȃ�X�V�����A�ȊO�̓��O�֏o��
        IF ( gt_attribute1(ln_loop_cnt) = gn_gyotai_chu_vd ) THEN
--
          -- =====================================================
          --  �������E����t�x���f�[�^���o����(A-5)
          -- =====================================================
          get_change_unpaid(
             ln_loop_cnt           -- �J�����g���R�[�h�C���f�b�N�X
            ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  �ޑK�߂�����t�f�[�^���o����(A-6)
          -- =====================================================
          get_change_back(
             ln_loop_cnt           -- �J�����g���R�[�h�C���f�b�N�X
            ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  �ޑK���z�X�V����(A-7)
          -- =====================================================
          update_xxcmm_cust_accounts(
             ln_loop_cnt           -- �J�����g���R�[�h�C���f�b�N�X
            ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
          -- �X�V�������I������琳�팏�����J�E���g
          ln_normal_cnt := ln_normal_cnt + 1;
--
        ELSE
--
          -- =====================================================
          --  VD�ȊO�̌ڋq���擾����(A-8)
          -- =====================================================
          get_other_vd_cust(
             ln_loop_cnt           -- �J�����g���R�[�h�C���f�b�N�X
            ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  VD�ȊO�̌ڋq���ێ�����(A-9)
          -- =====================================================
          set_other_vd_cust(
             lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
        END IF;
      END LOOP cust_data_loop;
--
      -- VD�ȊO�̌ڋq�����o���Ă���΃��O�o�͂��s��
      IF ( gt_other_vd_cust.COUNT > 0 ) THEN
--
        -- =====================================================
        --  VD�ȊO�̌ڋq���w�b�_�o�͏���(A-10)
        -- =====================================================
        out_other_vd_cust_header(
           lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  VD�ȊO�̌ڋq��񖾍׏o�͏���(A-11)
        -- =====================================================
        out_other_vd_cust_detail(
           lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    ELSE
      -- �Ώۃf�[�^��0���̃��b�Z�[�W�o�͂��s��
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_008a01_010) -- �Ώۃf�[�^��0��
                                                   ,1
                                                   ,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    -- ���팏���̃Z�b�g
    gn_normal_cnt := ln_normal_cnt;
    -- �X�L�b�v�����̃Z�b�g
    gn_warn_cnt := gt_other_vd_cust.COUNT;
--
    -- VD�ȊO�̌ڋq��񂪂���ꍇ�A�x���I��
    IF ( gn_warn_cnt > 0 ) THEN
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
    errbuf              OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_operation_date   IN      VARCHAR2          --    �^�p��
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
       iv_operation_date    -- �^�p��
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
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
END XXCFO008A01C;
/
