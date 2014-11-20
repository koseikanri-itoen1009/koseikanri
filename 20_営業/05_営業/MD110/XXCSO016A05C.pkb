CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A05C(bosy)
 * Description      : �������(���̋@���)�f�[�^�����n�V�X�e���֘A�g���邽�߂̂b�r�u�t�@�C�����쐬���܂��B
 *
 * MD.050           : MD050_CSO_016_A05_���n-EBS�C���^�[�t�F�[�X�F(OUT)�Y��}�X�^
 *
 * Version          : 1.19
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  get_profile_info            �v���t�@�C���l�擾 (A-2)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-3)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-6)
 *  create_csv_rec              �Y��}�X�^�f�[�^CSV�o�� (A-7)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                                �����f�[�^���o���� (A-4)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Syoei.Kin        �V�K�쐬
 *  2009-02-20    1.1   K.Sai            ���r���[��Ή�
 *  2009-03-11    1.1   M.Maruyama       �����}�X�^���ڒǉ�(�挎���ݒu��ڋq�R�[�h�E�挎��
 *                                       �@���ԁE�挎���N��)�ɂ��ύX�Ή�
 *                                         �挎���ڋq�R�[�h�E�挎�����_(����)�R�[�h���o�ǉ�
 *                                         �ڋq�R�[�h�E���_(����)�R�[�h�擾���@�ύX
 *                                           �v���t�@�C���I�v�V�������g���_�R�[�h�擾�����폜
 *                                         �ؗ��J�n�����o�����ύX
 *                                         ���t�����`�F�b�N���b�Z�[�W�ύX
 *  2009-03-11    1.1   M.Maruyama       �y�s��Ή�054�z�����}�X�^�֘A���擾����
 *                                       �@����2(�ؗ�)���C���X�^���X�^�C�v1(���̋@)��
 *                                       �ꍇ�̎擾���_�R�[�h�̊ԈႢ���C��
 *  2009-03-27    1.2   N.Yabuki         �yST��Q�Ǘ�T1_0191_T1_0192_T1_0193_T1_0194�z
 *                                        (����Q�Ǘ��ԍ��A��Q���e�͏�Q�Ǘ��ԍ��̔Ԍ�ɋL��)
 *  2009-04-08    1.3   K.Satomura       �r�s��Q�Ή�(T1_0365)
 *  2009-04-15    1.4   M.Maruyama       �r�s��Q�Ή�(T1_0550) ���C���J�[�\����WHERE����C��
 *  2009-05-01    1.5   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-18    1.6   K.Satomura       �r�s��Q�Ή�(T1_1049)
 *  2009-05-25    1.7   M.Maruyama       �r�s��Q�Ή�(T1_1154)
 *  2009-06-09    1.8   K.Hosoi          �r�s��Q�Ή�(T1_1154) �ďC��
 *  2009-07-09    1.9   K.Hosoi          SCS��Q�Ǘ��ԍ�(0000518) �Ή�
 *  2009-07-21    1.10  K.Hosoi          SCS��Q�Ǘ��ԍ�(0000475) �Ή�
 *  2009-08-06    1.11  K.Satomura       SCS��Q�Ǘ��ԍ�(0000935) �Ή�
 *  2009-09-03    1.12  M.Maruyama       SCS��Q�Ǘ��ԍ�(0001192) �Ή�
 *  2009-11-27    1.13  K.Satomura       E_�{�ғ�_00118�Ή�
 *  2009-12-09    1.14  T.Maruyama       E_�{�ғ�_00117�Ή�
 *  2010-02-26    1.15  K.Hosoi          E_�{�ғ�_01568�Ή�
 *  2010-03-17    1.16  K.Hosoi          E_�{�ғ�_01881�Ή�
 *  2010-04-21    1.17  T.Maruyama       E_�{�ғ�_02391�Ή� INSTANCE_NUMBER��EBS��7���ȏ�ƂȂ邽�ߌŒ�l���Z�b�g
 *  2010-05-19    1.18  T.Maruyama       E_�{�ғ�_02787�Ή� �挎�����_CD�̓��o���ڂ𔄏㋒�_����O�����㋒�_�֕ύX
 *  2011-10-14    1.19  T.Yoshimoto      E_�{�ғ�_05929�Ή� �����E�����`�F�b�N��ǉ�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929(�R�����g�A�E�g����)
  gn_skip_cnt               NUMBER;                    -- �X�L�b�v����
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
  gv_company_cd             VARCHAR2(2000);            -- ��ЃR�[�h(�Œ�l001)
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A05C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- �A�N�e�B�u
  cv_houmon_kbn_taget    CONSTANT VARCHAR2(1)   := '1';             -- �K��Ώۋ敪�i�K��ΏہF1�j
  cv_source_obj_type_cd  CONSTANT VARCHAR2(10)  := 'PARTY';         -- �\�[�X�I�u�W�F�N�g�^�C�v�R�[�h
  cv_delete_flg          CONSTANT VARCHAR2(10)  := 'N';             -- �폜�t���O
  cn_job_kbn             CONSTANT NUMBER        := 5;               -- ��ƃe�[�u���̍�Ƌ敪(���g:5)
/*20090327_yabuki_T1_0193 START*/
  cn_job_kbn_new_replace CONSTANT NUMBER        := 3;               -- ��ƃe�[�u���̍�Ƌ敪(�V����:3)
  cn_job_kbn_old_replace CONSTANT NUMBER        := 4;               -- ��ƃe�[�u���̍�Ƌ敪(������:4)
/*20090327_yabuki_T1_0193 END*/
  cn_completion_kbn      CONSTANT NUMBER        := 1;               -- ��ƃe�[�u���̊����敪(����:1)
  cv_category_kbn        CONSTANT VARCHAR2(10)  := '50';            -- �����˗����׏��r���[�̈��g���(���g���:50)
/*20090327_yabuki_T1_0193 START*/
  cv_category_kbn_new_rplc  CONSTANT VARCHAR2(10)  := '20';            -- �����˗����׏��r���[�̐V���֏��(�V���֏��:20)
  cv_category_kbn_old_rplc  CONSTANT VARCHAR2(10)  := '40';            -- �����˗����׏��r���[�̋����֏��(�����֏��:40)
/*20090327_yabuki_T1_0193 END*/
/* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
  cv_withdrawal_type_1   CONSTANT VARCHAR2(10)  := '1:���g';        -- �����˗����׏��r���[�̈��g(���g:1)
  cv_withdrawal_type_2   CONSTANT VARCHAR2(10)  := '2:�ꎞ���g';    -- �����˗����׏��r���[�̈��g(�ꎞ���g:2)
/* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
  cv_instance_status     CONSTANT VARCHAR2(50)  := 'XXCSO1_INSTANCE_STATUS';  -- �N�C�b�N�R�[�h�̃��b�N�A�b�v�^�C�v
  cv_enabled_flag        CONSTANT VARCHAR2(50)  := 'Y';             -- �N�C�b�N�R�[�h�̗L���t���O
  cv_jotai_kbn1_1        CONSTANT VARCHAR2(1)   := '1';             -- �@���ԂP�i1:�ғ����j
  cv_jotai_kbn1_2        CONSTANT VARCHAR2(2)   := '2';             -- �@���ԂP�i2:�ؗ��j
  cv_jotai_kbn1_3        CONSTANT VARCHAR2(2)   := '3';             -- �@���ԂP�i3:�p���ρj
  cv_instance_type_cd_1  CONSTANT VARCHAR2(1)   := '1';             -- �C���X�^���X�^�C�v���u1:�����̔��@�v
  cv_lease_kbn_1         CONSTANT VARCHAR2(1)   := '1';             -- ���[�X�敪�u1:���Ѓ��[�X�v
  cv_lease_kbn_2         CONSTANT VARCHAR2(1)   := '2';             -- ���[�X�敪�u2:���q�l���[�X�v
/* 2009.04.08 K.Satomura T1_0365�Ή� START */
  cv_flag_yes            CONSTANT VARCHAR2(1)   := 'Y';
/* 2009.04.08 K.Satomura T1_0365�Ή� END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929
  cv_comma               CONSTANT VARCHAR2(2)   := '�A';            -- �J���}
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- �v���t�@�C���擾�G���[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';     -- CSV�t�@�C���c���G���[
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';     -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- �f�[�^���o�G���[
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00492';     -- �N�C�b�N�R�[�h���o�G���[
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00279';     -- �ڋq�A�h�I���}�X�^�f�[�^���o�x��
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00280';     -- ���A�ԍ��}�X�^�f�[�^���o�x��
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00281';     -- ���[�X�_��f�[�^���o�x��
  /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
  -- cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00282';     -- ��ƃf�[�^�e�[�u���f�[�^���o�x��
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00564';     -- ���o�G���[
  /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00283';     -- CSV�t�@�C���o�̓G���[
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';     -- CSV�t�@�C���o��0���G���[
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';     -- ���t�����`�F�b�N
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- �Ɩ��������t�擾�G���[
  /* 2009.04.09 K.Satomura T1_0441�Ή� START */
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00560';     -- �l���ݒ胁�b�Z�[�W
  /* 2009.04.09 K.Satomura T1_0441�Ή� END */
  /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
  cv_tkn_number_18    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';     -- �l���ݒ胁�b�Z�[�W
  /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
  /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
  cv_tkn_number_19    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00581';
  /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929
  cv_tkn_number_20    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00616';     -- CSV�o�̓G���[
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
--
  -- �g�[�N���R�[�h
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_err_msg2        CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';        -- SQL�G���[���b�Z�[�W2
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- �v���t�@�C����
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';       -- CSV�t�@�C���o�͐�
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';      -- CSV�t�@�C����
  cv_tkn_proc_name       CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';    -- ���o������
  cv_tkn_object_cd       CONSTANT VARCHAR2(20) := 'OBJECT_CD';          -- �O���Q��(�����R�[�h)
  cv_tkn_account_id      CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';         -- ���L�҃A�J�E���gID
  cv_tkn_location_cd     CONSTANT VARCHAR2(20) := 'LOCATION_CD';        -- ���_�R�[�h
  cv_tkn_customer_cd     CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';        -- �ڋq�R�[�h
  cv_tkn_un_number       CONSTANT VARCHAR2(20) := 'UN_NUMBER';          -- �@��R�[�h
  cv_tkn_maker_cd        CONSTANT VARCHAR2(20) := 'MAKER_CD';           -- ���[�J�[�R�[�h
  cv_tkn_special1        CONSTANT VARCHAR2(20) := 'SPECIAL1';           -- ����@�敪1
  cv_tkn_special2        CONSTANT VARCHAR2(20) := 'SPECIAL2';           -- ����@�敪2
  cv_tkn_special3        CONSTANT VARCHAR2(20) := 'SPECIAL3';           -- ����@�敪3
  cv_tkn_column          CONSTANT VARCHAR2(20) := 'COLUMN';             -- �R������
  cv_tkn_lease_kbn       CONSTANT VARCHAR2(20) := 'LEASE_KBN';          -- ���[�X�敪
  cv_tkn_lease_price     CONSTANT VARCHAR2(20) := 'LEASE_PRICE';        -- ���[�X��
  cv_tkn_work_date       CONSTANT VARCHAR2(20) := 'WORK_DATE';          -- ����Ɠ�
  cv_tkn_count           CONSTANT VARCHAR2(20) := 'COUNT';              -- ��������
  cv_tkn_status_id       CONSTANT VARCHAR2(20) := 'STATUS_ID';          -- �X�e�[�^�XID
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';               -- ���ږ�
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'BASE_VALUE';         -- �l
  /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
  cv_tkn_tsk_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';          -- �l
  cv_tkn_vl              CONSTANT VARCHAR2(20) := 'VALUE';              -- �l
  /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
  /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';             -- �l
  /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
  /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
  cv_tkn_param           CONSTANT VARCHAR2(20) := 'PARAM';
  /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'message';            -- ���b�Z�[�W
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'lv_file_dir         = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'lv_file_name        = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_company_cd       = ';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< �X�e�[�^�X�̃R�[�h���o���� >>' ;
  cv_debug_msg13          CONSTANT VARCHAR2(200) := '�X�e�[�^�X          = ';
  cv_debug_msg14          CONSTANT VARCHAR2(200) := '<< ���_�R�[�h�A�ڋq�R�[�h���o���� >>' ;
  cv_debug_msg15          CONSTANT VARCHAR2(200) := '���_(����)�R�[�h    = ';
  cv_debug_msg16          CONSTANT VARCHAR2(200) := '�ڋq�R�[�h          = ';
  cv_debug_msg17          CONSTANT VARCHAR2(200) := '<< �������[�J�[�A����@�敪�A�R���������o���� >>' ;
  cv_debug_msg18          CONSTANT VARCHAR2(200) := '�������[�J�[        = ';
  cv_debug_msg19          CONSTANT VARCHAR2(200) := '����@�敪1         = ';
  cv_debug_msg20          CONSTANT VARCHAR2(200) := '����@�敪2         = ';
  cv_debug_msg21          CONSTANT VARCHAR2(200) := '����@�敪3         = ';
  cv_debug_msg22          CONSTANT VARCHAR2(200) := '�R������            = ';
  cv_debug_msg23          CONSTANT VARCHAR2(200) := '<< ���[�X�敪�A���[�X�����o���� >>' ;
  cv_debug_msg24          CONSTANT VARCHAR2(200) := '�ă��[�X�敪        = ';
  cv_debug_msg25          CONSTANT VARCHAR2(200) := '���[�X��            = ';
  cv_debug_msg26          CONSTANT VARCHAR2(200) := '<< �ؗ��J�n���A���_(����)���o���� >>' ;
  cv_debug_msg27          CONSTANT VARCHAR2(200) := '�ؗ��J�n��          = ';
  cv_debug_msg28          CONSTANT VARCHAR2(200) := '���_(����)          = ';
  cv_debug_msg29          CONSTANT VARCHAR2(200) := '<< ���_(����)���o���� >>' ;
  cv_debug_msg30          CONSTANT VARCHAR2(200) := '���_(����)          = ';
  cv_debug_msg31          CONSTANT VARCHAR2(200) := '<< �Ɩ������N���擾���� >>';
  cv_debug_msg32          CONSTANT VARCHAR2(200) := '�Ɩ������N��        = ';
  /*20090709_hosoi_0000518 START*/
  cv_debug_msg33          CONSTANT VARCHAR2(200) := 'lv_attribute_level  = ';
  /*20090709_hosoi_0000518 END*/
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
--
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929
  cv_kiban_ja                CONSTANT VARCHAR2(100) := '�@��';                     --  �@��(DFF2)
  cv_count_no_ja             CONSTANT VARCHAR2(100) := '�J�E���^�[No';             --  �J�E���^�[No
  cv_chiku_cd_ja             CONSTANT VARCHAR2(100) := '�n��R�[�h';               --  �n��R�[�h
  cv_sagyougaisya_cd_ja      CONSTANT VARCHAR2(100) := '��Ɖ�ЃR�[�h';           --  ��Ɖ�ЃR�[�h
  cv_jigyousyo_cd_ja         CONSTANT VARCHAR2(100) := '���Ə��R�[�h';             --  ���Ə��R�[�h
  cv_den_no_ja               CONSTANT VARCHAR2(100) := '�ŏI��Ɠ`�[No';           --  �ŏI��Ɠ`�[No
  cv_job_kbn_ja              CONSTANT VARCHAR2(100) := '�ŏI��Ƌ敪';             --  �ŏI��Ƌ敪
  cv_sintyoku_kbn_ja         CONSTANT VARCHAR2(100) := '�ŏI��Ɛi��';             --  �ŏI��Ɛi��
  cv_yotei_dt_ja             CONSTANT VARCHAR2(100) := '�ŏI��Ɗ����\���';       --  �ŏI��Ɗ����\���
  cv_kanryo_dt_ja            CONSTANT VARCHAR2(100) := '�ŏI��Ɗ�����';           --  �ŏI��Ɗ�����
  cv_sagyo_level_ja          CONSTANT VARCHAR2(100) := '�ŏI�������e';             --  �ŏI�������e
  cv_den_no2_ja              CONSTANT VARCHAR2(100) := '�ŏI�ݒu�`�[No';           --  �ŏI�ݒu�`�[No
  cv_job_kbn2_ja             CONSTANT VARCHAR2(100) := '�ŏI�ݒu�敪';             --  �ŏI�ݒu�敪
  cv_sintyoku_kbn2_ja        CONSTANT VARCHAR2(100) := '�ŏI�ݒu�i��';             --  �ŏI�ݒu�i��
  cv_jotai_kbn1_ja           CONSTANT VARCHAR2(100) := '�@����1';                --  �@����1�i�ғ���ԁj
  cv_jotai_kbn2_ja           CONSTANT VARCHAR2(100) := '�@����2';                --  �@����2�i��ԏڍׁj
  cv_jotai_kbn3_ja           CONSTANT VARCHAR2(100) := '�@����3';                --  �@����3�i�p�����j
  cv_nyuko_dt_ja             CONSTANT VARCHAR2(100) := '���ɓ�';                   --  ���ɓ�
  cv_hikisakigaisya_cd_ja    CONSTANT VARCHAR2(100) := '���g��ЃR�[�h';           --  ���g��ЃR�[�h
  cv_hikisakijigyosyo_cd_ja  CONSTANT VARCHAR2(100) := '���g���Ə��R�[�h';         --  ���g���Ə��R�[�h
  cv_setti_tanto_ja          CONSTANT VARCHAR2(100) := '�ݒu��S���Җ�';           --  �ݒu��S���Җ�
  cv_setti_tel1_ja           CONSTANT VARCHAR2(100) := '�ݒu��TEL1';               --  �ݒu��TEL1
  cv_setti_tel2_ja           CONSTANT VARCHAR2(100) := '�ݒu��TEL2';               --  �ݒu��TEL2
  cv_setti_tel3_ja           CONSTANT VARCHAR2(100) := '�ݒu��TEL3';               --  �ݒu��TEL3
  cv_haikikessai_dt_ja       CONSTANT VARCHAR2(100) := '�p�����ٓ�';               --  �p�����ٓ�
  cv_tenhai_tanto_ja         CONSTANT VARCHAR2(100) := '�]���p���Ǝ�';             --  �]���p���Ǝ�
  cv_tenhai_den_no_ja        CONSTANT VARCHAR2(100) := '�]���p���`�[No';           --  �]���p���`�[No
  cv_syoyu_cd_ja             CONSTANT VARCHAR2(100) := '���L��';                   --  ���L��
  cv_tenhai_flg_ja           CONSTANT VARCHAR2(100) := '�]���p���󋵃t���O';       --  �]���p���󋵃t���O
  cv_kanryo_kbn_ja           CONSTANT VARCHAR2(100) := '�]�������敪';             --  �]�������敪
  cv_sakujo_flg_ja           CONSTANT VARCHAR2(100) := '�폜�t���O';               --  �폜�t���O
  cv_ven_kyaku_last_ja       CONSTANT VARCHAR2(100) := '�ŏI�ڋq�R�[�h';           --  �ŏI�ڋq�R�[�h
  cv_ven_tasya_cd01_ja       CONSTANT VARCHAR2(100) := '���ЃR�[�h1';              --  ���ЃR�[�h�P
  cv_ven_tasya_daisu01_ja    CONSTANT VARCHAR2(100) := '���Б䐔1';                --  ���Б䐔�P
  cv_ven_tasya_cd02_ja       CONSTANT VARCHAR2(100) := '���ЃR�[�h2';              --  ���ЃR�[�h�Q
  cv_ven_tasya_daisu02_ja    CONSTANT VARCHAR2(100) := '���Б䐔2';                --  ���Б䐔�Q
  cv_ven_tasya_cd03_ja       CONSTANT VARCHAR2(100) := '���ЃR�[�h3';              --  ���ЃR�[�h�R
  cv_ven_tasya_daisu03_ja    CONSTANT VARCHAR2(100) := '���Б䐔3';                --  ���Б䐔�R
  cv_ven_tasya_cd04_ja       CONSTANT VARCHAR2(100) := '���ЃR�[�h4';              --  ���ЃR�[�h�S
  cv_ven_tasya_daisu04_ja    CONSTANT VARCHAR2(100) := '���Б䐔4';                --  ���Б䐔�S
  cv_ven_tasya_cd05_ja       CONSTANT VARCHAR2(100) := '���ЃR�[�h5';              --  ���ЃR�[�h�T
  cv_ven_tasya_daisu05_ja    CONSTANT VARCHAR2(100) := '���Б䐔5';                --  ���Б䐔�T
  cv_ven_haiki_flg_ja        CONSTANT VARCHAR2(100) := '�p���t���O';               --  �p���t���O
  cv_ven_sisan_kbn_ja        CONSTANT VARCHAR2(100) := '���Y�敪';                 --  ���Y�敪
  cv_ven_kobai_ymd_ja        CONSTANT VARCHAR2(100) := '�w�����t';                 --  �w�����t
  cv_ven_kobai_kg_ja         CONSTANT VARCHAR2(100) := '�w�����z';                 --  �w�����z
  cv_safty_level_ja          CONSTANT VARCHAR2(100) := '���S�ݒu�';             --  ���S�ݒu�
  cv_lease_kbn_ja            CONSTANT VARCHAR2(100) := '���[�X�敪';               --  ���[�X�敪
  cv_last_inst_cust_code_ja  CONSTANT VARCHAR2(100) := '�挎���ݒu��ڋq�R�[�h';   --  �挎���ݒu��ڋq�R�[�h                            
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand    UTL_FILE.FILE_TYPE;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Y��}�X�^���f�[�^
    TYPE g_value_rtype IS RECORD(
      company_cd                VARCHAR2(100)                                    -- ��ЃR�[�h
     ,install_code              xxcso_install_base_v.install_code%TYPE           -- �O���Q��
     ,instance_type_code        xxcso_install_base_v.instance_type_code%TYPE     -- �C���X�^���X�^�C�v
     ,lookup_code               fnd_lookup_values_vl.lookup_code%TYPE            -- �X�e�[�^�X
     ,install_date              xxcso_install_base_v.install_date%TYPE           -- ������
     ,instance_number           xxcso_install_base_v.instance_number%TYPE        -- �C���X�^���X�ԍ�
     ,quantity                  xxcso_install_base_v.quantity%TYPE               -- ����
     ,accounting_class_code     xxcso_install_base_v.accounting_class_code%TYPE  -- ��v����
     ,active_start_date         xxcso_install_base_v.active_start_date%TYPE      -- �J�n��
     ,inventory_item_id         xxcso_install_base_v.inventory_item_id%TYPE      -- �i���R�[�h
     ,install_party_id          xxcso_install_base_v.install_party_id%TYPE       -- �g�p�҃p�[�e�BID
     ,install_account_id        xxcso_install_base_v.install_account_id%TYPE     -- �g�p�҃A�J�E���gID
     ,vendor_model              xxcso_install_base_v.vendor_model%TYPE           -- �@��(DFF1)
     ,vendor_number             xxcso_install_base_v.vendor_number%TYPE          -- �@��(DFF2)
     ,first_install_date        xxcso_install_base_v.first_install_date%TYPE     -- ����ݒu��(DFF3)
     ,op_request_flag           xxcso_install_base_v.op_request_flag%TYPE        -- ��ƈ˗����t���O(DFF4)
     ,ven_kyaku_last            xxcso_install_base_v.ven_kyaku_last%TYPE         -- �ŏI�ڋq�R�[�h
     ,ven_tasya_cd01            xxcso_install_base_v.ven_tasya_cd01%TYPE         -- ���ЃR�[�h�P
     ,ven_tasya_daisu01         xxcso_install_base_v.ven_tasya_daisu01%TYPE      -- ���Б䐔�P
     ,ven_tasya_cd02            xxcso_install_base_v.ven_tasya_cd02%TYPE         -- ���ЃR�[�h�Q
     ,ven_tasya_daisu02         xxcso_install_base_v.ven_tasya_daisu02%TYPE      -- ���Б䐔�Q
     ,ven_tasya_cd03            xxcso_install_base_v.ven_tasya_cd03%TYPE         -- ���ЃR�[�h�R
     ,ven_tasya_daisu03         xxcso_install_base_v.ven_tasya_daisu03%TYPE      -- ���Б䐔�R
     ,ven_tasya_cd04            xxcso_install_base_v.ven_tasya_cd04%TYPE         -- ���ЃR�[�h�S
     ,ven_tasya_daisu04         xxcso_install_base_v.ven_tasya_daisu04%TYPE      -- ���Б䐔�S
     ,ven_tasya_cd05            xxcso_install_base_v.ven_tasya_cd05%TYPE         -- ���ЃR�[�h�T
     ,ven_tasya_daisu05         xxcso_install_base_v.ven_tasya_daisu05%TYPE      -- ���Б䐔�T
     ,ven_haiki_flg             xxcso_install_base_v.ven_haiki_flg%TYPE          -- �p���t���O
     ,haikikessai_dt            xxcso_install_base_v.haikikessai_dt%TYPE         -- �p�����ٓ�
     ,ven_sisan_kbn             xxcso_install_base_v.ven_sisan_kbn%TYPE          -- ���Y�敪
     ,ven_kobai_ymd             xxcso_install_base_v.ven_kobai_ymd%TYPE          -- �w�����t
     ,ven_kobai_kg              xxcso_install_base_v.ven_kobai_kg%TYPE           -- �w�����z
     ,count_no                  xxcso_install_base_v.count_no%TYPE               -- �J�E���^�[No.
     ,chiku_cd                  xxcso_install_base_v.chiku_cd%TYPE               -- �n��R�[�h
     ,sagyougaisya_cd           xxcso_install_base_v.sagyougaisya_cd%TYPE        -- ��Ɖ�ЃR�[�h
     ,jigyousyo_cd              xxcso_install_base_v.jigyousyo_cd%TYPE           -- ���Ə��R�[�h
     ,den_no                    xxcso_install_base_v.den_no%TYPE                 -- �ŏI��Ɠ`�[No.
     ,job_kbn                   xxcso_install_base_v.job_kbn%TYPE                -- �ŏI��Ƌ敪
     ,sintyoku_kbn              xxcso_install_base_v.sintyoku_kbn%TYPE           -- �ŏI��Ɛi��
     ,yotei_dt                  xxcso_install_base_v.yotei_dt%TYPE               -- �ŏI��Ɗ����\���
     ,kanryo_dt                 xxcso_install_base_v.kanryo_dt%TYPE              -- �ŏI��Ɗ�����
     ,sagyo_level               xxcso_install_base_v.sagyo_level%TYPE            -- �ŏI�������e
     ,den_no2                   xxcso_install_base_v.den_no2%TYPE                -- �ŏI�ݒu�`�[No.
     ,job_kbn2                  xxcso_install_base_v.job_kbn2%TYPE               -- �ŏI�ݒu�敪
     ,sintyoku_kbn2             xxcso_install_base_v.sintyoku_kbn2%TYPE          -- �ŏI�ݒu�i��
     ,jotai_kbn1                xxcso_install_base_v.jotai_kbn1%TYPE             -- �@����1�i�ғ���ԁj
     ,jotai_kbn2                xxcso_install_base_v.jotai_kbn2%TYPE             -- �@����2�i��ԏڍׁj
     ,jotai_kbn3                xxcso_install_base_v.jotai_kbn3%TYPE             -- �@����3�i�p�����j
     ,nyuko_dt                  xxcso_install_base_v.nyuko_dt%TYPE               -- ���ɓ�
     ,hikisakigaisya_cd         xxcso_install_base_v.hikisakigaisya_cd%TYPE      -- ���g��ЃR�[�h
     ,hikisakijigyosyo_cd       xxcso_install_base_v.hikisakijigyosyo_cd%TYPE    -- ���g���Ə��R�[�h
     ,setti_tanto               xxcso_install_base_v.setti_tanto%TYPE            -- �ݒu��S���Җ�
     ,setti_tel1                xxcso_install_base_v.setti_tel1%TYPE             -- �ݒu��TEL(�A��)�P
     ,setti_tel2                xxcso_install_base_v.setti_tel2%TYPE             -- �ݒu��TEL(�A��)�Q
     ,setti_tel3                xxcso_install_base_v.setti_tel3%TYPE             -- �ݒu��TEL(�A��)�R
     ,tenhai_tanto              xxcso_install_base_v.tenhai_tanto%TYPE           -- �]���p���Ǝ�
     ,tenhai_den_no             xxcso_install_base_v.tenhai_den_no%TYPE          -- �]���p���`�[��
     ,syoyu_cd                  xxcso_install_base_v.syoyu_cd%TYPE               -- ���L��
     ,tenhai_flg                xxcso_install_base_v.tenhai_flg%TYPE             -- �]���p���󋵃t���O
     ,kanryo_kbn                xxcso_install_base_v.kanryo_kbn%TYPE             -- �]�������敪
     ,sakujo_flg                xxcso_install_base_v.sakujo_flg%TYPE             -- �폜�t���O
     ,safty_level               xxcso_install_base_v.safty_level%TYPE            -- ���S�ݒu�
     ,lease_kbn                 xxcso_install_base_v.lease_kbn%TYPE              -- ���[�X�敪
     ,base_code                 VARCHAR2(100)                                    -- ���_(����)�R�[�h
     ,account_number            xxcso_cust_accounts_v.account_number%TYPE        -- �ڋq�R�[�h
     ,attribute2                po_un_numbers_vl.attribute2%TYPE                 -- �������[�J�[
     ,attribute9                po_un_numbers_vl.attribute9%TYPE                 -- ����@�敪�P
     ,attribute10               po_un_numbers_vl.attribute10%TYPE                -- ����@�敪�Q
     ,attribute11               po_un_numbers_vl.attribute11%TYPE                -- ����@�敪�R
     ,lease_type                xxcff_contract_headers.lease_type%TYPE           -- �ă��[�X�敪
     ,second_charge             xxcff_contract_lines.second_charge%TYPE          -- ���[�X�� ���z���[�X��(�Ŕ�)
     ,attribute8                po_un_numbers_vl.attribute8%TYPE                 -- �R������
     ,actual_work_date          xxcso_in_work_data.actual_work_date%TYPE         -- �ؗ��J�n��
     ,last_inst_cust_code       xxcso_install_base_v.last_inst_cust_code%TYPE    -- �挎���ڋq�R�[�h
     ,last_jotai_kbn            xxcso_install_base_v.last_jotai_kbn%TYPE         -- �挎���@����
     ,last_year_month           xxcso_install_base_v.last_year_month%TYPE        -- �挎���N��
     ,last_month_base_cd        VARCHAR2(1000)                                   -- �挎�����_(����)�R�[�h
     ,new_old_flag              xxcso_install_base_v.new_old_flag%TYPE           -- �V�Ñ�t���O
     ,sysdate_now               VARCHAR2(100)                                    -- �A�g����
     ,instance_status_id        xxcso_install_base_v.instance_status_id%TYPE     -- �X�e�[�^�XID
    );
  --*** �f�[�^�o�^�A�X�V��O ***
  global_ins_upd_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_ins_upd_expt,-30000);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_sysdate          OUT NOCOPY VARCHAR2,  -- �V�X�e�����t
    od_bsnss_mnth       OUT NOCOPY VARCHAR2,  -- �Ɩ�������
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_sysdate           VARCHAR2(100);    -- �V�X�e�����t
    lv_init_msg          VARCHAR2(5000);   -- �G���[���b�Z�[�W���i�[
    lv_bsnss_mnth        VARCHAR2(10);             -- �Ɩ����������i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �V�X�e�����t�擾
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    lv_init_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_01      --���b�Z�[�W�R�[�h
                     );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_init_msg  || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- �Ɩ��������擾
    lv_bsnss_mnth := TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMM');
--
   -- �Ɩ��������擾�Ɏ��s�����ꍇ
    IF (lv_bsnss_mnth IS NULL) THEN
      -- ��s�̑}��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_16             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    ELSE
      -- �擾�����Ɩ������������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg31  || CHR(10) ||
                   cv_debug_msg32  || lv_bsnss_mnth || CHR(10) ||
                   ''
      );
    END IF;
--
    -- �擾�����V�X�e�����t�E�Ɩ���������OUT�p�����[�^�ɐݒ�
    ov_sysdate := lv_sysdate;
    od_bsnss_mnth := TO_DATE(lv_bsnss_mnth,'YYYYMM');
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
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l���擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSV�t�@�C���o�͐�
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSV�t�@�C����
    ov_company_cd           OUT NOCOPY VARCHAR2,        -- ��ЃR�[�h(�Œ�l001)
    /*20090709_hosoi_0000518 START*/
    ov_attribute_level      OUT NOCOPY VARCHAR2,        -- IB�g�������e���v���[�g�A�N�Z�X���x��
    /*20090709_hosoi_0000518 END*/
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- �v���O������
--
    cv_tkn_csv_name     CONSTANT VARCHAR2(100)  := 'CSV_FILE_NAME';
      -- �C���^�[�t�F�[�X�t�@�C�����g�[�N����
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_DIR';     -- CSV�t�@�C���o�͐�
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_CSV_IB';      -- CSV�t�@�C����
    cv_company_cd       CONSTANT VARCHAR2(100)  := 'XXCSO1_INFO_OUT_COMPANY_CD';  -- ��ЃR�[�h(�Œ�l001)
    /*20090709_hosoi_0000518 START*/
    cv_attribute_level  CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';   -- IB�g�������e���v���[�g�A�N�Z�X���x��
    /*20090709_hosoi_0000518 END*/
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
    -- *** ���[�J���ϐ� ***
    lv_file_dir       VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(2000);             -- CSV�t�@�C����
    lv_company_cd     VARCHAR2(2000);             -- ��ЃR�[�h(�Œ�l001)
    lv_msg_set        VARCHAR2(1000);             -- ���b�Z�[�W�i�[
    /*20090709_hosoi_0000518 START*/
    lv_attribute_level  VARCHAR2(15);
    /*20090709_hosoi_0000518 END*/
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
    -- �v���t�@�C���l���擾
    -- ===============================
--
    -- CSV�t�@�C���o�͐�̒l�擾
    FND_PROFILE.GET(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSV�t�@�C�����̒l�擾
    FND_PROFILE.GET(
                  cv_file_name
                 ,lv_file_name
    );
    -- ��ЃR�[�h�̒l�擾
    FND_PROFILE.GET(
                  cv_company_cd
                 ,lv_company_cd
    );
    /*20090709_hosoi_0000518 START*/
    -- IB�g�������e���v���[�g�A�N�Z�X���x��
    FND_PROFILE.GET(
                  cv_attribute_level
                 ,lv_attribute_level
    );
    /*20090709_hosoi_0000518 END*/
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg5 || lv_file_name   || CHR(10) ||
                 cv_debug_msg6 || lv_company_cd  || CHR(10) ||
                 /*20090709_hosoi_0000518 START*/
                 cv_debug_msg33|| lv_attribute_level || CHR(10) ||
                 /*20090709_hosoi_0000518 EMD*/
                 ''
    );
    --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W�o��
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_csv_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- �߂�l���uNULL�v�ł������ꍇ,��O�������s��
    -- CSV�t�@�C���o�͐�
    IF (lv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- CSV�t�@�C����
    IF (lv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ��ЃR�[�h(�Œ�l001)
    IF (lv_company_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_company_cd            -- �g�[�N���l1��ЃR�[�h(�Œ�l001)
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    ov_file_dir   := lv_file_dir;       -- CSV�t�@�C���o�͐�
    ov_file_name  := lv_file_name;      -- CSV�t�@�C����
    ov_company_cd := lv_company_cd;     -- ��ЃR�[�h(�Œ�l001)
    /*20090709_hosoi_0000518 START*/
    ov_attribute_level := lv_attribute_level;  -- IB�g�������e���v���[�g�A�N�Z�X���x��
    /*20090709_hosoi_0000518 END*/
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- CSV�t�@�C���o�͐�
    iv_file_name            IN  VARCHAR2,               -- CSV�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- �v���O������
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- ���o�̓��[�h

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
    -- *** ���[�J���ϐ� ***
    lv_file_dir       VARCHAR2(1000);      -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(1000);      -- CSV�t�@�C����
    lv_exists         BOOLEAN;             -- ���݃`�F�b�N����
    lv_file_length    VARCHAR2(1000);      -- �t�@�C���T�C�Y
    lv_blocksize      VARCHAR2(1000);      -- �u���b�N�T�C�Y
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    lv_file_dir   := iv_file_dir;       -- CSV�t�@�C���o�͐�
    lv_file_name  := iv_file_name;      -- CSV�t�@�C����
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSV�t�@�C�������݂����ꍇ
    IF (lv_exists = cb_true) THEN
      -- CSV�t�@�C���c���G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                        ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf := lv_errmsg;
      RAISE file_err_expt;
    ELSIF (lv_exists = cb_false) THEN
      -- ========================
      -- CSV�t�@�C���I�[�v��
      -- ========================
      BEGIN
  --
        -- �t�@�C��ID���擾
        gf_file_hand := UTL_FILE.FOPEN(
                             location   => lv_file_dir
                            ,filename   => lv_file_name
                            ,open_mode  => cv_open_writer
          );
        -- *** DEBUG_LOG ***
        -- �t�@�C���I�[�v���������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg9    || CHR(10)   ||
                     cv_debug_msg_fnm || lv_file_name || CHR(10) ||
                     ''
        );
        EXCEPTION
          WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
               UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
               UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
               UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
            -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W�擾
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_04         -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                          ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                          ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                          ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
            );
            lv_errbuf := lv_errmsg;
            RAISE file_err_expt;
      END;
    END IF;
--
    EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- �擾�����l��OUT�p�����[�^�ɐݒ�
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
--
  /**********************************************************************************
   * Procedure Name   : get_csv_data
   * Description      : CSV�t�@�C���ɏo�͂���֘A���擾 (A-6)
   ***********************************************************************************/
  PROCEDURE get_csv_data(
    io_get_rec      IN  OUT NOCOPY g_value_rtype,      -- ���f�[�^
    id_bsnss_mnth   IN  DATE,                          -- �Ɩ����t
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'get_csv_data';       -- �v���O������
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    --
    cv_quick_cd                CONSTANT VARCHAR2(100)  := '�N�C�b�N�R�[�h';
    cv_base_account_cd         CONSTANT VARCHAR2(100)  := '�ڋq�}�X�^�r���[';
    cv_lst_bs_ccnt_cd          CONSTANT VARCHAR2(100)  := '�ڋq�}�X�^�r���[(�O����)';
    cv_po_un_number_vl         CONSTANT VARCHAR2(100)  := '���A�ԍ��}�X�^�r���[';
    cv_contract_headers        CONSTANT VARCHAR2(100)  := '���[�X�_��f�[�^';
    cv_work_data               CONSTANT VARCHAR2(100)  := '��ƃf�[�^�e�[�u��';
    /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
    /* 2009.04.09 K.Satomura T1_0441�Ή� START */
    cv_actual_work_date        CONSTANT VARCHAR2(100)  := '��ƃf�[�^�e�[�u���̎���Ɠ�(�ؗ��J�n��)';
    /* 2009.04.09 K.Satomura T1_0441�Ή� END */
    cv_clm_nm                  CONSTANT VARCHAR2(100)  := '�����R�[�h';
    /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
    cv_actual_work_date_2      CONSTANT VARCHAR2(100)  := '��ƃf�[�^�e�[�u���̎���Ɠ�(�ؗ��J�n��)��';
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_mnth_shft          CONSTANT NUMBER       := -1;        -- �挎�Ɩ����擾�p��l
    cv_yr_mnth_frmt       CONSTANT VARCHAR2(6)  := 'YYYYMM';  -- �N���t�H�[�}�b�g
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
    cv_lookup_code        CONSTANT fnd_lookup_values_vl.lookup_code%TYPE := '9';
    cv_tkn_val1           CONSTANT VARCHAR2(100) := '�C���X�^���X�X�e�[�^�X';
    cv_tkn_val2           CONSTANT VARCHAR2(100) := '�@��R�[�h';
    cv_tkn_val3           CONSTANT VARCHAR2(100) := '�挎���ڋq�R�[�h';
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
    /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 START */
    cv_ls_tp_no_cntrct          CONSTANT VARCHAR2(1)   := '9';      -- �ݒu�\�_�񖳂�
    cv_obj_sts_contracted       CONSTANT VARCHAR2(3)   := '102';    -- �_���
    cv_obj_sts_re_lease_cntrctd CONSTANT VARCHAR2(3)   := '104';    -- �ă��[�X�_���
    cv_obj_sts_uncontract       CONSTANT VARCHAR2(3)   := '101';    -- ���_��
    cv_obj_sts_lease_wait       CONSTANT VARCHAR2(3)   := '103';    -- �ă��[�X��
    /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 END */
    -- *** ���[�J���ϐ� ***
    ld_bsnss_mnth         DATE;
    lv_lookup_code        VARCHAR2(100);      -- �X�e�[�^�X
    lv_sale_base_code     VARCHAR2(100);      -- ���_(����)�R�[�h
    lv_account_number     VARCHAR2(100);      -- �ڋq�R�[�h
    lv_lst_accnt_num      VARCHAR2(100);      -- �挎���ڋq�R�[�h
    lv_install_code       VARCHAR2(100);      -- �����R�[�h
    lv_attribute2         VARCHAR2(150);      -- ���[�J�[�R�[�h
    lv_attribute9         VARCHAR2(150);      -- ����@�敪1
    lv_attribute10        VARCHAR2(150);      -- ����@�敪2
    lv_attribute11        VARCHAR2(150);      -- ����@�敪3
    lv_attribute8         VARCHAR2(150);      -- �R������
    lv_lease_type         VARCHAR2(100);      -- �ă��[�X�敪
    ln_second_charge      NUMBER;             -- ���[�X�� ���z���[�X��(�Ŕ�)
    lv_company_cd         VARCHAR2(2000);     -- ��ЃR�[�h(�Œ�l001)
    lv_base_code          VARCHAR2(2000);     -- ���_(����)�R�[�h
    lv_last_month_base_cd VARCHAR2(2000);     -- �挎�����_(����)�R�[�h
    ln_actual_work_date   NUMBER;             -- �ؗ��J�n��
    ld_sysdate            DATE;               -- �V�X�e�����t
    /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 START */
    lt_object_status      xxcff_object_headers.object_status%TYPE; -- �����X�e�[�^�X
    /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 END */
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
    ln_target_cnt         NUMBER;             -- �J�[�\�����o�����i�[
     /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
    lt_past_sale_base_code xxcmm_cust_accounts.past_sale_base_code%TYPE; --�O�����㋒�_CD
     /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */ 
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_act_wk_dt_cur(
             it_instll_cd IN xxcso_install_base_v.install_code%TYPE
           )
    IS
      SELECT xiw.actual_work_date  actual_work_date -- �ؗ��J�n��
            ,xrl.category_kbn      category_kbn     -- �J�e�S���敪
            ,xiw.job_kbn           job_kbn          -- ��Ƌ敪
            ,xrl.withdrawal_type   withdrawal_type  -- ���g�敪
      FROM   xxcso_in_work_data        xiw -- ��ƃf�[�^�e�[�u��
            ,po_requisition_headers    prh -- �����˗��w�b�_�r���[
            ,xxcso_requisition_lines_v xrl -- �����˗����׏��r���[
      WHERE  xiw.install2_processed_flag = cv_flag_yes
        AND  xiw.install_code2           = it_instll_cd
        AND  xiw.completion_kbn          = cn_completion_kbn
        AND  TO_CHAR(xiw.po_req_number)  = prh.segment1
        AND  prh.requisition_header_id   = xrl.requisition_header_id
        AND  xiw.line_num                = xrl.line_num
        AND  (
               (
                     xrl.category_kbn    = cv_category_kbn
                 AND xiw.job_kbn         = cn_job_kbn
                 AND ( 
                          xrl.withdrawal_type = cv_withdrawal_type_1
                       OR xrl.withdrawal_type = cv_withdrawal_type_2
                     )
               )
             OR
               (
                     xrl.category_kbn = cv_category_kbn_new_rplc
                 AND xiw.job_kbn      = cn_job_kbn_new_replace
               )
             OR
               (
                     xrl.category_kbn = cv_category_kbn_old_rplc
                 AND xiw.job_kbn      = cn_job_kbn_old_replace
               )
             )
      ORDER BY xiw.actual_work_date  DESC
     ;
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;            -- �K��\����f�[�^
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
    l_get_act_wk_dt_rec   get_act_wk_dt_cur%ROWTYPE;
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
    -- *** ���[�J����O ***
    select_error_expt     EXCEPTION;          -- �f�[�^�o�͏�����O
    /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
    select_warn_expt      EXCEPTION;
    status_warn_expt      EXCEPTION;          -- �f�[�^�o�͏����x����O
    /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    l_get_rec     := io_get_rec;
    ld_bsnss_mnth := id_bsnss_mnth;
    --������
    lv_lst_accnt_num      := NULL;
    lv_account_number     := NULL;
    lv_sale_base_code     := NULL;
    lv_last_month_base_cd := NULL;
    lv_company_cd     := gv_company_cd;
    ld_sysdate        := TO_DATE(l_get_rec.sysdate_now,'YYYYMMDDHH24MISS');
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
    ln_actual_work_date   := NULL;
    ln_target_cnt         := 0;
    /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
    -- ===============================
    -- �X�e�[�^�X�R�[�h�𒊏o
    -- ===============================
    BEGIN
      SELECT flv.lookup_code  lookup_code   -- �X�e�[�^�X
      INTO   lv_lookup_code                 -- �X�e�[�^�X
      FROM   csi_instance_statuses cis      -- �C���X�^���X�X�e�[�^�X�}�X�^
            ,fnd_lookup_values_vl flv       -- �N�C�b�N�R�[�h
      WHERE cis.instance_status_id = l_get_rec.instance_status_id  -- �X�e�[�^�XID
        AND flv.meaning = cis.name                                 -- ���e(�X�e�[�^�X��)
        AND flv.lookup_type = cv_instance_status                   -- ���b�N�A�b�v�^�C�v
        AND flv.enabled_flag = cv_enabled_flag                     -- �L���t���O
        AND ld_sysdate BETWEEN flv.start_date_active AND NVL(flv.end_date_active,ld_sysdate); -- �N�C�b�N�R�[�h����
    EXCEPTION
      -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
      WHEN OTHERS THEN
        /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
        --lv_errmsg := xxccp_common_pkg.get_msg(
        --                   iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
        --                  ,iv_name         => cv_tkn_number_06              -- ���b�Z�[�W�R�[�h
        --                  ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
        --                  ,iv_token_value1 => cv_quick_cd                   -- �g�[�N���l1���o������
        --                  ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                  ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --                  ,iv_token_name3  => cv_tkn_status_id              -- �g�[�N���R�[�h3
        --                  ,iv_token_value3 => l_get_rec.instance_status_id  -- �g�[�N���l3���o������(�X�e�[�^�XID)
        --                  ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
        --                  ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
        --    );
        --lv_errbuf  := lv_errmsg;
        --RAISE select_error_expt;
        lv_lookup_code := cv_lookup_code;
        ov_retcode     := cv_status_warn;
        lv_errmsg      := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_tkn_number_19       -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_param           -- �g�[�N���R�[�h1
                            ,iv_token_value1 => cv_tkn_val1            -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_object_cd       -- �g�[�N���R�[�h2
                            ,iv_token_value2 => l_get_rec.install_code -- �g�[�N���l2�O���Q��(�����R�[�h)
                          );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
    END;
--
    -- ===================================
    -- ���_(����)�R�[�h�E�ڋq�R�[�h�𒊏o
    -- ===================================
    /* 2009.08.06 K.Satomura 0000935�Ή� START */
    --IF ((l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3) AND (l_get_rec.install_account_id IS NULL)) THEN
    /* 2009.08.06 K.Satomura 0000935�Ή� END */
    lv_sale_base_code   := NULL;  -- ���_�R�[�h��NULL���Z�b�g
    lv_account_number   := NULL;  -- �ڋq�R�[�h��NULL���Z�b�g
    /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
    lt_past_sale_base_code := NULL; --�O�����㋒�_CD��NULL���Z�b�g
    /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
    /* 2009.08.06 K.Satomura 0000935�Ή� START */
    --ELSIF (l_get_rec.jotai_kbn1 IS NOT NULL) THEN
    /* 2009.08.06 K.Satomura 0000935�Ή� END */
    BEGIN
      /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
      --SELECT   (CASE
      --            WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_1 THEN
      --              xcav.sale_base_code       -- ���_(����)�R�[�h
      --            /* 2009.08.06 K.Satomura 0000935�Ή� START */
      --            --WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2 THEN
      --            --  xcav.account_number       -- �ڋq�R�[�h
      --            --WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3 THEN
      --            --  NULL
      --            WHEN l_get_rec.jotai_kbn1 IN (cv_jotai_kbn1_2, cv_jotai_kbn1_3) THEN
      --              xcav.account_number       -- �ڋq�R�[�h
      --            ELSE
      --              NULL
      --            /* 2009.08.06 K.Satomura 0000935�Ή� END */
      --          END) sale_base_code            -- ���_(����)�R�[�h
      SELECT   xcav.sale_base_code             -- ���_(����)�R�[�h
      /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
              ,xcav.account_number             -- �ڋq�R�[�h
              /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
              ,xcav.past_sale_base_code        -- �O�����㋒�_
              /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
      INTO     lv_sale_base_code               -- ���_(����)�R�[�h
              ,lv_account_number               -- �ڋq�R�[�h
              /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
              ,lt_past_sale_base_code          -- �O�����㋒�_
              /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
      FROM     xxcso_cust_accounts_v xcav      -- �ڋq�}�X�^�r���[
      WHERE    xcav.cust_account_id = l_get_rec.install_account_id; -- �A�J�E���gID

    EXCEPTION
      -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_07              -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_base_account_cd            -- �g�[�N���l1���o������
                          ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                          ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                          ,iv_token_name3  => cv_tkn_account_id             -- �g�[�N���R�[�h3
                          ,iv_token_value3 => l_get_rec.install_account_id  -- �g�[�N���l3���L�҃A�J�E���gID
                          ,iv_token_name4  => cv_tkn_location_cd            -- �g�[�N���R�[�h4
                          ,iv_token_value4 => lv_sale_base_code             -- �g�[�N���l4���_(����)�R�[�h
                          ,iv_token_name5  => cv_tkn_customer_cd            -- �g�[�N���R�[�h5
                          ,iv_token_value5 => lv_account_number             -- �g�[�N���l5�ڋq�R�[�h
                          ,iv_token_name6  => cv_tkn_err_msg                -- �g�[�N���R�[�h6
                          ,iv_token_value6 => SQLERRM                       -- �g�[�N���l6
            );
        lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
    END;
    /* 2009.08.06 K.Satomura 0000935�Ή� START */
    --END IF;
    /* 2009.08.06 K.Satomura 0000935�Ή� END */
    -- �@���ԂP���u2:�ؗ��v�̏ꍇ
    /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
    /* 2009.04.08 K.Satomura T1_0365�Ή� START */
    IF ((io_get_rec.new_old_flag <> cv_flag_yes) 
       OR (io_get_rec.new_old_flag IS NULL)) THEN
    /* 2009.04.08 K.Satomura T1_0365�Ή� END */
    /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
      IF (l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2) THEN
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
        --BEGIN
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
        /* 2009.04.09 K.Satomura T1_0441�Ή� START */
        --  SELECT MAX(xiwd.actual_work_date) max_actual_work_date
        --  INTO   ln_actual_work_date                       -- �ؗ��J�n��
        --  FROM   xxcso_in_work_data xiwd                   -- ��ƃf�[�^�e�[�u��
        --        ,po_requisition_headers_all prha           -- �����˗��w�b�_�e�[�u��
        --        ,po_requisition_lines_all prla             -- �����˗����׃e�[�u��
        --        ,xxcso_requisition_lines_v xrlv            -- �����˗����׏��r���[
        --  WHERE  xiwd.install_code2 = l_get_rec.install_code
        --    /*20090327_yabuki_T1_0193 START*/
        --    --AND  xiwd.job_kbn = cn_job_kbn
        --    /*20090327_yabuki_T1_0193 END*/
        --    AND  xiwd.completion_kbn = cn_completion_kbn
        --    AND  TO_CHAR(xiwd.po_req_number) = prha.segment1
        --    AND  prha.requisition_header_id = prla.requisition_header_id
        --    AND  xiwd.line_num = xrlv.requisition_line_id
        --    /*20090327_yabuki_T1_0193 START*/
        --    AND  (( xiwd.job_kbn = cn_job_kbn
        --       AND xrlv.category_kbn = cv_category_kbn
        --       AND xrlv.withdrawal_type = cv_withdrawal_type )
        --    OR   ( xiwd.job_kbn = cn_job_kbn_new_replace
        --       AND xrlv.category_kbn = cv_category_kbn_new_rplc )
        --    OR   ( xiwd.job_kbn = cn_job_kbn_old_replace
        --       AND xrlv.category_kbn = cv_category_kbn_old_rplc ));
        --    --AND xrlv.category_kbn = cv_category_kbn
        --    --AND xrlv.withdrawal_type = cv_withdrawal_type;
        --    /*20090327_yabuki_T1_0193 END*/
        /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
          --SELECT MAX(xiw.actual_work_date) max_actual_work_date -- �ؗ��J�n��
          --INTO   ln_actual_work_date
          --FROM   xxcso_in_work_data        xiw -- ��ƃf�[�^�e�[�u��
          --      ,po_requisition_headers    prh -- �����˗��w�b�_�r���[
          --      ,po_requisition_lines      prl -- �����˗����׃r���[
          --      ,xxcso_requisition_lines_v xrl -- �����˗����׏��r���[
          --WHERE  xiw.install_code2          = l_get_rec.install_code
          --  AND  xiw.completion_kbn         = cn_completion_kbn
          --  AND  TO_CHAR(xiw.po_req_number) = prh.segment1
          --  AND  prh.requisition_header_id  = prl.requisition_header_id
          --  AND  xiw.line_num               = xrl.line_num
          --  AND  (
          --         (
          --               xrl.category_kbn    = cv_category_kbn
          --           AND xiw.job_kbn         = cn_job_kbn
          --           AND xrl.withdrawal_type = cv_withdrawal_type
          --         )
          --       OR
          --         (
          --               xrl.category_kbn = cv_category_kbn_new_rplc
          --           AND xiw.job_kbn      = cn_job_kbn_new_replace
          --         )
          --       OR
          --         (
          --               xrl.category_kbn = cv_category_kbn_old_rplc
          --           AND xiw.job_kbn      = cn_job_kbn_old_replace
          --         )
          --       )
          --  ;
          /* 2009.04.09 K.Satomura T1_0441�Ή� END */
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
        --  SELECT MAX(xiw.actual_work_date) max_actual_work_date -- �ؗ��J�n��
        --  INTO   ln_actual_work_date
        --  FROM   xxcso_in_work_data        xiw -- ��ƃf�[�^�e�[�u��
        --        ,po_requisition_headers    prh -- �����˗��w�b�_�r���[
        --        ,xxcso_requisition_lines_v xrl -- �����˗����׏��r���[
        --  WHERE  xiw.install2_processed_flag = cv_flag_yes
        --    AND  xiw.install_code2           = l_get_rec.install_code
        --    AND  xiw.completion_kbn          = cn_completion_kbn
        --    AND  TO_CHAR(xiw.po_req_number)  = prh.segment1
        --    AND  prh.requisition_header_id   = xrl.requisition_header_id
        --    AND  xiw.line_num                = xrl.line_num
        --    AND  (
        --           (
        --                 xrl.category_kbn    = cv_category_kbn
        --             AND xiw.job_kbn         = cn_job_kbn
        --             AND xrl.withdrawal_type = cv_withdrawal_type
        --           )
        --         OR
        --           (
        --                 xrl.category_kbn = cv_category_kbn_new_rplc
        --             AND xiw.job_kbn      = cn_job_kbn_new_replace
        --           )
        --         OR
        --           (
        --                 xrl.category_kbn = cv_category_kbn_old_rplc
        --             AND xiw.job_kbn      = cn_job_kbn_old_replace
        --           )
        --         )
        --    ;
        --
        ---- �������ʂ��Ȃ��ꍇ
        --IF (ln_actual_work_date IS NULL) THEN
        --  lv_errmsg := xxccp_common_pkg.get_msg(
        --                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
        --                      ,iv_name         => cv_tkn_number_17              -- ���b�Z�[�W�R�[�h
        --                      ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
        --                      ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
        --                      ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                      ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --        );
        --    lv_errbuf  := lv_errmsg;
        --    RAISE select_warn_expt;
        --END IF;
        --
        --EXCEPTION
        --  -- �������ʂ��Ȃ��ꍇ�A�x���I����O��
        --  WHEN select_warn_expt THEN
        --    RAISE status_warn_expt;
        --  -- ���o���s�����ꍇ
        --  WHEN OTHERS THEN
        --    lv_errmsg := xxccp_common_pkg.get_msg(
        --                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
        --                      ,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h
        --                      -- ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
        --                      -- ,iv_token_value1 => cv_work_data                  -- �g�[�N���l1���o������
        --                      -- ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                      -- ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --                      -- /* 2009.04.09 K.Satomura T1_0441�Ή� START */
        --                      -- --,iv_token_name3  => cv_tkn_work_date              -- �g�[�N���R�[�h3
        --                      -- --,iv_token_value3 => ln_actual_work_date           -- �g�[�N���l3����Ɠ�
        --                      -- --,iv_token_name4  => cv_tkn_location_cd            -- �g�[�N���R�[�h4
        --                      -- --,iv_token_value4 => lv_base_code                  -- �g�[�N���l4���_(����)�R�[�h
        --                      -- --,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
        --                      -- --,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
        --                      -- ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
        --                      -- ,iv_token_value3 => SQLERRM                       -- �g�[�N���l3����Ɠ�
        --                      -- /* 2009.04.09 K.Satomura T1_0441�Ή� END */
        --                      ,iv_token_name1  => cv_tkn_tsk_nm                 -- �g�[�N���R�[�h1
        --                      ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
        --                      ,iv_token_name2  => cv_tkn_item                   -- �g�[�N���R�[�h2
        --                      ,iv_token_value2 => cv_clm_nm                     -- �g�[�N���l2���ږ������R�[�h
        --                      ,iv_token_name3  => cv_tkn_vl                     -- �g�[�N���R�[�h3
        --                      ,iv_token_value3 => l_get_rec.install_code        -- �g�[�N���l3�O���Q��(�����R�[�h)
        --                      ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
        --                      ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4SQL�G���[���b�Z�[�W
        --        );
        --    lv_errbuf  := lv_errmsg;
        --    RAISE select_error_expt;
        --END;
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
        -- -- �������ʂ��Ȃ��ꍇ
        -- IF (ln_actual_work_date IS NULL) THEN
        --   lv_errmsg := xxccp_common_pkg.get_msg(
        --                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
        --                       /* 2009.04.09 K.Satomura T1_0441�Ή� START */
        --                       --,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h
        --                       --,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
        --                       --,iv_token_value1 => cv_work_data                  -- �g�[�N���l1���o������
        --                       --,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                       --,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --                       ,iv_name         => cv_tkn_number_17              -- ���b�Z�[�W�R�[�h
        --                       ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
        --                       ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
        --                       ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                       ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --                       --,iv_token_name3  => cv_tkn_work_date              -- �g�[�N���R�[�h3
        --                       --,iv_token_value3 => ln_actual_work_date           -- �g�[�N���l3����Ɠ�
        --                       --,iv_token_name4  => cv_tkn_location_cd            -- �g�[�N���R�[�h4
        --                       --,iv_token_value4 => lv_base_code                  -- �g�[�N���l4���_(����)�R�[�h
        --                       --,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
        --                       --,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
        --                       /* 2009.04.09 K.Satomura T1_0441�Ή� END */
        --         );
        --     lv_errbuf  := lv_errmsg;
        --     RAISE select_error_expt;
        -- END IF;
        /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
        -- �J�[�\���I�[�v��
        OPEN get_act_wk_dt_cur(
               it_instll_cd  => l_get_rec.install_code -- �O���Q��
             );
--
          BEGIN
            FETCH get_act_wk_dt_cur INTO l_get_act_wk_dt_rec;
--
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_tsk_nm                 -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
                                ,iv_token_name2  => cv_tkn_item                   -- �g�[�N���R�[�h2
                                ,iv_token_value2 => cv_clm_nm                     -- �g�[�N���l2���ږ������R�[�h
                                ,iv_token_name3  => cv_tkn_vl                     -- �g�[�N���R�[�h3
                                ,iv_token_value3 => l_get_rec.install_code        -- �g�[�N���l3�O���Q��(�����R�[�h)
                                ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                                ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4SQL�G���[���b�Z�[�W
                  );
              lv_errbuf  := lv_errmsg;
              RAISE select_error_expt;
          END;
--
        -- �����Ώی����i�[
        ln_target_cnt := get_act_wk_dt_cur%ROWCOUNT;
        --���o�������O���̏ꍇ
        IF (ln_target_cnt = 0) THEN
        /* 2009.07.21 K.Hosoi 0000475�Ή� START */
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
--                                ,iv_name         => cv_tkn_number_18              -- ���b�Z�[�W�R�[�h
--                                ,iv_token_name1  => cv_tkn_tsk_nm                 -- �g�[�N���R�[�h1
--                                ,iv_token_value1 => cv_actual_work_date_2         -- �g�[�N���l1���o������
--                                ,iv_token_name2  => cv_tkn_bukken                 -- �g�[�N���R�[�h2
--                                ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
--                  );
--            lv_errbuf  := lv_errmsg;
--            RAISE status_warn_expt;
          ln_actual_work_date := NULL;
        /* 2009.07.21 K.Hosoi 0000475�Ή� END */
        END IF;
--
        -- �擾��������Ɠ���NULL�̏ꍇ
        IF ( l_get_act_wk_dt_rec.actual_work_date IS NULL ) THEN
        /* 2009.07.21 K.Hosoi 0000475�Ή� START */
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
--                              ,iv_name         => cv_tkn_number_17              -- ���b�Z�[�W�R�[�h
--                              ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
--                              ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
--                              ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
--                              ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
--                );
--          lv_errbuf  := lv_errmsg;
--          RAISE status_warn_expt;
          ln_actual_work_date := NULL;
        /* 2009.07.21 K.Hosoi 0000475�Ή� END */
        END IF;
--
        -- �J�e�S���敪 = '50'(���g���) ���� ��Ƌ敪 = '5'(���g)�̏ꍇ
        IF ( l_get_act_wk_dt_rec.category_kbn = cv_category_kbn
          AND l_get_act_wk_dt_rec.job_kbn = cn_job_kbn ) THEN
--
          -- ���g�敪 = '1: ���g'�̏ꍇ
          IF ( l_get_act_wk_dt_rec.withdrawal_type = cv_withdrawal_type_1) THEN
            -- �ؗ��J�n���ɁA�擾��������Ɠ���ݒ�
            ln_actual_work_date := l_get_act_wk_dt_rec.actual_work_date;
--
          -- ���g�敪 = '2: �ꎞ���g'�̏ꍇ
          ELSE
            -- �ؗ��J�n����NULL��ݒ�
            ln_actual_work_date := NULL;
          END IF;
        ELSE
          -- �ؗ��J�n���ɁA�擾��������Ɠ���ݒ�
          ln_actual_work_date := l_get_act_wk_dt_rec.actual_work_date;
        END IF;
--
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
        /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� END */
--
      END IF;
    /* 2009.04.08 K.Satomura T1_0365�Ή� START */
    END IF;
    /* 2009.04.08 K.Satomura T1_0365�Ή� END */
--
    -- ========================================
    -- �������[�J�[�A����@�敪�ƃR�������𒊏o
    -- ========================================
    /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� START */
    -- �C���X�^���X�^�C�v���u1:�����̔��@�v�̏ꍇ
    --IF (l_get_rec.instance_type_code = 1) THEN
    /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� END */
    BEGIN
      SELECT  punv.attribute2 attribute2    -- ���[�J�[�R�[�h
             ,punv.attribute9 attribute9    -- ����@�敪�P
             ,punv.attribute10 attribute10  -- ����@�敪2
             ,punv.attribute11 attribute11  -- ����@�敪3
             ,punv.attribute8 attribute8    -- �R������
      INTO    lv_attribute2                 -- ���[�J�[�R�[�h
             ,lv_attribute9                 -- ����@�敪1
             ,lv_attribute10                -- ����@�敪2
             ,lv_attribute11                -- ����@�敪3
             ,lv_attribute8                 -- �R������
      FROM   po_un_numbers_vl punv          -- ���A�ԍ��}�X�^�r���[
      WHERE  punv.un_number = l_get_rec.vendor_model; -- �@��R�[�h
      /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� START */
      -- �C���X�^���X�^�C�v���u1:�����̔��@�v�ȊO�̏ꍇ
      IF (l_get_rec.instance_type_code <> 1) THEN
        lv_attribute9   := NULL;             -- ����@�敪1
        lv_attribute10  := NULL;             -- ����@�敪2
        lv_attribute11  := NULL;             -- ����@�敪3
        lv_attribute8   := NULL;             -- �R������
      END IF;
      /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� END */
    EXCEPTION
      -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
      WHEN OTHERS THEN
        /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
        --lv_errmsg := xxccp_common_pkg.get_msg(
        --                   iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
        --                  ,iv_name         => cv_tkn_number_08              -- ���b�Z�[�W�R�[�h
        --                  ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
        --                  ,iv_token_value1 => cv_po_un_number_vl            -- �g�[�N���l1���o������
        --                  ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
        --                  ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
        --                  ,iv_token_name3  => cv_tkn_un_number              -- �g�[�N���R�[�h3
        --                  ,iv_token_value3 => l_get_rec.vendor_model        -- �g�[�N���l3�@��R�[�h
        --                  ,iv_token_name4  => cv_tkn_maker_cd               -- �g�[�N���R�[�h4
        --                  ,iv_token_value4 => lv_attribute2                 -- �g�[�N���l4���[�J�[�R�[�h
        --                  ,iv_token_name5  => cv_tkn_special1               -- �g�[�N���R�[�h5
        --                  ,iv_token_value5 => lv_attribute9                 -- �g�[�N���l5����@�敪1
        --                  ,iv_token_name6  => cv_tkn_special2               -- �g�[�N���R�[�h6
        --                  ,iv_token_value6 => lv_attribute10                -- �g�[�N���l6����@�敪2
        --                  ,iv_token_name7  => cv_tkn_special3               -- �g�[�N���R�[�h7
        --                  ,iv_token_value7 => lv_attribute11                -- �g�[�N���l7����@�敪3
        --                  ,iv_token_name8  => cv_tkn_column                 -- �g�[�N���R�[�h8
        --                  ,iv_token_value8 => lv_attribute8                 -- �g�[�N���l8�R������
        --                  ,iv_token_name9  => cv_tkn_err_msg                -- �g�[�N���R�[�h9
        --                  ,iv_token_value9 => SQLERRM                       -- �g�[�N���l9
        --    );
        --lv_errbuf  := lv_errmsg;
        --RAISE select_error_expt;
        lv_attribute2  := NULL;
        lv_attribute9  := NULL;
        lv_attribute10 := NULL;
        lv_attribute11 := NULL;
        lv_attribute8  := NULL;
        ov_retcode     := cv_status_warn;
        lv_errmsg      := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_tkn_number_19       -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_param           -- �g�[�N���R�[�h1
                            ,iv_token_value1 => cv_tkn_val2            -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_object_cd       -- �g�[�N���R�[�h2
                            ,iv_token_value2 => l_get_rec.install_code -- �g�[�N���l2�O���Q��(�����R�[�h)
                          );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg
        );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
        /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
    END;
    /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� START */
    -- �C���X�^���X�^�C�v���u1:�����̔��@�v�ȊO�̏ꍇ
    --ELSE
    --  lv_attribute2   := NULL;             -- ���[�J�[�R�[�h
    --  lv_attribute9   := NULL;             -- ����@�敪1
    --  lv_attribute10  := NULL;             -- ����@�敪2
    --  lv_attribute11  := NULL;             -- ����@�敪3
    --  lv_attribute8   := NULL;             -- �R������
    --END IF;
    /* 2010.03.17 K.Hosoi E_�{�ғ�_01881�Ή� END */
--
    -- ==================================================
    -- �ă��[�X�敪�ƃ��[�X�� ���z���[�X��(�Ŕ�)���𒊏o
    -- ==================================================
    /*20090327_yabuki_T1_0191_T1_0194 START*/
    -- ���[�X�敪���u1:���Ѓ��[�X�v�̏ꍇ
    lv_install_code := l_get_rec.install_code;
    IF (l_get_rec.lease_kbn = cv_lease_kbn_1) THEN
--    -- ���[�X�敪���u1:���Ѓ��[�X�v���́u2:���q�l���[�X�v�̏ꍇ
--    lv_install_code := SUBSTR(l_get_rec.install_code,1,3) || SUBSTR(l_get_rec.install_code,5,6);
--    IF ((l_get_rec.lease_kbn = cv_lease_kbn_1) OR (l_get_rec.lease_kbn = cv_lease_kbn_2)) THEN
    /*20090327_yabuki_T1_0191_T1_0194 END*/
      BEGIN
        SELECT  xch.lease_type lease_type       -- �ă��[�X�敪
               ,xcl.second_charge second_charge -- ���[�X�� ���z���[�X��(�Ŕ�)
               /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 START */
               ,xoh.object_status object_status -- �����X�e�[�^�X
               /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 END */
        INTO    lv_lease_type                   -- �ă��[�X�敪
               ,ln_second_charge                -- ���[�X�� ���z���[�X��(�Ŕ�)
               /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 START */
               ,lt_object_status
               /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 END */
        FROM    xxcff_object_headers xoh        -- ���[�X�����}�X�^
               ,xxcff_contract_headers xch      -- ���[�X�_��e�[�u��
               ,xxcff_contract_lines xcl        -- ���[�X�_�񖾍׃e�[�u��
        WHERE   xoh.object_code = lv_install_code                 -- �����R�[�h
          AND   xoh.object_header_id = xcl.object_header_id       -- ��������ID
          AND   xcl.contract_header_id = xch.contract_header_id   -- �_�����ID
          AND   xch.re_lease_times = xoh.re_lease_times;          -- �ă��[�X��
        /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 START */
        --
        -- �����X�e�[�^�X�ɂ��A�ݒu�\�_��̗L�����`�F�b�N
        -- �����X�e�[�^�X��NULL�ȊO�ł��A�u�_��ρv�u�ă��[�X�_��ρv�u���_��v�u�ă��[�X�ҁv�ȊO�̏ꍇ
        IF ( lt_object_status IS NOT NULL
             AND lt_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract,
                                         cv_obj_sts_lease_wait ) ) THEN
          -- �ă��[�X�敪��'9'��ݒ� (�����n�ɂ͋敪�u9�v�̂ݘA�g����A���̂͘A�g����Ȃ�)
          lv_lease_type := cv_ls_tp_no_cntrct;
          --
        END IF;
        /* 2010.02.26 K.Hosoi E_�{�ғ�_01568 END */
      EXCEPTION
        /*20090327_yabuki_T1_0192 START*/
        -- �Y�����郌�R�[�h�����݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          lv_lease_type    := NULL;    -- �ă��[�X�敪
          ln_second_charge := NULL;    -- ���[�X�� ���z���[�X��(�Ŕ�)
        /*20090327_yabuki_T1_0192 END*/
        --
        -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_09              -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_contract_headers           -- �g�[�N���l1���o������
                          ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                          ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                          ,iv_token_name3  => cv_tkn_lease_kbn              -- �g�[�N���R�[�h3
                          ,iv_token_value3 => lv_lease_type                 -- �g�[�N���l3���[�X�敪
                          ,iv_token_name4  => cv_tkn_lease_price            -- �g�[�N���R�[�h4
                          ,iv_token_value4 => TO_CHAR(ln_second_charge)     -- �g�[�N���l4���[�X��
                          ,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                          ,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
            );
          lv_errbuf  := lv_errmsg;
          RAISE select_error_expt;
      END;
    END IF;
--
    -- =========================================
    -- �挎�����_�R�[�h�E�挎���ڋq�R�[�h�𒊏o
    -- =========================================
    /* 2009.09.03 M.Maruyama 0001192�Ή� START */
    -- �挎���N�������ݒ�̏ꍇ
    IF (l_get_rec.last_year_month IS NULL) THEN
      -- �ݒu��=�Ɩ����̏ꍇ
      IF (TO_CHAR(l_get_rec.install_date,cv_yr_mnth_frmt) = TO_CHAR(ld_bsnss_mnth,cv_yr_mnth_frmt)) THEN
        lv_last_month_base_cd   := NULL;  -- �挎�����_�R�[�h��NULL���Z�b�g
        lv_lst_accnt_num        := NULL;  -- �挎���ڋq�R�[�h��NULL���Z�b�g
      -- ����ݒu��<>�Ɩ����̏ꍇ
      ELSE
        /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
        --lv_last_month_base_cd   := lv_sale_base_code;  -- �挎�����_�R�[�h�Ɍ��݂̋��_�R�[�h���Z�b�g
        lv_last_month_base_cd   := lt_past_sale_base_code;  -- �挎�����_�R�[�h�Ɍ��݂̌ڋq�̑O�����㋒�_�R�[�h���Z�b�g
        /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
        lv_lst_accnt_num        := lv_account_number;  -- �挎���ڋq�R�[�h�Ɍ��݂̌ڋq�R�[�h���Z�b�g
      END IF;
--
    -- �挎���N��<>�Ɩ���-�P�̏ꍇ
    --IF ((l_get_rec.last_year_month <> TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt))
    --  OR (l_get_rec.last_year_month IS NULL))
    ELSIF (l_get_rec.last_year_month <> TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt))
    /* 2009.09.03 M.Maruyama 0001192�Ή� END */
    THEN
      /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
      --lv_last_month_base_cd   := lv_sale_base_code;  -- �挎�����_�R�[�h�Ɍ��݂̋��_�R�[�h���Z�b�g
      lv_last_month_base_cd   := lt_past_sale_base_code;  -- �挎�����_�R�[�h�Ɍ��݂̌ڋq�̑O�����㋒�_�R�[�h���Z�b�g
      /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
      lv_lst_accnt_num        := lv_account_number;  -- �挎���ڋq�R�[�h�Ɍ��݂̌ڋq�R�[�h���Z�b�g
--
    -- �挎���N��=�Ɩ���-�P�̏ꍇ
    ELSIF (l_get_rec.last_year_month = TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt)) THEN
      -- �挎���@���Ԃ�3�̏ꍇ
      /* 2009.08.06 K.Satomura 0000935�Ή� START */
      --IF (l_get_rec.last_jotai_kbn = cv_jotai_kbn1_3) THEN
      --  lv_last_month_base_cd   := NULL;                           -- �挎�����_�R�[�h��NULL���Z�b�g
      --  lv_lst_accnt_num        := l_get_rec.last_inst_cust_code;  -- �挎���ڋq�R�[�h�ɐ挎���ڋq�R�[�h���Z�b�g
      --ELSIF (l_get_rec.last_jotai_kbn IN (cv_jotai_kbn1_1,cv_jotai_kbn1_2)) THEN
      /* 2009.08.06 K.Satomura 0000935�Ή� END */
      BEGIN
        /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
         SELECT xcav.past_sale_base_code  last_month_base_cd-- �O�����㋒�_(����)�R�[�h 
               ,l_get_rec.last_inst_cust_code  -- �挎���ڋq�R�[�h
          INTO  lv_last_month_base_cd           -- �挎�����㋒�_�R�[�h
               ,lv_lst_accnt_num                -- �挎���ڋq�R�[�h
          FROM  xxcso_cust_accounts_v xcav      -- �ڋq�}�X�^�r���[
         WHERE  xcav.account_number = l_get_rec.last_inst_cust_code; -- �ڋq�R�[�h
         
        --SELECT (CASE
        --          WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_1 THEN
        --            xcav.past_sale_base_code  -- �O�����㋒�_(����)�R�[�h
        --          /* 2009.08.06 K.Satomura 0000935�Ή� START */
        --          --WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_2 THEN
        --          WHEN l_get_rec.last_jotai_kbn IN (cv_jotai_kbn1_2, cv_jotai_kbn1_3) THEN
        --          /* 2009.08.06 K.Satomura 0000935�Ή� END */
        --            /* 2009.12.09 T.Maruyama E_�{�ғ�_00117 START */
        --            --xcav.account_number       -- �ڋq�R�[�h
        --            xcav.sale_base_code       -- ����S�����_�R�[�h
        --          ELSE
        --            xcav.sale_base_code       -- ����S�����_�R�[�h
        --            /* 2009.12.09 T.Maruyama E_�{�ғ�_00117 END */
        --          END) last_month_base_cd
        --       ,l_get_rec.last_inst_cust_code  -- �挎���ڋq�R�[�h
        --  INTO  lv_last_month_base_cd           -- �挎�����㋒�_�R�[�h
        --       ,lv_lst_accnt_num                -- �挎���ڋq�R�[�h
        --  FROM  xxcso_cust_accounts_v xcav      -- �ڋq�}�X�^�r���[
        -- WHERE  xcav.account_number = l_get_rec.last_inst_cust_code; -- �ڋq�R�[�h
        /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
      EXCEPTION
        -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
        WHEN OTHERS THEN
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
          --lv_errmsg := xxccp_common_pkg.get_msg(
          --                   iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
          --                  ,iv_name         => cv_tkn_number_07               -- ���b�Z�[�W�R�[�h
          --                  ,iv_token_name1  => cv_tkn_proc_name               -- �g�[�N���R�[�h1
          --                  ,iv_token_value1 => cv_lst_bs_ccnt_cd              -- �g�[�N���l1���o������
          --                  ,iv_token_name2  => cv_tkn_object_cd               -- �g�[�N���R�[�h2
          --                  ,iv_token_value2 => l_get_rec.install_code         -- �g�[�N���l2�O���Q��(�����R�[�h)
          --                  ,iv_token_name3  => cv_tkn_account_id              -- �g�[�N���R�[�h3
          --                  ,iv_token_value3 => l_get_rec.install_account_id   -- �g�[�N���l3���L�҃A�J�E���gID
          --                  ,iv_token_name4  => cv_tkn_location_cd             -- �g�[�N���R�[�h4
          --                  ,iv_token_value4 => lv_last_month_base_cd          -- �g�[�N���l4���_(����)�R�[�h
          --                  ,iv_token_name5  => cv_tkn_customer_cd             -- �g�[�N���R�[�h5
          --                  ,iv_token_value5 => l_get_rec.last_inst_cust_code  -- �g�[�N���l5�挎���ڋq�R�[�h
          --                  ,iv_token_name6  => cv_tkn_err_msg                 -- �g�[�N���R�[�h6
          --                  ,iv_token_value6 => SQLERRM                        -- �g�[�N���l6
          --    );
          --lv_errbuf  := lv_errmsg;
          --RAISE select_error_expt;
          /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� START */
          --lv_last_month_base_cd := lv_sale_base_code;
          lv_last_month_base_cd := lt_past_sale_base_code;
          /* 2010.05.19 T.Maruyama E_�{�ғ�_02787�Ή� END */
          lv_lst_accnt_num      := lv_account_number;
          ov_retcode            := cv_status_warn;
          lv_errmsg             := xxccp_common_pkg.get_msg(
                                      iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                                     ,iv_name         => cv_tkn_number_19       -- ���b�Z�[�W�R�[�h
                                     ,iv_token_name1  => cv_tkn_param           -- �g�[�N���R�[�h1
                                     ,iv_token_value1 => cv_tkn_val3            -- �g�[�N���l1
                                     ,iv_token_name2  => cv_tkn_object_cd       -- �g�[�N���R�[�h2
                                     ,iv_token_value2 => l_get_rec.install_code -- �g�[�N���l2�O���Q��(�����R�[�h)
                                   );
          --
          fnd_file.put_line(
             which  => fnd_file.log
            ,buff   => lv_errmsg
          );
          --
          fnd_file.put_line(
             which  => fnd_file.output
            ,buff   => lv_errmsg
          );
          --
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
      END;
      /* 2009.08.06 K.Satomura 0000935�Ή� START */
      --END IF;
      /* 2009.08.06 K.Satomura 0000935�Ή� END */
    END IF;
--
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    l_get_rec.lookup_code         := lv_lookup_code;         -- �X�e�[�^�X
    l_get_rec.base_code           := lv_sale_base_code;      -- ���_(����)�R�[�h
    l_get_rec.account_number      := lv_account_number;      -- �ڋq�R�[�h
    l_get_rec.attribute2          := lv_attribute2;          -- �������[�J�[
    l_get_rec.attribute9          := lv_attribute9;          -- ����@�敪�P
    l_get_rec.attribute10         := lv_attribute10;         -- ����@�敪�Q
    l_get_rec.attribute11         := lv_attribute11;         -- ����@�敪�R
    l_get_rec.lease_type          := lv_lease_type;          -- �ă��[�X�敪
    l_get_rec.second_charge       := ln_second_charge;       -- ���[�X�� ���z���[�X��(�Ŕ�)
    l_get_rec.attribute8          := lv_attribute8;          -- �R������
    l_get_rec.actual_work_date    := ln_actual_work_date;    -- �ؗ��J�n��
    l_get_rec.last_month_base_cd  := lv_last_month_base_cd;  -- �挎�����_�R�[�h
    l_get_rec.last_inst_cust_code := lv_lst_accnt_num;       -- �挎���ڋq�R�[�h
--
    io_get_rec := l_get_rec;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN select_error_expt THEN
      /* 2009.04.09 K.Satomura T1_0441�Ή� START */
      gn_error_cnt  := gn_error_cnt + 1;
      /* 2009.04.09 K.Satomura T1_0441�Ή� END */
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
    WHEN status_warn_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      /* 2009.05.25 M.Maruyama T1_1154�Ή� END */
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_act_wk_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_act_wk_dt_cur;
      END IF;
      /* 2009.06.09 K.Hosoi T1_1154(�ďC��) �Ή� START */
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_csv_data;
--
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-7)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- �Y��}�X�^�f�[�^
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- �v���O������
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
    /* 2010.04.21 T.Maruyama E_�{�ғ�_02391�Ή� start*/
    cv_dummy_instance_num   CONSTANT VARCHAR2(6)    := '000000';
    /* 2010.04.21 T.Maruyama E_�{�ғ�_02391�Ή� end*/
    
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_data          VARCHAR2(5000);                -- �ҏW�f�[�^
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;                  -- �Y��}�X�^�f�[�^
    -- *** ���[�J����O ***
    file_put_line_expt             EXCEPTION;       -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    l_get_rec  := i_get_rec;               -- �Y��}�X�^�f�[�^���i�[���郌�R�[�h
--
    BEGIN
--
      --�f�[�^�쐬
      lv_data := cv_sep_wquot || l_get_rec.company_cd || cv_sep_wquot                         -- ��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.install_code || cv_sep_wquot               -- �O���Q��
        || cv_sep_com || NVL(l_get_rec.instance_type_code,0)                                  -- �C���X�^���X�^�C�v
        || cv_sep_com || l_get_rec.lookup_code                                                -- �X�e�[�^�X
        || cv_sep_com || TO_CHAR(l_get_rec.install_date,'YYYYMMDD')                           -- ������
        /* 2010.04.21 T.Maruyama E_�{�ғ�_02391�Ή� start*/
        --|| cv_sep_com || l_get_rec.instance_number                                            -- �C���X�^���X�ԍ�
        || cv_sep_com || cv_dummy_instance_num                                                -- �C���X�^���X�ԍ�
        /* 2010.04.21 T.Maruyama E_�{�ғ�_02391�Ή� start*/
        || cv_sep_com || TO_CHAR(l_get_rec.quantity)                                          -- ����
        || cv_sep_com || cv_sep_wquot || l_get_rec.accounting_class_code || cv_sep_wquot      -- ��v����
        || cv_sep_com || TO_CHAR(l_get_rec.active_start_date,'YYYYMMDD')                      -- �J�n��
        || cv_sep_com || cv_sep_wquot || TO_CHAR(l_get_rec.inventory_item_id) || cv_sep_wquot -- �i���R�[�h
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.install_party_id),0)                           -- �g�p�҃p�[�e�BID
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.install_account_id),0)                         -- �g�p�҃A�J�E���gID
        || cv_sep_com || cv_sep_wquot || l_get_rec.vendor_model || cv_sep_wquot               -- �@��(DFF1)
        || cv_sep_com || cv_sep_wquot || l_get_rec.vendor_number || cv_sep_wquot              -- �@��(DFF2)
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.first_install_date,'YY/MM/DD HH24:MI:SS'),'YYYYMMDD')
          -- ����ݒu��(DFF3)
        || cv_sep_com || cv_sep_wquot || l_get_rec.op_request_flag || cv_sep_wquot            -- ��ƈ˗����t���O(DFF4)
        || cv_sep_com || cv_sep_wquot || l_get_rec.ven_kyaku_last || cv_sep_wquot             -- �ŏI�ڋq�R�[�h
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd01,0)                                      -- ���ЃR�[�h�P
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu01,0)                                   -- ���Б䐔�P
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd02,0)                                      -- ���ЃR�[�h�Q
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu02,0)                                   -- ���Б䐔�Q
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd03,0)                                      -- ���ЃR�[�h�R
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu03,0)                                   -- ���Б䐔�R
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd04,0)                                      -- ���ЃR�[�h�S
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu04,0)                                   -- ���Б䐔�S
        || cv_sep_com || NVL(l_get_rec.ven_tasya_cd05,0)                                      -- ���ЃR�[�h�T
        || cv_sep_com || NVL(l_get_rec.ven_tasya_daisu05,0)                                   -- ���Б䐔�T
        || cv_sep_com || cv_sep_wquot || l_get_rec.ven_haiki_flg || cv_sep_wquot              -- �p���t���O
        /* 2009.05.18 K.Satomura T1_1049�Ή� START */
        --|| cv_sep_com || l_get_rec.haikikessai_dt                                             -- �p�����ٓ�
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.haikikessai_dt, 'YYYY/MM/DD'), 'YYYYMMDD')  -- �p�����ٓ�
        /* 2009.05.18 K.Satomura T1_1049�Ή� END */
        || cv_sep_com || cv_sep_wquot ||l_get_rec.ven_sisan_kbn || cv_sep_wquot               -- ���Y�敪
        /* 2009.07.21 K.Hosoi 0000475�Ή� START */
        --|| cv_sep_com || l_get_rec.ven_kobai_ymd                                              -- �w�����t
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.ven_kobai_ymd, 'YYYY/MM/DD'), 'YYYYMMDD')  -- �w�����t
        /* 2009.07.21 K.Hosoi 0000475�Ή� END */
        || cv_sep_com || NVL(l_get_rec.ven_kobai_kg,0)                                        -- �w�����z
        || cv_sep_com || NVL(l_get_rec.count_no,0)                                            -- �J�E���^�[No.
        || cv_sep_com || cv_sep_wquot || l_get_rec.chiku_cd || cv_sep_wquot                   -- �n��R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.sagyougaisya_cd || cv_sep_wquot            -- ��Ɖ�ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.jigyousyo_cd || cv_sep_wquot               -- ���Ə��R�[�h
        || cv_sep_com || NVL(l_get_rec.den_no,0)                                              -- �ŏI��Ɠ`�[No.
        || cv_sep_com || NVL(l_get_rec.job_kbn,0)                                             -- �ŏI��Ƌ敪
        || cv_sep_com || NVL(l_get_rec.sintyoku_kbn,0)                                        -- �ŏI��Ɛi��
        /* 2009.05.18 K.Satomura T1_1049�Ή� START */
        --|| cv_sep_com || l_get_rec.yotei_dt                                                   -- �ŏI��Ɗ����\���
        --|| cv_sep_com || l_get_rec.kanryo_dt                                                  -- �ŏI��Ɗ�����
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.yotei_dt, 'YYYY/MM/DD'), 'YYYYMMDD')       -- �ŏI��Ɗ����\���
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.kanryo_dt, 'YYYY/MM/DD'), 'YYYYMMDD')      -- �ŏI��Ɗ�����
        /* 2009.05.18 K.Satomura T1_1049�Ή� END */
        || cv_sep_com || NVL(l_get_rec.sagyo_level,0)                                         -- �ŏI�������e
        || cv_sep_com || NVL(l_get_rec.den_no2,0)                                             -- �ŏI�ݒu�`�[No.
        || cv_sep_com || NVL(l_get_rec.job_kbn2,0)                                            -- �ŏI�ݒu�敪
        || cv_sep_com || NVL(l_get_rec.sintyoku_kbn2,0)                                       -- �ŏI�ݒu�i��
        || cv_sep_com || NVL(l_get_rec.jotai_kbn1,0)                                          -- �@����1�i�ғ���ԁj
        || cv_sep_com || NVL(l_get_rec.jotai_kbn2,0)                                          -- �@����2�i��ԏڍׁj
        || cv_sep_com || NVL(l_get_rec.jotai_kbn3,0)                                          -- �@����3�i�p�����j
        || cv_sep_com || TO_CHAR(TO_DATE(l_get_rec.nyuko_dt,'YY/MM/DD HH24:MI:SS'),'YYYYMMDD')
          -- ���ɓ�
        || cv_sep_com || cv_sep_wquot || l_get_rec.hikisakigaisya_cd || cv_sep_wquot          -- ���g��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.hikisakijigyosyo_cd || cv_sep_wquot        -- ���g���Ə��R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tanto || cv_sep_wquot                -- �ݒu��S���Җ�
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel1 || cv_sep_wquot                 -- �ݒu��TEL(�A��)�P
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel2 || cv_sep_wquot                 -- �ݒu��TEL(�A��)�Q
        || cv_sep_com || cv_sep_wquot || l_get_rec.setti_tel3 || cv_sep_wquot                 -- �ݒu��TEL(�A��)�R
        || cv_sep_com || cv_sep_wquot || l_get_rec.tenhai_tanto || cv_sep_wquot               -- �]���p���Ǝ�
        || cv_sep_com || NVL(l_get_rec.tenhai_den_no,0)                                       -- �]���p���`�[��
        || cv_sep_com || cv_sep_wquot || l_get_rec.syoyu_cd || cv_sep_wquot                   -- ���L��
        || cv_sep_com || NVL(l_get_rec.tenhai_flg,0)                                          -- �]���p���󋵃t���O
        || cv_sep_com || NVL(l_get_rec.kanryo_kbn,0)                                          -- �]�������敪
        || cv_sep_com || NVL(l_get_rec.sakujo_flg,0)                                          -- �폜�t���O
        || cv_sep_com || cv_sep_wquot || l_get_rec.safty_level || cv_sep_wquot                -- ���S�ݒu�
        || cv_sep_com || cv_sep_wquot || l_get_rec.lease_kbn || cv_sep_wquot                  -- ���[�X�敪
        || cv_sep_com || cv_sep_wquot || l_get_rec.base_code || cv_sep_wquot                  -- ���_(����)�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.account_number || cv_sep_wquot             -- �ڋq�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute2 || cv_sep_wquot                 -- �������[�J�[
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute9 || cv_sep_wquot                 -- ����@�敪�P
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute10 || cv_sep_wquot                -- ����@�敪�Q
        || cv_sep_com || cv_sep_wquot || l_get_rec.attribute11 || cv_sep_wquot                -- ����@�敪�R
        || cv_sep_com || cv_sep_wquot || l_get_rec.lease_type || cv_sep_wquot                 -- �ă��[�X�敪
        || cv_sep_com || NVL(TO_CHAR(l_get_rec.second_charge),0)                              -- ���[�X�� ���z���[�X��(�Ŕ�)
        || cv_sep_com || NVL(l_get_rec.attribute8,0)                                          -- �R������
        || cv_sep_com || TO_CHAR(l_get_rec.actual_work_date)                                  -- �ؗ��J�n��
        || cv_sep_com || cv_sep_wquot || l_get_rec.last_inst_cust_code || cv_sep_wquot        -- �挎���ڋq�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.last_month_base_cd  || cv_sep_wquot        -- �挎�����_�i����j�R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.new_old_flag || cv_sep_wquot               -- �V�Ñ�t���O
        || cv_sep_com || l_get_rec.sysdate_now;                                               -- �A�g����
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                       --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_11                  --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_object_cd                  --�g�[�N���R�[�h1
                     ,iv_token_value1 => l_get_rec.install_code            --�g�[�N���l1�ڋq�R�[�h
                     ,iv_token_name2  => cv_tkn_err_msg                    --�g�[�N���R�[�h2
                     ,iv_token_value2 => SQLERRM                           --�g�[�N���l2
                    );
        lv_errbuf := lv_errmsg;
      RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-8)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_file_name      IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W              --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h                --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg10   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
             UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_13             --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                        ,iv_token_value1 => iv_file_dir                  --�g�[�N���l1
                        ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h1
                        ,iv_token_value2 => iv_file_name                 --�g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
---- *** ���[�J���萔 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
    /*20090709_hosoi_0000518 START*/
--    cv_install_cd_tkn       CONSTANT VARCHAR2(100)   := '�����}�X�^�r���[';
    cv_install_cd_tkn       CONSTANT VARCHAR2(100)   := '�����}�X�^';
    /*20090709_hosoi_0000518 END*/
    cv_fist_install_dt_tkn  CONSTANT VARCHAR2(100)   := '����ݒu��';
    cv_nyuko_date_tkn       CONSTANT VARCHAR2(100)   := '���ɓ�';
    cv_lst_yr_mnth_tkn      CONSTANT VARCHAR2(100)   := '�挎���N��';
    /* 2009.07.21 K.Hosoi 0000475�Ή� START */
    cv_haikikessai_dt_tkn   CONSTANT VARCHAR2(100)   := '�p�����ϓ�';
    cv_ven_kobai_ymd_tkn    CONSTANT VARCHAR2(100)   := '�w�����t';
    cv_yotei_dt_tkn         CONSTANT VARCHAR2(100)   := '�ŏI��Ɗ����\���';
    cv_kanryo_dt_tkn        CONSTANT VARCHAR2(100)   := '�ŏI��Ɗ�����';
    cv_msg_bkn_cd           CONSTANT VARCHAR2(100)   := '�A�����R�[�h( ';
    cv_prnthss              CONSTANT VARCHAR2(100)   := ' )';
    /* 2009.07.21 K.Hosoi 0000475�Ή� END */
    cn_lst_yr_mnth_num      CONSTANT NUMBER(1)       := 6;
    /*20090709_hosoi_0000518 START*/
    cv_count_no             CONSTANT VARCHAR2(100)   := 'COUNT_NO';
    cv_chiku_cd             CONSTANT VARCHAR2(100)   := 'CHIKU_CD';
    cv_sagyougaisya_cd      CONSTANT VARCHAR2(100)   := 'SAGYOUGAISYA_CD';
    cv_jigyousyo_cd         CONSTANT VARCHAR2(100)   := 'JIGYOUSYO_CD';
    cv_den_no               CONSTANT VARCHAR2(100)   := 'DEN_NO';
    cv_job_kbn              CONSTANT VARCHAR2(100)   := 'JOB_KBN';
    cv_sintyoku_kbn         CONSTANT VARCHAR2(100)   := 'SINTYOKU_KBN';
    cv_yotei_dt             CONSTANT VARCHAR2(100)   := 'YOTEI_DT';
    cv_kanryo_dt            CONSTANT VARCHAR2(100)   := 'KANRYO_DT';
    cv_sagyo_level          CONSTANT VARCHAR2(100)   := 'SAGYO_LEVEL';
    cv_den_no2              CONSTANT VARCHAR2(100)   := 'DEN_NO2';
    cv_job_kbn2             CONSTANT VARCHAR2(100)   := 'JOB_KBN2';
    cv_sintyoku_kbn2        CONSTANT VARCHAR2(100)   := 'SINTYOKU_KBN2';
    cv_jotai_kbn1           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN1';
    cv_jotai_kbn2           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN2';
    cv_jotai_kbn3           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN3';
    cv_nyuko_dt             CONSTANT VARCHAR2(100)   := 'NYUKO_DT';
    cv_hikisakigaisya_cd    CONSTANT VARCHAR2(100)   := 'HIKISAKIGAISYA_CD';
    cv_hikisakijigyosyo_cd  CONSTANT VARCHAR2(100)   := 'HIKISAKIJIGYOSYO_CD';
    cv_setti_tanto          CONSTANT VARCHAR2(100)   := 'SETTI_TANTO';
    cv_setti_tel1           CONSTANT VARCHAR2(100)   := 'SETTI_TEL1';
    cv_setti_tel2           CONSTANT VARCHAR2(100)   := 'SETTI_TEL2';
    cv_setti_tel3           CONSTANT VARCHAR2(100)   := 'SETTI_TEL3';
    cv_haikikessai_dt       CONSTANT VARCHAR2(100)   := 'HAIKIKESSAI_DT';
    cv_tenhai_tanto         CONSTANT VARCHAR2(100)   := 'TENHAI_TANTO';
    cv_tenhai_den_no        CONSTANT VARCHAR2(100)   := 'TENHAI_DEN_NO';
    cv_syoyu_cd             CONSTANT VARCHAR2(100)   := 'SYOYU_CD';
    cv_tenhai_flg           CONSTANT VARCHAR2(100)   := 'TENHAI_FLG';
    cv_kanryo_kbn           CONSTANT VARCHAR2(100)   := 'KANRYO_KBN';
    cv_sakujo_flg           CONSTANT VARCHAR2(100)   := 'SAKUJO_FLG';
    cv_ven_kyaku_last       CONSTANT VARCHAR2(100)   := 'VEN_KYAKU_LAST';
    cv_ven_tasya_cd01       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD01';
    cv_ven_tasya_daisu01    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU01';
    cv_ven_tasya_cd02       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD02';
    cv_ven_tasya_daisu02    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU02';
    cv_ven_tasya_cd03       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD03';
    cv_ven_tasya_daisu03    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU03';
    cv_ven_tasya_cd04       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD04';
    cv_ven_tasya_daisu04    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU04';
    cv_ven_tasya_cd05       CONSTANT VARCHAR2(100)   := 'VEN_TASYA_CD05';
    cv_ven_tasya_daisu05    CONSTANT VARCHAR2(100)   := 'VEN_TASYA_DAISU05';
    cv_ven_haiki_flg        CONSTANT VARCHAR2(100)   := 'VEN_HAIKI_FLG';
    cv_ven_sisan_kbn        CONSTANT VARCHAR2(100)   := 'VEN_SISAN_KBN';
    cv_ven_kobai_ymd        CONSTANT VARCHAR2(100)   := 'VEN_KOBAI_YMD';
    cv_ven_kobai_kg         CONSTANT VARCHAR2(100)   := 'VEN_KOBAI_KG';
    cv_safty_level          CONSTANT VARCHAR2(100)   := 'SAFTY_LEVEL';
    cv_lease_kbn            CONSTANT VARCHAR2(100)   := 'LEASE_KBN';
    cv_last_inst_cust_code  CONSTANT VARCHAR2(100)   := 'LAST_INST_CUST_CODE';
    cv_last_jotai_kbn       CONSTANT VARCHAR2(100)   := 'LAST_JOTAI_KBN';
    cv_last_year_month      CONSTANT VARCHAR2(100)   := 'LAST_YEAR_MONTH';
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
    cv_yymmddhhmiss         CONSTANT VARCHAR2(100)   := 'YY/MM/DD HH24:MI:SS';
    cv_yymmdd               CONSTANT VARCHAR2(100)   := 'YY/MM/DD';
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
--
    /*20090709_hosoi_0000518 END*/
    -- *** ���[�J���ϐ� ***
    lv_sub_retcode         VARCHAR2(1);                -- �T�u���C���p���^�[���E�R�[�h
    lv_sub_msg             VARCHAR2(5000);             -- �x���p���b�Z�[�W
    lv_sub_buf             VARCHAR2(5000);             -- �x���p�G���[�E���b�Z�[�W
    lv_sysdate             VARCHAR2(100);              -- �V�X�e�����t
    ld_bsnss_mnth          DATE;                       -- �Ɩ���
    lv_file_dir            VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name           VARCHAR2(2000);             -- CSV�t�@�C����
    lv_company_cd          VARCHAR2(2000);             -- ��ЃR�[�h(�Œ�l001)
    lb_check_date          BOOLEAN;                    -- ���t�̏����ł��邩���m�F
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg          VARCHAR2(2000);
    /*20090709_hosoi_0000518 START*/
    lv_attribute_level     VARCHAR2(15);               -- IB�g�������e���v���[�g�A�N�Z�X���x���i�[�p
    ld_date                DATE;                       -- TRUNC(SYSDATE)�i�[�p
    /*20090709_hosoi_0000518 END*/
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
    lv_warn_flag           VARCHAR2(1) := 'N';
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
    lv_token_msg           VARCHAR2(1000);             -- �����E�����`�F�b�N�G���[���ږ��i�[�p
    lv_msg2                VARCHAR2(2000);             -- �����E�����`�F�b�N�G���[MSG�[�p
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
    -- *** ���[�J���E�J�[�\�� ***
    /*20090709_hosoi_0000518 START*/
--    CURSOR xibv_data_cur
--    IS
--      SELECT xibv.install_code           install_code             -- �O���Q��
--            ,xibv.instance_type_code     instance_type_code       -- �C���X�^���X�^�C�v
--            ,xibv.instance_status_id     instance_status_id       -- �X�e�[�^�XID
--            ,xibv.install_date           install_date             -- ������
--            ,xibv.instance_number        instance_number          -- �C���X�^���X�ԍ�
--            ,xibv.quantity               quantity                 -- ����
--            ,xibv.accounting_class_code  accounting_class_code    -- ��v����
--            ,xibv.active_start_date      active_start_date        -- �J�n��
--            ,xibv.inventory_item_id      inventory_item_id        -- �i���R�[�h
--            ,xibv.install_party_id       install_party_id         -- �g�p�҃p�[�e�BID
--            ,xibv.install_account_id     install_account_id       -- �g�p�҃A�J�E���gID
--            ,xibv.vendor_model           vendor_model             -- �@��(DFF1)
--            ,xibv.vendor_number          vendor_number            -- �@��(DFF2)
--            ,xibv.first_install_date     first_install_date       -- ����ݒu��(DFF3)
--            ,xibv.op_request_flag        op_request_flag          -- ��ƈ˗����t���O(DFF4)
--            ,xibv.ven_kyaku_last         ven_kyaku_last           -- �ŏI�ڋq�R�[�h
--            ,xibv.ven_tasya_cd01         ven_tasya_cd01           -- ���ЃR�[�h�P
--            ,xibv.ven_tasya_daisu01      ven_tasya_daisu01        -- ���Б䐔�P
--            ,xibv.ven_tasya_cd02         ven_tasya_cd02           -- ���ЃR�[�h�Q
--            ,xibv.ven_tasya_daisu02      ven_tasya_daisu02        -- ���Б䐔�Q
--            ,xibv.ven_tasya_cd03         ven_tasya_cd03           -- ���ЃR�[�h�R
--            ,xibv.ven_tasya_daisu03      ven_tasya_daisu03        -- ���Б䐔�R
--            ,xibv.ven_tasya_cd04         ven_tasya_cd04           -- ���ЃR�[�h�S
--            ,xibv.ven_tasya_daisu04      ven_tasya_daisu04        -- ���Б䐔�S
--            ,xibv.ven_tasya_cd05         ven_tasya_cd05           -- ���ЃR�[�h�T
--            ,xibv.ven_tasya_daisu05      ven_tasya_daisu05        -- ���Б䐔�T
--            ,xibv.ven_haiki_flg          ven_haiki_flg            -- �p���t���O
--            ,xibv.haikikessai_dt         haikikessai_dt           -- �p�����ٓ�
--            ,xibv.ven_sisan_kbn          ven_sisan_kbn            -- ���Y�敪
--            ,xibv.ven_kobai_ymd          ven_kobai_ymd            -- �w�����t
--            ,xibv.ven_kobai_kg           ven_kobai_kg             -- �w�����z
--            ,xibv.count_no               count_no                 -- �J�E���^�[No.
--            ,xibv.chiku_cd               chiku_cd                 -- �n��R�[�h
--            ,xibv.sagyougaisya_cd        sagyougaisya_cd          -- ��Ɖ�ЃR�[�h
--            ,xibv.jigyousyo_cd           jigyousyo_cd             -- ���Ə��R�[�h
--            ,xibv.den_no                 den_no                   -- �ŏI��Ɠ`�[No.
--            ,xibv.job_kbn                job_kbn                  -- �ŏI��Ƌ敪
--            ,xibv.sintyoku_kbn           sintyoku_kbn             -- �ŏI��Ɛi��
--            ,xibv.yotei_dt               yotei_dt                 -- �ŏI��Ɗ����\���
--            ,xibv.kanryo_dt              kanryo_dt                -- �ŏI��Ɗ�����
--            ,xibv.sagyo_level            sagyo_level              -- �ŏI�������e
--            ,xibv.den_no2                den_no2                  -- �ŏI�ݒu�`�[No.
--            ,xibv.job_kbn2               job_kbn2                 -- �ŏI�ݒu�敪
--            ,xibv.sintyoku_kbn2          sintyoku_kbn2            -- �ŏI�ݒu�i��
--            ,xibv.jotai_kbn1             jotai_kbn1               -- �@����1�i�ғ���ԁj
--            ,xibv.jotai_kbn2             jotai_kbn2               -- �@����2�i��ԏڍׁj
--            ,xibv.jotai_kbn3             jotai_kbn3               -- �@����3�i�p�����j
--            ,xibv.nyuko_dt               nyuko_dt                 -- ���ɓ�
--            ,xibv.hikisakigaisya_cd      hikisakigaisya_cd        -- ���g��ЃR�[�h
--            ,xibv.hikisakijigyosyo_cd    hikisakijigyosyo_cd      -- ���g���Ə��R�[�h
--            ,xibv.setti_tanto            setti_tanto              -- �ݒu��S���Җ�
--            ,xibv.setti_tel1             setti_tel1               -- �ݒu��TEL(�A��)�P
--            ,xibv.setti_tel2             setti_tel2               -- �ݒu��TEL(�A��)�Q
--            ,xibv.setti_tel3             setti_tel3               -- �ݒu��TEL(�A��)�R
--            ,xibv.tenhai_tanto           tenhai_tanto             -- �]���p���Ǝ�
--            ,xibv.tenhai_den_no          tenhai_den_no            -- �]���p���`�[��
--            ,xibv.syoyu_cd               syoyu_cd                 -- ���L��
--            ,xibv.tenhai_flg             tenhai_flg               -- �]���p���󋵃t���O
--            ,xibv.kanryo_kbn             kanryo_kbn               -- �]�������敪
--            ,xibv.sakujo_flg             sakujo_flg               -- �폜�t���O
--            ,xibv.safty_level            safty_level              -- ���S�ݒu�
--            ,xibv.lease_kbn              lease_kbn                -- ���[�X�敪
--            ,xibv.new_old_flag           new_old_flag             -- �V�Ñ�t���O
--            ,xibv.last_inst_cust_code    last_inst_cust_code      -- �挎���ݒu��ڋq�R�[�h
--            ,xibv.last_jotai_kbn         last_jotai_kbn           -- �挎���@����
--            ,xibv.last_year_month        last_year_month          -- �挎���N��
--      /*20090415_maruyama_T1_0550 START*/
--      FROM   xxcso_install_base_v xibv;
----      where instance_id IN(104039,90043,90045);                           -- �����}�X�^�r���[
--      /*20090415_maruyama_T1_0550 END*/
    CURSOR xibv_data_cur(
              iv_attribute_level IN VARCHAR2      -- IB�g�������e���v���[�g�A�N�Z�X���x��
             ,id_date            IN DATE          -- SYSDATE(yyyymmdd)
           )
    IS
      SELECT cii.EXTERNAL_REFERENCE           install_code             -- �O���Q��
            ,cii.INSTANCE_TYPE_CODE           instance_type_code       -- �C���X�^���X�^�C�v
            ,cii.INSTANCE_STATUS_ID           instance_status_id       -- �X�e�[�^�XID
            ,cii.INSTALL_DATE                 install_date             -- ������
            ,cii.INSTANCE_NUMBER              instance_number          -- �C���X�^���X�ԍ�
            ,cii.QUANTITY                     quantity                 -- ����
            ,cii.ACCOUNTING_CLASS_CODE        accounting_class_code    -- ��v����
            ,cii.ACTIVE_START_DATE            active_start_date        -- �J�n��
            ,cii.INVENTORY_ITEM_ID            inventory_item_id        -- �i���R�[�h
            ,cii.OWNER_PARTY_ID               install_party_id         -- �g�p�҃p�[�e�BID
            ,cii.OWNER_PARTY_ACCOUNT_ID       install_account_id       -- �g�p�҃A�J�E���gID
            ,cii.ATTRIBUTE1                   vendor_model             -- �@��(DFF1)
            ,cii.ATTRIBUTE2                   vendor_number            -- �@��(DFF2)
            ,cii.ATTRIBUTE3                   first_install_date       -- ����ݒu��(DFF3)
            ,cii.ATTRIBUTE4                   op_request_flag          -- ��ƈ˗����t���O(DFF4)
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kyaku_last
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kyaku_last           -- �ŏI�ڋq�R�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd01
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd01           -- ���ЃR�[�h�P
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu01
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu01        -- ���Б䐔�P
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd02
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd02           -- ���ЃR�[�h�Q
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu02
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu02        -- ���Б䐔�Q
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd03
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd03           -- ���ЃR�[�h�R
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu03
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu03        -- ���Б䐔�R
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd04
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd04           -- ���ЃR�[�h�S
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu04
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu04        -- ���Б䐔�S
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_cd05
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_cd05           -- ���ЃR�[�h�T
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_tasya_daisu05
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_tasya_daisu05        -- ���Б䐔�T
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_haiki_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_haiki_flg            -- �p���t���O
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_haikikessai_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                haikikessai_dt           -- �p�����ٓ�
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_sisan_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_sisan_kbn            -- ���Y�敪
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kobai_ymd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kobai_ymd            -- �w�����t
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_ven_kobai_kg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                ven_kobai_kg             -- �w�����z
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_count_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                count_no                 -- �J�E���^�[No.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_chiku_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                chiku_cd                 -- �n��R�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sagyougaisya_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sagyougaisya_cd          -- ��Ɖ�ЃR�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jigyousyo_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jigyousyo_cd             -- ���Ə��R�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_den_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                den_no                   -- �ŏI��Ɠ`�[No.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_job_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                job_kbn                  -- �ŏI��Ƌ敪
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sintyoku_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sintyoku_kbn             -- �ŏI��Ɛi��
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_yotei_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                yotei_dt                 -- �ŏI��Ɗ����\���
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_kanryo_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                kanryo_dt                -- �ŏI��Ɗ�����
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sagyo_level
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sagyo_level              -- �ŏI�������e
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_den_no2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                den_no2                  -- �ŏI�ݒu�`�[No.
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_job_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                job_kbn2                 -- �ŏI�ݒu�敪
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sintyoku_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sintyoku_kbn2            -- �ŏI�ݒu�i��
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn1
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn1               -- �@����1�i�ғ���ԁj
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn2               -- �@����2�i��ԏڍׁj
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_jotai_kbn3
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                jotai_kbn3               -- �@����3�i�p�����j
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_nyuko_dt
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                nyuko_dt                 -- ���ɓ�
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_hikisakigaisya_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                hikisakigaisya_cd        -- ���g��ЃR�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_hikisakijigyosyo_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                hikisakijigyosyo_cd      -- ���g���Ə��R�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tanto
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tanto              -- �ݒu��S���Җ�
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel1
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel1               -- �ݒu��TEL(�A��)�P
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel2
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel2               -- �ݒu��TEL(�A��)�Q
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_setti_tel3
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                setti_tel3               -- �ݒu��TEL(�A��)�R
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_tanto
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_tanto             -- �]���p���Ǝ�
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_den_no
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_den_no            -- �]���p���`�[��
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_syoyu_cd
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                syoyu_cd                 -- ���L��
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_tenhai_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                tenhai_flg               -- �]���p���󋵃t���O
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_kanryo_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                kanryo_kbn               -- �]�������敪
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_sakujo_flg
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                sakujo_flg               -- �폜�t���O
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_safty_level
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                safty_level              -- ���S�ݒu�
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_lease_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                lease_kbn                -- ���[�X�敪
            ,cii.ATTRIBUTE5                   new_old_flag             -- �V�Ñ�t���O
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_inst_cust_code
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_inst_cust_code      -- �挎���ݒu��ڋq�R�[�h
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_jotai_kbn
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_jotai_kbn           -- �挎���@����
            ,( SELECT  civ.attribute_value       attribute_value
               FROM    csi_i_extended_attribs    ciea  -- �ݒu�@��g��������`���e�[�u��
                     , csi_iea_values            civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE   ciea.attribute_level = iv_attribute_level
                 AND   ciea.attribute_code  = cv_last_year_month
                 AND   civ.instance_id      = cii.instance_id
                 AND   ciea.attribute_id    = civ.attribute_id
                 AND   NVL( ciea.active_start_date, id_date ) <= id_date
                 AND   NVL( ciea.active_end_date, id_date )   >= id_date
             )                                last_year_month          -- �挎���N��
      FROM   csi_item_instances cii;
    /*20090709_hosoi_0000518 END*/
    -- *** ���[�J���E���R�[�h ***
    l_xibv_data_rec        xibv_data_cur%ROWTYPE;
    l_get_rec              g_value_rtype;                        -- �Y��}�X�^�f�[�^
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
    no_data_expt      EXCEPTION;
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
    validation_expt   EXCEPTION;                                 -- �����E�����`�F�b�N��O
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
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
-- 2011/10/14 v1.19 T.Yoshimto Add Start E_�{�ғ�_05929(�R�����g�A�E�g����)
    gn_skip_cnt   :=0;
-- 2011/10/14 v1.19 T.Yoshimto Add End E_�{�ғ�_05929
--
    -- ================================
    -- A-1.��������
    -- ================================
    init(
      ov_sysdate          => lv_sysdate,       -- �V�X�e�����t
      od_bsnss_mnth       => ld_bsnss_mnth,    -- �Ɩ���
      ov_errbuf           => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.�v���t�@�C���l���擾
    -- =================================================
    get_profile_info(
       ov_file_dir    => lv_file_dir    -- CSV�t�@�C���o�͐�
      ,ov_file_name   => lv_file_name   -- CSV�t�@�C����
      ,ov_company_cd  => lv_company_cd  -- ��ЃR�[�h(�Œ�l001)
      /*20090709_hosoi_0000518 START*/
      ,ov_attribute_level => lv_attribute_level  -- IB�g�������e���v���[�g�A�N�Z�X���x��
      /*20090709_hosoi_0000518 END*/
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    gv_company_cd     := lv_company_cd;  -- ��ЃR�[�h(�Œ�l001)
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.CSV�t�@�C���I�[�v��
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.�����f�[�^���o����
    -- =================================================
--
    /*20090709_hosoi_0000518 START*/
    -- �V�X�e�����t�擾�i�����b�͐؂�̂āj
    ld_date := TRUNC(SYSDATE);
    /*20090709_hosoi_0000518 END*/
    /*20090709_hosoi_0000518 START*/
    -- �J�[�\���I�[�v��
--    OPEN xibv_data_cur;
    OPEN xibv_data_cur(
            iv_attribute_level =>  lv_attribute_level  -- IB�g�������e���v���[�g�A�N�Z�X���x��
           ,id_date            =>  ld_date             -- SYSDATE(yyyymmdd)
         );
    /*20090709_hosoi_0000518 END*/
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_data_loop>>
    LOOP
--
      BEGIN
        FETCH xibv_data_cur INTO l_xibv_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- �Y��}�X�^�f�[�^���o�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_05          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name          -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_install_cd_tkn         -- �g�[�N���l1
                              ,iv_token_name2  => cv_tkn_err_msg2           -- �g�[�N���R�[�h2
                              ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
              );
          lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      BEGIN
        -- �f�[�^������
        lv_sub_msg := NULL;
        lv_sub_buf := NULL;
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
        lv_token_msg := NULL;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
--
        -- ���R�[�h�ϐ�������
        l_get_rec         := NULL;    -- �Y��}�X�^�f�[�^�i�[
        -- �����Ώی����i�[
        gn_target_cnt := xibv_data_cur%ROWCOUNT;
        -- �Ώی�����O���̏ꍇ
        EXIT WHEN xibv_data_cur%NOTFOUND
        OR  xibv_data_cur%ROWCOUNT = 0;
--
        -- �擾�f�[�^���i�[
        l_get_rec.install_code           := l_xibv_data_rec.install_code;           -- �O���Q��
        l_get_rec.instance_type_code     := l_xibv_data_rec.instance_type_code;     -- �C���X�^���X�^�C�v
        l_get_rec.instance_status_id     := l_xibv_data_rec.instance_status_id;     -- �X�e�[�^�XID
        l_get_rec.install_date           := l_xibv_data_rec.install_date;           -- ������
        l_get_rec.instance_number        := l_xibv_data_rec.instance_number;        -- �C���X�^���X�ԍ�
        l_get_rec.quantity               := l_xibv_data_rec.quantity;               -- ����
        l_get_rec.accounting_class_code  := l_xibv_data_rec.accounting_class_code;  -- ��v����
        l_get_rec.active_start_date      := l_xibv_data_rec.active_start_date;      -- �J�n��
        l_get_rec.inventory_item_id      := l_xibv_data_rec.inventory_item_id;      -- �i���R�[�h
        l_get_rec.install_party_id       := l_xibv_data_rec.install_party_id;       -- �g�p�҃p�[�e�BID
        l_get_rec.install_account_id     := l_xibv_data_rec.install_account_id;     -- �g�p�҃A�J�E���gID
        l_get_rec.vendor_model           := l_xibv_data_rec.vendor_model;           -- �@��(DFF1)
        l_get_rec.vendor_number          := l_xibv_data_rec.vendor_number;          -- �@��(DFF2)
        l_get_rec.first_install_date     := l_xibv_data_rec.first_install_date;     -- ����ݒu��(DFF3)
        l_get_rec.op_request_flag        := l_xibv_data_rec.op_request_flag;        -- ��ƈ˗����t���O(DFF4)
        l_get_rec.ven_kyaku_last         := l_xibv_data_rec.ven_kyaku_last;         -- �ŏI�ڋq�R�[�h
        l_get_rec.ven_tasya_cd01         := l_xibv_data_rec.ven_tasya_cd01;         -- ���ЃR�[�h�P
        l_get_rec.ven_tasya_daisu01      := l_xibv_data_rec.ven_tasya_daisu01;      -- ���Б䐔�P
        l_get_rec.ven_tasya_cd02         := l_xibv_data_rec.ven_tasya_cd02;         -- ���ЃR�[�h�Q
        l_get_rec.ven_tasya_daisu02      := l_xibv_data_rec.ven_tasya_daisu02;      -- ���Б䐔�Q
        l_get_rec.ven_tasya_cd03         := l_xibv_data_rec.ven_tasya_cd03;         -- ���ЃR�[�h�R
        l_get_rec.ven_tasya_daisu03      := l_xibv_data_rec.ven_tasya_daisu03;      -- ���Б䐔�R
        l_get_rec.ven_tasya_cd04         := l_xibv_data_rec.ven_tasya_cd04;         -- ���ЃR�[�h�S
        l_get_rec.ven_tasya_daisu04      := l_xibv_data_rec.ven_tasya_daisu04;      -- ���Б䐔�S
        l_get_rec.ven_tasya_cd05         := l_xibv_data_rec.ven_tasya_cd05;         -- ���ЃR�[�h�T
        l_get_rec.ven_tasya_daisu05      := l_xibv_data_rec.ven_tasya_daisu05;      -- ���Б䐔�T
        l_get_rec.ven_haiki_flg          := l_xibv_data_rec.ven_haiki_flg;          -- �p���t���O
        l_get_rec.haikikessai_dt         := l_xibv_data_rec.haikikessai_dt;         -- �p�����ٓ�
        l_get_rec.ven_sisan_kbn          := l_xibv_data_rec.ven_sisan_kbn;          -- ���Y�敪
        l_get_rec.ven_kobai_ymd          := l_xibv_data_rec.ven_kobai_ymd;          -- �w�����t
        l_get_rec.ven_kobai_kg           := l_xibv_data_rec.ven_kobai_kg;           -- �w�����z
        l_get_rec.count_no               := l_xibv_data_rec.count_no;               -- �J�E���^�[No.
        l_get_rec.chiku_cd               := l_xibv_data_rec.chiku_cd;               -- �n��R�[�h
        l_get_rec.sagyougaisya_cd        := l_xibv_data_rec.sagyougaisya_cd;        -- ��Ɖ�ЃR�[�h
        l_get_rec.jigyousyo_cd           := l_xibv_data_rec.jigyousyo_cd;           -- ���Ə��R�[�h
        l_get_rec.den_no                 := l_xibv_data_rec.den_no;                 -- �ŏI��Ɠ`�[No.
        l_get_rec.job_kbn                := l_xibv_data_rec.job_kbn;                -- �ŏI��Ƌ敪
        l_get_rec.sintyoku_kbn           := l_xibv_data_rec.sintyoku_kbn;           -- �ŏI��Ɛi��
        l_get_rec.yotei_dt               := l_xibv_data_rec.yotei_dt;               -- �ŏI��Ɗ����\���
        l_get_rec.kanryo_dt              := l_xibv_data_rec.kanryo_dt;              -- �ŏI��Ɗ�����
        l_get_rec.sagyo_level            := l_xibv_data_rec.sagyo_level;            -- �ŏI�������e
        l_get_rec.den_no2                := l_xibv_data_rec.den_no2;                -- �ŏI�ݒu�`�[No.
        l_get_rec.job_kbn2               := l_xibv_data_rec.job_kbn2;               -- �ŏI�ݒu�敪
        l_get_rec.sintyoku_kbn2          := l_xibv_data_rec.sintyoku_kbn2;          -- �ŏI�ݒu�i��
        l_get_rec.jotai_kbn1             := l_xibv_data_rec.jotai_kbn1;             -- �@����1�i�ғ���ԁj
        l_get_rec.jotai_kbn2             := l_xibv_data_rec.jotai_kbn2;             -- �@����2�i��ԏڍׁj
        l_get_rec.jotai_kbn3             := l_xibv_data_rec.jotai_kbn3;             -- �@����3�i�p�����j
        l_get_rec.nyuko_dt               := l_xibv_data_rec.nyuko_dt;               -- ���ɓ�
        l_get_rec.hikisakigaisya_cd      := l_xibv_data_rec.hikisakigaisya_cd;      -- ���g��ЃR�[�h
        l_get_rec.hikisakijigyosyo_cd    := l_xibv_data_rec.hikisakijigyosyo_cd;    -- ���g���Ə��R�[�h
        l_get_rec.setti_tanto            := l_xibv_data_rec.setti_tanto;            -- �ݒu��S���Җ�
        l_get_rec.setti_tel1             := l_xibv_data_rec.setti_tel1;             -- �ݒu��TEL(�A��)�P
        l_get_rec.setti_tel2             := l_xibv_data_rec.setti_tel2;             -- �ݒu��TEL(�A��)�Q
        l_get_rec.setti_tel3             := l_xibv_data_rec.setti_tel3;             -- �ݒu��TEL(�A��)�R
        l_get_rec.tenhai_tanto           := l_xibv_data_rec.tenhai_tanto;           -- �]���p���Ǝ�
        l_get_rec.tenhai_den_no          := l_xibv_data_rec.tenhai_den_no;          -- �]���p���`�[��
        l_get_rec.syoyu_cd               := l_xibv_data_rec.syoyu_cd;               -- ���L��
        l_get_rec.tenhai_flg             := l_xibv_data_rec.tenhai_flg;             -- �]���p���󋵃t���O
        l_get_rec.kanryo_kbn             := l_xibv_data_rec.kanryo_kbn;             -- �]�������敪
        l_get_rec.sakujo_flg             := l_xibv_data_rec.sakujo_flg;             -- �폜�t���O
        l_get_rec.safty_level            := l_xibv_data_rec.safty_level;            -- ���S�ݒu�
        l_get_rec.lease_kbn              := l_xibv_data_rec.lease_kbn;              -- ���[�X�敪
        l_get_rec.sysdate_now            := lv_sysdate;                             -- �A�g����
        l_get_rec.company_cd             := gv_company_cd;                          -- ��ЃR�[�h(�Œ�l001)
        l_get_rec.new_old_flag           := l_xibv_data_rec.new_old_flag;           -- �V�Ñ�t���O
        l_get_rec.last_inst_cust_code    := l_xibv_data_rec.last_inst_cust_code;    -- �挎���ڋq�R�[�h
        l_get_rec.last_jotai_kbn         := l_xibv_data_rec.last_jotai_kbn;         -- �挎���@����
        l_get_rec.last_year_month        := l_xibv_data_rec.last_year_month;        -- �挎���N��
--
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
        -- =================================================
        -- A-5.�����E�����`�F�b�N����
        -- =================================================
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
        -- ���t�����`�F�b�N
        -- ����ݒu��(DFF3)
        lb_check_date := xxcso_util_common_pkg.check_date(
                                      iv_date         => l_get_rec.first_install_date
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
--                                    ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
                                    ,iv_date_format  => cv_yymmddhhmiss
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
        );
        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
        IF (lb_check_date = cb_false) THEN
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
          --lv_sub_msg := xxccp_common_pkg.get_msg(
          --                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
          --                      ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
          --                      ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
          --                      ,iv_token_value1 => cv_fist_install_dt_tkn        -- �g�[�N���l1���ږ�
          --                      ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
          --                      ,iv_token_value2 => l_get_rec.first_install_date  -- �g�[�N���l2�l
          --);
          --lv_sub_buf  := lv_sub_msg;
          --RAISE select_error_expt;
          l_get_rec.first_install_date := NULL;
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
        END IF;
-- 2011/10/14 v1.19 T.Yoshimoto Del Start E_�{�ғ�_05929
--        -- ���ɓ�
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.nyuko_dt
--                                     ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
--          --                      ,iv_token_value1 => cv_nyuko_date_tkn             -- �g�[�N���l1���ږ�
--          --                      ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.nyuko_dt            -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.nyuko_dt := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        -- �挎���N��
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.last_year_month
--                                     ,iv_date_format  => 'YY/MM'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
--          --                      ,iv_token_value1 => cv_lst_yr_mnth_tkn            -- �g�[�N���l1���ږ�
--          --                      ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.last_year_month     -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.last_year_month := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        /* 2009.05.18 K.Satomura T1_1049�Ή� START */
--        -- �p�����ٓ�
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.haikikessai_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15         -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� START */
--        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn       -- �g�[�N���l1���ږ�
--          --                      ,iv_token_value1 => cv_haikikessai_dt_tkn    -- �g�[�N���l1���ږ�
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� END */
--          --                      ,iv_token_name2  => cv_tkn_value             -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.haikikessai_dt -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.haikikessai_dt := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        /* 2009.07.21 K.Hosoi 0000475�Ή� START */
--        -- �w�����t
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.ven_kobai_ymd
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15         -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
--          --                      ,iv_token_value1 => cv_ven_kobai_ymd_tkn     -- �g�[�N���l1���ږ�
--          --                      ,iv_token_name2  => cv_tkn_value             -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.ven_kobai_ymd -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.ven_kobai_ymd := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        /* 2009.07.21 K.Hosoi 0000475�Ή� END */
--        -- �ŏI��Ɗ����\���
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.yotei_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15   -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item        -- �g�[�N���R�[�h1
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� START */
----        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn -- �g�[�N���l1���ږ�
--          --                      ,iv_token_value1 => cv_yotei_dt_tkn -- �g�[�N���l1���ږ�
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� END */
--          --                      ,iv_token_name2  => cv_tkn_value       -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.yotei_dt -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.yotei_dt := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        --
--        -- �ŏI��Ɗ�����
--        lb_check_date := xxcso_util_common_pkg.check_date(
--                                      iv_date         => l_get_rec.kanryo_dt
--                                     ,iv_date_format  => 'YYYY/MM/DD'
--        );
--        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
--        IF (lb_check_date = cb_false) THEN
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 START */
--          --lv_sub_msg := xxccp_common_pkg.get_msg(
--          --                       iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
--          --                      ,iv_name         => cv_tkn_number_15    -- ���b�Z�[�W�R�[�h
--          --                      ,iv_token_name1  => cv_tkn_item         -- �g�[�N���R�[�h1
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� START */
----        --                        ,iv_token_value1 => cv_lst_yr_mnth_tkn  -- �g�[�N���l1���ږ�
--          --                      ,iv_token_value1 => cv_kanryo_dt_tkn    -- �g�[�N���l1���ږ�
--          --                      /* 2009.07.21 K.Hosoi 0000475�Ή� START */
--          --                      ,iv_token_name2  => cv_tkn_value        -- �g�[�N���R�[�h2
--          --                      ,iv_token_value2 => l_get_rec.kanryo_dt -- �g�[�N���l2�l
--          --);
--          --lv_sub_buf  := lv_sub_msg;
--          --RAISE select_error_expt;
--          l_get_rec.kanryo_dt := NULL;
--          /* 2009.11.27 K.Satomura E_�{�ғ�_00118 END */
--        END IF;
--        --
--        /* 2009.05.18 K.Satomura T1_1049�Ή� END */
--
-- 2011/10/14 v1.19 T.Yoshimoto Del End E_�{�ғ�_05929
--
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
        -- ==========================
        -- == �@��
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.vendor_number
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.vendor_number) > 14 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kiban_ja;
--
        END IF;
--
        -- ==========================
        -- == �J�E���^�[No
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.count_no
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.count_no) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_count_no_ja;
--
        END IF;
--
        -- ==========================
        -- == �n��R�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.chiku_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.chiku_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_chiku_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == ��Ɖ�ЃR�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.sagyougaisya_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sagyougaisya_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sagyougaisya_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Ə��R�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.jigyousyo_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jigyousyo_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jigyousyo_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI��Ɠ`�[No
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.den_no
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.den_no) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_den_no_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI��Ƌ敪
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.job_kbn
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.job_kbn) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_job_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI��Ɛi��
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sintyoku_kbn
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sintyoku_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sintyoku_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI��Ɗ����\���
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.yotei_dt
                                       ,iv_date_format  => 'YYYY/MM/DD'
                                       );
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_yotei_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI��Ɗ�����
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.kanryo_dt
                                       ,iv_date_format  => 'YYYY/MM/DD'
                                       );
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kanryo_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI�������e
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sagyo_level
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sagyo_level) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sagyo_level_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI�ݒu�`�[No
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.den_no2
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.den_no2) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_den_no2_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI�ݒu�敪
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.job_kbn2
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.job_kbn2) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_job_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI�ݒu�i��
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sintyoku_kbn2
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sintyoku_kbn2) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sintyoku_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == �@����1
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn1
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn1) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn1_ja;
--
        END IF;
--
        -- ==========================
        -- == �@����2
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn2
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn2) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn2_ja;
--
        END IF;
--
        -- ==========================
        -- == �@����3
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.jotai_kbn3
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.jotai_kbn3) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_jotai_kbn3_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ɓ�
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.nyuko_dt
                                       ,iv_date_format  => cv_yymmddhhmiss
                                       );
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_nyuko_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == ���g��ЃR�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.hikisakigaisya_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.hikisakigaisya_cd) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_hikisakigaisya_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == ���g���Ə��R�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.hikisakijigyosyo_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.hikisakijigyosyo_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_hikisakijigyosyo_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == �ݒu��S���Җ�
        -- ==========================
        lb_check_date := cb_true;    -- ������
        -- �����`�F�b�N
        IF ( LENGTHB(l_get_rec.setti_tanto) > 20 ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tanto_ja;
--
        END IF;
--
        -- ==========================
        -- == �ݒu��TEL1
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel1
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel1) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel1_ja;
--
        END IF;
--
        -- ==========================
        -- == �ݒu��TEL2
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel2
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel2) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel2_ja;
--
        END IF;
--
        -- ==========================
        -- == �ݒu��TEL3
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.setti_tel3
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.setti_tel3) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_setti_tel3_ja;
--
        END IF;
--
        -- ==========================
        -- == �p�����ٓ�
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.haikikessai_dt
                                       ,iv_date_format  => cv_yymmdd
                                       );
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_haikikessai_dt_ja;
--
        END IF;
--
        -- ==========================
        -- == �]���p���Ǝ�
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.tenhai_tanto
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_tanto) > 6 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_tanto_ja;
--
        END IF;
--
        -- ==========================
        -- == �]���p���`�[No
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.tenhai_den_no
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_den_no) > 12 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_den_no_ja;
--
        END IF;
--
        -- ==========================
        -- == ���L��
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.syoyu_cd
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.syoyu_cd) > 4 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_syoyu_cd_ja;
--
        END IF;
--
        -- ==========================
        -- == �]���p���󋵃t���O
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.tenhai_flg
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.tenhai_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_tenhai_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == �]�������敪
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.kanryo_kbn
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.kanryo_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_kanryo_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == �폜�t���O
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.sakujo_flg
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.sakujo_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_sakujo_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == �ŏI�ڋq�R�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_kyaku_last
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_kyaku_last) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kyaku_last_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ЃR�[�h1
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd01
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd01) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd01_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Б䐔1
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu01
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu01) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu01_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ЃR�[�h2
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd02
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd02) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd02_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Б䐔2
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu02
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu02) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu02_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ЃR�[�h3
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd03
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd03) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd03_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Б䐔3
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu03
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu03) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu03_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ЃR�[�h4
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd04
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd04) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd04_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Б䐔4
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu04
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu04) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu04_ja;
--
        END IF;
--
        -- ==========================
        -- == ���ЃR�[�h5
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_cd05
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_cd05) > 2 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_cd05_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Б䐔5
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_tasya_daisu05
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_tasya_daisu05) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_tasya_daisu05_ja;
--
        END IF;
--
        -- ==========================
        -- == �p���t���O
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_haiki_flg
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_haiki_flg) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_haiki_flg_ja;
--
        END IF;
--
        -- ==========================
        -- == ���Y�敪
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.ven_sisan_kbn
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_sisan_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_sisan_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == �w�����t
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxcso_util_common_pkg.check_date(
                                        iv_date         => l_get_rec.ven_kobai_ymd
                                       ,iv_date_format  => cv_yymmddhhmiss
                                       );
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kobai_ymd_ja;
--
        END IF;
--
        -- ==========================
        -- == �w�����z
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_number(
                                 iv_check_char => l_get_rec.ven_kobai_kg
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.ven_kobai_kg) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_ven_kobai_kg_ja;
--
        END IF;
--


        -- ==========================
        -- == ���S�ݒu�
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.safty_level
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.safty_level) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_safty_level_ja;
--
        END IF;
--
        -- ==========================
        -- == ���[�X�敪
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.lease_kbn
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.lease_kbn) > 1 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_lease_kbn_ja;
--
        END IF;
--
        -- ==========================
        -- == �挎���ݒu��ڋq�R�[�h
        -- ==========================
        -- �����`�F�b�N
        lb_check_date := xxccp_common_pkg.chk_single_byte(
                                 iv_chk_char => l_get_rec.last_inst_cust_code
                                 );
        -- �����`�F�b�N��OK���A�����`�F�b�N��NG�̏ꍇ
        IF (( lb_check_date = cb_true)
          AND ( LENGTHB(l_get_rec.last_inst_cust_code) > 9 ) ) THEN
--
          lb_check_date := cb_false;
--
        END IF;
--
        -- �g�[�N��(message)�ɍ��ږ���ݒ�
        IF ( lb_check_date = cb_false ) THEN
--
          IF lv_token_msg IS NOT NULL THEN
            lv_token_msg := lv_token_msg || cv_comma;
          END IF;
--
          lv_token_msg := lv_token_msg || cv_last_inst_cust_code_ja;
--
        END IF;
--
        -- ==================================
        -- == �����E�����`�F�b�N���ʏo��
        -- ==================================
        IF ( lv_token_msg IS NOT NULL ) THEN
--
          -- �X�L�b�v�������J�E���g�A�b�v
          gn_skip_cnt  := gn_skip_cnt + 1;
--
          RAISE validation_expt;
--
        END IF;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
--
        -- ================================================================
        -- A-6 CSV�t�@�C���ɏo�͂���֘A���擾
        -- ================================================================
--
-- UPD 20090220 Sai �֘A��񒊏o���s���A�x���X�L�b�v�˃G���[���f�ɕύX START
--      get_csv_data(
--         io_get_rec       => l_get_rec        -- �Y��}�X�^�f�[�^
--        ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
--        ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--        ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--      );
--      IF (lv_sub_retcode = cv_status_error) THEN
--        RAISE select_error_expt;
--      END IF;
        get_csv_data(
           io_get_rec       => l_get_rec        -- �Y��}�X�^�f�[�^
          ,id_bsnss_mnth    => ld_bsnss_mnth    -- �Ɩ���
          ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
        ELSIF (lv_retcode = cv_status_warn) THEN
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
          --lv_sub_msg := lv_errmsg;
          --lv_sub_buf := lv_errmsg;
          --RAISE select_error_expt;
          lv_warn_flag := cv_flag_yes;
          --
          /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
        /* 2009.05.25 M.Maruyama T1_1154�Ή� START */
        END IF;
-- UPD 20090220 Sai �֘A��񒊏o���s���A�x���X�L�b�v�˃G���[���f�@�ɕύX�@END
--
        -- ========================================
        -- A-7. �Y��}�X�^�f�[�^CSV�t�@�C���o��
        -- ========================================
        create_csv_rec(
          i_get_rec        =>  l_get_rec         -- �Y��}�X�^�f�[�^
         ,ov_errbuf        =>  lv_errbuf         -- �G���[�E���b�Z�[�W
         ,ov_retcode       =>  lv_retcode        -- ���^�[���E�R�[�h
         ,ov_errmsg        =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE lv_process_expt;
        END IF;
        --���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929
        -- *** �����E�����`�F�b�N�̃G���[��O�n���h�� ***
        WHEN validation_expt THEN
--
          lv_msg2 := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_20               -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_bukken                  -- �g�[�N��
                             ,iv_token_value1 => l_get_rec.install_code         -- �l
                             ,iv_token_name2  => cv_tkn_message                 -- �g�[�N��
                             ,iv_token_value2 => lv_token_msg                   -- �l
                            );
--
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg2
          );
--
          -- �X�e�[�^�X�Ɍx����ݒ�
          ov_retcode     := cv_status_warn;
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
--
        -- *** �f�[�^���o���̃G���[��O�n���h�� ***
        WHEN lv_process_expt THEN
          RAISE global_process_expt;
        -- *** �f�[�^���o���̌x����O�n���h�� ***
        WHEN select_error_expt THEN
          --�G���[�����J�E���g
          gn_error_cnt  := gn_error_cnt + 1;
          --
          lv_sub_retcode := cv_status_warn;
          ov_retcode     := lv_sub_retcode;
          --�x���o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg                  --���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       /* 2009.07.21 K.Hosoi 0000475�Ή� START */
                       --lv_sub_buf
                       lv_sub_buf ||cv_msg_bkn_cd||
                       l_get_rec.install_code || cv_prnthss
                       /* 2009.07.21 K.Hosoi 0000475�Ή� START */
          );
      END;
--
    END LOOP get_data_loop;
--
    --�o�͌������O���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE no_data_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE xibv_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- ========================================
    -- A-8.CSV�t�@�C���N���[�Y
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name  => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� START */
    IF (lv_warn_flag = cv_flag_yes) THEN
       ov_retcode := cv_status_warn;
       --
    END IF;
    /* 2009.11.27 K.Satomura E_�{�ғ�_00118�Ή� END */
  EXCEPTION
    -- *** �����Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xibv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xibv_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xibv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xibv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                    ''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (xibv_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE xibv_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
''
       );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf              OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode             OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I��
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
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-9.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
-- 2011/10/14 v1.19 T.Yoshimoto Add Start E_�{�ғ�_05929(�R�����g�A�E�g����)
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2011/10/14 v1.19 T.Yoshimoto Add End E_�{�ғ�_05929
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A05C;
/
