CREATE OR REPLACE PACKAGE BODY XXCOP004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A06C(body)
 * Description      : ����v��(���nIF)
 * MD.050           : ����v��(���nIF) MD050_COP_004_A06
 * Version          : ver1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������           (A-1)
 *  get_lastdate           �O��N�������擾   (A-2)
 *  open_utl_file          UTL�t�@�C���I�[�v��(A-3)
 *  write_h_plan_csv       ����v��CSV�쐬    (A-5)
 *  update_lastdate        �O��N�������X�V   (A-6)
 *  close_utl_file         UTL�t�@�C���N���[�Y(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/06    1.0   SCS.Uchida       �V�K�쐬
 *  2009/02/16    1.1   SCS.Fukada       ������Q012�Ή�(A-1�F�f�B���N�g�����擾�����ύX)
 *  2009/02/20    1.2   SCS.Fukada       ������Q013�Ή�(�f�o�b�O���b�Z�[�W���폜)
 *
 *****************************************************************************************/
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  --�V�X�e���ݒ�
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'XXCOP004A06C';       -- �p�b�P�[�W��
  gv_debug_mode              VARCHAR2(10)  := 'OFF';--NULL;                 -- �f�o�b�O���[�h�FON/OFF
  --���b�Z�[�W�ݒ�
  gv_xxcop          CONSTANT VARCHAR2(100) := 'XXCOP';              -- �A�v���P�[�V�����Z�k��
  gv_m_e_get_who    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00001';   -- WHO�J�����擾���s
  gv_m_e_get_pro    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';   -- �v���t�@�C���l�擾���s
  gv_m_e_no_data    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';   -- �Ώۃf�[�^�Ȃ�
  gv_m_e_lock       CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';   -- �e�[�u�����b�N�G���[���b�Z�[�W
  gv_m_n_fname      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';   -- �t�@�C�����o�̓��b�Z�[�W
  gv_m_e_fopen      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00034';   -- �t�@�C���I�[�v���������s
  gv_m_e_public     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00035';   -- �W��API/Oracle�G���[���b�Z�[�W
  gv_m_e_get_item   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00048';   -- ���ڎ擾���s���b�Z�[�W
  gv_m_e_fwrite     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10013';   -- �t�@�C�������ݏ������s
  gv_m_e_fopen_p    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10014';   -- �t�@�C���I�[�v���������s�^�t�@�C���p�X�s��
  gv_m_e_fopen_n    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10015';   -- �t�@�C���I�[�v���������s�^�t�@�C�����s��
  gv_m_e_perm_acc   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10016';   -- �t�@�C���A�N�Z�X�����G���[
  gv_m_e_update     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10017';   -- �O��N�������X�V�G���[
  --�g�[�N���ݒ�
  gv_t_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME'       ;   -- APP-XXCOP1-00002
  gv_t_value        CONSTANT VARCHAR2(100) := 'VALUE'           ;   -- APP-XXCOP1-00005
  gv_t_table        CONSTANT VARCHAR2(100) := 'TABLE'           ;   -- APP-XXCOP1-00007
  gv_t_file_name    CONSTANT VARCHAR2(100) := 'FILE_NAME'       ;   -- APP-XXCOP1-00033
  gv_t_data         CONSTANT VARCHAR2(100) := 'DATA'            ;   -- APP-XXCOP1-10013
  gv_t_item_name    CONSTANT VARCHAR2(100) := 'ITEM_NAME'       ;
  --�v���t�@�C����
  gv_p_if_dir       CONSTANT VARCHAR2(100) := 'XXCOP1_IF_DIRECTORY' ;  -- ���n�A�g�f�B���N�g���p�X
  gv_p_file_hiki    CONSTANT VARCHAR2(100) := 'XXCOP1_FILE_HIKITORI';  -- ����v��t�@�C����
  gv_p_com_cd       CONSTANT VARCHAR2(100) := 'XXCOP1_COMPANY_CODE' ;  -- ��ЃR�[�h
  --UTL_FILE�I�v�V����
  gv_utl_open_modew CONSTANT VARCHAR2(100)  := 'w'              ;   -- �I�[�v�����[�h [�������݃��[�h]
  gv_utl_max_size   CONSTANT BINARY_INTEGER := 32767            ;   -- �ő僌�R�[�h�� [max_linesize]
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    od_conv_date               OUT DATE,       --   �A�g����
    ov_inf_conv_dir_path       OUT VARCHAR2,   --   ���n�A�g�f�B���N�g���p�X
    ov_h_plan_file_name        OUT VARCHAR2,   --   ����v��t�@�C����
    ov_company_cd              OUT VARCHAR2,   --   ��ЃR�[�h
    ov_errbuf                  OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_dir_path  VARCHAR2(5000); -- ���n�A�g�f�B���N�g���p�X[�v���t�@�C���l]
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --1.�A�g�����擾
    od_conv_date := SYSDATE;
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('���A�g���� �F ' || TO_CHAR(od_conv_date),gv_debug_mode);
    --
--
    --2.who�J�������擾
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��CREATED_BY �F ' || TO_CHAR(gn_created_by),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��CREATION_DATE �F ' || TO_CHAR(gd_creation_date),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��LAST_UPDATED_BY �F ' || TO_CHAR(gn_last_updated_by),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��LAST_UPDATE_DATE �F ' || TO_CHAR(gd_last_update_date),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��LAST_UPDATE_LOGIN �F ' || TO_CHAR(gn_last_update_login),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��REQUEST_ID �F ' || TO_CHAR(gn_request_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��PROGRAM_APPLICATION_ID �F ' || TO_CHAR(gn_program_application_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��PROGRAM_ID �F ' || TO_CHAR(gn_program_id),gv_debug_mode);
    xxcop_common_pkg.put_debug_message('��PROGRAM_UPDATE_DATE �F ' || TO_CHAR(gd_program_update_date),gv_debug_mode);
    --
    IF ( gn_created_by              IS NULL
      OR gd_creation_date           IS NULL
      OR gn_last_updated_by         IS NULL
      OR gd_last_update_date        IS NULL
      OR gn_last_update_login       IS NULL
      OR gn_request_id              IS NULL
      OR gn_program_application_id  IS NULL
      OR gn_program_id              IS NULL
      OR gd_program_update_date     IS NULL
    )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_who
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--==1.1 Modify Start ===========================================================================
    --3.���n�A�g�f�B���N�g���p�X�擾
    --3-1.�f�B���N�g�����̎擾
   ov_inf_conv_dir_path := FND_PROFILE.VALUE(gv_p_if_dir);
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��Dir_Object�F ' || ov_inf_conv_dir_path,gv_debug_mode);
    --
    IF ( ov_inf_conv_dir_path IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '���n�A�g�f�B���N�g���p�X'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --3-2.�f�B���N�g���E�I�u�W�F�N�g���݊m�F
    BEGIN
      SELECT directory_path                              -- �f�B���N�g���E�I�u�W�F�N�g��
      INTO   lv_dir_path                                 -- ���n�A�g�f�B���N�g���p�X[����]
      FROM   all_directories                             -- �f�B���N�g���I�u�W�F�N�g�e�[�u��
      WHERE  directory_name = ov_inf_conv_dir_path       -- �f�B���N�g���p�X��r
      ;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message('��Dir_Path �F ' || lv_dir_path,gv_debug_mode);
      --
    EXCEPTION
      WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_get_pro
                       ,iv_token_name1  => gv_t_prof_name
                       ,iv_token_value1 => '���n�A�g�f�B���N�g���p�X'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;

--
--    --3.���n�A�g�f�B���N�g���p�X�擾
--    --3-1.��΃p�X�̎擾�i�v���t�@�C���j
--    lv_dir_path := FND_PROFILE.VALUE(gv_p_if_dir);
--    --���f�o�b�O���O�i�J���p�j
--    xxcop_common_pkg.put_debug_message('��Dir_Path �F ' || lv_dir_path,gv_debug_mode);
--    --
--    IF ( lv_dir_path IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => gv_xxcop
--                     ,iv_name         => gv_m_e_get_pro
--                     ,iv_token_name1  => gv_t_prof_name
--                     ,iv_token_value1 => '���n�A�g�f�B���N�g���p�X'
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_process_expt;
--    END IF;
--    --
--    --3-2.�f�B���N�g���E�I�u�W�F�N�g���̎擾�i�e�[�u���j
--    BEGIN
--      SELECT directory_name                              -- �f�B���N�g���E�I�u�W�F�N�g��
--      INTO   ov_inf_conv_dir_path                        -- ���n�A�g�f�B���N�g���p�X[����]
--      FROM   all_directories                             -- �f�B���N�g���I�u�W�F�N�g�e�[�u��
--      WHERE  directory_path = lv_dir_path                -- �f�B���N�g���p�X��r
--      ;
--      --���f�o�b�O���O�i�J���p�j
--      xxcop_common_pkg.put_debug_message('��Dir_Object �F ' || ov_inf_conv_dir_path,gv_debug_mode);
--      --
--    EXCEPTION
--      WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => gv_xxcop
--                       ,iv_name         => gv_m_e_get_pro
--                       ,iv_token_name1  => gv_t_prof_name
--                       ,iv_token_value1 => '���n�A�g�f�B���N�g���p�X'
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END;
--==1.1 Modify End =============================================================================
--
    --4.����v��t�@�C�����擾        [�v���t�@�C�����]
    ov_h_plan_file_name := FND_PROFILE.VALUE(gv_p_file_hiki);
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('������v��t�@�C���� �F ' || ov_h_plan_file_name,gv_debug_mode);
    --
    IF ( ov_h_plan_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '����v��t�@�C����'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --5.��ЃR�[�h�擾               [�v���t�@�C�����]
    ov_company_cd := FND_PROFILE.VALUE(gv_p_com_cd);
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('����ЃR�[�h �F ' || ov_company_cd,gv_debug_mode);
    --
    IF ( ov_company_cd IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '��ЃR�[�h'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : get_lastdate
   * Description      : �O��N�������擾(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_lastdate(
    od_last_if_date   OUT DATE,         --   �O��N������
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lastdate'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --1.�O��N�������擾
    SELECT last_process_date               -- �ŏI�A�g����
    INTO   od_last_if_date                 -- �O��N������ [����]
    FROM   xxcop_appl_controls             -- �v��p�R���g���[���e�[�u��
    WHERE  function_id = gv_pkg_name       -- �v���O��������r
    ;
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('���O��N������ �F ' || TO_CHAR(od_last_if_date),gv_debug_mode);
    --
    IF ( od_last_if_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_item
                     ,iv_token_name1  => gv_t_item_name
                     ,iv_token_value1 => '�O��N������'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- �������擾����0���擾�̏ꍇ �i�L�q���[�����j
    WHEN TOO_MANY_ROWS OR NO_DATA_FOUND THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_lastdate;
--
--
  /**********************************************************************************
   * Procedure Name   : open_utl_file
   * Description      : UTL�t�@�C���I�[�v��(A-3)
   ***********************************************************************************/
--
  PROCEDURE open_utl_file(
    iv_inf_conv_dir_path  IN  VARCHAR2,            --  ���n�A�g�f�B���N�g���p�X
    iv_h_plan_file_name   IN  VARCHAR2,            --  ����v��t�@�C����
    ot_file_handle        OUT UTL_FILE.FILE_TYPE,  --  �t�@�C���n���h��
    ov_errbuf             OUT VARCHAR2,            --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,            --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)            --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_utl_file'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      --1.�t�@�C���I�[�v��
      ot_file_handle := UTL_FILE.FOPEN(
                           iv_inf_conv_dir_path  --  ���n�A�g�f�B���N�g���p�X
                          ,iv_h_plan_file_name   --  ����v��t�@�C����
                          ,gv_utl_open_modew     --  �I�[�v�����[�h [�������݃��[�h]
                          ,gv_utl_max_size       --  �ő僌�R�[�h�� [max_linesize]
                        );
    --
    --[UTL_FILE.FOPEN]�̗�O
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN         -- �t�@�C���p�X�s���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen_p
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN UTL_FILE.INVALID_FILENAME THEN     -- �t�@�C�����s���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen_n
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN UTL_FILE.ACCESS_DENIED THEN        -- �t�@�C���A�N�Z�X�����G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_perm_acc
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN                        -- ���̑��I�[�v�����G���[�S��
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fopen
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END open_utl_file;
--
  /**********************************************************************************
   * Procedure Name   :
   * Description      : ����v���񒊏o(A-4)
   ***********************************************************************************/
   --�ȉ��̏����̓J�[�\���I�[�v���݂̂ł���ׁAsubmain�Ŏ��{
   --1.����v���񒊏o
   --2.�P�[�X���Z�o
--
  /**********************************************************************************
   * Procedure Name   : write_h_plan_csv
   * Description      : ����v��CSV�쐬(A-5)
   ***********************************************************************************/
--
  PROCEDURE write_h_plan_csv(
    it_file_handle     IN  UTL_FILE.FILE_TYPE,  --  �t�@�C���n���h��
    iv_output_csv_buf  IN  VARCHAR2,            --  �o�͕�����
    ov_errbuf          OUT VARCHAR2,            --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,            --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)            --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_utl_file'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      --1.����v��CSV�쐬
      UTL_FILE.PUT_LINE(
         it_file_handle     --  �t�@�C���n���h��
        ,iv_output_csv_buf  --  �o�͕�����
      );
    --
    --[UTL_FILE.PUT_LINE]�̗�O
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fwrite
                       ,iv_token_name1  => gv_t_data
                       ,iv_token_value1 => iv_output_csv_buf
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END write_h_plan_csv;
--
  /**********************************************************************************
   * Procedure Name   : update_lastdate
   * Description      : �O��N�������X�V(A-6)
   ***********************************************************************************/
--
  PROCEDURE update_lastdate(
    id_conv_date    IN  DATE,       --   �A�g����
    ov_errbuf       OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lastdate'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ld_last_if_date      xxcop_appl_controls.last_process_date%TYPE;
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
    resource_busy_expt   EXCEPTION;     -- �f�b�h���b�N�G���[
--
    PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --1.�e�[�u�����b�N
    BEGIN
      SELECT last_process_date                      -- �ŏI�A�g����
      INTO   ld_last_if_date
      FROM   xxcop_appl_controls                    -- �v��p�R���g���[���e�[�u��
      WHERE  function_id = gv_pkg_name              -- �v���O��������r
      FOR UPDATE OF last_process_date NOWAIT
      ;
    EXCEPTION
      WHEN resource_busy_expt                  -- ���\�[�X�r�W�[�i���b�N���j
        OR NO_DATA_FOUND                       -- �Ώۃf�[�^����
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_lock
                       ,iv_token_name1  => gv_t_table
                       ,iv_token_value1 => '�v��p�R���g���[���e�[�u��'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --2.�O��N�������X�V
    UPDATE xxcop_appl_controls                                 -- �v��p�R���g���[���e�[�u��
    SET    last_process_date      = id_conv_date               -- �ŏI�A�g����
           --�ȉ�WHO�J����
          ,last_updated_by        = gn_last_updated_by         -- LAST_UPDATED_BY
          ,last_update_date       = gd_last_update_date        -- LAST_UPDATE_DATE
          ,last_update_login      = gn_last_update_login       -- LAST_UPDATE_LOGIN
          ,request_id             = gn_request_id              -- REQUEST_ID
          ,program_application_id = gn_program_application_id  -- PROGRAM_APPLICATION_ID
          ,program_id             = gn_program_id              -- PROGRAM_ID
          ,program_update_date    = gd_program_update_date     -- PROGRAM_UPDATE_DATE
    WHERE  function_id = gv_pkg_name                           -- �v���O��������r
    ;
    --�X�V�G���[
    IF ( SQL%ROWCOUNT != 1 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_update
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END update_lastdate;
--
  /**********************************************************************************
   * Procedure Name   : close_utl_file
   * Description      : UTL�t�@�C���N���[�Y(A-7)
   ***********************************************************************************/
--
  PROCEDURE close_utl_file(
    iot_file_handle  IN OUT UTL_FILE.FILE_TYPE,  --  �t�@�C���n���h��
    ov_errbuf        OUT    VARCHAR2,            --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT    VARCHAR2,            --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT    VARCHAR2)            --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_utl_file'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      UTL_FILE.FCLOSE( iot_file_handle );
    --
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END close_utl_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE submain(
    ov_h_plan_file_name  OUT VARCHAR2,     --   ����v��t�@�C����
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
    ld_conv_date               DATE;            -- �A�g����
    lv_inf_conv_dir_path       VARCHAR2(5000);  -- ���n�A�g�f�B���N�g���p�X
    lv_h_plan_file_name        VARCHAR2(1000);  -- ����v��t�@�C����
    lv_company_cd              VARCHAR2(10);    -- ��ЃR�[�h
    ld_last_if_date            DATE;            -- �O��N������
    ln_case_quantity           NUMBER;          -- �P�[�X����
--
    lf_file_hand               UTL_FILE.FILE_TYPE;
    lv_output_csv_buf          VARCHAR2(100);   -- CSV�t�@�C���������ݗp���R�[�h�o�b�t�@
--
    -- *** ���[�J��RECORD�^ ***
    CURSOR l_h_plan_info_cur
    IS
      SELECT lv_company_cd                    c_cd                                      -- ��ЃR�[�h [���[�J���ϐ�]
            ,TO_CHAR(mfda.forecast_date,'YYYYMM')  fsda                                 -- �t�H�[�L���X�g�J�n��
            ,mfda.attribute5                  b_cd                                      -- ���_�R�[�h(DFF5)
            ,iimb.item_no                     i_no                                      -- �i�ځi���i�R�[�h�j
            ,SUM(mfda.original_forecast_quantity)  fo_q                                 -- ����
            ,ld_conv_date                     coda                                      -- �A�g���� [���[�J���ϐ�]
      FROM   mrp_forecast_dates               mfda                                      -- �t�H�[�L���X�g���t
            ,mrp_forecast_designators         mfde                                      -- �t�H�[�L���X�g��
            ,ic_item_mst_b                    iimb                                      -- OPM�i�ڃ}�X�^
            ,xxcop_item_categories1_v         xicv                                      -- �y����view�z�v��_�i�ڃJ�e�S���r���[1
      WHERE  mfda.forecast_designator  =  mfde.forecast_designator                      --�t�H�[�L���X�g����r
      AND    mfda.organization_id      =  mfde.organization_id                          --�݌ɑg�DID��r
      AND    mfde.attribute1           =  '01'                                          --�t�H�[�L���X�g����(1����v��)
      AND    mfda.inventory_item_id    =  xicv.inventory_item_id                        --�i��ID��r1(INV�i��ID)
      AND    xicv.item_id              =  iimb.item_id                                  --�i��ID��r2(OPM�i��ID)
      AND    TO_CHAR(mfda.forecast_date,'YYYYMM') >= TO_CHAR(ld_last_if_date,'YYYYMM')  --�����ȍ~�̃f�[�^
      GROUP BY TO_CHAR(mfda.forecast_date,'YYYYMM')
              ,mfda.attribute5
              ,iimb.item_no
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_h_plan_info_rec l_h_plan_info_cur%ROWTYPE;
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --*********************************************
    --*** �������F��������                        ***
    --*** ����NO�FA-1                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-1]Process Start',gv_debug_mode);
    --
    init(
       ld_conv_date                 --   �A�g����
      ,lv_inf_conv_dir_path         --   ���n�A�g�f�B���N�g���p�X
      ,lv_h_plan_file_name          --   ����v��t�@�C����
      ,lv_company_cd                --   ��ЃR�[�h
      ,lv_errbuf                    --   �G���[�E���b�Z�[�W          --# �Œ� #
      ,lv_retcode                   --   ���^�[���E�R�[�h            --# �Œ� #
      ,lv_errmsg                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-1:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --�f�o�b�O���O
--    fnd_file.put_line(FND_FILE.LOG,'A-1:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** �������F�O��N�������擾                 ***
    --*** ����NO�FA-2                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-2]Process Start',gv_debug_mode);
    --
    get_lastdate(
       ld_last_if_date              --   �O��N������
      ,lv_errbuf                    --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                   --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-2:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --�f�o�b�O���O
--    fnd_file.put_line(FND_FILE.LOG,'A-2:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** �������FUTL�t�@�C���I�[�v��              ***
    --*** ����NO�FA-3                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-3]Process Start',gv_debug_mode);
    --
    open_utl_file(
      lv_inf_conv_dir_path  --   ���n�A�g�f�B���N�g���p�X
     ,lv_h_plan_file_name   --   ����v��t�@�C����
     ,lf_file_hand          --   �t�@�C���n���h��
     ,lv_errbuf             --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode            --   ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-3:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --�f�o�b�O���O
--    fnd_file.put_line(FND_FILE.LOG,'A-3:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** �������F����v���񒊏o                 ***
    --*** ����NO�FA-4                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-4]Process Start',gv_debug_mode);
    --
    --�J�[�\���I�[�v��
    OPEN l_h_plan_info_cur;
--==1.2 Delete Start ===========================================================================
--    --�f�o�b�O���O
--    fnd_file.put_line(FND_FILE.LOG,'A-4:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --*********************************************
    --*** �������F����v��CSV�쐬                  ***
    --*** ����NO�FA-5                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-5]Process Start',gv_debug_mode);
    --
    <<row_loop>>
    LOOP
      FETCH l_h_plan_info_cur INTO l_h_plan_info_rec ;
      EXIT WHEN l_h_plan_info_cur%NOTFOUND;
      --
      --[���ʊ֐�]�P�[�X�����Z�֐��̌Ăяo���i�P�[�X���v�Z�j
      xxcop_common_pkg.get_case_quantity(
        iv_item_no               => l_h_plan_info_rec.i_no  -- �i�ڃR�[�h
       ,in_individual_quantity   => l_h_plan_info_rec.fo_q  -- �o������
       ,in_trunc_digits          => 0                       -- �؎̂Č���
       ,on_case_quantity         => ln_case_quantity        -- �P�[�X����
       ,ov_retcode               => lv_retcode              -- ���^�[���R�[�h
       ,ov_errbuf                => lv_errbuf               -- �G���[�E���b�Z�[�W
       ,ov_errmsg                => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--        --�f�o�b�O���O
--        fnd_file.put_line(FND_FILE.LOG,'A-5:Process Error');
--==1.2 Delete End   ===========================================================================
        RAISE global_api_others_expt;
      END IF;
      --
      --�t�@�C�������݃f�[�^�쐬
      lv_output_csv_buf := '"' || l_h_plan_info_rec.c_cd || '"'                -- ��ЃR�[�h
                 || ',' || l_h_plan_info_rec.fsda                              -- �N��
                 || ',' || '"' || l_h_plan_info_rec.b_cd || '"'                -- ���_�i����j�R�[�h
                 || ',' || '"' || l_h_plan_info_rec.i_no || '"'                -- ���i�R�[�h
                 || ',' || ln_case_quantity                                    -- �P�[�X��
                 || ',' || TO_CHAR(l_h_plan_info_rec.coda,'YYYYMMDDHH24MISS'); -- �A�g����
      --
      write_h_plan_csv(
         lf_file_hand       --  �t�@�C���n���h��
        ,lv_output_csv_buf  --  �o�͕�����
        ,lv_errbuf          --  �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode         --  ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg          --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = gv_status_error ) THEN
        gn_target_cnt := l_h_plan_info_cur%ROWCOUNT;
        gn_normal_cnt := gn_target_cnt - 1;
        gn_error_cnt  := 1;
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-5:Process Error');
        fnd_file.put_line(FND_FILE.LOG,'Record_NO:'||l_h_plan_info_cur%ROWCOUNT);
        fnd_file.put_line(FND_FILE.LOG,'Record_INFO:'||lv_output_csv_buf);
        RAISE global_process_expt;
      END IF;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message('��' || to_char(l_h_plan_info_cur%ROWCOUNT,'00000') || ':' || lv_output_csv_buf,gv_debug_mode);
      --
    END LOOP row_loop;
    --
    --���������W�v
    gn_target_cnt := l_h_plan_info_cur%ROWCOUNT;
    gn_normal_cnt := gn_target_cnt;
    --
    CLOSE l_h_plan_info_cur;
    --
    --0����������
    IF ( gn_target_cnt = 0 ) THEN
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-5:Process Success(0��)');
--==1.2 Delete End   ===========================================================================
      --
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_no_data
                   );
    ELSE
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-5:Process Success');
--==1.2 Delete End   ===========================================================================
      --
      --*********************************************
      --*** �������F�O��N�������X�V                 ***
      --*** ����NO�FA-6                            ***
      --*********************************************
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message('��[A-6]Process Start',gv_debug_mode);
      --
      update_lastdate(
         ld_conv_date                 --   �A�g����
        ,lv_errbuf                    --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                   --   ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      --
      IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--        --�f�o�b�O���O
--        fnd_file.put_line(FND_FILE.LOG,'A-6:Process Error');
--==1.2 Delete End   ===========================================================================
        RAISE global_process_expt;
      END IF;
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-6:Process Success');
--==1.2 Delete End   ===========================================================================
    END IF;
--
    --*********************************************
    --*** �������FUTL�t�@�C���N���[�Y              ***
    --*** ����NO�FA-7                            ***
    --*********************************************
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('��[A-7]Process Start',gv_debug_mode);
    --
    close_utl_file(
       lf_file_hand    --  �t�@�C���n���h��
      ,lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = gv_status_error ) THEN
--==1.2 Delete Start ===========================================================================
--      --�f�o�b�O���O
--      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Error');
--==1.2 Delete End   ===========================================================================
      RAISE global_process_expt;
    END IF;
--==1.2 Delete Start ===========================================================================
--    --�f�o�b�O���O
--    fnd_file.put_line(FND_FILE.LOG,'A-7:Process Success');
--==1.2 Delete End   ===========================================================================
--
    --�擾�����t�@�C������main�ɕԂ�
    ov_h_plan_file_name := lv_h_plan_file_name;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �t�@�C���N���[�Y����
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C���N���[�Y����
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y����
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf             OUT VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --�װ�I�����b�Z�[�W�i�S�������O�߂��j
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code      VARCHAR2(100);
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_h_plan_file_name  VARCHAR2(1000);  -- ����v��t�@�C����
--
  BEGIN
--
  --[retcode]�������i�L�q���[�����j
  retcode := gv_status_normal;
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- ���̓p�����[�^�o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => 'APP-XXCCP1-90008'
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_h_plan_file_name  -- ����v��t�@�C����
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    -- ===============================
    -- �o�̓t�@�C�����E�o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcop
                    ,iv_name         => gv_m_n_fname
                    ,iv_token_name1  => gv_t_file_name
                    ,iv_token_value1 => lv_h_plan_file_name
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- �G���[���b�Z�[�W�o�͏���
    -- ===============================
    IF ( retcode = gv_status_error ) AND ( lv_errmsg IS NULL ) THEN
      --��^���b�Z�[�W�E�Z�b�g
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_public
                   );
    END IF;
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
    );
    --
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- �Ώی����o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- ���������o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- �G���[�����o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
/*�����������������������������������������ȉ��g�p��������������������������������������������
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
��������������������������������������������������������������������������������������������*/
    --
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- �I�����b�Z�[�W�o��
    -- ===============================
    IF ( retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    --ELSIF( lv_retcode = gv_status_warn ) THEN
    --  lv_message_code := cv_warn_msg;
    ELSIF( retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- �G���[�����iROLLBACK�j
    -- ===============================
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
END XXCOP004A06C;
/
