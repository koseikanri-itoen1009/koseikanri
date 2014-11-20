CREATE OR REPLACE PACKAGE BODY XXCFO019A05C AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A05C
 * Description      : �d�q����AP�x���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A05_�d�q����AP�x���̏��n�V�X�e���A�g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       ��������(A-1)
 *  get_ap_check_wait          ���A�g�f�[�^�擾����(A-2)
 *  get_ap_check_control       �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  chk_check_target           �x���f�[�^�A�g�Ώۃ`�F�b�N(A-4)
 *  get_ap_check               �Ώۃf�[�^�擾(A-5)
 *  chk_gl_transfer            GL�]���`�F�b�N(A-6)
 *  chk_item                   ���ڃ`�F�b�N����(A-7)
 *  out_csv                    �b�r�u�o�͏���(A-8)
 *  out_ap_check_wait          ���A�g�e�[�u���o�^����(A-9)
 *  del_ap_check_wait          ���A�g�e�[�u���폜����(A-10)
 *  ins_upd_ap_check_control   �Ǘ��e�[�u���o�^�E�X�V����(A-11)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/25    1.0   M.Kitajma        ����쐬
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
  gn_target_cnt      NUMBER;                    -- �Ώی����i�A�g���j
  gn_normal_cnt      NUMBER;                    -- ��������
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
  -- ���[�U�[��`��O
  -- ===============================
  -- *** ���b�N�G���[�n���h�� ***
    global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A05C'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
                                                                -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
--
  -- �v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';
                                                                -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_prf_gl_set_of_bks_id     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
                                                                -- ��v����ID
  cv_prf_org_id               CONSTANT VARCHAR2(50)  := 'ORG_ID';
                                                                -- �g�DID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AP_PAYMENT_I_FILENAME';
                                                                -- �d�q����`�o�x�������ǉ��t�@�C����
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AP_PAYMENT_U_FILENAME';
                                                                -- �d�q����`�o�x���X�V�t�@�C����
  -- ���b�Z�[�W�ԍ�
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';
                                                                -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025';   -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189';   -- �Q�ƃ^�C�v�擾�G���[���b�Z�[�W
  cv_msg_cff_00002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002';   -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';   -- �Ɩ����t�擾�G���[
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025';   -- �폜�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';   -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';   -- �t�@�C�������݃G���[���b�Z�[�W
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00031';   -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10001';   -- �Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10002';   -- �Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10003';   -- ���A�g�������b�Z�[�W
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10004';   -- �p�����[�^���͕s�����b�Z�[�W
  cv_msg_cfo_10016            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10016';   -- �p�����[�^���͕s�G���[���b�Z�[�W
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10008';   -- �p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007';   -- ���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10009            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10009';   -- �ԍ��w��G���[���b�Z�[�W
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10006';   -- �͈͎w��G���[���b�Z�[�W
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010';   -- ���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011';   -- �������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';   -- ���b�N�G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';            -- �f�B���N�g����
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';           -- �e�[�u����
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';             -- �p�����[�^��
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';             -- �p�����[�^��
  cv_tkn_param                CONSTANT VARCHAR2(20)  := 'PARAM';              -- �p�����[�^��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';          -- �v���t�@�C����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';          -- �t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';              -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- �G���[���e
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';        -- ���b�N�A�b�v�^�C�v��
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';        -- ���b�N�A�b�v�R�[�h��
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';              -- ����
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';             -- ���ڒl
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';            -- �Ӗ�
  cv_tkn_doc_div              CONSTANT VARCHAR2(20)  := 'DOC_DIV';            -- ���ږ�
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';           -- ���ږ�
  cv_tkn_max_id               CONSTANT VARCHAR2(20)  := 'MAX_ID';             -- ���ڒl�̍ő�l
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';        -- ���ڒl
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';           -- �G���[���e
  --���b�Z�[�W�o�͗p(�g�[�N���o�^)
  cv_msgtkn_cfo_11097         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11097';   -- �؜ߔԍ�
  cv_msgtkn_cfo_11098         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11098';   -- �����x��ID
  cv_msgtkn_cfo_11099         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11099';   -- �����x��ID(From)
  cv_msgtkn_cfo_11100         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11100';   -- �����x��ID(To)
  cv_msgtkn_cfo_11101         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11101';   -- �`�o�x���Ǘ��e�[�u��
  cv_msgtkn_cfo_11102         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11102';   -- �`�o�x�����A�g�e�[�u��
  cv_msgtkn_cfo_11103         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11103';   -- �`�o�x�����
  cv_msgtkn_cfo_11034         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11034';   -- �d�󖢍쐬
  cv_msgtkn_cfo_11035         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11035';   -- �d�󖢓]��
  cv_msgtkn_cfo_11036         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11036';   -- �f�k�]���`�F�b�N�G���[
  cv_msgtkn_cfo_11037         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11037';   -- ���ڃ`�F�b�N�G���[
  cv_msgtkn_cfo_11104         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11104';   -- �؜ߔԍ��A�����x��ID
  --���b�Z�[�W�o�͗p
  cv_msg_ap_check_num         CONSTANT VARCHAR2(30)  := '�؜ߔԍ�';       -- ���b�Z�[�W�o�͗p
  cv_msg_ap_invoice_num       CONSTANT VARCHAR2(30)  := '�������ԍ�';         -- ���b�Z�[�W�o�͗p
  cv_clm_colon                CONSTANT VARCHAR2(30)  := ':';                  -- ���b�Z�[�W�o�͗p
  -- �Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      -- �d�q���돈�����s��
  cv_lookup_item_chk_pay      CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_PAY';
                                                                              -- �d�q���덀�ڃ`�F�b�N�i�`�o�x���j
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --����
  --�b�r�u
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_file_mode_w              CONSTANT VARCHAR2(1)   := 'W';                  -- �t�@�C�����[�h
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;               -- �t�@�C���T�C�Y
  --���ڑ���
  cv_item_attr_vc2            CONSTANT VARCHAR2(1) := '0';                    -- VARCHAR����
  cv_item_attr_num            CONSTANT VARCHAR2(1) := '1';                    -- NUMBER����
  cv_item_attr_date           CONSTANT VARCHAR2(1) := '2';                    -- DATE����
  cv_item_attr_cha            CONSTANT VARCHAR2(1) := '3';                    -- CHAR����
  --���s���[�h
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- ������s
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- �蓮���s
  --�ǉ��X�V�敪
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- �ǉ�
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- �X�V
  --��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  --�Œ�l
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
  --�t�@�C���o��
  cv_file_type_out            CONSTANT VARCHAR2(10)  := 'OUTPUT';             -- ���b�Z�[�W�o��
  cv_file_type_log            CONSTANT VARCHAR2(10)  := 'LOG';                -- ���O�o��
   --�d��G���[�敪
  cv_gl_je_no_data            CONSTANT VARCHAR2(1) := '0';                    -- �d�󖢍쐬
  cv_gl_je_no_transfer        CONSTANT VARCHAR2(1) := '1';                    -- �d�󖢓]��
  cv_gl_je_yes_transfer       CONSTANT VARCHAR2(1) := '2';                    -- �d��]����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                                         -- �Ɩ����t
  gd_coop_date                DATE;                                                         -- �A�g���t
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;                            -- �d�q���돈�����s����
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;                            -- �����Ώێ���
  gt_gl_set_of_books_id       ap_invoice_payments_all.set_of_books_id%TYPE;                 -- ��v����ID
  gt_org_id                   ap_checks_all.org_id%TYPE;                                    -- �g�DID
  gv_activ_file_h             UTL_FILE.FILE_TYPE;                                           -- �t�@�C���n���h���擾�p
  gv_file_name                VARCHAR2(100) DEFAULT NULL;                                   -- �t�@�C����
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL;             -- �f�B���N�g����
  gt_directory_path           all_directories.directory_path%TYPE DEFAULT NULL;             -- �f�B���N�g��
  -- ���ڃ`�F�b�N
  TYPE g_item_name_ttype      IS TABLE OF fnd_lookup_values.attribute1%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype       IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype   IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype   IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype      IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype    IS TABLE OF fnd_lookup_values.attribute6%TYPE
                                          INDEX BY PLS_INTEGER;
  --
  --�`�o�x����
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)
                                          INDEX BY PLS_INTEGER;
  gt_data_tab                   g_layout_ttype;             -- �o�̓f�[�^���
  gt_item_name                  g_item_name_ttype;          -- ���ږ���
  gt_item_len                   g_item_len_ttype;           -- ���ڂ̒���
  gt_item_decimal               g_item_decimal_ttype;       -- ���ځi�����_�ȉ��̒����j
  gt_item_nullflg               g_item_nullflg_ttype;       -- �K�{���ڃt���O
  gt_item_attr                  g_item_attr_ttype;          -- ���ڑ���
  gt_item_cutflg                g_item_cutflg_ttype;        -- �؎̂ăt���O
  --
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
  -- �`�o�x�����A�g�f�[�^�擾�J�[�\��
  CURSOR  get_ap_check_wait_cur
  IS
    SELECT
       xcwc.rowid                      -- ROWID
      ,xcwc.invoice_payment_id         -- �����x���h�c
    FROM xxcfo_ap_check_wait_coop xcwc -- �`�o�x�����A�g
    ;
    -- �e�[�u���^
    TYPE ap_check_wait_ttype IS TABLE OF get_ap_check_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_ap_check_wait_tab ap_check_wait_ttype;
--
  -- �`�o�x���Ǘ��e�[�u���擾�J�[�\��
  CURSOR get_ap_check_ctl_to_cur
  IS
    SELECT  xacc.rowid
           ,xacc.invoice_payment_id    -- �����x���h�c
    FROM   xxcfo_ap_check_control xacc -- �`�o�x���Ǘ�
    WHERE  xacc.process_flag = cv_flag_n
    ORDER BY xacc.invoice_payment_id DESC,xacc.creation_date DESC
    FOR UPDATE NOWAIT;
  -- �e�[�u���^
  TYPE ap_check_ctl_ttype IS TABLE OF get_ap_check_ctl_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ap_check_ctl_tab  ap_check_ctl_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_ins_upd_kbn        IN  VARCHAR2                                                   -- �ǉ��X�V�敪
    ,iv_file_name          IN  VARCHAR2                                                   -- �t�@�C����
    ,it_doc_sequence_val   IN  ap_checks_all.doc_sequence_value%TYPE                      -- �؜ߔԍ�
    ,it_invoice_pay_id_fr  IN  ap_invoice_payments_all.invoice_payment_id%TYPE            -- �����x��ID(From)
    ,it_invoice_pay_id_to  IN  ap_invoice_payments_all.invoice_payment_id%TYPE            -- �����x��ID(To)
    ,iv_fixedmanual_kbn    IN  VARCHAR2                                                   -- ����蓮�敪
    ,ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W                        --# �Œ� #
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h                          --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W              --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
    -- *** ���[�J���ϐ� ***
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists            BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length       NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size        BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg               VARCHAR2(3000);
    ln_item_data_count   NUMBER;                        -- ���ڃ`�F�b�N�J�E���g
    lv_full_name         VARCHAR2(200)   DEFAULT NULL;  -- �d�q����t�@�C����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  get_chk_item_cur( gd_process_date IN DATE )
    IS
      SELECT    flv.meaning             -- ���ږ���
              , flv.attribute1          -- ���ڂ̒���
              , flv.attribute2          -- ���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          -- �K�{�t���O
              , flv.attribute4          -- ����
              , flv.attribute5          -- �؎̂ăt���O
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_pay
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       ct_lang
      ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_msg    := NULL;
    ln_item_data_count := 0;
--
    --==============================================================
    -- 1.(1)  �p�����[�^�o��
    --==============================================================
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => it_doc_sequence_val   -- �؜ߔԍ�
      ,iv_conc_param4  => it_invoice_pay_id_fr  -- �����x��ID�iFrom�j
      ,iv_conc_param5  => it_invoice_pay_id_to  -- �����x��ID�iTo�j
      ,iv_conc_param6  => iv_fixedmanual_kbn    -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN 
        RAISE global_api_expt; -- �`�o�h�G���[
      END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ���O�o��
      ,iv_conc_param1  => iv_ins_upd_kbn        -- �ǉ��X�V�敪
      ,iv_conc_param2  => iv_file_name          -- �t�@�C����
      ,iv_conc_param3  => it_doc_sequence_val   -- �؜ߔԍ�
      ,iv_conc_param4  => it_invoice_pay_id_fr  -- �����x��ID�iFrom�j
      ,iv_conc_param5  => it_invoice_pay_id_to  -- �����x��ID�iTo�j
      ,iv_conc_param6  => iv_fixedmanual_kbn    -- ����蓮�敪
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN 
        RAISE global_api_expt; 
      END IF; 
--
    --==============================================================
    -- 1.(2) [������s]�̏ꍇ�A�ȉ��̏����œ��̓p�����[�^�̃`�F�b�N�����{
    -- �u�؜ߔԍ��v�u�����x��ID(From)�v�u�����x��ID(To)�v�̂����ꂩ���w
    --  �肳��Ă���ꍇ
    --==============================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      IF ( it_doc_sequence_val IS NOT NULL )
        OR ( it_invoice_pay_id_fr IS NOT NULL ) OR ( it_invoice_pay_id_to IS NOT NULL )
      THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                        ,cv_msg_cfo_10016          -- �p�����[�^���͕s�G���[
                                                        ,cv_tkn_param1             -- �g�[�N��'PARAM1'
                                                        ,cv_msgtkn_cfo_11097       -- �؜ߔԍ�
                                                        ,cv_tkn_param2             -- �g�[�N��'PARAM2'
                                                        ,cv_msgtkn_cfo_11098       -- �����x��ID
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(3)[�蓮���s]�̏ꍇ�A�ȉ��̏����œ��̓p�����[�^�̃`�F�b�N�����{
    -- �E�u�؜ߔԍ��v�u�����x��ID(From)�v�u�����x��ID(To)�v���S�Ďw�肳��
    --    �Ă��Ȃ��ꍇ
    -- �E�u�؜ߔԍ��v�u�����x��ID(From)�v�������Ƃ��w�肳��Ă���ꍇ
    --   �u�؜ߔԍ��v�u�����x��ID(To)�v�������Ƃ��w�肳��Ă���ꍇ
    -- �E�u�����x��ID(From)�v���w�肳��Ă���A�u�����x��ID(To)�v���w�肳��
    --    �Ă��Ȃ��ꍇ
    -- �E�u�����x��ID(To)�v���w�肳��Ă���A�u�����x��ID(From)�v���w�肳��
    --    �Ă��Ȃ��ꍇ
    -- �E�u�����x��ID(From)�v���u�����x��ID(To)�v�̊֌W�Ŏw�肳��Ă����ꍇ
    --==============================================================
    IF  ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
      IF  ( ( it_doc_sequence_val IS NULL ) AND ( it_invoice_pay_id_fr IS NULL )
            AND ( it_invoice_pay_id_to IS NULL ) )
          OR ( ( it_doc_sequence_val IS NOT NULL ) AND ( it_invoice_pay_id_fr IS NOT NULL ) )
          OR ( ( it_doc_sequence_val IS NOT NULL ) AND ( it_invoice_pay_id_to IS NOT NULL ) )  THEN
            lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                            ,cv_msg_cfo_10004          -- �p�����[�^���͕s���G���[
                                                            ,cv_tkn_param              -- �g�[�N��'PARAM'
                                                            ,cv_msgtkn_cfo_11104       -- �؜ߔԍ��A�����x��ID
                                                           )
                                  ,1
                                  ,5000
                                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
      IF  ( ( it_invoice_pay_id_fr IS NOT NULL ) AND ( it_invoice_pay_id_to IS NULL ) )
          OR ( ( it_invoice_pay_id_fr IS NULL ) AND  ( it_invoice_pay_id_to IS NOT NULL ) )
          OR ( it_invoice_pay_id_fr   > it_invoice_pay_id_to ) THEN
            lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                            ,cv_msg_cfo_10008          -- �p�����[�^���͕s���G���[
                                                            ,cv_tkn_param1             -- �g�[�N��'PARAM1'
                                                            ,cv_msgtkn_cfo_11099       -- �����x��ID(From)
                                                            ,cv_tkn_param2             -- �g�[�N��'PRAM2'
                                                            ,cv_msgtkn_cfo_11100       -- �����x��ID(To)
                                                           )
                                  ,1
                                  ,5000
                                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(4) �Ɩ��������t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00015          -- �Ɩ����t�擾�G���[
                                                     )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
--
    --==============================================================
    -- 1.(5) �N�C�b�N�R�[�h��荀�ڃ`�F�b�N�����p�̏����擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_chk_item_cur( gd_process_date );
    -- �f�[�^�̈ꊇ�擾
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- �Ώی����̃Z�b�g
    ln_item_data_count := gt_item_name.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
--
    IF ln_item_data_count = 0 THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- 'XXCFF'
                                                      ,cv_msg_cff_00189           -- �Q�ƃ^�C�v�擾�G���[
                                                      ,cv_tkn_lookup_type         -- �g�[�N��'LOOKUP_TYPE'
                                                      ,cv_lookup_item_chk_pay
                                                                                -- �uXXCFO1_ELECTRIC_ITEM_CHK_PAY�v
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
--
    --==============================================================
    -- 1.(6) �N�C�b�N�R�[�h���d�q���돈�����s�����Ə����Ώێ����̎擾
    --==============================================================
    BEGIN
      SELECT      flv.attribute1
                , flv.attribute2
      INTO        gt_electric_exec_days
                , gt_proc_target_time
      FROM        fnd_lookup_values       flv
      WHERE       flv.lookup_type         =       cv_lookup_book_date
      AND         flv.lookup_code         =       cv_pkg_name
      AND         gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                          AND     NVL(flv.end_date_active, gd_process_date)
      AND         flv.enabled_flag        =       cv_flag_y
      AND         flv.language            =       ct_lang;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00031      -- �N�C�b�N�R�[�h�擾�G���[
                                                        ,cv_tkn_lookup_type    -- �g�[�N��'LOOKUP_TYPE' 
                                                        ,cv_lookup_book_date   -- �uXXCFO1_ELECTRIC_BOOK_DATE�v
                                                        ,cv_tkn_lookup_code    -- �g�[�N��'LOOKUP_CODE'
                                                        ,cv_pkg_name           -- �uXXCFO019A05C�v
                                                       )
                              ,1
                              ,5000
                            );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END;
    -- �d�q���돈�����s���������͏����Ώێ������Z�b�g����Ă��Ȃ��ꍇ
    IF ( gt_electric_exec_days IS NULL ) OR ( gt_proc_target_time IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00031      -- �N�C�b�N�R�[�h�擾�G���[
                                                        ,cv_tkn_lookup_type    -- �g�[�N��'LOOKUP_TYPE' 
                                                        ,cv_lookup_book_date   -- �uXXCFO1_ELECTRIC_BOOK_DATE�v
                                                        ,cv_tkn_lookup_code    -- �g�[�N��'LOOKUP_CODE'
                                                        ,cv_pkg_name           -- �uXXCFO019A05C�v
                                                       )
                              ,1
                              ,5000
                            );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
--
    --==============================================================
    -- 1.(7) �v���t�@�C���̎擾
    --==============================================================
    --�t�@�C���p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo       -- 'XXCFO'
                                                      ,cv_msg_cfo_00001     -- �v���t�@�C���擾�G���[
                                                      ,cv_tkn_prof_name     -- �g�[�N��'PROF_NAME' 
                                                      ,cv_data_filepath
                                                                            -- �uXXCFO1_ELECTRIC_BOOK_DATA_FILEPATH�v
                                                      )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
    --��v����ID
    gt_gl_set_of_books_id  := FND_PROFILE.VALUE( cv_prf_gl_set_of_bks_id );
    --
    IF ( gt_gl_set_of_books_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00001          -- �v���t�@�C���擾�G���[
                                                      ,cv_tkn_prof_name          -- �g�[�N��'PROF_NAME' 
                                                      ,cv_prf_gl_set_of_bks_id   -- �uGL_SET_OF_BKS_ID�v
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
    --�g�DID
    gt_org_id  := FND_PROFILE.VALUE( cv_prf_org_id );
    --
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00001          -- �v���t�@�C���擾�G���[
                                                      ,cv_tkn_prof_name          -- �g�[�N��'PROF_NAME' 
                                                      ,cv_prf_org_id             -- �uORG_ID�v
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
    --
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    END IF;
    --
    IF ( iv_file_name IS NULL ) AND ( iv_ins_upd_kbn = cv_ins_upd_0 )  THEN
      --�ǉ��t�@�C����
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,cv_msg_cfo_00001  -- �v���t�@�C���擾�G���[
                                                        ,cv_tkn_prof_name  -- �g�[�N��'PROF_NAME' 
                                                        ,cv_add_filename
                                                        -- �uXXCFO1_ELECTRIC_BOOK_AP_PAYMENT_I_FILENAME�v
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
    END IF;
    --
    IF ( iv_file_name IS NULL ) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --�X�V�t�@�C����
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,cv_msg_cfo_00001  -- �v���t�@�C���擾�G���[
                                                        ,cv_tkn_prof_name  -- �g�[�N��'PROF_NAME' 
                                                        ,cv_upd_filename
                                                          -- �uXXCFO1_ELECTRIC_BOOK_AP_PAYMENT_I_FILENAME�v
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(8) �f�B���N�g���p�X�擾
    --==============================================================
    BEGIN
      SELECT    ad.directory_path
      INTO      gt_directory_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_coi    -- 'XXCOI'
                                                      ,cv_msg_coi_00029  -- �f�B���N�g���p�X�擾�G���[
                                                      ,cv_tkn_dir_tok    -- �g�[�N��'DIR_TOK' 
                                                      ,gt_file_path      -- �f�B���N�g���p�X
                                                     )
                            ,1
                            ,5000
                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END;
--
    --==============================================================
    -- 1.(9) �t�@�C�����o��
    --==============================================================
     --�擾�����f�B���N�g���p�X�̖�����'/'(�X���b�V��)�����݂���ꍇ�A
    --�f�B���N�g���ƃt�@�C�����̊Ԃ�'/'�A���͍s�킸�Ƀt�@�C�������o�͂���
    IF  SUBSTRB(gt_directory_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  gt_directory_path || gv_file_name;
    ELSE
      lv_full_name :=  gt_directory_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_msg_kbn_cfo
              , iv_name         => cv_msg_cff_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_full_name
              );
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 1.(10) �A�g�����p��SYSDATE(YYYYMMDDHHMMSS)�̎擾
    --==============================================================
    gd_coop_date := SYSDATE;
--
    --==============================================================
    -- 2.(1) ����t�@�C���̑��݃`�F�b�N
    --==============================================================
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_cfo_00027  -- ����t�@�C�����݃G���[
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;   -- �`�o�h�G���[
    END IF;
    --
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_ap_check_wait
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_ap_check_wait(
     ov_errbuf            OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_check_wait'; -- �v���O������
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    --
    --==============================================================
    -- 1.���A�g�f�[�^�̎擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_ap_check_wait_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_ap_check_wait_cur BULK COLLECT INTO
      gt_ap_check_wait_tab;
    CLOSE get_ap_check_wait_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
      -- �J�[�\���N���[�Y
      IF get_ap_check_wait_cur%ISOPEN THEN
        CLOSE get_ap_check_wait_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ap_check_wait;
--
  /**********************************************************************************
   * Procedure Name   : �Ǘ��e�[�u���f�[�^�擾����
   * Description      : �`�o�x���Ǘ��e�[�u���̃f�[�^���擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_ap_check_control(
     iv_fixedmanual_kbn      IN     VARCHAR2                                             -- ����蓮�敪
    ,ot_invoice_pay_id_fr    OUT    ap_invoice_payments_all.invoice_payment_id%TYPE      -- �����x��ID_fr
    ,ot_invoice_pay_id_to    OUT    ap_invoice_payments_all.invoice_payment_id%TYPE      -- �����x��ID_to
    ,ot_invoice_pay_id_max   OUT    ap_invoice_payments_all.invoice_payment_id%TYPE      -- �����x��ID_max
    ,ov_errbuf               OUT    VARCHAR2     -- �G���[�E���b�Z�[�W                   --# �Œ� #
    ,ov_retcode              OUT    VARCHAR2     -- ���^�[���E�R�[�h                     --# �Œ� #
    ,ov_errmsg               OUT    VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W         --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_check_control'; -- �v���O������
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
    lt_invoice_pay_id  ap_invoice_payments_all.invoice_payment_id%TYPE;  -- �����x��ID
--
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_pay_id := NULL;
--
    --==============================================================
    -- 1.[������s��]-�����x��ID�͈̔͂�From�l���擾
    --   [�蓮���s��]-�����x��ID�͈̔͂�To�l���擾
    --==============================================================
    -- �`�o�x����(�ŐV�̏����ϐ����x��ID)�擾
    SELECT MAX(xacc.invoice_payment_id)       -- �����x��ID
    INTO   lt_invoice_pay_id
    FROM   xxcfo_ap_check_control xacc        -- �`�o�x���Ǘ�
    WHERE  xacc.process_flag = cv_flag_y;
--
    -- �f�[�^���擾�ł��Ȃ������ꍇ
    IF lt_invoice_pay_id IS NULL THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                      ,cv_tkn_get_data       -- �g�[�N��'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11101   -- �`�o�x���Ǘ��e�[�u��
                                                      )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ���[�U�[�G���[
    END IF;
--
    --[������s]�̏ꍇ�͔͈͂̐����x��ID(From)�Ƃ��Ďg�p
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      ot_invoice_pay_id_fr   := lt_invoice_pay_id;
    ELSIF ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
    --[�蓮���s]�̏ꍇ�͑��M�ς��̃`�F�b�N�Ő����x��ID(max)�Ƃ��Ďg�p
      ot_invoice_pay_id_max  := lt_invoice_pay_id;
    END IF;
--
    --==============================================================
    -- 2.[������s��]-�����x��ID�͈̔͂�To�l���擾
    --==============================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      -- �`�o�x����(�������`�o�x���x��ID)�擾
      -- �J�[�\���I�[�v��
      OPEN get_ap_check_ctl_to_cur;
      -- �f�[�^�̈ꊇ�擾
      FETCH get_ap_check_ctl_to_cur BULK COLLECT INTO gt_ap_check_ctl_tab;
      --�J�[�\���N���[�Y
      CLOSE get_ap_check_ctl_to_cur;
      --
      IF ( gt_ap_check_ctl_tab.COUNT = 0 ) THEN
        lv_retcode := cv_status_warn;
        lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                        ,cv_msg_cfo_10025    -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                        ,cv_tkn_get_data     -- �g�[�N��'GET_DATA'
                                                        ,cv_msgtkn_cfo_11101 -- �`�o�x���Ǘ��e�[�u��
                                                       )
                              ,1
                              ,5000
                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �`�o�����x��ID(To)�̎擾
      IF ( gt_ap_check_ctl_tab.COUNT < TO_NUMBER( gt_electric_exec_days ) ) THEN
        -- �擾�����Ǘ��f�[�^�������A�d�q���돈�����s�����������ꍇ�A�`�o�x���x��ID(To)��NULL��ݒ肷��
        ot_invoice_pay_id_to := NULL;
      ELSE
        -- �d�q���돈�����s������Y���Ƃ��Ďg�p����
        ot_invoice_pay_id_to := gt_ap_check_ctl_tab( TO_NUMBER( gt_electric_exec_days ) ).invoice_payment_id;
      END IF;
--
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                     ,cv_msgtkn_cfo_11101   -- �`�o�x���Ǘ��e�[�u��
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_ap_check_ctl_to_cur%ISOPEN THEN
        CLOSE get_ap_check_ctl_to_cur;
      END IF;
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
      -- �J�[�\���N���[�Y
      IF get_ap_check_ctl_to_cur%ISOPEN THEN
        CLOSE get_ap_check_ctl_to_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ap_check_control;
--
  /**********************************************************************************
   * Procedure Name   : �x���f�[�^�Ώۃ`�F�b�N����(A-4)
   * Description      : [�蓮���s]���A[�X�V]�̏ꍇ�A�x���f�[�^�A�g�̑Ώۃf�[�^�����݂��邩��
   *                    �`�F�b�N�����{
   ***********************************************************************************/
  PROCEDURE chk_check_target(
     iv_ins_upd_kbn          IN  VARCHAR2                                           -- �ǉ��X�V�敪
    ,it_doc_sequence_val     IN  ap_checks_all.doc_sequence_value%TYPE              -- �؜ߔԍ�
    ,it_invoice_pay_id_to    IN  ap_invoice_payments_all.invoice_payment_id%TYPE    -- �����x��ID(To)
    ,iv_fixedmanual_kbn      IN  VARCHAR2                                           -- ����蓮�敪
    ,it_invoice_pay_id_max   IN  ap_invoice_payments_all.invoice_payment_id%TYPE    -- �����x��ID(MAX�l)
    ,ov_errbuf               OUT VARCHAR2    -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode              OUT VARCHAR2    -- ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg               OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_check_target'; -- �v���O������
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
    lt_invoice_pay_id  ap_invoice_payments_all.invoice_payment_id%TYPE; --�����x��ID
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_pay_id := NULL;
--
    -- [�蓮���s]�A���A[�X�V]�̏ꍇ
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --==============================================================
      -- 1.(1) �؜ߔԍ����w�肳��Ă���ꍇ�A�w�肳��Ă���؜ߔԍ�
      --       �ɕR�Â�MAX(�����x��ID)���擾
      --==============================================================
      IF ( it_doc_sequence_val IS NOT NULL ) THEN
        SELECT MAX(aip.invoice_payment_id)                    -- 1.MAX(�����x��ID)
        INTO   lt_invoice_pay_id
        FROM   ap_invoice_payments_all aip,                   -- 2.AP�����x��
               ap_checks_all           aca                    -- 3.AP�x��
        WHERE  aca.doc_sequence_value = it_doc_sequence_val   -- 1.�؜ߔԍ�
        AND    aca.check_id           = aip.check_id          -- 2.�x��ID
        AND    aip.set_of_books_id    = gt_gl_set_of_books_id -- 3.��v����ID
        AND    aip.org_id             = aca.org_id            -- 4.�g�DID
        AND    aca.org_id             = gt_org_id;            -- 5.�g�DID
--
        -- �؜ߔԍ������݂��Ȃ��ꍇ
        IF lt_invoice_pay_id IS NULL THEN
          lt_invoice_pay_id := NULL;
        END IF;
      END IF;
--
      --==============================================================
      -- 1.(2) �擾���������x��ID��A-3�Ŏ擾���������x��ID(To)����
      --       �傫���ꍇ�A��O���������{
      --==============================================================
      IF ( lt_invoice_pay_id IS NOT NULL ) AND ( lt_invoice_pay_id > it_invoice_pay_id_max ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                        ,cv_msg_cfo_10009                -- �ԍ��w��G���[���b�Z�[�W
                                                        ,cv_tkn_doc_div                  -- �g�[�N��'DOC_DIV' 
                                                        ,cv_msgtkn_cfo_11097             -- �u�؜ߔԍ��v
                                                        ,cv_tkn_doc_data                 -- �g�[�N��'DOC_DATA'
                                                        ,cv_msgtkn_cfo_11098             -- �u�؜ߔԍ��v
                                                        ,cv_tkn_max_id                   -- �g�[�N��'MAX_ID'
                                                        ,TO_CHAR(it_invoice_pay_id_max) -- �����x��ID�̏����ς�MAX�l
                                                        ,cv_tkn_doc_dist_id              -- �g�[�N��'DOC_DIST_ID'
                                                        ,TO_CHAR(lt_invoice_pay_id)
                                                                                      -- �؜ߔԍ��ɕR�Â������x��ID
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
--
      --==============================================================
      -- 2.(1) �u�����x��ID(To)�v��A-3�Ŏ擾���������x��ID(To)����
      --       �傫���ꍇ�A�ȉ��̗�O����
      --==============================================================
      IF ( it_invoice_pay_id_to IS NOT NULL ) AND ( it_invoice_pay_id_to > it_invoice_pay_id_max ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                 -- 'XXCFO'
                                                        ,cv_msg_cfo_10006               -- �͈͒�G���[���b�Z�[�W
                                                        ,cv_tkn_max_id                  -- �g�[�N��'MAX_ID' 
                                                        ,TO_CHAR( it_invoice_pay_id_max )
                                                                                        -- �����x��ID�̏����ς�MAX�l
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ���[�U�[�G���[
      END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_check_target;
--
  /**********************************************************************************
   * Procedure Name   : GL�]���`�F�b�N(A-6)
   * Description      : �擾���������x��ID�̎d�󂪂f�k�]������Ă��邩�ǂ������`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_gl_transfer(
     ov_gl_je_flag           OUT VARCHAR2                         --  �d�󖢍쐬�A���]���t���O
    ,ov_errbuf               OUT VARCHAR2                         --  �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode              OUT VARCHAR2                         --  ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg               OUT VARCHAR2)                        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gl_transfer'; -- �v���O������
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
    cv_je_category_pay          CONSTANT VARCHAR2(30)  := 'Payments';            -- �x��
    cv_je_category_recpay       CONSTANT VARCHAR2(30)  := 'Reconciled Payments'; -- ��������
    cv_table_name               CONSTANT VARCHAR2(30)  := 'AP_INVOICE_PAYMENTS'; -- �����x���e�[�u��
--
    -- *** ���[�J���ϐ� ***
    lt_gl_transfer_flag         ap_ae_headers_all.gl_transfer_flag%TYPE;        -- GL�]���t���O
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_gl_transfer_flag := NULL;
--
    -- =================================================================
    -- =  1.�f�k�]���`�F�b�N�����{����ׁA�f�k�]���t���O���擾          
    -- =================================================================
    BEGIN
      SELECT aaha.gl_transfer_flag                          -- 1.GL�]���t���O
      INTO   lt_gl_transfer_flag
      FROM   ap_ae_headers_all aaha,                        -- 1.�`�o�d��w�b�_
             ap_ae_lines_all   aala                         -- 2.�`�o�d�󖾍�
      WHERE  aala.source_id       = gt_data_tab(1)          -- 1.�����x��ID
      AND    aala.source_table    = cv_table_name           -- 2.�e�[�u���� 'AP_INVOICE_PAYMENTS'
      AND    aaha.ae_header_id    = aala.ae_header_id       -- 3.�������w�b�_ID
      AND    aaha.set_of_books_id = gt_gl_set_of_books_id   -- 4.��v����ID
      AND    aala.org_id          = aaha.org_id             -- 5.�g�DID
      AND    aaha.org_id          = gt_org_id               -- 6.�g�DID
      AND    aaha.ae_category     IN ( cv_je_category_pay,cv_je_category_recpay )
                                                            -- 7.�d��J�e�S�� 'Payments' 'Reconciled Payments'
      GROUP BY aaha.gl_transfer_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �d�󖢍쐬�G���[
        ov_errbuf     := cv_msg_cfo_10007;
        ov_gl_je_flag := cv_gl_je_no_data;
        ov_retcode := cv_status_warn;
    END;
--
    -- �d�󂪓]������Ă��邩�̃`�F�b�N
    IF ( ov_retcode = cv_status_normal ) AND ( lt_gl_transfer_flag <> cv_flag_y ) THEN
      -- �d�󖢓]���G���[
      ov_errbuf     := cv_msg_cfo_10007;
      ov_gl_je_flag := cv_gl_je_no_transfer;
      ov_retcode    := cv_status_warn;
    END IF;
--
    -- �d�󂪓]������Ă���ꍇ
    IF ( ov_retcode = cv_status_normal ) THEN
      ov_gl_je_flag := cv_gl_je_yes_transfer;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END chk_gl_transfer;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      :���ڃ`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
     iv_ins_upd_kbn      IN     VARCHAR2        -- ����X�V�敪
    ,iv_fixedmanual_kbn  IN     VARCHAR2        -- �����蓮�敪
    ,ov_wait_ins_flag    OUT    VARCHAR2        -- ���A�g�e�[�u���}���ۃt���O
    ,ov_errbuf           OUT    VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT    VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT    VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- �v���O������
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
    cv_nullflg_ng CONSTANT VARCHAR2(7) := 'NULL_NG';  -- �K�{�t���O���f
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
--
    --=================================================================
    -- 1.����蓮�敪���蓮�̏ꍇ�A���A�X�V�̏ꍇ
    --   ���A�g�e�[�u���ɑ��݂���ꍇ�͌x��
    --=================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        <<ap_check_wait_chk_loop>>
        FOR i IN 1 .. gt_ap_check_wait_tab.COUNT LOOP
          IF gt_ap_check_wait_tab( i ).invoice_payment_id = gt_data_tab(1) THEN         -- �����x��ID
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo               -- 'XXCFO'
                                                          ,cv_msg_cfo_10010
                                                                             -- ���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
                                                          ,cv_tkn_doc_data              -- �g�[�N��'DOC_DATA'
                                                          ,cv_msgtkn_cfo_11098          -- �u�����x��ID�v
                                                          ,cv_tkn_doc_dist_id           -- �g�[�N��'DOC_DIST_ID'
                                                          ,gt_data_tab( 1 )             -- �����x��ID
                                                         )
                                                         ,1
                                                         ,5000
                                );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_wait_ins_flag := cv_flag_n;        --�蓮���s�ׁ̈A���A�g�e�[�u���ɑ}�����Ȃ�
            ov_errbuf        := cv_msg_cfo_10010; --�G���[���b�Z�[�W��}�����A���A�g�e�[�u���o�^�ł̓��b�Z�[�W�o�͂�
                                                  --���Ȃ��悤�ɂ���
            ov_errmsg        := lv_errmsg;
            ov_retcode       := cv_status_warn;
          END IF;
        END LOOP;
    END IF;
--
    --==============================================================
    -- 2.���ڌ��`�F�b�N�i�A�g�����͏���)
    --==============================================================
    IF ( ov_retcode = cv_status_normal ) THEN
      FOR i IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name                  =>        gt_item_name( i )              --���ږ���
          , iv_item_value                 =>        gt_data_tab( i )               --�ύX�O�̒l
          , in_item_len                   =>        gt_item_len( i )               --���ڂ̒���
          , in_item_decimal               =>        gt_item_decimal( i )           --���ڂ̒���(�����_�ȉ�)
          , iv_item_nullflg               =>        gt_item_nullflg( i )           --�K�{�t���O
          , iv_item_attr                  =>        gt_item_attr( i )              --���ڑ���
          , iv_item_cutflg                =>        gt_item_cutflg( i )            --�؎̂ăt���O
          , ov_item_value                 =>        gt_data_tab( i )               --���ڂ̒l
          , ov_errbuf                     =>        lv_errbuf                      --�G���[���b�Z�[�W
          , ov_retcode                    =>        lv_retcode                     --���^�[���R�[�h
          , ov_errmsg                     =>        lv_errmsg                      --���[�U�[�E�G���[���b�Z�[�W
          );
        -- �V�X�e���G���[�̏ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        -- �x���̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- �K�{���̓G���[�̏ꍇ
          IF ( ( gt_item_nullflg( i ) = cv_nullflg_ng ) AND ( NVL(gt_data_tab( i ),cv_flag_y ) = cv_flag_y )
               AND ( lv_errbuf IS NULL )
             ) THEN
            ov_wait_ins_flag := cv_flag_y;
          ELSE
            -- CHAR�AVARCHAR�̔��f�`�F�b�N
            -- ���A�g�e�[�u���ւ̓o�^���f�Ɏg�p
            IF ( gt_item_attr( i )  =  cv_item_attr_num )
               AND ( ( lv_errbuf = cv_msg_cfo_10011 ) OR  ( lv_errbuf IS NULL ) )
               THEN                                              -- ���l�����I�[�o�[�̏ꍇ
              ov_wait_ins_flag := cv_flag_n;                     -- ���A�g�e�[�u���ɑ}�����Ȃ�
            ELSE                                                 -- ��L�A�����ȊO
              ov_wait_ins_flag := cv_flag_y;                     -- ���A�g�e�[�u���ɑ}������
            END IF;
          END IF;
          ov_errbuf  := lv_errbuf;                             -- �G���[���b�Z�[�W
          ov_errmsg  := lv_errmsg;                             -- ���[�U�[�G���[���b�Z�[�W
          ov_retcode := cv_status_warn;                        -- �x���I��
          EXIT;
        END IF;
      END LOOP;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Description      : �b�r�u�o�͏���(A-8)
   ***********************************************************************************/
  PROCEDURE out_csv(
     ov_errbuf        OUT VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode       OUT VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg        OUT VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- �v���O������
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
    --�b�r�u�o�͗p������
    cv_csv_quote                CONSTANT VARCHAR2(1)   := '"';                  -- ��������
--
    -- *** ���[�J���ϐ� ***
    lv_delimit                VARCHAR2(1);
    lv_file_data              VARCHAR2(30000);
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_delimit:= NULL;
    lv_file_data:= NULL;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
--
    --�f�[�^�ҏW
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR i IN gt_item_name.FIRST..( gt_item_name.COUNT )  LOOP
      IF ( gt_item_attr( i ) IN ( cv_item_attr_vc2, cv_item_attr_cha ) ) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_csv_quote ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab( i ),CHR(10),' '), '"', ' '), ',', ' ') ||
                          cv_csv_quote;
      ELSIF ( gt_item_attr(i) = cv_item_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(i) ;
      ELSIF ( gt_item_attr(i) = cv_item_attr_date ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(i) ;
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --�A�g�����̒ǉ�
    lv_file_data := lv_file_data || cv_delimit || gt_data_tab(gt_item_name.COUNT + 1);
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    UTL_FILE.PUT_LINE( gv_activ_file_h
                      ,lv_file_data
                     );
    --���������J�E���g
    gn_normal_cnt := NVL(gn_normal_cnt,0) + 1;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      --�t�@�C���N���[�Y�֐�
      IF ( UTL_FILE.IS_OPEN ( gv_activ_file_h )) THEN
        UTL_FILE.FCLOSE( gv_activ_file_h );
      END IF;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00030  -- �t�@�C���ɏ����݂ł��Ȃ�
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : ins_ap_invoice_wait
   * Description      : ���A�g�e�[�u���o�^����(A-9)
   ***********************************************************************************/
  PROCEDURE out_ap_check_wait(
     iv_fixedmanual_kbn  IN     VARCHAR2    --   ����蓮�敪
    ,iv_ins_upd_kbn      IN     VARCHAR2    --   �ǉ��X�V�敪
    ,iv_wait_ins_flag    IN     VARCHAR2    --   ���A�g�e�[�u���}���ۃt���O
    ,iv_gl_je_flag       IN     VARCHAR2    --   �d��G���[���R
    ,iv_meaning          IN     VARCHAR2    --   �G���[���e
    ,iov_errbuf          IN OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT    VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT    VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_ap_check_wait'; -- �v���O������
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
--
    --================================================================
    -- ������s�̏ꍇ
    -- A-6�AA-7�ŃG���[�����������ꍇ�A���A�g�e�[�u���ɑ}������
    -- �A���AA-7�ɂĐ��l�`�F�b�N�G���[�����������ꍇ�͑ΏۊO�Ƃ���
    --================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) AND ( iv_wait_ins_flag = cv_flag_y ) THEN
      --�Ώۃf�[�^�����l�������߃G���[�ȊO�̏ꍇ�̂݁A�ȉ��̏������s��
      --==============================================================
      --�d�󖢘A�g�e�[�u���o�^
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_ap_check_wait_coop(
           invoice_payment_id    -- �����x��ID
          ,created_by                 -- �쐬��
          ,creation_date              -- �쐬��
          ,last_updated_by            -- �ŏI�X�V��
          ,last_update_date           -- �ŏI�X�V��
          ,last_update_login          -- �ŏI�X�V���O�C��
          ,request_id                 -- �v��ID
          ,program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                 -- �R���J�����g�E�v���O����ID
          ,program_update_date        -- �v���O�����X�V��
          )
        VALUES (
           gt_data_tab(1)             --�����x��ID
          ,cn_created_by              --�쐬��
          ,cd_creation_date           --�쐬��
          ,cn_last_updated_by         --�ŏI�X�V��
          ,cd_last_update_date        --�ŏI�X�V��
          ,cn_last_update_login       --�ŏI�X�V���O�C��
          ,cn_request_id              --�v��ID
          ,cn_program_application_id  --�v���O�����A�v���P�[�V����ID
          ,cn_program_id              --�v���O����ID
          ,cd_program_update_date     --�v���O�����X�V��
        );
        --���A�g�o�^�����J�E���g
        gn_wait_data_cnt := NVL(gn_wait_data_cnt,0) + 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                         ,cv_msg_cfo_00024           -- �f�[�^�o�^�G���[
                                                         ,cv_tkn_table               -- �g�[�N��'TABLE'
                                                         ,cv_msgtkn_cfo_11102        -- �`�o�x�����A�g�e�[�u��
                                                         ,cv_tkn_errmsg              -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM                    -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��
    --==============================================================
    -- A-6�̃`�F�b�N�̃G���[
    IF  ( iov_errbuf    = cv_msg_cfo_10007 ) THEN
      -- �d�󂪖��쐬�̏ꍇ
      IF  ( iv_gl_je_flag = cv_gl_je_no_data ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- ���A�g�f�[�^�o�^
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11036             -- �f�k�]���`�F�b�N�G���[
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_check_num        ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(3)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(17)
                                                                              -- �؜ߔԍ�:XXXX�A�������ԍ�:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,cv_msgtkn_cfo_11034             -- �d�󖢍쐬
                                                     )
                             ,1
                             ,5000
                           );
      -- �d�󂪖��]���̏ꍇ
      ELSIF  ( iv_gl_je_flag = cv_gl_je_no_transfer ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- ���A�g�f�[�^�o�^
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11036             -- �f�k�]���`�F�b�N�G���[
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_check_num        ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(3)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(17)
                                                                              -- �؜ߔԍ�:XXXX�A�������ԍ�:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,cv_msgtkn_cfo_11035             -- �d�󖢓]��
                                                     )
                             ,1
                             ,5000
                           );
      END IF;
--
      --������s�̏ꍇ�A�蓮���s�ł��ǉ��̏ꍇ�͏o��(�蓮���s�ōX�V�̏ꍇ��main�ŃG���[�Ƃ��ďo�͂���)
      IF ( iv_fixedmanual_kbn = cv_exec_fixed_period )
         OR (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_0 ))
        THEN
        --���O�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
      --���^�[���l
      iov_errbuf  := lv_errmsg;                            -- ���[�U�[�G���[���b�Z�[�W
      ov_errmsg   := lv_errmsg;                            -- �G���[���b�Z�[�W
--
    END IF;
--
    -- A-7�̃`�F�b�N�G���[
    IF ( iv_gl_je_flag = cv_gl_je_yes_transfer ) THEN
      -- ���l�����G���[�̏ꍇ
      IF  ( iv_wait_ins_flag = cv_flag_n ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo               -- 'XXCFO'
                                                         ,cv_msg_cfo_10011             -- �������߃X�L�b�v���b�Z�[�W
                                                         ,cv_tkn_key_data              -- 'KEY_DATA'
                                                         ,cv_msg_ap_check_num        ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(3)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(17)
                                                                             -- �؜ߔԍ�:XXXX�A�������ԍ�:XXXXX
                                                        )
                               ,1
                               ,5000
                              );
--
      ELSE
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- ���A�g�f�[�^�o�^
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11037             -- ���ڃ`�F�b�N�G���[
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_check_num        ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(3)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(17)
                                                                             -- �؜ߔԍ�:XXXX�A�������ԍ�:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,iv_meaning                      -- ���ʊ֐��̃G���[���b�Z�[�W
                                                       )
                               ,1
                               ,5000
                            );
--
      END IF;
--
      -- ���A�g�f�[�^�`�F�b�N�ɂăG���[�ɂȂ����ꍇ�͍��ڃ`�F�b�N�ŏo�͂��Ă���ׁA�o�͂��Ȃ�
      -- �܂��A���A�g�f�[�^�`�F�b�N�G���[�ɂ��Ă͒�����s�A�蓮���s�Ƃ��x���ŏI������B
      IF ( iov_errbuf = cv_msg_cfo_10010 ) THEN
        NULL;
      ELSE
        --������s�̏ꍇ�A�蓮���s�ł��ǉ��̏ꍇ�͏o��(�蓮���s�ōX�V�̏ꍇ��main�ŃG���[�Ƃ��ďo�͂���)
        IF ( iv_fixedmanual_kbn = cv_exec_fixed_period )
           OR (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_0 ))
          THEN
          --���O�o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
--
        -- �蓮���s�ł��X�V�̏ꍇ�ŁA���A���l�G���[�̏ꍇ�̓X�L�b�v���b�Z�[�W���o�͂���
        IF  (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ))
            AND ( iv_wait_ins_flag = cv_flag_n ) THEN
             --���O�o��
             FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
             );
        END IF;
      END IF;
--
      --���^�[���l
      iov_errbuf  := lv_errmsg;                             -- ���[�U�[�G���[���b�Z�[�W
      ov_errmsg   := lv_errmsg;                             -- �G���[���b�Z�[�W
--
    END IF;
--
  --==============================================================
  --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
  --==============================================================
EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      iov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      iov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      iov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      iov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_ap_check_wait;
--
  /**********************************************************************************
   * Procedure Name   : �Ώۃf�[�^�擾 ����(A-5)
   * Description      : �p�����[�^�ɂ��擾SQL��ύX���A�Ώۂ̂`�o�x�������擾
   *                    A-6�`A-9�̏�����1���R�[�h���A�����B
   ***********************************************************************************/
  PROCEDURE get_ap_check(
     iv_ins_upd_kbn         IN  VARCHAR2                                           -- �ǉ��X�V�敪
    ,it_doc_sequence_val    IN  ap_checks_all.doc_sequence_value%TYPE              -- �؜ߔԍ�
    ,it_invoice_pay_id_fr   IN  ap_invoice_payments_all.invoice_payment_id%TYPE    -- �����x��ID(From)
    ,it_invoice_pay_id_to   IN  ap_invoice_payments_all.invoice_payment_id%TYPE    -- �����x��ID(To)
    ,iv_fixedmanual_kbn     IN  VARCHAR2                                           -- ����蓮�敪
    ,ov_errbuf              OUT VARCHAR2     -- �G���[�E���b�Z�[�W                 --# �Œ� #
    ,ov_retcode             OUT VARCHAR2     -- ���^�[���E�R�[�h                   --# �Œ� #
    ,ov_errmsg              OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W       --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'get_ap_check';                   -- �v���O������
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
    cv_period_flag              CONSTANT VARCHAR2(1)   := 'P';                                -- ���A�g�f�[�^�ȊO
    cv_wait_flag                CONSTANT VARCHAR2(1)   := 'W';                                -- ���A�g�f�[�^
    --�b�r�u�o�̓t�H�[�}�b�g
    cv_date_format_ymdhms       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';   -- �b�r�u�o�̓t�H�[�}�b�g
    cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';           -- �b�r�u�o�̓t�H�[�}�b�g

--
    -- *** ���[�J���ϐ� ***
    lv_gl_je_flag               VARCHAR2(1);    -- �d��֘A�̃��b�Z�[�W�t���O
    lv_wait_ins_flag            VARCHAR2(1);    -- ���A�g�e�[�u���}���ۃt���O
                                                --   (�����G���[��NUMBER�ACHAR�AVARCHAR2�ɂ���ď������Ⴄ��)
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �`�o�x�����f�[�^�擾�J�[�\��
    -- (1) �؜ߔԍ����w�肳��Ă���ꍇ
    CURSOR get_ap_check_num_cur ( lt_doc_sequence_num IN ap_checks_all.doc_sequence_value%TYPE )
    IS
      SELECT
         aip.invoice_payment_id                       AS invoice_payment_id      -- 1.�����x��ID        
        ,ac.check_number                              AS check_number            -- 2.�x�������ԍ�      
        ,ac.doc_sequence_value                        AS doc_sequence_value      -- 3.�؜ߔԍ�          
        ,ac.checkrun_name                             AS checkrun_name           -- 4.�x���o�b�`��      
        ,TO_CHAR(aip.accounting_date,cv_date_format_ymd) AS accounting_date      -- 5.�v���            
        ,pv.segment1                                  AS vendor_code             -- 6.�d����R�[�h      
        ,pv.vendor_name                               AS vendor_name             -- 7.�d���於          
        ,pvs.vendor_site_code                         AS vendor_site_code        -- 8.�d����T�C�g�R�[�h
        ,abb.bank_number                              AS bank_number             -- 9.��s�ԍ�          
        ,abb.bank_name                                AS bank_name               --10.��s��            
        ,abb.bank_num                                 AS bank_branch_number      --11.�x�X�ԍ�          
        ,abb.bank_branch_name                         AS bank_branch_name        --12.�x�X��            
        ,ac.bank_account_num                          AS bank_account_number     --13.�����ԍ�          
        ,ac.bank_account_name                         AS bank_account_name       --14.������            
        ,ac.amount                                    AS amount                  --15.�x�����z          
        ,aip.invoice_id                               AS invoice_id              --16.������ID          
        ,aia.invoice_num                              AS invoice_number          --17.�������ԍ�        
        ,aip.amount                                   AS invoice_amount          --18.���������z        
        ,ac.currency_code                             AS currency_code           --19.�x���ʉ�          
        ,gdct.user_conversion_type                    AS user_conversion_type    --20.���[�g�^�C�v      
        ,TO_CHAR(ac.exchange_date,cv_date_format_ymd) AS exchange_date           --21.���Z��            
        ,ac.exchange_rate                             AS exchange_rate           --22.���Z���[�g        
        ,ac.base_amount                               AS base_amount             --23.�@�\�ʉݐ��������z
        ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)  AS coop_date               --24.�A�g����          
        ,cv_period_flag                               AS data_type               --25.�f�[�^�^�C�v      
      FROM
         ap_checks_all ac                                                        -- 1.�`�o�x��
        ,ap_invoice_payments_all aip                                             -- 2.�`�o�����x��
        ,ap_invoices_all aia                                                     -- 3.�`�o�������w�b�_
        ,ap_bank_accounts_all aba                                                -- 4.��s�����}�X�^
        ,ap_bank_branches abb                                                    -- 5.��s�x�X�}�X�^
        ,gl_daily_conversion_types gdct                                          -- 6.GL���[�g�}�X�^
        ,po_vendors pv                                                           -- 7.�d����}�X�^
        ,po_vendor_sites_all pvs                                                 -- 8.�d����T�C�g�}�X�^
      WHERE ac.check_id            =  aip.check_id                                
      AND   aia.invoice_id         =  aip.invoice_id
      AND   ac.bank_account_id     =  aba.bank_account_id
      AND   aba.bank_branch_id     =  abb.bank_branch_id
      AND   ac.exchange_rate_type  =  gdct.conversion_type (+)
      AND   pv.vendor_id           =  aia.vendor_id
      AND   pvs.vendor_site_id     =  aia.vendor_site_id
      AND   pvs.vendor_id          =  pv.vendor_id
      AND   aia.set_of_books_id    =  gt_gl_set_of_books_id
      AND   aia.org_id             =  ac.org_id
      AND   ac.org_id              =  gt_org_id
      AND   ac.doc_sequence_value  =  lt_doc_sequence_num
      ORDER BY ac.check_id,aip.invoice_payment_id
      ;                                                                               
    --
    -- (2) �����x��ID���w�肳��Ă���ꍇ
    CURSOR get_ap_check_id_cur ( lt_invoice_pay_id_fr IN ap_invoice_payments_all.invoice_payment_id%TYPE,
                                 lt_invoice_pay_id_to IN ap_invoice_payments_all.invoice_payment_id%TYPE )
    IS
      SELECT
         aip.invoice_payment_id                       AS invoice_payment_id      -- 1.�����x��ID        
        ,ac.check_number                              AS check_number            -- 2.�x�������ԍ�      
        ,ac.doc_sequence_value                        AS doc_sequence_value      -- 3.�؜ߔԍ�          
        ,ac.checkrun_name                             AS checkrun_name           -- 4.�x���o�b�`��      
        ,TO_CHAR(aip.accounting_date,cv_date_format_ymd) AS accounting_date       -- 5.�v���            
        ,pv.segment1                                  AS vendor_code             -- 6.�d����R�[�h      
        ,pv.vendor_name                               AS vendor_name             -- 7.�d���於          
        ,pvs.vendor_site_code                         AS vendor_site_code        -- 8.�d����T�C�g�R�[�h
        ,abb.bank_number                              AS bank_number             -- 9.��s�ԍ�          
        ,abb.bank_name                                AS bank_name               --10.��s��            
        ,abb.bank_num                                 AS bank_branch_number      --11.�x�X�ԍ�          
        ,abb.bank_branch_name                         AS bank_branch_name        --12.�x�X��            
        ,ac.bank_account_num                          AS bank_account_number     --13.�����ԍ�          
        ,ac.bank_account_name                         AS bank_account_name       --14.������            
        ,ac.amount                                    AS amount                  --15.�x�����z          
        ,aip.invoice_id                               AS invoice_id              --16.������ID          
        ,aia.invoice_num                              AS invoice_number          --17.�������ԍ�        
        ,aip.amount                                   AS invoice_amount          --18.���������z        
        ,ac.currency_code                             AS currency_code           --19.�x���ʉ�          
        ,gdct.user_conversion_type                    AS user_conversion_type    --20.���[�g�^�C�v      
        ,TO_CHAR(ac.exchange_date,cv_date_format_ymd) AS exchange_date           --21.���Z��            
        ,ac.exchange_rate                             AS exchange_rate           --22.���Z���[�g        
        ,ac.base_amount                               AS base_amount             --23.�@�\�ʉݐ��������z
        ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)  AS coop_date               --24.�A�g����          
        ,cv_period_flag                               AS data_type               --25.�f�[�^�^�C�v      
      FROM
         ap_checks_all ac                                                        -- 1.�`�o�x��
        ,ap_invoice_payments_all aip                                             -- 2.�`�o�����x��
        ,ap_invoices_all aia                                                     -- 3.�`�o�������w�b�_
        ,ap_bank_accounts_all aba                                                -- 4.��s�����}�X�^
        ,ap_bank_branches abb                                                    -- 5.��s�x�X�}�X�^
        ,gl_daily_conversion_types gdct                                          -- 6.GL���[�g�}�X�^
        ,po_vendors pv                                                           -- 7.�d����}�X�^
        ,po_vendor_sites_all pvs                                                 -- 8.�d����T�C�g�}�X�^
      WHERE ac.check_id            =  aip.check_id                                
      AND   aia.invoice_id         =  aip.invoice_id
      AND   ac.bank_account_id     =  aba.bank_account_id
      AND   aba.bank_branch_id     =  abb.bank_branch_id
      AND   ac.exchange_rate_type  =  gdct.conversion_type (+)
      AND   pv.vendor_id           =  aia.vendor_id
      AND   pvs.vendor_site_id     =  aia.vendor_site_id
      AND   pvs.vendor_id          =  pv.vendor_id
      AND   aia.set_of_books_id    =  gt_gl_set_of_books_id
      AND   aia.org_id             =  ac.org_id
      AND   ac.org_id              =  gt_org_id
      AND   aip.invoice_payment_id >= lt_invoice_pay_id_fr
      AND   aip.invoice_payment_id <= lt_invoice_pay_id_to
      ORDER BY ac.check_id,aip.invoice_payment_id
      ;
--
    -- (3) ������s��
    CURSOR get_ap_check_cur( lt_invoice_pay_id_fr IN ap_invoice_payments_all.invoice_payment_id%TYPE,
                             lt_invoice_pay_id_to IN ap_invoice_payments_all.invoice_payment_id%TYPE )
    IS
      SELECT
         invoice_payment_id          -- 1.�����x��ID        
        ,check_number                -- 2.�؜ߔԍ�      
        ,doc_sequence_value          -- 3.�؜ߔԍ�          
        ,checkrun_name               -- 4.�x���o�b�`��      
        ,accounting_date             -- 5.�v���            
        ,vendor_code                 -- 6.�d����R�[�h      
        ,vendor_name                 -- 7.�d���於          
        ,vendor_site_code            -- 8.�d����T�C�g�R�[�h
        ,bank_number                 -- 9.��s�ԍ�          
        ,bank_name                   --10.��s��            
        ,bank_branch_number          --11.�x�X�ԍ�          
        ,bank_branch_name            --12.�x�X��            
        ,bank_account_number         --13.�����ԍ�          
        ,bank_account_name           --14.������            
        ,amount                      --15.�x�����z          
        ,invoice_id                  --16.������ID          
        ,invoice_number              --17.�������ԍ�        
        ,invoice_amount              --18.���������z        
        ,currency_code               --19.�x���ʉ�          
        ,user_conversion_type        --20.���[�g�^�C�v      
        ,exchange_date               --21.���Z��            
        ,exchange_rate               --22.���Z���[�g        
        ,base_amount                 --23.�@�\�ʉݐ��������z
        ,coop_date                   --24.�A�g����          
        ,data_type                   --25.�f�[�^�^�C�v      
      FROM
        (
           SELECT
              aip.invoice_payment_id                       AS invoice_payment_id      -- 1.�����x��ID        
             ,ac.check_number                              AS check_number            -- 2.�x�������ԍ�      
             ,ac.doc_sequence_value                        AS doc_sequence_value      -- 3.�؜ߔԍ�          
             ,ac.checkrun_name                             AS checkrun_name           -- 4.�x���o�b�`��      
             ,TO_CHAR(aip.accounting_date,cv_date_format_ymd) AS accounting_date       -- 5.�v���            
             ,pv.segment1                                  AS vendor_code             -- 6.�d����R�[�h      
             ,pv.vendor_name                               AS vendor_name             -- 7.�d���於          
             ,pvs.vendor_site_code                         AS vendor_site_code        -- 8.�d����T�C�g�R�[�h
             ,abb.bank_number                              AS bank_number             -- 9.��s�ԍ�          
             ,abb.bank_name                                AS bank_name               --10.��s��            
             ,abb.bank_num                                 AS bank_branch_number      --11.�x�X�ԍ�          
             ,abb.bank_branch_name                         AS bank_branch_name        --12.�x�X��            
             ,ac.bank_account_num                          AS bank_account_number     --13.�����ԍ�          
             ,ac.bank_account_name                         AS bank_account_name       --14.������            
             ,ac.amount                                    AS amount                  --15.�x�����z          
             ,aip.invoice_id                               AS invoice_id              --16.������ID          
             ,aia.invoice_num                              AS invoice_number          --17.�������ԍ�        
             ,aip.amount                                   AS invoice_amount          --18.���������z        
             ,ac.currency_code                             AS currency_code           --19.�x���ʉ�          
             ,gdct.user_conversion_type                    AS user_conversion_type    --20.���[�g�^�C�v      
             ,TO_CHAR(ac.exchange_date,cv_date_format_ymd) AS exchange_date           --21.���Z��            
             ,ac.exchange_rate                             AS exchange_rate           --22.���Z���[�g        
             ,ac.base_amount                               AS base_amount             --23.�@�\�ʉݐ��������z
             ,ac.check_id                                  AS check_id                --**.�x��ID(�\�[�g�̈�)
             ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)  AS coop_date               --24.�A�g����          
             ,cv_wait_flag                                 AS data_type               --25.�f�[�^�^�C�v(W:���A�g)
           FROM
              ap_checks_all ac                                                        -- 1.�`�o�x��
             ,ap_invoice_payments_all aip                                             -- 2.�`�o�����x��
             ,ap_invoices_all aia                                                     -- 3.�`�o�������w�b�_
             ,ap_bank_accounts_all aba                                                -- 4.��s�����}�X�^
             ,ap_bank_branches abb                                                    -- 5.��s�x�X�}�X�^
             ,gl_daily_conversion_types gdct                                          -- 6.GL���[�g�}�X�^
             ,po_vendors pv                                                           -- 7.�d����}�X�^
             ,po_vendor_sites_all pvs                                                 -- 8.�d����T�C�g�}�X�^
           WHERE ac.check_id            =  aip.check_id                                
           AND   aia.invoice_id         =  aip.invoice_id
           AND   ac.bank_account_id     =  aba.bank_account_id
           AND   aba.bank_branch_id     =  abb.bank_branch_id
           AND   ac.exchange_rate_type  =  gdct.conversion_type (+)
           AND   pv.vendor_id           =  aia.vendor_id
           AND   pvs.vendor_site_id     =  aia.vendor_site_id
           AND   pvs.vendor_id          =  pv.vendor_id
           AND   aia.set_of_books_id    =  gt_gl_set_of_books_id
           AND   aia.org_id             =  ac.org_id
           AND   ac.org_id              =  gt_org_id
           AND EXISTS                                                    
                ( SELECT 'X'                                             
                  FROM   xxcfo_ap_check_wait_coop xcwc                   
                  WHERE  xcwc.invoice_payment_id = aip.invoice_payment_id
                )
         UNION ALL
           SELECT
              aip.invoice_payment_id                       AS invoice_payment_id      -- 1.�����x��ID        
             ,ac.check_number                              AS check_number            -- 2.�x�������ԍ�      
             ,ac.doc_sequence_value                        AS doc_sequence_value      -- 3.�؜ߔԍ�          
             ,ac.checkrun_name                             AS checkrun_name           -- 4.�x���o�b�`��      
             ,TO_CHAR(aip.accounting_date,cv_date_format_ymd) AS accounting_date      -- 5.�v���            
             ,pv.segment1                                  AS vendor_code             -- 6.�d����R�[�h      
             ,pv.vendor_name                               AS vendor_name             -- 7.�d���於          
             ,pvs.vendor_site_code                         AS vendor_site_code        -- 8.�d����T�C�g�R�[�h
             ,abb.bank_number                              AS bank_number             -- 9.��s�ԍ�          
             ,abb.bank_name                                AS bank_name               --10.��s��            
             ,abb.bank_num                                 AS bank_branch_number      --11.�x�X�ԍ�          
             ,abb.bank_branch_name                         AS bank_branch_name        --12.�x�X��            
             ,ac.bank_account_num                          AS bank_account_number     --13.�����ԍ�          
             ,ac.bank_account_name                         AS bank_account_name       --14.������            
             ,ac.amount                                    AS amount                  --15.�x�����z          
             ,aip.invoice_id                               AS invoice_id              --16.������ID          
             ,aia.invoice_num                              AS invoice_number          --17.�������ԍ�        
             ,aip.amount                                   AS invoice_amount          --18.���������z        
             ,ac.currency_code                             AS currency_code           --19.�x���ʉ�          
             ,gdct.user_conversion_type                    AS user_conversion_type    --20.���[�g�^�C�v      
             ,TO_CHAR(ac.exchange_date,cv_date_format_ymd) AS exchange_date           --21.���Z��            
             ,ac.exchange_rate                             AS exchange_rate           --22.���Z���[�g        
             ,ac.base_amount                               AS base_amount             --23.�@�\�ʉݐ��������z
             ,ac.check_id                                  AS check_id                --**.�x��ID(�\�[�g�̈�)
             ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)  AS coop_date               --24.�A�g����          
             ,cv_period_flag                               AS data_type               --25.�f�[�^�^�C�v      
           FROM
              ap_checks_all ac                                                        -- 1.�`�o�x��
             ,ap_invoice_payments_all aip                                             -- 2.�`�o�����x��
             ,ap_invoices_all aia                                                     -- 3.�`�o�������w�b�_
             ,ap_bank_accounts_all aba                                                -- 4.��s�����}�X�^
             ,ap_bank_branches abb                                                    -- 5.��s�x�X�}�X�^
             ,gl_daily_conversion_types gdct                                          -- 6.GL���[�g�}�X�^
             ,po_vendors pv                                                           -- 7.�d����}�X�^
             ,po_vendor_sites_all pvs                                                 -- 8.�d����T�C�g�}�X�^
           WHERE ac.check_id            =  aip.check_id                                
           AND   aia.invoice_id         =  aip.invoice_id
           AND   ac.bank_account_id     =  aba.bank_account_id
           AND   aba.bank_branch_id     =  abb.bank_branch_id
           AND   ac.exchange_rate_type  =  gdct.conversion_type (+)
           AND   pv.vendor_id           =  aia.vendor_id
           AND   pvs.vendor_site_id     =  aia.vendor_site_id
           AND   pvs.vendor_id          =  pv.vendor_id
           AND   aia.set_of_books_id    =  gt_gl_set_of_books_id
           AND   aia.org_id             =  ac.org_id
           AND   ac.org_id              =  gt_org_id
           AND   aip.invoice_payment_id >  lt_invoice_pay_id_fr
           AND   aip.invoice_payment_id <= lt_invoice_pay_id_to
        )
      ORDER BY check_id,invoice_payment_id
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_gl_je_flag    := NULL;
    lv_wait_ins_flag := NULL;
--
    --==============================================================
    -- 1.�t�@�C���̃I�[�v�������{�B
    --==============================================================
    BEGIN
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gt_file_path        -- �f�B���N�g���p�X
                          , filename     => gv_file_name        -- �t�@�C����
                          , open_mode    => cv_file_mode_w      -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                         );
    EXCEPTION    --
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cfo
                      , iv_name         => cv_msg_cfo_00029
                      );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;  -- �`�o�h�G���[
    END;
--
    --==============================================================
    -- 2.�Ώۂ̂`�o�x�������擾
    --==============================================================
    -- �J�[�\���I�[�v��
    -- (1) �؜ߔԍ������͂���Ă���ꍇ
    IF ( iv_fixedmanual_kbn = cv_exec_manual )
      AND ( it_doc_sequence_val IS NOT NULL ) THEN
      OPEN  get_ap_check_num_cur( it_doc_sequence_val );
      <<get_ap_check_num_loop>>
      LOOP
        FETCH get_ap_check_num_cur INTO
            gt_data_tab(1)  -- 1.�����x��ID        
          , gt_data_tab(2)  -- 2.�x�������ԍ�      
          , gt_data_tab(3)  -- 3.�؜ߔԍ�          
          , gt_data_tab(4)  -- 4.�x���o�b�`��      
          , gt_data_tab(5)  -- 5.�x����            
          , gt_data_tab(6)  -- 6.�d����R�[�h      
          , gt_data_tab(7)  -- 7.�d���於          
          , gt_data_tab(8)  -- 8.�d����T�C�g�R�[�h
          , gt_data_tab(9)  -- 9.��s�ԍ�          
          , gt_data_tab(10) --10.��s��            
          , gt_data_tab(11) --11.�x�X�ԍ�          
          , gt_data_tab(12) --12.�x�X��            
          , gt_data_tab(13) --13.�����ԍ�          
          , gt_data_tab(14) --14.������            
          , gt_data_tab(15) --15.�x�����z          
          , gt_data_tab(16) --16.������ID          
          , gt_data_tab(17) --17.�������ԍ�        
          , gt_data_tab(18) --18.���������z        
          , gt_data_tab(19) --19.�x���ʉ�          
          , gt_data_tab(20) --20.���[�g�^�C�v      
          , gt_data_tab(21) --21.���Z��            
          , gt_data_tab(22) --22.���Z���[�g        
          , gt_data_tab(23) --23.�@�\�ʉݐ��������z
          , gt_data_tab(24) --24.�A�g����          
          , gt_data_tab(25) --25.�f�[�^�^�C�v      
        ;
        EXIT WHEN get_ap_check_num_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL�]���`�F�b�N
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- �d��G���[���R
                         ,ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W
                         ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h
                         ,ov_errmsg     => lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W
        -- A-6.�ŃV�X�e���G���[�����������ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.���ڃ`�F�b�N�iA-6.������I���̏ꍇ���{)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- ����蓮�敪
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                    ,ov_errbuf          => lv_errbuf            -- �G���[�E���b�Z�[�W
                    ,ov_retcode         => lv_retcode           -- ���^�[���E�R�[�h
                    ,ov_errmsg          => lv_errmsg );         -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-7.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.�b�r�u�o�́iA-6�AA-7������I���̏ꍇ)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W
                   ,ov_retcode => lv_retcode            -- ���^�[���E�R�[�h
                   ,ov_errmsg  => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-8.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.���A�g�e�[�u���o�^�����iA-6�AA-7���x���I���̏ꍇ)
        --     ���A�g�}���ۃt���O��'Y'(�}��)�̏ꍇ�ł��蓮���s�ׁ̈A
        --     �}������Ȃ�
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ��PROCEDURE�̃��^�[���l��ݒ�
          -- �蓮�A�X�V�̏ꍇ
          IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
            -- ���l�����I�[�o�[�̏ꍇ�͌x���I��
            IF  ( lv_wait_ins_flag = cv_flag_n ) THEN
              ov_retcode   := cv_status_warn;
            ELSE
              ov_retcode   := cv_status_error;
            END IF;
          ELSE -- �蓮�A�ǉ��̏ꍇ�͌x���I��
            ov_retcode := cv_status_warn;
          END IF;
          out_ap_check_wait(    iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- ����蓮�敪
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- �d��G���[���R
                               ,iv_meaning         => lv_errmsg            -- �G���[���e
                               ,iov_errbuf         => lv_errbuf            -- �G���[���b�Z�[�W
                               ,ov_retcode         => lv_retcode           -- ���^�[���R�[�h
                               ,ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
                              );
          -- A-9.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���l�����I�[�o�[�ȊO�̓G���[�Ƃ��ďI������
        IF ( ov_retcode = cv_status_error ) THEN
          ov_errbuf := lv_errbuf;
          RAISE global_process_expt;
        END IF;
--
        -- �Ώی����i�A�g���j�J�E���g
        gn_target_cnt := NVL(gn_target_cnt,0) + 1;
--
        -- �`�o�x���̃O���[�o���ϐ��̏�����
        gt_data_tab.DELETE;
--
      END LOOP get_invoice_num_loop;
      CLOSE get_ap_check_num_cur;
    END IF;
--
    -- (2) �����x��ID�����͂���Ă���ꍇ
    IF ( iv_fixedmanual_kbn = cv_exec_manual )
      AND ( it_invoice_pay_id_fr IS NOT NULL )
      AND ( it_invoice_pay_id_to IS NOT NULL ) THEN
      OPEN  get_ap_check_id_cur( it_invoice_pay_id_fr, it_invoice_pay_id_to );
      <<get_ap_check_id_loop>>
      LOOP
        FETCH get_ap_check_id_cur INTO
            gt_data_tab(1)  -- 1.�����x��ID        
          , gt_data_tab(2)  -- 2.�x�������ԍ�      
          , gt_data_tab(3)  -- 3.�؜ߔԍ�          
          , gt_data_tab(4)  -- 4.�x���o�b�`��      
          , gt_data_tab(5)  -- 5.�x����            
          , gt_data_tab(6)  -- 6.�d����R�[�h      
          , gt_data_tab(7)  -- 7.�d���於          
          , gt_data_tab(8)  -- 8.�d����T�C�g�R�[�h
          , gt_data_tab(9)  -- 9.��s�ԍ�          
          , gt_data_tab(10) --10.��s��            
          , gt_data_tab(11) --11.�x�X�ԍ�          
          , gt_data_tab(12) --12.�x�X��            
          , gt_data_tab(13) --13.�����ԍ�          
          , gt_data_tab(14) --14.������            
          , gt_data_tab(15) --15.�x�����z          
          , gt_data_tab(16) --16.������ID          
          , gt_data_tab(17) --17.�������ԍ�        
          , gt_data_tab(18) --18.���������z        
          , gt_data_tab(19) --19.�x���ʉ�          
          , gt_data_tab(20) --20.���[�g�^�C�v      
          , gt_data_tab(21) --21.���Z��            
          , gt_data_tab(22) --22.���Z���[�g        
          , gt_data_tab(23) --23.�@�\�ʉݐ��������z
          , gt_data_tab(24) --24.�A�g����          
          , gt_data_tab(25) --25.�f�[�^�^�C�v      
        ;
        EXIT WHEN get_ap_check_id_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL�]���`�F�b�N
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- �d��G���[���R
                         ,ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W
                         ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h
                         ,ov_errmsg     => lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W
        -- A-6.�ŃV�X�e���G���[�����������ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.���ڃ`�F�b�N�iA-6.������I���̏ꍇ���{)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- ����蓮�敪
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                    ,ov_errbuf          => lv_errbuf            -- �G���[�E���b�Z�[�W
                    ,ov_retcode         => lv_retcode           -- ���^�[���E�R�[�h
                    ,ov_errmsg          => lv_errmsg );         -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-7.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.�b�r�u�o�́iA-6�AA-7������I���̏ꍇ)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W
                   ,ov_retcode => lv_retcode            -- ���^�[���E�R�[�h
                   ,ov_errmsg  => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-8.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.���A�g�e�[�u���o�^�����iA-6�AA-7���x���I���̏ꍇ)
        --     ���A�g�}���ۃt���O��'Y'(�}��)�̏ꍇ�ł��蓮���s�ׁ̈A
        --     �}������Ȃ�
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ��PROCEDURE�̃��^�[���l��ݒ�
          -- �蓮�A�X�V�̏ꍇ
          IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
            -- ���l�����I�[�o�[�ȊO�̏ꍇ�̓G���[�I��
            IF  ( lv_wait_ins_flag = cv_flag_n ) THEN
              ov_retcode   := cv_status_warn;
            ELSE
              ov_retcode   := cv_status_error;
            END IF;
          ELSE -- �蓮�A�ǉ��̏ꍇ�͌x���I��
            ov_retcode := cv_status_warn;
          END IF;
          out_ap_check_wait(  iv_fixedmanual_kbn   => iv_fixedmanual_kbn   -- ����蓮�敪
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- �d��G���[���R
                               ,iv_meaning         => lv_errmsg            -- �G���[���e
                               ,iov_errbuf         => lv_errbuf            -- �G���[���b�Z�[�W
                               ,ov_retcode         => lv_retcode           -- ���^�[���R�[�h
                               ,ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
                              );
          -- A-9.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���l�����I�[�o�[�ȊO�̓G���[�Ƃ��ďI������
        IF ( ov_retcode = cv_status_error ) THEN
          ov_errbuf := lv_errbuf;
          RAISE global_process_expt;
        END IF;
--
        -- �Ώی����i�A�g���j�J�E���g
        gn_target_cnt := NVL(gn_target_cnt,0) + 1;
--
        -- �`�o�x���̃O���[�o���ϐ��̏�����
        gt_data_tab.DELETE;
--
      END LOOP get_ap_check_id_loop;
      CLOSE get_ap_check_id_cur;
    END IF;
--
    -- (3) ������s��
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      OPEN  get_ap_check_cur( it_invoice_pay_id_fr, it_invoice_pay_id_to );
      <<get_ap_check_loop>>
      LOOP
        FETCH get_ap_check_cur INTO
            gt_data_tab(1)  -- 1.�����x��ID        
          , gt_data_tab(2)  -- 2.�x�������ԍ�      
          , gt_data_tab(3)  -- 3.�؜ߔԍ�          
          , gt_data_tab(4)  -- 4.�x���o�b�`��      
          , gt_data_tab(5)  -- 5.�x����            
          , gt_data_tab(6)  -- 6.�d����R�[�h      
          , gt_data_tab(7)  -- 7.�d���於          
          , gt_data_tab(8)  -- 8.�d����T�C�g�R�[�h
          , gt_data_tab(9)  -- 9.��s�ԍ�          
          , gt_data_tab(10) --10.��s��            
          , gt_data_tab(11) --11.�x�X�ԍ�          
          , gt_data_tab(12) --12.�x�X��            
          , gt_data_tab(13) --13.�����ԍ�          
          , gt_data_tab(14) --14.������            
          , gt_data_tab(15) --15.�x�����z          
          , gt_data_tab(16) --16.������ID          
          , gt_data_tab(17) --17.�������ԍ�        
          , gt_data_tab(18) --18.���������z        
          , gt_data_tab(19) --19.�x���ʉ�          
          , gt_data_tab(20) --20.���[�g�^�C�v      
          , gt_data_tab(21) --21.���Z��            
          , gt_data_tab(22) --22.���Z���[�g        
          , gt_data_tab(23) --23.�@�\�ʉݐ��������z
          , gt_data_tab(24) --24.�A�g����          
          , gt_data_tab(25) --25.�f�[�^�^�C�v      
        ;
        EXIT WHEN get_ap_check_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL�]���`�F�b�N
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- �d��G���[���R
                         ,ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W
                         ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h
                         ,ov_errmsg     => lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W
        -- A-6.�ŃV�X�e���G���[�����������ꍇ
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.���ڃ`�F�b�N�iA-6.������I���̏ꍇ���{)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- ����蓮�敪
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                    ,ov_errbuf          => lv_errbuf            -- �G���[�E���b�Z�[�W
                    ,ov_retcode         => lv_retcode           -- ���^�[���E�R�[�h
                    ,ov_errmsg          => lv_errmsg );         -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-7.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.�b�r�u�o�́iA-6�AA-7������I���̏ꍇ)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W
                   ,ov_retcode => lv_retcode            -- ���^�[���E�R�[�h
                   ,ov_errmsg  => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- A-8.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.���A�g�e�[�u���o�^�����iA-6�AA-7���x���I���̏ꍇ)
        --     ���A�g�}���ۃt���O��'Y'(�}��)�̏ꍇ�ł��蓮���s�ׁ̈A
        --     �}������Ȃ�
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ��PROCEDURE�̃��^�[���l��ݒ�
          ov_retcode   := cv_status_warn;
          out_ap_check_wait(    iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- ����蓮�敪
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- �ǉ��X�V�敪
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- ���A�g�e�[�u���}���ۃt���O
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- �d��G���[���R
                               ,iv_meaning         => lv_errmsg            -- �G���[���e
                               ,iov_errbuf         => lv_errbuf            -- �G���[���b�Z�[�W
                               ,ov_retcode         => lv_retcode           -- ���^�[���R�[�h
                               ,ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
                              );
          -- A-9.�ŃG���[�����������ꍇ
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- �Ώی����i�A�g���j�J�E���g
        IF ( gt_data_tab(25) = cv_period_flag ) THEN
          gn_target_cnt := NVL(gn_target_cnt,0) + 1;
        -- �Ώی����i���A�g�������j�J�E���g
        ELSE
          gn_target_wait_cnt := NVL(gn_target_wait_cnt,0) + 1;
        END IF;
--
        -- �`�o�x���̃O���[�o���ϐ��̏�����
        gt_data_tab.DELETE;
--
      END LOOP get_ap_check_loop;
      CLOSE get_ap_check_cur;
    END IF;
--
    --==================================================================
    -- 0���̏ꍇ�̓��b�Z�[�W�o��
    --==================================================================
    IF ( NVL(gn_target_cnt,0) +  NVL(gn_target_wait_cnt,0) ) = 0 THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                      ,cv_tkn_get_data       -- �g�[�N��'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11103   -- �`�o�x�����
                                                     )
                            ,1
                            ,5000
                          );
      --���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --���^�[���l
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF get_ap_check_num_cur%ISOPEN THEN
        CLOSE get_ap_check_num_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ap_check_id_cur%ISOPEN THEN
        CLOSE get_ap_check_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ap_check_cur%ISOPEN THEN
        CLOSE get_ap_check_cur;
      END IF;
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
      -- �J�[�\���N���[�Y
      IF get_ap_check_num_cur%ISOPEN THEN
        CLOSE get_ap_check_num_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ap_check_id_cur%ISOPEN THEN
        CLOSE get_ap_check_id_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF get_ap_check_cur%ISOPEN THEN
        CLOSE get_ap_check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ap_check;
--
  /**********************************************************************************
   * Procedure Name   : del_ap_check_wait
   * Description      : ���A�g�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_ap_check_wait(
     iv_fixedmanual_kbn  IN  VARCHAR2     --   ����蓮�敪
    ,ov_errbuf           OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ap_check_wait'; -- �v���O������
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
    --==================================================================
    -- ���A�g�e�[�u�����폜����
    --==================================================================
    --A-2�Ŏ擾�������A�g�f�[�^�������ɁA�폜���s��
    IF  ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      <<delete_loop>>
      FOR i IN 1 .. gt_ap_check_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_ap_check_wait_coop xcwc --�d�󖢘A�g
          WHERE xcwc.rowid = gt_ap_check_wait_tab( i ).rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo              -- XXCFO
                                                           ,cv_msg_cfo_00025            -- �f�[�^�폜�G���[
                                                           ,cv_tkn_table                -- �g�[�N��'TABLE'
                                                           ,cv_msgtkn_cfo_11102         -- �`�o�x�����A�g
                                                           ,cv_tkn_errmsg               -- �g�[�N��'ERRMSG'
                                                           ,SQLERRM                     -- SQL�G���[���b�Z�[�W
                                                          )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_process_expt;
        END;
      END LOOP;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END del_ap_check_wait;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_ap_check_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE ins_upd_ap_check_control(
     iv_fixedmanual_kbn       IN  VARCHAR2                                            --   ����蓮�敪
    ,ov_errbuf                OUT VARCHAR2     --   �G���[�E���b�Z�[�W                --# �Œ� #
    ,ov_retcode               OUT VARCHAR2     --   ���^�[���E�R�[�h                  --# �Œ� #
    ,ov_errmsg                OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W      --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_ap_check_control'; -- �v���O������
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
    lt_invoice_pay_id      ap_invoice_payments_all.invoice_payment_id%TYPE;     -- �����x��ID
    lt_invoice_pay_id_max  ap_invoice_payments_all.invoice_payment_id%TYPE;     -- �����x��ID(max)
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_pay_id := NULL;
    lt_invoice_pay_id_max := NULL;
--
    -- ������s���̂ݓ����������{
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      --================================================================
      -- �Ǘ��e�[�u���֑}������ۂ̐����x��ID�̍ő�l���擾
      --================================================================
      -- �Ǘ��e�[�u����MAX�l���擾
      SELECT
        MAX(xacc.invoice_payment_id)
      INTO
        lt_invoice_pay_id_max
      FROM xxcfo_ap_check_control xacc;
      -- �Ǘ��e�[�u���֑}������ۂ̐����x��ID�̍ő�l���擾
      SELECT
        MAX(aida.invoice_payment_id)
      INTO
        lt_invoice_pay_id
      FROM  ap_invoice_payments_all aida
      WHERE aida.invoice_payment_id   > lt_invoice_pay_id_max
      AND   aida.creation_date        < gd_process_date + 1 + ( TO_NUMBER( NVL(gt_proc_target_time,0) ) / 24 )
      AND   aida.set_of_books_id      = gt_gl_set_of_books_id
      AND   aida.org_id               = gt_org_id;
--
      --�����x��ID��NULL�̏ꍇ
      IF lt_invoice_pay_id IS NULL THEN
        lt_invoice_pay_id := lt_invoice_pay_id_max;
      END IF;
--
      --================================================================
      -- �Ǘ��e�[�u���փf�[�^�}�������{
      --================================================================
      BEGIN
        INSERT INTO xxcfo_ap_check_control (
            business_date                           --�Ɩ����t
          , invoice_payment_id                      --�����x��ID
          , process_flag                            --�����t���O
          , created_by                              --�쐬��
          , creation_date                           --�쐬��
          , last_updated_by                         --�ŏI�X�V��
          , last_update_date                        --�ŏI�X�V��
          , last_update_login                       --�ŏI�X�V���O�C��
          , request_id                              --�v��ID
          , program_application_id                  --�v���O�����A�v���P�[�V����ID
          , program_id                              --�v���O�����X�V��
          , program_update_date                     --�v���O�����X�V��
        ) VALUES ( 
            gd_process_date                         --�Ɩ����t
          , lt_invoice_pay_id                       --�����x��ID
          , cv_flag_n                               --�����t���O
          , cn_created_by                           --�쐬��
          , cd_creation_date                        --�쐬��
          , cn_last_updated_by                      --�ŏI�X�V��
          , cd_last_update_date                     --�ŏI�X�V��
          , cn_last_update_login                    --�ŏI�X�V���O�C��
          , cn_request_id                           --�v��ID
          , cn_program_application_id               --�v���O�����A�v���P�[�V����ID
          , cn_program_id                           --�v���O����ID
          , cd_program_update_date                  --�v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
         lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                        ,cv_msg_cfo_00024           -- �f�[�^�o�^�G���[
                                                        ,cv_tkn_table               -- �g�[�N��'TABLE'
                                                        ,cv_msgtkn_cfo_11101        -- �`�o�x���Ǘ��e�[�u��
                                                        ,cv_tkn_errmsg              -- �g�[�N��'ERRMSG'
                                                        ,SQLERRM                    -- SQL�G���[���b�Z�[�W
                                                       )
                              ,1
                              ,5000);
         lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
         RAISE global_process_expt;
      END;
--
      --================================================================
      -- �Ǘ��e�[�u���X�V����
      --================================================================
      -- �擾�����Ǘ��f�[�^�������A�d�q���돈�����s�����������ꍇ�̂ݎ��{
      IF ( gt_ap_check_ctl_tab.COUNT >= TO_NUMBER( gt_electric_exec_days ) ) THEN
        <<ap_invoice_ctl_upd_loop>>
        FOR i IN gt_electric_exec_days..gt_ap_check_ctl_tab.COUNT LOOP
          BEGIN
            UPDATE xxcfo_ap_check_control xacc
            SET xacc.process_flag           = cv_flag_y                 -- �����σt���O
               ,xacc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
               ,xacc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
               ,xacc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
               ,xacc.request_id             = cn_request_id             -- �v��ID
               ,xacc.program_application_id = cn_program_application_id -- �v���O�����A�v���P�[�V����ID
               ,xacc.program_id             = cn_program_id             -- �v���O����ID
               ,xacc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
            WHERE  xacc.ROWID               = gt_ap_check_ctl_tab(i).ROWID;  -- ROWID
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo           -- XXCFO
                                                             ,cv_msg_cfo_00020         -- �f�[�^�o�^�G���[
                                                             ,cv_tkn_table             -- �g�[�N��'TABLE'
                                                             ,cv_msgtkn_cfo_11101      -- �`�o�x���Ǘ��e�[�u��
                                                             ,cv_tkn_errmsg            -- �g�[�N��'ERRMSG'
                                                             ,SQLERRM                  -- SQL�G���[���b�Z�[�W
                                                            )
                                   ,1
                                   ,5000);
              lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
              RAISE global_process_expt;
          END;
        END LOOP;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_upd_ap_check_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_ins_upd_kbn        IN  VARCHAR2                                       -- �ǉ��X�V�敪
    ,iv_file_name          IN  VARCHAR2                                       -- �t�@�C����
    ,it_doc_sequence_val   IN  ap_checks_all.doc_sequence_value%TYPE          -- �؜ߔԍ�
    ,it_invoice_pay_id_fr  IN  ap_invoice_payments_all.invoice_payment_id%TYPE-- �����x��ID(From)
    ,it_invoice_pay_id_to  IN  ap_invoice_payments_all.invoice_payment_id%TYPE-- �����x��ID(To)
    ,iv_fixedmanual_kbn    IN  VARCHAR2                                       -- ����蓮�敪
    ,ov_file_cre_flag      OUT VARCHAR2                                       -- �G���[����0byte�t�@�C���쐬�t���O
    ,ov_errbuf             OUT VARCHAR2  -- �G���[�E���b�Z�[�W                --# �Œ� #
    ,ov_retcode            OUT VARCHAR2  -- ���^�[���E�R�[�h                  --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W      --# �Œ� #
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
    lt_invoice_pay_id_max  ap_invoice_payments_all.invoice_payment_id%TYPE;
                                                                   -- �蓮���s���̎x���f�[�^�Ώۃ`�F�b�N�����Ɏg�p
    lt_invoice_pay_id_fr   ap_invoice_payments_all.invoice_payment_id%TYPE;
    lt_invoice_pay_id_to   ap_invoice_payments_all.invoice_payment_id%TYPE;
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_pay_id_max := NULL;
    lt_invoice_pay_id_fr  := NULL;
    lt_invoice_pay_id_to  := NULL;
--
    -- �G���[����0byte�t�@�C���쐬�t���O��'N'�ɂ���
    ov_file_cre_flag := cv_flag_n;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    gn_target_wait_cnt    := 0;
    gn_wait_data_cnt      := 0;
    gd_process_date       := NULL;
    gd_coop_date          := NULL;
    gt_electric_exec_days := NULL;
    gt_proc_target_time   := NULL;
    gt_gl_set_of_books_id := NULL;
    gt_org_id             := NULL;
    gv_activ_file_h       := NULL;
    gv_file_name          := NULL;
    gt_file_path          := NULL;
    gt_directory_path     := NULL;
    gt_data_tab.DELETE;
    gt_item_name.DELETE;
    gt_item_len.DELETE;
    gt_item_decimal.DELETE;
    gt_item_nullflg.DELETE;
    gt_item_attr.DELETE;
    gt_item_cutflg.DELETE;
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_ins_upd_kbn        => iv_ins_upd_kbn            -- �ǉ��X�V�敪
      ,iv_file_name          => iv_file_name              -- �t�@�C����
      ,it_doc_sequence_val   => it_doc_sequence_val       -- �؜ߔԍ�
      ,it_invoice_pay_id_fr  => it_invoice_pay_id_fr      -- �����x��ID(From)
      ,it_invoice_pay_id_to  => it_invoice_pay_id_to      -- �����x��ID(To)
      ,iv_fixedmanual_kbn    => iv_fixedmanual_kbn        -- ����蓮�敪
      ,ov_errbuf             => lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte�쐬�t���O��'N'�ɂ���
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_ap_check_wait(
       ov_errbuf             => lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte�쐬�t���O��'N'�ɂ���
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �`�o�x���Ǘ��e�[�u���擾����(A-3)
    -- ===============================
    get_ap_check_control(
       iv_fixedmanual_kbn    => iv_fixedmanual_kbn        -- ����蓮�敪
      ,ot_invoice_pay_id_fr  => lt_invoice_pay_id_fr      -- �����x��ID_fr
      ,ot_invoice_pay_id_to  => lt_invoice_pay_id_to      -- �����x��ID_to
      ,ot_invoice_pay_id_max => lt_invoice_pay_id_max     -- �����x��ID_max
      ,ov_errbuf             => lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte�쐬�t���O��'N'�ɂ���
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;   --�x���ł���Όx���ێ�
    END IF;
    -- �蓮���s�̏ꍇ�́A�����x��ID���㏑������
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
      lt_invoice_pay_id_fr := it_invoice_pay_id_fr;
      lt_invoice_pay_id_to := it_invoice_pay_id_to;
    END IF;
--
    -- ===============================
    -- �x���f�[�^�Ώۃ`�F�b�N����(A-4)
    -- ===============================
    chk_check_target(
       iv_ins_upd_kbn          => iv_ins_upd_kbn          -- �ǉ��X�V�敪
      ,it_doc_sequence_val     => it_doc_sequence_val     -- �؜ߔԍ�
      ,it_invoice_pay_id_to    => lt_invoice_pay_id_to    -- �����x��ID(To)
      ,iv_fixedmanual_kbn      => iv_fixedmanual_kbn      -- ����蓮�敪
      ,it_invoice_pay_id_max   => lt_invoice_pay_id_max   -- �����x��ID(MAX�l)
      ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W          --# �Œ� #
      ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h            --# �Œ� #
      ,ov_errmsg               => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte�쐬�t���O��'Y'�ɂ���
      gn_target_cnt := 1;             --�Ώی�����1���Z�b�g
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^�擾����(A-5)
    -- ===============================
    get_ap_check(
        iv_ins_upd_kbn         => iv_ins_upd_kbn          -- �ǉ��X�V�敪
       ,it_doc_sequence_val    => it_doc_sequence_val     -- �؜ߔԍ�
       ,it_invoice_pay_id_fr   => lt_invoice_pay_id_fr    -- �����x��ID(From)
       ,it_invoice_pay_id_to   => lt_invoice_pay_id_to    -- �����x��ID(To)
       ,iv_fixedmanual_kbn     => iv_fixedmanual_kbn      -- ����蓮�敪
       ,ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg              => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte�쐬�t���O��'Y'�ɂ���
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;   -- �x���ł���Όx���ێ�
    END IF;
--
    -- ===============================
    -- ���A�g�e�[�u���폜����(A-10)
    -- ===============================
    del_ap_check_wait(
       iv_fixedmanual_kbn      => iv_fixedmanual_kbn      -- ����蓮�敪
      ,ov_errbuf               => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode              => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg               => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte�쐬�t���O��'Y'�ɂ���
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-11)
    -- ===============================
    ins_upd_ap_check_control(
       iv_fixedmanual_kbn       => iv_fixedmanual_kbn     -- ����蓮�敪
      ,ov_errbuf                => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode               => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte�쐬�t���O��'Y'�ɂ���
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W          --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h            --# �Œ� #
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- �ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2,                                       -- �t�@�C����
    it_doc_sequence_val   IN  ap_checks_all.doc_sequence_value%TYPE,          -- �؜ߔԍ�
    it_invoice_pay_id_fr  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- �����x��ID(From)
    it_invoice_pay_id_to  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- �����x��ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- ����蓮�敪
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
    lv_file_cre_flag   VARCHAR2(1);     -- �G���[��0btye�t�@�C���쐬�t���O
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
    -- ���[�J���ϐ��̏�����
    lv_errbuf        := NULL;
    lv_errmsg        := NULL;
    lv_message_code  := NULL;
    lv_file_cre_flag := NULL;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_ins_upd_kbn,         -- �ǉ��X�V�敪
      iv_file_name,           -- �t�@�C����
      it_doc_sequence_val,    -- �؜ߔԍ�
      it_invoice_pay_id_fr,   -- �����x��ID(From)
      it_invoice_pay_id_to,   -- �����x��ID(To)
      iv_fixedmanual_kbn,     -- ����蓮�敪
      lv_file_cre_flag,       -- �G���[��0Byte�t�@�C���쐬�t���O
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[���̌������Z�b�g����
    IF ( lv_retcode = cv_status_error ) THEN
      --�Ώی����o��(�A�g��)
      gn_target_cnt := 0;
      --�Ώی����o��(���A�g������)
      gn_target_wait_cnt := 0;
      --���A�g����
      gn_wait_data_cnt := 0;
      --��������
      gn_normal_cnt := 0;
      --�G���[�o�͌���
      gn_error_cnt  := 1;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ====================================================
    -- 1.�t�@�C���N���[�Y
    -- ====================================================
    -- �t�@�C�����I�[�v������Ă���ꍇ�̓N���[�Y����
    IF ( UTL_FILE.IS_OPEN ( gv_activ_file_h )) THEN
      UTL_FILE.FCLOSE( gv_activ_file_h );
    END IF;
--
    --==========================================================================
    -- 2.[�蓮���s]���AA-4�ȍ~�̏����ŃG���[���������Ă����ꍇ�A
    -- �t�@�C���̍ăI�[�v�����N���[�Y���s���A0byte�t�@�C�����쐬
    --==========================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND ( lv_file_cre_flag = cv_flag_y ) THEN
      BEGIN
        gv_activ_file_h := UTL_FILE.FOPEN(
                              location     => gt_file_path        -- �f�B���N�g���p�X
                            , filename     => gv_file_name        -- �t�@�C����
                            , open_mode    => cv_file_mode_w      -- �I�[�v�����[�h
                            , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                            );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                       )
                                                       ,1
                                                       ,5000);
          lv_errbuf := lv_errmsg;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
          RAISE global_api_others_expt;
      END;
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gv_activ_file_h );
--
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��(�A�g��)
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
    --�Ώی����o��(���A�g������)
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
END XXCFO019A05C;
/
