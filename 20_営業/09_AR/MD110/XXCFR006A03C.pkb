CREATE OR REPLACE PACKAGE BODY XXCFR006A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A03C(body)
 * Description      : �������������iHHT�j
 * MD.050           : MD050_CFR_006_A03_�������������iHHT�j
 * MD.070           : MD050_CFR_006_A03_�������������iHHT�j
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���            (A-1)
 *  get_process_date       p �Ɩ��������t�擾����                    (A-2)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-3)
 *  get_target_credit      p �Ώۍ����z����                        (A-5)
 *  start_apply_api        p ��������API�N������                     (A-7)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.00 SCS ���� ����    ����쐬
 *  2009/02/12    1.1  SCS T.KANEDA     [��QCOK_003] �����z�擾�s��Ή�
 *  2009/07/15    1.2  SCS M.HIROSE     [��Q0000511] �p�t�H�[�}���X���P
 *  2010/01/12    1.3  SCS ���� �q��    ��Q�uE_�{�ғ�_01136�v�Ή�
 *  2011/05/17    1.4  SCS �n�� �w      ��Q�uE_�{�ғ�_07434�v�Ή�
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR006A03C'; -- �p�b�P�[�W��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_006a03_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_006a03_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_006a03_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00036'; --��������API�G���[���b�Z�[�W
-- Modify 2010.01.12 Ver1.3 Start
  cv_msg_006a03_086  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00086'; --�x�������P�\��������`�G���[���b�Z�[�W
  cv_msg_006a03_087  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00087'; --�x�������P�\�������l�G���[���b�Z�[�W
-- Modify 2010.01.12 Ver1.3 End
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_receipt_nm  CONSTANT VARCHAR2(15) := 'RECEIPT_NUMBER';   -- �����ԍ�
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';     -- �ڋq�R�[�h
  cv_tkn_meathod     CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';  -- �x�����@
  cv_tkn_receipt_dt  CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';     -- ������
  cv_tkn_amount      CONSTANT VARCHAR2(15) := 'AMOUNT';           -- �����z
  cv_tkn_trx_nm      CONSTANT VARCHAR2(15) := 'TRX_NUMBER';       -- ����ԍ�
-- Modify 2010.01.12 Ver1.3 Start
  cv_tkn_hht_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';  -- �Q�ƃ^�C�v
  cv_tkn_hht_lookup_code CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';  -- �Q�ƃR�[�h
-- Modify 2010.01.12 Ver1.3 End
--
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';           -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';              -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';   -- ���t�t�H�[�}�b�g�i�N�����j
--
  -- ���e�����l
  cv_status_op        CONSTANT VARCHAR2(10) := 'OP';              -- �X�e�[�^�X�F�I�[�v��
  cv_flag_y           CONSTANT VARCHAR2(10) := 'Y';               -- �t���O�l�FY
--
--
  -- �Q�ƃ^�C�v
-- Modify 2010.01.12 Ver1.3 Start
  cv_hht_receipt_date CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_HHT_RECEIPT_DATE'; -- �Q�ƃ^�C�v�uHHT�����ΏۗP�\���ԁv
  cv_date_from        CONSTANT fnd_lookup_values.lookup_code%TYPE := 'DATE_FROM';               -- �Q�ƃR�[�h�u�x�������O�P�\�����v
  cv_date_to          CONSTANT fnd_lookup_values.lookup_code%TYPE := 'DATE_TO';                 -- �Q�ƃR�[�h�u�x��������P�\�����v
-- Modify 2010.01.12 Ver1.3 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id             NUMBER;             -- �g�DID
  gd_process_date       DATE;               -- �Ɩ��������t
  gd_receipt_date       DATE;               -- ������
-- Modify 2010.01.12 Ver1.3 Start
  gn_hht_date_from      NUMBER;             -- �x�������O�P�\����
  gn_hht_date_to        NUMBER;             -- �x��������P�\����
-- Modify 2010.01.12 Ver1.3 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receipt_date   IN      VARCHAR2,    -- ������
    ov_errbuf         OUT     VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT     VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT     VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���E��O ***
-- Modify 2010.01.12 Ver1.3 Start
    hht_date_from_null_expt   EXCEPTION;  -- �Q�ƃR�[�h�u�x�������O�P�\�����v��`�Ȃ���O
    hht_date_to_null_expt     EXCEPTION;  -- �Q�ƃR�[�h�u�x��������P�\�����v��`�Ȃ���O
    hht_date_from_number_expt EXCEPTION;  -- �Q�ƃR�[�h�u�x�������O�P�\�����v���l��O
    hht_date_to_number_expt   EXCEPTION;  -- �Q�ƃR�[�h�u�x��������P�\�����v���l��O
-- Modify 2010.01.12 Ver1.3 End
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,iv_conc_param1  => iv_receipt_date    -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUT�t�@�C���o��
      ,iv_conc_param1  => iv_receipt_date    -- �R���J�����g�p�����[�^�P
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Modify 2010.01.12 Ver1.3 Start
    -- �Q�ƃR�[�h�u�x�������O�P�\�����v�擾����
    BEGIN
      SELECT NVL(TO_NUMBER(flvv.description),0) description
      INTO gn_hht_date_from
      FROM fnd_lookup_values_vl flvv
      WHERE flvv.lookup_type = cv_hht_receipt_date
        AND flvv.lookup_code = cv_date_from
        AND flvv.enabled_flag = cv_flag_y
        AND SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE hht_date_from_null_expt;
      WHEN INVALID_NUMBER THEN
        RAISE hht_date_from_number_expt;
    END;
--
    -- �Q�ƃR�[�h�u�x��������P�\�����v�擾����
    BEGIN
      SELECT NVL(TO_NUMBER(flvv.description),0) description
      INTO gn_hht_date_to
      FROM fnd_lookup_values_vl flvv
      WHERE flvv.lookup_type = cv_hht_receipt_date
        AND flvv.lookup_code = cv_date_to
        AND flvv.enabled_flag = cv_flag_y
        AND SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE hht_date_to_null_expt;
      WHEN INVALID_NUMBER THEN
        RAISE hht_date_to_number_expt;
    END;
-- Modify 2010.01.12 Ver1.3 End    
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
-- Modify 2010.01.12 Ver1.3 Start
    -- *** �Q�ƃR�[�h�u�x�������O�P�\�����v��`�Ȃ���O�n���h�� ***
    WHEN hht_date_from_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_086,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_from);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Q�ƃR�[�h�u�x��������P�\�����v��`�Ȃ���O�n���h�� ***
    WHEN hht_date_to_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_086,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_to);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Q�ƃR�[�h�u�x�������O�P�\�����v���l��O�n���h�� ***
    WHEN hht_date_from_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_087,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_from);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Q�ƃR�[�h�u�x��������P�\�����v���l��O�n���h�� ***
    WHEN hht_date_to_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_087,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_to);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
-- Modify 2010.01.12 Ver1.3 End
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
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a03_010 -- �Ɩ��������t�擾�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾���� (A-3)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a03_009 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_target_credit
   * Description      : �Ώۍ����z���� (A-5)
   ***********************************************************************************/
  PROCEDURE get_target_credit(
    in_pay_from_customer IN  NUMBER,              -- �ڋqID
    id_receipt_date      IN  DATE,                -- ������
    on_target_credit     OUT NUMBER,              -- �Ώۍ����z
    ov_errbuf            OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_credit'; -- �v���O������
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
    -- �Ώۍ����z������
    on_target_credit := 0;
--
    -- �Ώۍ����z�擾
    SELECT 
-- Delete 2011.05.17 Ver1.4 Start
---- Modify 2009.07.15 Ver1.2 Start
--           /*+ INDEX(rcta RA_CUSTOMER_TRX_N11)
--               INDEX(apsa AR_PAYMENT_SCHEDULES_N2)
--           */
---- Modify 2009.07.15 Ver1.2 End
-- Delete 2011.05.17 Ver1.4 End
-- Add 2011.05.17 Ver1.4 Start
           /*+
               LEADING(XCHVG APSA RCTA RADIST)
               USE_NL (XCHVG APSA RCTA RADIST)
               INDEX  (XCHVG   XXCFR_CUST_HIERARCHY_MV_N01)
               INDEX  (APSA    AR_PAYMENT_SCHEDULES_N6)
               INDEX  (RCTA    RA_CUSTOMER_TRX_U1)
               INDEX  (RADIST  RA_CUST_TRX_LINE_GL_DIST_N6)
           */
-- Add 2011.05.17 Ver1.4 End
           SUM(apsa.amount_due_remaining) sum_amount --�������c�����z
    INTO on_target_credit
    FROM ra_customer_trx_all rcta,      --AR����w�b�_�e�[�u��
         ar_payment_schedules_all apsa, --AR�x���v��e�[�u��
         ( SELECT xchv.bill_account_id bill_account_id  --������ڋqID
-- Modify 2011.05.17 Ver1.4 Start
--           FROM xxcfr_cust_hierarchy_v xchv             --�ڋq�K�wView
           FROM xxcfr_cust_hierarchy_mv xchv             --�ڋq�K�w�}�e���A���C�Y�hView
-- Modify 2011.05.17 Ver1.4 End
           WHERE xchv.cash_account_id  = in_pay_from_customer  --�p�����[�^�F�ڋqID
-- Delete 2011.05.17 Ver1.4 Start
--           GROUP BY xchv.bill_account_id
-- Delete 2011.05.17 Ver1.4 End
         ) xchvg --������ڋq�C�����C���r���[
    WHERE rcta.org_id              = gn_org_id
      AND rcta.customer_trx_id     = apsa.customer_trx_id
      AND rcta.complete_flag       = cv_flag_y
      AND apsa.status              = cv_status_op
-- Modify 2011.05.17 Ver1.4 Start
--      AND rcta.bill_to_customer_id = xchvg.bill_account_id
      AND xchvg.bill_account_id    = apsa.customer_id
-- Modify 2011.05.17 Ver1.4 End
-- Modify 2010.01.12 Ver1.3 Start
--      AND apsa.due_date            = id_receipt_date    --�p�����[�^�F������
      AND apsa.due_date            >= id_receipt_date - gn_hht_date_from
      AND apsa.due_date            <= id_receipt_date + gn_hht_date_to
      AND rcta.trx_date            <= id_receipt_date
      AND EXISTS (SELECT 'X'
                  FROM ra_cust_trx_line_gl_dist_all radist
                  WHERE radist.customer_trx_id = rcta.customer_trx_id
                    AND radist.account_class = 'REV'
                    AND radist.gl_date <= id_receipt_date)
-- Modify 2010.01.12 Ver1.3 End
    ;
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
  END get_target_credit;
--
  /**********************************************************************************
   * Procedure Name   : start_apply_api
   * Description      : ��������API�N������ (A-7)
   ***********************************************************************************/
  PROCEDURE start_apply_api(
    in_cash_receipt_id IN  NUMBER,   --   ����ID
    iv_receipt_number  IN  VARCHAR2, --   �����ԍ�
    id_receipt_date    IN  DATE,     --   ������
    in_amount          IN  NUMBER,   --   �����z
    iv_receipt_method  IN  VARCHAR2, --   �x�����@
    iv_account_number  IN  VARCHAR2, --   �ڋq�R�[�h
    in_customer_trx_id IN  NUMBER,   --   ����w�b�_ID
    iv_trx_number      IN  VARCHAR2, --   ����ԍ�
    ov_errbuf          OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_apply_api'; -- �v���O������
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
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
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
    -- ��������API�N��
    ar_receipt_api_pub.apply(
       p_api_version     =>  1.0
      ,p_init_msg_list   =>  FND_API.G_TRUE
      ,x_return_status   =>  lv_return_status
      ,x_msg_count       =>  ln_msg_count
      ,x_msg_data        =>  lv_msg_data
      ,p_customer_trx_id =>  in_customer_trx_id --����w�b�_ID
      ,p_cash_receipt_id =>  in_cash_receipt_id --����ID
      ,p_apply_date      =>  id_receipt_date    --������
      ,p_apply_gl_date   =>  id_receipt_date    --GL�L����
      );
--
    IF (lv_return_status <> 'S') THEN
      --�G���[����
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr      -- 'XXCFR'
                              ,cv_msg_006a03_011
                              ,cv_tkn_receipt_nm   -- �g�[�N��'RECEIPT_NUMBER'
                              ,iv_receipt_number
                                -- �����ԍ�
                              ,cv_tkn_account      -- �g�[�N��'ACCOUNT_CODE'
                              ,iv_account_number
                                -- �ڋq�R�[�h
                              ,cv_tkn_meathod      -- �g�[�N��'RECEIPT_MEATHOD'
                              ,iv_receipt_method
                                -- �x�����@
                              ,cv_tkn_receipt_dt   -- �g�[�N��'RECEIPT_DATE'
                              ,TO_CHAR(id_receipt_date, cv_format_date_ymd)
                                -- ������
                              ,cv_tkn_amount       -- �g�[�N��'AMOUNT'
                              ,in_amount
                                -- �����z
                              ,cv_tkn_trx_nm       -- �g�[�N��'TRX_NUMBER'
                              ,iv_trx_number
                                -- ����ԍ�
                            )
                           ,1
                           ,5000
                          );
      -- ��������API�G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API�W���G���[���b�Z�[�W�o��
      IF (ln_msg_count = 1) THEN
        -- API�W���G���[���b�Z�[�W���P���̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || lv_msg_data
        );
--
      ELSE
        -- API�W���G���[���b�Z�[�W���������̏ꍇ
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- �x���Z�b�g
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
  END start_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_receipt_date        IN      VARCHAR2,         --   ������
    ov_errbuf              OUT     VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_status_unapp     CONSTANT VARCHAR2(10) := 'UNAPP';    -- �X�e�[�^�X�F�����|�������ݑO
--
    -- *** ���[�J���ϐ� ***
    ln_target_credit   ar_cash_receipts_all.amount%type;  -- �Ώۍ����z
    ln_subloop_err_cnt NUMBER;  -- �T�u���[�v���G���[����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    --�Ώ�AR�������o�e�[�u���f�[�^�擾�J�[�\��
    CURSOR ar_cash_receipts_cur
    IS
      SELECT acra.cash_receipt_id cash_receipt_id,     --����ID
             acra.receipt_number receipt_number,       --�����ԍ�
             acra.receipt_date receipt_date,           --������
             acra.pay_from_customer pay_from_customer, --�ڋqID
-- Modify 2009.02.12 Ver1.1 Start
--             acra.amount amount,                       --�����z
             (SELECT SUM(DECODE(araa.status,'UNAPP',NVL(araa.amount_applied,0),0))
                FROM ar_receivable_applications_all araa
               WHERE acra.cash_receipt_id = araa.cash_receipt_id ) amount, --�����z
-- Modify 2009.02.12 Ver1.1 End
             arm.name name,                            --�x�����@����
             hca.account_number account_number         --�ڋq�R�[�h
      FROM ar_cash_receipts_all acra,   --AR�����e�[�u��
           hz_cust_accounts     hca,    --�ڋq�}�X�^
           ar_receipt_methods   arm,    --AR�x�����@�e�[�u��
           ar_receipt_classes   arc     --AR�����敪�e�[�u��
      WHERE acra.org_id            = gn_org_id
        AND acra.receipt_date     <= TRUNC(gd_receipt_date)
        AND acra.status            = cv_status_unapp
        AND acra.pay_from_customer = hca.cust_account_id
        AND acra.receipt_method_id = arm.receipt_method_id
        AND arm.receipt_class_id   = arc.receipt_class_id
        AND arc.attribute1         = cv_flag_y              --HHT���������t���O
    ;
--
    l_ar_cash_receipts_rec   ar_cash_receipts_cur%ROWTYPE;
--
    --�Ώێ���f�[�^�擾�J�[�\��
    CURSOR ra_customer_trx_cur(
      in_pay_from_customer NUMBER, --A-4�ڋqID
      id_receipt_date      DATE)   --A-4������
    IS
      SELECT 
-- Delete 2011.05.17 Ver1.4 Start
---- Modify 2009.07.15 Ver1.2 Start
--           /*+ INDEX(rcta RA_CUSTOMER_TRX_N11)
--               INDEX(apsa AR_PAYMENT_SCHEDULES_N2)
--           */
---- Modify 2009.07.15 Ver1.2 End
-- Delete 2011.05.17 Ver1.4 End
-- Add 2011.05.17 Ver1.4 Start
           /*+
               LEADING(XCHVG APSA RCTA RADIST)
               USE_NL (XCHVG APSA RCTA RADIST)
               INDEX  (XCHVG   XXCFR_CUST_HIERARCHY_MV_N01)
               INDEX  (APSA    AR_PAYMENT_SCHEDULES_N6)
               INDEX  (RCTA    RA_CUSTOMER_TRX_U1)
               INDEX  (RADIST  RA_CUST_TRX_LINE_GL_DIST_N6)
           */
-- Add 2011.05.17 Ver1.4 End
             rcta.customer_trx_id customer_trx_id, --����w�b�_ID
             rcta.trx_number trx_number            --����ԍ�
      FROM ra_customer_trx_all rcta,      --AR����w�b�_�e�[�u��
           ar_payment_schedules_all apsa, --AR�x���v��e�[�u��
           ( SELECT xchv.bill_account_id bill_account_id  --������ڋqID
-- Modify 2011.05.17 Ver1.4 Start
--             FROM xxcfr_cust_hierarchy_v xchv             --�ڋq�K�wView
             FROM xxcfr_cust_hierarchy_mv xchv             --�ڋq�K�w�}�e���A���C�Y�hView
-- Modify 2011.05.17 Ver1.4 End
             WHERE xchv.cash_account_id  = in_pay_from_customer  --A-4�ڋqID
-- Delete 2011.05.17 Ver1.4 Start
--             GROUP BY xchv.bill_account_id
-- Delete 2011.05.17 Ver1.4 End
           ) xchvg --������ڋq�C�����C���r���[
      WHERE rcta.org_id              = gn_org_id
        AND rcta.customer_trx_id     = apsa.customer_trx_id
        AND rcta.complete_flag       = cv_flag_y
        AND apsa.status              = cv_status_op
-- Modify 2011.05.17 Ver1.4 Start
--        AND rcta.bill_to_customer_id = xchvg.bill_account_id
        AND xchvg.bill_account_id    = apsa.customer_id
-- Modify 2011.05.17 Ver1.4 End
-- Modify 2010.01.12 Ver1.3 Start
--        AND apsa.due_date            = id_receipt_date  --A-4������
        AND apsa.due_date            >= id_receipt_date - gn_hht_date_from
        AND apsa.due_date            <= id_receipt_date + gn_hht_date_to
        AND rcta.trx_date            <= id_receipt_date
        AND EXISTS (SELECT 'X'
                    FROM ra_cust_trx_line_gl_dist_all radist
                    WHERE radist.customer_trx_id = rcta.customer_trx_id
                      AND radist.account_class = 'REV'
                      AND radist.gl_date <= id_receipt_date)
-- Modify 2010.01.12 Ver1.3 End
      ORDER BY apsa.amount_due_remaining
    ;
--
    l_ra_customer_trx_rec   ra_customer_trx_cur%ROWTYPE;
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
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       iv_receipt_date        -- ������
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�E��������NULL�̏ꍇ
    IF (iv_receipt_date IS NULL) THEN
      -- =====================================================
      --  �Ɩ��������t�擾���� (A-2)
      -- =====================================================
      get_process_date(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
      
      -- �������̃O���[�o���ϐ��ɋƖ��������t���Z�b�g����
      gd_receipt_date := gd_process_date;
      
    -- ���̓p�����[�^�E��������NULL�łȂ��ꍇ
    ELSE
      -- �������̃O���[�o���ϐ��ɓ��̓p�����[�^�E���������Z�b�g����
      gd_receipt_date := xxcfr_common_pkg.get_date_param_trans ( iv_receipt_date );
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-3)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ώ�AR�����e�[�u���f�[�^�擾���� (A-4)
    -- =====================================================
    -- �J�[�\���I�[�v��
    OPEN ar_cash_receipts_cur;
--
    -- ���C�����[�v�J�n
    <<ar_cash_receipts_loop>>
    LOOP
      -- �f�[�^�̎擾
      FETCH ar_cash_receipts_cur INTO l_ar_cash_receipts_rec;
      EXIT WHEN ar_cash_receipts_cur%NOTFOUND;
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �Ώۍ����z������
      ln_target_credit := 0;
--
      -- =====================================================
      --  �Ώۍ����z���� (A-5)
      -- =====================================================
      get_target_credit(
         l_ar_cash_receipts_rec.pay_from_customer   -- �ڋqID
        ,l_ar_cash_receipts_rec.receipt_date        -- ������
        ,ln_target_credit                           -- �Ώۍ����z
        ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- A-4�Ŏ擾���������z��A-5�Ŏ擾�����������c�����z���������ꍇ
      IF (lv_retcode = cv_status_normal AND
          l_ar_cash_receipts_rec.amount = ln_target_credit) THEN
--
        -- =====================================================
        --  �Ώێ���f�[�^�擾���� (A-6)
        -- =====================================================
        -- �J�[�\���I�[�v��
        OPEN ra_customer_trx_cur(l_ar_cash_receipts_rec.pay_from_customer,
                                 l_ar_cash_receipts_rec.receipt_date);
--
        -- �T�u���[�v���G���[����������
        ln_subloop_err_cnt := 0;
--
        -- �T�u���[�v�J�n
        <<ra_customer_trx_loop>>
        LOOP
          -- �f�[�^�̎擾
          FETCH ra_customer_trx_cur INTO l_ra_customer_trx_rec;
          EXIT WHEN ra_customer_trx_cur%NOTFOUND;
--
        -- =====================================================
        --  ��������API�N������ (A-7)
        -- =====================================================
        start_apply_api(
           l_ar_cash_receipts_rec.cash_receipt_id  -- ����ID
          ,l_ar_cash_receipts_rec.receipt_number   -- �����ԍ�
          ,l_ar_cash_receipts_rec.receipt_date     -- ������
          ,l_ar_cash_receipts_rec.amount           -- �����z
          ,l_ar_cash_receipts_rec.name             -- �x�����@
          ,l_ar_cash_receipts_rec.account_number   -- �ڋq�R�[�h
          ,l_ra_customer_trx_rec.customer_trx_id   -- ����w�b�_ID
          ,l_ra_customer_trx_rec.trx_number        -- ����ԍ�
          ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        
        -- ���폈���`�F�b�N
        IF (lv_retcode <> cv_status_normal) THEN
          ln_subloop_err_cnt := ln_subloop_err_cnt + 1;
        END IF;
--
        -- �T�u���[�v�I��
        END LOOP ra_customer_trx_loop;
--
        -- �J�[�\���N���[�Y
        CLOSE ra_customer_trx_cur;
        
        IF (ln_subloop_err_cnt > 0) THEN
          -- �G���[�����J�E���g
          gn_error_cnt   := gn_error_cnt + 1;
        ELSE
          -- ���팏���J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      -- ���������ΏۊO�̏ꍇ
      ELSE
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt   := gn_warn_cnt + 1;
      END IF;
--
    -- ���C�����[�v�I��
    END LOOP ar_cash_receipts_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE ar_cash_receipts_cur;
--
    --���^�[���E�R�[�h�̐ݒ�
    IF (gn_error_cnt > 0) THEN
      -- �x���Z�b�g
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                 OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_receipt_date        IN      VARCHAR2          --    ������
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
       iv_receipt_date  -- ������
      ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
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
END XXCFR006A03C;
/
