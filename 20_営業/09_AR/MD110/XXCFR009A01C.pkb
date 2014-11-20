CREATE OR REPLACE PACKAGE BODY XXCFR009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR009A01C(body)
 * Description      : �c�ƈ��ʕ����ʓ����\��\
 * MD.050           : MD050_CFR_009_A01_�c�ƈ��ʕ����ʓ����\��\
 * MD.070           : MD050_CFR_009_A01_�c�ƈ��ʕ����ʓ����\��\
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  insert_work_table      p ���[�N�e�[�u���f�[�^�o�^                (A-3)
 *  start_svf_api          p SVF�N��                                 (A-4)
 *  delete_work_table      p ���[�N�e�[�u���f�[�^�폜                (A-5)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.00 SCS ���� ��      ����쐬
 *  2009/02/19    1.1  SCS T.KANEDA     [��QCOK_008] �ō��z�擾�s��Ή�
 *  2009/03/05    1.2  SCS M.OKAWA      ���ʊ֐������[�X�ɔ���SVF�N�������ύX�Ή�
 *                                      ���ԃe�[�u���f�[�^�폜�����R�����g�A�E�g�폜�Ή�
 *  2009/04/14    1.3  SCS M.OKAWA      [��QT1_0533] �o�̓t�@�C�����ϐ�������I�[�o�[�t���[�Ή�
 *  2009/04/24    1.4  SCS S.KAYAHARA   [��QT1_0633] �g�D�v���t�@�C�����������Ή�
 *  2009/07/15    1.5  SCS M.HIROSE     [��Q0000481] �p�t�H�[�}���X���P
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  file_not_exists_expt  EXCEPTION;      -- �t�@�C�����݃G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR009A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
-- Modify 2009.07.15 Ver1.5 Start
  cv_msg_kbn_ar      CONSTANT VARCHAR2(5)   := 'AR';    -- �A�v���P�[�V�����Z�k��(AR)
-- Modify 2009.07.15 Ver1.5 End
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_009a01_008  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --�G���[�I���ꕔ�������b�Z�[�W
  cv_msg_009a01_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; --�V�X�e���G���[���b�Z�[�W
--
  cv_msg_009a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_009a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --���b�N�G���[���b�Z�[�W
  cv_msg_009a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_009a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --�e�[�u���}���G���[
  cv_msg_009a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; --���[�O�����b�Z�[�W
  cv_msg_009a01_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; --API�G���[���b�Z�[�W
  cv_msg_009a01_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --���[�O�����O���b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API��
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- �R�����g
--
  -- ���{�ꎫ��
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF�N��
--
  --�v���t�@�C��
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
-- Modify 2009.02.19 Ver1.1 Start
  cv_prof_trx_source     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_TAX_DIFF_TRX_SOURCE';          -- �ō��z����\�[�X
-- Modify 2009.02.19 Ver1.1 End
--
  -- �g�pDB��
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_REP_SALES_REP_PAY_SCH';  -- ���[�N�e�[�u����
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- �L���t���O�i�x�j
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';  -- ���t�t�H�[�}�b�g�i�N���������b�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id             NUMBER;             -- �g�DID
  gn_set_of_bks_id      NUMBER;             -- ��v����ID
-- Modify 2009.02.19 Ver1.1 Start
  gt_taxd_trx_source     fnd_profile_option_values.profile_option_value%TYPE;  -- �ō��z����\�[�X
-- Modify 2009.02.19 Ver1.1 End
--
  /**********************************************************************************
   * Function Name    : get_receipt_class_name
   * Description      : �����敪���擾����
   ***********************************************************************************/
  FUNCTION get_receipt_class_name(
    iv_receipt_class_id          IN  VARCHAR2 )       -- �����敪�h�c
  RETURN VARCHAR2 IS -- �����敪��
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_class_name'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt     NUMBER;         -- �Ώی���
    ln_loop_cnt       NUMBER;         -- ���[�v�J�E���^
    lt_receipt_class_id    ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�h�c
    lt_receipt_class_name  ar_receipt_methods.name%TYPE;              -- �����敪��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �e�[�u�������o
    CURSOR receipt_class_name_cur IS
    SELECT arc.name                 receipt_class_name  -- �����敪��
    FROM ar_receipt_classes         arc                 -- �����敪
    WHERE arc.receipt_class_id      = lt_receipt_class_id
    ;
--
    TYPE receipt_class_name_tbl IS TABLE OF receipt_class_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_receipt_class_name_data  receipt_class_name_tbl;
--
  BEGIN
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lt_receipt_class_id := TO_NUMBER( iv_receipt_class_id );
--
    -- �J�[�\���I�[�v��
    OPEN receipt_class_name_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH receipt_class_name_cur BULK COLLECT INTO lt_receipt_class_name_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_receipt_class_name_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE receipt_class_name_cur;
--
    -- �Ώۃf�[�^����̏ꍇ�̓e�[�u������߂�l�ɐݒ�
    IF (ln_target_cnt > 0) THEN
      <<data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lt_receipt_class_name := lt_receipt_class_name_data(ln_loop_cnt).receipt_class_name;
      END LOOP data_loop;
      RETURN lt_receipt_class_name;
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ�́ANULL��߂�l�ɐݒ�
    ELSE
--
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_receipt_class_name;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receive_base_code   IN      VARCHAR2,         --    �������_
    iv_sales_rep           IN      VARCHAR2,         --    �c�ƒS����
    iv_due_date_from       IN      VARCHAR2,         --    �x������(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x������(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    �����敪�P
    iv_receipt_class2      IN      VARCHAR2,         --    �����敪�Q
    iv_receipt_class3      IN      VARCHAR2,         --    �����敪�R
    iv_receipt_class4      IN      VARCHAR2,         --    �����敪�S
    iv_receipt_class5      IN      VARCHAR2,         --    �����敪�T
    ov_errbuf              OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_receipt_class_name1  ar_receipt_methods.name%TYPE := NULL;  -- �����敪���P
    lt_receipt_class_name2  ar_receipt_methods.name%TYPE := NULL;  -- �����敪���Q
    lt_receipt_class_name3  ar_receipt_methods.name%TYPE := NULL;  -- �����敪���R
    lt_receipt_class_name4  ar_receipt_methods.name%TYPE := NULL;  -- �����敪���S
    lt_receipt_class_name5  ar_receipt_methods.name%TYPE := NULL;  -- �����敪���T
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
    --�����敪�ϊ�
    --==============================================================
    IF (iv_receipt_class1 IS NOT NULL) THEN
      -- �����敪���P�擾
      lt_receipt_class_name1 := get_receipt_class_name(
                                  iv_receipt_class1
                                );
    END IF;
    IF (iv_receipt_class2 IS NOT NULL) THEN
      -- �����敪���Q�擾
      lt_receipt_class_name2 := get_receipt_class_name(
                                  iv_receipt_class2
                                );
    END IF;
    IF (iv_receipt_class3 IS NOT NULL) THEN
      -- �����敪���R�擾
      lt_receipt_class_name3 := get_receipt_class_name(
                                  iv_receipt_class3
                                );
    END IF;
    IF (iv_receipt_class4 IS NOT NULL) THEN
      -- �����敪���S�擾
      lt_receipt_class_name4 := get_receipt_class_name(
                                  iv_receipt_class4
                                );
    END IF;
    IF (iv_receipt_class5 IS NOT NULL) THEN
      -- �����敪���T�擾
      lt_receipt_class_name5 := get_receipt_class_name(
                                  iv_receipt_class5
                                );
    END IF;
--
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log       -- ���O�o��
      ,iv_conc_param1  => iv_receive_base_code   -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_sales_rep           -- �R���J�����g�p�����[�^�Q
      ,iv_conc_param3  => iv_due_date_from       -- �R���J�����g�p�����[�^�R
      ,iv_conc_param4  => iv_due_date_to         -- �R���J�����g�p�����[�^�S
      ,iv_conc_param5  => lt_receipt_class_name1 -- �R���J�����g�p�����[�^�T
      ,iv_conc_param6  => lt_receipt_class_name2 -- �R���J�����g�p�����[�^�U
      ,iv_conc_param7  => lt_receipt_class_name3 -- �R���J�����g�p�����[�^�V
      ,iv_conc_param8  => lt_receipt_class_name4 -- �R���J�����g�p�����[�^�W
      ,iv_conc_param9  => lt_receipt_class_name5 -- �R���J�����g�p�����[�^�X
      ,ov_errbuf       => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
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
-- Modify 2009.02.18 Ver1.1 Start
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
-- Modify 2009.02.18 Ver1.1 End
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
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_009a01_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- ��v����ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_009a01_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.02.18 Ver1.1 Start
    --==============================================================
    --�v���t�@�C���擾����
    --==============================================================
    --�ō��z����\�[�X
    gt_taxd_trx_source := fnd_profile.value(cv_prof_trx_source);
    IF (gt_taxd_trx_source IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_009a01_010
                                                    ,iv_token_name1  => cv_tkn_prof
                                                    ,iv_token_value1 
                                                        => xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_source))
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.02.18 Ver1.1 End
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
   * Procedure Name   : insert_work_table
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_receive_base_code    IN         VARCHAR2,            -- �������_
    iv_sales_rep            IN         VARCHAR2,            -- �c�ƒS����
    iv_due_date_from        IN         VARCHAR2,            -- �x������(FROM)
    iv_due_date_to          IN         VARCHAR2,            -- �x������(TO)
    iv_receipt_class1       IN         VARCHAR2,            -- �����敪�P
    iv_receipt_class2       IN         VARCHAR2,            -- �����敪�Q
    iv_receipt_class3       IN         VARCHAR2,            -- �����敪�R
    iv_receipt_class4       IN         VARCHAR2,            -- �����敪�S
    iv_receipt_class5       IN         VARCHAR2,            -- �����敪�T
    ov_errbuf               OUT        VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT        VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT        VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- �v���O������
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
    cv_rounding_rule_n  CONSTANT VARCHAR2(10) := 'NEAREST';  -- �l�̌ܓ�
    cv_rounding_rule_u  CONSTANT VARCHAR2(10) := 'UP';       -- �؏グ
    cv_rounding_rule_d  CONSTANT VARCHAR2(10) := 'DOWN';     -- �؎̂�
    cv_bill_to          CONSTANT VARCHAR2(10) := 'BILL_TO';  -- �g�p�ړI�F������
    cv_status_op        CONSTANT VARCHAR2(10) := 'OP';       -- �X�e�[�^�X�F�I�[�v��
    cv_status_enabled   CONSTANT VARCHAR2(10) := 'A';        -- �X�e�[�^�X�F�L��
    cv_relate_class     CONSTANT VARCHAR2(10) := '2';        -- �֘A���ށF����
    cv_lookup_tax_type  CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN';   -- ����ŋ敪
    cv_sales_rep_attr   CONSTANT VARCHAR2(30) := 'RESOURCE' ;   -- �S���c�ƈ�����
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    lv_no_data_msg  VARCHAR2(5000); -- ���[�O�����b�Z�[�W
--
    lt_receipt_class_id1  ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�P
    lt_receipt_class_id2  ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�Q
    lt_receipt_class_id3  ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�R
    lt_receipt_class_id4  ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�S
    lt_receipt_class_id5  ar_receipt_methods.receipt_class_id%TYPE;  -- �����敪�T
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
    -- ====================================================
    -- ���[�O�����b�Z�[�W�擾
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                       ,cv_msg_009a01_014 -- ���[�O�����b�Z�[�W
                                                      )
                                                    ,1
                                                    ,5000);
--
    lt_receipt_class_id1 := TO_NUMBER( iv_receipt_class1 );
    lt_receipt_class_id2 := TO_NUMBER( iv_receipt_class2 );
    lt_receipt_class_id3 := TO_NUMBER( iv_receipt_class3 );
    lt_receipt_class_id4 := TO_NUMBER( iv_receipt_class4 );
    lt_receipt_class_id5 := TO_NUMBER( iv_receipt_class5 );
--
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
      INSERT INTO xxcfr_rep_sales_rep_pay_sch ( 
         report_id
        ,output_date
        ,receipt_area_code
        ,receipt_dept_code
        ,receipt_dept_name
        ,receipt_sales_rep_code
        ,receipt_sales_rep_name
        ,due_date
        ,receipt_customer_code
        ,receipt_customer_name
        ,receipt_class_id
        ,receipt_class_name
        ,tax_class_code
        ,tax_class_name
        ,amount_due_original
        ,amount_due_remaining
        ,amount_due_remaining_ex_tax
        ,tax_original
        ,tax_remaining
        ,data_empty_message
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login 
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT
-- Modify 2009.07.15 Ver1.5 Start
             /*+ INDEX(hp    HZ_PARTIES_U1 )
                 INDEX(hop   HZ_ORGANIZATION_PROFILES_N1)
                 INDEX(hopeb HZ_ORG_PROFILES_EXT_B_N1)
                 INDEX(xca   XXCMM_CUST_ACCOUNTS_PK)
             */
-- Modify 2009.07.15 Ver1.5 End
        cv_pkg_name                                 report_id,            -- ���[�h�c
        TO_CHAR( cd_creation_date, cv_format_date_ymdhns ) output_date,   -- �o�͓�
        xdev.attribute9                             receipt_area_code,    -- �������_�G���A�R�[�h�i�{���R�[�h�j
        NVL( xca.receiv_base_code, xca.sale_base_code ) receipt_dept_code, -- �������_�R�[�h
        xdev.description                            receipt_dept_name,    -- �������_��
        hopeb.c_ext_attr1                           sales_rep_code,       -- �c�ƒS���҃R�[�h
        papf.per_information18 || papf.per_information19 sales_rep_name,  -- �]�ƈ�����
        pay_sch.due_date                            due_date,             -- �x������
        ca.cr_account_number                        cr_account_number,    -- ������ڋq�R�[�h
        hp.party_name                               party_name,           -- ������ڋq��
        pay_sch.receipt_class_id                    receipt_class_id,     -- �����敪ID
        pay_sch.receipt_class_name                  receipt_class_name,   -- �����敪��
        xca.tax_div                                 tax_div,              -- ����ŋ敪
        flv.meaning                                 tax_div_name,         -- ����ŋ敪��
        NVL( SUM( pay_sch.amount_due_original ),0 ) amount_due_original,  -- �����c���i�ō��j
        NVL( SUM( pay_sch.amount_due_remaining ),0 ) amount_due_remaining, -- ������c���i�ō��j
        NVL( SUM( pay_sch.amount_due_remaining ),0 )
         -  NVL( SUM( DECODE( pay_sch.tax_rounding_rule,
                              cv_rounding_rule_n, ROUND( pay_sch.tax_due_remaining ),
                              cv_rounding_rule_u, CEIL ( pay_sch.tax_due_remaining ),
                              cv_rounding_rule_d, FLOOR( pay_sch.tax_due_remaining ),
                              ROUND( pay_sch.tax_due_remaining )
                            )
                     ) 
               ,0 )                                 amount_due_remaining_ex_tax,
                                                                          -- ������c���i�Ŕ��j
        NVL( SUM( pay_sch.tax_original ), 0 )       tax_original,         -- �����Ŋz
        NVL( SUM( DECODE( pay_sch.tax_rounding_rule,
                          cv_rounding_rule_n, ROUND( pay_sch.tax_due_remaining ),
                          cv_rounding_rule_u, CEIL ( pay_sch.tax_due_remaining ),
                          cv_rounding_rule_d, FLOOR( pay_sch.tax_due_remaining ),
                          ROUND( pay_sch.tax_due_remaining )
                        )
                )
           ,0 )                                     tax_due_remaining,    -- ������Ŋz
        NULL                                        data_empty_message,   -- 0�����b�Z�[�W
        cn_created_by                               created_by,           -- �쐬��
        cd_creation_date                            creation_date,        -- �쐬��
        cn_last_updated_by                          last_updated_by,      -- �ŏI�X�V��
        cd_last_update_date                         last_update_date,     -- �ŏI�X�V��
        cn_last_update_login                        last_update_login,    -- �ŏI�X�V���O�C��
        cn_request_id                               request_id,           -- �v��ID
        cn_program_application_id                   program_application_id, -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        cn_program_id                               program_id,           -- �R���J�����g�E�v���O����ID
        cd_program_update_date                      program_update_date   -- �v���O�����X�V��
      FROM
        ( 
        SELECT 
-- Modify 2009.07.15 Ver1.5 Start
               /*+ INDEX(apsa  XXCFR_AR_PAYMENT_SCHEDULES_N01)
               */
-- Modify 2009.07.15 Ver1.5 End
               rcta.bill_to_customer_id           bill_to_customer_id,    -- ������ڋqID
               arm.name                           receipt_method_name,    -- �������@�i�x�����@�j
               arm.receipt_class_id               receipt_class_id,       -- �����敪ID
               arc.name                           receipt_class_name,     -- �����敪
               apsa.due_date                      due_date,               -- �x������
               SUM ( apsa.amount_due_remaining )  amount_due_remaining,   -- ������c���i�ō��j
               SUM ( apsa.amount_due_original )   amount_due_original,    -- �����c���i�ō��j
-- Modify 2009.02.18 Ver1.1 Start
--               SUM ( apsa.tax_original )          tax_original,           -- �����Ŋz
--               SUM ( DECODE ( apsa.amount_due_remaining, 
--                              apsa.amount_due_original, apsa.tax_original,
--                              apsa.amount_due_remaining / apsa.amount_due_original * apsa.tax_original ) )
--                                                  tax_due_remaining,      -- ������Ŋz
--
               SUM ( DECODE ( rbsa.name,
                              gt_taxd_trx_source,apsa.amount_due_original,
                              apsa.tax_original ) )          tax_original,           -- �����Ŋz
               SUM ( DECODE ( apsa.amount_due_remaining, 
                              apsa.amount_due_original, DECODE ( rbsa.name,
                                                                 gt_taxd_trx_source,apsa.amount_due_original,
                                                                 apsa.tax_original ),
                              apsa.amount_due_remaining / apsa.amount_due_original
                                                              * DECODE ( rbsa.name,
                                                                         gt_taxd_trx_source,apsa.amount_due_original,
                                                                         apsa.tax_original ) ) )
--                              apsa.amount_due_remaining / apsa.amount_due_original * apsa.tax_original ) )
                                                  tax_due_remaining,      -- ������Ŋz
-- Modify 2009.02.18 Ver1.1 End
               hcsua.tax_rounding_rule            tax_rounding_rule       -- �ŋ��|�[������
-- Modify 2009.07.15 Ver1.5 Start
--        FROM ra_customer_trx_all        rcta,     -- ����w�b�_
--             ar_payment_schedules_all   apsa,     -- �x���v��
        FROM ra_customer_trx            rcta,     -- ����w�b�_
             ar_payment_schedules       apsa,     -- �x���v��
-- Modify 2009.07.15 Ver1.5 End
             ar_receipt_methods         arm,      -- �������@�i�x�����@�j
             ar_receipt_classes         arc,      -- �����敪
             hz_cust_accounts           hca,      -- �ڋq�}�X�^�i������j
-- Modify 2009.07.15 Ver1.5 Start
--             hz_cust_acct_sites_all     hcasa,    -- �ڋq���ݒn�}�X�^
--             hz_cust_site_uses_all      hcsua     -- �ڋq�g�p�ړI�}�X�^
---- Modify 2009.02.18 Ver1.1 Start
--            ,ra_batch_sources_all       rbsa
---- Modify 2009.02.18 Ver1.1 End
             hz_cust_acct_sites         hcasa,    -- �ڋq���ݒn�}�X�^
             hz_cust_site_uses          hcsua,    -- �ڋq�g�p�ړI�}�X�^
             ra_batch_sources           rbsa
-- Modify 2009.07.15 Ver1.5 End
        WHERE rcta.customer_trx_id      = apsa.customer_trx_id
          AND rcta.receipt_method_id    = arm.receipt_method_id
          AND arm.receipt_class_id      = arc.receipt_class_id
          AND rcta.bill_to_customer_id  = hca.cust_account_id
          AND hca.cust_account_id       = hcasa.cust_account_id(+)
          AND hcasa.cust_acct_site_id   = hcsua.cust_acct_site_id(+)
          AND hcsua.site_use_code       = cv_bill_to   -- �g�p�ړI�F������
          AND rcta.set_of_books_id      = gn_set_of_bks_id
-- Modify 2009.07.15 Ver1.5 Start
--          AND rcta.org_id               = gn_org_id
-- Modify 2009.07.15 Ver1.5 End
          AND apsa.status               = cv_status_op -- �X�e�[�^�X�F�I�[�v��
          AND (
                ( lt_receipt_class_id1 IS NULL 
                  AND lt_receipt_class_id2 IS NULL
                  AND lt_receipt_class_id3 IS NULL
                  AND lt_receipt_class_id4 IS NULL
                  AND lt_receipt_class_id5 IS NULL
                )
                OR arm.receipt_class_id IN ( 
                    lt_receipt_class_id1,
                    lt_receipt_class_id2,
                    lt_receipt_class_id3,
                    lt_receipt_class_id4,
                    lt_receipt_class_id5
                )
              )
          AND ( apsa.due_date >= xxcfr_common_pkg.get_date_param_trans ( iv_due_date_from )
                OR iv_due_date_from IS NULL )
          AND ( apsa.due_date <= xxcfr_common_pkg.get_date_param_trans ( iv_due_date_to )
                OR iv_due_date_to IS NULL )
-- Modify 2009.02.18 Ver1.1 Start
          AND rcta.batch_source_id      = rbsa.batch_source_id
          AND rcta.org_id               = rbsa.org_id
-- Modify 2009.02.18 Ver1.1 End
        GROUP BY 
          rcta.bill_to_customer_id,   -- ������ڋqID
          arm.name,                   -- �������@�i�x�����@�j
          arm.receipt_class_id,       -- �����敪ID
          arc.name,                   -- �����敪
          apsa.due_date,              -- �x������
          hcsua.tax_rounding_rule     -- �ŋ��|�[������
        )                         pay_sch,        -- �ڋq�ʖ�����c���r���[
        (
          SELECT
            hca.cust_account_id                     bill_cust_account_id,   -- ������ڋq�h�c
            hca_c.cust_account_id                   cr_cust_account_id,     -- ������̌ڋq�h�c
            hca.account_number                      bill_to_account_number, -- ������ڋq�R�[�h�i������ڋq�R�[�h�j
            hca_c.account_number                    cr_account_number,      -- ������ڋq�R�[�h
            hca_c.party_id                          cr_party_id             -- ������ڋq�p�[�e�B�h�c
          FROM hz_cust_accounts           hca_c,    -- �ڋq�}�X�^�i�����j
               hz_cust_accounts           hca,      -- �ڋq�}�X�^�i������j
-- Modify 2009.07.15 Ver1.5 Start
--               hz_cust_acct_relate_all    hcara     -- �ڋq�֘A
               hz_cust_acct_relate        hcara     -- �ڋq�֘A
-- Modify 2009.07.15 Ver1.5 End
          WHERE hca_c.cust_account_id     = hcara.cust_account_id
            AND hcara.related_cust_account_id = hca.cust_account_id
            AND hcara.status              = cv_status_enabled -- �X�e�[�^�X�F�L��
            AND hcara.attribute1          = cv_relate_class   -- �֘A���ށF����
-- Modify 2009.07.15 Ver1.5 Start
--          UNION
          UNION ALL
-- Modify 2009.07.15 Ver1.5 End
          SELECT
            hca.cust_account_id                     bill_cust_account_id,   -- ������ڋq�h�c
            hca.cust_account_id                     cr_cust_account_id,     -- ������ڋq�h�c
            hca.account_number                      bill_to_account_number, -- ������ڋq�R�[�h�i������ڋq�R�[�h�j
            hca.account_number                      cr_account_number,      -- ������ڋq�R�[�h
            hca.party_id                            cr_party_id             -- ������ڋq�p�[�e�B�h�c
          FROM hz_cust_accounts           hca      -- �ڋq�}�X�^�i�����֘A�Ȃ��j
          WHERE NOT EXISTS (
                  SELECT 'X'
                    FROM hz_cust_acct_relate_all   cash_hcar_1       --�ڋq�֘A�}�X�^(�����֘A)
                   WHERE cash_hcar_1.status     = cv_status_enabled  --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                     AND cash_hcar_1.attribute1 = cv_relate_class    --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                     AND cash_hcar_1.related_cust_account_id = hca.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
                )
        )                         ca,             -- �ڋq�����֘A�擾�r���[
        hz_parties                hp,             -- �p�[�e�B
        hz_organization_profiles  hop,            -- �g�D�v���t�@�C��
        hz_org_profiles_ext_b     hopeb,          -- �g�D�v���t�@�C���g��
        ego_attr_groups_v         eagv,           -- �g�D�v���t�@�C���g�������O���[�v
        per_all_people_f          papf,           -- �]�ƈ��}�X�^
        xxcmm_cust_accounts       xca,            -- �ڋq�ǉ����e�[�u��
        xx03_departments_ext_v    xdev,           -- ����}�X�^�r���[
        fnd_lookup_values         flv             -- �Q�ƕ\�i����ŋ敪�j
-- Modify 2009.07.15 Ver1.5 Start
       ,fnd_application           fapp            -- �A�v���P�[�V����
-- Modify 2009.07.15 Ver1.5 End
      WHERE pay_sch.bill_to_customer_id = ca.bill_cust_account_id
        AND ca.cr_party_id              = hp.party_id
        AND hp.party_id                 = hop.party_id(+)
-- Modify 2009.04.24 Ver1.4 Start
        AND hop.effective_end_date(+) is NULL
-- Modify 2009.04.24 Ver1.4 End
        AND hop.organization_profile_id = hopeb.organization_profile_id(+)
        AND hopeb.attr_group_id         = eagv.attr_group_id(+)
        AND eagv.attr_group_name        = cv_sales_rep_attr    -- �S���c�ƈ�����
-- Modify 2009.07.15 Ver1.5 Start
        AND eagv.application_id         = fapp.application_id  -- �A�v���P�[�V����ID
        AND fapp.application_short_name = cv_msg_kbn_ar        -- �A�v���P�[�V�����Z�k��(AR)
-- Modify 2009.07.15 Ver1.5 Start
        AND hopeb.c_ext_attr1           = papf.employee_number
        AND ( hopeb.d_ext_attr1 <= TRUNC ( SYSDATE )
           OR hopeb.d_ext_attr1 IS NULL )
        AND ( hopeb.d_ext_attr2 >= TRUNC ( SYSDATE )
           OR hopeb.d_ext_attr2 IS NULL )
        AND papf.effective_start_date   <= TRUNC ( SYSDATE )
        AND papf.effective_end_date     >= TRUNC ( SYSDATE )
        AND ca.cr_cust_account_id       = xca.customer_id
        AND NVL( xca.receiv_base_code, xca.sale_base_code )
                                        = xdev.flex_value
        AND xdev.enabled_flag           = cv_enabled_yes
-- Modify 2009.07.15 Ver1.5 Start
        AND xdev.set_of_books_id        = gn_set_of_bks_id
-- Modify 2009.07.15 Ver1.5 End
        AND NVL( xca.receiv_base_code, xca.sale_base_code )
                                        = NVL ( iv_receive_base_code, 
                                                NVL( xca.receiv_base_code, xca.sale_base_code ) )
        AND hopeb.c_ext_attr1           = NVL ( iv_sales_rep, hopeb.c_ext_attr1 )
        AND xca.tax_div                 = flv.lookup_code
        AND flv.lookup_type             = cv_lookup_tax_type
        AND flv.language                = USERENV( 'LANG' )
        AND flv.enabled_flag            = cv_enabled_yes
        AND ( flv.start_date_active     IS NULL
           OR flv.start_date_active     <= TRUNC ( SYSDATE ) )
        AND ( flv.end_date_active       IS NULL
           OR flv.end_date_active       >= TRUNC ( SYSDATE ) )
      GROUP BY
        xdev.attribute9,                    -- �������_�G���A�R�[�h�i�{���R�[�h�j
        NVL( xca.receiv_base_code, xca.sale_base_code ), -- �������_�R�[�h
        xdev.description,                   -- �������_��
        hopeb.c_ext_attr1,                  -- �c�ƒS���҃R�[�h
        papf.per_information18,             -- �]�ƈ���
        papf.per_information19,             -- �]�ƈ���
        pay_sch.due_date,                   -- �x������
        ca.cr_account_number,               -- ������ڋq�R�[�h
        hp.party_name,                      -- ������ڋq��
        pay_sch.receipt_class_id,           -- �����敪ID
        pay_sch.receipt_class_name,         -- �����敪��
        xca.tax_div,                        -- ����ŋ敪
        flv.meaning                         -- ����ŋ敪��
      ;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�O�����b�Z�[�W���R�[�h�ǉ�
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_sales_rep_pay_sch ( 
           report_id
          ,output_date
          ,receipt_dept_code
          ,receipt_sales_rep_code
          ,data_empty_message
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login 
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        )
        VALUES ( 
          cv_pkg_name                                        , -- ���[�h�c
          TO_CHAR( cd_creation_date, cv_format_date_ymdhns ) , -- �o�͓�
          iv_receive_base_code                               , -- �������_�R�[�h
          iv_sales_rep                                       , -- �c�ƒS����
          lv_no_data_msg                                     , -- 0�����b�Z�[�W
          cn_created_by                                      , -- �쐬��
          cd_creation_date                                   , -- �쐬��
          cn_last_updated_by                                 , -- �ŏI�X�V��
          cd_last_update_date                                , -- �ŏI�X�V��
          cn_last_update_login                               , -- �ŏI�X�V���O�C��
          cn_request_id                                      , -- �v��ID
          cn_program_application_id                          , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id                                      , -- �R���J�����g�E�v���O����ID
          cd_program_update_date                               -- �v���O�����X�V��
        );
--
        -- �x���I��
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_009a01_016    -- �Ώۃf�[�^0���x��
                                                      )
                                                      ,1
                                                      ,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- �o�^���G���[
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_009a01_013    -- �e�[�u���o�^�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- �c�ƈ��ʕ����ʓ����\��\���[���[�N�e�[�u��
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- ���������̐ݒ�
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : start_svf_api
   * Description      : SVF�N�� (A-4)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- �v���O������
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
-- Modify 2009.03.05 Ver1.2 Start
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR009A01S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR009A01S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- �o�͋敪(=1�FPDF�o�́j
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- �g���q�ipdf�j
-- Modify 2009.03.05 Ver1.2 End
--
    -- *** ���[�J���ϐ� ***
    lv_no_data_msg     VARCHAR2(5000);  -- ���[�O�����b�Z�[�W
-- Modify 2009.04.14 Ver1.3 Start
--    lv_svf_file_name   VARCHAR2(30);
    lv_svf_file_name   VARCHAR2(100);
-- Modify 2009.04.14 Ver1.3 END
-- Modify 2009.03.05 Ver1.2 Start
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Modify 2009.03.05 Ver1.2 End
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
    -- =====================================================
    --  SVF�N�� (A-4)
    -- =====================================================
--
-- Modify 2009.03.05 Ver1.2 Start
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
    -- �R���J�����g���̐ݒ�
    lv_conc_name := cv_pkg_name;
--
    -- �t�@�C��ID�̐ݒ�
    lv_file_id := cv_pkg_name;
--
--    -- ���[�O�����b�Z�[�W�擾
--    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
--                                                       ,cv_msg_009a01_016 -- ���[�O�����b�Z�[�W
--                                                      )
--                                                    ,1
--                                                    ,5000);
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_svf_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
      ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
      ,iv_file_id      => lv_file_id            -- ���[ID
      ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
      ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
      ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => NULL                  -- ������
      ,iv_printer_name => NULL                  -- �v�����^��
      ,iv_request_id   => cn_request_id         -- �v��ID
      ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
    );
-- Modify 2009.03.05 Ver1.2 End
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_009a01_015    -- API�G���[
                                                     ,cv_tkn_api           -- �g�[�N��'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF�N��
                                                    )
                                                  ,1
                                                  ,5000);
-- Modify 2009.03.05 Ver1.2 Start
--      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
-- Modify 2009.03.05 Ver1.2 End
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT        VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT        VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT        VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR del_rep_sales_rep_cur
    IS
      SELECT xrsr.ROWID        ln_rowid
      FROM xxcfr_rep_sales_rep_pay_sch  xrsr
      WHERE xrsr.request_id             = cn_request_id  -- �v��ID
      FOR UPDATE NOWAIT
    ;
--
    TYPE g_del_rep_sales_rep_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_sales_rep_data    g_del_rep_sales_rep_ttype;
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
    -- �J�[�\���I�[�v��
    OPEN del_rep_sales_rep_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH del_rep_sales_rep_cur BULK COLLECT INTO lt_del_rep_sales_rep_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_del_rep_sales_rep_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE del_rep_sales_rep_cur;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_sales_rep_pay_sch
          WHERE ROWID = lt_del_rep_sales_rep_data(ln_loop_cnt);
--
        -- �R�~�b�g���s
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_009a01_012 -- �f�[�^�폜�G���[
                                                        ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- �c�ƈ��ʕ����ʓ����\��\���[���[�N�e�[�u��
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_009a01_011    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- �c�ƈ��ʕ����ʓ����\��\���[���[�N�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_receive_base_code   IN      VARCHAR2,         --    �������_
    iv_sales_rep           IN      VARCHAR2,         --    �c�ƒS����
    iv_due_date_from       IN      VARCHAR2,         --    �x������(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x������(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    �����敪�P
    iv_receipt_class2      IN      VARCHAR2,         --    �����敪�Q
    iv_receipt_class3      IN      VARCHAR2,         --    �����敪�R
    iv_receipt_class4      IN      VARCHAR2,         --    �����敪�S
    iv_receipt_class5      IN      VARCHAR2,         --    �����敪�T
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
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_receive_base_code   -- �������_
      ,iv_sales_rep           -- �c�ƒS����
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_receipt_class1      -- �����敪�P
      ,iv_receipt_class2      -- �����敪�Q
      ,iv_receipt_class3      -- �����敪�R
      ,iv_receipt_class4      -- �����敪�S
      ,iv_receipt_class5      -- �����敪�T
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
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
    --  ���[�N�e�[�u���f�[�^�o�^ (A-3)
    -- =====================================================
    insert_work_table(
       iv_receive_base_code   -- �������_
      ,iv_sales_rep           -- �c�ƒS����
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_receipt_class1      -- �����敪�P
      ,iv_receipt_class2      -- �����敪�Q
      ,iv_receipt_class3      -- �����敪�R
      ,iv_receipt_class4      -- �����敪�S
      ,iv_receipt_class5      -- �����敪�T
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --(�߂�l�̕ۑ�)
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
    -- =====================================================
    --  SVF�N�� (A-4)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode_svf            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg_svf);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�폜 (A-5)
    -- =====================================================
-- Modify 2009.03.05 Ver1.2 Start
--/*
-- Modify 2009.03.05 Ver1.2 End
    delete_work_table(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
-- Modify 2009.03.05 Ver1.2 Start
--*/
-- Modify 2009.03.05 Ver1.2 End
--
    -- =====================================================
    --  SVF�N��API�G���[�`�F�b�N (A-6)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(�G���[����)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
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
    iv_receive_base_code   IN      VARCHAR2,         --    �������_
    iv_sales_rep           IN      VARCHAR2,         --    �c�ƒS����
    iv_due_date_from       IN      VARCHAR2,         --    �x������(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x������(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    �����敪�P
    iv_receipt_class2      IN      VARCHAR2,         --    �����敪�Q
    iv_receipt_class3      IN      VARCHAR2,         --    �����敪�R
    iv_receipt_class4      IN      VARCHAR2,         --    �����敪�S
    iv_receipt_class5      IN      VARCHAR2          --    �����敪�T
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
    lv_errbuf2      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
       iv_receive_base_code   -- �������_
      ,iv_sales_rep           -- �c�ƒS����
      ,iv_due_date_from       -- �x������(FROM)
      ,iv_due_date_to         -- �x������(TO)
      ,iv_receipt_class1      -- �����敪�P
      ,iv_receipt_class2      -- �����敪�Q
      ,iv_receipt_class3      -- �����敪�R
      ,iv_receipt_class4      -- �����敪�S
      ,iv_receipt_class5      -- �����敪�T
      ,lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
    IF (lv_errmsg IS NOT NULL) THEN
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_009a01_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
    fnd_file.put_line(
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
END XXCFR009A01C;
/