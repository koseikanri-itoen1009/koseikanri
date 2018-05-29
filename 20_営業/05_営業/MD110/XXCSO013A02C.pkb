CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A02C(body)
 * Description      : ���̋@�Ǘ��V�X�e������A�g���ꂽ���[�X�����Ɋ֘A�����Ƃ̏����A
 *                    ���[�X�A�h�I���ɔ��f���܂��B
 * MD.050           :  MD050_CSO_013_A02_CSI��FA�C���^�t�F�[�X�F�iOUT�j���[�X���Y���
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                          �������� (A-1)
 *  get_po_number                 �����ԍ����o (A-3)
 *  get_type_info                 �@���񒊏o (A-4)
 *  get_acct_info                 �ڋq�֘A��񒊏o (A-5)
 *  ib_info_change_chk            �����֘A���ύX�`�F�b�N���� (A-6)
 *  xxcff_vd_object_if_chk        ���̋@SH�����C���^�t�F�[�X���݃`�F�b�N (A-7)
 *  xxcso_ib_info_h_lock          �����֘A�ύX�����e�[�u�����b�N (A-8)
 *  insert_xxcff_vd_object_if     ���̋@SH�����C���^�t�F�[�X�o�^���� (A-10)
 *  update_xxcso_ib_info_h        �����֘A���ύX�����e�[�u���X�V���� (A-11)
 *  submain                       ���C�������v���V�[�W��
 *                                  �����֘A��񒊏o (A-2)
 *                                  �Z�[�u�|�C���g���s���� (A-9)
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-02    1.0   Tomoko.Mori      �V�K�쐬
 *  2009-04-01    1.1   Kazuo.Satomura   T1_0148,0149�Ή�
 *  2009-04-03    1.2   Kazuo.Satomura   T1_0269�Ή�
 *  2009-04-07    1.3   Daisuke.Abe      T1_0339�Ή�
 *  2009-04-07    1.4   Kazuo.Satomura   T1_0378�Ή�
 *  2009-04-08    1.5   Kazuo.Satomura   T1_0372,0403�Ή�
 *  2009-04-28    1.6   Tomoko.Mori      T1_0758�Ή�
 *  2009-05-01    1.7   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-14    1.8   Kazuo.Satomura   T1_0413�Ή�,SQL���R�[�f�B���O�K��ʂ�ɏC��
 *  2009-05-20    1.9   Kazuo.Satomura   T1_1095�Ή�
 *  2009-05-26    1.10  Daisuke.Abe      T1_1042�Ή�
 *  2009-05-28    1.11  Daisuke.Abe      T1_1042(��)�Ή�
 *  2009-05-28    1.12  Daisuke.Abe      T1_1042(�ĂQ)�Ή�
 *  2009-07-02    1.13  Kazuo.Satomura   �����e�X�g��Q�Ή�(0000229,0000334)
 *  2009-07-17    1.14  Hiroshi.Ogawa    0000781�Ή�
 *  2009-08-19    1.15  Kazuo.Satomura   �����e�X�g��Q�Ή�(0001051)
 *  2010-01-13    1.16  Kazuyo.Hosoi     E_�{�ғ�_00443�Ή�
 *  2016-01-18    1.17  K.Kiriu          E_�{�ғ�_13456�Ή�
 *  2018-05-22    1.18  Y.Shoji          E_�{�ғ�_15102�Ή�
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO013A02C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00250';  -- �p�����[�^�����敪
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00147';  -- �p�����[�^�������s��
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- �p�����[�^�����敪���͂Ȃ��G���[���b�Z�[�W
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- �p�����[�^�����敪�Ó����`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00029';  -- ���t�����G���[���b�Z�[�W
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00192';  -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������擾�G���[���b�Z�[�W
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- �X�e�[�^�XID�Ȃ��G���[���b�Z�[�W
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- �X�e�[�^�XID���o�G���[���b�Z�[�W
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- �Q�ƃ^�C�v�Ȃ��G���[���b�Z�[�W
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- �Q�ƃ^�C�v���o�G���[���b�Z�[�W
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- �f�[�^�Ȃ��x�����b�Z�[�W
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00254';  -- �l�Z�b�g�Ȃ��x�����b�Z�[�W
  cv_tkn_number_16    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00255';  -- �l�Z�b�g���o�G���[���b�Z�[�W
  cv_tkn_number_17    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- �o�^�G���[���b�Z�[�W
  cv_tkn_number_18    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00272';  -- ���̋@SH�����C���^�t�F�[�X���݃`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_19    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �����֘A��񒊏o�G���[���b�Z�[�W
  /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--  cv_tkn_number_20    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';  -- �����ԍ��Ȃ��x�����b�Z�[�W
--  cv_tkn_number_21    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- �����ԍ����o�G���[���b�Z�[�W
  /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
  cv_tkn_number_22    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00709';  -- ���o�G���[���b�Z�[�W(�L�[�t��)
  cv_tkn_number_23    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00706';  -- �ڋq�ڍs���e�[�u��(�Œ�)
  cv_tkn_number_24    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- �����R�[�h(�Œ�)
  cv_tkn_number_25    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';  -- �ڋq�R�[�h(�Œ�)
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
  -- �g�[�N���R�[�h
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_name        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_value_set_name   CONSTANT VARCHAR2(20) := 'VALUE_SET_NAME';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
  cv_tkn_key              CONSTANT VARCHAR2(20)  := 'KEY';
  cv_tkn_key_value        CONSTANT VARCHAR2(20)  := 'KEY_VALUE';
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
--
  -- ���b�Z�[�W�p�Œ蕶����
  cv_tkn_msg_pro_div      CONSTANT VARCHAR2(200) := '�����敪';
  cv_tkn_msg_pro_date     CONSTANT VARCHAR2(200) := '�����Ώۓ��t';
  cv_tkn_msg_itoen_acc_nm CONSTANT VARCHAR2(200) := 'XXCSO:�ɓ����ڋq��';
  /* 2009.04.28 T.Mori T1_0758�Ή� START */
  cv_tkn_msg_cust_cd_dammy CONSTANT VARCHAR2(200) := 'XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j';
  /* 2009.04.28 T.Mori T1_0758�Ή� END */
  cv_tkn_msg_org_id       CONSTANT VARCHAR2(200) := 'MO:�c�ƒP��';
  cv_tkn_msg_status_id    CONSTANT VARCHAR2(200) := '�C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID';
  cv_tkn_msg_object_del   CONSTANT VARCHAR2(200) := '�����폜��';
  cv_tkn_msg_lookup_type  CONSTANT VARCHAR2(200) := '�Q�ƃ^�C�v';
  cv_tkn_msg_inv_henpin   CONSTANT VARCHAR2(200) := 'INV �H��ԕi�q�֐�R�[�h';
  cv_tkn_msg_po_num       CONSTANT VARCHAR2(200) := '�����ԍ�';
  cv_tkn_msg_model        CONSTANT VARCHAR2(200) := '�@��';
  cv_tkn_msg_model_cd     CONSTANT VARCHAR2(200) := '�@��R�[�h';
  cv_tkn_msg_acct_info    CONSTANT VARCHAR2(200) := '�ڋq�֘A���';
  cv_tkn_msg_account_id   CONSTANT VARCHAR2(200) := '���L�҃A�J�E���gID';
  cv_tkn_msg_value_set    CONSTANT VARCHAR2(200) := '�l�Z�b�g';
  cv_tkn_msg_owner_comp   CONSTANT VARCHAR2(200) := '�{�Ё^�H��敪';
  cv_tkn_msg_vd_object_if CONSTANT VARCHAR2(200) := '���̋@SH�����C���^�t�F�[�X';
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  cv_tkn_msg_target       CONSTANT VARCHAR2(200) := '���o�Ώە���';
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
  cv_tkn_msg_ib_info      CONSTANT VARCHAR2(200) := '�����֘A���';
  cv_tkn_msg_ib_info_h    CONSTANT VARCHAR2(200) := '�����֘A���ύX����';
  cv_tkn_msg_select       CONSTANT VARCHAR2(200) := '���o';
  cv_tkn_msg_insert       CONSTANT VARCHAR2(200) := '�o�^';
  cv_tkn_msg_update       CONSTANT VARCHAR2(200) := '�X�V';
  cv_tkn_msg_lock         CONSTANT VARCHAR2(200) := '���b�N';
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1_1         CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg1_2         CONSTANT VARCHAR2(200) := 'gd_sys_date = ';
  cv_debug_msg1_3         CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg1_4         CONSTANT VARCHAR2(200) := 'gd_business_date = ';
  cv_debug_msg1_5         CONSTANT VARCHAR2(200) := '<< �������擾���� >>';
  cv_debug_msg1_6         CONSTANT VARCHAR2(200) := 'gd_process_date = ';
  cv_debug_msg1_7         CONSTANT VARCHAR2(200) := '<< �ɓ����ڋq���擾���� >>';
  cv_debug_msg1_8         CONSTANT VARCHAR2(200) := 'gv_itoen_cust_name = ';
  cv_debug_msg1_9         CONSTANT VARCHAR2(200) := '<< �c�ƒP�ʎ擾���� >>';
  cv_debug_msg1_10        CONSTANT VARCHAR2(200) := 'gn_org_id = ';
  cv_debug_msg1_11        CONSTANT VARCHAR2(200) := '<< �C���X�^���X�X�e�[�^�XID�擾���� >>';
  cv_debug_msg1_12        CONSTANT VARCHAR2(200) := 'gn_instance_status_id = ';
  cv_debug_msg1_13        CONSTANT VARCHAR2(200) := '<< INV �H��ԕi�q�֐�R�[�h�擾���� >>';
  cv_debug_msg1_14        CONSTANT VARCHAR2(200) := '�H��ԕi�q�֐�R�[�h = ';
  cv_debug_msg1_15        CONSTANT VARCHAR2(200) := 'INV �H��ԕi�q�֐�R�[�h�擾�p�J�[�\��';
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  cv_debug_msg1_16        CONSTANT VARCHAR2(200) := '<< IB�������x���擾���� >>';
  cv_debug_msg1_17        CONSTANT VARCHAR2(200) := 'gv_attribute_level = ';
  cv_debug_msgsub_0       CONSTANT VARCHAR2(200) := '���o�Ώە����擾�p�J�[�\��';
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
  cv_debug_msgsub_1       CONSTANT VARCHAR2(200) := '�����֘A���擾�p�J�[�\��';
  cv_debug_msg_rollback   CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err0_1     CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err0_2     CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err0_3     CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err1_1     CONSTANT VARCHAR2(200) := 'prm_check_expt';
  cv_debug_msg_err1_2     CONSTANT VARCHAR2(200) := 'sql_err_expt';
  --
  cv_yes                  CONSTANT VARCHAR2(1) := 'Y';
  cv_no                   CONSTANT VARCHAR2(1) := 'N';
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
  cv_null                 CONSTANT VARCHAR2(10) := 'NULL';
  /* 2009.04.08 K.Satomura T1_0403�Ή� START */
  cn_zero                 CONSTANT NUMBER := 0;
  /* 2009.04.08 K.Satomura T1_0403�Ή� END */
  --IN�p�����[�^�F�����敪
  cv_prm_normal           CONSTANT VARCHAR2(1) := '1';
  cv_prm_div              CONSTANT VARCHAR2(1) := '2';
  --IN�p�����[�^�F�������s���t�H�[�}�b�g
  cv_prm_date_format      CONSTANT VARCHAR2(8) := 'YYYYMMDD';
  -- �C���X�^���X�}�X�^�F�X�e�[�^�X
  cv_delete_code            CONSTANT VARCHAR2(1) := '6'; -- �����폜�σR�[�h
  -- �Q�ƃ^�C�v
  cv_xxcoi_mfg_fctory_cd    CONSTANT VARCHAR2(200) := 'XXCOI_MFG_FCTORY_CD';
  cv_xxcso1_instance_status CONSTANT VARCHAR2(200) := 'XXCSO1_INSTANCE_STATUS';
  cv_csi_inst_type_code     CONSTANT VARCHAR2(200) := 'CSI_INST_TYPE_CODE';
  cv_xxcso_csi_maker_code   CONSTANT VARCHAR2(200) := 'XXCSO_CSI_MAKER_CODE';
  cv_xxcff_owner_company    CONSTANT VARCHAR2(200) := 'XXCFF_OWNER_COMPANY';
  cv_xxcso1_owner_company   CONSTANT VARCHAR2(200) := 'XXCSO1_OWNER_COMPANY';
  -- �����}�X�^�ǉ������n�擾���ږ�
  cv_lease_kbn              CONSTANT VARCHAR2(200) := 'LEASE_KBN';
  -- ���[�X�敪
  cv_jisya_lease            CONSTANT VARCHAR2(1) := '1'; -- ���Ѓ��[�X
  -- ��Ƌ敪
  cv_job_kbn_set            CONSTANT VARCHAR2(1) := '1'; -- �V��ݒu
  cv_job_kbn_change         CONSTANT VARCHAR2(1) := '3'; -- �V����
  -- �����敪
  cv_comp_kbn_ok            CONSTANT VARCHAR2(1) := '1'; -- ����
  -- �{�Ё^�H��敪
  cv_owner_company_honsya   CONSTANT VARCHAR2(1) := '1'; -- �{��
  cv_owner_company_fact     CONSTANT VARCHAR2(1) := '2'; -- �H��
  -- �捞�X�e�[�^�X�i�Œ�l�j
  cv_import_status          CONSTANT VARCHAR2(1) := '0'; -- ���捞
  -- �ڋq�X�e�[�^�X
  cv_cut_enb_status         CONSTANT VARCHAR2(1) := 'A'; -- �g�p��
  /* 2009.04.28 T.Mori T1_0758�Ή� START */
  -- �ڋq�敪
  cv_cust_class_10          CONSTANT VARCHAR2(200) := '10'; -- 10:�ڋq
  -- �v���t�@�C����I�v�V�����l
  cv_prf_cust_cd_dammy      CONSTANT VARCHAR2(200) := 'XXCSO1_AFF_CUST_CODE'; -- �ڋq�R�[�h�i��`�Ȃ��j
  /* 2009.04.28 T.Mori T1_0758�Ή� END */
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  cv_attribute_level        CONSTANT VARCHAR2(200) := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �p�����[�^�i�[�p
  gv_prm_process_div          VARCHAR2(1);  -- �����敪
  gv_prm_process_date         VARCHAR2(8);  -- �������s��
  -- ���[���o�b�N�σt���O
  gv_rollback_flg             VARCHAR2(1);  -- ���[���o�b�N�ρF'Y'
  --
  gd_process_date         DATE;  -- ������
  gd_sys_date             DATE;  -- �V�X�e�����t
  gd_business_date        DATE;  -- �Ɩ��������t
  -- �v���t�@�C����I�v�V�����l
  gv_itoen_cust_name      VARCHAR2(200);  -- �ɓ����ڋq��
  gn_org_id               NUMBER;  -- �c�ƒP��
  --
  gn_instance_status_id   NUMBER;  -- �C���X�^���X�X�e�[�^�XID
  --
  gn_mfg_fctory_cd_cnt    NUMBER;  -- INV �H��ԕi�q�֐�R�[�h����
  --
  /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--  gn_po_number            xxcso_in_work_data.po_number%TYPE;   -- �V_�����ԍ�
  /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
  gv_manufacturer_name    fnd_lookup_values_vl.meaning%TYPE;   -- �V_���[�J�[��
  gv_age_type             po_un_numbers_vl.attribute3%TYPE;    -- �V_�N��
  gv_department_code      xxcso_cust_acct_sites_v.customer_class_code%TYPE;
                                                               -- �V_���_�R�[�h
  /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
  --gv_installation_place   xxcso_cust_acct_sites_v.customer_class_name%TYPE;
  --                                                             -- �V_�ݒu�於
  gv_installation_place   hz_parties.party_name%TYPE;
                                                               -- �V_�ݒu�於
  /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
  gv_installation_address VARCHAR2(600);                       -- �V_�ݒu��Z��
  gv_customer_code        xxcso_cust_acct_sites_v.account_number%TYPE;
                                                               -- �V_�ڋq�R�[�h
  gv_owner_company        fnd_flex_values_vl.flex_value%TYPE;  -- �V_�{�Ё^�H��敪
  /* 2009.04.28 T.Mori T1_0758�Ή� START */
  -- AFF�ڋq�R�[�h�i��`�Ȃ��j
  gv_customer_code_dammy  xxcso_cust_acct_sites_v.account_number%TYPE;
  /* 2009.04.28 T.Mori T1_0758�Ή� END */
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  gv_attribute_level      fnd_profile_option_values.profile_option_value%TYPE;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
--
  -- ===============================
  -- ���[�U�[��`�J�[�\���^
  -- ===============================
  -- INV �H��ԕi�q�֐�R�[�h�擾�p�J�[�\��
  CURSOR mfg_fctory_cd_cur
  IS
    SELECT flvv.lookup_code lookup_code --�쐬��
    FROM   fnd_lookup_values_vl flvv
    WHERE  flvv.lookup_type = cv_xxcoi_mfg_fctory_cd
    AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
    AND    TRUNC(NVL(flvv.end_date_active, gd_process_date))
    AND    flvv.enabled_flag = cv_yes
    ;
  -- �����֘A���擾�p�J�[�\��
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--CURSOR get_xxcso_ib_info_h_cur
  CURSOR get_xxcso_ib_info_h_cur(
    in_instance_id       NUMBER
  )
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
  IS
    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
    --SELECT cii.external_reference        object_code                -- �O���Q�Ɓi�����R�[�h�j
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--  SELECT /*+ first_rows leading(cis) use_nl(cii) */
    SELECT /*+ use_nl(cii xiih hca hp xca hcas hps hl) */
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
           cii.external_reference        object_code                -- �O���Q�Ɓi�����R�[�h�j
    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
          ,cii.attribute1                new_model                  -- �V_�@��(DFF1)
          ,cii.attribute2                new_serial_number          -- �V_�@��(DFF2)
          ,cii.owner_party_account_id    owner_party_account_id     -- ���L�҃A�J�E���gID
          ,DECODE(cii.instance_status_id
                 ,gn_instance_status_id, cv_yes
                 ,cv_no)                 new_active_flag            -- �V_�_���폜�t���O
          /* 2009.04.01 K.Satomura T1_0149�Ή� START */
          --,DECODE(cii.instance_status_id, gn_instance_status_id, cv_yes, cv_no)
          --                               effective_flag             -- �����L���t���O
          ,DECODE(cii.instance_status_id
                 ,gn_instance_status_id, cv_no
                 ,cv_yes)                effective_flag             -- �����L���t���O
          /* 2009.04.01 K.Satomura T1_0149�Ή� END */
          ,xxcso_util_common_pkg.get_lookup_attribute(
             cv_csi_inst_type_code
            ,cii.instance_type_code
            ,1
            ,gd_process_date
           )                             lease_class                -- ���[�X���
          ,cii.quantity                  new_quantity               -- �V_����
          ,xiih.history_creation_date    history_creation_date      -- �����쐬��
          ,xiih.interface_flag           interface_flag             -- �A�g�σt���O
          /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--          ,xiih.po_number                old_po_number              -- ��_�����ԍ�
          /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
          ,xiih.manufacturer_name        old_manufacturer_name      -- ��_���[�J�[��
          ,xiih.age_type                 old_age_type               -- ��_�N��
          ,xiih.un_number                old_model                  -- ��_�@��
          ,xiih.install_number           old_serial_number          -- ��_�@��
          ,xiih.quantity                 old_quantity               -- ��_����
          ,xiih.base_code                old_department_code        -- ��_���_�R�[�h
          ,xiih.owner_company_type       old_owner_company          -- ��_�{�Ё^�H��敪
          ,xiih.install_name             old_installation_place     -- ��_�ݒu�於
          ,xiih.install_address          old_installation_address   -- ��_�ݒu��Z��
          ,xiih.logical_delete_flag      old_active_flag            -- ��_�_���폜�t���O
          ,xiih.account_number           old_customer_code          -- ��_�ڋq�R�[�h
          /* 2009.04.07 D.Abe T1_0339�Ή� START */
          ,cii.attribute5                newold_flag                -- �V�Ñ�t���O
          /* 2009.04.07 D.Abe T1_0339�Ή� END */
          /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--        ,xca.sale_base_code            new_department_code      -- �V_���_�R�[�h
--        ,xca.established_site_name     new_installation_place   -- �V_�ݒu�於
--        ,xca.state    ||
--         xca.city     ||
--         xca.address1 ||
--         xca.address2                  new_installation_address -- �V_�ݒu��Z��
--        ,xca.account_number            new_customer_code        -- �V_�ڋq�R�[�h
--        ,xca.customer_class_code       new_customer_class_code  -- �V_�ڋq�敪�R�[�h
          ,xca.sale_base_code            new_department_code      -- �V_���_�R�[�h
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
          ,xca.past_sale_base_code       past_sale_base_code      -- �O�����㋒�_�R�[�h
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
          /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
          --,xca.established_site_name     new_installation_place   -- �V_�ݒu�於
          ,hp.party_name                 new_installation_place   -- �V_�ݒu�於
          /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
          ,hl.state    ||
           hl.city     ||
           hl.address1 ||
           hl.address2                   new_installation_address -- �V_�ݒu��Z��
          ,hca.account_number            new_customer_code        -- �V_�ڋq�R�[�h
          ,hca.customer_class_code       new_customer_class_code  -- �V_�ڋq�敪�R�[�h
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
          /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
    FROM   csi_item_instances cii    -- �C���X�g�[���x�[�X�}�X�^
          ,xxcso_ib_info_h xiih      -- �����֘A���ύX�����e�[�u��
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--        ,csi_instance_statuses cis -- �C���X�^���X�X�e�[�^�X�}�X�^
--        /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
--        ,xxcso_cust_acct_sites_v xca -- �ڋq�}�X�^�T�C�g�r���[
--        /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
          ,hz_cust_accounts     hca
          ,hz_parties           hp
          ,xxcmm_cust_accounts  xca
          ,hz_cust_acct_sites   hcas
          ,hz_party_sites       hps
          ,hz_locations         hl
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
    WHERE
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
           cii.instance_id           = in_instance_id
      AND  xiih.install_code         = cii.external_reference
      AND  hca.cust_account_id       = cii.owner_party_account_id
      AND  hp.party_id               = hca.party_id
      AND  xca.customer_id           = hca.cust_account_id
      AND  hcas.cust_account_id      = hca.cust_account_id
      AND  hps.party_id              = hp.party_id
      AND  hps.party_site_id         = hcas.party_site_id
      AND  hl.location_id            = hps.location_id
--    (
--        /* 2009.05.26 D.Abe T1_1042�Ή� START */
--        ( (
--             /* 2009.05.28 D.Abe T1_1042(��)�Ή� START */
--             gv_prm_process_date IS NULL
--             AND  (xiih.history_creation_date < gd_process_date  -- �����쐬��
--             OR    xiih.interface_flag  =  cv_no             -- �A�g�σt���O
--                  )
--             --     gv_prm_process_date IS NULL
--             --AND  xiih.interface_flag  = cv_no         -- �A�g�σt���O
--            /* 2009.05.28 D.Abe T1_1042(��)�Ή� END */
--          )
--          OR (
--                   gv_prm_process_date IS NOT NULL
--               AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--               AND  xiih.interface_flag  = cv_yes      -- �A�g�σt���O
--             )
--        )
--      AND
--      --/* 2009.05.14 K.Satomura T1_0413�Ή� START */
--      --  (
--      --       gv_prm_process_date IS NULL
--      --    OR (
--      --             gv_prm_process_date IS NOT NULL
--      --         AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--      --       )
--      --  )
--      --AND
--      --/* 2009.05.14 K.Satomura T1_0413�Ή� END */
--      /* 2009.05.26 D.Abe T1_1042�Ή� END */
--          gv_prm_process_div = cv_prm_normal          -- �p�����[�^�F�����敪
--      AND xiih.install_code  = cii.external_reference -- �����R�[�h
--      AND xxcso_ib_common_pkg.get_ib_ext_attribs(
--             cii.instance_id
--            ,cv_lease_kbn
--          ) = cv_jisya_lease -- ���Ѓ��[�X
--      AND cii.instance_status_id = cis.instance_status_id -- �C���X�^���X�X�e�[�^�XID
--      AND cis.attribute2         = cv_no                  -- �p���σt���O
--      /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
--      AND xca.cust_account_id    = cii.owner_party_account_id -- �A�J�E���gID
--      /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
--      /* 2009.05.26 D.Abe T1_1042�Ή� START */
--      --AND (
--      --         xiih.history_creation_date < gd_process_date  -- �����쐬��
--      --      OR xiih.interface_flag        = cv_no            -- �A�g�σt���O
--      --    )
--      /* 2009.05.26 D.Abe T1_1042�Ή� END */
--    )
--  OR
--    (
--    /* 2009.05.14 K.Satomura T1_0413�Ή� START */
--      (
--           gv_prm_process_date IS NULL
--        OR (
--                 gv_prm_process_date IS NOT NULL
--             AND TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
--           )
--      )
--      AND
--    /* 2009.05.14 K.Satomura T1_0413�Ή� END */
--          gv_prm_process_div = cv_prm_div             -- �p�����[�^�F�����敪
--      AND xiih.install_code  = cii.external_reference -- �����R�[�h
--      AND xxcso_ib_common_pkg.get_ib_ext_attribs(
--             cii.instance_id
--            ,cv_lease_kbn
--          ) = cv_jisya_lease -- ���Ѓ��[�X
--      AND cii.instance_status_id = cis.instance_status_id -- �C���X�^���X�X�e�[�^�XID
--      AND cis.attribute2         = cv_no                  -- �p���σt���O
--      /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
--      AND xca.cust_account_id    = cii.owner_party_account_id -- �A�J�E���gID
--      /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
--    )
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
    ;
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  CURSOR get_target_cur
  IS
    SELECT  /*+ LEADING(xiih) INDEX(XXCSO_IB_INFO_H_N02) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div  = cv_prm_normal
      AND   gv_prm_process_date IS NULL
      AND   xiih.interface_flag    = cv_no
      AND   cii.external_reference = xiih.install_code
      AND   cis.instance_status_id = cii.instance_status_id
      AND   cis.attribute2         = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
    UNION ALL
    SELECT  cii.instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_div   = cv_prm_normal
      AND   gv_prm_process_date  IS NULL
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
      AND   EXISTS (
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- �V�Ñ�ȊO
                AND   xiih.install_code                  = cii.external_reference
                AND   xiih.history_creation_date         < gd_process_date
                AND   xiih.interface_flag                = cv_yes
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- �ڋq�R�[�h�`�F�b�N
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- ���㋒�_�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- �ݒu�於�`�F�b�N
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- �ݒu�於�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- �Z���`�F�b�N
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- �@��`�F�b�N
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- �@�ԃ`�F�b�N
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- ���ʃ`�F�b�N
                       /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--                       OR  NVL(xiih.po_number,' ')            <>                               -- �����ԍ��`�F�b�N
--                             (
--                              SELECT  NVL(TO_CHAR(MAX(xiwd.po_number)),' ')
--                              FROM    xxcso_in_work_data  xiwd
--                              WHERE   xiwd.install_code1           = cii.external_reference
--                                AND   xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)
--                                AND   xiwd.completion_kbn          = cv_comp_kbn_ok
--                                AND   xiwd.install1_processed_flag = cv_yes
--                             )
                       /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- ���[�J�[���`�F�b�N
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- �N���`�F�b�N
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- �_���폜�`�F�b�N
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- �{�ЍH��敪�`�F�b�N
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
              UNION ALL
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
              --WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- �V�Ñ�ȊO
              WHERE   NVL(cii.attribute5,cv_no)          = cv_yes                               -- �V�Ñ�
              /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
                AND   xiih.install_code                  = cii.external_reference
                AND   xiih.history_creation_date         < gd_process_date
                AND   xiih.interface_flag                = cv_yes
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- �ڋq�R�[�h�`�F�b�N
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- ���㋒�_�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- �ݒu�於�`�F�b�N
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- �ݒu�於�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- �Z���`�F�b�N
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- �@��`�F�b�N
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- �@�ԃ`�F�b�N
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- ���ʃ`�F�b�N
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- ���[�J�[���`�F�b�N
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- �N���`�F�b�N
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- �_���폜�`�F�b�N
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- �{�ЍH��敪�`�F�b�N
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
            )
      AND   EXISTS (
              SELECT  1
              FROM    csi_instance_statuses  cis
              WHERE   cis.instance_status_id   = cii.instance_status_id
                AND   cis.attribute2           = cv_no
                AND   ROWNUM                   = 1
            )
    UNION ALL
    SELECT  /*+ LEADING(xiih) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div                = cv_prm_normal
      AND   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
      AND   xiih.interface_flag               = cv_yes
      AND   cii.external_reference            = xiih.install_code
      AND   cis.instance_status_id            = cii.instance_status_id
      AND   cis.attribute2                    = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
    UNION ALL
    SELECT  cii.instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_div   = cv_prm_div
      AND   gv_prm_process_date  IS NULL
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
      AND   EXISTS (
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- �V�Ñ�ȊO
                AND   xiih.install_code                  = cii.external_reference
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- �ڋq�R�[�h�`�F�b�N
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- ���㋒�_�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- �ݒu�於�`�F�b�N
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- �ݒu�於�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- �Z���`�F�b�N
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- �@��`�F�b�N
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- �@�ԃ`�F�b�N
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- ���ʃ`�F�b�N
                       /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--                       OR  NVL(xiih.po_number,' ')            <>                               -- �����ԍ��`�F�b�N
--                             (
--                              SELECT  NVL(TO_CHAR(MAX(xiwd.po_number)),' ')
--                              FROM    xxcso_in_work_data  xiwd
--                              WHERE   xiwd.install_code1           = cii.external_reference
--                                AND   xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)
--                                AND   xiwd.completion_kbn          = cv_comp_kbn_ok
--                                AND   xiwd.install1_processed_flag = cv_yes
--                             )
                       /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- ���[�J�[���`�F�b�N
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� EMD */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- �N���`�F�b�N
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- �_���폜�`�F�b�N
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- �{�ЍH��敪�`�F�b�N
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
              UNION ALL
              SELECT  /*+ USE_NL(xiih hca hp xca hcas hps hl) */
                      1
              FROM    xxcso_ib_info_h       xiih
                     ,hz_cust_accounts      hca
                     ,hz_parties            hp
                     ,xxcmm_cust_accounts   xca
                     ,hz_cust_acct_sites    hcas
                     ,hz_party_sites        hps
                     ,hz_locations          hl
              /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
              --WHERE   NVL(cii.attribute5,cv_no)          = cv_no                               -- �V�Ñ�ȊO
              WHERE   NVL(cii.attribute5,cv_no)          = cv_yes                               -- �V�Ñ�
              /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
                AND   xiih.install_code                  = cii.external_reference
                AND   hca.cust_account_id                = cii.owner_party_account_id
                AND   hp.party_id                        = hca.party_id
                AND   xca.customer_id                    = hca.cust_account_id
                AND   hcas.cust_account_id               = hca.cust_account_id
                AND   hps.party_id                       = hp.party_id
                AND   hps.party_site_id                  = hcas.party_site_id
                AND   hl.location_id                     = hps.location_id
                AND   (
                           (
                            (
                             (hca.customer_class_code <> cv_cust_class_10)
                             AND
                             (gv_customer_code_dammy <> NVL(xiih.account_number,' '))
                            )
                            OR
                            (
                             (
                              (hca.customer_class_code = cv_cust_class_10)
                              AND
                              (NVL(hca.account_number,' ') <> NVL(xiih.account_number,' '))
                             )
                            )
                           )                                                                   -- �ڋq�R�[�h�`�F�b�N
                       OR  NVL(xca.sale_base_code,' ')        <> NVL(xiih.base_code,' ')       -- ���㋒�_�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
                       --OR  NVL(xca.established_site_name,' ') <> NVL(xiih.install_name,' ')    -- �ݒu�於�`�F�b�N
                       OR  NVL(hp.party_name,' ') <> NVL(xiih.install_name,' ')                -- �ݒu�於�`�F�b�N
                       /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
                       OR  NVL(hl.state || hl.city || hl.address1 || hl.address2,' ')          -- �Z���`�F�b�N
                                                              <> NVL(xiih.install_address,' ')
                       OR  NVL(xiih.un_number,' ')            <> NVL(cii.attribute1,' ')       -- �@��`�F�b�N
                       OR  NVL(xiih.install_number,' ')       <> NVL(cii.attribute2,' ')       -- �@�ԃ`�F�b�N
                       OR  NVL(xiih.quantity,0)               <> NVL(cii.quantity,0)           -- ���ʃ`�F�b�N
                       OR  NVL(xiih.manufacturer_name,' ')    <>                               -- ���[�J�[���`�F�b�N
                             (
                              SELECT  NVL(
                                        xxcso_util_common_pkg.get_lookup_meaning(
                                          cv_xxcso_csi_maker_code
                                         ,punv.attribute2
                                         ,gd_process_date
                                        )
                                       ,' '
                                      )
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.age_type,' ')             <>                               -- �N���`�F�b�N
                             (
                              SELECT  NVL(punv.attribute3,' ')
                              FROM    po_un_numbers_vl   punv
                              WHERE   punv.un_number               = cii.attribute1
                                /* 2009.08.19 K.Satomura 0001051�Ή� START */
                                --AND   TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date)
                                /* 2009.08.19 K.Satomura 0001051�Ή� END */
                             )
                       OR  NVL(xiih.logical_delete_flag,' ')  <>                               -- �_���폜�`�F�b�N
                             DECODE(cii.instance_status_id
                               ,gn_instance_status_id, cv_yes
                               ,cv_no
                             )
                       OR  NVL(xiih.owner_company_type,' ')   <>                               -- �{�ЍH��敪�`�F�b�N
                             (
                              SELECT  ffvv.flex_value
                              FROM    fnd_flex_value_sets  ffvs
                                     ,fnd_flex_values_vl   ffvv
                              WHERE   ffvs.flex_value_set_name = cv_xxcff_owner_company
                                AND   ffvv.flex_value_set_id   = ffvs.flex_value_set_id
                                AND   ffvv.enabled_flag        = cv_yes
                                AND   TRUNC(gd_process_date)
                                        BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                            AND TRUNC(NVL(ffvv.end_date_active, gd_process_date))
                                AND   ffvv.flex_value_meaning  =
                                        (
                                         SELECT  flvv.meaning
                                         FROM    fnd_lookup_values_vl  flvv
                                         WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                           AND   TRUNC(gd_process_date)
                                                   BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                       AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                           AND   flvv.enabled_flag  = cv_yes
                                           AND   flvv.lookup_code   =
                                                   (
                                                    SELECT  DECODE(COUNT('x')
                                                              ,0, cv_owner_company_honsya
                                                              ,cv_owner_company_fact
                                                            )
                                                    FROM    xxcmm_cust_accounts   xca
                                                           ,fnd_lookup_values_vl  flvv
                                                    WHERE   xca.customer_id   = cii.owner_party_account_id
                                                      AND   flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                                      AND   flvv.lookup_code  = xca.sale_base_code
                                                      AND   flvv.enabled_flag = cv_yes
                                                      AND   TRUNC(gd_process_date)
                                                              BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                                  AND TRUNC(NVL(flvv.end_date_active, gd_process_date))
                                                   )
                                        )
                             )
                      )
                AND   ROWNUM                             = 1
            )
      AND   EXISTS (
              SELECT  1
              FROM    csi_instance_statuses  cis
              WHERE   cis.instance_status_id   = cii.instance_status_id
                AND   cis.attribute2           = cv_no
                AND   ROWNUM                   = 1
            )
    UNION ALL
    SELECT  /*+ LEADING(xiih) USE_NL(cii cis) */
            cii.instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
           ,csi_instance_statuses  cis
    WHERE   gv_prm_process_div                = cv_prm_div
      AND   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(TO_DATE(gv_prm_process_date, 'YYYY/MM/DD'))
      AND   cii.external_reference            = xiih.install_code
      AND   cis.instance_status_id            = cii.instance_status_id
      AND   cis.attribute2                    = cv_no
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gv_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_jisya_lease
                AND   ROWNUM                  = 1
            )
  ;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h��`
  -- ===============================
  -- INV �H��ԕi�q�֐�R�[�h�擾�p�z���`
  TYPE g_mfg_fctory_cd_rtype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE
   INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  -- INV �H��ԕi�q�֐�R�[�h�擾�p���R�[�h�ϐ�
  g_mfg_fctory_cd_rec  mfg_fctory_cd_cur%ROWTYPE;
  -- INV �H��ԕi�q�֐�R�[�h�擾�p�z��ϐ�
  g_mfg_fctory_cd      g_mfg_fctory_cd_rtype;
  -- �����֘A���擾�p���R�[�h�ϐ�
  g_get_xxcso_ib_info_h_rec get_xxcso_ib_info_h_cur%ROWTYPE;
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
  g_get_target_rec          get_target_cur%ROWTYPE;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
  -- ===============================
  -- ���[�U�[��`�O���[�o����O
  -- ===============================
  g_sql_err_expt         EXCEPTION;  -- SQL�G���[��O
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prof_itoen_cust_name CONSTANT VARCHAR2(100)  := 'XXCSO1_ITOEN_CUST_NAME';   -- �v���t�@�C���E�I�v�V�����F�ɓ����ڋq��
    cv_prof_org_id          CONSTANT VARCHAR2(100)  := 'ORG_ID';   -- �v���t�@�C���E�I�v�V�����F�c�ƒP��
    cv_xxcoi_mfg_fctory_cd  CONSTANT VARCHAR2(100)  := 'XXCOI_MFG_FCTORY_CD';   -- �H��ԕi�q�֐�CD
    -- *** ���[�J���ϐ� ***
    lb_ret_status    BOOLEAN;  -- ���t�����`�F�b�N�֐�RETURN�l�i�[�p
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
    prm_check_expt       EXCEPTION;  -- �p�����[�^�`�F�b�N��O
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
    gn_mfg_fctory_cd_cnt := 0;
--
    -- *** DEBUG_LOG ***
    -- �擾����WHO�J���������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'WHO�J����'               || CHR(10) ||
                 'created_by:'             || TO_CHAR(cn_created_by            ) || CHR(10) ||
                 'creation_date:'          || TO_CHAR(cd_creation_date         ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 'last_updated_by:'        || TO_CHAR(cn_last_updated_by       ) || CHR(10) ||
                 'last_update_date:'       || TO_CHAR(cd_last_update_date      ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 'last_update_login:'      || TO_CHAR(cn_last_update_login     ) || CHR(10) ||
                 'request_id:'             || TO_CHAR(cn_request_id            ) || CHR(10) ||
                 'program_application_id:' || TO_CHAR(cn_program_application_id) || CHR(10) ||
                 'program_id:'             || TO_CHAR(cn_program_id            ) || CHR(10) ||
                 'program_update_date:'    || TO_CHAR(cd_program_update_date   ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- ===========================
    -- �V�X�e�����t�擾����
    -- ===========================
    gd_sys_date := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_1  || CHR(10) ||
                 cv_debug_msg1_2  || TO_CHAR(gd_sys_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    --
    -- ===========================
    -- �p�����[�^�`�F�b�N
    -- ===========================
    -- IN�p�����[�^�̏o�͏���
    IF (
            (gv_prm_process_div IS NOT NULL)
        AND (gv_prm_process_date IS NOT NULL)
       )
    THEN
      -- �p�����[�^�����敪�A�p�����[�^�������s����NULL�ł͂Ȃ��ꍇ
      --
      -- IN�p�����[�^�F�����敪�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_tkn_number_01
                      ,iv_token_name1  => cv_tkn_entry
                      ,iv_token_value1 => gv_prm_process_div
                     );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      -- IN�p�����[�^�F�������s���o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_tkn_number_02
                      ,iv_token_name1  => cv_tkn_value
                      ,iv_token_value1 => gv_prm_process_date
                     );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      -- IN�p�����[�^�F�����敪�̑Ó����`�F�b�N
      IF (gv_prm_process_div NOT IN (cv_prm_normal, cv_prm_div)) THEN
        -- �p�����[�^�����敪��'1','2'�ł͂Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => gv_prm_process_div
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
      --
      -- IN�p�����[�^�F�������s���̏����`�F�b�N
      lb_ret_status := xxcso_util_common_pkg.check_date
                        (
                          iv_date         => gv_prm_process_date
                         ,iv_date_format  => cv_prm_date_format
                        );
      IF (lb_ret_status = cb_false) THEN
        -- ���^�[���X�e�[�^�X��FALSE�ł���ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_tkn_msg_pro_date
                      ,iv_token_name2  => cv_tkn_base_value
                      ,iv_token_value2 => gv_prm_process_date
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
    ELSE
      -- IN�p�����[�^�F�����敪��NULL�`�F�b�N
      IF (gv_prm_process_div IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_tkn_msg_pro_div
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE prm_check_expt;
      END IF;
    END IF;
    --
    -- ===========================
    -- �Ɩ��������t�擾
    -- ===========================
    --
    gd_business_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_3  || CHR(10) ||
                 cv_debug_msg1_4  || TO_CHAR(gd_business_date,'yyyy/mm/dd hh24:mi:ss') ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gd_business_date = NULL) THEN
      -- �Ɩ��������t�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_07             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    --
    -- ===========================
    -- ����������
    -- ===========================
    --
    IF (gv_prm_process_date IS NOT NULL) THEN
      -- �p�����[�^�������s�������͂���Ă���ꍇ
      --
      -- �������Ƀp�����[�^�������s����ݒ肷��
      gd_process_date := TO_DATE(gv_prm_process_date, 'YYYYMMDD HH24:MI:SS');
    ELSE
      --
      -- �������Ƀp�����[�^�������s����ݒ肷��
      gd_process_date := gd_business_date;
    END IF;
    -- *** DEBUG_LOG ***
    -- �擾���������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_5  || CHR(10) ||
                 cv_debug_msg1_6  || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') ||
                  CHR(10) ||
                 ''
    );
    --
    -- ===========================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===========================
    --
    -- �ɓ����ڋq���擾
    gv_itoen_cust_name := FND_PROFILE.VALUE(cv_prof_itoen_cust_name);
    --
    -- *** DEBUG_LOG ***
    -- �擾���������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_7  || CHR(10) ||
                 cv_debug_msg1_8  || gv_itoen_cust_name ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gv_itoen_cust_name = NULL) THEN
      -- �ɓ����ڋq���擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_itoen_acc_nm
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    /* 2009.04.28 T.Mori T1_0758�Ή� START */
    gv_customer_code_dammy := FND_PROFILE.VALUE(cv_prf_cust_cd_dammy);
    IF (gv_customer_code_dammy = NULL) THEN
      -- AFF�ڋq�R�[�h�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_cust_cd_dammy
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    /* 2009.04.28 T.Mori T1_0758�Ή� END */
    --
    -- �c�ƒP�ʎ擾
    gn_org_id := FND_PROFILE.VALUE(cv_prof_org_id);
    --
    -- *** DEBUG_LOG ***
    -- �擾���������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_9  || CHR(10) ||
                 cv_debug_msg1_10 || TO_CHAR(gn_org_id) ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gn_org_id = NULL) THEN
      -- �c�ƒP�ʎ擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_tkn_msg_org_id
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    --
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
    -- IB�������x���擾
    gv_attribute_level := FND_PROFILE.VALUE(cv_attribute_level);
    --
    -- *** DEBUG_LOG ***
    -- �擾���������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_16 || CHR(10) ||
                 cv_debug_msg1_17 || gv_attribute_level ||
                  CHR(10) ||
                 ''
    );
    --
    IF (gv_attribute_level = NULL) THEN
      --IB�������x���擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_attribute_level
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
    -- ===========================
    -- �C���X�^���X�X�e�[�^�XID�擾
    -- ===========================
    --
    BEGIN
      --
      SELECT cis.instance_status_id instance_status_id
      INTO   gn_instance_status_id
      FROM   csi_instance_statuses cis
      WHERE  cis.NAME IN
        (
          SELECT flvv.description
          FROM   fnd_lookup_values_vl flvv
          WHERE  TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
          AND    TRUNC(NVL(flvv.end_date_active, gd_process_date))
          AND    flvv.enabled_flag = cv_yes
          AND    flvv.lookup_code  = cv_delete_code
          AND    flvv.lookup_type  = cv_xxcso1_instance_status
        )
      AND TRUNC(gd_process_date) BETWEEN TRUNC(NVL(cis.start_date_active, gd_process_date))
      AND TRUNC(NVL(cis.end_date_active, gd_process_date))
      ;
    -- *** DEBUG_LOG ***
    -- �擾�����C���X�^���X�X�e�[�^�XID�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1_11 || CHR(10) ||
                 cv_debug_msg1_12 || TO_CHAR(gn_instance_status_id) ||
                  CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �������ʂ��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_status_id
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => cv_tkn_msg_object_del
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_10             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_status_id
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => cv_tkn_msg_object_del
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
    END;
    --
    -- ===========================
    -- INV �H��ԕi�q�֐�R�[�h�擾
    -- ===========================
    --
    BEGIN
      --
      -- �J�[�\���I�[�v��
      OPEN mfg_fctory_cd_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                   cv_debug_msg1_15    || CHR(10)   ||
                   ''
      );
      <<loop_get_mfg_fctory_cd>>
      LOOP
        FETCH mfg_fctory_cd_cur INTO g_mfg_fctory_cd_rec;
        IF (mfg_fctory_cd_cur%ROWCOUNT = 0) THEN
          -- �������ʂ��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_11             --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_task_name
                        ,iv_token_value1 => cv_tkn_msg_lookup_type
                        ,iv_token_name2  => cv_tkn_lookup_type_name
                        ,iv_token_value2 => cv_tkn_msg_inv_henpin
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE g_sql_err_expt;
        END IF;
        EXIT WHEN mfg_fctory_cd_cur%NOTFOUND;
        gn_mfg_fctory_cd_cnt := gn_mfg_fctory_cd_cnt + 1;
        g_mfg_fctory_cd(gn_mfg_fctory_cd_cnt) := g_mfg_fctory_cd_rec.lookup_code;
        -- *** DEBUG_LOG ***
        -- �擾����INV �H��ԕi�q�֐�R�[�h�����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg1_13 || CHR(10) ||
                     cv_debug_msg1_14 || TO_CHAR(g_mfg_fctory_cd_rec.lookup_code) ||
                      CHR(10) ||
                     ''
        );
      END LOOP loop_get_mfg_fctory_cd;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_lookup_type
                      ,iv_token_name2  => cv_tkn_lookup_type_name
                      ,iv_token_value2 => cv_tkn_msg_inv_henpin
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_sql_err_expt;
    END;
    --
    -- �J�[�\���N���[�Y
    CLOSE mfg_fctory_cd_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                 cv_debug_msg1_15    || CHR(10)   ||
                 ''
    );
--
  EXCEPTION
--
    -- �p�����[�^�`�F�b�N��O
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_1  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2 || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (mfg_fctory_cd_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mfg_fctory_cd_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msg1_15    || CHR(10)   ||
                     ''
        );
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
/* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--  /**********************************************************************************
--   * Procedure Name   : get_po_number
--   * Description      : �����ԍ����o(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_po_number(
--     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
--    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
--    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_po_number';     -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
--    -- *** ���[�J���ϐ� ***
--    -- *** ���[�J���E���R�[�h ***
--    -- *** ���[�J���E�J�[�\�� ***
--    -- *** ���[�J����O ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
----
--    -- ========================================
--    -- �����ԍ����o
--    -- ========================================
--    BEGIN
--    --
--      /* 2009.05.20 K.Satomura T1_1095�Ή� START */
--      --SELECT xiwd.po_number
--      SELECT MAX(xiwd.po_number)
--      /* 2009.05.20 K.Satomura T1_1095�Ή� END */
--      INTO   gn_po_number
--      FROM   xxcso_in_work_data xiwd
--      WHERE  xiwd.install_code1           = g_get_xxcso_ib_info_h_rec.object_code -- �����R�[�h
--      AND    xiwd.job_kbn                 IN (cv_job_kbn_set, cv_job_kbn_change)  -- ��Ƌ敪
--      AND    xiwd.completion_kbn          = cv_comp_kbn_ok                        -- �����敪
--      AND    xiwd.install1_processed_flag = cv_yes                                -- ����1�����σt���O
--      /* 2009.04.08 K.Satomura T1_0372�Ή� START */
--      /* 2009.05.20 K.Satomura T1_1095�Ή� START */
--      --GROUP BY xiwd.po_number
--      /* 2009.05.20 K.Satomura T1_1095�Ή� END */
--      /* 2009.04.08 K.Satomura T1_0372�Ή� END */
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        -- �������ʂ�0���ł���ꍇ
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
--                      ,iv_name         => cv_tkn_number_20             --���b�Z�[�W�R�[�h
--                      ,iv_token_name1  => cv_tkn_task_name
--                      ,iv_token_value1 => cv_tkn_msg_po_num
--                      ,iv_token_name2  => cv_tkn_bukken
--                      ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
--                     );
--        lv_errbuf := lv_errmsg || SQLERRM;
--        ov_retcode := cv_status_warn;
--        RAISE g_sql_err_expt;
--      WHEN OTHERS THEN
--        -- SQL�G���[�����������ꍇ
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
--                      ,iv_name         => cv_tkn_number_21             --���b�Z�[�W�R�[�h
--                      ,iv_token_name1  => cv_tkn_task_name
--                      ,iv_token_value1 => cv_tkn_msg_po_num
--                      ,iv_token_name2  => cv_tkn_bukken
--                      ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
--                      ,iv_token_name3  => cv_tkn_err_msg
--                      ,iv_token_value3 => SQLERRM
--                     );
--        lv_errbuf := lv_errmsg || SQLERRM;
--        ov_retcode := cv_status_error;
--        RAISE g_sql_err_expt;
--    END;
----
--    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000334) START */
--    /* 2009.05.20 K.Satomura T1_1095�Ή� START */
--    --IF (gn_po_number IS NULL) THEN
--    --  -- �������ʂ�0���ł���ꍇ
--    --  lv_errmsg := xxccp_common_pkg.get_msg(
--    --                 iv_application  => cv_app_name      --�A�v���P�[�V�����Z�k��
--    --                ,iv_name         => cv_tkn_number_20 --���b�Z�[�W�R�[�h
--    --                ,iv_token_name1  => cv_tkn_task_name
--    --                ,iv_token_value1 => cv_tkn_msg_po_num
--    --                ,iv_token_name2  => cv_tkn_bukken
--    --                ,iv_token_value2 => g_get_xxcso_ib_info_h_rec.object_code
--    --               );
--    --  --
--    --  lv_errbuf := lv_errmsg || SQLERRM;
--    --  ov_retcode := cv_status_warn;
--    --  RAISE g_sql_err_expt;
--    --  --
--    --END IF;
--    /* 2009.05.20 K.Satomura T1_1095�Ή� END */
--    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000334) END */
----
--  EXCEPTION
----
--    -- SQL�G���[��O
--    WHEN g_sql_err_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      --
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      ov_retcode := cv_status_error;
----
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
--      ov_retcode := cv_status_error;
----
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END get_po_number;
/* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
--
  /**********************************************************************************
   * Procedure Name   : get_type_info
   * Description      : �@���񒊏o(A-4)
   ***********************************************************************************/
  PROCEDURE get_type_info(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_type_info';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- �@���񒊏o
    -- ========================================
    BEGIN
    --
      SELECT xxcso_util_common_pkg.get_lookup_meaning(
                cv_xxcso_csi_maker_code
               ,punv.attribute2
               ,gd_process_date
              ) manufacturer_name     -- �V_���[�J�[��
            ,punv.attribute3 age_type -- �V_�N��
      INTO   gv_manufacturer_name
            ,gv_age_type
      FROM   po_un_numbers_vl punv -- ���A�ԍ��}�X�^�r���[
      WHERE  punv.un_number = g_get_xxcso_ib_info_h_rec.new_model -- ���A�ԍ�
      /* 2009.08.19 K.Satomura 0001051�Ή� START */
      --AND    TRUNC(NVL(punv.inactive_date, gd_process_date + 1)) > TRUNC(gd_process_date) -- ��Ƌ敪
      /* 2009.08.19 K.Satomura 0001051�Ή� START */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �������ʂ�0���ł���ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_13             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_model
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_tkn_msg_model_cd
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.new_model
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_14             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_model
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_tkn_msg_model_cd
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.new_model
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_type_info;
--
  /**********************************************************************************
   * Procedure Name   : get_acct_info
   * Description      : �ڋq�֘A��񒊏o(A-5)
   ***********************************************************************************/
  PROCEDURE get_acct_info(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_acct_info';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_owner_company_flg        VARCHAR2(1);  -- �{�Ё^�H��t���O
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
  /* 2009.04.28 T.Mori T1_0758�Ή� START */
    lv_customer_class_code      xxcso_cust_acct_sites_v.customer_class_code%TYPE;   -- �V_�ڋq�敪�R�[�h
  /* 2009.04.28 T.Mori T1_0758�Ή� END */
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
    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
    ---- ========================================
    ---- �ڋq�֘A��񒊏o
    ---- ========================================
    --BEGIN
    ----
    --  SELECT xcasv.sale_base_code        new_department_code      -- �V_���_�R�[�h
    --        ,xcasv.established_site_name new_installation_place   -- �V_�ݒu�於
    --        ,xcasv.state    ||
    --         xcasv.city     ||
    --         xcasv.ADDRESS1 ||
    --         xcasv.ADDRESS2              new_installation_address -- �V_�ݒu��Z��
    --        ,xcasv.account_number        new_customer_code        -- �V_�ڋq�R�[�h
    --       /* 2009.04.28 T.Mori T1_0758�Ή� START */
    --        ,xcasv.customer_class_code   new_customer_class_code  -- �V_�ڋq�敪�R�[�h
    --       /* 2009.04.28 T.Mori T1_0758�Ή� END */
    --  INTO   gv_department_code      -- �V_���_�R�[�h
    --        ,gv_installation_place   -- �V_�ݒu�於
    --        ,gv_installation_address -- �V_�ݒu��Z��
    --        ,gv_customer_code        -- �V_�ڋq�R�[�h
    --        /* 2009.04.28 T.Mori T1_0758�Ή� START */
    --        ,lv_customer_class_code  -- �V_�ڋq�敪�R�[�h
    --        /* 2009.04.28 T.Mori T1_0758�Ή� END */
    --  FROM   xxcso_cust_acct_sites_v xcasv  -- �ڋq�}�X�^�T�C�g�r���[
    --  WHERE  xcasv.cust_account_id   = g_get_xxcso_ib_info_h_rec.owner_party_account_id -- �A�J�E���gID
    --  AND    xcasv.account_status    = cv_cut_enb_status                                -- �A�J�E���g�X�e�[�^�X
    --  AND    xcasv.acct_site_status  = cv_cut_enb_status                                -- �ڋq���ݒn�X�e�[�^�X
    --  AND    xcasv.party_status      = cv_cut_enb_status                                -- �p�[�e�B�X�e�[�^�X
    --  AND    xcasv.party_site_status = cv_cut_enb_status                                -- �p�[�e�B�T�C�g�X�e�[�^�X
    --  ;
    --EXCEPTION
    --  WHEN NO_DATA_FOUND THEN
    --    -- �������ʂ�0���ł���ꍇ
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                   iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
    --                  ,iv_name         => cv_tkn_number_13             --���b�Z�[�W�R�[�h
    --                  ,iv_token_name1  => cv_tkn_task_name
    --                  ,iv_token_value1 => cv_tkn_msg_acct_info
    --                  ,iv_token_name2  => cv_tkn_item
    --                  ,iv_token_value2 => cv_tkn_msg_account_id
    --                  ,iv_token_name3  => cv_tkn_base_value
    --                  ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.owner_party_account_id
    --                 );
    --    lv_errbuf := lv_errmsg || SQLERRM;
    --    ov_retcode := cv_status_warn;
    --    RAISE g_sql_err_expt;
    --  WHEN OTHERS THEN
    --    -- SQL�G���[�����������ꍇ
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                   iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
    --                  ,iv_name         => cv_tkn_number_14             --���b�Z�[�W�R�[�h
    --                  ,iv_token_name1  => cv_tkn_task_name
    --                  ,iv_token_value1 => cv_tkn_msg_acct_info
    --                  ,iv_token_name2  => cv_tkn_item
    --                  ,iv_token_value2 => cv_tkn_msg_account_id
    --                  ,iv_token_name3  => cv_tkn_base_value
    --                  ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.owner_party_account_id
    --                  ,iv_token_name4  => cv_tkn_err_msg
    --                  ,iv_token_value4 => SQLERRM
    --                 );
    --    lv_errbuf := lv_errmsg || SQLERRM;
    --    ov_retcode := cv_status_error;
    --    RAISE g_sql_err_expt;
    --END;
    lv_customer_class_code := g_get_xxcso_ib_info_h_rec.new_customer_class_code;
    /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
    /* 2009.04.28 T.Mori T1_0758�Ή� START */
    IF (lv_customer_class_code <> cv_cust_class_10) THEN
      gv_customer_code := gv_customer_code_dammy;
    END IF;
    /* 2009.04.28 T.Mori T1_0758�Ή� END */
--
    -- ========================================
    -- �{�Ё^�H��敪�̒��o
    -- ========================================
    --
    -- �H��ԕi�q�֐�R�[�h���݃`�F�b�N
    --
    -- �V_�{�Ё^�H��敪�Ƀf�t�H���g�l�i�u'1'�F�{�Ёv�j��ݒ�
    lv_owner_company_flg := cv_owner_company_honsya;
    --
    <<loop_mfg_fctory_cd_chk>>
    FOR i IN 1..gn_mfg_fctory_cd_cnt LOOP
    --
      IF (gv_department_code = g_mfg_fctory_cd(i)) THEN
      -- ���o�����V_���_�R�[�h��A-1�Ŏ擾�����H��ԕi�q�֐�R�[�h�ƈ�v����ꍇ
      -- �V_�{�Ё^�H��敪�Ɂu'2'�F�H��v��ݒ�
        lv_owner_company_flg := cv_owner_company_fact;
      END IF;
    END LOOP loop_mfg_fctory_cd_chk;
    --
    BEGIN
    --
      SELECT ffvv.flex_value new_owner_company -- �V_�{�Ё^�H��敪
      INTO   gv_owner_company -- �V_�{�Ё^�H��敪
      FROM   fnd_flex_values_vl ffvv  -- �l�Z�b�g�l�r���[
            ,fnd_flex_value_sets ffvs -- �l�Z�b�g
      WHERE  ffvv.flex_value_set_id   = ffvs.flex_value_set_id  -- �l�Z�b�gID
      AND    ffvs.flex_value_set_name = cv_xxcff_owner_company  -- �l�Z�b�g��
      AND    ffvv.enabled_flag        = cv_yes  -- �g�p�\�t���O
      AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
      AND    TRUNC(NVL(ffvv.end_date_active, gd_process_date)) -- �L������
      AND    ffvv.flex_value_meaning =
        (
          SELECT flvv.meaning meaning  -- ���e�i�{�Ё^�H��j
          FROM   fnd_lookup_values_vl flvv  -- �N�C�b�N�R�[�h
          WHERE  flvv.lookup_type = cv_xxcso1_owner_company  -- �^�C�v
          AND    TRUNC(gd_process_date) BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
          AND    TRUNC(NVL(flvv.end_date_active, gd_process_date)) -- �L������
          AND    flvv.lookup_code = lv_owner_company_flg  -- �{�Ё^�H��t���O
          AND    flvv.enabled_flag = cv_yes  -- �g�p�\�t���O
        )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �������ʂ�0���ł���ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_value_set
                      ,iv_token_name2  => cv_tkn_value_set_name
                      ,iv_token_value2 => cv_tkn_msg_owner_comp
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_16             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => cv_tkn_msg_value_set
                      ,iv_token_name2  => cv_tkn_value_set_name
                      ,iv_token_value2 => cv_tkn_msg_owner_comp
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_acct_info;
--
  /**********************************************************************************
   * Procedure Name   : ib_info_change_chk
   * Description      : �����֘A���ύX�`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE ib_info_change_chk(
     ov_change_flg       OUT        VARCHAR2   -- �ύX�`�F�b�N�t���O�i�ύX����FY�^�ύX�Ȃ��FN�j
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ib_info_change_chk';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- �����֘A���ύX�`�F�b�N����
    -- ========================================
    --
    -- �ύX�`�F�b�N�t���O�Ƀf�t�H���g�l�iY�j��ݒ�
    ov_change_flg := cv_yes;
    --
    IF (
        /* 2009.04.08 K.Satomura T1_0403�Ή� START*/
        --    (
        --       g_get_xxcso_ib_info_h_rec.old_po_number
        --     = gn_po_number                                                       -- �����ԍ�
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_manufacturer_name
        --     = gv_manufacturer_name                                               -- ���[�J�[��
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_age_type
        --     = gv_age_type                                                        -- �N��
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_model
        --     = g_get_xxcso_ib_info_h_rec.new_model                                -- �@��
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_serial_number       , cv_null)
        --     = NVL(g_get_xxcso_ib_info_h_rec.new_serial_number       , cv_null)   -- �@��
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_quantity
        --     = g_get_xxcso_ib_info_h_rec.new_quantity                             -- ����
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_department_code     , cv_null)
        --     = NVL(gv_department_code                                , cv_null)   -- ���_�R�[�h
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_owner_company
        --     = gv_owner_company                                                   -- �{�Ё^�H��敪
        --    )
        --AND (
        --       NVL(g_get_xxcso_ib_info_h_rec.old_installation_place  , cv_null)
        --     = NVL(gv_installation_place                             , cv_null)   -- �ݒu�於
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_installation_address
        --     = gv_installation_address                                            -- �ݒu��Z��
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_active_flag
        --     = g_get_xxcso_ib_info_h_rec.new_active_flag                          -- �_���폜�t���O
        --    )
        --AND (
        --       g_get_xxcso_ib_info_h_rec.old_customer_code
        --     = gv_customer_code                                                   -- �ڋq�R�[�h
        --    )
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� MOD START */
--            (
--               NVL(g_get_xxcso_ib_info_h_rec.old_po_number, cn_zero)
--             = NVL(gn_po_number, cn_zero) -- �����ԍ�
--            )
--        AND (
            (
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� MOD END   */
               NVL(g_get_xxcso_ib_info_h_rec.old_manufacturer_name, cv_null)
             = NVL(gv_manufacturer_name, cv_null) -- ���[�J�[��
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_age_type, cv_null)
             = NVL(gv_age_type, cv_null) -- �N��
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_model, cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_model , cv_null) -- �@��
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_serial_number , cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_serial_number , cv_null) -- �@��
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_quantity, cn_zero)
             = NVL(g_get_xxcso_ib_info_h_rec.new_quantity, cn_zero) -- ����
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_department_code, cv_null)
             = NVL(gv_department_code, cv_null) -- ���_�R�[�h
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_owner_company, cv_null)
             = NVL(gv_owner_company, cv_null)-- �{�Ё^�H��敪
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_installation_place, cv_null)
             = NVL(gv_installation_place, cv_null) -- �ݒu�於
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_installation_address, cv_null)
             = NVL(gv_installation_address, cv_null)-- �ݒu��Z��
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_active_flag, cv_null)
             = NVL(g_get_xxcso_ib_info_h_rec.new_active_flag, cv_null) -- �_���폜�t���O
            )
        AND (
               NVL(g_get_xxcso_ib_info_h_rec.old_customer_code, cv_null)
             = NVL(gv_customer_code, cv_null)-- �ڋq�R�[�h
            )
        /* 2009.04.08 K.Satomura T1_0403�Ή� END*/
       ) THEN
      -- �ύX���ڂ����݂��Ȃ��ꍇ�ύX�`�F�b�N�t���O��N��ݒ�
      ov_change_flg := cv_no;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ib_info_change_chk;
--
  /**********************************************************************************
   * Procedure Name   : xxcff_vd_object_if_chk
   * Description      : ���̋@SH�����C���^�t�F�[�X���݃`�F�b�N(A-7)
   ***********************************************************************************/
  PROCEDURE xxcff_vd_object_if_chk(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'xxcff_vd_object_if_chk';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_data_cnt           NUMBER;  -- �����J�E���g
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- ���̋@SH�����C���^�t�F�[�X���ݔ���
    -- ========================================
    BEGIN
    --
      SELECT COUNT(xvoi.object_code)
      INTO   ln_data_cnt
      FROM   xxcff_vd_object_if xvoi -- ���̋@SH�����C���^�t�F�[�X
      WHERE  xvoi.object_code = g_get_xxcso_ib_info_h_rec.object_code -- �����R�[�h
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_17             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_vd_object_if
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_select
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
    --
    IF (ln_data_cnt > 0) THEN
      -- �擾������0�ȏ�ł���ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_18             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_bukken
                    ,iv_token_value1 => g_get_xxcso_ib_info_h_rec.object_code
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      ov_retcode := cv_status_warn;
      RAISE g_sql_err_expt;
    END IF;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END xxcff_vd_object_if_chk;
--
  /**********************************************************************************
   * Procedure Name   : xxcso_ib_info_h_lock
   * Description      : �����֘A�ύX�����e�[�u�����b�N(A-8)
   ***********************************************************************************/
  PROCEDURE xxcso_ib_info_h_lock(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'xxcso_ib_info_h_lock';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    lv_install_code       xxcso_ib_info_h.install_code%TYPE;  -- �����R�[�h
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- �����֘A�ύX�����e�[�u�����b�N����
    -- ========================================
    BEGIN
    --
      SELECT xiih.install_code -- �����R�[�h
      INTO   lv_install_code
      FROM   xxcso_ib_info_h xiih -- �����֘A���ύX�����e�[�u��
      WHERE  xiih.install_code = g_get_xxcso_ib_info_h_rec.object_code -- �����R�[�h
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �������ʂ�0���ł���ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_17             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_select
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_17             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_lock
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_error;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END xxcso_ib_info_h_lock;
--
  /**********************************************************************************
   * Procedure Name   : insert_xxcff_vd_object_if
   * Description      : ���̋@SH�����C���^�t�F�[�X�o�^����(A-10)
   ***********************************************************************************/
  PROCEDURE insert_xxcff_vd_object_if(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_xxcff_vd_object_if';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- ���̋@SH�����C���^�t�F�[�X�o�^����
    -- ========================================
    BEGIN
    --
      INSERT INTO xxcff_vd_object_if(
         object_code                                 -- �����R�[�h
        ,generation_date                             -- ������
        ,lease_class                                 -- ���[�X���
        ,po_number                                   -- �����ԍ�
        ,manufacturer_name                           -- ���[�J�[��
        ,age_type                                    -- �N��
        ,model                                       -- �@��
        ,serial_number                               -- �@��
        ,quantity                                    -- ����
        ,department_code                             -- �Ǘ�����R�[�h
        ,owner_company                               -- �{�ЍH��敪
        ,installation_place                          -- ���ݒu��
        ,installation_address                        -- ���ݒu�ꏊ
        ,active_flag                                 -- �����L���t���O
        ,import_status                               -- �捞�X�e�[�^�X
        ,customer_code                               -- �ڋq�R�[�h
        ,group_id                                    -- �O���[�vID
        ,created_by                                  -- �쐬��
        ,creation_date                               -- �쐬��
        ,last_updated_by                             -- �ŏI�X�V��
        ,last_update_date                            -- �ŏI�X�V��
        ,last_update_login                           -- �ŏI�X�V���O�C��
        ,request_id                                  -- �v��ID
        ,program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                                  -- �R���J�����g�E�v���O����ID
        ,program_update_date                         -- �v���O�����X�V��
      ) VALUES(
         g_get_xxcso_ib_info_h_rec.object_code       -- �����R�[�h
        ,gd_process_date                             -- ������
        ,g_get_xxcso_ib_info_h_rec.lease_class       -- ���[�X���
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� MOD START */
--        ,gn_po_number                                -- �����ԍ�
        ,NULL                                        -- �����ԍ�
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� MOD END   */
        ,gv_manufacturer_name                        -- ���[�J�[��
        ,gv_age_type                                 -- �N��
        ,g_get_xxcso_ib_info_h_rec.new_model         -- �@��
        ,g_get_xxcso_ib_info_h_rec.new_serial_number -- �@��
        ,g_get_xxcso_ib_info_h_rec.new_quantity      -- ����
        ,gv_department_code                          -- �Ǘ�����R�[�h
        ,gv_owner_company                            -- �{�ЍH��敪
        /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
        --,gv_installation_place                       -- ���ݒu��
        ,SUBSTRB(gv_installation_place, 1, 50)       -- ���ݒu��
        /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
        ,gv_installation_address                     -- ���ݒu�ꏊ
        /* 2009.04.01 K.Satomura T1_0149�Ή� START */
        --,g_get_xxcso_ib_info_h_rec.new_active_flag   -- �����L���t���O
        ,g_get_xxcso_ib_info_h_rec.effective_flag    -- �����L���t���O
        /* 2009.04.01 K.Satomura T1_0149�Ή� END */
        ,cv_import_status                            -- �捞�X�e�[�^�X�i�Œ�l�F'0'�j
        ,gv_customer_code                            -- �ڋq�R�[�h
        ,NULL                                        -- �O���[�vID
        ,cn_created_by                               -- �쐬��
        ,cd_creation_date                            -- �쐬��
        ,cn_last_updated_by                          -- �ŏI�X�V��
        ,cd_last_update_date                         -- �ŏI�X�V��
        ,cn_last_update_login                        -- �ŏI�X�V���O�C��
        ,cn_request_id                               -- �v��ID
        ,cn_program_application_id                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                               -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date                      -- �v���O�����X�V��
      )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_17             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_vd_object_if
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_insert
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_xxcff_vd_object_if;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcso_ib_info_h
   * Description      : �����֘A���ύX�����e�[�u���X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE update_xxcso_ib_info_h(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_xxcso_ib_info_h';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    -- ========================================
    -- �����֘A���ύX�����e�[�u���X�V����
    -- ========================================
    BEGIN
    --
      UPDATE xxcso_ib_info_h
      SET    history_creation_date   = gd_process_date                             -- �����쐬��
            ,interface_flag          = cv_yes                                      -- �A�g�σt���O
            /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--            ,po_number               = gn_po_number                                -- �����ԍ�
            /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
            ,manufacturer_name       = gv_manufacturer_name                        -- ���[�J�[��
            ,age_type                = gv_age_type                                 -- �N��
            ,un_number               = g_get_xxcso_ib_info_h_rec.new_model         -- �@��
            ,install_number          = g_get_xxcso_ib_info_h_rec.new_serial_number -- �@��
            ,quantity                = g_get_xxcso_ib_info_h_rec.new_quantity      -- ����
            ,base_code               = gv_department_code                          -- ���_�R�[�h
            ,owner_company_type      = gv_owner_company                            -- �{�Ё^�H��敪
            ,install_name            = gv_installation_place                       -- �ݒu�於
            ,install_address         = gv_installation_address                     -- �ݒu��Z��
            ,logical_delete_flag     = g_get_xxcso_ib_info_h_rec.new_active_flag   -- �_���폜�t���O
            ,account_number          = gv_customer_code                            -- �ڋq�R�[�h
            /* 2009.04.03 K.Satomura T1_0269�Ή� START */
            ,last_updated_by         = cn_last_updated_by                          -- �ŏI�X�V��
            ,last_update_date        = cd_last_update_date                         -- �ŏI�X�V��
            ,last_update_login       = cn_last_update_login                        -- �ŏI�X�V���O�C��
            ,request_id              = cn_request_id                               -- �v��ID
            ,program_application_id  = cn_program_application_id                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id              = cn_program_id                               -- �R���J�����g�E�v���O����ID
            ,program_update_date     = cd_program_update_date                      -- �v���O�����X�V��
            /* 2009.04.03 K.Satomura T1_0269�Ή� END */
      WHERE  install_code = g_get_xxcso_ib_info_h_rec.object_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- SQL�G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_17             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_tkn_msg_ib_info_h
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => cv_tkn_msg_update
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        ov_retcode := cv_status_warn;
        RAISE g_sql_err_expt;
    END;
--
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      --
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
    cv_base_split_flag       CONSTANT VARCHAR2(1)   := '1';
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
    -- *** ���[�J���ϐ� ***
    lv_change_flg            VARCHAR2(1);  -- �ύX�`�F�b�N�t���O
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
    lv_exists_flg            VARCHAR2(1);    -- �ڋq�ڍs���݃t���O
    lv_msg_tkn_1             VARCHAR2(100);  --���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2             VARCHAR2(100);  --���b�Z�[�W�g�[�N���擾�p2
    lv_msg_tkn_4             VARCHAR2(100);  --���b�Z�[�W�g�[�N���擾�p4
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
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
    gn_target_cnt := 0;  -- �Ώی���
    gn_normal_cnt := 0;  -- ���팏��
    gn_error_cnt  := 0;  -- �G���[����
    gn_warn_cnt   := 0;  -- �X�L�b�v����
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
    -- ========================================
    -- A-2-0.���o�Ώە����擾
    -- ========================================
    OPEN get_target_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                 cv_debug_msgsub_0   || CHR(10)   ||
                 ''
    );
    --
    <<loop_get_target>>
    LOOP
      BEGIN
        FETCH get_target_cur INTO g_get_target_rec;
      EXCEPTION
        WHEN OTHERS THEN
          -- SQL�G���[�����������ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_19             --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_tkn_msg_target
                        ,iv_token_name2  => cv_tkn_err_msg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE g_sql_err_expt;
      END;
      EXIT WHEN get_target_cur%NOTFOUND
              OR get_target_cur%ROWCOUNT = 0;
--
      -- �Ώی����̎擾
      gn_target_cnt := get_target_cur%ROWCOUNT;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
      -- ========================================
      -- A-2-1.�����֘A��񒊏o
      -- ========================================
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--    OPEN get_xxcso_ib_info_h_cur;
      OPEN get_xxcso_ib_info_h_cur(g_get_target_rec.instance_id);
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || CHR(10)   ||
                   cv_debug_msgsub_1   || CHR(10)   ||
                   ''
      );
      --
      <<loop_get_xxcso_ib_info>>
      LOOP
        /* 2009.04.07 K.Satomura T1_0378�Ή� START */
        lv_change_flg := NULL;
        lv_retcode    := cv_status_normal;
        /* 2009.04.07 K.Satomura T1_0378�Ή� END */
        /* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
        lv_exists_flg := cv_no;
        /* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
        BEGIN
          FETCH get_xxcso_ib_info_h_cur INTO g_get_xxcso_ib_info_h_rec;
        EXCEPTION
          WHEN OTHERS THEN
            -- SQL�G���[�����������ꍇ
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_19             --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table
                          ,iv_token_value1 => cv_tkn_msg_ib_info
                          ,iv_token_name2  => cv_tkn_err_msg
                          ,iv_token_value2 => SQLERRM
                         );
            lv_errbuf := lv_errmsg || SQLERRM;
            RAISE g_sql_err_expt;
        END;
        EXIT WHEN get_xxcso_ib_info_h_cur%NOTFOUND
                OR get_xxcso_ib_info_h_cur%ROWCOUNT = 0;
        --
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
        -- �Ώی����̎擾
        --gn_target_cnt := get_xxcso_ib_info_h_cur%ROWCOUNT;
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
--
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
        -- ========================================
        -- A-13.�ڋq�ڍs�`�F�b�N����
        -- ========================================
        BEGIN
          SELECT cv_yes exists_flg
          INTO   lv_exists_flg
          FROM   xxcok_cust_shift_info xcsi  -- �ڋq�ڍs���e�[�u��
          WHERE  xcsi.cust_code        = g_get_xxcso_ib_info_h_rec.new_customer_code    -- �Ώیڋq
          AND    xcsi.cust_shift_date  = gd_process_date + 1                            -- �Ɩ����t�̗������ڍs���ƂȂ��Ă���
          AND    xcsi.base_split_flag  = cv_base_split_flag                             -- �\�񔄏㋒�_�R�[�h���f��
          AND    xcsi.new_base_code    = g_get_xxcso_ib_info_h_rec.new_department_code  -- ���㋒�_�������ɕR�t���ڋq�̔��㋒�_�Ɠ���
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_exists_flg := cv_no;
          WHEN OTHERS THEN
            -- �g�[�N���擾
            lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_23        -- �ڋq�ڍs���e�[�u��(�Œ�)
                             );
            lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_24        -- �����R�[�h(�Œ�)
                             );
            lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_25        -- �ڋq�R�[�h(�Œ�)
                             );
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_22            -- ���o�G���[���b�Z�[�W(�L�[�t��)
                          ,iv_token_name1  => cv_tkn_task_name
                          ,iv_token_value1 => lv_msg_tkn_1
                          ,iv_token_name2  => cv_tkn_key
                          ,iv_token_value2 => lv_msg_tkn_2
                          ,iv_token_name3  => cv_tkn_key_value
                          ,iv_token_value3 => g_get_xxcso_ib_info_h_rec.object_code         -- �����R�[�h
                          ,iv_token_name4  => cv_tkn_item
                          ,iv_token_value4 => lv_msg_tkn_4
                          ,iv_token_name5  => cv_tkn_base_value
                          ,iv_token_value5 => g_get_xxcso_ib_info_h_rec.new_customer_code   -- �ڋq�R�[�h
                          ,iv_token_name6  => cv_tkn_err_msg
                          ,iv_token_value6 => SQLERRM
                         );
            lv_errbuf := lv_errmsg;
            RAISE g_sql_err_expt;
        END;
--
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
        /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) START */
        -- �ڋq�֘A����ޔ�
        gv_department_code      := g_get_xxcso_ib_info_h_rec.new_department_code;
        gv_installation_place   := g_get_xxcso_ib_info_h_rec.new_installation_place;
        gv_installation_address := g_get_xxcso_ib_info_h_rec.new_installation_address;
        gv_customer_code        := g_get_xxcso_ib_info_h_rec.new_customer_code;
        /* 2009.07.02 K.Satomura �����e�X�g��Q�Ή�(0000229) END */
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--        -- ========================================
--        -- A-3.�����ԍ����o
--        -- ========================================
--        /* 2009.04.07 D.Abe T1_0339�Ή� START */
--        gn_po_number := NULL;
--        IF (g_get_xxcso_ib_info_h_rec.newold_flag = cv_no
--          OR g_get_xxcso_ib_info_h_rec.newold_flag IS NULL)
--        THEN
--        /* 2009.04.07 D.Abe T1_0339�Ή� END */
--          get_po_number(
--             ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
--            ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
--            ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--          );
--        /* 2009.04.07 D.Abe T1_0339�Ή� START */
--        ELSE
--          lv_retcode := cv_status_normal;
--        END IF;
--        /* 2009.04.07 D.Abe T1_0339�Ή� END */
----
--        IF (lv_retcode = cv_status_error) THEN
--          RAISE global_process_expt;
--        ELSIF (lv_retcode = cv_status_warn) THEN
--          -- �X�L�b�v����
--          gn_warn_cnt   := gn_warn_cnt + 1;
--          -- �Œ�X�e�[�^�X�ݒ�i�x���j
--          ov_retcode := cv_status_warn;
--          --�x���o��
--          fnd_file.put_line(
--             which  => FND_FILE.OUTPUT
--            ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
--          );
--          fnd_file.put_line(
--             which  => FND_FILE.LOG
--            ,buff   => lv_errmsg                  --�x�����b�Z�[�W
--          );
--        ELSE
       /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END    */
--
          -- ========================================
          -- A-4.�@���񒊏o
          -- ========================================
          get_type_info(
             ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            -- �X�L�b�v����
            gn_warn_cnt   := gn_warn_cnt + 1;
            -- �Œ�X�e�[�^�X�ݒ�i�x���j
            ov_retcode := cv_status_warn;
            --�x���o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg                  --�x�����b�Z�[�W
            );
          ELSE
--
            -- ========================================
            -- A-5.�ڋq�֘A��񒊏o
            -- ========================================
            get_acct_info(
               ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
              ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
              ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
--
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            ELSIF (lv_retcode = cv_status_warn) THEN
              -- �X�L�b�v����
              gn_warn_cnt   := gn_warn_cnt + 1;
              -- �Œ�X�e�[�^�X�ݒ�i�x���j
              ov_retcode := cv_status_warn;
              --�x���o��
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
              );
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg                  --�x�����b�Z�[�W
              );
            ELSE
--
              /* 2009.05.26 D.Abe T1_1042�Ή� START */
              /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� START */
              -- �����敪��1�ŏ������t�����͍ς�
              IF (gv_prm_process_div = cv_prm_normal )
                  AND  (gv_prm_process_date IS NOT NULL) THEN
                lv_change_flg := cv_yes;
              ELSE
              ---- �����敪���Q�̂ݑΏۂƂ���
              --IF (gv_prm_process_div = cv_prm_div) THEN
              /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� END */
              /* 2009.05.26 D.Abe T1_1042�Ή� END */
                -- ========================================
                -- A-6.�����֘A���ύX�`�F�b�N����
                -- ========================================
                /* 2009.04.01 K.Satomura T1_0148�Ή� START */
                /* 2009.04.07 K.Satomura T1_0378�Ή� START */
                --IF (g_get_xxcso_ib_info_h_rec.interface_flag <> cv_yes) THEN
                IF (g_get_xxcso_ib_info_h_rec.interface_flag = cv_yes) THEN
                /* 2009.04.07 K.Satomura T1_0378�Ή� END */
                  -- �A�g�σt���O��Y�̏ꍇ
                /* 2009.04.01 K.Satomura T1_0148�Ή� END */
                  ib_info_change_chk(
                     ov_change_flg => lv_change_flg    -- �ύX�`�F�b�N�t���O
                    ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
                    ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
                    ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                  );
                /* 2009.04.01 K.Satomura T1_0148�Ή� START */
                END IF;
                /* 2009.04.01 K.Satomura T1_0148�Ή� END */
                --
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                --
              /* 2009.05.26 D.Abe T1_1042�Ή� START */
              /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� START */
              --ELSIF ((gv_prm_process_div = cv_prm_normal)
              --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_yes)) THEN
              --  -- �����敪���P�ŘA�g�ς�
              --  lv_change_flg := cv_yes;
              --ELSE
              --  -- �����敪���P�Ŗ��A�g
              --  NULL;
              /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� END */
              END IF;
              /* 2009.05.26 D.Abe T1_1042�Ή� END */
              /* 2009.04.07 K.Satomura T1_0378�Ή� START */
              IF (lv_change_flg IS NOT NULL) THEN
              /* 2009.04.07 K.Satomura T1_0378�Ή� END */
                IF (lv_change_flg = cv_no) THEN
                  -- �X�L�b�v����
                  gn_warn_cnt   := gn_warn_cnt + 1;
                ELSE
                  -- ���ڂ��ύX����Ă���ꍇ
--
                  -- ========================================
                  -- A-7.���̋@SH�����C���^�t�F�[�X���݃`�F�b�N
                  -- ========================================
                  xxcff_vd_object_if_chk(
                     ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
                    ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
                    ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                  );
--
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_process_expt;
                  ELSIF (lv_retcode = cv_status_warn) THEN
                    -- �X�L�b�v����
                    gn_warn_cnt   := gn_warn_cnt + 1;
                    -- �Œ�X�e�[�^�X�ݒ�i�x���j
                    ov_retcode := cv_status_warn;
                    --�x���o��
                    fnd_file.put_line(
                       which  => FND_FILE.OUTPUT
                      ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
                    );
                    fnd_file.put_line(
                       which  => FND_FILE.LOG
                      ,buff   => lv_errmsg                  --�x�����b�Z�[�W
                    );
                /* 2009.04.01 K.Satomura T1_0148�Ή� START */
                  --ELSE
                  END IF;
                END IF;
                /* 2009.04.01 K.Satomura T1_0148�Ή� END */
                  -- ���̋@SH�����C���^�t�F�[�X�ɓo�^�Ώە��������݂��Ȃ��ꍇ
              /* 2009.04.07 K.Satomura T1_0378�Ή� START */
              END IF;
              /* 2009.04.07 K.Satomura T1_0378�Ή� END */
--
              /* 2009.04.01 K.Satomura T1_0148�Ή� START */
              IF (((NVL(lv_change_flg, cv_yes) <> cv_no)
                OR (g_get_xxcso_ib_info_h_rec.interface_flag <> cv_yes))
                AND (lv_retcode = cv_status_normal))
              THEN
              /* 2009.04.01 K.Satomura T1_0148�Ή� END */
                /* 2009.05.26 D.Abe T1_1042�Ή� START */
                /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� START */
                -- �����敪��1�ŏ������t�����͍ς�
                IF (gv_prm_process_div = cv_prm_normal )
                    AND  (gv_prm_process_date IS NOT NULL) THEN
                  NULL;
                ELSE
                ---- �����敪���P�ł����A�g�A�܂��͏����敪���Q�̏ꍇ
                --IF (((gv_prm_process_div = cv_prm_normal)
                --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_no))
                --    OR
                --    (gv_prm_process_div = cv_prm_div)
                --   )
                --THEN
                /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� END */
                /* 2009.05.26 D.Abe T1_1042�Ή� END */
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
                  -- �����Ɍڋq�ڍs���������Ă��Ȃ��ꍇ�̂݃��b�N
                  IF ( lv_exists_flg = cv_no ) THEN
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
                    -- ========================================
                    -- A-8.�����֘A�ύX�����e�[�u�����b�N
                    -- ========================================
                    xxcso_ib_info_h_lock(
                       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
                      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
                      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                    );
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
                  ELSE
                    gv_department_code      := g_get_xxcso_ib_info_h_rec.past_sale_base_code; -- �O�����㋒�_
                    lv_retcode := cv_status_normal;
                  END IF;
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
--
                  IF (lv_retcode = cv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
/* 2009.05.26 D.Abe T1_1042�Ή� START */
                END IF;
/* 2009.05.26 D.Abe T1_1042�Ή� END */
                -- ========================================
                -- A-9.�Z�[�u�|�C���g���s����
                -- ========================================
                --
                SAVEPOINT ib_info;
--
                -- ========================================
                -- A-10.���̋@SH�����C���^�t�F�[�X�o�^����
                -- ========================================
                insert_xxcff_vd_object_if(
                   ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
                  ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
                  ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                );
--
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
--
                ELSIF (lv_retcode = cv_status_warn) THEN
                  -- �X�L�b�v����
                  gn_warn_cnt   := gn_warn_cnt + 1;
                  -- �Œ�X�e�[�^�X�ݒ�i�x���j
                  ov_retcode := cv_status_warn;
                  --�x���o��
                  fnd_file.put_line(
                     which  => FND_FILE.OUTPUT
                    ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
                  );
                  fnd_file.put_line(
                     which  => FND_FILE.LOG
                    ,buff   => lv_errmsg                  --�x�����b�Z�[�W
                  );
                  ROLLBACK TO SAVEPOINT ib_info;
                  --
                  -- *** DEBUG_LOG ***
                  -- ���[���o�b�N���������O�o��
                  fnd_file.put_line(
                     which  => FND_FILE.LOG
                    ,buff   => cv_debug_msg_rollback  || CHR(10) ||
                               cv_tkn_msg_vd_object_if || cv_tkn_msg_insert ||
                                CHR(10) ||
                               ''
                  );
                ELSE
--
                  /* 2009.05.26 D.Abe T1_1042�Ή� START */
                  /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� START */
                  -- �����敪��1�ŏ������t�����͍ς�
                  IF (gv_prm_process_div = cv_prm_normal )
                      AND  (gv_prm_process_date IS NOT NULL) THEN
                    gn_normal_cnt := gn_normal_cnt + 1;
                  ELSE
                  ---- �����敪���P�ł����A�g�A�܂��͏����敪���Q
                  --IF (((gv_prm_process_div = cv_prm_normal)
                  --     AND (g_get_xxcso_ib_info_h_rec.interface_flag = cv_no))
                  --    OR
                  --    (gv_prm_process_div = cv_prm_div)
                  --   )
                  --THEN
                  /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� END */
                  /* 2009.05.26 D.Abe T1_1042�Ή� END */
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
                    -- �����Ɍڋq�ڍs���������Ă���ꍇ�A�����ēx�A�g����ח����e�[�u�����X�V���Ȃ�
                    IF ( lv_exists_flg = cv_no ) THEN
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
                      -- ========================================
                      -- A-11.�����֘A���ύX�����e�[�u���X�V����
                      -- ========================================
                      update_xxcso_ib_info_h(
                         ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
                        ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
                        ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                      );
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD START */
                    ELSE
                      lv_retcode := cv_status_normal;
                    END IF;
/* 2018.05.22 Y.Shoji E_�{�ғ�_15102�Ή� ADD END */
--
                    IF (lv_retcode = cv_status_error) THEN
                      RAISE global_process_expt;
                    ELSIF (lv_retcode = cv_status_warn) THEN
                      -- �X�L�b�v����
                      gn_warn_cnt   := gn_warn_cnt + 1;
                      -- �Œ�X�e�[�^�X�ݒ�i�x���j
                      ov_retcode := cv_status_warn;
                      --�x���o��
                      fnd_file.put_line(
                         which  => FND_FILE.OUTPUT
                        ,buff   => lv_errmsg                  --���[�U�[�E�x�����b�Z�[�W
                      );
                      fnd_file.put_line(
                         which  => FND_FILE.LOG
                        ,buff   => lv_errmsg                  --�x�����b�Z�[�W
                      );
                      ROLLBACK TO SAVEPOINT ib_info;
                      --
                      -- *** DEBUG_LOG ***
                      -- ���[���o�b�N���������O�o��
                      fnd_file.put_line(
                         which  => FND_FILE.LOG
                        ,buff   => cv_debug_msg_rollback  || CHR(10) ||
                                   cv_tkn_msg_ib_info_h || cv_tkn_msg_update ||
                                    CHR(10) ||
                                   ''
                      );
                      --
                    ELSE
                      -- ���팏���擾
                      gn_normal_cnt := gn_normal_cnt + 1;
                    END IF;
                    /* 2009.04.01 K.Satomura T1_0148�Ή� START */
                    --END IF;
                    /* 2009.04.01 K.Satomura T1_0148�Ή� END */
                  /* 2009.05.26 D.Abe T1_1042�Ή� START */
                  /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� START */
                  --ELSE
                  --  -- ���팏���擾
                  --  gn_normal_cnt := gn_normal_cnt + 1;
                  /* 2009.05.28 D.Abe T1_1042(�ĂQ)�Ή� END */
                  END IF;
                  /* 2009.05.26 D.Abe T1_1042�Ή� END */
                END IF;
              END IF;
            END IF;
          END IF;
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL START */
--        END IF;
        /* 2016.01.18 K.Kiriu E_�{�ғ�_13456�Ή� DEL END   */
--
--
      END LOOP loop_get_xxcso_ib_info;
--
      -- �J�[�\���N���[�Y
      CLOSE get_xxcso_ib_info_h_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                   cv_debug_msgsub_1   || CHR(10)   ||
                   ''
      );
--
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
    END LOOP loop_get_target;
    -- �J�[�\���N���[�Y
    CLOSE get_target_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1   || CHR(10)   ||
                 cv_debug_msgsub_0   || CHR(10)   ||
                 ''
    );
--
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
--
  EXCEPTION
--
    -- SQL�G���[��O
    WHEN g_sql_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
      IF (get_target_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err1_2  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
      IF (get_target_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_1  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
--
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
      IF (get_target_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_2  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
      IF (get_xxcso_ib_info_h_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_xxcso_ib_info_h_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msgsub_1   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� START */
      IF (get_target_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_target_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_ccls2   || CHR(10)   ||
                     cv_debug_msg_err0_3  || CHR(10)   ||
                     cv_debug_msgsub_0   || CHR(10)   ||
                     ''
        );
      END IF;
/* 2009.07.17 H.Ogawa 0000781�Ή� END */
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
     errbuf          OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode         OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_process_div  IN  VARCHAR2           --   �����敪
    ,iv_process_date IN  VARCHAR2           --   �������s��
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �p�����[�^�̊i�[
    -- ===============================================
    gv_prm_process_div  := iv_process_div;
    gv_prm_process_date := iv_process_date;
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
    -- A-15.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)  -- ���o����
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)  -- �o�͌���
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
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
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
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
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
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO013A02C;
/
