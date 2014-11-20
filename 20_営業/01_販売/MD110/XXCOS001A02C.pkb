CREATE OR REPLACE PACKAGE BODY XXCOS001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A02C (body)
 * Description      : �����f�[�^�̎捞���s��
 * MD.050           : HHT�����f�[�^�捞 (MD050_COS_001_A02)
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_data_receive   �������[�N�e�[�u���������f�[�^���o(A-1)
 *  payment_data_check     ���o�����f�[�^�̑Ó����`�F�b�N(A-2)
 *  error_data_register    �G���[�����Ώۃf�[�^��o�^(A-3)
 *  payment_data_register  �����f�[�^��o�^(A-4)
 *  payment_work_delete    �������[�N�e�[�u���̃��R�[�h�폜(A-5)
 *  payment_data_delete    �����e�[�u���̕s�v�f�[�^�폜(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0   S.Miyakoshi       �V�K�쐬
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]�S�ݓXHHT�敪�ύX�ɑΉ�
 *                                       [COS_005]�Ƒԏ����ނɂ�����捞�Ώۏ����̕s��ɑΉ�
 *  2009/02/20    1.2   S.Miyakoshi      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/04/30    1.3   T.Kitajima       [T1_0268]CHAR���ڂ�TRIM�Ή�
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- �N�C�b�N�R�[�h�擾�G���[
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A02C';      -- �p�b�P�[�W��
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';             -- �A�v���P�[�V������
--
  -- �v���t�@�C��
  -- XXCOS:�����f�[�^�捞�p�[�W�������Z�o�����
  cv_prf_purge_date  CONSTANT VARCHAR2(50)  := 'XXCOS1_PAYMENT_PURGE_DATE';
  -- XXCOS:MAX���t
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
--
  -- �G���[�R�[�h
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�����G���[
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX���t
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- �Q�ƃR�[�h�}�X�^
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10051';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10052';  -- �}�X�^�`�F�b�N�G���[
  cv_msg_class       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10053';  -- �����敪�G���[
  cv_msg_minus       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10054';  -- �}�C�i�X���z�G���[
  cv_msg_prd         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10055';  -- ��������v���ԃ`�F�b�N
  cv_msg_ftr         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10056';  -- �������������`�F�b�N
  cv_msg_colm        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10057';  -- �K�{���ڃG���[
  cv_msg_status      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10058';  -- �ڋq�X�e�[�^�X�G���[
  cv_msg_base        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10060';  -- �ڋq�̔��㋒�_�R�[�h�G���[
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10061';  -- �f�[�^�ǉ��G���[���b�Z�[�W
  cv_msg_del         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10062';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_busi        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10063';  -- �Ƒԁi�����ށj�G���[
  cv_msg_purge       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10064';  -- �����f�[�^�捞�p�[�W�������Z�o���
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10065';  -- �Ɩ��������擾�G���[
  cv_msg_pay_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10066';  -- �����e�[�u��
  cv_msg_paywk_tab   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10067';  -- �������[�N�e�[�u��
  cv_msg_err_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10068';  -- HHT�G���[���X�g���[���[�N�e�[�u��
  cv_msg_base_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10069';  -- ���_�R�[�h
  cv_msg_cus_num     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10070';  -- �ڋq�R�[�h
  cv_msg_pay_class   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10071';  -- �����敪
  cv_msg_pay_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10072';  -- ������
  cv_msg_pay_amount  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10073';  -- �����z
  cv_msg_data_name   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10074';  -- �����f�[�^
  cv_msg_del_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10075';  -- �폜����
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10076';  -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cust_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10077';  -- �ڋq�X�e�[�^�X
  cv_msg_busi_low    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10078';  -- �Ƒԁi�����ށj
  cv_msg_parameter   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N��
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u����
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';            -- �e�[�u����
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';              -- �N�C�b�N�R�[�h�^�C�v
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';             -- ����
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';           -- �v���t�@�C����
  cv_tkn_del_flag    CONSTANT VARCHAR2(1)   := 'N';
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';
--
  cv_general         CONSTANT VARCHAR2(1)   := NULL;                -- �S�ݓX�pHHT�敪��NULL�F��ʋ��_
  cv_depart          CONSTANT VARCHAR2(1)   := '1';                 -- �S�ݓX�pHHT�敪��1�F�S�ݓX
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_typ_class   CONSTANT VARCHAR2(30)  := 'XXCOS1_RECEIPT_MONEY_CLASS';      -- �����敪
  cv_qck_typ_busi    CONSTANT VARCHAR2(30)  := 'XXCOS1_GYOTAI_SHO_MST_001_A02';   -- �Ƒԁi�����ށj
  cv_qck_typ_status  CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_STATUS_MST_001_A02';   -- �ڋq�X�e�[�^�X
  cv_qck_typ_cus     CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_CLASS_MST_001_A02';    -- �ڋq�敪
  cv_qck_typ_a02     CONSTANT VARCHAR2(30)  := 'XXCOS_001_A02_%';
--
  --�t�H�[�}�b�g
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE�`��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �������[�N�e�[�u���f�[�^�i�[�p�ϐ�
  TYPE g_rec_payment_data IS RECORD
    (
      line_id          xxcos_payment.line_id%TYPE,           -- ����ID
      base_code        xxcos_payment.base_code%TYPE,         -- ���_�R�[�h
      customer_number  xxcos_payment.customer_number%TYPE,   -- �ڋq�R�[�h
      payment_amount   xxcos_payment.payment_amount%TYPE,    -- �����z
      payment_date     xxcos_payment.payment_date%TYPE,      -- ������
      payment_class    xxcos_payment.payment_class%TYPE,     -- �����敪
      hht_invoice_no   xxcos_payment.hht_invoice_no%TYPE     -- HHT�`�[No
    );
  TYPE g_tab_payment_data IS TABLE OF g_rec_payment_data INDEX BY PLS_INTEGER;
--
  -- �����f�[�^�o�^�p�ϐ�
  TYPE g_tab_pay_base_code           IS TABLE OF xxcos_payment.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���_�R�[�h
  TYPE g_tab_pay_customer_number     IS TABLE OF xxcos_payment.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�R�[�h
  TYPE g_tab_pay_payment_amount      IS TABLE OF xxcos_payment.payment_amount%TYPE
    INDEX BY PLS_INTEGER;   -- �����z
  TYPE g_tab_pay_payment_date        IS TABLE OF xxcos_payment.payment_date%TYPE
    INDEX BY PLS_INTEGER;   -- ������
  TYPE g_tab_pay_payment_class       IS TABLE OF xxcos_payment.payment_class%TYPE
    INDEX BY PLS_INTEGER;   -- �����敪
  TYPE g_tab_pay_hht_invoice_no      IS TABLE OF xxcos_payment.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT�`�[No
--
  -- �G���[�f�[�^�i�[�p�ϐ�
  TYPE g_tab_err_base_code           IS TABLE OF xxcos_rep_hht_err_list.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���_�R�[�h
  TYPE g_tab_err_base_name           IS TABLE OF xxcos_rep_hht_err_list.base_name%TYPE
    INDEX BY PLS_INTEGER;   -- ���_����
  TYPE g_tab_err_entry_number        IS TABLE OF xxcos_rep_hht_err_list.entry_number%TYPE
    INDEX BY PLS_INTEGER;   -- �`�[NO
  TYPE g_tab_err_party_num           IS TABLE OF xxcos_rep_hht_err_list.party_num%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�R�[�h
  TYPE g_tab_err_customer_name       IS TABLE OF xxcos_rep_hht_err_list.customer_name%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq��
  TYPE g_tab_err_payment_dlv_date    IS TABLE OF xxcos_rep_hht_err_list.payment_dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- ����/�[�i��
  TYPE g_tab_err_payment_class_name  IS TABLE OF xxcos_rep_hht_err_list.payment_class_name%TYPE
    INDEX BY PLS_INTEGER;   -- �����敪����
  TYPE g_tab_err_error_message       IS TABLE OF xxcos_rep_hht_err_list.error_message%TYPE
    INDEX BY PLS_INTEGER;   -- �G���[���e
--
  -- �K��E�L�����ѓo�^�p�ϐ�
  TYPE g_tab_resource_id             IS TABLE OF jtf_rs_resource_extns.resource_id%TYPE
    INDEX BY PLS_INTEGER;   -- ���\�[�XID
  TYPE g_tab_party_id                IS TABLE OF hz_parties.party_id%TYPE
    INDEX BY PLS_INTEGER;   -- �p�[�e�BID
  TYPE g_tab_party_name              IS TABLE OF hz_parties.party_name%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq����
  TYPE g_tab_cus_status              IS TABLE OF hz_parties.duns_number_c%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�X�e�[�^�X
--
  -- �N�C�b�N�R�[�h�i�[�p
  -- �ڋq�X�e�[�^�X�i�[�p�ϐ�
  TYPE g_tab_qck_status  IS TABLE OF hz_parties.duns_number_c%TYPE INDEX BY PLS_INTEGER;
  -- �Ƒԁi�����ށj�i�[�p�ϐ�
  TYPE g_tab_qck_busi    IS TABLE OF xxcmm_cust_accounts.business_low_type%TYPE INDEX BY PLS_INTEGER;
  -- �����敪�i�[�p�ϐ�
  TYPE g_rec_pay_class IS RECORD
    (
      payment_class    xxcos_payment.payment_class%TYPE,                  -- �����敪
      pay_class_name   xxcos_rep_hht_err_list.payment_class_name%TYPE     -- �����敪����
    );
  TYPE g_tab_qck_class   IS TABLE OF g_rec_pay_class INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����e�[�u���o�^�f�[�^
  gt_pay_base_code        g_tab_pay_base_code;           -- ���_�R�[�h
  gt_pay_customer_number  g_tab_pay_customer_number;     -- �ڋq�R�[�h
  gt_pay_payment_amount   g_tab_pay_payment_amount;      -- �����z
  gt_pay_payment_date     g_tab_pay_payment_date;        -- ������
  gt_pay_payment_class    g_tab_pay_payment_class;       -- �����敪
  gt_pay_hht_invoice_no   g_tab_pay_hht_invoice_no;      -- HHT�`�[No
  -- HHT�G���[���X�g���[���[�N�e�[�u���o�^�f�[�^
  gt_err_base_code        g_tab_err_base_code;           -- ���_�R�[�h
  gt_err_base_name        g_tab_err_base_name;           -- ���_����
  gt_err_entry_number     g_tab_err_entry_number;        -- �`�[NO
  gt_err_party_num        g_tab_err_party_num;           -- �ڋq�R�[�h
  gt_err_cus_name         g_tab_err_customer_name;       -- �ڋq��
  gt_err_pay_dlv_date     g_tab_err_payment_dlv_date;    -- ����/�[�i��
  gt_err_pay_class_name   g_tab_err_payment_class_name;  -- �����敪����
  gt_err_error_message    g_tab_err_error_message;       -- �G���[���e
--
  -- �K��E�L�����ѓo�^�p�ϐ�
  gt_resource_id          g_tab_resource_id;             -- ���\�[�XID
  gt_party_id             g_tab_party_id;                -- �p�[�e�BID
  gt_party_name           g_tab_party_name;              -- �ڋq����
  gt_cus_status           g_tab_cus_status;              -- �ڋq�X�e�[�^�X
--
  gt_payment_work_data    g_tab_payment_data;            -- �������[�N�e�[�u�����o�f�[�^
  gt_qck_status           g_tab_qck_status;              -- �ڋq�X�e�[�^�X
  gt_qck_busi             g_tab_qck_busi;                -- �Ƒԁi�����ށj
  gt_qck_class            g_tab_qck_class;               -- �����敪
  gn_purge_date           NUMBER;                        -- �p�[�W�������
  gd_process_date         DATE;                          -- �Ɩ�������
  gd_max_date             DATE;                          -- MAX���t
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_application_ccp CONSTANT VARCHAR2(5)   := 'XXCCP';                  -- �A�v���P�[�V������
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
    --==============================================================
    --�u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    --==============================================================
    --�u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W�����O�o��
    --==============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- ���b�Z�[�W���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : payment_data_receive
   * Description      : �������[�N�e�[�u���������f�[�^���o(A-1)
   ***********************************************************************************/
  PROCEDURE payment_data_receive(
    on_target_cnt     OUT NUMBER,                --   ���o����
    ov_errbuf         OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_receive'; -- �v���O������
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
    lv_purge_date    VARCHAR2(5);   -- �p�[�W�����Z�o���
    ld_process_date  DATE;          -- �Ɩ�������
    lv_max_date      VARCHAR2(50);  -- MAX���t
    lv_tkn           VARCHAR2(50);  -- �G���[���b�Z�[�W�p�g�[�N��
    lv_tkn2          VARCHAR2(50);  -- �G���[���b�Z�[�W�p�g�[�N��2
    lv_tkn3          VARCHAR2(50);  -- �G���[���b�Z�[�W�p�g�[�N��3
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �������[�N�e�[�u���f�[�^���o
    CURSOR get_payment_data_cur
    IS
--****************************** 2009/04/30 1.3 T.Kitajima MOD START ******************************--
--      SELECT xpw.line_id          line_id,           -- ����ID
--             xpw.base_code        base_code,         -- ���_�R�[�h
--             xpw.customer_number  customer_number,   -- �ڋq�R�[�h
--             xpw.payment_amount   payment_amount,    -- �����z
--             xpw.payment_date     payment_date,      -- ������
--             xpw.payment_class    payment_class,     -- �����敪
--             xpw.hht_invoice_no   hht_invoice_no     -- HHT�`�[No
--      FROM   xxcos_payment_work   xpw                -- �������[�N�e�[�u��
--      FOR UPDATE NOWAIT;
--
      SELECT xpw.line_id                  line_id,           -- ����ID
             TRIM( xpw.base_code )        base_code,         -- ���_�R�[�h
             TRIM( xpw.customer_number )  customer_number,   -- �ڋq�R�[�h
             xpw.payment_amount           payment_amount,    -- �����z
             xpw.payment_date             payment_date,      -- ������
             TRIM( xpw.payment_class  )   payment_class,     -- �����敪
             TRIM( xpw.hht_invoice_no )   hht_invoice_no     -- HHT�`�[No
      FROM   xxcos_payment_work   xpw                -- �������[�N�e�[�u��
      FOR UPDATE NOWAIT;
--****************************** 2009/04/30 1.3 T.Kitajima MOD  END ******************************--
--
    -- �N�C�b�N�R�[�h�F�ڋq�X�e�[�^�X�擾
    CURSOR get_cus_status_cur
    IS
      SELECT  look_val.meaning      meaning
      FROM    fnd_lookup_values     look_val,
              fnd_lookup_types_tl   types_tl,
              fnd_lookup_types      types,
              fnd_application_tl    appl,
              fnd_application       app
      WHERE   appl.application_id   = types.application_id
      AND     look_val.language     = USERENV( 'LANG' )
      AND     appl.language         = USERENV( 'LANG' )
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     app.application_id    = appl.application_id
      AND     app.application_short_name = cv_application
      AND     look_val.lookup_type = cv_qck_typ_status
      AND     look_val.lookup_code LIKE cv_qck_typ_a02
      AND     types.lookup_type = types_tl.lookup_type
      AND     types.security_group_id = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     types_tl.language = USERENV( 'LANG' );
--
    -- �N�C�b�N�R�[�h�F�Ƒԁi�����ށj�擾
    CURSOR get_gyotai_sho_cur
    IS
      SELECT  look_val.meaning      meaning
      FROM    fnd_lookup_values     look_val,
              fnd_lookup_types_tl   types_tl,
              fnd_lookup_types      types,
              fnd_application_tl    appl,
              fnd_application       app
      WHERE   appl.application_id   = types.application_id
      AND     look_val.language     = USERENV( 'LANG' )
      AND     appl.language         = USERENV( 'LANG' )
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     app.application_id    = appl.application_id
      AND     app.application_short_name = cv_application
      AND     look_val.lookup_type = cv_qck_typ_busi
      AND     look_val.lookup_code LIKE cv_qck_typ_a02
      AND     types.lookup_type = types_tl.lookup_type
      AND     types.security_group_id = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     types_tl.language = USERENV( 'LANG' );
--
    -- �N�C�b�N�R�[�h�F�����敪�擾
    CURSOR get_pay_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code,
              look_val.meaning      meaning
      FROM    fnd_lookup_values     look_val,
              fnd_lookup_types_tl   types_tl,
              fnd_lookup_types      types,
              fnd_application_tl    appl,
              fnd_application       app
      WHERE   appl.application_id   = types.application_id
      AND     look_val.language     = USERENV( 'LANG' )
      AND     appl.language         = USERENV( 'LANG' )
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     app.application_id    = appl.application_id
      AND     look_val.lookup_type  = cv_qck_typ_class
      AND     app.application_short_name = cv_application
      AND     types.lookup_type = types_tl.lookup_type
      AND     types.security_group_id = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     types_tl.language     = USERENV( 'LANG' )
      AND     look_val.attribute1   = cv_tkn_yes;
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
    -- ���o����������
    on_target_cnt := 0;
--
    --==============================================================
    -- �v���t�@�C���̎擾
    -- (�����f�[�^�捞�p�[�W�������Z�o���)
    --==============================================================
    lv_purge_date := FND_PROFILE.VALUE( cv_prf_purge_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_purge_date IS NULL ) THEN
      lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, lv_tkn );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gn_purge_date := TO_NUMBER( lv_purge_date );
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾(XXCOS:MAX���t)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_max_date IS NULL ) THEN
      lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, lv_tkn );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==============================================================
    -- ���ʊ֐����Ɩ��������擾���̌Ăяo��
    --==============================================================
     ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- �N�C�b�N�R�[�h�̎擾
    --==============================================================
    -- �ڋq�X�e�[�^�X�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_cus_status_cur;
      -- �o���N�t�F�b�`
      FETCH get_cus_status_cur BULK COLLECT INTO gt_qck_status;
      -- �J�[�\��CLOSE
      CLOSE get_cus_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�ڋq�X�e�[�^�X�擾
        IF ( get_cus_status_cur%ISOPEN ) THEN
          CLOSE get_cus_status_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_status );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cust_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- �Ƒԁi�����ށj�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_gyotai_sho_cur;
      -- �o���N�t�F�b�`
      FETCH get_gyotai_sho_cur BULK COLLECT INTO gt_qck_busi;
      -- �J�[�\��CLOSE
      CLOSE get_gyotai_sho_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�Ƒԁi�����ށj�擾
        IF ( get_gyotai_sho_cur%ISOPEN ) THEN
          CLOSE get_gyotai_sho_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_busi );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi_low );
--
        RAISE lookup_types_expt;
    END;
--
    -- �����敪�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_pay_class_cur;
      -- �o���N�t�F�b�`
      FETCH get_pay_class_cur BULK COLLECT INTO gt_qck_class;
      -- �J�[�\��CLOSE
      CLOSE get_pay_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�����敪�擾
        IF ( get_pay_class_cur%ISOPEN ) THEN
          CLOSE get_pay_class_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_class );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_class );
--
        RAISE lookup_types_expt;
    END;
--
    --==============================================================
    -- �������[�N�e�[�u���f�[�^�擾
    --==============================================================
    BEGIN
--
      -- �J�[�\��OPEN
      OPEN  get_payment_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_payment_data_cur BULK COLLECT INTO gt_payment_work_data;
      -- ���o�����Z�b�g
      on_target_cnt := get_payment_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_payment_data_cur;
--
    EXCEPTION
--
      -- ���b�N�G���[
      WHEN lock_expt THEN
        lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn );
        lv_errbuf  := lv_errmsg;
--
        -- �J�[�\��CLOSE�F�������[�N�e�[�u���f�[�^�擾
        IF ( get_payment_data_cur%ISOPEN ) THEN
          CLOSE get_payment_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- �G���[�����i�f�[�^���o�G���[�j
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
--
        -- �J�[�\��CLOSE�F�������[�N�e�[�u���f�[�^�擾
        IF ( get_payment_data_cur%ISOPEN ) THEN
          CLOSE get_payment_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN lookup_types_expt THEN
      lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  lv_tkn,
                                                                                cv_tkn_type,   lv_tkn2,
                                                                                cv_tkn_colmun, lv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END payment_data_receive;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_check
   * Description      : ���o�����f�[�^�̑Ó����`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE payment_data_check(
    on_target_cnt    IN  NUMBER,                --   ���o����
    ov_errbuf        OUT VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_check'; -- �v���O������
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
    cv_default   CONSTANT VARCHAR2(1) := '0';
    cv_hit       CONSTANT VARCHAR2(1) := '1';
    cv_month     CONSTANT VARCHAR2(5) := 'MONTH';
    cv_ar_class  CONSTANT VARCHAR2(2) := '02';
    cv_open      CONSTANT VARCHAR2(4) := 'OPEN';
--
    -- *** ���[�J���ϐ� ***
    lt_line_id          xxcos_payment.line_id%TYPE;                     -- ����ID
    lt_base_code        xxcos_payment.base_code%TYPE;                   -- ���_�R�[�h
    lt_customer_number  xxcos_payment.customer_number%TYPE;             -- �ڋq�R�[�h
    lt_payment_amount   xxcos_payment.payment_amount%TYPE;              -- �����z
    lt_payment_date     xxcos_payment.payment_date%TYPE;                -- ������
    lt_payment_class    xxcos_payment.payment_class%TYPE;               -- �����敪
    lt_hht_invoice_no   xxcos_payment.hht_invoice_no%TYPE;              -- HHT�`�[No
    lt_base_name        xxcos_rep_hht_err_list.base_name%TYPE;          -- ���_����
    lt_customer_name    xxcos_rep_hht_err_list.customer_name%TYPE;      -- �ڋq��
    lt_pay_class_name   xxcos_rep_hht_err_list.payment_class_name%TYPE; -- �����敪����
    lt_error_message    xxcos_rep_hht_err_list.error_message%TYPE;      -- �G���[���e
    lv_err_flag         VARCHAR2(1)  DEFAULT  '0';                      -- �G���[�t���O
    lt_sale_base        xxcmm_cust_accounts.sale_base_code%TYPE;        -- ���㋒�_�R�[�h
    lt_past_sale_base   xxcmm_cust_accounts.past_sale_base_code%TYPE;   -- �O�����㋒�_�R�[�h
    lt_cus_status       hz_parties.duns_number_c%TYPE;                  -- �ڋq�X�e�[�^�X
    lt_bus_low_type     xxcmm_cust_accounts.business_low_type%TYPE;     -- �Ƒԁi�����ށj
    ln_err_no           NUMBER  DEFAULT  '1';                           -- �G���[�z��i���o�[
    ln_ok_no            NUMBER  DEFAULT  '1';                           -- ����l�z��i���o�[
    lv_tkn              VARCHAR2(50);                                   -- �G���[���b�Z�[�W�p�g�[�N��
    lv_status           VARCHAR2(5);                                    -- AR��v���ԃ`�F�b�N�F�X�e�[�^�X�̎��
    ln_from_date        DATE;                                           -- AR��v���ԃ`�F�b�N�F��v�iFROM�j
    ln_to_date          DATE;                                           -- AR��v���ԃ`�F�b�N�F��v�iTO�j
    lt_resource_id      jtf_rs_resource_extns.resource_id%TYPE;         -- ���\�[�XID
    lt_party_id         hz_parties.party_id%TYPE;                       -- �p�[�e�BID
    lt_hht_class        xxcmm_cust_accounts.dept_hht_div%TYPE;          -- �S�ݓX�pHHT�敪
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
    -- ���[�v�J�n
    FOR ck_no IN 1..on_target_cnt LOOP
--
      -- �G���[�t���O������
      lv_err_flag := cv_default;
--
      -- �f�[�^�擾
      lt_line_id         := gt_payment_work_data(ck_no).line_id;                -- ����ID
      lt_base_code       := gt_payment_work_data(ck_no).base_code;              -- ���_�R�[�h
      lt_customer_number := gt_payment_work_data(ck_no).customer_number;        -- �ڋq�R�[�h
      lt_payment_amount  := gt_payment_work_data(ck_no).payment_amount;         -- �����z
      lt_payment_date    := TRUNC( gt_payment_work_data(ck_no).payment_date );  -- ������
      lt_payment_class   := gt_payment_work_data(ck_no).payment_class;          -- �����敪
      lt_hht_invoice_no  := gt_payment_work_data(ck_no).hht_invoice_no;         -- HHT�`�[No
      lt_base_name       := NULL;                                               -- ���_���̂�������
      lt_customer_name   := NULL;                                               -- �ڋq����������
      lt_pay_class_name  := NULL;                                               -- �����敪���̂�������
--
      --==============================================================
      -- �����敪�̑Ó����`�F�b�N
      --==============================================================
      --== �K�{���ڃ`�F�b�N�F�����敪 ==--
      IF ( lt_payment_class IS NULL ) THEN
        -- ���O�o��
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_class );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
        gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
        gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
        gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
        gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
        gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
        gt_err_pay_class_name(ln_err_no)   :=  NULL;                         -- �����敪����
        gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      ELSE
        -- �����敪�Ó����`�F�b�N
        FOR k IN 1..gt_qck_class.COUNT LOOP
          lt_pay_class_name := gt_qck_class(k).pay_class_name;  -- �����敪���̎擾
          EXIT WHEN gt_qck_class(k).payment_class = lt_payment_class;
          IF ( k = gt_qck_class.COUNT ) THEN
            -- �����敪���̎擾�s��
            lt_pay_class_name := NULL;
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_class );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
            gt_err_base_code(ln_err_no)        :=  lt_base_code;                   -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                   -- ���_����
            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;              -- �`�[NO
            gt_err_party_num(ln_err_no)        :=  lt_customer_number;             -- �ڋq�R�[�h
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;               -- �ڋq��
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;                -- ����/�[�i��
            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;              -- �����敪����
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );    -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
        END LOOP;
      END IF;
--
      --==============================================================
      -- ���_�R�[�h�A�ڋq�R�[�h�̑Ó����`�F�b�N
      --==============================================================
      BEGIN
        --== �K�{���ڃ`�F�b�N�F���_�R�[�h�A�ڋq�R�[�h�A������ ==--
        IF ( ( lt_base_code IS NULL ) OR ( lt_customer_number IS NULL ) OR ( lt_payment_date IS NULL ) ) THEN
--
          -- ���_�R�[�h��NULL�̏ꍇ
          IF ( lt_base_code IS NULL ) THEN
            -- ���O�o��
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
          -- �ڋq�R�[�h��NULL�̏ꍇ
          IF ( lt_customer_number IS NULL ) THEN
            -- ���O�o��
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_num );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
          -- ��������NULL�̏ꍇ
          IF ( lt_payment_date IS NULL ) THEN
            -- ���O�o��
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_date );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
        ELSE
          --== �ڋq�}�X�^�f�[�^���o ==--
          SELECT parties.party_name           party_name,           -- �ڋq����
                 parties.party_id             party_id,             -- �p�[�e�BID
                 custadd.sale_base_code       sale_base_code,       -- ���㋒�_�R�[�h
                 custadd.past_sale_base_code  past_sale_base,       -- �O�����㋒�_�R�[�h
                 parties.duns_number_c        customer_status,      -- �ڋq�X�e�[�^�X
                 custadd.business_low_type    business_low_type,    -- �Ƒԁi�����ށj
                 base.account_name            account_name,         -- ���_����
                 baseadd.dept_hht_div         dept_hht_div,         -- �S�ݓX�pHHT�敪
                 salesreps.resource_id        resource_id           -- ���\�[�XID
          INTO   lt_customer_name,
                 lt_party_id,
                 lt_sale_base,
                 lt_past_sale_base,
                 lt_cus_status,
                 lt_bus_low_type,
                 lt_base_name,
                 lt_hht_class,
                 lt_resource_id
          FROM   hz_cust_accounts     cust,                    -- �ڋq�}�X�^
                 hz_cust_accounts     base,                    -- ���_�}�X�^
                 hz_parties           parties,                 -- �p�[�e�B
                 xxcmm_cust_accounts  custadd,                 -- �ڋq�ǉ����_�ڋq
                 xxcmm_cust_accounts  baseadd,                 -- �ڋq�ǉ����_���_
                 xxcos_salesreps_v    salesreps,               -- �S���c�ƈ�view
                 (
                   SELECT  look_val.meaning      cus
                   FROM    fnd_lookup_values     look_val,
                           fnd_lookup_types_tl   types_tl,
                           fnd_lookup_types      types,
                           fnd_application_tl    appl,
                           fnd_application       app
                   WHERE   appl.application_id   = types.application_id
                   AND     app.application_id    = appl.application_id
                   AND     types_tl.lookup_type  = look_val.lookup_type
                   AND     types.lookup_type     = types_tl.lookup_type
                   AND     types.security_group_id   = types_tl.security_group_id
                   AND     types.view_application_id = types_tl.view_application_id
                   AND     types_tl.language = USERENV( 'LANG' )
                   AND     look_val.language = USERENV( 'LANG' )
                   AND     appl.language     = USERENV( 'LANG' )
                   AND     app.application_short_name = cv_application
                   AND     look_val.lookup_type = cv_qck_typ_cus
                   AND     look_val.lookup_code LIKE cv_qck_typ_a02
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_yes
                 ) cus_class,    -- �ڋq�敪�i'10'(�ڋq) , '12'(��l)�j
                 (
                   SELECT  look_val.meaning      base
                   FROM    fnd_lookup_values     look_val,
                           fnd_lookup_types_tl   types_tl,
                           fnd_lookup_types      types,
                           fnd_application_tl    appl,
                           fnd_application       app
                   WHERE   appl.application_id   = types.application_id
                   AND     app.application_id    = appl.application_id
                   AND     types_tl.lookup_type  = look_val.lookup_type
                   AND     types.lookup_type     = types_tl.lookup_type
                   AND     types.security_group_id   = types_tl.security_group_id
                   AND     types.view_application_id = types_tl.view_application_id
                   AND     types_tl.language = USERENV( 'LANG' )
                   AND     look_val.language = USERENV( 'LANG' )
                   AND     appl.language     = USERENV( 'LANG' )
                   AND     app.application_short_name = cv_application
                   AND     look_val.lookup_type = cv_qck_typ_cus
                   AND     look_val.lookup_code LIKE cv_qck_typ_a02
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute2   = cv_tkn_yes
                 ) base_class    -- �ڋq�敪�i'1'(���_)�j
          WHERE  cust.cust_account_id     = custadd.customer_id    -- �ڋq�}�X�^.�ڋqID = �ڋq�ǉ����_�ڋq.�ڋqID
            AND  cust.customer_class_code = cus_class.cus          -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq) or '12'(��l)
            AND  cust.account_number      = lt_customer_number     -- �ڋq�}�X�^.�ڋq�R�[�h = ���o�����ڋq�R�[�h
            AND  cust.party_id            = parties.party_id       -- �ڋq�}�X�^.�p�[�e�BID=�p�[�e�B.�p�[�e�BID
            AND  custadd.sale_base_code   = base.account_number    -- �ڋq�ǉ����_�ڋq.���㋒�_=���_�}�X�^.�ڋq�R�[�h
            AND  base.cust_account_id     = baseadd.customer_id    -- ���_�}�X�^.�ڋqID=�ڋq�ǉ����_���_.�ڋqID
            AND  base.customer_class_code = base_class.base        -- ���_�}�X�^.�ڋq�敪 = '1'(���_)
            AND  (
                    salesreps.account_number = lt_customer_number  -- �S���c�ƈ�view.�ڋq�ԍ� = ���o�����ڋq�R�[�h
                  AND                                              -- �������̓K�p�͈�
                    lt_payment_date >= NVL(salesreps.effective_start_date, gd_process_date)
                  AND
                    lt_payment_date <= NVL(salesreps.effective_end_date, gd_max_date)
                 )
          ;
--
          --== �ڋq�X�e�[�^�X�`�F�b�N ==--
          FOR i IN 1..gt_qck_status.COUNT LOOP
            EXIT WHEN gt_qck_status(i) = lt_cus_status;
            IF ( i = gt_qck_status.COUNT ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_status );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
              gt_err_base_code(ln_err_no)        :=  lt_base_code;               -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        :=  lt_base_name;               -- ���_����
              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;          -- �`�[NO
              gt_err_party_num(ln_err_no)        :=  lt_customer_number;         -- �ڋq�R�[�h
              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;           -- �ڋq��
              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;            -- ����/�[�i��
              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;          -- �����敪����
              gt_err_error_message(ln_err_no)    :=  SUBSTRB(lv_errmsg, 1, 60);  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== ���㋒�_�R�[�h�`�F�b�N ==--
          -- ���㋒�_�R�[�h�ƑO�����㋒�_�R�[�h�̎g�p����
          IF ( TRUNC( lt_payment_date, cv_month ) < TRUNC( gd_process_date, cv_month ) ) THEN
            lt_sale_base := NVL( lt_past_sale_base, lt_sale_base );
          END IF;
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
          -- ��ʋ��_�̏ꍇ
--      IF ( lt_hht_class = cv_general ) THEN
        IF ( lt_hht_class IS NULL ) THEN
            -- ���㋒�_�R�[�h�Ó����`�F�b�N
            IF ( lt_sale_base != lt_base_code ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
              gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
              gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
              gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END IF;
--
          --== �Ƒԁi�����ށj�`�F�b�N ==--
          FOR j IN 1..gt_qck_busi.COUNT LOOP
--          EXIT WHEN gt_qck_busi(j) = lt_bus_low_type;
--          IF ( j = gt_qck_busi.COUNT ) THEN
            IF ( gt_qck_busi(j) = lt_bus_low_type ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
              gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
              gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
              gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
  /*-----2009/02/03-----END-------------------------------------------------------------------------------*/
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
      END;
--
      --==============================================================
      -- �������̑Ó����`�F�b�N
      --==============================================================
      IF ( lt_payment_date IS NOT NULL ) THEN
        --== AR��v���ԃ`�F�b�N ==--
        -- ���ʊ֐�����v���ԏ��擾��
        xxcos_common_pkg.get_account_period(
          cv_ar_class         -- 02:AR
         ,lt_payment_date     -- ������
         ,lv_status           -- �X�e�[�^�X(OPEN or CLOSE)
         ,ln_from_date        -- ��v�iFROM�j
         ,ln_to_date          -- ��v�iTO�j
         ,lv_errbuf           -- �G���[�E���b�Z�[�W
         ,lv_retcode          -- ���^�[���E�R�[�h
         ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
--
        --�G���[�`�F�b�N
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
--
        -- AR��v���Ԕ͈͊O�̏ꍇ
        IF ( lv_status != cv_open ) THEN
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_prd );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
--
        --== �������`�F�b�N ==--
        IF ( lt_payment_date > gd_process_date ) THEN
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_ftr );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
      END IF;
--
      --==============================================================
      -- �����z�̑Ó����`�F�b�N
      --==============================================================
      --== �K�{���ڃ`�F�b�N�F�����z ==--
      IF ( lt_payment_amount IS NULL ) THEN
        -- ���O�o��
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_amount );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
        gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
        gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
        gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
        gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
        gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
        gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
        gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      ELSE
        -- �}�C�i�X���z�A�y��0�~�`�F�b�N
        IF ( lt_payment_amount <= 0 ) THEN
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_minus );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- ���_����
          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- �`�[NO
          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- �ڋq�R�[�h
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- �ڋq��
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- ����/�[�i��
          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- �����敪����
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
      END IF;
--
      --==============================================================
      -- �����f�[�^��ϐ��֊i�[
      --==============================================================
      IF ( lv_err_flag = cv_default ) THEN
        gt_pay_base_code(ln_ok_no)        :=  lt_sale_base;          -- ���_�R�[�h
        gt_pay_customer_number(ln_ok_no)  :=  lt_customer_number;    -- �ڋq�R�[�h
        gt_pay_payment_amount(ln_ok_no)   :=  lt_payment_amount;     -- �����z
        gt_pay_payment_date(ln_ok_no)     :=  lt_payment_date;       -- ������
        gt_pay_payment_class(ln_ok_no)    :=  lt_payment_class;      -- �����敪
        gt_pay_hht_invoice_no(ln_ok_no)   :=  lt_hht_invoice_no;     -- HHT�`�[No
        gt_resource_id(ln_ok_no)          :=  lt_resource_id;        -- ���\�[�XID
        gt_party_id(ln_ok_no)             :=  lt_party_id;           -- �p�[�e�BID
        gt_party_name(ln_ok_no)           :=  lt_customer_name;      -- �ڋq����
        gt_cus_status(ln_ok_no)           :=  lt_cus_status;         -- �ڋq�X�e�[�^�X
        ln_ok_no := ln_ok_no + 1;
      END IF;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END payment_data_check;
--
  /**********************************************************************************
   * Procedure Name   : error_data_register
   * Description      : �G���[�����Ώۃf�[�^��o�^(A-3)
   ***********************************************************************************/
  PROCEDURE error_data_register(
    on_warn_cnt      OUT NUMBER,              --   �x������
    ov_errbuf        OUT VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_data_register'; -- �v���O������
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
    lv_data_name  VARCHAR2(10);   -- �f�[�^����
    lv_tkn        VARCHAR2(50);   -- �G���[���b�Z�[�W�p�g�[�N��
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
    -- �x������������
    on_warn_cnt := 0;
--
    --==============================================================
    -- HHT�G���[���X�g���[���[�N�e�[�u���փG���[�f�[�^�o�^
    --==============================================================
    -- �f�[�^���̎擾
    lv_data_name := xxccp_common_pkg.get_msg( cv_application, cv_msg_data_name );
--
    -- �G���[�����Z�b�g
    on_warn_cnt := gt_err_base_code.COUNT;
--
    BEGIN
--
      -- �G���[�f�[�^�o�^
      FORALL i IN 1..on_warn_cnt
        INSERT INTO xxcos_rep_hht_err_list
          (
            record_id,
            base_code,
            base_name,
            origin_shipment,
            data_name,
            order_no_hht,
            invoice_invent_date,
            entry_number,
            line_no,
            order_no_ebs,
            party_num,
            customer_name,
            payment_dlv_date,
            payment_class_name,
            performance_by_code,
            item_code,
            error_message,
            report_group_id,
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
        VALUES
          (
            xxcos_rep_hht_err_list_s01.NEXTVAL,          -- ���R�[�hID
            gt_err_base_code(i),                         -- ���_�R�[�h
            gt_err_base_name(i),                         -- ���_����
            NULL,                                        -- �o�ɑ��R�[�h
            lv_data_name,                                -- �f�[�^����
            NULL,                                        -- ��NO�iHHT�j
            NULL,                                        -- �`�[/�I����
            gt_err_entry_number(i),                      -- �`�[NO
            NULL,                                        -- �sNO
            NULL,                                        -- ��NO�iEBS�j
            gt_err_party_num(i),                         -- �ڋq�R�[�h
            gt_err_cus_name(i),                          -- �ڋq��
            gt_err_pay_dlv_date(i),                      -- ����/�[�i��
            gt_err_pay_class_name(i),                    -- �����敪����
            NULL,                                        -- ���ю҃R�[�h
            NULL,                                        -- �i�ڃR�[�h
            gt_err_error_message(i),                     -- �G���[���e
            NULL,                                        -- ���[�p�O���[�vID
            cn_created_by,                               -- �쐬��
            cd_creation_date,                            -- �쐬��
            cn_last_updated_by,                          -- �ŏI�X�V��
            cd_last_update_date,                         -- �ŏI�X�V��
            cn_last_update_login,                        -- �ŏI�X�V���O�C��
            cn_request_id,                               -- �v��ID
            cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                               -- �R���J�����g�E�v���O����ID
            cd_program_update_date                       -- �v���O�����X�V��
          );
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END error_data_register;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_register
   * Description      : �����f�[�^��o�^(A-4)
   ***********************************************************************************/
  PROCEDURE payment_data_register(
    on_normal_cnt    OUT NUMBER,              --   �����f�[�^�쐬����
    ov_errbuf        OUT VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_register'; -- �v���O������
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
    cv_input_class  VARCHAR2(1) DEFAULT '0';  -- ���͋敪
    cv_entry_class  VARCHAR2(1) DEFAULT '4';  -- �K��L�����o�^�FDFF12�i�o�^�敪�j
--
    -- *** ���[�J���ϐ� ***
    ln_pay_cnt      NUMBER;         -- �����f�[�^�쐬����
    lv_tkn          VARCHAR2(50);   -- �G���[���b�Z�[�W�p�g�[�N��
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
    -- �����f�[�^�쐬����������
    on_normal_cnt := 0;
--
    --==============================================================
    -- �����e�[�u���֓����f�[�^�o�^
    --==============================================================
    -- ���ʊ֐����K��L�����o�^��
    FOR i IN 1..gt_party_id.COUNT LOOP
--
      xxcos_task_pkg.task_entry(
        lv_errbuf                 -- �G���[�E���b�Z�[�W
       ,lv_retcode                -- ���^�[���E�R�[�h
       ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,gt_resource_id(i)         -- ���\�[�XID
       ,gt_party_id(i)            -- �p�[�e�BID
       ,gt_party_name(i)          -- �p�[�e�B���́i�ڋq���́j
       ,gt_pay_payment_date(i)    -- �K����� �� ������
       ,NULL                      -- �ڍד��e
       ,0                         -- ������z
       ,cv_input_class            -- ���͋敪
       ,cv_entry_class            -- DFF12�i�o�^�敪�j�� 4
       ,gt_pay_hht_invoice_no(i)  -- DFF13�i�o�^���\�[�X�ԍ��j�� HHT�`�[No
       ,gt_cus_status(i)          -- DFF14�i�ڋq�X�e�[�^�X�j
      );
--
      --�G���[�`�F�b�N
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP;
--
    BEGIN
--
      -- �����f�[�^�o�^
      ln_pay_cnt := gt_pay_base_code.COUNT;
      FORALL i IN 1..ln_pay_cnt
        INSERT INTO xxcos_payment
          (
            line_id,
            base_code,
            customer_number,
            payment_amount,
            payment_date,
            payment_class,
            hht_invoice_no,
            delete_flag,
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
        VALUES
          (
            xxcos_payment_s01.NEXTVAL,                   -- ����ID
            gt_pay_base_code(i),                         -- ���_�R�[�h
            gt_pay_customer_number(i),                   -- �ڋq�R�[�h
            gt_pay_payment_amount(i),                    -- �����z
            gt_pay_payment_date(i),                      -- ������
            gt_pay_payment_class(i),                     -- �����敪
            gt_pay_hht_invoice_no(i),                    -- HHT�`�[No
            cv_tkn_del_flag,                             -- �폜�t���O
            cn_created_by,                               -- �쐬��
            cd_creation_date,                            -- �쐬��
            cn_last_updated_by,                          -- �ŏI�X�V��
            cd_last_update_date,                         -- �ŏI�X�V��
            cn_last_update_login,                        -- �ŏI�X�V���O�C��
            cn_request_id,                               -- �v��ID
            cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                               -- �R���J�����g�E�v���O����ID
            cd_program_update_date                       -- �v���O�����X�V��
          );
--
      -- �����f�[�^�쐬�����Z�b�g
      on_normal_cnt := ln_pay_cnt;
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END payment_data_register;
--
  /**********************************************************************************
   * Procedure Name   : payment_work_delete
   * Description      : �������[�N�e�[�u���̃��R�[�h�폜(A-5)
   ***********************************************************************************/
  PROCEDURE payment_work_delete(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_work_delete'; -- �v���O������
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
    lv_tkn      VARCHAR2(50);   -- �G���[���b�Z�[�W�p�g�[�N��
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
    --==============================================================
    -- �������[�N�e�[�u���̃��R�[�h�폜
    --==============================================================
    BEGIN
--
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_payment_work';
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�폜�G���[�j
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END payment_work_delete;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_delete
   * Description      : �����e�[�u���̕s�v�f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE payment_data_delete(
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_delete'; -- �v���O������
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
    ln_delete_cnt  NUMBER;         -- �폜����
    lv_tkn         VARCHAR2(50);   -- �G���[���b�Z�[�W�p�g�[�N��
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����e�[�u�����b�N
    CURSOR lock_cur
    IS
      SELECT pay.delete_flag  delete_flag
      FROM   xxcos_payment    pay                -- �����e�[�u��
      WHERE  pay.delete_flag = cv_tkn_yes
      AND    TRUNC( pay.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
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
    --==============================================================
    -- �e�[�u�����b�N
    --==============================================================
    OPEN  lock_cur;
    CLOSE lock_cur;
--
    --==============================================================
    -- �����e�[�u���̕s�v�f�[�^�폜
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_payment
      WHERE xxcos_payment.delete_flag = cv_tkn_yes
        AND TRUNC( xxcos_payment.creation_date ) < ( gd_process_date - gn_purge_date );
--
      ln_delete_cnt := SQL%ROWCOUNT;    -- �폜����
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�폜�G���[�j
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- �폜�����o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_count, cv_tkn_count, TO_CHAR( ln_delete_cnt ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END payment_data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn        VARCHAR2(50);   -- �G���[���b�Z�[�W�p�g�[�N��
    ln_error_cnt  NUMBER;         -- �x������
    ln_normal_cnt NUMBER;         -- �����f�[�^�쐬����
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-0)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
      ov_errmsg   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �������[�N�e�[�u���������f�[�^���o (A-1)
    -- ============================================
    payment_data_receive(
      gn_target_cnt,          -- �Ώی���
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
--
    -- �x�������i�Ώۃf�[�^�����G���[�j
    ELSIF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
--
    END IF;
--
    --== �Ώۃf�[�^��1���ȏ゠��ꍇ�AA-2����A-5�̏������s���܂��B ==--
    IF ( gn_target_cnt >= 1 ) THEN
--
      -- ============================================
      -- ���o�����f�[�^�̑Ó����`�F�b�N (A-2)
      -- ============================================
      payment_data_check(
        gn_target_cnt,          -- �Ώی���
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_errbuf   :=  lv_errbuf;
        ov_retcode  :=  lv_retcode;
        ov_errmsg   :=  lv_errmsg;
      END IF;
--
      --�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- �G���[�����Ώۃf�[�^��o�^ (A-3)
      -- ============================================
      -- A-2�̃`�F�b�N�ŃG���[�ƂȂ����f�[�^�ɑ΂��Ĉȉ��̏������s���܂��B
      IF ( gt_err_base_code IS NOT NULL ) THEN
        error_data_register(
          ln_error_cnt,           -- �x������
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        --�G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ============================================
      -- �����f�[�^��o�^ (A-4)
      -- ============================================
      -- A-2�̃`�F�b�N�ŃG���[�ƂȂ�Ȃ������f�[�^�ɑ΂��Ĉȉ��̏������s���B
      IF ( gt_pay_base_code IS NOT NULL ) THEN
        payment_data_register(
          ln_normal_cnt,          -- �����f�[�^�쐬����
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        --�G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ============================================
      -- �������[�N�e�[�u���̃��R�[�h�폜 (A-5)
      -- ============================================
      payment_work_delete(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      --�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �R�~�b�g
      COMMIT;
--
      -- �����Z�b�g
      gn_error_cnt  := ln_error_cnt;    -- �x������
      gn_normal_cnt := ln_normal_cnt;   -- �����f�[�^�쐬����
--
    END IF;
--
    -- ============================================
    -- �����e�[�u���̕s�v�f�[�^�폜 (A-6)
    -- ============================================
    payment_data_delete(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   #####################################################
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #######################################################
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
--###########################  �Œ蕔 START   #####################################################
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
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
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
END XXCOS001A02C;
/
