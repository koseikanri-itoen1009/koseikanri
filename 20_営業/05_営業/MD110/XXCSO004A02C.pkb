CREATE OR REPLACE PACKAGE BODY APPS.XXCSO004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO004A02C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ���_�ʉc�Ɛl���ꗗ
 *                    �f�[�^�����_�ʉc�Ɛl���i�A�h�I���j�Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_004_A02_���_�ʉc�Ɛl���ꗗ�i�[
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_dept_sales_stff_data    ���_�ʉc�Ɛl���ꗗ���o                          (A-2)
 *  data_proper_check           �f�[�^�Ó����`�F�b�N                            (A-4)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N                              (A-5)
 *  chk_dept_sales_stff         ���ꋒ�_�ʉc�Ɛl�����o                          (A-6)
 *  insert_dept_sales_stff      ���_�ʉc�Ɛl���o�^                              (A-8)
 *  update_dept_sales_stff      ���_�ʉc�Ɛl���X�V                              (A-7)
 *  delete_if_data              �t�@�C���f�[�^�폜����                          (A-9)
 *  submain                     ���C�������v���V�[�W��(
 *                                �Z�[�u�|�C���g�ݒ�                            (A-3)
 *                              )
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��(
 *                                �I������                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-17    1.0   kyo     �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO004A02C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
--
  -- ���b�Z�[�W�R�[�h
  -- ���������G���[
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00428';  -- �N�x���擾�G���[
  -- �f�[�^�����G���[�i�t�@�C���A�b�v���[�hI/F�e�[�u���j
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';  -- ���b�N�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00259';  -- �f�[�^���o�G���[(�t�@�C���A�b�v���[�hI/F�e�[�u��)
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  -- �f�[�^�`�F�b�N�G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00262';  -- ���_�ʉc�Ɛl���ꗗ�t�H�[�}�b�g�`�F�b�N�G���[
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00265';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00266';  -- ���p�p���`�F�b�N�G���[
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00267';  -- �T�C�Y�`�F�b�N�G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00263';  -- DATE�^�`�F�b�N�G���[
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00429';  -- �N�x�s��v�`�F�b�N�G���[
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00264';  -- �N�x���`�F�b�N�G���[
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00268';  -- �}�C�i�X�l�G���[
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00261';  -- �}�X�^�`�F�b�N�G���[
  -- �f�[�^�����G���[�i���_�ʉc�Ɛl���j
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00258';  -- ���b�N�G���[
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00260';  -- ���_�ʉc�Ɛl���f�[�^���o�G���[
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00427';  -- �f�[�^�o�^�G���[
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00269';  -- �f�[�^�X�V�G���[
--
  -- �R���J�����g�p�����[�^�֘A
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �p�����[�^�t�@�C��ID
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �p�����[�^�o��CSV�t�@�C����
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �t�@�C���A�b�v���[�h���̒��o�G���[
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_number_24       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �p�����[�^�t�H�[�}�b�g�p�^�[��
--
  cv_tkn_number_25       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00497';  -- AFF����}�X�^�r���[���o�G���[
--
  -- �g�[�N���R�[�h
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';  
  cv_tkn_loc             CONSTANT VARCHAR2(20) := 'LOCATION';
  cv_tkn_year_month      CONSTANT VARCHAR2(20) := 'YEARMONTH';  
  cv_tkn_eigyo           CONSTANT VARCHAR2(20) := 'EIGYO';
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_cur_year        CONSTANT VARCHAR2(20) := 'CURRENT_YEAR';
  cv_tkn_item_value      CONSTANT VARCHAR2(20) := 'ITEM_VALUE';
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '���_�ʉc�Ɛl���ꗗ�𒊏o���܂����B';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'ln_business_year = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '�t�@�C���f�[�^�폜���܂����B';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := '���[���o�b�N���܂����B';
--
  -- CSV�t�@�C�����̍��ڏ���
  cn_fscl_year_num       CONSTANT NUMBER       := 1;                  -- �N�x
  cn_year_mnth_num       CONSTANT NUMBER       := 2;                  -- �N��
  cn_base_code_num       CONSTANT NUMBER       := 3;                  -- ���_�R�[�h
  cn_sales_sff_num       CONSTANT NUMBER       := 5;                  -- �c�Ɛl��
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���_�ʉc�Ɛl����񒊏o�f�[�^�\����
  TYPE g_dept_sales_stff_rtype IS RECORD(
     fiscal_year            xxcso_dept_sales_staffs.fiscal_year%TYPE   -- �N�x
    ,year_month             xxcso_dept_sales_staffs.year_month%TYPE    -- �N��
    ,base_code              xxcso_dept_sales_staffs.base_code%TYPE     -- ���_�R�[�h
    ,sales_staff            xxcso_dept_sales_staffs.sales_staff%TYPE   -- �c�Ɛl��
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �V�K�o�^�t���O(TRUE�F�o�^�AFALSE�F�X�V)
  gb_insert_process_flg    BOOLEAN;
  -- ���[���o�b�N���f
  gb_rollback_upd_flg      BOOLEAN;
  -- �t�@�C���f�[�^
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;
  -- ���_�ʉc�Ɛl����񒊏o
  g_dept_sales_stff_rec    g_dept_sales_stff_rtype;
  -- �t�@�C��ID
  gt_file_id               xxccp_mrp_file_ul_interface.file_id%TYPE;
  -- �t�H�[�}�b�g�p�^�[�� 
  gv_fmt_ptn               VARCHAR2(20);
--  
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_error_expt   EXCEPTION;  -- �X�L�b�v��O
  global_lock_expt         EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     od_process_date            OUT NOCOPY DATE       -- �Ɩ��������t
    ,on_process_year            OUT NOCOPY NUMBER     -- ���ݔN�x
    ,ov_errbuf                  OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
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
    cv_dept_sales_lookup_code   CONSTANT VARCHAR2(30)  := '610';
    -- *** ���[�J���ϐ� ***
    lv_file_upload_nm           VARCHAR2(30);                   -- �t�@�C���A�b�v���[�h����
    lv_current_yymm             VARCHAR2(10);                   -- ���݂̔N��
    ld_process_date             DATE;                           -- �V�X�e�����t
    ln_business_year            gl_periods.period_year%TYPE;    -- �N�x
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_noprm_msg                VARCHAR2(5000);  
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
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_20           -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_file_id             -- �g�[�N���R�[�h1
                ,iv_token_value1 => TO_CHAR(gt_file_id)        -- �g�[�N���l1
              );
--
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
    -- �t�@�C��ID���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_24        -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_fmt_ptn          -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_fmt_ptn              -- �g�[�N���l1
                 );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
    -- �t�H�[�}�b�g�p�^�[�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) || 
                 '' 
    );
--
    -- ���̓p�����[�^�t�@�C��ID��NULL�`�F�b�N
    IF (gt_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01      -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
--
      RAISE global_process_expt;
    END IF;
--
    -- �Ɩ��������t�擾���� 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg4 || CHR(10) ||
                 cv_debug_msg5 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_02            -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    od_process_date := ld_process_date;
--
    BEGIN
      -- �t�@�C���A�b�v���[�h���̒��o
      lv_file_upload_nm := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_file_upload_lookup_type
                          ,cv_dept_sales_lookup_code
                          ,ld_process_date);
      IF (lv_file_upload_nm IS NULL) THEN
        RAISE global_process_expt;
      END IF;
     -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
      lv_noprm_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_23       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_file_upload_nm      -- �g�[�N���l1
                   );
--
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => lv_noprm_msg || CHR(10) || 
                   '' 
      );
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_noprm_msg || CHR(10) || 
                   '' 
      );
--
    EXCEPTION
      -- �t�@�C���A�b�v���[�h���̒��o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_22    -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
    BEGIN
      lv_current_yymm  := TO_CHAR(ld_process_date, 'YYYYMM');
      -- ���ݔN�x���擾���܂��B
      ln_business_year := xxcso_util_common_pkg.get_business_year(
                           lv_current_yymm
                         );
      IF (ln_business_year IS NULL) THEN
        RAISE global_process_expt;
      END IF;
      on_process_year  := ln_business_year;
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg2 || TO_CHAR(ln_business_year) || CHR(10) ||
                   ''
      );
--
    EXCEPTION
      -- ���ݔN�x���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_year_month      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_current_yymm        -- �g�[�N���l1
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
   * Procedure Name   : get_dept_sales_stff_data
   * Description      : ���_�ʉc�Ɛl���ꗗ���o���� (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_dept_sales_stff_data(
     ov_errbuf           OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dept_sales_stff_data';     -- �v���O������
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
    -- �p�����[�^�o��CSV�t�@�C�������b�Z�[�W�i�[�p
    lv_noprm_msg                VARCHAR2(5000);  
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
                       ,iv_name         => cv_tkn_number_04     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05     -- ���b�Z�[�W�R�[�h
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
                     ,iv_name         => cv_tkn_number_05       -- ���b�Z�[�W�R�[�h
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
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 ''
    );
--
    -- CSV�t�@�C�������b�Z�[�W
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_21          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_csv_file_nm        -- �g�[�N���R�[�h1
                  ,iv_token_value1 => lt_file_name              -- �g�[�N���l1
                 );
--
    -- CSV�t�@�C�������b�Z�[�W�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''
    );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''
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
  END get_dept_sales_stff_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : �f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_base_value         IN  VARCHAR2                 -- ���Y�s�f�[�^
    ,in_process_year       IN  NUMBER                   -- ���ݔN�x
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
    cn_format_col_cnt      CONSTANT NUMBER        := 5;           -- ���ڐ�
    cn_byte_fscl_year      CONSTANT NUMBER        := 4;           -- �N�x�o�C�g��
    cn_byte_year_mnth      CONSTANT NUMBER        := 6;           -- �N���o�C�g��
    cn_byte_base_code      CONSTANT NUMBER        := 4;           -- ���_�R�[�h�o�C�g��
    cn_byte_sales_sff      CONSTANT NUMBER        := 3;           -- �c�Ɛl��
    cv_date_fmt            CONSTANT VARCHAR2(100) := 'YYYY/MM';   -- DATE�^
    cv_fiscal_year         CONSTANT VARCHAR2(100) := '�N�x';      -- �N�x
    cv_year_month          CONSTANT VARCHAR2(100) := '�N��';      -- �N��
    cv_base_code           CONSTANT VARCHAR2(100) := '���_�R�[�h'; -- ���_�R�[�h
    cv_sales_staff         CONSTANT VARCHAR2(100) := '�c�Ɛl��';   -- �c�Ɛl��
--
    -- *** ���[�J���ϐ� ***
    lv_fiscal_year         VARCHAR2(100);                              -- �N�x
    lv_year_month          VARCHAR2(100);                              -- �N��
    lv_base_code           VARCHAR2(100);                              -- ���_�R�[�h
    ln_sales_staff         NUMBER;                                     -- �c�Ɛl��
    lv_sales_staff         VARCHAR2(100);                              -- �c�Ɛl��
    lv_item_nm             VARCHAR2(100);                              -- �Y�����ږ�
    ln_year                NUMBER;                                     -- (CSV)�N���̔N
    lb_return              BOOLEAN;                                    -- ���^�[���X�e�[�^�X
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
                       ,iv_name         => cv_tkn_number_07   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_base_val    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_base_value      -- �g�[�N���l1
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_skip_error_expt;
    END IF;
--
    -- 2.�K�{���ڂ�NULL�`�F�b�N
    lv_fiscal_year := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_fscl_year_num), '"');
    lv_year_month  := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_year_mnth_num), '"');
    lv_base_code   := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_base_code_num), '"');
    lv_sales_staff := REPLACE(xxccp_common_pkg.char_delim_partition(
                                iv_base_value, cv_comma, cn_sales_sff_num), '"');
--
    lb_return  := TRUE;
    lv_item_nm := '';
--
    IF lv_fiscal_year IS NULL THEN
      -- �N�x
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF lv_year_month IS NULL THEN
      -- �N��
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF lv_base_code IS NULL THEN
      -- ���_�R�[�h
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF lv_sales_staff IS NULL THEN
      -- �c�Ɛl��
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
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
    -- 3. �T�C�Y�`�F�b�N
    IF (LENGTHB(lv_fiscal_year) <> cn_byte_fscl_year) THEN
      -- �N�x
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF (LENGTHB(lv_year_month) <> cn_byte_year_mnth) THEN
      -- �N��
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF (LENGTHB(lv_base_code) <> cn_byte_base_code) THEN
      -- ���_�R�[�h
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF (LENGTHB(lv_sales_staff) > cn_byte_sales_sff) THEN
      -- �c�Ɛl��
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
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
    -- 4. ���p���l�^�`�F�b�N
    IF (xxccp_common_pkg.chk_number(lv_fiscal_year) = FALSE) THEN
      -- �N�x
      lb_return  := FALSE;
      lv_item_nm := cv_fiscal_year;
    ELSIF (xxccp_common_pkg.chk_number(lv_year_month) = FALSE) THEN
      -- �N��
      lb_return  := FALSE;
      lv_item_nm := cv_year_month;
    ELSIF (xxccp_common_pkg.chk_number(lv_base_code) = FALSE) THEN
      -- ���_�R�[�h
      lb_return  := FALSE;
      lv_item_nm := cv_base_code;
    ELSIF (xxccp_common_pkg.chk_number(lv_sales_staff) = FALSE) THEN
      -- �c�Ɛl��
      lb_return  := FALSE;
      lv_item_nm := cv_sales_staff;
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
    -- 5. ���t�����`�F�b�N
    -- �N��
    IF (xxcso_util_common_pkg.check_date(lv_year_month, cv_date_fmt) = FALSE) THEN
     lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_11   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_year_month  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_year_month      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    -- 6. �N�x�s��v�`�F�b�N
    IF (TO_CHAR(in_process_year) <> lv_fiscal_year) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_cur_year    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => TO_CHAR(in_process_year)     -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_val    -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_base_value      -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    -- 7. �N�x�E�N���������`�F�b�N
    BEGIN
      ln_year := xxcso_util_common_pkg.get_business_year(
                   lv_year_month
                 ); 
      IF (ln_year IS NULL) THEN
        RAISE global_skip_error_expt;
      END IF;
--      
    EXCEPTION
      -- �N������N�x���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_year_month      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_year_month          -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_skip_error_expt;
    END;
--    
    -- �N�x�ƔN������̔N�x����v���Ȃ��ꍇ
    IF (TO_CHAR(ln_year) <> lv_fiscal_year) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_13   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_base_val    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_base_value      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
--
    ln_sales_staff := TO_CHAR(lv_sales_staff);
    -- �s�P�ʃf�[�^�����R�[�h�ɃZ�b�g
    g_dept_sales_stff_rec.fiscal_year      := lv_fiscal_year;   -- �N�x
    g_dept_sales_stff_rec.year_month       := lv_year_month;    -- �N��
    g_dept_sales_stff_rec.base_code        := lv_base_code;     -- ���_�R�[�h
    g_dept_sales_stff_rec.sales_staff      := ln_sales_staff;   -- �c�Ɛl��
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
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : �}�X�^���݃`�F�b�N (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     id_process_date       IN  DATE             -- �Ɩ��������t 
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
    cv_item_nm             CONSTANT VARCHAR2(100) := '���_�R�[�h';
    cv_aff_mst_v_nm        CONSTANT VARCHAR2(100) := 'AFF����}�X�^�r���[';
    -- *** ���[�J���ϐ� ***
    ld_process_date        DATE;
    lv_base_code_value     VARCHAR2(4);           -- ���_�R�[�h
    ln_count               NUMBER;                -- ���_�R�[�h�J�E���g�p�ϐ�(AFF�}�X�^�r���[�`�F�b�N)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ld_process_date    := TRUNC(id_process_date);
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- �}�X�^���݃`�F�b�N--
    BEGIN
      SELECT COUNT(xabv.base_code)  base_code_num          -- ���_�R�[�h���J�E���g
      INTO   ln_count                                      -- ���_�R�[�h�J�E���g�p�ϐ�
      FROM   xxcso_aff_base_v xabv                         -- AFF����}�X�^�r���[
      WHERE  xabv.base_code = lv_base_code_value
        AND NVL(xabv.start_date_active,ld_process_date) <= ld_process_date
              AND NVL(xabv.end_date_active,ld_process_date) >= ld_process_date
        ;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                       -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_25                  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_aff_mst_v_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item                       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_base_code_value                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                           -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    IF (ln_count = 0) THEN
    -- ���o������0���̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_15                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_item_nm                          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_tbl                          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_aff_mst_v_nm                     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_value                   -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_base_code_value                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_skip_error_expt;
    END IF;
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
   * Procedure Name   : chk_dept_sales_stff
   * Description      : ���ꋒ�_�ʉc�Ɛl�����o���� (A-6)
   ***********************************************************************************/
--
  PROCEDURE chk_dept_sales_stff(
     on_count              OUT NOCOPY NUMBER    -- ���ꋒ�_�ʉc�Ɛl�����o����
    ,ov_errbuf             OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'chk_dept_sales_stff';  -- �v���O������
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
    cv_base_code_nm        CONSTANT VARCHAR2(100) := '���_�R�[�h';
    cv_fscl_year_nm        CONSTANT VARCHAR2(100) := '�N��';
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '���_�ʉc�Ɛl���e�[�u��';
    -- *** ���[�J���ϐ� ***
    lv_year_mnth_value     VARCHAR2(6);           -- �N��
    lv_base_code_value     VARCHAR2(4);           -- ���_�R�[�h
    ln_count               NUMBER;                -- ���_�R�[�h�J�E���g�p�ϐ�(���_�ʉc�Ɛl���e�[�u���`�F�b�N)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--    
    -- ���_�ʉc�Ɛl���f�[�^���o
    BEGIN
--  
      SELECT COUNT(xdss.base_code)  base_code_num          -- ���_�R�[�h���J�E���g
      INTO   ln_count
      FROM   xxcso_dept_sales_staffs xdss                  -- ���_�ʉc�Ɛl���e�[�u��
      WHERE  xdss.base_code  = lv_base_code_value
        AND  xdss.year_month = lv_year_mnth_value
        ;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_17     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_loc           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_base_code_value   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year_month    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_year_mnth_value   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg       -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM              -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
--
    on_count := ln_count;
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
  END chk_dept_sales_stff;
--
  /**********************************************************************************
   * Procedure Name   : insert_dept_sales_stff
   * Description      : ���_�ʉc�Ɛl���o�^ (A-8)
   ***********************************************************************************/
--
  PROCEDURE insert_dept_sales_stff(
     ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'insert_dept_sales_stff';     -- �v���O������
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
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '���_�ʉc�Ɛl���e�[�u��';
    -- *** ���[�J���ϐ� ***
    lv_year_mnth_value     VARCHAR2(6);           -- �N��
    lv_base_code_value     VARCHAR2(4);           -- ���_�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- =======================
    -- ���_�ʉc�Ɛl���f�[�^�o�^ 
    -- =======================
    BEGIN
      INSERT INTO xxcso_dept_sales_staffs  -- ���_�ʉc�Ɛl���e�[�u��
        ( year_month              -- �N��
         ,base_code               -- ���_�R�[�h
         ,fiscal_year             -- �N�x
         ,sales_staff             -- �c�Ɛl��
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
        ( g_dept_sales_stff_rec.year_month
         ,g_dept_sales_stff_rec.base_code        
         ,g_dept_sales_stff_rec.fiscal_year
         ,g_dept_sales_stff_rec.sales_staff
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
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_18     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_loc           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_base_code_value   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year_month    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_year_mnth_value   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg       -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM              -- �g�[�N���l4
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
  END insert_dept_sales_stff;
--
  /**********************************************************************************
   * Procedure Name   : update_dept_sales_stff
   * Description      : ���_�ʉc�Ɛl���e�[�u���f�[�^�X�V (A-7)
   ***********************************************************************************/
--
  PROCEDURE update_dept_sales_stff(
     ov_errbuf             OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100)   := 'update_dept_sales_stff';     -- �v���O������
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
    cv_dept_sales_stff_nm  CONSTANT VARCHAR2(100) := '���_�ʉc�Ɛl���e�[�u��';
    -- *** ���[�J���ϐ� ***
    lv_year_mnth_value     VARCHAR2(6);           -- �N��
    lv_base_code_value     VARCHAR2(4);           -- ���_�R�[�h
    lv_base_code_loc       VARCHAR2(4);           -- ���_�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--    
    lv_year_mnth_value := g_dept_sales_stff_rec.year_month;
    lv_base_code_value := g_dept_sales_stff_rec.base_code;
--
    -- ���_�ʉc�Ɛl���f�[�^���b�N 
    BEGIN
--  
      SELECT xdss.base_code base_code                      -- ���_�R�[�h
      INTO   lv_base_code_loc
      FROM   xxcso_dept_sales_staffs xdss                  -- ���_�ʉc�Ɛl���e�[�u��
      WHERE  xdss.base_code  = lv_base_code_value
        AND  xdss.year_month = lv_year_mnth_value
      FOR UPDATE NOWAIT;  -- �e�[�u�����b�N
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_loc           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_base_code_value   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_year_month    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_year_mnth_value   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_17     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_loc           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_base_code_value   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year_month    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_year_mnth_value   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg       -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM              -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_skip_error_expt;
    END;
    -- ================================
    -- ���_�ʉc�Ɛl���e�[�u���f�[�^�X�V 
    -- ================================
--
    BEGIN
--   
      UPDATE xxcso_dept_sales_staffs xdss                        -- ���_�ʉc�Ɛl���e�[�u��
      SET    fiscal_year             =  g_dept_sales_stff_rec.fiscal_year  -- �N�x
            ,sales_staff             =  g_dept_sales_stff_rec.sales_staff  -- �c�Ɛl��
            ,last_updated_by         =  cn_last_updated_by           -- �ŏI�X�V��
            ,last_update_date        =  cd_last_update_date          -- �ŏI�X�V��
            ,last_update_login       =  cn_last_update_login         -- �ŏI�X�V���O�C��
            ,request_id              =  cn_request_id                -- �v��ID
            ,program_application_id  =  cn_program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id              =  cn_program_id                -- �R���J�����g�E�v���O����ID
            ,program_update_date     =  cd_program_update_date       -- �v���O�����X�V��
      WHERE  xdss.base_code  = lv_base_code_value
      AND    xdss.year_month = lv_year_mnth_value;
    
--
    EXCEPTION
      -- �X�V�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dept_sales_stff_nm-- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_loc           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_base_code_value   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_year_month    -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_year_mnth_value   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg       -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM              -- �g�[�N���l4
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
  END update_dept_sales_stff;
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
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   '' 
      );
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06     -- ���b�Z�[�W�R�[�h
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
    -- *** ���[�J���萔 ***
    cn_no_data        CONSTANT NUMBER := 0;   -- �f�[�^�Ȃ� 
    -- *** ���[�J���ϐ� ***
    lv_base_value     VARCHAR2(5000);         -- ���Y�s�f�[�^
    ln_count_process  NUMBER;                 -- ���o����
    ln_process_year   NUMBER;                 -- ���ݔN�x
    ld_process_date   DATE;                   -- �Ɩ��������t
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
       od_process_date  => ld_process_date     -- �Ɩ��������t
      ,on_process_year  => ln_process_year     -- ���ݔN�x
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--

    -- ========================================
    -- A-2.���_�ʉc�Ɛl���ꗗ���o���� 
    -- ========================================
    get_dept_sales_stff_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���f�[�^���[�v
    <<dept_sales_stff_data>>
    FOR i IN 1..g_file_data_tab.COUNT LOOP
--
      BEGIN
--
        -- ���R�[�h�N���A
        g_dept_sales_stff_rec := NULL;

        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;

        lv_base_value := g_file_data_tab(i);
--
        -- =======================
        -- A-3.�Z�[�u�|�C���g�ݒ�
        -- =======================
        SAVEPOINT dept_sales_stff;
--
        -- =================================================
        -- A-4.�f�[�^�Ó����`�F�b�N (���R�[�h�Ƀf�[�^�Z�b�g)
        -- =================================================
        data_proper_check(
           iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
          ,in_process_year  => ln_process_year  -- ���ݔN�x
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
        -- A-5.�}�X�^���݃`�F�b�N 
        -- =============================
        chk_mst_is_exists(
           id_process_date  => ld_process_date  -- �Ɩ��������t
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
        -- ===============================
        -- A-6.���ꋒ�_�ʉc�Ɛl�����o���� 
        -- ===============================
--
        -- ���ꋒ�_�ʉc�Ɛl�����o����������
        ln_count_process := 0;
--        
        chk_dept_sales_stff(
           on_count         => ln_count_process -- ���ꋒ�_�ʉc�Ɛl�����o����
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
        -- �V�K�o�^�t���O��TRUE�̏ꍇ
        IF (ln_count_process = cn_no_data) THEN
--
          -- ===============================
          -- A-8.���_�ʉc�Ɛl���o�^���� 
          -- ===============================
          insert_dept_sales_stff(
             ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_skip_error_expt;
          END IF;
        -- �V�K�o�^�t���O��FALSE�̏ꍇ
        ELSE
          -- ===============================
          -- A-7.���_�ʉc�Ɛl���X�V���� 
          -- ===============================
          update_dept_sales_stff(
             ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            gb_rollback_upd_flg := TRUE;
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
          lv_retcode   := cv_status_warn;
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
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--
        --*** ���������ʗ�O�n���h�� ***
        WHEN global_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
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
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--        
        -- *** �X�L�b�v��OOTHERS�n���h�� ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
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
          IF gb_rollback_upd_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT dept_sales_stff;    -- ROLLBACK
            gb_rollback_upd_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_debug_msg6|| CHR(10) ||
                         ''
            );
          END IF;
--
      END;
--
    END LOOP dept_sales_stff_data;
--
    ov_retcode := lv_retcode;                -- ���^�[���E�R�[�h
--
    -- =============================
    -- A-9.�t�@�C���f�[�^�폜���� 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
    ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
    ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
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
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
--
    END IF;
--
    -- =======================
    -- A-10.�I������ 
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
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6 || CHR(10) ||
                   ''
      );
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
END XXCSO004A02C;
/
