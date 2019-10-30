CREATE OR REPLACE PACKAGE BODY XXCFO022A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO022A01C(body)
 * Description      : AP�d��������񐶐��i�d���j
 * MD.050           : AP�d��������񐶐��i�d���j<MD050_CFO_022_A01>
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_period_name      ��v���ԃ`�F�b�N(A-2)
 *  get_ap_invoice_data    AP������OIF��񒊏o(A-3,4)
 *  ins_offset_info        �J�z���o�^(A-5)
 *  ins_ap_invoice_headers AP�������w�b�_OIF�o�^(A-6)
 *  ins_ap_invoice_lines   AP����������OIF�o�^(A-7)
 *  upd_inv_trn_data       ���Y����f�[�^�X�V(A-8)
 *  ins_rcv_result         �d�����уA�h�I���o�^(A-9)
 *  upd_proc_flag          �����σt���O�X�V(A-10)
 *  del_offset_data        �����σf�[�^�폜(A-11)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-12)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           �V�K�쐬
 *  2015-01-26    1.1   A.Uchida         �V�X�e���e�X�g��Q�Ή�
 *                                       �E���o�@�i������сj�ɕs�����Ă�������������ǉ��B
 *                                       �EAP�������w�b�_OIF��AP���������ׂ́u�E�v�v�ɐݒ肷��l���C���B
 *                                       �E���K����ł��y���������/�a����z�Ƃ��Čv�シ��B
 *  2015-02-06    1.2   A.Uchida         �V�X�e���e�X�g��Q#40�Ή�
 *                                       �E���o���@�̕ύX
 *                                         �ˎ�����ׂ�attribute1(����ԕi���т̎��ID)��
 *                                           NULL�̃f�[�^�����݂��邽��
 *  2015-02-10    1.3   Y.Shoji          �V�X�e���e�X�g��Q#44�Ή�
 *                                       �E�������P�ʂ̎d����T�C�g�R�[�h���d����R�[�h�ɏC���B
 *  2015-02-26    1.4   Y.Shoji          ����i���[�U�d��m�F�j������Q#23�Ή�
 *                                         �E�d����z���}�C�i�X�̏ꍇ�ɌJ�z�������̕ύX�Ή�
 *                                           �i�������̎�ނ��uCREDIT�v��AP���������쐬���A�J��z���Ȃ��j
 *                                         �E�J�z���o�^(A-5)�̏������폜
 *                                         �E�d�����уA�h�I���o�^(A-9)�̏������폜
 *                                         �E�����σt���O�X�V(A-10)�̏������폜
 *                                         �E�����σf�[�^�폜(A-11)�̏������폜
 *  2017-12-05    1.5   S.Niki           E_�{�ғ�_14674�Ή�
 *                                       �E�a�������(���K�A���ۋ��A���K����ł̗a���)�̏ꍇ�A�ŃR�[�h�Ɂu0000�v��ݒ�B
 *  2019-04-04    1.6   N.Miyamoto       E_�{�ғ�_15601(�y���ŗ�)�Ή�
 *                                       �E�ŗ��̎擾����Q�ƕ\����y���ŗ��Ή�����ŗ��r���[�ɕύX
 *                                       �E��������CCID�̎擾�L�[��ŗ��������ŗ��r���[.�ŃR�[�h�ɕύX
 *                                       �E�ŃR�[�h�}�X�^�̎擾������ORG_ID��ǉ�
 *                                       �EA-4(AP������OIF���ҏW)�Ŏx�����z0�~���̃u���C�N�������C��
 *  2019-10-29    1.7   Y.Shouji         E_�{�ғ�_15601(�y���ŗ�)�s��Ή�
 *                                       �E���K�̏���ł�W���ŗ��ɂď���
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
  cv_underbar      CONSTANT VARCHAR2(1) := '_';       -- 2015-01-26 Ver1.1 Add
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO022A01C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- ����
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_cmn_10002            CONSTANT VARCHAR2(50)  := 'APP-XXCMN-10002';         -- �R���J�����g���̓p�����[�^�Ȃ�
--
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  cv_msg_cfo_10037            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10037';        -- �J�z�������b�Z�[�W
  cv_msg_cfo_10040            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10040';        -- AP�������f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_cfo_10041            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10041';        -- �J�z�Ώۏ�񃁃b�Z�[�W
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- �f�[�^�X�V�G���[
  cv_msg_cfo_10035            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10035';        -- �f�[�^�擾�G���[
--
  -- �g�[�N��
  cv_tkn_profile              CONSTANT VARCHAR2(20)  := 'NG_PROFILE';              -- �g�[�N���F�v���t�@�C����
  cv_tkn_key                  CONSTANT VARCHAR2(20)  := 'KEY';                     -- �g�[�N���F�L�[
  cv_tkn_key2                 CONSTANT VARCHAR2(20)  := 'KEY2';                    -- �g�[�N���F�L�[2
  cv_tkn_key3                 CONSTANT VARCHAR2(20)  := 'KEY3';                    -- �g�[�N���F�L�[3
  cv_tkn_val                  CONSTANT VARCHAR2(20)  := 'VAL';                     -- �g�[�N���F�l
  cv_tkn_data                 CONSTANT VARCHAR2(20)  := 'DATA';                    -- �g�[�N���F�f�[�^
  cv_tkn_vendor_site_code     CONSTANT VARCHAR2(20)  := 'VENDOR_SITE_CODE';        -- �g�[�N���F�d����T�C�g�R�[�h
  cv_tkn_department           CONSTANT VARCHAR2(20)  := 'DEPARTMENT';              -- �g�[�N���F����
  cv_tkn_item_kbn             CONSTANT VARCHAR2(20)  := 'ITEM_KBN';                -- �g�[�N���F�i�ڋ敪
  cv_tkn_item                 CONSTANT VARCHAR2(20)  := 'ITEM';                    -- �g�[�N���F�i��
  cv_tkn_table                CONSTANT VARCHAR2(100) := 'TABLE';                   -- �g�[�N���F�e�[�u����
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';  -- �d��p�^�[���F�d�����ѕ\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_INVOICE_SOURCE_MFG'; -- XXCFO:�������\�[�X�i�H��j
  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_ITEM';  -- XXCFO:AP-OIF���׃^�C�v_����
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_TAX';   -- XXCFO:AP-OIF���׃^�C�v_�ŋ�
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- �g�DID (�c��)
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';         -- ���YORG_ID
--
  -- �Q�ƃ^�C�v
  cv_lookup_type_01           CONSTANT VARCHAR2(50)  := 'XXCMN_CONSUMPTION_TAX_RATE';   -- �Q�ƃ^�C�v�F����ŗ��}�X�^
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- �ݕ�
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- �ؕ�
--
  cv_type_standard            CONSTANT VARCHAR2(20)  := 'STANDARD';                  -- STANDARD
  cv_type_credit              CONSTANT VARCHAR2(20)  := 'CREDIT';                    -- CREDIT
--
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                         -- �f�[�^�^�C�v�i1:�d���J�z�j
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
  cv_mfg                      CONSTANT VARCHAR2(3)   := 'MFG';                       -- MFG
  cv_dummy_invoice_num        CONSTANT VARCHAR2(2)   := '-1';                        -- �J�z�f�[�^�̐������ԍ�
--
  -- �g�[�N���l
  cv_msg_out_data_01          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11139';          -- ���E���z���
  cv_msg_out_data_02          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11140';          -- ����ԕi����
  cv_msg_out_data_03          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11141';          -- �d����}�X�^�ǂݑւ�View
  cv_msg_out_data_04          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11142';          -- AP������OIF�w�b�_�[
  cv_msg_out_data_05          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11143';          -- AP�ŃR�[�h�}�X�^
  cv_msg_out_data_06          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11144';          -- AP������OIF����_�{��
  cv_msg_out_data_07          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11145';          -- AP������OIF����_�����
  cv_msg_out_data_08          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11146';          -- AP������OIF����_���K
  cv_msg_out_data_09          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11147';          -- AP������OIF����_���ۋ�
  cv_msg_out_data_10          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11148';          -- �d�����уA�h�I��
  cv_msg_out_data_11          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11149';          -- ���Y����f�[�^
  --
  cv_msg_out_item_01          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11135';          -- ���ID
  cv_msg_out_item_02          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11150';          -- �d����T�C�gID
  cv_msg_out_item_03          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11151';          -- �{��CCID
  cv_msg_out_item_04          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11152';          -- �i�ڋ敪
  cv_msg_out_item_05          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11153';          -- ���KCCID
  cv_msg_out_item_06          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11154';          -- ���ۋ�CCID
  cv_msg_out_item_07          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11155';          -- �ŃR�[�h
  cv_msg_out_item_08          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073';          -- ��v����
-- 2019-10-29 Ver1.7 Add Start
  cv_msg_out_item_09          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11177';          -- �ŗ�
-- 2019-10-29 Ver1.7 Add End
--
  -- �d��p�^�[���m�F�p
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
  cv_line_no_05               CONSTANT VARCHAR2(1)   := '5';
  -- 2015-01-26 Ver1.1 Add Start
  cv_line_no_06               CONSTANT VARCHAR2(1)   := '6';
  cv_line_no_07               CONSTANT VARCHAR2(1)   := '7';
  -- 2015-01-26 Ver1.1 Add End
--
  -- �i�ڋ敪
  cv_item_class_1             CONSTANT VARCHAR2(1)   := '1';           -- ����
  cv_item_class_2             CONSTANT VARCHAR2(1)   := '2';           -- ����
  cv_item_class_4             CONSTANT VARCHAR2(1)   := '4';           -- �����i
  cv_item_class_5             CONSTANT VARCHAR2(1)   := '5';           -- ���i
--
  -- �ېŏW�v�敪
  cv_tax_sum_type_2           CONSTANT VARCHAR2(1)   := '2';           -- �ېŎ���
--
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --�������t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�v���t�@�C���擾
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- �g�DID (���Y)
  gn_org_id_sales             NUMBER        DEFAULT NULL;    -- �g�DID (�c��)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- �c�ƃV�X�e����v����ID
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- ��ЃR�[�h�i�H��j
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��1_�_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��2_�_�~�[�l
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- �d��\�[�X_���Y�V�X�e��
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e����v���떼
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
  gv_je_ptn_purchasing        VARCHAR2(100) DEFAULT NULL;    -- �d��p�^�[���F�d�����ѕ\
  gv_invoice_source_mfg       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�������\�[�X�i�H��j
  gv_detail_type_item         VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF���׃^�C�v_����
  gv_detail_type_tax          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF���׃^�C�v_�ŋ�
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
--
  gn_payment_amount_all       NUMBER        DEFAULT NULL;    -- �������P�ʁF�x�����z�i�ō��j
  gn_commission_all           NUMBER        DEFAULT NULL;    -- �������P�ʁF���K���z�i�Ŕ��j
  gn_assessment_all           NUMBER        DEFAULT NULL;    -- �������P�ʁF���ۋ��z
  gv_vendor_code_hdr          VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d����R�[�h�i���Y�j
  gv_vendor_site_code_hdr     VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d����T�C�g�R�[�h�i���Y�j
  gn_vendor_site_id_hdr       NUMBER        DEFAULT NULL;    -- �������P�ʁF�d����T�C�gID�i���Y�j
  gv_department_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF����R�[�h
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�i�ڋ敪
  -- 2015-01-26 Ver1.1 Add Start
  gn_commission_tax_all       NUMBER        DEFAULT NULL;    -- �������P�ʁF���K�����
  -- 2015-01-26 Ver1.1 Add End
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d���於�i���Y�j
  gv_invoice_num              VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�������ԍ�
--
  gn_transfer_cnt             NUMBER;                        -- �J�z��������
--
  gv_period_name              VARCHAR2(7);                   -- IN�p����v����
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�^
  -- ===============================
  -- AP���������i�[�p
  TYPE g_ap_invoice_rec IS RECORD
    (
      vendor_code             VARCHAR2(100)                  -- �d����R�[�h
     ,vendor_site_code        VARCHAR2(100)                  -- �d����T�C�g�R�[�h
     ,vendor_site_id          NUMBER                         -- �d����T�C�gID
     ,department_code         VARCHAR2(100)                  -- ����R�[�h
     ,item_class_code         VARCHAR2(100)                  -- �i�ڋ敪
     ,target_period           VARCHAR2(100)                  -- �Ώ۔N��
     ,txns_id                 NUMBER                         -- ���ID
     ,trans_qty               NUMBER                         -- �������
     ,tax_rate                NUMBER                         -- ����ŗ�
     ,order_amount_net        NUMBER                         -- �d�����z�i�Ŕ��j
     ,payment_tax             NUMBER                         -- �x������Ŋz
     ,commission_net          NUMBER                         -- ���K���z�i�Ŕ��j
     ,commission_tax          NUMBER                         -- ���K����ŋ��z
     ,assessment              NUMBER                         -- ���ۋ��z
     ,payment_amount_net      NUMBER                         -- �x�����z�i�Ŕ��j
     ,payment_amount          NUMBER                         -- �x�����z�i�ō��j
    );
  TYPE g_ap_invoice_ttype IS TABLE OF g_ap_invoice_rec INDEX BY PLS_INTEGER;
--
  -- AP���������׏��i�[�p
  TYPE g_ap_invoice_line_rec IS RECORD
    (
      tax_rate                NUMBER                         -- ����ŗ�
     ,payment_amount_net      NUMBER                         -- �x�����z�i�Ŕ��j
     ,commission_net          NUMBER                         -- ���K���z�i�Ŕ��j
     ,assessment              NUMBER                         -- ���ۋ��z
     ,payment_tax             NUMBER                         -- �x������Ŋz
     ,tax_code                NUMBER                         -- �ŃR�[�h�i�c�Ɓj
     ,tax_ccid                NUMBER                         -- ����Ŋ���CCID
     -- 2015-01-26 Ver1.1 Add Start
     ,commission_tax          NUMBER                         -- ���K�����
     -- 2015-01-26 Ver1.1 Add End
    );
  TYPE g_ap_invoice_line_ttype IS TABLE OF g_ap_invoice_line_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�ϐ�
  -- ===============================
  -- AP���������i�[�pPL/SQL�\
  g_ap_invoice_tab            g_ap_invoice_ttype;
  -- AP���������׏��i�[�pPL/SQL�\
  g_ap_invoice_line_tab       g_ap_invoice_line_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
--
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    -- 1.(1)  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_out    -- ���b�Z�[�W�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_log    -- ���O�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(1)  �Ɩ��������t�A�v���t�@�C���l�̎擾
    --==============================================================
    xxcfo_common_pkg3.init_proc(
        ov_company_code_mfg         =>  gv_company_code_mfg         -- ��ЃR�[�h�i�H��j
      , ov_aff5_customer_dummy      =>  gv_aff5_customer_dummy      -- �ڋq�R�[�h_�_�~�[�l
      , ov_aff6_company_dummy       =>  gv_aff6_company_dummy       -- ��ƃR�[�h_�_�~�[�l
      , ov_aff7_preliminary1_dummy  =>  gv_aff7_preliminary1_dummy  -- �\��1_�_�~�[�l
      , ov_aff8_preliminary2_dummy  =>  gv_aff8_preliminary2_dummy  -- �\��2_�_�~�[�l
      , ov_je_invoice_source_mfg    =>  gv_je_invoice_source_mfg    -- �d��\�[�X_���Y�V�X�e��
      , on_org_id_mfg               =>  gn_org_id_mfg               -- ���YORG_ID
      , on_sales_set_of_bks_id      =>  gn_sales_set_of_bks_id      -- �c�ƃV�X�e����v����ID
      , ov_sales_set_of_bks_name    =>  gv_sales_set_of_bks_name    -- �c�ƃV�X�e����v���떼
      , ov_currency_code            =>  gv_currency_code            -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
      , od_process_date             =>  gd_process_date             -- �Ɩ����t
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(2)  �v���t�@�C���l�̎擾
    --==============================================================
    -- �d��p�^�[���F�d�����ѕ\
    gv_je_ptn_purchasing  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_purchasing IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:�������\�[�X�i�H��j
    gv_invoice_source_mfg  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF���׃^�C�v_����
    gv_detail_type_item  := FND_PROFILE.VALUE( cv_profile_name_03 );
    IF( gv_detail_type_item IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_03
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF���׃^�C�v_�ŋ�
    gv_detail_type_tax  := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_detail_type_tax IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_04
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �g�DID (�c��)
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_05 ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_05
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    --
    gv_period_name       := iv_period_name;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_period_name
   * Description      : ��v���ԃ`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_period_name(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_period_name'; -- �v���O������
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
    --==============================================================
    -- 1.  AP�������쐬�p��v���ԃ`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_ap_period_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.  �d��쐬�pGL�A�g�`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_gl_if_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , iv_func_name                    => cv_pkg_name                 -- �@�\���i�R���J�����g�Z�k���j
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
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
  END check_period_name;
--
-- 2015-02-26 Ver1.4 Del Start
--  /**********************************************************************************
--   * Procedure Name   : ins_offset_info
--   * Description      : �J�z���o�^(A-5)
--   ***********************************************************************************/
--  PROCEDURE ins_offset_info(
--    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_offset_info'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    lv_out_msg               VARCHAR2(5000);
--    ln_cnt                   NUMBER;
--    lt_txns_id               xxpo_rcv_and_rtn_txns.txns_id%TYPE;
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    -- ===============================
--    -- ���E���z���e�[�u���o�^
--    -- ===============================
--    ln_cnt := 1;
--    << insert_loop >>
--    FOR ln_cnt IN g_ap_invoice_tab.FIRST..g_ap_invoice_tab.LAST LOOP
--      BEGIN
--        INSERT INTO xxcfo_offset_amount_info(
--           data_type                  -- �f�[�^�敪
--          ,vendor_code                -- �d����R�[�h
--          ,vendor_site_code           -- �d����T�C�g�R�[�h
--          ,vendor_site_id             -- �d����T�C�gID
--          ,dept_code                  -- ����R�[�h
--          ,item_kbn                   -- �i�ڋ敪
--          ,target_month               -- �Ώ۔N��
--          ,trn_id                     -- ���ID
--          ,trans_qty                  -- �������
--          ,tax_rate                   -- ����ŗ�
--          ,order_amount_net           -- �d�����z�i�Ŕ��j
--          ,payment_tax                -- �x������Ŋz
--          ,commission_net             -- ���K���z�i�Ŕ��j
--          ,commission_tax             -- ���K����ŋ��z
--          ,assessment                 -- ���ۋ��z
--          ,invoice_net_amount         -- �x�����z�i�Ŕ��j
--          ,invoice_amount             -- �x�����z�i�ō��݁j
--          ,proc_flag                  -- �����σt���O
--          ,proc_date                  -- ��������
--          ,created_by
--          ,creation_date
--          ,last_updated_by
--          ,last_update_date
--          ,last_update_login
--          ,request_id
--          ,program_application_id
--          ,program_id
--          ,program_update_date
--        )VALUES(
--           cv_data_type_1                                   -- �f�[�^�敪 1:�d���J�z
--          ,g_ap_invoice_tab(ln_cnt).vendor_code             -- �d����R�[�h
--          ,g_ap_invoice_tab(ln_cnt).vendor_site_code        -- �d����T�C�g�R�[�h
--          ,g_ap_invoice_tab(ln_cnt).vendor_site_id          -- �d����T�C�gID
--          ,g_ap_invoice_tab(ln_cnt).department_code         -- ����R�[�h
--          ,g_ap_invoice_tab(ln_cnt).item_class_code         -- �i�ڋ敪
--          ,gv_period_name                                   -- �Ώ۔N��(IN�p����v����)
--          ,g_ap_invoice_tab(ln_cnt).txns_id                 -- ���ID
--          ,g_ap_invoice_tab(ln_cnt).trans_qty               -- �������
--          ,g_ap_invoice_tab(ln_cnt).tax_rate                -- ����ŗ�
--          ,g_ap_invoice_tab(ln_cnt).order_amount_net        -- �d�����z�i�Ŕ��j
--          ,g_ap_invoice_tab(ln_cnt).payment_tax             -- �x������Ŋz
--          ,g_ap_invoice_tab(ln_cnt).commission_net          -- ���K���z�i�Ŕ��j
--          ,g_ap_invoice_tab(ln_cnt).commission_tax          -- ���K����ŋ��z
--          ,g_ap_invoice_tab(ln_cnt).assessment              -- ���ۋ��z
--          ,g_ap_invoice_tab(ln_cnt).payment_amount_net      -- �x�����z�i�Ŕ��j
--          ,g_ap_invoice_tab(ln_cnt).payment_amount          -- �x�����z�i�ō��݁j
--          ,cv_flag_n                                        -- �����σt���O(N:�����{)
--          ,NULL                                             -- ��������
--          ,cn_created_by
--          ,cd_creation_date
--          ,cn_last_updated_by
--          ,cd_last_update_date
--          ,cn_last_update_login
--          ,cn_request_id
--          ,cn_program_application_id
--          ,cn_program_id
--          ,cd_program_update_date
--        );
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
--                    , iv_name         => cv_msg_cfo_10040
--                    , iv_token_name1  => cv_tkn_data                             -- �f�[�^
--                    , iv_token_value1 => cv_msg_out_data_01                      -- ���E���z���
--                    , iv_token_name2  => cv_tkn_vendor_site_code                 -- �d����T�C�g�R�[�h
--                    , iv_token_value2 => g_ap_invoice_tab(ln_cnt).vendor_site_code
--                    , iv_token_name3  => cv_tkn_department                       -- ����
--                    , iv_token_value3 => g_ap_invoice_tab(ln_cnt).department_code
--                    , iv_token_name4  => cv_tkn_item_kbn                         -- �i�ڋ敪
--                    , iv_token_value4 => g_ap_invoice_tab(ln_cnt).item_class_code
--                    );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
----
--      -- ===============================
--      -- ���Y����f�[�^�X�V�i�������ԍ��j
--      -- ===============================
--      -- ����ԕi���уA�h�I���ɑ΂��čs���b�N���擾
--      BEGIN
--        SELECT xrrt.txns_id
--        INTO   lt_txns_id
--        FROM   xxpo_rcv_and_rtn_txns xrrt
--        WHERE  xrrt.txns_id      = g_ap_invoice_tab(ln_cnt).txns_id
--        FOR UPDATE NOWAIT
--        ;
--      EXCEPTION
--        WHEN global_lock_expt THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
--                    , iv_name         => cv_msg_cfo_00019                        -- ���b�N�G���[
--                    , iv_token_name1  => cv_tkn_table                            -- �e�[�u��
--                    , iv_token_value1 => cv_msg_out_data_02                      -- ����ԕi����
--                    );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
----
--      -- �J�z�f�[�^�ɂ͈ꗥ�Ő������ԍ��Ɂu-1�v���Z�b�g
--      BEGIN
--        UPDATE xxpo_rcv_and_rtn_txns xrart  -- ����ԕi����(�A�h�I��)
--        SET    xrart.invoice_num  = cv_dummy_invoice_num                         -- �J�z�f�[�^�̐������ԍ�: -1
--              ,xrart.last_updated_by        = cn_last_updated_by
--              ,xrart.last_update_date       = cd_last_update_date
--              ,xrart.last_update_login      = cn_last_update_login
--              ,xrart.request_id             = cn_request_id
--              ,xrart.program_application_id = cn_program_application_id
--              ,xrart.program_id             = cn_program_id
--              ,xrart.program_update_date    = cd_program_update_date
--        WHERE  xrart.txns_id      = g_ap_invoice_tab(ln_cnt).txns_id
--        ;
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
--                    , iv_name         => cv_msg_cfo_10042
--                    , iv_token_name1  => cv_tkn_data                             -- �f�[�^
--                    , iv_token_value1 => cv_msg_out_data_02                      -- ����ԕi����
--                    , iv_token_name2  => cv_tkn_item                             -- �A�C�e��
--                    , iv_token_value2 => cv_msg_out_item_01                      -- ���ID
--                    , iv_token_name3  => cv_tkn_key                              -- �L�[
--                    , iv_token_value3 => g_ap_invoice_tab(ln_cnt).txns_id
--                    );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
----
--      -- �J�z�����J�E���g
--      gn_transfer_cnt := gn_transfer_cnt + 1;
----
--    END LOOP insert_loop;
----
--    -- ===============================
--    -- �J�z�f�[�^�̃��b�Z�[�W�o��
--    -- ===============================
--    -- �x����Ƌ��z�������b�Z�[�W�o�͂���
--    lv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo
--                    , iv_name         => cv_msg_cfo_10041
--                    , iv_token_name1  => cv_tkn_key                -- �d����R�[�h
--                    , iv_token_value1 => gv_vendor_code_hdr
--                    , iv_token_name2  => cv_tkn_key2               -- �d����T�C�g�R�[�h
--                    , iv_token_value2 => gv_vendor_site_code_hdr
--                    , iv_token_name3  => cv_tkn_key3               -- ����R�[�h
--                    , iv_token_value3 => gv_department_code_hdr
--                    , iv_token_name4  => cv_tkn_val                -- �J�z���z
--                    , iv_token_value4 => gn_payment_amount_all
--                  );
--    FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT
--      , buff   => lv_out_msg
--    );
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--  EXCEPTION
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# �C�� #
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END ins_offset_info;
----
-- 2015-02-26 Ver1.4 Del End
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_headers
   * Description      : AP�������w�b�_OIF�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_ap_invoice_headers(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_invoice_headers'; -- �v���O������
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
    lv_sales_vendor_code        VARCHAR2(100)     DEFAULT NULL;     -- �d����R�[�h�i�c�Ɓj
    lv_sales_vendor_site_code   VARCHAR2(100)     DEFAULT NULL;     -- �x����T�C�g�R�[�h�i�c�Ɓj
    lv_mfg_vendor_code          VARCHAR2(100)     DEFAULT NULL;     -- �d����R�[�h�i���Y�j
    ln_sales_accts_pay_ccid     NUMBER            DEFAULT NULL;     -- ������CCID�i�c�Ɓj
    --
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)���
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)����
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)����Ȗ�
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)�⏕�Ȗ�
    lv_description              VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)�E�v
-- 2015-02-26 Ver1.4 Add Start
    lv_invoice_type             VARCHAR2(100)     DEFAULT NULL;     -- (�w�b�_)�������^�C�v
-- 2015-02-26 Ver1.4 Add End
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
    -- �ϐ��̏�����
    lv_sales_vendor_code            := NULL;
    lv_sales_vendor_site_code       := NULL;
    lv_mfg_vendor_code              := NULL;
    ln_sales_accts_pay_ccid         := NULL;
    lv_company_code                 := NULL;
    lv_department_code              := NULL;
    lv_account_title                := NULL;
    lv_account_subsidiary           := NULL;
    lv_description                  := NULL;
-- 2015-02-26 Ver1.4 Add Start
    lv_invoice_type                 := NULL;
-- 2015-02-26 Ver1.4 Add End
--
    -- ===============================
    -- �d����}�X�^�̏����擾
    -- ===============================
    BEGIN
      SELECT xvmv.sales_vendor_code             -- �d����R�[�h�i�c�Ɓj
            ,xvmv.sales_vendor_site_code        -- �x����T�C�g�R�[�h�i�c�Ɓj
            ,xvmv.mfg_vendor_code               -- �d����R�[�h�i���Y�j
            ,xvmv.mfg_vendor_name               -- �d���於�i���Y�j
      INTO   lv_sales_vendor_code               -- �d����R�[�h�i�c�Ɓj
            ,lv_sales_vendor_site_code          -- �x����T�C�g�R�[�h�i�c�Ɓj
            ,lv_mfg_vendor_code                 -- �d����R�[�h�i���Y�j
            ,gv_mfg_vendor_name                 -- �d���於�i���Y�j
      FROM   xxcfo_vendor_mst_read_v xvmv       -- �d����}�X�^�ǂݑւ��r���[
      WHERE  xvmv.mfg_vendor_site_id = gn_vendor_site_id_hdr
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_data_03            -- �d����}�X�^�ǂݑւ�View
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_02            -- �d����T�C�gID
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gn_vendor_site_id_hdr
                        );
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- �������ԍ��i�`�[�ԍ��j�擾
    -- ===============================
    -- �������ԍ����̔Ԃ���
    gv_invoice_num := cv_mfg || LPAD(xxcfo_invoice_mfg_s1.nextval, 8, 0);
--
    -- ===============================
    -- ���ʊ֐��i����Ȗڐ����@�\�j
    -- ===============================
    -- ���ʊ֐����R�[������
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing        -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                        -- (IN)���i�敪
      , iv_reason_code              =>  NULL                        -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01            -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  cv_line_no_01               -- (IN)�s�ԍ� �F1
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  NULL                        -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code             -- (OUT)���
      , ov_department_code          =>  lv_department_code          -- (OUT)����
      , ov_account_title            =>  lv_account_title            -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description              -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                  -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �{�̃��R�[�h��CCID���擾
    ln_sales_accts_pay_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                  -- ������
                      , iv_segment1  => lv_company_code                  -- ��ЃR�[�h
                      , iv_segment2  => lv_department_code               -- ����R�[�h
                      , iv_segment3  => lv_account_title                 -- ����ȖڃR�[�h
                      , iv_segment4  => lv_account_subsidiary            -- �⏕�ȖڃR�[�h
                      , iv_segment5  => gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                      , iv_segment6  => gv_aff6_company_dummy            -- ��ƃR�[�h�_�~�[�l
                      , iv_segment7  => gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                      , iv_segment8  => gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                      );
    IF ( ln_sales_accts_pay_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_03            -- �{��CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_04            -- �i�ڋ敪
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      RAISE global_api_expt;
    END IF;
--
-- 2015-02-26 Ver1.4 Add Start
    -- �x�����z�i�ō��j���v���X�̏ꍇ�A�������̎�ނ�'STANDARD'
    IF (gn_payment_amount_all > 0) THEN
      lv_invoice_type := cv_type_standard;
    -- �x�����z�i�ō��j���}�C�i�X�̏ꍇ�A�������̎�ނ�'CREDIT'
    ELSIF (gn_payment_amount_all < 0) THEN
      lv_invoice_type := cv_type_credit;
    END IF;
--
-- 2015-02-26 Ver1.4 Add End
    -- ===============================
    -- AP������OIF�o�^
    -- ===============================
    BEGIN
      INSERT INTO ap_invoices_interface (
        invoice_id                              -- �V�[�P���X
      , invoice_num                             -- �`�[�ԍ�
      , invoice_type_lookup_code                -- �������̎��
      , invoice_date                            -- �������t
      , vendor_num                              -- �d����R�[�h
      , vendor_site_code                        -- �d����T�C�g�R�[�h
      , invoice_amount                          -- �������z
      , description                             -- �E�v
      , last_update_date                        -- �ŏI�X�V��
      , last_updated_by                         -- �ŏI�X�V��
      , last_update_login                       -- �ŏI���O�C��ID
      , creation_date                           -- �쐬��
      , created_by                              -- �쐬��
      , attribute_category                      -- DFF�R���e�L�X�g
      , attribute2                              -- �������ԍ�
      , attribute3                              -- �N�[����
      , attribute4                              -- �`�[���͎�
      , source                                  -- �\�[�X
      , pay_group_lookup_code                   -- �x���O���[�v
      , gl_date                                 -- �d��v���
      , accts_pay_code_combination_id           -- ������CCID
      , org_id                                  -- �g�DID
      , terms_date                              -- �x���N�Z��
      )
      VALUES (
        ap_invoices_interface_s.NEXTVAL         -- AP������OIF�w�b�_�[�p�V�[�P���X�ԍ�(���)
      , gv_invoice_num                          -- �������ԍ�(���O�Ŏ擾)
-- 2015-02-26 Ver1.4 Mod Start
--      , cv_type_standard                        -- �������^�C�v
      , lv_invoice_type                         -- �������^�C�v
-- 2015-02-26 Ver1.4 Mod End
      , gd_target_date_to                       -- �������t
      , lv_sales_vendor_code                    -- �d����R�[�h
      , lv_sales_vendor_site_code               -- �d����T�C�g�R�[�h
      , gn_payment_amount_all                   -- �������P�ʁF�x�����z�i�ō��j
      -- 2015-01-26 Ver1.1 Mod Start
--      , lv_description || lv_mfg_vendor_code || gv_mfg_vendor_name
      , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_mfg_vendor_name
      -- 2015-01-26 Ver1.1 Mod End
                                                -- �u�d����R�[�h�i���Y�j�v�{�u�E�v�v�{�u�d���於�i���Y�j�v
      , cd_last_update_date                     -- �ŏI�X�V��
      , cn_last_updated_by                      -- �ŏI�X�V��
      , cn_last_update_login                    -- �ŏI���O�C��ID
      , cd_creation_date                        -- �쐬��
      , cn_created_by                           -- �쐬��
      , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
      , gv_invoice_num                          -- �������ԍ�(���O�Ŏ擾)
      , gv_department_code_hdr                  -- ���_�R�[�h
      , NULL                                    -- �`�[���͎�(�]�ƈ�No)
      , gv_invoice_source_mfg                   -- �������\�[�X(init�Ŏ擾)
      , NULL                                    -- �x���O���[�v
      , gd_target_date_to                       -- �d��v���(�Ώی��̌���)
      , ln_sales_accts_pay_ccid                 -- ������Ȗ�CCID
      , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
      , gd_target_date_to                       -- �x���N�Z��(�Ώی��̌���)
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10040
                  , iv_token_name1  => cv_tkn_data                             -- �f�[�^
                  , iv_token_value1 => cv_msg_out_data_04                      -- AP������OIF�w�b�_�[
                  , iv_token_name2  => cv_tkn_vendor_site_code                 -- �d����T�C�g�R�[�h
                  , iv_token_value2 => gv_vendor_code_hdr
                  , iv_token_name3  => cv_tkn_department                       -- ����
                  , iv_token_value3 => gv_department_code_hdr
                  , iv_token_name4  => cv_tkn_item_kbn                         -- �i�ڋ敪
                  , iv_token_value4 => gv_item_class_code_hdr
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
  END ins_ap_invoice_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_lines
   * Description      : AP����������OIF�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ap_invoice_lines(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_invoice_lines'; -- �v���O������
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
    cn_minus                        CONSTANT NUMBER := -1;         -- ���z�Z�o�p
-- 2017-12-05 Ver1.5 Add Start
    cv_tax_code_0000                CONSTANT VARCHAR2(4) := '0000'; -- �ŃR�[�h�F0000�i�ΏۊO�j
-- 2017-12-05 Ver1.5 Add End
--
    -- *** ���[�J���ϐ� ***
    lv_company_code_hontai          VARCHAR2(100) DEFAULT NULL;    -- (�{��)���
    lv_department_code_hontai       VARCHAR2(100) DEFAULT NULL;    -- (�{��)����
    lv_account_title_hontai         VARCHAR2(100) DEFAULT NULL;    -- (�{��)����Ȗ�
    lv_account_subsidiary_hontai    VARCHAR2(100) DEFAULT NULL;    -- (�{��)�⏕�Ȗ�
    lv_description_hontai           VARCHAR2(100) DEFAULT NULL;    -- (�{��)�E�v
    lv_ccid_hontai                  NUMBER        DEFAULT NULL;    -- (�{��)CCID
    --
    lv_company_code_fukakin         VARCHAR2(100) DEFAULT NULL;    -- (���ۋ�)���
    lv_department_code_fukakin      VARCHAR2(100) DEFAULT NULL;    -- (���ۋ�)����
    lv_account_title_fukakin        VARCHAR2(100) DEFAULT NULL;    -- (���ۋ�)����Ȗ�
    lv_account_subsidiary_fukakin   VARCHAR2(100) DEFAULT NULL;    -- (���ۋ�)�⏕�Ȗ�
    lv_description_fukakin          VARCHAR2(100) DEFAULT NULL;    -- (���ۋ�)�E�v
    lv_ccid_fukakin                 NUMBER        DEFAULT NULL;    -- (���ۋ�)CCID
    --
    lv_company_code_kosen           VARCHAR2(100) DEFAULT NULL;    -- (���K)���
    lv_department_code_kosen        VARCHAR2(100) DEFAULT NULL;    -- (���K)����
    lv_account_title_kosen          VARCHAR2(100) DEFAULT NULL;    -- (���K)����Ȗ�
    lv_account_subsidiary_kosen     VARCHAR2(100) DEFAULT NULL;    -- (���K)�⏕�Ȗ�
    lv_description_kosen            VARCHAR2(100) DEFAULT NULL;    -- (���K)�E�v
    lv_ccid_kosen                   NUMBER        DEFAULT NULL;    -- (���K)CCID
    --
    lv_company_code_tax             VARCHAR2(100) DEFAULT NULL;    -- (�����)���
    lv_department_code_tax          VARCHAR2(100) DEFAULT NULL;    -- (�����)����
    lv_account_title_tax            VARCHAR2(100) DEFAULT NULL;    -- (�����)����Ȗ�
    lv_account_subsidiary_tax       VARCHAR2(100) DEFAULT NULL;    -- (�����)�⏕�Ȗ�
    lv_description_tax              VARCHAR2(100) DEFAULT NULL;    -- (�����)�E�v
--
    -- 2015-01-26 Ver1.1 Add Start
    lv_comp_code_comm_tax_dr        VARCHAR2(100) DEFAULT NULL;    -- (���K�����DR)���
    lv_dept_code_comm_tax_dr        VARCHAR2(100) DEFAULT NULL;    -- (���K�����DR)����
    lv_acct_title_comm_tax_dr       VARCHAR2(100) DEFAULT NULL;    -- (���K�����DR)����Ȗ�
    lv_acct_sub_comm_tax_dr         VARCHAR2(100) DEFAULT NULL;    -- (���K�����DR)�⏕�Ȗ�
    lv_desc_comm_tax_dr             VARCHAR2(100) DEFAULT NULL;    -- (���K�����DR)�E�v
    lv_ccid_comm_tax_dr             NUMBER        DEFAULT NULL;    -- (���K�����DR)CCID
--
    lv_comp_code_comm_tax_cr        VARCHAR2(100) DEFAULT NULL;    -- (���K�����CR)���
    lv_dept_code_comm_tax_cr        VARCHAR2(100) DEFAULT NULL;    -- (���K�����CR)����
    lv_acct_title_comm_tax_cr       VARCHAR2(100) DEFAULT NULL;    -- (���K�����CR)����Ȗ�
    lv_acct_sub_comm_tax_cr         VARCHAR2(100) DEFAULT NULL;    -- (���K�����CR)�⏕�Ȗ�
    lv_desc_comm_tax_cr             VARCHAR2(100) DEFAULT NULL;    -- (���K�����CR)�E�v
    lv_ccid_comm_tax_cr             NUMBER        DEFAULT NULL;    -- (���K�����CR)CCID
    -- 2015-01-26 Ver1.1 Add End
--
    ln_detail_num                   NUMBER        DEFAULT 1;       -- ���ׂ̘A��
--
-- 2019-10-29 Ver1.7 Add Start
    lt_name                         ap_tax_codes_all.name%TYPE;                    -- �ŃR�[�h�i�c�Ɓj
    lt_tax_code_combination_id      ap_tax_codes_all.tax_code_combination_id%TYPE; -- ����Ŋ���CCID
-- 2019-10-29 Ver1.7 Add End
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
    -- �ϐ��̏�����
    lv_company_code_hontai          := NULL;
    lv_department_code_hontai       := NULL;
    lv_account_title_hontai         := NULL;
    lv_account_subsidiary_hontai    := NULL;
    lv_description_hontai           := NULL;
    lv_ccid_hontai                  := NULL;
    --
    lv_company_code_fukakin         := NULL;
    lv_department_code_fukakin      := NULL;
    lv_account_title_fukakin        := NULL;
    lv_account_subsidiary_fukakin   := NULL;
    lv_description_fukakin          := NULL;
    lv_ccid_fukakin                 := NULL;
    -- 2015-01-26 Ver1.1 Add Start
    lv_ccid_comm_tax_dr             := NULL;
    lv_ccid_comm_tax_cr             := NULL;
    -- 2015-01-26 Ver1.1 Add End
    --
    lv_company_code_kosen           := NULL;
    lv_department_code_kosen        := NULL;
    lv_account_title_kosen          := NULL;
    lv_account_subsidiary_kosen     := NULL;
    lv_description_kosen            := NULL;
    lv_ccid_kosen                   := NULL;
    --
    lv_company_code_tax             := NULL;
    lv_department_code_tax          := NULL;
    lv_account_title_tax            := NULL;
    lv_account_subsidiary_tax       := NULL;
    lv_description_tax              := NULL;
    --
    ln_detail_num                   := 1;
--
    -- �{�̃��R�[�h�̉Ȗڏ������ʊ֐��Ŏ擾
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing             -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr           -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                             -- (IN)���i�敪
      , iv_reason_code              =>  NULL                             -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                 -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  cv_line_no_02                    -- (IN)�s�ԍ� �F2
      , iv_gloif_dr_cr              =>  cv_gloif_dr                      -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  NULL                             -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code_hontai           -- (OUT)���
      , ov_department_code          =>  lv_department_code_hontai        -- (OUT)����
      , ov_account_title            =>  lv_account_title_hontai          -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary_hontai     -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description_hontai            -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                       -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                        -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                        -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �{�̃��R�[�h��CCID���擾
    lv_ccid_hontai := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                  -- ������
                      , iv_segment1  => lv_company_code_hontai           -- ��ЃR�[�h
                      , iv_segment2  => lv_department_code_hontai        -- ����R�[�h
                      , iv_segment3  => lv_account_title_hontai          -- ����ȖڃR�[�h
                      , iv_segment4  => lv_account_subsidiary_hontai     -- �⏕�ȖڃR�[�h
                      , iv_segment5  => gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                      , iv_segment6  => gv_aff6_company_dummy            -- ��ƃR�[�h�_�~�[�l
                      , iv_segment7  => gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                      , iv_segment8  => gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                      );
    IF ( lv_ccid_hontai IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_03            -- �{��CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_04            -- �i�ڋ敪
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      RAISE global_api_expt;
    END IF;
--
    -- ���K������ꍇ�A���ʊ֐��ŉȖڏ����擾
    IF ( gn_commission_all <> 0 ) THEN
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)���[
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)�i�ڋ敪
        , iv_prod_class               =>  NULL                           -- (IN)���i�敪
        , iv_reason_code              =>  NULL                           -- (IN)���R�R�[�h
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)�d��p�^�[�� �F1
        , iv_line_no                  =>  cv_line_no_03                  -- (IN)�s�ԍ� �F3
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)�ؕ��E�ݕ�
        , iv_warehouse_code           =>  NULL                           -- (IN)�q�ɃR�[�h
        , ov_company_code             =>  lv_company_code_kosen          -- (OUT)���
        , ov_department_code          =>  lv_department_code_kosen       -- (OUT)����
        , ov_account_title            =>  lv_account_title_kosen         -- (OUT)����Ȗ�
        , ov_account_subsidiary       =>  lv_account_subsidiary_kosen    -- (OUT)�⏕�Ȗ�
        , ov_description              =>  lv_description_kosen           -- (OUT)�E�v
        , ov_retcode                  =>  lv_retcode                     -- ���^�[���R�[�h
        , ov_errbuf                   =>  lv_errbuf                      -- �G���[���b�Z�[�W
        , ov_errmsg                   =>  lv_errmsg                      -- ���[�U�[�E�G���[���b�Z�[�W
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���K���R�[�h��CCID���擾
      lv_ccid_kosen := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date               -- ������
                         , iv_segment1  => lv_company_code_kosen         -- ��ЃR�[�h
                         , iv_segment2  => lv_department_code_kosen      -- ����R�[�h
                         , iv_segment3  => lv_account_title_kosen        -- ����ȖڃR�[�h
                         , iv_segment4  => lv_account_subsidiary_kosen   -- �⏕�ȖڃR�[�h
                         , iv_segment5  => gv_aff5_customer_dummy        -- �ڋq�R�[�h�_�~�[�l
                         , iv_segment6  => gv_aff6_company_dummy         -- ��ƃR�[�h�_�~�[�l
                         , iv_segment7  => gv_aff7_preliminary1_dummy    -- �\��1�_�~�[�l
                         , iv_segment8  => gv_aff8_preliminary2_dummy    -- �\��2�_�~�[�l
                         );
      -- 2015-01-26 Ver1.1 Mod Start
--      IF ( lv_ccid_hontai IS NULL ) THEN
      IF ( lv_ccid_kosen IS NULL ) THEN
      -- 2015-01-26 Ver1.1 Mod End
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035            -- �f�[�^�擾�G���[
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_05          -- ���KCCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04          -- �i�ڋ敪
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���ۋ�������ꍇ�A���ʊ֐��ŉȖڏ����擾
    IF ( gn_assessment_all <> 0 ) THEN
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)���[
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)�i�ڋ敪
        , iv_prod_class               =>  NULL                           -- (IN)���i�敪
        , iv_reason_code              =>  NULL                           -- (IN)���R�R�[�h
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)�d��p�^�[�� �F1
        , iv_line_no                  =>  cv_line_no_04                  -- (IN)�s�ԍ� �F4
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)�ؕ��E�ݕ�
        , iv_warehouse_code           =>  NULL                           -- (IN)�q�ɃR�[�h
        , ov_company_code             =>  lv_company_code_fukakin        -- (OUT)���
        , ov_department_code          =>  lv_department_code_fukakin     -- (OUT)����
        , ov_account_title            =>  lv_account_title_fukakin       -- (OUT)����Ȗ�
        , ov_account_subsidiary       =>  lv_account_subsidiary_fukakin  -- (OUT)�⏕�Ȗ�
        , ov_description              =>  lv_description_fukakin         -- (OUT)�E�v
        , ov_retcode                  =>  lv_retcode                     -- ���^�[���R�[�h
        , ov_errbuf                   =>  lv_errbuf                      -- �G���[���b�Z�[�W
        , ov_errmsg                   =>  lv_errmsg                      -- ���[�U�[�E�G���[���b�Z�[�W
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���ۋ����R�[�h��CCID���擾
      lv_ccid_fukakin := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date                 -- ������
                         , iv_segment1  => lv_company_code_fukakin         -- ��ЃR�[�h
                         , iv_segment2  => lv_department_code_fukakin      -- ����R�[�h
                         , iv_segment3  => lv_account_title_fukakin        -- ����ȖڃR�[�h
                         , iv_segment4  => lv_account_subsidiary_fukakin   -- �⏕�ȖڃR�[�h
                         , iv_segment5  => gv_aff5_customer_dummy          -- �ڋq�R�[�h�_�~�[�l
                         , iv_segment6  => gv_aff6_company_dummy           -- ��ƃR�[�h�_�~�[�l
                         , iv_segment7  => gv_aff7_preliminary1_dummy      -- �\��1�_�~�[�l
                         , iv_segment8  => gv_aff8_preliminary2_dummy      -- �\��2�_�~�[�l
                         );
      -- 2015-01-26 Ver1.1 Mod Start
--      IF ( lv_ccid_hontai IS NULL ) THEN
      IF ( lv_ccid_fukakin IS NULL ) THEN
      -- 2015-01-26 Ver1.1 Mod End
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_06            -- ���ۋ�CCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04            -- �i�ڋ敪
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 2015-01-26 Ver1.1 Add Start
    -- ���K����ł�����ꍇ�A���ʊ֐��ŉȖڏ����擾
    IF ( gn_commission_tax_all <> 0 ) THEN
      -- �ؕ�
      -- ���ʊ֐��Ō��K����Ń��R�[�h�́u�E�v�v���擾
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)���[
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)�i�ڋ敪
        , iv_prod_class               =>  NULL                           -- (IN)���i�敪
        , iv_reason_code              =>  NULL                           -- (IN)���R�R�[�h
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)�d��p�^�[�� �F1
        , iv_line_no                  =>  cv_line_no_06                  -- (IN)�s�ԍ�(6)
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)�ؕ��E�ݕ�
        , iv_warehouse_code           =>  NULL                           -- (IN)�q�ɃR�[�h
        , ov_company_code             =>  lv_comp_code_comm_tax_dr       -- (OUT)���
        , ov_department_code          =>  lv_dept_code_comm_tax_dr       -- (OUT)����
        , ov_account_title            =>  lv_acct_title_comm_tax_dr      -- (OUT)����Ȗ�
        , ov_account_subsidiary       =>  lv_acct_sub_comm_tax_dr        -- (OUT)�⏕�Ȗ�
        , ov_description              =>  lv_desc_comm_tax_dr            -- (OUT)�E�v
        , ov_retcode                  =>  lv_retcode                     -- ���^�[���R�[�h
        , ov_errbuf                   =>  lv_errbuf                      -- �G���[���b�Z�[�W
        , ov_errmsg                   =>  lv_errmsg                      -- ���[�U�[�E�G���[���b�Z�[�W
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �ݕ�
      -- ���ʊ֐��ŉȖڏ����擾
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)���[
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)�i�ڋ敪
        , iv_prod_class               =>  NULL                           -- (IN)���i�敪
        , iv_reason_code              =>  NULL                           -- (IN)���R�R�[�h
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)�d��p�^�[�� �F1
        , iv_line_no                  =>  cv_line_no_07                  -- (IN)�s�ԍ� �F7
        , iv_gloif_dr_cr              =>  cv_gloif_cr                    -- (IN)�ؕ��E�ݕ�
        , iv_warehouse_code           =>  NULL                           -- (IN)�q�ɃR�[�h
        , ov_company_code             =>  lv_comp_code_comm_tax_cr       -- (OUT)���
        , ov_department_code          =>  lv_dept_code_comm_tax_cr       -- (OUT)����
        , ov_account_title            =>  lv_acct_title_comm_tax_cr      -- (OUT)����Ȗ�
        , ov_account_subsidiary       =>  lv_acct_sub_comm_tax_cr        -- (OUT)�⏕�Ȗ�
        , ov_description              =>  lv_desc_comm_tax_cr            -- (OUT)�E�v
        , ov_retcode                  =>  lv_retcode                     -- ���^�[���R�[�h
        , ov_errbuf                   =>  lv_errbuf                      -- �G���[���b�Z�[�W
        , ov_errmsg                   =>  lv_errmsg                      -- ���[�U�[�E�G���[���b�Z�[�W
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���K����őݕ����R�[�h��CCID���擾
      lv_ccid_comm_tax_cr := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_process_date                 -- ������
                             , iv_segment1  => lv_comp_code_comm_tax_cr        -- ��ЃR�[�h
                             , iv_segment2  => lv_dept_code_comm_tax_cr        -- ����R�[�h
                             , iv_segment3  => lv_acct_title_comm_tax_cr       -- ����ȖڃR�[�h
                             , iv_segment4  => lv_acct_sub_comm_tax_cr         -- �⏕�ȖڃR�[�h
                             , iv_segment5  => gv_aff5_customer_dummy          -- �ڋq�R�[�h�_�~�[�l
                             , iv_segment6  => gv_aff6_company_dummy           -- ��ƃR�[�h�_�~�[�l
                             , iv_segment7  => gv_aff7_preliminary1_dummy      -- �\��1�_�~�[�l
                             , iv_segment8  => gv_aff8_preliminary2_dummy      -- �\��2�_�~�[�l
                             );
      IF ( lv_ccid_comm_tax_cr IS NULL ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_05            -- ���KCCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04            -- �i�ڋ敪
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
--
    END IF;
    -- 2015-01-26 Ver1.1 Add End
--
    -- ���ʊ֐��ŏ���Ń��R�[�h�́u�E�v�v���擾
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing           -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                           -- (IN)���i�敪
      , iv_reason_code              =>  NULL                           -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  cv_line_no_05                  -- (IN)�s�ԍ�(5)
      , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  NULL                           -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code_tax            -- (OUT)���
      , ov_department_code          =>  lv_department_code_tax         -- (OUT)����
      , ov_account_title            =>  lv_account_title_tax           -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary_tax      -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description_tax             -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                     -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                      -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                      -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =================================================
    -- ����ŃR�[�h���ƂɁA AP����������OIF�o�^���������[�v
    -- =================================================
    << line_insert_loop >>
    FOR line_cnt IN g_ap_invoice_line_tab.FIRST..g_ap_invoice_line_tab.LAST LOOP
      -- ����Ń��R�[�h��CCID��AP�ŃR�[�h�}�X�^����擾
      BEGIN
        SELECT  atc.name                                 -- �ŃR�[�h�i�c�Ɓj
               ,atc.tax_code_combination_id              -- ����Ŋ���CCID
        INTO    g_ap_invoice_line_tab(line_cnt).tax_code
               ,g_ap_invoice_line_tab(line_cnt).tax_ccid
        FROM    ap_tax_codes_all atc
-- 2019-04-04 Ver1.6 Mod Start
--        WHERE   atc.attribute2   = cv_tax_sum_type_2     -- �ېŏW�v�敪(2:�ېŎd��)
--        AND     atc.attribute4   = g_ap_invoice_line_tab(line_cnt).tax_rate  -- ���Y�ŗ�
        WHERE   atc.name         = g_ap_invoice_line_tab(line_cnt).tax_code  -- A-4�Ŏ擾�����ŃR�[�h
        AND     atc.org_id       = gn_org_id_sales       -- �c�ƒP��
-- 2019-04-04 Ver1.6 Mod End
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_cfo
                          , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                          , iv_token_name1  => cv_tkn_data
                          , iv_token_value1 => cv_msg_out_data_05            -- AP�ŃR�[�h�}�X�^
                          , iv_token_name2  => cv_tkn_item
                          , iv_token_value2 => cv_msg_out_item_07            -- �ŃR�[�h
                          , iv_token_name3  => cv_tkn_key
-- 2019-04-04 Ver1.6 Mod Start
--                          , iv_token_value3 => g_ap_invoice_line_tab(line_cnt).tax_rate
                          , iv_token_value3 => g_ap_invoice_line_tab(line_cnt).tax_code
-- 2019-04-04 Ver1.6 Mod End
                          );
          RAISE global_process_expt;
      END;
--
      -- ================
      -- AP����OIF�o�^
      -- ================
      -- �{�̃��R�[�h�̓o�^
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- ������ID
        , invoice_line_id                                   -- ����������ID
        , line_number                                       -- ���׍s�ԍ�
        , line_type_lookup_code                             -- ���׃^�C�v
        , amount                                            -- ���׋��z
        , description                                       -- �E�v
        , tax_code                                          -- �ŃR�[�h
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- �ŏI�X�V��
        , last_update_date                                  -- �ŏI�X�V��
        , last_update_login                                 -- �ŏI���O�C��ID
        , created_by                                        -- �쐬��
        , creation_date                                     -- �쐬��
        , attribute_category                                -- DFF�R���e�L�X�g
        , org_id                                            -- �g�DID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
        , ln_detail_num                                     -- �w�b�_�[���ł̘A��
        , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
        , g_ap_invoice_line_tab(line_cnt).payment_amount_net  -- �x�����z�i�Ŕ��j
        -- 2015-01-26 Ver1.1 Mod Start
--        , lv_description_hontai || gv_vendor_code_hdr || gv_mfg_vendor_name
        , gv_vendor_code_hdr || cv_underbar || lv_description_hontai || cv_underbar || gv_mfg_vendor_name
        -- 2015-01-26 Ver1.1 Mod End
                                                            -- �E�v�i�d����C�{�E�v�{�d���於�j
        , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
        , lv_ccid_hontai                                    -- CCID
        , cn_last_updated_by                                -- �ŏI�X�V��
        , SYSDATE                                           -- �ŏI�X�V��
        , cn_last_update_login                              -- �ŏI���O�C��ID
        , cn_created_by                                     -- �쐬��
        , SYSDATE                                           -- �쐬��
        , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
        , gn_org_id_sales                                   -- �g�DID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                    , iv_token_value1 => cv_msg_out_data_06                  -- AP������OIF����_�{��
                    , iv_token_name2  => cv_tkn_vendor_site_code             -- �d����T�C�g�R�[�h
                    , iv_token_value2 => gv_vendor_code_hdr
                    , iv_token_name3  => cv_tkn_department                   -- ����
                    , iv_token_value3 => gv_department_code_hdr
                    , iv_token_name4  => cv_tkn_item_kbn                     -- �i�ڋ敪
                    , iv_token_value4 => gv_item_class_code_hdr
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      ln_detail_num := ln_detail_num + 1;
--
      -- ����Ń��R�[�h�̓o�^
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- ������ID
        , invoice_line_id                                   -- ����������ID
        , line_number                                       -- ���׍s�ԍ�
        , line_type_lookup_code                             -- ���׃^�C�v
        , amount                                            -- ���׋��z
        , description                                       -- �E�v
        , tax_code                                          -- �ŃR�[�h
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- �ŏI�X�V��
        , last_update_date                                  -- �ŏI�X�V��
        , last_update_login                                 -- �ŏI���O�C��ID
        , created_by                                        -- �쐬��
        , creation_date                                     -- �쐬��
        , attribute_category                                -- DFF�R���e�L�X�g
        , org_id                                            -- �g�DID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
        , ln_detail_num                                     -- �w�b�_�[���ł̘A��
        , gv_detail_type_tax                                -- ���׃^�C�v�F�ŋ�(TAX)
        , g_ap_invoice_line_tab(line_cnt).payment_tax       -- �d�����z�i�Ŕ��j
        -- 2015-01-26 Ver1.1 Mod Start
--        , lv_description_tax || gv_vendor_code_hdr || gv_mfg_vendor_name
        , gv_vendor_code_hdr || cv_underbar || lv_description_tax || cv_underbar || gv_mfg_vendor_name
        -- 2015-01-26 Ver1.1 Mod End
                                                            -- �E�v�i�E�v�{�d����C�{�d���於�j
        , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
        , g_ap_invoice_line_tab(line_cnt).tax_ccid          -- CCID
        , cn_last_updated_by                                -- �ŏI�X�V��
        , SYSDATE                                           -- �ŏI�X�V��
        , cn_last_update_login                              -- �ŏI���O�C��ID
        , cn_created_by                                     -- �쐬��
        , SYSDATE                                           -- �쐬��
        , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
        , gn_org_id_sales                                   -- �g�DID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                    , iv_token_value1 => cv_msg_out_data_07                  -- AP������OIF����_�����
                    , iv_token_name2  => cv_tkn_vendor_site_code             -- �d����T�C�g�R�[�h
                    , iv_token_value2 => gv_vendor_code_hdr
                    , iv_token_name3  => cv_tkn_department                   -- ����
                    , iv_token_value3 => gv_department_code_hdr
                    , iv_token_name4  => cv_tkn_item_kbn                     -- �i�ڋ敪
                    , iv_token_value4 => gv_item_class_code_hdr
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      ln_detail_num := ln_detail_num + 1;
--
      -- ���K���R�[�h�̓o�^
      IF ( g_ap_invoice_line_tab(line_cnt).commission_net <> 0 ) THEN
        BEGIN
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- ������ID
          , invoice_line_id                                   -- ����������ID
          , line_number                                       -- ���׍s�ԍ�
          , line_type_lookup_code                             -- ���׃^�C�v
          , amount                                            -- ���׋��z
          , description                                       -- �E�v
          , tax_code                                          -- �ŃR�[�h
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- �ŏI�X�V��
          , last_update_date                                  -- �ŏI�X�V��
          , last_update_login                                 -- �ŏI���O�C��ID
          , created_by                                        -- �쐬��
          , creation_date                                     -- �쐬��
          , attribute_category                                -- DFF�R���e�L�X�g
          , org_id                                            -- �g�DID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , ln_detail_num                                     -- �w�b�_�[���ł̘A��
          , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
          , g_ap_invoice_line_tab(line_cnt).commission_net * cn_minus
                                                              -- ���K���z�i�Ŕ��j
          -- 2015-01-26 Ver1.1 Mod Start
--          , lv_description_kosen || gv_vendor_code_hdr || gv_mfg_vendor_name
          , gv_vendor_code_hdr || cv_underbar || lv_description_kosen || cv_underbar || gv_mfg_vendor_name
          -- 2015-01-26 Ver1.1 Mod End
                                                              -- �E�v�i�d����C�{�E�v�{�d���於�j
-- 2017-12-05 Ver1.5 Mod Start
--          , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
          , cv_tax_code_0000                                  -- �������ŃR�[�h
-- 2017-12-05 Ver1.5 Mod End
          , lv_ccid_kosen                                     -- CCID
          , cn_last_updated_by                                -- �ŏI�X�V��
          , SYSDATE                                           -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , SYSDATE                                           -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_08                -- AP������OIF����_���K
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- �d����T�C�g�R�[�h
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- ����
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- �i�ڋ敪
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
        ln_detail_num := ln_detail_num + 1;
      --
      END IF;
--
      -- ���ۋ����R�[�h�̓o�^
      IF ( g_ap_invoice_line_tab(line_cnt).assessment <> 0 ) THEN
        BEGIN
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- ������ID
          , invoice_line_id                                   -- ����������ID
          , line_number                                       -- ���׍s�ԍ�
          , line_type_lookup_code                             -- ���׃^�C�v
          , amount                                            -- ���׋��z
          , description                                       -- �E�v
          , tax_code                                          -- �ŃR�[�h
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- �ŏI�X�V��
          , last_update_date                                  -- �ŏI�X�V��
          , last_update_login                                 -- �ŏI���O�C��ID
          , created_by                                        -- �쐬��
          , creation_date                                     -- �쐬��
          , attribute_category                                -- DFF�R���e�L�X�g
          , org_id                                            -- �g�DID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , ln_detail_num                                     -- �w�b�_�[���ł̘A��
          , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
          , g_ap_invoice_line_tab(line_cnt).assessment * cn_minus
                                                              -- ���ۋ��z�i�ō��j
          -- 2015-01-26 Ver1.1 Mod Start
--          , lv_description_fukakin || gv_vendor_code_hdr || gv_mfg_vendor_name
          , gv_vendor_code_hdr || cv_underbar || lv_description_fukakin || cv_underbar || gv_mfg_vendor_name
          -- 2015-01-26 Ver1.1 Mod End
                                                              -- �E�v�i�d����C�{�E�v�{�d���於�j
-- 2017-12-05 Ver1.5 Mod Start
--          , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
          , cv_tax_code_0000                                  -- �������ŃR�[�h
-- 2017-12-05 Ver1.5 Mod End
          , lv_ccid_fukakin                                   -- CCID
          , cn_last_updated_by                                -- �ŏI�X�V��
          , SYSDATE                                           -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , SYSDATE                                           -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_09                -- AP������OIF����_���ۋ�
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- �d����T�C�g�R�[�h
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- ����
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- �i�ڋ敪
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
        ln_detail_num := ln_detail_num + 1;
      --
      END IF;
--
      -- 2015-01-26 Ver1.1 Add Start
      -- ���K����Ń��R�[�h�̓o�^
      IF ( g_ap_invoice_line_tab(line_cnt).commission_tax <> 0 ) THEN
-- 2019-10-29 Ver1.7 Add Start
        -- ���K����Ń��R�[�h��CCID��AP�ŃR�[�h�}�X�^����擾
        BEGIN
          SELECT  atc.name                     name                      -- �ŃR�[�h�i�c�Ɓj
                 ,atc.tax_code_combination_id  tax_code_combination_id   -- ����Ŋ���CCID
          INTO    lt_name
                 ,lt_tax_code_combination_id
          FROM    ap_tax_codes_all atc
          WHERE   atc.attribute2   = cv_tax_sum_type_2                         -- �ېŏW�v�敪(2:�ېŎd��)
          AND     atc.attribute4   = g_ap_invoice_line_tab(line_cnt).tax_rate  -- ���Y�ŗ�
          AND     atc.org_id       = gn_org_id_sales                           -- �c�ƒP��
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cfo
                            , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_05            -- AP�ŃR�[�h�}�X�^
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_09            -- �ŗ�
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => g_ap_invoice_line_tab(line_cnt).tax_rate
                            );
            RAISE global_process_expt;
        END;
--
-- 2019-10-29 Ver1.7 Add End
        BEGIN
          -- �ؕ��@���������
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- ������ID
          , invoice_line_id                                   -- ����������ID
          , line_number                                       -- ���׍s�ԍ�
          , line_type_lookup_code                             -- ���׃^�C�v
          , amount                                            -- ���׋��z
          , description                                       -- �E�v
          , tax_code                                          -- �ŃR�[�h
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- �ŏI�X�V��
          , last_update_date                                  -- �ŏI�X�V��
          , last_update_login                                 -- �ŏI���O�C��ID
          , created_by                                        -- �쐬��
          , creation_date                                     -- �쐬��
          , attribute_category                                -- DFF�R���e�L�X�g
          , org_id                                            -- �g�DID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , ln_detail_num                                     -- �w�b�_�[���ł̘A��
          , gv_detail_type_tax                                -- ���׃^�C�v�F�ŋ�(TAX)
          , g_ap_invoice_line_tab(line_cnt).commission_tax    -- ���ۋ��z�i�ō��j
          , gv_vendor_code_hdr || cv_underbar || lv_desc_comm_tax_dr || cv_underbar || gv_mfg_vendor_name
                                                              -- �E�v�i�d����C�{�E�v�{�d���於�j
-- 2019-10-29 Ver1.7 Mod Start
--          , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
--          , g_ap_invoice_line_tab(line_cnt).tax_ccid          -- CCID
          , lt_name                                           -- �������ŃR�[�h
          , lt_tax_code_combination_id                        -- CCID
-- 2017-12-05 Ver1.7 Mod End
          , cn_last_updated_by                                -- �ŏI�X�V��
          , SYSDATE                                           -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , SYSDATE                                           -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
--
          -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
          ln_detail_num := ln_detail_num + 1;
--
          -- �ݕ��@�a�����
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- ������ID
          , invoice_line_id                                   -- ����������ID
          , line_number                                       -- ���׍s�ԍ�
          , line_type_lookup_code                             -- ���׃^�C�v
          , amount                                            -- ���׋��z
          , description                                       -- �E�v
          , tax_code                                          -- �ŃR�[�h
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- �ŏI�X�V��
          , last_update_date                                  -- �ŏI�X�V��
          , last_update_login                                 -- �ŏI���O�C��ID
          , created_by                                        -- �쐬��
          , creation_date                                     -- �쐬��
          , attribute_category                                -- DFF�R���e�L�X�g
          , org_id                                            -- �g�DID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , ln_detail_num                                     -- �w�b�_�[���ł̘A��
          , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
          , g_ap_invoice_line_tab(line_cnt).commission_tax * cn_minus
                                                              -- ���ۋ��z�i�ō��j
          , gv_vendor_code_hdr || cv_underbar || lv_desc_comm_tax_cr || cv_underbar || gv_mfg_vendor_name
                                                              -- �E�v�i�d����C�{�E�v�{�d���於�j
-- 2017-12-05 Ver1.5 Mod Start
--          , g_ap_invoice_line_tab(line_cnt).tax_code          -- �������ŃR�[�h
          , cv_tax_code_0000                                  -- �������ŃR�[�h
-- 2017-12-05 Ver1.5 Mod End
          , lv_ccid_comm_tax_cr                               -- CCID
          , cn_last_updated_by                                -- �ŏI�X�V��
          , SYSDATE                                           -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , SYSDATE                                           -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
--
          -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
          ln_detail_num := ln_detail_num + 1;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_09                -- AP������OIF����_���ۋ�
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- �d����T�C�g�R�[�h
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- ����
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- �i�ڋ敪
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      --
      END IF;
      -- 2015-01-26 Ver1.1 Add End
--
    END LOOP line_insert_loop;
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
  END ins_ap_invoice_lines;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : ���Y����f�[�^�X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_trn_data'; -- �v���O������
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
    upd_cnt      NUMBER;
    lt_txns_id   xxpo_rcv_and_rtn_txns.txns_id%TYPE;
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
    -- =========================================================
    -- ����ԕi���уA�h�I���ɕR�t���L�[�̒l��ݒ�i�������ԍ��j
    -- =========================================================
    upd_cnt := 1;
    << update_loop >>
    FOR upd_cnt IN g_ap_invoice_tab.FIRST..g_ap_invoice_tab.LAST LOOP
--
      BEGIN
        -- ����ԕi���уA�h�I���ɑ΂��čs���b�N���擾
        SELECT xrrt.txns_id
        INTO   lt_txns_id
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.txns_id      = g_ap_invoice_tab(upd_cnt).txns_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ���b�N�G���[
                    , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                    , iv_token_value1 => cv_msg_out_data_02                  -- ����ԕi����
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      BEGIN
        -- ����f�[�^�����ʂ����ӂȒl������ԕi���тɍX�V
        UPDATE xxpo_rcv_and_rtn_txns xrart
        SET    xrart.invoice_num  = gv_invoice_num                           -- �������ԍ�
              ,xrart.last_updated_by        = cn_last_updated_by
              ,xrart.last_update_date       = cd_last_update_date
              ,xrart.last_update_login      = cn_last_update_login
              ,xrart.request_id             = cn_request_id
              ,xrart.program_application_id = cn_program_application_id
              ,xrart.program_id             = cn_program_id
              ,xrart.program_update_date    = cd_program_update_date
        WHERE  xrart.txns_id      = g_ap_invoice_tab(upd_cnt).txns_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10042
                    , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                    , iv_token_value1 => cv_msg_out_data_02                  -- ����ԕi����
                    , iv_token_name2  => cv_tkn_item                         -- �A�C�e��
                    , iv_token_value2 => cv_msg_out_item_01                  -- ���ID
                    , iv_token_name3  => cv_tkn_key                          -- �L�[
                    , iv_token_value3 => g_ap_invoice_tab(upd_cnt).txns_id
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt +1;
--
    END LOOP update_loop;
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
  END upd_inv_trn_data;
--
-- 2015-02-26 Ver1.4 Del Start
--  /**********************************************************************************
--   * Procedure Name   : ins_rcv_result
--   * Description      : �d�����уA�h�I���o�^(A-9)
--   ***********************************************************************************/
--  PROCEDURE ins_rcv_result(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rcv_result'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    -- ============================
--    -- �d�����уA�h�I���f�[�^�o�^
--    -- ============================
--    BEGIN
--      INSERT INTO xxcfo_rcv_result(
--         rcv_month                            -- �d���N��
--        ,vendor_code                          -- �d����R�[�h
--        ,vendor_site_code                     -- �d����T�C�g�R�[�h
--        ,bumon_code                           -- ����R�[�h
--        ,invoice_number                       -- �������ԍ�
--        ,item_kbn                             -- �i�ڋ敪
--        ,invoice_amount                       -- �x�����z�i�ō��j
--        --WHO�J����
--        ,created_by
--        ,creation_date
--        ,last_updated_by
--        ,last_update_date
--        ,last_update_login
--        ,request_id
--        ,program_application_id
--        ,program_id
--        ,program_update_date
--      )VALUES(
--         TO_CHAR(gd_target_date_to,'YYYYMM')  -- �d���N��
--        ,gv_vendor_code_hdr                   -- �d����R�[�h
--        ,gv_vendor_site_code_hdr              -- �d����T�C�g�R�[�h
--        ,gv_department_code_hdr               -- ����R�[�h
--        ,gv_invoice_num                       -- �������ԍ�
--        ,gv_item_class_code_hdr               -- �i�ڋ敪
--        ,gn_payment_amount_all                -- �x�����z�i�ō��j
--        --WHO�J����
--        ,cn_created_by
--        ,cd_creation_date
--        ,cn_last_updated_by
--        ,cd_last_update_date
--        ,cn_last_update_login
--        ,cn_request_id
--        ,cn_program_application_id
--        ,cn_program_id
--        ,cd_program_update_date
--       );
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
--                  , iv_name         => cv_msg_cfo_10040
--                  , iv_token_name1  => cv_tkn_data                    -- �f�[�^
--                  , iv_token_value1 => cv_msg_out_data_10             -- �d�����уA�h�I��
--                  , iv_token_name2  => cv_tkn_vendor_site_code        -- �d����T�C�g�R�[�h
--                  , iv_token_value2 => gv_vendor_site_code_hdr
--                  , iv_token_name3  => cv_tkn_department              -- ����
--                  , iv_token_value3 => gv_department_code_hdr
--                  , iv_token_name4  => cv_tkn_item_kbn                -- �i�ڋ敪
--                  , iv_token_value4 => gv_item_class_code_hdr
--                  );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END ins_rcv_result;
----
--  /**********************************************************************************
--   * Procedure Name   : upd_proc_flag
--   * Description      : �����σt���O�X�V(A-10)
--   ***********************************************************************************/
--  PROCEDURE upd_proc_flag(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_proc_flag'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--    -- *** ���[�J��TABLE�^ ***
--    TYPE l_vendor_site_code_ttype IS TABLE OF xxcfo_offset_amount_info.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
--    lt_vendor_site_code    l_vendor_site_code_ttype;
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    -- ====================================================
--    -- �J�z���Ƃ��ď��������f�[�^�ɁA�����σt���O�𗧂Ă�
--    -- ====================================================
--    -- ���E���z���ɑ΂��čs���b�N���擾
--    BEGIN
--      SELECT xoai.vendor_site_code
--      BULK COLLECT INTO lt_vendor_site_code
--      FROM   xxcfo_offset_amount_info xoai                            -- ���E���z���
--      -- 2015-02-10 Ver1.3 Mod Start
----      WHERE  xoai.vendor_site_code       = gv_vendor_site_code_hdr    -- �d����T�C�g�R�[�h
--      WHERE  xoai.vendor_code            = gv_vendor_code_hdr         -- �d����R�[�h
--      -- 2015-02-10 Ver1.3 Mod End
--      AND    xoai.dept_code              = gv_department_code_hdr     -- ����R�[�h
--      AND    xoai.item_kbn               = gv_item_class_code_hdr     -- �i�ڋ敪
--      AND    xoai.data_type              = cv_data_type_1             -- �f�[�^�^�C�v�i1:�d���J�z�j
--      AND    xoai.proc_flag              = cv_flag_n                  -- �����σt���O�iN�j
--      AND    xoai.target_month           <> gv_period_name            -- �{�����ō쐬�����f�[�^�ȊO
--      FOR UPDATE NOWAIT
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--      --
--      WHEN global_lock_expt THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
--                  , iv_name         => cv_msg_cfo_00019               -- ���b�N�G���[
--                  , iv_token_name1  => cv_tkn_table                   -- �e�[�u��
--                  , iv_token_value1 => cv_msg_out_data_01             -- ���E���z���
--                  );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
----
--    -- �����σt���O�X�V
--    BEGIN
--      UPDATE xxcfo_offset_amount_info xoai                            -- ���E���z���
--      SET    xoai.proc_flag  = cv_flag_y
--            ,xoai.proc_date  = SYSDATE
--      -- 2015-02-10 Ver1.3 Mod Start
----      WHERE  xoai.vendor_site_code       = gv_vendor_site_code_hdr    -- �d����T�C�g�R�[�h
--      WHERE  xoai.vendor_code            = gv_vendor_code_hdr         -- �d����R�[�h
--      -- 2015-02-10 Ver1.3 Mod End
--      AND    xoai.dept_code              = gv_department_code_hdr     -- ����R�[�h
--      AND    xoai.item_kbn               = gv_item_class_code_hdr     -- �i�ڋ敪
--      AND    xoai.data_type              = cv_data_type_1             -- �f�[�^�^�C�v�i1:�d���J�z�j
--      AND    xoai.proc_flag              = cv_flag_n                  -- �����σt���O�iN�j
--      AND    xoai.target_month           <> gv_period_name            -- �{�����ō쐬�����f�[�^�ȊO
--      ;
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--      --
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
--                  , iv_name         => cv_msg_cfo_10040
--                  , iv_token_name1  => cv_tkn_data                    -- �f�[�^
--                  , iv_token_value1 => cv_msg_out_data_01             -- ���E���z���
--                  , iv_token_name2  => cv_tkn_vendor_site_code        -- �d����T�C�g�R�[�h
--                  , iv_token_value2 => gv_vendor_site_code_hdr
--                  , iv_token_name3  => cv_tkn_department              -- ����
--                  , iv_token_value3 => gv_department_code_hdr
--                  , iv_token_name4  => cv_tkn_item_kbn                -- �i�ڋ敪
--                  , iv_token_value4 => gv_item_class_code_hdr
--                  );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END upd_proc_flag;
----
-- 2015-02-26 Ver1.4 Del End
  /**********************************************************************************
   * Procedure Name   : get_ap_invoice_data
   * Description      : AP������OIF��񒊏o(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_ap_invoice_data(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_invoice_data'; -- �v���O������
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
    cv_doc_type_porc         CONSTANT VARCHAR2(30)  := 'PORC';           -- �w���֘A
    cv_doc_type_adji         CONSTANT VARCHAR2(30)  := 'ADJI';           -- �݌ɒ���
    cv_reason_cd_x201        CONSTANT VARCHAR2(30)  := 'X201';           -- �d����ԕi
    cv_kousen_type_yen       CONSTANT VARCHAR2(1)   := '1';              -- ���K�敪�i1:�~�j
    cv_kousen_type_ritsu     CONSTANT VARCHAR2(1)   := '2';              -- ���K�敪�i2:���j
    cv_txns_type_1           CONSTANT VARCHAR2(1)   := '1';              -- ����敪�i1:����j
    cv_txns_type_2           CONSTANT VARCHAR2(1)   := '2';              -- ����敪�i2:�d����ԕi�j
    cv_txns_type_3           CONSTANT VARCHAR2(1)   := '3';              -- ����敪�i3:�����Ȃ��ԕi�j
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- ����
    cv_source_doc_cd_rma     CONSTANT VARCHAR2(5)   := 'RMA';
--
    cv_proc_type_1           CONSTANT VARCHAR2(1)   := '1';              -- ���������敪�i1:�J�z�����j
    cv_proc_type_2           CONSTANT VARCHAR2(1)   := '2';              -- ���������敪�i2:�o�^�����j
    -- 2015-02-06 Ver1.2 Add Start
    cn_rcv_pay_div_1         CONSTANT NUMBER        := 1;                -- �󕥋敪�F�P
    -- 2015-02-06 Ver1.2 Add End
--
    -- *** ���[�J���ϐ� ***
    ln_out_count             NUMBER       DEFAULT 0;                     -- �������J�E���g
    ln_tax_cnt               NUMBER       DEFAULT 0;                     -- ���������׃J�E���g�i�ŗ��̎�ސ��j
-- 2019-04-04 Ver1.6 Mod Start
--    ln_tax_rate_jdge         NUMBER       DEFAULT 0;                     -- ����ŗ�(����p)
    lv_tax_code_jdge         VARCHAR2(10) DEFAULT NULL;                  -- ����ŃR�[�h��(����p)
-- 2019-04-04 Ver1.6 Mod End
    lv_proc_type             VARCHAR2(1)  DEFAULT NULL;                  -- �������������p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\���iSELECT���@�`�C��UNION ALL�j
    CURSOR get_ap_invoice_cur
    IS
      SELECT  trn.vendor_code                                 AS vendor_code              -- �d����R�[�h
             ,trn.vendor_site_code                            AS vendor_site_code         -- �d����T�C�g�R�[�h
             ,trn.vendor_site_id                              AS vendor_site_id           -- �d����T�C�gID
             ,trn.department_code                             AS department_code          -- ����R�[�h
             ,trn.item_class_code                             AS item_class_code          -- �i�ڋ敪
             ,trn.target_period                               AS target_period            -- �Ώ۔N��
             ,trn.txns_id                                     AS txns_id                  -- ���ID
             ,trn.trans_qty                                   AS trans_qty                -- �������
             ,trn.order_amount_net                            AS order_amount_net         -- �d�����z�i�Ŕ��j
             ,trn.tax_rate                                    AS tax_rate                 -- ����ŗ�
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_net      )                AS commission_net           -- ���K���z�i�Ŕ��j<����-���K>
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_tax      )                AS commission_tax           -- ���K����ŋ��z
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_net + trn.commission_tax) AS commission_price       -- ���K���z�i�ō��j
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.assessment )                         AS assessment               -- ���ۋ��z<����-���ۋ�>
             ,trn.order_amount_net                            AS payment_amount_net       -- �x�����z�i�Ŕ��j<����-�{��>
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,trn.payment_tax + trn.commission_tax
                    ,cv_item_class_2
                    ,trn.payment_tax + trn.commission_tax
                    ,trn.payment_tax   )                      AS payment_tax              -- �x������Ŋz<����-�����>
             ,trn.order_amount_net + trn.payment_tax
               - (DECODE(trn.item_class_code
                        ,cv_item_class_5       -- ���i
                        ,commission_tax * -1   -- ���K����ł��v���X����
                        ,cv_item_class_2       -- ����
                        ,commission_tax * -1   -- ���K����ł��v���X����
                        ,trn.commission_net + trn.assessment))  AS payment_amount           -- �x�����z�i�ō��j<�w�b�_-���z>
-- 2019-04-04 Ver1.6 Add Start
             ,trn.tax_code                                    AS tax_code                 -- ����ŃR�[�h�i�ېŎd���i�O�Łj�j
-- 2019-04-04 Ver1.6 Add End
      FROM(-- ���o�@�i������сj
-- 2019-04-04 Ver1.6 Mod Start
--           SELECT  xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
           SELECT  /*+ PUSH_PRED(xitrv) */
                   xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
-- 2019-04-04 Ver1.6 Mod End
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- �d����T�C�g�R�[�h
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- �d����T�C�gID
                  ,pha.attribute10                 AS department_code           -- ����R�[�h
                  ,xic5v.item_class_code           AS item_class_code           -- �i�ڋ敪
                  ,SUBSTRB(pha.attribute4,1,7)     AS target_period             -- �Ώ۔N��
                  ,xrart.txns_id                   AS txns_id                   -- ���ID
                  -- 2015-02-06 Ver1.2 Mod Start
--                  ,SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
                  ,SUM(NVL(xrart.quantity, 0) * cn_rcv_pay_div_1)
                  -- 2015-02-06 Ver1.2 Mod End
                                                   AS trans_qty                 -- �������
-- 2019-04-04 Ver1.6 Mod Start
--                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod Start
--                  ,TO_NUMBER(xitrv.tax)            AS tax_rate                  -- ����ŗ�
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                  -- 2015-02-06 Ver1.2 Mod Start
--                  ,ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0)
--                     * TO_NUMBER(xrpm.rcv_pay_div))) AS order_amount_net        -- �d�����z�i�Ŕ��j
                  ,ROUND(NVL(pla.unit_price, 0) * SUM(NVL(xrart.quantity, 0)
                     * cn_rcv_pay_div_1))          AS order_amount_net        -- �d�����z�i�Ŕ��j
                  -- 2015-02-06 Ver1.2 Mod End
                  ,CASE plla.attribute3   -- ���K�敪
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       -- 2015-02-06 Ver1.2 Mod Start
--                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0)
--                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
--                         - ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(xrart.quantity, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * cn_rcv_pay_div_1)) * TO_NUMBER(xlv2v.lookup_code) / 100)
--                         - ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(xrart.quantity, 0))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * cn_rcv_pay_div_1)) * TO_NUMBER(xitrv.tax) / 100)
                         - ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(xrart.quantity, 0))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                       -- 2015-02-06 Ver1.2 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       -- 2015-02-06 Ver1.2 Mod Start
--                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0) 
--                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
--                         - ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) 
--                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(xrart.quantity, 0) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * cn_rcv_pay_div_1)) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * cn_rcv_pay_div_1)) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                         - ROUND(TRUNC( pla.attribute8 * SUM(NVL(xrart.quantity, 0)) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                       -- 2015-02-06 Ver1.2 Mod End
                     ELSE 
                       -- 2015-02-06 Ver1.2 Mod Start
--                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0) 
--                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(xrart.quantity, 0) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * cn_rcv_pay_div_1)) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * cn_rcv_pay_div_1)) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                       -- 2015-02-06 Ver1.2 Mod End
                     END                           AS payment_tax               -- �x������ŋ��z
                  ,CASE plla.attribute3   -- ���K�敪
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       -- 2015-02-06 Ver1.2 Mod Start
--                       TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0)))
                       TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(xrart.quantity, 0)))
                       -- 2015-02-06 Ver1.2 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       -- 2015-02-06 Ver1.2 Mod Start
--                       TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute4, 0) / 100 )
                       TRUNC( pla.attribute8 * SUM(NVL(xrart.quantity, 0)) * NVL(plla.attribute4, 0) / 100 )
                       -- 2015-02-06 Ver1.2 Mod End
                     ELSE 
                       0 
                     END                           AS commission_net            -- ���K���z�i�Ŕ��j
                  ,CASE plla.attribute3   -- ���K�敪
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       -- 2015-02-06 Ver1.2 Mod Start
--                       ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) 
--                         * TO_NUMBER(xlv2v.lookup_code) / 100) 
                       ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(xrart.quantity, 0))) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * TO_NUMBER(xlv2v.lookup_code) / 100) 
-- 2019-10-29 Ver1.7 Mod Start
--                         * TO_NUMBER(xitrv.tax) / 100) 
                         * TO_NUMBER(xlv2v.lookup_code) / 100) 
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                       -- 2015-02-06 Ver1.2 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       -- 2015-02-06 Ver1.2 Mod Start
--                       ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0))
--                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       ROUND(TRUNC( pla.attribute8 * SUM(NVL(xrart.quantity, 0))
-- 2019-04-04 Ver1.6 Mod Start
--                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod Start
--                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xitrv.tax) / 100)
                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                       -- 2015-02-06 Ver1.2 Mod End
                     ELSE 
                       0 
                     END                           AS commission_tax            -- ���K����ŋ��z
                  ,CASE plla.attribute6   -- ���ۋ��敪
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       -- 2015-02-06 Ver1.2 Mod Start
--                       TRUNC( NVL(plla.attribute7,0) * SUM(NVL(itp.trans_qty, 0)))
                       TRUNC( NVL(plla.attribute7,0) * SUM(NVL(xrart.quantity, 0)))
                       -- 2015-02-06 Ver1.2 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       -- 2015-02-06 Ver1.2 Mod Start
--                       TRUNC((pla.attribute8 * SUM(NVL(itp.trans_qty, 0))
--                         - pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute1,0) / 100)
--                         * NVL(plla.attribute7,0) / 100)
                       TRUNC((pla.attribute8 * SUM(NVL(xrart.quantity, 0))
                         - pla.attribute8 * SUM(NVL(xrart.quantity, 0)) * NVL(plla.attribute1,0) / 100)
                         * NVL(plla.attribute7,0) / 100)
                       -- 2015-02-06 Ver1.2 Mod End
                     ELSE 
                       0 
                     END                           AS assessment                -- ���ۋ��z
-- 2019-04-04 Ver1.6 Add Start
                  ,xitrv.tax_code_ex               AS tax_code                  -- ����ŃR�[�h�i�ېŎd���i�O�Łj�j
-- 2019-04-04 Ver1.6 Add End
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- ����ԕi���уA�h�I��
--                  ,ic_tran_pnd                     itp                          -- �ۗ��݌Ƀg�����U�N�V����   -- 2015-02-06 Ver1.2 Del
                  ,po_headers_all                  pha                          -- �����w�b�_
                  ,xxpo_headers_all                xha                          -- �����w�b�_�A�h�I��
                  ,po_lines_all                    pla                          -- ��������
                  ,po_line_locations_all           plla                         -- �����[������
--                  ,rcv_shipment_lines              rsl                          -- �������                   -- 2015-02-06 Ver1.2 Del
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM�i�ڃJ�e�S���������VIEW5
                  ,xxcmn_vendors_v                 xvv_vendor                   -- �d������VIEW�i�����j
                  ,po_vendor_sites_all             pvsa                         -- �d����T�C�g�i�H��j
--                  ,rcv_transactions                rt                           -- ������                   -- 2015-02-06 Ver1.2 Del
--                  ,xxcmn_rcv_pay_mst               xrpm                         -- �󕥋敪�A�h�I���}�X�^     -- 2015-02-06 Ver1.2 Del
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add Start
                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add End
                  ,xxcmm_item_tax_rate_v           xitrv                        -- ����ŗ��r���[
-- 2019-04-04 Ver1.6 Mod End
           WHERE   xrart.txns_type                 = cv_txns_type_1             -- ���ы敪�F1�i����j
           AND     xrart.source_document_number    = pha.segment1
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pha.segment1                    = xha.po_header_number
           -- 2015-02-06 Ver1.2 Del Start
--           AND     pha.po_header_id                = rsl.po_header_id
--           AND     rsl.shipment_header_id          = itp.doc_id
--           AND     rsl.line_num                    = itp.doc_line
--           AND     itp.doc_type                    = cv_doc_type_porc           -- �w���֘A
--           AND     itp.completed_ind               = cn_completed_ind           -- ����
--           AND     rsl.po_line_id                  = pla.po_line_id
           -- 2015-02-06 Ver1.2 Del Start
           AND     pla.po_line_id                  = plla.po_line_id
           AND     pha.vendor_id                   = xvv_vendor.vendor_id
           AND     pla.attribute2                  = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           -- 2015-02-06 Ver1.2 Del Start
--           AND     rt.transaction_id               = itp.line_id
--           AND     rt.shipment_line_id             = rsl.shipment_line_id
--           AND     rt.transaction_type             = xrpm.transaction_type
--           AND     xrpm.doc_type                   = itp.doc_type
--           AND     xrpm.source_document_code       <> cv_source_doc_cd_rma
--           AND     xrpm.source_document_code       = rsl.source_document_code
--           AND     xrpm.break_col_05               IS NOT NULL
           -- 2015-02-06 Ver1.2 Del Start
-- 2019-04-04 Ver1.6 Mod Start
--           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
--           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
--           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-10-29 Ver1.7 Add Start
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-10-29 Ver1.7 Add End
           AND     xitrv.item_id                   = xrart.item_id          -- ����ԕi���уA�h�I��.�i��ID
           AND     xitrv.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     NVL(xitrv.end_date_active ,TO_DATE(pha.attribute4, 'YYYY/MM/DD')) >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-04-04 Ver1.6 Mod End
           AND     TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN gd_target_date_from  -- �[����
                                                        AND     gd_target_date_to
           -- 2015-02-06 Ver1.2 Mod Start
--           -- 2015-01-26 Ver1.1 Add Start
--           and     xrart.txns_id                   = rsl.attribute1
--           -- 2015-01-26 Ver1.1 Add End
           AND     pha.po_header_id = pla.po_header_id
           -- 2015-02-06 Ver1.2 Mod End
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,pha.attribute10
                  ,xic5v.item_class_code
                  ,SUBSTRB(pha.attribute4,1,7)
                  ,xrart.txns_id
--                  ,xrpm.rcv_pay_div                 -- 2015-02-06 Ver1.2 Del
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add Start
                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add End
                  ,xitrv.tax
                  ,xitrv.tax_code_ex
-- 2019-04-04 Ver1.6 Mod End
                  ,pla.attribute8
                  ,plla.attribute3
                  ,pla.unit_price
                  ,plla.attribute4
                  ,plla.attribute6
                  ,plla.attribute7
                  ,plla.attribute1
--
         UNION ALL
           -- ���o�A�i�d����ԕi�j
-- 2019-04-04 Ver1.6 Mod Start
--           SELECT  xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
           SELECT  /*+ PUSH_PRED(xitrv) */
                   xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
-- 2019-04-04 Ver1.6 Mod End
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- �d����T�C�g�R�[�h
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- �d����T�C�gID
                  ,pha.attribute10                 AS department_code           -- ����R�[�h
                  ,xic5v.item_class_code           AS item_class_code           -- �i�ڋ敪
                  ,SUBSTRB(pha.attribute4,1,7)     AS target_period             -- �Ώ۔N��
                  ,xrart.txns_id                   AS txns_id                   -- ���ID
                  ,SUM(NVL(itc.trans_qty, 0)) * ABS(TO_NUMBER(xrpm.rcv_pay_div))
                                                   AS trans_qty                 -- �������
-- 2019-04-04 Ver1.6 Mod Start
--                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod Start
--                  ,TO_NUMBER(xitrv.tax)            AS tax_rate                  -- ����ŗ�
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                  ,ROUND(NVL(xrart.kobki_converted_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                                                   AS order_amount_net          -- �d�����z�i�Ŕ��j
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                         - ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                         - ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
-- 2019-04-04 Ver1.6 Mod Start
--                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     ELSE 
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     END                           AS payment_tax               -- �x������ŋ��z
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                       * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                     ELSE 
                       0 
                     END                           AS commission_net            -- ���K���z�i�Ŕ��j
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod Start
--                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0)) 
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod Start
--                         * TO_NUMBER(xitrv.tax) / 100)
                         * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                     ELSE 
                       0 
                     END                           AS commission_tax            -- ���K����ŋ��z
                  ,CASE xrart.fukakin_type 
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       TRUNC( NVL(xrart.fukakin_rate_or_unit_price, 0) * ABS(SUM(NVL(itc.trans_qty, 0)))) * -1
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       TRUNC((xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0)))
                         - xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) * NVL(xrart.kobiki_rate,0) / 100)
                         * NVL(xrart.fukakin_rate_or_unit_price,0) / 100) * -1
                     ELSE 
                       0 
                     END                           AS assessment                -- ���ۋ��z
-- 2019-04-04 Ver1.6 Add Start
                  ,xitrv.tax_code_ex               AS tax_code                  -- ����ŃR�[�h�i�ېŎd���i�O�Łj�j
-- 2019-04-04 Ver1.6 Add End
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- ����ԕi���уA�h�I��
                  ,po_headers_all                  pha                          -- �����w�b�_
                  ,xxpo_headers_all                xha                          -- �����w�b�_�A�h�I��
                  ,po_lines_all                    pla                          -- ��������
                  ,po_line_locations_all           plla                         -- �����[������
                  ,ic_jrnl_mst                     ijm                          -- �W���[�i���}�X�^
                  ,ic_adjs_jnl                     iaj                          -- �݌ɒ����W���[�i��
                  ,ic_tran_cmp                     itc                          -- �����݌Ƀg�����U�N�V����
                  ,xxcmn_vendors_v                 xvv_vendor                   -- �d������VIEW�i�����j
                  ,po_vendor_sites_all             pvsa                         -- �d����T�C�g�i�H��j
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM�i�ڃJ�e�S���������VIEW5
                  ,xxcmn_rcv_pay_mst               xrpm                         -- �󕥋敪�A�h�I���}�X�^
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add Start
                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add End
                  ,xxcmm_item_tax_rate_v           xitrv                        -- ����ŗ��r���[
-- 2019-04-04 Ver1.6 Mod End
           WHERE   xrart.txns_type                 = cv_txns_type_2             -- ���ы敪�F2�i�d����ԕi�j
           AND     xrart.source_document_number    = pha.segment1
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pha.segment1                    = xha.po_header_number
           AND     pha.po_header_id                = pla.po_header_id
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pla.po_header_id                = plla.po_header_id
           AND     pla.po_line_id                  = plla.po_line_id
           AND     TO_CHAR(xrart.txns_id)          = ijm.attribute1
           AND     itc.doc_type                    = cv_doc_type_adji           -- �I������
           AND     itc.reason_code                 = cv_reason_cd_x201          -- �d����ԕi
           AND     ijm.journal_id                  = iaj.journal_id
           AND     iaj.doc_id                      = itc.doc_id
           AND     iaj.doc_line                    = itc.doc_line
           AND     pha.vendor_id                   = xvv_vendor.vendor_id(+)
           AND     pla.attribute2                  = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           AND     itc.doc_type                    = xrpm.doc_type
           AND     itc.reason_code                 = xrpm.reason_code
           AND     xrpm.break_col_05               IS NOT NULL
-- 2019-04-04 Ver1.6 Mod Start
--           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
--           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
--           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-10-29 Ver1.7 Add Start
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-10-29 Ver1.7 Add End
           AND     xitrv.item_id                   = xrart.item_id          -- ����ԕi���уA�h�I��.�i��ID
           AND     xitrv.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     NVL(xitrv.end_date_active ,TO_DATE(pha.attribute4, 'YYYY/MM/DD')) >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
-- 2019-04-04 Ver1.6 Mod End
           and     xrart.txns_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,pha.attribute10
                  ,xic5v.item_class_code
                  ,SUBSTRB(pha.attribute4,1,7)
                  ,xrart.txns_id
                  ,xrpm.rcv_pay_div
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add Start
                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add End
                  ,xitrv.tax
                  ,xitrv.tax_code_ex
-- 2019-04-04 Ver1.6 Mod End
                  ,xrart.unit_price
                  ,xrart.kousen_type
                  ,xrart.kobki_converted_unit_price
                  ,xrart.kousen_rate_or_unit_price
                  ,xrart.fukakin_type
                  ,xrart.fukakin_rate_or_unit_price
                  ,xrart.kobiki_rate
           --
         UNION ALL
           -- ���o�B�i�����Ȃ��ԕi�j
-- 2019-04-04 Ver1.6 Mod Start
--           SELECT  xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
           SELECT  /*+ PUSH_PRED(xitrv) */
                   xvv_vendor.segment1             AS vendor_code               -- �d����R�[�h
-- 2019-04-04 Ver1.6 Mod End
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- �d����T�C�g�R�[�h
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- �d����T�C�gID
                  ,xrart.department_code           AS department_code           -- ����R�[�h
                  ,xic5v.item_class_code           AS item_class_code           -- �i�ڋ敪
                  ,SUBSTRB(xrart.txns_date,1,7)    AS target_period             -- �Ώ۔N��
                  ,xrart.txns_id                   AS txns_id                   -- ���ID
                  ,SUM(NVL(itc.trans_qty, 0)) * ABS(TO_NUMBER(xrpm.rcv_pay_div))
                                                   AS trans_qty                 -- �������
-- 2019-04-04 Ver1.6 Mod Start
--                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod Start
--                  ,TO_NUMBER(xitrv.tax)            AS tax_rate                  -- ����ŗ�
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- ����ŗ�
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                  ,ROUND(NVL(xrart.kobki_converted_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) 
                                                   AS order_amount_net          -- �d�����z�i�Ŕ��j
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                         - ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                         - ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
-- 2019-04-04 Ver1.6 Mod Start
--                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     ELSE 
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
-- 2019-04-04 Ver1.6 Mod Start
--                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
-- 2019-04-04 Ver1.6 Mod End
                     END                           AS payment_tax               -- �x������ŋ��z
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                       * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                     ELSE 
                       0 
                     END                           AS commission_net            -- ���K���z�i�Ŕ��j
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod Start
--                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xitrv.tax) / 100)
                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0)) 
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) 
-- 2019-04-04 Ver1.6 Mod Start
--                         * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod Start
--                         * TO_NUMBER(xitrv.tax) / 100)
                         * TO_NUMBER(xlv2v.lookup_code) / 100)
-- 2019-10-29 Ver1.7 Mod End
-- 2019-04-04 Ver1.6 Mod End
                     ELSE 
                       0 
                     END                           AS commission_tax            -- ���K����ŋ��z
                  ,CASE xrart.fukakin_type 
                     WHEN cv_kousen_type_yen THEN     -- 1:�~
                       TRUNC( NVL(xrart.fukakin_rate_or_unit_price, 0) * ABS(SUM(NVL(itc.trans_qty, 0)))) * -1
                     WHEN cv_kousen_type_ritsu THEN   -- 2:��
                       TRUNC((xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0)))
                         - xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) * NVL(xrart.kobiki_rate,0) / 100)
                         * NVL(xrart.fukakin_rate_or_unit_price,0) / 100) * -1
                     ELSE 
                       0 
                     END                           AS assessment                -- ���ۋ��z
-- 2019-04-04 Ver1.6 Add Start
                  ,xitrv.tax_code_ex               AS tax_code                  -- ����ŃR�[�h�i�ېŎd���i�O�Łj�j
-- 2019-04-04 Ver1.6 Add End
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- ����ԕi����
                  ,ic_jrnl_mst                     ijm                          -- �W���[�i���}�X�^
                  ,ic_adjs_jnl                     iaj                          -- �݌ɒ����W���[�i��
                  ,ic_tran_cmp                     itc                          -- �����݌Ƀg�����U�N�V����
                  ,xxcmn_vendors_v                 xvv_vendor                   -- �d������VIEW�i�����j
                  ,po_vendor_sites_all             pvsa                         -- �d����T�C�g�i�H��j
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM�i�ڃJ�e�S���������VIEW5
                  ,xxcmn_rcv_pay_mst               xrpm                         -- �󕥋敪�A�h�I���}�X�^
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add Start
                  ,xxcmn_lookup_values2_v          xlv2v                        -- ����ŗ����VIEW
-- 2019-10-29 Ver1.7 Add End
                  ,xxcmm_item_tax_rate_v           xitrv                        -- ����ŗ��r���[
-- 2019-04-04 Ver1.6 Mod End
           WHERE   xrart.txns_type                 = cv_txns_type_3             -- ���ы敪�F3�i�����Ȃ��ԕi�j
           AND     TO_CHAR(xrart.txns_id)          = ijm.attribute1
           AND     itc.doc_type                    = cv_doc_type_adji           -- �I������
           AND     itc.reason_code                 = cv_reason_cd_x201          -- �d����ԕi
           AND     ijm.journal_id                  = iaj.journal_id
           AND     iaj.doc_id                      = itc.doc_id
           AND     iaj.doc_line                    = itc.doc_line
           AND     xrart.vendor_id                 = xvv_vendor.vendor_id
           AND     xrart.factory_code              = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           AND     itc.doc_type                    = xrpm.doc_type
           AND     itc.reason_code                 = xrpm.reason_code
           AND     xrpm.break_col_05               IS NOT NULL
-- 2019-04-04 Ver1.6 Mod Start
--           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
--           AND     xlv2v.start_date_active         < xrart.txns_date + 1
--           AND     xlv2v.end_date_active           >= xrart.txns_date
-- 2019-10-29 Ver1.7 Add Start
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- �Q�ƃ^�C�v�F����ŗ��}�X�^
           AND     xlv2v.start_date_active         < xrart.txns_date + 1
           AND     xlv2v.end_date_active           >= xrart.txns_date
-- 2019-10-29 Ver1.7 Add End
           AND     xitrv.item_id                   = xrart.item_id          -- ����ԕi���уA�h�I��.�i��ID
           AND     xitrv.start_date_active         < xrart.txns_date + 1
           AND     NVL(xitrv.end_date_active ,xrart.txns_date) >= xrart.txns_date
-- 2019-04-04 Ver1.6 Mod End
           AND     xrart.txns_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,xrart.department_code
                  ,xic5v.item_class_code
                  ,SUBSTRB(xrart.txns_date,1,7)
                  ,xrart.txns_id
                  ,xrpm.rcv_pay_div
-- 2019-04-04 Ver1.6 Mod Start
--                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add Start
                  ,xlv2v.lookup_code
-- 2019-10-29 Ver1.7 Add End
                  ,xitrv.tax
                  ,xitrv.tax_code_ex
-- 2019-04-04 Ver1.6 Mod End
                  ,xrart.unit_price
                  ,xrart.kousen_type
                  ,xrart.kobki_converted_unit_price
                  ,xrart.kousen_rate_or_unit_price
                  ,xrart.fukakin_type
                  ,xrart.fukakin_rate_or_unit_price
                  ,xrart.kobiki_rate
           --
-- 2015-02-26 Ver1.4 Del Start
--         UNION ALL
--           -- ���o�C�i�O���J�z���j
--           SELECT  xoai.vendor_code                AS vendor_code               -- �d����R�[�h
--                  ,xoai.vendor_site_code           AS vendor_site_code          -- �d����T�C�g�R�[�h
--                  ,xoai.vendor_site_id             AS vendor_site_id            -- �d����T�C�gID
--                  ,xoai.dept_code                  AS department_code           -- ����R�[�h
--                  ,xoai.item_kbn                   AS item_class_code           -- �i�ڋ敪
--                  ,xoai.target_month               AS target_period             -- �Ώ۔N��
--                  ,xoai.trn_id                     AS txns_id                   -- ���ID
--                  ,xoai.trans_qty                  AS trans_qty                 -- �������
--                  ,xoai.tax_rate                   AS tax_rate                  -- ����ŗ�
--                  ,xoai.order_amount_net           AS order_amount_net          -- �d�����z�i�Ŕ��j
--                  ,xoai.payment_tax                AS payment_tax               -- �x������ŋ��z
--                  ,xoai.commission_net             AS commission_net            -- ���K���z�i�Ŕ��j
--                  ,xoai.commission_tax             AS commission_tax            -- ���K����ŋ��z
--                  ,xoai.assessment                 AS assessment                -- ���ۋ��z
--           FROM    xxcfo_offset_amount_info        xoai                         -- ���E���z���e�[�u��
--           WHERE   xoai.data_type                  = cv_data_type_1             -- 1:�d���J�z
--           AND     xoai.proc_flag                  = cv_flag_n                  -- N:������
-- 2015-02-26 Ver1.4 Del End
          ) trn
      ORDER BY  vendor_code                     -- �d����R�[�h
               -- 2015-02-10 Ver1.3 Del Start
--               ,vendor_site_code                -- �d����T�C�g�R�[�h
               -- 2015-02-10 Ver1.3 Del End
               ,department_code                 -- ����R�[�h
               ,item_class_code                 -- �i�ڋ敪
-- 2019-10-29 Ver1.7 Del Start
--               ,tax_rate                        -- ����ŗ�
-- 2019-10-29 Ver1.7 Del End
-- 2019-04-04 Ver1.6 Add Start
               ,tax_code                        -- ����ŃR�[�h
-- 2019-04-04 Ver1.6 Add End
    ;
    -- ���R�[�h�^
    ap_invoice_rec get_ap_invoice_cur%ROWTYPE;
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
    <<main_loop>>
    OPEN get_ap_invoice_cur;
    LOOP 
      FETCH get_ap_invoice_cur INTO ap_invoice_rec;
--
      -- �u���C�N�L�[�i�d����R�[�h�^����R�[�h�^�i�ڋ敪�j���O���R�[�h�ƈقȂ�ꍇ(1���R�[�h�ڂ͏���)
      -- �܂��A�ŏI���R�[�h�̏ꍇ�A�������P�ʂł̋��z�`�F�b�N���s���B
      -- 2015-02-10 Ver1.3 Mod Start
--      IF (((NVL(gv_vendor_site_code_hdr,ap_invoice_rec.vendor_site_code) <> ap_invoice_rec.vendor_site_code)
      IF (((NVL(gv_vendor_code_hdr,ap_invoice_rec.vendor_code) <> ap_invoice_rec.vendor_code)
      -- 2015-02-10 Ver1.3 Mod End
          OR (NVL(gv_department_code_hdr,ap_invoice_rec.department_code) <> ap_invoice_rec.department_code)
          OR (NVL(gv_item_class_code_hdr,ap_invoice_rec.item_class_code) <> ap_invoice_rec.item_class_code))
-- 2019-04-04 Ver1.6 Mod Start
--          AND NVL(gn_payment_amount_all,0) <> 0 )
          )
-- 2019-04-04 Ver1.6 Mod End
         OR (get_ap_invoice_cur%NOTFOUND)
      THEN
-- 2019-04-04 Ver1.6 Add Start
        IF ( NVL(gn_payment_amount_all,0) <> 0 ) THEN
-- 2019-04-04 Ver1.6 Add End
          -- �������P�ʂŁu�x�����z�i�ō��j�v�̍��v���z���}�C�i�X�̏ꍇ
          IF (gn_payment_amount_all < 0 ) THEN 
            lv_proc_type := cv_proc_type_1;
          ELSIF (gn_payment_amount_all >= 0) THEN
            lv_proc_type := cv_proc_type_2;
          ELSE
            -- �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�A���[�v�𔲂���
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cfo
                            , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_11            -- ���Y����f�[�^
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_08            -- ��v����
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => iv_period_name
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
--
-- 2015-02-26 Ver1.4 Mod Start
--        -- �������P�ʂŎx�����z���}�C�i�X�̏ꍇ�́A�����ɌJ�z�����������{
--        IF (lv_proc_type = cv_proc_type_1) THEN
----
--          -- ===============================
--          -- �J�z���o�^(A-5)
--          -- ===============================
--          ins_offset_info(
--            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
--            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
--            ov_errmsg                => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            );
----
--          IF (lv_retcode <> cv_status_normal) THEN
--            RAISE global_process_expt;
--          END IF;
--
--        ELSIF (lv_proc_type = cv_proc_type_2) THEN
          IF (lv_proc_type = cv_proc_type_1 OR lv_proc_type = cv_proc_type_2) THEN
-- 2015-02-26 Ver1.4 Mod End
            -- ===============================
            -- AP�������w�b�_OIF�o�^(A-6)
            -- ===============================
            ins_ap_invoice_headers(
              ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
              ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ===============================
            -- AP����������OIF�o�^(A-7)
            -- ===============================
            ins_ap_invoice_lines(
              ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
              ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ===============================
            -- ���Y����f�[�^�X�V(A-8)
            -- ===============================
            upd_inv_trn_data(
              ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
              ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--
-- 2015-02-26 Ver1.4 Del Start
--          -- ===============================
--          -- �d�����уA�h�I���o�^(A-9)
--          -- ===============================
--          ins_rcv_result(
--            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
--            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
--            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--          IF (lv_retcode <> cv_status_normal) THEN
--            RAISE global_process_expt;
--          END IF;
----
-- 2015-02-26 Ver1.4 Del End
          END IF;
--
-- 2015-02-26 Ver1.4 Del Start
--        -- ===============================
--        -- �����σt���O�X�V(A-10)
--        -- ===============================
--        upd_proc_flag(
--          ov_errbuf                => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode               => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg                => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--        IF (lv_retcode <> cv_status_normal) THEN
--          RAISE global_process_expt;
--        END IF;
----
-- 2015-02-26 Ver1.4 Del End
-- 2019-04-04 Ver1.6 Add Start
        END IF;
-- 2019-04-04 Ver1.6 Add End
        -- �ŏI���R�[�h�̏ꍇ�A���[�v�𔲂���
        IF (get_ap_invoice_cur%NOTFOUND) THEN
          EXIT;
        END IF;
--
        -- �������P�ʂ̏������ϐ��̏����������{
        gv_vendor_code_hdr        := NULL;                -- �������P�ʁF�d����R�[�h�i���Y�j
        gv_vendor_site_code_hdr   := NULL;                -- �������P�ʁF�d����T�C�g�R�[�h�i���Y�j
        gn_vendor_site_id_hdr     := NULL;                -- �������P�ʁF�d����T�C�gID�i���Y�j
        gv_department_code_hdr    := NULL;                -- �������P�ʁF����R�[�h
        gv_item_class_code_hdr    := NULL;                -- �������P�ʁF�i�ڋ敪
        --
        gn_payment_amount_all     := 0;                   -- �������P�ʁF�x�����z�i�ō��j
        gn_commission_all         := 0;                   -- �������P�ʁF���K���z�i�Ŕ��j
        gn_assessment_all         := 0;                   -- �������P�ʁF���ۋ��z
        -- 2015-01-26 Ver1.1 Add Start
        gn_commission_tax_all     := 0;                   -- �������P�ʁF���K�����
        -- 2015-01-26 Ver1.1 Add End
        --
-- 2019-04-04 Ver1.6 Mod Start
--        ln_tax_rate_jdge          := 0;                   -- ����ŗ�(����p)
        lv_tax_code_jdge          := '';                   -- ����ŃR�[�h��(����p)
-- 2019-04-04 Ver1.6 Mod End
        ln_out_count              := 0;
        ln_tax_cnt                := 0;
        --
        g_ap_invoice_tab.DELETE;                          -- AP���������i�[�pPL/SQL�\
        g_ap_invoice_line_tab.DELETE;                     -- AP���������׏��i�[�pPL/SQL�\
--
      END IF;
--
      -- �������P�ʂ̏���ێ�
      gv_vendor_code_hdr        := ap_invoice_rec.vendor_code;                 -- �������P�ʁF�d����R�[�h�i���Y�j
      gv_vendor_site_code_hdr   := ap_invoice_rec.vendor_site_code;            -- �������P�ʁF�d����T�C�g�R�[�h�i���Y�j
      gn_vendor_site_id_hdr     := ap_invoice_rec.vendor_site_id;              -- �������P�ʁF�d����T�C�gID�i���Y�j
      gv_department_code_hdr    := ap_invoice_rec.department_code;             -- �������P�ʁF����R�[�h
      gv_item_class_code_hdr    := ap_invoice_rec.item_class_code;             -- �������P�ʁF�i�ڋ敪
--
      -- �l�̐ςݏグ���s���B
      gn_payment_amount_all     := NVL(gn_payment_amount_all,0) + ap_invoice_rec.payment_amount;     -- �������P�ʁF�x�����z�i�ō��j
      gn_commission_all         := NVL(gn_commission_all,0) + ap_invoice_rec.commission_net;         -- �������P�ʁF���K���z�i�Ŕ��j
      gn_assessment_all         := NVL(gn_assessment_all,0) + ap_invoice_rec.assessment;             -- �������P�ʁF���ۋ��z
      -- 2015-01-26 Ver1.1 Add Start
      gn_commission_tax_all     := NVL(gn_commission_tax_all,0) + ap_invoice_rec.commission_tax;     -- �������P�ʁF���K�����
      -- 2015-01-26 Ver1.1 Add End
--
      -- ����ŃR�[�h���Ƃ̐ςݏグ���s���B
-- 2019-04-04 Ver1.6 Mod Start
--      IF (NVL(ln_tax_rate_jdge,0) = 0) THEN
      IF (NVL(lv_tax_code_jdge,'') = '') THEN
-- 2019-04-04 Ver1.6 Mod End
        ln_tax_cnt := 1;
      --
-- 2019-04-04 Ver1.6 Mod Start
--      ELSIF (NVL(ln_tax_rate_jdge,0) <> ap_invoice_rec.tax_rate) THEN
      ELSIF (NVL(lv_tax_code_jdge,'') <> ap_invoice_rec.tax_code) THEN
-- 2019-04-04 Ver1.6 Mod End
        ln_tax_cnt := NVL(ln_tax_cnt,0) + 1;
      --
      END IF;
--
      g_ap_invoice_line_tab(ln_tax_cnt).tax_rate           := ap_invoice_rec.tax_rate;               -- ���������גP�ʁF����ŗ�
-- 2019-04-04 Ver1.6 Add Start
      g_ap_invoice_line_tab(ln_tax_cnt).tax_code           := ap_invoice_rec.tax_code;               -- ���������גP�ʁF����ŃR�[�h
-- 2019-04-04 Ver1.6 Add End
      g_ap_invoice_line_tab(ln_tax_cnt).payment_amount_net := NVL(g_ap_invoice_line_tab(ln_tax_cnt).payment_amount_net,0)
                                                             + ap_invoice_rec.payment_amount_net;    -- ���������גP�ʁF�d�����z�i�Ŕ��j
      g_ap_invoice_line_tab(ln_tax_cnt).commission_net     := NVL(g_ap_invoice_line_tab(ln_tax_cnt).commission_net,0)
                                                             + ap_invoice_rec.commission_net  ;      -- ���������גP�ʁF���K���z�i�Ŕ��j
      g_ap_invoice_line_tab(ln_tax_cnt).assessment         := NVL(g_ap_invoice_line_tab(ln_tax_cnt).assessment,0)
                                                             + ap_invoice_rec.assessment;            -- ���������גP�ʁF���ۋ��z
      g_ap_invoice_line_tab(ln_tax_cnt).payment_tax        := NVL(g_ap_invoice_line_tab(ln_tax_cnt).payment_tax,0)
                                                             + ap_invoice_rec.payment_tax;           -- ���������גP�ʁF�x������Ŋz
      -- 2015-01-26 Ver1.1 Add Start
      g_ap_invoice_line_tab(ln_tax_cnt).commission_tax     := NVL(g_ap_invoice_line_tab(ln_tax_cnt).commission_tax,0)
                                                             + ap_invoice_rec.commission_tax  ;      -- ���������גP�ʁF���K�����
      -- 2015-01-26 Ver1.1 Add End
-- 2019-04-04 Ver1.6 Mod Start
--      -- ����ŗ�(����p)��ێ�
--      ln_tax_rate_jdge                                     := ap_invoice_rec.tax_rate;
      -- ����ŃR�[�h(����p)��ێ�
      lv_tax_code_jdge                                     := ap_invoice_rec.tax_code;
-- 2019-04-04 Ver1.6 Mod End
--
      -- �J�z�������l�����A���o�����f�[�^��PL/SQL�\�ɑޔ�
      ln_out_count :=  ln_out_count + 1;
      --
      g_ap_invoice_tab(ln_out_count).vendor_code           := ap_invoice_rec.vendor_code;            -- �d����R�[�h
      g_ap_invoice_tab(ln_out_count).vendor_site_code      := ap_invoice_rec.vendor_site_code;       -- �d����T�C�g�R�[�h
      g_ap_invoice_tab(ln_out_count).vendor_site_id        := ap_invoice_rec.vendor_site_id;         -- �d����T�C�gID
      g_ap_invoice_tab(ln_out_count).department_code       := ap_invoice_rec.department_code;        -- ����R�[�h
      g_ap_invoice_tab(ln_out_count).item_class_code       := ap_invoice_rec.item_class_code;        -- �i�ڋ敪
      g_ap_invoice_tab(ln_out_count).target_period         := ap_invoice_rec.target_period;          -- �Ώ۔N��
      g_ap_invoice_tab(ln_out_count).txns_id               := ap_invoice_rec.txns_id;                -- ���ID
      g_ap_invoice_tab(ln_out_count).trans_qty             := ap_invoice_rec.trans_qty;              -- �������
      g_ap_invoice_tab(ln_out_count).tax_rate              := ap_invoice_rec.tax_rate;               -- ����ŗ�
      g_ap_invoice_tab(ln_out_count).order_amount_net      := ap_invoice_rec.order_amount_net;       -- �d�����z�i�Ŕ��j
      g_ap_invoice_tab(ln_out_count).payment_tax           := ap_invoice_rec.payment_tax;            -- �x������Ŋz
      g_ap_invoice_tab(ln_out_count).commission_net        := ap_invoice_rec.commission_net;         -- ���K���z�i�Ŕ��j
      g_ap_invoice_tab(ln_out_count).commission_tax        := ap_invoice_rec.commission_tax;         -- ���K����ŋ��z
      g_ap_invoice_tab(ln_out_count).assessment            := ap_invoice_rec.assessment;             -- ���ۋ��z
      g_ap_invoice_tab(ln_out_count).payment_amount_net    := ap_invoice_rec.payment_amount_net;     -- �x�����z�i�Ŕ��j
      g_ap_invoice_tab(ln_out_count).payment_amount        := ap_invoice_rec.payment_amount;         -- �x�����z�i�ō��݁j
--
      -- �����Ώی����J�E���g
      gn_target_cnt := gn_target_cnt +1;
--
    END LOOP main_loop;
--
    CLOSE get_ap_invoice_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_ap_invoice_cur%ISOPEN ) THEN
        CLOSE get_ap_invoice_cur;
      END IF;
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
      IF ( get_ap_invoice_cur%ISOPEN ) THEN
        CLOSE get_ap_invoice_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ap_invoice_data;
--
-- 2015-02-26 Ver1.4 Del Start
--  /**********************************************************************************
--   * Procedure Name   : del_offset_data
--   * Description      : �����σf�[�^�폜(A-11)
--   ***********************************************************************************/
--  PROCEDURE del_offset_data(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_offset_data'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
----
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    -- ===============================
--    -- �ߋ��̏����σf�[�^���폜
--    -- ===============================
--    BEGIN
--      DELETE FROM xxcfo_offset_amount_info xoai            -- ���E���z���e�[�u��
--      WHERE  xoai.data_type     = cv_data_type_1
--      AND    xoai.proc_flag     = cv_flag_y
--      AND    xoai.proc_date     < gd_target_date_to
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--    END;
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END del_offset_data;
----
-- 2015-02-26 Ver1.4 Del End
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : �A�g�Ǘ��e�[�u���o�^(A-12)
   ***********************************************************************************/
  PROCEDURE ins_mfg_if_control(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mfg_if_control'; -- �v���O������
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
    -- =====================================
    -- �A�g�Ǘ��e�[�u���ɓo�^
    -- =====================================
    INSERT INTO xxcfo_mfg_if_control(
       program_name                        -- �@�\��
      ,set_of_books_id                     -- ��v����ID
      ,period_name                         -- ��v����
      ,gl_process_flag                     -- GL�]���t���O
      --WHO�J����
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       cv_pkg_name                         -- �@�\�� 'XXCFO022A01C'
      ,gn_sales_set_of_bks_id              -- ��v����ID
      ,iv_period_name                      -- ��v����
      ,cv_flag_y                           -- GL�]���t���O
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
     );
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_mfg_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_transfer_cnt := 0;
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
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N(A-2)
    -- ===============================
    check_period_name(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- AP������OIF��񒊏o(A-3)
    -- ===============================
    get_ap_invoice_data(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2015-02-26 Ver1.4 Del Start
--    -- ===============================
--    -- �����σf�[�^�폜(A-11)
--    -- ===============================
--    del_offset_data(
--      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
--      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
--      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
----
-- 2015-02-26 Ver1.4 Del End
    -- ===============================
    -- �A�g�Ǘ��e�[�u���o�^(A-12)
    -- ===============================
    ins_mfg_if_control(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name      IN  VARCHAR2       -- 1.��v����
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
       iv_period_name                              -- 1.��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_transfer_cnt := 0;
      gn_error_cnt    := 1;
    END IF;
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
    --�J�z�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_cfo
                    ,iv_name         => cv_msg_cfo_10037
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_transfer_cnt)
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
END XXCFO022A01C;
/
