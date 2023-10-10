create or replace PACKAGE BODY      XX034RI001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name     : XX034RI001C(body)
 * Description      : �������f�[�^�̃C���|�[�g�A�y�ѓ��̓`�F�b�N���s���܂��B
 * MD.050           : ������̓o�b�`����(AR)    OCSJ/BFAFIN/MD050/F702
 * MD.070           : ������́iAR�j�C���|�[�g  OCSJ/BFAFIN/MD070/F702
 * Version          : 11.5.10.2.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  call_ldr_xx034rl001c   �����˗��f�[�^�̓ǂݍ��݁A�������� (C-1)
 *  set_distinct_data      �ꎞ�\�̃f�[�^���� (C-2)
 *  call_xx034ri002c       �����˗��e�[�u���ւ̃f�[�^�R�s�[�A���̓`�F�b�N (C-3)
 *  chk_concurrent         �R���J�����g�`�F�b�N����
 *  upd_load_data          ���[�h�f�[�^�X�V����
 *  del_interface_table    �C���^�[�t�F�[�X�e�[�u���폜
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2005/01/12   1.0            main�V�K�쐬
 *  2005/03/09   1.1            �s��Ή�
 *  2005/05/31   11.5.10.1.2    xx00_global_pkg.application_short_name�̌�g�p�C��
 *  2005/08/22   11.5.10.1.4    ���[�h�f�[�^�X�V�s��C��
 *  2005/09/02   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2006/09/05   11.5.10.2.5    �A�b�v���[�h�����ŕ������[�U�̓������s�\�Ƃ���
 *                              ����̌��A�f�[�^�폜�����̌��C��
 *  2007/08/01   11.5.10.2.10   �G���[���̃f�[�^�N���A������commit�������Ă���
 *                              ���[���o�b�N�Ńf�[�^���������邱�Ƃ̏C��
 *  2021/12/17   11.5.10.2.11   [E_�{�ғ�_17678]�Ή� �d�q����ۑ��@�����Ή�
 *  2023/10/03   11.5.10.2.12   [E_�{�ғ�_19542]�Ή� SQLLDR��DB�ڑ�����C��
 *
 *****************************************************************************************/
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
--###########################  �Œ蕔 END   ############################
--
  -- *** �O���[�o���萔 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --���ʏo�͗p���t�`��1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --���ʏo�͗p���t�`��2
--
  -- xx00_concurrent_pkg.wait_for_request�p
  cv_error            CONSTANT VARCHAR2(20) := 'ERROR';      --�X�e�[�^�X(ERROR)
  cv_dateted          CONSTANT VARCHAR2(20) := 'DELETED';    --�X�e�[�^�X(DELETED)
  cv_terminated       CONSTANT VARCHAR2(20) := 'TERMINATED'; --�X�e�[�^�X(TERMINATED)
  cv_warning          CONSTANT VARCHAR2(20) := 'WARNING';    --�X�e�[�^�X(WARNING)
  cv_standby          CONSTANT VARCHAR2(20) := 'STANDBY';    --�X�e�[�^�X(STANDBY)
  cv_complete         CONSTANT VARCHAR2(8)  := 'COMPLETE';   --�R���J�����g�I���t�F�[�Y
  cv_inactive         CONSTANT VARCHAR2(8)  := 'INACTIVE';   --�R���J�����g�I���t�F�[�Y
--
  cv_source_name      CONSTANT VARCHAR2(20) := 'EXCEL';
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  data_load_fail_expt    EXCEPTION;              -- �f�[�^���[�h���s�G���[
  chk_concurrent_expt    EXCEPTION;              -- �R���J�����g���s�G���[
--
  /**********************************************************************************
   * Procedure Name   : del_interface_table
   * Description      : �C���^�[�t�F�[�X�e�[�u���폜
   ***********************************************************************************/
  PROCEDURE del_interface_table(
    in_request_no     IN  NUMBER,       -- 1.�v��ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_interface_table'; -- �v���O������
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- ������̓w�b�_�C���^�[�t�F�[�X�폜
    DELETE XX03_RECEIVABLE_SLIPS_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
--
    -- ������͖��׃C���^�[�t�F�[�X�폜
    DELETE XX03_RECEIVABLE_SLIPS_LINE_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
--
-- ver 11.5.10.2.10 Add Start
    commit;
-- ver 11.5.10.2.10 Add End
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_interface_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_load_data
   * Description      : ���[�h�f�[�^�X�V
   ***********************************************************************************/
  PROCEDURE upd_load_data(
    in_request_no     IN  NUMBER,       -- 1.�v��ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_load_data'; -- �v���O������
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
    -- Ver11.5.10.1.4 2005/08/22 Add Start
    lv_person_number VARCHAR2(30);
    -- Ver11.5.10.1.4 2005/08/22 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- ������̓w�b�_�C���^�[�t�F�[�X�X�V
    -- Ver11.5.10.1.4 2005/08/22 Add Start
    SELECT employee_number
    INTO   lv_person_number
    FROM   XX03_PER_PEOPLES_V
    WHERE  USER_ID = xx00_global_pkg.user_id
    AND    TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date;
    -- Ver11.5.10.1.4 2005/08/22 Add End
--
    -- ver 11.5.10.2.5 Chg Start
    ---- Ver11.5.10.1.4 2005/08/22 Modify Start
    --UPDATE  XX03_RECEIVABLE_SLIPS_IF
    --SET     request_id              = in_request_no,
    --        --entry_person_number     = xx00_global_pkg.user_name,          -- �\����
    --        --requestor_person_number = xx00_global_pkg.user_name,          -- �`�[���͎�
    --        entry_person_number     = lv_person_number,          -- �\����
    --        requestor_person_number = lv_person_number,          -- �`�[���͎�
    --        created_by              = xx00_global_pkg.created_by,
    --        last_updated_by         = xx00_global_pkg.last_updated_by,
    --        last_update_login       = xx00_global_pkg.last_update_login,
    --        program_application_id  = xx00_global_pkg.prog_appl_id,
    --        program_id              = xx00_global_pkg.conc_program_id
    --WHERE   source = cv_source_name;
    ---- Ver11.5.10.1.4 2005/08/22 Modify End
    UPDATE  XX03_RECEIVABLE_SLIPS_IF
    SET     entry_person_number     = lv_person_number,          -- �\����
            requestor_person_number = lv_person_number,          -- �`�[���͎�
            created_by              = xx00_global_pkg.created_by,
            last_updated_by         = xx00_global_pkg.last_updated_by,
            last_update_login       = xx00_global_pkg.last_update_login,
            program_application_id  = xx00_global_pkg.prog_appl_id,
            program_id              = xx00_global_pkg.conc_program_id,
            org_id                  = xx00_profile_pkg.value('ORG_ID')
    WHERE   request_id = in_request_no
      AND   source     = cv_source_name;
    -- ver 11.5.10.2.5 Chg End
--
    -- ������͖��׃C���^�[�t�F�[�X�X�V
    -- ver 11.5.10.2.5 Chg Start
    --UPDATE XX03_RECEIVABLE_SLIPS_LINE_IF
    --SET     request_id              = in_request_no,
    --        created_by              = xx00_global_pkg.created_by,
    --        last_updated_by         = xx00_global_pkg.last_updated_by,
    --        last_update_login       = xx00_global_pkg.last_update_login,
    --        program_application_id  = xx00_global_pkg.prog_appl_id,
    --        program_id              = xx00_global_pkg.conc_program_id
    --WHERE   source                  = cv_source_name;
    UPDATE XX03_RECEIVABLE_SLIPS_LINE_IF
    SET     created_by              = xx00_global_pkg.created_by,
            last_updated_by         = xx00_global_pkg.last_updated_by,
            last_update_login       = xx00_global_pkg.last_update_login,
            program_application_id  = xx00_global_pkg.prog_appl_id,
            program_id              = xx00_global_pkg.conc_program_id,
            org_id                  = xx00_profile_pkg.value('ORG_ID')
    WHERE   request_id = in_request_no
      AND   source     = cv_source_name;
    -- ver 11.5.10.2.5 Chg End
--
    -- �R�~�b�g
    COMMIT;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_load_data;
--
  /**********************************************************************************
   * Procedure Name   : call_ldr_xx034rl001c
   * Description      : �f�[�^���[�h�R���J�����g���s (C-1)
   ***********************************************************************************/
  PROCEDURE call_ldr_xx034rl001c(
    iv_file_name      IN  VARCHAR2,     -- 1.�f�[�^�t�@�C����(IN)
    on_request_no     OUT NUMBER,       -- 2.�v��ID(OUT)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_ldr_xx034rl001c'; -- �v���O������
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
    -- �f�[�^���[�h�v���O������
    cv_program_name     CONSTANT  VARCHAR2(11) := 'XX034RL001C';
-- Ver11.5.10.1.2 Add BEGIN
    cv_program_appl_sname CONSTANT  VARCHAR2(4) := 'XX03';
-- Ver11.5.10.1.2 Add END
-- ver 1.1 Change Start
    cv_ctl_file_name    CONSTANT  VARCHAR2(30) := 'LDR_XX03_RECEIVABLE_SLIPS_IF';
-- Ver11.5.10.2.12 Add Start
--    cv_oracle_sid       CONSTANT  VARCHAR2(30) := XX00_PROFILE_PKG.VALUE('CSF_MAP_DB_SID');
    cv_oracle_sid       CONSTANT  VARCHAR2(30) := XX00_PROFILE_PKG.VALUE('XXCFO1_SQLLDR_CONNECT_DB_NAME');
-- Ver11.5.10.2.12 Add End
    cv_org_id           CONSTANT  VARCHAR2(30) := xx00_profile_pkg.value('ORG_ID');
-- ver 1.1 Change End
--
    -- *** ���[�J���ϐ� ***
    lv_phase          VARCHAR2(240);    -- �t�F�[�Y(JA)
    lv_status         VARCHAR2(240);    -- �X�e�[�^�X(JA)
    lv_dev_phase      VARCHAR2(240);    -- �t�F�[�Y(US)
    lv_dev_status     VARCHAR2(240);    -- �X�e�[�^�X(US)
    lv_message        VARCHAR2(240);    -- �������b�Z�[�W
    lb_return         BOOLEAN;          -- �֐��߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
-- ver 1.1 Change Start
--    -- ������̓f�[�^���[�h�̌Ăяo��
--    on_request_no := xx00_request_pkg.submit_request(
--      xx00_global_pkg.application_short_name,   -- �A�v���P�[�V�����Z�k��
--      cv_program_name,                          -- �Ăяo���R���J�����g��
--      NULL,
--      NULL,
--      FALSE,
--      iv_file_name);
    -- ������̓f�[�^���[�h�̌Ăяo��
    on_request_no := xx00_request_pkg.submit_request(
-- Ver11.5.10.1.2 Modify BEGIN
      -- xx00_global_pkg.application_short_name,   -- �A�v���P�[�V�����Z�k��
      cv_program_appl_sname,
-- Ver11.5.10.1.2 Modify END
      cv_program_name,                          -- �Ăяo���R���J�����g��
      NULL,
      NULL,
      FALSE,
      cv_ctl_file_name,
      iv_file_name,
      cv_oracle_sid,
      cv_org_id);
-- ver 1.1 Change End
--
    -- ������̓f�[�^���[�h�N���`�F�b�N
    IF (NVL(on_request_no,0) = 0) THEN
      --(�G���[����)
      RAISE data_load_fail_expt;
    END IF;
    xx00_file_pkg.log('on_request_no=' || TO_CHAR(on_request_no));
--
    --�R�~�b�g
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN data_load_fail_expt THEN             --*** �f�[�^���[�h���s�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08024',
          'XX03_TOK_FILE_NAME',
          iv_file_name));                     -- �f�[�^���[�h���s���b�Z�[�W
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
      ROLLBACK;
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_ldr_xx034rl001c;
--
  /**********************************************************************************
   * Procedure Name   : set_distinct_data
   * Description      : �ꎞ�\�̃f�[�^���� (C-2)
   ***********************************************************************************/
  PROCEDURE set_distinct_data(
    in_request_no     IN  NUMBER,       -- 1.�v��ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_distinct_data'; -- �v���O������
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
    -- ������̓C���^�[�t�F�[�X(�w�b�_)��d���f�[�^�擾�J�[�\��
    CURSOR slip_if_head_data_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT    DISTINCT
--                xrsi.interface_id                    AS interface_id,                -- �C���^�[�t�F�C�XID
--                MAX(xrsi.source)                     AS source,                      -- �\�[�X
--                MAX(xrsi.wf_status)                  AS wf_status,                   -- �X�e�[�^�X
--                MAX(xrsi.slip_type_name)             AS slip_type_name,              -- �`�[���
--                MAX(xrsi.entry_date)                 AS entry_date,                  -- �N�[��
--                MAX(xrsi.requestor_person_number)    AS requestor_person_number,     -- �`�[���͎�
--                MAX(xrsi.approver_person_number)     AS approver_person_number,      -- ���F��
--                MAX(xrsi.invoice_date)               AS invoice_date,                -- ���������t
---- ver 1.1 Change Start
----                MAX(xrsi.TRANS_TYPE_ID)              AS TRANS_TYPE_ID,               -- ����^�C�vID
----                MAX(xrsi.CUSTOMER_ID)                AS CUSTOMER_ID,                 -- �ڋqID
----                MAX(xrsi.CUSTOMER_OFFICE_ID)         AS CUSTOMER_OFFICE_ID,          -- �ڋq���Ə�ID
--                MAX(xrsi.TRANS_TYPE_NAME)            AS TRANS_TYPE_NAME,             -- ����^�C�v
--                MAX(xrsi.CUSTOMER_NUMBER)            AS CUSTOMER_NUMBER,             -- �ڋq
--                MAX(xrsi.LOCATION)                   AS LOCATION,                    -- �ڋq���Ə�
---- ver 1.1 Change End
--                MAX(xrsi.COMMITMENT_NUMBER)          AS COMMITMENT_NUMBER,           -- �O����[���`�[�ԍ�
--                MAX(xrsi.ONETIME_CUSTOMER_NAME)      AS ONETIME_CUSTOMER_NAME,       -- �ꌩ�ڋq����
--                MAX(xrsi.ONETIME_CUSTOMER_KANA_NAME) AS ONETIME_CUSTOMER_KANA_NAME,  -- �J�i��
--                MAX(xrsi.ONETIME_CUSTOMER_ADDRESS_1) AS ONETIME_CUSTOMER_ADDRESS_1,  -- �Z���P
--                MAX(xrsi.ONETIME_CUSTOMER_ADDRESS_2) AS ONETIME_CUSTOMER_ADDRESS_2,  -- �Z���Q
--                MAX(xrsi.ONETIME_CUSTOMER_ADDRESS_3) AS ONETIME_CUSTOMER_ADDRESS_3,  -- �Z���R
--                MAX(xrsi.CURRENCY_CODE)              AS CURRENCY_CODE,               -- �ʉ݃R�[�h
--                MAX(xrsi.CONVERSION_RATE)            AS CONVERSION_RATE,             -- ���[�g
--                MAX(xrsi.CONVERSION_TYPE)            AS CONVERSION_TYPE,             -- ���[�g�^�C�v
--                MAX(xrsi.RECEIPT_METHOD_NAME)        AS RECEIPT_METHOD_NAME,         -- �x�����@
--                MAX(xrsi.terms_name)                 AS terms_name,                  -- �x������
--                MAX(xrsi.description)                AS description,                 -- ���l
--                MAX(xrsi.entry_person_number)        AS entry_person_number,         -- �\����
--                MAX(xrsi.gl_date)                    AS gl_date,                     -- �v���
--                MAX(xrsi.org_id)                     AS org_id,                      -- �I���OID
--                MAX(xrsi.created_by)                 AS created_by,
--                MAX(xrsi.creation_date)              AS creation_date,
--                MAX(xrsi.last_updated_by)            AS last_updated_by,
--                MAX(xrsi.last_update_date)           AS last_update_date,
--                MAX(xrsi.last_update_login)          AS last_update_login,
--                MAX(xrsi.request_id)                 AS request_id,
--                MAX(xrsi.program_application_id)     AS program_application_id,
--                MAX(xrsi.program_id)                 AS program_id,
--                MAX(xrsi.program_update_date)        AS program_update_date
--      FROM      XX03_RECEIVABLE_SLIPS_IF xrsi      -- ������̓C���^�[�t�F�[�X(�w�b�_)
--      WHERE     xrsi.request_id = in_request_no -- �v��ID�̓p�����[�^�w��
--      GROUP BY  xrsi.interface_id
--      ORDER BY  xrsi.interface_id;
      SELECT    DISTINCT
                    xrsi.interface_id                AS interface_id,                -- �C���^�[�t�F�C�XID
                MAX(xrsi.source)                     AS source,                      -- �\�[�X
                MAX(xrsi.wf_status)                  AS wf_status,                   -- �X�e�[�^�X
                    xrsi.slip_type_name              AS slip_type_name,              -- �`�[���
                MAX(xrsi.entry_date)                 AS entry_date,                  -- �N�[��
                MAX(xrsi.requestor_person_number)    AS requestor_person_number,     -- �`�[���͎�
                    xrsi.approver_person_number      AS approver_person_number,      -- ���F��
                    xrsi.invoice_date                AS invoice_date,                -- ���������t
                    xrsi.TRANS_TYPE_NAME             AS TRANS_TYPE_NAME,             -- ����^�C�v
                    xrsi.CUSTOMER_NUMBER             AS CUSTOMER_NUMBER,             -- �ڋq
                    xrsi.LOCATION                    AS LOCATION,                    -- �ڋq���Ə�
                    xrsi.COMMITMENT_NUMBER           AS COMMITMENT_NUMBER,           -- �O����[���`�[�ԍ�
                    xrsi.ONETIME_CUSTOMER_NAME       AS ONETIME_CUSTOMER_NAME,       -- �ꌩ�ڋq����
                    xrsi.ONETIME_CUSTOMER_KANA_NAME  AS ONETIME_CUSTOMER_KANA_NAME,  -- �J�i��
                    xrsi.ONETIME_CUSTOMER_ADDRESS_1  AS ONETIME_CUSTOMER_ADDRESS_1,  -- �Z���P
                    xrsi.ONETIME_CUSTOMER_ADDRESS_2  AS ONETIME_CUSTOMER_ADDRESS_2,  -- �Z���Q
                    xrsi.ONETIME_CUSTOMER_ADDRESS_3  AS ONETIME_CUSTOMER_ADDRESS_3,  -- �Z���R
                    xrsi.CURRENCY_CODE               AS CURRENCY_CODE,               -- �ʉ݃R�[�h
                    xrsi.CONVERSION_RATE             AS CONVERSION_RATE,             -- ���[�g
                    xrsi.CONVERSION_TYPE             AS CONVERSION_TYPE,             -- ���[�g�^�C�v
                    xrsi.RECEIPT_METHOD_NAME         AS RECEIPT_METHOD_NAME,         -- �x�����@
                    xrsi.terms_name                  AS terms_name,                  -- �x������
                    xrsi.description                 AS description,                 -- ���l
                MAX(xrsi.entry_person_number)        AS entry_person_number,         -- �\����
                    xrsi.gl_date                     AS gl_date,                     -- �v���
                MAX(xrsi.org_id)                     AS org_id,                      -- �I���OID
                -- ver 11.5.10.2.11 Add Start
                    xrsi.payment_ele_data_yes        AS payment_ele_data_yes,        -- �x���ē����d�q�f�[�^��̂���
                    xrsi.payment_ele_data_no         AS payment_ele_data_no,         -- �x���ē����d�q�f�[�^��̂Ȃ�
                -- ver 11.5.10.2.11 Add End
                MAX(xrsi.created_by)                 AS created_by,
                MAX(xrsi.creation_date)              AS creation_date,
                MAX(xrsi.last_updated_by)            AS last_updated_by,
                MAX(xrsi.last_update_date)           AS last_update_date,
                MAX(xrsi.last_update_login)          AS last_update_login,
                MAX(xrsi.request_id)                 AS request_id,
                MAX(xrsi.program_application_id)     AS program_application_id,
                MAX(xrsi.program_id)                 AS program_id,
                MAX(xrsi.program_update_date)        AS program_update_date
      FROM      XX03_RECEIVABLE_SLIPS_IF xrsi      -- ������̓C���^�[�t�F�[�X(�w�b�_)
      WHERE     xrsi.request_id = in_request_no -- �v��ID�̓p�����[�^�w��
      GROUP BY  xrsi.interface_id,
                xrsi.slip_type_name,
                xrsi.approver_person_number,
                xrsi.invoice_date,
                xrsi.TRANS_TYPE_NAME,
                xrsi.CUSTOMER_NUMBER,
                xrsi.LOCATION,
                xrsi.COMMITMENT_NUMBER,
                xrsi.ONETIME_CUSTOMER_NAME,
                xrsi.ONETIME_CUSTOMER_KANA_NAME,
                xrsi.ONETIME_CUSTOMER_ADDRESS_1,
                xrsi.ONETIME_CUSTOMER_ADDRESS_2,
                xrsi.ONETIME_CUSTOMER_ADDRESS_3,
                xrsi.CURRENCY_CODE,
                xrsi.CONVERSION_RATE,
                xrsi.CONVERSION_TYPE,
                xrsi.RECEIPT_METHOD_NAME,
                xrsi.terms_name,
                xrsi.description,
                xrsi.gl_date
                -- ver 11.5.10.2.11 Add Start
                ,
                xrsi.payment_ele_data_yes,
                xrsi.payment_ele_data_no
                -- ver 11.5.10.2.11 Add End
      ORDER BY  xrsi.interface_id;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- *** ���[�J���E���R�[�h ***
    -- ������̓C���^�[�t�F�[�X(�w�b�_)��d���f�[�^�擾���R�[�h
    slip_if_head_data_rec slip_if_head_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --������̓C���^�[�t�F�[�X(�w�b�_)��d���f�[�^�擾
    --�J�[�\���I�[�v��
    OPEN slip_if_head_data_cur;
--
    -- ������̓w�b�_�C���^�[�t�F�[�X�폜
    DELETE XX03_RECEIVABLE_SLIPS_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
--
    <<slip_interface_loop>>
    LOOP
      FETCH slip_if_head_data_cur INTO slip_if_head_data_rec;
      --�J�[�\���f�[�^�擾�`�F�b�N
      IF slip_if_head_data_cur%NOTFOUND THEN
          EXIT slip_interface_loop;
      END IF;
--
      -- �C���^�[�t�F�[�X�e�[�u���ւ̑}��
      INSERT INTO XX03_RECEIVABLE_SLIPS_IF (
        interface_id,                                      -- �C���^�[�t�F�C�XID
        source,                                            -- �\�[�X
        wf_status,                                         -- �X�e�[�^�X
        slip_type_name,                                    -- �`�[���
        entry_date,                                        -- �N�[��
        requestor_person_number,                           -- �`�[���͎�
        approver_person_number,                            -- ���F��
        invoice_date,                                      -- ���������t
-- ver 1.1 Change Start
--        trans_type_id,                                     -- ����^�C�vID
--        customer_id,                                       -- �ڋqID
--        customer_office_id,                                -- �ڋq���Ə�ID
        trans_type_name,                                   -- ����^�C�v
        customer_number,                                   -- �ڋq
        location,                                          -- �ڋq���Ə�
-- ver 1.1 Change End
        commitment_number,                                 -- �O����[���`�[�ԍ�
        onetime_customer_name,                             -- �ꌩ�ڋq����
        onetime_customer_kana_name,                        -- �J�i��
        onetime_customer_address_1,                        -- �Z���P
        onetime_customer_address_2,                        -- �Z���Q
        onetime_customer_address_3,                        -- �Z���R
        currency_code,                                     -- �ʉ݃R�[�h
        conversion_rate,                                   -- ���[�g
        conversion_type,                                   -- ���[�g�^�C�v
        receipt_method_name,                               -- �x�����@
        terms_name,                                        -- �x������
        description,                                       -- ���l
        entry_person_number,                               -- �\����
        gl_date,                                           -- �v���
        org_id,                                            -- �I���OID
        -- ver 11.5.10.2.11 Add Start
        payment_ele_data_yes,                              -- �x���ē����d�q�f�[�^��̂���
        payment_ele_data_no,                               -- �x���ē����d�q�f�[�^��̂Ȃ�
        -- ver 11.5.10.2.11 Add End
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date
      )VALUES(
        slip_if_head_data_rec.interface_id,                -- �C���^�[�t�F�C�XID
        slip_if_head_data_rec.source,                      -- �\�[�X
        slip_if_head_data_rec.wf_status,                   -- �X�e�[�^�X
        slip_if_head_data_rec.slip_type_name,              -- �`�[���
        slip_if_head_data_rec.entry_date,                  -- �N�[��
        slip_if_head_data_rec.requestor_person_number,     -- �`�[���͎�
        slip_if_head_data_rec.approver_person_number,      -- ���F��
        slip_if_head_data_rec.invoice_date,                -- ���������t
-- ver 1.1 Change Start
--        slip_if_head_data_rec.trans_type_id,               -- ����^�C�vID
--        slip_if_head_data_rec.customer_id,                 -- �ڋqID
--        slip_if_head_data_rec.customer_office_id,          -- �ڋq���Ə�ID
        slip_if_head_data_rec.trans_type_name,             -- ����^�C�v
        slip_if_head_data_rec.customer_number,             -- �ڋq
        slip_if_head_data_rec.location,                    -- �ڋq���Ə�
-- ver 1.1 Change End
        slip_if_head_data_rec.commitment_number,           -- �O����[���`�[�ԍ�
        slip_if_head_data_rec.onetime_customer_name,       -- �ꌩ�ڋq����
        slip_if_head_data_rec.onetime_customer_kana_name,  -- �J�i��
        slip_if_head_data_rec.onetime_customer_address_1,  -- �Z���P
        slip_if_head_data_rec.onetime_customer_address_2,  -- �Z���Q
        slip_if_head_data_rec.onetime_customer_address_3,  -- �Z���R
        slip_if_head_data_rec.currency_code,               -- �ʉ݃R�[�h
        slip_if_head_data_rec.conversion_rate,             -- ���[�g
        slip_if_head_data_rec.conversion_type,             -- ���[�g�^�C�v
        slip_if_head_data_rec.receipt_method_name,         -- �x�����@
        slip_if_head_data_rec.terms_name,                  -- �x������
        slip_if_head_data_rec.description,                 -- ���l
        slip_if_head_data_rec.entry_person_number,         -- �\����
        slip_if_head_data_rec.gl_date,                     -- �v���
        slip_if_head_data_rec.org_id,                      -- �I���OID
        -- ver 11.5.10.2.11 Add Start
        NVL(slip_if_head_data_rec.payment_ele_data_yes,'N'),  -- �x���ē����d�q�f�[�^��̂���
        NVL(slip_if_head_data_rec.payment_ele_data_no,'N'),   -- �x���ē����d�q�f�[�^��̂Ȃ�
        -- ver 11.5.10.2.11 Add End
        slip_if_head_data_rec.created_by,
        slip_if_head_data_rec.creation_date,
        slip_if_head_data_rec.last_updated_by,
        slip_if_head_data_rec.last_update_date,
        slip_if_head_data_rec.last_update_login,
        slip_if_head_data_rec.request_id,
        slip_if_head_data_rec.program_application_id,
        slip_if_head_data_rec.program_id,
        slip_if_head_data_rec.program_update_date
        );
--
    END LOOP slip_interface_loop;
    -- �J�[�\���N���[�Y
    CLOSE slip_if_head_data_cur;
    -- �R�~�b�g
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_distinct_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_concurrent
   * Description      : �R���J�����g�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE chk_concurrent(
    in_request_id       IN  NUMBER,       -- 1.�v��ID(IN)
    iv_file_name        IN  VARCHAR2,     -- 2.�f�[�^�t�@�C����(IN)
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_concurrent'; -- �v���O������
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
    ln_req_chk        BOOLEAN;         --�I���X�e�[�^�X�`�F�b�N
    lv_phase          VARCHAR2(240);   --�v���t�F�[�Y
    lv_status         VARCHAR2(240);   --�v���X�e�[�^�X
    lv_dev_phase      VARCHAR2(240);   --PG��Ŕ�r�ł���v���t�F�[�Y
    lv_dev_status     VARCHAR2(240);   --PG��Ŕ�r�ł���v���X�e�[�^�X
    lv_message        VARCHAR2(240);   --�v���I�����ɕK�v�ɂȂ�I�����b�Z�[�W
    ln_wait_interval  NUMBER;          --�`�F�b�N�Ԋu
    ln_max_wait       NUMBER;          --�ő�҂�����

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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --�`�F�b�N�Ԋu
    ln_wait_interval := xx00_profile_pkg.value('XX03_WAIT_INTERVAL');
    --MAX�҂�����
    ln_max_wait := xx00_profile_pkg.value('XX03_MAX_WAIT');
    --�R���J�����g�v���҂��֐�
    ln_req_chk := xx00_concurrent_pkg.wait_for_request(
      in_request_id,      -- �v��ID
      ln_wait_interval,   -- �`�F�b�N�Ԋu
      ln_max_wait,        -- �ő�҂�����
      lv_phase,           -- �v���t�F�[�YJA
      lv_status,          -- �v���X�e�[�^�XJA
      lv_dev_phase,       -- �v���t�F�[�YUS
      lv_dev_status,      -- �v���X�e�[�^�XUS
      lv_message);        -- �I�����b�Z�[�W
--
    --���O�o��
    xx00_file_pkg.log('ln_wait_interval = '||ln_wait_interval);
    xx00_file_pkg.log('ln_max_wait = '||ln_max_wait);
    xx00_file_pkg.log('lv_phase = '||lv_phase);
    xx00_file_pkg.log('lv_status = '||lv_status);
    xx00_file_pkg.log('lv_dev_phase = '||lv_dev_phase);
    xx00_file_pkg.log('lv_dev_status = '||lv_dev_status);
    xx00_file_pkg.log('lv_message = '||lv_message);
--
    -- �R���J�����g�̖߂�l�`�F�b�N
    IF (ln_req_chk = FALSE) THEN
      ov_retcode := xx00_common_pkg.set_status_error_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    -- �R���J�����g�̃t�F�[�Y�`�F�b�N
    IF (lv_dev_phase <> cv_complete)
      AND (lv_dev_phase <> cv_inactive)
    THEN
      ov_retcode := xx00_common_pkg.set_status_error_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    -- �R���J�����g�̃X�e�[�^�X�`�F�b�N
    IF (lv_dev_status = cv_error)
      OR (lv_dev_status = cv_dateted)
      OR (lv_dev_status = cv_terminated)
      OR (lv_dev_status = cv_standby)
      OR (lv_dev_status = cv_warning)
    THEN
      -- ver 11.5.10.2.5 Del Start
      ---- �C���^�[�t�F�[�X�e�[�u���폜����
      ---- ������̓w�b�_�C���^�[�t�F�[�X�폜
      --DELETE xx03_receivable_slips_if
      --WHERE source = cv_source_name;
      --
      ---- ������͖��׃C���^�[�t�F�[�X�폜
      --DELETE xx03_receivable_slips_line_if
      --WHERE source = cv_source_name;
      -- ver 11.5.10.2.5 Del End
--
      ov_retcode := xx00_common_pkg.set_status_warn_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_concurrent_expt THEN                    --*** �f�[�^���[�h���s�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08024',
          'XX03_TOK_FILE_NAME',
          iv_file_name));                     -- �f�[�^���[�h���s���b�Z�[�W
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : call_xx034ri002c
   * Description      : �������e�[�u���ւ̃f�[�^�R�s�[�A���̓`�F�b�N (C-3)
   ***********************************************************************************/
  PROCEDURE call_xx034ri002c(
    iv_source_name     IN  VARCHAR2,     -- 1.�\�[�X��(IN)
    in_req_load_no     IN  NUMBER,       -- 2.���[�h�����v��ID(IN)
    on_req_imp_no      OUT NUMBER,       -- 2.�C���|�[�g�v��ID(OUT)
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_xx034ri002c'; -- �v���O������
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
    -- �f�[�^���[�h�v���O������
    cv_program_name     CONSTANT  VARCHAR2(11) := 'XX034RI002C';
-- Ver11.5.10.1.2 Add BEGIN
    cv_program_appl_sname CONSTANT  VARCHAR2(4) := 'XX03';
-- Ver11.5.10.1.2 Add END
--
    -- *** ���[�J���ϐ� ***
    lv_phase          VARCHAR2(240);    -- �t�F�[�Y(JA)
    lv_status         VARCHAR2(240);    -- �X�e�[�^�X(JA)
    lv_dev_phase      VARCHAR2(240);    -- �t�F�[�Y(US)
    lv_dev_status     VARCHAR2(240);    -- �X�e�[�^�X(US)
    lv_message        VARCHAR2(240);    -- �������b�Z�[�W
    lb_return         BOOLEAN;          -- �֐��߂�l
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
    -- ������̓f�[�^�C���|�[�g�̌Ăяo��
    on_req_imp_no := xx00_request_pkg.submit_request(
-- Ver11.5.10.1.2 Modify BEGIN
      -- xx00_global_pkg.application_short_name,   -- �A�v���P�[�V�����Z�k��
      cv_program_appl_sname,
-- Ver11.5.10.1.2 Modify END
      cv_program_name,                          -- �Ăяo���R���J�����g��
      NULL,
      NULL,
      FALSE,
      iv_source_name,
      in_req_load_no);
--
    -- ������̓f�[�^�C���|�[�g�N���`�F�b�N
    IF (NVL(on_req_imp_no,0) = 0) THEN
      xx00_file_pkg.log('0 errror');
      --(�G���[����)
      RAISE data_load_fail_expt;
    END IF;
    xx00_file_pkg.log('on_req_imp_no=' || TO_CHAR(on_req_imp_no));
--
    --�R�~�b�g
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN data_load_fail_expt THEN             --*** �f�[�^���[�h���s�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08007'));                  -- �f�[�^���[�h���s���b�Z�[�W
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
      ROLLBACK;
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_xx034ri002c;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name        IN  VARCHAR2,     -- 1.�f�[�^�t�@�C����(IN)
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
    ln_request_no       NUMBER := 0;         -- �f�[�^���[�h�����v��ID
    ln_imp_req_no       NUMBER := 0;         -- �C���|�[�g�v��ID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =======================================
    -- �����˗��f�[�^�̓ǂݍ��݁A�������� (C-1)
    -- =======================================
    call_ldr_xx034rl001c(
      iv_file_name,         -- 1.�f�[�^�t�@�C����(IN)
      ln_request_no,        -- 2.�v��ID(OUT)
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      -- ver 11.5.10.2.5 Add Start
      del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
      -- ver 11.5.10.2.5 Add End
      --(�G���[����)
      RAISE global_process_expt;
    -- �x���X�e�[�^�X���A�������f
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =======================================
    -- �R���J�����g�`�F�b�N
    -- =======================================
    chk_concurrent(
      ln_request_no,        -- 1.�v��ID(IN)
      iv_file_name,         -- 2.�f�[�^�t�@�C����(IN)
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      -- ver 11.5.10.2.5 Add Start
      del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
      -- ver 11.5.10.2.5 Add End
      --(�G���[����)
      RAISE global_process_expt;
      --  �x���X�e�[�^�X���A�������f
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_normal_f) THEN
      -- ����X�e�[�^�X���݈̂ȍ~�̏����ɑ���
      -- =======================================
      -- ���[�h�f�[�^�X�V����
      -- =======================================
      upd_load_data(
        ln_request_no,        -- 1.�v��ID(IN)
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =======================================
      -- �ꎞ�\�̃f�[�^���� (C-2)
      -- =======================================
      set_distinct_data(
        ln_request_no,        -- 1.�v��ID(IN)
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =================================================
      -- �����˗��e�[�u���ւ̃f�[�^�R�s�[�A���̓`�F�b�N(C-3)
      -- =================================================
      call_xx034ri002c(
        cv_source_name,       -- 1.�\�[�X��(IN)
        ln_request_no,        -- 2.�f�[�^���[�h�v��ID(IN)
        ln_imp_req_no,        -- 3.�C���|�[�g�v��ID(IN)
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(�G���[����)
        RAISE global_process_expt;
      -- �x���X�e�[�^�X���A�������f
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        ov_retcode := xx00_common_pkg.set_status_warn_f;
      END IF;
--
    -- =======================================
      -- �R���J�����g�`�F�b�N
      -- =======================================
      chk_concurrent(
        ln_imp_req_no,        -- 1.�C���|�[�g�v��ID(IN)
        iv_file_name,         -- 2.�f�[�^�t�@�C����(IN)
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(�G���[����)
        RAISE global_process_expt;
        --  �x���X�e�[�^�X���A�������f
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        ov_retcode := xx00_common_pkg.set_status_warn_f;
      END IF;
--
    -- ver 11.5.10.2.5 Mov Start
    END IF;
    -- ver 11.5.10.2.5 Mov End
--
      -- =======================================
      -- �I������ (C-4)
      -- =======================================
      del_interface_table(
        ln_request_no,        -- 1.�v��ID(IN)
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
    -- ver 11.5.10.2.5 Mov Start
    --END IF;
    -- ver 11.5.10.2.5 Mov Start
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_name        IN  VARCHAR2)      -- 1.�f�[�^�t�@�C����(IN)
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
    -- ===============================
    -- ���O�w�b�_�̏o��
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_name,       -- 1.�f�[�^�t�@�C����(IN)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ���O�t�b�^�̏o��
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XX034RI001C;
/
