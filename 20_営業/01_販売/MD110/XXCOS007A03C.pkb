CREATE OR REPLACE PACKAGE BODY APPS.XXCOS007A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS007A03C(body)
 * Description      : �󒍃N���[�Y�Ώۏ��e�[�u���̏�񂩂�󒍃��[�N���X�g�̃X�e�[�^�X��
 *                    �X�V���܂��B
 * MD.050           :  MD050_COS_007_A03_�󒍖���WF�N���[�Y
 *
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  start_proc             �������� (A-1)
 *  get_order_close        �󒍃N���[�Y�Ώۏ��擾 (A-2)
 *  upd_wk_staus           ���[�N�t���[�X�e�[�^�X�X�V (A-3)
 *  upd_order_close        �󒍃N���[�Y�Ώۏ��X�V (A-4)
 *  del_order_close        �󒍃N���[�Y�Ώۏ��폜 (A-6)
 *  submain                ���C�������v���V�[�W��
 *                           �Z�[�u�|�C���g���s���� (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-09-01    1.0   Kazuo.Satomura   �V�K�쐬
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
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_delete_cnt    NUMBER;                    -- �폜����
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
  cv_pkg_name CONSTANT VARCHAR2(100) := 'XXCOS007A03C';  -- �p�b�P�[�W��
  cv_app_name CONSTANT VARCHAR2(5)   := 'XXCOS';         -- �A�v���P�[�V�����Z�k��
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  cv_tkn_number_02 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00001'; -- ���b�N�G���[
  cv_tkn_number_03 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13906'; -- �󒍖���WF�N���[�Y�G���[
  cv_tkn_number_04 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_tkn_number_05 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00012'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_tkn_number_06 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13907'; -- �����������b�Z�[�W
  cv_tkn_number_07 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  cv_tkn_number_08 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-10075'; -- �폜����
  cv_tkn_number_09 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13901'; -- ���̓p�����[�^�G���[
  cv_tkn_number_10 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13902'; -- �c�Ɠ��擾�G���[���b�Z�[�W
  cv_tkn_number_11 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11952'; -- ���b�Z�[�W�p������i���s�敪�j
  cv_tkn_number_12 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13903'; -- ���b�Z�[�W�p������i�󒍃N���[�Y�폜�����j
  cv_tkn_number_13 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13904'; -- ���b�Z�[�W�p������i�󒍃N���[�Y�Ώۏ��e�[�u���j
  cv_tkn_number_14 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-13905'; -- ���̓p�����[�^�o�̓��b�Z�[�W
  cv_tkn_number_15 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11532'; -- ���b�Z�[�W�p������i�󒍃N���[�YAPI�j
  --
  -- �g�[�N���R�[�h
  cv_tkn_param       CONSTANT VARCHAR2(20) := 'PARAM';
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_profile     CONSTANT VARCHAR2(20) := 'PROFILE';
  cv_tkn_api_name    CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_line_ID     CONSTANT VARCHAR2(20) := 'LINE_ID';
  cv_tkn_table_name  CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data    CONSTANT VARCHAR2(20) := 'KEY_DATA';
  cv_tkn_count1      CONSTANT VARCHAR2(20) := 'COUNT1';
  cv_tkn_count2      CONSTANT VARCHAR2(20) := 'COUNT2';
  cv_tkn_count3      CONSTANT VARCHAR2(20) := 'COUNT3';
  cv_tkn_count4      CONSTANT VARCHAR2(20) := 'COUNT4';
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_value       CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_basic_day   CONSTANT VARCHAR2(20) := 'BASIC_DAY';
  cv_tkn_working_day CONSTANT VARCHAR2(20) := 'WORKING_DAY';
  --
  -- DEBUG_LOG�p���b�Z�[�W
  --cv_debug_msg1_1       CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  --cv_debug_msg1_2       CONSTANT VARCHAR2(200) := 'gd_business_date = ';
  --cv_debug_msg1_3       CONSTANT VARCHAR2(200) := '<< ���̓p�����[�^ >>';
  --cv_debug_msg1_4       CONSTANT VARCHAR2(200) := 'in_exe_div = ';
  --cv_debug_msg1_5       CONSTANT VARCHAR2(200) := '<< �v���t�@�C���I�v�V�����l >>';
  --cv_debug_msg1_6       CONSTANT VARCHAR2(200) := 'lt_delete_days = ';
  --cv_debug_msg1_7       CONSTANT VARCHAR2(200) := '<< ���[�N�t���[�X�e�[�^�X�X�V���s >>';
  --cv_debug_msg1_8       CONSTANT VARCHAR2(200) := 'lv_errmsg = ';
  --cv_debug_msg_rollback CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�J�[�\���^
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h��`
  -- ===============================
  TYPE order_line_id_ttype IS TABLE OF xxcos_order_close.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE process_status_ttype IS TABLE OF xxcos_order_close.process_status%TYPE INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  gt_order_line_id_tab  order_line_id_ttype;
  gt_process_status_tab process_status_ttype;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o����O
  -- ===============================
  global_lock_expt EXCEPTION;  -- ���b�N��O
  --
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : start_proc
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE start_proc(
     in_exe_div      IN         NUMBER                                              -- ���s�敪
    ,od_process_date OUT        DATE                                                -- �Ɩ��������t
    ,ot_delete_days  OUT        fnd_profile_option_values.profile_option_value%TYPE -- �󒍃N���[�Y�폜����
    ,ov_errbuf       OUT NOCOPY VARCHAR2                                            -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2                                            -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                                            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'start_proc';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_prof_delete_days CONSTANT fnd_profile_option_values.profile_option_value%TYPE := 'XXCOS1_ORDER_DELETE_DAYS';
    cn_exe_div_any_time CONSTANT NUMBER                                              := 1; -- �������s
    cn_exe_div_regular  CONSTANT NUMBER                                              := 2; -- ������s
    -- 
    -- *** ���[�J���ϐ� ***
    lv_work         VARCHAR2(4000);
    ld_process_date DATE;                                                -- �Ɩ��������t
    lt_delete_days  fnd_profile_option_values.profile_option_value%TYPE; -- �󒍃N���[�Y�폜����
    lv_tkn1         VARCHAR2(4000);
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �Ɩ��������t�擾
    -- ===========================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (ld_process_date = NULL) THEN
      -- �Ɩ��������t�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                    ,iv_name        => cv_tkn_number_01 -- ���b�Z�[�W�R�[�h
                   );
      --
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    --fnd_file.put_line(
    --   which  => fnd_file.log
    --  ,buff   => cv_debug_msg1_1 || CHR(10) ||
    --             cv_debug_msg1_2 || TO_CHAR(ld_process_date, 'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||
    --             ''
    --);
    --
    -- ===========================
    -- ���̓p�����[�^�`�F�b�N
    -- ===========================
    IF (NVL(in_exe_div, 0) <> cn_exe_div_any_time
      AND NVL(in_exe_div, 0) <> cn_exe_div_regular)
    THEN
      -- ���̓p�����[�^�G���[
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                   ,iv_name        => cv_tkn_number_11 -- ���b�Z�[�W�R�[�h
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_09   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_param_name  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_tkn1            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_value       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cn_exe_div_any_time ||
                                         ',' ||
                                         cn_exe_div_regular -- �g�[�N���l2
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ���̓p�����[�^�����O�o��
    lv_work := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_14    -- ���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_param        -- �g�[�N���R�[�h1
                 ,iv_token_value1 => TO_CHAR(in_exe_div) -- �g�[�N���l1
               );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_work
    );
    --
    -- ��s�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => lv_work
    );
    --
    -- ��s�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => NULL
    );
    --
    -- ============================
    -- �v���t�@�C���I�v�V�����l�擾
    -- ============================
    lt_delete_days := fnd_profile.value(ct_prof_delete_days);
    --
    IF (lt_delete_days IS NULL) THEN
      -- �v���t�@�C���擾�G���[
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                   ,iv_name        => cv_tkn_number_12 -- ���b�Z�[�W�R�[�h
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_07 -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_profile   -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn1          -- �g�[�N���l1
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- *** DEBUG_LOG ***
    -- �v���t�@�C���I�v�V�����l�����O�o��
    --fnd_file.put_line(
    --   which  => fnd_file.log
    --  ,buff   => cv_debug_msg1_5 || CHR(10) ||
    --             cv_debug_msg1_6 || lt_delete_days || CHR(10) ||
    --             ''
    --);
    --
    od_process_date := ld_process_date;
    ot_delete_days  := lt_delete_days;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
--
--#####################################  �Œ蕔 END   ##########################################
--
  END start_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_order_close
   * Description      : �󒍃N���[�Y�Ώۏ��擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_order_close(
     it_sel_process_status IN         xxcos_order_close.process_status%TYPE -- �����X�e�[�^�X
    ,ov_errbuf             OUT NOCOPY VARCHAR2                              -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2                              -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2                              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_order_close';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lt_delete_days fnd_profile_option_values.profile_option_value%TYPE; -- �󒍃N���[�Y�폜����
    lv_tkn1        VARCHAR2(4000);
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �󒍃N���[�Y�Ώۏ��擾
    -- ===========================
    BEGIN
      SELECT xoc.order_line_id order_line_id -- �󒍖��ׂh�c
      BULK COLLECT INTO gt_order_line_id_tab
      FROM   xxcos_order_close xoc -- �󒍃N���[�Y�Ώۏ��e�[�u��
      WHERE  xoc.process_status = it_sel_process_status
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_13 -- ���b�Z�[�W�R�[�h
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02 -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_tkn1          -- �g�[�N���l1
                     );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        --
    END;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_wk_staus
   * Description      : ���[�N�t���[�X�e�[�^�X�X�V (A-3)
   ***********************************************************************************/
  PROCEDURE upd_wk_staus(
     it_order_line_id  IN         xxcos_order_close.order_line_id%TYPE  -- �󒍖��ׂh�c
    ,ot_process_status OUT        xxcos_order_close.process_status%TYPE -- �����X�e�[�^�X
    ,ov_errbuf         OUT NOCOPY VARCHAR2                              -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2                              -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2                              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_wk_staus';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_close_type CONSTANT VARCHAR2(5)                           := 'OEOL';
    cv_activity   CONSTANT VARCHAR2(27)                          := 'XXCOS_R_STANDARD_LINE:BLOCK';
    cv_result     CONSTANT VARCHAR2(1)                           := NULL;
    ct_status_end CONSTANT xxcos_order_close.process_status%TYPE := 'Y';
    ct_status_err CONSTANT xxcos_order_close.process_status%TYPE := 'E';
    --
    -- *** ���[�J���ϐ� ***
    lt_process_status xxcos_order_close.process_status%TYPE;
    lv_err_name       VARCHAR2(4000);
    lv_err_stack      VARCHAR2(4000);
    lv_tkn1           VARCHAR2(4000);
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ot_process_status := ct_status_end;
    --
    wf_engine.completeactivity(
       itemtype => cv_close_type
      ,itemkey  => it_order_line_id
      ,activity => cv_activity
      ,result   => cv_result
    );
    --
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.get_error(
         err_name    => lv_err_name
        ,err_message => lv_errmsg
        ,err_stack   => lv_err_stack
      );
      --
      -- �G���[���e���o��
      lv_tkn1 := xxccp_common_pkg.get_msg(
                    iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                   ,iv_name        => cv_tkn_number_15 -- ���b�Z�[�W�R�[�h
                 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_03 -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_api_name  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_tkn1          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg   -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_errmsg        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_line_id   -- �g�[�N���R�[�h3
                     ,iv_token_value3 => it_order_line_id -- �g�[�N���l3
                   );
      --
      fnd_file.put_line(
         which  => fnd_file.log
        ,buff   => lv_errmsg || CHR(10) ||
                   ''
      );
      --
      ov_errbuf         := lv_errmsg;
      ov_errmsg         := lv_errmsg;
      ot_process_status := ct_status_err;
      ov_retcode        := cv_status_warn;
      --
  END upd_wk_staus;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_close
   * Description      : �󒍃N���[�Y�Ώۏ��X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_order_close(
     id_process_date IN         DATE     -- �Ɩ����t
    ,ov_errbuf       OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_order_close';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_tkn1 VARCHAR2(4000);
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- �󒍃N���[�Y�Ώۏ��X�V
    -- ========================================
    BEGIN
      FORALL i IN  1.. gt_order_line_id_tab.COUNT
        UPDATE xxcos_order_close xoc -- �󒍃N���[�Y�Ώۏ��e�[�u��
        SET    xoc.process_status         = gt_process_status_tab(i)  -- �����X�e�[�^�X
              ,xoc.process_date           = id_process_date           -- ������
              ,xoc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
              ,xoc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
              ,xoc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,xoc.request_id             = cn_request_id             -- �v��ID
              ,xoc.program_application_id = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xoc.program_id             = cn_program_id             -- �R���J�����g�E�v���O����ID
              ,xoc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE  xoc.order_line_id = gt_order_line_id_tab(i)
        ;
        --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_13 -- ���b�Z�[�W�R�[�h
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table_name -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_tkn1           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => NULL              -- �g�[�N���R�[�h2
                     );
        --
        lv_errbuf  := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE global_api_others_expt;
        --
    END;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_order_close;
--
  /**********************************************************************************
   * Procedure Name   : del_order_close
   * Description      : �󒍃N���[�Y�Ώۏ��폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_order_close(
     id_process_date IN         DATE     -- �Ɩ��������t
    ,in_delete_days  IN         NUMBER   -- �폜����
    ,on_delete_count OUT        NUMBER   -- �폜����
    ,ov_errbuf       OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'del_order_close';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_process_status_end CONSTANT xxcos_order_close.process_status%TYPE := 'Y'; -- �����X�e�[�^�X=������
    --
    -- *** ���[�J���ϐ� ***
    ld_working_day  DATE;
    ln_delete_count NUMBER;
    lv_tkn1         VARCHAR2(4000);
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ========================================
    -- �폜�c�Ɠ��擾
    -- ========================================
    ld_working_day := xxccp_common_pkg2.get_working_day(
                         id_date          => id_process_date
                        ,in_working_day   => in_delete_days
                        ,iv_calendar_code => NULL
                      );
    --
    IF (ld_working_day IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_10   -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_basic_day   -- �g�[�N���R�[�h1
                    ,iv_token_value1 => id_process_date    -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_working_day -- �g�[�N���R�[�h2
                    ,iv_token_value2 => in_delete_days     -- �g�[�N���l2
                   );
      --
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ========================================
    -- �󒍃N���[�Y�Ώۏ��폜
    -- ========================================
    BEGIN
      DELETE xxcos_order_close xoc -- �󒍃N���[�Y�Ώۏ��e�[�u��
      WHERE  xoc.process_status       = ct_process_status_end
      AND    TRUNC(xoc.process_date) <= TRUNC(ld_working_day)
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn1 := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_13 -- ���b�Z�[�W�R�[�h
                   );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table_name -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_tkn1           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_key_data   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => id_process_date   -- �g�[�N���R�[�h2
                     );
        --
        lv_errbuf  := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE global_api_others_expt;
        --
    END;
    --
    -- ========================================
    -- �󒍃N���[�Y�Ώۏ��폜�����擾
    -- ========================================
    ln_delete_count := SQL%ROWCOUNT;
    --
    on_delete_count := ln_delete_count;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_order_close;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     in_exe_div IN         NUMBER   -- ���s�敪
    ,ov_errbuf  OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_exe_div_1  CONSTANT NUMBER                                := 1;   -- ���s�敪=�������s
    ct_exe_div_2  CONSTANT NUMBER                                := 2;   -- ���s�敪=������s
    ct_proc_sts_1 CONSTANT xxcos_order_close.process_status%TYPE := 'E'; -- �����X�e�[�^�X=�G���[
    ct_proc_sts_2 CONSTANT xxcos_order_close.process_status%TYPE := 'N'; -- �����X�e�[�^�X=������
    ct_proc_sts_3 CONSTANT xxcos_order_close.process_status%TYPE := 'Y'; -- �����X�e�[�^�X=������
    --
    -- *** ���[�J���ϐ� ***
    ld_process_date       DATE;                                                -- �Ɩ��������t
    lt_delete_days        fnd_profile_option_values.profile_option_value%TYPE; -- �󒍃N���[�Y�폜����
    lt_sel_process_status xxcos_order_close.process_status%TYPE;               -- �����X�e�[�^�X�i�����p�j
    lt_upd_process_status xxcos_order_close.process_status%TYPE;               -- �����X�e�[�^�X�i�X�V�p�j
    --
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
    upd_wk_status_warn EXCEPTION;
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
    gn_target_cnt := 0; -- �Ώی���
    gn_normal_cnt := 0; -- ���팏��
    gn_error_cnt  := 0; -- �G���[����
    gn_warn_cnt   := 0; -- �x������
    gn_delete_cnt := 0; -- �폜����
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    start_proc(
       in_exe_div      => in_exe_div      -- ���s�敪
      ,od_process_date => ld_process_date -- �Ɩ��������t
      ,ot_delete_days  => lt_delete_days  -- �󒍃N���[�Y�폜����
      ,ov_errbuf       => lv_errbuf       -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode      -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2.�󒍃N���[�Y�Ώۏ��擾
    -- ========================================
    IF (in_exe_div = ct_exe_div_1) THEN
      -- ���s�敪��1(�������s)�̏ꍇ
      lt_sel_process_status := ct_proc_sts_1;
      --
    ELSE
      -- ���s�敪��2(������s)�̏ꍇ
      lt_sel_process_status := ct_proc_sts_2;
      --
    END IF;
    --
    get_order_close(
       it_sel_process_status => lt_sel_process_status -- �����X�e�[�^�X
      ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    <<wf_upd_loop>>
    FOR i IN 1..gt_order_line_id_tab.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1;
      --
      -- ========================================
      -- A-3.���[�N�t���[�X�e�[�^�X�X�V
      -- ========================================
      upd_wk_staus(
         it_order_line_id  => gt_order_line_id_tab(i) -- �󒍖��ׂh�c
        ,ot_process_status => lt_upd_process_status   -- �����X�e�[�^�X
        ,ov_errbuf         => lv_errbuf               -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode        => lv_retcode              -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg         => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_normal) THEN
        gt_process_status_tab(i) := ct_proc_sts_3;
        gn_normal_cnt            := gn_normal_cnt + 1;
        --
      ELSIF (lv_retcode = cv_status_warn) THEN
        gt_process_status_tab(i) := ct_proc_sts_1;
        gn_warn_cnt              := gn_warn_cnt + 1;
        --
      END IF;
      --
    END LOOP wf_upd_loop;
    --
    -- ========================================
    -- A-4.�󒍃N���[�Y�Ώۏ��X�V
    -- ========================================
    upd_order_close(
       id_process_date => ld_process_date -- �Ɩ��������t
      ,ov_errbuf       => lv_errbuf       -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode      -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-5.�Z�[�u�|�C���g���s
    -- ========================================
    SAVEPOINT delete_order_close;
    --
    -- ========================================
    -- A-6.�󒍃N���[�Y�Ώۏ��폜
    -- ========================================
    del_order_close(
       id_process_date => ld_process_date           -- �Ɩ��������t
      ,in_delete_days  => TO_NUMBER(lt_delete_days) -- �󒍃N���[�Y�폜����
      ,on_delete_count => gn_delete_cnt             -- �󒍃N���[�Y�폜����
      ,ov_errbuf       => lv_errbuf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode                -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK TO SAVEPOINT delete_order_close;
      RAISE global_process_expt;
      --
    END IF;
    --
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    IF (gn_error_cnt > 0) THEN
      ov_retcode := cv_status_error;
      --
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode   := cv_status_error;
      --
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode   := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
      --
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf     OUT NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode    OUT NOCOPY VARCHAR2 -- ���^�[���E�R�[�h    --# �Œ� #
    ,in_exe_div IN         NUMBER   -- ���s�敪
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
       in_exe_div => in_exe_div -- ���s�敪
      ,ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-7.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_06
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt) -- ���o����
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt) -- ��������
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)  -- �G���[����
                    ,iv_token_name4  => cv_tkn_count4
                    ,iv_token_value4 => TO_CHAR(gn_warn_cnt)   -- �x������
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_08
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_delete_cnt) -- �폜����
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      --fnd_file.put_line(
      --   which  => FND_FILE.LOG
      --  ,buff   => cv_debug_msg_rollback || CHR(10) ||
      --             ''
      --);
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOS007A03C;
/
