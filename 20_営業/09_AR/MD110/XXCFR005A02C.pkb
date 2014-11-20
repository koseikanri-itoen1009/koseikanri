CREATE OR REPLACE PACKAGE BODY XXCFR005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A02C(body)
 * Description      : ���b�N�{�b�N�X�f�[�^�X�V
 * MD.050           : MD050_CFR_005_A02_���b�N�{�b�N�X�f�[�^�X�V
 * MD.070           : MD050_CFR_005_A02_���b�N�{�b�N�X�f�[�^�X�V
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ���̓p�����[�^�l���O�o�͏���            (A-1)
 *  get_profile_value      P �v���t�@�C���擾����                    (A-2)
 *  upd_payments_if        p ���b�N�{�b�N�XIF�X�V����                (A-3)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.00  SCS �_�� ����    ����쐬
 *  2009/11/06    1.10  SCS ���� �q��    ��Q�uT4_165�v�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  lock_expt          EXCEPTION;                                       -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A02C';        -- �p�b�P�[�W��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';               -- �A�v���P�[�V�����Z�k��(XXCFR)
  cv_dict_cd         CONSTANT VARCHAR2(100) := 'CFR005A02001';        -- ���b�N�{�b�N�XIF
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_005a02_003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003';     -- ���b�N�G���[���b�Z�[�W
  cv_msg_005a02_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_005a02_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017';     -- �f�[�^�X�V�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';            -- �v���t�@�C����
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';                -- �e�[�u����
--
  --�v���t�@�C��
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';               -- �g�DID
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';               -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';                  -- ���O�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gn_org_id          NUMBER;                                          -- �g�DID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- �R���J�����g�p�����[�^�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
--#################################  �Œ��O������ START   ####################################
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
   * Description      : �v���t�@�C���擾���� (A-2)
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
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a02_004 -- �v���t�@�C���擾�G���[
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
   * Procedure  Name   : upd_payments_if
   * Description       : ���b�N�{�b�N�XIF�X�V���� (A-3)
   ***********************************************************************************/
  Procedure upd_payments_if(
    on_target_cnt           OUT        NUMBER,              -- �Ώی���
    on_normal_cnt           OUT        NUMBER,              -- ��������
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_payments_if'; -- �v���O������
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
    cv_record_type CONSTANT VARCHAR2(1)       := '2';                           -- ���R�[�h���ʎq
    cv_status      CONSTANT VARCHAR2(30)      := 'AR_PLB_ALT_MATCH_VERIFY';     -- ���؃X�e�[�^�X
    cv_upd_status  CONSTANT VARCHAR2(30)      := 'AR_PLB_ALT_MATCH_CONFIRMED';  -- �m�F�σX�e�[�^�X
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���o
    CURSOR lock_payments_if_cur
    IS
      SELECT 'X'
      FROM ar_payments_interface_all pay
      WHERE pay.record_type = cv_record_type -- ���R�[�h���ʎq
--        AND pay.status      = cv_status      -- �X�e�[�^�X
        AND pay.org_id      = gn_org_id      -- �g�DID
      FOR UPDATE NOWAIT
    ;
--
    lock_payments_if_rec lock_payments_if_cur%ROWTYPE;
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
    -- �ϐ�������
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
--
    -- �J�[�\���I�[�v��
    OPEN lock_payments_if_cur;
--
    -- �J�[�\���N���[�Y
    CLOSE lock_payments_if_cur;
--
    -- ���b�N�{�b�N�XIF�X�V(�X�e�[�^�X)
    UPDATE ar_payments_interface_all
    SET    status                 = cv_upd_status             -- �X�e�[�^�X
          ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login      -- �ŏI�X�V����LOGIN_ID
    WHERE record_type = cv_record_type                        -- ���R�[�h���ʎq
      AND status      = cv_status                             -- �X�e�[�^�X
      AND org_id      = gn_org_id                             -- �g�DID
    ;
    -- ���b�N�{�b�N�XIF�X�V(DFF1(�U���˗��l�J�i��))
    UPDATE ar_payments_interface_all
    SET    attribute1             = customer_name_alt         -- DFF1(�U���˗��l�J�i��)
-- Add 2009-11-06 Ver1.10 Start
          ,attribute_category     = gn_org_id                 -- �g�DID
-- Add 2009-11-06 Ver1.10 Start
          ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login      -- �ŏI�X�V����LOGIN_ID
    WHERE record_type = cv_record_type                        -- ���R�[�h���ʎq
      AND org_id      = gn_org_id                             -- �g�DID
    ;
    -- �Ώی����E�X�V�����J�E���g
    IF (SQL%ROWCOUNT > 0) THEN
      gn_target_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := SQL%ROWCOUNT;
    END IF;
--
    -- �����Z�b�g
    on_target_cnt := gn_target_cnt;
    on_normal_cnt := gn_normal_cnt;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_005a02_003    -- �e�[�u�����b�N�G���[
                              ,cv_tkn_table         -- �g�[�N��'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- '���b�N�{�b�N�XIF'
                            )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF (lock_payments_if_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE lock_payments_if_cur;
      END IF;
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (lock_payments_if_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE lock_payments_if_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (lock_payments_if_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE lock_payments_if_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Add Start 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
      IF (lock_payments_if_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE lock_payments_if_cur;
      END IF;
-- Add End 2008/12/16 SCS R.Hamanaka �e���v���[�g���C��
--
--#####################################  �Œ蕔 END   ##########################################
--
      -- �e�[�u�����b�N�ȊO�̃G���[����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                               cv_msg_kbn_cfr       -- 'XXCFR'
                              ,cv_msg_005a02_017    -- �e�[�u���X�V�G���[
                              ,cv_tkn_table         -- �g�[�N��'TABLE'
                              ,xxcfr_common_pkg.lookup_dictionary(
                                 cv_msg_kbn_cfr
                                ,cv_dict_cd
                               )                    -- '���b�N�{�b�N�XIF'
                            )
                          ,1
                          ,5000
                          );
      ov_errmsg  := lv_errmsg;
--
  END upd_payments_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    on_target_cnt          OUT     NUMBER,           -- �Ώی���
    on_normal_cnt          OUT     NUMBER,           -- ��������
    on_error_cnt           OUT     NUMBER,           -- �G���[����
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
--
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���b�N�{�b�N�XIF�X�V����(A-3)
    -- =====================================================
--
    upd_payments_if(
       gn_target_cnt                 -- �Ώی���
      ,gn_normal_cnt                 -- ��������
      ,lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �I������ (A-4)
    -- =====================================================
    on_target_cnt := gn_target_cnt;  -- �Ώی����J�E���g
    on_normal_cnt := gn_normal_cnt;  -- ���������J�E���g
    on_error_cnt  := gn_error_cnt;   -- �G���[�����J�E���g
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
    retcode                OUT     VARCHAR2)         --    �G���[�R�[�h        --# �Œ� #
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100)      := 'main';             -- �v���O������
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
       gn_target_cnt -- �Ώی���
      ,gn_normal_cnt -- ��������
      ,gn_error_cnt  -- �G���[����
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
END XXCFR005A02C;
/
