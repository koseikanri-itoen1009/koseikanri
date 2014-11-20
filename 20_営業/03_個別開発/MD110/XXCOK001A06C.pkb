CREATE OR REPLACE PACKAGE BODY APPS.XXCOK001A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOK001A06C(body)
 * Description      : �N���ڋq�ڍs���csv�A�b�v���[�h
 * MD.050           : MD050_COK_001_A06_�N���ڋq�ڍs���csv�A�b�v���[�h
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
 *  conv_file_upload_data  �t�@�C���A�b�v���[�h�f�[�^�ϊ�����(A-3)
 *  ins_tmp_001a06c_upload �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�o�^����(A-4)
 *  chk_validate_item      �Ó����`�F�b�N����(A-5)
 *  ins_cust_shift_info    �ڋq�ڍs���ꊇ�o�^����(A-6)
 *  upd_cust_shift_info    �ڋq�ڍs���ꊇ�X�V����(A-7)
 *  out_error_message      �G���[���b�Z�[�W�o�͏���(A-8)
 *  del_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�폜����(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/02/07    1.0   K.Nakamura       �V�K�쐬
 *  2013/03/13    1.1   K.Nakamura       �@�\�����u�N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�v�ɕύX
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
  global_lock_expt          EXCEPTION; -- ���b�N��O
  global_chk_item_expt      EXCEPTION; -- �Ó����`�F�b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOK001A06C';            -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOK';                   -- �A�v���P�[�V����
  -- �v���t�@�C��
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';        -- ��v����ID
  -- �N�C�b�N�R�[�h
  cv_yearly_cust_shift_item   CONSTANT VARCHAR2(30) := 'XXCOK1_YEARLY_CUST_SHIFT_ITEM'; -- �N���ڋq�ڍs���csv�A�b�v���[�h���ڃ`�F�b�N
  cv_cust_shift_status        CONSTANT VARCHAR2(30) := 'XXCOK1_CUST_SHIFT_STATUS';      -- �ڋq�ڍs���X�e�[�^�X
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';        -- �t�@�C���A�b�v���[�h���
  -- ���b�Z�[�W
  cv_msg_xxcok_00005          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00005';        -- �]�ƈ��擾�G���[���b�Z�[�W
  cv_msg_xxcok_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00006';        -- �t�@�C�����o�͗p���b�Z�[�W
  cv_msg_xxcok_00008          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00008';        -- ��v������擾�G���[���b�Z�[�W
  cv_msg_xxcok_00015          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015';        -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcok_00016          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';        -- �t�@�C��ID�o�͗p���b�Z�[�W
  cv_msg_xxcok_00017          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';        -- �t�@�C���p�^�[���o�͗p���b�Z�[�W
  cv_msg_xxcok_00028          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';        -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_xxcok_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';        -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
  cv_msg_xxcok_00061          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';        -- �t�@�C���A�b�v���[�h���b�N�G���[���b�Z�[�W
  cv_msg_xxcok_00062          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';        -- �t�@�C���A�b�v���[�hIF�폜�G���[���b�Z�[�W
  cv_msg_xxcok_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00065';        -- ��v�����ԏ��擾�G���[���b�Z�[�W
  cv_msg_xxcok_00066          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00066';        -- ����v�N�x�擾�G���[���b�Z�[�W
  cv_msg_xxcok_00106          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00106';        -- �t�@�C���A�b�v���[�h���̏o�͗p���b�Z�[�W
  cv_msg_xxcok_10507          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10507';        -- �ڋq�ڍs���ꊇ�A�b�v���[�h�ꎞ�\�o�^�G���[���b�Z�[�W
  cv_msg_xxcok_10508          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10508';        -- �ڋq�ڍs���ꊇ�A�b�v���[�h�ꎞ�\�X�V�G���[���b�Z�[�W
  cv_msg_xxcok_10509          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10509';        -- �ڋq�ڍs���o�^�G���[���b�Z�[�W
  cv_msg_xxcok_10510          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10510';        -- �ڋq�ڍs���X�V�G���[���b�Z�[�W
  cv_msg_xxcok_10511          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10511';        -- �ڋq�ڍs��񃍃b�N�G���[���b�Z�[�W
  cv_msg_xxcok_10512          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10512';        -- �ڋq�ڍs���K�{�G���[���b�Z�[�W
  cv_msg_xxcok_10513          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10513';        -- �ڋq�ڍs���X�e�[�^�X�G���[���b�Z�[�W
  cv_msg_xxcok_10514          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10514';        -- �ڋq�ڍs��񋒓_�R�[�h�ݒ�G���[���b�Z�[�W
  cv_msg_xxcok_10515          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10515';        -- �ڋq�ڍs���m��ς݃G���[���b�Z�[�W
  cv_msg_xxcok_10516          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10516';        -- �ڋq�ڍs���o�^�ς݃G���[���b�Z�[�W
  cv_msg_xxcok_10517          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10517';        -- �ڋq�ڍs������ς݃G���[���b�Z�[�W
  cv_msg_xxcok_10518          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10518';        -- �ڋq�ڍs���o�^�ς݁i�����j�G���[���b�Z�[�W
  cv_msg_xxcok_10519          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10519';        -- �ڋq�ڍs������ΏۂȂ��G���[���b�Z�[�W
  cv_msg_xxcok_10520          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10520';        -- �ڋq�ڍs���V���_�ύX�s�G���[���b�Z�[�W
  cv_msg_xxcok_10521          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10521';        -- �ڋq�ڍs��񓯈�t�@�C�����O���R�[�h�G���[���b�Z�[�W
  cv_msg_xxcok_10522          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10522';        -- �ڋq�ڍs��񓯈�t�@�C�����d���G���[���b�Z�[�W
  cv_msg_xxcok_10523          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10523';        -- �ڋq�ڍs���ڋq�R�[�h���݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcok_10524          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10524';        -- �ڋq�ڍs��񋌋��_�R�[�h�G���[���b�Z�[�W
  cv_msg_xxcok_10525          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10525';        -- �ڋq�ڍs���V���_�R�[�h���݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcok_10526          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10526';        -- �ڋq�ڍs���V���_�R�[�h�L���͈͊O�G���[���b�Z�[�W
  cv_msg_xxcok_10527          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10527';        -- �ڋq�ڍs����s�G���[���b�Z�[�W
  cv_msg_xxcok_10528          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10528';        -- �ڋq�ڍs��񍀖ڐ�����G���[���b�Z�[�W
  cv_msg_xxcok_10529          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10529';        -- �ڋq�ڍs��񍀖ڕs���G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_cust_code            CONSTANT VARCHAR2(20) := 'CUST_CODE';               -- �ڋq�R�[�h
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';                  -- �G���[���e�ڍ�
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';                 -- �t�@�C��ID
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';               -- �t�@�C������
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';                  -- �t�H�[�}�b�g
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';                    -- ����
  cv_tkn_lookup_value_set     CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';        -- �^�C�v
  cv_tkn_new_base_code        CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE';           -- �V���_�R�[�h
  cv_tkn_new_base_code_from   CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE_FROM';      -- �V���_�R�[�h�J�n��
  cv_tkn_new_base_code_to     CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE_TO';        -- �V���_�R�[�h�I����
  cv_tkn_prev_base_code       CONSTANT VARCHAR2(20) := 'PREV_BASE_CODE';          -- �����_�R�[�h
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- �v���t�@�C��
  cv_tkn_record_no            CONSTANT VARCHAR2(20) := 'RECORD_NO';               -- ���R�[�hNo
  cv_tkn_status               CONSTANT VARCHAR2(20) := 'STATUS';                  -- �X�e�[�^�X
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';           -- �t�@�C���A�b�v���[�h����
  -- �ڍs�敪
  cv_shift_type_1             CONSTANT VARCHAR2(1)  := '1';                       -- �N��
  -- �X�e�[�^�X�i�ڋq�ڍs���^�N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�j
  cv_status_a                 CONSTANT VARCHAR2(1)  := 'A';                       -- �m��
  cv_status_c                 CONSTANT VARCHAR2(1)  := 'C';                       -- ���
  cv_status_i                 CONSTANT VARCHAR2(1)  := 'I';                       -- ���͒�
  cv_status_w                 CONSTANT VARCHAR2(1)  := 'W';                       -- �m��O
  -- �ޑK�d��쐬�t���O
  cv_create_chg_je_flag_0     CONSTANT VARCHAR2(1)  := '0';                       -- ���쐬
  cv_create_chg_je_flag_2     CONSTANT VARCHAR2(1)  := '2';                       -- �ΏۊO
  -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X
  cv_vd_inv_trnsfr_status_0   CONSTANT VARCHAR2(1)  := '0';                       -- ���]��
  cv_vd_inv_trnsfr_status_3   CONSTANT VARCHAR2(1)  := '3';                       -- �ΏۊO
  -- �c�Ǝ��̋@�A�g�t���O
  cv_business_vd_if_flag_0    CONSTANT VARCHAR2(1)  := '0';                       -- ���A�g
  -- �c��FA�A�g�t���O
  cv_business_fa_if_flag_0    CONSTANT VARCHAR2(1)  := '0';                       -- ���A�g
  -- �A�b�v���[�h����t���O
  cv_upload_dicide_flag_i     CONSTANT VARCHAR2(1)  := 'I';                       -- �o�^
  cv_upload_dicide_flag_u     CONSTANT VARCHAR2(1)  := 'U';                       -- �X�V
  cv_upload_dicide_flag_w     CONSTANT VARCHAR2(1)  := 'W';                       -- �x��
  -- �ڋq�敪
  cv_customer_class_code_10   CONSTANT VARCHAR2(2)  := '10';                      -- �ڋq
  cv_customer_class_code_12   CONSTANT VARCHAR2(2)  := '12';                      -- ��l�ڋq
  cv_customer_class_code_14   CONSTANT VARCHAR2(2)  := '14';                      -- ���|�Ǘ���ڋq
  cv_customer_class_code_15   CONSTANT VARCHAR2(2)  := '15';                      -- �X�܉c��
  -- �ڋq�X�e�[�^�X
  cv_cust_status_20           CONSTANT VARCHAR2(2)  := '20';                      -- MC
  -- ��񒊏o�p
  cv_appl_short_name_gl       CONSTANT VARCHAR2(5)  := 'SQLGL';                   -- GL
  cv_adjustment_period_flag_n CONSTANT VARCHAR2(1)  := 'N';                       -- �������ԃt���O�i�������ԂȂ��j
  cv_yyyymmdd                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- �N��������
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                       -- 'Y'
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
  -- ������
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                       -- ������؂�
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                       -- ��������
  -- ���l
  cn_zero                     CONSTANT NUMBER       := 0;                         -- 0
  cn_one                      CONSTANT NUMBER       := 1;                         -- 1
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڃ`�F�b�N�i�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1              fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2              fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3              fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4              fnd_lookup_values.attribute4%TYPE -- ����
  );
  -- �e�[�u���^�C�v
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- �e�[�u���^
  gt_csv_data_old             xxcok_common_pkg.g_split_csv_tbl;  -- CSV�����f�[�^�i������؂菈���O�j
  gt_csv_data                 xxcok_common_pkg.g_split_csv_tbl;  -- CSV�����f�[�^�i������؂菈����j
  gt_file_data_all            xxccp_common_pkg2.g_file_data_tbl; -- �ϊ���VARCHAR2�f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_employee_code            VARCHAR2(5)  DEFAULT NULL;  -- �]�ƈ��R�[�h
  gv_status_c                 VARCHAR2(10) DEFAULT NULL;  -- ���
  gv_status_i                 VARCHAR2(10) DEFAULT NULL;  -- ���͒�
  gv_status_w                 VARCHAR2(10) DEFAULT NULL;  -- �m��O
  gn_set_of_books_id          NUMBER       DEFAULT NULL;  -- ��v����ID
  gn_item_cnt                 NUMBER       DEFAULT 0;     -- CSV���ڐ�
  gn_line_cnt                 NUMBER       DEFAULT 0;     -- CSV�����s�J�E���^
  gn_record_no                NUMBER       DEFAULT 0;     -- ���R�[�hNo
  gn_target_acctg_year        NUMBER       DEFAULT NULL;  -- ����v�N�x
  gn_ins_cnt                  NUMBER       DEFAULT 0;     -- �o�^����
  gn_upd_cnt_i                NUMBER       DEFAULT 0;     -- �X�V�����i�X�e�[�^�X�F���͒��j
  gn_upd_cnt_w                NUMBER       DEFAULT 0;     -- �X�V�����i�X�e�[�^�X�F�m��O�j
  gn_upd_cnt_c                NUMBER       DEFAULT 0;     -- �X�V�����i�X�e�[�^�X�F����j
  gd_process_date             DATE         DEFAULT NULL;  -- �Ɩ����t
  gd_cust_shift_date          DATE         DEFAULT NULL;  -- ����v�N�x����
  gb_ins_record_flg           BOOLEAN      DEFAULT TRUE;  -- �o�^�Ώۃ��R�[�h�t���O
  -- �e�[�u���ϐ�
  g_chk_item_tab              g_chk_item_ttype;        -- ���ڃ`�F�b�N
--
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- �Ó����`�F�b�N�J�[�\��
  CURSOR chk_cur
  IS
    SELECT xt0u.record_no      AS record_no      -- ���R�[�hNo
         , xt0u.cust_code      AS cust_code      -- �ڋq�R�[�h
         , xt0u.prev_base_code AS prev_base_code -- �����_�R�[�h
         , xt0u.new_base_code  AS new_base_code  -- �V���_�R�[�h
         , xt0u.status         AS status         -- �X�e�[�^�X
    FROM   xxcok_tmp_001a06c_upload xt0u         -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
    WHERE  xt0u.cust_code IS NOT NULL
    ORDER BY
           xt0u.cust_code                        -- �ڋq�R�[�h
         , xt0u.status    ASC NULLS FIRST        -- �X�e�[�^�X
         , xt0u.record_no                        -- ���R�[�hNo
  ;
  -- ���R�[�h��`
  chk_rec                     chk_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- *** ���[�J���ϐ� ***
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL; -- ���b�Z�[�W
    lv_curr_period_name       VARCHAR2(10)   DEFAULT NULL; -- ����v���Ԗ�
    lv_curr_closing_status    VARCHAR2(1)    DEFAULT NULL; -- ����v���ԃX�e�[�^�X
    ln_curr_period_year       NUMBER         DEFAULT NULL; -- ����v�N�x
    lb_retcode                BOOLEAN;                     -- ���b�Z�[�W�߂�l
--
    -- *** ���[�J���J�[�\�� ***
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- ���ږ���
           , flv.attribute1    AS attribute1  -- ���ڂ̒���
           , flv.attribute2    AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3    AS attribute3  -- �K�{�t���O
           , flv.attribute4    AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_yearly_cust_shift_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    --==============================================================
    -- �P�D�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    -- �t�@�C��ID���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00016
                    , iv_token_name1  => cv_tkn_file_id
                    , iv_token_value1 => iv_file_id
                  );
    -- �t�@�C��ID���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00017
                    , iv_token_name1  => cv_tkn_format
                    , iv_token_value1 => iv_format
                  );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
--
    --==============================================================
    -- �Q�D�Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_msg_xxcok_00028 -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �R�D�v���t�@�C���擾
    --==============================================================
    --
    BEGIN
      -- ��v����ID
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00008 -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00008 -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �S�D�N�C�b�N�R�[�h(���ڃ`�F�b�N�p��`���)�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE chk_item_cur;
    -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00015        -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_yearly_cust_shift_item -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �T�D�N�C�b�N�R�[�h(���ڃ`�F�b�N�p��`���̌���)�擾
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
--
    --==============================================================
    -- �U�D�N�C�b�N�R�[�h(�ڋq�ڍs���X�e�[�^�X�̕�����)�擾
    --==============================================================
    -- ���
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_c
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_c
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00015      -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_lookup_value_set -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_cust_shift_status    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    -- ���͒�
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_i
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_i
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00015      -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_lookup_value_set -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_cust_shift_status    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    -- �m��O
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_w
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_w
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00015      -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_lookup_value_set -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_cust_shift_status    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �V�D��v�J�����_�擾
    --==============================================================
    xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                   -- �G���[�o�b�t�@
      , ov_retcode                => lv_retcode                  -- ���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                   -- �G���[���b�Z�[�W
      , in_set_of_books_id        => gn_set_of_books_id          -- ��v����ID
      , iv_application_short_name => cv_appl_short_name_gl       -- �A�v���P�[�V�����Z�k��
      , id_object_date            => gd_process_date             -- �Ώۓ�
      , iv_adjustment_period_flag => cv_adjustment_period_flag_n -- �����t���O
      , on_period_year            => ln_curr_period_year         -- ��v�N�x
      , ov_period_name            => lv_curr_period_name         -- ��v���Ԗ�
      , ov_closing_status         => lv_curr_closing_status      -- �X�e�[�^�X
    );
    -- ���^�[���R�[�h���G���[�܂��͉�v�N�x��NULL�̏ꍇ
    IF ( ( lv_retcode = cv_status_error ) OR ( ln_curr_period_year IS NULL ) ) THEN
      -- ��v�����ԏ��擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00065 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_errmsg      -- �g�[�N���R�[�h1
                     , iv_token_value1 => SQLERRM            -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �W�D����v�N�x������擾
    --==============================================================
    xxcok_common_pkg.get_next_year_p(
        ov_errbuf           => lv_errbuf            -- �G���[�o�b�t�@
      , ov_retcode          => lv_retcode           -- ���^�[���R�[�h
      , ov_errmsg           => lv_errmsg            -- �G���[���b�Z�[�W
      , in_set_of_books_id  => gn_set_of_books_id   -- ��v����ID
      , in_period_year      => ln_curr_period_year  -- ��v�N�x
      , on_next_period_year => gn_target_acctg_year -- ����v�N�x
      , od_next_start_date  => gd_cust_shift_date   -- ����v�N�x����
    );
    -- ���^�[���R�[�h���G���[�܂��͉�v�N�x��NULL�̏ꍇ
    IF ( ( lv_retcode = cv_status_error ) OR ( gn_target_acctg_year IS NULL ) ) THEN
      -- ����v�N�x������擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00066 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_errmsg      -- �g�[�N���R�[�h1
                     , iv_token_value1 => SQLERRM            -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �X�D�]�ƈ��R�[�h�擾
    --==============================================================
    BEGIN
      gv_employee_code := xxcok_common_pkg.get_emp_code_f( cn_created_by );
    EXCEPTION
      -- �]�ƈ��R�[�h���擾�ł��Ȃ��ꍇ
      WHEN OTHERS THEN
      -- �]�ƈ��R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_msg_xxcok_00005 -- ���b�Z�[�W�R�[�h
                   );
      ov_errmsg  := lv_errmsg;
      RAISE global_api_others_expt;
    END;
--
  EXCEPTION
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
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_upload_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL; -- ���b�Z�[�W
    lb_retcode                BOOLEAN;                     -- ���b�Z�[�W�߂�l
    -- *** ���[�J���J�[�\�� ***
    -- �A�b�v���[�h�t�@�C���f�[�^�J�[�\��
    CURSOR xmfui_cur( in_file_id NUMBER )
    IS
      SELECT  xmfui.file_name             AS file_name     -- �t�@�C����
            , flv.meaning                 AS upload_object -- �t�@�C���A�b�v���[�h����
      FROM    xxccp_mrp_file_ul_interface xmfui            -- �t�@�C���A�b�v���[�hIF�e�[�u��
            , fnd_lookup_values           flv              -- �N�C�b�N�R�[�h
      WHERE   xmfui.file_id    = in_file_id
      AND     flv.lookup_type  = cv_file_upload_obj
      AND     flv.lookup_code  = xmfui.file_content_type
      AND     gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                              AND     NVL( flv.end_date_active, gd_process_date )
      AND     flv.enabled_flag = cv_flag_y
      AND     flv.language     = ct_lang
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
    -- ���R�[�h��`
    xmfui_rec                 xmfui_cur%ROWTYPE;
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
    -- �P�D�t�@�C���A�b�v���[�hIF�e�[�u�����b�N�擾
    --==============================================================
    BEGIN
      -- �I�[�v��
      OPEN xmfui_cur( TO_NUMBER(iv_file_id) );
      -- �t�F�b�`
      FETCH xmfui_cur INTO xmfui_rec;
      -- �N���[�Y
      CLOSE xmfui_cur;
      --
    EXCEPTION
      -- ���b�N�擾��O�n���h��
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00061 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- �Q�D�t�@�C���A�b�v���[�h���́A�t�@�C�����̏o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00106 
                    , iv_token_name1  => cv_tkn_upload_object
                    , iv_token_value1 => xmfui_rec.upload_object
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00006
                    , iv_token_name1  => cv_tkn_file_name
                    , iv_token_value1 => xmfui_rec.file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
--
    --==============================================================
    -- �R�DBLOB�f�[�^�ϊ�����
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , ov_file_data => gt_file_data_all      -- �ϊ���VARCHAR2�f�[�^
      , ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- ���^�[���R�[�h���G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00041 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : conv_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�ϊ�����(A-3)
   ***********************************************************************************/
  PROCEDURE conv_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conv_file_upload_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    ln_col_cnt                NUMBER  DEFAULT 0;     -- CSV���ڐ�
    lb_blank_line_flag        BOOLEAN DEFAULT FALSE; -- ��s�t���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lb_blank_line_flag := FALSE;
    gb_ins_record_flg  := TRUE;
    gt_csv_data_old.DELETE;
    gt_csv_data.DELETE;
   -- �J�E���g�A�b�v
   gn_line_cnt := gn_line_cnt + 1;
--
    --==============================================================
    -- �P�DCSV�����񕪊�
    --==============================================================
    xxcok_common_pkg.split_csv_data_p(
        iv_csv_data      => gt_file_data_all(gn_line_cnt) -- CSV������
      , on_csv_col_cnt   => ln_col_cnt                    -- CSV���ڐ�
      , ov_split_csv_tab => gt_csv_data_old               -- CSV�����f�[�^
      , ov_errbuf        => lv_errbuf                     -- �G���[�E���b�Z�[�W
      , ov_retcode       => lv_retcode                    -- ���^�[���E�R�[�h
      , ov_errmsg        => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- �Q�D���R�[�hNo�̔�
    --==============================================================
    -- ���R�[�hNo
    gn_record_no  := gn_record_no + 1;
    -- �Ώی����iCSV�̃��R�[�h���j�ݒ�
    gn_target_cnt := gn_target_cnt + 1;
    --
    --==============================================================
    -- �R�D���ڐ�����m�F
    --==============================================================
    -- ���ڐ����قȂ�ꍇ
    IF ( gn_item_cnt <> ln_col_cnt ) THEN
      -- �N���ڋq�ڍs��񍀖ڐ�����G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_10528 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_record_no   -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_record_no       -- �g�[�N���l1
                   );
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
      --
    END IF;
    --
    --==============================================================
    -- �S�D�S���ږ��ݒ�m�F
    --==============================================================
    -- �S�Ă̍��ڂ����ݒ�̏ꍇ
    IF ( TRIM( REPLACE( REPLACE( gt_file_data_all(gn_line_cnt), cv_comma, NULL ), cv_dobule_quote, NULL ) ) IS NULL ) THEN
      -- �N���ڋq�ڍs����s�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_10527 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_record_no   -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_record_no       -- �g�[�N���l1
                   );
      -- ��s�t���OON
      lb_blank_line_flag := TRUE;
      -- �Ó����`�F�b�N��O
      RAISE global_chk_item_expt;
      --
    END IF;
    --
    --==============================================================
    -- �T�D���ڃ`�F�b�N
    --==============================================================
    -- ���ڃ`�F�b�N���[�v
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      -- �������肪���݂���ꍇ�͍폜
      gt_csv_data(i) := TRIM( REPLACE( gt_csv_data_old(i), cv_dobule_quote, NULL ) );
      --
      -- ���ڃ`�F�b�N���ʊ֐�
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- ���ږ���
        , iv_item_value   => gt_csv_data(i)               -- ���ڂ̒l
        , in_item_len     => g_chk_item_tab(i).attribute1 -- ���ڂ̒���
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- ���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- �K�{�t���O
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- ���ڑ���
        , ov_errbuf       => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- �N���ڋq�ڍs��񍀖ڕs���G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_10529        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_chk_item_tab(i).meaning -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_record_no          -- �g�[�N���R�[�h2
                       , iv_token_value2 => gn_record_no              -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_errmsg             -- �g�[�N���R�[�h3
                       , iv_token_value3 => lv_errmsg                 -- �g�[�N���l3
                     );
        -- �Ó����`�F�b�N��O
        RAISE global_chk_item_expt;
        --
      END IF;
      --
    END LOOP item_check_loop;
--
  EXCEPTION
    -- �Ó����`�F�b�N��O�n���h��
    WHEN global_chk_item_expt THEN
      -- �o�^�Ώۃ��R�[�h�t���OOFF
      gb_ins_record_flg := FALSE;
      -- ��s�͌x���ɂ��Ȃ��i���b�Z�[�W�\���̂݁j
      IF ( lb_blank_line_flag = FALSE ) THEN
        -- �x�������ݒ�
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
      --==============================================================
      -- �U�D�`�F�b�N�G���[���̈ꎞ�\�o�^����
      --==============================================================
      BEGIN
        INSERT INTO xxcok_tmp_001a06c_upload(
            file_id                 -- �t�@�C��ID
          , record_no               -- ���R�[�hNo
          , cust_code               -- �ڋq�R�[�h
          , prev_base_code          -- �����_�R�[�h
          , new_base_code           -- �V���_�R�[�h
          , status                  -- �X�e�[�^�X
          , cust_shift_id           -- �ڋq�ڍs���ID
          , customer_class_code     -- �ڋq�敪
          , upload_dicide_flag      -- �A�b�v���[�h����t���O
          , error_message           -- �G���[���b�Z�[�W
        ) VALUES (
            TO_NUMBER(iv_file_id)   -- �t�@�C��ID
          , gn_record_no            -- ���R�[�hNo
          , NULL                    -- �ڋq�R�[�h
          , NULL                    -- �����_�R�[�h
          , NULL                    -- �V���_�R�[�h
          , NULL                    -- �X�e�[�^�X
          , NULL                    -- �ڋq�ڍs���ID
          , NULL                    -- �ڋq�敪
          , cv_upload_dicide_flag_w -- �A�b�v���[�h����t���O
          , lv_errmsg               -- �G���[���b�Z�[�W
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcok_10507 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                         , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END conv_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_001a06c_upload
   * Description      : �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�o�^����(A-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_001a06c_upload(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tmp_001a06c_upload'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_status                 VARCHAR2(1) DEFAULT NULL; -- �X�e�[�^�X
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �X�e�[�^�X���m��O
    IF ( gt_csv_data(4) = gv_status_w ) THEN
      lv_status := cv_status_w;
    -- �X�e�[�^�X�����͒�
    ELSIF ( gt_csv_data(4) = gv_status_i ) THEN
      lv_status := cv_status_i;
    -- �X�e�[�^�X�����
    ELSIF ( gt_csv_data(4) = gv_status_c ) THEN
      lv_status := cv_status_c;
    -- �X�e�[�^�X����L�ȊO
    ELSE
      lv_status := NULL;
    END IF;
    --
    --==============================================================
    -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�o�^����
    --==============================================================
    BEGIN
      INSERT INTO xxcok_tmp_001a06c_upload(
          file_id               -- �t�@�C��ID
        , record_no             -- ���R�[�hNo
        , cust_code             -- �ڋq�R�[�h
        , prev_base_code        -- �����_�R�[�h
        , new_base_code         -- �V���_�R�[�h
        , status                -- �X�e�[�^�X
        , cust_shift_id         -- �ڋq�ڍs���ID
        , customer_class_code   -- �ڋq�敪
        , upload_dicide_flag    -- �A�b�v���[�h����t���O
        , error_message         -- �G���[���b�Z�[�W
      ) VALUES (
          TO_NUMBER(iv_file_id) -- �t�@�C��ID
        , gn_record_no          -- ���R�[�hNo
        , gt_csv_data(1)        -- �ڋq�R�[�h
        , gt_csv_data(2)        -- �����_�R�[�h
        , gt_csv_data(3)        -- �V���_�R�[�h
        , lv_status             -- �X�e�[�^�X
        , NULL                  -- �ڋq�ڍs���ID
        , NULL                  -- �ڋq�敪
        , NULL                  -- �A�b�v���[�h����t���O
        , NULL                  -- �G���[���b�Z�[�W
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_10507 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_tmp_001a06c_upload;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : �Ó����`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_message_code           VARCHAR2(20) DEFAULT NULL;  -- ���b�Z�[�W�R�[�h
    lv_customer_class_code    VARCHAR2(2)  DEFAULT NULL;  -- �ڋq�敪
    lv_sales_base_code        VARCHAR2(4)  DEFAULT NULL;  -- ���㋒�_
    lv_aff_department_code    VARCHAR2(4)  DEFAULT NULL;  -- ����R�[�h
    lv_new_base_code          VARCHAR2(4)  DEFAULT NULL;  -- �V���_�R�[�h
    lv_status                 VARCHAR2(1)  DEFAULT NULL;  -- �X�e�[�^�X
    lv_upload_dicide_flag     VARCHAR2(1)  DEFAULT NULL;  -- �A�b�v���[�h����t���O
    lv_upload_dicide_flag_upd VARCHAR2(1)  DEFAULT NULL;  -- �A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j
    lv_err_status             VARCHAR2(10) DEFAULT NULL;  -- �G���[���X�e�[�^�X
    ln_cust_shift_id          NUMBER       DEFAULT NULL;  -- �ڋq�ڍs���ID
    ln_chk_cnt                NUMBER       DEFAULT 0;     -- �`�F�b�N�p����
    ln_dummy                  NUMBER       DEFAULT 0;     -- �_�~�[�l
    ld_start_date_active      DATE         DEFAULT NULL;  -- �J�n��
    ld_end_date_active        DATE         DEFAULT NULL;  -- �I����
    ld_cust_shift_date        DATE         DEFAULT NULL;  -- �ڋq�ڍs��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_message_code           := NULL; -- ���b�Z�[�W�R�[�h
    lv_customer_class_code    := NULL; -- �ڋq�敪
    lv_sales_base_code        := NULL; -- ���㋒�_
    lv_aff_department_code    := NULL; -- ����R�[�h
    lv_new_base_code          := NULL; -- �V���_�R�[�h
    lv_status                 := NULL; -- �X�e�[�^�X
    lv_upload_dicide_flag     := NULL; -- �A�b�v���[�h����t���O
    lv_upload_dicide_flag_upd := NULL; -- �A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j
    ln_cust_shift_id          := NULL; -- �ڋq�ڍs���ID
    ln_chk_cnt                := 0;    -- �`�F�b�N�p����
    ln_dummy                  := 0;    -- �_�~�[�l
    ld_start_date_active      := NULL; -- �J�n��
    ld_end_date_active        := NULL; -- �I����
    ld_cust_shift_date        := NULL; -- �ڋq�ڍs��
--
    --==============================================================
    -- �P�D�X�e�[�^�X�`�F�b�N
    --==============================================================
    -- �X�e�[�^�X��NULL�̏ꍇ
    IF ( chk_rec.status IS NULL ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10513;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- �Q�D����ڋq�X�e�[�^�X�`�F�b�N�P
    --==============================================================
    -- �@�X�e�[�^�X������̏ꍇ
    IF ( chk_rec.status = cv_status_c ) THEN
      -- ����ڋq�X�e�[�^�X�`�F�b�N�`�F�b�N�J�[�\��
      SELECT COUNT(1)                 AS cnt     -- �`�F�b�N����
      INTO   ln_chk_cnt
      FROM   xxcok_tmp_001a06c_upload xt0u       -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.status     = cv_status_c       -- �X�e�[�^�X�i����j
      AND    xt0u.record_no <> chk_rec.record_no -- ���R�[�hNo
      AND    xt0u.cust_code  = chk_rec.cust_code -- �ڋq�R�[�h
      ;
      -- ����ڋq�Ŏ�����R�[�h���������݂���ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
        lv_message_code := cv_msg_xxcok_10522;
        RAISE global_chk_item_expt;
      END IF;
    -- �A�X�e�[�^�X������ȊO�̏ꍇ
    ELSE
      -- ����ڋq�X�e�[�^�X�`�F�b�N�`�F�b�N�J�[�\��
      SELECT COUNT(1)                 AS cnt     -- �`�F�b�N����
      INTO   ln_chk_cnt
      FROM   xxcok_tmp_001a06c_upload xt0u       -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.status    <> cv_status_c       -- �X�e�[�^�X�i����j
      AND    xt0u.record_no <> chk_rec.record_no -- ���R�[�hNo
      AND    xt0u.cust_code  = chk_rec.cust_code -- �ڋq�R�[�h
      ;
      -- ����ڋq�Ŏ���ȊO�̃��R�[�h���������݂���ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
        lv_message_code := cv_msg_xxcok_10522;
        RAISE global_chk_item_expt;
      END IF;
      --
    END IF;
--
    --==============================================================
    -- �R�D����ڋq�X�e�[�^�X�`�F�b�N�Q
    --==============================================================
    -- ����ڋq�X�e�[�^�X�`�F�b�N�`�F�b�N�J�[�\��
    SELECT COUNT(1)                 AS cnt                   -- �`�F�b�N����
    INTO   ln_chk_cnt
    FROM   xxcok_tmp_001a06c_upload xt0u                     -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
    WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_w -- �A�b�v���[�h����t���O�i�x���j
    AND    xt0u.record_no         <> chk_rec.record_no       -- ���R�[�hNo
    AND    xt0u.cust_code          = chk_rec.cust_code       -- �ڋq�R�[�h
    ;
    -- ����ڋq�Ŋ��Ɍx�����R�[�h�����݂���ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10521;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- �S�D�����_�R�[�h�A�V���_�R�[�h�s��v�`�F�b�N
    --==============================================================
    -- �����_�R�[�h�ƐV���_�R�[�h������R�[�h�̏ꍇ
    IF ( chk_rec.prev_base_code = chk_rec.new_base_code ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10514;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- �T�D�ڋq�R�[�h�A�����_�R�[�h�`�F�b�N
    --==============================================================
    BEGIN
      SELECT hca.customer_class_code AS customer_class_code           -- �ڋq�敪
           , xca.sale_base_code      AS sale_base_code                -- ���㋒�_
      INTO   lv_customer_class_code
           , lv_sales_base_code
      FROM   hz_cust_accounts        hca                              -- �ڋq�}�X�^
           , hz_parties              hp                               -- �p�[�e�B
           , xxcmm_cust_accounts     xca                              -- �ڋq�ǉ����
      WHERE  hca.party_id            = hp.party_id                    -- �p�[�e�BID
      AND    hca.cust_account_id     = xca.customer_id                -- �ڋqID
      AND (  hca.customer_class_code IN ( cv_customer_class_code_10
                                        , cv_customer_class_code_12
                                        , cv_customer_class_code_14
                                        , cv_customer_class_code_15 ) -- �ڋq�敪
        OR ( ( hca.customer_class_code IS NULL )                      -- �ڋq�敪
        AND  ( hp.duns_number_c = cv_cust_status_20 ) ) )             -- �ڋq�X�e�[�^�X
      AND    hca.account_number      = chk_rec.cust_code              -- �ڋq�R�[�h
      ;
    EXCEPTION
      -- �@�擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
        lv_message_code := cv_msg_xxcok_10523;
        RAISE global_chk_item_expt;
    END;
    --
    -- �A���㋒�_�������_�R�[�h�ƈ�v���Ȃ��ꍇ
    IF ( lv_sales_base_code <> chk_rec.prev_base_code ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10524;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- �U�D�V���_�R�[�h�`�F�b�N
    --==============================================================
    BEGIN
      SELECT xadv.aff_department_code AS aff_department_code -- ����R�[�h
           , xadv.start_date_active   AS start_date_active   -- �J�n��
           , xadv.end_date_active     AS end_date_active     -- �I����
      INTO   lv_aff_department_code
           , ld_start_date_active
           , ld_end_date_active
      FROM   xxcok_base_all_v         xbav                   -- ���_�r���[
           , xxcok_aff_department_v   xadv                   -- ����r���[
      WHERE  xbav.base_code = xadv.aff_department_code(+)    -- ���_�R�[�h
      AND    xbav.base_code = chk_rec.new_base_code          -- ���_�R�[�h
      ;
    EXCEPTION
      -- �@�擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
        lv_message_code := cv_msg_xxcok_10525;
        RAISE global_chk_item_expt;
    END;
    --
    -- �@�擾��������R�[�h��NULL�̏ꍇ
    IF ( lv_aff_department_code IS NULL ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10525;
      RAISE global_chk_item_expt;
    END IF;
    --
    -- �A����v�N�x��������J�n���`�I�����͈͓̔��ɂȂ��ꍇ
    IF ( ( NVL( ld_start_date_active, gd_cust_shift_date ) > gd_cust_shift_date )
      OR ( NVL( ld_end_date_active, gd_cust_shift_date )   < gd_cust_shift_date ) ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10526;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- �V�D�m��σ`�F�b�N�A����s�`�F�b�N
    --==============================================================
    -- �@�ڋq�ڍs���擾
    SELECT COUNT(1)              AS cnt              -- ���݃`�F�b�N�p����
    INTO   ln_chk_cnt
    FROM   xxcok_cust_shift_info xcsi                -- �ڋq�ڍs���
    WHERE  xcsi.cust_shift_date > gd_process_date    -- �ڋq�ڍs�����Ɩ����t
    AND    xcsi.cust_shift_date < gd_cust_shift_date -- �ڋq�ڍs��������v�N�x�����
    AND    xcsi.status         <> cv_status_c        -- �X�e�[�^�X�i����j
    AND    xcsi.cust_code       = chk_rec.cust_code  -- �ڋq�R�[�h
    ;
    -- �擾���ꂽ�ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10518;
      RAISE global_chk_item_expt;
    END IF;
    -- �擾����Ȃ��ꍇ�͌p��
    -- �A����v�N�x������̌ڋq�ڍs���擾
    BEGIN
      SELECT xcsi1.cust_shift_id   AS cust_shift_id      -- �ڋq�ڍs���ID
           , xcsi1.new_base_code   AS new_base_code      -- �V���_�R�[�h
           , xcsi1.cust_shift_date AS cust_shift_date    -- �ڋq�ڍs��
           , xcsi1.status          AS status             -- �X�e�[�^�X
      INTO   ln_cust_shift_id
           , lv_new_base_code
           , ld_cust_shift_date
           , lv_status
      FROM   xxcok_cust_shift_info xcsi1                 -- �ڋq�ڍs���
      WHERE  xcsi1.cust_shift_id = (
                                     SELECT MAX(xcsi2.cust_shift_id)
                                     FROM   xxcok_cust_shift_info xcsi2                -- �ڋq�ڍs���
                                     WHERE  xcsi2.cust_shift_date = gd_cust_shift_date -- �ڋq�ڍs��������v�N�x�����
                                     AND    xcsi2.cust_code       = chk_rec.cust_code  -- �ڋq�R�[�h
                                   )
      ;
    EXCEPTION
      -- �B�ڋq�ڍs��񂪎擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �T�D�ꎞ�\�̃X�e�[�^�X������ȊO�͌p��
        -- �U�D�ꎞ�\�̃X�e�[�^�X������̏ꍇ
        IF ( chk_rec.status = cv_status_c ) THEN
          -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
          lv_message_code := cv_msg_xxcok_10519;
          RAISE global_chk_item_expt;
        END IF;
    END;
    --
    -- �C�ڋq�ڍs���̃X�e�[�^�X���m��̏ꍇ
    IF ( lv_status = cv_status_a ) THEN
      -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
      lv_message_code := cv_msg_xxcok_10515;
      RAISE global_chk_item_expt;
    -- �D�ڋq�ڍs���̃X�e�[�^�X������ȊO�͌p��
    -- �E�ڋq�ڍs���̃X�e�[�^�X������̏ꍇ
    ELSIF ( lv_status = cv_status_c ) THEN
      -- �T�D�ꎞ�\�̃X�e�[�^�X������ȊO�̏ꍇ�͌p��
      -- �U�D�ꎞ�\�̃X�e�[�^�X������̏ꍇ
      IF ( chk_rec.status = cv_status_c ) THEN
        -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
        lv_message_code := cv_msg_xxcok_10517;
        RAISE global_chk_item_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- �W�D�捞�t�@�C�����`�F�b�N
    --==============================================================
    BEGIN
      SELECT xt0u.new_base_code      AS new_base_code      -- �V���_�R�[�h
           , xt0u.status             AS status             -- �X�e�[�^�X
           , xt0u.upload_dicide_flag AS upload_dicide_flag -- �A�b�v���[�h����t���O
      INTO   lv_new_base_code
           , lv_status
           , lv_upload_dicide_flag
      FROM   xxcok_tmp_001a06c_upload xt0u                 -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.upload_dicide_flag IS NOT NULL           -- �A�b�v���[�h����t���O
      AND    xt0u.cust_code          = chk_rec.cust_code   -- �ڋq�R�[�h
      ORDER BY
             xt0u.status -- �X�e�[�^�X
      ;
    EXCEPTION
      -- �@�擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �T�D�ڋq�ڍs��񂪎擾�ł��Ă��Ȃ��ꍇ
        IF ( ln_cust_shift_id IS NULL ) THEN
          -- ����o�^�F�A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j��o�^�Ƃ��Đݒ�
          lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
          --
        -- �U�D �ڋq�ڍs��񂪓o�^�ςŐV���_�R�[�h����v�̏ꍇ
        ELSIF ( ( ln_cust_shift_id IS NOT NULL )
          AND   ( chk_rec.new_base_code = lv_new_base_code ) ) THEN
          -- 1. �X�e�[�^�X���s��v�̏ꍇ
          IF ( chk_rec.status <> lv_status ) THEN
            -- �X�e�[�^�X�X�V�F�A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j���X�V�Ƃ��Đݒ�
            lv_upload_dicide_flag_upd := cv_upload_dicide_flag_u;
          -- 2. �X�e�[�^�X����v�̏ꍇ
          ELSE
            -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
            lv_message_code := cv_msg_xxcok_10516;
            RAISE global_chk_item_expt;
          END IF;
        -- �V�D�ڋq�ڍs��񂪓o�^�ςŐV���_�R�[�h���s��v�̏ꍇ
        ELSIF ( ( ln_cust_shift_id IS NOT NULL )
          AND   ( chk_rec.new_base_code <> lv_new_base_code ) ) THEN
          -- 1. �X�e�[�^�X������̏ꍇ
          IF ( lv_status = cv_status_c ) THEN
            -- ������ꂽ�ڋq�̓o�^�F�A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j��o�^�Ƃ��Đݒ�
            lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
          -- 2. �X�e�[�^�X������ȊO�̏ꍇ
          ELSE
            -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
            lv_message_code := cv_msg_xxcok_10520;
            RAISE global_chk_item_expt;
          END IF;
          --
        END IF;
    END;
    -- �A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j���ݒ肳��Ă���ꍇ�͌p��
    IF ( lv_upload_dicide_flag_upd IS NULL ) THEN
      -- �A�擾�ł����X�e�[�^�X������̏ꍇ
      IF ( lv_status = cv_status_c ) THEN
        -- ������ꂽ�ڋq�̓o�^�F�A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j��o�^�Ƃ��Đݒ�
        lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
      -- �B�X�e�[�^�X������ȊO�̏ꍇ
      ELSE
        -- �X�e�[�^�X�X�V�F�A�b�v���[�h����t���O�i�ꎞ�\�X�V�p�j���X�V�Ƃ��Đݒ�
        lv_upload_dicide_flag_upd := cv_upload_dicide_flag_u;
      END IF;
    END IF;
--
    --==============================================================
    -- �X�D�ڋq�ڍs��񃍃b�N�擾
    --==============================================================
    -- �X�V�̏ꍇ
    IF ( lv_upload_dicide_flag_upd = cv_upload_dicide_flag_u ) THEN
      BEGIN
        SELECT xcsi.cust_shift_id    AS dummy        -- �ڋq�ڍs���ID
        INTO   ln_dummy
        FROM   xxcok_cust_shift_info xcsi            -- �ڋq�ڍs���
        WHERE  xcsi.cust_shift_id = ln_cust_shift_id -- �ڋq�ڍs���ID
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        -- �擾�ł��Ȃ��ꍇ
        WHEN global_lock_expt THEN
          -- ���b�Z�[�W�R�[�h��ݒ肵�ė�O����
          lv_message_code := cv_msg_xxcok_10511;
          RAISE global_chk_item_expt;
      END;
    END IF;
--
    --==============================================================
    -- �P�O�D�N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�X�V
    --==============================================================
    BEGIN
      UPDATE xxcok_tmp_001a06c_upload xt0u                        -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      SET    xt0u.cust_shift_id       = ln_cust_shift_id          -- �ڋq�ڍs���ID
           , xt0u.customer_class_code = lv_customer_class_code    -- �ڋq�敪
           , xt0u.upload_dicide_flag  = lv_upload_dicide_flag_upd -- �A�b�v���[�h����t���O
           , xt0u.error_message       = NULL                      -- �G���[���b�Z�[�W
      WHERE  xt0u.record_no           = chk_rec.record_no         -- ���R�[�hNo
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_10508 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
--
  EXCEPTION
--
    -- �Ó����`�F�b�N��O�n���h��
    WHEN global_chk_item_expt THEN
      -- �X�e�[�^�X���m��O
      IF ( chk_rec.status = cv_status_w ) THEN
        lv_err_status := gv_status_w;
      -- �X�e�[�^�X�����͒�
      ELSIF ( chk_rec.status = cv_status_i ) THEN
        lv_err_status := gv_status_i;
      -- �X�e�[�^�X�����
      ELSIF ( chk_rec.status = cv_status_c ) THEN
        lv_err_status := gv_status_c;
      -- �X�e�[�^�X����L�ȊO
      ELSE
        lv_err_status := NULL;
      END IF;
      --
      -- ���b�Z�[�W�R�[�h��APP-XXCOK1-10513�̏ꍇ
      IF ( lv_message_code = cv_msg_xxcok_10513 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application         -- �A�v���P�[�V�����Z�k��
                       , iv_name         => lv_message_code        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_record_no       -- �g�[�N���R�[�h1
                       , iv_token_value1 => chk_rec.record_no      -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_cust_code       -- �g�[�N���R�[�h2
                       , iv_token_value2 => chk_rec.cust_code      -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_prev_base_code  -- �g�[�N���R�[�h3
                       , iv_token_value3 => chk_rec.prev_base_code -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_new_base_code   -- �g�[�N���R�[�h4
                       , iv_token_value4 => chk_rec.new_base_code  -- �g�[�N���l4
                     );
      -- ���b�Z�[�W�R�[�h��APP-XXCOK1-10526�̏ꍇ
      ELSIF ( lv_message_code = cv_msg_xxcok_10526 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application                             -- �A�v���P�[�V�����Z�k��
                       , iv_name         => lv_message_code                            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_record_no                           -- �g�[�N���R�[�h1
                       , iv_token_value1 => chk_rec.record_no                          -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_cust_code                           -- �g�[�N���R�[�h2
                       , iv_token_value2 => chk_rec.cust_code                          -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_prev_base_code                      -- �g�[�N���R�[�h3
                       , iv_token_value3 => chk_rec.prev_base_code                     -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_new_base_code                       -- �g�[�N���R�[�h4
                       , iv_token_value4 => chk_rec.new_base_code                      -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_status                              -- �g�[�N���R�[�h5
                       , iv_token_value5 => lv_err_status                              -- �g�[�N���l5
                       , iv_token_name6  => cv_tkn_new_base_code_from                  -- �g�[�N���R�[�h6
                       , iv_token_value6 => TO_CHAR(ld_start_date_active, cv_yyyymmdd) -- �g�[�N���l6
                       , iv_token_name7  => cv_tkn_new_base_code_to                    -- �g�[�N���R�[�h7
                       , iv_token_value7 => TO_CHAR(ld_end_date_active, cv_yyyymmdd)   -- �g�[�N���l7
                     );
      -- ���b�Z�[�W�R�[�h����L�ȊO�̏ꍇ
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application         -- �A�v���P�[�V�����Z�k��
                       , iv_name         => lv_message_code        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_record_no       -- �g�[�N���R�[�h1
                       , iv_token_value1 => chk_rec.record_no      -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_cust_code       -- �g�[�N���R�[�h2
                       , iv_token_value2 => chk_rec.cust_code      -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_prev_base_code  -- �g�[�N���R�[�h3
                       , iv_token_value3 => chk_rec.prev_base_code -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_new_base_code   -- �g�[�N���R�[�h4
                       , iv_token_value4 => chk_rec.new_base_code  -- �g�[�N���l4
                       , iv_token_name5  => cv_tkn_status          -- �g�[�N���R�[�h5
                       , iv_token_value5 => lv_err_status          -- �g�[�N���l5
                     );
      END IF;
      -- �x�������ݒ�
      gn_warn_cnt := gn_warn_cnt + 1;
      --==============================================================
      -- �P�O�D�N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�X�V�i�`�F�b�N�G���[���j
      --==============================================================
      BEGIN
        UPDATE xxcok_tmp_001a06c_upload xt0u                      -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
        SET    xt0u.cust_shift_id       = ln_cust_shift_id        -- �ڋq�ڍs���ID
             , xt0u.customer_class_code = lv_customer_class_code  -- �ڋq�敪
             , xt0u.upload_dicide_flag  = cv_upload_dicide_flag_w -- �A�b�v���[�h����t���O
             , xt0u.error_message       = lv_errmsg               -- �G���[���b�Z�[�W
        WHERE  xt0u.record_no           = chk_rec.record_no       -- ���R�[�hNo
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_xxcok_10508 -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                          , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                          , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_shift_info
   * Description      : �ڋq�ڍs���ꊇ�o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE ins_cust_shift_info(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_shift_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    -- �ꊇ�o�^����
    --==============================================================
    BEGIN
      INSERT INTO xxcok_cust_shift_info(
          cust_shift_id          -- �ڋq�ڍs���ID
        , cust_code              -- �ڋq�R�[�h
        , prev_base_code         -- �����_�R�[�h
        , new_base_code          -- �V���_�R�[�h
        , cust_shift_date        -- �ڋq�ڍs��
        , target_acctg_year      -- �Ώۉ�v�N�x
        , emp_code               -- ���͎�
        , input_date             -- ���͓�
        , status                 -- �X�e�[�^�X
        , shift_type             -- �ڍs�敪
        , create_chg_je_flag     -- �ޑK�d��쐬�t���O
        , org_slip_number        -- ���`�[�ԍ�
        , vd_inv_trnsfr_status   -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X
        , base_split_flag        -- ���_�������A�g�t���O
        , business_vd_if_flag    -- �c�Ǝ��̋@�A�g�t���O
        , business_fa_if_flag    -- �c��FA�A�g�t���O
        , created_by             -- �쐬��
        , creation_date          -- �쐬��
        , last_updated_by        -- �ŏI�X�V��
        , last_update_date       -- �ŏI�X�V��
        , last_update_login      -- �ŏI�X�V���O�C��
        , request_id             -- �v��ID
        , program_application_id -- �v���O�����A�v���P�[�V����ID
        , program_id             -- �v���O����ID
        , program_update_date    -- �v���O�����X�V��
      )
      SELECT
             xxcok_cust_shift_info_s01.NEXTVAL AS cust_shift_id          -- �ڋq�ڍs���ID
           , xt0u.cust_code                    AS cust_code              -- �ڋq�R�[�h
           , xt0u.prev_base_code               AS prev_base_code         -- �����_�R�[�h
           , xt0u.new_base_code                AS new_base_code          -- �V���_�R�[�h
           , gd_cust_shift_date                AS cust_shift_date        -- �ڋq�ڍs��
           , gn_target_acctg_year              AS target_acctg_year      -- �Ώۉ�v�N�x
           , gv_employee_code                  AS emp_code               -- ���͎�
           , SYSDATE                           AS input_date             -- ���͓�
           , xt0u.status                       AS status                 -- �X�e�[�^�X
           , cv_shift_type_1                   AS shift_type             -- �ڍs�敪
           , CASE WHEN xt0u.customer_class_code IN ( cv_customer_class_code_12, cv_customer_class_code_14 )
                  THEN cv_create_chg_je_flag_2
                  ELSE cv_create_chg_je_flag_0
             END                               AS create_chg_je_flag     -- �ޑK�d��쐬�t���O
           , NULL                              AS org_slip_number        -- ���`�[�ԍ�
           , CASE WHEN xt0u.customer_class_code IN ( cv_customer_class_code_12, cv_customer_class_code_14 )
                  THEN cv_vd_inv_trnsfr_status_3
                  ELSE cv_vd_inv_trnsfr_status_0
             END                               AS vd_inv_trnsfr_status   -- VD�݌ɕۊǏꏊ�]���X�e�[�^�X
           , NULL                              AS base_split_flag        -- ���_�������A�g�t���O
           , cv_business_vd_if_flag_0          AS business_vd_if_flag    -- �c�Ǝ��̋@�A�g�t���O
           , cv_business_fa_if_flag_0          AS business_fa_if_flag    -- �c��FA�A�g�t���O
           , cn_created_by                     AS created_by             -- �쐬��
           , cd_creation_date                  AS creation_date          -- �쐬��
           , cn_last_updated_by                AS last_updated_by        -- �ŏI�X�V��
           , cd_last_update_date               AS last_update_date       -- �ŏI�X�V��
           , cn_last_update_login              AS last_update_login      -- �ŏI�X�V���O�C��
           , cn_request_id                     AS request_id             -- �v��ID
           , cn_program_application_id         AS program_application_id -- �v���O�����A�v���P�[�V����ID
           , cn_program_id                     AS program_id             -- �v���O����ID
           , cd_program_update_date            AS program_update_date    -- �v���O�����X�V��
      FROM   xxcok_tmp_001a06c_upload          xt0u                      -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_i           -- �A�b�v���[�h����t���O
      ;
      -- �o�^�����ݒ�
      gn_ins_cnt := SQL%ROWCOUNT;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_10509 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_cust_shift_info
   * Description      : �ڋq�ڍs���ꊇ�X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE upd_cust_shift_info(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cust_shift_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    ln_cnt                    NUMBER DEFAULT 0; -- ���[�v�p����
    --
    -- *** ���[�J���J�[�\�� ***
    -- �X�V�Ώێ擾�J�[�\��
    CURSOR upd_data_cur
    IS
      SELECT xt0u.cust_shift_id       AS cust_shift_id         -- �ڋq�ڍs���ID
           , xt0u.status              AS status                -- �X�e�[�^�X
      FROM   xxcok_tmp_001a06c_upload xt0u                     -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_u -- �A�b�v���[�h����t���O
    ;
    -- ���R�[�h��`
    upd_data_rec              upd_data_cur%ROWTYPE;
    --
    -- �e�[�u���^�C�v
    TYPE l_cust_shift_id_ttype IS TABLE OF xxcok_cust_shift_info.cust_shift_id%TYPE INDEX BY PLS_INTEGER;
    TYPE l_status_ttype        IS TABLE OF xxcok_cust_shift_info.status%TYPE        INDEX BY PLS_INTEGER;
    l_cust_shift_id_tab        l_cust_shift_id_ttype;
    l_status_tab               l_status_ttype;
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
    -- �P�D�X�V�Ώێ擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN upd_data_cur;
    -- �Ó����`�F�b�N���[�v
    << upd_data_loop >>
    LOOP
      -- �t�F�b�`
      FETCH upd_data_cur INTO upd_data_rec;
      EXIT WHEN upd_data_cur%NOTFOUND;
      --
      ln_cnt := ln_cnt + 1;
      -- �X�V�f�[�^�ݒ�
      l_cust_shift_id_tab(ln_cnt) := upd_data_rec.cust_shift_id;
      l_status_tab(ln_cnt)        := upd_data_rec.status;
      -- �X�V�����ݒ�
      IF ( l_status_tab(ln_cnt) = cv_status_i ) THEN
        gn_upd_cnt_i := gn_upd_cnt_i + 1;
      ELSIF ( l_status_tab(ln_cnt) = cv_status_w ) THEN
        gn_upd_cnt_w := gn_upd_cnt_w + 1;
      ELSIF ( l_status_tab(ln_cnt) = cv_status_c ) THEN
        gn_upd_cnt_c := gn_upd_cnt_c + 1;
      END IF;
    --
    END LOOP upd_data_loop;
    -- �J�[�\���N���[�Y
    CLOSE upd_data_cur;
--
    --==============================================================
    -- �Q�D�ꊇ�X�V����
    --==============================================================
    -- �X�V�f�[�^�����݂���ꍇ
    IF ( ln_cnt > 0 ) THEN
      BEGIN
        FORALL ln_cnt IN l_cust_shift_id_tab.FIRST .. l_cust_shift_id_tab.COUNT
          UPDATE xxcok_cust_shift_info  xcsi
          SET    xcsi.emp_code               = gv_employee_code            -- ���͎�
               , xcsi.input_date             = SYSDATE                     -- ���͓�
               , xcsi.status                 = l_status_tab(ln_cnt)        -- �X�e�[�^�X
               , xcsi.last_updated_by        = cn_last_updated_by          -- �ŏI�X�V��
               , xcsi.last_update_date       = cd_last_update_date         -- �ŏI�X�V��
               , xcsi.last_update_login      = cn_last_update_login        -- �ŏI�X�V���O�C��
               , xcsi.request_id             = cn_request_id               -- �v��ID
               , xcsi.program_application_id = cn_program_application_id   -- �v���O�����A�v���P�[�V����ID
               , xcsi.program_id             = cn_program_id               -- �v���O����ID
               , xcsi.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
          WHERE  xcsi.cust_shift_id          = l_cust_shift_id_tab(ln_cnt) -- �ڋq�ڍs���
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcok_10510 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                         , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_errmsg      -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( upd_data_cur%ISOPEN ) THEN
        CLOSE upd_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : out_error_message
   * Description      : �G���[���b�Z�[�W�o�͏���(A-8)
   ***********************************************************************************/
  PROCEDURE out_error_message(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_error_message'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���J�[�\�� ***
    -- �G���[���b�Z�[�W�J�[�\��
    CURSOR out_err_msg_cur
    IS
      SELECT xt0u.record_no           AS record_no             -- ���R�[�hNo
           , xt0u.error_message       AS error_message         -- �G���[���b�Z�[�W
      FROM   xxcok_tmp_001a06c_upload xt0u                     -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_w -- �A�b�v���[�h����t���O
      ORDER BY
             xt0u.record_no
    ;
    --
    -- ���R�[�h��`
    out_err_msg_rec           out_err_msg_cur%ROWTYPE;
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
    -- �G���[���b�Z�[�W�o�͏���
    --==============================================================
    -- �I�[�v��
    OPEN out_err_msg_cur;
    -- �G���[���b�Z�[�W�o�̓��[�v
    << out_loop >>
    LOOP
      -- �t�F�b�`
      FETCH out_err_msg_cur INTO out_err_msg_rec;
      EXIT WHEN out_err_msg_cur%NOTFOUND;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => out_err_msg_rec.error_message
      );
    END LOOP out_loop;
    -- �N���[�Y
    CLOSE out_err_msg_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( out_err_msg_cur%ISOPEN ) THEN
        CLOSE out_err_msg_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_error_message;
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�폜����(A-9)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    -- �t�@�C���A�b�v���[�h�폜
    --==============================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui     -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE       xmfui.file_id = TO_NUMBER(iv_file_id) -- �t�@�C��ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcok_00062 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_ins_cnt     := 0;
    gn_upd_cnt_i   := 0;
    gn_upd_cnt_w   := 0;
    gn_upd_cnt_c   := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
    -- ===============================================
    get_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�o�^���[�v
    << ins_tmp_loop >>
    FOR i IN gt_file_data_all.FIRST .. gt_file_data_all.COUNT LOOP
      -- ===============================================
      -- �t�@�C���A�b�v���[�h�f�[�^�ϊ�����(A-3)
      -- ===============================================
      conv_file_upload_data(
          iv_file_id => iv_file_id -- �t�@�C��ID
        , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �o�^�Ώۃ��R�[�h�t���O��ON�̏ꍇ�̂ݓo�^
      IF ( gb_ins_record_flg = TRUE ) THEN
        -- ===============================================
        -- �N���ڋq�ڍs���csv�A�b�v���[�h�ꎞ�\�o�^����(A-4)
        -- ===============================================
        ins_tmp_001a06c_upload(
            iv_file_id => iv_file_id -- �t�@�C��ID
          , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
          , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
          , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      --
    END LOOP ins_tmp_loop;
--
    -- �J�[�\���I�[�v��
    OPEN chk_cur;
    -- �Ó����`�F�b�N���[�v
    << chk_validate_loop >>
    LOOP
      -- �t�F�b�`
      FETCH chk_cur INTO chk_rec;
      EXIT WHEN chk_cur%NOTFOUND;
      -- ===============================================
      -- �Ó����`�F�b�N����(A-5)
      -- ===============================================
      chk_validate_item(
          iv_file_id => iv_file_id -- �t�@�C��ID
        , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP chk_validate_loop;
    -- �J�[�\���N���[�Y
    CLOSE chk_cur;
--
    -- ===============================================
    -- �ڋq�ڍs���ꊇ�o�^����(A-6)
    -- ===============================================
    ins_cust_shift_info(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �ڋq�ڍs���ꊇ�X�V����(A-7)
    -- ===============================================
    upd_cust_shift_info(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �G���[���b�Z�[�W�o�͏���(A-8)
    -- ===============================================
    out_error_message(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
      IF ( chk_cur%ISOPEN ) THEN
        CLOSE chk_cur;
      END IF;
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
      errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W #�Œ�#
    , retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h   #�Œ�#
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    -- ���b�Z�[�W
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_msg_xxcok_10530 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10530'; -- �o�^�������b�Z�[�W
    cv_msg_xxcok_10531 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10531'; -- �X�V�����i�X�e�[�^�X�F���͒��j���b�Z�[�W
    cv_msg_xxcok_10532 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10532'; -- �X�V�����i�X�e�[�^�X�F�m��O�j���b�Z�[�W
    cv_msg_xxcok_10533 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10533'; -- �X�V�����i�X�e�[�^�X�F����j���b�Z�[�W
    cv_msg_xxcok_10534 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10534'; -- �x���������b�Z�[�W
    -- �g�[�N��
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
--
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
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      , iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�폜����(A-9)
    -- ===============================================
    del_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
    -- �t�@�C���A�b�v���[�h�f�[�^�폜���COMMIT
    COMMIT;
--
    -- �G���[���������݂���ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      -- �G���[���̌����ݒ�
      gn_target_cnt := 0;
      gn_ins_cnt    := 0;
      gn_upd_cnt_i  := 0;
      gn_upd_cnt_w  := 0;
      gn_upd_cnt_c  := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      -- �I���X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    -- �G���[�ȊO�Ōx�����������݂���ꍇ
    ELSIF ( ( gn_error_cnt = 0 ) AND ( gn_warn_cnt > 0 ) ) THEN
      -- �I���X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    -- �G���[�����A�x�����������݂��Ȃ��ꍇ
    ELSIF ( ( gn_error_cnt = 0 ) AND ( gn_warn_cnt = 0 ) ) THEN
      -- �I���X�e�[�^�X�𐳏�ɂ���
      lv_retcode := cv_status_normal;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10530
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ins_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �X�V�����i�X�e�[�^�X�F���͒��j�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10531
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_i)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �X�V�����i�X�e�[�^�X�F�m��O�j�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10532
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_w)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �X�V�����i�X�e�[�^�X�F����j�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10533
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_c)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10534
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOK001A06C;
/
