CREATE OR REPLACE PACKAGE BODY XXCOP001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A02C(body)
 * Description      : ��v��̎捞
 * MD.050           : ��v��̎捞 MD050_COP_001_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_xmsi            ��v��I/F�\(�A�h�I��)�f�[�^�폜(A-7)
 *  delete_msi             ��v��OIF�f�[�^�폜(A-6)
 *  judge_msi              �o�^�m�F����(A-5)
 *  entry_msi              ��v��o�^����(A-4)
 *  entry_msii             �i�ڑ����X�V����(A-3)
 *  get_xmsi               �Ώۃf�[�^���o(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   Y.Goto           �V�K�쐬
 *  2009/08/21    1.1   S.Moriyama       0001134�Ή�
 *
 *****************************************************************************************/
--
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
  -- ���[�U�[��`��O
  -- ===============================
  format_ptn_validate_expt  EXCEPTION;     -- �A�b�v���[�h���̎擾�G���[
  profile_validate_expt     EXCEPTION;     -- �v���t�@�C���Ó����G���[
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
  lower_rows_expt           EXCEPTION;     -- �f�[�^�Ȃ���O
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP001A02C';           -- �p�b�P�[�W��
  --���b�Z�[�W����
  gv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- �A�v���P�[�V�����Z�k��
  --����
  gv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');
  --�v���O�������s�N����
  gd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- �V�X�e�����t�i�N�����j
  --���b�Z�[�W��
  gv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- �v���t�@�C���l�擾���s
  gv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';       -- �Ώۃf�[�^�Ȃ�
  gv_msg_00005              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';       -- �p�����[�^�G���[���b�Z�[�W
  gv_msg_00007              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';       -- �e�[�u�����b�N�G���[���b�Z�[�W
  gv_msg_00026              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00026';       -- �o�^�����^�C���A�E�g�G���[���b�Z�[�W
  gv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';       -- �o�^�����G���[���b�Z�[�W
  gv_msg_00031              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00031';       -- �A�b�v���[�h�h�e�f�[�^�폜�G���[���b�Z�[�W
  gv_msg_00036              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';       -- �A�b�v���[�h�t�@�C���o�̓��b�Z�[�W
  gv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';       -- �폜�����G���[���b�Z�[�W
  gv_msg_10011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10011';       -- �X�V�����G���[
  gv_msg_10012              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10012';       -- �R���J�����g���s�G���[
  --���b�Z�[�W�g�[�N��
  gv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_msg_00005_token_1      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_msg_00005_token_2      CONSTANT VARCHAR2(100) := 'VALUE';
  gv_msg_00007_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00026_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00031_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00031_token_2      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_1      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_2      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_msg_00036_token_3      CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_msg_00036_token_4      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_10011_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  gv_msg_10011_token_2      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_10012_token_1      CONSTANT VARCHAR2(100) := 'SYORI';
  --���b�Z�[�W�g�[�N���l
  gv_msg_table_msib         CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^';              --
  gv_msg_table_mism         CONSTANT VARCHAR2(100) := '�i��OIF';                 --
  gv_msg_table_msi          CONSTANT VARCHAR2(100) := '��v��OIF';             --
  gv_msg_table_xmsi         CONSTANT VARCHAR2(100) := '��v��I/F�e�[�u��';     --
  gv_msg_conc_incoin        CONSTANT VARCHAR2(100) := '�i�ڃC���|�[�g';          --
  gv_msg_conc_msi           CONSTANT VARCHAR2(100) := '��v��';                --
  gv_msg_param_format       CONSTANT VARCHAR2(100) := '�t�H�[�}�b�g�p�^�[��';    --
  --�v���t�@�C��
  gv_profile_baseline       CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_BASELINE';--�m��������
  gv_profile_name_baseline  CONSTANT VARCHAR2(100) := 'XXCOP�F�m��������';   --�m��������
  gv_profile_timeout        CONSTANT VARCHAR2(100) := 'XXCOP1_CONC_TIMEOUT';     --�^�C���A�E�g����
  gv_profile_name_timeout   CONSTANT VARCHAR2(100) := 'XXCOP�F�^�C���A�E�g����'; --�^�C���A�E�g����
  gv_profile_interval       CONSTANT VARCHAR2(100) := 'XXCOP1_CONC_INTERVAL';    --�����Ԋu
  gv_profile_name_interval  CONSTANT VARCHAR2(100) := 'XXCOP�F�����Ԋu';         --�����Ԋu
  gv_profile_master_org_id  CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';     --�}�X�^�g�DID
--��
  gv_profile_name_m_org_id  CONSTANT VARCHAR2(100) := 'XXCMN:�}�X�^�g�D';        --�}�X�^�g�DID
--��
  --���t�^�t�H�[�}�b�g
  gv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';              -- �N����
  --�N�C�b�N�R�[�h�^�C�v
  gv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';  -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  gv_enable                 CONSTANT VARCHAR2(100) := 'Y';                       -- �L��
  --�v��}�l�[�W�������X�e�[�^�X
  gn_status_wait            CONSTANT NUMBER        := 2;                         -- Waiting to be processed
  gn_status_processing      CONSTANT NUMBER        := 3;                         -- Being processed
  gn_status_error           CONSTANT NUMBER        := 4;                         -- Error
  gn_status_processed       CONSTANT NUMBER        := 5;                         -- Processed
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_lock_column_ttype  IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;           -- �sNo
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_fixed_baseline         NUMBER;
  gn_conc_interval          NUMBER;
  gn_conc_timeout           NUMBER;
--��
  gn_master_org_id          NUMBER;
--��
  gv_debug_mode             VARCHAR2(256);
--
  /**********************************************************************************
   * Procedure Name   : delete_xmsi
   * Description      : ��v��I/F�\(�A�h�I��)�f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xmsi(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_xmsi'; -- �v���O������
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
    l_row_no_tab              g_lock_column_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --��v��I/F�\�̃��b�N�擾
      SELECT xmsi.row_no
      BULK COLLECT INTO l_row_no_tab
      FROM  xxcop_mrp_schedule_interface xmsi
      WHERE xmsi.file_id = in_file_id
      FOR UPDATE OF xmsi.row_no NOWAIT;
--
      --��v��I/F�\�폜
      DELETE xxcop_mrp_schedule_interface xmsi
      WHERE  xmsi.file_id = in_file_id;
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00007
                              ,iv_token_name1  => gv_msg_00007_token_1
                              ,iv_token_value1 => gv_msg_table_xmsi
                              );
        RAISE global_api_expt;
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00031
                              ,iv_token_name1  => gv_msg_00031_token_1
                              ,iv_token_value1 => gv_msg_table_xmsi
                              ,iv_token_name2  => gv_msg_00031_token_2
                              ,iv_token_value3 => in_file_id
                              );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_xmsi;
--
  /**********************************************************************************
   * Procedure Name   : delete_msi
   * Description      : ��v��OIF�f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE delete_msi(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_msi'; -- �v���O������
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
    l_file_id_tab          g_lock_column_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --��v��OIF�̃��b�N�擾
      SELECT msi.attribute4  file_id
      BULK COLLECT INTO l_file_id_tab
      FROM  mrp_schedule_interface msi
      WHERE msi.attribute4 = in_file_id
      FOR UPDATE OF msi.attribute4 NOWAIT;
--
      --��v��OIF�폜
      DELETE mrp_schedule_interface msi
      WHERE msi.process_status = gn_status_processed
        AND msi.attribute4     = in_file_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN resource_busy_expt THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00007
                              ,iv_token_name1  => gv_msg_00007_token_1
                              ,iv_token_value1 => gv_msg_table_msi
                              );
        RAISE global_api_expt;
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00042
                              ,iv_token_name1  => gv_msg_00042_token_1
                              ,iv_token_value1 => gv_msg_table_msi
                              );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_msi;
--
  /**********************************************************************************
   * Procedure Name   : judge_msi
   * Description      : �o�^�m�F����(A-5)
   ***********************************************************************************/
  PROCEDURE judge_msi(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_msi'; -- �v���O������
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
    ln_wait_cnt               NUMBER;                                              -- ����������
    ln_processing_cnt         NUMBER;                                              -- ����������
    ln_error_cnt              NUMBER;                                              -- �G���[����
    ln_processed_cnt          NUMBER;                                              -- ���팏��
    ln_entry_cnt              NUMBER;                                              -- OIF�o�^����
    ld_init_time              NUMBER;                                              -- �R���J�����g�N������
    lv_timeout                VARCHAR2(1);                                         -- �^�C���A�E�g����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
      lv_timeout := gv_status_error;
    IF ( gn_conc_timeout > 0 ) THEN
      --�����J�n���Ԃ��擾
      ld_init_time := dbms_utility.get_time;
    END IF;
    <<waiting_loop>>
    LOOP
      --��v��OIF�̏����X�e�[�^�X���m�F
      SELECT SUM( DECODE( process_status, gn_status_wait      , 1, 0 ) ) wait_cnt
            ,SUM( DECODE( process_status, gn_status_processing, 1, 0 ) ) processing_cnt
            ,SUM( DECODE( process_status, gn_status_error     , 1, 0 ) ) error_cnt
            ,SUM( DECODE( process_status, gn_status_processed , 1, 0 ) ) processed_cnt
            ,COUNT('X')                                                  entry_cnt
      INTO   ln_wait_cnt
            ,ln_processing_cnt
            ,ln_error_cnt
            ,ln_processed_cnt
            ,ln_entry_cnt
      FROM  mrp_schedule_interface msi
      WHERE msi.attribute4 = in_file_id;
--
      --�v��}�l�[�W���̏I������
      IF ( ( ln_error_cnt + ln_processed_cnt ) = ln_entry_cnt ) THEN
        lv_timeout := gv_status_normal;
        EXIT waiting_loop;
      END IF;
      --�^�C���A�E�g���Ԃ̏I������
      IF ( (( dbms_utility.get_time - ld_init_time ) / 100 ) > gn_conc_timeout ) THEN
        EXIT waiting_loop;
      END IF;
      --�����Ԋu�b�̊ԑҋ@
      dbms_lock.sleep( gn_conc_interval );
    END LOOP waiting_loop;
--
    --�^�C���A�E�g�̔���
    IF ( lv_timeout = gv_status_error ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => gv_msg_appl_cont
                            ,iv_name         => gv_msg_00026
                            ,iv_token_name1  => gv_msg_00026_token_1
                            ,iv_token_value1 => gv_msg_conc_msi
                            );
      RAISE global_api_expt;
    END IF;
    --���������̔���
    IF ( ln_processed_cnt <> ln_entry_cnt ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => gv_msg_appl_cont
                            ,iv_name         => gv_msg_00027
                            ,iv_token_name1  => gv_msg_00027_token_1
                            ,iv_token_value1 => gv_msg_conc_msi
                            );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END judge_msi;
--
  /**********************************************************************************
   * Procedure Name   : entry_msi
   * Description      : ��v��o�^����(A-4)
   ***********************************************************************************/
  PROCEDURE entry_msi(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_msi'; -- �v���O������
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
    --�v��I�[�v���C���^�[�t�F�[�X�e�[�u���萔
    cn_schedule_level         CONSTANT NUMBER        := 2;                         --
    cv_insert_action          CONSTANT VARCHAR2(1)   := 'I';                       -- �ǉ�
    cv_delete_action          CONSTANT VARCHAR2(1)   := 'D';                       -- �폜
    cv_update_action          CONSTANT VARCHAR2(1)   := 'U';                       -- �X�V
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt             NUMBER;          -- �Ώی���
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --�f�[�^�C���T�[�g
      INSERT INTO mrp_schedule_interface (
         inventory_item_id
        ,schedule_designator
        ,organization_id
        ,last_update_date
        ,last_updated_by
        ,creation_date
        ,created_by
        ,last_update_login
        ,schedule_date
        ,schedule_quantity
        ,transaction_id
        ,process_status
        ,program_application_id
        ,program_id
        ,program_update_date
        ,attribute1
        ,attribute2
        ,attribute3
        ,attribute4
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
        ,attribute5
        ,attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
        ,action
      )
      SELECT inventory_item_id                 inventory_item_id
            ,schedule_designator               schedule_designator
            ,organization_id                   organization_id
            ,gd_last_update_date               last_update_date
            ,gn_last_updated_by                last_updated_by
            ,gd_creation_date                  creation_date
            ,gn_created_by                     created_by
            ,gn_last_update_login              last_update_login
            ,schedule_date                     schedule_date
            ,schedule_quantity                 schedule_quantity
            ,transaction_id                    transaction_id
            ,gn_status_wait                    process_status
            ,gn_program_application_id         program_application_id
            ,gn_program_id                     program_id
            ,gd_program_update_date            program_update_date
            ,attribute1                        attribute1
            ,attribute2                        attribute2
            ,attribute3                        attribute3
            ,in_file_id                        attribute4
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
            ,attribute5                        attribute5
            ,attribute6                        attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
            ,action                            action
      FROM (
        WITH xmsi_vw AS (
          SELECT xmsi.row_no                   row_no
                ,xmsi.schedule_designator      schedule_designator
                ,xmsi.item_code                item_code
                ,xmsi.schedule_date            schedule_date
                ,xmsi.schedule_quantity        schedule_quantity
                ,msib.inventory_item_id        inventory_item_id
                ,mp.organization_id            organization_id
                ,xmsi.schedule_prod_flg        schedule_prod_flg
                ,xmsi.deliver_from             deliver_from
                ,xmsi.shipment_date            shipment_date
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
                ,xmsi.schedule_type            schedule_type
                ,xmsi.schedule_prod_date       schedule_prod_date
                ,xmsi.prod_purchase_flg        prod_purchase_flg
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
          FROM   xxcop_mrp_schedule_interface  xmsi
                ,mrp_schedule_designators      msd
                ,mtl_system_items_b            msib
                ,mtl_parameters                mp
          WHERE msd.schedule_designator      = xmsi.schedule_designator
            AND msd.organization_id          = mp.organization_id
            AND msib.segment1                = xmsi.item_code
            AND msib.organization_id         = mp.organization_id
            AND mp.organization_code         = xmsi.organization_code
            AND xmsi.file_id                 = in_file_id
        )
        , msds_vw AS (
          SELECT msds.inventory_item_id        inventory_item_id
                ,msds.schedule_designator      schedule_designator
                ,msds.organization_id          organization_id
                ,msds.schedule_date            schedule_date
                ,msds.schedule_quantity        schedule_quantity
                ,msds.mps_transaction_id       mps_transaction_id
                --����2009/01/21 �ǉ�
                ,msds.attribute2               deliver_from
                --����2009/01/21 �ǉ�
          FROM   mrp_schedule_dates            msds
          WHERE msds.schedule_date           > gd_sysdate + gn_fixed_baseline
            AND msds.schedule_level          = cn_schedule_level
            AND EXISTS (
              SELECT 'x'
              FROM   xmsi_vw                   xmsiv
              WHERE msds.schedule_designator = xmsiv.schedule_designator
--20090821_Ver1.1_0001134_SCS.Moriyama_MOD_START
--                AND msds.organization_id     = xmsiv.organization_id
--                AND msds.inventory_item_id   = xmsiv.inventory_item_id
--                --����2009/01/21 �ǉ�
--                AND ( ( msds.attribute2 IS NULL AND xmsiv.deliver_from IS NULL)
--                   OR ( msds.attribute2 = xmsiv.deliver_from ) )
--                --����2009/01/21 �ǉ�
--                AND msds.inventory_item_id   = xmsiv.inventory_item_id
                AND(( xmsiv.schedule_type = 2
                    AND msds.attribute2 = xmsiv.deliver_from)
                OR  (xmsiv.schedule_type != 2
                    AND msds.organization_id = xmsiv.organization_id )
                )
--20090821_Ver1.1_0001134_SCS.Moriyama_MOD_END
            )
        )
        SELECT NVL( xmsiv.inventory_item_id  , msdsv.inventory_item_id )   inventory_item_id
              ,NVL( xmsiv.schedule_designator, msdsv.schedule_designator ) schedule_designator
              ,NVL( xmsiv.organization_id    , msdsv.organization_id )     organization_id
              ,NVL( xmsiv.schedule_date      , msdsv.schedule_date )       schedule_date
              ,NVL( xmsiv.schedule_quantity  , msdsv.schedule_quantity )   schedule_quantity
              ,msdsv.mps_transaction_id                                    transaction_id
              ,xmsiv.schedule_prod_flg                                     attribute1
              ,xmsiv.deliver_from                                          attribute2
              ,TO_CHAR( xmsiv.shipment_date  , gv_date_format )            attribute3
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
              ,TO_CHAR( xmsiv.schedule_prod_date , gv_date_format )        attribute5
              ,xmsiv.prod_purchase_flg                                     attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
              ,CASE
                  WHEN msdsv.mps_transaction_id IS NULL THEN cv_insert_action
                  WHEN xmsiv.row_no IS NULL THEN cv_delete_action
                  ELSE cv_update_action
               END                                                         action
        FROM   msds_vw msdsv
                  FULL OUTER JOIN xmsi_vw xmsiv
                ON (  xmsiv.schedule_designator  = msdsv.schedule_designator
                  AND xmsiv.organization_id      = msdsv.organization_id
                  AND xmsiv.inventory_item_id    = msdsv.inventory_item_id
                  AND xmsiv.schedule_date        = msdsv.schedule_date
                  --����2009/01/21 �ǉ�
                  AND xmsiv.deliver_from         = msdsv.deliver_from
                  --����2009/01/21 �ǉ�
                )
      );
      ln_target_cnt := SQL%ROWCOUNT;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '��v��OIF  �f�[�^�����F' || ln_target_cnt
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00027
                             ,iv_token_name1  => gv_msg_00027_token_1
                             ,iv_token_value1 => gv_msg_table_msi
                             );
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        RAISE global_api_expt;
    END;
    --�v��}�l�[�W���N���̂��߃R�~�b�g
    COMMIT;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END entry_msi;
--
  /**********************************************************************************
   * Procedure Name   : entry_msii
   * Description      : �i�ڑ����X�V����(A-3)
   ***********************************************************************************/
  PROCEDURE entry_msii(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_msii'; -- �v���O������
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
    --�i�ڃC���|�[�g�e�[�u���萔
    cn_msii_process_flag      CONSTANT NUMBER        := 1;                         -- Pending
    cv_msii_transaction_type  CONSTANT VARCHAR2(6)   := 'UPDATE';                  -- �X�V
    cn_mrp_planning_code      CONSTANT NUMBER        := 8;                         -- MPS/MPP�v��
    --�i�ڃC���|�[�g�R���J�����g�萔
    cv_application            CONSTANT VARCHAR2(3)   := 'INV';                     --
    cv_program                CONSTANT VARCHAR2(6)   := 'INCOIN';                  -- �i�ڃC���|�[�g
    cn_all_org_flag           CONSTANT NUMBER        := 1;                         -- �S�g�D
    cn_validate_flag          CONSTANT NUMBER        := 1;                         -- �i�ڂ̌���    :YES
    cn_process_flag           CONSTANT NUMBER        := 1;                         -- �i�ڏ���      :YES
    cn_delete_flag            CONSTANT NUMBER        := 1;                         -- �����ύs�̍폜:YES
    cn_action_type            CONSTANT NUMBER        := 2;                         -- �X�V
    --�R���J�����g�v���ҋ@�萔
    cv_complete_phase         CONSTANT VARCHAR2(8)   := 'COMPLETE';                -- ����
    cv_successful_status      CONSTANT VARCHAR2(8)   := 'NORMAL';                  -- ����
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt             NUMBER;          -- �Ώی���
    ln_process_set            NUMBER;          -- �����Z�b�g
    ln_request_id             NUMBER;          -- �i�ڃC���|�[�g�v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  fnd_lookups.meaning%TYPE;
    lv_status                 fnd_lookups.meaning%TYPE;
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                fnd_concurrent_requests.completion_text%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --�����Z�b�g�̎擾
      SELECT xxcop_item_import_row_no_s1.NEXTVAL
      INTO   ln_process_set
      FROM DUAL;
      --�f�[�^�C���T�[�g
      INSERT INTO mtl_system_items_interface (
         inventory_item_id
        ,organization_id
        ,process_flag
        ,transaction_type
        ,transaction_id
        ,set_process_id
        ,mrp_planning_code
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT msib.inventory_item_id        inventory_item_id
            ,msib.organization_id          organization_id
            ,cn_msii_process_flag          process_flag
            ,cv_msii_transaction_type      transaction_type
            ,NULL                          transaction_id
            ,ln_process_set                set_process_id
            ,cn_mrp_planning_code          mrp_planning_code
            ,gn_last_updated_by            last_updated_by
            ,gd_last_update_date           last_update_date
            ,gn_last_update_login          last_update_login
            ,gn_request_id                 request_id
            ,gn_program_application_id     program_application_id
            ,gn_program_id                 program_id
            ,gd_program_update_date        program_update_date
      FROM   mtl_system_items_b            msib
      WHERE msib.mrp_planning_code      <> cn_mrp_planning_code
        AND EXISTS (
          SELECT 'x'
          FROM   xxcop_mrp_schedule_interface  xmsi
                ,mrp_schedule_designators      msd
                ,mtl_parameters                mp
          WHERE msib.segment1               =  xmsi.item_code
            AND msib.organization_id        =  mp.organization_id
            AND msd.schedule_designator     =  xmsi.schedule_designator
            AND msd.organization_id         =  mp.organization_id
            AND mp.organization_code        =  xmsi.organization_code
            AND xmsi.file_id                =  in_file_id
        );
      ln_target_cnt := SQL%ROWCOUNT;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '�i��OIF      �f�[�^�����F' || ln_target_cnt
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00027
                             ,iv_token_name1  => gv_msg_00027_token_1
                             ,iv_token_value1 => gv_msg_table_mism
                             );
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        RAISE global_api_expt;
    END;
    IF ( ln_target_cnt > 0 ) THEN
      --�i�ڃC���|�[�g�R���J�����g�N��
      ln_request_id := fnd_request.submit_request(
                          application  => cv_application
                         ,program      => cv_program
--��
--                         ,argument1    => fnd_profile.value(gv_profile_master_org_id)
                         ,argument1    => TO_CHAR(gn_master_org_id)
--��
                         ,argument2    => cn_all_org_flag
                         ,argument3    => cn_validate_flag
                         ,argument4    => cn_process_flag
                         ,argument5    => cn_delete_flag
                         ,argument6    => ln_process_set
                         ,argument7    => cn_action_type
                       );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '�i�ڃC���|�[�g�N�� =>  �F' || ln_request_id
      );
      IF ( ln_request_id = 0 ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10012
                              ,iv_token_name1  => gv_msg_10012_token_1
                              ,iv_token_value1 => gv_msg_conc_incoin
                              );
        RAISE global_api_expt;
      END IF;
--
      --�i�ڃC���|�[�g�R���J�����g�N���̂��߃R�~�b�g
      COMMIT;
--
      --�i�ڃC���|�[�g�R���J�����g�̏I���ҋ@
      lb_wait_result := fnd_concurrent.wait_for_request(
                           request_id   => ln_request_id
                          ,interval     => gn_conc_interval
                          ,max_wait     => gn_conc_timeout
                          ,phase        => lv_phase
                          ,status       => lv_status
                          ,dev_phase    => lv_dev_phase
                          ,dev_status   => lv_dev_status
                          ,message      => lv_message
                        );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '�i�ڃC���|�[�gSTATUS'
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  �t�F�[�Y             �F' || lv_phase
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  �X�e�[�^�X           �F' || lv_status
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  DEV�t�F�[�Y          �F' || lv_dev_phase
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  DEV�X�e�[�^�X        �F' || lv_dev_status
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  ���b�Z�[�W           �F' || lv_message
      );
      --�i�ڃC���|�[�g�R���J�����g�ُ̈�I��
      IF ( lv_dev_phase  NOT IN ( cv_complete_phase )
        OR lv_dev_status NOT IN ( cv_successful_status ) )
      THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10011
                              ,iv_token_name1  => gv_msg_10011_token_1
                              ,iv_token_value1 => ln_request_id
                              ,iv_token_name2  => gv_msg_10011_token_2
                              ,iv_token_value2 => gv_msg_table_msib
                             );
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END entry_msii;
--
  /**********************************************************************************
   * Procedure Name   : get_xmsi
   * Description      : �Ώۃf�[�^���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_xmsi(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xmsi'; -- �v���O������
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
    l_row_no_tab              g_lock_column_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --��v��I/F�\�̃��b�N�擾
    BEGIN
      SELECT xmsi.row_no
      BULK COLLECT INTO l_row_no_tab
      FROM  xxcop_mrp_schedule_interface xmsi
      WHERE xmsi.file_id = in_file_id
      FOR UPDATE OF xmsi.row_no NOWAIT;
      --�Ώی����̐ݒ�
      gn_target_cnt := l_row_no_tab.COUNT;
    EXCEPTION
      WHEN resource_busy_expt THEN
        ov_retcode   := gv_status_error;
        ov_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00007
                             ,iv_token_name1  => gv_msg_00007_token_1
                             ,iv_token_value1 => gv_msg_table_xmsi
                             );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_xmsi;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_format_validate   CONSTANT VARCHAR2(1) := '1';
    cv_lower_rows        CONSTANT VARCHAR2(1) := '2';
--
    -- *** ���[�J���ϐ� ***
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- �t�@�C���A�b�v���[�h����
    lv_file_name         xxcop_mrp_schedule_interface.file_name%TYPE;     -- �t�@�C����
    lv_param_name        VARCHAR2(100);   -- �p�����[�^��
    lv_param_value       VARCHAR2(100);   -- �p�����[�^�l
    lv_value             VARCHAR2(100);   -- �v���t�@�C���l
    lv_profile_name      VARCHAR2(100);   -- �v���t�@�C����
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f�o�b�N���b�Z�[�W�o��
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --�A�b�v���[�h����
    BEGIN
      SELECT flv.meaning  meaning
      INTO   lv_upload_name
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type        = gv_lookup_type
        AND  flv.lookup_code        = iv_format
        AND  flv.language           = gv_lang
        AND  flv.source_lang        = gv_lang
        AND  flv.enabled_flag       = gv_enable
        AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                            AND NVL(flv.end_date_active  ,gd_sysdate);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := cv_format_validate;
    END;
--
    --�t�@�C����
    BEGIN
      SELECT xmsi.file_name   file_name
      INTO   lv_file_name
      FROM   xxcop_mrp_schedule_interface xmsi
      WHERE  xmsi.file_id = in_file_id
        AND  ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := cv_lower_rows;
    END;
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --�A�b�v���[�h���o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_appl_cont
                   ,iv_name         => gv_msg_00036
                   ,iv_token_name1  => gv_msg_00036_token_1
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_msg_00036_token_2
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_msg_00036_token_3
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_msg_00036_token_4
                   ,iv_token_value4 => lv_file_name
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --�󔒍s��}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    IF ( lv_retcode = cv_format_validate ) THEN
      --�t�@�C���A�b�v���[�h���̂̎擾�Ɏ��s�����ꍇ
      RAISE format_ptn_validate_expt;
    ELSIF ( lv_retcode = cv_lower_rows ) THEN
      --�Ώۃ��R�[�h���Ȃ��ꍇ
      RAISE lower_rows_expt;
    END IF;
    --�v���t�@�C���̎擾
    --�m��������
    lv_value := fnd_profile.value( gv_profile_baseline );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_baseline;
      RAISE profile_validate_expt;
    END IF;
    gn_fixed_baseline := TO_NUMBER(lv_value);
    --�^�C���A�E�g����
    lv_value := fnd_profile.value( gv_profile_timeout );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_timeout;
      RAISE profile_validate_expt;
    END IF;
    gn_conc_timeout := TO_NUMBER(lv_value);
    --�����Ԋu
    lv_value := fnd_profile.value( gv_profile_interval );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_interval;
      RAISE profile_validate_expt;
    END IF;
    gn_conc_interval := TO_NUMBER(lv_value);
--��
    ---------------------------------------------------
    --  �}�X�^�i�ڑg�D�̎擾
    ---------------------------------------------------
    BEGIN
      gn_master_org_id  :=  TO_NUMBER(fnd_profile.value(gv_profile_master_org_id));
    EXCEPTION
      WHEN OTHERS THEN
        gn_master_org_id  :=  NULL;
    END;
    -- �v���t�@�C���F�}�X�^�i�ڑg�D���擾�o���Ȃ����G���[�ƂȂ�ꍇ
    IF ( gn_master_org_id IS NULL ) THEN
      lv_profile_name := gv_profile_name_m_org_id;
      RAISE profile_validate_expt;
    END IF;
--��
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00002
                     ,iv_token_name1  => gv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
      ov_retcode := gv_status_error;
    WHEN format_ptn_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00005
                     ,iv_token_name1  => gv_msg_00005_token_1
                     ,iv_token_value1 => gv_msg_param_format
                     ,iv_token_name2  => gv_msg_00005_token_2
                     ,iv_token_value2 => iv_format
                   );
      ov_retcode := gv_status_error;
    WHEN lower_rows_expt THEN                           --*** <��O�R�����g> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00003
                   );
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2,     -- 2.�t�H�[�}�b�g�p�^�[��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    BEGIN
      -- ===============================
      -- A-1�D��������
      -- ===============================
      init(
         in_file_id                     -- �t�@�C��ID
        ,iv_format                      -- �t�H�[�}�b�g�p�^�[��
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-2�D�Ώۃf�[�^���o����
      -- ===============================
      get_xmsi(
         in_file_id                     -- �t�@�C��ID
        ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '��v��I/F  �f�[�^�����F' || gn_target_cnt
      );
      -- ===============================
      -- A-3�D�i�ڑ����X�V����
      -- ===============================
      entry_msii(
         in_file_id                   -- �t�@�C��ID
        ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-4�D��v��o�^����
      -- ===============================
      entry_msi(
         in_file_id                   -- �t�@�C��ID
        ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-5�D�o�^�m�F����
      -- ===============================
      judge_msi(
         in_file_id                   -- �t�@�C��ID
        ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
    --�I���X�e�[�^�X���G���[�̏ꍇ�A���[���o�b�N����B
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      gn_error_cnt := 1;
        --�G���[���b�Z�[�W���o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
    END IF;
--
    -- ===============================
    -- A-6�D��v��OIF�f�[�^�폜
    -- ===============================
    delete_msi(
       in_file_id                   -- �t�@�C��ID
      ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-7�D��v��I/F�\(�A�h�I��)�f�[�^�폜
    -- ===============================
    delete_xmsi(
       in_file_id                   -- �t�@�C��ID
      ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
--
    IF ( ov_retcode = gv_status_normal ) THEN
      --�I���X�e�[�^�X������̏ꍇ�A�����������Z�b�g����B
      gn_normal_cnt := gn_target_cnt;
    ELSE
      --�I���X�e�[�^�X���G���[�̏ꍇ�A�R�~�b�g����B
      COMMIT;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
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
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id    IN  NUMBER,        -- 1.�t�@�C��ID
    iv_format     IN  VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --�ُ�I�����b�Z�[�W
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_file_id  -- �t�@�C��ID
      ,iv_format   -- �t�H�[�}�b�g�p�^�[��
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => lv_errbuf --�G���[���b�Z�[�W
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOP001A02C;
/
