CREATE OR REPLACE PACKAGE BODY XXCMM003A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A14C(body)
 * Description      : HHT���Ɍڋq�ւ̍ŏI�K�����A�g���邽�߁A�ڋq�}�X�^��ɍŏI�K�����
 *                    �ێ�����K�v������܂��B
 *                    ���@�\������ŉғ������A�ŐV�̍ŏI�K����������X�V���܂��B
 * MD.050           : �ŏI�K����X�V MD050_CMM_003_A14
 * Version          : Issue3.4
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_hz_parties              �ڋq�X�e�[�^�X�X�V(A-6)
 *  prc_ins_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���o�^(A-5)
 *  prc_upd_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���ŏI�K����X�V(A-4)
 *  prc_init                        ��������(A-1)
 *  submain                         ���C�������v���V�[�W��(A-2:�����Ώۃf�[�^���o)
 *                                    �Eprc_init
 *                                    �Eprc_upd_xxcmm_cust_accounts
 *                                    �Eprc_ins_xxcmm_cust_accounts
 *                                    �Eprc_upd_hz_parties
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-7:�I������)
 *                                    �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/21    1.0   SCS Okuyama      �V�K�쐬
 *  2009/02/29    1.1   Yutaka.Kuboshima �ڋq�X�e�[�^�X�X�V������ύX
 *  2009/03/18    1.2   Yuuki.Nakamura   �^�X�N�X�e�[�^�X����`�e�[�u���D���̂̎擾�������u�N���[�Y�v�ɕύX
 *  2009/05/20    1.3   Yutaka.Kuboshima ��QT1_0476,T1_1098�̑Ή�
 *  2009/08/27    1.4   Yutaka.Kuboshima ��Q0001193�̑Ή� �S���c�ƈ��̎擾�������C��
 *                                       (�A�T�C�����g�ԍ� -> �]�ƈ��ԍ�)
 *  2009/11/09    1.5   Shigeto.Niki     ��QE_T4_00135�̑Ή� �G���[�I�� -> �x���I���ɏC��
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bracket_f          CONSTANT VARCHAR2(1) := '[';
  cv_msg_bracket_t          CONSTANT VARCHAR2(1) := ']';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);
  gv_conc_name            VARCHAR2(30);
  gv_conc_status          VARCHAR2(30);
  gn_target_cnt           NUMBER;       -- �Ώی���
  gn_normal_cnt           NUMBER;       -- ���팏��
  gn_error_cnt            NUMBER;       -- �G���[����
  gn_warn_cnt             NUMBER;       -- �X�L�b�v����
  gn_xx_cust_acnt_upd_cnt NUMBER;       -- �ڋq�ǉ����e�[�u���X�V����
  gn_xx_cust_acnt_ins_cnt NUMBER;       -- �ڋq�ǉ����e�[�u���o�^����
  gn_hz_pts_upd_cnt       NUMBER;       -- �p�[�e�B�e�[�u���X�V����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt        EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt            EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_check_para_expt     EXCEPTION;     -- �p�����[�^�G���[
  global_check_lock_expt     EXCEPTION;     -- ���b�N�擾�G���[
  global_get_base_cd_expt    EXCEPTION;     -- ���㋒�_�擾�G���[
  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A14C';        -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ���Ѵװ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- �Ώۃf�[�^����
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';    -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ���b�N�G���[
  cv_msg_xxcmm_00305        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00305';    -- �p�����[�^�G���[
  cv_msg_xxcmm_00306        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00306';    -- �ŏI�K����X�V�G���[
  cv_msg_xxcmm_00307        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00307';    -- ���㋒�_�擾�G���[
  cv_msg_xxcmm_00308        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00308';    -- �ŏI�K����o�^�G���[
  cv_msg_xxcmm_00309        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00309';    -- �ڋq�X�e�[�^�X�X�V�G���[
  cv_msg_xxcmm_00033        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00033';    -- �X�V�������b�Z�[�W
  cv_msg_xxcmm_00034        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00034';    -- �o�^�������b�Z�[�W
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';          -- �v���t�@�C����
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- �e�[�u����
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- �ڋq�R�[�h
  cv_tkn_fnl_call_date      CONSTANT VARCHAR2(13) := 'FINAL_CALL_DT';       -- �ŏI�K���
  cv_tkn_table              CONSTANT VARCHAR2(8)  := 'TBL_NAME';            -- �e�[�u����
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '�ڋq�ǉ����';        -- XXCMM_CUST_ACCOUNTS
  cv_tbl_nm_hzpt            CONSTANT VARCHAR2(8)  := '�p�[�e�B';            -- HZ_PARTIES
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- ���t�t�H�[�}�b�g
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';              -- ���t�H�[�}�b�g
  cv_date_time_fmt          CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';          -- �����t�H�[�}�b�g
  cv_time_max               CONSTANT VARCHAR2(9)  := ' 23:59:59';
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ���щғ�������޺��ޒ�`���̧��
  cv_term_immediate         CONSTANT VARCHAR2(8)  := '00_00_00';            -- �x���������i�����j
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                  -- ����i���{�j
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                   -- �t���O�iYes�j
  cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';                   -- �t���O�iNo�j
  cv_tsk_type_visit         CONSTANT VARCHAR2(4)  := '�K��';                -- �^�X�N�^�C�v���i�K��j
-- 2009/03/18 mod start
--  cv_tsk_status_cmp         CONSTANT VARCHAR2(4)  := '����';                -- �^�X�N�X�e�[�^�X���i�����j
  cv_tsk_status_cmp         CONSTANT VARCHAR2(8)  := '�N���[�Y';            -- �^�X�N�X�e�[�^�X���i�N���[�Y�j
-- 2009/03/18 mod end
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);               -- ���p�X�y�[�X����
  cv_ui_flag_new            CONSTANT VARCHAR2(1)  := '1';                   -- �V�K�^�X�V�t���O�i�V�K�j
  cv_cust_status_mc_cnd     CONSTANT VARCHAR2(2)  := '10';                  -- �ڋq�X�e�[�^�X�i�l�b���j
  cv_cust_status_mc         CONSTANT VARCHAR2(2)  := '20';                  -- �ڋq�X�e�[�^�X�i�l�b�j
  --
  cv_para01_name            CONSTANT VARCHAR2(12) := '������(FROM)';        -- �ݶ��ĥ���Ұ���01
  cv_para02_name            CONSTANT VARCHAR2(12) := '������(TO)  ';        -- �ݶ��ĥ���Ұ���02
  cv_para_at_name           CONSTANT VARCHAR2(10) := '�����擾�l';          -- �ݶ��ĥ���Ұ���_����
--
-- 2009/05/20 Ver1.3 ��QT1_1098 add start by Yutaka.Kuboshima
  cv_cust_kbn               CONSTANT VARCHAR2(2)  := '10';                  -- �ڋq�敪�i�ڋq�j
  cv_uesama_kbn             CONSTANT VARCHAR2(2)  := '12';                  -- �ڋq�敪�i��l�ڋq�j
-- 2009/05/20 Ver1.3 ��QT1_1098 add end by Yutaka.Kuboshima
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_cal_code           VARCHAR2(10);   -- �V�X�e���ғ����J�����_�R�[�h�l
  gd_now_proc_date      DATE;           -- �Ɩ����t
  gd_para_proc_date_f   DATE;           -- ������(From)
  gd_para_proc_date_t   DATE;           -- ������(To)
  --
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --
  -- A-2.�����Ώۃf�[�^���o�J�[�\��
  --
  CURSOR  XXCMM003A14C_cur
  IS
    SELECT
      hzac.cust_account_id        AS  cust_id,              -- �ڋqID
      hzac.account_number         AS  cust_code,            -- �ڋq�R�[�h
      hzac.customer_class_code    AS  cust_kbn,             -- �ڋq�敪
      hzpt.duns_number_c          AS  cust_status,          -- �ڋq�X�e�[�^�X
      TRUNC(fcdt.final_call_date) AS  task_final_call_date, -- ���яI�����i�K����j
      TRUNC(xcac.final_call_date) AS  now_final_call_date,  -- ���ݍŏI�K���
      CASE WHEN (xcac.customer_id IS NULL)
      THEN
        cv_flag_yes
      ELSE
        cv_flag_no
      END                       AS  rec_ins_flg,          -- ���R�[�h�쐬�L��
      hzac.party_id             AS  party_id,             -- �p�[�e�BID
      hzpt.ROWID                AS  hzpt_rowid,           -- ���R�[�hID�i�p�[�e�B�j
      xcac.ROWID                AS  xcac_rowid            -- ���R�[�hID�i�ڋq�ǉ����j
    FROM
      hz_cust_accounts        hzac,                       -- �ڋq�}�X�^
      hz_parties              hzpt,                       -- �p�[�e�B
      xxcmm_cust_accounts     xcac,                       -- �ڋq�ǉ����
-- 2009/05/20 Ver1.3 ��QT1_0476 modify start by Yutaka.Kuboshima
--      (
--        SELECT
--          jtab.customer_id            AS  party_id,         -- �p�[�e�BID
--          MAX(jtab.actual_end_date)   AS  final_call_date   -- ���яI�����i�K����j
--        FROM
--          jtf_tasks_b                 jtab,                 -- �^�X�N
--          jtf_task_statuses_b         jtsb,                 -- �^�X�N�X�e�[�^�X��`
--          jtf_task_statuses_tl        jtst,                 -- �^�X�N�X�e�[�^�X����`
--          jtf_task_types_b            jttb,                 -- �^�X�N�^�C�v��`
--          jtf_task_types_tl           jttt                  -- �^�X�N�^�C�v����`
--        WHERE
--              jtab.task_type_id     = jttb.task_type_id
--          AND jtab.task_status_id   = jtsb.task_status_id
--          AND jttb.task_type_id     = jttt.task_type_id
--          AND jtsb.task_status_id   = jtst.task_status_id
--          AND jttt.language         = cv_lang_ja
--          AND jttt.name             = cv_tsk_type_visit
--          AND jtsb.completed_flag   = cv_flag_yes
--          AND jtst.language         = cv_lang_ja
--          AND jtst.name             = cv_tsk_status_cmp
--          AND jtab.last_update_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
--        GROUP BY
--          jtab.customer_id
--      )                     fcdt      -- �ŏI�K����X�V�Ώۏ��
        (
          SELECT xvav.customer_id          AS party_id,       -- �p�[�e�BID
                 MAX(xvav.actual_end_date) AS final_call_date -- ���яI�����i�K����j
          FROM xxcso_visit_actual_v xvav                      -- �L���K����уr���[
          WHERE xvav.last_update_date BETWEEN gd_para_proc_date_f AND gd_para_proc_date_t
          GROUP BY xvav.customer_id
        )                     fcdt      -- �ŏI�K����X�V�Ώۏ��
-- 2009/05/20 Ver1.3 ��QT1_0476 modify end by Yutaka.Kuboshima
    WHERE
          hzac.party_id         = fcdt.party_id
      AND hzpt.party_id         = hzac.party_id
      AND hzac.cust_account_id  = xcac.customer_id(+)
    FOR UPDATE OF xcac.customer_id, hzpt.party_id NOWAIT
  ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ڋq�X�e�[�^�X�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE prc_upd_hz_parties(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_hz_parties'; -- �v���O������
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
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
    lv_step := 'A-6.1';
    --
    -- �ڋq�X�e�[�^�X�X�VSQL��
-- 2009/02/27 delete start
--    UPDATE
--      hz_parties                    hzpt                          -- �p�[�e�B
--    SET
--      hzpt.duns_number_c            = cv_cust_status_mc,          -- �ڋq�X�e�[�^�X�i�l�b�j
--      hzpt.last_updated_by          = cn_last_updated_by,         -- �ŏI�X�V��
--      hzpt.last_update_date         = cd_last_update_date,        -- �ŏI�X�V��
--      hzpt.last_update_login        = cn_last_update_login,       -- �ŏI�X�V���O�C��
--      hzpt.request_id               = cn_request_id,              -- �v��ID
--      hzpt.program_application_id   = cn_program_application_id,  -- �ݶ��ĥ��۸��ѥ���ع����ID
--      hzpt.program_id               = cn_program_id,              -- �ݶ��ĥ��۸���ID
--      hzpt.program_update_date      = cd_program_update_date      -- �v���O�����X�V��
--    WHERE
--          hzpt.rowid                = iv_rec.hzpt_rowid           -- ���R�[�hID�i�p�[�e�B�j
--    ;
-- 2009/02/27 delete end
-- 2009/02/27 add start
    -- ���ʊ֐��p�[�e�B�}�X�^�X�V�p�֐��ďo��
    xxcmm_003common_pkg.update_hz_party(iv_rec.party_id,
                                        cv_cust_status_mc,
                                        lv_errbuf,
                                        lv_retcode,
                                        lv_errmsg);
    -- �������ʂ��G���[�̏ꍇ��RAISE
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
-- 2009/02/27 add end
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
-- 2009/02/27 add start
    WHEN global_process_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00309,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h1
                        iv_token_value1 =>  iv_rec.cust_code            -- �g�[�N���l1
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod end by Shigeto.Niki
-- 2009/02/27 add end
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00309,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h1
                        iv_token_value1 =>  iv_rec.cust_code            -- �g�[�N���l1
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_upd_hz_parties;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_ins_xxcmm_cust_accounts
   * Description      : �ڋq�ǉ����o�^(A-5)
   ***********************************************************************************/
  PROCEDURE prc_ins_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_xxcmm_cust_accounts'; -- �v���O������
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
    lv_emp_code   hz_org_profiles_ext_b.c_ext_attr1%TYPE;     -- �S���c�ƈ�
    lv_base_code  per_all_assignments_f.ass_attribute5%TYPE;  -- ���_�R�[�h�i�V�j
-- 2009/05/20 Ver1.3 ��QT1_1098 add start by Yutaka.Kuboshima
    lv_delivery_base_code xxcmm_cust_accounts.delivery_base_code%TYPE; -- �[�i���_�R�[�h
-- 2009/05/20 Ver1.3 ��QT1_1098 add end by Yutaka.Kuboshima
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
    lv_step := 'A-5.1';
    --
    -- A-5.�S���c�ƈ��������_�R�[�h�擾
    --
    BEGIN
      --
      lv_emp_code   :=  NULL;
      lv_base_code  :=  NULL;
      -- 
      SELECT
        eres.resource_no,                   -- �S���c�ƈ�
        SUBSTRB(pasi.ass_attribute5, 1, 4)  -- ���_�R�[�h�i�V�j
      INTO
        lv_emp_code,
        lv_base_code
      FROM
        hz_organization_profiles    opro,   -- �g�D�v���t�@�C���e�[�u��
        ego_resource_agv            eres,   -- �g�D�v���t�@�C���g���e�[�u��
        per_all_assignments_f       pasi    -- �A�T�C�������g�}�X�^�e�[�u��
-- 2009/08/27 Ver1.4 add start by Yutaka.Kuboshima
       ,per_all_people_f            papf    -- �]�ƈ��}�X�^�e�[�u��
-- 2009/08/27 Ver1.4 add end by Yutaka.Kuboshima
      WHERE
            opro.organization_profile_id  = eres.organization_profile_id
-- 2009/08/27 Ver1.4 modify start by Yutaka.Kuboshima
--        AND eres.resource_no              = pasi.assignment_number
        AND eres.resource_no              = papf.employee_number
        AND papf.person_id                = pasi.person_id
        AND gd_now_proc_date BETWEEN
              papf.effective_start_date AND papf.effective_end_date
-- 2009/08/27 Ver1.4 modify end by Yutaka.Kuboshima
        AND gd_now_proc_date BETWEEN
              opro.effective_start_date AND NVL(opro.effective_end_date, gd_now_proc_date)
        AND gd_now_proc_date BETWEEN
              NVL(eres.resource_s_date, gd_now_proc_date) AND NVL(eres.resource_e_date, gd_now_proc_date)
        AND gd_now_proc_date BETWEEN
              pasi.effective_start_date AND pasi.effective_end_date
        AND opro.party_id                 = iv_rec.party_id
        AND ROWNUM  = 1
      ;
      --
      IF (lv_base_code IS NULL) THEN
        RAISE global_get_base_cd_expt;
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_get_base_cd_expt;
    END;
-- 2009/05/20 Ver1.3 ��QT1_01098 add start by Yutaka.Kuboshima
    -- �ڋq�敪��'10','12'�̏ꍇ�A���_�R�[�h�i�V�j��[�i���_�ɓo�^
    IF (iv_rec.cust_kbn IN (cv_cust_kbn, cv_uesama_kbn)) THEN
      lv_delivery_base_code := lv_base_code;
    ELSE
      lv_delivery_base_code := NULL;
    END IF;
-- 2009/05/20 Ver1.3 ��QT1_01098 add end by Yutaka.Kuboshima
    --
    -- �ڋq�ǉ����o�^SQL��
    lv_step := 'A-5.1';
    --
    INSERT INTO xxcmm_cust_accounts
    (
      customer_id,                  -- �ڋqID
      customer_code,                -- �ڋq�R�[�h
      cust_update_flag,             -- �V�K�^�X�V�t���O
      business_low_type,            -- �Ƒԁi�����ށj
      industry_div,                 -- �Ǝ�
      selling_transfer_div,         -- ������ѐU��
      torihiki_form,                -- ����`��
      delivery_form,                -- �z���`��
      wholesale_ctrl_code,          -- �≮�Ǘ��R�[�h
      ship_storage_code,            -- �o�׌��ۊǏꏊ(EDI)
      start_tran_date,              -- ��������
      final_tran_date,              -- �ŏI�����
      past_final_tran_date,         -- �O���ŏI�����
      final_call_date,              -- �ŏI�K���
      stop_approval_date,           -- ���~���ٓ�
      stop_approval_reason,         -- ���~���R
      vist_untarget_date,           -- �ڋq�ΏۊO�ύX��
      vist_target_div,              -- �K��Ώۋ敪
      party_representative_name,    -- ��\�Җ��i�����j
      party_emp_name,               -- �S���ҁi�����j
      sale_base_code,               -- ���㋒�_�R�[�h
      past_sale_base_code,          -- �O�����㋒�_�R�[�h
      rsv_sale_base_act_date,       -- �\�񔄏㋒�_�L���J�n��
      rsv_sale_base_code,           -- �\�񔄏㋒�_�R�[�h
      delivery_base_code,           -- �[�i���_�R�[�h
      sales_head_base_code,         -- �̔���{���S�����_
      chain_store_code,             -- �`�F�[���X�R�[�h�iEDI�j
      store_code,                   -- �X�܃R�[�h
      cust_store_name,              -- �ڋq�X�ܖ���
      torihikisaki_code,            -- �����R�[�h
      sales_chain_code,             -- �̔���`�F�[���R�[�h
      delivery_chain_code,          -- �[�i��`�F�[���R�[�h
      policy_chain_code,            -- �����p�`�F�[���R�[�h
      intro_chain_code1,            -- �Љ�҃`�F�[���R�[�h�P
      intro_chain_code2,            -- �Љ�҃`�F�[���R�[�h�Q
      tax_div,                      -- ����ŋ敪
      rate,                         -- �����v�Z�p�|��
      receiv_discount_rate,         -- �����l����
      conclusion_day1,              -- �����v�Z���ߓ��P
      conclusion_day2,              -- �����v�Z���ߓ��Q
      conclusion_day3,              -- �����v�Z���ߓ��R
      contractor_supplier_code,     -- �_��Ҏd����R�[�h
      bm_pay_supplier_code1,        -- �Љ��BM�x���d����R�[�h�P
      bm_pay_supplier_code2,        -- �Љ��BM�x���d����R�[�h�Q
      delivery_order,               -- �z�����iEDI)
      edi_district_code,            -- EDI�n��R�[�h�iEDI)
      edi_district_name,            -- EDI�n�於�iEDI)
      edi_district_kana,            -- EDI�n�於�J�i�iEDI)
      center_edi_div,               -- �Z���^�[EDI�敪
      tsukagatazaiko_div,           -- �ʉߍ݌Ɍ^�敪�iEDI�j
      establishment_location,       -- �ݒu���P�[�V����
      open_close_div,               -- �����I�[�v���E�N���[�Y�敪
      operation_div,                -- �I�y���[�V�����敪
      change_amount,                -- �ޑK
      vendor_machine_number,        -- �����̔��@�ԍ��i�����j
      established_site_name,        -- �ݒu�於�i�����j
      cnvs_date,                    -- �ڋq�l����
      cnvs_base_code,               -- �l�����_�R�[�h
      cnvs_business_person,         -- �l���c�ƈ�
      new_point_div,                -- �V�K�|�C���g�敪
      new_point,                    -- �V�K�|�C���g
      intro_base_code,              -- �Љ�_�R�[�h
      intro_business_person,        -- �Љ�c�ƈ�
      edi_chain_code,               -- �`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
      latitude,                     -- �ܓx
      longitude,                    -- �o�x
      management_base_code,         -- �Ǘ������_�R�[�h
      edi_item_code_div,            -- EDI�A�g�i�ڃR�[�h�敪
      edi_forward_number,           -- EDI�`���ǔ�
      handwritten_slip_div,         -- EDI�菑�`�[�`���敪
      deli_center_code,             -- EDI�[�i�Z���^�[�R�[�h
      deli_center_name,             -- EDI�[�i�Z���^�[��
      dept_hht_div,                 -- �S�ݓX�pHHT�敪
      bill_base_code,               -- �������_�R�[�h
      receiv_base_code,             -- �������_�R�[�h
      child_dept_shop_code,         -- �S�ݓX�`��R�[�h
      parnt_dept_shop_code,         -- �S�ݓX�`��R�[�h�y�e���R�[�h�p�z
      past_customer_status,         -- �O���ڋq�X�e�[�^�X
      created_by,                   -- �쐬��
      creation_date,                -- �쐬��
      last_updated_by,              -- �ŏI�X�V��
      last_update_date,             -- �ŏI�X�V��
      last_update_login,            -- �ŏI�X�V۸޲�
      request_id,                   -- �v��ID
      program_application_id,       -- �ݶ��ĥ��۸��ѥ���ع����ID
      program_id,                   -- �ݶ��ĥ��۸���ID
      program_update_date           -- ��۸��эX�V��
    )
    VALUES
    (
      iv_rec.cust_id,               -- �ڋqID
      iv_rec.cust_code,             -- �ڋq�R�[�h
      cv_ui_flag_new,               -- �V�K�^�X�V�t���O
      NULL,                         -- �Ƒԁi�����ށj
      NULL,                         -- �Ǝ�
      NULL,                         -- ������ѐU��
      NULL,                         -- ����`��
      NULL,                         -- �z���`��
      NULL,                         -- �≮�Ǘ��R�[�h
      NULL,                         -- �o�׌��ۊǏꏊ(EDI)
      NULL,                         -- ��������
      NULL,                         -- �ŏI�����
      NULL,                         -- �O���ŏI�����
      iv_rec.task_final_call_date,  -- �ŏI�K���
      NULL,                         -- ���~���ٓ�
      NULL,                         -- ���~���R
      NULL,                         -- �ڋq�ΏۊO�ύX��
      NULL,                         -- �K��Ώۋ敪
      NULL,                         -- ��\�Җ��i�����j
      NULL,                         -- �S���ҁi�����j
      SUBSTRB(lv_base_code, 1, 4),  -- ���㋒�_�R�[�h
      SUBSTRB(lv_base_code, 1, 4),  -- �O�����㋒�_�R�[�h
      NULL,                         -- �\�񔄏㋒�_�L���J�n��
      NULL,                         -- �\�񔄏㋒�_�R�[�h
-- 2009/05/20 Ver1.3 ��QT1_1098 modify start by Yutaka.Kuboshima
--      NULL,                         -- �[�i���_�R�[�h
      lv_delivery_base_code,        -- �[�i���_�R�[�h
-- 2009/05/20 Ver1.3 ��QT1_1098 modify end by Yutaka.Kuboshima
      NULL,                         -- �̔���{���S�����_
      NULL,                         -- �`�F�[���X�R�[�h�iEDI�j
      NULL,                         -- �X�܃R�[�h
      NULL,                         -- �ڋq�X�ܖ���
      NULL,                         -- �����R�[�h
      NULL,                         -- �̔���`�F�[���R�[�h
      NULL,                         -- �[�i��`�F�[���R�[�h
      NULL,                         -- �����p�`�F�[���R�[�h
      NULL,                         -- �Љ�҃`�F�[���R�[�h�P
      NULL,                         -- �Љ�҃`�F�[���R�[�h�Q
      NULL,                         -- ����ŋ敪
      NULL,                         -- �����v�Z�p�|��
      NULL,                         -- �����l����
      NULL,                         -- �����v�Z���ߓ��P
      NULL,                         -- �����v�Z���ߓ��Q
      NULL,                         -- �����v�Z���ߓ��R
      NULL,                         -- �_��Ҏd����R�[�h
      NULL,                         -- �Љ��BM�x���d����R�[�h�P
      NULL,                         -- �Љ��BM�x���d����R�[�h�Q
      NULL,                         -- �z�����iEDI)
      NULL,                         -- EDI�n��R�[�h�iEDI)
      NULL,                         -- EDI�n�於�iEDI)
      NULL,                         -- EDI�n�於�J�i�iEDI)
      NULL,                         -- �Z���^�[EDI�敪
      NULL,                         -- �ʉߍ݌Ɍ^�敪�iEDI�j
      NULL,                         -- �ݒu���P�[�V����
      NULL,                         -- �����I�[�v���E�N���[�Y�敪
      NULL,                         -- �I�y���[�V�����敪
      NULL,                         -- �ޑK
      NULL,                         -- �����̔��@�ԍ��i�����j
      NULL,                         -- �ݒu�於�i�����j
      NULL,                         -- �ڋq�l����
      NULL,                         -- �l�����_�R�[�h
      NULL,                         -- �l���c�ƈ�
      NULL,                         -- �V�K�|�C���g�敪
      NULL,                         -- �V�K�|�C���g
      NULL,                         -- �Љ�_�R�[�h
      NULL,                         -- �Љ�c�ƈ�
      NULL,                         -- �`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
      NULL,                         -- �ܓx
      NULL,                         -- �o�x
      NULL,                         -- �Ǘ������_�R�[�h
      NULL,                         -- EDI�A�g�i�ڃR�[�h�敪
      NULL,                         -- EDI�`���ǔ�
      NULL,                         -- EDI�菑�`�[�`���敪
      NULL,                         -- EDI�[�i�Z���^�[�R�[�h
      NULL,                         -- EDI�[�i�Z���^�[��
      NULL,                         -- �S�ݓX�pHHT�敪
      NULL,                         -- �������_�R�[�h
      NULL,                         -- �������_�R�[�h
      NULL,                         -- �S�ݓX�`��R�[�h
      NULL,                         -- �S�ݓX�`��R�[�h�y�e���R�[�h�p�z
      NULL,                         -- �O���ڋq�X�e�[�^�X
      cn_created_by,                -- �쐬��
      cd_creation_date,             -- �쐬��
      cn_last_updated_by,           -- �ŏI�X�V��
      cd_last_update_date,          -- �ŏI�X�V��
      cn_last_update_login,         -- �ŏI�X�V۸޲�
      cn_request_id,                -- �v��ID
      cn_program_application_id,    -- �ݶ��ĥ��۸��ѥ���ع����ID
      cn_program_id,                -- �ݶ��ĥ��۸���ID
      cd_program_update_date        -- ��۸��эX�V��
    )
    ;
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_get_base_cd_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00307,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h1
                        iv_token_value1 =>  iv_rec.cust_code,           -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_fnl_call_date,       -- �g�[�N���R�[�h2
                        iv_token_value2 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- �g�[�N���l2
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      -- �����X�e�[�^�X�Z�b�g
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod end by Shigeto.Niki
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00308,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.cust_code,           -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_fnl_call_date,       -- �g�[�N���R�[�h3
                        iv_token_value3 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- �g�[�N���l3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_ins_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ŏI�K����X�V(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  XXCMM003A14C_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcmm_cust_accounts'; -- �v���O������
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
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
    lv_step := 'A-4.1';
    --
    -- �ŏI�K����X�VSQL��
    UPDATE
      -- �ڋq�ǉ����
      xxcmm_cust_accounts         xcac
    SET
      -- �ŏI�K���
      xcac.final_call_date        = iv_rec.task_final_call_date,
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,         -- �ŏI�X�V��
      xcac.last_update_date       = cd_last_update_date,        -- �ŏI�X�V��
      xcac.last_update_login      = cn_last_update_login,       -- �ŏI�X�V���O�C��
      xcac.request_id             = cn_request_id,              -- �v��ID
      xcac.program_application_id = cn_program_application_id,  -- �ݶ��ĥ��۸��ѥ���ع����ID
      xcac.program_id             = cn_program_id,              -- �ݶ��ĥ��۸���ID
      xcac.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE
      xcac.rowid  = iv_rec.xcac_rowid                           -- ���R�[�hID�i�ڋq�ǉ����j
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00306,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.cust_code,           -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_fnl_call_date,       -- �g�[�N���R�[�h3
                        iv_token_value3 =>  TO_CHAR(iv_rec.task_final_call_date, cv_date_fmt) -- �g�[�N���l3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod end by Shigeto.Niki
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_upd_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE prc_init(
    iv_proc_date_from  IN  VARCHAR2,     --  ������
    iv_proc_date_to    IN  VARCHAR2,     --  ������
    ov_errbuf     OUT VARCHAR2,     --  �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --  ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- �v���O������
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
    lv_step             VARCHAR2(10);   -- �X�e�b�v
    lv_now_proc_date    VARCHAR2(10);   -- �Ɩ����t�i������j
    lv_proc_date        VARCHAR2(10);   -- �p�����[�^������
    ld_now_proc_date    DATE;           -- �Ɩ����t
    ld_prev_proc_date   DATE;           -- �O�Ɩ����t
    lv_para_edit_buf    VARCHAR2(60);   -- �o�͗p���Ұ�������ҏW�̈�
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
    -- �v���t�@�C���l�擾
    --
    lv_step := 'A-1.1';
    -- �V�X�e���ғ����J�����_�R�[�h�擾
    gv_cal_code := fnd_profile.value(cv_profile_ctrl_cal);
    IF (gv_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_msg_xxcmm_00002,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ctrl_cal   -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    
    --
    -- �Ɩ����t�擾
    --
    lv_step := 'A-1.2';
    --
    ld_now_proc_date    :=  xxccp_common_pkg2.get_process_date;
    gd_now_proc_date    :=  ld_now_proc_date;
    -- ������(To)���O���[�o���ϐ��Ɋi�[
    IF (iv_proc_date_to IS NULL) THEN
      gd_para_proc_date_t   :=  TO_DATE(TO_CHAR(ld_now_proc_date, cv_date_fmt) || cv_time_max, cv_date_time_fmt);
    ELSE
      gd_para_proc_date_t   :=  TO_DATE(iv_proc_date_to || cv_time_max, cv_date_time_fmt);
    END IF;
    --
    -- �O�Ɩ����t�擾
    --
    lv_step := 'A-1.3';
    --
    ld_prev_proc_date   :=  xxccp_common_pkg2.get_working_day(
                              gd_now_proc_date,
                              -1,
                              gv_cal_code
                            );
    ld_prev_proc_date   :=  TRUNC(ld_prev_proc_date + 1);
    --
    -- ������(From)���O���[�o���ϐ��Ɋi�[
    IF (iv_proc_date_from IS NULL) THEN
      gd_para_proc_date_f   :=  ld_prev_proc_date;
    ELSE
      gd_para_proc_date_f   :=  TO_DATE(iv_proc_date_from, cv_date_fmt);
    END IF;
     lv_step := 'A-1.4';
    --
    -- �R���J�����g�E�p�����[�^�̃��O�o��
    -- ������(From)
    lv_para_edit_buf    :=  cv_para01_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_from ||  cv_msg_bracket_t;
    -- ������(From)�̎����擾�l
    IF (iv_proc_date_from IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_f, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- ������(To)
    lv_para_edit_buf    :=  cv_para02_name    ||  cv_msg_part       ||
                            cv_msg_bracket_f  ||  iv_proc_date_to   ||  cv_msg_bracket_t;
    -- ������(To)�̎����擾�l
    IF (iv_proc_date_to IS NULL) THEN
      lv_para_edit_buf  :=  lv_para_edit_buf  ||  cv_msg_part       ||  cv_para_at_name     ||
                            cv_msg_bracket_f  ||  TO_CHAR(gd_para_proc_date_t, cv_date_fmt) ||  cv_msg_bracket_t;
    END IF;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    -- ��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --
    --
    -- �p�����[�^�`�F�b�N�i�������j
    --
    lv_step := 'A-1.5';
    IF (gd_para_proc_date_f > gd_para_proc_date_t) THEN
      -- �p�����[�^�́u������(From)�v�� �u������(To)�v�ł���ꍇ�A�G���[
      -- ���b�Z�[�W�擾
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00305    -- ���b�Z�[�W�R�[�h
                      );
      -- �p�����[�^�G���[��O
      RAISE global_check_para_expt;
      --
    END IF;
    --
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �p�����[�^�G���[��O�n���h�� ***
    WHEN global_check_para_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_init;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_from   IN  VARCHAR2,   -- �R���J�����g�E�p�����[�^ ������(From)
    iv_proc_date_to     IN  VARCHAR2,   -- �R���J�����g�E�p�����[�^ ������(To)
    ov_errbuf           OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
--
    -- *** ���[�J���ϐ� ***
    lb_err_flg                  BOOLEAN;    -- �G���[�L��
    lb_xxcust_acnt_upd_cnt_flg  BOOLEAN;    -- �ڋq�ǉ����X�V�����J�E���g�L��
    lb_xxcust_acnt_ins_cnt_flg  BOOLEAN;    -- �ڋq�ǉ����o�^�����J�E���g�L��
    ln_err_cnt                  NUMBER;     -- �G���[�������i�P�ڋq�P�ʁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    XXCMM003A14C_rec    XXCMM003A14C_cur%ROWTYPE;
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
    gn_target_cnt           :=  0;
    gn_normal_cnt           :=  0;
    gn_error_cnt            :=  0;
    gn_warn_cnt             :=  0;
    gn_xx_cust_acnt_upd_cnt :=  0;
    gn_xx_cust_acnt_ins_cnt :=  0;
    gn_hz_pts_upd_cnt       :=  0;
--
    -- �G���[�L����������
    lb_err_flg := FALSE;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.����������
    -- ===============================
    lv_step := 'A-1';
    prc_init(
      iv_proc_date_from,  -- ������(From)
      iv_proc_date_to,    -- ������(To)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- A-2.�����Ώۃf�[�^���o
    -- ===============================
    lv_step := 'A-2';
    OPEN  XXCMM003A14C_cur;
    --
    LOOP
      -- �����Ώۃf�[�^�E�J�[�\���t�F�b�`
      FETCH XXCMM003A14C_cur INTO XXCMM003A14C_rec;
      EXIT WHEN XXCMM003A14C_cur%NOTFOUND;
      --
      gn_target_cnt := XXCMM003A14C_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      lb_xxcust_acnt_upd_cnt_flg := FALSE;
      lb_xxcust_acnt_ins_cnt_flg := FALSE;
      --
      -- ===============================
      -- A-3.SAVE POINT ���s
      -- ===============================
      lv_step := 'A-3';
      SAVEPOINT svpt_cust_rec;
      --
      IF (XXCMM003A14C_rec.rec_ins_flg = cv_flag_no) THEN
        --
        IF (      (XXCMM003A14C_rec.now_final_call_date IS NULL)
              OR  (XXCMM003A14C_rec.task_final_call_date > XXCMM003A14C_rec.now_final_call_date)) THEN
          -- ===============================
          -- A-4.�ŏI�K����X�V
          -- ===============================
          lv_step := 'A-4';
          prc_upd_xxcmm_cust_accounts(
            XXCMM003A14C_rec,   -- �J�[�\�����R�[�h
            lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode <> cv_status_normal) THEN
            lb_err_flg  :=  TRUE;
            ln_err_cnt  :=  1;
            fnd_file.put_line(
              which => fnd_file.output,
              buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
            );
            fnd_file.put_line(
              which => fnd_file.log,
              buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
            );
            fnd_file.put_line(
              which => fnd_file.log,
              buff  => lv_errbuf --�G���[���b�Z�[�W
            );
            -- ���b�Z�[�W�ҏW�̈揉����
            lv_errmsg := NULL;
            lv_errbuf := NULL;
            --
          END IF;
        --
        END IF;
        -- �ڋq�ǉ����X�V�����J�E���g
        IF (ln_err_cnt = 0) THEN
          gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt + 1;
          lb_xxcust_acnt_upd_cnt_flg := TRUE;
        END IF;
      ELSE
        -- ===============================
        -- A-5.�ڋq�ǉ����o�^
        -- ===============================
        lv_step := 'A-5';
        prc_ins_xxcmm_cust_accounts(
          XXCMM003A14C_rec,   -- �J�[�\�����R�[�h
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_err_flg  :=  TRUE;
          ln_err_cnt  :=  1;
          fnd_file.put_line(
            which => fnd_file.output,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errbuf --�G���[���b�Z�[�W
          );
          -- ���b�Z�[�W�ҏW�̈揉����
          lv_errmsg := NULL;
          lv_errbuf := NULL;
          --
        ELSE
          -- �ڋq�ǉ����o�^�����J�E���g
          gn_xx_cust_acnt_ins_cnt := gn_xx_cust_acnt_ins_cnt + 1;
          lb_xxcust_acnt_ins_cnt_flg := TRUE;
        END IF;
        --
      END IF;
      --
      -- 10:MC���
-- 2009/03/02 modify start
      IF (XXCMM003A14C_rec.cust_status = cv_cust_status_mc_cnd) --THEN
        AND (ln_err_cnt = 0)
      THEN
-- 2009/03/02 modify end
        -- ===============================
        -- A-6.�ڋq�X�e�[�^�X�X�V
        -- ===============================
        lv_step := 'A-6';
        prc_upd_hz_parties(
          XXCMM003A14C_rec,   -- �J�[�\�����R�[�h
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_err_flg  :=  TRUE;
          ln_err_cnt  :=  1;
          fnd_file.put_line(
            which => fnd_file.output,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errmsg --���[�U�[�G���[���b�Z�[�W
          );
          fnd_file.put_line(
            which => fnd_file.log,
            buff  => lv_errbuf --�G���[���b�Z�[�W
          );
          -- ���b�Z�[�W�ҏW�̈揉����
          lv_errmsg := NULL;
          lv_errbuf := NULL;
          --
          -- �ڋq�ǉ����X�V�����J�E���g�߂�
          IF (lb_xxcust_acnt_upd_cnt_flg = TRUE) THEN
            gn_xx_cust_acnt_upd_cnt := gn_xx_cust_acnt_upd_cnt - 1;
          END IF;
          -- �ڋq�ǉ����o�^�����J�E���g�߂�
          IF (lb_xxcust_acnt_ins_cnt_flg = TRUE) THEN
            gn_xx_cust_acnt_ins_cnt := gn_xx_cust_acnt_ins_cnt - 1;
          END IF;
          --
        ELSE
          -- �p�[�e�B�X�V�i�ڋq�X�e�[�^�X�j����
          gn_hz_pts_upd_cnt := gn_hz_pts_upd_cnt + 1;
        END IF;
        --
      END IF;
      --
      -- ���������A�G���[�����̃J�E���g
      IF (ln_err_cnt = 0) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod start by Shigeto.Niki
--        gn_error_cnt := gn_error_cnt + ln_err_cnt;
        gn_warn_cnt := gn_warn_cnt + ln_err_cnt;
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod end by Shigeto.Niki
      END IF;
      --
      -- �G���[���o���ASAVEPOINT�܂�ROLLBACK
      IF (ln_err_cnt > 0) THEN
        -- ===============================
        -- A-9.ROLLBACK���s����
        -- ===============================
        lv_step := 'A-9';
        ROLLBACK TO svpt_cust_rec;
        --
      END IF;
      --
    END LOOP;
    --
    -- �J�[�\���N���[�Y
    CLOSE XXCMM003A14C_cur;
    --
    IF (lb_err_flg = FALSE) THEN
      -- �Ώۃf�[�^�Ȃ����̃��b�Z�[�W
      IF (gn_target_cnt = 0) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                          iv_name         =>  cv_msg_xxcmm_00001      -- ���b�Z�[�W�R�[�h
                        );
        fnd_file.put_line(
          which => fnd_file.output,
          buff  => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
        fnd_file.put_line(
          which => fnd_file.log,
          buff  => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
      END IF;
    ELSE
      -- �X�V�G���[���������Ă���ׁA�G���[���Z�b�g
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod start by Shigeto.Niki
--      ov_retcode  :=  cv_status_error;
      ov_retcode  :=  cv_status_warn;      
-- 2009/11/09 Ver1.5 ��QE_T4_00135 mod end by Shigeto.Niki
    END IF;
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �p�����[�^�G���[��O�n���h�� ***
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE  XXCMM003A14C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00008,     -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,        -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac          -- �g�[�N���l1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE XXCMM003A14C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF XXCMM003A14C_cur%ISOPEN THEN
        CLOSE XXCMM003A14C_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
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
    errbuf            OUT   VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT   VARCHAR2,     -- ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date_from IN    VARCHAR2,     -- �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to   IN    VARCHAR2      -- �R���J�����g�E�p�����[�^������(TO)
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
-- 2009/11/09 Ver1.5 ��QE_T4_00135 add start by Shigeto.Niki
    cv_skip_rec_msg   CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
-- 2009/11/09 Ver1.5 ��QE_T4_00135 add end by Shigeto.Niki
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_all_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_prt_error_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ����
    --
    cv_log             CONSTANT VARCHAR2(100) := 'LOG';              -- ���O
    cv_output          CONSTANT VARCHAR2(100) := 'OUTPUT';           -- �A�E�g�v�b�g
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
    ----------------------------------
    -- ���O�w�b�_�o��
    ----------------------------------
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_proc_date_from,    -- �R���J�����g�E�p�����[�^������(FROM)
      iv_proc_date_to,      -- �R���J�����g�E�p�����[�^������(TO)
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.output,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errbuf)   --�G���[���b�Z�[�W
        );
      END IF;
    END IF;
    --��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�ڋq�ǉ����X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_xx_cust_acnt_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_xcac
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�ڋq�ǉ����o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00034,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_xx_cust_acnt_ins_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_xcac
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�p�[�e�B�X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name_cmm,
                     iv_name         => cv_msg_xxcmm_00033,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_hz_pts_upd_cnt),
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => cv_tbl_nm_hzpt
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
-- 2009/11/09 Ver1.5 ��QE_T4_00135 add start by Shigeto.Niki
    --
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_skip_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
-- 2009/11/09 Ver1.5 ��QE_T4_00135 add end by Shigeto.Niki
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�󔒍s�o��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      IF (gn_normal_cnt > 0) THEN
        lv_message_code := cv_prt_error_msg;
      ELSE
        lv_message_code := cv_all_error_msg;
      END IF;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�R�~�b�g
    COMMIT;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmm003a14c;
/
