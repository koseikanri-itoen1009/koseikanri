CREATE OR REPLACE PACKAGE BODY XXCOI010A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOI010A07C(body)
 * Description      : �o�׃y�[�XHHT�A�g
 * MD.050           : �o�׃y�[�XHHT�A�g <MD050_COI_010_A07>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv             �Ώۃf�[�^���o����CSV�쐬 (A-2,A-3,A-4)
 *  submain                ���C�������v���V�[�W�� (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/15    1.0   SCSK���X��       �V�K�쐬(E_�{�ғ�_14486)
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
  procedure_common_expt     EXCEPTION;      --  ���[�U��`���b�Z�[�W�o�͗p���ʗ�O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100)  :=  'XXCOI010A07C';             --  �p�b�P�[�W��
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)   :=  'XXCOI';                    --  �A�v���P�[�V�����FXXCOI
  --  ���b�Z�[�W�E�g�[�N��
  cv_msg_xxcoi1_00023         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00023';         --  �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_xxcoi1_00011         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';         --  �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00003         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00003';         --  �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00029         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00029';         --  �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00004         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00004';         --  �t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00028         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00028';         --  �t�@�C�����o�̓��b�Z�[�W
  cv_msg_xxcoi1_00027         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00027';         --  �t�@�C�����݃`�F�b�N�G���[
  cv_msg_xxcoi1_00008         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';         --  �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_00005         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00005';         --  �݌ɑg�D�R�[�h�擾�G���[
  cv_msg_xxcoi1_00006         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00006';         --  �݌ɑg�DID�擾�G���[
  cv_msg_xxcoi1_00032         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00032';         --  �v���t�@�C���l�擾�G���[
  cv_msg_xxcoi1_10736         CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10736';         --  �o�׃y�[�X�Ώے��o���ԁi�����j�ݒ�l�s��
  cv_tkn_xxcoi1_10316_1       CONSTANT VARCHAR2(30)   :=  'P_DATE';                   --  APP-XXCOI1-10316�pTOKEN
  cv_tkn_xxcoi1_00003_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00003�pTOKEN
  cv_tkn_xxcoi1_00029_1       CONSTANT VARCHAR2(30)   :=  'DIR_TOK';                  --  APP-XXCOI1-00029�pTOKEN
  cv_tkn_xxcoi1_00004_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00004�pTOKEN
  cv_tkn_xxcoi1_00028_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';                --  APP-XXCOI1-00028�pTOKEN
  cv_tkn_xxcoi1_00027_1       CONSTANT VARCHAR2(30)   :=  'FILE_NAME';                --  APP-XXCOI1-00027�pTOKEN
  cv_tkn_xxcoi1_00005_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00005�pTOKEN
  cv_tkn_xxcoi1_00006_1       CONSTANT VARCHAR2(30)   :=  'ORG_CODE_TOK';             --  APP-XXCOI1-00006�pTOKEN
  cv_tkn_xxcoi1_00032_1       CONSTANT VARCHAR2(30)   :=  'PRO_TOK';                  --  APP-XXCOI1-00032�pTOKEN
  --  �v���t�@�C��
  cv_profile_dire_out_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_DIRE_OUT_HHT';      --  XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
  cv_profile_shippace_hht     CONSTANT VARCHAR2(30)   :=  'XXCOI1_FILE_SHIPPACEHHT';  --  XXCOI:�H����ɏ��HHT�A�g�t�@�C����
  cv_profile_org_code         CONSTANT VARCHAR2(30)   :=  'XXCOI1_ORGANIZATION_CODE'; --  XXCOI:�݌ɑg�D�R�[�h
  cv_profile_pace_term        CONSTANT VARCHAR2(30)   :=  'XXCOI1_SHIP_PACE_TERM';    --  XXCOI:�o�׃y�[�X�Ώۊ��� 
  --
  cv_subinv_type_1            CONSTANT VARCHAR2(1)    :=  '1';                        --  �ۊǏꏊ�敪 1:�q��
  cv_subinv_type_2            CONSTANT VARCHAR2(1)    :=  '2';                        --  �ۊǏꏊ�敪 2:�c�Ǝ�
  cv_slash                    CONSTANT VARCHAR2(1)    :=  '/';
  cv_comma                    CONSTANT VARCHAR2(1)    :=  ',';
  cv_dquot                    CONSTANT VARCHAR2(1)    :=  '"';
  cv_utlfile_open_w           CONSTANT VARCHAR2(1)    :=  'w';                        --  �I�[�v�����[�h w:��������
  cv_calendar_desc            CONSTANT bom_calendars.description%TYPE :=  '�ɓ����c�Ɖғ��J�����_';
                                                                                      --  �J�����_�K�p
  cn_roundup_rank             CONSTANT NUMBER         :=  3;                          --  �����؂�グ�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                                 --  �Ɩ����t
  g_file_handle               UTL_FILE.FILE_TYPE;                                   --  �t�@�C���n���h��
  gt_organization_code        mtl_parameters.organization_code%TYPE;                --  �g�D�R�[�h
  gt_organization_id          mtl_parameters.organization_id%TYPE;                  --  �g�DID
  gn_ship_pace_term           NUMBER;                                               --  �o�׃y�[�X�Ώۊ���
  gn_work_day_count           NUMBER;                                               --  �ғ�������
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf         OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
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
    lv_dire_name        VARCHAR2(50);                             --  �f�B���N�g����
    lt_dire_path        all_directories.directory_path%TYPE;      --  �f�B���N�g���p�X
    lv_file_name        VARCHAR2(50);                             --  �t�@�C����
    lb_fexists          BOOLEAN;                                  --  �t�@�C�����݃`�F�b�N����
    ln_file_length      NUMBER;                                   --  �t�@�C���̒����̕ϐ�
    ln_block_size       NUMBER;                                   --  �u���b�N�T�C�Y�̕ϐ�
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
    --  ������
    lv_dire_name        :=  NULL;           --  �f�B���N�g����
    lt_dire_path        :=  NULL;           --  �f�B���N�g���p�X
    lv_file_name        :=  NULL;           --  �t�@�C����
    lb_fexists          :=  FALSE;          --  �t�@�C�����݃`�F�b�N����
    ln_file_length      :=  NULL;           --  �t�@�C���̒����̕ϐ�
    ln_block_size       :=  NULL;           --  �u���b�N�T�C�Y�̕ϐ�
    --
    -- ===================================
    --  �R���J�����g���̓p�����[�^�o��
    -- ===================================
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00023
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  ''
    );
    --
    -- ===================================
    --  �Ɩ����t�擾
    -- ===================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      --  �Ɩ����t���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00011
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �g�D�R�[�h/�g�DID�擾
    -- ===================================
    gt_organization_code  :=  fnd_profile.value( cv_profile_org_code );
    IF ( gt_organization_code IS NULL ) THEN
      --  �g�D�R�[�h���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00005
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00005_1
                      , iv_token_value1   =>  cv_profile_org_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    gt_organization_id  :=  xxcoi_common_pkg.get_organization_id( gt_organization_code );
    IF ( gt_organization_id IS NULL ) THEN
      --  �g�DID���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00006
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00006_1
                      , iv_token_value1   =>  gt_organization_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �f�B���N�g�����擾
    -- ===================================
    lv_dire_name  :=  fnd_profile.value( cv_profile_dire_out_hht );
    IF ( lv_dire_name IS NULL ) THEN
      --  �f�B���N�g�������擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00003
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00003_1
                      , iv_token_value1   =>  cv_profile_dire_out_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �f�B���N�g���p�X�擾
    -- ===================================
    BEGIN
      SELECT  ad.directory_path
      INTO    lt_dire_path
      FROM    all_directories     ad
      WHERE   ad.directory_name   =   lv_dire_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_appl_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00029
                        , iv_token_name1    =>  cv_tkn_xxcoi1_00029_1
                        , iv_token_value1   =>  lv_dire_name
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE procedure_common_expt;
    END;
    --
    -- ===================================
    --  �t�@�C�����擾
    -- ===================================
    lv_file_name  :=  fnd_profile.value( cv_profile_shippace_hht );
    IF ( lv_file_name IS NULL ) THEN
      --  �t�@�C�������擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00004
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00004_1
                      , iv_token_value1   =>  cv_profile_shippace_hht
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �t�@�C�����o��
    -- ===================================
    -- ���b�Z�[�W����
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00028
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00028_1
                      , iv_token_value1   =>  lt_dire_path || cv_slash || lv_file_name
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
    --
    -- ===================================
    --  �t�@�C�����݃`�F�b�N
    -- ===================================
    UTL_FILE.FGETATTR(
        location      =>  lv_dire_name
      , filename      =>  lv_file_name
      , fexists       =>  lb_fexists
      , file_length   =>  ln_file_length
      , block_size    =>  ln_block_size
    );
    IF ( lb_fexists ) THEN
      --  �����t�@�C�������݂���ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00027
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00027_1
                      , iv_token_value1   =>  lv_file_name
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �t�@�C��OPEN
    -- ===================================
    g_file_handle :=  UTL_FILE.FOPEN(
                          location    =>  lv_dire_name
                        , filename    =>  lv_file_name
                        , open_mode   =>  cv_utlfile_open_w
                      );
    --
    -- ===================================
    --  �o�׃y�[�X�Ώے��o���ԁi�����j�擾
    -- ===================================
    gn_ship_pace_term :=  TO_NUMBER( fnd_profile.value( cv_profile_pace_term ) );
    IF ( gn_ship_pace_term IS NULL ) THEN
      --  �o�׃y�[�X�Ώے��o���ԁi�����j���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00032
                      , iv_token_name1    =>  cv_tkn_xxcoi1_00032_1
                      , iv_token_value1   =>  cv_profile_pace_term
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    IF ( gn_ship_pace_term < 0 ) THEN
      --  �o�׃y�[�X�Ώے��o���ԁi�����j�� 0 ��菬�����ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_10736
                    );
      lv_errbuf := lv_errmsg;
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===================================
    --  �ғ��������擾
    -- ===================================
    SELECT  COUNT(1)
    INTO    gn_work_day_count
    FROM    bom_calendars         bc
          , bom_calendar_dates    bcd
    WHERE   bc.description        =   cv_calendar_desc
    AND     bc.calendar_code      =   bcd.calendar_code
    AND     bcd.seq_num IS NOT NULL
    AND     bcd.calendar_date     >   gd_process_date - gn_ship_pace_term
    AND     bcd.calendar_date     <=  gd_process_date
    ;
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      -- *** ���[�U��`���b�Z�[�W�o��<���ʗ�O> ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
   * Procedure Name   : create_csv
   * Description      : �Ώۃf�[�^���o����CSV�쐬 (A-2, A-3, A-4)
   ***********************************************************************************/
  PROCEDURE create_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv'; -- �v���O������
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
    lv_csv_line                     VARCHAR2(1500);               --  CSV�f�[�^
    lv_transfer_date                VARCHAR2(21);                 --  ���M����
    ln_ship_pace                    NUMBER;                       --  �o�׃y�[�X
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ===============================
    --  �����݌Ɏ󕥕\�i�����j���o (A-2)
    -- ===============================
    CURSOR  ship_pace_cur
    IS
      SELECT  subq.subinventory_code          AS  "SUBINVENTORY_CODE"                       --  �ۊǏꏊ�R�[�h
            , msib.segment1                   AS  "ITEM_NUMBER"                             --  �i�ڃR�[�h
            , subq.ship_quantity_total        AS  "SHIP_QUANTITY_TOTAL"                     --  �o�ב���
      FROM    (
                SELECT  xird.subinventory_code        AS  "SUBINVENTORY_CODE"               --  �ۊǏꏊ�R�[�h
                      , xird.inventory_item_id        AS  "INVENTORY_ITEM_ID"               --  �i��ID
                      , xird.organization_id          AS  "ORGANIZATION_ID"                 --  �g�DID
                      , SUM(  xird.sales_shipped                --  ����o��
                            + xird.truck_ship                   --  �c�ƎԂ֏o��
                            + xird.others_ship                  --  ���o�ɁQ���̑��o��
                            + xird.goods_transfer_old           --  ���i�U�ցi�����i�j
                            + xird.customer_sample_ship         --  �ڋq���{�o��
                            + xird.customer_support_ss          --  �ڋq���^���{�o��
                            + xird.vd_supplement_ship           --  ����VD��[�o��
                        )                             AS  "SHIP_QUANTITY_TOTAL"             --  �o�ב���
                FROM    xxcoi_inv_reception_daily   xird                                    --  �����݌Ɏ󕥕\�i�����j
                WHERE   xird.subinventory_type IN( cv_subinv_type_1, cv_subinv_type_2 )     --  �q��or�c�ƈ�
                AND     xird.organization_id    =   gt_organization_id
                AND     xird.practice_date      >   gd_process_date - gn_ship_pace_term
                GROUP BY  xird.subinventory_code
                        , xird.inventory_item_id
                        , xird.organization_id
              )                     subq
            , mtl_system_items_b    msib
      WHERE   subq.inventory_item_id    =   msib.inventory_item_id
      AND     subq.organization_id      =   msib.organization_id
      ORDER BY  subq.subinventory_code
              , msib.segment1
    ;
    -- <�����݌Ɏ󕥕\�i�����j���o>���R�[�h�^
    ship_pace_rec     ship_pace_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_transfer_date  :=  TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' );            --  ���M����
    --
    <<csv_loop>>
    FOR ship_pace_rec IN ship_pace_cur LOOP
      --  �Ώی����J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      lv_errmsg     :=  NULL;
      lv_csv_line   :=  NULL;
      ln_ship_pace  :=  NULL;
      -- ===============================
      --  �o�׃y�[�X�Z�o (A-3)
      -- ===============================
      --  ���ԓ��̑����� / �ғ������� �i�ғ����P��������̕��Ϗo�א��j
      ln_ship_pace  :=  ship_pace_rec.ship_quantity_total / gn_work_day_count;
      --
      --  �؏グ����(���� ��cn_roundup_rank�� �Ő؏グ)
      IF ( TRUNC( ln_ship_pace, cn_roundup_rank ) = TRUNC( ln_ship_pace, cn_roundup_rank-1 ) ) THEN
        --  �����A�܂��́A�؏グ�Ώۂ̈ʂ�0�̏ꍇ
        ln_ship_pace  :=  TRUNC( ln_ship_pace, cn_roundup_rank-1 );
      ELSE
        --  �؏グ�Ώۂ̈ʂ�0�ȊO�̏ꍇ
        ln_ship_pace  :=  TRUNC( ln_ship_pace, cn_roundup_rank-1 ) + POWER( 0.1, cn_roundup_rank-1 );
      END IF;
      --
      -- ===============================
      --  CSV�쐬 (A-4)
      -- ===============================
      lv_csv_line :=
                          cv_dquot || ship_pace_rec.subinventory_code || cv_dquot     --  �ۊǏꏊ
        ||  cv_comma  ||  cv_dquot || ship_pace_rec.item_number       || cv_dquot     --  ���i�R�[�h
        ||  cv_comma  ||  TO_CHAR( ln_ship_pace )                                     --  �o�׃y�[�X
        ||  cv_comma  ||  cv_dquot || lv_transfer_date                || cv_dquot     --  ���M����
      ;
      UTL_FILE.PUT_LINE(
          file    =>  g_file_handle
        , buffer  =>  lv_csv_line
      );
      --
      gn_normal_cnt :=  gn_normal_cnt + 1;
    END LOOP  csv_loop;
    --
    --  �Ώۃf�[�^�����݂��Ȃ��ꍇ�A���O���o��
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_appl_short_name_xxcoi
                      , iv_name           =>  cv_msg_xxcoi1_00008
                    );
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  lv_errmsg
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    ELSIF ( gn_warn_cnt <> 0 ) THEN
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
    END IF;
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      --  CURSOR��OPEN���Ă���ꍇ�ACLOSE
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( ship_pace_cur%ISOPEN ) THEN
        CLOSE ship_pace_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf       OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) IS
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
    gn_target_cnt     :=  0;
    gn_normal_cnt     :=  0;
    gn_error_cnt      :=  0;
    gn_warn_cnt       :=  0;
    gd_process_date   :=  NULL;
    g_file_handle     :=  NULL;
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
        ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===============================
    -- �Ώۃf�[�^���o����CSV�쐬 (A-2, A-3, A-4)
    -- ===============================
    create_csv(
        ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE procedure_common_expt;
    END IF;
    --
    -- ===============================
    -- �t�@�C��CLOSE (A-5)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
    --
  EXCEPTION
    WHEN procedure_common_expt THEN
      --  ���b�Z�[�W�A�X�e�[�^�X��main�ֈ����n��
      ov_errmsg     :=  lv_errmsg;
      ov_errbuf     :=  lv_errbuf;
      ov_retcode    :=  lv_retcode;
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
      errbuf          OUT VARCHAR2        --  �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode         OUT VARCHAR2        --  ���^�[���E�R�[�h    --# �Œ� #
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
        ov_errbuf         =>  lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt  :=  gn_error_cnt + 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
END XXCOI010A07C;
/
