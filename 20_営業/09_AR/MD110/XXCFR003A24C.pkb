CREATE OR REPLACE PACKAGE BODY XXCFR003A24C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCFR003A24C(body)
 * Description      : �������א�����ڋq���f
 * MD.050           : MD050_CFR_003_A24_�������א�����ڋq���f
 * MD.070           : MD050_CFR_003_A24_�������א�����ڋq���f
 * Version          : 1.01
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    p ��������(�����w�b�_�쐬)                (A-1)
 *  ins_target_bill_acct_n  p �Ώې�����ڋq�擾����                  (A-2)
 *  get_target_bill_acct    p �������Ώیڋq��񒊏o����              (A-3)
 *  ins_invoice_header      p �����w�b�_���o�^����                  (A-4)
 *  get_update_target_line  p �������׍X�V�Ώێ擾����                (A-5)
 *  update_invoice_lines_id p ����ID�X�V���� �������׏��e�[�u��     (A-6)
 *  get_update_target_bill  p �����X�V�Ώێ擾����                    (A-7)
 *  update_invoice_lines    p �������z�X�V���� �������׏��e�[�u��   (A-8)
 *  update_bill_amount      p �������z�X�V���� �����w�b�_���e�[�u�� (A-9)
 *
 *  submain                 p ���C�������v���V�[�W��
 *  main                    p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/10/20    1.00  SCSK �Ԓn �w     ����쐬 [E_�{�ғ�_19546] �������̏���Ŋz����
 *  2023/10/27    1.01  SCSK �Ԓn �w     [E_�{�ғ�_19546] �������̏���Ŋz���� �C��
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
  gn_ins_cnt       NUMBER;                    -- �o�b�N�A�b�v����
  gn_target_header_cnt    NUMBER;             -- �Ώی���(�����w�b�_�P��)
  gn_target_line_cnt      NUMBER;             -- �Ώی���(�������גP��)
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
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A24C'; -- �p�b�P�[�W��
  
  -- �v���t�@�C���I�v�V����
  ct_prof_name_itoen_name  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_GENERAL_INVOICE_ITOEN_NAME';   -- �ėp����������於
  cv_org_id                CONSTANT VARCHAR2(6)  := 'ORG_ID';                   -- �g�DID
  cv_set_of_books_id       CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';         -- ��v����ID
  cv_invoice_h_parallel_count CONSTANT VARCHAR2(36)
                                      := 'XXCFR1_INVOICE_HEADER_PARALLEL_COUNT';  -- XXCFR:�����w�b�_�p���������s��
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
  cv_msg_cfr_00077  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00077'; --��Ӑ���G���[���b�Z�[�W
  cv_msg_cfr_00132  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00132'; --���|�R�[�h1(������)�G���[���b�Z�[�W(EDI����)
  cv_msg_cfr_00133  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00133'; --���|�R�[�h1(������)�G���[���b�Z�[�W(�ɓ����W��)
  cv_msg_cfr_00134  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00134'; --�������o�͌`����`�����G���[���b�Z�[�W(0��)
  cv_msg_cfr_00135  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00135'; --�������o�͌`����`�����G���[���b�Z�[�W
  cv_msg_cfr_00146  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00146'; --�X�V�������b�Z�[�W
  cv_msg_cfr_00018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --���b�Z�[�W�^�C�g��(�w�b�_��)
  cv_msg_cfr_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --���b�Z�[�W�^�C�g��(���ו�)
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
  cv_dict_cfr_00303014  CONSTANT VARCHAR2(20) := 'CFR003A03014'; -- �����ΏۃR���J�����g�v��ID
--
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- �v���t�@�C���I�v�V������
  cv_tkn_func_name  CONSTANT VARCHAR2(30)  := 'FUNC_NAME';       -- �t�@���N�V������
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- �e�[�u����
  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- �ڋq�R�[�h
  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- �ڋq��
  cv_tkn_column     CONSTANT VARCHAR2(30)  := 'COLUMN';          -- �J������
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- �f�[�^
  cv_tkn_cut_date   CONSTANT VARCHAR2(30)  := 'CUTOFF_DATE';     -- ����
  cv_tkn_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';       -- �Q�ƃ^�C�v
  cv_tkn_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';       -- �Q�ƃR�[�h
  cv_tkn_bill_invoice_type  CONSTANT VARCHAR2(30)  := 'BILL_INVOICE_TYPE'; -- �������o�͌`��
--
  -- �g�pDB��
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- ���������n�e�[�u��
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- �������Ώیڋq���[�N�e�[�u��
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- �����w�b�_���e�[�u��
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- �������׏��e�[�u��
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- �ō��z����쐬�e�[�u��
  cv_table_xwil       CONSTANT VARCHAR2(100) := 'XXCFR_WK_INVOICE_LINES';      -- �������׏�񃏁[�N�e�[�u��
--
  -- �Q�ƃ^�C�v
  cv_look_type_ar_cd  CONSTANT VARCHAR2(100) := 'XXCMM_INVOICE_GRP_CODE';     -- ���|�R�[�h1(������)
  cv_inv_output_form_type  CONSTANT VARCHAR2(100) := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';  -- �������o�͌`��
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
  cv_inv_prt_type       CONSTANT VARCHAR2(1)  := '3';         -- �������o�͋敪 3(EDI)
  cv_delete_flag_yes    CONSTANT VARCHAR2(1)  := 'Y';         -- �O�񏈗��f�[�^�폜�t���O(Y)
  cv_delete_flag_no     CONSTANT VARCHAR2(1)  := 'N';         -- �O�񏈗��f�[�^�폜�t���O(N)
  cv_inv_creation_flag  CONSTANT VARCHAR2(1)  := 'Y';         -- �����쐬�Ώۃt���O(Y)
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- �؂�̂�
  cv_output_format_1               CONSTANT VARCHAR2(1)     :=   '1';      -- �������o�͌`���i�ɓ����W���j
  cv_output_format_4               CONSTANT VARCHAR2(1)     :=   '4';      -- �������o�͌`���i�Ǝ҈ϑ��j
  cv_output_format_5               CONSTANT VARCHAR2(1)     :=   '5';      -- �������o�͌`���i���s�Ȃ��j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
    TYPE inv_output_form_rtype IS RECORD(
      inv_output_form_code            fnd_lookup_values_vl.lookup_code%type     -- �������o�͌`��
     ,inv_output_form_name            fnd_lookup_values_vl.meaning%type         -- �������o�͌`������
    );
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
    TYPE inv_output_form_ttype        IS TABLE OF inv_output_form_rtype
                                                  INDEX BY fnd_lookup_values.lookup_code%TYPE;
    TYPE inv_output_form_sub_ttype    IS TABLE OF inv_output_form_rtype
                                                  INDEX BY BINARY_INTEGER;
    gt_get_acct_code_tab            get_acct_code_ttype;
    gt_get_cutoff_date_tab          get_cutoff_date_ttype;
    gt_get_cust_name_tab            get_cust_name_ttype;
    gt_get_cust_acct_id_tab         get_cust_acct_id_ttype;
    gt_get_cust_acct_site_id_tab    get_cust_acct_site_id_ttype;
    gt_get_term_name_tab            get_term_name_ttype;
    gt_get_term_id_tab              get_term_id_ttype;
    gt_get_tax_div_tab              get_tax_div_ttype;
    gt_get_bill_pub_cycle_tab       get_bill_pub_cycle_ttype;
    gt_inv_output_form_tab          inv_output_form_ttype;
    gt_inv_output_form_sub_tab      inv_output_form_sub_ttype;
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
  gt_target_request_id       xxcfr_inv_info_transfer.target_request_id%TYPE;    -- �����ΏۃR���J�����g�v��ID
  gv_party_ref_type          VARCHAR2(50);                                         -- �p�[�e�B�֘A�^�C�v(�^�M�֘A)
  gv_party_rev_code          VARCHAR2(50);                                         -- �p�[�e�B�֘A(���|�Ǘ���)
  gt_bill_payment_term_id    hz_cust_site_uses_all.payment_term_id%TYPE;           -- �x������1
  gt_bill_payment_term2      hz_cust_site_uses_all.attribute2%TYPE;                -- �x������2
  gt_bill_payment_term3      hz_cust_site_uses_all.attribute3%TYPE;                -- �x������3
  gn_parallel_count          NUMBER DEFAULT 0;                                     -- �����w�b�_�p���������s��

  TYPE get_inv_id_ttype          IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
                                                  INDEX BY PLS_INTEGER;
  TYPE get_amt_no_tax_ttype      IS TABLE OF xxcfr_invoice_headers.inv_amount_no_tax%TYPE
                                                  INDEX BY PLS_INTEGER;
  TYPE get_tax_amt_sum_ttype     IS TABLE OF xxcfr_invoice_headers.tax_amount_sum%TYPE
                                                  INDEX BY PLS_INTEGER;

  gt_get_inv_id_tab          get_inv_id_ttype;
  TYPE get_tax_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.tax_gap_amount%TYPE      INDEX BY PLS_INTEGER;
  TYPE get_inv_gap_amount_ttype    IS TABLE OF xxcfr_invoice_headers.inv_gap_amount%TYPE      INDEX BY PLS_INTEGER;
  TYPE get_invoice_tax_div_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_tax_div%TYPE     INDEX BY PLS_INTEGER;
  TYPE get_output_format_ttype     IS TABLE OF xxcfr_invoice_headers.output_format%TYPE       INDEX BY PLS_INTEGER;
--
  gt_invoice_tax_div_tab    get_invoice_tax_div_ttype;       -- ����������ŐϏグ�v�Z����
  gt_output_format_tab      get_output_format_ttype;         -- �������o�͌`��
  gt_tax_gap_amount_tab     get_tax_gap_amount_ttype;        -- �ō��z
  gt_tax_sum1_tab           get_tax_amt_sum_ttype;           -- �Ŋz���v�P
  gt_tax_sum2_tab           get_tax_amt_sum_ttype;           -- �Ŋz���v�Q
  gt_inv_gap_amount_tab     get_inv_gap_amount_ttype;        -- �{�̍��z
  gt_no_tax_sum1_tab        get_amt_no_tax_ttype;            -- �Ŕ����v�P
  gt_no_tax_sum2_tab        get_amt_no_tax_ttype;            -- �Ŕ����v�Q
  gt_tax_div_tab            get_tax_div_ttype;               -- ����ŋ敪
  cv_inv_type_no        CONSTANT VARCHAR2(2)  := '00';        -- �����敪(�ʏ�)
  cv_inv_type_re        CONSTANT VARCHAR2(2)  := '01';        -- �����敪(�Đ���)
  cv_tax_div_inslip     CONSTANT VARCHAR2(1)  := '2';         -- ����ŋ敪(����(�`�[))
  cv_tax_div_inunit     CONSTANT VARCHAR2(1)  := '3';         -- ����ŋ敪(����(�P��))
  cv_tax_div_notax      CONSTANT VARCHAR2(1)  := '4';         -- ����ŋ敪(��ې�)
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)  := 'XXCCP';
  cv_tkn_count          CONSTANT VARCHAR2(30) := 'COUNT';           -- ����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date          IN VARCHAR2,      -- ����
    iv_bill_acct_code       IN VARCHAR2,      -- ������ڋq�R�[�h
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
    --���̓p�����[�^���t�^�ϊ�����
    --==============================================================
--
    IF (iv_target_date IS NOT NULL) THEN
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
    --==============================================================
    -- �������o�͌`��
    --==============================================================
    BEGIN
      SELECT
        flv.lookup_code      lookup_code  -- �������o�͌`��
       ,flv.meaning          line_type    -- �������o�͌`������
      BULK COLLECT INTO
        gt_inv_output_form_sub_tab        -- �������o�͌`��
      FROM
        fnd_lookup_values    flv
      WHERE
          flv.lookup_type        = cv_inv_output_form_type
      AND flv.language           = USERENV( 'LANG' )
      AND flv.enabled_flag       = 'Y'
      AND gd_process_date  BETWEEN NVL( flv.start_date_active , gd_process_date )
                               AND NVL( flv.end_date_active , gd_process_date )
      ;
--
      IF( gt_inv_output_form_sub_tab.COUNT = 0) THEN
        RAISE NO_DATA_FOUND;
      END IF; 
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr           -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00134         -- �������o�͌`��
                             ,iv_token_name1  => cv_tkn_lookup_type       -- �g�[�N��'lookup_type'
                             ,iv_token_value1 => cv_inv_output_form_type) -- �Q�ƃ^�C�v
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || cv_msg_part || SQLERRM;
        RAISE global_api_expt;
    END;
--
    FOR i IN 1..gt_inv_output_form_sub_tab.COUNT LOOP
      gt_inv_output_form_tab( gt_inv_output_form_sub_tab( i ).inv_output_form_code ) := gt_inv_output_form_sub_tab( i );
    END LOOP;
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
    -- *** �ϊ���O�n���h�� ***
    WHEN VALUE_ERROR THEN
      ov_errmsg  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
   * Procedure Name   : ins_target_bill_acct_n
   * Description      : �Ώې�����ڋq�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE ins_target_bill_acct_n(
    iv_bill_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h
    iv_bill_acct_id         IN  VARCHAR2,     -- ������ڋqID
    iv_bill_acct_name       IN  VARCHAR2,     -- ������ڋq����
    id_cutoff_date          IN  DATE,         -- �U�֌�������̒���
    iv_term_name            IN  VARCHAR2,     -- �U�֌�������̎x������
    in_term_id              IN  NUMBER,       -- �U�֌�������̎x������ID
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
    ln_bill_cust_acct_site_id NUMBER;      -- ������ڋq���ݒnID
    lv_tax_div                VARCHAR2(1); -- ����ŋ敪
    lv_bill_pub_cycle         VARCHAR2(1); -- ���������s�T�C�N��
    
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
    -- �U�֐搿���ڋq�̏����擾����
    BEGIN
        SELECT hzsa.cust_acct_site_id    AS bill_cust_acct_site_id  -- ������ڋq���ݒnID
              ,xxca.tax_div              AS tax_div                 -- ����ŋ敪
              ,hzsu.attribute8           AS bill_pub_cycle          -- ���������s�T�C�N��
        INTO   ln_bill_cust_acct_site_id
              ,lv_tax_div
              ,lv_bill_pub_cycle
        FROM   hz_cust_site_uses_all     hzsu              -- �ڋq�g�p�ړI
              ,hz_cust_acct_sites_all    hzsa              -- �ڋq���ݒn
              ,hz_cust_accounts          hzca              -- �ڋq�}�X�^
              ,xxcmm_cust_accounts       xxca              -- �ڋq�ǉ����
              ,hz_customer_profiles      hzcp              -- �ڋq�v���t�@�C��
        WHERE  
                   hzca.cust_account_id = hzsa.cust_account_id  
            AND    hzsa.cust_acct_site_id = hzsu.cust_acct_site_id
            AND    hzca.cust_account_id = xxca.customer_id
            AND    hzsu.site_use_id = hzcp.site_use_id(+)
            AND    hzca.cust_account_id = hzcp.cust_account_id
            AND    hzsu.site_use_code = 'BILL_TO'                     -- �g�p�ړI�R�[�h(������)
            AND    hzsu.status = 'A'                                  -- �g�p�ړI�X�e�[�^�X = 'A'
            AND    hzcp.cons_inv_flag = 'Y'                           -- �ꊇ���������g�p�\FLAG('Y')
            AND    hzsa.org_id = gn_org_id                            -- �g�DID
            AND    hzsu.org_id = gn_org_id                            -- �g�DID
            AND    hzca.cust_account_id = iv_bill_acct_id
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_bill_cust_acct_site_id := NULL;
        lv_tax_div := NULL;
        lv_bill_pub_cycle := NULL;
    END;
--
    -- �Ώۃf�[�^�����ݎ�,�������Ώیڋq���[�N�e�[�u���o�^
    BEGIN
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
      ) VALUES (
         iv_bill_acct_code
        ,id_cutoff_date
        ,iv_bill_acct_name
        ,iv_bill_acct_id
        ,ln_bill_cust_acct_site_id
        ,iv_term_name
        ,in_term_id
        ,lv_tax_div
        ,lv_bill_pub_cycle
      )
      ;
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
   * Procedure Name   : get_target_bill_acct
   * Description      : �������Ώیڋq��񒊏o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_bill_acct(
    iv_bill_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h
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
      WHERE  bill_cust_code = iv_bill_acct_code
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
  /**********************************************************************************
   * Procedure Name   : ins_invoice_header
   * Description      : �����w�b�_���o�^����(A-4)
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
    iv_bill_acct_code       IN  VARCHAR2,     -- ������ڋq�R�[�h(�R���J�����g�p�����[�^)
    ov_invoice_id           OUT NUMBER,       -- �ꊇ������ID
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
    ln_target_inv_cnt   NUMBER;                             -- �Ώې�������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    acct_info_required_expt  EXCEPTION;      -- �ڋq���K�{�G���[
    uniq_expt                EXCEPTION;      -- ��Ӑ���G���[
--
    PRAGMA EXCEPTION_INIT(uniq_expt, -1);    -- ��Ӑ���G���[
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
    ln_target_inv_cnt := 0;
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
    gt_bill_payment_term_id  := NULL;      -- �x������1
    gt_bill_payment_term2    := NULL;      -- �x������2
    gt_bill_payment_term3    := NULL;      -- �x������3
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
            ,xxhv.bill_payment_term_id                bill_payment_term_id    -- �x������1
            ,xxhv.bill_payment_term2                  bill_payment_term2      -- �x������2
            ,xxhv.bill_payment_term3                  bill_payment_term3      -- �x������3
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
        AND   hsua_bill.status = 'A'
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
        IF (gt_invoice_output_form = cv_inv_prt_type ) THEN  -- '3'(EDI)
          -- EDI�����̏ꍇ
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr
                               ,iv_name         => cv_msg_cfr_00132
                               ,iv_token_name1  => cv_tkn_cust_code
                               ,iv_token_value1 => iv_cust_acct_code
                               ,iv_token_name2  => cv_tkn_cust_name
                               ,iv_token_value2 => iv_cust_acct_name)
                               ,1
                               ,5000);
        ELSE
          -- EDI�����ȊO�̏ꍇ
          IF ( gt_inv_output_form_tab.EXISTS( gt_invoice_output_form )) THEN
            -- �������o�͌`�����o�^����Ă���ꍇ
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( 
                                  iv_application  => cv_msg_kbn_cfr
                                 ,iv_name         => cv_msg_cfr_00133
                                 ,iv_token_name1  => cv_tkn_cust_code
                                 ,iv_token_value1 => iv_cust_acct_code
                                 ,iv_token_name2  => cv_tkn_cust_name
                                 ,iv_token_value2 => iv_cust_acct_name
                                 ,iv_token_name3  => cv_tkn_bill_invoice_type
                                 ,iv_token_value3 => gt_inv_output_form_tab( gt_invoice_output_form ).inv_output_form_name)
                                 ,1
                                 ,5000);
          ELSE
            -- �������o�͌`�����o�^����Ă��Ȃ��ꍇ
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr           -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00135         -- �������o�͌`��
                                 ,iv_token_name1  => cv_tkn_lookup_type       -- �g�[�N��'lookup_type'
                                 ,iv_token_value1 => cv_inv_output_form_type  -- �Q�ƃ^�C�v
                                 ,iv_token_name2  => cv_tkn_lookup_code       -- �g�[�N��'lookup_code'
                                 ,iv_token_value2 => gt_invoice_output_form)  -- �Q�ƃR�[�h
                                 ,1
                                 ,5000);
          END IF;
        END IF;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        ov_retcode := cv_status_warn;
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
                     ra_terms_vl             rv11           -- �x�������}�X�^
              WHERE  rv11.term_id              = gt_bill_payment_term_id
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
                     ra_terms_vl             rv12           -- �x�������}�X�^
              WHERE  rv12.term_id              = gt_bill_payment_term_id
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
                     ra_terms_vl             rv21           -- �x�������}�X�^
              WHERE  rv21.term_id              = gt_bill_payment_term2
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
                     ra_terms_vl             rv22           -- �x�������}�X�^
              WHERE  rv22.term_id              = gt_bill_payment_term2
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
                     ra_terms_vl             rv31           -- �x�������}�X�^
              WHERE  rv31.term_id              = gt_bill_payment_term3
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
                     ra_terms_vl             rv32           -- �x�������}�X�^
              WHERE  rv32.term_id              = gt_bill_payment_term3
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
    -- �ꊇ������ID�̔�
    ov_invoice_id := xxcfr_invoice_headers_s1.NEXTVAL;
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
        program_update_date,               -- �v���O�����X�V��
        parallel_type                      -- �p���������s�敪
      ) VALUES (
--        xxcfr_invoice_headers_s1.NEXTVAL,                             -- �ꊇ������ID
        ov_invoice_id,
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
        gt_target_request_id,                                         -- �v��ID
        cn_program_application_id,                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        cn_program_id,                                                -- �R���J�����g�E�v���O����ID
        cd_program_update_date,                                       -- �v���O�����X�V��
        gn_parallel_count                                             -- �p���������s�敪
      )
      RETURNING invoice_id INTO gt_invoice_id;                        -- �ꊇ������ID
--
    EXCEPTION
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
  /**********************************************************************************
   * Procedure Name   : update_invoice_lines_id
   * Description      : ����ID�X�V���� �������׏��e�[�u��(A-6)
   ***********************************************************************************/
  PROCEDURE update_invoice_lines_id(
    in_xih_invoice_id         IN  NUMBER,       -- �����w�b�_.������ID
    in_xil_invoice_id         IN  NUMBER,       -- ��������.������ID
    in_invoice_detail_num     IN  NUMBER,       -- �ꊇ����������No
    ov_errbuf                 OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_invoice_lines_id'; -- �v���O������
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
    -- �������׏��e�[�u���������z�X�V
    BEGIN
--
      UPDATE  xxcfr_invoice_lines  xxil   -- �������׏��e�[�u��
      SET     xxil.invoice_id         = in_xih_invoice_id         -- �X�V����ꊇ������ID
             ,xxil.invoice_detail_num = ( SELECT NVL(MAX(xxil.invoice_detail_num),0) + 1
                                          FROM   xxcfr_invoice_lines xxil
                                          WHERE  xxil.invoice_id = in_xih_invoice_id ) -- �C���{�C�X���הԍ��̍ő�l+1
             ,invoice_id_bef            = in_xil_invoice_id          -- �ꊇ������ID(�ŐV������K�p�O)
             ,invoice_detail_num_bef    = in_invoice_detail_num      -- �ꊇ����������No(�ŐV������K�p�O)
      WHERE   xxil.invoice_id = in_xil_invoice_id                    -- �ꊇ������ID
      AND     xxil.invoice_detail_num = in_invoice_detail_num        -- �ꊇ����������No
      ;
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- �f�[�^�X�V�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil)) -- �������׏��e�[�u��
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_invoice_lines_id;
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_line
   * Description      : �������׍X�V�Ώێ擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_update_target_line(
    iv_target_date          IN VARCHAR2,      -- ����
    iv_bill_acct_code       IN VARCHAR2,      -- ������ڋq�R�[�h
--    ov_target_trx_cnt       OUT NUMBER,       -- �Ώێ������
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_line'; -- �v���O������
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
    ln_xih_invoice_id    NUMBER;                       -- �����w�b�_.�ꊇ������ID
    ln_target_trx_cnt    NUMBER;                       -- �����Ώێ���f�[�^����
    lv_bill_acct_code    VARCHAR2(30);                      -- 
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
--
--    -- *** ���[�J���E�J�[�\�� ***
    --�������׏��f�[�^���b�N�J�[�\��
    CURSOR lock_target_inv_lines_cur
    IS
      SELECT  xxil.invoice_id         AS invoice_id    -- ������ID
      FROM    xxcfr_invoice_lines xxil              -- �������׏��e�[�u��
      WHERE   xxil.invoice_id IN
      ( SELECT xxih.invoice_id
        FROM xxcfr_invoice_headers xxih
        WHERE xxih.request_id = gt_target_request_id )
      FOR UPDATE NOWAIT
      ;
    --
    --�Ώې������׏��擾
    CURSOR get_target_inv_cur
    IS
      SELECT  xxil.invoice_id                     AS xil_invoice_id              -- ��������.�ꊇ������ID
             ,xxil.invoice_detail_num             AS xil_invoice_detail_num      -- ��������.�ꊇ����������No
             ,ship_cust_info.bill_account_id      AS mst_bill_account_id         -- �ڋq�K�w.������ڋqID
             ,ship_cust_info.bill_account_number  AS mst_bill_account_number     -- �ڋq�K�w.������ڋq�R�[�h
             ,ship_cust_info.bill_account_name    AS mst_bill_account_name       -- �ڋq�K�w.������ڋq����
             ,xxih.cutoff_date                    AS xih_cutoff_date             -- �����w�b�_.����
             ,xxih.term_name                      AS xih_term_name               -- �����w�b�_.�x������
             ,xxih.term_id                        AS xih_term_id                 -- �����w�b�_.�x������ID
      FROM    xxcfr_invoice_headers xxih                                         -- �����w�b�_���e�[�u��
             ,xxcfr_invoice_lines   xxil                                         -- �������׏��e�[�u��
             ,xxcfr_cust_hierarchy_v  ship_cust_info                             -- �ڋq�K�w�r���[
      WHERE   xxih.request_id = gt_target_request_id                             -- �R���J�����g�v��ID
      AND     xxil.invoice_id = xxih.invoice_id
      AND     ship_cust_info.ship_account_number = xxil.ship_cust_code
      AND     xxih.bill_cust_account_id != ship_cust_info.bill_account_id
      AND     xxih.invoice_output_form  != cv_inv_prt_type                       -- �U�֌������搿�����o�͌`��(EDI)�͏���
      ;
    --
    --�����w�b�_���擾
    CURSOR get_header_inf_cur( p_bill_cust_account_id number
                              ,p_cutoff_date date )
    IS
      SELECT  xxih.invoice_id                     AS xih_invoice_id             -- ��������.�ꊇ������ID
      FROM    xxcfr_invoice_headers xxih
      WHERE   xxih.cutoff_date = p_cutoff_date
      AND     xxih.bill_cust_account_id  = p_bill_cust_account_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    get_header_inf_rec  get_header_inf_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
--    ov_target_trx_cnt := 0;
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
    --==============================================================
    --���������n�e�[�u���f�[�^���o����
    --==============================================================
    -- �����ΏۃR���J�����g�v��ID���o
--
    BEGIN
      SELECT xiit.target_request_id  target_request_id
      INTO   gt_target_request_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.set_of_books_id = gn_set_book_id
      AND    xiit.org_id = gn_org_id
      ;
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303014);    -- �����ΏۃR���J�����g�v��ID
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
    --==============================================================
    --�������׃e�[�u�����b�N���擾����
    --==============================================================
    BEGIN
      OPEN lock_target_inv_lines_cur;
--
      CLOSE lock_target_inv_lines_cur;
--
    EXCEPTION
      -- *** �e�[�u�����b�N�G���[�n���h�� ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))  -- �������׏��e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date          -- ����
      ,lv_bill_acct_code       -- ������ڋq�R�[�h
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�������׏��X�V����
    --==============================================================
    --
    <<edit_loop>>
    FOR get_target_inv_rec IN get_target_inv_cur LOOP
--
      OPEN  get_header_inf_cur(get_target_inv_rec.mst_bill_account_id ,get_target_inv_rec.xih_cutoff_date);
      FETCH get_header_inf_cur INTO get_header_inf_rec;
--
      -- �����w�b�_.�ꊇ������ID
      ln_xih_invoice_id := get_header_inf_rec.xih_invoice_id;
--
      IF ( iv_bill_acct_code IS NULL ) THEN
        lv_bill_acct_code := get_target_inv_rec.mst_bill_account_number;
      ELSE 
        lv_bill_acct_code := iv_bill_acct_code;
      END IF;
--
      IF get_header_inf_cur%NOTFOUND  THEN
--
        -- �O���[�o���ϐ��̏�����
        gn_target_cnt  := 0;
        gn_normal_cnt  := 0;
        gn_error_cnt   := 0;
        gn_warn_cnt    := 0;
        gv_conc_status := cv_status_normal;
        gn_ins_cnt   := 0;
        
        -- ���b�Z�[�W�o��
        xxcfr_common_pkg.put_log_param(
           iv_which        => cv_file_type_out        -- ���b�Z�[�W�o��
          ,iv_conc_param1  => iv_target_date          -- ����
          ,iv_conc_param2  => lv_bill_acct_code       -- ������ڋq�R�[�h
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
          ,iv_conc_param2  => lv_bill_acct_code       -- ������ڋq�R�[�h
          ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
--
          -- =====================================================
          -- �Ώې�����ڋq�擾���� (A-2)
          -- =====================================================
          ins_target_bill_acct_n(
             lv_bill_acct_code     -- ������ڋq�R�[�h
            ,get_target_inv_rec.mst_bill_account_id     -- ������ڋqID
            ,get_target_inv_rec.mst_bill_account_name   -- ������ڋq����
            ,get_target_inv_rec.xih_cutoff_date         -- �U�֌�������̒���
            ,get_target_inv_rec.xih_term_name           -- �U�֌�������̎x������
            ,get_target_inv_rec.xih_term_id             -- �U�֌�������̎x������ID
            ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
        -- =====================================================
        -- �������Ώیڋq��񒊏o���� (A-3)
        -- =====================================================
        get_target_bill_acct(
           lv_bill_acct_code     -- ������ڋq�R�[�h
          ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
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
--          RETURN;
          CONTINUE;
        END IF;
--
        --���[�v
        <<for_loop>>
        FOR ln_loop_cnt IN gt_get_acct_code_tab.FIRST..gt_get_acct_code_tab.LAST LOOP
          --�ϐ�������
          ln_target_trx_cnt := 0;
--
            -- =====================================================
            -- �����w�b�_���o�^���� (A-4)
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
               lv_bill_acct_code,                          -- ������ڋq�R�[�h
               ln_xih_invoice_id,                          -- �����w�b�_.�ꊇ������ID
               lv_errbuf,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode,                                 -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            -- �w�b�_�쐬����
            gn_target_header_cnt := gn_target_header_cnt + 1;
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
        END LOOP for_loop;
--
        -- �x���t���O���x���ƂȂ��Ă���ꍇ
        IF (gv_conc_status = cv_status_warn) THEN
          -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
          ov_retcode := cv_status_warn;
        END IF;
        -- �����w�b�_�ڐA E
      END IF;
      CLOSE get_header_inf_cur;
--
      -- �������׍X�V(A-6)
      update_invoice_lines_id(
        ln_xih_invoice_id,                            -- �����w�b�_.�ꊇ������ID
        get_target_inv_rec.xil_invoice_id,            -- ��������.�ꊇ������ID
        get_target_inv_rec.xil_invoice_detail_num,    -- �ꊇ����������No
        lv_errbuf,                                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                                   -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
      --���׍X�V����
      gn_target_line_cnt := gn_target_line_cnt + 1;
    END LOOP edit_loop;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_update_target_line;
--
--
  /**********************************************************************************
   * Procedure Name   : update_invoice_lines
   * Description      : �������z�X�V���� �������׏��e�[�u��(A-8)
   ***********************************************************************************/
  PROCEDURE update_invoice_lines(
    in_invoice_id             IN  NUMBER,       -- ������ID
    in_invoice_detail_num     IN  NUMBER,       -- �ꊇ����������No
    in_tax_gap_amount         IN  NUMBER,       -- �ō��z
    in_tax_sum1               IN  NUMBER,       -- �Ŋz���v�P
    in_tax_sum2               IN  NUMBER,       -- �Ŋz���v�Q
    in_inv_gap_amount         IN  NUMBER,       -- �{�̍��z
    in_no_tax_sum1            IN  NUMBER,       -- �Ŕ����v�P
    in_no_tax_sum2            IN  NUMBER,       -- �Ŕ����v�Q
    iv_category               IN  VARCHAR2,     -- ���󕪗�
    iv_invoice_printing_unit  IN  VARCHAR2,     -- ����������P��
    iv_customer_for_sum       IN  VARCHAR2,     -- �ڋq(�W�v�p)
    iv_tax_div                IN  VARCHAR2,     -- ����ŋ敪
    ov_errbuf                 OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_invoice_lines'; -- �v���O������
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
    -- �������׏��e�[�u���������z�X�V
    BEGIN
--
      UPDATE  xxcfr_invoice_lines  xxil   -- �������׏��e�[�u��
      SET     xxil.tax_gap_amount        = in_tax_gap_amount         -- �ō��z
             ,xxil.tax_amount_sum        = in_tax_sum1               -- �Ŋz���v�P
             ,xxil.tax_amount_sum2       = in_tax_sum2               -- �Ŋz���v�Q
             ,xxil.inv_gap_amount        = in_inv_gap_amount         -- �{�̍��z
             ,xxil.inv_amount_sum        = in_no_tax_sum1            -- �Ŕ����v�P
             ,xxil.inv_amount_sum2       = in_no_tax_sum2            -- �Ŕ����v�Q
             ,xxil.category              = iv_category               -- ���󕪗�
             ,xxil.invoice_printing_unit = iv_invoice_printing_unit  -- ����������P��
             ,xxil.customer_for_sum      = iv_customer_for_sum       -- �ڋq(�W�v�p)
      WHERE   xxil.invoice_id = in_invoice_id                        -- �ꊇ������ID
      AND     xxil.invoice_detail_num = in_invoice_detail_num        -- �ꊇ����������No
      ;
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- �f�[�^�X�V�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil)) -- �������׏��e�[�u��
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_invoice_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_bill
   * Description      : �����X�V�Ώێ擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_update_target_bill(
    ov_target_trx_cnt       OUT NUMBER,       -- �Ώێ������
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_bill'; -- �v���O������
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
    ln_int             PLS_INTEGER := 0;
    lt_invoice_id      xxcfr_invoice_headers.invoice_id%TYPE;     -- �ꊇ������ID
    lt_tax_gap_amount  xxcfr_invoice_lines.tax_gap_amount%TYPE;   -- �ō��z
    lt_tax_sum1        xxcfr_invoice_lines.tax_amount_sum%TYPE;   -- �Ŋz���v�P
    lt_inv_gap_amount  xxcfr_invoice_lines.inv_gap_amount%TYPE;   -- �{�̍��z
    lt_no_tax_sum1     xxcfr_invoice_lines.inv_amount_sum%TYPE;   -- �Ŕ����v�P
--
    -- *** ���[�J���E�J�[�\�� ***
    --�Ώې��������f�[�^���b�N�J�[�\��
    CURSOR lock_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id         invoice_id    -- ������ID
      FROM    xxcfr_invoice_headers xxih            -- �����w�b�_���e�[�u��
      WHERE   xxih.request_id = gt_target_request_id   -- �R���J�����g�v��ID
      FOR UPDATE NOWAIT
      ;
--
   --�������׏��f�[�^���b�N�J�[�\��
    CURSOR lock_target_inv_lines_cur
    IS
      SELECT  xxil.invoice_id         invoice_id    -- ������ID
      FROM    xxcfr_invoice_lines xxil              -- �������׏��e�[�u��
      WHERE   EXISTS (SELECT 1 
                      FROM xxcfr_invoice_headers xxih            -- �����w�b�_���e�[�u��
                      WHERE  xxih.invoice_id = xxil.invoice_id
                      AND    xxih.request_id = gt_target_request_id   -- �R���J�����g�v��ID
                     )
      FOR UPDATE NOWAIT
      ;
--
    --
    CURSOR get_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id                 invoice_id    -- ������ID
             ,MIN(xxil.invoice_detail_num)    invoice_detail_num     -- �ꊇ����������No
             ,SUM(NVL(xxil.ship_amount, 0))   ship_amount   -- �Ŕ��z���v
             ,SUM(NVL(xxil.tax_amount, 0))    tax_amount    -- �Ŋz���v
             ,SUM(NVL(xxil.ship_amount, 0) + NVL(xxil.tax_amount, 0)) sold_amount  -- �ō��z���v
             ,flv.attribute2                  category               -- ���󕪗�
             ,DECODE(xcal.invoice_printing_unit,
                     '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                     '3',xxih.bill_cust_code,
                     '4',xcal20.customer_code || xcal.bill_base_code,
                     '5',xcal14.customer_code || xcal.bill_base_code,
                     '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                     '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                     'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
                                              customer_for_sum       -- �ڋq(�W�v�p)
             ,xxih.invoice_output_form        output_format          -- �������o�͌`��
             ,xxil.tax_rate                   tax_rate               -- ����ŗ�
             ,NVL(xxca.invoice_tax_div,'N')   invoice_tax_div        -- ����������ŐϏグ�v�Z����
             ,xxca.tax_div                    tax_div                -- ����ŋ敪
             ,xcal.invoice_printing_unit      invoice_printing_unit  -- ����������P��
      FROM    xxcfr_invoice_headers xxih                          -- �����w�b�_���e�[�u��
             ,xxcfr_invoice_lines   xxil                          -- �������׏��e�[�u��
             ,xxcmm_cust_accounts   xxca                          -- �ڋq�ǉ����
             ,fnd_lookup_values     flv                           -- �Q�ƕ\�i�ŕ��ށj
             ,xxcmm_cust_accounts   xcal20                        -- �ڋq�ǉ����(�������p�ڋq)
             ,xxcmm_cust_accounts   xcal14                        -- �ڋq�ǉ����(�������p�ڋq)
             ,xxcmm_cust_accounts   xcal                          -- �ڋq�ǉ����(�[�i��ڋq)
      WHERE   xxih.request_id = gt_target_request_id              -- �R���J�����g�v��ID
      AND     xxih.invoice_output_form IN ( '1', '4', '5' )
      AND     xxih.invoice_id = xxil.invoice_id
      AND     xxca.customer_id = xxih.bill_cust_account_id
      AND     flv.lookup_type(+)        = 'XXCFR1_TAX_CATEGORY'   -- �ŕ���
      AND     flv.lookup_code(+)        = xxil.tax_code           -- �Q�ƕ\�i�ŕ��ށj.���b�N�A�b�v�R�[�h = ��������.�ŋ��R�[�h
      AND     flv.language(+)           = USERENV( 'LANG' )
      AND     flv.enabled_flag(+)       = 'Y'
      AND     flv.attribute2(+)         IS NOT NULL               -- ���󕪗�
      AND     xxil.ship_cust_code       = xcal.customer_code
      AND     xcal20.customer_code(+)   = xcal.invoice_code
      AND     xcal14.customer_code(+)   = xxih.bill_cust_code
      GROUP BY xxih.invoice_id
              ,flv.attribute2                  -- ���󕪗�
              ,DECODE(xcal.invoice_printing_unit,
                      '0',xxil.ship_cust_code,'1',xcal.invoice_code,'2',xxil.ship_cust_code,
                      '3',xxih.bill_cust_code,
                      '4',xcal20.customer_code || xcal.bill_base_code,
                      '5',xcal14.customer_code || xcal.bill_base_code,
                      '6',xcal.invoice_code,  '7',xcal.invoice_code,'8',xcal20.enclose_invoice_code,
                      '9',xxih.bill_cust_code,'A',xxih.bill_cust_code,'B',xxih.bill_cust_code,
                      'C',xxih.bill_cust_code,'D',xxil.ship_cust_code, null)
              ,xxih.invoice_output_form        -- �������o�͌`��
              ,xxil.tax_rate                   -- �ŗ�
              ,NVL(xxca.invoice_tax_div,'N')   -- ����������ŐϏグ�v�Z����
              ,xxca.tax_div                    -- ����ŋ敪
              ,xcal.invoice_printing_unit      -- ����������P��
      ORDER BY 
               invoice_id
              ,category
              ,customer_for_sum
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    get_target_inv_rec  get_target_inv_cur%ROWTYPE;
--
    -- *** ���[�J���E�t�@���N�V���� ***
    -- �Ŋz���v�P�i�Ŕ����j�Z�o����
    FUNCTION calc_tax_sum1(
       it_ship_amount        IN   xxcfr_invoice_lines.ship_amount%TYPE      -- �Ŕ��z���v
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- ����ŗ�
    ) RETURN NUMBER
    IS
--
      ln_tax_sum1  NUMBER;          -- �߂�l�F�Ŋz���v�P
--
    BEGIN
      ln_tax_sum1 := 0;
      -- �����_�ȉ��̒[����؂�̂Ă��܂��B
      ln_tax_sum1 := TRUNC( it_ship_amount * ( it_tax_rate / 100 ) );
--
      RETURN ln_tax_sum1;
    END calc_tax_sum1;
--
    -- *** ���[�J���E�t�@���N�V���� ***
    -- �Ŕ����v�P�Z�o����
    FUNCTION calc_no_tax_sum1(
       it_sold_amount        IN   xxcfr_invoice_lines.sold_amount%TYPE      -- �ō��z���v
      ,it_tax_rate           IN   xxcfr_invoice_lines.tax_rate%TYPE         -- ����ŗ�
    ) RETURN NUMBER
    IS
--
      ln_no_tax_sum1  NUMBER;          -- �߂�l�F�Ŕ����v�P
--
    BEGIN
      ln_no_tax_sum1 := 0;
      -- �����_�ȉ��̒[����؂�̂Ă��܂��B
      ln_no_tax_sum1 := TRUNC( it_sold_amount / ( it_tax_rate / 100 + 1 ) );
--
      RETURN ln_no_tax_sum1;
    END calc_no_tax_sum1;
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
    ov_target_trx_cnt := 0;
--
    --==============================================================
    --�����e�[�u�����b�N���擾����
    --==============================================================
    BEGIN
      OPEN lock_target_inv_cur;
--
      CLOSE lock_target_inv_cur;
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
    --==============================================================
    --�������׃e�[�u�����b�N���擾����
    --==============================================================
    BEGIN
      OPEN lock_target_inv_lines_cur;
--
      CLOSE lock_target_inv_lines_cur;
--
    EXCEPTION
      -- *** �e�[�u�����b�N�G���[�n���h�� ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))  -- �������׏��e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --�������׏��X�V����
    --==============================================================
    --
    <<edit_loop>>
    FOR get_target_inv_rec IN get_target_inv_cur LOOP
--
      --����A���́A�ꊇ������ID���ς�����ꍇ�u���[�N
      IF (
           ( lt_invoice_id IS NULL )
           OR
           ( lt_invoice_id <> get_target_inv_rec.invoice_id )
         )
      THEN
        --�������A�y�сA�P���R�[�h�ڂ̐ŕʍ��ڐݒ�
        ln_int                           := ln_int + 1;                             -- �z��J�E���g�A�b�v
        gt_get_inv_id_tab(ln_int)        := get_target_inv_rec.invoice_id;          -- �ꊇ������ID
        gt_invoice_tax_div_tab(ln_int)   := get_target_inv_rec.invoice_tax_div;     -- ����������ŐϏグ�v�Z����
        gt_output_format_tab(ln_int)     := get_target_inv_rec.output_format;       -- �������o�͌`��
        gt_tax_div_tab(ln_int)           := get_target_inv_rec.tax_div;             -- ����ŋ敪
--
        lt_tax_sum1       := 0;  -- �Ŋz���v�P
        lt_no_tax_sum1    := 0;  -- �Ŕ����v�P
        lt_tax_gap_amount := 0;  -- �ō��z
        lt_inv_gap_amount := 0;  -- �{�̍��z
        --
        -- �Ŕ����i����ŋ敪�F�O�ŁA��ېŁj
        IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
          -- �Ŋz���v�P�i�Ŕ����j�Z�o����
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
             lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                          ,get_target_inv_rec.tax_rate );
          END IF;
          -- �Ŕ����v�P�͎擾�����Ŕ��z���v
          lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
          -- �{�̍��z��0
          lt_inv_gap_amount := 0;
        --
        -- �ō��݁i����ŋ敪�F����(�`�[)�A����(�P��)�j
        ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
          -- �Ŕ����v�P�Z�o����
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
            lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                               ,get_target_inv_rec.tax_rate );
          END IF;
          -- �Ŋz���v�P
          lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
          -- �{�̍��z
          -- ����������ŐϏグ�v�Z������Y�̏ꍇ��0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_inv_gap_amount := 0;
          ELSE
          -- ����������ŐϏグ�v�Z������Y�ȊO�̏ꍇ�A�Ŕ����v�P �|�Ŕ����v�Q
             lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
          END IF;
        END IF;
        -- �ō��z
        -- ����������ŐϏグ�v�Z������Y�̏ꍇ��0
        IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
           lt_tax_gap_amount := 0;
        ELSE
        -- ����������ŐϏグ�v�Z������Y�ȊO�̏ꍇ�A�Ŋz���v�P �|�Ŋz���v�Q
           lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
        END IF;
--
        -- �����w�b�_�X�V�p�Ƀf�[�^��ێ����܂�
        gt_tax_gap_amount_tab(ln_int) := lt_tax_gap_amount;                      -- �ō��z
        gt_tax_sum1_tab(ln_int)       := lt_tax_sum1;                            -- �Ŋz���v�P
        gt_tax_sum2_tab(ln_int)       := get_target_inv_rec.tax_amount;          -- �Ŋz���v�Q
        gt_inv_gap_amount_tab(ln_int) := lt_inv_gap_amount;                      -- �{�̍��z
        gt_no_tax_sum1_tab(ln_int)    := lt_no_tax_sum1;                         -- �Ŕ����v�P
        gt_no_tax_sum2_tab(ln_int)    := get_target_inv_rec.ship_amount;         -- �Ŕ����v�Q
        lt_invoice_id                 := get_target_inv_rec.invoice_id;          -- �u���[�N�R�[�h�ݒ�
--
        -- �������׍X�V(A-8)
        update_invoice_lines(
          get_target_inv_rec.invoice_id,             -- ������ID
          get_target_inv_rec.invoice_detail_num,     -- �ꊇ����������No
          lt_tax_gap_amount,                         -- �ō��z
          lt_tax_sum1,                               -- �Ŋz���v�P
          get_target_inv_rec.tax_amount,             -- �Ŋz���v�Q
          lt_inv_gap_amount,                         -- �{�̍��z
          lt_no_tax_sum1,                            -- �Ŕ����v�P
          get_target_inv_rec.ship_amount,            -- �Ŕ����v�Q
          get_target_inv_rec.category,               -- ���󕪗�
          get_target_inv_rec.invoice_printing_unit,  -- ����������P��
          get_target_inv_rec.customer_for_sum,       -- �ڋq(�W�v�p)
          get_target_inv_rec.tax_div,                -- ����ŋ敪
          lv_errbuf,                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                                -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      ELSE
        -- 2���R�[�h�ڈȍ~
        lt_tax_sum1       := 0;  -- �Ŋz���v�P
        lt_no_tax_sum1    := 0;  -- �Ŕ����v�P
        lt_tax_gap_amount := 0;  -- �ō��z
        lt_inv_gap_amount := 0;  -- �{�̍��z
        --
        -- �Ŕ����i����ŋ敪�F�O�ŁA��ېŁj
        IF ( get_target_inv_rec.tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) ) THEN
          -- �Ŋz���v�P�i�Ŕ����j�Z�o����
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
             lt_tax_sum1 := calc_tax_sum1( get_target_inv_rec.ship_amount
                                          ,get_target_inv_rec.tax_rate );
          END IF;
          -- �Ŕ����v�P�͎擾�����Ŕ��z���v
          lt_no_tax_sum1 := get_target_inv_rec.ship_amount;
          -- �{�̍��z��0
          lt_inv_gap_amount := 0;
        --
        -- �ō��݁i����ŋ敪�F����(�`�[)�A����(�P��)�j
        ELSIF ( get_target_inv_rec.tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
          -- �Ŕ����v�P�Z�o����
          IF( get_target_inv_rec.tax_rate IS NOT NULL ) THEN
            lt_no_tax_sum1 := calc_no_tax_sum1( get_target_inv_rec.sold_amount
                                               ,get_target_inv_rec.tax_rate );
          END IF;
          -- �Ŋz���v�P
          lt_tax_sum1 := get_target_inv_rec.sold_amount - lt_no_tax_sum1;
          -- �{�̍��z
          -- ����������ŐϏグ�v�Z������Y�̏ꍇ��0
          IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
             lt_inv_gap_amount := 0;
          ELSE
          -- ����������ŐϏグ�v�Z������Y�ȊO�̏ꍇ�A�Ŕ����v�P �|�Ŕ����v�Q
             lt_inv_gap_amount := lt_no_tax_sum1 - get_target_inv_rec.ship_amount;
          END IF;
        END IF;
        -- �ō��z
        -- ����������ŐϏグ�v�Z������Y�̏ꍇ��0
        IF ( get_target_inv_rec.invoice_tax_div = 'Y' ) THEN
           lt_tax_gap_amount := 0;
        ELSE
        -- ����������ŐϏグ�v�Z������Y�ȊO�̏ꍇ�A�Ŋz���v�P �|�Ŋz���v�Q
           lt_tax_gap_amount := lt_tax_sum1 - get_target_inv_rec.tax_amount;
        END IF;
--
        -- �����w�b�_�X�V�p�Ƀf�[�^��ێ����܂�
        gt_tax_gap_amount_tab(ln_int) := gt_tax_gap_amount_tab(ln_int) + lt_tax_gap_amount;                -- �ō��z
        gt_tax_sum1_tab(ln_int)       := gt_tax_sum1_tab(ln_int) + lt_tax_sum1;                            -- �Ŋz���v�P
        gt_tax_sum2_tab(ln_int)       := gt_tax_sum2_tab(ln_int) + get_target_inv_rec.tax_amount;          -- �Ŋz���v�Q
        gt_inv_gap_amount_tab(ln_int) := gt_inv_gap_amount_tab(ln_int) + lt_inv_gap_amount;                -- �{�̍��z
        gt_no_tax_sum1_tab(ln_int)    := gt_no_tax_sum1_tab(ln_int) + lt_no_tax_sum1;                      -- �Ŕ����v�P
        gt_no_tax_sum2_tab(ln_int)    := gt_no_tax_sum2_tab(ln_int) + get_target_inv_rec.ship_amount;      -- �Ŕ����v�Q
--
        -- �������׍X�V(A-8)
        update_invoice_lines(
          get_target_inv_rec.invoice_id,             -- ������ID
          get_target_inv_rec.invoice_detail_num,     -- �ꊇ����������No
          lt_tax_gap_amount,                         -- �ō��z
          lt_tax_sum1,                               -- �Ŋz���v�P
          get_target_inv_rec.tax_amount,             -- �Ŋz���v�Q
          lt_inv_gap_amount,                         -- �{�̍��z
          lt_no_tax_sum1,                            -- �Ŕ����v�P
          get_target_inv_rec.ship_amount,            -- �Ŕ����v�Q
          get_target_inv_rec.category,               -- ���󕪗�
          get_target_inv_rec.invoice_printing_unit,  -- ����������P��
          get_target_inv_rec.customer_for_sum,       -- �ڋq(�W�v�p)
          get_target_inv_rec.tax_div,                -- ����ŋ敪
          lv_errbuf,                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                                -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP edit_loop;
--
    -- ���������̃Z�b�g
    ov_target_trx_cnt := gt_get_inv_id_tab.COUNT;
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
  END get_update_target_bill;
--
--
  /**********************************************************************************
   * Procedure Name   : update_bill_amount
   * Description      : �������z�X�V���� �����w�b�_���e�[�u��(A-9)
   ***********************************************************************************/
  PROCEDURE update_bill_amount(
    in_invoice_id           IN  NUMBER,       -- ������ID
    in_tax_gap_amount       IN  NUMBER,       -- �ō��z
    in_tax_amount_sum       IN  NUMBER,       -- �Ŋz���v�P
    in_tax_amount_sum2      IN  NUMBER,       -- �Ŋz���v�Q
    in_inv_gap_amount       IN  NUMBER,       -- �{�̍��z
    in_inv_amount_sum       IN  NUMBER,       -- �Ŕ��z���v�P
    in_inv_amount_sum2      IN  NUMBER,       -- �Ŕ��z���v�Q
    iv_invoice_tax_div      IN  VARCHAR2,     -- ����������ŐϏグ�v�Z����
    iv_output_format        IN  VARCHAR2,     -- �������o�͌`��
    iv_tax_div              IN  VARCHAR2,     -- �ŋ敪
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_bill_amount'; -- �v���O������
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
    lt_inv_gap_amount              xxcfr_invoice_headers.inv_gap_amount%TYPE;              -- �{�̍��z
    lt_inv_amount_no_tax           xxcfr_invoice_headers.inv_amount_no_tax%TYPE;           -- �Ŕ��������z���v
    lt_tax_amount_sum              xxcfr_invoice_headers.tax_amount_sum%TYPE;              -- �Ŋz���v
    lt_inv_amount_includ_tax       xxcfr_invoice_headers.inv_amount_includ_tax%TYPE;       -- �ō��������z���v
    lt_tax_diff_amount_create_flg  xxcfr_invoice_headers.tax_diff_amount_create_flg%TYPE;  -- ����ō��z�쐬�t���O
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
    lt_inv_gap_amount              := 0;
    lt_inv_amount_no_tax           := 0;
    lt_tax_amount_sum              := 0;
    lt_inv_amount_includ_tax       := 0;
    lt_tax_diff_amount_create_flg  := NULL;
--
    -- �Ŋz���v
    IF ( iv_invoice_tax_div = 'Y' ) THEN
      lt_tax_amount_sum := in_tax_amount_sum2;  -- �Ŋz���v�ɐŊz���v�Q��ݒ�
    ELSE
      lt_tax_amount_sum := in_tax_amount_sum;   -- �Ŋz���v�ɐŊz���v�P��ݒ�
    END IF;
    -- �Ŕ����̏ꍇ
    IF ( iv_tax_div IN ( cv_tax_div_outtax, cv_tax_div_notax ) )  THEN
      lt_inv_gap_amount    := 0;                    -- �{�̍��z��0��ݒ�
      lt_inv_amount_no_tax := in_inv_amount_sum2;   -- �Ŕ��������z���v�ɐŔ��z���v�Q��ݒ�
--
    -- �ō��݂̏ꍇ
    ELSIF ( iv_tax_div IN ( cv_tax_div_inslip, cv_tax_div_inunit ) ) THEN
      IF ( iv_invoice_tax_div = 'Y' ) THEN
        lt_inv_gap_amount    := 0;                  -- �{�̍��z��0��ݒ�
        lt_inv_amount_no_tax := in_inv_amount_sum2; -- �Ŕ��������z���v�ɐŔ��z���v�Q��ݒ�
      ELSE
        lt_inv_gap_amount    := in_inv_gap_amount;  -- �{�̍��z
        lt_inv_amount_no_tax := in_inv_amount_sum;  -- �Ŕ��������z���v�ɐŔ��z���v�P��ݒ�
      END IF;
    END IF;
--
    -- �ō��������z���v = �Ŕ��������z���v �{ �Ŋz���v
    lt_inv_amount_includ_tax := NVL(lt_inv_amount_no_tax,0) + lt_tax_amount_sum;
    -- ����ō��z�쐬�t���O
    -- ����������ŐϏグ�v�Z������Y�ȊO���ō��z�܂��͖{�̍��z��0�܂���NULL�łȂ��ꍇ
    IF ( iv_invoice_tax_div <> 'Y' AND
         (( NVL(in_tax_gap_amount,0) <> 0 ) OR ( NVL(lt_inv_gap_amount,0) <> 0 )) ) THEN
      lt_tax_diff_amount_create_flg := '0';
    END IF;
-- Ver1.190 Add End
--
    -- �����w�b�_���e�[�u���������z�X�V
    BEGIN
--
      UPDATE  xxcfr_invoice_headers  xxih -- �����w�b�_���e�[�u��
      SET    xxih.tax_gap_amount              =  in_tax_gap_amount         -- �ō��z
            ,xxih.inv_amount_no_tax           =  lt_inv_amount_no_tax      -- �Ŕ��������z���v
            ,xxih.tax_amount_sum              =  lt_tax_amount_sum         -- �Ŋz���v
            ,xxih.inv_amount_includ_tax       =  lt_inv_amount_includ_tax  -- �ō��������z���v
            ,xxih.inv_gap_amount              =  lt_inv_gap_amount         -- �{�̍��z
            ,xxih.invoice_tax_div             =  iv_invoice_tax_div        -- ����������ŐϏグ�v�Z����
            ,xxih.tax_diff_amount_create_flg  =  lt_tax_diff_amount_create_flg  -- ����ō��z�쐬�t���O
            ,xxih.tax_rounding_rule           =  cv_tax_rounding_rule_down      -- �ŋ��|�[������
            ,xxih.output_format               =  iv_output_format          -- �������o�͌`��
      WHERE   xxih.invoice_id = in_invoice_id          -- ������ID
      ;
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- �f�[�^�X�V�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- �����w�b�_���e�[�u��
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_bill_amount;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date            IN  VARCHAR2,     -- ����
    iv_bill_acct_code         IN  VARCHAR2,     -- ������ڋq�R�[�h
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    gv_conc_status := cv_status_normal;
    gn_ins_cnt   := 0;
    gn_target_header_cnt := 0;
    gn_target_line_cnt   := 0;
--
--
    -- =====================================================
    --  �������׍X�V�Ώێ擾����(A-5)
    -- =====================================================
    get_update_target_line(
       iv_target_date          -- ����
      ,iv_bill_acct_code       -- ������ڋq�R�[�h
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �����w�b�_���̐������z���Čv�Z����B
    --�ϐ�������
    ln_target_trx_cnt := 0;
    -- =====================================================
    -- �����X�V�Ώێ擾���� (A-7)
    -- =====================================================
    get_update_target_bill(
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
      --���[�v
      <<for_loop>>
      FOR ln_loop_cnt IN gt_get_inv_id_tab.FIRST..gt_get_inv_id_tab.LAST LOOP
        -- =====================================================
        -- �������z�X�V���� �����w�b�_���e�[�u��(A-9)
        -- =====================================================
        update_bill_amount(
           gt_get_inv_id_tab(ln_loop_cnt),         -- ������ID
           gt_tax_gap_amount_tab(ln_loop_cnt),     -- �ō��z
           gt_tax_sum1_tab(ln_loop_cnt),           -- �Ŋz���v�P
           gt_tax_sum2_tab(ln_loop_cnt),           -- �Ŋz���v�Q
           gt_inv_gap_amount_tab(ln_loop_cnt),     -- �{�̍��z
           gt_no_tax_sum1_tab(ln_loop_cnt),        -- �Ŕ��z���v�P
           gt_no_tax_sum2_tab(ln_loop_cnt),        -- �Ŕ��z���v�Q
           gt_invoice_tax_div_tab(ln_loop_cnt),    -- ����������ŐϏグ�v�Z����
           gt_output_format_tab(ln_loop_cnt),      -- �������o�͌`��
           gt_tax_div_tab(ln_loop_cnt),            -- �ŋ敪
           lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
           lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
           lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
    END LOOP for_loop;
--
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
    iv_bill_acct_code       IN      VARCHAR2         -- ������ڋq�R�[�h
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
--      gn_target_cnt := 0;
--      gn_normal_cnt := 0;
      gn_target_header_cnt := 0;
      gn_target_line_cnt := 0;
      gn_error_cnt  := 1;
--      gn_warn_cnt   := 0;
--      gn_ins_cnt    := 0;
    END IF;
    --���b�Z�[�W�^�C�g��(�w�b�_��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00018
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(�w�b�_��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���b�Z�[�W�^�C�g��(���ו�)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00019
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(���ו�)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
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
END XXCFR003A24C;
/
