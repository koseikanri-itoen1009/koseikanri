create or replace PACKAGE BODY XXCSM001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A02C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�N�Ԍv��f�[�^��
 *                  : �̔��v��e�[�u��(�A�h�I��)�Ɏ捞�݂܂��B
 * MD.050           : �\�Z�f�[�^�`�F�b�N�捞    MD050_CSM_001_A02
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
 *  check_location         ���_�f�[�^�Ó����`�F�b�N(A-5)
 *  check_item             ���ڑÓ����`�F�b�N(A-6)
 *  insert_data            �o�^����(A-7)
 *  loop_main              LOOP�N�Ԍv��f�[�^�擾�A�Z�[�u�|�C���g�̐ݒ�(A-3,A-4)
 *                            �Echeck_location
 *                            �Echeck_item
 *                            �Einsert_data
 *  final                  �I������(A-8)
 *  submain                ���C�������v���V�[�W��
 *                            �Einit  
 *                            �Eget_if_data
 *                            �Eloop_main
 *                            �Efinal
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                            �Emain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS M.Ohtsuki    �V�K�쐬
 *  2009/02/10    1.1   SCS K.Yamada     [��QCT004]�捞���ڏ��̕ύX�Ή�
 *  2009/02/12    1.1   SCS K.Yamada     [��QCT012]�s�v�ȃ��O�o�͂��폜
 *  2009/03/16    1.2   SCS M.Ohtsuki    [��QT1_0011]���b�Z�[�W�s���̑Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- �z��O�G���[���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- �Ώی���
  gn_normal_cnt             NUMBER;                                                                 -- ���팏��
  gn_error_cnt              NUMBER;                                                                 -- �G���[����
  gn_warn_cnt               NUMBER;                                                                 -- �X�L�b�v����
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM001A02C';                               -- �p�b�P�[�W��
  cv_param_msg_1            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00101';                           -- �p�����[�^�o�͗p���b�Z�[�W
  cv_param_msg_2            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00102';                           -- �p�����[�^�o�͗p���b�Z�[�W
  cv_file_name              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00084';                           -- �t�@�C����
  cv_msg_comma              CONSTANT VARCHAR2(3)   := ',';                                          -- �J���}
  --�G���[���b�Z�[�W�R�[�h
  cv_csm_msg_004            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';                           -- �\�Z�N�x�d���`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_005            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_csm_msg_022            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00022';                           -- �t�@�C���A�b�v���[�hIF�e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_csm_msg_024            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00024';                           -- ����}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_025            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00025';                           -- �\�Z�N�x�s��v�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_026            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00026';                           -- �\�Z�N���d���`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_027            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00027';                           -- �N�Ԍv��f�[�^���݃`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_028            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00028';                           -- �N�Ԍv��f�[�^�t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_029            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00029';                           -- ���ڃ`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_040            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00040';                           -- �N�Ԍv��N���`�F�b�N�G���[���b�Z�[�W
  cv_csm_msg_043            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00043';                           -- �̔��v��e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_csm_msg_108            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00108';                           -- �t�@�C���A�b�v���[�h����
--//+DEL START 2009/02/12 CT012 K.Yamada
--  cv_csm_msg_109            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00109';                           -- CSV�t�@�C����
--//+DEL END   2009/02/12 CT012 K.Yamada
  --�g�[�N���R�[�h
  cv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';                                       -- ���ږ���
  cv_tkn_plan_ym            CONSTANT VARCHAR2(100) := 'YOSAN_NENGETSU';                             -- �\�Z�N��
  cv_tkn_loca_cd            CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- ���_�R�[�h
  cv_tkn_prf_nm             CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- �v���t�@�C����
  cv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';                                      -- ��������
  cv_tkn_count_2            CONSTANT VARCHAR2(100) := 'COUNT_2';                                    -- �s��
  cv_tkn_pl_year            CONSTANT VARCHAR2(100) := 'YOSAN_NENDO';                                -- �\�Z�N�x
  cv_tkn_err_msg            CONSTANT VARCHAR2(100) := 'ERR_MSG';                                    -- �G���[���b�Z�[�W
  cv_tkn_file_id            CONSTANT VARCHAR2(100) := 'FILE_ID';                                    -- �t�@�C��ID
  cv_tkn_format             CONSTANT VARCHAR2(100) := 'FORMAT';                                     -- �t�H�[�}�b�g
  cv_tkn_file_name          CONSTANT VARCHAR2(100) := 'FILE_NAME';                                  -- �t�@�C����
  cv_tkn_up_name            CONSTANT VARCHAR2(100) := 'UPLOAD_NAME';                                -- �t�@�C���A�b�v���[�h����
  --�A�v���P�[�V�����Z�k��
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM';                                      -- �A�v���P�[�V�����Z�k��
  cv_chk_warning            CONSTANT VARCHAR2(1)   := '1';                                          -- �x��
  cv_chk_normal             CONSTANT VARCHAR2(1)   := '0';                                          -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE gr_def_info_rtype IS RECORD                                                                  -- ���R�[�h�^��錾
      (meaning    VARCHAR2(100)                                                                     -- ���ږ�
      ,attribute  VARCHAR2(100)                                                                     -- ���ڑ���
      ,essential  VARCHAR2(100)                                                                     -- �K�{�t���O
      ,figures    NUMBER                                                                            -- ���ڂ̒���
      );
  TYPE gt_def_info_ttype IS TABLE OF gr_def_info_rtype                                              -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--
  TYPE gt_check_data_ttype IS TABLE OF VARCHAR2(4000)                                               -- �e�[�u���^�̐錾
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --�e�[�u���^�ϐ��̐錾
  gt_def_info_tab           gt_def_info_ttype;                                                      -- �e�[�u���^�ϐ��̐錾
  gn_counter                NUMBER;                                                                 -- ���������J�E���^�[
  gn_file_id                NUMBER;                                                                 -- �p�����[�^�i�[�p�ϐ�
  gn_item_num               NUMBER;                                                                 -- �N�Ԍv��f�[�^���ڐ��i�[�p
  gv_format                 VARCHAR2(100);                                                          -- �p�����[�^�i�[�p�ϐ�
  gv_calender_name          VARCHAR2(100);                                                          -- �N�Ԕ̔��v��J�����_�[���i�[�p
  gn_object_year            NUMBER;                                                                 -- �Ώ۔N�x
  gv_check_flag             VARCHAR2(1);                                                            -- �`�F�b�N�t���O
  gd_process_date           DATE;                                                                   -- �Ɩ����t
  gv_warnig_flg             VARCHAR2(1);
--  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- �G���[�E���b�Z�[�W
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- ���^�[���E�R�[�h
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- �v���O������
    cv_calender_name        CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';                   -- �N�Ԕ̔��v��J�����_�[��
    cv_item_num             CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_ITEM_NUM';                   -- �N�Ԍv��f�[�^���ڐ�
    cv_csv_file_name        CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_FILE_NAME';                  -- CSV�t�@�C����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- ���^�[���E�R�[�h
    lv_errbuf               VARCHAR2(4000);                                                         -- �G���[�E���b�Z�[�W
    lv_errmsg               VARCHAR2(4000);                                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn_value            VARCHAR2(4000);                                                         -- �g�[�N���l
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_upload_obj           CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';                     -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
    cv_sales_pl_item        CONSTANT VARCHAR2(100) := 'XXCSM1_SALES_PLAN_ITEM';                     -- �̔����ڃf�[�^���ڒ�`
    cv_null_ok              CONSTANT VARCHAR2(100) := 'NULL_OK';                                    -- �C�Ӎ���
    cv_null_ng              CONSTANT VARCHAR2(100) := 'NULL_NG';                                    -- �K�{����
    cv_varchar              CONSTANT VARCHAR2(100) := 'VARCHAR2';                                   -- ������
    cv_number               CONSTANT VARCHAR2(100) := 'NUMBER';                                     -- ���l
    cv_date                 CONSTANT VARCHAR2(100) := 'DATE';                                       -- ���t
    cv_varchar_cd           CONSTANT VARCHAR2(100) := '0';                                          -- �����񍀖�
    cv_number_cd            CONSTANT VARCHAR2(100) := '1';                                          -- ���l����
    cv_date_cd              CONSTANT VARCHAR2(100) := '2';                                          -- ���t����
    cv_not_null             CONSTANT VARCHAR2(100) := '1';                                          -- �K�{
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                  NUMBER;                                                                 -- �J�E���^
    ln_calender_cnt         NUMBER;                                                                 -- �J�����_�[�����i�[�p
    ln_result               VARCHAR2(100);                                                          -- ��������
    lv_up_name              VARCHAR2(1000);                                                         -- �A�b�v���[�h���̏o�͗p
    lv_file_name            VARCHAR2(1000);                                                         -- �t�@�C�����o�͗p
    lv_in_file_id           VARCHAR2(1000);                                                         -- �t�@�C���h�c�o�͗p
    lv_in_format            VARCHAR2(1000);                                                         -- �t�H�[�}�b�g�o�͗p
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_csv_file_name        VARCHAR2(100);                                                          -- CSV�t�@�C����
--//+DEL END   2009/02/12 CT012 K.Yamada
    lv_upload_obj           VARCHAR2(100);                                                          -- �t�@�C���A�b�v���[�h����
--
    get_err_expt            EXCEPTION;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR   get_def_info_cur                                                                       -- �f�[�^���ڒ�`�擾�p�J�[�\��
    IS
      SELECT   flv.meaning                                               meaning                    -- ���e
              ,DECODE(flv.attribute1,cv_varchar,cv_varchar_cd
                                    ,cv_number,cv_number_cd,cv_date_cd)  attribute                  -- ���ڑ���
              ,DECODE(flv.attribute2,cv_not_null,cv_null_ng,cv_null_ok)  essential                  -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)  figures                                                   -- ���ڂ̒���
      FROM     fnd_lookup_values  flv                                                               -- �N�C�b�N�R�[�h�l
      WHERE    flv.lookup_type        = cv_sales_pl_item                                            -- �̔��v��f�[�^���ڒ�`
        AND    flv.language           = USERENV('LANG')                                             -- ����('JA')
        AND    flv.enabled_flag       = 'Y'                                                         -- �g�p�\�t���O
        AND    flv.start_date_active <= gd_process_date                                             -- �K�p�J�n��
        AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date                                -- �K�p�I����
      ORDER BY flv.lookup_code   ASC;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --A-1 �Ɩ����t�̎擾
    --==============================================================
--
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- �Ɩ����t�擾
--
    --==============================================================
    --A-1 �v���t�@�C���l�擾
    --==============================================================
--
    gv_calender_name := FND_PROFILE.VALUE(cv_calender_name);
    gn_item_num      := FND_PROFILE.VALUE(cv_item_num);
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_csv_file_name := FND_PROFILE.VALUE(cv_csv_file_name);
--//+DEL END   2009/02/12 CT012 K.Yamada
--
    IF (gv_calender_name IS NULL) THEN                                                              -- �J�����_���擾���s�̏ꍇ
      lv_tkn_value    := cv_calender_name;
    ELSIF (gn_item_num IS NULL) THEN                                                                -- ���ڐ��擾���s�̏ꍇ
      lv_tkn_value    := cv_item_num;
--//+DEL START 2009/02/12 CT012 K.Yamada
--    ELSIF (lv_csv_file_name IS NULL) THEN                                                           -- CSV�t�@�C�����擾���s�̏ꍇ
--      lv_tkn_value    := cv_csv_file_name;
--//+DEL END   2009/02/12 CT012 K.Yamada
    END IF;
--
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_csm_msg_005                       -- ���b�Z�[�W�R�[�h
                                           ,iv_token_name1  => cv_tkn_prf_nm                        -- �g�[�N���R�[�h1
                                           ,iv_token_value1 => lv_tkn_value                         -- �g�[�N���l1
                                           );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
    END IF;
--
    --==============================================================
    --A-1  �N�Ԕ̔��v��J�����_�[�L���N�x�擾
    --==============================================================
--
    xxcsm_common_pkg.get_yearplan_calender(
                                  id_comparison_date => cd_creation_date                            -- �V�X�e�����t
                                 ,ov_status          => ln_result                                   -- ��������
                                 ,on_active_year     => gn_object_year                              -- �Ώ۔N�x
                                 ,ov_retcode         => lv_retcode
                                 ,ov_errbuf          => lv_errbuf
                                 ,ov_errmsg          => lv_errmsg
                                 );
    IF (lv_retcode <> cv_status_normal ) THEN                                                        -- �������ʂ�(�ُ� = 1)�̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application     => cv_xxcsm                                    -- �A�v���P�[�V�����Z�k��
                                 ,iv_name            => cv_csm_msg_004                              -- ���b�Z�[�W�R�[�h
                                 ,iv_token_name1     => cv_tkn_item                                 -- �g�[�N���R�[�h1
                                 ,iv_token_value1    => gv_calender_name                            -- �g�[�N���l1
                                 );
      lv_errbuf := lv_errmsg;
      RAISE get_err_expt;
     END IF;
    --==============================================================
    --A-1  �̔��v��e�[�u����`���擾
    --==============================================================
--
    ln_cnt := 0;                                                                                    -- �ϐ��̏�����
    <<def_info_loop>>                                                                               -- �e�[�u����`�擾LOOP
    FOR rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_def_info_tab(ln_cnt).meaning   := rec.meaning;                                             -- ���ږ�
      gt_def_info_tab(ln_cnt).attribute := rec.attribute;                                           -- ���ڑ���
      gt_def_info_tab(ln_cnt).essential := rec.essential;                                           -- �K�{�t���O
      gt_def_info_tab(ln_cnt).figures   := rec.figures;                                             -- ���ڂ̒���
    END LOOP def_info_loop;
--
    --==============================================================
    --A-1  �t�@�C���A�b�v���[�h���̂̎擾
    --==============================================================
--
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values flv
    WHERE    flv.lookup_type        = cv_upload_obj                                                 -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND    flv.lookup_code        = TO_CHAR(gv_format)
      AND    flv.language           = USERENV('LANG')                                               -- ����('JA')
      AND    flv.enabled_flag       = 'Y'                                                           -- �g�p�\�t���O
      AND    flv.start_date_active <= gd_process_date                                               -- �K�p�J�n��
      AND    NVL(flv.end_date_active,SYSDATE)   >= gd_process_date;                                 -- �K�p�I����
--
    --==============================================================
    --A-1 IN�p�����[�^�̏o��
    --==============================================================
--
    lv_up_name    := xxccp_common_pkg.get_msg(                                                      -- �A�b�v���[�h���̂̏o��
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_108                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_up_name                                            -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_upload_obj                                             -- �g�[�N���l1
                      );
--//+DEL START 2009/02/12 CT012 K.Yamada
--    lv_file_name  := xxccp_common_pkg.get_msg(                                                      -- CSV�t�@�C�����̏o��
--                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
--                      ,iv_name         => cv_csm_msg_109                                            -- ���b�Z�[�W�R�[�h
--                      ,iv_token_name1  => cv_tkn_file_name                                          -- �g�[�N���R�[�h1
--                      ,iv_token_value1 => lv_csv_file_name                                          -- �g�[�N���l1
--                      );
--//+DEL END   2009/02/12 CT012 K.Yamada
    lv_in_file_id := xxccp_common_pkg.get_msg(                                                      -- �t�@�C��ID�̏o��
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_param_msg_1                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_id                                            -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gn_file_id                                                -- �g�[�N���l1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                                                      -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_param_msg_2                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_format                                             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format                                                 -- �g�[�N���l1
                      );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- �o�͂ɕ\��
                     ,buff   => lv_up_name    || CHR(10) ||
--//+DEL START 2009/02/12 CT012 K.Yamada
--                                lv_file_name  || CHR(10) ||
--//+DEL END   2009/02/12 CT012 K.Yamada
                                lv_in_file_id || CHR(10) ||
--//+UPD START 2009/02/12 CT012 K.Yamada
--                                lv_in_format  || CHR(10)
                                lv_in_format
--//+UPD END   2009/02/12 CT012 K.Yamada
                                );
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_up_name    || CHR(10) ||
--//+DEL START 2009/02/12 CT012 K.Yamada
--                                lv_file_name  || CHR(10) ||
--//+DEL END   2009/02/12 CT012 K.Yamada
                                lv_in_file_id || CHR(10) ||
--//+UPD START 2009/02/12 CT012 K.Yamada
--                                lv_in_format  || CHR(10) ||
--                                ''            || CHR(10)
                                lv_in_format
--//+UPD END   2009/02/12 CT012 K.Yamada
                                );
--
  EXCEPTION
    WHEN get_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY   VARCHAR2                                                             -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY   VARCHAR2                                                             -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY   VARCHAR2)                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';                                      -- �v���O������
--
    lv_errbuf         VARCHAR2(4000);                                                               -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                                                  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_cnt_a          NUMBER;                                                                       -- �J�E���^��錾
    ln_cnt_b          NUMBER;                                                                       -- �J�E���^��錾
    ln_item_cnt       NUMBER;                                                                       -- �J�E���^��錾
    lv_file_name      VARCHAR2(100);                                                                -- �t�@�C�����i�[�p
    lv_created_by     VARCHAR2(100);                                                                -- �쐬�Ҋi�[�p
    lv_creation_date  VARCHAR2(100);                                                                -- �쐬���i�[�p
    lv_fname_op       VARCHAR2(100);                                                                -- �t�@�C�����o�͗p
--
    lt_plan_item_tab  gt_check_data_ttype;                                                          --  �e�[�u���^�ϐ���錾
    lt_if_data_tab    xxccp_common_pkg2.g_file_data_tbl;                                            --  �e�[�u���^�ϐ���錾
--
    get_if_data_expt  EXCEPTION;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --A-2 �Ώۃf�[�^���b�N�̎擾
    --==============================================================
--
    BEGIN
      SELECT   fui.file_name         file_name                                                      -- �t�@�C����
              ,fui.created_by        created_by                                                     -- �쐬��
              ,fui.creation_date     creation_date                                                  -- �쐬��
      INTO     lv_file_name   
              ,lv_created_by
              ,lv_creation_date
      FROM     xxccp_mrp_file_ul_interface  fui                                                     -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE    fui.file_id = gn_file_id                                                             -- �t�@�C��ID
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ���b�N�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm                           --�A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_csm_msg_022                     --���b�Z�[�W�R�[�h
                                             );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
    END;
--
    lv_fname_op := xxccp_common_pkg.get_msg(                                                        -- �t�@�C�����̏o��
                      iv_application  => cv_xxcsm                                                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_file_name                                               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_file_name                                           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_file_name                                               -- �g�[�N���l1
                     );
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT                                                     -- �o�͂ɕ\��
                     ,buff   => lv_fname_op || CHR(10)
                     );
--//+ADD START 2009/02/12 CT012 K.Yamada
    fnd_file.put_line(
                      which  => FND_FILE.LOG                                                        -- ���O�ɕ\��
                     ,buff   => lv_fname_op || CHR(10)
                     );
--//+ADD END   2009/02/12 CT012 K.Yamada
--
    xxccp_common_pkg2.blob_to_varchar2(                                                             -- BLOB�f�[�^�ϊ����ʊ֐�
                                   in_file_id    => gn_file_id                                      -- IN�p�����[�^
                                   ,ov_file_data => lt_if_data_tab
                                   ,ov_errbuf    => lv_errbuf 
                                   ,ov_retcode   => lv_retcode
                                   ,ov_errmsg    => lv_errmsg 
                                   );
--
    gn_target_cnt := lt_if_data_tab.COUNT;                                                          -- �����Ώی������i�[
    ln_cnt_a      := 0;                                                                             -- �J�E���^��������
--
    <<ins_wk_loop>>                                                                                 -- ���[�N�e�[�u���o�^LOOP
    LOOP
      EXIT WHEN ln_cnt_a >= gn_target_cnt;
      ln_cnt_a := ln_cnt_a + 1;                                                                     -- �����J�E���^���C���N�������g
      --���ڐ��̃`�F�b�N
      ln_item_cnt := (LENGTHB(lt_if_data_tab(ln_cnt_a)) -
                     (LENGTHB(REPLACE(lt_if_data_tab(ln_cnt_a),cv_msg_comma,''))) + 1);             -- �f�[�^���ڐ����i�[
      --
      IF (gn_item_num <> ln_item_cnt) THEN                                                          -- ���ڐ�����v���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm                            -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_csm_msg_028                      -- ���b�Z�[�W�R�[�h
                                            ,iv_token_name1  => cv_tkn_count                        -- �g�[�N���R�[�h1
                                            ,iv_token_name2  => cv_tkn_count_2                      -- �g�[�N���R�[�h2
                                            ,iv_token_value1 => ln_item_cnt                         -- �g�[�N���l1
                                            ,iv_token_value2 => ln_cnt_a                            -- �g�[�N���l2
                                            );
        lv_errbuf := lv_errmsg;
        RAISE get_if_data_expt;
      END IF;
      --
      ln_cnt_b := 0;                                                                                -- �J�E���^��������
--
      <<get_column_loop>>                                                                           -- ���ڒl�擾LOOP
      LOOP
        EXIT WHEN ln_cnt_b >= gn_item_num;
        ln_cnt_b := ln_cnt_b + 1;                                                                   -- �J�E���^���C���N�������g
        lt_plan_item_tab(ln_cnt_b) := xxccp_common_pkg.char_delim_partition(                        -- �f���~�^�����ϊ����ʊ֐�
                                                       iv_char     =>  lt_if_data_tab(ln_cnt_a)
                                                      ,iv_delim    =>  cv_msg_comma
                                                      ,in_part_num =>  (ln_cnt_b)
                                                       );                                           -- �ϐ��ɍ��ڂ̒l���i�[
--
      END LOOP get_column_loop;
      INSERT INTO  
        xxcsm_wk_sales_plan(                                                                        -- �̔��v�惏�[�N�e�[�u��
          plan_year                                                                                 -- �\�Z�N�x
         ,plan_ym                                                                                   -- �N��
         ,location_cd                                                                               -- ���_�R�[�h
         ,act_work_date                                                                             -- ������
         ,plan_staff                                                                                -- �v��l��
         ,sale_plan_depart                                                                          -- �ʔ̓X����v��
         ,sale_plan_cvs                                                                             -- CVS����v��
         ,sale_plan_dealer                                                                          -- �≮����v��
         ,sale_plan_vendor                                                                          -- �x���_�[����v��
         ,sale_plan_others                                                                          -- ���̑�����v��
         ,sale_plan_total                                                                           -- ����v�捇�v
         ,sale_plan_spare_1                                                                         -- �Ƒԕʔ���v��i�\���P�j
         ,sale_plan_spare_2                                                                         -- �Ƒԕʔ���v��i�\���Q�j
         ,sale_plan_spare_3                                                                         -- �Ƒԕʔ���v��i�\���R�j
         ,ly_revision_depart                                                                        -- �O�N���яC���i�ʔ̓X�j
         ,ly_revision_cvs                                                                           -- �O�N���яC���iCVS�j
         ,ly_revision_dealer                                                                        -- �O�N���яC���i�≮�j
         ,ly_revision_others                                                                        -- �O�N���яC���i���̑��j
         ,ly_revision_vendor                                                                        -- �O�N���яC���i�x���_�[�j
         ,ly_revision_spare_1                                                                       -- �O�N���яC���i�\���P�j
         ,ly_revision_spare_2                                                                       -- �O�N���яC���i�\���Q�j
         ,ly_revision_spare_3                                                                       -- �O�N���яC���i�\���R�j
         ,ly_exist_total                                                                            -- ��N����v��_�����q�i�S�́j
         ,ly_newly_total                                                                            -- ��N����v��_�V�K�q�i�S�́j
         ,ty_first_total                                                                            -- �{�N����v��_�V�K����i�S�́j
         ,ty_turn_total                                                                             -- �{�N����v��_�V�K��]�i�S�́j
         ,discount_total                                                                            -- �����l���i�S�́j
         ,ly_exist_vd_charge                                                                        -- ��N����v��_�����q�iVD�j�S���x�[�X
         ,ly_newly_vd_charge                                                                        -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
         ,ty_first_vd_charge                                                                        -- �{�N����v��_�V�K����iVD�j�S���x�[�X
         ,ty_turn_vd_charge                                                                         -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
         ,ty_first_vd_get                                                                           -- �{�N����v��_�V�K����iVD�j�l���x�[�X
         ,ty_turn_vd_get                                                                            -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
         ,st_mon_get_total                                                                          -- �����ڋq���i�S�́j�l���x�[�X
         ,newly_get_total                                                                           -- �V�K�����i�S�́j�l���x�[�X
         ,cancel_get_total                                                                          -- ���~�����i�S�́j�l���x�[�X
         ,newly_charge_total                                                                        -- �V�K�����i�S�́j�S���x�[�X
         ,st_mon_get_vd                                                                             -- �����ڋq���iVD�j�l���x�[�X
         ,newly_get_vd                                                                              -- �V�K�����iVD�j�l���x�[�X
         ,cancel_get_vd                                                                             -- ���~�����iVD�j�l���x�[�X
         ,newly_charge_vd_own                                                                       -- ���͐V�K�����iVD�j�S���x�[�X
         ,newly_charge_vd_help                                                                      -- ���͐V�K�����iVD�j�S���x�[�X
         ,cancel_charge_vd                                                                          -- ���~�����iVD�j�S���x�[�X
         ,patrol_visit_cnt                                                                          -- ����K��ڋq��
         ,patrol_def_visit_cnt                                                                      -- ���񉄖K�⌬��
         ,vendor_visit_cnt                                                                          -- �x���_�[�K��ڋq��
         ,vendor_def_visit_cnt                                                                      -- �x���_�[���K�⌬��
         ,public_visit_cnt                                                                          -- ��ʖK��ڋq��
         ,public_def_visit_cnt                                                                      -- ��ʉ��K�⌬��
         ,def_cnt_total                                                                             -- ���K�⌬�����v
         ,vend_machine_sales_plan                                                                   -- ���̋@����v��
         ,vend_machine_margin                                                                       -- ���̋@�v��e���v
         ,vend_machine_bm                                                                           -- ���̋@�萔���iBM�j
         ,vend_machine_elect                                                                        -- ���̋@�萔���i�d�C��j
         ,vend_machine_lease                                                                        -- ���̋@���[�X��
         ,vend_machine_manage                                                                       -- ���̋@�ێ��Ǘ���
         ,vend_machine_sup_money                                                                    -- ���̋@�v�拦�^��
         ,vend_machine_total                                                                        -- ���̋@�v���p���v
         ,vend_machine_profit                                                                       -- ���_���̋@���v
         ,deficit_num                                                                               -- �Ԏ��䐔
         ,par_machine                                                                               -- �p�[�}�V��
         ,possession_num                                                                            -- �ۗL�䐔
         ,stock_num                                                                                 -- �݌ɑ䐔
         ,operation_num                                                                             -- �ғ��䐔
         ,increase                                                                                  -- ����
         ,new_setting_own                                                                           -- �V�K�ݒu�䐔�i���́j
         ,new_setting_help                                                                          -- �V�K�ݒu�䐔�i���́j
         ,new_setting_total                                                                         -- �V�K�ݒu�䐔���v
         ,withdraw_num                                                                              -- �P�ƈ��g�䐔
         ,new_num_newly                                                                             -- �V��䐔�i�V�K�j
         ,new_num_replace                                                                           -- �V��䐔�i��ցj
         ,new_num_total                                                                             -- �V��䐔���v
         ,old_num_newly                                                                             -- ����䐔�i�V�K�j
         ,old_num_replace                                                                           -- ����䐔�i��ցE�ڐ݁j
         ,disposal_num                                                                              -- �p���䐔
         ,enter_num                                                                                 -- ���_�Ԉړ��䐔
         ,appear_num                                                                                -- ���_�Ԉڏo�䐔
         ,vend_machine_plan_spare_1                                                                 -- �����̔��@�v��i�\���P�j
         ,vend_machine_plan_spare_2                                                                 -- �����̔��@�v��i�\���Q�j
         ,vend_machine_plan_spare_3                                                                 -- �����̔��@�v��i�\���R�j
         ,spare_1                                                                                   -- �\���P
         ,spare_2                                                                                   -- �\���Q
         ,spare_3                                                                                   -- �\���R
         ,spare_4                                                                                   -- �\���S
         ,spare_5                                                                                   -- �\���T
         ,spare_6                                                                                   -- �\���U
         ,spare_7                                                                                   -- �\���V
         ,spare_8                                                                                   -- �\���W
         ,spare_9                                                                                   -- �\���X
         ,spare_10                                                                                  -- �\���P�O
         )
        VALUES(
          lt_plan_item_tab(1)                                                                       -- �\�Z�N�x
         ,lt_plan_item_tab(2)                                                                       -- �N��
         ,lt_plan_item_tab(3)                                                                       -- ���_�R�[�h
         ,lt_plan_item_tab(4)                                                                       -- ������
         ,lt_plan_item_tab(5)                                                                       -- �v��l��
         ,lt_plan_item_tab(6)                                                                       -- �ʔ̓X����v��
         ,lt_plan_item_tab(7)                                                                       -- CVS����v��
         ,lt_plan_item_tab(8)                                                                       -- �≮����v��
--//+UPD START 2009/02/10 CT004 K.Yamada
--         ,lt_plan_item_tab(9)                                                                       -- ���̑�����v��
--         ,lt_plan_item_tab(10)                                                                      -- �x���_�[����v��
         -- CSV�t�@�C���̏��i���̑��A�x���_�[�j
         ,lt_plan_item_tab(10)                                                                      -- �x���_�[����v��
         ,lt_plan_item_tab(9)                                                                       -- ���̑�����v��
--//+UPD END   2009/02/10 CT004 K.Yamada
         ,lt_plan_item_tab(11)                                                                      -- ����v�捇�v
         ,lt_plan_item_tab(12)                                                                      -- �Ƒԕʔ���v��i�\���P�j
         ,lt_plan_item_tab(13)                                                                      -- �Ƒԕʔ���v��i�\���Q�j
         ,lt_plan_item_tab(14)                                                                      -- �Ƒԕʔ���v��i�\���R�j
         ,lt_plan_item_tab(15)                                                                      -- �O�N���яC���i�ʔ̓X�j
         ,lt_plan_item_tab(16)                                                                      -- �O�N���яC���iCVS�j
         ,lt_plan_item_tab(17)                                                                      -- �O�N���яC���i�≮�j
         ,lt_plan_item_tab(18)                                                                      -- �O�N���яC���i���̑��j
         ,lt_plan_item_tab(19)                                                                      -- �O�N���яC���i�x���_�[�j
         ,lt_plan_item_tab(20)                                                                      -- �O�N���яC���i�\���P�j
         ,lt_plan_item_tab(21)                                                                      -- �O�N���яC���i�\���Q�j
         ,lt_plan_item_tab(22)                                                                      -- �O�N���яC���i�\���R�j
         ,lt_plan_item_tab(23)                                                                      -- ��N����v��_�����q�i�S�́j
         ,lt_plan_item_tab(24)                                                                      -- ��N����v��_�V�K�q�i�S�́j
         ,lt_plan_item_tab(25)                                                                      -- �{�N����v��_�V�K����i�S�́j
         ,lt_plan_item_tab(26)                                                                      -- �{�N����v��_�V�K��]�i�S�́j
         ,lt_plan_item_tab(27)                                                                      -- �����l���i�S�́j
         ,lt_plan_item_tab(28)                                                                      -- ��N����v��_�����q�iVD�j�S���x�[�X
         ,lt_plan_item_tab(29)                                                                      -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
         ,lt_plan_item_tab(30)                                                                      -- �{�N����v��_�V�K����iVD�j�S���x�[�X
         ,lt_plan_item_tab(31)                                                                      -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
         ,lt_plan_item_tab(32)                                                                      -- �{�N����v��_�V�K����iVD�j�l���x�[�X
         ,lt_plan_item_tab(33)                                                                      -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
         ,lt_plan_item_tab(34)                                                                      -- �����ڋq���i�S�́j�l���x�[�X
         ,lt_plan_item_tab(35)                                                                      -- �V�K�����i�S�́j�l���x�[�X
         ,lt_plan_item_tab(36)                                                                      -- ���~�����i�S�́j�l���x�[�X
         ,lt_plan_item_tab(37)                                                                      -- �V�K�����i�S�́j�S���x�[�X
         ,lt_plan_item_tab(38)                                                                      -- �����ڋq���iVD�j�l���x�[�X
         ,lt_plan_item_tab(39)                                                                      -- �V�K�����iVD�j�l���x�[�X
         ,lt_plan_item_tab(40)                                                                      -- ���~�����iVD�j�l���x�[�X
         ,lt_plan_item_tab(41)                                                                      -- ���͐V�K�����iVD�j�S���x�[�X
         ,lt_plan_item_tab(42)                                                                      -- ���͐V�K�����iVD�j�S���x�[�X
         ,lt_plan_item_tab(43)                                                                      -- ���~�����iVD�j�S���x�[�X
         ,lt_plan_item_tab(44)                                                                      -- ����K��ڋq��
         ,lt_plan_item_tab(45)                                                                      -- ���񉄖K�⌬��
         ,lt_plan_item_tab(46)                                                                      -- �x���_�[�K��ڋq��
         ,lt_plan_item_tab(47)                                                                      -- �x���_�[���K�⌬��
         ,lt_plan_item_tab(48)                                                                      -- ��ʖK��ڋq��
         ,lt_plan_item_tab(49)                                                                      -- ��ʉ��K�⌬��
         ,lt_plan_item_tab(50)                                                                      -- ���K�⌬�����v
         ,lt_plan_item_tab(51)                                                                      -- ���̋@����v��
         ,lt_plan_item_tab(52)                                                                      -- ���̋@�v��e���v
         ,lt_plan_item_tab(53)                                                                      -- ���̋@�萔���iBM�j
         ,lt_plan_item_tab(54)                                                                      -- ���̋@�萔���i�d�C��j
         ,lt_plan_item_tab(55)                                                                      -- ���̋@���[�X��
         ,lt_plan_item_tab(56)                                                                      -- ���̋@�ێ��Ǘ���
         ,lt_plan_item_tab(57)                                                                      -- ���̋@�v�拦�^��
         ,lt_plan_item_tab(58)                                                                      -- ���̋@�v���p���v
         ,lt_plan_item_tab(59)                                                                      -- ���_���̋@���v
         ,lt_plan_item_tab(60)                                                                      -- �Ԏ��䐔
         ,lt_plan_item_tab(61)                                                                      -- �p�[�}�V��
         ,lt_plan_item_tab(62)                                                                      -- �ۗL�䐔
         ,lt_plan_item_tab(63)                                                                      -- �݌ɑ䐔
         ,lt_plan_item_tab(64)                                                                      -- �ғ��䐔
         ,lt_plan_item_tab(65)                                                                      -- ����
         ,lt_plan_item_tab(66)                                                                      -- �V�K�ݒu�䐔�i���́j
         ,lt_plan_item_tab(67)                                                                      -- �V�K�ݒu�䐔�i���́j
         ,lt_plan_item_tab(68)                                                                      -- �V�K�ݒu�䐔���v
         ,lt_plan_item_tab(69)                                                                      -- �P�ƈ��g�䐔
         ,lt_plan_item_tab(70)                                                                      -- �V��䐔�i�V�K�j
         ,lt_plan_item_tab(71)                                                                      -- �V��䐔�i��ցj
         ,lt_plan_item_tab(72)                                                                      -- �V��䐔���v
         ,lt_plan_item_tab(73)                                                                      -- ����䐔�i�V�K�j
         ,lt_plan_item_tab(74)                                                                      -- ����䐔�i��ցE�ڐ݁j
         ,lt_plan_item_tab(75)                                                                      -- �p���䐔
         ,lt_plan_item_tab(76)                                                                      -- ���_�Ԉړ��䐔
         ,lt_plan_item_tab(77)                                                                      -- ���_�Ԉڏo�䐔
         ,lt_plan_item_tab(78)                                                                      -- �����̔��@�v��i�\���P�j
         ,lt_plan_item_tab(79)                                                                      -- �����̔��@�v��i�\���Q�j
         ,lt_plan_item_tab(80)                                                                      -- �����̔��@�v��i�\���R�j
         ,lt_plan_item_tab(81)                                                                      -- �\���P
         ,lt_plan_item_tab(82)                                                                      -- �\���Q
         ,lt_plan_item_tab(83)                                                                      -- �\���R
         ,lt_plan_item_tab(84)                                                                      -- �\���S
         ,lt_plan_item_tab(85)                                                                      -- �\���T
         ,lt_plan_item_tab(86)                                                                      -- �\���U
         ,lt_plan_item_tab(87)                                                                      -- �\���V
         ,lt_plan_item_tab(88)                                                                      -- �\���W
         ,lt_plan_item_tab(89)                                                                      -- �\���X
         ,lt_plan_item_tab(90)                                                                      -- �\���P�O
        );
    END LOOP ins_wk_loop;
--
  EXCEPTION
    WHEN get_if_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END  get_if_data;
--
  /**********************************************************************************
   * Procedure Name   :  check_location
   * Description      :  ���_�f�[�^�Ó����`�F�b�N(A-5)
   ***********************************************************************************/
--
  PROCEDURE check_location(
    iv_plan_year    IN  VARCHAR2                                                                    -- �Ώ۔N�x
   ,iv_location_cd  IN  VARCHAR2                                                                    -- ���_�R�[�h
   ,ov_errbuf       OUT NOCOPY VARCHAR2                                                             -- �G���[�E���b�Z�[�W
   ,ov_retcode      OUT NOCOPY VARCHAR2                                                             -- ���^�[���E�R�[�h
   ,ov_errmsg       OUT NOCOPY VARCHAR2)                                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'check_location';                                     -- �v���O������
    cv_cust_cd_1    CONSTANT VARCHAR2(1)   := '1';                                                  -- �ڋq�敪�i1�j
    cv_month_1      CONSTANT VARCHAR2(10)  := '01';                                                 -- 1��
    cv_month_2      CONSTANT VARCHAR2(10)  := '02';                                                 -- 2��
    cv_month_3      CONSTANT VARCHAR2(10)  := '03';                                                 -- 3��
    cv_month_4      CONSTANT VARCHAR2(10)  := '04';                                                 -- 4��
    cv_month_5      CONSTANT VARCHAR2(10)  := '05';                                                 -- 5��
    cv_month_6      CONSTANT VARCHAR2(10)  := '06';                                                 -- 6��
    cv_month_7      CONSTANT VARCHAR2(10)  := '07';                                                 -- 7��
    cv_month_8      CONSTANT VARCHAR2(10)  := '08';                                                 -- 8��
    cv_month_9      CONSTANT VARCHAR2(10)  := '09';                                                 -- 9��
    cv_month_10     CONSTANT VARCHAR2(10)  := '10';                                                 -- 10��
    cv_month_11     CONSTANT VARCHAR2(10)  := '11';                                                 -- 11��
    cv_month_12     CONSTANT VARCHAR2(10)  := '12';                                                 -- 12��
    cn_cnt_12       CONSTANT NUMBER(10)    := '12';                                                 -- 12�����`�F�b�N
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf       VARCHAR2(4000);                                                                 -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                                                                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(4000);                                                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_plan_ym      VARCHAR2(1000);
    lv_year         VARCHAR2(1000);
    lv_month        VARCHAR2(1000);
    lv_data_cnt     VARCHAR2(1000);
    lv_planyear     VARCHAR2(1000);
    lv_location_cd  VARCHAR2(1000);
    ln_check_12     NUMBER;                                                                         -- 12�������f�[�^�i�[�p
    ln_location_cnt NUMBER;                                                                         -- ���_�R�[�h�����i�[�p
--  
    CURSOR data_lock_cur                                                                            -- ���b�N�擾�J�[�\��
    IS
      SELECT      xsp.plan_year        plan_year                                                    -- �\�Z�N�x
                 ,xsp.location_cd      location_cd                                                  -- ���_�R�[�h
      INTO        lv_planyear
                 ,lv_location_cd
      FROM        xxcsm_sales_plan  xsp                                                             -- �̔��v��e�[�u��
      WHERE       xsp.plan_year     =  iv_plan_year                                                 -- �\�Z�N�x
        AND       xsp.location_cd   =  iv_location_cd                                               -- ���_�R�[�h
      FOR UPDATE  NOWAIT;
--
    chk_warning_expt  EXCEPTION;
  BEGIN
--
    ov_retcode      := cv_status_normal;                                                            -- �ϐ��̏�����
    ln_check_12     := 0;
    ln_location_cnt := 0;
--
      --==============================================================
      --  �N�ԃf�[�^���݃`�F�b�N(12�������̃f�[�^�`�F�b�N)
      --==============================================================
--
    IF (iv_plan_year IS NOT NULL AND iv_location_cd IS NOT NULL) THEN                               -- �\�Z�N�x�A���_�R�[�h��NULL�ȊO�̏ꍇ
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- �̔��v�惏�[�N�e�[�u��
      WHERE   wsp.plan_year   = iv_plan_year
      AND     wsp.location_cd = iv_location_cd;                                                      -- �\�Z�N�x�A���_�R�[�h����v
    END IF;
--
/***************************************************************************************************
  --�ȉ��̋L�q�͂̓G���[���̌������J�E���g����ׂ�SQL�ł��B
****************************************************************************************************/
    IF (iv_plan_year IS NOT NULL AND iv_location_cd IS  NULL) THEN                                  -- �\�Z�N�x��NULL�ȊO�A���_�R�[�h��NULL�̏ꍇ
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- �̔��v�惏�[�N�e�[�u��
      WHERE   wsp.plan_year   = iv_plan_year
      AND     wsp.location_cd IS NULL;                                                              -- �\�Z�N�x����v�A���_�R�[�h��NULL
    END IF;
--
    IF (iv_plan_year IS  NULL AND iv_location_cd IS NOT NULL) THEN                                  -- �\�Z�N�x��NULL�A���_�R�[�h��NULL�ȊO�̏ꍇ
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- �̔��v�惏�[�N�e�[�u��
      WHERE   wsp.plan_year IS NULL
      AND     wsp.location_cd =iv_location_cd;                                                      -- �\�Z�N�x��NULL�A���_�R�[�h����v
    END IF;
--
    IF (iv_plan_year IS  NULL AND iv_location_cd IS  NULL) THEN                                     -- �\�Z�N�x�A���_�R�[�h��NULL�̏ꍇ
      SELECT  COUNT(1)
      INTO    ln_check_12
      FROM    xxcsm_wk_sales_plan  wsp                                                              -- �̔��v�惏�[�N�e�[�u��
      WHERE   wsp.plan_year IS NULL
      AND     wsp.location_cd IS NULL;                                                              -- �\�Z�N�x�A���_�R�[�h��NULL
    END IF;
/***************************************************************************************************
****************************************************************************************************/
--
    gn_counter := ln_check_12;                                                                      -- �ϐ��ɑΏی������i�[
--
    IF (ln_check_12 <> cn_cnt_12) THEN                                                              -- �Ώی�����12�ȊO�̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_027                                              --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_loca_cd                                              --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_location_cd                                              --�g�[�N���l1
                     );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- �o�͂ɕ\��
                       ,buff   => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
                       );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  ���_��񑶍݃`�F�b�N
      --==============================================================
--
    SELECT COUNT(1)
    INTO   ln_location_cnt
    FROM   hz_cust_accounts  hca                                                                    -- �ڋq�}�X�^
    WHERE  hca.customer_class_code = cv_cust_cd_1                                                   -- �ڋq�敪
      AND  hca.account_number = iv_location_cd;                                                     -- �ڋq�R�[�h
--
    IF (ln_location_cnt = 0) THEN                                                                   -- ���_�R�[�h�����݂��Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm                             -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_csm_msg_024                       -- ���b�Z�[�W�R�[�h
                                           ,iv_token_name1  => cv_tkn_loca_cd                       -- �g�[�N���R�[�h1
                                           ,iv_token_value1 => iv_location_cd                       -- �g�[�N���l1
                                           ); 
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- �o�͂ɕ\��
                       ,buff   => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
                       );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  �\�Z�N�x�`�F�b�N
      --==============================================================
--
    IF (iv_plan_year <> gn_object_year) THEN                                                        -- �\�Z�N�x���s��v�̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm                                                    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_csm_msg_025                                              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_pl_year                                              -- �g�[�N���R�[�h1
                    ,iv_token_name2  => cv_tkn_loca_cd                                              -- �g�[�N���R�[�h2
                    ,iv_token_value1 => iv_plan_year                                                -- �g�[�N���l1
                    ,iv_token_value2 => iv_location_cd                                              -- �g�[�N���l2
                    );
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT                                                   -- �o�͂ɕ\��
                       ,buff   => lv_errmsg                                                         -- ���[�U�[�E�G���[���b�Z�[�W
                       );
      gv_check_flag := cv_chk_warning;                                                              -- �`�F�b�N�t���O��ON
      RAISE chk_warning_expt;
    END IF;
--
      --==============================================================
      --  A-5  �N�ԃf�[�^���݃`�F�b�N
      --==============================================================
--
    BEGIN
      SELECT   spv.plan_ym                                   plan_ym                                -- �N��
              ,spv.year                                      year                                   -- �N
              ,spv.month                                     month                                  -- ��
              ,spv.data_cnt                                  data_cnt                               -- �Ώی��f�[�^���݌���
      INTO     lv_plan_ym
              ,lv_year
              ,lv_month
              ,lv_data_cnt
      FROM     (SELECT    wsp.plan_ym                        plan_ym                                -- �N��
                         ,SUBSTRB(wsp.plan_ym,1,4)           year                                   -- �N
                         ,NVL(SUBSTRB(wsp.plan_ym,5,2),'00') month                                  -- ��
                         ,COUNT(1)                           data_cnt                               -- �Ώی��f�[�^���݌���
                FROM      xxcsm_wk_sales_plan                wsp                                    -- �̔��v�惏�[�N�e�[�u��
                WHERE     wsp.plan_year         = iv_plan_year                                      -- �\�Z�N�x
                  AND     wsp.location_cd       = iv_location_cd                                    -- ���_�R�[�h
                GROUP BY  wsp.plan_ym                                                               -- �N��
               )  spv                                                                               -- �̔��v�挎�ʌ����r���[
      WHERE    (spv.data_cnt <> 1                                                                   -- �f�[�^���݌�����1���ȊO
         OR    (spv.year = iv_plan_year                                                             -- �N = �\�Z�N�x
               AND spv.month NOT IN (cv_month_5                                                     -- 5��
                                    ,cv_month_6                                                     -- 6��
                                    ,cv_month_7                                                     -- 7��
                                    ,cv_month_8                                                     -- 8��
                                    ,cv_month_9                                                     -- 9��
                                    ,cv_month_10                                                    -- 10��
                                    ,cv_month_11                                                    -- 11��
                                    ,cv_month_12                                                    -- 12��
                                    ))
         OR    (spv.year = TO_CHAR(TO_NUMBER(iv_plan_year) + 1)                                     -- �N = �\�Z�N�x + 1
               AND spv.month NOT IN (cv_month_1                                                     -- 1��
                                    ,cv_month_2                                                     -- 2��
                                    ,cv_month_3                                                     -- 3��
                                    ,cv_month_4                                                     -- 4��
                                    ))
         OR    spv.year NOT IN  (iv_plan_year,TO_CHAR(TO_NUMBER(iv_plan_year) + 1)))
        AND    ROWNUM = 1;
--
      IF (lv_data_cnt > 1) THEN                                                                     -- �d���f�[�^�����݂���ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_026                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_plan_ym                                            -- �g�[�N���R�[�h1
                      ,iv_token_name2  => cv_tkn_loca_cd                                              -- �g�[�N���R�[�h2
                      ,iv_token_value1 => lv_plan_ym                                                -- �g�[�N���l1
                      ,iv_token_value2 => iv_location_cd                                            -- �g�[�N���l2
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- �o�͂ɕ\��
                         ,buff   => lv_errmsg                                                       -- ���[�U�[�E�G���[���b�Z�[�W
                         );
        lv_errbuf := lv_errmsg;
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
      ELSE                                                                                          -- �N���ɕs���Ȓl���ݒ肳��Ă����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_040                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_plan_ym                                            -- �g�[�N���R�[�h1
                      ,iv_token_name2  => cv_tkn_loca_cd                                            -- �g�[�N���R�[�h2
                      ,iv_token_value1 => lv_plan_ym                                                -- �g�[�N���l1
                      ,iv_token_value2 => iv_location_cd                                            -- �g�[�N���l2
                      );
        fnd_file.put_line(
                          which  => FND_FILE.OUTPUT                                                 -- �o�͂ɕ\��
                         ,buff   => lv_errmsg                                                       -- ���[�U�[�E�G���[���b�Z�[�W
                         );
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL;
    END;
--
      --==============================================================
      --  A-5   �̔��v��e�[�u�������f�[�^�̃��b�N
      --==============================================================
--
    BEGIN
      OPEN  data_lock_cur;
      CLOSE data_lock_cur;
    EXCEPTION
      WHEN OTHERS THEN                                                                              -- ���b�N�̎擾�Ɏ��s�����ꍇ
        IF (data_lock_cur%ISOPEN) THEN
          CLOSE data_lock_cur;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm                                                  -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_csm_msg_043                                            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_pl_year                                            -- �g�[�N���R�[�h1
                      ,iv_token_name2  => cv_tkn_loca_cd                                            -- �g�[�N���R�[�h2
                      ,iv_token_value1 => iv_plan_year                                              -- �g�[�N���l1
                      ,iv_token_value2 => iv_location_cd                                            -- �g�[�N���l2
                      );
        fnd_file.put_line(
                       which  => FND_FILE.OUTPUT                                                    -- �o�͂ɕ\��
                      ,buff   => lv_errmsg                                                          -- ���[�U�[�E�G���[���b�Z�[�W
                       );
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
    END;
--
      --==============================================================
      --  A-5   �̔��v��e�[�u������f�[�^�̍폜
      --==============================================================
--
    DELETE   FROM  xxcsm_sales_plan   xsp                                                           -- �̔��v��e�[�u��
    WHERE    xsp.plan_year    = iv_plan_year                                                        -- �\�Z�N�x
      AND    xsp.location_cd  = iv_location_cd;                                                     -- ���_�R�[�h
--
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN chk_warning_expt THEN
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_location;
--
  /**********************************************************************************
   * Procedure Name   : check_item
   * Description      : ���ڑÓ����`�F�b�N(A-6)
   ***********************************************************************************/
--
  PROCEDURE check_item(
    ir_plan_rec   IN  xxcsm_wk_sales_plan%ROWTYPE                                                   -- �Ώۃ��R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item';                                           -- �v���O������
    cn_zero       CONSTANT NUMBER        := 0;
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_check_cnt  NUMBER;
--
    lt_check_data_tab gt_check_data_ttype;                                                          -- �e�[�u���^�ϐ��̐錾
    chk_warning_expt  EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;                                                                 -- �ϐ��̏�����
--
    lt_check_data_tab(1)  := ir_plan_rec.plan_year;                                                 -- �\�Z�N�x
    lt_check_data_tab(2)  := ir_plan_rec.plan_ym;                                                   -- �N��
    lt_check_data_tab(3)  := ir_plan_rec.location_cd;                                               -- ���_�R�[�h
    lt_check_data_tab(4)  := ir_plan_rec.act_work_date;                                             -- ������
    lt_check_data_tab(5)  := ir_plan_rec.plan_staff;                                                -- �v��l��
    lt_check_data_tab(6)  := ir_plan_rec.sale_plan_depart;                                          -- �ʔ̓X����v��
    lt_check_data_tab(7)  := ir_plan_rec.sale_plan_cvs;                                             -- CVS����v��
    lt_check_data_tab(8)  := ir_plan_rec.sale_plan_dealer;                                          -- �≮����v��
    -- �Q�ƃ^�C�v�̃R�[�h���i�x���_�[�A���̑��j
    lt_check_data_tab(9)  := ir_plan_rec.sale_plan_vendor;                                          -- �x���_�[����v��
    lt_check_data_tab(10) := ir_plan_rec.sale_plan_others;                                          -- ���̑�����v��
    lt_check_data_tab(11) := ir_plan_rec.sale_plan_total;                                           -- ����v�捇�v
    lt_check_data_tab(12) := ir_plan_rec.sale_plan_spare_1;                                         -- �Ƒԕʔ���v��i�\���P�j
    lt_check_data_tab(13) := ir_plan_rec.sale_plan_spare_2;                                         -- �Ƒԕʔ���v��i�\���Q�j
    lt_check_data_tab(14) := ir_plan_rec.sale_plan_spare_3;                                         -- �Ƒԕʔ���v��i�\���R�j
    lt_check_data_tab(15) := ir_plan_rec.ly_revision_depart;                                        -- �O�N���яC���i�ʔ̓X�j
    lt_check_data_tab(16) := ir_plan_rec.ly_revision_cvs;                                           -- �O�N���яC���iCVS�j
    lt_check_data_tab(17) := ir_plan_rec.ly_revision_dealer;                                        -- �O�N���яC���i�≮�j
    lt_check_data_tab(18) := ir_plan_rec.ly_revision_others;                                        -- �O�N���яC���i���̑��j
    lt_check_data_tab(19) := ir_plan_rec.ly_revision_vendor;                                        -- �O�N���яC���i�x���_�[�j
    lt_check_data_tab(20) := ir_plan_rec.ly_revision_spare_1;                                       -- �O�N���яC���i�\���P�j
    lt_check_data_tab(21) := ir_plan_rec.ly_revision_spare_2;                                       -- �O�N���яC���i�\���Q�j
    lt_check_data_tab(22) := ir_plan_rec.ly_revision_spare_3;                                       -- �O�N���яC���i�\���R�j
    lt_check_data_tab(23) := ir_plan_rec.ly_exist_total;                                            -- ��N����v��_�����q�i�S�́j
    lt_check_data_tab(24) := ir_plan_rec.ly_newly_total;                                            -- ��N����v��_�V�K�q�i�S�́j
    lt_check_data_tab(25) := ir_plan_rec.ty_first_total;                                            -- �{�N����v��_�V�K����i�S�́j
    lt_check_data_tab(26) := ir_plan_rec.ty_turn_total;                                             -- �{�N����v��_�V�K��]�i�S�́j
    lt_check_data_tab(27) := ir_plan_rec.discount_total;                                            -- �����l���i�S�́j
    lt_check_data_tab(28) := ir_plan_rec.ly_exist_vd_charge;                                        -- ��N����v��_�����q�iVD�j�S��
    lt_check_data_tab(29) := ir_plan_rec.ly_newly_vd_charge;                                        -- ��N����v��_�V�K�q�iVD�j�S��
    lt_check_data_tab(30) := ir_plan_rec.ty_first_vd_charge;                                        -- �{�N����v��_�V�K����iVD�j�S
    lt_check_data_tab(31) := ir_plan_rec.ty_turn_vd_charge;                                         -- �{�N����v��_�V�K��]�iVD�j�S
    lt_check_data_tab(32) := ir_plan_rec.ty_first_vd_get;                                           -- �{�N����v��_�V�K����iVD�j�l
    lt_check_data_tab(33) := ir_plan_rec.ty_turn_vd_get;                                            -- �{�N����v��_�V�K��]�iVD�j�l
    lt_check_data_tab(34) := ir_plan_rec.st_mon_get_total;                                          -- �����ڋq���i�S�́j�l���x�[�X
    lt_check_data_tab(35) := ir_plan_rec.newly_get_total;                                           -- �V�K�����i�S�́j�l���x�[�X
    lt_check_data_tab(36) := ir_plan_rec.cancel_get_total;                                          -- ���~�����i�S�́j�l���x�[�X
    lt_check_data_tab(37) := ir_plan_rec.newly_charge_total;                                        -- �V�K�����i�S�́j�S���x�[�X
    lt_check_data_tab(38) := ir_plan_rec.st_mon_get_vd;                                             -- �����ڋq���iVD�j�l���x�[�X
    lt_check_data_tab(39) := ir_plan_rec.newly_get_vd;                                              -- �V�K�����iVD�j�l���x�[�X
    lt_check_data_tab(40) := ir_plan_rec.cancel_get_vd;                                             -- ���~�����iVD�j�l���x�[�X
    lt_check_data_tab(41) := ir_plan_rec.newly_charge_vd_own;                                       -- ���͐V�K�����iVD�j�S���x�[�X
    lt_check_data_tab(42) := ir_plan_rec.newly_charge_vd_help;                                      -- ���͐V�K�����iVD�j�S���x�[�X
    lt_check_data_tab(43) := ir_plan_rec.cancel_charge_vd;                                          -- ���~�����iVD�j�S���x�[�X
    lt_check_data_tab(44) := ir_plan_rec.patrol_visit_cnt;                                          -- ����K��ڋq��
    lt_check_data_tab(45) := ir_plan_rec.patrol_def_visit_cnt;                                      -- ���񉄖K�⌬��
    lt_check_data_tab(46) := ir_plan_rec.vendor_visit_cnt;                                          -- �x���_�[�K��ڋq��
    lt_check_data_tab(47) := ir_plan_rec.vendor_def_visit_cnt;                                      -- �x���_�[���K�⌬��
    lt_check_data_tab(48) := ir_plan_rec.public_visit_cnt;                                          -- ��ʖK��ڋq��
    lt_check_data_tab(49) := ir_plan_rec.public_def_visit_cnt;                                      -- ��ʉ��K�⌬��
    lt_check_data_tab(50) := ir_plan_rec.def_cnt_total;                                             -- ���K�⌬�����v
    lt_check_data_tab(51) := ir_plan_rec.vend_machine_sales_plan;                                   -- ���̋@����v��
    lt_check_data_tab(52) := ir_plan_rec.vend_machine_margin;                                       -- ���̋@�v��e���v
    lt_check_data_tab(53) := ir_plan_rec.vend_machine_bm;                                           -- ���̋@�萔���iBM�j
    lt_check_data_tab(54) := ir_plan_rec.vend_machine_elect;                                        -- ���̋@�萔���i�d�C��j
    lt_check_data_tab(55) := ir_plan_rec.vend_machine_lease;                                        -- ���̋@���[�X��
    lt_check_data_tab(56) := ir_plan_rec.vend_machine_manage;                                       -- ���̋@�ێ��Ǘ���
    lt_check_data_tab(57) := ir_plan_rec.vend_machine_sup_money;                                    -- ���̋@�v�拦�^��
    lt_check_data_tab(58) := ir_plan_rec.vend_machine_total;                                        -- ���̋@�v���p���v
    lt_check_data_tab(59) := ir_plan_rec.vend_machine_profit;                                       -- ���_���̋@���v
    lt_check_data_tab(60) := ir_plan_rec.deficit_num;                                               -- �Ԏ��䐔
    lt_check_data_tab(61) := ir_plan_rec.par_machine;                                               -- �p�[�}�V��
    lt_check_data_tab(62) := ir_plan_rec.possession_num;                                            -- �ۗL�䐔
    lt_check_data_tab(63) := ir_plan_rec.stock_num;                                                 -- �݌ɑ䐔
    lt_check_data_tab(64) := ir_plan_rec.operation_num;                                             -- �ғ��䐔
    lt_check_data_tab(65) := ir_plan_rec.increase;                                                  -- ����
    lt_check_data_tab(66) := ir_plan_rec.new_setting_own;                                           -- �V�K�ݒu�䐔�i���́j
    lt_check_data_tab(67) := ir_plan_rec.new_setting_help;                                          -- �V�K�ݒu�䐔�i���́j
    lt_check_data_tab(68) := ir_plan_rec.new_setting_total;                                         -- �V�K�ݒu�䐔���v
    lt_check_data_tab(69) := ir_plan_rec.withdraw_num;                                              -- �P�ƈ��g�䐔
    lt_check_data_tab(70) := ir_plan_rec.new_num_newly;                                             -- �V��䐔�i�V�K�j
    lt_check_data_tab(71) := ir_plan_rec.new_num_replace;                                           -- �V��䐔�i��ցj
    lt_check_data_tab(72) := ir_plan_rec.new_num_total;                                             -- �V��䐔���v
    lt_check_data_tab(73) := ir_plan_rec.old_num_newly;                                             -- ����䐔�i�V�K�j
    lt_check_data_tab(74) := ir_plan_rec.old_num_replace;                                           -- ����䐔�i��ցE�ڐ݁j
    lt_check_data_tab(75) := ir_plan_rec.disposal_num;                                              -- �p���䐔
    lt_check_data_tab(76) := ir_plan_rec.enter_num;                                                 -- ���_�Ԉړ��䐔
    lt_check_data_tab(77) := ir_plan_rec.appear_num;                                                -- ���_�Ԉڏo�䐔
    lt_check_data_tab(78) := ir_plan_rec.vend_machine_plan_spare_1;                                 -- �����̔��@�v��i�\���P�j
    lt_check_data_tab(79) := ir_plan_rec.vend_machine_plan_spare_2;                                 -- �����̔��@�v��i�\���Q�j
    lt_check_data_tab(80) := ir_plan_rec.vend_machine_plan_spare_3;                                 -- �����̔��@�v��i�\���R�j
    lt_check_data_tab(81) := ir_plan_rec.spare_1;                                                   -- �\���P
    lt_check_data_tab(82) := ir_plan_rec.spare_2;                                                   -- �\���Q
    lt_check_data_tab(83) := ir_plan_rec.spare_3;                                                   -- �\���R
    lt_check_data_tab(84) := ir_plan_rec.spare_4;                                                   -- �\���S
    lt_check_data_tab(85) := ir_plan_rec.spare_5;                                                   -- �\���T
    lt_check_data_tab(86) := ir_plan_rec.spare_6;                                                   -- �\���U
    lt_check_data_tab(87) := ir_plan_rec.spare_7;                                                   -- �\���V
    lt_check_data_tab(88) := ir_plan_rec.spare_8;                                                   -- �\���W
    lt_check_data_tab(89) := ir_plan_rec.spare_9;                                                   -- �\���X
    lt_check_data_tab(90) := ir_plan_rec.spare_10;                                                  -- �\���P�O
--
    ln_check_cnt := 0;                                                                              -- �J�E���^�̏�����
--
    <<chk_column_loop>>                                                                             -- ���ڑÓ����`�F�b�NLOOP
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      ln_check_cnt := ln_check_cnt + 1;                                                             -- �J�E���^�����Z
      xxccp_common_pkg2.upload_item_check(
                        iv_item_name    => gt_def_info_tab(ln_check_cnt).meaning                    -- ���ږ���
                       ,iv_item_value   => lt_check_data_tab(ln_check_cnt)                          -- ���ڂ̒l
                       ,in_item_len     => gt_def_info_tab(ln_check_cnt).figures                    -- ���ڂ̒���(��������)
                       ,in_item_decimal => cn_zero                                                  -- ���ڂ̒���(�����_�ȉ�)
                       ,iv_item_nullflg => gt_def_info_tab(ln_check_cnt).essential                  -- �K�{�t���O
                       ,iv_item_attr    => gt_def_info_tab(ln_check_cnt).attribute                  -- ���ڂ̑���
                       ,ov_errbuf       => lv_errbuf 
                       ,ov_retcode      => lv_retcode
                       ,ov_errmsg       => lv_errmsg 
                       );
      IF (lv_retcode <> cv_status_normal) THEN                                                      -- �߂�l���ُ�̏ꍇ
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm                                                 -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_csm_msg_029                                           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_plan_ym                                           -- �g�[�N���R�[�h1
                       ,iv_token_name2  => cv_tkn_loca_cd                                           -- �g�[�N���R�[�h2
--//+UPD START 2009/03/16 T1_0011 M.Ohtsuki
--                       ,iv_token_name3  => cv_tkn_item                                              -- �g�[�N���R�[�h3
--                       ,iv_token_name4  => cv_tkn_err_msg                                           -- �g�[�N���R�[�h4
--��������������������������������������������������������������������������������������������������
                       ,iv_token_name3  => cv_tkn_err_msg                                           -- �g�[�N���R�[�h3
--//+UPD END   2009/03/16 T1_0011 M.Ohtsuki
                       ,iv_token_value1 => ir_plan_rec.plan_year                                    -- �g�[�N���l1
                       ,iv_token_value2 => ir_plan_rec.location_cd                                  -- �g�[�N���l2
--//+UPD START 2009/03/16 T1_0011 M.Ohtsuki
--                       ,iv_token_value3 => gt_def_info_tab(ln_check_cnt).meaning                    -- �g�[�N���l3
--                       ,iv_token_value4 => lv_errmsg                                                -- �g�[�N���l4
--��������������������������������������������������������������������������������������������������
                       ,iv_token_value3 => lv_errmsg                                                -- �g�[�N���l3
--//+UPD END   2009/03/16 T1_0011 M.Ohtsuki
                       );
         fnd_file.put_line(
                           which  => FND_FILE.OUTPUT                                                -- �o�͂ɕ\��
                          ,buff   => lv_errmsg                                                      -- ���[�U�[�E�G���[���b�Z�[�W
                          );
        gv_check_flag := cv_chk_warning;                                                            -- �`�F�b�N�t���O��ON
        RAISE chk_warning_expt;
      END IF;
    END LOOP chk_column_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN chk_warning_expt THEN
      ov_retcode := cv_status_warn;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_item;
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^ (A-7)
   ***********************************************************************************/
  PROCEDURE insert_data(
    ir_plan_rec   IN  xxcsm_wk_sales_plan%ROWTYPE                                                   -- �Ώۃ��R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data';                                          -- �v���O������
--
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
/***************************************************************************************************
  �������v���O�����͍��ڂ̑Ó����`�F�b�N���s�����߁A�C���T�[�g���͈Öٕϊ����s����B
****************************************************************************************************/
    INSERT INTO  
      xxcsm_sales_plan(
        plan_year                                                                                   -- �\�Z�N�x
       ,plan_ym                                                                                     -- �N��
       ,location_cd                                                                                 -- ���_�R�[�h
       ,act_work_date                                                                               -- ������
       ,plan_staff                                                                                  -- �v��l��
       ,sale_plan_depart                                                                            -- �ʔ̓X����v��
       ,sale_plan_cvs                                                                               -- CVS����v��
       ,sale_plan_dealer                                                                            -- �≮����v��
       ,sale_plan_vendor                                                                            -- �x���_�[����v��
       ,sale_plan_others                                                                            -- ���̑�����v��
       ,sale_plan_total                                                                             -- ����v�捇�v
       ,sale_plan_spare_1                                                                           -- �Ƒԕʔ���v��i�\���P�j
       ,sale_plan_spare_2                                                                           -- �Ƒԕʔ���v��i�\���Q�j
       ,sale_plan_spare_3                                                                           -- �Ƒԕʔ���v��i�\���R�j
       ,ly_revision_depart                                                                          -- �O�N���яC���i�ʔ̓X�j
       ,ly_revision_cvs                                                                             -- �O�N���яC���iCVS�j
       ,ly_revision_dealer                                                                          -- �O�N���яC���i�≮�j
       ,ly_revision_others                                                                          -- �O�N���яC���i���̑��j
       ,ly_revision_vendor                                                                          -- �O�N���яC���i�x���_�[�j
       ,ly_revision_spare_1                                                                         -- �O�N���яC���i�\���P�j
       ,ly_revision_spare_2                                                                         -- �O�N���яC���i�\���Q�j
       ,ly_revision_spare_3                                                                         -- �O�N���яC���i�\���R�j
       ,ly_exist_total                                                                              -- ��N����v��_�����q�i�S�́j
       ,ly_newly_total                                                                              -- ��N����v��_�V�K�q�i�S�́j
       ,ty_first_total                                                                              -- �{�N����v��_�V�K����i�S�́j
       ,ty_turn_total                                                                               -- �{�N����v��_�V�K��]�i�S�́j
       ,discount_total                                                                              -- �����l���i�S�́j
       ,ly_exist_vd_charge                                                                          -- ��N����v��_�����q�iVD�j�S���x�[�X
       ,ly_newly_vd_charge                                                                          -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
       ,ty_first_vd_charge                                                                          -- �{�N����v��_�V�K����iVD�j�S���x�[�X
       ,ty_turn_vd_charge                                                                           -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
       ,ty_first_vd_get                                                                             -- �{�N����v��_�V�K����iVD�j�l���x�[�X
       ,ty_turn_vd_get                                                                              -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
       ,st_mon_get_total                                                                            -- �����ڋq���i�S�́j�l���x�[�X
       ,newly_get_total                                                                             -- �V�K�����i�S�́j�l���x�[�X
       ,cancel_get_total                                                                            -- ���~�����i�S�́j�l���x�[�X
       ,newly_charge_total                                                                          -- �V�K�����i�S�́j�S���x�[�X
       ,st_mon_get_vd                                                                               -- �����ڋq���iVD�j�l���x�[�X
       ,newly_get_vd                                                                                -- �V�K�����iVD�j�l���x�[�X
       ,cancel_get_vd                                                                               -- ���~�����iVD�j�l���x�[�X
       ,newly_charge_vd_own                                                                         -- ���͐V�K�����iVD�j�S���x�[�X
       ,newly_charge_vd_help                                                                        -- ���͐V�K�����iVD�j�S���x�[�X
       ,cancel_charge_vd                                                                            -- ���~�����iVD�j�S���x�[�X
       ,patrol_visit_cnt                                                                            -- ����K��ڋq��
       ,patrol_def_visit_cnt                                                                        -- ���񉄖K�⌬��
       ,vendor_visit_cnt                                                                            -- �x���_�[�K��ڋq��
       ,vendor_def_visit_cnt                                                                        -- �x���_�[���K�⌬��
       ,public_visit_cnt                                                                            -- ��ʖK��ڋq��
       ,public_def_visit_cnt                                                                        -- ��ʉ��K�⌬��
       ,def_cnt_total                                                                               -- ���K�⌬�����v
       ,vend_machine_sales_plan                                                                     -- ���̋@����v��
       ,vend_machine_margin                                                                         -- ���̋@�v��e���v
       ,vend_machine_bm                                                                             -- ���̋@�萔���iBM�j
       ,vend_machine_elect                                                                          -- ���̋@�萔���i�d�C��j
       ,vend_machine_lease                                                                          -- ���̋@���[�X��
       ,vend_machine_manage                                                                         -- ���̋@�ێ��Ǘ���
       ,vend_machine_sup_money                                                                      -- ���̋@�v�拦�^��
       ,vend_machine_total                                                                          -- ���̋@�v���p���v
       ,vend_machine_profit                                                                         -- ���_���̋@���v
       ,deficit_num                                                                                 -- �Ԏ��䐔
       ,par_machine                                                                                 -- �p�[�}�V��
       ,possession_num                                                                              -- �ۗL�䐔
       ,stock_num                                                                                   -- �݌ɑ䐔
       ,operation_num                                                                               -- �ғ��䐔
       ,increase                                                                                    -- ����
       ,new_setting_own                                                                             -- �V�K�ݒu�䐔�i���́j
       ,new_setting_help                                                                            -- �V�K�ݒu�䐔�i���́j
       ,new_setting_total                                                                           -- �V�K�ݒu�䐔���v
       ,withdraw_num                                                                                -- �P�ƈ��g�䐔
       ,new_num_newly                                                                               -- �V��䐔�i�V�K�j
       ,new_num_replace                                                                             -- �V��䐔�i��ցj
       ,new_num_total                                                                               -- �V��䐔���v
       ,old_num_newly                                                                               -- ����䐔�i�V�K�j
       ,old_num_replace                                                                             -- ����䐔�i��ցE�ڐ݁j
       ,disposal_num                                                                                -- �p���䐔
       ,enter_num                                                                                   -- ���_�Ԉړ��䐔
       ,appear_num                                                                                  -- ���_�Ԉڏo�䐔
       ,vend_machine_plan_spare_1                                                                   -- �����̔��@�v��i�\���P�j
       ,vend_machine_plan_spare_2                                                                   -- �����̔��@�v��i�\���Q�j
       ,vend_machine_plan_spare_3                                                                   -- �����̔��@�v��i�\���R�j
       ,spare_1                                                                                     -- �\���P
       ,spare_2                                                                                     -- �\���Q
       ,spare_3                                                                                     -- �\���R
       ,spare_4                                                                                     -- �\���S
       ,spare_5                                                                                     -- �\���T
       ,spare_6                                                                                     -- �\���U
       ,spare_7                                                                                     -- �\���V
       ,spare_8                                                                                     -- �\���W
       ,spare_9                                                                                     -- �\���X
       ,spare_10                                                                                    -- �\���P�O
       ,created_by                                                                                  -- �쐬��
       ,creation_date                                                                               -- �쐬��
       ,last_updated_by                                                                             -- �ŏI�X�V��
       ,last_update_date                                                                            -- �ŏI�X�V��
       ,last_update_login                                                                           -- �ŏI�X�V���O�C��
       ,request_id                                                                                  -- �v��ID
       ,program_application_id                                                                      -- �v���O�����A�v���P�[�V����ID
       ,program_id                                                                                  -- �v���O����ID
       ,program_update_date                                                                         -- �v���O�����X�V��
       )
      VALUES(
        ir_plan_rec.plan_year                                                                       -- �\�Z�N�x
       ,ir_plan_rec.plan_ym                                                                         -- �N��
       ,ir_plan_rec.location_cd                                                                     -- ���_�R�[�h
       ,ir_plan_rec.act_work_date                                                                   -- ������
       ,ir_plan_rec.plan_staff                                                                      -- �v��l��
       ,ir_plan_rec.sale_plan_depart                                                                -- �ʔ̓X����v��
       ,ir_plan_rec.sale_plan_cvs                                                                   -- CVS����v��
       ,ir_plan_rec.sale_plan_dealer                                                                -- �≮����v��
       ,ir_plan_rec.sale_plan_vendor                                                                -- �x���_�[����v��
       ,ir_plan_rec.sale_plan_others                                                                -- ���̑�����v��
       ,ir_plan_rec.sale_plan_total                                                                 -- ����v�捇�v
       ,ir_plan_rec.sale_plan_spare_1                                                               -- �Ƒԕʔ���v��i�\���P�j
       ,ir_plan_rec.sale_plan_spare_2                                                               -- �Ƒԕʔ���v��i�\���Q�j
       ,ir_plan_rec.sale_plan_spare_3                                                               -- �Ƒԕʔ���v��i�\���R�j
       ,ir_plan_rec.ly_revision_depart                                                              -- �O�N���яC���i�ʔ̓X�j
       ,ir_plan_rec.ly_revision_cvs                                                                 -- �O�N���яC���iCVS�j
       ,ir_plan_rec.ly_revision_dealer                                                              -- �O�N���яC���i�≮�j
       ,ir_plan_rec.ly_revision_others                                                              -- �O�N���яC���i���̑��j
       ,ir_plan_rec.ly_revision_vendor                                                              -- �O�N���яC���i�x���_�[�j
       ,ir_plan_rec.ly_revision_spare_1                                                             -- �O�N���яC���i�\���P�j
       ,ir_plan_rec.ly_revision_spare_2                                                             -- �O�N���яC���i�\���Q�j
       ,ir_plan_rec.ly_revision_spare_3                                                             -- �O�N���яC���i�\���R�j
       ,ir_plan_rec.ly_exist_total                                                                  -- ��N����v��_�����q�i�S�́j
       ,ir_plan_rec.ly_newly_total                                                                  -- ��N����v��_�V�K�q�i�S�́j
       ,ir_plan_rec.ty_first_total                                                                  -- �{�N����v��_�V�K����i�S�́j
       ,ir_plan_rec.ty_turn_total                                                                   -- �{�N����v��_�V�K��]�i�S�́j
       ,ir_plan_rec.discount_total                                                                  -- �����l���i�S�́j
       ,ir_plan_rec.ly_exist_vd_charge                                                              -- ��N����v��_�����q�iVD�j�S���x�[�X
       ,ir_plan_rec.ly_newly_vd_charge                                                              -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
       ,ir_plan_rec.ty_first_vd_charge                                                              -- �{�N����v��_�V�K����iVD�j�S���x�[�X
       ,ir_plan_rec.ty_turn_vd_charge                                                               -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
       ,ir_plan_rec.ty_first_vd_get                                                                 -- �{�N����v��_�V�K����iVD�j�l���x�[�X
       ,ir_plan_rec.ty_turn_vd_get                                                                  -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
       ,ir_plan_rec.st_mon_get_total                                                                -- �����ڋq���i�S�́j�l���x�[�X
       ,ir_plan_rec.newly_get_total                                                                 -- �V�K�����i�S�́j�l���x�[�X
       ,ir_plan_rec.cancel_get_total                                                                -- ���~�����i�S�́j�l���x�[�X
       ,ir_plan_rec.newly_charge_total                                                              -- �V�K�����i�S�́j�S���x�[�X
       ,ir_plan_rec.st_mon_get_vd                                                                   -- �����ڋq���iVD�j�l���x�[�X
       ,ir_plan_rec.newly_get_vd                                                                    -- �V�K�����iVD�j�l���x�[�X
       ,ir_plan_rec.cancel_get_vd                                                                   -- ���~�����iVD�j�l���x�[�X
       ,ir_plan_rec.newly_charge_vd_own                                                             -- ���͐V�K�����iVD�j�S���x�[�X
       ,ir_plan_rec.newly_charge_vd_help                                                            -- ���͐V�K�����iVD�j�S���x�[�X
       ,ir_plan_rec.cancel_charge_vd                                                                -- ���~�����iVD�j�S���x�[�X
       ,ir_plan_rec.patrol_visit_cnt                                                                -- ����K��ڋq��
       ,ir_plan_rec.patrol_def_visit_cnt                                                            -- ���񉄖K�⌬��
       ,ir_plan_rec.vendor_visit_cnt                                                                -- �x���_�[�K��ڋq��
       ,ir_plan_rec.vendor_def_visit_cnt                                                            -- �x���_�[���K�⌬��
       ,ir_plan_rec.public_visit_cnt                                                                -- ��ʖK��ڋq��
       ,ir_plan_rec.public_def_visit_cnt                                                            -- ��ʉ��K�⌬��
       ,ir_plan_rec.def_cnt_total                                                                   -- ���K�⌬�����v
       ,ir_plan_rec.vend_machine_sales_plan                                                         -- ���̋@����v��
       ,ir_plan_rec.vend_machine_margin                                                             -- ���̋@�v��e���v
       ,ir_plan_rec.vend_machine_bm                                                                 -- ���̋@�萔���iBM�j
       ,ir_plan_rec.vend_machine_elect                                                              -- ���̋@�萔���i�d�C��j
       ,ir_plan_rec.vend_machine_lease                                                              -- ���̋@���[�X��
       ,ir_plan_rec.vend_machine_manage                                                             -- ���̋@�ێ��Ǘ���
       ,ir_plan_rec.vend_machine_sup_money                                                          -- ���̋@�v�拦�^��
       ,ir_plan_rec.vend_machine_total                                                              -- ���̋@�v���p���v
       ,ir_plan_rec.vend_machine_profit                                                             -- ���_���̋@���v
       ,ir_plan_rec.deficit_num                                                                     -- �Ԏ��䐔
       ,ir_plan_rec.par_machine                                                                     -- �p�[�}�V��
       ,ir_plan_rec.possession_num                                                                  -- �ۗL�䐔
       ,ir_plan_rec.stock_num                                                                       -- �݌ɑ䐔
       ,ir_plan_rec.operation_num                                                                   -- �ғ��䐔
       ,ir_plan_rec.increase                                                                        -- ����
       ,ir_plan_rec.new_setting_own                                                                 -- �V�K�ݒu�䐔�i���́j
       ,ir_plan_rec.new_setting_help                                                                -- �V�K�ݒu�䐔�i���́j
       ,ir_plan_rec.new_setting_total                                                               -- �V�K�ݒu�䐔���v
       ,ir_plan_rec.withdraw_num                                                                    -- �P�ƈ��g�䐔
       ,ir_plan_rec.new_num_newly                                                                   -- �V��䐔�i�V�K�j
       ,ir_plan_rec.new_num_replace                                                                 -- �V��䐔�i��ցj
       ,ir_plan_rec.new_num_total                                                                   -- �V��䐔���v
       ,ir_plan_rec.old_num_newly                                                                   -- ����䐔�i�V�K�j
       ,ir_plan_rec.old_num_replace                                                                 -- ����䐔�i��ցE�ڐ݁j
       ,ir_plan_rec.disposal_num                                                                    -- �p���䐔
       ,ir_plan_rec.enter_num                                                                       -- ���_�Ԉړ��䐔
       ,ir_plan_rec.appear_num                                                                      -- ���_�Ԉڏo�䐔
       ,ir_plan_rec.vend_machine_plan_spare_1                                                       -- �����̔��@�v��i�\���P�j
       ,ir_plan_rec.vend_machine_plan_spare_2                                                       -- �����̔��@�v��i�\���Q�j
       ,ir_plan_rec.vend_machine_plan_spare_3                                                       -- �����̔��@�v��i�\���R�j
       ,ir_plan_rec.spare_1                                                                         -- �\���P
       ,ir_plan_rec.spare_2                                                                         -- �\���Q
       ,ir_plan_rec.spare_3                                                                         -- �\���R
       ,ir_plan_rec.spare_4                                                                         -- �\���S
       ,ir_plan_rec.spare_5                                                                         -- �\���T
       ,ir_plan_rec.spare_6                                                                         -- �\���U
       ,ir_plan_rec.spare_7                                                                         -- �\���V
       ,ir_plan_rec.spare_8                                                                         -- �\���W
       ,ir_plan_rec.spare_9                                                                         -- �\���X
       ,ir_plan_rec.spare_10                                                                        -- �\���P�O
       ,cn_created_by                                                                               -- �쐬��
       ,cd_creation_date                                                                            -- �쐬��
       ,cn_last_updated_by                                                                          -- �ŏI�X�V��
       ,cd_last_update_date                                                                         -- �ŏI�X�V��
       ,cn_last_update_login                                                                        -- �ŏI�X�V���O�C��
       ,cn_request_id                                                                               -- �v��ID
       ,cn_program_application_id                                                                   -- �v���O�����A�v���P�[�V����ID
       ,cn_program_id                                                                               -- �v���O����ID
       ,cd_program_update_date                                                                      -- �v���O�����X�V��
       );
/***************************************************************************************************
****************************************************************************************************/
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �N�Ԍv��f�[�^�擾�A�Z�[�u�|�C���g�̐ݒ� (A-3,A-4)
   ***********************************************************************************/
--
  PROCEDURE loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name          CONSTANT VARCHAR2(100) := 'loop_main';                                     -- �v���O������
    sub_proc_other_expt  EXCEPTION;
--
    lv_errbuf         VARCHAR2(4000);                                                               -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);                                                                  -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(4000);                                                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_location_cd    VARCHAR2(100);                                                                -- ���_�R�[�h�i�[�p
    lv_plan_year      VARCHAR2(100);                                                                -- �\�Z�N�x�i�[�p
    lr_plan_rec       xxcsm_wk_sales_plan%ROWTYPE;                                                  -- �e�[�u���^�ϐ���錾
--
    CURSOR get_data_cur                                                                             -- �N�Ԍv��f�[�^�擾�J�[�\��
    IS
      SELECT     wsp.plan_year                                   plan_year                          -- �\�Z�N�x
                ,wsp.plan_ym                                     plan_ym                            -- �N��
                ,wsp.location_cd                                 location_cd                        -- ���_�R�[�h
                ,NVL(wsp.act_work_date                   ,0)     act_work_date                      -- ������
                ,NVL(wsp.plan_staff                      ,0)     plan_staff                         -- �v��l��
                ,NVL((wsp.sale_plan_depart        * 1000),0)     sale_plan_depart                   -- �ʔ̓X����v��
                ,NVL((wsp.sale_plan_cvs           * 1000),0)     sale_plan_cvs                      -- CVS����v��
                ,NVL((wsp.sale_plan_dealer        * 1000),0)     sale_plan_dealer                   -- �≮����v��
                ,NVL((wsp.sale_plan_vendor        * 1000),0)     sale_plan_vendor                   -- �x���_�[����v��
                ,NVL((wsp.sale_plan_others        * 1000),0)     sale_plan_others                   -- ���̑�����v��
                ,NVL((wsp.sale_plan_total         * 1000),0)     sale_plan_total                    -- ����v�捇�v
                ,NVL(wsp.sale_plan_spare_1               ,0)     sale_plan_spare_1                  -- �Ƒԕʔ���v��i�\���P�j
                ,NVL(wsp.sale_plan_spare_2               ,0)     sale_plan_spare_2                  -- �Ƒԕʔ���v��i�\���Q�j
                ,NVL(wsp.sale_plan_spare_3               ,0)     sale_plan_spare_3                  -- �Ƒԕʔ���v��i�\���R�j
                ,NVL((wsp.ly_revision_depart      * 1000),0)     ly_revision_depart                 -- �O�N���яC���i�ʔ̓X�j
                ,NVL((wsp.ly_revision_cvs         * 1000),0)     ly_revision_cvs                    -- �O�N���яC���iCVS�j
                ,NVL((wsp.ly_revision_dealer      * 1000),0)     ly_revision_dealer                 -- �O�N���яC���i�≮�j
                ,NVL((wsp.ly_revision_others      * 1000),0)     ly_revision_others                 -- �O�N���яC���i���̑��j
                ,NVL((wsp.ly_revision_vendor      * 1000),0)     ly_revision_vendor                 -- �O�N���яC���i�x���_�[�j
                ,NVL(wsp.ly_revision_spare_1             ,0)     ly_revision_spare_1                -- �O�N���яC���i�\���P�j
                ,NVL(wsp.ly_revision_spare_2             ,0)     ly_revision_spare_2                -- �O�N���яC���i�\���Q�j
                ,NVL(wsp.ly_revision_spare_3             ,0)     ly_revision_spare_3                -- �O�N���яC���i�\���R�j
                ,NVL((wsp.ly_exist_total          * 1000),0)     ly_exist_total                     -- ��N����v��_�����q�i�S�́j
                ,NVL((wsp.ly_newly_total          * 1000),0)     ly_newly_total                     -- ��N����v��_�V�K�q�i�S�́j
                ,NVL((wsp.ty_first_total          * 1000),0)     ty_first_total                     -- �{�N����v��_�V�K����i�S�́j
                ,NVL((wsp.ty_turn_total           * 1000),0)     ty_turn_total                      -- �{�N����v��_�V�K��]�i�S�́j
                ,NVL((wsp.discount_total          * 1000),0)     discount_total                     -- �����l���i�S�́j
                ,NVL((wsp.ly_exist_vd_charge      * 1000),0)     ly_exist_vd_charge                 -- ��N����v��_�����q�iVD�j�S���x�[�X
                ,NVL((wsp.ly_newly_vd_charge      * 1000),0)     ly_newly_vd_charge                 -- ��N����v��_�V�K�q�iVD�j�S���x�[�X
                ,NVL((wsp.ty_first_vd_charge      * 1000),0)     ty_first_vd_charge                 -- �{�N����v��_�V�K����iVD�j�S���x�[�X
                ,NVL((wsp.ty_turn_vd_charge       * 1000),0)     ty_turn_vd_charge                  -- �{�N����v��_�V�K��]�iVD�j�S���x�[�X
                ,NVL((wsp.ty_first_vd_get         * 1000),0)     ty_first_vd_get                    -- �{�N����v��_�V�K����iVD�j�l���x�[�X
                ,NVL((wsp.ty_turn_vd_get          * 1000),0)     ty_turn_vd_get                     -- �{�N����v��_�V�K��]�iVD�j�l���x�[�X
                ,NVL(wsp.st_mon_get_total                ,0)     st_mon_get_total                   -- �����ڋq���i�S�́j�l���x�[�X
                ,NVL(wsp.newly_get_total                 ,0)     newly_get_total                    -- �V�K�����i�S�́j�l���x�[�X
                ,NVL(wsp.cancel_get_total                ,0)     cancel_get_total                   -- ���~�����i�S�́j�l���x�[�X
                ,NVL(wsp.newly_charge_total              ,0)     newly_charge_total                 -- �V�K�����i�S�́j�S���x�[�X
                ,NVL(wsp.st_mon_get_vd                   ,0)     st_mon_get_vd                      -- �����ڋq���iVD�j�l���x�[�X
                ,NVL(wsp.newly_get_vd                    ,0)     newly_get_vd                       -- �V�K�����iVD�j�l���x�[�X
                ,NVL(wsp.cancel_get_vd                   ,0)     cancel_get_vd                      -- ���~�����iVD�j�l���x�[�X
                ,NVL(wsp.newly_charge_vd_own             ,0)     newly_charge_vd_own                -- ���͐V�K�����iVD�j�S���x�[�X
                ,NVL(wsp.newly_charge_vd_help            ,0)     newly_charge_vd_help               -- ���͐V�K�����iVD�j�S���x�[�X
                ,NVL(wsp.cancel_charge_vd                ,0)     cancel_charge_vd                   -- ���~�����iVD�j�S���x�[�X
                ,NVL(wsp.patrol_visit_cnt                ,0)     patrol_visit_cnt                   -- ����K��ڋq��
                ,NVL(wsp.patrol_def_visit_cnt            ,0)     patrol_def_visit_cnt               -- ���񉄖K�⌬��
                ,NVL(wsp.vendor_visit_cnt                ,0)     vendor_visit_cnt                   -- �x���_�[�K��ڋq��
                ,NVL(wsp.vendor_def_visit_cnt            ,0)     vendor_def_visit_cnt               -- �x���_�[���K�⌬��
                ,NVL(wsp.public_visit_cnt                ,0)     public_visit_cnt                   -- ��ʖK��ڋq��
                ,NVL(wsp.public_def_visit_cnt            ,0)     public_def_visit_cnt               -- ��ʉ��K�⌬��
                ,NVL(wsp.def_cnt_total                   ,0)     def_cnt_total                      -- ���K�⌬�����v
                ,NVL((wsp.vend_machine_sales_plan * 1000),0)     vend_machine_sales_plan            -- ���̋@����v��
                ,NVL((wsp.vend_machine_margin     * 1000),0)     vend_machine_margin                -- ���̋@�v��e���v
                ,NVL((wsp.vend_machine_bm         * 1000),0)     vend_machine_bm                    -- ���̋@�萔���iBM�j
                ,NVL((wsp.vend_machine_elect      * 1000),0)     vend_machine_elect                 -- ���̋@�萔���i�d�C��j
                ,NVL((wsp.vend_machine_lease      * 1000),0)     vend_machine_lease                 -- ���̋@���[�X��
                ,NVL((wsp.vend_machine_manage     * 1000),0)     vend_machine_manage                -- ���̋@�ێ��Ǘ���
                ,NVL((wsp.vend_machine_sup_money  * 1000),0)     vend_machine_sup_money             -- ���̋@�v�拦�^��
                ,NVL((wsp.vend_machine_total      * 1000),0)     vend_machine_total                 -- ���̋@�v���p���v
                ,NVL((wsp.vend_machine_profit     * 1000),0)     vend_machine_profit                -- ���_���̋@���v
                ,NVL(wsp.deficit_num                     ,0)     deficit_num                        -- �Ԏ��䐔
                ,NVL(wsp.par_machine                     ,0)     par_machine                        -- �p�[�}�V��
                ,NVL(wsp.possession_num                  ,0)     possession_num                     -- �ۗL�䐔
                ,NVL(wsp.stock_num                       ,0)     stock_num                          -- �݌ɑ䐔
                ,NVL(wsp.operation_num                   ,0)     operation_num                      -- �ғ��䐔
                ,NVL(wsp.increase                        ,0)     increase                           -- ����
                ,NVL(wsp.new_setting_own                 ,0)     new_setting_own                    -- �V�K�ݒu�䐔�i���́j
                ,NVL(wsp.new_setting_help                ,0)     new_setting_help                   -- �V�K�ݒu�䐔�i���́j
                ,NVL(wsp.new_setting_total               ,0)     new_setting_total                  -- �V�K�ݒu�䐔���v
                ,NVL(wsp.withdraw_num                    ,0)     withdraw_num                       -- �P�ƈ��g�䐔
                ,NVL(wsp.new_num_newly                   ,0)     new_num_newly                      -- �V��䐔�i�V�K�j
                ,NVL(wsp.new_num_replace                 ,0)     new_num_replace                    -- �V��䐔�i��ցj
                ,NVL(wsp.new_num_total                   ,0)     new_num_total                      -- �V��䐔���v
                ,NVL(wsp.old_num_newly                   ,0)     old_num_newly                      -- ����䐔�i�V�K�j
                ,NVL(wsp.old_num_replace                 ,0)     old_num_replace                    -- ����䐔�i��ցE�ڐ݁j
                ,NVL(wsp.disposal_num                    ,0)     disposal_num                       -- �p���䐔
                ,NVL(wsp.enter_num                       ,0)     enter_num                          -- ���_�Ԉړ��䐔
                ,NVL(wsp.appear_num                      ,0)     appear_num                         -- ���_�Ԉڏo�䐔
                ,NVL(wsp.vend_machine_plan_spare_1       ,0)     vend_machine_plan_spare_1          -- �����̔��@�v��i�\���P�j
                ,NVL(wsp.vend_machine_plan_spare_2       ,0)     vend_machine_plan_spare_2          -- �����̔��@�v��i�\���Q�j
                ,NVL(wsp.vend_machine_plan_spare_3       ,0)     vend_machine_plan_spare_3          -- �����̔��@�v��i�\���R�j
                ,NVL(wsp.spare_1                         ,0)     spare_1                            -- �\���P
                ,NVL(wsp.spare_2                         ,0)     spare_2                            -- �\���Q
                ,NVL(wsp.spare_3                         ,0)     spare_3                            -- �\���R
                ,NVL(wsp.spare_4                         ,0)     spare_4                            -- �\���S
                ,NVL(wsp.spare_5                         ,0)     spare_5                            -- �\���T
                ,NVL(wsp.spare_6                         ,0)     spare_6                            -- �\���U
                ,NVL(wsp.spare_7                         ,0)     spare_7                            -- �\���V
                ,NVL(wsp.spare_8                         ,0)     spare_8                            -- �\���W
                ,NVL(wsp.spare_9                         ,0)     spare_9                            -- �\���X
                ,NVL(wsp.spare_10                        ,0)     spare_10                           -- �\���P�O
      FROM      xxcsm_wk_sales_plan                       wsp                                       -- �̔��v�惏�[�N�e�[�u��
      ORDER BY  wsp.plan_year                             ASC                                       -- �\�Z�N��
               ,wsp.location_cd                           ASC                                       -- ���_�R�[�h
               ,wsp.plan_ym                               ASC;                                      -- �N��
--
    get_data_rec  get_data_cur%ROWTYPE;                                                             -- �N�Ԍv��f�[�^�擾 ���R�[�h�^
  BEGIN
--
    ov_retcode    := cv_status_normal;                                                              -- �ϐ��̏�����
--
    gn_normal_cnt := 0;                                                                             -- ���팏���̏�����
    gn_warn_cnt   := 0;                                                                             -- �X�L�b�v�����̏�����
    gn_counter    := 0;
    gv_check_flag := cv_chk_normal;
--
    OPEN get_data_cur;
    <<main_loop>>                                                                                   -- ���C������LOOP
    LOOP
      FETCH get_data_cur INTO get_data_rec;
      EXIT WHEN get_data_cur%NOTFOUND;                                                              -- �Ώۃf�[�^�����������J��Ԃ�
--
      IF ((get_data_cur%ROWCOUNT = 1)                                                               -- 1����
         OR (lv_plan_year <> get_data_rec.plan_year)                                                -- �\�Z�N�x�u���C�N��
         OR (lv_location_cd <> get_data_rec.location_cd)                                            -- ���_�R�[�h�u���C�N��
         OR (get_data_rec.plan_year IS NULL
             AND lv_plan_year IS NOT NULL)                                                          -- �N�x��NULL�ɑ�������
         OR (get_data_rec.location_cd IS NULL 
             AND lv_location_cd IS NOT NULL)) THEN                                                  -- ���_�R�[�h��NULL�ɑ�������
--
        IF (gv_check_flag = cv_chk_normal)THEN                                                      -- �`�F�b�N�t���O���i���� = 0)�̏ꍇ
          gn_normal_cnt := (gn_normal_cnt + gn_counter);                                            -- ���폈�����������Z
        ELSIF (gv_check_flag = cv_chk_warning) THEN                                                 -- �`�F�b�N�t���O���i�G���[ = 1)�̏ꍇ
          gn_error_cnt := (gn_error_cnt + gn_counter);                                              -- �X�L�b�v���������Z
        END IF;
--
        gv_check_flag  := cv_chk_normal;                                                            -- �`�F�b�N�t���O�̏�����
        gn_counter := 0;                                                                            -- ����������������
--
    --==============================================================
    -- A-4 �Z�[�u�|�C���g�̐ݒ�
    --==============================================================
--
        SAVEPOINT check_warning;                                                                    -- �Z�[�u�|�C���g�̐ݒ�
--
        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- �`�F�b�N�t���O��(����=0)�̏ꍇ
          check_location(                                                                           -- check_location���R�[��
             iv_plan_year   => get_data_rec.plan_year                                               -- �\�Z�N�x
            ,iv_location_cd => get_data_rec.location_cd                                             -- ���_�R�[�h
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
            );
--
          IF (lv_retcode = cv_status_error) THEN                                                    -- �߂�l���G���[�̏ꍇ
            RAISE sub_proc_other_expt;
          END IF;
--
          IF (lv_retcode = cv_status_warn) THEN                                                     -- �߂�l���x���̏ꍇ
            gv_warnig_flg := cv_status_warn;
            ROLLBACK TO check_warning;                                                              -- �Z�[�u�|�C���g�փ��[���o�b�N
          END IF;
        END IF;
      END IF;
      lv_location_cd := get_data_rec.location_cd;                                                   -- ���_�R�[�h��ϐ��ɕێ�
      lv_plan_year   := get_data_rec.plan_year;                                                     -- �\�Z�N�x��ϐ��ɕێ�
--
      IF (gv_check_flag = cv_chk_normal) THEN                                                       -- �`�F�b�N�t���O��(����=0)�̏ꍇ
        lr_plan_rec.plan_year                 := get_data_rec.plan_year;                            -- �\�Z�N�x
        lr_plan_rec.plan_ym                   := get_data_rec.plan_ym;                              -- �N��
        lr_plan_rec.location_cd               := get_data_rec.location_cd;                          -- ���_�R�[�h
        lr_plan_rec.act_work_date             := get_data_rec.act_work_date;                        -- ������
        lr_plan_rec.plan_staff                := get_data_rec.plan_staff;                           -- �v��l��
        lr_plan_rec.sale_plan_depart          := get_data_rec.sale_plan_depart;                     -- �ʔ̓X����v��
        lr_plan_rec.sale_plan_cvs             := get_data_rec.sale_plan_cvs;                        -- CVS����v��
        lr_plan_rec.sale_plan_dealer          := get_data_rec.sale_plan_dealer;                     -- �≮����v��
        lr_plan_rec.sale_plan_vendor          := get_data_rec.sale_plan_vendor;                     -- �x���_�[����v��
        lr_plan_rec.sale_plan_others          := get_data_rec.sale_plan_others;                     -- ���̑�����v��
        lr_plan_rec.sale_plan_total           := get_data_rec.sale_plan_total;                      -- ����v�捇�v
        lr_plan_rec.sale_plan_spare_1         := get_data_rec.sale_plan_spare_1;                    -- �Ƒԕʔ���v��i�\���P�j
        lr_plan_rec.sale_plan_spare_2         := get_data_rec.sale_plan_spare_2;                    -- �Ƒԕʔ���v��i�\���Q�j
        lr_plan_rec.sale_plan_spare_3         := get_data_rec.sale_plan_spare_3;                    -- �Ƒԕʔ���v��i�\���R�j
        lr_plan_rec.ly_revision_depart        := get_data_rec.ly_revision_depart;                   -- �O�N���яC���i�ʔ̓X�j
        lr_plan_rec.ly_revision_cvs           := get_data_rec.ly_revision_cvs;                      -- �O�N���яC���iCVS�j
        lr_plan_rec.ly_revision_dealer        := get_data_rec.ly_revision_dealer;                   -- �O�N���яC���i�≮�j
        lr_plan_rec.ly_revision_others        := get_data_rec.ly_revision_others;                   -- �O�N���яC���i���̑��j
        lr_plan_rec.ly_revision_vendor        := get_data_rec.ly_revision_vendor;                   -- �O�N���яC���i�x���_�[�j
        lr_plan_rec.ly_revision_spare_1       := get_data_rec.ly_revision_spare_1;                  -- �O�N���яC���i�\���P�j
        lr_plan_rec.ly_revision_spare_2       := get_data_rec.ly_revision_spare_2;                  -- �O�N���яC���i�\���Q�j
        lr_plan_rec.ly_revision_spare_3       := get_data_rec.ly_revision_spare_3;                  -- �O�N���яC���i�\���R�j
        lr_plan_rec.ly_exist_total            := get_data_rec.ly_exist_total;                       -- ��N����v��_�����q�i�S�́j
        lr_plan_rec.ly_newly_total            := get_data_rec.ly_newly_total;                       -- ��N����v��_�V�K�q�i�S�́j
        lr_plan_rec.ty_first_total            := get_data_rec.ty_first_total;                       -- �{�N����v��_�V�K����i�S�́j
        lr_plan_rec.ty_turn_total             := get_data_rec.ty_turn_total;                        -- �{�N����v��_�V�K��]�i�S�́j
        lr_plan_rec.discount_total            := get_data_rec.discount_total;                       -- �����l���i�S�́j
        lr_plan_rec.ly_exist_vd_charge        := get_data_rec.ly_exist_vd_charge;                   -- ��N����v��_�����q�iVD�j�S��
        lr_plan_rec.ly_newly_vd_charge        := get_data_rec.ly_newly_vd_charge;                   -- ��N����v��_�V�K�q�iVD�j�S��
        lr_plan_rec.ty_first_vd_charge        := get_data_rec.ty_first_vd_charge;                   -- �{�N����v��_�V�K����iVD�j�S��
        lr_plan_rec.ty_turn_vd_charge         := get_data_rec.ty_turn_vd_charge;                    -- �{�N����v��_�V�K��]�iVD�j�S��
        lr_plan_rec.ty_first_vd_get           := get_data_rec.ty_first_vd_get;                      -- �{�N����v��_�V�K����iVD�j�l��
        lr_plan_rec.ty_turn_vd_get            := get_data_rec.ty_turn_vd_get;                       -- �{�N����v��_�V�K��]�iVD�j�l��
        lr_plan_rec.st_mon_get_total          := get_data_rec.st_mon_get_total;                     -- �����ڋq���i�S�́j�l���x�[�X
        lr_plan_rec.newly_get_total           := get_data_rec.newly_get_total;                      -- �V�K�����i�S�́j�l���x�[�X
        lr_plan_rec.cancel_get_total          := get_data_rec.cancel_get_total;                     -- ���~�����i�S�́j�l���x�[�X
        lr_plan_rec.newly_charge_total        := get_data_rec.newly_charge_total;                   -- �V�K�����i�S�́j�S���x�[�X
        lr_plan_rec.st_mon_get_vd             := get_data_rec.st_mon_get_vd;                        -- �����ڋq���iVD�j�l���x�[�X
        lr_plan_rec.newly_get_vd              := get_data_rec.newly_get_vd;                         -- �V�K�����iVD�j�l���x�[�X
        lr_plan_rec.cancel_get_vd             := get_data_rec.cancel_get_vd;                        -- ���~�����iVD�j�l���x�[�X
        lr_plan_rec.newly_charge_vd_own       := get_data_rec.newly_charge_vd_own;                  -- ���͐V�K�����iVD�j�S���x�[�X
        lr_plan_rec.newly_charge_vd_help      := get_data_rec.newly_charge_vd_help;                 -- ���͐V�K�����iVD�j�S���x�[�X
        lr_plan_rec.cancel_charge_vd          := get_data_rec.cancel_charge_vd;                     -- ���~�����iVD�j�S���x�[�X
        lr_plan_rec.patrol_visit_cnt          := get_data_rec.patrol_visit_cnt;                     -- ����K��ڋq��
        lr_plan_rec.patrol_def_visit_cnt      := get_data_rec.patrol_def_visit_cnt;                 -- ���񉄖K�⌬��
        lr_plan_rec.vendor_visit_cnt          := get_data_rec.vendor_visit_cnt;                     -- �x���_�[�K��ڋq��
        lr_plan_rec.vendor_def_visit_cnt      := get_data_rec.vendor_def_visit_cnt;                 -- �x���_�[���K�⌬��
        lr_plan_rec.public_visit_cnt          := get_data_rec.public_visit_cnt;                     -- ��ʖK��ڋq��
        lr_plan_rec.public_def_visit_cnt      := get_data_rec.public_def_visit_cnt;                 -- ��ʉ��K�⌬��
        lr_plan_rec.def_cnt_total             := get_data_rec.def_cnt_total;                        -- ���K�⌬�����v
        lr_plan_rec.vend_machine_sales_plan   := get_data_rec.vend_machine_sales_plan;              -- ���̋@����v��
        lr_plan_rec.vend_machine_margin       := get_data_rec.vend_machine_margin;                  -- ���̋@�v��e���v
        lr_plan_rec.vend_machine_bm           := get_data_rec.vend_machine_bm;                      -- ���̋@�萔���iBM�j
        lr_plan_rec.vend_machine_elect        := get_data_rec.vend_machine_elect;                   -- ���̋@�萔���i�d�C��j
        lr_plan_rec.vend_machine_lease        := get_data_rec.vend_machine_lease;                   -- ���̋@���[�X��
        lr_plan_rec.vend_machine_manage       := get_data_rec.vend_machine_manage;                  -- ���̋@�ێ��Ǘ���
        lr_plan_rec.vend_machine_sup_money    := get_data_rec.vend_machine_sup_money;               -- ���̋@�v�拦�^��
        lr_plan_rec.vend_machine_total        := get_data_rec.vend_machine_total;                   -- ���̋@�v���p���v
        lr_plan_rec.vend_machine_profit       := get_data_rec.vend_machine_profit;                  -- ���_���̋@���v
        lr_plan_rec.deficit_num               := get_data_rec.deficit_num;                          -- �Ԏ��䐔
        lr_plan_rec.par_machine               := get_data_rec.par_machine;                          -- �p�[�}�V��
        lr_plan_rec.possession_num            := get_data_rec.possession_num;                       -- �ۗL�䐔
        lr_plan_rec.stock_num                 := get_data_rec.stock_num;                            -- �݌ɑ䐔
        lr_plan_rec.operation_num             := get_data_rec.operation_num;                        -- �ғ��䐔
        lr_plan_rec.increase                  := get_data_rec.increase;                             -- ����
        lr_plan_rec.new_setting_own           := get_data_rec.new_setting_own;                      -- �V�K�ݒu�䐔�i���́j
        lr_plan_rec.new_setting_help          := get_data_rec.new_setting_help;                     -- �V�K�ݒu�䐔�i���́j
        lr_plan_rec.new_setting_total         := get_data_rec.new_setting_total;                    -- �V�K�ݒu�䐔���v
        lr_plan_rec.withdraw_num              := get_data_rec.withdraw_num;                         -- �P�ƈ��g�䐔
        lr_plan_rec.new_num_newly             := get_data_rec.new_num_newly;                        -- �V��䐔�i�V�K�j
        lr_plan_rec.new_num_replace           := get_data_rec.new_num_replace;                      -- �V��䐔�i��ցj
        lr_plan_rec.new_num_total             := get_data_rec.new_num_total;                        -- �V��䐔���v
        lr_plan_rec.old_num_newly             := get_data_rec.old_num_newly;                        -- ����䐔�i�V�K�j
        lr_plan_rec.old_num_replace           := get_data_rec.old_num_replace;                      -- ����䐔�i��ցE�ڐ݁j
        lr_plan_rec.disposal_num              := get_data_rec.disposal_num;                         -- �p���䐔
        lr_plan_rec.enter_num                 := get_data_rec.enter_num;                            -- ���_�Ԉړ��䐔
        lr_plan_rec.appear_num                := get_data_rec.appear_num;                           -- ���_�Ԉڏo�䐔
        lr_plan_rec.vend_machine_plan_spare_1 := get_data_rec.vend_machine_plan_spare_1;            -- �����̔��@�v��i�\���P�j
        lr_plan_rec.vend_machine_plan_spare_2 := get_data_rec.vend_machine_plan_spare_2;            -- �����̔��@�v��i�\���Q�j
        lr_plan_rec.vend_machine_plan_spare_3 := get_data_rec.vend_machine_plan_spare_3;            -- �����̔��@�v��i�\���R�j
        lr_plan_rec.spare_1                   := get_data_rec.spare_1;                              -- �\���P
        lr_plan_rec.spare_2                   := get_data_rec.spare_2;                              -- �\���Q
        lr_plan_rec.spare_3                   := get_data_rec.spare_3;                              -- �\���R
        lr_plan_rec.spare_4                   := get_data_rec.spare_4;                              -- �\���S
        lr_plan_rec.spare_5                   := get_data_rec.spare_5;                              -- �\���T
        lr_plan_rec.spare_6                   := get_data_rec.spare_6;                              -- �\���U
        lr_plan_rec.spare_7                   := get_data_rec.spare_7;                              -- �\���V
        lr_plan_rec.spare_8                   := get_data_rec.spare_8;                              -- �\���W
        lr_plan_rec.spare_9                   := get_data_rec.spare_9;                              -- �\���X
        lr_plan_rec.spare_10                  := get_data_rec.spare_10;                             -- �\���P�O
--
        check_item(                                                                                 -- check_item���R�[��
           ir_plan_rec => lr_plan_rec
          ,ov_errbuf   => lv_errbuf
          ,ov_retcode  => lv_retcode
          ,ov_errmsg   => lv_errmsg
          );
--
        IF (lv_retcode = cv_status_error) THEN                                                      -- �߂�l���G���[�̏ꍇ
          RAISE sub_proc_other_expt;
        END IF;
--
        IF (lv_retcode = cv_status_warn) THEN                                                       -- �߂�l���x���̏ꍇ
          gv_warnig_flg := cv_status_warn;
          ROLLBACK TO check_warning;                                                                -- �Z�[�u�|�C���g�փ��[���o�b�N
        END IF;
--
        IF (gv_check_flag = cv_chk_normal) THEN                                                     -- �`�F�b�N�t���O��(����=0)�̏ꍇ
          insert_data(                                                                              -- insert_data���R�[��
            ir_plan_rec => lr_plan_rec
           ,ov_errbuf   => lv_errbuf
           ,ov_retcode  => lv_retcode
           ,ov_errmsg   => lv_errmsg
           );
--
          IF (lv_retcode = cv_status_error) THEN                                                    -- �߂�l���G���[�̏ꍇ
            RAISE sub_proc_other_expt;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
    IF (gv_check_flag = cv_chk_normal)THEN                                                          -- �`�F�b�N�t���O���i���� = 0)�̏ꍇ
      gn_normal_cnt := (gn_normal_cnt + gn_counter);                                                -- ���폈�����������Z
    ELSIF (gv_check_flag = cv_chk_warning) THEN                                                     -- �`�F�b�N�t���O���i�G���[ = 1)�̏ꍇ
      gn_error_cnt := (gn_error_cnt + gn_counter);                                                  -- �X�L�b�v���������Z
    END IF;
--
    CLOSE  get_data_cur;
--
    IF (gn_error_cnt >= 1) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_other_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode    := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_data_cur%ISOPEN) THEN
        CLOSE get_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : final
   * Description      : �I������ (A-8)
   ***********************************************************************************/
  PROCEDURE final(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'final';                                                -- �v���O������
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
      --==============================================================
      --  A-8    �̔��v�惏�[�N�e�[�u���f�[�^�폜
      --==============================================================
--
    DELETE  FROM    xxcsm_wk_sales_plan;                                                            -- �̔��v�惏�[�N�e�[�u��
--
      --==============================================================
      --  A-8    �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
      --==============================================================
--
    DELETE  FROM    xxccp_mrp_file_ul_interface  fui                                                -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE   fui.file_id = gn_file_id;                                                               -- �t�@�C��ID
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END final;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT NOCOPY VARCHAR2)                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                                              -- �v���O������
    lv_errbuf     VARCHAR2(4000);                                                                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);                                                                      -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(4000);                                                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;                                                                 -- ���^�[���R�[�h��������
--
    gn_target_cnt := 0;                                                                             -- �����J�E���^�̏�����
    gn_normal_cnt := 0;                                                                             -- �����J�E���^�̏�����
    gn_error_cnt  := 0;                                                                             -- �����J�E���^�̏�����
    gn_warn_cnt   := 0;                                                                             -- �����J�E���^�̏�����
--
    init(                                                                                           -- init���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    get_if_data(                                                                                    -- get_if_data���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    loop_main(                                                                                      -- loop_main���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ȏ�̏ꍇ
      RAISE global_process_expt;
    END IF;
--
    final(                                                                                          -- final���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN                                                          -- �߂�l���ُ�̏ꍇ
      RAISE global_process_expt;
    END IF;
    ov_retcode := lv_retcode;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2                                                               -- �G���[�E���b�Z�[�W
   ,retcode       OUT NOCOPY VARCHAR2                                                               -- ���^�[���E�R�[�h
   ,iv_file_id    IN         VARCHAR2                                                               -- �t�@�C��ID
   ,iv_format     IN         VARCHAR2                                                               -- �t�H�[�}�b�g�p�^�[��
    )
--
  IS
--
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- �G���[�I���S���[���o�b�N
--
    lv_errbuf          VARCHAR2(4000);                                                              -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                                                 -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);                                                              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                                               -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
    xxccp_common_pkg.put_log_header(                                                                -- �w�b�_�[���̏o��
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    gn_file_id := TO_NUMBER(iv_file_id);                                                            -- IN�p�����[�^���i�[
    gv_format  := iv_format;                                                                        -- IN�p�����[�^���i�[
--
    submain(                                                                                        -- submain���R�[��
       lv_errbuf                                                                                    -- �G���[�E���b�Z�[�W
      ,lv_retcode                                                                                   -- ���^�[���E�R�[�h
      ,lv_errmsg                                                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm
                      ,iv_name         => cv_msg_00111
                     );
      END IF;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- ��s�̑}��
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    IF (gv_warnig_flg = cv_status_warn
      AND lv_retcode = cv_status_normal) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''                                                                                 -- ��s�̑}��
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
    fnd_file.put_line(
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
END XXCSM001A02C;
/
