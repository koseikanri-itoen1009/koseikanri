create or replace
PACKAGE BODY XXCFF003A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A07C(body)
 * Description      : ���[�X�_��E�����A�b�v���[�h
 * MD.050           : MD050_CFF_003_A07_���[�X�_��E�����A�b�v���[�h.doc
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                       (A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hI/F�擾    (A-2)
 *  devide_item            �f���~�^�������ڕ���           (A-3)
 *  chk_err_disposion      �z�񍀖ڃ`�F�b�N����           (A-4)
 *  ins_cont_work          �A�b�v���[�h�U������           (A-5)
 *                         �G���[���菈��                 (A-6)
 *  chk_rept_adjust        ܰ�̧�ُd���E��������������    (A-7)
 *  chk_cont_header        �_�񃏁[�N�`�F�b�N����         (A-8)
 *  chk_cont_line          �_�񖾍׃��[�N�`�F�b�N����     (A-9)
 *  chk_obj_header         �������[�N�`�F�b�N����         (A-10)
 *                         �G���[���菈��                 (A-11)
 *  get_contract_info      ���[�X�_�񃏁[�N���o           (A-12)
 *  set_upload_item        �A�b�v���[�h���ڕҏW           (A-13)
 *  jdg_lease_kind         ���[�X��ޔ���                 (A-14)
 *  insert_ob_hed          ���[�X�����V�K�o�^             (A-15)
 *  insert_co_hed          ���[�X�_��V�K�o�^             (A-16)
 *  insert_co_lin          ���[�X�_�񖾍אV�K�o�^         (A-17)
 *  ins_object_histories   ���[�X��������o�^             (A-18)
 *  xxcff003a05c           ���[�X�x���v��쐬             (A-19)
 *  submain                �I������                       (A-20)
 *  submain_main           ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor          Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/22     1.0   SCS�E��S��     �V�K�쐬
 *  2009/2/24     1.1   SCS�E��S��     [��QCFF_056] �R���J�����g�p�����[�^��
 *                                      �b�r�u�t�@�C�����̕\���ύX*
 *  2009/03/02    1.2   SCS�E��S��     [��QCFF_068] �Ɩ��G���[���b�Z�[�W��
 *                                      �o�̓t�@�C���ɏo�͂���B
 *  2009/05/14    1.3   SCS�E��S��     [��QT1_0783]���ʂ�NULL�̏ꍇ�́A1��ݒ肷��B
 *  2009/05/18    1.4   SCS�����r��     [��QT1_0721]�f���~�^����������f�[�^�i�[�z���
 *                                      ������ύX
 *                                      ����ݒu�ꏊ�Ə���ݒu��̊i�[�ϐ����C��
 *  2009/05/27    1.5   SCS�E��S��     [��QT1_1225] �ŋ��R�[�h�}�X�^��
 *                                      ���}�X�^�`�F�b�N�̍ہA�L�����̏�����ǉ�����B
 *  2009/11/27    1.6X  SCS�n�ӊw       �y�b��Ή��Łz
 *                                      �ڍs�R��o�^�̂��߁A�`�F�b�N���͂����B
 *                                      �E�_��ԍ��̔��p�`�F�b�N
 *                                      �E�I�����ƍŏI�x�����̑召�`�F�b�N
 *  2010/01/07    1.7   SCS�n�ӊw       Ver.1.6X�y�b��Ή��Łz�̑Ή��͍P�v�Ή��Ƃ���B
 *                                      [E_�{��_00229]
 *                                        ���͍��ځu���z���[�X�T���z�i�Ŕ��j�v���u�ێ��Ǘ���p�����z�i���z�j�v�ύX�B
 *                                        �u�ێ��Ǘ���p�����z�i���z�j�v���猎�z���z�����Z���i�~�����؎̂āj�A
 *                                        �[�����z������̌��z�T���z�Œ�������B
 *  2013/07/05    1.8   SCSK����O��    �yE_�{�ғ�_10871�z(����ő��őΉ�)
 *  2016/08/15    1.9   SCSK�m�� �d�l   �yE_�{�ғ�_13658�z���̋@�ϗp�N���ύX�Ή�
 *  2018/03/27    1.10  SCSK��� ��     �yE_�{�ғ�_14830�zIFRS���[�X���Y�Ή�
 *  2018/05/25    1.11  SCSK�X ����     �yE_�{�ғ�_15112�zIFRS��Q�Ή�
 *  2018/09/10    1.12  SCSK���X�؍G�V  �yE_�{�ғ�_14830�z�ǉ��Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn    CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg        VARCHAR2(2000);
  gv_sep_msg        VARCHAR2(2000);
  gv_exec_user      VARCHAR2(100);
  gv_conc_name      VARCHAR2(30);
  gv_conc_status    VARCHAR2(30);
  gn_target_cnt     NUMBER;                          -- �Ώی���
  gn_normal_cnt     NUMBER;                          -- ���팏��
  gn_error_cnt      NUMBER;                          -- �G���[����
  gn_warn_cnt       NUMBER;                          -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
  cv_msg_part       CONSTANT VARCHAR2(1)    := ':';  -- �R����
  cv_msg_cont       CONSTANT VARCHAR2(1)    := '.';  -- �s���I�h
  --
  cv_const_n        CONSTANT VARCHAR2(1)    := 'N';  -- 'N'
  cv_const_y        CONSTANT VARCHAR2(1)    := 'Y';  -- 'Y'
  --
  cv_null_byte      CONSTANT VARCHAR2(1)    := '';   -- ''
  --
  cv_csv_name       CONSTANT VARCHAR2(3)    := 'CSV'; -- CSV
  cv_csv_delim      CONSTANT VARCHAR2(1)    := ',';   -- CSV��؂蕶��
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
  
  lock_expt              EXCEPTION;     -- ���b�N�擾�G���[
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  --
--################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF003A07C'; -- �p�b�P�[�W��
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
--
  cv_look_type       CONSTANT VARCHAR2(100) := 'XXCFF1_CONT_OBJ_UPLOAD'; -- LOOKUP TYPE
--
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';      --�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';         --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- ���b�Z�[�W�ԍ�
-- Ver.1.9 DEL Start
--  -- ���͕K�{�G���[
--  cv_msg_cff_00005   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00005';
-- Ver.1.9 DEL End
  -- �_��ԍ����݃G���[
  cv_msg_cff_00044   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00044';
  -- �_��ԍ��d���G���[
  cv_msg_cff_00119   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00119';
  -- �_��s�����G���[
  cv_msg_cff_00127   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00127';
  -- �_����Ó����G���[
  cv_msg_cff_00083   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00083';
  -- ���E�l�G���[
  cv_msg_cff_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00013';
  -- ���[�X�J�n���Ó����G���[
  cv_msg_cff_00043   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00043';
  -- �x���񐔋��E�l�G���[
  cv_msg_cff_00016   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00016';
  -- �x���񐔓��͒l�G���[
  cv_msg_cff_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00014';
-- Ver.1.9 DEL Start
--  -- �p�x�G���[
--  cv_msg_cff_00023   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00023';
-- Ver.1.9 DEL End
  -- ����x�����Ó����G���[�i���[�X�J�n���O�j
  cv_msg_cff_00022   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00022';
  -- 2��ڎx�����Ó����G���[�i����x�����O�j
  cv_msg_cff_00056   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00056';
  -- 2��ڎx�����Ó����G���[�i����x�������X���ȍ~�j
  cv_msg_cff_00055   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00055';
-- Ver.1.9 DEL Start
--  -- �x�����Ó����G���[�i�ŏI�x�����j
--  cv_msg_cff_00031   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00031';
-- Ver.1.9 DEL End
  -- �_��}�ԏd���G���[
  cv_msg_cff_00067   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00067';
  -- �_��}�ԕs�����G���[
  cv_msg_cff_00068   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00068';
-- Ver.1.9 DEL Start
--  -- �����R�[�h���o�^�G���[
--  cv_msg_cff_00075   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00075';
-- Ver.1.9 DEL End
  -- �����R�[�h���݃G���[
  cv_msg_cff_00160   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00160';
  -- ���[�N�e�[�u�������R�[�h�d���G���[
  cv_msg_cff_00145   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00145';
  -- ���Y��ރ}�X�^�G���[
  cv_msg_cff_00069   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00069';
-- Ver.1.9 DEL Start
--  -- ���b�N�G���[
--  cv_msg_cff_00007   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';
-- Ver.1.9 DEL End
  -- �G���[�Ώ�
  cv_msg_cff_00009   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00009';
  -- ���[�X�_��G���[�Ώ�
  cv_msg_cff_00146   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00146';
  -- ���[�X�_�񖾍׃G���[�Ώ�
  cv_msg_cff_00147   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00147';
  -- ���[�X��ʃG���[
  cv_msg_cff_00122   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00122';
  -- �ϗp�N���G���[
  cv_msg_cff_00149   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00149';
-- 2018/05/25 Ver1.11 Mori DEL Start
--  -- �T���z�G���[
--  cv_msg_cff_00034   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00034';
-- 2018/05/25 Ver1.11 Mori DEL End
-- Ver.1.9 DEL Start
--  -- �ă��[�X�񐔕s��v�G���[
--  cv_msg_cff_00148   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00148';
-- Ver.1.9 DEL End
  -- �_�񖾍׌����G���[
  cv_msg_cff_00150   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00150';
  -- ���l�_���G���[(0����)
  cv_msg_cff_00117   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00117';
-- Ver.1.9 DEL Start
--  -- ���t�_���G���[
--  cv_msg_cff_00118   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00118';
-- Ver.1.9 DEL End
  -- �֑������G���[
  cv_msg_cff_00138   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00138';
  -- �f�[�^�ϊ��G���[
  cv_msg_cff_00110   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00110';
-- Ver.1.9 DEL Start
--  -- 2��ڎx�����Ó����G���[�i����x�������X�N�ȍ~�j
--  cv_msg_cff_00177   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00177';
-- Ver.1.9 DEL End
  -- �A�b�v���[�h�����o�̓��b�Z�[�W  
  cv_msg_cff_00167   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00167'; 
  -- ���p�p�����G���[
  cv_msg_cff_00179   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00179';
  -- ���ʊ֐��G���[
  cv_msg_cff_00094   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';
  -- ���ʊ֐����b�Z�[�W
  cv_msg_cff_00095   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';
   -- ���ڒl�Ó����`�F�b�N�G���[
  cv_msg_cff_00124   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00124';
-- Ver.1.9 DEL Start
--  -- �Ώی������b�Z�[�W
--  cv_msg_cff_90000   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90000';
--  -- �����������b�Z�[�W
--  cv_msg_cff_90001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90001';
--  -- �G���[�������b�Z�[�W
--  cv_msg_cff_90002   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90002';
--  -- ����I�����b�Z�[�W
--  cv_msg_cff_90004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90004';
--  -- �G���[�I���S���[���o�b�N���b�Z�[�W
--  cv_msg_cff_90006   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90006';
--  -- �R���J�����g���̓p�����[�^���b�Z�[�W
--  cv_msg_cff_90009   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-90009';
-- Ver.1.9 DEL End
-- 2018/03/27 Ver1.10 Otsuka ADD Start
  cv_msg_cff_00282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00282';   -- ���ό����w�����z�G���[
  cv_msg_cff_00283   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00283';   -- �@��ϗp�N���G���[
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
  -- ���b�Z�[�W�g�[�N��
  cv_tk_cff_00005_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- �J�����_����
-- Ver.1.9 DEL Start
--  cv_tk_cff_00007_01 CONSTANT VARCHAR2(15)  := 'TABLE_NAME';  -- �e�[�u����
-- Ver.1.9 DEL End
  cv_tk_cff_00009_01 CONSTANT VARCHAR2(15)  := 'CONTRACT_NO'; -- �_��ԍ�
  cv_tk_cff_00009_02 CONSTANT VARCHAR2(15)  := 'L_COMPANY';   -- ���[�X���
  cv_tk_cff_00009_03 CONSTANT VARCHAR2(15)  := 'SPEC_NO';     -- �_��}��
  cv_tk_cff_00009_04 CONSTANT VARCHAR2(15)  := 'OBJECT_NO';   -- �����R�[�h
  cv_tk_cff_00013_01 CONSTANT VARCHAR2(15)  := 'INPUT';       -- �J�����_����
  cv_tk_cff_00013_02 CONSTANT VARCHAR2(15)  := 'MINVALUE';    -- ���E�l�G���[�͈̔�(MIN)
  cv_tk_cff_00016_01 CONSTANT VARCHAR2(15)  := 'MINVALUE';    -- ���E�l�G���[�͈̔�(MIN)
  cv_tk_cff_00016_02 CONSTANT VARCHAR2(15)  := 'MAXVALUE';    -- ���E�l�G���[�͈̔�(MAX)
  cv_tk_cff_00094_01 CONSTANT VARCHAR2(15)  := 'FUNC_NAME';   -- ���ʊ֐�
  cv_tk_cff_00095_01 CONSTANT VARCHAR2(15)  := 'ERR_MSG';     -- �G���[���b�Z�[�W
  cv_tk_cff_00101_01 CONSTANT VARCHAR2(15)  := 'APPL_NAME';   -- �A�v���P�[�V������
  cv_tk_cff_00101_02 CONSTANT VARCHAR2(15)  := 'INFO';        -- �G���[���b�Z�[�W
  cv_tk_cff_90000_01 CONSTANT VARCHAR2(15)  := 'COUNT';       -- �����Ώ�
-- Ver.1.9 DEL Start
--  cv_tk_cff_90009_01 CONSTANT VARCHAR2(15)  := 'PARAM_NAME';  -- �R���J�����g���̓p�����[�^��
--  cv_tk_cff_90009_02 CONSTANT VARCHAR2(15)  := 'PARAM_VAL';   -- �R���J�����g���̓p�����[�^�l
-- Ver.1.9 DEL End
  cv_tk_cff_00124_01 CONSTANT VARCHAR2(15)  := 'COLUMN_NAME'; -- �J�����_����
  cv_tk_cff_00124_02 CONSTANT VARCHAR2(15)  := 'COLUMN_INFO'; -- �J������
  cv_tk_cff_00167_01 CONSTANT VARCHAR2(15)  := 'FILE_NAME';   -- �t�@�C�����g�[�N��
  cv_tk_cff_00167_02 CONSTANT VARCHAR2(15)  := 'CSV_NAME';    -- CSV�t�@�C�����g�[�N��
--
  -- �g�[�N��
-- Ver.1.9 DEL Start
  cv_msg_cff_50014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50014';  -- ���[�X�����e�[�u��
-- Ver.1.9 DEL End
  cv_msg_cff_50040   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50040';  -- �_��ԍ�
-- Ver.1.9 DEL Start
--  cv_msg_cff_50134   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50134';  -- ���[�X�_���
-- Ver.1.9 DEL End
  cv_msg_cff_50041   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50041';  -- ���[�X���
  cv_msg_cff_50042   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50042';  -- ���[�X�敪
  cv_msg_cff_50043   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50043';  -- ���[�X���
-- Ver.1.9 DEL Start
--  cv_msg_cff_50044   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50044';  -- �ă��[�X��
-- Ver.1.9 DEL End
  cv_msg_cff_50045   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50045';  -- ����
-- Ver.1.9 DEL Start
--  cv_msg_cff_50046   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50046';  -- ���[�X�J�n��
-- Ver.1.9 DEL End
  cv_msg_cff_50047   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50047';  -- �x����
  cv_msg_cff_50048   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50048';  -- �p�x
-- Ver.1.9 DEL Start
--  cv_msg_cff_50049   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50049';  -- �N��
--  cv_msg_cff_50051   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50051';  -- ���[�X�I����
--  cv_msg_cff_50052   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50052';  -- ����x����
--  cv_msg_cff_50053   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50053';  -- 2��ڎx����
--  cv_msg_cff_50054   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50054';  -- 3��ڈȍ~�x����
--  cv_msg_cff_50055   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50055';  -- ��p�v��J�n��v����
--  cv_msg_cff_50056   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50056';  -- ���[�X�_��e�[�u��
--  cv_msg_cff_50058   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50058';  -- �_��}��
-- Ver.1.9 DEL End
  cv_msg_cff_50148   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50148';  -- �ŋ��R�[�h
  cv_msg_cff_50149   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50149';  -- ����ݒu��
  cv_msg_cff_50150   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50150';  -- ����ݒu�ꏊ
  cv_msg_cff_50108   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50108';  -- ���񌎊z���[�X��
  cv_msg_cff_50109   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50109';  -- �Q��ڈȍ~���z���[�X��
  cv_msg_cff_50156   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50156';  -- ���񌎊z����Ŋz
  cv_msg_cff_50157   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50157';  -- �Q��ڈȍ~����Ŋz
  cv_msg_cff_50158   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50158';  -- ���z���[�X�T���z
-- Ver.1.9 DEL Start
--  cv_msg_cff_50159   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50159';  -- ���z���[�X�T������Ŋz
-- Ver.1.9 DEL End
  cv_msg_cff_50064   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50064';  -- ���ό����w���w�����z
  cv_msg_cff_50032   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50032';  -- �@��ϗp�N��
  cv_msg_cff_50010   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50010';  -- �����R�[�h
-- Ver.1.9 DEL Start
--  cv_msg_cff_50072   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50072';  -- ���Y���
-- Ver.1.9 DEL End
  cv_msg_cff_50011   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50011';  -- �Ǘ�����R�[�h
  cv_msg_cff_50012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50012';  -- �{��/�H��
  cv_msg_cff_50184   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50184';  -- �����ԍ�
  cv_msg_cff_50177   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50177';  -- ���[�J�[��
  cv_msg_cff_50178   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50178';  -- �@��
  cv_msg_cff_50179   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50179';  -- �@��
  cv_msg_cff_50180   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50180';  -- �N��
  cv_msg_cff_50181   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50181';  -- ����
  cv_msg_cff_50182   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50182';  -- �ԑ�ԍ�
  cv_msg_cff_50183   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50183';  -- �o�^�ԍ�
  cv_msg_cff_50187   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50187';  -- ���[�X�_��E����
--
-- Ver.1.9 DEL Start
--  cv_msg_cff_50121   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50121';  -- �R���J�����g���̓p�����[�^��
--  cv_msg_cff_50122   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50122';  -- �t�@�C��ID
-- Ver.1.9 DEL End
  cv_msg_cff_50130   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- ��������
  cv_msg_cff_50131   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50131';  -- BLOB�f�[�^�ϊ��p�֐�
--
-- 2018/03/27 Ver1.10 Otsuka ADD Start
  -- ���[�X����
  cv_lease_cls_chk1  CONSTANT VARCHAR2(1)  := '1';        -- ���[�X���茋�ʁF1
  cv_msg_cff_50323   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50323';  -- ���[�X���菈��
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �z��ϐ�
  --[��QT1_0721]MOD START
  --TYPE load_data_rtype  IS TABLE OF VARCHAR2(200)
  TYPE load_data_rtype  IS TABLE OF VARCHAR2(600)
  --[��QT1_0721]MOD END
    INDEX BY binary_integer;       
  TYPE load_name_rtype  IS TABLE OF VARCHAR2(50)
    INDEX BY binary_integer;       
  TYPE load_len_rtype   IS TABLE OF NUMBER(4)
    INDEX BY binary_integer;       
  TYPE load_dec_rtype   IS TABLE OF NUMBER(2)
    INDEX BY binary_integer;       
  TYPE load_null_rtype  IS TABLE OF VARCHAR2(10)
    INDEX BY binary_integer;       
  TYPE load_attr_rtype  IS TABLE OF NUMBER(1)
    INDEX BY binary_integer;       
--
  -- ���[�X�_�񃏁[�N�Ώۃf�[�^���R�[�h�^
  TYPE contract_info_rtype IS RECORD(
    contract_number            xxcff_cont_headers_work.contract_number%TYPE
   ,lease_class                xxcff_cont_headers_work.lease_class%TYPE
   ,lease_type                 xxcff_cont_headers_work.lease_type%TYPE
   ,lease_company              xxcff_cont_headers_work.lease_company%TYPE
   ,re_lease_times             xxcff_cont_headers_work.re_lease_times%TYPE
   ,comments                   xxcff_cont_headers_work.comments%TYPE
   ,contract_date              xxcff_cont_headers_work.contract_date%TYPE
   ,payment_frequency          xxcff_cont_headers_work.payment_frequency%TYPE
   ,payment_type               xxcff_cont_headers_work.payment_type%TYPE
   ,lease_start_date           xxcff_cont_headers_work.lease_start_date%TYPE
   ,first_payment_date         xxcff_cont_headers_work.first_payment_date%TYPE
   ,second_payment_date        xxcff_cont_headers_work.second_payment_date%TYPE
   ,contract_line_num          xxcff_cont_lines_work.contract_line_num%TYPE
   ,lease_company_line         xxcff_cont_lines_work.lease_company%TYPE
   ,first_charge               xxcff_cont_lines_work.first_charge%TYPE
   ,first_tax_charge           xxcff_cont_lines_work.first_tax_charge%TYPE
   ,second_charge              xxcff_cont_lines_work.second_charge%TYPE
   ,second_tax_charge          xxcff_cont_lines_work.second_tax_charge%TYPE
   ,first_deduction            xxcff_cont_lines_work.first_deduction%TYPE
   ,first_tax_deduction        xxcff_cont_lines_work.first_tax_deduction%TYPE
   --ADD 2010/01/07 START
   ,second_deduction           xxcff_cont_lines_work.first_deduction%TYPE
   --ADD 2010/01/07 END
   ,estimated_cash_price       xxcff_cont_lines_work.estimated_cash_price%TYPE
   ,life_in_months             xxcff_cont_lines_work.life_in_months%TYPE
   ,lease_kind                 xxcff_cont_lines_work.lease_kind%TYPE
   ,asset_category             xxcff_cont_lines_work.asset_category%TYPE
   ,first_installation_address xxcff_cont_lines_work.first_installation_address%TYPE
   ,first_installation_place   xxcff_cont_lines_work.first_installation_place%TYPE 
   ,object_header_id           xxcff_cont_lines_work.object_header_id%TYPE
   ,tax_code                   xxcff_cont_headers_work.tax_code%TYPE
   ,object_code                xxcff_cont_obj_work.object_code%TYPE
   ,po_number                  xxcff_cont_obj_work.po_number%TYPE
   ,registration_number        xxcff_cont_obj_work.registration_number%TYPE
   ,age_type                   xxcff_cont_obj_work.age_type%TYPE
   ,model                      xxcff_cont_obj_work.model%TYPE
   ,serial_number              xxcff_cont_obj_work.serial_number%TYPE
   ,quantity                   xxcff_cont_obj_work.quantity%TYPE
   ,manufacturer_name         xxcff_cont_obj_work.manufacturer_name%TYPE
   ,department_code            xxcff_cont_obj_work.department_code%TYPE
   ,owner_company              xxcff_cont_obj_work.owner_company%TYPE
   ,chassis_number             xxcff_cont_obj_work.chassis_number%TYPE
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����������
  gr_init_rec              xxcff_common1_pkg.init_rtype;
  -- ���[�X�_�񃏁[�N���
  gr_contract_info_rec     contract_info_rtype;
  -- ���[�X�_����
  gr_cont_hed_rec          xxcff_common4_pkg.cont_hed_data_rtype;
  -- ���[�X�_�񖾍׏��
  gr_cont_line_rec         xxcff_common4_pkg.cont_lin_data_rtype;
  -- ���[�X�����A�������
  gr_object_data_rec       xxcff_common3_pkg.object_data_rtype;
--
  -- ���[�X�_�񍀖�
  gn_seqno                 xxcff_cont_headers_work.seqno%TYPE;
  gv_contract_number       xxcff_cont_headers_work.contract_number%TYPE;
  gv_lease_class           xxcff_cont_headers_work.lease_class%TYPE;
  gv_lease_type            xxcff_cont_headers_work.lease_type%TYPE;
  gv_lease_company         xxcff_cont_headers_work.lease_company%TYPE;
  gn_re_lease_times        xxcff_cont_headers_work.re_lease_times%TYPE;
  gv_comments              xxcff_cont_headers_work.comments%TYPE;
  gd_contract_date         xxcff_cont_headers_work.contract_date%TYPE;
  gn_payment_frequency     xxcff_cont_headers_work.payment_frequency%TYPE;
  gv_payment_type          xxcff_cont_headers_work.payment_type%TYPE;
  gd_lease_start_date      xxcff_cont_headers_work.lease_start_date%TYPE;
  gd_first_payment_date    xxcff_cont_headers_work.first_payment_date%TYPE;
  gd_second_payment_date   xxcff_cont_headers_work.second_payment_date%TYPE;
  gv_tax_code              xxcff_cont_headers_work.tax_code%TYPE;
--
  -- ���[�X�_�񖾍׍���
  gn_seqno_line            xxcff_cont_lines_work.seqno%TYPE; 
  gv_contract_number_line  xxcff_cont_lines_work.contract_number%TYPE; 
  gv_contract_line_num     xxcff_cont_lines_work.contract_line_num%TYPE;
  gv_lease_company_line    xxcff_cont_lines_work.lease_company%TYPE;
  gn_first_charge          xxcff_cont_lines_work.first_charge%TYPE;
  gn_first_tax_charge      xxcff_cont_lines_work.first_tax_charge%TYPE; 
  gn_second_charge         xxcff_cont_lines_work.second_charge%TYPE; 
  gn_second_tax_charge     xxcff_cont_lines_work.second_tax_charge%TYPE; 
  gn_first_deduction       xxcff_cont_lines_work.first_deduction%TYPE; 
  gn_first_tax_deduction   xxcff_cont_lines_work.first_tax_deduction%TYPE; 
  gn_estimated_cash_price  xxcff_cont_lines_work.estimated_cash_price%TYPE; 
  gn_life_in_months        xxcff_cont_lines_work.life_in_months%TYPE; 
  gv_object_code           xxcff_cont_lines_work.object_code%TYPE; 
  gv_lease_kind            xxcff_cont_lines_work.lease_kind%TYPE; 
  gv_asset_category        xxcff_cont_lines_work.asset_category%TYPE; 
  gv_first_inst_address    xxcff_cont_lines_work.first_installation_address%TYPE; 
  gv_first_inst_place      xxcff_cont_lines_work.first_installation_place%TYPE; 
--  
  -- ���[�X��������
  gn_seqno_obj             xxcff_cont_obj_work.seqno%TYPE; 
  gv_po_number             xxcff_cont_obj_work.po_number%TYPE;
  gv_registration_number   xxcff_cont_obj_work.registration_number%TYPE;
  gv_age_type              xxcff_cont_obj_work.age_type%TYPE;
  gv_model                 xxcff_cont_obj_work.model%TYPE;
  gv_serial_number         xxcff_cont_obj_work.serial_number%TYPE;
  gn_quantity              xxcff_cont_obj_work.quantity%TYPE;
  gv_manufacturer_name     xxcff_cont_obj_work.manufacturer_name%TYPE;
  gv_department_code       xxcff_cont_obj_work.department_code%TYPE;
  gv_owner_company         xxcff_cont_obj_work.owner_company%TYPE;
  gv_chassis_number        xxcff_cont_obj_work.chassis_number%TYPE;
--
  gr_file_data_tbl         xxccp_common_pkg2.g_file_data_tbl;        -- �t�@�C���A�b�v���[�h�f�[�^�i�[�z��
  gr_lord_data_tab         load_data_rtype;                          -- �������ڕ�����f�[�^�i�[�z��
  gr_lord_name_tab         load_name_rtype;                          -- �������ڕ������ږ��i�[�z��
  gr_lord_len_tab          load_len_rtype;                           -- �������ڕ������ڒ��i�[�z��
  gr_lord_dec_tab          load_dec_rtype;                           -- �������ڕ������ڏ����_�ȉ��i�[�z��
  gr_lord_null_tab         load_null_rtype;                          -- �������ڕ������ڕK�{�t���O�i�[�z��
  gr_lord_attr_tab         load_attr_rtype;                          -- �������ڕ������ڍ��ڑ����i�[�z��
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id             IN  NUMBER                                -- 1.�t�@�C��ID
   ,in_file_upload_code    IN  NUMBER                                -- 2.�t�@�C���A�b�v���[�h�R�[�h
   ,ov_errbuf              OUT NOCOPY VARCHAR2                       -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2                       -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2                       -- ���[�U�[�E�G���[�E���b�Z�[�W
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
-- 
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
    lv_usermsg    VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- �G���[�E���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.�R���J�����g���̓p�����[�^�̕\��
    -- ***************************************************
--    �A�b�v���[�hCSV�t�@�C�����擾
    SELECT  file_name
    INTO    lv_file_name
    FROM    xxccp_mrp_file_ul_interface
    WHERE   file_id = in_file_id;
--    �A�b�v���[�hCSV�t�@�C�������O�o��
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                   cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                   cv_msg_cff_00167,    -- ���b�Z�[�W�F�A�b�v���[�hCSV�t�@�C�������O�o��
                   cv_tk_cff_00167_01,  -- �t�@�C���A�b�v���[�h���� 
                   cv_msg_cff_50187,    -- ���[�X�_��E���� 
                   cv_tk_cff_00167_02,  -- CSV�t�@�C����
                   lv_file_name         -- �t�@�C��ID
                 ),1,5000);
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG      --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��         
     ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT   --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
     ,buff   => lv_errmsg
    );
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- ***************************************************
    -- 2.���ʊ֐����������������s����
    -- ***************************************************
--
    -- ���ʏ��������̌Ăяo��
    xxcff_common1_pkg.init(
       or_init_rec => gr_init_rec         -- 1.�������i�[
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
--
    --�ُ�I���̎�
    IF (lv_retcode <> cv_status_normal) THEN                   
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                     cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                     cv_tk_cff_00094_01,  -- ���ʊ֐���
                     cv_msg_cff_50130     -- �t�@�C��ID
                    ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END init;
--
 /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hI/F�擾  (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id             IN  NUMBER           -- 1.�t�@�C��ID
   ,ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W
   ,ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h
   ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.BLOB�f�[�^�ϊ�
    -- ***************************************************
    --���ʃA�b�v���[�h�f�[�^�ϊ�����
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id       -- �t�@�C���h�c
     ,ov_file_data => gr_file_data_tbl -- �ϊ���VARCHAR2�f�[�^
     ,ov_retcode   => lv_retcode
     ,ov_errbuf    => lv_errbuf
     ,ov_errmsg    => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN                   
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                     cv_msg_cff_00110,    -- ���b�Z�[�W�F�f�[�^�ϊ��G���[
                     cv_tk_cff_00101_01,  -- �A�v���P�[�V������
                     cv_msg_cff_50131,    -- BLOB�f�[�^�ϊ��p�֐�
                     cv_tk_cff_00101_02,  -- INFO
                     lv_errmsg
                    ),1,5000);
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
  END get_if_data;
--
 /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : �f���~�^�������ڕ���         (A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    in_file_data     IN  VARCHAR2          --  1.�t�@�C���f�[�^
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'devide_item'; -- �v���O������
    cv_data_type_1   CONSTANT VARCHAR2(1)   := '1';           -- �1:�w�b�_�[�
    cv_data_type_2   CONSTANT VARCHAR2(1)   := '2';           -- �2:���ף
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
--
    --*** ���[�J���萔 ***
    cn_item_max     CONSTANT NUMBER(2) := 34;  --���ڐ� 
--
    --*** ���[�J���ϐ� ***
    ln_item_cnt     NUMBER;  -- �J�E���^
--
    --*** ���[�J���E�J�[�\�� ***
    CURSOR item_check_cur(in_type VARCHAR2)
    IS
    SELECT
           flv.lookup_code           AS lookup_code
          ,TO_NUMBER(flv.meaning)    AS index_num
          ,flv.description           AS item_name
          ,TO_NUMBER(flv.attribute1) AS item_len
          ,TO_NUMBER(flv.attribute2) AS item_dec
          ,flv.attribute3            AS item_null
          ,flv.attribute4            AS item_type
    FROM   fnd_lookup_values_vl flv
    WHERE  lookup_type = in_type
    ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
    item_check_cur_rec item_check_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.�f���~�^�������ڕ���
    -- ***************************************************
    --������
    ln_item_cnt          := 1;
    -- �Y�����������[�v����
    OPEN item_check_cur(cv_look_type);
    LOOP
      FETCH item_check_cur INTO item_check_cur_rec;
      EXIT WHEN item_check_cur%NOTFOUND;
      --
        gr_lord_data_tab(item_check_cur_rec.index_num) :=
          xxccp_common_pkg.char_delim_partition(in_file_data
                                               ,cv_csv_delim
                                               ,item_check_cur_rec.index_num
        );
      --�R�����g�s�̓X�L�b�v����̂ňȍ~�̏����͕s�v
        IF (item_check_cur_rec.index_num = 1) THEN
          IF (gr_lord_data_tab(ln_item_cnt) <> cv_data_type_1) AND
             (gr_lord_data_tab(ln_item_cnt) <> cv_data_type_2) THEN
            RETURN;
          END IF;
        END IF;
      --
        gr_lord_name_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_name;
        gr_lord_len_tab(item_check_cur_rec.index_num)  := item_check_cur_rec.item_len;
        gr_lord_dec_tab(item_check_cur_rec.index_num)  := item_check_cur_rec.item_dec;
        gr_lord_null_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_null;
        gr_lord_attr_tab(item_check_cur_rec.index_num) := item_check_cur_rec.item_type;
    END LOOP;
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
  END devide_item;
--
 /**********************************************************************************
   * Procedure Name   : chk_err_disposion
   * Description      : �z�񍀖ڃ`�F�b�N����         (A-4)
   ***********************************************************************************/
  PROCEDURE chk_err_disposion(
    ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_err_disposion'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    --*** ���[�J���萔 ***
    cv_data_type_1     CONSTANT VARCHAR2(1)  := '1';        -- �1:�w�b�_�[�
    cv_data_type_2     CONSTANT VARCHAR2(1)  := '2';        -- �2:���ף
    cv_check_scope     CONSTANT VARCHAR2(10) := 'GARBLED';  -- ���������`�F�b�N   
    cv_check_must_y    CONSTANT VARCHAR2(10) := 'NULL_NG';  -- �K�{�t���O=Y
    cv_check_must_n    CONSTANT VARCHAR2(10) := 'NULL_OK';  -- �K�{�t���O=N
    cv_check_format_0  CONSTANT VARCHAR2(1)  := '0';        -- VARCHAR2
    cv_check_format_1  CONSTANT VARCHAR2(1)  := '1';        -- NUMBER
    cv_check_format_2  CONSTANT VARCHAR2(1)  := '2';        -- DATE
--
    --*** ���[�J���ϐ� ***
    lv_return     BOOLEAN;          -- ���^�[���l
    lv_err_flag   VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_info   VARCHAR2(5000);   -- �G���[�Ώۏ��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.�e���ڂ̃t�H�[�}�b�g�A�K�{�`�F�b�N
    -- ***************************************************
    -- �G���[�Ώۏ��̕ҏW
    lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                    cv_msg_cff_00009,    -- ���b�Z�[�W�F�G���[�Ώ�
                    cv_tk_cff_00009_01,  -- �_��ԍ�
                    gr_lord_data_tab(2),
                    cv_tk_cff_00009_02,  -- ���[�X���
                    gr_lord_data_tab(3),
                    cv_tk_cff_00009_03,  -- �_��}��
                    gr_lord_data_tab(12), 
                    cv_tk_cff_00009_04,  -- �����R�[�h
                    gr_lord_data_tab(13) 
                  ),1,5000);
--
    -- �G���[�`�F�b�N�t���O���N���A����B
    lv_err_flag := cv_const_n;
--
    -- �f�[�^�敪���1:�w�b�_�[��̎�
    IF (gr_lord_data_tab(1) = cv_data_type_1) THEN
      -- 1.�_��ԍ�
--DEL 2009/11/27 START
/*
      --(���p�`�F�b�N)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(2)); 
      IF (lv_return <> TRUE) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00179 ,   -- ���b�Z�[�W�F���p�p�����G���[
                      cv_tk_cff_00005_01,  -- �J������
                      cv_msg_cff_50040     -- �_��ԍ�
                    ),1,5000)
        );
      END IF;              
*/
--DEL 2009/11/27 END
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(2)   -- ���ږ���
       ,gr_lord_data_tab(2)   -- ���ڒl
       ,gr_lord_len_tab(2)    -- ���ڂ̒���
       ,gr_lord_dec_tab(2)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(2)   -- �K�{�t���O
       ,gr_lord_attr_tab(2)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(2),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50040     -- �_��ԍ�
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_contract_number := gr_lord_data_tab(2);
        END IF;
      END IF;
--       
      -- 2.���[�X���
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(3)   -- ���ږ���
       ,gr_lord_data_tab(3)   -- ���ڒl
       ,gr_lord_len_tab(3)    -- ���ڂ̒���
       ,gr_lord_dec_tab(3)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(3)   -- �K�{�t���O
       ,gr_lord_attr_tab(3)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --�ϐ��Ɋi�[����B
        gv_lease_company := gr_lord_data_tab(3);
      END IF;
--      
      -- 3.����
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(4)   -- ���ږ���
       ,gr_lord_data_tab(4)   -- ���ڒl
       ,gr_lord_len_tab(4)    -- ���ڂ̒���
       ,gr_lord_dec_tab(4)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(4)   -- �K�{�t���O
       ,gr_lord_attr_tab(4)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(4),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50045     -- ����
                      ),1,5000)
          );
        ELSE
          --�ϐ��Ɋi�[����B
          gv_comments := gr_lord_data_tab(4);
        END IF;
      END IF;
--       
      -- 4.�_���
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(5)   -- ���ږ���
       ,gr_lord_data_tab(5)   -- ���ڒl
       ,gr_lord_len_tab(5)    -- ���ڂ̒���
       ,gr_lord_dec_tab(5)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(5)   -- �K�{�t���O
       ,gr_lord_attr_tab(5)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --�ϐ��Ɋi�[����B
        gd_contract_date := TO_DATE(gr_lord_data_tab(5),'YYYY/MM/DD');
      END IF;
--     
      -- 5.���[�X���
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(6)   -- ���ږ���
       ,gr_lord_data_tab(6)   -- ���ڒl
       ,gr_lord_len_tab(6)    -- ���ڂ̒���
       ,gr_lord_dec_tab(6)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(6)   -- �K�{�t���O
       ,gr_lord_attr_tab(6)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg       
      );
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );        
      ELSE
        --�ϐ��Ɋi�[����B
        gv_lease_class := gr_lord_data_tab(6);
      END IF;
--       
      -- 7.���[�X�J�n��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(7)   -- ���ږ���
       ,gr_lord_data_tab(7)   -- ���ڒl
       ,gr_lord_len_tab(7)    -- ���ڂ̒���
       ,gr_lord_dec_tab(7)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(7)   -- �K�{�t���O
       ,gr_lord_attr_tab(7)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          ); 
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --�ϐ��Ɋi�[����B
        gd_lease_start_date := TO_DATE(gr_lord_data_tab(7),'YYYY/MM/DD');
      END IF;
--
      -- 8.�x����
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(8)   -- ���ږ���
       ,gr_lord_data_tab(8)   -- ���ڒl
       ,gr_lord_len_tab(8)    -- ���ڂ̒���
       ,gr_lord_dec_tab(8)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(8)   -- �K�{�t���O
       ,gr_lord_attr_tab(8)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(8)) < 0) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            ); 
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50047     -- �x����
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_payment_frequency := TO_NUMBER(gr_lord_data_tab(8));
      END IF;
--       
      -- 9.����x����
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(9)   -- ���ږ���
       ,gr_lord_data_tab(9)   -- ���ڒl
       ,gr_lord_len_tab(9)    -- ���ڂ̒���
       ,gr_lord_dec_tab(9)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(9)   -- �K�{�t���O
       ,gr_lord_attr_tab(9)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --�ϐ��Ɋi�[����B
        gd_first_payment_date := TO_DATE(gr_lord_data_tab(9),'YYYY/MM/DD');
      END IF;
--
      -- 10.�Q��ڎx����
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(10)   -- ���ږ���
       ,gr_lord_data_tab(10)   -- ���ڒl
       ,gr_lord_len_tab(10)    -- ���ڂ̒���
       ,gr_lord_dec_tab(10)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(10)   -- �K�{�t���O
       ,gr_lord_attr_tab(10)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );            
      ELSE
        --�ϐ��Ɋi�[����B
        gd_second_payment_date := TO_DATE(gr_lord_data_tab(10),'YYYY/MM/DD');
      END IF;
--  
      -- 11.�ŋ��R�[�h
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(11)   -- ���ږ���
       ,gr_lord_data_tab(11)   -- ���ڒl
       ,gr_lord_len_tab(11)    -- ���ڂ̒���
       ,gr_lord_dec_tab(11)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(11)   -- �K�{�t���O
       ,gr_lord_attr_tab(11)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --�ϐ��Ɋi�[����B
        gv_tax_code  := gr_lord_data_tab(11);
      END IF;
--
    ELSIF (gr_lord_data_tab(1) = cv_data_type_2) THEN
      -- 1.�_��ԍ�
--DEL 2009/11/27 START
/*
      --(���p�`�F�b�N)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(2)); 
      IF (lv_return <> TRUE) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00179 ,   -- ���b�Z�[�W�F���p�p�����G���[
                      cv_tk_cff_00005_01,  -- �J������
                      cv_msg_cff_50040     -- �_��ԍ�
                    ),1,5000)
        );
      END IF;              
*/
--DEL 2009/11/27 END
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(2)   -- ���ږ���
       ,gr_lord_data_tab(2)   -- ���ڒl
       ,gr_lord_len_tab(2)    -- ���ڂ̒���
       ,gr_lord_dec_tab(2)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(2)   -- �K�{�t���O
       ,gr_lord_attr_tab(2)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(2),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50040     -- �_��ԍ�
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_contract_number_line := gr_lord_data_tab(2);
        END IF;
      END IF;
--       
      -- 2.�_��}��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(12)   -- ���ږ���
       ,gr_lord_data_tab(12)   -- ���ڒl
       ,gr_lord_len_tab(12)    -- ���ڂ̒���
       ,gr_lord_dec_tab(12)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(12)   -- �K�{�t���O
       ,gr_lord_attr_tab(12)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --�ϐ��Ɋi�[����B
        gv_contract_line_num := TO_NUMBER(gr_lord_data_tab(12));
      END IF;
--      
      -- 3.���[�X���
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(3)   -- ���ږ���
       ,gr_lord_data_tab(3)   -- ���ڒl
       ,gr_lord_len_tab(3)    -- ���ڂ̒���
       ,gr_lord_dec_tab(3)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(3)   -- �K�{�t���O
       ,gr_lord_attr_tab(3)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --�ϐ��Ɋi�[����B
        gv_lease_company_line := gr_lord_data_tab(3);
      END IF;
--      
      -- 4.�����R�[�h
      --(���p�`�F�b�N)
      lv_return := xxccp_common_pkg.chk_alphabet_number(
                     iv_check_char   => gr_lord_data_tab(13)); 
      IF (lv_return <> TRUE) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00179 ,   -- ���b�Z�[�W�F���p�p�����G���[
                      cv_tk_cff_00005_01,  -- �J������
                      cv_msg_cff_50010     -- �����R�[�h
                    ),1,5000)
        );
      END IF;                    
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(13)   -- ���ږ���
       ,gr_lord_data_tab(13)   -- ���ڒl
       ,gr_lord_len_tab(13)    -- ���ڂ̒���
       ,gr_lord_dec_tab(13)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(13)   -- �K�{�t���O
       ,gr_lord_attr_tab(13)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --�ϐ��Ɋi�[����B
        gv_object_code := gr_lord_data_tab(13);
      END IF;
--      
      -- 5.���Y���
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(14)   -- ���ږ���
       ,gr_lord_data_tab(14)   -- ���ڒl
       ,gr_lord_len_tab(14)    -- ���ڂ̒���
       ,gr_lord_dec_tab(14)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(14)   -- �K�{�t���O
       ,gr_lord_attr_tab(14)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --�ϐ��Ɋi�[����B
        gv_asset_category := gr_lord_data_tab(14);
      END IF;
--
      -- 6.����ݒu��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(15)   -- ���ږ���
       ,gr_lord_data_tab(15)   -- ���ڒl
       ,gr_lord_len_tab(15)    -- ���ڂ̒���
       ,gr_lord_dec_tab(15)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(15)   -- �K�{�t���O
       ,gr_lord_attr_tab(15)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(15),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50149     -- ����ݒu��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          --[��QT1_0721]MOD START
          --gv_first_inst_address := gr_lord_data_tab(15);
          gv_first_inst_place := gr_lord_data_tab(15);
          --[��QT1_0721]MOD END
        END IF;
      END IF;  
--
      -- 7.����ݒu�ꏊ
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(16)   -- ���ږ���
       ,gr_lord_data_tab(16)   -- ���ڒl
       ,gr_lord_len_tab(16)    -- ���ڂ̒���
       ,gr_lord_dec_tab(16)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(16)   -- �K�{�t���O
       ,gr_lord_attr_tab(16)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );           
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(16),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50150     -- ����ݒu�ꏊ
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          --[��QT1_0721]MOD START
          --gv_first_inst_place  := gr_lord_data_tab(16);
          gv_first_inst_address  := gr_lord_data_tab(16);
          --[��QT1_0721]MOD END
        END IF;
      END IF;  
--      
      -- 8.���񌎊z���[�X��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(17)   -- ���ږ���
       ,gr_lord_data_tab(17)   -- ���ڒl
       ,gr_lord_len_tab(17)    -- ���ڂ̒���
       ,gr_lord_dec_tab(17)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(17)   -- �K�{�t���O
       ,gr_lord_attr_tab(17)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(17)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50108     -- ���񌎊z���[�X��
                      ),1,5000)
          );
        END IF;        --�ϐ��Ɋi�[����B
        gn_first_charge := TO_NUMBER(gr_lord_data_tab(17));
      END IF;   
--      
      -- 9.���񌎊z����Ŋz
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(18)   -- ���ږ���
       ,gr_lord_data_tab(18)   -- ���ڒl
       ,gr_lord_len_tab(18)    -- ���ڂ̒���
       ,gr_lord_dec_tab(18)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(18)   -- �K�{�t���O
       ,gr_lord_attr_tab(18)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(18)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50156     -- ���񌎊z����Ŋz
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_first_tax_charge := TO_NUMBER(gr_lord_data_tab(18));
      END IF;   
--
      -- 11.�Q��ڌ��z���[�X��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(19)   -- ���ږ���
       ,gr_lord_data_tab(19)   -- ���ڒl
       ,gr_lord_len_tab(19)    -- ���ڂ̒���
       ,gr_lord_dec_tab(19)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(19)   -- �K�{�t���O
       ,gr_lord_attr_tab(19)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(19)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50109     -- �Q��ڌ��z���[�X��
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_second_charge := TO_NUMBER(gr_lord_data_tab(19));
      END IF;   
--
      -- 11.�Q��ڈȍ~����Ŋz
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(20)   -- ���ږ���
       ,gr_lord_data_tab(20)   -- ���ڒl
       ,gr_lord_len_tab(20)    -- ���ڂ̒���
       ,gr_lord_dec_tab(20)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(20)   -- �K�{�t���O
       ,gr_lord_attr_tab(20)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(20)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50157     -- �Q��ڈȍ~����Ŋz
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_second_tax_charge := TO_NUMBER(gr_lord_data_tab(20));
      END IF;      
--
      -- 12.�ێ��Ǘ���p�����z�i���z�j
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(21)   -- ���ږ���
       ,gr_lord_data_tab(21)   -- ���ڒl
       ,gr_lord_len_tab(21)    -- ���ڂ̒���
       ,gr_lord_dec_tab(21)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(21)   -- �K�{�t���O
       ,gr_lord_attr_tab(21)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(21)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50158     -- ���z���[�X�T���z
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_first_deduction := TO_NUMBER(gr_lord_data_tab(21));
      END IF;      
--
--DEL 2010/01/07 START
--      -- 12.���z���[�X�T������Ŋz
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(22)   -- ���ږ���
--       ,gr_lord_data_tab(22)   -- ���ڒl
--       ,gr_lord_len_tab(22)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(22)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(22)   -- �K�{�t���O
--       ,gr_lord_attr_tab(22)    -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(22)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50159     -- ���z���[�X�T������Ŋz
--                      ),1,5000)
--          );
--        END IF;
--        --�ϐ��Ɋi�[����B
--        gn_first_tax_deduction := TO_NUMBER(gr_lord_data_tab(22));
--      END IF;      
----
--      -- 13.���ό����w�����z
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(23)   -- ���ږ���
--       ,gr_lord_data_tab(23)   -- ���ڒl
--       ,gr_lord_len_tab(23)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(23)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(23)   -- �K�{�t���O
--       ,gr_lord_attr_tab(23)    -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(23)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50064     -- ���ό����w�����z
--                      ),1,5000)
--          );
--        END IF;
--        --�ϐ��Ɋi�[����B
--        gn_estimated_cash_price := TO_NUMBER(gr_lord_data_tab(23));
--      END IF;      
----
--      -- 14.�@��ϗp�N��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(24)   -- ���ږ���
--       ,gr_lord_data_tab(24)   -- ���ڒl
--       ,gr_lord_len_tab(24)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(24)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(24)   -- �K�{�t���O
--       ,gr_lord_attr_tab(24)    -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(24)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          --
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50032     -- �@��ϗp�N��
--                      ),1,5000)
--          );
--        END IF;
--        --�ϐ��Ɋi�[����B
--        gn_life_in_months := TO_NUMBER(gr_lord_data_tab(24));
--      END IF;         
----
--      -- 15.�{��/�H��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(25)   -- ���ږ���
--       ,gr_lord_data_tab(25)   -- ���ڒl
--       ,gr_lord_len_tab(25)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(25)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(25)   -- �K�{�t���O
--       ,gr_lord_attr_tab(25)    -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(25),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50012     -- �H��/�{��
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_owner_company := gr_lord_data_tab(25);
--        END IF;         
--      END IF;         
----
--      -- 16.�Ǘ�����R�[�h
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(26)   -- ���ږ���
--       ,gr_lord_data_tab(26)   -- ���ڒl
--       ,gr_lord_len_tab(26)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(26)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(26)   -- �K�{�t���O
--       ,gr_lord_attr_tab(26)    -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(26),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50011     -- �Ǘ�����R�[�h
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_department_code := gr_lord_data_tab(26);
--        END IF;         
--      END IF;         
----
--      -- 17.�����ԍ�
--      --(�K�{�A�������`�F�b�N) gv_po_number
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(27)   -- ���ږ���
--       ,gr_lord_data_tab(27)   -- ���ڒl
--       ,gr_lord_len_tab(27)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(27)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(27)   -- �K�{�t���O
--       ,gr_lord_attr_tab(27)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(27),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50184     -- �����ԍ�
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--           gv_po_number := gr_lord_data_tab(27);
--        END IF;         
--      END IF;               
----
--      -- 18.���[�J�[��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(28)   -- ���ږ���
--       ,gr_lord_data_tab(28)   -- ���ڒl
--       ,gr_lord_len_tab(28)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(28)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(28)   -- �K�{�t���O
--       ,gr_lord_attr_tab(28)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(28),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50177     -- ���[�J�[��
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_manufacturer_name := gr_lord_data_tab(28);
--        END IF;         
--      END IF;               
----
--      -- 19.�@��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(29)   -- ���ږ���
--       ,gr_lord_data_tab(29)   -- ���ڒl
--       ,gr_lord_len_tab(29)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(29)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(29)   -- �K�{�t���O
--       ,gr_lord_attr_tab(29)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(29),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50178     -- �@��
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_model   := gr_lord_data_tab(29);
--        END IF;         
--      END IF;               
----
--      -- 20.�@��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(30)   -- ���ږ���
--       ,gr_lord_data_tab(30)   -- ���ڒl
--       ,gr_lord_len_tab(30)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(30)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(30)   -- �K�{�t���O
--       ,gr_lord_attr_tab(30)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(30),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50179     -- �@��
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_serial_number   := gr_lord_data_tab(30);
--        END IF;         
--      END IF;      
----
--      -- 21.�N��
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(31)   -- ���ږ���
--       ,gr_lord_data_tab(31)   -- ���ڒl
--       ,gr_lord_len_tab(31)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(31)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(31)   -- �K�{�t���O
--       ,gr_lord_attr_tab(31)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(31),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50180     -- �N��
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_age_type   := gr_lord_data_tab(31);
--        END IF;         
--      END IF;      
----
--      -- 22.����
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(32)   -- ���ږ���
--       ,gr_lord_data_tab(32)   -- ���ڒl
--       ,gr_lord_len_tab(32)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(32)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(32)   -- �K�{�t���O
--       ,gr_lord_attr_tab(32)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        IF (TO_NUMBER(gr_lord_data_tab(32)) < 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50181     -- ����
--                      ),1,5000)
--          );
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gn_quantity   := TO_NUMBER(gr_lord_data_tab(32));
--        END IF;
--      END IF;      
----
--      -- 23.�ԑ�ԍ�
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(33)   -- ���ږ���
--       ,gr_lord_data_tab(33)   -- ���ڒl
--       ,gr_lord_len_tab(33)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(33)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(33)   -- �K�{�t���O
--       ,gr_lord_attr_tab(33)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(33),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50182     -- �ԑ�ԍ�
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_chassis_number  := gr_lord_data_tab(33);
--        END IF;         
--      END IF;      
----
--      -- 24.�o�^�ԍ�
--      --(�K�{�A�������`�F�b�N)
--      xxccp_common_pkg2.upload_item_check(
--        gr_lord_name_tab(34)   -- ���ږ���
--       ,gr_lord_data_tab(34)   -- ���ڒl
--       ,gr_lord_len_tab(34)    -- ���ڂ̒���
--       ,gr_lord_dec_tab(34)    -- ���ڂ̒���(�����_�ȉ�)
--       ,gr_lord_null_tab(34)   -- �K�{�t���O
--       ,gr_lord_attr_tab(34)   -- ���ڌ^
--       ,lv_errbuf
--       ,lv_retcode
--       ,lv_errmsg);
--      IF (lv_retcode <> cv_status_normal) THEN
--        -- �G���[�Ώۏ��̏o��
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg
--        );  
--      ELSE
--        --(�֑������`�F�b�N)
--        lv_return := xxccp_common_pkg2.chk_moji(
--                       gr_lord_data_tab(34),   -- �Ώە�����
--                       cv_check_scope);
--        IF (lv_return <> TRUE) THEN
--          -- �G���[�Ώۏ��̏o��
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--            lv_err_flag := cv_const_y;
--          END IF;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
--                        cv_tk_cff_00005_01,  -- �J������
--                        cv_msg_cff_50183     -- �o�^�ԍ�
--                      ),1,5000)
--          );            
--        ELSE
--          --�ϐ��Ɋi�[����B
--          gv_registration_number  := gr_lord_data_tab(34);
--        END IF;         
--      END IF;      
--DEL 2010/01/07 END
--
--ADD 2010/01/07 START
--
      -- 13.���ό����w�����z
      --(�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(22)   -- ���ږ���
       ,gr_lord_data_tab(22)   -- ���ڒl
       ,gr_lord_len_tab(22)    -- ���ڂ̒���
       ,gr_lord_dec_tab(22)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(22)   -- �K�{�t���O
       ,gr_lord_attr_tab(22)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--      �����ł̓��[�X���ʌ��ʂ𗘗p���Ȃ����߁A��UNVL�ŉ��
--      �}�C�i�X�l�݂̂�ΏۂƂ���
--        IF (TO_NUMBER(gr_lord_data_tab(22)) < 0) THEN
        IF (NVL(TO_NUMBER(gr_lord_data_tab(22)),0) < 0) THEN
-- 2018/03/27 Ver1.10 Otsuka MOD End
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�����j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50064     -- ���ό����w�����z
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_estimated_cash_price := TO_NUMBER(gr_lord_data_tab(22));
      END IF;      
--
      -- 14.�@��ϗp�N��
      --(�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(23)   -- ���ږ���
       ,gr_lord_data_tab(23)   -- ���ڒl
       ,gr_lord_len_tab(23)    -- ���ڂ̒���
       ,gr_lord_dec_tab(23)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(23)   -- �K�{�t���O
       ,gr_lord_attr_tab(23)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--      �����ł̓��[�X���ʌ��ʂ𗘗p���Ȃ����߁A��UNVL�ŉ��
--      �}�C�i�X�l�݂̂�ΏۂƂ���
--        IF (TO_NUMBER(gr_lord_data_tab(23)) < 0) THEN
        IF (NVL(TO_NUMBER(gr_lord_data_tab(23)),0) < 0) THEN
-- 2018/03/27 Ver1.10 Otsuka MOD End
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�����j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50032     -- �@��ϗp�N��
                      ),1,5000)
          );
        END IF;
        --�ϐ��Ɋi�[����B
        gn_life_in_months := TO_NUMBER(gr_lord_data_tab(23));
      END IF;         
--
      -- 15.�{��/�H��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(24)   -- ���ږ���
       ,gr_lord_data_tab(24)   -- ���ڒl
       ,gr_lord_len_tab(24)    -- ���ڂ̒���
       ,gr_lord_dec_tab(24)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(24)   -- �K�{�t���O
       ,gr_lord_attr_tab(24)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(24),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50012     -- �H��/�{��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_owner_company := gr_lord_data_tab(24);
        END IF;         
      END IF;         
--
      -- 16.�Ǘ�����R�[�h
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(25)   -- ���ږ���
       ,gr_lord_data_tab(25)   -- ���ڒl
       ,gr_lord_len_tab(25)    -- ���ڂ̒���
       ,gr_lord_dec_tab(25)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(25)   -- �K�{�t���O
       ,gr_lord_attr_tab(25)    -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(25),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50011     -- �Ǘ�����R�[�h
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_department_code := gr_lord_data_tab(25);
        END IF;         
      END IF;         
--
      -- 17.�����ԍ�
      --(�K�{�A�������`�F�b�N) gv_po_number
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(26)   -- ���ږ���
       ,gr_lord_data_tab(26)   -- ���ڒl
       ,gr_lord_len_tab(26)    -- ���ڂ̒���
       ,gr_lord_dec_tab(26)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(26)   -- �K�{�t���O
       ,gr_lord_attr_tab(26)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(26),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50184     -- �����ԍ�
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
           gv_po_number := gr_lord_data_tab(26);
        END IF;         
      END IF;               
--
      -- 18.���[�J�[��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(27)   -- ���ږ���
       ,gr_lord_data_tab(27)   -- ���ڒl
       ,gr_lord_len_tab(27)    -- ���ڂ̒���
       ,gr_lord_dec_tab(27)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(27)   -- �K�{�t���O
       ,gr_lord_attr_tab(27)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(27),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50177     -- ���[�J�[��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_manufacturer_name := gr_lord_data_tab(27);
        END IF;         
      END IF;               
--
      -- 19.�@��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(28)   -- ���ږ���
       ,gr_lord_data_tab(28)   -- ���ڒl
       ,gr_lord_len_tab(28)    -- ���ڂ̒���
       ,gr_lord_dec_tab(28)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(28)   -- �K�{�t���O
       ,gr_lord_attr_tab(28)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(28),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50178     -- �@��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_model   := gr_lord_data_tab(28);
        END IF;         
      END IF;               
--
      -- 20.�@��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(29)   -- ���ږ���
       ,gr_lord_data_tab(29)   -- ���ڒl
       ,gr_lord_len_tab(29)    -- ���ڂ̒���
       ,gr_lord_dec_tab(29)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(29)   -- �K�{�t���O
       ,gr_lord_attr_tab(29)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(29),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50179     -- �@��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_serial_number   := gr_lord_data_tab(29);
        END IF;         
      END IF;      
--
      -- 21.�N��
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(30)   -- ���ږ���
       ,gr_lord_data_tab(30)   -- ���ڒl
       ,gr_lord_len_tab(30)    -- ���ڂ̒���
       ,gr_lord_dec_tab(30)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(30)   -- �K�{�t���O
       ,gr_lord_attr_tab(30)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(30),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50180     -- �N��
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_age_type   := gr_lord_data_tab(30);
        END IF;         
      END IF;      
--
      -- 22.����
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(31)   -- ���ږ���
       ,gr_lord_data_tab(31)   -- ���ڒl
       ,gr_lord_len_tab(31)    -- ���ڂ̒���
       ,gr_lord_dec_tab(31)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(31)   -- �K�{�t���O
       ,gr_lord_attr_tab(31)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        IF (TO_NUMBER(gr_lord_data_tab(31)) < 0) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00117,    -- ���b�Z�[�W�F���l�_���G���[(0�ȉ��j
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50181     -- ����
                      ),1,5000)
          );
        ELSE
          --�ϐ��Ɋi�[����B
          gn_quantity   := TO_NUMBER(gr_lord_data_tab(31));
        END IF;
      END IF;      
--
      -- 23.�ԑ�ԍ�
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(32)   -- ���ږ���
       ,gr_lord_data_tab(32)   -- ���ڒl
       ,gr_lord_len_tab(32)    -- ���ڂ̒���
       ,gr_lord_dec_tab(32)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(32)   -- �K�{�t���O
       ,gr_lord_attr_tab(32)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(32),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50182     -- �ԑ�ԍ�
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_chassis_number  := gr_lord_data_tab(32);
        END IF;         
      END IF;      
--
      -- 24.�o�^�ԍ�
      --(�K�{�A�������`�F�b�N)
      xxccp_common_pkg2.upload_item_check(
        gr_lord_name_tab(33)   -- ���ږ���
       ,gr_lord_data_tab(33)   -- ���ڒl
       ,gr_lord_len_tab(33)    -- ���ڂ̒���
       ,gr_lord_dec_tab(33)    -- ���ڂ̒���(�����_�ȉ�)
       ,gr_lord_null_tab(33)   -- �K�{�t���O
       ,gr_lord_attr_tab(33)   -- ���ڌ^
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg);
      IF (lv_retcode <> cv_status_normal) THEN
        -- �G���[�Ώۏ��̏o��
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );  
      ELSE
        --(�֑������`�F�b�N)
        lv_return := xxccp_common_pkg2.chk_moji(
                       gr_lord_data_tab(33),   -- �Ώە�����
                       cv_check_scope);
        IF (lv_return <> TRUE) THEN
          -- �G���[�Ώۏ��̏o��
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00138,    -- ���b�Z�[�W�F�֑������G���[
                        cv_tk_cff_00005_01,  -- �J������
                        cv_msg_cff_50183     -- �o�^�ԍ�
                      ),1,5000)
          );            
        ELSE
          --�ϐ��Ɋi�[����B
          gv_registration_number  := gr_lord_data_tab(33);
        END IF;         
      END IF;      
--ADD 2010/01/07 END
--
    END IF;
--   
   --�G���[���ݎ�
   IF (lv_err_flag = cv_const_y) THEN
       ov_retcode := cv_status_error;
   END IF;
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
  END chk_err_disposion;
--
 /**********************************************************************************
   * Procedure Name   : ins_cont_work
   * Description      : �A�b�v���[�h�U������          (A-5)
   ***********************************************************************************/
  PROCEDURE ins_cont_work(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cont_work'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_data_type_1     CONSTANT VARCHAR2(1)  := '1';        -- �1:�w�b�_�[�
    cv_data_type_2     CONSTANT VARCHAR2(1)  := '2';        -- �2:���ף
    cv_lease_type_1    CONSTANT VARCHAR2(1)  := '1';        -- �1:���_��
    cv_payment_type_0  CONSTANT VARCHAR2(1)  := '0';        -- �0:�p�x�i���j�
--
    --*** ���[�J���ϐ� ***
    lv_return  BOOLEAN;  -- ���^�[���l
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.���[�N�e�[�u���ւ̐U������
    -- ***************************************************
    -- �f�[�^�敪���1:�w�b�_�[��̎�
    IF (gr_lord_data_tab(1) = cv_data_type_1) THEN
      --���[�X�_�񃏁[�N�ւ̒ǉ�
      gn_seqno := gn_seqno + 1;
      INSERT INTO xxcff_cont_headers_work(
        seqno                                     -- �ʔ�
      , contract_number                           -- �_��ԍ�
      , lease_class                               -- ���[�X���
      , lease_type                                -- ���[�X�敪
      , lease_company                             -- ���[�X���
      , re_lease_times                            -- �ă��[�X��
      , comments                                  -- ����
      , contract_date                             -- ���[�X�_���
      , payment_frequency                         -- �x����
      , payment_type                              -- �p�x
      , lease_start_date                          -- ���[�X�J�n��
      , first_payment_date                        -- ����x����
      , second_payment_date                       -- 2��ڎx����
      , tax_code                                  -- �ŋ��R�[�h
      , file_id                                   -- �t�@�C��ID
      , created_by                                -- �쐬��
      , creation_date                             -- �쐬��
      , last_updated_by                           -- �ŏI�X�V��
      , last_update_date                          -- �ŏI�X�V��
      , last_update_login                         -- �ŏI�X�V۸޲�
      , request_id                                -- �v��ID
      , program_application_id                    -- �ݶ��ĥ��۸��ѥ���ع����ID
      , program_id                                -- �ݶ��ĥ��۸���ID
      , program_update_date                       -- ��۸��эX�V��
      )
      VALUES(
        gn_seqno                                  -- �ʔ�
      , gv_contract_number                        -- �_��ԍ�
      , gv_lease_class                            -- ���[�X���
      , cv_lease_type_1                           -- ���[�X�敪
      , gv_lease_company                          -- ���[�X���
      , 0                                         -- �ă��[�X��
      , gv_comments                               -- ����
      , gd_contract_date                          -- ���[�X�_���
      , gn_payment_frequency                      -- �x����
      , cv_payment_type_0                         -- �p�x
      , gd_lease_start_date                       -- ���[�X�J�n��
      , gd_first_payment_date                     -- ����x����
      , gd_second_payment_date                    -- 2��ڎx����
      , gv_tax_code                               -- �ŋ��R�[�h
      , in_file_id                                -- �t�@�C��ID
      , cn_created_by                             -- �쐬��
      , cd_creation_date                          -- �쐬��
      , cn_last_updated_by                        -- �ŏI�X�V��
      , cd_last_update_date                       -- �ŏI�X�V��
      , cn_last_update_login                      -- �ŏI�X�V۸޲�
      , cn_request_id                             -- �v��ID
      , cn_program_application_id                 -- �ݶ��ĥ��۸��ѥ���ع����ID
      , cn_program_id                             -- �ݶ��ĥ��۸���ID
      , cd_program_update_date                    -- ��۸��эX�V��
      );
    ELSIF (gr_lord_data_tab(1) = cv_data_type_2) THEN
      gn_seqno_line := gn_seqno_line + 1;
      --���[�X�_�񖾍׃��[�N�ւ̒ǉ�
      INSERT INTO xxcff_cont_lines_work(
        seqno                                     -- �ʔ�
      , contract_number                           -- �_��ԍ�
      , contract_line_num                         -- �_��}��
      , lease_company                             -- ���[�X��� 
      , first_charge                              -- ���񃊁[�X��
      , first_tax_charge                          -- ���񃊁[�X��_����Ŋz
      , second_charge                             -- �Q��ڃ��[�X��
      , second_tax_charge                         -- �Q��ڃ��[�X��_����Ŋz
      , first_deduction                           -- ���񃊁[�X��_�T���z
      , first_tax_deduction                       -- �������Ŋz_�T���z
      , estimated_cash_price                      -- ���ό����w�����z
      , life_in_months                            -- �@��ϗp�N��
      , object_code                               -- �����R�[�h
      , lease_kind                                -- ���[�X���
      , asset_category                            -- ���Y���
      , first_installation_address                -- ����ݒu�ꏊ
      , first_installation_place                  -- ����ݒu��
      , file_id                                   -- �t�@�C��ID
      , created_by                                -- �쐬��
      , creation_date                             -- �쐬��
      , last_updated_by                           -- �ŏI�X�V��
      , last_update_date                          -- �ŏI�X�V��
      , last_update_login                         -- �ŏI�X�V۸޲�
      , request_id                                -- �v��ID
      , program_application_id                    -- �ݶ��ĥ��۸��ѥ���ع����ID
      , program_id                                -- �ݶ��ĥ��۸���ID
      , program_update_date                       -- ��۸��эX�V��
      )
      VALUES(
        gn_seqno_line                             -- �ʔ�
      , gv_contract_number_line                   -- �_��ԍ�
      , gv_contract_line_num                      -- �_��}��
      , gv_lease_company_line                     -- ���[�X��� 
      , gn_first_charge                           -- ���񃊁[�X��
      , gn_first_tax_charge                       -- ���񃊁[�X��_����Ŋz
      , gn_second_charge                          -- �Q��ڃ��[�X��
      , gn_second_tax_charge                      -- �Q��ڃ��[�X��_����Ŋz
      , gn_first_deduction                        -- ���񃊁[�X��_�T���z
--UPD 2010/01/07 START
      --, gn_first_tax_deduction                    -- �������Ŋz_�T���z
      , 0                                         -- �������Ŋz_�T���z
--UPD 2010/01/07 END
      , gn_estimated_cash_price                   -- ���ό����w�����z
      , gn_life_in_months                         -- �@��ϗp�N��
      , gv_object_code                            -- �����R�[�h
      , '0'                                       -- ���[�X���
      , gv_asset_category                         -- ���Y���
      , gv_first_inst_address                     -- ����ݒu�ꏊ
      , gv_first_inst_place                       -- ����ݒu��
      , in_file_id                                -- �t�@�C��ID
      , cn_created_by                             -- �쐬��
      , cd_creation_date                          -- �쐬��
      , cn_last_updated_by                        -- �ŏI�X�V��
      , cd_last_update_date                       -- �ŏI�X�V��
      , cn_last_update_login                      -- �ŏI�X�V۸޲�
      , cn_request_id                             -- �v��ID
      , cn_program_application_id                 -- �ݶ��ĥ��۸��ѥ���ع����ID
      , cn_program_id                             -- �ݶ��ĥ��۸���ID
      , cd_program_update_date                    -- ��۸��эX�V��
      );
      --���[�X�������[�N�ւ̒ǉ�
      INSERT INTO xxcff_cont_obj_work(
        seqno                                     -- �ʔ�
      , contract_number                           -- �_��ԍ�
      , contract_line_num                         -- �_��}��
      , lease_company                             -- ���[�X��� 
      , object_code                               -- �����R�[�h
      , po_number                                 -- �����ԍ�
      , registration_number                       -- �o�^�ԍ�
      , age_type                                  -- �N��
      , model                                     -- �@��
      , serial_number                             -- �@��
      , quantity                                  -- ����
      , manufacturer_name                         -- ���[�J�[��
      , department_code                           -- �Ǘ�����R�[�h
      , owner_company                             -- �{�Ё^�H��
      , chassis_number                            -- �ԑ�ԍ�
      , file_id                                   -- �t�@�C��ID
      , created_by                                -- �쐬��
      , creation_date                             -- �쐬��
      , last_updated_by                           -- �ŏI�X�V��
      , last_update_date                          -- �ŏI�X�V��
      , last_update_login                         -- �ŏI�X�V۸޲�
      , request_id                                -- �v��ID
      , program_application_id                    -- �ݶ��ĥ��۸��ѥ���ع����ID
      , program_id                                -- �ݶ��ĥ��۸���ID
      , program_update_date                       -- ��۸��эX�V��
      )
      VALUES(
        gn_seqno_line                             -- �ʔ�
      , gv_contract_number_line                   -- �_��ԍ�
      , gv_contract_line_num                      -- �_��}��
      , gv_lease_company_line                     -- ���[�X��� 
      , gv_object_code                            -- �����R�[�h
      , gv_po_number                              -- �����ԍ�
      , gv_registration_number                    -- �o�^�ԍ�
      , gv_age_type                               -- �N��
      , gv_model                                  -- �@��
      , gv_serial_number                          -- �@��
      , gn_quantity                               -- ����
      , gv_manufacturer_name                      -- ���[�J�[��
      , gv_department_code                        -- �Ǘ�����R�[�h
      , gv_owner_company                          -- �{�Ё^�H��
      , gv_chassis_number                         -- �ԑ�ԍ�
      , in_file_id                                -- �t�@�C��ID
      , cn_created_by                             -- �쐬��
      , cd_creation_date                          -- �쐬��
      , cn_last_updated_by                        -- �ŏI�X�V��
      , cd_last_update_date                       -- �ŏI�X�V��
      , cn_last_update_login                      -- �ŏI�X�V۸޲�
      , cn_request_id                             -- �v��ID
      , cn_program_application_id                 -- �ݶ��ĥ��۸��ѥ���ع����ID
      , cn_program_id                             -- �ݶ��ĥ��۸���ID
      , cd_program_update_date                    -- ��۸��эX�V��
      );
    END IF; 
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
  END ins_cont_work;
--
  /**********************************************************************************
   * Procedure Name   : chk_rept_adjust
   * Description      : ܰ�̧�ُd���E��������������      (A-7)
   ***********************************************************************************/
  PROCEDURE chk_rept_adjust(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_rept_adjust'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
    lv_err_flag          VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_flag_1        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�P
    lv_err_flag_2        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�Q
    lv_err_flag_3        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�R
    lv_err_flag_4        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�S
    lv_err_flag_5        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�T
    lv_err_flag_6        VARCHAR2(1);      -- �J�[�\���ʃG���[�t���O�U
    lv_err_info          VARCHAR2(5000);   -- �G���[�Ώۏ��
    lv_contract_number   xxcff_cont_headers_work.contract_number%TYPE;   -- �_��ԍ��u���[�N�p
    lv_lease_company     xxcff_cont_headers_work.lease_company%TYPE;     -- ���[�X��Ѓu���[�N�p
    ln_check_cnt         NUMBER(2);        -- �ă��[�X�񐔃`�F�b�N�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�_�񃏁[�N��̌_��ԍ��d���`�F�b�N�p
    CURSOR xchw_double_data_cur
    IS
      SELECT xchw.contract_number    AS contract_number
            ,xchw.lease_company      AS lease_company 
            ,COUNT(*)                AS seqno
      FROM   xxcff_cont_headers_work xchw
      WHERE  xchw.file_id          = in_file_id
      GROUP  BY xchw.contract_number
            ,xchw.lease_company
      HAVING COUNT(*) > 1;
    -- *** ���[�J���E���R�[�h ***
    xchw_double_data_rec xchw_double_data_cur%ROWTYPE;
--
    -- ���[�X�_�񃏁[�N��̌_��ԍ����݃`�F�b�N�p
    CURSOR xchw_exist_data_cur
    IS
      SELECT xchw.contract_number    AS contract_number
            ,xchw.lease_company      AS lease_company 
      FROM   xxcff_cont_headers_work xchw
      WHERE  NOT EXISTS
       (SELECT null
        FROM   xxcff_cont_lines_work xclw
        WHERE  xclw.file_id          =  in_file_id
        AND    xclw.contract_number  =  xchw.contract_number
        AND    xclw.lease_company    =  xchw.lease_company)
      AND    xchw.file_id          = in_file_id;
    -- *** ���[�J���E���R�[�h ***
    xchw_exist_data_rec xchw_exist_data_cur%ROWTYPE;
--
    -- ���[�X�_�񖾍׃��[�N��̌_��ԍ��d���`�F�b�N�p
    CURSOR xclw_double_data_cur
    IS
      SELECT xclw.contract_number    AS contract_number
            ,xclw.contract_line_num  AS contract_line_num
            ,xclw.lease_company      AS lease_company
            ,COUNT(*)                AS seqno
      FROM   xxcff_cont_lines_work   xclw
      WHERE xclw.file_id             = in_file_id
      GROUP BY xclw.contract_number
              ,xclw.contract_line_num
              ,xclw.lease_company
      HAVING   COUNT(*) > 1;
    -- *** ���[�J���E���R�[�h ***
    xclw_double_data_rec xclw_double_data_cur%ROWTYPE;
--
    -- ���[�X�_�񖾍׃��[�N��̌_��ԍ����݃`�F�b�N�p
    CURSOR xclw_exist_data_cur
    IS
      SELECT xclw.contract_number    AS contract_number
            ,xclw.contract_line_num  AS contract_line_num
            ,xclw.lease_company      AS lease_company 
      FROM   xxcff_cont_lines_work   xclw
      WHERE  NOT EXISTS
       (SELECT null
        FROM   xxcff_cont_headers_work xchw
        WHERE  xchw.file_id          =  in_file_id
        AND    xchw.contract_number  =  xclw.contract_number
        AND    xchw.lease_company    =  xclw.lease_company)
      AND    xclw.file_id = in_file_id;
    -- *** ���[�J���E���R�[�h ***
    xclw_exist_data_rec xclw_exist_data_cur%ROWTYPE;
--
    -- �P�_�񖾍א��`�F�b�N�p
    CURSOR xclw_line_num_data_cur
    IS
      SELECT xclw.contract_number   AS contract_number
            ,xclw.lease_company     AS lease_company
            ,COUNT(*)               AS seqno
      FROM   xxcff_cont_lines_work  xclw
      WHERE  xclw.file_id       = in_file_id
      GROUP  BY xclw.contract_number
               ,xclw.lease_company
      HAVING COUNT(*) > 999;
    -- *** ���[�J���E���R�[�h ***
    xclw_line_num_data_rec xclw_line_num_data_cur%ROWTYPE;
--
    -- �����R�[�h�`�F�b�N�p
    CURSOR xclw_object_data_cur
    IS
      SELECT xclw.object_code       AS object_code
            ,COUNT(*)               AS seqno
      FROM   xxcff_cont_lines_work  xclw
      WHERE  xclw.file_id  = in_file_id
      GROUP  BY xclw.object_code 
      HAVING COUNT(*) > 1;
    -- *** ���[�J���E���R�[�h ***
    xclw_object_data_rec xclw_object_data_cur%ROWTYPE;
--  
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_err_flag   := cv_const_n;
    lv_err_flag_1 := cv_const_n;
    lv_err_flag_2 := cv_const_n;
    lv_err_flag_3 := cv_const_n;
    lv_err_flag_4 := cv_const_n;
    lv_err_flag_5 := cv_const_n;
    lv_err_flag_6 := cv_const_n;
    --
    -- ***************************************************
    -- 1.���[�X�_�񃏁[�N��̌_��ԍ��d���`�F�b�N
    -- **************************************************
    OPEN xchw_double_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xchw_double_data_cur INTO xchw_double_data_rec;
      EXIT WHEN xchw_double_data_cur%NOTFOUND;
--
        --�G���[�Ώۃ��R�[�h�̏o��
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                       cv_msg_cff_00146,    -- ���b�Z�[�W�F���[�X�_��G���[�Ώ�
                       cv_tk_cff_00009_01,  -- �_��ԍ�
                       xchw_double_data_rec.contract_number, 
                       cv_tk_cff_00009_02,  -- ���[�X���
                       xchw_double_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --�G���[���b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00119     -- ���b�Z�[�W�F�_��ԍ��d���G���[
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --�G���[�����̃J�E���g
        IF (lv_err_flag_1 = cv_const_n) THEN
          lv_err_flag_1 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xchw_double_data_cur;
--
    -- ***************************************************
    -- 2.���[�X�_�񃏁[�N��̌_��ԍ����݃`�F�b�N
    -- ***************************************************
    OPEN xchw_exist_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xchw_exist_data_cur INTO xchw_exist_data_rec;
      EXIT WHEN xchw_exist_data_cur%NOTFOUND;
--
        --�G���[�Ώۃ��R�[�h�̏o��
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                       cv_msg_cff_00146,    -- ���b�Z�[�W�F���[�X�_��G���[�Ώ�
                       cv_tk_cff_00009_01,  -- �_��ԍ�
                       xchw_exist_data_rec.contract_number, 
                       cv_tk_cff_00009_02,  -- ���[�X���
                       xchw_exist_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --�G���[���b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00127     -- ���b�Z�[�W�F�_��ԍ��s�����G���[
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --�G���[�����̃J�E���g
        IF (lv_err_flag_2 = cv_const_n) THEN
          lv_err_flag_2 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xchw_exist_data_cur;
--
    -- ***************************************************
    -- 3.���[�X�_�񃏁[�N��̌_��ԍ����݃`�F�b�N
    -- ***************************************************
    OPEN xclw_double_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_double_data_cur INTO xclw_double_data_rec;
      EXIT WHEN xclw_double_data_cur%NOTFOUND;
--
        --�G���[�Ώۃ��R�[�h�̏o��
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                       cv_msg_cff_00147,    -- ���b�Z�[�W�F���[�X�_�񖾍׃G���[�Ώ�
                       cv_tk_cff_00009_01,  -- �_��ԍ�
                       xclw_double_data_rec.contract_number, 
                       cv_tk_cff_00009_03,  -- �_�񖾍�
                       xclw_double_data_rec.contract_line_num, 
                       cv_tk_cff_00009_02,  -- ���[�X���
                       xclw_double_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --�G���[���b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00067     -- ���b�Z�[�W�F�_��}�ԏd���G���[
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --�G���[�����̃J�E���g
        IF (lv_err_flag_3 = cv_const_n) THEN
          lv_err_flag_3 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xclw_double_data_cur;
--
    -- ***************************************************
    -- 4.���[�X�_�񖾍׃��[�N��̌_��ԍ����݃`�F�b�N
    -- ***************************************************
    OPEN xclw_exist_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_exist_data_cur INTO xclw_exist_data_rec;
      EXIT WHEN xclw_exist_data_cur%NOTFOUND;
--
        --�G���[�Ώۃ��R�[�h�̏o��
        lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                       cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                       cv_msg_cff_00147,    -- ���b�Z�[�W�F���[�X�_�񖾍׃G���[�Ώ�
                       cv_tk_cff_00009_01,  -- �_��ԍ�
                       xclw_exist_data_rec.contract_number, 
                       cv_tk_cff_00009_03,  -- �_�񖾍�
                       xclw_exist_data_rec.contract_line_num, 
                       cv_tk_cff_00009_02,  -- ���[�X���
                       xclw_exist_data_rec.lease_company
                      ),1,5000);
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_info
        );
        --�G���[���b�Z�[�W�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00068     -- ���b�Z�[�W�F�_��}�ԕs�����G���[
                    ),1,5000)
        );
        lv_err_flag := cv_const_y;
        --�G���[�����̃J�E���g
        IF (lv_err_flag_4 = cv_const_n) THEN
          lv_err_flag_4 := cv_const_y;
          gn_error_cnt  := gn_error_cnt + 1;
        END IF;
    END LOOP;
    CLOSE xclw_exist_data_cur;
--
    -- ***************************************************
    -- 5.�P�_�񖾍א��`�F�b�N�p
    -- ***************************************************
    OPEN xclw_line_num_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_line_num_data_cur INTO xclw_line_num_data_rec;
      EXIT WHEN xclw_line_num_data_cur%NOTFOUND;
--
      --�G���[�Ώۃ��R�[�h�̏o��
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00146,    -- ���b�Z�[�W�F���[�X�_��G���[�Ώ�
                      cv_tk_cff_00009_01,  -- �_��ԍ�
                      xclw_line_num_data_rec.contract_number, 
                      cv_tk_cff_00009_02,  -- ���[�X���
                      xclw_line_num_data_rec.lease_company
                     ),1,5000);
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_info
      );
      --�G���[���b�Z�[�W�̏o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                    cv_msg_cff_00150     -- ���b�Z�[�W�F�_�񖾍׌����G���[
                  ),1,5000)
      );
      lv_err_flag := cv_const_y;
      --�G���[�����̃J�E���g
      IF (lv_err_flag_5 = cv_const_n) THEN
        lv_err_flag_5 := cv_const_y;
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
    END LOOP;
    CLOSE xclw_line_num_data_cur;
--
    -- ***************************************************
    -- 6. �����R�[�h�`�F�b�N�p
    -- ***************************************************
    OPEN xclw_object_data_cur;
    gn_target_cnt := gn_target_cnt + 1;
    LOOP
      FETCH xclw_object_data_cur INTO xclw_object_data_rec;
      EXIT WHEN xclw_object_data_cur%NOTFOUND;
--
      --�G���[���b�Z�[�W�̏o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                    cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                    cv_msg_cff_00145,    -- ���b�Z�[�W�F�����R�[�h�d���G���[
                    cv_tk_cff_00009_04,  -- �����R�[�h
                    xclw_object_data_rec.object_code
                  ),1,5000)
      );
      lv_err_flag := cv_const_y;
      --�G���[�����̃J�E���g
      IF (lv_err_flag_6 = cv_const_n) THEN
        lv_err_flag_6 := cv_const_y;
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
    END LOOP;
    -- �����R�[�h�`�F�b�N�p
    CLOSE xclw_object_data_cur;
--   
   --�G���[���ݎ�
   IF (lv_err_flag = cv_const_y) THEN
       ov_retcode := cv_status_error;
   END IF;
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
      IF (xchw_double_data_cur%ISOPEN) THEN
        CLOSE xchw_double_data_cur;
      END IF;
      IF (xchw_exist_data_cur%ISOPEN) THEN
        CLOSE xchw_exist_data_cur;
      END IF;
      IF (xclw_double_data_cur%ISOPEN) THEN
        CLOSE xclw_double_data_cur;
      END IF;
      IF (xclw_exist_data_cur%ISOPEN) THEN
        CLOSE xclw_exist_data_cur;
      END IF;
      IF (xclw_line_num_data_cur%ISOPEN) THEN
        CLOSE xclw_line_num_data_cur;
      END IF;
      IF (xclw_object_data_cur%ISOPEN) THEN
        CLOSE xclw_object_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_rept_adjust;
--  
 /**********************************************************************************
   * Procedure Name   : chk_cont_header 
   * Description      : �_�񃏁[�N�`�F�b�N����        (A-8)
   ***********************************************************************************/
  PROCEDURE chk_cont_header(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.�G���[�t���O  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cont_header'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_lease_type_1        CONSTANT VARCHAR2(1) := '1'; -- ����_��
    cv_payment_type_0      CONSTANT VARCHAR2(1) := '0'; -- ����
    cv_payment_type_1      CONSTANT VARCHAR2(1) := '1'; -- ��N�
--
    cv_frequency_min_0     CONSTANT NUMBER(3)   := 1;
    cv_frequency_max_0     CONSTANT NUMBER(3)   := 600;
    cv_frequency_min_1     CONSTANT NUMBER(3)   := 1;
    cv_frequency_max_1     CONSTANT NUMBER(3)   := 50;
--
    cn_month               CONSTANT NUMBER(2)   := 12;
    cv_payment_frequency_3 CONSTANT NUMBER(3)   := 3;
    cv_re_lease_time       CONSTANT NUMBER(3)   := 0;
--
    --*** ���[�J���ϐ� ***
    lv_err_flag          VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_info          VARCHAR2(5000);   -- �G���[�Ώۏ��
--
    lv_lease_type        xxcff_contract_headers.lease_type%TYPE;
    lv_lease_class       xxcff_contract_headers.lease_class%TYPE;
    lv_lease_company     xxcff_contract_headers.lease_company%TYPE;
    lv_payment_type      xxcff_contract_headers.payment_type%TYPE;
    ld_lease_end_date    xxcff_contract_headers.lease_end_date%TYPE;
    ld_last_end_date     xxcff_contract_headers.lease_end_date%TYPE;
    lv_tax_code          xxcff_contract_headers.tax_code%TYPE;
    lv_vdsh_flag         VARCHAR2(1);      -- ���̋@sh�t���O    
-- V1.12 2018/09/10 Added START
    lv_ret_dff4    fnd_lookup_values.attribute4%TYPE;   --  ���[�X����DFF4
    lv_ret_dff5    fnd_lookup_values.attribute5%TYPE;   --  ���[�X����DFF5
    lv_ret_dff6    fnd_lookup_values.attribute6%TYPE;   --  ���[�X����DFF6
    lv_ret_dff7    fnd_lookup_values.attribute7%TYPE;   --  ���[�X����DFF7
-- V1.12 2018/09/10 Added END
    lv_first_date        DATE;
    lv_second_date       DATE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�_�񃏁[�N�J�[�\����`
    CURSOR xchw_data_cur
    IS
      SELECT xchw.contract_number      AS contract_number
            ,xchw.lease_class          AS lease_class
            ,xchw.lease_type           AS lease_type
            ,xchw.lease_company        AS lease_company
            ,xchw.contract_date        AS contract_date
            ,xchw.payment_frequency    AS payment_frequency
            ,xchw.payment_type         AS payment_type 
            ,xchw.lease_start_date     AS lease_start_date
            ,xchw.first_payment_date   AS first_payment_date
            ,xchw.second_payment_date  AS second_payment_date
            ,xchw.tax_code             AS tax_code
      FROM  xxcff_cont_headers_work  xchw
      WHERE xchw.file_id             = in_file_id;
    -- *** ���[�J���E���R�[�h ***
    xchw_data_rec xchw_data_cur%ROWTYPE;
--
    -- �_��ԍ��`�F�b�N�p
    CURSOR xch_cont_double_data_cur
    IS
      SELECT xch.contract_number
      FROM   xxcff_contract_headers  xch
      WHERE  xch.contract_number   = xchw_data_rec.contract_number
      AND    xch.lease_company     = xchw_data_rec.lease_company
      AND    xch.re_lease_times       = cv_re_lease_time;
    -- *** ���[�J���E���R�[�h ***
    xch_cont_double_data_rec xch_cont_double_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN xchw_data_cur;
    LOOP
      FETCH xchw_data_cur INTO xchw_data_rec;
      EXIT WHEN xchw_data_cur%NOTFOUND;
      -- ���������̃J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      -- ������
      lv_err_flag := cv_const_n;
      
      -- �G���[�Ώۏ��̕ҏW
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00146,                -- ���b�Z�[�W�F���[�X�_��G���[�Ώ�
                      cv_tk_cff_00009_01,              -- �_��ԍ�
                      xchw_data_rec.contract_number,   
                      cv_tk_cff_00009_02,              -- ���[�X���
                      xchw_data_rec.lease_company
                    ),1,5000);
--
      -- ***************************************************
      -- 1. �_��ԍ�
      -- ***************************************************
      -- ���[�X�_��Ƃ̑��݃`�F�b�N
      OPEN xch_cont_double_data_cur;
      FETCH xch_cont_double_data_cur INTO xch_cont_double_data_rec;
      IF (xch_cont_double_data_cur%FOUND) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00044     -- ���b�Z�[�W�F�_��ԍ����݃G���[
                    ),1,5000)
        );
      END IF;
      CLOSE xch_cont_double_data_cur;
--
      -- ***************************************************
      -- 2. ���[�X�敪
      -- ***************************************************
      BEGIN
        SELECT xltv.lease_type_code
        INTO   lv_lease_type 
        FROM   xxcff_lease_type_v   xltv
        WHERE  xltv.lease_type_code = xchw_data_rec.lease_type
        AND    xltv.enabled_flag    = cv_const_y
        AND  NVL( xltv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xltv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00013,    -- ���b�Z�[�W�F���E�l�G���[
                        cv_tk_cff_00013_01,  -- �J�����_����
                        cv_msg_cff_50042,    -- ���[�X�敪
                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                        xchw_data_rec.lease_type
                      ),1,5000)
          );
      END;
--
      -- ***************************************************
      -- 3. ���[�X���
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT xlcv.lease_class_code
              ,xlcv.vdsh_flag
        INTO   lv_lease_class
              ,lv_vdsh_flag
        FROM   xxcff_lease_class_v   xlcv
        WHERE  xlcv.lease_class_code = xchw_data_rec.lease_class
        AND    xlcv.enabled_flag     = cv_const_y
        AND  NVL( xlcv.start_date_active, TO_DATE(gr_init_rec.process_date,'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xlcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00013,    -- ���b�Z�[�W�F���E�l�G���[
                        cv_tk_cff_00013_01,  -- �J�����_����
                        cv_msg_cff_50041,    -- ���[�X���
                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                        xchw_data_rec.lease_class
                      ),1,5000)
         );
      END;
      -- 2.���̋@_SH�͑ΏۊO
      IF (lv_vdsh_flag = cv_const_y) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00122     -- ���b�Z�[�W�F���[�X��ʃG���[
                   ),1,5000)
        );
      END IF;
 --
      -- ***************************************************
      -- 4. ���[�X���
      -- ***************************************************
      BEGIN
        SELECT xlcv.lease_company_code
        INTO   lv_lease_company
        FROM   xxcff_lease_company_v   xlcv
        WHERE  xlcv.lease_company_code = xchw_data_rec.lease_company
        AND    xlcv.enabled_flag       = cv_const_y
        AND  NVL( xlcv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xlcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00013,    -- ���b�Z�[�W�F���E�l�G���[
                        cv_tk_cff_00013_01,  -- �J�����_����
                        cv_msg_cff_50043,    -- ���[�X���
                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                        xchw_data_rec.lease_company
                      ),1,5000)
          );
      END;
 --
      -- ***************************************************
      -- 5. �p�x
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT xptv.payment_type_code
        INTO   lv_payment_type
        FROM   xxcff_payment_type_v xptv
        WHERE  xptv.payment_type_code = xchw_data_rec.payment_type
        AND    xptv.enabled_flag      = cv_const_y
        AND  NVL( xptv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xptv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00013,    -- ���b�Z�[�W�F���E�l�G���[
                        cv_tk_cff_00013_01,  -- �J�����_����
                        cv_msg_cff_50048,    -- �p�x
                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                        xchw_data_rec.payment_type
                      ),1,5000)
          );
      END;
--
      -- ***************************************************
      -- 6. �x����
      -- ***************************************************
      -- 1.���E�l�`�F�b�N
      IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
        IF ((xchw_data_rec.payment_frequency < cv_frequency_min_0) OR
            (xchw_data_rec.payment_frequency > cv_frequency_max_0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,             -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00016,           -- ���b�Z�[�W�F�x���񐔋��E�l�G���[
                        cv_tk_cff_00013_01,         -- �J�����_����
                        cv_msg_cff_50047,           -- �x����
                        cv_tk_cff_00016_01,         -- ���E�l�G���[�͈̔�(MIN)
                        cv_frequency_min_0,
                        cv_tk_cff_00016_02,         -- ���E�l�G���[�͈̔�(MAX)
                        cv_frequency_max_0  
                      ),1,5000)
          );
        END IF;
      ELSIF (xchw_data_rec.payment_type = cv_payment_type_1 ) THEN
        IF ((xchw_data_rec.payment_frequency < cv_frequency_min_1  ) OR
            (xchw_data_rec.payment_frequency > cv_frequency_max_1  )) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00016,    -- ���b�Z�[�W�F�x���񐔋��E�l�G���[
                        cv_tk_cff_00016_01,  -- ���E�l�G���[�͈̔�(MIN)
                        cv_frequency_min_1  ,
                        cv_tk_cff_00016_02,  -- ���E�l�G���[�͈̔�(MAX)
                        cv_frequency_max_1  
                      ),1,5000)
          );
        END IF;
      END IF;
      -- 2.���͒l�`�F�b�N
-- V1.12 2018/09/10 Modified START
--      IF (xchw_data_rec.lease_type = cv_lease_type_1) THEN
--        IF (MOD(xchw_data_rec.payment_frequency,cn_month) <> 0) THEN
--          IF (lv_err_flag = cv_const_n) THEN
--            FND_FILE.PUT_LINE(
--              which  => FND_FILE.OUTPUT
--             ,buff   => lv_err_info
--            );
--          END IF;
--          lv_err_flag := cv_const_y;
--          -- �G���[���e�̏o��
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                        cv_msg_cff_00014,    -- ���b�Z�[�W�F�x���񐔓��͒l�G���[
--                        cv_tk_cff_00013_01,  -- �J�����_����
--                        cv_msg_cff_50047,    -- �x����
--                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
--                        cn_month
--                     ),1,5000)
--          );
--        END IF;
--      END IF;
      --  ���[�X���菈��
      xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>    lv_lease_class
        ,ov_ret_dff4    =>    lv_ret_dff4           -- DFF4(���{��A�g)
        ,ov_ret_dff5    =>    lv_ret_dff5           -- DFF5(IFRS�A�g)
        ,ov_ret_dff6    =>    lv_ret_dff6           -- DFF6(�d��쐬)
        ,ov_ret_dff7    =>    lv_ret_dff7           -- DFF7(���[�X���菈��)
        ,ov_errbuf      =>    lv_errbuf
        ,ov_retcode     =>    lv_retcode
        ,ov_errmsg      =>    lv_errmsg
      );
      -- ���ʊ֐��G���[�̏ꍇ
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                                                       cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                                                       cv_tk_cff_00094_01,  -- ���ʊ֐���
                                                       cv_msg_cff_50323  )  -- �t�@�C��ID
                                                      || cv_msg_part
                                                      || lv_errmsg          --���ʊ֐���װү����
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --  ���_��ŁA���[�X���菈��1�̏ꍇ�A�x���񐔂�12�̔{���łȂ���΂Ȃ�Ȃ�
      IF (xchw_data_rec.lease_type = cv_lease_type_1) THEN
        IF ( lv_ret_dff7 = cv_lease_cls_chk1 ) THEN
          IF (MOD(xchw_data_rec.payment_frequency,cn_month) <> 0) THEN
            IF (lv_err_flag = cv_const_n) THEN
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_err_info
              );
            END IF;
            lv_err_flag := cv_const_y;
            -- �G���[���e�̏o��
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                          cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                          cv_msg_cff_00014,    -- ���b�Z�[�W�F�x���񐔓��͒l�G���[
                          cv_tk_cff_00013_01,  -- �J�����_����
                          cv_msg_cff_50047,    -- �x����
                          cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                          cn_month
                       ),1,5000)
            );
          END IF;
        END IF;
      END IF;
-- V1.12 2018/09/10 Modified END
--
      -- ***************************************************
      -- 7. ���[�X�_���
      -- ***************************************************
      IF (TO_CHAR(gr_init_rec.process_date,'YYYYMM') < TO_CHAR(xchw_data_rec.contract_date,'YYYYMM')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00083     -- ���b�Z�[�W�F�_����Ó����G���[
                    ),1,5000)
        );
      END IF;
--
      -- ***************************************************
      -- 8. ���[�X�J�n��
      -- ***************************************************
      IF (TO_CHAR(xchw_data_rec.lease_start_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.contract_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00043     -- ���b�Z�[�W�F���[�X�J�n���Ó����G���[
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 9. ����x����
      -- ***************************************************
      IF (TO_CHAR(xchw_data_rec.first_payment_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.lease_start_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00022     -- ���b�Z�[�W�F����x�����Ó����G���[
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 10. �Q��ڎx����
      -- ***************************************************
      -- 1. �Q��ڎx����������x����
      IF (TO_CHAR(xchw_data_rec.second_payment_date,'YYYYMMDD') < TO_CHAR(xchw_data_rec.first_payment_date,'YYYYMMDD')) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00056     -- ���b�Z�[�W�F2��ڎx�����Ó����G���[�i����x�����O�j
                    ),1,5000)
        );
      END IF;
      -- 2. �Q��ڎx����(�N��)������x����
      IF (TO_CHAR(xchw_data_rec.second_payment_date,'YYYYMM') > 
        TO_CHAR(ADD_MONTHS(xchw_data_rec.first_payment_date,1),'YYYYMM')) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00055     -- ���b�Z�[�W�F2��ڎx�����Ó����G���[�i����x�������X���ȍ~�j
                    ),1,5000)
        );
      END IF;  
      -- (���[�X�I����)
      IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
        ld_lease_end_date := ADD_MONTHS(xchw_data_rec.lease_start_date,xchw_data_rec.payment_frequency) - 1;
      ELSIF (xchw_data_rec.payment_type = cv_payment_type_1 ) THEN
        ld_lease_end_date := ADD_MONTHS(xchw_data_rec.lease_start_date,xchw_data_rec.payment_frequency*12) -1;
      END IF;
--
      -- (�ŏI�x����)
      --  �x���񐔂��R�񖢖��̏ꍇ�͂Q��ڎx������ݒ肷��B
      IF (xchw_data_rec.payment_frequency < cv_payment_frequency_3) THEN
        ld_last_end_date  := xchw_data_rec.second_payment_date;
      ELSE
        -- �������ȊO�̎�
        IF (xchw_data_rec.second_payment_date) <> LAST_DAY(xchw_data_rec.second_payment_date) THEN
          IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
            ld_last_end_date  := ADD_MONTHS(xchw_data_rec.second_payment_date,xchw_data_rec.payment_frequency -2);
          ELSE
            ld_last_end_date  := ADD_MONTHS(xchw_data_rec.second_payment_date,(xchw_data_rec.payment_frequency-2)*12);
          END IF;
        -- �������̎�
        ELSE
          IF (xchw_data_rec.payment_type = cv_payment_type_0) THEN
            ld_last_end_date  := LAST_DAY(ADD_MONTHS(xchw_data_rec.second_payment_date,xchw_data_rec.payment_frequency -2));
          ELSE 
            ld_last_end_date  := LAST_DAY(ADD_MONTHS(xchw_data_rec.second_payment_date,(xchw_data_rec.payment_frequency-2)*12));
          END IF;
        END IF;
      END IF;
--
--DEL 2009/11/27 START
/*
      IF (TO_CHAR(ld_lease_end_date,'YYYYMMDD') < TO_CHAR(ld_last_end_date,'YYYYMMDD')) THEN
        IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00031     -- ���b�Z�[�W�F�x�����Ó����G���[
                    ),1,5000)
        );
      END IF; 
*/
--DEL 2009/11/27 END
--
      --***************************************************
      -- 12. �ŋ��R�[�h
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT atc.name
        INTO   lv_tax_code
        FROM   ap_tax_codes atc
        WHERE  atc.name = xchw_data_rec.tax_code
--[��QT1_1225] MOD START
--      AND    atc.enabled_flag  = cv_const_y;
        AND    atc.enabled_flag  = cv_const_y
        AND  NVL( atc.start_date, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date
        AND  NVL( atc.inactive_date, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date;
--[��QT1_1225] MOD END 
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00013,    -- ���b�Z�[�W�F���E�l�G���[
                        cv_tk_cff_00013_01,  -- �J�����_����
                        cv_msg_cff_50148,    -- �ŋ��R�[�h
                        cv_tk_cff_00013_02,  -- ���E�l�G���[�͈̔�(MIN)
                        xchw_data_rec.tax_code
                      ),1,5000)
         );
      END;
      --�G���[���ݎ�
      IF (lv_err_flag = cv_const_y) THEN
        ov_err_flag   := cv_const_y;
        -- ���������̃J�E���g
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
    END LOOP;
--
    CLOSE xchw_data_cur;
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
      IF (xchw_data_cur%ISOPEN) THEN
        CLOSE xchw_data_cur;
      END IF;
      IF (xch_cont_double_data_cur%ISOPEN) THEN
        CLOSE xch_cont_double_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_cont_header;
--
 /**********************************************************************************
   * Procedure Name   : chk_cont_line
   * Description      : �_�񖾍׃��[�N�`�F�b�N����        (A-9)
   ***********************************************************************************/
  PROCEDURE chk_cont_line(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.�G���[�t���O  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cont_line'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ����_��
--
    --*** ���[�J���ϐ� ***
    lv_err_flag          VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_info          VARCHAR2(5000);   -- �G���[�Ώۏ��
--
    lv_objectcode        xxcff_object_headers.object_code%TYPE;
    ln_object_id         xxcff_contract_lines.object_header_id%TYPE;
    ln_contact_id        xxcff_contract_lines.contract_header_id%TYPE;
    ln_line_id           xxcff_contract_lines.contract_line_id%TYPE;
    ln_re_lease_times    xxcff_contract_headers.re_lease_times%TYPE;
    lv_lease_class       xxcff_contract_headers.lease_class%TYPE;
    lv_lease_type        xxcff_contract_headers.lease_type%TYPE;
    ln_payment_frequency xxcff_contract_headers.payment_frequency%TYPE;
    lv_category_code     xxcff_contract_lines.asset_category%TYPE;
    lv_live_month        VARCHAR2(2);
    ln_category_id       NUMBER(15);
-- 2018/03/27 Ver1.10 Otsuka ADD Start
    lv_ret_dff4    VARCHAR2(1);    -- ���[�X����DFF4
    lv_ret_dff5    VARCHAR2(1);    -- ���[�X����DFF5
    lv_ret_dff6    VARCHAR2(1);    -- ���[�X����DFF6
    lv_ret_dff7    VARCHAR2(1);    -- ���[�X����DFF7
-- 2018/03/27 Ver1.10 Otsuka ADD End
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�_�񖾍׃��[�N�J�[�\����`
    CURSOR xclw_data_cur
    IS
      SELECT xclw.contract_number      AS contract_number
            ,xclw.contract_line_num    AS contract_line_num
            ,xclw.lease_company        AS lease_company
            ,xclw.object_code          AS object_code
            ,xclw.asset_category       AS asset_category
            ,xclw.first_charge         AS first_charge
            ,xclw.first_tax_charge     AS first_tax_charge
            ,xclw.second_charge        AS second_charge
            ,xclw.second_tax_charge    AS second_tax_charge
            ,xclw.first_deduction      AS first_deduction
            ,xclw.first_tax_deduction  AS first_tax_deduction
-- 2018/03/27 Ver1.10 Otsuka ADD Start
            ,xclw.estimated_cash_price AS estimated_cash_price
            ,xclw.life_in_months       AS life_in_months
-- 2018/03/27 Ver1.10 Otsuka ADD End
      FROM  xxcff_cont_lines_work  xclw
      WHERE xclw.file_id             = in_file_id;
    -- *** ���[�J���E���R�[�h ***
    xclw_data_rec xclw_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN xclw_data_cur;
    LOOP
      FETCH xclw_data_cur INTO xclw_data_rec;
      EXIT WHEN xclw_data_cur%NOTFOUND;
      -- ���������̃J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      -- ������
      lv_err_flag := cv_const_n;
      -- �G���[�Ώۏ��̕ҏW
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00009,                -- ���b�Z�[�W�F�G���[�Ώ�
                      cv_tk_cff_00009_01,              -- �_��ԍ�
                      xclw_data_rec.contract_number,
                      cv_tk_cff_00009_02,              -- ���[�X���
                      xclw_data_rec.lease_company,
                      cv_tk_cff_00009_03,              -- �_��}��
                      xclw_data_rec.contract_line_num,
                      cv_tk_cff_00009_04,              -- �����R�[�h
                      xclw_data_rec.object_code
                    ),1,5000);
--
      -- ***************************************************
      -- 1. ���[�X�_�񃏁[�N�̌���
      -- ***************************************************
      SELECT xchw.re_lease_times
            ,xchw.lease_class
            ,xchw.lease_type
            ,xchw.payment_frequency
      INTO   ln_re_lease_times
            ,lv_lease_class
            ,lv_lease_type
            ,ln_payment_frequency
      FROM   xxcff_cont_headers_work  xchw
      WHERE  xchw.contract_number     = xclw_data_rec.contract_number
      AND    xchw.lease_company       = xclw_data_rec.lease_company;
      -- ***************************************************
      -- 2. �����R�[�h
      -- ***************************************************
      -- 1.�����R�[�h�̑��݃`�F�b�N
      xxcff_common2_pkg.get_lease_key(
        iv_objectcode => xclw_data_rec.object_code  --   1.�����R�[�h(�K�{)
       ,on_object_id  => ln_object_id               --   2.���������h�c
       ,on_contact_id => ln_contact_id              --   3.�_������h�c
       ,on_line_id    => ln_line_id                 --   4.�_�񖾍ד����h�c
       ,ov_retcode    => lv_retcode
       ,ov_errbuf     => lv_errbuf
       ,ov_errmsg     => lv_errmsg
      );
      --�����R�[�h���o�^�ς̎�
      IF (ln_object_id  IS NOT NULL) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
        END IF;
        lv_err_flag := cv_const_y;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00160,    -- ���b�Z�[�W�F�����R�[�h���݃G���[
                      cv_tk_cff_00009_04,  -- �g�[�N���F�����R�[�h
                      xclw_data_rec.object_code
                    ),1,5000)
        );
      END IF;
      -- ***************************************************
      -- 3. ���Y���
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT xcv.category_code
        INTO   lv_category_code
        FROM   xxcff_category_v xcv
        WHERE  xcv.category_code = xclw_data_rec.asset_category
        AND    xcv.enabled_flag  = cv_const_y
        AND  NVL( xcv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xcv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00069     -- ���b�Z�[�W�F���Y��ރ}�X�^�G���[
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 4. �ϗp�N��
      -- ***************************************************
      IF (lv_lease_type = cv_lease_type_1) THEN
        -- �ϗp�N�����Z�o����B
-- V1.12 2018/09/10 Modified START
--        lv_live_month :=  round(ln_payment_frequency / cn_month);
        --  12�Ŋ���؂�Ȃ��ꍇ�͐؏グ
        IF ( ( ln_payment_frequency / cn_month ) <> TRUNC( ln_payment_frequency / cn_month ) ) THEN
          lv_live_month :=  TO_CHAR( TRUNC( ln_payment_frequency / cn_month ) + 1 );
        ELSE
          lv_live_month :=  TO_CHAR( ln_payment_frequency / cn_month );
        END IF;
-- V1.12 2018/09/10 Modified END
        -- �ϗp�N���`�F�b�N
        xxcff_common1_pkg.chk_life(
          iv_category           => xclw_data_rec.asset_category --   1.���Y���
         ,iv_life               => lv_live_month                --   2.�ϗp�N��
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00149     -- ���b�Z�[�W�F�ϗp�N���G���[
                      ),1,5000)
          );
        END IF;
      END IF;
      -- ***************************************************
      -- 5. ���Y�J�e�S��
      -- ***************************************************
      IF (lv_lease_type = cv_lease_type_1) THEN
        -- �ϗp�N�����Z�o����B
-- V1.12 2018/09/10 Modified START
--        lv_live_month :=  round(ln_payment_frequency / cn_month);
        --  12�Ŋ���؂�Ȃ��ꍇ�͐؏グ
        IF ( ( ln_payment_frequency / cn_month ) <> TRUNC( ln_payment_frequency / cn_month ) ) THEN
          lv_live_month :=  TO_CHAR( TRUNC( ln_payment_frequency / cn_month ) + 1 );
        ELSE
          lv_live_month :=  TO_CHAR( ln_payment_frequency / cn_month );
        END IF;
-- V1.12 2018/09/10 Modified END
        -- ���Y�J�e�S���`�F�b�N
        xxcff_common1_pkg.chk_fa_category(
          iv_segment1    => xclw_data_rec.asset_category    -- ���
         ,iv_segment2    => NULL                            -- �\�����p
         ,iv_segment3    => NULL                            -- ���Y����
         ,iv_segment4    => NULL                            -- ���p�Ȗ�
         ,iv_segment5    => lv_live_month                   -- �ϗp�N��
         ,iv_segment6    => NULL                            -- ���p���@
         ,iv_segment7    => lv_lease_class                  -- ���[�X���
         ,on_category_id => ln_category_id
         ,ov_errbuf      => lv_errbuf 
         ,ov_retcode     => lv_retcode
         ,ov_errmsg      => lv_errmsg
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
      END IF;
      -- ***************************************************
      -- 6. ���z���[�X���T���z
      -- ***************************************************
--
      --DEL 2010/01/07 START
      --IF ((xclw_data_rec.first_charge  <= xclw_data_rec.first_deduction) OR
      --    (xclw_data_rec.second_charge <= xclw_data_rec.first_deduction)) THEN
      --  IF (lv_err_flag = cv_const_n) THEN
      --    FND_FILE.PUT_LINE(
      --      which  => FND_FILE.OUTPUT
      --     ,buff   => lv_err_info
      --    );
      --    lv_err_flag := cv_const_y;
      --  END IF;
      --  -- �G���[���e�̏o��
      --  FND_FILE.PUT_LINE(
      --    which  => FND_FILE.OUTPUT
      --   ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
      --                cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
      --                cv_msg_cff_00034     -- ���b�Z�[�W�F�T���z�G���[
      --              ),1,5000)
      --  );
      --END IF;
      --DEL 2010/01/07 START
--
-- 2018/05/25 Ver1.11 Mori DEL Start
--      -- ***************************************************
--      -- 7. ���z����Ŋz�T���z
--      -- ***************************************************
--      IF ((xclw_data_rec.first_tax_charge  <= xclw_data_rec.first_tax_deduction) OR
--          (xclw_data_rec.second_tax_charge <= xclw_data_rec.first_tax_deduction)) THEN
--        IF (lv_err_flag = cv_const_n) THEN
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          ,buff   => lv_err_info
--          );
--          lv_err_flag := cv_const_y;
--        END IF;
--        -- �G���[���e�̏o��
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
--                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
--                      cv_msg_cff_00034     -- ���b�Z�[�W�F�T���z�G���[
--                    ),1,5000)
--       );
--      END IF;
--      --�G���[���ݎ�
--      IF (lv_err_flag = cv_const_y) THEN
--        ov_err_flag   := cv_const_y;
--        -- ���������̃J�E���g
--        gn_error_cnt := gn_error_cnt + 1;
--      END IF;
-- 
-- 2018/05/25 Ver1.11 Mori DEL End
-- 2018/03/27 Ver1.10 Otsuka ADD Start
      -- ***************************************************
      -- 8. ���ό����w�����z
      -- ***************************************************
      -- ***************************************
      -- ***        �������̋L�q             ***
      -- ***       ���ʊ֐��̌Ăяo��        ***
      -- ***************************************
      --  ���[�X���菈��
      xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>    lv_lease_class
        ,ov_ret_dff4    =>    lv_ret_dff4           -- DFF4(���{��A�g)
        ,ov_ret_dff5    =>    lv_ret_dff5           -- DFF5(IFRS�A�g)
        ,ov_ret_dff6    =>    lv_ret_dff6           -- DFF6(�d��쐬)
        ,ov_ret_dff7    =>    lv_ret_dff7           -- DFF7(���[�X���菈��)
        ,ov_errbuf      =>    lv_errbuf
        ,ov_retcode     =>    lv_retcode
        ,ov_errmsg      =>    lv_errmsg
      );
      -- ���ʊ֐��G���[�̏ꍇ
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                                                       cv_msg_cff_00094,    -- ���b�Z�[�W�F���ʊ֐��G���[
                                                       cv_tk_cff_00094_01,  -- ���ʊ֐���
                                                       cv_msg_cff_50323  )  -- �t�@�C��ID
                                                      || cv_msg_part
                                                      || lv_errmsg          --���ʊ֐���װү����
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -- ���[�X���ʌ��ʂ��u1�v�̏ꍇ
      IF (lv_ret_dff7 = cv_lease_cls_chk1) THEN
        -- �����͂����0�̏ꍇ�G���[
        IF ((xclw_data_rec.estimated_cash_price IS NULL) OR 
            (xclw_data_rec.estimated_cash_price = 0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00282     -- ���b�Z�[�W�F���ό����w�����z�G���[
                      ),1,5000)
          );
        END IF;
      -- ���[�X���ʌ��ʂ��u2�v�̏ꍇ�A�����̓f�[�^��0�ɒu��������
      ELSE
        IF (xclw_data_rec.estimated_cash_price IS NULL) THEN
          xclw_data_rec.estimated_cash_price := NVL(TO_NUMBER(xclw_data_rec.estimated_cash_price),0);
        END IF;
      END IF;
      -- ***************************************************
      -- 9. �@��ϗp�N��
      -- ***************************************************
      -- ���[�X���ʌ��ʂ��u1�v�̏ꍇ
      IF (lv_ret_dff7 = cv_lease_cls_chk1) THEN
        -- �����͂����0�̏ꍇ�G���[
        IF ((xclw_data_rec.life_in_months IS NULL) OR
            (xclw_data_rec.life_in_months = 0)) THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
            lv_err_flag := cv_const_y;
          END IF;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00283     -- ���b�Z�[�W�F�@��ϗp�N���G���[
                      ),1,5000)
          );
        END IF;
      -- ���[�X���ʌ��ʂ��u2�v�̏ꍇ�A�����̓f�[�^��0�ɒu��������
      ELSE
        IF (xclw_data_rec.life_in_months IS NULL) THEN
          xclw_data_rec.life_in_months := NVL(xclw_data_rec.life_in_months,0);
        END IF;
      END IF;
-- 2018/03/27 Ver1.10 Otsuka ADD End
--  V1.12 2018/09/10 Added START
      --  �G���[���ݎ�
      IF ( lv_err_flag = cv_const_y ) THEN
        -- �G���[�t���O�ݒ�A�G���[�����J�E���g
        ov_err_flag   :=  cv_const_y;
        gn_error_cnt  :=  gn_error_cnt + 1;
      END IF;
--  V1.12 2018/09/10 Added END
--
    END LOOP;
--
    CLOSE xclw_data_cur;
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
      IF (xclw_data_cur%ISOPEN) THEN
        CLOSE xclw_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_cont_line;
--
 /**********************************************************************************
   * Procedure Name   : chk_obj_header
   * Description      : �������[�N�`�F�b�N����          (A-10)
   ***********************************************************************************/
  PROCEDURE chk_obj_header(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.�G���[�t���O  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_obj_header'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ����_��
--
    --*** ���[�J���ϐ� ***
    lv_err_flag          VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_info          VARCHAR2(5000);   -- �G���[�Ώۏ��
--
    lv_live_month        VARCHAR2(2);
    lv_owner_company     xxcff_object_headers.owner_company%TYPE;
    lv_department_code   xxcff_object_headers.department_code%TYPE;
    lv_location_id       NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�������[�N�J�[�\����`
    CURSOR xcow_data_cur
    IS
      SELECT xcow.contract_number      AS contract_number
            ,xcow.contract_line_num    AS contract_line_num
            ,xcow.lease_company        AS lease_company
            ,xcow.object_code          AS object_code
            ,xcow.po_number            AS po_number
            ,xcow.registration_number  AS registration_number
            ,xcow.age_type             AS age_type
            ,xcow.model                AS model
            ,xcow.serial_number        AS serial_number
            ,xcow.quantity             AS quantity
            ,xcow.manufacturer_name    AS manufacturer_name 
            ,xcow.department_code      AS department_code
            ,xcow.owner_company        AS owner_company
            ,xcow.chassis_number       AS chassis_number
      FROM  xxcff_cont_obj_work  xcow
      WHERE xcow.file_id             = in_file_id;
    -- *** ���[�J���E���R�[�h ***
    xcow_data_rec xcow_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN xcow_data_cur;
    LOOP
      FETCH xcow_data_cur INTO xcow_data_rec;
      EXIT WHEN xcow_data_cur%NOTFOUND;
      -- ���������̃J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      -- ������
      lv_err_flag := cv_const_n;
      -- �G���[�Ώۏ��̕ҏW
      lv_err_info :=SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,                  -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00009,                -- ���b�Z�[�W�F�G���[�Ώ�
                      cv_tk_cff_00009_01,              -- �_��ԍ�
                      xcow_data_rec.contract_number,
                      cv_tk_cff_00009_02,              -- ���[�X���
                      xcow_data_rec.lease_company,
                      cv_tk_cff_00009_03,              -- �_��}��
                      xcow_data_rec.contract_line_num,
                      cv_tk_cff_00009_04,              -- �����R�[�h
                      xcow_data_rec.object_code
                    ),1,5000);
--
      -- ***************************************************
      -- 1. �{��/�H��
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT xocv.owner_company_code
        INTO   lv_owner_company
        FROM   xxcff_owner_company_v xocv
        WHERE  xocv.owner_company_code = xcow_data_rec.owner_company
        AND    xocv.enabled_flag  = cv_const_y
        AND  NVL( xocv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xocv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00124,    -- ���b�Z�[�W�F���ڒl�Ó����`�F�b�N�G���[
                        cv_tk_cff_00124_01,  -- �J�����_����
                        cv_msg_cff_50012,    -- �{��/�H��
                        cv_tk_cff_00124_02,  -- �J������
                        xcow_data_rec.owner_company
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 2. �Ǘ�����
      -- ***************************************************
      -- 1.���݃`�F�b�N
      BEGIN
        SELECT xdv.department_code
        INTO   lv_department_code
        FROM   xxcff_department_v xdv
        WHERE  xdv.department_code = xcow_data_rec.department_code
        AND    xdv.enabled_flag  = cv_const_y
        AND  NVL( xdv.start_date_active, TO_DATE(gr_init_rec.process_date, 'YYYY/MM/DD'))
          <= gr_init_rec.process_date 
        AND  NVL( xdv.end_date_active, TO_DATE('9999/12/31', 'YYYY/MM/DD'))
          >= gr_init_rec.process_date; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          IF (lv_err_flag = cv_const_n) THEN
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_err_info
            );
          END IF;
          lv_err_flag := cv_const_y;
          -- �G���[���e�̏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                        cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                        cv_msg_cff_00124,    -- ���b�Z�[�W�F���ڒl�Ó����`�F�b�N�G���[
                        cv_tk_cff_00124_01,  -- �J�����_����
                        cv_msg_cff_50011,    -- �Ǘ�����
                        cv_tk_cff_00124_02,  -- �J������
                        xcow_data_rec.department_code
                      ),1,5000)
          );
      END;
      -- ***************************************************
      -- 3. ���Ə��}�X�^�̑g���킹�`�F�b�N
      -- ***************************************************
      -- ���Ə��}�X�^�`�F�b�N
      xxcff_common1_pkg.chk_fa_location(
        iv_segment1           => NULL                           -- 1.�\���n
       ,iv_segment2           => xcow_data_rec.department_code  -- 2.���Y���
       ,iv_segment3           => NULL                           -- 3.���Ə�
       ,iv_segment4           => NULL                           -- 4.�ꏊ
       ,iv_segment5           => xcow_data_rec.owner_company    -- 5.�H��/�{��
       ,on_location_id        => lv_location_id                 -- ���Ə�ID
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --
      IF (lv_retcode <> cv_status_normal) THEN
        IF (lv_err_flag = cv_const_n) THEN
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_info
          );
          lv_err_flag := cv_const_y;
        END IF;
        -- �G���[���e�̏o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => SUBSTRB(xxccp_common_pkg.get_msg(
                      cv_app_kbn_cff,      -- �A�v���P�[�V�����Z�k���FXXCFF
                      cv_msg_cff_00095,    -- ���b�Z�[�W�F���ʊ֐��G���[
                      cv_tk_cff_00095_01,  -- ���ʊ֐���
                      lv_errmsg            -- lv_errmsg
                    ),1,5000)
        );
      END IF;
      --�G���[���ݎ�
      IF (lv_err_flag = cv_const_y) THEN
        ov_err_flag   := cv_const_y;
        -- ���������̃J�E���g
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
-- 
    END LOOP;
--
    CLOSE xcow_data_cur;
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
      IF (xcow_data_cur%ISOPEN) THEN
        CLOSE xcow_data_cur;
      END IF;
    --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_obj_header;
 /**********************************************************************************
   * Procedure Name   : set_upload_item
   * Description      : �A�b�v���[�h���ڕҏW     (A-13)
   ***********************************************************************************/
  PROCEDURE set_upload_item(
    ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upload_item'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_payment_type_0       CONSTANT VARCHAR2(1) := '0';   --�p�x�F����
    cv_payment_type_1       CONSTANT VARCHAR2(1) := '1';   --�p�x�F��N�
--
    cn_last_payment_date    CONSTANT NUMBER(2)   :=  31; 
--
    cv_lease_type_1         CONSTANT VARCHAR2(1) := '1';   --���[�X�敪�F����_��
    cv_lease_type_2         CONSTANT VARCHAR2(1) := '2';   --���[�X�敪�F��ă��[�X�
--
    cv_cont_status_201      CONSTANT VARCHAR2(3) := '201'; --�_��X�e�[�^�X�F��o�^�ϣ
--
    cv_lease_payment_flag_1 CONSTANT VARCHAR2(1) := '1';   --�x�������t���O�F������
--
    cv_re_lease_flag_0      CONSTANT VARCHAR2(1) := '0';   --�ă��[�X�v
    cv_bond_accept_flag_0   CONSTANT VARCHAR2(1) := '0';   --�؏���̃t���O�u����́v
--
    cv_object_status_101    CONSTANT VARCHAR2(3) := '101'; -- 101:���_��
    cv_object_status_102    CONSTANT VARCHAR2(3) := '102'; -- 102:�_���
    
    --*** ���[�J���ϐ� ***
    lv_err_flag             VARCHAR2(1);                   -- �G���[���݃t���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- ***************************************************
  -- 1. ���[�X�_�񍀖ڕҏW
  -- ***************************************************
    gr_cont_hed_rec.contract_header_id      := NULL;                                   -- �_�����ID
    gr_cont_hed_rec.contract_number         := gr_contract_info_rec.contract_number;   -- �_��ԍ�
    gr_cont_hed_rec.lease_class             := gr_contract_info_rec.lease_class;       -- ���[�X���
    gr_cont_hed_rec.lease_type              := gr_contract_info_rec.lease_type;        -- ���[�X�敪
    gr_cont_hed_rec.lease_company           := gr_contract_info_rec.lease_company;     -- ���[�X���
    gr_cont_hed_rec.re_lease_times          := gr_contract_info_rec.re_lease_times;    -- �ă��[�X��
    gr_cont_hed_rec.comments                := gr_contract_info_rec.comments;          -- ����
    gr_cont_hed_rec.contract_date           := gr_contract_info_rec.contract_date;     -- ���[�X�_���
    gr_cont_hed_rec.payment_frequency       := gr_contract_info_rec.payment_frequency; -- �x����
    gr_cont_hed_rec.payment_type            := gr_contract_info_rec.payment_type;      -- �p�x
  -- �N��
    IF (gr_contract_info_rec.payment_type = cv_payment_type_0) THEN
      gr_cont_hed_rec.payment_years := ROUND(gr_contract_info_rec.payment_frequency/12);
    END IF;
  -- ���[�X�J�n��
    gr_cont_hed_rec.lease_start_date        := gr_contract_info_rec.lease_start_date;
  -- ���[�X�I����
    IF (gr_contract_info_rec.payment_type = cv_payment_type_0) THEN
        gr_cont_hed_rec.lease_end_date      :=
          ADD_MONTHS(gr_contract_info_rec.lease_start_date,gr_contract_info_rec.payment_frequency) - 1;
    ELSE
        gr_cont_hed_rec.lease_end_date      :=
          ADD_MONTHS(gr_contract_info_rec.lease_start_date,gr_contract_info_rec.payment_frequency * 12) - 1;
    END IF;
  -- ����x����
    gr_cont_hed_rec.first_payment_date      := gr_contract_info_rec.first_payment_date;
  -- �Q��ڎx����  
    gr_cont_hed_rec.second_payment_date     := gr_contract_info_rec.second_payment_date;
  -- 3��ڎx����
    IF (gr_contract_info_rec.second_payment_date = LAST_DAY(gr_cont_hed_rec.second_payment_date)) THEN
      gr_cont_hed_rec.third_payment_date    := cn_last_payment_date;
    ELSE
      gr_cont_hed_rec.third_payment_date    := TO_CHAR(gr_contract_info_rec.second_payment_date,'DD');
    END IF;
  -- ��p�v���v��v����
    gr_cont_hed_rec.start_period_name       := TO_CHAR(gr_contract_info_rec.first_payment_date,'YYYY-MM');
    gr_cont_hed_rec.lease_payment_flag      := cv_lease_payment_flag_1;                   -- �x���v�抮���t���O
-- 2013/07/05 Ver.1.8 T.Nakano MOD Start
--    gr_cont_hed_rec.tax_code                := gr_contract_info_rec.tax_code;             -- �ŃR�[�h
    gr_cont_hed_rec.tax_code                := NULL;                                      -- �ŋ��R�[�h
-- 2013/07/05 Ver.1.8 T.Nakano MOD End
  -- WHO�J����
    gr_cont_hed_rec.created_by              := cn_created_by;                             -- �쐬��
    gr_cont_hed_rec.creation_date           := cd_creation_date;                          -- �쐬��
    gr_cont_hed_rec.last_updated_by         := cn_last_updated_by;                        -- �ŏI�X�V��
    gr_cont_hed_rec.last_update_date        := cd_last_update_date;                       -- �ŏI�X�V��
    gr_cont_hed_rec.last_update_login       := cn_last_update_login;                      -- �ŏI�X�V۸޲�
    gr_cont_hed_rec.request_id              := cn_request_id;                             -- �v��ID
    gr_cont_hed_rec.program_application_id  := cn_program_application_id;                 -- �ݶ��ĥ��۸��ѥ���ع����ID
    gr_cont_hed_rec.program_id              := cn_program_id;                             -- �ݶ��ĥ��۸���ID
    gr_cont_hed_rec.program_update_date     := cd_program_update_date;                    -- ��۸��эX�V��
--
  -- ***************************************************
  -- 2. ���[�X�_�񖾍׍��ڕҏW
  -- ***************************************************
    gr_cont_line_rec.contract_line_id       := NULL;                                      -- �_�����ID
    gr_cont_line_rec.contract_header_id     := NULL;                                      -- �_���������ID
    gr_cont_line_rec.contract_line_num      := gr_contract_info_rec.contract_line_num;    -- �_��}��
-- 2013/07/05 Ver.1.8 T.Nakano ADD Start
    gr_cont_line_rec.tax_code               := gr_contract_info_rec.tax_code;             -- �ŋ��R�[�h
-- 2013/07/05 Ver.1.8 T.Nakano ADD End
  -- �_��X�e�[�^�X
    gr_cont_line_rec.contract_status        := cv_cont_status_201;
  --
    gr_cont_line_rec.first_charge           := gr_contract_info_rec.first_charge;         -- ���񌎊z���[�X��_���[�X��
    gr_cont_line_rec.first_tax_charge       := gr_contract_info_rec.first_tax_charge;     -- �������Ŋz_���[�X��
    gr_cont_line_rec.first_total_charge     := 
      gr_cont_line_rec.first_charge  + gr_cont_line_rec.first_tax_charge;                 -- ����v���[�X��
  --
    gr_cont_line_rec.second_charge          := gr_contract_info_rec.second_charge;        -- �Q��ڌ��z���[�X��_���[�X��
    gr_cont_line_rec.second_tax_charge      := gr_contract_info_rec.second_tax_charge;    -- �Q��ڏ���Ŋz_���[�X��
    gr_cont_line_rec.second_total_charge    := 
      gr_cont_line_rec.second_charge  + gr_cont_line_rec.second_tax_charge;               -- �Q��ڌv���[�X��
  --
    gr_cont_line_rec.first_deduction        := gr_contract_info_rec.first_deduction;      -- ���񌎊z���[�X��_�T���z
    gr_cont_line_rec.first_tax_deduction    := gr_contract_info_rec.first_tax_deduction;  -- �������Ŋz_�T���z
    gr_cont_line_rec.first_total_deduction  := 
      gr_cont_line_rec.first_deduction  + gr_cont_line_rec.first_tax_deduction ;          -- ����v�T���z
  --
--
    --UPD 2010/01/07 START
    --gr_cont_line_rec.second_deduction       := gr_contract_info_rec.first_deduction;      -- �Q��ڈȍ~���z���[�X��_�T���z
    gr_cont_line_rec.second_deduction       := gr_contract_info_rec.second_deduction;       -- �Q��ڈȍ~���z���[�X��_�T���z
    --UPD 2010/01/07 END
--
    gr_cont_line_rec.second_tax_deduction   := gr_contract_info_rec.first_tax_deduction;  -- �Q��ڈȍ~����Ŋz_�T���z
    gr_cont_line_rec.second_total_deduction := 
      gr_cont_line_rec.second_deduction + gr_cont_line_rec.second_tax_deduction ;         -- �Q��ڈȍ~�v�T���z
  -- ���z���[�X��_���[�X��
    gr_cont_line_rec.gross_charge           := gr_contract_info_rec.first_charge +
      (gr_contract_info_rec.second_charge * (gr_contract_info_rec.payment_frequency - 1));
  -- ���z����Ŋz_���[�X��
    gr_cont_line_rec.gross_tax_charge       := gr_contract_info_rec.first_tax_charge +
      (gr_contract_info_rec.second_tax_charge * (gr_contract_info_rec.payment_frequency - 1));
  -- ���z�v_���[�X��
    gr_cont_line_rec.gross_total_charge     :=
      gr_cont_line_rec.gross_charge         + gr_cont_line_rec.gross_tax_charge;
  -- ���z���[�X��_�T���z
    --UPD 2010/01/07 START
    --gr_cont_line_rec.gross_deduction        :=
    --  (gr_contract_info_rec.first_deduction * gr_contract_info_rec.payment_frequency);
    gr_cont_line_rec.gross_deduction        := gr_contract_info_rec.first_deduction +
      (gr_contract_info_rec.second_deduction * (gr_contract_info_rec.payment_frequency - 1));
    --UPD 2010/01/07 END
  -- ���z�����_�T���z
    gr_cont_line_rec.gross_tax_deduction    :=
      (gr_contract_info_rec.first_tax_deduction * gr_contract_info_rec.payment_frequency);
  -- ���z�v_�T���z
    gr_cont_line_rec.gross_total_deduction  :=
      gr_cont_line_rec.gross_deduction      + gr_cont_line_rec.gross_tax_deduction;
  -- 
    gr_cont_line_rec.estimated_cash_price   := gr_contract_info_rec.estimated_cash_price; -- ���ό����w�����z
    gr_cont_line_rec.life_in_months         := gr_contract_info_rec.life_in_months;       -- �@��ϗp�N��
  --  gr_cont_line_rec.object_header_id     := gr_contract_info_rec.object_header_id;     -- ��������id
    gr_cont_line_rec.asset_category         := gr_contract_info_rec.asset_category;       -- ���Y���
    gr_cont_line_rec.first_installation_address := gr_contract_info_rec.first_installation_address;   -- ����ݒu�ꏊ
    gr_cont_line_rec.first_installation_place   := gr_contract_info_rec.first_installation_place;     -- ����ݒu��
  -- WHO�J����
    gr_cont_line_rec.created_by             := cn_created_by;                             -- �쐬��
    gr_cont_line_rec.creation_date          := cd_creation_date;                          -- �쐬��
    gr_cont_line_rec.last_updated_by        := cn_last_updated_by;                        -- �ŏI�X�V��
    gr_cont_line_rec.last_update_date       := cd_last_update_date;                       -- �ŏI�X�V��
    gr_cont_line_rec.last_update_login      := cn_last_update_login;                      -- �ŏI�X�V۸޲�
    gr_cont_line_rec.request_id             := cn_request_id;                             -- �v��ID
    gr_cont_line_rec.program_application_id := cn_program_application_id;                 -- �ݶ��ĥ��۸��ѥ���ع����ID
    gr_cont_line_rec.program_id             := cn_program_id;                             -- �ݶ��ĥ��۸���ID
    gr_cont_line_rec.program_update_date    := cd_program_update_date;                    -- ��۸��эX�V��
-- 
  -- ***************************************************
  -- 3. ���[�X�������ڕҏW
  -- ***************************************************
    gr_object_data_rec.object_header_id     := NULL;                                      -- ��������ID
    gr_object_data_rec.object_code          := gr_contract_info_rec.object_code;          -- �����R�[�h
    gr_object_data_rec.lease_class          := gr_contract_info_rec.lease_class;          -- ���[�X���
    gr_object_data_rec.lease_type           := gr_contract_info_rec.lease_type;           -- ���[�X�敪
    gr_object_data_rec.re_lease_times       := gr_contract_info_rec.re_lease_times;       -- �ă��[�X��
    gr_object_data_rec.po_number            := gr_contract_info_rec.po_number;            -- �����ԍ�
    gr_object_data_rec.registration_number  := gr_contract_info_rec.registration_number;  -- �o�^�ԍ�
    gr_object_data_rec.age_type             := gr_contract_info_rec.age_type;             -- �N��
    gr_object_data_rec.model                := gr_contract_info_rec.model;                -- �@��
    gr_object_data_rec.serial_number        := gr_contract_info_rec.serial_number;        -- �@��
-- T1_0783 2009/05/14 MOD START --
--  gr_object_data_rec.quantity             := gr_contract_info_rec.quantity;             -- ����
    IF (gr_contract_info_rec.quantity IS NULL) THEN                                       -- ����
      gr_object_data_rec.quantity           := 1;
    ELSE
      gr_object_data_rec.quantity           := gr_contract_info_rec.quantity;
    END IF;
-- T1_0783 2009/05/14 MOD END   --
    gr_object_data_rec.manufacturer_name    := gr_contract_info_rec.manufacturer_name;    -- ���[�J�[��
    gr_object_data_rec.department_code      := gr_contract_info_rec.department_code;      -- �Ǘ�����R�[�h
    gr_object_data_rec.owner_company        := gr_contract_info_rec.owner_company;        -- �{�Ё^�H��
    gr_object_data_rec.chassis_number       := gr_contract_info_rec.chassis_number;       -- �ԑ�ԍ�
    gr_object_data_rec.re_lease_flag        := cv_re_lease_flag_0;                        -- �ă��[�X�v�t���O
    gr_object_data_rec.cancellation_type    := NULL;                                      -- ���敪
    gr_object_data_rec.cancellation_date    := NULL;                                      -- ���r����
    gr_object_data_rec.dissolution_date     := NULL;                                      -- ���r���L�����Z����
    gr_object_data_rec.bond_acceptance_flag := cv_bond_accept_flag_0;                     -- �؏���̃t���O
    gr_object_data_rec.bond_acceptance_Date := NULL;                                      -- ��������ID
    gr_object_data_rec.expiration_date      := NULL;                                      -- ��������ID
    gr_object_data_rec.object_status        := cv_object_status_102;                      -- �����X�e�[�^�X
    gr_object_data_rec.active_flag          := cv_const_y;                                -- �����L���t���O
    gr_object_data_rec.info_sys_if_date     := NULL;                                      -- ���[�X�Ǘ����A�g��
    gr_object_data_rec.generation_date      := NULL;                                      -- ������
  -- WHO�J����
    gr_object_data_rec.created_by           := cn_created_by;                             -- �쐬��
    gr_object_data_rec.creation_date        := cd_creation_date;                          -- �쐬��
    gr_object_data_rec.last_updated_by      := cn_last_updated_by;                        -- �ŏI�X�V��
    gr_object_data_rec.last_update_date     := cd_last_update_date;                       -- �ŏI�X�V��
    gr_object_data_rec.last_update_login    := cn_last_update_login;                      -- �ŏI�X�V۸޲�
    gr_object_data_rec.request_id           := cn_request_id;                             -- �v��ID
    gr_object_data_rec.program_application_id := cn_program_application_id;               -- �ݶ��ĥ��۸��ѥ���ع����ID
    gr_object_data_rec.program_id           := cn_program_id;                             -- �ݶ��ĥ��۸���ID
    gr_object_data_rec.program_update_date  := cd_program_update_date;                    -- ��۸��эX�V��
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
  END set_upload_item;
--
 /**********************************************************************************
   * Procedure Name   : jdg_lease_kind
   * Description      : ���[�X��ޔ���         (A-14)
   ***********************************************************************************/
  PROCEDURE jdg_lease_kind(
    ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'jdg_lease_kind'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
--
    --*** ���[�J���ϐ� ***
    lv_contract_ym      DATE;
    lv_first_after_charge      xxcff_cont_lines_work.first_charge%TYPE;
    lv_second_after_charge     xxcff_cont_lines_work.second_charge%TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  -- ***************************************************
  -- 1. ���[�X��ޔ���
  -- ***************************************************
    lv_contract_ym   := TRUNC(gr_cont_hed_rec.contract_date,'mm');
    lv_first_after_charge  := 
      gr_cont_line_rec.first_charge  - gr_cont_line_rec.first_deduction;               -- ���񌎊z���[�X��(�T����)
    lv_second_after_charge := 
      gr_cont_line_rec.second_charge - gr_cont_line_rec.second_deduction;              -- �Q��ڌ��z���[�X��(�T����)
    -- �֐��̌Ăяo��
    XXCFF003A03C.main(
      iv_lease_type                  => gr_cont_hed_rec.lease_type                     -- 1.���[�X�敪
     ,in_payment_frequency           => gr_cont_hed_rec.payment_frequency              -- 2.�x����
     ,in_first_charge                => lv_first_after_charge                          -- 3.���񌎊z���[�X��(�T����)
     ,in_second_charge               => lv_second_after_charge                         -- 4.�Q��ڈȍ~���z���[�X���i�T����j
     ,in_estimated_cash_price        => gr_cont_line_rec.estimated_cash_price          -- 5.���ό����w�����z
     ,in_life_in_months              => gr_cont_line_rec.life_in_months                -- 6.�@��ϗp�N��
     ,id_contract_ym                 => lv_contract_ym                                 -- 7.�_��N��
-- Ver.1.9 ADD Start
     ,iv_lease_class                 => gr_cont_hed_rec.lease_class                    -- 8.���[�X���
-- Ver.1.9 ADD End
     ,ov_lease_kind                  => gr_cont_line_rec.lease_kind                    -- 9.���[�X���
     ,on_present_value_discount_rate => gr_cont_line_rec.present_value_discount_rate   -- 10.���݉��l������
     ,on_present_value               => gr_cont_line_rec.present_value                 -- 11.���݉��l
     ,on_original_cost               => gr_cont_line_rec.original_cost                 -- 12.�擾���z
     ,on_calc_interested_rate        => gr_cont_line_rec.calc_interested_rate          -- 13.�v�Z���q��
-- Ver.1.9 ADD Start
     ,on_original_cost_type1         => gr_cont_line_rec.original_cost_type1           -- 14.���[�X���z_���_��
     ,on_original_cost_type2         => gr_cont_line_rec.original_cost_type2           -- 15.���[�X���z_�ă��[�X
-- Ver.1.9 ADD End
     ,ov_errbuf                      => lv_errbuf
     ,ov_retcode                     => lv_retcode
     ,ov_errmsg                      => lv_errmsg
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END jdg_lease_kind;
--
 /**********************************************************************************
   * Procedure Name   : ins_object_histories
   * Description      : ���[�X��������o�^        (A-18)
   ***********************************************************************************/
  PROCEDURE ins_object_histories(
    in_object_header_id  IN  NUMBER            -- ��������ID
   ,ov_errbuf            OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode           OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg            OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_object_histories'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cv_object_status_101     CONSTANT VARCHAR2(3) := '101'; -- 101:���_��
    cv_object_status_102     CONSTANT VARCHAR2(3) := '102'; -- 102:�_���
--
    --*** ���[�J���ϐ� ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************************
    -- 1.���[�X���������̓o�^������(101�F���_��)
    -- ***************************************************
    gr_object_data_rec.object_status         := cv_object_status_101;       -- ���_��
    gr_object_data_rec.active_flag           := cv_const_y;                 -- �����L���t���O
    -- �֐��̌Ăяo��
    xxcff_common3_pkg.insert_ob_his(
      io_object_data_rec    => gr_object_data_rec  --���[�X�������
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    --�G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ***************************************************
    -- 2.���[�X���������̓o�^������(102:�_��ρj
    -- ***************************************************
    gr_object_data_rec.object_status         := cv_object_status_102;       -- �_���
    -- �֐��̌Ăяo��
    xxcff_common3_pkg.insert_ob_his(
      io_object_data_rec    => gr_object_data_rec  --���[�X�����������
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    --�G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
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
  END ins_object_histories;
-- 
 /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : ���[�X�_�񃏁[�N���o       (A-12)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    in_file_id       IN  NUMBER            -- 1.�t�@�C��ID
   ,ov_err_flag      OUT NOCOPY VARCHAR2   -- 2.�G���[�t���O  
   ,ov_errbuf        OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- �v���O������
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
--
    --*** ���[�J���萔 ***
    cn_month             CONSTANT NUMBER(2)   := 12;
    cv_lease_type_1      CONSTANT VARCHAR2(1) := '1'; -- ����_��
    cv_shori_type_1      CONSTANT VARCHAR2(1) := '1'; -- ��o�^�
--
    --*** ���[�J���ϐ� ***
    lv_err_flag          VARCHAR2(1);      -- �G���[���݃t���O
    lv_err_info          VARCHAR2(5000);   -- �G���[�Ώۏ��
--
    lv_contract_number   xxcff_cont_lines_work.contract_number%TYPE;
    lv_lease_company     xxcff_cont_lines_work.lease_company%TYPE;
    ln_cont_header_id    xxcff_contract_lines.contract_header_id%TYPE;
    ln_object_header_id  xxcff_object_headers.object_header_id%TYPE;
--
  --ADD 2010/01/07 START
    ln_second_deduction               NUMBER;
    ln_truncated_deduction            NUMBER;
    ln_total_fraction                 NUMBER;
    ln_first_deduction                NUMBER;
  --ADD 2010/01/07 END
--
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X�_�񃏁[�N�J�[�\����`
    CURSOR contract_work_data_cur
    IS
      SELECT xchw.contract_number            AS contract_number
            ,xchw.lease_class                AS lease_class
            ,xchw.lease_type                 AS lease_type
            ,xchw.lease_company              AS lease_company
            ,xchw.re_lease_times             AS re_lease_times
            ,xchw.comments                   AS comments
            ,xchw.contract_date              AS contract_date
            ,xchw.payment_frequency          AS payment_frequency
            ,xchw.payment_type               AS payment_type 
            ,xchw.lease_start_date           AS lease_start_date
            ,xchw.first_payment_date         AS first_payment_date
            ,xchw.second_payment_date        AS second_payment_date
            ,xclw.contract_line_num          AS contract_line_num
            ,xclw.lease_company              AS lease_company_line
            ,xclw.first_charge               AS first_charge
            ,xclw.first_tax_charge           AS first_tax_charge
            ,xclw.second_charge              AS second_charge
            ,xclw.second_tax_charge          AS second_tax_charge
            ,xclw.first_deduction            AS first_deduction
            ,xclw.first_tax_deduction        AS first_tax_deduction
            --ADD 2010/01/07 STAR
            ,NULL                            AS second_deduction
            --ADD 2010/01/07 END
-- 2018/03/27 Ver1.10 Otsuka MOD Start
--            ,xclw.estimated_cash_price       AS estimated_cash_price
--            ,xclw.life_in_months             AS life_in_months
            ,NVL(TO_NUMBER(xclw.estimated_cash_price),0)
                                             AS estimated_cash_price
            ,NVL(TO_NUMBER(xclw.life_in_months),0)
                                             AS life_in_months
-- 2018/03/27 Ver1.10 Otsuka MOD End
            ,xclw.lease_kind                 AS lease_kind
            ,xclw.asset_category             AS asset_category
            ,xclw.first_installation_address AS first_installation_address
            ,xclw.first_installation_place   AS first_installation_place
            ,xclw.object_header_id           AS object_header_id
            ,xchw.tax_code                   AS tax_code
            ,xcow.object_code                AS object_code 
            ,xcow.po_number                  AS po_number
            ,xcow.registration_number        AS registration_number
            ,xcow.age_type                   AS age_type
            ,xcow.model                      AS model
            ,xcow.serial_number              AS serial_number
            ,xcow.quantity                   AS quantity
            ,xcow.manufacturer_name          AS manufacturer_name 
            ,xcow.department_code            AS department_code
            ,xcow.owner_company              AS owner_company
            ,xcow.chassis_number             AS chassis_number
      FROM   xxcff_cont_lines_work   xclw
            ,xxcff_cont_headers_work xchw
            ,xxcff_cont_obj_work     xcow
      WHERE  xchw.contract_number    = xclw.contract_number
      AND    xchw.lease_company      = xclw.lease_company
      AND    xclw.object_code        = xcow.object_code
      AND    xchw.file_id            = in_file_id
      AND    xclw.file_id            = in_file_id
      AND    xcow.file_id            = in_file_id
      ORDER BY
             xclw.contract_number
            ,xclw.lease_company
            ,xclw.contract_line_num;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN contract_work_data_cur;
    LOOP
      FETCH contract_work_data_cur INTO gr_contract_info_rec;
      EXIT WHEN contract_work_data_cur%NOTFOUND;
--
      gn_target_cnt := gn_target_cnt + 1;
--
  --ADD 2010/01/07 START
  -- ***************************************************
  --  �ێ��Ǘ�����z�̌��z���z���v�Z
  --  ���񌎊z���[�X���T���z�A2��ڈȍ~���z���[�X���T���z�ɋ��z�ݒ�
  --  �[�������� ���񌎊z���[�X���T���z �Ŏ��{
  -- ***************************************************
--
      -- ���z�Z�o���W�b�N
--
      -- �ێ��Ǘ���p�����z�̌��z�̋��z���Z�o(�~�����̒[���؎̂�)
      -- 2��ڈȍ~���z���[�X���T���z
      ln_second_deduction := trunc(gr_contract_info_rec.first_deduction / gr_contract_info_rec.payment_frequency);
      -- 2��ڈȍ~���z���[�X���T���z�Ǝx���񐔂��ێ��Ǘ���p�����z�i�[���؎̂āj���Z�o
      ln_truncated_deduction := ln_second_deduction * gr_contract_info_rec.payment_frequency;
      -- �ێ��Ǘ���p�����z�ƈێ��Ǘ���p�����z�i�[���؎̂āj���[���̑��z���Z�o
      ln_total_fraction := gr_contract_info_rec.first_deduction - ln_truncated_deduction;
      -- �[���̑��z�����񌎊z���[�X���T���z�Œ�������
      ln_first_deduction := ln_second_deduction + ln_total_fraction;
--
      -- ���z�ݒ�
--
      -- ���񌎊z���[�X���T���z
      gr_contract_info_rec.first_deduction := ln_first_deduction;
      -- 2��ڈȍ~���z���[�X���T���z
      gr_contract_info_rec.second_deduction := ln_second_deduction;
--
  --ADD 2010/01/07 END
--
  -- ***************************************************
  -- 1. �A�b�v���[�h���ڕҏW                      (A-13)
  -- ***************************************************
      --�֐��̌Ăяo��
      set_upload_item(
        ov_retcode       => lv_retcode
       ,ov_errbuf        => lv_errbuf
       ,ov_errmsg        => lv_errmsg
      );
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
  -- ***************************************************
  -- 2. ���[�X��ޔ���                            (A-14)
  -- ***************************************************
      --�֐��̌Ăяo��
      jdg_lease_kind(
        ov_retcode    => lv_retcode
       ,ov_errbuf     => lv_errbuf
       ,ov_errmsg     => lv_errmsg
      );
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 3. ���[�X�����V�K�o�^                        (A-15)
  -- ***************************************************
      xxcff_common3_pkg.insert_ob_hed(
        io_object_data_rec    => gr_object_data_rec --���[�X����
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --��������ID��ޔ�����B
      ln_object_header_id  := gr_object_data_rec.object_header_id;
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 4. ���[�X�_��V�K�o�^                        (A-16)
  -- ***************************************************
      --�_��ԍ��A���[�X��Ђ��قȂ�ꍇ
      IF ((lv_contract_number IS NULL) OR
          (lv_lease_company   IS NULL) OR
          (lv_contract_number <> gr_contract_info_rec.contract_number) OR
          (lv_lease_company   <> gr_contract_info_rec.lease_company)) THEN
      --�u���[�N�L�[��ޔ�����B
        lv_contract_number := gr_contract_info_rec.contract_number;
        lv_lease_company   := gr_contract_info_rec.lease_company;
      --�֐��̌Ăяo��
        xxcff_common4_pkg.insert_co_hed(
          io_contract_data_rec  => gr_cont_hed_rec  --���[�X�_����
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        --�_��ID��ޔ�����B
        ln_cont_header_id  := gr_cont_hed_rec.contract_header_id;
      END IF;
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
  -- ***************************************************
  -- 5. ���[�X�_�񖾍אV�K�o�^                    (A-17)
  -- ***************************************************
      -- �_�����ID�����[�X�_�񖾍ׂɐݒ肷��B
      gr_cont_line_rec.contract_header_id := ln_cont_header_id;
      -- ��������ID�����[�X�_�񖾍ׂɐݒ肷��B
      gr_cont_line_rec.object_header_id   := ln_object_header_id;
      -- ���[�X�_�񖾍אV�K�o�^(A-15)
      xxcff_common4_pkg.insert_co_lin(
        io_contract_data_rec  => gr_cont_line_rec  --���[�X�_�񖾍׏��
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 6. ���[�X��������o�^                        (A-18)
  -- ***************************************************
      ins_object_histories(
        in_object_header_id   => gr_contract_info_rec.object_header_id
       ,ov_retcode            => lv_retcode
       ,ov_errbuf             => lv_errbuf
       ,ov_errmsg             => lv_errmsg
      );
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
--
  -- ***************************************************
  -- 7. ���[�X�x���v��쐬                        (A-19)
  -- ***************************************************
      xxcff003a05c.main(
        iv_shori_type         => cv_shori_type_1                    -- 1.�����敪
       ,in_contract_line_id   => gr_cont_line_rec.contract_line_id  -- 2.�_�񖾍ד���ID
       ,ov_retcode            => lv_retcode
       ,ov_errbuf             => lv_errbuf
       ,ov_errmsg             => lv_errmsg
      );
      --�G���[�����݂���ꍇ�͋����I��
      IF (lv_retcode = cv_status_error) THEN
        CLOSE contract_work_data_cur;
        RAISE global_api_expt;
      END IF;
      --���팏���̃J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
--
    CLOSE contract_work_data_cur;
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
      IF (contract_work_data_cur%ISOPEN) THEN
        CLOSE contract_work_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : submain_main
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain_main(
    in_file_id           IN  NUMBER,              --   �t�@�C��ID
    in_file_upload_code  IN  NUMBER,              --   �A�b�v���[�h�R�[�h
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain_main'; -- �v���O������
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
    cv_data_type_1  CONSTANT VARCHAR2(1) := '1'; -- ��_��
    cv_data_type_2  CONSTANT VARCHAR2(1) := '2'; -- ��_�񖾍ף
--
    -- *** ���[�J���ϐ� ***
    lr_init_rtype   xxcff_common1_pkg.init_rtype;  -- ���������擾���ʊi�[�p
    lv_all_err_flag VARCHAR2(1);                   -- �G���[���݃t���O
    ln_reccnt       NUMBER(10);                    -- ���[�v�����J�E���^
    lv_err_flag     VARCHAR2(1);                   -- �G���[���݃t���O
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
    gn_seqno      := 0;
    gn_seqno_line := 0;
    gn_seqno_obj  := 0;
--
    -- ���[�J���ϐ��̏�����
    lv_all_err_flag := cv_const_n;

    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ==================================
    -- ��������                     (A-1)
    -- ==================================
    init(
      in_file_id,          -- 1.�t�@�C��ID
      in_file_upload_code, -- 2.�t�@�C���A�b�v���[�h�R�[�h
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --�G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================
    -- �t�@�C���A�b�v���[�hI/F�擾  (A-2)
    -- ==================================
    get_if_data(
       in_file_id => in_file_id       -- 1.�t�@�C��ID
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
      --�G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --�z��Ɋi�[����Ă���CSV�s��1�s�Â擾����
    FOR ln_reccnt IN gr_file_data_tbl.first..gr_file_data_tbl.last LOOP
      --gn_target_cnt := gn_target_cnt + 1;   --���������J�E���g
      -- ==================================
      -- �f���~�^�������ڕ���         (A-3)
      -- ==================================
      devide_item(
         in_file_data  => gr_file_data_tbl(ln_reccnt)  -- 1.�t�@�C���f�[�^
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );
      -- ==================================
      -- �z�񍀖ڃ`�F�b�N����         (A-4)
      -- ==================================
      IF  ((gr_lord_data_tab(1) = cv_data_type_1)
       OR  (gr_lord_data_tab(1) = cv_data_type_2)) THEN
        -- ���������̃J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        -- 
        chk_err_disposion(
           ov_retcode    => lv_retcode
          ,ov_errbuf     => lv_errbuf
          ,ov_errmsg     => lv_errmsg
        );
      -- ==================================
      -- �A�b�v���[�h�U������         (A-5)
      -- ==================================
        --�G���[�����݂��Ȃ��ꍇ�̂݃��[�N�e�[�u���ɓo�^
        IF (lv_retcode <> cv_status_error) THEN
          ins_cont_work (
            in_file_id    => in_file_id       -- 1.�t�@�C��ID
           ,ov_retcode    => lv_retcode
           ,ov_errbuf     => lv_errbuf
           ,ov_errmsg     => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        ELSE
          lv_all_err_flag := cv_const_y;
          -- ���������̃J�E���g
          gn_error_cnt := gn_error_cnt + 1;
        END IF;  
      END IF;
    END LOOP;
--
    -- ==================================
    -- �G���[���菈��               (A-6)
    -- ==================================
    --�P���ł��G���[�����݂���ꍇ�͋����I��
    IF (lv_all_err_flag = cv_const_y) THEN
      -- �X�L�b�v����
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- ܰ�̧�ُd���E��������������  (A-7)
    -- ==================================
    chk_rept_adjust(
      in_file_id    => in_file_id       -- 1.�t�@�C��ID
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --�P���ł��G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      -- �X�L�b�v����
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- �_�񃏁[�N�`�F�b�N����       (A-8)
    -- ==================================
    chk_cont_header(
      in_file_id    => in_file_id       -- 1.�t�@�C��ID
     ,ov_err_flag   => lv_err_flag      -- 2.�G���[�t���O
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- �_�񖾍׃��[�N�`�F�b�N����   (A-9)
    -- ==================================
    chk_cont_line(
      in_file_id    => in_file_id       -- 1.�t�@�C��ID
     ,ov_err_flag   => lv_err_flag      -- 2.�G���[�t���O
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- �������[�N�`�F�b�N����   (A-10)
    -- ==================================
    chk_obj_header(
      in_file_id    => in_file_id       -- 1.�t�@�C��ID
     ,ov_err_flag   => lv_err_flag      -- 2.�G���[�t���O
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --
    IF (lv_err_flag =  cv_const_y) THEN
      lv_all_err_flag := cv_const_y;
    END IF;
--
    -- ==================================
    -- �G���[���菈��               (A-11)
    -- ==================================
    --�P���ł��G���[�����݂���ꍇ�͋����I��
    IF (lv_all_err_flag = cv_const_y) THEN
      -- �X�L�b�v����
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
      RAISE global_process_expt;
    END IF;
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ==================================
    -- ���[�X�_�񃏁[�N���o        (A-12)
    -- ==================================
    get_contract_info(
      in_file_id    => in_file_id       -- 1.�t�@�C��ID
     ,ov_err_flag   => lv_err_flag      -- 2.�G���[�t���O
     ,ov_retcode    => lv_retcode
     ,ov_errbuf     => lv_errbuf
     ,ov_errmsg     => lv_errmsg
    );
    --�P���ł��G���[�����݂���ꍇ�͋����I��
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_process_expt;
    END IF;
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
  END submain_main;
--  
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id           IN  NUMBER,              --   �t�@�C��ID
    in_file_upload_code  IN  NUMBER,              --   �A�b�v���[�h�R�[�h
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ===============================================
    -- submain_main�̌Ăяo���i���ۂ̏�����submain_main�ōs���j
    -- ===============================================
    submain_main(
       in_file_id             -- 1.�t�@�C��ID
      ,in_file_upload_code    -- 2.�A�b�v���[�h�R�[�h
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ==================================
    -- �I������                    (A-19)
    -- ==================================
    IF (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      -- ���[�X�_�񃏁[�N�폜
      DELETE
      FROM  xxcff_cont_headers_work
      WHERE file_id = in_file_id;
      -- ���[�X�_�񖾍׃��[�N�폜
      DELETE
      FROM  xxcff_cont_lines_work
      WHERE file_id = in_file_id;
      -- ���[�X�������[�N�폜
      DELETE
      FROM  xxcff_cont_obj_work
      WHERE file_id = in_file_id;
    END IF;
    -- �t�@�C���A�b�v���[�hIF�e�[�u���폜
    DELETE
    FROM  xxccp_mrp_file_ul_interface
    WHERE file_id = in_file_id;
    --�ُ�I���̏ꍇ�t�@�C���A�b�v���[�hIF�e�[�u���폜�̂��߂�COMMIT���s
    IF (lv_retcode = cv_status_error) THEN
      COMMIT;
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
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
     errbuf                 OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W  --# �Œ� #
   , retcode                OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h    --# �Œ� #
   , in_file_id             IN  NUMBER             -- 1.�t�@�C��ID
   , in_file_upload_code    IN  NUMBER             -- 2.�t�@�C���A�b�v���[�h�R�[�h
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
       in_file_id             -- 1.�t�@�C��ID
      ,in_file_upload_code    -- 2.�t�@�C���A�b�v���[�h�R�[�h
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCFF003A07C;
/