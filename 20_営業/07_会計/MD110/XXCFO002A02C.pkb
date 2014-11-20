CREATE OR REPLACE PACKAGE BODY XXCFO002A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCFO002A02C(body)
 * Description      : �����F�o��x���˗��f�[�^���o
 * MD.050           : �����F�o��x���˗��f�[�^���o MD050_CFO_002_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_target_data        �Ώۃf�[�^�擾(A-2)
 *  output_data            �f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/15    1.0   SCSK ���� �O��   �V�K�쐬
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFO002A02C'; -- �p�b�P�[�W��
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';                             -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';                                -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                         -- ���t�t�H�[�}�b�g�iYYYY/MM/DD�j
--
  cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');   -- �ŏ����t
  cd_max_date           CONSTANT DATE          := TO_DATE('9999/12/31','YYYY/MM/DD');   -- �ő���t
  cv_userenv_lang       CONSTANT VARCHAR2(10)  := USERENV('LANG');                      -- ����
  cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                                  -- �t���O�uY�v
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(20)  := 'XXCFO';                              -- XXCFO�A�v���P�[�V�����Z�k��
  cv_delimit            CONSTANT VARCHAR2(10)  := ',';                                  -- ��؂蕶��
  cv_enclosed           CONSTANT VARCHAR2(1)   := '"';                                  -- �P��͂ݕ���
  cv_hihun              CONSTANT VARCHAR2(1)   := '-';                                  -- �n�C�t��
  cv_pending_status     CONSTANT VARCHAR2(10)  := '30';                                 -- 30�F����ŏI���F��
  cv_language_ja        CONSTANT VARCHAR2(10)  := 'JA';                                 -- ���o����������'JA'
  --�v���t�@�C��
  cv_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                             -- �g�DID
--
  -- �Q�ƃ^�C�v
  cv_xx03_slip_type     CONSTANT VARCHAR2(30)  := 'XX03_SLIP_TYPES';                    -- �`�[���
  cv_type_csv_header    CONSTANT VARCHAR2(30)  := 'XXCFO1_PAY_SLIP_HEAD';               -- �G�N�Z���o�͗p���o��
  cv_msg_token_001      CONSTANT VARCHAR2(30)  := 'CFO002A02001';                       -- ���b�Z�[�W�g�[�N���F���������t�i���j
  cv_msg_token_002      CONSTANT VARCHAR2(30)  := 'CFO002A02002';                       -- ���b�Z�[�W�g�[�N���F���������t�i���j
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cfo_00015      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';                    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00033      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033';                    -- �R���J�����g�p�����[�^�G���[���b�Z�[�W
  cv_msg_prof_err       CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';                    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_no_data_err    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';                    -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
--
  -- �g�[�N���R�[�h
  cv_tkn_prof            CONSTANT VARCHAR2(10) := 'PROF_NAME';        -- �v���t�@�C���`�F�b�N
  cv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- �召�`�F�b�NFrom �����p
  cv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- �召�`�F�b�NTo �����p
  cv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- �召�`�F�b�NFrom �l�p
  Cv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- �召�`�F�b�NTo �l�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
   gd_process_date            DATE;                                                     -- �Ɩ����t
   gn_org_id                  NUMBER;                                                   -- �g�DID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �Ώۃf�[�^�擾�J�[�\��
  CURSOR get_target_data_cur(  iv_invoice_date_from  VARCHAR2
                              ,iv_invoice_date_to    VARCHAR2
                            )
  IS
  SELECT /*+ USE_NL( xps flv papf xadv )
             INDEX( xps XX03_PAYMENT_SLIPS_N15 )
             USE_NL( xadv.FFLEXVALSET xadv.FFLEXVAL xadv.FFLEXVALTL )
             LEADING( xps ) */
        xps.entry_department || cv_hihun 
            || xadv.aff_department_name   AS entry_department       -- �N�[����
       ,xps.requestor_person_name         AS requestor_person_name  -- �\����
       ,xps.approver_person_name          AS approver_person_name   -- ���F��
       ,xps.invoice_num                   AS invoice_num            -- �`�[�ԍ�
       ,flv.description                   AS invoice_class          -- �`�[���
       ,xps.vendor_name                   AS vendor_name            -- �d����
       ,xps.vendor_invoice_num            AS vendor_invoice_num     -- ��̐������ԍ�
       ,TO_CHAR(xps.invoice_date, cv_format_date_ymd)  AS invoice_date  -- ���������t
       ,TO_CHAR(xps.gl_date, cv_format_date_ymd)       AS gl_date       -- �v���
       ,xps.inv_amount                    AS inv_amount             -- ���v���z
       ,xps.invoice_currency_code         AS invoice_currency_code  -- �ʉ�
  FROM  xx03_payment_slips      xps    -- �x���`�[
       ,fnd_lookup_values       flv    -- �Q�ƃ^�C�v
       ,per_all_people_f        papf   -- �]�ƈ��}�X�^
       ,xxcff_aff_department_v  xadv   -- ����VIEW
  WHERE xps.org_id       = gn_org_id
  AND   xps.wf_status    = cv_pending_status  -- �X�e�[�^�X:30(����ŏI���F��)
  AND   xps.slip_type    = flv.lookup_code
  AND   flv.lookup_type  = cv_xx03_slip_type  -- �`�[���
  AND   flv.language     = cv_language_ja
  AND   flv.enabled_flag = cv_yes
  AND   NVL(flv.start_date_active, xps.entry_date ) <= xps.entry_date
  AND   NVL(flv.end_date_active, xps.entry_date )   >= xps.entry_date
  AND   papf.person_id   = xps.entry_person_id
  AND   papf.effective_start_date <= xps.entry_date
  AND   papf.effective_end_date   >= xps.entry_date
  AND   xadv.aff_department_code   = xps.entry_department
  AND   NVL(xadv.start_date_active, xps.entry_date) <= xps.entry_date
  AND   NVL(xadv.end_date_active,   xps.entry_date) >= xps.entry_date
  AND   NVL(TO_DATE(iv_invoice_date_from, cv_format_date_ymd), xps.invoice_date)
                                      <= xps.invoice_date  -- �p�����[�^���������i���j
  AND   NVL(TO_DATE(iv_invoice_date_to, cv_format_date_ymd), xps.invoice_date)
                                      >= xps.invoice_date  -- �p�����[�^���������i���j
  ORDER BY
        xps.entry_department  -- �N�[����R�[�h
       ,papf.employee_number  -- �\���ҎЈ��ԍ�
       ,xps.invoice_num       -- �`�[�ԍ�
  ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Ώۃf�[�^�擾�J�[�\�����R�[�h�^
  TYPE g_target_data_ttype IS TABLE OF get_target_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_target_data_tab       g_target_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_invoice_date_from IN  VARCHAR2,     --   1.���������t(from)
    iv_invoice_date_to   IN  VARCHAR2,     --   2.���������t(to)
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log     -- ���O�o��
      ,iv_conc_param1  => iv_invoice_date_from -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_invoice_date_to   -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
--
    -- ���ʊ֐�����Ɩ����t���擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�G���[��
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- �A�v���P�[�V�����Z�k��
                                            ,cv_msg_cfo_00015);    -- ���b�Z�[�W�FAPP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���g�DID�擾
    --==============================================================
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_prof_err      -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_org_id);          -- �g�[�N���FORG_ID
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �R���J�����g�p�����[�^�`�F�b�N
    --==============================================================
--
    -- �p�����[�^���������t(from)�Ɛ��������t(to)�̃`�F�b�N
    IF ( iv_invoice_date_from > iv_invoice_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo               -- �A�v���P�[�V�����Z�k���FXXCFO
                                            ,cv_msg_cfo_00033             -- �l�召�`�F�b�N�G���[
                                            ,cv_tkn_param_name_from       -- �g�[�N��'PARAM_NAME_FROM'
                                            ,xxcfr_common_pkg.lookup_dictionary(
                                               cv_msg_kbn_cfo
                                              ,cv_msg_token_001
                                             )                            -- ���������t�i���j
                                            ,cv_tkn_param_name_to         -- �g�[�N��'PARAM_NAME_TO'
                                            ,xxcfr_common_pkg.lookup_dictionary(
                                               cv_msg_kbn_cfo
                                              ,cv_msg_token_002
                                             )                            -- ���������t�i���j
                                            ,cv_tkn_param_val_from        -- �g�[�N��'PARAM_VAL_FROM'
                                            ,iv_invoice_date_from         -- �p�����[�^�F���������t�i���j
                                            ,cv_tkn_param_val_to          -- �g�[�N��'PARAM_VAL_TO'
                                            ,iv_invoice_date_to           -- �p�����[�^�F���������t�i���j
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_target_data
   * Description      : �Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    iv_invoice_date_from IN VARCHAR2,      --   1.���������t(from)
    iv_invoice_date_to   IN VARCHAR2,      --   2.���������t(to)
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �Ώۃf�[�^�擾�J�[�\��
    OPEN  get_target_data_cur( iv_invoice_date_from
                              ,iv_invoice_date_to
                             );
    FETCH get_target_data_cur BULK COLLECT INTO gt_target_data_tab;
    CLOSE get_target_data_cur;
--
    --�Ώی����Z�b�g
    gn_target_cnt := gt_target_data_tab.COUNT;
--
    -- �Ώی���0���̏ꍇ�A�x��
    IF ( gt_target_data_tab.COUNT = 0 ) THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_msg_no_data_err   -- ���b�Z�[�W�FAPP-XXCFO1-00004
                                            ); 
      ov_errbuf  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
      IF( get_target_data_cur%ISOPEN ) THEN
        CLOSE get_target_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR get_csv_header_cur
    IS
      SELECT  flv.description   head
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type  = cv_type_csv_header
      AND     flv.language     = cv_language_ja
      AND     flv.enabled_flag = cv_yes
      AND     NVL(flv.start_date_active, gd_process_date ) <= gd_process_date
      AND     NVL(flv.end_date_active, gd_process_date )   >= gd_process_date
      ORDER BY
              flv.lookup_code
      ;
    -- ���o���p�ϐ���`
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
    lt_head_tab l_head_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  get_csv_header_cur;
    FETCH get_csv_header_cur BULK COLLECT INTO lt_head_tab;
    CLOSE get_csv_header_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_target_data_tab.COUNT LOOP
      --�f�[�^��ҏW
      lv_line_data :=     cv_enclosed || gt_target_data_tab(i).entry_department           || cv_enclosed  -- �N�[����
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).requestor_person_name      || cv_enclosed  -- �\����
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).approver_person_name       || cv_enclosed  -- ���F��
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_num                || cv_enclosed  -- �`�[�ԍ�
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_class              || cv_enclosed  -- �`�[���
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).vendor_name                || cv_enclosed  -- �d����
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).vendor_invoice_num         || cv_enclosed  -- ��̐������ԍ�
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_date               || cv_enclosed  -- ���������t
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).gl_date                    || cv_enclosed  -- �v���
         || cv_delimit                || gt_target_data_tab(i).inv_amount                                 -- ���v���z
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).invoice_currency_code      || cv_enclosed  -- �ʉ�
      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    --
    END LOOP data_output;
--
  EXCEPTION
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
      IF( get_csv_header_cur%ISOPEN ) THEN
        CLOSE get_csv_header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_invoice_date_from IN  VARCHAR2,     --   1.���������t(from)
    iv_invoice_date_to   IN  VARCHAR2,     --   2.���������t(to)
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       iv_invoice_date_from  => iv_invoice_date_from  -- 1.���������t(from)
      ,iv_invoice_date_to    => iv_invoice_date_to    -- 2.���������t(to)
      ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg );          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ώۃf�[�^�擾 (A-2)
    -- =====================================================
    get_target_data(
       iv_invoice_date_from  => iv_invoice_date_from  -- 1.���������t(from)
      ,iv_invoice_date_to    => iv_invoice_date_to    -- 2.���������t(to)
      ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn ) THEN
      -- �x���̏ꍇ�A�X�e�[�^�X�ƃ��b�Z�[�W�𐧌�
      ov_errbuf   := lv_errbuf;
      ov_retcode  := lv_retcode;
      ov_errmsg   := lv_errmsg;
    END IF;
    --
--
    -- =====================================================
    --  �f�[�^�o�� (A-3)
    -- =====================================================
    output_data(
       ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_invoice_date_from  IN  VARCHAR2,      --   1.���������t(from)
    iv_invoice_date_to    IN  VARCHAR2       --   2.���������t(to)
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
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
       iv_invoice_date_from    -- 1.���������t(from)
      ,iv_invoice_date_to      -- 2.���������t(to)
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCFO002A02C;
/
