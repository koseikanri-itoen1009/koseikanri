CREATE OR REPLACE PACKAGE BODY XXCOI008A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A05C(body)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS��VD�R�����}�X�^(�A�h�I��)��CSV�t�@�C���ɏo��
 * MD.050           : VD�R�����}�X�^���n�A�g <MD050_COI_008_A05>
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           VD�R�����}�X�^CSV�̍쐬(A-4)
 *  vd_column_cur_p        VD�R�����}�X�^���̒��o(A-3)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���I�[�v��(A-2)
 *                           �E�t�@�C���N���[�Y(A-5) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   S.Kanda          �V�K�쐬
 *  2009/06/11    1.1   H.Sasaki         [T1_1416]�g���o�Ώیڋq�X�e�[�^�X��ύX
 *  2009/07/13    1.2   H.Sasaki         [0000494]VD�R�����}�X�^���擾��PT�Ή�
 *  2009/08/14    1.3   N.Abe            [0000891]VD�R�����}�X�^���擾�̏C��
 *  2009/09/11    1.4   H.Sasaki         [0001352]PT�Ή��i�q���g��leading��ǉ��j
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A05C';
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
  --
  --�g�[�N��
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- �v���t�@�C�����p
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- �v���t�@�C�����p
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- �������b�Z�[�W�p
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- �t�@�C�����p
  -- SQL�L�q�p
  cv_duns_number_90         CONSTANT VARCHAR2(30)  := '90';            -- �ڋq�X�e�[�^�X�F���~���ٍ�
-- == 2009/06/11 V1.1 Added START ===============================================================
  cv_duns_number_80         CONSTANT VARCHAR2(30)  := '80';            -- �ڋq�X�e�[�^�X�F�X����
-- == 2009/06/11 V1.1 Added END   ===============================================================
  cn_inv_quantity_0         CONSTANT NUMBER        := 0;               -- ��݌ɐ� ��r�l
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
  gv_file_vd_column     VARCHAR2(50);                          -- VD�R�����}�X�^�t�@�C�����p
  gv_company_code       VARCHAR2(50);                          -- ��ЃR�[�h�擾�p
  gv_file_name          VARCHAR2(150);                         -- �t�@�C���p�X���擾�p
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- �t�@�C���n���h���擾�p
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
    cv_pro_file_vdinfo      CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_VDINFO';
    cv_pro_company_code     CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
--
    -- *** ���[�J���ϐ� ***
    lv_directory_path       VARCHAR2(100);     -- �f�B���N�g���p�X�擾�p
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
    gv_dire_pass          :=  NULL;          -- �f�B���N�g���p�X��
    gv_file_vd_column     :=  NULL;          -- VD�R�����}�X�^�t�@�C����
    gv_company_code       :=  NULL;          -- ��ЃR�[�h��
    gv_file_name          :=  NULL;          -- �t�@�C���p�X��
    lv_directory_path     :=  NULL;
    --
    -- ===============================
    --  1.SYSDATE�擾
    -- ===============================
    gd_process_date   :=  sysdate;
    --
    -- ====================================================
    -- 2.���n_OUTBOUND�i�[�f�B���N�g���������擾
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- �f�B���N�g������񂪎擾�ł��Ȃ������ꍇ
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
    -- 3.VD�R�����}�X�^�t�@�C�������擾
    -- =======================================
    gv_file_vd_column   := fnd_profile.value( cv_pro_file_vdinfo );
    --
    -- VD�R�����}�X�^�t�@�C�������擾�ł��Ȃ������ꍇ
    IF ( gv_file_vd_column IS NULL ) THEN
      -- �t�@�C�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�t�@�C����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_vdinfo
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
    --
    -- =====================================
    -- 6.���b�Z�[�W�̏o�͇A
    -- =====================================
    --
    -- 2.�Ŏ擾�����v���t�@�C���l���f�B���N�g���p�X���擾
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- �f�B���N�g�����
      WHERE  directory_name = gv_dire_pass;
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
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_vd_column;
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
   * Description      : VD�R�����}�X�^CSV�̍쐬(A-4)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     in_column_no          IN  VARCHAR2    -- �R����NO.
   , in_price              IN  NUMBER      -- �P��
   , in_inventory_quantity IN  NUMBER      -- ��݌ɐ�
   , in_last_month_inv_q   IN  NUMBER      -- �O����݌ɐ�
   , iv_hot_cold           IN  VARCHAR2    -- HOT/COLD�敪
   , iv_account_number     IN  VARCHAR2    -- �ڋq�R�[�h
   , iv_segment1           IN  VARCHAR2    -- ���i�R�[�h
   , iv_external_reference IN  VARCHAR2    -- �����R�[�h
   , ov_errbuf             OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_vd_column     VARCHAR2(3000);
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
    lv_vd_column      := NULL;
    lv_process_date   := NULL;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �A�g����
    lv_process_date := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );
    --
    -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[���܂�
    lv_vd_column := cv_file_encloser || gv_company_code       || cv_file_encloser || cv_csv_com ||  -- ��ЃR�[�h
                    cv_file_encloser || iv_account_number     || cv_file_encloser || cv_csv_com ||  -- �ڋq�R�[�h
                    cv_file_encloser || in_column_no          || cv_file_encloser || cv_csv_com ||  -- �R����NO.
                    cv_file_encloser || iv_segment1           || cv_file_encloser || cv_csv_com ||  -- �i�ڃR�[�h
                                        in_price                                  || cv_csv_com ||  -- �P��
                                        in_inventory_quantity                     || cv_csv_com ||  -- ��݌ɐ�
                                        in_last_month_inv_q                       || cv_csv_com ||  -- �O����݌ɐ�
                    cv_file_encloser || iv_hot_cold           || cv_file_encloser || cv_csv_com ||  -- HOT/COLD�敪
                    cv_file_encloser || iv_external_reference || cv_file_encloser || cv_csv_com ||  -- �����R�[�h                                                            -- �����R�[�h
                                        lv_process_date;                                            -- �A�g����
--
    UTL_FILE.PUT_LINE(
        gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
      , lv_vd_column        -- �f���~�^�{��LCSV�o�͍���
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
   * Procedure Name   : vd_column_cur_p
   * Description      : VD�R�����}�X�^���̒��o(A-3)
   ***********************************************************************************/
  PROCEDURE vd_column_cur_p(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'vd_column_cur_p'; -- �v���O������
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
-- == 2009/08/14 V1.3 Added START ===============================================================
   cv_zero_10   CONSTANT VARCHAR2(10) := '0000000000';
-- == 2009/08/14 V1.3 Added END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
-- == 2009/08/14 V1.3 Added START ===============================================================
   ln_column_no          xxcoi_mst_vd_column.column_no%TYPE;
   lv_account_number     hz_cust_accounts.account_number%TYPE;
-- == 2009/08/14 V1.3 Added END   ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- VD�R�����}�X�^���擾
    CURSOR vd_column_cur
    IS
      SELECT
-- == 2009/07/13 V1.2+V1.4 Added START ===============================================================
              /*+ leading(hp) use_nl(hp hca cii xmvc msib) index( hp hz_parties_n17 ) */
-- == 2009/07/13 V1.2+V1.4 Added END   ===============================================================
              xmvc.column_no                      -- �R����NO.
            , xmvc.price                          -- �P��
            , xmvc.inventory_quantity             -- ��݌ɐ�
            , xmvc.last_month_inventory_quantity  -- �O����݌ɐ�
            , xmvc.hot_cold                       -- HOT/COLD�敪
            , hca.account_number                  -- �ڋq�R�[�h
            , msib.segment1                       -- �i�ڃR�[�h
-- == 2009/08/14 V1.3 Modified START ===============================================================
--            , cii.external_reference              -- �����R�[�h
            , NVL(cii.external_reference, cv_zero_10) external_reference  -- �����R�[�h
-- == 2009/08/14 V1.3 Modified END   ===============================================================
      FROM    xxcoi_mst_vd_column  xmvc        -- VD�R�����}�X�^
            , hz_cust_accounts     hca         -- �ڋq�}�X�^
            , mtl_system_items_b   msib        -- �i�ڃ}�X�^
            , csi_item_instances   cii         -- �����}�X�^
            , hz_parties           hp          -- �p�[�e�B
-- == 2009/07/13 V1.2 Modified START ===============================================================
---- == 2009/06/11 V1.1 Modified START ===============================================================
----      WHERE  hp.duns_number_c         <>  cv_duns_number_90           -- �ڋq�X�e�[�^�X�F���~���ٍ�
--      WHERE  hp.duns_number_c         NOT IN ( cv_duns_number_90 , cv_duns_number_80 )  -- �ڋq�X�e�[�^�X
---- == 2009/06/11 V1.1 Modified END   ===============================================================
      WHERE  hp.duns_number_c         <   cv_duns_number_80           -- �ڋq�X�e�[�^�X
-- == 2009/07/13 V1.2 Modified END   ===============================================================
      AND    hp.party_id              =   hca.party_id                -- �p�[�e�BID
      AND    xmvc.inventory_quantity  <>  cn_inv_quantity_0           -- ��݌ɐ���'0'�ȊO
      AND    hca.cust_account_id      =   xmvc.customer_id            -- �ڋqID
      AND    msib.inventory_item_id   =   xmvc.item_id                -- �i��ID
      AND    msib.organization_id     =   xmvc.organization_id        -- �g�DID
-- == 2009/08/14 V1.3 Modified START ===============================================================
--      AND    hca.cust_account_id      =   cii.owner_party_account_id; -- ���L�҃A�J�E���gID
      AND    hca.cust_account_id      =   cii.owner_party_account_id(+) -- ���L�҃A�J�E���gID
      ORDER BY hca.account_number
              ,xmvc.column_no;
-- == 2009/08/14 V1.3 Modified END   ===============================================================
      --
      -- vd_column���R�[�h�^
      vd_column_rec  vd_column_cur%ROWTYPE;
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
    --VD�R�����}�X�^�f�[�^�擾�J�[�\���I�[�v��
    OPEN vd_column_cur;
      --
      <<vd_column_loop>>
      LOOP
        FETCH vd_column_cur INTO vd_column_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN vd_column_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
--
-- == 2009/08/14 V1.3 Added START ===============================================================
        IF    (ln_column_no IS NOT NULL)
          AND (ln_column_no = vd_column_rec.column_no)
          AND (lv_account_number IS NOT NULL)
          AND (lv_account_number = vd_column_rec.account_number)
        THEN
          --�R����No�ƌڋq�R�[�h���O���R�[�h�̒l�ƈ�v�����ꍇ�͎����R�[�h�֐i��
          NULL;
        ELSE
-- == 2009/08/14 V1.3 Added END   ===============================================================
          -- ===============================
          -- A-4�DVD�R�����}�X�^CSV�̍쐬
          -- ===============================
          create_csv_p(
              in_column_no          => vd_column_rec.column_no                      -- �R����NO.
            , in_price              => vd_column_rec.price                          -- �P��
            , in_inventory_quantity => vd_column_rec.inventory_quantity             -- ��݌ɐ�
            , in_last_month_inv_q   => vd_column_rec.last_month_inventory_quantity  -- �O����݌ɐ�
            , iv_hot_cold           => vd_column_rec.hot_cold                       -- HOT/COLD�敪
            , iv_account_number     => vd_column_rec.account_number                 -- �ڋq�R�[�h
            , iv_segment1           => vd_column_rec.segment1                       -- ���i�R�[�h
            , iv_external_reference => vd_column_rec.external_reference             -- �����R�[�h
            , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg             => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
  --
          IF (lv_retcode = cv_status_error) THEN
            -- �G���[����
            RAISE global_process_expt;
          END IF;
  --
          -- ���팏���ɉ��Z
          gn_normal_cnt := gn_normal_cnt + 1;
        --
-- == 2009/08/14 V1.3 Added START ===============================================================
        END IF;
        --�ϐ��ɏ㏑��
        ln_column_no      := vd_column_rec.column_no;
        lv_account_number := vd_column_rec.account_number;
-- == 2009/08/14 V1.3 Added END   ===============================================================
      --���[�v�̏I��
      END LOOP vd_column_loop;
      --
    --�J�[�\���̃N���[�Y
    CLOSE vd_column_cur;
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
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
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
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
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
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF vd_column_cur%ISOPEN THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END vd_column_cur_p;
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
    --
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
      , filename     =>  gv_file_vd_column
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
                          , filename     => gv_file_vd_column   -- �t�@�C����
                          , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                         );
    END IF;
    --
    -- ========================================
    -- A-3�DVD�R�����}�X�^���̒��o
    -- ========================================
    -- A-3�̏���������A-4������
    vd_column_cur_p(
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
                        , iv_token_value1 => gv_file_vd_column
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
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    -- A-6�D�����\������
    --==============================================================
    -- �G���[���͐��������o�͂��O�ɃZ�b�g
    --           �G���[�����o�͂��P�ɃZ�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
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
END XXCOI008A05C;
/
