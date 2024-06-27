CREATE OR REPLACE PACKAGE BODY XXCFO022A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO022A02C(body)
 * Description      : AP�d��������񐶐��i�L���x���j
 * MD.050           : AP�d��������񐶐��i�L���x���j<MD050_CFO_022_A02>
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_period_name      ��v���ԃ`�F�b�N(A-2)
 *  get_fee_payment_data   �L���x���f�[�^���o(A-3,4)
 *  ins_ap_invoice_headers AP�������w�b�_OIF�o�^(A-5)
 *  ins_ap_invoice_lines   AP����������OIF�o�^(A-6)
 *  del_offset_data        �����σf�[�^�폜(A-7)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-8)
 *  ins_ap_invoice_tmp     OIF�ꎞ�\�f�[�^�o�^(A-10)
 *  upd_invoice_oif        AP������OIF�X�V(A-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-24    1.0   K.Kubo           �V�K�쐬
 *  2015-01-27    1.1   A.Uchida         �V�X�e���e�X�g��Q�Ή�
 *                                       �E�U�֏o�ׂŁA�قȂ�i�ڋ敪�̕i�ڂ֐U�ւ��s���Ă���ꍇ�A
 *                                         �˗��i�ڂ̋敪���Q�Ƃ���B
 *                                       �E�d��OIF�́u�d�󖾍דE�v�v�ɐݒ肷��l���C���B
 *  2015-02-10    1.2   Y.Shoji          �V�X�e���e�X�g��Q�Ή�#44�Ή�
 *                                       �E�������P�ʂ̎d����T�C�g�R�[�h���d����R�[�h�ɏC���B
 *  2015-02-25    1.3   Y.Shoji          ����i���[�U�d��m�F�j������Q#22�Ή�
 *                                         �E�d����z���}�C�i�X�̏ꍇ�̏�����ύX�Ή�
 *                                          �i�������̎�ނ��uSTANDARD�v��AP���������쐬���A�J��z���Ȃ��B�j
 *                                         �E�����σf�[�^�폜(A-7)�̏������폜
 *  2015-03-09    1.4   Y.Shoji          E_�{�ғ�_12865 ���ǉ�v�ύX�Ή�
 *                                         �E�d����}�X�^�̎x���������l�����đ��E�d��𔭐�������悤�Ɏd�l�ύX
 *  2019-06-15    1.5   N.Miyamoto       E_�{�ғ�_15601 ���Y_�y���ŗ��Ή�
 *                                         �E�ŗ���i�ڂ��Ƃɏ���ŗ��r���[����擾����悤�d�l�ύX
 *                                         �E�O���J�z�Ώۂ̃��W�b�N�폜
 *  2024-05-27    1.6   R.Oikawa         E_�{�ғ�_19497 ���Y�C���{�C�X�Ή�
 *                                         �E�d����/�ŗ����ƂɐŌv�Z���s�����אϏグ�ƍ��z������ꍇ�͒����z�������
 *                                           �˗v���ꗂׁ̈A�{�Ԃւ͖������[�X
 *  2024-06-20    1.7   R.Oikawa         E_�{�ғ�_19497 ���Y�C���{�C�X�Ή�
 *                                         �E���z���d����/����/�ŗ��P�ʂŎZ�o
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
  cv_underbar      CONSTANT VARCHAR2(1) := '_';       -- 2015-01-27 Ver1.1 Add
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO022A02C';
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
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
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
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- �g�[�N���FSQL�G���[���b�Z�[�W
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';  -- �d��p�^�[���F�d�����ѕ\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_SHIPMENT';    -- �d��p�^�[���F�o�׎��ѕ\
  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_CO'; -- XXCFO:�d��J�e�S��_�L���J�z
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_INVOICE_SOURCE_MFG'; -- XXCFO:�������\�[�X�i�H��j
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_ITEM';  -- XXCFO:AP-OIF���׃^�C�v_����
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- �g�DID (�c��)
  cv_profile_name_07          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';         -- ���YORG_ID
  cv_profile_name_08          CONSTANT VARCHAR2(50)  := 'XXCMN_MASTER_ORG_ID';       -- �i�ڃ}�X�^�g�DID
-- 2015-03-09 Ver1.4 Add Start
  cv_profile_name_09          CONSTANT VARCHAR2(50)  := 'XXCFO1_TERMS_PAYMENT_99';   -- �x������_�w��l
-- 2015-03-09 Ver1.4 Add End
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
  cv_data_type_2              CONSTANT VARCHAR2(1)   := '2';                         -- �f�[�^�^�C�v�i2:�L���x���J�z�j
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
  cv_mfg                      CONSTANT VARCHAR2(3)   := 'MFG';                       -- MFG
  cv_amount_fix_class         CONSTANT VARCHAR2(1)   := '1';                         -- �m��
  cv_shikyu_class             CONSTANT VARCHAR2(1)   := '2';                         -- �o�׎x���敪 : 2(�x���˗�)
  cv_doc_type_prov            CONSTANT VARCHAR2(2)   := '30';                        -- �x���w��
  cv_rec_type_stck            CONSTANT VARCHAR2(2)   := '20';                        -- �o�Ɏ���
  cn_minus                    CONSTANT NUMBER        := -1;                          -- ���z�Z�o�p
-- 2019/06/15 Ver1.5 Add Start
  cn_plus                     CONSTANT NUMBER        :=  1;                          -- ���z�Z�o�p
-- 2019/06/15 Ver1.5 Add End
--
  -- �g�[�N���l
  cv_msg_out_data_01          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11139';          -- ���E���z���
  cv_msg_out_data_02          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11141';          -- �d����}�X�^�ǂݑւ�View
  cv_msg_out_data_03          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11142';          -- AP������OIF�w�b�_�[
  cv_msg_out_data_04          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11144';          -- AP������OIF����_�{��
  cv_msg_out_data_05          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11149';          -- ���Y����f�[�^
  cv_msg_out_data_06          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11173';          -- �d��OIF
-- 2015-03-09 Ver1.4 Add Start
  cv_msg_out_data_07          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11174';          -- �x������
  cv_msg_out_data_08          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11175';          -- AP�������w�b�_�[OIF�ꎞ�\
  cv_msg_out_data_09          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11176';          -- AP����������OIF�ꎞ�\
-- 2015-03-09 Ver1.4 Add End
  --
  cv_msg_out_item_01          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11150';          -- �d����T�C�gID
  cv_msg_out_item_02          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11151';          -- �{��CCID
  cv_msg_out_item_03          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11152';          -- �i�ڋ敪
  cv_msg_out_item_04          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073';          -- ��v����
--
  -- �d��p�^�[���m�F�p
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
  cv_line_no_05               CONSTANT VARCHAR2(1)   := '5';
  cv_wh_code                  CONSTANT VARCHAR2(3)   := '999';
--
  cv_dt_format                CONSTANT VARCHAR2(30)  := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30)  := 'YYYYMMDD';
  cv_m_format                 CONSTANT VARCHAR2(30)  := 'YYYY-MM';
  cv_e_time                   CONSTANT VARCHAR2(10)  := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02)  := '01';           -- �������t
-- 2015-03-09 Ver1.4 Add Start
  cn_months_2                 CONSTANT NUMBER        := 2;              -- 2������Z�o�p
-- 2015-03-09 Ver1.4 Add End
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
  gn_prof_mst_org_id          NUMBER        DEFAULT NULL;    -- �g�DID (�i�ڃ}�X�^�g�D)
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
  gv_je_ptn_rec_pay           VARCHAR2(100) DEFAULT NULL;    -- �d��p�^�[���F�o�׎��ѕ\
  gv_je_category_mfg_co       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��J�e�S��_�L���J�z
  gv_invoice_source_mfg       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�������\�[�X�i�H��j
  gv_detail_type_item         VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF���׃^�C�v_����
  gv_detail_type_tax          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF���׃^�C�v_�ŋ�
--  2015-03-09 Ver1.4 Add Start
  gv_terms_payment_99         VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�x������_�w��l
--  2015-03-09 Ver1.4 Add End
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
  gd_target_date_last         DATE          DEFAULT NULL;    -- ��v����_�ŏI��
-- 2015-03-09 Ver1.4 Add Start
  gd_target_date_last2        DATE          DEFAULT NULL;    -- 2������̉�v���Ԃ̍ŏI��
  gd_due_date                 DATE          DEFAULT NULL;    -- �x���\���/�v���
-- 2015-03-09 Ver1.4 Add End
--
  gn_payment_amount_all       NUMBER        DEFAULT NULL;    -- �������P�ʁF�x�����z�i�ō��j
  gv_vendor_code_hdr          VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d����R�[�h�i���Y�j
  gv_vendor_site_code_hdr     VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d����T�C�g�R�[�h�i���Y�j
  gn_vendor_site_id_hdr       NUMBER        DEFAULT NULL;    -- �������P�ʁF�d����T�C�gID�i���Y�j
  gv_department_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF����R�[�h
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�i�ڋ敪
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d���於�i���Y�j
  gv_invoice_num_prev         VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�������ԍ�(�O�����E��)
  gv_invoice_num_this         VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�������ԍ�(�������E��)
  gn_prev_month_amount        NUMBER        DEFAULT NULL;    -- �������P�ʁF�O�����E���z
  gn_this_month_amount        NUMBER        DEFAULT NULL;    -- �������P�ʁF�������E���z
  gn_next_month_amount        NUMBER        DEFAULT NULL;    -- �������P�ʁF�����J�z���z
  gn_sales_accts_pay_ccid     NUMBER        DEFAULT NULL;    -- ������CCID�i�c�Ɓj
--
  gn_transfer_cnt             NUMBER;                        -- �J�z��������
-- 2015-03-09 Ver1.4 Add Start
  gn_transfer_in_cnt          NUMBER;                        -- �J�z�f�[�^�捞����
-- 2015-03-09 Ver1.4 Add End
--
  gv_period_name              VARCHAR2(7);                   -- IN�p����v����
  gv_period_name_prev         VARCHAR2(7);                   -- IN�p����v���� -1
  gv_period_name_sl           VARCHAR2(7);                   -- IN�p����v����(YYYY/MM�`��)
--
  gn_invoice_id_01            NUMBER;                        -- invoice_id �ۑ��p
  gn_invoice_id_02            NUMBER;                        -- invoice_id �ۑ��p
--
-- Ver1.6 Add Start
  gn_payment_amount_net       NUMBER        DEFAULT 0;       -- �������P�ʁF�x�����z�i�Ŕ��j
  gn_payment_tax_rate         NUMBER        DEFAULT NULL;    -- �������P�ʁF�ŗ�
  gn_payment_amount_net2      NUMBER        DEFAULT 0;       -- �������P�ʁF�x�����z�i�Ŕ��j2
  gn_payment_tax_rate2        NUMBER        DEFAULT NULL;    -- �������P�ʁF�ŗ�2
  gn_payment_amount_net3      NUMBER        DEFAULT 0;       -- �������P�ʁF�x�����z�i�Ŕ��j3
  gn_payment_tax_rate3        NUMBER        DEFAULT NULL;    -- �������P�ʁF�ŗ�3
  gv_skip_flg                 VARCHAR2(1);                   -- ���z�v�Z�ΏۊO�t���O(Y:�v�Z�ΏۊO N:�v�Z�Ώ�)
-- Ver1.6 Add End
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �d��p�^�[���F�o�׎��ѕ\
    gv_je_ptn_rec_pay     := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_ptn_rec_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:�������\�[�X�i�H��j
    gv_invoice_source_mfg  := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_04
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF���׃^�C�v_����
    gv_detail_type_item  := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF( gv_detail_type_item IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_05
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �g�DID (�c��)
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_06 ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_06
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �i�ڃ}�X�^�g�D�h�c
    gn_prof_mst_org_id := FND_PROFILE.VALUE( cv_profile_name_08 ) ;
    IF ( gn_prof_mst_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_08
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF ;
--
-- 2015-03-09 Ver1.4 Add Start
    -- �x������_�w��l
    gv_terms_payment_99 := FND_PROFILE.VALUE( cv_profile_name_09 ) ;
    IF ( gv_terms_payment_99 IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- �A�v���P�[�V�����Z�k���FXXCMN ����
                    , iv_name           => cv_msg_cmn_10002        -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_profile          -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_09
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF ;
--
-- 2015-03-09 Ver1.4 Add End
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- ���̓p�����[�^�̉�v���Ԃ���A�d��OIF�o�^�p�Ɋi�[
    gd_target_date_last  := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
-- 2015-03-09 Ver1.4 Add Start
    gd_target_date_last2 := LAST_DAY(ADD_MONTHS(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format),cn_months_2));
-- 2015-03-09 Ver1.4 Add End
    --
    gv_period_name       := iv_period_name;
    gv_period_name_prev  := TO_CHAR(ADD_MONTHS(gd_target_date_from,cn_minus) ,cv_m_format);
    gv_period_name_sl    := REPLACE(iv_period_name,'-','/');
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
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_headers
   * Description      : AP�������w�b�_OIF�o�^(A-5)
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
    cv_comment_01               CONSTANT VARCHAR2(100) := '�����F'; -- AP������ �E�v��
-- 2015-03-09 Ver1.4 Add Start
    cv_date_format_mm           CONSTANT VARCHAR2(100) := 'MM';             -- ���t�����FMM
    cv_payment_terms            CONSTANT VARCHAR2(100) := 'PAYMENT TERMS';  -- �J�����_�^�C�v�FPAYMENT_TERMS
    cv_sql_ap                   CONSTANT VARCHAR2(100) := 'SQLAP';          -- �A�v�����́FSQLAP
    cn_sequence_num_1           CONSTANT NUMBER        := 1;                -- �x����������No�F1
-- 2015-03-09 Ver1.4 Add End
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
-- 2015.02.25 Ver1.3 Add Start
    lv_invoice_type             VARCHAR2(20)      DEFAULT NULL;     -- �������^�C�v
-- 2015.02.25 Ver1.3 Add End
-- 2015-03-09 Ver1.4 Add Start
    lv_period_name              VARCHAR2(15)      DEFAULT NULL;     -- ���ʃJ�����_�F�V�X�e����
-- 2015-03-09 Ver1.4 Add End
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
-- 2015-03-09 Ver1.4 Add Start
    lv_invoice_type                 := NULL;
    lv_period_name                  := NULL;
-- 2015-03-09 Ver1.4 Add End
--
    -- ===============================
    -- �d����}�X�^�̏����擾
    -- ===============================
    BEGIN
      SELECT xvmv.sales_vendor_code             -- �d����R�[�h�i�c�Ɓj
            ,xvmv.sales_vendor_site_code        -- �x����T�C�g�R�[�h�i�c�Ɓj
            ,xvmv.mfg_vendor_code               -- �d����R�[�h�i���Y�j
            ,xvmv.mfg_vendor_name               -- �d���於�i���Y�j
            ,xvmv.sales_accts_pay_ccid          -- ������CCID�i�c�Ɓj
      INTO   lv_sales_vendor_code               -- �d����R�[�h�i�c�Ɓj
            ,lv_sales_vendor_site_code          -- �x����T�C�g�R�[�h�i�c�Ɓj
            ,lv_mfg_vendor_code                 -- �d����R�[�h�i���Y�j
            ,gv_mfg_vendor_name                 -- �d���於�i���Y�j
            ,ln_sales_accts_pay_ccid            -- ������CCID�i�c�Ɓj
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
                        , iv_token_value1 => cv_msg_out_data_02            -- �d����}�X�^�ǂݑւ�View
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_01            -- �d����T�C�gID
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gn_vendor_site_id_hdr
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
-- 2015-03-09 Ver1.4 Add Start
    -- ���ʃJ�����_�̃V�X�e�������擾
    lv_period_name := REPLACE(SUBSTR(gv_period_name,3,5),'-') || '-' || SUBSTR(gv_period_name,3,2);
--
    -- ===============================
    -- �d����̎x���\���/�v������擾
    -- ===============================
    BEGIN
      SELECT /*+ INDEX(AP_OTHER_PERIODS_U1) */
             aop.due_date          dd     -- �x���\���/�v���
      INTO   gd_due_date
      FROM   po_vendor_sites_all   pvsa   -- �x����T�C�g
            ,apps.ap_terms_lines   atl    -- �x����������
            ,apps.ap_other_periods aop    -- ���ʃJ�����_
            ,fnd_application       fa     -- �A�v���P�[�V����
      WHERE pvsa.terms_id              = atl.term_id
      AND   atl.calendar               = aop.period_type
      AND   aop.application_id         = fa.application_id
      AND   pvsa.vendor_site_code      = lv_sales_vendor_site_code   -- �x����T�C�g�R�[�h�i�c�Ɓj
      AND   atl.sequence_num           = cn_sequence_num_1           -- ����No�F1
      AND   aop.module                 = cv_payment_terms            -- PAYMENT TERMS
      AND   aop.period_name            = lv_period_name              -- �V�X�e����
      AND   fa.application_short_name  = cv_sql_ap                   -- �A�v������
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_data_07            -- �x������
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_01            -- �d����T�C�gID
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gn_vendor_site_id_hdr
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
-- 2015-03-09 Ver1.4 Add End
    -- ===============================
    -- ���ʊ֐��i����Ȗڐ����@�\�j
    -- ===============================
    -- ���ʊ֐����R�[������
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                        -- (IN)���i�敪
      , iv_reason_code              =>  NULL                        -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_02            -- (IN)�d��p�^�[�� �F2
      , iv_line_no                  =>  cv_line_no_01               -- (IN)�s�ԍ� �F1
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)�ؕ��E�ݕ�
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
    -- ������CCID���擾
    gn_sales_accts_pay_ccid  := xxcok_common_pkg.get_code_combination_id_f(
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
    IF ( gn_sales_accts_pay_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_02            -- �{��CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_03            -- �i�ڋ敪
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�������E���z�v�����݂���ꍇ
-- 2015.02.25 Ver1.3 Mod Start
--    IF (gn_this_month_amount > 0) THEN
    IF (gn_this_month_amount <> 0) THEN
-- 2015.02.25 Ver1.3 Mod End
      -- ===============================
      -- �������ԍ��i�`�[�ԍ��j�擾
      -- ===============================
      -- �������ԍ����̔Ԃ���
      gv_invoice_num_this := cv_mfg || LPAD(xxcfo_invoice_mfg_s1.nextval, 8, 0);
--
-- 2015.02.25 Ver1.3 Add Start
      -- �u�������E���z�v���v���X�̏ꍇ�A�������̎�ނ�'CREDIT'
      IF (gn_this_month_amount > 0) THEN
        lv_invoice_type := cv_type_credit;
      -- �u�������E���z�v���}�C�i�X�̏ꍇ�A�������̎�ނ�'STANDARD'
      ELSIF (gn_this_month_amount < 0) THEN
        lv_invoice_type := cv_type_standard;
      END IF;
--
-- 2015.02.25 Ver1.3 Add End
-- 2015-03-09 Ver1.4 Mod Start
--      -- ===============================
--      -- AP������OIF�o�^
--      -- ===============================
--      BEGIN
--        INSERT INTO ap_invoices_interface (
--          invoice_id                              -- �V�[�P���X
--        , invoice_num                             -- �`�[�ԍ�
--        , invoice_type_lookup_code                -- �������̎��
--        , invoice_date                            -- �������t
--        , vendor_num                              -- �d����R�[�h
--        , vendor_site_code                        -- �d����T�C�g�R�[�h
--        , invoice_amount                          -- �������z
--        , description                             -- �E�v
--        , last_update_date                        -- �ŏI�X�V��
--        , last_updated_by                         -- �ŏI�X�V��
--        , last_update_login                       -- �ŏI���O�C��ID
--        , creation_date                           -- �쐬��
--        , created_by                              -- �쐬��
--        , attribute_category                      -- DFF�R���e�L�X�g
--        , attribute2                              -- �������ԍ�
--        , attribute3                              -- �N�[����
--        , attribute4                              -- �`�[���͎�
--        , source                                  -- �\�[�X
--        , pay_group_lookup_code                   -- �x���O���[�v
--        , gl_date                                 -- �d��v���
--        , accts_pay_code_combination_id           -- ������CCID
--        , org_id                                  -- �g�DID
--        , terms_date                              -- �x���N�Z��
--        )
--        VALUES (
--          ap_invoices_interface_s.NEXTVAL         -- AP������OIF�w�b�_�[�p�V�[�P���X�ԍ�(���)
--        , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
---- 2015.02.25 Ver1.3 Mod Start
----        , cv_type_credit                          -- �������^�C�v
--        , lv_invoice_type                         -- �������^�C�v
---- 2015.02.25 Ver1.3 Mod End
--        , gd_target_date_to                       -- �������t(�Ώی��̌���)
--        , lv_sales_vendor_code                    -- �d����R�[�h
--        , lv_sales_vendor_site_code               -- �d����T�C�g�R�[�h
--        , gn_this_month_amount * cn_minus         -- �������P�ʁF�������E���z
--        -- 2015-01-27 Ver1.1 Mod Start
----        , lv_description || gv_period_name || cv_comment_01
----          || lv_mfg_vendor_code || gv_mfg_vendor_name
--        , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_period_name 
--          || cv_comment_01|| gv_mfg_vendor_name
--        -- 2015-01-27 Ver1.1 Mod End
--                                                  -- �u�d����R�[�h�i���Y�j�v�{�E�v�F�u�E�v�v�{
--                                                  -- �u���̓p�����[�^�̉�v�N���v�{�u�d���於�i���Y�j�v
--        , cd_last_update_date                     -- �ŏI�X�V��
--        , cn_last_updated_by                      -- �ŏI�X�V��
--        , cn_last_update_login                    -- �ŏI���O�C��ID
--        , cd_creation_date                        -- �쐬��
--        , cn_created_by                           -- �쐬��
--        , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
--        , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
--        , gv_department_code_hdr                  -- ���_�R�[�h
--        , NULL                                    -- �`�[���͎�(�]�ƈ�No)
--        , gv_invoice_source_mfg                   -- �������\�[�X(init�Ŏ擾)
--        , NULL                                    -- �x���O���[�v
--        , gd_target_date_to                       -- �d��v���(�Ώی��̌���)
--        , gn_sales_accts_pay_ccid                 -- ������Ȗ�CCID
--        , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
--        , gd_target_date_to                       -- �x���N�Z��(�Ώی��̌���)
--        );
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
--                    , iv_name         => cv_msg_cfo_10040
--                    , iv_token_name1  => cv_tkn_data                             -- �f�[�^
--                    , iv_token_value1 => cv_msg_out_data_03                      -- AP������OIF�w�b�_�[
--                    , iv_token_name2  => cv_tkn_vendor_site_code                 -- �d����T�C�g�R�[�h
--                    , iv_token_value2 => gv_vendor_code_hdr
--                    , iv_token_name3  => cv_tkn_department                       -- ����
--                    , iv_token_value3 => gv_department_code_hdr
--                    , iv_token_name4  => cv_tkn_item_kbn                         -- �i�ڋ敪
--                    , iv_token_value4 => gv_item_class_code_hdr
--                    );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--      -- invoice_id��ێ�
--      SELECT ap_invoices_interface_s.CURRVAL
--      INTO   gn_invoice_id_02
--      FROM   DUAL;
--      --
--    END IF;
----
--    -- ���팏���J�E���g
--    gn_normal_cnt := gn_normal_cnt +1;
--
      -- �x���\�����2������̉�v���Ԃ̍ŏI���ȑO�̏ꍇ
      IF (gd_due_date <= gd_target_date_last2) THEN
        -- ===============================
        -- AP������OIF�o�^
        -- ===============================
        BEGIN
          INSERT INTO ap_invoices_interface (
            invoice_id                              -- ������ID
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
          , terms_name                              -- �x������
          , gl_date                                 -- �d��v���
          , accts_pay_code_combination_id           -- ������CCID
          , org_id                                  -- �g�DID
          , terms_date                              -- �x���N�Z��
-- Ver1.6 Add Start
          , request_id                              -- �v��ID
          , attribute5                              -- �������z(�Ŕ�)
          , attribute6                              -- �ŗ�
          , attribute7                              -- �������z(�Ŕ�)2
          , attribute8                              -- �ŗ�2
          , attribute9                              -- �������z(�Ŕ�)3
          , attribute10                             -- �ŗ�3
          , attribute11                             -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
          )
          VALUES (
            ap_invoices_interface_s.NEXTVAL         -- AP������OIF�w�b�_�[�p�V�[�P���X�ԍ�(���)
          , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
          , lv_invoice_type                         -- �������^�C�v
          , gd_due_date                             -- �������t(�x���\���)
          , lv_sales_vendor_code                    -- �d����R�[�h
          , lv_sales_vendor_site_code               -- �d����T�C�g�R�[�h
          , gn_this_month_amount * cn_minus         -- �������P�ʁF�������E���z
          , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_period_name 
            || cv_comment_01|| gv_mfg_vendor_name
                                                    -- �u�d����R�[�h�i���Y�j�v�{�u_�v�{�u�E�v�v�{�u_�v
                                                    -- �u�����F�v�{�u�d���於�i���Y�j�v
          , cd_last_update_date                     -- �ŏI�X�V��
          , cn_last_updated_by                      -- �ŏI�X�V��
          , cn_last_update_login                    -- �ŏI���O�C��ID
          , cd_creation_date                        -- �쐬��
          , cn_created_by                           -- �쐬��
          , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
          , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
          , gv_department_code_hdr                  -- ���_�R�[�h
          , NULL                                    -- �`�[���͎�(�]�ƈ�No)
          , gv_invoice_source_mfg                   -- �������\�[�X(init�Ŏ擾)
          , NULL                                    -- �x���O���[�v
          , gv_terms_payment_99                     -- �x������
          , gd_due_date                             -- �d��v���(�x���\���)
          , gn_sales_accts_pay_ccid                 -- ������Ȗ�CCID
          , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
          , gd_due_date                             -- �x���N�Z��(�x���\���)
-- Ver1.6 Add Start
          , cn_request_id                           -- �v��ID
          , TO_CHAR(gn_payment_amount_net * cn_minus)  -- �������z(�Ŕ�)
          , TO_CHAR(gn_payment_tax_rate)            -- �ŗ�
          , TO_CHAR(gn_payment_amount_net2 * cn_minus) -- �������z(�Ŕ�)2
          , TO_CHAR(gn_payment_tax_rate2)           -- �ŗ�2
          , TO_CHAR(gn_payment_amount_net3 * cn_minus) -- �������z(�Ŕ�)3
          , TO_CHAR(gn_payment_tax_rate3)           -- �ŗ�3
          , gv_skip_flg                             -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                             -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_03                      -- AP������OIF�w�b�_�[
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
--
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt +1;
--
      -- �x���\�����2������̉�v���Ԃ̍ŏI������̏ꍇ
      ELSE
        -- ===============================
        -- AP�������w�b�_�[OIF�ꎞ�\�o�^
        -- ===============================
        BEGIN
          INSERT INTO xxcfo_ap_inv_int_tmp (
            invoice_id                              -- ������ID
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
          , terms_name                              -- �x������
          , gl_date                                 -- �d��v���
          , accts_pay_code_combination_id           -- ������CCID
          , org_id                                  -- �g�DID
          , terms_date                              -- �x���N�Z��
-- Ver1.6 Add Start
          , request_id                              -- �v��ID
          , attribute5                              -- �������z(�Ŕ�)
          , attribute6                              -- �ŗ�
          , attribute7                              -- �������z(�Ŕ�)2
          , attribute8                              -- �ŗ�2
          , attribute9                              -- �������z(�Ŕ�)3
          , attribute10                             -- �ŗ�3
          , attribute11                             -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
          )
          VALUES (
            ap_invoices_interface_s.NEXTVAL         -- AP������OIF�w�b�_�[�p�V�[�P���X�ԍ�(���)
          , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
          , lv_invoice_type                         -- �������^�C�v
          , gd_due_date                             -- �������t(�x���\���)
          , lv_sales_vendor_code                    -- �d����R�[�h
          , lv_sales_vendor_site_code               -- �d����T�C�g�R�[�h
          , gn_this_month_amount * cn_minus         -- �������P�ʁF�������E���z
          , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_period_name 
            || cv_comment_01|| gv_mfg_vendor_name
                                                    -- �u�d����R�[�h�i���Y�j�v�{�u_�v�{�u�E�v�v�{�u_�v
                                                    -- �u�����F�v�{�u�d���於�i���Y�j�v
          , cd_last_update_date                     -- �ŏI�X�V��
          , cn_last_updated_by                      -- �ŏI�X�V��
          , cn_last_update_login                    -- �ŏI���O�C��ID
          , cd_creation_date                        -- �쐬��
          , cn_created_by                           -- �쐬��
          , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
          , gv_invoice_num_this                     -- �������ԍ�(���O�Ŏ擾)
          , gv_department_code_hdr                  -- ���_�R�[�h
          , NULL                                    -- �`�[���͎�(�]�ƈ�No)
          , gv_invoice_source_mfg                   -- �������\�[�X(init�Ŏ擾)
          , NULL                                    -- �x���O���[�v
          , gv_terms_payment_99                     -- �x������
          , gd_due_date                             -- �d��v���(�x���\���)
          , gn_sales_accts_pay_ccid                 -- ������Ȗ�CCID
          , gn_org_id_sales                         -- �g�DID(init�Ŏ擾)
          , gd_due_date                             -- �x���N�Z��(�x���\���)
-- Ver1.6 Add Start
          , cn_request_id                           -- �v��ID
          , TO_CHAR(gn_payment_amount_net * cn_minus)  -- �������z(�Ŕ�)
          , TO_CHAR(gn_payment_tax_rate)            -- �ŗ�
          , TO_CHAR(gn_payment_amount_net2 * cn_minus) -- �������z(�Ŕ�)2
          , TO_CHAR(gn_payment_tax_rate2)           -- �ŗ�2
          , TO_CHAR(gn_payment_amount_net3 * cn_minus) -- �������z(�Ŕ�)3
          , TO_CHAR(gn_payment_tax_rate3)           -- �ŗ�3
          , gv_skip_flg                             -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                             -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_08                      -- AP�������w�b�_�[OIF�ꎞ�\
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
        -- �J�z���������J�E���g
        gn_transfer_cnt := gn_transfer_cnt +1;
--
      END IF;
--
      -- invoice_id��ێ�
      gn_invoice_id_02 := ap_invoices_interface_s.CURRVAL;
    END IF;
--
-- 2015-03-09 Ver1.4 Mod End
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
   * Description      : AP����������OIF�o�^(A-6)
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
    cn_detail_num                   CONSTANT NUMBER := 1;
    cv_comment_01                   CONSTANT VARCHAR2(100) := '�����F'; -- AP������ �E�v��
    cv_tax_code_0000                CONSTANT VARCHAR2(4)   := '0000';   -- �ŃR�[�h�F0000�i�ΏۊO�j
--
    -- *** ���[�J���ϐ� ***
    lv_company_code                 VARCHAR2(100) DEFAULT NULL;    -- ���
    lv_department_code              VARCHAR2(100) DEFAULT NULL;    -- ����
    lv_account_title                VARCHAR2(100) DEFAULT NULL;    -- ����Ȗ�
    lv_account_subsidiary           VARCHAR2(100) DEFAULT NULL;    -- �⏕�Ȗ�
    lv_description                  VARCHAR2(100) DEFAULT NULL;    -- �E�v
    lv_line_ccid                    NUMBER        DEFAULT NULL;    -- CCID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    lv_company_code                 := NULL;
    lv_department_code              := NULL;
    lv_account_title                := NULL;
    lv_account_subsidiary           := NULL;
    lv_description                  := NULL;
    lv_line_ccid                    := NULL;
    --
--
    -- �{�̃��R�[�h�̉Ȗڏ������ʊ֐��Ŏ擾
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay                -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr           -- (IN)�i�ڋ敪
      , iv_prod_class               =>  NULL                             -- (IN)���i�敪
      , iv_reason_code              =>  NULL                             -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_02                 -- (IN)�d��p�^�[�� �F2
      , iv_line_no                  =>  cv_line_no_02                    -- (IN)�s�ԍ� �F2
      , iv_gloif_dr_cr              =>  cv_gloif_cr                      -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  cv_wh_code                       -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code                  -- (OUT)���
      , ov_department_code          =>  lv_department_code               -- (OUT)����
      , ov_account_title            =>  lv_account_title                 -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary            -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description                   -- (OUT)�E�v
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
    lv_line_ccid     := xxcok_common_pkg.get_code_combination_id_f(
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
    IF ( lv_line_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_02            -- �{��CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_03            -- �i�ڋ敪
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2015.02.25 Ver1.3 Mod Start
--    IF (gn_this_month_amount > 0) THEN
    IF (gn_this_month_amount <> 0) THEN
-- 2015.02.25 Ver1.3 Mod End
-- 2015-03-09 Ver1.4 Mod Start
--      -- �{�̃��R�[�h�̓o�^�i�������E���j
--      BEGIN
--        INSERT INTO ap_invoice_lines_interface (
--          invoice_id                                        -- ������ID
--        , invoice_line_id                                   -- ����������ID
--        , line_number                                       -- ���׍s�ԍ�
--        , line_type_lookup_code                             -- ���׃^�C�v
--        , amount                                            -- ���׋��z
--        , description                                       -- �E�v
--        , tax_code                                          -- �ŃR�[�h
--        , dist_code_combination_id                          -- CCID
--        , last_updated_by                                   -- �ŏI�X�V��
--        , last_update_date                                  -- �ŏI�X�V��
--        , last_update_login                                 -- �ŏI���O�C��ID
--        , created_by                                        -- �쐬��
--        , creation_date                                     -- �쐬��
--        , attribute_category                                -- DFF�R���e�L�X�g
--        , org_id                                            -- �g�DID
--        )
--        VALUES (
--          gn_invoice_id_02                                  -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
--        , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
--        , cn_detail_num                                     -- �w�b�_�[���ł̘A�� �i1�Œ�j
--        , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
--        , gn_this_month_amount * cn_minus                   -- �O�����E���z
--        -- 2015.01.27 Ver1.1 Mod Start
----        , lv_description || gv_period_name || cv_comment_01
----          || gv_vendor_code_hdr || gv_mfg_vendor_name       
--        , gv_vendor_code_hdr || cv_underbar || lv_description || cv_underbar || gv_period_name
--          || cv_comment_01 || gv_mfg_vendor_name
--        -- 2015.01.27 Ver1.1 Mod End
--                                                            -- �u�d����R�[�h�i���Y�j�v�{�E�v�F�u�E�v�v
--                                                            -- �{�u���̓p�����[�^�̉�v�N���v�{�u�d���於�i���Y�j�v
--        , cv_tax_code_0000                                  -- �������ŃR�[�h
--        , lv_line_ccid                                      -- CCID
--        , cn_last_updated_by                                -- �ŏI�X�V��
--        , cd_last_update_date                               -- �ŏI�X�V��
--        , cn_last_update_login                              -- �ŏI���O�C��ID
--        , cn_created_by                                     -- �쐬��
--        , cd_creation_date                                  -- �쐬��
--        , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
--        , gn_org_id_sales                                   -- �g�DID
--        );
--      EXCEPTION
--        WHEN OTHERS THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
--                    , iv_name         => cv_msg_cfo_10040
--                    , iv_token_name1  => cv_tkn_data                         -- �f�[�^
--                    , iv_token_value1 => cv_msg_out_data_04                  -- AP������OIF����_�{��
--                    , iv_token_name2  => cv_tkn_vendor_site_code             -- �d����T�C�g�R�[�h
--                    , iv_token_value2 => gv_vendor_code_hdr
--                    , iv_token_name3  => cv_tkn_department                   -- ����
--                    , iv_token_value3 => gv_department_code_hdr
--                    , iv_token_name4  => cv_tkn_item_kbn                     -- �i�ڋ敪
--                    , iv_token_value4 => gv_item_class_code_hdr
--                    );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--      END;
--    END iF;
      -- �x���\�����2������̉�v���Ԃ̍ŏI���ȑO�̏ꍇ
      IF (gd_due_date <= gd_target_date_last2) THEN
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
            gn_invoice_id_02                                  -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , cn_detail_num                                     -- �w�b�_�[���ł̘A�� �i1�Œ�j
          , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
          , gn_this_month_amount * cn_minus                   -- �O�����E���z   
          , gv_vendor_code_hdr || cv_underbar || lv_description || cv_underbar || gv_period_name
            || cv_comment_01 || gv_mfg_vendor_name
                                                              -- �u�d����R�[�h�i���Y�j�v�{�E�v�F�u�E�v�v
                                                              -- �{�u���̓p�����[�^�̉�v�N���v�{�u�d���於�i���Y�j�v
          , cv_tax_code_0000                                  -- �������ŃR�[�h
          , lv_line_ccid                                      -- CCID
          , cn_last_updated_by                                -- �ŏI�X�V��
          , cd_last_update_date                               -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , cd_creation_date                                  -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_04                  -- AP������OIF����_�{��
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
--
      -- �x���\�����2������̉�v���Ԃ̍ŏI������̏ꍇ
      ELSE
        -- AP����������OIF�ꎞ�\�ɖ{�̃��R�[�h��o�^
        BEGIN
          INSERT INTO xxcfo_ap_inv_line_int_tmp (
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
            gn_invoice_id_02                                  -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP������OIF���ׂ̈��ID
          , cn_detail_num                                     -- �w�b�_�[���ł̘A�� �i1�Œ�j
          , gv_detail_type_item                               -- ���׃^�C�v�F����(ITEM)
          , gn_this_month_amount * cn_minus                   -- �O�����E���z   
          , gv_vendor_code_hdr || cv_underbar || lv_description || cv_underbar || gv_period_name
            || cv_comment_01 || gv_mfg_vendor_name
                                                              -- �u�d����R�[�h�i���Y�j�v�{�E�v�F�u�E�v�v
                                                              -- �{�u���̓p�����[�^�̉�v�N���v�{�u�d���於�i���Y�j�v
          , cv_tax_code_0000                                  -- �������ŃR�[�h
          , lv_line_ccid                                      -- CCID
          , cn_last_updated_by                                -- �ŏI�X�V��
          , cd_last_update_date                               -- �ŏI�X�V��
          , cn_last_update_login                              -- �ŏI���O�C��ID
          , cn_created_by                                     -- �쐬��
          , cd_creation_date                                  -- �쐬��
          , gn_org_id_sales                                   -- DFF�R���e�L�X�g�F�g�DID
          , gn_org_id_sales                                   -- �g�DID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                      , iv_token_value1 => cv_msg_out_data_09                  -- AP����������OIF�ꎞ�\
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
      END IF;
    END IF;
-- 2015-03-09 Ver1.4 Mod End
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
   * Procedure Name   : get_fee_payment_data
   * Description      : �L���x���f�[�^���o(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_fee_payment_data(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fee_payment_data'; -- �v���O������
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
    cv_proc_type_1           CONSTANT VARCHAR2(1)   := '1';              -- ���������敪�i1:�J�z�����j
    cv_proc_type_2           CONSTANT VARCHAR2(1)   := '2';              -- ���������敪�i2:�o�^�����j
    cv_cat_cd_order          CONSTANT VARCHAR2(6)   := 'ORDER';
    cv_cat_cd_return         CONSTANT VARCHAR2(6)   := 'RETURN';
    cv_cat_set_item_class    CONSTANT VARCHAR2(10)  := '�i�ڋ敪';
--
    -- *** ���[�J���ϐ� ***
-- 2019/06/15 Ver1.5 Del Start
--    ln_transfer_amount       NUMBER       DEFAULT 0;                     -- �O���J�z�����E���z
-- 2019/06/15 Ver1.5 Del End
    ln_rcv_result_amount     NUMBER       DEFAULT 0;                     -- �d������_�x�����z�i�ō��j
    --
    lv_proc_type             VARCHAR2(1)  DEFAULT NULL;                  -- �������������p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\���iSELECT���@�A��UNION ALL�j
    CURSOR get_fee_payment_cur
    IS
      SELECT  trn.vendor_code                                 AS vendor_code              -- �d����R�[�h
             ,trn.vendor_site_code                            AS vendor_site_code         -- �d����T�C�g�R�[�h
             ,trn.vendor_site_id                              AS vendor_site_id           -- �d����T�C�gID
             ,trn.department_code                             AS department_code          -- ����R�[�h
             ,trn.item_class_code                             AS item_class_code          -- �i�ڋ敪
-- 2019/06/15 Ver1.5 Mod Start
--             ,trn.target_period                               AS target_period            -- �Ώ۔N��
--             ,trn.net_amount                                  AS net_amount               -- ���z�i�Ŕ��j
--             ,trn.tax_rate                                    AS tax_rate                 -- ����ŗ�
--             ,trn.tax_amount                                  AS tax_amount               -- �x������Ŋz
--             ,NVL(trn.net_amount,0) + NVL(trn.tax_amount,0)   AS amount                   -- ���z�i�ō��j
--             ,trn.transfer_flag                               AS transfer_flag            -- �O���J�z�Ώۃt���O
             ,SUM(ROUND(actual_quantity * sign * unit_price)) + 
              SUM(ROUND(actual_quantity * sign * unit_price * tax_rate / 100)) 
                                                              AS amount                   -- ���z�i�ō��j
-- 2019/06/15 Ver1.5 Mod End
-- Ver1.6 Add Start
             ,SUM(ROUND(trn.actual_quantity * trn.sign * trn.unit_price))
                                                              AS amount_net               -- ���z�i�Ŕ��j
             ,trn.tax_rate                                    AS tax_rate                 -- �ŗ�
-- Ver1.6 Add End
      FROM(-- ���o�@�i�L���x���j
           SELECT
-- 2019/06/15 Ver1.5 Add Start
                  /*+ PUSH_PRED(xitrv) */
-- 2019/06/15 Ver1.5 Add End
                  pv.segment1                                 AS vendor_code          -- �d����R�[�h
                 ,pvsa.vendor_site_code                       AS vendor_site_code     -- �d����T�C�g�R�[�h
                 ,pvsa.vendor_site_id                         AS vendor_site_id       -- �d����T�C�gID
                 ,xoha.performance_management_dept            AS department_code      -- ����R�[�h
                 ,mcb.segment1                                AS item_class_code      -- �i�ڋ敪
-- 2019/06/15 Ver1.5 Mod Start
--                 ,TO_CHAR(xoha.arrival_date , 'YYYY/MM' )     AS target_period        -- �Ώ۔N��
--                 ,SUM(ROUND(CASE
--                   WHEN ( otta.order_category_code = cv_cat_cd_order  ) THEN xmld.actual_quantity
--                   WHEN ( otta.order_category_code = cv_cat_cd_return ) THEN xmld.actual_quantity * cn_minus
--                  END * xola.unit_price))                     AS net_amount           -- ���z�i�Ŕ��j
--                 ,TO_NUMBER(xlv2v.lookup_code)                AS tax_rate             -- ����ŗ�
--                 ,SUM(ROUND(CASE
--                   WHEN ( otta.order_category_code = cv_cat_cd_order  ) THEN xmld.actual_quantity
--                   WHEN ( otta.order_category_code = cv_cat_cd_return ) THEN xmld.actual_quantity * cn_minus
--                  END * xola.unit_price * TO_NUMBER( xlv2v.lookup_code ) / 100)) 
--                                                              AS tax_amount           -- ����Ŋz
--                 ,cv_flag_n                                   AS transfer_flag        -- �O���J�z�Ώۃt���O'N'
                 ,NVL(xmld.actual_quantity, 0)                AS actual_quantity      -- ����
                 ,NVL(xola.unit_price, 0)                     AS unit_price           -- �P��
                 ,TO_NUMBER(xitrv.tax)                        AS tax_rate             -- �ŗ� 
                 ,CASE
                    WHEN ( order_category_code = cv_cat_cd_order  ) THEN cn_plus      --�ԕi�ȊO�͐��l
                    WHEN ( order_category_code = cv_cat_cd_return ) THEN cn_minus     --�ԕi�͕��l
                  END                                         AS sign                 --����
-- 2019/06/15 Ver1.5 Mod End
           FROM   xxwsh_order_headers_all      xoha              -- �󒍃w�b�_�A�h�I��
                 ,xxwsh_order_lines_all        xola              -- �󒍖��׃A�h�I��
                 ,oe_transaction_types_all     otta              -- �󒍃^�C�v
                 ,xxinv_mov_lot_details        xmld              -- �ړ����b�g�ڍ׃A�h�I��
                 ,po_vendors                   pv                -- �d����
                 ,xxcmn_vendors                xv                -- �d����A�h�I��
                 ,po_vendor_sites_all          pvsa              -- �d����T�C�g
                 ,xxcmn_vendor_sites_all       xvsa              -- �d����T�C�g�A�h�I��
                 ,mtl_system_items_b           msib              -- INV�i�ڃ}�X�^
                 ,ic_item_mst_b                iimb              -- OPM�i�ڃ}�X�^
                 ,xxcmn_item_mst_b             ximb              -- �i�ڃA�h�I��
                 ,gmi_item_categories          gic               -- �i�ڃJ�e�S������
                 ,mtl_categories_b             mcb               -- �i�ڃJ�e�S��
                 ,mtl_category_sets_b          mcsb              -- �i�ڃJ�e�S���Z�b�g
                 ,mtl_category_sets_tl         mcst              -- �i�ڃJ�e�S���Z�b�g�i���{��j
-- 2019/06/15 Ver1.5 Mod Start
--                 ,xxcmn_lookup_values2_v       xlv2v             -- ����ŗ����VIEW
                 ,xxcmm_item_tax_rate_v        xitrv             -- ����ŗ����VIEW
-- 2019/06/15 Ver1.5 Mod End
           WHERE  xoha.order_header_id              = xola.order_header_id
           AND    xola.order_line_id                = xmld.mov_line_id
           AND    xoha.latest_external_flag         = cv_flag_y
           AND    NVL(xola.delete_flag,cv_flag_n)   = cv_flag_n
           AND    xoha.order_type_id                = otta.transaction_type_id
           AND    otta.org_id                       = gn_org_id_mfg
           AND    otta.attribute1                   = cv_shikyu_class        -- �o�׎x���敪 = 2(�x���˗�)
           AND    xola.order_line_id                = xmld.mov_line_id
           -- 2015-01-27 Ver1.1 Mod Start
--           AND    xola.shipping_inventory_item_id   = msib.inventory_item_id
           AND    xola.request_item_id              = msib.inventory_item_id
           -- 2015-01-27 Ver1.1 Mod End
           AND    msib.segment1                     = iimb.item_no
           AND    msib.organization_id              = gn_prof_mst_org_id  -- �i�ڃ}�X�^�g�D
           AND    iimb.item_id                      = ximb.item_id
           AND    mcsb.structure_id                 = mcb.structure_id
           AND    gic.category_id                   = mcb.category_id
           AND    mcst.category_set_name            = cv_cat_set_item_class -- �i�ڋ敪
           AND    mcst.source_lang                  = cv_lang
           AND    mcst.language                     = cv_lang
           AND    mcsb.category_set_id              = mcst.category_set_id
           AND    gic.category_set_id               = mcsb.category_set_id
           AND    ximb.item_id                      = gic.item_id
           AND    xoha.arrival_date                 BETWEEN ximb.start_date_active  -- ���ד��ŗL���ȃf�[�^
                                                    AND     ximb.end_date_active    -- 
           AND    xmld.document_type_code           = cv_doc_type_prov       -- 30(�x���w��)
           AND    xmld.record_type_code             = cv_rec_type_stck       -- 20(�o�Ɏ���)
           --
           AND    xoha.vendor_id                    = xv.vendor_id(+)
           AND    pv.vendor_id                      = xv.vendor_id
           AND    xoha.arrival_date                 BETWEEN xv.start_date_active(+)   -- ���ד��ŗL���ȃf�[�^
                                                    AND     xv.end_date_active(+)
           AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
           AND    pvsa.vendor_site_id               = xvsa.vendor_site_id
           AND    xoha.arrival_date                 BETWEEN xvsa.start_date_active(+) -- ���ד��ŗL���ȃf�[�^
                                                    AND     xvsa.end_date_active(+)
           --
-- 2019/06/15 Ver1.5 Mod Start
--           AND    xlv2v.lookup_type                 = cv_lookup_type_01               -- �Q�ƃ^�C�v�F����ŗ��}�X�^
--           AND    xoha.arrival_date                 BETWEEN NVL( xlv2v.start_date_active, xoha.arrival_date )
--                                                    AND     NVL( xlv2v.end_date_active  , xoha.arrival_date )
--
           AND    xitrv.item_no                     = xola.shipping_item_code
           AND    NVL(xoha.sikyu_return_date, xoha.arrival_date ) 
                                                    BETWEEN NVL(xitrv.start_date_active, NVL(xoha.sikyu_return_date, xoha.arrival_date ))
                                                    AND     NVL(xitrv.end_date_active,   NVL(xoha.sikyu_return_date, xoha.arrival_date ))
-- 2019/06/15 Ver1.5 Mod End
           AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                    AND     gd_target_date_to
-- 2019/06/15 Ver1.5 Del Start
--           GROUP BY
--                  pv.segment1
--                 ,pvsa.vendor_site_code
--                 ,pvsa.vendor_site_id
--                 ,xoha.performance_management_dept
--                 ,mcb.segment1
--                 ,TO_CHAR(xoha.arrival_date , 'YYYY/MM' )
--                 ,xlv2v.lookup_code
-- 2019/06/15 Ver1.5 Del End
          ) trn
-- 2019/06/15 Ver1.5 Add Start
      GROUP BY
             vendor_code
            ,vendor_site_code
            ,vendor_site_id
            ,department_code
            ,item_class_code
-- 2019/06/15 Ver1.5 Add End
-- Ver1.6 Add Start
            ,trn.tax_rate
-- Ver1.6 Add End
      ORDER BY
              vendor_code                      -- �d����R�[�h
             -- 2015-02-10 Ver1.2 Del Start
--             ,vendor_site_code                 -- �d����T�C�g�R�[�h
             -- 2015-02-10 Ver1.2 Del End
             ,department_code                  -- ����R�[�h
             ,item_class_code                  -- �i�ڋ敪
-- Ver1.6 Add Start
             ,tax_rate                         -- �ŗ�
-- Ver1.6 Add End
    ;
    -- ���R�[�h�^
    ap_fee_payment_rec get_fee_payment_cur%ROWTYPE;
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
-- Ver1.6 Add Start
    -- �t���O�̏�����
    gv_skip_flg               := cv_flag_n;           -- ���z�v�Z�̑ΏۊO
-- Ver1.6 Add End
    <<main_loop>>
    OPEN get_fee_payment_cur;
    LOOP 
      FETCH get_fee_payment_cur INTO ap_fee_payment_rec;
--
      -- �u���C�N�L�[�i�d����R�[�h�^����R�[�h�^�i�ڋ敪�j���O���R�[�h�ƈقȂ�ꍇ(1���R�[�h�ڂ͏���)
      -- �܂��A�ŏI���R�[�h�̏ꍇ�A�������P�ʂł̋��z�`�F�b�N���s���B
      -- 2015-02-10 Ver1.2 Mod Start
      --IF (((NVL(gv_vendor_site_code_hdr,ap_fee_payment_rec.vendor_site_code) <> ap_fee_payment_rec.vendor_site_code)
      IF (((NVL(gv_vendor_code_hdr,ap_fee_payment_rec.vendor_code) <> ap_fee_payment_rec.vendor_code)
      -- 2015-02-10 Ver1.2 Mod End
          OR (NVL(gv_department_code_hdr,ap_fee_payment_rec.department_code) <> ap_fee_payment_rec.department_code)
          OR (NVL(gv_item_class_code_hdr,ap_fee_payment_rec.item_class_code) <> ap_fee_payment_rec.item_class_code))
          AND NVL(gn_payment_amount_all,0) <> 0 )
         OR (get_fee_payment_cur%NOTFOUND)
      THEN
        -- 2015-02-10 Ver1.2 Del Start
--        -- �d�����уA�h�I������A�L���x�����E�̑ΏۂƂȂ�d�����z���擾
--        BEGIN
--          SELECT xrr.invoice_amount
--          INTO   ln_rcv_result_amount          -- �d������_�x�����z�i�ō��j
--          FROM   xxcfo_rcv_result xrr          -- �d�����уA�h�I��
--          WHERE  xrr.vendor_site_code = gv_vendor_site_code_hdr
--          AND    xrr.bumon_code       = gv_department_code_hdr
--          AND    xrr.item_kbn         = gv_item_class_code_hdr
--          AND    xrr.rcv_month        = REPLACE(iv_period_name,'-')
--          ;
--        --
--        EXCEPTION
--          -- �f�[�^�����݂��Ȃ��ꍇ��0�~��ݒ�
--          WHEN NO_DATA_FOUND THEN
--            ln_rcv_result_amount      := 0;
--        END;
--        --
--        -- �������P�ʂŁu�d������_�x�����z�i�ō��j�v-�u���E���z�i�ō��j�v���}�C�i�X�̏ꍇ�A
--        -- �J�z���������{����
--        IF (ln_rcv_result_amount - gn_payment_amount_all < 0 ) THEN 
--          lv_proc_type := cv_proc_type_1;
--        ELSIF (ln_rcv_result_amount - gn_payment_amount_all >= 0) THEN
--          lv_proc_type := cv_proc_type_2;
--        ELSE
--          -- �Ώۃf�[�^���擾�ł��Ȃ��ꍇ�A���[�v�𔲂���
--          lv_errmsg    := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_appl_short_name_cfo
--                          , iv_name         => cv_msg_cfo_10035              -- �f�[�^�擾�G���[
--                          , iv_token_name1  => cv_tkn_data
--                          , iv_token_value1 => cv_msg_out_data_05            -- ���Y����f�[�^
--                          , iv_token_name2  => cv_tkn_item
--                          , iv_token_value2 => cv_msg_out_item_04            -- ��v����
--                          , iv_token_name3  => cv_tkn_key
--                          , iv_token_value3 => iv_period_name
--                          );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
        -- 2015-02-10 Ver1.2 Del Start
--
        gn_prev_month_amount         := 0;                                   -- �O�����E���z
        gn_this_month_amount         := gn_payment_amount_all;               -- �������E���z
        gn_next_month_amount         := 0;                                   -- �����J�z���z
--
        -- ===============================
        -- AP�������w�b�_OIF�o�^(A-5)
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
        -- AP����������OIF�o�^(A-6)
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
        -- �����Ώی����J�E���g
        gn_target_cnt := gn_target_cnt +1;
--
        -- �ŏI���R�[�h�̏ꍇ�A���[�v�𔲂���
        IF (get_fee_payment_cur%NOTFOUND) THEN
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
        gn_payment_amount_all     := 0;                   -- �������P�ʁF���E���z�i�ō��j
        gn_prev_month_amount      := 0;                   -- �������P�ʁF�O�����E���z
        gn_this_month_amount      := 0;                   -- �������P�ʁF�������E���z
        gn_next_month_amount      := 0;                   -- �������P�ʁF�����J�z���z
-- Ver1.6 Add Start
        gn_payment_amount_net     := 0;                   -- �������P�ʁF���E���z�i�Ŕ��j
        gn_payment_tax_rate       := NULL;                -- �������P�ʁF�ŗ�
        gn_payment_amount_net2    := 0;                   -- �������P�ʁF���E���z�i�Ŕ��j2
        gn_payment_tax_rate2      := NULL;                -- �������P�ʁF�ŗ�2
        gn_payment_amount_net3    := 0;                   -- �������P�ʁF���E���z�i�Ŕ��j3
        gn_payment_tax_rate3      := NULL;                -- �������P�ʁF�ŗ�3
        gv_skip_flg               := cv_flag_n;           -- ���z�v�Z�̑ΏۊO
-- Ver1.6 Add End
        --
-- 2019/06/15 Ver1.5 Del Start
--        ln_transfer_amount        := 0;                   -- �O���J�z�����E���z
-- 2019/06/15 Ver1.5 Del End
        ln_rcv_result_amount      := 0;                   -- �d������_�x�����z�i�ō��j
        --
      END IF;
--
      -- �������P�ʂ̏���ێ�
      gv_vendor_code_hdr        := ap_fee_payment_rec.vendor_code;             -- �������P�ʁF�d����R�[�h�i���Y�j
      gv_vendor_site_code_hdr   := ap_fee_payment_rec.vendor_site_code;        -- �������P�ʁF�d����T�C�g�R�[�h�i���Y�j
      gn_vendor_site_id_hdr     := ap_fee_payment_rec.vendor_site_id;          -- �������P�ʁF�d����T�C�gID�i���Y�j
      gv_department_code_hdr    := ap_fee_payment_rec.department_code;         -- �������P�ʁF����R�[�h
      gv_item_class_code_hdr    := ap_fee_payment_rec.item_class_code;         -- �������P�ʁF�i�ڋ敪
--
      -- �l�̐ςݏグ���s���B
      gn_payment_amount_all     := NVL(gn_payment_amount_all,0) 
                                   + ap_fee_payment_rec.amount;                -- �������P�ʁF���E���z�i�ō��j
-- Ver1.6 Add Start
      IF ( gn_payment_tax_rate IS NULL
       OR  gn_payment_tax_rate = ap_fee_payment_rec.tax_rate ) THEN
        gn_payment_amount_net     := NVL(gn_payment_amount_net,0) 
                                     + ap_fee_payment_rec.amount_net;            -- �������P�ʁF���E���z�i�Ŕ��j
        gn_payment_tax_rate       := ap_fee_payment_rec.tax_rate;                -- �������P�ʁF�ŗ�
      ELSIF ( gn_payment_tax_rate2 IS NULL
             AND gn_payment_tax_rate <> ap_fee_payment_rec.tax_rate
            )
            OR
            ( gn_payment_tax_rate2 = ap_fee_payment_rec.tax_rate ) THEN
        gn_payment_amount_net2     := NVL(gn_payment_amount_net2,0) 
                                     + ap_fee_payment_rec.amount_net;            -- �������P�ʁF���E���z�i�Ŕ��j2
        gn_payment_tax_rate2       := ap_fee_payment_rec.tax_rate;               -- �������P�ʁF�ŗ�2
      ELSIF ( gn_payment_tax_rate3 IS NULL
             AND gn_payment_tax_rate2 <> ap_fee_payment_rec.tax_rate
            )
            OR
            ( gn_payment_tax_rate3 = ap_fee_payment_rec.tax_rate ) THEN
        gn_payment_amount_net3     := NVL(gn_payment_amount_net3,0) 
                                     + ap_fee_payment_rec.amount_net;            -- �������P�ʁF���E���z�i�Ŕ��j3
        gn_payment_tax_rate3       := ap_fee_payment_rec.tax_rate;               -- �������P�ʁF�ŗ�3
      ELSE
        gv_skip_flg := cv_flag_y;   -- ���z�v�Z�̑ΏۊO
      END IF;
-- Ver1.6 Add End
--
-- 2019/06/15 Ver1.5 Del Start
--      -- �O���J�z�Ώۃt���O�������Ă���ꍇ
--      IF (ap_fee_payment_rec.transfer_flag = cv_flag_y) THEN
--        ln_transfer_amount      := NVL(ln_transfer_amount,0)
--                                   + ap_fee_payment_rec.amount;                -- �������P�ʁF�O���J�z�����E���z
--      END IF;
-- 2019/06/15 Ver1.5 Del End
--
    END LOOP main_loop;
--
    CLOSE get_fee_payment_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_fee_payment_cur%ISOPEN ) THEN
        CLOSE get_fee_payment_cur;
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
      IF ( get_fee_payment_cur%ISOPEN ) THEN
        CLOSE get_fee_payment_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_fee_payment_data;
--
-- 2015.02.25 Ver1.3 Del Start
--  /**********************************************************************************
--   * Procedure Name   : del_offset_data
--   * Description      : �����σf�[�^�폜(A-7)
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
--  cv_yyyymm_format              CONSTANT VARCHAR2(30) := 'YYYYMM';
----
--    -- *** ���[�J���ϐ� ***
--  ln_check_month                NUMBER DEFAULT 0;
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
--    -- �폜�����Ɏg�p���鐔�l���Z�o
--    ln_check_month := TO_NUMBER( TO_CHAR( ADD_MONTHS(gd_target_date_from,cn_minus) ,cv_yyyymm_format) );
--    -- ======================================
--    -- �d�����уA�h�I���̏����σf�[�^���폜
--    -- ======================================
--    BEGIN
--      DELETE FROM xxcfo_rcv_result xrr                     -- �d�����уA�h�I��
--      WHERE  TO_NUMBER(xrr.rcv_month) < ln_check_month
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
-- 2015.02.25 Ver1.3 Del End
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : �A�g�Ǘ��e�[�u���o�^(A-8)
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
       cv_pkg_name                         -- �@�\�� 'XXCFO022A02C'
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
-- 2015-03-09 Ver1.4 Add Start
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_tmp
   * Description      : OIF�ꎞ�\�f�[�^�o�^(A-10)
   ***********************************************************************************/
  PROCEDURE ins_ap_invoice_tmp(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_invoice_tmp'; -- �v���O������
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
    CURSOR get_invoice_id_cur
    IS
      SELECT xaiit.invoice_id       AS invoice_id            -- ������ID
      FROM   xxcfo_ap_inv_int_tmp   xaiit                    -- AP�������w�b�_�[OIF�ꎞ�\
      WHERE  xaiit.terms_date <= gd_target_date_last2
    ;
--
    -- *** ���[�J���E���R�[�h ***
    get_invoice_id_rec get_invoice_id_cur%ROWTYPE;
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
    -- �o�^�Ώۂ̃f�[�^�𒊏o
    -- =====================================
    <<tmp_loop>>
    OPEN get_invoice_id_cur;
    LOOP
      FETCH get_invoice_id_cur INTO get_invoice_id_rec;
--
      -- �o�^�Ώۂ��Ȃ��Ȃ����ꍇ�A�����I��
      EXIT WHEN get_invoice_id_cur%NOTFOUND;
--
      -- =====================================
      -- �o�^�Ώۂ̃f�[�^��o�^
      -- =====================================
      -- �w�b�_�[�f�[�^�o�^
      INSERT INTO ap_invoices_interface(
        invoice_id                                    -- ������ID
       ,invoice_num                                   -- �`�[�ԍ�
       ,invoice_type_lookup_code                      -- �������̎��
       ,invoice_date                                  -- �������t
       ,vendor_num                                    -- �d����R�[�h
       ,vendor_site_code                              -- �d����T�C�g�R�[�h
       ,invoice_amount                                -- �������z
       ,description                                   -- �E�v
       ,last_update_date                              -- �ŏI�X�V��
       ,last_updated_by                               -- �ŏI�X�V��
       ,last_update_login                             -- �ŏI���O�C��ID
       ,creation_date                                 -- �쐬��
       ,created_by                                    -- �쐬��
       ,attribute_category                            -- DFF�R���e�L�X�g
       ,attribute2                                    -- �������ԍ�
       ,attribute3                                    -- �N�[����
       ,attribute4                                    -- �`�[���͎�
       ,source                                        -- �\�[�X
       ,pay_group_lookup_code                         -- �x���O���[�v
       ,terms_name                                    -- �x������
       ,gl_date                                       -- �d��v���
       ,accts_pay_code_combination_id                 -- ������CCID
       ,org_id                                        -- �g�DID
       ,terms_date                                    -- �x���N�Z��
-- Ver1.6 Add Start
       ,request_id                                    -- �v��ID
       ,attribute5                                    -- �������z(�Ŕ�)
       ,attribute6                                    -- �ŗ�
       ,attribute7                                    -- �������z(�Ŕ�)2
       ,attribute8                                    -- �ŗ�2
       ,attribute9                                    -- �������z(�Ŕ�)3
       ,attribute10                                   -- �ŗ�3
       ,attribute11                                   -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
      )
      SELECT
        xaiit.invoice_id                              -- ������ID
       ,xaiit.invoice_num                             -- �`�[�ԍ�
       ,xaiit.invoice_type_lookup_code                -- �������̎��
       ,xaiit.invoice_date                            -- �������t
       ,xaiit.vendor_num                              -- �d����R�[�h
       ,xaiit.vendor_site_code                        -- �d����T�C�g�R�[�h
       ,xaiit.invoice_amount                          -- �������z
       ,xaiit.description                             -- �E�v
       ,xaiit.last_update_date                        -- �ŏI�X�V��
       ,xaiit.last_updated_by                         -- �ŏI�X�V��
       ,xaiit.last_update_login                       -- �ŏI���O�C��I
       ,xaiit.creation_date                           -- �쐬��
       ,xaiit.created_by                              -- �쐬��
       ,xaiit.attribute_category                      -- DFF�R���e�L�X
       ,xaiit.attribute2                              -- �������ԍ�
       ,xaiit.attribute3                              -- �N�[����
       ,xaiit.attribute4                              -- �`�[���͎�
       ,xaiit.source                                  -- �\�[�X
       ,xaiit.pay_group_lookup_code                   -- �x���O���[�v
       ,xaiit.terms_name                              -- �x������
       ,xaiit.gl_date                                 -- �d��v���
       ,xaiit.accts_pay_code_combination_id           -- ������CCID
       ,xaiit.org_id                                  -- �g�DID
       ,xaiit.terms_date                              -- �x���N�Z��
-- Ver1.6 Add Start
       ,cn_request_id                                 -- �v��ID
       ,attribute5                                    -- �������z(�Ŕ�)
       ,attribute6                                    -- �ŗ�
       ,attribute7                                    -- �������z(�Ŕ�)2
       ,attribute8                                    -- �ŗ�2
       ,attribute9                                    -- �������z(�Ŕ�)3
       ,attribute10                                   -- �ŗ�3
       ,attribute11                                   -- ���z�v�Z�ΏۊO�t���O
-- Ver1.6 Add End
      FROM   xxcfo_ap_inv_int_tmp        xaiit        -- AP�������w�b�_�[OIF�ꎞ�\
      WHERE  xaiit.invoice_id = get_invoice_id_rec.invoice_id
      ;
--
      -- ���׃f�[�^�o�^
      INSERT INTO ap_invoice_lines_interface(
        invoice_id                                     -- ������ID
       ,invoice_line_id                                -- ����������ID
       ,line_number                                    -- ���׍s�ԍ�
       ,line_type_lookup_code                          -- ���׃^�C�v
       ,amount                                         -- ���׋��z
       ,description                                    -- �E�v
       ,tax_code                                       -- �ŃR�[�h
       ,dist_code_combination_id                       -- CCID
       ,last_updated_by                                -- �ŏI�X�V��
       ,last_update_date                               -- �ŏI�X�V��
       ,last_update_login                              -- �ŏI���O�C��ID
       ,created_by                                     -- �쐬��
       ,creation_date                                  -- �쐬��
       ,attribute_category                             -- DFF�R���e�L�X�g
       ,org_id                                         -- �g�DID
      )
      SELECT
        xailit.invoice_id                              -- ������ID
       ,xailit.invoice_line_id                         -- ����������ID
       ,xailit.line_number                             -- ���׍s�ԍ�
       ,xailit.line_type_lookup_code                   -- ���׃^�C�v
       ,xailit.amount                                  -- ���׋��z
       ,xailit.description                             -- �E�v
       ,xailit.tax_code                                -- �ŃR�[�h
       ,xailit.dist_code_combination_id                -- CCID
       ,xailit.last_updated_by                         -- �ŏI�X�V��
       ,xailit.last_update_date                        -- �ŏI�X�V��
       ,xailit.last_update_login                       -- �ŏI���O�C��ID
       ,xailit.created_by                              -- �쐬��
       ,xailit.creation_date                           -- �쐬��
       ,xailit.attribute_category                      -- DFF�R���e�L�X�g
       ,xailit.org_id                                  -- �g�DID
      FROM   xxcfo_ap_inv_line_int_tmp   xailit        -- AP����������OIF�ꎞ�\
      WHERE  xailit.invoice_id = get_invoice_id_rec.invoice_id
      ;
--
      -- =====================================
      -- �o�^�ς̃f�[�^���폜
      -- =====================================
      -- �w�b�_�[�f�[�^�폜
      DELETE xxcfo_ap_inv_int_tmp        xaiit
      WHERE  xaiit.invoice_id = get_invoice_id_rec.invoice_id
      ;
--
      -- ���׃f�[�^�폜
      DELETE xxcfo_ap_inv_line_int_tmp   xailit
      WHERE  xailit.invoice_id = get_invoice_id_rec.invoice_id
      ;
--
      -- �J�z�f�[�^�捞�����J�E���g
      gn_transfer_in_cnt := gn_transfer_in_cnt +1;
--
    END LOOP tmp_loop;
--
    CLOSE get_invoice_id_cur;
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
      -- �J�[�\���N���[�Y
      IF ( get_invoice_id_cur%ISOPEN ) THEN
        CLOSE get_invoice_id_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_ap_invoice_tmp;
--
-- 2015-03-09 Ver1.4 Add End
-- Ver1.6 Add Start
  /**********************************************************************************
   * Procedure Name   : upd_invoice_oif
   * Description      : AP������OIF�X�V(A-11)
   ***********************************************************************************/
  PROCEDURE upd_invoice_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'upd_invoice_oif'; -- �v���O������
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
    CURSOR get_ap_invoice_oif_cur
    IS
      SELECT MAX(ai.invoice_id)               AS invoice_id,    -- ������ID
             ai.vendor_num                    AS vendor_num,    -- �d����
-- Ver1.7 Add Start
             ai.attribute3                    AS dept_code,     -- ����
-- Ver1.7 Add End
             SUM(vendor_adjust.adjust_amount) AS adjust_amount  -- ���z
      FROM   ap_invoices_interface ai,
             (
              SELECT  MAX(ai2.invoice_id)               AS invoice_id,
                      ai2.vendor_num                    AS vendor_num,
-- Ver1.7 Add Start
                      ai2.attribute3                    AS dept_code,
-- Ver1.7 Add End
                      TO_NUMBER(NVL(ai2.attribute6,0))  AS tax_rate1,
                      TO_NUMBER(NVL(ai2.attribute8,0))  AS tax_rate2,
                      TO_NUMBER(NVL(ai2.attribute10,0)) AS tax_rate3,
                      (SUM(TO_NUMBER(ai2.attribute5)) + ROUND(SUM(TO_NUMBER(ai2.attribute5)) * TO_NUMBER(NVL(ai2.attribute6,0)) / 100))
                       + (SUM(TO_NUMBER(ai2.attribute7)) + ROUND(SUM(TO_NUMBER(ai2.attribute7)) * TO_NUMBER(NVL(ai2.attribute8,0)) / 100))
                       + (SUM(TO_NUMBER(ai2.attribute9)) + ROUND(SUM(TO_NUMBER(ai2.attribute9)) * TO_NUMBER(NVL(ai2.attribute10,0)) / 100))
                       - SUM(ai2.invoice_amount)       AS adjust_amount
              FROM    ap_invoices_interface ai2
              WHERE   ai2.request_id  = cn_request_id
              AND     ai2.attribute11 = cv_flag_n
              GROUP BY ai2.vendor_num,
-- Ver1.7 Add Start
                       ai2.attribute3,
-- Ver1.7 Add End
                       TO_NUMBER(NVL(ai2.attribute6,0)),
                       TO_NUMBER(NVL(ai2.attribute8,0)),
                       TO_NUMBER(NVL(ai2.attribute10,0))
             ) vendor_adjust
      WHERE  vendor_adjust.adjust_amount <> 0   -- ���z����
      AND    vendor_adjust.invoice_id    =  ai.invoice_id
      AND    vendor_adjust.vendor_num    =  ai.vendor_num
-- Ver1.7 Add Start
      AND    vendor_adjust.dept_code     =  ai.attribute3
-- Ver1.7 Add End
      AND    ai.request_id               =  cn_request_id
      GROUP BY ai.vendor_num
-- Ver1.7 Add Start
              ,ai.attribute3
-- Ver1.7 Add End
      ;
--
    -- *** ���[�J���E���R�[�h ***
    ap_invoice_oif_rec get_ap_invoice_oif_cur%ROWTYPE;
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
    -- ���z���������Ă��鐿���d��𒲐�
    -- =========================================================
    <<ap_oif_loop>>
    FOR ap_invoice_oif_rec IN get_ap_invoice_oif_cur LOOP
--
      BEGIN
        -- AP������OIF�X�V
        UPDATE ap_invoices_interface aii
        SET    aii.invoice_amount  = ( aii.invoice_amount + ap_invoice_oif_rec.adjust_amount)  -- ���z����
        WHERE  aii.invoice_id      = ap_invoice_oif_rec.invoice_id
        ;
--
        -- AP����������OIF�X�V
        UPDATE ap_invoice_lines_interface ail
        SET    ail.amount          = ( ail.amount + ap_invoice_oif_rec.adjust_amount)          -- ���z����
        WHERE  ail.invoice_id      = ap_invoice_oif_rec.invoice_id
        ;
      END;
--
    END LOOP ap_oif_loop;
--
    -- AP������OIF�̗v��ID/�������z(�Ŕ�)/�ŗ��N���A
    UPDATE ap_invoices_interface aii
    SET    aii.request_id  = NULL,
           aii.attribute5  = NULL,
           aii.attribute6  = NULL,
           aii.attribute7  = NULL,
           aii.attribute8  = NULL,
           aii.attribute9  = NULL,
           aii.attribute10 = NULL,
           aii.attribute11 = NULL
    WHERE  aii.request_id  = cn_request_id
    ;
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
  END upd_invoice_oif;
-- Ver1.6 Add End
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
-- 2015-03-09 Ver1.4 Add Start
    gn_transfer_in_cnt :=0;
-- 2015-03-09 Ver1.4 Add Start
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
    -- �L���x���f�[�^���o(A-3,4)
    -- ===============================
    get_fee_payment_data(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2015.02.25 Ver1.3 Del Start
--    -- ===============================
--    -- �����σf�[�^�폜(A-7)
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
-- 2015.02.25 Ver1.3 Del End
-- 2015-03-09 Ver1.4 Add Start
    -- ===============================
    -- OIF�ꎞ�\�f�[�^�o�^(A-10)
    -- ===============================
    ins_ap_invoice_tmp(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2015-03-09 Ver1.4 Add End
-- Ver1.6 Add Start
    -- ===============================
    -- AP������OIF�X�V(A-11)
    -- ===============================
    upd_invoice_oif(
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- Ver1.6 Add End
    -- ===============================
    -- �A�g�Ǘ��e�[�u���o�^(A-8)
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
-- 2015-03-09 Ver1.4 Add Start
    cv_appl_xxcfo_name CONSTANT VARCHAR2(10)  := 'XXCFO';            -- �A�h�I���F��v�E�A�h�I���̈�
    cv_transfer_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10037'; -- �J�z�������b�Z�[�W
    cv_transfer_in_msg CONSTANT VARCHAR2(100) := 'APP-XXCFO1-10054'; -- �J�z�f�[�^�捞�������b�Z�[�W
-- 2015-03-09 Ver1.4 Add End
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
-- 2015-03-09 Ver1.4 Add Start
      gn_transfer_in_cnt := 0;
-- 2015-03-09 Ver1.4 Add End
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
-- 2015-03-09 Ver1.4 Add Start
    --
    -- �J�z�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcfo_name
                    ,iv_name         => cv_transfer_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_transfer_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- �J�z�f�[�^�捞�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcfo_name
                    ,iv_name         => cv_transfer_in_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_transfer_in_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2015-03-09 Ver1.4 Add End
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
END XXCFO022A02C;
/
