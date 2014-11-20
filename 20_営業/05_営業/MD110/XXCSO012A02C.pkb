CREATE OR REPLACE PACKAGE BODY APPS.XXCSO012A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO012A02C(body)
 * Description      : �t�@�C���A�b�v���[�hIF�Ɏ捞�܂ꂽ�f�[�^��
 *                    �����}�X�^���(IB)�ɓo�^���܂��B
 * MD.050           : MD050_CSO_012_A02_�����̔��@�f�[�^�i�[
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_item_instances     ������񒊏o (A-2)
 *  chk_data_validate      �f�[�^�Ó����`�F�b�N���� (A-3)
 *  chk_data_master        �f�[�^�}�X�^�`�F�b�N���� (A-4)
 *  get_custmer_data       �ڋq���擾���� (A-5)
 *  insert_item_instances  �����f�[�^�o�^���� (A-6)
 *  rock_file_interface    �t�@�C���A�b�v���[�hIF���b�N���� (A-7)
 *  delete_in_item_data    �����f�[�^���[�N�e�[�u���폜���� (A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-03-18    1.0   T.Matsunaka      �V�K�쐬
 *  2009-03-26    1.1   T.Matsunaka      �yST��Q�Ή�183�z�����̔��@�f�[�^�i�[��IB�g�������l�e�[�u���o�^�s��
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-22    1.3   M.Ohtsuki        T1_1141�Ή�      �p���t���O��0��ݒ�
 *  2009-01-13    1.4   K.Hosoi          E_�{�ғ�_00443�Ή�
 *  2014-05-19    1.5   K.Nakamura       E_�{�ғ�_11853�Ή� �x���_�[�w���Ή�
 *  2014-08-27    1.6   S.Yamashita      E_�{�ғ�_11719�Ή� �x���_�[�w���Ή�
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO012A02C';      -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_33        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �t�@�C��ID�o��
  cv_tkn_number_34        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[���o��
  cv_tkn_number_01        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_tkn_number_02        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_03        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_35        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �A�b�v���[�h�t�@�C�����̎擾�G���[
  cv_tkn_number_36        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �A�b�v���[�h�t�@�C�����̏o��
  cv_tkn_number_04        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00092';  -- �g�DID�擾�G���[
  cv_tkn_number_05        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00093';  -- �g�DID���o�G���[
  cv_tkn_number_06        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00094';  -- �i��ID�擾�G���[
  cv_tkn_number_07        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00095';  -- �i��ID���o�G���[
  cv_tkn_number_08        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- �X�e�[�^�XID�擾�G���[
  cv_tkn_number_09        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- �X�e�[�^�XID���o�G���[
  cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- ����^�C�vID�擾�G���[
  cv_tkn_number_11        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- ����^�C�vID���o�G���[
  cv_tkn_number_12        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- �ǉ�����ID���o�G���[
  cv_tkn_number_37        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00254';  -- �l�Z�b�g�擾�G���[
  cv_tkn_number_38        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00255';  -- �l�Z�b�g���o�G���[
  cv_tkn_number_49        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- �f�[�^�폜�G���[
  cv_tkn_number_40        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00554';  -- BLOB�ϊ��G���[
  cv_tkn_number_39        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �A�b�v���[�h�t�@�C�����̏o��
  cv_tkn_number_41        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_43        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00317';  -- ���p�p�����G���[
  cv_tkn_number_42        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00551';  -- �����R�[�h�����G���[
  cv_tkn_number_44        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00183';  -- LENGTH�G���[
  cv_tkn_number_45        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- �f�[�^���o�A�o�^�x�����b�Z�[�W
  cv_tkn_number_46        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00552';  -- �����}�X�^�d���G���[
  cv_tkn_number_47        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00553';  -- �@��}�X�^�擾�G���[
  cv_tkn_number_48        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  cv_tkn_number_50        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00557';  -- �@��敪�擾�G���[
  cv_tkn_number_32        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- �f�[�^���o0�����b�Z�[�W
  cv_tkn_number_51        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00550';  -- CSV�f�[�^�t�H�[�}�b�g�G���[
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_tkn_number_52        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00670';  -- ���[�X�敪
  cv_tkn_number_53        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- �\���n
  cv_tkn_number_54        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00675';  -- �擾���i
  cv_tkn_number_55        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00678';  -- �@��}�X�^�r���[
  cv_tkn_number_56        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- ���݃G���[
  cv_tkn_number_57        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00680';  -- �Q�ƃ^�C�v �F
  cv_tkn_number_58        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00681';  -- �l�Z�b�g �F
  cv_tkn_number_59        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00682';  -- �Œ莑�Y���K�{�G���[
  cv_tkn_number_60        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00268';  -- �}�C�i�X�l�G���[���b�Z�[�W
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
  cv_target_rec_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_success_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_error_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_normal_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_warn_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
  cv_error_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--
  -- �g�[�N���R�[�h
  cv_tkn_file_id          CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_format           CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_upload           CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_task_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_organization     CONSTANT VARCHAR2(20) := 'ORGANIZATION_CODE';
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_segment          CONSTANT VARCHAR2(20) := 'SEGMENT';
  cv_tkn_organization_id  CONSTANT VARCHAR2(20) := 'ORGANIZATION_ID';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_attribute_name   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_value_set_name   CONSTANT VARCHAR2(20) := 'VALUE_SET_NAME';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_csv_upload       CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_value            CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_value2           CONSTANT VARCHAR2(20) := 'VALUE2';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_cnt_token            CONSTANT VARCHAR2(10) := 'COUNT';           -- �������b�Z�[�W�p�g�[�N����
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_eigyo            CONSTANT VARCHAR2(20) := 'EIGYO';
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
  cv_encoded_f            CONSTANT VARCHAR2(1)   := 'F';              -- FALSE
--
  cv_msg_conm             CONSTANT VARCHAR2(1)   := ',';              -- �J���}
--
/* 2014-08-27 S.Yamashita E_�{�ғ�_11719�Ή� START */
  cv_msg_part_only        CONSTANT VARCHAR2(1) := ':';
/* 2014-08-27 S.Yamashita E_�{�ғ�_11719�Ή� END */
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_hyphen               CONSTANT VARCHAR2(1)   := '-';                -- �n�C�t��
  -- �l�Z�b�g
  cv_xxcff_dclr_place     CONSTANT VARCHAR2(30) := 'XXCFF_DCLR_PLACE';  -- �\���n
  -- �Q�ƃ^�C�v
  cv_xxcso1_lease_kbn     CONSTANT VARCHAR2(30) := 'XXCSO1_LEASE_KBN';  -- ���[�X�敪
  --
  cv_fixed_assets         CONSTANT VARCHAR2(1)  := '4';                 -- ���[�X�敪�u�Œ莑�Y�v
  cv_y                    CONSTANT VARCHAR2(1)  := 'Y';                 -- �L���t���OY
  ct_language             CONSTANT fnd_flex_values_tl.language%TYPE := USERENV('LANG'); -- ����
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gt_inv_mst_org_id       mtl_parameters.organization_id%TYPE;                 -- �g�DID
  gt_vld_org_id           mtl_parameters.organization_id%TYPE;                 -- ���ؑg�DID
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;              -- ����^�C�vID
  gt_bukken_item_id       mtl_system_items_b.inventory_item_id%TYPE;           -- �����p�i��ID
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE;       -- �g�p��
  gd_process_date         DATE;                                                -- �Ɩ����t
  gv_owner_company        fnd_flex_values_vl.flex_value%TYPE;                  -- �{��/�H��敪
  gn_account_id           xxcso_cust_acct_sites_v.cust_account_id%TYPE;        -- �A�J�E���gID
  gn_locatoin_id          xxcso_cust_acct_sites_v.location_id%TYPE;            -- ���P�[�V����ID
  gn_party_id             xxcso_cust_acct_sites_v.party_id%TYPE;               -- �p�[�e�BID
  gn_party_site_id        xxcso_cust_acct_sites_v.party_site_id%TYPE;          -- �p�[�e�B�T�C�gID
  /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
  --gv_established_site     xxcso_cust_acct_sites_v.established_site_name%TYPE;  -- �ݒu�於
  gv_established_site     xxcso_cust_acct_sites_v.party_name%TYPE;             -- �ݒu�於
  /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
  gv_address              VARCHAR2(1000);                                      -- �ݒu��Z��
  gv_address3             VARCHAR2(1000);                                      -- �n��R�[�h
  gv_file_name            VARCHAR2(1000);                                      -- ���̓t�@�C����
  gv_hazard_class         po_hazard_classes_vl.hazard_class%TYPE;              -- �@��敪
  gv_maker_name           fnd_lookup_values.meaning%TYPE;                      -- ���[�J�[��
  gv_age_type             po_un_numbers_vl.attribute3%TYPE;                    -- �N��
--
  -- �ǉ�����ID�i�[�p���R�[�h�^��`
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     jotai_kbn1            NUMBER               -- �@����1�i�ғ���ԁj
    ,jotai_kbn2            NUMBER               -- �@����2�i��ԏڍׁj
    ,jotai_kbn3            NUMBER               -- �@����3�i�p�����j
    ,lease_kbn             NUMBER               -- ���[�X�敪
/*20090326_matsunaka_ST183 START*/
--    ,chiku_cd              VARCHAR2(150)        -- �n��R�[�h
    ,chiku_cd              NUMBER               -- �n��R�[�h
    ,count_no              NUMBER               -- �J�E���^�[No.
    ,sagyougaisya_cd       NUMBER               -- ��Ɖ�ЃR�[�h
    ,jigyousyo_cd          NUMBER               -- ���Ə��R�[�h
    ,den_no                NUMBER               -- �ŏI��Ɠ`�[No.
    ,job_kbn               NUMBER               -- �ŏI��Ƌ敪
    ,sintyoku_kbn          NUMBER               -- �ŏI��Ɛi��
    ,yotei_dt              NUMBER               -- �ŏI��Ɗ����\���
    ,kanryo_dt             NUMBER               -- �ŏI��Ɗ�����
    ,sagyo_level           NUMBER               -- �ŏI�������e
    ,den_no2               NUMBER               -- �ŏI�ݒu�`�[No.
    ,job_kbn2              NUMBER               -- �ŏI�ݒu�敪
    ,sintyoku_kbn2         NUMBER               -- �ŏI�ݒu�i��
    ,nyuko_dt              NUMBER               -- ���ɓ�
    ,hikisakigaisya_cd     NUMBER               -- ���g��ЃR�[�h
    ,hikisakijigyosyo_cd   NUMBER               -- ���g���Ə��R�[�h
    ,setti_tanto           NUMBER               -- �ݒu��S���Җ�
    ,setti_tel1            NUMBER               -- �ݒu��tel1
    ,setti_tel2            NUMBER               -- �ݒu��tel2
    ,setti_tel3            NUMBER               -- �ݒu��tel3
    ,haikikessai_dt        NUMBER               -- �p�����ٓ�
    ,tenhai_tanto          NUMBER               -- �]���p���Ǝ�
    ,tenhai_den_no         NUMBER               -- �]���p���`�[��
    ,syoyu_cd              NUMBER               -- ���L��
    ,tenhai_flg            NUMBER               -- �]���p���󋵃t���O
    ,kanryo_kbn            NUMBER               -- �]�������敪
    ,sakujo_flg            NUMBER               -- �폜�t���O
    ,ven_kyaku_last        NUMBER               -- �ŏI�ڋq�R�[�h
    ,ven_tasya_cd01        NUMBER               -- ���ЃR�[�h�P
    ,ven_tasya_daisu01     NUMBER               -- ���Б䐔�P
    ,ven_tasya_cd02        NUMBER               -- ���ЃR�[�h�Q
    ,ven_tasya_daisu02     NUMBER               -- ���Б䐔�Q
    ,ven_tasya_cd03        NUMBER               -- ���ЃR�[�h�R
    ,ven_tasya_daisu03     NUMBER               -- ���Б䐔�R
    ,ven_tasya_cd04        NUMBER               -- ���ЃR�[�h�S
    ,ven_tasya_daisu04     NUMBER               -- ���Б䐔�S
    ,ven_tasya_cd05        NUMBER               -- ���ЃR�[�h�T
    ,ven_tasya_daisu05     NUMBER               -- ���Б䐔�T
    ,ven_haiki_flg         NUMBER               -- �p���t���O
    ,ven_sisan_kbn         NUMBER               -- ���Y�敪
    ,ven_kobai_ymd         NUMBER               -- �w�����t
    ,ven_kobai_kg          NUMBER               -- �w�����z
    ,safty_level           NUMBER               -- ���S�ݒu�
    ,last_inst_cust_code   NUMBER               -- �挎���ݒu��ڋq�R�[�h
    ,last_jotai_kbn        NUMBER               -- �挎���@����
    ,last_year_month       NUMBER               -- �挎���N��
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    ,vd_shutoku_kg         NUMBER               -- �擾���i
    ,dclr_place            NUMBER               -- �\���n
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
  );
  -- �ǉ�����ID�i�[�p���R�[�h�ϐ�
  gr_ext_attribs_id_rec   gr_ib_ext_attribs_id_rtype;
--
  --BLOB�f�[�^�i�[�z��
  gr_file_data_tbl         xxccp_common_pkg2.g_file_data_tbl;
--
  --BLOB�f�[�^�����f�[�^�i�[
  TYPE gr_blob_data_rtype IS RECORD(
    object_code          VARCHAR2(10)            -- �����R�[�h
   ,serial_code          VARCHAR2(15)            -- �@��R�[�h
   ,base_code            VARCHAR2(4)             -- ���_�R�[�h
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
   ,lease_kbn            VARCHAR2(1)             -- ���[�X�敪
   ,dclr_place           VARCHAR2(5)             -- �\���n
   ,vd_shutoku_kg        VARCHAR2(10)            -- �擾���i
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
  );
  gr_blob_data gr_blob_data_rtype;
--  
  -- *** ���[�U�[��`�O���[�o����O ***
  global_lock_expt        EXCEPTION;                                 -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id           IN  NUMBER               -- �t�@�C��ID
    ,iv_format            IN  VARCHAR2             -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- XXCSO:�݌Ƀ}�X�^�g�D
    cv_inv_mst_org_code       CONSTANT VARCHAR2(30)  := 'XXCSO1_INV_MST_ORG_CODE';
    -- XXCSO:���ؑg�D
    cv_vld_org_code           CONSTANT VARCHAR2(30)  := 'XXCSO1_VLD_ORG_CODE';
    -- XXCSO:�����p�i��
    cv_bukken_item            CONSTANT VARCHAR2(30)  := 'XXCSO1_BUKKEN_ITEM';
    -- �t�@�C���A�b�v���[�h����
    cv_xxcso1_file_name       CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X�^�C�v�R�[�h
    cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
    -- XXCSO:�{��/�H��敪(�{��)�Q�ƃ^�C�v
    cv_cso_owner_company_type CONSTANT VARCHAR2(30)  := 'XXCSO1_OWNER_COMPANY';
    -- XXCFF:�{��/�H��敪(�{��)
    cv_cff_owner_company_type CONSTANT VARCHAR2(30)  := 'XXCFF_OWNER_COMPANY';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�g�p��)�R�[�h
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';
    -- �\�[�X�g�����U�N�V�����^�C�v
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- �t�@�C���A�b�v���[�h�R�[�h
    cv_xxcso1_file_code       CONSTANT VARCHAR2(30)  := '640';
    -- XXCSO:�{��/�H��敪(�{��)�Q�ƃR�[�h
    cv_cso_owner_company_code CONSTANT VARCHAR2(1)  := '1';
    -- ���o���e��(�݌Ƀ}�X�^�̑g�DID)
    cv_mtl_parameters_info    CONSTANT VARCHAR2(100) := '�݌Ƀ}�X�^�̑g�DID';
    -- ���o���e��(�݌Ƀ}�X�^�̌��ؑg�DID)
    cv_mtl_parameters_vld     CONSTANT VARCHAR2(100) := '�݌Ƀ}�X�^�̌��ؑg�DID';
    -- ���o���e��(�i�ڃ}�X�^�̕i��ID)
    cv_mtl_system_items_id    CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�̕i��ID';
    -- ���o���e��(�C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID)
    cv_csi_instance_statuses  CONSTANT VARCHAR2(100) := '�C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID';
    -- ���o���e��(����^�C�v�̎���^�C�vID)
    cv_csi_txn_types          CONSTANT VARCHAR2(100) := '����^�C�v�̎���^�C�vID';
    -- ���o���e��(�ݒu�@��g��������`���̒ǉ�����ID)
    cv_attribute_id_info      CONSTANT VARCHAR2(100) := '�ݒu�@��g��������`���̒ǉ�����ID';
    -- �X�e�[�^�X��(�g�p��)
    cv_statuses_name02        CONSTANT VARCHAR2(100) := '�g�p��';
    -- �l�Z�b�g
    cv_csi_txn_flex           CONSTANT VARCHAR2(100) := '�l�Z�b�g';
    -- �@����1�i�ғ���ԁj
    cv_i_ext_jotai_kbn1       CONSTANT VARCHAR2(100) := '�@����1�i�ғ���ԁj';
    -- �@����2�i��ԏڍׁj
    cv_i_ext_jotai_kbn2       CONSTANT VARCHAR2(100) := '�@����2�i��ԏڍׁj';
    -- �@����3�i�p�����j
    cv_i_ext_jotai_kbn3       CONSTANT VARCHAR2(100) := '�@����3�i�p�����j';
    -- ���[�X�敪
    cv_i_ext_lease_kbn        CONSTANT VARCHAR2(100) := '���[�X�敪';
    -- �n��R�[�h
    cv_i_ext_chiku_cd         CONSTANT VARCHAR2(100) := '�n��R�[�h';
    -- �@����1�i�ғ���ԁj
    cv_jotai_kbn1             CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';
    -- �@����2�i��ԏڍׁj
    cv_jotai_kbn2             CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';
    -- �@����2�i�p�����j
    cv_jotai_kbn3             CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
    -- ���[�X�敪
    cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
    -- �n��R�[�h
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';
    -- �{��/�H��敪
    cv_owner_company          CONSTANT VARCHAR2(100) := '�{��/�H��敪';
--
/*20090326_matsunaka_ST183 START*/
    -- �J�E���^�[No.
    cv_i_ext_count_no         CONSTANT VARCHAR2(100) := '�J�E���^�[No.';
    -- ��Ɖ�ЃR�[�h
    cv_i_ext_sagyougaisya_cd  CONSTANT VARCHAR2(100) := '��Ɖ�ЃR�[�h';
    -- ���Ə��R�[�h
    cv_i_ext_jigyousyo_cd     CONSTANT VARCHAR2(100) := '���Ə��R�[�h';
    -- �ŏI��Ɠ`�[No.
    cv_i_ext_den_no           CONSTANT VARCHAR2(100) := '�ŏI��Ɠ`�[No.';
    -- �ŏI��Ƌ敪
    cv_i_ext_job_kbn          CONSTANT VARCHAR2(100) := '�ŏI��Ƌ敪';
    -- �ŏI��Ɛi��
    cv_i_ext_sintyoku_kbn     CONSTANT VARCHAR2(100) := '�ŏI��Ɛi��';
    -- �ŏI��Ɗ����\���
    cv_i_ext_yotei_dt         CONSTANT VARCHAR2(100) := '�ŏI��Ɗ����\���';
    -- �ŏI��Ɗ�����
    cv_i_ext_kanryo_dt        CONSTANT VARCHAR2(100) := '�ŏI��Ɗ�����';
    -- �ŏI�������e
    cv_i_ext_sagyo_level      CONSTANT VARCHAR2(100) := '�ŏI�������e';
    -- �ŏI�ݒu�`�[No.
    cv_i_ext_den_no2          CONSTANT VARCHAR2(100) := '�ŏI�ݒu�`�[No.';
    -- �ŏI�ݒu�敪
    cv_i_ext_job_kbn2         CONSTANT VARCHAR2(100) := '�ŏI�ݒu�敪';
    -- �ŏI�ݒu�i��
    cv_i_ext_sintyoku_kbn2    CONSTANT VARCHAR2(100) := '�ŏI�ݒu�i��';
    -- ���ɓ�
    cv_i_ext_nyuko_dt         CONSTANT VARCHAR2(100) := '���ɓ�';
    -- ���g��ЃR�[�h
    cv_i_ext_hikisakicmy_cd   CONSTANT VARCHAR2(100) := '���g��ЃR�[�h';
    -- ���g���Ə��R�[�h
    cv_i_ext_hikisakilct_cd   CONSTANT VARCHAR2(100) := '���g���Ə��R�[�h';
    -- �ݒu��S���Җ�
    cv_i_ext_setti_tanto      CONSTANT VARCHAR2(100) := '�ݒu��S���Җ�';
    -- �ݒu��tel1
    cv_i_ext_setti_tel1       CONSTANT VARCHAR2(100) := '�ݒu��tel1';
    -- �ݒu��tel2
    cv_i_ext_setti_tel2       CONSTANT VARCHAR2(100) := '�ݒu��tel2';
    -- �ݒu��tel3
    cv_i_ext_setti_tel3       CONSTANT VARCHAR2(100) := '�ݒu��tel3';
    -- �p�����ٓ�
    cv_i_ext_haikikessai_dt   CONSTANT VARCHAR2(100) := '�p�����ٓ�';
    -- �]���p���Ǝ�
    cv_i_ext_tenhai_tanto     CONSTANT VARCHAR2(100) := '�]���p���Ǝ�';
    -- �]���p���`�[��
    cv_i_ext_tenhai_den_no    CONSTANT VARCHAR2(100) := '�]���p���`�[��';
    -- ���L��
    cv_i_ext_syoyu_cd         CONSTANT VARCHAR2(100) := '���L��';
    -- �]���p���󋵃t���O
    cv_i_ext_tenhai_flg       CONSTANT VARCHAR2(100) := '�]���p���󋵃t���O';
    -- �]�������敪
    cv_i_ext_kanryo_kbn       CONSTANT VARCHAR2(100) := '�]�������敪';
    -- �폜�t���O
    cv_i_ext_sakujo_flg       CONSTANT VARCHAR2(100) := '�폜�t���O';
    -- �ŏI�ڋq�R�[�h
    cv_i_ext_ven_kyaku_last   CONSTANT VARCHAR2(100) := '�ŏI�ڋq�R�[�h';
    -- ���ЃR�[�h�P
    cv_i_ext_ven_tasya_cd01   CONSTANT VARCHAR2(100) := '���ЃR�[�h�P';
    -- ���Б䐔�P
    cv_i_ext_ven_tasya_ds01   CONSTANT VARCHAR2(100) := '���Б䐔�P';
    -- ���ЃR�[�h�Q
    cv_i_ext_ven_tasya_cd02   CONSTANT VARCHAR2(100) := '���ЃR�[�h�Q';
    -- ���Б䐔�Q
    cv_i_ext_ven_tasya_ds02   CONSTANT VARCHAR2(100) := '���Б䐔�Q';
    -- ���ЃR�[�h�R
    cv_i_ext_ven_tasya_cd03   CONSTANT VARCHAR2(100) := '���ЃR�[�h�R';
    -- ���Б䐔�R
    cv_i_ext_ven_tasya_ds03   CONSTANT VARCHAR2(100) := '���Б䐔�R';
    -- ���ЃR�[�h�S
    cv_i_ext_ven_tasya_cd04   CONSTANT VARCHAR2(100) := '���ЃR�[�h�S';
    -- ���Б䐔�S
    cv_i_ext_ven_tasya_ds04   CONSTANT VARCHAR2(100) := '���Б䐔�S';
    -- ���ЃR�[�h�T
    cv_i_ext_ven_tasya_cd05   CONSTANT VARCHAR2(100) := '���ЃR�[�h�T';
    -- ���Б䐔�T
    cv_i_ext_ven_tasya_ds05   CONSTANT VARCHAR2(100) := '���Б䐔�T';
    -- �p���t���O
    cv_i_ext_ven_haiki_flg    CONSTANT VARCHAR2(100) := '�p���t���O';
    -- ���Y�敪
    cv_i_ext_ven_sisan_kbn    CONSTANT VARCHAR2(100) := '���Y�敪';
    -- �w�����t
    cv_i_ext_ven_kobai_ymd    CONSTANT VARCHAR2(100) := '�w�����t';
    -- �w�����z
    cv_i_ext_ven_kobai_kg     CONSTANT VARCHAR2(100) := '�w�����z';
    -- ���S�ݒu�
    cv_i_ext_safty_level      CONSTANT VARCHAR2(100) := '���S�ݒu�';
    -- �挎���ݒu��ڋq�R�[�h
    cv_i_ext_last_inst_cust_code  CONSTANT VARCHAR2(100) := '�挎���ݒu��ڋq�R�[�h';
    -- �挎���@����
    cv_i_ext_last_jotai_kbn   CONSTANT VARCHAR2(100) := '�挎���@����';
    -- �挎���N��
    cv_i_ext_last_year_month  CONSTANT VARCHAR2(100) := '�挎���N��';
    -- �J�E���^�[No.
    cv_count_no               CONSTANT VARCHAR2(100) := 'COUNT_NO';
    -- ��Ɖ�ЃR�[�h
    cv_sagyougaisya_cd        CONSTANT VARCHAR2(100) := 'SAGYOUGAISYA_CD'; 
    -- ���Ə��R�[�h
    cv_jigyousyo_cd           CONSTANT VARCHAR2(100) := 'JIGYOUSYO_CD';
    -- �ŏI��Ɠ`�[No.
    cv_den_no                 CONSTANT VARCHAR2(100) := 'DEN_NO';
    -- �ŏI��Ƌ敪
    cv_job_kbn                CONSTANT VARCHAR2(100) := 'JOB_KBN';
    -- �ŏI��Ɛi��
    cv_sintyoku_kbn           CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN';
    -- �ŏI��Ɗ����\���
    cv_yotei_dt               CONSTANT VARCHAR2(100) := 'YOTEI_DT';
    -- �ŏI��Ɗ�����
    cv_kanryo_dt              CONSTANT VARCHAR2(100) := 'KANRYO_DT';
    -- �ŏI�������e
    cv_sagyo_level            CONSTANT VARCHAR2(100) := 'SAGYO_LEVEL';
    -- �ŏI�ݒu�`�[No.
    cv_den_no2                CONSTANT VARCHAR2(100) := 'DEN_NO2';
    -- �ŏI�ݒu�敪
    cv_job_kbn2               CONSTANT VARCHAR2(100) := 'JOB_KBN2';
    -- �ŏI�ݒu�i��
    cv_sintyoku_kbn2          CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN2';
    -- ���ɓ�
    cv_nyuko_dt               CONSTANT VARCHAR2(100) := 'NYUKO_DT';
    -- ���g��ЃR�[�h
    cv_hikisakigaisya_cd      CONSTANT VARCHAR2(100) := 'HIKISAKIGAISYA_CD';
    -- ���g���Ə��R�[�h
    cv_hikisakijigyosyo_cd    CONSTANT VARCHAR2(100) := 'HIKISAKIJIGYOSYO_CD';
    -- �ݒu��S���Җ�
    cv_setti_tanto            CONSTANT VARCHAR2(100) := 'SETTI_TANTO';
    -- �ݒu��tel1
    cv_setti_tel1             CONSTANT VARCHAR2(100) := 'SETTI_TEL1';
    -- �ݒu��tel2
    cv_setti_tel2             CONSTANT VARCHAR2(100) := 'SETTI_TEL2';
    -- �ݒu��tel3
    cv_setti_tel3             CONSTANT VARCHAR2(100) := 'SETTI_TEL3';
    -- �p�����ٓ�
    cv_haikikessai_dt         CONSTANT VARCHAR2(100) := 'HAIKIKESSAI_DT';
    -- �]���p���Ǝ�
    cv_tenhai_tanto           CONSTANT VARCHAR2(100) := 'TENHAI_TANTO';
    -- �]���p���`�[��
    cv_tenhai_den_no          CONSTANT VARCHAR2(100) := 'TENHAI_DEN_NO';
    -- ���L��
    cv_syoyu_cd               CONSTANT VARCHAR2(100) := 'SYOYU_CD';
    -- �]���p���󋵃t���O
    cv_tenhai_flg             CONSTANT VARCHAR2(100) := 'TENHAI_FLG';
    -- �]�������敪
    cv_kanryo_kbn             CONSTANT VARCHAR2(100) := 'KANRYO_KBN';
    -- �폜�t���O
    cv_sakujo_flg             CONSTANT VARCHAR2(100) := 'SAKUJO_FLG';
    -- �ŏI�ڋq�R�[�h
    cv_ven_kyaku_last         CONSTANT VARCHAR2(100) := 'VEN_KYAKU_LAST';
    -- ���ЃR�[�h�P
    cv_ven_tasya_cd01         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD01';
    -- ���Б䐔�P
    cv_ven_tasya_daisu01      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU01';
    -- ���ЃR�[�h2
    cv_ven_tasya_cd02         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD02';
    -- ���Б䐔2
    cv_ven_tasya_daisu02      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU02';
    -- ���ЃR�[�h3
    cv_ven_tasya_cd03         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD03';
    -- ���Б䐔3
    cv_ven_tasya_daisu03      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU03';
    -- ���ЃR�[�h4
    cv_ven_tasya_cd04         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD04';
    -- ���Б䐔4
    cv_ven_tasya_daisu04      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU04';
    -- ���ЃR�[�h5
    cv_ven_tasya_cd05         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD05';
    -- ���Б䐔5
    cv_ven_tasya_daisu05      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU05';
    -- �p���t���O
    cv_ven_haiki_flg          CONSTANT VARCHAR2(100) := 'VEN_HAIKI_FLG';
    -- ���Y�敪
    cv_ven_sisan_kbn          CONSTANT VARCHAR2(100) := 'VEN_SISAN_KBN';
    -- �w�����t
    cv_ven_kobai_ymd          CONSTANT VARCHAR2(100) := 'VEN_KOBAI_YMD';
    -- �w�����z
    cv_ven_kobai_kg           CONSTANT VARCHAR2(100) := 'VEN_KOBAI_KG';
    -- ���S�ݒu�
    cv_safty_level            CONSTANT VARCHAR2(100) := 'SAFTY_LEVEL';
    -- �挎���ݒu��ڋq�R�[�h
    cv_last_inst_cust_code    CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    -- �挎���@����
    cv_last_jotai_kbn         CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';
    -- �挎���N��
    cv_last_year_month        CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �擾���i
    cv_vd_shutoku_kg          CONSTANT VARCHAR2(100) := 'VD_SHUTOKU_KG';
    -- �\���n
    cv_dclr_place             CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- *** ���[�J���ϐ� ***
    -- �Ɩ�������
    ld_process_date           DATE;
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_noprm_msg              VARCHAR2(5000);  
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value              VARCHAR2(1000);
    -- �o�^�p�g�D�R�[�h
    lv_inv_mst_org_code       VARCHAR2(100);
    -- �o�^�p���ؑg�D�R�[�h
    lv_vld_org_code           VARCHAR2(100);
    -- �o�^�p�Z�O�����g
    lv_bukken_item            VARCHAR2(100);
    -- �X�e�[�^�X��
    lv_status_name            VARCHAR2(100);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                    VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    
    -- ============================
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- ============================
    --�t�@�C��ID
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_33             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id
                       ,iv_token_value1 => in_file_id
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    --�t�H�[�}�b�g�p�^�[��
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_34             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_format
                       ,iv_token_value1 => iv_format
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- ==========================
    -- ���̓p�����[�^�K�{�`�F�b�N
    -- ==========================
    --�t�@�C��ID
    IF (in_file_id IS NULL) THEN
      -- =================================
      -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��(�ُ�I�������邱��) 
      -- =================================
      lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name           --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                        );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    ld_process_date :=TRUNC(gd_process_date);
--
    -- ====================
    -- �ϐ����������� 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    cv_inv_mst_org_code
                   ,lv_inv_mst_org_code
                   ); -- �݌Ƀ}�X�^�g�D
    FND_PROFILE.GET(
                    cv_vld_org_code
                   ,lv_vld_org_code
                   ); -- ���ؑg�D
    FND_PROFILE.GET(
                    cv_bukken_item
                   ,lv_bukken_item
                   ); -- �����p�i��
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- �݌Ƀ}�X�^�g�D�擾���s��
    IF (lv_inv_mst_org_code IS NULL) THEN
      lv_tkn_value := cv_inv_mst_org_code;
    -- ���ؑg�D�擾���s��
    ELSIF (lv_vld_org_code IS NULL) THEN
      lv_tkn_value := cv_vld_org_code;
    -- �����p�i��
    ELSIF (lv_bukken_item IS NULL) THEN
      lv_tkn_value := cv_bukken_item;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_03             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- �t�@�C���A�b�v���[�h���̎擾���� 
    -- =================================
    BEGIN
      SELECT flvv.meaning          -- �t�@�C���A�b�v���[�h����
      INTO   gv_file_name
      FROM   fnd_lookup_values_vl  flvv                               -- �Q�ƃ^�C�v
      WHERE  flvv.lookup_type      = cv_xxcso1_file_name
      AND    flvv.lookup_code      = cv_xxcso1_file_code
      AND    flvv.enabled_flag     = 'Y'
      AND    NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
      AND    NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_35             -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --�擾�����t�@�C���A�b�v���[�h���̂��t�@�C���o��
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_36             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_upload
                       ,iv_token_value1 => gv_file_name
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- ===========================
    -- �݌Ƀ}�X�^�̑g�DID�擾���� 
    -- ===========================
    BEGIN
      SELECT  mp.organization_id                                      -- �g�DID
      INTO    gt_inv_mst_org_id
      FROM    mtl_parameters  mp                                      -- �݌ɑg�D�}�X�^
      WHERE   mp.organization_code = lv_inv_mst_org_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- �݌Ƀ}�X�^�̌��ؑg�DID�擾���� 
    -- ===============================
    BEGIN
      SELECT  mp.organization_id                                        -- �g�DID
      INTO    gt_vld_org_id
      FROM    mtl_parameters  mp                                        -- �݌ɑg�D�}�X�^
      WHERE   mp.organization_code = lv_vld_org_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_vld_org_code              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_vld_org_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- �����p�i��ID�擾���� 
    -- ====================
    BEGIN
      SELECT msib.inventory_item_id                                     -- �i��ID
      INTO   gt_bukken_item_id
      FROM   mtl_system_items_b msib                                    -- �i�ڃ}�X�^
      WHERE  msib.segment1 = lv_bukken_item
        AND  msib.organization_id = gt_inv_mst_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_segment               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_bukken_item               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_organization_id       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_segment               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_bukken_item               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_organization_id       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_errmsg                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--    
    -- =================================
    -- �C���X�^���X�X�e�[�^�XID�擾���� 
    -- =================================
    -- ������
    lv_status_name   := '';
    -- �u�g�p�v
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,ld_process_date);
--
      SELECT cis.instance_status_id                                     -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_2
      FROM   csi_instance_statuses cis                                  -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name02           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name02           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- ����^�C�vID�擾���� 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id                                    -- �g�����U�N�V�����^�C�vID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                          -- ����^�C�v
      WHERE  ctt.source_transaction_type  = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- �ǉ�����ID�擾���� 
    -- ====================
    -- ������
    gr_ext_attribs_id_rec := NULL;
--
    -- �ǉ�����ID(�@����1�i�ғ���ԁj)
    gr_ext_attribs_id_rec.jotai_kbn1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn1
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn1          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn1                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�@����2�i��ԏڍׁj)
    gr_ext_attribs_id_rec.jotai_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn2
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn2          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn2                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�@����3�i�p�����j)
    gr_ext_attribs_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn3
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn3          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn3                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���[�X�敪)
    gr_ext_attribs_id_rec.lease_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_lease_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.lease_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_lease_kbn           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_lease_kbn                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�n��R�[�h)
    gr_ext_attribs_id_rec.chiku_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_chiku_cd
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.chiku_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_chiku_cd            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_chiku_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/*20090326_matsunaka_ST183 START*/
    -- �ǉ�����ID(�J�E���^�[No.)
    gr_ext_attribs_id_rec.count_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_count_no
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.count_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_count_no            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_count_no                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(��Ɖ�ЃR�[�h)
    gr_ext_attribs_id_rec.sagyougaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                cv_sagyougaisya_cd
                                               ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyougaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sagyougaisya_cd     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sagyougaisya_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Ə��R�[�h)
    gr_ext_attribs_id_rec.jigyousyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_jigyousyo_cd
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jigyousyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jigyousyo_cd        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jigyousyo_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɠ`�[No.)
    gr_ext_attribs_id_rec.den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                       cv_den_no
                                      ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_den_no              -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_den_no                    -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ƌ敪)
    gr_ext_attribs_id_rec.job_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_job_kbn
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_job_kbn             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_job_kbn                   -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɛi��)
    gr_ext_attribs_id_rec.sintyoku_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_sintyoku_kbn
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sintyoku_kbn              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɗ����\���)
    gr_ext_attribs_id_rec.yotei_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_yotei_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.yotei_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_yotei_dt            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_yotei_dt                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɗ�����)
    gr_ext_attribs_id_rec.kanryo_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_kanryo_dt
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_kanryo_dt           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_kanryo_dt                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�������e)
    gr_ext_attribs_id_rec.sagyo_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_sagyo_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyo_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sagyo_level         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sagyo_level               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ŏI�ݒu�`�[No.
    gr_ext_attribs_id_rec.den_no2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_den_no2
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_den_no2             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_den_no2                   -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ݒu�敪)
    gr_ext_attribs_id_rec.job_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_job_kbn2
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_job_kbn2            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_job_kbn2                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ݒu�i��)
    gr_ext_attribs_id_rec.sintyoku_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_sintyoku_kbn2
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn2       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sintyoku_kbn2             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ɓ�)
    gr_ext_attribs_id_rec.nyuko_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_nyuko_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.nyuko_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_nyuko_dt            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_nyuko_dt                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���g��ЃR�[�h)
    gr_ext_attribs_id_rec.hikisakigaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                  cv_hikisakigaisya_cd
                                                 ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakigaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_hikisakicmy_cd      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_hikisakigaisya_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���g���Ə��R�[�h)
    gr_ext_attribs_id_rec.hikisakijigyosyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                    cv_hikisakijigyosyo_cd
                                                   ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakijigyosyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_hikisakilct_cd      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_hikisakijigyosyo_cd       -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��S���Җ�)
    gr_ext_attribs_id_rec.setti_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tanto         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tanto               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel1)
    gr_ext_attribs_id_rec.setti_tel1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel1
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel1          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel1                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel2)
    gr_ext_attribs_id_rec.setti_tel2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel2
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel2          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel2                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel3)
    gr_ext_attribs_id_rec.setti_tel3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel3
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel3          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel3                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�p�����ٓ�)
    gr_ext_attribs_id_rec.haikikessai_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_haikikessai_dt
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.haikikessai_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_haikikessai_dt      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_haikikessai_dt            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���Ǝ�)
    gr_ext_attribs_id_rec.tenhai_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_tenhai_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_tanto        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_tanto              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���`�[��)
    gr_ext_attribs_id_rec.tenhai_den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_tenhai_den_no
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_den_no       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_den_no             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���L��)
    gr_ext_attribs_id_rec.syoyu_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_syoyu_cd
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.syoyu_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_syoyu_cd            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_syoyu_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���󋵃t���O)
    gr_ext_attribs_id_rec.tenhai_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_tenhai_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_flg          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_flg                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]�������敪)
    gr_ext_attribs_id_rec.kanryo_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_kanryo_kbn
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_kanryo_kbn          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_kanryo_kbn                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�폜�t���O)
    gr_ext_attribs_id_rec.sakujo_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_sakujo_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sakujo_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sakujo_flg          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sakujo_flg                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ڋq�R�[�h)
    gr_ext_attribs_id_rec.ven_kyaku_last := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_kyaku_last
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kyaku_last IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kyaku_last      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kyaku_last            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h�P)
    gr_ext_attribs_id_rec.ven_tasya_cd01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd01      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd01            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔�P)
    gr_ext_attribs_id_rec.ven_tasya_daisu01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds01      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu01         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h2)
    gr_ext_attribs_id_rec.ven_tasya_cd02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd02      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd02                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔2)
    gr_ext_attribs_id_rec.ven_tasya_daisu02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds02      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu02         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h3)
    gr_ext_attribs_id_rec.ven_tasya_cd03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd03      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd03            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔3)
    gr_ext_attribs_id_rec.ven_tasya_daisu03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds03      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu03         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h4)
    gr_ext_attribs_id_rec.ven_tasya_cd04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd04      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd04                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔4)
    gr_ext_attribs_id_rec.ven_tasya_daisu04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds04          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu04             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h5)
    gr_ext_attribs_id_rec.ven_tasya_cd05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd05 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd05      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd05                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔5)
    gr_ext_attribs_id_rec.ven_tasya_daisu05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds05          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu05             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�p���t���O)
    gr_ext_attribs_id_rec.ven_haiki_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_haiki_flg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_haiki_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_haiki_flg       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_haiki_flg             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Y�敪)
    gr_ext_attribs_id_rec.ven_sisan_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_sisan_kbn
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_sisan_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_sisan_kbn       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_sisan_kbn             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�w�����t)
    gr_ext_attribs_id_rec.ven_kobai_ymd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_ymd
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_ymd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_ymd       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kobai_ymd             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�w�����z)
    gr_ext_attribs_id_rec.ven_kobai_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_kg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_kg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_kg        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kobai_kg              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���S�ݒu�)
    gr_ext_attribs_id_rec.safty_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_safty_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.safty_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_safty_level         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_safty_level               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���ݒu��ڋq�R�[�h)
    gr_ext_attribs_id_rec.last_inst_cust_code := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_inst_cust_code
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_inst_cust_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_inst_cust_code -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_inst_cust_code       -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���@����)
    gr_ext_attribs_id_rec.last_jotai_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_jotai_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_jotai_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_jotai_kbn      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_jotai_kbn            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���N��)
    gr_ext_attribs_id_rec.last_year_month := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_year_month
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_year_month IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_year_month     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_year_month           -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/*20090326_matsunaka_ST183 END*/
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �ǉ�����ID(�擾���i)
    gr_ext_attribs_id_rec.vd_shutoku_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_vd_shutoku_kg
                                             ,ld_process_date
                                           );
    IF ( gr_ext_attribs_id_rec.vd_shutoku_kg IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_54 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg                       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_vd_shutoku_kg             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �ǉ�����ID(�\���n)
    gr_ext_attribs_id_rec.dclr_place := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_dclr_place
                                          ,ld_process_date
                                        );
    IF ( gr_ext_attribs_id_rec.dclr_place IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_53 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg                       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_dclr_place                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- ========================
    -- �{��/�H��敪(�{��)�擾 
    -- ========================
    BEGIN
      SELECT ffvv.flex_value
      INTO   gv_owner_company
      FROM   fnd_flex_values_vl  ffvv
            ,fnd_flex_value_sets ffvs
      WHERE  ffvv.flex_value_set_id = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_cff_owner_company_type
      AND    ffvv.enabled_flag = 'Y'
      AND    ld_process_date BETWEEN NVL(ffvv.start_date_active,ld_process_date) 
                             AND     NVL(ffvv.end_date_active,ld_process_date)
      AND    ffvv.flex_value_meaning = (SELECT flvv1.meaning
                                        FROM   fnd_lookup_values_vl flvv1
                                        WHERE  flvv1.lookup_type = cv_cso_owner_company_type
                                        AND    flvv1.lookup_code = cv_cso_owner_company_code
                                        AND    ld_process_date BETWEEN NVL(flvv1.start_date_active,ld_process_date) 
                                                               AND     NVL(flvv1.end_date_active,ld_process_date)
                                        AND    flvv1.enabled_flag = 'Y');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_37             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_flex              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_value_set_name        -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_owner_company             -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_38             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_flex              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_value_set_name        -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_owner_company             -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--    
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
   * Procedure Name   : get_item_instances
   * Description      : ������񒊏o (A-2)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     in_file_id              IN     NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_instances'; -- �v���O������
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
    -- �e�[�u����
    cv_table_name            CONSTANT VARCHAR2(100) := '�t�@�C���A�b�v���[�hIF';
--
    -- *** ���[�J���ϐ� ***
    lv_file_name             xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    lv_msg                   VARCHAR2(5000);
--
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
  -- ***************************************************
  -- 1.CSV�t�@�C�����擾
  -- ***************************************************
    SELECT   xciwd.file_name
    INTO     lv_file_name
    FROM     xxccp_mrp_file_ul_interface    xciwd
    WHERE    xciwd.file_id = in_file_id;
--
    --�擾����CSV�t�@�C�������t�@�C���o��
    lv_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_39             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_csv_upload
                       ,iv_token_value1 => lv_file_name
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_msg       || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- ***************************************************
    -- 2.BLOB�f�[�^�ϊ�
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
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_40,    -- ���b�Z�[�W�F�f�[�^�ϊ��G���[
                     cv_tkn_table,
                     cv_table_name,
                     cv_tkn_file_id,
                     in_file_id,
                     cv_tkn_errmsg,
                     SQLERRM);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_validate
   * Description      : �f�[�^�Ó����`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_data_validate(
     it_blob_data            IN     xxccp_common_pkg2.g_file_data_tbl                  -- blob�f�[�^(�s�P��)
    ,in_data_num             IN     NUMBER                  -- �z��ԍ�
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_validate'; -- �v���O������
    -- �����R�[�h
    cv_object_code  CONSTANT VARCHAR2(100) := '�����R�[�h';
    -- �@��R�[�h
    cv_serial_code  CONSTANT VARCHAR2(100) := '�@��R�[�h';
    -- ���_�R�[�h
    cv_base_code    CONSTANT VARCHAR2(100) := '���_�R�[�h';
    -- �����f�[�^
    cv_object_data  CONSTANT VARCHAR2(100) := '�����f�[�^';

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
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
--    cn_format_col_cnt        CONSTANT NUMBER := 3;  -- ���ڐ�
    cn_format_col_cnt        CONSTANT NUMBER := 6;  -- ���ڐ�
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- *** ���[�J���ϐ� ***
    lv_object_front          VARCHAR2(3);
    lv_object_tail           VARCHAR2(6);
    lv_substr                VARCHAR2(1);
    lb_ret                   BOOLEAN;
    lb_format_flag           BOOLEAN := TRUE;
    lv_tmp                   VARCHAR2(2000);
    ln_pos                   NUMBER;
    ln_cnt                   NUMBER := 1;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    lv_msg                   VARCHAR2(5000);
    lv_vd_shutoku_kg         VARCHAR2(2000); -- �`�F�b�N�p
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
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
    -- ***************************************************
    -- 1.���ڐ��擾
    -- ***************************************************
    IF (it_blob_data(in_data_num) IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := it_blob_data(in_data_num);
      LOOP
        ln_pos := INSTR(lv_tmp, cv_msg_conm);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.���ڐ��`�F�b�N
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_51           -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_object_data             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_value          -- �g�[�N���R�[�h1
                     ,iv_token_value2 => it_blob_data(in_data_num)  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- ***************************************************
    -- 2.blob�f�[�^����
    -- ***************************************************
    --�����R�[�h
    gr_blob_data.object_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,1);
    IF (gr_blob_data.object_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�@��R�[�h
    gr_blob_data.serial_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,2);
    IF (gr_blob_data.serial_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_serial_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --���_�R�[�h
    gr_blob_data.base_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                   ,cv_msg_conm
                                                                   ,3);
    IF (gr_blob_data.base_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_base_code,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- ���[�X�敪
    gr_blob_data.lease_kbn := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                   ,cv_msg_conm
                                                                   ,4);
--
    -- �\���n
    gr_blob_data.dclr_place := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                    ,cv_msg_conm
                                                                    ,5);
--
    -- �擾���i
    lv_vd_shutoku_kg := NULL;
    lv_vd_shutoku_kg := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                             ,cv_msg_conm
                                                             ,6);
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- ***************************************************
    -- 3.���ڒl�Ó����`�F�b�N
    -- ***************************************************
    --�����R�[�h�����`�F�b�N
    lv_substr := SUBSTRB(gr_blob_data.object_code,4,1);
    IF (lv_substr = '-') THEN
      lv_object_front := SUBSTRB(gr_blob_data.object_code,1,3);
      lv_object_tail  := SUBSTRB(gr_blob_data.object_code,5);
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                   cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                   cv_tkn_number_42,
                   cv_tkn_base_value,
                   gr_blob_data.object_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �擾���i�}�C�i�X�l�`�F�b�N
    lv_substr := SUBSTRB(lv_vd_shutoku_kg,1,1);
    IF ( lv_substr = cv_hyphen ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_54 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_60
                     ,cv_tkn_eigyo
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    --�����R�[�h���p�����`�F�b�N
    lb_ret := xxccp_common_pkg.chk_number(
                iv_check_char   => lv_object_front||lv_object_tail);
    IF (lb_ret = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_43,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     gr_blob_data.object_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �擾���i���p�����`�F�b�N
    lb_ret := xxccp_common_pkg.chk_number(
                iv_check_char   => lv_vd_shutoku_kg
              );
    IF ( lb_ret = FALSE ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_54 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_43
                     ,cv_tkn_item
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    --�����R�[�hLENGTH�`�F�b�N
    IF (LENGTHB(gr_blob_data.object_code) <> 10) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_44,
                     cv_tkn_item,
                     cv_object_code,
                     cv_tkn_base_value,
                     gr_blob_data.object_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�@��R�[�hLENGTH�`�F�b�N
    IF (LENGTHB(gr_blob_data.serial_code) > 14) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_44,
                     cv_tkn_item,
                     cv_serial_code,
                     cv_tkn_base_value,
                     gr_blob_data.serial_code
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �擾���iLENGTH�`�F�b�N
    IF ( LENGTHB(lv_vd_shutoku_kg) > 10 ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_tkn_number_54 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_app_name
                     ,cv_tkn_number_44
                     ,cv_tkn_item
                     ,lv_msg
                     ,cv_tkn_base_value
                     ,lv_vd_shutoku_kg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    gr_blob_data.vd_shutoku_kg := lv_vd_shutoku_kg;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
  END chk_data_validate;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_master
   * Description      : �f�[�^�}�X�^�`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_master(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_master'; -- �v���O������
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
    -- �e�[�u����
    cv_table_object          CONSTANT VARCHAR2(100) := '�C���X�g�[���x�[�X�}�X�^';
    cv_table_serial          CONSTANT VARCHAR2(100) := '�@��}�X�^�r���[';
    cv_table_hazard          CONSTANT VARCHAR2(100) := '�@��敪�}�X�^�r���[';
    cv_select_process        CONSTANT VARCHAR2(100) := '���o';
    cv_object_code           CONSTANT VARCHAR2(100) := '�����R�[�h';
    cv_serial_code           CONSTANT VARCHAR2(100) := '�@��R�[�h';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt          NUMBER;
    lv_hazard_class po_un_numbers_vl.hazard_class_id%TYPE;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    lv_msg                   VARCHAR2(5000);
    lv_msg2                  VARCHAR2(5000);
    lb_ret                   BOOLEAN DEFAULT TRUE;
    lt_lease_kbn             po_un_numbers_vl.attribute13%TYPE; -- ���[�X�敪
    lt_vd_shutoku_kg         po_un_numbers_vl.attribute14%TYPE; -- �擾���i
    lt_dclr_place            fnd_flex_values.flex_value%TYPE;   -- �\���n
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
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
  -- ***************************************************
  -- 1.�����R�[�h�d���`�F�b�N
  -- ***************************************************
    BEGIN
      SELECT COUNT(instance_id)
      INTO   ln_cnt
      FROM   csi_item_instances
      WHERE  external_reference = gr_blob_data.object_code;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_table_object               -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => SQLERRM                       -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_process                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_select_process             -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF (ln_cnt > 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name          => cv_tkn_number_46              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1   => cv_tkn_bukken                 -- �g�[�N���R�[�h1
                     ,iv_token_value1  => gr_blob_data.object_code      -- �g�[�N���l1
                     ,iv_token_name2   => cv_tkn_base_value             -- �g�[�N���R�[�h2
                     ,iv_token_value2  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                          cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l2
      );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  -- ***************************************************
  -- 2.�@��}�X�^���݃`�F�b�N
  -- ***************************************************
    BEGIN
      SELECT flvv.meaning
            ,punv.attribute3
            ,punv.hazard_class_id
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
            ,punv.attribute13
            ,punv.attribute14
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
      INTO   gv_maker_name
            ,gv_age_type
            ,lv_hazard_class
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
            ,lt_lease_kbn
            ,lt_vd_shutoku_kg
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
      FROM   po_un_numbers_vl punv
            ,fnd_lookup_values_vl flvv
      WHERE  punv.un_number = gr_blob_data.serial_code
      AND    TRUNC(NVL(punv.inactive_date,gd_process_date + 1)) > TRUNC(gd_process_date)
      AND    flvv.lookup_type = 'XXCSO_CSI_MAKER_CODE'
      AND    flvv.lookup_code(+) = punv.attribute2
      AND    TRUNC(gd_process_date) BETWEEN NVL(flvv.start_date_active, TRUNC(gd_process_date))
                                   AND     NVL(flvv.end_date_active, TRUNC(gd_process_date))
      AND    flvv.enabled_flag = 'Y';
--
    EXCEPTION
      -- ���o�ł��Ȃ������ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_47              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_item                   -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_serial_code                -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_value                  -- �g�[�N���R�[�h2
                       ,iv_token_value2  => gr_blob_data.serial_code      -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_table                  -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_table_serial               -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_table_serial               -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => SQLERRM                       -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_process                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_select_process             -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  -- ***************************************************
  -- 3.�@��敪�}�X�^���݃`�F�b�N
  -- ***************************************************
    BEGIN
      SELECT phcv.hazard_class
      INTO   gv_hazard_class
      FROM   po_hazard_classes_vl phcv
      WHERE  phcv.hazard_class_id = lv_hazard_class
      AND    TRUNC(NVL(phcv.inactive_date,gd_process_date + 1)) > TRUNC(gd_process_date);
--
    EXCEPTION
      -- ���o�ł��Ȃ������ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_50              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_value                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => gr_blob_data.serial_code      -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_value2                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => lv_hazard_class               -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value3  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_table_hazard               -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => SQLERRM                       -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_process                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_select_process             -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
  -- ***************************************************
  -- 4.���[�X�敪�`�F�b�N
  -- ***************************************************
    -- �����f�[�^�̃��[�X�敪�ɒl���ݒ肳��Ă��Ȃ��ꍇ
    IF ( gr_blob_data.lease_kbn IS NULL ) THEN
      -- �@��}�X�^�̒l��ݒ�
      gr_blob_data.lease_kbn := lt_lease_kbn;
    END IF;
    --
    -- �@��}�X�^�̃��[�X�敪��NULL�ł���ꍇ
    IF ( gr_blob_data.lease_kbn IS NULL ) THEN
      lv_msg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_52 -- ���b�Z�[�W
                   );
      lv_msg2   := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_55 -- ���b�Z�[�W
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_56               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_msg2                        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_base_value              -- �g�[�N���R�[�h3
                     ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                         gr_blob_data.serial_code || cv_msg_conm ||
                                         gr_blob_data.base_code   || cv_msg_conm ||
                                         gr_blob_data.lease_kbn   || cv_msg_conm ||
                                         gr_blob_data.dclr_place  || cv_msg_conm ||
                                         gr_blob_data.vd_shutoku_kg     -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ���[�X�敪�̃}�X�^�`�F�b�N
    BEGIN
      SELECT flvv.lookup_code     lookup_code
      INTO   lt_lease_kbn
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcso1_lease_kbn
      AND    flvv.lookup_code  = gr_blob_data.lease_kbn
      AND    flvv.enabled_flag = cv_y
      AND    gd_process_date   BETWEEN NVL(flvv.start_date_active, gd_process_date)
                               AND     NVL(flvv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_52               -- ���b�Z�[�W
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_57               -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_lookup_type_name        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_xxcso1_lease_kbn            -- �g�[�N���l1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_56               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg2                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_value              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_57               -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_lookup_type_name        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_xxcso1_lease_kbn            -- �g�[�N���l1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_45               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg2                        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_process                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_select_process              -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_base_value              -- �g�[�N���R�[�h4
                       ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  -- ***************************************************
  -- 5.�\���n�`�F�b�N
  -- ***************************************************
    -- ���[�X�敪���Œ莑�Y�ȊO�̏ꍇ
    IF ( gr_blob_data.lease_kbn <> cv_fixed_assets ) THEN
      -- NULL��ݒ�
      gr_blob_data.dclr_place := NULL;
    -- ���[�X�敪���Œ莑�Y�̏ꍇ
    ELSIF ( gr_blob_data.lease_kbn = cv_fixed_assets ) THEN
      -- �\���n�ɒl���ݒ肳��Ă��Ȃ��ꍇ
      IF ( gr_blob_data.dclr_place IS NULL ) THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_53               -- ���b�Z�[�W
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_59               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_base_value              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
      --
      -- �\���n�̃}�X�^�`�F�b�N
      BEGIN
        SELECT ffv.flex_value       flex_value
        INTO   lt_dclr_place
        FROM   fnd_flex_values      ffv
              ,fnd_flex_values_tl   ffvt
              ,fnd_flex_value_sets  ffvs
        WHERE  ffv.flex_value_id        = ffvt.flex_value_id
        AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
        AND    ffvs.flex_value_set_name = cv_xxcff_dclr_place
        AND    gd_process_date BETWEEN NVL(ffv.start_date_active, gd_process_date)
                               AND     NVL(ffv.end_date_active, gd_process_date)
        AND    ffv.enabled_flag         = cv_y
        AND    ffvt.language            = ct_language
        AND    ffv.flex_value           = gr_blob_data.dclr_place
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_53               -- ���b�Z�[�W
                       );
          lv_msg2   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_58               -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_value_set_name          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_xxcff_dclr_place            -- �g�[�N���l1
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_56               -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                         ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                         ,iv_token_value2 => lv_msg2                        -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_value              -- �g�[�N���R�[�h3
                         ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                             gr_blob_data.serial_code || cv_msg_conm ||
                                             gr_blob_data.base_code   || cv_msg_conm ||
                                             gr_blob_data.lease_kbn   || cv_msg_conm ||
                                             gr_blob_data.dclr_place  || cv_msg_conm ||
                                             gr_blob_data.vd_shutoku_kg     -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_msg2   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_58               -- ���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_value_set_name          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_xxcff_dclr_place            -- �g�[�N���l1
                       );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_45               -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                   -- �g�[�N���R�[�h1
                         ,iv_token_value1 => lv_msg2                        -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_errmsg                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                        -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_process                 -- �g�[�N���R�[�h3
                         ,iv_token_value3 => cv_select_process              -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_base_value              -- �g�[�N���R�[�h4
                         ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                             gr_blob_data.serial_code || cv_msg_conm ||
                                             gr_blob_data.base_code   || cv_msg_conm ||
                                             gr_blob_data.lease_kbn   || cv_msg_conm ||
                                             gr_blob_data.dclr_place  || cv_msg_conm ||
                                             gr_blob_data.vd_shutoku_kg     -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  -- ***************************************************
  -- 6.�擾���i�`�F�b�N
  -- ***************************************************
    -- ���[�X�敪���Œ莑�Y�ȊO�̏ꍇ
    IF ( gr_blob_data.lease_kbn <> cv_fixed_assets ) THEN
      -- NULL��ݒ�
      gr_blob_data.vd_shutoku_kg := NULL;
    -- ���[�X�敪���Œ莑�Y�̏ꍇ
    ELSIF ( gr_blob_data.lease_kbn = cv_fixed_assets ) THEN
      -- �����f�[�^�̎擾���i�ɒl���ݒ肳��Ă��Ȃ��ꍇ
      IF ( gr_blob_data.vd_shutoku_kg IS NULL ) THEN
        -- �@��}�X�^�̒l��ݒ�
        gr_blob_data.vd_shutoku_kg := lt_vd_shutoku_kg;
      END IF;
      --
      -- �擾���i�ɒl���ݒ肳��Ă��Ȃ��ꍇ
      IF ( gr_blob_data.vd_shutoku_kg IS NULL ) THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_54               -- ���b�Z�[�W
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_55               -- ���b�Z�[�W
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_56               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg2                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_value              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.serial_code || cv_msg_conm ||
                                           gr_blob_data.base_code   || cv_msg_conm ||
                                           gr_blob_data.lease_kbn   || cv_msg_conm ||
                                           gr_blob_data.dclr_place  || cv_msg_conm ||
                                           gr_blob_data.vd_shutoku_kg     -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
  END chk_data_master;
--
  /**********************************************************************************
   * Procedure Name   : get_custmer_data
   * Description      : �ڋq���擾���� (A-5)
   ***********************************************************************************/
  PROCEDURE get_custmer_data(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_custmer_data'; -- �v���O������
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
    cv_table_cust            CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�T�C�g�r���[';
    cv_select_process        CONSTANT VARCHAR2(100) := '���o';
    cv_item_cust             CONSTANT VARCHAR2(100) := '�ڋq�R�[�h';
--
    -- *** ���[�J���ϐ� ***
--
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
  -- ***************************************************
  -- 1.�ڋq���擾
  -- ***************************************************
    BEGIN
      SELECT casv.cust_account_id                                   -- �A�J�E���gID
            ,casv.location_id                                       -- ���P�[�V����ID
            ,casv.party_id                                          -- �p�[�e�BID
            ,casv.party_site_id                                     -- �p�[�e�B�T�C�gID
            /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� START */
            --,casv.established_site_name                             -- �ݒu�於
            ,casv.party_name                                        -- �ݒu�於
            /* 2010.01.13 K.Hosoi E_�{�ғ�_00443�Ή� END */
            ,casv.state||casv.city||casv.address1||casv.address2    -- �ݒu��Z��
            ,casv.area_code                                         -- �n��R�[�h
      INTO   gn_account_id
            ,gn_locatoin_id
            ,gn_party_id
            ,gn_party_site_id
            ,gv_established_site
            ,gv_address
            ,gv_address3
      FROM   xxcso_cust_acct_sites_v casv                           -- �ڋq�}�X�^�T�C�g�r���[
      WHERE  casv.account_number    = gr_blob_data.base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_47              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_item                   -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_item_cust                  -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_value                  -- �g�[�N���R�[�h2
                       ,iv_token_value2  => gr_blob_data.base_code        -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_table                  -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_table_cust                 -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_table_cust                 -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => SQLERRM                       -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_process                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_select_process             -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
  END get_custmer_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_item_instances
   * Description      : �����f�[�^�o�^���� (A-7)
   ***********************************************************************************/
  PROCEDURE insert_item_instances(
     ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_item_instances'; -- �v���O������
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
    cn_num1                  CONSTANT NUMBER        := 1;
    cn_api_version           CONSTANT NUMBER        := 1.0;
    cv_kbn0                  CONSTANT NUMBER        := '0';
    cv_kbn1                  CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                  CONSTANT VARCHAR2(1)   := '2'; 
    cv_unit_of_measure       CONSTANT VARCHAR2(10)  := '��';                -- �P��
    cv_xxcso_ib_info_h       CONSTANT VARCHAR2(100) := '�����֘A���ύX�����e�[�u��';    -- ���o���e
    cv_inst_base_insert      CONSTANT VARCHAR2(100) := '�C���X�g�[���x�[�X�}�X�^';
    cv_insert_process        CONSTANT VARCHAR2(100) := '�o�^';
    cv_location_type_code    CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- ���s���Ə��^�C�v
    cv_instance_usage_code   CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- �C���X�^���X�g�p�R�[�h
    cv_party_source_table    CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- �p�[�e�B�\�[�X�e�[�u��
    cv_relatnsh_type_code    CONSTANT VARCHAR2(100) := 'OWNER';             -- �����[�V�����^�C�v
    cv_flg_no                CONSTANT VARCHAR2(1)   := 'N';                 -- �t���ONO
    /*20090326_matsunaka_ST183 START*/
    cv_flg_yes               CONSTANT VARCHAR2(1)   := 'Y';                 -- �t���OYES
    /*20090326_matsunaka_ST183 END*/
--
    -- *** ���[�J���ϐ� ***
    ln_validation_level        NUMBER;                  -- �o���f�[�V�������[�x��
    lv_commit                  VARCHAR2(1);             -- �R�~�b�g�t���O
    lv_init_msg_list           VARCHAR2(2000);          -- ���b�Z�[�W���X�g
    ln_cnt                     NUMBER;                  -- �z��ԍ�
--
    -- API�߂�l�i�[�p
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API���o�̓��R�[�h�l�i�[�p
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
--
    -- *** ���[�J����O ***
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- �f�[�^�̊i�[
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;

    -- ================================
    -- 1.�C���X�^���X���R�[�h�쐬
    -- ================================
    l_instance_rec.external_reference         := gr_blob_data.object_code;     -- �O���Q��
    l_instance_rec.inventory_item_id          := gt_bukken_item_id;            -- �݌ɕi��ID
    l_instance_rec.vld_organization_id        := gt_vld_org_id;                -- ���ؑg�DID
    l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- �݌Ƀ}�X�^�[�g�DID
    l_instance_rec.quantity                   := cn_num1;                      -- ����
    l_instance_rec.unit_of_measure            := cv_unit_of_measure;           -- �P��
    l_instance_rec.instance_status_id         := gt_instance_status_id_2;      -- �C���X�^���X�X�e�[�^�XID
/* 2014.08.27 S.Yamashita E_�{�ғ�_11719�Ή� START */
--    l_instance_rec.instance_type_code         := SUBSTRB(gv_hazard_class,1,1); -- �C���X�^���X�^�C�v�R�[�h
    l_instance_rec.instance_type_code         := SUBSTRB(gv_hazard_class,1,INSTRB(gv_hazard_class,cv_msg_part_only,1,1)-1); -- �C���X�^���X�^�C�v�R�[�h
/* 2014.08.27 S.Yamashita E_�{�ғ�_11719�Ή� END */
    l_instance_rec.location_type_code         := cv_location_type_code;        -- ���s���Ə��^�C�v
    l_instance_rec.location_id                := gn_party_site_id;             -- ���s���Ə�ID
    l_instance_rec.install_date               := gd_process_date;              -- ������
    l_instance_rec.attribute1                 := gr_blob_data.serial_code;     -- �@��(�R�[�h)
    l_instance_rec.attribute4                 := cv_flg_no;                    -- ��ƈ˗����t���O
    /*20090326_matsunaka_ST183 START*/
    l_instance_rec.attribute5                 := cv_flg_yes;                   -- �V�Ñ�t���O
    /*20090326_matsunaka_ST183 END*/
    l_instance_rec.instance_usage_code        := cv_instance_usage_code;       -- �C���X�^���X�g�p�R�[�h
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ==================================
    -- 2.�o�^�p�ݒu�@��g�������l���쐬
    -- ==================================
    -- �@����1�i�ғ���ԁj
    ln_cnt := 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn2;
--
    -- �@����2�i��ԏڍׁj
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- �@����3�i�p�����j
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- ���[�X�敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.lease_kbn;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
--    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.lease_kbn;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- �n��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.chiku_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gv_address3;
--
/*20090326_matsunaka_ST183 START*/
    -- �J�E���^�[No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.count_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ��Ɖ�ЃR�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyougaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Ə��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jigyousyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI��Ɠ`�[No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI��Ƌ敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI��Ɛi��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI��Ɗ����\���
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.yotei_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI��Ɗ�����
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI�������e
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyo_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI�ݒu�`�[No.2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI�ݒu�敪2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI�ݒu�i��2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ɓ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.nyuko_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���g��ЃR�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakigaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���g���Ə��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakijigyosyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ݒu��S���Җ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ݒu��tel1
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ݒu��tel2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ݒu��tel3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �p�����ٓ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.haikikessai_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �]���p���Ǝ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �]���p���`�[��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���L��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.syoyu_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �]���p���󋵃t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �]�������敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �폜�t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sakujo_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �ŏI�ڋq�R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kyaku_last;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ЃR�[�h�P
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Б䐔�P
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ЃR�[�h�Q
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Б䐔�Q
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ЃR�[�h�R
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Б䐔�R
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ЃR�[�h�S
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Б䐔�S
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���ЃR�[�h�T
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���Б䐔�T
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �p���t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_haiki_flg;
    /*20090522_Ohtsuki_T1_1141 START*/
--    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--��������������������������������������������������������������������������������������������������
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;                                     --( 0 = ���ݒ� )
    /*20090522_Ohtsuki_T1_1141 END  */
--
    -- ���Y�敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_sisan_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �w�����t
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_ymd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �w�����z
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- ���S�ݒu�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.safty_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �挎���ݒu��ڋq�R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �挎���@����
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
--
    -- �挎���N��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := NULL;
/*20090326_matsunaka_ST183 END*/
--
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �擾���i
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.vd_shutoku_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.vd_shutoku_kg;
--
    -- �\���n
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.dclr_place;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := gr_blob_data.dclr_place;
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
--
    -- ====================
    -- 3.�p�[�e�B�f�[�^�쐬
    -- ====================
--
    ln_cnt := 1;
    l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
    l_party_tab(ln_cnt).party_id                 := gn_party_id;
    l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
    l_party_tab(ln_cnt).contact_flag             := cv_flg_no;
--
    -- ===============================
    -- 4.�p�[�e�B�A�J�E���g�f�[�^�쐬
    -- ===============================
--
    ln_cnt := 1;
    l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
    l_account_tab(ln_cnt).party_account_id       := gn_account_id;
    l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
--
    -- ===============================
    -- 5.������R�[�h�f�[�^�쐬
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 6.�W��API���A�����o�^�������s��
    -- =================================
--
    CSI_ITEM_INSTANCE_PUB.create_item_instance(
       p_api_version           => cn_api_version
      ,p_commit                => lv_commit
      ,p_init_msg_list         => lv_init_msg_list
      ,p_validation_level      => ln_validation_level
      ,p_instance_rec          => l_instance_rec
      ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      ,p_party_tbl             => l_party_tab
      ,p_account_tbl           => l_account_tab
      ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
      ,p_org_assignments_tbl   => l_org_assignments_tab
      ,p_asset_assignment_tbl  => l_asset_assignment_tab
      ,p_txn_rec               => l_txn_rec
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
--
    -- ����I���łȂ��ꍇ
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (FND_MSG_PUB.Count_Msg > 0) THEN
        FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.Get(
             p_msg_index     => i
            ,p_encoded       => cv_encoded_f
            ,p_data          => lv_io_msg_data
            ,p_msg_index_out => ln_io_msg_count
          );
          lv_msg_data := lv_msg_data || lv_io_msg_data;
        END LOOP;
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1  => cv_inst_base_insert           -- �g�[�N���l1
                     ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                     ,iv_token_value2  => cv_insert_process             -- �g�[�N���l2
                     ,iv_token_name3   => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                     ,iv_token_value3  => lv_msg_data                       -- �g�[�N���l3
                     ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                     ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                          cv_msg_conm||gr_blob_data.base_code   -- �g�[�N���l4
                   );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
    END IF;
--
    -- ========================================
    -- 7.�����֘A���ύX�����e�[�u���̓o�^����
    -- ========================================
    BEGIN
      INSERT INTO xxcso_ib_info_h(
         install_code                           -- �����R�[�h
        ,history_creation_date                  -- �����쐬��
        ,interface_flag                         -- �A�g�σt���O
        ,po_number                              -- �����ԍ�
        ,manufacturer_name                      -- ���[�J�[��
        ,age_type                               -- �N��
        ,un_number                              -- �@��
        ,install_number                         -- �@��
        ,quantity                               -- ����
        ,base_code                              -- ���_�R�[�h
        ,owner_company_type                     -- �{�Ё^�H��敪
        ,install_name                           -- �ݒu�於
        ,install_address                        -- �ݒu��Z��
        ,logical_delete_flag                    -- �_���폜�t���O
        ,account_number                         -- �ڋq�R�[�h
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
        ,declaration_place                       -- �\���n
        ,disposal_intaface_flag                  -- �p���A�g�t���O
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
        ,created_by                             -- �쐬��
        ,creation_date                          -- �쐬��
        ,last_updated_by                        -- �ŏI�X�V��
        ,last_update_date                       -- �ŏI�X�V��
        ,last_update_login                      -- �ŏI�X�V���O�C��
        ,request_id                             -- �v��ID
        ,program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                             -- �R���J�����g�E�v���O����ID	PROGRAM_ID
        ,program_update_date                    -- �v���O�����X�V��
      )VALUES(
         gr_blob_data.object_code               -- �����R�[�h
        ,gd_process_date                        -- �����쐬��
        ,cv_flg_no                              -- �A�g�σt���O
        ,NULL                                   -- �����ԍ�
        ,gv_maker_name                          -- ���[�J�[��
        ,gv_age_type                            -- �N��
        ,gr_blob_data.serial_code               -- �@��
        ,NULL                                   -- �@��
        ,cn_num1                                -- ����
        ,gr_blob_data.base_code                 -- ���_�R�[�h
        ,gv_owner_company                       -- �{�Ё^�H��敪
        ,gv_established_site                    -- �ݒu�於
        ,gv_address                             -- �ݒu��Z��
        ,cv_flg_no                              -- �_���폜�t���O
        ,gr_blob_data.base_code                 -- �ڋq�R�[�h
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� START */
        ,gr_blob_data.dclr_place                -- �\���n
        ,cv_flg_no                              -- �p���A�g�t���O
/* 2014-05-19 K.Nakamura E_�{�ғ�_11853�Ή� END */
        ,cn_created_by                          -- �쐬��
        ,SYSDATE                                -- �쐬��
        ,cn_last_updated_by                     -- �ŏI�X�V��
        ,SYSDATE                                -- �ŏI�X�V��
        ,cn_last_update_login                   -- �ŏI�X�V���O�C��
        ,cn_request_id                          -- �v��ID
        ,cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                          -- �R���J�����g�E�v���O����ID	PROGRAM_ID
        ,SYSDATE                                -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_xxcso_ib_info_h            -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_insert_process             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => SQLERRM                       -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code   -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                   '�G���[�F'||lv_errmsg|| CHR(10) ||
                   ''                           -- ��s�̑}��
      );
--
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
  END insert_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : rock_file_interface
   * Description      : �t�@�C���A�b�v���[�hIF���b�N���� (A-8)
   ***********************************************************************************/
  PROCEDURE rock_file_interface(
     in_file_id              IN  NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_file_interface'; -- �v���O������
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
    cv_table_name              CONSTANT VARCHAR2(100)   := '�t�@�C���A�b�v���[�hIF';
    cv_lock_process            CONSTANT VARCHAR2(100)   := '���b�N';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E���R�[�h ***
    CURSOR rock_interface_cur IS
      SELECT xmfui.file_id
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
   rock_interface_rec rock_interface_cur%ROWTYPE;
--
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
    -- �t�@�C���A�b�v���[�hIF���o
    BEGIN
--
      OPEN rock_interface_cur;
      FETCH rock_interface_cur INTO rock_interface_rec;
      CLOSE rock_interface_cur;
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_49              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                       -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_table_name                 -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_lock_process               -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => SQLERRM                       -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.serial_code||
                                            cv_msg_conm||gr_blob_data.base_code   -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
  END rock_file_interface;
--
   /**********************************************************************************
   * Procedure Name   : delete_in_item_data
   * Description      : �����f�[�^���[�N�e�[�u���폜����(A-9)
   ***********************************************************************************/
  PROCEDURE delete_in_item_data(
     in_file_id              IN  NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_in_item_data';  -- �v���O������
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
    cv_table_name            CONSTANT  VARCHAR2(100)  := '�t�@�C���A�b�v���[�hIF';
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E��O ***
    delete_error_expt        EXCEPTION;
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
      -- ==========================================
      -- �������[�N�e�[�u���폜���� 
      -- ==========================================
      DELETE  
      FROM xxccp_mrp_file_ul_interface                  -- �������[�N�e�[�u��
      WHERE file_id = in_file_id;
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_48             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => in_file_id                   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;
--
  EXCEPTION
--
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ������O�n���h�� ***
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_in_item_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    in_file_id    IN  NUMBER,       --   �t�@�C��ID
    iv_format     IN  VARCHAR2)     --   �t�H�[�}�b�g�p�^�[��
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    skip_process_expt       EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
--
    init(
       in_file_id            => in_file_id          -- �t�@�C��ID
      ,iv_format             => iv_format           -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�����}�X�^��񒊏o����
    -- ========================================
    get_item_instances(
       in_file_id       => in_file_id     -- �t�@�C��ID
      ,ov_errbuf        => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode       => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg        => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����Ώی����i�[
    gn_target_cnt := gr_file_data_tbl.COUNT;
--
    FOR i IN gr_file_data_tbl.FIRST..gr_file_data_tbl.LAST LOOP
      -- ===========================
      -- A-3�f�[�^�Ó����`�F�b�N����
      -- ===========================
      chk_data_validate(
        it_blob_data => gr_file_data_tbl
       ,in_data_num  => i
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-4�f�[�^�}�X�^�`�F�b�N����
      -- ===========================
      chk_data_master(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-5�ڋq���擾����
      -- ===========================
      get_custmer_data(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-7.�����f�[�^�o�^����
      -- ========================================
      insert_item_instances(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
--
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP;
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_32             --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- �G���[���b�Z�[�W
      );
--     
    ELSE 
      -- ========================================
      -- A-8.�t�@�C���A�b�v���[�hIF���b�N����
      -- ========================================
      rock_file_interface(
        in_file_id   => in_file_id     -- �t�@�C��ID
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
  --
      -- ========================================
      -- A-9.�����f�[�^���[�N�e�[�u���폜����
      -- ========================================
      delete_in_item_data(
        in_file_id   => in_file_id     -- �t�@�C��ID
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf        OUT  NOCOPY  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT  NOCOPY  VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id    IN   NUMBER,                --   �t�@�C��ID
    iv_format     IN   VARCHAR2               --   �t�H�[�}�b�g�p�^�[��
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
      ov_errbuf   => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode  => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg   => lv_errmsg,           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      in_file_id  => in_file_id,          -- �t�@�C��ID
      iv_format   => iv_format            -- �t�@�C���t�H�[�}�b�g
    );
--
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
    -- A-13.�I������ 
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO012A02C;
/
