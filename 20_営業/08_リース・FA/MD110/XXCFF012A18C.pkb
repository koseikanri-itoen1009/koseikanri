create or replace PACKAGE BODY XXCFF012A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF012A18C(body)
 * Description      : ���[�X���c�����|�[�g
 * MD.050           : ���[�X���c�����|�[�g MD050_CFF_012_A18
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���̓p�����[�^�l���O�o�͏���(A-1)
 *  chk_period_name        ��v���ԃ`�F�b�N����(A-2)
 *  get_first_period       ��v���Ԋ���擾����(A-3)
 *  get_contract_info      ���[�X�_����擾����(A-4)
 *  get_pay_planning       ���[�X�x���v����擾����(A-5)
 *  edit_bal_in_obg_wk     ���[�X���c�����[�N�f�[�^�ҏW���� (A-6)
 *  ins_bal_in_obg_wk      ���[�X���c�����[�N�f�[�^�쐬���� (A-7)
 *  submit_svf_request     SVF�N������(A-8)
 *  del_bal_in_obg_wk      �f�[�^�폜����(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   SCS�R��          main�V�K�쐬
 *  2009/02/26    1.1   SCS�R��          [��QCFF_063] ����A2��ړ����x���̏ꍇ�̕s��Ή�
 *  2009/02/27    1.2   SCS�R��          SVF�o�͊֐��ɑΉ�
 *  2009/07/17    1.3   SCS����          [�����e�X�g��Q0000417] �x���v��̓����x�����[�X���擾�����C��
 *  2009/07/31    1.4   SCS�n��          [�����e�X�g��Q0000417(�ǉ�)]
 *                                         �E�擾���z�A�������p�݌v�z�̎擾�������C��
 *                                         �E�x�����������z�A�����x�����[�X���i�T���z�j�̎擾�����C��
 *                                         �E���[�X�_����擾�J�[�\�������[�X��ނŕ���
 *  2009/08/28    1.5   SCS �n��         [�����e�X�g��Q0001063(PT�Ή�)]
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
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF012A18C'; -- �p�b�P�[�W��
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- �A�v���P�[�V�����Z�k��
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W
  cv_msg_close        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00038'; -- ��v���ԉ��N���[�Y�`�F�b�N�G���[
  cv_msg_ins_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102'; -- �o�^�G���[
  cv_msg_del_err      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; -- �폜�G���[
  cv_msg_no_lines     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00010'; -- ����0���p���b�Z�[�W
  cv_msg_lock_err     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  -- �g�[�N����
  cv_tkn_book_type    CONSTANT VARCHAR2(50)  := 'BOOK_TYPE_CODE';   -- ���Y�䒠��
  cv_tkn_period_name  CONSTANT VARCHAR2(50)  := 'PERIOD_NAME';      -- ��v���Ԗ�
  cv_tkn_column_name  CONSTANT VARCHAR2(20)  := 'COLUMN_NAME';      -- �J������
  cv_tkn_table_name   CONSTANT VARCHAR2(20)  := 'TABLE_NAME';       -- �e�[�u����
  cv_tkn_err_info     CONSTANT VARCHAR2(20)  := 'INFO';             -- �G���[���
  -- �g�[�N���l
  cv_tkv_wk_tab_name  CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50153'; -- ���[�X���c�����|�[�g���[���[�N�e�[�u��
  -- ���[�X���
  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Fin���[�X
  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Op���[�X
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- ��Fin���[�X
  -- ���[�X�敪
  cv_lease_type1      CONSTANT VARCHAR2(1)   := '1';  -- ���_��
  -- �_��X�e�[�^�X
  cv_contr_st_201     CONSTANT VARCHAR2(3)   := '201'; -- �o�^�ς�
-- 0000417 2009/07/31 ADD START --
  -- �����p�X�e�[�^�X
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --������
  -- ��vIF�t���O�X�e�[�^�X
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --�A�g��
-- 0000417 2009/07/31 ADD END --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_wk_ttype IS TABLE OF xxcff_rep_bal_in_obg_wk%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_bal_in_obg_wk
   * Description      : �f�[�^�폜����(A-9)
   ***********************************************************************************/
  PROCEDURE del_bal_in_obg_wk(
    ov_errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_bal_in_obg_wk'; -- �v���O������
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
    CURSOR bal_in_obg_wk_cur
    IS
      SELECT request_id
        FROM xxcff_rep_bal_in_obg_wk
       WHERE request_id = cn_request_id
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE l_request_id_ttype IS TABLE OF xxcff_rep_bal_in_obg_wk.request_id%TYPE INDEX BY BINARY_INTEGER;
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
      OPEN bal_in_obg_wk_cur;
      FETCH bal_in_obg_wk_cur BULK COLLECT INTO l_request_id_tab;
      CLOSE bal_in_obg_wk_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF (bal_in_obg_wk_cur%ISOPEN) THEN
          CLOSE bal_in_obg_wk_cur;
        END IF;
        lv_errbuf := SQLERRM;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name, cv_msg_lock_err
                       ,cv_tkn_table_name, cv_tkv_wk_tab_name);
        RAISE global_process_expt;
    END;
    -- ���[�N�f�[�^�폜
    DELETE FROM xxcff_rep_bal_in_obg_wk
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
  END del_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : submit_svf_request
   * Description      : SVF�N������(A-8)
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
    cv_rep_id    CONSTANT VARCHAR2(20) := 'XXCFF012A18';  -- ���[ID
    cv_svf_fname CONSTANT VARCHAR2(20) := 'XXCFF012A18S'; -- SVF�t�@�C����
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
   * Procedure Name   : ins_bal_in_obg_wk
   * Description      : ���[�X���c�����[�N�f�[�^�쐬����(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bal_in_obg_wk(
    i_wk_tab          IN  g_wk_ttype,    -- 1.���[�X���c�����|�[�g���[�N�f�[�^
    ov_errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bal_in_obg_wk'; -- �v���O������
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
    -- �Ώی����C���N�������g
    gn_target_cnt := gn_target_cnt + NVL(i_wk_tab.count,0);
--
    FORALL i IN 1..NVL(i_wk_tab.LAST,0) SAVE EXCEPTIONS
      INSERT INTO xxcff_rep_bal_in_obg_wk VALUES i_wk_tab(i);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : edit_bal_in_obg_wk
   * Description      : ���[�X���c�����[�N�f�[�^�ҏW���� (A-6)
   ***********************************************************************************/
  PROCEDURE edit_bal_in_obg_wk(
    iv_period_from    IN     VARCHAR2,     -- 1.�o�͊��ԁi���j
    iv_period_to      IN     VARCHAR2,     -- 2.�o�͊��ԁi���j
    io_wk_tab         IN OUT g_wk_ttype,   -- 3.���[�X���c�����|�[�g���[�N�f�[�^
    ov_errbuf         OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_bal_in_obg_wk'; -- �v���O������
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
    -- �o�͊��Ԃ̐ݒ�
    io_wk_tab(1).period_from           := REPLACE(iv_period_from,'-','/'); -- �o�͊��ԁi���j
    io_wk_tab(1).period_to             := REPLACE(iv_period_to,'-','/');   -- �o�͊��ԁi���j
    -- Op���[�X�̌Œ�o�͍���
    io_wk_tab(1).o_deprn_amount        := 0;              -- �������p�z�����z
    io_wk_tab(1).o_interest_amount     := 0;              -- �x�����������z
    -- WHO�J�����̐ݒ�
    io_wk_tab(1).created_by            := cn_created_by;
    io_wk_tab(1).creation_date         := cd_creation_date;
    io_wk_tab(1).last_updated_by       := cn_last_updated_by;
    io_wk_tab(1).last_update_date      := cd_last_update_date;
    io_wk_tab(1).last_update_login     := cn_last_update_login;
    io_wk_tab(1).request_id            := cn_request_id;
    io_wk_tab(1).program_application_id:= cn_program_application_id;
    io_wk_tab(1).program_id            := cn_program_id;
    io_wk_tab(1).program_update_date   := cd_program_update_date;
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
  END edit_bal_in_obg_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_planning
   * Description      : ���[�X�x���v����擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_pay_planning(
    id_start_date_1st IN     DATE,         -- 1.����J�n��
    id_start_date_now IN     DATE,         -- 2.�����J�n��
    io_wk_tab         IN OUT g_wk_ttype,   -- 3.���[�X���c�����|�[�g���[�N�f�[�^
    ov_errbuf         OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_planning'; -- �v���O������
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
    CURSOR planning_cur
    IS
      SELECT 
-- 0001063 2009/08/28 ADD START --
           /*+
             LEADING(XCH XCL)
             INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
             INDEX(XCL XXCFF_CONTRACT_LINES_U01)
           */
-- 0001063 2009/08/28 ADD END --
           xcl.lease_kind
-- 0000417 2009/07/17 ADD START --
          ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/17 ADD END --
-- 0000417 2009/07/17 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                 (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/17 MOD END --
                    (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                       xpp.lease_charge
                     ELSE 0 END)
-- 0000417 2009/07/17 ADD START --
                  ELSE 0 END)
-- 0000417 2009/07/17 ADD END --
               ELSE 0 END) AS lease_charge_this_month   -- �����x�����[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_future       -- ���o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_charge
                    ELSE 0 END)
                 ELSE 0 END) AS lease_charge_1year        -- 1�N�ȓ����o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_over_1year   -- 1�N�z���o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS lease_charge_debt         -- ���o�߃��[�X�����c�������z
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_future           -- ���o�߃��[�X�x�������z
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- ���o�߃��[�X����Ŋz
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1�N��2�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1�N��2�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1�N��2�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2�N��3�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2�N��3�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2�N��3�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3�N��4�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3�N��4�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3�N��4�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4�N��5�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4�N��5�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4�N��5�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_5year      -- 5�N�z���{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_over_5year       -- 5�N�z�x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_5year            -- 5�N�z�����
-- 0000417 2009/07/31 ADD START --
            ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                      (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                         xpp.fin_interest_due
                       ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                    ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                 ELSE 0 END) AS interest_amount           -- �x�����������z
-- 0000417 2009/07/31 ADD START --
            ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                      (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                         xpp.lease_deduction
                       ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                    ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                 ELSE 0 END) AS deduction_this_month      -- �����x�����[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_future          -- ���o�߃��[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS deduction_1year           -- 1�N�ȓ����o�߃��[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_over_1year      -- 1�N�z���o�߃��[�X���i�T���z�j
        FROM xxcff_contract_headers xch
            ,xxcff_contract_lines xcl
            ,xxcff_pay_planning xpp
       WHERE xch.contract_header_id = xcl.contract_header_id
         AND xpp.contract_line_id = xcl.contract_line_id
         AND xch.lease_type = cv_lease_type1
         AND EXISTS (
               SELECT 'x' FROM xxcff_pay_planning xpp2
                WHERE xpp2.contract_line_id = xcl.contract_line_id
                  AND xpp2.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM'))
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
                  xcl.cancellation_date IS NOT NULL)
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xcl.lease_kind
      ;
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
    <<planning_loop>>
    FOR l_rec IN planning_cur LOOP
      IF (l_rec.lease_kind = cv_lease_kind_fin) THEN
        io_wk_tab(1).f_lease_charge_this_month := l_rec.lease_charge_this_month; -- �����x�����[�X��
        io_wk_tab(1).f_lease_charge_future     := l_rec.lease_charge_future;     -- ���o�߃��[�X��
        io_wk_tab(1).f_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1�N�ȓ����o�߃��[�X��
        io_wk_tab(1).f_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1�N�z���o�߃��[�X��
        io_wk_tab(1).f_lease_charge_debt       := l_rec.lease_charge_debt;       -- ���o�߃��[�X�����c�������z
        io_wk_tab(1).f_interest_future         := l_rec.interest_future;         -- ���o�߃��[�X�x�������z
        io_wk_tab(1).f_tax_future              := l_rec.tax_future;              -- ���o�߃��[�X����Ŋz
        io_wk_tab(1).f_principal_1year         := l_rec.principal_1year;         -- 1�N�ȓ����{
        io_wk_tab(1).f_interest_1year          := l_rec.interest_1year;          -- 1�N�ȓ��x������
        io_wk_tab(1).f_tax_1year               := l_rec.tax_1year;               -- 1�N�ȓ������
        io_wk_tab(1).f_principal_1to2year      := l_rec.principal_1to2year;      -- 1�N�z2�N�ȓ����{
        io_wk_tab(1).f_interest_1to2year       := l_rec.interest_1to2year;       -- 1�N�z2�N�ȓ��x������
        io_wk_tab(1).f_tax_1to2year            := l_rec.tax_1to2year;            -- 1�N�z2�N�ȓ������
        io_wk_tab(1).f_principal_2to3year      := l_rec.principal_2to3year;      -- 2�N��3�N�ȓ����{
        io_wk_tab(1).f_interest_2to3year       := l_rec.interest_2to3year;       -- 2�N��3�N�ȓ��x������
        io_wk_tab(1).f_tax_2to3year            := l_rec.tax_2to3year;            -- 2�N��3�N�ȓ������
        io_wk_tab(1).f_principal_3to4year      := l_rec.principal_3to4year;      -- 3�N�z4�N�ȓ����{
        io_wk_tab(1).f_interest_3to4year       := l_rec.interest_3to4year;       -- 3�N�z4�N�ȓ��x������
        io_wk_tab(1).f_tax_3to4year            := l_rec.tax_3to4year;            -- 3�N�z4�N�ȓ������
        io_wk_tab(1).f_principal_4to5year      := l_rec.principal_4to5year;      -- 4�N�z5�N�ȓ����{
        io_wk_tab(1).f_interest_4to5year       := l_rec.interest_4to5year;       -- 4�N�z5�N�ȓ��x������
        io_wk_tab(1).f_tax_4to5year            := l_rec.tax_4to5year;            -- 4�N�z5�N�ȓ������
        io_wk_tab(1).f_principal_over_5year    := l_rec.principal_over_5year;    -- 5�N�z���{
        io_wk_tab(1).f_interest_over_5year     := l_rec.interest_over_5year;     -- 5�N�z�x������
        io_wk_tab(1).f_tax_over_5year          := l_rec.tax_over_5year;          -- 5�N�z�����
        io_wk_tab(1).f_interest_amount         := l_rec.interest_amount;         -- �x�����������z
        io_wk_tab(1).f_deduction_this_month    := l_rec.deduction_this_month;    -- �����x�����[�X���i�T���z�j
        io_wk_tab(1).f_deduction_future        := l_rec.deduction_future;        -- ���o�߃��[�X���i�T���z�j
        io_wk_tab(1).f_deduction_1year         := l_rec.deduction_1year;         -- 1�N�ȓ����o�߃��[�X���i�T���z�j
        io_wk_tab(1).f_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1�N�z���o�߃��[�X���i�T���z�j
--
      ELSIF (l_rec.lease_kind = cv_lease_kind_qfin) THEN
        io_wk_tab(1).q_lease_charge_this_month := l_rec.lease_charge_this_month; -- �����x�����[�X��
        io_wk_tab(1).q_lease_charge_future     := l_rec.lease_charge_future;     -- ���o�߃��[�X��
        io_wk_tab(1).q_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1�N�ȓ����o�߃��[�X��
        io_wk_tab(1).q_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1�N�z���o�߃��[�X��
        io_wk_tab(1).q_lease_charge_debt       := l_rec.lease_charge_debt;       -- ���o�߃��[�X�����c�������z
        io_wk_tab(1).q_interest_future         := l_rec.interest_future;         -- ���o�߃��[�X�x�������z
        io_wk_tab(1).q_tax_future              := l_rec.tax_future;              -- ���o�߃��[�X����Ŋz
        io_wk_tab(1).q_principal_1year         := l_rec.principal_1year;         -- 1�N�ȓ����{
        io_wk_tab(1).q_interest_1year          := l_rec.interest_1year;          -- 1�N�ȓ��x������
        io_wk_tab(1).q_tax_1year               := l_rec.tax_1year;               -- 1�N�ȓ������
        io_wk_tab(1).q_principal_1to2year      := l_rec.principal_1to2year;      -- 1�N�z2�N�ȓ����{
        io_wk_tab(1).q_interest_1to2year       := l_rec.interest_1to2year;       -- 1�N�z2�N�ȓ��x������
        io_wk_tab(1).q_tax_1to2year            := l_rec.tax_1to2year;            -- 1�N�z2�N�ȓ������
        io_wk_tab(1).q_principal_2to3year      := l_rec.principal_2to3year;      -- 2�N��3�N�ȓ����{
        io_wk_tab(1).q_interest_2to3year       := l_rec.interest_2to3year;       -- 2�N��3�N�ȓ��x������
        io_wk_tab(1).q_tax_2to3year            := l_rec.tax_2to3year;            -- 2�N��3�N�ȓ������
        io_wk_tab(1).q_principal_3to4year      := l_rec.principal_3to4year;      -- 3�N�z4�N�ȓ����{
        io_wk_tab(1).q_interest_3to4year       := l_rec.interest_3to4year;       -- 3�N�z4�N�ȓ��x������
        io_wk_tab(1).q_tax_3to4year            := l_rec.tax_3to4year;            -- 3�N�z4�N�ȓ������
        io_wk_tab(1).q_principal_4to5year      := l_rec.principal_4to5year;      -- 4�N�z5�N�ȓ����{
        io_wk_tab(1).q_interest_4to5year       := l_rec.interest_4to5year;       -- 4�N�z5�N�ȓ��x������
        io_wk_tab(1).q_tax_4to5year            := l_rec.tax_4to5year;            -- 4�N�z5�N�ȓ������
        io_wk_tab(1).q_principal_over_5year    := l_rec.principal_over_5year;    -- 5�N�z���{
        io_wk_tab(1).q_interest_over_5year     := l_rec.interest_over_5year;     -- 5�N�z�x������
        io_wk_tab(1).q_tax_over_5year          := l_rec.tax_over_5year;          -- 5�N�z�����
        io_wk_tab(1).q_interest_amount         := l_rec.interest_amount;         -- �x�����������z
        io_wk_tab(1).q_deduction_this_month    := l_rec.deduction_this_month;    -- �����x�����[�X���i�T���z�j
        io_wk_tab(1).q_deduction_future        := l_rec.deduction_future;        -- ���o�߃��[�X���i�T���z�j
        io_wk_tab(1).q_deduction_1year         := l_rec.deduction_1year;         -- 1�N�ȓ����o�߃��[�X���i�T���z�j
        io_wk_tab(1).q_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1�N�z���o�߃��[�X���i�T���z�j
--
      ELSIF (l_rec.lease_kind = cv_lease_kind_op) THEN
        io_wk_tab(1).o_lease_charge_this_month := l_rec.lease_charge_this_month; -- �����x�����[�X��
        io_wk_tab(1).o_lease_charge_future     := l_rec.lease_charge_future;     -- ���o�߃��[�X��
        io_wk_tab(1).o_lease_charge_1year      := l_rec.lease_charge_1year;      -- 1�N�ȓ����o�߃��[�X��
        io_wk_tab(1).o_lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1�N�z���o�߃��[�X��
        io_wk_tab(1).o_deduction_this_month    := l_rec.deduction_this_month;    -- �����x�����[�X���i�T���z�j
        io_wk_tab(1).o_deduction_future        := l_rec.deduction_future;        -- ���o�߃��[�X���i�T���z�j
        io_wk_tab(1).o_deduction_1year         := l_rec.deduction_1year;         -- 1�N�ȓ����o�߃��[�X���i�T���z�j
        io_wk_tab(1).o_deduction_over_1year    := l_rec.deduction_over_1year;    -- 1�N�z���o�߃��[�X���i�T���z�j
      END IF;
    END LOOP planning_loop;
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
  END get_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : ���[�X�_����擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    id_start_date_1st  IN     DATE,       --  1.����J�n��
    id_start_date_now  IN     DATE,       --  2.�����J�n��
    in_fiscal_year     IN     NUMBER,     --  3.��v�N�x
    in_period_num_1st  IN     NUMBER,     --  4.������Ԕԍ�
    in_period_num_now  IN     NUMBER,     --  5.�������Ԕԍ�
    iv_period_from     IN     VARCHAR2,   --  6.�o�͊��ԁi���j
    iv_period_to       IN     VARCHAR2,   --  7.�o�͊��ԁi���j
    io_wk_tab          IN OUT g_wk_ttype, --  8.���[�X���c�����|�[�g���[�N�f�[�^
    ov_errbuf          OUT    VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT    VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT    VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- �v���O������
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
-- 0000417 2009/08/06 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xcl.lease_kind                     -- ���[�X���
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- �擾���z���z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN fdp.period_name = iv_period_to THEN
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
            ,SUM(NVL(fds.deprn_amount,0)) AS deprn_amount -- �������p�����z
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
       INNER JOIN xxcff_lease_kind_v xlk      -- ���[�X��ރr���[
          ON xcl.lease_kind = xlk.lease_kind_code
       LEFT JOIN fa_additions_b fab           -- ���Y�ڍ׏��
          ON fab.attribute10 = xcl.contract_line_id
-- 0000417 2009/07/31 ADD START --
       LEFT JOIN fa_retirements fret  -- �����p
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = xlk.book_type_code
         AND fret.transaction_header_id_out IS NULL
-- 0000417 2009/07/31 ADD END --
       LEFT JOIN fa_deprn_periods fdp         -- �������p����
          ON fdp.book_type_code = xlk.book_type_code
       LEFT JOIN fa_deprn_summary fds         -- �������p�T�}��
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
      GROUP BY xcl.lease_kind
      ;
*/
-- 0000417 2009/08/06 DEL END --
--
-- 0000417 2009/08/06 ADD START --
    --FIN�A��FIN���[�X�擾�ΏۃJ�[�\��
    CURSOR contract_cur
    IS
      SELECT
-- 0001063 2009/08/28 ADD START --
            /*+
              LEADING(XCH XCL XLK FAB FRET FDP FDS)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_N06)
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              NO_USE_MERGE(XCH XLK)
              USE_NL(XCL FAB)
            */
-- 0001063 2009/08/28 ADD START --
             xcl.lease_kind                     -- ���[�X���

            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- �擾���z���z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      NVL(fds.deprn_reserve,original_cost)
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
            ,SUM(NVL(fds.deprn_amount,0)) AS deprn_amount -- �������p�����z

            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN fdp.period_name = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
         AND xcl.lease_kind IN (cv_lease_kind_fin,cv_lease_kind_qfin)
       INNER JOIN xxcff_lease_kind_v xlk      -- ���[�X��ރr���[
          ON xcl.lease_kind = xlk.lease_kind_code
       INNER JOIN fa_additions_b fab           -- ���Y�ڍ׏��
-- 0001063 2009/08/28 MOD START --
--          ON fab.attribute10 = xcl.contract_line_id
          ON fab.attribute10 = to_char(xcl.contract_line_id)
-- 0001063 2009/08/28 MOD END --
       LEFT JOIN fa_retirements fret  -- �����p
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = xlk.book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- �������p����
          ON fdp.book_type_code = xlk.book_type_code
-- 0001063 2009/08/28 ADD START --
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
-- 0001063 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- �������p�T�}��
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
         AND xcl.contract_status > cv_contr_st_201
-- 0001063 2009/08/28 DEL START --
--         AND fdp.fiscal_year = in_fiscal_year
--         AND fdp.period_num >= in_period_num_1st
--         AND fdp.period_num <= in_period_num_now
-- 0001063 2009/08/28 DEL END --
      GROUP BY xcl.lease_kind
      ;
--
    --OP���[�X�擾�ΏۃJ�[�\��
    CURSOR contract_op_cur
    IS
      SELECT xcl.lease_kind                     -- ���[�X���
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
            ,NULL AS original_cost   -- �擾���z���z
            ,NULL AS deprn_reserve   -- �������p�݌v�z�����z
            ,NULL AS deprn_amount    -- �������p�����z
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
         AND xcl.lease_kind = cv_lease_kind_op
       INNER JOIN xxcff_lease_kind_v xlk      -- ���[�X��ރr���[
          ON xcl.lease_kind = xlk.lease_kind_code
       WHERE xch.lease_type = cv_lease_type1
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xcl.lease_kind
      ;
-- 0000417 2009/08/06 ADD END --
    contract_rec contract_cur%ROWTYPE;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    -- FIN�A��FIN���[�X�Ώ�
    <<contract_loop>>
    FOR l_rec in contract_cur LOOP
      -- �擾�l���i�[
      IF    (l_rec.lease_kind = cv_lease_kind_fin) THEN
        io_wk_tab(1).f_monthly_charge      := l_rec.monthly_charge;     -- ���ԃ��[�X��
        io_wk_tab(1).f_gross_charge        := l_rec.gross_charge;       -- ���[�X�����z
        io_wk_tab(1).f_original_cost       := l_rec.original_cost;      -- �擾���z���z
        io_wk_tab(1).f_deprn_reserve       := l_rec.deprn_reserve;      -- �������p�݌v�z�����z
        io_wk_tab(1).f_deprn_amount        := l_rec.deprn_amount;       -- �������p�����z
        io_wk_tab(1).f_monthly_deduction   := l_rec.monthly_deduction;  -- ���ԃ��[�X���i�T���z�j
        io_wk_tab(1).f_gross_deduction     := l_rec.gross_deduction;    -- ���[�X�����z�i�T���z�j
        io_wk_tab(1).f_bal_amount          := l_rec.original_cost - l_rec.deprn_reserve; -- �����c�������z
      ELSIF (l_rec.lease_kind = cv_lease_kind_qfin) THEN
        io_wk_tab(1).q_monthly_charge      := l_rec.monthly_charge;     -- ���ԃ��[�X��
        io_wk_tab(1).q_gross_charge        := l_rec.gross_charge;       -- ���[�X�����z
        io_wk_tab(1).q_original_cost       := l_rec.original_cost;      -- �擾���z���z
        io_wk_tab(1).q_deprn_reserve       := l_rec.deprn_reserve;      -- �������p�݌v�z�����z
        io_wk_tab(1).q_deprn_amount        := l_rec.deprn_amount;       -- �������p�����z
        io_wk_tab(1).q_monthly_deduction   := l_rec.monthly_deduction;  -- ���ԃ��[�X���i�T���z�j
        io_wk_tab(1).q_gross_deduction     := l_rec.gross_deduction;    -- ���[�X�����z�i�T���z�j
        io_wk_tab(1).q_bal_amount          := l_rec.original_cost - l_rec.deprn_reserve; -- �����c�������z
-- 0000417 2009/08/05 DEL START --
--      ELSIF (l_rec.lease_kind = cv_lease_kind_op) THEN
--        io_wk_tab(1).o_monthly_charge      := l_rec.monthly_charge;     -- ���ԃ��[�X��
--        io_wk_tab(1).o_gross_charge        := l_rec.gross_charge;       -- ���[�X�����z
--        io_wk_tab(1).o_monthly_deduction   := l_rec.monthly_deduction;  -- ���ԃ��[�X���i�T���z�j
--        io_wk_tab(1).o_gross_deduction     := l_rec.gross_deduction;    -- ���[�X�����z�i�T���z�j
-- 0000417 2009/08/05 DEL END --
      END IF;
    END LOOP contract_loop;
--
-- 0000417 2009/08/06 START END --
    -- OP���[�X�Ώ�
    <<contract_loop2>>
    FOR l_rec in contract_op_cur LOOP
      -- �擾�l���i�[
      io_wk_tab(1).o_monthly_charge      := l_rec.monthly_charge;     -- ���ԃ��[�X��
      io_wk_tab(1).o_gross_charge        := l_rec.gross_charge;       -- ���[�X�����z
      io_wk_tab(1).o_monthly_deduction   := l_rec.monthly_deduction;  -- ���ԃ��[�X���i�T���z�j
      io_wk_tab(1).o_gross_deduction     := l_rec.gross_deduction;    -- ���[�X�����z�i�T���z�j
    END LOOP contract_loop2;
-- 0000417 2009/08/06 END END --
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
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : get_first_period
   * Description      : ��v���Ԋ���擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_first_period(
    in_fiscal_year    IN  NUMBER,       -- 1.��v�N�x
    ov_period_from    OUT VARCHAR2,     -- 2.�o�͊��ԁi���j
    on_period_num_1st OUT NUMBER,       -- 3.���Ԕԍ�
    od_start_date_1st OUT DATE,         -- 4.����J�n��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_first_period'; -- �v���O������
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
    cn_period_num_1st CONSTANT NUMBER(1) := 1;  -- ������Ԕԍ�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_1st_cur
    IS
      SELECT fcp.period_name AS period_from    -- �o�͊��ԁi���j
            ,fcp.period_num  AS period_num     -- ���Ԕԍ�
            ,fcp.start_date  AS start_date_1st -- ����J�n��
        FROM fa_calendar_periods fcp  -- ���Y�J�����_
            ,fa_calendar_types fct    -- ���Y�J�����_�^�C�v
            ,fa_fiscal_year ffy       -- ���Y��v�N�x
            ,fa_book_controls fbc     -- ���Y�䒠�}�X�^
            ,xxcff_lease_kind_v xlk   -- ���[�X��ރr���[
       WHERE fbc.book_type_code = xlk.book_type_code
         AND xlk.lease_kind_code = cv_lease_kind_fin
         AND fbc.deprn_calendar = fcp.calendar_type
         AND ffy.fiscal_year = in_fiscal_year
         AND ffy.fiscal_year_name = fct.fiscal_year_name
         AND fct.calendar_type = fcp.calendar_type
         AND fcp.start_date >= ffy.start_date
         AND fcp.end_date <= ffy.end_date
         AND fcp.period_num = cn_period_num_1st;
    period_1st_rec period_1st_cur%ROWTYPE;
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
    OPEN period_1st_cur;
    FETCH period_1st_cur INTO period_1st_rec;
    CLOSE period_1st_cur;
    -- �߂�l�ݒ�
    ov_period_from    := period_1st_rec.period_from;     -- �o�͊��ԁi���j
    on_period_num_1st := period_1st_rec.period_num;      -- ���Ԕԍ�
    od_start_date_1st := period_1st_rec.start_date_1st;  -- ����J�n��
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
  END get_first_period;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_name
   * Description      : ��v���ԃ`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.��v���Ԗ�
    on_fiscal_year    OUT NUMBER,       -- 2.��v�N�x
    ov_period_to      OUT VARCHAR2,     -- 3.�o�͊��ԁi���j
    on_period_num_now OUT NUMBER,       -- 4.���Ԕԍ�
    od_start_date_now OUT DATE,         -- 5.�����J�n��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- �v���O������
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
    CURSOR period_cur
    IS
      SELECT fdp.deprn_run   AS deprn_run      -- �������p���s�t���O
            ,fdp.fiscal_year AS fiscal_year    -- ��v����
            ,fdp.period_name AS period_to      -- �o�͊��ԁi���j
            ,fdp.period_num  AS period_num     -- ���Ԕԍ�
            ,fcp.start_date  AS start_date_now -- �����J�n��
            ,xlk.book_type_code AS book_type_code -- ���Y�䒠��
        FROM fa_deprn_periods fdp     -- �������p����
            ,fa_calendar_periods fcp  -- ���Y�J�����_
            ,fa_book_controls fbc     -- ���Y�䒠�}�X�^
            ,xxcff_lease_kind_v xlk   -- ���[�X��ރr���[
       WHERE fbc.book_type_code = xlk.book_type_code
         AND fdp.period_name = iv_period_name
         AND fdp.book_type_code = fbc.book_type_code
         AND fbc.deprn_calendar = fcp.calendar_type
         AND fdp.period_name = fcp.period_name;
    period_rec period_cur%ROWTYPE;
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
    -- �������p���ԏ��擾
    OPEN period_cur;
    <<period_loop>>
    LOOP
      FETCH period_cur INTO period_rec;
      EXIT WHEN period_cur%NOTFOUND;
      IF (NVL(period_rec.deprn_run,'N') != 'Y') THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name,cv_msg_close
                       ,cv_tkn_book_type,period_rec.book_type_code
                       ,cv_tkn_period_name,iv_period_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP period_loop;
    CLOSE period_cur;
--
    -- �߂�l�ݒ�
    on_fiscal_year    := period_rec.fiscal_year;      -- ��v�N�x
    ov_period_to      := period_rec.period_to;        -- �o�͊��ԁi���j
    on_period_num_now := period_rec.period_num;       -- ���Ԕԍ�
    od_start_date_now := period_rec.start_date_now;   -- �����J�n��
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** ���ʏ�����O ***
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
  END chk_period_name;
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
    iv_period_name       IN  VARCHAR2,     -- 1.��v���Ԗ�
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
    lt_fiscal_year    fa_deprn_periods.fiscal_year%TYPE;     -- ��v�N�x
    lt_period_from    fa_deprn_periods.period_name%TYPE;     -- �o�͊��ԁi���j
    lt_period_to      fa_deprn_periods.period_name%TYPE;     -- �o�͊��ԁi���j
    lt_period_num_1st fa_deprn_periods.period_num%TYPE;      -- ������Ԕԍ�
    lt_period_num_now fa_deprn_periods.period_num%TYPE;      -- �������Ԕԍ�
    ld_start_date_1st DATE;                                  -- ����J�n��
    ld_start_date_now DATE;                                  -- �����J�n��
    l_wk_tab          g_wk_ttype;
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
    -- A-2�D��v���ԃ`�F�b�N����
    -- ============================================
    chk_period_name(
       iv_period_name     -- 1.��v���Ԗ�
      ,lt_fiscal_year     -- 2.��v�N�x
      ,lt_period_to       -- 3.�o�͊��ԁi���j
      ,lt_period_num_now  -- 4.���Ԕԍ�
      ,ld_start_date_now  -- 5.�����J�n��
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D��v���Ԋ���擾����
    -- ============================================
    get_first_period(
       lt_fiscal_year     -- 1.��v�N�x
      ,lt_period_from     -- 2.�o�͊��ԁi���j
      ,lt_period_num_1st  -- 3.���Ԕԍ�
      ,ld_start_date_1st  -- 4.�����J�n��
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D���[�X�_����擾����
    -- ============================================
    get_contract_info(
       ld_start_date_1st  --  1.����J�n��
      ,ld_start_date_now  --  2.�����J�n��
      ,lt_fiscal_year     --  3.��v�N�x
      ,lt_period_num_1st  --  4.������Ԕԍ�
      ,lt_period_num_now  --  5.�������Ԕԍ�
      ,lt_period_from     --  6.�o�͊��ԁi���j
      ,lt_period_to       --  7.�o�͊��ԁi���j
      ,l_wk_tab           --  8.���[�X���c�����|�[�g���[�N�f�[�^
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    IF (NVL(l_wk_tab.COUNT,0) > 0) THEN
      -- ============================================
      -- A-5�D���[�X�x���v����擾����
      -- ============================================
      get_pay_planning(
         ld_start_date_1st  --  1.����J�n��
        ,ld_start_date_now  --  2.�����J�n��
        ,l_wk_tab           --  3.���[�X���c�����|�[�g���[�N�f�[�^
        ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
  --
      -- ============================================
      -- A-6�D���[�X���c�����|�[�g���[�N�f�[�^�ҏW����
      -- ============================================
      edit_bal_in_obg_wk(
         lt_period_from     -- 1.�o�͊��ԁi���j
        ,lt_period_to       -- 2.�o�͊��ԁi���j
        ,l_wk_tab           -- 3.���[�X���c�����|�[�g���[�N�f�[�^
        ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode != cv_status_normal) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
  --
      -- ============================================
      -- A-7�D���[�X���c�����|�[�g���[�N�f�[�^�쐬����
      -- ============================================
      ins_bal_in_obg_wk(
         l_wk_tab           -- 1.���[�X���c�����|�[�g���[�N�f�[�^
        ,lv_errbuf          --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode         --   ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    END IF;
--
    -- ============================================
    -- A-8�DSVF�N������
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
    -- A-9�D�f�[�^�폜����
    -- ============================================
    del_bal_in_obg_wk(
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
    iv_period_name       IN  VARCHAR2       -- 1.��v���Ԗ�
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
       iv_which    => cv_which     -- �o�͋敪
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
       iv_period_name  -- 1.��v���Ԗ�
      ,lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ============================================
    -- A-10�D�I������
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
--       which  => FND_FILE.OUTPUT
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
END XXCFF012A18C;
/
