CREATE OR REPLACE PACKAGE BODY XXCMM006A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A04C(body)
 * Description      : �ғ����J�����_IF�o�́i���n�j
 * MD.050           : �ғ����J�����_IF�o�́i���n) MD050_CMM_006_A04
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             CSV�t�@�C���o�͏���(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   SCS �H�� �^��    ����쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
--  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1(���g�p)
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
--  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����(���g�p)
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
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- �A�h�I���F�}�X�^
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F���ʁEIF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM006A04C';      -- �p�b�P�[�W��
--
  -- ���b�Z�[�W�ԍ�(�}�X�^)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- �Ώۃf�[�^�������b�Z�[�W
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- �t�@�C���p�X�s���G���[
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- �t�@�C���A�N�Z�X�����G���[
  cv_csv_data_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';  -- CSV�f�[�^�o�̓G���[
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';  -- CSV�t�@�C�����݃`�F�b�N
  -- ���b�Z�[�W�ԍ�(���ʁEIF)
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';  -- �t�@�C�������b�Z�[�W
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
--
  -- �v���t�@�C��
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';  -- �ғ����J�����_�A�g�pCSV�t�@�C���o�͐�
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_006A04_OUT_FILE';  -- �ғ����J�����_�A�g�pCSV�t�@�C����
  cv_prf_calender_cd   CONSTANT VARCHAR2(30) := 'XXCCP1_WORKING_CALENDAR';  -- �J�����_����(�A�h�I���F���ʁEIF�̈�)

  -- �g�[�N��
  cv_tkn_ng_profile    CONSTANT VARCHAR2(30) := 'NG_PROFILE';        -- �v���t�@�C����
  cv_tkn_ng_word       CONSTANT VARCHAR2(30) := 'NG_WORD';           -- ���ږ�
  cv_tkn_ng_data       CONSTANT VARCHAR2(30) := 'NG_DATA';           -- �f�[�^
  cv_tkn_filename      CONSTANT VARCHAR2(30) := 'FILE_NAME';         -- �t�@�C����
  cv_prf_dir_nm        CONSTANT VARCHAR2(30) := 'CSV�t�@�C���o�͐�';
  cv_prf_fil_nm        CONSTANT VARCHAR2(30) := 'CSV�t�@�C����';
  cv_prf_calender_nm   CONSTANT VARCHAR2(30) := '�J�����_����';
  cv_calender_date_nm  CONSTANT VARCHAR2(30) := '�J�����_�[���t';

--
  -- �b�r�u�p�Œ�l
  cc_itoen             CONSTANT CHAR(3)      := '001';              -- ��ЃR�[�h�i001:�Œ�j
  cd_sysdate           DATE                  := SYSDATE;            -- �����J�n����
  cc_output            CONSTANT CHAR(1)      := 'w';                -- �o�̓X�e�[�^�X
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �ғ����J�����_�}�X�^�����i�[���郌�R�[�h
  TYPE csv_out_rec  IS RECORD(
       calendar_ymd    CHAR(8),    -- �J�����_�[���t
       calendar_flg    NUMBER(1)   -- �ғ����t���O
  );
--
  -- �ғ����J�����_�}�X�^�����i�[����e�[�u���^�̒�`
  TYPE csv_out_tbl  IS TABLE OF csv_out_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_directory      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C���p�X��
  gv_file_name      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C����
  gv_calender_cd    VARCHAR2(60);          -- �v���t�@�C���E�J�����_�[�R�[�h
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_csv_file       VARCHAR2(5000);        -- �o�͏��
  gt_csv_out_tbl    csv_out_tbl;           -- �����z��̒�`
  gc_del_flg        CHAR(1) := ' ';        -- CSV�폜�t���O('1':�폜)

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
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
    lv_file_chk   boolean;   --���݃`�F�b�N����
    lv_file_size  number;    --�t�@�C���T�C�Y
    lv_block_size number;   --�u���b�N�T�C�Y
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
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --���̓p�����[�^�Ȃ����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    -- �ғ����J�����_�A�g�pCSV�t�@�C���o�͐�擾
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_directory IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_dir_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �ғ����J�����_�A�g�pCSV�t�@�C�����擾
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_fil_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- �ɓ����c�Ɠ��p�J�����_�R�[�h�擾
    gv_calender_cd := FND_PROFILE.VALUE(cv_prf_calender_cd);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_calender_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_calender_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --IF�t�@�C�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_file_name
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_file_name
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    -- ===============================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- �t�@�C�����ݎ��G���[
    IF (lv_file_chk = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_csv_file_err
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- ===============================
    -- �ғ����J�����_�O���`�F�b�N
    -- ===============================

    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   bom_calendar_dates bcd
      WHERE  bcd.calendar_code = gv_calender_cd
      AND    ROWNUM = 1;
    EXCEPTION
      -- �f�[�^�Ȃ��̏ꍇ�G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- CSV�t�@�C���I�[�v������
    -- ===============================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                      gv_directory    -- �o�͐�
                     ,gv_file_name    -- CSV�t�@�C����
                     ,cc_output       -- �o�̓X�e�[�^�X
                     );
    EXCEPTION
      -- �t�@�C���p�X�s���G���[
      WHEN UTL_FILE.INVALID_PATH THEN
        gn_target_cnt := 0;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_pass_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;


    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN                           --*** <��O�R�����g> ***
      ov_errmsg  := lv_errmsg;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    lv_sep_com      CONSTANT VARCHAR2(1)  := ',';     -- �J���}
    lv_char_dq      CONSTANT VARCHAR2(1)  := '"';     -- �_�u���N�H�[�e�[�V����
--
    -- *** ���[�J���ϐ� ***
    lc_last_update   CHAR(14); -- �X�V���t(YYYYMMDDHH24MISS)
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
    lc_last_update := TO_CHAR(cd_sysdate, 'YYYYMMDDHH24MISS');
--
    <<gt_csv_out_tbl_loop>>
    FOR out_cnt IN 1 .. gn_target_cnt LOOP
      gv_csv_file   := lv_char_dq || cc_itoen || lv_char_dq   -- ��ЃR�[�h�i�Œ�l:"001")
      || lv_sep_com || gt_csv_out_tbl(out_cnt).calendar_ymd   -- �J�����_�[���t
      || lv_sep_com || gt_csv_out_tbl(out_cnt).calendar_flg   -- �ғ����t���O
      || lv_sep_com || lc_last_update                         -- �ŏI�X�V����
      ;
--
      BEGIN
      -- CSV�t�@�C���֏o��
        UTL_FILE.PUT_LINE(gf_file_hand,gv_csv_file);

      EXCEPTION
        WHEN UTL_FILE.INVALID_OPERATION THEN       -- �t�@�C���A�N�Z�X�����G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_file_priv_err
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN UTL_FILE.WRITE_ERROR THEN   -- CSV�f�[�^�o�̓G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_csv_data_err
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_calender_date_nm
                      ,iv_token_name2  => cv_tkn_ng_data
                      ,iv_token_value2 => gt_csv_out_tbl(out_cnt).calendar_ymd
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;

         -- ���팏��
      gn_normal_cnt := gn_normal_cnt + 1;

    END LOOP gt_csv_out_tbl_loop;


    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   ####################################
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
    -- �ғ����J�����^�e�[�u���擾�J�[�\��
    CURSOR calender_cur
    IS
      SELECT TO_CHAR(bcd.calendar_date,'YYYYMMDD')   calendar_ymd,  -- �J�����_�[���t
             DECODE(bcd.seq_num,NULL,0,1)            calendar_flg   -- �ғ����t���O
      FROM   bom_calendar_dates bcd
      WHERE  bcd.calendar_code = gv_calender_cd
      ORDER  BY calendar_ymd;
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
    gc_del_flg    := ' ';
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
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �ғ����J�����^�e�[�u�����擾(A-2)
    -- ====================================
--
    OPEN calender_cur;
--
    <<calender_loop>>
    LOOP
      FETCH calender_cur BULK COLLECT INTO gt_csv_out_tbl;
      EXIT WHEN calender_cur%NOTFOUND;

    END LOOP calender_loop;
--
    CLOSE calender_cur;

    gn_target_cnt := gt_csv_out_tbl.COUNT; -- ��������

    -- ===============================
    -- CSV�t�@�C���o�͏���(A-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���������Ȃ��̏ꍇ
    IF (gn_normal_cnt = 0) THEN
      gc_del_flg    := '1';   --CSV�폜
    END IF;

    IF (lv_retcode = cv_status_error) THEN
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
      RAISE global_process_expt;
    END IF;

    -- ===============================
    -- �I������(A-4)
    -- ===============================

    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);

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
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
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
    cv_prg_name        CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
--
    -- ���b�Z�[�W�ԍ�(���ʁEIF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
--    cv_skip_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
--    cv_warn_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    ln_cvs_cnt      NUMBER;          -- CSV�폜�t���O
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

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );


--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --�ُ�G���[���́A���������O���A�G���[�����P���ƌŒ�\��
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
    END IF;

    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );

    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF(lv_retcode = cv_status_warn) THEN --�x���I�� ���g�p
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    -- CSV�t�@�C�����폜����(�Ώی����������Đ����������O���̏ꍇ)
    IF  (gc_del_flg = '1')  THEN
      UTL_FILE.FREMOVE(gv_directory,   -- �o�͐�
                       gv_file_name    -- CSV�t�@�C����
      );
    END IF;

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
END XXCMM006A04C;
/
