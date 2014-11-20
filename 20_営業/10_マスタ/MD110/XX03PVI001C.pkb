CREATE OR REPLACE PACKAGE BODY XX03PVI001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX03PVI001C(body)
 * Description      : �d�������̪��ð��قɃZ�b�g����Ă�������A�d����}�X�^�A
 *                    �d����T�C�g�}�X�^�A��s�����}�X�^�A��s���������e�[�u���֓o�^���s���B
 * MD.050(CMD.040)  : �d�������̪��      <B_P_MD050_DVL_009>
 * MD.070(CMD.050)  : �d�������̪��(PVI) <B_P_MD070_DVL_013>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_param              �p�����[�^�̃`�F�b�N(A-1)
 *  get_option_data        �e��f�[�^�̎擾(A-2)
 *  valid_data             �d����f�[�^�̑Ó����`�F�b�N(A-4)
 *  upd_vendors            �d����}�X�^�ւ̓o�^(A-5)
 *  upd_vendor_sites       �d����T�C�g�}�X�^�ւ̓o�^(A-6)
 *  upd_bank_accounts      ��s�����}�X�^�ւ̓o�^��X�V(A-7)
 *  upd_bank_account_uses  ��s��������ð��قւ̓o�^��X�V(A-8)
 *  upd_ift                �d����C���^�[�t�F�[�X�e�[�u���̍X�V(A-9)
 *  main_loop              �d����f�[�^���o(A-3)
 *  del_ift                �C���|�[�g�����f�[�^�폜(A-10)
 *  msg_processed_data     ���b�Z�[�W�o��(A-11)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ----------- ------------- ------------ -------------------------------------------------
 *  Date        Ver.          Editor       Description
 * ----------- ------------- ------------ -------------------------------------------------
 *  2003.05.14  1.0           H.TANIGAWA   �V�K
 *  2004.08.20  1.1           MATSUMURA    �d����T�C�g�w���t���O�ǉ�(IF�e�[�u�����ύX)
 *  2006.06.10  11.5.10.1.3   MATSUMURA    �d����T�C�g�A��s������ORG�Ή�
 *  2009.04.24  1.2           �}�X�^�s�l   �o�O�Ή��i�o�א掖�Ə��̋����j
 *****************************************************************************************/
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`�錾��
  -- ===============================
--
    -- *** �O���[�o���萔 ***
    cv_msg_appl_name          CONSTANT VARCHAR2(100) := 'XXIF';

    -- *** �p�b�P�[�W�J�[�\�� ***
    --��v�I�v�V�����f�[�^�擾�J�[�\��
    CURSOR financials_cur
    IS
      SELECT user_defined_vendor_num_code,
             ship_to_location_id,
             bill_to_location_id,
             ship_via_lookup_code,
             freight_terms_lookup_code,
             fob_lookup_code,
             terms_id,
             always_take_disc_flag,
             invoice_currency_code,
             payment_currency_code,
             payment_method_lookup_code,
             exclusive_payment_flag,
             hold_unmatched_invoices_flag,
             match_option,
             tax_rounding_rule,
             accts_pay_code_combination_id,
             future_dated_payment_ccid
      FROM   financials_system_parameters;
--
    --# ���|�Ǘ��I�v�V�����擾�J�[�\��
    CURSOR payables_cur
    IS
      SELECT pay_date_basis_lookup_code,
             terms_date_basis,
             auto_tax_calc_flag,
             auto_tax_calc_override,
             amount_includes_tax_flag,
             bank_charge_bearer,
             gain_code_combination_id,
             loss_code_combination_id,
             max_outlay,
             multi_currency_flag
      FROM   ap_system_parameters;
    --# ����I�v�V�����J�[�\��
    CURSOR rcv_parameters_cur(
      in_c_org_id IN rcv_parameters.organization_id%TYPE)
    IS
      SELECT qty_rcv_tolerance,
             days_early_receipt_allowed,
             days_late_receipt_allowed,
             enforce_ship_to_location_code,
             receiving_routing_id,
             receipt_days_exception_code,
             qty_rcv_exception_code,
             allow_substitute_receipts_flag,
             allow_unordered_receipts_flag
      FROM   rcv_parameters
      WHERE  organization_id = in_c_org_id;
--
    --# vendor_interface_cur(�Ώۃf�[�^�擾�J�[�\��)
    CURSOR vendor_interface_cur(
      iv_force_flag   IN  VARCHAR2)
    IS
      SELECT xvi.ROWID,
             xvi.vendors_interface_id,
             UPPER(xvi.insert_update_flag) insert_update_flag,
             xvi.vndr_vendor_id,
             xvi.vndr_vendor_name,
             xvi.vndr_segment1,
             xvi.vndr_employee_id,
             xvi.vndr_vendor_type_lkup_code,
             xvi.vndr_terms_id,
             xvi.vndr_pay_group_lkup_code,
             xvi.vndr_invoice_amount_limit,
             xvi.vndr_accts_pay_ccid,
             xvi.vndr_prepay_ccid,
             xvi.vndr_end_date_active,
             UPPER(xvi.vndr_small_business_flag) vndr_small_business_flag,
             UPPER(xvi.vndr_receipt_required_flag) vndr_receipt_required_flag,
             xvi.vndr_attribute_category,
             xvi.vndr_attribute1,
             xvi.vndr_attribute2,
             xvi.vndr_attribute3,
             xvi.vndr_attribute4,
             xvi.vndr_attribute5,
             xvi.vndr_attribute6,
             xvi.vndr_attribute7,
             xvi.vndr_attribute8,
             xvi.vndr_attribute9,
             xvi.vndr_attribute10,
             xvi.vndr_attribute11,
             xvi.vndr_attribute12,
             xvi.vndr_attribute13,
             xvi.vndr_attribute14,
             xvi.vndr_attribute15,
             UPPER(xvi.vndr_allow_awt_flag) vndr_allow_awt_flag,
             xvi.vndr_vendor_name_alt,
             UPPER(xvi.vndr_ap_tax_rounding_rule) vndr_ap_tax_rounding_rule,
             UPPER(xvi.vndr_auto_tax_calc_flag) vndr_auto_tax_calc_flag,
             UPPER(xvi.vndr_auto_tax_calc_override) vndr_auto_tax_calc_override,
             xvi.vndr_bank_charge_bearer,
             xvi.site_vendor_site_id,
             xvi.site_vendor_site_code,
             xvi.site_address_line1,
             xvi.site_address_line2,
             xvi.site_address_line3,
             xvi.site_city,
             xvi.site_state,
             xvi.site_zip,
             xvi.site_province,
             xvi.site_country,
             xvi.site_area_code,
             xvi.site_phone,
             xvi.site_fax,
             xvi.site_fax_area_code,
             xvi.site_payment_method_lkup_code,
             xvi.site_bank_account_name,
             xvi.site_bank_account_num,
             abb.bank_num site_bank_num,
             xvi.site_bank_account_type,
             xvi.site_vat_code,
             xvi.site_distribution_set_id,
             xvi.site_accts_pay_ccid,
             xvi.site_prepay_ccid,
             xvi.site_pay_group_lkup_code,
             xvi.site_terms_id,
             xvi.site_invoice_amount_limit,
             xvi.site_attribute_category,
             xvi.site_attribute1,
             xvi.site_attribute2,
             xvi.site_attribute3,
             xvi.site_attribute4,
             xvi.site_attribute5,
             xvi.site_attribute6,
             xvi.site_attribute7,
             xvi.site_attribute8,
             xvi.site_attribute9,
             xvi.site_attribute10,
             xvi.site_attribute11,
             xvi.site_attribute12,
             xvi.site_attribute13,
             xvi.site_attribute14,
             xvi.site_attribute15,
             abb.bank_number site_bank_number,
             xvi.site_address_line4,
             xvi.site_county,
             UPPER(xvi.site_allow_awt_flag) site_allow_awt_flag,
             xvi.site_awt_group_id,
             xvi.site_vendor_site_code_alt,
             xvi.site_address_lines_alt,
             UPPER(xvi.site_ap_tax_rounding_rule) site_ap_tax_rounding_rule,
             UPPER(xvi.site_auto_tax_calc_flag) site_auto_tax_calc_flag,
             UPPER(xvi.site_auto_tax_calc_override) site_auto_tax_calc_override,
             xvi.site_bank_charge_bearer,
             xvi.site_bank_branch_type,
             UPPER(xvi.site_create_debit_memo_flag) site_create_debit_memo_flag,
             UPPER(xvi.site_supplier_notif_method) site_supplier_notif_method,
             xvi.site_email_address,
             UPPER(xvi.site_primary_pay_site_flag) site_primary_pay_site_flag,
             --�����C��
             UPPER(xvi.site_purchasing_site_flag) site_purchasing_site_flag,
             --�����C��end
             --���R�C��
             --xvi.acnt_bank_name,
             abb.bank_name acnt_bank_name,
             --���R�C��
             --xvi.acnt_bank_branch_name,
             abb.bank_branch_name acnt_bank_branch_name,
             xvi.acnt_bank_account_name,
             xvi.acnt_bank_account_num,
             xvi.acnt_currency_code,
             xvi.acnt_description,
             xvi.acnt_asset_id,
             xvi.acnt_bank_account_type,
             xvi.acnt_attribute_category,
             xvi.acnt_attribute1,
             xvi.acnt_attribute2,
             xvi.acnt_attribute3,
             xvi.acnt_attribute4,
             xvi.acnt_attribute5,
             xvi.acnt_attribute6,
             xvi.acnt_attribute7,
             xvi.acnt_attribute8,
             xvi.acnt_attribute9,
             xvi.acnt_attribute10,
             xvi.acnt_attribute11,
             xvi.acnt_attribute12,
             xvi.acnt_attribute13,
             xvi.acnt_attribute14,
             xvi.acnt_attribute15,
             xvi.acnt_cash_clearing_ccid,
             xvi.acnt_bank_charges_ccid,
             xvi.acnt_bank_errors_ccid,
             xvi.acnt_account_holder_name,
             xvi.acnt_account_holder_name_alt,
             xvi.uses_start_date,
             xvi.uses_end_date,
             xvi.uses_attribute_category,
             xvi.uses_attribute1,
             xvi.uses_attribute2,
             xvi.uses_attribute3,
             xvi.uses_attribute4,
             xvi.uses_attribute5,
             xvi.uses_attribute6,
             xvi.uses_attribute7,
             xvi.uses_attribute8,
             xvi.uses_attribute9,
             xvi.uses_attribute10,
             xvi.uses_attribute11,
             xvi.uses_attribute12,
             xvi.uses_attribute13,
             xvi.uses_attribute14,
             xvi.uses_attribute15
      FROM   xx03_vendors_interface xvi,
             ap_bank_branches abb
      WHERE  xvi.status_flag = iv_force_flag
      --���R�C��
      --AND    xvi.site_bank_name = abb.bank_name(+)
      --ymatsumu�C��
      --AND    xvi.acnt_bank_number = abb.bank_num(+)
      AND    NVL(xvi.acnt_bank_number,xvi.site_bank_number) = abb.bank_num(+)
      --���R�C��
      --AND    xvi.site_bank_branch_name = abb.bank_branch_name(+)
      --ymatsumu�C��
      --AND    xvi.acnt_bank_num = abb.bank_number(+)
      AND    NVL(xvi.acnt_bank_num,xvi.site_bank_num) = abb.bank_number(+)
      ORDER BY xvi.vendors_interface_id
      FOR UPDATE NOWAIT;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
    chk_param_expt           EXCEPTION;  --�p�����[�^�`�F�b�N�G���[
    get_option_data_expt     EXCEPTION;  --�e��f�[�^�擾���s
    valid_data_expt          EXCEPTION;  --�Ó����`�F�b�N�G���[
    upd_vendors_expt         EXCEPTION;  --�d����}�X�^�f�[�^�X�V���s
    upd_vendor_sites_expt    EXCEPTION;  --�d����T�C�g�}�X�^�f�[�^�X�V���s
    upd_bank_accounts_expt   EXCEPTION;  --��s�����}�X�^�f�[�^�X�V���s
    upd_bank_acnt_uses_expt  EXCEPTION;  --��s���������f�[�^�X�V���s
    upd_ift_expt             EXCEPTION;  --�d����C���^�[�t�F�[�X�e�[�u���X�V���s
    del_ift_expt             EXCEPTION;  --�C���|�[�g�����f�[�^�폜���s
--
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�̃`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_force_flag         IN  VARCHAR2,  -- 1.�����t���O
    iv_start_date_active  IN  VARCHAR2,  -- 2.�Ɩ����t
    od_start_date_active  OUT DATE,      -- 3.�Ɩ����t�i2�̃p�����[�^����DATE�^�ɕϊ��������́j
    ov_errbuf             OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --# �����t���O�̃`�F�b�N
    IF (iv_force_flag IS NULL) THEN
      RAISE chk_param_expt;
    END IF;
    --# �Ɩ����t�̃`�F�b�N
    IF (iv_start_date_active IS NULL) THEN
      od_start_date_active := xx00_date_pkg.get_system_datetime_f;
    ELSE
      BEGIN
        od_start_date_active := TO_DATE(iv_start_date_active);
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE chk_param_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN chk_param_expt THEN                 --*** �p�����[�^�`�F�b�N���s�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                            'APP-XX03-00009');
      --�G���[���b�Z�[�W���R�s�[
      lv_errbuf := lv_errmsg;
      -------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param;
--
--
  /**********************************************************************************
   * Procedure Name   : get_option_data
   * Description      : �e��f�[�^�̎擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_option_data(
    financials_rec   OUT  financials_cur%ROWTYPE,      -- 1.��v�I�v�V�����f�[�^
    payables_rec     OUT  payables_cur%ROWTYPE,        -- 2.���|�Ǘ��I�v�V�����f�[�^
    receipts_rec     OUT  rcv_parameters_cur%ROWTYPE,  -- 3.����I�v�V�����f�[�^
    ot_chart_of_accounts_id OUT gl_sets_of_books.chart_of_accounts_id%TYPE,  -- 4.����̌nID
    on_set_of_books_id      OUT NUMBER, -- 5.��v����ID
    ov_errbuf        OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_option_data'; -- �v���O������
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
    ln_org_id                NUMBER;   --�g�DID
    lt_currency              gl_sets_of_books.currency_code%TYPE;         --�ʉ݃R�[�h
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --# �g�DID�̎擾
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --# ��v����ID�̎擾
    xx00_profile_pkg.get('GL_SET_OF_BKS_ID',on_set_of_books_id);
    --# �g�DID�̐ݒ�
    xx00_client_info_pkg.set_org_context(ln_org_id);
    --# ��v�I�v�V�����f�[�^�擾
    OPEN financials_cur;
    FETCH financials_cur INTO financials_rec;
    IF (financials_cur%NOTFOUND) THEN
       CLOSE financials_cur;
       RAISE get_option_data_expt;
    END IF;
    CLOSE financials_cur;
    --# ���|�Ǘ��I�v�V�����f�[�^�擾
    OPEN payables_cur;
    FETCH payables_cur INTO payables_rec;
    IF (payables_cur%NOTFOUND) THEN
       CLOSE payables_cur;
       RAISE get_option_data_expt;
    END IF;
    CLOSE payables_cur;
    --# ����I�v�V�����f�[�^�擾
    OPEN rcv_parameters_cur(ln_org_id);
    FETCH rcv_parameters_cur INTO receipts_rec;
    CLOSE rcv_parameters_cur;
    --# ����̌nID�A�ʉ݃R�[�h�̎擾
    BEGIN
      SELECT chart_of_accounts_id,
             currency_code
      INTO   ot_chart_of_accounts_id,
             lt_currency
      FROM   gl_sets_of_books
      WHERE  set_of_books_id = on_set_of_books_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := xx00_common_pkg.set_status_error_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      RAISE get_option_data_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN get_option_data_expt THEN             --*** �e��f�[�^�擾���s�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00010');
      --�G���[���b�Z�[�W���R�s�[
      lv_errbuf := lv_errmsg;
      -------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_option_data;
--
--
  /**********************************************************************************
   * Procedure Name   : valid_data
   * Description      : �d����f�[�^�̑Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE valid_data(
    vendor_interface_rec     IN  vendor_interface_cur%ROWTYPE,  -- 1.�d����f�[�^
    financials_rec           IN  financials_cur%ROWTYPE,        -- 2.��v�I�v�V�����f�[�^
    iv_force_flag            IN  VARCHAR2,    -- 3.�����t���O
    id_start_date_active     IN  DATE,        -- 4.�Ɩ����t
    it_chart_of_accounts_id  IN  gl_sets_of_books.chart_of_accounts_id%TYPE,  -- 5.����̌nID
    ov_process_mode          OUT VARCHAR2,    -- 1.�ǉ�/�X�V���[�h
    ov_interface_errcode     OUT VARCHAR2,    -- 2.�G���[���R�R�[�h
    ov_errbuf                OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'valid_data'; -- �v���O������
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
    ln_wk_cnt   NUMBER;  --�J�E���g�̂��߂̃��[�N�ϐ�
    --Ver11.5.10.1.3 2005.06.10 add START
    ln_org_id   NUMBER;
    --Ver11.5.10.1.3 2005.06.10 add END
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    --Ver11.5.10.1.3 2005.06.10 add START
    --# �g�DID�̎擾
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- �ǉ�/�X�V���[�h�̃`�F�b�N
    --==============================================================
    IF (vendor_interface_rec.insert_update_flag = 'I')
      AND (vendor_interface_rec.vndr_vendor_id IS NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '1';
    ELSIF (vendor_interface_rec.insert_update_flag='I')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '2';
    ELSIF (vendor_interface_rec.insert_update_flag='U')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NOT NULL)
    THEN
      ov_process_mode := '3';
    ELSIF (vendor_interface_rec.insert_update_flag='U')
      AND (vendor_interface_rec.vndr_vendor_id IS NOT NULL)
      AND (vendor_interface_rec.site_vendor_site_id IS NULL)
    THEN
      ov_process_mode := '4';
    ELSE
      ov_interface_errcode := '010';
      RAISE valid_data_expt;
    END IF;
--
    --==============================================================
    -- �d������Ɋւ���`�F�b�N
    --==============================================================
    --# �d����ID(vndr_vendor_id) ���݃`�F�b�N
    IF (ov_process_mode IN ('2','3','4')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors
      WHERE  vendor_id = vendor_interface_rec.vndr_vendor_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '060';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d���於(vndr_vendor_name) NULL�`�F�b�N
    IF (ov_process_mode IN ('1','3','4')) THEN
      IF (vendor_interface_rec.vndr_vendor_name IS NULL) THEN
        ov_interface_errcode := '070';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d���於(vndr_vendor_name) �d���`�F�b�N
    IF (ov_process_mode IN ('1','3','4')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
              OR vendor_interface_rec.vndr_vendor_id != pv.vendor_id)
      AND    pv.vendor_name = vendor_interface_rec.vndr_vendor_name;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '080';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# (user_defined_vendor_num_code) NULL�`�F�b�N
    IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC')
      AND (ov_process_mode IN ('1','3','4')) 
    THEN
      IF (vendor_interface_rec.vndr_segment1 IS NULL) THEN
         ov_interface_errcode := '090';
         RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d����ԍ�(vndr_segment1) �d���`�F�b�N
    IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC')
      AND (ov_process_mode IN ('1','3','4'))
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
              OR vendor_interface_rec.vndr_vendor_id != pv.vendor_id)
      AND    pv.segment1 = vendor_interface_rec.vndr_segment1;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '100';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d����^�C�v(vndr_vendor_type_lkup_code) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_vendor_type_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'VENDOR TYPE',
                vendor_interface_rec.vndr_vendor_type_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '040';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �]�ƈ�ID(employee_id) �̃`�F�b�N
    IF (vendor_interface_rec.vndr_employee_id IS NOT NULL)
      AND (ov_process_mode = '1')
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   hr_employees_current_v hec_v
      WHERE  hec_v.employee_id = vendor_interface_rec.vndr_employee_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '020';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �]�ƈ�ID(employee_id) �̃`�F�b�N�Q
    IF (vendor_interface_rec.vndr_employee_id IS NOT NULL)
      AND (ov_process_mode = '1')
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendors pv
      WHERE  (vendor_interface_rec.vndr_vendor_id IS NULL 
             OR pv.vendor_id != vendor_interface_rec.vndr_vendor_id)
      AND    pv.employee_id = vendor_interface_rec.vndr_employee_id;
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '030';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �x������(vndr_terms_id) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_terms_id IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_term_id(vendor_interface_rec.vndr_terms_id,
                                                   id_start_date_active)) 
      THEN
        ov_interface_errcode := '110';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �x���O���[�v�R�[�h(vndr_pay_group_lkup_code) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_pay_group_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
--���R�C��
--              'PAY_GROUP',
                'PAY GROUP',
                vendor_interface_rec.vndr_pay_group_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '120';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ������Ȗ�ID(vndr_accts_pay_ccid) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_accts_pay_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.vndr_accts_pay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '130';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �O��/����������Ȗ�ID(vndr_prepay_ccid) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_prepay_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.vndr_prepay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '140';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# �����@�l�׸�(vndr_small_business_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_small_business_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_small_business_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '150';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����m�F�׸�(vndr_receipt_required_flag) �̃`�F�b�N
   IF (ov_process_mode = '1') 
     AND (vendor_interface_rec.vndr_receipt_required_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_receipt_required_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '050';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# ���򒥎��Ŏg�p�׸�(vndr_allow_awt_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_allow_awt_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_allow_awt_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '160';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�[�������K��(vndr_ap_tax_rounding_rule) �̃`�F�b�N
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_ap_tax_rounding_rule IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_ap_tax_rounding_rule NOT IN ('U','D','N')) THEN
       ov_interface_errcode := '170';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�v�Z���x��(vndr_auto_tax_calc_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_auto_tax_calc_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_auto_tax_calc_flag NOT IN ('Y','T','L','N')) THEN
       ov_interface_errcode := '180';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�㏑���̋����׸�(vndr_auto_tax_calc_override) �̃`�F�b�N
   IF (ov_process_mode IN ('1','3','4'))
     AND (vendor_interface_rec.vndr_auto_tax_calc_override IS NOT NULL)
   THEN
     IF (vendor_interface_rec.vndr_auto_tax_calc_override NOT IN ('Y','N')) THEN
       ov_interface_errcode := '190';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
    --# ��s�萔�����S��(vndr_bank_charge_bearer) �̃`�F�b�N
    IF (ov_process_mode IN ('1','3','4'))
      AND (vendor_interface_rec.vndr_bank_charge_bearer IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK CHARGE BEARER',
                vendor_interface_rec.vndr_bank_charge_bearer,
                id_start_date_active))
      THEN
        ov_interface_errcode := '200';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- �d����T�C�g���Ɋւ���`�F�b�N
    --==============================================================
    --# �d����T�C�gID(site_vendor_site_id) �̃`�F�b�N
    IF (ov_process_mode = '3') THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendor_sites_all pvsa
      WHERE  pvsa.vendor_site_id = vendor_interface_rec.site_vendor_site_id
      AND    pvsa.vendor_id = vendor_interface_rec.vndr_vendor_id;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '250';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d����T�C�g��(site_vendor_site_code) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.site_vendor_site_code IS NULL) THEN
        ov_interface_errcode := '260';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �d����T�C�g��(site_vendor_site_code) �d���`�F�b�N
    IF (ov_process_mode IN ('2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   po_vendor_sites_all pvsa
      WHERE  (vendor_interface_rec.site_vendor_site_id IS NULL 
              OR pvsa.vendor_site_id != vendor_interface_rec.site_vendor_site_id)
      AND    pvsa.vendor_id = vendor_interface_rec.vndr_vendor_id
      AND    pvsa.vendor_site_code = vendor_interface_rec.site_vendor_site_code
    --Ver11.5.10.1.3 2005.06.10 add START
      AND    pvsa.org_id = ln_org_id;
    --Ver11.5.10.1.3 2005.06.10 add START
      IF (ln_wk_cnt > 0) THEN
        ov_interface_errcode := '270';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �Z������ݒn1(site_address_line1) NULL�`�F�b�N
    IF (ov_process_mode IN ('1','2','3')) THEN
      IF (vendor_interface_rec.site_address_line1 IS NULL) THEN
        ov_interface_errcode := '280';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �Z�����(site_country) �`�F�b�N
    IF (ov_process_mode IN ('1','2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_territories_vl ft_v
      WHERE  ft_v.territory_code = vendor_interface_rec.site_country;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '290';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �x�����@(site_payment_method_lkup_code) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_payment_method_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'PAYMENT METHOD',
                vendor_interface_rec.site_payment_method_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '300';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �ŃR�[�h(site_vat_code) �`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_vat_code IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_lookup_values_vl lc,
             ap_tax_codes         tc
      WHERE  lc.lookup_type = 'TAX TYPE'
      AND    tc.name = vendor_interface_rec.site_vat_code
      AND    tc.tax_type != 'OFFSET'
      AND    tc.tax_type != 'AWT'
      AND    lc.lookup_code != tc.tax_type
      AND    (TRUNC(id_start_date_active) 
              BETWEEN TRUNC(NVL(lc.start_date_active,id_start_date_active - 1))
              AND TRUNC(NVL(lc.end_date_active,id_start_date_active + 1)))
      AND    lc.enabled_flag = 'Y'
      AND    NVL(tc.enabled_flag,'Y') = 'Y'
      AND    TRUNC(id_start_date_active) < TRUNC(NVL(tc.inactive_date,id_start_date_active + 1));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '310';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �z���Z�b�g(site_distribution_set_id) �`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_distribution_set_id IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   ap_distribution_sets ads
      WHERE  ads.distribution_set_id = vendor_interface_rec.site_distribution_set_id
      AND    TRUNC(id_start_date_active) < TRUNC(NVL(ads.inactive_date,id_start_date_active + 1));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '320';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ������Ȗ�(site_accts_pay_ccid) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_accts_pay_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.site_accts_pay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '210';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �O��/����������Ȗ�ID(site_prepay_ccid) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_prepay_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.site_prepay_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '220';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# site_pay_group_lkup_code �̃`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_pay_group_lkup_code IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'PAY GROUP',
                vendor_interface_rec.site_pay_group_lkup_code,
                id_start_date_active))
      THEN
        ov_interface_errcode := '330';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# site_terms_id �̃`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_terms_id IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_term_id(vendor_interface_rec.site_terms_id,
                                                   id_start_date_active)) 
      THEN
        ov_interface_errcode := '340';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# ���򒥎��Ŏg�p�t���O(site_allow_awt_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_allow_awt_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_allow_awt_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '350';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# ���򒥎��ŃO���[�v(site_awt_group_id) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_awt_group_id IS NOT NULL)
   THEN
     SELECT COUNT(*)
     INTO   ln_wk_cnt
     FROM   ap_awt_groups aag
     WHERE  aag.group_id = vendor_interface_rec.site_awt_group_id
     AND    TRUNC(id_start_date_active) < TRUNC(NVL(inactive_date,id_start_date_active + 1));
     IF (ln_wk_cnt = 0) THEN
       ov_interface_errcode := '360';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�[�������K��(site_ap_tax_rounding_rule) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_ap_tax_rounding_rule IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_ap_tax_rounding_rule NOT IN ('U','D','N')) THEN
       ov_interface_errcode := '370';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�v�Z���x��(site_auto_tax_calc_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_auto_tax_calc_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_auto_tax_calc_flag NOT IN ('Y','T','L','N')) THEN
       ov_interface_errcode := '380';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �����Ŏ����v�Z�㏑�����t���O(site_auto_tax_calc_override) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_auto_tax_calc_override IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_auto_tax_calc_override NOT IN ('Y','N')) THEN
       ov_interface_errcode := '390';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
    --# ��s�萔�����S��(site_bank_charge_bearer) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.site_bank_charge_bearer IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK CHARGE BEARER',
                vendor_interface_rec.site_bank_charge_bearer,
                id_start_date_active))
      THEN
        ov_interface_errcode := '400';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��s�x�X�^�C�v(site_bank_branch_type) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.site_bank_branch_type IS NOT NULL)
    THEN
      IF NOT (xx03_vendor_if_validate_pkg.check_lookup_code(
                'BANK BRANCH TYPE',
                vendor_interface_rec.site_bank_branch_type,
                id_start_date_active))
      THEN
        ov_interface_errcode := '230';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
   --# RTS����f�r�b�g�����쐬�t���O(site_create_debit_memo_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_create_debit_memo_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_create_debit_memo_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '410';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# �d����ʒm���@(site_supplier_notif_method) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2','3'))
     AND (vendor_interface_rec.site_supplier_notif_method IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_supplier_notif_method NOT IN ('PRINT','FAX','EMAIL')) THEN
       ov_interface_errcode := '420';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
   --# ��x���T�C�g�t���O(site_primary_pay_site_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2'))
     AND (vendor_interface_rec.site_primary_pay_site_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_primary_pay_site_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '240';
       RAISE valid_data_expt;
     END IF;
   END IF;
--
--�����C��(�ǉ�)
   --# �w���t���O(site_purchasing_site_flag) �̃`�F�b�N
   IF (ov_process_mode IN ('1','2'))
     AND (vendor_interface_rec.site_purchasing_site_flag IS NOT NULL)
   THEN
     IF (vendor_interface_rec.site_purchasing_site_flag NOT IN ('Y','N')) THEN
       ov_interface_errcode := '640';
       RAISE valid_data_expt;
     END IF;
   END IF;
--�����C��end
--
    --==============================================================
    -- ��s�������Ɋւ���`�F�b�N
    --==============================================================
    --# ��s��(acnt_bank_name) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_name IS NULL) THEN
        ov_interface_errcode := '500';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��s�x�X��(acnt_bank_branch_name) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_branch_name IS NULL) THEN
        ov_interface_errcode := '510';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��s���A��s�x�X��(acnt_bank_name, acnt_bank_branch_name) �̃`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   ap_bank_branches abb
      WHERE  abb.bank_name = vendor_interface_rec.acnt_bank_name
      AND    abb.bank_branch_name = vendor_interface_rec.acnt_bank_branch_name;
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '520';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��������(acnt_bank_account_name) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_name IS NULL) THEN
        ov_interface_errcode := '530';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �����ԍ�(acnt_bank_account_num) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_num IS NULL) THEN
        ov_interface_errcode := '430';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �ʉ݃R�[�h(acnt_currency_code) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_currency_code IS NULL) THEN
        ov_interface_errcode := '540';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �ʉ݃R�[�h(acnt_currency_code) �`�F�b�N�Q
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.acnt_currency_code IS NOT NULL)
    THEN
      SELECT COUNT(*)
      INTO   ln_wk_cnt
      FROM   fnd_currencies_vl fc_v
      WHERE  fc_v.currency_code = vendor_interface_rec.acnt_currency_code
      AND    fc_v.enabled_flag = 'Y'
      AND    (TRUNC(id_start_date_active)
              BETWEEN TRUNC(NVL(fc_v.start_date_active,id_start_date_active - 1))
              AND TRUNC(NVL(fc_v.end_date_active,id_start_date_active + 1)));
      IF (ln_wk_cnt = 0) THEN
        ov_interface_errcode := '550';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ���a������Ȗ�ID(acnt_asset_id) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_asset_id IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_asset_id,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '450';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �a�����(acnt_bank_account_type) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_bank_account_type IS NULL) THEN
        ov_interface_errcode := '460';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �������ϊ���Ȗ�ID(acnt_cash_clearing_ccid) NULL�`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_cash_clearing_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_cash_clearing_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '470';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��s�萔������Ȗ�ID(acnt_bank_charges_ccid) NULL�`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_bank_charges_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_bank_charges_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '480';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# ��s�G���[����Ȗ�ID(acnt_bank_errors_ccid) NULL�`�F�b�N
    IF (ov_process_mode IN ('1','2'))
      AND (vendor_interface_rec.acnt_bank_errors_ccid IS NOT NULL)
    THEN
      --����Ȗڑg�����̃`�F�b�N
      IF (NOT fnd_flex_keyval.validate_ccid('SQLGL',
                                            'GL#',
                                            it_chart_of_accounts_id,
                                            vendor_interface_rec.acnt_bank_errors_ccid,
                                            'ALL',
                                            NULL,
                                            NULL,
                                            'IGNORE',
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL))
      THEN
        ov_interface_errcode := '490';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �������`�l������(acnt_account_holder_name_alt) NULL�`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF (vendor_interface_rec.acnt_account_holder_name_alt IS NULL) THEN
        ov_interface_errcode := '560';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --# �������`�l������(acnt_account_holder_name_alt) �`�F�b�N
    IF (ov_process_mode IN('1','2','3')) THEN
      IF NOT(xx03_chk_kana_pkg.chk_kana(vendor_interface_rec.acnt_account_holder_name_alt)) THEN
        ov_interface_errcode := '570';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- ��s�����������Ɋւ���`�F�b�N
    --==============================================================
    --# �J�n��(uses_start_date)�A�I����(uses_end_date) �̃`�F�b�N
    IF (ov_process_mode IN ('1','2','3'))
      AND (vendor_interface_rec.uses_start_date IS NOT NULL 
           AND vendor_interface_rec.uses_end_date IS NOT NULL)
    THEN
      IF (vendor_interface_rec.uses_start_date > vendor_interface_rec.uses_end_date) THEN
        ov_interface_errcode := '580';
        RAISE valid_data_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN valid_data_expt THEN              --*** �Ó����`�F�b�N���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
     lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           ov_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           ov_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      --------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --�X�e�[�^�X���x���ŕԂ�
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END valid_data;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vendors
   * Description      : �d����}�X�^�ւ̓o�^(A-5)
   ***********************************************************************************/
  PROCEDURE upd_vendors(
    iv_process_mode       IN  VARCHAR2,  -- 1.�ǉ�/�X�V���[�h
    vendor_interface_rec  IN  vendor_interface_cur%ROWTYPE,  -- 2.�d����IFT�̃f�[�^
    financials_rec        IN  financials_cur%ROWTYPE,        -- 3.��v�I�v�V�����f�[�^
    payables_rec          IN  payables_cur%ROWTYPE,          -- 4.���|�Ǘ��I�v�V�����f�[�^
    receipts_rec          IN  rcv_parameters_cur%ROWTYPE,    -- 5.����I�v�V�����f�[�^
    in_set_of_books_id    IN  NUMBER,    -- 6.��v����ID
    id_start_date_active  IN  DATE,      -- 7.�Ɩ����t
    or_vendors_rowid      OUT ROWID,                     --ap_vendors_pkg.insert_row�Ŏ擾��OUT�ϐ�
    ot_vendor_id          OUT po_vendors.vendor_id%TYPE, --upd_vendors�Ŏ擾��vendor_id
    ov_interface_errcode  OUT VARCHAR2,  -- �G���[���R�R�[�h
    ov_errbuf             OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vendors'; -- �v���O������
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
    lt_wk_segment1   po_vendors.segment1%TYPE;
    lt_wk_vendor_id  po_vendors.vendor_id%TYPE; --ap_vendors_pkg.insert_row�Ŏ擾��OUT�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    --# �X�V�ΏۊO��̍X�V�p�f�[�^
    CURSOR  upd_vendors_cur(
      vndr_vendor_id IN vendor_interface_rec.vndr_vendor_id%TYPE)
    IS
      SELECT rowidtochar(rowid) char_rowid,
             vendor_id,
             segment1,
             summary_flag,
             enabled_flag,
             employee_id,
             validation_number,
             vendor_type_lookup_code,
             customer_num,
             one_time_flag,
             parent_vendor_id,
             min_order_amount,
             ship_to_location_id,
             bill_to_location_id,
             ship_via_lookup_code,
             freight_terms_lookup_code,
             fob_lookup_code,
             terms_id,
             set_of_books_id,
             always_take_disc_flag,
             pay_date_basis_lookup_code,
             payment_priority,
             invoice_currency_code,
             payment_currency_code,
             hold_all_payments_flag,
             hold_future_payments_flag,
             hold_reason,
             distribution_set_id,
             future_dated_payment_ccid,
             num_1099,
             type_1099,
             withholding_status_lookup_code,
             withholding_start_date,
             organization_type_lookup_code,
             vat_code,
             start_date_active,
             qty_rcv_tolerance,
             minority_group_lookup_code,
             payment_method_lookup_code,
             bank_account_name,
             bank_account_num,
             bank_num,
             bank_account_type,
             women_owned_flag,
             standard_industry_class,
             hold_flag,
             purchasing_hold_reason,
             hold_by,
             hold_date,
             terms_date_basis,
             price_tolerance,
             days_early_receipt_allowed,
             days_late_receipt_allowed,
             enforce_ship_to_location_code,
             exclusive_payment_flag,
             federal_reportable_flag,
             hold_unmatched_invoices_flag,
             match_option,
             create_debit_memo_flag,
             inspection_required_flag,
             receipt_required_flag,
             receiving_routing_id,
             state_reportable_flag,
             tax_verification_date,
             auto_calculate_interest_flag,
             name_control,
             allow_substitute_receipts_flag,
             allow_unordered_receipts_flag,
             receipt_days_exception_code,
             qty_rcv_exception_code,
             offset_tax_flag,
             exclude_freight_from_discount,
             vat_registration_num,
             tax_reporting_name,
             awt_group_id,
             check_digits,
             bank_number,
             bank_branch_type,
             edi_payment_method,
             edi_payment_format,
             edi_remittance_method,
             edi_remittance_instruction,
             edi_transaction_handling,
             amount_includes_tax_flag,
             global_attribute_category,
             global_attribute1,
             global_attribute2,
             global_attribute3,
             global_attribute4,
             global_attribute5,
             global_attribute6,
             global_attribute7,
             global_attribute8,
             global_attribute9,
             global_attribute10,
             global_attribute11,
             global_attribute12,
             global_attribute13,
             global_attribute14,
             global_attribute15,
             global_attribute16,
             global_attribute17,
             global_attribute18,
             global_attribute19,
             global_attribute20
      FROM   po_vendors
      WHERE  vendor_id = vndr_vendor_id
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    upd_vendors_rec    upd_vendors_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '1') THEN
--
        lt_wk_segment1 := vendor_interface_rec.vndr_segment1;
        --# �ǉ�����
        ap_vendors_pkg.insert_row(
          or_vendors_rowid,   --OUT�ϐ�
          lt_wk_vendor_id,       --OUT�ϐ�
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          vendor_interface_rec.vndr_vendor_name,
          lt_wk_segment1,
          'N',
          'Y',
          xx00_global_pkg.last_update_login,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.created_by,
          vendor_interface_rec.vndr_employee_id,
          NULL,
          vendor_interface_rec.vndr_vendor_type_lkup_code,
          NULL,
          'N',
          NULL,
          NULL,
          financials_rec.ship_to_location_id,
          financials_rec.bill_to_location_id,
          financials_rec.ship_via_lookup_code,
          financials_rec.freight_terms_lookup_code,
          financials_rec.fob_lookup_code,
          NVL(vendor_interface_rec.vndr_terms_id,financials_rec.terms_id),
          in_set_of_books_id,
          financials_rec.always_take_disc_flag,
          payables_rec.pay_date_basis_lookup_code,
          vendor_interface_rec.vndr_pay_group_lkup_code,
          99,
          financials_rec.invoice_currency_code,
          financials_rec.payment_currency_code,
          vendor_interface_rec.vndr_invoice_amount_limit,
          'N',
          'N',
          NULL,
          NULL,
          vendor_interface_rec.vndr_accts_pay_ccid,
          NULL,
          vendor_interface_rec.vndr_prepay_ccid,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          id_start_date_active,
          vendor_interface_rec.vndr_end_date_active,
          receipts_rec.qty_rcv_tolerance,   --�f�[�^�Ȃ��̏ꍇ�́ANULL
          NULL,
          financials_rec.payment_method_lookup_code,
          NULL,
          NULL,
          NULL,
          NULL,
          'N',
          vendor_interface_rec.vndr_small_business_flag,
          NULL,
          vendor_interface_rec.vndr_attribute_category,
          vendor_interface_rec.vndr_attribute1,
          vendor_interface_rec.vndr_attribute2,
          vendor_interface_rec.vndr_attribute3,
          vendor_interface_rec.vndr_attribute4,
          vendor_interface_rec.vndr_attribute5,
          'N',
          NULL,
          NULL,
          NULL,
          payables_rec.terms_date_basis,
          NULL,
          vendor_interface_rec.vndr_attribute10,
          vendor_interface_rec.vndr_attribute11,
          vendor_interface_rec.vndr_attribute12,
          vendor_interface_rec.vndr_attribute13,
          vendor_interface_rec.vndr_attribute14,
          vendor_interface_rec.vndr_attribute15,
          vendor_interface_rec.vndr_attribute6,
          vendor_interface_rec.vndr_attribute7,
          vendor_interface_rec.vndr_attribute8,
          vendor_interface_rec.vndr_attribute9,
          receipts_rec.days_early_receipt_allowed,  --�f�[�^�Ȃ��̏ꍇ��NULL
          receipts_rec.days_late_receipt_allowed,   --�f�[�^�Ȃ��̏ꍇ��NULL
          receipts_rec.enforce_ship_to_location_code,  --�f�[�^�Ȃ��̏ꍇ��NULL
          financials_rec.exclusive_payment_flag,
          'N',
          financials_rec.hold_unmatched_invoices_flag,
          financials_rec.match_option,
          NULL,
          'N',
          NVL(vendor_interface_rec.VNDR_RECEIPT_REQUIRED_FLAG,'Y'),
          receipts_rec.receiving_routing_id,   --�f�[�^�Ȃ��̏ꍇ��NULL
          'N',
          NULL,
          'N',
          NULL,
          receipts_rec.allow_substitute_receipts_flag,  --�f�[�^�Ȃ��̏ꍇ��NULL
          receipts_rec.allow_unordered_receipts_flag,   --�f�[�^�Ȃ��̏ꍇ��NULL
          receipts_rec.receipt_days_exception_code,     --�f�[�^�Ȃ��̏ꍇ��NULL
          receipts_rec.qty_rcv_exception_code,          --�f�[�^�Ȃ��̏ꍇ��NULL
          'N',
          'N',
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.vndr_allow_awt_flag,'N'),
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.vndr_auto_tax_calc_flag,payables_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.vndr_auto_tax_calc_override,payables_rec.auto_tax_calc_override),
          payables_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.vndr_ap_tax_rounding_rule,financials_rec.tax_rounding_rule),
          vendor_interface_rec.vndr_vendor_name_alt,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(payables_rec.bank_charge_bearer,'I'),
          'XX03PVI001C');
--
          --# OUT�ϐ���ap_vendors_pkg.insert_row�Ŏ擾��vendor_id���Z�b�g
          ot_vendor_id := lt_wk_vendor_id;
--
        ELSIF (iv_process_mode in ('3','4')) THEN
          --# �X�V�Ώۃ��R�[�h�擾
          OPEN upd_vendors_cur(vendor_interface_rec.vndr_vendor_id);
          FETCH upd_vendors_cur INTO upd_vendors_rec;
          CLOSE upd_vendors_cur;
          --# �X�V�p�d����ԍ���ϐ��Ɋi�[
          IF (financials_rec.user_defined_vendor_num_code <> 'AUTOMATIC') THEN
            lt_wk_segment1 := vendor_interface_rec.vndr_segment1;
          ELSE
            lt_wk_segment1 := upd_vendors_rec.segment1;
          END IF;
          --# �X�V����
          ap_vendors_pkg.update_row(
            upd_vendors_rec.char_rowid,
            vendor_interface_rec.vndr_vendor_id,
            xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
            vendor_interface_rec.vndr_vendor_name,
            lt_wk_segment1,
            upd_vendors_rec.summary_flag,
            upd_vendors_rec.enabled_flag,
            xx00_global_pkg.last_update_login,
            upd_vendors_rec.employee_id,
            upd_vendors_rec.validation_number,
            upd_vendors_rec.vendor_type_lookup_code,
            upd_vendors_rec.customer_num,
            upd_vendors_rec.one_time_flag,
            upd_vendors_rec.parent_vendor_id,
            upd_vendors_rec.min_order_amount,
            upd_vendors_rec.ship_to_location_id,
            upd_vendors_rec.bill_to_location_id,
            upd_vendors_rec.ship_via_lookup_code,
            upd_vendors_rec.freight_terms_lookup_code,
            upd_vendors_rec.fob_lookup_code,
            NVL(vendor_interface_rec.vndr_terms_id,financials_rec.terms_id),
            upd_vendors_rec.set_of_books_id,
            upd_vendors_rec.always_take_disc_flag,
            upd_vendors_rec.pay_date_basis_lookup_code,
            vendor_interface_rec.vndr_pay_group_lkup_code,
            upd_vendors_rec.payment_priority,
            upd_vendors_rec.invoice_currency_code,
            upd_vendors_rec.payment_currency_code,
            vendor_interface_rec.vndr_invoice_amount_limit,
            upd_vendors_rec.hold_all_payments_flag,
            upd_vendors_rec.hold_future_payments_flag,
            upd_vendors_rec.hold_reason,
            upd_vendors_rec.distribution_set_id,
            vendor_interface_rec.vndr_accts_pay_ccid,
            upd_vendors_rec.future_dated_payment_ccid,
            vendor_interface_rec.vndr_prepay_ccid,
            upd_vendors_rec.num_1099,
            upd_vendors_rec.type_1099,
            upd_vendors_rec.withholding_status_lookup_code,
            upd_vendors_rec.withholding_start_date,
            upd_vendors_rec.organization_type_lookup_code,
            upd_vendors_rec.vat_code,
            id_start_date_active,
            vendor_interface_rec.vndr_end_date_active,
            upd_vendors_rec.qty_rcv_tolerance,
            upd_vendors_rec.minority_group_lookup_code,
            upd_vendors_rec.payment_method_lookup_code,
            upd_vendors_rec.bank_account_name,
            upd_vendors_rec.bank_account_num,
            upd_vendors_rec.bank_num,
            upd_vendors_rec.bank_account_type,
            upd_vendors_rec.women_owned_flag,
            vendor_interface_rec.vndr_small_business_flag,
            upd_vendors_rec.standard_industry_class,
            vendor_interface_rec.vndr_attribute_category,
            vendor_interface_rec.vndr_attribute1,
            vendor_interface_rec.vndr_attribute2,
            vendor_interface_rec.vndr_attribute3,
            vendor_interface_rec.vndr_attribute4,
            vendor_interface_rec.vndr_attribute5,
            upd_vendors_rec.hold_flag,
            upd_vendors_rec.purchasing_hold_reason,
            upd_vendors_rec.hold_by,
            upd_vendors_rec.hold_date,
            upd_vendors_rec.terms_date_basis,
            upd_vendors_rec.price_tolerance,
            vendor_interface_rec.vndr_attribute10,
            vendor_interface_rec.vndr_attribute11,
            vendor_interface_rec.vndr_attribute12,
            vendor_interface_rec.vndr_attribute13,
            vendor_interface_rec.vndr_attribute14,
            vendor_interface_rec.vndr_attribute15,
            vendor_interface_rec.vndr_attribute6,
            vendor_interface_rec.vndr_attribute7,
            vendor_interface_rec.vndr_attribute8,
            vendor_interface_rec.vndr_attribute9,
            upd_vendors_rec.days_early_receipt_allowed,
            upd_vendors_rec.days_late_receipt_allowed,
-- 1.2  Modify 2009/04/24  Bug�Ή�
--            upd_vendors_rec.days_late_receipt_allowed,
            upd_vendors_rec.enforce_ship_to_location_code,
-- End
            upd_vendors_rec.exclusive_payment_flag,
            upd_vendors_rec.federal_reportable_flag,
            upd_vendors_rec.hold_unmatched_invoices_flag,
            upd_vendors_rec.match_option,
            upd_vendors_rec.create_debit_memo_flag,
            upd_vendors_rec.inspection_required_flag,
            upd_vendors_rec.receipt_required_flag,
            upd_vendors_rec.receiving_routing_id,
            upd_vendors_rec.state_reportable_flag,
            upd_vendors_rec.tax_verification_date,
            upd_vendors_rec.auto_calculate_interest_flag,
            upd_vendors_rec.name_control,
            upd_vendors_rec.allow_substitute_receipts_flag,
            upd_vendors_rec.allow_unordered_receipts_flag,
            upd_vendors_rec.receipt_days_exception_code,
            upd_vendors_rec.qty_rcv_exception_code,
            upd_vendors_rec.offset_tax_flag,
            upd_vendors_rec.exclusive_payment_flag,
            upd_vendors_rec.vat_registration_num,
            upd_vendors_rec.tax_reporting_name,
            upd_vendors_rec.awt_group_id,
            upd_vendors_rec.check_digits,
            upd_vendors_rec.bank_number,
            NVL(vendor_interface_rec.vndr_allow_awt_flag,'N'),
            upd_vendors_rec.bank_branch_type,
            upd_vendors_rec.edi_payment_method,
            upd_vendors_rec.edi_payment_format,
            upd_vendors_rec.edi_remittance_method,
            upd_vendors_rec.edi_remittance_instruction,
            upd_vendors_rec.edi_transaction_handling,
            NVL(vendor_interface_rec.vndr_auto_tax_calc_flag,payables_rec.auto_tax_calc_flag),
            NVL(vendor_interface_rec.vndr_auto_tax_calc_override,
                payables_rec.auto_tax_calc_override) ,
            upd_vendors_rec.amount_includes_tax_flag,
            NVL(vendor_interface_rec.vndr_ap_tax_rounding_rule,financials_rec.tax_rounding_rule),
            vendor_interface_rec.vndr_vendor_name_alt,
            upd_vendors_rec.global_attribute_category,
            upd_vendors_rec.global_attribute1,
            upd_vendors_rec.global_attribute2,
            upd_vendors_rec.global_attribute3,
            upd_vendors_rec.global_attribute4,
            upd_vendors_rec.global_attribute5,
            upd_vendors_rec.global_attribute6,
            upd_vendors_rec.global_attribute7,
            upd_vendors_rec.global_attribute8,
            upd_vendors_rec.global_attribute9,
            upd_vendors_rec.global_attribute10,
            upd_vendors_rec.global_attribute11,
            upd_vendors_rec.global_attribute12,
            upd_vendors_rec.global_attribute13,
            upd_vendors_rec.global_attribute14,
            upd_vendors_rec.global_attribute15,
            upd_vendors_rec.global_attribute16,
            upd_vendors_rec.global_attribute17,
            upd_vendors_rec.global_attribute18,
            upd_vendors_rec.global_attribute19,
            upd_vendors_rec.global_attribute20,
            NVL(NVL(vendor_interface_rec.vndr_bank_charge_bearer,payables_rec.bank_charge_bearer),
                'I'),
            'XX03PVI001C');
--
            --# OUT�ϐ���vendor_id����
            ot_vendor_id := vendor_interface_rec.vndr_vendor_id;
--
      ELSE
        --# OUT�ϐ���vendor_id����
        ot_vendor_id := vendor_interface_rec.vndr_vendor_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '590';
      RAISE upd_vendors_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN upd_vendors_expt THEN           --*** �d����}�X�^�f�[�^�X�V���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�J�[�\���̃N���[�Y
      IF (upd_vendors_cur%ISOPEN) THEN
        CLOSE upd_vendors_cur;
      END IF;
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00012',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00011',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      --------------------------------------------------------------------------------------
      --# �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO main_loop_pvt;
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --�X�e�[�^�X���x���ŕԂ�
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_vendors;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_vendor_sites
   * Description      : �d����T�C�g�}�X�^�ւ̓o�^(A-6)
   ***********************************************************************************/
  PROCEDURE upd_vendor_sites(
    it_wk_vendor_id       IN po_vendors.vendor_id%TYPE,    --1.upd_vendors(A-6)�Ŏ擾��vendor_id
    vendor_interface_rec  IN vendor_interface_cur%ROWTYPE, --2.�d����IFT�̃f�[�^
    financials_rec        IN  financials_cur%ROWTYPE,      --3.��v�I�v�V�����f�[�^
    iv_process_mode       IN VARCHAR2,                     --4.�ǉ�/�X�V���[�h
    ov_upd_vs_rowid          OUT VARCHAR2, --ap_vendor_site_pkg.update_row��OUT�ϐ�
    on_upd_vs_vendor_site_id OUT NUMBER,   --upd_vendor_sites�Ŏ擾��vendor_sites_id
    ov_interface_errcode     OUT VARCHAR2, --�G���[���R�R�[�h
    ov_errbuf                OUT VARCHAR2, --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2, --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2) --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vendor_sites'; -- �v���O������
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
    lt_address_style        fnd_territories_vl.address_style%TYPE;  --�Z���`���f�[�^�i�[�p
    ln_wk_vendor_site_id    NUMBER;   --ap_vendor_site_pkg.update_row�Ŏ擾��vendr_seite_id
    lt_wk_vendor_site_code  po_vendor_sites.vendor_site_code%TYPE;
    lt_wk_vendor_id         po_vendor_sites_all.vendor_id%TYPE;  --�ǉ����g�p��vendor_id
    lt_lock_dummy           po_vendor_sites_all.vendor_site_id%TYPE; --���b�N�擾�p���[�N�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    --# �f�t�H���g�l�g�p�f�[�^�擾�J�[�\��
    CURSOR po_vendors_cur(
      it_wk_vendor_id IN po_vendors.vendor_id%TYPE,
      vndr_vendor_id  IN vendor_interface_rec.vndr_vendor_id%TYPE)
    IS
    SELECT ship_to_location_id,
           bill_to_location_id,
           ship_via_lookup_code,
           freight_terms_lookup_code,
           fob_lookup_code,
           payment_method_lookup_code,
           terms_date_basis,
           prepay_code_combination_id,
           payment_priority,
           terms_id,
           pay_date_basis_lookup_code,
           always_take_disc_flag,
           invoice_currency_code,
           payment_currency_code,
           hold_all_payments_flag,
           hold_future_payments_flag,
           hold_reason,
           hold_unmatched_invoices_flag,
           match_option,
           exclusive_payment_flag,
           exclude_freight_from_discount,
           offset_tax_flag,
           allow_awt_flag,
           auto_tax_calc_flag,
           auto_tax_calc_override,
           amount_includes_tax_flag,
           ap_tax_rounding_rule
    FROM   po_vendors
    WHERE  vendor_id = it_wk_vendor_id;
--
   --# update���g�p�f�[�^�擾�J�[�\��
   CURSOR vendors_site_all_cur (
     site_vendor_site_id IN vendor_interface_rec.site_vendor_site_id%TYPE)
   IS
     SELECT rowidtochar(rowid)  char_rowid,
            vendor_id,
            last_update_login,
            creation_date,
            created_by,
            purchasing_site_flag,
            rfq_only_site_flag,
            pay_site_flag,
            attention_ar_flag,
            customer_num,
            ship_to_location_id,
            bill_to_location_id,
            ship_via_lookup_code,
            freight_terms_lookup_code,
            fob_lookup_code,
            inactive_date,
            telex,
            bank_account_name,
            bank_account_num,
            bank_num,
            bank_account_type,
            terms_date_basis,
            current_catalog_num,
            accts_pay_code_combination_id,
            future_dated_payment_ccid,
            prepay_code_combination_id,
            payment_priority,
            pay_date_basis_lookup_code,
            always_take_disc_flag,
            invoice_currency_code,
            payment_currency_code,
            hold_all_payments_flag,
            hold_future_payments_flag,
            hold_reason,
            hold_unmatched_invoices_flag,
            match_option,
            exclusive_payment_flag,
            tax_reporting_site_flag,
            validation_number,
            exclude_freight_from_discount,
            vat_registration_num,
            offset_tax_flag,
            check_digits,
            bank_number,
            county,
            address_style,
            language,
            pay_on_code,
            default_pay_site_id,
            pay_on_receipt_summary_code,
            bank_branch_type,
            edi_id_number,
            edi_payment_method,
            edi_payment_format,
            edi_remittance_method,
            edi_remittance_instruction,
            edi_transaction_handling,
            amount_includes_tax_flag,
            global_attribute_category,
            global_attribute1,
            global_attribute2,
            global_attribute3,
            global_attribute4,
            global_attribute5,
            global_attribute6,
            global_attribute7,
            global_attribute8,
            global_attribute9,
            global_attribute10,
            global_attribute11,
            global_attribute12,
            global_attribute13,
            global_attribute14,
            global_attribute15,
            global_attribute16,
            global_attribute17,
            global_attribute18,
            global_attribute19,
            global_attribute20,
            ece_tp_location_code,
            pcard_site_flag,
            country_of_origin_code,
            remittance_email,
            primary_pay_site_flag
     FROM   po_vendor_sites_all
     WHERE  vendor_site_id = site_vendor_site_id;
--
    -- *** ���[�J���E���R�[�h ***
    ven_rec   po_vendors_cur%ROWTYPE;       --�f�t�H���g�l�g�p�f�[�^
    site_rec  vendors_site_all_cur%ROWTYPE; --�d����T�C�g�}�X�^UPDATE���g�p�f�[�^
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      -- ===============================
      --  �f�[�^�擾
      -- ===============================
      --# �f�t�H���g�l�g�p�f�[�^�擾
      OPEN po_vendors_cur(it_wk_vendor_id,vendor_interface_rec.vndr_vendor_id);
      FETCH po_vendors_cur INTO ven_rec;
      CLOSE po_vendors_cur;
      --# �Z���`���f�[�^�擾
      BEGIN
        SELECT ftv.address_style
        INTO   lt_address_style
        FROM   fnd_territories_vl ftv
        WHERE  ftv.territory_code = vendor_interface_rec.site_country;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_address_style := NULL;
      END;
--
      -- ===============================
      --  ���b�N�擾
      -- ===============================
-- N.Fujikawa Start
xx00_file_pkg.log('Lock Start');
-- N.Fujikawa End
-- N.Fujikawa Start
BEGIN
-- N.Fujikawa End
      SELECT pvsa.vendor_site_id
      INTO   lt_lock_dummy
      FROM   po_vendor_sites_all pvsa
      WHERE  ROWNUM = 1
      FOR UPDATE NOWAIT;
-- N.Fujikawa Start
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
-- N.Fujikawa End
END;
-- N.Fujikawa Start
xx00_file_pkg.log('Lock End');
-- N.Fujikawa End
--
      -- ===============================
      --  �d����T�C�g�}�X�^�ւ̓o�^
      -- ===============================
      IF (iv_process_mode IN ('1','2')) THEN
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode IN (''1'',''2'')');
-- N.Fujikawa End
--
        --�d�������̪��ð��ق��擾��site_vendor_site_code��ϐ��Ɋi�[
        lt_wk_vendor_site_code := vendor_interface_rec.site_vendor_site_code;
        --�d����ID��ϐ��Ɋi�[
        IF (iv_process_mode = '1') THEN
          lt_wk_vendor_id := it_wk_vendor_id;
        ELSIF (iv_process_mode = '2') THEN
          lt_wk_vendor_id := vendor_interface_rec.vndr_vendor_id;
        END IF;
--
        --# ���R�[�h�ǉ�
        ap_vendor_sites_pkg.insert_row(
          ov_upd_vs_rowid,
          ln_wk_vendor_site_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          lt_wk_vendor_id,
          lt_wk_vendor_site_code,
          xx00_global_pkg.last_update_login,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.created_by,
          NVL(vendor_interface_rec.site_purchasing_site_flag,'N'),
          'N',
          'Y',
          'N',
          vendor_interface_rec.site_address_line1,
          vendor_interface_rec.site_address_line2,
          vendor_interface_rec.site_address_line3,
          vendor_interface_rec.site_city,
          vendor_interface_rec.site_state,
          vendor_interface_rec.site_zip,
          vendor_interface_rec.site_province,
          vendor_interface_rec.site_country,
          vendor_interface_rec.site_area_code,
          vendor_interface_rec.site_phone,
          NULL,
          ven_rec.ship_to_location_id,
          ven_rec.bill_to_location_id,
          ven_rec.ship_via_lookup_code,
          ven_rec.freight_terms_lookup_code,
          ven_rec.fob_lookup_code,
          NULL,
          vendor_interface_rec.site_fax,
          vendor_interface_rec.site_fax_area_code,
          NULL,
          NVL(vendor_interface_rec.site_payment_method_lkup_code,
              ven_rec.payment_method_lookup_code),
          vendor_interface_rec.site_bank_account_name,
          vendor_interface_rec.site_bank_account_num,
          vendor_interface_rec.site_bank_num,
          vendor_interface_rec.site_bank_account_type,
          ven_rec.terms_date_basis,
          NULL,
          vendor_interface_rec.site_vat_code,
          vendor_interface_rec.site_distribution_set_id,
          NVL(vendor_interface_rec.site_accts_pay_ccid,
              financials_rec.accts_pay_code_combination_id)  ,
          financials_rec.future_dated_payment_ccid,
          NVL(vendor_interface_rec.site_prepay_ccid,ven_rec.prepay_code_combination_id),
          vendor_interface_rec.site_pay_group_lkup_code,
          ven_rec.payment_priority,
          NVL(vendor_interface_rec.site_terms_id,ven_rec.terms_id),
          vendor_interface_rec.site_invoice_amount_limit,
          ven_rec.pay_date_basis_lookup_code,
          ven_rec.always_take_disc_flag,
          ven_rec.invoice_currency_code,
          ven_rec.payment_currency_code,
          ven_rec.hold_all_payments_flag,
          ven_rec.hold_future_payments_flag,
          ven_rec.hold_reason,
          ven_rec.hold_unmatched_invoices_flag,
          ven_rec.match_option,
          NVL(vendor_interface_rec.site_create_debit_memo_flag,'N'),
          ven_rec.exclusive_payment_flag,
          'N',
          vendor_interface_rec.site_attribute_category,
          vendor_interface_rec.site_attribute1,
          vendor_interface_rec.site_attribute2,
          vendor_interface_rec.site_attribute3,
          vendor_interface_rec.site_attribute4,
          vendor_interface_rec.site_attribute5,
          vendor_interface_rec.site_attribute6,
          vendor_interface_rec.site_attribute7,
          vendor_interface_rec.site_attribute8,
          vendor_interface_rec.site_attribute9,
          vendor_interface_rec.site_attribute10,
          vendor_interface_rec.site_attribute11,
          vendor_interface_rec.site_attribute12,
          vendor_interface_rec.site_attribute13,
          vendor_interface_rec.site_attribute14,
          vendor_interface_rec.site_attribute15,
          NULL,
          ven_rec.exclude_freight_from_discount,
          NULL,
          ven_rec.offset_tax_flag,
          NULL,
          vendor_interface_rec.site_bank_number,
          vendor_interface_rec.site_address_line4,
          vendor_interface_rec.site_county,
          lt_address_style,
          NULL,
          NVL(vendor_interface_rec.site_allow_awt_flag,ven_rec.allow_awt_flag),
          vendor_interface_rec.site_awt_group_id,
          NULL,
          NULL,
          NULL,
          vendor_interface_rec.site_bank_branch_type,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NVL(vendor_interface_rec.site_auto_tax_calc_flag,ven_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.site_auto_tax_calc_override,ven_rec.auto_tax_calc_override),
          ven_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.site_ap_tax_rounding_rule,ven_rec.ap_tax_rounding_rule),
          vendor_interface_rec.site_vendor_site_code_alt,
          vendor_interface_rec.site_address_lines_alt,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          vendor_interface_rec.site_bank_charge_bearer,
          NULL,
          NULL,
          NULL,
          'XX03PVI001C',
          NULL,
          NVL(vendor_interface_rec.site_supplier_notif_method,'PRINT'),
          vendor_interface_rec.site_email_address,
          NULL,
          NVL(vendor_interface_rec.site_primary_pay_site_flag,'N'));
--
          --# OUT�ϐ���ap_vendor_site_pkg.update_row����擾��vendor_site_id����
          on_upd_vs_vendor_site_id := ln_wk_vendor_site_id;
--
      --# �d����T�C�g�}�X�^�X�V
      ELSIF (iv_process_mode = '3') THEN
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode = ''3'')');
-- N.Fujikawa End
        --# �f�[�^�擾
        OPEN  vendors_site_all_cur(vendor_interface_rec.site_vendor_site_id);
        FETCH vendors_site_all_cur INTO site_rec;
        CLOSE vendors_site_all_cur;
        --# ���R�[�h�X�V
        ap_vendor_sites_pkg.update_row(
          site_rec.char_rowid,
          vendor_interface_rec.site_vendor_site_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.last_updated_by,
          site_rec.vendor_id,
          vendor_interface_rec.site_vendor_site_code,
          xx00_global_pkg.last_update_login,
          site_rec.creation_date,
          site_rec.created_by,
          NVL(vendor_interface_rec.site_purchasing_site_flag,'N'),
          site_rec.rfq_only_site_flag,
          site_rec.pay_site_flag,
          site_rec.attention_ar_flag,
          vendor_interface_rec.site_address_line1,
          vendor_interface_rec.site_address_line2,
          vendor_interface_rec.site_address_line3,
          vendor_interface_rec.site_city,
          vendor_interface_rec.site_state,
          vendor_interface_rec.site_zip,
          vendor_interface_rec.site_province,
          vendor_interface_rec.site_country,
          vendor_interface_rec.site_area_code,
          vendor_interface_rec.site_phone,
          site_rec.customer_num,
          site_rec.ship_to_location_id,
          site_rec.bill_to_location_id,
          site_rec.ship_via_lookup_code,
          site_rec.freight_terms_lookup_code,
          site_rec.fob_lookup_code,
          site_rec.inactive_date,
          vendor_interface_rec.site_fax,
          vendor_interface_rec.site_fax_area_code,
          site_rec.telex,
          NVL(vendor_interface_rec.site_payment_method_lkup_code,
              ven_rec.payment_method_lookup_code),
          site_rec.bank_account_name,
          site_rec.bank_account_num,
          site_rec.bank_num,
          site_rec.bank_account_type,
          site_rec.terms_date_basis,
          site_rec.current_catalog_num,
          vendor_interface_rec.site_vat_code,
          vendor_interface_rec.site_distribution_set_id,
          site_rec.accts_pay_code_combination_id,
          site_rec.future_dated_payment_ccid,
          site_rec.prepay_code_combination_id,
          vendor_interface_rec.site_pay_group_lkup_code,
          site_rec.payment_priority,
          NVL(vendor_interface_rec.site_terms_id,ven_rec.terms_id),
          vendor_interface_rec.site_invoice_amount_limit,
          site_rec.pay_date_basis_lookup_code,
          site_rec.always_take_disc_flag,
          site_rec.invoice_currency_code,
          site_rec.payment_currency_code,
          site_rec.hold_all_payments_flag,
          site_rec.hold_future_payments_flag,
          site_rec.hold_reason,
          site_rec.hold_unmatched_invoices_flag,
          site_rec.match_option,
          NVL(vendor_interface_rec.site_create_debit_memo_flag,'N'),
          site_rec.exclusive_payment_flag,
          site_rec.tax_reporting_site_flag,
          vendor_interface_rec.site_attribute_category,
          vendor_interface_rec.site_attribute1,
          vendor_interface_rec.site_attribute2,
          vendor_interface_rec.site_attribute3,
          vendor_interface_rec.site_attribute4,
          vendor_interface_rec.site_attribute5,
          vendor_interface_rec.site_attribute6,
          vendor_interface_rec.site_attribute7,
          vendor_interface_rec.site_attribute8,
          vendor_interface_rec.site_attribute9,
          vendor_interface_rec.site_attribute10,
          vendor_interface_rec.site_attribute11,
          vendor_interface_rec.site_attribute12,
          vendor_interface_rec.site_attribute13,
          vendor_interface_rec.site_attribute14,
          vendor_interface_rec.site_attribute15,
          site_rec.validation_number,
          site_rec.exclude_freight_from_discount,
          site_rec.vat_registration_num,
          site_rec.offset_tax_flag,
          site_rec.check_digits,
          site_rec.bank_number,
          vendor_interface_rec.site_address_line4,
          site_rec.county,
          site_rec.address_style,
          site_rec.language,
          NVL(vendor_interface_rec.site_allow_awt_flag,ven_rec.allow_awt_flag),
          vendor_interface_rec.site_awt_group_id,
          site_rec.pay_on_code,
          site_rec.default_pay_site_id,
          site_rec.pay_on_receipt_summary_code,
          site_rec.bank_branch_type,
          site_rec.edi_id_number,
          site_rec.edi_payment_method,
          site_rec.edi_payment_format,
          site_rec.edi_remittance_method,
          site_rec.edi_remittance_instruction,
          site_rec.edi_transaction_handling,
          NVL(vendor_interface_rec.site_auto_tax_calc_flag,ven_rec.auto_tax_calc_flag),
          NVL(vendor_interface_rec.site_auto_tax_calc_override,ven_rec.auto_tax_calc_override),
          site_rec.amount_includes_tax_flag,
          NVL(vendor_interface_rec.site_ap_tax_rounding_rule,ven_rec.ap_tax_rounding_rule),
          vendor_interface_rec.site_vendor_site_code_alt,
          vendor_interface_rec.site_address_lines_alt,
          site_rec.global_attribute_category,
          site_rec.global_attribute1,
          site_rec.global_attribute2,
          site_rec.global_attribute3,
          site_rec.global_attribute4,
          site_rec.global_attribute5,
          site_rec.global_attribute6,
          site_rec.global_attribute7,
          site_rec.global_attribute8,
          site_rec.global_attribute9,
          site_rec.global_attribute10,
          site_rec.global_attribute11,
          site_rec.global_attribute12,
          site_rec.global_attribute13,
          site_rec.global_attribute14,
          site_rec.global_attribute15,
          site_rec.global_attribute16,
          site_rec.global_attribute17,
          site_rec.global_attribute18,
          site_rec.global_attribute19,
          site_rec.global_attribute20,
          vendor_interface_rec.site_bank_charge_bearer,
          site_rec.ece_tp_location_code,
          site_rec.pcard_site_flag,
          site_rec.country_of_origin_code,
          'XX03PVI001C',
          NULL,
          NVL(vendor_interface_rec.site_supplier_notif_method,'PRINT'),
          vendor_interface_rec.site_email_address,
          site_rec.remittance_email,
          NVL(site_rec.primary_pay_site_flag,'N'));
--
       --# OUT�ϐ���vendor_site_id���i�[
       on_upd_vs_vendor_site_id := vendor_interface_rec.site_vendor_site_id;
--
     ELSE
-- N.Fujikawa Start
xx00_file_pkg.log('iv_process_mode = else');
-- N.Fujikawa End
       --# OUT�ϐ���vendor_site_id���i�[
       on_upd_vs_vendor_site_id := vendor_interface_rec.site_vendor_site_id;
     END IF;
   EXCEPTION
     WHEN OTHERS THEN
-- N.Fujikawa Start
xx00_file_pkg.log(SQLCODE || '>>' || SQLERRM);
-- N.Fujikawa End
       lv_retcode := xx00_common_pkg.set_status_warn_f;
   END;
   IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
     ov_interface_errcode := '600';
     RAISE upd_vendor_sites_expt;
   END IF;
--
   --==============================================================
   --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN upd_vendor_sites_expt THEN        --*** �d����T�C�g�}�X�^�X�V���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�J�[�\���̃N���[�Y
      IF (po_vendors_cur%ISOPEN) THEN
        CLOSE po_vendors_cur;
      ELSIF (vendors_site_all_cur%ISOPEN) THEN
        CLOSE vendors_site_all_cur;
      END IF;
      --���b�Z�[�W�̃Z�b�g
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00013',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --------------------------------------------------------------------------------------
      --# �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO main_loop_pvt;
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --�X�e�[�^�X���x���ŕԂ�
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_vendor_sites;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_bank_accounts
   * Description      : ��s�����}�X�^�ւ̓o�^��X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_bank_accounts(
    iv_process_mode       IN  VARCHAR2,               --1.�ǉ�/�X�V���[�h
    vendor_interface_rec  IN  vendor_interface_cur%ROWTYPE,             --2.�d����IFT�̃f�[�^
    financials_rec        IN  financials_cur%ROWTYPE, --3.��v�I�v�V�����f�[�^
    payables_rec          IN  payables_cur%ROWTYPE,   --4.���|�Ǘ��I�v�V�����f�[�^
    ot_wk_bank_account_id  OUT ap_bank_accounts_all.bank_account_id%TYPE, --��s����ID
    ov_interface_errcode  OUT VARCHAR2,     -- �G���[���R�R�[�h
    ov_errbuf             OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bank_accounts'; -- �v���O������
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
    lt_wk_bank_branch_id   ap_bank_branches.bank_branch_id%TYPE;  --��s�x�XID
    lv_usr_prof_option     VARCHAR2(255); --xx00_profile_pkg.get�̖߂�l(հ�ޥ���̧�٥��߼��)
    --Ver11.5.10.1.3 2005.06.10 add START
    ln_org_id NUMBER;
    --Ver11.5.10.1.3 2005.06.10 add END
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    --Ver11.5.10.1.3 2005.06.10 add START
    --# �g�DID�̎擾
    xx00_profile_pkg.get('ORG_ID',ln_org_id);
    --Ver11.5.10.1.3 2005.06.10 add END
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '4') THEN
        --# �ǉ�/�X�V���[�h���C�̎��́A�o�^/�X�V�͍s��Ȃ��B
        NULL;
      ELSE
        --==============================================================
        -- �f�[�^�擾
        --==============================================================
        --# ��s�x�XID�擾
        SELECT abb.bank_branch_id
        INTO   lt_wk_bank_branch_id
        FROM   ap_bank_branches abb
        WHERE  abb.bank_name = vendor_interface_rec.acnt_bank_name
        AND    abb.bank_branch_name = vendor_interface_rec.acnt_bank_branch_name;
        --# ��s����ID�̎擾
        BEGIN
          SELECT bank_account_id
          INTO   ot_wk_bank_account_id
          FROM   ap_bank_accounts_all baa
          WHERE  baa.bank_account_num = vendor_interface_rec.acnt_bank_account_num
          AND    bank_branch_id = lt_wk_bank_branch_id
          AND    account_type = 'SUPPLIER'
          AND    NVL(currency_code,'null_currency') 
          = nvl(vendor_interface_rec.acnt_currency_code,'null_currency')
        --Ver11.5.10.1.3 2005.06.10 add START
          AND    org_id = ln_org_id
        --Ver11.5.10.1.3 2005.06.10 add END
          FOR UPDATE NOWAIT;
          --==============================================================
          -- �f�[�^�X�V�iBANK_ACCOUNT_ID���擾�ł����ꍇ�j
          --==============================================================
          UPDATE ap_bank_accounts_all
          set    bank_account_name       = vendor_interface_rec.acnt_bank_account_name,
                 last_update_date        = xx00_date_pkg.get_system_datetime_f,
                 last_updated_by         = xx00_global_pkg.last_updated_by,
                 last_update_login       = xx00_global_pkg.last_update_login,
                 attribute_category      = vendor_interface_rec.acnt_attribute_category,
                 attribute1              = vendor_interface_rec.acnt_attribute1,
                 attribute2              = vendor_interface_rec.acnt_attribute2,
                 attribute3              = vendor_interface_rec.acnt_attribute3,
                 attribute4              = vendor_interface_rec.acnt_attribute4,
                 attribute5              = vendor_interface_rec.acnt_attribute5,
                 attribute6              = vendor_interface_rec.acnt_attribute6,
                 attribute7              = vendor_interface_rec.acnt_attribute7,
                 attribute8              = vendor_interface_rec.acnt_attribute8,
                 attribute9              = vendor_interface_rec.acnt_attribute9,
                 attribute10             = vendor_interface_rec.acnt_attribute10,
                 attribute11             = vendor_interface_rec.acnt_attribute11,
                 attribute12             = vendor_interface_rec.acnt_attribute12,
                 attribute13             = vendor_interface_rec.acnt_attribute13,
                 attribute14             = vendor_interface_rec.acnt_attribute14,
                 attribute15             = vendor_interface_rec.acnt_attribute15,
                 request_id              = xx00_global_pkg.conc_request_id,
                 program_application_id  = xx00_global_pkg.prog_appl_id,
                 program_id              = xx00_global_pkg.conc_program_id,
                 program_update_date     = xx00_date_pkg.get_system_datetime_f,
                 account_holder_name     = vendor_interface_rec.acnt_account_holder_name,
                 account_holder_name_alt = vendor_interface_rec.acnt_account_holder_name_alt
          WHERE  bank_account_id = ot_wk_bank_account_id;
        EXCEPTION
          --# BANK_ACCOUNT_ID���擾�ł��Ȃ������ꍇ
          WHEN NO_DATA_FOUND THEN
            --# �V�[�P���X���擾
            SELECT ap_bank_accounts_s.nextval
            INTO   ot_wk_bank_account_id
            FROM   sys.dual;
            --��v����ID�̎擾
            xx00_profile_pkg.get('GL_SET_OF_BKS_ID',lv_usr_prof_option);
            --==============================================================
            -- �f�[�^�ǉ��iBANK_ACCOUNT_ID���擾�ł��Ȃ������ꍇ�j
            --==============================================================
            INSERT INTO ap_bank_accounts_all(
              bank_account_id,
              bank_account_name,
              last_update_date,
              last_updated_by,
              last_update_login,
              creation_date,
              created_by,
              bank_account_num,
              bank_branch_id,
              set_of_books_id,
              currency_code,
              description,
              contact_first_name,
              contact_middle_name,
              contact_last_name,
              contact_prefix,
              contact_title,
              contact_area_code,
              contact_phone,
              max_check_amount,
              min_check_amount,
              one_signature_max_flag,
              inactive_date,
              avg_float_days,
              asset_code_combination_id,
              gain_code_combination_id,
              loss_code_combination_id,
              bank_account_type,
              validation_number,
              max_outlay,
              multi_currency_flag,
              account_type,
              attribute_category,
              attribute1,
              attribute2,
              attribute3,
              attribute4,
              attribute5,
              attribute6,
              attribute7,
              attribute8,
              attribute9,
              attribute10,
              attribute11,
              attribute12,
              attribute13,
              attribute14,
              attribute15,
              pooled_flag,
              zero_amounts_allowed,
              request_id,
              program_application_id,
              program_id,
              program_update_date,
              receipt_multi_currency_flag,
              check_digits,
              org_id,
              cash_clearing_ccid,
              bank_charges_ccid,
              bank_errors_ccid,
              earned_ccid,
              unearned_ccid,
              on_account_ccid,
              unapplied_ccid,
              unidentified_ccid,
              factor_ccid,
              receipt_clearing_ccid,
              remittance_ccid,
              short_term_deposit_ccid,
              global_attribute_category,
              global_attribute1,
              global_attribute2,
              global_attribute3,
              global_attribute4,
              global_attribute5,
              global_attribute6,
              global_attribute7,
              global_attribute8,
              global_attribute9,
              global_attribute10,
              global_attribute11,
              global_attribute12,
              global_attribute13,
              global_attribute14,
              global_attribute15,
              global_attribute16,
              global_attribute17,
              global_attribute18,
              global_attribute19,
              global_attribute20,
              bank_account_name_alt,
              account_holder_name,
              account_holder_name_alt,
              eft_requester_id,
              eft_user_number,
              payroll_bank_account_id,
              future_dated_payment_ccid,
              edisc_receivables_trx_id,
              unedisc_receivables_trx_id,
              br_remittance_ccid,
              br_factor_ccid,
              br_std_receivables_trx_id,
              allow_multi_assignments_flag,
              agency_location_code)
            VALUES(
              ot_wk_bank_account_id,
              vendor_interface_rec.acnt_bank_account_name,
              xx00_date_pkg.get_system_datetime_f,
              xx00_global_pkg.last_updated_by,
              xx00_global_pkg.last_update_login,
              xx00_date_pkg.get_system_datetime_f,
              XX00_GLOBAL_PKG.CREATED_BY,
              vendor_interface_rec.acnt_bank_account_num,
              lt_wk_bank_branch_id,
--              xx00_profile_pkg.get('SET_OF_BOOKS_ID',lv_usr_prof_option),
              lv_usr_prof_option,
              vendor_interface_rec.acnt_currency_code,
              vendor_interface_rec.acnt_description,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              vendor_interface_rec.acnt_asset_id,
              payables_rec.gain_code_combination_id,
              payables_rec.loss_code_combination_id,
              vendor_interface_rec.acnt_bank_account_type,
              NULL,
              payables_rec.max_outlay,
              'N',
              'SUPPLIER',
              vendor_interface_rec.acnt_attribute_category,
              vendor_interface_rec.acnt_attribute1,
              vendor_interface_rec.acnt_attribute2,
              vendor_interface_rec.acnt_attribute3,
              vendor_interface_rec.acnt_attribute4,
              vendor_interface_rec.acnt_attribute5,
              vendor_interface_rec.acnt_attribute6,
              vendor_interface_rec.acnt_attribute7,
              vendor_interface_rec.acnt_attribute8,
              vendor_interface_rec.acnt_attribute9,
              vendor_interface_rec.acnt_attribute10,
              vendor_interface_rec.acnt_attribute11,
              vendor_interface_rec.acnt_attribute12,
              vendor_interface_rec.acnt_attribute13,
              vendor_interface_rec.acnt_attribute14,
              vendor_interface_rec.acnt_attribute15,
              'N',
              'N',
              xx00_global_pkg.conc_request_id,
              xx00_global_pkg.prog_appl_id,
              xx00_global_pkg.conc_program_id,
              xx00_date_pkg.get_system_datetime_f,
              payables_rec.multi_currency_flag,
              NULL,
            --Ver11.5.10.1.3 2005.06.10 modify START
              --to_number(xx00_profile_pkg.value('ORG_ID')),
              ln_org_id,
            --Ver11.5.10.1.3 2005.06.10 modify END
              vendor_interface_rec.acnt_cash_clearing_ccid,
              vendor_interface_rec.acnt_bank_charges_ccid,
              vendor_interface_rec.acnt_bank_errors_ccid,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              vendor_interface_rec.acnt_account_holder_name,
              vendor_interface_rec.acnt_account_holder_name_alt,
              NULL,
              NULL,
              NULL,
              financials_rec.future_dated_payment_ccid,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              'Y',
              NULL);
        END;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '610';
      RAISE upd_bank_accounts_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN upd_bank_accounts_expt THEN       --*** ��s�����}�X�^�f�[�^�X�V���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00014',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --# �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO main_loop_pvt;
      -----------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --�X�e�[�^�X���x���ŕԂ�
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_bank_accounts;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_bank_account_uses
   * Description      : ��s��������ð��قւ̓o�^��X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_bank_account_uses(
    iv_process_mode          IN  VARCHAR2,  --1.�ǉ�/�X�V���[�h
    it_wk_vendor_id          IN  po_vendors.vendor_id%TYPE,    --2.upd_vendors�Ŏ擾��vendor_id
    in_upd_vs_vendor_site_id IN  NUMBER,    --3.upd_vendor_sites�Ŏ擾��vendor_site_id
    vendor_interface_rec     IN  vendor_interface_cur%ROWTYPE, --4.�d����f�[�^
    it_wk_bank_account_id     IN  ap_bank_accounts_all.bank_account_id%TYPE, --5.��s����ID
    ov_interface_errcode OUT VARCHAR2,     --�G���[���R�R�[�h
    ov_errbuf            OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bank_account_uses'; -- �v���O������
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
    lr_wk_rowid   ROWID;            --ap_bank_account_uses_pkg.insert_row�Ŏ擾��OUT�ϐ�
    ln_wk_bank_account_uses_id  NUMBER;  --ap_bank_account_uses_pkg.insert_row�Ŏ擾��OUT�ϐ�
    lt_wk_lock    ap_bank_account_uses_all.bank_account_uses_id%TYPE; --���b�N�l�����g�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --�o�^�p�f�[�^�擾�J�[�\��
    CURSOR bank_account_uses_cur(
      it_wk_vendor_id           IN po_vendors.vendor_id%TYPE,
      in_upd_vs_vendor_site_id  IN NUMBER,
      it_wk_bank_account_id     IN ap_bank_accounts_all.bank_account_id%TYPE)
    IS
      SELECT rowidtochar(rowid) char_rowid,
             bank_account_uses_id,
             customer_id,
             customer_site_use_id,
             vendor_id,
             vendor_site_id,
             external_bank_account_id
      FROM   ap_bank_account_uses_all
      WHERE  vendor_id = it_wk_vendor_id
      AND    vendor_site_id = in_upd_vs_vendor_site_id
      AND    external_bank_account_id = it_wk_bank_account_id;
--
    -- *** ���[�J���E���R�[�h ***
    bank_account_uses_rec bank_account_uses_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      IF (iv_process_mode = '4') THEN
        --# �ǉ�/�X�V���[�h���C�̏ꍇ�́A�X�V/�ǉ��͍s��Ȃ�
        NULL;
      ELSE
        --==============================================================
        -- ���b�N�̊l��
        --==============================================================
-- N.Fujikawa Start
xx00_file_pkg.log('��s��������Lock Start');
-- N.Fujikawa End
-- N.Fujikawa Start
BEGIN
-- N.Fujikawa End
        SELECT uses.bank_account_uses_id
        INTO   lt_wk_lock
        FROM   ap_bank_account_uses_all uses
        WHERE  ROWNUM = 1
        FOR UPDATE NOWAIT;
-- N.Fujikawa Start
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
    END;
-- N.Fujikawa End
-- N.Fujikawa Start
xx00_file_pkg.log('��s��������Lock End');
-- N.Fujikawa End
        --==============================================================
        -- �f�[�^�̍X�V
        --==============================================================
        UPDATE ap_bank_account_uses_all
        SET    primary_flag      = 'N',
               last_update_date  = xx00_date_pkg.get_system_datetime_f,
               last_updated_by   = xx00_global_pkg.last_updated_by,
               last_update_login = xx00_global_pkg.last_update_login
        WHERE  bank_account_uses_id IN (
          SELECT abau.bank_account_uses_id
          FROM   ap_bank_account_uses_all abau,
                 ap_bank_accounts_all     aba
          WHERE  abau.external_bank_account_id = aba.bank_account_id
          AND    abau.vendor_id = it_wk_vendor_id
          AND    abau.vendor_site_id = in_upd_vs_vendor_site_id
          AND    abau.primary_flag='Y'
          AND    NVL(aba.currency_code,'null_currency')
                 = NVL(vendor_interface_rec.acnt_currency_code,'null_currency')
          AND    ( NVL(vendor_interface_rec.uses_start_date,TO_DATE('01-01-1000','DD-MM-YYYY'))
                 BETWEEN NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
                 OR  NVL(vendor_interface_rec.uses_end_date,TO_DATE('01-01-9999','DD-MM-YYYY'))
                 BETWEEN NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
                 OR   NVL(vendor_interface_rec.uses_start_date,TO_DATE('01-01-1000','DD-MM-YYYY'))
                 <= NVL(abau.start_date, TO_DATE('01-01-1000','DD-MM-YYYY'))
                 AND NVL(vendor_interface_rec.uses_end_date,TO_DATE('01-01-9999','DD-MM-YYYY')) 
                 >= NVL(abau.end_date, TO_DATE('01-01-9999','DD-MM-YYYY'))
               ));
        --==============================================================
        -- �f�[�^�擾
        --==============================================================
        OPEN  bank_account_uses_cur(it_wk_vendor_id,in_upd_vs_vendor_site_id,it_wk_bank_account_id);
        FETCH bank_account_uses_cur INTO bank_account_uses_rec;
        IF bank_account_uses_cur%NOTFOUND THEN
          --==============================================================
          -- �f�[�^�̒ǉ��i�f�[�^���擾�ł��Ȃ������ꍇ�j
          --==============================================================
          ap_bank_account_uses_pkg.insert_row(
            lr_wk_rowid,
            ln_wk_bank_account_uses_id,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.created_by,
            xx00_global_pkg.last_update_login,
            NULL,
            NULL,
            it_wk_vendor_id,
            in_upd_vs_vendor_site_id,
            it_wk_bank_account_id,
            vendor_interface_rec.uses_start_date,
            vendor_interface_rec.uses_end_date,
            'Y',
            vendor_interface_rec.uses_attribute_category,
            vendor_interface_rec.uses_attribute1,
            vendor_interface_rec.uses_attribute2,
            vendor_interface_rec.uses_attribute3,
            vendor_interface_rec.uses_attribute4,
            vendor_interface_rec.uses_attribute5,
            vendor_interface_rec.uses_attribute6,
            vendor_interface_rec.uses_attribute7,
            vendor_interface_rec.uses_attribute8,
            vendor_interface_rec.uses_attribute9,
            vendor_interface_rec.uses_attribute10,
            vendor_interface_rec.uses_attribute11,
            vendor_interface_rec.uses_attribute12,
            vendor_interface_rec.uses_attribute13,
            vendor_interface_rec.uses_attribute14,
            vendor_interface_rec.uses_attribute15);
        ELSE
          --==============================================================
          -- �f�[�^�̍X�V�i�f�[�^���擾�ł����ꍇ�j
          --==============================================================
          ap_bank_account_uses_pkg.update_row(
            bank_account_uses_rec.char_rowid,
            bank_account_uses_rec.bank_account_uses_id,
          xx00_date_pkg.get_system_datetime_f,
            xx00_global_pkg.last_updated_by,
            xx00_global_pkg.last_update_login,
            bank_account_uses_rec.customer_id,
            bank_account_uses_rec.customer_site_use_id,
            bank_account_uses_rec.vendor_id,
            bank_account_uses_rec.vendor_site_id,
            bank_account_uses_rec.external_bank_account_id,
            vendor_interface_rec.uses_start_date,
            vendor_interface_rec.uses_end_date,
            'Y',
            vendor_interface_rec.uses_attribute_category,
            vendor_interface_rec.uses_attribute1,
            vendor_interface_rec.uses_attribute2,
            vendor_interface_rec.uses_attribute3,
            vendor_interface_rec.uses_attribute4,
            vendor_interface_rec.uses_attribute5,
            vendor_interface_rec.uses_attribute6,
            vendor_interface_rec.uses_attribute7,
            vendor_interface_rec.uses_attribute8,
            vendor_interface_rec.uses_attribute9,
            vendor_interface_rec.uses_attribute10,
            vendor_interface_rec.uses_attribute11,
            vendor_interface_rec.uses_attribute12,
            vendor_interface_rec.uses_attribute13,
            vendor_interface_rec.uses_attribute14,
            vendor_interface_rec.uses_attribute15);
        END IF;
        CLOSE bank_account_uses_cur;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
-- N.Fujikawa Start
xx00_file_pkg.log(SQLCODE || '>>' || SQLERRM);
-- N.Fujikawa End
        --�J�[�\���̃N���[�Y
        IF (bank_account_uses_cur%ISOPEN) THEN
          CLOSE bank_account_uses_cur;
        END IF;
        lv_retcode := xx00_common_pkg.set_status_warn_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      ov_interface_errcode := '620';
      RAISE upd_bank_acnt_uses_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN upd_bank_acnt_uses_expt THEN      --*** ��s���������f�[�^�X�V���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --���b�Z�[�W�̃Z�b�g
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00015',
                                           'TOK_XX03_VENDOR_INTERFACE_ID',
                                           vendor_interface_rec.VENDORS_INTERFACE_ID,
                                           'TOK_XX03_INSERT_UPDATE_FLAG',
                                           iv_process_mode,
                                           'TOK_XX03_VENDOR_ID',
                                           vendor_interface_rec.vndr_vendor_id,
                                           'TOK_XX03_VENDOR_NAME',
                                           vendor_interface_rec.vndr_vendor_name,
                                           'TOK_XX03_VENDOR_SITE_ID',
                                           vendor_interface_rec.site_vendor_site_id,
                                           'TOK_XX03_VENDOR_SITE_CODE',
                                           vendor_interface_rec.site_vendor_site_code,
                                           'TOK_XX03_ERROR_REASON',
                                           xx03_get_error_message_pkg.get_error_message(
                                             'XX03_VENDOR_IF_ERROR_REASON',
                                             ov_interface_errcode));
      lv_errmsg := lv_errbuf;
      --# �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO main_loop_pvt;
      -----------------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --�X�e�[�^�X���x���ŕԂ�
      ov_retcode := xx00_common_pkg.set_status_warn_f;                     --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_bank_account_uses;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_ift
   * Description      : �d����C���^�[�t�F�[�X�e�[�u���̍X�V(A-9)
   ***********************************************************************************/
  PROCEDURE upd_ift(
    ir_rowid      IN  ROWID,             -- 1.ROWID
    it_status     IN  xx03_vendors_interface.status_flag%TYPE,  -- 2.��������/���s�׸�
    iv_interface_errcode  IN  VARCHAR2,  -- 3.�G���[���R�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ift'; -- �v���O������
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- =================================================
    -- �d����C���^�[�t�F�[�X�\�X�V
    -- =================================================
    IF (it_status = 'S') THEN
      --# �o�^�����t���O��������
      BEGIN
        UPDATE xx03_vendors_interface
        SET    status_flag            = it_status,
               error_reason           = null,
               last_update_date       = xx00_date_pkg.get_system_datetime_f,
               last_updated_by        = xx00_global_pkg.last_updated_by,
               last_update_login      = xx00_global_pkg.last_update_login,
               request_id             = xx00_global_pkg.conc_request_id,
               program_application_id = xx00_global_pkg.prog_appl_id,
               program_id             = xx00_global_pkg.conc_program_id,
               program_update_date    = xx00_date_pkg.get_system_datetime_f
        WHERE  ROWID = ir_rowid;
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE upd_ift_expt;
      END IF;
    ELSE
      --# �o�^���s�t���O��������
      BEGIN
        UPDATE xx03_vendors_interface
        SET    status_flag            = it_status,
               error_reason           = iv_interface_errcode,
               last_update_date       = xx00_date_pkg.get_system_datetime_f,
               last_updated_by        = xx00_global_pkg.last_updated_by,
               last_update_login      = xx00_global_pkg.last_update_login,
               request_id             = xx00_global_pkg.conc_request_id,
               program_application_id = xx00_global_pkg.prog_appl_id,
               program_id             = xx00_global_pkg.conc_program_id,
               program_update_date    = xx00_date_pkg.get_system_datetime_f
        WHERE  ROWID = ir_rowid;
      EXCEPTION
        WHEN OTHERS THEN
          lv_retcode := xx00_common_pkg.set_status_error_f;
      END;
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        RAISE upd_ift_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN upd_ift_expt THEN              --*** �d�������̪��ð��ٍX�V ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�Z�b�g
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00016');
      lv_errmsg := lv_errbuf;
      --���[���o�b�N
      Rollback;
      -------------------------------------------------------------------------------
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_ift;
--
--
  /**********************************************************************************
   * Procedure Name   : main_loop
   * Description      : �d����f�[�^���o(A-3)
   ***********************************************************************************/
  PROCEDURE main_loop(
    iv_force_flag            IN  VARCHAR2,     -- �����t���O
    id_start_date_active     IN  DATE,         -- �Ɩ����t
    it_chart_of_accounts_id  IN  gl_sets_of_books.chart_of_accounts_id%TYPE,  -- ����̌nID
    financials_rec           IN  financials_cur%ROWTYPE,      -- ��v�I�v�V�����f�[�^
    payables_rec             IN  payables_cur%ROWTYPE,        -- ���|�Ǘ��I�v�V�����f�[�^
    receipts_rec             IN  rcv_parameters_cur%ROWTYPE,  -- ����I�v�V�����f�[�^
    in_set_of_books_id       IN  NUMBER,       -- ��v����ID
    on_target_count          OUT NUMBER,       -- �����Ώی���
    on_err_count             OUT NUMBER,       -- �G���[�f�[�^����
    on_success_count         OUT NUMBER,       -- ��������I������
    ov_errbuf                OUT VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode               OUT VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main_loop'; -- �v���O������
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
    lv_interface_errcode      VARCHAR2(3); --�G���[���R�R�[�h
    lv_process_mode           VARCHAR2(1); --�ǉ�/�X�V���[�h
    lr_wk_vendors_rowid       ROWID;       --ap_vendors_pkg.insert_row�Ŏ擾��OUT�ϐ�(ROWID)
    lt_wk_vendor_id           po_vendors.vendor_id%TYPE; --upd_vendors�Ŏ擾��vendor_id
    lv_upd_vs_rowid           VARCHAR2(2000);  --ap_vendor_site_pkg.update_row��OUT�ϐ�
    ln_upd_vs_vendor_site_id  NUMBER;      --upd_vendor_sites�Ŏ擾��vendor_site_id
    lt_wk_bank_account_id     ap_bank_accounts_all.bank_account_id%TYPE; --��s����ID
    lv_wk_process_status      VARCHAR2(1); --�e�������̏�������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --# ��������
    on_target_count  := 0;  --�����Ώی���
    on_err_count     := 0;  --�G���[����
    on_success_count := 0;  --������������
--
    --==============================================================
    -- �Ώۃf�[�^�̎擾
    --==============================================================
    << vendor_ift_loop >>
    FOR vendor_interface_rec IN vendor_interface_cur(iv_force_flag) LOOP
      --# SavePoint�̐ݒ�
      SAVEPOINT main_loop_pvt;
      lv_interface_errcode := NULL;
      --�����Ώۃf�[�^�����̃J�E���g
      on_target_count := on_target_count + 1;
      --�������̏������ʊi�[�ϐ��̏�����
     lv_wk_process_status := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
      -- =================================================
      --  A-4.�d�����ް��̑Ó��������ivalid_data�j
      -- =================================================
      valid_data(
        vendor_interface_rec,  -- �d����IFT�̃f�[�^
        financials_rec,        -- ��v�I�v�V�����f�[�^
        iv_force_flag,         -- �����t���O
        id_start_date_active,  -- �Ɩ����t
        it_chart_of_accounts_id,  -- ����̌nID
        lv_process_mode,       -- �ǉ�/�X�V���[�h
        lv_interface_errcode,  -- �G���[���R�R�[�h
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --# �������ʂ�ϐ��ɕێ�
      lv_wk_process_status := lv_retcode;
      --# �G���[����
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --���O����b�Z�[�W�̏o��
        xx00_file_pkg.log(lv_errbuf);
        xx00_file_pkg.output(lv_errmsg);
        --�G���[�f�[�^�����̃J�E���g
        on_err_count := on_err_count + 1;
        ov_retcode := lv_retcode;
        -- =================================================
        --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
        -- =================================================
        --# �d����f�[�^�Ó����`�F�b�N���s���i�X�e�[�^�X�F�G���[�j
        upd_ift(
          vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
          'E',                         --�������s�̃X�e�[�^�X
          lv_interface_errcode,        --�G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
        --# �G���[���͏����I��
        RAISE global_process_expt;
      --# �x������
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        --���O����b�Z�[�W�̏o��
        xx00_file_pkg.log(lv_errbuf);
        xx00_file_pkg.output(lv_errmsg);
        --�G���[�f�[�^�����̃J�E���g
        on_err_count := on_err_count + 1;
        ov_retcode := lv_retcode;
        -- =================================================
        --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
        -- =================================================
        --# �d����f�[�^�Ó����`�F�b�N���s���i�X�e�[�^�X�F�x���j
        upd_ift(
          vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
          'E',                         --�������s�̃X�e�[�^�X
          lv_interface_errcode,        --�G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-5.�d����}�X�^�ւ̓o�^�iupd_vendors�j
        -- =================================================
        upd_vendors(
          lv_process_mode,       -- �ǉ�/�X�V���[�h
          vendor_interface_rec,  -- �d����IFT�̃f�[�^
          financials_rec,        -- ��v�I�v�V�����f�[�^
          payables_rec,          -- ���|�Ǘ��I�v�V�����f�[�^
          receipts_rec,          -- ����I�v�V�����f�[�^
          in_set_of_books_id,    -- ��v����ID
          id_start_date_active,  -- �Ɩ����t
          lr_wk_vendors_rowid,   --ap_vendors_pkg.insert_row�Ŏ擾��OUT�ϐ�
          lt_wk_vendor_id,       --ap_vendors_pkg.insert_row�Ŏ擾��OUT�ϐ�
          lv_interface_errcode,  --�G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --# �������ʂ�ϐ��ɕێ�
        lv_wk_process_status := lv_retcode;
        --# �G���[����
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# �d����}�X�^�o�^���s���i�X�e�[�^�X�F�G���[�j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# �G���[���͏����I��
          RAISE global_process_expt;
        --# �x������
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# �d����}�X�^�o�^���s���i�X�e�[�^�X�F�x���j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-6.�d����T�C�g�}�X�^�ւ̓o�^�iupd_vendor_sites�j
        -- =================================================
        upd_vendor_sites(
          lt_wk_vendor_id,      --A-5.upd_vendors(ap_vendors_pkg.insert_row)�Ŏ擾��OUT�ϐ�
          vendor_interface_rec, --�d����IFT�̃f�[�^
          financials_rec,       --��v�I�v�V�����f�[�^
          lv_process_mode,      --�ǉ�/�X�V���[�h
          lv_upd_vs_rowid,      --ap_vendor_site_pkg.update_row��OUT�ϐ�
          ln_upd_vs_vendor_site_id, --ap_vendor_site_pkg.update_row��OUT�ϐ�
          lv_interface_errcode,        --�G���[���R�R�[�h
          lv_errbuf,            --�G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           --���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --# �������ʂ�ϐ��ɕێ�
        lv_wk_process_status := lv_retcode;
        --# �G���[����
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# �d����T�C�g�}�X�^�o�^���s���i�X�e�[�^�X�F�G���[�j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# �G���[���͏����I��
          RAISE global_process_expt;
        --# �x������
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# �d����T�C�g�}�X�^�o�^���s���i�X�e�[�^�X�F�x���j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-7.��s�����}�X�^�ւ̓o�^�iupd_bank_accounts�j
        -- =================================================
        upd_bank_accounts(
          lv_process_mode,       -- �ǉ�/�X�V���[�h
          vendor_interface_rec,  -- �d����IFT�̃f�[�^
          financials_rec,        -- ��v�I�v�V�����f�[�^
          payables_rec,          -- ���|�Ǘ��I�v�V�����f�[�^
          lt_wk_bank_account_id,  -- ��s����ID
          lv_interface_errcode,  -- �G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --# �������ʂ�ϐ��ɕێ�
        lv_wk_process_status := lv_retcode;
        --# �G���[����
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# ��s�����}�X�^�o�^���s���i�X�e�[�^�X�F�G���[�j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# �G���[���͏����I��
          RAISE global_process_expt;
        --# �x������
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# ��s�����}�X�^�o�^���s���i�X�e�[�^�X�F�x���j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =======================================================
        --  A-8.��s��������ð��قւ̓o�^�iupd_bank_account_uses�j
        -- =======================================================
        upd_bank_account_uses(
          lv_process_mode,           -- �ǉ�/�X�V���[�h
          lt_wk_vendor_id,           -- upd_vendors�Ŏ擾��vendor_id
          ln_upd_vs_vendor_site_id,  -- upd_vendor_sites�Ŏ擾��vendor_site_id
          vendor_interface_rec,      -- �d����f�[�^
          lt_wk_bank_account_id,      -- ��s����ID
          lv_interface_errcode,      -- �G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --# �������ʂ�ϐ��ɕێ�
        lv_wk_process_status := lv_retcode;
        --# �G���[����
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# ��s�����}�X�^�o�^���s���i�X�e�[�^�X�F�G���[�j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
          --# �G���[���͏����I��
          RAISE global_process_expt;
        --# �x������
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���O����b�Z�[�W�̏o��
          xx00_file_pkg.log(lv_errbuf);
          xx00_file_pkg.output(lv_errmsg);
          --�G���[�f�[�^�����̃J�E���g
          on_err_count := on_err_count + 1;
          ov_retcode := lv_retcode;
          -- =================================================
          --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
          -- =================================================
          --# ��s�����}�X�^�o�^���s���i�X�e�[�^�X�F�x���j
          upd_ift(
            vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
            'E',                         --�������s�̃X�e�[�^�X
            lv_interface_errcode,        --�G���[���R�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      IF (lv_wk_process_status = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        -- =================================================
        --  A-9.�d�������̪��ð��ٍX�V(upd_ift)
        -- =================================================
        --# ���ׂĂ̓o�^������ɏI��
        upd_ift(
          vendor_interface_rec.rowid,  --�Ώۃf�[�^��ROWID
          'S',                         --�������s�̃X�e�[�^�X
          NULL,                        --�G���[���R�R�[�h
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
--
        --�������������̃J�E���g
        on_success_count := on_success_count + 1;
      END IF;
--
    END LOOP vendor_ift_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END main_loop;
--
--
  /**********************************************************************************
   * Procedure Name   : del_ift
   * Description      : �C���|�[�g�����f�[�^�폜(A-10)
   ***********************************************************************************/
  PROCEDURE del_ift(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ift'; -- �v���O������
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      DELETE FROM xx03_vendors_interface
      WHERE  status_flag = 'S';
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode := xx00_common_pkg.set_status_error_f;
    END;
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      RAISE del_ift_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN del_ift_expt THEN       --*** �C���|�[�g�����f�[�^�폜���s ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errbuf := xx00_message_pkg.get_msg(cv_msg_appl_name,
                                           'APP-XX03-00017');
      lv_errmsg := lv_errbuf;
      --���[���o�b�N
      Rollback;
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_ift;
--
--
  /**********************************************************************************
   * Procedure Name   : msg_processed_data
   * Description      : ���b�Z�[�W�o��(A-11)
   ***********************************************************************************/
  PROCEDURE msg_processed_data(
    in_target_count  IN  NUMBER,   -- �����Ώی���
    in_err_count     IN  NUMBER,   -- �G���[�f�[�^����
    in_success_count IN  NUMBER,   -- ������������
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_processed_data'; -- �v���O������
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    --  �Ώۃf�[�^�����o��
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00023',
                                               'TOK_XX03_ALL_COUNT',
                                               in_target_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00023',
                                               'TOK_XX03_ALL_COUNT',
                                               in_target_count));
    -- ===============================
    --  �C���|�[�g�����f�[�^�����o��
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00024',
                                               'TOK_XX03_NORMAL_COUNT',
                                               in_success_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00024',
                                               'TOK_XX03_NORMAL_COUNT',
                                               in_success_count));
    -- ===============================
    --  �G���[�f�[�^�����o��
    -- ===============================
    xx00_file_pkg.log(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00025',
                                               'TOK_XX03_ERROR_COUNT',
                                               in_err_count));
    xx00_file_pkg.output(xx00_message_pkg.get_msg(cv_msg_appl_name,
                                               'APP-XX03-00025',
                                               'TOK_XX03_ERROR_COUNT',
                                               in_err_count));
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END msg_processed_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_force_flag          IN  VARCHAR2,  --�����t���O
    iv_start_date_active   IN  VARCHAR2,  --�Ɩ����t
    ov_errbuf              OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_start_date_active      DATE;    --�Ɩ����t
    financials_rec            financials_cur%ROWTYPE;     --��v�I�v�V�����f�[�^
    payables_rec              payables_cur%ROWTYPE;       --���|�Ǘ��I�v�V�����f�[�^
    receipts_rec              rcv_parameters_cur%ROWTYPE; --����I�v�V�����f�[�^
    lt_chart_of_accounts_id   gl_sets_of_books.chart_of_accounts_id%TYPE;  --����̌nID
    ln_set_of_books_id        NUMBER;  --��v����ID
    ln_target_count           NUMBER;  --�����Ώی���
    ln_err_count              NUMBER;  --�G���[�f�[�^����
    ln_success_count          NUMBER;  --������������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ============================================
    --  A-1.�p�����[�^�̃`�F�b�N�ichk_param�j
    -- ============================================
    chk_param(
      iv_force_flag,          -- �����t���O
      iv_start_date_active,   -- �Ɩ����t
      ld_start_date_active,   -- �Ɩ����t�iDATE�^�j
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- ============================================
    --  A-2.�e��f�[�^�擾 (get_option_data)
    -- ============================================
    get_option_data(
      financials_rec,  --��v�I�v�V�����f�[�^
      payables_rec,    --���|�Ǘ��I�v�V�����f�[�^
      receipts_rec,    --����I�v�V�����f�[�^
      lt_chart_of_accounts_id,  --����ȖڃR�[�h
      ln_set_of_books_id,       --��v����ID
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- ============================================
    --  A-3.�d����f�[�^���o (main_loop)
    -- ============================================
    main_loop(
      iv_force_flag,           -- �����t���O
      ld_start_date_active,    -- �Ɩ����t(DATE�^)
      lt_chart_of_accounts_id, -- ����̌nID
      financials_rec,          -- ��v�I�v�V�����f�[�^
      payables_rec,            -- ���|�Ǘ��I�v�V�����f�[�^
      receipts_rec,            -- ����I�v�V�����f�[�^
      ln_set_of_books_id,      -- ��v����ID
      ln_target_count,   -- �����Ώی���
      ln_err_count,      -- �G���[�f�[�^����
      ln_success_count,  -- ������������
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =========================================
    --  A-10.�C���|�[�g�����f�[�^�폜 (del_ift) 
    -- =========================================
    del_ift(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =========================================
    --  A-11.���b�Z�[�W�o�� (msg_processed_data)
    -- =========================================
    msg_processed_data(
      ln_target_count,   -- �����Ώی���
      ln_err_count,      -- �G���[�f�[�^����
      ln_success_count,  -- ������������
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
    errbuf                 OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_force_flag          IN  VARCHAR2,  --�����t���O
    iv_start_date_active   IN  VARCHAR2)  --�Ɩ����t
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
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================
    -- ���O�w�b�_�̏o��
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_force_flag,          -- �����t���O
      iv_start_date_active,   -- �Ɩ����t
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ���O�t�b�^�̏o��
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XX03PVI001C;
/
