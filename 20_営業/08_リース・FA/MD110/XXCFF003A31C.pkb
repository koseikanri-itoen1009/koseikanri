CREATE OR REPLACE PACKAGE BODY XXCFF003A31C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A31C(body)
 * Description      : ���[�X�_��o�^�ꗗ
 * MD.050           : ���[�X�_��o�^�ꗗ MD050_CFF_003_A31
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���̓p�����[�^�l���O�o�͏���(A-1)
 *  chk_input_param        ���̓p�����[�^�`�F�b�N����(A-2)
 *  get_lease_contr_list   ���[�X�_��o�^�ꗗ���擾����(A-3)
 *  ins_lease_contr_wk     ���[�X�_��o�^�ꗗ���[�N�f�[�^�쐬����(A-4)
 *  submit_svf_request     SVF�N������(A-5)
 *  del_lease_contr_wk     �f�[�^�폜����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS�R��          main�V�K�쐬
 *  2009/02/27    1.1   SCS�R��          SVF�o�͊֐��ɑΉ�
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
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF003A31C'; -- �p�b�P�[�W��
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- �A�v���P�[�V�����Z�k��
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W
  cv_msg_vld_fr_to    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00018'; -- �p�����[�^�Ó����`�F�b�N�G���[
  cv_msg_ins_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102'; -- �o�^�G���[
  cv_msg_del_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; -- �폜�G���[
  cv_msg_no_lines     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00010'; -- ����0���p���b�Z�[�W
  cv_msg_lock_err     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  -- �g�[�N����
  cv_tkn_column_name  CONSTANT VARCHAR2(20)  := 'COLUMN_NAME';      -- �J������
  cv_tkn_table_name   CONSTANT VARCHAR2(20)  := 'TABLE_NAME';       -- �e�[�u����
  cv_tkn_err_info     CONSTANT VARCHAR2(20)  := 'INFO';             -- �G���[���
  -- �g�[�N���l
  cv_tkv_lease_st_dt  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50046'; -- ���[�X�J�n��
  cv_tkv_wk_tab_name  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50152'; -- ���[�X�_��o�^�ꗗ���[���[�N�e�[�u��
  -- �_��X�e�[�^�X
  cv_st_contract      CONSTANT VARCHAR2(3) := '202';  -- �_��
  cv_st_re_lease      CONSTANT VARCHAR2(3) := '203';  -- �ă��[�X
  -- �x���p�x
  cv_pmt_type_mon     CONSTANT VARCHAR2(1) := '0';    -- ��
  cv_pmt_type_year    CONSTANT VARCHAR2(1) := '1';    -- �N
  -- ���[�X���
  cv_lease_kind_op    CONSTANT VARCHAR2(1) := '1';    -- Op
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_wk_ttype IS TABLE OF xxcff_rep_contr_list_wk%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_lease_contr_wk
   * Description      : �f�[�^�폜����(A-6)
   ***********************************************************************************/
  PROCEDURE del_lease_contr_wk(
    ov_errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_contr_wk'; -- �v���O������
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
    CURSOR contr_list_wk_cur
    IS
      SELECT request_id
        FROM xxcff_rep_contr_list_wk
       WHERE request_id = cn_request_id
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE l_request_id_ttype IS TABLE OF xxcff_rep_contr_list_wk.request_id%TYPE INDEX BY BINARY_INTEGER;
    l_request_id_tab   l_request_id_ttype;
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
    -- ���b�N�̎擾
    BEGIN
      OPEN contr_list_wk_cur;
      FETCH contr_list_wk_cur BULK COLLECT INTO l_request_id_tab;
      CLOSE contr_list_wk_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (contr_list_wk_cur%ISOPEN) THEN
          CLOSE contr_list_wk_cur;
        END IF;
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name, cv_msg_lock_err
                       ,cv_tkn_table_name, cv_tkv_wk_tab_name);
        RAISE global_process_expt;
    END;
    -- ���[�N�f�[�^�폜
    DELETE FROM xxcff_rep_contr_list_wk
     WHERE request_id = cn_request_id;
    -- �ϐ��̃N���A
    l_request_id_tab.DELETE;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       cv_appl_short_name, cv_msg_del_err
                      ,cv_tkn_table_name, cv_tkv_wk_tab_name
                      ,cv_tkn_err_info, ''
                      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_lease_contr_wk;
--
  /**********************************************************************************
   * Procedure Name   : submit_svf_request
   * Description      : SVF�N������(A-5)
   ***********************************************************************************/
  PROCEDURE submit_svf_request(
    ov_errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_svf_request'; -- �v���O������
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
    cv_rep_id    CONSTANT VARCHAR2(20) := 'XXCFF003A31';  -- ���[ID
    cv_svf_fname CONSTANT VARCHAR2(20) := 'XXCFF003A31S'; -- SVF�t�@�C����
--
    -- *** ���[�J���ϐ� ***
    lv_no_data_msg VARCHAR2(100);
    lv_file_name   VARCHAR2(100);
    lv_user_name   VARCHAR2(100);
    lv_resp_name   VARCHAR2(100);
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
    -- �o�̓t�@�C����
    lv_file_name := cv_rep_id || TO_CHAR(SYSDATE,'yyyymmdd') || TO_CHAR(cn_request_id) || '.pdf';
    -- ����0���p���b�Z�[�W
    lv_no_data_msg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_msg_no_lines);
    -- ���[�U�[��
    SELECT user_name
      INTO lv_user_name
      FROM fnd_user
     WHERE user_id = cn_created_by;
    -- �E�Ӗ�
    fnd_profile.get('RESP_NAME',lv_resp_name);
    -- SVF���[�N��API�Ăяo��
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name    => cv_pkg_name        -- �R���J�����g��
      ,iv_file_name    => lv_file_name       -- �o�̓t�@�C����
      ,iv_file_id      => cv_rep_id          -- ���[ID
      ,iv_output_mode  => '1'                -- �o�͋敪
      ,iv_frm_file     => cv_svf_fname || '.xml' -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => cv_svf_fname || '.vrq' -- �N�G���[�l���t�@�C����
      ,iv_org_id       => fnd_profile.value('ORG_ID') -- ORG_ID
      ,iv_user_name    => lv_user_name       -- ���[�U�[��
      ,iv_resp_name    => lv_resp_name       -- �E�Ӗ�
      ,iv_doc_name     => NULL               -- ������
      ,iv_printer_name => NULL               -- �v�����^��
      ,iv_request_id   => TO_CHAR(cn_request_id) -- �v��ID
      ,iv_nodata_msg   => lv_no_data_msg     -- ����0���p���b�Z�[�W
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
--
    -- �Ώۃf�[�^��0���������ꍇ�A�R���J�����g���O�Ƀ��b�Z�[�W���o��
    IF (gn_target_cnt = 0) THEN
      lv_retcode := xxccp_svfcommon_pkg.no_data_msg;
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
  END submit_svf_request;
--
  /**********************************************************************************
   * Procedure Name   : ins_lease_contr_wk
   * Description      : ���[�X�_��o�^�ꗗ���[�N�f�[�^�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE ins_lease_contr_wk(
    i_wk_tab          IN  g_wk_ttype,    -- 1.���[�X�_��o�^�ꗗ���[�N�f�[�^
    ov_errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_contr_wk'; -- �v���O������
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
    FORALL i IN 1..NVL(i_wk_tab.LAST,0) SAVE EXCEPTIONS
      INSERT INTO xxcff_rep_contr_list_wk VALUES i_wk_tab(i);
    -- ���������C���N�������g
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
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
      -- ���������C���N�������g
      gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
      -- �G���[�����C���N�������g
      gn_error_cnt := gn_error_cnt + SQL%BULK_EXCEPTIONS.COUNT;
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       cv_appl_short_name, cv_msg_ins_err
                      ,cv_tkn_table_name, cv_tkv_wk_tab_name
                      ,cv_tkn_err_info, ''
                      );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_lease_contr_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_contr_list
   * Description      : ���[�X�_��o�^�ꗗ���擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_lease_contr_list(
    id_lease_st_date_fr  IN  DATE,          -- 1.���[�X�J�n��FROM
    id_lease_st_date_to  IN  DATE,          -- 2.���[�X�J�n��TO
    iv_lease_company     IN  VARCHAR2,      -- 3.���[�X��ЃR�[�h
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.���[�X���FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.���[�X���TO
    iv_lease_type        IN  VARCHAR2,      -- 6.���[�X�敪
    ov_errbuf            OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode           OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg            OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_contr_list'; -- �v���O������
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
    cn_bulk_size  CONSTANT PLS_INTEGER  := 200;
--
    -- *** ���[�J���ϐ� ***
    l_wk_tab    g_wk_ttype;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�_��o�^�ꗗ���
    CURSOR lease_contr_cur
    IS
      SELECT (SELECT xlcv.lease_company_code ||' '|| xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company                -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,xch.comments                       -- ����
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class                  -- ���[�X���
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type                   -- ���[�X�敪
            ,TO_CHAR(xch.contract_date,'yyyy/mm/dd') AS contract_date -- ���[�X�_���
            ,TO_CHAR(xch.lease_start_date,'yyyy/mm/dd') AS lease_start_date -- ���[�X�J�n��
            ,TO_CHAR(xch.lease_end_date,'yyyy/mm/dd') AS lease_end_date -- ���[�X�I����
            ,xch.payment_frequency              -- �x����
            ,(SELECT xptv.payment_type_name
                FROM xxcff_payment_type_v xptv
               WHERE xptv.payment_type_code = xch.payment_type
              ) AS payment_type                 -- �p�x
            ,(CASE xch.payment_type
              WHEN cv_pmt_type_mon THEN xch.payment_frequency
              WHEN cv_pmt_type_year THEN xch.payment_frequency * 12
              END) AS term                      -- ����
            ,TO_CHAR(xch.first_payment_date,'yyyy/mm/dd') AS first_payment_date -- ����x����
            ,TO_CHAR(xch.second_payment_date,'yyyy/mm/dd') AS second_payment_date -- 2��ڎx����
            ,LTRIM(TO_CHAR(xch.third_payment_date,'00')) AS third_payment_date -- 3��ڈȍ~�x����
            ,SUM(CASE xcl.lease_kind
                 WHEN cv_lease_kind_op THEN 0
                 ELSE 1 END
             ) AS fin_cnt                       -- ���א��iFin���j
            ,SUM(CASE xcl.lease_kind
                 WHEN cv_lease_kind_op THEN 1
                 ELSE 0 END
             ) AS op_cnt                        -- ���א��iOp���j
            ,SUM(NVL(xhis.estimated_cash_price,xcl.estimated_cash_price)
             ) AS estimated_cash_price          -- ���ό����w�����z
            ,SUM(NVL(xhis.gross_charge,xcl.gross_charge)
             ) AS gross_charge                  -- ���[�X�����z�i���[�X���j
            ,SUM(NVL(xhis.gross_tax_charge,xcl.gross_tax_charge)
             ) AS gross_tax_charge              -- ���[�X�����z�i����Łj
            ,SUM(NVL(xhis.gross_total_charge,xcl.gross_total_charge)
             ) AS gross_total_charge            -- ���[�X�����z�i�v�j
            ,SUM(NVL(xhis.gross_deduction,xcl.gross_deduction)
             ) AS gross_deduction               -- �T���z���z�i���[�X���j
            ,SUM(NVL(xhis.gross_tax_deduction,xcl.gross_tax_deduction)
             ) AS gross_tax_deduction           -- �T���z���z�i����Łj
            ,SUM(NVL(xhis.gross_total_deduction,xcl.gross_total_deduction)
             ) AS gross_total_deduction         -- �T���z���z�i�v�j
            ,SUM(NVL(xhis.first_charge,xcl.first_charge)
             ) AS first_charge                  -- ���񃊁[�X���i���[�X���j
            ,SUM(NVL(xhis.first_tax_charge,xcl.first_tax_charge)
             ) AS first_tax_charge              -- ���񃊁[�X���i����Łj
            ,SUM(NVL(xhis.first_total_charge,xcl.first_total_charge)
             ) AS first_total_charge            -- ���񃊁[�X���i�v�j
            ,SUM(NVL(xhis.second_charge,xcl.second_charge)
             ) AS second_charge                 -- ���z���[�X���i���[�X���j
            ,SUM(NVL(xhis.second_tax_charge,xcl.second_tax_charge)
             ) AS second_tax_charge             -- ���z���[�X���i����Łj
            ,SUM(NVL(xhis.second_total_charge,xcl.second_total_charge)
             ) AS second_total_charge           -- ���z���[�X���i�v�j
            -- WHO�J����
            ,cn_created_by             AS created_by
            ,cd_creation_date          AS creation_date
            ,cn_last_updated_by        AS last_updated_by
            ,cd_last_update_date       AS last_update_date
            ,cn_last_update_login      AS last_update_login
            ,cn_request_id             AS request_id
            ,cn_program_application_id AS program_application_id
            ,cn_program_id             AS program_id
            ,cd_program_update_date    AS program_update_date
      FROM xxcff_contract_headers xch
      INNER JOIN xxcff_contract_lines xcl
         ON xch.contract_header_id = xcl.contract_header_id
       LEFT JOIN xxcff_contract_histories xhis
         ON xcl.contract_line_id = xhis.contract_line_id
        AND xch.contract_header_id = xhis.contract_header_id
      WHERE (xhis.contract_status = cv_st_contract
          OR xhis.contract_status = cv_st_re_lease
          OR xhis.contract_status IS NULL)
        AND xcl.expiration_date IS NULL
        AND EXISTS (
            SELECT 'x'
              FROM xxcff_contract_lines xcl2
             WHERE xcl2.contract_header_id = xch.contract_header_id
               AND xcl2.cancellation_date IS NULL)
        AND xch.lease_start_date >= id_lease_st_date_fr
        AND xch.lease_start_date <= NVL(id_lease_st_date_to,xch.lease_start_date)
        AND xch.lease_company = NVL(iv_lease_company,xch.lease_company)
        AND xch.lease_class >= NVL(iv_lease_class_fr,xch.lease_class)
        AND xch.lease_class <= NVL(iv_lease_class_to,xch.lease_class)
        AND xch.lease_type = NVL(iv_lease_type,xch.lease_type)
      GROUP BY
             xch.lease_company                  -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,xch.lease_start_date               -- ���[�X�J�n��
            ,xch.lease_end_date                 -- ���[�X�I����
            ,xch.contract_date                  -- ���[�X�_���
            ,xch.comments                       -- ����
            ,xch.lease_class                    -- ���[�X���
            ,xch.lease_type                     -- ���[�X�敪
            ,xch.payment_frequency              -- �x����
            ,xch.payment_type                   -- �p�x
            ,xch.first_payment_date             -- ����x����
            ,xch.second_payment_date            -- 2��ڎx����
            ,xch.third_payment_date             -- 3��ڈȍ~�x����
            ,xch.contract_header_id
      ;
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
    OPEN lease_contr_cur;
    <<main_loop>>
    LOOP
      FETCH lease_contr_cur BULK COLLECT INTO l_wk_tab LIMIT cn_bulk_size;
      EXIT WHEN l_wk_tab.COUNT = 0;
      -- �Ώی����C���N�������g
      gn_target_cnt := gn_target_cnt + NVL(l_wk_tab.COUNT,0);
      -- ============================================
      -- A-5�D���[�X�_��o�^�ꗗ���[�N�f�[�^�쐬����
      -- ============================================
      ins_lease_contr_wk(
         l_wk_tab           -- 1.���[�X�_��o�^�ꗗ���[�N�f�[�^
        ,lv_errbuf          --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode         --   ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
      -- �R���N�V����������
      l_wk_tab.DELETE;
    END LOOP main_loop;
    CLOSE lease_contr_cur;
--
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
      -- �J�[�\���N���[�Y
      IF (lease_contr_cur%ISOPEN) THEN
        CLOSE lease_contr_cur;
      END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease_contr_list;
--
  /**********************************************************************************
   * Procedure Name   : chk_input_param
   * Description      : ���̓p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    id_lease_st_date_fr  IN  DATE,         -- 1.���[�X�J�n��FROM
    id_lease_st_date_to  IN  DATE,         -- 2.���[�X�J�n��TO
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- �v���O������
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
    -- ���[�X�J�n��TO�̓��͂�����ꍇ��FROM <= TO �̊֌W�`�F�b�N
    IF (id_lease_st_date_to IS NOT NULL) THEN
      IF (id_lease_st_date_fr > id_lease_st_date_to) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name,cv_msg_vld_fr_to
                     ,cv_tkn_column_name,cv_tkv_lease_st_dt
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END chk_input_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
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
    xxcff_common1_pkg.put_log_param(
       iv_which    => cv_which     -- �o�͋敪
      ,ov_retcode  => lv_retcode   --���^�[���R�[�h
      ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
      ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    id_lease_st_date_fr  IN  DATE,          -- 1.���[�X�J�n��FROM
    id_lease_st_date_to  IN  DATE,          -- 2.���[�X�J�n��TO
    iv_lease_company     IN  VARCHAR2,      -- 3.���[�X��ЃR�[�h
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.���[�X���FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.���[�X���TO
    iv_lease_type        IN  VARCHAR2,      -- 6.���[�X�敪
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
    -- <�J�[�\����>
--    CURSOR <cursor_name>_cur
--    IS
--     SELECT
--      FROM
--      WHERE
    -- <�J�[�\����>���R�[�h�^
--    <cursor_name>_rec <cursor_name>_cur%ROWTYPE;
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
    -- ============================================
    -- A-1�D���̓p�����[�^�l���O�o�͏���
    -- ============================================
    init(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D���̓p�����[�^�`�F�b�N����
    -- ============================================
    chk_input_param(
       id_lease_st_date_fr   -- 1.���[�X�J�n��FROM
      ,id_lease_st_date_to   -- 2.���[�X�J�n��TO
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D���[�X�_��o�^�ꗗ���擾����
    -- ============================================
    get_lease_contr_list(
       id_lease_st_date_fr   -- 1.���[�X�J�n��FROM
      ,id_lease_st_date_to   -- 2.���[�X�J�n��TO
      ,iv_lease_company      -- 3.���[�X��ЃR�[�h
      ,iv_lease_class_fr     -- 4.���[�X���FROM
      ,iv_lease_class_to     -- 5.���[�X���TO
      ,iv_lease_type         -- 6.���[�X�敪
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ����������0���ȏ�Ȃ�R�~�b�g���s
      IF (gn_normal_cnt > 0) THEN
        COMMIT;
      END IF;
    ELSE
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5�DSVF�N������
    -- ============================================
    submit_svf_request(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6�D�f�[�^�폜����
    -- ============================================
    del_lease_contr_wk(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
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
    errbuf               OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode              OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_lease_st_date_fr  IN  VARCHAR2,      -- 1.���[�X�J�n��FROM
    iv_lease_st_date_to  IN  VARCHAR2,      -- 2.���[�X�J�n��TO
    iv_lease_company     IN  VARCHAR2,      -- 3.���[�X��ЃR�[�h
    iv_lease_class_fr    IN  VARCHAR2,      -- 4.���[�X���FROM
    iv_lease_class_to    IN  VARCHAR2,      -- 5.���[�X���TO
    iv_lease_type        IN  VARCHAR2       -- 6.���[�X�敪
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
       iv_which   => cv_which
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
       TO_DATE(iv_lease_st_date_fr,'yyyy/mm/dd hh24:mi:ss')  -- 1.���[�X�J�n��FROM
      ,TO_DATE(iv_lease_st_date_to,'yyyy/mm/dd hh24:mi:ss')  -- 2.���[�X�J�n��TO
      ,iv_lease_company     -- 3.���[�X��ЃR�[�h
      ,iv_lease_class_fr    -- 4.���[�X���FROM
      ,iv_lease_class_to    -- 5.���[�X���TO
      ,iv_lease_type        -- 6.���[�X�敪
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ============================================
    -- A-7�D�I������
    -- ============================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
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
    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
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
END XXCFF003A31C;
/
