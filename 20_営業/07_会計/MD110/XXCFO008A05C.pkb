CREATE OR REPLACE PACKAGE BODY APPS.XXCFO008A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO008A05C (body)
 * Description      : ERP Cloud��芨��ȖځF������(�ޑK)��GL�d���A�g���AEBS�̃A�h�I���e�[�u�����X�V����B
 * MD.050           : T_MD050_CFO_008_A05_������(�ޑK)IF_�d��捞_EBS�R���J�����g
 * Version          : 1.1
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  csv_data_load          CSV�f�[�^�捞����(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-11-15    1.0   Y.Fuku           �V�K�쐬
 *  2023-02-10    1.1   F.Hasebe         ���C���e���f
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_dir_get_expt       EXCEPTION;                                     -- �f�B���N�g���t���p�X�擾�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO008A05C';               -- �p�b�P�[�W�� 
--
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo            CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';
-- Ver 1.1 Add Start
  cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
-- Ver 1.1 Add End
  --
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  --
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;              -- �t�@�C���T�C�Y
  cv_open_mode_r            CONSTANT VARCHAR2(1)    := 'R';                -- �ǂݍ��݃��[�h
  cv_delim_comma            CONSTANT VARCHAR2(1)    := ',';                -- �J���}
  --�v���t�@�C��
  -- XXCFO:OIC�A�g�f�[�^�t�@�C���捞�f�B���N�g����
  cv_oic_in_file_dir        CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_IN_FILE_DIR';
  -- XXCFO:ERP_�d�󖾍�_������(�ޑK)�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_data_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_GL_JE_L_ERP_IN_FILE';
  --���b�Z�[�W
  cv_msg_cfo_00001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_coi_00029          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';   -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_00029          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00024          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- �o�^�G���[���b�Z�[�W
-- Ver 1.1 Add Start
  cv_msg_cfo_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_60030          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60030';   -- CSV�X�V�������b�Z�[�W
  cv_msg_cfo_60031          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60031';   -- CSV�o�^�������b�Z�[�W
-- Ver 1.1 Add End
  cv_msg_cfo_60002          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';   -- �t�@�C�����o�̓��b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';         -- �v���t�@�C����
  cv_tkn_dir_tok            CONSTANT VARCHAR2(20)  := 'DIR_TOK';           -- �f�B���N�g����
  cv_tkn_file_name          CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u����
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';           -- �g�[�N����(SQLERRM)
-- Ver 1.1 Add Start
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';             -- �g�[�N����(COUNT)
-- Ver 1.1 Add End
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_60024       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60024';  -- 'GL�d�󖾍�_ERP
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- XXCFO:OIC�A�g�f�[�^�t�@�C���捞�f�B���N�g����
  gv_dir_name      VARCHAR2(1000);
  -- XXCFO:ERP_�d�󖾍�_������(�ޑK)�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gv_if_file_name  VARCHAR2(1000);
  gt_directory_path all_directories.directory_path%TYPE;       -- �f�B���N�g���p�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2 ,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2 ,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_full_name      VARCHAR2(200)   DEFAULT NULL;                     -- �f�B���N�g���p�X�{�t�@�C�����A���l
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- ���b�Z�[�W�o�͗p
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
    -- ==============================================================
    -- 1.�v���t�@�C���̎擾
    -- ==============================================================
    -- OIC�A�g�f�[�^�t�@�C���捞�f�B���N�g����
    gv_dir_name := FND_PROFILE.VALUE( cv_oic_in_file_dir );
--
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name      -- �g�[�N�����F�v���t�@�C����
                               , cv_oic_in_file_dir    -- �g�[�N���l�FXXCFO1_OIC_IN_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ERP_�d�󖾍�_������(�ޑK)�A�g�f�[�^�t�@�C����
    gv_if_file_name := FND_PROFILE.VALUE( cv_data_filename );
--
    IF ( gv_if_file_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name      -- �g�[�N�����F�v���t�@�C����
                               , cv_data_filename      -- �g�[�N���l�FXXCFO1_OIC_GL_JE_L_ERP_IN_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 2.�v���t�@�C���l�uXXCFO:OIC�A�g�f�[�^�t�@�C���捞�f�B���N�g�����v����f�B���N�g���p�X���擾����B
    -- ==============================================================
    BEGIN
      SELECT 
        RTRIM( ad.directory_path , cv_slash ) AS directory_path
      INTO 
        gt_directory_path
      FROM 
        all_directories ad
      WHERE 
        ad.directory_name = gv_dir_name
      ;
      -- ���R�[�h�͑��݂��邪�f�B���N�g���p�X��null�̏ꍇ�A�G���[
      IF ( gt_directory_path IS NULL ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                               , cv_tkn_dir_tok          -- �g�[�N�����F�f�B���N�g����
                               , gv_dir_name             -- �g�[�N���l�Fgv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
      END IF;
    -- ���R�[�h���擾�ł��Ȃ��ꍇ�A�G���[
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                               , cv_tkn_dir_tok          -- �g�[�N�����F�f�B���N�g����
                               , gv_dir_name             -- �g�[�N���l�Fgv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
    END;

--
    -- ==============================================================
    -- 3.�t�@�C�������f�B���N�g���p�X�t���ŏo�͂���B
    -- ==============================================================
    lv_full_name := gt_directory_path || cv_slash || gv_if_file_name;
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo   -- 'XXCFO'
                                       , cv_msg_cfo_60002 -- �t�@�C�����o�̓��b�Z�[�W
                                       , cv_tkn_file_name -- 'FILE_NAME'
                                       , lv_full_name     -- �f�B���N�g���p�X�ƃt�@�C�����̘A������
                                      );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
  EXCEPTION
    WHEN global_dir_get_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : csv_data_load
   * Description      : OIC����A�g���ꂽCSV�t�@�C���̎�荞�ݏ����Ƃ��ď������s���B(A-2)
   ***********************************************************************************/
  PROCEDURE csv_data_load(
    ov_errbuf     OUT VARCHAR2 ,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2 ,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_data_load'; -- �v���O������
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
    lv_csv_buf       VARCHAR2(32767);       -- CSV�t�@�C���o�b�t�@
-- Ver 1.1 Add Start
    ln_get_count     NUMBER;                -- ���o����
-- Ver 1.1 Add End
    ln_cnt_insert    NUMBER;                -- insert����
-- Ver 1.1 Add Start
    ln_cnt_update    NUMBER;                -- update����
-- Ver 1.1 Add End
    lf_file_handle   UTL_FILE.FILE_TYPE;    -- CSV�t�@�C���o�b�t�@
    TYPE lt_tbl_type_textlist IS TABLE OF VARCHAR2(100) NOT NULL;
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
    -- �ϐ��̏�����
    ln_cnt_insert  := 0;
-- Ver 1.1 Add Start
    ln_cnt_update  := 0;
    ln_get_count   := 0;
-- Ver 1.1 Add End
    ----------------
    -- �t�@�C���捞
    ----------------
    -- 1�D�t�@�C���̃I�[�v�����s���B
    BEGIN
      lf_file_handle := UTL_FILE.FOPEN( gt_directory_path , gv_if_file_name , cv_open_mode_r , cn_max_linesize );
    EXCEPTION
      -- �t�@�C���I�[�v���G���[ 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- �t�@�C���I�[�v���G���[���b�Z�[�W
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --��O�\���́A��ʃ��W���[���ōs���B
        RAISE global_process_expt;
    END;
    -- �t�@�C���̃��R�[�h�����[�v
    <<file_recode_loop>>
    LOOP
      BEGIN
        UTL_FILE.GET_LINE( lf_file_handle , lv_csv_buf );
        --�s���J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
-- Ver 1.1 Add Start
        --
        -- GL�d�󖾍�_ERP�e�[�u���Ɋ��Ƀf�[�^���o�^�ς݂��m�F
        SELECT COUNT(1)
        INTO   ln_get_count
        FROM   XXCFO_GL_JE_LINES_ERP xgjle
        WHERE  xgjle.je_header_id  =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
        AND    xgjle.je_line_num   =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL );
        --
        IF (ln_get_count = 0) THEN
        -- �o�^
-- Ver 1.1 Add END
        -- 2�D�uGL�d�󖾍�_ERP�v�e�[�u���̓o�^�������s���B
          BEGIN
            INSERT INTO XXCFO_GL_JE_LINES_ERP(
                je_header_id
              , je_line_num
              , set_of_books_name
              , period_name
              , je_source
              , je_category
              , effective_date
              , entered_dr
              , entered_cr
              , accounted_dr
              , accounted_cr
              , segment1
              , segment2
              , segment3
              , segment4
              , segment5
              , segment6
              , segment7
              , segment8
              , payment_status_flag
              , check_date
              , cancelled_date
              --WHO�J����
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
                NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 3 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 4 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 5 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 6 ) ) , NULL )
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 7 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 8 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 9 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 10 ) ) , NULL )
              , NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 11 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 12 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 13 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 14 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 15 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 16 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 17 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 18 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 19 ) ) , NULL )
              , NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 20 ) ) , NULL )
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 21 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 22 ) , 
-- Ver 1.1 Mod Start
--                'YYYY-MM-DD' ) , NULL )
                cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , cn_created_by
              , cd_creation_date
              , cn_last_updated_by
              , cd_last_update_date
              , cn_last_update_login
              , cn_request_id
              , cn_program_application_id
              , cn_program_id
              , cd_program_update_date
            );
          EXCEPTION
            WHEN OTHERS THEN
              --�t�@�C�����J���Ă��������
              IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
                  UTL_FILE.FCLOSE( lf_file_handle );
              END IF;
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                               cv_msg_kbn_cfo       -- XXCFO
                                                             , cv_msg_cfo_00024     -- �o�^�G���[���b�Z�[�W
                                                             , cv_tkn_table         -- �g�[�N����1�FTABLE
                                                             , cv_msgtkn_cfo_60024  -- �g�[�N���l1�FGL�d�󖾍�_ERP
                                                             , cv_tkn_errmsg        -- �g�[�N����2�FERRMSG
                                                             , SQLERRM              -- �g�[�N���l2�FSQLERRM
                                                            )
                                   , 1
                                   , 5000
                                  );
              lv_errbuf := lv_errmsg;
              --��O�\���́A��ʃ��W���[���ōs���B
              RAISE global_process_expt;
          END;
          ln_cnt_insert := ln_cnt_insert + 1;
-- Ver 1.1 Add Start
        ELSE
          -- �X�V
          BEGIN
            UPDATE
              XXCFO_GL_JE_LINES_ERP xgjle
            SET
                xgjle.payment_status_flag    = NVL( TO_CHAR( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 20 ) ) , NULL )
              , xgjle.check_date             = NVL( TO_DATE( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 21 ) , 
-- Ver 1.1 Mod Start
--                                               'YYYY-MM-DD' ) , NULL )
                                               cv_date_fmt ) , NULL )
-- Ver 1.1 Mod End
              , xgjle.last_updated_by        = cn_last_updated_by
              , xgjle.last_update_date       = cd_last_update_date
              , xgjle.last_update_login      = cn_last_update_login
              , xgjle.request_id             = cn_request_id
              , xgjle.program_application_id = cn_program_application_id
              , xgjle.program_id             = cn_program_id
              , xgjle.program_update_date    = cd_program_update_date
            WHERE
                  xgjle.je_header_id  =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 1 ) ) , NULL )
              AND xgjle.je_line_num   =  NVL( TO_NUMBER( xxccp_common_pkg.char_delim_partition( lv_csv_buf , cv_delim_comma , 2 ) ) , NULL );
          EXCEPTION
            WHEN  OTHERS  THEN
              --�t�@�C�����J���Ă��������
              IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
                  UTL_FILE.FCLOSE( lf_file_handle );
              END IF;
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                               cv_msg_kbn_cfo       -- XXCFO
                                                             , cv_msg_cfo_00020     -- �X�V�G���[���b�Z�[�W
                                                             , cv_tkn_table         -- �g�[�N����1�FTABLE
                                                             , cv_msgtkn_cfo_60024  -- �g�[�N���l1�FGL�d�󖾍�_ERP
                                                             , cv_tkn_errmsg        -- �g�[�N����2�FERRMSG
                                                             , SQLERRM              -- �g�[�N���l2�FSQLERRM
                                                            )
                                   , 1
                                   , 5000
                                  );
              lv_errbuf := lv_errmsg;
              --��O�\���́A��ʃ��W���[���ōs���B
              RAISE global_process_expt;
          END;
          ln_cnt_update := ln_cnt_update + 1;
        END IF;
-- Ver 1.1 Add End
      EXCEPTION
        -- ���̃��R�[�h���Ȃ��ꍇ�A���[�v�I��
        WHEN NO_DATA_FOUND THEN
          -- 3�DCSV�t�@�C�������
          IF ( UTL_FILE.IS_OPEN( lf_file_handle ) ) THEN
              UTL_FILE.FCLOSE( lf_file_handle );
          END IF;
-- Ver 1.1 Mod Start
--          gn_normal_cnt := ln_cnt_insert;
          gn_normal_cnt := ln_cnt_insert + ln_cnt_update;
-- Ver 1.1 Mod End
          EXIT;
      END;
    END LOOP file_recode_loop;
-- Ver 1.1 Add Start
    -- ���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfo       -- XXCFO
                   , cv_msg_cfo_60031     -- CSV�o�^�������b�Z�[�W
                   , cv_tkn_table         -- �g�[�N����1�FTABLE
                   , cv_msgtkn_cfo_60024  -- �g�[�N���l1�FGL�d�󖾍�_ERP
                   , cv_tkn_count         -- �g�[�N����2�FCOUNT
                   , ln_cnt_insert        -- �g�[�N���l2�FCSV�ɂ��o�^����
                 );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    gv_out_msg := xxccp_common_pkg.get_msg(
                     cv_msg_kbn_cfo       -- XXCFO
                   , cv_msg_cfo_60030     -- CSV�X�V�������b�Z�[�W
                   , cv_tkn_table         -- �g�[�N����1�FTABLE
                   , cv_msgtkn_cfo_60024  -- �g�[�N���l1�FGL�d�󖾍�_ERP
                   , cv_tkn_count         -- �g�[�N����2�FCOUNT
                   , ln_cnt_update        -- �g�[�N���l2�FCSV�ɂ��X�V����
                 );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- Ver 1.1 Add End
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END csv_data_load;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2 ,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2 ,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- <A-1�D��������>
    -- ===============================
    init(
      lv_errbuf ,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode ,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <A-2�DCSV�f�[�^�捞����>
    -- ===============================
    csv_data_load(
      lv_errbuf ,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode ,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg );        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    errbuf        OUT VARCHAR2 ,     --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
        lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
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
    IF ( retcode = cv_status_error ) THEN
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
END XXCFO008A05C;
/
