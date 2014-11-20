CREATE OR REPLACE PACKAGE BODY XXCMM006A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A05C(body)
 * Description      : ���ߏ��t�@�C��IF�o��(���n)
 * MD.050           : ���ߏ��t�@�C��IF�o��(���n) MD050_CMM_006_A05
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_period_data        ��v���ԃX�e�[�^�X���擾�v���V�[�W��(A-2)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/26    1.0   SCS ���� �M�q    ����쐬
 *  2009/03/12    1.1   SCS R.Takigawa   ���oSQL���C��(�݌Ɋ���(INV)�̒��o�e�[�u���̕ύX)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM006A05C';               -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';       -- ���nCSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A05_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := '���W���[��';
  cv_tkn_word2              CONSTANT VARCHAR2(20)  := '�A�N���F';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- �f�[�^
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- �t�@�C����
  -- ���b�Z�[�W�敪
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- ���b�Z�[�W
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- �t�@�C���p�X�s���G���[
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00013              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00013';           -- ��v�J�����_�̃^�C�v�擾�G���[
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- �Ώۃf�[�^����
  cv_msg_00011              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00011';           -- �ʏ팎�̃f�[�^����
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
  -- �Œ�l(�ݒ�l�A���o����)
  cv_company_cd             CONSTANT VARCHAR2(3)   := '001';                        -- ��ЃR�[�h
  cv_karenda                CONSTANT VARCHAR2(20)  := '��v�J�����_';               -- ���o�ΏۃJ�����_
  cv_SQLGL                  CONSTANT VARCHAR2(5)   := 'SQLGL';                      -- ���o�Ώۃ��W���[��
  cv_AR                     CONSTANT VARCHAR2(5)   := 'AR';                         -- ���o�Ώۃ��W���[��
  cv_INV                    CONSTANT VARCHAR2(5)   := 'INV';                        -- ���o�Ώۃ��W���[��
  cv_open_status            CONSTANT VARCHAR2(1)   := 'O';                          -- �I�[�v���̃X�e�[�^�X
  cv_open_status_nm         CONSTANT VARCHAR2(40)  := '�I�[�v��';                   -- �I�[�v���̃X�e�[�^�X��
--Ver1.1 2009/03/12 add �݌Ɋ���(INV)�̒��o�e�[�u���̕ύX�ɂ��萔�ǉ�
  cv_unopen_status          CONSTANT VARCHAR2(1)   := 'N';                          -- ���I�[�v���̃X�e�[�^�X
  cv_unopen_status_nm       CONSTANT VARCHAR2(10)  := '���I�[�v��';                 -- ���I�[�v���̃X�e�[�^�X��
  cv_close_status           CONSTANT VARCHAR2(1)   := 'C';                          -- �N���[�Y�̃X�e�[�^�X
  cv_close_status_nm        CONSTANT VARCHAR2(8)   := '�N���[�Y';                   -- �N���[�Y�̃X�e�[�^�X��
  cv_unsmr_close_status_nm  CONSTANT VARCHAR2(14)  := '�N���[�Y���v��';             -- �N���[�Y���v��̃X�e�[�^�X��
  cv_future_status_nm       CONSTANT VARCHAR2(4)   := '����';                       -- �����̃X�e�[�^�X��
  cv_adj_period_flg_n       CONSTANT VARCHAR2(1)   := 'N';                          -- �������ԁFN
  cv_organization_code      CONSTANT VARCHAR2(3)   := 'S01';                        -- �g�D�R�[�h�FS01
--End1.1
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate                DATE;                 -- �����J�n����
  gv_filepath               VARCHAR2(255);        -- �A�g�pCSV�t�@�C���o�͐�
  gv_filename               VARCHAR2(255);        -- �A�g�pCSV�t�@�C����
  gd_process_date           DATE;                 -- �Ɩ����t
  gn_before_year            NUMBER(4);            -- �O�N�x
  gn_next_year              NUMBER(4);            -- ���N�x
  gv_period_type            VARCHAR2(15);         -- �J�����_�^�C�v
  gv_application_short_name VARCHAR2(5);          -- ���ԃ��W���[��
  gv_period_name            VARCHAR2(7);          -- ���Ԗ���
  gv_closing_status         VARCHAR2(1);          -- �X�e�[�^�X
  gv_show_status            VARCHAR2(40);         -- �X�e�[�^�X��
  gd_start_date             DATE;                 -- ����From
  gd_end_date               DATE;                 -- ����To
  gn_period_year            NUMBER(4);            -- �N�x
  gv_adjustment_period_flag VARCHAR2(1);          -- ��������
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gn_all_cnt                NUMBER;               -- �擾�f�[�^����
  gc_del_flg                CHAR(1);              -- �t�@�C���폜�t���O(�Ώۃf�[�^�����̏ꍇ)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR get_period_data_cur
  IS
--Ver1.1 2009/03/12 Mod �݌Ɋ���(INV)�̒��o�e�[�u���̕ύX
--    SELECT   SUBSTRB(g.period_name,1,7) AS period_name,
--             SUBSTRB(f.application_short_name,1,5) AS application_short_name,
--             SUBSTRB(g.closing_status,1,1) AS closing_status,
--             SUBSTRB(g.show_status,1,40) AS show_status,
--             g.start_date AS start_date,
--             g.end_date AS end_date,
--             SUBSTRB(g.period_year,1,4) AS period_year,
--             g.adjustment_period_flag AS adjustment_period_flag
--    FROM     gl_period_statuses_v g,
--             fnd_application f
--    WHERE    g.application_id = f.application_id
--    AND      g.period_year >= gn_before_year
--    AND      g.period_year <= gn_next_year
--    AND      (f.application_short_name = cv_SQLGL
--             OR f.application_short_name = cv_AR
--             OR f.application_short_name = cv_INV)
--    AND      g.period_type = gv_period_type
--    ORDER BY application_short_name,period_name,g.adjustment_period_flag
--���ԃ��W���[���yAR�z
    SELECT   SUBSTRB(gpsv.period_name,1,7)              AS period_name,              --���Ԗ���
             SUBSTRB(fapp.application_short_name,1,5)   AS application_short_name,   --���ԃ��W���[��
             SUBSTRB(gpsv.closing_status,1,1)           AS closing_status,           --�X�e�[�^�X
             SUBSTRB(gpsv.show_status,1,40)             AS show_status,              --�X�e�[�^�X��
             gpsv.start_date                            AS start_date,               --����From
             gpsv.end_date                              AS end_date,                 --����To
             SUBSTRB(gpsv.period_year,1,4)              AS period_year,              --�N�x
             gpsv.adjustment_period_flag                AS adjustment_period_flag    --��������
    FROM     gl_period_statuses_v gpsv,
             fnd_application fapp
    WHERE    gpsv.application_id = fapp.application_id
    AND      gpsv.period_year >= gn_before_year
    AND      gpsv.period_year <= gn_next_year
    AND      fapp.application_short_name = cv_AR
    AND      adjustment_period_flag = cv_adj_period_flg_n
    AND      gpsv.period_type = gv_period_type
    UNION ALL
--���ԃ��W���[���ySQLGL�z
    SELECT   SUBSTRB(gpsv.period_name,1,7)              AS period_name,              --���Ԗ���
             SUBSTRB(fapp.application_short_name,1,5)   AS application_short_name,   --���ԃ��W���[��
             SUBSTRB(gpsv.closing_status,1,1)           AS closing_status,           --�X�e�[�^�X
             SUBSTRB(gpsv.show_status,1,40)             AS show_status,              --�X�e�[�^�X��
             gpsv.start_date                            AS start_date,               --����From
             gpsv.end_date                              AS end_date,                 --����To
             SUBSTRB(gpsv.period_year,1,4)              AS period_year,              --�N�x
             gpsv.adjustment_period_flag                AS adjustment_period_flag    --��������
    FROM     gl_period_statuses_v gpsv,
             fnd_application fapp
    WHERE    gpsv.application_id = fapp.application_id
    AND      gpsv.period_year >= gn_before_year
    AND      gpsv.period_year <= gn_next_year
    AND      fapp.application_short_name = cv_SQLGL
    AND      gpsv.period_type = gv_period_type
   UNION ALL
--���ԃ��W���[���yINV�z
    SELECT   SUBSTRB(oapv.period_name,1,7)              AS period_name,              --���Ԗ���
             cv_INV                                     AS application_short_name,   --���ԃ��W���[��
             DECODE(oapv.status,
                      cv_open_status_nm,cv_open_status,                              --�I�[�v��      �FO
                      cv_unsmr_close_status_nm,cv_close_status,                      --�N���[�Y���v��FC
                      cv_close_status_nm,cv_close_status,                            --�N���[�Y      �FC
                      cv_future_status_nm,cv_unopen_status,                          --����          �FN
                      NULL)                             AS closing_status,           --�X�e�[�^�X
             DECODE(SUBSTRB(oapv.status,1,40),
                      cv_open_status_nm,cv_open_status_nm,                           --�I�[�v��      �F�I�[�v��
                      cv_unsmr_close_status_nm,cv_close_status_nm,                   --�N���[�Y���v��F�N���[�Y
                      cv_close_status_nm,cv_close_status_nm,                         --�N���[�Y      �F�N���[�Y
                      cv_future_status_nm,cv_unopen_status_nm,                       --����          �F���I�[�v��
                      NULL)                             AS show_status,              --�X�e�[�^�X��
             oapv.start_date                            AS start_date,               --����From
             oapv.end_date                              AS end_date,                 --����To
             SUBSTRB(oapv.period_year,1,4)              AS period_year,              --�N�x
             cv_adj_period_flg_n                        AS adjustment_period_flag    --��������
    FROM     org_acct_periods_v oapv,
             mtl_parameters mp
    WHERE    oapv.period_year >= gn_before_year
    AND      oapv.period_year <= gn_next_year
    AND      mp.organization_code = cv_organization_code
    AND  (
            ( oapv.organization_id = mp.organization_id )
        OR  ( oapv.accounted_period_type = gv_period_type
          AND NOT EXISTS ( SELECT  oap.period_name,
                                   oap.period_year
                           FROM    org_acct_periods oap
                           WHERE   oap.organization_id = mp.organization_id
                           AND     oap.period_name = oapv.period_name )
            )
         )
    ORDER BY application_short_name,period_name,adjustment_period_flag
--End1.1
  ;
  TYPE g_period_data_ttype IS TABLE OF get_period_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_period_data            g_period_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- �v���O������
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
    -- �t�@�C���I�[�v�����[�h
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- �㏑��
--
    -- *** ���[�J���ϐ� ***
    lb_fexists              BOOLEAN;              -- �t�@�C�������݂��邩�ǂ���
    ln_file_size            NUMBER;               -- �t�@�C���̒���
    ln_block_size           NUMBER;               -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
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
    -- =========================================================
    --  �����J�n�������擾
    -- =========================================================
    gd_sysdate := SYSDATE;
    --
    -- =========================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- =========================================================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_90008           -- �R���J�����g���̓p�����[�^�Ȃ�
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- =========================================================
    --  �v���t�@�C���̎擾(CSV�t�@�C���o�͐�ACSV�t�@�C����)
    -- =========================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile       -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm   -- �v���t�@�C����(CSV�t�@�C���o�͐�)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile       -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm   -- �v���t�@�C����(CSV�t�@�C����)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =========================================================
    --  �Œ�o��(I/F�t�@�C������)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_05102           -- �t�@�C�����o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_filename        -- �g�[�N��(FILE_NAME)
                    ,iv_token_value1 => gv_filename            -- �t�@�C����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- =========================================================
    --  CSV�t�@�C�����݃`�F�b�N
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00010         -- �t�@�C���쐬�ς݃G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =========================================================
    --  �t�@�C���I�[�v��
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                        ,iv_name         => cv_msg_00003       -- �t�@�C���p�X�s���G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- =========================================================
    --  �Ɩ����t�擾(�O�N�x�A���N�x�擾)
    -- =========================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00018         -- �Ɩ��������t�擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �O�N�x�A���N�x�擾
    IF ((TO_NUMBER(TO_CHAR(gd_process_date,'MM')) >= 1)
      AND (TO_NUMBER(TO_CHAR(gd_process_date,'mm')) <= 4))
    THEN
      -- �Ɩ����t�̌���1����4�̏ꍇ (�O�N�x:�Ɩ����t�̔N-2�A���N�x:�Ɩ����t�̔N)
      gn_before_year := TO_CHAR(gd_process_date,'YYYY')-2;
      gn_next_year   := TO_CHAR(gd_process_date,'YYYY');
    ELSE
      -- �Ɩ����t�̌���5����12�̏ꍇ(�O�N�x:�Ɩ����t�̔N-1�A���N�x:�Ɩ����t�̔N+1)
      gn_before_year := TO_CHAR(gd_process_date,'YYYY')-1;
      gn_next_year   := TO_CHAR(gd_process_date,'YYYY')+1;
    END IF;
    --
    -- =========================================================
    --  ��v�J�����_�̃^�C�v�擾
    -- =========================================================
    BEGIN
      SELECT  t.period_type INTO gv_period_type
      FROM    gl_periods_and_types_v t,gl_period_sets_v k
      WHERE   t.period_set_name = k.period_set_name
      AND     k.description = cv_karenda;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                        ,iv_name         => cv_msg_00013       -- ��v�J�����_�̃^�C�v�擾�G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_period_data
   * Description      : ��v���ԃX�e�[�^�X���擾�v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE get_period_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_data';       -- �v���O������
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
   -- �J�[�\���I�[�v��
    OPEN get_period_data_cur;
    --
    -- �f�[�^�̈ꊇ�擾
    FETCH get_period_data_cur BULK COLLECT INTO gt_period_data;
    --
    -- �擾�f�[�^�������Z�b�g
    gn_all_cnt := gt_period_data.COUNT;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_period_data_cur;
    --
    -- �����ΏۂƂȂ�f�[�^�����݂��邩���`�F�b�N
    IF (gn_all_cnt = 0) THEN
      gc_del_flg := '1';
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00001         -- �Ώۃf�[�^����
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_period_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�̓v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- �v���O������
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER;                   -- ���[�v�J�E���^
    ln_target_cnt       NUMBER;                   -- ��������(���ԃ��W���[��/���Ԗ��̖�)
    lv_csv_text         VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �ϐ��̏�����
    ln_target_cnt := 0;
    gv_application_short_name := ' ';
    gv_period_name := ' ';
    -- =========================================================
    --  ��v���ԃX�e�[�^�X��񒊏o(A-3)
    -- =========================================================
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_all_cnt LOOP
      -- =========================================================
      --  �擾�������ԃ��W���[���A���Ԗ��̂ƈقȂ�ꍇ�A
      --  ���ԃ��W���[���Ɗ��Ԗ��̂̎擾�A�f�[�^�̏o�͂��s��
      -- =========================================================
      IF ((gv_application_short_name <> gt_period_data(ln_loop_cnt).application_short_name)
        OR (gv_period_name <> gt_period_data(ln_loop_cnt).period_name))
      THEN
        -- ���ԃ��W���[���A���Ԗ��̂̎擾
        gv_application_short_name := gt_period_data(ln_loop_cnt).application_short_name;
        gv_period_name := gt_period_data(ln_loop_cnt).period_name;
        -- �ʏ팎�̃��R�[�h�����݂��Ȃ��ꍇ
        IF (gt_period_data(ln_loop_cnt).adjustment_period_flag <> 'N') THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00011                             -- �ʏ팎�̃f�[�^����
                          ,iv_token_name1  => cv_tkn_word                              -- �g�[�N��(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD1
                          ,iv_token_name2  => cv_tkn_data                              -- �g�[�N��(NG_DATA)
                          ,iv_token_value2 => gv_application_short_name                -- NG_WORD1��DATA
                                                || cv_tkn_word2                        -- NG_WORD2
                                                || gv_period_name                      -- NG_WORD2��DATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- =========================================================
        --  �f�[�^�̎擾
        -- =========================================================
        IF (ln_loop_cnt = gn_all_cnt) THEN
          -- �ŏI���R�[�h�̏ꍇ�A�����R�[�h�̃`�F�b�N�͍s��Ȃ�
          gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;             -- �X�e�[�^�X
          gv_show_status := gt_period_data(ln_loop_cnt).show_status;                   -- �X�e�[�^�X��
          gd_start_date := gt_period_data(ln_loop_cnt).start_date;                     -- ����FROM
          gd_end_date := gt_period_data(ln_loop_cnt).end_date;                         -- ����TO
          gn_period_year := gt_period_data(ln_loop_cnt).period_year;                   -- �N�x
        ELSE
          -- �ŏI���R�[�h�ȊO�̏ꍇ�A�����R�[�h�̊��ԃ��W���[���A���Ԗ��̂��`�F�b�N
          IF ((gv_application_short_name <> gt_period_data(ln_loop_cnt+1).application_short_name)
            OR (gv_period_name <> gt_period_data(ln_loop_cnt+1).period_name))
          THEN
            -- ����̊��ԃ��W���[���A���Ԗ��̂̃f�[�^�Ȃ�
            gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;           -- �X�e�[�^�X
            gv_show_status := gt_period_data(ln_loop_cnt).show_status;                 -- �X�e�[�^�X��
            gd_start_date := gt_period_data(ln_loop_cnt).start_date;                   -- ����FROM
            gd_end_date := gt_period_data(ln_loop_cnt).end_date;                       -- ����TO
            gn_period_year := gt_period_data(ln_loop_cnt).period_year;                 -- �N�x
          ELSE
            -- ����̊��ԃ��W���[���A���Ԗ��̂̃f�[�^����̏ꍇ�A�������ԃ��R�[�h�̃X�e�[�^�X���`�F�b�N
            IF ((gt_period_data(ln_loop_cnt+1).adjustment_period_flag = 'Y')
              AND (gt_period_data(ln_loop_cnt+1).closing_status = cv_open_status))
            THEN
              -- �������ԃ��R�[�h�̃X�e�[�^�X���uO�v�̏ꍇ�A�X�e�[�^�X�A�X�e�[�^�X���ɃI�[�v�����Z�b�g
              gv_closing_status := cv_open_status;                                     -- �X�e�[�^�X
              gv_show_status := cv_open_status_nm;                                     -- �X�e�[�^�X��
              gd_start_date := gt_period_data(ln_loop_cnt).start_date;                 -- ����FROM
              gd_end_date := gt_period_data(ln_loop_cnt).end_date;                     -- ����TO
              gn_period_year := gt_period_data(ln_loop_cnt).period_year;               -- �N�x
            ELSE
              -- �������ԃ��R�[�h�̃X�e�[�^�X���uO�v�ȊO
              gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;         -- �X�e�[�^�X
              gv_show_status := gt_period_data(ln_loop_cnt).show_status;               -- �X�e�[�^�X��
              gd_start_date := gt_period_data(ln_loop_cnt).start_date;                 -- ����FROM
              gd_end_date := gt_period_data(ln_loop_cnt).end_date;                     -- ����TO
              gn_period_year := gt_period_data(ln_loop_cnt).period_year;               -- �N�x
            END IF;
          END IF;
        END IF;
        -- =========================================================
        --  CSV�t�@�C���o��
        -- =========================================================
        lv_csv_text := cv_enclosed || cv_company_cd || cv_enclosed || cv_delimiter     -- ��ЃR�[�h
          || cv_enclosed || gv_period_name || cv_enclosed || cv_delimiter              -- ���Ԗ���
          || cv_enclosed || gv_application_short_name || cv_enclosed || cv_delimiter   -- ���ԃ��W���[��
          || cv_enclosed || gv_closing_status || cv_enclosed || cv_delimiter           -- �X�e�[�^�X
          || cv_enclosed || gv_show_status || cv_enclosed || cv_delimiter              -- �X�e�[�^�X��
          || TO_CHAR(gd_start_date,'YYYYMMDD') || cv_delimiter                         -- ����FROM
          || TO_CHAR(gd_end_date,'YYYYMMDD') || cv_delimiter                           -- ����TO
          || gn_period_year || cv_delimiter                                            -- �N�x
          || TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS')                                    -- �A�g����
        ;
        BEGIN
          -- �t�@�C����������
          UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
        EXCEPTION
          -- �t�@�C���A�N�Z�X�����G���[
          WHEN UTL_FILE.INVALID_OPERATION THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00007                           -- �t�@�C���A�N�Z�X�����G���[
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          --
          -- CSV�f�[�^�o�̓G���[
          WHEN UTL_FILE.WRITE_ERROR THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00009                           -- CSV�f�[�^�o�̓G���[
                            ,iv_token_name1  => cv_tkn_word                            -- �g�[�N��(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD1
                            ,iv_token_name2  => cv_tkn_data                            -- �g�[�N��(NG_DATA)
                            ,iv_token_value2 => gv_application_short_name              -- NG_WORD1��DATA
                                                  || cv_tkn_word2                      -- NG_WORD2
                                                  || gv_period_name                    -- NG_WORD2��DATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        --
        -- ���������̃J�E���g
        ln_target_cnt := ln_target_cnt + 1;
      END IF;
    END LOOP out_loop;
    --
    -- �Ώی����ɏ����������Z�b�g
    gn_target_cnt := ln_target_cnt;
    -- ���팏���ɏ����������Z�b�g
    gn_normal_cnt := ln_target_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
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
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =====================================================
    --  ���������v���V�[�W��(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  ��v���ԃX�e�[�^�X���擾�v���V�[�W��(A-2)
    -- =====================================================
    get_period_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSV�t�@�C���o�̓v���V�[�W��(A-4)
    -- =====================================================
    output_csv(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  �I�������v���V�[�W��(A-5)
    -- =====================================================
    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);
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
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
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
    -- �t�@�C���폜�t���O���N���A
    gc_del_flg := '0';
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --�Ώی����o��
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
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSV�t�@�C�����N���[�Y����Ă��Ȃ������ꍇ�A�N���[�Y����
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --�Ώۃf�[�^�����̏ꍇ�ACSV�t�@�C�����폜
    IF (gc_del_flg = '1') THEN
      UTL_FILE.FREMOVE(gv_filepath,    -- CSV�t�@�C���o�͐�
                       gv_filename);   -- �t�@�C����
    END IF;
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
END XXCMM006A05C;
/
