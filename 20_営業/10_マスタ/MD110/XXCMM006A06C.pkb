CREATE OR REPLACE PACKAGE BODY XXCMM006A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A06C(body)
 * Description      : �̎�}�X�^IF�o��(���n)
 * MD.050           : �̎�}�X�^IF�o��(���n) MD050_CMM_006_A06
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_contract_data      �̎�����}�X�^���擾�v���V�[�W��(A-2)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS ���� �M�q    ����쐬
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM006A06C';               -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';       -- �A�g�pCSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A06_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '�ڋq�R�[�h';
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
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- �Ώۃf�[�^����
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
  -- �Œ�l(�ݒ�l�A���o����)
  cv_company_cd             CONSTANT VARCHAR2(3)   := '001';                        -- ��ЃR�[�h
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
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gc_del_flg                CHAR(1);              -- �t�@�C���폜�t���O(�Ώۃf�[�^�����̏ꍇ)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR get_contract_data_cur
  IS
    SELECT   cust_code,             -- �ڋq�R�[�h
             calc_type,             -- �v�Z����
             container_type_code,   -- �e��敪
             selling_price,         -- ����
             bm1_pct,               -- BM1��(%)
             bm1_amt,               -- BM1���z
             bm2_pct,               -- BM2��(%)
             bm2_amt,               -- BM2���z
             bm3_pct,               -- BM3��(%)
             bm3_amt,               -- BM3���z
             calc_target_flag,      -- �v�Z�Ώۃt���O
             start_date_active,     -- �L����(from)
             end_date_active        -- �L����(to)
    FROM     xxcok_mst_bm_contract
    ORDER BY cust_code,calc_type,container_type_code,start_date_active
  ;
  TYPE g_contract_data_ttype IS TABLE OF get_contract_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_contract_data            g_contract_data_ttype;
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
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_90008           -- �R���J�����g���̓p�����[�^�Ȃ�
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��(���̓p�����[�^�̉�)
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
    -- ��s�}��(I/F�t�@�C�����̉�)
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
   * Procedure Name   : get_contract_data
   * Description      : �̎�����}�X�^���擾�v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data';       -- �v���O������
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
    OPEN get_contract_data_cur;
    --
    -- �f�[�^�̈ꊇ�擾
    FETCH get_contract_data_cur BULK COLLECT INTO gt_contract_data;
    --
    -- �Ώی������Z�b�g
    gn_target_cnt := gt_contract_data.COUNT;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_contract_data_cur;
    --
    -- �����ΏۂƂȂ�f�[�^�����݂��邩���`�F�b�N
    IF (gn_target_cnt = 0) THEN
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�̓v���V�[�W��(A-3)
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
    <<out_loop>>
    FOR ln_loop_cnt IN gt_contract_data.FIRST..gt_contract_data.LAST LOOP
      lv_csv_text := cv_enclosed || cv_company_cd || cv_enclosed || cv_delimiter                           -- ��ЃR�[�h
        || cv_enclosed || gt_contract_data(ln_loop_cnt).cust_code || cv_enclosed || cv_delimiter           -- �ڋq�R�[�h
        || cv_enclosed || gt_contract_data(ln_loop_cnt).calc_type || cv_enclosed || cv_delimiter           -- �v�Z����
        || cv_enclosed || gt_contract_data(ln_loop_cnt).container_type_code || cv_enclosed || cv_delimiter -- �v�Z����-�e��敪
        || gt_contract_data(ln_loop_cnt).SELLING_PRICE || cv_delimiter                                     -- �v�Z����-����
        || gt_contract_data(ln_loop_cnt).bm1_pct || cv_delimiter                                           -- BM1��
        || gt_contract_data(ln_loop_cnt).bm1_amt || cv_delimiter                                           -- BM1���z
        || gt_contract_data(ln_loop_cnt).bm2_pct || cv_delimiter                                           -- BM2��
        || gt_contract_data(ln_loop_cnt).bm2_amt || cv_delimiter                                           -- BM2���z
        || gt_contract_data(ln_loop_cnt).bm3_pct || cv_delimiter                                           -- BM3��
        || gt_contract_data(ln_loop_cnt).bm3_amt || cv_delimiter                                           -- BM3���z
        || cv_enclosed || gt_contract_data(ln_loop_cnt).calc_target_flag || cv_enclosed || cv_delimiter    -- �v�Z�Ώۃt���O
        || TO_CHAR(gt_contract_data(ln_loop_cnt).start_date_active,'YYYYMMDD') || cv_delimiter             -- �L���J�n��
        || TO_CHAR(gt_contract_data(ln_loop_cnt).end_date_active,'YYYYMMDD') || cv_delimiter               -- �L���I����
        || TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS')
      ;
      BEGIN
        -- �t�@�C����������
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- �t�@�C���A�N�Z�X�����G���[
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                             -- �t�@�C���A�N�Z�X�����G���[
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSV�f�[�^�o�̓G���[
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                             -- CSV�f�[�^�o�̓G���[
                          ,iv_token_name1  => cv_tkn_word                              -- �g�[�N��(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                              -- �g�[�N��(NG_DATA)
                          ,iv_token_value2 => gt_contract_data(ln_loop_cnt).cust_code  -- NG_WORD��DATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      -- ���������̃J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP out_loop;
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
    --  �̎�����}�X�^���擾�v���V�[�W��(A-2)
    -- =====================================================
    get_contract_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSV�t�@�C���o�̓v���V�[�W��(A-3)
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
    --  �I�������v���V�[�W��(A-4)
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
      -- ��s�}��(�����������̏�)
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
    -- ��s�}��(�I�����b�Z�[�W�̏�)
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
END XXCMM006A06C;
/
