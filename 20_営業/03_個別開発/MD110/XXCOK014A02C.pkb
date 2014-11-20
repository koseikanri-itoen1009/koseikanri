CREATE OR REPLACE PACKAGE BODY XXCOK014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A02C(body)
 * Description      : �̔��萔���i���̋@�j�̌v�Z���ʂ����n�V�X�e����
 *                    �A�g����C���^�[�t�F�[�X�t�@�C�����쐬���܂�
 * MD.050           : ���n�V�X�e��IF�t�@�C���쐬-�����ʔ̎�̋�  MD050_COK_014_A02
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1),
 *                         �t�@�C���I�[�v��(A-2)
 *  get_cust_info          �ڋq���擾����(A-3)
 *  get_bm_support_info    �����ʔ̎�̋����擾����(A-4)
 *  storage_plsql_tab      PL/SQL�\�i�[����(A-5)
 *  output_csv_file        �t�@�C���o�͏���(A-6)
 *  upd_cond_bm_support    �����ʔ̎�̋��e�[�u���X�V����(A-7)
 *  submain                ���C�������v���V�[�W��,
 *                         �t�@�C���N���[�Y(A-8)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/19    1.0   T.Abe            �V�K�쐬
 *  2009/02/06    1.1   T.Abe            [��QCOK_012] �f�B���N�g���p�X�̏o�͂��C��
 *  2009/02/16    1.2   T.Abe            [��QCOK_035] �萔 �t���T�[�r�XVD�̕ύX
 *  2009/02/19    1.3   K.Yamaguchi      [��QCOK_048] �ŐV�̎d����T�C�g�����擾����悤�ύX
 *                                                     �d����T�C�g�̒��o�����ɉc�ƒP��ID��ǉ�
 *                                                     ���̓p�����[�^�u�x�����v�̏�����ύX
 *  2009/02/25    1.4   T.Abe            [��QCOK_056] �Ɩ��������t�|�Q���c�Ɠ����擾���鏈����ǉ�
 *                                                     ���ʊ֐� ���ߓ��擾�����ɋƖ��������t�|�Q�c�Ɠ���n���悤�C��
 *                                                     �Ɩ��������t���擾�����c�Ɠ��̏ꍇ�ɏ����ʔ̎�̋�����
 *                                                     �擾����悤�C��
 *
 *****************************************************************************************/
--
  --==========================
  -- �O���[�o���萔
  --==========================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOK014A02C';                     -- �p�b�P�[�W��
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  --�ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                 --CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                 --LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;         --PROGRAM_ID
  -- �L��
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';                              -- �R����
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';                                -- �h�b�g
  -- �A�v���P�[�V������
  cv_appli_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';                            -- �A�v���P�[�V�������FXXCOK
  cv_appli_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';                            -- �A�v���P�[�V�������FXXCCP
  -- ���b�Z�[�W
  cv_msg_cok_00022           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00022';                 -- �R���J�����g���̓p�����[�^
  cv_msg_cok_10342           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10342';                 -- �Ɩ����t�̌`���Ⴂ�G���[
  cv_msg_cok_00028           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00028';                 -- �Ɩ����t�擾�G���[
  cv_msg_cok_00009           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00009';                 -- �t�@�C�����݃`�F�b�N�G���[
  cv_msg_cok_00051           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00051';                 -- ���b�N�擾�G���[
  cv_msg_cok_00003           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_msg_cok_10203           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10203';                 -- �c�Ɠ��擾�G���[
  cv_msg_cok_10369           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10369';                 -- ���ߓ��擾�G���[
  cv_msg_cok_00067           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00067';                 -- �f�B���N�g��
  cv_msg_cok_00006           CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-00006';                 -- �t�@�C����
  cv_msg_ccp_90000           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000';                 -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90001';                 -- �����������b�Z�[�W
  cv_msg_ccp_90002           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002';                 -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_msg_ccp_90006           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006';                 -- �G���[�I���S���[���o�b�N���b�Z�[�W
  -- �v���t�@�C��
  cv_prof_org_id             CONSTANT VARCHAR2(50)  := 'ORG_ID';                           -- �c�ƒP��ID
  cv_prof_aff1_company_code  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';         -- ��ЃR�[�h
  cv_prof_bs_period_to       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- �̎�̋��v�Z�������ԁiTo�j
  cv_prof_bs_dire_path       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_DIRE_PATH';      -- �����ʔ̎�̋��f�B���N�g���I�u�W�F�N�g
  cv_prof_bs_file_name       CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_SUPPORT_FILE_NAME';      -- �����ʔ̎�̋��t�@�C����
  cv_prof_uom_code_hon       CONSTANT VARCHAR2(50)  := 'XXCOK1_UOM_CODE_HON';              -- �P�ʃR�[�h(�{)
  -- �g�[�N��
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';                            -- ��������
  cv_token_business_date     CONSTANT VARCHAR2(30)  := 'BUSINESS_DATE';                    -- �Ɩ����t
  cv_token_profile           CONSTANT VARCHAR2(7)   := 'PROFILE';                          -- �v���t�@�C����
  cv_token_directory         CONSTANT VARCHAR2(9)   := 'DIRECTORY';                        -- �f�B���N�g��
  cv_token_file_name         CONSTANT VARCHAR2(9)   := 'FILE_NAME';                        -- �t�@�C����
  cv_token_close_date        CONSTANT VARCHAR2(10)  := 'CLOSE_DATE';                       -- ���ߓ�
  cv_token_term_code         CONSTANT VARCHAR2(10)  := 'TERM_CODE';                        -- �x������
  -- �t���O
  cv_flag_no                 CONSTANT VARCHAR2(1)   := 'N';                                -- �t���O'N'
  -- �Q�ƃ^�C�v
  cv_bm_calc_type            CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_CALC_TYPE';              -- �Q�ƃ^�C�v
  -- ���l
  cv_fullservice_vd          CONSTANT VARCHAR2(2)   := '25';                               -- �t���T�[�r�XVD
  cv_customer                CONSTANT VARCHAR2(2)   := '10';                               -- �ڋq
  cv_0                       CONSTANT VARCHAR2(1)   := '0';                                -- ����'0'
  cv_1                       CONSTANT VARCHAR2(1)   := '1';                                -- ����'1'
  cv_2                       CONSTANT VARCHAR2(1)   := '2';                                -- ����'2'
  cn_1                       CONSTANT NUMBER        := 1;                                  -- ���l 1
  cn_2                       CONSTANT NUMBER        := 2;                                  -- ���l 2
  cn_minus_2                 CONSTANT NUMBER        := -2;                                 -- ���l -2
--
  --==========================
  -- �O���[�o���ϐ�
  --==========================
  gv_out_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt             NUMBER         DEFAULT NULL;                            -- �Ώی���
  gn_normal_cnt             NUMBER         DEFAULT NULL;                            -- ���팏��
  gn_error_cnt              NUMBER         DEFAULT NULL;                            -- �G���[����
  gn_warn_cnt               NUMBER         DEFAULT NULL;                            -- �X�L�b�v����
  -- �v���t�@�C��
  gt_prof_aff1_company_code fnd_profile_option_values.profile_option_value%TYPE;    -- ��ЃR�[�h
  gt_prof_bs_period_to      fnd_profile_option_values.profile_option_value%TYPE;    -- �̎�̋��v�Z�������ԁiTo�j
  gt_prof_bs_dire_path      fnd_profile_option_values.profile_option_value%TYPE;    -- �����ʔ̎�̋��f�B���N�g���I�u�W�F�N�g
  gt_prof_bs_file_name      fnd_profile_option_values.profile_option_value%TYPE;    -- �����ʔ̎�̋��t�@�C����
  gt_prof_uom_code_hon      fnd_profile_option_values.profile_option_value%TYPE;    -- �P�ʃR�[�h(�{)
  -- �ϐ�
  gv_bs_dire_path           VARCHAR2(1000) DEFAULT NULL;                            -- �����ʔ̎�̋��f�B���N�g���p�X
  gd_sysdate                DATE           DEFAULT NULL;                            -- �V�X�e�����t
  gd_business_date          DATE           DEFAULT NULL;                            -- �Ɩ����t
  gu_open_file_handle       UTL_FILE.FILE_TYPE;                                     -- �I�[�v���t�@�C���n���h��
  gn_org_id                 NUMBER         DEFAULT NULL;
  --==========================
  -- �O���[�o���E���R�[�h
  --==========================
  TYPE bm_support_csv_rtype IS RECORD(
    sequence_number          NUMBER             -- �V�[�P���X�ԍ�
   ,company_code             VARCHAR2(3)        -- ��ЃR�[�h
   ,base_code                VARCHAR2(4)        -- ���_(����) �R�[�h
   ,emp_code                 VARCHAR2(5)        -- �S���҃R�[�h
   ,cust_code                VARCHAR2(9)        -- �ڋq�R�[�h
   ,acctg_year               VARCHAR2(4)        -- ��v�N�x
   ,chain_store_code         VARCHAR2(9)        -- �`�F�[���X�R�[�h
   ,supplier_code            VARCHAR2(9)        -- �d����R�[�h
   ,supplier_site_code       VARCHAR2(10)       -- �x����T�C�g�R�[�h
   ,delivery_date            NUMBER             -- �[�i���N��
   ,delivery_qty             NUMBER             -- �[�i����
   ,delivery_unit_type       VARCHAR2(2)        -- �[�i�P��(�{/�P�[�X)
   ,selling_amt_tax          NUMBER             -- ������z(�ō�)
   ,account_type             VARCHAR2(20)       -- �������
   ,rebate_rate              NUMBER             -- ���ߗ�
   ,rebate_amt               NUMBER             -- ���ߊz
   ,container_type_code      VARCHAR2(4)        -- �e��敪�R�[�h
   ,selling_price            NUMBER             -- �������z
   ,cond_bm_amt_tax          NUMBER             -- �����ʎ萔���z(�ō�)
   ,cond_bm_amt_no_tax       NUMBER             -- �����ʎ萔���z(�Ŕ�)
   ,cond_tax_amt             NUMBER             -- �����ʏ���Ŋz
   ,electric_amt             NUMBER             -- �d�C��
   ,closing_date             DATE               -- ����
   ,expect_payment_date      DATE               -- �x����
   ,calc_target_period_from  DATE               -- �v�Z�Ώۊ���(From)
   ,calc_target_period_to    DATE               -- �v�Z�Ώۊ���(To)
   ,ref_base_code            VARCHAR2(4)        -- �⍇�킹�S�����_�R�[�h
   ,interface_date           DATE               -- �A�g����
  );
  --===========================
  -- �O���[�o���E�J�[�\��
  --===========================
  -- A-3.�ڋq���擾
  CURSOR cust_info_cur
  IS
  SELECT xcm.install_account_number  AS  install_account_number                      -- �ݒu��ڋq�R�[�h
        ,xcm.close_day_code          AS  close_day_code                              -- ���ߓ�
        ,xcm.transfer_day_code       AS  transfer_day_code                           -- �x����
  FROM   xxcso_contract_managements  xcm                                             -- �_��Ǘ�
        ,(
            SELECT MAX( TO_NUMBER( xcm.contract_number ) )  AS  contract_number      -- �_�񏑔ԍ�
                  ,xcm.install_account_id                   AS  install_account_id   -- �ݒu��ڋqID
            FROM   xxcso_contract_managements  xcm                                   -- �_��Ǘ�
                  ,hz_cust_accounts            hca                                   -- �ڋq�}�X�^
                  ,xxcmm_cust_accounts         xca                                   -- �ڋq�ǉ��A�h�I��
            WHERE  hca.cust_account_id     = xcm.install_account_id
            AND    hca.cust_account_id     = xca.customer_id
            AND    xca.business_low_type   = cv_fullservice_vd
            AND    hca.customer_class_code = cv_customer
            AND    xcm.status              = cv_1
            GROUP BY xcm.install_account_id
         )                           xcm_v                                           -- �C�����C���r���[
  WHERE  xcm.contract_number    = xcm_v.contract_number
  AND    xcm.install_account_id = xcm_v.install_account_id
  AND    xcm.status             = cv_1;
  cust_info_rec    cust_info_cur%ROWTYPE;
  --==================================
  -- �O���[�o��TABLE�^
  --==================================
  -- �ڋq���
  TYPE cust_info_ttpye IS TABLE OF cust_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  gt_cust_info_tab    cust_info_ttpye;
  --==================================
  -- �O���[�o���E�J�[�\��
  --==================================
  --�����ʔ̎�̋����
  CURSOR bm_support_cur(
           in_ci_cnt IN NUMBER
  )
  IS
  SELECT  xcbs.cond_bm_support_id       AS cond_bm_support_id         -- �����ʔ̎�̋�ID
         ,xcbs.base_code                AS base_code                  -- ���_�R�[�h
         ,xcbs.emp_code                 AS emp_code                   -- �S���҃R�[�h
         ,xcbs.delivery_cust_code       AS delivery_cust_code         -- �ڋq�y�[�i��z
         ,xcbs.acctg_year               AS acctg_year                 -- ��v�N�x
         ,xcbs.chain_store_code         AS chain_store_code           -- �`�F�[���X�R�[�h
         ,xcbs.supplier_code            AS supplier_code              -- �d����R�[�h
         ,pvsa.vendor_site_code         AS supplier_site_code         -- �d����T�C�g�R�[�h
         ,xcbs.delivery_date            AS delivery_date              -- �[�i���N��
         ,xcbs.delivery_qty             AS delivery_qty               -- �[�i����
         ,xcbs.delivery_unit_type       AS delivery_unit_type         -- �[�i�P��
         ,xcbs.selling_amt_tax          AS selling_amt_tax            -- ������z�i�ō��j
         ,xlv_v.meaning                 AS calc_type                  -- �v�Z����
         ,xcbs.rebate_rate              AS rebate_rate                -- ���ߗ�
         ,xcbs.rebate_amt               AS rebate_amt                 -- ���ߊz
         ,xcbs.container_type_code      AS container_type_code        -- �e��敪�R�[�h
         ,xcbs.selling_price            AS selling_price              -- �������z
         ,xcbs.cond_bm_amt_tax          AS cond_bm_amt_tax            -- �����ʎ萔���z�i�ō��j
         ,xcbs.cond_bm_amt_no_tax       AS cond_bm_amt_no_tax         -- �����ʎ萔���z�i�Ŕ��j
         ,xcbs.cond_tax_amt             AS cond_tax_amt               -- �����ʏ���Ŋz
         ,xcbs.electric_amt_tax         AS electric_amt_tax           -- �d�C���i�ō��j
         ,xcbs.closing_date             AS closing_date               -- ���ߓ�
         ,xcbs.expect_payment_date      AS expect_payment_date        -- �x���\���
         ,xcbs.calc_target_period_from  AS calc_target_period_from    -- �v�Z�Ώۊ��ԁiFrom�j
         ,xcbs.calc_target_period_to    AS calc_target_period_to      -- �v�Z�Ώۊ��ԁiTo�j
         ,pvsa.attribute5               AS ref_base_code              -- �⍇���S�����_�R�[�h
  FROM    xxcok_cond_bm_support         xcbs                          -- �����ʔ̎�̋��e�[�u��
         ,xxcok_backmargin_balance      xbb                           -- �̎�c���e�[�u��
         ,po_vendors                    pv                            -- �d����}�X�^
         ,po_vendor_sites_all           pvsa                          -- �d����T�C�g�}�X�^
         ,xxcmn_lookup_values_v         xlv_v                         -- �N�C�b�N�R�[�h
  WHERE xcbs.base_code                  = xbb.base_code
  AND   xcbs.supplier_code              = xbb.supplier_code
  AND   xcbs.closing_date               = xbb.closing_date
  AND   xcbs.expect_payment_date        = xbb.expect_payment_date
  AND   xcbs.supplier_code              = pv.segment1
  AND   xcbs.cond_bm_interface_status   = cv_0
  AND   pv.vendor_id                    = pvsa.vendor_id
  AND   ( pvsa.inactive_date            > gd_business_date OR pvsa.inactive_date IS NULL )
  AND   pvsa.org_id                     = gn_org_id
  AND   xbb.resv_flag                   IS NULL
  AND   pvsa.hold_all_payments_flag     = cv_flag_no
  AND   xbb.cust_code                   = xcbs.delivery_cust_code
  AND   xbb.cust_code                   = gt_cust_info_tab( in_ci_cnt ).install_account_number
  AND   xlv_v.lookup_code               = xcbs.calc_type
  AND   xlv_v.lookup_type               = cv_bm_calc_type
  AND   pvsa.attribute4                 IN (cv_1, cv_2);
  bm_support_rec    bm_support_cur%ROWTYPE;
  -- �����ʔ̎�̋��e�[�u�����b�N���
  CURSOR lock_cond_bm_support_cur(
           in_cond_bm_support_id IN xxcok_cond_bm_support.cond_bm_support_id%TYPE      -- �����ʔ̎�̋�ID
  )
  IS
  SELECT xcbs.cond_bm_support_id  AS  cond_bm_support_id                               -- �����ʔ̎�̋�ID
  FROM   xxcok_cond_bm_support  xcbs                                                   -- �����ʔ̎�̋��e�[�u��
  WHERE  xcbs.cond_bm_support_id = in_cond_bm_support_id
  FOR UPDATE NOWAIT;
  --=================================
  -- �O���[�o���ETABLE�^
  --=================================
  -- �����ʔ̎�̋����
  TYPE bm_support_ttpye IS TABLE OF bm_support_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  gt_bm_support_tab    bm_support_ttpye;
  --=================================
  -- �O���[�o���EPL/SQL�\
  --=================================
  TYPE bm_support_csv_ttpye IS TABLE OF bm_support_csv_rtype
  INDEX BY BINARY_INTEGER;
  gt_bms_csv_tab  bm_support_csv_ttpye;
  --=================================
  -- ���ʗ�O
  --=================================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���ʃ��b�N�擾��O ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- �v���O�}
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   *                  : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT VARCHAR2           -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT VARCHAR2           -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_business_date IN  VARCHAR2           -- ���̓p�����[�^�E�Ɩ����t
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';      -- �v���O������
    cv_open_mode     CONSTANT VARCHAR2(1)   := 'w';         -- OPEN_MODE
    cn_max_linesize  CONSTANT NUMBER        := 32767;       -- MAX_LINESIZE
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;           -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;           -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;           -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode       BOOLEAN        DEFAULT NULL;           -- ���^�[���R�[�h
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;           -- �A�E�g���b�Z�[�W
    ld_business_date DATE           DEFAULT NULL;           -- ���̓p�����[�^�ϊ��`�F�b�N�p
    lv_err_profile   VARCHAR2(50)   DEFAULT NULL;           -- �擾�Ɏ��s�����v���t�@�C��
    lb_exists        BOOLEAN        DEFAULT NULL;           -- �t�@�C�����݃`�F�b�N
    ln_file_length   NUMBER         DEFAULT NULL;           -- �t�@�C���̒���
    ln_block_size    NUMBER         DEFAULT NULL;           -- �u���b�N�T�C�Y
    --===============================
    -- ���[�J����O
    --===============================
    --*** �^�ϊ���O ***
    date_prm_expt          EXCEPTION;
    --*** �v���t�@�C���擾��O ***
    no_prifile_expt        EXCEPTION;
    --*** �Ɩ����t�擾��O ***
    no_process_date_expt   EXCEPTION;
    --*** �t�@�C�����ݗ�O ***
    file_exists_expt       EXCEPTION;
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �R���J�����g�v���O�������͍��ڂ����b�Z�[�W�o�͂���
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00022
                    ,iv_token_name1  => cv_token_business_date
                    ,iv_token_value1 => iv_business_date
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT      -- �o�͋敪
                   ,iv_message  => lv_out_msg           -- ���b�Z�[�W
                   ,in_new_line => 1                    -- ���s
                  );
    BEGIN
      -- ���̓p�����[�^DATE�^�ϊ��`�F�b�N
      IF( iv_business_date IS NOT NULL ) THEN
        gd_business_date := TO_DATE( iv_business_date, 'FXRRRR/MM/DD' );
      ELSE
        -- �Ɩ����t�擾
        gd_business_date := xxccp_common_pkg2.get_process_date;
        -- �Ɩ����t�擾�G���[
        IF( gd_business_date IS NULL ) THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appli_xxcok
                         ,iv_name         => cv_msg_cok_00028
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                         ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                         ,in_new_line => 0                  -- ���s
                        );
          RAISE no_process_date_expt;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_xxcok
                       ,iv_name         => cv_msg_cok_10342
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     -- �o�͋敪
                       ,iv_message  => lv_out_msg          -- ���b�Z�[�W
                       ,in_new_line => 0                   -- ���s
                      );
      RAISE date_prm_expt;
    END;
    -- �V�X�e�����t���擾����
    gd_sysdate := SYSDATE;
    -- �c�ƒP��ID���擾����
    gn_org_id  := FND_PROFILE.VALUE( cv_prof_org_id );
    IF( gn_org_id IS NULL ) THEN
      lv_err_profile := cv_prof_org_id;
      RAISE no_prifile_expt;
    END IF;
    -- ��ЃR�[�h �v���t�@�C�����擾����
    gt_prof_aff1_company_code := FND_PROFILE.VALUE( cv_prof_aff1_company_code );
    IF( gt_prof_aff1_company_code IS NULL ) THEN
      lv_err_profile := cv_prof_aff1_company_code;
      RAISE no_prifile_expt;
    END IF;
    -- �̎�̋��v�Z�������ԁiTo�j�v���t�@�C�����擾����
    gt_prof_bs_period_to := FND_PROFILE.VALUE( cv_prof_bs_period_to );
    IF( gt_prof_bs_period_to IS NULL ) THEN
      lv_err_profile := cv_prof_bs_period_to;
      RAISE no_prifile_expt;
    END IF;
    -- �����ʔ̎�̋��f�B���N�g���I�u�W�F�N�g �v���t�@�C�����擾����
    gt_prof_bs_dire_path := FND_PROFILE.VALUE( cv_prof_bs_dire_path );
    IF( gt_prof_bs_dire_path IS NULL ) THEN
      lv_err_profile := cv_prof_bs_dire_path;
      RAISE no_prifile_expt;
    END IF;
    -- �����ʔ̎�̋��t�@�C���� �v���t�@�C�����擾����
    gt_prof_bs_file_name := FND_PROFILE.VALUE( cv_prof_bs_file_name );
    IF( gt_prof_bs_file_name IS NULL ) THEN
      lv_err_profile := cv_prof_bs_file_name;
      RAISE no_prifile_expt;
    END IF;
    -- �P�ʃR�[�h(�{) �v���t�@�C�����擾����
    gt_prof_uom_code_hon := FND_PROFILE.VALUE( cv_prof_uom_code_hon );
    IF( gt_prof_uom_code_hon IS NULL ) THEN
      lv_err_profile := cv_prof_uom_code_hon;
      RAISE no_prifile_expt;
    END IF;
    -- �f�B���N�g���I�u�W�F�N�g���p�X���擾����
    gv_bs_dire_path := xxcok_common_pkg.get_directory_path_f(
                         iv_directory_name => gt_prof_bs_dire_path
                       );
    -- �f�B���N�g���p�X�����b�Z�[�W�o�͂���
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00067
                    ,iv_token_name1  => cv_token_directory
                    ,iv_token_value1 => gv_bs_dire_path
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    -- �t�@�C���������b�Z�[�W�o�͂���
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcok
                    ,iv_name         => cv_msg_cok_00006
                    ,iv_token_name1  => cv_token_file_name
                    ,iv_token_value1 => gt_prof_bs_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 1                  -- ���s
                  );
    --========================================
    -- A-2.�t�@�C�����݃`�F�b�N
    --========================================
    UTL_FILE.FGETATTR(
      location    => gt_prof_bs_dire_path              -- �t�@�C���p�X
     ,filename    => gt_prof_bs_file_name              -- �t�@�C����
     ,fexists     => lb_exists                         -- �t�@�C�����݃`�F�b�N
     ,file_length => ln_file_length                    -- �t�@�C���̒���
     ,block_size  => ln_block_size                     -- �u���b�N�T�C�Y
    );
    -- �t�@�C�������݂��Ă���ꍇ
    IF( lb_exists = TRUE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00009
                      ,iv_token_name1  => cv_token_file_name
                      ,iv_token_value1 => gt_prof_bs_file_name
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                    ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                    ,in_new_line => 0                  -- ���s
                   );
      RAISE file_exists_expt;
    END IF;
    --=======================================
    -- �t�@�C���I�[�v��
    --=======================================
    gu_open_file_handle := UTL_FILE.FOPEN(
                             location     => gt_prof_bs_dire_path
                            ,filename     => gt_prof_bs_file_name
                            ,open_mode    => cv_open_mode
                            ,max_linesize => cn_max_linesize
                           );
--
  EXCEPTION
    -- *** ���̓p�����[�^DATE�^�ϊ���O�n���h�� ****
    WHEN date_prm_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C���擾��O�n���h�� ****
    WHEN no_prifile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxcok
                      ,iv_name         => cv_msg_cok_00003
                      ,iv_token_name1  => cv_token_profile
                      ,iv_token_value1 => lv_err_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �Ɩ����t�擾��O�n���h�� ****
    WHEN no_process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �t�@�C�����݃`�F�b�N��O�n���h�� ****
    WHEN file_exists_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_info
   * Description      : �ڋq���擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_info(
    ov_errbuf     OUT VARCHAR2             -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT VARCHAR2             -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;               -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;               -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �ڋq�����擾����
    OPEN cust_info_cur;
      FETCH cust_info_cur BULK COLLECT INTO gt_cust_info_tab;
    CLOSE cust_info_cur;
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
  END get_cust_info;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_support_info
   * Description      : �����ʔ̎�̋����擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_bm_support_info(
    ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,in_ci_cnt     IN  NUMBER              -- �����J�E���^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_support_info';   -- �v���O������
    cv_00         CONSTANT VARCHAR2(2)   := '00';                    -- �x������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;                       -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;                       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode       BOOLEAN        DEFAULT NULL;                       -- ���^�[���E�R�[�h
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;                       -- ���b�Z�[�W
    lv_pay_cond      VARCHAR2(8)    DEFAULT NULL;                       -- �x������
    ld_close_date    DATE           DEFAULT NULL;                       -- ���ߓ�
    ld_pay_date      DATE           DEFAULT NULL;                       -- �x����
    ld_op_day        DATE           DEFAULT NULL;                       -- �c�Ɠ�
    ld_business_date DATE           DEFAULT NULL;                       -- �Ɩ��������t-2��
    --===============================
    -- ���[�J����O
    --===============================
    --*** ���ߓ��擾��O ***
    close_date_expt    EXCEPTION;
    --*** �c�Ɠ��擾��O ***
    operating_day_expt EXCEPTION;
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �擾�����f�[�^���������x��������ݒ肷��
    lv_pay_cond := gt_cust_info_tab( in_ci_cnt ).close_day_code    || '_' ||
                   gt_cust_info_tab( in_ci_cnt ).transfer_day_code || '_' || cv_00;
    -- �Ɩ��������t�|�Q�c�Ɠ����擾����
    ld_business_date := xxcok_common_pkg.get_operating_day_f(
                          id_proc_date => gd_business_date     -- ������
                         ,in_days      => cn_minus_2           -- ����
                         ,in_proc_type => cn_1                 -- �����敪
                        );
    -- ���ߓ����擾����
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf     => lv_errbuf
     ,ov_retcode    => lv_retcode
     ,ov_errmsg     => lv_errmsg
     ,id_proc_date  => ld_business_date
     ,iv_pay_cond   => lv_pay_cond
     ,od_close_date => ld_close_date
     ,od_pay_date   => ld_pay_date
    );
    -- ���ߓ��擾�G���[
    IF( lv_retcode = cv_status_error ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_appli_xxcok
                     ,iv_name          => cv_msg_cok_10369
                     ,iv_token_name1   => cv_token_close_date
                     ,iv_token_value1  => gd_business_date
                     ,iv_token_name2   => cv_token_term_code
                     ,iv_token_value2  => lv_pay_cond
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      RAISE close_date_expt;
    END IF;
    -- �c�Ɠ����擾����
    ld_op_day := xxcok_common_pkg.get_operating_day_f(
                   id_proc_date => ld_close_date                -- ������
                  ,in_days      => gt_prof_bs_period_to         -- ����
                  ,in_proc_type => cn_2                         -- �����敪
                 );
    -- �c�Ɠ��擾�G���[
    IF( ld_op_day IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_appli_xxcok
                     ,iv_name          => cv_msg_cok_10203
                     ,iv_token_name1   => cv_token_close_date
                     ,iv_token_value1  => ld_close_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      RAISE operating_day_expt;
    END IF;
    -- �Ɩ��������t���擾�����c�Ɠ��̏ꍇ
    IF( gd_business_date = ld_op_day ) THEN
      -- �����ʔ̎�̋������擾����
      OPEN bm_support_cur(
             in_ci_cnt => in_ci_cnt
           );
        FETCH bm_support_cur BULK COLLECT INTO gt_bm_support_tab;
      CLOSE bm_support_cur;
    END IF;
--
  EXCEPTION
    -- *** ���ߓ��擾��O�n���h�� ***
    WHEN close_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �c�Ɠ��擾��O�n���h�� ***
    WHEN operating_day_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
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
  END get_bm_support_info;
--
  /**********************************************************************************
   * Procedure Name   : storage_plsql_tab
   * Description      : PL/SQL�\�i�[����(A-5)
   ***********************************************************************************/
  PROCEDURE storage_plsql_tab(
    ov_errbuf     OUT VARCHAR2              -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT VARCHAR2              -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,in_bs_cnt     IN  NUMBER                -- �����ʔ̎�̋����̍����J�E���^
   ,in_idx_cnt    IN  NUMBER                -- PL/SQL�\�i�[�����J�E���^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'storage_plsql_tab'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                   -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                   -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �擾�����f�[�^��PL/SQL�\�Ɋi�[����
    gt_bms_csv_tab( in_idx_cnt ).sequence_number         := gt_bm_support_tab( in_bs_cnt ).cond_bm_support_id;       -- �V�[�P���X�ԍ�
    gt_bms_csv_tab( in_idx_cnt ).company_code            := gt_prof_aff1_company_code;                               -- ��ЃR�[�h
    gt_bms_csv_tab( in_idx_cnt ).base_code               := gt_bm_support_tab( in_bs_cnt ).base_code;                -- ���_(����) �R�[�h
    gt_bms_csv_tab( in_idx_cnt ).emp_code                := gt_bm_support_tab( in_bs_cnt ).emp_code;                 -- �S���҃R�[�h
    gt_bms_csv_tab( in_idx_cnt ).cust_code               := gt_bm_support_tab( in_bs_cnt ).delivery_cust_code;       -- �ڋq�R�[�h
    gt_bms_csv_tab( in_idx_cnt ).acctg_year              := gt_bm_support_tab( in_bs_cnt ).acctg_year;               -- ��v�N�x
    gt_bms_csv_tab( in_idx_cnt ).chain_store_code        := gt_bm_support_tab( in_bs_cnt ).chain_store_code;         -- �`�F�[���X�R�[�h
    gt_bms_csv_tab( in_idx_cnt ).supplier_code           := gt_bm_support_tab( in_bs_cnt ).supplier_code;            -- �d����R�[�h
    gt_bms_csv_tab( in_idx_cnt ).supplier_site_code      := gt_bm_support_tab( in_bs_cnt ).supplier_site_code;       -- �x����T�C�g�R�[�h
    gt_bms_csv_tab( in_idx_cnt ).delivery_date           := gt_bm_support_tab( in_bs_cnt ).delivery_date;            -- �[�i���N��
    gt_bms_csv_tab( in_idx_cnt ).delivery_qty            := gt_bm_support_tab( in_bs_cnt ).delivery_qty;             -- �[�i����
    gt_bms_csv_tab( in_idx_cnt ).delivery_unit_type      := gt_prof_uom_code_hon;                                    -- �[�i�P��(�{/�P�[�X)
    gt_bms_csv_tab( in_idx_cnt ).selling_amt_tax         := gt_bm_support_tab( in_bs_cnt ).selling_amt_tax;          -- ������z(�ō�)
    gt_bms_csv_tab( in_idx_cnt ).account_type            := gt_bm_support_tab( in_bs_cnt ).calc_type;                -- �������
    gt_bms_csv_tab( in_idx_cnt ).rebate_rate             := gt_bm_support_tab( in_bs_cnt ).rebate_rate;              -- ���ߗ�
    gt_bms_csv_tab( in_idx_cnt ).rebate_amt              := gt_bm_support_tab( in_bs_cnt ).rebate_amt;               -- ���ߊz
    gt_bms_csv_tab( in_idx_cnt ).container_type_code     := gt_bm_support_tab( in_bs_cnt ).container_type_code;      -- �e��敪�R�[�h
    gt_bms_csv_tab( in_idx_cnt ).selling_price           := gt_bm_support_tab( in_bs_cnt ).selling_price;            -- �������z
    gt_bms_csv_tab( in_idx_cnt ).cond_bm_amt_tax         := gt_bm_support_tab( in_bs_cnt ).cond_bm_amt_tax;          -- �����ʎ萔���z(�ō�)
    gt_bms_csv_tab( in_idx_cnt ).cond_bm_amt_no_tax      := gt_bm_support_tab( in_bs_cnt ).cond_bm_amt_no_tax;       -- �����ʎ萔���z(�Ŕ�)
    gt_bms_csv_tab( in_idx_cnt ).cond_tax_amt            := gt_bm_support_tab( in_bs_cnt ).cond_tax_amt;             -- �����ʏ���Ŋz
    gt_bms_csv_tab( in_idx_cnt ).electric_amt            := gt_bm_support_tab( in_bs_cnt ).electric_amt_tax;         -- �d�C��
    gt_bms_csv_tab( in_idx_cnt ).closing_date            := gt_bm_support_tab( in_bs_cnt ).closing_date;             -- ����
    gt_bms_csv_tab( in_idx_cnt ).expect_payment_date     := gt_bm_support_tab( in_bs_cnt ).expect_payment_date;      -- �x����
    gt_bms_csv_tab( in_idx_cnt ).calc_target_period_from := gt_bm_support_tab( in_bs_cnt ).calc_target_period_from;  -- �v�Z�Ώۊ���(From)
    gt_bms_csv_tab( in_idx_cnt ).calc_target_period_to   := gt_bm_support_tab( in_bs_cnt ).calc_target_period_to;    -- �v�Z�Ώۊ���(To)
    gt_bms_csv_tab( in_idx_cnt ).ref_base_code           := gt_bm_support_tab( in_bs_cnt ).ref_base_code;            -- �⍇�킹�S�����_�R�[�h
    gt_bms_csv_tab( in_idx_cnt ).interface_date          := gd_sysdate;                                              -- �A�g����
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
  END storage_plsql_tab;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_file
   * Description      : �t�@�C���o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE output_csv_file(
    ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,in_csv_cnt    IN  NUMBER       -- �����J�E���^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_file'; -- �v���O������
    cv_comma      CONSTANT VARCHAR2(1)   := ',';               -- �R���}
    cv_wq         CONSTANT VARCHAR2(1)   := '"';               -- �_�u���R�[�e�[�V����
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                 -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_csv_file   VARCHAR2(5000) DEFAULT NULL;                 -- CSV�t�@�C��
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --
    lv_csv_file := TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).sequence_number )                     || cv_comma || -- �V�[�P���X�ԍ�
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).company_code                 || cv_wq || cv_comma || -- ��ЃR�[�h
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).base_code                    || cv_wq || cv_comma || -- ���_(����) �R�[�h
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).emp_code                     || cv_wq || cv_comma || -- �S���҃R�[�h
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).cust_code                    || cv_wq || cv_comma || -- �ڋq�R�[�h
                            gt_bms_csv_tab( in_csv_cnt ).acctg_year                            || cv_comma || -- ��v�N�x
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).chain_store_code             || cv_wq || cv_comma || -- �`�F�[���X�R�[�h
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).supplier_code                || cv_wq || cv_comma || -- �d����R�[�h
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).supplier_site_code           || cv_wq || cv_comma || -- �x����T�C�g�R�[�h
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).delivery_date )                       || cv_comma || -- �[�i���N��
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).delivery_qty )                        || cv_comma || -- �[�i����
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).delivery_unit_type           || cv_wq || cv_comma || -- �[�i�P��(�{/�P�[�X)
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).selling_amt_tax )                     || cv_comma || -- ������z(�ō�)
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).account_type                 || cv_wq || cv_comma || -- �������
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).rebate_rate )                         || cv_comma || -- ���ߗ�
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).rebate_amt )                          || cv_comma || -- ���ߊz
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).container_type_code          || cv_wq || cv_comma || -- �e��敪�R�[�h
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).selling_price )                       || cv_comma || -- �������z
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_bm_amt_tax )                     || cv_comma || -- �����ʎ萔���z(�ō�)
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_bm_amt_no_tax )                  || cv_comma || -- �����ʎ萔���z(�Ŕ�)
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).cond_tax_amt )                        || cv_comma || -- �����ʏ���Ŋz
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).electric_amt )                        || cv_comma || -- �d�C��
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).closing_date, 'YYYYMMDD' )            || cv_comma || -- ����
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).expect_payment_date, 'YYYYMMDD' )     || cv_comma || -- �x����
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).calc_target_period_from, 'YYYYMMDD' ) || cv_comma || -- �v�Z�Ώۊ���(From)
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).calc_target_period_to, 'YYYYMMDD' )   || cv_comma || -- �v�Z�Ώۊ���(To)
          cv_wq ||          gt_bms_csv_tab( in_csv_cnt ).ref_base_code                || cv_wq || cv_comma || -- �⍇�킹�S�����_�R�[�h
                   TO_CHAR( gt_bms_csv_tab( in_csv_cnt ).interface_date, 'YYYYMMDDHHMISS' );                  -- �A�g����
    -- CSV�t�@�C���o��
    UTL_FILE.PUT_LINE(
       file      => gu_open_file_handle
      ,buffer    => lv_csv_file
    );
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
  END output_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : upd_cond_bm_support
   * Description      : �����ʔ̎�̋��e�[�u���X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE upd_cond_bm_support(
    ov_errbuf     OUT VARCHAR2                                     -- �G���[�E���b�Z�[�W
   ,ov_retcode    OUT VARCHAR2                                     -- ���^�[���E�R�[�h
   ,ov_errmsg     OUT VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,in_bs_cnt     IN  NUMBER                                       -- �����J�E���^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cond_bm_support'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                     -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;                     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                     -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(5000) DEFAULT NULL;                     -- ���b�Z�[�W
    lb_retcode    BOOLEAN        DEFAULT NULL;                     -- ���^�[���E�R�[�h
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �����ʔ̎�̋��e�[�u���̃��b�N���擾����
    OPEN lock_cond_bm_support_cur(
           in_cond_bm_support_id => gt_bms_csv_tab( in_bs_cnt ).sequence_number
         );
    CLOSE lock_cond_bm_support_cur;
    -- �����ʔ̎�̋��e�[�u���X�V�������s�Ȃ�
    UPDATE xxcok_cond_bm_support    xcbs                                                    -- �����ʔ̎�̋��e�[�u��
    SET    xcbs.cond_bm_interface_status = cv_1                                             -- �A�g�X�e�[�^�X
          ,xcbs.cond_bm_interface_date   = gd_sysdate                                       -- �A�g��
          ,xcbs.last_updated_by          = cn_last_updated_by                               -- �ŏI�X�V��
          ,xcbs.last_update_date         = SYSDATE                                          -- �ŏI�X�V��
          ,xcbs.last_update_login        = cn_last_update_login                             -- �ŏI�X�V���O�C��
          ,xcbs.request_id               = cn_request_id                                    -- �v��ID
          ,xcbs.program_application_id   = cn_program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xcbs.program_id               = cn_program_id                                    -- �R���J�����g�E�v���O����ID
          ,xcbs.program_update_date      = SYSDATE                                          -- �v���O�����X�V��
    WHERE  xcbs.cond_bm_support_id       = gt_bms_csv_tab( in_bs_cnt ).sequence_number;
--
  EXCEPTION
    -- *** ���ʃ��b�N�擾��O�n���h�� ***
    WHEN global_lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appli_xxcok
                      ,iv_name        => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
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
  END upd_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : �����ʔ̎�̋����csv�t�@�C���쐬
   ***********************************************************************************/
  PROCEDURE create_csv_file(
    ov_errbuf   OUT VARCHAR2            -- �G���[�E���b�Z�[�W
   ,ov_retcode  OUT VARCHAR2            -- ���^�[���E�R�[�h
   ,ov_errmsg   OUT VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'create_csv_file';    -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                    -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;                    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_ci_cnt   NUMBER         DEFAULT NULL;                    -- �ڋq���擾�̍����J�E���^
    ln_bs_cnt   NUMBER         DEFAULT NULL;                    -- �����ʔ̎�̋����̍����J�E���^
    ln_csv_cnt  NUMBER         DEFAULT NULL;                    -- CSV�o�͂̍����J�E���^
    ln_idx_cnt  NUMBER         DEFAULT NULL;                    -- PL/SQL�\�i�[�����J�E���^
--
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �����J�E���^������
    ln_ci_cnt  := 0;                                    -- �ڋq���擾�̍����J�E���^
    ln_bs_cnt  := 0;                                    -- �����ʔ̎�̋����̍����J�E���^
    ln_csv_cnt := 0;                                    -- CSV�o�͂̍����J�E���^
    ln_idx_cnt := 0;                                    -- PL/SQL�\�i�[�����J�E���^
    --===================================
    -- A-3.�ڋq���擾����
    --===================================
    get_cust_info(
       ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    <<cust_info_loop>>                                  -- �ڋq���[�v START
    FOR ln_ci_cnt IN 1 .. gt_cust_info_tab.COUNT LOOP
      --===================================
      -- A-4.�����ʔ̎�̋����擾����
      --===================================
      get_bm_support_info(
         ov_errbuf            => lv_errbuf              -- �G���[�E���b�Z�[�W
        ,ov_retcode           => lv_retcode             -- ���^�[���E�R�[�h
        ,ov_errmsg            => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,in_ci_cnt            => ln_ci_cnt              -- �ڋq���擾�̍����J�E���^
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      <<bm_support_tab_loop>>                           -- �����ʔ̎胋�[�v START
      FOR ln_bs_cnt IN 1 .. gt_bm_support_tab.COUNT LOOP
        -- PL/SQL�\�i�[�����J�E���g
        ln_idx_cnt    := ln_idx_cnt + 1;
        --===================================
        -- A-5.PL/SQL�\�i�[����
        --===================================
        storage_plsql_tab(
          ov_errbuf  => lv_errbuf                       -- �G���[�E���b�Z�[�W
         ,ov_retcode => lv_retcode                      -- ���^�[���E�R�[�h
         ,ov_errmsg  => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,in_bs_cnt  => ln_bs_cnt                       -- �����ʔ̎�̋����̍����J�E���^
         ,in_idx_cnt => ln_idx_cnt                      -- PL/SQL�\�i�[�����J�E���^
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- �Ώی����J�E���g
        gn_target_cnt := gn_target_cnt + 1;
      END LOOP bm_support_tab_loop;                     -- �����ʔ̎胋�[�v END
    END LOOP cust_info_loop;                            -- �ڋq���[�v END
    <<bms_csv_tab_loop>>                                -- �o�̓��[�v START
      FOR ln_csv_cnt IN 1 .. gt_bms_csv_tab.COUNT LOOP
      --===================================
      -- A-6.�t�@�C���o�͏���
      --===================================
      output_csv_file(
        ov_errbuf  => lv_errbuf                         -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode                        -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,in_csv_cnt => ln_csv_cnt                        -- CSV�o�͂̍����J�E���^
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
      --===================================
      -- A-7.�����ʔ̎�̋��e�[�u���X�V����
      --===================================
      upd_cond_bm_support(
        ov_errbuf  => lv_errbuf                         -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode                        -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,in_bs_cnt  => ln_csv_cnt                        -- �����J�E���^
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP bms_csv_tab_loop;                          -- �o�̓��[�v END
--
  EXCEPTION
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
  END create_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode       OUT VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg        OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_business_date IN  VARCHAR2     -- �N���p�����[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain';   -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;           -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;           -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;           -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --===============================
    -- A-1.��������
    --===============================
    init(
      ov_errbuf        => lv_errbuf               -- �G���[�E���b�Z�[�W
     ,ov_retcode       => lv_retcode              -- ���^�[���E�R�[�h
     ,ov_errmsg        => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_business_date => iv_business_date        -- ���̓p�����[�^�E�Ɩ����t
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --===================================
    -- �����ʔ̎�̋����csv�t�@�C���쐬
    --===================================
    create_csv_file(
      ov_errbuf  => lv_errbuf               -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode              -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --=================================
    -- A-8.�t�@�C���N���[�Y
    --=================================
   IF( UTL_FILE.IS_OPEN( gu_open_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
         file => gu_open_file_handle
      );
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      --=================================
      -- A-8.�t�@�C���N���[�Y
      --=================================
      IF( UTL_FILE.IS_OPEN( gu_open_file_handle ) ) THEN
        UTL_FILE.FCLOSE(
           file => gu_open_file_handle
        );
      END IF;
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT VARCHAR2      -- �G���[�E���b�Z�[�W
   ,retcode          OUT VARCHAR2      -- ���^�[���E�R�[�h
   ,iv_business_date IN  VARCHAR2      -- �N���p�����[�^
  )
  IS
--
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';   -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL;        -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)    DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL;        -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)  DEFAULT NULL;        -- �I�����b�Z�[�W�R�[�h
    lb_retcode         BOOLEAN        DEFAULT NULL;        -- ���^�[���E�R�[�h
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL;        -- ���b�Z�[�W
--
  BEGIN
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode                            -- �G���[�E���b�Z�[�W
      ,ov_errbuf  => lv_errbuf                             -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf        => lv_errbuf                -- �G���[�E���b�Z�[�W
      ,ov_retcode       => lv_retcode               -- ���^�[���E�R�[�h
      ,ov_errmsg        => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_business_date => iv_business_date         -- �N���p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- �G���[�����J�E���g
      gn_error_cnt := 1;
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_errmsg          -- ���b�Z�[�W
                     ,in_new_line => 1                  -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG       -- �o�͋敪
                     ,iv_message  => lv_errbuf          -- ���b�Z�[�W
                     ,in_new_line => 1                  -- ���s
                    );
    END IF;
    --================================================
    -- A-9.�I������
    --================================================
    -- �Ώی���
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_token_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    --��������
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_token_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 0                  -- ���s
                  );
    --�G���[����
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appli_xxccp
                   ,iv_name         => cv_msg_ccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                   ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                   ,in_new_line => 1                  -- ���s
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X������̏ꍇ�͐���I�����b�Z�[�W���o�͂���
    IF( retcode = cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_xxccp
                     ,iv_name         => cv_msg_ccp_90004
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    ELSIF( retcode = cv_status_error ) THEN
      ROLLBACK;
      -- ���[���o�b�N���b�Z�[�W
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_xxccp
                      ,iv_name         => cv_msg_ccp_90006
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    -- �o�͋敪
                     ,iv_message  => lv_out_msg         -- ���b�Z�[�W
                     ,in_new_line => 0                  -- ���s
                    );
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
END XXCOK014A02C;
/
