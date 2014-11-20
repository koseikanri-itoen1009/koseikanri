CREATE OR REPLACE PACKAGE BODY XXCOK015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A01C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : EDI�V�X�e���ɂăC�Z�g�[�Ђ֑��M����x���ē���(�����͂���)�p�f�[�^�t�@�C���쐬
 * Version          : 2.4
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  �t�@�C���N���[�Y(A-8)
 *  upd_bm_data                 �A�g�Ώۃf�[�^�X�V(A-7)
 *  put_record                  �A�g�f�[�^�o��(A-6)
 *  chk_bm_data                 �A�g�f�[�^�Ó����`�F�b�N(A-5)
 *  get_bank_fee                ��s�U���萔���擾(A-4)
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
 *  2009/05/22    1.3   M.Hiruta         [��QT1_1144] �t�b�^���R�[�h�쐬���Ƀf�[�^��R�[�h���g�p����悤�ύX
 *  2009/07/01    1.4   M.Hiruta         [��Q0000289] �p�t�H�[�}���X����̂��߃f�[�^���o���@��ύX
 *  2009/07/10    1.5   M.Hiruta         [��Q0000498] �w�b�_�f�[�^�擾���ʊ֐��֗^����`�F�[���X�R�[�h��ύX
 *  2009/07/15    1.6   K.Yamaguchi      [��Q0000688] ����2�s�ڂ��C��
 *  2009/08/24    1.7   T.Taniguchi      [��Q0001160] �ڋq���Q�A�����Q�̕ҏW�C��
 *  2009/09/19    2.0   S.Moriyama       [��Q0001309] �ύX�Ǘ��ԍ�I_E_540�Ή��i��ʓ��󖾍׏o�́j
 *  2009/10/14    2.1   S.Moriyama       [�ύX�˗�I_E_573] �����A�Z���̎擾����ύX
 *  2009/11/16    2.2   S.Moriyama       [�ύX�˗�I_E_665] �X�֔ԍ���7���n�C�t���Ȃ�����n�C�t������֕ύX
 *  2009/12/15    2.3   K.Nakamura       [��QE_�{�ғ�_00427] ��s�U���萔���̎Z�o��ύX
 *  2010/01/06    2.4   K.Yamaguchi      [E_�{�ғ�_00901] ���ߓ��̔�����@�C��
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
  cv_msg_xxcok1_00027        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00027';  -- �c�Ɠ��t�擾�G���[
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok1_00036        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00036';  -- ���߁E�x�����擾�G���[
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00053';  -- �̎�c���e�[�u�����b�N�擾�G���[
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00067';  -- �f�B���N�g���o��
  cv_msg_xxcok1_10009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10009';  -- �x�����z0�~�ȉ��x��
  cv_msg_xxcok1_10430        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10430';  -- �����S�p�`�F�b�N�x��
  cv_msg_xxcok1_10431        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10431';  -- �d����Z���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10434';  -- ��s���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10435';  -- ��s�x�X���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10436        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10436';  -- �X�֔ԍ����p�p�����L���`�F�b�N�x��
  cv_msg_xxcok1_10439        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10439';  -- �d����R�[�h�����`�F�b�N�x��
  cv_msg_xxcok1_10440        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10440';  -- �X�֔ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10441        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10441';  -- ���_�X�֔ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10442        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10442';  -- ���_�d�b�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10443        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10443';  -- ��s�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10444        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10444';  -- ��s�x�X�ԍ������`�F�b�N�x��
  cv_msg_xxcok1_10445        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10445';  -- �̔����z���v�����`�F�b�N�x��
  cv_msg_xxcok1_10446        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10446';  -- �̔��萔�������`�F�b�N�x��
  cv_msg_xxcok1_10459        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10459';  -- �d����R�[�h���p�`�F�b�N�x��
  cv_msg_xxcok1_10460        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10460';  -- ��s�R�[�h���p�`�F�b�N�x��
  cv_msg_xxcok1_10461        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10461';  -- �x�X�R�[�h���p�`�F�b�N�x��
  cv_msg_xxcok1_10462        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10462';  -- ���������p�`�F�b�N�x��
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
  cv_token_conn_zip          CONSTANT VARCHAR2(20)    := 'CONN_LOC_ZIP';
  cv_token_conn_phone        CONSTANT VARCHAR2(20)    := 'CONN_LOC_PHONE';
  cv_token_vendor_code       CONSTANT VARCHAR2(20)    := 'VENDOR_CODE';
  cv_token_vendor_name       CONSTANT VARCHAR2(20)    := 'VENDOR_NAME';
  cv_token_vendor_addr       CONSTANT VARCHAR2(20)    := 'VENDOR_ADDRESS';
  cv_token_vendor_zip        CONSTANT VARCHAR2(20)    := 'VENDOR_ZIP';
  cv_token_bank_code         CONSTANT VARCHAR2(20)    := 'BANK_CODE';
  cv_token_bank_name         CONSTANT VARCHAR2(20)    := 'BANK_NAME';
  cv_token_bank_branch_code  CONSTANT VARCHAR2(20)    := 'BANK_BRANCH_CODE';
  cv_token_bank_branch_name  CONSTANT VARCHAR2(20)    := 'BANK_BRANCH_NAME';
  cv_token_bank_holder_name  CONSTANT VARCHAR2(20)    := 'BANK_HOLDER_NAME_ALT';
  cv_token_sales_amount      CONSTANT VARCHAR2(20)    := 'SALES_AMOUNT';
  cv_token_vdbm_amount       CONSTANT VARCHAR2(20)    := 'VDBM_AMOUNT';
  cv_token_close_date        CONSTANT VARCHAR2(20)    := 'CLOSE_DATE';
  cv_token_due_date          CONSTANT VARCHAR2(20)    := 'DUE_DATE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)    := 'LOOKUP_VALUE_SET';
  cv_data_kind               CONSTANT VARCHAR2(20)    := 'DATA_KIND';
  cv_from_series             CONSTANT VARCHAR2(20)    := 'FROM_SERIES';
  cv_token_count             CONSTANT VARCHAR2(20)    := 'COUNT';
  cv_token_vendor_count      CONSTANT VARCHAR2(20)    := 'VEN_CNT';
  -- �v���t�@�C��
  cv_prof_i_dire_path        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DIRE_PATH';     -- �C�Z�g�[_�f�B���N�g���p�X
  cv_prof_i_file_name        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_FILE_NAME';     -- �C�Z�g�[_�t�@�C����
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE START
--  cv_prof_suport_period_to   CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- �̎�̋��v�Z�������ԁiTo�j
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE END
  cv_prof_term_name          CONSTANT VARCHAR2(40)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- �f�t�H���g�x������
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- ��s�萔��_�U���z�
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- ��s�萔��_��z����
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- ��s�萔��_��z�ȏ�
  cv_prof_bm_tax             CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_TAX';                    -- �̔��萔��_����ŗ�
  cv_prof_edi_data_type_head CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_HEAD';  -- XXCOK:�C�Z�g�[EDI�f�[�^�敪_�w�b�_
  cv_prof_edi_data_type_line CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_LINE';  -- XXCOK:�C�Z�g�[EDI�f�[�^�敪_����
  cv_prof_edi_data_type_fee  CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_FEE';   -- XXCOK:�C�Z�g�[EDI�f�[�^�敪_�萔��
  cv_prof_edi_data_type_sum  CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_SUM';   -- XXCOK:�C�Z�g�[EDI�f�[�^�敪_���v
  cv_prof_org_id             CONSTANT VARCHAR2(40)    := 'ORG_ID';                           -- �g�DID
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- ���l
  cn_number_0                CONSTANT NUMBER          := 0;
  cn_number_1                CONSTANT NUMBER          := 1;
  cn_number_2                CONSTANT NUMBER          := 2;
  cn_number_3                CONSTANT NUMBER          := 3;
  cn_number_4                CONSTANT NUMBER          := 4;
  cn_number_7                CONSTANT NUMBER          := 7;
  cn_number_9                CONSTANT NUMBER          := 9;
  cn_number_11               CONSTANT NUMBER          := 11;
  cn_number_15               CONSTANT NUMBER          := 15;
  cn_number_100              CONSTANT NUMBER          := 100;
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
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';                   -- �e�L�X�g�̏�����
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;                 -- 1�s����ő啶����
  -- �A�g�X�e�[�^�X�iEDI�x���ē����j
  cv_edi_if_status_0         CONSTANT VARCHAR2(1)     := '0';                   -- ������
  cv_edi_if_status_1         CONSTANT VARCHAR2(1)     := '1';                   -- ������
  -- BM�x���敪
  cv_bm_pay_class_1          CONSTANT VARCHAR2(1)     := '1';                   -- �{�U(�ē��L)
  cv_bm_pay_class_2          CONSTANT VARCHAR2(1)     := '2';                   -- �{�U(�ē���)
  -- ���s�t���O
  cv_primary_flag            CONSTANT VARCHAR2(1)     := 'Y';                   -- ���s
  -- ��s�萔�����S��
  cv_bank_charge_bearer      CONSTANT VARCHAR2(1)     := 'I';                   -- ����
  -- �L���t���O
  cv_enabled_flag            CONSTANT VARCHAR2(1)     := 'Y';                   -- �L��
  -- �Q�ƃ^�C�v
  cv_lookup_type             CONSTANT VARCHAR2(30)    := 'XXCOK1_ISETO_IF_COLUMN_NAME'; -- CSV�w�b�_
  -- ��؂蕶��
  cv_separator_char          CONSTANT VARCHAR2(1)     := CHR(9);                -- �^�u��؂�
  -- �G���[�A�g����
  cv_edi_output_error_kbn    CONSTANT VARCHAR2(10)    := '�~';                  -- �G���[
  -- �X�֔ԍ���؂�
  cv_zip_separator_char      CONSTANT VARCHAR2(1)     := '-';                   -- �X�֔ԍ��n�C�t��
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD START
  cv_fix_status              CONSTANT VARCHAR2(1)     := '1';                   -- ���z�m��X�e�[�^�X�F�m��
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD END
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT cn_number_0;                        -- �Ώی���
  gn_normal_cnt              NUMBER DEFAULT cn_number_0;                        -- ���팏��
  gn_error_cnt               NUMBER DEFAULT cn_number_0;                        -- �G���[����
  gn_skip_cnt                NUMBER DEFAULT cn_number_0;                        -- �X�L�b�v����
  gd_process_date            DATE   DEFAULT NULL;                               -- �Ɩ��������t
  gd_operating_date          DATE   DEFAULT NULL;                               -- �c�Ɠ�(�A�g�Ώے��ߓ�)
  gd_close_date              DATE   DEFAULT NULL;                               -- ���ߓ�
  gd_schedule_date           DATE   DEFAULT NULL;                               -- �x���\���
  gd_pay_date                DATE   DEFAULT NULL;                               -- �x����
  gv_prof_org_id             VARCHAR2(40) DEFAULT NULL;                         -- �g�DID
  gv_i_dire_path             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �C�Z�g�[_�f�B���N�g���p�X
  gv_i_file_name             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �C�Z�g�[_�t�@�C����
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE START
--  gv_bm_period_to            fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �̎�̋��v�Z�������ԁiTo�j
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE END
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �x������
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_�U���z�
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z����
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z�ȏ�
  gn_bm_tax                  NUMBER;                                            -- �̔��萔��_����ŗ�
  gn_tax_include_less        NUMBER;                                            -- �ō���s�萔��_��z����
  gn_tax_include_more        NUMBER;                                            -- �ō���s�萔��_��z�ȏ�
  gn_bank_fee                NUMBER;                                            -- ��s�萔���i�ō��j
  g_file_handle              UTL_FILE.FILE_TYPE;                                -- �t�@�C���n���h��
  gv_data_type_addr          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �������
  gv_data_type_line          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ���׏��
  gv_data_type_fee           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �U����
  gv_data_type_total         fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ���v���
--
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  CURSOR g_bm_data_cur
  IS
    SELECT /*+ INDEX( xbb, xxcok_backmargin_balance_n05 )
               LEADING( xbb , pv , pvs , cntct_hca , cntct_hp , cntct_hcas , cntct_hps ) */
           xbb.supplier_code               AS payee_code                        -- �y�x����z�d����R�[�h
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , pv.vendor_name                  AS payee_name                        -- �y�x����z����
         , pvs.attribute1                  AS payee_name                        -- �y�x����z����
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
         , pvs.zip                         AS payee_zip                         -- �y�x����z�X�֔ԍ�
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--         , pvs.city          ||
--           pvs.address_line1 ||
--           pvs.address_line2               AS payee_address                     -- �y�x����z�Z��
         , pvs.address_line1 ||
           pvs.address_line2               AS payee_address                     -- �y�x����z�Z��
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
         , pvs.attribute5                  AS cntct_base_code                   -- �y�⍇���z���_�R�[�h
         , cntct_hp.party_name             AS cntct_base_name                   -- �y�⍇���z���_��
         , cntct_hl.city     ||
           cntct_hl.address1 ||
           cntct_hl.address2               AS cntct_base_address                -- �y�⍇���z���_�Z��
         , cntct_hl.postal_code            AS cntct_base_zip                    -- �y�⍇���z���_�X�֔ԍ�
         , cntct_hl.address_lines_phonetic AS cntct_base_phone                  -- �y�⍇���z���_�d�b�ԍ�
         , cntct_hl.address3               AS cntct_base_area_code              -- �y�⍇���z�n��R�[�h
         , abb.bank_number                 AS payee_bank_number                 -- �y�x����z��s�R�[�h
         , abb.bank_name                   AS payee_bank_name                   -- �y�x����z��s��
         , abb.bank_num                    AS payee_bank_branch_num             -- �y�x����z�x�X�R�[�h
         , abb.bank_branch_name            AS payee_bank_branch_name            -- �y�x����z�x�X��
         , aba.account_holder_name_alt     AS payee_bank_holder_name_alt        -- �y�x����z������
         , pvs.bank_charge_bearer          AS payee_bank_charge_bearer          -- �y�x����z�U���萔��
         , pvs.attribute4                  AS payee_bm_pay_class                -- �y�x����zBM�x���敪
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN cn_number_0
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN cn_number_0
                       ELSE xbb.selling_amt_tax
                     END )
              , cn_number_0 )                        AS selling_amt_tax         -- �̔����z
         , NVL( SUM( xbb.selling_amt_tax )
              , cn_number_0 )                        AS total_selling_amt_tax   -- �̔����z�̍��v
         , NVL( SUM( xbb.expect_payment_amt_tax )
              , cn_number_0 )                        AS total_payment_amt_tax   -- �萔�����z�̍��v
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN xbb.expect_payment_amt_tax
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN xbb.expect_payment_amt_tax
                       ELSE cn_number_0
                     END )
              , cn_number_0 )                        AS reserve_amt_tax         -- �x���ۗ����z
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN cn_number_0
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN cn_number_0
                       ELSE xbb.expect_payment_amt_tax
                     END )
              , cn_number_0 )                        AS payment_amt_tax         -- �萔�����z
         , MIN( xbb.closing_date )         AS closing_date_start                -- �Ώے��ߓ�(��)
         , MAX( xbb.closing_date )         AS closing_date_end                  -- �Ώے��ߓ�(��)
         , MIN( xbb.expect_payment_date )  AS expect_payment_date_start         -- �Ώێx���\���(��)
         , MAX( xbb.expect_payment_date )  AS expect_payment_date_end           -- �Ώێx���\���(��)
      FROM xxcok_backmargin_balance xbb                                         -- �̎�c��
         , po_vendors               pv                                          -- �d����}�X�^
         , po_vendor_sites_all      pvs                                         -- �d����T�C�g
         , hz_cust_accounts         cntct_hca                                   -- �y�⍇���z�ڋq�}�X�^
         , hz_parties               cntct_hp                                    -- �y�⍇���z�ڋq�p�[�e�B
         , hz_cust_acct_sites       cntct_hcas                                  -- �y�⍇���z�ڋq���ݒn
         , hz_party_sites           cntct_hps                                   -- �y�⍇���z�ڋq�p�[�e�B�T�C�g
         , hz_locations             cntct_hl                                    -- �y�⍇���z�ڋq���Ə�
         , ap_bank_account_uses     abau                                        -- ��s�����g�p���}�X�^
         , ap_bank_accounts         aba                                         -- ��s�����}�X�^
         , ap_bank_branches         abb                                         -- ��s�x�X�}�X�^
     WHERE xbb.edi_interface_status      =  cv_edi_if_status_0
-- 2010/01/06 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi REPAIR START
--       AND xbb.closing_date              <= gd_operating_date
       AND xbb.closing_date              <= gd_schedule_date
-- 2010/01/06 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi REPAIR END
       AND NVL( xbb.payment_amt_tax, cn_number_0 ) =  cn_number_0
       AND pv.segment1                   =  xbb.supplier_code
       AND pv.vendor_id                  =  pvs.vendor_id
       AND pvs.vendor_site_code          =  xbb.supplier_site_code
       AND pvs.attribute4                IN ( cv_bm_pay_class_1 , cv_bm_pay_class_2 )
       AND TRUNC( gd_process_date )      <  NVL( pvs.inactive_date, TRUNC( gd_process_date ) + 1 )
       AND pvs.org_id                    =  TO_NUMBER( gv_prof_org_id )
       AND cntct_hca.account_number      =  pvs.attribute5
       AND cntct_hp.party_id             =  cntct_hca.party_id
       AND cntct_hca.cust_account_id     =  cntct_hcas.cust_account_id
       AND cntct_hps.party_site_id       =  cntct_hcas.party_site_id
       AND cntct_hp.party_id             =  cntct_hps.party_id
       AND cntct_hl.location_id          =  cntct_hps.location_id
       AND pvs.vendor_id                 =  abau.vendor_id
       AND pvs.vendor_site_id            =  abau.vendor_site_id
       AND abau.primary_flag             =  cv_primary_flag
       AND TRUNC( gd_process_date )      BETWEEN NVL( abau.start_date, TRUNC( gd_process_date ) )
                                             AND NVL( abau.end_date,   TRUNC( gd_process_date ) )
       AND aba.bank_account_id           =  abau.external_bank_account_id
       AND abb.bank_branch_id            =  aba.bank_branch_id
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD START
       AND xbb.amt_fix_status            = cv_fix_status
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD END
    GROUP BY  xbb.supplier_code
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD START
--            , pv.vendor_name
            , pvs.attribute1
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama UPD END
            , pvs.zip
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama DEL START
--            , pvs.city
-- 2009/10/14 Ver.2.1 [�ύX�˗�I_E_573] SCS S.Moriyama DEL END
            , pvs.address_line1
            , pvs.address_line2
            , pvs.attribute5
            , cntct_hp.party_name
            , cntct_hl.city
            , cntct_hl.address1
            , cntct_hl.address2
            , cntct_hl.postal_code
            , cntct_hl.address_lines_phonetic
            , cntct_hl.address3
            , abb.bank_number
            , abb.bank_name
            , abb.bank_num
            , abb.bank_branch_name
            , aba.account_holder_name_alt
            , pvs.bank_charge_bearer
            , pvs.attribute4
    ORDER BY  cntct_hl.address3
            , pvs.attribute5
            , aba.account_holder_name_alt
            , xbb.supplier_code
    ;
--
  -- ===============================================
  -- �J�[�\��
  -- ===============================================
  CURSOR g_bm_line_cur(
      it_supplier_code             IN xxcok_backmargin_balance.supplier_code%TYPE
    , it_closing_date_start        IN xxcok_backmargin_balance.closing_date%TYPE
    , it_closing_date_end          IN xxcok_backmargin_balance.closing_date%TYPE
    , it_expect_payment_date_start IN xxcok_backmargin_balance.expect_payment_date%TYPE
    , it_expect_payment_date_end   IN xxcok_backmargin_balance.expect_payment_date%TYPE
  )
  IS
    SELECT /*+ INDEX(xbb, xxcok_backmargin_balance_n06)
               LEADING ( xbb , sales_hca , sales_hp , sales_hps , sales_hcas , sales_hl ) */
           xbb.supplier_code                           AS payee_code            -- �y�x����z�d����R�[�h
         , xbb.base_code                               AS sales_base_code       -- �y����z���_�R�[�h
         , sales_hl.address3                           AS sales_base_area_code  -- �y����z�n��R�[�h
         , xbb.cust_code                               AS cust_code             -- �y�ݒu��z�ڋq�R�[�h
         , cust_hp.party_name                          AS cust_name             -- �y�ݒu��z�ڋq��
         , NVL( SUM( xbb.selling_amt_tax ), cn_number_0 )        AS selling_amt_tax -- �̔����z
         , NVL( SUM( xbb.expect_payment_amt_tax ), cn_number_0 ) AS payment_amt_tax -- �萔�����z
      FROM xxcok_backmargin_balance  xbb                                        -- �̎�c��
         , hz_cust_accounts          sales_hca                                  -- �y����z�ڋq�}�X�^
         , hz_parties                sales_hp                                   -- �y����z�ڋq�p�[�e�B
         , hz_cust_acct_sites        sales_hcas                                 -- �y����z�ڋq���ݒn
         , hz_party_sites            sales_hps                                  -- �y����z�ڋq�p�[�e�B�T�C�g
         , hz_locations              sales_hl                                   -- �y����z�ڋq���Ə�
         , hz_cust_accounts          cust_hca                                   -- �y�ݒu��z�ڋq�}�X�^
         , hz_parties                cust_hp                                    -- �y�ݒu��z�ڋq�p�[�e�B
     WHERE xbb.supplier_code             = it_supplier_code
       AND xbb.edi_interface_status      = cv_edi_if_status_0
       AND xbb.resv_flag                 IS NULL
       AND xbb.closing_date              BETWEEN it_closing_date_start
                                             AND it_closing_date_end
       AND xbb.expect_payment_date       BETWEEN it_expect_payment_date_start
                                             AND it_expect_payment_date_end
       AND NVL( xbb.payment_amt_tax, cn_number_0 ) = cn_number_0
       AND sales_hca.account_number      = xbb.base_code
       AND sales_hp.party_id             = sales_hca.party_id
       AND sales_hca.cust_account_id     = sales_hcas.cust_account_id
       AND sales_hps.party_site_id       = sales_hcas.party_site_id
       AND sales_hp.party_id             = sales_hps.party_id
       AND sales_hl.location_id          = sales_hps.location_id
       AND cust_hca.account_number       = xbb.cust_code
       AND cust_hp.party_id              = cust_hca.party_id
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD START
       AND xbb.amt_fix_status            = cv_fix_status
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi ADD END
     GROUP BY xbb.supplier_code
            , xbb.base_code
            , sales_hl.address3
            , xbb.cust_code
            , cust_hp.party_name
     ORDER BY sales_hl.address3
            , xbb.base_code
            , xbb.cust_code
     ;
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
   * Description      : �t�@�C���N���[�Y(A-8)
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
   * Procedure Name   : upd_bm_data
   * Description      : �A�g�Ώۃf�[�^�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_bm_data(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  , it_bm_line_rec  IN g_bm_line_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_bm_data';  -- �v���O������
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
      SELECT /*+ INDEX( xbb , xxcok_backmargin_balance_n06 )*/
             xbb.bm_balance_id
        FROM xxcok_backmargin_balance  xbb
       WHERE xbb.supplier_code         = it_bm_data_rec.payee_code
         AND xbb.edi_interface_status  = cv_edi_if_status_0
         AND xbb.resv_flag             IS NULL
         AND xbb.closing_date          BETWEEN it_bm_data_rec.closing_date_start
                                       AND it_bm_data_rec.closing_date_end
         AND xbb.expect_payment_date   BETWEEN it_bm_data_rec.expect_payment_date_start
                                       AND it_bm_data_rec.expect_payment_date_end
         AND NVL( xbb.payment_amt_tax , 0) = cn_number_0
         AND xbb.base_code             = it_bm_line_rec.sales_base_code
         AND xbb.cust_code             = it_bm_line_rec.cust_code
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
    << bm_lock_loop >>
    FOR l_bm_lock_rec IN l_bm_lock_cur LOOP
      -- ===============================================
      -- �̎�c���e�[�u���X�V
      -- ===============================================
      UPDATE xxcok_backmargin_balance xbb
         SET xbb.publication_date        = gd_pay_date                          -- �ē���������
           , xbb.edi_interface_date      = gd_process_date                      -- �A�g���iEDI�x���ē����j
           , xbb.edi_interface_status    = cv_edi_if_status_1                   -- �A�g�X�e�[�^�X�iEDI�x���ē����j
           , xbb.last_updated_by         = cn_last_updated_by
           , xbb.last_update_date        = SYSDATE
           , xbb.last_update_login       = cn_last_update_login
           , xbb.request_id              = cn_request_id
           , xbb.program_application_id  = cn_program_application_id
           , xbb.program_id              = cn_program_id
           , xbb.program_update_date     = SYSDATE
       WHERE xbb.bm_balance_id           = l_bm_lock_rec.bm_balance_id
      ;
    END LOOP bm_lock_loop;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
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
  END upd_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : put_record
   * Description      : �A�g�f�[�^�o��(A-6)
   ***********************************************************************************/
  PROCEDURE put_record(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'put_record';                       -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;                           -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;               -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg            VARCHAR2(5000) DEFAULT NULL;                           -- �o�͗p���b�Z�[�W
    lb_msg_return        BOOLEAN        DEFAULT TRUE;                           -- ���b�Z�[�W�֐��߂�l�p
    lv_out_file_data     VARCHAR2(2000) DEFAULT NULL;                           -- �t�@�C���o�͗p�f�[�^
    ln_line_num          NUMBER;                                                -- ���׍s�ԍ�
    lt_selling_amt_tax   xxcok_backmargin_balance.selling_amt_tax%TYPE;         -- �̔����z���v
    lt_payment_amt_tax   xxcok_backmargin_balance.payment_amt_tax%TYPE;         -- �萔�����z���v
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �o�͓��e�Z�b�g�i�������j
    -- ===============================================
    lv_out_file_data := gv_data_type_addr                                                  -- �f�[�^���
           || cv_separator_char || it_bm_data_rec.payee_code                               -- �x����R�[�h
           || cv_separator_char || NULL                                                    -- ���הԍ�
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_name , 1 , 80 )           -- ����
-- 2009/11/16 Ver.2.2 [�ύX�˗�I_E_665] SCS S.Moriyama UPD START
--           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_zip , 1 , 15 )            -- �X�֔ԍ�
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_zip , 1 , 3 )
                                || cv_zip_separator_char
                                || SUBSTRB( it_bm_data_rec.payee_zip , 4 , 4 )             -- �X�֔ԍ�
-- 2009/11/16 Ver.2.2 [�ύX�˗�I_E_665] SCS S.Moriyama UPD END
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_address , 1 , 80 )        -- �Z��
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_name , 1 , 80 )      -- ���_��
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_address , 1 , 80 )   -- ���_�Z��
-- 2009/11/16 Ver.2.2 [�ύX�˗�I_E_665] SCS S.Moriyama UPD START
--           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_zip , 1 , 8 )        -- ���_�X�֔ԍ�
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_zip , 1 , 3 )
                                || cv_zip_separator_char
                                || SUBSTRB( it_bm_data_rec.cntct_base_zip , 4 , 4 )        -- ���_�X�֔ԍ�
-- 2009/11/16 Ver.2.2 [�ύX�˗�I_E_665] SCS S.Moriyama UPD END
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_phone , 1 , 15 )     -- ���_�d�b�ԍ�
           || cv_separator_char || TO_CHAR( it_bm_data_rec.closing_date_end , cv_format_ee
                                                                 , cv_nls_param )          -- �N��
           || cv_separator_char || TO_CHAR( it_bm_data_rec.closing_date_end , cv_format_ee_year
                                                                 , cv_nls_param )          -- �N����
           || cv_separator_char || TO_CHAR( gd_pay_date , cv_format_mmdd )                 -- �x����
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_number , 1 , 4 )     -- ��s�R�[�h
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_name , 1 , 20 )      -- ��s��
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_branch_num , 1 , 4 ) -- �x�X�R�[�h
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_branch_name , 1 , 20 )-- �x�X��
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_holder_name_alt , 1 , 40 )-- ������
    ;
--
    -- ===============================================
    -- �������o��
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
    lt_selling_amt_tax := cn_number_0;
    lt_payment_amt_tax := cn_number_0;
    ln_line_num := cn_number_1;
--
    -- ===============================================
    -- �J�[�\��
    -- ===============================================
    << bm_line_loop >>
    FOR l_bm_line_rec IN g_bm_line_cur (
        it_supplier_code             => it_bm_data_rec.payee_code
      , it_closing_date_start        => it_bm_data_rec.closing_date_start
      , it_closing_date_end          => it_bm_data_rec.closing_date_end
      , it_expect_payment_date_start => it_bm_data_rec.expect_payment_date_start
      , it_expect_payment_date_end   => it_bm_data_rec.expect_payment_date_end
    )
    LOOP
      -- ===============================================
      -- �o�͓��e�Z�b�g�iVDBM���׏��j
      -- ===============================================
      lv_out_file_data := gv_data_type_line                                     -- �f�[�^���
             || cv_separator_char || it_bm_data_rec.payee_code                  -- �x����R�[�h
             || cv_separator_char || ln_line_num                                -- ���הԍ�
             || cv_separator_char || SUBSTRB( l_bm_line_rec.cust_name , 1 , 80 )-- �ݒu�於��
             || cv_separator_char || TO_CHAR( l_bm_line_rec.selling_amt_tax )   -- �̔����z
             || cv_separator_char || TO_CHAR( l_bm_line_rec.payment_amt_tax )   -- �萔�����z
      ;
--
      -- ===============================================
      -- VDBM���׏��o��
      -- ===============================================
      UTL_FILE.PUT_LINE(
        file      => g_file_handle
      , buffer    => lv_out_file_data
      );
--
      lt_selling_amt_tax := lt_selling_amt_tax + l_bm_line_rec.selling_amt_tax; -- �̔����z���v
      lt_payment_amt_tax := lt_payment_amt_tax + l_bm_line_rec.payment_amt_tax; -- �萔�����z���v
      ln_line_num := ln_line_num + cn_number_1;
--
      -- ===============================================
      -- �A�g�Ώۃf�[�^�X�V(A-7)
      -- ===============================================
      upd_bm_data(
        ov_errbuf      => lv_errbuf
      , ov_retcode     => lv_retcode
      , ov_errmsg      => lv_errmsg
      , it_bm_data_rec => it_bm_data_rec
      , it_bm_line_rec => l_bm_line_rec
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP bm_line_loop;
--
    -- ===============================================
    -- �o�͓��e�Z�b�g�i�U���萔�����j
    -- ===============================================
    lv_out_file_data := gv_data_type_fee                                        -- �f�[�^���
           || cv_separator_char || it_bm_data_rec.payee_code                    -- �x����R�[�h
           || cv_separator_char || NULL                                         -- ���הԍ�
           || cv_separator_char || TO_CHAR( gn_bank_fee * -1 )                  -- ��s�U���萔��
    ;
    -- ===============================================
    -- �U���萔�����o��
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
    -- ===============================================
    -- �o�͓��e�Z�b�g�i���v���j
    -- ===============================================
    lv_out_file_data := gv_data_type_total                                      -- �f�[�^���
           || cv_separator_char || it_bm_data_rec.payee_code                    -- �x����R�[�h
           || cv_separator_char || NULL                                         -- ���הԍ�
           || cv_separator_char || TO_CHAR( lt_selling_amt_tax )                -- �̔����z���v
           || cv_separator_char || TO_CHAR( lt_payment_amt_tax - gn_bank_fee )  -- �萔�����z���v
    ;
    -- ===============================================
    -- �U���萔�����o��
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
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
  END put_record;
--
  /**********************************************************************************
   * Procedure Name   : chk_bm_data
   * Description      : �A�g�f�[�^�Ó����`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE chk_bm_data(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'chk_bm_data';                      -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- ���b�Z�[�W�֐��߂�l�p
    lb_chk_return   BOOLEAN        DEFAULT TRUE;                                -- �`�F�b�N���ʖ߂�l�p
    ln_chk_length   NUMBER         DEFAULT 0;                                   -- ���l�����`�F�b�N�p
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ���� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10430
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_name
                         , iv_token_value3  => it_bm_data_rec.payee_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �Z�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_address
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_addr
                         , iv_token_value3  => it_bm_data_rec.payee_address
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ��s�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10434
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_name
                         , iv_token_value4  => it_bm_data_rec.payee_bank_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ��s�x�X�� �S�p�`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_branch_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10435
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         , iv_token_name5   => cv_token_bank_branch_name
                         , iv_token_value5  => it_bm_data_rec.payee_bank_branch_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �d����R�[�h ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_code
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10459
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �X�֔ԍ� ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_zip
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10436
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_zip
                         , iv_token_value3  => it_bm_data_rec.payee_zip
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ��s�R�[�h ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_bank_number
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10460
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �x�X�R�[�h ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_bank_branch_num
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10461
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ������ ���p�p�����L���`�F�b�N
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_single_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_holder_name_alt
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10462
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         , iv_token_name5   => cv_token_bank_holder_name
                         , iv_token_value5  => it_bm_data_rec.payee_bank_holder_name_alt
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �d����R�[�h �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_code );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10439
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �X�֔ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_zip );
    IF ( ln_chk_length != cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10440
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_zip
                         , iv_token_value3  => it_bm_data_rec.payee_zip
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ���_�X�֔ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.cntct_base_zip );
    IF ( ln_chk_length != cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10441
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_conn_zip
                         , iv_token_value2  => it_bm_data_rec.cntct_base_zip
                         , iv_token_name3   => cv_token_vendor_code
                         , iv_token_value3  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ���_�d�b�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.cntct_base_phone );
    IF ( ln_chk_length > cn_number_15 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10442
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_conn_phone
                         , iv_token_value2  => it_bm_data_rec.cntct_base_phone
                         , iv_token_name3   => cv_token_vendor_code
                         , iv_token_value3  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ��s�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_bank_number );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10443
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- ��s�x�X�ԍ� �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_bank_branch_num );
    IF ( ln_chk_length > cn_number_3 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10444
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �̔����z���v �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.total_selling_amt_tax );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10445
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_sales_amount
                         , iv_token_value3  => it_bm_data_rec.total_selling_amt_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- �̔��萔�����v �����`�F�b�N
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.total_payment_amt_tax );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10446
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vdbm_amount
                         , iv_token_value3  => it_bm_data_rec.total_payment_amt_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : get_bank_fee
   * Description      : ��s�U���萔���擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_bank_fee(
    ov_errbuf            OUT VARCHAR2
  , ov_retcode           OUT VARCHAR2
  , ov_errmsg            OUT VARCHAR2
  , it_bm_data_rec        IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bank_fee';                     -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- ���b�Z�[�W�֐��߂�l�p
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
--
    -- ===============================================
    -- ��s�U���萔���擾
    -- ===============================================
    IF ( it_bm_data_rec.payee_bank_charge_bearer = cv_bank_charge_bearer ) THEN
      gn_bank_fee := cn_number_0;
-- 2009/12/15 Ver.2.3 [��QE_�{�ғ�_00427] SCS K.Nakamura UPD START
--    ELSIF ( it_bm_data_rec.total_payment_amt_tax < gv_bank_fee_trans ) THEN
    ELSIF ( ( it_bm_data_rec.total_payment_amt_tax - it_bm_data_rec.reserve_amt_tax ) < gv_bank_fee_trans ) THEN
-- 2009/12/15 Ver.2.3 [��QE_�{�ғ�_00427] SCS K.Nakamura UPD END
      gn_bank_fee := gn_tax_include_less;
    ELSE
      gn_bank_fee := gn_tax_include_more;
    END IF;
  EXCEPTION
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
  END get_bank_fee;
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
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bm_data';                      -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- ���b�Z�[�W�֐��߂�l�p
    lv_log_line     VARCHAR2(2000);
    lv_output_csv_data      VARCHAR2(2000) DEFAULT NULL;                        -- �o�͂̕\���p�f�[�^
    ln_total_payment_amt_tax       NUMBER;
    lv_output_error VARCHAR2(10);
--
    CURSOR l_output_header_cur
    IS
      SELECT flv.meaning
        FROM fnd_lookup_values flv
       WHERE flv.lookup_type = cv_lookup_type
         AND flv.language = USERENV('LANG')
         AND flv.enabled_flag = cv_enabled_flag
         AND gd_process_date BETWEEN flv.start_date_active AND NVL( flv.end_date_active , gd_process_date )
       ORDER BY TO_NUMBER( flv.lookup_code )
      ;
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �o�͂̕\���֌��o���s�擾
    -- ===============================================
    << output_header_loop >>
    FOR l_output_header_rec IN l_output_header_cur
    LOOP
      IF ( lv_log_line IS NOT NULL ) THEN
        lv_log_line := lv_log_line || cv_msg_canm || l_output_header_rec.meaning ;
      ELSE
        lv_log_line := l_output_header_rec.meaning ;
      END IF;
    END LOOP output_header_loop;
--
    -- ===============================================
    -- �o�͂̕\���֌��o���s�o��
    -- ===============================================
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_log_line
                     , in_new_line     => cn_number_0
                     );
--
    -- ===============================================
    -- �J�[�\��
    -- ===============================================
    << bm_data_loop >>
    FOR l_bm_data_rec IN g_bm_data_cur LOOP
      lv_output_error := NULL;
      -- ===============================================
      -- �Ώی����擾
      -- ===============================================
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================================
      -- ��s�萔���U��(A-4)
      -- ===============================================
      get_bank_fee(
        ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
      , ov_errmsg             => lv_errmsg
      , it_bm_data_rec        => l_bm_data_rec
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_skip_cnt := gn_skip_cnt + cn_number_1;
      END IF;
--
      -- ===============================================
      -- �C�Z�g�[�A�g��BM�x���敪:1(�{�U)�݂̂Ƃ���
      -- ===============================================
      IF ( l_bm_data_rec.payee_bm_pay_class = cv_bm_pay_class_1 ) THEN
        -- ===============================================
        -- BM - �U���萔�� < 1 �̏ꍇ�͏o�͂��s��Ȃ�
        -- ===============================================
        IF ( l_bm_data_rec.payment_amt_tax - gn_bank_fee < cn_number_1 ) THEN
          lv_output_error := cv_edi_output_error_kbn;
          gn_skip_cnt := gn_skip_cnt + cn_number_1;
          lv_errmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                             , iv_name          => cv_msg_xxcok1_10009
                             , iv_token_name1   => cv_token_conn_loc
                             , iv_token_value1  => l_bm_data_rec.cntct_base_code
                             , iv_token_name2   => cv_token_vendor_code
                             , iv_token_value2  => l_bm_data_rec.payee_code
                             , iv_token_name3   => cv_token_close_date
                             , iv_token_value3  => TO_CHAR( l_bm_data_rec.closing_date_start , cv_format_yyyy_mm_dd )
                             , iv_token_name4   => cv_token_due_date
                             , iv_token_value4  => TO_CHAR( l_bm_data_rec.expect_payment_date_start , cv_format_yyyy_mm_dd )
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                             , iv_message       => lv_errmsg
                             , in_new_line      => cn_number_0
                             );
          ov_retcode := cv_status_warn;
        ELSE
          -- ===============================================
          -- �A�g�f�[�^�Ó����`�F�b�N(A-5)
          -- ===============================================
          chk_bm_data(
            ov_errbuf      => lv_errbuf
          , ov_retcode     => lv_retcode
          , ov_errmsg      => lv_errmsg
          , it_bm_data_rec => l_bm_data_rec
          );
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ===============================================
            -- �A�g�f�[�^�o��(A-6)
            -- ===============================================
            put_record(
              ov_errbuf      => lv_errbuf
            , ov_retcode     => lv_retcode
            , ov_errmsg      => lv_errmsg
            , it_bm_data_rec => l_bm_data_rec
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSE
              gn_normal_cnt := gn_normal_cnt + cn_number_1;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_output_error := cv_edi_output_error_kbn;
            gn_skip_cnt := gn_skip_cnt + cn_number_1;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      ELSE
        gn_skip_cnt := gn_skip_cnt + cn_number_1;
      END IF;
--
      -- ===============================================
      -- ���x���z�Z�o�i0������0�Ƃ���j
      -- ===============================================
      IF ( l_bm_data_rec.payment_amt_tax - gn_bank_fee < cn_number_0 ) THEN
        ln_total_payment_amt_tax := cn_number_0;
      ELSE
        ln_total_payment_amt_tax := l_bm_data_rec.payment_amt_tax - gn_bank_fee;
      END IF;
--
      -- ===============================================
      -- �A�g���CSV�o��
      -- ===============================================
      lv_output_csv_data := l_bm_data_rec.payee_code                 || cv_msg_canm  -- �d����CD
                         || l_bm_data_rec.payee_name                 || cv_msg_canm  -- �d���於
                         || l_bm_data_rec.cntct_base_code            || cv_msg_canm  -- ���_CD
                         || l_bm_data_rec.cntct_base_name            || cv_msg_canm  -- ���_��
                         || l_bm_data_rec.payee_bank_number          || cv_msg_canm  -- ��sCD
                         || l_bm_data_rec.payee_bank_name            || cv_msg_canm  -- ��s��
                         || l_bm_data_rec.payee_bank_branch_num      || cv_msg_canm  -- �x�XCD
                         || l_bm_data_rec.payee_bank_branch_name     || cv_msg_canm  -- �x�X��
                         || l_bm_data_rec.payee_bank_holder_name_alt || cv_msg_canm  -- ������
                         || TO_CHAR( l_bm_data_rec.total_payment_amt_tax )
                                                                     || cv_msg_canm  -- BM�����v
                         || TO_CHAR( l_bm_data_rec.reserve_amt_tax ) || cv_msg_canm  -- �ۗ����z
                         || TO_CHAR( l_bm_data_rec.payment_amt_tax ) || cv_msg_canm  -- BM���z
                         || TO_CHAR( gn_bank_fee )                   || cv_msg_canm  -- �U�藿
                         || TO_CHAR( ln_total_payment_amt_tax )      || cv_msg_canm  -- ���x���z
                         || l_bm_data_rec.payee_bm_pay_class         || cv_msg_canm  -- BM�x���敪
                         || lv_output_error ;                                        -- �G���[
--
      -- ===============================================
      -- �o�͂̕\���֘A�W���o��
      -- ===============================================
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_output_csv_data
                       , in_new_line     => cn_number_0
                       );
    END LOOP bm_data_loop;
  EXCEPTION
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
                         in_which        => FND_FILE.LOG
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
    --*** �N�C�b�N�R�[�h�f�[�^�擾�G���[ ***
    no_data_expt    EXCEPTION;
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
                         in_which        => FND_FILE.LOG
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
                         in_which         => FND_FILE.LOG
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
                         in_which         => FND_FILE.LOG
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE START
--    -- ===============================================
--    -- �v���t�@�C���擾(�̎�̋��v�Z�������ԁiTo�j)
--    -- ===============================================
--    gv_bm_period_to  := FND_PROFILE.VALUE( cv_prof_suport_period_to );
--    IF ( gv_bm_period_to IS NULL ) THEN
--      lv_outmsg     := xxccp_common_pkg.get_msg(
--                         iv_application   => cv_appli_short_name_xxcok
--                       , iv_name          => cv_msg_xxcok1_00003
--                       , iv_token_name1   => cv_token_profile
--                       , iv_token_value1  => cv_prof_suport_period_to
--                       );
--      lb_msg_return := xxcok_common_pkg.put_message_f(
--                         in_which         => FND_FILE.LOG
--                       , iv_message       => lv_outmsg
--                       , in_new_line      => cn_number_0
--                       );
--      RAISE init_fail_expt;
--    END IF;
-- 2010/01/12 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi DELETE END
    -- ===============================================
    -- �v���t�@�C���擾(FB�x������)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_term_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
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
                            in_which         => FND_FILE.LOG
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
                           in_which         => FND_FILE.LOG
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
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�̔��萔��_����ŗ�)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(XXCOK:�C�Z�g�[EDI�f�[�^�敪_�w�b�_)
    -- ===============================================
    gv_data_type_addr  := FND_PROFILE.VALUE( cv_prof_edi_data_type_head );
    IF ( gv_data_type_addr IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_head
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(XXCOK:�C�Z�g�[EDI�f�[�^�敪_����)
    -- ===============================================
    gv_data_type_line  := FND_PROFILE.VALUE( cv_prof_edi_data_type_line );
    IF ( gv_data_type_line IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_line
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(XXCOK:�C�Z�g�[EDI�f�[�^�敪_�萔��)
    -- ===============================================
    gv_data_type_fee  := FND_PROFILE.VALUE( cv_prof_edi_data_type_fee );
    IF ( gv_data_type_fee IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_fee
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(XXCOK:�C�Z�g�[EDI�f�[�^�敪_���v)
    -- ===============================================
    gv_data_type_total  := FND_PROFILE.VALUE( cv_prof_edi_data_type_sum );
    IF ( gv_data_type_total IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_sum
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �v���t�@�C���擾(�g�DID)
    -- ===============================================
    gv_prof_org_id := FND_PROFILE.VALUE(
                        cv_prof_org_id
                      );
    IF ( gv_prof_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
-- 2010/01/06 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi REPAIR START
--    -- ===============================================
--    -- �c�Ɠ��擾(�A�g�Ώے��ߓ�)
--    -- ===============================================
--    gd_operating_date := xxcok_common_pkg.get_operating_day_f(
--                           id_proc_date      => gd_process_date
--                         , in_days           => TO_NUMBER ( gv_bm_period_to ) * -1
--                         , in_proc_type      => cn_number_0
--                         );
--    IF ( gd_operating_date IS NULL ) THEN
--      lv_outmsg       := xxccp_common_pkg.get_msg(
--                           iv_application   => cv_appli_short_name_xxcok
--                         , iv_name          => cv_msg_xxcok1_00027
--                         );
--      lb_msg_return   := xxcok_common_pkg.put_message_f(
--                           in_which         => FND_FILE.LOG
--                         , iv_message       => lv_outmsg
--                         , in_new_line      => cn_number_0
--                         );
--      RAISE init_fail_expt;
--    END IF;
      gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
-- 2010/01/06 Ver.2.4 [E_�{�ғ�_00901] SCS K.Yamaguchi REPAIR END
    -- ===============================================
    -- ���ߓ��A�x�����\����擾
    -- ===============================================
    xxcok_common_pkg.get_close_date_p(
        ov_errbuf         => lv_errbuf
      , ov_retcode        => lv_retcode
      , ov_errmsg         => lv_errmsg
      , id_proc_date      => gd_operating_date
      , iv_pay_cond       => gv_term_name
      , od_close_date     => gd_schedule_date
      , od_pay_date       => gd_pay_date
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �x�����擾
    -- ===============================================
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                    id_proc_date      => gd_pay_date
                  , in_days           => cn_number_0
                  , in_proc_type      => cn_number_1
                  );
    IF ( gd_pay_date IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00036
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- �ō��萔���擾
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( cn_number_1 + gn_bm_tax / cn_number_100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( cn_number_1 + gn_bm_tax / cn_number_100 );
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
                        in_which         => FND_FILE.LOG
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
                        in_which         => FND_FILE.LOG
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_1
                      );
--
  EXCEPTION
    -- *** �N�C�b�N�R�[�h�f�[�^�擾�G���[***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
    -- �t�@�C���N���[�Y(A-8)
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
                         in_which      => FND_FILE.LOG
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
                         in_which      => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
