CREATE OR REPLACE PACKAGE BODY xxcmm004a08c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A08C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�W�������f�[�^��
 *                  : OPM�W�������e�[�u���ɔ��f���܂��B
 * MD.050           : �W�������ꊇ����    MD050_CMM_004_A08
 * Version          : Draft2B
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              �������� (A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
 *  loop_main              �W�������ꊇ���胏�[�N�̎擾 (A-3)
 *                            �Evalidate_item
 *                            �Eproc_opm_cost_ref
 *  validate_item          �f�[�^�Ó����`�F�b�N (A-4)
 *  proc_opm_cost_ref      OPM�W���������f
 *                         �W����������Ώۃf�[�^�̒��o (A-5)
 *                         OPM�W���������f (A-6)
 *  proc_comp              �I������ (A-7)
 *
 *  submain                ���C�������v���V�[�W��
 *                            �Eproc_init  
 *                            �Eget_if_data
 *                            �Eloop_main
 *                            �Eproc_comp
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   H.Yoshikawa      �V�K�쐬
 *  2009/01/27    1.0   N.Nishimura      BLOB�f�[�^�ϊ����ʊ֐��̖߂�l�n���h�����O
 *                                       �K�p�����o�^�N�x�̃`�F�b�N
 *  2009/01/28    1.0   N.Nishimura      ���b�Z�[�W�A�g�[�N���ǉ�
 *                                       OPM�W�������}�X�^�ւ̃��b�N����
 *                                       �e�i�ڃ`�F�b�N��SELECT���ɕi�ڃX�e�[�^�X�ǉ�
 *                                       �t�@�C���A�b�v���[�h���̂̎擾 �f�[�^���o�G���[
 *  2009/01/29    1.0   N.Nishimura      IF���̊O�ɏo���i�f�[�^�Ó����`�F�b�N�̃X�e�[�^�X��ޔ��j
 *  2009/02/03    1.0   N.Nishimura      proc_init���ʊ֐��̗�O�������b�Z�[�W�ύX
 *  2009/02/03    1.1   N.Nishimura      �t�@�C�����d���`�F�b�N�C��
 *                                       OPM�W������ ���b�N�擾�G���[�C��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;    -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;      -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;     -- �ُ�:2
  --WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                    -- CREATED_BY
  cd_creation_date           CONSTANT DATE          := SYSDATE;                               -- CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                    -- LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE          := SYSDATE;                               -- LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                   -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;            -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;               -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;            -- PROGRAM_ID
  cd_program_update_date     CONSTANT DATE          := SYSDATE;                               -- PROGRAM_UPDATE_DATE
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                 VARCHAR2(2000);
  gv_sep_msg                 VARCHAR2(2000);
  gv_exec_user               VARCHAR2(100);
  gv_conc_name               VARCHAR2(30);
  gv_conc_status             VARCHAR2(30);
  gn_target_cnt              NUMBER;                -- �Ώی���
  gn_normal_cnt              NUMBER;                -- ���팏��
  gn_error_cnt               NUMBER;                -- �G���[����
  gn_warn_cnt                NUMBER;                -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���ʊ֐���O ***
  global_api_expt            EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
  --*** ���b�N�G���[��O ***
  global_check_lock_expt     EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  �Œ蕔 END   ##################################
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_appl_name_xxcmm         CONSTANT VARCHAR2(10)  := 'XXCMM';              -- �A�h�I���F���ʁE�}�X�^
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCMM004A08C';       -- �p�b�P�[�W��
  cv_msg_comma               CONSTANT VARCHAR2(3)   := ',';                  -- �J���}
  --
  cv_yes                     CONSTANT VARCHAR2(1)   := 'Y';                  -- Y
  cv_no                      CONSTANT VARCHAR2(1)   := 'N';                  -- N
  --
  cv_upd_div_upd             CONSTANT VARCHAR2(1)   := 'U';                  -- �X�V�敪(U)
  --
  -- �W������
  cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                             -- �q��
  cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                             -- �������@
  cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                             -- ���̓R�[�h
  --2009/02/03�ǉ�
  cv_date_fmt_std            CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                             -- ���t����
  --
  --=========================================================================================================================================
  -- ���b�Z�[�W�R�[�h�i�R���J�����g���s���j
  cv_msg_xxcmm_00021         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';   -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';   -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';   -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';   -- �t�H�[�}�b�g�p�^�[���m�[�g
  --
  -- �g�[�N���R�[�h
  cv_tkn_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';            -- �t�@�C��ID
  cv_tkn_format              CONSTANT VARCHAR2(20)  := 'FORMAT';             -- �t�H�[�}�b�g
  cv_tkn_file_name           CONSTANT VARCHAR2(20)  := 'FILE_NAME';          -- �t�@�C����
  cv_tkn_up_name             CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';        -- �t�@�C���A�b�v���[�h����
  --=========================================================================================================================================
  --
  --�G���[���b�Z�[�W�R�[�h
  cv_msg_xxcmm_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00008         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';   -- ���b�N�擾�G���[
  cv_msg_xxcmm_00028         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';   -- �f�[�^���ڐ��G���[
  cv_msg_xxcmm_00440         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- �p�����[�^�`�F�b�N�G���[
  cv_msg_xxcmm_00455         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00455';   -- �N����ʃG���[
  cv_msg_xxcmm_00456         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00456';   -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00457         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00457';   -- �K�p���`�F�b�N�G���[
  cv_msg_xxcmm_00458         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00458';   -- �e�i�ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00459         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00459';   -- �}�X�^�`�F�b�N�G���[
  cv_msg_xxcmm_00460         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00460';   -- �W�������`�F�b�N�G���[
  cv_msg_xxcmm_00463         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00463';   -- �t�@�C�����d���G���[
  cv_msg_xxcmm_00464         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00464';   -- �d���G���[
  cv_msg_xxcmm_00466         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00466';   -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_00467         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00467';   -- �f�[�^�X�V�G���[
  cv_msg_xxcmm_00468         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00468';   -- �f�[�^�폜�G���[
  cv_msg_xxcmm_00469         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00469';   -- �W���������f�G���[
  --2009/01/28�ǉ�
  cv_msg_xxcmm_00482         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00482';   -- �K�p�����o�^�N�x�G���[
  cv_msg_xxcmm_00483         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00483';   -- �i�ڃX�e�[�^�X�ΏۊO�G���[
  cv_msg_xxcmm_00409         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';   -- �f�[�^���o�G���[
  --
  --�x�����b�Z�[�W�R�[�h
  cv_msg_xxcmm_00462         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00462';   -- �W��������r�x��
  --
  --�g�[�N���R�[�h
  cv_tkn_table               CONSTANT VARCHAR2(20)  := 'TABLE';              -- �e�[�u����
  cv_tkn_ng_table            CONSTANT VARCHAR2(20)  := 'NG_TABLE';           -- ���b�N�擾�G���[�e�[�u����
  cv_tkn_count               CONSTANT VARCHAR2(20)  := 'COUNT';              -- ���ڐ��`�F�b�N����
  cv_tkn_profile             CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- �v���t�@�C����
  cv_tkn_param_name          CONSTANT VARCHAR2(20)  := 'PARAM_NAME';         -- �p�����[�^��
  cv_tkn_input_col_name      CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';     -- ���ږ���
  cv_tkn_cost_type           CONSTANT VARCHAR2(20)  := 'COST_TYPE ';         -- �����^�C�v
  cv_tkn_input_cost          CONSTANT VARCHAR2(20)  := 'INPUT_COST';         -- ���͌���(�W������)
  cv_tkn_disc_cost           CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- �c�ƌ���
  cv_tkn_opm_cost            CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- �W������
  cv_tkn_input_item          CONSTANT VARCHAR2(20)  := 'INPUT_ITEM';         -- �i�ڃR�[�h
  cv_tkn_input_apply_date    CONSTANT VARCHAR2(20)  := 'INPUT_APPLY_DATE';   -- �K�p��
  cv_tkn_err_msg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
  --
  cv_tkn_val_proc_name       CONSTANT VARCHAR2(30)  := '�W�������ꊇ����';
  cv_tkn_val_fmt_pattern     CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';
  cv_tkn_val_opm_cost        CONSTANT VARCHAR2(30)  := '�W������';
  cv_tkn_val_file_ul_if      CONSTANT VARCHAR2(30)  := '�t�@�C���A�b�v���[�h�h�^�e';
  cv_tkn_val_wk_opm_cost     CONSTANT VARCHAR2(30)  := '�W�������ꊇ���胏�[�N';
  cv_tkn_val_cmpnt_cost      CONSTANT VARCHAR2(100) := '�W�������i�����A�Đ���A���ޔ�A���A�O���Ǘ���A�ۊǔ�A���̑��o��j';
  --
  cv_tkn_cm_cmpt_dtl         CONSTANT VARCHAR2(30)  := '�n�o�l�W�������}�X�^';
  cv_lookup_cost_cmpt        CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- �W�������R���|�[�l���g
  --2009/01/28�ǉ�
  cv_tkn_errmsg              CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- �G���[���e
  cv_tkn_input_line_no       CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';      -- �C���^�t�F�[�X�̍s�ԍ�
  cv_tkn_input_item_code     CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';    -- �C���^�t�F�[�X�̕i���R�[�h
  cv_table_flv               CONSTANT VARCHAR2(30)  := 'LOOKUP�\';           -- FND_LOOKUP_VALUES_VL
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_def_info_rtype IS RECORD(
    meaning                  VARCHAR2(100)                                   -- ���ږ�
   ,attribute                VARCHAR2(100)                                   -- ���ڑ���
   ,essential                VARCHAR2(100)                                   -- �K�{�t���O
   ,figures                  NUMBER                                          -- ���ڂ̒���(����)
   ,decim                    NUMBER                                          -- ���ڂ̒���(����)
  );
  --
  TYPE g_opm_cost_rtype IS RECORD(
    item_id                  ic_item_mst_b.item_id%TYPE                      -- �i��ID
   ,item_no                  ic_item_mst_b.item_no%TYPE                      -- �i�ڃR�[�h
   ,apply_date               xxcmm_system_items_b_hst.apply_date%TYPE        -- �K�p��
   ,cmpntcost_01gen          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- ����
   ,cmpntcost_02sai          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- �Đ���
   ,cmpntcost_03szi          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- ���ޔ�
   ,cmpntcost_04hou          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- ���
   ,cmpntcost_05gai          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- �O���Ǘ���
   ,cmpntcost_06hkn          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- �ۊǔ�
   ,cmpntcost_07kei          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- ���̑��o��
   ,cmpntcost_total          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- �W�������v
  );
  --
  TYPE g_def_info_ttype   IS TABLE OF g_def_info_rtype INDEX BY BINARY_INTEGER;
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(1000)   INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�e�[�u���^�ϐ��̐錾
  g_def_info_tab             g_def_info_ttype;                               -- �e�[�u���^�ϐ��̐錾
  gn_file_id                 NUMBER;                                         -- �p�����[�^�i�[�p�ϐ�
  gn_item_num                NUMBER;                                         -- �N�Ԍv��f�[�^���ڐ��i�[�p
  gv_format                  VARCHAR2(100);                                  -- �p�����[�^�i�[�p�ϐ�
  gd_process_date            DATE;                                           -- �Ɩ����t
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������ (A-7)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_COMP';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    --
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    IF ( gn_error_cnt > 0 ) THEN
      --==============================================================
      --A-7.1 �`�F�b�N�G���[���ݎ�(SAVEPOINT �܂� ROLLBACK)
      --==============================================================
      lv_step := 'A-7.1';
      -- SAVEPOINT�܂� ROLLBACK
      ROLLBACK TO XXCMM004A08C_savepoint;
      --
    ELSE
      --==============================================================
      --A-7.2 �W�������ꊇ����f�[�^�폜
      --==============================================================
      BEGIN
        lv_step := 'A-7.2';
        DELETE  FROM    xxcmm_wk_opmcost_batch_regist;
        --
      EXCEPTION
        -- *** �f�[�^�폜��O�n���h�� ***
        WHEN OTHERS THEN
          --
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxcmm_00468          -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_table                -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  cv_tkn_val_wk_opm_cost      -- �g�[�N���l1
                         ,iv_token_name2   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h2
                         ,iv_token_value2  =>  SQLERRM                     -- �g�[�N���l2
                        );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          ov_retcode := cv_status_error;
      END;
      --
    END IF;
    --
    --==============================================================
    --A-7.3 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-7.3';
      DELETE  FROM    xxccp_mrp_file_ul_interface
      WHERE   file_id = gn_file_id;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxcmm_00468            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_tkn_val_file_ul_if         -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_err_msg                -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  SQLERRM                       -- �g�[�N���l2
                      );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        ov_retcode := cv_status_error;
    END;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_comp;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_opm_cost_ref
   * Description      : OPM�W���������f (A-5�AA-6)
   ***********************************************************************************/
  PROCEDURE proc_opm_cost_ref(
    i_opm_cost_rec    IN       g_opm_cost_rtype                                -- �W����������f�[�^
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_OPM_COST_REF';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �i�ڃX�e�[�^�X
    cn_itm_status_num_tmp      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                           -- ���̔�
    cn_itm_status_pre_reg      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;
                                                                           -- ���o�^
    cn_itm_status_regist       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;
                                                                           -- �{�o�^
    cn_itm_status_no_sch       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;
                                                                           -- �p
    cn_itm_status_trn_only     CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;
                                                                           -- �c�f
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                           -- �c
    --
    -- �R���|�[�l���g�敪
    cv_cost_cmpnt_01gen        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;
                                                                           -- ����
    cv_cost_cmpnt_02sai        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;
                                                                           -- �Đ���
    cv_cost_cmpnt_03szi        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;
                                                                           -- ���ޔ�
    cv_cost_cmpnt_04hou        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;
                                                                           -- ���
    cv_cost_cmpnt_05gai        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;
                                                                           -- �O���Ǘ���
    cv_cost_cmpnt_06hkn        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;
                                                                           -- �ۊǔ�
    cv_cost_cmpnt_07kei        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;
                                                                           -- ���̑��o��
    --
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    --
    ln_cmp_cost_index          NUMBER;
    ln_cmpnt_cost              cm_cmpt_dtl.cmpnt_cost%TYPE;
    --
    -- *** �J�[�\�� ***
    -- �W����������Ώۃf�[�^�擾�J�[�\��
    CURSOR opmcost_item_cur(
      p_item_id    NUMBER )
    IS
      -- �e�i�ڒ��o
      SELECT    xoiv.item_id
      FROM      xxcmm_opmmtl_items_v      xoiv                             -- �i�ڃr���[
      WHERE     xoiv.item_id            = p_item_id                        -- �i��ID
      AND       xoiv.parent_item_id     = xoiv.item_id                     -- �e�i�ڂł��邱��
      AND       xoiv.start_date_active <= TRUNC( SYSDATE )                 -- �K�p�J�n��
      AND       xoiv.end_date_active   >= TRUNC( SYSDATE )                 -- �K�p�I����
-- 2009/01/16 Mod
      AND       NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                       != cn_itm_status_no_use             -- �c�ȊO
--      AND       xoiv.item_status       IN ( cn_itm_status_num_tmp          -- ���̔�
--                                           ,cn_itm_status_pre_reg          -- ���o�^
--                                           ,cn_itm_status_regist           -- �{�o�^
--                                           ,cn_itm_status_no_sch           -- �p
--                                           ,cn_itm_status_trn_only )       -- �c�f
-- End
      UNION ALL
      -- �q�i�ڒ��o
      SELECT    xoiv.item_id
      FROM      xxcmm_opmmtl_items_v      xoiv                             -- �i�ڃr���[
      WHERE     xoiv.parent_item_id     = p_item_id                        -- �e�i��ID
      AND       xoiv.item_id           != xoiv.parent_item_id              -- �e�i�ڂłȂ�����
      AND       xoiv.start_date_active <= TRUNC( SYSDATE )                 -- �K�p�J�n��
      AND       xoiv.end_date_active   >= TRUNC( SYSDATE )                 -- �K�p�I����
      AND       xoiv.item_status       IN ( cn_itm_status_regist           -- �{�o�^
                                           ,cn_itm_status_no_sch           -- �p
                                           ,cn_itm_status_trn_only );      -- �c�f
    --
    -- �W�������R���|�[�l���g�擾�J�[�\��
    CURSOR opmcost_cmpnt_cur(
      p_item_id     NUMBER
     ,p_apply_date  DATE )
    IS
      SELECT    ccmd.cmpntcost_id                                          -- �W������ID
               ,cmcr.calendar_code                                         -- �J�����_�R�[�h
               ,cmcr.period_code                                           -- ���ԃR�[�h
               ,cmcr.cost_cmpntcls_id                                      -- �����R���|�[�l���gID
               ,cmcr.cost_cmpntcls_code                                    -- �����R���|�[�l���g�R�[�h
      FROM      cm_cmpt_dtl          ccmd,                                 -- OPM�W������
              ( SELECT    cclr.calendar_code                               -- �J�����_�R�[�h
                         ,cclr.period_code                                 -- ���ԃR�[�h
                         ,ccmv.cost_cmpntcls_id                            -- �����R���|�[�l���gID
                         ,ccmv.cost_cmpntcls_code                          -- �����R���|�[�l���g�R�[�h
                FROM      cm_cldr_dtl          cclr,                       -- OPM�����J�����_
                          cm_cmpt_mst_vl       ccmv,                       -- �����R���|�[�l���g
                          fnd_lookup_values_vl flv                         -- �Q�ƃR�[�h�l
                WHERE     flv.lookup_type          = cv_lookup_cost_cmpt   -- �Q�ƃ^�C�v
                AND       flv.enabled_flag         = cv_yes                -- �g�p�\
                AND       ccmv.cost_cmpntcls_code  = flv.meaning           -- �����R���|�[�l���g�R�[�h
                AND       cclr.start_date         <= p_apply_date          -- �J�n��
                AND       cclr.end_date           >= p_apply_date )  cmcr  -- �I����
      WHERE     ccmd.item_id(+)            = p_item_id                     -- �i��
      AND       ccmd.cost_cmpntcls_id(+)   = cmcr.cost_cmpntcls_id         -- �����R���|�[�l���gID
      AND       ccmd.calendar_code(+)      = cmcr.calendar_code            -- �J�����_�R�[�h
      AND       ccmd.period_code(+)        = cmcr.period_code              -- ���ԃR�[�h
      AND       ccmd.whse_code(+)          = cv_whse_code                  -- �q��
      AND       ccmd.cost_mthd_code(+)     = cv_cost_mthd_code             -- �������@
      AND       ccmd.cost_analysis_code(+) = cv_cost_analysis_code         -- ���̓R�[�h
      ORDER BY  cmcr.cost_cmpntcls_code
      FOR UPDATE OF ccmd.cmpntcost_id NOWAIT;                              -- ���b�N�����ǉ� 2009/01/28
    --
    -- OPM�W�������p
    l_opm_cost_header_rec           xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab             xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
    --2009/02/04 �ǉ�
    proc_opmcost_ref_expt  EXCEPTION;
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
    --A-5 �i�ڕύX�����A�h�I���o�^�E�X�V����
    --==============================================================
    -- OPM�W���������f����LOOP
    <<opmcost_loop>>
    FOR l_opmcost_item_rec IN opmcost_item_cur( i_opm_cost_rec.item_id ) LOOP
    --==============================================================
    --A-6 OPM�W���������f
    --==============================================================
      --==============================================================
      --A-6.1 �W�������o�^�Ώۏ��̎擾
      --==============================================================
      ln_cmp_cost_index := 0;
      <<cmpnt_loop>>
      FOR l_opmcost_cmpnt_rec IN opmcost_cmpnt_cur( l_opmcost_item_rec.item_id
                                                   ,i_opm_cost_rec.apply_date ) LOOP
        --
        -- �����̎擾
        CASE l_opmcost_cmpnt_rec.cost_cmpntcls_code 
          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
            -- ����
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_01gen;
          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
            -- �Đ���
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_02sai;
          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
            -- ���ޔ�
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_03szi;
          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
            -- ���
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_04hou;
          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
            -- �O���Ǘ���
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_05gai;
          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
            -- �ۊǔ�
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_06hkn;
          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
            -- ���̑��o��
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_07kei;
        END CASE;
        --
        -- �����ݒ蔻�f
        IF ( ln_cmpnt_cost IS NOT NULL ) THEN
          --
          -- OPM�W�������w�b�_�p�����[�^�ݒ�
          IF ( ln_cmp_cost_index = 0 ) THEN
            -- �J�����_�R�[�h
            l_opm_cost_header_rec.calendar_code     := l_opmcost_cmpnt_rec.calendar_code;
            -- ���ԃR�[�h
            l_opm_cost_header_rec.period_code       := l_opmcost_cmpnt_rec.period_code;
            -- �i��ID
            l_opm_cost_header_rec.item_id           := l_opmcost_item_rec.item_id;
          END IF;
          --
          -- �����o�^�E�X�V���f
          IF ( l_opmcost_cmpnt_rec.cmpntcost_id IS NULL ) THEN 
            --==============================================================
            --A-6.2 �W�������o�^��
            --==============================================================
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            -- ��������
            -- �W������ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := NULL;
            -- �����R���|�[�l���gID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_opmcost_cmpnt_rec.cost_cmpntcls_id;
            -- ����
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := ln_cmpnt_cost;
            --
          ELSE
            --==============================================================
            --A-6.3 �W�������X�V��
            --==============================================================
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            -- ��������
            -- �W������ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_opmcost_cmpnt_rec.cmpntcost_id;
            -- �����R���|�[�l���gID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_opmcost_cmpnt_rec.cost_cmpntcls_id;
            -- ����
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := ln_cmpnt_cost;
            --
          END IF;
          --
        END IF;
        --
      END LOOP cmpnt_loop;
      --
      --==============================================================
      --A-6.4 �W���������fAPI
      --==============================================================
      -- �W�������o�^
      xxcmm_004common_pkg.proc_opmcost_ref(
        i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
       ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
       ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W
       ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h
       ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_opmcost_ref_expt;
      END IF;
      --
    END LOOP opmcost_loop;
    --
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00008    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_ng_table       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_cm_cmpt_dtl    -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      --
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
      --
    -- *** �W���������fAPI�G���[��O�n���h�� *** 2009/02/04�ǉ�
    WHEN proc_opmcost_ref_expt THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_00469                        -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   =>  cv_tkn_input_item                         -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  i_opm_cost_rec.item_no                    -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_input_apply_date                   -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  i_opm_cost_rec.apply_date                 -- �g�[�N���l2
                      ,iv_token_name3   =>  cv_tkn_err_msg                            -- �g�[�N���R�[�h3
                      ,iv_token_value3  =>  lv_errmsg                                 -- �g�[�N���l3
                     );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
    --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_opm_cost_ref;
--
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_opm_cost_rec    IN       xxcmm_wk_opmcost_batch_regist%ROWTYPE           -- �ϊ��O�W����������f�[�^
   ,o_opm_cost_rec    OUT      g_opm_cost_rtype                                -- �ϊ���W����������f�[�^
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'VALIDATE_ITEM';      -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �i�ڃX�e�[�^�X
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                           -- �c
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);
    ln_column_cnt              NUMBER;
    --
    ln_exists_cnt              NUMBER;
    lv_item_no                 ic_item_mst_b.item_no%TYPE;
    ln_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE;
    ln_disc_cost               NUMBER;
    --2009/01/27�ǉ�
    ln_cldr_code_cnt           NUMBER;
    ln_item_status             xxcmm_system_items_b.item_status%TYPE;
    --
    l_validate_disc_cost_tab   g_check_data_ttype;
    l_opm_cost_rec             g_opm_cost_rtype;
    --
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    lv_step := 'A-4.0';
    lv_warnig_flg                  := cv_status_normal;
    --
    -- �i��ID
    l_validate_disc_cost_tab( 1 )  := i_opm_cost_rec.item_id;
    -- �i�ڃR�[�h
    l_validate_disc_cost_tab( 2 )  := i_opm_cost_rec.item_no;
    -- �K�p��
    l_validate_disc_cost_tab( 3 )  := i_opm_cost_rec.apply_date;
    -- ����
    l_validate_disc_cost_tab( 4 )  := i_opm_cost_rec.cmpntcost_01gen;
    -- �Đ���
    l_validate_disc_cost_tab( 5 )  := i_opm_cost_rec.cmpntcost_02sai;
    -- ���ޔ�
    l_validate_disc_cost_tab( 6 )  := i_opm_cost_rec.cmpntcost_03szi;
    -- ���
    l_validate_disc_cost_tab( 7 )  := i_opm_cost_rec.cmpntcost_04hou;
    -- �O���Ǘ���
    l_validate_disc_cost_tab( 8 )  := i_opm_cost_rec.cmpntcost_05gai;
    -- �ۊǔ�
    l_validate_disc_cost_tab( 9 )  := i_opm_cost_rec.cmpntcost_06hkn;
    -- ���̑��o��
    l_validate_disc_cost_tab( 10 ) := i_opm_cost_rec.cmpntcost_07kei;
    --
    --==============================================================
    --A-4.1 �K�{�E�^�E�T�C�Y�`�F�b�N
    --==============================================================
    <<validate_column_loop>>
    FOR ln_column_cnt IN 1..4 LOOP
      --
      -- ���ڃ`�F�b�N
      lv_step := 'A-4.1';
      xxccp_common_pkg2.upload_item_check(
        iv_item_name     =>  g_def_info_tab( ln_column_cnt ).meaning                   -- ���ږ���
       ,iv_item_value    =>  l_validate_disc_cost_tab( ln_column_cnt )                 -- ���ڂ̒l
       ,in_item_len      =>  g_def_info_tab( ln_column_cnt ).figures                   -- ���ڂ̒���(��������)
       ,in_item_decimal  =>  g_def_info_tab( ln_column_cnt ).decim                     -- ���ڂ̒���(�����_�ȉ�)
       ,iv_item_nullflg  =>  g_def_info_tab( ln_column_cnt ).essential                 -- �K�{�t���O
       ,iv_item_attr     =>  g_def_info_tab( ln_column_cnt ).attribute                 -- ���ڂ̑���
       ,ov_errbuf        =>  lv_errbuf 
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg 
      );
      --
      -- �߂�l���ُ�̏ꍇ
      IF ( lv_retcode != cv_status_normal ) THEN    -- cv_status_error����cv_status_normal�ɕύX 2009/01/27
        -- �t�@�C�����ڃ`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00456                        -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_col_name                     -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  g_def_info_tab( ln_column_cnt ).meaning   -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_item                         -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_opm_cost_rec.item_no                    -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_opm_cost_rec.apply_date                 -- �g�[�N���l3
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �X�e�[�^�X���G���[�ɂ���B
        lv_warnig_flg := cv_status_error;
      END IF;
    END LOOP validate_column_loop;
    --
    --==============================================================
    --A-4.2 �W�������̕K�{�`�F�b�N
    --==============================================================
    lv_step := 'A-4.2';
    IF (  i_opm_cost_rec.cmpntcost_01gen IS NULL
      AND i_opm_cost_rec.cmpntcost_02sai IS NULL
      AND i_opm_cost_rec.cmpntcost_03szi IS NULL
      AND i_opm_cost_rec.cmpntcost_04hou IS NULL
      AND i_opm_cost_rec.cmpntcost_05gai IS NULL
      AND i_opm_cost_rec.cmpntcost_06hkn IS NULL
      AND i_opm_cost_rec.cmpntcost_07kei IS NULL ) THEN
      -- 
      -- �t�@�C�����ڃ`�F�b�N�G���[
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_00456                        -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   =>  cv_tkn_input_col_name                     -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  cv_tkn_val_cmpnt_cost                     -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_input_item                         -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  i_opm_cost_rec.item_no                    -- �g�[�N���l2
                      ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- �g�[�N���R�[�h3
                      ,iv_token_value3  =>  i_opm_cost_rec.apply_date                 -- �g�[�N���l3
                     );
      -- ���b�Z�[�W�o��
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      --
      -- �X�e�[�^�X���G���[�ɂ���B
      lv_warnig_flg := cv_status_error;
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- �e���ڂɊi�[
      l_opm_cost_rec.item_id         := TO_NUMBER( i_opm_cost_rec.item_id );
      l_opm_cost_rec.apply_date      := fnd_date.canonical_to_date( i_opm_cost_rec.apply_date );
      l_opm_cost_rec.cmpntcost_01gen := TO_NUMBER( i_opm_cost_rec.cmpntcost_01gen );
      l_opm_cost_rec.cmpntcost_02sai := TO_NUMBER( i_opm_cost_rec.cmpntcost_02sai );
      l_opm_cost_rec.cmpntcost_03szi := TO_NUMBER( i_opm_cost_rec.cmpntcost_03szi );
      l_opm_cost_rec.cmpntcost_04hou := TO_NUMBER( i_opm_cost_rec.cmpntcost_04hou );
      l_opm_cost_rec.cmpntcost_05gai := TO_NUMBER( i_opm_cost_rec.cmpntcost_05gai );
      l_opm_cost_rec.cmpntcost_06hkn := TO_NUMBER( i_opm_cost_rec.cmpntcost_06hkn );
      l_opm_cost_rec.cmpntcost_07kei := TO_NUMBER( i_opm_cost_rec.cmpntcost_07kei );
      l_opm_cost_rec.cmpntcost_total := NVL( l_opm_cost_rec.cmpntcost_01gen, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_02sai, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_03szi, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_04hou, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_05gai, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_06hkn, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_07kei, 0 );
      --
      --==============================================================
      --A-4.3 �e�i�ڃ`�F�b�N
      --==============================================================
      -- ���e�i�ڂł��A�i�ڃX�e�[�^�X���c�̏ꍇ�ΏۊO�ł���ׂ�����
      lv_step := 'A-4.3';
      --
      BEGIN
        --
        SELECT    xoiv.item_no                                         -- �i�ڃR�[�h
                 ,TO_NUMBER( NVL( xoiv.opt_cost_new, '0' ) )
                                                            disc_cost  -- �c�ƌ���
                 ,xoiv.item_status                                     -- �i�ڃX�e�[�^�X 2009/01/28�ǉ�
        INTO      lv_item_no
                 ,ln_disc_cost
                 ,ln_item_status                                       -- �i�ڃX�e�[�^�X 2009/01/28�ǉ�
        FROM      xxcmm_opmmtl_items_v       xoiv                      -- �i�ڃr���[
        WHERE     xoiv.item_id             = l_opm_cost_rec.item_id    -- �i��ID
        AND       xoiv.item_id             = xoiv.parent_item_id       -- �e�i��
        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )          -- �K�p�J�n��
        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );         -- �K�p�I����
        --
        l_opm_cost_rec.item_no       := lv_item_no;
        --
        -- �i�ڃX�e�[�^�X��'D'�̂��͍̂X�V���Ȃ�
        IF ( ln_item_status = cn_itm_status_no_use ) THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_00483          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_input_item           -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- �g�[�N���l1
                         );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          -- �X�e�[�^�X���G���[�ɂ���B
          lv_warnig_flg := cv_status_error;
          --
        END IF;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- �e�i�ڃ`�F�b�N�G���[
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_00458          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_input_item           -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- �g�[�N���l1
                         );
          -- ���b�Z�[�W�o��
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          -- �X�e�[�^�X���G���[�ɂ���B
          lv_warnig_flg := cv_status_error;
      END;
      --
      --==============================================================
      --A-4.4 �K�p���`�F�b�N
      --==============================================================
      -- ���J�����_���ݒ肳��Ă��Ȃ��K�p���w�莞�̓G���[��ǉ�����K�v����
      -- �����J�����_�ɓo�^����Ă��Ȃ��N�x���K�p���Ɏw�肳��Ă����ꍇ�A�G���[�Ƃ��� 2009/01/27�ǉ�
      --
      SELECT    COUNT( ccd.calendar_code )
      INTO      ln_cldr_code_cnt
      FROM      cm_cldr_dtl ccd
      WHERE     TRUNC( ccd.start_date ) <= l_opm_cost_rec.apply_date
      AND       TRUNC( ccd.end_date   ) >= l_opm_cost_rec.apply_date
      AND       ROWNUM = 1;
      --
      -- �K�p�����o�^�N�x�G���[
      IF ( ln_cldr_code_cnt = 0 ) THEN
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00482          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_item           -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date     -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_opm_cost_rec.apply_date   -- �g�[�N���l2
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �X�e�[�^�X���G���[�ɂ���B
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      -- �������̂ݎw��\
      lv_step := 'A-4.4';
      IF ( l_opm_cost_rec.apply_date <= gd_process_date ) THEN
        -- �}�X�^�`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00457            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_item             -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_opm_cost_rec.item_no        -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_opm_cost_rec.apply_date     -- �g�[�N���l2
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �X�e�[�^�X���G���[�ɂ���B
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.5 �t�@�C�����d���`�F�b�N
      --==============================================================
      lv_step := 'A-4.5';
      SELECT    COUNT( xwobr.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_wk_opmcost_batch_regist    xwobr               -- �W�������ꊇ���胏�[�N
               ,cm_cldr_dtl                      ccd1                -- OPM�����J�����_�i�Ώەi�ځj
               ,cm_cldr_dtl                      ccd2                -- OPM�����J�����_�i�d���`�F�b�N�i�ځj
      WHERE     xwobr.file_id         = gn_file_id                   -- �t�@�C��ID
      AND       xwobr.update_div      = cv_upd_div_upd               -- �X�V�敪
      --�󔒍폜 2009/02/03
      AND       TRIM( xwobr.item_id ) = i_opm_cost_rec.item_id       -- �i��ID
      --���t�^�ϊ��ǉ� 2009/02/03
      AND       ccd2.start_date      <= TO_DATE( xwobr.apply_date, cv_date_fmt_std)
                                                                     -- �J�n��(�d���`�F�b�N�i��)
      AND       ccd2.end_date        >= TO_DATE( xwobr.apply_date, cv_date_fmt_std)
                                                                     -- �I����(�d���`�F�b�N�i��)
      AND       xwobr.file_seq       != i_opm_cost_rec.file_seq      -- �t�@�C���V�[�P���X
      AND       ccd1.start_date      <= TO_DATE( i_opm_cost_rec.apply_date, cv_date_fmt_std)
                                                                     -- �J�n��(�Ώەi��)
      AND       ccd1.end_date        >= TO_DATE( i_opm_cost_rec.apply_date, cv_date_fmt_std)
                                                                     -- �I����(�Ώەi��)
      AND       ccd1.calendar_code    = ccd2.calendar_code           -- �J�����_�R�[�h
      AND       ccd1.period_code      = ccd2.period_code             -- ���ԃR�[�h
      AND       ROWNUM           = 1;
      
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- �t�@�C�����d���G���[  �g�[�N���ǉ� 2009/02/03
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00463            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_cost_type              -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  cv_tkn_val_opm_cost           -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_item             -- �g�[�N���R�[�h1
                        ,iv_token_value2  =>  i_opm_cost_rec.item_no        -- �g�[�N���l1
                        ,iv_token_name3   =>  cv_tkn_input_apply_date       -- �g�[�N���R�[�h2
                        ,iv_token_value3  =>  i_opm_cost_rec.apply_date     -- �g�[�N���l2
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �X�e�[�^�X���G���[�ɂ���B
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.6 �W�������`�F�b�N
      -- ���ڃ��x���ŏ����_�ȉ��`�F�b�N������̂ŕs�v�����B
      --==============================================================
      lv_step := 'A-4.6';
      IF ( l_opm_cost_rec.cmpntcost_total < 0 )
      OR ( l_opm_cost_rec.cmpntcost_total <> TRUNC( l_opm_cost_rec.cmpntcost_total ) ) THEN
        -- �W�������`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00460              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_cost_type                -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  cv_tkn_val_opm_cost             -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_cost               -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  l_opm_cost_rec.cmpntcost_total  -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_opm_cost_rec.item_no          -- �g�[�N���l3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- �g�[�N���R�[�h4
                        ,iv_token_value4  =>  i_opm_cost_rec.apply_date       -- �g�[�N���l4
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �X�e�[�^�X���G���[�ɂ���B
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.7 �W�������Ɖc�ƌ����̔�r
      --==============================================================
      lv_step := 'A-4.7';
      --
      IF ( l_opm_cost_rec.cmpntcost_total > ln_disc_cost ) THEN
        -- �W��������r�x��
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00462              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_opm_cost                 -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  TO_CHAR( l_opm_cost_rec.cmpntcost_total )
                                                                              -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_disc_cost                -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  TO_CHAR( ln_disc_cost )         -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_opm_cost_rec.item_no          -- �g�[�N���l3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- �g�[�N���R�[�h4
                        ,iv_token_value4  =>  i_opm_cost_rec.apply_date       -- �g�[�N���l4
                       );
        -- ���b�Z�[�W�o��
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ���펞�̓X�e�[�^�X���x���ɂ���B�i�ُ펞�͕ύX���Ȃ��j
        IF ( lv_warnig_flg = cv_status_normal ) THEN
          lv_warnig_flg := cv_status_warn;
        END IF;
      END IF;
      --
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- �^�ϊ����{��OUT�ϐ��Ɋi�[
      o_opm_cost_rec := l_opm_cost_rec;
    ELSIF ( lv_warnig_flg = cv_status_warn ) THEN
      -- �^�ϊ����{��OUT�ϐ��Ɋi�[
      o_opm_cost_rec := l_opm_cost_rec;
      -- �I���X�e�[�^�X�Ɍx����ݒ�
      ov_retcode      := cv_status_warn;
    ELSE
      -- �I���X�e�[�^�X�ɃG���[��ݒ�
      ov_retcode      := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �W�������ꊇ���胏�[�N�̎擾 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'LOOP_MAIN';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);                                    -- �ޔ�p���^�[���E�R�[�h
    --
    -- *** �J�[�\�� ***
    -- �W�������ꊇ����f�[�^�擾�J�[�\��
    CURSOR get_data_cur
    IS
      SELECT    xwobr.file_id                                   -- �t�@�C��ID
               ,xwobr.file_seq                                  -- �t�@�C���V�[�P���X
               ,TRIM( xwobr.item_id )          item_id          -- �i��ID
               ,TRIM( xwobr.item_no )          item_no          -- �i�ڃR�[�h
               ,TRIM( xwobr.apply_date )       apply_date       -- �K�p��
               ,TRIM( xwobr.cmpntcost_01gen )  cmpntcost_01gen  -- ����
               ,TRIM( xwobr.cmpntcost_02sai )  cmpntcost_02sai  -- �Đ���
               ,TRIM( xwobr.cmpntcost_03szi )  cmpntcost_03szi  -- ���ޔ�
               ,TRIM( xwobr.cmpntcost_04hou )  cmpntcost_04hou  -- ���
               ,TRIM( xwobr.cmpntcost_05gai )  cmpntcost_05gai  -- �O���Ǘ���
               ,TRIM( xwobr.cmpntcost_06hkn )  cmpntcost_06hkn  -- �ۊǔ�
               ,TRIM( xwobr.cmpntcost_07kei )  cmpntcost_07kei  -- ���̑��o��
               ,xwobr.update_div                                -- ���X�V�敪(�g�p���Ȃ�)
               ,xwobr.created_by                                -- ���쐬��(�g�p���Ȃ�)
               ,xwobr.creation_date                             -- ���쐬��(�g�p���Ȃ�)
               ,xwobr.last_updated_by                           -- ���ŏI�X�V��(�g�p���Ȃ�)
               ,xwobr.last_update_date                          -- ���ŏI�X�V��(�g�p���Ȃ�)
               ,xwobr.last_update_login                         -- ���ŏI�X�V۸޲�(�g�p���Ȃ�)
               ,xwobr.request_id                                -- ���v��ID(�g�p���Ȃ�)
               ,xwobr.program_application_id                    -- ���ݶ��ĥ��۸��ѥ���ع����ID(�g�p���Ȃ�)
               ,xwobr.program_id                                -- ���ݶ��ĥ��۸���ID(�g�p���Ȃ�)
               ,xwobr.program_update_date                       -- ����۸��эX�V��(�g�p���Ȃ�)
      FROM      xxcmm_wk_opmcost_batch_regist    xwobr          -- �W�������ꊇ���胏�[�N
      WHERE     xwobr.file_id    = gn_file_id                   -- �t�@�C��ID
      AND       xwobr.update_div = cv_upd_div_upd               -- �X�V�敪
      ORDER BY  xwobr.file_seq;                                 -- �t�@�C���V�[�P���X
    --
    l_opm_cost_rec             g_opm_cost_rtype;
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
    --A-3 �W�������ꊇ���胏�[�N�̎擾
    --==============================================================
    lv_step := 'A-3.1';
    -- ���C������LOOP
    <<main_loop>>
    FOR l_get_data_rec IN get_data_cur LOOP
      --
      --==============================================================
      --A-4 �f�[�^�Ó����`�F�b�N
      --==============================================================
      lv_step := 'A-4';
      validate_item(
        i_opm_cost_rec    =>  l_get_data_rec
       ,o_opm_cost_rec    =>  l_opm_cost_rec
       ,ov_errbuf         =>  lv_errbuf
       ,ov_retcode        =>  lv_retcode
       ,ov_errmsg         =>  lv_errmsg
      );
      --
      -- �f�[�^�Ó����`�F�b�N�̃X�e�[�^�X��ޔ�
      lv_warnig_flg := lv_retcode;  -- 2009/01/29�ǉ�
      --
      -- �f�[�^�Ó����`�F�b�N���ʂ�����A�x����o�^�E�X�V������
      -- (�x���f�[�^���o�^�E�X�V�Ώ�)
      IF ( lv_retcode != cv_status_error ) THEN
        --
        -- �f�[�^�Ó����`�F�b�N�̃X�e�[�^�X��ޔ�
        --lv_warnig_flg := lv_retcode;  2009/01/29 IF���̊O�ɏo��
        --
        --==============================================================
        --OPM�W���������f
        --  A-5 �W����������Ώۃf�[�^�̒��o
        --  A-6 OPM�W���������f
        --==============================================================
        lv_step := 'A-5';
        proc_opm_cost_ref(
          i_opm_cost_rec   =>  l_opm_cost_rec
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- �ُ펞�́A�f�[�^�Ó����`�F�b�N�̃X�e�[�^�X���㏑��
        IF ( lv_retcode = cv_status_error ) THEN
          lv_warnig_flg := lv_retcode;
          --
        END IF;
      END IF;
      --
      IF ( lv_warnig_flg = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSIF ( lv_warnig_flg = cv_status_warn ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
        gn_warn_cnt   := gn_warn_cnt   + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt  + 1;
      END IF;
    END LOOP main_loop;
    --
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    ELSE
      IF ( gn_warn_cnt > 0 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'GET_IF_DATA';        -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾��  END    ########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_cost_div_str            CONSTANT VARCHAR2(20)  := '���������ʋ敪�F';
                                                                        -- ����������
    cv_cost_div_opm            CONSTANT NUMBER(2)     := '1';           -- ���������ʋ敪(�W������)
    --
    -- CSV�t�@�C������ԍ�
    cn_csv_item_id             CONSTANT NUMBER(2)     := 17;            -- �i��ID
    cn_csv_item_no             CONSTANT NUMBER(2)     := 2;             -- �i�ڃR�[�h
    cn_csv_apply_date          CONSTANT NUMBER(2)     := 14;            -- �K�p��
    cn_csv_opm_cost_01         CONSTANT NUMBER(2)     := 3;             -- ����
    cn_csv_opm_cost_02         CONSTANT NUMBER(2)     := 4;             -- �Đ���
    cn_csv_opm_cost_03         CONSTANT NUMBER(2)     := 5;             -- ���ޔ�
    cn_csv_opm_cost_04         CONSTANT NUMBER(2)     := 6;             -- ���
    cn_csv_opm_cost_05         CONSTANT NUMBER(2)     := 7;             -- �O���Ǘ���
    cn_csv_opm_cost_06         CONSTANT NUMBER(2)     := 8;             -- �ۊǔ�
    cn_csv_opm_cost_07         CONSTANT NUMBER(2)     := 9;             -- ���̑��o��
    cn_csv_update_div          CONSTANT NUMBER(2)     := 13;            -- �X�V�敪
    --
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    --
    ln_line_cnt                NUMBER;                                  -- �s�J�E���^
    ln_item_num                NUMBER;                                  -- ���ڐ�
    lv_cost_div                VARCHAR2(1);                             -- ���������ʋ敪
    lv_update_div              VARCHAR2(1);                             -- �X�V�敪
    ln_ins_item_cnt            NUMBER;                                  -- �o�^�����J�E���^
    --
    -- 
    l_if_data_tab              xxccp_common_pkg2.g_file_data_tbl;
    -- 
    l_disc_cost_tab            g_check_data_ttype;
    --
    cost_div_expt              EXCEPTION;                               -- �N����ʋ敪�G���[
    get_ifdat_cnt_expt         EXCEPTION;                               -- �f�[�^���ڐ��G���[
    ins_data_expt              EXCEPTION;                               -- �f�[�^�o�^�G���[
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_step := 'A-2';
    ln_ins_item_cnt := 0;
    --
    -- SAVEPOINT�ݒ�
    SAVEPOINT XXCMM004A08C_savepoint;
--    --
    --==============================================================
    --A-2.2 �W�������ꊇ����Ώۃf�[�^�̕���(���R�[�h����)
    --==============================================================
    lv_step := 'A-2.2-L';
    -- BLOB�f�[�^�ϊ����ʊ֐�
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id    =>  gn_file_id        -- IN�p�����[�^
     ,ov_file_data  =>  l_if_data_tab     -- ���R�[�h�P��
     ,ov_errbuf     =>  lv_errbuf 
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg 
    );
-- 2009/01/27 �ǉ�
    -- �X�e�[�^�X���G���[�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
-- End
    --
    ------------------
    -- ���R�[�hLOOP
    ------------------
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      --
      IF ( ln_line_cnt <= 5 ) THEN
        ------------------
        -- �w�b�_���R�[�h
        -- 1�s�ځF�\��
        -- 2�s�ځF�W�������N�x
        -- 3�s�ځF�c�ƌ����^�C�v
        -- 4�s�ځF���������ʋ敪
        -- 5�s�ځF���׃^�C�g��
        ------------------
        IF ( ln_line_cnt = 4 ) THEN
          --==============================================================
          --A-2.4 ���������ʋ敪�̃`�F�b�N
          --==============================================================
          -- ���������ʋ敪�̒��o
          lv_step := 'A-2.4';
          lv_cost_div := SUBSTRB( TRIM( REPLACE( l_if_data_tab( ln_line_cnt ), cv_cost_div_str, '' ) ), 1, 1 );
          --
          IF ( lv_cost_div != cv_cost_div_opm ) THEN
            -- �W����������ł͂Ȃ����߃G���[
            RAISE cost_div_expt;
          END IF;
        END IF;
        --
      ELSIF ( ln_line_cnt > 5 ) THEN
        ------------------
        -- ���׃��R�[�h
        ------------------
        --==============================================================
        --A-2.3 ���ڐ��̃`�F�b�N
        --==============================================================
        -- ���ڐ��̃`�F�b�N
        -- �f�[�^���ڐ����i�[( ���R�[�h�o�C�g�� - �J���}�����������R�[�h�o�C�g�� + 1 )
        lv_step := 'A-2.3';
        ln_item_num := ( LENGTHB( l_if_data_tab( ln_line_cnt ) )
                     - ( LENGTHB( REPLACE( l_if_data_tab( ln_line_cnt ), cv_msg_comma, '' ) ) )
                     +   1 );
        --
        -- ���ڐ�����v���Ȃ��ꍇ
        IF ( gn_item_num <> ln_item_num ) THEN
          RAISE get_ifdat_cnt_expt;
        END IF;
        --
        --==============================================================
        --A-2.2 �W�������ꊇ����Ώۃf�[�^�̕���(���ڕ���)
        --==============================================================
        -------------------------------
        -- �f���~�^�����ϊ����ʊ֐�
        -- �e���ڂ̒l���i�[
        -------------------------------
        lv_step := 'A-2.2-C';
        -- �i��ID    �i�P�V��ځj
        l_disc_cost_tab( 1 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_item_id
                                 );
        -- �i�ڃR�[�h�i�Q��ځj
        l_disc_cost_tab( 2 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_item_no
                                 );
        -- �K�p��    �i�P�S��ځj
        l_disc_cost_tab( 3 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_apply_date
                                 );
        -- ����      �i�R��ځj
        l_disc_cost_tab( 4 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_01
                                 );
        -- �Đ���    �i�S��ځj
        l_disc_cost_tab( 5 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_02
                                 );
        -- ���ޔ�    �i�T��ځj
        l_disc_cost_tab( 6 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_03
                                 );
        -- ���    �i�U��ځj
        l_disc_cost_tab( 7 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_04
                                 );
        -- �O���Ǘ���i�V��ځj
        l_disc_cost_tab( 8 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_05
                                 );
        -- �ۊǔ�    �i�W��ځj
        l_disc_cost_tab( 9 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_06
                                 );
        -- ���̑��o��i�X��ځj
        l_disc_cost_tab( 10 ) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_07
                                 );
        -- �X�V�敪  �i�P�R��ځj
        l_disc_cost_tab( 11 ) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_update_div
                                 );
        lv_update_div := SUBSTRB( TRIM( l_disc_cost_tab( 11 ) ), 1, 1 );
        --
        IF ( lv_update_div = cv_upd_div_upd ) THEN
          -- �X�V�敪��'U'�̂ݑΏ�
          gn_target_cnt := gn_target_cnt + 1;
          --
          --==============================================================
          --A-2.5 �W�������ꊇ���胏�[�N�֓o�^
          --==============================================================
          lv_step := 'A-2.5';
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            INSERT INTO  xxcmm_wk_opmcost_batch_regist(
              file_id                        -- �t�@�C��ID
             ,file_seq                       -- �t�@�C���V�[�P���X
             ,item_id                        -- �i��ID
             ,item_no                        -- �i�ڃR�[�h
             ,apply_date                     -- �K�p��
             ,cmpntcost_01gen                -- ����
             ,cmpntcost_02sai                -- �Đ���
             ,cmpntcost_03szi                -- ���ޔ�
             ,cmpntcost_04hou                -- ���
             ,cmpntcost_05gai                -- �O���Ǘ���
             ,cmpntcost_06hkn                -- �ۊǔ�
             ,cmpntcost_07kei                -- ���̑��o��
             ,update_div                     -- �X�V�敪
             ,created_by                     -- �쐬��
             ,creation_date                  -- �쐬��
             ,last_updated_by                -- �ŏI�X�V��
             ,last_update_date               -- �ŏI�X�V��
             ,last_update_login              -- �ŏI�X�V۸޲�
             ,request_id                     -- �v��ID
             ,program_application_id         -- �ݶ��ĥ��۸��ѥ���ع����ID
             ,program_id                     -- �ݶ��ĥ��۸���ID
             ,program_update_date )          -- ��۸��эX�V��
            VALUES(
              gn_file_id                     -- �t�@�C��ID
             ,ln_ins_item_cnt                -- �t�@�C���V�[�P���X
             ,SUBSTRB( l_disc_cost_tab( 1 ),
                       1, 100 )              -- �i��ID
             ,SUBSTRB( l_disc_cost_tab( 2 ),
                       1, 100 )              -- �i�ڃR�[�h
             ,SUBSTRB( l_disc_cost_tab( 3 ),
                       1, 100 )              -- �K�p��
             ,SUBSTRB( l_disc_cost_tab( 4 ),
                       1, 100 )              -- ����
             ,SUBSTRB( l_disc_cost_tab( 5 ),
                       1, 100 )              -- �Đ���
             ,SUBSTRB( l_disc_cost_tab( 6 ),
                       1, 100 )              -- ���ޔ�
             ,SUBSTRB( l_disc_cost_tab( 7 ),
                       1, 100 )              -- ���
             ,SUBSTRB( l_disc_cost_tab( 8 ),
                       1, 100 )              -- �O���Ǘ���
             ,SUBSTRB( l_disc_cost_tab( 9 ),
                       1, 100 )              -- �ۊǔ�
             ,SUBSTRB( l_disc_cost_tab( 10 ),
                       1, 100 )              -- ���̑��o��
             ,lv_update_div                  -- �X�V�敪
             ,cn_created_by                  -- �쐬��
             ,cd_creation_date               -- �쐬��
             ,cn_last_updated_by             -- �ŏI�X�V��
             ,cd_last_update_date            -- �ŏI�X�V��
             ,cn_last_update_login           -- �ŏI�X�V۸޲�
             ,cn_request_id                  -- �v��ID
             ,cn_program_application_id      -- �ݶ��ĥ��۸��ѥ���ع����ID
             ,cn_program_id                  -- �ݶ��ĥ��۸���ID
             ,cd_program_update_date         -- ��۸��эX�V��
            );
          EXCEPTION
            -- *** �f�[�^�o�^��O�n���h�� ***
            WHEN OTHERS THEN
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxcmm         -- �A�v���P�[�V�����Z�k��
                             ,iv_name          =>  cv_msg_xxcmm_00466         -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1   =>  cv_tkn_table               -- �g�[�N���R�[�h1
                             ,iv_token_value1  =>  cv_tkn_val_wk_opm_cost     -- �g�[�N���l1
                             ,iv_token_name2   =>  cv_tkn_input_item          -- �g�[�N���R�[�h2
                             ,iv_token_value2  =>  l_disc_cost_tab( 2 )       -- �g�[�N���l2
                             ,iv_token_name3   =>  cv_tkn_input_apply_date    -- �g�[�N���R�[�h3
                             ,iv_token_value3  =>  l_disc_cost_tab( 3 )       -- �g�[�N���l3
                             ,iv_token_name4   =>  cv_tkn_err_msg             -- �g�[�N���R�[�h2
                             ,iv_token_value4  =>  SQLERRM                    -- �g�[�N���l2
                            );
              -- ���b�Z�[�W�o��
              xxcmm_004common_pkg.put_message(
                iv_message_buff  =>  lv_errmsg
               ,ov_errbuf        =>  lv_errbuf
               ,ov_retcode       =>  lv_retcode
               ,ov_errmsg        =>  lv_errmsg
              );
              --
              gn_error_cnt  := gn_error_cnt  + 1;
            --
          END;
          --
        END IF;
      END IF;
      --
    END LOOP ins_wk_loop;
    --
  EXCEPTION
--
    -- *** �N����ʋ敪��O�n���h�� ***
    WHEN cost_div_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name          =>  cv_msg_xxcmm_00455    -- ���b�Z�[�W�R�[�h
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
    -- *** �f�[�^���ڐ���O�n���h�� ***
    WHEN get_ifdat_cnt_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name          =>  cv_msg_xxcmm_00028    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1   =>  cv_tkn_table          -- �g�[�N���R�[�h1
                     ,iv_token_value1  =>  cv_tkn_val_proc_name  -- �g�[�N���l1
                     ,iv_token_name2   =>  cv_tkn_count          -- �g�[�N���R�[�h2
                     ,iv_token_value2  =>  ln_item_num           -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END  get_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id        IN       VARCHAR2                                        -- ���̓p�����[�^.FILE_ID
   ,iv_format         IN       VARCHAR2                                        -- ���̓p�����[�^.�t�@�C���t�H�[�}�b�g
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_INIT';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lookup_type_upload_obj  CONSTANT VARCHAR2(30) := xxcmm_004common_pkg.cv_lookup_type_upload_obj;
                                                                                                    -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
    cv_lookup_opm_cost_item    CONSTANT VARCHAR2(30) := 'XXCMM1_004A08_ITEM_DEF';                   -- �W�������ꊇ����f�[�^���ڒ�`
    cv_item_num                CONSTANT VARCHAR2(30) := 'XXCMM1_004A08_ITEM_NUM';                   -- �W�������ꊇ����f�[�^���ڐ�
    --
    cv_null_ok                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_null_ok;             -- �C�Ӎ���
    cv_null_ng                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_null_ng;             -- �K�{����
    cv_varchar                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_varchar;             -- ������
    cv_number                  CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_number;              -- ���l
    cv_date                    CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date;                -- ���t
    cv_varchar_cd              CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_varchar_cd;          -- �����񍀖�
    cv_number_cd               CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_number_cd;           -- ���l����
    cv_date_cd                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_cd;             -- ���t����
    cv_not_null                CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_not_null;            -- �K�{
    --
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    lv_tkn_value               VARCHAR2(4000);                                                      -- �g�[�N���l
    ln_cnt                     NUMBER;                                                              -- �J�E���^
    lv_upload_obj              VARCHAR2(100);                                                       -- �t�@�C���A�b�v���[�h����
    --
    -- �t�@�C���A�b�v���[�hIF�e�[�u������
    lv_csv_file_name           xxccp_mrp_file_ul_interface.file_name%TYPE;                          -- �t�@�C�����i�[�p
    ln_created_by              xxccp_mrp_file_ul_interface.created_by%TYPE;                         -- �쐬�Ҋi�[�p
    ld_creation_date           xxccp_mrp_file_ul_interface.creation_date%TYPE;                      -- �쐬���i�[�p
    --
    -- �����o��
    lv_up_name                 VARCHAR2(1000);                                                      -- �A�b�v���[�h���̏o�͗p
    lv_file_name               VARCHAR2(1000);                                                      -- �t�@�C�����o�͗p
    lv_in_file_id              VARCHAR2(1000);                                                      -- �t�@�C���h�c�o�͗p
    lv_in_format               VARCHAR2(1000);                                                      -- �t�H�[�}�b�g�o�͗p
    --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR   get_def_info_cur                                                                       -- �f�[�^���ڒ�`�擾�p�J�[�\��
    IS
      SELECT   flv.meaning                                                   meaning                -- ���e
              ,DECODE( flv.attribute1, cv_varchar, cv_varchar_cd
                                     , cv_number,  cv_number_cd
                                     , cv_date_cd )                          attribute              -- ���ڑ���
              ,DECODE( flv.attribute2, cv_not_null, cv_null_ng
                                     , cv_null_ok )                          essential              -- �K�{�t���O
              ,TO_NUMBER( flv.attribute3 )                                   figures                -- ���ڂ̒���(����)
              ,TO_NUMBER( flv.attribute4 )                                   decim                  -- ���ڂ̒���(����)
      FROM     fnd_lookup_values_vl  flv                                                            -- LOOKUP�\
      WHERE    flv.lookup_type        = cv_lookup_opm_cost_item                                     -- �W�������ꊇ���荀�ڒ�`
      AND      flv.enabled_flag       = cv_yes                                                      -- �g�p�\�t���O
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date                     -- �K�p�J�n��
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date                     -- �K�p�I����
      ORDER BY flv.lookup_code;
      --
    --
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;                              -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;                              -- �v���t�@�C���擾��O
    select_expt               EXCEPTION;                              -- �f�[�^���o�G���[
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    --A-1.1 �p�����[�^�`�F�b�N
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_tkn_file_id;
      RAISE get_param_expt;
    END IF;
    --
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_tkn_val_fmt_pattern;
      RAISE get_param_expt;
    END IF;
    --
    gn_file_id := TO_NUMBER( iv_file_id );    -- IN�p�����[�^���i�[
    gv_format  := iv_format;                  -- IN�p�����[�^���i�[
    --
    --==============================================================
    --A-1.2 �Ɩ����t�̎擾
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    --==============================================================
    --A-1.3 �v���t�@�C���l�擾
    --==============================================================
    -- ���ڐ��̎擾
    lv_step := 'A-1.3';
    gn_item_num     := TO_NUMBER( FND_PROFILE.VALUE( cv_item_num ) );
    --
    IF ( gn_item_num IS NULL ) THEN
      -- ���ڐ��擾���s�̏ꍇ
      lv_tkn_value := cv_tkn_profile;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 �t�@�C���A�b�v���[�h���̂̎擾
    --==============================================================
    lv_step := 'A-1.4';
    --
    BEGIN
      SELECT   flv.meaning  meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv                                             -- LOOKUP�\
      WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND      flv.lookup_code        = gv_format                                   -- �t�H�[�}�b�g�p�^�[��
      AND      flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
    EXCEPTION
      WHEN OTHERS THEN    --�f�[�^���o�G���[ 2009/01/28�ǉ�
        RAISE select_expt;
    END;
    --
    --==============================================================
    --A-1.5 �Ώۃf�[�^���b�N�̎擾
    --==============================================================
    lv_step := 'A-1.5';
    SELECT   fui.file_name         file_name        -- �t�@�C����
            ,fui.created_by        created_by       -- �쐬��
            ,fui.creation_date     creation_date    -- �쐬��
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui       -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE    fui.file_id = gn_file_id               -- �t�@�C��ID
    FOR UPDATE NOWAIT;
    --
    --==============================================================
    --A-1.6 �W�������ꊇ����e�[�u����`���擾
    --==============================================================
    lv_step := 'A-1.6';
    ln_cnt := 0;                                                           -- �ϐ��̏�����
    <<def_info_loop>>                                                      -- �e�[�u����`�擾LOOP
    FOR l_get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_def_info_tab(ln_cnt).meaning   := l_get_def_info_rec.meaning;      -- ���ږ�
      g_def_info_tab(ln_cnt).attribute := l_get_def_info_rec.attribute;    -- ���ڑ���
      g_def_info_tab(ln_cnt).essential := l_get_def_info_rec.essential;    -- �K�{�t���O
      g_def_info_tab(ln_cnt).figures   := l_get_def_info_rec.figures;      -- ���ڂ̒���(����)
      g_def_info_tab(ln_cnt).decim     := l_get_def_info_rec.decim;        -- ���ڂ̒���(����)
    END LOOP def_info_loop;
    --
    --==============================================================
    --A-1.7 IN�p�����[�^�̏o��
    --==============================================================
    lv_step := 'A-1.7';
    --
    lv_up_name    := xxccp_common_pkg.get_msg(                -- �A�b�v���[�h���̂̏o��
                       iv_application  => cv_appl_name_xxcmm  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00021  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_up_name      -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_upload_obj       -- �g�[�N���l1
                      );
    lv_file_name  := xxccp_common_pkg.get_msg(                -- CSV�t�@�C�����̏o��
                       iv_application  => cv_appl_name_xxcmm  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00022  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_name    -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_csv_file_name    -- �g�[�N���l1
                      );
    lv_in_file_id := xxccp_common_pkg.get_msg(                -- �t�@�C��ID�̏o��
                       iv_application  => cv_appl_name_xxcmm  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00023  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_id      -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gn_file_id          -- �g�[�N���l1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmm  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_format       -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format           -- �g�[�N���l1
                      );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  ''            || CHR(10) ||
                           lv_up_name    || CHR(10) ||
                           lv_file_name  || CHR(10) ||
                           lv_in_file_id || CHR(10) ||
                           lv_in_format  || CHR(10)
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
  EXCEPTION
--
    -- *** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN get_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00440    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_param_name     -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_tkn_value          -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_profile_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00002    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_profile        -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_tkn_value          -- �g�[�N���l1
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00008    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_ng_table       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_file_ul_if -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --*** �f�[�^���o�G���[(�A�b�v���[�h�t�@�C������) ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00409            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_flv                  -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_input_line_no          -- �g�[�N���R�[�h2
                    ,iv_token_value2 => NULL                          -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_input_item_code        -- �g�[�N���R�[�h3
                    ,iv_token_value3 => NULL                          -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- �g�[�N���R�[�h4
                    ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id        IN       VARCHAR2                                        -- ���̓p�����[�^.FILE_ID
   ,iv_format         IN       VARCHAR2                                        -- ���̓p�����[�^.�t�@�C���t�H�[�}�b�g
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'SUBMAIN';            -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
  --
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_step                    VARCHAR2(10);
    lv_lm_errbuf               VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_lm_retcode              VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_lm_errmsg               VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- *** ���[�J����O ***
    sub_proc_expt              EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    --A-1.  ��������
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id  =>  iv_file_id    -- ���̓p�����[�^.FILE_ID
     ,iv_format   =>  iv_format     -- ���̓p�����[�^.�t�@�C���t�H�[�}�b�g
     ,ov_errbuf   =>  lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �߂�l���ُ�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    lv_step := 'A-2';
    get_if_data(
      ov_errbuf   =>  lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �߂�l���ُ�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-3 �W�������ꊇ���胏�[�N�̎擾
    --  A-4 �f�[�^�Ó����`�F�b�N
    --  A-5 �W����������Ώۃf�[�^�̒��o
    --  A-6 OPM�W���������f
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf   =>  lv_lm_errbuf   -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_lm_retcode  -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_lm_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    --==============================================================
    --A-7.  �I������
    --==============================================================
    lv_step := 'A-7';
    proc_comp(
      ov_errbuf   =>  lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- LOOP_MAIN�̖߂�l���ُ�̏ꍇ
    IF ( lv_lm_retcode = cv_status_error ) THEN
      lv_errbuf := lv_lm_errbuf;
      lv_errmsg := lv_lm_errmsg;
      RAISE sub_proc_expt;
    END IF;
    --
    -- �I�������̖߂�l���ُ�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    ov_retcode := lv_lm_retcode;
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf            OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,retcode           OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,iv_file_id        IN       VARCHAR2                                        -- �t�@�C��ID
   ,iv_format         IN       VARCHAR2                                        -- �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name                CONSTANT VARCHAR2(100) := 'MAIN';               -- �v���O������
    --
    cv_appl_name_xxccp         CONSTANT VARCHAR2(10)  := 'XXCCP';              -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';   -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- �G���[�I���S���[���o�b�N
    --
    cv_log                     CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                  CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code            VARCHAR2(100);                                  -- �I�����b�Z�[�W�R�[�h
    --
    lv_submain_retcode         VARCHAR2(1);                                    -- ���^�[���E�R�[�h
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
    --
    ----------------------------------
    -- ���O�w�b�_�o��
    ----------------------------------
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
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
      iv_file_id  =>  iv_file_id              -- ���̓p�����[�^.FILE_ID
     ,iv_format   =>  iv_format               -- ���̓p�����[�^.�t�@�C���t�H�[�}�b�g
     ,ov_errbuf   =>  lv_errbuf               -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_retcode              -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- submain�̃��^�[���R�[�h��ޔ�
    lv_submain_retcode := lv_retcode;
    --
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_submain_retcode = cv_status_error ) THEN
      -- �o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                -- �G���[���b�Z�[�W
      );
    END IF;
    --
    ----------------------------------
    -- ���O�t�b�^�o��
    ----------------------------------
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_target_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    --
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_success_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_error_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
-- 2009/01/16 Del �s�v
--    -- �X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_skip_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_warn_cnt )
--                  );
--    -- ���b�Z�[�W�o��
--    xxcmm_004common_pkg.put_message(
--      iv_message_buff  =>  gv_out_msg
--     ,ov_errbuf        =>  lv_errbuf
--     ,ov_retcode       =>  lv_retcode
--     ,ov_errmsg        =>  lv_errmsg
--    );
-- End
    --
    -- �I�����b�Z�[�W
    IF ( lv_submain_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_submain_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_submain_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appl_name_xxccp
                   ,iv_name         =>  lv_message_code
                  );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_submain_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
--
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
END xxcmm004a08c;
/
