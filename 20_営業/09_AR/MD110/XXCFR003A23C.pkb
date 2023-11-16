CREATE OR REPLACE PACKAGE BODY XXCFR003A23C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFR003A23C_pkb(body)
 * Description      : ����ō��z�쐬����
 * MD.050           : MD050_CFR_003_A23_����ō��z�쐬����.doc
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_invoice_p          �����w�b�_��񒊏o(A-2)
 *  transfer_to_ar_p       AR�A�W����(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/07/25    1.0   R.Oikawa         �V�K�쐬(E_�{�ғ�_18983)
 *  2023/11/14    1.1   M.Akachi         E_�{�ғ�_19546 �T�C�N���ׂ��Ή�
 *
 *****************************************************************************************/
--
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCFR003A23C';                      -- �p�b�P�[�W��
  cv_msg_kbn_cfr              CONSTANT VARCHAR2(5)          := 'XXCFR';
--
  -- �v���t�@�C��
  cv_ra_trx_type_tax          CONSTANT VARCHAR2(30)         := 'XXCFR1_RA_TRX_TYPE_TAX';            -- ����^�C�v_����ō��z�쐬
  cv_other_tax_code           CONSTANT VARCHAR2(30)         := 'XXCFR1_OTHER_TAX_CODE';             -- �ΏۊO����ŃR�[�h
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF1_COMPANY_CODE';          -- ��ЃR�[�h
  cv_aff2_dept_fin            CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF2_DEPT_FIN';              -- ����R�[�h_�����o����
  cv_aff3_receive_excise_tax  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_RECEIVE_EXCISE_TAX';    -- ����Ȗ�_�������œ�
  cv_aff3_account_receivable  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_ACCOUNT_RECEIVABLE';    -- ����Ȗ�_���|��
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_SUBACCT_DUMMY';         -- �⏕�Ȗ�_�_�~�[�l
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF5_CUSTOMER_DUMMY';        -- �ڋq�R�[�h_�_�~�[�l
  cv_aff6_company_dummy       CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF6_COMPANY_DUMMY';         -- ��ƃR�[�h_�_�~�[�l
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF7_PRELIMINARY1_DUMMY';    -- �\���P_�_�~�[�l
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF8_PRELIMINARY2_DUMMY';    -- �\���Q_�_�~�[�l
  cv_org_id                   CONSTANT VARCHAR2(30)         := 'ORG_ID';                            -- �c�ƒP��
  cv_description              CONSTANT VARCHAR2(30)         := 'XXCFR1_DESCRIPTION';                -- �i�ږ��דE�v_�ō��z
  cv_header_attribute5        CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_DPT';                  -- �N�[����_����ō��z
  cv_header_attribute6        CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_USER';                 -- �`�[���͎�_����ō��z
  cv_description_inv          CONSTANT VARCHAR2(30)         := 'XXCFR1_DESCRIPTION_INV';            -- �i�ږ��דE�v_�{�̍��z
  cv_header_attribute5_inv    CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_DPT_INV';              -- �N�[����_�{�̍��z
  cv_header_attribute6_inv    CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_USER_INV';             -- �`�[���͎�_�{�̍��z
  cv_aff3_rec_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_REC_INV';               -- ����Ȗ�_�{�̍��zREC
  cv_aff3_rev_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_REV_INV';               -- ����Ȗ�_�{�̍��zREV
  cv_aff3_tax_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_TAX_INV';               -- ����Ȗ�_�{�̍��zTAX
  cv_aff4_rec_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_REC_INV';               -- �⏕�Ȗ�_�{�̍��zREC
  cv_aff4_rev_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_REV_INV';               -- �⏕�Ȗ�_�{�̍��zREV
  cv_aff4_tax_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_TAX_INV';               -- �⏕�Ȗ�_�{�̍��zTAX
--
  -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcfr_name         CONSTANT VARCHAR2(15)         := 'XXCFR';                             -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_cfr_00056            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00056';                  -- �V�X�e���G���[���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- �����������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_cfr_00004            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00004';                  -- �v���t�@�C���擾�G���[
  cv_msg_cfr_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00003';                  -- ���b�N�G���[
--
  -- �t�@�C���o��
  cv_file_type_log            CONSTANT VARCHAR2(10)         := 'LOG';                               -- ���O�o��
  -- �g�[�N����
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- �����̃g�[�N����
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROF_NAME';                         -- �v���t�@�C�����̃g�[�N����
  cv_tkn_table                CONSTANT VARCHAR2(15)         := 'TABLE';                             -- �e�[�u�����̃g�[�N����
  -- �L��
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
  -- DFF
  cv_hold                     CONSTANT VARCHAR2(4)          := 'HOLD';
  cv_waiting                  CONSTANT VARCHAR2(7)          := 'WAITING';
  -- ���t�t�H�[�}�b�g
  cv_yyyy_mm_dd               CONSTANT VARCHAR2(10)         := 'YYYY/MM/DD';
  cv_yyyymmdd                 CONSTANT VARCHAR2(10)         := 'YYYYMMDD';
  -- ����ō��z�쐬�t���O
  cv_not_created              CONSTANT VARCHAR2(1)          := '0';                                 -- ���쐬
  cv_created                  CONSTANT VARCHAR2(1)          := '1';                                 -- �쐬��
  -- 
  cn_0                        CONSTANT NUMBER               := 0;
  cn_1                        CONSTANT NUMBER               := 1;
  cn_2                        CONSTANT NUMBER               := 2;
  cn_100                      CONSTANT NUMBER               := 100;
  cv_line                     CONSTANT VARCHAR2(4)          := 'LINE';
  cv_tax                      CONSTANT VARCHAR2(3)          := 'TAX';
  cv_rev                      CONSTANT VARCHAR2(3)          := 'REV';
  cv_rec                      CONSTANT VARCHAR2(3)          := 'REC';
  cv_tx                       CONSTANT VARCHAR2(2)          := 'TX';                                 -- �`�[�ԍ��ړ�(�ō��z)
  cv_ne                       CONSTANT VARCHAR2(2)          := 'NE';                                 -- �`�[�ԍ��ړ�(�{�̍��z)
  cv_currency_code            CONSTANT VARCHAR2(3)          := 'JPY';                                -- �ʉ�
  cv_user                     CONSTANT VARCHAR2(4)          := 'User';                               -- ���Z�^�C�v
  cv_table_name               CONSTANT VARCHAR2(30)         := 'XXCFR_INVOICE_HEADERS';              -- �e�[�u����
--
  -- ==============================
  -- �O���[�o���ϐ�
  -- ==============================
  gv_out_msg                           VARCHAR2(2000);
  gn_target_cnt                        NUMBER               := 0;                                   -- �Ώی���
  gn_normal_cnt                        NUMBER               := 0;                                   -- ���팏��
  gn_error_cnt                         NUMBER               := 0;                                   -- �G���[����
--
  gv_ra_trx_type_tax                   VARCHAR2(30);                                                -- ����^�C�v_����ō��z�쐬
  gv_other_tax_code                    VARCHAR2(30);                                                -- �ΏۊO����ŃR�[�h
  gn_org_id                            NUMBER;                                                      -- �c�ƒP��
  gv_aff1_company_code                 VARCHAR2(30);                                                -- ��ЃR�[�h
  gv_aff2_dept_fin                     VARCHAR2(30);                                                -- ����R�[�h_�����o����
  gv_aff3_receive_excise_tax           VARCHAR2(30);                                                -- ����Ȗ�_�������œ�
  gv_aff3_account_receivable           VARCHAR2(30);                                                -- ����Ȗ�_���|��
  gv_aff4_subacct_dummy                VARCHAR2(30);                                                -- �⏕�Ȗ�_�_�~�[�l
  gv_aff5_customer_dummy               VARCHAR2(30);                                                -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy                VARCHAR2(30);                                                -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy           VARCHAR2(30);                                                -- �\���P_�_�~�[�l
  gv_aff8_preliminary2_dummy           VARCHAR2(30);                                                -- �\���Q_�_�~�[�l
  gv_description                       VARCHAR2(30);                                                -- �i�ږ��דE�v_�ō��z
  gv_header_attribute5                 VARCHAR2(30);                                                -- �N�[����_����ō��z
  gv_header_attribute6                 VARCHAR2(30);                                                -- �`�[���͎�_����ō��z
  gv_description_inv                   VARCHAR2(30);                                                -- �i�ږ��דE�v_�{�̍��z
  gv_header_attribute5_inv             VARCHAR2(30);                                                -- �N�[����_�{�̍��z
  gv_header_attribute6_inv             VARCHAR2(30);                                                -- �`�[���͎�_�{�̍��z
  gv_aff3_rec_inv                      VARCHAR2(30);                                                -- ����Ȗ�_�{�̍��zREC
  gv_aff3_rev_inv                      VARCHAR2(30);                                                -- ����Ȗ�_�{�̍��zREV
  gv_aff3_tax_inv                      VARCHAR2(30);                                                -- ����Ȗ�_�{�̍��zTAX
  gv_aff4_rec_inv                      VARCHAR2(30);                                                -- �⏕�Ȗ�_�{�̍��zREC
  gv_aff4_rev_inv                      VARCHAR2(30);                                                -- �⏕�Ȗ�_�{�̍��zREV
  gv_aff4_tax_inv                      VARCHAR2(30);                                                -- �⏕�Ȗ�_�{�̍��zTAX
--
  -- ==============================
  -- �O���[�o����O
  -- ==============================
  -- *** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �v���t�@�C���l�̎擾
    -- ============================================================
    -- ����^�C�v_����ō��z�쐬
    gv_ra_trx_type_tax := FND_PROFILE.VALUE( cv_ra_trx_type_tax );
    IF gv_ra_trx_type_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ΏۊO����ŃR�[�h
    gv_other_tax_code := FND_PROFILE.VALUE( cv_other_tax_code );
    IF gv_other_tax_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_other_tax_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ЃR�[�h
    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF gv_aff1_company_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff1_company_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����R�[�h_�����o����
    gv_aff2_dept_fin := FND_PROFILE.VALUE( cv_aff2_dept_fin );
    IF gv_aff2_dept_fin IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff2_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_�������œ�
    gv_aff3_receive_excise_tax := FND_PROFILE.VALUE( cv_aff3_receive_excise_tax );
    IF gv_aff3_receive_excise_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_receive_excise_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_���|��
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );
    IF gv_aff3_account_receivable IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_account_receivable
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�_�~�[�l
    gv_aff4_subacct_dummy := FND_PROFILE.VALUE( cv_aff4_subacct_dummy );
    IF gv_aff4_subacct_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_subacct_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ڋq�R�[�h_�_�~�[�l
    gv_aff5_customer_dummy := FND_PROFILE.VALUE( cv_aff5_customer_dummy );
    IF gv_aff5_customer_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff5_customer_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��ƃR�[�h_�_�~�[�l
    gv_aff6_company_dummy := FND_PROFILE.VALUE( cv_aff6_company_dummy );
    IF gv_aff6_company_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff6_company_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���P_�_�~�[�l
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );
    IF gv_aff7_preliminary1_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff7_preliminary1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �\���Q_�_�~�[�l
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );
    IF gv_aff8_preliminary2_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff8_preliminary2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �i�ږ��דE�v_�ō��z
    gv_description := FND_PROFILE.VALUE( cv_description );
    IF gv_description IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_description
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �c�ƒP��
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �N�[����_����ō��z
    gv_header_attribute5 := FND_PROFILE.VALUE( cv_header_attribute5 );
    IF gv_header_attribute5 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute5
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �`�[���͎�_����ō��z
    gv_header_attribute6 := FND_PROFILE.VALUE( cv_header_attribute6 );
    IF gv_header_attribute6 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute6
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �i�ږ��דE�v_�{�̍��z
    gv_description_inv := FND_PROFILE.VALUE( cv_description_inv );
    IF gv_description_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_description_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �N�[����_�{�̍��z
    gv_header_attribute5_inv := FND_PROFILE.VALUE( cv_header_attribute5_inv );
    IF gv_header_attribute5_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute5_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �`�[���͎�_�{�̍��z
    gv_header_attribute6_inv := FND_PROFILE.VALUE( cv_header_attribute6_inv );
    IF gv_header_attribute6_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute6_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_�{�̍��zREC
    gv_aff3_rec_inv := FND_PROFILE.VALUE( cv_aff3_rec_inv );
    IF gv_aff3_rec_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_rec_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_�{�̍��zREV
    gv_aff3_rev_inv := FND_PROFILE.VALUE( cv_aff3_rev_inv );
    IF gv_aff3_rev_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_rev_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ����Ȗ�_�{�̍��zTAX
    gv_aff3_tax_inv := FND_PROFILE.VALUE( cv_aff3_tax_inv );
    IF gv_aff3_tax_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_tax_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�{�̍��zREC
    gv_aff4_rec_inv := FND_PROFILE.VALUE( cv_aff4_rec_inv );
    IF gv_aff4_rec_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_rec_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�{�̍��zREV
    gv_aff4_rev_inv := FND_PROFILE.VALUE( cv_aff4_rev_inv );
    IF gv_aff4_rev_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_rev_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �⏕�Ȗ�_�{�̍��zTAX
    gv_aff4_tax_inv := FND_PROFILE.VALUE( cv_aff4_tax_inv );
    IF gv_aff4_tax_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_tax_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : transfer_to_ar_p
   * Description      : AR�A�W����(A-3)
   ***********************************************************************************/
  PROCEDURE transfer_to_ar_p(
    ov_errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_invoice_id               IN  NUMBER    -- �ꊇ������ID
  , in_set_of_books_id          IN  NUMBER    -- ��v����ID
  , in_inv_gap_amount           IN  NUMBER    -- �{�̍��z
  , in_tax_gap_amount           IN  NUMBER    -- �ō��z
  , iv_term_name                IN  VARCHAR2  -- �x������
  , in_bill_cust_account_id     IN  NUMBER    -- ������ڋqID
  , in_bill_cust_acct_site_id   IN  NUMBER    -- ������ڋq���ݒnID
  , id_cutoff_date              IN  DATE      -- ����
  , iv_receipt_location_code    IN  VARCHAR2  -- �������_�R�[�h
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'transfer_to_ar_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_interface_line_attribute1        VARCHAR2(30);                           -- �`�[�ԍ�(�ō��z)
    lv_interface_line_atr1_inv          VARCHAR2(30);                           -- �`�[�ԍ�(�{�̍��z)
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- �ō��z���������Ă���ꍇAROIF���쐬
    IF ( NVL(in_tax_gap_amount,0) <> 0 ) THEN
      -- ============================================================
      -- �`�[�ԍ��擾
      -- ============================================================
      SELECT  cv_tx || TO_CHAR(id_cutoff_date, cv_yyyymmdd) || LPAD(xxcfr_slip_number_tx_s01.NEXTVAL, 8, 0)
      INTO    lv_interface_line_attribute1
      FROM    dual;
--
      -- ============================================================
      -- �ō��z��AR�������OIF�o�^�y�{�̍s�z
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- ������׃R���e�L�X�g
        interface_line_attribute1                 , -- �������DFF1(�`�[�ԍ�)
        interface_line_attribute2                 , -- �������DFF2(���׍s�ԍ�)
        batch_source_name                         , -- ����\�[�X
        set_of_books_id                           , -- ��v����ID
        line_type                                 , -- ���׃^�C�v
        description                               , -- �i�ږ��דE�v
        currency_code                             , -- �ʉ݃R�[�h
        amount                                    , -- ���׋��z
        cust_trx_type_name                        , -- ����^�C�v
        term_name                                 , -- �x������
        orig_system_bill_customer_id              , -- ������ڋqID
        orig_system_bill_address_id               , -- ������ڋq���ݒn�Q��ID
        link_to_line_context                      , -- �����N���׃R���e�L�X�g
        link_to_line_attribute1                   , -- �����N����DFF1
        link_to_line_attribute2                   , -- �����N����DFF2
        conversion_type                           , -- ���Z�^�C�v
        conversion_rate                           , -- ���Z���[�g
        trx_date                                  , -- �����
        gl_date                                   , -- GL�L����
        trx_number                                , -- �`�[�ԍ�
        quantity                                  , -- ����
        unit_selling_price                        , -- �̔��P��
        tax_code                                  , -- �ŋ��R�[�h
        header_attribute_category                 , -- �w�b�_�[DFF�J�e�S��
        header_attribute5                         , -- �w�b�_�[DFF5(�N�[����)
        header_attribute6                         , -- �w�b�_�[DFF6(�`�[���͎�)
        header_attribute7                         , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        header_attribute8                         , -- �w�b�_�[DFF8(�ʐ��������)
        header_attribute9                         , -- �w�b�_�[DFF9(�ꊇ���������)
        header_attribute11                        , -- �w�b�_�[DFF11(�������_)
        header_attribute14                        , -- �w�b�_�[DFF14(�`�[�ԍ�)
        header_attribute15                        , -- �w�b�_�[DFF15(GL�L����)
        created_by                                , -- �쐬��
        creation_date                             , -- �쐬��
        last_updated_by                           , -- �ŏI�X�V��
        last_update_date                          , -- �ŏI�X�V��
        last_update_login                         , -- �ŏI�X�V���O�C��
        org_id                                      -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- ������׃R���e�L�X�g
        lv_interface_line_attribute1              , -- �������DFF1(�`�[�ԍ�)
        cn_1                                      , -- �������DFF2(���׍s�ԍ�)
        gv_ra_trx_type_tax                        , -- ����\�[�X
        in_set_of_books_id                        , -- ��v����ID
        cv_line                                   , -- ���׃^�C�v
        gv_description                            , -- �i�ږ��דE�v
        cv_currency_code                          , -- �ʉ݃R�[�h
        in_tax_gap_amount                         , -- ���׋��z
        gv_ra_trx_type_tax                        , -- ����^�C�v
        iv_term_name                              , -- �x������
        in_bill_cust_account_id                   , -- ������ڋqID
        in_bill_cust_acct_site_id                 , -- ������ڋq���ݒn�Q��ID
        NULL                                      , -- �����N���׃R���e�L�X�g
        NULL                                      , -- �����N����DFF1
        NULL                                      , -- �����N����DFF2
        cv_user                                   , -- ���Z�^�C�v
        cn_1                                      , -- ���Z���[�g
        id_cutoff_date                            , -- �����
        id_cutoff_date                            , -- GL�L����
        lv_interface_line_attribute1              , -- �`�[�ԍ�
        cn_1                                      , -- ����
        in_tax_gap_amount                         , -- �̔��P��
        gv_other_tax_code                         , -- �ŋ��R�[�h
        gn_org_id                                 , -- �w�b�_�[DFF�J�e�S��
        gv_header_attribute5                      , -- �w�b�_�[DFF5(�N�[����)
        gv_header_attribute6                      , -- �w�b�_�[DFF6(�`�[���͎�)
        cv_hold                                   , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        cv_waiting                                , -- �w�b�_�[DFF8(�ʐ��������)
        cv_waiting                                , -- �w�b�_�[DFF9(�ꊇ���������)
        iv_receipt_location_code                  , -- �w�b�_�[DFF11(�������_)
        in_invoice_id                             , -- �w�b�_�[DFF14(�`�[�ԍ�)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- �w�b�_�[DFF15(GL�L����)
        cn_user_id                                , -- �쐬��
        SYSDATE                                   , -- �쐬��
        cn_user_id                                , -- �ŏI�X�V��
        SYSDATE                                   , -- �ŏI�X�V��
        cn_login_id                               , -- �ŏI�X�V���O�C��
        gn_org_id                                   -- �c�ƒP��ID
        );
--
      -- ============================================================
      -- �ō��z��AR��v�z��OIF�o�^�y�{�̍s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- ������׃R���e�L�X�g
        interface_line_attribute1        , -- �������DFF1
        interface_line_attribute2        , -- �������DFF2
        account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
        amount                           , -- ���z(���׋��z)
        percent                          , -- �p�[�Z���g(����)
        segment1                         , -- ��ЃZ�O�����g
        segment2                         , -- ����Z�O�����g
        segment3                         , -- ����ȖڃZ�O�����g
        segment4                         , -- �⏕�ȖڃZ�O�����g
        segment5                         , -- �ڋq�Z�O�����g
        segment6                         , -- ��ƃZ�O�����g
        segment7                         , -- �\���P�Z�O�����g
        segment8                         , -- �\���Q�Z�O�����g
        attribute_category               , -- �d�󖾍׃J�e�S��
        created_by                       , -- �쐬��
        creation_date                    , -- �쐬��
        last_updated_by                  , -- �ŏI�X�V��
        last_update_date                 , -- �ŏI�X�V��
        last_update_login                , -- �ŏI�X�V���O�C��
        org_id                             -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
        lv_interface_line_attribute1     , -- �������DFF1(�`�[�ԍ�)
        cn_1                             , -- �������DFF2(���׍s�ԍ�)
        cv_rev                           , -- ����Ȗڋ敪(�z���^�C�v)
        in_tax_gap_amount                , -- ���z(���׋��z)
        cn_100                           , -- �p�[�Z���g(����)
        gv_aff1_company_code             , -- ��ЃZ�O�����g
        gv_aff2_dept_fin                 , -- ����Z�O�����g
        gv_aff3_receive_excise_tax       , -- ����ȖڃZ�O�����g
        gv_aff4_subacct_dummy            , -- �⏕�ȖڃZ�O�����g
        gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
        gv_aff6_company_dummy            , -- ��ƃZ�O�����g
        gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
        gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
        gn_org_id                        , -- ����DFF�J�e�S��
        cn_user_id                       , -- �쐬��
        SYSDATE                          , -- �쐬��
        cn_user_id                       , -- �ŏI�X�V��
        SYSDATE                          , -- �ŏI�X�V��
        cn_login_id                      , -- �ŏI�X�V���O�C��
        gn_org_id                          -- �c�ƒP��ID
      );
--
      -- ============================================================
      -- �ō��z��AR�������OIF�o�^�y�ŋ��s�z
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- ������׃R���e�L�X�g
        interface_line_attribute1                 , -- �������DFF1(�`�[�ԍ�)
        interface_line_attribute2                 , -- �������DFF2(���׍s�ԍ�)
        batch_source_name                         , -- ����\�[�X
        set_of_books_id                           , -- ��v����ID
        line_type                                 , -- ���׃^�C�v
        description                               , -- �i�ږ��דE�v
        currency_code                             , -- �ʉ݃R�[�h
        amount                                    , -- ���׋��z
        cust_trx_type_name                        , -- ����^�C�v
        term_name                                 , -- �x������
        orig_system_bill_customer_id              , -- ������ڋqID
        orig_system_bill_address_id               , -- ������ڋq���ݒn�Q��ID
        link_to_line_context                      , -- �����N���׃R���e�L�X�g
        link_to_line_attribute1                   , -- �����N����DFF1
        link_to_line_attribute2                   , -- �����N����DFF2
        conversion_type                           , -- ���Z�^�C�v
        conversion_rate                           , -- ���Z���[�g
        trx_date                                  , -- �����
        gl_date                                   , -- GL�L����
        trx_number                                , -- �`�[�ԍ�
        quantity                                  , -- ����
        unit_selling_price                        , -- �̔��P��
        tax_code                                  , -- �ŋ��R�[�h
        header_attribute_category                 , -- �w�b�_�[DFF�J�e�S��
        header_attribute5                         , -- �w�b�_�[DFF5(�N�[����)
        header_attribute6                         , -- �w�b�_�[DFF6(�`�[���͎�)
        header_attribute7                         , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        header_attribute8                         , -- �w�b�_�[DFF8(�ʐ��������)
        header_attribute9                         , -- �w�b�_�[DFF9(�ꊇ���������)
        header_attribute11                        , -- �w�b�_�[DFF11(�������_)
        header_attribute14                        , -- �w�b�_�[DFF14(�`�[�ԍ�)
        header_attribute15                        , -- �w�b�_�[DFF15(GL�L����)
        created_by                                , -- �쐬��
        creation_date                             , -- �쐬��
        last_updated_by                           , -- �ŏI�X�V��
        last_update_date                          , -- �ŏI�X�V��
        last_update_login                         , -- �ŏI�X�V���O�C��
        org_id                                      -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- ������׃R���e�L�X�g
        lv_interface_line_attribute1              , -- �������DFF1(�`�[�ԍ�)
        cn_2                                      , -- �������DFF2(���׍s�ԍ�)
        gv_ra_trx_type_tax                        , -- ����\�[�X
        in_set_of_books_id                        , -- ��v����ID
        cv_tax                                    , -- ���׃^�C�v
        gv_description                            , -- �i�ږ��דE�v
        cv_currency_code                          , -- �ʉ݃R�[�h
        cn_0                                      , -- ���׋��z
        gv_ra_trx_type_tax                        , -- ����^�C�v
        iv_term_name                              , -- �x������
        in_bill_cust_account_id                   , -- ������ڋqID
        in_bill_cust_acct_site_id                 , -- ������ڋq���ݒn�Q��ID
        gv_ra_trx_type_tax                        , -- �����N���׃R���e�L�X�g
        lv_interface_line_attribute1              , -- �����N����DFF1
        cn_1                                      , -- �����N����DFF2
        cv_user                                   , -- ���Z�^�C�v
        cn_1                                      , -- ���Z���[�g
        id_cutoff_date                            , -- �����
        NULL                                      , -- GL�L����
        lv_interface_line_attribute1              , -- �`�[�ԍ�
        NULL                                      , -- ����
        NULL                                      , -- �̔��P��
        gv_other_tax_code                         , -- �ŋ��R�[�h
        gn_org_id                                 , -- �w�b�_�[DFF�J�e�S��
        gv_header_attribute5                      , -- �w�b�_�[DFF5(�N�[����)
        gv_header_attribute6                      , -- �w�b�_�[DFF6(�`�[���͎�)
        cv_hold                                   , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        cv_waiting                                , -- �w�b�_�[DFF8(�ʐ��������)
        cv_waiting                                , -- �w�b�_�[DFF9(�ꊇ���������)
        iv_receipt_location_code                  , -- �w�b�_�[DFF11(�������_)
        in_invoice_id                             , -- �w�b�_�[DFF14(�`�[�ԍ�)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- �w�b�_�[DFF15(GL�L����)
        cn_user_id                                , -- �쐬��
        SYSDATE                                   , -- �쐬��
        cn_user_id                                , -- �ŏI�X�V��
        SYSDATE                                   , -- �ŏI�X�V��
        cn_login_id                               , -- �ŏI�X�V���O�C��
        gn_org_id                                   -- �c�ƒP��ID
        );
--
      -- ============================================================
      -- �ō��z��AR��v�z��OIF�o�^�y�ŋ��s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- ������׃R���e�L�X�g
        interface_line_attribute1        , -- �������DFF1
        interface_line_attribute2        , -- �������DFF2
        account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
        amount                           , -- ���z(���׋��z)
        percent                          , -- �p�[�Z���g(����)
        segment1                         , -- ��ЃZ�O�����g
        segment2                         , -- ����Z�O�����g
        segment3                         , -- ����ȖڃZ�O�����g
        segment4                         , -- �⏕�ȖڃZ�O�����g
        segment5                         , -- �ڋq�Z�O�����g
        segment6                         , -- ��ƃZ�O�����g
        segment7                         , -- �\���P�Z�O�����g
        segment8                         , -- �\���Q�Z�O�����g
        attribute_category               , -- �d�󖾍׃J�e�S��
        created_by                       , -- �쐬��
        creation_date                    , -- �쐬��
        last_updated_by                  , -- �ŏI�X�V��
        last_update_date                 , -- �ŏI�X�V��
        last_update_login                , -- �ŏI�X�V���O�C��
        org_id                             -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
        lv_interface_line_attribute1     , -- �������DFF1(�`�[�ԍ�)
        cn_2                             , -- �������DFF2(���׍s�ԍ�)
        cv_tax                           , -- ����Ȗڋ敪(�z���^�C�v)
        cn_0                             , -- ���z(���׋��z)
        cn_100                           , -- �p�[�Z���g(����)
        gv_aff1_company_code             , -- ��ЃZ�O�����g
        gv_aff2_dept_fin                 , -- ����Z�O�����g
        gv_aff3_receive_excise_tax       , -- ����ȖڃZ�O�����g
        gv_aff4_subacct_dummy            , -- �⏕�ȖڃZ�O�����g
        gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
        gv_aff6_company_dummy            , -- ��ƃZ�O�����g
        gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
        gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
        gn_org_id                        , -- ����DFF�J�e�S��
        cn_user_id                       , -- �쐬��
        SYSDATE                          , -- �쐬��
        cn_user_id                       , -- �ŏI�X�V��
        SYSDATE                          , -- �ŏI�X�V��
        cn_login_id                      , -- �ŏI�X�V���O�C��
        gn_org_id                          -- �c�ƒP��ID
      );
--
      -- ============================================================
      -- �ō��z��AR��v�z��OIF�o�^�y���s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
          interface_line_context           , -- ������׃R���e�L�X�g
          interface_line_attribute1        , -- �������DFF1
          interface_line_attribute2        , -- �������DFF2
          account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
          amount                           , -- ���z(���׋��z)
          percent                          , -- �p�[�Z���g(����)
          segment1                         , -- ��ЃZ�O�����g
          segment2                         , -- ����Z�O�����g
          segment3                         , -- ����ȖڃZ�O�����g
          segment4                         , -- �⏕�ȖڃZ�O�����g
          segment5                         , -- �ڋq�Z�O�����g
          segment6                         , -- ��ƃZ�O�����g
          segment7                         , -- �\���P�Z�O�����g
          segment8                         , -- �\���Q�Z�O�����g
          attribute_category               , -- �d�󖾍׃J�e�S��
          created_by                       , -- �쐬��
          creation_date                    , -- �쐬��
          last_updated_by                  , -- �ŏI�X�V��
          last_update_date                 , -- �ŏI�X�V��
          last_update_login                , -- �ŏI�X�V���O�C��
          org_id                             -- �c�ƒP��ID
          )
        VALUES(
          gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
          lv_interface_line_attribute1     , -- �������DFF1(�`�[�ԍ�)
          cn_1                             , -- �������DFF2(���׍s�ԍ�)
          cv_rec                           , -- ����Ȗڋ敪(�z���^�C�v)
          NULL                             , -- ���z(���׋��z)
          cn_100                           , -- �p�[�Z���g(����)
          gv_aff1_company_code             , -- ��ЃZ�O�����g
          gv_aff2_dept_fin                 , -- ����Z�O�����g
          gv_aff3_account_receivable       , -- ����ȖڃZ�O�����g
          gv_aff4_subacct_dummy            , -- �⏕�ȖڃZ�O�����g
          gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
          gv_aff6_company_dummy            , -- ��ƃZ�O�����g
          gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
          gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
          gn_org_id                        , -- ����DFF�J�e�S��
          cn_user_id                       , -- �쐬��
          SYSDATE                          , -- �쐬��
          cn_user_id                       , -- �ŏI�X�V��
          SYSDATE                          , -- �ŏI�X�V��
          cn_login_id                      , -- �ŏI�X�V���O�C��
          gn_org_id                          -- �c�ƒP��ID
        );
    END IF;
--
--
    -- �{�̍��z���������Ă���ꍇAROIF���쐬
    IF ( NVL(in_inv_gap_amount,0) <> 0 ) THEN
      -- ============================================================
      -- �`�[�ԍ��擾
      -- ============================================================
      SELECT  cv_ne || TO_CHAR(id_cutoff_date, cv_yyyymmdd) || LPAD(xxcfr_slip_number_ne_s01.NEXTVAL, 8, 0)
      INTO    lv_interface_line_atr1_inv
      FROM    dual;
--
      -- ============================================================
      -- �{�̍��z��AR�������OIF�o�^�y�{�̍s�z
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- ������׃R���e�L�X�g
        interface_line_attribute1                 , -- �������DFF1(�`�[�ԍ�)
        interface_line_attribute2                 , -- �������DFF2(���׍s�ԍ�)
        batch_source_name                         , -- ����\�[�X
        set_of_books_id                           , -- ��v����ID
        line_type                                 , -- ���׃^�C�v
        description                               , -- �i�ږ��דE�v
        currency_code                             , -- �ʉ݃R�[�h
        amount                                    , -- ���׋��z
        cust_trx_type_name                        , -- ����^�C�v
        term_name                                 , -- �x������
        orig_system_bill_customer_id              , -- ������ڋqID
        orig_system_bill_address_id               , -- ������ڋq���ݒn�Q��ID
        link_to_line_context                      , -- �����N���׃R���e�L�X�g
        link_to_line_attribute1                   , -- �����N����DFF1
        link_to_line_attribute2                   , -- �����N����DFF2
        conversion_type                           , -- ���Z�^�C�v
        conversion_rate                           , -- ���Z���[�g
        trx_date                                  , -- �����
        gl_date                                   , -- GL�L����
        trx_number                                , -- �`�[�ԍ�
        quantity                                  , -- ����
        unit_selling_price                        , -- �̔��P��
        tax_code                                  , -- �ŋ��R�[�h
        header_attribute_category                 , -- �w�b�_�[DFF�J�e�S��
        header_attribute5                         , -- �w�b�_�[DFF5(�N�[����)
        header_attribute6                         , -- �w�b�_�[DFF6(�`�[���͎�)
        header_attribute7                         , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        header_attribute8                         , -- �w�b�_�[DFF8(�ʐ��������)
        header_attribute9                         , -- �w�b�_�[DFF9(�ꊇ���������)
        header_attribute11                        , -- �w�b�_�[DFF11(�������_)
        header_attribute14                        , -- �w�b�_�[DFF14(�`�[�ԍ�)
        header_attribute15                        , -- �w�b�_�[DFF15(GL�L����)
        created_by                                , -- �쐬��
        creation_date                             , -- �쐬��
        last_updated_by                           , -- �ŏI�X�V��
        last_update_date                          , -- �ŏI�X�V��
        last_update_login                         , -- �ŏI�X�V���O�C��
        org_id                                      -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- ������׃R���e�L�X�g
        lv_interface_line_atr1_inv                , -- �������DFF1(�`�[�ԍ�)
        cn_1                                      , -- �������DFF2(���׍s�ԍ�)
        gv_ra_trx_type_tax                        , -- ����\�[�X
        in_set_of_books_id                        , -- ��v����ID
        cv_line                                   , -- ���׃^�C�v
        gv_description_inv                        , -- �i�ږ��דE�v
        cv_currency_code                          , -- �ʉ݃R�[�h
        in_inv_gap_amount                         , -- ���׋��z
        gv_ra_trx_type_tax                        , -- ����^�C�v
        iv_term_name                              , -- �x������
        in_bill_cust_account_id                   , -- ������ڋqID
        in_bill_cust_acct_site_id                 , -- ������ڋq���ݒn�Q��ID
        NULL                                      , -- �����N���׃R���e�L�X�g
        NULL                                      , -- �����N����DFF1
        NULL                                      , -- �����N����DFF2
        cv_user                                   , -- ���Z�^�C�v
        cn_1                                      , -- ���Z���[�g
        id_cutoff_date                            , -- �����
        id_cutoff_date                            , -- GL�L����
        lv_interface_line_atr1_inv                , -- �`�[�ԍ�
        cn_1                                      , -- ����
        in_inv_gap_amount                         , -- �̔��P��
        gv_other_tax_code                         , -- �ŋ��R�[�h
        gn_org_id                                 , -- �w�b�_�[DFF�J�e�S��
        gv_header_attribute5_inv                  , -- �w�b�_�[DFF5(�N�[����)
        gv_header_attribute6_inv                  , -- �w�b�_�[DFF6(�`�[���͎�)
        cv_hold                                   , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        cv_waiting                                , -- �w�b�_�[DFF8(�ʐ��������)
        cv_waiting                                , -- �w�b�_�[DFF9(�ꊇ���������)
        iv_receipt_location_code                  , -- �w�b�_�[DFF11(�������_)
        in_invoice_id                             , -- �w�b�_�[DFF14(�`�[�ԍ�)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- �w�b�_�[DFF15(GL�L����)
        cn_user_id                                , -- �쐬��
        SYSDATE                                   , -- �쐬��
        cn_user_id                                , -- �ŏI�X�V��
        SYSDATE                                   , -- �ŏI�X�V��
        cn_login_id                               , -- �ŏI�X�V���O�C��
        gn_org_id                                   -- �c�ƒP��ID
        );
--
      -- ============================================================
      -- �{�̍��z��AR��v�z��OIF�o�^�y�{�̍s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- ������׃R���e�L�X�g
        interface_line_attribute1        , -- �������DFF1
        interface_line_attribute2        , -- �������DFF2
        account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
        amount                           , -- ���z(���׋��z)
        percent                          , -- �p�[�Z���g(����)
        segment1                         , -- ��ЃZ�O�����g
        segment2                         , -- ����Z�O�����g
        segment3                         , -- ����ȖڃZ�O�����g
        segment4                         , -- �⏕�ȖڃZ�O�����g
        segment5                         , -- �ڋq�Z�O�����g
        segment6                         , -- ��ƃZ�O�����g
        segment7                         , -- �\���P�Z�O�����g
        segment8                         , -- �\���Q�Z�O�����g
        attribute_category               , -- �d�󖾍׃J�e�S��
        created_by                       , -- �쐬��
        creation_date                    , -- �쐬��
        last_updated_by                  , -- �ŏI�X�V��
        last_update_date                 , -- �ŏI�X�V��
        last_update_login                , -- �ŏI�X�V���O�C��
        org_id                             -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
        lv_interface_line_atr1_inv       , -- �������DFF1(�`�[�ԍ�)
        cn_1                             , -- �������DFF2(���׍s�ԍ�)
        cv_rev                           , -- ����Ȗڋ敪(�z���^�C�v)
        in_inv_gap_amount                , -- ���z(���׋��z)
        cn_100                           , -- �p�[�Z���g(����)
        gv_aff1_company_code             , -- ��ЃZ�O�����g
        gv_header_attribute5_inv         , -- ����Z�O�����g
        gv_aff3_rev_inv                  , -- ����ȖڃZ�O�����g
        gv_aff4_rev_inv                  , -- �⏕�ȖڃZ�O�����g
        gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
        gv_aff6_company_dummy            , -- ��ƃZ�O�����g
        gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
        gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
        gn_org_id                        , -- ����DFF�J�e�S��
        cn_user_id                       , -- �쐬��
        SYSDATE                          , -- �쐬��
        cn_user_id                       , -- �ŏI�X�V��
        SYSDATE                          , -- �ŏI�X�V��
        cn_login_id                      , -- �ŏI�X�V���O�C��
        gn_org_id                          -- �c�ƒP��ID
      );
--
      -- ============================================================
      -- �{�̍��z��AR�������OIF�o�^�y�ŋ��s�z
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- ������׃R���e�L�X�g
        interface_line_attribute1                 , -- �������DFF1(�`�[�ԍ�)
        interface_line_attribute2                 , -- �������DFF2(���׍s�ԍ�)
        batch_source_name                         , -- ����\�[�X
        set_of_books_id                           , -- ��v����ID
        line_type                                 , -- ���׃^�C�v
        description                               , -- �i�ږ��דE�v
        currency_code                             , -- �ʉ݃R�[�h
        amount                                    , -- ���׋��z
        cust_trx_type_name                        , -- ����^�C�v
        term_name                                 , -- �x������
        orig_system_bill_customer_id              , -- ������ڋqID
        orig_system_bill_address_id               , -- ������ڋq���ݒn�Q��ID
        link_to_line_context                      , -- �����N���׃R���e�L�X�g
        link_to_line_attribute1                   , -- �����N����DFF1
        link_to_line_attribute2                   , -- �����N����DFF2
        conversion_type                           , -- ���Z�^�C�v
        conversion_rate                           , -- ���Z���[�g
        trx_date                                  , -- �����
        gl_date                                   , -- GL�L����
        trx_number                                , -- �`�[�ԍ�
        quantity                                  , -- ����
        unit_selling_price                        , -- �̔��P��
        tax_code                                  , -- �ŋ��R�[�h
        header_attribute_category                 , -- �w�b�_�[DFF�J�e�S��
        header_attribute5                         , -- �w�b�_�[DFF5(�N�[����)
        header_attribute6                         , -- �w�b�_�[DFF6(�`�[���͎�)
        header_attribute7                         , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        header_attribute8                         , -- �w�b�_�[DFF8(�ʐ��������)
        header_attribute9                         , -- �w�b�_�[DFF9(�ꊇ���������)
        header_attribute11                        , -- �w�b�_�[DFF11(�������_)
        header_attribute14                        , -- �w�b�_�[DFF14(�`�[�ԍ�)
        header_attribute15                        , -- �w�b�_�[DFF15(GL�L����)
        created_by                                , -- �쐬��
        creation_date                             , -- �쐬��
        last_updated_by                           , -- �ŏI�X�V��
        last_update_date                          , -- �ŏI�X�V��
        last_update_login                         , -- �ŏI�X�V���O�C��
        org_id                                      -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- ������׃R���e�L�X�g
        lv_interface_line_atr1_inv                , -- �������DFF1(�`�[�ԍ�)
        cn_2                                      , -- �������DFF2(���׍s�ԍ�)
        gv_ra_trx_type_tax                        , -- ����\�[�X
        in_set_of_books_id                        , -- ��v����ID
        cv_tax                                    , -- ���׃^�C�v
        gv_description_inv                        , -- �i�ږ��דE�v
        cv_currency_code                          , -- �ʉ݃R�[�h
        cn_0                                      , -- ���׋��z
        gv_ra_trx_type_tax                        , -- ����^�C�v
        iv_term_name                              , -- �x������
        in_bill_cust_account_id                   , -- ������ڋqID
        in_bill_cust_acct_site_id                 , -- ������ڋq���ݒn�Q��ID
        gv_ra_trx_type_tax                        , -- �����N���׃R���e�L�X�g
        lv_interface_line_atr1_inv                , -- �����N����DFF1
        cn_1                                      , -- �����N����DFF2
        cv_user                                   , -- ���Z�^�C�v
        cn_1                                      , -- ���Z���[�g
        id_cutoff_date                            , -- �����
        NULL                                      , -- GL�L����
        lv_interface_line_atr1_inv                , -- �`�[�ԍ�
        NULL                                      , -- ����
        NULL                                      , -- �̔��P��
        gv_other_tax_code                         , -- �ŋ��R�[�h
        gn_org_id                                 , -- �w�b�_�[DFF�J�e�S��
        gv_header_attribute5_inv                  , -- �w�b�_�[DFF5(�N�[����)
        gv_header_attribute6_inv                  , -- �w�b�_�[DFF6(�`�[���͎�)
        cv_hold                                   , -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
        cv_waiting                                , -- �w�b�_�[DFF8(�ʐ��������)
        cv_waiting                                , -- �w�b�_�[DFF9(�ꊇ���������)
        iv_receipt_location_code                  , -- �w�b�_�[DFF11(�������_)
        in_invoice_id                             , -- �w�b�_�[DFF14(�`�[�ԍ�)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- �w�b�_�[DFF15(GL�L����)
        cn_user_id                                , -- �쐬��
        SYSDATE                                   , -- �쐬��
        cn_user_id                                , -- �ŏI�X�V��
        SYSDATE                                   , -- �ŏI�X�V��
        cn_login_id                               , -- �ŏI�X�V���O�C��
        gn_org_id                                   -- �c�ƒP��ID
        );
--
      -- ============================================================
      -- �{�̍��z��AR��v�z��OIF�o�^�y�ŋ��s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- ������׃R���e�L�X�g
        interface_line_attribute1        , -- �������DFF1
        interface_line_attribute2        , -- �������DFF2
        account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
        amount                           , -- ���z(���׋��z)
        percent                          , -- �p�[�Z���g(����)
        segment1                         , -- ��ЃZ�O�����g
        segment2                         , -- ����Z�O�����g
        segment3                         , -- ����ȖڃZ�O�����g
        segment4                         , -- �⏕�ȖڃZ�O�����g
        segment5                         , -- �ڋq�Z�O�����g
        segment6                         , -- ��ƃZ�O�����g
        segment7                         , -- �\���P�Z�O�����g
        segment8                         , -- �\���Q�Z�O�����g
        attribute_category               , -- �d�󖾍׃J�e�S��
        created_by                       , -- �쐬��
        creation_date                    , -- �쐬��
        last_updated_by                  , -- �ŏI�X�V��
        last_update_date                 , -- �ŏI�X�V��
        last_update_login                , -- �ŏI�X�V���O�C��
        org_id                             -- �c�ƒP��ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
        lv_interface_line_atr1_inv       , -- �������DFF1(�`�[�ԍ�)
        cn_2                             , -- �������DFF2(���׍s�ԍ�)
        cv_tax                           , -- ����Ȗڋ敪(�z���^�C�v)
        cn_0                             , -- ���z(���׋��z)
        cn_100                           , -- �p�[�Z���g(����)
        gv_aff1_company_code             , -- ��ЃZ�O�����g
        gv_aff2_dept_fin                 , -- ����Z�O�����g
        gv_aff3_tax_inv                  , -- ����ȖڃZ�O�����g
        gv_aff4_tax_inv                  , -- �⏕�ȖڃZ�O�����g
        gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
        gv_aff6_company_dummy            , -- ��ƃZ�O�����g
        gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
        gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
        gn_org_id                        , -- ����DFF�J�e�S��
        cn_user_id                       , -- �쐬��
        SYSDATE                          , -- �쐬��
        cn_user_id                       , -- �ŏI�X�V��
        SYSDATE                          , -- �ŏI�X�V��
        cn_login_id                      , -- �ŏI�X�V���O�C��
        gn_org_id                          -- �c�ƒP��ID
      );
--
      -- ============================================================
      -- �{�̍��z��AR��v�z��OIF�o�^�y���s�z
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
          interface_line_context           , -- ������׃R���e�L�X�g
          interface_line_attribute1        , -- �������DFF1
          interface_line_attribute2        , -- �������DFF2
          account_class                    , -- ����Ȗڋ敪(�z���^�C�v)
          amount                           , -- ���z(���׋��z)
          percent                          , -- �p�[�Z���g(����)
          segment1                         , -- ��ЃZ�O�����g
          segment2                         , -- ����Z�O�����g
          segment3                         , -- ����ȖڃZ�O�����g
          segment4                         , -- �⏕�ȖڃZ�O�����g
          segment5                         , -- �ڋq�Z�O�����g
          segment6                         , -- ��ƃZ�O�����g
          segment7                         , -- �\���P�Z�O�����g
          segment8                         , -- �\���Q�Z�O�����g
          attribute_category               , -- �d�󖾍׃J�e�S��
          created_by                       , -- �쐬��
          creation_date                    , -- �쐬��
          last_updated_by                  , -- �ŏI�X�V��
          last_update_date                 , -- �ŏI�X�V��
          last_update_login                , -- �ŏI�X�V���O�C��
          org_id                             -- �c�ƒP��ID
          )
        VALUES(
          gv_ra_trx_type_tax               , -- ������׃R���e�L�X�g
          lv_interface_line_atr1_inv       , -- �������DFF1(�`�[�ԍ�)
          cn_1                             , -- �������DFF2(���׍s�ԍ�)
          cv_rec                           , -- ����Ȗڋ敪(�z���^�C�v)
          NULL                             , -- ���z(���׋��z)
          cn_100                           , -- �p�[�Z���g(����)
          gv_aff1_company_code             , -- ��ЃZ�O�����g
          gv_aff2_dept_fin                 , -- ����Z�O�����g
          gv_aff3_rec_inv                  , -- ����ȖڃZ�O�����g
          gv_aff4_rec_inv                  , -- �⏕�ȖڃZ�O�����g
          gv_aff5_customer_dummy           , -- �ڋq�Z�O�����g
          gv_aff6_company_dummy            , -- ��ƃZ�O�����g
          gv_aff7_preliminary1_dummy       , -- �\���P�Z�O�����g
          gv_aff8_preliminary2_dummy       , -- �\���Q�Z�O�����g
          gn_org_id                        , -- ����DFF�J�e�S��
          cn_user_id                       , -- �쐬��
          SYSDATE                          , -- �쐬��
          cn_user_id                       , -- �ŏI�X�V��
          SYSDATE                          , -- �ŏI�X�V��
          cn_login_id                      , -- �ŏI�X�V���O�C��
          gn_org_id                          -- �c�ƒP��ID
        );
    END IF;
--
    -- �o�^�����J�E���g
    gn_normal_cnt :=  gn_normal_cnt + 1;
--
    -- ============================================================
    -- �����w�b�_���X�V(A-4)
    -- ============================================================
    UPDATE  xxcfr_invoice_headers xih
    SET     xih.tax_diff_amount_create_flg = cv_created        , -- �쐬��
            xih.last_updated_by            = cn_user_id        , -- �ŏI�X�V��
            xih.last_update_date           = SYSDATE           , -- �ŏI�X�V��
            xih.last_update_login          = cn_login_id       , -- �ŏI�X�V���O�C��
            xih.request_id                 = cn_conc_request_id, -- �v��ID
            xih.program_application_id     = cn_prog_appl_id   , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            xih.program_id                 = cn_conc_program_id, -- �R���J�����g�E�v���O����ID
            xih.program_update_date        = SYSDATE             -- �v���O�����X�V��
    WHERE   xih.invoice_id  = in_invoice_id;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END transfer_to_ar_p;
--
  /**********************************************************************************
   * Procedure Name   : get_invoice_p
   * Description      : �����w�b�_��񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_invoice_p(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_invoice_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ==============================
    -- ���[�J���J�[�\��
    -- ==============================
    -- AR�A�W�Ώې����f�[�^
    CURSOR l_target_inv_cur
    IS
      SELECT  xih.invoice_id                 AS invoice_id                    -- �ꊇ������ID
             ,xih.set_of_books_id            AS set_of_books_id               -- ��v����ID
-- Mod Ver1.1 Start
             ,xih.inv_gap_amount  - NVL(xih.inv_gap_amount_sent, 0)
                                             AS inv_gap_amount                -- �{�̍��z
             ,xih.tax_gap_amount  - NVL(xih.tax_gap_amount_sent, 0)
                                             AS tax_gap_amount                -- �ō��z
--             ,xih.inv_gap_amount             AS inv_gap_amount                -- �{�̍��z
--             ,xih.tax_gap_amount             AS tax_gap_amount                -- �ō��z
-- Mod Ver1.1 End
             ,xih.term_name                  AS term_name                     -- �x������
             ,xih.bill_cust_account_id       AS bill_cust_account_id          -- ������ڋqID
             ,xih.bill_cust_acct_site_id     AS bill_cust_acct_site_id        -- ������ڋq���ݒnID
             ,xih.cutoff_date                AS cutoff_date                   -- ����
             ,xih.receipt_location_code      AS receipt_location_code         -- �������_�R�[�h
      FROM    xxcfr_invoice_headers xih
      WHERE   xih.tax_diff_amount_create_flg = cv_not_created                 -- ���쐬
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �����w�b�_��񒊏o
    -- ============================================================
    FOR l_target_inv_rec IN  l_target_inv_cur LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ============================================================
      -- AR�A�W����(A-3)�̌Ăяo��
      -- ============================================================
      transfer_to_ar_p(
        ov_errbuf                   =>  lv_errbuf                                   -- �G���[�E���b�Z�[�W
      , ov_retcode                  =>  lv_retcode                                  -- ���^�[���E�R�[�h
      , ov_errmsg                   =>  lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_invoice_id               =>  l_target_inv_rec.invoice_id                 -- �ꊇ������ID
      , in_set_of_books_id          =>  l_target_inv_rec.set_of_books_id            -- ��v����ID
      , in_inv_gap_amount           =>  l_target_inv_rec.inv_gap_amount             -- �{�̍��z
      , in_tax_gap_amount           =>  l_target_inv_rec.tax_gap_amount             -- �ō��z
      , iv_term_name                =>  l_target_inv_rec.term_name                  -- �x������
      , in_bill_cust_account_id     =>  l_target_inv_rec.bill_cust_account_id       -- ������ڋqID
      , in_bill_cust_acct_site_id   =>  l_target_inv_rec.bill_cust_acct_site_id     -- ������ڋq���ݒnID
      , id_cutoff_date              =>  l_target_inv_rec.cutoff_date                -- ����
      , iv_receipt_location_code    =>  l_target_inv_rec.receipt_location_code      -- �������_�R�[�h
      );
--
      IF ( lv_retcode  = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    WHEN global_data_lock_expt THEN
      -- ���b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcfr_name
                    ,iv_name         => cv_msg_cfr_00003     -- ���b�N�G���[
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_table_name
                   );
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_invoice_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �O���[�o���ϐ��̏�����
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- ��������(A-1)�̌Ăяo��
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      gn_error_cnt  :=  1;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �����w�b�_��񒊏o(A-2)�̌Ăяo��
    -- ============================================================
    get_invoice_p(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode  = cv_status_error ) THEN
      gn_error_cnt  :=  1;
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                    -- ���^�[���E�R�[�h
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- ���b�Z�[�W�R�[�h
--
    lv_errbuf2      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
      ,ov_retcode => lv_retcode
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
    -- ============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_cfr_00056
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCFR003A23C;
/
