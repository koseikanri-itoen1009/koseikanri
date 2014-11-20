CREATE OR REPLACE PACKAGE BODY XXCFR003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A02C(body)
 * Description      : �����w�b�_�f�[�^�쐬
 * MD.050           : MD050_CFR_003_A02_�����w�b�_�f�[�^�쐬
 * MD.070           : MD050_CFR_003_A02_�����w�b�_�f�[�^�쐬
 * Version          : 1.08
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  ins_inv_info_trans     p ���������n�e�[�u���o�^����            (A-2)
 *  ins_target_bill_acct_n p �Ώې�����ڋq�擾����(���)            (A-3)
 *  ins_target_bill_acct_o p �Ώې�����ڋq�擾����(�蓮)            (A-4)
 *  get_target_bill_acct   p �������Ώیڋq��񒊏o����              (A-5)
 *  delete_last_data       p �O�񏈗��f�[�^�폜����                  (A-6)
 *  get_bill_info          p �����Ώێ���f�[�^�擾����              (A-7)
 *  ins_invoice_header     p �����w�b�_���o�^����                  (A-8)
-- Modify 2009.09.29 Ver1.06 start
-- *  update_tax_gap         p �ō��z�Z�o����                          (A-9)
-- Modify 2009.09.29 Ver1.06 End
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.00 SCS ���� �א�    ����쐬
 *  2009/04/20    1.01 SCS ���� �L��    ��QT1_0564�Ή� �ō��z�v�Z����
 *  2009/07/13    1.02 SCS �A�� �^���l  ��Q0000344�Ή� �p�t�H�[�}���X���P
 *  2009/07/21    1.03 SCS ���� �א�    ��Q0000819�Ή� ��Ӑ���G���[�Ή�
 *  2009/07/22    1.04 SCS �A�� �^���l  ��Q0000827�Ή� �p�t�H�[�}���X���P
 *  2009/08/03    1.05 SCS �A�� �^���l  ��Q0000913�Ή� �p�t�H�[�}���X���P
 *  2009/09/29    1.06 SCS �A�� �^���l  ���ʉۑ�IE535�Ή� ���������
 *  2009/12/11    1.07 SCS ���� �q��    ��Q�uE_�{�ғ�_00424�v�b��Ή�
 *  2009/12/28    1.08 SCS ���� �q��    ��Q�uE_�{�ғ�_00606�v�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  dml_expt              EXCEPTION;      -- �c�l�k�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A02C'; -- �p�b�P�[�W��
  
  -- �v���t�@�C���I�v�V����
  ct_prof_name_itoen_name  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_GENERAL_INVOICE_ITOEN_NAME';   -- �ėp����������於
  cv_org_id                CONSTANT VARCHAR2(6)  := 'ORG_ID';                   -- �g�DID
  cv_set_of_books_id       CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';         -- ��v����ID
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';     -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_ccp_90000  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W
  cv_msg_ccp_90001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W
  cv_msg_ccp_90002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W
  cv_msg_ccp_90003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; --�X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  cv_msg_ccp_90005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
  cv_msg_ccp_90006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_ccp_90007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --�G���[�I���ꕔ�������b�Z�[�W
--
  cv_msg_cfr_00003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --���b�N�G���[���b�Z�[�W
  cv_msg_cfr_00004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cfr_00006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�G���[���b�Z�[�W
  cv_msg_cfr_00007  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --�f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cfr_00010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; --���ʊ֐��G���[���b�Z�[�W
  cv_msg_cfr_00015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --�擾�G���[���b�Z�[�W  
  cv_msg_cfr_00016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --�f�[�^�}���G���[���b�Z�[�W
  cv_msg_cfr_00017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_cfr_00031  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00031'; --�ڋq�}�X�^�o�^�s���G���[���b�Z�[�W
  cv_msg_cfr_00065  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00065'; --������ڋq�R�[�h���b�Z�[�W
-- Modify 2009.07.21 Ver1.03 start
  cv_msg_cfr_00077  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00077'; --��Ӑ���G���[���b�Z�[�W
-- Modify 2009.07.21 Ver1.03 end
--
  -- ���{�ꎫ���Q�ƃR�[�h
  cv_dict_cfr_00000002  CONSTANT VARCHAR2(20) := 'CFR000A00002'; -- �c�Ɠ��t�擾�֐�
  cv_dict_cfr_00000003  CONSTANT VARCHAR2(20) := 'CFR000A00003'; -- ���t�p�����[�^�ϊ��֐�
  cv_dict_cfr_00302001  CONSTANT VARCHAR2(20) := 'CFR003A02001'; -- ����ŋ敪
  cv_dict_cfr_00302002  CONSTANT VARCHAR2(20) := 'CFR003A02002'; -- �������o�͌`��
  cv_dict_cfr_00302003  CONSTANT VARCHAR2(20) := 'CFR003A02003'; -- ���|�R�[�h1(������)
  cv_dict_cfr_00302004  CONSTANT VARCHAR2(20) := 'CFR003A02004'; -- �������_�R�[�h
  cv_dict_cfr_00302005  CONSTANT VARCHAR2(20) := 'CFR003A02005'; -- �ŋ��|�[������
  cv_dict_cfr_00302006  CONSTANT VARCHAR2(20) := 'CFR003A02006'; -- �^�M�֘A
  cv_dict_cfr_00302007  CONSTANT VARCHAR2(20) := 'CFR003A02007'; -- ���|�Ǘ���
  cv_dict_cfr_00302008  CONSTANT VARCHAR2(20) := 'CFR003A02008'; -- �ō��z
  cv_dict_cfr_00302009  CONSTANT VARCHAR2(20) := 'CFR003A02009'; -- �Ώێ���f�[�^����
  cv_dict_cfr_00302010  CONSTANT VARCHAR2(20) := 'CFR003A02010'; -- �������z
  cv_dict_cfr_00302011  CONSTANT VARCHAR2(20) := 'CFR003A02011'; -- �T�C�g�����A�����A�x����
  cv_dict_cfr_00302012  CONSTANT VARCHAR2(20) := 'CFR003A02012'; -- �����ڋq���
  cv_dict_cfr_00302013  CONSTANT VARCHAR2(20) := 'CFR003A02013'; -- �Ώۊ���(��)
  cv_dict_cfr_00302014  CONSTANT VARCHAR2(20) := 'CFR003A02014'; -- ����ȖځE�⏕�Ȗ�
--
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- �v���t�@�C���I�v�V������
  cv_tkn_func_name  CONSTANT VARCHAR2(30)  := 'FUNC_NAME';       -- �t�@���N�V������
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- �e�[�u����
  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- �ڋq�R�[�h
  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- �ڋq��
  cv_tkn_column     CONSTANT VARCHAR2(30)  := 'COLUMN';          -- �J������
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- �f�[�^
-- Modify 2009.07.21 Ver1.03 start
  cv_tkn_cut_date   CONSTANT VARCHAR2(30)  := 'CUTOFF_DATE';     -- ����
-- Modify 2009.07.21 Ver1.03 end
--
  -- �g�pDB��
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- ���������n�e�[�u��
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- �������Ώیڋq���[�N�e�[�u��
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- �����w�b�_���e�[�u��
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- �������׏��e�[�u��
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- �ō��z����쐬�e�[�u��
--
  -- �Q�ƃ^�C�v
  cv_look_type_ar_cd  CONSTANT VARCHAR2(100) := 'XXCMM_INVOICE_GRP_CODE';     -- ���|�R�[�h1(������)
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_judge_type_batch   CONSTANT VARCHAR2(1)  := '2';         -- ��Ԏ蓮���f�敪(2:���)
  cv_inv_hold_status_o  CONSTANT VARCHAR2(4)  := 'OPEN';      -- �������ۗ��X�e�[�^�X(�I�[�v��)
  cv_inv_hold_status_r  CONSTANT VARCHAR2(7)  := 'REPRINT';   -- �������ۗ��X�e�[�^�X(�Đ���)
  cv_tax_div_outtax     CONSTANT VARCHAR2(1)  := '1';         -- ����ŋ敪(�O��)
  cv_get_acct_name_f    CONSTANT VARCHAR2(1)  := '0';         -- �ڋq���̎擾�֐��p�����[�^(�S�p)
  cv_get_acct_name_k    CONSTANT VARCHAR2(1)  := '1';         -- �ڋq���̎擾�֐��p�����[�^(�J�i)
  cv_account_class_rec  CONSTANT VARCHAR2(3)  := 'REC';       -- ����敪(���|/������)
  cv_line_type_tax      CONSTANT VARCHAR2(3)  := 'TAX';       -- ������׃^�C�v(�ŋ�)
  cv_line_type_line     CONSTANT VARCHAR2(4)  := 'LINE';      -- ������׃^�C�v(����)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
    -- �������Ώیڋq��񒊏o�J�[�\���p
    TYPE get_acct_code_ttype          IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_code%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cutoff_date_ttype        IS TABLE OF xxcfr_inv_target_cust_list.cutoff_date%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_name_ttype          IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_name%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_acct_id_ttype       IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_account_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_cust_acct_site_id_ttype  IS TABLE OF xxcfr_inv_target_cust_list.bill_cust_acct_site_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_term_name_ttype          IS TABLE OF xxcfr_inv_target_cust_list.term_name%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_term_id_ttype            IS TABLE OF xxcfr_inv_target_cust_list.term_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_tax_div_ttype            IS TABLE OF xxcfr_inv_target_cust_list.tax_div%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_bill_pub_cycle_ttype     IS TABLE OF xxcfr_inv_target_cust_list.bill_pub_cycle%TYPE
                                                  INDEX BY PLS_INTEGER;
    gt_get_acct_code_tab            get_acct_code_ttype;
    gt_get_cutoff_date_tab          get_cutoff_date_ttype;
    gt_get_cust_name_tab            get_cust_name_ttype;
    gt_get_cust_acct_id_tab         get_cust_acct_id_ttype;
    gt_get_cust_acct_site_id_tab    get_cust_acct_site_id_ttype;
    gt_get_term_name_tab            get_term_name_ttype;
    gt_get_term_id_tab              get_term_id_ttype;
    gt_get_tax_div_tab              get_tax_div_ttype;
    gt_get_bill_pub_cycle_tab       get_bill_pub_cycle_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_itoen_name              fnd_profile_option_values.profile_option_value%TYPE;  -- �ėp����������於
  gd_target_date             DATE;                                                 -- ����(���t�^)
  gn_org_id                  NUMBER;                                               -- �g�DID
  gn_set_book_id             NUMBER;                                               -- ��v����ID
  gn_request_id              NUMBER;                                               -- �R���J�����g�v��ID
  gd_process_date            DATE;                                                 -- �Ɩ��������t
  gd_work_day_ago1           DATE;                                                 -- 1�c�Ɠ��O��
  gd_work_day_ago2           DATE;                                                 -- 2�c�Ɠ��O��
  gt_warning_flag            VARCHAR2(1);                                          -- �x���t���O
--
  gt_invoice_id              xxcfr_invoice_headers.invoice_id%TYPE;                -- �ꊇ������ID
  gt_amount_no_tax           xxcfr_invoice_headers.inv_amount_no_tax%TYPE;         -- �Ŕ��������z���v
  gt_tax_amount_sum          xxcfr_invoice_headers.tax_amount_sum%TYPE;            -- �Ŋz���v
  gt_amount_includ_tax       xxcfr_invoice_headers.inv_amount_includ_tax%TYPE;     -- �ō��������z���v
  gt_due_months_forword      xxcfr_invoice_headers.due_months_forword%TYPE;        -- �T�C�g����
  gt_month_remit             xxcfr_invoice_headers.month_remit%TYPE;               -- ����
  gt_payment_date            xxcfr_invoice_headers.payment_date%TYPE;              -- �x����
  gt_tax_type                xxcfr_invoice_headers.tax_type%TYPE;                  -- ����ŋ敪
  gt_tax_gap_trx_id          xxcfr_invoice_headers.tax_gap_trx_id%TYPE;            -- �ō��z���ID
  gt_tax_gap_amount          xxcfr_invoice_headers.tax_gap_amount%TYPE;            -- �ō��z
  gt_postal_code             xxcfr_invoice_headers.postal_code%TYPE;               -- ���t��X�֔ԍ�
  gt_send_address1           xxcfr_invoice_headers.send_address1%TYPE;             -- ���t��Z��1
  gt_send_address2           xxcfr_invoice_headers.send_address2%TYPE;             -- ���t��Z��2
  gt_send_address3           xxcfr_invoice_headers.send_address3%TYPE;             -- ���t��Z��3
  gt_object_date_from        xxcfr_invoice_headers.object_date_from%TYPE;          -- �Ώۊ��ԁi���j
  gt_vender_code             xxcfr_invoice_headers.vender_code%TYPE;               -- �d����R�[�h
  gt_receipt_location_code   xxcfr_invoice_headers.receipt_location_code%TYPE;     -- �������_�R�[�h
  gt_bill_location_code      xxcfr_invoice_headers.bill_location_code%TYPE;        -- �������_�R�[�h
  gt_bill_location_name      xxcfr_invoice_headers.bill_location_name%TYPE;        -- �������_��
  gt_agent_tel_num           xxcfr_invoice_headers.agent_tel_num%TYPE;             -- �S���d�b�ԍ�
  gt_credit_cust_code        xxcfr_invoice_headers.credit_cust_code%TYPE;          -- �^�M��ڋq�R�[�h
  gt_credit_cust_name        xxcfr_invoice_headers.credit_cust_name%TYPE;          -- �^�M��ڋq��
  gt_receipt_cust_code       xxcfr_invoice_headers.receipt_cust_code%TYPE;         -- ������ڋq�R�[�h
  gt_receipt_cust_name       xxcfr_invoice_headers.receipt_cust_name%TYPE;         -- ������ڋq��
  gt_payment_cust_code       xxcfr_invoice_headers.payment_cust_code%TYPE;         -- �e������ڋq�R�[�h
  gt_payment_cust_name       xxcfr_invoice_headers.payment_cust_name%TYPE;         -- �e������ڋq��
  gt_bill_cust_kana_name     xxcfr_invoice_headers.bill_cust_kana_name%TYPE;       -- ������ڋq�J�i��
  gt_bill_shop_code          xxcfr_invoice_headers.bill_shop_code%TYPE;            -- ������X�܃R�[�h
  gt_bill_shop_name          xxcfr_invoice_headers.bill_shop_name%TYPE;            -- ������X��
  gt_credit_receiv_code2     xxcfr_invoice_headers.credit_receiv_code2%TYPE;       -- ���|�R�[�h2�i���Ə��j
  gt_credit_receiv_name2     xxcfr_invoice_headers.credit_receiv_name2%TYPE;       -- ���|�R�[�h2�i���Ə��j����
  gt_credit_receiv_code3     xxcfr_invoice_headers.credit_receiv_code3%TYPE;       -- ���|�R�[�h3�i���̑��j
  gt_credit_receiv_name3     xxcfr_invoice_headers.credit_receiv_name3%TYPE;       -- ���|�R�[�h3�i���̑��j����
  gt_invoice_output_form     xxcfr_invoice_headers.invoice_output_form%TYPE;       -- �������o�͌`��
  gt_tax_round_rule          hz_cust_site_uses_all.tax_rounding_rule%TYPE;         -- �ŋ��|�[������
  gv_party_ref_type          VARCHAR2(50);                                         -- �p�[�e�B�֘A�^�C�v(�^�M�֘A)
  gv_party_rev_code          VARCHAR2(50);                                         -- �p�[�e�B�֘A(���|�Ǘ���)
-- Modify 2009.07.13 Ver1.02 start
  gt_bill_payment_term_id    hz_cust_site_uses_all.payment_term_id%TYPE;           -- �x������1
  gt_bill_payment_term2      hz_cust_site_uses_all.attribute2%TYPE;                -- �x������2
  gt_bill_payment_term3      hz_cust_site_uses_all.attribute3%TYPE;                -- �x������3
-- Modify 2009.07.13 Ver1.02 end
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN VARCHAR2,      -- ����
    iv_bill_acct_code       IN VARCHAR2,      -- ������ڋq�R�[�h
    iv_batch_on_judge_type  IN VARCHAR2,      -- ��Ԏ蓮���f�敪
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out        -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_target_date          -- ����
      ,iv_conc_param2  => iv_bill_acct_code       -- ������ڋq�R�[�h
      ,iv_conc_param3  => iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
      ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log        -- ���O�o��
      ,iv_conc_param1  => iv_target_date          -- ����
      ,iv_conc_param2  => iv_bill_acct_code       -- ������ڋq�R�[�h
      ,iv_conc_param3  => iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
      ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C���擾����
    --==============================================================
    --�ėp����������於
    gt_itoen_name := FND_PROFILE.VALUE(ct_prof_name_itoen_name);
    IF (gt_itoen_name IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(ct_prof_name_itoen_name);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --�g�DID
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    IF (gn_org_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_org_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --��v����ID
    gn_set_book_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_books_id));
    IF (gn_set_book_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_set_of_books_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�Ɩ��������t�擾����
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date());
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00006  )
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�c�Ɠ��t�擾����
    --==============================================================
    --1�c�Ɠ��O
    gd_work_day_ago1 := TRUNC(xxccp_common_pkg2.get_working_day(
                                id_date        => gd_process_date
                               ,in_working_day => -1));
    IF (gd_work_day_ago1 IS NULL) THEN
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                             iv_loopup_type_prefix => cv_msg_kbn_cfr
                            ,iv_keyword            => cv_dict_cfr_00000002);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr    
                            ,iv_name         => cv_msg_cfr_00010  
                            ,iv_token_name1  => cv_tkn_func_name  
                            ,iv_token_value1 => lt_look_dict_word)
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --2�c�Ɠ��O
    gd_work_day_ago2 := TRUNC(xxccp_common_pkg2.get_working_day(
                                id_date        => gd_process_date
                               ,in_working_day => -2));
    IF (gd_work_day_ago2 IS NULL) THEN
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                             iv_loopup_type_prefix => cv_msg_kbn_cfr
                            ,iv_keyword            => cv_dict_cfr_00000002);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cfr    
                            ,iv_name         => cv_msg_cfr_00010  
                            ,iv_token_name1  => cv_tkn_func_name  
                            ,iv_token_value1 => lt_look_dict_word)
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���̓p�����[�^���t�^�ϊ�����
    --==============================================================
--
    IF (iv_target_date IS NOT NULL) AND
       (iv_batch_on_judge_type != cv_judge_type_batch)
    THEN
      gd_target_date := xxcfr_common_pkg.get_date_param_trans(iv_target_date);
      -- �Ɩ��������t�ɓ��̓p�����[�^�D������ݒ�
      gd_process_date := gd_target_date;
      IF (gd_target_date IS NULL) THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr
                              ,iv_keyword            => cv_dict_cfr_00000003);
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr    
                              ,iv_name         => cv_msg_cfr_00010  
                              ,iv_token_name1  => cv_tkn_func_name  
                              ,iv_token_value1 => lt_look_dict_word)
                            ,1
                            ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --�^�M�֘A�����擾����
    --==============================================================
    -- �p�[�e�B�֘A�^�C�v(�^�M�֘A)�擾
    gv_party_ref_type := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_msg_kbn_cfr
                          ,iv_keyword            => cv_dict_cfr_00302006);
--
    -- �p�[�e�B�֘A(���|�Ǘ���)�擾
    gv_party_rev_code := xxcfr_common_pkg.lookup_dictionary(
                           iv_loopup_type_prefix => cv_msg_kbn_cfr
                          ,iv_keyword            => cv_dict_cfr_00302007);
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Procedure Name   : ins_inv_info_trans
   * Description      : ���������n�e�[�u���o�^����(A-2)
   ***********************************************************************************/
  PROCEDURE ins_inv_info_trans(
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_info_trans'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �폜�Ώۃf�[�^���o
    CURSOR del_inv_info_trans_cur
    IS
      SELECT xiit.ROWID    row_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.org_id = gn_org_id
      AND    xiit.set_of_books_id = gn_set_book_id
      FOR UPDATE NOWAIT
    ;
--
    TYPE del_inv_info_trans_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_inv_info_trans_tab    del_inv_info_trans_ttype;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    --==============================================================
    --���������n�e�[�u���f�[�^�폜����
    --==============================================================
    -- ���������n�e�[�u�����b�N
--
    -- �J�[�\���I�[�v��
    OPEN del_inv_info_trans_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH del_inv_info_trans_cur BULK COLLECT INTO lt_del_inv_info_trans_tab;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_del_inv_info_trans_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE del_inv_info_trans_cur;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<transfer_data_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_inv_info_transfer
          WHERE ROWID = lt_del_inv_info_trans_tab(ln_loop_cnt);
      END IF;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                                         -- ���������n�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --���������n�e�[�u���f�[�^�o�^����
    --==============================================================
    BEGIN
      INSERT INTO xxcfr_inv_info_transfer (
         target_request_id     
        ,set_of_books_id
        ,org_id
        ,created_by            
        ,creation_date         
        ,last_updated_by       
        ,last_update_date      
        ,last_update_login     
        ,request_id            
        ,program_application_id
        ,program_id            
        ,program_update_date   
      )
      VALUES
      (
         cn_request_id
        ,gn_set_book_id
        ,gn_org_id
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
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                                         -- ���������n�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �e�[�u�����b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( 
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xiit))
                                                    -- ���������n�e�[�u��
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END ins_inv_info_trans;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_bill_acct_n
   * Description      : �Ώې�����ڋq�擾����(���)(A-3)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_n(
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_bill_acct_n'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �x���������o(1)�J�[�\��
    CURSOR get_target_term_info1_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(gd_process_date, -1)), 'DD')) THEN
                             LAST_DAY(ADD_MONTHS(gd_process_date, -1))
                    ELSE TO_DATE(TO_CHAR(ADD_MONTHS(gd_process_date, -1), 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
        UNION ALL
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date >= gd_work_day_ago1
      AND    inlv.cut_date <  gd_process_date
      ORDER BY inlv.cut_date DESC
      ;
--
    -- �x���������o(2)�J�[�\��
    CURSOR get_target_term_info2_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(gd_process_date, -1)), 'DD')) THEN
                             LAST_DAY(ADD_MONTHS(gd_process_date, -1))
                    ELSE TO_DATE(TO_CHAR(ADD_MONTHS(gd_process_date, -1), 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
        UNION ALL
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date >= gd_work_day_ago2
      AND    inlv.cut_date <  gd_work_day_ago1
      ORDER BY inlv.cut_date DESC
      ;
--
    TYPE get_target_term_name_ttype     IS TABLE OF ra_terms_vl.name%TYPE INDEX BY PLS_INTEGER;
    TYPE get_target_term_cut_date_ttype IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE get_target_term_term_id_ttype  IS TABLE OF ra_terms_vl.term_id%TYPE INDEX BY PLS_INTEGER;
    lt_get1_term_name_tab               get_target_term_name_ttype;
    lt_get1_term_cut_date_tab           get_target_term_cut_date_ttype;
    lt_get1_term_term_id_tab            get_target_term_term_id_ttype;
    lt_get2_term_name_tab               get_target_term_name_ttype;
    lt_get2_term_cut_date_tab           get_target_term_cut_date_ttype;
    lt_get2_term_term_id_tab            get_target_term_term_id_ttype;
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    --==============================================================
    --�������Ώیڋq���[�N�e�[�u���o�^����(������1�c�Ɠ���̌ڋq)
    --==============================================================
    -- �x���������o(1)�J�[�\���I�[�v��
    OPEN get_target_term_info1_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_target_term_info1_cur 
    BULK COLLECT INTO  lt_get1_term_name_tab    
                     , lt_get1_term_cut_date_tab
                     , lt_get1_term_term_id_tab 
    ;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_get1_term_name_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_target_term_info1_cur;
--
    -- �Ώۃf�[�^�����ݎ�,�������Ώیڋq���[�N�e�[�u���o�^
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- �������Ώیڋq���[�N�e�[�u���o�^
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                        bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                        bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get1_term_cut_date_tab(ln_loop_cnt)     cutoff_date             -- ����
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)     bill_cust_name          -- ������ڋq��
                  , hzca.cust_account_id                       bill_cust_account_id    -- ������ڋqID
                  , hzsa.cust_acct_site_id                     bill_cust_acct_site_id  -- ������ڋq���ݒnID
                  , lt_get1_term_name_tab(ln_loop_cnt)         term_name               -- �x������
                  , lt_get1_term_term_id_tab(ln_loop_cnt)      term_id                 -- �x������ID
                  , xxca.tax_div                               tax_div                 -- ����ŋ敪
                  , hzsu.attribute8                            bill_pub_cycle          -- ���������s�T�C�N��
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- �ڋq�}�X�^
--                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
--                  ,hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                   hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
                  ,hz_cust_accounts          hzca              -- �ڋq�}�X�^
-- Modify 2009.08.03 Ver1.05 End
                  ,xxcmm_cust_accounts       xxca              -- �ڋq�ǉ����
                  ,hz_customer_profiles      hzcp              -- �ڋq�v���t�@�C��
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get1_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2 = TO_CHAR(lt_get1_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3 = TO_CHAR(lt_get1_term_term_id_tab(ln_loop_cnt)) )  --�x������
            AND    hzsu.site_use_code = 'BILL_TO'                     -- �g�p�ړI�R�[�h(������)
            AND    hzcp.cons_inv_flag = 'Y'                           -- �ꊇ���������g�p�\FLAG('Y')
            AND    hzsa.org_id = gn_org_id                            -- �g�DID
            AND    hzsu.org_id = gn_org_id                            -- �g�DID
            AND    hzsu.attribute8 = '1'                              -- ���������s�T�C�N��(���c�Ɠ�)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                   -- �g�p�ړI�R�[�h(�o�א�)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- �������Ώیڋq���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --���[�J���ϐ�������
    ln_target_cnt := 0;
--
    --==============================================================
    --�������Ώیڋq���[�N�e�[�u���o�^����(������2�c�Ɠ���̌ڋq)
    --==============================================================
    -- �x���������o(2)�J�[�\���I�[�v��
    OPEN get_target_term_info2_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_target_term_info2_cur 
    BULK COLLECT INTO  lt_get2_term_name_tab    
                     , lt_get2_term_cut_date_tab
                     , lt_get2_term_term_id_tab 
    ;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_get2_term_name_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_target_term_info2_cur;
--
    -- �Ώۃf�[�^�����ݎ�,�������Ώیڋq���[�N�e�[�u���o�^
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop2>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- �������Ώیڋq���[�N�e�[�u���o�^
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                       bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                       bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get2_term_cut_date_tab(ln_loop_cnt)    cutoff_date             -- ����
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)    bill_cust_name          -- ������ڋq��
                  , hzca.cust_account_id                      bill_cust_account_id    -- ������ڋqID
                  , hzsa.cust_acct_site_id                    bill_cust_acct_site_id  -- ������ڋq���ݒnID
                  , lt_get2_term_name_tab(ln_loop_cnt)        term_name               -- �x������
                  , lt_get2_term_term_id_tab(ln_loop_cnt)     term_id                 -- �x������ID
                  , xxca.tax_div                              tax_div                 -- ����ŋ敪
                  , hzsu.attribute8                           bill_pub_cycle          -- ���������s�T�C�N��
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- �ڋq�}�X�^
--                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
--                  ,hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                   hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
                  ,hz_cust_accounts          hzca              -- �ڋq�}�X�^
-- Modify 2009.08.03 Ver1.05 End
                  ,xxcmm_cust_accounts       xxca              -- �ڋq�ǉ����
                  ,hz_customer_profiles      hzcp              -- �ڋq�v���t�@�C��
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get2_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2      = TO_CHAR(lt_get2_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3      = TO_CHAR(lt_get2_term_term_id_tab(ln_loop_cnt)) )--�x������
            AND    hzsu.site_use_code = 'BILL_TO'                    -- �g�p�ړI�R�[�h(������)
            AND    hzcp.cons_inv_flag = 'Y'                          -- �ꊇ���������g�p�\FLAG('Y')
            AND    hzsa.org_id = gn_org_id                           -- �g�DID
            AND    hzsu.org_id = gn_org_id                           -- �g�DID
            AND    hzsu.attribute8 = '2'                             -- ���������s�T�C�N��(���c�Ɠ�)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                    -- �g�p�ړI�R�[�h(�o�א�)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- �������Ώیڋq���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
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
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_target_bill_acct_n;
--
  /**********************************************************************************
   * Procedure Name   : ins_target_bill_acct_o
   * Description      : �Ώې�����ڋq�擾����(�蓮)(A-4)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_o(
    iv_bill_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_target_bill_acct_o'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �x���������o(�蓮)�J�[�\��
    CURSOR get_target_term_info_cur
    IS
      SELECT inlv.name        name
           , inlv.cut_date    cut_date
           , inlv.term_id     term_id
      FROM (
        SELECT rtvl.name                                                                             name
             , CASE WHEN DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1) >= 
                           TO_NUMBER(TO_CHAR(LAST_DAY(gd_process_date), 'DD')) THEN
                             LAST_DAY(gd_process_date)
                    ELSE TO_DATE(TO_CHAR(gd_process_date, 'YYYY/MM/') || 
                           TO_CHAR(DECODE(rtvl.due_cutoff_day - 1, 0, 31, rtvl.due_cutoff_day - 1))
                               , 'YYYY/MM/DD')
               END                                                                                   cut_date
             , rtvl.term_id                                                                          term_id
        FROM   ra_terms_vl rtvl
        WHERE  rtvl.due_cutoff_day IS NOT NULL                      --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
        AND    gd_process_date BETWEEN NVL(rtvl.start_date_active, gd_process_date)
                                   AND NVL(rtvl.end_date_active,   gd_process_date)
      ) inlv
      WHERE  inlv.cut_date = gd_target_date
      ;
--
    TYPE get_target_term_name_ttype     IS TABLE OF ra_terms_vl.name%TYPE INDEX BY PLS_INTEGER;
    TYPE get_target_term_cut_date_ttype IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE get_target_term_term_id_ttype  IS TABLE OF ra_terms_vl.term_id%TYPE INDEX BY PLS_INTEGER;
    lt_get_term_name_tab                get_target_term_name_ttype;
    lt_get_term_cut_date_tab            get_target_term_cut_date_ttype;
    lt_get_term_term_id_tab             get_target_term_term_id_ttype;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    --==============================================================
    --�������Ώیڋq���[�N�e�[�u���o�^����
    --==============================================================
    -- �x���������o�J�[�\���I�[�v��
    OPEN get_target_term_info_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_target_term_info_cur 
    BULK COLLECT INTO  lt_get_term_name_tab    
                     , lt_get_term_cut_date_tab
                     , lt_get_term_term_id_tab 
    ;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_get_term_name_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE get_target_term_info_cur;
--
    -- �Ώۃf�[�^�����ݎ�,�������Ώیڋq���[�N�e�[�u���o�^
    BEGIN
      IF (ln_target_cnt > 0) THEN
        <<target_term_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
--
          -- �������Ώیڋq���[�N�e�[�u���o�^
          INSERT INTO xxcfr_inv_target_cust_list(
              bill_cust_code
            , cutoff_date
            , bill_cust_name
            , bill_cust_account_id
            , bill_cust_acct_site_id
            , term_name
            , term_id
            , tax_div
            , bill_pub_cycle
          )
-- Modify 2009.07.22 Ver1.04 start
--            SELECT  hzca.account_number                      bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.08.03 Ver1.05 start
--            SELECT  /*+ USE_CONCAT */
            SELECT  /*+ USE_CONCAT 
                        ORDERED
                    */
-- Modify 2009.08.03 Ver1.05 End
                    hzca.account_number                      bill_cust_code          -- ������ڋq�R�[�h
-- Modify 2009.07.22 Ver1.04 start
                  , lt_get_term_cut_date_tab(ln_loop_cnt)    cutoff_date             -- ����
                  , xxcfr_common_pkg.get_cust_account_name(
                                       hzca.account_number,
                                       cv_get_acct_name_f)   bill_cust_name          -- ������ڋq��
                  , hzca.cust_account_id                     bill_cust_account_id    -- ������ڋqID
                  , hzsa.cust_acct_site_id                   bill_cust_acct_site_id  -- ������ڋq���ݒnID
                  , lt_get_term_name_tab(ln_loop_cnt)        term_name               -- �x������
                  , lt_get_term_term_id_tab(ln_loop_cnt)     term_id                 -- �x������ID
                  , xxca.tax_div                             tax_div                 -- ����ŋ敪
                  , hzsu.attribute8                          bill_pub_cycle          -- ���������s�T�C�N��
            FROM
-- Modify 2009.08.03 Ver1.05 start
--                   hz_cust_accounts          hzca              -- �ڋq�}�X�^
--                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
--                  ,hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                   hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
                  ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
                  ,hz_cust_accounts          hzca              -- �ڋq�}�X�^
-- Modify 2009.08.03 Ver1.05 start
                  ,xxcmm_cust_accounts       xxca              -- �ڋq�ǉ����
                  ,hz_customer_profiles      hzcp              -- �ڋq�v���t�@�C��
            WHERE
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND  ( hzsu.payment_term_id = lt_get_term_term_id_tab(ln_loop_cnt)
            OR     hzsu.attribute2      = TO_CHAR(lt_get_term_term_id_tab(ln_loop_cnt))
            OR     hzsu.attribute3      = TO_CHAR(lt_get_term_term_id_tab(ln_loop_cnt)) )--�x������
            AND    hzsu.site_use_code = 'BILL_TO'                    -- �g�p�ړI�R�[�h(������)
            AND    hzcp.cons_inv_flag = 'Y'                          -- �ꊇ���������g�p�\FLAG('Y')
            AND    hzsa.org_id = gn_org_id                           -- �g�DID
            AND    hzsu.org_id = gn_org_id                           -- �g�DID
-- Modify 2009.07.13 Ver1.02 start
--            AND    hzsu.attribute8 IS NOT NULL                       -- ���������s�T�C�N��
            AND    hzsu.attribute8 IN('1','2')                       -- ���������s�T�C�N��
-- Modify 2009.07.13 Ver1.02 end
            AND    hzca.account_number = NVL(iv_bill_acct_code, hzca.account_number)
-- Modify 2009.12.28 Ver1.08 start
--            AND EXISTS (
--              SELECT 'X'
--              FROM   hz_cust_site_uses_all   shsu
--              WHERE  shsu.bill_to_site_use_id = hzsu.site_use_id
--              AND    shsu.site_use_code = 'SHIP_TO'                    -- �g�p�ړI�R�[�h(�o�א�)
--              AND    shsu.org_id = gn_org_id
--              AND    ROWNUM = 1
--              )
-- Modify 2009.12.28 Ver1.08 end
            AND NOT EXISTS (
              SELECT 'X'
              FROM   xxcfr_inv_target_cust_list xxcl
              WHERE  xxcl.bill_cust_code = hzca.account_number
              )
          ;
--
      END IF;
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xtcl))
                                                                         -- �������Ώیڋq���[�N�e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
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
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_target_bill_acct_o;
--
  /**********************************************************************************
   * Procedure Name   : get_target_bill_acct
   * Description      : �������Ώیڋq��񒊏o����(A-5)
   ***********************************************************************************/
  PROCEDURE get_target_bill_acct(
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_bill_acct'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �������Ώیڋq��񒊏o�J�[�\��
    CURSOR get_target_acct_info_cur
    IS
      SELECT bill_cust_code             bill_cust_code        
           , cutoff_date                cutoff_date
           , bill_cust_name             bill_cust_name
           , bill_cust_account_id       bill_cust_account_id
           , bill_cust_acct_site_id     bill_cust_acct_site_id
           , term_name                  term_name
           , term_id                    term_id
           , tax_div                    tax_div
           , bill_pub_cycle             bill_pub_cycle
      FROM   xxcfr_inv_target_cust_list
      ;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    --==============================================================
    --�������Ώیڋq���[�N�e�[�u���o�^����
    --==============================================================
    -- �������Ώیڋq��񒊏o�J�[�\���I�[�v��
    OPEN get_target_acct_info_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_target_acct_info_cur 
    BULK COLLECT INTO gt_get_acct_code_tab,
                      gt_get_cutoff_date_tab,
                      gt_get_cust_name_tab,
                      gt_get_cust_acct_id_tab,
                      gt_get_cust_acct_site_id_tab,
                      gt_get_term_name_tab,
                      gt_get_term_id_tab,
                      gt_get_tax_div_tab,
                      gt_get_bill_pub_cycle_tab   
    ;
--
    -- ���������̃Z�b�g
    gn_target_cnt := gt_get_acct_code_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE get_target_acct_info_cur;
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_bill_acct;
--
  /**********************************************************************************
   * Procedure Name   : delete_last_data
   * Description      : �O�񏈗��f�[�^�폜����(A-6)
   ***********************************************************************************/
  PROCEDURE delete_last_data(
    iv_account_code         IN  VARCHAR2,     -- ������ڋq�R�[�h
    id_cutoff_date          IN  DATE,         -- ����
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_last_data'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �O�񏈗��f�[�^���o(�w�b�_)
    CURSOR del_target_inv_data_cur(
      id_cutoff_date    VARCHAR2,
      iv_customer_code  VARCHAR2
    )
    IS
      SELECT xxih.invoice_id    invoice_id
      FROM   xxcfr_invoice_headers xxih
      WHERE  xxih.cutoff_date = id_cutoff_date
      AND    xxih.bill_cust_code = iv_customer_code
      AND    xxih.org_id = gn_org_id
      AND    xxih.set_of_books_id = gn_set_book_id
      FOR UPDATE NOWAIT
    ;
--
    -- �O�񏈗��f�[�^���o(����)���b�N�p
    -- �������w�b�_�e�[�u���ɂ̂݃f�[�^�����݂���P�[�X��z�肵
    --   �������׃e�[�u���̃��b�N��ʂō쐬
    CURSOR del_target_inv_line_data_cur(
      id_cutoff_date    VARCHAR2,
      iv_customer_code  VARCHAR2
    )
    IS
      SELECT xxil.invoice_id    invoice_id
      FROM   xxcfr_invoice_lines   xxil
      WHERE  xxil.invoice_id IN (
               SELECT xxih.invoice_id    invoice_id
               FROM   xxcfr_invoice_headers xxih
               WHERE  xxih.cutoff_date = id_cutoff_date
               AND    xxih.bill_cust_code = iv_customer_code
               AND    xxih.org_id = gn_org_id
               )
      FOR UPDATE NOWAIT
    ;
--
    TYPE del_target_inv_id_ttype IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE INDEX BY PLS_INTEGER;
    lt_del_target_inv_id_tab     del_target_inv_id_ttype;
    lt_inv_line_id_tab           del_target_inv_id_ttype;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    --==============================================================
    --�����e�[�u�����b�N���擾����
    --==============================================================
    -- �J�[�\���I�[�v��(�w�b�_)
    BEGIN
      OPEN del_target_inv_data_cur( id_cutoff_date,
                                    iv_account_code)
      ;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_target_inv_data_cur BULK COLLECT INTO lt_del_target_inv_id_tab;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_del_target_inv_id_tab.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE del_target_inv_data_cur;
--
    EXCEPTION
      -- *** �e�[�u�����b�N�G���[�n���h�� ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- �����w�b�_���e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- �J�[�\���I�[�v��(����)
    BEGIN
      OPEN del_target_inv_line_data_cur( id_cutoff_date,
                                         iv_account_code)
      ;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH del_target_inv_line_data_cur BULK COLLECT INTO lt_inv_line_id_tab;
--
      -- �J�[�\���N���[�Y
      CLOSE del_target_inv_line_data_cur;
--
    EXCEPTION
      -- *** �e�[�u�����b�N�G���[�n���h�� ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                                         -- �������׏��e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<del_invoice_lines_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_invoice_lines
          WHERE invoice_id = lt_del_target_inv_id_tab(ln_loop_cnt);
--
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                                         -- �������׏��e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
      END;
--
      BEGIN
        <<del_invoice_header_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_invoice_headers
          WHERE invoice_id = lt_del_target_inv_id_tab(ln_loop_cnt);
--
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                      -- �����w�b�_���e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
      END;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_last_data;
--
  /**********************************************************************************
   * Procedure Name   : get_bill_info
   * Description      : �����Ώێ���f�[�^�擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_bill_info(
    iv_cust_acct_id         IN  NUMBER,       -- ������ڋqID
    id_cutoff_date          IN  DATE,         -- ����
    ov_target_trx_cnt       OUT NUMBER,       -- �Ώێ������
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bill_info'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
    lt_look_dict_word := NULL;
--
    -- �O���[�o���ϐ�������
    gt_amount_no_tax     := 0;
    gt_tax_amount_sum    := 0;
    gt_amount_includ_tax := 0;
--
-- Modify 2009.12.28 Ver1.08 start
    --==============================================================
    --�Ώۃf�[�^�����擾����
    --==============================================================
--    BEGIN
--      SELECT COUNT(rcta.customer_trx_id)    cnt
--      INTO   ln_target_cnt
--      FROM   ra_customer_trx_all        rcta
--           , ra_customer_trx_lines_all  rcla
--      WHERE  rcta.trx_date <= id_cutoff_date                                  -- ����
--      AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- �������ۗ��X�e�[�^�X
--      AND    rcta.bill_to_customer_id = iv_cust_acct_id                       -- ������ڋqID
--      AND    rcta.org_id          = gn_org_id                                 -- �g�DID
--      AND    rcta.set_of_books_id = gn_set_book_id                            -- ��v����ID
--      AND    rcta.customer_trx_id = rcla.customer_trx_id
--      ;
--    EXCEPTION
--      -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00302009);    -- �Ώێ���f�[�^����
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,
--                               iv_name         => cv_msg_cfr_00015,  
--                               iv_token_name1  => cv_tkn_data,  
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
--    -- �Ώێ���f�[�^�������Z�b�g
--    ov_target_trx_cnt := ln_target_cnt;
--
--    IF (ln_target_cnt > 0) THEN
      --==============================================================
      --�������z�擾����
      --==============================================================
      BEGIN
        SELECT SUM( DECODE( rcla.line_type, cv_line_type_line, rcla.extended_amount
                                          , 0))   amount_no_tax             -- �Ŕ��������z���v
             , SUM( DECODE( rcla.line_type, cv_line_type_tax , rcla.extended_amount
                                          , 0))   tax_amount_sum            -- �Ŋz���v
             , SUM( rcla.extended_amount)         amount_includ_tax         -- �ō��������z���v
             , COUNT('X')                         cnt                       -- ���R�[�h����
        INTO   gt_amount_no_tax
             , gt_tax_amount_sum
             , gt_amount_includ_tax
             , ln_target_cnt
        FROM   ra_customer_trx_all        rcta
             , ra_customer_trx_lines_all  rcla
        WHERE  rcta.trx_date <= id_cutoff_date                                  -- ����
        AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- �������ۗ��X�e�[�^�X
        AND    rcta.bill_to_customer_id = iv_cust_acct_id                       -- ������ڋqID
        AND    rcta.org_id          = gn_org_id                                 -- �g�DID
        AND    rcta.set_of_books_id = gn_set_book_id                            -- ��v����ID
        AND    rcta.customer_trx_id = rcla.customer_trx_id
        ;
        -- �Ώێ���f�[�^�������Z�b�g
        ov_target_trx_cnt := ln_target_cnt;
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00302010);    -- �������z
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
--    END IF;
-- Modify 2009.12.28 Ver1.08 end
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_bill_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_invoice_header
   * Description      : �����w�b�_���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_invoice_header(
    iv_cust_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h
    id_cutoff_date          IN  DATE,         -- ����
    iv_cust_acct_name       IN  VARCHAR2,     -- ������ڋq��
    iv_cust_acct_id         IN  VARCHAR2,     -- ������ڋqID
    iv_cust_acct_site_id    IN  VARCHAR2,     -- ������ڋq���ݒnID
    iv_term_name            IN  VARCHAR2,     -- �x������
    iv_term_id              IN  NUMBER,       -- �x������ID
    iv_tax_div              IN  VARCHAR2,     -- ����ŋ敪
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_invoice_header'; -- �v���O������
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
    ln_target_cnt       NUMBER;                             -- �Ώی���
    lv_dict_err_code    VARCHAR2(20);                       -- ���{�ꎫ���Q�ƃR�[�h
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;  -- ���{�ꎫ�����[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    acct_info_required_expt  EXCEPTION;      -- �ڋq���K�{�G���[
-- Modify 2009.07.21 Ver1.03 start
    uniq_expt                EXCEPTION;      -- ��Ӑ���G���[
--
    PRAGMA EXCEPTION_INIT(uniq_expt, -1);    -- ��Ӑ���G���[
-- Modify 2009.07.21 Ver1.03 end
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
    lv_dict_err_code  := NULL;
    lt_look_dict_word := NULL;
--
    -- �O���[�o���ϐ�������
    gt_invoice_id            := NULL;      -- �ꊇ������ID
    gt_due_months_forword    := NULL;      -- �T�C�g����
    gt_month_remit           := NULL;      -- ����
    gt_payment_date          := NULL;      -- �x����
    gt_tax_type              := NULL;      -- ����ŋ敪
    gt_tax_gap_trx_id        := NULL;      -- �ō��z���ID
    gt_tax_gap_amount        := NULL;      -- �ō��z
    gt_postal_code           := NULL;      -- ���t��X�֔ԍ�
    gt_send_address1         := NULL;      -- ���t��Z��1
    gt_send_address2         := NULL;      -- ���t��Z��2
    gt_send_address3         := NULL;      -- ���t��Z��3
    gt_vender_code           := NULL;      -- �d����R�[�h
    gt_receipt_location_code := NULL;      -- �������_�R�[�h
    gt_bill_location_code    := NULL;      -- �������_�R�[�h
    gt_bill_location_name    := NULL;      -- �������_��
    gt_agent_tel_num         := NULL;      -- �S���d�b�ԍ�
    gt_credit_cust_code      := NULL;      -- �^�M��ڋq�R�[�h
    gt_credit_cust_name      := NULL;      -- �^�M��ڋq��
    gt_receipt_cust_code     := NULL;      -- ������ڋq�R�[�h
    gt_receipt_cust_name     := NULL;      -- ������ڋq��
    gt_payment_cust_code     := NULL;      -- �e������ڋq�R�[�h
    gt_payment_cust_name     := NULL;      -- �e������ڋq��
    gt_bill_cust_kana_name   := NULL;      -- ������ڋq�J�i��
    gt_bill_shop_code        := NULL;      -- ������X�܃R�[�h
    gt_bill_shop_name        := NULL;      -- ������X��
    gt_credit_receiv_code2   := NULL;      -- ���|�R�[�h2�i���Ə��j
    gt_credit_receiv_name2   := NULL;      -- ���|�R�[�h2�i���Ə��j����
    gt_credit_receiv_code3   := NULL;      -- ���|�R�[�h3�i���̑��j
    gt_credit_receiv_name3   := NULL;      -- ���|�R�[�h3�i���̑��j����
    gt_invoice_output_form   := NULL;      -- �������o�͌`��
    gt_tax_round_rule        := NULL;      -- �ŋ��|�[������
    gt_object_date_from      := NULL;      -- �Ώۊ��ԁi���j
-- Modify 2009.07.13 Ver1.02 start
    gt_bill_payment_term_id  := NULL;      -- �x������1
    gt_bill_payment_term2    := NULL;      -- �x������2
    gt_bill_payment_term3    := NULL;      -- �x������3
-- Modify 2009.07.13 Ver1.02 end
--
    --==============================================================
    --�w�b�_�f�[�^�擾����
    --==============================================================
    --�T�C�g�����A�����A�x�����̎擾
    BEGIN
      SELECT ratl.due_months_forward       due_months_forward, -- �T�C�g����
             TO_CHAR(ADD_MONTHS(id_cutoff_date + 1,
                                - 1 + ratl.due_months_forward),
                     'YYYYMMDD')           month_remit,        -- ����
             CASE WHEN ratl.due_day_of_month 
                         >= TO_NUMBER(
                              TO_CHAR(
                                LAST_DAY( ADD_MONTHS( id_cutoff_date,
                                                      ratl.due_months_forward)),
                                'DD'))
                  THEN LAST_DAY( ADD_MONTHS( id_cutoff_date, ratl.due_months_forward))
                  ELSE TO_DATE( TO_CHAR( ADD_MONTHS( id_cutoff_date,
                                                     ratl.due_months_forward),
                                         'YYYY/MM/') || 
                                TO_CHAR(ratl.due_day_of_month), 'YYYY/MM/DD')
             END                           payment_date        -- �x����
      INTO   gt_due_months_forword,
             gt_month_remit,
             gt_payment_date
      FROM   ra_terms_b        ratb,
             ra_terms_lines    ratl
      WHERE  ratb.term_id = ratl.term_id
      AND    ratb.term_id = iv_term_id
      AND    ROWNUM = 1
      ;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302011);    -- �T�C�g�����A�����A�x����
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --�ڋq���̎擾
    BEGIN
-- Modify 2009.08.03 Ver1.05 start
--      SELECT xxhv.bill_tax_div                        tax_type,               -- ����ŋ敪
      SELECT /*+ LEADING(xxhv.temp.bill_hzca_1 xxhv.temp.bill_hzca_2 xxhv.temp.ship_hzca_3 xxhv.temp.ship_hzca_4) 
                 USE_NL(xxhv.temp.bill_hasa_1 xxhv.temp.bill_hsua_1 xxhv.temp.bill_hzad_1 
                        xxhv.temp.bill_hzps_1 xxhv.temp.bill_hzlo_1 xxhv.temp.bill_hzcp_1 
                        xxhv.temp.ship_hzca_1 xxhv.temp.ship_hasa_1 xxhv.temp.ship_hsua_1 
                        xxhv.temp.ship_hzad_1 xxhv.temp.bill_hcar_1)
                 USE_NL(xxhv.temp.cash_hasa_2 xxhv.temp.cash_hzad_2 xxhv.temp.bill_hasa_2 
                        xxhv.temp.bill_hsua_2 xxhv.temp.bill_hzad_2 xxhv.temp.bill_hzps_2 
                        xxhv.temp.bill_hzlo_2 xxhv.temp.bill_hzcp_2 xxhv.temp.ship_hzca_2 
                        xxhv.temp.ship_hasa_2 xxhv.temp.ship_hsua_2 xxhv.temp.ship_hzad_2 
                        xxhv.temp.cash_hcar_2 xxhv.temp.bill_hcar_2)
                 USE_NL(xxhv.temp.cash_hzca_3 xxhv.temp.cash_hasa_3 xxhv.temp.cash_hzad_3 
                        xxhv.temp.bill_hasa_3 xxhv.temp.bill_hsua_3 
                        xxhv.temp.ship_hsua_3 xxhv.temp.bill_hzad_3 xxhv.temp.bill_hzps_3
                        xxhv.temp.bill_hzlo_3 xxhv.temp.bill_hzcp_3 xxhv.temp.cash_hcar_3)
                 USE_NL(xxhv.temp.bill_hasa_4 xxhv.temp.bill_hsua_4 xxhv.temp.ship_hsua_4
                        xxhv.temp.bill_hzad_4 xxhv.temp.bill_hzps_4 xxhv.temp.bill_hzlo_4
                        xxhv.temp.bill_hzcp_4)
              */
             xxhv.bill_tax_div                        tax_type,               -- ����ŋ敪
-- Modify 2009.08.03 Ver1.05 End
             NULL                                     tax_gap_trx_id,         -- �ō��z���ID
             0                                        tax_gap_amount,         -- �ō��z
             xxhv.bill_postal_code                    postal_code,            -- ���t��X�֔ԍ�
             xxhv.bill_state || xxhv.bill_city        send_address1,          -- ���t��Z��1
             xxhv.bill_address1                       send_address2,          -- ���t��Z��2
             xxhv.bill_address2                       send_address3,          -- ���t��Z��3
             xxhv.bill_torihikisaki_code              vender_code,            -- �d����R�[�h
             xxhv.cash_receiv_base_code               receipt_location_code,  -- �������_�R�[�h
             xxhv.bill_bill_base_code                 bill_location_code,     -- �������_�R�[�h
             xxcfr_common_pkg.get_cust_account_name(
               xxhv.bill_bill_base_code,
               cv_get_acct_name_f)                    bill_location_name,     -- �������_��
             xxcfr_common_pkg.get_base_target_tel_num(
               iv_cust_acct_code)                     agent_tel_num,          -- �S���d�b�ԍ�
             hzca.account_number                      credit_cust_code,       -- �^�M��ڋq�R�[�h
             xxcfr_common_pkg.get_cust_account_name(
               hzca.account_number,
               cv_get_acct_name_f)                    credit_cust_name,       -- �^�M��ڋq��
             xxhv.cash_account_number                 receipt_cust_code,      -- ������ڋq�R�[�h
             xxcfr_common_pkg.get_cust_account_name(
               xxhv.cash_account_number,
               cv_get_acct_name_f)                    receipt_cust_name,      -- ������ڋq��
             fnlv.lookup_code                         payment_cust_code,      -- �e������ڋq�R�[�h
             fnlv.meaning                             payment_cust_name,      -- �e������ڋq��
             xxcfr_common_pkg.get_cust_account_name(
               iv_cust_acct_code,
               cv_get_acct_name_k)                    bill_cust_kana_name,    -- ������ڋq�J�i��
             xxhv.bill_store_code                     bill_shop_code,         -- ������X�܃R�[�h
             xxhv.bill_cust_store_name                bill_shop_name,         -- ������X��
             xxhv.bill_cred_rec_code2                 credit_receiv_code2,    -- ���|�R�[�h2�i���Ə��j
             NULL                                     credit_receiv_name2,    -- ���|�R�[�h2�i���Ə��j����
             xxhv.bill_cred_rec_code3                 credit_receiv_code3,    -- ���|�R�[�h3�i���̑��j
             NULL                                     credit_receiv_name3,    -- ���|�R�[�h3�i���̑��j����
             xxhv.bill_invoice_type                   invoice_output_form,    -- �������o�͌`��
             xxhv.bill_tax_round_rule                         -- �ŋ��|�[������
-- Modify 2009.07.13 Ver1.02 start
            ,xxhv.bill_payment_term_id                bill_payment_term_id    -- �x������1
            ,xxhv.bill_payment_term2                  bill_payment_term2      -- �x������2
            ,xxhv.bill_payment_term3                  bill_payment_term3      -- �x������3
-- Modify 2009.07.13 Ver1.02 end
      INTO   gt_tax_type,               -- ����ŋ敪
             gt_tax_gap_trx_id,         -- �ō��z���ID
             gt_tax_gap_amount,         -- �ō��z
             gt_postal_code,            -- ���t��X�֔ԍ�
             gt_send_address1,          -- ���t��Z��1
             gt_send_address2,          -- ���t��Z��2
             gt_send_address3,          -- ���t��Z��3
             gt_vender_code,            -- �d����R�[�h
             gt_receipt_location_code,  -- �������_�R�[�h
             gt_bill_location_code,     -- �������_�R�[�h
             gt_bill_location_name,     -- �������_��
             gt_agent_tel_num,          -- �S���d�b�ԍ�
             gt_credit_cust_code,       -- �^�M��ڋq�R�[�h
             gt_credit_cust_name,       -- �^�M��ڋq��
             gt_receipt_cust_code,      -- ������ڋq�R�[�h
             gt_receipt_cust_name,      -- ������ڋq��
             gt_payment_cust_code,      -- �e������ڋq�R�[�h
             gt_payment_cust_name,      -- �e������ڋq��
             gt_bill_cust_kana_name,    -- ������ڋq�J�i��
             gt_bill_shop_code,         -- ������X�܃R�[�h
             gt_bill_shop_name,         -- ������X��
             gt_credit_receiv_code2,    -- ���|�R�[�h2�i���Ə��j
             gt_credit_receiv_name2,    -- ���|�R�[�h2�i���Ə��j����
             gt_credit_receiv_code3,    -- ���|�R�[�h3�i���̑��j
             gt_credit_receiv_name3,    -- ���|�R�[�h3�i���̑��j����
             gt_invoice_output_form,    -- �������o�͌`��
             gt_tax_round_rule          -- �ŋ��|�[������
-- Modify 2009.07.13 Ver1.02 start
            ,gt_bill_payment_term_id    -- �x������1
            ,gt_bill_payment_term2      -- �x������2
            ,gt_bill_payment_term3      -- �x������3
-- Modify 2009.07.13 Ver1.02 end
      FROM   xxcfr_cust_hierarchy_v    xxhv,       -- �ڋq�K�w�r���[
             hz_relationships          hzrl,       -- �p�[�e�B�֘A
             hz_cust_accounts          hzca,       -- (�^�M��)�ڋq�}�X�^
             fnd_lookup_values         fnlv        -- �N�C�b�N�R�[�h
      WHERE  xxhv.bill_account_id = iv_cust_acct_id
      AND    xxhv.bill_party_id = hzrl.object_id(+)
      AND    hzrl.status(+) = 'A'
      AND    hzrl.relationship_type(+) = gv_party_ref_type
      AND    hzrl.relationship_code(+) = gv_party_rev_code
      AND    gd_process_date BETWEEN TRUNC( NVL( hzrl.start_date(+), gd_process_date ) )
                                 AND TRUNC( NVL( hzrl.end_date(+),   gd_process_date ) )
      AND    hzrl.subject_id = hzca.party_id(+)
      AND    xxhv.bill_cred_rec_code1 = fnlv.lookup_code(+)
      AND    fnlv.lookup_type(+)  = cv_look_type_ar_cd
      AND    fnlv.language(+)     = USERENV( 'LANG' )
      AND    fnlv.enabled_flag(+) = 'Y'
      AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                 AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
      AND    ROWNUM = 1
      ;
    EXCEPTION
-- Modify 2009.12.28 Ver1.08 start
      -- *** NO_DATA_FOUND��O�n���h�� ***
      WHEN NO_DATA_FOUND THEN
        SELECT xxca.tax_div                             tax_type,               -- ����ŋ敪
               NULL                                     tax_gap_trx_id,         -- �ō��z���ID
               0                                        tax_gap_amount,         -- �ō��z
               hzlo_bill.postal_code                    postal_code,            -- ���t��X�֔ԍ�
               hzlo_bill.state || hzlo_bill.city        send_address1,          -- ���t��Z��1
               hzlo_bill.address1                       send_address2,          -- ���t��Z��2
               hzlo_bill.address2                       send_address3,          -- ���t��Z��3
               xxca.torihikisaki_code                   vender_code,            -- �d����R�[�h
               xxca.receiv_base_code                    receipt_location_code,  -- �������_�R�[�h
               xxca.bill_base_code                      bill_location_code,     -- �������_�R�[�h
               xxcfr_common_pkg.get_cust_account_name(
                 xxca.bill_base_code,
                 cv_get_acct_name_f)                    bill_location_name,     -- �������_��
               xxcfr_common_pkg.get_base_target_tel_num(
                 iv_cust_acct_code)                     agent_tel_num,          -- �S���d�b�ԍ�
               hzca.account_number                      credit_cust_code,       -- �^�M��ڋq�R�[�h
               xxcfr_common_pkg.get_cust_account_name(
                 hzca.account_number,
                 cv_get_acct_name_f)                    credit_cust_name,       -- �^�M��ڋq��
               iv_cust_acct_code                        receipt_cust_code,      -- ������ڋq�R�[�h
               iv_cust_acct_name                        receipt_cust_name,      -- ������ڋq��
               fnlv.lookup_code                         payment_cust_code,      -- �e������ڋq�R�[�h
               fnlv.meaning                             payment_cust_name,      -- �e������ڋq��
               xxcfr_common_pkg.get_cust_account_name(
                 iv_cust_acct_code,
                 cv_get_acct_name_k)                    bill_cust_kana_name,    -- ������ڋq�J�i��
               xxca.store_code                          bill_shop_code,         -- ������X�܃R�[�h
               xxca.cust_store_name                     bill_shop_name,         -- ������X��
               hsua_bill.attribute5                     credit_receiv_code2,    -- ���|�R�[�h2�i���Ə��j
               NULL                                     credit_receiv_name2,    -- ���|�R�[�h2�i���Ə��j����
               hsua_bill.attribute6                     credit_receiv_code3,    -- ���|�R�[�h3�i���̑��j
               NULL                                     credit_receiv_name3,    -- ���|�R�[�h3�i���̑��j����
               hsua_bill.attribute7                     invoice_output_form,    -- �������o�͌`��
               hsua_bill.tax_rounding_rule              bill_tax_round_rule,    -- �ŋ��|�[������
               hsua_bill.payment_term_id                bill_payment_term_id,   -- �x������1
               hsua_bill.attribute2                     bill_payment_term2,     -- �x������2
               hsua_bill.attribute3                     bill_payment_term3      -- �x������3
        INTO   gt_tax_type,               -- ����ŋ敪
               gt_tax_gap_trx_id,         -- �ō��z���ID
               gt_tax_gap_amount,         -- �ō��z
               gt_postal_code,            -- ���t��X�֔ԍ�
               gt_send_address1,          -- ���t��Z��1
               gt_send_address2,          -- ���t��Z��2
               gt_send_address3,          -- ���t��Z��3
               gt_vender_code,            -- �d����R�[�h
               gt_receipt_location_code,  -- �������_�R�[�h
               gt_bill_location_code,     -- �������_�R�[�h
               gt_bill_location_name,     -- �������_��
               gt_agent_tel_num,          -- �S���d�b�ԍ�
               gt_credit_cust_code,       -- �^�M��ڋq�R�[�h
               gt_credit_cust_name,       -- �^�M��ڋq��
               gt_receipt_cust_code,      -- ������ڋq�R�[�h
               gt_receipt_cust_name,      -- ������ڋq��
               gt_payment_cust_code,      -- �e������ڋq�R�[�h
               gt_payment_cust_name,      -- �e������ڋq��
               gt_bill_cust_kana_name,    -- ������ڋq�J�i��
               gt_bill_shop_code,         -- ������X�܃R�[�h
               gt_bill_shop_name,         -- ������X��
               gt_credit_receiv_code2,    -- ���|�R�[�h2�i���Ə��j
               gt_credit_receiv_name2,    -- ���|�R�[�h2�i���Ə��j����
               gt_credit_receiv_code3,    -- ���|�R�[�h3�i���̑��j
               gt_credit_receiv_name3,    -- ���|�R�[�h3�i���̑��j����
               gt_invoice_output_form,    -- �������o�͌`��
               gt_tax_round_rule          -- �ŋ��|�[������
              ,gt_bill_payment_term_id    -- �x������1
              ,gt_bill_payment_term2      -- �x������2
              ,gt_bill_payment_term3      -- �x������3
        FROM  xxcmm_cust_accounts       xxca,       -- �ڋq�ǉ����
              hz_cust_accounts          hzca_bill,  -- �ڋq�}�X�^
              hz_cust_acct_sites        hasa_bill,  -- �ڋq���ݒn
              hz_cust_site_uses         hsua_bill,  -- �ڋq�g�p�ړI
              hz_party_sites            hzps_bill,  -- �ڋq�p�[�e�B�T�C�g
              hz_locations              hzlo_bill,  -- �ڋq���Ə�
              hz_parties                hzpa,       -- �p�[�e�B
              hz_relationships          hzrl,       -- �p�[�e�B�֘A
              hz_cust_accounts          hzca,       -- (�^�M��)�ڋq�}�X�^
              fnd_lookup_values         fnlv        -- �N�C�b�N�R�[�h
        WHERE xxca.customer_id = iv_cust_acct_id
        AND   hzca_bill.cust_account_id = xxca.customer_id
        AND   hzpa.party_id = hzca_bill.party_id
        AND   hzpa.party_id = hzrl.object_id(+)
        AND   hzrl.status(+) = 'A'
        AND   hzrl.relationship_type(+) = gv_party_ref_type
        AND   hzrl.relationship_code(+) = gv_party_rev_code
        AND   gd_process_date BETWEEN TRUNC( NVL( hzrl.start_date(+), gd_process_date ) )
                                  AND TRUNC( NVL( hzrl.end_date(+),   gd_process_date ) )
        AND   hzrl.subject_id = hzca.party_id(+)
        AND   hasa_bill.cust_account_id = hzca_bill.cust_account_id
        AND   hsua_bill.cust_acct_site_id = hasa_bill.cust_acct_site_id
        AND   hsua_bill.site_use_code = 'BILL_TO'
        AND   hsua_bill.attribute4 = fnlv.lookup_code(+)     -- ���|�R�[�h�P
        AND   fnlv.lookup_type(+)  = cv_look_type_ar_cd
        AND   fnlv.language(+)     = USERENV( 'LANG' )
        AND   fnlv.enabled_flag(+) = 'Y'
        AND   gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                 AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
        AND   hzps_bill.party_site_id = hasa_bill.party_site_id
        AND   hzlo_bill.location_id = hzps_bill.location_id
        AND   ROWNUM = 1
        ;
-- Modify 2009.12.28 Ver1.08 end
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302012);    -- �����ڋq���
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --�擾���ڂ�NULL�`�F�b�N
    --==============================================================
    BEGIN
      --����ŋ敪
      IF (gt_tax_type IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302001;
        RAISE acct_info_required_expt;
      END IF;
--
      --�������o�͌`��
      IF (gt_invoice_output_form IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302002;
        RAISE acct_info_required_expt;
      END IF;
--
      --���|�R�[�h1(������)
      IF (gt_payment_cust_code IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302003;
        RAISE acct_info_required_expt;
      END IF;
--
      --�������_�R�[�h
      IF (gt_bill_location_code IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302004;
        RAISE acct_info_required_expt;
      END IF;
--
      --�ŋ��|�[������
      IF (gt_tax_round_rule IS NULL) THEN
        lv_dict_err_code := cv_dict_cfr_00302005;
        RAISE acct_info_required_expt;
      END IF;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => lv_dict_err_code);
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                      ,iv_name         => cv_msg_cfr_00031  
                                                      ,iv_token_name1  => cv_tkn_cust_code  
                                                      ,iv_token_value1 => iv_cust_acct_code
                                                      ,iv_token_name2  => cv_tkn_cust_name  
                                                      ,iv_token_value2 => iv_cust_acct_name
                                                      ,iv_token_name3  => cv_tkn_column  
                                                      ,iv_token_value3 => lt_look_dict_word)
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
        RETURN;
    END;
--
    --�Ώۊ��ԁi���j���
    BEGIN
      SELECT MAX(inlv.cutoff_date) + 1   object_date -- ���ߒ����̗���
      INTO   gt_object_date_from
      FROM   (
              --��1�x������(�O��)
              SELECT CASE WHEN DECODE(rv11.due_cutoff_day - 1, 0, 31, rv11.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv11.due_cutoff_day - 1, 0, 31, rv11.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv11           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id      = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term_id = rv11.term_id
              WHERE  rv11.term_id              = gt_bill_payment_term_id
-- Modify 2009.07.13 Ver1.02 start
              AND    rv11.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv11.start_date_active, gd_process_date)
                                         AND NVL(rv11.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --��1�x������(����)
              SELECT CASE WHEN DECODE(rv12.due_cutoff_day - 1, 0, 31, rv12.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv12.due_cutoff_day - 1, 0, 31, rv12.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv12           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id      = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term_id = rv12.term_id
              WHERE  rv12.term_id              = gt_bill_payment_term_id
-- Modify 2009.07.13 Ver1.02 start
              AND    rv12.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv12.start_date_active, gd_process_date)
                                         AND NVL(rv12.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --��2�x������(�O��)
              SELECT CASE WHEN DECODE(rv21.due_cutoff_day - 1, 0, 31, rv21.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv21.due_cutoff_day - 1, 0, 31, rv21.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv21           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term2 = rv21.term_id
              WHERE  rv21.term_id              = gt_bill_payment_term2
-- Modify 2009.07.13 Ver1.02 start
              AND    rv21.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv21.start_date_active, gd_process_date)
                                         AND NVL(rv21.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --��2�x������(����)
              SELECT CASE WHEN DECODE(rv22.due_cutoff_day - 1, 0, 31, rv22.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv22.due_cutoff_day - 1, 0, 31, rv22.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv22           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term2 = rv22.term_id
              WHERE  rv22.term_id              = gt_bill_payment_term2
-- Modify 2009.07.13 Ver1.02 start
              AND    rv22.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv22.start_date_active, gd_process_date)
                                         AND NVL(rv22.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --��3�x������(�O��)
              SELECT CASE WHEN DECODE(rv31.due_cutoff_day - 1, 0, 31, rv31.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)), 'DD')) 
                          THEN LAST_DAY(ADD_MONTHS(id_cutoff_date, -1)) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(ADD_MONTHS(id_cutoff_date, -1), 'YYYY/MM/') || 
                                   DECODE(rv31.due_cutoff_day - 1, 0, 31, rv31.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv31           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term3 = rv31.term_id
              WHERE  rv31.term_id              = gt_bill_payment_term3
-- Modify 2009.07.13 Ver1.02 start
              AND    rv31.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv31.start_date_active, gd_process_date)
                                         AND NVL(rv31.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
              UNION ALL
              --��3�x������(����)
              SELECT CASE WHEN DECODE(rv32.due_cutoff_day - 1, 0, 31, rv32.due_cutoff_day - 1)
                                 >= TO_NUMBER(TO_CHAR(LAST_DAY(id_cutoff_date), 'DD')) 
                          THEN LAST_DAY(id_cutoff_date) 
                          ELSE xxcfr_common_pkg.get_date_param_trans(
                                 TO_CHAR(id_cutoff_date, 'YYYY/MM/') || 
                                   DECODE(rv32.due_cutoff_day - 1, 0, 31, rv32.due_cutoff_day - 1))
                     END cutoff_date
              FROM   
-- Modify 2009.07.13 Ver1.02 start
--                     xxcfr_cust_hierarchy_v  xxhv,          -- �ڋq�K�w�r���[
-- Modify 2009.07.13 Ver1.02 end
                     ra_terms_vl             rv32           -- �x�������}�X�^
-- Modify 2009.07.13 Ver1.02 start
--              WHERE  xxhv.bill_account_id    = iv_cust_acct_id 
--              AND    xxhv.bill_payment_term3 = rv32.term_id
              WHERE  rv32.term_id              = gt_bill_payment_term3
-- Modify 2009.07.13 Ver1.02 start
              AND    rv32.due_cutoff_day IS NOT NULL        --���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
              AND    gd_process_date BETWEEN NVL(rv32.start_date_active, gd_process_date)
                                         AND NVL(rv32.end_date_active,   gd_process_date)
              AND    ROWNUM = 1
             ) inlv
      WHERE  inlv.cutoff_date < id_cutoff_date      -- ����
      ;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00302013);    -- �Ώۊ���(��)
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00015,  
                               iv_token_name1  => cv_tkn_data,  
                               iv_token_value1 => lt_look_dict_word),
                             1,
                             5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --�����w�b�_���e�[�u���o�^����
    --==============================================================
    BEGIN
      INSERT INTO xxcfr_invoice_headers(
        invoice_id,                        -- �ꊇ������ID
        set_of_books_id,                   -- ��v����ID
        cutoff_date,                       -- ����
        term_name,                         -- �x������
        term_id,                           -- �x������ID
        due_months_forword,                -- �T�C�g����
        month_remit,                       -- ����
        payment_date,                      -- �x����
        tax_type,                          -- ����ŋ敪
        tax_gap_trx_id,                    -- �ō��z���ID
        tax_gap_amount,                    -- �ō��z
        inv_amount_no_tax,                 -- �Ŕ��������z���v
        tax_amount_sum,                    -- �Ŋz���v
        inv_amount_includ_tax,             -- �ō��������z���v
        itoen_name,                        -- ����於
        postal_code,                       -- ���t��X�֔ԍ�
        send_address1,                     -- ���t��Z��1
        send_address2,                     -- ���t��Z��2
        send_address3,                     -- ���t��Z��3
        send_to_name,                      -- ���t�於
        inv_creation_date,                 -- �쐬��
        object_month,                      -- �Ώ۔N��
        object_date_from,                  -- �Ώۊ��ԁi���j
        object_date_to,                    -- �Ώۊ��ԁi���j
        vender_code,                       -- �d����R�[�h
        receipt_location_code,             -- �������_�R�[�h
        bill_location_code,                -- �������_�R�[�h
        bill_location_name,                -- �������_��
        agent_tel_num,                     -- �S���d�b�ԍ�
        credit_cust_code,                  -- �^�M��ڋq�R�[�h
        credit_cust_name,                  -- �^�M��ڋq��
        receipt_cust_code,                 -- ������ڋq�R�[�h
        receipt_cust_name,                 -- ������ڋq��
        payment_cust_code,                 -- �e������ڋq�R�[�h
        payment_cust_name,                 -- �e������ڋq��
        bill_cust_code,                    -- ������ڋq�R�[�h
        bill_cust_name,                    -- ������ڋq��
        bill_cust_kana_name,               -- ������ڋq�J�i��
        bill_cust_account_id,              -- ������ڋqID
        bill_cust_acct_site_id,            -- ������ڋq���ݒnID
        bill_shop_code,                    -- ������X�܃R�[�h
        bill_shop_name,                    -- ������X��
        credit_receiv_code2,               -- ���|�R�[�h2�i���Ə��j
        credit_receiv_name2,               -- ���|�R�[�h2�i���Ə��j����
        credit_receiv_code3,               -- ���|�R�[�h3�i���̑��j
        credit_receiv_name3,               -- ���|�R�[�h3�i���̑��j����
        invoice_output_form,               -- �������o�͌`��
        org_id,                            -- �g�DID
        created_by,                        -- �쐬��
        creation_date,                     -- �쐬��
        last_updated_by,                   -- �ŏI�X�V��
        last_update_date,                  -- �ŏI�X�V��
        last_update_login,                 -- �ŏI�X�V���O�C��
        request_id,                        -- �v��ID
        program_application_id,            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        program_id,                        -- �R���J�����g�E�v���O����ID
        program_update_date                -- �v���O�����X�V��
      ) VALUES (
        xxcfr_invoice_headers_s1.NEXTVAL,                             -- �ꊇ������ID
        gn_set_book_id,                                               -- ��v����ID
        id_cutoff_date,                                               -- ����
        iv_term_name,                                                 -- �x������
        iv_term_id,                                                   -- �x������ID
        gt_due_months_forword,                                        -- �T�C�g����
        gt_month_remit,                                               -- ����
        gt_payment_date,                                              -- �x����
        gt_tax_type,                                                  -- ����ŋ敪
        gt_tax_gap_trx_id,                                            -- �ō��z���ID
        gt_tax_gap_amount,                                            -- �ō��z
        gt_amount_no_tax,                                             -- �Ŕ��������z���v
        gt_tax_amount_sum,                                            -- �Ŋz���v
        gt_amount_includ_tax,                                         -- �ō��������z���v
        gt_itoen_name,                                                -- ����於
        gt_postal_code,                                               -- ���t��X�֔ԍ�
        gt_send_address1,                                             -- ���t��Z��1
        gt_send_address2,                                             -- ���t��Z��2
        gt_send_address3,                                             -- ���t��Z��3
        iv_cust_acct_name,                                            -- ���t�於
        cd_creation_date,                                             -- �쐬��
        TO_CHAR(id_cutoff_date, 'YYYYMM'),                            -- �Ώ۔N��
        gt_object_date_from,                                          -- �Ώۊ��ԁi���j
        id_cutoff_date,                                               -- �Ώۊ��ԁi���j
        gt_vender_code,                                               -- �d����R�[�h
        gt_receipt_location_code,                                     -- �������_�R�[�h
        gt_bill_location_code,                                        -- �������_�R�[�h
        gt_bill_location_name,                                        -- �������_��
        gt_agent_tel_num,                                             -- �S���d�b�ԍ�
        NVL(gt_credit_cust_code, iv_cust_acct_code),                  -- �^�M��ڋq�R�[�h
        NVL(gt_credit_cust_name, iv_cust_acct_name),                  -- �^�M��ڋq��
        gt_receipt_cust_code,                                         -- ������ڋq�R�[�h
        gt_receipt_cust_name,                                         -- ������ڋq��
        gt_payment_cust_code,                                         -- �e������ڋq�R�[�h
        gt_payment_cust_name,                                         -- �e������ڋq��
        iv_cust_acct_code,                                            -- ������ڋq�R�[�h
        iv_cust_acct_name,                                            -- ������ڋq��
        gt_bill_cust_kana_name,                                       -- ������ڋq�J�i��
        iv_cust_acct_id,                                              -- ������ڋqID
        iv_cust_acct_site_id,                                         -- ������ڋq���ݒnID
        gt_bill_shop_code,                                            -- ������X�܃R�[�h
        gt_bill_shop_name,                                            -- ������X��
        gt_credit_receiv_code2,                                       -- ���|�R�[�h2�i���Ə��j
        gt_credit_receiv_name2,                                       -- ���|�R�[�h2�i���Ə��j����
        gt_credit_receiv_code3,                                       -- ���|�R�[�h3�i���̑��j
        gt_credit_receiv_name3,                                       -- ���|�R�[�h3�i���̑��j����
        gt_invoice_output_form,                                       -- �������o�͌`��
        gn_org_id,                                                    -- �g�DID
        cn_created_by,                                                -- �쐬��
        cd_creation_date,                                             -- �쐬��
        cn_last_updated_by,                                           -- �ŏI�X�V��
        cd_last_update_date,                                          -- �ŏI�X�V��
        cn_last_update_login,                                         -- �ŏI�X�V���O�C��
        cn_request_id,                                                -- �v��ID
        cn_program_application_id,                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        cn_program_id,                                                -- �R���J�����g�E�v���O����ID
        cd_program_update_date                                        -- �v���O�����X�V��
      )
      RETURNING invoice_id INTO gt_invoice_id;                        -- �ꊇ������ID
--
    EXCEPTION
-- Modify 2009.07.21 Ver1.03 start
    -- *** ��Ӑ����O�n���h�� ***
      WHEN uniq_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr    
                              ,iv_name         => cv_msg_cfr_00077  
                              ,iv_token_name1  => cv_tkn_cut_date  
                              ,iv_token_value1 => TO_CHAR(id_cutoff_date, 'YYYY/MM/DD')
                              ,iv_token_name2  => cv_tkn_cust_code  
                              ,iv_token_value2 => iv_cust_acct_code
                              ,iv_token_name3  => cv_tkn_cust_name  
                              ,iv_token_value3 => iv_cust_acct_name)
                              ,1
                              ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
        RETURN;
-- Modify 2009.07.21 Ver1.03 end
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- �����w�b�_���e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --�����w�b�_���e�[�u���o�^�����J�E���g�A�b�v
    --==============================================================
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg || 
                     SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr,
                               iv_name         => cv_msg_cfr_00065,  --������ڋq�R�[�h���b�Z�[�W
                               iv_token_name1  => cv_tkn_cust_code,  
                               iv_token_value1 => iv_cust_acct_code),
                             1,
                             5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_invoice_header;
--
-- Modify 2009.09.29 Ver1.06 start
--  /**********************************************************************************
--   * Procedure Name   : update_tax_gap
--   * Description      : �ō��z�Z�o����(A-9)
--   ***********************************************************************************/
--  PROCEDURE update_tax_gap(
--    iv_cust_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h
--    id_cutoff_date          IN  DATE,         -- ����
--    iv_cust_acct_name       IN  VARCHAR2,     -- ������ڋq��
--    iv_cust_acct_id         IN  VARCHAR2,     -- ������ڋqID
--    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_tax_gap'; -- �v���O������
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
--    ln_target_cnt       NUMBER;                             -- �Ώی���
--    ln_upd_target_cnt   NUMBER;                             -- �X�V�Ώی���
--    ln_tax_gap_amount   NUMBER;                             -- �ō��z
--    lt_segment3         gl_code_combinations.segment3%TYPE; -- ����Ȗ�
--    lt_segment4         gl_code_combinations.segment4%TYPE; -- �⏕�Ȗ�
--    lv_dict_err_code    VARCHAR2(20);                       -- ���{�ꎫ���Q�ƃR�[�h
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;  -- ���{�ꎫ�����[�h
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- �ŃR�[�h�P�ʂ̐ō��z�f�[�^���o
--    CURSOR get_tax_gap_cur
--    IS
---- Modify 2009.07.13 Ver1.02 start
----      SELECT taxv.tax_rate                                       tax_rate,       -- �ŗ�
----             taxv.vat_tax_id                                     vat_tax_id,     -- �ŃR�[�hID
----             SUM(taxv.re_calc_tax_amount - taxv.sum_tax_amount)  tax_gap_amount, -- �ō��z
----             taxv.tax_code                                       tax_code        -- �ŃR�[�h
----      FROM   (
---- Modify 2009.07.13 Ver1.02 end
--        SELECT avta.tax_rate                        tax_rate,    -- �ŗ�
--               avta.vat_tax_id                      vat_tax_id,  -- �ŃR�[�hID
---- Modify 2009.07.13 Ver1.02 start
----               avta.tax_code                        tax_code,    -- �ŃR�[�h
------Modify 2009.04.20 Ver1.01 Start
------               DECODE(gt_tax_round_rule,
------                        'UP',      CEIL(ABS(SUM(rctl.taxable_amount) * avta.tax_rate / 100))
------                                     * SIGN(SUM(rctl.taxable_amount)),
------                        'DOWN',    TRUNC(SUM(rctl.taxable_amount) * avta.tax_rate / 100),
------                        'NEAREST', ROUND(SUM(rctl.taxable_amount) * avta.tax_rate / 100, 0)
------                     )                              re_calc_tax_amount,     -- ����Ŋz(�Čv�Z)
----               DECODE(gt_tax_round_rule,
----                        'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
----                                    * SIGN(SUM(rlli.extended_amount)),
----                        'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
----                        'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
----                     )                              re_calc_tax_amount,     -- ����Ŋz(�Čv�Z)  
------Modify 2009.04.20 Ver1.01 End        
----               SUM(rctl.extended_amount)            sum_tax_amount          -- ����Ŋz���v
--               DECODE(gt_tax_round_rule,
--                        'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
--                                    * SIGN(SUM(rlli.extended_amount)),
--                        'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
--                        'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
--               )
--             - SUM(rctl.extended_amount)            tax_gap_amount, -- ����Ŋz(�Čv�Z) - ����Ŋz���v
--               avta.tax_code                        tax_code        -- �ŃR�[�h
---- Modify 2009.07.13 Ver1.02 end
--        FROM   ra_customer_trx_all        rcta,                -- ����e�[�u��
--               ra_customer_trx_lines_all  rctl,                -- ������׃e�[�u��
----Modify 2009.04.20 Ver1.01 Start
--               ra_customer_trx_lines_all  rlli,                -- ������׃e�[�u���iLINE�j
----Modify 2009.04.20 Ver1.01 End
--               ar_vat_tax_all_b           avta                 -- �ŋ��}�X�^
--        WHERE  rctl.line_type = cv_line_type_tax               -- ���׃^�C�v
----Modify 2009.04.20 Ver1.01 Start       
----        AND    rctl.taxable_amount IS NOT NULL                 -- �ŋ��Ώۊz
----        AND    rctl.taxable_amount != 0                        -- �ŋ��Ώۊz
--        AND    rlli.extended_amount IS NOT NULL                 -- ���׋��z
--        AND    rlli.extended_amount != 0                        -- ���׋��z
----Modify 2009.04.20 Ver1.01 End
--        AND    avta.tax_rate IS NOT NULL                       -- �ŗ�
--        AND    avta.tax_rate != 0                              -- �ŗ�
--        AND    rcta.trx_date <= id_cutoff_date                 -- ����
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)       -- �������ۗ��X�e�[�^�X
--        AND    rcta.bill_to_customer_id = iv_cust_acct_id      -- ������ڋqID
--        AND    rcta.org_id          = gn_org_id                -- �g�DID
--        AND    rcta.set_of_books_id = gn_set_book_id           -- ��v����ID
--        AND    rcta.customer_trx_id = rctl.customer_trx_id
--        AND    avta.vat_tax_id = rctl.vat_tax_id  
--        AND    avta.validate_flag = 'Y'           
--        AND    gd_process_date BETWEEN NVL(avta.start_date, gd_process_date)
--                                   AND NVL(avta.end_date,   gd_process_date)
----Modify 2009.04.20 Ver1.01 Start   
--        AND    rctl.link_to_cust_trx_line_id = rlli.customer_trx_line_id
----Modify 2009.04.20 Ver1.01 End                                
--        GROUP BY avta.tax_rate,                                -- �ŗ�
--                 avta.vat_tax_id,                              -- �ŃR�[�hID
--                 avta.tax_code                                 -- �ŃR�[�h
---- Modify 2009.07.13 Ver1.02 start
----      ) taxv
----      HAVING SUM(taxv.sum_tax_amount - taxv.re_calc_tax_amount) != 0   -- �ō��z
----      GROUP BY taxv.tax_rate,
----               taxv.vat_tax_id,
----               taxv.tax_code
--      HAVING SUM(rctl.extended_amount) <> DECODE(gt_tax_round_rule,
--                                             'UP',     CEIL(ABS(SUM(rlli.extended_amount) * avta.tax_rate / 100))
--                                                         * SIGN(SUM(rlli.extended_amount)),
--                                             'DOWN',    TRUNC(SUM(rlli.extended_amount) * avta.tax_rate / 100),
--                                             'NEAREST', ROUND(SUM(rlli.extended_amount) * avta.tax_rate / 100, 0)
--                                          )    -- �ō��z
---- Modify 2009.07.13 Ver1.02 end
--      ;
----
--    TYPE l_get_tax_gap_rtype IS TABLE OF get_tax_gap_cur%ROWTYPE INDEX BY PLS_INTEGER;
--    lt_get_tax_gap_tab       l_get_tax_gap_rtype;
----
--    -- �ō��z�X�V�Ώۃf�[�^���o
--    CURSOR upd_inv_tax_gap_cur
--    IS
--      SELECT xxih.ROWID       row_id
--      FROM   xxcfr_invoice_headers xxih
--      WHERE  xxih.cutoff_date = id_cutoff_date            -- ����
--      AND    xxih.bill_cust_account_id = iv_cust_acct_id  -- ������ڋqID
--      AND    xxih.request_id = cn_request_id              -- �R���J�����g�v��ID
--      AND    xxih.org_id = gn_org_id                      -- �g�DID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- ��v����ID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE upd_inv_tax_gap_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
--    lt_upd_inv_tax_gap_tab    upd_inv_tax_gap_ttype;
----
--    -- *** ���[�J���E���R�[�h ***
----
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
--    -- ���[�J���ϐ��̏�����
--    ln_target_cnt     := 0;
--    ln_tax_gap_amount := 0;
--    lv_dict_err_code  := NULL;
--    lt_look_dict_word := NULL;
--    lt_segment3       := NULL;
--    lt_segment4       := NULL;
----
--    --==============================================================
--    --�������P�ʂ̏���Ŋz�̍Čv�Z����
--    --==============================================================
--    -- �J�[�\���I�[�v��
--    OPEN get_tax_gap_cur;
----
--    -- �f�[�^�̈ꊇ�擾
--    FETCH get_tax_gap_cur BULK COLLECT INTO lt_get_tax_gap_tab;
----
--    -- ���������̃Z�b�g
--    ln_target_cnt := lt_get_tax_gap_tab.COUNT;
----
--    -- �J�[�\���N���[�Y
--    CLOSE get_tax_gap_cur;
----
--    -- �Ώۃf�[�^����̏ꍇ�͐ō��z���Z�o
--    IF (ln_target_cnt > 0) THEN
----
--      <<gap_tax_calc_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--        ln_tax_gap_amount := ln_tax_gap_amount + lt_get_tax_gap_tab(ln_loop_cnt).tax_gap_amount;
--      END LOOP gap_tax_calc_loop;
----
--    -- �Ώۃf�[�^�Ȃ��̏ꍇ(�ō��z�Ȃ�)�A�ڍs�̏������s��Ȃ�
--    ELSE
--      RETURN;
--    END IF;
----
--    --==============================================================
--    --�ō��z�̍X�V����
--    --==============================================================
--    -- �ō��z��0�ł͂Ȃ��ꍇ
--    IF (ln_tax_gap_amount != 0) THEN
--      -- �����w�b�_���e�[�u�����b�N
--      -- �J�[�\���I�[�v��
--      OPEN upd_inv_tax_gap_cur;
----
--      -- �f�[�^�̈ꊇ�擾
--      FETCH upd_inv_tax_gap_cur BULK COLLECT INTO lt_upd_inv_tax_gap_tab;
----
--      -- ���������̃Z�b�g
--      ln_upd_target_cnt := lt_upd_inv_tax_gap_tab.COUNT;
----
--      -- �J�[�\���N���[�Y
--      CLOSE upd_inv_tax_gap_cur;
----
--      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���X�V����
--      IF (ln_upd_target_cnt > 0) THEN
--        BEGIN
--          <<upd_invoice_header_loop>>
--          FORALL ln_loop_cnt IN 1..ln_upd_target_cnt
--            UPDATE xxcfr_invoice_headers
--            SET    tax_gap_amount        = ln_tax_gap_amount,                         -- �ō��z
--                   tax_amount_sum        = tax_amount_sum + ln_tax_gap_amount,        -- �Ŋz���v
--                   inv_amount_includ_tax = inv_amount_includ_tax + ln_tax_gap_amount, -- �ō��������z���v
--                   last_updated_by       = cn_last_updated_by,                        -- �ŏI�X�V��
--                   last_update_date      = cd_last_update_date,                       -- �ŏI�X�V��
--                   last_update_login     = cn_last_update_login                       -- �ŏI�X�V���O�C��
--            WHERE  ROWID = lt_upd_inv_tax_gap_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00017      -- �e�[�u���X�V�G���[
--                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                           -- �����w�b�_���e�[�u��
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
--      END IF;
----
--      --==============================================================
--      --�ō��z����쐬�e�[�u���̓o�^�f�[�^���o����
--      --==============================================================
--      --�ō��z����p����ȖځE�⏕�Ȗڒ��o
--      BEGIN
--        SELECT inlv.segment3                segment3,
--               inlv.segment4                segment4
--        INTO   lt_segment3,
--               lt_segment4
--        FROM   (
--          SELECT glcc.segment3              segment3,
--                 glcc.segment4              segment4,
--                 SUM(rctl.extended_amount)  amount
--          FROM   ra_customer_trx_all            rcta
--                ,ra_customer_trx_lines_all      rctl
--                ,ra_cust_trx_line_gl_dist_all   rgda
--                ,gl_code_combinations           glcc
--          WHERE  rgda.account_class = cv_account_class_rec       -- ����敪
--          AND    rcta.trx_date <= id_cutoff_date                 -- ����
--          AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                     cv_inv_hold_status_r)       -- �������ۗ��X�e�[�^�X
--          AND    rcta.bill_to_customer_id = iv_cust_acct_id      -- ������ڋqID
--          AND    rcta.org_id          = gn_org_id                -- �g�DID
--          AND    rcta.set_of_books_id = gn_set_book_id           -- ��v����ID
--          AND    rcta.customer_trx_id = rctl.customer_trx_id
--          AND    rctl.customer_trx_id = rgda.customer_trx_id
--          AND    rgda.code_combination_id  = glcc.code_combination_id
--          GROUP BY glcc.segment3,
--                   glcc.segment4
--          ORDER BY amount DESC
--        ) inlv
--        WHERE  ROWNUM = 1
--        ;
----
--      EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00302014);    -- ����ȖځE�⏕�Ȗ�
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--      --==============================================================
--      --�ō��z����쐬�e�[�u���̓o�^����
--      --==============================================================
--      --�ō��z����쐬�e�[�u���̓o�^���[�v
--      <<ins_gap_tax_trx_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
----
--        --�ō��z����쐬�e�[�u���o�^����
--        BEGIN
--          INSERT INTO xxcfr_tax_gap_trx_list(
--            invoice_id,                   -- �ꊇ������ID
--            tax_code_id,                  -- �ŋ��R�[�hID
--            cutoff_date,                  -- ����
--            bill_cust_code,               -- ������ڋq�R�[�h
--            bill_cust_name,               -- ������ڋq��
--            tax_code,                     -- �ŃR�[�h
--            segment3,                     -- ����Ȗ�
--            segment4,                     -- �⏕�Ȗ�
--            tax_gap_amount,               -- �ō��z
--            note,                         -- ����
--            created_by,                   -- �쐬��
--            creation_date,                -- �쐬��
--            last_updated_by,              -- �ŏI�X�V��
--            last_update_date,             -- �ŏI�X�V��
--            last_update_login,            -- �ŏI�X�V���O�C��
--            request_id,                   -- �v��ID
--            program_application_id,       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--            program_id,                   -- �R���J�����g�E�v���O����ID
--            program_update_date           -- �v���O�����X�V��
--          )VALUES (
--            gt_invoice_id,                                                    -- �ꊇ������ID
--            lt_get_tax_gap_tab(ln_loop_cnt).vat_tax_id,                       -- �ŋ��R�[�hID
--            id_cutoff_date,                                                   -- ����
--            iv_cust_acct_code,                                                -- ������ڋq�R�[�h
--            iv_cust_acct_name,                                                -- ������ڋq��
--            lt_get_tax_gap_tab(ln_loop_cnt).tax_code,                         -- �ŃR�[�h
--            lt_segment3,                                                      -- ����Ȗ�
--            lt_segment4,                                                      -- �⏕�Ȗ�
--            lt_get_tax_gap_tab(ln_loop_cnt).tax_gap_amount,                   -- �ō��z
--            iv_cust_acct_name || '_' || TO_CHAR(id_cutoff_date, 'YYYY/MM/DD'),-- ����
--            cn_created_by,                                                    -- �쐬��
--            cd_creation_date,                                                 -- �쐬��
--            cn_last_updated_by,                                               -- �ŏI�X�V��
--            cd_last_update_date,                                              -- �ŏI�X�V��
--            cn_last_update_login,                                             -- �ŏI�X�V���O�C��
--            cn_request_id,                                                    -- �v��ID
--            cn_program_application_id,                                        -- �A�v���P�[�V����ID
--            cn_program_id,                                                    -- �v���O����ID
--            cd_program_update_date                                            -- �v���O�����X�V��
--          );
----
--        EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                                   ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxgt))
--                                                                             -- �ō��z����쐬�e�[�u��
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--      END LOOP ins_gap_tax_trx_loop;
----
--    END IF;
----
--  EXCEPTION
--    -- *** �e�[�u�����b�N�G���[�n���h�� ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
--                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- �����w�b�_���e�[�u��
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END update_tax_gap;
-- Modify 2009.09.29 Ver1.06 End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date            IN  VARCHAR2,     -- ����
    iv_bill_acct_code         IN  VARCHAR2,     -- ������ڋq�R�[�h
    iv_batch_on_judge_type    IN  VARCHAR2,     -- ��Ԏ蓮���f�敪
    ov_errbuf                 OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_target_trx_cnt   NUMBER; --�����Ώێ���f�[�^����
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
    -- <�J�[�\����>
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gv_conc_status := cv_status_normal;
--
-- Modify 2009.12.11 Ver1.07 start
    UPDATE ra_customer_trx_all update_tab
    SET 
    update_tab.attribute7 = 'INVALID',
    update_tab.last_update_date = cd_last_update_date,
    update_tab.last_updated_by = cn_last_updated_by,
    update_tab.last_update_login = cn_last_update_login,
    update_tab.request_id = cn_request_id,
    update_tab.program_application_id = cn_program_application_id,
    update_tab.program_id = cn_program_id,
    update_tab.program_update_date = cd_program_update_date
    WHERE update_tab.customer_trx_id IN
    (
    SELECT
    rcta.customer_trx_id
    FROM
    ra_customer_trx_all rcta,
    xxcmm_cust_accounts xxca
    WHERE rcta.bill_to_customer_id = xxca.customer_id
    AND xxca.card_company_div = '1'
    AND EXISTS (SELECT 'X'
                FROM 
                ra_cust_trx_line_gl_dist_all radist,
                gl_code_combinations gcc
                WHERE gcc.segment3 = '14903'
                AND gcc.code_combination_id = radist.code_combination_id
                AND radist.customer_trx_id = rcta.customer_trx_id)
    AND rcta.attribute7 = 'OPEN'
    );
-- Modify 2009.12.11 Ver1.07 end
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date          -- ����
      ,iv_bill_acct_code       -- ������ڋq�R�[�h
      ,iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- ���������n�e�[�u���o�^���� (A-2)
    -- =====================================================
    ins_inv_info_trans(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --��Ԏ蓮���f�敪�̔��f
    IF (iv_batch_on_judge_type = cv_judge_type_batch) THEN
      -- =====================================================
      -- �Ώې�����ڋq�擾����(���) (A-3)
      -- =====================================================
      ins_target_bill_acct_n(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    ELSE 
--
      -- =====================================================
      -- �Ώې�����ڋq�擾����(�蓮) (A-4)
      -- =====================================================
      ins_target_bill_acct_o(
         iv_bill_acct_code     -- ������ڋq�R�[�h
        ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- =====================================================
    -- �������Ώیڋq��񒊏o���� (A-5)
    -- =====================================================
    get_target_bill_acct(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --�����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      --�������I������
      RETURN;
    END IF;
--
    --���[�v
    <<for_loop>>
    FOR ln_loop_cnt IN gt_get_acct_code_tab.FIRST..gt_get_acct_code_tab.LAST LOOP
      --�ϐ�������
      ln_target_trx_cnt := 0;
--
      --��Ԏ蓮���f�敪�̔��f
      IF (iv_batch_on_judge_type != cv_judge_type_batch) THEN
        -- =====================================================
        -- �O�񏈗��f�[�^�폜���� (A-6)
        -- =====================================================
        delete_last_data(
           gt_get_acct_code_tab(ln_loop_cnt)     -- ������ڋq�R�[�h
          ,gt_get_cutoff_date_tab(ln_loop_cnt)   -- ����
          ,lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- =====================================================
      -- �����Ώێ���f�[�^�擾���� (A-7)
      -- =====================================================
      get_bill_info(
         gt_get_cust_acct_id_tab(ln_loop_cnt),   -- ������ڋqID
         gt_get_cutoff_date_tab(ln_loop_cnt),    -- ����
         ln_target_trx_cnt,                      -- �Ώێ������
         lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
         lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
         lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      IF (ln_target_trx_cnt > 0) THEN
        -- =====================================================
        -- �����w�b�_���o�^���� (A-8)
        -- =====================================================
        ins_invoice_header(
           gt_get_acct_code_tab(ln_loop_cnt),          -- ������ڋq�R�[�h
           gt_get_cutoff_date_tab(ln_loop_cnt),        -- ����
           gt_get_cust_name_tab(ln_loop_cnt),          -- ������ڋq��
           gt_get_cust_acct_id_tab(ln_loop_cnt),       -- ������ڋqID
           gt_get_cust_acct_site_id_tab(ln_loop_cnt),  -- ������ڋq���ݒnID
           gt_get_term_name_tab(ln_loop_cnt),          -- �x������
           gt_get_term_id_tab(ln_loop_cnt),            -- �x������ID
           gt_get_tax_div_tab(ln_loop_cnt),            -- ����ŋ敪
           lv_errbuf,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
           lv_retcode,                                 -- ���^�[���E�R�[�h             --# �Œ� #
           lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_warn)  THEN
          --(�x�������J�E���g�A�b�v)
          gn_error_cnt := gn_error_cnt + 1;
          --�x���t���O���Z�b�g
          gv_conc_status := cv_status_warn;
        ELSIF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
-- Modify 2009.09.29 Ver1.06 start
--        --�����w�b�_���e�[�u���ɓo�^�������A
--        --����ŋ敪���O�ł̏ꍇ
--        IF (gt_invoice_id IS NOT NULL) AND
--           (gt_get_tax_div_tab(ln_loop_cnt) = cv_tax_div_outtax)
--        THEN
--          -- =====================================================
--          -- �ō��z�Z�o���� (A-9)
--          -- =====================================================
--          update_tax_gap(
--             gt_get_acct_code_tab(ln_loop_cnt),      -- ������ڋq�R�[�h
--             gt_get_cutoff_date_tab(ln_loop_cnt),    -- ����
--             gt_get_cust_name_tab(ln_loop_cnt),      -- ������ڋq��
--             gt_get_cust_acct_id_tab(ln_loop_cnt),   -- ������ڋqID
--             lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
--             lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
--             lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          );
--          IF (lv_retcode = cv_status_error) THEN
--            --(�G���[����)
--            RAISE global_process_expt;
--          END IF;
--        END IF;
-- Modify 2009.09.29 Ver1.06 End
--
      --�����Ώێ���f�[�^�����݂��Ȃ������ꍇ
      ELSE
        -- �X�L�b�v�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
--
      END IF;
    END LOOP for_loop;
--
    -- �x���t���O���x���ƂȂ��Ă���ꍇ
    IF (gv_conc_status = cv_status_warn) THEN
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := cv_status_warn;
    END IF;
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
    errbuf                  OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W
    retcode                 OUT     VARCHAR2,         -- �G���[�R�[�h
    iv_target_date          IN      VARCHAR2,         -- ����
    iv_bill_acct_code       IN      VARCHAR2,         -- ������ڋq�R�[�h
    iv_batch_on_judge_type  IN      VARCHAR2          -- ��Ԏ蓮���f�敪
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- ���b�Z�[�W�R�[�h
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_target_date            -- ����
      ,iv_bill_acct_code         -- ������ڋq�R�[�h
      ,iv_batch_on_judge_type    -- ��Ԏ蓮���f�敪
      ,lv_errbuf                 -- �G���[�E���b�Z�[�W           
      ,lv_retcode                -- ���^�[���E�R�[�h             
      ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
    IF (lv_errmsg IS NOT NULL) THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I���X�e�[�^�X���ُ�I���̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
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
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFR003A02C;
/