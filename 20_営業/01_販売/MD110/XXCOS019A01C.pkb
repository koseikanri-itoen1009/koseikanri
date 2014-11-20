CREATE OR REPLACE PACKAGE BODY APPS.XXCOS019A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS019A01C (body)
 * Description      : �d���^�X�N���̍폜���s��
 * MD.050           : �d���^�X�N�폜���� (MD050_COS_019_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_dup_task           �d���^�X�N��������(A-2)
 *  del_dup_task           �d���^�X�N�폜����(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/07    1.0   K.NARAHARA       �V�K�쐬
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_period_err_expt   EXCEPTION;   -- ��v���Ԏ擾�G���[��O�n���h��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOS019A01C';      -- �p�b�P�[�W��
--
  cv_application             CONSTANT VARCHAR2(5)   := 'XXCOS';             -- �A�v���P�[�V������
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_period              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00026';  -- ��v���Ԏ擾�G���[
  cv_msg_nodata              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�����G���[
  cv_msg_del                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14201';  -- �폜���b�Z�[�W
  cv_msg_count               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14202';  -- �������b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_acct_name           CONSTANT VARCHAR2(20)  := 'ACCOUNT_NAME';      -- ��v���ԋ敪�l
  cv_tkn_cust_code           CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';     -- �ڋq�R�[�h
  cv_tkn_cust_name           CONSTANT VARCHAR2(20)  := 'CUSTOMER_NAME';     -- �ڋq��
  cv_tkn_actual_date         CONSTANT VARCHAR2(20)  := 'ACTUAL_DATE';       -- ���ѓ�
  cv_tkn_visit_kbn           CONSTANT VARCHAR2(20)  := 'VISIT_KBN';         -- �L���K��敪
  cv_tkn_count1              CONSTANT VARCHAR2(20)  := 'COUNT1';            -- �Ώی���
  cv_tkn_count2              CONSTANT VARCHAR2(20)  := 'COUNT2';            -- �폜����
  cv_tkn_count3              CONSTANT VARCHAR2(20)  := 'COUNT3';            -- �G���[����
--
  -- ���̑��萔
  cv_ar_class                CONSTANT VARCHAR2(20)  := '02';                -- 02:AR��v���ԋ敪�l
  cv_ar                      CONSTANT VARCHAR2(20)  := 'AR';                -- ��v���ԋ敪�l�FAR
  cv_entry_type3             CONSTANT VARCHAR2(20)  := '3';                 -- �o�^�敪�F3�i�[�i���j
  cv_entry_type4             CONSTANT VARCHAR2(20)  := '4';                 -- �o�^�敪�F4�i�W�����j
  cv_entry_type5             CONSTANT VARCHAR2(20)  := '5';                 -- �o�^�敪�F5�i����VD���j
  cv_n                       CONSTANT VARCHAR2(20)  := 'N';                 -- �t���O�FN
  cv_party                   CONSTANT VARCHAR2(20)  := 'PARTY';             -- �\�[�X�I�u�W�F�N�g�R�[�h�FPARTY
  cv_rs_employee             CONSTANT VARCHAR2(20)  := 'RS_EMPLOYEE';       -- �^�X�N���L�҃^�C�v�R�[�h�FRS_EMPLOYEE
  cv_date_format             CONSTANT VARCHAR2(20)  := 'YYYY/MM/DD';        -- ���t����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �d���^�X�N�f�[�^�i�[�p���R�[�h
  TYPE g_rec_dup_task_data   IS RECORD
    (
      account_number         hz_cust_accounts.account_number%TYPE,          -- �ڋq�ԍ�
      party_name             hz_parties.party_name%TYPE,                    -- �ڋq��
      task_id                jtf_tasks_b.task_id%TYPE,                      -- �^�X�NID
      owner_id               jtf_tasks_b.owner_id%TYPE,                     -- �^�X�N���L��ID
      source_object_id       jtf_tasks_b.source_object_id%TYPE,             -- �\�[�X�I�u�W�F�N�gID
      actual_end_date        jtf_tasks_b.actual_end_date%TYPE,              -- ���ѓ�
      attribute11            jtf_tasks_b.attribute11%TYPE,                  -- �L���K��敪
      creation_date          jtf_tasks_b.creation_date%TYPE,                -- �쐬��
      object_version_number  jtf_tasks_b.object_version_number%TYPE         -- �I�u�W�F�N�g���@�[�W�����ԍ�
    );
--
  -- �d���^�X�N�f�[�^�i�[�p�e�[�u��
  TYPE g_tab_dup_task_data   IS TABLE OF g_rec_dup_task_data INDEX BY PLS_INTEGER;
--
  -- �폜���b�Z�[�W�i�[�p�e�[�u��
  TYPE g_tab_del_msg_data    IS TABLE OF VARCHAR(1000) INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_chk_start_date          DATE;                                          -- �`�F�b�N�J�n���t
  gt_dup_task_data           g_tab_dup_task_data;                           -- �d���^�X�N�f�[�^
  gt_del_msg_data            g_tab_del_msg_data;                            -- �폜���b�Z�[�W
  gn_dup_cnt                 NUMBER;                                        -- �d������
  gn_del_cnt                 NUMBER;                                        -- �폜����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
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
    lv_status        VARCHAR2(5);       -- ��v���ԏ��F�X�e�[�^�X
    ld_from_date     DATE;              -- ��v���ԏ��F�J�n�N����
    ld_to_date       DATE;              -- ��v���ԏ��F�I���N����
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
    -- ���ʊ֐�����v���ԏ��擾��
    xxcos_common_pkg.get_account_period(
      cv_ar_class         -- 02:AR��v���ԋ敪�l
     ,NULL                -- ���
     ,lv_status           -- �X�e�[�^�X
     ,ld_from_date        -- �J�n�N����
     ,ld_to_date          -- �I���N����
     ,lv_errbuf           -- �G���[�E���b�Z�[�W
     ,lv_retcode          -- ���^�[���E�R�[�h
     ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    -- �G���[�`�F�b�N
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_period_err_expt;
    END IF;
--
    -- �擾�����J�n�����`�F�b�N�J�n���t�ɐݒ�
    gd_chk_start_date := ld_from_date;  -- �`�F�b�N�J�n���t
--
  EXCEPTION
--
    -- ��v���Ԏ擾�G���[
    WHEN global_period_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_period,     -- ��v���Ԏ擾�G���[
                     iv_token_name1  => cv_tkn_acct_name,  -- �g�[�N���FACCOUNT_NAME
                     iv_token_value1 => cv_ar              -- ��v���ԋ敪�l�FAR
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;

--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_dup_task
   * Description      : �d���^�X�N��������(A-2)
   ***********************************************************************************/
  PROCEDURE get_dup_task(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dup_task'; -- �v���O������
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
    -- �d���^�X�N�����J�[�\��
    CURSOR get_dup_task_data_cur
    IS
    SELECT   /*+ USE_NL(task jtb_2 hca hp)*/
             hca.account_number            account_number,         -- �ڋq�ԍ�
             hp.party_name                 party_name,             -- �ڋq��
             jtb_2.task_id                 task_id,                -- �^�X�NID
             jtb_2.owner_id                owner_id,               -- �^�X�N���L��ID
             jtb_2.source_object_id        source_object_id,       -- �\�[�X�I�u�W�F�N�gID
             TRUNC(jtb_2.actual_end_date)  actual_end_date,        -- ���ѓ�
             jtb_2.attribute11             attribute11,            -- �L���K��敪
             jtb_2.creation_date           creation_date,          -- �쐬��
             jtb_2.object_version_number   object_version_number   -- �I�u�W�F�N�g���@�[�W�����ԍ�
    FROM     hz_cust_accounts              hca,
             hz_parties                    hp,
             jtf_tasks_b                   jtb_2,
             (
             SELECT   /*+ INDEX_DESC(jtb XXCSO_JTF_TASKS_B_N20) */
                      jtb.owner_id                 owner_id,            -- �^�X�N���L��ID
                      jtb.source_object_id         source_object_id,    -- �\�[�X�I�u�W�F�N�gID
                      TRUNC(jtb.actual_end_date)   actual_end_date,     -- ���ѓ�
                      COUNT(1)
             FROM     jtf.jtf_tasks_b              jtb
             WHERE    jtb.source_object_type_code  = cv_party           -- PARTY
             AND      jtb.attribute12              IN (cv_entry_type3,  -- �o�^�敪�F3�i�[�i���j
                                                       cv_entry_type4,  -- �o�^�敪�F4�i�W�����j
                                                       cv_entry_type5)  -- �o�^�敪�F5�i����VD���j
             AND      jtb.deleted_flag             = cv_n               -- N
             AND      jtb.owner_type_code          = cv_rs_employee     -- RS_EMPLOYEE
             AND      TRUNC(jtb.actual_end_date)  >= gd_chk_start_date  -- �`�F�b�N�J�n���t
             GROUP BY jtb.owner_id,                                     -- ���L��ID
                      jtb.source_object_id,                             -- �\�[�X�I�u�W�F�N�gID
                      TRUNC(jtb.actual_end_date)                        -- ���ѓ�
             HAVING   COUNT(1) > 1
             )                             task
    WHERE    hp.party_id                   = hca.party_id
    AND      hca.party_id                  = jtb_2.source_object_id
    AND      jtb_2.owner_id                = task.owner_id
    AND      jtb_2.source_object_id        = task.source_object_id
    AND      TRUNC(jtb_2.actual_end_date)  = task.actual_end_date
    AND      jtb_2.attribute12             IN (cv_entry_type3,  -- �o�^�敪�F3�i�[�i���j
                                               cv_entry_type4,  -- �o�^�敪�F4�i�W�����j
                                               cv_entry_type5)  -- �o�^�敪�F5�i����VD���j
    AND      jtb_2.deleted_flag            = cv_n               -- N
    ORDER BY jtb_2.owner_id,
             jtb_2.source_object_id,
             TRUNC(jtb_2.actual_end_date),
             jtb_2.attribute11 DESC,
             jtb_2.task_id;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �d���^�X�N�f�[�^�擾
    --==============================================================
    -- �J�[�\��OPEN
    OPEN  get_dup_task_data_cur;
    -- �o���N�t�F�b�`
    FETCH get_dup_task_data_cur BULK COLLECT INTO gt_dup_task_data;
    -- �d�������Z�b�g
    gn_dup_cnt := get_dup_task_data_cur%ROWCOUNT;
    -- �J�[�\��CLOSE
    CLOSE Get_Dup_Task_Data_Cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_dup_task;
--
  /***********************************************************************************
   * Procedure Name   : del_dup_task
   * Description      : �d���^�X�N�폜����(A-3)
   ***********************************************************************************/
  PROCEDURE del_dup_task(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_dup_task'; -- �v���O������
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
    -- *** ���[�J���^   ***
--
    -- *** ���[�J���E���R�[�h ***
    -- �폜�Ώۃ^�X�N�f�[�^�i�[�p���R�[�h
    TYPE l_rec_del_task_data IS RECORD(
      task_id                jtf_tasks_b.task_id%TYPE,                 -- �^�X�NID
      object_version_number  jtf_tasks_b.object_version_number%TYPE,   -- �I�u�W�F�N�g���@�[�W�����ԍ�
      account_number         hz_cust_accounts.account_number%TYPE,     -- �ڋq�R�[�h
      party_name             hz_parties.party_name%TYPE,               -- �ڋq��
      actual_end_date        jtf_tasks_b.actual_end_date%TYPE,         -- ���ѓ�
      attribute11            jtf_tasks_b.attribute11%TYPE              -- �L���K��敪
    );
--
    -- �폜�Ώۃ^�X�N�f�[�^�i�[�p�e�[�u��
    TYPE l_tab_del_task_data    IS TABLE OF l_rec_del_task_data INDEX BY PLS_INTEGER;
--
    -- *** ���[�J���ϐ� ***
    lt_owner_id              jtf_tasks_b.owner_id%TYPE;                -- ���L��id
    lt_source_object_id      jtf_tasks_b.source_object_id%TYPE;        -- �\�[�X�I�u�W�F�N�gid
    lt_actual_end_date       jtf_tasks_b.actual_end_date%TYPE;         -- ���ѓ�
    ln_cnt                   NUMBER;                                   -- �z��p�Y����
    lt_del_task_data         l_tab_del_task_data;                      -- �폜�Ώۃ^�X�N�f�[�^
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �ϐ�������
    lt_owner_id         := 0;
    lt_source_object_id := 0;
    lt_actual_end_date  := TO_DATE( '1900/01/01', cv_date_format);
    ln_cnt              := 0;
--
    -- �d�����������[�v
    FOR i IN 1..gn_dup_cnt LOOP
      -- �O���R�[�h�Ə��L��ID�A�\�[�X�I�u�W�F�N�gID�A���ѓ����������ꍇ�A�폜�ΏۂƂ���
      IF  ( ( lt_owner_id         = gt_dup_task_data(i).owner_id )
        AND ( lt_source_object_id = gt_dup_task_data(i).source_object_id )
        AND ( lt_actual_end_date  = gt_dup_task_data(i).actual_end_date ) ) THEN
--
        -- �폜�Ώۃ^�X�N�f�[�^���i�[
        ln_cnt := ln_cnt + 1;
        lt_del_task_data(ln_cnt).task_id               := gt_dup_task_data(i).task_id;                -- �^�X�NID
        lt_del_task_data(ln_cnt).object_version_number := gt_dup_task_data(i).object_version_number;  -- �I�u�W�F�N�g���@�[�W�����ԍ�
        lt_del_task_data(ln_cnt).account_number        := gt_dup_task_data(i).account_number;         -- �ڋq�R�[�h
        lt_del_task_data(ln_cnt).party_name            := gt_dup_task_data(i).party_name;             -- �ڋq��
        lt_del_task_data(ln_cnt).actual_end_date       := gt_dup_task_data(i).actual_end_date;        -- ���ѓ�
        lt_del_task_data(ln_cnt).attribute11           := gt_dup_task_data(i).attribute11;            -- �L���K��敪
--
      END IF;
--
      -- �����R�[�h�Ɣ�r���邽�ߌ��݂̃��R�[�h�����i�[
      lt_owner_id         := gt_dup_task_data(i).owner_id;            -- ���L��ID
      lt_source_object_id := gt_dup_task_data(i).source_object_id;    -- �\�[�X�I�u�W�F�N�gID
      lt_actual_end_date  := gt_dup_task_data(i).actual_end_date;     -- ���ѓ�
--
    END LOOP;
--
    -- �폜�Ώی����Z�b�g
    gn_target_cnt := ln_cnt;
--
    -- �폜�Ώی��������[�v
    FOR i IN 1..gn_target_cnt LOOP
      -- ���ʊ֐����^�X�N�폜��
      xxcso_task_common_pkg.delete_task(
         in_task_id     => lt_del_task_data(i).task_id                -- �^�X�NID
        ,in_obj_ver_num => lt_del_task_data(i).object_version_number  -- �I�u�W�F�N�g���@�[�W�����ԍ�
        ,ov_errbuf      => lv_errbuf                                  -- �G���[�o�b�t�@�[
        ,ov_retcode     => lv_retcode                                 -- �G���[�R�[�h
        ,ov_errmsg      => lv_errmsg                                  -- �G���[���b�Z�[�W
      );
      -- �G���[�`�F�b�N
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �폜�����J�E���g�A�b�v
      gn_del_cnt := gn_del_cnt + 1;
      -- �폜���b�Z�[�W�i�[
      gt_del_msg_data(i) := xxccp_common_pkg.get_msg(
                              iv_application => cv_application,
                              iv_name        => cv_msg_del,                                                   -- �폜���b�Z�[�W
                              iv_token_name1 => cv_tkn_cust_code,                                             -- �g�[�N���FCUSTOMER_CODE
                              iv_token_value1=> lt_del_task_data(i).account_number,                           -- �ڋq�R�[�h
                              iv_token_name2 => cv_tkn_cust_name,                                             -- �g�[�N���FCUSTOMER_NAME
                              iv_token_value2=> lt_del_task_data(i).party_name,                               -- �ڋq��
                              iv_token_name3 => cv_tkn_actual_date,                                           -- �g�[�N���FACTUAL_DATE
                              iv_token_value3=> TO_CHAR(lt_del_task_data(i).actual_end_date, cv_date_format), -- ���ѓ�
                              iv_token_name4 => cv_tkn_visit_kbn,                                             -- �g�[�N���FVISIT_KBN
                              iv_token_value4=> lt_del_task_data(i).attribute11                               -- �L���K��敪
                            );
--
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END del_dup_task;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_dup_cnt    := 0;
    gn_del_cnt    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �d���^�X�N��������(A-2)
    -- ============================================
    get_dup_task(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �d��������1���ȏ㑶�݂���ꍇ�̂ݍ폜���������s
    IF ( gn_dup_cnt >= 1 ) THEN
      -- ============================================
      -- �d���^�X�N�폜����(A-3)
      -- ============================================
      del_dup_task(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF ( lv_retcode != cv_status_normal ) THEN
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    Errbuf        Out Varchar2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ���^�[���R�[�h������̏ꍇ
    IF ( lv_retcode = cv_status_normal ) THEN
      -- �d��������0���̏ꍇ
      IF ( gn_dup_cnt = 0 ) THEN
        -- �Ώۃf�[�^�Ȃ����b�Z�[�W���o��
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_nodata
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        lv_message_code := cv_normal_msg;       -- �I�����b�Z�[�W�F����
        lv_retcode      := cv_status_normal;    -- ���^�[���R�[�h�F����
--
      -- �폜������1���ȏ㑶�݂���ꍇ
      ELSIF ( gn_del_cnt >= 1 ) THEN
        -- �폜���b�Z�[�W���o��
        FOR ck_no IN 1..gn_del_cnt LOOP
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => gt_del_msg_data(ck_no)
          );
          --��s�}��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END LOOP;
        lv_message_code := cv_warn_msg;         -- �I�����b�Z�[�W�F�x��
        lv_retcode      := cv_status_warn;      -- ���^�[���R�[�h�F�x��
--
      END IF;
--
    -- ���^�[���R�[�h������ȊO�̏ꍇ
    ELSE
      gn_del_cnt   := 0;    -- �폜����������
      gn_error_cnt := 1;    -- �G���[����1��
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_message_code := cv_error_msg;        -- �I�����b�Z�[�W�F�G���[
      lv_retcode      := cv_status_error;     -- ���^�[���R�[�h�F�G���[
--
    END IF;
--
    -- �������b�Z�[�W���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count1             -- �g�[�N���FCOUNT1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)    -- �Ώی���
                    ,iv_token_name2  => cv_tkn_count2             -- �g�[�N���FCOUNT2
                    ,iv_token_value2 => TO_CHAR(gn_del_cnt)       -- �폜����
                    ,iv_token_name3  => cv_tkn_count3             -- �g�[�N���FCOUNT3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)     -- �G���[����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS019A01C;
