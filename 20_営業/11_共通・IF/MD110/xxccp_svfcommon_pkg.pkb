CREATE OR REPLACE PACKAGE BODY apps.xxccp_svfcommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_svfcommon_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.6
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  submit_svf_request        P           SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
 *  no_data_msg               F     CHAR  SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-11-11    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009-01-15    1.1  T.matsumoto
 *  2009-03-05    1.2  Masayuki.Sano    [submit_svf_request]��O���̃��[���o�b�N�폜
 *  2009-03-06    1.3  Masayuki.Sano    �\�[�g��������s���Ή�
 *  2009-03-23    1.4  Shinya.Kayahara  �ŏI�s�ɃX���b�V���ǉ�
 *  2009-04-08    1.5  Masayuki.Sano    �\�[�g��������s���Ή�
 *  2009-05-01    1.6  Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;          -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;            -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;           -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER         := fnd_global.user_id;                          -- CREATED_BY
  cd_creation_date          CONSTANT DATE           := SYSDATE;                                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER         := fnd_global.user_id;                          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE           := SYSDATE;                                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER         := fnd_global.login_id;                         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := fnd_global.conc_request_id;                  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := fnd_global.prog_appl_id;                     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := fnd_global.conc_program_id;                  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE           := SYSDATE;                                     -- PROGRAM_UPDATE_DATE
  -- �L��
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
  cv_msg_sq                 CONSTANT VARCHAR2(3)    := '''';
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�p�b�P�[�W���O���[�o���萔
  -- ===============================
  -- ���̑�
  cb_NULL                   CONSTANT BOOLEAN        := NULL;
  cb_FALSE                  CONSTANT BOOLEAN        := FALSE;
  cb_TURE                   CONSTANT BOOLEAN        := TRUE;
  cv_log_mode               CONSTANT VARCHAR2(30)   := 'LOG';                                       -- �o�̓��[�h�F���O�o��
  cv_output_mode            CONSTANT VARCHAR2(30)   := 'OUTPUT';                                    -- �o�̓��[�h�F��ʏo��
  cv_part_bs                CONSTANT VARCHAR2(3)    := '\\';                                        -- �E�B���h�E�Y�̃f�B���N�g���K�w��\\�ŕ\�L
  cv_part_sl                CONSTANT VARCHAR2(3)    := '/';                                         -- Linux�̃f�B���N�g���K�w��/�ŕ\�L
  cv_pkg_name               CONSTANT VARCHAR2(30)   := 'xxccp_svfcommon_pkg';                       -- PKG��
  cv_applcation_xxccp       CONSTANT VARCHAR2(30)   := 'XXCCP';                                     -- �A�v���P�[�V�����Z�k��
  cv_pdf_dir                CONSTANT VARCHAR2(30)   := 'PDF';                                       -- PDF�t�@�C���i�[�f�B���N�g��
  cv_form_dir               CONSTANT VARCHAR2(30)   := 'Form';                                      -- �t�H�[���l���t�@�C���i�[�f�B���N�g��
  cv_query_dir              CONSTANT VARCHAR2(30)   := 'Query';                                     -- �N�G���l���t�@�C���i�[�f�B���N�g��
--
--  �v���t�F�[�Y�Ɨv���X�e�[�^�X�萔
  cv_phase_comp             CONSTANT VARCHAR2(30)   := 'COMPLETE';                                  -- �v���t�F�[�Y�F����
  cv_status_nomal           CONSTANT VARCHAR2(30)   := 'NORMAL';                                    -- �v���X�e�[�^�X�F����
--
  -- ===============================
  -- ���b�Z�[�W�֘A�萔
  -- ===============================
  -- �G���[���b�Z�[�W�p���b�Z�[�WID
  cv_err_prm_unjust       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10015';                            -- �p�����[�^�l�s��
  cv_err_prm_required     CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10004';                            -- �p�����[�^�K�{�G���[
  cv_err_prm_length       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10006';                            -- �p�����[�^���G���[
  cv_err_date_accession   CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10112';                            -- �f�[�^�擾�G���[
  cv_err_exec_conc        CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10026';                            -- �R���J�����g�X�e�[�^�X�ُ�I��
  cv_err_prog_start       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91001';                            -- �Ώ�Prog�N���G���[
  cv_err_process          CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91005';                            -- �Ώۏ����G���[
  cv_err_get_profile      CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10032';                            -- �v���t�@�C���擾�G���[
  cv_err_end              CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-10003';                            -- �ُ�I�����b�Z�[�W
  --
  --��񃍃O�p���b�Z�[�WID
  cv_info_appl_name       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00002';                            -- �N���ΏۃA�v���P�[�V�����Z�k���\��
  cv_info_conc_name       CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00003';                            -- �N���ΏۃR���J�����g�Z�k���\��
  cv_info_prm             CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00005';                            -- �p�����[�^�\��
  cv_info_request_end     CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-00007';                            -- �v���̐���I�����\��
  cv_info_request_start   CONSTANT VARCHAR2(30)   := 'APP-XXCCP1-91002';                            -- �v���̐���ȊJ�n��\��
  --
  --���b�Z�[�W�g�[�N��
  cv_token_item           CONSTANT VARCHAR2(30)   := 'ITEM';
  cv_token_value          CONSTANT VARCHAR2(30)   := 'VALUE';
  cv_token_number         CONSTANT VARCHAR2(30)   := 'NUMBER';
  cv_token_prmval         CONSTANT VARCHAR2(30)   := 'PARAM_VALUE';
  cv_token_appl_name      CONSTANT VARCHAR2(30)   := 'AP_SHORT_NAME';
  cv_token_conc_name      CONSTANT VARCHAR2(30)   := 'CONC_SHORT_NAME';
  cv_token_req_id         CONSTANT VARCHAR2(30)   := 'REQ_ID';
  cv_token_phase          CONSTANT VARCHAR2(30)   := 'PHASE';
  cv_token_staus          CONSTANT VARCHAR2(30)   := 'STATUS';
  cv_token_proc           CONSTANT VARCHAR2(30)   := 'PROCESS';
  cv_token_prog           CONSTANT VARCHAR2(30)   := 'PROGRAM';
  cv_token_id             CONSTANT VARCHAR2(30)   := 'ID';
  cv_token_prof_name      CONSTANT VARCHAR2(30)   := 'PROFILE_NAME';
--
--  ���b�Z�[�W�g�[�N���l�p�萔(IN�p�����[�^�֘A)
  cv_token_v_prm01        CONSTANT VARCHAR2(50)   := '�R���J�����g��';
  cv_token_v_prm02        CONSTANT VARCHAR2(50)   := '�o�̓t�@�C����';
  cv_token_v_prm03        CONSTANT VARCHAR2(50)   := '���[ID';
  cv_token_v_prm04        CONSTANT VARCHAR2(50)   := '�o�͋敪';
  cv_token_v_prm05        CONSTANT VARCHAR2(50)   := '�t�H�[���l���t�@�C����';
  cv_token_v_prm06        CONSTANT VARCHAR2(50)   := '�N�G���[�l���t�@�C����';
  cv_token_v_prm07        CONSTANT VARCHAR2(50)   := 'ORG_ID';
  cv_token_v_prm08        CONSTANT VARCHAR2(50)   := '���O�C���E���[�U��';
  cv_token_v_prm09        CONSTANT VARCHAR2(50)   := '���O�C���E���[�U�̐E��';
  cv_token_v_prm10        CONSTANT VARCHAR2(50)   := '������';
  cv_token_v_prm11        CONSTANT VARCHAR2(50)   := '�v�����^��';
  cv_token_v_prm12        CONSTANT VARCHAR2(50)   := '�v��ID';
  cv_token_v_prm13        CONSTANT VARCHAR2(50)   := '�f�[�^�Ȃ����b�Z�[�W';
  cv_token_v_prm14        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^01';
  cv_token_v_prm15        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^02';
  cv_token_v_prm16        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^03';
  cv_token_v_prm17        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^04';
  cv_token_v_prm18        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^05';
  cv_token_v_prm19        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^06';
  cv_token_v_prm20        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^07';
  cv_token_v_prm21        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^08';
  cv_token_v_prm22        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^09';
  cv_token_v_prm23        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^10';
  cv_token_v_prm24        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^11';
  cv_token_v_prm25        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^12';
  cv_token_v_prm26        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^13';
  cv_token_v_prm27        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^14';
  cv_token_v_prm28        CONSTANT VARCHAR2(50)   := 'svf�σp�����[�^15';
--
--  ���b�Z�[�W�g�[�N���l�p�萔(DB�擾���ڊ֘A)
  cv_token_v_db_val_of    CONSTANT VARCHAR2(50)   := 'OUTFILE_PATH';
--
--  ���b�Z�[�W�g�[�N���l�p�萔(���̑�)
  cv_token_v_svf_conc     CONSTANT VARCHAR2(50)   := 'SVF�R���J�����g';
  cv_token_v_wait_ftp     CONSTANT VARCHAR2(50)   := 'SVF�R���J�����g�I���҂�����';
  cv_token_v_ftp_conc     CONSTANT VARCHAR2(50)   := '�t�@�C���]���R���J�����g';
  cv_token_v_wait_svf     CONSTANT VARCHAR2(50)   := '�t�@�C���]���R���J�����g�I���҂�����';
--
--  ���̑��̃��b�Z�[�W�p
  cv_msg_part_mb          CONSTANT VARCHAR2(4)    := '�F  ';
  cv_plofile_msg          CONSTANT VARCHAR2(30)   := '�v���t�@�C�� ';
  cv_outpath_msg          CONSTANT VARCHAR2(30)   := '�o��PDF�p�X  ';
  cv_add_cond_msg         CONSTANT VARCHAR2(30)   := '������ݒ�   ';                               -- TEST�����ʕ\���p���b�Z�[�W
--
--  ���̑�
-- 
  cn_chk_svfprm_len       CONSTANT NUMBER := 230 ;                                                  -- SVF�σp�����[�^�`�F�b�N���̍ő啶����
  -- ===============================
  -- ���[�U�[��`�p�b�P�[�W���O���[�o���^
  -- ===============================
--
  -- �R���J�����g�N���p�p�����[�^�ϐ�
  TYPE  gt_conc_argument IS RECORD(
      appl                  VARCHAR2(4000)  DEFAULT   NULL,                                         -- �A�v���P�[�V�����̒Z�k��
      prog                  VARCHAR2(4000)  DEFAULT   NULL,                                         -- �R���J�����g�E�v���O�����̒Z�k��
      descr                 VARCHAR2(4000)  DEFAULT   NULL,                                         --�u�R���J�����g�v���v�t�H�[���ɕ\�������v���̐���
      startt                VARCHAR2(4000)  DEFAULT   NULL,                                         -- �v���̎��s���J�n���鎞��
      sub                   BOOLEAN         DEFAULT   FALSE,                                        -- �T�u�v���Ƃ��Ĉ�����ꍇ��TRUE
      arg001                VARCHAR2(4000)  DEFAULT   CHR(0),                                       -- 000 - 100 �R���J�����g�v���̈���
      arg002                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg003                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg004                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg005                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg006                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg007                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg008                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg009                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg010                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg011                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg012                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg013                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg014                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg015                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg016                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg017                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg018                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg019                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg020                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg021                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg022                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg023                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg024                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg025                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg026                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg027                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg028                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg029                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg030                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg031                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg032                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg033                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg034                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg035                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg036                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg037                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg038                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg039                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg040                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg041                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg042                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg043                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg044                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg045                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg046                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg047                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg048                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg049                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg050                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg051                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg052                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg053                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg054                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg055                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg056                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg057                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg058                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg059                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg060                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg061                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg062                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg063                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg064                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg065                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg066                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg067                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg068                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg069                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg070                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg071                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg072                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg073                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg074                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg075                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg076                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg077                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg078                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg079                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg080                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg081                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg082                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg083                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg084                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg085                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg086                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg087                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg088                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg089                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg090                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg091                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg092                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg093                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg094                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg095                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg096                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg097                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg098                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg099                VARCHAR2(4000)  DEFAULT   CHR(0),
      arg100                VARCHAR2(4000)  DEFAULT   CHR(0)
    );
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Private Function
   * Function  Name   :output_log
   * Description      :���b�Z�[�W�̎擾��LOG�o�͂𓯎��ɍs���v���V�[�W��
   * PARAMETERS       :xxccp_common_pkg.get_msg�Ɠ���
   ***********************************************************************************/
  PROCEDURE output_log(   iv_appl             IN VARCHAR2 DEFAULT NULL,
                          iv_name             IN VARCHAR2 DEFAULT NULL,
                          iv_token_01         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val01      IN VARCHAR2 DEFAULT NULL,
                          iv_token_02         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val02      IN VARCHAR2 DEFAULT NULL,
                          iv_token_03         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val03      IN VARCHAR2 DEFAULT NULL,
                          iv_token_04         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val04      IN VARCHAR2 DEFAULT NULL,
                          iv_token_05         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val05      IN VARCHAR2 DEFAULT NULL,
                          iv_token_06         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val06      IN VARCHAR2 DEFAULT NULL,
                          iv_token_07         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val07      IN VARCHAR2 DEFAULT NULL,
                          iv_token_08         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val08      IN VARCHAR2 DEFAULT NULL,
                          iv_token_09         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val09      IN VARCHAR2 DEFAULT NULL,
                          iv_token_10         IN VARCHAR2 DEFAULT NULL,
                          iv_token_val10      IN VARCHAR2 DEFAULT NULL
                          )
  IS
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'output_log';
    lv_output_msg           VARCHAR2(4000) := NULL;                                                 -- �擾���b�Z�[�W�i�[�ϐ�
  BEGIN
    -- ���b�Z�[�W�̎擾
    lv_output_msg := xxccp_common_pkg.get_msg(
      iv_application    =>  iv_appl           ,                                                     --�A�v���P�[�V�����Z�k��
      iv_name           =>  iv_name           ,                                                     --���b�Z�[�W�R�[�h
      iv_token_name1    =>  iv_token_01       ,                                                     --�g�[�N���R�[�h1
      iv_token_value1   =>  iv_token_val01    ,                                                     --�g�[�N���l1
      iv_token_name2    =>  iv_token_02       ,                                                     --�g�[�N���R�[�h2
      iv_token_value2   =>  iv_token_val02    ,                                                     --�g�[�N���l2
      iv_token_name3    =>  iv_token_03       ,                                                     --�g�[�N���R�[�h3
      iv_token_value3   =>  iv_token_val03    ,                                                     --�g�[�N���l4
      iv_token_name4    =>  iv_token_04       ,                                                     --�g�[�N���R�[�h4
      iv_token_value4   =>  iv_token_val04    ,                                                     --�g�[�N���l4
      iv_token_name5    =>  iv_token_05       ,                                                     --�g�[�N���R�[�h5
      iv_token_value5   =>  iv_token_val05    ,                                                     --�g�[�N���l5
      iv_token_name6    =>  iv_token_06       ,                                                     --�g�[�N���R�[�h6
      iv_token_value6   =>  iv_token_val06    ,                                                     --�g�[�N���l6
      iv_token_name7    =>  iv_token_07       ,                                                     --�g�[�N���R�[�h7
      iv_token_value7   =>  iv_token_val07    ,                                                     --�g�[�N���l7
      iv_token_name8    =>  iv_token_08       ,                                                     --�g�[�N���R�[�h8
      iv_token_value8   =>  iv_token_val08    ,                                                     --�g�[�N���l8
      iv_token_name9    =>  iv_token_09       ,                                                     --�g�[�N���R�[�h9
      iv_token_value9   =>  iv_token_val09    ,                                                     --�g�[�N���l9
      iv_token_name10   =>  iv_token_10       ,                                                     --�g�[�N���R�[�h10
      iv_token_value10  =>  iv_token_val10                                                          --�g�[�N���l10
    );
    -- �G���[���b�Z�[�W�̃��O�ւ̏o��
    FND_FILE.PUT_LINE(
       which            => FND_FILE.LOG,                                                            -- LOG�o��
       buff             => lv_output_msg                                                            -- �o�͓��e
    );
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
    --
  END output_log;
--
--
  /**********************************************************************************
   * Private Function
   * Function  Name   : start_request
   * Description      : FND_REQUEST.submit_request�̋N��
   * PARAMETER        : �R���J�����g�̋N������
   * RETURN           : �v��ID
   ***********************************************************************************/
  FUNCTION start_request (it_conc_argument     IN OUT gt_conc_argument
                          )
    RETURN NUMBER
  IS
  --
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cl_error                CONSTANT NUMBER := 0 ;                                                  -- �G���[���̏o�͓��e
  --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_reqid                NUMBER := NULL ;                                                        -- �R���J�����g�N�����̕Ԃ�l(�v��ID)/�G���[����0���A���Ă���
    --
  BEGIN
  --
--##################  �W���@�\�̃R���J�����g�N���p�b�P�[�W�Ăяo�� START   ###################
    ln_reqid := FND_REQUEST.SUBMIT_REQUEST(
        application         =>  it_conc_argument.appl,
        program             =>  it_conc_argument.prog,
        description         =>  it_conc_argument.descr,
        start_time          =>  it_conc_argument.startt,
        sub_request         =>  it_conc_argument.sub,
        argument1           =>  it_conc_argument.arg001,
        argument2           =>  it_conc_argument.arg002,
        argument3           =>  it_conc_argument.arg003,
        argument4           =>  it_conc_argument.arg004,
        argument5           =>  it_conc_argument.arg005,
        argument6           =>  it_conc_argument.arg006,
        argument7           =>  it_conc_argument.arg007,
        argument8           =>  it_conc_argument.arg008,
        argument9           =>  it_conc_argument.arg009,
        argument10          =>  it_conc_argument.arg010,
        argument11          =>  it_conc_argument.arg011,
        argument12          =>  it_conc_argument.arg012,
        argument13          =>  it_conc_argument.arg013,
        argument14          =>  it_conc_argument.arg014,
        argument15          =>  it_conc_argument.arg015,
        argument16          =>  it_conc_argument.arg016,
        argument17          =>  it_conc_argument.arg017,
        argument18          =>  it_conc_argument.arg018,
        argument19          =>  it_conc_argument.arg019,
        argument20          =>  it_conc_argument.arg020,
        argument21          =>  it_conc_argument.arg021,
        argument22          =>  it_conc_argument.arg022,
        argument23          =>  it_conc_argument.arg023,
        argument24          =>  it_conc_argument.arg024,
        argument25          =>  it_conc_argument.arg025,
        argument26          =>  it_conc_argument.arg026,
        argument27          =>  it_conc_argument.arg027,
        argument28          =>  it_conc_argument.arg028,
        argument29          =>  it_conc_argument.arg029,
        argument30          =>  it_conc_argument.arg030,
        argument31          =>  it_conc_argument.arg031,
        argument32          =>  it_conc_argument.arg032,
        argument33          =>  it_conc_argument.arg033,
        argument34          =>  it_conc_argument.arg034,
        argument35          =>  it_conc_argument.arg035,
        argument36          =>  it_conc_argument.arg036,
        argument37          =>  it_conc_argument.arg037,
        argument38          =>  it_conc_argument.arg038,
        argument39          =>  it_conc_argument.arg039,
        argument40          =>  it_conc_argument.arg040,
        argument41          =>  it_conc_argument.arg041,
        argument42          =>  it_conc_argument.arg042,
        argument43          =>  it_conc_argument.arg043,
        argument44          =>  it_conc_argument.arg044,
        argument45          =>  it_conc_argument.arg045,
        argument46          =>  it_conc_argument.arg046,
        argument47          =>  it_conc_argument.arg047,
        argument48          =>  it_conc_argument.arg048,
        argument49          =>  it_conc_argument.arg049,
        argument50          =>  it_conc_argument.arg050,
        argument51          =>  it_conc_argument.arg051,
        argument52          =>  it_conc_argument.arg052,
        argument53          =>  it_conc_argument.arg053,
        argument54          =>  it_conc_argument.arg054,
        argument55          =>  it_conc_argument.arg055,
        argument56          =>  it_conc_argument.arg056,
        argument57          =>  it_conc_argument.arg057,
        argument58          =>  it_conc_argument.arg058,
        argument59          =>  it_conc_argument.arg059,
        argument60          =>  it_conc_argument.arg060,
        argument61          =>  it_conc_argument.arg061,
        argument62          =>  it_conc_argument.arg062,
        argument63          =>  it_conc_argument.arg063,
        argument64          =>  it_conc_argument.arg064,
        argument65          =>  it_conc_argument.arg065,
        argument66          =>  it_conc_argument.arg066,
        argument67          =>  it_conc_argument.arg067,
        argument68          =>  it_conc_argument.arg068,
        argument69          =>  it_conc_argument.arg069,
        argument70          =>  it_conc_argument.arg070,
        argument71          =>  it_conc_argument.arg071,
        argument72          =>  it_conc_argument.arg072,
        argument73          =>  it_conc_argument.arg073,
        argument74          =>  it_conc_argument.arg074,
        argument75          =>  it_conc_argument.arg075,
        argument76          =>  it_conc_argument.arg076,
        argument77          =>  it_conc_argument.arg077,
        argument78          =>  it_conc_argument.arg078,
        argument79          =>  it_conc_argument.arg079,
        argument80          =>  it_conc_argument.arg080,
        argument81          =>  it_conc_argument.arg081,
        argument82          =>  it_conc_argument.arg082,
        argument83          =>  it_conc_argument.arg083,
        argument84          =>  it_conc_argument.arg084,
        argument85          =>  it_conc_argument.arg085,
        argument86          =>  it_conc_argument.arg086,
        argument87          =>  it_conc_argument.arg087,
        argument88          =>  it_conc_argument.arg088,
        argument89          =>  it_conc_argument.arg089,
        argument90          =>  it_conc_argument.arg090,
        argument91          =>  it_conc_argument.arg091,
        argument92          =>  it_conc_argument.arg092,
        argument93          =>  it_conc_argument.arg093,
        argument94          =>  it_conc_argument.arg094,
        argument95          =>  it_conc_argument.arg095,
        argument96          =>  it_conc_argument.arg096,
        argument97          =>  it_conc_argument.arg097,
        argument98          =>  it_conc_argument.arg098,
        argument99          =>  it_conc_argument.arg099,
        argument100         =>  it_conc_argument.arg100
      );
--##################  �W���@�\�̃R���J�����g�N���p�b�P�[�W�Ăяo�� END     ###################
  --
      RETURN ln_reqid ;
  --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN cv_status_error ;
    --
  END start_request ;
--
  --
  /**********************************************************************************
   * Function  Name   : submit_svf_request
   * Description      : SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)
   ***********************************************************************************/
  PROCEDURE submit_svf_request(ov_retcode      OUT VARCHAR2                                         --���^�[���R�[�h
                              ,ov_errbuf       OUT VARCHAR2                                         --�G���[���b�Z�[�W
                              ,ov_errmsg       OUT VARCHAR2                                         --���[�U�[�E�G���[���b�Z�[�W
                              ,iv_conc_name    IN  VARCHAR2                                         --�R���J�����g��
                              ,iv_file_name    IN  VARCHAR2                                         --�o�̓t�@�C����
                              ,iv_file_id      IN  VARCHAR2                                         --���[ID
                              ,iv_output_mode  IN  VARCHAR2  DEFAULT 1                              --�o�͋敪
                              ,iv_frm_file     IN  VARCHAR2                                         --�t�H�[���l���t�@�C����
                              ,iv_vrq_file     IN  VARCHAR2                                         --�N�G���[�l���t�@�C����
                              ,iv_org_id       IN  VARCHAR2                                          --ORG_ID
                              ,iv_user_name    IN  VARCHAR2                                         --���O�C���E���[�U��
                              ,iv_resp_name    IN  VARCHAR2                                         --���O�C���E���[�U�̐E�Ӗ�
                              ,iv_doc_name     IN  VARCHAR2  DEFAULT NULL                           --������
                              ,iv_printer_name IN  VARCHAR2  DEFAULT NULL                           --�v�����^��
                              ,iv_request_id   IN  VARCHAR2                                         --�v��ID
                              ,iv_nodata_msg   IN  VARCHAR2                                         --�f�[�^�Ȃ����b�Z�[�W
                              ,iv_svf_param1   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^1
                              ,iv_svf_param2   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^2
                              ,iv_svf_param3   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^3
                              ,iv_svf_param4   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^4
                              ,iv_svf_param5   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^5
                              ,iv_svf_param6   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^6
                              ,iv_svf_param7   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^7
                              ,iv_svf_param8   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^8
                              ,iv_svf_param9   IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^9
                              ,iv_svf_param10  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^10
                              ,iv_svf_param11  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^11
                              ,iv_svf_param12  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^12
                              ,iv_svf_param13  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^13
                              ,iv_svf_param14  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^14
                              ,iv_svf_param15  IN  VARCHAR2  DEFAULT NULL                           --svf�σp�����[�^15
                              )
  IS
    -- ===============================
    -- ���[�U�[�錾���[�J���萔
    -- ===============================
    -- ��{���
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submit_svf_request';
    -- SVF�N���R���J�����g�̈����֘A
    cv_svf_app              CONSTANT VARCHAR2(30)   := 'SVF';
    cv_ftp_app              CONSTANT VARCHAR2(30)   := 'XXCCP';
    cv_svf_prog             CONSTANT VARCHAR2(30)   := 'SVF_ORA';
    cv_ftp_prog             CONSTANT VARCHAR2(30)   := 'XXCCP004A02C';
    cv_orgid                CONSTANT VARCHAR2(100)  := '0';
    cv_op_spool             CONSTANT VARCHAR2(30)   := 'SpoolFileName=';
    cv_op_msg               CONSTANT VARCHAR2(30)   := 'NODATA_MSG=';
    cv_op_cond              CONSTANT VARCHAR2(30)   := 'Condition=';
    cv_opv_cond1            CONSTANT VARCHAR2(30)   := '[REQUEST_ID]=';
-- ADD START 2009/03/06
-- 2009-04-08 UPDATE 2009-04-08 Ver.1.5 Masayuki.Sano Start
--    cv_form_mode_4          CONSTANT VARCHAR2(30)   := 'FromMode=4';
    cv_form_mode_4          CONSTANT VARCHAR2(30)   := 'FormMode=4';
-- 2009-04-08 UPDATE 2009-04-08 Ver.1.5 Masayuki.Sano Start
-- ADD END   2009/03/06
    --
    -- �V�X�e���v���t�@�C�����̒萔
    cv_plofile01            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_HOST_NAME'     ;                 -- XXCCP:SVF�z�X�g��
    cv_plofile02            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_LOGIN_USER'    ;                 -- XXCCP:SVF���O�C�����[�U��
    cv_plofile03            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_LOGIN_PASSWORD';                 -- XXCCP:SVF���O�C���p�X���[�h
    cv_plofile04            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_ENV'           ;                 -- XXCCP:SVF���s���p�X
    cv_plofile05            CONSTANT VARCHAR2(30)   := 'XXCCP1_EBS_TEMP_PATH'     ;                 -- XXCCP:EBS�T�[�o�ꎞ�t�@�C���i�[PATH
    cv_plofile06            CONSTANT VARCHAR2(30)   := 'XXCCP1_EBS_TEMP_FILENAME' ;                 -- XXCCP:EBS�T�[�o�ꎞ�t�@�C����
    cv_plofile07            CONSTANT VARCHAR2(30)   := 'XXCCP1_NODATA_MSG'        ;                 -- XXCCP:SVF�I�v�V�����E�f�[�^�������b�Z�[�W
    cv_plofile08            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVFCONC_INTERVAL'  ;                 -- XXCCP:SVF�R���J�����g�Ď��Ԋu
    cv_plofile09            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVFCONC_MAXWAIT'   ;                 -- XXCCP:SVF�R���J�����g�ő�Ď�����
    cv_plofile10            CONSTANT VARCHAR2(30)   := 'XXCCP1_FTPCONC_INTERVAL'  ;                 -- XXCCP:�t�@�C���]���R���J�����g�Ď��Ԋu
    cv_plofile11            CONSTANT VARCHAR2(30)   := 'XXCCP1_FTPCONC_MAXWAIT'   ;                 -- XXCCP:�t�@�C���]���R���J�����g�ő�Ď�����
    cv_plofile12            CONSTANT VARCHAR2(30)   := 'XXCCP1_SVF_DRAIVE'        ;                 -- XXCCP:SVF���s�h���C�u��
    --
    -- ���̑�
    cv_mode_pdf             CONSTANT VARCHAR2(1)    := '1';                                         -- �o�͋敪 1�FPDF�o��
    cv_mode_rde             CONSTANT VARCHAR2(1)    := '2';                                         -- �o�͋敪 2�FRDE�o��
    cv_mode_rep             CONSTANT VARCHAR2(1)    := '3';                                         -- �o�͋敪 3�FReportMisson�o��
    cn_svf_prm_len          CONSTANT NUMBER         := 240;                                         -- SVF�R���J�����g�̃p�����[�^�ő咷
    cn_pad_plofile          CONSTANT NUMBER         := 30;                                          -- �v���t�@�C���\����PAD���̋l�ߐ�
    cn_pad_prm              CONSTANT NUMBER         := 36;                                          -- �p�����[�^�\����PAD���̋l�ߐ�
    --
    -- ===============================
    -- ���[�U�[�錾���[�J���ϐ�
    -- ===============================
    -- INFO
    lv_step                 VARCHAR2(100) := NULL;
    --
    -- IN PRM
    -- SVF�N���R���J�����g/�t�@�C���]���R���J�����g�p�ϐ�(�v���t�@�C������̎擾�l)
    lv_svf_host_name        VARCHAR2(240) := NULL;                                                  -- SVF�T�[�o��HOST��
    lv_svf_login_user       VARCHAR2(240) := NULL;                                                  -- SVF�T�[�o��Login���[�U��
    lv_svf_login_pass       VARCHAR2(240) := NULL;                                                  -- SVF�T�[�o��Login�p�X���[�h
    lv_svf_spool_dir        VARCHAR2(240) := NULL;                                                  -- spool��f�B���N�g���p�X
    lv_from_dir             VARCHAR2(240) := NULL;                                                  -- Form�l���t�@�C���i�[��f�B���N�g���p�X
    lv_quary_dir            VARCHAR2(240) := NULL;                                                  -- Quary�l���t�@�C���i�[��f�B���N�g���p�X
    lv_svf_env              VARCHAR2(240) := NULL;                                                  -- SVF���s���p�X
    lv_svfdrive             VARCHAR2(240) := NULL;                                                  -- SVF���s�h���C�u��
    lv_ebs_put_fpath        VARCHAR2(240) := NULL;                                                  -- EBS���̎擾�t�@�C����΃p�X
    lv_ebs_temp_dir         VARCHAR2(240) := NULL;                                                  -- EBS���̈ꎞLOG�t�@�C���i�[�f�B���N�g���p�X
    lv_ebs_temp_file        VARCHAR2(240) := NULL;                                                  -- EBS���̈ꎞLOG�t�@�C������
    lv_nodata_msg           VARCHAR2(240) := NULL;                                                  -- �f�t�H���g��NO_DATA_MASSAGE
    lv_svf_interval         VARCHAR2(240) := NULL;                                                  -- SVF�N���R���J�����g�̊Ď��Ԋu(�b)
    lv_ftp_interval         VARCHAR2(240) := NULL;                                                  -- FTP�]���R���J�����g�̊Ď��Ԋu(�b)
    lv_svf_maxwait          VARCHAR2(240) := NULL;                                                  -- SVF�N���R���J�����g�̍ő�I���҂�����(�b)
    lv_ftp_maxwait          VARCHAR2(240) := NULL;                                                  -- FTP�]���R���J�����g�̍ő�I���҂�����(�b)
    -- �ҏW�p�ϐ�
    lv_spool_op_edit        VARCHAR2(500) := NULL;
    lv_print_op_edit        VARCHAR2(500) := NULL;
    lv_msg_op_edit          VARCHAR2(500) := NULL;
    lv_cond_001             VARCHAR2(240) := NULL;
    lv_cond_002             VARCHAR2(240) := NULL;
    lv_cond_003             VARCHAR2(240) := NULL;
    lv_cond_004             VARCHAR2(240) := NULL;
    lv_cond_005             VARCHAR2(240) := NULL;
    lv_cond_006             VARCHAR2(240) := NULL;
    lv_cond_007             VARCHAR2(240) := NULL;
    lv_cond_008             VARCHAR2(240) := NULL;
    lv_cond_009             VARCHAR2(240) := NULL;
    lv_cond_010             VARCHAR2(240) := NULL;
    lv_cond_011             VARCHAR2(240) := NULL;
    lv_cond_012             VARCHAR2(240) := NULL;
    lv_cond_013             VARCHAR2(240) := NULL;
    lv_cond_014             VARCHAR2(240) := NULL;
    lv_cond_015             VARCHAR2(240) := NULL;
    ln_cond_cnt             NUMBER := 0;                                                            -- �ǉ������̌����J�E���g 
    -- OUT PRM
    -- FND_REQUEST.SUBMIT_REQUEST�Ԃ�l�i�[�ϐ�
    ln_svf_reqid            NUMBER := NULL;                                                         -- SVF�N���R���J�����g�̃��N�G�X�gID
    ln_ftp_reqid            NUMBER := NULL;                                                         -- FTP�]���R���J�����g�̃��N�G�X�gID
    --
    -- FND_CONCURRENT.WAIT_FOR_REQUEST�Ԃ�l�i�[�ϐ�
    lv_phase                VARCHAR2(4000) := NULL;                                                 -- �v���t�F�[�Y(FND�ݒ�)
    lv_status               VARCHAR2(4000) := NULL;                                                 -- ���s����(FND�ݒ�)
    lv_dev_phase            VARCHAR2(4000) := NULL;                                                 -- �v���t�F�[�Y(�p��)
    lv_dev_status           VARCHAR2(4000) := NULL;                                                 -- ���s����(�p��)
    lv_message              VARCHAR2(4000) := NULL;                                                 -- ���b�Z�[�W
    lb_ret_bool             BOOLEAN := NULL ;                                                       -- �_���^�Ԃ�l
    --
    -- OTHER
    ln_error_msg_cnt        NUMBER  := 0;                                                           -- �G���[���b�Z�[�W�̃J�E���g
    ln_loop_cnt             NUMBER  := 0;                                                           -- LOOP�J�E���g�p�ϐ�
    -- ===============================
    -- ���[�U�[�錾���[�J���J�[�\��
    -- ===============================
    --
    -- ===============================
    -- ���[�U�[�錾���[�J�����R�[�h
    -- ===============================
    -- �R���J�����g�����p
    lt_svf_argument         gt_conc_argument;                                                       -- SVF�N���R���J�����g�p�p�����[�^�Z�b�g
    lt_ftp_argument         gt_conc_argument;                                                       -- �t�@�C���]���R���J�����g�p�p�����[�^�Z�b�g
    --
    -- ===============================
    -- ���[�U�[�錾���[�J����O
    -- ===============================
    prm_error_expt          EXCEPTION;                                                              -- �p�����[�^�̃G���[
    date_accession_expt     EXCEPTION;                                                              -- �f�[�^�擾�G���[
    --
  BEGIN
    lv_step         := 'STEP 00.00.00';
    -- ==============================================================
    -- 1.��������
    -- ==============================================================
    -- *******************************
    -- 1-1.�ϐ�������
    -- *******************************
    lv_step         := 'STEP 01.01.00';
    -- OUT�p�����[�^�̏�����
    ov_retcode      := cv_status_normal;
    ov_errbuf       := NULL;
    ov_errmsg       := NULL;
    --
    -- *******************************
    -- 1-2.���̓p�����[�^���O�o��
    -- *******************************
    -- 1-2.�p�����[�^�̃��O�o��
    -- IN:01.�R���J�����g��
    lv_step         := 'STEP 01.02.01';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm01, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_conc_name
      );
    --
    -- IN:02.�o�̓t�@�C����
    lv_step         := 'STEP 01.02.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm02, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_file_name
      );
    --
    -- IN:03.���[ID
    lv_step         := 'STEP 01.02.03';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm03, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_file_id
      );
    --
    -- IN:04.�o�͋敪
    lv_step         := 'STEP 01.02.04';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm04, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_output_mode
      );
    --
    -- IN:05.�t�H�[���l���t�@�C����
    lv_step         := 'STEP 01.02.05';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm05, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_frm_file
      );
    --
    -- IN:06.�N�G���[�l���t�@�C����
    lv_step         := 'STEP 01.02.06';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm06, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_vrq_file
      );
    --
    -- IN:07.ORG_ID
    lv_step         := 'STEP 01.02.07';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm07, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_org_id
      );
    --
    -- IN:08.���O�C���E���[�U��
    lv_step         := 'STEP 01.03.08';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm08, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_user_name
      );
    --
    -- IN:09.���O�C���E���[�U�̐E�Ӗ�
    lv_step         := 'STEP 01.02.09';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm09, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_resp_name
      );
    --
    -- IN:10.������
    lv_step         := 'STEP 01.02.10';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm10, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_doc_name
      );
    --
    -- IN:11.�v�����^��
    lv_step         := 'STEP 01.02.11';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm11, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_printer_name
      );
    --
    -- IN:12.�v��ID
    lv_step         := 'STEP 01.02.12';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm12, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_request_id
      );
    --
    -- IN:13.�f�[�^�Ȃ����b�Z�[�W
    lv_step         := 'STEP 01.02.13';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm13, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_nodata_msg
      );
    --
    -- IN:14.svf�σp�����[�^1
    lv_step         := 'STEP 01.02.14';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm14, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param1
      );
    --
    -- IN:15.svf�σp�����[�^2
    lv_step         := 'STEP 01.02.15';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm15, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param2
      );
    --
    -- IN:16.svf�σp�����[�^3
    lv_step         := 'STEP 01.02.16';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm16, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param3
      );
    --
    -- IN:17.svf�σp�����[�^4
    lv_step         := 'STEP 01.02.17';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm17, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param4
      );
    --
    -- IN:18.svf�σp�����[�^5
    lv_step         := 'STEP 01.02.18';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm18, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param5
      );
    --
    -- IN:19.svf�σp�����[�^6
    lv_step         := 'STEP 01.02.19';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm19, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param6
      );
    --
    -- IN:20.svf�σp�����[�^7
    lv_step         := 'STEP 01.02.20';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm20, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param7
      );
    --
    -- IN:21.svf�σp�����[�^8
    lv_step         := 'STEP 01.02.21';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm21, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param8
      );
    --
    -- IN:22.svf�σp�����[�^9
    lv_step         := 'STEP 01.02.22';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm22, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param9
      );
    --
    -- IN:23.svf�σp�����[�^10
    lv_step         := 'STEP 01.02.23';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm23, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param10
      );
    --
    -- IN:24.svf�σp�����[�^11
    lv_step         := 'STEP 01.02.24';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm24, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param11
      );
    --
    -- IN:25.svf�σp�����[�^12
    lv_step         := 'STEP 01.02.25';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm25, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param12
      );
    --
    -- IN:26.svf�σp�����[�^13
    lv_step         := 'STEP 01.02.26';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm26, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param13
      );
    --
    -- IN:27.svf�σp�����[�^14
    lv_step         := 'STEP 01.02.27';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm27, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param14
      );
    --
    -- IN:28.svf�σp�����[�^15
    lv_step         := 'STEP 01.02.28';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_prm,
      iv_token_01     => cv_token_number,
      iv_token_val01  => RPAD(cv_token_v_prm28, cn_pad_prm),
      iv_token_02     => cv_token_prmval,
      iv_token_val02  => iv_svf_param15
      );
    --
--
    -- *******************************
    -- 1-3.���̓p�����[�^�`�F�b�N
    -- *******************************
    lv_step         := 'STEP 01.03.00';
    -- IN_01.�R���J�����g��[ iv_conc_name ]�̃`�F�b�N(�K�{�`�F�b�N)
    IF (iv_conc_name IS NULL ) THEN
      lv_step         := 'STEP.01.03.01';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm01
        );
    END IF;
    --
    -- IN_02.�o�̓t�@�C����[ iv_file_name ]�̃`�F�b�N(�K�{�`�F�b�N)
    IF (iv_file_name IS NULL ) THEN
      lv_step         := 'STEP.01.03.02';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm02
        );
    END IF;
    --
    -- IN_03.���[ID[ iv_file_id ]
    -- ���g�p�Ȃ̂Ń`�F�b�N�ΏۊO
    --
    -- IN_04.�o�͋敪[ iv_output_mode ]�̃`�F�b�N(�������`�F�b�N)
    IF (iv_output_mode IS NULL OR iv_output_mode NOT IN(cv_mode_pdf)) THEN
      lv_step         := 'STEP.01.03.04';
      -- iv_output_mode��NULL�̏ꍇ��'1'�ȊO�̏ꍇ�ɃG���[
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_unjust,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm04
        );
    END IF;
    --
    -- IN_05.�t�H�[���l���t�@�C����[ iv_frm_file ]�̃`�F�b�N(�K�{�`�F�b�N)
    IF (iv_frm_file IS NULL ) THEN
      lv_step         := 'STEP.01.03.05';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm05
        );
    END IF;
    --
    -- IN_06.�N�G���[�l���t�@�C����[ iv_vrq_file ]�̃`�F�b�N(�K�{�`�F�b�N)
    IF (iv_vrq_file IS NULL ) THEN
      lv_step         := 'STEP.01.03.06';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm06
        );
    END IF;
    --
    -- IN_07.ORG_ID[ iv_org_id ]
    -- IN_08.���O�C���E���[�U��[ iv_user_name ]
    -- IN_09.���O�C���E���[�U�̐E�Ӗ�[ iv_resp_name ]
    -- IN_10.������[ iv_doc_name ]
    -- IN_11.�v�����^��[ iv_printer_name ]
    -- ���͖��g�p�Ȃ̂Ń`�F�b�N�ΏۊO
    --
    -- IN_12.�v��ID[ iv_request_id ]�̃`�F�b�N(�K�{�`�F�b�N)
    IF (iv_request_id IS NULL ) THEN
      lv_step         := 'STEP.01.03.12';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_required,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm12
        );
    END IF;
    -- IN_13.�f�[�^�Ȃ����b�Z�[�W[ iv_nodata_msg ]�̃`�F�b�N(�������`�F�b�N)
    -- SVF�I�v�V�����p�����[�^�y�f�[�^�������b�Z�[�W�z�̍쐬���Ƀ`�F�b�N
    --
--
    -- IN_14.svf�σp�����[�^01[ iv_svf_param1 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param1 IS NOT NULL) AND ( LENGTHB(iv_svf_param1) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param1�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.14';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm14
        );
    END IF;
    --
    -- IN_15.svf�σp�����[�^02[ iv_svf_param2 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param2 IS NOT NULL) AND ( LENGTHB(iv_svf_param2) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param2�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.15';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm15
        );
    END IF;
    --
    -- IN_16.svf�σp�����[�^03[ iv_svf_param3 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param3 IS NOT NULL) AND ( LENGTHB(iv_svf_param3) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param3�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.16';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm16
        );
    END IF;
    --
    -- IN_17.svf�σp�����[�^04[ iv_svf_param4 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param4 IS NOT NULL) AND ( LENGTHB(iv_svf_param4) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param4�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.17';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm17
        );
    END IF;
    --
    -- IN_18.svf�σp�����[�^05[ iv_svf_param5 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param5 IS NOT NULL) AND ( LENGTHB(iv_svf_param5) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param5�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.18';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm18
        );
    END IF;
    --
    -- IN_19.svf�σp�����[�^06[ iv_svf_param6 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param6 IS NOT NULL) AND ( LENGTHB(iv_svf_param6) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param6�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.19';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm19
        );
    END IF;
    --
    -- IN_20.svf�σp�����[�^07[ iv_svf_param7 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param7 IS NOT NULL) AND ( LENGTHB(iv_svf_param7) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param7�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.20';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm20
        );
    END IF;
    --
    -- IN_21.svf�σp�����[�^08[ iv_svf_param8 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param8 IS NOT NULL) AND ( LENGTHB(iv_svf_param8) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param8�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.21';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm21
        );
    END IF;
    --
    -- IN_22.svf�σp�����[�^09[ iv_svf_param9 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param9 IS NOT NULL) AND ( LENGTHB(iv_svf_param9) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param9�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.22';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm22
        );
    END IF;
    --
    -- IN_23.svf�σp�����[�^10[ iv_svf_param10 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param10 IS NOT NULL) AND ( LENGTHB(iv_svf_param10) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param10�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.23';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm23
        );
    END IF;
    --
    -- IN_24.svf�σp�����[�^11[ iv_svf_param11 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param11 IS NOT NULL) AND ( LENGTHB(iv_svf_param11) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param11�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.24';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm24
        );
    END IF;
    --
    -- IN_25.svf�σp�����[�^12[ iv_svf_param12 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param12 IS NOT NULL) AND ( LENGTHB(iv_svf_param12) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param12�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.25';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm25
        );
    END IF;
    --
    -- IN_26.svf�σp�����[�^13[ iv_svf_param13 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param13 IS NOT NULL) AND ( LENGTHB(iv_svf_param13) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param13�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.26';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm26
        );
    END IF;
    --
    -- IN_27.svf�σp�����[�^14[ iv_svf_param14 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param14 IS NOT NULL) AND ( LENGTHB(iv_svf_param14) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param14�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.27';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm27
        );
    END IF;
    --
    -- IN_28.svf�σp�����[�^15[ iv_svf_param15 ]�̃`�F�b�N(�p�����[�^���`�F�b�N)
    IF ( (iv_svf_param15 IS NOT NULL) AND ( LENGTHB(iv_svf_param15) > cn_chk_svfprm_len ) ) THEN
      -- ���̓p�����[�^iv_svf_param15�ւ̓��͂��L��A���̒�����230�o�C�g���傫���ꍇ�ɃG���[�Ƃ���B
      lv_step         := 'STEP.01.03.28';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prm_length,
        iv_token_01     => cv_token_item,
        iv_token_val01  => cv_token_v_prm28
        );
    END IF;
    --
--
    -- �p�����[�^�̃G���[�̗L���𔻒f
    IF (ln_error_msg_cnt > 0 ) THEN
      -- �G���[������ꍇ�͗�O������
      lv_step         := 'STEP 01.03.99';
      RAISE prm_error_expt ;
    END IF;
--
    -- *******************************
    -- 1-4.�V�X�e���v���t�@�C������̏��擾
    -- *******************************
    lv_step         := 'STEP 01.04.01';
    -- �V�X�e���v���t�@�C������l���擾����
    lv_svf_host_name  := FND_PROFILE.VALUE(cv_plofile01);
    lv_svf_login_user := FND_PROFILE.VALUE(cv_plofile02);
    lv_svf_login_pass := FND_PROFILE.VALUE(cv_plofile03);
    lv_svf_env        := FND_PROFILE.VALUE(cv_plofile04);
    lv_ebs_temp_dir   := FND_PROFILE.VALUE(cv_plofile05);
    lv_ebs_temp_file  := FND_PROFILE.VALUE(cv_plofile06);
    lv_nodata_msg     := FND_PROFILE.VALUE(cv_plofile07);
    lv_svf_interval   := FND_PROFILE.VALUE(cv_plofile08);
    lv_svf_maxwait    := FND_PROFILE.VALUE(cv_plofile09);
    lv_ftp_interval   := FND_PROFILE.VALUE(cv_plofile10);
    lv_ftp_maxwait    := FND_PROFILE.VALUE(cv_plofile11);
    lv_svfdrive       := FND_PROFILE.VALUE(cv_plofile12);
    --
    -- �擾�f�[�^�̃��O�o��
    lv_step         := 'STEP 01.04.02';
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile01, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_host_name, ' ')  );
--    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile02, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_login_user, ' ') );
--    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile03, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_login_pass, ' ') );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile12, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svfdrive, ' ')       );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile04, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_env, ' ')        );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile05, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_temp_dir, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile06, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_temp_file, ' ')  );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile07, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_nodata_msg, ' ')     );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile08, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_interval, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile09, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_svf_maxwait, ' ')    );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile10, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ftp_interval, ' ')   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_plofile_msg || RPAD(cv_plofile11, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ftp_maxwait, ' ')    );
    --
    -- *******************************
    -- 1-5.�V�X�e���v���t�@�C���擾�`�F�b�N���s���܂��B
    -- *******************************
    lv_step         := 'STEP 01.05.00';
    -- �V�X�e���v���t�@�C��:XXCCP:SVF�z�X�g��
    IF (lv_svf_host_name IS NULL) THEN
      lv_step         := 'STEP 01.05.01';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile01
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF���O�C�����[�U��
    IF (lv_svf_login_user IS NULL) THEN
      lv_step         := 'STEP 01.05.02';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile02
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF���O�C���p�X���[�h
    IF (lv_svf_login_pass IS NULL) THEN
      lv_step         := 'STEP 01.05.03';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile03
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF���s���p�X
    IF (lv_svf_env IS NULL) THEN
      lv_step         := 'STEP 01.05.04';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile04
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:EBS�T�[�o�ꎞ�t�@�C���i�[PATH
    IF (lv_ebs_temp_dir IS NULL) THEN
      lv_step         := 'STEP 01.05.05';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile05
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:EBS�T�[�o�ꎞ�t�@�C����
    IF (lv_ebs_temp_file IS NULL) THEN
      lv_step         := 'STEP 01.05.06';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile06
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:XXCCP:SVF�I�v�V�����E�f�[�^�������b�Z�[�W
    IF (lv_nodata_msg IS NULL) THEN
      lv_step         := 'STEP 01.05.07';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile07
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF�R���J�����g�Ď��Ԋu
    IF (lv_svf_interval IS NULL) THEN
      lv_step         := 'STEP 01.05.08';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile08
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF�R���J�����g�ő�Ď�����
    IF (lv_svf_maxwait IS NULL) THEN
      lv_step         := 'STEP 01.05.09';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile09
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:�t�@�C���]���R���J�����g�Ď��Ԋu
    IF (lv_ftp_interval IS NULL) THEN
      lv_step         := 'STEP 01.05.10';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile10
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:�t�@�C���]���R���J�����g�ő�Ď�����
    IF (lv_ftp_maxwait IS NULL) THEN
      lv_step         := 'STEP 01.05.11';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile11
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C��:XXCCP:SVF���s�h���C�u��
    IF (lv_svfdrive IS NULL) THEN
      lv_step         := 'STEP 01.05.12';
      ln_error_msg_cnt := ln_error_msg_cnt + 1 ;
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_get_profile,
        iv_token_01     => cv_token_prof_name,
        iv_token_val01  => cv_plofile12
        );
      --
    END IF;
    --
    -- �V�X�e���v���t�@�C���̎擾�G���[�̗L���𔻒f
    IF (ln_error_msg_cnt > 0 ) THEN
      -- �G���[������ꍇ�͗�O������
      lv_step         := 'STEP 01.05.99';
      RAISE date_accession_expt ;
    --
    END IF;
    --
    --===============================
    -- EBS���i�[�t�@�C����΃p�X�擾
    --===============================
    lv_step         := 'STEP 01.06.01';
    BEGIN
      -- �v��ID����OUTFILE_NAME���擾���܂��B
      SELECT  outfile_name
      INTO    lv_ebs_put_fpath
      FROM    fnd_concurrent_requests
      WHERE   request_id = TO_NUMBER(iv_request_id) ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�擾�G���[���b�Z�[�W���o��
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_date_accession,
          iv_token_01     => cv_token_number,
          iv_token_val01  => cv_token_v_db_val_of
          );
        --
      RAISE date_accession_expt;
    END;
    --
    -- �擾�`�F�b�N
    IF (lv_ebs_put_fpath IS NULL) THEN
      -- �擾���o���ĂȂ��ꍇ�̓G���[�Ƃ���
      -- �f�[�^�擾�G���[���b�Z�[�W���o��
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_date_accession,
        iv_token_01     => cv_token_number,
        iv_token_val01  => cv_token_v_db_val_of
        );
        --
        RAISE date_accession_expt;
    END IF;
    -- ���b�Z�[�W�o�͂�����
    FND_FILE.PUT_LINE(FND_FILE.LOG, cv_outpath_msg || RPAD(cv_token_v_db_val_of, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_ebs_put_fpath, ' ')    );
    --
    -- ==============================================================
    -- 2.SVF�R���J�����g�̋N��
    -- ==============================================================
    lv_step         := 'STEP 02.00.00';
    -- *******************************
    -- 2-1.SVF�R���J�����g�p�I�v�V�����p�����[�^�̕ҏW
    -- *******************************
    -- 2-1.�N���p�����[�^�̕ҏW
    IF (iv_output_mode = cv_mode_pdf ) THEN
      --===============================
      -- �e��p�X�̐���
      --===============================
      lv_step         := 'STEP 02.01.00';
      lv_svf_spool_dir  := lv_svf_env   || cv_part_bs ||
                           cv_pdf_dir   ;
      lv_from_dir       := lv_svfdrive  || cv_part_bs ||
                           lv_svf_env   || cv_part_bs ||
                           cv_form_dir  || cv_part_bs ||
                           iv_frm_file  ;
      lv_quary_dir      := lv_svfdrive  || cv_part_bs ||
                           lv_svf_env   || cv_part_bs ||
                           cv_query_dir || cv_part_bs ||
                           iv_vrq_file  ;
      --
      --===============================
      -- �t�@�C���X�v�[����w��I�v�V�����̕ҏW
      --===============================
      lv_step         := 'STEP 02.01.01';
      lv_spool_op_edit := cv_op_spool || lv_svfdrive      || cv_part_bs ||
                                         lv_svf_spool_dir || cv_part_bs ||
                                         iv_file_name;
      --
      --===============================
      -- NO DATA���b�Z�[�W�̕ҏW
      --===============================
      IF (iv_nodata_msg IS NOT NULL) THEN
      -- ���̓p�����[�^�̃f�[�^�������b�Z�[�W���p��
        lv_step         := 'STEP 02.01.02';
        IF (LENGTH(cv_op_msg || iv_nodata_msg ) > cn_svf_prm_len ) THEN
          lv_step         := 'STEP 02.01.03';
          -- �p�����[�^����荞�񂾌��ʂ�240�����ȏ�Ȃ�΃G���[
          output_log(
            iv_appl         => cv_applcation_xxccp,
            iv_name         => cv_err_prm_unjust,
            iv_token_01     => cv_token_item,
            iv_token_val01  => cv_token_v_prm13
            );
          --
          RAISE prm_error_expt;
          --
        ELSE
          --
          lv_step         := 'STEP 02.01.04';
          lv_msg_op_edit := cv_op_msg ||iv_nodata_msg ;
        END IF;
      --
      ELSE
      -- �f�t�H���g�̃f�[�^�������b�Z�[�W���p��
        lv_step         := 'STEP 02.01.05';
        IF (LENGTH(cv_op_msg || lv_nodata_msg ) > cn_svf_prm_len ) THEN
          lv_step         := 'STEP 02.01.06';
          -- �p�����[�^����荞�񂾌��ʂ�240�����ȏ�Ȃ�΃G���[
          output_log(
            iv_appl         => cv_applcation_xxccp,
            iv_name         => cv_err_prm_unjust,
            iv_token_01     => cv_token_item,
            iv_token_val01  => cv_plofile07
            );
          --
          RAISE date_accession_expt;
          --
        ELSE
          --
          lv_step         := 'STEP 02.01.07';
          lv_msg_op_edit := cv_op_msg ||lv_nodata_msg ;
        END IF;
      --
      END IF;
    --
      --
      --===============================
      -- �ǉ������̕ҏW(Condition�F�v��ID)
      --===============================
      -- �v��ID
      lv_step         := 'STEP 02.01.08';
      --
      --===============================
      -- �ǉ������̕ҏW(Condition)
      --===============================
      --svf�σp�����[�^1
      IF ( iv_svf_param1  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_001 := cv_op_cond || iv_svf_param1  ;
      END IF;
      --
      --svf�σp�����[�^2
      IF ( iv_svf_param2  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_002 := cv_op_cond || iv_svf_param2  ;
      END IF;
      --
      --svf�σp�����[�^3
      IF ( iv_svf_param3  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_003 := cv_op_cond || iv_svf_param3  ;
      END IF;
      --
      --svf�σp�����[�^4
      IF ( iv_svf_param4  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_004 := cv_op_cond || iv_svf_param4  ;
      END IF;
      --
      --svf�σp�����[�^5
      IF ( iv_svf_param5  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_005 := cv_op_cond || iv_svf_param5  ;
      END IF;
      --
      --svf�σp�����[�^6
      IF ( iv_svf_param6  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_006 := cv_op_cond || iv_svf_param6  ;
      END IF;
      --
      --svf�σp�����[�^7
      IF ( iv_svf_param7  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_007 := cv_op_cond || iv_svf_param7  ;
      END IF;
      --
      --svf�σp�����[�^8
      IF ( iv_svf_param8  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_008 := cv_op_cond || iv_svf_param8  ;
      END IF;
      --
      --svf�σp�����[�^9
      IF ( iv_svf_param9  IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_009 := cv_op_cond || iv_svf_param9  ;
      END IF;
      --
      --svf�σp�����[�^10
      IF ( iv_svf_param10 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_010 := cv_op_cond || iv_svf_param10 ;
      END IF;
      --
      --svf�σp�����[�^11
      IF ( iv_svf_param11 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_011 := cv_op_cond || iv_svf_param11 ;
      END IF;
      --
      --svf�σp�����[�^12
      IF ( iv_svf_param12 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_012 := cv_op_cond || iv_svf_param12 ;
      END IF;
      --
      --svf�σp�����[�^13
      IF ( iv_svf_param13 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_013 := cv_op_cond || iv_svf_param13 ;
      END IF;
      --
      --svf�σp�����[�^14
      IF ( iv_svf_param14 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_014 := cv_op_cond || iv_svf_param14 ;
      END IF;
      --
      --svf�σp�����[�^15
      IF ( iv_svf_param15 IS NOT NULL ) THEN
        ln_cond_cnt := ln_cond_cnt + 1;
        lv_cond_015 := cv_op_cond || iv_svf_param15 ;
      END IF;
      --
--
--
    -- *******************************
    -- 2-2.SVF�R���J�����g�p�����[�^�̍\���̂ւ̐ݒ�
    -- *******************************
      lv_step         := 'STEP 02.02.01';
      lt_svf_argument.appl    := cv_svf_app;                                                        -- �A�v���P�[�V������
      lt_svf_argument.prog    := cv_svf_prog;                                                       -- �v���O������
      lt_svf_argument.arg001  := lv_svf_host_name;                                                  -- SVF�T�[�oHOST��
      lt_svf_argument.arg002  := lv_from_dir;                                                       -- FRM��(�t�H�[���l���t�@�C���̐�΃p�X)
      lt_svf_argument.arg003  := lv_quary_dir;                                                      -- QRY��(�N�G���[�l���t�@�C���̐�΃p�X)
      lt_svf_argument.arg004  := cv_orgid;                                                          -- Org_id��
      lt_svf_argument.arg005  := lv_spool_op_edit;                                                  -- �t�@�C���X�v�[����w��I�v�V����
      lt_svf_argument.arg006  := lv_msg_op_edit ;                                                   -- NO DATA���b�Z�[�W�ݒ�I�v�V����
-- ADD START 2009/03/06
      lt_svf_argument.arg007  := cv_form_mode_4;                                                    -- �t�H�[���l���t�@�C���̃��[�h�I�v�V����
-- ADD END   2009/03/06
      --===============================
      -- �ǉ����o����(Condition)�̐ݒ�
      --===============================
-- UPD START 2009/03/06
--      IF ( ln_cond_cnt = 0 )THEN
--        -- �ǉ������������ꍇ�͗v��ID��������Ƃ��ĕҏW���Z�b�g���� 
--        -- Condition=[REQUEST_ID]=9999999
--        lv_cond_001 := cv_op_cond || cv_opv_cond1 || iv_request_id ;
--        lt_svf_argument.arg007  :=  lv_cond_001 ;
--      ELSE
--        -- �ǉ���������ł��݂�ꍇ�͂��̂܂܃Z�b�g����
--        lt_svf_argument.arg007  :=  lv_cond_001 ;                                                   --Condition=svf�σp�����[�^01
--        lt_svf_argument.arg008  :=  lv_cond_002 ;                                                   --Condition=svf�σp�����[�^02
--        lt_svf_argument.arg009  :=  lv_cond_003 ;                                                   --Condition=svf�σp�����[�^03
--        lt_svf_argument.arg010  :=  lv_cond_004 ;                                                   --Condition=svf�σp�����[�^04
--        lt_svf_argument.arg011  :=  lv_cond_005 ;                                                   --Condition=svf�σp�����[�^05
--        lt_svf_argument.arg012  :=  lv_cond_006 ;                                                   --Condition=svf�σp�����[�^06
--        lt_svf_argument.arg013  :=  lv_cond_007 ;                                                   --Condition=svf�σp�����[�^07
--        lt_svf_argument.arg014  :=  lv_cond_008 ;                                                   --Condition=svf�σp�����[�^08
--        lt_svf_argument.arg015  :=  lv_cond_009 ;                                                   --Condition=svf�σp�����[�^09
--        lt_svf_argument.arg016  :=  lv_cond_010 ;                                                   --Condition=svf�σp�����[�^10
--        lt_svf_argument.arg017  :=  lv_cond_011 ;                                                   --Condition=svf�σp�����[�^11
--        lt_svf_argument.arg018  :=  lv_cond_012 ;                                                   --Condition=svf�σp�����[�^12
--        lt_svf_argument.arg019  :=  lv_cond_013 ;                                                   --Condition=svf�σp�����[�^13
--        lt_svf_argument.arg020  :=  lv_cond_014 ;                                                   --Condition=svf�σp�����[�^14
--        lt_svf_argument.arg021  :=  lv_cond_015 ;                                                   --Condition=svf�σp�����[�^15
--      END IF;
      IF ( ln_cond_cnt = 0 )THEN
        -- �ǉ������������ꍇ�͗v��ID��������Ƃ��ĕҏW���Z�b�g���� 
        -- Condition=[REQUEST_ID]=9999999
        lv_cond_001 := cv_op_cond || cv_opv_cond1 || iv_request_id ;
        lt_svf_argument.arg008  :=  lv_cond_001 ;
      ELSE
        -- �ǉ���������ł��݂�ꍇ�͂��̂܂܃Z�b�g����
        lt_svf_argument.arg008  :=  lv_cond_001 ;                                                   --Condition=svf�σp�����[�^01
        lt_svf_argument.arg009  :=  lv_cond_002 ;                                                   --Condition=svf�σp�����[�^02
        lt_svf_argument.arg010  :=  lv_cond_003 ;                                                   --Condition=svf�σp�����[�^03
        lt_svf_argument.arg011  :=  lv_cond_004 ;                                                   --Condition=svf�σp�����[�^04
        lt_svf_argument.arg012  :=  lv_cond_005 ;                                                   --Condition=svf�σp�����[�^05
        lt_svf_argument.arg013  :=  lv_cond_006 ;                                                   --Condition=svf�σp�����[�^06
        lt_svf_argument.arg014  :=  lv_cond_007 ;                                                   --Condition=svf�σp�����[�^07
        lt_svf_argument.arg015  :=  lv_cond_008 ;                                                   --Condition=svf�σp�����[�^08
        lt_svf_argument.arg016  :=  lv_cond_009 ;                                                   --Condition=svf�σp�����[�^09
        lt_svf_argument.arg017  :=  lv_cond_010 ;                                                   --Condition=svf�σp�����[�^10
        lt_svf_argument.arg018  :=  lv_cond_011 ;                                                   --Condition=svf�σp�����[�^11
        lt_svf_argument.arg019  :=  lv_cond_012 ;                                                   --Condition=svf�σp�����[�^12
        lt_svf_argument.arg020  :=  lv_cond_013 ;                                                   --Condition=svf�σp�����[�^13
        lt_svf_argument.arg021  :=  lv_cond_014 ;                                                   --Condition=svf�σp�����[�^14
        lt_svf_argument.arg022  :=  lv_cond_015 ;                                                   --Condition=svf�σp�����[�^15
      END IF;
-- UPD END   2009/03/06
    --
    -- ****************************************** �e�X�g���Ɏg�p�����ǉ��������LOG�\�� ************************************************** --
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm14, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_001 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm15, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_002 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm16, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_003 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm17, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_004 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm18, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_005 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm19, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_006 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm20, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_007 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm21, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_008 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm22, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_009 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm23, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_010 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm24, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_011 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm25, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_012 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm26, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_013 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm27, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_014 , ' ') );
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, cv_add_cond_msg || RPAD(cv_token_v_prm28, cn_pad_plofile) ||cv_msg_part_mb || NVL(lv_cond_015 , ' ') );
    -- ************************************************************************************************************************************ --
    --
    END IF ;
    -- ��񃍃O�̏o��
    lv_step         := 'STEP 02.02.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_appl_name,
      iv_token_01     => cv_token_appl_name,
      iv_token_val01  => cv_svf_app
      );
    --
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_conc_name,
      iv_token_01     => cv_token_conc_name,
      iv_token_val01  => cv_svf_prog
      );
    --
    -- *******************************
    -- 2-3.SVF�R���J�����g�̎��s
    -- *******************************
    lv_step         := 'STEP 02.03.01';
    ln_svf_reqid := start_request(lt_svf_argument);
    --
    -- *******************************
    -- 2-4.SVF�R���J�����g�̎��s���f
    -- *******************************
    lv_step         := 'STEP 02.04.00';
    IF (ln_svf_reqid = 0 OR ln_svf_reqid IS NULL) THEN
      lv_step         := 'STEP 02.04.01';
      -- �Ԃ�l�̗v��ID��0��NULL�̏ꍇ�͋N���Ɏ��s���Ă���̂ŃG���[�Ƃ���B
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prog_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_svf_conc
        );
      --
      RAISE global_api_expt;
    --
    ELSE
      -- �N�����������Ă�ꍇ�́ACOMMIT���Ȃ���SVF�������Ȃ�
      lv_step         := 'STEP 02.04.02';
      COMMIT;
      -- �R���J�����g�̋N�����b�Z�[�W���o�͂���
      --
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_info_request_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_svf_conc,
        iv_token_02     => cv_token_id,
        iv_token_val02  => TO_CHAR(ln_svf_reqid)
        );
    --
    END IF;
    --
    -- ==============================================================
    -- 3.SVF�R���J�����g�̏I���҂�
    -- ==============================================================
    -- 3-1.SVF�R���J�����g�̃��N�G�X�gID��p���ăR���J�����g�̏I���҂����s��
    lv_step         := 'STEP 03.01.00';
    -- �R���J�����g�̑ҋ@
    lb_ret_bool := FND_CONCURRENT.WAIT_FOR_REQUEST(
        request_id          =>  ln_svf_reqid              ,
        interval            =>  TO_NUMBER(lv_svf_interval),
        max_wait            =>  TO_NUMBER(lv_svf_maxwait) ,
        phase               =>  lv_phase                  ,
        status              =>  lv_status                 ,
        dev_phase           =>  lv_dev_phase              ,
        dev_status          =>  lv_dev_status             ,
        message             =>  lv_message
        );
--
    -- ==============================================================
    -- 4.SVF�R���J�����g�̎��s���ʊm�F
    -- ==============================================================
    -- *******************************
    -- 4-1.���s���ʂ̔��f
    -- *******************************
    IF (lb_ret_bool = cb_TURE ) THEN
      lv_step         := 'STEP 04.01.00';
      -- �ҋ@�����������̏ꍇ
      -- ���s���ʂ̔��f(�v���t�F�[�Y�Ɨv���X�e�[�^�X���)
      IF (lv_dev_phase = cv_phase_comp AND lv_dev_status = cv_status_nomal ) THEN
        lv_step         := 'STEP 04.01.01';
        -- �t�F�[�Y�F�����E�X�e�[�^�X�F����̏ꍇ�ɂ͐���I���ƌ��Ȃ�
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_info_request_end,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_svf_reqid)
          );
      --
      ELSE
        lv_step         := 'STEP 04.01.02';
        -- ���튮���ȊO�̏ꍇ�̓G���[�Ƃ��ď�������
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_exec_conc,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_svf_reqid),
          iv_token_02     => cv_token_phase,
          iv_token_val02  => lv_phase,
          iv_token_03     => cv_token_staus,
          iv_token_val03  => lv_status
          );
        --
        RAISE global_api_expt;
      --
      END IF;
    --
    ELSE
      -- �ҋ@���������s�̏ꍇ
      lv_step         := 'STEP 04.01.99';
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_process,
        iv_token_01     => cv_token_proc,
        iv_token_val01  => cv_token_v_wait_svf
        );
      --
      RAISE global_api_expt;
      --
    END IF;
--
    -- ==============================================================
    -- 5.�t�@�C���]���R���J�����g�̋N��
    -- ==============================================================
    -- *******************************
    -- 5-1.�t�@�C���]���R���J�����g�p�����[�^�̍\���̂ւ̐ݒ�
    -- *******************************
    lv_step         := 'STEP 05.01.01';
    lt_ftp_argument.appl    := cv_ftp_app         ;                                               -- �A�v���P�[�V������
    lt_ftp_argument.prog    := cv_ftp_prog        ;                                               -- �v���O������
    lt_ftp_argument.arg001  := lv_svf_host_name   ;                                               -- FTP��̃z�X�g��
    lt_ftp_argument.arg002  := lv_svf_login_user  ;                                               -- FTP�����O�C�����[�U
    lt_ftp_argument.arg003  := lv_svf_login_pass  ;                                               -- FTP�����O�C���p�X���[�h
    -- SHELL�R���J�����g�p�Ƀp�X��\\��/�ɒu��������
    lt_ftp_argument.arg004  := REPLACE(lv_svf_spool_dir, cv_part_bs, cv_part_sl) ;                -- SVF�T�[�oPDF�t�@�C���i�[��
    lt_ftp_argument.arg005  := lv_ebs_put_fpath   ;                                               -- EBS�T�[�o�i�[PDF�t�@�C����΃p�X
    lt_ftp_argument.arg006  := iv_file_name       ;                                               -- PDF�t�@�C����
    lt_ftp_argument.arg007  := lv_ebs_temp_dir    ;                                               -- EBS�T�[�oTemp�t�@�C���i�[��
    lt_ftp_argument.arg008  := lv_ebs_temp_file   ;                                               -- EBS�T�[�oFTP���OTemp�t�@�C����
    -- ��񃍃O�̏o��
    lv_step         := 'STEP 05.01.02';
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_appl_name,
      iv_token_01     => cv_token_appl_name,
      iv_token_val01  => cv_ftp_app
      );
    --
    output_log(
      iv_appl         => cv_applcation_xxccp,
      iv_name         => cv_info_conc_name,
      iv_token_01     => cv_token_conc_name,
      iv_token_val01  => cv_ftp_prog
      );
    --
    -- *******************************
    -- 5-2.�t�@�C���]���R���J�����g�̎��s
    -- *******************************
    lv_step         := 'STEP 05.02.01';
    ln_ftp_reqid := start_request(lt_ftp_argument);
--
    -- *******************************
    -- 5-3.�t�@�C���]���R���J�����g�̎��s���f
    -- *******************************
    lv_step         := 'STEP 05.03.00';
    IF (ln_ftp_reqid = 0 OR ln_ftp_reqid IS NULL) THEN
      lv_step         := 'STEP 05.03.01';
      -- �Ԃ�l�̗v��ID��0��NULL�̏ꍇ�͋N���Ɏ��s���Ă���̂ŃG���[�Ƃ���B
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_prog_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_ftp_conc
        );
      --
      RAISE global_api_expt;
    --
    ELSE
      -- �N�����������Ă�ꍇ�́ACOMMIT���Ȃ��ƃt�@�C���]���R���J�����g�������Ȃ�
      lv_step         := 'STEP 05.03.02';
      COMMIT;
      -- �R���J�����g�̋N�����b�Z�[�W���o�͂���
      --
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_info_request_start,
        iv_token_01     => cv_token_prog,
        iv_token_val01  => cv_token_v_ftp_conc,
        iv_token_02     => cv_token_id,
        iv_token_val02  => TO_CHAR(ln_ftp_reqid)
        );
    --
    END IF;
--
    -- ==============================================================
    -- 6.�t�@�C���]���R���J�����g�̏I���҂�
    -- ==============================================================
    -- 6-1.�t�@�C���]���R���J�����g�̃��N�G�X�gID��p���ăR���J�����g�̏I���҂����s��
    lv_step         := 'STEP 06.01.00';
    -- �R���J�����g�̑ҋ@
    lb_ret_bool := FND_CONCURRENT.WAIT_FOR_REQUEST(
        request_id          =>  ln_ftp_reqid              ,
        interval            =>  TO_NUMBER(lv_ftp_interval),
        max_wait            =>  TO_NUMBER(lv_ftp_maxwait) ,
        phase               =>  lv_phase                  ,
        status              =>  lv_status                 ,
        dev_phase           =>  lv_dev_phase              ,
        dev_status          =>  lv_dev_status             ,
        message             =>  lv_message
        );
--
    -- ==============================================================
    -- 7.�t�@�C���]���R���J�����g�̎��s���ʊm�F
    -- ==============================================================
    -- *******************************
    -- 7-1.���s���ʂ̔��f
    -- *******************************
    IF (lb_ret_bool = cb_TURE ) THEN
      lv_step         := 'STEP 07.01.00';
      -- �ҋ@�����������̏ꍇ
      -- ���s���ʂ̔��f(�v���t�F�[�Y�Ɨv���X�e�[�^�X���)
      IF (lv_dev_phase = cv_phase_comp AND lv_dev_status = cv_status_nomal ) THEN
        lv_step         := 'STEP 07.01.01';
        -- �t�F�[�Y�F�����E�X�e�[�^�X�F����̏ꍇ�ɂ͐���I���ƌ��Ȃ�
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_info_request_end,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_ftp_reqid)
          );
      --
      ELSE
        lv_step         := 'STEP 07.01.02';
        -- ���튮���ȊO�̏ꍇ�̓G���[�Ƃ��ď�������
        output_log(
          iv_appl         => cv_applcation_xxccp,
          iv_name         => cv_err_exec_conc,
          iv_token_01     => cv_token_req_id,
          iv_token_val01  => TO_CHAR(ln_ftp_reqid),
          iv_token_02     => cv_token_phase,
          iv_token_val02  => lv_phase,
          iv_token_03     => cv_token_staus,
          iv_token_val03  => lv_status
          );
        --
        RAISE global_api_expt;
      --
      END IF;
    --
    ELSE
      -- �ҋ@���������s�̏ꍇ
      lv_step         := 'STEP 07.01.99';
      output_log(
        iv_appl         => cv_applcation_xxccp,
        iv_name         => cv_err_process,
        iv_token_01     => cv_token_proc,
        iv_token_val01  => cv_token_v_wait_ftp
        );
      --
      RAISE global_api_expt;
    --
    END IF;
  -- ����I���ŏ����𔲂���
    ov_retcode  := cv_status_normal;
--
  EXCEPTION
    -- �p�����[�^�s���̏ꍇ
    WHEN prm_error_expt THEN
      -- �G���[���b�Z�[�W�̏o��
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             );
-- Del Start 2009-03-05
--      ROLLBACK;
-- Del End   2009-03-05
    --
    WHEN date_accession_expt THEN
      -- �G���[���b�Z�[�W�̏o��
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             ); 
-- Del Start 2009-03-05
--      ROLLBACK;
-- Del End   2009-03-05
    --
    WHEN global_api_expt THEN
      -- �G���[���b�Z�[�W�̏o��
      ov_errbuf   := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || SQLERRM , 1, 5000);
      ov_retcode  := cv_status_error;
      ov_errmsg   := xxccp_common_pkg.get_msg(iv_application => cv_applcation_xxccp,
                                              iv_name        => cv_err_end
                                             );
-- Del Start 2009-03-05
--      ROLLBACK;
-- Del End   2009-03-05
    --
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
  END submit_svf_request;
  --
  --
  /**********************************************************************************
   * Function  Name   : no_data_msg
   * Description      : SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)
   ***********************************************************************************/
  FUNCTION no_data_msg
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxccp_svfcommon_pkg.no_data_msg';
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'�o�͑Ώۂ͂���܂���B');
    RETURN xxccp_common_pkg.set_status_normal;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
  END no_data_msg;
  --
END xxccp_svfcommon_pkg;
/
