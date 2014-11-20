CREATE OR REPLACE PACKAGE BODY XXCSM001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A03C(body)
 * Description      : �̔��v��e�[�u���ɓo�^���ꂽ�����Ώۗ\�Z�N�x�̃f�[�^�𒊏o���A
 *                  : CSV�`���̃t�@�C�����쐬���܂��B
 *                  : �쐬����CSV�t�@�C��������̃t�H���_�Ɋi�[���܂��B
 * MD.050           : MD050_CSM_001_A03_�N�Ԍv����n�V�X�e��IF
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  open_csv_file          �t�@�C���I�[�v������ (A-2)
 *  create_csv_rec         �̔��v��f�[�^�������� (A-4)
 *  close_csv_file         �N�Ԍv��IF�t�@�C���N���[�Y�������� (A-5)
 *  submain                ���C�������v���V�[�W��
 *                           �̔��v��f�[�^���o���� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-01    1.0   M.Ohtsuki       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- �Ώی���
  gn_normal_cnt             NUMBER;                                                                 -- ���팏��
  gn_error_cnt              NUMBER;                                                                 -- �G���[����
  gn_warn_cnt               NUMBER;                                                                 -- �X�L�b�v����
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM001A03C';                                 -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_xxccp_msg_008        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_xxcsm_msg_001        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00001';                             -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_xxcsm_msg_002        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00002';                             -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_xxcsm_msg_003        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00003';                             -- �t�@�C���N���[�Y�G���[���b�Z�[�W
  cv_xxcsm_msg_019        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00019';                             -- ���n�V�X�e���A�g�Ώۖ����G���[���b�Z�[�W
  cv_xxcsm_msg_021        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                             -- �N�x�擾�G���[���b�Z�[�W
  cv_xxcsm_msg_031        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00031';                             -- ������s�p�v���t�@�C���擾�G���[���b�Z�[�W
  cv_xxcsm_msg_084        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                             -- �C���^�[�t�F�[�X�t�@�C����
  --�v���t�@�C����
  cv_file_dir             CONSTANT VARCHAR2(100) := 'XXCSM1_INFOSYS_FILE_DIR';                      -- ���n�f�[�^�t�@�C���쐬�f�B���N�g��
  cv_file_name            CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_FILE_NAME';                    -- �N�Ԍv��f�[�^�t�@�C����
  -- �g�[�N���R�[�h
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_directory        CONSTANT VARCHAR2(20) := 'DIRECTORY';
  cv_tkn_file_name        CONSTANT VARCHAR2(20) := 'FILE_NAME';
  cv_tkn_sql_code         CONSTANT VARCHAR2(20) := 'SQL_CODE';
  cv_tkn_yyyymm           CONSTANT VARCHAR2(20) := 'YYYYMM';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand            UTL_FILE.FILE_TYPE;
  gv_file_dir             VARCHAR2(100);
  gv_file_name            VARCHAR2(100);
  gv_obj_year             VARCHAR2(100);
  gd_sysdate              DATE;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
    company_cd                   VARCHAR2(3)                                                        -- ��ЃR�[�h
   ,plan_year                    xxcsm_sales_plan.plan_year%TYPE                                    -- �N�x
   ,plan_ym                      xxcsm_sales_plan.plan_ym%TYPE                                      -- �N��
   ,location_cd                  xxcsm_sales_plan.location_cd%TYPE                                  -- ���_�i����j�R�[�h
   ,act_work_date                xxcsm_sales_plan.act_work_date%TYPE                                -- ������
   ,plan_staff                   xxcsm_sales_plan.plan_staff%TYPE                                   -- �v��l��
   ,sale_plan_depart             xxcsm_sales_plan.sale_plan_depart%TYPE                             -- �ʔ̓X
   ,sale_plan_cvs                xxcsm_sales_plan.sale_plan_cvs%TYPE                                -- �b�u�r
   ,sale_plan_dealer             xxcsm_sales_plan.sale_plan_dealer%TYPE                             -- �≮
   ,sale_plan_others             xxcsm_sales_plan.sale_plan_others%TYPE                             -- ���̑�
   ,sale_plan_vendor             xxcsm_sales_plan.sale_plan_vendor%TYPE                             -- �x���_�[
   ,sale_plan_total              xxcsm_sales_plan.sale_plan_total%TYPE                              -- ���㍇�v
   ,sale_plan_spare_1            xxcsm_sales_plan.sale_plan_spare_1%TYPE                            -- �Ƒԕʔ���v��i�\���P�j
   ,sale_plan_spare_2            xxcsm_sales_plan.sale_plan_spare_2%TYPE                            -- �Ƒԕʔ���v��i�\���Q�j
   ,sale_plan_spare_3            xxcsm_sales_plan.sale_plan_spare_3%TYPE                            -- �Ƒԕʔ���v��i�\���R�j
   ,ly_revision_depart           xxcsm_sales_plan.ly_revision_depart%TYPE                           -- �O�N���яC���i�ʔ̓X�j
   ,ly_revision_cvs              xxcsm_sales_plan.ly_revision_cvs%TYPE                              -- �O�N���яC���i�b�u�r�j
   ,ly_revision_dealer           xxcsm_sales_plan.ly_revision_dealer%TYPE                           -- �O�N���яC���i�≮�j
   ,ly_revision_others           xxcsm_sales_plan.ly_revision_others%TYPE                           -- �O�N���яC���i���̑��j
   ,ly_revision_vendor           xxcsm_sales_plan.ly_revision_vendor%TYPE                           -- �O�N���яC���i�x���_�[�j
   ,ly_revision_spare_1          xxcsm_sales_plan.ly_revision_spare_1%TYPE                          -- �O�N���яC���i�\���P�j
   ,ly_revision_spare_2          xxcsm_sales_plan.ly_revision_spare_2%TYPE                          -- �O�N���яC���i�\���Q�j
   ,ly_revision_spare_3          xxcsm_sales_plan.ly_revision_spare_3%TYPE                          -- �O�N���яC���i�\���R�j
   ,ly_exist_total               xxcsm_sales_plan.ly_exist_total%TYPE                               -- ��N�����q�i�S�́j
   ,ly_newly_total               xxcsm_sales_plan.ly_newly_total%TYPE                               -- ��N�V�K�q�i�S�́j
   ,ty_first_total               xxcsm_sales_plan.ty_first_total%TYPE                               -- �{�N�V�K����i�S�́j
   ,ty_turn_total                xxcsm_sales_plan.ty_turn_total%TYPE                                -- �{�N�V�K��]�i�S�́j
   ,discount_total               xxcsm_sales_plan.discount_total%TYPE                               -- �����l���i�S�́j
   ,ly_exist_vd_charge           xxcsm_sales_plan.ly_exist_vd_charge%TYPE                           -- ��N�����q�i�u�c�j�S��
   ,ly_newly_vd_charge           xxcsm_sales_plan.ly_newly_vd_charge%TYPE                           -- ��N�V�K�q�i�u�c�j�S��
   ,ty_first_vd_charge           xxcsm_sales_plan.ty_first_vd_charge%TYPE                           -- �{�N�V�K����i�u�c�j�S��
   ,ty_turn_vd_charge            xxcsm_sales_plan.ty_turn_vd_charge%TYPE                            -- �{�N�V�K��]�i�u�c�j�S��
   ,ty_first_vd_get              xxcsm_sales_plan.ty_first_vd_get%TYPE                              -- �{�N�V�K����i�u�c�j�l��
   ,ty_turn_vd_get               xxcsm_sales_plan.ty_turn_vd_get%TYPE                               -- �{�N�V�K��]�i�u�c�j�l��
   ,st_mon_get_total             xxcsm_sales_plan.st_mon_get_total%TYPE                             -- ����ڋq���i�S�́j�l��
   ,newly_get_total              xxcsm_sales_plan.newly_get_total%TYPE                              -- �V�K�����i�S�́j�l��
   ,cancel_get_total             xxcsm_sales_plan.cancel_get_total%TYPE                             -- ���~�����i�S�́j�l��
   ,newly_charge_total           xxcsm_sales_plan.newly_charge_total%TYPE                           -- �V�K�����i�S�́j�S��
   ,st_mon_get_vd                xxcsm_sales_plan.st_mon_get_vd%TYPE                                -- ����ڋq���i�u�c�j�l��
   ,newly_get_vd                 xxcsm_sales_plan.newly_get_vd%TYPE                                 -- �V�K�����i�u�c�j�l��
   ,cancel_get_vd                xxcsm_sales_plan.cancel_get_vd%TYPE                                -- ���~�����i�u�c�j�l��
   ,newly_charge_vd_own          xxcsm_sales_plan.newly_charge_vd_own%TYPE                          -- ���͐V�K�����i�u�c�j�S��
   ,newly_charge_vd_help         xxcsm_sales_plan.newly_charge_vd_help%TYPE                         -- ���͐V�K�����i�u�c�j�S��
   ,cancel_charge_vd             xxcsm_sales_plan.cancel_charge_vd%TYPE                             -- ���~�����i�u�c�j�S��
   ,patrol_visit_cnt             xxcsm_sales_plan.patrol_visit_cnt%TYPE                             -- ����K��ڋq��
   ,patrol_def_visit_cnt         xxcsm_sales_plan.patrol_def_visit_cnt%TYPE                         -- ���񉄖K�⌬��
   ,vendor_visit_cnt             xxcsm_sales_plan.vendor_visit_cnt%TYPE                             -- �x���_�[�K��ڋq��
   ,vendor_def_visit_cnt         xxcsm_sales_plan.vendor_def_visit_cnt%TYPE                         -- �x���_�[���K�⌬��
   ,public_visit_cnt             xxcsm_sales_plan.public_visit_cnt%TYPE                             -- ��ʖK��ڋq��
   ,public_def_visit_cnt         xxcsm_sales_plan.public_def_visit_cnt%TYPE                         -- ��ʉ��K�⌬��
   ,def_cnt_total                xxcsm_sales_plan.def_cnt_total%TYPE                                -- ���K�⌬�����v
   ,vend_machine_sales_plan      xxcsm_sales_plan.vend_machine_sales_plan%TYPE                      -- ���̋@����
   ,vend_machine_margin          xxcsm_sales_plan.vend_machine_margin%TYPE                          -- �e���v
   ,vend_machine_bm              xxcsm_sales_plan.vend_machine_bm%TYPE                              -- ���̋@�萔���i�a�l�j
   ,vend_machine_elect           xxcsm_sales_plan.vend_machine_elect%TYPE                           -- ���̋@�萔���i�d�C��j
   ,vend_machine_lease           xxcsm_sales_plan.vend_machine_lease%TYPE                           -- ���̋@���[�X��
   ,vend_machine_manage          xxcsm_sales_plan.vend_machine_manage%TYPE                          -- ���̋@�ێ��Ǘ���
   ,vend_machine_sup_money       xxcsm_sales_plan.vend_machine_sup_money%TYPE                       -- ���^��
   ,vend_machine_total           xxcsm_sales_plan.vend_machine_total%TYPE                           -- ��p���v
   ,vend_machine_profit          xxcsm_sales_plan.vend_machine_profit%TYPE                          -- ���_���̋@���v
   ,deficit_num                  xxcsm_sales_plan.deficit_num%TYPE                                  -- �Ԏ��䐔
   ,par_machine                  xxcsm_sales_plan.par_machine%TYPE                                  -- �p�[�}�V��
   ,possession_num               xxcsm_sales_plan.possession_num%TYPE                               -- �ۗL�䐔
   ,stock_num                    xxcsm_sales_plan.stock_num%TYPE                                    -- �݌ɑ䐔
   ,operation_num                xxcsm_sales_plan.operation_num%TYPE                                -- �ғ��䐔
   ,increase                     xxcsm_sales_plan.increase%TYPE                                     -- ����
   ,new_setting_own              xxcsm_sales_plan.new_setting_own%TYPE                              -- �V�K�ݒu�i���́j
   ,new_setting_help             xxcsm_sales_plan.new_setting_help%TYPE                             -- �V�K�ݒu�i���́j
   ,new_setting_total            xxcsm_sales_plan.new_setting_total%TYPE                            -- �V�K�ݒu���v
   ,withdraw_num                 xxcsm_sales_plan.withdraw_num%TYPE                                 -- �P�ƈ��g
   ,new_num_newly                xxcsm_sales_plan.new_num_newly%TYPE                                -- �V��i�V�K�j
   ,new_num_replace              xxcsm_sales_plan.new_num_replace%TYPE                              -- �V��i��ցj
   ,new_num_total                xxcsm_sales_plan.new_num_total%TYPE                                -- �V�䍇�v
   ,old_num_newly                xxcsm_sales_plan.old_num_newly%TYPE                                -- ����i�V�K�j
   ,old_num_replace              xxcsm_sales_plan.old_num_replace%TYPE                              -- ����i��ցE�ڐ݁j
   ,disposal_num                 xxcsm_sales_plan.disposal_num%TYPE                                 -- �p��
   ,enter_num                    xxcsm_sales_plan.enter_num%TYPE                                    -- ���_�ԁi�ړ��j
   ,appear_num                   xxcsm_sales_plan.appear_num%TYPE                                   -- ���_�ԁi�ڏo�j
   ,vend_machine_plan_spare_1    xxcsm_sales_plan.vend_machine_plan_spare_1%TYPE                    -- �����̔��@�v��i�\���P�j
   ,vend_machine_plan_spare_2    xxcsm_sales_plan.vend_machine_plan_spare_2%TYPE                    -- �����̔��@�v��i�\���Q�j
   ,vend_machine_plan_spare_3    xxcsm_sales_plan.vend_machine_plan_spare_3%TYPE                    -- �����̔��@�v��i�\���R�j
   ,spare_1                      xxcsm_sales_plan.spare_1%TYPE                                      -- �\���P
   ,spare_2                      xxcsm_sales_plan.spare_2%TYPE                                      -- �\���Q
   ,spare_3                      xxcsm_sales_plan.spare_3%TYPE                                      -- �\���R
   ,spare_4                      xxcsm_sales_plan.spare_4%TYPE                                      -- �\���S
   ,spare_5                      xxcsm_sales_plan.spare_5%TYPE                                      -- �\���T
   ,spare_6                      xxcsm_sales_plan.spare_6%TYPE                                      -- �\���U
   ,spare_7                      xxcsm_sales_plan.spare_7%TYPE                                      -- �\���V
   ,spare_8                      xxcsm_sales_plan.spare_8%TYPE                                      -- �\���W
   ,spare_9                      xxcsm_sales_plan.spare_9%TYPE                                      -- �\���X
   ,spare_10                     xxcsm_sales_plan.spare_10%TYPE                                     -- �\���P�O
   ,cprtn_date                   DATE                                                               -- �A�g����
   );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);                                                                -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(4000);                                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';                                          -- �A�v���P�[�V�����Z�k��
    -- *** ���[�J���ϐ� ***
    lv_noprm_msg        VARCHAR2(4000);                                                             -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_month            VARCHAR2(100);
    lv_msg              VARCHAR2(100);
    lv_tkn_value        VARCHAR2(100);
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd            BOOLEAN;
    ln_file_size        NUMBER;
    ln_block_size       NUMBER;
    ld_process_date     DATE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_xxccp_msg_008                                         --���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    gv_file_dir   := FND_PROFILE.VALUE(cv_file_dir);
    gv_file_name  := FND_PROFILE.VALUE(cv_file_name);
    -- �N�Ԍv��f�[�^�t�@�C���������b�Z�[�W�o�͂���
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                                                     --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_xxcsm_msg_084                                                --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_file_name                                                --�g�[�N���R�[�h1
                ,iv_token_value1 => gv_file_name                                                    --�g�[�N���l1
              );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (gv_file_dir IS NULL) THEN                                                                   -- CSV�t�@�C���o�͐�擾���s��
      lv_tkn_value := cv_file_dir;
    ELSIF (gv_file_name IS NULL) THEN                                                               -- CSV�t�@�C�����擾���s��
      lv_tkn_value := cv_file_name;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg_031                                            --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prf_name                                             --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                                                --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => gv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg_001                                            --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_directory                                            --�g�[�N���R�[�h1
                    ,iv_token_value1 => gv_file_dir                                                 --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_file_name                                            --�g�[�N���R�[�h2
                    ,iv_token_value2 => gv_file_name                                                --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    gd_sysdate := SYSDATE;
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- =====================
    -- �Ώۗ\�Z�N�x�Z�o���� 
    -- =====================
    xxcsm_common_pkg.get_year_month(iv_process_years => TO_CHAR(ld_process_date,'YYYYMM')
                                   ,ov_year          => gv_obj_year
                                   ,ov_month         => lv_month
                                   ,ov_retcode       => lv_retcode
                                   ,ov_errbuf        => lv_errbuf 
                                   ,ov_errmsg        => lv_errmsg 
                                   );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg_021                                            --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_yyyymm                                               --�g�[�N���R�[�h1
                    ,iv_token_value1 => TO_CHAR(ld_process_date,'YYYYMM')                           --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : �t�@�C���I�[�v������ (A-4)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'open_csv_file';                                        -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                                               -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                                                  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_w              CONSTANT VARCHAR2(1) := 'w';                                                  -- ���� = w
    cn_max_size       CONSTANT NUMBER := 2047;                                                      -- 2047�o�C�g
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd     BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt     EXCEPTION;                                                                    -- �t�@�C��������O
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
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand := UTL_FILE.FOPEN(
                         location     => gv_file_dir                                                -- �N�Ԍv��t�@�C���f�B���N�g��
                        ,filename     => gv_file_name                                               -- �N�Ԍv��t�@�C����
                        ,open_mode    => cv_w                                                       -- ����
                        ,max_linesize => cn_max_size                                                -- 2047�o�C�g
                      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_xxcsm_msg_002                                          --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_directory                                          --�g�[�N���R�[�h1
                      ,iv_token_value1 => gv_file_dir                                               --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_file_name                                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => gv_file_name                                              --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_sql_code                                           --�g�[�N���R�[�h3
                      ,iv_token_value3 => SQLERRM                                                   --�g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : �̔��v��f�[�^�������� (A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     ir_sales_plan       IN  g_get_data_rtype                                                       -- �̔��v�撊�o�f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'create_csv_rec';                              -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com           CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot         CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data              VARCHAR2(4000);                                                            -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_sales_plan_rec     g_get_data_rtype;                                                          -- IN�p�����[�^.�N�Ԍv��f�[�^�i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_sales_plan_rec := ir_sales_plan; -- �N�Ԍv��f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
      -- �f�[�^�쐬
    lv_data := 
      cv_sep_wquot  || l_sales_plan_rec.company_cd || cv_sep_wquot                                  -- ��ЃR�[�h
      || cv_sep_com || l_sales_plan_rec.plan_year                                                   -- �N�x
      || cv_sep_com || l_sales_plan_rec.plan_ym                                                     -- �N��
      || cv_sep_com ||
      cv_sep_wquot  || l_sales_plan_rec.location_cd || cv_sep_wquot                                 -- ���_�R�[�h
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.act_work_date)                                      -- ������
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.plan_staff)                                         -- �v��l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_depart)                                   -- �ʔ̓X
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_cvs)                                      -- �b�u�r
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_dealer)                                   -- �≮
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_others)                                   -- ���̑�
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_vendor)                                   -- �x���_�[
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_total)                                    -- ���㍇�v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_1)                                  -- �Ƒԕʔ���v��i�\���P�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_2)                                  -- �Ƒԕʔ���v��i�\���Q�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.sale_plan_spare_3)                                  -- �Ƒԕʔ���v��i�\���R�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_depart)                                 -- �O�N���яC���i�ʔ̓X�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_cvs)                                    -- �O�N���яC���i�b�u�r�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_dealer)                                 -- �O�N���яC���i�≮�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_others)                                 -- �O�N���яC���i���̑��j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_vendor)                                 -- �O�N���яC���i�x���_�[�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_1)                                -- �O�N���яC���i�\���P�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_2)                                -- �O�N���яC���i�\���Q�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_revision_spare_3)                                -- �O�N���яC���i�\���R�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_exist_total)                                     -- ��N�����q�i�S�́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_newly_total)                                     -- ��N�V�K�q�i�S�́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_total)                                     -- �{�N�V�K����i�S�́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_total)                                      -- �{�N�V�K��]�i�S�́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.discount_total)                                     -- �����l���i�S�́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_exist_vd_charge)                                 -- ��N�����q�i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ly_newly_vd_charge)                                 -- ��N�V�K�q�i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_vd_charge)                                 -- �{�N�V�K����i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_vd_charge)                                  -- �{�N�V�K��]�i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_first_vd_get)                                    -- �{�N�V�K����i�u�c�j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.ty_turn_vd_get)                                     -- �{�N�V�K��]�i�u�c�j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.st_mon_get_total)                                   -- ����ڋq���i�S�́j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_get_total)                                    -- �V�K�����i�S�́j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_get_total)                                   -- ���~�����i�S�́j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_total)                                 -- �V�K�����i�S�́j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.st_mon_get_vd)                                      -- ����ڋq���i�u�c�j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_get_vd)                                       -- �V�K�����i�u�c�j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_get_vd)                                      -- ���~�����i�u�c�j�l��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_vd_own)                                -- ���͐V�K�����i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.newly_charge_vd_help)                               -- ���͐V�K�����i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cancel_charge_vd)                                   -- ���~�����i�u�c�j�S��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.patrol_visit_cnt)                                   -- ����K��ڋq��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.patrol_def_visit_cnt)                               -- ���񉄖K�⌬��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vendor_visit_cnt)                                   -- �x���_�[�K��ڋq��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vendor_def_visit_cnt)                               -- �x���_�[���K�⌬��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.public_visit_cnt)                                   -- ��ʖK��ڋq��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.public_def_visit_cnt)                               -- ��ʉ��K�⌬��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.def_cnt_total)                                      -- ���K�⌬�����v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_sales_plan)                            -- ���̋@����
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_margin)                                -- �e���v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_bm)                                    -- ���̋@�萔���i�a�l�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_elect)                                 -- ���̋@�萔���i�d�C��j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_lease)                                 -- ���̋@���[�X��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_manage)                                -- ���̋@�ێ��Ǘ���
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_sup_money)                             -- ���^��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_total)                                 -- ��p���v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_profit)                                -- ���_���̋@���v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.deficit_num)                                        -- �Ԏ��䐔
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.par_machine)                                        -- �p�[�}�V��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.possession_num)                                     -- �ۗL�䐔
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.stock_num)                                          -- �݌ɑ䐔
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.operation_num)                                      -- �ғ��䐔
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.increase)                                           -- ����
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_own)                                    -- �V�K�ݒu�i���́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_help)                                   -- �V�K�ݒu�i���́j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_setting_total)                                  -- �V�K�ݒu���v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.withdraw_num)                                       -- �P�ƈ��g
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_newly)                                      -- �V��i�V�K�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_replace)                                    -- �V��i��ցj
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.new_num_total)                                      -- �V�䍇�v
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.old_num_newly)                                      -- ����i�V�K�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.old_num_replace)                                    -- ����i��ցE�ڐ݁j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.disposal_num)                                       -- �p��
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.enter_num)                                          -- ���_�ԁi�ړ��j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.appear_num)                                         -- ���_�ԁi�ڏo�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_1)                          -- �����̔��@�v��i�\���P�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_2)                          -- �����̔��@�v��i�\���Q�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.vend_machine_plan_spare_3)                          -- �����̔��@�v��i�\���R�j
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_1)                                            -- �\���P
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_2)                                            -- �\���Q
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_3)                                            -- �\���R
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_4)                                            -- �\���S
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_5)                                            -- �\���T
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_6)                                            -- �\���U
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_7)                                            -- �\���V
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_8)                                            -- �\���W
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_9)                                            -- �\���X
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.spare_10)                                           -- �\���P�O
      || cv_sep_com || TO_CHAR(l_sales_plan_rec.cprtn_date, 'yyyymmddhh24miss');                    -- �A�g����                                                                                            -- �A�g����
    -- �f�[�^�o��
    UTL_FILE.PUT_LINE(
      file   => gf_file_hand
     ,buffer => lv_data
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : �N�Ԍv��IF�t�@�C���N���[�Y�������� (A-5)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     ov_errbuf         OUT NOCOPY VARCHAR2                                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode        OUT NOCOPY VARCHAR2                                                          -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'close_csv_file';                                  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd     BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt     EXCEPTION;                                                                    -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                                               -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_xxcsm_msg_003                                          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_file_dir                                               -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_file_dir                                               -- �g�[�N���l1
                      ,iv_token_name2  => cv_file_name                                              -- �g�[�N���R�[�h1
                      ,iv_token_value2 => gv_file_name                                              -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';                                     -- �v���O������
    cv_company_cd        CONSTANT VARCHAR2(3)     := '001';                                         -- ��ЃR�[�h
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);                                                               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(4000);                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd        BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_sales_plan_cur                                                                       -- �N�Ԍv��f�[�^�擾�J�[�\��
    IS
      SELECT    xsp.plan_year                       plan_year                                       -- �\�Z�N�x
               ,xsp.plan_ym                         plan_ym                                         -- �N��
               ,xsp.location_cd                     location_cd                                     -- ���_�R�[�h
               ,xsp.act_work_date                   act_work_date                                   -- ������
               ,xsp.plan_staff                      plan_staff                                      -- �v��l��
               ,xsp.sale_plan_depart                sale_plan_depart                                -- �ʔ̓X
               ,xsp.sale_plan_cvs                   sale_plan_cvs                                   -- �b�u�r
               ,xsp.sale_plan_dealer                sale_plan_dealer                                -- �≮
               ,xsp.sale_plan_others                sale_plan_others                                -- ���̑�
               ,xsp.sale_plan_vendor                sale_plan_vendor                                -- �x���_�[
               ,xsp.sale_plan_total                 sale_plan_total                                 -- ���㍇�v
               ,xsp.sale_plan_spare_1               sale_plan_spare_1                               -- �Ƒԕʔ���v��i�\���P�j
               ,xsp.sale_plan_spare_2               sale_plan_spare_2                               -- �Ƒԕʔ���v��i�\���Q�j
               ,xsp.sale_plan_spare_3               sale_plan_spare_3                               -- �Ƒԕʔ���v��i�\���R�j
               ,xsp.ly_revision_depart              ly_revision_depart                              -- �O�N���яC���i�ʔ̓X�j
               ,xsp.ly_revision_cvs                 ly_revision_cvs                                 -- �O�N���яC���i�b�u�r�j
               ,xsp.ly_revision_dealer              ly_revision_dealer                              -- �O�N���яC���i�≮�j
               ,xsp.ly_revision_others              ly_revision_others                              -- �O�N���яC���i���̑��j
               ,xsp.ly_revision_vendor              ly_revision_vendor                              -- �O�N���яC���i�x���_�[�j
               ,xsp.ly_revision_spare_1             ly_revision_spare_1                             -- �O�N���яC���i�\���P�j
               ,xsp.ly_revision_spare_2             ly_revision_spare_2                             -- �O�N���яC���i�\���Q�j
               ,xsp.ly_revision_spare_3             ly_revision_spare_3                             -- �O�N���яC���i�\���R�j
               ,xsp.ly_exist_total                  ly_exist_total                                  -- ��N�����q�i�S�́j
               ,xsp.ly_newly_total                  ly_newly_total                                  -- ��N�V�K�q�i�S�́j
               ,xsp.ty_first_total                  ty_first_total                                  -- �{�N�V�K����i�S�́j
               ,xsp.ty_turn_total                   ty_turn_total                                   -- �{�N�V�K��]�i�S�́j
               ,xsp.discount_total                  discount_total                                  -- �����l���i�S�́j
               ,xsp.ly_exist_vd_charge              ly_exist_vd_charge                              -- ��N�����q�i�u�c�j�S��
               ,xsp.ly_newly_vd_charge              ly_newly_vd_charge                              -- ��N�V�K�q�i�u�c�j�S��
               ,xsp.ty_first_vd_charge              ty_first_vd_charge                              -- �{�N�V�K����i�u�c�j�S��
               ,xsp.ty_turn_vd_charge               ty_turn_vd_charge                               -- �{�N�V�K��]�i�u�c�j�S��
               ,xsp.ty_first_vd_get                 ty_first_vd_get                                 -- �{�N�V�K����i�u�c�j�l��
               ,xsp.ty_turn_vd_get                  ty_turn_vd_get                                  -- �{�N�V�K��]�i�u�c�j�l��
               ,xsp.st_mon_get_total                st_mon_get_total                                -- ����ڋq���i�S�́j�l��
               ,xsp.newly_get_total                 newly_get_total                                 -- �V�K�����i�S�́j�l��
               ,xsp.cancel_get_total                cancel_get_total                                -- ���~�����i�S�́j�l��
               ,xsp.newly_charge_total              newly_charge_total                              -- �V�K�����i�S�́j�S��
               ,xsp.st_mon_get_vd                   st_mon_get_vd                                   -- ����ڋq���i�u�c�j�l��
               ,xsp.newly_get_vd                    newly_get_vd                                    -- �V�K�����i�u�c�j�l��
               ,xsp.cancel_get_vd                   cancel_get_vd                                   -- ���~�����i�u�c�j�l��
               ,xsp.newly_charge_vd_own             newly_charge_vd_own                             -- ���͐V�K�����i�u�c�j�S��
               ,xsp.newly_charge_vd_help            newly_charge_vd_help                            -- ���͐V�K�����i�u�c�j�S��
               ,xsp.cancel_charge_vd                cancel_charge_vd                                -- ���~�����i�u�c�j�S��
               ,xsp.patrol_visit_cnt                patrol_visit_cnt                                -- ����K��ڋq��
               ,xsp.patrol_def_visit_cnt            patrol_def_visit_cnt                            -- ���񉄖K�⌬��
               ,xsp.vendor_visit_cnt                vendor_visit_cnt                                -- �x���_�[�K��ڋq��
               ,xsp.vendor_def_visit_cnt            vendor_def_visit_cnt                            -- �x���_�[���K�⌬��
               ,xsp.public_visit_cnt                public_visit_cnt                                -- ��ʖK��ڋq��
               ,xsp.public_def_visit_cnt            public_def_visit_cnt                            -- ��ʉ��K�⌬��
               ,xsp.def_cnt_total                   def_cnt_total                                   -- ���K�⌬�����v
               ,xsp.vend_machine_sales_plan         vend_machine_sales_plan                         -- ���̋@����
               ,xsp.vend_machine_margin             vend_machine_margin                             -- �e���v
               ,xsp.vend_machine_bm                 vend_machine_bm                                 -- ���̋@�萔���i�a�l�j
               ,xsp.vend_machine_elect              vend_machine_elect                              -- ���̋@�萔���i�d�C��j
               ,xsp.vend_machine_lease              vend_machine_lease                              -- ���̋@���[�X��
               ,xsp.vend_machine_manage             vend_machine_manage                             -- ���̋@�ێ��Ǘ���
               ,xsp.vend_machine_sup_money          vend_machine_sup_money                          -- ���^��
               ,xsp.vend_machine_total              vend_machine_total                              -- ��p���v
               ,xsp.vend_machine_profit             vend_machine_profit                             -- ���_���̋@���v
               ,xsp.deficit_num                     deficit_num                                     -- �Ԏ��䐔
               ,xsp.par_machine                     par_machine                                     -- �p�[�}�V��
               ,xsp.possession_num                  possession_num                                  -- �ۗL�䐔
               ,xsp.stock_num                       stock_num                                       -- �݌ɑ䐔
               ,xsp.operation_num                   operation_num                                   -- �ғ��䐔
               ,xsp.increase                        increase                                        -- ����
               ,xsp.new_setting_own                 new_setting_own                                 -- �V�K�ݒu�i���́j
               ,xsp.new_setting_help                new_setting_help                                -- �V�K�ݒu�i���́j
               ,xsp.new_setting_total               new_setting_total                               -- �V�K�ݒu���v
               ,xsp.withdraw_num                    withdraw_num                                    -- �P�ƈ��g
               ,xsp.new_num_newly                   new_num_newly                                   -- �V��i�V�K�j
               ,xsp.new_num_replace                 new_num_replace                                 -- �V��i��ցj
               ,xsp.new_num_total                   new_num_total                                   -- �V�䍇�v
               ,xsp.old_num_newly                   old_num_newly                                   -- ����i�V�K�j
               ,xsp.old_num_replace                 old_num_replace                                 -- ����i��ցE�ڐ݁j
               ,xsp.disposal_num                    disposal_num                                    -- �p��
               ,xsp.enter_num                       enter_num                                       -- ���_�ԁi�ړ��j
               ,xsp.appear_num                      appear_num                                      -- ���_�ԁi�ڏo�j
               ,xsp.vend_machine_plan_spare_1       vend_machine_plan_spare_1                       -- �����̔��@�v��i�\���P�j
               ,xsp.vend_machine_plan_spare_2       vend_machine_plan_spare_2                       -- �����̔��@�v��i�\���Q�j
               ,xsp.vend_machine_plan_spare_3       vend_machine_plan_spare_3                       -- �����̔��@�v��i�\���R�j
               ,xsp.spare_1                         spare_1                                         -- �\���P
               ,xsp.spare_2                         spare_2                                         -- �\���Q
               ,xsp.spare_3                         spare_3                                         -- �\���R
               ,xsp.spare_4                         spare_4                                         -- �\���S
               ,xsp.spare_5                         spare_5                                         -- �\���T
               ,xsp.spare_6                         spare_6                                         -- �\���U
               ,xsp.spare_7                         spare_7                                         -- �\���V
               ,xsp.spare_8                         spare_8                                         -- �\���W
               ,xsp.spare_9                         spare_9                                         -- �\���X
               ,xsp.spare_10                        spare_10                                        -- �\���P�O
      FROM      xxcsm_sales_plan                    xsp                                             -- �̔��v��e�[�u��
      WHERE     xsp.plan_year = gv_obj_year
      ORDER BY  xsp.plan_ym                         ASC                                             -- �N��
               ,xsp.location_cd                     ASC;                                            -- ���_�R�[�h
--
    -- *** ���[�J���E���R�[�h ***
    get_sales_plan_rec   get_sales_plan_cur%ROWTYPE;
    l_get_data_rec       g_get_data_rtype;
    -- *** ���[�J����O ***
    no_data_expt         EXCEPTION;
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
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- A-2.�t�@�C���I�[�v������ 
    -- =========================================
    open_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.�̔��v��f�[�^���o����
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_sales_plan_cur;
--
    <<get_data_loop>>                                                                               -- �N�Ԕ̔��v��f�[�^�擾LOOP
    LOOP
      FETCH get_sales_plan_cur INTO get_sales_plan_rec;
      -- �����Ώی����i�[
      gn_target_cnt := get_sales_plan_cur%ROWCOUNT;
--
      EXIT WHEN get_sales_plan_cur%NOTFOUND
             OR get_sales_plan_cur%ROWCOUNT = 0;
      -- ���R�[�h�ϐ�������
      l_get_data_rec := NULL;
      -- �擾�f�[�^���i�[
      l_get_data_rec.company_cd                := cv_company_cd;                                    -- ��ЃR�[�h
      l_get_data_rec.plan_year                 := get_sales_plan_rec.plan_year;                     -- �\�Z�N�x
      l_get_data_rec.plan_ym                   := get_sales_plan_rec.plan_ym;                       -- �N��
      l_get_data_rec.location_cd               := get_sales_plan_rec.location_cd;                   -- ���_�R�[�h
      l_get_data_rec.act_work_date             := get_sales_plan_rec.act_work_date;                 -- ������
      l_get_data_rec.plan_staff                := get_sales_plan_rec.plan_staff;                    -- �v��l��
      l_get_data_rec.sale_plan_depart          := get_sales_plan_rec.sale_plan_depart;              -- �ʔ̓X����v��
      l_get_data_rec.sale_plan_cvs             := get_sales_plan_rec.sale_plan_cvs;                 -- CVS����v��
      l_get_data_rec.sale_plan_dealer          := get_sales_plan_rec.sale_plan_dealer;              -- �≮����v��
      l_get_data_rec.sale_plan_others          := get_sales_plan_rec.sale_plan_others;              -- ���̑�����v��
      l_get_data_rec.sale_plan_vendor          := get_sales_plan_rec.sale_plan_vendor;              -- �x���_�[����v��
      l_get_data_rec.sale_plan_total           := get_sales_plan_rec.sale_plan_total;               -- ����v�捇�v
      l_get_data_rec.sale_plan_spare_1         := get_sales_plan_rec.sale_plan_spare_1;             -- �Ƒԕʔ���v��i�\���P�j
      l_get_data_rec.sale_plan_spare_2         := get_sales_plan_rec.sale_plan_spare_2;             -- �Ƒԕʔ���v��i�\���Q�j
      l_get_data_rec.sale_plan_spare_3         := get_sales_plan_rec.sale_plan_spare_3;             -- �Ƒԕʔ���v��i�\���R�j
      l_get_data_rec.ly_revision_depart        := get_sales_plan_rec.ly_revision_depart;            -- �O�N���яC���i�ʔ̓X�j
      l_get_data_rec.ly_revision_cvs           := get_sales_plan_rec.ly_revision_cvs;               -- �O�N���яC���iCVS�j
      l_get_data_rec.ly_revision_dealer        := get_sales_plan_rec.ly_revision_dealer;            -- �O�N���яC���i�≮�j
      l_get_data_rec.ly_revision_others        := get_sales_plan_rec.ly_revision_others;            -- �O�N���яC���i���̑��j
      l_get_data_rec.ly_revision_vendor        := get_sales_plan_rec.ly_revision_vendor;            -- �O�N���яC���i�x���_�[�j
      l_get_data_rec.ly_revision_spare_1       := get_sales_plan_rec.ly_revision_spare_1;           -- �O�N���яC���i�\���P�j
      l_get_data_rec.ly_revision_spare_2       := get_sales_plan_rec.ly_revision_spare_2;           -- �O�N���яC���i�\���Q�j
      l_get_data_rec.ly_revision_spare_3       := get_sales_plan_rec.ly_revision_spare_3;           -- �O�N���яC���i�\���R�j
      l_get_data_rec.ly_exist_total            := get_sales_plan_rec.ly_exist_total;                -- ��N����v��_�����q�i�S�́j
      l_get_data_rec.ly_newly_total            := get_sales_plan_rec.ly_newly_total;                -- ��N����v��_�V�K�q�i�S�́j
      l_get_data_rec.ty_first_total            := get_sales_plan_rec.ty_first_total;                -- �{�N����v��_�V�K����i�S�́j
      l_get_data_rec.ty_turn_total             := get_sales_plan_rec.ty_turn_total;                 -- �{�N����v��_�V�K��]�i�S�́j
      l_get_data_rec.discount_total            := get_sales_plan_rec.discount_total;                -- �����l���i�S�́j
      l_get_data_rec.ly_exist_vd_charge        := get_sales_plan_rec.ly_exist_vd_charge;            -- ��N����v��_�����q�iVD�j�S���x�[�X
      l_get_data_rec.ly_newly_vd_charge        := get_sales_plan_rec.ly_newly_vd_charge;            -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
      l_get_data_rec.ty_first_vd_charge        := get_sales_plan_rec.ty_first_vd_charge;            -- �{�N����v��_�V�K����iVD�j�S���x�[�X
      l_get_data_rec.ty_turn_vd_charge         := get_sales_plan_rec.ty_turn_vd_charge;             -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
      l_get_data_rec.ty_first_vd_get           := get_sales_plan_rec.ty_first_vd_get;               -- �{�N����v��_�V�K����iVD�j�l���x�[�X
      l_get_data_rec.ty_turn_vd_get            := get_sales_plan_rec.ty_turn_vd_get;                -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
      l_get_data_rec.st_mon_get_total          := get_sales_plan_rec.st_mon_get_total;              -- �����ڋq���i�S�́j�l���x�[�X
      l_get_data_rec.newly_get_total           := get_sales_plan_rec.newly_get_total;               -- �V�K�����i�S�́j�l���x�[�X
      l_get_data_rec.cancel_get_total          := get_sales_plan_rec.cancel_get_total;              -- ���~�����i�S�́j�l���x�[�X
      l_get_data_rec.newly_charge_total        := get_sales_plan_rec.newly_charge_total;            -- �V�K�����i�S�́j�S���x�[�X
      l_get_data_rec.st_mon_get_vd             := get_sales_plan_rec.st_mon_get_vd;                 -- �����ڋq���iVD�j�l���x�[�X
      l_get_data_rec.newly_get_vd              := get_sales_plan_rec.newly_get_vd;                  -- �V�K�����iVD�j�l���x�[�X
      l_get_data_rec.cancel_get_vd             := get_sales_plan_rec.cancel_get_vd;                 -- ���~�����iVD�j�l���x�[�X
      l_get_data_rec.newly_charge_vd_own       := get_sales_plan_rec.newly_charge_vd_own;           -- ���͐V�K�����iVD�j�S���x�[�X
      l_get_data_rec.newly_charge_vd_help      := get_sales_plan_rec.newly_charge_vd_help;          -- ���͐V�K�����iVD�j�S���x�[�X
      l_get_data_rec.cancel_charge_vd          := get_sales_plan_rec.cancel_charge_vd;              -- ���~�����iVD�j�S���x�[�X
      l_get_data_rec.patrol_visit_cnt          := get_sales_plan_rec.patrol_visit_cnt;              -- ����K��ڋq��
      l_get_data_rec.patrol_def_visit_cnt      := get_sales_plan_rec.patrol_def_visit_cnt;          -- ���񉄖K�⌬��
      l_get_data_rec.vendor_visit_cnt          := get_sales_plan_rec.vendor_visit_cnt;              -- �x���_�[�K��ڋq��
      l_get_data_rec.vendor_def_visit_cnt      := get_sales_plan_rec.vendor_def_visit_cnt;          -- �x���_�[���K�⌬��
      l_get_data_rec.public_visit_cnt          := get_sales_plan_rec.public_visit_cnt;              -- ��ʖK��ڋq��
      l_get_data_rec.public_def_visit_cnt      := get_sales_plan_rec.public_def_visit_cnt;          -- ��ʉ��K�⌬��
      l_get_data_rec.def_cnt_total             := get_sales_plan_rec.def_cnt_total;                 -- ���K�⌬�����v
      l_get_data_rec.vend_machine_sales_plan   := get_sales_plan_rec.vend_machine_sales_plan;       -- ���̋@����v��
      l_get_data_rec.vend_machine_margin       := get_sales_plan_rec.vend_machine_margin;           -- ���̋@�v��e���v
      l_get_data_rec.vend_machine_bm           := get_sales_plan_rec.vend_machine_bm;               -- ���̋@�萔���iBM�j
      l_get_data_rec.vend_machine_elect        := get_sales_plan_rec.vend_machine_elect;            -- ���̋@�萔���i�d�C��j
      l_get_data_rec.vend_machine_lease        := get_sales_plan_rec.vend_machine_lease;            -- ���̋@���[�X��
      l_get_data_rec.vend_machine_manage       := get_sales_plan_rec.vend_machine_manage;           -- ���̋@�ێ��Ǘ���
      l_get_data_rec.vend_machine_sup_money    := get_sales_plan_rec.vend_machine_sup_money;        -- ���̋@�v�拦�^��
      l_get_data_rec.vend_machine_total        := get_sales_plan_rec.vend_machine_total;            -- ���̋@�v���p���v
      l_get_data_rec.vend_machine_profit       := get_sales_plan_rec.vend_machine_profit;           -- ���_���̋@���v
      l_get_data_rec.deficit_num               := get_sales_plan_rec.deficit_num;                   -- �Ԏ��䐔
      l_get_data_rec.par_machine               := get_sales_plan_rec.par_machine;                   -- �p�[�}�V��
      l_get_data_rec.possession_num            := get_sales_plan_rec.possession_num;                -- �ۗL�䐔
      l_get_data_rec.stock_num                 := get_sales_plan_rec.stock_num;                     -- �݌ɑ䐔
      l_get_data_rec.operation_num             := get_sales_plan_rec.operation_num;                 -- �ғ��䐔
      l_get_data_rec.increase                  := get_sales_plan_rec.increase;                      -- ����
      l_get_data_rec.new_setting_own           := get_sales_plan_rec.new_setting_own;               -- �V�K�ݒu�䐔�i���́j
      l_get_data_rec.new_setting_help          := get_sales_plan_rec.new_setting_help;              -- �V�K�ݒu�䐔�i���́j
      l_get_data_rec.new_setting_total         := get_sales_plan_rec.new_setting_total;             -- �V�K�ݒu�䐔���v
      l_get_data_rec.withdraw_num              := get_sales_plan_rec.withdraw_num;                  -- �P�ƈ��g�䐔
      l_get_data_rec.new_num_newly             := get_sales_plan_rec.new_num_newly;                 -- �V��䐔�i�V�K�j
      l_get_data_rec.new_num_replace           := get_sales_plan_rec.new_num_replace;               -- �V��䐔�i��ցj
      l_get_data_rec.new_num_total             := get_sales_plan_rec.new_num_total;                 -- �V��䐔���v
      l_get_data_rec.old_num_newly             := get_sales_plan_rec.old_num_newly;                 -- ����䐔�i�V�K�j
      l_get_data_rec.old_num_replace           := get_sales_plan_rec.old_num_replace;               -- ����䐔�i��ցE�ڐ݁j
      l_get_data_rec.disposal_num              := get_sales_plan_rec.disposal_num;                  -- �p���䐔
      l_get_data_rec.enter_num                 := get_sales_plan_rec.enter_num;                     -- ���_�Ԉړ��䐔
      l_get_data_rec.appear_num                := get_sales_plan_rec.appear_num;                    -- ���_�Ԉڏo�䐔
      l_get_data_rec.vend_machine_plan_spare_1 := get_sales_plan_rec.vend_machine_plan_spare_1;     -- �����̔��@�v��i�\���P�j
      l_get_data_rec.vend_machine_plan_spare_2 := get_sales_plan_rec.vend_machine_plan_spare_2;     -- �����̔��@�v��i�\���Q�j
      l_get_data_rec.vend_machine_plan_spare_3 := get_sales_plan_rec.vend_machine_plan_spare_3;     -- �����̔��@�v��i�\���R�j
      l_get_data_rec.spare_1                   := get_sales_plan_rec.spare_1;                       -- �\���P
      l_get_data_rec.spare_2                   := get_sales_plan_rec.spare_2;                       -- �\���Q
      l_get_data_rec.spare_3                   := get_sales_plan_rec.spare_3;                       -- �\���R
      l_get_data_rec.spare_4                   := get_sales_plan_rec.spare_4;                       -- �\���S
      l_get_data_rec.spare_5                   := get_sales_plan_rec.spare_5;                       -- �\���T
      l_get_data_rec.spare_6                   := get_sales_plan_rec.spare_6;                       -- �\���U
      l_get_data_rec.spare_7                   := get_sales_plan_rec.spare_7;                       -- �\���V
      l_get_data_rec.spare_8                   := get_sales_plan_rec.spare_8;                       -- �\���W
      l_get_data_rec.spare_9                   := get_sales_plan_rec.spare_9;                       -- �\���X
      l_get_data_rec.spare_10                  := get_sales_plan_rec.spare_10;                      -- �\���P�O
      l_get_data_rec.cprtn_date                := gd_sysdate;                                       -- �A�g����
--
      -- ========================================
      -- A-4.�̔��v��f�[�^��������
      -- ========================================
      create_csv_rec(
        ir_sales_plan  =>  l_get_data_rec                                                           -- �̔��v��v�撊�o�f�[�^
       ,ov_errbuf      =>  lv_errbuf                                                                -- �G���[�E���b�Z�[�W
       ,ov_retcode     =>  lv_retcode                                                               -- ���^�[���E�R�[�h
       ,ov_errmsg      =>  lv_errmsg                                                                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_sales_plan_cur;
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_xxcsm_msg_019                                            --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    -- ========================================
    -- A-5.�N�Ԍv��I/F�t�@�C���N���[�Y����
    -- ========================================
    close_csv_file(
       ov_errbuf    => lv_errbuf                                                                    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode                                                                   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_sales_plan_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_sales_plan_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_sales_plan_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2                                                              -- �G���[�E���b�Z�[�W
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- ���^�[���E�R�[�h
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- �v���O������
    cv_xxcsm           CONSTANT VARCHAR2(100) := 'XXCSM';                                           -- �A�v���P�[�V�����Z�k�� 
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                                               -- �I�����b�Z�[�W�R�[�h
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
       ov_errbuf   => lv_errbuf                                                                     -- �G���[�E���b�Z�[�W
      ,ov_retcode  => lv_retcode                                                                    -- ���^�[���E�R�[�h
      ,ov_errmsg   => lv_errmsg                                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                                        --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                                        --�G���[���b�Z�[�W
      );
      --�����̐U��(�G���[�̏ꍇ�A�G���[������1���̂ݕ\��������B�j
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    -- =======================
    -- A-6.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
--###########################  �Œ蕔 END   #######################################################
--
END XXCSM001A03C;
/
