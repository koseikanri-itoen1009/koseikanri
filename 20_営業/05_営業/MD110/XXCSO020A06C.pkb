CREATE OR REPLACE PACKAGE BODY XXCSO020A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A06C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽSP�ꌈWF���F�g�D
 *                    �}�X�^�f�[�^��WF���F�g�D�}�X�^�e�[�u���Ɏ捞�݂܂��B
 *
 * MD.050           : MD050_CSO_020_A06_SP-WF���F�g�D�}�X�^���ꊇ�捞
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_dcsn_wf_org_data        WF���F�g�D�}�X�^�f�[�^���o����                  (A-2)
 *  data_proper_check           �f�[�^�Ó����`�F�b�N                            (A-3)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N                              (A-4)
 *  chk_mst_effective_date      ���ꋒ�_CD�ŗL�����Ԃ��d������
 *                              �f�[�^���݃`�F�b�N����(�o�^�p)                  (A-5)
 *  insert_dcsn_wf_org_data     WF���F�g�D�}�X�^�f�[�^�o�^                      (A-6)
 *  chk_dcsn_wf_org_exists      WF���F�g�D�}�X�^�f�[�^���݃`�F�b�N              (A-7)
 *  chk_mst_effective_date_2    ���ꋒ�_CD�ŗL�����Ԃ��d������
 *                              �f�[�^���݃`�F�b�N����(�X�V�p)                  (A-8)
 *  update_dcsn_wf_org_data     WF���F�g�D�}�X�^�f�[�^�X�V                      (A-9)
 *  delete_if_data              �t�@�C���f�[�^�폜����                          (A-11)
 *  submain                     ���C�������v���V�[�W��(
 *                                �Z�[�u�|�C���g�ݒ�                            (A-10)
 *                              )
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��(
 *                                �I������                                      (A-12)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-01-06    1.0   Maruyama.Mio     �V�K�쐬
 *  2008-01-16    1.0   Maruyama.Mio     ���r���[���ʔ��f
 *  2008-01-21    1.0   Maruyama.Mio     �X�V��WHO�J�����C��(�쐬�ҁE�쐬���폜),
 *                                       �X�V�敪NULL�`�F�b�N�ǉ�
 *  2008-01-30    1.0   Maruyama.Mio     IN�p�����[�^�t�@�C��ID�ϐ����ύX(�L�q���[���Q�l)
 *  2008-02-25    1.1   Maruyama.Mio     �y��Q�Ή�028�z�L�����ԏd���`�F�b�N�s��Ή�
 *
 *****************************************************************************************/
-- 
-- #######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
-- #######################  �Œ�O���[�o���萔�錾�� END   #########################
--
-- #######################  �Œ�O���[�o���ϐ��錾�� START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- �Ώی���
  gn_normal_cnt          NUMBER;                    -- ���팏��
  gn_error_cnt           NUMBER;                    -- �G���[����
--
-- #######################  �Œ�O���[�o���ϐ��錾�� END   #########################
--
-- #######################  �Œ苤�ʗ�O�錾�� START       #########################
--
  --*** ���������ʗ�O ***
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  �Œ苤�ʗ�O�錾�� END         #########################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO020A06C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- �L��
--
  -- �X�V�敪�f�t�H���g�l
  cv_value_kubun_val_1   CONSTANT VARCHAR2(100) := '1';  -- �X�V�敪���e�l�P
  cv_value_kubun_val_2   CONSTANT VARCHAR2(100) := '2';  -- �X�V�敪���e�l�Q

  -- ���b�Z�[�W�R�[�h
  
  -- ���������G���[
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ���b�N�G���[
  -- �f�[�^�����G���[�i�t�@�C���A�b�v���[�hI/F�e�[�u���j
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00259';  -- �f�[�^���o�G���[(�t�@�C���A�b�v���[�hI/F�e�[�u��)
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00178';  -- �f�[�^�o�^�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00179';  -- �f�[�^�X�V�G���[
  -- �f�[�^�`�F�b�N�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00180';  -- WF���F�g�D�}�X�^�f�[�^�t�H�[�}�b�g�`�F�b�N�G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00317';  -- ���p�p���`�F�b�N�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00183';  -- �T�C�Y�`�F�b�N�G���[
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00184';  -- DATE�^�`�F�b�N�G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00185';  -- �L���J�n���E�I�����召�`�F�b�N�G���[
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00186';  -- �X�V�敪�`�F�b�N�G���[
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00187';  -- �}�X�^�`�F�b�N�G���[
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00188';  -- �X�V�Ώۑ��݃`�F�b�N�G���[
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00189';  -- �L�����ԏd���G���[
  -- �f�[�^�폜�G���[�i�t�@�C���A�b�v���[�hI/F�e�[�u���j
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  -- �R���J�����g�p�����[�^�֘A
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �p�����[�^�t�@�C��ID
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �p�����[�^�o��CSV�t�@�C����
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �t�@�C���A�b�v���[�h���̒��o�G���[
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �p�����[�^�t�H�[�}�b�g�p�^�[��
  -- �f�[�^���o�G���[
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00497';  -- ���Ə��}�X�^�f�[�^���o�G���[
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- SP�ꌈWF���F�g�D�}�X�^�f�[�^���o�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLMUN';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_val_kubn        CONSTANT VARCHAR2(20) := 'VALUE_KUBUN';
  cv_tkn_val_start       CONSTANT VARCHAR2(20) := 'VALUE_START';
  cv_tkn_val_end         CONSTANT VARCHAR2(20) := 'VALUE_END';
  cv_tkn_val_loc         CONSTANT VARCHAR2(20) := 'VALUE_LOCATION';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';  
  cv_tkn_loc             CONSTANT VARCHAR2(20) := 'LOCATION';
  cv_tkn_efctv_satrt_dt  CONSTANT VARCHAR2(20) := 'EFFECTIVE_START_DATE';
  cv_tkn_efctv_end_dt    CONSTANT VARCHAR2(20) := 'EFFECTIVE_END_DATE';
  cv_tkn_summary         CONSTANT VARCHAR2(20) := 'SUMMARY';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';

--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'SP�ꌈ-WF���F�g�D�}�X�^�f�[�^�𒊏o���܂����B';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '�t�@�C���f�[�^�폜���܂����B';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := '<< SP�ꌈ-WF���F�g�D�}�X�^�f�[�^���o >>';
  cv_debug_msg19         CONSTANT VARCHAR2(200) := '<< �t�@�C���f�[�^�폜 >>';
  cv_debug_msg22         CONSTANT VARCHAR2(200) := '���[���o�b�N���܂����B';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �s�P�ʃf�[�^���i�[����z��
  TYPE g_col_data_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- �}�X�^�f�[�^���݃`�F�b�N�p���_�R�[�h�i�[�z��
  TYPE g_base_code_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- WF���F�g�D�}�X�^�f�[�^���֘A��񒊏o�f�[�^�\����
  TYPE g_dcsn_wf_org_data_rtype IS RECORD(
    update_kubun       VARCHAR2(100),                                     -- �X�V�敪
    base_code          xxcso_sp_decision_wf_orgs.sends_dept_code1%TYPE,   -- ���_CD
    effective_st_date  xxcso_sp_decision_wf_orgs.effective_st_date%TYPE,  -- �L���J�n��
    effective_ed_date  xxcso_sp_decision_wf_orgs.effective_ed_date%TYPE,  -- �L���I����
    sends_dept_code1   xxcso_sp_decision_wf_orgs.sends_dept_code1%TYPE,   -- �񑗋��_CD1
    sends_dept_code2   xxcso_sp_decision_wf_orgs.sends_dept_code2%TYPE,   -- �񑗋��_CD2
    sends_dept_code3   xxcso_sp_decision_wf_orgs.sends_dept_code3%TYPE,   -- �񑗋��_CD3
    sends_dept_code4   xxcso_sp_decision_wf_orgs.sends_dept_code4%TYPE,   -- �񑗋��_CD4
    sends_dept_code5   xxcso_sp_decision_wf_orgs.sends_dept_code5%TYPE,   -- �񑗋��_CD5
    sends_dept_code6   xxcso_sp_decision_wf_orgs.sends_dept_code6%TYPE,   -- �񑗋��_CD6
    sends_dept_code7   xxcso_sp_decision_wf_orgs.sends_dept_code7%TYPE,   -- �񑗋��_CD7
    sends_dept_code8   xxcso_sp_decision_wf_orgs.sends_dept_code8%TYPE,   -- �񑗋��_CD8
    sends_dept_code9   xxcso_sp_decision_wf_orgs.sends_dept_code9%TYPE,   -- �񑗋��_CD9
    sends_dept_code10  xxcso_sp_decision_wf_orgs.sends_dept_code10%TYPE,  -- �񑗋��_CD10
    excerpt            xxcso_sp_decision_wf_orgs.excerpt%TYPE             -- �E�v
  );
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_error_expt EXCEPTION;  -- �X�L�b�v��O
  global_lock_expt       EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gt_base_code             g_base_code_ttype;                  -- �}�X�^�f�[�^���݃`�F�b�N�p���_�R�[�h�i�[�ϐ�
--
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;
  g_dcsn_wf_org_data_rec   g_dcsn_wf_org_data_rtype;           -- WF���F�g�D�}�X�^�f�[�^���o�p���R�[�h
--
  gt_file_id                    xxccp_mrp_file_ul_interface.file_id%TYPE;           -- �t�@�C��ID
  gv_fmt_ptn                    VARCHAR2(20);                                       -- �t�H�[�}�b�g�p�^�[��
  gb_if_del_err_flag            BOOLEAN := FALSE;  -- TRUE : �t�@�C���f�[�^�폜�������s���Ȃ�
  gb_wf_org_inup_rollback_flag  BOOLEAN := FALSE;  -- TRUE : ���[���o�b�N
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf                  OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode                 OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg                  OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf                   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_file_upload_lookup_type  CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_sp_wf_data_lookup_code   CONSTANT VARCHAR2(30)  := '630';
    -- *** ���[�J���ϐ� ***
    lv_file_upload_nm           VARCHAR2(30);  -- �t�@�C���A�b�v���[�h����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- �t�@�C��ID���b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_17           -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_file_id             -- �g�[�N���R�[�h1
                ,iv_token_value1 => TO_CHAR(gt_file_id)        -- �g�[�N���l1
              );
--
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => '' || CHR(10) || lv_errmsg
    );
    -- �t�@�C��ID���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_21        -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_fmt_ptn          -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_fmt_ptn              -- �g�[�N���l1
                 );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_errmsg || CHR(10)
    );
    -- �t�H�[�}�b�g�p�^�[�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg
    );
--
    -- ���̓p�����[�^�t�@�C��ID��NULL�`�F�b�N
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01      -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      -- TRUE : �t�@�C���f�[�^�폜�������s���Ȃ�
      gb_if_del_err_flag := TRUE;
--
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�h���̒��o
    BEGIN
--
      -- �Q�ƃ^�C�v�e�[�u������t�@�C���A�b�v���[�h���̒��o
      SELECT lvvl.meaning  meaning     -- ���e
      INTO   lv_file_upload_nm         -- �t�@�C���A�b�v���[�h����
      FROM   fnd_lookup_values_vl lvvl -- �N�C�b�N�R�[�h
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(SYSDATE) BETWEEN TRUNC(lvvl.start_date_active)
              AND TRUNC(NVL(lvvl.end_date_active, SYSDATE))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_sp_wf_data_lookup_code;
--    
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_20       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_file_upload_nm      -- �g�[�N���l1
                   );
--
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_errmsg || CHR(10)
      );
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg || CHR(10)
      );
--
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̒��o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19    -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_dcsn_wf_org_data
   * Description      : WF���F�g�D�}�X�^�f�[�^���o���� (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_dcsn_wf_org_data(
     ov_errbuf           OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dcsn_wf_org_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;          -- �t�@�C����
    lt_file_content_type xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- �t�@�C���敪
    lt_file_data         xxccp_mrp_file_ul_interface.file_data%TYPE;          -- �t�@�C���f�[�^
    lt_file_format       xxccp_mrp_file_ul_interface.file_format%TYPE;        -- �t�@�C���t�H�[�}�b�g
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �t�@�C���f�[�^���o
      SELECT xmfui.file_name          file_name          -- �t�@�C����
            ,xmfui.file_content_type  file_content_type  -- �t�@�C���敪
            ,xmfui.file_data          file_date          -- �t�@�C���f�[�^
            ,xmfui.file_format        file_format        -- �t�@�C���t�H�[�}�b�g
      INTO   lt_file_name             -- �t�@�C����
            ,lt_file_content_type     -- �t�@�C���敪
            ,lt_file_data             -- �t�@�C���f�[�^
            ,lt_file_format           -- �t�@�C���t�H�[�}�b�g
      FROM   xxccp_mrp_file_ul_interface  xmfui  -- �t�@�C���A�b�v���[�hI/F�e�[�u��
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;  -- �e�[�u�����b�N
      
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id         -- �t�@�C��ID
      ,ov_file_data => g_file_data_tab    -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_03       -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_if_table_nm         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_file_id         -- �g�[�N���R�[�h2
                     ,iv_token_value2 => TO_CHAR(gt_file_id)    -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg         -- �g�[�N���R�[�h2
                     ,iv_token_value3 => lv_errbuf              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg16 || CHR(10) || cv_debug_msg3 || CHR(10)
    );
--
    -- CSV�t�@�C�������b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_18          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_csv_file_nm        -- �g�[�N���R�[�h1
                  ,iv_token_value1 => lt_file_name              -- �g�[�N���l1
                 );
--
    -- CSV�t�@�C�������b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_errmsg || CHR(10)
    );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg || CHR(10)
    );
--

  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END get_dcsn_wf_org_data;
--

  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : �f�[�^�Ó����`�F�b�N (A-3)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value         IN  VARCHAR2                 -- ���Y�s�f�[�^
    ,o_col_data_tab        OUT NOCOPY g_col_data_ttype  -- �����㍀�ڃf�[�^���i�[����z��
    ,ov_errbuf             OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_format_col_cnt      CONSTANT NUMBER        := 15;          -- ���ڐ�
    cn_value_kubun_len     CONSTANT NUMBER        := 1;           -- �X�V�敪�o�C�g��
    cn_value_location_len  CONSTANT NUMBER        := 4;           -- ���_�R�[�h�o�C�g��
    cn_effctv_date_len     CONSTANT NUMBER        := 8;           -- �L���J�n�E�I�����o�C�g��
    cn_description_len     CONSTANT NUMBER        := 100;         -- �E�v�͈�
    cv_effctv_date_fmt     CONSTANT VARCHAR2(100) := 'YYYYMMDD';  -- DATE�^
--
    -- *** ���[�J���ϐ� ***
    l_col_data_tab         g_col_data_ttype;  -- �����㍀�ڃf�[�^���i�[����z��
    lv_item_nm             VARCHAR2(100);     -- �Y�����ږ�
    lv_effctv_strt_date    DATE;              -- �L���J�n��
    lv_effctv_end_date     DATE;              -- �L���I����
    lb_return              BOOLEAN;           -- ���^�[���X�e�[�^�X
--
    lv_tmp                 VARCHAR2(2000);
    ln_pos                 NUMBER;
    ln_cnt                 NUMBER := 1;
    lb_format_flag         BOOLEAN := TRUE;
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- ���ڐ����擾
    IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := iv_base_value;
      LOOP
        ln_pos := INSTR(lv_tmp, cv_comma);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.���ڐ��`�F�b�N
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_base_val    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_base_value      -- �g�[�N���l1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
--
    -- 2.���ڂ�NULL�`�F�b�N�A�f�[�^�^�i���p�����^���t�j�̃`�F�b�N�A�T�C�Y�`�F�b�N
    ELSE
--
      -- ���ʊ֐��ɂ���ĕ����������ڃf�[�^�e�[�u���̎擾
      FOR i IN 1..cn_format_col_cnt LOOP
        l_col_data_tab(i) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, i), '"');
      END LOOP;
--
      lb_return  := TRUE;
      lv_item_nm := '';
--
      -- 1). NULL�`�F�b�N
      IF l_col_data_tab(1) IS NULL THEN
        -- �X�V�敪
        lb_return  := FALSE;
        lv_item_nm := '�X�V�敪';
      ELSIF l_col_data_tab(2) IS NULL THEN
        -- ���_CD
        lb_return  := FALSE;
        lv_item_nm := '���_�R�[�h';
      ELSIF l_col_data_tab(3) IS NULL THEN
        -- �L���J�n��
        lb_return  := FALSE;
        lv_item_nm := '�L���J�n��';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 2). ���p�p���^�`�F�b�N
      IF (xxccp_common_pkg.chk_alphabet_number_only(l_col_data_tab(2)) = FALSE) THEN
        -- ���_CD
        lb_return  := FALSE;
        lv_item_nm := '���_�R�[�h';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 3). ���t�����`�F�b�N
      -- �L���J�n��
      IF (xxcso_util_common_pkg.check_date(l_col_data_tab(3), cv_effctv_date_fmt) = FALSE) THEN
        lb_return := FALSE;
        lv_item_nm := '�L���J�n��';
      ELSIF (l_col_data_tab(4) IS NOT NULL) THEN
      -- �L���I����
        IF (xxcso_util_common_pkg.check_date(l_col_data_tab(4), cv_effctv_date_fmt) = FALSE) THEN
          lb_return := FALSE;
          lv_item_nm := '�L���I����';
        END IF;
      END IF;
--
      IF (lb_return = FALSE) THEN
        
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 4). �T�C�Y�`�F�b�N
      IF (LENGTHB(l_col_data_tab(1)) <> cn_value_kubun_len) THEN
        -- �X�V�敪
        lb_return  := FALSE;
        lv_item_nm := '�X�V�敪';
      ELSIF (LENGTHB(l_col_data_tab(2)) <> cn_value_location_len) THEN
        -- ���_CD
        lb_return  := FALSE;
        lv_item_nm := '���_�R�[�h';
      ELSIF (LENGTHB(l_col_data_tab(3)) <> cn_effctv_date_len) THEN
        -- �L���J�n��
        lb_return  := FALSE;
        lv_item_nm := '�L���J�n��';
      ELSIF (LENGTHB(l_col_data_tab(4)) <> cn_effctv_date_len) THEN
        -- �L���I����
        lb_return  := FALSE;
        lv_item_nm := '�L���I����';
      ELSIF (LENGTHB(l_col_data_tab(5)) <> cn_value_location_len) THEN
        -- �񑗋��_CD1
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h1';
      ELSIF (LENGTHB(l_col_data_tab(6)) <> cn_value_location_len) THEN
        -- �񑗋��_CD2
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h2';
      ELSIF (LENGTHB(l_col_data_tab(7)) <> cn_value_location_len) THEN
        -- �񑗋��_CD3
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h3';
      ELSIF (LENGTHB(l_col_data_tab(8)) <> cn_value_location_len) THEN
        -- �񑗋��_CD4
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h4';
      ELSIF (LENGTHB(l_col_data_tab(9)) <> cn_value_location_len) THEN
        -- �񑗋��_CD5
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h5';
      ELSIF (LENGTHB(l_col_data_tab(10)) <> cn_value_location_len) THEN
        -- �񑗋��_CD6
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h6';
      ELSIF (LENGTHB(l_col_data_tab(11)) <> cn_value_location_len) THEN
        -- �񑗋��_CD7
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h7';
      ELSIF (LENGTHB(l_col_data_tab(12)) <> cn_value_location_len) THEN
        -- �񑗋��_CD8
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h8';
      ELSIF (LENGTHB(l_col_data_tab(13)) <> cn_value_location_len) THEN
        -- �񑗋��_CD9
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h9';
      ELSIF (LENGTHB(l_col_data_tab(14)) <> cn_value_location_len) THEN
        -- �񑗋��_CD10
        lb_return  := FALSE;
        lv_item_nm := '�񑗋��_�R�[�h10';
      ELSIF (LENGTHB(l_col_data_tab(15)) > cn_description_len) THEN
        -- �E�v
        lb_return  := FALSE;
        lv_item_nm := '�E�v';
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 5). �X�V�敪�`�F�b�N
      IF ((l_col_data_tab(1) <> cv_value_kubun_val_1) AND
          (l_col_data_tab(1) <> cv_value_kubun_val_2)) THEN
        lb_return  := FALSE;
      END IF;
--
      IF (lb_return = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_val_kubn    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => l_col_data_tab(1)  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      END IF;
--
      -- 6). �L���J�n���E�I�����召�`�F�b�N
      IF (l_col_data_tab(4) IS NOT NULL) THEN
        IF (l_col_data_tab(3) > l_col_data_tab(4)) THEN
        lb_return  := FALSE;
        END IF;
--
        IF (lb_return = FALSE) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_11   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_val_start   -- �g�[�N���R�[�h1
                         ,iv_token_value1 => l_col_data_tab(3)  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_val_end     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => l_col_data_tab(4)  -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_val    -- �g�[�N���R�[�h3
                         ,iv_token_value3 => iv_base_value      -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
--
    END IF;
--
    -- �s�P�ʃf�[�^�����R�[�h�ɃZ�b�g
    g_dcsn_wf_org_data_rec.update_kubun      := l_col_data_tab(1);   -- �X�V�敪
    g_dcsn_wf_org_data_rec.base_code         := l_col_data_tab(2);   -- ���_CD
    g_dcsn_wf_org_data_rec.effective_st_date := TO_DATE(l_col_data_tab(3), cv_effctv_date_fmt); -- �L���J�n��
    g_dcsn_wf_org_data_rec.effective_ed_date := TO_DATE(l_col_data_tab(4), cv_effctv_date_fmt); -- �L���I����
    g_dcsn_wf_org_data_rec.sends_dept_code1  := l_col_data_tab(5);   -- �񑗋��_CD1
    g_dcsn_wf_org_data_rec.sends_dept_code2  := l_col_data_tab(6);   -- �񑗋��_CD2
    g_dcsn_wf_org_data_rec.sends_dept_code3  := l_col_data_tab(7);   -- �񑗋��_CD3
    g_dcsn_wf_org_data_rec.sends_dept_code4  := l_col_data_tab(8);   -- �񑗋��_CD4
    g_dcsn_wf_org_data_rec.sends_dept_code5  := l_col_data_tab(9);   -- �񑗋��_CD5
    g_dcsn_wf_org_data_rec.sends_dept_code6  := l_col_data_tab(10);  -- �񑗋��_CD6
    g_dcsn_wf_org_data_rec.sends_dept_code7  := l_col_data_tab(11);  -- �񑗋��_CD7
    g_dcsn_wf_org_data_rec.sends_dept_code8  := l_col_data_tab(12);  -- �񑗋��_CD8
    g_dcsn_wf_org_data_rec.sends_dept_code9  := l_col_data_tab(13);  -- �񑗋��_CD9
    g_dcsn_wf_org_data_rec.sends_dept_code10 := l_col_data_tab(14);  -- �񑗋��_CD10
    g_dcsn_wf_org_data_rec.excerpt           := l_col_data_tab(15);  -- �E�v
--
    -- �}�X�^���݃`�F�b�N�p�z��֊i�[ �f�o�b�O�p(gt_base_code_num := gt_base_code.count;)
    gt_base_code.delete;                     -- �z�񏉊���
    gt_base_code(1)  := l_col_data_tab(5);   -- �񑗋��_CD1
    gt_base_code(2)  := l_col_data_tab(6);   -- �񑗋��_CD2
    gt_base_code(3)  := l_col_data_tab(7);   -- �񑗋��_CD3
    gt_base_code(4)  := l_col_data_tab(8);   -- �񑗋��_CD4
    gt_base_code(5)  := l_col_data_tab(9);   -- �񑗋��_CD5
    gt_base_code(6)  := l_col_data_tab(10);  -- �񑗋��_CD6
    gt_base_code(7)  := l_col_data_tab(11);  -- �񑗋��_CD7
    gt_base_code(8)  := l_col_data_tab(12);  -- �񑗋��_CD8
    gt_base_code(9)  := l_col_data_tab(13);  -- �񑗋��_CD9
    gt_base_code(10) := l_col_data_tab(14);  -- �񑗋��_CD10
    
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : �}�X�^���݃`�F�b�N (A-4)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_base_value         IN  VARCHAR2         -- ���Y�s�f�[�^
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_colmun_nm           CONSTANT VARCHAR2(100) := '���_�R�[�h';
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := '���Ə��}�X�^';
    -- *** ���[�J���ϐ� ***
    ln_location_code_num   NUMBER;  -- ���_CD�J�E���g�p�ϐ�(���Ə��}�X�^�`�F�b�N)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. ���_CD�̃}�X�^(���Ə��}�X�^)���݃`�F�b�N *** --
    BEGIN
      SELECT COUNT(hrl.location_code)  location_code_num  -- ���_CD���J�E���g
      INTO   ln_location_code_num  -- ���_CD�J�E���g�p�ϐ�(���Ə��}�X�^�`�F�b�N)
      FROM   hr_locations hrl      -- ���Ə��}�X�^
      WHERE  hrl.location_code = g_dcsn_wf_org_data_rec.base_code;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_22                  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_locations_table_nm             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item                       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_dcsn_wf_org_data_rec.base_code  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                           -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    IF (ln_location_code_num = 0) THEN
    -- ���o������0���̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_13                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_clmn                         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_colmun_nm                        -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_tbl                          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_locations_table_nm               -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item                         -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_dcsn_wf_org_data_rec.base_code    -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_base_val                     -- �g�[�N���R�[�h4
                     ,iv_token_value4 => iv_base_value                       -- �g�[�N���l4
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;

--
    -- *** 2. �񑗗p���_CD�̃}�X�^(���Ə��}�X�^)���݃`�F�b�N *** --
    FOR i IN 1..gt_base_code.COUNT LOOP
      IF (gt_base_code(i) IS NOT NULL) THEN
        BEGIN
          SELECT COUNT(hrl.location_code)  location_code_num  -- ���_CD���J�E���g
          INTO   ln_location_code_num  -- ���_CD�J�E���g�p�ϐ�(���Ə��}�X�^�`�F�b�N)
          FROM   hr_locations hrl      -- ���Ə��}�X�^
          WHERE  hrl.location_code = gt_base_code(i);

--
        EXCEPTION
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_22              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_tbl                    -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_locations_table_nm         -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_item                   -- �g�[�N���R�[�h2
                           ,iv_token_value2 => gt_base_code(i)               -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                           ,iv_token_value3 => SQLERRM                       -- �g�[�N���l3
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_skip_error_expt;
        END;
      
        IF (ln_location_code_num = 0) THEN
          -- ���o������0���̏ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                      -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_13                 -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_clmn                      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_colmun_nm                     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_tbl                       -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_locations_table_nm            -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_item                      -- �g�[�N���R�[�h3
                        ,iv_token_value3 => gt_base_code(i)                  -- �g�[�N���l3
                        ,iv_token_name4  => cv_tkn_base_val                  -- �g�[�N���R�[�h4
                        ,iv_token_value4 => iv_base_value                    -- �g�[�N���l4
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_error_expt;
        END IF;
      END IF;
    END LOOP;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_is_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_effective_date
   * Description      : ���ꋒ�_CD�ŗL�����Ԃ��d������
   *                    �f�[�^���݃`�F�b�N����(�o�^�p) (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_effective_date(
     iv_base_value         IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'chk_mst_effective_date';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP�ꌈWF���F�g�D�}�X�^';
    -- *** ���[�J���ϐ� *** 
    ln_base_code_num       NUMBER;   -- ���_CD�J�E���g�p�ϐ�(SP�ꌈWF���F�g�D�}�X�^�`�F�b�N)
    -- *** ���[�J����O ***
    chk_ffctv_dt_err_expt  EXCEPTION;  -- �L�����ԏd����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. ���ꋒ�_CD�A�L�����Ԃ̃f�[�^�����ɑ��݂��邩�`�F�b�N *** --
    BEGIN
      SELECT COUNT(sdwo.base_code)  location_code_num  -- ���_CD���J�E���g
      INTO   ln_base_code_num                -- ���_CD�J�E���g�p�ϐ�(SP�ꌈWF���F�g�D�}�X�^�`�F�b�N)
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = TRUNC(g_dcsn_wf_org_data_rec.effective_st_date);
--
      IF (ln_base_code_num = 0) THEN
        SELECT COUNT(sdwo.base_code)  location_code_num  -- ���_CD���J�E���g
        INTO   ln_base_code_num                -- ���_CD�J�E���g�p�ϐ�(SP�ꌈWF���F�g�D�}�X�^�`�F�b�N)
        FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
        WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
        AND    (TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)
               BETWEEN sdwo.effective_st_date
               AND     NVL(TRUNC(sdwo.effective_ed_date), TRUNC(g_dcsn_wf_org_data_rec.effective_st_date))
        OR     TRUNC(sdwo.effective_st_date)
               BETWEEN TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)
               AND     NVL(TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date), TRUNC(sdwo.effective_st_date)));
      END IF;
--
      IF (ln_base_code_num >= 1) THEN
      -- �擾����������1���ȏ�̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                       -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15                  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_val_loc                    -- �g�[�N���R�[�h1
                      ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code  -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_val_start                  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)              -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_val_end                    -- �g�[�N���R�[�h3
                      ,iv_token_value3 => TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)              -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_base_val                   -- �g�[�N���R�[�h4
                      ,iv_token_value4 => iv_base_value                     -- �g�[�N���l4
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_ffctv_dt_err_expt;
      END IF;
--
    EXCEPTION
      -- �L�����Ԃ��d������f�[�^�����݂����ꍇ
      WHEN chk_ffctv_dt_err_expt THEN
        RAISE global_skip_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_locations_table_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                       ,iv_token_value2 => SQLERRM                       -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_effective_date;

  /**********************************************************************************
   * Procedure Name   : insert_dcsn_wf_org_data
   * Description      : WF���F�g�D�}�X�^�f�[�^�o�^ (A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_dcsn_wf_org_data(
     iv_base_value         IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'insert_dcsn_wf_org_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP�ꌈWF���F�g�D�}�X�^';
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- WF���F�g�D�}�X�^�f�[�^�o�^ 
    -- =======================
    BEGIN
      INSERT INTO xxcso_sp_decision_wf_orgs  -- SP�ꌈWF���F�g�D�}�X�^
        ( wf_approval_org_id      -- WF���F�g�D�}�X�^ID
         ,base_code               -- ���_CD
         ,effective_st_date       -- �L���J�n��
         ,effective_ed_date       -- �L���I����
         ,sends_dept_code1        -- �񑗋��_CD1
         ,sends_dept_code2        -- �񑗋��_CD2
         ,sends_dept_code3        -- �񑗋��_CD3
         ,sends_dept_code4        -- �񑗋��_CD4
         ,sends_dept_code5        -- �񑗋��_CD5
         ,sends_dept_code6        -- �񑗋��_CD6
         ,sends_dept_code7        -- �񑗋��_CD7
         ,sends_dept_code8        -- �񑗋��_CD8
         ,sends_dept_code9        -- �񑗋��_CD9
         ,sends_dept_code10       -- �񑗋��_CD10
         ,excerpt                 -- �E�v
         ,created_by              -- �쐬��
         ,creation_date           -- �쐬��
         ,last_updated_by         -- �ŏI�X�V��
         ,last_update_date        -- �ŏI�X�V��
         ,last_update_login       -- �ŏI�X�V���O�C��
         ,request_id              -- �v��ID
         ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              -- �R���J�����g�E�v���O����ID
         ,program_update_date     -- �v���O�����X�V��
         )
      VALUES
        ( xxcso_sp_decision_wf_orgs_s01.NEXTVAL
         ,g_dcsn_wf_org_data_rec.base_code        
         ,g_dcsn_wf_org_data_rec.effective_st_date
         ,g_dcsn_wf_org_data_rec.effective_ed_date
         ,g_dcsn_wf_org_data_rec.sends_dept_code1 
         ,g_dcsn_wf_org_data_rec.sends_dept_code2 
         ,g_dcsn_wf_org_data_rec.sends_dept_code3 
         ,g_dcsn_wf_org_data_rec.sends_dept_code4 
         ,g_dcsn_wf_org_data_rec.sends_dept_code5 
         ,g_dcsn_wf_org_data_rec.sends_dept_code6 
         ,g_dcsn_wf_org_data_rec.sends_dept_code7 
         ,g_dcsn_wf_org_data_rec.sends_dept_code8 
         ,g_dcsn_wf_org_data_rec.sends_dept_code9 
         ,g_dcsn_wf_org_data_rec.sends_dept_code10
         ,g_dcsn_wf_org_data_rec.excerpt          
         ,cn_created_by            
         ,cd_creation_date         
         ,cn_last_updated_by       
         ,cd_last_update_date      
         ,cn_last_update_login     
         ,cn_request_id            
         ,cn_program_application_id
         ,cn_program_id            
         ,cd_program_update_date   
        );
--
    EXCEPTION
         -- �o�^�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_locations_table_nm  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_dcsn_wf_org_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_dcsn_wf_org_exists
   * Description      : WF���F�g�D�}�X�^�f�[�^���݃`�F�b�N (A-7)
   ***********************************************************************************/
--
  PROCEDURE chk_dcsn_wf_org_exists(
     iv_base_value          IN  VARCHAR2         -- ���Y�s�f�[�^
    ,ov_wf_approval_org_id  OUT NOCOPY VARCHAR2  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_dcsn_wf_org_exists';  -- �v���O������
--
-- #######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP�ꌈWF���F�g�D�}�X�^';
    -- *** ���[�J���ϐ� ***
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �X�V�敪��2�̏ꍇ��(WF���F�g�D�}�X�^)���݃`�F�b�N *** --
    BEGIN
      SELECT sdwo.wf_approval_org_id  wf_approval_org_id  -- WF���F�g�D�}�X�^ID
      INTO   ct_wf_approval_org_id           -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date;

    ov_wf_approval_org_id := ct_wf_approval_org_id;  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID���A�E�g�p�����[�^��
--
    EXCEPTION
      -- ���o������0���̏ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                               -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_14                          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_val_loc                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_val_start                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_dcsn_wf_org_data_rec.effective_st_date  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_val                           -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_base_value                             -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_locations_table_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                       ,iv_token_value2 => SQLERRM                       -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_dcsn_wf_org_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_effective_date_2
   * Description      : ���ꋒ�_CD�ŗL�����Ԃ��d������
   *                    �f�[�^���݃`�F�b�N����(�X�V�p) (A-8)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_effective_date_2(
     iv_base_value         IN  VARCHAR2                    -- ���Y�s�f�[�^
    ,iv_wf_approval_org_id IN  VARCHAR2                    -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'chk_mst_effective_date_2';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_locations_table_nm  CONSTANT VARCHAR2(100) := 'SP�ꌈWF���F�g�D�}�X�^';
    -- *** ���[�J���ϐ� *** 
    ln_count_num           NUMBER;            -- WF���F�g�D�}�X�^ID�J�E���g�p�ϐ�(SP�ꌈWF���F�g�D�}�X�^�`�F�b�N)
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
    -- *** ���[�J����O ***
    chk_ffctv_dt_err_expt  EXCEPTION;         -- �L�����ԏd����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--

    -- *** 1. ���ꋒ�_CD�A�L�����Ԃ̃f�[�^�����ɑ��݂��邩�`�F�b�N *** --
    BEGIN
      ct_wf_approval_org_id := iv_wf_approval_org_id;  -- IN�p�����[�^���i�[

      SELECT COUNT(sdwo.wf_approval_org_id)  wf_approval_org_id_num  -- WF���F�g�D�}�X�^ID��
      INTO   ln_count_num                    -- WF���F�g�D�}�X�^ID�J�E���g�p�ϐ�(SP�ꌈWF���F�g�D�}�X�^�`�F�b�N)
      FROM   xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.wf_approval_org_id <> ct_wf_approval_org_id
      AND    TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)
             BETWEEN sdwo.effective_st_date
             AND     NVL(TRUNC(sdwo.effective_ed_date), TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date));
--
      IF (ln_count_num >= 1) THEN
      -- �擾����������1���ȏ�̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                      -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15                                 -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_val_loc                                   -- �g�[�N���R�[�h1
                      ,iv_token_value1 => g_dcsn_wf_org_data_rec.base_code                 -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_val_start                                 -- �g�[�N���R�[�h2
                      ,iv_token_value2 => TRUNC(g_dcsn_wf_org_data_rec.effective_st_date)  -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_val_end                                   -- �g�[�N���R�[�h3
                      ,iv_token_value3 => TRUNC(g_dcsn_wf_org_data_rec.effective_ed_date)  -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_base_val                                  -- �g�[�N���R�[�h4
                      ,iv_token_value4 => iv_base_value                                    -- �g�[�N���l4
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_ffctv_dt_err_expt;
      END IF;
--
    EXCEPTION
      -- �L�����Ԃ��d������f�[�^�����݂����ꍇ
      WHEN chk_ffctv_dt_err_expt THEN
        RAISE global_skip_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_locations_table_nm         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                       ,iv_token_value2 => SQLERRM                       -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END chk_mst_effective_date_2;
--
  /**********************************************************************************
   * Procedure Name   : update_dcsn_wf_org_data
   * Description      : WF���F�g�D�}�X�^�f�[�^�X�V (A-9)
   ***********************************************************************************/
--
  PROCEDURE update_dcsn_wf_org_data(
     iv_base_value         IN  VARCHAR2                    -- ���Y�s�f�[�^

    ,ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'update_dcsn_wf_org_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_update_table_nm     CONSTANT VARCHAR2(100) := 'SP�ꌈWF���F�g�D�}�X�^';
    -- *** ���[�J���ϐ� ***
    ln_wf_approval_org_id  NUMBER;  -- WF���F�g�D�}�X�^ID�i�[�p�ϐ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--    
    -- =======================
    -- WF���F�g�D�}�X�^�f�[�^�X�V 
    -- =======================
    BEGIN
      SELECT  sdwo.wf_approval_org_id  wf_approval_org_id  -- WF���F�g�D�}�X�^ID
      INTO    ln_wf_approval_org_id           -- WF���F�g�D�}�X�^ID�i�[
      FROM    xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
      WHERE   sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND     sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date
      FOR UPDATE NOWAIT;  -- �e�[�u�����b�N
--
    EXCEPTION
          -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_update_table_nm   -- �g�[�N���l1
                       ,iv_token_name3  => cv_tkn_err_msg       -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_update_table_nm   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg       -- �g�[�N���R�[�h3
                       ,iv_token_value2 => SQLERRM              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
    END;
--
    BEGIN
      UPDATE xxcso_sp_decision_wf_orgs sdwo  -- SP�ꌈWF���F�g�D�}�X�^
      SET
         base_code               =  g_dcsn_wf_org_data_rec.base_code          -- ���_CD
        ,effective_st_date       =  g_dcsn_wf_org_data_rec.effective_st_date  -- �L���J�n��
        ,effective_ed_date       =  g_dcsn_wf_org_data_rec.effective_ed_date  -- �L���I����
        ,sends_dept_code1        =  g_dcsn_wf_org_data_rec.sends_dept_code1   -- �񑗋��_CD1
        ,sends_dept_code2        =  g_dcsn_wf_org_data_rec.sends_dept_code2   -- �񑗋��_CD2
        ,sends_dept_code3        =  g_dcsn_wf_org_data_rec.sends_dept_code3   -- �񑗋��_CD3
        ,sends_dept_code4        =  g_dcsn_wf_org_data_rec.sends_dept_code4   -- �񑗋��_CD4
        ,sends_dept_code5        =  g_dcsn_wf_org_data_rec.sends_dept_code5   -- �񑗋��_CD5
        ,sends_dept_code6        =  g_dcsn_wf_org_data_rec.sends_dept_code6   -- �񑗋��_CD6
        ,sends_dept_code7        =  g_dcsn_wf_org_data_rec.sends_dept_code7   -- �񑗋��_CD7
        ,sends_dept_code8        =  g_dcsn_wf_org_data_rec.sends_dept_code8   -- �񑗋��_CD8
        ,sends_dept_code9        =  g_dcsn_wf_org_data_rec.sends_dept_code9   -- �񑗋��_CD9
        ,sends_dept_code10       =  g_dcsn_wf_org_data_rec.sends_dept_code10  -- �񑗋��_CD10
        ,excerpt                 =  g_dcsn_wf_org_data_rec.excerpt            -- �E�v
        ,last_updated_by         =  cn_last_updated_by           -- �ŏI�X�V��
        ,last_update_date        =  cd_last_update_date          -- �ŏI�X�V��
        ,last_update_login       =  cn_last_update_login         -- �ŏI�X�V���O�C��
        ,request_id              =  cn_request_id                -- �v��ID
        ,program_application_id  =  cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id              =  cn_program_id                -- �R���J�����g�E�v���O����ID
        ,program_update_date     =  cd_program_update_date       -- �v���O�����X�V��
      WHERE  sdwo.base_code = g_dcsn_wf_org_data_rec.base_code
      AND    sdwo.effective_st_date = g_dcsn_wf_org_data_rec.effective_st_date;
    
--
    EXCEPTION
      -- �X�V�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_update_table_nm   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_dcsn_wf_org_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : �t�@�C���f�[�^�폜���� (A-11)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf      OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode     OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg      OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm  CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- �t�@�C���f�[�^�폜
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || cv_debug_msg19 || CHR(10) || cv_debug_msg15 || CHR(10)
      );
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg       -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;                              -- # �C�� #
    END;

--

  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf      OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode     OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg      OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode  VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================

    -- *** ���[�J���ϐ� ***
    l_col_data_tab         g_col_data_ttype;       -- �����㍀�ڃf�[�^���i�[����z��
    lv_base_value          VARCHAR2(5000);         -- ���Y�s�f�[�^
    ln_obj_ver_num         NUMBER;                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ct_wf_approval_org_id  xxcso_sp_decision_wf_orgs.wf_approval_org_id%TYPE;  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--

    -- ========================================
    -- A-2.WF���F�g�D�}�X�^�f�[�^���o���� 
    -- ========================================
    get_dcsn_wf_org_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���f�[�^���[�v
    <<dcsn_wf_org_data_loop>>
    FOR i IN 1..g_file_data_tab.COUNT LOOP
--
      BEGIN
--
        -- ���R�[�h�N���A
        g_dcsn_wf_org_data_rec := NULL;

        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;

        lv_base_value := g_file_data_tab(i);
--

        -- =================================================
        -- A-3.�f�[�^�Ó����`�F�b�N (���R�[�h�Ƀf�[�^�Z�b�g)
        -- =================================================
        data_proper_check(
           o_col_data_tab   => l_col_data_tab   -- �t�@�C���f�[�^(�s�f�[�^)
          ,iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- =============================
        -- A-4.�}�X�^���݃`�F�b�N 
        -- =============================
        chk_mst_is_exists(
           iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE global_skip_error_expt;
        END IF;
--
        -- A-2�Œ��o�����X�V�敪��1�̏ꍇ
        IF (g_dcsn_wf_org_data_rec.update_kubun = cv_value_kubun_val_1) THEN
--
          -- =====================================
          -- A-5.���ꋒ�_CD�ŗL�����Ԃ��d������
          --     �f�[�^���݃`�F�b�N����(�o�^�p)
          -- =====================================
--
          chk_mst_effective_date(
             iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- A-10.SAVEPOINT���s
          SAVEPOINT dcsn_wf_org;
--
          -- =============================
          -- A-6.WF���F�g�D�}�X�^�f�[�^�o�^ 
          -- =============================
          insert_dcsn_wf_org_data(
             iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_skip_error_expt;
          END IF;
--
        -- A-2�Œ��o�����X�V�敪��2�̏ꍇ
        ELSIF (g_dcsn_wf_org_data_rec.update_kubun = cv_value_kubun_val_2) THEN
--
          -- ========================================
          -- A-7.WF���F�g�D�}�X�^�f�[�^���݃`�F�b�N 
          -- ========================================
          chk_dcsn_wf_org_exists(
             iv_base_value          => lv_base_value          -- ���Y�s�f�[�^
            ,ov_wf_approval_org_id  => ct_wf_approval_org_id  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
            ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode             => lv_sub_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_skip_error_expt;
          END IF;
--
          -- A-10.SAVEPOINT���s
          SAVEPOINT dcsn_wf_org;
--

          -- =====================================
          -- A-8.���ꋒ�_CD�ŗL�����Ԃ��d������
          --     �f�[�^���݃`�F�b�N����(�X�V�p)
          -- =====================================
          -- A-2�Œ��o�����L���I������NULL�ȊO�̏ꍇ
          IF (g_dcsn_wf_org_data_rec.effective_ed_date IS NOT NULL) THEN
            chk_mst_effective_date_2(
              iv_base_value           => lv_base_value          -- ���Y�s�f�[�^
              ,iv_wf_approval_org_id  => ct_wf_approval_org_id  -- A-8�`�F�b�N�pWF���F�g�D�}�X�^ID
              ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode             => lv_sub_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              RAISE global_skip_error_expt;
            END IF;
          END IF;
--
          -- =============================
          -- A-9.WF���F�g�D�}�X�^�f�[�^�X�V 
          -- =============================
          update_dcsn_wf_org_data(
             iv_base_value  => lv_base_value   -- ���Y�s�f�[�^
            ,ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode     => lv_sub_retcode  -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_wf_org_inup_rollback_flag := TRUE;
            RAISE global_skip_error_expt;
          END IF;
--
        END IF;
--
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** �X�L�b�v��O�n���h�� ***
        WHEN global_skip_error_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode := cv_status_warn;
--
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
            );
          END IF;
--
        --*** ���������ʗ�O�n���h�� ***
        WHEN global_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode := cv_status_warn;
--
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
            );
          END IF;
--        
        -- *** �X�L�b�v��OOTHERS�n���h�� ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode := cv_status_warn;
--
          -- ���O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
--
          -- ���[���o�b�N
          IF gb_wf_org_inup_rollback_flag = TRUE THEN
            ROLLBACK TO SAVEPOINT dcsn_wf_org;    -- ROLLBACK
            gb_wf_org_inup_rollback_flag := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg22|| CHR(10)
            );
          END IF;
--
      END;
--
    END LOOP dcsn_wf_org_data_loop;
--
    ov_retcode := lv_retcode;                -- ���^�[���E�R�[�h
--
    -- =============================
    -- A-11.�t�@�C���f�[�^�폜���� 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �t�@�C���f�[�^�폜�ł̃G���[
      gb_if_del_err_flag := TRUE;
--
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      -- �t�@�C���f�[�^�폜����
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      -- �t�@�C���f�[�^�폜����
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
      END IF;
--
    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
    ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      -- �t�@�C���f�[�^�폜����
      IF (gb_if_del_err_flag = FALSE) THEN
        delete_if_data(
           ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
--

  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W  -- # �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h    -- # �Œ� #
    ,in_file_id    IN         NUMBER            -- �t�@�C��ID
    ,iv_fmt_ptn    IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  )    
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g
    gt_file_id := in_file_id;
    gv_fmt_ptn := iv_fmt_ptn;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf                  -- �G���[���b�Z�[�W
       );
--
         IF (gn_normal_cnt IS NOT NULL) THEN
         gn_error_cnt := gn_error_cnt + gn_normal_cnt;
         gn_normal_cnt := 0;  -- ����������S�ăG���[������
         END IF;
--
    END IF;
--
    -- =======================
    -- A-12.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCSO020A06C;
/
