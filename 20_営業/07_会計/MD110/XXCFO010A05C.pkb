CREATE OR REPLACE PACKAGE BODY APPS.XXCFO010A05C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCFO010A05C
 * Description     : EBS�d�󒊏o
 * MD.050          : T_MD050_CFO_010_A05_EBS�d�󒊏o_EBS�R���J�����g
 * Version         : 1.7
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  to_csv_string       CSV�t�@�C���p������ϊ�
 *  init                ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
 *  data_outbound_proc1 GL�d��f�[�^�̒��o�E�t�@�C���o�͏���            (A-2 �` A-4-1)
 *  upd_oic_journal_h   OIC�d��Ǘ��w�b�_�e�[�u���X�V����               (A-4-2)
 *  file_close_proc     �t�@�C���N���[�Y����                            (����)
 *  submain             ���C�������v���V�[�W��
 *  main                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2023-01-11    1.0   T.Okuyama     ����쐬
 *  2023-01-25    1.1   T.Mizutani    �t�@�C�������Ή�
 *  2023-03-01    1.2   Y.Ooyama      �ڍs�ۑ�No.44�Ή�
 *  2023-03-07    1.3   Y.Ooyama      �V�i���I�e�X�g�s�No.0063�Ή�
 *  2023-03-17    1.4   Y.Ooyama      �V�i���I�e�X�g�s�No.0090�Ή�
 *  2023-05-10    1.5   S.Yoshioka    �J���c�ۑ�07�Ή�
 *  2023-08-01    1.6   Y.Ryu         E_�{�ғ�_19360�y��v�zERP���|�Ǘ��d��]�L�����̉��P�Ή�
 *  2023-11-15    1.7   Y.Ooyama      E_�{�ғ�_19496 �O���[�v��Г����Ή�
 ************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_slash     CONSTANT VARCHAR2(3) := '/';
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
  gn_target_cnt    NUMBER;                    -- �Ώی����i�����j
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --*** ���b�N(�r�W�[)�G���[��O ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,         -54);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFO010A05C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmm     CONSTANT VARCHAR2(5)   := 'XXCMM';        -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';        -- �A�h�I���F�̕��E�݌ɗ̈�̃A�v���P�[�V�����Z�k��
--
-- Ver1.2 Del Start
--  cv_group_id1       CONSTANT VARCHAR2(5)   := '1001';               -- Receivables�i���|�Ǘ��j�O���[�vID1
--  cv_group_id2       CONSTANT VARCHAR2(5)   := '1002';               -- Receivables�i���|�Ǘ��j�O���[�vID2
--  cv_group_id3       CONSTANT VARCHAR2(5)   := '1003';               -- Receivables�i���|�Ǘ��j�O���[�vID3
--  cv_group_id4       CONSTANT VARCHAR2(5)   := '1004';               -- Receivables�i���|�Ǘ��j�O���[�vID4
--  cv_group_id5       CONSTANT VARCHAR2(5)   := '1005';               -- Receivables�i���|�Ǘ��j�O���[�vID5
-- Ver1.2 Del End
--
  cv_receivables     CONSTANT VARCHAR2(20) := 'Receivables';         -- �t�@�C�������Ώۂ̎d��\�[�X���i���|�Ǘ��j
  cv_execute_kbn_n   CONSTANT VARCHAR2(20) := 'N';                   -- ���s�敪 = 'N':���
  cv_execute_kbn_d   CONSTANT VARCHAR2(20) := 'D';                   -- ���s�敪 = 'D':�莞
  cv_ebs_journal     CONSTANT VARCHAR2(20) := '1';                   -- �A�g�p�^�[��   = '1':EBS�d�󒊏o
  cv_books_status    CONSTANT VARCHAR2(20) := 'P';                   -- �d��X�e�[�^�X = 'P':�]�L��
  cv_status_code     CONSTANT VARCHAR2(20) := 'NEW';                 -- �t�@�C���o�͌Œ�l�FStatus Code
  cv_je_source_ast   CONSTANT VARCHAR2(20) := 'Assets';              -- �d��\�[�X�F���Y�Ǘ�
  cv_je_source_inv   CONSTANT VARCHAR2(20) := 'Inventory';           -- �d��\�[�X�F�݌ɊǗ�
-- Ver1.1 Add Start
  cv_sales_sob       CONSTANT VARCHAR2(20) := 'SALES-SOB';           -- SALES��v���떼
  -- �O���[�vID
  cn_init_group_id   CONSTANT NUMBER       := 1000;                  -- �O���[�vID�����l
  -- �t�@�C�����p�萔
  cv_extension       CONSTANT VARCHAR2(10) := '.csv';                -- �t�@�C���������̊g���q
  cv_fmt_fileno      CONSTANT VARCHAR2(10) := 'FM00';                -- �t�@�C���A�ԏ���
-- Ver1.1 Add End
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_coi1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';    -- �f�B���N�g���p�X�擾�G���[
--
  cv_msg_cfo1_00001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';    -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo1_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';    -- ���b�N�G���[���b�Z�[�W
  cv_msg_cfo1_00020  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';    -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo1_00024  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';    -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo1_00027  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';    -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';    -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo1_00030  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';    -- �t�@�C�������݃G���[���b�Z�[�W
--
  cv_msg_cfo1_60001  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60001';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_cfo1_60002  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';    -- IF�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo1_60004  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60004';    -- �����ΏہE�������b�Z�[�W
  cv_msg_cfo1_60005  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60005';    -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  cv_msg_cfo1_60009  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60009';    -- �p�����[�^�K�{�G���[���b�Z�[�W
  cv_msg_cfo1_60010  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60010';    -- �p�����[�^�s���G���[���b�Z�[�W
  cv_msg_cfo1_60011  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60011';    -- OIC�A�g�Ώێd��Y���Ȃ��G���[���b�Z�[�W
  cv_msg_cfo1_60012  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60012';    -- ���A�g_�ŏ��d��w�b�_ID�o�̓��b�Z�[�W
  cv_msg_cfo1_60013  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60013';    -- �g�[�N��(���s�敪)
  cv_msg_cfo1_60014  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60014';    -- �g�[�N��(��v����ID)
  cv_msg_cfo1_60015  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60015';    -- �g�[�N��(�d��\�[�X)
  cv_msg_cfo1_60016  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60016';    -- �g�[�N��(�d��J�e�S��)
  cv_msg_cfo1_60017  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60017';    -- �g�[�N��(OIC�d��Ǘ��w�b�_�e�[�u��)
  cv_msg_cfo1_60018  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60018';    -- �g�[�N��(OIC�d��Ǘ����׃e�[�u��)
  cv_msg_cfo1_60026  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60026';    -- �g�[�N��((EBS�d��)
--
  cv_msg1            CONSTANT VARCHAR2(2)  := '1.';                  -- ���b�Z�[�WNo.
  cv_msg2            CONSTANT VARCHAR2(2)  := '2.';                  -- ���b�Z�[�WNo.
  cv_msg3            CONSTANT VARCHAR2(2)  := '3.';                  -- ���b�Z�[�WNo.
  cv_msg4            CONSTANT VARCHAR2(2)  := '4.';                  -- ���b�Z�[�WNo.
  cv_msg5            CONSTANT VARCHAR2(2)  := '5.';                  -- ���b�Z�[�WNo.
--
  -- �g�[�N��
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';          -- �p�����[�^��
  cv_tkn_param_val   CONSTANT VARCHAR2(20) := 'PARAM_VAL';           -- �p�����[�^�l
  cv_tkn_ng_profile  CONSTANT VARCHAR2(20) := 'PROF_NAME';           -- �v���t�@�C����
  cv_tkn_dir_tok     CONSTANT VARCHAR2(20) := 'DIR_TOK';             -- �f�B���N�g����
  cv_tkn_file_name   CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- �t�@�C����
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- �O�񏈗������iYYYY/MM/DD HH24:MI:SS�j
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- ���񏈗������iYYYY/MM/DD HH24:MI:SS�j
  cv_tkn_target      CONSTANT VARCHAR2(20) := 'TARGET';              -- �����ΏہA�܂��̓t�@�C���o�͑Ώ�
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- ����
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- �e�[�u����
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERRMSG';              -- SQLERRM
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(20) := 'SQLERRM';             -- SQLERRM
  cv_tkn_bookid      CONSTANT VARCHAR2(20) := 'BOOKID';              -- ��v����ID
  cv_tkn_source      CONSTANT VARCHAR2(20) := 'SOURCE';              -- �d��\�[�X
  cv_tkn_category    CONSTANT VARCHAR2(20) := 'CATEGORY';            -- �d��J�e�S��
  cv_tkn_id1         CONSTANT VARCHAR2(20) := 'ID1';                 -- ���A�g_�ŏ��d��w�b�_ID(�����O)
  cv_tkn_id2         CONSTANT VARCHAR2(20) := 'ID2';                 -- ���A�g_�ŏ��d��w�b�_ID(������)
--
  -- �v���t�@�C��
  cv_data_filedir    CONSTANT VARCHAR2(60) := 'XXCFO1_OIC_OUT_FILE_DIR';  -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
-- Ver1.1 Add Start
  cv_div_cnt         CONSTANT VARCHAR2(60) := 'XXCFO1_OIC_DIVCNT_GL_JE';  -- XXCFO:OIC�A�g�����s���iEBS�d��j
-- Ver1.1 Add End
-- Ver1.2 Add Start
  cv_prf_max_h_cnt_per_b   CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_MAX_H_CNT_PER_BATCH'; -- XXCFO:�d��o�b�`������d��w�b�_�����iOIC�A�g�j
-- Ver1.2 Add End
--
  -- ����������
  cv_proc_date_fm    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_ymd        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_comma_edit      CONSTANT VARCHAR2(30) := 'FM999,999,999';
--
  -- ���ݓ����iUTC�j
  cd_utc_date        CONSTANT VARCHAR2(30) := TO_CHAR(SYS_EXTRACT_UTC(CURRENT_TIMESTAMP), cv_date_ymd);
--
-- Ver1.1 Add Start
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �o�̓t�@�C�������̃��R�[�h�^�錾
  TYPE l_out_file_rtype IS RECORD(
      set_of_books_id     NUMBER               -- ����ID
    , je_source           VARCHAR2(25)         -- �d��\�[�X
    , file_name           VARCHAR2(100)        -- �t�@�C����(�A�ԕt��)
    , file_handle         UTL_FILE.FILE_TYPE   -- �t�@�C���n���h��
    , out_cnt             NUMBER               -- �o�͌���
  );
  -- �o�̓t�@�C�������̃e�[�u���^�錾
  TYPE l_out_file_ttype IS TABLE OF l_out_file_rtype INDEX BY BINARY_INTEGER;
-- Ver1.1 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_data_filedir         VARCHAR2(100);                                        -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  gv_file_path            ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- �t�@�C���p�X
  gv_para_exe_kbn         VARCHAR2(150);                                        -- �p�����[�^�F���s�敪
  gv_para_sob             VARCHAR2(150);                                        -- �p�����[�^�F��v����ID
  gv_para_source          VARCHAR2(150);                                        -- �p�����[�^�F�d��\�[�X
  gv_para_category        VARCHAR2(150);                                        -- �p�����[�^�F�d��J�e�S��
  gn_pre_sob_id           gl_je_headers.set_of_books_id%TYPE :=NULL;            -- ��v����ID�i�O��l�j
  gv_pre_source           gl_je_headers.je_source%TYPE       :=NULL;            -- �d��\�[�X�i�O��l�j
  gv_pre_category         gl_je_headers.je_category%TYPE     :=NULL;            -- �d��J�e�S���i�O��l�j
--  gn_pre_header_id        gl_je_headers.je_header_id%TYPE    :=NULL;            -- �d��w�b�_ID�i�O��l�j -- Ver1.4 Del
  gn_pre_min_je_id        gl_je_headers.je_header_id%TYPE    :=NULL;            -- ���A�g_�ŏ��d��w�b�_ID�i�O��l�j
--
  -- �t�@�C���o�͊֘A
-- Ver1.1 Add Start
  l_out_sale_tab          l_out_file_ttype;                                     -- SALES�o�̓t�@�C�����e�[�u���ϐ�
  l_out_ifrs_tab          l_out_file_ttype;                                     -- IFRS�o�̓t�@�C�����e�[�u���ϐ�
  gn_divcnt               NUMBER := 0;                                          -- �t�@�C�������s��
  gv_fl_name_sales        XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- SALES�t�@�C����(�A�ԂȂ��g���q�Ȃ��j
  gv_fl_name_ifrs         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- IFRS�t�@�C����(�A�ԂȂ��g���q�Ȃ��j
-- Ver1.1 Add End
-- Ver1.1 Del Start
--  gf_file_hand_01         UTL_FILE.FILE_TYPE;                                   -- �t�@�C��01�E�n���h��
--  gf_file_hand_02         UTL_FILE.FILE_TYPE;                                   -- �t�@�C��02�E�n���h��
--  gf_file_hand_03         UTL_FILE.FILE_TYPE;                                   -- �t�@�C��03�E�n���h��
--  gf_file_hand_04         UTL_FILE.FILE_TYPE;                                   -- �t�@�C��04�E�n���h��
--  gf_file_hand_05         UTL_FILE.FILE_TYPE;                                   -- �t�@�C��05�E�n���h��
--  gn_cnt_fl_01            NUMBER := 0;                                          -- �t�@�C��01����
--  gn_cnt_fl_02            NUMBER := 0;                                          -- �t�@�C��02����
--  gn_cnt_fl_03            NUMBER := 0;                                          -- �t�@�C��03����
--  gn_cnt_fl_04            NUMBER := 0;                                          -- �t�@�C��04����
--  gn_cnt_fl_05            NUMBER := 0;                                          -- �t�@�C��05����
--  gn_fl_out_c             NUMBER := 0;                                          -- �t�@�C���o�͌���
--  gv_fl_name1             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- ���|�Ǘ�����1�t�@�C����
--  gv_fl_name2             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- ���|�Ǘ�����2�t�@�C����
--  gv_fl_name3             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- ���|�Ǘ�����3�t�@�C����
--  gv_fl_name4             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- ���|�Ǘ�����4�t�@�C����
--  gv_fl_name5             XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- ���|�Ǘ�����5�t�@�C����
-- Ver1.1 Del End
--
-- Ver1.2 Add Start
  gn_max_h_cnt_per_b      NUMBER := 0;                                          -- �d��o�b�`������d��w�b�_����
-- Ver1.2 Add End
--
  cv_open_mode_w          CONSTANT VARCHAR2(1)    := 'w';                       -- �t�@�C���I�[�v�����[�h�i�㏑���j
  cn_max_linesize         CONSTANT BINARY_INTEGER := 32767;                     -- �t�@�C���s�T�C�Y
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ==============================
--
-- Ver1.1 Add Start
  /**********************************************************************************
   * Procedure Name   : open_output_file
   * Description      : �o�̓t�@�C���I�[�v������
   ***********************************************************************************/
  PROCEDURE open_output_file(
    ov_errbuf              OUT VARCHAR2 -- �G���[���b�Z�[�W
   ,ov_retcode             OUT VARCHAR2 -- ���^�[���R�[�h
   ,ov_errmsg              OUT VARCHAR2 -- ���[�U�[�G���[���b�Z�[�W
   ,iv_output_file_name    IN  VARCHAR2 -- �o�̓t�@�C����
   ,of_file_hand           OUT UTL_FILE.FILE_TYPE   -- �t�@�C���E�n���h��
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_output_file'; -- �v���O������
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
--
    lv_msgbuf       VARCHAR2(5000);     -- ���[�U�[�E���b�Z�[�W
     -- �t�@�C���o�͊֘A
    lb_fexists      BOOLEAN;            -- �t�@�C�������݂��邩�ǂ���
    ln_file_size    NUMBER;             -- �t�@�C���̒���
    ln_block_size   NUMBER;             -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- (1)�t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(
      gv_data_filedir,
      iv_output_file_name,
      lb_fexists,
      ln_file_size,
      ln_block_size
    );
--
    -- �O��t�@�C�������݂��Ă���
    IF ( lb_fexists ) THEN
        -- ��s�}��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ''
        );
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                     )
                                                    , 1
                                                    , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
  -- ====================================================
  -- (2)�t�s�k�t�@�C���I�[�v��
  -- ====================================================
    BEGIN
      of_file_hand := UTL_FILE.FOPEN( gv_data_filedir            -- �f�B���N�g���p�X
                                    , iv_output_file_name        -- �t�@�C����
                                    , cv_open_mode_w             -- �I�[�v�����[�h
                                    , cn_max_linesize            -- �t�@�C���s�T�C�Y
                                    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                     , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
                                                     , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                     , SQLERRM             -- SQLERRM�i�t�@�C�����������j
                                                    )
                                                   , 1
                                                   , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                     , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
                                                     , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                     , SQLERRM             -- SQLERRM�i�t�@�C�����I�[�v���ł��Ȃ��j
                                                    )
                                                   , 1
                                                   , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                      , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
                                                      , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                      , SQLERRM             -- SQLERRM�i���̑��j
                                                     )
                                                    , 1
                                                    , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B
    lv_msgbuf := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                                        , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
                                        , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
                                        , iv_token_value1 => gv_file_path || iv_output_file_name   -- OIC�A�g�Ώۂ̃t�@�C����
                                        );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
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
  END open_output_file;
-- Ver1.1 Add End
--
-- Ver1.5 Add Start
  /**********************************************************************************
   * Function Name    : to_csv_string
   * Description      : CSV�t�@�C���p������ϊ�
   ***********************************************************************************/
  FUNCTION to_csv_string(
              iv_string       IN VARCHAR2                   -- �Ώە�����
             ,iv_lf_replace   IN VARCHAR2 DEFAULT NULL      -- LF�u���P��
           )
    RETURN VARCHAR2
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'to_csv_string';
    lv_changed_string   VARCHAR2(3000);           -- �ϊ��㕶����(�߂�l)
  --
  BEGIN
    -- �ϊ��㕶�����������
    lv_changed_string := iv_string;
    -- 
    -- ���ׂĂ�CR���s�R�[�h�uCHAR(13)�v��NULL�ɒu��
    lv_changed_string := REPLACE( lv_changed_string , CHR(13) , NULL );
    --
    -- OIC���ʊ֐���CSV�t�@�C���p������ϊ������{
    RETURN xxccp_oiccommon_pkg.to_csv_string( lv_changed_string , iv_lf_replace );
    --
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END to_csv_string;
--
-- Ver1.5 Add End
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_execute_kbn          IN  VARCHAR2     -- ���s�敪 ���:'N'�A�莞:'D'
    , in_set_of_books_id      IN  NUMBER       -- ��v����ID
    , iv_je_source_name       IN  VARCHAR2     -- �d��\�[�X
    , iv_je_category_name     IN  VARCHAR2     -- �d��J�e�S��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
-- Ver1.1 Del Start
--    cv_extension        CONSTANT VARCHAR2(10)  := '.csv';            -- �t�@�C���������̊g���q
--    cv_div1             CONSTANT VARCHAR2(10)  := '_1001';           -- �t�@�C���������̃O���[�vID
--    cv_div2             CONSTANT VARCHAR2(10)  := '_1002';           -- �t�@�C���������̃O���[�vID
--    cv_div3             CONSTANT VARCHAR2(10)  := '_1003';           -- �t�@�C���������̃O���[�vID
--    cv_div4             CONSTANT VARCHAR2(10)  := '_1004';           -- �t�@�C���������̃O���[�vID
--    cv_div5             CONSTANT VARCHAR2(10)  := '_1005';           -- �t�@�C���������̃O���[�vID
-- Ver1.1 Del End
--
    -- *** ���[�J���ϐ� ***
    ln_cnt              NUMBER;                                           -- ����
    ln_cnt2             NUMBER;                                           -- ����
    lv_msgbuf           VARCHAR2(5000);                                   -- ���[�U�[�E���b�Z�[�W
    lv_msg              VARCHAR(2);                                       -- MSG No.
    lv_fl_name          XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- �t�@�C����
-- Ver1.1 Add Start
    lv_fl_name_noext    XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- �t�@�C�����i�g���q�Ȃ��j
-- Ver1.1 Add End
    lf_file_hand        UTL_FILE.FILE_TYPE;                               -- �t�@�C���E�n���h��
--
    -- �t�@�C���o�͊֘A
    lb_fexists          BOOLEAN;                                     -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                                      -- �t�@�C���̒���
    ln_block_size       NUMBER;                                      -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- OIC�A�g�Ώێd����擾
    CURSOR c_prog_journal_cur IS
      SELECT DISTINCT
             set_of_books_id    AS set_of_books_id   -- ��v����ID
-- Ver1.1 Add Start
           , name               AS name              -- ��v���떼
-- Ver1.1 Add End
           , je_source          AS je_source         -- �d��\�[�X
           , file_name          AS file_name         -- �t�@�C����
      FROM   xxcfo_oic_target_journal                                     -- OIC�A�g�Ώێd��e�[�u��
      WHERE  if_pattern = cv_ebs_journal                                  -- �A�g�p�^�[���iEBS�d�󒊏o�j
      AND    set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- ���̓p�����[�^�u����ID�v
      AND    je_source       = iv_je_source_name                          -- ���̓p�����[�^�u�d��\�[�X�v
      AND    je_category     = NVL(iv_je_category_name, je_category)      -- ���̓p�����[�^�u�d��J�e�S���v
      ORDER BY je_source, file_name desc;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- OIC�A�g�Ώێd��e�[�u�� �J�[�\�����R�[�h�^
    c_journal_rec      c_prog_journal_cur%ROWTYPE;                   -- �o�̓t�@�C�����擾
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
    -- ===================================
    -- A-1-1�D���̓p�����[�^���`�F�b�N����
    -- ===================================
--
    -- (1) ���̓p�����[�^�o��
    -- ===================================================================
    -- 1.���s�敪
    gv_para_exe_kbn := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo     -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60013  -- �p�����[�^���i���s�敪�j
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                    , iv_token_value1 => gv_para_exe_kbn          -- ���s�敪
                    , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                    , iv_token_value2 => iv_execute_kbn           -- �p�����[�^�F���s�敪
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 2.��v����ID
    gv_para_sob := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo      -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60014   -- �p�����[�^���i����ID�j
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001            -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_param_name            -- �g�[�N��(PARAM_NAME)
                    , iv_token_value1 => gv_para_sob                  -- ��v����ID
                    , iv_token_name2  => cv_tkn_param_val             -- �g�[�N��(PARAM_VAL)
                    , iv_token_value2 => TO_CHAR(in_set_of_books_id)  -- �p�����[�^�F����ID
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 3.�d��\�[�X
    gv_para_source := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo     -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60015  -- �p�����[�^���i�d��\�[�X�j
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                    , iv_token_value1 => gv_para_source           -- �d��\�[�X
                    , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                    , iv_token_value2 => iv_je_source_name        -- �p�����[�^�F�d��\�[�X
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- 4.�d��J�e�S��
    gv_para_category := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cfo      -- 'XXCFO'
                         , iv_name         => cv_msg_cfo1_60016   -- �p�����[�^���i�d��\�[�X�j
                        );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                    , iv_token_value1 => gv_para_category         -- �d��J�e�S��
                    , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                    , iv_token_value2 => iv_je_category_name      -- �p�����[�^�F�d��J�e�S��
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- (2) ���̓p�����[�^�̕K�{�`�F�b�N
    -- ===================================================================
    -- ���̓p�����[�^�u���s�敪�v�������͂̏ꍇ�A�ȉ��̗�O�������s���B
    IF ( iv_execute_kbn IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60009  -- �p�����[�^�K�{�G���[
                                                    , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                    , gv_para_exe_kbn    -- ���s�敪
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�d��\�[�X�v�������͂̏ꍇ�A�ȉ��̗�O�������s���B
    IF ( iv_je_source_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60009  -- �p�����[�^�K�{�G���[
                                                    , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                    , gv_para_source     -- �d��\�[�X
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) ���̓p�����[�^�̕s���`�F�b�N
    -- ===================================================================
    -- ���̓p�����[�^�u���s�敪�v��'N', 'D'�ȊO�̏ꍇ�A�ȉ��̗�O�������s���B
    IF ( iv_execute_kbn NOT IN ('N', 'D') ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                    , cv_msg_cfo1_60010  -- �p�����[�^�s���G���[
                                                    , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                    , gv_para_exe_kbn
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (4) ���̓p�����[�^�̑g�ݍ��킹��OIC�A�g�Ώێd��ɑ��݂��邩�̃`�F�b�N
    -- ===================================================================
    SELECT COUNT(1) AS count
    INTO   ln_cnt
    FROM   xxcfo_oic_target_journal xxotj                                     -- OIC�A�g�Ώێd��e�[�u��
    WHERE  xxotj.if_pattern      = cv_ebs_journal                             -- �A�g�p�^�[���iEBS�d�󒊏o�j
    AND    xxotj.set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- ���̓p�����[�^�u����ID�v
    AND    xxotj.je_source       = iv_je_source_name                          -- ���̓p�����[�^�u�d��\�[�X�v
    AND    xxotj.je_category     = NVL(iv_je_category_name, je_category);     -- ���̓p�����[�^�u�d��J�e�S���v
--
    -- �g�ݍ��킹��OIC�A�g�Ώێd��ɑ��݂��Ȃ��ꍇ�A�ȉ��̗�O�������s���B
    IF ( ln_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cfo     -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_cfo1_60011  -- OIC�A�g�Ώێd��Y���Ȃ��G���[�G���[���b�Z�[�W
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-2�D�v���t�@�C���l���擾����
    -- ===============================
--
    -- 1.�v���t�@�C������XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����擾
    -- ===================================================================
    gv_data_filedir := FND_PROFILE.VALUE( cv_data_filedir );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_data_filedir IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                                                     , cv_tkn_ng_profile  -- �g�[�N��'PROF_NAME'
                                                     , cv_data_filedir
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1 Add Start
    -- 2.�v���t�@�C������XXCFO:OIC�A�g�����s���iEBS�d��j�擾
    -- ===================================================================
    BEGIN
      gn_divcnt := TO_NUMBER(FND_PROFILE.VALUE( cv_div_cnt ));
      -- �v���t�@�C���擾�G���[��
      IF ( gn_divcnt IS NULL ) THEN
        RAISE VALUE_ERROR; -- ���L�̗�O�ŏ��������邽��
      END IF;
    EXCEPTION
    -- *** ��O�n���h�� ***
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                                                     , cv_tkn_ng_profile  -- �g�[�N��'PROF_NAME'
                                                     , cv_div_cnt
                                                    )
                                                 , 1
                                                 , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.1 Add End
--
-- Ver1.2 Add Start
    -- 3.XXCFO:�d��o�b�`������d��w�b�_�����iOIC�A�g�j�擾
    -- ===================================================================
    BEGIN
      gn_max_h_cnt_per_b := TO_NUMBER(FND_PROFILE.VALUE( cv_prf_max_h_cnt_per_b ));
      -- �v���t�@�C���擾�G���[��
      IF ( gn_max_h_cnt_per_b IS NULL ) THEN
        RAISE VALUE_ERROR; -- ���L�̗�O�ŏ��������邽��
      END IF;
    EXCEPTION
    -- *** ��O�n���h�� ***
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo     -- 'XXCFO'
                                                     , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                                                     , cv_tkn_ng_profile  -- �g�[�N��'PROF_NAME'
                                                     , cv_prf_max_h_cnt_per_b
                                                    )
                                                 , 1
                                                 , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.2 Add End
--
    -- ====================================================================================================
    -- A-1-3�D�v���t�@�C���l�uXXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v����f�B���N�g���p�X���擾����
    -- ====================================================================================================
    BEGIN
      SELECT RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- �f�B���N�g���p�X
      INTO   gv_file_path
      FROM   all_directories  ad
      WHERE  ad.directory_name = gv_data_filedir;                         -- �v���t�@�C���l�uXXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                                 , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                                                                 , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                                                                 , gv_data_filedir        -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                                                                )
                                                               , 1
                                                               , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
    -- directory_name�͓o�^����Ă��邪�Adirectory_path���󔒂̎�
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                               , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                                                               , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                                                               , gv_data_filedir        -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =================================
    -- A-1-4�D�o�̓t�@�C�����I�[�v������
    -- =================================
    -- (1) ���̓p�����[�^�������ɏo�̓t�@�C������OIC�A�g�Ώێd��e�[�u������擾����B
    -- �t�@�C�������t�@�C���p�X/�t�@�C�����ŏo�͂���
    gv_file_path := gv_file_path || cv_msg_slash;
-- Ver1.1 Add Start
    -- �e��v����̏o�̓t�@�C������������
    gv_fl_name_sales := NULL;
    gv_fl_name_ifrs := NULL;
-- Ver1.1 Add End
--
    <<data1_loop>>
    ln_cnt := 1;
    FOR c_journal_rec IN c_prog_journal_cur LOOP
-- Ver1.1 Add Start
      -- �t�@�C����
      lv_fl_name_noext := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name, cv_extension) -1);
      lv_fl_name  := lv_fl_name_noext || '_' || TO_CHAR(1, cv_fmt_fileno) || cv_extension;
--
-- Ver1.1 Del Start
--      -- (2-2) �t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                                             iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                           , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                           , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                           , iv_token_value1 => gv_file_path || lv_fl_name   -- OIC�A�g�Ώۂ̃t�@�C����
--                                           );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
-- Ver1.1 Del End
--
      open_output_file(ov_errbuf           => lv_errbuf,
                       ov_retcode          => lv_retcode,
                       ov_errmsg           => lv_errmsg,
                       iv_output_file_name => lv_fl_name,
                       of_file_hand        => lf_file_hand
                      );
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_expt;
      END IF;
--
      -- �o�̓t�@�C�����e�[�u���ϐ��ɒl���i�[����B
      -- SALES��v����̏ꍇ
      IF c_journal_rec.name = cv_sales_sob THEN
        l_out_sale_tab(1).set_of_books_id := c_journal_rec.set_of_books_id; -- ����ID
        l_out_sale_tab(1).je_source       := c_journal_rec.je_source;       -- �d��\�[�X
        l_out_sale_tab(1).file_name       := lv_fl_name;                    -- �t�@�C����
        l_out_sale_tab(1).file_handle     := lf_file_hand;                  -- �t�@�C���n���h��
        l_out_sale_tab(1).out_cnt         := 0;                             -- �o�͌���
        gv_fl_name_sales                  := lv_fl_name_noext;              -- �t�@�C����(�A�ԂȂ��g���q�Ȃ��j
      ELSE
      -- IFRS��v����̏ꍇ
        l_out_ifrs_tab(1).set_of_books_id := c_journal_rec.set_of_books_id; -- ����ID
        l_out_ifrs_tab(1).je_source       := c_journal_rec.je_source;       -- �d��\�[�X
        l_out_ifrs_tab(1).file_name       := lv_fl_name;                    -- �t�@�C����
        l_out_ifrs_tab(1).file_handle     := lf_file_hand;                  -- �t�@�C���n���h��
        l_out_ifrs_tab(1).out_cnt         := 0;                             -- �o�͌���
        gv_fl_name_ifrs                   := lv_fl_name_noext;              -- �t�@�C����(�A�ԂȂ��g���q�Ȃ��j
      END IF;
--
      ln_cnt := ln_cnt + 1;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (2-1) �d��\�[�X����'Receivables'�i���|�Ǘ��j�̏ꍇ�A�O���[�vID�i1001, 1002, 1003, 1004, 1005�j�ōו��������t�@�C�����ɂ���B
--      IF ( c_journal_rec.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_n ) THEN       -- �d��\�[�X���i���|�Ǘ��Ŗ�ԁj
--        lv_fl_name  := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name,'.csv') -1);  -- �g���q�Ȃ��̃t�@�C����
--        gv_fl_name1 := lv_fl_name || cv_div1 || cv_extension;                                          -- ���|�Ǘ������t�@�C��1
--        gv_fl_name2 := lv_fl_name || cv_div2 || cv_extension;                                          -- ���|�Ǘ������t�@�C��2
--        gv_fl_name3 := lv_fl_name || cv_div3 || cv_extension;                                          -- ���|�Ǘ������t�@�C��3
--        gv_fl_name4 := lv_fl_name || cv_div4 || cv_extension;                                          -- ���|�Ǘ������t�@�C��4
--        gv_fl_name5 := lv_fl_name || cv_div5 || cv_extension;                                          -- ���|�Ǘ������t�@�C��5
--        gn_fl_out_c := 5;
----
--        -- (2-2) �t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B                                  -- ���|�Ǘ��̕��������T�t�@�C��
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name1  -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name2  -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name3  -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name4  -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || gv_fl_name5  -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
----
--        -- (2-3) ���ɓ���t�@�C�������݂��Ă��Ȃ����A���|�Ǘ��̕����t�@�C�������`�F�b�N���s���B
--        <<data2_loop>>
--        ln_cnt2 := 1;
--        FOR i in 1..5 LOOP
--          CASE WHEN ln_cnt2 = 1 THEN
--                 lv_fl_name := gv_fl_name1;
--               WHEN ln_cnt2 = 2 THEN
--                 lv_fl_name := gv_fl_name2;
--               WHEN ln_cnt2 = 3 THEN
--                 lv_fl_name := gv_fl_name3;
--               WHEN ln_cnt2 = 4 THEN
--                 lv_fl_name := gv_fl_name4;
--               WHEN ln_cnt2 = 5 THEN
--                 lv_fl_name := gv_fl_name5;
--               ELSE
--                 NULL;
--          END CASE;
----
--          UTL_FILE.FGETATTR( gv_data_filedir
--                           , lv_fl_name                                         -- ���|�Ǘ������t�@�C����
--                           , lb_fexists
--                           , ln_file_size
--                           , ln_block_size );
----
--          -- ����t�@�C�����݃G���[���b�Z�[�W
--          IF ( lb_fexists ) THEN
--            -- ��s�}��
--            FND_FILE.PUT_LINE(
--                which  => FND_FILE.OUTPUT
--              , buff   => ''
--            );
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
--                                                         , cv_msg_cfo1_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
--                                                         )
--                                                        , 1
--                                                        , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--          END IF;
----
--          -- (2-4) ���|�Ǘ��̕��������T�t�@�C�����I�[�v������B
--          BEGIN
--            lf_file_hand := UTL_FILE.FOPEN( gv_data_filedir               -- �f�B���N�g���p�X
--                                             , lv_fl_name                 -- �t�@�C����
--                                             , cv_open_mode_w             -- �I�[�v�����[�h
--                                             , cn_max_linesize            -- �t�@�C���s�T�C�Y
--                                             );
----
--            CASE WHEN ln_cnt2 = 1 THEN
--                   gf_file_hand_01 := lf_file_hand;
--                 WHEN ln_cnt2 = 2 THEN
--                   gf_file_hand_02 := lf_file_hand;
--                 WHEN ln_cnt2 = 3 THEN
--                   gf_file_hand_03 := lf_file_hand;
--                 WHEN ln_cnt2 = 4 THEN
--                   gf_file_hand_04 := lf_file_hand;
--                 WHEN ln_cnt2 = 5 THEN
--                   gf_file_hand_05 := lf_file_hand;
--                 ELSE
--                   NULL;
--            END CASE;
----
--          EXCEPTION
--            WHEN UTL_FILE.INVALID_FILENAME THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                           , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                           , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                           , SQLERRM             -- SQLERRM�i�t�@�C�����������j
--                                                          )
--                                                         , 1
--                                                         , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
----
--            WHEN UTL_FILE.INVALID_OPERATION THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                           , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                           , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                           , SQLERRM             -- SQLERRM�i�t�@�C�����I�[�v���ł��Ȃ��j
--                                                          )
--                                                         , 1
--                                                         , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
----
--            WHEN OTHERS THEN
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
--                                                            , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                            , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                            , SQLERRM             -- SQLERRM�i���̑��j
--                                                           )
--                                                          , 1
--                                                          , 5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_process_expt;
--          END;
----
--          ln_cnt2 := ln_cnt2 + 1;
--        END LOOP data2_loop;
----
--      ELSE
--        -- �����t�@�C���ȊO�̃I�[�v������
--        IF ( c_journal_rec.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_d ) THEN       -- �d��\�[�X���i���|�Ǘ��Œ莞�j
--          lv_fl_name  := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name,'.csv') -1);  -- �g���q�Ȃ��̃t�@�C����
--          lv_fl_name  := lv_fl_name || cv_div1 || cv_extension;                                          -- ���|�Ǘ��t�@�C��1
--        ELSE
--          lv_fl_name := c_journal_rec.file_name;                                                         -- ���|�Ǘ��ȊO�̃t�@�C��1
--        END IF;
----
--        -- (2-2) �t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B
--        lv_msgbuf := xxccp_common_pkg.get_msg(
--                                               iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
--                                             , iv_name         => cv_msg_cfo1_60002            -- IF�t�@�C�����o�̓��b�Z�[�W
--                                             , iv_token_name1  => cv_tkn_file_name             -- �g�[�N��(FILE_NAME)
--                                             , iv_token_value1 => gv_file_path || lv_fl_name   -- OIC�A�g�Ώۂ̃t�@�C����
--                                             );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => lv_msgbuf
--        );
----
--        -- (2-3) ���ɓ���t�@�C�������݂��Ă��Ȃ����̃`�F�b�N���s���B
--        UTL_FILE.FGETATTR( gv_data_filedir
--                         , lv_fl_name
--                         , lb_fexists
--                         , ln_file_size
--                         , ln_block_size );
----
--        -- ����t�@�C�����݃G���[���b�Z�[�W
--        IF ( lb_fexists ) THEN
--          -- ��s�}��
--          FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--            , buff   => ''
--          );
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
--                                                       , cv_msg_cfo1_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
--                                                       )
--                                                      , 1
--                                                      , 5000);
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
----
--        -- (2-4) ���|�Ǘ��ȊO�̃t�@�C���I�[�v�����s���B
--        BEGIN
--          lf_file_hand := UTL_FILE.FOPEN( gv_data_filedir            -- �f�B���N�g���p�X
--                                        , lv_fl_name                 -- �t�@�C����
--                                        , cv_open_mode_w             -- �I�[�v�����[�h
--                                        , cn_max_linesize            -- �t�@�C���s�T�C�Y
--                                        );
----
--          CASE WHEN ln_cnt =  1 THEN
--                 gv_fl_name1 := lv_fl_name;
--                 gf_file_hand_01 := lf_file_hand;      -- Journal_SALES or Journal_IFRS
--                 gn_fl_out_c := gn_fl_out_c + 1;
--               WHEN ln_cnt =  2 THEN
--                 gv_fl_name2 := lv_fl_name;
--                 gf_file_hand_02 := lf_file_hand;      -- Journal_IFRS
--                 gn_fl_out_c := gn_fl_out_c + 1;
--              ELSE
--                 NULL;
--          END CASE;
----
--        EXCEPTION
--          WHEN UTL_FILE.INVALID_FILENAME THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                         , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                         , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                         , SQLERRM             -- SQLERRM�i�t�@�C�����������j
--                                                        )
--                                                       , 1
--                                                       , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
----
--          WHEN UTL_FILE.INVALID_OPERATION THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
--                                                         , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                         , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                         , SQLERRM             -- SQLERRM�i�t�@�C�����I�[�v���ł��Ȃ��j
--                                                        )
--                                                       , 1
--                                                       , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
----
--          WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
--                                                          , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                                                          , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
--                                                          , SQLERRM             -- SQLERRM�i���̑��j
--                                                         )
--                                                        , 1
--                                                        , 5000);
--            lv_errbuf := lv_errmsg;
--            RAISE global_process_expt;
--        END;
----
--        ln_cnt := ln_cnt + 1;
--      END IF;
-- Ver1.1 Del End
    END LOOP data1_loop;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_close_proc
   * Description      : �t�@�C���N���[�Y���� (A-5-1)
   ***********************************************************************************/
  PROCEDURE file_close_proc(
      ov_errbuf       OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode      OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg       OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close_proc'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- A-6-1�D���ׂẴt�@�C�����N���[�Y����
    -- =====================================
-- Ver1.1 Add Start
    IF gv_fl_name_sales IS NOT NULL THEN
      <<file_close_loop>>
      FOR i IN 1..l_out_sale_tab.COUNT LOOP
        IF ( UTL_FILE.IS_OPEN ( l_out_sale_tab(i).file_handle ) ) THEN
          UTL_FILE.FCLOSE( l_out_sale_tab(i).file_handle );
        END IF;
      END LOOP file_close_loop;
    END IF;
--
    IF gv_fl_name_ifrs IS NOT NULL THEN
      <<file_close_loop2>>
      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
        IF ( UTL_FILE.IS_OPEN ( l_out_ifrs_tab(i).file_handle ) ) THEN
          UTL_FILE.FCLOSE( l_out_ifrs_tab(i).file_handle );
        END IF;
      END LOOP file_close_loop2;
    END IF;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_01 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_01 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_02 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_02 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_03 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_03 );
--    END IF;
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_04 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_04 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_05 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_05 );
--    END IF;
-- Ver1.1 Del End
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
  END file_close_proc;
--
  /**********************************************************************************
   * Procedure Name   : upd_oic_journal_h
   * Description      : OIC�d��Ǘ��w�b�_�e�[�u���X�V���� (A-4-2)
   ***********************************************************************************/
  PROCEDURE upd_oic_journal_h(
      ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_oic_journal_h'; -- �v���O������
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
    ln_unsent_header_id          gl_je_headers.je_header_id%TYPE;       -- ���A�g_�ŏ��d��w�b�_ID
    lv_msgbuf                    VARCHAR2(5000);                        -- ���[�U�[�E���b�Z�[�W
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
    -- ===============================
    -- (1) �d��w�b�_����V���ȁu���A�g_�ŏ��d��w�b�_ID�v���擾����B
    -- ===============================
    -- A-2�Ŏ擾�����u����ID�v�A�u�d��J�e�S���v�̂����ꂩ���O��l�ƈقȂ�ꍇ
    -- (1) �d��w�b�_����V���ȁu���A�g_�ŏ��d��w�b�_ID�v���擾����B
    SELECT
      MIN(gjh.je_header_id)     AS je_header_id
      INTO ln_unsent_header_id                                    -- ���A�g_�ŏ��d��w�b�_ID
    FROM
      gl_je_headers             gjh                               -- �d��w�b�_
-- Ver1.1 Del Start
--    , xxcfo_oic_journal_mng_l   xxojl                             -- OIC�d��Ǘ����׃e�[�u��
-- Ver1.1 Del End
    WHERE
-- Ver1.4 Mod Start
--        gjh.je_header_id     >= gn_pre_header_id                  -- �d��w�b�_ID�i�O��l�j
        gjh.je_header_id     >= gn_pre_min_je_id                  -- ���A�g_�ŏ��d��w�b�_ID�i�O��l�j
-- Ver1.4 Mod End
    AND gjh.set_of_books_id   = gn_pre_sob_id                     -- ��v����ID�i�O��l�j
    AND gjh.je_source         = gv_pre_source                     -- �d��\�[�X�i�O��l�j
    AND gjh.je_category       = gv_pre_category                   -- �d��J�e�S���i�O��l�j
-- Ver1.4 Add Start
    AND gjh.status           <> cv_books_status                   -- �X�e�[�^�X:�u�]�L�ρv�ȊO
-- Ver1.4 Add End
    AND NOT EXISTS (
            SELECT 1
            FROM   xxcfo_oic_journal_mng_l   xxojl                -- OIC�d��Ǘ����׃e�[�u��
            WHERE  xxojl.set_of_books_id   = gn_pre_sob_id        -- ��v����ID�i�O��l�j
            AND    xxojl.je_source         = gv_pre_source        -- �d��\�[�X�i�O��l�j
            AND    xxojl.je_category       = gv_pre_category      -- �d��J�e�S���i�O��l�j
            AND    xxojl.je_header_id      = gjh.je_header_id     -- �d��w�b�_ID
        )
    ;
--
    -- (2)�u���A�g_�ŏ��d��w�b�_ID�v���擾�ł��Ȃ������ꍇ�A�d��w�b�_�́u�ő�d��w�b�_ID�v���擾����B
    IF ( ln_unsent_header_id IS NULL ) THEN
      SELECT
        MAX(gjh.je_header_id)   AS je_header_id                   -- ���A�g_�d��w�b�_ID
        INTO ln_unsent_header_id
      FROM
        gl_je_headers  gjh                                        -- �d��w�b�_
      ;
    END IF;
--
    -- (3) �����O��̖��A�g_�ŏ��d��w�b�_ID�����b�Z�[�W�o�͂���B
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60012                 -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_bookid                     -- �g�[�N��(BOOKID)
                    , iv_token_value1 => TO_CHAR(gn_pre_sob_id)            -- ��v����ID�i�O��l�j
                    , iv_token_name2  => cv_tkn_source                     -- �g�[�N��(SOURCE)
                    , iv_token_value2 => gv_pre_source                     -- �d��\�[�X�i�O��l�j
                    , iv_token_name3  => cv_tkn_category                   -- �g�[�N��(CATEGORY)
                    , iv_token_value3 => gv_pre_category                   -- �d��J�e�S���i�O��l�j
                    , iv_token_name4  => cv_tkn_id1                        -- �g�[�N��(ID1)
                    , iv_token_value4 => TO_CHAR(gn_pre_min_je_id)         -- ���A�g_�ŏ��d��w�b�_ID(�����O)
                    , iv_token_name5  => cv_tkn_id2                        -- �g�[�N��(ID2)
                    , iv_token_value5 => TO_CHAR(ln_unsent_header_id)      -- ���A�g_�ŏ��d��w�b�_ID(������) 
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- (4)  OIC�d��Ǘ��w�b�_�e�[�u���X�V
    BEGIN
      UPDATE xxcfo_oic_journal_mng_h
      SET    unsent_min_je_header_id = ln_unsent_header_id,         -- ���A�g_�d��w�b�_ID
             last_updated_by         = cn_last_updated_by,          -- �ŏI�X�V��
             last_update_date        = cd_last_update_date,         -- �ŏI�X�V��
             last_update_login       = cn_last_update_login,        -- �ŏI�X�V���O�C��
             request_id              = cn_request_id,               -- �v��ID
             program_application_id  = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             program_id              = cn_program_id,               -- �R���J�����g�E�v���O����ID
             program_update_date     = cd_program_update_date       -- �v���O�����X�V��
      WHERE  set_of_books_id    = gn_pre_sob_id                  -- ��v����ID�i�O��l�j
      AND    je_source          = gv_pre_source                  -- �d��\�[�X�i�O��l�j
      AND    je_category        = gv_pre_category;               -- �d��J�e�S���i�O��l�j
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�X�V�G���[
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo        -- 'XXCFO'
                                                      , cv_msg_cfo1_00020     -- �X�V�G���[
                                                      , cv_tkn_table          -- �g�[�N��'TABLE'
                                                      , cv_msg_cfo1_60017     -- OIC�d��Ǘ��w�b�_�e�[�u��
                                                      , cv_tkn_err_msg        -- �g�[�N��'ERR_MSG'
                                                      , SQLERRM               -- SQLERRM
                                                     )
                                                    , 1
                                                    , 5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_oic_journal_h;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc1
   * Description      : GL�d��f�[�^�̒��o�E�t�@�C���o�͏��� (A-2 �` A-4-1)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc1(
      iv_execute_kbn          IN  VARCHAR2     -- ���s�敪 ���:'N'�A�莞:'D'
    , in_set_of_books_id      IN  NUMBER       -- ��v����ID
    , iv_je_source_name       IN  VARCHAR2     -- �d��\�[�X
    , iv_je_category_name     IN  VARCHAR2     -- �d��J�e�S��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc1'; -- �v���O������
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
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF�u���P��iFBDI�t�@�C���p������u���j
    -- Ver1.5 Add Start
    cv_lf_str         CONSTANT VARCHAR2(2)  := '\n';                        -- LF�u���P��iFBDI�t�@�C���p���s�R�[�h�u���j
    -- Ver1.5 Add End
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                         -- CSV��؂蕶��
    cv_fixed_n        CONSTANT VARCHAR2(1)  := 'N';                         -- �Œ�o�͕���
    ln_sales_sob      CONSTANT NUMBER       := fnd_profile.value('XXCMN_SALES_SET_OF_BOOKS_ID');
    ln_ifrs_sob       CONSTANT NUMBER       := fnd_profile.value('XXCFF1_IFRS_SET_OF_BKS_ID');
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER := 0;                                          -- ����
    lv_csv_text       VARCHAR2(30000)                    DEFAULT NULL;      -- �o�͂P�s��������ϐ�
    lv_attribute6     gl_je_lines.reference_1%TYPE    := NULL;              -- �����уw�b�_ID / ���Y�Ǘ��L�[�݌ɊǗ��L�[
    ln_oic_header_id  gl_je_headers.je_header_id%TYPE := NULL;              -- OIC�d��Ǘ����דo�^�w�b�_ID
    ln_sob_kbn        NUMBER := 0;                                          -- ����ID�ʃt�@�C���쐬�敪
-- Ver1.1 Add Start
    ln_out_file_idx   NUMBER;                                               -- �o�̓t�@�C��Index
    ln_out_line       NUMBER;                                               -- �t�@�C�����o�͍s��
    lv_cur_sob        xxcfo_oic_target_journal.name%TYPE;                   -- ��v���떼
    lv_file_name      xxcfo_oic_target_journal.file_name%TYPE;              -- �o�̓t�@�C����(�A�ԕt��)
    lf_file_handle    UTL_FILE.FILE_TYPE;                                   -- �o�̓t�@�C���n���h��
    ln_group_id       gl_interface.group_id%TYPE;                           -- �O���[�vID
-- Ver1.1 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
  CURSOR c_outbound_data1_cur
  IS
    SELECT
-- Ver1.3 Add Start
        /*+ 
            LEADING(xxot xxojh gjh)
            INDEX(xxot XXCFO_OIC_TARGET_JOURNAL_U01)
            INDEX(gjh GL_JE_HEADERS_U1)
            USE_NL(xxojh gjh gjl gcc gsob gjb gjs)
        */
-- Ver1.3 Add End
        TO_CHAR(gjl.effective_date, cv_date_ymd)            AS effective_date         --  1.�L����
      , gjh.je_source                                       AS je_source              --  2.�d��\�[�X
      , gjh.je_category                                     AS je_category            --  3.�d��J�e�S��
      , xxot.je_category_name                               AS je_category_name       --  3.�d��J�e�S����
      , gjs.attribute2                                      AS cloud_source           --  4.ERP Cloud�d��\�[�X
      , gjh.currency_code                                   AS currency_code          --  5.�ʉ�
      , gjh.actual_flag                                     AS actual_flag            --  6.�c���^�C�v
      , gcc.segment1                                        AS segment1               --  7.���
      , gcc.segment2                                        AS segment2               --  8.����
      , gcc.segment3                                        AS segment3               --  9.����Ȗ�
      , gcc.segment3 || gcc.segment4                        AS segment34              -- 10.�⏕�Ȗ�
      , gcc.segment5                                        AS segment5               -- 11.�ڋq�R�[�h
      , gcc.segment6                                        AS segment6               -- 12.��ƃR�[�h
      , gcc.segment7                                        AS segment7               -- 13.�\���P
      , gcc.segment8                                        AS segment8               -- 14.�\���Q
      , gjl.entered_dr                                      AS entered_dr             -- 15.�ؕ����z
      , gjl.entered_cr                                      AS entered_cr             -- 16.�ݕ����z
      , gjl.accounted_dr                                    AS accounted_dr           -- 17.���Z��ؕ����z
      , gjl.accounted_cr                                    AS accounted_cr           -- 18.���Z��ݕ����z
-- Ver1.2 Mod Start
--      , gjb.name                                            AS b_name                 -- 19.�o�b�`��
      , gjb.name || ' ' ||
          TO_CHAR(
            TRUNC(
              (DENSE_RANK() OVER(PARTITION BY gjh.je_batch_id ORDER BY gjh.je_batch_id, gjh.je_header_id) - 1)
              / gn_max_h_cnt_per_b
            ) + 1
          )                                                 AS b_name                 -- 19.�o�b�`��
-- Ver1.2 Mod End
      , gjb.description                                     AS b_description          -- 20.�o�b�`�E�v
      , gjh.name                                            AS h_name                 -- 21.�d��
      , gjh.description                                     AS h_description          -- 22.�d��E�v
      , gjl.description                                     AS l_description          -- 23.�d�󖾍דE�v
      , gjh.currency_conversion_type                        AS conv_type              -- 24.���Z�^�C�v
      , TO_CHAR(gjh.currency_conversion_date, cv_date_ymd)  AS conv_date              -- 25.���Z��
      , gjh.currency_conversion_rate                        AS conv_rate              -- 26.���Z���[�g
      , gjh.set_of_books_id                                 AS set_of_books_id        -- 27.��v����ID
      , gjl.attribute1                                      AS attribute1             -- 28.����ŃR�[�h
      , gjl.attribute2                                      AS attribute2             -- 29.�������R
      , gjl.attribute3                                      AS attribute3             -- 30.�`�[�ԍ�
      , gjl.attribute4                                      AS attribute4             -- 31.�N�[����
      , gjl.attribute6                                      AS attribute6             -- 32.�C�����`�[�ԍ�
      , gjl.attribute8                                      AS attribute8             -- 33.�̔����уw�b�_ID
      , gjl.reference_1                                     AS reference_1            -- 34.���Y�Ǘ��L�[�݌ɊǗ��L�[
      , gjl.attribute9                                      AS attribute9             -- 35.�g�c���ٔԍ�
      , gjl.attribute5                                      AS attribute5             -- 36.���[�UID
      , gjl.attribute7                                      AS attribute7             -- 37.�\���P
      , gjl.attribute10                                     AS attribute10            -- 38.�d�q�f�[�^���
      , gjl.jgzz_recon_ref                                  AS jgzz_recon_ref         -- 39.�����Q��
      , gjl.je_line_num                                     AS je_line_num            -- 40.�d�󖾍הԍ�
      , gjl.code_combination_id                             AS code_combination_id    -- 41.����Ȗڑg����ID
      , gjl.subledger_doc_sequence_value                    AS subledger_value        -- 42.�⏕�땶���ԍ�
-- Ver1.7 Add Start
      , gjl.attribute15                                     AS drafting_company       -- 43.�`�[�쐬���
-- Ver1.7 Add End
      , gsob.name                                           AS sob_name               -- 44.��v���떼
      , gjh.period_name                                     AS period_name            -- 45.��v���Ԗ�
      , gjh.je_header_id                                    AS je_header_id           -- 46.�d��w�b�_ID
-- Ver1.2 Del Start
--      , (CASE WHEN gjh.je_source = cv_receivables AND iv_execute_kbn = cv_execute_kbn_n THEN
--                DECODE( MOD(DENSE_RANK() OVER(
--                          ORDER BY
--                              gjh.set_of_books_id       -- ��v����ID
--                            , gjh.je_source             -- �d��\�[�X
--                            , gjh.je_category           -- �d��J�e�S��
--                            , gjh.je_header_id          -- �d��w�b�_ID
--                          ), 5)
--                        , 0, cv_group_id1, 1, cv_group_id2, 2, cv_group_id3, 3, cv_group_id4, 4, cv_group_id5
--                      )
--              WHEN gjh.je_source  = cv_receivables
--              AND  iv_execute_kbn = cv_execute_kbn_d THEN
--                     cv_group_id1
--              ELSE
--                     NULL
--         END)                                               AS group_id               -- 47.�O���[�vID
-- Ver1.2 Del End
      , xxojh.unsent_min_je_header_id                       AS min_je_header_id       -- 48.���A�g_�ŏ��d��w�b�_ID
    FROM
        gl_sets_of_books          gsob                                -- ��v����
      , gl_je_batches             gjb                                 -- �d��o�b�`
      , gl_je_headers             gjh                                 -- �d��w�b�_
      , gl_je_lines               gjl                                 -- �d�󖾍�
      , gl_code_combinations      gcc                                 -- ����Ȗڑg����
      , gl_je_sources             gjs                                 -- �d��\�[�X
      , xxcfo_oic_target_journal  xxot                                -- OIC�A�g�Ώێd��e�[�u��
      , xxcfo_oic_journal_mng_h   xxojh                               -- OIC�d��Ǘ��w�b�_�e�[�u��
    WHERE
        gjh.status               = cv_books_status                    -- �X�e�[�^�X:�]�L��
    AND gjh.set_of_books_id      = gsob.set_of_books_id               -- ��v����ID
    AND gjh.je_batch_id          = gjb.je_batch_id                    -- �d��o�b�`ID
    AND gjh.je_header_id         = gjl.je_header_id                   -- �d��w�b�_ID
    AND gjl.code_combination_id  = gcc.code_combination_id            -- CCID
    AND gjh.je_source            = gjs.je_source_name                 -- �d��\�[�X��
-- Ver1.3 Mod Start
--    AND gjh.set_of_books_id      = xxot.set_of_books_id               -- ��v����ID
--    AND gjh.je_source            = xxot.je_source                     -- �d��\�[�X
--    AND gjh.je_category          = xxot.je_category                   -- �d��J�e�S��
    AND xxojh.set_of_books_id    = xxot.set_of_books_id               -- ��v����ID
    AND xxojh.je_source          = xxot.je_source                     -- �d��\�[�X
    AND xxojh.je_category        = xxot.je_category                   -- �d��J�e�S��
-- Ver1.3 Mod End
    AND gjh.set_of_books_id      = xxojh.set_of_books_id              -- ��v����ID
    AND gjh.je_source            = xxojh.je_source                    -- �d��\�[�X
    AND gjh.je_category          = xxojh.je_category                  -- �d��J�e�S��
    AND gjh.je_header_id        >= xxojh.unsent_min_je_header_id      -- ���A�g_�ŏ��d��w�b�_ID
    AND NOT EXISTS (
          SELECT 1
          FROM   xxcfo_oic_journal_mng_l  xxojl                    -- OIC�d��Ǘ����׃e�[�u��
          WHERE  xxojl.set_of_books_id  = gjh.set_of_books_id      -- ��v����ID
          AND    xxojl.je_source        = gjh.je_source            -- �d��\�[�X
          AND    xxojl.je_category      = gjh.je_category          -- �d��J�e�S��
          AND    xxojl.je_header_id     = gjh.je_header_id         -- �d��w�b�_ID
        )
    AND xxot.if_pattern          = cv_ebs_journal                     -- �A�g�p�^�[�� :EBS�d�󒊏o
    AND xxot.set_of_books_id     = NVL(in_set_of_books_id,  xxot.set_of_books_id) -- ���̓p�����[�^�u����ID�v
    AND xxot.je_source           = iv_je_source_name                              -- ���̓p�����[�^�u�d��\�[�X�v
    AND xxot.je_category         = NVL(iv_je_category_name, xxot.je_category)     -- ���̓p�����[�^�u�d��J�e�S���v
    ORDER BY
        gjh.set_of_books_id                                        -- ��v����ID
      , gjh.je_source                                              -- �d��\�[�X
      , gjh.je_category                                            -- �d��J�e�S��
-- Ver1.2 Del Start
--      , group_id                                                   -- �O���[�vID
-- Ver1.2 Del End
      , gjh.je_header_id                                           -- �d��w�b�_ID
      , gjl.je_line_num                                            -- �d�󖾍הԍ�
    FOR UPDATE OF xxojh.unsent_min_je_header_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    data1_tbl_rec      c_outbound_data1_cur%ROWTYPE;           -- GL�d��擾
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- A-2.GL�d��A�g�f�[�^�̒��o
    -- =======================================
-- Ver1.1 Add Start
    -- �e�ϐ�������
    ln_out_file_idx := 0;             -- �o�̓t�@�C��Index
    ln_out_line := 0;                 -- �t�@�C�����o�͍s��
    lv_cur_sob := ' ';                -- ���݉�v���떼
    ln_group_id := cn_init_group_id;  -- �O���[�vID
-- Ver1.1 Add End
--
    <<data_loop>>
    FOR data1_tbl_rec IN c_outbound_data1_cur LOOP
-- Ver1.1 Add Start
      -- ��v���떼���؂�ւ�����ꍇ
      IF data1_tbl_rec.sob_name <> lv_cur_sob THEN
        --���݉�v���떼��ݒ�
        lv_cur_sob := data1_tbl_rec.sob_name;
        -- �ϐ�������
        ln_out_line := 0;                -- �t�@�C�����o�͍s��������
        ln_out_file_idx := 1;            -- �o�̓t�@�C��Index������
        ln_group_id := ln_group_id + 1;  -- �O���[�vID
      ELSE
        -- �����s���������Ďd��w�b�_�[ID���ς�����ꍇ�A�o�̓t�@�C����؂�ւ���
        IF ln_out_line >= gn_divcnt
        AND data1_tbl_rec.je_header_id <> ln_oic_header_id THEN
          -- �ϐ�������
          ln_out_line := 0;                        -- �t�@�C�����o�͍s��������
          ln_out_file_idx := ln_out_file_idx + 1;  -- �o�̓t�@�C��Index��+1
          ln_group_id := ln_group_id + 1;          -- �O���[�vID
--
          -- �V�����o�̓t�@�C�����i�A�Ԃ���j��ݒ�
          IF data1_tbl_rec.sob_name = cv_sales_sob THEN
            lv_file_name := gv_fl_name_sales;
          ELSE
            lv_file_name := gv_fl_name_ifrs;
          END IF;
          lv_file_name := lv_file_name || '_' || TO_CHAR(ln_out_file_idx, cv_fmt_fileno) || cv_extension;
--
-- Ver1.6 Add Start
          -- �t�@�C���N���[�Y
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
          -- �V�����o�̓t�@�C�����i�A�Ԃ���j���I�[�v��
          open_output_file(ov_errbuf           => lv_errbuf,
                           ov_retcode          => lv_retcode,
                           ov_errmsg           => lv_errmsg,
                           iv_output_file_name => lv_file_name,
                           of_file_hand        => lf_file_handle
                          );
          IF lv_retcode = cv_status_error THEN
            RAISE global_api_expt;
          END IF;
--
          --�o�̓t�@�C�����ݒ�
          IF data1_tbl_rec.sob_name = cv_sales_sob THEN
            l_out_sale_tab(ln_out_file_idx).file_name := lv_file_name;
            l_out_sale_tab(ln_out_file_idx).file_handle := lf_file_handle;
            l_out_sale_tab(ln_out_file_idx).out_cnt := 0;
          ELSE
            l_out_ifrs_tab(ln_out_file_idx).file_name := lv_file_name;
            l_out_ifrs_tab(ln_out_file_idx).file_handle := lf_file_handle;
            l_out_ifrs_tab(ln_out_file_idx).out_cnt := 0;
          END IF;
        END IF;
      END IF;
--
      ln_out_line := ln_out_line + 1;   -- �t�@�C�����o�͍s����+1
--
      -- �o�͗p�t�@�C���n���h�����擾
      IF data1_tbl_rec.sob_name = cv_sales_sob THEN
        l_out_sale_tab(ln_out_file_idx).out_cnt := l_out_sale_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_sale_tab(ln_out_file_idx).file_handle;
      ELSE
        l_out_ifrs_tab(ln_out_file_idx).out_cnt := l_out_ifrs_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_ifrs_tab(ln_out_file_idx).file_handle;
      END IF;
-- Ver1.1 Add End
      -- 74.�����уw�b�_ID / ���Y�Ǘ��L�[�݌ɊǗ��L�[�̕ҏW
      -- �d��\�[�X���u���Y�Ǘ��vor�u�݌ɊǗ��v�̏ꍇ�A���Y�Ǘ��L�[�݌ɊǗ��L�[��DFF6�Ƀ}�b�s���O����B
      IF ( data1_tbl_rec.je_source = cv_je_source_ast OR data1_tbl_rec.je_source = cv_je_source_inv ) THEN
        lv_attribute6 := data1_tbl_rec.reference_1;
      ELSE
      -- ��L�ȊO�̏ꍇ�A�̔����уw�b�_ID��DFF6�Ƀ}�b�s���O����B
        lv_attribute6 := data1_tbl_rec.attribute8;
      END IF;
--
      -- �t�@�C���o�͍s��ҏW
      lv_csv_text := cv_status_code                                                      || cv_delimiter     --   1.�Œ�l�FStatus Code
        || NULL || cv_delimiter                                                                              --   2.Ledger ID
        || data1_tbl_rec.effective_date                                                  || cv_delimiter     --   3.�L����
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.cloud_source, cv_space )     || cv_delimiter     --   4.ERP Cloud�d��\�[�X
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_category_name, cv_space ) || cv_delimiter     --   5.�d��J�e�S����
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.currency_code, cv_space )    || cv_delimiter     --   6.�ʉ�
        || cd_utc_date                                                                   || cv_delimiter     --   7.���ݓ����iUTC�j
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.actual_flag, cv_space )      || cv_delimiter     --   8.�c���^�C�v
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment1, cv_space )         || cv_delimiter     --   9.���
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment2, cv_space )         || cv_delimiter     --  10.����
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment3, cv_space )         || cv_delimiter     --  11.����Ȗ�
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment34,cv_space)          || cv_delimiter     --  12.�⏕�Ȗ�
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment5, cv_space )         || cv_delimiter     --  13.�ڋq�R�[�h
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment6, cv_space )         || cv_delimiter     --  14.��ƃR�[�h
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment7, cv_space )         || cv_delimiter     --  15.�\���P
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.segment8, cv_space )         || cv_delimiter     --  16.�\���Q
        || NULL || cv_delimiter                                                                              --  17.Segment9
        || NULL || cv_delimiter                                                                              --  18.Segment10
        || NULL || cv_delimiter                                                                              --  19.Segment11
        || NULL || cv_delimiter                                                                              --  20.Segment12
        || NULL || cv_delimiter                                                                              --  21.Segment13
        || NULL || cv_delimiter                                                                              --  22.Segment14
        || NULL || cv_delimiter                                                                              --  23.Segment15
        || NULL || cv_delimiter                                                                              --  24.Segment16
        || NULL || cv_delimiter                                                                              --  25.Segment17
        || NULL || cv_delimiter                                                                              --  26.Segment18
        || NULL || cv_delimiter                                                                              --  27.Segment19
        || NULL || cv_delimiter                                                                              --  28.Segment20
        || NULL || cv_delimiter                                                                              --  29.Segment21
        || NULL || cv_delimiter                                                                              --  30.Segment22
        || NULL || cv_delimiter                                                                              --  31.Segment23
        || NULL || cv_delimiter                                                                              --  32.Segment24
        || NULL || cv_delimiter                                                                              --  33.Segment25
        || NULL || cv_delimiter                                                                              --  34.Segment26
        || NULL || cv_delimiter                                                                              --  35.Segment27
        || NULL || cv_delimiter                                                                              --  36.Segment28
        || NULL || cv_delimiter                                                                              --  37.Segment29
        || NULL || cv_delimiter                                                                              --  38.Segment30
        || data1_tbl_rec.entered_dr                                                    || cv_delimiter       --  39.�ؕ����z
        || data1_tbl_rec.entered_cr                                                    || cv_delimiter       --  40.�ݕ����z
        || data1_tbl_rec.accounted_dr                                                  || cv_delimiter       --  41.���Z��ؕ����z
        || data1_tbl_rec.accounted_cr                                                  || cv_delimiter       --  42.���Z��ݕ����z
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.b_name , cv_space )        || cv_delimiter       --  43.�o�b�`��
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.b_description , cv_space ) || cv_delimiter       --  44.�o�b�`�E�v
        || to_csv_string( data1_tbl_rec.b_description , cv_lf_str )                    || cv_delimiter       --  44.�o�b�`�E�v
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  45.REFERENCE3
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.h_name , cv_space )        || cv_delimiter       --  46.�d��
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.h_description , cv_space ) || cv_delimiter       --  47.�d��E�v
        || to_csv_string( data1_tbl_rec.h_description , cv_lf_str )                    || cv_delimiter       --  47.�d��E�v
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  48.REFERENCE6
        || NULL || cv_delimiter                                                                              --  49.REFERENCE7
        || NULL || cv_delimiter                                                                              --  50.REFERENCE8
        || NULL || cv_delimiter                                                                              --  51.REFERENCE9
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.l_description , cv_space ) || cv_delimiter       --  52.�d�󖾍דE�v
        || NULL || cv_delimiter                                                                              --  53.Reference column 1
        || NULL || cv_delimiter                                                                              --  54.Reference column 2
        || NULL || cv_delimiter                                                                              --  55.Reference column 3
        || NULL || cv_delimiter                                                                              --  56.Reference column 4
        || NULL || cv_delimiter                                                                              --  57.Reference column 5
        || NULL || cv_delimiter                                                                              --  58.Reference column 6
        || NULL || cv_delimiter                                                                              --  59.Reference column 7
        || NULL || cv_delimiter                                                                              --  60.Reference column 8
        || NULL || cv_delimiter                                                                              --  61.Reference column 9
        || NULL || cv_delimiter                                                                              --  62.Reference column 10
        || NULL || cv_delimiter                                                                              --  63.Statistical Amount
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.conv_type, cv_space )   || cv_delimiter          --  64.���Z�^�C�v
        || data1_tbl_rec.conv_date                                                  || cv_delimiter          --  65.���Z��
        || data1_tbl_rec.conv_rate                                                  || cv_delimiter          --  66.���Z���[�g
-- Ver1.1 Mod Start
--        || data1_tbl_rec.group_id                                                   || cv_delimiter          --  67.�O���[�vID
        || ln_group_id                                                              || cv_delimiter          --  67.�O���[�vID
-- Ver1.1 Mod End
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  68.��v���떼
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute1, cv_space )  || cv_delimiter          --  69.����ŃR�[�h
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute2, cv_space )  || cv_delimiter          --  70.�������R
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute3, cv_space )  || cv_delimiter          --  71.�`�[�ԍ�
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute4, cv_space )  || cv_delimiter          --  72.�N�[����
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute6, cv_space )  || cv_delimiter          --  73.�C�����`�[�ԍ�
--        || xxccp_oiccommon_pkg.to_csv_string(lv_attribute6, cv_space ) || cv_delimiter                       --  74.�����уw�b�_ID / ���Y�Ǘ��L�[�݌ɊǗ��L�[
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute9, cv_space )  || cv_delimiter          --  75.�g�c���ٔԍ�
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute5, cv_space )  || cv_delimiter          --  76.���[�UID
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute7, cv_space )  || cv_delimiter          --  77.�\���P
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.attribute10, cv_space ) || cv_delimiter          --  78.�d�q�f�[�^���
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.jgzz_recon_ref, cv_space )      || cv_delimiter  --  79.�����Q��
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_line_num, cv_space )         || cv_delimiter  --  80.�d�󖾍הԍ�
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.code_combination_id, cv_space ) || cv_delimiter  --  81.����Ȗڑg����ID
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.subledger_value, cv_space )     || cv_delimiter  --  82.�⏕�땶���ԍ�
        || to_csv_string( data1_tbl_rec.sob_name, cv_lf_str )                         || cv_delimiter        --  68.��v���떼
        || to_csv_string( data1_tbl_rec.attribute1, cv_lf_str )                       || cv_delimiter        --  69.����ŃR�[�h
        || to_csv_string( data1_tbl_rec.attribute2, cv_lf_str )                       || cv_delimiter        --  70.�������R
        || to_csv_string( data1_tbl_rec.attribute3, cv_lf_str )                       || cv_delimiter        --  71.�`�[�ԍ�
        || to_csv_string( data1_tbl_rec.attribute4, cv_lf_str )                       || cv_delimiter        --  72.�N�[����
        || to_csv_string( data1_tbl_rec.attribute6, cv_lf_str )                       || cv_delimiter        --  73.�C�����`�[�ԍ�
        || to_csv_string(lv_attribute6, cv_lf_str )                                   || cv_delimiter        --  74.�����уw�b�_ID / ���Y�Ǘ��L�[�݌ɊǗ��L�[
        || to_csv_string( data1_tbl_rec.attribute9, cv_lf_str )                       || cv_delimiter        --  75.�g�c���ٔԍ�
        || to_csv_string( data1_tbl_rec.attribute5, cv_lf_str )                       || cv_delimiter        --  76.���[�UID
        || to_csv_string( data1_tbl_rec.attribute7, cv_lf_str )                       || cv_delimiter        --  77.�\���P
        || to_csv_string( data1_tbl_rec.attribute10, cv_lf_str )                      || cv_delimiter        --  78.�d�q�f�[�^���
        || to_csv_string( data1_tbl_rec.jgzz_recon_ref, cv_lf_str )                   || cv_delimiter        --  79.�����Q��
        || to_csv_string( data1_tbl_rec.je_line_num, cv_lf_str )                      || cv_delimiter        --  80.�d�󖾍הԍ�
        || to_csv_string( data1_tbl_rec.code_combination_id, cv_lf_str )              || cv_delimiter        --  81.����Ȗڑg����ID
        || to_csv_string( data1_tbl_rec.subledger_value, cv_lf_str )                  || cv_delimiter        --  82.�⏕�땶���ԍ�
        -- Ver1.5 Mod End
-- Ver1.7 Mod Start
--        || NULL || cv_delimiter                                                                              --  83.Attribute15 Value for Captured Information
        || to_csv_string( data1_tbl_rec.drafting_company, cv_lf_str )                 || cv_delimiter        --  83.Attribute15 Value for Captured Information
-- Ver1.7 Mod End
        || NULL || cv_delimiter                                                                              --  84.Attribute16 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  85.Attribute17 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  86.Attribute18 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  87.Attribute19 Value for Captured Information
        || NULL || cv_delimiter                                                                              --  88.Attribute20 Value for Captured Information
        -- Ver1.5 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  89.��v���떼
        || to_csv_string( data1_tbl_rec.sob_name, cv_lf_str )                         || cv_delimiter        --  89.��v���떼
        -- Ver1.5 Mod End
        || NULL || cv_delimiter                                                                              --  90.Average Journal Flag
        || NULL || cv_delimiter                                                                              --  91.Clearing Company
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  92.��v���떼
        || NULL || cv_delimiter                                                                              --  93.Encumbrance Type ID
        || NULL || cv_delimiter                                                                              --  94.Reconciliation Reference
-- Ver1.1 Mod Start
--        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.sob_name, cv_space )    || cv_delimiter          --  95.��v���떼
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.period_name, cv_space )    || cv_delimiter       --  95.��v���Ԗ�
-- Ver1.1 Mod End
        || NULL || cv_delimiter                                                                              --  96.REFERENCE 18
        || NULL || cv_delimiter                                                                              --  97.REFERENCE 19
        || NULL || cv_delimiter                                                                              --  98.REFERENCE 20
        || NULL || cv_delimiter                                                                              --  99.Attribute Date 1
        || NULL || cv_delimiter                                                                              -- 100.Attribute Date 2
        || NULL || cv_delimiter                                                                              -- 101.Attribute Date 3
        || NULL || cv_delimiter                                                                              -- 102.Attribute Date 4
        || NULL || cv_delimiter                                                                              -- 103.Attribute Date 5
        || NULL || cv_delimiter                                                                              -- 104.Attribute Date 6
        || NULL || cv_delimiter                                                                              -- 105.Attribute Date 7
        || NULL || cv_delimiter                                                                              -- 106.Attribute Date 8
        || NULL || cv_delimiter                                                                              -- 107.Attribute Date 9
        || NULL || cv_delimiter                                                                              -- 108.Attribute Date 10
        || xxccp_oiccommon_pkg.to_csv_string( data1_tbl_rec.je_header_id, cv_space ) || cv_delimiter         -- 109.�d��w�b�_ID
        || NULL || cv_delimiter                                                                              -- 110.Attribute Number 2
        || NULL || cv_delimiter                                                                              -- 111.Attribute Number 3
        || NULL || cv_delimiter                                                                              -- 112.Attribute Number 4
        || NULL || cv_delimiter                                                                              -- 113.Attribute Number 5
        || NULL || cv_delimiter                                                                              -- 114.Attribute Number 6
        || NULL || cv_delimiter                                                                              -- 115.Attribute Number 7
        || NULL || cv_delimiter                                                                              -- 116.Attribute Number 8
        || NULL || cv_delimiter                                                                              -- 117.Attribute Number 9
        || NULL || cv_delimiter                                                                              -- 118.Attribute Number 10
        || NULL || cv_delimiter                                                                              -- 119.Global Attribute Category
        || NULL || cv_delimiter                                                                              -- 120.Global Attribute 1 
        || NULL || cv_delimiter                                                                              -- 121.Global Attribute 2
        || NULL || cv_delimiter                                                                              -- 122.Global Attribute 3
        || NULL || cv_delimiter                                                                              -- 123.Global Attribute 4
        || NULL || cv_delimiter                                                                              -- 124.Global Attribute 5
        || NULL || cv_delimiter                                                                              -- 125.Global Attribute 6 
        || NULL || cv_delimiter                                                                              -- 126.Global Attribute 7
        || NULL || cv_delimiter                                                                              -- 127.Global Attribute 8
        || NULL || cv_delimiter                                                                              -- 128.Global Attribute 9
        || NULL || cv_delimiter                                                                              -- 129.Global Attribute 10
        || NULL || cv_delimiter                                                                              -- 130.Global Attribute 11
        || NULL || cv_delimiter                                                                              -- 131.Global Attribute 12
        || NULL || cv_delimiter                                                                              -- 132.Global Attribute 13
        || NULL || cv_delimiter                                                                              -- 133.Global Attribute 14
        || NULL || cv_delimiter                                                                              -- 134.Global Attribute 15
        || NULL || cv_delimiter                                                                              -- 135.Global Attribute 16
        || NULL || cv_delimiter                                                                              -- 136.Global Attribute 17
        || NULL || cv_delimiter                                                                              -- 137.Global Attribute 18
        || NULL || cv_delimiter                                                                              -- 138.Global Attribute 19 
        || NULL || cv_delimiter                                                                              -- 139.Global Attribute 20 
        || NULL || cv_delimiter                                                                              -- 140.Global Attribute Date 1
        || NULL || cv_delimiter                                                                              -- 141.Global Attribute Date 2
        || NULL || cv_delimiter                                                                              -- 142.Global Attribute Date 3
        || NULL || cv_delimiter                                                                              -- 143.Global Attribute Date 4
        || NULL || cv_delimiter                                                                              -- 144.Global Attribute Date 5
        || NULL || cv_delimiter                                                                              -- 145.Global Attribute Number 1
        || NULL || cv_delimiter                                                                              -- 146.Global Attribute Number 2
        || NULL || cv_delimiter                                                                              -- 147.Global Attribute Number 3
        || NULL || cv_delimiter                                                                              -- 148.Global Attribute Number 4
        || NULL                                                                                              -- 149.Global Attribute Number 5
      ;
--
      -- =======================================
      -- A-3.GL�d��A�g�f�[�^�̃t�@�C���o��
      -- =======================================
      -- �t�@�C����������
-- Ver1.1 Add Start
      UTL_FILE.PUT_LINE( lf_file_handle, lv_csv_text );
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      IF ( iv_execute_kbn = cv_execute_kbn_n AND data1_tbl_rec.je_source = cv_receivables ) THEN       -- ��Ԏ��s�����|�Ǘ�
--        CASE WHEN data1_tbl_rec.group_id = cv_group_id1 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_01, lv_csv_text );
--               gn_cnt_fl_01 := gn_cnt_fl_01 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id2 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_02, lv_csv_text );
--               gn_cnt_fl_02 := gn_cnt_fl_02 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id3 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_03, lv_csv_text );
--               gn_cnt_fl_03 := gn_cnt_fl_03 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id4 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_04, lv_csv_text );
--               gn_cnt_fl_04 := gn_cnt_fl_04 + 1;
--             WHEN data1_tbl_rec.group_id = cv_group_id5 THEN
--               UTL_FILE.PUT_LINE( gf_file_hand_05, lv_csv_text );
--               gn_cnt_fl_05 := gn_cnt_fl_05 + 1;
--            ELSE
--               NULL;
--        END CASE;
--      ELSE                                                                            -- �����ΏۊO
--        IF ( ln_sob_kbn = 0 OR data1_tbl_rec.set_of_books_id  = ln_sob_kbn ) THEN
--          UTL_FILE.PUT_LINE( gf_file_hand_01, lv_csv_text );                          -- Journal_SALES or Journal_IFRS
--          ln_sob_kbn := data1_tbl_rec.set_of_books_id;
--          gn_cnt_fl_01 := gn_cnt_fl_01 + 1;
--        ELSE
--          UTL_FILE.PUT_LINE( gf_file_hand_02, lv_csv_text );                          -- Journal_IFRS
--          gn_cnt_fl_02 := gn_cnt_fl_02 + 1;
--        END IF;
--      END IF;
-- Ver1.1 Del End
      ln_cnt := ln_cnt + 1;
--
      -- =================================
      -- A-4-1.OIC�d��Ǘ����׃e�[�u���o�^
      -- =================================
      -- �d��w�b�_ID�P�ʂɖ��׃e�[�u���֓o�^����
      IF ( ln_oic_header_id IS NULL OR ln_oic_header_id != data1_tbl_rec.je_header_id ) THEN
        BEGIN
          INSERT INTO xxcfo_oic_journal_mng_l(
             set_of_books_id
           , je_source
           , je_category
           , je_header_id
           , created_by
           , creation_date
           , last_updated_by
           , last_update_date
           , last_update_login
           , request_id
           , program_application_id
           , program_id
           , program_update_date
          ) VALUES (
             data1_tbl_rec.set_of_books_id          -- ��v����ID
           , data1_tbl_rec.je_source                -- �d��\�[�X
           , data1_tbl_rec.je_category              -- �d��J�e�S��
           , data1_tbl_rec.je_header_id             -- �d��w�b�_ID
           , cn_created_by                          -- �쐬��
           , cd_creation_date                       -- �쐬��
           , cn_last_updated_by                     -- �ŏI�X�V��
           , cd_last_update_date                    -- �ŏI�X�V��
           , cn_last_update_login                   -- �ŏI�X�V���O�C��
           , cn_request_id                          -- �v��ID
           , cn_program_application_id              -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
           , cn_program_id                          -- �R���J�����g�E�v���O����ID
           , cd_program_update_date                 -- �v���O�����ɂ��X�V��
          );
--
        EXCEPTION
          WHEN OTHERS THEN
            -- �f�[�^�o�^�G���[
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo        -- 'XXCFO'
                                                          , cv_msg_cfo1_00024     -- �o�^�G���[
                                                          , cv_tkn_table          -- �g�[�N��'TABLE'
                                                          , cv_msg_cfo1_60018     -- OIC�d��Ǘ����׃e�[�u��
                                                          , cv_tkn_err_msg        -- �g�[�N��'ERR_MSG'
                                                          , SQLERRM               -- SQLERRM
                                                         )
                                                        , 1
                                                        , 5000);
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
--
      IF ( ln_oic_header_id IS NULL ) THEN
        gn_pre_sob_id    := data1_tbl_rec.set_of_books_id;  -- ��v����ID�i�O��l�j
        gv_pre_source    := data1_tbl_rec.je_source;        -- �d��\�[�X�i�O��l�j
        gv_pre_category  := data1_tbl_rec.je_category;      -- �d��J�e�S���i�O��l�j
        gn_pre_min_je_id := data1_tbl_rec.min_je_header_id; -- ���A�g_�ŏ��d��w�b�_ID�i�O��l�j
      END IF;
--
      ln_oic_header_id := data1_tbl_rec.je_header_id;       -- �o�^�����d��w�b�_ID
--
      -- ==========================================================================
      -- A-4-2.OIC�d��Ǘ��w�b�_�e�[�u���X�V�i�u���A�g_�ŏ��d��w�b�_ID�v�̍ŐV���j
      -- ==========================================================================
      -- �u����ID�v�A�u�d��J�e�S���v�̂����ꂩ���O��l�ƈقȂ�ꍇ�A�w�b�_�e�[�u���̍X�V�������s���B
      IF ( ( gn_pre_sob_id   != data1_tbl_rec.set_of_books_id )
        OR ( gv_pre_category != data1_tbl_rec.je_category ) )   THEN
        upd_oic_journal_h(
            lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
          , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
          , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_pre_sob_id    := data1_tbl_rec.set_of_books_id;  -- ��v����ID�i�O��l�j
        gv_pre_source    := data1_tbl_rec.je_source;        -- �d��\�[�X�i�O��l�j
        gv_pre_category  := data1_tbl_rec.je_category;      -- �d��J�e�S���i�O��l�j
        gn_pre_min_je_id := data1_tbl_rec.min_je_header_id; -- ���A�g_�ŏ��d��w�b�_ID�i�O��l�j
--
      END IF;
    END LOOP data_loop;
--
    -- �S��������A�ŏI�̒l�Ńw�b�_�e�[�u���̍X�V�������s���B
    IF ( gn_pre_sob_id IS NOT NULL ) THEN
      upd_oic_journal_h(
          lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
        , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
        , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- Ver1.6 Add Start
    -- �t�@�C���N���[�Y
    IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
      UTL_FILE.FCLOSE( lf_file_handle );
    END IF;
-- Ver1.6 Add End
    -- GL�d��A�g�̑Ώی������Z�b�g
    gn_target_cnt  := ln_cnt;                    -- �A�g�f�[�^�̌���
    -- ���팏�� = �Ώی����i�����j
    gn_normal_cnt  := gn_target_cnt;
--
  EXCEPTION
    WHEN global_lock_expt THEN  -- �e�[�u�����b�N�G���[
      -- �t�@�C���N���[�Y
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
--                     , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
--                     , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                    , cv_msg_cfo1_00019   -- ���b�N�G���[���b�Z�[�W
                                                    , cv_tkn_table        -- �g�[�N��(TABLE)
                                                    , cv_msg_cfo1_60017   -- OIC�d��Ǘ��w�b�_�e�[�u��
                                                   )
                                                  , 1
                                                  , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- �t�@�C���N���[�Y
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
--                     , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
--                     , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- 'XXCFO'
                                                    , cv_msg_cfo1_00030   -- �t�@�C���������݃G���[
                                                    , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                    , SQLERRM             -- SQLERRM
                                                   )
                                                  , 1
                                                  , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
-- Ver1.6 Add Start
          -- �t�@�C���N���[�Y
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- Ver1.6 Add Start
          -- �t�@�C���N���[�Y
          IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
            UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver1.6 Add End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C���N���[�Y
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
--                     , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
--                     , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y
-- Ver1.6 Mod Start
--      file_close_proc( lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
--                     , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
--                     , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
      IF ( UTL_FILE.IS_OPEN ( lf_file_handle ) ) THEN
        UTL_FILE.FCLOSE( lf_file_handle );
      END IF;
-- Ver1.6 Mod End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_outbound_proc1;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_execute_kbn          IN  VARCHAR2     -- ���s�敪 ���:'N'�A�莞:'D'
    , in_set_of_books_id      IN  NUMBER       -- ��v����ID
    , iv_je_source_name       IN  VARCHAR2     -- �d��\�[�X
    , iv_je_category_name     IN  VARCHAR2     -- �d��J�e�S��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
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
--
    -- ======================================================
    --  ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
    -- ======================================================
    init(
        iv_execute_kbn          -- ���s�敪 ���:'N'�A�莞:'D'
      , in_set_of_books_id      -- ��v����ID
      , iv_je_source_name       -- �d��\�[�X
      , iv_je_category_name     -- �d��J�e�S��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  GL�d��f�[�^�̒��o�E�t�@�C���o�͏��� (A-2 �` A-4-1)
    -- =====================================================
    data_outbound_proc1(
        iv_execute_kbn          -- ���s�敪 ���:'N'�A�莞:'D'
      , in_set_of_books_id      -- ��v����ID
      , iv_je_source_name       -- �d��\�[�X
      , iv_je_category_name     -- �d��J�e�S��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- �G���[�E���b�Z�[�W   # �Œ� #
    , retcode                 OUT VARCHAR2      -- ���^�[���E�R�[�h     # �Œ� #
    , iv_execute_kbn          IN  VARCHAR2      -- ���s�敪 ���:'N'�A�莞:'D'
    , in_set_of_books_id      IN  NUMBER        -- ��v����ID
    , iv_je_source_name       IN  VARCHAR2      -- �d��\�[�X
    , iv_je_category_name     IN  VARCHAR2      -- �d��J�e�S��
  )
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
    lv_msgbuf          VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    ln_cnt             NUMBER := 0;     -- �t�@�C����
    ln_cnt2            NUMBER := 0;     -- �o�͌���
    lv_fl_name         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- �t�@�C����
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        iv_execute_kbn           -- ���s�敪 ���:'N'�A�莞:'D'
      , in_set_of_books_id       -- ��v����ID
      , iv_je_source_name        -- �d��\�[�X
      , iv_je_category_name      -- �d��J�e�S��
      , lv_errbuf                -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode               -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    );
--
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := 1;                                   -- �G���[����
--
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
--
    -- =============
    -- A-5�D�I������
    -- =============
-- Ver1.6 Del Start
--    -- A-5-1�D�I�[�v�����Ă��邷�ׂẴt�@�C�����N���[�Y����
--    -- =====================================================
---- Ver1.1 Add Start
--    IF gv_fl_name_sales IS NOT NULL THEN
--      <<file_close_loop>>
--      FOR i IN 1..l_out_sale_tab.COUNT LOOP
--        IF ( UTL_FILE.IS_OPEN ( l_out_sale_tab(i).file_handle ) ) THEN
--          UTL_FILE.FCLOSE( l_out_sale_tab(i).file_handle );
--        END IF;
--      END LOOP file_close_loop;
--    END IF;
----
--    IF gv_fl_name_ifrs IS NOT NULL THEN
--      <<file_close_loop2>>
--      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
--        IF ( UTL_FILE.IS_OPEN ( l_out_ifrs_tab(i).file_handle ) ) THEN
--          UTL_FILE.FCLOSE( l_out_ifrs_tab(i).file_handle );
--        END IF;
--      END LOOP file_close_loop2;
--    END IF;
---- Ver1.1 Add End
-- Ver1.6 Del End
-- Ver1.1 Del Start
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_01 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_01 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_02 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_02 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_03 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_03 );
--    END IF;
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_04 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_04 );
--    END IF;
--    --
--    IF ( UTL_FILE.IS_OPEN ( gf_file_hand_05 ) ) THEN
--      UTL_FILE.FCLOSE( gf_file_hand_05 );
--    END IF;
-- Ver1.1 Del End
--
    -- A-5-2�D���o�������o�͂���
    -- =========================
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    ln_cnt := gn_target_cnt;                                               -- GL�d��A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                    , iv_name         => cv_msg_cfo1_60004                 -- �����ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => cv_msg_cfo1_60026                 -- �g�[�N��(EBS�d��)
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- ���o����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- A-5-3�D�o�͌������t�@�C�������o�͂���
    -- =====================================
    -- 1.GL�d��A�g�t�@�C���o�͌����o��
-- Ver1.1 Add Start
    -- SALES GL�d��A�g�t�@�C���o�͌����o��
    IF gv_fl_name_sales IS NOT NULL THEN
      <<log_out_loop>>
      FOR i IN 1..l_out_sale_tab.COUNT LOOP
        lv_msgbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                        , iv_name         => cv_msg_cfo1_60005                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                        , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                        , iv_token_value1 => l_out_sale_tab(i).file_name       -- GL�d��A�g�f�[�^�t�@�C��
                        , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                        , iv_token_value2 => TO_CHAR(l_out_sale_tab(i).out_cnt, cv_comma_edit)   -- �o�͌���
                       );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_msgbuf
        );
      END LOOP log_out_loop;
    END IF;
--
    -- IFRS GL�d��A�g�t�@�C���o�͌����o��
    IF gv_fl_name_ifrs IS NOT NULL THEN
      <<log_out_loop2>>
      FOR i IN 1..l_out_ifrs_tab.COUNT LOOP
        lv_msgbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
                        , iv_name         => cv_msg_cfo1_60005                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                        , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                        , iv_token_value1 => l_out_ifrs_tab(i).file_name       -- GL�d��A�g�f�[�^�t�@�C��
                        , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                        , iv_token_value2 => TO_CHAR(l_out_ifrs_tab(i).out_cnt, cv_comma_edit)   -- �o�͌���
                       );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_msgbuf
        );
      END LOOP log_out_loop2;
    END IF;
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    <<data_loop>>
--    ln_cnt := 1;
--    FOR i in 1..gn_fl_out_c LOOP
--      CASE WHEN ln_cnt = 1 THEN
--             lv_fl_name := gv_fl_name1;
--             ln_cnt2    := gn_cnt_fl_01;
--           WHEN ln_cnt = 2 THEN
--             lv_fl_name := gv_fl_name2;
--             ln_cnt2    := gn_cnt_fl_02;
--           WHEN ln_cnt = 3 THEN
--             lv_fl_name := gv_fl_name3;
--             ln_cnt2    := gn_cnt_fl_03;
--           WHEN ln_cnt = 4 THEN
--             lv_fl_name := gv_fl_name4;
--             ln_cnt2    := gn_cnt_fl_04;
--           WHEN ln_cnt = 5 THEN
--             lv_fl_name := gv_fl_name5;
--             ln_cnt2    := gn_cnt_fl_05;
--           ELSE
--             NULL;
--      END CASE;
--      -- 1.GL�d��A�g�t�@�C���o�͌����o��
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_kbn_cfo                    -- 'XXCFO'
--                      , iv_name         => cv_msg_cfo1_60005                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
--                      , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
--                      , iv_token_value1 => lv_fl_name                        -- GL�d��A�g�f�[�^�t�@�C��
--                      , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
--                      , iv_token_value2 => TO_CHAR(ln_cnt2, cv_comma_edit)   -- �o�͌���
--                     );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
--      ln_cnt := ln_cnt + 1;
--    END LOOP data_loop;
-- Ver1.1 Del End
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --
    -- A-5-4�D�Ώی����A�����I/F�t�@�C���ւ̏o�͌����i���������^�G���[�����j���o�͂���
    -- ================================================================================
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- �Ώی���
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt, cv_comma_edit)    -- ��������
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt, cv_comma_edit)    -- �G���[����
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-5-5�D�I���X�e�[�^�X�ɂ��A�Y�����鏈���I�����b�Z�[�W���o�͂���
    -- =================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�X �e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXCFO010A05C;
/
