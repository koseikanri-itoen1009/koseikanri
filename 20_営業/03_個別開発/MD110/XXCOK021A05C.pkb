CREATE OR REPLACE PACKAGE BODY XXCOK021A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A05C(body)
 * Description      : AP�C���^�[�t�F�C�X
 * MD.050           : AP�C���^�[�t�F�[�X MD050_COK_021_A05
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_csv           �f�[�^�t�@�C���o��(A-8)
 *  change_status        �A�g�X�e�[�^�X�X�V(A-7)
 *  amount_chk           ���z�`�F�b�N(A-6)
 *  create_detail_tax    AP����������OIF�o�^(A-5) �����
 *  create_detail_data   AP����������OIF(A-5) �ňȊO
 *  create_oif_data      AP�������w�b�_�[OIF�o�^(A-3)
 *  init                 ��������(A-1)
 *  submain              ���C�������v���V�[�W��
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   S.Tozawa         �V�K�쐬
 *  2009/02/02    1.1   S.Tozawa         [��QCOK_006]�����e�X�g���C���Ή�
 *  2009/02/12    1.2   K.Iwabuchi       [��QCOK_030]�����e�X�g���C���Ή�
 *  2009/10/06    1.3   S.Moriyama       [��QE_T3_00632]�d��`�[���͎҂��������s���[�U�[�̏]�ƈ��ԍ��֕ύX
 *  2009/10/22    1.4   K.Yamaguchi      [��QE_T4_00070]�x���O���[�v��ݒ肵�Ȃ��悤�ɕύX
 *  2009/11/25    1.5   K.Yamaguchi      [E_�{�ғ�_00021]���z�s��v�Ή�
 *                                                       ���׃��R�[�h�擾���ɃC���^�[�t�F�[�X�X�e�[�^�X��
 *                                                       �l������悤�ɕύX
 *                                                       AP_IF�w�b�_�ɓo�^���Ă��鐿�����ԍ���≮�x���e�[�u���֍X�V
 *  2009/12/09    1.6   K.Yamaguchi      [E_�{�ғ�_00388]�A�g�X�e�[�^�X�X�V�����R��Ή�
 *  2010/09/21    1.7   M.Watanabe       [E_�{�ғ�_02046]
 *                                       �E�}�C�i�X�x�����z����APOIF�������^�C�v�̐ݒ�l�ύX
 *                                       �E�⏕�Ȗږ��̎擾���̏����ǉ�
 *  2012/03/27    1.8   S.Niki           [E_�{�ғ�_08315]�x���N�Z���̐ݒ�l�ύX
 *  2014/04/09    1.9   K.Kiriu          [E_�{�ғ�_11765]����ő��őΉ�
 *  2019/06/14    1.10  N.Abe            [E_�{�ғ�_15472]�y���ŗ��Ή�
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK021A05C';
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  cv_sqlap_appl_short_name   CONSTANT VARCHAR2(10)  := 'SQLAP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[
  cv_msg_code_00042          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';  -- ��v���ԃ`�F�b�N�x�����b�Z�[�W
  cv_msg_code_10189          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10189';  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_code_10190          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10190';  -- �f�[�^�o�^�G���[(�w�b�_�[)
  cv_msg_code_10191          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10191';  -- �f�[�^�o�^�G���[(���ׁE�̔��萔��)
  cv_msg_code_10192          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10192';  -- �f�[�^�o�^�G���[(���ׁE�̔����^��)
  cv_msg_code_10193          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10193';  -- �f�[�^�o�^�G���[(���ׁE���̑��Ȗ�)
  cv_msg_code_10194          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10194';  -- ���׋��z���Ⴡ�b�Z�[�W
  cv_msg_code_10195          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10195';  -- ���b�N�擾�G���[(����������)
  cv_msg_code_10196          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10196';  -- �X�V�G���[(����������)
  cv_msg_code_10197          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10197';  -- ���b�N�擾�G���[(�x���e�[�u��)
  cv_msg_code_10198          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10198';  -- �X�V�G���[(�x���e�[�u��)
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';  -- ��������
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_code_90003          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';  -- �X�L�b�v����
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';  -- ����I��
  cv_msg_code_90005          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_msg_code_90008          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_code_00034          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00034';  -- ����Ȗڏ��擾�G���[
  cv_msg_code_10407          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10407';  -- �f�[�^�o�^�G���[(���ׁE�����)
  cv_msg_code_10416          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10416';  -- �������ԍ��擾�G���[
  cv_msg_code_00089          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00089';  -- ����Ŏ擾�G���[
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD START
  cv_msg_code_00005          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00005';  -- �]�ƈ��擾�G���[
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  cv_msg_code_10565          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10565';  -- ����ŗ��擾���s�G���[���b�Z�[�W
  cv_msg_code_10566          CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10566';  -- ����ŗ����d���G���[���b�Z�[�W
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- �g�[�N��
  cv_token_profile           CONSTANT VARCHAR2(20)  := 'PROFILE';
  cv_token_proc_date         CONSTANT VARCHAR2(20)  := 'PROC_DATE';
  cv_token_payment_date      CONSTANT VARCHAR2(20)  := 'PAYMENT_DATE';
  cv_token_sales_month       CONSTANT VARCHAR2(20)  := 'SALES_MONTH';
  cv_token_vender_code       CONSTANT VARCHAR2(20)  := 'VENDOR_CODE';
  cv_token_base_code         CONSTANT VARCHAR2(20)  := 'BASE_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';
  cv_token_balance_code      CONSTANT VARCHAR2(20)  := 'BALANCE_CODE';
  cv_token_acct_code         CONSTANT VARCHAR2(20)  := 'ACCOUNT_CODE';
  cv_token_assist_code       CONSTANT VARCHAR2(20)  := 'ASSIST_CODE';
  cv_token_count             CONSTANT VARCHAR2(20)  := 'COUNT';
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  cv_token_item_code         CONSTANT VARCHAR2(9)   := 'ITEM_CODE';
  cv_token_sub_acct_code     CONSTANT VARCHAR2(13)  := 'SUB_ACCT_CODE';
  cv_token_year_month        CONSTANT VARCHAR2(10)  := 'YEAR_MONTH';
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- �v���t�@�C��
  cv_prof_books_id           CONSTANT VARCHAR2(40)  := 'GL_SET_OF_BKS_ID';               -- ��v����ID
  cv_prof_org_id             CONSTANT VARCHAR2(40)  := 'ORG_ID';                         -- �g�DID
  -- �J�X�^���E�v���t�@�C��
  cv_prof_company_code       CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF1_COMPANY_CODE';       -- ��ЃR�[�h
  cv_prof_dept_act           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_ACT';           -- ����R�[�h_�Ɩ��Ǘ���
  cv_prof_detail_type_item   CONSTANT VARCHAR2(40)  := 'XXCOK1_OIF_DETAIL_TYPE_ITEM';    -- OIF���׃^�C�v_����
  cv_prof_invoice_source     CONSTANT VARCHAR2(40)  := 'XXCOK1_INVOICE_SOURCE';          -- �������\�[�X
-- 2009/10/22 Ver.1.4 [��QE_T4_00070] SCS K.Yamaguchi DELETE START
--  cv_prof_pay_group          CONSTANT VARCHAR2(40)  := 'XXCOK1_PAY_GROUP';               -- �x���O���[�v
-- 2009/10/22 Ver.1.4 [��QE_T4_00070] SCSK K.Yamaguchi DELETE END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu DELETE START
--  cv_prof_invoice_tax_code   CONSTANT VARCHAR2(40)  := 'XXCOK1_INVOICE_TAX_CODE';        -- �������ŃR�[�h
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCS K.Kiriu DELETE END
  cv_prof_dept_fin           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_FIN';           -- ����R�[�h_�����o����
  cv_prof_customer_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';     -- �ڋq�R�[�h_�_�~�[�l
  cv_prof_company_dummy      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF6_COMPANY_DUMMY';      -- ��ƃR�[�h_�_�~�[�l
  cv_prof_pre1_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY'; -- �\��1_�_�~�[�l
  cv_prof_pre2_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY'; -- �\��2_�_�~�[�l
  cv_prof_detail_type_tax    CONSTANT VARCHAR2(40)  := 'XXCOK1_OIF_DETAIL_TYPE_TAX';     -- OIF���׃^�C�v_�ŋ�
  -- �v���t�@�C���F����Ȗ�
  cv_prof_acct_sell_fee      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_SELL_FEE';           -- �̔��萔��(�≮)
  cv_prof_acct_sell_support  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_SELL_SUPPORT';       -- �̔����^��(�≮)
  cv_prof_acct_payable       CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYABLE';            -- ������
  cv_prof_acct_excise_tax    CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX'; -- ��������œ�
  -- �v���t�@�C���F�⏕�Ȗ�
  cv_prof_asst_sell_fee      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SELL_FEE';           -- �̔��萔��(�≮)_�≮����
  cv_prof_asst_sell_support  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SELL_SUPPORT';       -- �̔����^��(�≮)_�g����
  cv_prof_asst_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';      -- �_�~�[�l
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
  cv_prof_inst_term_name     CONSTANT VARCHAR2(40)  := 'XXCOK1_INSTANTLY_TERM_NAME';     -- �x������_��������
  cv_prof_spec_term_name     CONSTANT VARCHAR2(40)  := 'XXCOK1_SPECIFICATION_TERM_NAME'; -- �x������_�w�蕥��
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  cv_hyphen                  CONSTANT VARCHAR2(1)   := '-';
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- CSV�t�@�C���o�͗p
  cv_lookup_type_ap_column   CONSTANT VARCHAR2(40)  := 'XXCOK1_AP_IF_COLUMN_NAME'; -- APIF���ږ�(�N�C�b�N�R�[�h�Q��)
  cv_csv_part                CONSTANT VARCHAR2(3)   := ',';                        -- ��؂�p�J���}
  -- �o�͋敪
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                      -- �o�͋敪�F'LOG'
  -- ���l(���s�̎w��Ɏg�p)
  cn_number_0                CONSTANT NUMBER        := 0;                          -- ���b�Z�[�W�o�͌���s�Ȃ�
  cn_number_1                CONSTANT NUMBER        := 1;                          -- ���b�Z�[�W�o�͌�󔒍s1�s�ǉ�
  -- AP������OIF�o�^�p
  cv_invoice_type_standard   CONSTANT VARCHAR(30)   := 'STANDARD';          -- ����^�C�v�F�W��
-- ************ 2010/09/21 1.7 M.Watanabe ADD START ************ --
  cv_invoice_type_credit     CONSTANT VARCHAR(30)   := 'CREDIT';            -- ����^�C�v�F�N���W�b�g�E����
-- ************ 2010/09/21 1.7 M.Watanabe ADD END   ************ --
--
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama DEL START
--  cn_slip_input_user         CONSTANT NUMBER        := fnd_global.user_id;  -- ���O�C�����F���[�UID
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama DEL END
  -- AP�A�g�X�e�[�^�X
  cv_payment_uncooperate     CONSTANT VARCHAR2(1)   := '0';                 -- ���A�g(�≮�x���e�[�u��)
  cv_payment_cooperate       CONSTANT VARCHAR2(1)   := '1';                 -- �A�g��(�≮�x���e�[�u��)
  cv_bill_cooperate          CONSTANT VARCHAR2(1)   := 'P';                 -- �A�g��(�≮���������׃e�[�u��)
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
  -- ����
  cv_format_mm               CONSTANT VARCHAR2(2)   := 'MM';
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
  cv_format_yyyymm           CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_format_yyyymm_sla       CONSTANT VARCHAR2(7)   := 'YYYY/MM';
  cv_format_yyyymmdd_sla     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  -- �ėp�t���O
  cv_yes                     CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                      CONSTANT VARCHAR2(1)   := 'N';
  -- �Q�ƃ^�C�v
  cv_lookup_type_invoice     CONSTANT VARCHAR2(23)  := 'XXCOK1_INVOICE_TAX_CODE';  -- �������ŋ��R�[�h
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  cv_lookup_sub_acct_tax     CONSTANT VARCHAR2(19)  := 'XXCOK1_SUB_ACCT_TAX';       -- ����Ȗڎx���ŗ�
  cv_lookup_tax_code         CONSTANT VARCHAR2(15)  := 'XXCFO1_TAX_CODE';           -- �y���ŗ��p�Ŏ��
  cv_lookup_tax_code_his     CONSTANT VARCHAR2(25)  := 'XXCFO1_TAX_CODE_HISTORIES'; -- �y���ŗ�����
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  -- �J�E���^
  gn_target_cnt              NUMBER       DEFAULT 0;      -- �Ώی���
  gn_normal_cnt              NUMBER       DEFAULT 0;      -- ���팏��
  gn_skip_cnt                NUMBER       DEFAULT 0;      -- �x������(�X�L�b�v����)
  gn_error_cnt               NUMBER       DEFAULT 0;      -- �G���[����
  gn_detail_num              NUMBER       DEFAULT 1;      -- OIF�w�b�_�[�����טA��(�w�b�_�[���Ƀ��Z�b�g)
  gn_sell_detail_num         NUMBER       DEFAULT 0;      -- �≮�x���e�[�u���Ŏ擾�������חp�f�[�^�̌���
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
  gn_invoice_tax_err_cnt     NUMBER       DEFAULT 0;      -- �������ŋ��R�[�h�擾�G���[����
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
  -- ��������(A-1) �擾�f�[�^�i�[
  gv_prof_books_id           VARCHAR2(40) DEFAULT NULL;   -- �v���t�@�C���F��v����ID
  gv_prof_org_id             VARCHAR2(40) DEFAULT NULL;   -- �v���t�@�C���F�g�DID
  gv_prof_company_code       VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F��ЃR�[�h
  gv_prof_dept_act           VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F����R�[�h_�Ɩ��Ǘ���
  gv_prof_detail_type_item   VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���FOIF���׃^�C�v_����
  gv_prof_invoice_source     VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�������\�[�X
  gv_prof_pay_group          VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�x���O���[�v
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu DELETE START
--  gv_prof_invoice_tax_code   VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�������ŃR�[�h
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu DELETE END
  gv_prof_dept_fin           VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F����R�[�h_�����o����
  gv_prof_customer_dummy     VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�ڋq�R�[�h_�_�~�[�l
  gv_prof_company_dummy      VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F��ƃR�[�h_�_�~�[�l
  gv_prof_pre1_dummy         VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�\��1_�_�~�[�l
  gv_prof_pre2_dummy         VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�\��2_�_�~�[�l
  gv_prof_detail_type_tax    VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���FOIF���׃^�C�v_�ŋ�
  gv_prof_acct_sell_fee      VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�̔��萔��(�≮)
  gv_prof_acct_sell_support  VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�̔����^��(�≮)
  gv_prof_acct_payable       VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F������
  gv_prof_acct_excise_tax    VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F��������œ�
  gv_prof_asst_sell_fee      VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�̔��萔��(�≮)_�≮����
  gv_prof_asst_sell_support  VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�̔����^��(�≮)_�g����
  gv_prof_asst_dummy         VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�_�~�[�l
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
  gv_prof_inst_term_name     VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�x������_��������
  gv_prof_spec_term_name     VARCHAR2(50) DEFAULT NULL;   -- �v���t�@�C���F�x������_�w�蕥��
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
  gd_prof_process_date       DATE         DEFAULT NULL;   -- �Ɩ����t�i�[
  gn_tax_rate                NUMBER       DEFAULT NULL;   -- �ŗ�
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
  gv_tax_code                VARCHAR2(50) DEFAULT NULL;   -- �ŃR�[�h
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
  gn_payment_ccid            NUMBER       DEFAULT NULL;   -- ������Ȗ�CCID
  gn_tax_ccid                NUMBER       DEFAULT NULL;   -- ��������ŉȖ�CCID
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
--  -- AP������OIF�w�b�_�[�o�^���z
--  gn_header_amt              NUMBER       DEFAULT 0;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
  -- �o�̓t�@�C������t���O
  gb_outfile_first_flag      BOOLEAN      DEFAULT TRUE;
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD START
  gt_employee_number         per_all_people_f.employee_number%TYPE;  -- �]�ƈ��ԍ�
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
  -- �������ŋ��R�[�h�G���[�t���O
  gv_invoice_tax_err_flag    VARCHAR2(1)  DEFAULT 'N';
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  gn_bill_amt                NUMBER;                      -- �������z
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  -- �≮�x�����擾�J�[�\��
  CURSOR g_sell_haeder_cur(
    in_org_id    IN  NUMBER                                    -- �c�ƒP��ID(�g�DID)
  , id_proc_date IN  DATE                                      -- �Ɩ��������t
  )
  IS
    SELECT xwp.expect_payment_date AS expect_payment_date      -- �x���\���
         , xwp.selling_month       AS selling_month            -- ����Ώ۔N��
         , xwp.supplier_code       AS supplier_code            -- �d����R�[�h
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
         , att.name                AS term_name                -- �x������
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
         , SUM( xwp.payment_amt )  AS payment_amt              -- �x�����z(�Ŕ�)(�W�v)
         , pvsa.vendor_site_code   AS vendor_site_code         -- �d����T�C�g�R�[�h
         , xwp.base_code           AS base_code                -- ���_�R�[�h
    FROM   xxcok_wholesale_payment    xwp                      -- �≮�x���e�[�u��
         , po_vendors                 pv                       -- �d����}�X�^
         , po_vendor_sites_all        pvsa                     -- �d����T�C�g�}�X�^
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
         , ap_terms                   att                      -- �x�������}�X�^
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
    WHERE  xwp.ap_interface_status = cv_payment_uncooperate    -- AP�C���^�[�t�F�[�X�A�g�󋵁F'0'���A�g
    AND    pv.vendor_id            = pvsa.vendor_id
    AND    pv.segment1             = xwp.supplier_code
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
    AND    pvsa.terms_id           = att.term_id
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
    AND    pvsa.org_id             = in_org_id                 -- �c�ƒP��ID = A-1.�Ŏ擾�����g�DID
    AND ( 
           ( pvsa.inactive_date    > id_proc_date )            -- ������ > �Ɩ��������t OR ������ IS NULL
      OR   ( pvsa.inactive_date    IS NULL )
    )
    GROUP BY
           xwp.expect_payment_date         -- �x���\���
         , xwp.selling_month               -- ����Ώ۔N��
         , xwp.supplier_code               -- �d����R�[�h
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
         , att.name                        -- �x������
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
         , pvsa.vendor_site_code           -- �d����T�C�g�R�[�h
         , xwp.base_code                   -- ���_�R�[�h
  ;
  -- �≮���������׏��擾�J�[�\��
  CURSOR g_sell_detail_cur(
    id_payment_date   IN DATE                                  -- �x���\���
  , iv_selling_month  IN VARCHAR2                              -- ����Ώ۔N��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  , id_b_month        IN DATE                                  -- ����Ώ۔N���i�������j
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  , iv_supplier_code  IN VARCHAR2                              -- �d����R�[�h
  , iv_base_code      IN VARCHAR2                              -- ���_�R�[�h
  )
  IS
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    SELECT sub.cust_code
          ,sub.sales_outlets_code
          ,sub.acct_code
          ,sub.sub_acct_code
          ,sub.misc_acct_amt
          ,sub.backmargin
          ,sub.sales_support_amt
          ,sub.sum_payment_amt
          ,sub.tax_code
          ,sub.tax_rate
    FROM (
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    SELECT xwp.cust_code                                                      AS cust_code           -- �ڋq�R�[�h
         , xwp.sales_outlets_code                                             AS sales_outlets_code  -- �≮������R�[�h
         , xwp.acct_code                                                      AS acct_code           -- ����ȖڃR�[�h
         , xwp.sub_acct_code                                                  AS sub_acct_code       -- �⏕�ȖڃR�[�h
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi REPAIR START
--         , SUM( NVL( xwp.misc_acct_amt, 0 ) )                                 AS misc_acct_amt       -- ���̑����z(�W�v)
--         , SUM( NVL( xwp.backmargin, 0 ) * NVL( xwp.payment_qty, 0 ) )        AS backmargin          -- �̔��萔��(�W�v)
--         , SUM( NVL( xwp.sales_support_amt, 0 ) * NVL( xwp.payment_qty, 0 ) ) AS sales_support_amt   -- �̔����^��(�W�v)
         , SUM( NVL( TRUNC( xwp.misc_acct_amt ), 0 ) )                        AS misc_acct_amt       -- ���̑����z(�W�v)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 0
               ELSE
                 xwp.payment_amt - TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS backmargin          -- �̔��萔��(�W�v)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 0
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               ELSE
                 TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS sales_support_amt   -- �̔����^��(�W�v)
         , SUM( xwp.payment_amt )                                             AS sum_payment_amt     -- �x�����z
         , xrtrv.tax_class_suppliers_outside                                  AS tax_code            -- �ŋ敪_�d���O��
         , xrtrv.tax_rate                                                     AS tax_rate
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi REPAIR END
    FROM   xxcok_wholesale_payment         xwp       -- �≮�x���e�[�u��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
         , xxcos_reduced_tax_rate_v        xrtrv     -- XXCOS�i�ڕʏ���ŗ��r���[
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    WHERE  xwp.expect_payment_date = id_payment_date
    AND    xwp.selling_month       = iv_selling_month
    AND    xwp.supplier_code       = iv_supplier_code
    AND    xwp.base_code           = iv_base_code
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD START
    AND    xwp.ap_interface_status = cv_payment_uncooperate    -- AP�C���^�[�t�F�[�X�A�g�󋵁F'0'���A�g
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    AND    xwp.item_code          IS NOT NULL                       -- �i�ڂ��ݒ肳��Ă郌�R�[�h�̂�
    AND    xwp.item_code           = xrtrv.item_code(+)             -- �i�ڃR�[�h
    AND    id_b_month             >= xrtrv.start_date(+)
    AND    id_b_month             <= NVL(xrtrv.end_date(+), id_b_month)
    AND    id_b_month             >= xrtrv.start_date_histories(+)
    AND    id_b_month             <= NVL(xrtrv.end_date_histories(+), id_b_month)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    GROUP BY 
           xwp.cust_code                               -- �ڋq�R�[�h
         , xwp.sales_outlets_code                      -- �≮������R�[�h
         , xwp.acct_code                               -- ����ȖڃR�[�h
         , xwp.sub_acct_code                           -- �⏕�ȖڃR�[�h
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
         , xrtrv.tax_class_suppliers_outside           -- �������ŃR�[�h
         , xrtrv.tax_rate                              -- ����ŗ�
    UNION ALL
    SELECT xwp.cust_code                                                      AS cust_code           -- �ڋq�R�[�h
         , xwp.sales_outlets_code                                             AS sales_outlets_code  -- �≮������R�[�h
         , xwp.acct_code                                                      AS acct_code           -- ����ȖڃR�[�h
         , xwp.sub_acct_code                                                  AS sub_acct_code       -- �⏕�ȖڃR�[�h
         , SUM( NVL( TRUNC( xwp.misc_acct_amt ), 0 ) )                        AS misc_acct_amt       -- ���̑����z(�W�v)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 0
               ELSE
                 xwp.payment_amt - TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS backmargin          -- �̔��萔��(�W�v)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 0
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               ELSE
                 TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS sales_support_amt   -- �̔����^��(�W�v)
         , SUM(xwp.payment_amt)                                               AS sum_payment_amt     -- �x�����z�i���v�j
         , flvv_his.attribute2                                                AS tax_code            -- �ŋ敪_�d���O��
         , TO_NUMBER(flvv_his.attribute1)                                     AS tax_rate
    FROM   xxcok_wholesale_payment         xwp                      -- �≮�x���e�[�u��
         , fnd_lookup_values_vl            flvv_tax                 -- LOOKUP�\�i�y���ŗ��p�Ŏ�ʁj
         , fnd_lookup_values_vl            flvv_his                 -- LOOKUP�\�i�y���ŗ������j
         , fnd_lookup_values_vl            flvv_act                 -- LOOKUP�\�i�⏕�Ȗڐŗ��j
    WHERE  xwp.expect_payment_date         =  id_payment_date
    AND    xwp.selling_month               =  iv_selling_month
    AND    xwp.supplier_code               =  iv_supplier_code
    AND    xwp.base_code                   =  iv_base_code
    AND    xwp.ap_interface_status         =  cv_payment_uncooperate       -- AP�C���^�[�t�F�[�X�A�g�󋵁F'0'���A�g
    AND    xwp.sub_acct_code              IS NOT NULL                      -- �⏕�Ȗڂ��ݒ肳��Ă郌�R�[�h�̂�
    AND    xwp.acct_code || cv_hyphen || xwp.sub_acct_code
                                           =  flvv_act.lookup_code(+)      -- �⏕�ȖڃR�[�h
    AND    flvv_act.lookup_type(+)         =  cv_lookup_sub_acct_tax       -- �Q�ƃ^�C�v
    AND    flvv_act.enabled_flag(+)        =  cv_yes
    AND    flvv_act.start_date_active(+)  <=  id_b_month
    AND    NVL(flvv_act.end_date_active(+), id_b_month)
                                          >=  id_b_month
    AND    flvv_act.description            =  flvv_tax.lookup_code(+)
    AND    flvv_tax.lookup_type(+)         =  cv_lookup_tax_code           -- �Q�ƃ^�C�v
    AND    flvv_tax.enabled_flag(+)        =  cv_yes
    AND    flvv_tax.start_date_active(+)  <=  id_b_month
    AND    NVL(flvv_tax.end_date_active(+), id_b_month)
                                          >=  id_b_month
    AND    flvv_tax.lookup_code            =  flvv_his.tag(+)
    AND    flvv_his.lookup_type(+)         =  cv_lookup_tax_code_his       -- �Q�ƃ^�C�v
    AND    flvv_his.enabled_flag(+)        =  cv_yes
    AND    flvv_his.start_date_active(+)  <=  id_b_month
    AND    NVL(flvv_his.end_date_active(+), id_b_month)
                                          >=  id_b_month
    GROUP BY
           xwp.cust_code                               -- �ڋq�R�[�h
         , xwp.sales_outlets_code                      -- �≮������R�[�h
         , xwp.acct_code                               -- ����ȖڃR�[�h
         , xwp.sub_acct_code                           -- �⏕�ȖڃR�[�h
         , flvv_his.attribute2                         -- �������ŃR�[�h
         , flvv_his.attribute1                         -- ����ŗ�
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  ) sub
  ORDER BY tax_code;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
--  -- �������ŃR�[�h
--  CURSOR g_invoice_tax_cur
--  IS
--    SELECT flvv.meaning            tax_code           --�ŃR�[�h
--         , flvv.description        tax_rate           --�ŗ�
--         , flvv.start_date_active  start_date_active  --�K�p�J�n��
--         , flvv.end_date_active    end_date_active    --�K�p�I����
--    FROM   fnd_lookup_values_vl flvv
--    WHERE  flvv.lookup_type   = cv_lookup_type_invoice
--    AND    flvv.enabled_flag  = cv_yes
--  ;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  --�ŗ��擾�J�[�\��
  CURSOR g_tax_cur(
    id_pay_date   IN  DATE        -- �x���\���
   ,iv_sel_month  IN  VARCHAR2    -- ����Ώ۔N��
   ,id_b_month    IN  DATE        -- ����Ώ۔N���i�������j
   ,iv_sup_code   IN  VARCHAR2    -- �d����R�[�h
   ,iv_base_code  IN  VARCHAR2    -- ���_�R�[�h
  )
  IS
    -- �i�ڂ̐ŗ�
    SELECT xwp.item_code                      AS item_code                    -- �i�ڃR�[�h
          ,xwp.acct_code                      AS acct_code                    -- ����ȖڃR�[�h
          ,xwp.sub_acct_code                  AS sub_acct_code                -- �⏕�ȖڃR�[�h
          ,xrtrv.tax_class_suppliers_outside  AS tax_code                     -- �ŋ敪_�d���O��
          ,xrtrv.tax_rate                     AS tax_rate
    FROM   xxcok_wholesale_payment        xwp                             -- �≮�x���e�[�u��
          ,xxcos_reduced_tax_rate_v       xrtrv                           -- XXCOS�i�ڕʏ���ŗ��r���[
    WHERE  xwp.expect_payment_date        =  id_pay_date                  -- �x���\���
    AND    xwp.selling_month              =  iv_sel_month                 -- ����Ώ۔N��
    AND    xwp.supplier_code              =  iv_sup_code                  -- �d����R�[�h
    AND    xwp.base_code                  =  iv_base_code                 -- ���_�R�[�h
    AND    xwp.ap_interface_status        =  cv_payment_uncooperate       -- AP�A�g�X�e�[�^�X(���A�g�F0�j
    AND    xwp.item_code                  IS NOT NULL                     -- �i�ڂ��ݒ肳��Ă郌�R�[�h�̂�
    AND    xwp.item_code                  =  xrtrv.item_code(+)           -- �i�ڃR�[�h
    AND    id_b_month                     >= xrtrv.start_date(+)
    AND    id_b_month                     <= NVL(xrtrv.end_date(+), id_b_month)
    AND    id_b_month                     >= xrtrv.start_date_histories(+)
    AND    id_b_month                     <= NVL(xrtrv.end_date_histories(+), id_b_month)
    GROUP BY  xwp.item_code
             ,xwp.acct_code
             ,xwp.sub_acct_code
             ,xrtrv.tax_class_suppliers_outside
             ,xrtrv.tax_rate
    UNION ALL
    -- ����Ȗځi�⏕�Ȗځj�̐ŗ�
    SELECT xwp.item_code                  AS item_code                    -- �i�ڃR�[�h
          ,xwp.acct_code                  AS acct_code                    -- ����ȖڃR�[�h
          ,xwp.sub_acct_code              AS sub_acct_code                -- �⏕�ȖڃR�[�h
          ,flvv_his.attribute2            AS tax_code                     -- �ŋ敪_�d���O��
          ,TO_NUMBER(flvv_his.attribute1) AS tax_rate
    FROM   xxcok_wholesale_payment        xwp                             -- �≮�x���e�[�u��
          ,fnd_lookup_values_vl           flvv_tax                        -- LOOKUP�\�i�y���ŗ��p�Ŏ�ʁj
          ,fnd_lookup_values_vl           flvv_his                        -- LOOKUP�\�i�y���ŗ������j
          ,fnd_lookup_values_vl           flvv_act                        -- LOOKUP�\�i�⏕�Ȗڐŗ��j
    WHERE  xwp.expect_payment_date        =  id_pay_date                  -- �x���\���
    AND    xwp.selling_month              =  iv_sel_month                 -- ����Ώ۔N��
    AND    xwp.supplier_code              =  iv_sup_code                  -- �d����R�[�h
    AND    xwp.base_code                  =  iv_base_code                 -- ���_�R�[�h
    AND    xwp.ap_interface_status        =  cv_payment_uncooperate       -- AP�A�g�X�e�[�^�X(���A�g�F0�j
    AND    xwp.sub_acct_code              IS NOT NULL                     -- �⏕�Ȗڂ��ݒ肳��Ă郌�R�[�h�̂�
    AND    xwp.acct_code || cv_hyphen || xwp.sub_acct_code
                                          =  flvv_act.lookup_code(+)      -- ����ȖڃR�[�h - �⏕�ȖڃR�[�h
    AND    flvv_act.lookup_type(+)        =  cv_lookup_sub_acct_tax       -- �Q�ƃ^�C�v
    AND    flvv_act.enabled_flag(+)       =  cv_yes
    AND    flvv_act.start_date_active(+)  <= id_b_month
    AND    NVL(flvv_act.end_date_active(+), id_b_month)
                                          >= id_b_month
    AND    flvv_act.description           =  flvv_tax.lookup_code(+)
    AND    flvv_tax.lookup_type(+)        =  cv_lookup_tax_code           -- �Q�ƃ^�C�v
    AND    flvv_tax.enabled_flag(+)       =  cv_yes
    AND    flvv_tax.start_date_active(+)  <= id_b_month
    AND    NVL(flvv_tax.end_date_active(+), id_b_month)
                                          >= id_b_month
    AND    flvv_tax.lookup_code           =  flvv_his.tag(+)
    AND    flvv_his.lookup_type(+)        =  cv_lookup_tax_code_his       -- �Q�ƃ^�C�v
    AND    flvv_his.enabled_flag(+)       =  cv_yes
    AND    flvv_his.start_date_active(+)  <= id_b_month
    AND    NVL(flvv_his.end_date_active(+), id_b_month)
                                          >= id_b_month
    GROUP BY  xwp.item_code
             ,xwp.acct_code
             ,xwp.sub_acct_code
             ,flvv_his.attribute2
             ,flvv_his.attribute1
  ;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- ===============================================
  -- �O���[�o���J�[�\���e�[�u���^�C�v
  -- ===============================================
  -- �≮�x���擾���ʊi�[�e�[�u���^
  TYPE g_sell_header_ttype IS TABLE OF g_sell_haeder_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- �≮���������׎擾���ʊi�[�e�[�u���^
  TYPE g_sell_detail_ttype IS TABLE OF g_sell_detail_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
--  -- �������ŃR�[�h
--  TYPE g_invoice_tax_ttype IS TABLE OF g_invoice_tax_cur%ROWTYPE
--  INDEX BY BINARY_INTEGER;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  -- �ŗ��擾���ʊi�[�e�[�u���^
  TYPE g_bill_amd_ttype IS TABLE OF g_tax_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  -- ===============================================
  -- �O���[�o���e�[�u���^�ϐ�
  -- ===============================================
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
--  gt_invoice_tax_tab  g_invoice_tax_ttype;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
  -- ===============================================
  -- �O���[�o����O
  -- ===============================================
  global_api_expt           EXCEPTION;                 -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION;                 -- ���ʊ֐�OTHERS��O
  global_lock_fail_expt     EXCEPTION;                 -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_fail_expt, -54 );
--
  /************************************************************************
   * Procedure Name  : create_csv
   * Description     : �f�[�^�t�@�C���o��(A-8)
   ************************************************************************/
  PROCEDURE create_csv(
    ov_errbuf        OUT  VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT  VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg        OUT  VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_haed_data_rec IN   g_sell_haeder_cur%ROWTYPE  -- AP������OIF�w�b�_�[���
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'create_csv';           -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_payment_date        VARCHAR2(20)   DEFAULT NULL;             -- ������ϊ�����t�i�[
    ln_payment_amt         NUMBER         DEFAULT NULL;             -- �x�����z(�ō�)
    lv_csv_line            VARCHAR2(5000) DEFAULT NULL;             -- CSV�o�͕�����(1�s��)
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- ���ږ��擾�J�[�\��
    CURSOR get_column_name_cur
    IS
      SELECT xlvv.meaning       AS column_name              -- �~�[�j���O(���ږ�)
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_lookup_type_ap_column    -- �N�C�b�N�R�[�h�FAPIF���ږ�
      ORDER BY
             TO_NUMBER( xlvv.lookup_code )                  -- ���b�N�A�b�v�R�[�h(�o�͔ԍ�)
    ;
    -- �o�͓��e�擾�J�[�\��
    CURSOR get_csv_data_cur(
      id_payment_date   IN DATE                                  -- �x���\���
    , iv_selling_month  IN VARCHAR2                              -- ����Ώ۔N��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    , id_b_month        IN DATE                                  -- ����Ώ۔N���i�������j
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    , iv_supplier_code  IN VARCHAR2                              -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN VARCHAR2                              -- ���_
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
    )
    IS
      SELECT xwp.expect_payment_date  AS expect_payment_date     -- �x���\���
           , xwp.supplier_code        AS supplier_code           -- �d����R�[�h
           , xwp.bill_no              AS bill_no                 -- ������No
           , xwp.base_code            AS base_code               -- ���_�R�[�h
           , hca_base.account_name    AS base_name               -- ���_��
           , xwp.cust_code            AS cust_code               -- �ڋq�R�[�h
           , hca_cust.account_name    AS cust_name               -- �ڋq��
           , xwp.sales_outlets_code   AS sales_outlets_code      -- �≮������R�[�h
           , hca_sale.account_name    AS sales_outlets_name      -- �≮�����於��
           , xwp.acct_code            AS acct_code               -- ����ȖڃR�[�h
           , xav.description          AS acct_name               -- ����Ȗږ���
           , xwp.sub_acct_code        AS sub_acct_code           -- �⏕�ȖڃR�[�h
           , xsav.description         AS sub_acct_name           -- �⏕�Ȗږ���
           , SUM( xwp.payment_amt )   AS payment_amt             -- �x�����z(�Ŕ�)(�W�v)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
           , xrtrv.tax_rate           AS tax_rate                -- ����ŗ�
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
      FROM   xxcok_wholesale_payment  xwp                        -- �≮�x���e�[�u��
           , hz_cust_accounts         hca_base                   -- �ڋq�R�[�h(���_)
           , hz_cust_accounts         hca_cust                   -- �ڋq�R�[�h(�ڋq)
           , hz_cust_accounts         hca_sale                   -- �ڋq�R�[�h(������R�[�h)
           , xx03_accounts_v          xav                        -- AFF����Ȗ�
           , xx03_sub_accounts_v      xsav                       -- AFF�⏕�Ȗ�
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
           , xxcos_reduced_tax_rate_v xrtrv                      -- XXCOS�i�ڕʏ���ŗ��r���[
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
      WHERE  xwp.expect_payment_date  = id_payment_date
      AND    xwp.selling_month        = iv_selling_month
      AND    xwp.supplier_code        = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
      AND    xwp.base_code            = iv_base_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
      AND    xwp.request_id           = cn_request_id
      AND    xwp.ap_interface_status  = cv_payment_cooperate     -- AP�A�g�t���O�F'1'�A�g��
      AND    xwp.base_code            = hca_base.account_number
      AND    xwp.cust_code            = hca_cust.account_number
      AND    xwp.sales_outlets_code   = hca_sale.account_number(+)
      AND    xwp.acct_code            = xav.flex_value(+)
-- ************ 2010/09/21 1.7 M.Watanabe ADD START ************ --
      AND    xwp.acct_code            = xsav.parent_flex_value_low(+)
-- ************ 2010/09/21 1.7 M.Watanabe ADD END   ************ --
      AND    xwp.sub_acct_code        = xsav.flex_value(+)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
      AND    xwp.item_code           IS NOT NULL                       -- �i�ڂ��ݒ肳��Ă郌�R�[�h�̂�
      AND    xwp.item_code            = xrtrv.item_code(+)             -- �i�ڃR�[�h
      AND    id_b_month              >= xrtrv.start_date(+)
      AND    id_b_month              <= NVL(xrtrv.end_date(+), id_b_month)
      AND    id_b_month              >= xrtrv.start_date_histories(+)
      AND    id_b_month              <= NVL(xrtrv.end_date_histories(+), id_b_month)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
      GROUP BY
             xwp.expect_payment_date                             -- �x���\���
           , xwp.supplier_code                                   -- �d����R�[�h
           , xwp.bill_no                                         -- ������No
           , xwp.base_code                                       -- ���_�R�[�h
           , hca_base.account_name                               -- ���_��
           , xwp.cust_code                                       -- �ڋq�R�[�h
           , hca_cust.account_name                               -- �ڋq��
           , xwp.sales_outlets_code                              -- �≮������R�[�h
           , hca_sale.account_name                               -- �≮�����於��
           , xwp.acct_code                                       -- ����ȖڃR�[�h
           , xav.description                                     -- ����Ȗږ���
           , xwp.sub_acct_code                                   -- �⏕�ȖڃR�[�h
           , xsav.description                                    -- �⏕�Ȗږ���      
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
           , xrtrv.tax_class_suppliers_outside                   -- ����ŃR�[�h
           , xrtrv.tax_rate                                      -- ����ŗ�
      UNION ALL
      SELECT xwp.expect_payment_date  AS expect_payment_date     -- �x���\���
           , xwp.supplier_code        AS supplier_code           -- �d����R�[�h
           , xwp.bill_no              AS bill_no                 -- ������No
           , xwp.base_code            AS base_code               -- ���_�R�[�h
           , hca_base.account_name    AS base_name               -- ���_��
           , xwp.cust_code            AS cust_code               -- �ڋq�R�[�h
           , hca_cust.account_name    AS cust_name               -- �ڋq��
           , xwp.sales_outlets_code   AS sales_outlets_code      -- �≮������R�[�h
           , hca_sale.account_name    AS sales_outlets_name      -- �≮�����於��
           , xwp.acct_code            AS acct_code               -- ����ȖڃR�[�h
           , xav.description          AS acct_name               -- ����Ȗږ���
           , xwp.sub_acct_code        AS sub_acct_code           -- �⏕�ȖڃR�[�h
           , xsav.description         AS sub_acct_name           -- �⏕�Ȗږ���
           , SUM( xwp.payment_amt )   AS payment_amt             -- �x�����z(�Ŕ�)(�W�v)
           , TO_NUMBER(flvv_his.attribute1)
                                      AS tax_rate                -- ����ŗ�
      FROM   xxcok_wholesale_payment  xwp                        -- �≮�x���e�[�u��
           , hz_cust_accounts         hca_base                   -- �ڋq�R�[�h(���_)
           , hz_cust_accounts         hca_cust                   -- �ڋq�R�[�h(�ڋq)
           , hz_cust_accounts         hca_sale                   -- �ڋq�R�[�h(������R�[�h)
           , xx03_accounts_v          xav                        -- AFF����Ȗ�
           , xx03_sub_accounts_v      xsav                       -- AFF�⏕�Ȗ�
           , fnd_lookup_values_vl     flvv_tax                   -- LOOKUP�\�i�y���ŗ��p�Ŏ�ʁj
           , fnd_lookup_values_vl     flvv_his                   -- LOOKUP�\�i�y���ŗ������j
           , fnd_lookup_values_vl     flvv_act                   -- LOOKUP�\�i�⏕�Ȗڐŗ��j
      WHERE  xwp.expect_payment_date        = id_payment_date
      AND    xwp.selling_month              = iv_selling_month
      AND    xwp.supplier_code              = iv_supplier_code
      AND    xwp.base_code                  = iv_base_code
      AND    xwp.request_id                 = cn_request_id
      AND    xwp.ap_interface_status        = cv_payment_cooperate     -- AP�A�g�t���O�F'1'�A�g��
      AND    xwp.base_code                  = hca_base.account_number
      AND    xwp.cust_code                  = hca_cust.account_number
      AND    xwp.sales_outlets_code         = hca_sale.account_number(+)
      AND    xwp.acct_code                  = xav.flex_value(+)
      AND    xwp.acct_code                  = xsav.parent_flex_value_low(+)
      AND    xwp.sub_acct_code              = xsav.flex_value(+)
      AND    xwp.sub_acct_code             IS NOT NULL                     -- �⏕�Ȗڂ��ݒ肳��Ă郌�R�[�h�̂�
      AND    xwp.acct_code || cv_hyphen || xwp.sub_acct_code
                                            = flvv_act.lookup_code(+)      -- �⏕�ȖڃR�[�h
      AND    flvv_act.lookup_type(+)        = cv_lookup_sub_acct_tax       -- �Q�ƃ^�C�v
      AND    flvv_act.enabled_flag(+)       = cv_yes
      AND    flvv_act.start_date_active(+) <= id_b_month
      AND    NVL(flvv_act.end_date_active(+), id_b_month)
                                           >= id_b_month
      AND    flvv_act.description           = flvv_tax.lookup_code(+)
      AND    flvv_tax.lookup_type(+)        = cv_lookup_tax_code           -- �Q�ƃ^�C�v
      AND    flvv_tax.enabled_flag(+)       = cv_yes
      AND    flvv_tax.start_date_active(+) <= id_b_month
      AND    NVL(flvv_tax.end_date_active(+), id_b_month)
                                           >= id_b_month
      AND    flvv_tax.lookup_code           = flvv_his.tag(+)
      AND    flvv_his.lookup_type(+)        = cv_lookup_tax_code_his       -- �Q�ƃ^�C�v
      AND    flvv_his.enabled_flag(+)       = cv_yes
      AND    flvv_his.start_date_active(+) <= id_b_month
      AND    NVL(flvv_his.end_date_active(+), id_b_month)
                                           >= id_b_month
      GROUP BY
             xwp.expect_payment_date                             -- �x���\���
           , xwp.supplier_code                                   -- �d����R�[�h
           , xwp.bill_no                                         -- ������No
           , xwp.base_code                                       -- ���_�R�[�h
           , hca_base.account_name                               -- ���_��
           , xwp.cust_code                                       -- �ڋq�R�[�h
           , hca_cust.account_name                               -- �ڋq��
           , xwp.sales_outlets_code                              -- �≮������R�[�h
           , hca_sale.account_name                               -- �≮�����於��
           , xwp.acct_code                                       -- ����ȖڃR�[�h
           , xav.description                                     -- ����Ȗږ���
           , xwp.sub_acct_code                                   -- �⏕�ȖڃR�[�h
           , xsav.description                                    -- �⏕�Ȗږ���
           , flvv_his.attribute2                                 -- �ŃR�[�h
           , flvv_his.attribute1                                 -- ����ŗ�
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
      ORDER BY
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
--             xwp.expect_payment_date                             -- �x���\���
--           , xwp.supplier_code                                   -- �d����R�[�h
--           , xwp.bill_no                                         -- ������No
--           , xwp.base_code                                       -- ���_�R�[�h
--           , xwp.cust_code                                       -- �ڋq�R�[�h
--           , xwp.sales_outlets_code                              -- �≮������R�[�h
--           , xwp.acct_code                                       -- ����ȖڃR�[�h
--           , xwp.sub_acct_code                                   -- �⏕�ȖڃR�[�h
             expect_payment_date                                 -- �x���\���
           , supplier_code                                       -- �d����R�[�h
           , bill_no                                             -- ������No
           , base_code                                           -- ���_�R�[�h
           , cust_code                                           -- �ڋq�R�[�h
           , sales_outlets_code                                  -- �≮������R�[�h
           , acct_code                                           -- ����ȖڃR�[�h
           , sub_acct_code                                       -- �⏕�ȖڃR�[�h
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
      ;
--
    -- ===============================================
    -- ���[�J���e�[�u���^
    -- ===============================================
    TYPE l_column_name_ttype IS TABLE OF get_column_name_cur%ROWTYPE
    INDEX BY BINARY_INTEGER;
    TYPE l_cdv_data_ttype IS TABLE OF get_csv_data_cur%ROWTYPE
    INDEX BY BINARY_INTEGER;
    -- ===============================================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================================
    lt_column_name_tab     l_column_name_ttype;             -- CSV�o�͍��ږ��̊i�[
    lt_csv_data_tab        l_cdv_data_ttype;                -- CSV�o�̓f�[�^�i�[
    lv_step                VARCHAR2(100);
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �o�͍��ږ��̂��o��
    -- ===============================================
    IF ( gb_outfile_first_flag = TRUE ) THEN
      -- �N�C�b�N�R�[�h���獀�ږ��̂��擾
      OPEN get_column_name_cur;
      FETCH get_column_name_cur BULK COLLECT INTO lt_column_name_tab;
      CLOSE get_column_name_cur;
      -- CSV�t�@�C���ɏ�������
      <<output_csv_column_loop>>
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR START
--      FOR i IN lt_column_name_tab.FIRST .. lt_column_name_tab.LAST LOOP
      FOR i IN 1 .. lt_column_name_tab.COUNT LOOP
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR END
        -- �o�͍s�쐬
        IF ( i != lt_column_name_tab.COUNT ) THEN
          lv_csv_line := lv_csv_line || lt_column_name_tab( i ).column_name || ',';
        ELSE
          lv_csv_line := lv_csv_line || lt_column_name_tab( i ).column_name;
        END IF;
      END LOOP output_csv_column_loop;
      -- �t�@�C���o��
      FND_FILE.PUT_LINE(
        FND_FILE.OUTPUT
      , lv_csv_line
      );
      -- ����t���O��FALSE�����B
      gb_outfile_first_flag := FALSE;
    END IF;
    -- ===============================================
    -- �Ώۃf�[�^�t�@�C���o��
    -- ===============================================
    -- �Ώۃf�[�^�擾
    OPEN get_csv_data_cur(
           id_payment_date   => ir_haed_data_rec.expect_payment_date      -- �x���\���
         , iv_selling_month  => ir_haed_data_rec.selling_month            -- ����Ώ۔N��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
         , id_b_month        => TO_DATE(ir_haed_data_rec.selling_month, cv_format_yyyymm)
                                                                          -- ����Ώ۔N���i�������j
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
         , iv_supplier_code  => ir_haed_data_rec.supplier_code            -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
         , iv_base_code      => ir_haed_data_rec.base_code                -- ���_�R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
         );
    FETCH get_csv_data_cur BULK COLLECT INTO lt_csv_data_tab;
    CLOSE get_csv_data_cur;
    -- CSV�t�@�C���ɏ�������
    <<output_csv_data_loop>>
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR START
--    FOR j IN lt_csv_data_tab.FIRST .. lt_csv_data_tab.LAST LOOP
    FOR j IN 1 .. lt_csv_data_tab.COUNT LOOP
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR END
      -- �x���\����𕶎���ɕύX
      lv_payment_date := TO_CHAR( lt_csv_data_tab( j ).expect_payment_date , 'YYYY/MM/DD' );
      -- �x�����z(�Ŕ�)�ɐł����Z
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
--      ln_payment_amt  := lt_csv_data_tab( j ).payment_amt + ( lt_csv_data_tab( j ).payment_amt * gn_tax_rate );
      ln_payment_amt  := lt_csv_data_tab( j ).payment_amt + ( lt_csv_data_tab( j ).payment_amt * ( lt_csv_data_tab( j ).tax_rate / 100) );
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
      -- �o�͍s�쐬
      lv_step := 'STEP1';
      lv_csv_line := lv_payment_date || ',';                                         -- �x���\���
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).supplier_code || ',';       -- �d����R�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).bill_no || ',';             -- �������ԍ�
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).base_code || ',';           -- ���_�R�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).base_name || ',';           -- ���_����
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).cust_code || ',';           -- �ڋq�R�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).cust_name || ',';           -- �ڋq����
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sales_outlets_code || ',';  -- �≮������R�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sales_outlets_name || ',';  -- �≮������R�[�h����
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).acct_code || ',';           -- ����ȖڃR�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).acct_name || ',';           -- ����Ȗږ���
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sub_acct_code || ',';       -- �⏕�ȖڃR�[�h
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sub_acct_name || ',';       -- �⏕�Ȗږ���
      lv_csv_line := lv_csv_line || TO_CHAR( ln_payment_amt );                       -- �x�����z(�ō�)
      -- �t�@�C���o��
      FND_FILE.PUT_LINE(
        FND_FILE.OUTPUT
      , lv_csv_line
      );
    END LOOP output_csv_data_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END create_csv;
--
  /************************************************************************
   * Procedure Name  : change_status
   * Description     : �A�g�X�e�[�^�X�X�V(A-7)
   ************************************************************************/
  PROCEDURE change_status(
    ov_errbuf         OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode        OUT VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg         OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_head_data_rec  IN  g_sell_haeder_cur%ROWTYPE  -- AP������OIF�w�b�_�[���
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD START
  , iv_invoice_num    IN  VARCHAR2                   -- �������ԍ�
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'change_status';        -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���O�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- �≮���������׃e�[�u���̃��b�N�m�F
    CURSOR wholesale_bill_chk(
      id_payment_date   IN  DATE                   -- �x���\���
    , iv_selling_month  IN  VARCHAR2               -- ����Ώ۔N��
    , iv_supplier_code  IN  VARCHAR2               -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN  VARCHAR2               -- ���_�R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
    )
    IS
      SELECT 'X'
      FROM   xxcok_wholesale_bill_line        xwbl      -- �≮���������׃e�[�u��
      WHERE  EXISTS (
               SELECT 'X'
               FROM   xxcok_wholesale_payment xwp       -- �≮�x���e�[�u��
               WHERE  xwp.wholesale_bill_detail_id = xwbl.wholesale_bill_detail_id
               AND    xwp.expect_payment_date      = id_payment_date
               AND    xwp.selling_month            = iv_selling_month
               AND    xwp.supplier_code            = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
               AND    xwp.base_code                = iv_base_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
               AND    xwp.ap_interface_status      = cv_payment_uncooperate  -- AP�A�g�X�e�[�^�X�F'0'���A�g
             )
    FOR UPDATE NOWAIT;
    -- �≮�x���e�[�u���̃��b�N�m�F
    CURSOR wholesale_payment_chk(
      id_payment_date   IN  DATE                   -- �x���\���
    , iv_selling_month  IN  VARCHAR2               -- ����Ώ۔N��
    , iv_supplier_code  IN  VARCHAR2               -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN  VARCHAR2               -- ���_�R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
    )
    IS
       SELECT 'X'
       FROM   xxcok_wholesale_payment xwp          -- �≮�x���e�[�u��
       WHERE  xwp.expect_payment_date      = id_payment_date
       AND    xwp.selling_month            = iv_selling_month
       AND    xwp.supplier_code            = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
       AND    xwp.base_code                = iv_base_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
       AND    xwp.ap_interface_status      = cv_payment_uncooperate          -- AP�A�g�X�e�[�^�X�F'0'���A�g
     FOR UPDATE NOWAIT;
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    update_err_expt    EXCEPTION;                 -- �X�e�[�^�X�X�V�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �≮���������׃e�[�u���̃X�e�[�^�X�X�V
    -- ===============================================
    BEGIN
      -- ���b�N�m�F
      OPEN wholesale_bill_chk(
        id_payment_date   => ir_head_data_rec.expect_payment_date  -- �x���\���
      , iv_selling_month  => ir_head_data_rec.selling_month        -- ����Ώ۔N��
      , iv_supplier_code  => ir_head_data_rec.supplier_code        -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
      , iv_base_code      => ir_head_data_rec.base_code            -- ���_�R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
      );
      -- �J�[�\���N���[�Y
      CLOSE wholesale_bill_chk;
      -- �X�e�[�^�X�X�V
      BEGIN
        UPDATE xxcok_wholesale_bill_line xwbl                           -- �≮���������׃e�[�u��
        SET    xwbl.status            = cv_bill_cooperate               -- �X�e�[�^�X�F�X�V��
             , xwbl.last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
             , xwbl.last_update_date       = SYSDATE                    -- �ŏI�X�V��
             , xwbl.last_update_login      = cn_last_update_login       -- �ŏI���O�C��ID
             , xwbl.request_id             = cn_request_id              -- ���N�G�X�gID
             , xwbl.program_application_id = cn_program_application_id  -- �v���O�����A�v���P�[�V����ID
             , xwbl.program_id             = cn_program_id              -- �v���O����ID
             , xwbl.program_update_date    = SYSDATE                    -- �v���O�����ŏI�X�V��
        WHERE  EXISTS (
                 SELECT 'X'
                 FROM   xxcok_wholesale_payment        xwp                                -- �≮�x���e�[�u��
                 WHERE  xwp.wholesale_bill_detail_id = xwbl.wholesale_bill_detail_id      -- �≮��������ID
                 AND    xwp.expect_payment_date      = ir_head_data_rec.expect_payment_date
                 AND    xwp.selling_month            = ir_head_data_rec.selling_month
                 AND    xwp.supplier_code            = ir_head_data_rec.supplier_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
                 AND    xwp.base_code                = ir_head_data_rec.base_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
                 AND    xwp.ap_interface_status      = cv_payment_uncooperate             -- AP�A�g�X�e�[�^�X�F���A�g
               );
      EXCEPTION
        -- *** �X�V���G���[ ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10196
                        , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- �x����R�[�h
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                        , iv_token_value4 => ir_head_data_rec.base_code
                        );
          -- �X�V�Ɏ��s�����ꍇ�A�X�e�[�^�X���G���[�ɂ��ĕԂ��B
          lv_retcode := cv_status_error;
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
          RAISE update_err_expt;
      END;
--
    EXCEPTION
      -- *** ���b�N�擾�G���[ ***
      WHEN global_lock_fail_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10195
                      , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- �x����R�[�h
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- ���b�N�G���[�̏ꍇ�A�x����Ԃ��B
        lv_retcode := cv_status_warn;
        lv_errbuf  := NULL;
        RAISE update_err_expt;
    END;
    -- ===============================================
    -- �≮�x���e�[�u���̃X�e�[�^�X�X�V
    -- ===============================================
    BEGIN
      -- ���b�N�m�F
      OPEN wholesale_payment_chk(
        id_payment_date   => ir_head_data_rec.expect_payment_date  -- �x���\���
      , iv_selling_month  => ir_head_data_rec.selling_month        -- ����Ώ۔N��
      , iv_supplier_code  => ir_head_data_rec.supplier_code        -- �d����R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
      , iv_base_code      => ir_head_data_rec.base_code            -- ���_�R�[�h
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
      );
      -- �J�[�\���N���[�Y
      CLOSE wholesale_payment_chk;
      -- �X�e�[�^�X�X�V
      BEGIN
        UPDATE xxcok_wholesale_payment                                     -- �≮�x���e�[�u��
        SET    ap_interface_status    = cv_payment_cooperate               -- AP�A�g�X�e�[�^�X�F�X�V��
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD START
             , invoice_num            = iv_invoice_num                     -- �������ԍ�
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD END
             , last_updated_by        = cn_last_updated_by                 -- �ŏI�X�V��
             , last_update_date       = SYSDATE                            -- �ŏI�X�V��
             , last_update_login      = cn_last_update_login               -- �ŏI���O�C��ID
             , request_id             = cn_request_id                      -- ���N�G�X�gID
             , program_application_id = cn_program_application_id          -- �v���O�����A�v���P�[�V����ID
             , program_id             = cn_program_id                      -- �v���O����ID
             , program_update_date    = SYSDATE                            -- �v���O�����ŏI�X�V��
        WHERE  expect_payment_date    = ir_head_data_rec.expect_payment_date
        AND    selling_month          = ir_head_data_rec.selling_month
        AND    supplier_code          = ir_head_data_rec.supplier_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD START
        AND    base_code              = ir_head_data_rec.base_code
-- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi ADD END
        AND    ap_interface_status    = cv_payment_uncooperate;            -- AP�A�g�X�e�[�^�X�F���A�g
--
      EXCEPTION
        -- *** �X�V���G���[ ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10198
                        , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- �d����R�[�h
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                        , iv_token_value4 => ir_head_data_rec.base_code
                        );
          -- �X�V�Ɏ��s�����ꍇ�A�X�e�[�^�X���G���[�ɂ��ĕԂ��B
          lv_retcode := cv_status_error;
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
          RAISE update_err_expt;
      END;
--
    EXCEPTION
      -- *** ���b�N�擾�G���[ ***
      WHEN global_lock_fail_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10197
                      , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                      , iv_token_value1 => TO_CHAR( TRUNC( ir_head_data_rec.expect_payment_date ), 'YYYY/MM/DD')
                      , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- �d����R�[�h
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- ���b�N�G���[�̏ꍇ�A�x����Ԃ��B
        lv_retcode := cv_status_warn;
        lv_errbuf  := NULL;
        RAISE update_err_expt;
    END;
--
  EXCEPTION
    -- *** �X�e�[�^�X�X�V�G���[ ***
    WHEN update_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END change_status;
--
  /************************************************************************
   * Procedure Name  : amount_chk
   * Description     : ���z�`�F�b�N(A-6)
   ************************************************************************/
  PROCEDURE amount_chk(
    ov_errbuf        OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_head_data_rec IN  g_sell_haeder_cur%ROWTYPE  -- AP������OIF�w�b�_�[
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'amount_chk';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;
    ln_current_seq         NUMBER         DEFAULT NULL;             -- �V�[�P���X���ݒl�擾
    ln_get_row             NUMBER         DEFAULT NULL;             -- ROWNUM�擾�p
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ���݂̃V�[�P���X���擾
    -- ===============================================
    SELECT ap_invoices_interface_s.CURRVAL  -- ���O�ɍ쐬�����w�b�_�[ID
    INTO   ln_current_seq
    FROM   dual;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    -- ===============================================
    -- �w�b�_�[�̐������z�Ɛ������^�C�v�̍X�V
    -- �������z���[���ȏ�̏ꍇ�A�W��            �uSTANDARD�v
    -- �������z���}�C�i�X�̏ꍇ�A�N���W�b�g�E�����uCREDIT�v
    -- ===============================================
    UPDATE ap_invoices_interface  aii
    SET    (aii.invoice_amount, aii.invoice_type_lookup_code) = (SELECT SUM(aili.amount)
                                                                       ,CASE
                                                                          WHEN SUM(aili.amount) >= 0 THEN
                                                                            cv_invoice_type_standard
                                                                          WHEN SUM(aili.amount) <  0 THEN
                                                                            cv_invoice_type_credit
                                                                        END
                                                                 FROM   ap_invoice_lines_interface aili
                                                                 WHERE  aili.invoice_id = aii.invoice_id)
    WHERE  aii.invoice_id = ln_current_seq;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    -- ===============================================
    -- ���z�`�F�b�N
    -- ===============================================
    BEGIN
      SELECT ROWNUM
      INTO   ln_get_row
      FROM   (
               SELECT SUM( aili.amount )       AS amount  -- ���׋��z���v
               FROM   ap_invoice_lines_interface  aili    -- AP����������OIF�e�[�u��
               WHERE  aili.invoice_id = ln_current_seq    -- ���O�ɍ쐬�����w�b�_�[ID
             ) detail_amount
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
            ,ap_invoices_interface  aii
--      WHERE  detail_amount.amount = gn_header_amt;     -- �x�����z
      WHERE  detail_amount.amount = aii.invoice_amount
      AND    aii.invoice_id       = ln_current_seq;       -- �x�����z
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
--
    EXCEPTION
      -- *** �f�[�^���擾����Ȃ��ꍇ ***
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10194
                      , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- �d����R�[�h
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- ���^�[���R�[�h���x���ɂ��ĕԂ��B
        ov_retcode := cv_status_warn;
        ov_errbuf  := NULL;
        ov_errmsg  := lv_errmsg;
    END;
-- 
  EXCEPTION
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END amount_chk;
--
  /************************************************************************
   * Procedure Name  : create_detail_tax
   * Description     : AP����������OIF�o�^(A-5) ����Ń��R�[�h�}��
   ************************************************************************/
  PROCEDURE create_detail_tax(
    ov_errbuf          OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_head_data_rec   IN  g_sell_haeder_cur%ROWTYPE  -- AP������OIF�w�b�_�[���
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
  , in_sum_payment_amount IN NUMBER
  , in_tax_rate           IN NUMBER
  , iv_tax_code           VARCHAR2
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'create_detail_tax';    -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    -- �����
    ln_tax                 NUMBER         DEFAULT 0;
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    create_data_err_expt   EXCEPTION;                               -- �f�[�^�쐬�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �ŋ��v�Z(�[���؎̂�)
    -- ===============================================
    ln_tax := TRUNC(
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
--                ir_head_data_rec.payment_amt * gn_tax_rate
                in_sum_payment_amount * ( in_tax_rate / 100)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
              , 0
              );
    -- ===============================================
    -- ����ő}��
    -- ===============================================
    BEGIN
      INSERT INTO ap_invoice_lines_interface (
        invoice_id                            -- ������ID
      , invoice_line_id                       -- ����������ID
      , line_number                           -- ���׍s�ԍ�
      , line_type_lookup_code                 -- ���׃^�C�v
      , amount                                -- ���׋��z
      , tax_code                              -- �ŋ敪
      , dist_code_combination_id              -- CCID
      , last_updated_by                       -- �ŏI�X�V��
      , last_update_date                      -- �ŏI�X�V��
      , last_update_login                     -- �ŏI���O�C��ID
      , created_by                            -- �쐬��
      , creation_date                         -- �쐬��
      , attribute_category                    -- DFF�R���e�L�X�g
      , org_id                                -- �g�DID
      )
      VALUES (
        ap_invoices_interface_s.CURRVAL       -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
      , ap_invoice_lines_interface_s.NEXTVAL  -- AP������OIF���ׂ̈��ID
      , gn_detail_num                         -- �w�b�_�[���ł̘A��
      , gv_prof_detail_type_tax               -- ���׃^�C�v�F�ŋ�
      , ln_tax                                -- ���z�F�ŋ�
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
----      , gv_prof_invoice_tax_code              -- �������ŃR�[�h
--      , gv_tax_code                           -- �������ŃR�[�h
      , iv_tax_code
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
      , gn_tax_ccid                           -- ���������CCID
      , cn_last_updated_by                    -- �ŏI�X�V��
      , SYSDATE                               -- �ŏI�X�V��
      , cn_last_update_login                  -- �ŏI���O�C��ID
      , cn_created_by                         -- �쐬��
      , SYSDATE                               -- �쐬��
      , gv_prof_org_id                        -- DFF�R���e�L�X�g�F�g�DID
      , TO_NUMBER( gv_prof_org_id )           -- �g�DID
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10407
                      , iv_token_name1  => cv_token_payment_date                     -- �x���\���
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                      -- ����Ώ۔N��
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                      -- �x����R�[�h
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                        -- ���_�R�[�h
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        RAISE create_data_err_expt;
    END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      gn_detail_num := gn_detail_num + 1;
--
  EXCEPTION
    -- *** �f�[�^�쐬�G���[ ***
    WHEN create_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_detail_tax;
--
  /************************************************************************
   * Procedure Name  : create_detail_data
   * Description     : AP����������OIF(A-5) �ňȊO
   ************************************************************************/
  PROCEDURE create_detail_data(
    ov_errbuf          OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_detail_data_rec IN  g_sell_detail_cur%ROWTYPE  -- AP������OIF���׏��
  , ir_head_data_rec   IN  g_sell_haeder_cur%ROWTYPE  -- AP������OIF�w�b�_�[���
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'create_detail_data';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���O�t�@�C���o�͎����^�[���R�[�h
    lv_company_code        VARCHAR2(20)   DEFAULT NULL;             -- ��ƃR�[�h
    ln_backmargin_ccid     NUMBER         DEFAULT NULL;             -- �̔��萔��CCID
    ln_support_amt_ccid    NUMBER         DEFAULT NULL;             -- �̔����^��CCID
    ln_misc_acct_amt_ccid  NUMBER         DEFAULT NULL;             -- ���̑��Ȗ�CCID
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    create_data_err_expt   EXCEPTION;                               -- �f�[�^�쐬�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��ƃR�[�h�쐬(�擾������ƃR�[�h��NULL�̏ꍇ�A�_�~�[������)
    -- ===============================================
    lv_company_code := NVL(
                         xxcok_common_pkg.get_companies_code_f(
                           ir_detail_data_rec.sales_outlets_code
                         )
                       , gv_prof_company_dummy 
                       );
    -- ===============================================
    -- �u�̔��萔���v���׍쐬
    -- ===============================================
    IF ( ir_detail_data_rec.backmargin <> 0 ) THEN
      -- �̔��萔��CCID�擾
      ln_backmargin_ccid := xxcok_common_pkg.get_code_combination_id_f(
                              id_proc_date => gd_prof_process_date         -- ������
                            , iv_segment1  => gv_prof_company_code         -- ��ЃR�[�h
                            , iv_segment2  => ir_head_data_rec.base_code   -- ����R�[�h
                            , iv_segment3  => gv_prof_acct_sell_fee        -- ����ȖڃR�[�h
                            , iv_segment4  => gv_prof_asst_sell_fee        -- �⏕�ȖڃR�[�h
                            , iv_segment5  => ir_detail_data_rec.cust_code -- �ڋq�R�[�h
                            , iv_segment6  => lv_company_code              -- ��ƃR�[�h
                            , iv_segment7  => gv_prof_pre1_dummy           -- �\���P�R�[�h
                            , iv_segment8  => gv_prof_pre2_dummy           -- �\���Q�R�[�h
                            );
      IF ( ln_backmargin_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- �u�̔��萔���v�}��
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- ������ID
        , invoice_line_id                                   -- ����������ID
        , line_number                                       -- ���׍s�ԍ�
        , line_type_lookup_code                             -- ���׃^�C�v
        , amount                                            -- ���׋��z
        , tax_code                                          -- �ŋ敪
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
        , gn_detail_num                                     -- �w�b�_�[���ł̘A��
        , gv_prof_detail_type_item                          -- ���׃^�C�v�F����
        , ir_detail_data_rec.backmargin                     -- ���z�F�̔��萔��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
----        , gv_prof_invoice_tax_code                          -- �������ŃR�[�h
--        , gv_tax_code                                       -- �������ŃR�[�h
        , ir_detail_data_rec.tax_code                       -- �������ŃR�[�h
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
        , ln_backmargin_ccid                                -- �̔��萔��CCID
        , cn_last_updated_by                                -- �ŏI�X�V��
        , SYSDATE                                           -- �ŏI�X�V��
        , cn_last_update_login                              -- �ŏI���O�C��ID
        , cn_created_by                                     -- �쐬��
        , SYSDATE                                           -- �쐬��
        , gv_prof_org_id                                    -- DFF�R���e�L�X�g�F�g�DID
        , TO_NUMBER( gv_prof_org_id )                       -- �g�DID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10191
                        , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- �x����R�[�h
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- �ڋq�R�[�h
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- �≮������R�[�h
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                        );
          RAISE create_data_err_expt;
      END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      gn_detail_num := gn_detail_num + 1;
    END IF;
    -- ===============================================
    -- �u�̔����^���v���׍쐬
    -- ===============================================
    IF ( ir_detail_data_rec.sales_support_amt <> 0 ) THEN
      -- �̔����^��CCID�擾
      ln_support_amt_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_prof_process_date             -- ������
                             , iv_segment1  => gv_prof_company_code             -- ��ЃR�[�h
                             , iv_segment2  => ir_head_data_rec.base_code       -- ����R�[�h
                             , iv_segment3  => gv_prof_acct_sell_support        -- ����ȖڃR�[�h(�̔����^��)
                             , iv_segment4  => gv_prof_asst_sell_support        -- �⏕�ȖڃR�[�h(�g����)
                             , iv_segment5  => ir_detail_data_rec.cust_code     -- �ڋq�R�[�h
                             , iv_segment6  => lv_company_code                  -- ��ƃR�[�h
                             , iv_segment7  => gv_prof_pre1_dummy               -- �\���P�R�[�h
                             , iv_segment8  => gv_prof_pre2_dummy               -- �\���Q�R�[�h
                             );
      IF ( ln_support_amt_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- �u�̔����^���v���ב}��
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- ������ID
        , invoice_line_id                                   -- ����������ID
        , line_number                                       -- ���׍s�ԍ�
        , line_type_lookup_code                             -- ���׃^�C�v
        , amount                                            -- ���׋��z
        , tax_code                                          -- �ŋ敪
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
        , gn_detail_num                                     -- �w�b�_�[���ł̘A��
        , gv_prof_detail_type_item                          -- ���׃^�C�v�F����
        , ir_detail_data_rec.sales_support_amt              -- ���z�F�̔����^��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
----        , gv_prof_invoice_tax_code                          -- �������ŃR�[�h
--        , gv_tax_code                                       -- �������ŃR�[�h
        , ir_detail_data_rec.tax_code                       -- �������ŃR�[�h
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
        , ln_support_amt_ccid                               -- �̔��萔��CCID
        , cn_last_updated_by                                -- �ŏI�X�V��
        , SYSDATE                                           -- �ŏI�X�V��
        , cn_last_update_login                              -- �ŏI���O�C��ID
        , cn_created_by                                     -- �쐬��
        , SYSDATE                                           -- �쐬��
        , gv_prof_org_id                                    -- DFF�R���e�L�X�g�F�g�DID
        , TO_NUMBER( gv_prof_org_id )                       -- �g�DID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10192
                        , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- �x����R�[�h
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- �ڋq�R�[�h
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- �≮������R�[�h
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                          );
          RAISE create_data_err_expt;
      END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      gn_detail_num := gn_detail_num + 1;
    END IF;
    -- ===============================================
    -- �u���̑��Ȗځv���׍쐬
    -- ===============================================
    IF ( ir_detail_data_rec.misc_acct_amt <> 0 ) THEN
      -- ���̑��Ȗ�CCID�擾
      ln_misc_acct_amt_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_prof_process_date             -- ������
                             , iv_segment1  => gv_prof_company_code             -- ��ЃR�[�h
                             , iv_segment2  => ir_head_data_rec.base_code       -- ����R�[�h
                             , iv_segment3  => ir_detail_data_rec.acct_code     -- ����ȖڃR�[�h
                             , iv_segment4  => ir_detail_data_rec.sub_acct_code -- �⏕�ȖڃR�[�h
                             , iv_segment5  => ir_detail_data_rec.cust_code     -- �ڋq�R�[�h
                             , iv_segment6  => lv_company_code                  -- ��ƃR�[�h
                             , iv_segment7  => gv_prof_pre1_dummy               -- �\���P�R�[�h
                             , iv_segment8  => gv_prof_pre2_dummy               -- �\���Q�R�[�h
                             );
      IF ( ln_misc_acct_amt_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- �u���̑��Ȗځv���ב}��
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                          -- ������ID
        , invoice_line_id                                     -- ����������ID
        , line_number                                         -- ���׍s�ԍ�
        , line_type_lookup_code                               -- ���׃^�C�v
        , amount                                              -- ���׋��z
        , tax_code                                            -- �ŋ敪
        , dist_code_combination_id                            -- CCID
        , last_updated_by                                     -- �ŏI�X�V��
        , last_update_date                                    -- �ŏI�X�V��
        , last_update_login                                   -- �ŏI���O�C��ID
        , created_by                                          -- �쐬��
        , creation_date                                       -- �쐬��
        , attribute_category                                  -- DFF�R���e�L�X�g
        , org_id                                              -- �g�DID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                     -- ���O�ɍ쐬����AP������OIF�w�b�_�[�̐���ID
        , ap_invoice_lines_interface_s.NEXTVAL                -- AP������OIF���ׂ̈��ID
        , gn_detail_num                                       -- �w�b�_�[���ł̘A��
        , gv_prof_detail_type_item                            -- ���׃^�C�v�F����
        , ir_detail_data_rec.misc_acct_amt                    -- ���z�F���̑����z
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
----        , gv_prof_invoice_tax_code                            -- �������ŃR�[�h
--        , gv_tax_code                                         -- �������ŃR�[�h
        , ir_detail_data_rec.tax_code                         -- �������ŃR�[�h
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
        , ln_misc_acct_amt_ccid                               -- �̔��萔��CCID
        , cn_last_updated_by                                  -- �ŏI�X�V��
        , SYSDATE                                             -- �ŏI�X�V��
        , cn_last_update_login                                -- �ŏI���O�C��ID
        , cn_created_by                                       -- �쐬��
        , SYSDATE                                             -- �쐬��
        , gv_prof_org_id                                      -- DFF�R���e�L�X�g�F�g�DID
        , TO_NUMBER( gv_prof_org_id )                         -- �g�DID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10193
                        , iv_token_name1  => cv_token_payment_date                   -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- �x����R�[�h
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- ���_�R�[�h
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- �ڋq�R�[�h
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- �≮������R�[�h
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                        , iv_token_name7  => cv_token_acct_code                      -- ����ȖڃR�[�h
                        , iv_token_value7 => ir_detail_data_rec.acct_code
                        , iv_token_name8  => cv_token_assist_code                    -- �⏕�ȖڃR�[�h
                        , iv_token_value8 => ir_detail_data_rec.sub_acct_code
                          );
          RAISE create_data_err_expt;
      END;
      -- ����ɍ쐬���ꂽ�ꍇ�A�w�b�_�[�����טA�Ԃ��J�E���g�A�b�v
      gn_detail_num := gn_detail_num + 1;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�쐬�G���[ ***
    WHEN create_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_detail_data;
--
  /************************************************************************
   * Procedure Name  : create_oif_data
   * Description     : AP�������w�b�_�[OIF�o�^(A-3)
   ************************************************************************/
  PROCEDURE create_oif_data(
    ov_errbuf              OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
  , ov_retcode             OUT VARCHAR2                   -- ���^�[���E�R�[�h
  , ov_errmsg              OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  , ir_sell_head_data_rec  IN  g_sell_haeder_cur%ROWTYPE  -- AP������OIF�쐬�p�f�[�^���R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'create_oif_data';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode                   BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    lv_invoice_num               VARCHAR2(50)   DEFAULT NULL;             -- �������ԍ��i�[
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD START
--    ld_selling_month_first_date  DATE           DEFAULT NULL;             -- ����Ώ۔N���̏���
    ld_terms_date                DATE           DEFAULT NULL;             -- �x���N�Z��
    ln_due_months_forword        NUMBER         DEFAULT 0;                -- �T�C�g����
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD END
-- ************ 2010/09/21 1.7 M.Watanabe ADD START ************ --
    lt_invoice_type              ap_invoices_interface.invoice_type_lookup_code%TYPE; -- �������^�C�v
-- ************ 2010/09/21 1.7 M.Watanabe ADD END   ************ --
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
    ln_tax_data_cnt              NUMBER         DEFAULT 0;                -- �������ŋ��R�[�h�f�[�^����
    ld_selling_month             DATE           DEFAULT NULL;             -- ����v���(����v����̂P��)
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
    -- ===============================================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================================
    lt_detail_tab                g_sell_detail_ttype;                     -- ���׎擾�J�[�\�����R�[�h�^
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    ap_oif_create_expt           EXCEPTION;                               -- �w�b�_�[�o�^�G���[
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
    invoice_tax_expt             EXCEPTION;                               -- �������ŋ��R�[�h�擾�G���[
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
--
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    lt_before_tax_code           ap_invoice_lines_interface.tax_code%TYPE;
    lt_amount_sum                ap_invoice_lines_interface.amount%TYPE := 0;
    ln_before_tax_rate           NUMBER;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
  BEGIN
    ov_retcode := cv_status_normal;
    -- ���טA�ԏ�����
    gn_detail_num := 1;
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
    -- �T�C�g����������
    ln_due_months_forword := 0;
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
--    -- ����Ŋ֘A���ڏ�����
--    gv_tax_code      := NULL;
--    gn_tax_rate      := NULL;
--    -- ����v�����1�����擾
--    ld_selling_month := TO_DATE( ir_sell_head_data_rec.selling_month, cv_format_yyyymm );
--    -- �������ŋ��R�[�h������ŗ��̎擾
--    <<get_tax_loop>>
--    FOR i IN 1..gt_invoice_tax_tab.LAST LOOP
--      -- �������ŋ��R�[�h��蔄��v�㌎�ɊY������ŃR�[�h�E�ŗ����擾
--      IF (
--              ( ld_selling_month >= NVL( gt_invoice_tax_tab(i).start_date_active, ld_selling_month ) )
--          AND ( ld_selling_month <= NVL( gt_invoice_tax_tab(i).end_date_active, ld_selling_month ) )
--         )
--      THEN
--        -- ����ł̐��l�`�F�b�N
--        BEGIN
--          gn_tax_rate     := TO_NUMBER( gt_invoice_tax_tab(i).tax_rate / 100 ); -- ����ŗ����l�ϊ�
--          gv_tax_code     := gt_invoice_tax_tab(i).tax_code;                    -- ����ŃR�[�h
--          ln_tax_data_cnt := ln_tax_data_cnt + 1;                               -- �f�[�^����
--        EXCEPTION
--          WHEN VALUE_ERROR THEN
--            ln_tax_data_cnt := 0;
--            EXIT;
--        END;
--      END IF;
--    END LOOP get_tax_loop;
--    --�G���[�`�F�b�N(����ŗ����擾�ł��Ȃ��A���������݂���ꍇ�G���[)
--    IF ( ln_tax_data_cnt <> 1 ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00089
--                    , iv_token_name1  => cv_token_payment_date                      -- �x���\���
--                    , iv_token_value1 => TO_CHAR( ir_sell_head_data_rec.expect_payment_date , cv_format_yyyymmdd_sla )
--                    , iv_token_name2  => cv_token_sales_month                       -- ����Ώ۔N��
--                    , iv_token_value2 => TO_CHAR( 
--                        TO_DATE( ir_sell_head_data_rec.selling_month, cv_format_yyyymm_sla ), cv_format_yyyymm_sla )
--                    , iv_token_name3  => cv_token_vender_code                       -- �x����R�[�h
--                    , iv_token_value3 => ir_sell_head_data_rec.supplier_code
--                    , iv_token_name4  => cv_token_base_code                         -- ���_�R�[�h
--                    , iv_token_value4 => ir_sell_head_data_rec.base_code
--                    );
--      gv_invoice_tax_err_flag := cv_yes; --�������ŋ��R�[�h�G���[(�����擾�ׁ̈A�����͌p������)
--    END IF;
---- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
    -- ===============================================
    -- �Z�[�u�|�C���g�ݒ�
    -- ===============================================
    SAVEPOINT before_create_data;
    -- ===============================================
    -- AP������OIF�w�b�_�[�f�[�^�쐬(A-3)
    -- ===============================================
    -- �������ԍ��擾
    lv_invoice_num := xxcok_common_pkg.get_slip_number_f(
                        iv_package_name => cv_pkg_name              -- �p�b�P�[�W��
                      );
    IF ( lv_invoice_num IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10416
                      );
      RAISE ap_oif_create_expt;
    END IF;
    -- �ō��݋��z���v�Z �Ŕ����z�{�Ŕ����z*�ŗ�(�[���؎̂�)
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
--    gn_header_amt := TRUNC(
--                       ir_sell_head_data_rec.payment_amt + ir_sell_head_data_rec.payment_amt * gn_tax_rate
--                     , 0
--                     );
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD START
--    -- ����Ώ۔N���̏������擾
--    ld_selling_month_first_date := TO_DATE(
--                                     ir_sell_head_data_rec.selling_month
--                                   , 'YYYYMM'
--                                   );
--
    -- �x����������x���N�Z�����擾
    IF ( ir_sell_head_data_rec.term_name = gv_prof_inst_term_name ) THEN
      -- �x�����������������̏ꍇ�A�x���N�Z���Ɂu�x���\����v��ݒ�
      ld_terms_date := ir_sell_head_data_rec.expect_payment_date;
    ELSIF ( ir_sell_head_data_rec.term_name = gv_prof_spec_term_name ) THEN
      -- �x���������w�蕥���̏ꍇ�A�x���N�Z���Ɂu�x���\����v��ݒ�
      ld_terms_date := ir_sell_head_data_rec.expect_payment_date;
    ELSE
      -- �x������_�T�C�g�������擾
      ln_due_months_forword := TO_NUMBER( SUBSTRB( ir_sell_head_data_rec.term_name ,7 ,2 ) );
      -- �u�x���\����v����x������_�T�C�g�����������������̌�������ݒ�
      ld_terms_date := ADD_MONTHS( TRUNC( ir_sell_head_data_rec.expect_payment_date ,cv_format_mm ), - ln_due_months_forword );
    END IF;
-- 2012/03/27 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD END
--
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
---- ************ 2010/09/21 1.7 M.Watanabe ADD START ************ --
--    -- �������z�����Ƃɐ������^�C�v�̒l��ݒ肷��B
--    -- �������z���[���ȏ�̏ꍇ�A�W��            �uSTANDARD�v
--    -- �������z���}�C�i�X�̏ꍇ�A�N���W�b�g�E�����uCREDIT�v
--    IF ( gn_header_amt >= 0 ) THEN
--      lt_invoice_type := cv_invoice_type_standard;
--    ELSE
--      lt_invoice_type := cv_invoice_type_credit;
--    END IF;
---- ************ 2010/09/21 1.7 M.Watanabe ADD END   ************ --
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
--
    -- AP������OIF�w�b�_�[�o�^
    BEGIN
      INSERT INTO ap_invoices_interface (
        invoice_id                              -- �V�[�P���X
      , invoice_num                             -- �������ԍ�
      , invoice_type_lookup_code                -- �������̎��
      , invoice_date                            -- �������t
      , vendor_num                              -- �d����ԍ�
      , vendor_site_code                        -- �d����ꏊ�ԍ�
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
      , lv_invoice_num                          -- �������ԍ�(���O�Ŏ擾)
-- ************ 2010/09/21 1.7 M.Watanabe MOD START ************ --
--      , cv_invoice_type_standard                -- ����^�C�v�F�W��(�Œ�)
      , lt_invoice_type                         -- �������^�C�v
-- ************ 2010/09/21 1.7 M.Watanabe MOD END   ************ --
      , gd_prof_process_date                    -- �Ɩ��������t(init�Ŏ擾)
      , ir_sell_head_data_rec.supplier_code     -- �d����R�[�h()
      , ir_sell_head_data_rec.vendor_site_code  -- �d����T�C�g�R�[�h
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
--      , gn_header_amt                           -- �ō��݋��z
      , NULL                                    -- �ō��݋��z
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
      , gv_prof_invoice_source                  -- �������\�[�X(init�Ŏ擾)
      , SYSDATE                                 -- �ŏI�X�V��
      , cn_last_updated_by                      -- �ŏI�X�V��
      , cn_last_update_login                    -- �ŏI���O�C��ID
      , SYSDATE                                 -- �쐬��
      , cn_created_by                           -- �쐬��
      , gv_prof_org_id                          -- �g�DID(init�Ŏ擾)
      , lv_invoice_num                          -- �������ԍ�(���O�Ŏ擾)
      , ir_sell_head_data_rec.base_code         -- ���_�R�[�h
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD START
--      , cn_slip_input_user                      -- �`�[���͎�(���O�C�����[�UID)
      , gt_employee_number                      -- �`�[���͎�(�]�ƈ�No)
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD END
      , gv_prof_invoice_source                  -- �������\�[�X(init�Ŏ擾)
      , gv_prof_pay_group                       -- �x���O���[�v
      , gd_prof_process_date                    -- �Ɩ��������t(init�Ŏ擾)
      , gn_payment_ccid                         -- ������Ȗ�CCID(init�Ŏ擾)
      , TO_NUMBER( gv_prof_org_id )             -- �g�DID(init�Ŏ擾)
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD START
--      , ld_selling_month_first_date             -- ����Ώ۔N���̏���
      , ld_terms_date                           -- �x���N�Z��
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki MOD END
      );
    EXCEPTION
      WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10190
                        , iv_token_name1  => cv_token_payment_date                      -- �x���\���
                        , iv_token_value1 => TO_CHAR( ir_sell_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- ����Ώ۔N��
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_sell_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                       -- �x����R�[�h
                        , iv_token_value3 => ir_sell_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                         -- ���_�R�[�h
                        , iv_token_value4 => ir_sell_head_data_rec.base_code
                        );
          RAISE ap_oif_create_expt;
    END;
    -- ===============================================
    -- �≮�x�����׏W�v���o(A-4)
    -- ===============================================
    OPEN g_sell_detail_cur(
           id_payment_date   => ir_sell_head_data_rec.expect_payment_date   -- �x���\���
         , iv_selling_month  => ir_sell_head_data_rec.selling_month         -- ����Ώ۔N��
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
         , id_b_month        => TO_DATE(ir_sell_head_data_rec.selling_month, cv_format_yyyymm)
                                                                            -- ����Ώ۔N���i�������j
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
         , iv_supplier_code  => ir_sell_head_data_rec.supplier_code         -- �d����R�[�h
         , iv_base_code      => ir_sell_head_data_rec.base_code             -- ���_�R�[�h
         );
    -- �t�F�b�`
    FETCH g_sell_detail_cur BULK COLLECT INTO lt_detail_tab;
    -- �J�[�\���N���[�Y
    CLOSE g_sell_detail_cur;
    -- ===============================================
    -- �擾������ޔ����āA�Ώی����ɉ�����B
    -- ===============================================
    gn_sell_detail_num := lt_detail_tab.COUNT;
    -- �Ώی����ɒǉ�
    gn_target_cnt := gn_target_cnt + gn_sell_detail_num;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
    -- �������ŋ��R�[�h�擾�G���[�̏ꍇ�A�ȍ~�̏����̓X�L�b�v
    IF ( gv_invoice_tax_err_flag = cv_yes ) THEN
      RAISE invoice_tax_expt;
    END IF;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
    -- ===============================================
    -- AP������OIF���דo�^(A-5)
    -- ===============================================
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
    -- ���[�v�J�n
    <<ap_oif_detail_loop>>
    FOR i IN 1 .. lt_detail_tab.COUNT LOOP
--    -- ����Ń��R�[�h�̓o�^
--    create_detail_tax(
--      ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W
--    , ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h
--    , ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
--    , ir_head_data_rec   => ir_sell_head_data_rec  -- AP������OIF�w�b�_�[���
--    );
--    IF ( lv_retcode != cv_status_normal ) THEN
--      RAISE global_api_expt;
--    END IF;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD START
      IF lt_before_tax_code != lt_detail_tab( i ).tax_code THEN
        create_detail_tax(
          ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W
        , ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h
        , ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        , ir_head_data_rec   => ir_sell_head_data_rec  -- AP������OIF�w�b�_�[���
        , in_sum_payment_amount => lt_amount_sum
        , in_tax_rate           => ln_before_tax_rate
        , iv_tax_code           => lt_before_tax_code
        );
        lt_amount_sum := 0;
      END IF;
      lt_before_tax_code := lt_detail_tab( i ).tax_code;
      lt_amount_sum := lt_amount_sum + lt_detail_tab( i ).sum_payment_amt;
      ln_before_tax_rate := lt_detail_tab( i ).tax_rate;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe MOD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
--    -- ���[�v�J�n
--    <<ap_oif_detail_loop>>
---- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR START
----    FOR i IN lt_detail_tab.FIRST .. lt_detail_tab.LAST LOOP
--    FOR i IN 1 .. lt_detail_tab.COUNT LOOP
---- 2009/12/09 Ver.1.6 [E_�{�ғ�_00388] SCS K.Yamaguchi REPAIR END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
    -- �̔��萔���E�̔����^���E���̑��Ȗڃ��R�[�h�̓o�^
      create_detail_data(
        ov_errbuf           => lv_errbuf               -- �G���[�E���b�Z�[�W
      , ov_retcode          => lv_retcode              -- ���^�[���E�R�[�h
      , ov_errmsg           => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      , ir_detail_data_rec  => lt_detail_tab( i )      -- AP������OIF���׏��
      , ir_head_data_rec    => ir_sell_head_data_rec   -- AP������OIF�w�b�_�[���
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
    END LOOP ap_oif_detail_loop;
    
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    create_detail_tax(
        ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W
      , ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h
      , ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
      , ir_head_data_rec   => ir_sell_head_data_rec  -- AP������OIF�w�b�_�[���
      , in_sum_payment_amount => lt_amount_sum
      , in_tax_rate           => ln_before_tax_rate
      , iv_tax_code           => lt_before_tax_code
    );
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END

    -- ===============================================
    -- ���z�`�F�b�N(A-6)
    -- ===============================================
    amount_chk(
      ov_errbuf        => lv_errbuf                         -- �G���[�E���b�Z�[�W
    , ov_retcode       => lv_retcode                        -- ���^�[���E�R�[�h
    , ov_errmsg        => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ir_head_data_rec => ir_sell_head_data_rec             -- AP������OIF�w�b�_�[���
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- �A�g�X�e�[�^�X�X�V(A-7)
    -- ===============================================
    change_status(
      ov_errbuf        => lv_errbuf               -- �G���[�E���b�Z�[�W
    , ov_retcode       => lv_retcode              -- ���^�[���E�R�[�h
    , ov_errmsg        => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ir_head_data_rec => ir_sell_head_data_rec   -- AP������OIF�w�b�_�[���
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD START
    , iv_invoice_num   => lv_invoice_num          -- �������ԍ�
-- 2009/11/25 Ver.1.5 [E_�{�ғ�_00021] SCS K.Yamaguchi ADD END
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- �f�[�^�t�@�C���o��(A-8)
    -- ===============================================
    create_csv(
      ov_errbuf        => lv_errbuf               -- �G���[�E���b�Z�[�W
    , ov_retcode       => lv_retcode              -- ���^�[���E�R�[�h
    , ov_errmsg        => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
    , ir_haed_data_rec => ir_sell_head_data_rec   -- AP������OIF�w�b�_�[���
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** �w�b�_�[�o�^�G���[ ***
    WHEN ap_oif_create_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
    -- *** ����ŗ��擾�G���[ ***
    WHEN invoice_tax_expt THEN
      ov_retcode := lv_retcode;  --�S�f�[�^�`�F�b�N�ׁ̈A�����ł͐���ŕԂ��B
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO before_create_data;
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_oif_data;
--
  /************************************************************************
   * Procedure Name  : init
   * Description     : ��������(A-1)
   ************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'init';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    lb_period_chk          BOOLEAN        DEFAULT NULL;             -- ��v���ԃX�e�[�^�X�`�F�b�N�p
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    ln_cnt                 NUMBER;                                  -- �d���J�E���g�p
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    get_data_err_expt      EXCEPTION;                               -- �v���t�@�C���擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �R���J�����g���̓p�����[�^�̕\��(���̓p�����[�^�Ȃ�)
    -- ===============================================
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90008
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- �o�͋敪
                  , iv_message  => lv_errmsg         -- ���b�Z�[�W
                  , in_new_line => cn_number_1       -- ���s
                  );
    -- ===============================================
    -- �v���t�@�C���̎擾
    -- ===============================================
    -- �v���t�@�C���F��v����ID�̎擾
    gv_prof_books_id := FND_PROFILE.VALUE(
                          cv_prof_books_id
                        );
    IF ( gv_prof_books_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_books_id             -- ��v����ID
                    );
      RAISE get_data_err_expt;
    END IF;
    -- �v���t�@�C���F�g�DID�̎擾
    gv_prof_org_id := FND_PROFILE.VALUE(
                        cv_prof_org_id
                      );
    IF ( gv_prof_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_org_id               -- �g�DID
                    );
      RAISE get_data_err_expt;
    END IF;
    -- �J�X�^���E�v���t�@�C���F��ЃR�[�h�̎擾
    gv_prof_company_code := FND_PROFILE.VALUE(
                              cv_prof_company_code
                            );
    IF ( gv_prof_company_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_company_code         -- ��ЃR�[�h
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F����Ȗ�_�̔��萔���̎擾
    gv_prof_acct_sell_fee := FND_PROFILE.VALUE(
                               cv_prof_acct_sell_fee
                             );
    IF ( gv_prof_acct_sell_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_acct_sell_fee        -- ����Ȗ�_�̔��萔��
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F����Ȗ�_�̔����^���̎擾
    gv_prof_acct_sell_support := FND_PROFILE.VALUE(
                                   cv_prof_acct_sell_support
                                 );
    IF ( gv_prof_acct_sell_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_acct_sell_support    -- ����Ȗ�_�̔����^��
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�⏕�Ȗ�_�̔��萔��_�≮�����̎擾
    gv_prof_asst_sell_fee := FND_PROFILE.VALUE(
                               cv_prof_asst_sell_fee
                             );
    IF ( gv_prof_asst_sell_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_asst_sell_fee        -- �⏕�Ȗ�_�̔��萔��_�≮����
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�⏕�Ȗ�_�̔����^��_�g����̎擾
    gv_prof_asst_sell_support := FND_PROFILE.VALUE(
                                   cv_prof_asst_sell_support
                                 );
    IF ( gv_prof_asst_sell_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_asst_sell_support    -- �⏕�Ȗ�_�̔����^��_�g����
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F���׃^�C�v_���ׂ̎擾
    gv_prof_detail_type_item := FND_PROFILE.VALUE(
                                  cv_prof_detail_type_item
                                );
    IF ( gv_prof_detail_type_item IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_detail_type_item     -- ���׃^�C�v_����
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�������\�[�X�̎擾
    gv_prof_invoice_source := FND_PROFILE.VALUE(
                                cv_prof_invoice_source
                              );
    IF ( gv_prof_invoice_source IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_invoice_source       -- �������\�[�X
                    );
      RAISE get_data_err_expt;
    END IF;    
-- 2009/10/22 Ver.1.4 [��QE_T4_00070] SCS K.Yamaguchi REPAIR START
--    -- �J�X�^���E�v���t�@�C���F�x���O���[�v�̎擾
--    gv_prof_pay_group := FND_PROFILE.VALUE(
--                           cv_prof_pay_group
--                         );
--    IF ( gv_prof_pay_group IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00003
--                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
--                    , iv_token_value1 => cv_prof_pay_group            -- �x���O���[�v
--                    );
--      RAISE get_data_err_expt;
--    END IF;    
    gv_prof_pay_group := NULL;
-- 2009/10/22 Ver.1.4 [��QE_T4_00070] SCS K.Yamaguchi REPAIR END
    -- �J�X�^���E�v���t�@�C���F����Ȗ�_�������̎擾
    gv_prof_acct_payable := FND_PROFILE.VALUE(
                              cv_prof_acct_payable
                            );
    IF ( gv_prof_acct_payable IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_acct_payable         -- ����Ȗ�_������
                    );
      RAISE get_data_err_expt;
    END IF;    
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu DELETE START
--    -- �J�X�^���E�v���t�@�C���F�������ŋ敪�̎擾
--    gv_prof_invoice_tax_code := FND_PROFILE.VALUE(
--                                  cv_prof_invoice_tax_code
--                                );
--    IF ( gv_prof_invoice_tax_code IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00003
--                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
--                    , iv_token_value1 => cv_prof_invoice_tax_code     -- �������ŋ敪
--                    );
--      RAISE get_data_err_expt;
--    END IF;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu DELETE END
    -- �J�X�^���E�v���t�@�C���F����R�[�h_�����o�����̎擾
    gv_prof_dept_fin := FND_PROFILE.VALUE(
                          cv_prof_dept_fin
                        );
    IF ( gv_prof_dept_fin IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_dept_fin             -- ����R�[�h_�����o����
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�⏕�Ȗ�_�_�~�[�l�̎擾
    gv_prof_asst_dummy := FND_PROFILE.VALUE(
                            cv_prof_asst_dummy
                          );
    IF ( gv_prof_asst_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_asst_dummy           -- �⏕�Ȗ�_�_�~�[�l
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�ڋq�R�[�h_�_�~�[�l�̎擾
    gv_prof_customer_dummy := FND_PROFILE.VALUE(
                                cv_prof_customer_dummy
                              );
    IF ( gv_prof_customer_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_customer_dummy       -- �ڋq�R�[�h_�_�~�[�l
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F��ƃR�[�h_�_�~�[�l�̎擾
    gv_prof_company_dummy := FND_PROFILE.VALUE(
                               cv_prof_company_dummy
                             );
    IF ( gv_prof_company_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_company_dummy        -- ��ƃR�[�h_�_�~�[�l
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�\��1_�_�~�[�l�̎擾
    gv_prof_pre1_dummy := FND_PROFILE.VALUE(
                            cv_prof_pre1_dummy
                          );
    IF ( gv_prof_pre1_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_pre1_dummy           -- �\��1_�_�~�[�l
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F�\��2_�_�~�[�l�̎擾
    gv_prof_pre2_dummy := FND_PROFILE.VALUE(
                               cv_prof_pre2_dummy
                             );
    IF ( gv_prof_pre2_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_pre2_dummy           -- �\��2_�_�~�[�l
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���F����Ȗ�_��������œ��̎擾
    gv_prof_acct_excise_tax := FND_PROFILE.VALUE(
                                 cv_prof_acct_excise_tax
                               );
    IF ( gv_prof_acct_excise_tax IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_acct_excise_tax      -- ����Ȗ�_��������œ�
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- �J�X�^���E�v���t�@�C���FOIF���׃^�C�v_�ŋ��̎擾
    gv_prof_detail_type_tax := FND_PROFILE.VALUE(
                                 cv_prof_detail_type_tax
                               );
    IF ( gv_prof_detail_type_tax IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_detail_type_tax      -- OIF���׃^�C�v_�ŋ�
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD START
    -- �J�X�^���E�v���t�@�C���F�x������_���������̎擾
    gv_prof_inst_term_name := FND_PROFILE.VALUE(
                                cv_prof_inst_term_name
                              );
    IF ( gv_prof_inst_term_name IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_inst_term_name       -- �x������_��������
                    );
      RAISE get_data_err_expt;
    END IF;
    -- �J�X�^���E�v���t�@�C���F�x������_�w�蕥���̎擾
    gv_prof_spec_term_name := FND_PROFILE.VALUE(
                                cv_prof_spec_term_name
                              );
    IF ( gv_prof_spec_term_name IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- �v���t�@�C����
                    , iv_token_value1 => cv_prof_spec_term_name       -- �x������_�w�蕥��
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2012/03/22 Ver.1.8 [E_�{�ғ�_08315] SCSK S.Niki ADD END
    -- ===============================================
    -- �Ɩ��������t�̎擾
    -- ===============================================
    gd_prof_process_date := xxccp_common_pkg2.get_process_date;
    -- �߂�l��NULL�̏ꍇ�A�G���[�I������B
    IF ( gd_prof_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- ��v���ԃX�e�[�^�X�̊m�F
    -- ===============================================
    lb_period_chk := xxcok_common_pkg.check_acctg_period_f(
                       in_set_of_books_id         => TO_NUMBER( gv_prof_books_id )   -- ��v����ID
                     , id_proc_date               => gd_prof_process_date            -- ������(�Ώۓ�)
                     , iv_application_short_name  => cv_sqlap_appl_short_name        -- �A�v���P�[�V�����Z�k��
                     );
    -- �I�[�v��(�߂�l��TRUE)�ȊO�̏ꍇ�A�G���[�I������B
    IF ( lb_period_chk = FALSE ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00042
                    , iv_token_name1  => cv_token_proc_date           -- �Ɩ��������t
                    , iv_token_value1 => TO_CHAR( gd_prof_process_date , 'YYYY/MM/DD' )
                    );
                    
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- ����ŗ��̎擾
    -- ===============================================
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
--    BEGIN
--      SELECT ( atc.tax_rate / 100 ) AS tax_rate              -- ( ����ŗ�/100 )
--      INTO   gn_tax_rate
--      FROM   ap_tax_codes              atc                   -- �ŋ��R�[�h
--      WHERE  atc.name            = gv_prof_invoice_tax_code     -- �������ŃR�[�h
--      AND    atc.set_of_books_id = TO_NUMBER(gv_prof_books_id)  -- ��v����ID
--      AND    atc.enabled_flag    = 'Y'
--      AND    atc.start_date     <= TRUNC( gd_prof_process_date )
--      AND    NVL( atc.inactive_date , TRUNC( gd_prof_process_date ) ) >= TRUNC( gd_prof_process_date );
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcok_appl_short_name
--                      , iv_name         => cv_msg_code_00089
--                      );
--        RAISE get_data_err_expt;
--    END;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL START
--   OPEN  g_invoice_tax_cur;
--   FETCH g_invoice_tax_cur BULK COLLECT INTO gt_invoice_tax_tab;
--   CLOSE g_invoice_tax_cur;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
    -- ===============================================
    -- ������CCID�̎擾
    -- ===============================================
    gn_payment_ccid := xxcok_common_pkg.get_code_combination_id_f(
                         id_proc_date => gd_prof_process_date         -- ������
                       , iv_segment1  => gv_prof_company_code         -- ��ЃR�[�h
                       , iv_segment2  => gv_prof_dept_fin             -- ����R�[�h
                       , iv_segment3  => gv_prof_acct_payable         -- ����ȖڃR�[�h
                       , iv_segment4  => gv_prof_asst_dummy           -- �⏕�ȖڃR�[�h
                       , iv_segment5  => gv_prof_customer_dummy       -- �ڋq�R�[�h
                       , iv_segment6  => gv_prof_company_dummy        -- ��ƃR�[�h
                       , iv_segment7  => gv_prof_pre1_dummy           -- �\���P�R�[�h
                       , iv_segment8  => gv_prof_pre2_dummy           -- �\���Q�R�[�h
                       );
    IF ( gn_payment_ccid IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00034
                    );
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- ��������ŉȖ�CCID�̎擾
    -- ===============================================
    gn_tax_ccid := xxcok_common_pkg.get_code_combination_id_f(
                     id_proc_date => gd_prof_process_date         -- ������
                   , iv_segment1  => gv_prof_company_code         -- ��ЃR�[�h
                   , iv_segment2  => gv_prof_dept_fin             -- ����R�[�h
                   , iv_segment3  => gv_prof_acct_excise_tax      -- ����ȖڃR�[�h
                   , iv_segment4  => gv_prof_asst_dummy           -- �⏕�ȖڃR�[�h
                   , iv_segment5  => gv_prof_customer_dummy       -- �ڋq�R�[�h
                   , iv_segment6  => gv_prof_company_dummy        -- ��ƃR�[�h
                   , iv_segment7  => gv_prof_pre1_dummy           -- �\���P�R�[�h
                   , iv_segment8  => gv_prof_pre2_dummy           -- �\���Q�R�[�h
                   );
    IF ( gn_tax_ccid IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00034
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD START
    -- ===============================================
    -- �d��`�[���͎҂̎擾
    -- ===============================================
    BEGIN
      SELECT  papf.employee_number AS employee_number     -- �]�ƈ�No
        INTO  gt_employee_number
        FROM  fnd_user         fu    -- ���[�U�[�}�X�^
            , per_all_people_f papf  -- �]�ƈ��}�X�^
       WHERE  fu.user_id           = fnd_global.user_id
         AND  papf.person_id       = fu.employee_id
         AND  gd_prof_process_date BETWEEN NVL( TRUNC( papf.effective_start_date ), gd_prof_process_date )
                                       AND NVL( TRUNC( papf.effective_end_date   ), gd_prof_process_date )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00005
                      );
        RAISE get_data_err_expt;
    END;
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD END
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    -- ===============================================
    -- �d���f�[�^�`�F�b�N
    -- ===============================================
    SELECT COUNT(1) AS cnt
    INTO   ln_cnt
    FROM   fnd_lookup_values v1
          ,fnd_lookup_values v2
    WHERE  v1.lookup_type            = cv_lookup_tax_code_his
    AND    v2.lookup_type            = cv_lookup_tax_code_his
    AND    v1.enabled_flag           = cv_yes
    AND    v2.enabled_flag           = cv_yes
    AND    ( ( v1.start_date_active >= v2.start_date_active
    AND        v1.start_date_active <= v2.end_date_active )
      OR     ( v1.end_date_active   >= v2.start_date_active
    AND        v1.end_date_active   <= v2.end_date_active ) )
    AND    v1.tag                    = v2.tag
    AND    v1.lookup_code           <> v2.lookup_code
    ;
    -- �d���f�[�^���P���ł�����
    IF (ln_cnt > 0) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10566
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
--
  EXCEPTION
    -- *** �擾�f�[�^�G���[��O ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END init;
--
  /************************************************************************
   * Procedure Name  : submain
   * Description     : ���C�������v���V�[�W��
   ************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'submain';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J���e�[�u���^�ϐ�
    -- ===============================================
    lt_header_tab          g_sell_header_ttype;                     -- �≮�x���w�b�_�[���擾�J�[�\�����R�[�h�^
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
    lt_tax_tab             g_bill_amd_ttype;                        -- �ŗ��擾�J�[�\�����R�[�h�^
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    no_oif_data_expt       EXCEPTION;                               -- �Y���f�[�^0����O
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W
    , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h
    , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- �≮�x���w�b�_�[�W�v���o(A-2)
    -- ===============================================
    OPEN g_sell_haeder_cur(
      in_org_id    => TO_NUMBER( gv_prof_org_id )
    , id_proc_date => gd_prof_process_date
    );
    -- �t�F�b�`
    FETCH g_sell_haeder_cur BULK COLLECT INTO lt_header_tab;
    -- �J�[�\���N���[�Y
    CLOSE g_sell_haeder_cur;
    -- �擾������0���̂Ƃ��A�G���[�I��
    IF ( lt_header_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10189
                    );
      RAISE no_oif_data_expt;
    END IF;
    -- ===============================================
    -- AP������OIF�o�^(A-3, A-4, A-5, A-6, A-7, A-8)
    -- ===============================================
    -- ���[�v����
    <<ap_oif_header_loop>>
    FOR i IN lt_header_tab.FIRST .. lt_header_tab.LAST LOOP
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD START
      -- �ŗ��擾
      OPEN g_tax_cur(
        id_pay_date   =>  lt_header_tab(i).expect_payment_date                      -- �x���\���
       ,iv_sel_month  =>  lt_header_tab(i).selling_month                            -- ����Ώی�
       ,id_b_month    =>  TO_DATE(lt_header_tab(i).selling_month, cv_format_yyyymm) -- ����Ώی��i�������j
       ,iv_sup_code   =>  lt_header_tab(i).supplier_code                            -- �d����R�[�h
       ,iv_base_code  =>  lt_header_tab(i).base_code                                -- ���_�R�[�h
      );
      -- �t�F�b�`
      FETCH g_tax_cur BULK COLLECT INTO lt_tax_tab;
      -- �J�[�\���N���[�Y
      CLOSE g_tax_cur;
      -- �������z������
      gn_bill_amt := 0;
      -- �ŗ��`�F�b�N���[�v
      <<bill_amt_loop>>
      FOR j IN 1 .. lt_tax_tab.COUNT LOOP
        -- �ŗ����ݒ肳��Ă��邩�`�F�b�N
        IF lt_tax_tab(j).tax_rate IS NULL THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10565                      -- ����ŗ��擾���s�G���[���b�Z�[�W
                        , iv_token_name1  => cv_token_year_month                    -- �g�[�N��1
                        , iv_token_value1 => lt_header_tab(i).selling_month         -- ����Ώ۔N��
                        , iv_token_name2  => cv_token_item_code                     -- �g�[�N��2
                        , iv_token_value2 => lt_tax_tab(j).item_code                -- �i�ڃR�[�h
                        , iv_token_name3  => cv_token_acct_code                     -- �g�[�N��3
                        , iv_token_value3 => lt_tax_tab(j).acct_code                -- ����ȖڃR�[�h
                        , iv_token_name4  => cv_token_sub_acct_code                 -- �g�[�N��4
                        , iv_token_value4 => lt_tax_tab(j).sub_acct_code            -- �⏕�ȖڃR�[�h
                        );
          -- �G���[���b�Z�[�W���o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                in_which    => FND_FILE.LOG      -- �o�͋敪
              , iv_message  => lv_errmsg         -- ���b�Z�[�W
              , in_new_line => cn_number_0       -- ���s
              );
          -- �������ŋ��R�[�h�G���[�t���O��ݒ�
          gv_invoice_tax_err_flag := cv_yes;
        END IF;
      END LOOP bill_amt_loop;
--
      -- �ŗ��擾�G���[�̏ꍇ�A�w�b�_�[�̎����R�[�h�փX�L�b�v����
      IF (gv_invoice_tax_err_flag = cv_yes) THEN
        gv_invoice_tax_err_flag := cv_no;
        gn_skip_cnt := gn_skip_cnt + 1;
        CONTINUE;
      END IF;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe ADD END
      create_oif_data(
        ov_errbuf              => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode             => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg              => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      , ir_sell_head_data_rec  => lt_header_tab( i )    -- AP������OIF�쐬�p�f�[�^���R�[�h
      );
      -- ===============================================
      -- �I���X�e�[�^�X�ɂ���āA����������ύX����B
      -- ===============================================
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
--      -- ����I����
--      IF ( lv_retcode = cv_status_normal ) THEN
      -- �������ŋ��R�[�h�擾�G���[��
      IF ( gv_invoice_tax_err_flag = cv_yes ) THEN
        -- ���׌������G���[�����ɒǉ�����B
        gn_invoice_tax_err_cnt  := gn_invoice_tax_err_cnt + gn_sell_detail_num;
        -- �������ŋ��R�[�h�G���[�t���O������
        gv_invoice_tax_err_flag := cv_no;
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
--        -- lv_errmsg�����O�ɏo�͂���B
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      -- �o�͋敪
--                      , iv_message  => lv_errmsg         -- ���b�Z�[�W
--                      , in_new_line => cn_number_0       -- ���s
--                      );
-- 2019/06/14 Ver.1.10 [E_�{�ғ�_15472] SCSK N.Abe DEL END
      ELSIF ( lv_retcode = cv_status_normal ) THEN
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
        -- ���׌����𐳏�I�������ɒǉ�����B
        gn_normal_cnt := gn_normal_cnt + gn_sell_detail_num;
      -- �x���I����
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- ���׌����𐳏�I�������ɒǉ�����B
        gn_skip_cnt   := gn_skip_cnt   + gn_sell_detail_num;
        -- lv_errmsg�����O�ɏo�͂���B
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- �o�͋敪
                      , iv_message  => lv_errmsg         -- ���b�Z�[�W
                      , in_new_line => cn_number_0       -- ���s
                      );
      -- �G���[�I����
      ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD START
        gn_invoice_tax_err_cnt := 0;  --�������ŋ��R�[�h�G���[�ȊO(�V�X�e���G���[)�Ƃ���ׁA������
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu ADD END
        -- ���ʊ֐���O�ɔ��
        RAISE global_api_expt;
      END IF;
    END LOOP ap_oif_header_loop;
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
--    -- �x��(�X�L�b�v)����������0���ȊO�̏ꍇ�A���^�[���R�[�h�Ɍx����������B
--    IF ( gn_skip_cnt != 0 ) THEN
    -- �������ŋ��R�[�h�擾�G���[���������Ă���ꍇ
    IF ( gn_invoice_tax_err_cnt != 0 ) THEN
      ov_retcode := cv_status_error;
    -- �x��(�X�L�b�v)����������0���ȊO�̏ꍇ�A���^�[���R�[�h�Ɍx����������B
    ELSIF ( gn_skip_cnt != 0 ) THEN
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �Y���f�[�^0����O ***
    WHEN no_oif_data_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END submain;
--
  /************************************************************************
   * Procedure Name  : main
   * Description     : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'main';    -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    lv_message_code        VARCHAR2(100)  DEFAULT NULL;             -- �I�����b�Z�[�W�R�[�h�i�[
--
  BEGIN
    retcode := cv_status_normal;
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_errbuf     => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg             -- ���[�U�E�G���[�E���b�Z�[�W
    , iv_which      => cv_which              -- �o�͋敪
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�ďo��
    -- ===============================================
    submain(
      ov_errbuf     => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg             -- ���[�U�E�G���[�E���b�Z�[�W
    );
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
--    -- submain���x���I���̏ꍇ�A�󔒍s��1�s�ǉ�����B
--    If ( lv_retcode = cv_status_warn ) THEN
    -- �������ŋ��R�[�h�G���[���������Ă���ꍇ�A�󔒍s��1�s�ǉ�����B
    IF ( gn_invoice_tax_err_cnt != 0 ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => NULL              -- ���b�Z�[�W
                    , in_new_line => cn_number_1       -- ���s
                    );
    -- submain���x���I���̏ꍇ�A�󔒍s��1�s�ǉ�����B
    ELSIF ( lv_retcode = cv_status_warn ) THEN
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => NULL              -- ���b�Z�[�W
                    , in_new_line => cn_number_1       -- ���s
                    );
    -- submain���G���[�I���̏ꍇ�Alv_errbuf��lv_errmsg�����O�o�͂���B
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- lv_errmsg�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => lv_errmsg         -- ���b�Z�[�W
                    , in_new_line => cn_number_0       -- ���s
                    );
      -- lv_errbuf�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => lv_errbuf         -- ���b�Z�[�W
                    , in_new_line => cn_number_1       -- ���s
                    );
    END IF;
    -- ===============================================
    -- �I������(A-9)
    -- ===============================================
    -- �Ώی����o��
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90000         -- ���������o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )  -- ���׃e�[�u���̑Ώی���
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  -- �o�͋敪
                  , iv_message  => lv_errmsg                     -- ���b�Z�[�W
                  , in_new_line => cn_number_0                   -- ���s
                  );
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR START
--    -- �G���[�������A��������:0�� �X�L�b�v����:0�� �G���[����:1��
--    IF ( lv_retcode = cv_status_error ) THEN
    -- �������ŋ��R�[�h�G���[�������A�G���[�����͊Y���̃G���[�ƂȂ���������ݒ�
    IF ( gn_invoice_tax_err_cnt != 0 ) THEN
      gn_error_cnt  := gn_invoice_tax_err_cnt;
    -- �G���[�������A��������:0�� �X�L�b�v����:0�� �G���[����:1��
    ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2014/04/07 Ver.1.9 [E_�{�ғ�_11765] SCSK K.Kiriu REPAIR END
      gn_normal_cnt := 0;
      gn_skip_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
    -- ���������o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90001         -- ���������o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )  -- ���׃e�[�u���o�^����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_errmsg                     --���b�Z�[�W
                  , in_new_line => cn_number_0                   --���s
                  );
    -- �X�L�b�v�����o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90003         -- ���������o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_skip_cnt )    -- �X�L�b�v����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_errmsg                     --���b�Z�[�W
                  , in_new_line => cn_number_0                   --���s
                  );
    -- �G���[�����o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90002         -- �G���[�����o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )   -- �G���[����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_errmsg                     --���b�Z�[�W
                  , in_new_line => cn_number_1                   --���s
                  );
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    -- ����I��
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    -- �x���I��
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    -- �G���[�I��
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- XXCCP'
                  , iv_name         => lv_message_code           -- �I�����b�Z�[�W
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --�o�͋敪
                  , iv_message  => lv_errmsg        --���b�Z�[�W
                  , in_new_line => cn_number_0      --���s
                  );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := lv_errbuf;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END main;
--
END XXCOK021A05C;
/
