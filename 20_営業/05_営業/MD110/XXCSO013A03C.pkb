CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO013A03C(body)
 * Description      : �Œ莑�Y�̕��������[�X�EFA�̈�ɘA�g����OIF�f�[�^���쐬���܂��B
 * MD.050           : CSI��FA�C���^�t�F�[�X�F�iOUT�j�Œ莑�Y���Y��� <MD050_CSO_013_A03>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_xxcff_if           ���̋@�����Ǘ��C���^�t�F�[�X�o�^����(A-8)
 *  upd_xxcso_ib_info_h    �����֘A�ύX�����e�[�u���X�V����(A-7)
 *  lock_xxcso_ib_info_h   �����֘A�ύX�����e�[�u�����b�N����(A-6)
 *  chk_xxcff_if_exists    ���̋@�����Ǘ��C���^�t�F�[�X���݃`�F�b�N(A-5)
 *  chk_xxcso_ib_info_h    �����֘A���ύX�`�F�b�N����(A-4)
 *  get_relation_data      �����֘A���擾(A-3)
 *  get_target_data        �Ώە������o(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/06/10    1.0   Kazuyuki Kiriu   �V�K�쐬
 * 2016/02/09    1.1   H.Okada          E_�{�ғ�_13456�Ή�
 * 2023/04/05    1.2   M.Akachi         E_�{�ғ�_18758�Ή�
 * 2024/04/19    1.3   M.Akachi         E_�{�ғ�_19496�Ή�
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
  global_lock_expt          EXCEPTION;       -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO013A03C';   -- �p�b�P�[�W��
--
  cv_app_name               CONSTANT VARCHAR2(5)   := 'XXCSO';          -- �A�v���P�[�V�����Z�k��
--
  --���b�Z�[�W
  cv_msg_param_date         CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00147';  -- �p�����[�^�������s��
  cv_msg_proc_date_err      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- �Ɩ��������擾�G���[���b�Z�[�W
  cv_msg_prof_err           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_status_id_err      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00164';  -- �X�e�[�^�XID���o�G���[���b�Z�[�W
  cv_msg_lookup_err         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- �Q�ƃ^�C�v���o�G���[���b�Z�[�W
  cv_tkn_lookup_no_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- �Q�ƃ^�C�v�Ȃ��G���[���b�Z�[�W
  cv_msg_no_data1_wrn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- �f�[�^�Ȃ��x�����b�Z�[�W
  cv_msg_no_data2_wrn       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00708';  -- �f�[�^�Ȃ����b�Z�[�W(�L�[�t��)
  cv_msg_get_data1_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- ���o�G���[���b�Z�[�W
  cv_msg_get_data2_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00709';  -- ���o�G���[���b�Z�[�W(�L�[�t��)
  cv_msg_if_exists_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00701';  -- ���̋@�����Ǘ�IF���݃G���[
  cv_msg_data_dml_err       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- DML�G���[���b�Z�[�W
  cv_msg_status_id          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00687';  -- �C���X�^���X�X�e�[�^�X�}�X�^(�Œ�)
  cv_msg_status_nm          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00688';  -- �����폜(�Œ�)
  cv_msg_lookup_type        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00689';  -- �Q�ƃ^�C�v(�Œ�)
  cv_msg_lookup_code1       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00690';  -- INV �H��ԕi�q�֐�R�[�h(�Œ�)
  cv_msg_inst_relat_data    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00691';  -- �����֘A���(�Œ�)
  cv_msg_instance_id        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00692';  -- ����ID(�Œ�)
  cv_msg_model              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00693';  -- �@��(�Œ�l)
  cv_msg_model_code         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00694';  -- �@��R�[�h(�Œ�)
  cv_msg_instance_code      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- �����R�[�h(�Œ�)
  cv_msg_sale_base          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00697';  -- ���㋒�_(�Œ�)
  cv_msg_owner_comp_type    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00698';  -- �{��/�H��敪(�Œ�)
  cv_msg_mng_place          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00699';  -- ���Ə�(�Œ�)
  cv_msg_if_name            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00700';  -- ���̋@�����Ǘ��C���^�t�F�[�X(�Œ�)
  cv_msg_create             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00702';  -- �o�^(�Œ�)
  cv_msg_update             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- �X�V(�Œ�)
  cv_msg_lock               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00704';  -- ���b�N(�Œ�)
  cv_msg_ib_info            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00705';  -- �����֘A�ύX�����e�[�u��(�Œ�)
  cv_msg_dclr_place         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- �\���n(�Œ�)
  cv_msg_cust_shift_err     CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00706';  -- �ڋq�ڍs���e�[�u��(�Œ�)
  cv_msg_cust_code          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';  -- �ڋq�R�[�h(�Œ�)
  -- �g�[�N���R�[�h
  cv_tkn_value              CONSTANT VARCHAR2(20)  := 'VALUE';
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_task_name          CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_status_name        CONSTANT VARCHAR2(20)  := 'STATUS_NAME';
  cv_tkn_err_msg            CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_tkn_item               CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_base_value         CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_bukken             CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_process            CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_key                CONSTANT VARCHAR2(20)  := 'KEY';
  cv_tkn_key_value          CONSTANT VARCHAR2(20)  := 'KEY_VALUE';
  -- �v���t�@�C��
  cv_prf_cust_cd_dammy      CONSTANT VARCHAR2(30)  := 'XXCSO1_AFF_CUST_CODE';       -- XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j
  cv_prof_org_id            CONSTANT VARCHAR2(30)  := 'ORG_ID';                     -- MO:�c�ƒP��
  cv_attribute_level        CONSTANT VARCHAR2(30)  := 'XXCSO1_IB_ATTRIBUTE_LEVEL';  -- XXCSO:IB�g�������e���v���[�g�A�N�Z�X���x��
-- Ver.1.3 Del Start
--  cv_withdraw_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_CODE';  -- XXCSO:���g���_�R�[�h
-- Ver.1.3 Del End
  -- �Q�ƃ^�C�v
  cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
  cv_csi_inst_type_code     CONSTANT VARCHAR2(30)  := 'CSI_INST_TYPE_CODE';
  cv_xxcoi_mfg_fctory_cd    CONSTANT VARCHAR2(30)  := 'XXCOI_MFG_FCTORY_CD';
  cv_xxcso_csi_maker_code   CONSTANT VARCHAR2(30)  := 'XXCSO_CSI_MAKER_CODE';
  cv_xxcso1_owner_company   CONSTANT VARCHAR2(30)  := 'XXCSO1_OWNER_COMPANY';
-- Ver.1.3 Add Start
  cv_cp_withdraw_base_code  CONSTANT VARCHAR2(30)  := 'XXCSO1_COMP_WITHDRAW_BASE_CODE';  -- ��Еʈ��g���_�R�[�h
-- Ver.1.3 Add End
  --�l�Z�b�g
  cv_xxcff_owner_company    CONSTANT VARCHAR2(30)  := 'XXCFF_OWNER_COMPANY';       --�{��/�H��敪
  cv_xxcff_mng_place        CONSTANT VARCHAR2(30)  := 'XXCFF_MNG_PLACE';           --���Ə�
  cv_xxcff_dclr_place       CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';          --�\���n
  -- �C���X�^���X�}�X�^�F�X�e�[�^�X
  cv_delete_code            CONSTANT VARCHAR2(1)   := '6';              -- �����폜�σR�[�h
  -- �����R�[�h
  cv_lease_kbn              CONSTANT VARCHAR2(9)   := 'LEASE_KBN';      -- ���[�X�敪
  cv_disposed_flag          CONSTANT VARCHAR2(13)  := 'VEN_HAIKI_FLG';  -- �p�����كt���O
  cv_dclr_place             CONSTANT VARCHAR2(10)  := 'DCLR_PLACE';     -- �\���n
  cv_assets_cost            CONSTANT VARCHAR2(13)  := 'VD_SHUTOKU_KG';  -- �擾���i
  cv_disposed_date          CONSTANT VARCHAR2(14)  := 'HAIKIKESSAI_DT'; -- �p�����ϓ�
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD START */
  cv_fa_move_date           CONSTANT VARCHAR2(12)  := 'FA_MOVE_DATE';   -- �Œ莑�Y�ړ���
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD END */
  -- �����l
  cv_lease_type_assets      CONSTANT VARCHAR2(1)   := '4';              -- ���[�X�敪(�Œ莑�Y��)
  cv_disposed_approve       CONSTANT VARCHAR2(1)   := '9';              -- �p�����كt���O(�p�����ٍ�)
  -- �ڋq�֘A
  cv_cust_class_10          CONSTANT VARCHAR2(2)   := '10';             -- �ڋq�敪(�ڋq)
  -- ��Ɗ֘A
  cv_job_kbn_set            CONSTANT VARCHAR2(1)   := '1';              -- ��Ƌ敪(�V��ݒu)
  cv_job_kbn_change         CONSTANT VARCHAR2(1)   := '3';              -- ��Ƌ敪(�V����)
  cv_comp_kbn_complete      CONSTANT VARCHAR2(1)   := '1';              -- �����敪(����)
  -- �{��/�H��敪
  cv_owner_company_h_office CONSTANT VARCHAR2(1)   := '1';              -- �{��
  cv_owner_company_fact     CONSTANT VARCHAR2(1)   := '2';              -- �H��
  -- �Ώە����f�[�^�^�C�v
  cv_create                 CONSTANT VARCHAR2(1)   := '1';              -- �V�K
  cv_update                 CONSTANT VARCHAR2(1)   := '2';              -- �X�V
  cv_disposed               CONSTANT VARCHAR2(1)   := '3';              -- �p��
  cv_any_time               CONSTANT VARCHAR2(1)   := '4';              -- ����
  -- ���t�`��
  cv_yyyymmdd               CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_yyyymmddhhmmdd_sla     CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_yyyymmdd_sla           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_mm                     CONSTANT VARCHAR2(2)   := 'MM';
  -- ���̑��ėp
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';  --�ėpY
  cv_no                     CONSTANT VARCHAR2(1)   := 'N';  --�ėpN
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';  --�ėp�X�y�[�X
  cv_0                      CONSTANT VARCHAR2(1)   := '0';  --�ėp0(CHAR)
  cv_1                      CONSTANT VARCHAR2(1)   := '1';  --�ėp1(CHAR)
  cn_0                      CONSTANT NUMBER        := 0;    --�ėp0(NUMBRE)
  cn_1                      CONSTANT NUMBER        := 1;    --�ėp1(NUMBRE)
  cn_2                      CONSTANT NUMBER        := 2;    --�ėp2(NUMBRE)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- INV �H��ԕi�q�֐�R�[�h�擾�p�z���`
  TYPE gt_mfg_fctory_code_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY BINARY_INTEGER;
  -- �V���`�F�b�N�p���R�[�h�^��`
  TYPE g_check_rtype IS RECORD(
     install_code            xxcso_ib_info_h.install_code%TYPE             -- �����ԍ�
    ,manufacturer_name       xxcso_ib_info_h.manufacturer_name%TYPE        -- ���[�J�[��
    ,age_type                xxcso_ib_info_h.age_type%TYPE                 -- �N��
    ,un_number               xxcso_ib_info_h.un_number%TYPE                -- �@��
    ,install_number          xxcso_ib_info_h.install_number%TYPE           -- �@��
    ,quantity                xxcso_ib_info_h.quantity%TYPE                 -- ����
    ,base_code               xxcso_ib_info_h.base_code%TYPE                -- ���_�R�[�h
    ,owner_company_type      xxcso_ib_info_h.owner_company_type%TYPE       -- �{�Ё^�H��敪
    ,install_name            xxcso_ib_info_h.install_name%TYPE             -- �ݒu�於
    ,install_address         xxcso_ib_info_h.install_address%TYPE          -- �ݒu��Z��
    ,logical_delete_flag     xxcso_ib_info_h.logical_delete_flag%TYPE      -- �_���폜�t���O
    ,account_number          xxcso_ib_info_h.account_number%TYPE           -- �ڋq�R�[�h
    ,declaration_place       xxcso_ib_info_h.declaration_place%TYPE        -- �\���n
    ,disposal_intaface_flag  xxcso_ib_info_h.disposal_intaface_flag%TYPE   -- �p�����كt���O
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD START */
    ,fa_move_date            DATE                                          -- �Œ莑�Y�ړ���
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD END */
  );
  -- INV �H��ԕi�q�֐�R�[�h�擾�p�z��ϐ�
  g_mfg_fctory_cd      gt_mfg_fctory_code_ttype;
  -- �V���f�[�^��r(���������e�[�u���X�V)�p���R�[�h�^
  g_new_data_rec       g_check_rtype;
  -- �C���^�[�t�F�[�X�o�^�f�[�^�i�[�p���R�[�h�^
  g_if_rec             xxcff_vd_object_mng_if%ROWTYPE;
-- Ver.1.3 Add Start
  -- ��Еʈ��g���_�R�[�h�擾�p�z���`
  TYPE gt_comp_withdraw_base_cd_ttype IS TABLE OF fnd_lookup_values_vl.attribute1%TYPE INDEX BY BINARY_INTEGER;
  -- ��Еʈ��g���_�R�[�h�擾�p�z��ϐ�
  g_comp_withdraw_base_code  gt_comp_withdraw_base_cd_ttype;
-- Ver.1.3 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �p�����[�^�i�[�p
  gv_prm_process_date         VARCHAR2(8);  -- �������s��
  -- �����֘A�f�[�^�擾�p
  gd_business_date            DATE;         -- �Ɩ��������t
  gd_process_date             DATE;         -- ������
  -- �v���t�@�C���l
  gv_customer_code_dammy      hz_cust_accounts_all.account_number%TYPE;      -- XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j
  gn_org_id                   NUMBER;                                        -- MO:�c�ƒP��
  gt_attribute_level          csi_i_extended_attribs.attribute_level%TYPE;   -- XXCSO:IB�g�������e���v���[�g�A�N�Z�X���x��
-- Ver.1.3 Del Start
--  gt_withdraw_base_code       csi_i_extended_attribs.attribute_level%TYPE;   -- XXCSO:���g���_�R�[�h
-- Ver.1.3 Del End
  -- ���̑�
  gn_instance_status_id       csi_instance_statuses.instance_status_id%TYPE; --�����X�e�[�^�XID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  --�Ώە����擾�J�[�\��
  CURSOR get_target_cur
  IS
    -- �V�K����(��ԏ���)
    SELECT  /*+
              LEADING(xiih)
              INDEX(xiih xxcso_ib_info_h_n02)
              USE_NL(xiih cii)
            */
            cv_create        data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date    IS NULL  --��ԏ���
    AND     xiih.interface_flag    = cv_no  --���A�g
    AND     cii.external_reference = xiih.install_code
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                               --���[�X�敪:4(�Œ莑�Y)
    AND     NOT EXISTS ( 
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_disposed_flag
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_disposed_approve
              AND     ROWNUM                  = 1
          )                                 --�p���t���O:9(�p�����ٍ�)�ȊO
    UNION ALL
    --�X�V����(��ԏ���)
    SELECT  cv_update        data_type
           ,cii.instance_id  instance_id
    FROM    csi_item_instances   cii
    WHERE   gv_prm_process_date  IS NULL    --��ԏ���
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                               --���[�X�敪:4(�Œ莑�Y)
    AND     NOT EXISTS ( 
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_disposed_flag
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_disposed_approve
              AND     ROWNUM                  = 1
            )                                 --�p���t���O:9(�p�����ٍ�)�ȊO
    AND     EXISTS (
              SELECT  /*+
                        USE_NL(xiih hca hp xca hcas hps hl)
                      */
                      1
              FROM    xxcso_ib_info_h         xiih  -- �����֘A���ύX�����e�[�u��
                     ,hz_cust_accounts_all    hca   -- �ڋq�}�X�^
                     ,hz_parties              hp    -- �p�[�e�B�}�X�^
                     ,xxcmm_cust_accounts     xca   -- �ڋq�A�h�I���}�X�^
                     ,hz_cust_acct_sites_all  hcas  -- �ڋq���ݒn�}�X�^�r���[
                     ,hz_party_sites          hps   -- �p�[�e�B�T�C�g�}�X�^
                     ,hz_locations            hl    -- �ڋq���Ə��}�X�^
              WHERE   xiih.install_code                  = cii.external_reference
              AND     xiih.interface_flag                = cv_yes                    -- �A�g��
              AND     hca.cust_account_id                = cii.owner_party_account_id
              AND     hp.party_id                        = hca.party_id
              AND     xca.customer_id                    = hca.cust_account_id
              AND     hcas.cust_account_id               = hca.cust_account_id
              AND     hcas.org_id                        = gn_org_id
              AND     hps.party_id                       = hp.party_id
              AND     hps.party_site_id                  = hcas.party_site_id
              AND     hl.location_id                     = hps.location_id
              AND     (
                            (
                              (
                                (hca.customer_class_code <> cv_cust_class_10)
                                AND
                                (gv_customer_code_dammy  <> NVL(xiih.account_number, cv_space))
                              )
                              OR
                              (
                                (hca.customer_class_code =  cv_cust_class_10)
                                AND
                                (hca.account_number      <> NVL(xiih.account_number, cv_space))
                              )
                            )                                                                         -- �ڋq�R�[�h�`�F�b�N
                        OR  NVL(xca.sale_base_code, cv_space)  <> NVL(xiih.base_code, cv_space)       -- ���㋒�_�`�F�b�N
                        OR  NVL(hp.party_name, cv_space)       <> NVL(xiih.install_name, cv_space)    -- �ݒu�於�`�F�b�N
                        OR  NVL(hl.state || hl.city || hl.address1 || hl.address2, cv_space)
                                                               <> NVL(xiih.install_address, cv_space) -- �Z���`�F�b�N
                        OR  NVL(cii.attribute1, cv_space)      <> NVL(xiih.un_number, cv_space)       -- �@��`�F�b�N
                        OR  NVL(cii.attribute2, cv_space)      <> NVL(xiih.install_number, cv_space)  -- �@�ԃ`�F�b�N
                        OR  NVL(xiih.quantity, cn_0)           <> NVL(cii.quantity, cn_0)             -- ���ʃ`�F�b�N
                        OR  NVL(xiih.manufacturer_name, cv_space)   <>
                              (
                               SELECT  NVL(
                                         xxcso_util_common_pkg.get_lookup_meaning(
                                           cv_xxcso_csi_maker_code
                                          ,punv.attribute2
                                          ,gd_process_date
                                         )
                                        ,cv_space
                                       )
                               FROM    po_un_numbers_vl   punv
                               WHERE   punv.un_number  =  cii.attribute1
                              )                                                                      -- ���[�J���`�F�b�N
                        OR  NVL(xiih.age_type, cv_space)            <>
                              (
                               SELECT  NVL(punv.attribute3, cv_space)
                               FROM    po_un_numbers_vl   punv
                               WHERE   punv.un_number  =  cii.attribute1
                              )                                                                      -- �N���`�F�b�N
                        OR  NVL(xiih.logical_delete_flag, cv_space) <>
                              DECODE(cii.instance_status_id
                                ,gn_instance_status_id, cv_yes
                                ,cv_no
                              )                                                                      -- �_���폜�`�F�b�N
                        OR  NVL(xiih.owner_company_type, cv_space)  <>
                              (
                                SELECT  flvv.meaning
                                FROM    fnd_lookup_values_vl  flvv
                                WHERE   flvv.lookup_type   = cv_xxcso1_owner_company
                                AND     flvv.enabled_flag  = cv_yes
                                AND     gd_process_date
                                          BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                          AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date))
                                AND     flvv.lookup_code   =
                                          (
                                           SELECT  DECODE(COUNT('x')
                                                     ,cn_0, cv_owner_company_h_office
                                                     ,cv_owner_company_fact
                                                   )
                                           FROM    xxcmm_cust_accounts   xca
                                                  ,fnd_lookup_values_vl  flvv
                                           WHERE   xca.customer_id   = cii.owner_party_account_id
                                           AND     flvv.lookup_type  = cv_xxcoi_mfg_fctory_cd
                                           AND     flvv.lookup_code  = xca.sale_base_code
                                           AND     flvv.enabled_flag = cv_yes
                                           AND     gd_process_date
                                                     BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                                     AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date))
                                          )
                              )                                                                      -- �{��/�H��敪�`�F�b�N
                        OR  NVL(xiih.declaration_place, cv_space)  <> 
                              (
                                SELECT  civ.attribute_value
                                FROM    csi_i_extended_attribs  ciea
                                       ,csi_iea_values          civ
                                WHERE   ciea.attribute_level    = gt_attribute_level
                                AND     ciea.attribute_code     = cv_dclr_place
                                AND     civ.instance_id         = cii.instance_id
                                AND     ciea.attribute_id       = civ.attribute_id
                                AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                                AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
                              )                                                                      -- �\���n�`�F�b�N
                      )
                AND   ROWNUM                             = 1
            )
    UNION ALL
    --�p������(��ԏ���)
    SELECT  /*+
              LEADING(xiih)
              INDEX(xiih xxcso_ib_info_h_n02)
              USE_NL(cii cis)
            */
            cv_disposed      data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date IS NULL
    AND     xiih.interface_flag         = cv_yes  --���A��
    AND     xiih.disposal_intaface_flag = cv_no   --�p�����A�g
    AND     cii.external_reference      = xiih.install_code
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = cv_lease_kbn
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = cv_lease_type_assets
              AND     ROWNUM                  = 1
            )                                     --���[�X�敪:4(�Œ莑�Y)
    AND     EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
              AND     ciea.attribute_code     = 'VEN_HAIKI_FLG'
              AND     civ.instance_id         = cii.instance_id
              AND     ciea.attribute_id       = civ.attribute_id
              AND     NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
              AND     NVL(ciea.active_end_date  ,gd_process_date) >= gd_process_date
              AND     civ.attribute_value     = '9'
              AND     ROWNUM                  = 1
          )                                       --�p���t���O:9(�p�����ٍ�)
    UNION ALL
    --�ĘA�g(�������s)
    SELECT  /*+
              LEADING(xiih)
              USE_NL(xiih cii)
            */
            cv_any_time      data_type
           ,cii.instance_id  instance_id
    FROM    xxcso_ib_info_h        xiih
           ,csi_item_instances     cii
    WHERE   gv_prm_process_date               IS NOT NULL
      AND   TRUNC(xiih.history_creation_date) = TRUNC(gd_process_date)  -- �����쐬�����p�����[�^�u�������s���v
      AND   xiih.interface_flag               = cv_yes                  -- FA�A�g�ς�
      AND   cii.external_reference            = xiih.install_code
      AND   EXISTS (
              SELECT  1
              FROM    csi_i_extended_attribs  ciea
                     ,csi_iea_values          civ
              WHERE   ciea.attribute_level    = gt_attribute_level
                AND   ciea.attribute_code     = cv_lease_kbn
                AND   civ.instance_id         = cii.instance_id
                AND   ciea.attribute_id       = civ.attribute_id
                AND   NVL(ciea.active_start_date,gd_process_date) <= gd_process_date
                AND   NVL(ciea.active_end_date,gd_process_date)   >= gd_process_date
                AND   civ.attribute_value     = cv_lease_type_assets    -- ���[�X�敪:4(�Œ莑�Y)
                AND   ROWNUM                  = 1
            )
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_process_date   IN  VARCHAR2      -- 1.�������s��
    ,ov_errbuf         OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode        OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_msg_tkn_1  VARCHAR2(100);  --���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2  VARCHAR2(100);  --���b�Z�[�W�g�[�N���擾�p2
    lv_warn_msg   VARCHAR2(5000); --�x���o�͗p
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
    -- ===========================
    -- �p�����[�^�o��
    -- ===========================
    -- �����Ώۓ��t
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_param_date
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => iv_process_date
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �󔒍s�}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===========================
    -- �Ɩ��������t�擾
    -- ===========================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --�擾�G���[�`�F�b�N
    IF (gd_business_date IS NULL) THEN
      -- �Ɩ��������t�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_proc_date_err         --���b�Z�[�W�R�[�h
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- ����������
    -- ===========================
    gv_prm_process_date := iv_process_date;
    -- �p�����[�^�������s�������͂���Ă���ꍇ
    IF (gv_prm_process_date IS NOT NULL) THEN
      -- ���������p�����[�^�����Ώۓ�
      gd_process_date := TO_DATE(gv_prm_process_date, cv_yyyymmdd);
    ELSE
      -- ���������Ɩ����t
      gd_process_date := gd_business_date;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���E�I�v�V�����l�擾
    -- ===============================
    --XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j
    gv_customer_code_dammy := fnd_profile.value( cv_prf_cust_cd_dammy );
    -- �擾�G���[�`�F�b�N
    IF ( gv_customer_code_dammy IS NULL ) THEN
      -- AFF�ڋq�R�[�h�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_prof_err      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_prf_cust_cd_dammy
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- �c�ƒP�ʎ擾
    gn_org_id := fnd_profile.value( cv_prof_org_id );
    -- �擾�G���[�`�F�b�N
    IF ( gn_org_id IS NULL ) THEN
      -- �c�ƒP�ʎ擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_prof_err      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_prof_org_id
                   );
      RAISE global_api_expt;
    END IF;
    --
    -- IB�������x���擾
    gt_attribute_level := fnd_profile.value( cv_attribute_level );
    -- �擾�G���[�`�F�b�N
    IF ( gt_attribute_level IS NULL ) THEN
      --IB�������x���擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_prof_err      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name
                    ,iv_token_value1 => cv_attribute_level
                   );
      RAISE global_api_expt;
    END IF;
    --
-- Ver.1.3 Del Start
--    -- ���g���_�R�[�h�擾
--    gt_withdraw_base_code := fnd_profile.value( cv_withdraw_base_code );
--    -- �擾�G���[�`�F�b�N
--    IF ( gt_withdraw_base_code IS NULL ) THEN
--      --���g���_�R�[�h�擾�Ɏ��s�����ꍇ�i�߂�lNULL�j
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
--                    ,iv_name         => cv_msg_prof_err      --���b�Z�[�W�R�[�h
--                    ,iv_token_name1  => cv_tkn_prof_name
--                    ,iv_token_value1 => cv_withdraw_base_code
--                   );
--      RAISE global_api_expt;
--    END IF;
-- Ver.1.3 Del End
--
    -- =============================
    -- �C���X�^���X�X�e�[�^�XID�擾
    -- =============================
    --
    BEGIN
      -- �����폜��
      SELECT cis.instance_status_id instance_status_id
      INTO   gn_instance_status_id
      FROM   csi_instance_statuses cis
      WHERE  cis.name IN
               (
                  SELECT flvv.description description
                  FROM   fnd_lookup_values_vl flvv
                  WHERE  gd_process_date BETWEEN TRUNC( NVL(flvv.start_date_active, gd_process_date) )
                                         AND     TRUNC( NVL(flvv.end_date_active,   gd_process_date) )
                  AND    flvv.enabled_flag = cv_yes
                  AND    flvv.lookup_code  = cv_delete_code
                  AND    flvv.lookup_type  = cv_xxcso1_instance_status
               )
      AND    gd_process_date BETWEEN TRUNC( NVL(cis.start_date_active, gd_process_date) )
                             AND     TRUNC( NVL(cis.end_date_active,   gd_process_date) )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_status_id   --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_status_nm   --���b�Z�[�W�R�[�h
                         );
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_status_id_err   --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_status_name
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        RAISE global_api_expt;
    END;
--
    -- =============================
    -- INV �H��ԕi�q�֐�R�[�h�擾
    -- =============================
    BEGIN
      --�S���擾
      SELECT flvv.lookup_code lookup_code
      BULK COLLECT INTO
             g_mfg_fctory_cd
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_xxcoi_mfg_fctory_cd
      AND    gd_process_date  BETWEEN TRUNC( NVL(flvv.start_date_active, gd_process_date) )
                              AND     TRUNC( NVL(flvv.end_date_active,   gd_process_date) )
      AND    flvv.enabled_flag = cv_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_lookup_type  --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_lookup_code1 --���b�Z�[�W�R�[�h
                         );
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_lookup_err       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_lookup_type_name
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        RAISE global_api_expt;
    END;
    --
    -- INV �H��ԕi�q�֐�R�[�h��0���̏ꍇ
    IF ( g_mfg_fctory_cd.COUNT = 0 ) THEN
      lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_lookup_type  --���b�Z�[�W�R�[�h
                       );
      lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_lookup_code1 --���b�Z�[�W�R�[�h
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name               --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_lookup_no_err      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_task_name
                    ,iv_token_value1 => lv_msg_tkn_1
                    ,iv_token_name2  => cv_tkn_lookup_type_name
                    ,iv_token_value2 => lv_msg_tkn_2
                   );
      RAISE global_api_expt;
    END IF;
--
-- Ver.1.3 Add Start
    -- =========================
    -- ��Еʈ��g���_�R�[�h�擾
    -- =========================
    BEGIN
      --�S���擾
      SELECT flvv.attribute1  AS  comp_withdraw_base_code  -- ��Еʈ��g���_�R�[�h
      BULK COLLECT INTO
             g_comp_withdraw_base_code
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_cp_withdraw_base_code
      AND    gd_process_date  BETWEEN TRUNC( NVL(flvv.start_date_active, gd_process_date) )
                              AND     TRUNC( NVL(flvv.end_date_active,   gd_process_date) )
      AND    flvv.enabled_flag = cv_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_lookup_type  --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_cp_withdraw_base_code --�Q�ƃ^�C�v
                         );
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_lookup_err       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_lookup_type_name
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_err_msg
                      ,iv_token_value3 => SQLERRM
                     );
        RAISE global_api_expt;
    END;
    --
    -- ��Еʈ��g���_�R�[�h��0���̏ꍇ
    IF ( g_comp_withdraw_base_code.COUNT = 0 ) THEN
      lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_lookup_type  --���b�Z�[�W�R�[�h
                       );
      lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_cp_withdraw_base_code --�Q�ƃ^�C�v
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name               --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_lookup_no_err      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_task_name
                    ,iv_token_value1 => lv_msg_tkn_1
                    ,iv_token_name2  => cv_tkn_lookup_type_name
                    ,iv_token_value2 => lv_msg_tkn_2
                   );
      RAISE global_api_expt;
    END IF;
-- Ver.1.3 Add End
  EXCEPTION
    -- *** �����G���[��O ***
    WHEN global_api_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
   * Procedure Name   : ins_xxcff_if
   * Description      : ���̋@�����Ǘ��C���^�t�F�[�X�o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_xxcff_if(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcff_if'; -- �v���O������
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
    lv_msg_tkn_1  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p2
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
    BEGIN
      -- ���̋@�����Ǘ��C���^�t�F�[�X�f�[�^�}������
      INSERT INTO xxcff_vd_object_mng_if(
         object_code                  -- �����R�[�h
        ,generation_date              -- ������
        ,manufacturer_name            -- ���[�J��
        ,age_type                     -- �N��
        ,model                        -- �@��
        ,quantity                     -- ����
        ,department_code              -- �Ǘ�����
        ,owner_company_type           -- �{�Ё^�H��敪
        ,installation_place           -- ���ݒu��
        ,installation_address         -- ���ݒu�ꏊ
        ,active_flag                  -- �����L���t���O
        ,import_status                -- �捞�X�e�[�^�X
        ,group_id                     -- �O���[�vID
        ,customer_code                -- �ڋq�R�[�h
        ,machine_type                 -- �@��敪
        ,lease_class                  -- ���[�X���
        ,date_placed_in_service       -- ���Ƌ��p��
        ,assets_cost                  -- �擾���i
        ,moved_date                   -- �ړ���
        ,dclr_place                   -- �\���n
        ,location                     -- ���Ə�
        ,date_retired                 -- ���E���p��
        ,created_by                   -- �쐬��
        ,creation_date                -- �쐬��
        ,last_updated_by              -- �ŏI�X�V��
        ,last_update_date             -- �ŏI�X�V��
        ,last_update_login            -- �ŏI�X�V���O�C��
        ,request_id                   -- �v��ID
        ,program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                   -- �R���J�����g�E�v���O����ID
        ,program_update_date          -- �v���O�����X�V��
      )VALUES(
         g_if_rec.object_code               -- �����R�[�h
        ,g_if_rec.generation_date           -- ������
        ,g_if_rec.manufacturer_name         -- ���[�J��
        ,g_if_rec.age_type                  -- �N��
        ,g_if_rec.model                     -- �@��
        ,g_if_rec.quantity                  -- ����
        ,g_if_rec.department_code           -- �Ǘ�����
        ,g_if_rec.owner_company_type        -- �{�Ё^�H��敪
        ,g_if_rec.installation_place        -- ���ݒu��
        ,g_if_rec.installation_address      -- ���ݒu�ꏊ
        ,g_if_rec.active_flag               -- �����L���t���O
        ,g_if_rec.import_status             -- �捞�X�e�[�^�X
        ,g_if_rec.group_id                  -- �O���[�vID
        ,g_if_rec.customer_code             -- �ڋq�R�[�h
        ,g_if_rec.machine_type              -- �@��敪
        ,g_if_rec.lease_class               -- ���[�X���
        ,g_if_rec.date_placed_in_service    -- ���Ƌ��p��
        ,g_if_rec.assets_cost               -- �擾���i
        ,g_if_rec.moved_date                -- �ړ���
        ,g_if_rec.dclr_place                -- �\���n
        ,g_if_rec.location                  -- ���Ə�
        ,g_if_rec.date_retired              -- ���E���p��
        ,cn_created_by                      -- �쐬��
        ,cd_creation_date                   -- �쐬��
        ,cn_last_updated_by                 -- �ŏI�X�V��
        ,cd_last_update_date                -- �ŏI�X�V��
        ,cn_last_update_login               -- �ŏI�X�V���O�C��
        ,cn_request_id                      -- �v��ID
        ,cn_program_application_id          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                      -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date             -- �v���O�����X�V��
       );
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_if_name     --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name        --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_create      --���b�Z�[�W�R�[�h
                         );
        --���b�Z�[�W�ݒ�
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_data_dml_err    --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_xxcff_if;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcso_ib_info_h
   * Description      : �����֘A���ύX�����e�[�u���X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE upd_xxcso_ib_info_h(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'upd_xxcso_ib_info_h';     -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    lv_msg_tkn_1  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p2
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
--
    -- ========================================
    -- �����֘A���ύX�����e�[�u���X�V����
    -- ========================================
    BEGIN
      --
      UPDATE xxcso_ib_info_h xiih
      SET    xiih.history_creation_date   = gd_process_date                        -- �����쐬��
            ,xiih.interface_flag          = cv_yes                                 -- �A�g�σt���O
            ,xiih.manufacturer_name       = g_new_data_rec.manufacturer_name       -- ���[�J�[��
            ,xiih.age_type                = g_new_data_rec.age_type                -- �N��
            ,xiih.un_number               = g_new_data_rec.un_number               -- �@��
            ,xiih.install_number          = g_new_data_rec.install_number          -- �@��
            ,xiih.quantity                = g_new_data_rec.quantity                -- ����
            ,xiih.base_code               = g_new_data_rec.base_code               -- ���_�R�[�h
            ,xiih.owner_company_type      = g_new_data_rec.owner_company_type      -- �{�Ё^�H��敪
            ,xiih.install_name            = g_new_data_rec.install_name            -- �ݒu�於
            ,xiih.install_address         = g_new_data_rec.install_address         -- �ݒu��Z��
            ,xiih.logical_delete_flag     = g_new_data_rec.logical_delete_flag     -- �_���폜�t���O
            ,xiih.account_number          = g_new_data_rec.account_number          -- �ڋq�R�[�h
            ,xiih.declaration_place       = g_new_data_rec.declaration_place       -- �\���n
            ,xiih.disposal_intaface_flag  = g_new_data_rec.disposal_intaface_flag  -- �p�����كt���O
            ,xiih.last_updated_by         = cn_last_updated_by                     -- �ŏI�X�V��
            ,xiih.last_update_date        = cd_last_update_date                    -- �ŏI�X�V��
            ,xiih.last_update_login       = cn_last_update_login                   -- �ŏI�X�V���O�C��
            ,xiih.request_id              = cn_request_id                          -- �v��ID
            ,xiih.program_application_id  = cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xiih.program_id              = cn_program_id                          -- �R���J�����g�E�v���O����ID
            ,xiih.program_update_date     = cd_program_update_date                 -- �v���O�����X�V��
      WHERE  xiih.install_code   = g_new_data_rec.install_code
      ;
    EXCEPTION
      --���̑���O
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_ib_info       --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_update        --���b�Z�[�W�R�[�h
                         );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_data_dml_err      --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_process
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_bukken
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END upd_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : lock_xxcso_ib_info_h
   * Description      : �����֘A�ύX�����e�[�u�����b�N(A-6)
   ***********************************************************************************/
  PROCEDURE lock_xxcso_ib_info_h(
     ov_errbuf           OUT VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'lock_xxcso_ib_info_h';     -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    cv_dummy      VARCHAR2(1);     -- ���b�N�_�~�[�p
    lv_put_msg    VARCHAR2(5000);  -- �o�̓��b�Z�[�W�p
    lv_msg_tkn_1  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p2
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
--
    -- ========================================
    -- �����֘A�ύX�����e�[�u�����b�N����
    -- ========================================
    BEGIN
      --
      SELECT cv_1 lock_dummy
      INTO   cv_dummy
      FROM   xxcso_ib_info_h xiih -- �����֘A���ύX�����e�[�u��
      WHERE  xiih.install_code = g_if_rec.object_code -- �����R�[�h
      FOR UPDATE OF
             xiih.install_code
      NOWAIT
      ;
    EXCEPTION
      -- ���b�N��O
      WHEN global_lock_expt THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_ib_info        --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_lock           --���b�Z�[�W�R�[�h
                         );
        -- ���b�Z�[�W�ҏW
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_data_dml_err             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_process
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_bukken
                       ,iv_token_value3 => g_if_rec.object_code
                       ,iv_token_name4  => cv_tkn_err_msg
                       ,iv_token_value4 => SQLERRM
                      );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- �o�̓��b�Z�[�W
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ���O���b�Z�[�W
          );
        ov_retcode := cv_status_warn;
      -- ���̑��̗�O
      WHEN OTHERS THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_ib_info        --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_instance_code  --���b�Z�[�W�R�[�h
                         );
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_get_data1_err             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END lock_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : chk_xxcff_if_exists
   * Description      : ���̋@�����Ǘ��C���^�t�F�[�X���݃`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE chk_xxcff_if_exists(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcff_if_exists'; -- �v���O������
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
    ln_data_cnt   NUMBER;          -- ���݃`�F�b�N�p
    lv_msg_tkn_1  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2  VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���擾�p2
    lv_put_msg    VARCHAR2(5000);  -- �o�̓��b�Z�[�W�p
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ========================================
    -- ���̋@�����Ǘ��C���^�t�F�[�X���ݔ���
    -- ========================================
    BEGIN
      --
      SELECT COUNT(xvomi.object_code)
      INTO   ln_data_cnt
      FROM   xxcff_vd_object_mng_if xvomi -- ���̋@�����Ǘ��C���^�t�F�[�X
      WHERE  xvomi.object_code = g_if_rec.object_code -- �����R�[�h
      ;
    EXCEPTION
      -- ���̑���O
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_if_name        --���b�Z�[�W�R�[�h
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_instance_code  --���b�Z�[�W�R�[�h
                         );
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_get_data1_err         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => g_if_rec.object_code
                      ,iv_token_name4  => cv_tkn_err_msg
                      ,iv_token_value4 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- IF�Ƀf�[�^���c���Ă���ꍇ
    IF ( ln_data_cnt > 0 ) THEN
      --���b�Z�[�W�ҏW
      lv_put_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_if_exists_err    --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_bukken
                     ,iv_token_value1 => g_if_rec.object_code
                    );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_put_msg       -- �o�̓��b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_put_msg       -- ���O���b�Z�[�W
        );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END chk_xxcff_if_exists;
--
  /**********************************************************************************
   * Procedure Name   : chk_xxcso_ib_info_h
   * Description      : �����֘A���ύX�`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE chk_xxcso_ib_info_h(
     iv_new_data   IN  g_check_rtype  -- 1.�V�f�[�^
    ,iv_old_data   IN  g_check_rtype  -- 2.���f�[�^
    ,on_change_ptn OUT NUMBER         -- 3.�ύX�p�^�[��(1:�C�� 2:�ړ�)
    ,od_move_date  OUT DATE           -- 4.�ړ���
    ,ov_errbuf     OUT VARCHAR2       --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2       --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcso_ib_info_h'; -- �v���O������
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
    ld_move_date   DATE;           -- ����Ɠ��擾�p
    lv_msg_tkn_1   VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2   VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���擾�p2
    lv_msg_tkn_4   VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���擾�p4
-- Ver.1.3 Add Start
    lv_chk_base_new_flag   VARCHAR2(1); -- �V�f�[�^���_�R�[�h�`�F�b�N�t���O
    lv_chk_base_old_flag   VARCHAR2(1); -- ���f�[�^���_�R�[�h�`�F�b�N�t���O
-- Ver.1.3 Add End
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
/* 2016.02.09 H.Okada E_�{�ғ�_13456 DEL START */
--    -- ����Ɠ��擾�J�[�\��
--    CURSOR get_act_date
--    IS
--      SELECT TO_DATE( MAX( xiwd.actual_work_date ), cv_yyyymmdd )  actual_work_date
--      FROM   xxcso_in_work_data xiwd
--      WHERE  xiwd.completion_kbn   =  cn_1       -- ����
--      AND    (
--               ( xiwd.po_req_number    IS NOT NULL )
--               AND
--               ( xiwd.po_req_number <> cv_0 )
--             )                                   -- EBS��蔭���������(�X���ړ��ȊO)
--      AND    (
--                (
--                  ( xiwd.install_code1           = iv_new_data.install_code )  -- �ݒu�p����
--                  AND
--                  ( xiwd.install1_processed_flag = cv_yes )  -- �������f��
--                )
--                OR
--                (
--                  ( xiwd.install_code2           = iv_new_data.install_code )  -- ���g�p����
--                  AND
--                  ( xiwd.install2_processed_flag = cv_yes )  -- �������f��
--                )
--             )
--      ;
/* 2016.02.09 H.Okada E_�{�ғ�_13456 DEL END */
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
--
    -- ������
    on_change_ptn := cn_1;  -- �ύX�`�F�b�N�t���O�Ƀf�t�H���g�l1(�C��)��ݒ�
    ld_move_date  := NULL;  -- �ړ���
-- Ver.1.3 Add Start
    lv_chk_base_new_flag := cv_no;
    lv_chk_base_old_flag := cv_no;
-- Ver.1.3 Add End
    --
    --------------------------
    -- �ړ��ƂȂ�ύX�`�F�b�N
    --------------------------
    -- ���_�R�[�h(���Ə��E�{��/�H��敪)�̕ύX
    IF NVL( iv_old_data.base_code, cv_space ) <> NVL( iv_new_data.base_code, cv_space ) THEN
      --
      on_change_ptn := cn_2; -- 2(�ړ�)�Ƃ���
      --
      -------------------------------------
      -- ��Ƃɂ�锻��
      -------------------------------------
      -- ����ݒu�����g�̏ꍇ
-- Ver.1.3 Mod Start
--      IF ( iv_new_data.base_code = gt_withdraw_base_code )  -- �V���_�����g���_=���g
--         OR
--         ( iv_old_data.base_code = gt_withdraw_base_code )  -- �����_�����g���_=����ݒu
--      THEN
      <<loop_comp_withdraw_base_cd_chk>>
      FOR i IN 1..g_comp_withdraw_base_code.LAST LOOP
        -- �V�f�[�^�̋��_�R�[�h����Еʈ��g���_�R�[�h�Ɠ����i���g�j
        IF (iv_new_data.base_code = g_comp_withdraw_base_code(i)) THEN
          lv_chk_base_new_flag := cv_yes;
        -- ���f�[�^�̋��_�R�[�h����Еʈ��g���_�R�[�h�Ɠ����i����ݒu�j
        ELSIF (iv_old_data.base_code = g_comp_withdraw_base_code(i)) THEN
          lv_chk_base_old_flag := cv_yes;
        END IF;
      END LOOP loop_comp_withdraw_base_cd_chk;
      --
      IF ( lv_chk_base_new_flag = cv_yes OR lv_chk_base_old_flag = cv_yes ) THEN
-- Ver.1.3 Mod End
/* 2016.02.09 H.Okada E_�{�ғ�_13456 MOD START */
--        -- EBS���A�g���ꂽ��Ƃ̍ŐV������Ɠ����擾
--        OPEN  get_act_date;
--        FETCH get_act_date INTO ld_move_date;
--        CLOSE get_act_date;
        -- �����}�X�^�̌Œ莑�Y�ړ�����ݒ�i��Ƃɂ��ړ��j
        ld_move_date := iv_new_data.fa_move_date;
/* 2016.02.09 H.Okada E_�{�ғ�_13456 MOD END */
      -- ����ȊO�i��ʋ��_�����ʋ��_�ւ̕ύX�j
      ELSE
        -------------------------------------
        -- �ڋq�ڍs�E���_�����ɂ�锻��
        -------------------------------------
        BEGIN
          --
          SELECT xcsi.cust_shift_date cust_shift_date  --�ڋq�ڍs��
          INTO   ld_move_date
          FROM   xxcok_cust_shift_info xcsi  -- �ڋq�ڍs���e�[�u��
          WHERE  xcsi.cust_code        = iv_new_data.account_number     -- �Ώیڋq
          AND    xcsi.cust_shift_date  = gd_process_date + 1            -- �Ɩ����t�̗������ڍs���ƂȂ��Ă���
          AND    xcsi.base_split_flag  = cv_1                           -- �\�񔄏㋒�_�R�[�h���f��
          AND    xcsi.new_base_code    = iv_new_data.base_code          -- ���㋒�_�������ɕR�t���ڋq�̔��㋒�_�Ɠ���
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            -- �g�[�N���擾
            lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_cust_shift_err   -- �ڋq�ڍs���e�[�u��(�Œ�)
                             );
            lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_instance_code    -- �����R�[�h(�Œ�)
                             );
            lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_msg_cust_code        -- �ڋq�R�[�h(�Œ�)
                             );
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_get_data1_err        -- ���o�G���[���b�Z�[�W(�L�[�t��)
                          ,iv_token_name1  => cv_tkn_task_name
                          ,iv_token_value1 => lv_msg_tkn_1
                          ,iv_token_name2  => cv_tkn_key
                          ,iv_token_value2 => lv_msg_tkn_2
                          ,iv_token_name3  => cv_tkn_key_value
                          ,iv_token_value3 => iv_new_data.install_code
                          ,iv_token_name4  => cv_tkn_item
                          ,iv_token_value4 => lv_msg_tkn_4
                          ,iv_token_name5  => cv_tkn_base_value
                          ,iv_token_value5 => iv_new_data.account_number
                          ,iv_token_name6  => cv_tkn_err_msg
                          ,iv_token_value6 => SQLERRM
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        --
      END IF;
      --
      -- ���_���ύX����Ă��āA��L�܂łŎ擾�ł��Ȃ��ꍇ
      IF ( ld_move_date IS NULL ) THEN
        -- �ڋq���ύX����Ă���ꍇ�A�I�[�i�ύX
        IF NVL( iv_old_data.account_number, cv_space ) <> NVL( iv_new_data.account_number, cv_space ) THEN
          ld_move_date  := NULL;             -- �ړ�����NULL
          on_change_ptn := cn_1;             -- 1(�C��)�Ƃ���
        --����ȊO�̏ꍇ�́A�Ɩ����t�Ƃ���B
        ELSE
          ld_move_date  := gd_process_date;  -- �ړ���(�Ɩ����t)
          on_change_ptn := cn_2;             -- 2(�ړ�)�Ƃ���
        END IF;
        --
      END IF;
      --
    END IF;
--
    od_move_date := ld_move_date;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END chk_xxcso_ib_info_h;
--
  /**********************************************************************************
   * Procedure Name   : get_relation_data
   * Description      : �����֘A���擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_relation_data(
     iv_data_type    IN  VARCHAR2                              -- 1.�f�[�^�^�C�v(1:�V�K 2:�X�V 3:�p�� 4:����)
    ,it_instance_id  IN  csi_item_instances.instance_id%TYPE   -- 2.����ID
    ,ov_errbuf       OUT VARCHAR2                              --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode      OUT VARCHAR2                              --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)                             --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_data'; -- �v���O������
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
    cv_dummy                  VARCHAR2(1);                            -- �}�X�^���݃`�F�b�N�p
    lv_put_msg                VARCHAR2(5000);                         -- �o�̓��b�Z�[�W�p
    ln_data_cnt               NUMBER;                                 -- ���݃`�F�b�N�p
    lv_msg_tkn_1              VARCHAR2(100);                          -- ���b�Z�[�W�g�[�N���擾�p1
    lv_msg_tkn_2              VARCHAR2(100);                          -- ���b�Z�[�W�g�[�N���擾�p2
    lv_msg_tkn_3              VARCHAR2(100);                          -- ���b�Z�[�W�g�[�N���擾�p3
    lv_msg_tkn_4              VARCHAR2(100);                          -- ���b�Z�[�W�g�[�N���擾�p4
    lv_msg_tkn_5              VARCHAR2(100);                          -- ���b�Z�[�W�g�[�N���擾�p5
    lv_msg_tkn_6              VARCHAR2(5000);                         -- ���b�Z�[�W�g�[�N���擾�p5
    lt_new_manufacturer_name  fnd_lookup_values_vl.meaning%TYPE;      -- �V_���[�J��
    lt_new_age_type           po_un_numbers_vl.attribute3%TYPE;       -- �V_�N��
    lv_owner_company_code     VARCHAR2(1);                            -- �V_�{��/�H��R�[�h
    lt_new_owner_company      fnd_flex_values_vl.flex_value%TYPE;     -- �V_�{��/�H��敪
    ln_change_ptn             NUMBER(1);                              -- �ύX�p�^�[��
    lt_new_location           fnd_flex_values_vl.flex_value%TYPE;     -- ���Ə�
    ld_move_date              DATE;                                   -- �ړ���
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �����֘A���擾�p�J�[�\��
    CURSOR get_new_old_data_cur
    IS
      SELECT /*+
               USE_NL(cii xiih hca hp xca hcas hps hl)
             */
             cii.external_reference        install_code                -- �����R�[�h
            ,cii.attribute1                new_model                  -- �V_�@��(DFF1)
            ,cii.attribute2                new_serial_number          -- �V_�@��(DFF2)
            ,cii.quantity                  new_quantity               -- �V_����
            ,xca.sale_base_code            new_department_code        -- �V_���_�R�[�h
            ,hp.party_name                 new_installation_place     -- �V_�ݒu�於
            ,hl.state    ||
             hl.city     ||
             hl.address1 ||
             hl.address2                   new_installation_address   -- �V_�ݒu��Z��
            ,DECODE(cii.instance_status_id
                   ,gn_instance_status_id, cv_yes
                   ,cv_no
             )                             new_active_flag            -- �V_�_���폜�t���O
            ,hca.account_number            new_customer_code          -- �V_�ڋq�R�[�h
            ,DECODE(cii.instance_status_id
                   ,gn_instance_status_id, cv_no
                   ,cv_yes
             )                             effective_flag             -- �V_�����L���t���O
            ,xxcso_util_common_pkg.get_lookup_attribute(
               cv_csi_inst_type_code
              ,cii.instance_type_code
              ,1
              ,gd_process_date
             )                             lease_class                -- �V_���[�X���
            ,cii.attribute5                newold_flag                -- �V_�V�Ñ�t���O
            ,cii.instance_type_code        new_instance_type_code     -- �V_�@��敪
            ,hca.customer_class_code       new_customer_class_code    -- �V_�ڋq�敪
            ,( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
                     ,csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_dclr_place
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             )                            new_declaration_place       -- �V_�\���n
            ,( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
                     ,csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_assets_cost
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             )                             new_assets_cost            -- �V_�擾���i
            ,TO_DATE( ( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
                     ,csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_disposed_date
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             ), cv_yyyymmdd_sla )          new_disposed_date          -- �V_�p�����ϓ�
            ,TO_DATE( cii.attribute3, cv_yyyymmddhhmmdd_sla )
                                           new_first_install_date     -- �V_����ݒu��
            ,TRUNC(cii.creation_date)      new_creation_date          -- �V_�쐬��(�V�Ñ�p)
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD START */
            ,TO_DATE( ( 
               SELECT civ.attribute_value  attribute_value
               FROM   csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
                     ,csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
               WHERE  ciea.attribute_level = gt_attribute_level
               AND    ciea.attribute_code  = cv_fa_move_date
               AND    civ.instance_id      = cii.instance_id
               AND    ciea.attribute_id    = civ.attribute_id
               AND    NVL( ciea.active_start_date, gd_process_date ) <= gd_process_date
               AND    NVL( ciea.active_end_date,   gd_process_date ) >= gd_process_date
             ), cv_yyyymmdd_sla )          new_fa_move_date           -- �V_�Œ莑�Y�ړ���
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD END */
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
            ,xiih.declaration_place        old_declaration_place      -- ��_�\���n
      FROM   csi_item_instances       cii    -- �����}�X�^
            ,xxcso_ib_info_h          xiih   -- �����֘A���ύX�����e�[�u��
            ,hz_cust_accounts_all     hca    -- �ڋq�}�X�^
            ,hz_parties               hp     -- �p�[�e�B�}�X�^
            ,xxcmm_cust_accounts      xca    -- �ڋq�A�h�I���}�X�^
            ,hz_cust_acct_sites_all   hcas   -- �ڋq���ݒn�}�X�^
            ,hz_party_sites           hps    -- �p�[�e�B�T�C�g�}�X�^
            ,hz_locations             hl     -- �ڋq���Ə��}�X�^
      WHERE  cii.instance_id            = it_instance_id       -- A-2�Ŏ擾��������ID
      AND    cii.external_reference     = xiih.install_code 
      AND    cii.owner_party_account_id = hca.cust_account_id
      AND    hca.party_id               = hp.party_id
      AND    hca.cust_account_id        = xca.customer_id
      AND    hca.cust_account_id        = hcas.cust_account_id
      AND    hcas.org_id                = gn_org_id
      AND    hcas.party_site_id         = hps.party_site_id
      AND    hp.party_id                = hps.party_id
      AND    hps.location_id            = hl.location_id
      ;
    -- �����֘A���擾�p�J�[�\�����R�[�h�^
    l_get_new_old_data_rec  get_new_old_data_cur%ROWTYPE;
    -- �V���`�F�b�N�p���R�[�h�^(���f�[�^�p)
    l_old_data_rec          g_check_rtype;
    -- *** ���[�J����O ***
    skip_data1_expt   EXCEPTION;      -- �f�[�^�擾�X�L�b�v1(�����}�X�^)��O
    skip_data2_expt   EXCEPTION;      -- �f�[�^�擾�X�L�b�v2(���̑��t���}�X�^)��O
    sql_err_expt      EXCEPTION;      -- �f�[�^���o�G���[��O
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
--
    BEGIN
      --------------
      -- �ϐ�������
      --------------
      lv_put_msg                := NULL;
      ln_data_cnt               := 0;
      lv_msg_tkn_1              := NULL;
      lv_msg_tkn_2              := NULL;
      lv_msg_tkn_3              := NULL;
      lv_msg_tkn_4              := NULL;
      lv_msg_tkn_5              := NULL;
      lv_msg_tkn_6              := NULL;
      lt_new_manufacturer_name  := NULL;
      lt_new_age_type           := NULL;
      lv_owner_company_code     := cv_owner_company_h_office; --�f�t�H���g�{�Ђ�ݒ�
      lt_new_owner_company      := NULL;
      lt_new_location           := NULL;
      ld_move_date              := NULL;
--
      ------------------------------
      -- �����E�ڋq���擾
      ------------------------------
      OPEN get_new_old_data_cur;
      FETCH get_new_old_data_cur INTO l_get_new_old_data_rec;
      ln_data_cnt := get_new_old_data_cur%ROWCOUNT;
      CLOSE get_new_old_data_cur;
      --�f�[�^���݊m�F
      IF ( ln_data_cnt = cn_0 ) THEN
        -- �g�[�N���擾
        lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_inst_relat_data  -- �����֘A���(�Œ�)
                         );
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_instance_id      -- ����ID(�Œ�)
                         );
        lv_msg_tkn_3 :=  TO_CHAR( it_instance_id );
        RAISE skip_data1_expt;
      END IF;
--
      ------------------------------
      -- �@���񒊏o
      ------------------------------
      BEGIN
        --
        SELECT xxcso_util_common_pkg.get_lookup_meaning(
                  cv_xxcso_csi_maker_code
                 ,punv.attribute2
                 ,gd_process_date
                )               manufacturer_name  -- �V_���[�J�[��
              ,punv.attribute3  age_type           -- �V_�N��
        INTO   lt_new_manufacturer_name
              ,lt_new_age_type
        FROM   po_un_numbers_vl punv -- ���A�ԍ��}�X�^�r���[
        WHERE  punv.un_number = l_get_new_old_data_rec.new_model -- ���A�ԍ�
        ;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ�
        WHEN NO_DATA_FOUND THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_model         -- �@��(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_model_code    -- �@��R�[�h(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_model;
          RAISE skip_data2_expt;
        -- ���̑���O(���f)
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_model         -- �@��(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_model_code    -- �@��R�[�h(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_model;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------
      -- �{��/�H��敪�擾
      ------------------------------
      <<loop_mfg_fctory_cd_chk>>
      FOR i IN 1..g_mfg_fctory_cd.LAST LOOP
        -- ���o�����V_���_�R�[�h��A-1�Ŏ擾�����H��ԕi�q�֐�R�[�h�ƈ�v����ꍇ
        IF (l_get_new_old_data_rec.new_department_code = g_mfg_fctory_cd(i)) THEN
          -- �V_�{�Ё^�H��敪�Ɂu'2'�F�H��v��ݒ�
          lv_owner_company_code := cv_owner_company_fact;
        END IF;
      END LOOP loop_mfg_fctory_cd_chk;
      --
      BEGIN
        --
        SELECT ffvv.flex_value  new_owner_company -- �V_�{�Ё^�H��敪
        INTO   lt_new_owner_company
        FROM   fnd_flex_value_sets ffvs  -- �l�Z�b�g�w�b�_
              ,fnd_flex_values_vl  ffvv  -- �l�Z�b�g����
        WHERE  ffvs.flex_value_set_name = cv_xxcff_owner_company  -- �l�Z�b�g��(XXCFF_OWNER_COMPANY)
        AND    ffvv.flex_value_set_id   = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag        = cv_yes  -- �g�p�\�t���O
        AND    gd_process_date BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                               AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date)) -- �L������
        AND    ffvv.flex_value_meaning =
          (
            SELECT flvv.meaning meaning  -- ���e�i�{�Ё^�H��j
            FROM   fnd_lookup_values_vl flvv  -- �N�C�b�N�R�[�h
            WHERE  flvv.lookup_type  = cv_xxcso1_owner_company   -- �^�C�v
            AND    flvv.lookup_code  = lv_owner_company_code     -- �{�Ё^�H��t���O
            AND    flvv.enabled_flag = cv_yes                    -- �g�p�\�t���O
            AND    gd_process_date  BETWEEN TRUNC(NVL(flvv.start_date_active, gd_process_date))
                                    AND     TRUNC(NVL(flvv.end_date_active,   gd_process_date)) -- �L������
          )
        ;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ�
        WHEN NO_DATA_FOUND THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_owner_comp_type  -- �{��/�H��敪(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_owner_comp_type  -- �{��/�H��敪(�Œ�)
                           );
          lv_msg_tkn_5 :=  lv_owner_company_code;
          RAISE skip_data2_expt;
        -- ���̑���O(���f)
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_owner_comp_type  -- �{��/�H��敪(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_owner_comp_type  -- �{��/�H��敪(�Œ�)
                           );
          lv_msg_tkn_5 :=  lv_owner_company_code;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------
      -- ���Ə��擾
      ------------------------------
      BEGIN
        --
        SELECT ffvv.flex_value   location    -- ���Ə�
        INTO   lt_new_location
        FROM   fnd_flex_value_sets   ffvs   -- �l�Z�b�g�w�b�_
              ,fnd_flex_values_vl    ffvv   -- �l�Z�b�g����
        WHERE  ffvs.flex_value_set_name  = cv_xxcff_mng_place
        AND    ffvv.attribute1           = l_get_new_old_data_rec.new_department_code
        AND    ffvv.flex_value_set_id    = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag         = cv_yes
        AND    gd_process_date  BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                                AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date))
        ;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ�
        WHEN NO_DATA_FOUND THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_mng_place      -- ���Ə�(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_sale_base      -- ���㋒�_(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_department_code;
          RAISE skip_data2_expt;
        -- ���̑���O(���f)
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_mng_place      -- ���Ə�(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_sale_base      -- ���㋒�_(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_department_code;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ------------------------------------------------
      -- �\���n(�}�X�^���݃`�F�b�N)
      ------------------------------------------------
      -- �\���n
      BEGIN
        --
        SELECT 1
        INTO   cv_dummy
        FROM   fnd_flex_value_sets ffvs  -- �l�Z�b�g�w�b�_
              ,fnd_flex_values_vl  ffvv  -- �l�Z�b�g����
        WHERE  ffvs.flex_value_set_name = cv_xxcff_dclr_place  -- �l�Z�b�g��(XXCFF_DCLR_PLACE)
        AND    ffvv.flex_value_set_id   = ffvs.flex_value_set_id
        AND    ffvv.enabled_flag        = cv_yes  -- �g�p�\�t���O
        AND    gd_process_date BETWEEN TRUNC(NVL(ffvv.start_date_active, gd_process_date))
                               AND     TRUNC(NVL(ffvv.end_date_active,   gd_process_date)) -- �L������
        AND    ffvv.flex_value          = l_get_new_old_data_rec.new_declaration_place     -- �\���n
        ;
      EXCEPTION
        -- �f�[�^�����݂��Ȃ�
        WHEN NO_DATA_FOUND THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_dclr_place     -- �\���n(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_dclr_place     -- �\���n(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_declaration_place;
          RAISE skip_data2_expt;
        -- ���̑���O(���f)
        WHEN OTHERS THEN
          -- �g�[�N���擾
          lv_msg_tkn_1 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_dclr_place    -- �\���n(�Œ�)
                           );
          lv_msg_tkn_4 :=  xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_dclr_place    -- �\���n(�Œ�)
                           );
          lv_msg_tkn_5 :=  l_get_new_old_data_rec.new_declaration_place;
          lv_msg_tkn_6 :=  SUBSTRB(SQLERRM,1,5000);
          RAISE sql_err_expt;
      END;
--
      ---------------------------------------------------------------
      -- �ύX�`�F�b�N�A�y�сA�����֘A���ύX�����e�[�u���X�V���ڐݒ�
      ---------------------------------------------------------------
      -- ��r�p(�V�f�[�^)�̊i�[(���������X�V�f�[�^�Ƃ��Ă��g�p)
      g_new_data_rec.install_code        := l_get_new_old_data_rec.install_code;             -- �����R�[�h
      g_new_data_rec.manufacturer_name   := lt_new_manufacturer_name;                        -- ���[�J�[��
      g_new_data_rec.age_type            := lt_new_age_type;                                 -- �N��
      g_new_data_rec.un_number           := l_get_new_old_data_rec.new_model;                -- �@��
      g_new_data_rec.install_number      := l_get_new_old_data_rec.new_serial_number;        -- �@��
      g_new_data_rec.quantity            := l_get_new_old_data_rec.new_quantity;             -- ����
      g_new_data_rec.base_code           := l_get_new_old_data_rec.new_department_code;      -- ���_�R�[�h
      g_new_data_rec.owner_company_type  := lt_new_owner_company;                            -- �{�Ё^�H��敪
      g_new_data_rec.install_name        := l_get_new_old_data_rec.new_installation_place;   -- �ݒu�於
      g_new_data_rec.install_address     := l_get_new_old_data_rec.new_installation_address; -- �ݒu��Z��
      g_new_data_rec.logical_delete_flag := l_get_new_old_data_rec.new_active_flag;          -- �_���폜�t���O
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD START */
      g_new_data_rec.fa_move_date        := l_get_new_old_data_rec.new_fa_move_date;         -- �Œ莑�Y�ړ���
/* 2016.02.09 H.Okada E_�{�ғ�_13456 ADD END */
      --
      -- �ڋq�R�[�h
      IF (l_get_new_old_data_rec.new_customer_class_code = cv_cust_class_10) THEN
        g_new_data_rec.account_number    := l_get_new_old_data_rec.new_customer_code;        -- �ڋq�R�[�h
      ELSE
        g_new_data_rec.account_number    := gv_customer_code_dammy;                          -- �_�~�[�ڋq�R�[�h(���_)
      END IF;
      g_new_data_rec.declaration_place   := l_get_new_old_data_rec.new_declaration_place;    -- �\���n
      --
      -- �p�����قŖ��A�g
      IF ( iv_data_type = cv_disposed ) THEN
        g_new_data_rec.disposal_intaface_flag := cv_yes;
      -- ���̑�
      ELSE
        g_new_data_rec.disposal_intaface_flag := cv_no;
      END IF;
      --
      -- ��ԏ����̏ꍇ
      IF ( gv_prm_process_date IS NULL) THEN
        -- �ύX�f�[�^�̏ꍇ
        IF ( iv_data_type = cv_update ) THEN
          --��r�p(���f�[�^)�̊i�[
          l_old_data_rec.manufacturer_name   := l_get_new_old_data_rec.old_manufacturer_name;    -- ���[�J�[��
          l_old_data_rec.age_type            := l_get_new_old_data_rec.old_age_type;             -- �N��
          l_old_data_rec.un_number           := l_get_new_old_data_rec.old_model;                -- �@��
          l_old_data_rec.install_number      := l_get_new_old_data_rec.old_serial_number;        -- �@��
          l_old_data_rec.quantity            := l_get_new_old_data_rec.old_quantity;             -- ����
          l_old_data_rec.base_code           := l_get_new_old_data_rec.old_department_code;      -- ���_�R�[�h
          l_old_data_rec.owner_company_type  := l_get_new_old_data_rec.old_owner_company;        -- �{�Ё^�H��敪
          l_old_data_rec.install_name        := l_get_new_old_data_rec.old_installation_place;   -- �ݒu�於
          l_old_data_rec.install_address     := l_get_new_old_data_rec.old_installation_address; -- �ݒu��Z��
          l_old_data_rec.logical_delete_flag := l_get_new_old_data_rec.old_active_flag;          -- �_���폜�t���O
          l_old_data_rec.account_number      := l_get_new_old_data_rec.old_customer_code;        -- �ڋq�R�[�h
          l_old_data_rec.declaration_place   := l_get_new_old_data_rec.old_declaration_place;    -- �\���n
          --
          -- =================================
          -- A-4.�����֘A���ύX�`�F�b�N����
          -- =================================
          chk_xxcso_ib_info_h(
             iv_new_data     => g_new_data_rec     -- 1.�V�f�[�^
            ,iv_old_data     => l_old_data_rec     -- 2.���f�[�^
            ,on_change_ptn   => ln_change_ptn      -- 3.�ύX�p�^�[��(1:�C�� 2:�ړ�)
            ,od_move_date    => ld_move_date       -- 4.�ړ��� ���ύX�p�^�[��2�̏ꍇ�̂ݐݒ�
            ,ov_errbuf       => lv_errbuf          --   �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode      => lv_retcode         --   ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg       => lv_errmsg);        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          -- �G���[�̏ꍇ(���f)
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END IF;
--
      -------------------------------------
      -- �C���^�[�t�F�[�X�f�[�^�ݒ�
      -------------------------------------
      -- ���ʍ���
      g_if_rec.object_code           := l_get_new_old_data_rec.install_code;              -- �����R�[�h
      g_if_rec.generation_date       := gd_process_date;                                  -- ������
      g_if_rec.manufacturer_name     := g_new_data_rec.manufacturer_name;                 -- ���[�J��
      g_if_rec.age_type              := g_new_data_rec.age_type;                          -- �N��
      g_if_rec.model                 := g_new_data_rec.un_number;                         -- �@��
      g_if_rec.quantity              := g_new_data_rec.quantity;                          -- ����
      g_if_rec.department_code       := g_new_data_rec.base_code;                         -- �Ǘ�����
      g_if_rec.owner_company_type    := g_new_data_rec.owner_company_type;                -- �{�Ё^�H��敪
      g_if_rec.installation_place    := SUBSTRB( g_new_data_rec.install_name, 1, 50 );    -- ���ݒu��
      g_if_rec.installation_address  := g_new_data_rec.install_address;                   -- ���ݒu�ꏊ
      g_if_rec.active_flag           := l_get_new_old_data_rec.effective_flag;            -- �����L���t���O
      g_if_rec.import_status         := cv_0;                                             -- �捞�X�e�[�^�X(���捞)
      g_if_rec.group_id              := NULL;                                             -- �O���[�vID
      g_if_rec.customer_code         := g_new_data_rec.account_number;                    -- �ڋq�R�[�h
      g_if_rec.machine_type          := l_get_new_old_data_rec.new_instance_type_code;    -- �@��敪
      g_if_rec.lease_class           := l_get_new_old_data_rec.lease_class;               -- ���[�X���
      g_if_rec.assets_cost           := l_get_new_old_data_rec.new_assets_cost;           -- �擾���i
      g_if_rec.dclr_place            := l_get_new_old_data_rec.new_declaration_place;     -- �\���n 
      g_if_rec.location              := SUBSTRB( lt_new_location, 1, 30 );                -- ���Ə�
      g_if_rec.date_retired          := l_get_new_old_data_rec.new_disposed_date;         -- ���E���p��
      --------------------------
      -- ���Ƌ��^���̐ݒ�
      --------------------------
      -- �V�Ñ�ȊO
      IF ( NVL( l_get_new_old_data_rec.newold_flag, cv_no ) <> cv_yes ) THEN
-- Ver.1.2 Mod Start
--        g_if_rec.date_placed_in_service     :=
--          TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_first_install_date, cn_1 ), cv_mm );  -- ���Ƌ��p��(����ݒu�������P��)
        IF ( l_get_new_old_data_rec.new_first_install_date IS NOT NULL ) THEN
          g_if_rec.date_placed_in_service     :=
            TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_first_install_date, cn_1 ), cv_mm );  -- ���Ƌ��p��(����ݒu�������P��)       
        ELSE
          g_if_rec.date_placed_in_service     :=
            TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_creation_date, cn_1 ), cv_mm );       -- ���Ƌ��p��(�쐬�������P��)
        END IF;
-- Ver.1.2 Mod End
      ELSE
        g_if_rec.date_placed_in_service     :=
          TRUNC( ADD_MONTHS( l_get_new_old_data_rec.new_creation_date, cn_1 ), cv_mm );       -- ���Ƌ��p��(�쐬�������P��)
      END IF;
      --------------------------
      -- �ړ����̐ݒ�
      --------------------------
      -- ���(�V�K)
      IF ( iv_data_type = cv_create ) THEN
        g_if_rec.moved_date      := NULL;          -- �ړ���
      -- ���(�X�V)
      ELSIF ( iv_data_type = cv_update ) THEN
        -- 2(�ړ�)�𔺂��ꍇ
        IF ( ln_change_ptn = cn_2 ) THEN
          g_if_rec.moved_date    := ld_move_date;  -- �ړ���(�ڋq�ڍs�� or ����Ɠ� or �Ɩ����t)
        -- 1(�C��)
        ELSE
          g_if_rec.moved_date    := NULL;          -- �ړ���(NULL)
        END IF;
      -- ���(�p��)
      ELSIF ( iv_data_type = cv_disposed ) THEN
        g_if_rec.moved_date      := NULL;          -- �ړ���(NULL)
      -- ����
      ELSIF ( iv_data_type = cv_any_time ) THEN
        g_if_rec.moved_date      := NULL;          -- �ړ���(NULL)
        g_if_rec.date_retired    := NULL;          -- ���E���p��(NULL)
      END IF;
--
    EXCEPTION
      -- �f�[�^�擾�X�L�b�v(�����}�X�^)��O(�����p��)
      WHEN skip_data1_expt THEN
        -- ���b�Z�[�W�ҏW
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_no_data1_wrn  -- �f�[�^�Ȃ��x�����b�Z�[�W
                       ,iv_token_name1  => cv_tkn_task_name
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_item
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_base_value
                       ,iv_token_value3 => lv_msg_tkn_3
                      );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- �o�̓��b�Z�[�W
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ���O���b�Z�[�W
          );
        ov_retcode := cv_status_warn;
      -- �f�[�^�擾�X�L�b�v(���̑��t���}�X�^)��O(�����p��)
      WHEN skip_data2_expt THEN
        -- �g�[�N���ҏW
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_instance_code -- �����R�[�h(�Œ�)
                         );
        lv_msg_tkn_3 :=  l_get_new_old_data_rec.install_code;
        -- ���b�Z�[�W�ҏW
        lv_put_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_no_data2_wrn     -- �f�[�^�Ȃ����b�Z�[�W(�L�[�t��)
                       ,iv_token_name1  => cv_tkn_task_name
                       ,iv_token_value1 => lv_msg_tkn_1
                       ,iv_token_name2  => cv_tkn_key
                       ,iv_token_value2 => lv_msg_tkn_2
                       ,iv_token_name3  => cv_tkn_key_value
                       ,iv_token_value3 => lv_msg_tkn_3
                       ,iv_token_name4  => cv_tkn_item
                       ,iv_token_value4 => lv_msg_tkn_4
                       ,iv_token_name5  => cv_tkn_base_value
                       ,iv_token_value5 => lv_msg_tkn_5
                      );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_put_msg       -- �o�̓��b�Z�[�W
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_put_msg       -- ���O���b�Z�[�W
          );
        ov_retcode := cv_status_warn;
      -- SQL�G���[��O(�������f)
      WHEN sql_err_expt THEN
        -- �g�[�N���ҏW
        lv_msg_tkn_2 :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_instance_code -- �����R�[�h(�Œ�)
                         );
        lv_msg_tkn_3 :=  l_get_new_old_data_rec.install_code;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_get_data2_err     -- ���o�G���[���b�Z�[�W(�L�[�t��)
                      ,iv_token_name1  => cv_tkn_task_name
                      ,iv_token_value1 => lv_msg_tkn_1
                      ,iv_token_name2  => cv_tkn_key
                      ,iv_token_value2 => lv_msg_tkn_2
                      ,iv_token_name3  => cv_tkn_key_value
                      ,iv_token_value3 => lv_msg_tkn_3
                      ,iv_token_name4  => cv_tkn_item
                      ,iv_token_value4 => lv_msg_tkn_4
                      ,iv_token_name5  => cv_tkn_base_value
                      ,iv_token_value5 => lv_msg_tkn_5
                      ,iv_token_name6  => cv_tkn_err_msg
                      ,iv_token_value6 => lv_msg_tkn_6
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_relation_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �Ώە������o(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_get_target_rec  get_target_cur%ROWTYPE;    -- �Ώە����擾�J�[�\�����R�[�h�ϐ�
    -- *** ���[�J����O ***
    skip_data_expt    EXCEPTION;                 -- �X�L�b�v�f�[�^��O
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
    OPEN get_target_cur;
    <<loop_get_target>>
    LOOP
      BEGIN
        FETCH get_target_cur INTO l_get_target_rec;
        EXIT WHEN get_target_cur%NOTFOUND;
--
        -- �Ώی����̎擾
        gn_target_cnt := gn_target_cnt + 1;
--
        -- �ϐ��̏�����
        g_new_data_rec := NULL;  -- �V���f�[�^��r(���������e�[�u���X�V)�p���R�[�h�^
        g_if_rec       := NULL;  -- �C���^�[�t�F�[�X�o�^�f�[�^�i�[�p���R�[�h�^
--
        -- ========================================
        -- A-3.�����֘A���擾
        -- ========================================
        get_relation_data(
           iv_data_type    => l_get_target_rec.data_type     -- 1.�f�[�^�^�C�v(1:�V�K 2:�X�V 3:�p�� 4:����)
          ,it_instance_id  => l_get_target_rec.instance_id   -- 2.����ID
          ,ov_errbuf       => lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- �G���[�̏ꍇ(���f)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        -- �x���̏ꍇ(�X�L�b�v)
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- =============================================
        -- A-5.���̋@�����Ǘ��C���^�t�F�[�X���݃`�F�b�N
        -- =============================================
        chk_xxcff_if_exists(
           ov_errbuf       => lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- �G���[�̏ꍇ(���f)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        -- �x���̏ꍇ(�X�L�b�v)
        ELSIF (lv_retcode = cv_status_warn) THEN
          RAISE skip_data_expt;
        END IF;
--
        -- �����ȊO�̏ꍇ
        IF ( l_get_target_rec.data_type NOT IN ( cv_any_time ) ) THEN
          -- =========================================
          -- A-6.�����֘A�ύX�����e�[�u�����b�N����
          -- =========================================
          lock_xxcso_ib_info_h(
            ov_errbuf       => lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
           -- �G���[�̏ꍇ(���f)
           IF (lv_retcode = cv_status_error) THEN
             RAISE global_process_expt;
           -- �x���̏ꍇ(�X�L�b�v)
           ELSIF (lv_retcode = cv_status_warn) THEN
             RAISE skip_data_expt;
           END IF;
--
          -- =========================================
          -- A-7.�����֘A�ύX�����e�[�u���X�V����
          -- =========================================
          upd_xxcso_ib_info_h(
            ov_errbuf       => lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
           -- �G���[�̏ꍇ(���f)
           IF (lv_retcode = cv_status_error) THEN
             RAISE global_process_expt;
           END IF;
           --
        END IF;
--
        -- =========================================
        -- A-8.���̋@�����Ǘ��C���^�t�F�[�X�o�^����
        -- =========================================
        ins_xxcff_if(
           ov_errbuf       => lv_errbuf                      --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode                     --   ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg);                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        -- �G���[�̏ꍇ(���f)
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_normal_cnt := gn_normal_cnt + 1;  --���팏���J�E���g
--
      EXCEPTION
        -- �x���f�[�^��O(�����p��)
        WHEN skip_data_expt THEN
          gn_warn_cnt := gn_warn_cnt + 1;    -- �x�������J�E���g
          ov_retcode  := lv_retcode;         -- �߂�l�Ɍx����ݒ�
      END;
--
    END LOOP get_target_cur;
    --
    --�J�[�\���N���[�Y
    CLOSE get_target_cur;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      -- �J�[�\���N���[�Y
      IF ( get_target_cur%ISOPEN ) THEN
        CLOSE get_target_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_process_date IN  VARCHAR2     -- 1.�������s��
    ,ov_errbuf       OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_process_date => iv_process_date   -- 1.�������s��
      ,ov_errbuf       => lv_errbuf         --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode        --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώە������o(A-2)
    -- ===============================
    get_target_data(
       ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf          OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode         OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_process_date IN  VARCHAR2      -- 1.�������s��
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
       iv_process_date => iv_process_date  -- 1.�������s��
      ,ov_errbuf       => lv_errbuf        --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode       --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      --
      --�����ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      --
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
END XXCSO013A03C;
/
