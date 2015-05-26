CREATE OR REPLACE PACKAGE BODY APPS.XXCOI010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI010A05C(body)
 * Description      : �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^HHT�A�g
 * MD.050           : �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^HHT�A�g MD050_COI_010_A05
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                                     (A-1)
 *                         �f�[�^���o                                   (A-2)
 *  create_csv_file        �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^CSV�o��  (A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/04/21    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
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
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A05C';     -- �p�b�P�[�W��
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�v���P�[�V�����Z�k���FXXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- �A�v���P�[�V�����Z�k���FXXCOI
--
  -- ���b�Z�[�W
  cv_msg_coi_00003            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_msg_coi_00004            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- �t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_coi_00008            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_coi_00011            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_coi_00023            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00023'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_coi_00027            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_coi_00028            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_coi_00029            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_coi_10700            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10700'; -- ���_�R�[�h�s�����b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �v���t�@�C����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- �f�B���N�g����
  cv_tkn_base_code            CONSTANT VARCHAR2(20)  := 'BASE_CODE';        -- ���_�R�[�h
  cv_tkn_out_base_code        CONSTANT VARCHAR2(20)  := 'OUT_BASE_CODE';    -- ����拒�_�R�[�h
--
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_dir_name          VARCHAR2(50);          -- �f�B���N�g����
  gv_file_name         VARCHAR2(50);          -- �t�@�C����
  g_file_handle        UTL_FILE.FILE_TYPE;    -- �t�@�C���n���h��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  remain_file_expt          EXCEPTION;     -- �t�@�C�����݃G���[
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C��
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';    -- XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
    cv_prf_file_other_base     CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_OTHER_BASE'; -- XXCOI:�����_�c�Ǝԓ��o�ɃZ�L�����e�BIF�o�̓t�@�C����
--
    cv_slash                   CONSTANT VARCHAR2(1) :=  '/';  -- �X���b�V��
--
    -- *** ���[�J���ϐ� ***
    lv_dire_path               VARCHAR2(100);                 -- �f�B���N�g���t���p�X�i�[�ϐ�
    lv_file_name               VARCHAR2(100);                 -- �t�@�C�����i�[�ϐ�
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
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_msg_coi_00023
                  );
    -- ���b�Z�[�W�o��
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
    -- ===============================
    -- �v���t�@�C���F�f�B���N�g�����擾
    -- ===============================
    -- �f�B���N�g�����擾
    gv_dir_name := fnd_profile.value( cv_prf_dire_out_hht );
--
    -- �f�B���N�g�������擾�ł��Ȃ��ꍇ
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_coi_00003  -- �f�B���N�g�����擾�G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�B���N�g���p�X�擾
    BEGIN
      SELECT ad.directory_path AS directory_path -- �f�B���N�g���p�X
      INTO   lv_dire_path -- �f�B���N�g���p�X
      FROM   all_directories ad -- �f�B���N�g���}�X�^
      WHERE  ad.directory_name  = gv_dir_name; -- �f�B���N�g����
    EXCEPTION
      -- �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_msg_coi_00029 -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dir_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �v���t�@�C���F�t�@�C�����擾
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_other_base );
--
    -- �t�@�C�������擾�ł��Ȃ��ꍇ
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_msg_coi_00004  -- �t�@�C�����擾�G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_other_base
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j�o��
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_coi_00028  -- �t�@�C�����o�̓��b�Z�[�W
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
                    );
    -- ���b�Z�[�W�o��
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
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : create_csv_file
   * Description      : �����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^CSV�쐬(A-3)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'create_csv_file'; -- �v���O������
    cv_lookup_other_base CONSTANT VARCHAR2(100) := 'XXCOI1_OTHER_BASE_INOUT_SECURE'; -- �Q�ƃ^�C�v
    cv_cust_class_1      CONSTANT VARCHAR2(1)   := '1';               -- �ڋq�敪:1�i���_�j
    cv_language          CONSTANT VARCHAR2(100) := USERENV('LANG');   -- ����
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
    cv_delimiter     CONSTANT VARCHAR2(1) := ',';  -- ��؂蕶��
    cv_encloser      CONSTANT VARCHAR2(1) := '"';  -- ���蕶��
--
    -- *** ���[�J���ϐ� ***
    lv_csv_file      VARCHAR2(1500);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���o(A-2)
    CURSOR get_other_base_sec_cur
    IS
      SELECT SUBSTRB(flv.lookup_code,1,4) AS base_code            -- �e���_�R�[�h
            ,SUBSTRB(flv.meaning,1,4)     AS other_base_code      -- ����拒�_�R�[�h
            ,flv.description              AS other_warehouse_code -- �����q��
            ,hca1.account_number          AS base_code1           -- ���_�R�[�h1
            ,hca2.account_number          AS base_code2           -- ���_�R�[�h2
      FROM   fnd_lookup_values flv -- �N�C�b�N�R�[�h
            ,hz_cust_accounts hca1 -- �ڋq�}�X�^1
            ,hz_cust_accounts hca2 -- �ڋq�}�X�^2
      WHERE  flv.lookup_type             = cv_lookup_other_base  -- �^�C�v
      AND    flv.enabled_flag            = cv_flag_y             -- �L���t���O
      AND    flv.language                = cv_language           -- ����
      AND    hca1.account_number(+)      = SUBSTRB(flv.lookup_code,1,4) -- �ڋq�R�[�h1
      AND    hca1.customer_class_code(+) = cv_cust_class_1              -- �ڋq�敪
      AND    hca2.account_number(+)      = SUBSTRB(flv.meaning,1,4)     -- �ڋq�R�[�h2
      AND    hca2.customer_class_code(+) = cv_cust_class_1              -- �ڋq�敪
      ORDER BY 
             base_code             -- �e���_�R�[�h
            ,other_base_code       -- ����拒�_�R�[�h
            ,other_warehouse_code  -- �����q��
    ;
--
    -- *** ���[�J���E���R�[�h ***
    get_other_base_sec_rec  get_other_base_sec_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    lv_csv_file := NULL;
--
    -- ===============================
    -- ���[�v�J�n
    -- ===============================
    OPEN get_other_base_sec_cur;
--
    <<output_loop>>
    LOOP
      FETCH get_other_base_sec_cur INTO get_other_base_sec_rec;
      EXIT WHEN get_other_base_sec_cur%NOTFOUND;
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���_�R�[�h1�܂��͋��_�R�[�h2��NULL�̏ꍇ�i���_���s���ȏꍇ�j
      IF ( (get_other_base_sec_rec.base_code1 IS NULL)
        OR (get_other_base_sec_rec.base_code2 IS NULL) )
      THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_xxcoi
                        , iv_name         => cv_msg_coi_10700  -- ���_�R�[�h�s�����b�Z�[�W
                        , iv_token_name1  => cv_tkn_base_code
                        , iv_token_value1 => get_other_base_sec_rec.base_code       -- �e���_�R�[�h
                        , iv_token_name2  => cv_tkn_out_base_code
                        , iv_token_value2 => get_other_base_sec_rec.other_base_code -- ����拒�_�R�[�h
                      );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => gv_out_msg
        );
--
        -- �X�L�b�v�����J�E���g
        gn_skip_cnt := gn_skip_cnt + 1;
--
      ELSE
        -- �o�͕�������쐬
        lv_csv_file := (
          cv_encloser || get_other_base_sec_rec.base_code            || cv_encloser  || cv_delimiter ||  -- �e���_�R�[�h
          cv_encloser || get_other_base_sec_rec.other_base_code      || cv_encloser  || cv_delimiter ||  -- ����拒�_�R�[�h
          cv_encloser || get_other_base_sec_rec.other_warehouse_code || cv_encloser                      -- �����q��
        );
--
        -- ===============================
        -- CSV�o��
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- ���������J�E���g
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
--
    END LOOP output_loop;
--
    CLOSE get_other_base_sec_cur;
--
    -- ===============================
    -- ���o0���`�F�b�N
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_coi_00008
                    );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă���ꍇ�̓N���[�Y
      IF (get_other_base_sec_cur%ISOPEN) THEN
        CLOSE get_other_base_sec_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_open_mode    CONSTANT VARCHAR2(1) := 'w';  -- �I�[�v�����[�h�F��������
--
    -- *** ���[�J���ϐ� ***
    ln_file_length  NUMBER;        -- �t�@�C���̒����̕ϐ�
    ln_block_size   NUMBER;        -- �u���b�N�T�C�Y�̕ϐ�
    lb_fexists      BOOLEAN;       -- �t�@�C�����݃`�F�b�N����
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
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_skip_cnt     := 0;
    gn_error_cnt    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTL�t�@�C���I�[�v��
    -- ===============================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR(
        location    => gv_dir_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    -- ����t�@�C�������݂���ꍇ
    IF( lb_fexists = TRUE ) THEN
      -- ����t�@�C�����݃`�F�b�N�G���[
      RAISE remain_file_expt;
    END IF;
--
    -- �t�@�C���̃I�[�v��
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dir_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- �f�[�^���o/�����_�c�Ǝԓ��o�ɃZ�L�����e�B�}�X�^CSV�o�� (A-2,A-3)
    -- ===============================
    create_csv_file(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTL�t�@�C���N���[�Y
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_msg_coi_00027
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
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
      errbuf              OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode             OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
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
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[�̏ꍇ�A�G���[�����̂�1���ɐݒ�
      gn_target_cnt := 0; -- �Ώی���
      gn_normal_cnt := 0; -- ��������
      gn_skip_cnt   := 0; -- �X�L�b�v����
      gn_error_cnt  := 1; -- �G���[����
      --�G���[�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- �G���[���b�Z�[�W
      );
    END IF;
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
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
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_warn_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
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
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      IF ( gn_skip_cnt <> 0 ) THEN
        lv_message_code := cv_warn_msg;
        lv_retcode := cv_status_warn;
      ELSE
        lv_message_code := cv_normal_msg;
      END IF;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
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
END XXCOI010A05C;
/
