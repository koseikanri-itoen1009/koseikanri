CREATE OR REPLACE PACKAGE BODY APPS.XXCMM004A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM004A14C(body)
 * Description      : �e���}�X�^IF�o�́iHHT�j
 * MD.050           : �e���}�X�^IF�o�́iHHT�j MD050_CMM_004_A14
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  file_open              �t�@�C���I�[�v������(A-2)
 *  put_csv_data           ���}�X�^���擾����(A-3)
 *                         CSV�t�@�C���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/07/25    1.0   S.Niki           E_�{�ғ�_14486�Ή� �V�K�쐬
 *  2018/03/07    1.1   H.Sasaki         E_�{�ғ�_14914�Ή�
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
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
  cv_appl_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';               -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_appl_name_xxccp       CONSTANT VARCHAR2(5)   := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMM004A14C';        -- �p�b�P�[�W��
--
  -- �v���t�@�C����
  cv_prf_file_dir          CONSTANT VARCHAR2(60)  := 'XXCMM1_HHT_OUT_DIR';       -- XXCMM:HHT(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
  cv_prf_file_name         CONSTANT VARCHAR2(60)  := 'XXCMM1_004A14_OUT_FILE';   -- XXCMM:�e���}�X�^HHT�A�g�pCSV�t�@�C����
--
  -- LOOKUP�\
  cv_lookup_band_code      CONSTANT VARCHAR2(30)  := 'XXCOS1_BAND_CODE';    -- ����Q
  cv_lookup_itm_yokigun    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_YOKIGUN';   -- �e��Q
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00002       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';    -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00022       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00022';    -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_10482       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10482';    -- CSV�t�@�C�����݃G���[
  cv_msg_xxcmm_00487       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';    -- �t�@�C���I�[�v���G���[
  cv_msg_xxcmm_00488       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';    -- �t�@�C���������݃G���[
  cv_msg_xxcmm_00489       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';    -- �t�@�C���N���[�Y�G���[
  cv_msg_xxccp_90008       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90008';    -- �R���J�����g���̓p�����[�^�Ȃ�
--
  -- ���O������
  cv_msg_xxcmm_10483       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10483';    -- ���v
  cv_msg_xxcmm_10484       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10484';    -- �v
--
  -- �g�[�N����
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';    -- �擾�Ɏ��s�����v���t�@�C����
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';     -- CSV�t�@�C����
  cv_tkn_sqlerrm           CONSTANT VARCHAR2(20)  := 'SQLERRM';       -- SQL�G���[
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';             -- �t���O�F�L��
  cv_asterisk              CONSTANT VARCHAR2(1)   := '*';             -- �A�X�^���X�N
  cv_percent               CONSTANT VARCHAR2(1)   := '%';             -- �p�[�Z���g
  cv_comma                 CONSTANT VARCHAR2(1)   := ',';             -- ��؂蕶��
  cv_dqu                   CONSTANT VARCHAR2(1)   := '"';             -- ���蕶��
--
  -- ���t����
  cv_date_fmt_full         CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS'; -- ���t�����FYYYY/MM/DD HH24:MI:SS
--
  -- �敪
  cv_kbn_seisakugun        CONSTANT VARCHAR2(2)   := '01';            -- �敪�F����Q
  cv_kbn_youkigun          CONSTANT VARCHAR2(2)   := '02';            -- �敪�F�e��Q
--
  -- ���x��
  cv_lv_2                  CONSTANT VARCHAR2(1)   := '2';             -- ���x���F2
  -- ������
  cn_first                 CONSTANT NUMBER        := 1;               -- �J�n�ʒu
  cn_cd_length             CONSTANT NUMBER        := 10;              -- �R�[�h
  cn_nm_length             CONSTANT NUMBER        := 20;              -- ����
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_file_dir              VARCHAR2(1000);        -- CSV�t�@�C���o�͐�
  gv_file_name             VARCHAR2(30);          -- CSV�t�@�C����
  gf_file_handler          UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lb_fexists              BOOLEAN;                -- �t�@�C�����ݔ��f
    ln_file_length          NUMBER;                 -- �t�@�C���̕�����
    lbi_block_size          BINARY_INTEGER;         -- �u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
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
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxccp          -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_xxccp_90008          -- ���b�Z�[�W
                 );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => gv_out_msg
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    -- ��s�}��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => ''
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    -- CSV�t�@�C���o�͐�
    gv_file_dir := FND_PROFILE.VALUE(cv_prf_file_dir);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_file_dir IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002       -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prf_file_dir          -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- CSV�t�@�C����
    gv_file_name := FND_PROFILE.VALUE(cv_prf_file_name);
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_file_name IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002       -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile        -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prf_file_name         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- CSV�t�@�C�����o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_xxcmm_00022          -- ���b�Z�[�W
                 ,iv_token_name1  => cv_tkn_file_name            -- �g�[�N���R�[�h1
                 ,iv_token_value1 => gv_file_name                -- �g�[�N���l1
                 );
    -- ���b�Z�[�W�o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => gv_out_msg
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
--
    -- ===============================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ===============================
    UTL_FILE.FGETATTR(
      location     => gv_file_dir
     ,filename     => gv_file_name
     ,fexists      => lb_fexists
     ,file_length  => ln_file_length
     ,block_size   => lbi_block_size
    );
    -- �t�@�C�������݂���ꍇ
    IF ( lb_fexists = TRUE ) THEN
      -- CSV�t�@�C�����݃G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10482       -- ���b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf       OUT VARCHAR2            --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode      OUT VARCHAR2            --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- �v���O������
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
    cv_file_mode     CONSTANT VARCHAR2(1) := 'W';    -- �������݃��[�h
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_handler := UTL_FILE.FOPEN(
                           location  => gv_file_dir     -- �f�B���N�g��
                          ,filename  => gv_file_name    -- �t�@�C����
                          ,open_mode => cv_file_mode    -- ���[�h
                         );
    EXCEPTION
      WHEN OTHERS THEN
        -- �t�@�C���I�[�v���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00487      -- ���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_sqlerrm          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => SQLERRM                 -- �g�[�N���l1
                     );
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : put_csv_data
   * Description      : ���}�X�^���擾����(A-3)�ECSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE put_csv_data(
    ov_errbuf       OUT VARCHAR2            --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode      OUT VARCHAR2            --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_csv_data'; -- �v���O������
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
    cv_goukei                CONSTANT VARCHAR2(4)   := xxccp_common_pkg.get_msg(cv_appl_name_xxcmm ,cv_msg_xxcmm_10483);
                                                           -- ���v
    cv_kei                   CONSTANT VARCHAR2(2)   := xxccp_common_pkg.get_msg(cv_appl_name_xxcmm ,cv_msg_xxcmm_10484);
                                                           -- �v
--
    -- *** ���[�J���ϐ� ***
    lv_coordinated_date      VARCHAR2(30)    := NULL;      -- �A�g���t
    lv_csv_line              VARCHAR2(4095)  := NULL;      -- �o�͕�����i�[�p�ϐ�
--
    lv_code                  VARCHAR2(10);      -- �R�[�h
    lv_name                  VARCHAR2(20);      -- ����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���}�X�^���擾�J�[�\��
    CURSOR var_data_cur
    IS
      SELECT var_data.kbn           AS kbn
            ,var_data.code          AS code
            ,var_data.name          AS name
      FROM (
             -- ����Q
             SELECT cv_kbn_seisakugun      AS kbn
                   ,flv.lookup_code        AS code
                   ,flv.description        AS name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type  = cv_lookup_band_code     -- ����Q
             AND    flv.attribute2   = cv_lv_2                 -- ���x���F2
             AND    flv.enabled_flag = cv_yes
             AND    TRUNC(SYSDATE)
                      BETWEEN NVL(flv.start_date_active ,TRUNC(SYSDATE))
                          AND NVL(flv.end_date_active   ,TRUNC(SYSDATE))
             UNION ALL
             -- �e��Q
             SELECT cv_kbn_youkigun        AS kbn
                   ,flv.lookup_code        AS code
                   ,flv.meaning            AS name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type  = cv_lookup_itm_yokigun   -- �e��Q
             AND    flv.attribute1   IS NULL                   -- �e��敪�FNULL
             AND    flv.enabled_flag = cv_yes
             AND    TRUNC(SYSDATE)
                      BETWEEN NVL(flv.start_date_active ,TRUNC(SYSDATE))
                          AND NVL(flv.end_date_active   ,TRUNC(SYSDATE))
           ) var_data
      ORDER BY
        var_data.kbn    ASC   -- �敪
       ,var_data.code   ASC   -- �R�[�h
      ;
    -- ���}�X�^���擾�J�[�\�����R�[�h�^
    var_data_rec var_data_cur%ROWTYPE;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �A�g���t
    lv_coordinated_date := TO_CHAR(SYSDATE, cv_date_fmt_full);
--
    -- ���}�X�^���擾�J�[�\�����[�v
    << var_data_loop >>
    FOR var_data_rec IN var_data_cur
    LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ���[�J���ϐ��̏�����
      lv_code     := NULL;    -- �R�[�h
      lv_name     := NULL;    -- ����
      lv_csv_line := NULL;    -- �o�͕�����i�[�p�ϐ�
--
      -- ===============================
      -- �o�͕�����ҏW
      -- ===============================
      -- �R�[�h
      lv_code := SUBSTRB( RTRIM( REPLACE( var_data_rec.code, cv_asterisk ,'' ) ) ,cn_first ,cn_cd_length );
--
      -- ����
--  2018/03/07 V1.1 Modified START
--      IF ( var_data_rec.name LIKE cv_percent || cv_goukei ) THEN
      IF  ( var_data_rec.name LIKE cv_percent || cv_goukei
            OR
            LENGTHB( lv_code ) = 2
          )
      THEN
--  2018/03/07 V1.1 Modified END
        lv_name := SUBSTRB( RTRIM( var_data_rec.name ) ,cn_first ,cn_nm_length );
      ELSE
        lv_name := SUBSTRB( RTRIM( REPLACE( var_data_rec.name, cv_kei ,'' ) ) ,cn_first ,cn_nm_length );
      END IF;
--
      -- �o�͕����񌋍�
      lv_csv_line := cv_dqu || var_data_rec.kbn || cv_dqu;                                 -- �敪
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_code || cv_dqu;               -- �R�[�h
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_name || cv_dqu;               -- ����
      lv_csv_line := lv_csv_line || cv_comma || cv_dqu || lv_coordinated_date || cv_dqu;   -- �A�g���t
--
      -- ===============================
      -- CSV�t�@�C���o��
      -- ===============================
      BEGIN
        UTL_FILE.PUT_LINE(
          file   => gf_file_handler   -- �t�@�C��
         ,buffer => lv_csv_line       -- �o�͕�����i�[�p�ϐ�
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �t�@�C���������݃G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm      -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_00488      -- ���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_sqlerrm          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => SQLERRM                 -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP var_data_loop;
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
  END put_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J�����[�U�[��`��O ***
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
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���I�[�v������(A-2)
    -- ===============================
    file_open(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���}�X�^���擾����(A-3)�ECSV�t�@�C���o�͏���(A-4)
    -- ===============================
    put_csv_data(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    BEGIN
      -- �t�@�C���N���[�Y����
      IF (UTL_FILE.IS_OPEN(gf_file_handler)) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF ( lv_retcode = cv_status_error ) THEN
          -- �R���J�����g���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf --�G���[���b�Z�[�W
          );
        END IF;
        -- �t�@�C���N���[�Y�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00489      -- ���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_sqlerrm          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => SQLERRM                 -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
    errbuf                  OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                 OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf             => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --===============================================
    -- �I������(A-5)
    --===============================================
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_normal_cnt := 0;  -- ��������
      gn_error_cnt  := 1;  -- �G���[����
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
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X������ȊO�̏ꍇ��ROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
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
END XXCMM004A14C;
/
