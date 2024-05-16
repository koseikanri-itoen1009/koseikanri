CREATE OR REPLACE PACKAGE BODY apps.XXCFF018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF018A01C (body)
 * Description      : ���p�V�~�����[�V�������ʃ��X�g
 * MD.050           : ���p�V�~�����[�V�������ʃ��X�g (MD050_CFF_018_A01)
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             �f�[�^���o����(A-2)�ACSV�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4)
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-12-18    1.0   K.Kanada         �V�K�쐬  E_�{�ғ�_08122�Ή�
 *  2024-02-09    1.1   Y.Sato           E_�{�ғ�_19496�Ή�
 *
 *****************************************************************************************/
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
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  init_err_expt               EXCEPTION;      -- ���������G���[
  chk_no_data_found_expt      EXCEPTION;      -- �Ώۃf�[�^�Ȃ�
  subprocedure_warn_expt      EXCEPTION;      -- �T�u�@�\�̌x���I��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF018A01C';              -- �p�b�P�[�W��
--
  -- DBMS_SQL�����s�ꊇFetch�̌���
  cn_fetch_size               CONSTANT NUMBER        := 1000 ;
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- ���t����
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  cv_format_YM                CONSTANT VARCHAR2(50)  := 'YYYY/MM';
  cv_format_period            CONSTANT VARCHAR2(50)  := 'YYYY-MM';
  -- ���蕶��
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  cv_parenthesis1             CONSTANT VARCHAR2(1)   := '(';                         -- ����
  cv_parenthesis2             CONSTANT VARCHAR2(1)   := ')';                         -- ����
  cv_sql_csv_start            CONSTANT VARCHAR2(20)  := ' ''"''||' ;
  cv_sql_csv_mid              CONSTANT VARCHAR2(20)  := '||''","''||' ;
  cv_sql_space                CONSTANT VARCHAR2(20)  := '          ' ;
  cv_sql_csv_end              CONSTANT VARCHAR2(20)  := '||''"''' ;
  -- ���b�Z�[�W�R�[�h
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- ���̓p�����[�^
  cv_msg_cff_50277            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50277';          -- ���b�Z�[�W�p�g�[�N��(WHATIF���N�G�X�gID)
  cv_msg_cff_50278            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50278';          -- ���b�Z�[�W�p�g�[�N��(�J�n����)
  cv_msg_cff_50279            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50279';          -- ���b�Z�[�W�p�g�[�N��(���Ԑ�)
-- Ver1.1 Add Start
  cv_msg_cff_50267            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50267';          -- ���b�Z�[�W�p�g�[�N��(�{��/�H��敪)
-- Ver1.1 Add End
  cv_msg_cff_50280            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50280';          -- ���p�V�~�����[�V�������ʃ��X�g�w�b�_�p�g�[�N��1
  cv_msg_cff_50281            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50281';          -- ���p�V�~�����[�V�������ʃ��X�g�w�b�_�p�g�[�N��2(�������p�z)
  cv_msg_cff_50282            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50282';          -- ���p�V�~�����[�V�������ʃ��X�g�Ώۃf�[�^����
-- Ver1.1 Add Start
  cv_msg_cff_00062            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00062';          -- �Ώۃf�[�^����
-- Ver1.1 Add End
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی������b�Z�[�W
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- �����������b�Z�[�W
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[�������b�Z�[�W
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- �X�L�b�v�������b�Z�[�W
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I�����b�Z�[�W
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- �x�����b�Z�[�W
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N���b�Z�[�W
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���̓p�����[�^��
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���̓p�����[�^�l
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_whatif_request_id               NUMBER;         -- 1.WHATIF���N�G�X�gID
  gd_period_date                     DATE;           -- 2.�J�n���ԁi���t�^�ϊ��j
  gn_loop_cnt                        NUMBER;         -- ���[�v�񐔁i3.���Ԑ��|1�j
-- Ver1.1 Add Start
  gv_owner_company                   VARCHAR2(20);   -- 4.�{��/�H��敪
-- Ver1.1 Add End
  gv_book_type_code                  XX01_SIM_ADDITIONS.BOOK_TYPE_CODE%TYPE ;           -- �Œ莑�Y�䒠
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_whatif_request_id            IN  VARCHAR2     -- 1.WHATIF���N�G�X�gID
    ,iv_period_date                  IN  VARCHAR2     -- 2.�J�n����
    ,iv_num_periods                  IN  VARCHAR2     -- 3.���Ԑ�
-- Ver1.1 Add Start
    ,iv_owner_company                IN  VARCHAR2     -- 4.�{��/�H��敪
-- Ver1.1 Add End
    ,ov_errbuf                       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_param_name1                  VARCHAR2(1000);  -- ���̓p�����[�^��1
    lv_param_name2                  VARCHAR2(1000);  -- ���̓p�����[�^��2
    lv_param_name3                  VARCHAR2(1000);  -- ���̓p�����[�^��3
-- Ver1.1 Add Start
    lv_param_name4                  VARCHAR2(1000);  -- ���̓p�����[�^��4
-- Ver1.1 Add End
    lv_param_1                      VARCHAR2(1000);  -- 1.WHATIF���N�G�X�gID
    lv_param_2                      VARCHAR2(1000);  -- 2.�J�n����
    lv_param_3                      VARCHAR2(1000);  -- 3.���Ԑ�
-- Ver1.1 Add Start
    lv_param_4                      VARCHAR2(1000);  -- 4.�{��/�H��敪
-- Ver1.1 Add End
    lv_csv_header                   VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
    lv_csv_header_1                 VARCHAR2(5000);  -- �Œ蕔
    lv_csv_header_depr_amt          VARCHAR2(20);    -- �����u�������p�z�v
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
    --==============================================================
    -- 1.���̓p�����[�^�o��
    --==============================================================
    gn_whatif_request_id            := TO_NUMBER(iv_whatif_request_id) ;           -- 1.WHATIF���N�G�X�gID
    gd_period_date                  := TO_DATE(iv_period_date,cv_format_period) ;  -- 2.�J�n���ԁi���t�^�ϊ��j  ������
    gn_loop_cnt                     := TO_NUMBER(iv_num_periods) - 1 ;             -- ���[�v�񐔁i3.���Ԑ��|1�j
-- Ver1.1 Add Start
    gv_owner_company                := iv_owner_company ;                          -- 4.�{��/�H��敪
-- Ver1.1 Add End
    --
    -- 1.WHATIF���N�G�X�gID
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50277               -- ���b�Z�[�W�R�[�h
                      );
    lv_param_1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h   ���̓p�����[�^�uPARAM_NAME �F  PARAM_VALUE�v
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name1                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_whatif_request_id           -- �g�[�N���l2
                      );
    -- 2.�J�n����
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50278               -- ���b�Z�[�W�R�[�h
                      );
    lv_param_2  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h   ���̓p�����[�^�uPARAM_NAME �F  PARAM_VALUE�v
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name2                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_period_date                 -- �g�[�N���l2
                      );
    -- 3.���Ԑ�
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50279               -- ���b�Z�[�W�R�[�h
                      );
    lv_param_3  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h   ���̓p�����[�^�uPARAM_NAME �F  PARAM_VALUE�v
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name3                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_num_periods                 -- �g�[�N���l2
                      );
    --
-- Ver1.1 Add Start
    -- 4.�{��/�H��敪
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50267               -- ���b�Z�[�W�R�[�h
                      );
    lv_param_4  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h   ���̓p�����[�^�uPARAM_NAME �F  PARAM_VALUE�v
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name4                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_owner_company               -- �g�[�N���l2
                      );
-- Ver1.1 Add End
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''          || chr(10) ||
                 lv_param_1  || chr(10) ||      -- 1.WHATIF���N�G�X�gID
                 lv_param_2  || chr(10) ||      -- 2.�J�n����
                 lv_param_3  || chr(10) ||      -- 3.���Ԑ�
-- Ver1.1 Add Start
                 lv_param_4  || chr(10) ||      -- 4.�{��/�H��敪
-- Ver1.1 Add End
                 ''
    );
--
    --==================================================
    -- 2.�䒠���擾
    --==================================================
    BEGIN
      SELECT distinct xsw.book_type_code
      INTO   gv_book_type_code
      FROM   xx01_sim_whatif xsw
      WHERE  xsw.whatif_request_id = gn_whatif_request_id
      AND    xsw.period_date       = gd_period_date ;
    EXCEPTION
      -- *** �O���̏ꍇ ***
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50282               -- ���b�Z�[�W�R�[�h
                       );
        RAISE chk_no_data_found_expt;
    END ;
--
    --==================================================
    -- 3.CSV�w�b�_���ڏo��
    --==================================================
    -- WHATIF���N�G�X�gID,�䒠,���Y�ԍ�,�E�v,(�J�e�S��)���Y���,(�J�e�S��)���p�\��,(�J�e�S��)���Y����,
    -- (�J�e�S��)���p����,(�J�e�S��)�ϗp�N��,(�J�e�S��)���p���@,(�J�e�S��)���[�X���,(���Ə�)�\���n,
    -- (���Ə�)�Ǘ�����,(���Ə�)���Ə�,(���Ə�)�ꏊ,(���Ə�)�{��/�H��,(���pAFF)���,(���pAFF)�v�㕔��,
    -- (���pAFF)�v�㕔�喼,(���pAFF)����Ȗ�,���p���@,���Ƌ��p��,�擾���z,�����N���p�݌v�z,�����擾���z,
    -- �������p�݌v�z,�c�����z,�������뉿�z,�g���������p,���Y���z,(yyyy/mm)�������p�z
    --==================================================
    -- CSV�w�b�_����1
    lv_csv_header_1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50280               -- ���b�Z�[�W�R�[�h
                      );
    -- CSV�w�b�_�����u�������p�z�v
    lv_csv_header_depr_amt := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50281               -- ���b�Z�[�W�R�[�h
                      );
    --�o�͕�����쐬
    lv_csv_header := lv_csv_header_1 ;
    --
    << csv_header_loop >>
    FOR i IN 0..gn_loop_cnt
    LOOP
      lv_csv_header := lv_csv_header || cv_comma || cv_dqu ||
                       cv_parenthesis1 || TO_CHAR(ADD_MONTHS(gd_period_date,i),cv_format_YM) || cv_parenthesis2 || 
                       lv_csv_header_depr_amt || cv_dqu ;
                                                                          -- (yyyy/mm)�������p�z
    END LOOP ;
--
    --�w�b�_�̃t�@�C���o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** �O���̏ꍇ�̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : �f�[�^���o����(A-2)�ACSV�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
     ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    -- ���ISQL�p
    lv_sql_str            VARCHAR2(32767) DEFAULT NULL;  -- �o�͕�����i�[�p�ϐ�
    lv_edit_depr_amt      VARCHAR2(32767) DEFAULT NULL;  -- SELECT �������p�z�p�ϐ�
    lv_edit_period_date   VARCHAR2(100)   DEFAULT NULL;  -- SELECT �������p�z�p�ϐ�
    li_cid                INTEGER;
    li_row                INTEGER;
    l_sql_val_tab         DBMS_SQL.VARCHAR2_TABLE;
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ===============================
    -- �f�[�^���o����(A-2)
    -- ===============================
    ------------------------------
    -- 1.SQL���ҏW
    ------------------------------
    --�������p�z��SELECT��ҏW
    << sql_edit_depr_amt_loop >>
    FOR j IN 0..gn_loop_cnt
    LOOP
      lv_edit_period_date := TO_CHAR(ADD_MONTHS(gd_period_date,j),cv_format_YMD) ;
      lv_edit_depr_amt    := lv_edit_depr_amt || cv_sql_csv_mid
                                          || '(SELECT xsw.depreciation'
                               || chr(10) || ' FROM xx01_sim_whatif xsw'
                               || chr(10) || ' WHERE xsw.whatif_request_id = xsa.whatif_request_id'
                               || chr(10) || ' AND xsw.book_type_code = xsa.book_type_code'
                               || chr(10) || ' AND xsw.asset_number = xsa.asset_number'
                               || chr(10) || ' AND xsw.period_date = TO_DATE(''' || lv_edit_period_date || ''',''yyyy/mm/dd''))'
                               || chr(10) ;
    END LOOP sql_edit_depr_amt_loop ;
--
    --
    --SELECT��ҏW
    lv_sql_str        := 'SELECT'
    ||chr(10)||cv_sql_csv_start|| 'xsa.whatif_request_id'                                           --whatif���N�G�X�gid
    ||chr(10)|| cv_sql_csv_mid || 'xsa.book_type_code'                                              --�䒠
    ||chr(10)|| cv_sql_csv_mid || 'xsa.asset_number'                                                --���Y�ԍ�
    ||chr(10)|| cv_sql_csv_mid || 'xsa.description'                                                 --�E�v
    ||chr(10)|| cv_sql_csv_mid || 'category.segment1'                                               --(�J�e�S��)���Y���
    ||chr(10)|| cv_sql_csv_mid || 'category.segment2'                                               --(�J�e�S��)���p�\��
    ||chr(10)|| cv_sql_csv_mid || 'category.segment3'                                               --(�J�e�S��)���Y����
    ||chr(10)|| cv_sql_csv_mid || 'category.segment4'                                               --(�J�e�S��)���p����
    ||chr(10)|| cv_sql_csv_mid || 'category.segment5'                                               --(�J�e�S��)�ϗp�N��
    ||chr(10)|| cv_sql_csv_mid || 'category.segment6'                                               --(�J�e�S��)���p���@
    ||chr(10)|| cv_sql_csv_mid || 'category.segment7'                                               --(�J�e�S��)���[�X���
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment1'                                                 --(���Ə�)�\���n
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment2'                                                 --(���Ə�)�Ǘ�����
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment3'                                                 --(���Ə�)���Ə�
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment4'                                                 --(���Ə�)�ꏊ
    ||chr(10)|| cv_sql_csv_mid || 'locate.segment5'                                                 --(���Ə�)�{��/�H��
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment1'                                        --(���paff)���
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment2'                                        --(���paff)�v�㕔��
    ||chr(10)|| cv_sql_csv_mid || '(SELECT aff_department_name'
    ||chr(10)|| cv_sql_space   || ' FROM xxcff_aff_department_v aff_dep'
    ||chr(10)|| cv_sql_space   || ' WHERE aff_dep.aff_department_code = deprn_acct_code.segment2)'  --(���paff)�v�㕔�喼
    ||chr(10)|| cv_sql_csv_mid || 'deprn_acct_code.segment3'                                        --(���paff)����Ȗ�
    ||chr(10)|| cv_sql_csv_mid || 'xsa.deprn_method_code'                                           --���p���@
    ||chr(10)|| cv_sql_csv_mid || 'TO_CHAR(xsa.date_placed_in_service,''yyyy/mm/dd'')'              --���Ƌ��p��
    ||chr(10)|| cv_sql_csv_mid || 'xsa.cost'                                                        --�擾���z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_ytd_deprn'                                               --�����N���p�݌v�z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.original_cost'                                               --�����擾���z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_deprn_reserve'                                           --�������p�݌v�z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.salvage_value'                                               --�c�����z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.fst_nbv'                                                     --�������뉿�z
    ||chr(10)|| cv_sql_csv_mid || 'xsa.extended_deprn_flag'                                         --�g���������p
    ||chr(10)|| cv_sql_csv_mid || 'xsa.recoverable_cost'                                            --���Y���z
    ||chr(10)|| lv_edit_depr_amt || cv_sql_csv_end 
    ||chr(10) ;
    --
    --FROM WHERE ORDER-BY ��ҏW
    lv_sql_str := lv_sql_str || 'FROM xx01_sim_additions xsa'
                    ||chr(10)|| '    ,fa_categories_b category'
                    ||chr(10)|| '    ,fa_locations locate'
                    ||chr(10)|| '    ,gl_code_combinations deprn_acct_code'
                    ||chr(10)|| 'WHERE xsa.asset_category_id = category.category_id'
                    ||chr(10)|| 'AND xsa.location_id = locate.location_id'
                    ||chr(10)|| 'AND xsa.expense_code_combination_id = deprn_acct_code.code_combination_id'
                    ||chr(10)|| 'AND xsa.whatif_request_id = ' || gn_whatif_request_id
                    ||chr(10)|| 'AND xsa.book_type_code = ''' || gv_book_type_code || ''' '
-- Ver1.1 Add Start
                    ||chr(10)|| 'AND locate.segment5 = ''' || gv_owner_company ||''' '
-- Ver1.1 Add End
                    ||chr(10)|| 'ORDER BY xsa.book_type_code'
                    ||chr(10)|| '        ,xsa.asset_number'
                    ||chr(10) ;
--
--
-- SQL�m�F�p Debug
--FND_FILE.PUT_LINE(
--   which  => FND_FILE.LOG
--  ,buff   => 'debug //// lv_sql_str' || chr(10) || lv_sql_str
--);
--
    ------------------------------
    -- 2.SQL�����s
    ------------------------------
    li_cid := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(li_cid, lv_sql_str, DBMS_SQL.NATIVE);
    DBMS_SQL.DEFINE_ARRAY(li_cid, 1, l_sql_val_tab, cn_fetch_size, 1);
    li_row := DBMS_SQL.EXECUTE(li_cid);
    << sql_fetch_loop >>
    LOOP
      li_row := DBMS_SQL.FETCH_ROWS(li_cid);
      DBMS_SQL.COLUMN_VALUE(li_cid, 1, l_sql_val_tab);
      EXIT WHEN li_row != cn_fetch_size ;
    END LOOP sql_fetch_loop ;
    --
    -- �J�[�\���N���[�Y
    DBMS_SQL.close_cursor(li_cid);
    --
    -- �Ώی���
    gn_target_cnt := l_sql_val_tab.COUNT ;
--
-- Ver1.1 Add Start
    IF (gn_target_cnt = 0)
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cff_00062               -- �Ώۃf�[�^����
                     );
      RAISE chk_no_data_found_expt;
    END IF;
-- Ver1.1 Add End
    -- ===============================
    -- CSV�o��(A-3)
    -- ===============================
    << file_output_loop >>
    FOR k IN 1..l_sql_val_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => l_sql_val_tab(k)
      );
      gn_normal_cnt := gn_normal_cnt + 1 ;
    END LOOP file_output_loop ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- Ver1.1 Add Start
    -- *** �O���̏ꍇ�̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
-- Ver1.1 Add End
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_whatif_request_id            IN  VARCHAR2     -- 1.WHATIF���N�G�X�gID
    ,iv_period_date                  IN  VARCHAR2     -- 2.�J�n����
    ,iv_num_periods                  IN  VARCHAR2     -- 3.���Ԑ�
-- Ver1.1 Add Start
    ,iv_owner_company                IN  VARCHAR2     -- 4.�{��/�H��敪
-- Ver1.1 Add End
    ,ov_errbuf                       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ��������(A-1)
    -- ===============================
    init(
       iv_whatif_request_id           => iv_whatif_request_id           -- 1.WHATIF���N�G�X�gID
      ,iv_period_date                 => iv_period_date                 -- 2.�J�n����
      ,iv_num_periods                 => iv_num_periods                 -- 3.���Ԑ�
-- Ver1.1 Add Start
      ,iv_owner_company               => iv_owner_company               -- 4.�{��/�H��敪
-- Ver1.1 Add End
      ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE subprocedure_warn_expt;
    END IF;
--
    -- ===============================
    -- �f�[�^���o����(A-2)�ACSV�o��(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE subprocedure_warn_expt;
    END IF;
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ��x��
    WHEN subprocedure_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    errbuf                          OUT    VARCHAR2      -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2      -- �G���[�R�[�h     #�Œ�#
   ,iv_whatif_request_id            IN     VARCHAR2      -- 1.WHATIF���N�G�X�gID (���l)
   ,iv_period_date                  IN     VARCHAR2      -- 2.�J�n���� (YYYY-MM)
   ,iv_num_periods                  IN     VARCHAR2      -- 3.���Ԑ� (���l)
-- Ver1.1 Add Start
   ,iv_owner_company                IN     VARCHAR2      -- 4.�{��/�H��敪
-- Ver1.1 Add End
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_whatif_request_id           => iv_whatif_request_id           -- 1.WHATIF���N�G�X�gID
      ,iv_period_date                 => iv_period_date                 -- 2.�J�n����
      ,iv_num_periods                 => iv_num_periods                 -- 3.���Ԑ�
-- Ver1.1 Add Start
      ,iv_owner_company               => iv_owner_company               -- 4.�{��/�H��敪
-- Ver1.1 Add End
      ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error)
    THEN
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
END XXCFF018A01C;
/
