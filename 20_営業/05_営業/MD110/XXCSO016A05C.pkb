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
 * Version          : 1.4
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  get_profile_info            �v���t�@�C���l�擾 (A-2)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-3)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-5)
 *  create_csv_rec              �Y��}�X�^�f�[�^CSV�o�� (A-6)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-7)
 *  submain                     ���C�������v���V�[�W��
 *                                �����f�[�^���o���� (A-4)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-8)
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
--  gn_skip_cnt               NUMBER;                    -- �X�L�b�v����
--
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
  cv_withdrawal_type     CONSTANT VARCHAR2(10)  := '1:���g';        -- �����˗����׏��r���[�̈��g(���g:1)
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
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00282';     -- ��ƃf�[�^�e�[�u���f�[�^���o�x��
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00283';     -- CSV�t�@�C���o�̓G���[
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';     -- CSV�t�@�C���o��0���G���[
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';     -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';     -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';     -- ���t�����`�F�b�N
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';     -- �Ɩ��������t�擾�G���[
  /* 2009.04.09 K.Satomura T1_0441�Ή� START */
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00560';     -- �l���ݒ胁�b�Z�[�W
  /* 2009.04.09 K.Satomura T1_0441�Ή� END */
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
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'BASE_VALUE';              -- �l
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
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg5 || lv_file_name   || CHR(10) ||
                 cv_debug_msg6 || lv_company_cd  || CHR(10) ||
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
   * Description      : CSV�t�@�C���ɏo�͂���֘A���擾 (A-5)
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
    /* 2009.04.09 K.Satomura T1_0441�Ή� START */
    cv_actual_work_date        CONSTANT VARCHAR2(100)  := '��ƃf�[�^�e�[�u���̎���Ɠ�';
    /* 2009.04.09 K.Satomura T1_0441�Ή� END */
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
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;            -- �K��\����f�[�^
    -- *** ���[�J����O ***
    select_error_expt     EXCEPTION;          -- �f�[�^�o�͏�����O
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
        lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_06              -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_quick_cd                   -- �g�[�N���l1���o������
                          ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                          ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                          ,iv_token_name3  => cv_tkn_status_id              -- �g�[�N���R�[�h3
                          ,iv_token_value3 => l_get_rec.instance_status_id  -- �g�[�N���l3���o������(�X�e�[�^�XID)
                          ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                          ,iv_token_value4 => SQLERRM                       -- �g�[�N���l4
            );
        lv_errbuf  := lv_errmsg;
        RAISE select_error_expt;
    END;
--
    -- ===================================
    -- ���_(����)�R�[�h�E�ڋq�R�[�h�𒊏o
    -- ===================================
    IF ((l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3) AND (l_get_rec.install_account_id IS NULL)) THEN
      lv_sale_base_code   := NULL;  -- ���_�R�[�h��NULL���Z�b�g
      lv_account_number   := NULL;  -- �ڋq�R�[�h��NULL���Z�b�g
    ELSIF (l_get_rec.jotai_kbn1 IS NOT NULL) THEN
      BEGIN
        SELECT   (CASE
                  WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_1
                  THEN xcav.sale_base_code       -- ���_(����)�R�[�h
                  WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2
                  THEN xcav.account_number       -- �ڋq�R�[�h
                  WHEN l_get_rec.jotai_kbn1 = cv_jotai_kbn1_3
                  THEN NULL
                  END) sale_base_code            -- ���_(����)�R�[�h
                ,xcav.account_number             -- �ڋq�R�[�h
        INTO     lv_sale_base_code               -- ���_(����)�R�[�h
                ,lv_account_number               -- �ڋq�R�[�h
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
    END IF;
    -- �@���ԂP���u2:�ؗ��v�̏ꍇ
    /* 2009.04.08 K.Satomura T1_0365�Ή� START */
    IF (io_get_rec.new_old_flag <> cv_flag_yes) THEN
    /* 2009.04.08 K.Satomura T1_0365�Ή� END */
      IF (l_get_rec.jotai_kbn1 = cv_jotai_kbn1_2) THEN
        BEGIN
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
          SELECT MAX(xiw.actual_work_date) max_actual_work_date -- �ؗ��J�n��
          INTO   ln_actual_work_date
          FROM   xxcso_in_work_data        xiw -- ��ƃf�[�^�e�[�u��
                ,po_requisition_headers    prh -- �����˗��w�b�_�r���[
                ,po_requisition_lines      prl -- �����˗����׃r���[
                ,xxcso_requisition_lines_v xrl -- �����˗����׏��r���[
          WHERE  xiw.install_code2          = l_get_rec.install_code
            AND  xiw.completion_kbn         = cn_completion_kbn
            AND  TO_CHAR(xiw.po_req_number) = prh.segment1
            AND  prh.requisition_header_id  = prl.requisition_header_id
            AND  xiw.line_num               = xrl.line_num
            AND  (
                   (
                         xrl.category_kbn    = cv_category_kbn
                     AND xiw.job_kbn         = cn_job_kbn
                     AND xrl.withdrawal_type = cv_withdrawal_type
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
            ;
        /* 2009.04.09 K.Satomura T1_0441�Ή� END */
        EXCEPTION
          -- ���o���s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_work_data                  -- �g�[�N���l1���o������
                              ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                              ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                              /* 2009.04.09 K.Satomura T1_0441�Ή� START */
                              --,iv_token_name3  => cv_tkn_work_date              -- �g�[�N���R�[�h3
                              --,iv_token_value3 => ln_actual_work_date           -- �g�[�N���l3����Ɠ�
                              --,iv_token_name4  => cv_tkn_location_cd            -- �g�[�N���R�[�h4
                              --,iv_token_value4 => lv_base_code                  -- �g�[�N���l4���_(����)�R�[�h
                              --,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                              --,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                              ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                              ,iv_token_value3 => SQLERRM                       -- �g�[�N���l3����Ɠ�
                              /* 2009.04.09 K.Satomura T1_0441�Ή� END */
                );
            lv_errbuf  := lv_errmsg;
            RAISE select_error_expt;
        END;
        -- �������ʂ��Ȃ��ꍇ
        IF (ln_actual_work_date IS NULL) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                              /* 2009.04.09 K.Satomura T1_0441�Ή� START */
                              --,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h
                              --,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                              --,iv_token_value1 => cv_work_data                  -- �g�[�N���l1���o������
                              --,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                              --,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                              ,iv_name         => cv_tkn_number_17              -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_actual_work_date           -- �g�[�N���l1���o������
                              ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                              ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                              --,iv_token_name3  => cv_tkn_work_date              -- �g�[�N���R�[�h3
                              --,iv_token_value3 => ln_actual_work_date           -- �g�[�N���l3����Ɠ�
                              --,iv_token_name4  => cv_tkn_location_cd            -- �g�[�N���R�[�h4
                              --,iv_token_value4 => lv_base_code                  -- �g�[�N���l4���_(����)�R�[�h
                              --,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                              --,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                              /* 2009.04.09 K.Satomura T1_0441�Ή� END */
                );
            lv_errbuf  := lv_errmsg;
            RAISE select_error_expt;
        END IF;
      END IF;
    /* 2009.04.08 K.Satomura T1_0365�Ή� START */
    END IF;
    /* 2009.04.08 K.Satomura T1_0365�Ή� END */
--
    -- ========================================
    -- �������[�J�[�A����@�敪�ƃR�������𒊏o
    -- ========================================
    -- �C���X�^���X�^�C�v���u1:�����̔��@�v�̏ꍇ
    IF (l_get_rec.instance_type_code = 1) THEN
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
      EXCEPTION
        -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_tkn_number_08              -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_proc_name              -- �g�[�N���R�[�h1
                            ,iv_token_value1 => cv_po_un_number_vl            -- �g�[�N���l1���o������
                            ,iv_token_name2  => cv_tkn_object_cd              -- �g�[�N���R�[�h2
                            ,iv_token_value2 => l_get_rec.install_code        -- �g�[�N���l2�O���Q��(�����R�[�h)
                            ,iv_token_name3  => cv_tkn_un_number              -- �g�[�N���R�[�h3
                            ,iv_token_value3 => l_get_rec.vendor_model        -- �g�[�N���l3�@��R�[�h
                            ,iv_token_name4  => cv_tkn_maker_cd               -- �g�[�N���R�[�h4
                            ,iv_token_value4 => lv_attribute2                 -- �g�[�N���l4���[�J�[�R�[�h
                            ,iv_token_name5  => cv_tkn_special1               -- �g�[�N���R�[�h5
                            ,iv_token_value5 => lv_attribute9                 -- �g�[�N���l5����@�敪1
                            ,iv_token_name6  => cv_tkn_special2               -- �g�[�N���R�[�h6
                            ,iv_token_value6 => lv_attribute10                -- �g�[�N���l6����@�敪2
                            ,iv_token_name7  => cv_tkn_special3               -- �g�[�N���R�[�h7
                            ,iv_token_value7 => lv_attribute11                -- �g�[�N���l7����@�敪3
                            ,iv_token_name8  => cv_tkn_column                 -- �g�[�N���R�[�h8
                            ,iv_token_value8 => lv_attribute8                 -- �g�[�N���l8�R������
                            ,iv_token_name9  => cv_tkn_err_msg                -- �g�[�N���R�[�h9
                            ,iv_token_value9 => SQLERRM                       -- �g�[�N���l9
              );
          lv_errbuf  := lv_errmsg;
          RAISE select_error_expt;
      END;
    -- �C���X�^���X�^�C�v���u1:�����̔��@�v�ȊO�̏ꍇ
    ELSE
      lv_attribute2   := NULL;             -- ���[�J�[�R�[�h
      lv_attribute9   := NULL;             -- ����@�敪1
      lv_attribute10  := NULL;             -- ����@�敪2
      lv_attribute11  := NULL;             -- ����@�敪3
      lv_attribute8   := NULL;             -- �R������
    END IF;
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
        INTO    lv_lease_type                   -- �ă��[�X�敪
               ,ln_second_charge                -- ���[�X�� ���z���[�X��(�Ŕ�)
        FROM    xxcff_object_headers xoh        -- ���[�X�����}�X�^
               ,xxcff_contract_headers xch      -- ���[�X�_��e�[�u��
               ,xxcff_contract_lines xcl        -- ���[�X�_�񖾍׃e�[�u��
        WHERE   xoh.object_code = lv_install_code                 -- �����R�[�h
          AND   xoh.object_header_id = xcl.object_header_id       -- ��������ID
          AND   xcl.contract_header_id = xch.contract_header_id   -- �_�����ID
          AND   xch.re_lease_times = xoh.re_lease_times;          -- �ă��[�X��
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
    -- �挎���N��<>�Ɩ���-�P�̏ꍇ
    IF ((l_get_rec.last_year_month <> TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt))
      OR (l_get_rec.last_year_month IS NULL))
    THEN
     lv_last_month_base_cd   := lv_sale_base_code;  -- �挎�����_�R�[�h�Ɍ��݂̋��_�R�[�h���Z�b�g
     lv_lst_accnt_num        := lv_account_number;  -- �挎���ڋq�R�[�h�Ɍ��݂̌ڋq�R�[�h���Z�b�g
--
    -- �挎���N��=�Ɩ���-�P�̏ꍇ
    ELSIF (l_get_rec.last_year_month = TO_CHAR(ADD_MONTHS(ld_bsnss_mnth,cn_mnth_shft),cv_yr_mnth_frmt)) THEN
      -- �挎���@���Ԃ�3�̏ꍇ
      IF (l_get_rec.last_jotai_kbn = cv_jotai_kbn1_3) THEN
        lv_last_month_base_cd   := NULL;                           -- �挎�����_�R�[�h��NULL���Z�b�g
        lv_lst_accnt_num        := l_get_rec.last_inst_cust_code;  -- �挎���ڋq�R�[�h�ɐ挎���ڋq�R�[�h���Z�b�g
      ELSIF (l_get_rec.last_jotai_kbn IN (cv_jotai_kbn1_1,cv_jotai_kbn1_2)) THEN
        BEGIN
          SELECT   (CASE
                    WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_1
                    THEN xcav.past_sale_base_code  -- �O�����㋒�_(����)�R�[�h
                    WHEN l_get_rec.last_jotai_kbn = cv_jotai_kbn1_2
                    THEN xcav.account_number       -- �ڋq�R�[�h
                    END) last_month_base_cd
                   ,l_get_rec.last_inst_cust_code  -- �挎���ڋq�R�[�h
            INTO   lv_last_month_base_cd           -- �挎�����㋒�_�R�[�h
                  ,lv_lst_accnt_num                -- �挎���ڋq�R�[�h
            FROM   xxcso_cust_accounts_v xcav      -- �ڋq�}�X�^�r���[
           WHERE   xcav.account_number = l_get_rec.last_inst_cust_code; -- �ڋq�R�[�h
        EXCEPTION
          -- �������ʂ��Ȃ��ꍇ�A���o���s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_07               -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_proc_name               -- �g�[�N���R�[�h1
                              ,iv_token_value1 => cv_lst_bs_ccnt_cd              -- �g�[�N���l1���o������
                              ,iv_token_name2  => cv_tkn_object_cd               -- �g�[�N���R�[�h2
                              ,iv_token_value2 => l_get_rec.install_code         -- �g�[�N���l2�O���Q��(�����R�[�h)
                              ,iv_token_name3  => cv_tkn_account_id              -- �g�[�N���R�[�h3
                              ,iv_token_value3 => l_get_rec.install_account_id   -- �g�[�N���l3���L�҃A�J�E���gID
                              ,iv_token_name4  => cv_tkn_location_cd             -- �g�[�N���R�[�h4
                              ,iv_token_value4 => lv_last_month_base_cd          -- �g�[�N���l4���_(����)�R�[�h
                              ,iv_token_name5  => cv_tkn_customer_cd             -- �g�[�N���R�[�h5
                              ,iv_token_value5 => l_get_rec.last_inst_cust_code  -- �g�[�N���l5�挎���ڋq�R�[�h
                              ,iv_token_name6  => cv_tkn_err_msg                 -- �g�[�N���R�[�h6
                              ,iv_token_value6 => SQLERRM                        -- �g�[�N���l6
                );
            lv_errbuf  := lv_errmsg;
            RAISE select_error_expt;
        END;
      END IF;
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
  END get_csv_data;
--
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-6)
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
        || cv_sep_com || l_get_rec.instance_number                                            -- �C���X�^���X�ԍ�
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
        || cv_sep_com || l_get_rec.haikikessai_dt                                             -- �p�����ٓ�
        || cv_sep_com || cv_sep_wquot ||l_get_rec.ven_sisan_kbn || cv_sep_wquot               -- ���Y�敪
        || cv_sep_com || l_get_rec.ven_kobai_ymd                                              -- �w�����t
        || cv_sep_com || NVL(l_get_rec.ven_kobai_kg,0)                                        -- �w�����z
        || cv_sep_com || NVL(l_get_rec.count_no,0)                                            -- �J�E���^�[No.
        || cv_sep_com || cv_sep_wquot || l_get_rec.chiku_cd || cv_sep_wquot                   -- �n��R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.sagyougaisya_cd || cv_sep_wquot            -- ��Ɖ�ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.jigyousyo_cd || cv_sep_wquot               -- ���Ə��R�[�h
        || cv_sep_com || NVL(l_get_rec.den_no,0)                                              -- �ŏI��Ɠ`�[No.
        || cv_sep_com || NVL(l_get_rec.job_kbn,0)                                             -- �ŏI��Ƌ敪
        || cv_sep_com || NVL(l_get_rec.sintyoku_kbn,0)                                        -- �ŏI��Ɛi��
        || cv_sep_com || l_get_rec.yotei_dt                                                   -- �ŏI��Ɗ����\���
        || cv_sep_com || l_get_rec.kanryo_dt                                                  -- �ŏI��Ɗ�����
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
   * Description      : CSV�t�@�C���N���[�Y���� (A-7)
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
    cv_install_cd_tkn       CONSTANT VARCHAR2(100)   := '�����}�X�^�r���[';
    cv_fist_install_dt_tkn  CONSTANT VARCHAR2(100)   := '����ݒu��';
    cv_nyuko_date_tkn       CONSTANT VARCHAR2(100)   := '���ɓ�';
    cv_lst_yr_mnth_tkn      CONSTANT VARCHAR2(100)   := '�挎���N��';
    cn_lst_yr_mnth_num      CONSTANT NUMBER(1)       := 6;
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
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR xibv_data_cur
    IS
      SELECT xibv.install_code           install_code             -- �O���Q��
            ,xibv.instance_type_code     instance_type_code       -- �C���X�^���X�^�C�v
            ,xibv.instance_status_id     instance_status_id       -- �X�e�[�^�XID
            ,xibv.install_date           install_date             -- ������
            ,xibv.instance_number        instance_number          -- �C���X�^���X�ԍ�
            ,xibv.quantity               quantity                 -- ����
            ,xibv.accounting_class_code  accounting_class_code    -- ��v����
            ,xibv.active_start_date      active_start_date        -- �J�n��
            ,xibv.inventory_item_id      inventory_item_id        -- �i���R�[�h
            ,xibv.install_party_id       install_party_id         -- �g�p�҃p�[�e�BID
            ,xibv.install_account_id     install_account_id       -- �g�p�҃A�J�E���gID
            ,xibv.vendor_model           vendor_model             -- �@��(DFF1)
            ,xibv.vendor_number          vendor_number            -- �@��(DFF2)
            ,xibv.first_install_date     first_install_date       -- ����ݒu��(DFF3)
            ,xibv.op_request_flag        op_request_flag          -- ��ƈ˗����t���O(DFF4)
            ,xibv.ven_kyaku_last         ven_kyaku_last           -- �ŏI�ڋq�R�[�h
            ,xibv.ven_tasya_cd01         ven_tasya_cd01           -- ���ЃR�[�h�P
            ,xibv.ven_tasya_daisu01      ven_tasya_daisu01        -- ���Б䐔�P
            ,xibv.ven_tasya_cd02         ven_tasya_cd02           -- ���ЃR�[�h�Q
            ,xibv.ven_tasya_daisu02      ven_tasya_daisu02        -- ���Б䐔�Q
            ,xibv.ven_tasya_cd03         ven_tasya_cd03           -- ���ЃR�[�h�R
            ,xibv.ven_tasya_daisu03      ven_tasya_daisu03        -- ���Б䐔�R
            ,xibv.ven_tasya_cd04         ven_tasya_cd04           -- ���ЃR�[�h�S
            ,xibv.ven_tasya_daisu04      ven_tasya_daisu04        -- ���Б䐔�S
            ,xibv.ven_tasya_cd05         ven_tasya_cd05           -- ���ЃR�[�h�T
            ,xibv.ven_tasya_daisu05      ven_tasya_daisu05        -- ���Б䐔�T
            ,xibv.ven_haiki_flg          ven_haiki_flg            -- �p���t���O
            ,xibv.haikikessai_dt         haikikessai_dt           -- �p�����ٓ�
            ,xibv.ven_sisan_kbn          ven_sisan_kbn            -- ���Y�敪
            ,xibv.ven_kobai_ymd          ven_kobai_ymd            -- �w�����t
            ,xibv.ven_kobai_kg           ven_kobai_kg             -- �w�����z
            ,xibv.count_no               count_no                 -- �J�E���^�[No.
            ,xibv.chiku_cd               chiku_cd                 -- �n��R�[�h
            ,xibv.sagyougaisya_cd        sagyougaisya_cd          -- ��Ɖ�ЃR�[�h
            ,xibv.jigyousyo_cd           jigyousyo_cd             -- ���Ə��R�[�h
            ,xibv.den_no                 den_no                   -- �ŏI��Ɠ`�[No.
            ,xibv.job_kbn                job_kbn                  -- �ŏI��Ƌ敪
            ,xibv.sintyoku_kbn           sintyoku_kbn             -- �ŏI��Ɛi��
            ,xibv.yotei_dt               yotei_dt                 -- �ŏI��Ɗ����\���
            ,xibv.kanryo_dt              kanryo_dt                -- �ŏI��Ɗ�����
            ,xibv.sagyo_level            sagyo_level              -- �ŏI�������e
            ,xibv.den_no2                den_no2                  -- �ŏI�ݒu�`�[No.
            ,xibv.job_kbn2               job_kbn2                 -- �ŏI�ݒu�敪
            ,xibv.sintyoku_kbn2          sintyoku_kbn2            -- �ŏI�ݒu�i��
            ,xibv.jotai_kbn1             jotai_kbn1               -- �@����1�i�ғ���ԁj
            ,xibv.jotai_kbn2             jotai_kbn2               -- �@����2�i��ԏڍׁj
            ,xibv.jotai_kbn3             jotai_kbn3               -- �@����3�i�p�����j
            ,xibv.nyuko_dt               nyuko_dt                 -- ���ɓ�
            ,xibv.hikisakigaisya_cd      hikisakigaisya_cd        -- ���g��ЃR�[�h
            ,xibv.hikisakijigyosyo_cd    hikisakijigyosyo_cd      -- ���g���Ə��R�[�h
            ,xibv.setti_tanto            setti_tanto              -- �ݒu��S���Җ�
            ,xibv.setti_tel1             setti_tel1               -- �ݒu��TEL(�A��)�P
            ,xibv.setti_tel2             setti_tel2               -- �ݒu��TEL(�A��)�Q
            ,xibv.setti_tel3             setti_tel3               -- �ݒu��TEL(�A��)�R
            ,xibv.tenhai_tanto           tenhai_tanto             -- �]���p���Ǝ�
            ,xibv.tenhai_den_no          tenhai_den_no            -- �]���p���`�[��
            ,xibv.syoyu_cd               syoyu_cd                 -- ���L��
            ,xibv.tenhai_flg             tenhai_flg               -- �]���p���󋵃t���O
            ,xibv.kanryo_kbn             kanryo_kbn               -- �]�������敪
            ,xibv.sakujo_flg             sakujo_flg               -- �폜�t���O
            ,xibv.safty_level            safty_level              -- ���S�ݒu�
            ,xibv.lease_kbn              lease_kbn                -- ���[�X�敪
            ,xibv.new_old_flag           new_old_flag             -- �V�Ñ�t���O
            ,xibv.last_inst_cust_code    last_inst_cust_code      -- �挎���ݒu��ڋq�R�[�h
            ,xibv.last_jotai_kbn         last_jotai_kbn           -- �挎���@����
            ,xibv.last_year_month        last_year_month          -- �挎���N��
      /*20090415_maruyama_T1_0550 START*/
      FROM   xxcso_install_base_v xibv;
--      where instance_id IN(104039,90043,90045);                           -- �����}�X�^�r���[
      /*20090415_maruyama_T1_0550 END*/
    -- *** ���[�J���E���R�[�h ***
    l_xibv_data_rec        xibv_data_cur%ROWTYPE;
    l_get_rec              g_value_rtype;                        -- �Y��}�X�^�f�[�^
    -- *** ���[�J���E��O ***
    select_error_expt EXCEPTION;
    lv_process_expt   EXCEPTION;
    no_data_expt      EXCEPTION;
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
--    gn_skip_cnt   :=0;
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
    -- �J�[�\���I�[�v��
    OPEN xibv_data_cur;
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
        -- ���t�����`�F�b�N
        -- ����ݒu��(DFF3)
        lb_check_date := xxcso_util_common_pkg.check_date(
                                      iv_date         => l_get_rec.first_install_date
                                    ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
        );
        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
        IF (lb_check_date = cb_false) THEN
          lv_sub_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_fist_install_dt_tkn        -- �g�[�N���l1���ږ�
                                ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
                                ,iv_token_value2 => l_get_rec.first_install_date  -- �g�[�N���l2�l
          );
          lv_sub_buf  := lv_sub_msg;
          RAISE select_error_expt;
        END IF;
        -- ���ɓ�
        lb_check_date := xxcso_util_common_pkg.check_date(
                                      iv_date         => l_get_rec.nyuko_dt
                                     ,iv_date_format  => 'YY/MM/DD HH24:MI:SS'
        );
        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
        IF (lb_check_date = cb_false) THEN
          lv_sub_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_nyuko_date_tkn             -- �g�[�N���l1���ږ�
                                ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
                                ,iv_token_value2 => l_get_rec.nyuko_dt            -- �g�[�N���l2�l
          );
          lv_sub_buf  := lv_sub_msg;
          RAISE select_error_expt;
        END IF;
        -- �挎���N��
        lb_check_date := xxcso_util_common_pkg.check_date(
                                      iv_date         => l_get_rec.last_year_month
                                     ,iv_date_format  => 'YY/MM'
        );
        --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
        IF (lb_check_date = cb_false) THEN
          lv_sub_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_15              -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_item                   -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_lst_yr_mnth_tkn            -- �g�[�N���l1���ږ�
                                ,iv_token_name2  => cv_tkn_value                  -- �g�[�N���R�[�h2
                                ,iv_token_value2 => l_get_rec.last_year_month     -- �g�[�N���l2�l
          );
          lv_sub_buf  := lv_sub_msg;
          RAISE select_error_expt;
        END IF;
--
        -- ================================================================
        -- A-5 CSV�t�@�C���ɏo�͂���֘A���擾
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
        END IF;
-- UPD 20090220 Sai �֘A��񒊏o���s���A�x���X�L�b�v�˃G���[���f�@�ɕύX�@END
--
        -- ========================================
        -- A-6. �Y��}�X�^�f�[�^CSV�t�@�C���o��
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
                       lv_sub_buf
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
    -- A-7.CSV�t�@�C���N���[�Y
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
    -- A-8.�I������
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
    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
--                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
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
