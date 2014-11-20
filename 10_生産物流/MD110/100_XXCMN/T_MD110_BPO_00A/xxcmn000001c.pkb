CREATE OR REPLACE PACKAGE BODY xxcmn000001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn000001c(body)
 * Description      : �����`�[�ԍ��X�V
 * MD.050           : �����`�[�ԍ��X�V       T_MD050_BPO_00A
 * MD.070           : �����`�[�ԍ��X�V       T_MD070_BPO_00A
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/27    1.0   Oracle �ѓc ��   ����쐬
 *  2009/07/07    1.1   SCS�ۉ�          �{��1564�Ή�
 *  2009/07/09    1.2   SCS�ۉ�          API�ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxcmn000001c';      -- �p�b�P�[�W��
  gv_app_name            CONSTANT VARCHAR2(5)   := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
  gv_prof_option_name    CONSTANT VARCHAR2(16)  := 'XXCMN_SEQ_YYYYMM';  -- �v���t�@�C���I�v�V������
/* 2009/07/09 DEL START
  gn_level_id            CONSTANT NUMBER        := 10001;               -- ���x��ID
   2009/07/09 DEL END */
--
  gv_yyyymm              CONSTANT VARCHAR2(6)   := 'YYYYMM';            -- �N��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate             DATE;          -- �V�X�e�����t
  gn_user_id             NUMBER;        -- ���[�UID
  gn_login_id            NUMBER;        -- �ŏI�X�V���O�C��
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_application_short_name      CONSTANT VARCHAR2(100) := 'XXCMN';
    cv_profile_option_name         CONSTANT VARCHAR2(100) := 'XXCMN_SEQ_YYYYMM';
 /* 2009/07/09 DEL START
    cn_level_id                    CONSTANT NUMBER        := 10001;
    2009/07/09 DEL END */
-- 2009/07/07 ADD START
    cv_no_change_msg               CONSTANT VARCHAR2(100) := '�̔ԕύX�s�v:';
-- 2009/07/07 ADD END
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C��
 /* 2009/07/09 DEL START
    ln_apprication_id              fnd_profile_option_values.application_id%TYPE;
    ln_profile_option_id           fnd_profile_option_values.profile_option_id%TYPE;
    ln_level_id                    fnd_profile_option_values.level_id%TYPE;
    ln_level_value                 fnd_profile_option_values.level_value%TYPE;
    ln_level_value_application_id  fnd_profile_option_values.level_value_application_id%TYPE;
    lv_profile_option_value        fnd_profile_option_values.profile_option_value%TYPE;
   2009/07/09 DEL END */
    -- �̔Ԋ֐�
    lv_seq_no                      VARCHAR2(12);            -- �̔Ԍ�̌Œ蒷12���̔ԍ�
--
 /* 2009/07/09 DEL START
-- 2009/07/07 ADD START
    lv_present_month fnd_profile_option_values.profile_option_value%TYPE;
-- 2009/07/07 ADD END
   2009/07/09 DEL END */
-- 2009/07/09 ADD START
    lv_profile_option_value        VARCHAR2(100);
    lv_present_month               VARCHAR2(100);
-- 2009/07/09 ADD END
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    --**********************************************
    --***  �`�[�ԍ��������Ő؂�ւ��鏈�����s��  ***
    --**********************************************
--
    -- ================================
    -- 0.�֘A�f�[�^�擾
    -- ================================
    -- �V�X�e�����t�擾
    gd_sysdate  := SYSDATE;
--
    -- WHO�J�������擾
    gn_user_id  := FND_GLOBAL.USER_ID;              -- �ŏI�X�V���[�UID
    gn_login_id := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
--

-- 2009/07/07 ADD START
 /* 2009/07/09 DEL START
    -- ================================
    -- �v���t�@�C�����擾
    -- ================================
    SELECT TO_CHAR(TO_DATE(fpov.profile_option_value, gv_yyyymm),gv_yyyymm)
    INTO   lv_present_month
    FROM   fnd_profile_option_values  fpov
          ,fnd_profile_options        fpo
          ,fnd_application            fa
    WHERE  fa.application_short_name = gv_app_name
    AND    fpo.application_id        = fa.application_id
    AND    fpo.profile_option_name   = gv_prof_option_name
    AND    fpov.application_id       = fa.application_id
    AND    fpov.level_id             = gn_level_id
    AND    fpo.profile_option_id     = fpov.profile_option_id;
   2009/07/09 DEL END */
--
-- 2009/07/09 ADD END
    lv_present_month := TO_CHAR(TO_DATE(FND_PROFILE.VALUE(gv_prof_option_name), gv_yyyymm),gv_yyyymm);
-- 2009/07/09 ADD END
    IF(lv_present_month < TO_CHAR(gd_sysdate,gv_yyyymm)) THEN
-- 2009/07/07 ADD END
  --
      -- ================================
      -- 1.�V�[�P���X�h���b�v
      -- ================================
      EXECUTE IMMEDIATE 'DROP SEQUENCE xxcmn.xxcmn_slip_no_s1';
  --
      -- ================================
      -- 2.�V�[�P���X�쐬
      -- ================================
      EXECUTE IMMEDIATE 'CREATE SEQUENCE xxcmn.xxcmn_slip_no_s1 MINVALUE 1 MAXVALUE 99999999 '
        || 'INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE';
  --
/* 2009/07/09 DEL START
      -- ================================
      -- 3.�v���t�@�C���l�X�V���擾
      -- ================================
      SELECT fpov.application_id
            ,fpov.profile_option_id
            ,fpov.level_id
            ,fpov.level_value
            ,fpov.level_value_application_id
            ,TO_CHAR(ADD_MONTHS(TO_DATE(fpov.profile_option_value, gv_yyyymm), 1), gv_yyyymm)
      INTO   ln_apprication_id
            ,ln_profile_option_id
            ,ln_level_id
            ,ln_level_value
            ,ln_level_value_application_id
            ,lv_profile_option_value
      FROM   fnd_profile_option_values  fpov
            ,fnd_profile_options        fpo
            ,fnd_application            fa
      WHERE  fa.application_short_name = gv_app_name
      AND    fpo.application_id        = fa.application_id
      AND    fpo.profile_option_name   = gv_prof_option_name
      AND    fpov.application_id       = fa.application_id
      AND    fpov.level_id             = gn_level_id
      AND    fpo.profile_option_id     = fpov.profile_option_id;
  --
      -- ================================
      -- 4.�v���t�@�C���l�X�V
      -- ================================
      fnd_profile_option_values_pkg.update_row(
        x_application_id             => ln_apprication_id
       ,x_profile_option_id          => ln_profile_option_id
       ,x_level_id                   => ln_level_id
       ,x_level_value                => ln_level_value
       ,x_level_value_application_id => ln_level_value_application_id
       ,x_profile_option_value       => lv_profile_option_value
       ,x_last_update_date           => gd_sysdate
       ,x_last_updated_by            => gn_user_id
       ,x_last_update_login          => gn_login_id
      );
   2009/07/09 DEL END */
-- 2009/07/09 ADD START
      -- ================================
      -- 4.�v���t�@�C���l�X�V
      -- ================================
      lv_profile_option_value := TO_CHAR(ADD_MONTHS(TO_DATE(lv_present_month, gv_yyyymm), 1), gv_yyyymm);
      IF(FND_PROFILE.SAVE(gv_prof_option_name, lv_profile_option_value, 'SITE'))THEN
        NULL;
      END IF;
-- 2009/07/09 ADD END
  --
      -- ================================
      -- 5.�̔Ԋ֐��̎��s(�̔ԉ\���m�F)
      -- ================================
      xxcmn_common_pkg.get_seq_no(
        iv_seq_class => NULL              -- �̔Ԃ���ԍ���\���敪
       ,ov_seq_no    => lv_seq_no         -- �̔Ԃ����Œ蒷12���̔ԍ�
       ,ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
  --
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- 2009/07/07 ADD START
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, cv_no_change_msg || lv_present_month);
    END IF;
-- 2009/07/07 ADD END
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf           OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2)         -- �G���[�R�[�h     #�Œ�#
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add start 1.5
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.5
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
/*
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
*/
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn000001c;
/
