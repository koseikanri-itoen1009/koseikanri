CREATE OR REPLACE PACKAGE BODY XXCFO019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A01C(body)
 * Description      : �d�q����c���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A01_�d�q����c���̏��n�V�X�e���A�g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������(A-1)
 *  get_gl_bl_wait_coop     ���A�g�f�[�^�擾����(A-2)
 *  get_gl_bl_control       �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  get_gl_bl               �Ώۃf�[�^�擾(A-4)
 *  chk_item                ���ڃ`�F�b�N����(A-5)
 *  out_csv                 �b�r�u�o�͏���(A-6)
 *  ins_gl_bl_wait_coop     ���A�g�e�[�u���o�^����(A-7)
 *  upd_gl_bl_control       �Ǘ��e�[�u���X�V����(A-8)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W���E�I������(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-27    1.0   K.Onotsuka      �V�K�쐬
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
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- �Ώی����i�A�g���j
  gn_normal_cnt      NUMBER;                    -- ���팏��
  gn_error_cnt       NUMBER;                    -- �G���[����
  gn_warn_cnt        NUMBER;                    -- �X�L�b�v����
  gn_target_wait_cnt NUMBER;                    -- �Ώی����i���A�g���j
  gn_wait_data_cnt   NUMBER;                    -- ���A�g�f�[�^����
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A01C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_add_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_I_FILENAME'; -- �d�q����c���f�[�^�ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_U_FILENAME'; -- �d�q����c���f�[�^�X�V�t�@�C����
  cv_p_accounts               CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_P_ACCOUNTS';            -- �d�q���땡������敡�����莞����
  cv_set_of_bks_id            CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                           -- ��v����ID
  cv_org_id                   CONSTANT VARCHAR2(10)  := 'ORG_ID';                                     -- �c�ƒP��
  --���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --�t�@�C�����݃G���[
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --�t�@�C���������݃G���[
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10008';   --�p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10027';   --�d�q����c���p�����[�^���͕s�����b�Z�[�W
  cv_msg_cfo_10028            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10028';   --�Ώۉ�v���ԃ��b�Z�[�W
  cv_msg_cfo_10029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10029';   --�Ώۉ�v���Ԏ擾�G���[���b�Z�[�W
  cv_msg_cfo_10030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10030';   --��v���ԋt�]�G���[���b�Z�[�W
  cv_msg_cfo_10031            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10031';   --�c�������σf�[�^�`�F�b�N���b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';         -- �p�����[�^��
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';         -- �p�����[�^��
  cv_tkn_e_period_num         CONSTANT VARCHAR2(20)  := 'E_PERIOD_NUM';   -- ��v���Ԕԍ�
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ���b�N�A�b�v�^�C�v��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';          -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';         -- SQL�G���[���b�Z�[�W
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- �f�B���N�g����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- �t�@�C����
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- �e�[�u����
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';          -- ���A�g�f�[�^�o�^���R
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';         -- ���A�g�f�[�^����L�[
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';        -- ���A�g�G���[���e
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- �f�[�^���e('��v����')
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- ��v���Ԗ�
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';     -- �G���[�e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- �G���[���
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_11008         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11008'; -- ���ڂ��s��
  cv_msgtkn_cfo_11054         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11054'; -- �c�����
  cv_msgtkn_cfo_11073         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073'; -- ��v����
  cv_msgtkn_cfo_11113         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11113'; -- �c�����A�g�e�[�u��
  cv_msgtkn_cfo_11114         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11114'; -- �c���Ǘ��e�[�u��
  cv_msgtkn_cfo_11115         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11115'; -- ��v����(From)
  cv_msgtkn_cfo_11116         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11116'; -- ��v����(To)
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';    --�d�q���돈�����s��
  cv_lookup_item_chk_blc      CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_BLC'; --�d�q���덀�ڃ`�F�b�N�i�c���j
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --�b�r�u�o�̓t�H�[�}�b�g
  --�b�r�u
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- ��������
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- �蓮���s
  --�ǉ��X�V�敪
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- �ǉ�
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- �X�V
  --�f�[�^�^�C�v
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- �A�g��
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- ���A�g��
  --��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --����
  cv_sqlgl                    CONSTANT VARCHAR2(5)   := 'SQLGL';              -- 'SQLGL'
  cv_c                       CONSTANT VARCHAR2(2)    := 'C';                  -- 'C'(�N���[�Y)
  --�Œ�l
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
  cv_par_start                CONSTANT VARCHAR2(1)   := '(';                  -- ����(�n)
  cv_par_end                  CONSTANT VARCHAR2(1)   := ')';                  -- ����(�I)
  --�t�@�C���o��
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   �i�`�F�b�N�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�c��
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --�o�̓f�[�^���
  --���ڃ`�F�b�N
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- ���ږ���
  gt_item_len                   g_item_len_ttype;           -- ���ڂ̒���
  gt_item_decimal               g_item_decimal_ttype;       -- ���ځi�����_�ȉ��̒����j
  gt_item_nullflg               g_item_nullflg_ttype;       -- �K�{���ڃt���O
  gt_item_attr                  g_item_attr_ttype;          -- ���ڑ���
  gt_item_cutflg                g_item_cutflg_ttype;        -- �؎̂ăt���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                -- �Ɩ����t
  gv_coop_date                VARCHAR2(14);                        -- �A�g���t
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;   -- �d�q���돈�����s����
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;   -- �����Ώێ���
  gn_set_of_bks_id            NUMBER;                              -- ��v����ID
  gv_electric_book_p_accounts VARCHAR2(100) DEFAULT NULL;          -- �d�q���땡������敡�����莞����
  gt_period_name_from         gl_period_statuses.effective_period_num%TYPE; -- �L����v���Ԕԍ�(From)
  gt_period_name_to           gl_period_statuses.effective_period_num%TYPE; -- �L����v���Ԕԍ�(To)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --�t�@�C���p�X
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --�d�q����t�@�C����
  gn_item_cnt                 NUMBER;             --�`�F�b�N���ڌ���
  gv_0file_flg                VARCHAR2(1) DEFAULT 'N'; --0Byte�t�@�C���㏑���t���O
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --�x���t���O
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  --�c�����A�g�f�[�^�擾�J�[�\��
  CURSOR  gl_bl_wait_coop_cur
  IS
    SELECT xgbwc.effective_period_num AS effective_period_num -- ��v���Ԕԍ�
          ,xgbwc.rowid                AS row_id               -- RowID
      FROM xxcfo_gl_balance_wait_coop xgbwc -- �c�����A�g
    ;
    -- �e�[�u���^
    TYPE gl_bl_wait_coop_ttype IS TABLE OF gl_bl_wait_coop_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_bl_wait_coop_tab gl_bl_wait_coop_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  global_lock_expt  EXCEPTION; -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn      IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2, -- 2.�t�@�C����
    iv_period_name_from IN  VARCHAR2, -- 3.��v����(From)
    iv_period_name_to   IN  VARCHAR2, -- 4.��v����(To)
    iv_exec_kbn         IN  VARCHAR2, -- 5.����蓮�敪
    ov_errbuf      OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg          VARCHAR2(3000);
    lv_full_name    VARCHAR2(200) DEFAULT NULL;    --�f�B���N�g�����{�t�@�C�����A���l
    lt_dir_path     all_directories.directory_path%TYPE DEFAULT NULL; --�f�B���N�g���p�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --���ږ���
              , flv.attribute1          attribute1 --���ڂ̒���
              , flv.attribute2          attribute2 --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          attribute3 --�K�{�t���O
              , flv.attribute4          attribute4 --����
              , flv.attribute5          attribute5 --�؎̂ăt���O
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_blc --�d�q���덀�ڃ`�F�b�N�i�c���j
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        = cv_flag_y
      AND       flv.language            = cv_lang
      ORDER BY  flv.lookup_code
      ;
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
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => iv_period_name_from   -- ��v����(From)
      ,iv_conc_param4  => iv_period_name_to     -- ��v����(To)
      ,iv_conc_param5  => iv_exec_kbn           -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ���O�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => iv_period_name_from   -- ��v����(From)
      ,iv_conc_param4  => iv_period_name_to     -- ��v����(To)
      ,iv_conc_param5  => iv_exec_kbn           -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- �Ɩ����t�擾�G���[
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �A�g�����p���t�擾
    --==============================================================
    gv_coop_date := TO_CHAR(SYSDATE, cv_date_format_ymdhms);
--
    --==================================
    -- �N�C�b�N�R�[�h
    --==================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    flv.attribute1 -- �d�q���돈�����s����
              , flv.attribute2 -- �����Ώێ���
      INTO      gt_electric_exec_days
              , gt_proc_target_time
      FROM      fnd_lookup_values  flv
      WHERE     flv.lookup_type    = cv_lookup_book_date
      AND       flv.lookup_code    = cv_pkg_name
      AND       gd_process_date    BETWEEN NVL(flv.start_date_active, gd_process_date)
                                   AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag   = cv_flag_y
      AND       flv.language       = cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_book_date     -- 'XXCFO1_ELECTRIC_BOOK_DATE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p)���̎擾
    --==================================
    OPEN get_chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- �Ώی����̃Z�b�g
    gn_item_cnt := gt_item_name.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
    --
    IF ( gn_item_cnt = 0 ) THEN
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- 'XXCFF'
                                                    ,cv_msg_cff_00189       -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type     -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_blc -- 'XXCFO1_ELECTRIC_ITEM_CHK_BLC'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    --�t�@�C���i�[�p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_data_filepath -- 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --��v����ID
    gn_set_of_bks_id  := FND_PROFILE.VALUE( cv_set_of_bks_id );
    --
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_set_of_bks_id -- 'GL_SET_OF_BKS_ID'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�d�q���땡������敡�����莞����
    gv_electric_book_p_accounts  := FND_PROFILE.VALUE( cv_p_accounts );
    --
    IF ( gv_electric_book_p_accounts IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name
                                                    ,cv_p_accounts
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�t�@�C����
    IF ( iv_file_name IS NOT NULL ) THEN
      --�p�����[�^�u�t�@�C�����v�����͍ς̏ꍇ�́A���͒l���t�@�C�����Ƃ��Ďg�p
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
      --�p�����[�^�u�t�@�C�����v�������͂ŁA�ǉ��X�V�敪��'�ǉ�(0)'�̏ꍇ
      --�v���t�@�C������u�ǉ��t�@�C�����v���擾
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_add_filename  -- 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_I_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --�p�����[�^�u�t�@�C�����v�������͂ŁA�ǉ��X�V�敪��'�X�V(1)'�̏ꍇ
      --�v���t�@�C������u�X�V�t�@�C�����v���擾
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_upd_filename  -- 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_U_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- �f�B���N�g���p�X�擾�G���[
                                                    ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                    ,gt_file_path     -- �t�@�C���i�[�p�X
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IF�t�@�C�����o��
    --==================================
    --�擾�����f�B���N�g���p�X�̖�����'/'(�X���b�V��)�����݂���ꍇ�A
    --�f�B���N�g���ƃt�@�C�����̊Ԃ�'/'�A���͍s�킸�Ƀt�@�C�������o�͂���
    IF  SUBSTRB(lt_dir_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  lt_dir_path || gv_file_name;
    ELSE
      lv_full_name :=  lt_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                               ,cv_msg_cfo_00002 -- �t�@�C�����o�̓��b�Z�[�W
                                               ,cv_tkn_file_name -- 'FILE_NAME'
                                               ,lv_full_name     -- �i�[�p�X�ƃt�@�C�����̘A������
                                              )
                      ,1
                      ,5000);
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- ����t�@�C�����݃`�F�b�N
    --==================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- ����t�@�C������
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_bl_wait_coop
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_gl_bl_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl_wait_coop'; -- �v���O������
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
    --==============================================================
    -- �c�����A�g�f�[�^�擾
    --==============================================================
    --�J�[�\���I�[�v��
    OPEN gl_bl_wait_coop_cur;
    FETCH gl_bl_wait_coop_cur BULK COLLECT INTO gl_bl_wait_coop_tab;
    --�J�[�\���N���[�Y
    CLOSE gl_bl_wait_coop_cur;
    --
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                    ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                              ,cv_msgtkn_cfo_11113) -- �c�����A�g�e�[�u��
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF gl_bl_wait_coop_cur%ISOPEN THEN
        CLOSE gl_bl_wait_coop_cur;
      END IF;
--#################################  �Œ��O������ START   ####################################
--
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
      -- �J�[�\���N���[�Y
      IF gl_bl_wait_coop_cur%ISOPEN THEN
        CLOSE gl_bl_wait_coop_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_bl_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_bl_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_gl_bl_control(
    iv_ins_upd_kbn      IN  VARCHAR2, -- �ǉ��X�V�敪
    iv_period_name_from IN  VARCHAR2, -- ��v����(From)
    iv_period_name_to   IN  VARCHAR2, -- ��v����(To)
    iv_exec_kbn         IN  VARCHAR2, -- ����蓮�敪
    ov_next_period_flg  OUT VARCHAR2, -- ����v���ԗL���t���O(����̂�)
    ov_errbuf           OUT VARCHAR2, -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2, -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl_control'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    ln_dummy_adjustment_id NUMBER; --���b�N�pINTO��_�~�[�ϐ�
--
    -- *** ���[�J���ϐ� ***
    --�����ω�v���Ԕԍ�
    ln_effective_period_num xxcfo_gl_balance_control.effective_period_num%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ����v���Ԏ擾�J�[�\��(����̂�)
    CURSOR next_gl_period_cur(in_effective_period_num IN xxcfo_gl_balance_control.effective_period_num%TYPE)
    IS
      SELECT gps.effective_period_num AS effective_period_num -- �L����v���Ԕԍ�
            ,gps.closing_status       AS status               -- �X�e�[�^�X
            ,gps.last_update_date     AS last_update_date     -- �ŏI�X�V��
      FROM   gl_period_statuses gps                -- ��v���ԃX�e�[�^�X
            ,fnd_application    fa                 -- �A�v���P�[�V����
      WHERE  gps.effective_period_num  > in_effective_period_num -- �����ω�v���Ԕԍ�
      AND    gps.application_id        = fa.application_id
      AND    fa.application_short_name = cv_sqlgl                -- �A�v���P�[�V�����Z�k���uSQLGL�v
      AND    gps.set_of_books_id       = gn_set_of_bks_id        -- A-1�Ŏ擾������v����ID
      ORDER BY gps.effective_period_num
      ;
      -- �e�[�u���^
      TYPE next_gl_period_ttype IS TABLE OF next_gl_period_cur%ROWTYPE INDEX BY BINARY_INTEGER;
      next_gl_period_tab next_gl_period_ttype;
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
    no_gl_pererid EXCEPTION; --����v���Ԏ擾�s��
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
    -- 1.�����ω�v���Ԕԍ��擾
    --==============================================================
    BEGIN
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        --������s���̂ݕ\���b�N���擾����
        LOCK TABLE xxcfo_gl_balance_control IN EXCLUSIVE MODE NOWAIT
        ;
      END IF;
      --
      SELECT    xgbc.effective_period_num  AS effective_period_num -- ��v���Ԕԍ�
      INTO      ln_effective_period_num
      FROM      xxcfo_gl_balance_control xgbc -- �c���Ǘ�
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10025   -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                      ,cv_tkn_get_data    -- �g�[�N��'GET_DATA'
                                                      ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                                ,cv_msgtkn_cfo_11114) --�c���Ǘ��e�[�u��
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE  global_process_expt;
      -- *** ���b�N�G���[��O�n���h�� ***
      WHEN global_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                      ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                      ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                                ,cv_msgtkn_cfo_11114) -- �c���Ǘ��e�[�u��
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --2.�Ώۉ�v���Ԕԍ��擾(������s��)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --������s���̂݁A����v���Ԕԍ��擾
      OPEN next_gl_period_cur(ln_effective_period_num); --�����ω�v���Ԕԍ�
      FETCH next_gl_period_cur BULK COLLECT INTO next_gl_period_tab;
      --�J�[�\���N���[�Y
      CLOSE next_gl_period_cur;
      --
      IF ( next_gl_period_tab.COUNT > 0 ) THEN
        IF ( ( next_gl_period_tab(1).status = cv_c ) --���ԃN���[�Y
          AND ( TRUNC(next_gl_period_tab(1).last_update_date) <= ( gd_process_date - gt_electric_exec_days ) ) ) THEN
          --����v���Ԃ��N���[�Y���A���̍ŏI�X�V�����Ɩ����t-�d�q���돈�����s�����ȑO�̏ꍇ�A�������s
          --�Ώۃf�[�^�擾�������̌����L�[�u��v���Ԕԍ�(From-To)�v�����Ɏ擾�l��ݒ�
          gt_period_name_from := next_gl_period_tab(1).effective_period_num;
          gt_period_name_to   := next_gl_period_tab(1).effective_period_num;
        ELSE
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10028   -- �Ώۉ�v���ԃ��b�Z�[�W
                                                       )
                               ,1
                               ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --�����𐳏�I������
          RAISE no_gl_pererid;
        END IF;
      END IF;
    ELSE
      --==============================================================
      --3.�Ώۉ�v���Ԕԍ��擾(�蓮���s��)
      --==============================================================
      BEGIN
        --��v����(From)���擾
        SELECT gps.effective_period_num AS effective_period_num -- �L����v���Ԕԍ�(From)
        INTO   gt_period_name_from
        FROM   gl_period_statuses gps -- ��v���ԃX�e�[�^�X
              ,fnd_application    fa  -- �A�v���P�[�V����
        WHERE gps.period_name           = iv_period_name_from -- ���̓p�����[�^�u��v���ԁiFrom�j�v
        AND   gps.application_id        = fa.application_id
        AND   fa.application_short_name = cv_sqlgl            -- �A�v���P�[�V�����Z�k���uSQLGL�v
        AND   gps.set_of_books_id       = gn_set_of_bks_id    -- ��v����ID
        AND   gps.closing_status        = cv_c               -- ��v���ԃX�e�[�^�X�uC�v
        ORDER BY gps.effective_period_num
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10029 -- �Ώۉ�v���Ԏ擾�G���[���b�Z�[�W
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
      END;
      --
      BEGIN
        --��v����(To)���擾
        SELECT gps.effective_period_num AS effective_period_num -- �L����v���Ԕԍ�(To)
        INTO   gt_period_name_to
        FROM   gl_period_statuses gps -- ��v���ԃX�e�[�^�X
              ,fnd_application    fa  -- �A�v���P�[�V����
        WHERE gps.period_name           = iv_period_name_to -- ���̓p�����[�^�u��v���ԁiTo�j�v
        AND   gps.application_id        = fa.application_id
        AND   fa.application_short_name = cv_sqlgl            -- �A�v���P�[�V�����Z�k���uSQLGL�v
        AND   gps.set_of_books_id       = gn_set_of_bks_id    -- ��v����ID
        AND   gps.closing_status        = cv_c                -- ��v���ԃX�e�[�^�X�uC�v
        ORDER BY gps.effective_period_num
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10029 -- �Ώۉ�v���Ԏ擾�G���[���b�Z�[�W
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
      END;
--
      --==============================================================
      --4.�擾��v���Ԃ�From-To�t�]�`�F�b�N(�蓮���s��)
      --==============================================================
      IF ( gt_period_name_to < gt_period_name_from ) THEN
        --To���From�̕����傫���ꍇ�̓G���[�I��
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10030 -- ��v���ԋt�]�G���[���b�Z�[�W
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE  global_process_expt;
      END IF;
--
      --==============================================================
      --5.�w���v���ԏ����ς݃`�F�b�N(�蓮���s��)
      --==============================================================
      --�ǉ��X�V�敪���u�X�V�v�̏ꍇ�ɁA�w���v���Ԃ������ς݂��ۂ��`�F�b�N����
      IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        IF ( ln_effective_period_num < gt_period_name_to ) THEN
          --�������̉�v���Ԃ��w�肳��Ă����ꍇ�̓G���[�I��
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo          -- 'XXCFO'
                                                        ,cv_msg_cfo_10031        -- �c�������σf�[�^�`�F�b�N���b�Z�[�W
                                                        ,cv_tkn_e_period_num     -- ��v���Ԕԍ�
                                                        ,ln_effective_period_num -- �����ω�v���Ԕԍ�
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gt_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                                   );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    WHEN no_gl_pererid THEN
      ov_next_period_flg := 'N';
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF next_gl_period_cur%ISOPEN THEN
        CLOSE next_gl_period_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_bl_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn        IN  VARCHAR2,   --   �ǉ��X�V�敪
    iv_exec_kbn           IN  VARCHAR2,   --   ����蓮�敪
    ov_item_chk           OUT VARCHAR2,   --   ���ڃ`�F�b�N�̎��{�L���t���O    
    ov_msgcode            OUT VARCHAR2,   --   ���b�Z�[�W�R�[�h
    ov_errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_item'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
    warn_expt        EXCEPTION; --�����r��(�x��������)�Ń��W�b�N�𔲂���ׂɎg�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    IF ( iv_exec_kbn = cv_exec_manual ) THEN --�蓮���s�̏ꍇ
      --==============================================================
      -- ���A�g�f�[�^���݃`�F�b�N
      --==============================================================
      <<gl_bl_wait_chk_loop>>
      FOR i IN 1 .. gl_bl_wait_coop_tab.COUNT LOOP
        --���A�g�f�[�^�̉�v���Ԕԍ���A-4�Ŏ擾�����L����v���Ԕԍ����r
        IF ( gl_bl_wait_coop_tab( i ).effective_period_num = gt_data_tab(30) ) THEN
          --�Ώۉ�v���Ԃ����A�g�̏ꍇ�A�x�����b�Z�[�W���o��
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10010      -- ���A�g�f�[�^�`�F�b�NID�G���[
                                 ,cv_tkn_doc_data       -- �g�[�N��'DOC_DATA'
                                 ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                           ,cv_msgtkn_cfo_11073)-- '��v����'
                                 ,cv_tkn_doc_dist_id    -- �g�[�N��'DOC_DIST_ID'
                                 ,gt_data_tab(18)       -- ��v���Ԗ�
                                 )
                               ,1
                               ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          RAISE warn_expt;
        END IF;
      END LOOP;
      --
    END IF;
--
    --==============================================================
    -- ���ڌ��`�F�b�N
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --���ږ���
        , iv_item_value                 =>        gt_data_tab(ln_cnt)                --�ύX�O�̒l
        , in_item_len                   =>        gt_item_len(ln_cnt)               --���ڂ̒���
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --�K�{�t���O
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --���ڑ���
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --�؎̂ăt���O
        , ov_item_value                 =>        gt_data_tab(ln_cnt)                --���ڂ̒l
        , ov_errbuf                     =>        lv_errbuf                         --�G���[���b�Z�[�W
        , ov_retcode                    =>        lv_retcode                        --���^�[���R�[�h
        , ov_errmsg                     =>        lv_errmsg                         --���[�U�[�E�G���[���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_warn ) THEN
        gv_warning_flg      := cv_flag_y; --�x���t���O(Y)
        ov_item_chk         := cv_flag_y;  --���ڃ`�F�b�N���{
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;  --�߂胁�b�Z�[�W�R�[�h
        ov_errmsg           := lv_errmsg;  --�߂胁�b�Z�[�W
        EXIT; --LOOP�𔲂���
      ELSIF ( lv_retcode = cv_status_error ) THEN
        ov_errmsg   := lv_errmsg;
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
--
    -- *** �x���n���h�� ***
    WHEN warn_expt THEN
      gv_warning_flg := cv_flag_y; --�x���t���O(Y)
      lv_errbuf   := lv_errmsg;
      ov_item_chk := cv_flag_n;    --���ڃ`�F�b�N�����{
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn; --�x��
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : �b�r�u�o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_delimit                VARCHAR2(1);
    lv_file_data              VARCHAR2(30000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
--
    --�f�[�^�ҏW
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), cv_quot, ' '), cv_delimit, ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --�A�g����
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(29);
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,lv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END;
    --���������J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_bl_wait_coop
   * Description      : ���A�g�e�[�u���o�^����(A-7)
   ***********************************************************************************/
  PROCEDURE ins_gl_bl_wait_coop(
    iv_meaning      IN VARCHAR2,    --   �G���[���e
    ov_errbuf      OUT VARCHAR2,    --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode     OUT VARCHAR2,    --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg      OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_bl_wait_coop'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    --���b�Z�[�W�o��
    --==============================================================
    --���A�g�f�[�^�o�^���b�Z�[�W
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10007 -- ���A�g�f�[�^�o�^
                                                     ,cv_tkn_cause     -- 'CAUSE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11008) -- '���ڂ��s��'
                                                     ,cv_tkn_target    -- 'TARGET'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11073)
                                                       || cv_par_start 
                                                       || gt_data_tab(18)
                                                       || cv_par_end --��v����
                                                     ,cv_tkn_meaning   -- 'MEANING'
                                                     ,iv_meaning       -- �`�F�b�N�G���[���b�Z�[�W
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
    --==============================================================
    --���A�g�e�[�u���o�^
    --==============================================================
    BEGIN
      INSERT INTO xxcfo_gl_balance_wait_coop(
         effective_period_num   -- �L����v���Ԕԍ�
        ,created_by             -- �쐬��
        ,creation_date          -- �쐬��
        ,last_updated_by        -- �ŏI�X�V��
        ,last_update_date       -- �ŏI�X�V��
        ,last_update_login      -- �ŏI�X�V���O�C��
        ,request_id             -- �v��ID
        ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id             -- �R���J�����g�E�v���O����ID
        ,program_update_date    -- �v���O�����X�V��
        )
      VALUES (
         gt_data_tab(30)
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
      --���A�g�o�^�����J�E���g
      gn_wait_data_cnt := gn_wait_data_cnt + 1;
      --
      --�X�e�[�^�X���x���ɐݒ�
      ov_retcode := cv_status_warn;
      --�x���t���O��'Y'�ɐݒ肷��
      gv_warning_flg := cv_flag_y;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                     ,cv_msg_cfo_00024   -- �f�[�^�o�^�G���[
                                                     ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11113) -- �c�����A�g�e�[�u��
                                                     ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_bl_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_bl
   * Description      : �Ώۃf�[�^�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_gl_bl(
    iv_ins_upd_kbn IN VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_exec_kbn    IN VARCHAR2, -- 2.����蓮�敪
    ov_errbuf     OUT VARCHAR2, --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2, --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_sarch_account_type     CONSTANT VARCHAR2(12) := 'ACCOUNT_TYPE'; -- ���o����������'ACCOUNT_TYPE'
    cv_sarch_a                CONSTANT VARCHAR2(12) := 'A'; -- ���o����������'A'
    cv_sarch_e                CONSTANT VARCHAR2(12) := 'E'; -- ���o����������'E'
    cv_sarch_l                CONSTANT VARCHAR2(12) := 'L'; -- ���o����������'L'
    cv_sarch_o                CONSTANT VARCHAR2(12) := 'O'; -- ���o����������'O'
    cv_sarch_r                CONSTANT VARCHAR2(12) := 'R'; -- ���o����������'R'
--
    -- *** ���[�J���ϐ� ***
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-5�̖߂胁�b�Z�[�W�R�[�h(�^���`�F�b�N)
    lv_item_chk               VARCHAR2(1)  DEFAULT 'N';  --���ڃ`�F�b�N�t���O(Y�F���{ N:�����{)
    lv_ins_wait_flg           VARCHAR2(1)  DEFAULT 'N';  --���A�g�o�^�σt���O(Y�F�o�^�� N:���o�^)
    --�f�[�^���o���������i�[�p
    lt_sales_exp              fnd_lookup_values.description%TYPE; --�̔�����
    lt_type_adj               fnd_lookup_values.description%TYPE; --�C��
    lt_type_trx               fnd_lookup_values.description%TYPE; --���
    lt_type_cm                fnd_lookup_values.description%TYPE; --�N������
    lt_type_cm_apply          fnd_lookup_values.description%TYPE; --�N����������
    lt_type_sales_doc         fnd_lookup_values.description%TYPE; --���㐿����
    lt_type_credit_memo       fnd_lookup_values.description%TYPE; --�N���W�b�g�E����
    lt_type_credit_memo_apply fnd_lookup_values.description%TYPE; --�N���W�b�gMEMO����
    --���ڃ`�F�b�N(A-5)�i�[�p
    lv_ar_id_from             VARCHAR2(15) DEFAULT NULL; --A-3�ɂĎ擾����ID�l(From)
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    --������s�p
    CURSOR get_gl_bl_fixed_cur
    IS
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- ����Ȗڑg����ID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- ����Ȗڃ^�C�v
            ,gcc.segment1                        AS aff_company_code     -- �`�e�e��ЃR�[�h 
            ,gcc.segment2                        AS aff_department_code  -- �`�e�e����R�[�h 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- ���喼�� 
            ,gcc.segment3                        AS aff_account_code    -- �`�e�e����ȖڃR�[�h 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- ����Ȗږ��� 
            ,gcc.segment4                        AS aff_sub_account_code -- �`�e�e�⏕�ȖڃR�[�h 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- �⏕�Ȗږ��� 
            ,gcc.segment5                        AS aff_partner_code     -- �`�e�e�ڋq�R�[�h 
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq���� 
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ��� 
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- �\���P���� 
            ,gcc.segment8                        AS aff_future       -- �`�e�e�\���Q 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- �\���Q���� 
            ,gb.period_name                      AS period_name        -- ��v���Ԗ�
            ,gb.period_year                      AS period_year        -- ��v�N�x
            ,gb.period_num                       AS period_num         -- ��v���Ԕԍ�
            ,gb.currency_code                    AS currency_code      -- �ʉ݃R�[�h
            ,gb.period_net_dr                    AS period_net_dr      -- ���Ԏؕ�
            ,gb.period_net_cr                    AS period_net_cr      -- ���ԑݕ�
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- �l�����ؕ��݌v
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- �l�����ݕ��݌v
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- ����ؕ��c��
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- ����ݕ��c��
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              --�c��
            ,gv_coop_date                        AS cool_date            --�A�g����
            ,gps.effective_period_num            AS effective_period_num -- �L����v���Ԕԍ�
            ,cv_data_type_0                      AS data_type            -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  gl_balances gb           -- �d��c��
           ,gl_code_combinations gcc -- ����Ȗڑg����
           ,gl_period_statuses gps   -- ��v���ԃX�e�[�^�X
           ,fnd_application fa       -- �A�v���P�[�V����
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- �A�v���P�[�V�����Z�k���uSQLGL�v
      AND   gb.set_of_books_id        = gps.set_of_books_id
      AND   gps.effective_period_num  >= gt_period_name_from  -- �L����v���Ԕԍ�
      AND   gps.effective_period_num  <= gt_period_name_to    -- �L����v���Ԕԍ�
      UNION ALL
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- ����Ȗڑg����ID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- ����Ȗڃ^�C�v
            ,gcc.segment1                        AS aff_company_code     -- �`�e�e��ЃR�[�h 
            ,gcc.segment2                        AS aff_department_code  -- �`�e�e����R�[�h 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- ���喼�� 
            ,gcc.segment3                        AS aff_account_code    -- �`�e�e����ȖڃR�[�h 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- ����Ȗږ��� 
            ,gcc.segment4                        AS aff_sub_account_code -- �`�e�e�⏕�ȖڃR�[�h 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- �⏕�Ȗږ��� 
            ,gcc.segment5                        AS aff_partner_code     -- �`�e�e�ڋq�R�[�h 
            ,(SELECT xpv.description 
                FROM XX03_PARTNERS_V xpv
               WHERE GCC.SEGMENT5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq���� 
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ��� 
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- �\���P���� 
            ,gcc.segment8                        AS aff_future       -- �`�e�e�\���Q 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- �\���Q���� 
            ,gb.period_name                      AS period_name        -- ��v���Ԗ�
            ,gb.period_year                      AS period_year        -- ��v�N�x
            ,gb.period_num                       AS period_num         -- ��v���Ԕԍ�
            ,gb.currency_code                    AS currency_code      -- �ʉ݃R�[�h
            ,gb.period_net_dr                    AS period_net_dr      -- ���Ԏؕ�
            ,gb.period_net_cr                    AS period_net_cr      -- ���ԑݕ�
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- �l�����ؕ��݌v
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- �l�����ݕ��݌v
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- ����ؕ��c��
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- ����ݕ��c��
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              -- �c��
            ,gv_coop_date                        AS cool_date            -- �A�g����
            ,gps.effective_period_num            AS effective_period_num -- �L����v���Ԕԍ�
            ,cv_data_type_1                      AS data_type            -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  gl_balances gb           -- �d��c��
           ,gl_code_combinations gcc -- ����Ȗڑg����
           ,gl_period_statuses gps   -- ��v���ԃX�e�[�^�X
           ,fnd_application fa       -- �A�v���P�[�V����
           ,xxcfo_gl_balance_wait_coop xgbwc -- �c�����A�g
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.effective_period_num  = xgbwc.effective_period_num
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- �A�v���P�[�V�����Z�k���uSQLGL�v
      AND   gb.set_of_books_id        = gps.set_of_books_id
      ORDER BY period_year
              ,period_num
              ,code_cmb_id
      ;
    --�蓮���s�p
    CURSOR get_gl_bl_manual_cur
    IS
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- ����Ȗڑg����ID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- ����Ȗڃ^�C�v
            ,gcc.segment1                        AS aff_company_code     -- �`�e�e��ЃR�[�h 
            ,gcc.segment2                        AS aff_department_code  -- �`�e�e����R�[�h 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- ���喼�� 
            ,gcc.segment3                        AS aff_account_code    -- �`�e�e����ȖڃR�[�h 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- ����Ȗږ��� 
            ,gcc.segment4                        AS aff_sub_account_code -- �`�e�e�⏕�ȖڃR�[�h 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- �⏕�Ȗږ��� 
            ,gcc.segment5                        AS aff_partner_code     -- �`�e�e�ڋq�R�[�h 
            ,(SELECT xpv.description 
                FROM XX03_PARTNERS_V xpv
               WHERE GCC.SEGMENT5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- �ڋq���� 
            ,gcc.segment6                        AS aff_business_type_code -- �`�e�e��ƃR�[�h 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- ��Ɩ��� 
            ,gcc.segment7                        AS aff_project            -- �`�e�e�\���P 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- �\���P���� 
            ,gcc.segment8                        AS aff_future       -- �`�e�e�\���Q 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- �\���Q���� 
            ,gb.period_name                      AS period_name        -- ��v���Ԗ�
            ,gb.period_year                      AS period_year        -- ��v�N�x
            ,gb.period_num                       AS period_num         -- ��v���Ԕԍ�
            ,gb.currency_code                    AS currency_code      -- �ʉ݃R�[�h
            ,gb.period_net_dr                    AS period_net_dr      -- ���Ԏؕ�
            ,gb.period_net_cr                    AS period_net_cr      -- ���ԑݕ�
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- �l�����ؕ��݌v
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- �l�����ݕ��݌v
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- ����ؕ��c��
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- ����ݕ��c��
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              -- �c��
            ,gv_coop_date                        AS cool_date            -- �A�g����
            ,gps.effective_period_num            AS effective_period_num -- �L����v���Ԕԍ�
            ,cv_data_type_0                      AS data_type            -- �f�[�^�^�C�v(�A�g/���A�g)
      FROM  gl_balances gb           -- �d��c��
           ,gl_code_combinations gcc -- ����Ȗڑg����
           ,gl_period_statuses gps   -- ��v���ԃX�e�[�^�X
           ,fnd_application fa       -- �A�v���P�[�V����
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- �A�v���P�[�V�����Z�k���uSQLGL�v
      AND   gb.set_of_books_id        = gps.set_of_books_id
      AND   gps.effective_period_num  >= gt_period_name_from  -- �L����v���Ԕԍ�
      AND   gps.effective_period_num  <= gt_period_name_to    -- �L����v���Ԕԍ�
      ORDER BY period_year
              ,period_num
              ,code_cmb_id
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
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --==============================================================
      -- 1 �蓮���s�̏ꍇ
      --==============================================================
      --�J�[�\���I�[�v��
      OPEN get_gl_bl_manual_cur;
      <<main_loop>>
      LOOP
      FETCH get_gl_bl_manual_cur INTO
            gt_data_tab(1)  -- ����Ȗڑg����ID
          , gt_data_tab(2)  -- ����Ȗڃ^�C�v
          , gt_data_tab(3)  -- �`�e�e��ЃR�[�h
          , gt_data_tab(4)  -- �`�e�e����R�[�h
          , gt_data_tab(5)  -- ���喼��
          , gt_data_tab(6)  -- �`�e�e����ȖڃR�[�h
          , gt_data_tab(7)  -- ����Ȗږ���
          , gt_data_tab(8)  -- �`�e�e�⏕�ȖڃR�[�h
          , gt_data_tab(9)  -- �⏕�Ȗږ���
          , gt_data_tab(10) -- �`�e�e�ڋq�R�[�h
          , gt_data_tab(11) -- �ڋq����
          , gt_data_tab(12) -- �`�e�e��ƃR�[�h
          , gt_data_tab(13) -- ��Ɩ���
          , gt_data_tab(14) -- �`�e�e�\���P
          , gt_data_tab(15) -- �\���P����
          , gt_data_tab(16) -- �`�e�e�\���Q
          , gt_data_tab(17) -- �\���Q����
          , gt_data_tab(18) -- ��v���Ԗ�
          , gt_data_tab(19) -- ��v�N�x
          , gt_data_tab(20) -- ��v���Ԕԍ�
          , gt_data_tab(21) -- �ʉ݃R�[�h
          , gt_data_tab(22) -- ���Ԏؕ�
          , gt_data_tab(23) -- ���ԑݕ�
          , gt_data_tab(24) -- �l�����ؕ��݌v
          , gt_data_tab(25) -- �l�����ݕ��݌v
          , gt_data_tab(26) -- ����ؕ��c��
          , gt_data_tab(27) -- ����ݕ��c��
          , gt_data_tab(28) -- �c��
          , gt_data_tab(29) -- �A�g����
          , gt_data_tab(30) -- �L����v���Ԕԍ�
          , gt_data_tab(31) -- �f�[�^�^�C�v
          ;
      EXIT WHEN get_gl_bl_manual_cur%NOTFOUND;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- �ǉ��X�V�敪
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- ����蓮�敪
         ,ov_item_chk                   =>        lv_item_chk    -- ���ڃ`�F�b�N���{�t���O
         ,ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
         ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
        IF ( lv_retcode = cv_status_normal ) THEN
          --�`�F�b�N������I�������ꍇ�ACSV�o�͂���
          --==============================================================
          -- CSV�o�͏���(A-6)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn )
          AND ( lv_item_chk = cv_flag_y ) THEN
          IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
            --�x���I�����A�^���`�F�b�N���������߂̏ꍇ�A���b�Z�[�W�o��
            lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfo     -- 'XXCFO'
                                    ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                    ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                              ,cv_msgtkn_cfo_11073)
                                      || cv_msg_part 
                                      || gt_data_tab(18) --��v����
                                    )
                                  ,1
                                  ,5000);
          ELSE
            --�^���`�F�b�N�ɂāA�x�����e���������߈ȊO�̏ꍇ�A�߂胁�b�Z�[�W�ɉ�v���Ԃ�ǉ��o��
            lv_errmsg := lv_errmsg || ' ' 
                                   || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo, cv_msgtkn_cfo_11073)
                                   || cv_msg_part 
                                   || gt_data_tab(18); --��v����
          END IF;
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          --�����𒆒f
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          --�����𒆒f
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        --�Ώی����i�A�g���j��1�J�E���g
        gn_target_cnt      := gn_target_cnt + 1;
--
      END LOOP main_loop;
      CLOSE get_gl_bl_manual_cur;
    ELSE
      --==============================================================
      -- 2 ������s�̏ꍇ
      --==============================================================
      --�J�[�\���I�[�v��
      OPEN get_gl_bl_fixed_cur;
      <<main_loop>>
      LOOP
      FETCH get_gl_bl_fixed_cur INTO
            gt_data_tab(1)  -- ����Ȗڑg����ID
          , gt_data_tab(2)  -- ����Ȗڃ^�C�v
          , gt_data_tab(3)  -- �`�e�e��ЃR�[�h
          , gt_data_tab(4)  -- �`�e�e����R�[�h
          , gt_data_tab(5)  -- ���喼��
          , gt_data_tab(6)  -- �`�e�e����ȖڃR�[�h
          , gt_data_tab(7)  -- ����Ȗږ���
          , gt_data_tab(8)  -- �`�e�e�⏕�ȖڃR�[�h
          , gt_data_tab(9)  -- �⏕�Ȗږ���
          , gt_data_tab(10) -- �`�e�e�ڋq�R�[�h
          , gt_data_tab(11) -- �ڋq����
          , gt_data_tab(12) -- �`�e�e��ƃR�[�h
          , gt_data_tab(13) -- ��Ɩ���
          , gt_data_tab(14) -- �`�e�e�\���P
          , gt_data_tab(15) -- �\���P����
          , gt_data_tab(16) -- �`�e�e�\���Q
          , gt_data_tab(17) -- �\���Q����
          , gt_data_tab(18) -- ��v���Ԗ�
          , gt_data_tab(19) -- ��v�N�x
          , gt_data_tab(20) -- ��v���Ԕԍ�
          , gt_data_tab(21) -- �ʉ݃R�[�h
          , gt_data_tab(22) -- ���Ԏؕ�
          , gt_data_tab(23) -- ���ԑݕ�
          , gt_data_tab(24) -- �l�����ؕ��݌v
          , gt_data_tab(25) -- �l�����ݕ��݌v
          , gt_data_tab(26) -- ����ؕ��c��
          , gt_data_tab(27) -- ����ݕ��c��
          , gt_data_tab(28) -- �c��
          , gt_data_tab(29) -- �A�g����
          , gt_data_tab(30) -- �L����v���Ԕԍ�
          , gt_data_tab(31) -- �f�[�^�^�C�v
          ;
      EXIT WHEN get_gl_bl_fixed_cur%NOTFOUND;
--
        --==============================================================
        --���ڃ`�F�b�N����(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- �ǉ��X�V�敪
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- ����蓮�敪
         ,ov_item_chk                   =>        lv_item_chk    -- ���ڃ`�F�b�N���{�t���O
         ,ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
         ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
        IF ( lv_retcode = cv_status_normal ) THEN
          --�`�F�b�N������I�������ꍇ�ACSV�o�͂���
          --==============================================================
          -- CSV�o�͏���(A-6)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn )
          AND ( lv_item_chk = cv_flag_y ) THEN
          IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
            --�x���I�����A�^���`�F�b�N���������߂̏ꍇ�A���b�Z�[�W�o��
            lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfo     -- 'XXCFO'
                                    ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                    ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                              ,cv_msgtkn_cfo_11073)
                                      || cv_msg_part 
                                      || gt_data_tab(18) --��v����
                                    )
                                  ,1
                                  ,5000);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
          ELSE
            IF ( lv_ins_wait_flg <> cv_flag_y) THEN
              -- ����v���ԂŖ��A�g�e�[�u���ɓo�^���s���Ă��Ȃ��ꍇ�̂݁A�o�^���s��
              -- (��������v���Ԃŕ����o�^�͍s��Ȃ�)
              --==============================================================
              --���A�g�e�[�u���o�^����(A-7)
              --==============================================================
              ins_gl_bl_wait_coop(
                iv_meaning                  =>        lv_errmsg     -- A-5�̃��[�U�[�G���[���b�Z�[�W
              , ov_errbuf                   =>        lv_errbuf     -- �G���[���b�Z�[�W
              , ov_retcode                  =>        lv_retcode    -- ���^�[���R�[�h
              , ov_errmsg                   =>        lv_errmsg     -- ���[�U�[�E�G���[���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
              --���A�g�o�^�σt���O��'Y'�ɍX�V����
              lv_ins_wait_flg := cv_flag_y;
            END IF;
          END IF;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          --�����𒆒f
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(31) = cv_data_type_0 ) THEN
          --�f�[�^�^�C�v��0(�A�g��)�̏ꍇ�A�Ώی����i�A�g���j��1�J�E���g
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --�f�[�^�^�C�v��1(���A�g��)�̏ꍇ�A�Ώی����i���A�g���j��1�J�E���g
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
      END LOOP main_loop;
      CLOSE get_gl_bl_fixed_cur;
    END IF;
--
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_bl;
--
  /**********************************************************************************
   * Procedure Name   : upd_gl_bl_control
   * Description      : �Ǘ��e�[�u���폜�E�X�V����(A-8)
   ***********************************************************************************/
  PROCEDURE upd_gl_bl_control(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gl_bl_control'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    --���A�g�f�[�^�폜
    --==============================================================
    --A-2�Ŏ擾�������A�g�f�[�^�������ɁA�폜���s��
    <<delete_loop>>
    FOR i IN 1 .. gl_bl_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_gl_balance_wait_coop xgbwc -- �c�����A�g
        WHERE xgbwc.rowid = gl_bl_wait_coop_tab( i ).row_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                ( cv_msg_kbn_cfo     -- XXCFO
                                  ,cv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                  ,cv_tkn_table       -- �g�[�N��'TABLE'
                                  ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                            ,cv_msgtkn_cfo_11113) -- �c�����A�g
                                  ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                  ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                 )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
    END LOOP;
--
    --==============================================================
    --�c���Ǘ��e�[�u���X�V
    --==============================================================
    BEGIN
      UPDATE xxcfo_gl_balance_control xgbc -- �c���Ǘ�
      SET xgbc.effective_period_num   = gt_data_tab(30)           -- �L����v���Ԕԍ�
         ,xgbc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
         ,xgbc.last_update_date       = SYSDATE                   -- �ŏI�X�V��
         ,xgbc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
         ,xgbc.request_id             = cn_request_id             -- �v��ID
         ,xgbc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
         ,xgbc.program_id             = cn_program_id             -- �v���O����ID
         ,xgbc.program_update_date    = SYSDATE                   -- �v���O�����X�V��
      ;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                     ,cv_msg_cfo_00020   -- �f�[�^�X�V�G���[
                                                     ,cv_tkn_table       -- �g�[�N��'TABLE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11114) -- �c���Ǘ��e�[�u��
                                                     ,cv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_gl_bl_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2, -- 2.�t�@�C����
    iv_period_name_from   IN  VARCHAR2, -- 3.��v����(From)
    iv_period_name_to     IN  VARCHAR2, -- 4.��v����(To)
    iv_exec_kbn           IN  VARCHAR2, -- 5.����蓮�敪
    ov_errbuf             OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_next_period_flg VARCHAR2(1) DEFAULT NULL; -- ����v���ԗL���t���O(����̂�)
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
    gn_target_wait_cnt := 0;
    gn_wait_data_cnt   := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_ins_upd_kbn      -- 1.�ǉ��X�V�敪
      ,iv_file_name        -- 2.�t�@�C����
      ,iv_period_name_from -- 3.��v����(From)
      ,iv_period_name_to   -- 4.��v����(To)
      ,iv_exec_kbn         -- 5.����蓮�敪
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_gl_bl_wait_coop(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_gl_bl_control(
      iv_ins_upd_kbn,      -- 1.�ǉ��X�V�敪
      iv_period_name_from, -- 2.��v����(From)
      iv_period_name_to,   -- 3.��v����(To)
      iv_exec_kbn,         -- 4.����蓮�敪
      lv_next_period_flg,  -- ����v���ԗL���t���O(����̂�)
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x���t���O��Y�ɂ���
      gv_warning_flg := cv_flag_y;
    END IF;
--
    IF ( lv_next_period_flg IS NULL ) THEN
      --A-3�ŗ���v���Ԃ��擾��(����̂�)�܂��́A�蓮���s�̏ꍇ�̂݁A�㑱�������s��
      -- ===============================
      -- �Ώۃf�[�^�擾(A-4)
      -- ===============================
      get_gl_bl(
        iv_ins_upd_kbn      -- 1.�ǉ��X�V�敪
       ,iv_exec_kbn         -- 4.����蓮�敪
       ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        --�x���t���O��Y�ɂ���
        gv_warning_flg := cv_flag_y;
      END IF;
--
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        --������s�̏ꍇ�̂݁A�ȉ��̏������s��
        -- ===============================
        -- �Ǘ��e�[�u���o�^�E�X�V����(A-8)
        -- ===============================
        upd_gl_bl_control(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          --�����I�����ɁA�쐬�����t�@�C����0Byte�ɂ���
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        END IF;
      END IF;
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_ins_upd_kbn        IN  VARCHAR2,      -- 1.�ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2,      -- 2.�t�@�C����
    iv_period_name_from   IN  VARCHAR2,      -- 3.��v����(From)
    iv_period_name_to     IN  VARCHAR2,      -- 4.��v����(To)
    iv_exec_kbn           IN  VARCHAR2       -- 5.����蓮�敪
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
       iv_ins_upd_kbn                              -- 1.�ǉ��X�V�敪
      ,iv_file_name                                -- 2.�t�@�C����
      ,iv_period_name_from                         -- 3.��v����(From)
      ,iv_period_name_to                           -- 4.��v����(To)
      ,iv_exec_kbn                                 -- 5.����蓮�敪
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_wait_data_cnt   := 0;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�����Ōx�����������A�G���[�I���łȂ��ꍇ�A�X�e�[�^�X���x���ɂ���
    IF ( lv_retcode <> cv_status_error )
    AND ( gv_warning_flg = cv_flag_y ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    -- ====================================================
    -- �t�@�C���N���[�Y
    -- ====================================================
    -- �t�@�C�����I�[�v������Ă���ꍇ�̓N���[�Y����
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- �t�@�C��0Byte�X�V
    -- ====================================================
    -- �蓮���s���AA-5�ȍ~�̏����ŃG���[���������Ă����ꍇ�A
    -- �t�@�C�����ēx�I�[�v�����N���[�Y���A0Byte�ɍX�V����
    IF ( ( iv_exec_kbn = cv_exec_manual )
    AND ( lv_retcode = cv_status_error )
    AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o�́i�A�g���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o�́i���A�g�������j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���A�g�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_wait_data_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCFO019A01C;
/
