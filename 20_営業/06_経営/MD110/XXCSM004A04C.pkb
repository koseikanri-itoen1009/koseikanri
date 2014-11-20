CREATE OR REPLACE PACKAGE BODY XXCSM004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A04C(body)
 * Description      : �ڋq�}�X�^����V�K�l�������ڋq�𒊏o���A�V�K�l���|�C���g�ڋq�ʗ����e�[�u��
 *                  : �Ƀf�[�^��o�^���܂��B
 * MD.050           : �V�K�l���|�C���g�W�v�i�V�K�l���|�C���g�W�v�����jMD050_CSM_004_A04
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  delete_rec_with_lock   �e�[�u���i���R�[�h�P�ʁj�̃��b�N����(A-3)
 *                         �f�[�^�폜����(A-4)
 *  make_work_table        ���[�N�e�[�u���f�[�^�쐬�^�X�V����(A-8)
 *  update_work_table      ���[�N�e�[�v���m��t���O�^�V�K�]���Ώۋ敪�X�V����(A-11)
 *  insert_hst_table       �V�K�l���|�C���g�ڋq�ʗ����e�[�u���쐬����(A-13)
 *  set_new_point_loop     �V�K�l���|�C���g�쐬���[�v(loop-1)
 *                         �ڋq���擾����(A-5)
 *                         �l���^�Љ���Z�b�g����(A-6)
 *                         ���[�N�e�[�u���f�[�^�`�F�b�N����(A-7)
 *                         �|�C���g�t�^����擾����(A-9)
 *                         �|�C���g���m�蔻�菈��(A-10)
 *                         �|�C���g������(A-12)
 *                            �Emake_work_table
 *                            �Einsert_hst_table
 *                            �Eupdate_work_table
 *  get_ar_period_loop     �f�[�^�쐬�Ώۊ��Ԏ擾����(A-2)
 *                            �Edelete_rec_with_lock
 *                            �Eset_new_point_loop
 *  submain                ���C�������v���V�[�W��
 *                            �Einit
 *                            �Eget_ar_period_loop
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Esubmain
 *                         �I������(A-14)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/27    1.0   n.izumi         �V�K�쐬
 *  2009/04/09    1.1   M.Ohtsuki      �m��QT1_0416�n�Ɩ����t�ƃV�X�e�����t��r�̕s�
 *  2009/04/22    1.2   M.Ohtsuki      �m��QT1_0704�n�R�[�h��`���̕s�
 *  2009/04/22    1.2   M.Ohtsuki      �m��QT1_0713�n���m�蔻�菈���̕s�
 *  2009/07/07    1.3   M.Ohtsuki      �mSCS��Q�Ǘ��ԍ�0000254�n�����R�[�h�擾�����̕s�
 *  2009/07/14    1.4   M.Ohtsuki      �mSCS��Q�Ǘ��ԍ�0000663�n�z��O�G���[�������̕s�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM004A04C';                               -- �p�b�P�[�W��
  --�G���[���b�Z�[�W�R�[�h
  cv_err_prof_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_err_py4_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                           -- �N�x�擾�G���[���b�Z�[�W
  cv_err_emp_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00023';                           -- �]�ƈ����擾�G���[���b�Z�[�W
  cv_err_cust_trn_msg       CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00030';                           -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u�����b�N�G���[���b�Z�[�W
  cv_err_loca_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00033';                           -- �������_�s���G���[���b�Z�[�W
  cv_err_post_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00044';                           -- �����R�[�h�擾�G���[���b�Z�[�W
  cv_err_cnvs_busines_person_msg     CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00046';                  -- �l���c�ƈ��R�[�h���ݒ�G���[���b�Z�[�W
  --���b�Z�[�W�R�[�h
  cv_open_period_msg        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00041';                           -- �I�[�v����v���Ԏ擾���e���b�Z�[�W
  cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                           -- �Ώی������b�Z�[�W
  cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                           -- �����������b�Z�[�W
  cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                           -- �G���[�������b�Z�[�W
  cv_warn_cnt_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                           -- �X�L�b�v�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                           -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                           -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                           -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_error_stop_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007';                           -- �G���[�I���ꕔ�������b�Z�[�W
  cv_noparam_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
  --�g�[�N���R�[�h
  cv_empcd_tkn              CONSTANT VARCHAR2(100) := 'JUGYOIN_CD';                                 -- �]�ƈ��R�[�h
  cv_prof_name_tkn          CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- �v���t�@�C����
  cv_pym_tkn                CONSTANT VARCHAR2(100) := 'YYYYMM';                                     -- �I�[�v�����̉�v���ԁi�N���j
  cv_py4_tkn                CONSTANT VARCHAR2(100) := 'YYYY';                                       -- �N�x�Z�o�֐��Ŏ擾�����N�x
  cv_gcd_tkn                CONSTANT VARCHAR2(100) := 'GET_CUSTOM_DATE';                            -- �ڋq�l����
  cv_cnt_tkn                CONSTANT VARCHAR2(100) := 'COUNT';                                      -- ��������
  cv_dkb_tkn                CONSTANT VARCHAR2(100) := 'DATA_KBN';                                   -- �f�[�^�敪
  cv_loca_tkn               CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- ���_�R�[�h
  cv_account_tkn            CONSTANT VARCHAR2(100) := 'KOKYAKU_CD';                                 -- �ڋq�R�[�h
  --���̑�
  cv_appl_short_name_csm    CONSTANT VARCHAR2(5)   := 'XXCSM';                                      -- �A�h�I���F�o�c�Ǘ�
  cv_appl_short_name_ar     CONSTANT VARCHAR2(2)   := 'AR';                                         -- AR�A�v���P�[�V�����Z�k��
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCCP';                                      -- �A�h�I���F���ʊǗ�
  cv_point_custom_status    CONSTANT VARCHAR2(30)  := 'XXCSM1_POINT_CUSTOM_STATUS';                 -- �ڋq�X�e�[�^�X���b�N�A�b�v�^�C�v
--//+DEL START 2009/07/07 0000254 M.Ohtsuki
--  cv_post_level_name        CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_POST_LEVEL';               -- �|�C���g�Z�o�p�����K�w
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
  cv_set_of_bks_id_name     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                           -- ��v����ID
  cv_closing_status_o       CONSTANT VARCHAR2(1)   := 'O';                                          -- ��v���ԃX�e�[�^�X(�I�[�v��)
--//+DEL START 2009/04/27 T1_0713 M.Ohtsuki
--  cv_closing_status_p       CONSTANT VARCHAR2(1)   := 'P';                                          -- ��v���ԃX�e�[�^�X(�i�v�N���[�Y)
--  cv_closing_status_c       CONSTANT VARCHAR2(1)   := 'C';                                          -- ��v���ԃX�e�[�^�X(�N���[�Y)
--//+DEL END   2009/04/27 T1_0713 M.Ohtsuki
  cn_new_data               CONSTANT NUMBER        := 1;                                            -- �|�C���g�f�[�^�敪�i1�F�V�K�l���|�C���g�j
  cv_new_point              CONSTANT VARCHAR2(1)   := '1';                                          -- �V�K�|�C���g�敪(1�F�V�K�j
  cv_lang                   CONSTANT VARCHAR2(10)  := USERENV('LANG');                              -- ����
  cv_period_start           CONSTANT VARCHAR2(1)   := '1';                                          -- �N�x�����i�J�n�j
  cv_period_end             CONSTANT VARCHAR2(2)   := '12';                                         -- �N�x�����i�I���j
  cv_get                    CONSTANT VARCHAR2(1)   := '0';                                          -- �l���҃f�[�^
  cv_intro                  CONSTANT VARCHAR2(1)   := '1';                                          -- �Љ�҃f�[�^
  cv_kakutei                CONSTANT VARCHAR2(1)   := '1';                                          -- �m��t���O�m��
  cv_mikakutei              CONSTANT VARCHAR2(1)   := '0';                                          -- �m��t���O���m��
  cv_intro_ari              CONSTANT VARCHAR2(1)   := '1';                                          -- �Љ�җL
  cv_intro_nasi             CONSTANT VARCHAR2(1)   := '0';                                          -- �Љ�Җ�
  cv_cust_work_ari          CONSTANT VARCHAR2(1)   := '1';                                          -- �ڋq�l�������[�N�L
  cv_cust_work_nasi         CONSTANT VARCHAR2(1)   := '0';                                          -- �ڋq�l�������[�N��
  cv_sales                  CONSTANT VARCHAR2(2)   := '01';                                         -- �c�ƐE
  cv_other                  CONSTANT VARCHAR2(2)   := '  ';                                         -- �c�ƐE�ȊO
  cv_sts_stop               CONSTANT VARCHAR2(2)   := '90';                                         -- ���~�ڋq
  cv_grant_ok               CONSTANT VARCHAR2(2)   := '0';                                          -- �|�C���g�t�^����
  cv_grant_ng               CONSTANT VARCHAR2(2)   := '1';                                          -- �|�C���g�t�^���Ȃ�
  cv_point_cond_ari         CONSTANT VARCHAR2(1)   := '1';                                          -- �|�C���g�����L
  cv_point_cond_nasi        CONSTANT VARCHAR2(1)   := '0';                                          -- �|�C���g������
  cv_jisseki_chk_fuyo       CONSTANT VARCHAR2(1)   := '0';                                          -- ���є���Ȃ�
  cv_jisseki_chk_yo         CONSTANT VARCHAR2(1)   := '1';                                          -- ���є��肠��
  cv_chk_on                 CONSTANT VARCHAR2(1)   := '1';                                          -- �`�F�b�N�����I��
  cv_cond_all               CONSTANT VARCHAR2(1)   := '1';                                          -- �|�C���g�t�^����1
  cv_cond_any               CONSTANT VARCHAR2(1)   := '2';                                          -- �|�C���g�t�^����2
  cv_cond_sum               CONSTANT VARCHAR2(1)   := '3';                                          -- �|�C���g�t�^����3
--//+UPD START 2009/04/22 T1_0704 M.Ohtsuki
--  cv_business_low_type_s_vd CONSTANT VARCHAR2(2)   := '26';                                         -- �Ƒԁi�����ށj�t���T�[�r�X�i�����jVD
--  cv_business_low_type_vd   CONSTANT VARCHAR2(2)   := '27';                                         -- �Ƒԁi�����ށj�t���T�[�r�XVD
--  cv_business_low_type_n_vd CONSTANT VARCHAR2(2)   := '28';                                         -- �Ƒԁi�����ށj�[�iVD
--��������������������������������������������������������������������������������������������������
  cv_business_low_type_s_vd CONSTANT VARCHAR2(2)   := '24';                                         -- �Ƒԁi�����ށj�t���T�[�r�X�i�����jVD
  cv_business_low_type_vd   CONSTANT VARCHAR2(2)   := '25';                                         -- �Ƒԁi�����ށj�t���T�[�r�XVD
  cv_business_low_type_n_vd CONSTANT VARCHAR2(2)   := '26';                                         -- �Ƒԁi�����ށj�[�iVD
--//+UPD END   2009/04/22 T1_0704 M.Ohtsuki
  cv_custom_condition_fvd   CONSTANT VARCHAR2(2)   := '01';                                         -- �ڋq�ƑԃR�[�h �t��VD
  cv_custom_condition_nvd   CONSTANT VARCHAR2(2)   := '02';                                         -- �ڋq�ƑԃR�[�h �[�iVD
  cv_custom_condition_gvd   CONSTANT VARCHAR2(2)   := '03';                                         -- �ڋq�ƑԃR�[�h ���
  cv_error_on               CONSTANT VARCHAR2(1)   := '1';                                          -- �G���[�I��
  cv_error_off              CONSTANT VARCHAR2(1)   := '0';                                          -- �G���[�I�t
  cv_customer_class_cust    CONSTANT VARCHAR2(2)   := '10';                                         -- �ڋq�敪�i�ڋq�j
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                                          -- �t���O'Y'
--//+ADD START 2009/04/27 T1_0713 M.Ohtsuki
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                                          -- �t���O'N'
--//+ADD END   2009/04/27 T1_0713 M.Ohtsuki
  cv_kyousan                CONSTANT VARCHAR2(1)   := '5';                                          -- ����敪'���^'
  cv_mihon                  CONSTANT VARCHAR2(1)   := '6';                                          -- ����敪'���{'
  cv_cm                     CONSTANT VARCHAR2(1)   := '7';                                          -- ����敪'�L��'
  cv_empinfo_upd            CONSTANT VARCHAR2(1)   := '1';                                          -- ���ߓ������l�����̏��
  --�f�o�b�N�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  TYPE gt_loc_lv_ttype IS TABLE OF VARCHAR2(10)                                                     -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                                                                   -- �Ɩ����t
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--  gv_post_level             VARCHAR2(100);                                                          -- �|�C���g�Z�o�p�����K�w
--//+DEL END     2009/07/07 0000254 M.Ohtsuki
  gt_set_of_bks_id          gl_period_statuses.set_of_books_id%TYPE;                                -- ��v����ID
  gt_ar_appl_id             fnd_application.application_id%TYPE;                                    -- AR�A�v���P�[�V����ID
  gv_intro_umu_flg          VARCHAR2(1);                                                            -- �Љ�җL���t���O
--
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  gt_loc_lv_tab             gt_loc_lv_ttype;                                                        -- �e�[�u���^�ϐ��̐錾
  ln_loc_lv_cnt             NUMBER;                                                                 -- �J�E���^
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  global_lock_expt          EXCEPTION;                                                              -- ���b�N�擾��O
  global_skip_expt          EXCEPTION;                                                              -- �ڋq�P�ʃX�L�b�v��O

  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- �G���[�E���b�Z�[�W
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- ���^�[���E�R�[�h
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    cv_location_level       CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_LEVEL';                    -- �|�C���g�Z�o�p�����K�w
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
    -- *** ���[�J���ϐ� ***
    lv_tkn_value            VARCHAR2(4000);                                                         -- �g�[�N���l
    -- *** ���[�J���E�J�[�\�� **
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    CURSOR get_loc_lv_cur
    IS
          SELECT   flv.lookup_code        lookup_code
          FROM     fnd_lookup_values      flv                                                       -- �N�C�b�N�R�[�h�l
          WHERE    flv.lookup_type        = cv_location_level                                       -- �|�C���g�Z�o�p�����K�w
            AND    flv.language           = USERENV('LANG')                                         -- ����('JA')
            AND    flv.enabled_flag       = cv_flg_y                                                -- �g�p�\�t���O
            AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                    -- �K�p�J�n��
            AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                    -- �K�p�I����
          ORDER BY flv.lookup_code   DESC;                                                          -- ���b�N�A�b�v�R�[�h
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
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
    --A-1 ��������
    --==============================================================
    --==============================================================
    -- �@ �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    --==============================================================
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_noparam_msg                                           --���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => ''           || CHR(10) ||                                                         -- ��s�̑}��
                 gv_out_msg   || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
    --���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG                                                                       -- ���O
      ,buff   => ''           || CHR(10) ||                                                         -- ��s�̑}��
                 gv_out_msg   || CHR(10) ||
                 ''                                                                                 -- ��s�̑}��
    );
--
    --==============================================================
    -- �A�v���t�@�C���l�擾
    --==============================================================
--
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    FND_PROFILE.GET(name => cv_post_level_name
--                   ,val  => gv_post_level);                                                         -- �|�C���g�Z�o�p�����K�w
--//+DEL END     2009/07/07 0000254 M.Ohtsuki
    FND_PROFILE.GET(name => cv_set_of_bks_id_name
                   ,val  => gt_set_of_bks_id);                                                      -- ��v����ID
--//+UPD START   2009/07/07 0000254 M.Ohtsuki
--    IF ( gv_post_level IS NULL) THEN                                                                -- �|�C���g�Z�o�p�����K�w�̏ꍇ
--      lv_tkn_value    := cv_post_level_name;
--    ELSIF ( gt_set_of_bks_id IS NULL) THEN                                                          -- ��v����ID�̏ꍇ
--      lv_tkn_value    := cv_set_of_bks_id_name;
--    END IF;
--��������������������������������������������������������������������������������������������������
    IF ( gt_set_of_bks_id IS NULL) THEN  
      lv_tkn_value    := cv_set_of_bks_id_name;
    END IF;
--//+UPD START   2009/07/07 0000254 M.Ohtsuki
    IF (lv_tkn_value IS NOT NULL) THEN                                                              -- �擾�Ɏ��s�����ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_appl_short_name_csm               -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_err_prof_msg                      -- ���b�Z�[�W�R�[�h
                                           ,iv_token_name1  => cv_prof_name_tkn                     -- �g�[�N���R�[�h1
                                           ,iv_token_value1 => lv_tkn_value                         -- �g�[�N���l1
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--  --==============================================================
    --�B AR�A�v���P�[�V����ID�̎擾
    --==============================================================
    gt_ar_appl_id := xxccp_common_pkg.get_application(
                                            iv_application_name => cv_appl_short_name_ar            -- AR�A�v���P�[�V����ID�擾
                                           );                       
    IF (gt_ar_appl_id IS NULL) THEN                                                                 -- �擾�Ɏ��s�����ꍇ
      RAISE global_process_expt;
    END IF;
--  --==============================================================
    --�C �Ɩ����t�̎擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- �Ɩ����t�擾
--
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
--  --==============================================================
    --�D ���_�K�w�̎擾
    --==============================================================
    ln_loc_lv_cnt := 0;                                                                             -- �ϐ��̏�����
    <<get_loc_lv_cur_loop>>                                                                        -- ���_�K�w�擾LOOP
    FOR rec IN get_loc_lv_cur LOOP
      ln_loc_lv_cnt := ln_loc_lv_cnt + 1;
      gt_loc_lv_tab(ln_loc_lv_cnt)   := rec.lookup_code;                                            -- ���_�K�w
    END LOOP get_loc_lv_cur_loop;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END init;
  /**********************************************************************************
   * Procedure Name   : delete_rec_with_lock
   * Description      : �e�[�u���i���R�[�h�P�ʁj�̃��b�N����(A-3)
   *                  : �f�[�^�폜����(A-4)
   ***********************************************************************************/
  PROCEDURE delete_rec_with_lock(
     it_year             IN         xxcsm_new_cust_point_hst.subject_year%TYPE                      -- �Ώ۔N�x
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W                          --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h                            --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W                --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_rec_with_lock';                     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  delete_data_cur(                                                                        -- �폜�f�[�^�擾�J�[�\��(���b�N����)
       it_year2 xxcsm_new_cust_point_hst.subject_year%TYPE
    )
    IS
      SELECT xncph.subject_year   subject_year                                                      -- �Ώ۔N�x
      FROM   xxcsm_new_cust_point_hst  xncph                                                        -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
      WHERE  xncph.subject_year   =  it_year2                                                       -- �Ώ۔N�x
      AND    xncph.data_kbn       =  cn_new_data                                                    -- �V�K�l���|�C���g
      FOR UPDATE OF
          xncph.employee_number,
          xncph.subject_year,
          xncph.month_no,
          xncph.account_number,
          xncph.data_kbn
      NOWAIT;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �Ώ۔N�x�̐V�K�l���|�C���g�ڋq�ʗ����e�[�u���̃f�[�^�����b�N���܂��B
    -- ���b�N�����������ꍇ�A�Ώۃf�[�^�̍폜���s���܂��B
    -- ==============================================================
    --�f�[�^���b�N�擾�i�V�K�l���|�C���g�ڋq�ʗ����e�[�u���̔N�x�P�ʁj
    OPEN delete_data_cur(it_year);
    CLOSE delete_data_cur;
--
    --�����f�[�^�̃p�[�W�i�f�[�^�􂢑ւ��̂��߁j
    DELETE FROM xxcsm_new_cust_point_hst  xncph                                                     -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
    WHERE  xncph.subject_year   =  it_year                                                          -- �Ώ۔N�x
    AND    xncph.data_kbn       =  cn_new_data                                                      -- �V�K�l���|�C���g�̃f�[�^
    ;
--
  EXCEPTION
    WHEN global_lock_expt THEN                                                                      -- ���b�N�̎擾�Ɏ��s�����ꍇ
      IF (delete_data_cur%ISOPEN) THEN
        CLOSE delete_data_cur;
      END IF;
      ov_retcode := cv_status_error;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_err_cust_trn_msg                                         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_py4_tkn                                                  -- �Ώ۔N�x
                    ,iv_token_value1 => TO_CHAR(it_year)                                            -- �g�[�N���l1
                    ,iv_token_name2  => cv_dkb_tkn                                                  -- �f�[�^�敪
                    ,iv_token_value2 => TO_CHAR(cn_new_data)                                        -- 1�F�V�K�l���|�C���g
                    );
      ov_errbuf := lv_errmsg;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rec_with_lock;
--
  /**********************************************************************************
   * Procedure Name   : make_work_table
   * Description      : ���[�N�e�[�u���f�[�^�쐬����
   ***********************************************************************************/
  PROCEDURE make_work_table(
     it_get_intro_kbn    IN         xxcsm_wk_new_cust_get_emp.get_intro_kbn%TYPE                    -- �l���^�Љ�敪
    ,it_year             IN         xxcsm_wk_new_cust_get_emp.subject_year%TYPE                     -- �Ώ۔N�x
    ,it_account_number   IN         xxcsm_wk_new_cust_get_emp.account_number%TYPE                   -- �ڋq�R�[�h
    ,it_employee_number  IN         xxcsm_wk_new_cust_get_emp.employee_number%TYPE                  -- �]�ƈ��R�[�h
    ,it_cnvs_date        IN         xxcmm_cust_accounts.cnvs_date%TYPE                              -- �ڋq�l����
    ,it_business_low_type IN         xxcmm_cust_accounts.business_low_type%TYPE                     -- �Ƒԁi�����ށj�R�[�h
    ,iv_cust_work_flg    IN         VARCHAR2                                                        -- �ڋq�l�������[�N�L���t���O
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W                          --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h                            --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W                --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'make_work_table';                          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lt_decision_flg   xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                                  -- �m��t���O
    lt_location_cd    xxcmm_cust_accounts.intro_base_code%TYPE;                                     -- ���_
    lt_custom_condition_cd  xxcsm_wk_new_cust_get_emp.custom_condition_cd%TYPE;                     -- �ڋq�ƑԃR�[�h
    lt_post_cd        xxcmm_cust_accounts.intro_base_code%TYPE;                                     -- �����R�[�h 
    lv_qualificate_cd VARCHAR2(100);                                                                -- ���i�R�[�h
    lv_duties_cd      VARCHAR2(100);                                                                -- �E���R�[�h
    lv_job_type_cd    VARCHAR2(100);                                                                -- �E��R�[�h
    lv_new_old_type   VARCHAR2(1);                                                                  -- �V���t���O
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    ln_check_cnt         NUMBER;                                                                    -- �����`�F�b�N�p�J�E���^
--//+ADD END     2009/07/07 0000254 M.Ohtsuki

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
    -- ==============================================================
    -- A-8.���[�N�e�[�u���f�[�^�쐬�^�X�V����
    -- ==============================================================
    -- 1.�Ƒԁi�����ށj����ڋq�ƑԃR�[�h���Z�o���܂��B
    IF (it_business_low_type IN (cv_business_low_type_s_vd,cv_business_low_type_vd)) THEN           -- �Ƒԁi�����ށj���t��VD�A�t��VD(����)�̏ꍇ
      lt_custom_condition_cd := cv_custom_condition_fvd;     -- �ڋq�ƑԃR�[�h �t��VD
    ELSIF (it_business_low_type = cv_business_low_type_n_vd) THEN                                   -- �Ƒԁi�����ށj�[�iVD�̏ꍇ
      lt_custom_condition_cd := cv_custom_condition_nvd;     -- �ڋq�ƑԃR�[�h �[�iVD
    ELSE                                                                                            -- ���̑��̋Ƒԁi�����ށj�̏ꍇ
      lt_custom_condition_cd := cv_custom_condition_gvd;     -- �ڋq�ƑԃR�[�h ���
    END IF; 
    -- 2.�l��/�Љ�]�ƈ���菊�����_���擾���܂��B
    -- ===============================
    -- �������_�擾���� 
    -- ===============================
    xxcsm_common_pkg.get_employee_foothold(
       iv_employee_code   => it_employee_number                                                     -- �]�ƈ��R�[�h 
      ,id_comparison_date => it_cnvs_date                                                           -- �ڋq�l����
      ,ov_foothold_code   => lt_location_cd                                                         -- ���_�R�[�h
      ,ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W            
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h              
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  
    );

    -- �������_�擾�Ɏ��s�����ꍇ
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--    IF   (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
    IF   (lv_retcode <> cv_status_normal) 
      OR (lt_location_cd IS NULL) THEN                                                              -- ���_�R�[�h
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name_csm                                        -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_err_loca_msg                                               -- �������_�s���G���[
                  ,iv_token_name1  => cv_empcd_tkn                                                  -- �]�ƈ��R�[�h�g�[�N����
                  ,iv_token_value1 => it_employee_number                                            -- �]�ƈ��R�[�h
                  ,iv_token_name2  => cv_gcd_tkn                                                    -- �ڋq�l�����g�[�N����
                  ,iv_token_value2 => it_cnvs_date                                                  -- �ڋq�l����
                 );
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--��������������������������������������������������������������������������������������������������
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END IF;
    -- 3.���_�R�[�h�A�J�X�^���v���t�@�C���̊K�w����ɁAxxcsm:����r���[���畔���R�[�h���擾���܂��B
    --   �擾�ł��Ȃ��ꍇ�A�ڋq�P�ʂŃX�L�b�v���܂��B
    BEGIN
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      ln_check_cnt := 0;                                                                            -- �ϐ��̏�����
      lt_post_cd := NULL;                                                                           -- �ϐ��̏�����
      LOOP
        EXIT WHEN ln_check_cnt >= ln_loc_lv_cnt                                                     -- �|�C���g�Z�o�p�����K�w�̌�����
              OR  lt_post_cd IS NOT NULL;                                                           -- �����R�[�h���擾�ł���܂�
        ln_check_cnt := ln_check_cnt + 1;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
--//+UPD START  2009/07/07 0000254 M.Ohtsuki
--        SELECT DECODE(gv_post_level,'L6',xlllv.cd_level6 
--��������������������������������������������������������������������������������������������������
         SELECT DECODE(gt_loc_lv_tab(ln_check_cnt),'L6',xlllv.cd_level6 
--//+UPD END    2009/07/07 0000254 M.Ohtsuki
                                   ,'L5',xlllv.cd_level5 
                                   ,'L4',xlllv.cd_level4 
                                   ,'L3',xlllv.cd_level3 
                                   ,'L2',xlllv.cd_level2 
                                   ,'L1',xlllv.cd_level1 
                                   ,                NULL
                      ) cd_post
          INTO lt_post_cd            
          FROM xxcsm_loc_level_list_v xlllv
         WHERE DECODE(xlllv.location_level ,'L6',xlllv.cd_level6
                                           ,'L5',xlllv.cd_level5
                                           ,'L4',xlllv.cd_level4
                                           ,'L3',xlllv.cd_level3
                                           ,'L2',xlllv.cd_level2
                                           ,'L1',xlllv.cd_level1
                                           ,                NULL
                      ) = lt_location_cd
           AND ROWNUM = 1;
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      END LOOP;
      IF (lt_post_cd IS NULL) THEN                                                                  -- �����R�[�h�����o�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_err_post_msg                                             -- �����R�[�h�擾�G���[
                    ,iv_token_name1  => cv_account_tkn                                              -- �ڋq�R�[�h�g�[�N����
                    ,iv_token_value1 => it_account_number                                           -- �ڋq�R�[�h
                    ,iv_token_name2  => cv_loca_tkn                                                 -- ���_�R�[�h�g�[�N����
                    ,iv_token_value2 => lt_location_cd                                              -- ���_�R�[�h
                   );
        lv_errbuf := lv_errmsg;
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--��������������������������������������������������������������������������������������������������
      RAISE global_skip_expt;
--//+UPD END    2009/07/14 0000663 M.Ohtsuki
      END IF;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_err_post_msg                                             -- �����R�[�h�擾�G���[
                    ,iv_token_name1  => cv_account_tkn                                              -- �ڋq�R�[�h�g�[�N����
                    ,iv_token_value1 => it_account_number                                           -- �ڋq�R�[�h
                    ,iv_token_name2  => cv_loca_tkn                                                 -- ���_�R�[�h�g�[�N����
                    ,iv_token_value2 => lt_location_cd                                              -- ���_�R�[�h
                   );
        lv_errbuf := lv_errmsg;
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--��������������������������������������������������������������������������������������������������
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END;   
    -- 4.�Ώۏ]�ƈ��̎��i�R�[�h�A�E���R�[�h�A�E��R�[�h���擾���܂��B
    xxcsm_common_pkg.get_employee_info(
       iv_employee_code   => it_employee_number                                                     -- �]�ƈ��R�[�h 
      ,id_comparison_date => it_cnvs_date                                                           -- �ڋq�l����
      ,ov_capacity_code   => lv_qualificate_cd                                                      -- ���i�R�[�h
      ,ov_duty_code       => lv_duties_cd                                                           -- �E���R�[�h
      ,ov_job_code        => lv_job_type_cd                                                         -- �E��R�[�h
      ,ov_new_old_type    => lv_new_old_type                                                        -- �V���t���O�i1�F�V�A2�F���j
      ,ov_errbuf          => lv_errbuf                                                              -- �G���[�E���b�Z�[�W            
      ,ov_retcode         => lv_retcode                                                             -- ���^�[���E�R�[�h              
      ,ov_errmsg          => lv_errmsg                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W  
    );
    -- ���i���̎擾�Ɏ��s�����ꍇ�A�ڋq�P�ʂɃX�L�b�v���܂��B
    IF     (lv_retcode <> cv_status_normal) 
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
        OR (lv_qualificate_cd IS NULL)                                                              -- ���i�R�[�h
        OR (lv_job_type_cd    IS NULL)                                                              -- �E��R�[�h
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
        OR (lv_duties_cd IS NULL) THEN                                                              
        lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name_csm                                        -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_err_emp_msg                                                -- �]�ƈ����擾�G���[
                  ,iv_token_name1  => cv_account_tkn                                                -- �ڋq�R�[�h�g�[�N����
                  ,iv_token_value1 => it_account_number                                             -- �ڋq�R�[�h
                  ,iv_token_name2  => cv_empcd_tkn                                                  -- �]�ƈ��R�[�h�g�[�N����
                  ,iv_token_value2 => it_employee_number                                            -- �]�ƈ��R�[�h
                  ,iv_token_name3  => cv_gcd_tkn                                                    -- �ڋq�l�����g�[�N����
                  ,iv_token_value3 => it_cnvs_date                                                  -- �ڋq�l����
                 );
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--��������������������������������������������������������������������������������������������������
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END IF;
    -- 5.�ڋq�l�����]�ƈ����[�N�e�[�u���֍쐬�^�X�V���s�Ȃ��܂��B
    -- ===============================
    -- ���o�^�̏ꍇ�A�쐬���܂��B
    -- ===============================
    IF (iv_cust_work_flg = cv_cust_work_nasi) THEN
      INSERT INTO xxcsm_wk_new_cust_get_emp(                                                        -- �ڋq�l�����]�ƈ����[�N�e�[�u��
        subject_year                                                                                -- �Ώ۔N�x
       ,account_number                                                                              -- �ڋq�R�[�h
       ,custom_condition_cd                                                                         -- �ڋq�ƑԃR�[�h
       ,employee_number                                                                             -- �]�ƈ��R�[�h
       ,post_cd                                                                                     -- �����R�[�h
       ,qualificate_cd                                                                              -- ���i�R�[�h
       ,duties_cd                                                                                   -- �E���R�[�h
       ,job_type_cd                                                                                 -- �E��R�[�h
       ,location_cd                                                                                 -- ���_�R�[�h
       ,get_custom_date                                                                             -- �ڋq�l����
       ,decision_flg                                                                                -- �m��t���O
       ,get_intro_kbn                                                                               -- �l���E�Љ�敪
       ,created_by                                                                                  -- �쐬��
       ,creation_date                                                                               -- �쐬��
       ,last_updated_by                                                                             -- �ŏI�X�V��
       ,last_update_date                                                                            -- �ŏI�X�V��
       ,last_update_login                                                                           -- �ŏI�X�V���O�C��
       ,request_id                                                                                  -- �v��ID
       ,program_application_id                                                                      -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,program_id                                                                                  -- �R���J�����g�E�v���O����ID
       ,program_update_date                                                                         -- �v���O�����ɂ��X�V��
      ) VALUES (                                                                                     
        it_year                                                                                     -- �Ώ۔N�x   
       ,it_account_number                                                                           -- �ڋq�R�[�h
       ,lt_custom_condition_cd                                                                      -- �ڋq�ƑԃR�[�h
       ,it_employee_number                                                                          -- �]�ƈ��R�[�h
       ,lt_post_cd                                                                                  -- �����R�[�h
       ,lv_qualificate_cd                                                                           -- ���i�R�[�h
       ,lv_duties_cd                                                                                -- �E���R�[�h
       ,lv_job_type_cd                                                                              -- �E��R�[�h
       ,lt_location_cd                                                                              -- �l�����_�R�[�h
       ,it_cnvs_date                                                                                -- �ڋq�l����
       ,cv_mikakutei                                                                                -- �m��t���O
       ,it_get_intro_kbn                                                                            -- �l���E�Љ�敪
       ,cn_created_by                                                                               -- �쐬��
       ,cd_creation_date                                                                            -- �쐬��
       ,cn_last_updated_by                                                                          -- �ŏI�X�V��
       ,cd_last_update_date                                                                         -- �ŏI�X�V��
       ,cn_last_update_login                                                                        -- �ŏI�X�V���O�C��
       ,cn_request_id                                                                               -- �v��ID
       ,cn_program_application_id                                                                   -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,cn_program_id                                                                               -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                                                                      -- �v���O�����ɂ��X�V��
      );
    -- ===============================
    -- �o�^�ς̏ꍇ�A�X�V���܂��B
    -- ���ߓ������ڋq�l�����̊ԁA�]�ƈ������ŐV�����܂��B�i�}�X�^�s���Ή��j
    -- ���ߓ����ڋq�l�����̏ꍇ�A�]�ƈ������ŐV�����܂���B�i�l�������_�̏]�ƈ�����ێ�����j
    -- ===============================
    ELSIF (iv_cust_work_flg = cv_cust_work_ari) THEN
      UPDATE xxcsm_wk_new_cust_get_emp xwncge                                                       -- �ڋq�l�����]�ƈ����[�N�e�[�u��
      SET xwncge.custom_condition_cd    =  lt_custom_condition_cd                                   -- �ڋq�ƑԃR�[�h
         ,xwncge.post_cd                =  DECODE(lv_new_old_type,cv_empinfo_upd,lt_post_cd,xwncge.post_cd)               -- �����R�[�h
         ,xwncge.qualificate_cd         =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_qualificate_cd,xwncge.qualificate_cd) -- ���i�R�[�h
         ,xwncge.duties_cd              =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_duties_cd,xwncge.duties_cd)           -- �E���R�[�h
         ,xwncge.job_type_cd            =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_job_type_cd,xwncge.job_type_cd)       -- �E��R�[�h
         ,xwncge.location_cd            =  DECODE(lv_new_old_type,cv_empinfo_upd,lt_location_cd,xwncge.location_cd)       -- ���_�R�[�h
         ,xwncge.get_custom_date        =  it_cnvs_date                                             -- �ڋq�l����
         ,xwncge.get_intro_kbn          =  it_get_intro_kbn                                         -- �l���E�Љ�敪
         ,xwncge.last_updated_by        =  cn_last_updated_by                                       -- �ŏI�X�V��
         ,xwncge.last_update_date       =  cd_last_update_date                                      -- �ŏI�X�V��
         ,xwncge.last_update_login      =  cn_last_update_login                                     -- �ŏI�X�V���O�C��
         ,xwncge.request_id             =  cn_request_id                                            -- �v��ID
         ,xwncge.program_application_id =  cn_program_application_id                                -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,xwncge.program_id             =  cn_program_id                                            -- �R���J�����g�E�v���O����ID
         ,xwncge.program_update_date    =  cd_program_update_date                                   -- �v���O�����ɂ��X�V��
      WHERE xwncge.subject_year = it_year                                                           -- �Ώ۔N�x
        AND xwncge.account_number = it_account_number                                               -- �ڋq�R�[�h
        AND xwncge.employee_number = it_employee_number                                             -- �l���c�ƈ��R�[�h
        AND xwncge.get_intro_kbn = it_get_intro_kbn                                                 -- �l���^�Љ�敪
      ;
    END IF;

  EXCEPTION
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
    WHEN global_skip_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END make_work_table;
--
  /**********************************************************************************
   * Procedure Name   : insert_hst_table
   * Description      : �V�K�l���|�C���g�ڋq�ʗ����e�[�u���쐬����
   ***********************************************************************************/
  PROCEDURE insert_hst_table(
     it_get_intro_kbn    xxcsm_wk_new_cust_get_emp.get_intro_kbn%TYPE
    ,it_year             xxcsm_wk_new_cust_get_emp.subject_year%TYPE
    ,it_account_number   xxcsm_wk_new_cust_get_emp.account_number%TYPE
    ,it_employee_number  xxcsm_wk_new_cust_get_emp.employee_number%TYPE
    ,it_job_type_cd      xxcsm_wk_new_cust_get_emp.job_type_cd%TYPE
    ,it_business_low_type xxcsm_new_cust_point_hst.business_low_type%TYPE
    ,it_point            xxcsm_new_cust_point_hst.point%TYPE
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W                          --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h                            --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W                --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_hst_table';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
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
     -- �Љ�҂̓o�^ ���v���V�[�W���[����
    INSERT INTO xxcsm_new_cust_point_hst(                                                           -- �V�K�l���|�C���g�ڋq�ʗ����e�[�u��
      subject_year                                                                                  -- �Ώ۔N�x
     ,year_month                                                                                    -- �N��
     ,month_no                                                                                      -- ��
     ,account_number                                                                                -- �ڋq�R�[�h
     ,custom_condition_cd                                                                           -- �ڋq�ƑԃR�[�h
     ,get_custom_date                                                                               -- �ڋq�l����
     ,employee_number                                                                               -- �]�ƈ��R�[�h
     ,post_cd                                                                                       -- �����R�[�h
     ,qualificate_cd                                                                                -- ���i�R�[�h
     ,duties_cd                                                                                     -- �E���R�[�h
     ,location_cd                                                                                   -- ���_�R�[�h
     ,point                                                                                         -- �|�C���g
     ,business_low_type                                                                             -- �Ƒԁi�����ށj
     ,data_kbn                                                                                      -- �f�[�^�敪
     ,evaluration_kbn                                                                               -- �V�K�]���Ώۋ敪
     ,get_intro_kbn                                                                                 -- �l���E�Љ�敪
     ,created_by                                                                                    -- �쐬��
     ,creation_date                                                                                 -- �쐬��
     ,last_updated_by                                                                               -- �ŏI�X�V��
     ,last_update_date                                                                              -- �ŏI�X�V��
     ,last_update_login                                                                             -- �ŏI�X�V���O�C��
     ,request_id                                                                                    -- �v��ID
     ,program_application_id                                                                        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
     ,program_id                                                                                    -- �R���J�����g�E�v���O����ID
     ,program_update_date                                                                           -- �v���O�����ɂ��X�V��
    ) 
    SELECT xwncge.subject_year                                     subject_year                     -- �Ώ۔N�x
          ,TO_NUMBER(TO_CHAR(xwncge.get_custom_date,'YYYYMM'))     get_custom_yyyymm                -- �N��(�ڋq�l����YYYYMM)
          ,TO_NUMBER(TO_CHAR(xwncge.get_custom_date,'MM'))         get_custom_mm                    -- ��(�ڋq�l����MM)
          ,xwncge.account_number                                   account_number                   -- �ڋq�R�[�h
          ,xwncge.custom_condition_cd                              custom_condition_cd              -- �ڋq�ƑԃR�[�h
          ,xwncge.get_custom_date                                  get_custom_date                  -- �ڋq�l����
          ,xwncge.employee_number                                  employee_number                  -- �]�ƈ��R�[�h
          ,xwncge.post_cd                                          post_cd                          -- �����R�[�h
          ,xwncge.qualificate_cd                                   qualificate_cd                   -- ���i�R�[�h
          ,xwncge.duties_cd                                        duties_cd                        -- �E���R�[�h
          ,xwncge.location_cd                                      location_cd                      -- ���_�R�[�h
          ,it_point                                                point                            -- �|�C���g
          ,it_business_low_type                                    business_low_type                -- �Ƒԁi�����ށj
          ,cn_new_data                                             new_data                         -- �V�K�l���|�C���g�f�[�^
          ,xwncge.evaluration_kbn                                  evaluration_kbn                  -- �V�K�]���Ώۋ敪
          ,xwncge.get_intro_kbn                                    get_intro_kbn                    -- �l���^�Љ�敪
          ,cn_created_by                                           created_by                       -- �쐬��
          ,cd_creation_date                                        creation_date                    -- �쐬��
          ,cn_last_updated_by                                      last_updated_by                  -- �ŏI�X�V��
          ,cd_last_update_date                                     last_update_date                 -- �ŏI�X�V��
          ,cn_last_update_login                                    last_update_login                -- �ŏI�X�V���O�C��
          ,cn_request_id                                           request_id                       -- �v��ID
          ,cn_program_application_id                               program_application_id           -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
          ,cn_program_id                                           program_id                       -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                  program_update_date              -- �v���O�����ɂ��X�V��
      FROM xxcsm_wk_new_cust_get_emp xwncge                                                         -- �ڋq�l�����]�ƈ����[�N�e�[�u��
     WHERE xwncge.subject_year = it_year                                                            -- �Ώ۔N�x
       AND xwncge.account_number = it_account_number                                                -- �ڋq�R�[�h
       AND xwncge.employee_number = it_employee_number                                              -- �]�ƈ��R�[�h
       AND xwncge.get_intro_kbn = it_get_intro_kbn                                                  -- �l���^�Љ�敪
       AND xwncge.job_type_cd = DECODE(it_get_intro_kbn,cv_intro,cv_sales,xwncge.job_type_cd)       -- �Љ�҂̏ꍇ�A�c�ƐE�̂݁A�l���҂̏ꍇ�A������
    ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_hst_table;
--
  /**********************************************************************************
   * Procedure Name   : update_work_table
   * Description      : ���[�N�e�[�v���m��t���O�^�V�K�]���Ώۋ敪�X�V����  �l���c�ƈ��^�Љ�]�ƈ��̗������X�V����B
   ***********************************************************************************/
  PROCEDURE update_work_table(
     it_year             IN         xxcsm_wk_new_cust_get_emp.subject_year%TYPE
    ,it_account_number   IN         xxcsm_wk_new_cust_get_emp.account_number%TYPE
    ,it_decision_flg     IN         xxcsm_wk_new_cust_get_emp.decision_flg%TYPE
    ,it_evaluration_kbn  IN         xxcsm_wk_new_cust_get_emp.evaluration_kbn%TYPE
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W                          --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h                            --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W                --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_work_table';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
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
    UPDATE xxcsm_wk_new_cust_get_emp xwncge                                                         -- �ڋq�l�����]�ƈ����[�N�e�[�u��
    SET decision_flg           =  it_decision_flg                                                   -- �m��t���O
       ,evaluration_kbn        =  it_evaluration_kbn                                                -- �V�K�]���Ώۋ敪
       ,last_updated_by        =  cn_last_updated_by                                                -- �ŏI�X�V��
       ,last_update_date       =  cd_last_update_date                                               -- �ŏI�X�V��
       ,last_update_login      =  cn_last_update_login                                              -- �ŏI�X�V���O�C��
       ,request_id             =  cn_request_id                                                     -- �v��ID
       ,program_application_id =  cn_program_application_id                                         -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
       ,program_id             =  cn_program_id                                                     -- �R���J�����g�E�v���O����ID
       ,program_update_date    =  cd_program_update_date                                            -- �v���O�����ɂ��X�V��
    WHERE xwncge.subject_year = it_year                                                             -- �Ώ۔N�x
      AND xwncge.account_number = it_account_number                                                 -- �ڋq�R�[�h
    ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_work_table;
--
  /**********************************************************************************
   * Procedure Name   : set_new_point_loop
   * Description      : �V�K�l���|�C���g�쐬���[�v
   *                  : �ڋq���擾����(A-5)
   ***********************************************************************************/
  PROCEDURE set_new_point_loop(
     it_year             IN         xxcsm_new_cust_point_hst.subject_year%TYPE                      -- �Ώ۔N�x
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W                          --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h                            --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W                --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_new_point_loop';                       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lt_decision_flg_get      xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- �l���c�ƈ��m��t���O
    lt_decision_flg_intro    xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- �Љ�]�ƈ��m��t���O
    lt_decision_flg_upd      xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- �X�V�p�m��t���O
    lv_cust_work_flg         VARCHAR2(1);                                                           -- �ڋq�l�������[�N�L���t���O
    lt_evaluration_kbn       xxcsm_wk_new_cust_get_emp.evaluration_kbn%TYPE;                        -- �X�V�p�V�K�]���Ώۋ敪
    lt_point                 xxcsm_new_cust_point_hst.point%TYPE;                                   -- �l���|�C���g
    lt_custom_condition_cd   xxcsm_mst_grant_point.custom_condition_cd%TYPE;                        -- �ڋq�ƑԃR�[�h
    lt_grant_condition_point xxcsm_mst_grant_point.grant_condition_point%TYPE;                      -- �|�C���g�t�^����
    lt_post_cd               xxcsm_mst_grant_point.post_cd%TYPE;                                    -- �����R�[�h
    lt_duties_cd             xxcsm_mst_grant_point.duties_cd%TYPE;                                  -- �E���R�[�h
    lt_1st_month             xxcsm_mst_grant_point.grant_point_target_1st_month%TYPE;               -- �|�C���g�t�^�����Ώی�_����
    lt_2nd_month             xxcsm_mst_grant_point.grant_point_target_2nd_month%TYPE;               -- �|�C���g�t�^�����Ώی�_����
    lt_3rd_month             xxcsm_mst_grant_point.grant_point_target_3rd_month%TYPE;               -- �|�C���g�t�^�����Ώی�_���X��
    lt_price                 xxcsm_mst_grant_point.grant_point_condition_price%TYPE;                -- �|�C���g�t�^�������z
    lv_point_cond_flg        VARCHAR2(1);                                                           -- �|�C���g�����L���t���O
    ln_add_mm                NUMBER(1);                                                             -- ����
    ln_dummy                 NUMBER;                                                                -- �|�C���g�t�^�����ŏI������p
    lv_chk_jisseki_flg       VARCHAR2(1);                                                           -- �̔����уf�[�^�Ƃ̔���p
    lt_amount_1st            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- �{�̋��z�����v
    lt_amount_2nd            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- �{�̋��z�����v
    lt_amount_3rd            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- �{�̋��z���X���v
    lt_amount_all            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- �{�̋��z�S���v
    lv_error_flg             VARCHAR2(1);                                                           -- �G���[�t���O
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  set_new_point_cur(                                                                      -- �ڋq���擾�J�[�\��
       it_year xxcsm_new_cust_point_hst.subject_year%TYPE                                           -- �Ώ۔N�x
      ,it_set_of_bks_id gl_period_statuses.set_of_books_id%TYPE                                     -- ��v����ID
     )
    IS
      SELECT  hca.account_number         account_number                                             -- �ڋq�R�[�h
             ,hp.duns_number_c           duns_number_c                                              -- �ڋq�X�e�[�^�X
             ,xca.business_low_type      business_low_type                                          -- �Ƒԁi�����ށj
             ,xca.new_point_div          new_point_div                                              -- �V�K�|�C���g�敪
             ,xca.new_point              new_point                                                  -- �V�K�|�C���g
             ,xca.intro_business_person  intro_business_person                                      -- �Љ�]�ƈ�
             ,xca.intro_base_code        intro_base_code                                            -- �Љ�_
             ,xca.cnvs_date              cnvs_date                                                  -- �ڋq�l����
             ,xca.stop_approval_date     stop_approval_date                                         -- ���~���ϓ�
             ,xca.cnvs_business_person   cnvs_business_person                                       -- �l���c�ƈ�
             ,xca.cnvs_base_code         cnvs_base_code                                             -- �l�����_
             ,xca.start_tran_date        start_tran_date                                            -- ��������
        FROM  hz_cust_accounts hca
             ,hz_parties hp
             ,xxcmm_cust_accounts xca
             ,(SELECT  TRUNC(MIN(start_date)) year_start_date
                      ,TRUNC(MAX(end_date))   year_end_date
               FROM   gl_sets_of_books gsob
                     ,gl_periods       gp
               WHERE  gsob.set_of_books_id = it_set_of_bks_id
               AND    gsob.period_set_name = gp.period_set_name
               AND    gp.period_year       = it_year)   gpv
       WHERE  TRUNC(xca.cnvs_date) >= gpv.year_start_date                                           -- �ڋq�l���� >= ��v���ԊJ�n��
         AND  TRUNC(xca.cnvs_date) <= gpv.year_end_date                                             -- �ڋq�l���� <= ��v���ԏI����
         AND  hca.cust_account_id = xca.customer_id
         AND  hca.party_id = hp.party_id
         AND  xca.new_point_div = cv_new_point                                                      -- �V�K�|�C���g�敪���V�K
         AND  hca.customer_class_code = cv_customer_class_cust                                      -- �ڋq�敪�i10�F�ڋq�j
         AND  hp.duns_number_c IN (
                SELECT  flv.lookup_code    duns_number_c                                            -- �ڋq�X�e�[�^�X
                  FROM  fnd_lookup_values  flv                                                      -- �N�C�b�N�R�[�h�l
                 WHERE  flv.lookup_type        = cv_point_custom_status                             -- �ڋq�X�e�[�^�X���b�N�A�b�v�^�C�v
                   AND  flv.language           = cv_lang                                            -- ����('JA')
                   AND  flv.enabled_flag       = cv_flg_y                                           -- �L���t���O
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--                   AND  flv.start_date_active <= gd_process_date
--                   AND  NVL(flv.end_date_active,SYSDATE)   >= gd_process_date
--��������������������������������������������������������������������������������������������������
                   AND  NVL(flv.start_date_active,gd_process_date) <= gd_process_date
                   AND  NVL(flv.end_date_active,gd_process_date)   >= gd_process_date
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
                )
         AND  NVL(xca.new_point,0) <> 0                                                             -- �V�K�|�C���g�����ݒ�܂���0�ȊO
      ;
--
    CURSOR  set_month_amount_cur(                                                                   -- �̔����ю擾�J�[�\��
       it_account_number xxcos_sales_exp_headers.ship_to_customer_code%TYPE                         -- �ڋq�R�[�h
      ,it_year_month xxcos_sales_exp_headers.delivery_date%TYPE                                     -- ���єN��
     )
    IS
       SELECT NVL(SUM(xseh.pure_amount_sum),0) amount                                               -- �{�̋��z�̍��v
         FROM xxcsm_sales_exp_headers_v xseh                                                        -- �̔����уw�b�_�r���[
        WHERE xseh.ship_to_customer_code = it_account_number                                        -- �ڋq�R�[�h
          AND TRUNC(xseh.delivery_date,'MM') = it_year_month                                        -- �[�����P��
          AND NOT EXISTS (SELECT 'X'                                                                -- �敪��5�F���^�A6�F���{������
                            FROM xxcsm_sales_exp_lines_v xsel                                       -- �̔����і��׃r���[
                           WHERE xsel.sales_exp_header_id = xseh.sales_exp_header_id                -- ����w�b�_ID�Ŗ��ׂ𔻒�
                             AND xsel.sales_class IN (cv_kyousan,cv_mihon,cv_cm)                    -- �敪��5�F���^�A6�F���{�A7�F�L��
                         )
         ;
    set_month_amount_rec set_month_amount_cur%ROWTYPE;                                              -- �̔����є���v�擾���R�[�h
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- A-5.�ڋq���擾����
    -- ==============================================================
    <<set_new_point_loop>>                                                                          -- �����f�[�^���b�N�擾��A�폜LOOP
    FOR set_new_point_rec IN set_new_point_cur(
       it_year                                                                                      -- �Ώ۔N�x
      ,gt_set_of_bks_id                                                                             -- ��v����ID
        )
    LOOP
      --�e��t���O�̏�����
      lt_decision_flg_get := NULL;                                                                  -- �l���c�ƈ��m��t���O
      lt_decision_flg_intro := NULL;                                                                -- �Љ�]�ƈ��m��t���O
      lt_decision_flg_upd := NULL;                                                                  -- �X�V�p�m��t���O
      lv_cust_work_flg    := NULL;                                                                  -- �ڋq�l�������[�N�L���t���O
      lt_evaluration_kbn  := NULL;                                                                  -- �X�V�p�V�K�]���Ώۋ敪
      lt_point            := NULL;                                                                  -- �l���|�C���g
      lt_custom_condition_cd   := NULL;                                                             -- �ڋq�ƑԃR�[�h
      lt_grant_condition_point := NULL;                                                             -- �|�C���g�t�^����
      lt_post_cd          := NULL;                                                                  -- �����R�[�h
      lt_duties_cd        := NULL;                                                                  -- �E���R�[�h
      lt_1st_month        := NULL;                                                                  -- �|�C���g�t�^�����Ώی�_����
      lt_2nd_month        := NULL;                                                                  -- �|�C���g�t�^�����Ώی�_����
      lt_3rd_month        := NULL;                                                                  -- �|�C���g�t�^�����Ώی�_���X��
      lt_price            := NULL;                                                                  -- �|�C���g�t�^�������z
      lv_point_cond_flg   := NULL;                                                                  -- �|�C���g�����L���t���O
      ln_add_mm           := NULL;                                                                  -- ����
      ln_dummy            := NULL;                                                                  -- �|�C���g�t�^�����ŏI������p
      lv_chk_jisseki_flg  := NULL;                                                                  -- �̔����уf�[�^�Ƃ̔���p
      lt_amount_1st       := 0;                                                                     -- �{�̋��z�����v
      lt_amount_2nd       := 0;                                                                     -- �{�̋��z�����v
      lt_amount_3rd       := 0;                                                                     -- �{�̋��z���X���v
      lt_amount_all       := 0;                                                                     -- �{�̋��z�S���v
      lv_error_flg        := cv_error_off;                                                          -- �G���[�t���O
      -- ==============================================================
      -- �@�Ώ۔N�x���Ɋl�������V�K�ڋq�f�[�^���擾���܂��B
      -- ==============================================================
      -- �Z�[�u�|�C���g
      SAVEPOINT set_new_point;
      -- ==============================================================
      -- �A�Љ�җL�����ݒ� 
      -- ==============================================================
      IF (set_new_point_rec.intro_business_person IS NULL) THEN                                     -- �Љ�]�ƈ������ݒ�̏ꍇ
        gv_intro_umu_flg := cv_intro_nasi;                                                          -- �Љ�]�ƈ��̏����͂��Ȃ�
      ELSE                                                                                          -- �Љ�]�ƈ����ݒ肳��Ă���ꍇ
        gv_intro_umu_flg := cv_intro_ari;                                                           -- �Љ�]�ƈ��̏���������
      END IF;      
     -- ========================================
      -- A-6.�l��/�Љ���Z�b�g����
      -- A-7.���[�N�e�[�u���f�[�^�`�F�b�N����
      -- A-8.���[�N�e�[�u���f�[�^�쐬�^�X�V����
      -- ========================================
      BEGIN    
      -- ==============================================================
      -- �l���c�ƈ��L�����ݒ� 
      -- ==============================================================
        IF (set_new_point_rec.cnvs_business_person IS NULL) THEN                                    -- �l���]�ƈ������ݒ�̏ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_err_cnvs_busines_person_msg                              -- �l���]�ƈ������ݒ�G���[
                    ,iv_token_name1  => cv_account_tkn                                              -- �ڋq�R�[�h�g�[�N����
                    ,iv_token_value1 => set_new_point_rec.account_number                            -- �ڋq�R�[�h
                   );
          RAISE global_skip_expt;
        END IF;
        -- ========================================
        -- �l���c�ƈ��̏������s�Ȃ�
        -- ========================================
        -- ==============================================================
        -- A-7.���[�N�e�[�u���f�[�^�`�F�b�N�����i�l���c�ƈ��̊m���ԁj
        -- ==============================================================
        BEGIN
          SELECT xwncge.decision_flg                                                                -- �m��t���O
            INTO lt_decision_flg_get
            FROM xxcsm_wk_new_cust_get_emp xwncge                                                   -- �ڋq�l���]�ƈ����[�N�e�[�u��
           WHERE xwncge.subject_year = it_year                                                      -- �Ώ۔N�x
             AND xwncge.account_number = set_new_point_rec.account_number                           -- �ڋq�R�[�h
             AND xwncge.employee_number = set_new_point_rec.cnvs_business_person                    -- �l���c�ƈ��R�[�h
             AND xwncge.get_intro_kbn = cv_get                                                      -- �l���c�ƈ��̂�
          ;
          lv_cust_work_flg := cv_cust_work_ari;                                                     -- �ڋq�l�������[�N����
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_decision_flg_get := cv_mikakutei;                                                    -- �l���Җ��m��
            lv_cust_work_flg := cv_cust_work_nasi;                                                  -- �ڋq�l�������[�N�Ȃ�
        END; 
        -- �l���c�ƈ������m��(���[�N�e�[�u������or���m����)�Ȃ�΁A���������s����B
        IF  (lt_decision_flg_get = cv_mikakutei) THEN
          -- ==============================================================
          -- A-8.���[�N�e�[�u���f�[�^�쐬�^�X�V����
          -- ==============================================================
          make_work_table(
            it_get_intro_kbn    => cv_get                                                           -- �l���Љ�敪
           ,it_year             => it_year                                                          -- �Ώ۔N�x             
           ,it_account_number   => set_new_point_rec.account_number                                 -- �ڋq�R�[�h
           ,it_employee_number  => set_new_point_rec.cnvs_business_person                           -- �]�ƈ��R�[�h  
           ,it_cnvs_date    => set_new_point_rec.cnvs_date                                          -- �ڋq�l����
           ,it_business_low_type => set_new_point_rec.business_low_type                             -- �Ƒԁi�����ށj�R�[�h
           ,iv_cust_work_flg    => lv_cust_work_flg                                                 -- �ڋq�l�������[�N�L���t���O
           ,ov_errbuf           => lv_errbuf                                                        -- �G���[�E���b�Z�[�W            
           ,ov_retcode          => lv_retcode                                                       -- ���^�[���E�R�[�h              
           ,ov_errmsg           => lv_errmsg                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W  
          );
          -- �G���[�Ȃ�΁A�ڋq�P�ʂŏ������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--          IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
          IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
            RAISE global_skip_expt;                                                                 -- ���̌ڋq��
          END IF;
        END IF;
        -- �Љ�]�ƈ����o�^����Ă����ꍇ�A�Љ�]�ƈ��̏������s���B
        IF (gv_intro_umu_flg = cv_intro_ari) THEN
          -- ========================================
          -- �Љ�]�ƈ��̏������s���B
          -- ========================================
          -- ==============================================================
          -- A-7.���[�N�e�[�u���f�[�^�`�F�b�N�����i�Љ�]�ƈ��̊m���ԁj
          -- ==============================================================
          BEGIN
            SELECT xwncge.decision_flg                                                              -- �m��t���O
              INTO lt_decision_flg_intro
              FROM xxcsm_wk_new_cust_get_emp xwncge                                                 -- �ڋq�l���]�ƈ����[�N�e�[�u��
             WHERE xwncge.subject_year = it_year                                                    -- �Ώ۔N�x
               AND xwncge.account_number = set_new_point_rec.account_number                         -- �ڋq�R�[�h
               AND xwncge.employee_number = set_new_point_rec.intro_business_person                 -- �Љ�]�ƃR�[�h
               AND xwncge.get_intro_kbn = cv_intro                                                  -- �Љ�]�ƃR�[�h�̂�
            ;
            lv_cust_work_flg := cv_cust_work_ari;                                                   -- �ڋq�l�������[�N����
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_decision_flg_intro := cv_mikakutei;                                                -- �Љ�Җ��m��
              lv_cust_work_flg := cv_cust_work_nasi;                                                -- �ڋq�l�������[�N�Ȃ�
          END;
          -- �Љ�]�ƈ������m��Ȃ�΁A���������s����B
          IF  (lt_decision_flg_intro = cv_mikakutei) THEN
            -- ==============================================================
            -- A-8.���[�N�e�[�u���f�[�^�쐬�^�X�V����
            -- ==============================================================
            make_work_table(
              it_get_intro_kbn => cv_intro                                                          -- �l���Љ�敪
             ,it_year => it_year                                                                    -- �Ώ۔N�x             
             ,it_account_number => set_new_point_rec.account_number                                 -- �ڋq�R�[�h
             ,it_employee_number => set_new_point_rec.intro_business_person                         -- �Љ�]�ƈ��R�[�h  
             ,it_cnvs_date => set_new_point_rec.cnvs_date                                           -- �ڋq�l����
             ,it_business_low_type => set_new_point_rec.business_low_type                           -- �Ƒԁi�����ށj�R�[�h
             ,iv_cust_work_flg => lv_cust_work_flg                                                  -- �ڋq�l�������[�N�L���t���O
             ,ov_errbuf  => lv_errbuf                                                               -- �G���[�E���b�Z�[�W            
             ,ov_retcode => lv_retcode                                                              -- ���^�[���E�R�[�h              
             ,ov_errmsg  => lv_errmsg                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W  
            );
            -- �G���[�Ȃ�΁A�ڋq�P�ʂŏ������X�L�b�v����B
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--          IF (lv_retcode <> cv_status_normal) THEN
--��������������������������������������������������������������������������������������������������
          IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;                                                               -- ���̌ڋq��
            END IF;
          END IF;                                                                                   -- �Љ�]�ƈ������m��̏ꍇ�̏I��
--
        END IF;                                                                                     -- �Љ�]�ƈ�����̏ꍇ�̏I��
        -- �l���c�ƈ������m��̏ꍇ�̂ݏ������s���B
        IF (lt_decision_flg_get = cv_mikakutei) THEN
          -- ========================================
          -- A-9 �|�C���g�t�^����擾����
          -- ========================================
          -- 1.������������X�O���ȓ��ɒ��~�ڋq�Ȃ����ꍇ�A�|�C���g�t�^���Ȃ��B
          IF (set_new_point_rec.duns_number_c = cv_sts_stop )                                       -- ���~�ڋq�̏ꍇ
            AND (TRUNC(set_new_point_rec.stop_approval_date) < TRUNC(set_new_point_rec.start_tran_date + 90 )) THEN -- 90���ȓ��ɒ��~�ڋq�ƂȂ����B
              lt_evaluration_kbn := cv_grant_ng;                                                      
          ELSE
          -- 2.�|�C���g�t�^�����擾
            BEGIN
              -- ���j�[�N�L�[�ł̖₢���킹�̂��߁A�������擾�G���[�͔������Ȃ��B
              SELECT  xmgp.custom_condition_cd              custom_condition_cd                     -- �ڋq�ƑԃR�[�h
                     ,xmgp.grant_condition_point            grant_condition_point                   -- �|�C���g�t�^����
                     ,xmgp.post_cd                          post_cd                                 -- �����R�[�h
                     ,xmgp.duties_cd                        duties_cd                               -- �E���R�[�h
                     ,xmgp.grant_point_target_1st_month     target_1st_month                        -- �|�C���g�t�^�����Ώی�_����
                     ,xmgp.grant_point_target_2nd_month     target_2nd_month                        -- �|�C���g�t�^�����Ώی�_����
                     ,xmgp.grant_point_target_3rd_month     target_3rd_month                        -- �|�C���g�t�^�����Ώی�_���X��
                     ,xmgp.grant_point_condition_price      condition_price                         -- �|�C���g�t�^�������z
                INTO
                      lt_custom_condition_cd
                     ,lt_grant_condition_point
                     ,lt_post_cd
                     ,lt_duties_cd
                     ,lt_1st_month
                     ,lt_2nd_month
                     ,lt_3rd_month
                     ,lt_price
                FROM  xxcsm_mst_grant_point xmgp                                                    -- �|�C���g�t�^�����}�X�^
                     ,xxcsm_wk_new_cust_get_emp xwncge                                              -- �ڋq�l���]�ƈ����[�N�e�[�u��
               WHERE xmgp.subject_year = xwncge.subject_year                                        -- �Ώ۔N�x
                 AND xmgp.post_cd      = xwncge.post_cd                                             -- �����R�[�h
                 AND xmgp.duties_cd    = xwncge.duties_cd                                           -- �E��
                 AND xmgp.custom_condition_cd = xwncge.custom_condition_cd                          -- �ڋq�ƑԃR�[�h
                 AND xwncge.account_number = set_new_point_rec.account_number                       -- �ڋq�R�[�h
                 AND xwncge.get_intro_kbn  = cv_get                                                 -- �l���Љ�敪
                 AND xwncge.employee_number = set_new_point_rec.cnvs_business_person                -- �l���c�ƈ�
                 AND xwncge.subject_year = it_year                                                  -- �Ώ۔N�x
              ;
              lv_point_cond_flg := cv_point_cond_ari;                                               -- �|�C���g��������
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lt_evaluration_kbn := cv_grant_ok;                                                  -- �|�C���g�t�^
                lv_point_cond_flg := cv_point_cond_nasi;                                            -- �|�C���g�����Ȃ�
            END;
            IF  (lv_point_cond_flg = cv_point_cond_ari) THEN                                        -- �|�C���g��������
              --�|�C���g�t�^�����ŏI�Ώی���AR��v���Ԃ��N���[�Y����Ă��Ȃ��ꍇ�A�����݂ŕt�^���܂��B 
              -- ���������Ə������ŏI�������������{�����ƂȂ錎�����擾����B
              IF lt_3rd_month = cv_chk_on THEN                                                      -- ���X�����ŏI���̏ꍇ
                ln_add_mm := 2;
              ELSIF lt_2nd_month = cv_chk_on THEN                                                   -- �������ŏI���̏ꍇ
                ln_add_mm := 1;
              ELSIF lt_1st_month = cv_chk_on THEN                                                   -- �������ŏI���̏ꍇ
                 ln_add_mm := 0;
              END IF;
              -- �ŏI�����N���[�Y����Ă��Ȃ����Ƃ𔻒�
              SELECT COUNT(1)
                INTO ln_dummy
                FROM gl_period_statuses gps                                                         -- ��v���ԃX�e�[�^�X
               WHERE gps.application_id   = gt_ar_appl_id                                           -- �A�v���P�[�V����ID
                 AND gps.set_of_books_id  = gt_set_of_bks_id                                        -- ��v����ID
--//+UPD START 2009/04/27 T1_0713 M.Ohtsuki
--                 AND gps.closing_status  NOT IN ( cv_closing_status_c,cv_closing_status_p)          -- �N���[�Y�łȂ�
--��������������������������������������������������������������������������������������������������
                 AND (gps.closing_status = cv_closing_status_o                                      -- �I�[�v��
                    OR TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),ln_add_mm),'YYYYMM')
                    >= TO_CHAR(gd_process_date,'YYYYMM'))                                           -- ������
                 AND gps.adjustment_period_flag = cv_flg_n                                          -- �ʏ�̉�v����
--//+UPD END   2009/04/27 T1_0713 M.Ohtsuki
                 AND TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),ln_add_mm),'YYYYMM') = TO_CHAR(gps.start_date,'YYYYMM')
                ;
              IF ln_dummy >= 1 THEN
                lt_evaluration_kbn := cv_grant_ok;                                                  -- �|�C���g�t�^
                lv_chk_jisseki_flg := cv_jisseki_chk_fuyo;                                          -- �����݂ŕt�^�i���є���Ȃ��j
              ELSE
                lv_chk_jisseki_flg := cv_jisseki_chk_yo;                                            -- ���є����
              END IF;
              -- �̔����т���Ɏ��є�����s���܂��B
              IF (lv_chk_jisseki_flg = cv_jisseki_chk_yo)  THEN                                     -- ���є���
                -- �����̔����т̎擾
                IF (lt_1st_month = cv_chk_on) THEN                                                  -- �������Ώی��Ȃ��
                  OPEN set_month_amount_cur(
                     set_new_point_rec.account_number
                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),0)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_1st := 0;                                                             -- �������ъz
                  ELSE
                    lt_amount_1st := set_month_amount_rec.amount; 
                  END IF;
                  CLOSE set_month_amount_cur;
                END IF;
                -- �����̔����т̎擾
                IF (lt_2nd_month = cv_chk_on) THEN                                                   -- �������Ώی��Ȃ��
                  OPEN set_month_amount_cur(
                     set_new_point_rec.account_number
                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),1)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_2nd := 0;                                                              -- �������ъz
                  ELSE
                    lt_amount_2nd := set_month_amount_rec.amount;
                  END IF;
                  CLOSE set_month_amount_cur;
                END IF;
                -- ���X���̔����т̎擾
                IF (lt_3rd_month = cv_chk_on) THEN                                                   -- ���X�����Ώی��Ȃ��
                  OPEN set_month_amount_cur(
                     set_new_point_rec.account_number
                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),2)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_3rd := 0;                                   -- ���X�����ъz
                  ELSE
                    lt_amount_3rd := set_month_amount_rec.amount; 
                  END IF;
                  CLOSE set_month_amount_cur;
                END IF;
                -- �|�C���g�t�^�����ɑΉ�����������s���܂��B
                IF ( lt_grant_condition_point = cv_cond_all ) THEN                                  -- �Ώی��S�Ă��������z�ȏ�
                  IF    ( lt_1st_month != cv_chk_on                                                 -- �������Ώی��łȂ���
                          OR ( (lt_1st_month = cv_chk_on )                                          -- �������Ώی���
                                AND (lt_price <= lt_amount_1st)                                     -- �������т������𖞂����ꍇ
                             )
                        )
                    AND ( lt_2nd_month != cv_chk_on                                                 -- �������Ώی��łȂ���
                          OR ( (lt_2nd_month = cv_chk_on )                                          -- �������Ώی���
                                AND (lt_price <= lt_amount_2nd)                                     -- �������т������𖞂����ꍇ
                             )
                        )
                    AND ( lt_3rd_month != cv_chk_on                                                 -- ���X�����Ώی��łȂ���
                          OR ( (lt_3rd_month = cv_chk_on )                                          -- ���X�����Ώی���
                                AND (lt_price <= lt_amount_3rd)                                     -- ���X�����т������𖞂����ꍇ
                             )
                        )
                  THEN                                                                           
                    lt_evaluration_kbn := cv_grant_ok;                                              -- �|�C���g�t�^
                  ELSE
                    lt_evaluration_kbn := cv_grant_ng;                                              -- �|�C���g�t�^���Ȃ�
                  END IF;
                ELSIF ( lt_grant_condition_point = cv_cond_any ) THEN                               -- �Ώی��̂ǂꂩ���������z�ȏ�
                  IF   (  (lt_1st_month = cv_chk_on )                                                -- �������Ώی���
                        AND (lt_price <= lt_amount_1st)                                             -- �������т������𖞂����ꍇ
                       )                                                                               
                    OR ( (lt_2nd_month = cv_chk_on )                                                -- �������Ώی���
                        AND (lt_price <= lt_amount_2nd)                                             -- �������т������𖞂����ꍇ
                       )                                                                            
                    OR ( (lt_3rd_month = cv_chk_on )                                                -- ���X�����Ώی���
                        AND (lt_price <= lt_amount_3rd)                                             -- ���X�����т������𖞂����ꍇ
                       )
                  THEN                                                                           
                    lt_evaluration_kbn := cv_grant_ok;                                              -- �|�C���g�t�^
                  ELSE
                    lt_evaluration_kbn := cv_grant_ng;                                              -- �|�C���g�t�^���Ȃ�
                  END IF;
                ELSIF ( lt_grant_condition_point = cv_cond_sum ) THEN                               -- �Ώی����v���������z�ȏ�
                  --�Ώی��̂ݔ̔����т��W�v���Ă��邽�߁A�S�Ă����v���邱�ƂőΏی��̍��v���Z�o�����B
                  lt_amount_all := lt_amount_1st + lt_amount_2nd + lt_amount_3rd;
                  IF (lt_price <= lt_amount_all) THEN                                               -- ���v���z�������𖞂������ꍇ
                    lt_evaluration_kbn := cv_grant_ok;                                              -- �|�C���g�t�^
                  ELSE
                    lt_evaluration_kbn := cv_grant_ng;                                              -- �|�C���g�t�^���Ȃ�
                  END IF;
                END IF;                                                                             -- �|�C���g�t�^�����ʂ̏I��
              END IF;                                                                               -- ���є���v�̏I��
            END IF;                                                                                 -- �|�C���g�t�^��������̏I��        
          END IF;                                                                                   -- ���~�ڋq�łȂ��̏I��
          -- ========================================
          -- A-10 �|�C���g���m�蔻�菈��
          -- ========================================
          IF  (lv_point_cond_flg = cv_point_cond_ari) THEN                                          -- �|�C���g��������
            IF (lv_chk_jisseki_flg = cv_jisseki_chk_yo) THEN                                        -- ���є�����s�Ȃ����ꍇ
               lt_decision_flg_upd := cv_kakutei;                                                   -- �m��t���O���m��Ƃ���B
            ELSE
               lt_decision_flg_upd := cv_mikakutei;                                                 -- �m��t���O�𖢊m��Ƃ���B
            END IF;            
          ELSE
--//+UPD START 2009/04/22 T1_0713 M.Ohtsuki
--            -- �|�C���g���������ŁA������������3������̉�v���Ԃ��N���[�Y���Ă��邩����
--            SELECT COUNT(1)
--              INTO ln_dummy
--              FROM gl_period_statuses gps                                                           -- ��v���ԃX�e�[�^�X
--             WHERE gps.application_id   = gt_ar_appl_id                                             -- �A�v���P�[�V����ID
--               AND gps.set_of_books_id  = gt_set_of_bks_id                                          -- ��v����ID
--               AND gps.closing_status  IN ( cv_closing_status_c,cv_closing_status_p)                -- �N���[�Y���Ă���
--               AND TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),2),'YYYYMM') = TO_CHAR(gps.start_date,'YYYYMM')  -- ���X���̉�v�N���𔻒�
--              ;
--            --������������3������̉�v���Ԃ��N���[�Y���Ă���ꍇ
--            IF (ln_dummy >= 1) THEN
--              lt_decision_flg_upd := cv_kakutei;                                                    -- �m��t���O���m��Ƃ���B
--            --������������3������̉�v���Ԃ��N���[�Y���Ă��Ȃ��ꍇ
--            ELSE
--              lt_decision_flg_upd := cv_mikakutei;                                                  -- �m��t���O�𖢊m��Ƃ���B
--            END IF;
--          END IF;
--��������������������������������������������������������������������������������������������������
            -- �|�C���g�����Ȃ��ŁA�����������Ɩ����t��3�����O�ȑO�ɑ��݂��A�X�e�[�^�X���I�[�v���ȊO������
            SELECT COUNT(1)
              INTO ln_dummy
              FROM gl_period_statuses gps                                                           -- ��v���ԃX�e�[�^�X
             WHERE gps.application_id   =  gt_ar_appl_id                                            -- �A�v���P�[�V����ID
               AND gps.set_of_books_id  =  gt_set_of_bks_id                                         -- ��v����ID
               AND gps.closing_status   <>  cv_closing_status_o                                     -- �I�[�v��
               AND gps.adjustment_period_flag = cv_flg_n                                            -- �ʏ�̉�v����
               AND TO_CHAR(TRUNC(set_new_point_rec.start_tran_date,'MM'),'YYYYMM')
                   <= TO_CHAR(ADD_MONTHS(gd_process_date,-3),'YYYYMM')                              -- �����������Ɩ����t��3�����O�ȑO
               AND TO_CHAR(TRUNC(set_new_point_rec.start_tran_date,'MM'),'YYYYMM')
                    = TO_CHAR(gps.start_date,'YYYYMM')                                              -- ���������̉�v�N���𔻒�
            ;
            --���������̉�v���Ԃ��I�[�v���ȊO�̏ꍇ
            IF(ln_dummy >= 1) THEN
              lt_decision_flg_upd := cv_kakutei;                                                    -- �m��t���O���m��Ƃ���B
            --���������̉�v���Ԃ��I�[�v���̏ꍇ
            ELSE
              lt_decision_flg_upd := cv_mikakutei;                                                  -- �m��t���O�𖢊m��Ƃ���B
            END IF;
          END IF;
--//+UPD END   2009/04/22 T1_0713 M.Ohtsuki
          -- ========================================
          -- A-11 ���[�N�e�[�v���m��t���O�^�V�K�]���Ώۋ敪�X�V����  �l���c�ƈ��^�Љ�]�ƈ��̗������X�V����B
          -- ========================================
          update_work_table(
            it_year => it_year                                                                      -- �Ώ۔N�x             
           ,it_account_number => set_new_point_rec.account_number                                   -- �ڋq�R�[�h
           ,it_decision_flg => lt_decision_flg_upd                                                  -- �X�V�p�m��t���O
           ,it_evaluration_kbn => lt_evaluration_kbn                                                -- �V�K�]���Ώۋ敪
           ,ov_errbuf  => lv_errbuf                                                                 -- �G���[�E���b�Z�[�W            
           ,ov_retcode => lv_retcode                                                                -- ���^�[���E�R�[�h              
           ,ov_errmsg  => lv_errmsg                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W  
          );
          -- �G���[�Ȃ�΁A�ڋq�P�ʂŏ������X�L�b�v����B
          IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- ���̌ڋq��
--��������������������������������������������������������������������������������������������������
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
          END IF;
        END IF;                                                                                     -- �l���c�ƈ������m��̏I��
        -- ========================================
        -- A-12 �|�C���g������
        -- A-13 �V�K�l���|�C���g�ڋq�ʗ����e�[�u���쐬����
        -- ========================================
        -- �V�K�|�C���g�̐ݒ�
        lt_point := set_new_point_rec.new_point;
        -- �l���|�C���g����A�Љ�҂̓o�^
        IF  (gv_intro_umu_flg = cv_intro_ari) THEN                                                  -- �Љ�҂���̏ꍇ
          -- �l���|�C���g��
          lt_point := lt_point / 2;
          -- �Љ�҂̓o�^ 
          insert_hst_table(
            it_get_intro_kbn => cv_intro                                                            -- �l���Љ�敪
           ,it_year => it_year                                                                      -- �Ώ۔N�x             
           ,it_account_number => set_new_point_rec.account_number                                   -- �ڋq�R�[�h
           ,it_employee_number => set_new_point_rec.intro_business_person                           -- �Љ�]�ƈ��R�[�h  
           ,it_job_type_cd => cv_sales                                                              -- �E��
           ,it_business_low_type => set_new_point_rec.business_low_type                             -- �Ƒԁi�����ށj�R�[�h
           ,it_point => lt_point                                                                    -- �V�K�|�C���g
           ,ov_errbuf  => lv_errbuf                                                                 -- �G���[�E���b�Z�[�W            
           ,ov_retcode => lv_retcode                                                                -- ���^�[���E�R�[�h              
           ,ov_errmsg  => lv_errmsg                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W  
          );
          -- �G���[�Ȃ�΁A�ڋq�P�ʂŏ������X�L�b�v����B
          IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- ���̌ڋq��
--��������������������������������������������������������������������������������������������������
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
          END IF;
        END IF;     
        -- �l���҂̓o�^ 
        insert_hst_table(
          it_get_intro_kbn => cv_get                                                                -- �l���Љ�敪
         ,it_year => it_year                                                                        -- �Ώ۔N�x             
         ,it_account_number => set_new_point_rec.account_number                                     -- �ڋq�R�[�h
         ,it_employee_number => set_new_point_rec.cnvs_business_person                              -- �l���c�ƈ��R�[�h  
         ,it_job_type_cd => cv_other                                                                -- �E��(�c�ƐE�ȊO)
         ,it_business_low_type => set_new_point_rec.business_low_type                               -- �Ƒԁi�����ށj�R�[�h
         ,it_point => lt_point                                                                      -- �V�K�|�C���g
         ,ov_errbuf  => lv_errbuf                                                                   -- �G���[�E���b�Z�[�W            
         ,ov_retcode => lv_retcode                                                                  -- ���^�[���E�R�[�h              
         ,ov_errmsg  => lv_errmsg                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W  
        );
        -- �G���[�Ȃ�΁A�ڋq�P�ʂŏ������X�L�b�v����B
        IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- ���̌ڋq��
--��������������������������������������������������������������������������������������������������
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
        END IF;
--
      EXCEPTION
        WHEN  global_skip_expt then                                                                 -- �������ɃG���[����
        --  �G���[�����̉��Z
          lv_error_flg := cv_error_on;                                                              -- �G���[�t���O�ݒ�
          fnd_file.put_line(
            which  => FND_FILE.OUTPUT                                                               -- �o��
           ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          -- ���݂̌ڋq���������[���o�b�N
          ROLLBACK TO set_new_point;
      END;
--
      IF (lv_error_flg = cv_error_on) THEN
        --  �G���[�����̉��Z
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        --  ���������̉��Z
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;  
      -- �Ώی����̉��Z
      gn_target_cnt := gn_target_cnt + 1;
    END LOOP set_new_point_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_new_point_loop;
  /**********************************************************************************
   * Procedure Name   : get_ar_period_loop
   * Description      : �f�[�^�쐬�Ώۊ��Ԏ擾 (A-2)
   ***********************************************************************************/
   PROCEDURE get_ar_period_loop(
     ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ar_period_loop';                       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lt_pre_period_year gl_period_statuses.period_year%TYPE;  -- �N�x(��v���Ԗ�YYYYMM)
    -- *** �J�[�\����` ***
    CURSOR ar_open_period_cur
    IS
      SELECT  DISTINCT gps.period_year          period_year  --�N�x
             ,TO_CHAR(gps.start_date,'YYYYMM')  year_month   --�N��
      FROM   gl_period_statuses gps
      WHERE  gps.application_id   = gt_ar_appl_id
      AND    gps.set_of_books_id  = gt_set_of_bks_id
      AND    gps.closing_status   = cv_closing_status_o
      ORDER BY TO_CHAR(gps.start_date,'YYYYMM')
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
    --�L�[���ڂ̏�����
    lt_pre_period_year := NULL;
    -- ===============================
    -- AR��v����OPEN�N�x�̏���LOOP 
    -- ===============================
    <<open_period_loop>>
    FOR ar_open_period_rec IN ar_open_period_cur LOOP
--
      --OPEN��AR��v���ԃ��O�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm                                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_open_period_msg                                        -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_pym_tkn                                                -- YYYYMM
                      ,iv_token_value1 => ar_open_period_rec.year_month                             -- OPEN��v���ԔN��(YYYYMM)
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG                                                                     -- ���O
        ,buff   => gv_out_msg
      );
--
      -- �N�x�P�ʂɏ��������{���邽�߁A�N�x�ؑւ̃^�C�~���O�œ������������s
      IF (lt_pre_period_year IS NULL)
        OR (lt_pre_period_year <> ar_open_period_rec.period_year)
      THEN
        --�L�[�u���C�N���̕ێ��i�N�x�P�ʁj
        lt_pre_period_year := ar_open_period_rec.period_year;
--
        -- ===============================
        -- �e�[�u���i���R�[�h�P�ʁj�̃��b�N����(A-3)
        -- �f�[�^�폜����(A-4)
        -- ===============================
        delete_rec_with_lock(
           it_year    => ar_open_period_rec.period_year                                             -- �Ώ۔N�x
          ,ov_errbuf  => lv_errbuf                                                                  -- �G���[�E���b�Z�[�W            
          ,ov_retcode => lv_retcode                                                                 -- ���^�[���E�R�[�h              
          ,ov_errmsg  => lv_errmsg                                                                  -- ���[�U�[�E�G���[�E���b�Z�[�W  
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        set_new_point_loop(
           it_year    => ar_open_period_rec.period_year                                             -- �Ώ۔N�x
          ,ov_errbuf  => lv_errbuf                                                                  -- �G���[�E���b�Z�[�W            
          ,ov_retcode => lv_retcode                                                                 -- ���^�[���E�R�[�h              
          ,ov_errmsg  => lv_errmsg                                                                  -- ���[�U�[�E�G���[�E���b�Z�[�W  
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP open_period_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ar_period_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';                                  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
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
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    get_ar_period_loop(
       ov_errbuf  => lv_errbuf                                                                      -- �G���[�E���b�Z�[�W            
      ,ov_retcode => lv_retcode                                                                     -- ���^�[���E�R�[�h              
      ,ov_errmsg  => lv_errmsg                                                                      -- ���[�U�[�E�G���[�E���b�Z�[�W  
    );
    IF (lv_retcode <> cv_status_normal) THEN    --���x��������̂ŏC�����K�v
      RAISE global_process_expt;
    END IF;
    --�����ł��Ȃ������f�[�^�����݂����ꍇ�A�x���ŃX�e�[�^�X��߂��B
    IF (gn_error_cnt >= 1) THEN
      ov_retcode := cv_status_warn;
    END IF;
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
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
     errbuf        OUT NOCOPY VARCHAR2                                                              -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- ���^�[���E�R�[�h    --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';                                                 -- �v���O������
--
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(�V�K�l���|�C���g�W�v����)
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf                                                                     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode                                                                    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg                                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_appl_short_name_csm
                                                ,iv_name         => cv_msg_00111                    -- �z��O�G���[���b�Z�[�W
                                               );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT                                                                  -- �o��
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG                                                                     -- ���O
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
    -- =======================
    -- A-14.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- �o��
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf,1,4000);
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      retcode := cv_status_error;
      ROLLBACK;
--
--###########################  �Œ蕔 END   #######################################################
--
  END main;
END XXCSM004A04C;
/
