CREATE OR REPLACE PACKAGE BODY XXCMM004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A07C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�c�ƌ����f�[�^��
 *                  : Disc�i�ڕύX�����e�[�u��(�A�h�I��)�Ɏ捞�݂܂��B
 * MD.050           : �c�ƌ����ꊇ����    MD050_CMM_004_A07
 * Version          : Draft2C
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              �������� (A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
 *  loop_main              �c�ƌ����ꊇ���胏�[�N�̎擾 (A-3)
 *                            �Evalidate_item
 *                            �Eproc_disc_hst_ref
 *  validate_item          �f�[�^�Ó����`�F�b�N (A-4)
 *  proc_disc_hst_ref      Disc�i�ڕύX���𔽉f
 *                         �i�ڕύX�����A�h�I���o�^�E�X�V���� (A-5)
 *                            �Einsert_disc_hst
 *                            �Eupdate_disc_hst
 *  insert_disc_hst        Disc�i�ڕύX�����A�h�I���}�� (A-6)
 *  update_disc_hst        Disc�i�ڕύX�����A�h�I���X�V (A-7)
 *  proc_comp              �I������ (A-8)
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
 *  2009/01/22    1.01  R.Takigawa       BLOB�f�[�^�ϊ����ʊ֐��̌��retcode���G���[���ǂ������f����IF����ǋL
 *  2009/01/27    1.02  R.Takigawa       �t�@�C�����d���G���[�Ƀg�[�N����ǉ�
 *  2009/01/28    1.03  R.Takigawa       �f�[�^���o�G���[��ǉ�
 *  2009/02/02    1.04  R.Takigawa       �v���t�@�C������ǉ�
 *  2009/02/03    1.05  R.Takigawa       proc_init���ʊ֐��̗�O�������b�Z�[�W�ύX
 *  2009/02/03    1.06  R.Takigawa       �f�[�^���o�G���[�̃��b�Z�[�W�ύX
 *  2009/02/04    1.07  R.Takigawa       SQL�̃f�[�^�^�C��
 *  2009/02/09    1.08  R.Takigawa       ���b�N�G���[���̃��b�Z�[�W�ύX
 *  2009/05/15    1.1   H.Yoshikawa      ��QT1_0569,T1_0588 �Ή�
 *  2009/08/11    1.2   Y.Kuboshima      ��Q0000894 �Ή�
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
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCMM004A07C';       -- �p�b�P�[�W��
  cv_msg_comma               CONSTANT VARCHAR2(3)   := ',';                  -- �J���}
  --
  cv_yes                     CONSTANT VARCHAR2(1)   := 'Y';                  -- Y
  cv_no                      CONSTANT VARCHAR2(1)   := 'N';                  -- N
  --
  cv_upd_div_upd             CONSTANT VARCHAR2(1)   := 'U';                  -- �X�V�敪(U)
  cv_date_fmt_std            CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                             -- ���t�����FYYYY/MM/DD
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
-- Ver1.03
--  cv_msg_xxcmm_00409         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';   -- �f�[�^���o�G���[
-- End1.03
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
  cv_msg_xxcmm_00429         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00429';   -- �i�ڃX�e�[�^�X�G���[
-- End
-- Ver1.06
  cv_msg_xxcmm_00439         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';   -- �f�[�^���o�G���[
-- End1.03
  cv_msg_xxcmm_00440         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- �p�����[�^�`�F�b�N�G���[
-- Ver1.08 Add ���b�Z�[�W�ǉ� 2009/02/09
  cv_msg_xxcmm_00443         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00443';   -- ���b�N�擾�G���[
-- End1.08
  cv_msg_xxcmm_00455         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00455';   -- �N����ʃG���[
  cv_msg_xxcmm_00456         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00456';   -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00457         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00457';   -- �K�p���`�F�b�N�G���[
  cv_msg_xxcmm_00458         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00458';   -- �e�i�ڃ`�F�b�N�G���[
  cv_msg_xxcmm_00459         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00459';   -- �}�X�^�`�F�b�N�G���[
  cv_msg_xxcmm_00460         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00460';   -- �c�ƌ����`�F�b�N�G���[
  cv_msg_xxcmm_00461         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00461';   -- �c�ƌ�����r�G���[
  cv_msg_xxcmm_00463         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00463';   -- �t�@�C�����d���G���[
  cv_msg_xxcmm_00464         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00464';   -- �d���G���[
  cv_msg_xxcmm_00466         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00466';   -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_00467         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00467';   -- �f�[�^�X�V�G���[
  cv_msg_xxcmm_00468         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00468';   -- �f�[�^�폜�G���[
  --
  --�g�[�N���R�[�h
  cv_tkn_table               CONSTANT VARCHAR2(20)  := 'TABLE';              -- �e�[�u����
-- Ver1.08 Add ���b�Z�[�W�ǉ� 2009/02/09
  cv_tkn_item_code           CONSTANT VARCHAR2(20)  := 'ITEM_CODE';          -- �i�ڃR�[�h
-- End1.08
  cv_tkn_ng_table            CONSTANT VARCHAR2(20)  := 'NG_TABLE';           -- ���b�N�擾�G���[�e�[�u����
  cv_tkn_count               CONSTANT VARCHAR2(20)  := 'COUNT';              -- ���ڐ��`�F�b�N����
  cv_tkn_profile             CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- �v���t�@�C����
  cv_tkn_param_name          CONSTANT VARCHAR2(20)  := 'PARAM_NAME';         -- �p�����[�^��
  cv_tkn_input_col_name      CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';     -- ���ږ���
  cv_tkn_cost_type           CONSTANT VARCHAR2(20)  := 'COST_TYPE ';         -- �����^�C�v
  cv_tkn_input_cost          CONSTANT VARCHAR2(20)  := 'INPUT_COST';         -- ���͌���(�c�ƌ���)
  cv_tkn_disc_cost           CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- �c�ƌ���
  cv_tkn_opm_cost            CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- �W������
  cv_tkn_input_item          CONSTANT VARCHAR2(20)  := 'INPUT_ITEM';         -- �i�ڃR�[�h
  cv_tkn_input_apply_date    CONSTANT VARCHAR2(20)  := 'INPUT_APPLY_DATE';   -- �K�p��
  cv_tkn_err_msg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
-- Ver1.03
  --cv_tkn_errmsg              CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- �G���[���e
  cv_tkn_input_line_no       CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';      -- �C���^�t�F�[�X�̍s�ԍ�
  cv_tkn_input_item_code     CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';    -- �C���^�t�F�[�X�̕i���R�[�h
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
  cv_tkn_item_status         CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';        -- �i�ڃX�e�[�^�X��
-- End  --
  cv_table_flv               CONSTANT VARCHAR2(30)  := 'LOOKUP�\';           -- FND_LOOKUP_VALUES_VL
-- End1.03
  cv_tkn_val_proc_name       CONSTANT VARCHAR2(30)  := '�c�ƌ����ꊇ����';
  cv_tkn_val_fmt_pattern     CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';
  cv_tkn_val_disc_cost       CONSTANT VARCHAR2(30)  := '�c�ƌ���';
  cv_tkn_val_file_ul_if      CONSTANT VARCHAR2(30)  := '�t�@�C���A�b�v���[�h�h�^�e';
  cv_tkn_val_wk_disc_cost    CONSTANT VARCHAR2(30)  := '�c�ƌ����ꊇ���胏�[�N';
  cv_tkn_val_disc_hst        CONSTANT VARCHAR2(30)  := 'Disc�i�ڕύX�����A�h�I��';
  cv_tkn_val_disc_item       CONSTANT VARCHAR2(30)  := 'Disc�i�ڃ}�X�^';
-- Ver1.04
  cv_tkn_val_profile         CONSTANT VARCHAR2(50)  := 'XXCMM:�c�ƌ����ꊇ����f�[�^���ڐ�';
-- End1.04
  --
  cv_lookup_cost_cmpt        CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- �W�������R���|�[�l���g
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
  TYPE g_disc_hst_rtype IS RECORD(
    item_id                  xxcmm_system_items_b_hst.item_id%TYPE           -- �i��ID
   ,item_code                xxcmm_system_items_b_hst.item_code%TYPE         -- �i�ڃR�[�h
   ,apply_date               xxcmm_system_items_b_hst.apply_date%TYPE        -- �K�p��
   ,discrete_cost            xxcmm_system_items_b_hst.discrete_cost%TYPE     -- �c�ƌ���
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
   * Description      : �I������ (A-8)
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
    --
    --==============================================================
    --A-8.1 �`�F�b�N�G���[���ݎ�(SAVEPOINT �܂� ROLLBACK)
    --==============================================================
    IF ( gn_error_cnt > 0 ) THEN
      --==============================================================
      --A-8.1 �`�F�b�N�G���[���ݎ�(SAVEPOINT �܂� ROLLBACK)
      --==============================================================
      lv_step := 'A-8.1';
      -- SAVEPOINT�܂� ROLLBACK
      ROLLBACK TO xxcmm004a07c_savepoint;
      --
    ELSE
      --==============================================================
      --A-8.2 �c�ƌ����ꊇ����f�[�^�폜
      --==============================================================
      BEGIN
        lv_step := 'A-8.2';
        DELETE  FROM    xxcmm_wk_disccost_batch_regist;
        --
      EXCEPTION
        -- *** �f�[�^�폜��O�n���h�� ***
        WHEN OTHERS THEN
          --
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                         ,iv_name          =>  cv_msg_xxcmm_00468          -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   =>  cv_tkn_table                -- �g�[�N���R�[�h1
                         ,iv_token_value1  =>  cv_tkn_val_wk_disc_cost     -- �g�[�N���l1
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
    --A-8.3 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-8.3';
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
   * Procedure Name   : update_disc_hst
   * Description      : Disc�i�ڕύX�����A�h�I���X�V (A-7)
   ***********************************************************************************/
  PROCEDURE update_disc_hst(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- �W����������f�[�^
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'UPDATE_DISC_HST';    -- �v���O������
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
    --
    ln_item_hst_id             xxcmm_system_items_b_hst.item_hst_id%TYPE;
    --
    -- Disc�i�ڕύX�����A�h�I�����b�N�J�[�\��
    CURSOR lock_disc_hst_cur(
      p_item_id       NUMBER
     ,p_apply_date    DATE )
    IS
      SELECT    xsibh.item_hst_id                       -- �i�ڕύX����ID
      FROM      xxcmm_system_items_b_hst    xsibh       -- Disc�i�ڕύX�����A�h�I��
      WHERE     xsibh.item_id        = p_item_id        -- �i��ID
      AND       xsibh.apply_date     = p_apply_date     -- �K�p��
      AND       xsibh.apply_flag     = cv_no            -- �K�p�t���O
      FOR UPDATE NOWAIT;
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
    --A-7.1 Disc�i�ڕύX�����A�h�I���̃��b�N�擾
    --==============================================================
    lv_step := 'A-7.1';
    OPEN  lock_disc_hst_cur(
            i_disc_hst_rec.item_id
           ,i_disc_hst_rec.apply_date
          );
    FETCH lock_disc_hst_cur INTO ln_item_hst_id;
    CLOSE lock_disc_hst_cur;
    --
    --==============================================================
    --A-7.2 Disc�i�ڕύX�����A�h�I���̍X�V
    --==============================================================
    lv_step := 'A-7.2';
    BEGIN
      UPDATE  xxcmm_system_items_b_hst
      SET     discrete_cost          = i_disc_hst_rec.discrete_cost     -- �c�ƌ���
             ,last_updated_by        = cn_last_updated_by               -- �ŏI�X�V��
             ,last_update_date       = cd_last_update_date              -- �ŏI�X�V��
             ,last_update_login      = cn_last_update_login             -- �ŏI�X�V۸޲�
             ,request_id             = cn_request_id                    -- �v��ID
             ,program_application_id = cn_program_application_id        -- �ݶ��ĥ��۸��ѥ���ع����ID
             ,program_id             = cn_program_id                    -- �ݶ��ĥ��۸���ID
             ,program_update_date    = cd_program_update_date           -- ��۸��эX�V��
      WHERE   item_hst_id            = ln_item_hst_id;
      --
    EXCEPTION
      -- *** �f�[�^�X�V��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxcmm_00467          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_table                -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_tkn_val_disc_hst         -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_item           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  i_disc_hst_rec.item_code    -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_apply_date     -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  TO_CHAR( i_disc_hst_rec.apply_date
                                                    , cv_date_fmt_std )  -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  SQLERRM                     -- �g�[�N���l4
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
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
-- Ver1.08 Mod ���b�N�G���[���̃��b�Z�[�W�ύX 2009/02/09
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm        -- �A�v���P�[�V�����Z�k��
--                     ,iv_name         => cv_msg_xxcmm_00008      -- ���b�Z�[�W�R�[�h
                     ,iv_name         => cv_msg_xxcmm_00443        -- ���b�Z�[�W�R�[�h
--                     ,iv_token_name1  => cv_tkn_ng_table           -- �g�[�N���R�[�h1
                     ,iv_token_name1  => cv_tkn_table           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_disc_hst       -- �g�[�N���l1
--                     ,iv_token_name2  => cv_tkn_input_item         -- �g�[�N���R�[�h2
                     ,iv_token_name2  => cv_tkn_item_code         -- �g�[�N���R�[�h2
                    ,iv_token_value2 => i_disc_hst_rec.item_code  -- �g�[�N���l2
-- End1.08
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
      --
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
  END update_disc_hst;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_disc_hst
   * Description      : Disc�i�ڕύX�����A�h�I���}�� (A-6)
   ***********************************************************************************/
  PROCEDURE insert_disc_hst(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- �W����������f�[�^
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'INSERT_DISC_HST';    -- �v���O������
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
    --==============================================================
    --A-6 Disc�i�ڕύX�����A�h�I���}��
    --==============================================================
    lv_step := 'A-6.1';
    BEGIN
      INSERT INTO xxcmm_system_items_b_hst(
        item_hst_id                           -- �i�ڕύX����ID
       ,item_id                               -- �i��ID
       ,item_code                             -- �i�ڃR�[�h
       ,apply_date                            -- �K�p���i�K�p�J�n���j
       ,apply_flag                            -- �K�p�L��
       ,item_status                           -- �i�ڃX�e�[�^�X
       ,policy_group                          -- ����Q�R�[�h
       ,fixed_price                           -- �艿
       ,discrete_cost                         -- �c�ƌ���
       ,first_apply_flag                      -- ����K�p�t���O
       ,created_by                            -- �쐬��
       ,creation_date                         -- �쐬��
       ,last_updated_by                       -- �ŏI�X�V��
       ,last_update_date                      -- �ŏI�X�V��
       ,last_update_login                     -- �ŏI�X�V۸޲�
       ,request_id                            -- �v��ID
       ,program_application_id                -- �ݶ��ĥ��۸��ѥ���ع����ID
       ,program_id                            -- �ݶ��ĥ��۸���ID
       ,program_update_date )                 -- ��۸��эX�V��
      VALUES(
        xxcmm_system_items_b_hst_s.NEXTVAL    -- �i�ڕύX����ID
       ,i_disc_hst_rec.item_id                -- �i��ID
       ,i_disc_hst_rec.item_code              -- �i�ڃR�[�h
       ,i_disc_hst_rec.apply_date             -- �K�p���i�K�p�J�n���j
       ,cv_no                                 -- �K�p�L��
       ,NULL                                  -- �i�ڃX�e�[�^�X
       ,NULL                                  -- ����Q�R�[�h
       ,NULL                                  -- �艿
       ,i_disc_hst_rec.discrete_cost          -- �c�ƌ���
       ,cv_no                                 -- ����K�p�t���O
       ,cn_created_by                         -- �쐬��
       ,cd_creation_date                      -- �쐬��
       ,cn_last_updated_by                    -- �ŏI�X�V��
       ,cd_last_update_date                   -- �ŏI�X�V��
       ,cn_last_update_login                  -- �ŏI�X�V۸޲�
       ,cn_request_id                         -- �v��ID
       ,cn_program_application_id             -- �ݶ��ĥ��۸��ѥ���ع����ID
       ,cn_program_id                         -- �ݶ��ĥ��۸���ID
       ,cd_program_update_date                -- ��۸��эX�V��
      );
      --
    EXCEPTION
      -- *** �f�[�^�o�^��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxcmm_00466          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   =>  cv_tkn_table                -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_tkn_val_disc_hst         -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_item           -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  i_disc_hst_rec.item_code    -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_apply_date     -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  TO_CHAR( i_disc_hst_rec.apply_date
                                                    , cv_date_fmt_std )  -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  SQLERRM                     -- �g�[�N���l4
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
  END insert_disc_hst;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_disc_hst_ref
   * Description      : Disc�i�ڕύX���𔽉f (A-5�AA-6�AA-7)
   ***********************************************************************************/
  PROCEDURE proc_disc_hst_ref(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- �W����������f�[�^
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  --
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_DISC_HST_REF';  -- �v���O������
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
    ln_exists_cnt              NUMBER;
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
    lv_step := 'A-5.1';
    SELECT    COUNT( xsibh.ROWID )
    INTO      ln_exists_cnt
    FROM      xxcmm_system_items_b_hst    xsibh                     -- Disc�i�ڕύX�����A�h�I��
    WHERE     xsibh.item_id        = i_disc_hst_rec.item_id         -- �i��ID
    AND       xsibh.apply_date     = i_disc_hst_rec.apply_date      -- �K�p��
    AND       xsibh.apply_flag     = cv_no                          -- �K�p�t���O
    AND       ROWNUM               = 1;
    --
    IF ( ln_exists_cnt = 0 ) THEN
      --==============================================================
      --A-6 Disc�i�ڕύX�����A�h�I���}��
      --==============================================================
      lv_step := 'A-6';
      insert_disc_hst(
        i_disc_hst_rec   =>  i_disc_hst_rec
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      -- �߂�l���G���[�̏ꍇ
      IF ( lv_retcode = cv_status_error ) THEN
        ov_retcode := cv_status_error;
      END IF;
    ELSE
      --==============================================================
      --A-7 Disc�i�ڕύX�����A�h�I���X�V
      --==============================================================
      lv_step := 'A-7';
      update_disc_hst(
        i_disc_hst_rec   =>  i_disc_hst_rec
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      -- �߂�l���G���[�̏ꍇ
      IF ( lv_retcode = cv_status_error ) THEN
        ov_retcode := cv_status_error;
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
  END proc_disc_hst_ref;
--
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_disc_cost_rec   IN       xxcmm_wk_disccost_batch_regist%ROWTYPE          -- �ϊ��O�W����������f�[�^
   ,o_disc_hst_rec    OUT      g_disc_hst_rtype                                -- �ϊ���W����������f�[�^
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
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
    -- ���b�N�A�b�v
    cv_lookup_item_status      CONSTANT VARCHAR2(20)  := 'XXCMM_ITM_STATUS';   -- �i�ڃX�e�[�^�X
    --
    -- �i�ڃX�e�[�^�X
    cn_itm_status_num_tmp      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                               -- ���̔�
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                               -- �c
-- End
    -- �W������
    cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- �q��
    cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- �������@
    cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- ���̓R�[�h
    --
    -- *** ���[�J���ϐ� ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);
    ln_column_cnt              NUMBER;
    --
    ln_exists_cnt              NUMBER;
    lv_item_no                 ic_item_mst_b.item_no%TYPE;
    ln_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE;
    ln_opm_cost                NUMBER;
    --
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
    ln_item_status             xxcmm_system_items_b.item_status%TYPE;
    lv_item_status_name        VARCHAR2(10);
-- End
    l_validate_disc_cost_tab   g_check_data_ttype;
    l_disc_hst_rec             g_disc_hst_rtype;
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
    lv_warnig_flg                 := cv_status_normal;
    --
    -- �i��ID
    l_validate_disc_cost_tab( 1 ) := i_disc_cost_rec.item_id;
    -- �i�ڃR�[�h
    l_validate_disc_cost_tab( 2 ) := i_disc_cost_rec.item_no;
    -- �K�p��
    l_validate_disc_cost_tab( 3 ) := i_disc_cost_rec.apply_date;
    -- �c�ƌ���
    l_validate_disc_cost_tab( 4 ) := i_disc_cost_rec.discrete_cost;
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
-- Ver1.01
--      IF ( lv_retcode = cv_status_error ) THEN
      IF ( lv_retcode != cv_status_normal ) THEN
-- End1.01
        -- �t�@�C�����ڃ`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00456                        -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_col_name                     -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  g_def_info_tab( ln_column_cnt ).meaning   -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_item                         -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_disc_cost_rec.item_no                   -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_disc_cost_rec.apply_date                -- �g�[�N���l3
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
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      lv_step := 'A-4.2';
      -- �e���ڂɊi�[
      l_disc_hst_rec.item_id       := TO_NUMBER( i_disc_cost_rec.item_id );
      l_disc_hst_rec.apply_date    := fnd_date.canonical_to_date( i_disc_cost_rec.apply_date );
      l_disc_hst_rec.discrete_cost := TO_NUMBER( i_disc_cost_rec.discrete_cost );
      --
      --==============================================================
      --A-4.2 �e�i�ڃ`�F�b�N
      --==============================================================
      BEGIN
        --
        SELECT    xoiv.item_no                                            -- �i�ڃR�[�h
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
                 ,NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                      AS item_status                      -- �i�ڃX�e�[�^�X
                 ,flvv.meaning        AS item_status_name                 -- �i�ڃX�e�[�^�X��
-- End
        INTO      lv_item_no
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
                 ,ln_item_status
                 ,lv_item_status_name
-- End
        FROM      xxcmm_opmmtl_items_v       xoiv                         -- �i�ڃr���[
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
                 ,fnd_lookup_values_vl       flvv                         -- LOOKUP�\
-- End
        WHERE     xoiv.item_id             = l_disc_hst_rec.item_id       -- �i��ID
        AND       xoiv.item_id             = xoiv.parent_item_id          -- �e�i��
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
        AND       flvv.lookup_type         = cv_lookup_item_status        -- XXCMM_ITM_STATUS
        AND       flvv.lookup_code         = TO_CHAR( NVL( xoiv.item_status, cn_itm_status_num_tmp ))
                                                                          -- �i�ڃX�e�[�^�X
-- End
-- 2009/08/11 Ver1.2 modify start by Y.Kuboshima
--        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )             -- �K�p�J�n��
--        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );            -- �K�p�I����
        AND       xoiv.start_date_active  <= gd_process_date              -- �K�p�J�n��
        AND       xoiv.end_date_active    >= gd_process_date;             -- �K�p�I����
-- 2009/08/11 Ver1.2 modify end by Y.Kuboshima
        --
        l_disc_hst_rec.item_code     := lv_item_no;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- �e�i�ڃ`�F�b�N�G���[
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_00458          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_input_item           -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  i_disc_cost_rec.item_no     -- �g�[�N���l1
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
-- Ver1.1  2009/05/15  Add  T1_0588 �Ή�
      -- �i�ڃX�e�[�^�X�F���̔ԁA�܂��́A�c�̏ꍇ�G���[�B
      --   ���̔ԁF�c�Ƒg�D(Z99)�ɕi�ڊ�������Ă��Ȃ�����
      --   �c    �F�i�ڏ��ύX�s�̂���
      IF ( ln_item_status IN ( cn_itm_status_num_tmp, cn_itm_status_no_use ) ) THEN
        -- �c�ƌ����`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00429              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_item               -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no         -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_item_status              -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  TO_CHAR( ln_item_status ) || cv_msg_part || 
                                              lv_item_status_name             -- �g�[�N���l2
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
-- End
      --
      --==============================================================
      --A-4.3 Disc�i�ڑ��݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.3';
      BEGIN
        --
        SELECT    xoiv.inventory_item_id          inventory_item_id         -- Disc�i��ID
        INTO      ln_inventory_item_id
        FROM      xxcmm_opmmtl_items_v            xoiv                      -- Disc�i�ڃ}�X�^
        WHERE     xoiv.item_no         = lv_item_no                         -- �i�ڃR�[�h
-- 2009/08/11 Ver1.2 modify start by Y.Kuboshima
--        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )               -- �K�p�J�n��
--        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );              -- �K�p�I����
        AND       xoiv.start_date_active  <= gd_process_date                -- �K�p�J�n��
        AND       xoiv.end_date_active    >= gd_process_date;               -- �K�p�I����
-- 2009/08/11 Ver1.2 modify end by Y.Kuboshima
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- �}�X�^�`�F�b�N�G���[
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_00459          -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1   =>  cv_tkn_input_item           -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  i_disc_cost_rec.item_no     -- �g�[�N���l1
                          ,iv_token_name2   =>  cv_tkn_table                -- �g�[�N���R�[�h2
                          ,iv_token_value2  =>  cv_tkn_val_disc_item        -- �g�[�N���l2
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
      -- �������̂ݎw��\
      lv_step := 'A-4.4';
      IF ( l_disc_hst_rec.apply_date <= gd_process_date ) THEN
        -- �}�X�^�`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00457            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_item             -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no       -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_disc_cost_rec.apply_date    -- �g�[�N���l2
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
      SELECT    COUNT( xwdbr.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_wk_disccost_batch_regist    xwdbr                     -- �c�ƌ����ꊇ���胏�[�N
      WHERE     xwdbr.file_id             = gn_file_id                      -- �t�@�C��ID
      AND       xwdbr.update_div          = cv_upd_div_upd                  -- �X�V�敪
-- Ver1.07 Mod TRIM��ǉ�
      AND       TRIM( xwdbr.item_id )     = i_disc_cost_rec.item_id         -- �i��ID
-- End1.07
      AND       TRIM( xwdbr.apply_date )  = i_disc_cost_rec.apply_date      -- �K�p��
      AND       xwdbr.file_seq           != i_disc_cost_rec.file_seq        -- �t�@�C���V�[�P���X
      AND       ROWNUM                    = 1;
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- �t�@�C�����d���G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00463            -- ���b�Z�[�W�R�[�h
-- Ver1.02
                        ,iv_token_name1   =>  cv_tkn_cost_type              -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  cv_tkn_val_disc_cost          -- �g�[�N���l1
-- End1.02
                        ,iv_token_name2   =>  cv_tkn_input_item             -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_disc_cost_rec.item_no       -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date       -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_disc_cost_rec.apply_date    -- �g�[�N���l3
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
      --A-4.6 �ύX�\��ς݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.6';
      SELECT    COUNT( xsibh.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_system_items_b_hst    xsibh                     -- Disc�i�ڕύX�����A�h�I��
-- Ver1.07 Mod �i��ID�̌^��VARCHAR2����NUMBER�ɕύX
--      WHERE     xsibh.item_id        = i_disc_cost_rec.item_id        -- �i��ID
      WHERE     xsibh.item_id        = l_disc_hst_rec.item_id        -- �i��ID
-- End1.07
      AND       xsibh.apply_date     = l_disc_hst_rec.apply_date      -- �K�p��
      AND       xsibh.apply_flag     = cv_no                          -- �K�p�t���O
      AND       xsibh.discrete_cost IS NOT NULL                       -- �c�ƌ���
      AND       ROWNUM               = 1;
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- �d���G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00464            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_item             -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no       -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_disc_cost_rec.apply_date    -- �g�[�N���l2
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
      --A-4.7 �c�ƌ����`�F�b�N
      --==============================================================
      lv_step := 'A-4.7';
      IF ( l_disc_hst_rec.discrete_cost < 0 )
      OR ( l_disc_hst_rec.discrete_cost <> TRUNC( l_disc_hst_rec.discrete_cost ) ) THEN
        -- �c�ƌ����`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00464              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_cost_type                -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  cv_tkn_val_disc_cost            -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_input_cost               -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  i_disc_cost_rec.discrete_cost   -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_disc_cost_rec.item_no         -- �g�[�N���l3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- �g�[�N���R�[�h4
                        ,iv_token_value4  =>  i_disc_cost_rec.apply_date      -- �g�[�N���l4
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
      --A-4.8 �c�ƌ����ƕW�������̔�r
      --==============================================================
      lv_step := 'A-4.8';
      SELECT    SUM( NVL( ccmd.cmpnt_cost, 0 ) )    -- �W������
      INTO      ln_opm_cost
      FROM      cm_cmpt_dtl          ccmd,          -- OPM�W������
                cm_cldr_dtl          cclr,          -- OPM�����J�����_
                cm_cmpt_mst_vl       ccmv,          -- �����R���|�[�l���g
                fnd_lookup_values_vl flv            -- �Q�ƃR�[�h�l
      WHERE     ccmd.item_id             = l_disc_hst_rec.item_id     -- �i��ID
      AND       cclr.start_date         <= l_disc_hst_rec.apply_date  -- �J�n��
      AND       cclr.end_date           >= l_disc_hst_rec.apply_date  -- �I����
      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                     -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- �����R���|�[�l���g�R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = cclr.calendar_code         -- �J�����_�R�[�h
      AND       ccmd.period_code         = cclr.period_code           -- ���ԃR�[�h
      AND       ccmd.whse_code           = cv_whse_code               -- �q��
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- �������@
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code;     -- ���̓R�[�h
      --
      IF ( l_disc_hst_rec.discrete_cost < ln_opm_cost ) THEN
        -- �c�ƌ����`�F�b�N�G���[
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_00461              -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_disc_cost                -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_disc_cost_rec.discrete_cost   -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_opm_cost                 -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  TO_CHAR( ln_opm_cost )          -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  i_disc_cost_rec.item_no         -- �g�[�N���l3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- �g�[�N���R�[�h4
                        ,iv_token_value4  =>  i_disc_cost_rec.apply_date      -- �g�[�N���l4
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
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- �^�ϊ����{��OUT�ϐ��Ɋi�[
      o_disc_hst_rec := l_disc_hst_rec;
    ELSE
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
   * Description      : �c�ƌ����ꊇ���胏�[�N�̎擾 (A-3)
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
    --
    -- *** �J�[�\�� ***
    -- �c�ƌ����ꊇ����f�[�^�擾�J�[�\��
    CURSOR get_data_cur
    IS
      SELECT    xwdbr.file_id                                 -- �t�@�C��ID
               ,xwdbr.file_seq                                -- �t�@�C���V�[�P���X
               ,TRIM( xwdbr.item_id )        item_id          -- �i��ID
               ,TRIM( xwdbr.item_no )        item_no          -- �i�ڃR�[�h
               ,TRIM( xwdbr.apply_date )     apply_date       -- �K�p��
               ,TRIM( xwdbr.discrete_cost )  discrete_cost    -- �c�ƌ���
               ,xwdbr.update_div                              -- ���X�V�敪(�g�p���Ȃ�)
               ,xwdbr.created_by                              -- ���쐬��(�g�p���Ȃ�)
               ,xwdbr.creation_date                           -- ���쐬��(�g�p���Ȃ�)
               ,xwdbr.last_updated_by                         -- ���ŏI�X�V��(�g�p���Ȃ�)
               ,xwdbr.last_update_date                        -- ���ŏI�X�V��(�g�p���Ȃ�)
               ,xwdbr.last_update_login                       -- ���ŏI�X�V۸޲�(�g�p���Ȃ�)
               ,xwdbr.request_id                              -- ���v��ID(�g�p���Ȃ�)
               ,xwdbr.program_application_id                  -- ���ݶ��ĥ��۸��ѥ���ع����ID(�g�p���Ȃ�)
               ,xwdbr.program_id                              -- ���ݶ��ĥ��۸���ID(�g�p���Ȃ�)
               ,xwdbr.program_update_date                     -- ����۸��эX�V��(�g�p���Ȃ�)
      FROM      xxcmm_wk_disccost_batch_regist    xwdbr       -- �c�ƌ����ꊇ���胏�[�N
      WHERE     xwdbr.file_id    = gn_file_id                 -- �t�@�C��ID
      AND       xwdbr.update_div = cv_upd_div_upd             -- �X�V�敪
      ORDER BY  xwdbr.file_seq;                               -- �t�@�C���V�[�P���X
    --
    l_disc_hst_rec             g_disc_hst_rtype;
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
    --A-3 �c�ƌ����ꊇ���胏�[�N�̎擾
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
        i_disc_cost_rec   =>  l_get_data_rec
       ,o_disc_hst_rec    =>  l_disc_hst_rec
       ,ov_errbuf         =>  lv_errbuf
       ,ov_retcode        =>  lv_retcode
       ,ov_errmsg         =>  lv_errmsg
      );
      --
      -- �f�[�^�Ó����`�F�b�N���ʂ�����̂��̂̂ݓo�^�E�X�V������
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        -- Disc�i�ڕύX���𔽉f
        --  A-5 �i�ڕύX�����A�h�I���o�^�E�X�V����
        --  A-6 Disc�i�ڕύX�����A�h�I���}��
        --  A-7 Disc�i�ڕύX�����A�h�I���X�V
        --==============================================================
        lv_step := 'A-5';
        proc_disc_hst_ref(
          i_disc_hst_rec   =>  l_disc_hst_rec
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
      END IF;
      --
      IF ( lv_retcode = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt  + 1;
      END IF;
    END LOOP main_loop;
    --
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
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
    cv_cost_div_disc           CONSTANT NUMBER(2)     := '2';           -- ���������ʋ敪(�c�ƌ���)
    --
    -- CSV�t�@�C������ԍ�
    cn_csv_item_id             CONSTANT NUMBER(2)     := 17;            -- �i��ID
    cn_csv_item_no             CONSTANT NUMBER(2)     := 2;             -- �i�ڃR�[�h
    cn_csv_apply_date          CONSTANT NUMBER(2)     := 14;            -- �K�p��
    cn_csv_disc_cost           CONSTANT NUMBER(2)     := 11;            -- �c�ƌ���
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
    SAVEPOINT xxcmm004a07c_savepoint;
    --
    --==============================================================
    --A-2.2 �c�ƌ����ꊇ����Ώۃf�[�^�̕���(���R�[�h����)
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
    --
-- Ver1.01 Add
    -- �X�e�[�^�X���G���[�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
-- End1.01
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
-- Ver1.1  2009/05/15  Mod  T1_0569�Ή�
--          IF ( lv_cost_div != cv_cost_div_disc ) THEN
          IF ( lv_cost_div != cv_cost_div_disc )
          OR ( lv_cost_div IS NULL ) THEN
-- End
            -- �c�ƌ�������ł͂Ȃ����߃G���[
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
        --A-2.2 �c�ƌ����ꊇ����Ώۃf�[�^�̕���(���ڕ���)
        --==============================================================
        -------------------------------
        -- �f���~�^�����ϊ����ʊ֐�
        -- �e���ڂ̒l���i�[
        -------------------------------
        lv_step := 'A-2.2-C';
        -- �i��ID    �i�P�V��ځj
        l_disc_cost_tab( 1 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_item_id
                                );
        -- �i�ڃR�[�h�i�Q��ځj
        l_disc_cost_tab( 2 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_item_no
                                );
        -- �K�p��    �i�P�S��ځj
        l_disc_cost_tab( 3 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_apply_date
                                );
        -- �c�ƌ���  �i�P�P��ځj
        l_disc_cost_tab( 4 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_disc_cost
                                );
        -- �X�V�敪  �i�P�R��ځj
        l_disc_cost_tab( 5 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_update_div
                                );
        lv_update_div := SUBSTRB( TRIM( l_disc_cost_tab( 5 ) ), 1, 1 );
        --
        IF ( lv_update_div = cv_upd_div_upd ) THEN
          -- �X�V�敪��'U'�̂ݑΏ�
          gn_target_cnt := gn_target_cnt + 1;
          --
          --==============================================================
          --A-2.5 �c�ƌ����ꊇ���胏�[�N�֓o�^
          --==============================================================
          lv_step := 'A-2.5';
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            INSERT INTO  xxcmm_wk_disccost_batch_regist(
              file_id                        -- �t�@�C��ID
             ,file_seq                       -- �t�@�C���V�[�P���X
             ,item_id                        -- �i��ID
             ,item_no                        -- �i�ڃR�[�h
             ,apply_date                     -- �K�p��
             ,discrete_cost                  -- �c�ƌ���
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
                       1, 100 )              -- �c�ƌ���
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
                             ,iv_token_value1  =>  cv_tkn_val_wk_disc_cost    -- �g�[�N���l1
                             ,iv_token_name2   =>  cv_tkn_input_item          -- �g�[�N���R�[�h2
                             ,iv_token_value2  =>  l_disc_cost_tab( 2 )       -- �g�[�N���l2
                             ,iv_token_name3   =>  cv_tkn_input_apply_date    -- �g�[�N���R�[�h3
                             ,iv_token_value3  =>  l_disc_cost_tab( 3 )       -- �g�[�N���l3
                             ,iv_token_name4   =>  cv_tkn_err_msg             -- �g�[�N���R�[�h4
                             ,iv_token_value4  =>  SQLERRM                    -- �g�[�N���l4
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
    cv_disc_cost_item          CONSTANT VARCHAR2(30) := 'XXCMM1_004A07_ITEM_DEF';                   -- �c�ƌ����ꊇ����f�[�^���ڒ�`
    cv_item_num                CONSTANT VARCHAR2(30) := 'XXCMM1_004A07_ITEM_NUM';                   -- �c�ƌ����ꊇ����f�[�^���ڐ�
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
-- Ver1.06
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM��ޔ�
-- End1.06
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
    CURSOR get_def_info_cur                                                                       -- �f�[�^���ڒ�`�擾�p�J�[�\��
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
      WHERE    flv.lookup_type        = cv_disc_cost_item                                           -- �c�ƌ����ꊇ���荀�ڒ�`
      AND      flv.enabled_flag       = cv_yes                                                      -- �g�p�\�t���O
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date                     -- �K�p�J�n��
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date                     -- �K�p�I����
      ORDER BY flv.lookup_code;
      --
    --
    get_param_expt             EXCEPTION;
    get_profile_expt           EXCEPTION;
-- Ver1.03
    select_expt                EXCEPTION;                              -- �f�[�^���o�G���[
-- End1.03
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
      lv_tkn_value := cv_tkn_val_profile;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 �t�@�C���A�b�v���[�h���̂̎擾
    --==============================================================
    lv_step := 'A-1.4';
    --
-- Ver1.03 Mod
/*
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values_vl flv                                             -- LOOKUP�\
    WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
    AND      flv.lookup_code        = gv_format                                   -- �t�H�[�}�b�g�p�^�[��
    AND      flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
    AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
    AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
*/
    BEGIN
      SELECT   flv.meaning  meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv                                             -- LOOKUP�\
      WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND      flv.lookup_code        = gv_format                                   -- �t�H�[�}�b�g�p�^�[��
      AND      flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I��
    EXCEPTION
      WHEN OTHERS THEN
-- Ver1.06 Add
        lv_sqlerrm := SQLERRM;
-- End1.06
        RAISE select_expt;
    END;
-- End1.03
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
    --A-1.6 �c�ƌ����ꊇ����e�[�u����`���擾
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
-- Ver1.03
    IF ( ln_cnt = 0 ) THEN
      RAISE select_expt;
    END IF;
-- End1.03
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
-- Ver1.03 Add �f�[�^���o�G���[
-- Ver1.06 Mod �f�[�^���o�G���[
/*
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
*/
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00439            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_table_flv                  -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_err_msg                -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_sqlerrm                    -- �g�[�N���l2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
-- End1.06
-- End1.03
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- Ver1.05
      --ov_errmsg  := lv_errmsg;
      ov_errmsg  := SUBSTRB( SQLERRM, 1, 5000 );  --2009/02/03 ���b�Z�[�W�ύX
-- End1.05
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- Ver1.05
      ov_errmsg  := lv_errmsg;
--      ov_errmsg  := SUBSTRB( SQLERRM, 1, 5000 );  --2009/02/03 ���b�Z�[�W�ύX
-- End1.05
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
    --A-3 �c�ƌ����ꊇ���胏�[�N�̎擾
    --  A-4 �f�[�^�Ó����`�F�b�N
    --  A-5 �i�ڕύX�����A�h�I���o�^�E�X�V����
    --  A-6 Disc�i�ڕύX�����A�h�I���}��
    --  A-7 Disc�i�ڕύX�����A�h�I���X�V
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf   =>  lv_lm_errbuf   -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_lm_retcode  -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_lm_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    --==============================================================
    --A-8.  �I������
    --==============================================================
    lv_step := 'A-8';
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
    -- �I��lv_submain_retcode
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
    --
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
END XXCMM004A07C;
/
