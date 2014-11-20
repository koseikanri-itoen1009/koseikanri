CREATE OR REPLACE PACKAGE BODY XXCOI010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A02C(body)
 * Description      : �C�Â����IF�o��
 * MD.050           : �C�Â����IF�o�� MD050_COI_010_A02
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  chk_main_store_div     ���C���q�ɋ敪�`�F�b�N (A-3)
 *  get_awareness          �C�Â���񒊏o (A-4)
 *  chk_main_repeat        ���C���q�ɏd���`�F�b�N (A-5)
 *  submain                ���C�������v���V�[�W��
 *                         UTL�t�@�C���I�[�v�� (A-2)
 *                         �C�Â����CSV�쐬 (A-6)
 *                         UTL�t�@�C���N���[�Y (A-7)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   T.Nakamura       �V�K�쐬
 *  2009/03/30    1.1   T.Nakamura       [��QT1_0083]IF���ڂ̌������C��
 *                                       [��QT1_0084]IF���ڂ̌`�����C��
 *  2009/04/21    1.2   T.Nakamura       [��QT1_0580]���C���q�ɏd���`�F�b�N��ǉ�
 *  2010/02/16    1.3   N.Abe            [E_�{�ғ�_01593]�ۊǏꏊ�̖��������Q��
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A02C';     -- �p�b�P�[�W��
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�v���P�[�V�����Z�k���FXXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- �A�v���P�[�V�����Z�k���FXXCOI
--
  -- ���b�Z�[�W
  cv_no_para_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_sold_out_mc_get_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10322'; -- ���؂�΍􃁃b�Z�[�W�F�擾�G���[
  cv_supl_rate_mc_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10323'; -- ��[���΍􃁃b�Z�[�W�F�擾�G���[
  cv_hot_inv_mc_get_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10324'; -- �z�b�g�݌ɑ΍􃁃b�Z�[�W�F�擾�G���[
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- �t�@�C�����擾�G���[���b�Z�[�W
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_main_store_d_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10009'; -- ���C���q�ɋ敪�`�F�b�N�G���[���b�Z�[�W
  cv_sold_out_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10331'; -- ���؂�΍􃁃b�Z�[�W
  cv_supl_rate_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10332'; -- ��[���΍􃁃b�Z�[�W
  cv_hot_inv_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10333'; -- �z�b�g�݌ɑ΍􃁃b�Z�[�W
  cv_column_exist_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10334'; -- ���b�Z�[�W.�R��������܂�
-- == 2009/04/21 V1.2 Added START ===============================================================
  cv_main_repeat_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10379'; -- ���C���q�ɋ敪�d���G���[���b�Z�[�W
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
  -- �g�[�N��
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �v���t�@�C����
  cv_tkn_base_code_tok        CONSTANT VARCHAR2(20)  := 'BASE_CODE_TOK';    -- ���_�R�[�h
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- �f�B���N�g����
  cv_tkn_time                 CONSTANT VARCHAR2(20)  := 'TIME';             -- ����
  cv_tkn_rate                 CONSTANT VARCHAR2(20)  := 'RATE';             -- ��
  cv_tkn_day                  CONSTANT VARCHAR2(20)  := 'DAY';              -- ����
--
  cv_subinv_type_store        CONSTANT VARCHAR2(1)   := '1';                -- �ۊǏꏊ�敪�F�q��
  cv_main_store_div_y         CONSTANT VARCHAR2(1)   := 'Y';                -- ���C���q�ɋ敪�F'Y'
  cv_cust_class_code_base     CONSTANT VARCHAR2(1)   := '1';                -- �ڋq�敪�F���_
  cv_dept_hht_div_dummy       CONSTANT VARCHAR2(1)   := '9';                -- �S�ݓXHHT�敪�F�_�~�[
  cv_dept_hht_div_dept        CONSTANT VARCHAR2(1)   := '1';                -- �S�ݓXHHT�敪�F�S�ݓX
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date        DATE;                -- �Ɩ����t
  gv_sold_out_msg_color  VARCHAR2(100);       -- ���؂�΍􃁃b�Z�[�W�F
  gv_supl_rate_msg_color VARCHAR2(100);       -- ��[���΍􃁃b�Z�[�W�F
  gv_hot_inv_msg_color   VARCHAR2(100);       -- �z�b�g�݌ɑ΍􃁃b�Z�[�W�F
  gv_dire_name           VARCHAR2(50);        -- �f�B���N�g����
  gv_file_name           VARCHAR2(50);        -- �t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �C�Â���񒊏o
  CURSOR get_awareness_cur
  IS
    SELECT   msi.attribute7             AS sale_base_code                   -- ���㋒�_�R�[�h
           , msi.attribute8             AS sold_out_time                    -- ���؂ꎞ��
           , msi.attribute9             AS supl_rate                        -- ��[��
           , msi.attribute10            AS hot_inv                          -- �z�b�g�݌�
    FROM     mtl_secondary_inventories  msi                                 -- �ۊǏꏊ�}�X�^
           , hz_cust_accounts           hca                                 -- �ڋq�}�X�^
           , xxcmm_cust_accounts        xca                                 -- �ڋq�ǉ����
    WHERE    msi.attribute1             =  cv_subinv_type_store             -- �擾�����F�ۊǏꏊ�敪��'1'(�q��)
    AND      msi.attribute6             =  cv_main_store_div_y              -- �擾�����F���C���q�ɋ敪��'Y'
    AND      NVL( msi.disable_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
                                        >  gd_process_date                  -- �擾�����F��������NULL���Ɩ����t����
    AND      hca.account_number         =  msi.attribute7                   -- ���������F�ڋq�}�X�^�ƕۊǏꏊ�}�X�^
    AND      hca.customer_class_code    =  cv_cust_class_code_base          -- �擾�����F�ڋq�敪�����_
    AND      xca.customer_id            =  hca.cust_account_id              -- ���������F�ڋq�ǉ����ƌڋq�}�X�^
    AND      NVL( xca.dept_hht_div, cv_dept_hht_div_dummy )
                                        <> cv_dept_hht_div_dept             -- �擾�����F�S�ݓXHHT�敪��'1'(�S�ݓX)�ȊO
    ;
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���e�[�u��
  -- ==============================
  TYPE g_get_awareness_ttype IS TABLE OF get_awareness_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_get_awareness_tab        g_get_awareness_ttype;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  file_exist_expt           EXCEPTION;     -- �t�@�C�����݃G���[
  no_data_expt              EXCEPTION;     -- �Ώۃf�[�^0���G���[
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
    -- �v���t�@�C�� XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- �v���t�@�C�� XXCOI:�C�Â����IF�o�̓t�@�C����
    cv_prf_file_awareness      CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_AWARENESS';
    -- �v���t�@�C�� XXCOI:���؂�΍􃁃b�Z�[�W�F
    cv_prf_sold_out_msg_color  CONSTANT VARCHAR2(30) := 'XXCOI1_SOLD_OUT_MSG_COLOR';
    -- �v���t�@�C�� XXCOI:��[���΍􃁃b�Z�[�W�F
    cv_prf_supl_rate_msg_color CONSTANT VARCHAR2(30) := 'XXCOI1_SUPL_RATE_MSG_COLOR';
    -- �v���t�@�C�� XXCOI:�z�b�g�݌ɑ΍􃁃b�Z�[�W�F
    cv_prf_hot_inv_msg_color   CONSTANT VARCHAR2(30) := 'XXCOI1_HOT_INV_MSG_COLOR';
--
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- �X���b�V��
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
    -- ==============================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- ==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name_xxccp
                    , iv_name        => cv_no_para_msg
                  );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- �v���t�@�C���F���؂�΍􃁃b�Z�[�W�F�擾
    -- ==============================================================
    gv_sold_out_msg_color := fnd_profile.value( cv_prf_sold_out_msg_color );
    -- ���؂�΍􃁃b�Z�[�W�F���擾�ł��Ȃ��ꍇ
    IF ( gv_sold_out_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_sold_out_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_sold_out_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- �v���t�@�C���F��[���΍􃁃b�Z�[�W�F�擾
    -- ==============================================================
    gv_supl_rate_msg_color := fnd_profile.value( cv_prf_supl_rate_msg_color );
    -- ��[���΍􃁃b�Z�[�W�F���擾�ł��Ȃ��ꍇ
    IF ( gv_supl_rate_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_supl_rate_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_supl_rate_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- �v���t�@�C���F�z�b�g�݌ɑ΍􃁃b�Z�[�W�F�擾
    -- ==============================================================
    gv_hot_inv_msg_color := fnd_profile.value( cv_prf_hot_inv_msg_color );
    -- �z�b�g�݌ɑ΍􃁃b�Z�[�W�F���擾�ł��Ȃ��ꍇ
    IF ( gv_hot_inv_msg_color IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_hot_inv_mc_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_hot_inv_msg_color
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���F�f�B���N�g�����擾
    -- ===============================
    -- �f�B���N�g�����擾
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- �f�B���N�g�������擾�ł��Ȃ��ꍇ
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�B���N�g���p�X�擾
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �v���t�@�C���F�t�@�C�����擾
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_awareness );
    -- �t�@�C�������擾�ł��Ȃ��ꍇ
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_awareness
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
                      , iv_name         => cv_file_name_msg
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : chk_main_store_div
   * Description      : ���C���q�ɋ敪�`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_main_store_div(
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      on_chk_cnt    OUT NUMBER        --   �`�F�b�N�����J�E���g
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- == 2009/04/21 V1.2 Moded END   ===============================================================
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_main_store_div'; -- �v���O������
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
-- == 2009/04/21 V1.2 Added START ===============================================================
    ln_chk_cnt  NUMBER;  -- �`�F�b�N�����J�E���g
-- == 2009/04/21 V1.2 Added END   ===============================================================
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���C���q�ɋ敪�`�F�b�N
    CURSOR chk_main_store_div_cur
    IS
      SELECT    msi.attribute7             AS base_code             -- ���_�R�[�h
      FROM      mtl_secondary_inventories  msi                      -- �ۊǏꏊ�}�X�^
      WHERE     msi.attribute1             =  cv_subinv_type_store  -- ���o�����F�ۊǏꏊ�敪��'1'
-- == 2010/02/16 V1.3 Added START ===============================================================
      AND       NVL(msi.disable_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
                                           >  gd_process_date       -- �擾�����F��������NULL���Ɩ����t����
-- == 2010/02/16 V1.3 Added END   ===============================================================
      GROUP BY  msi.attribute7                                      -- �W������F���_�R�[�h
      MINUS                                                         -- �}�[�W�F�}�C�i�X
      SELECT    msi.attribute7             AS base_code             -- ���_�R�[�h
      FROM      mtl_secondary_inventories  msi                      -- �ۊǏꏊ�}�X�^
      WHERE     msi.attribute6             =  cv_main_store_div_y   -- ���o�����F���C���q�ɋ敪��'Y'
      AND       msi.attribute1             =  cv_subinv_type_store  -- ���o�����F�ۊǏꏊ�敪��'1'
-- == 2010/02/16 V1.3 Added START ===============================================================
      AND       NVL(msi.disable_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
                                           >  gd_process_date       -- �擾�����F��������NULL���Ɩ����t����
-- == 2010/02/16 V1.3 Added END   ===============================================================
      GROUP BY  msi.attribute7                                      -- �W������F���_�R�[�h
      ;
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
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- �ϐ��̏�����
    ln_chk_cnt  :=  0;
-- == 2009/04/21 V1.2 Added END   ===============================================================
    <<chk_main_store_div_loop>>
    FOR l_chk_main_store_div_rec IN chk_main_store_div_cur LOOP
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_main_store_d_err_msg
                      , iv_token_name1  => cv_tkn_base_code_tok
                      , iv_token_value1 => l_chk_main_store_div_rec.base_code
                    );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
      );
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      -- �x�������J�E���g
--      gn_warn_cnt := gn_warn_cnt + 1;
      -- �`�F�b�N�����J�E���g
      ln_chk_cnt := ln_chk_cnt + 1;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    END LOOP chk_main_store_div_loop;
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- �o�̓p�����[�^�̃Z�b�g
    on_chk_cnt  :=  ln_chk_cnt;
-- == 2009/04/21 V1.2 Added END   ===============================================================
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
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( chk_main_store_div_cur%ISOPEN ) THEN
        CLOSE chk_main_store_div_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_main_store_div;
--
  /**********************************************************************************
   * Procedure Name   : get_awareness
   * Description      : �C�Â���񒊏o (A-4)
   ***********************************************************************************/
  PROCEDURE get_awareness(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_awareness'; -- �v���O������
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
    -- �J�[�\���I�[�v��
    OPEN  get_awareness_cur;
--
    -- �J�[�\���f�[�^�擾
    FETCH get_awareness_cur BULK COLLECT INTO g_get_awareness_tab;
--
    -- �J�[�\���̃N���[�Y
    CLOSE get_awareness_cur;
--
    -- ===============================
    -- ���o0���`�F�b�N
    -- ===============================
    IF ( g_get_awareness_tab.COUNT = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �Ώۃf�[�^0���G���[
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_awareness_cur%ISOPEN ) THEN
        CLOSE get_awareness_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_awareness;
--
-- == 2009/04/21 V1.2 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : chk_main_repeat
   * Description      : ���C���q�ɏd���`�F�b�N (A-5)
   ***********************************************************************************/
  PROCEDURE chk_main_repeat(
      iv_base_code  IN  VARCHAR2      --   ���_�R�[�h
    , ob_chk_status OUT BOOLEAN       --   �d���`�F�b�N�X�e�[�^�X
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_main_repeat'; -- �v���O������
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
    lt_base_code       mtl_secondary_inventories.attribute7%TYPE; -- ���_�R�[�h
    ln_main_store_cnt  NUMBER;                                    -- ���_�����C���q�Ɍ���
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
    -- �ϐ��̏�����
    lt_base_code       := NULL;
    ln_main_store_cnt  := NULL;
    ob_chk_status      := TRUE;
--
    -- ���C���q�ɏd���`�F�b�N
    SELECT    msi.attribute7             AS base_code             -- ���_�R�[�h
            , COUNT(1)                   AS main_store_cnt        -- ���_�����C���q�Ɍ���
    INTO      lt_base_code
            , ln_main_store_cnt
    FROM      mtl_secondary_inventories  msi                      -- �ۊǏꏊ�}�X�^
    WHERE     msi.attribute6             =  cv_main_store_div_y   -- ���o�����F���C���q�ɋ敪��'Y'
    AND       msi.attribute1             =  cv_subinv_type_store  -- ���o�����F�ۊǏꏊ�敪��'1'
    AND       NVL( msi.disable_date, TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
                                         >  gd_process_date       -- �擾�����F��������NULL���Ɩ����t����
    AND       msi.attribute7             =  iv_base_code          -- �擾�����F���_�R�[�h�����̓p�����[�^
    GROUP BY  msi.attribute7                                      -- �W������F���_�R�[�h
    ;
--
    -- ���ꋒ�_���Ƀ��C���q�ɂ��������݂���ꍇ
    IF ( ln_main_store_cnt > 1 ) THEN
--
      -- �d���`�F�b�N�X�e�[�^�X���X�V
      ob_chk_status := FALSE;
--
      -- ���C���q�ɏd���G���[���b�Z�[�W
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_main_repeat_err_msg
                      , iv_token_name1  => cv_tkn_base_code_tok
                      , iv_token_value1 => lt_base_code
                    );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
      );
--
      -- �x�������J�E���g
      gn_warn_cnt := gn_warn_cnt + 1;
--
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
  END chk_main_repeat;
--
-- == 2009/04/21 V1.2 Added END   ===============================================================
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
    cv_open_mode             CONSTANT VARCHAR2(1)   := 'w';              -- �I�[�v�����[�h�F��������
    cv_delimiter             CONSTANT VARCHAR2(1)   := ',';              -- ��؂蕶��
    cv_encloser              CONSTANT VARCHAR2(1)   := '"';              -- ���蕶��
--
    -- *** ���[�J���ϐ� ***
    ln_file_length           NUMBER;                       -- �t�@�C���̒����̕ϐ�
    ln_block_size            NUMBER;                       -- �u���b�N�T�C�Y�̕ϐ�
    lb_fexists               BOOLEAN;                      -- �t�@�C�����݃`�F�b�N����
    lv_sold_out_msg          VARCHAR2(50);                 -- ���؂�΍􃁃b�Z�[�W
    lv_supl_rate_msg         VARCHAR2(50);                 -- ��[���΍􃁃b�Z�[�W
    lv_hot_inv_msg           VARCHAR2(50);                 -- �z�b�g�݌ɑ΍􃁃b�Z�[�W
    lv_column_exist_msg      VARCHAR2(50);                 -- �R��������܂����b�Z�[�W
    lv_csv_file              VARCHAR2(1500);               -- CSV�t�@�C��
    l_file_handle            UTL_FILE.FILE_TYPE;           -- �t�@�C���n���h��
-- == 2009/04/21 V1.2 Added START ===============================================================
    ln_main_chk_cnt          NUMBER;                       -- ���C���q�ɋ敪�`�F�b�N�����J�E���g
    lb_chk_status            BOOLEAN;                      -- ���C���q�ɏd���`�F�b�N�X�e�[�^�X
-- == 2009/04/21 V1.2 Added END   ===============================================================
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
-- == 2009/04/21 V1.2 Added START ===============================================================
    -- ���[�J���ϐ��̏�����
    ln_main_chk_cnt := 0;
    lb_chk_status   := NULL;
-- == 2009/04/21 V1.2 Added END   ===============================================================
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
    -- UTL�t�@�C���I�[�v�� (A-2)
    -- ===============================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE file_exist_expt;
    END IF;
--
    -- �t�@�C���̃I�[�v��
    l_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- ���C���q�ɋ敪�`�F�b�N(A-3)
    -- ===============================
    chk_main_store_div(
-- == 2009/04/21 V1.2 Added START ===============================================================
--        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        on_chk_cnt => ln_main_chk_cnt   -- ���C���q�ɋ敪�`�F�b�N�����J�E���g
      , ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- == 2009/04/21 V1.2 Added END   ===============================================================
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �C�Â���񒊏o(A-4)
    -- ===============================
    get_awareness(
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
    -- ���[�v�J�n
    -- ===============================
    <<create_file_loop>>
    FOR i IN 1 .. g_get_awareness_tab.COUNT LOOP
--
-- == 2009/04/21 V1.2 Moded START ===============================================================
--      -- ===============================
--      -- �C�Â����CSV�쐬 (A-5)
--      -- ===============================
--      -- ���؂�΍􃁃b�Z�[�W�擾
--      lv_sold_out_msg     := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_sold_out_msg
--                               , iv_token_name1  => cv_tkn_time
--                               , iv_token_value1 => g_get_awareness_tab(i).sold_out_time
--                             );
--      -- ��[���΍􃁃b�Z�[�W�擾
--      lv_supl_rate_msg    := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_supl_rate_msg
--                               , iv_token_name1  => cv_tkn_rate
--                               , iv_token_value1 => g_get_awareness_tab(i).supl_rate
--                             );
--      -- �z�b�g�݌ɑ΍􃁃b�Z�[�W�擾
--      lv_hot_inv_msg      := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_hot_inv_msg
--                               , iv_token_name1  => cv_tkn_day
--                               , iv_token_value1 => g_get_awareness_tab(i).hot_inv
--                             );
--      -- ���b�Z�[�W.�R��������܂��擾
--      lv_column_exist_msg := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_appl_short_name_xxcoi
--                               , iv_name         => cv_column_exist_msg
--                             );
--      -- CSV�f�[�^���쐬
--      lv_csv_file := (
--        cv_encloser || g_get_awareness_tab(i).sale_base_code || cv_encloser || cv_delimiter || --���㋒�_�R�[�h
--                       g_get_awareness_tab(i).sold_out_time                 || cv_delimiter || --���؂ꎞ��
--                       g_get_awareness_tab(i).supl_rate                     || cv_delimiter || --��[��
--                       g_get_awareness_tab(i).hot_inv                       || cv_delimiter || --�z�b�g�݌�
--        cv_encloser || gv_sold_out_msg_color                 || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W�F
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_sold_out_msg                       || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_sold_out_msg, ' ' ) )
--                                                             || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W2
--        cv_encloser || gv_supl_rate_msg_color                || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W�F
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_supl_rate_msg                      || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_supl_rate_msg, ' ' ) )    
--                                                             || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W2
--        cv_encloser || gv_hot_inv_msg_color                  || cv_encloser || cv_delimiter || --�z�b�g�݌Ƀ��b�Z�[�W�F
---- == 2009/03/30 V1.1 Moded START ===============================================================
----        cv_encloser || lv_hot_inv_msg                        || cv_encloser || cv_delimiter || --�z�b�g�݌Ƀ��b�Z�[�W1
--        cv_encloser || TO_MULTI_BYTE( REPLACE( lv_hot_inv_msg, ' ' ) )
--                                                             || cv_encloser || cv_delimiter || --�z�b�g�݌Ƀ��b�Z�[�W1
---- == 2009/03/30 V1.1 Moded END   ===============================================================
--        cv_encloser || lv_column_exist_msg                   || cv_encloser                    --�z�b�g�݌Ƀ��b�Z�[�W2
--      );
----
--      -- ===============================
--      -- CSV�f�[�^���o��
--      -- ===============================
--      UTL_FILE.PUT_LINE(
--          file   => l_file_handle
--        , buffer => lv_csv_file
--      );
----
--      -- ===============================
--      -- ���������J�E���g
--      -- ===============================
--      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- ===============================
      -- ���C���q�ɏd���`�F�b�N (A-5)
      -- ===============================
      chk_main_repeat(
          iv_base_code  => g_get_awareness_tab(i).sale_base_code  -- ���_�R�[�h
        , ob_chk_status => lb_chk_status     -- �d���`�F�b�N�X�e�[�^�X
        , ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���ꋒ�_���Ƀ��C���q�ɂ�1�̏ꍇ
      IF ( lb_chk_status = TRUE ) THEN
--
        -- ===============================
        -- �C�Â����CSV�쐬 (A-6)
        -- ===============================
        -- ���؂�΍􃁃b�Z�[�W�擾
        lv_sold_out_msg     := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_sold_out_msg
                                 , iv_token_name1  => cv_tkn_time
                                 , iv_token_value1 => g_get_awareness_tab(i).sold_out_time
                               );
        -- ��[���΍􃁃b�Z�[�W�擾
        lv_supl_rate_msg    := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_supl_rate_msg
                                 , iv_token_name1  => cv_tkn_rate
                                 , iv_token_value1 => g_get_awareness_tab(i).supl_rate
                               );
        -- �z�b�g�݌ɑ΍􃁃b�Z�[�W�擾
        lv_hot_inv_msg      := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_hot_inv_msg
                                 , iv_token_name1  => cv_tkn_day
                                 , iv_token_value1 => g_get_awareness_tab(i).hot_inv
                               );
        -- ���b�Z�[�W.�R��������܂��擾
        lv_column_exist_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_short_name_xxcoi
                                 , iv_name         => cv_column_exist_msg
                               );
        -- CSV�f�[�^���쐬
        lv_csv_file := (
          cv_encloser || g_get_awareness_tab(i).sale_base_code || cv_encloser || cv_delimiter || --���㋒�_�R�[�h
                         g_get_awareness_tab(i).sold_out_time                 || cv_delimiter || --���؂ꎞ��
                         g_get_awareness_tab(i).supl_rate                     || cv_delimiter || --��[��
                         g_get_awareness_tab(i).hot_inv                       || cv_delimiter || --�z�b�g�݌�
          cv_encloser || gv_sold_out_msg_color                 || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W�F
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_sold_out_msg, ' ' ) )
                                                               || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W1
          cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --���؂�΍􃁃b�Z�[�W2
          cv_encloser || gv_supl_rate_msg_color                || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W�F
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_supl_rate_msg, ' ' ) )    
                                                               || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W1
          cv_encloser || lv_column_exist_msg                   || cv_encloser || cv_delimiter || --��[���΍􃁃b�Z�[�W2
          cv_encloser || gv_hot_inv_msg_color                  || cv_encloser || cv_delimiter || --�z�b�g�݌Ƀ��b�Z�[�W�F
          cv_encloser || TO_MULTI_BYTE( REPLACE( lv_hot_inv_msg, ' ' ) )
                                                               || cv_encloser || cv_delimiter || --�z�b�g�݌Ƀ��b�Z�[�W1
          cv_encloser || lv_column_exist_msg                   || cv_encloser                    --�z�b�g�݌Ƀ��b�Z�[�W2
        );
--
        -- ===============================
        -- CSV�f�[�^���o��
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => l_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- ���������J�E���g
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END IF;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    END LOOP create_file_loop;
--
    -- ===============================
    -- UTL�t�@�C���N���[�Y (A-7)
    -- ===============================
    UTL_FILE.FCLOSE( file => l_file_handle );
--
-- == 2009/04/21 V1.2 Moded START ===============================================================
--    -- ===============================
--    -- �Ώی����J�E���g
--    -- ===============================
--    gn_target_cnt := gn_normal_cnt + gn_warn_cnt;
    -- ===============================
    -- �Ώی����J�E���g
    -- ===============================
    gn_target_cnt := g_get_awareness_tab.COUNT + ln_main_chk_cnt;
--
    -- ===============================
    -- �x�������J�E���g
    -- ===============================
    gn_warn_cnt := gn_warn_cnt + ln_main_chk_cnt;
-- == 2009/04/21 V1.2 Moded END   ===============================================================
--
    -- �x��������0����葽���ꍇ�A�X�e�[�^�X�F�x�����Z�b�g
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    WHEN file_exist_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
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
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => l_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => l_file_handle );
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
      errbuf        OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode       OUT VARCHAR2)      --   ���^�[���E�R�[�h    --# �Œ� #
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
      -- ���������A�X�L�b�v�����̏������y�уG���[�����̃Z�b�g
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      -- �G���[�o��
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
    -- �Ώی����o��
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
--
    -- �G���[�����o��
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
--
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
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
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOI010A02C;
/
