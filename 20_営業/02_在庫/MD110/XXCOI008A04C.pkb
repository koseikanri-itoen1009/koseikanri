CREATE OR REPLACE PACKAGE BODY XXCOI008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A04C(body)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̕ۊǏꏊ(�W��)��CSV�t�@�C���ɏo��
 * MD.050           : �ۊǏꏊ���n�A�g <MD050_COI_008_A04>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           �ۊǏꏊ�}�X�^CSV�̍쐬(A-4)
 *  sec_inv_cur_p          �ۊǏꏊ���̒��o(A-3)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���I�[�v��(A-2)
 *                           �E�t�@�C���N���[�Y(A-5) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   S.Kanda          �V�K�쐬
 *  2009/03/30    1.1   T.Nakamura       [��QT1_0121]�ۊǏꏊ���̒��o������ǉ�
 *  2010/05/02    1.2   H.Sasaki         [E_�{�ғ�_02545]�ۊǏꏊ�R�[�h�̑S�p�����`�F�b�N��ǉ�
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
-- == 2010/05/02 V1.2 Added START ===============================================================
  gn_warn_cnt      NUMBER;                    -- �x������
-- == 2010/05/02 V1.2 Added END   ===============================================================

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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A04C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- �A�h�I���F���ʁEIF�̈�
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- �t�@�C����؂�p
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- �����f�[�^����p
  --
  -- ���b�Z�[�W�萔
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';
-- == 2010/05/02 V1.2 Added START ===============================================================
  cv_msg_xxcoi_10427        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10427';
-- == 2010/05/02 V1.2 Added END   ===============================================================
  --
  --�g�[�N��
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- �v���t�@�C�����p
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- �v���t�@�C�����p
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- �������b�Z�[�W�p
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- �t�@�C�����p
-- == 2009/03/30 V1.1 Added START ===============================================================
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- �݌ɑg�D�R�[�h�p
-- == 2009/03/30 V1.1 Added END   ===============================================================
-- == 2010/05/02 V1.2 Added START ===============================================================
  cv_tkn_10427              CONSTANT VARCHAR2(15)  := 'SUBINV_CODE';
-- == 2010/05/02 V1.2 Added END   ===============================================================
  --
  --�t�@�C���I�[�v�����[�h
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- �I�[�v�����[�h
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                  -- �Ɩ��������t�擾�p
  gv_dire_pass          VARCHAR2(100);                         -- �f�B���N�g���p�X���p
  gv_file_sec_inv       VARCHAR2(50);                          -- �ۊǏꏊ�t�@�C�����p
  gv_company_code       VARCHAR2(50);                          -- ��ЃR�[�h�擾�p
  gv_file_name          VARCHAR2(150);                         -- �t�@�C���p�X���擾�p
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- �t�@�C���n���h���擾�p
-- == 2009/03/30 V1.1 Added START ===============================================================
  gv_organization_code  VARCHAR2(50);                          -- �݌ɑg�D�R�[�h�擾�p
  gn_organization_id    mtl_parameters.organization_id%TYPE;   -- �݌ɑg�DID�擾�p
-- == 2009/03/30 V1.1 Added END   ===============================================================
--
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
    --�v���t�@�C���擾�p�萔
    cv_pro_dire_out_info    CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';
    cv_pro_file_sec_inv     CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_SEC_INV';
    cv_pro_company_code     CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
-- == 2009/03/30 V1.1 Added START ===============================================================
    cv_pro_org_code         CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';
-- == 2009/03/30 V1.1 Added END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
    lv_directory_path       VARCHAR2(100);
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===============================
    --  ����������
    -- ===============================
    gd_process_date       :=  NULL;          -- �Ɩ����t
    gv_dire_pass          :=  NULL;          -- �f�B���N�g����
    gv_file_sec_inv       :=  NULL;          -- �ۊǏꏊ�t�@�C����
    gv_company_code       :=  NULL;          -- ��ЃR�[�h��
    gv_file_name          :=  NULL;          -- �t�@�C���p�X��
    lv_directory_path     :=  NULL;          -- �f�B���N�g���p�X��
    --
    -- ===============================
    --  1.SYSDATE�擾
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- ====================================================
    -- 2.���n_OUTBOUND�i�[�f�B���N�g�������擾
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- �f�B���N�g�������擾�ł��Ȃ������ꍇ
    IF ( gv_dire_pass IS NULL ) THEN
      -- �f�B���N�g�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�f�B���N�g����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 3.�ۊǏꏊ�t�@�C�������擾
    -- =======================================
    gv_file_sec_inv  := fnd_profile.value( cv_pro_file_sec_inv );
    --
    -- �ۊǏꏊ�t�@�C�������擾�ł��Ȃ������ꍇ
    IF ( gv_file_sec_inv IS NULL ) THEN
      -- �t�@�C�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�t�@�C����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_sec_inv
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 4.��ЃR�[�h���擾
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- ��ЃR�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_company_code  IS NULL ) THEN
      -- ��ЃR�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:��ЃR�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/03/30 V1.1 Added START ===============================================================
    -- =====================================
    -- 4.�݌ɑg�D�R�[�h���擾
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- �݌ɑg�D�R�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_organization_code  IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�݌ɑg�D�R�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- �݌ɑg�DID�擾
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- ���ʊ֐��̃��^�[���R�[�h���擾�ł��Ȃ������ꍇ
    IF ( gn_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      -- �u�݌ɑg�D�R�[�h( ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B�v
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/03/30 V1.1 Added END   ===============================================================
    -- =====================================
    -- 5.���b�Z�[�W�̏o�͇@
    -- =====================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00023
                    );
    --
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- =====================================
    -- 6.���b�Z�[�W�̏o�͇A
    -- =====================================
    -- 2.�Ŏ擾�����v���t�@�C���l���f�B���N�g���p�X���擾
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- �f�B���N�g�����
      WHERE  directory_name  =  gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
        -- �u���̃f�B���N�g�����ł̓f�B���N�g���p�X�͎擾�ł��܂���B
        -- �i�f�B���N�g���� = DIR_TOK �j�v
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j���o��
    -- '�f�B���N�g���p�X'��'/'�Ɓe�t�@�C����'������
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_sec_inv;
    --�u�t�@�C���F FILE_NAME �v
    --�t�@�C�����o�̓��b�Z�[�W
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
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
   * Procedure Name   : create_csv_p
   * Description      : �ۊǏꏊ�}�X�^CSV�̍쐬(A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     iv_sec_inv_name IN  VARCHAR2    -- �ۊǏꏊ�R�[�h
   , iv_description  IN  VARCHAR2    -- �ۊǏꏊ����
   , iv_disable_date IN  DATE        -- ������
   , iv_attribute1   IN  VARCHAR2    -- �ۊǏꏊ�敪(DFF1)
   , iv_attribute3   IN  VARCHAR2    -- �]�ƈ��R�[�h(DFF3)
   , iv_attribute4   IN  VARCHAR2    -- �ڋq�R�[�h(DFF4)
   , iv_attribute7   IN  VARCHAR2    -- ���_�R�[�h(DFF7)
   , ov_errbuf       OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode      OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg       OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- �v���O������
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
    cv_csv_com      CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_sec_inv       VARCHAR2(3000);
    lv_disable_date  VARCHAR2(8);
    lv_process_date  VARCHAR2(14);
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
    -- �ϐ��̏�����
    lv_sec_inv       := NULL;
    lv_disable_date  := NULL;
    lv_process_date  := NULL;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ������
    lv_disable_date := TO_CHAR( iv_disable_date , 'YYYYMMDD' );
    -- �A�g����
    lv_process_date := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );
    --
    -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[���܂�
    lv_sec_inv := cv_file_encloser || gv_company_code || cv_file_encloser || cv_csv_com ||  -- ��ЃR�[�h
                  cv_file_encloser || iv_sec_inv_name || cv_file_encloser || cv_csv_com ||  -- �ۊǏꏊ�R�[�h
                  cv_file_encloser || iv_description  || cv_file_encloser || cv_csv_com ||  -- �ۊǏꏊ����
                                      lv_disable_date                     || cv_csv_com ||  -- ������
                  cv_file_encloser || iv_attribute1   || cv_file_encloser || cv_csv_com ||  -- �ۊǏꏊ�敪(DFF1)
                  cv_file_encloser || iv_attribute3   || cv_file_encloser || cv_csv_com ||  -- �]�ƈ��R�[�h(DFF3)
                  cv_file_encloser || iv_attribute4   || cv_file_encloser || cv_csv_com ||  -- �ڋq�R�[�h(DFF4)
                  cv_file_encloser || iv_attribute7   || cv_file_encloser || cv_csv_com ||  -- ���_�R�[�h(DFF7)
                                      lv_process_date;                                      -- �A�g����
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
      , lv_sec_inv          -- �f���~�^�{��LCSV�o�͍���
      );
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
  END create_csv_p;
--
  /**********************************************************************************
   * Procedure Name   : sec_inv_cur_p
   * Description      : �ۊǏꏊ���̒��o(A-3)
   ***********************************************************************************/
  PROCEDURE sec_inv_cur_p(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sec_inv_cur_p'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �ۊǏꏊ���擾
    CURSOR sec_inv_cur
    IS
      SELECT  msi.secondary_inventory_name    -- �ۊǏꏊ�R�[�h
            , msi.description                 -- �ۊǏꏊ����
            , msi.disable_date                -- ������
            , msi.attribute1                  -- �ۊǏꏊ�敪(DFF1)
            , msi.attribute3                  -- �]�ƈ��R�[�h(DFF3)
            , msi.attribute4                  -- �ڋq�R�[�h(DFF4)
            , msi.attribute7                  -- ���_�R�[�h(DFF7)
-- == 2009/03/30 V1.1 Moded START ===============================================================
--      FROM    mtl_secondary_inventories msi;  -- �ۊǏꏊ�}�X�^
      FROM    mtl_secondary_inventories   msi                 -- �ۊǏꏊ�}�X�^
      WHERE   msi.organization_id       = gn_organization_id; -- A-1.�Ŏ擾�����݌ɑg�DID
-- == 2009/03/30 V1.1 Moded END   ===============================================================
      --
      -- sec_inv���R�[�h�^
      sec_inv_rec  sec_inv_cur%ROWTYPE;
--
      -- ===============================
      -- ���[�U�[��`��O
      -- ===============================
    NO_DATA_ERR         EXCEPTION;     -- �擾�f�[�^�O���G���[
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
    --�ۊǏꏊ�f�[�^�擾�J�[�\���I�[�v��
    OPEN sec_inv_cur;
      --
      <<sec_inv_loop>>
      LOOP
        FETCH sec_inv_cur INTO sec_inv_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN sec_inv_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
--
-- == 2010/05/02 V1.2 Added START ===============================================================
        IF (LENGTH(sec_inv_rec.secondary_inventory_name) = LENGTHB(sec_inv_rec.secondary_inventory_name)) THEN
          -- �������ƕ����o�C�g������v����ꍇCSV�t�@�C�����쐬
-- == 2010/05/02 V1.2 Added END   ===============================================================
          -- ===============================
          -- A-4�D�ۊǏꏊ�}�X�^CSV�̍쐬
          -- ===============================
          create_csv_p(
              iv_sec_inv_name => sec_inv_rec.secondary_inventory_name -- �ۊǏꏊ�R�[�h
            , iv_description  => sec_inv_rec.description              -- �ۊǏꏊ����
            , iv_disable_date => sec_inv_rec.disable_date             -- ������
            , iv_attribute1   => sec_inv_rec.attribute1               -- �ۊǏꏊ�敪(DFF1)
            , iv_attribute3   => sec_inv_rec.attribute3               -- �]�ƈ��R�[�h(DFF3)
            , iv_attribute4   => sec_inv_rec.attribute4               -- �ڋq�R�[�h(DFF4)
            , iv_attribute7   => sec_inv_rec.attribute7               -- ���_�R�[�h(DFF7)
            , ov_errbuf       => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode      => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg       => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
  --
          IF (lv_retcode = cv_status_error) THEN
            -- �G���[����
            RAISE global_process_expt;
          END IF;
  --
          -- ���팏���ɉ��Z
          gn_normal_cnt := gn_normal_cnt + 1;
-- == 2010/05/02 V1.2 Added START ===============================================================
      ELSE
        -- �������ƕ����o�C�g�����s��v�̏ꍇ�X�L�b�v
        -- �����͐���I���B�ۊǏꏊ�s���������J�E���g
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_appl_short_name
                        , iv_name           =>  cv_msg_xxcoi_10427
                        , iv_token_name1    =>  cv_tkn_10427
                        , iv_token_value1   =>  sec_inv_rec.secondary_inventory_name
                        );
        lv_errbuf   := lv_errmsg;
        --
        FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
          , buff   => lv_errbuf --�G���[���b�Z�[�W
        );
        --
        gn_warn_cnt  :=  gn_warn_cnt + 1;
      END IF;
-- == 2010/05/02 V1.2 Added END   ===============================================================
      --
      --���[�v�̏I��
      END LOOP sec_inv_loop;
      --
    --�J�[�\���̃N���[�Y
    CLOSE sec_inv_cur;
    --
    -- �f�[�^���O���ŏI�������ꍇ��
    IF ( gn_target_cnt = 0 ) THEN
      RAISE NO_DATA_ERR;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_ERR THEN
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      -- �Ώۃf�[�^�������b�Z�[�W
      -- �u�Ώۃf�[�^�͂���܂���B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
                      );
      lv_errbuf   := lv_errmsg;
      --
      -- �G���[���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      -- �G���[���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF sec_inv_cur%ISOPEN THEN
        CLOSE sec_inv_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sec_inv_cur_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode    OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- �v���O������
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                   -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);                -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- �t�@�C���̑��݃`�F�b�N�p�ϐ�
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
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
    -- *** ���[�J����O ***
    remain_file_expt           EXCEPTION;
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
    -- ����������
    -- ===============================
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
-- == 2010/05/02 V1.2 Added START ===============================================================
    gn_warn_cnt      := 0;
-- == 2010/05/02 V1.2 Added END   ===============================================================
    gv_activ_file_h  := NULL;            -- �t�@�C���n���h��
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ========================================
    --  A-1. ��������
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2�D�t�@�C���I�[�v������
    -- ========================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_sec_inv
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- �t�@�C���I�[�v���������s
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass        -- �f�B���N�g���p�X
                          , filename     => gv_file_sec_inv     -- �t�@�C����
                          , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                         );
    END IF;
    --
    -- ========================================
    -- A-3�D�ۊǏꏊ���̒��o
    -- ========================================
    -- A-3�̏���������A-4������
    sec_inv_cur_p(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5�D�t�@�C���̃N���[�Y����
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    -- �u�t�@�C���u FILE_NAME �v�͂��łɑ��݂��܂��B�v
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_sec_inv
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
    retcode       OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
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
-- == 2010/05/02 V1.2 Added START ===============================================================
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
-- == 2010/05/02 V1.2 Added END   ===============================================================
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================
    -- �ϐ��̏�����
    -- ===============================
    lv_errbuf    := NULL;   -- �G���[�E���b�Z�[�W
    lv_retcode   := NULL;   -- ���^�[���E�R�[�h
    lv_errmsg    := NULL;   -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_retcode => lv_retcode  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_errbuf  => lv_errbuf   -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
    --
    --==============================================================
    -- A-7.�����\������
    --==============================================================
    -- �G���[���͐��������o�͂��O�ɃZ�b�g
    --           �G���[�����o�͂��P�ɃZ�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
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
                      iv_application  => cv_appl_short_name_ccp
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
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
-- == 2010/05/02 V1.2 Added START ===============================================================
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- == 2010/05/02 V1.2 Added START ===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      -- ����I�����b�Z�[�W
      -- �u����������I�����܂����B�v
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- �G���[�I���S���[���o�b�N���b�Z�[�W
      -- �u�������G���[�I�����܂����B�f�[�^�͑S�������O�̏�Ԃɖ߂��܂����B�v
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
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
      --
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
END XXCOI008A04C;
/
