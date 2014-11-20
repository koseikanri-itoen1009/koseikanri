CREATE OR REPLACE PACKAGE BODY XXCOK015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A01C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : EDI�V�X�e���ɂăC�Z�g�[�Ђ֑��M����x���ē���(�����͂���)�p�f�[�^�t�@�C���쐬
 * Version          : 1.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  �t�@�C���N���[�Y(A-9)
 *  get_footer_data             �t�b�^���R�[�h�擾(A-8)
 *  update_bm_data              �A�g�Ώۃf�[�^�X�V(A-7)
 *  file_output                 �A�g�f�[�^�t�@�C���쐬(A-6)
 *  check_bm_data               �A�g�f�[�^�Ó����`�F�b�N(A-5)
 *  check_bm_amt                �̎�c�������z�`�F�b�N(A-4)
 *  get_bm_data                 �A�g�Ώ۔̎�c�����擾(A-3)
 *  file_open                   �t�@�C���I�[�v��(A-2)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   K.Iwabuchi       �V�K�쐬
 *  2009/02/06    1.1   K.Iwabuchi       [��QCOK_014] �N�C�b�N�R�[�h�r���[�L������ǉ��A�f�B���N�g���p�X�擾�ύX�Ή�
 *  2009/02/20    1.2   K.Iwabuchi       [��QCOK_050] �d����T�C�g����������ǉ�
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK015A01C';
  -- �A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxcok  CONSTANT VARCHAR2(10)    := 'XXCOK'; -- ��_�A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP'; -- ����_�A�v���P�[�V�����Z�k��
  -- �X�e�[�^�X
  cv_status_normal           CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W
  cv_msg_xxcok1_00003        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[
  cv_msg_xxcok1_00006        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00006';  -- �t�@�C�����o��
  cv_msg_xxcok1_00009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00009';  -- �t�@�C�����݃G���[
  cv_msg_xxcok1_00015        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00015';  -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00053';  -- �̎�c���e�[�u�����b�N�擾�G���[
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00067';  -- �f�B���N�g���o��
  cv_msg_xxcok1_10009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10009';  -- �x�����z0�~�ȉ��x��
  cv_msg_xxcok1_10428        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10428';  -- EDI�w�b�_���R�[�h�擾�G���[
  cv_msg_xxcok1_10429        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10429';  -- EDI�t�b�^���R�[�h�擾�G���[
  cv_msg_xxcok1_10430        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10430';  -- �d���於�S�p�`�F�b�N�x��
  cv_msg_xxcok1_10431        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10431';  -- �d����Z���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10432        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10432';  -- ���_���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10433        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10433';  -- ���_�Z���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10434';  -- ��s���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10435';  -- ��s�x�X���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10436        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10436';  -- �X�֔ԍ����p�p�����L���`�F�b�N�x��
  cv_msg_xxcok1_10437        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10437';  -- ���_�X�֔ԍ����p�p�����L���`�F�b�N�x��
  cv_msg_xxcok1_10438        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10438';  -- ���_�d�b�ԍ����p�p�����L���`�F�b�N�x��
  cv_msg_xxcok1_10439        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10439';  -- �d����R�[�h�����`�F�b�N�x��
  cv_msg_xxcok1_10440        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10440';  -- �X�֔ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10441        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10441';  -- ���_�X�֔ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10442        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10442';  -- ���_�d�b�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10443        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10443';  -- ��s�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10444        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10444';  -- ��s�x�X�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10445        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10445';  -- �̔����z���v�����`�F�b�N�x��
  cv_msg_xxcok1_10446        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10446';  -- �̔��萔�������`�F�b�N�x��
  cv_msg_xxcok1_10447        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10447';  -- ��s�x�X�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10448        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10448';  -- �x���\��z(�ō�)�����`�F�b�N�x��
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_xxccp1_90001        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';  -- ��������
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';  -- �x������
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_msg_xxccp1_90008        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N��
  cv_token_profile           CONSTANT VARCHAR2(20)    := 'PROFILE';
  cv_token_directory         CONSTANT VARCHAR2(20)    := 'DIRECTORY';
  cv_token_file_name         CONSTANT VARCHAR2(20)    := 'FILE_NAME';
  cv_token_conn_loc          CONSTANT VARCHAR2(20)    := 'CONN_LOC';
  cv_token_vendor_code       CONSTANT VARCHAR2(20)    := 'VENDOR_CODE';
  cv_token_close_date        CONSTANT VARCHAR2(20)    := 'CLOSE_DATE';
  cv_token_due_date          CONSTANT VARCHAR2(20)    := 'DUE_DATE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)    := 'LOOKUP_VALUE_SET';
  cv_data_kind               CONSTANT VARCHAR2(20)    := 'DATA_KIND';
  cv_from_series             CONSTANT VARCHAR2(20)    := 'FROM_SERIES';
  cv_token_count             CONSTANT VARCHAR2(20)    := 'COUNT';
  -- �v���t�@�C��
  cv_prof_i_dire_path        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DIRE_PATH';     -- �C�Z�g�[_�f�B���N�g���p�X
  cv_prof_i_file_name        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_FILE_NAME';     -- �C�Z�g�[_�t�@�C����
  cv_prof_i_data_class       CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DATA_CLASS';    -- �C�Z�g�[_�f�[�^���
  cv_prof_prompt_bm          CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';       -- �̔��萔�����o��
  cv_prof_prompt_ep          CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';       -- �d�C�����o��
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- ��s�萔��_�U���z�
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- ��s�萔��_��z����
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- ��s�萔��_��z�ȏ�
  cv_prof_bm_tax             CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_TAX';                    -- �̔��萔��_����ŗ�
  cv_prof_if_data            CONSTANT VARCHAR2(40)    := 'XXCCP1_IF_DATA';                   -- IF���R�[�h�敪_�f�[�^
  cv_prof_org_id             CONSTANT VARCHAR2(40)    := 'ORG_ID';                           -- �c�ƒP��ID
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  -- �L��
  cv_space                   CONSTANT VARCHAR2(1)     := ' ';    -- ���p�X�y�[�X
  cv_asterisk                CONSTANT VARCHAR2(2)     := '��';   -- �S�p�A�X�^���X�N
  cv_asterisk_half           CONSTANT VARCHAR2(1)     := '*';    -- ���p�A�X�^���X�N
  -- ���l
  cn_number_0                CONSTANT NUMBER          := 0;
  cn_number_1                CONSTANT NUMBER          := 1;
  cn_number_2                CONSTANT NUMBER          := 2;
  cn_number_4                CONSTANT NUMBER          := 4;
  cn_number_7                CONSTANT NUMBER          := 7;
  cn_number_9                CONSTANT NUMBER          := 9;
  cn_number_11               CONSTANT NUMBER          := 11;
  cn_number_15               CONSTANT NUMBER          := 15;
  -- ���l(�����`��)
  cv_0                       CONSTANT VARCHAR2(1)     := '0';
  -- �����t�H�[�}�b�g
  cv_format_ee               CONSTANT VARCHAR2(50)    := 'EE';
  cv_format_ee_year          CONSTANT VARCHAR2(50)    := 'RRMM';
  cv_format_mmdd             CONSTANT VARCHAR2(50)    := 'MMDD';
  cv_format_yyyy_mm_dd       CONSTANT VARCHAR2(50)    := 'YYYY/MM/DD';
  -- �e����T�|�[�g�p�����[�^
  cv_nls_param               CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
  -- �t�@�C���I�[�v���p�����[�^
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';    -- �e�L�X�g�̏�����
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;  -- 1�s����ő啶����
  -- �S�x���ۗ̕��t���O
  cv_hold_flag               CONSTANT VARCHAR2(1)     := 'N';
  -- �A�g�X�e�[�^�X�iEDI�x���ē����j
  cv_edi_if_status_0         CONSTANT VARCHAR2(1)     := '0';    -- ������
  cv_edi_if_status_1         CONSTANT VARCHAR2(1)     := '1';    -- ������
  -- BM�x���敪
  cv_bm_pay_class            CONSTANT VARCHAR2(1)     := '1';    -- �{�U(�ē��L)
  -- ���s�t���O
  cv_primary_flag            CONSTANT VARCHAR2(1)     := 'Y';    -- ���s
  -- ��s�萔�����S��
  cv_bank_charge_bearer      CONSTANT VARCHAR2(1)     := 'S';    -- �d����/�W��
  -- �t�^�敪
  cv_add_area_h              CONSTANT VARCHAR2(1)     := 'H';    -- �w�b�_�t�^
  cv_add_area_f              CONSTANT VARCHAR2(1)     := 'F';    -- �t�b�^�t�^
  -- �Q�ƃ^�C�v
  cv_lookup_type             CONSTANT VARCHAR2(30)    := 'XXCOS1_DATA_TYPE_CODE';  -- �f�[�^��R�[�h
  -- �Q�ƃR�[�h
  cv_lookup_code_i           CONSTANT VARCHAR2(5)     := '130';  -- �f�[�^��R�[�h�擾�p(�C�Z�gBM)
  -- ���񏈗��ԍ�
  cv_row_number              CONSTANT VARCHAR2(2)     := '01';
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt      NUMBER          DEFAULT cn_number_0;  -- �Ώی���
  gn_normal_cnt      NUMBER          DEFAULT cn_number_0;  -- ���팏��
  gn_error_cnt       NUMBER          DEFAULT cn_number_0;  -- �G���[����
  gn_skip_cnt        NUMBER          DEFAULT cn_number_0;  -- �X�L�b�v����
  gn_cnt             NUMBER          DEFAULT cn_number_0;  -- �A�g���ځu�J�E���^�v�p
  gd_process_date    DATE            DEFAULT NULL;         -- �Ɩ��������t
  gv_header_data     VARCHAR2(1000)  DEFAULT NULL;         -- �w�b�_���R�[�h�f�[�^
  gv_footer_data     VARCHAR2(1000)  DEFAULT NULL;         -- �t�b�^���R�[�h�f�[�^
  gn_org_id          NUMBER          DEFAULT NULL;         -- �c�ƒP��ID
  gv_i_dire_path     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �C�Z�g�[_�f�B���N�g���p�X
  gv_i_file_name     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �C�Z�g�[_�t�@�C����
  gv_i_data_class    fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �C�Z�g�[_�f�[�^���
  gv_prompt_bm       fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �̔��萔�����o��
  gv_prompt_ep       fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �d�C�����o��
  gv_bank_fee_trans  fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- ��s�萔��_�U���z�
  gv_bank_fee_less   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- ��s�萔��_��z����
  gv_bank_fee_more   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- ��s�萔��_��z�ȏ�
  gv_bm_tax          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- �̔��萔��_����ŗ�
  gv_if_data         fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- IF���R�[�h�敪_�f�[�^
  g_file_handle      UTL_FILE.FILE_TYPE;    -- �t�@�C���n���h��
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  CURSOR g_bm_data_cur
  IS
    SELECT bm.supplier_code                                                AS supplier_code           -- �d����R�[�h
         , pv.vendor_name                                                  AS vendor_name             -- �d���於
         , pvsa.zip                                                        AS zip                     -- �X�֔ԍ�
         , pvsa.state || pvsa.city || pvsa.address_line1                   AS address1                -- �Z��1
         , pvsa.address_line2                                              AS address2                -- �Z��2
         , hp.party_name                                                   AS base_name               -- ���_��
         , hl.state || hl.city || hl.address1 || hl.address2               AS base_address            -- ���_�Z��
         , hl.postal_code                                                  AS base_postal_code        -- ���_�X�֔ԍ�
         , hl.address_lines_phonetic                                       AS base_phone              -- ���_�d�b�ԍ�
         , bm.closing_date                                                 AS closing_date            -- ���ߓ�
         , TO_CHAR( bm.closing_date, cv_format_ee, cv_nls_param )          AS jpn_calendar            -- ���ߓ�(�a��N��)
         , TO_CHAR( bm.closing_date, cv_format_ee_year, cv_nls_param )     AS years                   -- ���ߓ�(�a��N��)
         , bm.expect_payment_date                                          AS expect_payment_date     -- �x���\���
         , TO_CHAR( bm.expect_payment_date, cv_format_mmdd )               AS payment_month_date      -- �x���\���(����)
         , abb.bank_number                                                 AS bank_number             -- ��s�ԍ�
         , abb.bank_name                                                   AS bank_name               -- ��s��
         , abb.bank_num                                                    AS bank_num                -- ��s�x�X�ԍ�
         , abb.bank_branch_name                                            AS bank_branch_name        -- ��s�x�X��
         , bm.selling_amt_tax                                              AS selling_amt_tax         -- �̔����z(�ō�)
         , bm.backmargin                                                   AS backmargin              -- �̔��萔��
         , bm.electric_amt                                                 AS electric_amt            -- �d�C��
         , bm.expect_payment_amt_tax                                       AS expect_payment_amt_tax  -- �x���\��z(�ō�)
         , pvsa.bank_charge_bearer                                         AS bank_charge_bearer      -- ��s�萔�����S��
         , pvsa.attribute5                                                 AS base_charge             -- �⍇���S�����_�R�[�h
    FROM   po_vendors                 pv     -- �d����}�X�^
         , po_vendor_sites_all        pvsa   -- �d����T�C�g�}�X�^
         , ap_bank_branches           abb    -- ��s�x�X�}�X�^
         , ap_bank_accounts_all       abaa   -- ��s�����}�X�^
         , ap_bank_account_uses_all   abaua  -- ��s�����g�p���}�X�^
         , hz_cust_accounts           hca    -- �ڋq�}�X�^
         , hz_parties                 hp     -- �p�[�e�B�}�X�^
         , hz_cust_acct_sites_all     hcas   -- �ڋq���ݒn�}�X�^
         , hz_party_sites             hps    -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations               hl     -- �ڋq���Ə��}�X�^
         , ( SELECT xbb.supplier_code                                                   AS supplier_code           -- �d����R�[�h
                  , xbb.supplier_site_code                                              AS supplier_site_code      -- �d����T�C�g�R�[�h
                  , SUM( NVL( xbb.selling_amt_tax, 0 ) )                                AS selling_amt_tax         -- �̔����z(�ō�)
                  , SUM( NVL( xbb.backmargin, 0 )   + NVL( xbb.backmargin_tax, 0 ) )    AS backmargin              -- �̔��萔��
                  , SUM( NVL( xbb.electric_amt, 0 ) + NVL( xbb.electric_amt_tax, 0 ) )  AS electric_amt            -- �d�C��
                  , SUM( NVL( xbb.expect_payment_amt_tax, 0 ) )                         AS expect_payment_amt_tax  -- �x���\��z(�ō�)
                  , MAX( xbb.closing_date )                                             AS closing_date            -- ���ߓ�
                  , MAX( xbb.expect_payment_date )                                      AS expect_payment_date     -- �x���\���
             FROM   xxcok_backmargin_balance  xbb                   -- �̎�c���e�[�u��
             WHERE  xbb.edi_interface_status  = cv_edi_if_status_0  -- ������
             AND    xbb.resv_flag IS NULL
             GROUP BY xbb.supplier_code
                    , xbb.supplier_site_code
           ) bm  -- �̎�c��
    WHERE  pv.segment1                       = bm.supplier_code
    AND    pvsa.vendor_site_code             = bm.supplier_site_code
    AND    pvsa.hold_all_payments_flag       = cv_hold_flag
    AND    pvsa.attribute4                   = cv_bm_pay_class
    AND    pvsa.org_id                       = gn_org_id
    AND    ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )
    AND    hca.account_number                = pvsa.attribute5
    AND    hca.party_id                      = hp.party_id
    AND    hca.cust_account_id               = hcas.cust_account_id
    AND    hcas.party_site_id                = hps.party_site_id
    AND    hcas.org_id                       = gn_org_id
    AND    hps.location_id                   = hl.location_id
    AND    pv.vendor_id                      = pvsa.vendor_id
    AND    pvsa.vendor_id                    = abaua.vendor_id
    AND    pvsa.vendor_site_id               = abaua.vendor_site_id
    AND    abaa.bank_account_id              = abaua.external_bank_account_id
    AND    abaa.bank_branch_id               = abb.bank_branch_id
    AND    abaa.org_id                       = gn_org_id
    AND    abaua.org_id                      = gn_org_id
    AND    abaua.primary_flag                = cv_primary_flag
    AND    ( abaua.start_date               <= gd_process_date OR abaua.start_date IS NULL )
    AND    ( abaua.end_date                 >= gd_process_date OR abaua.end_date   IS NULL )
    ORDER BY pvsa.zip;
  TYPE g_bm_data_ttype IS TABLE OF g_bm_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_bm_data_tab g_bm_data_ttype;
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���b�N�G���[ ***
  global_lock_fail                EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���������ʗ�O(�t�@�C���N���[�Y) ***
  global_process_file_close_expt  EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y(A-9)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_close';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �t�@�C���N���[�Y
    -- ===============================================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : get_footer_data
   * Description      : �t�b�^���R�[�h�擾(A-8)
   ***********************************************************************************/
  PROCEDURE get_footer_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_footer_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �t�b�^���R�[�h�擾
    -- ===============================================
    xxccp_ifcommon_pkg.add_edi_header_footer(
      ov_errbuf          => lv_errbuf
    , ov_retcode         => lv_retcode
    , ov_errmsg          => lv_errmsg
    , iv_add_area        => cv_add_area_f   -- �t�^�敪
    , iv_from_series     => NULL            -- �h�e���Ɩ��n��R�[�h
    , iv_base_code       => NULL            -- ���_�R�[�h
    , iv_base_name       => NULL            -- ���_����
    , iv_chain_code      => NULL            -- �`�F�[���X�R�[�h
    , iv_chain_name      => NULL            -- �`�F�[���X����
    , iv_data_kind       => NULL            -- �f�[�^��R�[�h
    , iv_row_number      => NULL            -- ���񏈗��ԍ�
    , in_num_of_records  => gn_normal_cnt   -- ���R�[�h����
    , ov_output          => gv_footer_data  -- �o�͒l
    );
    IF ( lv_retcode   <> cv_status_normal ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10429
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- �t�b�^���R�[�h���t�@�C���ɏo��
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => gv_footer_data
    );
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_footer_data;
--
  /**********************************************************************************
   * Procedure Name   : update_bm_data
   * Description      : �A�g�Ώۃf�[�^�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE update_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'update_bm_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR l_bm_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance  xbb
      WHERE  xbb.supplier_code         = g_bm_data_tab( in_index ).supplier_code
      AND    xbb.edi_interface_status  = cv_edi_if_status_0
      AND    xbb.resv_flag             IS NULL
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u�����b�N�擾
    -- ===============================================
    OPEN  l_bm_lock_cur;
    CLOSE l_bm_lock_cur;
    -- ===============================================
    -- �̎�c���e�[�u���X�V
    -- ===============================================
    UPDATE xxcok_backmargin_balance xbb
    SET    xbb.publication_date        = g_bm_data_tab( in_index ).expect_payment_date  -- �ē���������
         , xbb.edi_interface_date      = gd_process_date                                -- �A�g���iEDI�x���ē����j
         , xbb.edi_interface_status    = cv_edi_if_status_1                             -- �A�g�X�e�[�^�X�iEDI�x���ē����j
         , xbb.last_updated_by         = cn_last_updated_by
         , xbb.last_update_date        = SYSDATE
         , xbb.last_update_login       = cn_last_update_login
         , xbb.request_id              = cn_request_id
         , xbb.program_application_id  = cn_program_application_id
         , xbb.program_id              = cn_program_id
         , xbb.program_update_date     = SYSDATE
    WHERE  xbb.supplier_code           = g_bm_data_tab( in_index ).supplier_code
    AND    xbb.edi_interface_status    = cv_edi_if_status_0
    AND    xbb.resv_flag               IS NULL;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : file_output
   * Description      : �A�g�f�[�^�t�@�C���쐬(A-6)
   ***********************************************************************************/
  PROCEDURE file_output(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_output';    -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg            VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return        BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    lv_out_file_data     VARCHAR2(2000) DEFAULT NULL;              -- �t�@�C���o�͗p�f�[�^
    lv_data_kind         VARCHAR2(2)    DEFAULT NULL;              -- �f�[�^��R�[�h
    lv_from_series       VARCHAR2(2)    DEFAULT NULL;              -- �h�e���Ɩ��n��R�[�h
    lv_dummy_v           VARCHAR2(100)  DEFAULT cv_space;          -- ���ݒ荀�ڗp(����)
    lv_dummy_n           VARCHAR2(100)  DEFAULT cv_0;              -- ���ݒ荀�ڗp(���l)
    -- �o�̓t�@�C���p�ϐ�
    lv_if_data           VARCHAR2(1)    DEFAULT NULL;              -- ���R�[�h�敪
    lv_data_class        VARCHAR2(2)    DEFAULT NULL;              -- �f�[�^���
    lv_cust_code         VARCHAR2(9)    DEFAULT NULL;              -- �ڋq�R�[�h
    lv_counter           VARCHAR2(5)    DEFAULT NULL;              -- �J�E���^
    lv_cust_name1        VARCHAR2(30)   DEFAULT NULL;              -- �ڋq���P
    lv_cust_name2        VARCHAR2(30)   DEFAULT NULL;              -- �ڋq���Q
    lv_atena1            VARCHAR2(30)   DEFAULT NULL;              -- �����P
    lv_atena2            VARCHAR2(30)   DEFAULT NULL;              -- �����Q
    lv_zip               VARCHAR2(8)    DEFAULT NULL;              -- �X�֔ԍ�
    lv_address1          VARCHAR2(30)   DEFAULT NULL;              -- �Z���P
    lv_address2          VARCHAR2(30)   DEFAULT NULL;              -- �Z���Q
    lv_base_name         VARCHAR2(20)   DEFAULT NULL;              -- ���_��
    lv_base_address      VARCHAR2(60)   DEFAULT NULL;              -- ���_�Z��
    lv_base_postal_code  VARCHAR2(8)    DEFAULT NULL;              -- ���_�X�֔ԍ�
    lv_base_phone        VARCHAR2(15)   DEFAULT NULL;              -- ���_�d�b�ԍ�
    lv_years             VARCHAR2(4)    DEFAULT NULL;              -- �N����
    lv_payment_date      VARCHAR2(4)    DEFAULT NULL;              -- �x����
    lv_bank_code         VARCHAR2(4)    DEFAULT NULL;              -- ��s�R�[�h
    lv_bank_name         VARCHAR2(20)   DEFAULT NULL;              -- ��s��
    lv_branch_code       VARCHAR2(4)    DEFAULT NULL;              -- �x�X�R�[�h
    lv_branch_name       VARCHAR2(20)   DEFAULT NULL;              -- �x�X��
    lv_account_type      VARCHAR2(8)    DEFAULT cv_asterisk;       -- �������
    lv_account_number    VARCHAR2(8)    DEFAULT cv_asterisk_half;  -- �����ԍ�
    lv_account_name      VARCHAR2(40)   DEFAULT cv_asterisk_half;  -- ������
    lv_selling_amt_tax   VARCHAR2(11)   DEFAULT NULL;              -- �̔����z���v
    lv_total_prompt1     VARCHAR2(20)   DEFAULT NULL;              -- ���v���o��1
    lv_total_bm1         VARCHAR2(11)   DEFAULT NULL;              -- ���v�萔��1
    lv_total_prompt2     VARCHAR2(20)   DEFAULT NULL;              -- ���v���o��2
    lv_total_bm2         VARCHAR2(11)   DEFAULT NULL;              -- ���v�萔��2
    lv_total_prompt3     VARCHAR2(20)   DEFAULT NULL;              -- ���v���o��3
    lv_total_bm3         VARCHAR2(11)   DEFAULT NULL;              -- ���v�萔��3
    lv_total_prompt4     VARCHAR2(20)   DEFAULT NULL;              -- ���v���o��4
    lv_total_bm4         VARCHAR2(11)   DEFAULT NULL;              -- ���v�萔��4
    lv_total_bm          VARCHAR2(11)   DEFAULT NULL;              -- ���v�̔��萔��
    lv_dtl_prompt1       VARCHAR2(12)   DEFAULT NULL;              -- ���׌��o��1
    lv_dtl_sell_amt1     VARCHAR2(11)   DEFAULT NULL;              -- �̔����z1
    lv_dtl_sell_qty1     VARCHAR2(11)   DEFAULT NULL;              -- �̔��{��1
    lv_dtl_bm1           VARCHAR2(4)    DEFAULT NULL;              -- BM1
    lv_dtl_unit_bm1      VARCHAR2(2)    DEFAULT NULL;              -- BM�P��1
    lv_dtl_total_bm1     VARCHAR2(11)   DEFAULT NULL;              -- �̔��萔��1
    lv_dtl_prompt2       VARCHAR2(12)   DEFAULT NULL;              -- ���׌��o��2
    lv_dtl_sell_amt2     VARCHAR2(11)   DEFAULT NULL;              -- �̔����z2
    lv_dtl_sell_qty2     VARCHAR2(11)   DEFAULT NULL;              -- �̔��{��2
    lv_dtl_bm2           VARCHAR2(4)    DEFAULT NULL;              -- BM2
    lv_dtl_unit_bm2      VARCHAR2(2)    DEFAULT NULL;              -- BM�P��2
    lv_dtl_total_bm2     VARCHAR2(11)   DEFAULT NULL;              -- �̔��萔��2
    lv_dtl_prompt3       VARCHAR2(12)   DEFAULT NULL;              -- ���׌��o��3
    lv_dtl_sell_amt3     VARCHAR2(11)   DEFAULT NULL;              -- �̔����z3
    lv_dtl_sell_qty3     VARCHAR2(11)   DEFAULT NULL;              -- �̔��{��3
    lv_dtl_bm3           VARCHAR2(4)    DEFAULT NULL;              -- BM3
    lv_dtl_unit_bm3      VARCHAR2(2)    DEFAULT NULL;              -- BM�P��3
    lv_dtl_total_bm3     VARCHAR2(11)   DEFAULT NULL;              -- �̔��萔��3
    lv_jpn_calendar      VARCHAR2(4)    DEFAULT NULL;              -- �N��
    lv_reserve           VARCHAR2(53)   DEFAULT NULL;              -- �\��
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** �N�C�b�N�R�[�h�f�[�^�擾�G���[ ***
    no_data_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �w�b�_���R�[�h�擾�E�t�@�C���֏o��(����̂�)
    -- ===============================================
    IF ( gv_header_data IS NULL ) THEN
      BEGIN
        -- ===============================================
        -- �f�[�^��R�[�h�A�h�e���Ɩ��n��R�[�h�擾
        -- ===============================================
        SELECT xlv.meaning       -- �f�[�^��R�[�h
             , xlv.attribute1    -- I/F���Ɩ��n��R�[�h
        INTO   lv_data_kind
             , lv_from_series
        FROM   xxcok_lookups_v xlv
        WHERE  xlv.lookup_type = cv_lookup_type
        AND    xlv.lookup_code = cv_lookup_code_i
        AND    gd_process_date BETWEEN NVL( xlv.start_date_active, gd_process_date )
                               AND     NVL( xlv.end_date_active,   gd_process_date );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                             , iv_name          => cv_msg_xxcok1_00015
                             , iv_token_name1   => cv_token_lookup_value_set
                             , iv_token_value1  => cv_lookup_type
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.OUTPUT
                             , iv_message       => lv_outmsg
                             , in_new_line      => cn_number_0
                             );
          RAISE no_data_expt;
      END;
      -- ===============================================
      -- �w�b�_���R�[�h�擾
      -- ===============================================
      xxccp_ifcommon_pkg.add_edi_header_footer(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_add_area        => cv_add_area_h   -- �t�^�敪
      , iv_from_series     => lv_from_series  -- �h�e���Ɩ��n��R�[�h
      , iv_base_code       => cv_space        -- ���_�R�[�h
      , iv_base_name       => cv_space        -- ���_����
      , iv_chain_code      => cv_space        -- �`�F�[���X�R�[�h
      , iv_chain_name      => cv_space        -- �`�F�[���X����
      , iv_data_kind       => lv_data_kind    -- �f�[�^��R�[�h
      , iv_row_number      => cv_row_number   -- ���񏈗��ԍ�
      , in_num_of_records  => NULL            -- ���R�[�h����
      , ov_output          => gv_header_data  -- �o�͒l
      );
      IF ( lv_retcode   <> cv_status_normal ) THEN
        lv_outmsg       := xxccp_common_pkg.get_msg(
                             iv_application   => cv_appli_short_name_xxcok
                           , iv_name          => cv_msg_xxcok1_10428
                           , iv_token_name1   => cv_data_kind
                           , iv_token_value1  => lv_data_kind
                           , iv_token_name2   => cv_from_series
                           , iv_token_value2  => lv_from_series
                           );
        lb_msg_return   := xxcok_common_pkg.put_message_f(
                             in_which         => FND_FILE.OUTPUT
                           , iv_message       => lv_outmsg
                           , in_new_line      => cn_number_0
                           );
        RAISE global_api_expt;
      END IF;
      -- ===============================================
      -- �w�b�_���R�[�h���t�@�C���ɏo��
      -- ===============================================
      UTL_FILE.PUT_LINE(
        file      => g_file_handle
      , buffer    => gv_header_data
      );
    END IF;
    -- ===============================================
    -- �J�E���^
    -- ===============================================
    gn_cnt := gn_cnt + cn_number_1;
    -- ===============================================
    -- �ϐ��Ƀf�[�^�i�[
    -- ===============================================
    lv_if_data           :=  gv_if_data;        -- ���R�[�h�敪
    lv_data_class        :=  gv_i_data_class;   -- �f�[�^���
    lv_cust_code         :=  LPAD( g_bm_data_tab( in_index ).supplier_code, 9, cv_0 );                             -- �ڋq�R�[�h
    lv_counter           :=  LPAD( TO_CHAR( gn_cnt ), 5, cv_0 );                                                   -- �J�E���^
    lv_cust_name1        :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- �ڋq���P
    lv_cust_name2        :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- �ڋq���Q
    lv_atena1            :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- �����P
    lv_atena2            :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- �����Q
    lv_zip               :=  RPAD( NVL( g_bm_data_tab( in_index ).zip, cv_space ), 8, cv_space );                  -- �X�֔ԍ�
    lv_address1          :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).address1, cv_space ), 30, cv_space ) , 1, 30 );      -- �Z���P
    lv_address2          :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).address2, cv_space ), 30, cv_space ) , 1, 30 );      -- �Z���Q
    lv_base_name         :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).base_name, cv_space ), 20, cv_space ) , 1, 20 );     -- ���_��
    lv_base_address      :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).base_address, cv_space ), 60, cv_space ) , 1, 60 );  -- ���_�Z��
    lv_base_postal_code  :=  RPAD( NVL( g_bm_data_tab( in_index ).base_postal_code, cv_space ), 8, cv_space );     -- ���_�X�֔ԍ�
    lv_base_phone        :=  RPAD( NVL( g_bm_data_tab( in_index ).base_phone, cv_space ), 15, cv_space );          -- ���_�d�b�ԍ�
    lv_years             :=  g_bm_data_tab( in_index ).years;                -- �N����
    lv_payment_date      :=  g_bm_data_tab( in_index ).payment_month_date;   -- �x����
    lv_bank_code         :=  LPAD( NVL( g_bm_data_tab( in_index ).bank_number, cv_0 ), 4, cv_0 );                  -- ��s�R�[�h
    lv_bank_name         :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).bank_name, 20, cv_space ) , 1, 20 );         -- ��s��
    lv_branch_code       :=  LPAD( NVL( g_bm_data_tab( in_index ).bank_num, cv_0 ), 4, cv_0 );                     -- �x�X�R�[�h
    lv_branch_name       :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).bank_branch_name, 20, cv_space ) , 1, 20 );  -- �x�X��
    lv_account_type      :=  SUBSTRB( RPAD( lv_account_type, 8, cv_asterisk ) , 1, 8 );                            -- �������
    lv_account_number    :=  SUBSTRB( RPAD( lv_account_number, 8, cv_asterisk_half ) , 1, 8 );                     -- �����ԍ�
    lv_account_name      :=  SUBSTRB( RPAD( lv_account_name, 40, cv_asterisk_half ) , 1, 40 );                     -- ������
    lv_selling_amt_tax   :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).selling_amt_tax ), cv_0 ), 11, cv_0 );  -- �̔����z���v
    -- �̔��萔����0�̏ꍇ�A1�ɓd�C�����Z�b�g��2�͖��ݒ�
    IF ( g_bm_data_tab( in_index ).backmargin = cn_number_0 ) THEN
      lv_total_prompt1   :=  SUBSTRB( RPAD( gv_prompt_ep, 20, cv_space ) , 1, 20 );                             -- ���v���o��1(�d�C)
      lv_total_bm1       :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).electric_amt ), cv_0 ), 11, cv_0 );  -- ���v�萔��1
      lv_total_prompt2   :=  RPAD( lv_dummy_v, 20, cv_space );        -- ���v���o��2
      lv_total_bm2       :=  LPAD( lv_dummy_n, 11, cv_0 );            -- ���v�萔��2
    ELSE
      lv_total_prompt1   :=  SUBSTRB( RPAD( gv_prompt_bm, 20, cv_space ) , 1, 20 );                             -- ���v���o��1(�̔��萔��)
      lv_total_bm1       :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).backmargin ), cv_0 ), 11, cv_0 );    -- ���v�萔��1
      -- �d�C����0�̏ꍇ�A2�͖��ݒ�
      IF ( g_bm_data_tab( in_index ).electric_amt = cn_number_0 ) THEN
        lv_total_prompt2 :=  RPAD( lv_dummy_v, 20, cv_space );        -- ���v���o��2
        lv_total_bm2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- ���v�萔��2
      ELSE
        lv_total_prompt2 :=  SUBSTRB( RPAD( gv_prompt_ep, 20, cv_space ) , 1, 20 );                             -- ���v���o��2(�d�C)
        lv_total_bm2     :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).electric_amt ), cv_0 ), 11, cv_0 );  -- ���v�萔��2
      END IF;
    END IF;
    lv_total_prompt3     :=  RPAD( lv_dummy_v, 20, cv_space );        -- ���v���o��3
    lv_total_bm3         :=  LPAD( lv_dummy_n, 11, cv_0 );            -- ���v�萔��3
    lv_total_prompt4     :=  RPAD( lv_dummy_v, 20, cv_space );        -- ���v���o��4
    lv_total_bm4         :=  LPAD( lv_dummy_n, 11, cv_0 );            -- ���v�萔��4
    lv_total_bm          :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).expect_payment_amt_tax ), cv_0 ), 11, cv_0 );  -- ���v�̔��萔��
    lv_dtl_prompt1       :=  RPAD( lv_dummy_v, 12, cv_space );        -- ���׌��o��1
    lv_dtl_sell_amt1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔����z1
    lv_dtl_sell_qty1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��{��1
    lv_dtl_bm1           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM1
    lv_dtl_unit_bm1      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM�P��1
    lv_dtl_total_bm1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��萔��1
    lv_dtl_prompt2       :=  RPAD( lv_dummy_v, 12, cv_space );        -- ���׌��o��2
    lv_dtl_sell_amt2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔����z2
    lv_dtl_sell_qty2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��{��2
    lv_dtl_bm2           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM2
    lv_dtl_unit_bm2      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM�P��2
    lv_dtl_total_bm2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��萔��2
    lv_dtl_prompt3       :=  RPAD( lv_dummy_v, 12, cv_space );        -- ���׌��o��3
    lv_dtl_sell_amt3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔����z3
    lv_dtl_sell_qty3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��{��3
    lv_dtl_bm3           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM3
    lv_dtl_unit_bm3      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM�P��3
    lv_dtl_total_bm3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- �̔��萔��3
    lv_jpn_calendar      :=  g_bm_data_tab( in_index ).jpn_calendar;  -- �N��
    lv_reserve           :=  RPAD( lv_dummy_v, 53, cv_space );        -- �\��
    -- ===============================================
    -- �t�@�C���o�̓f�[�^�i�[
    -- ===============================================
    lv_out_file_data := lv_if_data           -- ���R�[�h�敪
                 ||     lv_data_class        -- �f�[�^���
                 ||     lv_cust_code         -- �ڋq�R�[�h
                 ||     lv_counter           -- �J�E���^
                 ||     lv_cust_name1        -- �ڋq���P
                 ||     lv_cust_name2        -- �ڋq���Q
                 ||     lv_atena1            -- �����P
                 ||     lv_atena2            -- �����Q
                 ||     lv_zip               -- �X�֔ԍ�
                 ||     lv_address1          -- �Z���P
                 ||     lv_address2          -- �Z���Q
                 ||     lv_base_name         -- ���_��
                 ||     lv_base_address      -- ���_�Z��
                 ||     lv_base_postal_code  -- ���_�X�֔ԍ�
                 ||     lv_base_phone        -- ���_�d�b�ԍ�
                 ||     lv_years             -- �N����
                 ||     lv_payment_date      -- �x����
                 ||     lv_bank_code         -- ��s�R�[�h
                 ||     lv_bank_name         -- ��s��
                 ||     lv_branch_code       -- �x�X�R�[�h
                 ||     lv_branch_name       -- �x�X��
                 ||     lv_account_type      -- �������
                 ||     lv_account_number    -- �����ԍ�
                 ||     lv_account_name      -- ������
                 ||     lv_selling_amt_tax   -- �̔����z���v
                 ||     lv_total_prompt1     -- ���v���o��1
                 ||     lv_total_bm1         -- ���v�萔��1
                 ||     lv_total_prompt2     -- ���v���o��2
                 ||     lv_total_bm2         -- ���v�萔��2
                 ||     lv_total_prompt3     -- ���v���o��3
                 ||     lv_total_bm3         -- ���v�萔��3
                 ||     lv_total_prompt4     -- ���v���o��4
                 ||     lv_total_bm4         -- ���v�萔��4
                 ||     lv_total_bm          -- ���v�̔��萔��
                 ||     lv_dtl_prompt1       -- ���׌��o��1
                 ||     lv_dtl_sell_amt1     -- �̔����z1
                 ||     lv_dtl_sell_qty1     -- �̔��{��1
                 ||     lv_dtl_bm1           -- BM1
                 ||     lv_dtl_unit_bm1      -- BM�P��1
                 ||     lv_dtl_total_bm1     -- �̔��萔��1
                 ||     lv_dtl_prompt2       -- ���׌��o��2
                 ||     lv_dtl_sell_amt2     -- �̔����z2
                 ||     lv_dtl_sell_qty2     -- �̔��{��2
                 ||     lv_dtl_bm2           -- BM2
                 ||     lv_dtl_unit_bm2      -- BM�P��2
                 ||     lv_dtl_total_bm2     -- �̔��萔��2
                 ||     lv_dtl_prompt3       -- ���׌��o��3
                 ||     lv_dtl_sell_amt3     -- �̔����z3
                 ||     lv_dtl_sell_qty3     -- �̔��{��3
                 ||     lv_dtl_bm3           -- BM3
                 ||     lv_dtl_unit_bm3      -- BM�P��3
                 ||     lv_dtl_total_bm3     -- �̔��萔��3
                 ||     lv_jpn_calendar      -- �N��
                 ||     lv_reserve           -- �\��
    ;
    -- ===============================================
    -- �t�@�C���ɏo��
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
  EXCEPTION
    -- *** �N�C�b�N�R�[�h�f�[�^�擾�G���[***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_output;
--
  /**********************************************************************************
   * Procedure Name   : check_bm_data
   * Description      : �A�g�f�[�^�Ó����`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'check_bm_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    lb_chk_return   BOOLEAN        DEFAULT TRUE;              -- �`�F�b�N���ʖ߂�l�p
    ln_chk_length   NUMBER         DEFAULT 0;                 -- ���l�����`�F�b�N�p
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �d���於 �S�p�`�F�b�N(�ڋq���P�E�ڋq���Q�E����1�E����2)
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).vendor_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10430
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- �Z��1 �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).address1
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- �Z��2 �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).address2
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ���_�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).base_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10432
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ���_�Z�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).base_address
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10433
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ��s�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).bank_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10434
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ��s�x�X�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).bank_branch_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10435
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- �X�֔ԍ� ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).zip
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10436
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ���_�X�֔ԍ� ���p�p�����`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).base_postal_code
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10437
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- ���_�d�b�ԍ� ���p�p�����`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).base_phone
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10438
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- �d����R�[�h �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).supplier_code );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10439
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- �X�֔ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).zip );
    IF ( ln_chk_length > cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10440
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- ���_�X�֔ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).base_postal_code );
    IF ( ln_chk_length > cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10441
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- ���_�d�b�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).base_phone );
    IF ( ln_chk_length > cn_number_15 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10442
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- ��s�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).bank_number );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10443
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- ��s�x�X�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).bank_num );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10444
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- �̔����z���v �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).selling_amt_tax );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10445
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- �̔��萔�� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).backmargin );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10446
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- �d�C�� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).electric_amt );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10447
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- �x���\��z �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).expect_payment_amt_tax );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10448
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END check_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : check_bm_amt
   * Description      : �̎�c�������z�`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE check_bm_amt(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'check_bm_amt';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    ln_bank_fee     NUMBER         DEFAULT NULL;              -- ��s�萔���z
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** �A�g�Ώۃ`�F�b�N��O ***
    check_warn_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��s�萔���x���Ώۃ`�F�b�N
    -- ===============================================
    IF ( g_bm_data_tab( in_index ).bank_charge_bearer = cv_bank_charge_bearer ) THEN
      -- ===============================================
      -- �x���\��z(�ō�)����s�萔���z�ݒ�
      -- ===============================================
      IF ( g_bm_data_tab( in_index ).expect_payment_amt_tax     < TO_NUMBER( gv_bank_fee_trans ) ) THEN
        ln_bank_fee := TO_NUMBER( gv_bank_fee_less );
      ELSIF ( g_bm_data_tab( in_index ).expect_payment_amt_tax >= TO_NUMBER( gv_bank_fee_trans ) ) THEN
        ln_bank_fee := TO_NUMBER( gv_bank_fee_more );
      END IF;
      -- ===============================================
      -- ��s�萔���z�ɏ���Ŋz�t�^
      -- ===============================================
      ln_bank_fee := ln_bank_fee + ln_bank_fee * ( TO_NUMBER( gv_bm_tax ) / 100 );
    ELSE
      ln_bank_fee := cn_number_0;
    END IF;
    -- ===============================================
    -- �x���\��z(�ō�)�����s�萔���z�����������z��0�~�ȉ��`�F�b�N
    -- ===============================================
    IF ( g_bm_data_tab( in_index ).expect_payment_amt_tax - ln_bank_fee <= cn_number_0 ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_10009
                       , iv_token_name1   => cv_token_conn_loc
                       , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                       , iv_token_name2   => cv_token_vendor_code
                       , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                       , iv_token_name3   => cv_token_close_date
                       , iv_token_value3  => TO_CHAR( g_bm_data_tab( in_index ).closing_date, cv_format_yyyy_mm_dd )
                       , iv_token_name4   => cv_token_due_date
                       , iv_token_value4  => TO_CHAR( g_bm_data_tab( in_index ).expect_payment_date, cv_format_yyyy_mm_dd )
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE check_warn_expt;
    END IF;
    -- ===============================================
    -- �A�g�f�[�^�Ó����`�F�b�N(A-5)
    -- ===============================================
    check_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode    = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE check_warn_expt;
    END IF;
    -- ===============================================
    -- �A�g�f�[�^�t�@�C���쐬(A-6)
    -- ===============================================
    file_output(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �A�g�Ώۃf�[�^�X�V(A-7)
    -- ===============================================
    update_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** �A�g�Ώۃ`�F�b�N��O ***
    WHEN check_warn_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END check_bm_amt;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_data
   * Description      : �A�g�Ώ۔̎�c�����擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bm_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �J�[�\��
    -- ===============================================
    OPEN  g_bm_data_cur;
    FETCH g_bm_data_cur BULK COLLECT INTO g_bm_data_tab;
    CLOSE g_bm_data_cur;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v��(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_open';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    lb_fexist       BOOLEAN        DEFAULT FALSE;             -- �t�@�C�����݃`�F�b�N����
    ln_file_length  NUMBER         DEFAULT NULL;              -- �t�@�C���̒���
    ln_block_size   NUMBER         DEFAULT NULL;              -- �u���b�N�T�C�Y
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �t�@�C�����݃`�F�b�N
    -- ===============================================
    UTL_FILE.FGETATTR(
      location     => gv_i_dire_path  -- �f�B���N�g��
    , filename     => gv_i_file_name  -- �t�@�C����
    , fexists      => lb_fexist       -- True:�t�@�C�����݁AFalse:�t�@�C�����݂Ȃ�
    , file_length  => ln_file_length  -- �t�@�C���̒���
    , block_size   => ln_block_size   -- �u���b�N�T�C�Y
    );
    IF ( lb_fexist ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00009
                       , iv_token_name1   => cv_token_file_name
                       , iv_token_value1  => gv_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE check_file_expt;
    END IF;
    -- ===============================================
    -- �t�@�C���I�[�v��
    -- ===============================================
    g_file_handle := UTL_FILE.FOPEN(
                       gv_i_dire_path   -- �f�B���N�g��
                     , gv_i_file_name   -- �t�@�C����
                     , cv_open_mode_w   -- �t�@�C���I�[�v�����@
                     , cn_max_linesize  -- 1�s����ő啶����
                     );
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'init';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���o��
    -- ===============================================
    lv_outmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90008
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_outmsg
                     , in_new_line     => cn_number_1
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                     , iv_message      => lv_outmsg
                     , in_new_line     => cn_number_2
                     );
    -- ===============================================
    -- �Ɩ��������t�擾
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                       , iv_name         => cv_msg_xxcok1_00028
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�x���ē���_�C�Z�g�[_�f�B���N�g���p�X)
    -- ===============================================
    gv_i_dire_path  := FND_PROFILE.VALUE( cv_prof_i_dire_path );
    IF ( gv_i_dire_path IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_dire_path
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�x���ē���_�C�Z�g�[_�t�@�C����)
    -- ===============================================
    gv_i_file_name  := FND_PROFILE.VALUE( cv_prof_i_file_name );
    IF ( gv_i_file_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�x���ē���_�C�Z�g�[_�f�[�^���)
    -- ===============================================
    gv_i_data_class := FND_PROFILE.VALUE( cv_prof_i_data_class );
    IF ( gv_i_data_class IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_data_class
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�x���ē���_�̔��萔�����o��)
    -- ===============================================
    gv_prompt_bm    := FND_PROFILE.VALUE( cv_prof_prompt_bm );
    IF ( gv_prompt_bm IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_prompt_bm
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�x���ē���_�d�C�����o��)
    -- ===============================================
    gv_prompt_ep    := FND_PROFILE.VALUE( cv_prof_prompt_ep );
    IF ( gv_prompt_ep IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_prompt_ep
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔��_�U���z�)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_outmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                          , iv_name          => cv_msg_xxcok1_00003
                          , iv_token_name1   => cv_token_profile
                          , iv_token_value1  => cv_prof_bank_fee_trans
                          );
      lb_msg_return    := xxcok_common_pkg.put_message_f(
                            in_which         => FND_FILE.OUTPUT
                          , iv_message       => lv_outmsg
                          , in_new_line      => cn_number_0
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔��_��z����)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bank_fee_less
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(��s�萔��_��z�ȏ�)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bank_fee_more
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�̔��萔��_����ŗ�)
    -- ===============================================
    gv_bm_tax         := FND_PROFILE.VALUE( cv_prof_bm_tax );
    IF ( gv_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(IF���R�[�h�敪_�f�[�^)
    -- ===============================================
    gv_if_data        := FND_PROFILE.VALUE( cv_prof_if_data );
    IF ( gv_if_data IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_if_data
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�c�ƒP��ID)
    -- ===============================================
    gn_org_id         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_org_id
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �f�B���N�g���o��
    -- ===============================================
    lv_outmsg      := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appli_short_name_xxcok
                      , iv_name          => cv_msg_xxcok1_00067
                      , iv_token_name1   => cv_token_directory
                      , iv_token_value1  => xxcok_common_pkg.get_directory_path_f( gv_i_dire_path )
                      );
    lb_msg_return  := xxcok_common_pkg.put_message_f(
                        in_which         => FND_FILE.OUTPUT
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_0
                      );
    -- ===============================================
    -- �t�@�C�����o��
    -- ===============================================
    lv_outmsg      := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appli_short_name_xxcok
                      , iv_name          => cv_msg_xxcok1_00006
                      , iv_token_name1   => cv_token_file_name
                      , iv_token_value1  => gv_i_file_name
                      );
    lb_msg_return  := xxcok_common_pkg.put_message_f(
                        in_which         => FND_FILE.OUTPUT
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_1
                      );
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- �Œ胍�[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'submain';
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �t�@�C���I�[�v��(A-2)
    -- ===============================================
    file_open(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �A�g�Ώ۔̎�c�����擾(A-3)
    -- ===============================================
    get_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_file_close_expt;
    END IF;
    -- ===============================================
    -- �Ώی����擾
    -- ===============================================
    gn_target_cnt := g_bm_data_tab.COUNT;
    IF ( gn_target_cnt > 0 ) THEN
      << bm_data_loop >>
      FOR i IN g_bm_data_tab.FIRST .. g_bm_data_tab.LAST LOOP
        -- ===============================================
        -- �̎�c�������z�`�F�b�N(A-4)�A�A�g�f�[�^�Ó����`�F�b�N(A-5)�A�A�g�f�[�^�t�@�C���쐬(A-6)�A�A�g�Ώۃf�[�^�X�V(A-7)
        -- ===============================================
        check_bm_amt(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        , in_index    => i
        );
        IF ( lv_retcode    = cv_status_error ) THEN
          RAISE global_process_file_close_expt;
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + cn_number_1;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_skip_cnt   := gn_skip_cnt   + cn_number_1;
        END IF;
      END LOOP bm_data_loop;
      -- ===============================================
      -- �������������݂���ꍇ�A�t�b�^���R�[�h�擾(A-8)
      -- ===============================================
      IF ( gn_normal_cnt > cn_number_0 ) THEN
        get_footer_data(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        );
        IF ( lv_retcode    = cv_status_error ) THEN
          RAISE global_process_file_close_expt;
        END IF;
      END IF;
    END IF;
    -- ===============================================
    -- �t�@�C���N���[�Y(A-9)
    -- ===============================================
    file_close(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- �X�L�b�v���������݂���ꍇ�A�X�e�[�^�X�x��
    -- ===============================================
    IF ( gn_skip_cnt > cn_number_0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O(�t�@�C���N���[�Y) ***
    WHEN global_process_file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2
  , retcode  OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20)  := 'main';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�G���[���b�Z�[�W
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;              -- ���b�Z�[�W�ϐ�
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- ���b�Z�[�W�R�[�h
    lb_msg_return    BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT
                       , iv_message    => lv_errmsg
                       , in_new_line   => cn_number_1
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                       , iv_message    => lv_errbuf
                       , in_new_line   => cn_number_0
                       );
    END IF;
    -- ===============================================
    -- �x����������s�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT
                       , iv_message    => NULL
                       , in_new_line   => cn_number_1
                       );
    END IF;
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90000
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_target_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- ���������o��(�G���[������0��)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90001
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := cn_number_1;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90002
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- �X�L�b�v�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90003
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_skip_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_1
                     );
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => lv_message_code
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK015A01C;
/
