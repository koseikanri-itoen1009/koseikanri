CREATE OR REPLACE PACKAGE BODY APPS.xxwsh420005c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxwsh420005c(body)
 * Description      : ����OIF�폜����
 * MD.050           : �o�׎��� T_MD050_BPO_420
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      ��������(D-1)
 *  get_oif_data              �폜�Ώی����擾����(D-2)
 *  del_oif_data              ����OIF�폜����(D-3)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/19    1.0   SCS �茴 ���D    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- ��؂蕶��
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ���s����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O **
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_error_expt             EXCEPTION;     -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_msg_kbn             CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxwsh420005c';         -- �p�b�P�[�W��
--
  --���b�Z�[�W�ԍ�(�Œ菈��)
  gv_msg_42d_001         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00001';      -- ���[�U�[��
  gv_msg_42d_002         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00002';      -- �R���J�����g��
  gv_msg_42d_003         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00003';      -- �Z�p���[�^
  gv_msg_42d_004         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00012';      -- �����X�e�[�^�X
  gv_msg_42d_005         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10030';      -- �R���J�����g��^�G���[
  gv_msg_42d_006         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10118';      -- �N������
--
  --���b�Z�[�W�ԍ�(���R���J�����g��p)
  gv_msg_42d_007         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11553';      -- �v���t�@�C���擾�G���[
  gv_msg_42d_008         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11772';      -- �f�[�^�擾�G���[
  gv_msg_42d_009         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13403';      -- �e�[�u�����b�N�G���[
  gv_msg_42d_010         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13173';      -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  gv_msg_42d_011         CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13006';      -- �e�[�u���f�[�^�폜�G���[
  gv_msg_42d_012         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00008';      -- �����������b�Z�[�W
  gv_msg_42d_013         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00009';      -- �����������b�Z�[�W
  gv_msg_42d_014         CONSTANT VARCHAR2(15)  := 'APP-XXCMN-00010';      -- �G���[�������b�Z�[�W
--
  --�g�[�N��(�Œ菈��)
  gv_tkn_status          CONSTANT VARCHAR2(15)  := 'STATUS';
  gv_tkn_conc            CONSTANT VARCHAR2(15)  := 'CONC';
  gv_tkn_user            CONSTANT VARCHAR2(15)  := 'USER';
  gv_tkn_time            CONSTANT VARCHAR2(15)  := 'TIME';
--
  --�g�[�N��(���R���J�����g��p)
  gv_tkn_prof_name       CONSTANT VARCHAR2(15)  := 'PROF_NAME';            -- �v���t�@�C���FXXCOS1_ITOE_OU_MFG
  gv_tkn_data            CONSTANT VARCHAR2(15)  := 'DATA';                 -- �擾�f�[�^�F���Y�c�ƒP��ID
  gv_tkn_table           CONSTANT VARCHAR2(15)  := 'TABLE';                -- �e�[�u�����F����OIF
  gv_tkn_table_name      CONSTANT VARCHAR2(15)  := 'TABLE_NAME';           -- �e�[�u�����F����OIF
  gv_tkn_cnt             CONSTANT VARCHAR2(15)  := 'CNT';                  -- ����
--
  -- �g�[�N���\���p
  gv_tkn_name_org        CONSTANT VARCHAR2(30)  := '���Y�c�ƒP��ID';
  gv_tkn_name_oif        CONSTANT VARCHAR2(30)  := '����OIF';
--
  --�v���t�@�C��
  gv_prof_ou_mfg         CONSTANT VARCHAR2(20)  := 'XXCOS1_ITOE_OU_MFG';   -- XXCOS:���Y�c�ƒP�ʎ擾����
--
  -- �N�C�b�N�R�[�h�擾�p(���b�N�A�b�v�^�C�v)
  gv_cp_status_code      CONSTANT VARCHAR2(30)  := 'CP_STATUS_CODE';       -- �X�e�[�^�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����OIF�����i�[���郌�R�[�h
  TYPE g_rec_oif_data IS RECORD(
    interface_line_id   ra_interface_lines_all.interface_line_id%TYPE      -- ����OIF����ID
  );
  -- ����OIF�����i�[����z��
  TYPE g_tab_oif_data IS TABLE OF g_rec_oif_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target_cnt          NUMBER;                                           -- ��������
  gn_del_cnt             NUMBER;                                           -- ��������
  gn_error_cnt           NUMBER;                                           -- �G���[����
  gv_ou_mfg_name         VARCHAR(200);                                     -- ���Y�c�ƒP�ʎ擾����
  gt_ou_mfg_id           hr_operating_units.organization_id%TYPE;          -- ���Y�c�ƒP��ID
  gt_oif_data            g_tab_oif_data;                                   -- ����OIF���
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(D-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ========================================
    -- �v���t�@�C���l�擾
    -- ========================================
    gv_ou_mfg_name  := FND_PROFILE.VALUE(gv_prof_ou_mfg);  -- XXCOS:���Y�c�ƒP�ʎ擾����
--
    -- XXCOS:���Y�c�ƒP�ʎ擾���̂̎擾���ł��Ȃ��ꍇ�A�G���[�I��
    IF ( gv_ou_mfg_name IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42d_007,
                                            gv_tkn_prof_name, gv_prof_ou_mfg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- ���Y�c�ƒP��ID�擾
    -- ========================================
    BEGIN
      SELECT hou.organization_id  organization_id     -- �c�ƒP��ID
      INTO   gt_ou_mfg_id
      FROM   hr_operating_units   hou                 -- ���샆�j�b�g
      WHERE  hou.name             = gv_ou_mfg_name    -- XXCOS:���Y�c�ƒP�ʎ擾����
      ;
    EXCEPTION
      -- �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�I��
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�擾�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_008,
                                              gv_tkn_data,    gv_tkn_name_org);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   #############################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : get_oif_data
   * Description      : �폜�Ώی����擾����(D-2)
   ***********************************************************************************/
  PROCEDURE get_oif_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_oif_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ========================================
    -- ����OIF���擾
    -- ========================================
    CURSOR get_oif_data_cur
    IS
    SELECT interface_line_id  interface_line_id  -- ����OIF����ID
    FROM   ra_interface_lines_all
    WHERE  org_id  = gt_ou_mfg_id                -- ���Y�c�ƒP��ID
    FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ========================================
    -- ����OIF���擾
    -- ========================================
    BEGIN
      OPEN  get_oif_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_oif_data_cur BULK COLLECT INTO gt_oif_data;
      -- �폜�Ώی����Z�b�g
      gn_target_cnt := get_oif_data_cur%ROWCOUNT;
      -- �J�[�\���N���[�Y
      CLOSE get_oif_data_cur;
    EXCEPTION
      WHEN lock_error_expt THEN -- ���b�N�G���[
        -- �J�[�\���N���[�Y
        IF (get_oif_data_cur%ISOPEN) THEN
          CLOSE get_oif_data_cur;
        END IF;
        -- ���b�N�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_009,
                                              gv_tkn_table,   gv_tkn_name_oif);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_oif_data;
--
  /***********************************************************************************
   * Procedure Name   : del_oif_data
   * Description      : ����OIF�폜����(D-3)
   ***********************************************************************************/
  PROCEDURE del_oif_data(
    ov_errbuf            OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_oif_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ========================================
    -- ����OIF�폜
    -- ========================================
    BEGIN
     DELETE FROM ra_interface_lines_all
     WHERE       org_id  = gt_ou_mfg_id     -- ���Y�c�ƒP��ID
     ;
     -- �폜�����Z�b�g
     gn_del_cnt  := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u���f�[�^�폜�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,    gv_msg_42d_011,
                                              gv_tkn_table_name, gv_tkn_name_oif);
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   #############################################
--
  END del_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_error_cnt  := 0;
    gn_del_cnt    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(D-1)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode != gv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �폜�Ώی����擾����(D-2)
    -- ============================================
    get_oif_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode != gv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �폜�Ώی�����1���ȏ㑶�݂���ꍇ�̂ݍ폜���������s
    IF ( gn_target_cnt >= 1 ) THEN
      -- ============================================
      -- ����OIF�폜����(D-3)
      -- ============================================
      del_oif_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF ( lv_retcode != gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      -- �J�[�\�����J���Ă���΃N���[�Y����
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
    errbuf          OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42d_006,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���擾
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_003);
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    -- ���^�[���R�[�h������̏ꍇ
    IF ( lv_retcode = gv_status_normal ) THEN
      -- �폜�Ώی�����0���̏ꍇ
      IF ( gn_target_cnt = 0 ) THEN
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W���o��
        gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42d_010);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
      END IF;
--
    -- ���^�[���R�[�h������ȊO�̏ꍇ
    ELSE
      IF (lv_errmsg IS NULL) THEN
        -- �R���J�����g��^�G���[���b�Z�[�W
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_005);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
    END IF;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ============================================
    -- �I������(D-4)
    -- ============================================
    -- ��s�}��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');
--
    -- �����������b�Z�[�W
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_012,
                                           gv_tkn_cnt, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �����������b�Z�[�W
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_013,
                                           gv_tkn_cnt, TO_CHAR(gn_del_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �G���[�������b�Z�[�W
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42d_014,
                                           gv_tkn_cnt, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- ��s�}��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '');
--
    -- �X�e�[�^�X�擾
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = USERENV('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = gv_cp_status_code    -- CP_STATUS_CODE
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    -- �����X�e�[�^�X���b�Z�[�W
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_42d_004,
                                           gv_tkn_status, gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END xxwsh420005c;