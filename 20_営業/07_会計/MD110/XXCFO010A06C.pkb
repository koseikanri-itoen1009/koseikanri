CREATE OR REPLACE PACKAGE BODY APPS.XXCFO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO010A06C (body)
 * Description      : GLOIF�d��̓]�����o
 * MD.050           : T_MD050_CFO_010_A06_GLOIF�d��̓]�����o_EBS�R���J�����g
 * Version          : 1.4
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  to_csv_string          CSV�t�@�C���p������ϊ�
 *  init                   ��������(A-1)
 *  output_gloif           �A�g�f�[�^���o����(A-2)
 *                         I/F�t�@�C���o�͏���(A-3)
 *  bkup_oic_gloif         �o�b�N�A�b�v����(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-28    1.0   K.Tomie          �V�K�쐬
 *  2023-01-19    1.1   T.Mizutani       �t�@�C�������Ή�
 *  2023-03-01    1.2   F.Hasebe         �V�i���I�e�X�g��QNo.0039�Ή�
 *  2023-03-01    1.3   Y.Ooyama         �ڍs��QNo.44�Ή�
 *  2023-05-10    1.4   S.Yoshioka       �J���c�ۑ�07�Ή�
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
  -- ���b�N�G���[��O
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name              CONSTANT VARCHAR2(100)  := 'XXCFO010A06C';            -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo           CONSTANT VARCHAR2(5)    := 'XXCFO';                   -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi           CONSTANT VARCHAR2(5)    := 'XXCOI';                   -- �A�h�I���F�̕��E�݌ɗ̈�̃A�v���P�[�V�����Z�k��
  -- 
  cv_msg_slash             CONSTANT VARCHAR2(1)    := '/';                       -- �X���b�V��
  cn_max_linesize          CONSTANT BINARY_INTEGER := 32767;                     -- �t�@�C���T�C�Y
  cv_open_mode_w           CONSTANT VARCHAR2(1)    := 'W';                       -- �ǂݍ��݃��[�h
  cv_delim_comma           CONSTANT VARCHAR2(1)    := ',';                       -- �J���}
  cv_space                 CONSTANT VARCHAR2(1)    := ' ';                       -- LF�u���P��
  -- Ver1.4 Add Start
  cv_lf_str                CONSTANT VARCHAR2(2)    := '\n';                      -- LF�u���P��iFBDI�t�@�C���p���s�R�[�h�u���j
  -- Ver1.4 Add End
  cv_execute_kbn_n         CONSTANT VARCHAR2(20)   := 'N';                       -- ���s�敪 = 'N':���
  cv_execute_kbn_d         CONSTANT VARCHAR2(20)   := 'D';                       -- ���s�敪 = 'D':�莞
  cv_gloif_journal         CONSTANT VARCHAR2(20)   := '2';                       -- �A�g�p�^�[��   = '2':GLOIF�d�󒊏o
  cv_gloif_status_new      CONSTANT VARCHAR2(20)   := 'NEW';                     -- �X�e�[�^�X = NEW
  cv_status_code           CONSTANT VARCHAR2(20)   := 'NEW';                     -- �t�@�C���o�͌Œ�l�FStatus Code
-- Ver1.1 Add Start
  cv_sales_sob             CONSTANT VARCHAR2(20)   := 'SALES-SOB';               -- SALES��v���떼
-- Ver1.1 Add End

  -- ����
  cv_comma_edit            CONSTANT VARCHAR2(30)   := 'FM999,999,999';           -- �����o�͏���
  cv_date_ymd              CONSTANT VARCHAR2(30)   := 'YYYY/MM/DD';              -- ���t����
  -- ���b�Z�[�WNo.
  cv_msg1                  CONSTANT VARCHAR2(2)    := '1.';                      -- 1
  cv_msg2                  CONSTANT VARCHAR2(2)    := '2.';                      -- 2
  -- �v���t�@�C��
  cv_oic_out_file_dir      CONSTANT VARCHAR2(100)  := 'XXCFO1_OIC_OUT_FILE_DIR'; -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
-- Ver1.1 Add Start
  cv_div_cnt               CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_DIVCNT_GL_OIF'; -- XXCFO:OIC�A�g�����s���iEBS�d��j
  -- �O���[�vID
  cn_init_group_id         CONSTANT NUMBER         := 1000;                       -- �O���[�vID�����l
  -- �t�@�C�����p�萔
  cv_extension             CONSTANT VARCHAR2(10)  := '.csv';                      -- �t�@�C���������̊g���q
  cv_fmt_fileno            CONSTANT VARCHAR2(10)  := 'FM00';                      -- �t�@�C���A�ԏ���
-- Ver1.1 Add End
-- Ver1.3 Add Start
  cv_prf_max_h_cnt_per_b   CONSTANT VARCHAR2(60)   := 'XXCFO1_OIC_MAX_H_CNT_PER_BATCH'; -- XXCFO:�d��o�b�`������d��w�b�_�����iOIC�A�g�j
-- Ver1.3 Add End
  -- ���b�Z�[�W
  cv_msg_cfo1_60001        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60001';        -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_cfo1_60009        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60009';        -- �p�����[�^�K�{�G���[���b�Z�[�W
  cv_msg_cfo1_60010        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60010';        -- �p�����[�^�s���G���[���b�Z�[�W
  cv_msg_cfo1_60011        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60011';        -- OIC�A�g�Ώێd��Y���Ȃ��G���[���b�Z�[�W
  cv_msg_cfo1_00001        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_coi1_00029        CONSTANT VARCHAR2(20)   := 'APP-XXCOI1-00029';        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo1_00019        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00019';        -- ���b�N�G���[���b�Z�[�W
  cv_msg_cfo1_60002        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60002';        -- IF�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo1_00027        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00027';        -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo1_00029        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00029';        -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo1_00030        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00030';        -- �t�@�C�������݃G���[���b�Z�[�W
  cv_msg_cfo1_00024        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo1_00025        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-00025';        -- �폜�G���[���b�Z�[�W
  cv_msg_cfo1_60004        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60004';        -- �����ΏہE�������b�Z�[�W
  cv_msg_cfo1_60005        CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60005';        -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_param_name        CONSTANT VARCHAR2(30)   := 'PARAM_NAME';              -- �g�[�N����(PARAM_NAME)
  cv_tkn_param_val         CONSTANT VARCHAR2(30)   := 'PARAM_VAL';               -- �g�[�N����(PARAM_VAL)
  cv_tkn_prof_name         CONSTANT VARCHAR2(30)   := 'PROF_NAME';               -- �g�[�N����(PROF_NAME)
  cv_tkn_dir_tok           CONSTANT VARCHAR2(30)   := 'DIR_TOK';                 -- �g�[�N����(DIR_TOK)
  cv_tkn_table             CONSTANT VARCHAR2(30)   := 'TABLE';                   -- �g�[�N����(TABLE)
  cv_tkn_count             CONSTANT VARCHAR2(30)   := 'COUNT';                   -- �g�[�N����(COUNT)
  cv_tkn_file_name         CONSTANT VARCHAR2(30)   := 'FILE_NAME';               -- �g�[�N����(FILE_NAME)
  cv_tkn_errmsg            CONSTANT VARCHAR2(30)   := 'ERRMSG';                  -- �g�[�N����(ERRMSG)
  cv_tkn_target            CONSTANT VARCHAR2(30)   := 'TARGET';                  -- �g�[�N����(TARGET)
-- Ver1.1 Add Start
  cv_tkn_sqlerrm           CONSTANT VARCHAR2(30)   := 'SQLERRM';                 -- SQLERRM
-- Ver1.1 Add End
  -- ���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo1_60013     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60013';        -- ���s�敪
  cv_msgtkn_cfo1_60014     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60014';        -- ����ID
  cv_msgtkn_cfo1_60015     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60015';        -- �d��\�[�X
  cv_msgtkn_cfo1_60016     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60016';        -- �d��J�e�S��
  cv_msgtkn_cfo1_60019     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60019';        -- OIC_GLOIF�o�b�N�A�b�v�e�[�u��
  cv_msgtkn_cfo1_60020     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60020';        -- GLOIF
  cv_msgtkn_cfo1_60027     CONSTANT VARCHAR2(20)   := 'APP-XXCFO1-60027';        -- GLOIF�d��̓]��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �o�̓t�@�C�����̃��R�[�h�^�錾
  TYPE l_out_file_rtype IS RECORD(
      set_of_books_id     NUMBER               -- ����ID
    , je_source           VARCHAR2(25)         -- �d��\�[�X
    , file_name           VARCHAR2(100)        -- �t�@�C����
    , file_handle         UTL_FILE.FILE_TYPE   -- �t�@�C���n���h��
    , out_cnt             NUMBER               -- �o�͌���
  );
  -- �o�̓t�@�C�����̃e�[�u���^�錾
  TYPE l_out_file_ttype IS TABLE OF l_out_file_rtype INDEX BY BINARY_INTEGER;
  -- GLOIF��ROWID�̃e�[�u���^�錾
  TYPE l_gi_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_oic_out_file_dir     VARCHAR2(100);                                        -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  gv_dir_path             ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- �f�B���N�g���p�X  
-- Ver1.1 Del Start
--  l_out_file_tab          l_out_file_ttype;                                     -- �o�̓t�@�C�����e�[�u���ϐ�
-- Ver1.1 Del End
  l_gi_rowid_tab          l_gi_rowid_ttype;                                     -- GLOIF��ROWID�̃e�[�u���ϐ�
-- Ver1.1 Add Start
  l_out_sale_tab          l_out_file_ttype;                                     -- SALES�o�̓t�@�C�����e�[�u���ϐ�
  l_out_ifrs_tab          l_out_file_ttype;                                     -- IFRS�o�̓t�@�C�����e�[�u���ϐ�
  gn_divcnt               NUMBER := 0;                                          -- �t�@�C�������s��
  gv_fl_name_sales        XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- SALES�t�@�C����(�A�ԂȂ��g���q�Ȃ��j
  gv_fl_name_ifrs         XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE;              -- IFRS�t�@�C����(�A�ԂȂ��g���q�Ȃ��j
-- Ver1.3 Add Start
  gn_max_h_cnt_per_b      NUMBER := 0;                                          -- �d��o�b�`������d��w�b�_����
-- Ver1.3 Add End
--
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
    lv_msg          VARCHAR2(300)   DEFAULT NULL;   -- ���b�Z�[�W�o�͗p    
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
      gv_dir_path,
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
      of_file_hand := UTL_FILE.FOPEN( gv_dir_path                -- �f�B���N�g���p�X
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
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cfo                                         -- 'XXCFO'
                  , iv_name         => cv_msg_cfo1_60002                                      -- IF�t�@�C�����o�̓��b�Z�[�W
                  , iv_token_name1  => cv_tkn_file_name                                       -- �g�[�N��(FILE_NAME)
                  , iv_token_value1 => gv_dir_path || cv_msg_slash ||iv_output_file_name      -- OIC�A�g�Ώۂ̃t�@�C����
                );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
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
-- Ver1.4 Add Start
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
-- Ver1.4 Add End
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_execute_kbn      IN  VARCHAR2    -- ���s�敪
    , in_set_of_books_id  IN  NUMBER      -- ����ID
    , iv_je_source_name   IN  VARCHAR2    -- �d��\�[�X
    , iv_je_category_name IN  VARCHAR2    -- �d��J�e�S��
    , ov_errbuf           OUT VARCHAR2    -- �G���[�E���b�Z�[�W           # �Œ� #
    , ov_retcode          OUT VARCHAR2    -- ���^�[���E�R�[�h             # �Œ� #
    , ov_errmsg           OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg              VARCHAR2(300)   DEFAULT NULL;   -- ���b�Z�[�W�o�͗p    
    ln_exsist_cnt       NUMBER;                         -- OIC�A�g�Ώێd�󑶍݃`�F�b�N�p�ϐ�
    ln_out_file_tab_cnt NUMBER;                         -- �o�̓t�@�C�����J�E���g�p
    -- �t�@�C���o�͊֘A
    lb_fexists          BOOLEAN;                        -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                         -- �t�@�C���̒���
    ln_block_size       NUMBER;                         -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
-- Ver1.1 Add Start
    lv_fl_name          XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- �t�@�C����
    lv_fl_name_noext    XXCFO_OIC_TARGET_JOURNAL.FILE_NAME%TYPE := NULL;  -- �t�@�C�����i�g���q�Ȃ��j
    lf_file_hand        UTL_FILE.FILE_TYPE;                               -- �t�@�C���E�n���h��
-- Ver1.1 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
    -- OIC�A�g�Ώێd����擾
    CURSOR c_prog_journal_cur IS
      SELECT DISTINCT
          set_of_books_id    AS set_of_books_id   -- ����ID
-- Ver1.1 Add Start
         , name              AS name              -- ��v���떼
-- Ver1.1 Add End
        , je_source          AS je_source         -- �d��\�[�X
        , file_name          AS file_name         -- �t�@�C����
      FROM
        xxcfo_oic_target_journal xotj                                            -- OIC�A�g�Ώێd��e�[�u��
      WHERE
          xotj.if_pattern = cv_gloif_journal                                     -- �A�g�p�^�[���iGLOIF�d��̓]���j
      AND xotj.set_of_books_id = NVL(in_set_of_books_id,  xotj.set_of_books_id)  -- ����ID = ���̓p�����[�^�u����ID�v
      AND xotj.je_source       = iv_je_source_name                               -- �d��\�[�X = ���̓p�����[�^�u�d��\�[�X�v
      AND xotj.je_category     = NVL(iv_je_category_name, xotj.je_category)      -- �d��J�e�S�� = ���̓p�����[�^�u�d��J�e�S���v
      ;
--
    -- *** ���[�J���E���R�[�h ***
    c_journal_rec      c_prog_journal_cur%ROWTYPE;   -- OIC�A�g�Ώێd��e�[�u�� �J�[�\�����R�[�h�^
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
    -- A-1-1.���̓p�����[�^�`�F�b�N
    -- ==============================================================
--
    -- (1)���̓p�����[�^�o��
    -- ===================================================================
--
    -- 1.���s�敪
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                 , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                 , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                 , iv_token_value1 => cv_msgtkn_cfo1_60013     -- ���s�敪
                 , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                 , iv_token_value2 => iv_execute_kbn           -- �p�����[�^�F���s�敪
              );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 2.����ID
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo               -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001            -- �p�����[�^�o�̓��b�Z�[�W
                , iv_token_name1  => cv_tkn_param_name            -- �g�[�N��(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60014         -- ����ID
                , iv_token_name2  => cv_tkn_param_val             -- �g�[�N��(PARAM_VAL)
                , iv_token_value2 => TO_CHAR(in_set_of_books_id)  -- �p�����[�^�F����ID
              );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 3.�d��\�[�X
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60015     -- �d��\�[�X
                , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                , iv_token_value2 => iv_je_source_name        -- �p�����[�^�F�d��\�[�X
              );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
--
    -- 4.�d��J�e�S��
    lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_msg_kbn_cfo           -- 'XXCFO'
                , iv_name         => cv_msg_cfo1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                , iv_token_value1 => cv_msgtkn_cfo1_60016     -- �d��J�e�S��
                , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                , iv_token_value2 => iv_je_category_name      -- �p�����[�^�F�d��J�e�S��
              );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
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
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60009  -- �p�����[�^�K�{�G���[
                         , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                         , cv_msgtkn_cfo1_60013
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ���̓p�����[�^�u�d��\�[�X�v�������͂̏ꍇ�A�ȉ��̗�O�������s���B
    IF ( iv_je_source_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60009  -- �p�����[�^�K�{�G���[
                         , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                         , cv_msgtkn_cfo1_60015
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) ���̓p�����[�^�̕s���`�F�b�N
    -- ===================================================================
    -- ���̓p�����[�^�u���s�敪�v��'N', 'D'�ȊO�̏ꍇ�A�ȉ��̗�O�������s���B
    IF ( iv_execute_kbn NOT IN ( cv_execute_kbn_n , cv_execute_kbn_d ) ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_60010  -- �p�����[�^�s���G���[
                         , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                         , cv_msgtkn_cfo1_60013
                       )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (4) ���̓p�����[�^�̑g�ݍ��킹��OIC�A�g�Ώێd��ɑ��݂��邩�̃`�F�b�N
    -- ===================================================================
    SELECT
      COUNT(1) AS count
    INTO
      ln_exsist_cnt
    FROM
      xxcfo_oic_target_journal xotj                                       -- OIC�A�g�Ώێd��e�[�u��
    WHERE
        xotj.if_pattern      = cv_gloif_journal                           -- �A�g�p�^�[���iGLOIF�d��̓]���j
    AND xotj.set_of_books_id = NVL(in_set_of_books_id,  set_of_books_id)  -- ����ID = ���̓p�����[�^�u����ID�v
    AND xotj.je_source       = iv_je_source_name                          -- �d��\�[�X = ���̓p�����[�^�u�d��\�[�X�v
    AND xotj.je_category     = NVL(iv_je_category_name, je_category)      -- �d��J�e�S�� = ���̓p�����[�^�u�d��J�e�S���v
    ;
--
    -- �g�ݍ��킹��OIC�A�g�Ώێd��ɑ��݂��Ȃ��ꍇ�A�ȉ��̗�O�������s���B
    IF ( ln_exsist_cnt = 0 ) THEN
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
    gv_oic_out_file_dir := FND_PROFILE.VALUE( cv_oic_out_file_dir );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_oic_out_file_dir IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                         , cv_tkn_prof_name   -- �g�[�N��'PROF_NAME'
                         , cv_oic_out_file_dir
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1 Add Start
    -- 2.�v���t�@�C������XXCFO:OIC�A�g�����s���iGLOIF�j�擾
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
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                         , cv_tkn_prof_name   -- �g�[�N��'PROF_NAME'
                         , cv_div_cnt
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.1 Add End
--
-- Ver1.3 Add Start
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
      lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo     -- 'XXCFO'
                         , cv_msg_cfo1_00001  -- �v���t�@�C���擾�G���[
                         , cv_tkn_prof_name   -- �g�[�N��'PROF_NAME'
                         , cv_prf_max_h_cnt_per_b
                       )
                     , 1
                     , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
-- Ver1.3 Add End
--
    -- ====================================================================================================
    -- A-1-3�D�v���t�@�C���l�uXXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v����f�B���N�g���p�X���擾����
    -- ====================================================================================================
--
    BEGIN
      SELECT
        RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- �f�B���N�g���p�X
      INTO
        gv_dir_path
      FROM
        all_directories  ad
      WHERE
        ad.directory_name = gv_oic_out_file_dir                         -- �v���t�@�C���l�uXXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(
                           cv_msg1
                        || xxccp_common_pkg.get_msg(
                               cv_msg_kbn_coi         -- 'XXCOI'
                             , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                             , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                             , gv_oic_out_file_dir    -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                           )
                       , 1
                       , 5000
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
    -- directory_name�͓o�^����Ă��邪�Adirectory_path���󔒂̎�
    IF ( gv_dir_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(
                          cv_msg2
                       || xxccp_common_pkg.get_msg(
                              cv_msg_kbn_coi         -- 'XXCOI'
                            , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                            , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                            , gv_oic_out_file_dir    -- XXCFO:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                          )
                     , 1
                     , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =================================
    -- A-1-4�D�o�̓t�@�C�����I�[�v������
    -- =================================
    -- (1) ���̓p�����[�^�������ɏo�̓t�@�C������OIC�A�g�Ώێd��e�[�u������擾����B
    OPEN c_prog_journal_cur;
--
    -- (2) ��L(1)�Ŏ擾�������R�[�h�����ȉ��̏������J��Ԃ��B
    ln_out_file_tab_cnt := 1;
-- Ver1.1 Add Start
    -- �e��v����̏o�̓t�@�C������������
    gv_fl_name_sales := NULL;
    gv_fl_name_ifrs := NULL;
-- Ver1.1 Add End
    <<data1_loop>>
    LOOP
      FETCH c_prog_journal_cur INTO c_journal_rec;
      EXIT WHEN c_prog_journal_cur%NOTFOUND;
-- Ver1.1 Del Start
--      -- �o�̓t�@�C�����e�[�u���ϐ��ɒl���i�[����B
--      l_out_file_tab(ln_out_file_tab_cnt).set_of_books_id := c_journal_rec.set_of_books_id; -- ����ID
--      l_out_file_tab(ln_out_file_tab_cnt).je_source       := c_journal_rec.je_source;       -- �d��\�[�X
--      l_out_file_tab(ln_out_file_tab_cnt).file_name       := c_journal_rec.file_name;       -- �t�@�C����
--      l_out_file_tab(ln_out_file_tab_cnt).out_cnt         := 0;                             -- �o�͌���
--      -- (2-1) �t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B
--      lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_msg_kbn_cfo                                         -- 'XXCFO'
--                  , iv_name         => cv_msg_cfo1_60002                                      -- IF�t�@�C�����o�̓��b�Z�[�W
--                  , iv_token_name1  => cv_tkn_file_name                                       -- �g�[�N��(FILE_NAME)
--                  , iv_token_value1 => gv_dir_path || cv_msg_slash ||c_journal_rec.file_name  -- OIC�A�g�Ώۂ̃t�@�C����
--                );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msg
--      );
-- Ver1.1 Del End
--
-- Ver1.1 Add Start
      -- �t�@�C����
      lv_fl_name_noext := SUBSTRB(c_journal_rec.file_name, 1, INSTR(c_journal_rec.file_name, cv_extension) -1);
      lv_fl_name := lv_fl_name_noext || '_' || TO_CHAR(1, cv_fmt_fileno) || cv_extension;
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
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (2-2) ���ɓ���t�@�C�������݂��Ă��Ȃ����̃`�F�b�N���s���B
--      UTL_FILE.FGETATTR(
--          gv_oic_out_file_dir
--        , c_journal_rec.file_name                            -- OIC�A�g�Ώۂ̃t�@�C����
--        , lb_fexists
--        , ln_file_size
--        , ln_block_size
--      );
--      -- ����t�@�C�����݃G���[���b�Z�[�W
--      IF ( lb_fexists ) THEN
--        -- ��s�}��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => ''
--        );
--        lv_errmsg := SUBSTRB(
--                         xxccp_common_pkg.get_msg(
--                             cv_msg_kbn_cfo     -- 'XXCFO'
--                           , cv_msg_cfo1_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
--                         )
--                       , 1
--                       , 5000
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--      END IF;
----
--      -- (2-3) �t�@�C���I�[�v�����s���B
--      BEGIN
--        l_out_file_tab(ln_out_file_tab_cnt).file_handle := UTL_FILE.FOPEN(
--                                                               gv_oic_out_file_dir        -- �f�B���N�g���p�X
--                                                             , c_journal_rec.file_name    -- �t�@�C����
--                                                             , cv_open_mode_w             -- �I�[�v�����[�h
--                                                             , cn_max_linesize            -- �t�@�C���s�T�C�Y
--                                                           );
----
--      EXCEPTION
--        -- ��O�F�t�@�C����������
--        WHEN UTL_FILE.INVALID_FILENAME THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        -- ��O�F�t�@�C�����I�[�v���ł��Ȃ�
--        WHEN UTL_FILE.INVALID_OPERATION THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        -- ��O�F���̑�
--        WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB(
--                           xxccp_common_pkg.get_msg(
--                               cv_msg_kbn_cfo      -- 'XXCFO'
--                             , cv_msg_cfo1_00029   -- �t�@�C���I�[�v���G���[
--                           )
--                         , 1
--                         , 5000
--                       );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--      ln_out_file_tab_cnt := ln_out_file_tab_cnt + 1;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
   * Procedure Name   : output_gloif
   * Description      : �A�g�f�[�^���o����,I/F�t�@�C���o�͏���(A-2,A-3)
   ***********************************************************************************/
  PROCEDURE output_gloif(
      in_set_of_books_id  IN  NUMBER      -- ����ID
    , iv_je_source_name   IN  VARCHAR2    -- �d��\�[�X
    , iv_je_category_name IN  VARCHAR2    -- �d��J�e�S��
    , ov_errbuf           OUT VARCHAR2    -- �G���[�E���b�Z�[�W           # �Œ� #
    , ov_retcode          OUT VARCHAR2    -- ���^�[���E�R�[�h             # �Œ� #
    , ov_errmsg           OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2 (100) := 'output_gloif'; -- �v���O������
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
    ln_cnt              NUMBER := 0;                      -- ����
    ln_out_file_tab_cnt NUMBER;                           -- �o�̓t�@�C�����e�[�u���ϐ��Y��
    lv_file_data        VARCHAR2(30000)   DEFAULT NULL;   -- �o�͂P�s��������ϐ�
    ln_set_of_books_id  xxcfo_oic_target_journal.set_of_books_id%TYPE;
    lv_je_source        xxcfo_oic_target_journal.je_source%TYPE;
    lv_je_creation_date VARCHAR2(100);                    -- ���ݓ����iUTC�j
-- Ver1.1 Add Start
    ln_out_file_idx     NUMBER;                                   -- �o�̓t�@�C��Index
    ln_out_line         NUMBER;                                   -- �t�@�C�����o�͍s��
    lv_cur_sob          xxcfo_oic_target_journal.name%TYPE;       -- ��v���떼
    lv_file_name        xxcfo_oic_target_journal.file_name%TYPE;  -- �o�̓t�@�C�����i�A�ԕt���j
    lf_file_handle      UTL_FILE.FILE_TYPE;                       -- �o�̓t�@�C���n���h��
    lv_je_category_name gl_interface.user_je_category_name%TYPE;  -- �d��J�e�S��
    lv_period_name      gl_interface.period_name%TYPE;            -- ��v����
    lv_currency_code    gl_interface.currency_code%TYPE;          -- �ʉ݃R�[�h
    lv_actual_flag      gl_interface.actual_flag%TYPE;            -- �c���^�C�v
    lv_accounting_date  VARCHAR2(30);                             -- �L����
    ln_group_id         gl_interface.group_id%TYPE;               -- �O���[�vID
-- Ver1.1 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
  CURSOR c_outbound_data1_cur IS
    SELECT
        gi.rowid                                             AS row_id                        --  1.ROWID
      , gi.status                                            AS status                        --  2.�X�e�[�^�X
      , TO_CHAR(gi.accounting_date, cv_date_ymd)             AS accounting_date               --  3.�L����
      , gjs.je_source_name                                   AS je_source_name                --  4.�d��\�[�X
      , gi.user_je_category_name                             AS user_je_category_name         --  5.�d��J�e�S��
      , gjs.attribute2                                       AS cloud_source                  --  6.ERP Cloud�d��\�[�X
      , gi.currency_code                                     AS currency_code                 --  7.�ʉ�
      , gi.actual_flag                                       AS actual_flag                   --  8.�c���^�C�v
      , gi.code_combination_id                               AS code_combination_id           --  9.�R�[�h�g����ID
-- Ver 1.2 Mod Start
--      , gi.segment1                                          AS segment1                      -- 10.���
--      , gi.segment2                                          AS segment2                      -- 11.����
--      , gi.segment3                                          AS segment3                      -- 12.����Ȗ�
--      , gi.segment3 || gi.segment4                           AS segment34                     -- 13.�⏕�Ȗ�
--      , gi.segment5                                          AS segment5                      -- 14.�ڋq�R�[�h
--      , gi.segment6                                          AS segment6                      -- 15.��ƃR�[�h
--      , gi.segment7                                          AS segment7                      -- 16.�\���P
--      , gi.segment8                                          AS segment8                      -- 17.�\���Q
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment1
           ELSE
             gi.segment1
         END)                                                AS segment1                      -- 10.���
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment2
           ELSE
             gi.segment2
         END)                                                AS segment2                      -- 11.����
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment3
           ELSE
             gi.segment3
         END)                                                AS segment3                      -- 12.����Ȗ�
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment3 || gcc.segment4
           ELSE
             gi.segment3 || gi.segment4
         END)                                                AS segment34                     -- 13.�⏕�Ȗ�
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment5
           ELSE
             gi.segment5
         END)                                                AS segment5                      -- 14.�ڋq�R�[�h
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment6
           ELSE
             gi.segment6
         END)                                                AS segment6                      -- 15.��ƃR�[�h
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment7
           ELSE
             gi.segment7
         END)                                                AS segment7                      -- 16.�\���P
      , (CASE
           WHEN gi.code_combination_id IS NOT NULL THEN
             gcc.segment8
           ELSE
             gi.segment8
         END)                                                AS segment8                      -- 17.�\���Q
-- Ver 1.2 Mod End
      , gi.entered_dr                                        AS entered_dr                    -- 18.�ؕ����z
      , gi.entered_cr                                        AS entered_cr                    -- 19.�ݕ����z
      , gi.accounted_dr                                      AS accounted_dr                  -- 20.���Z��ؕ����z
      , gi.accounted_cr                                      AS accounted_cr                  -- 21.���Z��ݕ����z
-- Ver1.3 Mod Start
--      , gi.reference1                                        AS reference1                    -- 22.�o�b�`��
      , gi.reference1 || ' ' ||
          TO_CHAR(
            TRUNC(
              (DENSE_RANK() OVER(PARTITION BY gi.reference1 ORDER BY gi.reference1, gi.reference4) - 1)
              / gn_max_h_cnt_per_b
            ) + 1
          )                                                  AS reference1                    -- 22.�o�b�`��
-- Ver1.3 Mod End
      , gi.reference2                                        AS reference2                    -- 23.�o�b�`�E�v
      , gi.reference4                                        AS reference4                    -- 24.�d��
      , gi.reference5                                        AS reference5                    -- 25.�d��E�v
      , gi.reference10                                       AS reference10                   -- 26.�d�󖾍דE�v
      , gi.user_currency_conversion_type                     AS user_currency_conversion_type -- 27.���Z�^�C�v
      , TO_CHAR( gi.currency_conversion_date , cv_date_ymd ) AS currency_conversion_date      -- 28.���Z��
      , gi.currency_conversion_rate                          AS currency_conversion_rate      -- 29.���Z���[�g
      , gi.group_id                                          AS group_id                      -- 30.�O���[�vID
      , gi.set_of_books_id                                   AS set_of_books_id               -- 31.��v����ID
      , gi.attribute1                                        AS attribute1                    -- 32.����ŃR�[�h
      , gi.attribute2                                        AS attribute2                    -- 33.�������R
      , gi.attribute3                                        AS attribute3                    -- 34.�`�[�ԍ�
      , gi.attribute4                                        AS attribute4                    -- 35.�N�[����
      , gi.attribute6                                        AS attribute6                    -- 36.�C�����`�[�ԍ�
      , gi.attribute8                                        AS attribute8                    -- 37.�̔����уw�b�_ID
      , gi.attribute9                                        AS attribute9                    -- 38.�g�c���ٔԍ�
      , gi.attribute5                                        AS attribute5                    -- 39.���[�UID
      , gi.attribute7                                        AS attribute7                    -- 40.�\���P
      , gi.attribute10                                       AS attribute10                   -- 41.�d�q�f�[�^���
      , gi.jgzz_recon_ref                                    AS jgzz_recon_ref                -- 42.�����Q��
      , gsob.name                                            AS name                          -- 43.��v���떼
      , gi.period_name                                       AS period_name                   -- 44.��v���Ԗ�
    FROM
        gl_interface              gi                                                          -- GLOIF
      , gl_sets_of_books          gsob                                                        -- ��v����
      , gl_je_sources             gjs                                                         -- �d��\�[�X
      , gl_je_categories          gjc                                                         -- �d��J�e�S��
      , xxcfo_oic_target_journal  xotj                                                        -- OIC�A�g�Ώێd��e�[�u��
-- Ver 1.2 Add Start
      , gl_code_combinations      gcc                                                         -- ����Ȗڑg����
-- Ver 1.2 Add End
    WHERE
        gi.status                = cv_status_code                                             -- �X�e�[�^�X:NEW
    AND gi.set_of_books_id       = gsob.set_of_books_id                                       -- ��v����ID
    AND gi.user_je_source_name   = gjs.user_je_source_name                                    -- ���[�U�d��\�[�X��
    AND gi.user_je_category_name = gjc.user_je_category_name                                  -- ���[�U�d��J�e�S����
    AND gi.set_of_books_id       = xotj.set_of_books_id                                       -- ����ID
    AND gi.user_je_source_name   = xotj.je_source_name                                        -- ���[�U�d��\�[�X��
    AND gi.user_je_category_name = xotj.je_category_name                                      -- ���[�U�d��J�e�S����
-- Ver 1.2 Add Start
    AND gi.code_combination_id   = gcc.code_combination_id(+)                                 -- ����Ȗڑg����ID
-- Ver 1.2 Add End
    AND xotj.if_pattern          = cv_gloif_journal                                           -- �A�g�p�^�[�� :GLOIF�d�󒊏o
    AND xotj.set_of_books_id     = NVL( in_set_of_books_id , xotj.set_of_books_id)            -- ����ID = ���̓p�����[�^�u����ID�v
    AND xotj.je_source           = iv_je_source_name                                          -- �d��\�[�X = ���̓p�����[�^�u�d��\�[�X�v
    AND xotj.je_category         = NVL( iv_je_category_name , xotj.je_category)               -- �d��J�e�S�� = ���̓p�����[�^�u�d��J�e�S���v
    ORDER BY
        gi.set_of_books_id                                                                    -- ����ID
-- Ver1.1 Add Start
      , gi.period_name                                                                        -- ��v����
-- Ver1.1 Add End
      , gjs.je_source_name                                                                    -- �d��\�[�X
      , gjc.je_category_name                                                                  -- �d��J�e�S��
-- Ver1.1 Add Start
      , gi.currency_code                                                                      -- �ʉ�
      , gi.actual_flag                                                                        -- �c���^�C�v
      , gi.accounting_date                                                                    -- �L����
-- Ver1.1 Add End
    FOR UPDATE OF gi.status NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data1_rec      c_outbound_data1_cur%ROWTYPE;           -- GLOIF�d��擾
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
    -- A-2-1�D�V�K�o�^���ꂽGLOIF�d��̒��o
    -- =================================
    OPEN c_outbound_data1_cur;
--
    -- =================================
    -- A-3-1�DI/F�t�@�C���o�͏���
    -- =================================
    --
    lv_je_creation_date := TO_CHAR(SYS_EXTRACT_UTC(CURRENT_TIMESTAMP), cv_date_ymd );
-- Ver1.1 Add Start
    ln_out_file_idx := 0;             -- �o�̓t�@�C��Index
    ln_out_line := 0;                 -- �t�@�C�����o�͍s��
    lv_cur_sob := ' ';                -- ���݉�v���떼
    ln_group_id := cn_init_group_id;  -- �O���[�vID
-- Ver1.1 Add End
    --
    <<main_loop>>
    LOOP
      FETCH c_outbound_data1_cur INTO l_data1_rec;
      EXIT WHEN c_outbound_data1_cur%NOTFOUND;
-- Ver1.1 Add Start
      -- ��v���떼���؂�ւ�����ꍇ
      IF l_data1_rec.name <> lv_cur_sob THEN
        --���݉�v���떼��ݒ�
        lv_cur_sob := l_data1_rec.name;
        -- �ϐ�������
        ln_out_line := 0;                -- �t�@�C�����o�͍s��������
        ln_out_file_idx := 1;            -- �o�̓t�@�C��Index������
        ln_group_id := ln_group_id + 1;  -- �O���[�vID
      ELSE
        -- �����s���������Ă���
        -- ��v����ID�A��v���ԁA�d��\�[�X���A�d��J�e�S���A�ʉ݃R�[�h�A���уt���O�A�d��v���
        -- ���ς�����ꍇ�A�o�̓t�@�C����؂�ւ���
        IF ln_out_line >= gn_divcnt
        AND (
             ln_set_of_books_id   <> l_data1_rec.set_of_books_id        -- ����ID
          OR lv_period_name       <> l_data1_rec.period_name            -- ��v����
          OR lv_je_source         <> l_data1_rec.je_source_name         -- �d��\�[�X
          OR lv_je_category_name  <> l_data1_rec.user_je_category_name  -- �d��J�e�S���[
          OR lv_currency_code     <> l_data1_rec.currency_code          -- �ʉ݃R�[�h
          OR lv_actual_flag       <> l_data1_rec.actual_flag            -- �c���^�C�v
          OR lv_accounting_date   <> l_data1_rec.accounting_date        -- �L����
        ) THEN
          -- �ϐ�������
          ln_out_line := 0;                        -- �t�@�C�����o�͍s��������
          ln_out_file_idx := ln_out_file_idx + 1;  -- �o�̓t�@�C��Index��+1
          ln_group_id := ln_group_id + 1;          -- �O���[�vID
--
          -- �V�����o�̓t�@�C�����i�A�Ԃ���j��ݒ�
          IF l_data1_rec.name = cv_sales_sob THEN
            lv_file_name := gv_fl_name_sales;
          ELSE
            lv_file_name := gv_fl_name_ifrs;
          END IF;
          lv_file_name := lv_file_name || '_' || TO_CHAR(ln_out_file_idx, cv_fmt_fileno) || cv_extension;
--
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
          IF l_data1_rec.name = cv_sales_sob THEN
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
      IF l_data1_rec.name = cv_sales_sob THEN
        l_out_sale_tab(ln_out_file_idx).out_cnt := l_out_sale_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_sale_tab(ln_out_file_idx).file_handle;
      ELSE
        l_out_ifrs_tab(ln_out_file_idx).out_cnt := l_out_ifrs_tab(ln_out_file_idx).out_cnt + 1;
        lf_file_handle := l_out_ifrs_tab(ln_out_file_idx).file_handle;
      END IF;
--
      -- �L�[�u���[�N���ڂ�ۑ�
      ln_set_of_books_id   := l_data1_rec.set_of_books_id;        -- ����ID
      lv_period_name       := l_data1_rec.period_name;            -- ��v����
      lv_je_source         := l_data1_rec.je_source_name;         -- �d��\�[�X
      lv_je_category_name  := l_data1_rec.user_je_category_name;  -- �d��J�e�S���[
      lv_currency_code     := l_data1_rec.currency_code;          -- �ʉ݃R�[�h
      lv_actual_flag       := l_data1_rec.actual_flag;            -- �c���^�C�v
      lv_accounting_date   := l_data1_rec.accounting_date;        -- �L����
-- Ver1.1 Add End
-- Ver1.1 Del Start
--      -- (1) �Ώۃf�[�^�́u����ID�v�A�u�d��\�[�X�v����A�o�̓t�@�C���n���h�����擾����B
--      ln_set_of_books_id := l_data1_rec.set_of_books_id; -- ����ID
--      lv_je_source       := l_data1_rec.je_source_name;  -- �d��\�[�X
--      -- ������
--      ln_out_file_tab_cnt := 1;
--      <<target_file_loop>>
--      LOOP
--        IF ( 
--             ( ln_set_of_books_id = l_out_file_tab(ln_out_file_tab_cnt).set_of_books_id )
--             AND
--             ( lv_je_source = l_out_file_tab(ln_out_file_tab_cnt).je_source )
--            ) THEN
--          EXIT;
--        END IF;
--        ln_out_file_tab_cnt := ln_out_file_tab_cnt + 1;
--      END LOOP target_file_loop;
-- Ver1.1 Del End
      -- �Ώۃf�[�^�����J�E���g
      gn_target_cnt := gn_target_cnt + 1 ;
      -- (2) �擾�����t�@�C���n���h���ɂāA�t�@�C���o�͂���B
      -- �ϐ��̏�����
      lv_file_data := NULL;
      -- �f�[�^�ҏW
      lv_file_data := cv_status_code;                                                                                                               --   1.*Status Code
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --   2.*Ledger ID
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounting_date;                                                                --   3.*Effective Date of Transaction
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.cloud_source , cv_space );                   --   4.*Journal Source
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.user_je_category_name , cv_space );          --   5.*Journal Category
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.currency_code , cv_space );                  --   6.*Currency Code
      lv_file_data := lv_file_data || cv_delim_comma || lv_je_creation_date;                                                                                    --   7.*Journal Entry Creation Date
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.actual_flag , cv_space );                    --   8.*Actual Flag
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment1 , cv_space );                       --   9.Segment1
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment2 , cv_space );                       --  10.Segment2
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment3 , cv_space );                       --  11.Segment3
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment34 , cv_space );                      --  12.Segment4
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment5 , cv_space );                       --  13.Segment5
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment6 , cv_space );                       --  14.Segment6
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment7 , cv_space );                       --  15.Segment7
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.segment8 , cv_space );                       --  16.Segment8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  17.Segment9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  18.Segment10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  19.Segment11
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  20.Segment12
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  21.Segment13
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  22.Segment14
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  23.Segment15
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  24.Segment16
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  25.Segment17
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  26.Segment18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  27.Segment19
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  28.Segment20
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  29.Segment21
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  30.Segment22
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  31.Segment23
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  32.Segment24
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  33.Segment25
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  34.Segment26
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  35.Segment27
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  36.Segment28
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  37.Segment29
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  38.Segment30
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.entered_dr ;                                                                    --  39.Entered Debit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.entered_cr ;                                                                    --  40.Entered Credit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounted_dr ;                                                                  --  41.Converted Debit Amount
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.accounted_cr ;                                                                  --  42.Converted Credit Amount
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference1 , cv_space );                     --  43.REFERENCE1 (Batch Name)
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference2 , cv_space );                     --  44.REFERENCE2 (Batch Description)
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.reference2 , cv_lf_str );                                        --  44.REFERENCE2 (Batch Description)
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  45.REFERENCE3
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference4 , cv_space );                     --  46.REFERENCE4 (Journal Entry Name)
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference5 , cv_space );                     --  47.REFERENCE5 (Journal Entry Description)
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.reference5 , cv_lf_str );                                        --  47.REFERENCE5 (Journal Entry Description)
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  48.REFERENCE6 (Journal Entry Reference)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  49.REFERENCE7 (Journal Entry Reversal flag)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  50.REFERENCE8 (Journal Entry Reversal Period)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  51.REFERENCE9 (Journal Reversal Method)
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.reference10 , cv_space );                    --  52.REFERENCE10 (Journal Entry Line Description)
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  53.Reference column 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  54.Reference column 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  55.Reference column 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  56.Reference column 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  57.Reference column 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  58.Reference column 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  59.Reference column 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  60.Reference column 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  61.Reference column 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  62.Reference column 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  63.Statistical Amount
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.user_currency_conversion_type , cv_space );  --  64.Currency Conversion Type
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.currency_conversion_date ;                                                      --  65.Currency Conversion Date
      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.currency_conversion_rate ;                                                      --  66.Currency Conversion Rate
-- Ver1.1 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || l_data1_rec.group_id ;                                                                      --  67.Interface Group Identifier
      lv_file_data := lv_file_data || cv_delim_comma || ln_group_id;                                                                                --  67.Interface Group Identifier
-- Ver1.1 Mod End
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  68.Context field for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute1 , cv_space );                     --  69.ATTRIBUTE1 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute2 , cv_space );                     --  70.ATTRIBUTE2 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute3 , cv_space );                     --  71.Attribute3 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute4 , cv_space );                     --  72.Attribute4 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute6 , cv_space );                     --  73.Attribute5 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute8 , cv_space );                     --  74.Attribute6 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute9 , cv_space );                     --  75.Attribute7 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute5 , cv_space );                     --  76.Attribute8 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute7 , cv_space );                     --  77.Attribute9 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.attribute10 , cv_space );                    --  78.Attribute10 Value for Journal Entry Line DFF
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.jgzz_recon_ref , cv_space );                  --  79.Attribute11 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.name , cv_lf_str );                                              --  68.Context field for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute1 , cv_lf_str );                                        --  69.ATTRIBUTE1 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute2 , cv_lf_str );                                        --  70.ATTRIBUTE2 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute3 , cv_lf_str );                                        --  71.Attribute3 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute4 , cv_lf_str );                                        --  72.Attribute4 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute6 , cv_lf_str );                                        --  73.Attribute5 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute8 , cv_lf_str );                                        --  74.Attribute6 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute9 , cv_lf_str );                                        --  75.Attribute7 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute5 , cv_lf_str );                                        --  76.Attribute8 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute7 , cv_lf_str );                                        --  77.Attribute9 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.attribute10 , cv_lf_str );                                       --  78.Attribute10 Value for Journal Entry Line DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.jgzz_recon_ref , cv_lf_str );                                    --  79.Attribute11 Value for Captured Information DFF
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  80.Attribute12 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  81.Attribute13 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  82.Attribute14 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  83.Attribute15 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  84.Attribute16 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  85.Attribute17 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  86.Attribute18 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  87.Attribute19 Value for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  88.Attribute20 Value for Captured Information DFF
      -- Ver1.4 Mod Start
--      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  89.Context field for Captured Information DFF
      lv_file_data := lv_file_data || cv_delim_comma || to_csv_string( l_data1_rec.name , cv_lf_str );                                              --  89.Context field for Captured Information DFF
      -- Ver1.4 Mod End
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  90.Average Journal Flag
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  91.Clearing Company
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.name , cv_space );                           --  92.Ledger Name
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  93.Encumbrance Type ID
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  94.Reconciliation Reference
      lv_file_data := lv_file_data || cv_delim_comma || xxccp_oiccommon_pkg.to_csv_string( l_data1_rec.period_name , cv_space );                    --  95.Period Name
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  96.REFERENCE 18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  97.REFERENCE 19
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  98.REFERENCE 20
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       --  99.Attribute Date 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 100.Attribute Date 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 101.Attribute Date 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 102.Attribute Date 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 103.Attribute Date 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 104.Attribute Date 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 105.Attribute Date 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 106.Attribute Date 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 107.Attribute Date 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 108.Attribute Date 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 109.Attribute Number 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 110.Attribute Number 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 111.Attribute Number 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 112.Attribute Number 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 113.Attribute Number 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 114.Attribute Number 6
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 115.Attribute Number 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 116.Attribute Number 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 117.Attribute Number 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 118.Attribute Number 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 119.Global Attribute Category
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 120.Global Attribute 1 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 121.Global Attribute 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 122.Global Attribute 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 123.Global Attribute 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 124.Global Attribute 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 125.Global Attribute 6 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 126.Global Attribute 7
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 127.Global Attribute 8
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 128.Global Attribute 9
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 129.Global Attribute 10
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 130.Global Attribute 11
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 131.Global Attribute 12
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 132.Global Attribute 13
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 133.Global Attribute 14
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 134.Global Attribute 15
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 135.Global Attribute 16
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 136.Global Attribute 17
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 137.Global Attribute 18
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 138.Global Attribute 19 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 139.Global Attribute 20 
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 140.Global Attribute Date 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 141.Global Attribute Date 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 142.Global Attribute Date 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 143.Global Attribute Date 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 144.Global Attribute Date 5
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 145.Global Attribute Number 1
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 146.Global Attribute Number 2
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 147.Global Attribute Number 3
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 148.Global Attribute Number 4
      lv_file_data := lv_file_data || cv_delim_comma || NULL;                                                                                       -- 149.Global Attribute Number 5
--
      -- �t�@�C��������
      BEGIN
        UTL_FILE.PUT_LINE(
-- Ver1.1 Mod Start
--            l_out_file_tab(ln_out_file_tab_cnt).file_handle
            lf_file_handle
-- Ver1.1 Mod End
          , lv_file_data
        );
        -- �o�͌����J�E���g
-- Ver1.1 Del Start
--        l_out_file_tab(ln_out_file_tab_cnt).out_cnt :=l_out_file_tab(ln_out_file_tab_cnt).out_cnt + 1;
-- Ver1.1 Del End
        gn_normal_cnt := gn_normal_cnt + 1;
        -- �Ώۃf�[�^��ROWID���擾����B
        l_gi_rowid_tab(gn_normal_cnt) := l_data1_rec.row_id;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg :=  SUBSTRB(
                            xxccp_common_pkg.get_msg(
                                cv_msg_kbn_cfo      -- 'XXCFO'
                              , cv_msg_cfo1_00030    -- �t�@�C���������݃G���[
                            )   
                          , 1
                          , 5000
                        );
          lv_errbuf := lv_errmsg || SQLERRM;
          -- �t�@�C�����N���[�Y
          UTL_FILE.FCLOSE(
-- Ver1.1 Mod Start
--            l_out_file_tab(ln_out_file_tab_cnt).file_handle
            lf_file_handle
-- Ver1.1 Mod End
          );
          RAISE global_process_expt;
      END;
    END LOOP main_loop;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfo            -- 'XXCFO'
                     , iv_name         => cv_msg_cfo1_00019         -- ���b�N�G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTARGET
                     , iv_token_value1 => cv_msgtkn_cfo1_60020      -- �g�[�N���l1�FGLOIF
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
  END output_gloif;
--
  /**********************************************************************************
   * Procedure Name   : bkup_oic_gloif
   * Description      : �o�b�N�A�b�v����(A-4)
   ***********************************************************************************/
  PROCEDURE bkup_oic_gloif (
      ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           # �Œ� #
    , ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             # �Œ� #
    , ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bkup_oic_gloif'; -- �v���O������
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
    -- A-2�Ŏ擾�������o�f�[�^��1�����擾���A�ȉ��̏������J��Ԃ��s���B
    <<bkup_loop>>
    FOR i IN 1..l_gi_rowid_tab.COUNT LOOP
      -- =================================
      -- A-4-1�DOIC_GLOIF�o�b�N�A�b�v�e�[�u���o�^����
      -- =================================
      BEGIN
        INSERT INTO xxcfo_oic_gloif_bkup (
            status                            --   1.Status
          , set_of_books_id                   --   2.Set Of Books Id
          , accounting_date                   --   3.Accounting Date
          , currency_code                     --   4.Currency Code
          , date_created                      --   5.Date Created
          , created_by                        --   6.Created By
          , actual_flag                       --   7.Actual Flag
          , user_je_category_name             --   8.User Je Category Name
          , user_je_source_name               --   9.User Je Source Name
          , currency_conversion_date          --  10.Currency Conversion Date
          , encumbrance_type_id               --  11.Encumbrance Type Id
          , budget_version_id                 --  12.Budget Version Id
          , user_currency_conversion_type     --  13.User Currency Conversion Type
          , currency_conversion_rate          --  14.Currency Conversion Rate
          , average_journal_flag              --  15.Average Journal Flag
          , originating_bal_seg_value         --  16.Originating Bal Seg Value
          , segment1                          --  17.Segment1
          , segment2                          --  18.Segment2
          , segment3                          --  19.Segment3
          , segment4                          --  20.Segment4
          , segment5                          --  21.Segment5
          , segment6                          --  22.Segment6
          , segment7                          --  23.Segment7
          , segment8                          --  24.Segment8
          , segment9                          --  25.Segment9
          , segment10                         --  26.Segment10
          , segment11                         --  27.Segment11
          , segment12                         --  28.Segment12
          , segment13                         --  29.Segment13
          , segment14                         --  30.Segment14
          , segment15                         --  31.Segment15
          , segment16                         --  32.Segment16
          , segment17                         --  33.Segment17
          , segment18                         --  34.Segment18
          , segment19                         --  35.Segment19
          , segment20                         --  36.Segment20
          , segment21                         --  37.Segment21
          , segment22                         --  38.Segment22
          , segment23                         --  39.Segment23
          , segment24                         --  40.Segment24
          , segment25                         --  41.Segment25
          , segment26                         --  42.Segment26
          , segment27                         --  43.Segment27
          , segment28                         --  44.Segment28
          , segment29                         --  45.Segment29
          , segment30                         --  46.Segment30
          , entered_dr                        --  47.Entered Dr
          , entered_cr                        --  48.Entered Cr
          , accounted_dr                      --  49.Accounted Dr
          , accounted_cr                      --  50.Accounted Cr
          , transaction_date                  --  51.Transaction Date
          , reference1                        --  52.Reference1
          , reference2                        --  53.Reference2
          , reference3                        --  54.Reference3
          , reference4                        --  55.Reference4
          , reference5                        --  56.Reference5
          , reference6                        --  57.Reference6
          , reference7                        --  58.Reference7
          , reference8                        --  59.Reference8
          , reference9                        --  60.Reference9
          , reference10                       --  61.Reference10
          , reference11                       --  62.Reference11
          , reference12                       --  63.Reference12
          , reference13                       --  64.Reference13
          , reference14                       --  65.Reference14
          , reference15                       --  66.Reference15
          , reference16                       --  67.Reference16
          , reference17                       --  68.Reference17
          , reference18                       --  69.Reference18
          , reference19                       --  70.Reference19
          , reference20                       --  71.Reference20
          , reference21                       --  72.Reference21
          , reference22                       --  73.Reference22
          , reference23                       --  74.Reference23
          , reference24                       --  75.Reference24
          , reference25                       --  76.Reference25
          , reference26                       --  77.Reference26
          , reference27                       --  78.Reference27
          , reference28                       --  79.Reference28
          , reference29                       --  80.Reference29
          , reference30                       --  81.Reference30
          , je_batch_id                       --  82.Je Batch Id
          , period_name                       --  83.Period Name
          , je_header_id                      --  84.Je Header Id
          , je_line_num                       --  85.Je Line Num
          , chart_of_accounts_id              --  86.Chart Of Accounts Id
          , functional_currency_code          --  87.Functional Currency Code
          , code_combination_id               --  88.Code Combination Id
          , date_created_in_gl                --  89.Date Created In Gl
          , warning_code                      --  90.Warning Code
          , status_description                --  91.Status Description
          , stat_amount                       --  92.Stat Amount
          , group_id                          --  93.Group Id
          , request_id                        --  94.Request Id
          , subledger_doc_sequence_id         --  95.Subledger Doc Sequence Id
          , subledger_doc_sequence_value      --  96.Subledger Doc Sequence Value
          , attribute1                        --  97.Attribute1
          , attribute2                        --  98.Attribute2
          , gl_sl_link_id                     --  99.Gl Sl Link Id
          , gl_sl_link_table                  -- 100.Gl Sl Link Table
          , attribute3                        -- 101.Attribute3
          , attribute4                        -- 102.Attribute4
          , attribute5                        -- 103.Attribute5
          , attribute6                        -- 104.Attribute6
          , attribute7                        -- 105.Attribute7
          , attribute8                        -- 106.Attribute8
          , attribute9                        -- 107.Attribute9
          , attribute10                       -- 108.Attribute10
          , attribute11                       -- 109.Attribute11
          , attribute12                       -- 110.Attribute12
          , attribute13                       -- 111.Attribute13
          , attribute14                       -- 112.Attribute14
          , attribute15                       -- 113.Attribute15
          , attribute16                       -- 114.Attribute16
          , attribute17                       -- 115.Attribute17
          , attribute18                       -- 116.Attribute18
          , attribute19                       -- 117.Attribute19
          , attribute20                       -- 118.Attribute20
          , context                           -- 119.Context
          , context2                          -- 120.Context2
          , invoice_date                      -- 121.Invoice Date
          , tax_code                          -- 122.Tax Code
          , invoice_identifier                -- 123.Invoice Identifier
          , invoice_amount                    -- 124.Invoice Amount
          , context3                          -- 125.Context3
          , ussgl_transaction_code            -- 126.Ussgl Transaction Code
          , descr_flex_error_message          -- 127.Descr Flex Error Message
          , jgzz_recon_ref                    -- 128.Jgzz Recon Ref
          , reference_date                    -- 129.Reference Date
          , bk_created_by                     -- 130.�쐬��
          , bk_creation_date                  -- 131.�쐬��
          , bk_last_updated_by                -- 132.�ŏI�X�V��
          , bk_last_update_date               -- 133.�ŏI�X�V��
          , bk_last_update_login              -- 134.�ŏI�X�V���O�C��
          , bk_request_id                     -- 135.�v��ID
          , bk_program_application_id         -- 136.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
          , bk_program_id                     -- 137.�R���J�����g�E�v���O����ID
          , bk_program_update_date            -- 138.�v���O�����ɂ��X�V��
        )
        SELECT
            gi.status                        AS status                                           --   1.Status
          , gi.set_of_books_id               AS set_of_books_id                                  --   2.Set Of Books Id
          , gi.accounting_date               AS accounting_date                                  --   3.Accounting Date
          , gi.currency_code                 AS currency_code                                    --   4.Currency Code
          , gi.date_created                  AS date_created                                     --   5.Date Created
          , gi.created_by                    AS created_by                                       --   6.Created By
          , gi.actual_flag                   AS actual_flag                                      --   7.Actual Flag
          , gi.user_je_category_name         AS user_je_category_name                            --   8.User Je Category Name
          , gi.user_je_source_name           AS user_je_source_name                              --   9.User Je Source Name
          , gi.currency_conversion_date      AS currency_conversion_date                         --  10.Currency Conversion Date
          , gi.encumbrance_type_id           AS encumbrance_type_id                              --  11.Encumbrance Type Id
          , gi.budget_version_id             AS budget_version_id                                --  12.Budget Version Id
          , gi.user_currency_conversion_type AS user_currency_conversion_type                    --  13.User Currency Conversion Type
          , gi.currency_conversion_rate      AS currency_conversion_rate                         --  14.Currency Conversion Rate
          , gi.average_journal_flag          AS average_journal_flag                             --  15.Average Journal Flag
          , gi.originating_bal_seg_value     AS originating_bal_seg_value                        --  16.Originating Bal Seg Value
          , gi.segment1                      AS segment1                                         --  17.Segment1
          , gi.segment2                      AS segment2                                         --  18.Segment2
          , gi.segment3                      AS segment3                                         --  19.Segment3
          , gi.segment4                      AS segment4                                         --  20.Segment4
          , gi.segment5                      AS segment5                                         --  21.Segment5
          , gi.segment6                      AS segment6                                         --  22.Segment6
          , gi.segment7                      AS segment7                                         --  23.Segment7
          , gi.segment8                      AS segment8                                         --  24.Segment8
          , gi.segment9                      AS segment9                                         --  25.Segment9
          , gi.segment10                     AS segment10                                        --  26.Segment10
          , gi.segment11                     AS segment11                                        --  27.Segment11
          , gi.segment12                     AS segment12                                        --  28.Segment12
          , gi.segment13                     AS segment13                                        --  29.Segment13
          , gi.segment14                     AS segment14                                        --  30.Segment14
          , gi.segment15                     AS segment15                                        --  31.Segment15
          , gi.segment16                     AS segment16                                        --  32.Segment16
          , gi.segment17                     AS segment17                                        --  33.Segment17
          , gi.segment18                     AS segment18                                        --  34.Segment18
          , gi.segment19                     AS segment19                                        --  35.Segment19
          , gi.segment20                     AS segment20                                        --  36.Segment20
          , gi.segment21                     AS segment21                                        --  37.Segment21
          , gi.segment22                     AS segment22                                        --  38.Segment22
          , gi.segment23                     AS segment23                                        --  39.Segment23
          , gi.segment24                     AS segment24                                        --  40.Segment24
          , gi.segment25                     AS segment25                                        --  41.Segment25
          , gi.segment26                     AS segment26                                        --  42.Segment26
          , gi.segment27                     AS segment27                                        --  43.Segment27
          , gi.segment28                     AS segment28                                        --  44.Segment28
          , gi.segment29                     AS segment29                                        --  45.Segment29
          , gi.segment30                     AS segment30                                        --  46.Segment30
          , gi.entered_dr                    AS entered_dr                                       --  47.Entered Dr
          , gi.entered_cr                    AS entered_cr                                       --  48.Entered Cr
          , gi.accounted_dr                  AS accounted_dr                                     --  49.Accounted Dr
          , gi.accounted_cr                  AS accounted_cr                                     --  50.Accounted Cr
          , gi.transaction_date              AS transaction_date                                 --  51.Transaction Date
          , gi.reference1                    AS reference1                                       --  52.Reference1
          , gi.reference2                    AS reference2                                       --  53.Reference2
          , gi.reference3                    AS reference3                                       --  54.Reference3
          , gi.reference4                    AS reference4                                       --  55.Reference4
          , gi.reference5                    AS reference5                                       --  56.Reference5
          , gi.reference6                    AS reference6                                       --  57.Reference6
          , gi.reference7                    AS reference7                                       --  58.Reference7
          , gi.reference8                    AS reference8                                       --  59.Reference8
          , gi.reference9                    AS reference9                                       --  60.Reference9
          , gi.reference10                   AS reference10                                      --  61.Reference10
          , gi.reference11                   AS reference11                                      --  62.Reference11
          , gi.reference12                   AS reference12                                      --  63.Reference12
          , gi.reference13                   AS reference13                                      --  64.Reference13
          , gi.reference14                   AS reference14                                      --  65.Reference14
          , gi.reference15                   AS reference15                                      --  66.Reference15
          , gi.reference16                   AS reference16                                      --  67.Reference16
          , gi.reference17                   AS reference17                                      --  68.Reference17
          , gi.reference18                   AS reference18                                      --  69.Reference18
          , gi.reference19                   AS reference19                                      --  70.Reference19
          , gi.reference20                   AS reference20                                      --  71.Reference20
          , gi.reference21                   AS reference21                                      --  72.Reference21
          , gi.reference22                   AS reference22                                      --  73.Reference22
          , gi.reference23                   AS reference23                                      --  74.Reference23
          , gi.reference24                   AS reference24                                      --  75.Reference24
          , gi.reference25                   AS reference25                                      --  76.Reference25
          , gi.reference26                   AS reference26                                      --  77.Reference26
          , gi.reference27                   AS reference27                                      --  78.Reference27
          , gi.reference28                   AS reference28                                      --  79.Reference28
          , gi.reference29                   AS reference29                                      --  80.Reference29
          , gi.reference30                   AS reference30                                      --  81.Reference30
          , gi.je_batch_id                   AS je_batch_id                                      --  82.Je Batch Id
          , gi.period_name                   AS period_name                                      --  83.Period Name
          , gi.je_header_id                  AS je_header_id                                     --  84.Je Header Id
          , gi.je_line_num                   AS je_line_num                                      --  85.Je Line Num
          , gi.chart_of_accounts_id          AS chart_of_accounts_id                             --  86.Chart Of Accounts Id
          , gi.functional_currency_code      AS functional_currency_code                         --  87.Functional Currency Code
          , gi.code_combination_id           AS code_combination_id                              --  88.Code Combination Id
          , gi.date_created_in_gl            AS date_created_in_gl                               --  89.Date Created In Gl
          , gi.warning_code                  AS warning_code                                     --  90.Warning Code
          , gi.status_description            AS status_description                               --  91.Status Description
          , gi.stat_amount                   AS stat_amount                                      --  92.Stat Amount
          , gi.group_id                      AS group_id                                         --  93.Group Id
          , gi.request_id                    AS request_id                                       --  94.Request Id
          , gi.subledger_doc_sequence_id     AS subledger_doc_sequence_id                        --  95.Subledger Doc Sequence Id
          , gi.subledger_doc_sequence_value  AS subledger_doc_sequence_value                     --  96.Subledger Doc Sequence Value
          , gi.attribute1                    AS attribute1                                       --  97.Attribute1
          , gi.attribute2                    AS attribute2                                       --  98.Attribute2
          , gi.gl_sl_link_id                 AS gl_sl_link_id                                    --  99.Gl Sl Link Id
          , gi.gl_sl_link_table              AS gl_sl_link_table                                 -- 100.Gl Sl Link Table
          , gi.attribute3                    AS attribute3                                       -- 101.Attribute3
          , gi.attribute4                    AS attribute4                                       -- 102.Attribute4
          , gi.attribute5                    AS attribute5                                       -- 103.Attribute5
          , gi.attribute6                    AS attribute6                                       -- 104.Attribute6
          , gi.attribute7                    AS attribute7                                       -- 105.Attribute7
          , gi.attribute8                    AS attribute8                                       -- 106.Attribute8
          , gi.attribute9                    AS attribute9                                       -- 107.Attribute9
          , gi.attribute10                   AS attribute10                                      -- 108.Attribute10
          , gi.attribute11                   AS attribute11                                      -- 109.Attribute11
          , gi.attribute12                   AS attribute12                                      -- 110.Attribute12
          , gi.attribute13                   AS attribute13                                      -- 111.Attribute13
          , gi.attribute14                   AS attribute14                                      -- 112.Attribute14
          , gi.attribute15                   AS attribute15                                      -- 113.Attribute15
          , gi.attribute16                   AS attribute16                                      -- 114.Attribute16
          , gi.attribute17                   AS attribute17                                      -- 115.Attribute17
          , gi.attribute18                   AS attribute18                                      -- 116.Attribute18
          , gi.attribute19                   AS attribute19                                      -- 117.Attribute19
          , gi.attribute20                   AS attribute20                                      -- 118.Attribute20
          , gi.context                       AS context                                          -- 119.Context
          , gi.context2                      AS context2                                         -- 120.Context2
          , gi.invoice_date                  AS invoice_date                                     -- 121.Invoice Date
          , gi.tax_code                      AS tax_code                                         -- 122.Tax Code
          , gi.invoice_identifier            AS invoice_identifier                               -- 123.Invoice Identifier
          , gi.invoice_amount                AS invoice_amount                                   -- 124.Invoice Amount
          , gi.context3                      AS context3                                         -- 125.Context3
          , gi.ussgl_transaction_code        AS ussgl_transaction_code                           -- 126.Ussgl Transaction Code
          , gi.descr_flex_error_message      AS descr_flex_error_message                         -- 127.Descr Flex Error Message
          , gi.jgzz_recon_ref                AS jgzz_recon_ref                                   -- 128.Jgzz Recon Ref
          , gi.reference_date                AS reference_date                                   -- 129.Reference Date
          , cn_created_by                    AS bk_created_by                                    -- 130.�쐬��
          , cd_creation_date                 AS bk_creation_date                                 -- 131.�쐬��
          , cn_last_updated_by               AS bk_last_updated_by                               -- 132.�ŏI�X�V��
          , cd_last_update_date              AS bk_last_update_date                              -- 133.�ŏI�X�V��
          , cn_last_update_login             AS bk_last_update_login                             -- 134.�ŏI�X�V���O�C��
          , cn_request_id                    AS bk_request_id                                    -- 135.�v��ID
          , cn_program_application_id        AS bk_program_application_id                        -- 136.�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
          , cn_program_id                    AS bk_program_id                                    -- 137.�R���J�����g�E�v���O����ID
          , cd_program_update_date           AS bk_program_update_date                           -- 138.�v���O�����ɂ��X�V��
        FROM
          gl_interface gi
        WHERE
          gi.rowid = l_gi_rowid_tab(i) -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �o�^�G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo        -- 'XXCFO'
                             , cv_msg_cfo1_00024     -- �o�^�G���[
                             , cv_tkn_table          -- �g�[�N��'TABLE'
                             , cv_msgtkn_cfo1_60019  -- OIC_GLOIF�o�b�N�A�b�v�e�[�u��
                             , cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                             , SQLERRM               -- SQLERRM
                           )
                         , 1
                         , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;  
      END;
      -- =================================
      -- A-4-2�DGL_INTERFACE(GLOIF)�e�[�u���폜����
      -- =================================
      BEGIN
        DELETE FROM
          gl_interface gi
        WHERE
          gi.rowid = l_gi_rowid_tab(i) -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �폜�G���[���b�Z�[�W
          lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo        -- 'XXCFO'
                             , cv_msg_cfo1_00025     -- �폜�G���[
                             , cv_tkn_table          -- �g�[�N��'TABLE'
                             , cv_msgtkn_cfo1_60020  -- GLOIF
                             , cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                             , SQLERRM               -- SQLERRM
                           )
                         , 1
                         , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP bkup_loop;
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
  END bkup_oic_gloif;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_execute_kbn      IN  VARCHAR2    -- ���s�敪
    , in_set_of_books_id  IN  NUMBER      -- ����ID
    , iv_je_source_name   IN  VARCHAR2    -- �d��\�[�X
    , iv_je_category_name IN  VARCHAR2    -- �d��J�e�S��    
    , ov_errbuf           OUT VARCHAR2    --   �G���[�E���b�Z�[�W           # �Œ� #
    , ov_retcode          OUT VARCHAR2    --   ���^�[���E�R�[�h             # �Œ� #
    , ov_errmsg           OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1�D�������� 
    -- ===============================
    init (
        iv_execute_kbn      -- ���s�敪
      , in_set_of_books_id  -- ����ID
      , iv_je_source_name   -- �d��\�[�X
      , iv_je_category_name -- �d��J�e�S��
      , lv_errbuf           -- �G���[�E���b�Z�[�W           # �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             # �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2�D�A�g�f�[�^���o���� , A-3�DI/F�t�@�C���o�͏���
    -- ===============================
    output_gloif ( 
        in_set_of_books_id  -- ����ID
      , iv_je_source_name   -- �d��\�[�X
      , iv_je_category_name -- �d��J�e�S��
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4�D�o�b�N�A�b�v����
    -- ===============================
    bkup_oic_gloif ( 
        lv_errbuf           -- �G���[�E���b�Z�[�W           # �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             # �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
      errbuf              OUT VARCHAR2    -- �G���[�E���b�Z�[�W # �Œ� #
    , retcode             OUT VARCHAR2    -- ���^�[���E�R�[�h   # �Œ� #
    , iv_execute_kbn      IN  VARCHAR2    -- ���s�敪
    , in_set_of_books_id  IN  NUMBER      -- ����ID
    , iv_je_source_name   IN  VARCHAR2    -- �d��\�[�X
    , iv_je_category_name IN  VARCHAR2    -- �d��J�e�S��
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
    lv_msgbuf          VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
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
        iv_execute_kbn      -- ���s�敪
      , in_set_of_books_id  -- ����ID
      , iv_je_source_name   -- �d��\�[�X
      , iv_je_category_name -- �d��J�e�S��
      , lv_errbuf           -- �G���[�E���b�Z�[�W           # �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             # �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W # �Œ� #
    );
--
    -- ===============================================
    -- A-5�D�I������
    -- ===============================================
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
      gn_normal_cnt := 0;
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-5-1�D�t�@�C���N���[�Y
    -- ===============================================
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
--    <<file_close_loop>>
--    FOR i IN 1..l_out_file_tab.COUNT LOOP
--      IF ( UTL_FILE.IS_OPEN ( l_out_file_tab(i).file_handle ) ) THEN
--        UTL_FILE.FCLOSE( l_out_file_tab(i).file_handle );
--      END IF;
--    END LOOP file_close_loop;
-- Ver1.1 Del End
--
    -- A-5-2�D���o�������b�Z�[�W�o��
    -- ===============================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    lv_msgbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo                           -- 'XXCFO'
                   , iv_name         => cv_msg_cfo1_60004                        -- �����ΏہE�������b�Z�[�W
                   , iv_token_name1  => cv_tkn_target                            -- �g�[�N��(TARGET)
                   , iv_token_value1 => cv_msgtkn_cfo1_60027                     -- GLOIF�d��̓]��
                   , iv_token_name2  => cv_tkn_count                             -- �g�[�N��(COUNT)
                   , iv_token_value2 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- ���o����
                 );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- A-5-3�D�o�͌������b�Z�[�W�o�́i�t�@�C�������j
    -- ===============================================
-- Ver1.1 Add Start
    -- SALES �t�@�C���o�͌����o��
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
    -- IFRS �t�@�C���o�͌����o��
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
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- Ver1.1 Add End
-- Ver1.1 Del Start
--    <<out_cnt_loop>>
--    FOR i IN 1..l_out_file_tab.COUNT LOOP
--      lv_msgbuf := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cfo                                           -- 'XXCFO'
--                     , iv_name         => cv_msg_cfo1_60005                                        -- �t�@�C���o�͑ΏہE�������b�Z�[�W
--                     , iv_token_name1  => cv_tkn_target                                            -- �g�[�N��(TARGET)
--                     , iv_token_value1 => l_out_file_tab(i).file_name                              -- �o�̓t�@�C����
--                     , iv_token_name2  => cv_tkn_count                                             -- �g�[�N��(COUNT)
--                     , iv_token_value2 => TO_CHAR(NVL(l_out_file_tab(i).out_cnt,0), cv_comma_edit) -- �o�͌���
--                   );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => lv_msgbuf
--      );
--      -- ��s�}��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => ''
--      );
--    END LOOP out_cnt_loop;
-- Ver1.1 Del End
--
    -- A-5-4�D�ΏہE�����E�G���[�������b�Z�[�W�o�́i���v�j
    -- ===============================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- A-5-5�D�����I�����b�Z�[�W�o��
    -- ===============================================
    --�I�����b�Z�[�W
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
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
END XXCFO010A06C;
/
