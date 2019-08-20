CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSO010A07C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ�_��X�V�f�[�^����荞�݂܂��B
 *
 * MD.050           : MD050_CSO_010_A07_�_��X�VCSV�A�b�v���[�h
 *
 * Version          : 1.01
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  output_result        �������ʌ����o��
 *  chk_data             �f�[�^�Ó����`�F�b�N
 *  update_data          �_����̍X�V
 *  output_file          �ύX�O�X�V��m�F�p�f�[�^�̏o��
 *  submain               ���C�������v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019-03-28    1.00  T.Kawaguchi      �V�K�쐬
 *  2019-07-30    1.01  S.Kuwako         �G���[�������̃��b�Z�[�W�A����яI���X�e�[�^�X�̏C��
 *                                       �R���J�����g�o�̓t�H�[�}�b�g�̏C��
 *
 *****************************************************************************************/
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCSO010A07C';      -- �p�b�P�[�W��
  cv_msg_cont                    CONSTANT VARCHAR2(3)   := '.';
  cv_msg_part                    CONSTANT VARCHAR2(3)   := ' : ';
  cv_app_name                    CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k�� �c��
  cv_app_name_xxccp              CONSTANT VARCHAR2(5)   := 'XXCCP';             -- �A�v���P�[�V�����Z�k�� ���ʁEIF
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  global_upd_expt                    EXCEPTION;                                         -- �X�V�G���[
  global_lock_expt                   EXCEPTION;                                         -- ���b�N��O
  global_api_others_expt             EXCEPTION;                                         -- �V�X�e����O
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  cv_separator                   CONSTANT VARCHAR2(1)   := ',';
  cv_double_quotation            CONSTANT VARCHAR2(1)   := '"';
  cv_enabled_flag                CONSTANT VARCHAR2(1)   := 'Y';                 -- �L��
  cv_exec_cls_chk                CONSTANT VARCHAR2(1)   := '0';                 -- �����敪 �m�F
  cv_exec_cls_update             CONSTANT VARCHAR2(1)   := '1';                 -- �����敪 �X�V
  cv_bm_pay_acc_w_guide          CONSTANT VARCHAR2(1)   := '1';                 -- BM�x���敪�F�{�U�i�ē�������j
  cv_bm_pay_acc_no_guide         CONSTANT VARCHAR2(1)   := '2';                 -- BM�x���敪�F�{�U�i�ē����Ȃ��j
  cv_day_type_month_end          CONSTANT VARCHAR2(20)  := '30';                -- ���t�^�C�v�F����
  cv_day_type_20                 CONSTANT VARCHAR2(20)  := '20';                -- ���t�^�C�v�F20
  cv_month_type_next_month       CONSTANT VARCHAR2(20)  := '50';                -- ���^�C�v�F����
  cv_done                        CONSTANT VARCHAR2(1)   := '1';                 -- �t���O�F��
  cv_yet                         CONSTANT VARCHAR2(1)   := '0';                 -- �t���O�F��
  cv_elec_type_static            CONSTANT VARCHAR2(1)   := '1';                 -- �d�C��敪 ��z
  cv_elec_type_vary              CONSTANT VARCHAR2(1)   := '2';                 -- �d�C��敪 �ϊz
  cv_batch_status_normal         CONSTANT VARCHAR2(1)   := '0';                 -- �o�b�`�x���X�e�[�^�X ����
  cn_exec_cls                    CONSTANT NUMBER        := 1;                   -- CSV���� �����敪
  cn_customer_code               CONSTANT NUMBER        := 2;                   -- CSV���� �ڋq�R�[�h
  cn_cur_sup_code                CONSTANT NUMBER        := 3;                   -- CSV���� ���d����R�[�h
  cn_new_sup_code                CONSTANT NUMBER        := 4;                   -- CSV���� �V�d����R�[�h
  cn_new_close_day_code          CONSTANT NUMBER        := 5;                   -- CSV���� �V���ߓ�
  cn_new_trans_month_code        CONSTANT NUMBER        := 6;                   -- CSV���� �V�U����
  cn_new_trans_day_code          CONSTANT NUMBER        := 7;                   -- CSV���� �V�U����
  cn_error_msg                   CONSTANT NUMBER        := 8;                   -- CSV���� �G���[���b�Z�[�W
  cn_conv_new_close_day_code     CONSTANT NUMBER        := 9;                   -- CSV���� �V���ߓ� �Q�ƃR�[�h�ɕϊ���
  cn_conv_new_trans_month_code   CONSTANT NUMBER        := 10;                  -- CSV���� �V�U���� �Q�ƃR�[�h�ɕϊ���
  cn_conv_new_trans_day_code     CONSTANT NUMBER        := 11;                  -- CSV���� �V�U���� �Q�ƃR�[�h�ɕϊ���
  -- �v���t�@�C��
  cv_pf_org_id                   CONSTANT VARCHAR2(30)  := 'ORG_ID';            -- MO:�c�ƒP��
  -- ���b�Z�[�W�R�[�h
  cv_param_fileid_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �p�����[�^�t�@�C��ID�o�̓��b�Z�[�W
  cv_param_formatptn_msg         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �p�����[�^�t�H�[�}�b�g�p�^�[���o�̓��b�Z�[�W
  cv_param_formatname_msg        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00890';  -- �p�����[�^�t�H�[�}�b�g�p�^�[�����o�̓��b�Z�[�W
  cv_param_filename_msg          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �A�b�v���[�h�t�@�C�����̏o�̓��b�Z�[�W
  cv_target_rec_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_normal_rec_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- ���팏�����b�Z�[�W
  cv_warn_rec_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001';  -- �x���������b�Z�[�W
  cv_error_rec_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_normal_msg                  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
-- *********** 2019/07/30 1.01 S.Kuwako DEL START *********** --
--  cv_warn_msg                    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
-- *********** 2019/07/30 1.01 S.Kuwako DEL END   *********** --
  cv_error_msg                   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_param_err_msg               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- �p�����[�^�Ó����`�F�b�N�G���[���b�Z�[�W
  cv_param_required_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- ���̓p�����[�^�K�{�G���[
  cv_update_err_msg              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00337';  -- �f�[�^�X�V�G���[
  cv_lock_err_msg                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00386';  -- ���b�N�G���[
  cv_dup_dest_err_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00521';  -- ���t��R�[�h�d���G���[
  cv_comb_3_chk_msg              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00891';  -- �g��(3����)�`�F�b�N
  cv_comb_chk_msg                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00892';  -- �g���`�F�b�N
  cv_pay_line_chk_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00893';  -- �x�����׏��������G���[
  cv_sall_bm_chk_msg             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00894';  -- �̔��萔���������G���[
  cv_new_sup_bm_inte_msg         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00895';  -- �V�d����BM�x���敪�������G���[
  cv_head_upld_err_list_msg      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00896';  -- �A�b�v���[�h�G���[���X�g�w�b�_�[�s
  cv_head_chk_cont_mng_msg       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00897';  -- �_��Ǘ��ύX�O�X�V��m�F�p���X�g�w�b�_�[�s
  cv_head_chk_dest_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00898';  -- ���t��ύX�O�X�V��m�F�p���X�g�w�b�_�[�s
  cv_head_chk_cust_inf_msg       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00899';  -- �ڋq�ǉ����ύX�O�X�V��m�F�p���X�g�w�b�_�[�s
  -- �g�[�N���R�[�h
  cv_tkn_table                   CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_item                    CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_count                   CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_file_id                 CONSTANT VARCHAR2(20)  := 'FILE_ID';
  cv_tkn_format_pattern          CONSTANT VARCHAR2(20)  := 'FORMAT_PATTERN';
  cv_tkn_format_name             CONSTANT VARCHAR2(20)  := 'FORMAT_NAME';
  cv_tkn_error_message           CONSTANT VARCHAR2(20)  := 'ERROR_MESSAGE';
  cv_tkn_key                     CONSTANT VARCHAR2(20)  := 'KEY';
  cv_tkn_entry1                  CONSTANT VARCHAR2(20)  := 'ENTRY1';
  cv_tkn_entry2                  CONSTANT VARCHAR2(20)  := 'ENTRY2';
  cv_tkn_entry3                  CONSTANT VARCHAR2(20)  := 'ENTRY3';
  cv_tkn_action                  CONSTANT VARCHAR2(20)  := 'ACTION';
  cv_tkn_file_name               CONSTANT VARCHAR2(20)  := 'UPLOAD_FILE_NAME';
  cv_tkn_errmsg                  CONSTANT VARCHAR2(100) := 'ERRMSG';
  -- �g�[�N���̓��e
  cv_exec_cls                    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00777';   -- �����敪
  cv_costomer_code               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';   -- �ڋq�R�[�h
  cv_cur_sup_code                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00900';   -- ���d����R�[�h
  cv_new_sup_code                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00901';   -- �V�d����R�[�h
  cv_new_close_day               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00902';   -- �V���ߓ�
  cv_new_trans_month             CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00903';   -- �V�U����
  cv_new_trans_day               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00904';   -- �V�U����
  cv_dest_table                  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00905';   -- ���t��e�[�u��
  cv_cust_account                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00906';   -- �ڋq�ǉ����
  cv_contract_mng                CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00907';   -- �_��Ǘ��e�[�u��
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
  cv_upld_err_list               CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00908';   -- �A�b�v���[�h�G���[���X�g
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
  -- �Q�ƃ^�C�v
  cv_type_file_upld_obj          CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ'; -- �Q�ƃ^�C�v �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_type_days_type              CONSTANT VARCHAR2(100) := 'XXCSO1_DAYS_TYPE';       -- �Q�ƃ^�C�v ���t�^�C�v
  cv_type_months_type            CONSTANT VARCHAR2(100) := 'XXCSO1_MONTHS_TYPE';     -- �Q�ƃ^�C�v ���^�C�v
--
  /**********************************************************************************
   * Procedure Name   : output_result
   * Description      : �������ʌ����o��
   ***********************************************************************************/
--
  PROCEDURE output_result(
     in_csv_counter                     IN         NUMBER                              -- �����Ώی���
    ,in_success_counter                 IN         NUMBER                              -- ���팏��
-- *********** 2019/07/30 1.01 S.Kuwako DEL START *********** --
--    ,in_warn_counter                    IN         NUMBER                              -- �x������
-- *********** 2019/07/30 1.01 S.Kuwako DEL END   *********** --
    ,in_error_counter                   IN         NUMBER                              -- �G���[����
  )
  IS
    lv_message_code                  VARCHAR2(100);
  BEGIN
    -- �Ώی���
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name_xxccp,
                                            iv_name          => cv_target_rec_msg,
                                            iv_token_name1   => cv_tkn_count,
                                            iv_token_value1  => TO_CHAR(in_csv_counter)
                                            )
        );
    -- ���팏��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name_xxccp,
                                            iv_name          => cv_normal_rec_msg,
                                            iv_token_name1   => cv_tkn_count,
                                            iv_token_value1  => TO_CHAR(in_success_counter)
                                            )
        );
-- *********** 2019/07/30 1.01 S.Kuwako DEL START *********** --
--    -- �x������
--    FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT,
--          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name_xxccp,
--                                            iv_name          => cv_warn_rec_msg,
--                                            iv_token_name1   => cv_tkn_count,
--                                            iv_token_value1  => TO_CHAR(in_warn_counter)
--                                            )
--        );
-- *********** 2019/07/30 1.01 S.Kuwako DEL END   *********** --
    -- �G���[����
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name_xxccp,
                                            iv_name          => cv_error_rec_msg,
                                            iv_token_name1   => cv_tkn_count,
                                            iv_token_value1  => TO_CHAR(in_error_counter)
                                            )
        );
    -- ���ʃ��b�Z�[�W
    IF in_error_counter != 0 THEN
      lv_message_code := cv_error_msg;
-- *********** 2019/07/30 1.01 S.Kuwako DEL START *********** --
--    ELSIF in_warn_counter != 0 THEN
--      lv_message_code := cv_warn_msg;
-- *********** 2019/07/30 1.01 S.Kuwako DEL END   *********** --
    ELSE
      lv_message_code := cv_normal_msg;
    END IF;
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name_xxccp,
                                             iv_name         => lv_message_code
                                            )
        );
  END output_result;

--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �f�[�^�Ó����`�F�b�N
   ***********************************************************************************/
--
  PROCEDURE chk_data(
     id_process_date               IN         DATE                                -- �Ɩ����t
    ,in_org_id                     IN         NUMBER                              -- �c�ƒP��ID
    ,io_split_csv_tbl              IN  OUT    xxcok_common_pkg.g_split_csv_tbl    -- CSV���̓t�@�C���^
    ,ov_errbuf                     OUT NOCOPY VARCHAR2                            -- �G���[�E���b�Z�[�W
    ,ov_retcode                    OUT NOCOPY VARCHAR2                            -- ���^�[���E�R�[�h
    ,ov_errmsg                     OUT NOCOPY VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,o_po_vendors_rtype            OUT        po_vendors%ROWTYPE                  -- �d����}�X�^���R�[�h�^
    ,o_po_vendor_sites_all_rtype   OUT        po_vendor_sites_all%ROWTYPE         -- �d����T�C�g�}�X�^���R�[�h�^
    ,o_contract_managements_rtype  OUT        xxcso_contract_managements%ROWTYPE  -- �_��Ǘ����R�[�h�^
    ,o_destinations                OUT        xxcso_destinations%ROWTYPE          -- ���t�惌�R�[�h�^
    ,o_cust_accounts               OUT        xxcmm_cust_accounts%ROWTYPE         -- �ڋq�ǉ���񃌃R�[�h�^
  )
  IS
    lv_token_code VARCHAR2(100);                        -- �l�̑Ó����`�F�b�N�p�ꎞ�ϐ��iNO_DATA_FOUND�ŉ�����邽�߁j
    ln_counter    NUMBER;
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data'; -- �v���O������
  BEGIN
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    -- �����敪�̃`�F�b�N
    IF io_split_csv_tbl(cn_exec_cls) != cv_exec_cls_chk AND io_split_csv_tbl(cn_exec_cls) != cv_exec_cls_update THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_param_err_msg,
                                            iv_token_name1  => cv_tkn_item,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,cv_exec_cls)
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
    -- �ڋq�R�[�h�K�{�`�F�b�N
    IF io_split_csv_tbl(cn_customer_code) IS NULL THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_param_required_err_msg,
                                            iv_token_name1  => cv_tkn_item,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,cv_costomer_code)
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
    -- �ڋq�R�[�h�ɂ��_��Ǘ��e�[�u���̃`�F�b�N�B���͂��ꂽ�ڋq�Ƃ̌_�񂪑��݂��邩�i�m��ς݁A�}�X�^�[�A�g�ς݁j
    lv_token_code := cv_costomer_code;
    SELECT xcm.contract_number               contract_number
          ,xcm.close_day_code                close_day_code
          ,xcm.transfer_month_code           transfer_month_code
          ,xcm.transfer_day_code             transfer_day_code
          ,xcm.sp_decision_header_id         sp_decision_header_id
          ,xcm.contract_management_id        contract_management_id
          ,xcm.last_updated_by               last_updated_by
          ,xcm.last_update_date              last_update_date
          ,xcm.last_update_login             last_update_login
          ,xcm.request_id                    request_id
          ,xcm.program_application_id        program_application_id
          ,xcm.program_id                    program_id
          ,xcm.program_update_date           program_update_date
          ,xca.contractor_supplier_code      contractor_supplier_code
          ,xca.bm_pay_supplier_code1         bm_pay_supplier_code1
          ,xca.bm_pay_supplier_code2         bm_pay_supplier_code2
          ,xca.last_updated_by               xca_last_updated_by
          ,xca.last_update_date              xca_last_update_date
          ,xca.last_update_login             xca_last_update_login
          ,xca.request_id                    xca_request_id
          ,xca.program_application_id        xca_program_application_id
          ,xca.program_id                    xca_program_id
          ,xca.program_update_date           xca_program_update_date
          ,xca.customer_id                   xca_customer_id
    INTO   o_contract_managements_rtype.contract_number
          ,o_contract_managements_rtype.close_day_code
          ,o_contract_managements_rtype.transfer_month_code
          ,o_contract_managements_rtype.transfer_day_code
          ,o_contract_managements_rtype.sp_decision_header_id
          ,o_contract_managements_rtype.contract_management_id
          ,o_contract_managements_rtype.last_updated_by
          ,o_contract_managements_rtype.last_update_date
          ,o_contract_managements_rtype.last_update_login
          ,o_contract_managements_rtype.request_id
          ,o_contract_managements_rtype.program_application_id
          ,o_contract_managements_rtype.program_id
          ,o_contract_managements_rtype.program_update_date
          ,o_cust_accounts.contractor_supplier_code
          ,o_cust_accounts.bm_pay_supplier_code1
          ,o_cust_accounts.bm_pay_supplier_code2
          ,o_cust_accounts.last_updated_by
          ,o_cust_accounts.last_update_date
          ,o_cust_accounts.last_update_login
          ,o_cust_accounts.request_id
          ,o_cust_accounts.program_application_id
          ,o_cust_accounts.program_id
          ,o_cust_accounts.program_update_date
          ,o_cust_accounts.customer_id
    FROM   xxcso_contract_managements xcm
          ,xxcmm_cust_accounts        xca
    WHERE  xcm.install_account_number = xca.customer_code
    AND    xcm.status                 = cv_done
    AND    xcm.cooperate_flag         = cv_done
    AND    xcm.batch_proc_status      = cv_batch_status_normal
    AND    xcm.contract_management_id = (SELECT MAX(contract_management_id)
                                         FROM   xxcso_contract_managements xcm_in
                                         WHERE  xcm_in.install_account_number = io_split_csv_tbl(cn_customer_code)
                                         AND    xcm_in.status                 = cv_done
                                         AND    xcm_in.cooperate_flag         = cv_done
                                         AND    xcm_in.batch_proc_status      = cv_batch_status_normal
                                        )
    AND    xcm.install_account_number = io_split_csv_tbl(cn_customer_code);

    -- ���d����R�[�h�A�V�d����R�[�h�������Ƃ����͂���Ă��Ȃ��A�������͗����ɓ��͂�����`�F�b�N
    IF NOT ((io_split_csv_tbl(cn_cur_sup_code) IS NULL AND io_split_csv_tbl(cn_new_sup_code) IS NULL) OR
       (io_split_csv_tbl(cn_cur_sup_code) IS NOT NULL AND io_split_csv_tbl(cn_new_sup_code) IS NOT NULL)) THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_comb_chk_msg,
                                            iv_token_name1  => cv_tkn_entry1,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,cv_cur_sup_code),
                                            iv_token_name2  => cv_tkn_entry2,
                                            iv_token_value2 => xxccp_common_pkg.get_msg(cv_app_name,cv_new_sup_code)
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
    IF io_split_csv_tbl(cn_cur_sup_code) IS NOT NULL THEN
      -- ���d����R�[�h�ɂ�鑗�t��e�[�u���̃`�F�b�N�B���͂��ꂽ�ڋq�Ƃ̌_��ɕR�Â����t��ɑ��݂��邩
      lv_token_code := cv_cur_sup_code;
      SELECT xd.delivery_id                  delivery_id
            ,xd.supplier_id                  supplier_id
            ,xd.payment_name                 payment_name
            ,xd.payment_name_alt             payment_name_alt
            ,xd.bank_transfer_fee_charge_div bank_transfer_fee_charge_div
            ,xd.belling_details_div          belling_details_div
            ,xd.inquery_charge_hub_cd        inquery_charge_hub_cd
            ,xd.post_code                    post_code
            ,xd.prefectures                  prefectures
            ,xd.city_ward                    city_ward
            ,xd.address_1                    address_1
            ,xd.address_2                    address_2
            ,xd.address_lines_phonetic       address_lines_phonetic
            ,xd.vendor_number                vendor_number
            ,xd.last_updated_by              last_updated_by
            ,xd.last_update_date             last_update_date
            ,xd.last_update_login            last_update_login
            ,xd.request_id                   request_id
            ,xd.program_application_id       program_application_id
            ,xd.program_id                   program_id
            ,xd.program_update_date          program_update_date
      INTO   o_destinations.delivery_id
            ,o_destinations.supplier_id
            ,o_destinations.payment_name
            ,o_destinations.payment_name_alt
            ,o_destinations.bank_transfer_fee_charge_div
            ,o_destinations.belling_details_div
            ,o_destinations.inquery_charge_hub_cd
            ,o_destinations.post_code
            ,o_destinations.prefectures
            ,o_destinations.city_ward
            ,o_destinations.address_1
            ,o_destinations.address_2
            ,o_destinations.address_lines_phonetic
            ,o_destinations.vendor_number
            ,o_destinations.last_updated_by
            ,o_destinations.last_update_date
            ,o_destinations.last_update_login
            ,o_destinations.request_id
            ,o_destinations.program_application_id
            ,o_destinations.program_id
            ,o_destinations.program_update_date
      FROM   xxcso_destinations xd
      WHERE  xd.vendor_number          = io_split_csv_tbl(cn_cur_sup_code)
      AND    xd.contract_management_id = o_contract_managements_rtype.contract_management_id;
    END IF;

    IF io_split_csv_tbl(cn_new_sup_code) IS NOT NULL THEN
      -- �V�d����R�[�h�ɂ��d����}�X�^�̃`�F�b�N
      lv_token_code := cv_new_sup_code;
      SELECT pv.vendor_id           vendor_id
            ,pv.vendor_name         vendor_name
            ,pv.vendor_name_alt     vendor_name_alt
            ,pvs.bank_charge_bearer bank_charge_bearer
            ,pvs.attribute4         attribute4
            ,pvs.attribute5         attribute5
            ,pvs.zip                zip
            ,pvs.state              state
            ,pvs.city               city
            ,pvs.address_line1      address_line1
            ,pvs.address_line2      address_line2
            ,pvs.phone              phone
      INTO   o_po_vendors_rtype.vendor_id
            ,o_po_vendors_rtype.vendor_name
            ,o_po_vendors_rtype.vendor_name_alt
            ,o_po_vendor_sites_all_rtype.bank_charge_bearer
            ,o_po_vendor_sites_all_rtype.attribute4
            ,o_po_vendor_sites_all_rtype.attribute5
            ,o_po_vendor_sites_all_rtype.zip
            ,o_po_vendor_sites_all_rtype.state
            ,o_po_vendor_sites_all_rtype.city
            ,o_po_vendor_sites_all_rtype.address_line1
            ,o_po_vendor_sites_all_rtype.address_line2
            ,o_po_vendor_sites_all_rtype.phone
      FROM   po_vendors pv
            ,po_vendor_sites_all pvs
      WHERE  pv.segment1 = io_split_csv_tbl(cn_new_sup_code)
      AND    pv.enabled_flag = 'Y'
      AND    pv.vendor_id = pvs.vendor_id
      AND    NVL(pvs.inactive_date, id_process_date + 1) > id_process_date
      AND    pvs.org_id   = in_org_id;
    END IF;

    -- �V���ߓ��A�V�U�����A�V�U�����̑S�Ă����͂���Ă��Ȃ��A�������͑S�Ăɓ��͂�����`�F�b�N
    IF NOT (
             (
                    io_split_csv_tbl(cn_new_close_day_code)   IS NULL
                AND io_split_csv_tbl(cn_new_trans_month_code) IS NULL
                AND io_split_csv_tbl(cn_new_trans_day_code)   IS NULL
             )
             OR
             (
                    io_split_csv_tbl(cn_new_close_day_code)   IS NOT NULL
                AND io_split_csv_tbl(cn_new_trans_month_code) IS NOT NULL
                AND io_split_csv_tbl(cn_new_trans_day_code)   IS NOT NULL
             )
           ) THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_comb_3_chk_msg,
                                            iv_token_name1  => cv_tkn_entry1,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,cv_new_close_day),
                                            iv_token_name2  => cv_tkn_entry2,
                                            iv_token_value2 => xxccp_common_pkg.get_msg(cv_app_name,cv_new_trans_month),
                                            iv_token_name3  => cv_tkn_entry3,
                                            iv_token_value3 => xxccp_common_pkg.get_msg(cv_app_name,cv_new_trans_day)
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;

    IF io_split_csv_tbl(cn_new_close_day_code) IS NOT NULL THEN
      -- �V���ߓ��̃}�X�^�`�F�b�N
      lv_token_code := cv_new_close_day;
      SELECT flvv.lookup_code
      INTO   io_split_csv_tbl(cn_conv_new_close_day_code)
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_type_days_type
      AND    flvv.description = io_split_csv_tbl(cn_new_close_day_code)
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    flvv.start_date_active <= id_process_date
      AND    NVL(flvv.end_date_active,id_process_date) >= id_process_date;
    END IF;

    IF io_split_csv_tbl(cn_new_trans_month_code) IS NOT NULL THEN
      -- �V�U�����̃}�X�^�`�F�b�N
      lv_token_code := cv_new_trans_month;
      SELECT flvv.lookup_code
      INTO   io_split_csv_tbl(cn_conv_new_trans_month_code)
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_type_months_type
      AND    flvv.description = io_split_csv_tbl(cn_new_trans_month_code)
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    flvv.start_date_active <= id_process_date
      AND    NVL(flvv.end_date_active,id_process_date) >= id_process_date;
    END IF;

    IF io_split_csv_tbl(cn_new_trans_day_code) IS NOT NULL THEN
      -- �V�U�����̃}�X�^�`�F�b�N
      lv_token_code := cv_new_trans_day;
      SELECT flvv.lookup_code
      INTO   io_split_csv_tbl(cn_conv_new_trans_day_code)
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type = cv_type_days_type
      AND    flvv.description = io_split_csv_tbl(cn_new_trans_day_code)
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    flvv.start_date_active <= id_process_date
      AND    NVL(flvv.end_date_active,id_process_date) >= id_process_date;
    END IF;

    -- �V���ߓ��A�V�U�����A�V�U�����Ɍ����A�����A20�ȊO�����͂��ꂽ�ꍇ�̃`�F�b�N�B���t��A�������͐V�d����R�[�h��BM�x���敪��1,2�ł͂Ȃ����Ƃ̃`�F�b�N
    IF io_split_csv_tbl(cn_new_close_day_code) IS NOT NULL AND io_split_csv_tbl(cn_new_trans_month_code) IS NOT NULL
        AND io_split_csv_tbl(cn_new_trans_day_code) IS NOT NULL THEN
      IF io_split_csv_tbl(cn_conv_new_close_day_code) != cv_day_type_month_end OR io_split_csv_tbl(cn_conv_new_trans_month_code) != cv_month_type_next_month
          OR io_split_csv_tbl(cn_conv_new_trans_day_code) != cv_day_type_20 THEN
        IF io_split_csv_tbl(cn_new_sup_code) IS NULL THEN
          -- �V�d����R�[�h�ɓ��͂��Ȃ��ꍇ�͑��t��e�[�u���̃`�F�b�N
          SELECT COUNT(*)
          INTO   ln_counter
          FROM   xxcso_destinations xd
          WHERE  xd.contract_management_id =  o_contract_managements_rtype.contract_management_id
          AND    xd.belling_details_div    IN (cv_bm_pay_acc_w_guide, cv_bm_pay_acc_no_guide);
        ELSE
          -- �V�d����R�[�h�ɓ��͂�����ꍇ�͌��d����R�[�h���������`�F�b�N
          SELECT COUNT(*)
          INTO   ln_counter
          FROM   xxcso_destinations xd
          WHERE  xd.contract_management_id =  o_contract_managements_rtype.contract_management_id
          AND    xd.vendor_number          != io_split_csv_tbl(cn_cur_sup_code)
          AND    xd.belling_details_div    IN (cv_bm_pay_acc_w_guide, cv_bm_pay_acc_no_guide);
          -- �V�d����R�[�h��BM�x���敪�̃`�F�b�N
          IF o_po_vendor_sites_all_rtype.attribute4 IN (cv_bm_pay_acc_w_guide, cv_bm_pay_acc_no_guide) THEN
            ln_counter := ln_counter + 1;
          END IF;
        END IF;

        IF ln_counter != 0 THEN
          io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                iv_name         => cv_pay_line_chk_msg
                                                );
          ov_errmsg  := io_split_csv_tbl(cn_error_msg);
          ov_retcode := cv_status_warn;
          RETURN;
        END IF;
      END IF;
    END IF;

    -- �V���ߓ��A�V�U�����A�V�U�����ɒl�����͂��ꂽ�ꍇ�̃`�F�b�N�B���͂��ꂽ�ڋq�Ƃ̌_��ɒ��ߓ��A�U�����A�U�������ݒ肳��Ă邱�Ƃ̃`�F�b�N
    IF io_split_csv_tbl(cn_new_close_day_code) IS NOT NULL AND io_split_csv_tbl(cn_new_trans_month_code) IS NOT NULL
        AND io_split_csv_tbl(cn_new_trans_day_code) IS NOT NULL THEN
      IF o_contract_managements_rtype.close_day_code IS NULL OR o_contract_managements_rtype.transfer_month_code IS NULL
          OR o_contract_managements_rtype.transfer_day_code IS NULL THEN
        io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                              iv_name         => cv_sall_bm_chk_msg
                                              );
        ov_errmsg  := io_split_csv_tbl(cn_error_msg);
        ov_retcode := cv_status_warn;
        RETURN;
      END IF;
    END IF;

    -- �V�d����R�[�h�ɒl���ݒ肳��Ă���A�V���ߓ��A�V�U�����A�V�U�����ɒl���ݒ肳��Ă��Ȃ��ꍇ�̃`�F�b�N�B
    -- �V�d�����BM�x���敪��1��2�̏ꍇ�A���͂��ꂽ�ڋq�Ƃ̌_��̒��ߓ��������A�U�����������A�U�����������ł��邱�Ƃ̃`�F�b�N
    IF io_split_csv_tbl(cn_new_sup_code) IS NOT NULL AND io_split_csv_tbl(cn_new_close_day_code) IS NULL
         AND io_split_csv_tbl(cn_new_trans_month_code) IS NULL AND io_split_csv_tbl(cn_new_trans_day_code) IS NULL THEN
      IF o_po_vendor_sites_all_rtype.attribute4 IN (cv_bm_pay_acc_w_guide, cv_bm_pay_acc_no_guide) THEN
        IF o_contract_managements_rtype.close_day_code != cv_day_type_month_end OR o_contract_managements_rtype.transfer_month_code != cv_month_type_next_month
            OR o_contract_managements_rtype.transfer_day_code != cv_day_type_20 THEN
          io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                iv_name         => cv_new_sup_bm_inte_msg
                                                );
          ov_errmsg  := io_split_csv_tbl(cn_error_msg);
          ov_retcode := cv_status_warn;
          RETURN;
        END IF;
      END IF;
    END IF;
    
    -- �V�d����R�[�h�ɒl���ݒ肳��Ă���ꍇ�̃`�F�b�N�B���t��̏d���`�F�b�N
    IF io_split_csv_tbl(cn_new_sup_code) IS NOT NULL THEN
      SELECT COUNT(*)
      INTO   ln_counter
      FROM   xxcso_destinations xd
      WHERE  xd.vendor_number          = io_split_csv_tbl(cn_new_sup_code)
      AND    xd.contract_management_id = o_contract_managements_rtype.contract_management_id;
      
      IF ln_counter != 0 THEN
          io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                iv_name         => cv_dup_dest_err_msg
                                                );
          ov_errmsg  := io_split_csv_tbl(cn_error_msg);
          ov_retcode := cv_status_warn;
      END IF;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_param_err_msg,
                                            iv_token_name1  => cv_tkn_item,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,lv_token_code)
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : update_data
   * Description      : �_����̍X�V
   ***********************************************************************************/
--
  PROCEDURE update_data(
     id_sysdate                    IN         DATE                                -- �V�X�e�����t
    ,io_split_csv_tbl              IN OUT     xxcok_common_pkg.g_split_csv_tbl    -- CSV���̓t�@�C���^
    ,ov_errbuf                     OUT NOCOPY VARCHAR2                            -- �G���[�E���b�Z�[�W
    ,ov_retcode                    OUT NOCOPY VARCHAR2                            -- ���^�[���E�R�[�h
    ,ov_errmsg                     OUT NOCOPY VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,i_po_vendors_rtype            IN         po_vendors%ROWTYPE                  -- �d����}�X�^���R�[�h�^
    ,i_po_vendor_sites_all_rtype   IN         po_vendor_sites_all%ROWTYPE         -- �d����T�C�g�}�X�^���R�[�h�^
    ,i_contract_managements_rtype  IN         xxcso_contract_managements%ROWTYPE  -- �_��Ǘ����R�[�h�^
    ,i_destinations                IN         xxcso_destinations%ROWTYPE          -- ���t�惌�R�[�h�^
    ,i_cust_accounts               IN         xxcmm_cust_accounts%ROWTYPE         -- �ڋq�ǉ���񃌃R�[�h�^
  )
  IS
    lv_token_code VARCHAR2(100);                           -- ���b�N�`�F�b�N�p�ꎞ�ϐ��i���b�N�擾�G���[�ŉ�����邽�߁j
    ln_temp_num   NUMBER;
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_data'; -- �v���O������
  BEGIN
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;

    -- ���d����R�[�h�A�V�d����R�[�h���ݒ肳��Ă���ꍇ�A���t��e�[�u���A�ڋq�ǉ������X�V
    IF io_split_csv_tbl(cn_cur_sup_code) IS NOT NULL AND io_split_csv_tbl(cn_new_sup_code) IS NOT NULL THEN
      lv_token_code := cv_dest_table;
      SELECT xd.delivery_id delivery_id
      INTO   ln_temp_num
      FROM   xxcso_destinations xd
      WHERE  xd.delivery_id = i_destinations.delivery_id
      FOR UPDATE NOWAIT;

      UPDATE xxcso_destinations xd
      SET    xd.supplier_id                    = i_po_vendors_rtype.vendor_id
            ,xd.payment_name                   = i_po_vendors_rtype.vendor_name
            ,xd.payment_name_alt               = i_po_vendors_rtype.vendor_name_alt
            ,xd.bank_transfer_fee_charge_div   = i_po_vendor_sites_all_rtype.bank_charge_bearer
            ,xd.belling_details_div            = i_po_vendor_sites_all_rtype.attribute4
            ,xd.inquery_charge_hub_cd          = i_po_vendor_sites_all_rtype.attribute5
            ,xd.post_code                      = i_po_vendor_sites_all_rtype.zip
            ,xd.prefectures                    = i_po_vendor_sites_all_rtype.state
            ,xd.city_ward                      = i_po_vendor_sites_all_rtype.city
            ,xd.address_1                      = i_po_vendor_sites_all_rtype.address_line1
            ,xd.address_2                      = i_po_vendor_sites_all_rtype.address_line2
            ,xd.address_lines_phonetic         = i_po_vendor_sites_all_rtype.phone
            ,xd.vendor_number                  = io_split_csv_tbl(cn_new_sup_code)
            ,xd.last_updated_by                = fnd_global.user_id
            ,xd.last_update_date               = id_sysdate
            ,xd.last_update_login              = fnd_global.login_id
            ,xd.request_id                     = fnd_global.conc_request_id
            ,xd.program_application_id         = fnd_global.prog_appl_id
            ,xd.program_id                     = fnd_global.conc_program_id
            ,xd.program_update_date            = id_sysdate
      WHERE  xd.delivery_id = i_destinations.delivery_id;

      lv_token_code := cv_cust_account;
      SELECT xca.customer_id customer_id
      INTO   ln_temp_num
      FROM   xxcmm_cust_accounts xca
      WHERE  xca.customer_id = i_cust_accounts.customer_id
      FOR UPDATE NOWAIT;

      UPDATE xxcmm_cust_accounts xca
      SET    xca.contractor_supplier_code       = DECODE(io_split_csv_tbl(cn_cur_sup_code), contractor_supplier_code,
                                                    io_split_csv_tbl(cn_new_sup_code), contractor_supplier_code)
            ,xca.bm_pay_supplier_code1          = DECODE(io_split_csv_tbl(cn_cur_sup_code), bm_pay_supplier_code1,
                                                    io_split_csv_tbl(cn_new_sup_code), bm_pay_supplier_code1)
            ,xca.bm_pay_supplier_code2          = DECODE(io_split_csv_tbl(cn_cur_sup_code), bm_pay_supplier_code2,
                                                    io_split_csv_tbl(cn_new_sup_code), bm_pay_supplier_code2)
            ,xca.last_updated_by                = fnd_global.user_id
            ,xca.last_update_date               = id_sysdate
            ,xca.last_update_login              = fnd_global.login_id
            ,xca.request_id                     = fnd_global.conc_request_id
            ,xca.program_application_id         = fnd_global.prog_appl_id
            ,xca.program_id                     = fnd_global.conc_program_id
            ,xca.program_update_date            = id_sysdate
      WHERE  xca.customer_id = i_cust_accounts.customer_id;

    END IF;

    -- �V���ߓ��A�V�U�����A�V�U�������ݒ肳��Ă���ꍇ�A�_��Ǘ��e�[�u�����X�V
    IF io_split_csv_tbl(cn_new_close_day_code) IS NOT NULL AND io_split_csv_tbl(cn_new_trans_month_code) IS NOT NULL AND
       io_split_csv_tbl(cn_new_trans_day_code) IS NOT NULL THEN
      lv_token_code := cv_contract_mng;
      SELECT xcm.contract_management_id contract_management_id
      INTO   ln_temp_num
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_management_id = i_contract_managements_rtype.contract_management_id
      FOR UPDATE NOWAIT;

      UPDATE xxcso_contract_managements xcm
      SET    xcm.transfer_month_code            = io_split_csv_tbl(cn_conv_new_trans_month_code)
            ,xcm.transfer_day_code              = io_split_csv_tbl(cn_conv_new_trans_day_code)
            ,xcm.close_day_code                 = io_split_csv_tbl(cn_conv_new_close_day_code)
            ,xcm.last_updated_by                = fnd_global.user_id
            ,xcm.last_update_date               = id_sysdate
            ,xcm.last_update_login              = fnd_global.login_id
            ,xcm.request_id                     = fnd_global.conc_request_id
            ,xcm.program_application_id         = fnd_global.prog_appl_id
            ,xcm.program_id                     = fnd_global.conc_program_id
            ,xcm.program_update_date            = id_sysdate
      WHERE  xcm.contract_management_id = i_contract_managements_rtype.contract_management_id;

    END IF;
  EXCEPTION
    WHEN global_lock_expt THEN
      io_split_csv_tbl(cn_error_msg) := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_lock_err_msg,
                                            iv_token_name1  => cv_tkn_table,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,lv_token_code),
                                            iv_token_name2  => cv_tkn_errmsg,
                                            iv_token_value2 => SQLERRM
                                            );
      ov_errmsg  := io_split_csv_tbl(cn_error_msg);
      ov_retcode := cv_status_warn;
    WHEN OTHERS THEN
      ov_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name         => cv_update_err_msg,
                                            iv_token_name1  => cv_tkn_action,
                                            iv_token_value1 => xxccp_common_pkg.get_msg(cv_app_name,lv_token_code),
                                            iv_token_name2  => cv_tkn_error_message,
                                            iv_token_value2 => SQLERRM
                                            );
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
      FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => ov_errmsg
          );
      ROLLBACK;
  END update_data;
--
  /**********************************************************************************
   * Procedure Name   : output_file
   * Description      : �ύX�O�X�V��m�F�p�f�[�^�̏o��
   ***********************************************************************************/
--
  PROCEDURE output_file(
     ov_errbuf                     OUT NOCOPY VARCHAR2                            -- �G���[�E���b�Z�[�W
    ,ov_retcode                    OUT NOCOPY VARCHAR2                            -- ���^�[���E�R�[�h
    ,ov_errmsg                     OUT NOCOPY VARCHAR2                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,id_sysdate                    IN         DATE                                -- �V�X�e�����t
    ,id_process_date               IN         DATE                                -- �Ɩ����t
    ,in_row_number                 IN         NUMBER                              -- �s�ԍ�
    ,i_split_csv_tbl               IN         xxcok_common_pkg.g_split_csv_tbl    -- CSV���̓t�@�C���^
    ,i_po_vendors_rtype            IN         po_vendors%ROWTYPE                  -- �d����}�X�^���R�[�h�^
    ,i_po_vendor_sites_all_rtype   IN         po_vendor_sites_all%ROWTYPE         -- �d����T�C�g�}�X�^���R�[�h�^
    ,i_contract_managements_rtype  IN         xxcso_contract_managements%ROWTYPE  -- �_��Ǘ����R�[�h�^
    ,i_destinations                IN         xxcso_destinations%ROWTYPE          -- ���t�惌�R�[�h�^
    ,i_cust_accounts               IN         xxcmm_cust_accounts%ROWTYPE         -- �ڋq�ǉ���񃌃R�[�h�^
  )
  IS
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_file'; -- �v���O������
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
    lv_table_name          VARCHAR2(100);                  -- �e�[�u�����o�͗p�ϐ�
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
  BEGIN
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    -- �A�b�v���[�h�G���[���X�g�̏o��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
--                                             iv_name         => cv_head_upld_err_list_msg
--                                            )
          buff   => cv_double_quotation || TO_CHAR(in_row_number) || cv_double_quotation || cv_separator ||
                    xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                             iv_name         => cv_head_upld_err_list_msg
                                            )
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
        );
--
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
    --�e�[�u�����̎擾�i�A�b�v���[�h�G���[���X�g�j
    lv_table_name := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                              iv_name         => cv_upld_err_list
                                             );
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
--
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => cv_double_quotation || TO_CHAR(in_row_number)                   || cv_double_quotation || cv_separator ||
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
                    cv_double_quotation || lv_table_name                            || cv_double_quotation || cv_separator ||
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
                    cv_double_quotation || i_split_csv_tbl(cn_exec_cls            ) || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_customer_code       ) || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_cur_sup_code        ) || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_new_sup_code        ) || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_new_close_day_code)   || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_new_trans_month_code) || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_new_trans_day_code)   || cv_double_quotation || cv_separator ||
                    cv_double_quotation || i_split_csv_tbl(cn_error_msg           ) || cv_double_quotation
        );
    -- �G���[�ɂȂ��Ă��Ȃ��ꍇ�͕ύX�O�X�V��f�[�^���X�g���o�͂���
    IF i_split_csv_tbl(cn_error_msg) IS NULL THEN
      IF i_split_csv_tbl(cn_new_close_day_code) IS NOT NULL AND i_split_csv_tbl(cn_new_trans_month_code)
         IS NOT NULL AND i_split_csv_tbl(cn_new_trans_day_code) IS NOT NULL THEN
        -- �_��Ǘ��e�[�u���̕ύX�O�X�V��m�F�p�f�[�^���X�g���o��
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
--                                                 iv_name         => cv_head_chk_cont_mng_msg
--                                                )
              buff   => cv_double_quotation || TO_CHAR(in_row_number) || cv_double_quotation || cv_separator ||
                        xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                 iv_name         => cv_head_chk_cont_mng_msg
                                                )
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
            );
--
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
        --�e�[�u�����̎擾�i�_��Ǘ��e�[�u���j
        lv_table_name := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                  iv_name         => cv_contract_mng
                                                 );
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
--
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => cv_double_quotation || i_split_csv_tbl(cn_customer_code       )                                                  || cv_double_quotation || cv_separator ||
              buff   => cv_double_quotation || TO_CHAR(in_row_number)                                                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || lv_table_name                                                                             || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_customer_code       )                                                  || cv_double_quotation || cv_separator ||
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
                        cv_double_quotation || i_contract_managements_rtype.contract_number                                              || cv_double_quotation || cv_separator ||
                        cv_double_quotation || xxcso_util_common_pkg.get_lookup_description(
                                                 cv_type_days_type, i_contract_managements_rtype.close_day_code, id_process_date)        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_new_close_day_code)                                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || xxcso_util_common_pkg.get_lookup_description(
                                                 cv_type_months_type, i_contract_managements_rtype.transfer_month_code, id_process_date) || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_new_trans_month_code)                                                  || cv_double_quotation || cv_separator ||
                        cv_double_quotation || xxcso_util_common_pkg.get_lookup_description(
                                                 cv_type_days_type, i_contract_managements_rtype.transfer_day_code, id_process_date)     || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_new_trans_day_code)                                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_contract_managements_rtype.last_updated_by                                              || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.user_id                                                                        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_contract_managements_rtype.last_update_date, 'YYYY/MM/DD HH24:MI:SS')           || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                                              || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_contract_managements_rtype.last_update_login                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.login_id                                                                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_contract_managements_rtype.request_id                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_request_id                                                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_contract_managements_rtype.program_application_id                                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.prog_appl_id                                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_contract_managements_rtype.program_id                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_program_id                                                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_contract_managements_rtype.program_update_date, 'YYYY/MM/DD HH24:MI:SS')        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                                              || cv_double_quotation
            );
      END IF;
--
      IF i_split_csv_tbl(cn_cur_sup_code) IS NOT NULL AND i_split_csv_tbl(cn_new_sup_code) IS NOT NULL THEN
        -- ���t��e�[�u���̕ύX�O�X�V��m�F�p�f�[�^���X�g���o��
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
--                                                 iv_name         => cv_head_chk_dest_msg
--                                                )
               buff   => cv_double_quotation || TO_CHAR(in_row_number) || cv_double_quotation || cv_separator ||
                         xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                  iv_name         => cv_head_chk_dest_msg
                                                 )
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
            );
--
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
        --�e�[�u�����̎擾�i���t��e�[�u���j
        lv_table_name := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                  iv_name         => cv_dest_table
                                                 );
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
--
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => cv_double_quotation || i_split_csv_tbl(cn_customer_code            )                        || cv_double_quotation || cv_separator ||
              buff   => cv_double_quotation || TO_CHAR(in_row_number)                                               || cv_double_quotation || cv_separator ||
                        cv_double_quotation || lv_table_name                                                        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_customer_code            )                        || cv_double_quotation || cv_separator ||
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
                        cv_double_quotation || i_contract_managements_rtype.contract_number                         || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_cur_sup_code             )                        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_new_sup_code             )                        || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.supplier_id                                           || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendors_rtype.vendor_id                                         || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.payment_name                                          || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendors_rtype.vendor_name                                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.payment_name_alt                                      || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendors_rtype.vendor_name_alt                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.bank_transfer_fee_charge_div                          || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.bank_charge_bearer                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.belling_details_div                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.attribute4                               || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.inquery_charge_hub_cd                                 || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.attribute5                               || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.post_code                                             || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.zip                                      || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.prefectures                                           || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.state                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.city_ward                                             || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.city                                     || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.address_1                                             || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.address_line1                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.address_2                                             || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.address_line2                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.address_lines_phonetic                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_po_vendor_sites_all_rtype.phone                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.last_updated_by                                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.user_id                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_destinations.last_update_date, 'YYYY/MM/DD HH24:MI:SS')    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                         || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.last_update_login                                     || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.login_id                                                  || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.request_id                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_request_id                                           || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.program_application_id                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.prog_appl_id                                              || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_destinations.program_id                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_program_id                                           || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_destinations.program_update_date, 'YYYY/MM/DD HH24:MI:SS') || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                         || cv_double_quotation
            );
        -- �ڋq�ǉ����̕ύX�O�X�V��m�F�p�f�[�^���X�g���o��
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
--                                                 iv_name         => cv_head_chk_cust_inf_msg
--                                                )
              buff   => cv_double_quotation || TO_CHAR(in_row_number) || cv_double_quotation || cv_separator ||
                        xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                 iv_name         => cv_head_chk_cust_inf_msg
                                                )
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
            );
--
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
        --�e�[�u�����̎擾�i�ڋq�ǉ����j
        lv_table_name := xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                                  iv_name         => cv_cust_account
                                                 );
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
--
        FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT,
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--              buff   => cv_double_quotation || i_split_csv_tbl(cn_customer_code       )                                              || cv_double_quotation || cv_separator ||
              buff   => cv_double_quotation || TO_CHAR(in_row_number)                                                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || lv_table_name                                                                         || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_split_csv_tbl(cn_customer_code       )                                              || cv_double_quotation || cv_separator ||
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
                        cv_double_quotation || i_cust_accounts.contractor_supplier_code                                              || cv_double_quotation || cv_separator ||
                        cv_double_quotation || CASE i_cust_accounts.contractor_supplier_code
                                               WHEN i_split_csv_tbl(cn_cur_sup_code) THEN i_split_csv_tbl(cn_new_sup_code)
                                               ELSE i_cust_accounts.contractor_supplier_code
                                               END                                                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.bm_pay_supplier_code1                                                 || cv_double_quotation || cv_separator ||
                        cv_double_quotation || CASE i_cust_accounts.bm_pay_supplier_code1
                                               WHEN i_split_csv_tbl(cn_cur_sup_code) THEN i_split_csv_tbl(cn_new_sup_code)
                                               ELSE i_cust_accounts.bm_pay_supplier_code1
                                               END                                                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.bm_pay_supplier_code2                                                 || cv_double_quotation || cv_separator ||
                        cv_double_quotation || CASE i_cust_accounts.bm_pay_supplier_code2
                                               WHEN i_split_csv_tbl(cn_cur_sup_code) THEN i_split_csv_tbl(cn_new_sup_code)
                                               ELSE i_cust_accounts.bm_pay_supplier_code2
                                               END                                                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.last_updated_by                                                       || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.user_id                                                                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_cust_accounts.last_update_date, 'YYYY/MM/DD HH24:MI:SS')                    || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                                          || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.last_update_login                                                     || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.login_id                                                                   || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.request_id                                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_request_id                                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.program_application_id                                                || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.prog_appl_id                                                               || cv_double_quotation || cv_separator ||
                        cv_double_quotation || i_cust_accounts.program_id                                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || fnd_global.conc_program_id                                                            || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(i_cust_accounts.program_update_date, 'YYYY/MM/DD HH24:MI:SS')                 || cv_double_quotation || cv_separator ||
                        cv_double_quotation || TO_CHAR(id_sysdate, 'YYYY/MM/DD HH24:MI:SS')                                          || cv_double_quotation
            );
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
  END output_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W
    ,ov_retcode          OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_file_id          IN         NUMBER            -- �t�@�C��ID
    ,iv_fmt_ptn          IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  )
  IS
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';               -- �v���O������
    ld_sysdate                       DATE;                                       -- �V�X�e�����t
    ld_process_date                  DATE;                                       -- �c�Ɠ��t
    ln_org_id                        NUMBER;                                     -- �c�ƒP��ID
    ln_csv_counter                   NUMBER := 0;                                -- CSV��������
    ln_success_counter               NUMBER := 0;                                -- ���팏��
    ln_warn_counter                  NUMBER := 0;                                -- �x������
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
    ln_error_counter                 NUMBER := 0;                                -- �ُ팏��
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
    lv_file_name                     xxccp_mrp_file_ul_interface.file_name%TYPE; -- �t�@�C����
    lv_errbuf                        VARCHAR2(5000);                             -- �G���[�o�b�t�@
    lv_retcode                       VARCHAR2(1);                                -- ���^�[���R�[�h
    lv_errmsg                        VARCHAR2(5000);                             -- �G���[���b�Z�[�W
    l_file_data_tbl                  xxccp_common_pkg2.g_file_data_tbl;          -- BLOB�ϊ���f�[�^
    l_split_csv_tbl                  xxcok_common_pkg.g_split_csv_tbl;           -- CSV������f�[�^
    ln_csv_col_counter               NUMBER;                                     -- CSV���ڐ�
    l_po_vendors_rtype               po_vendors%ROWTYPE;                         -- �d����}�X�^���R�[�h�^
    l_po_vendor_sites_all_rtype      po_vendor_sites_all%ROWTYPE;                -- �d����T�C�g�}�X�^���R�[�h�^
    l_contract_managements_rtype     xxcso_contract_managements%ROWTYPE;         -- �_��Ǘ����R�[�h�^
    l_destinations                   xxcso_destinations%ROWTYPE;                 -- ���t�惌�R�[�h�^
    l_cust_accounts                  xxcmm_cust_accounts%ROWTYPE;                -- �ڋq�ǉ���񃌃R�[�h�^
  BEGIN
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;

    -- ��������
    ln_org_id       := TO_NUMBER(FND_PROFILE.VALUE(cv_pf_org_id));
    ld_process_date := xxccp_common_pkg2.get_process_date;

    -- �t�@�C��ID�̏o��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name          => cv_param_fileid_msg,
                                            iv_token_name1   => cv_tkn_file_id,
                                            iv_token_value1  => in_file_id
                                            )
        );
    -- �t�H�[�}�b�g�p�^�[���̏o��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name          => cv_param_formatptn_msg,
                                            iv_token_name1   => cv_tkn_format_pattern,
                                            iv_token_value1  => iv_fmt_ptn
                                            )
        );
    -- �t�H�[�}�b�g�p�^�[�����̏o��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name          => cv_param_formatname_msg,
                                            iv_token_name1   => cv_tkn_format_name,
                                            iv_token_value1  => xxcso_util_common_pkg.get_lookup_meaning(cv_type_file_upld_obj, iv_fmt_ptn, ld_process_date)
                                            )
        );
    -- �A�b�v���[�h�t�@�C�����̏o��
    SELECT xmf.file_name
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;

    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => xxccp_common_pkg.get_msg(iv_application  => cv_app_name,
                                            iv_name          => cv_param_filename_msg,
                                            iv_token_name1   => cv_tkn_file_name,
                                            iv_token_value1  => lv_file_name
                                            )
        );
    -- ��s�̑}��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => ''
        );

    -- �t�@�C��ID����A�b�v���[�h�t�@�C���擾
    xxccp_common_pkg2.blob_to_varchar2(in_file_id        => in_file_id           -- �t�@�C���h�c
                                      ,ov_file_data      => l_file_data_tbl      -- �ϊ���VARCHAR2�f�[�^
                                      ,ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W
                                      ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h
                                      ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
                                      );
    -- �w�b�_�[�s���������߁A1�����Z����
    ln_csv_counter := l_file_data_tbl.COUNT - 1;

    -- �w�b�_�[�s���������߁A2����J�n����
    << csv_loop >>
    FOR num IN 2..l_file_data_tbl.COUNT LOOP
      ld_sysdate := SYSDATE;
      lv_errbuf  := NULL;
      lv_retcode := cv_status_normal;
      lv_errmsg  := NULL;
      -- �擾����CSV�A�b�v���[�h�t�@�C�����J���}��؂�Ŏ擾
      xxcok_common_pkg.split_csv_data_p(ov_errbuf        => lv_errbuf            -- �G���[�o�b�t�@
                                       ,ov_retcode       => lv_retcode           -- ���^�[���R�[�h
                                       ,ov_errmsg        => lv_errmsg            -- �G���[���b�Z�[�W
                                       ,iv_csv_data      => l_file_data_tbl(num) -- CSV������
                                       ,on_csv_col_cnt   => ln_csv_col_counter   -- CSV���ڐ�
                                       ,ov_split_csv_tab => l_split_csv_tbl      -- CSV�����f�[�^
                                       );
      --�G���[���b�Z�[�W��t�^���邽�߂ɃJ���}��؂�Ŏ擾�����t�@�C���̖�����NULL��ݒ肷��
      l_split_csv_tbl(cn_error_msg) := NULL;
      -- �f�[�^�Ó����`�F�b�N
      chk_data(id_process_date               => ld_process_date
              ,in_org_id                     => ln_org_id
              ,io_split_csv_tbl              => l_split_csv_tbl
              ,ov_errbuf                     => lv_errbuf
              ,ov_retcode                    => lv_retcode
              ,ov_errmsg                     => lv_errmsg
              ,o_po_vendors_rtype            => l_po_vendors_rtype
              ,o_po_vendor_sites_all_rtype   => l_po_vendor_sites_all_rtype
              ,o_contract_managements_rtype  => l_contract_managements_rtype
              ,o_destinations                => l_destinations
              ,o_cust_accounts               => l_cust_accounts);
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_others_expt;
      END IF;
      -- �_����̍X�V
      IF l_split_csv_tbl(cn_exec_cls) = cv_exec_cls_update AND lv_retcode = cv_status_normal THEN
        update_data(id_sysdate                    => ld_sysdate
                   ,io_split_csv_tbl              => l_split_csv_tbl
                   ,ov_errbuf                     => lv_errbuf
                   ,ov_retcode                    => lv_retcode
                   ,ov_errmsg                     => lv_errmsg
                   ,i_po_vendors_rtype            => l_po_vendors_rtype
                   ,i_po_vendor_sites_all_rtype   => l_po_vendor_sites_all_rtype
                   ,i_contract_managements_rtype  => l_contract_managements_rtype
                   ,i_destinations                => l_destinations
                   ,i_cust_accounts               => l_cust_accounts);
        IF lv_retcode = cv_status_error THEN
          RAISE global_upd_expt;
        END IF;
      END IF;
--
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
      IF ( lv_retcode = cv_status_normal )
      -- ���d����R�[�h�܂��͐V�d����R�[�h�̂����ꂩ��NULL�܂��͗�����NULL�̏ꍇ
      AND ( ( l_split_csv_tbl(cn_cur_sup_code)   IS NULL )
           OR ( l_split_csv_tbl(cn_new_sup_code) IS NULL ) )
      -- ���A�V���ߓ��A�V�U�����܂��͐V�U�����̂����ꂩ��NULL�܂��͗������S��NULL�̏ꍇ
      AND ( ( l_split_csv_tbl(cn_new_close_day_code)     IS NULL )
           OR ( l_split_csv_tbl(cn_new_trans_month_code) IS NULL )
           OR ( l_split_csv_tbl(cn_new_trans_day_code)   IS NULL ) ) THEN
        -- �Y������ꍇ�͉������Ȃ��B
        NULL;
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--      IF lv_retcode = cv_status_normal THEN
      ELSIF ( lv_retcode = cv_status_normal ) THEN
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
        ln_success_counter := ln_success_counter + 1;
      ELSE
        ov_retcode := cv_status_warn;
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--        ln_warn_counter := ln_warn_counter + 1;
        --�x���̏ꍇ�ł��G���[�Ƃ��Č����J�E���g�i�㑱�����ŏI���X�e�[�^�X���ُ�I���֕ύX�j
        ln_error_counter := ln_error_counter + 1;
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
      END IF;

      -- �ύX�O�X�V��m�F�p�f�[�^�̏o��
      output_file(ov_errbuf                    => lv_errbuf
                 ,ov_retcode                   => lv_retcode
                 ,ov_errmsg                    => lv_errmsg
                 ,id_sysdate                   => ld_sysdate
                 ,id_process_date              => ld_process_date
                 ,i_split_csv_tbl              => l_split_csv_tbl
                 ,in_row_number                => (num - 1)
                 ,i_po_vendors_rtype           => l_po_vendors_rtype
                 ,i_po_vendor_sites_all_rtype  => l_po_vendor_sites_all_rtype
                 ,i_contract_managements_rtype => l_contract_managements_rtype
                 ,i_destinations               => l_destinations
                 ,i_cust_accounts              => l_cust_accounts);
      IF lv_retcode = cv_status_error THEN
        RAISE global_api_others_expt;
      END IF;
    END LOOP;
    
    IF ov_retcode = cv_status_warn THEN
      ROLLBACK;
-- *********** 2019/07/30 1.01 S.Kuwako ADD START *********** --
      --�I���X�e�[�^�X���ُ�I���֕ύX
      ov_retcode := cv_status_error;
-- *********** 2019/07/30 1.01 S.Kuwako ADD END   *********** --
    END IF;

    -- �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜
    DELETE FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE         xmfui.file_id = in_file_id;

    -- ��s�̑}��
    FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => ''
        );
    -- �I������
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--    output_result(ln_csv_counter, ln_success_counter, ln_warn_counter, 0);
    output_result(ln_csv_counter, ln_success_counter, ln_error_counter);
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
--
  EXCEPTION
    WHEN global_upd_expt THEN
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--      output_result(0, 0, 0, 1);
      output_result(0, 0, 1);
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      ov_errmsg := lv_errmsg;
      ov_retcode := cv_status_error;
      ROLLBACK;
    WHEN OTHERS THEN
-- *********** 2019/07/30 1.01 S.Kuwako MOD START *********** --
--      output_result(0, 0, 0, 1);
      output_result(0, 0, 1);
-- *********** 2019/07/30 1.01 S.Kuwako MOD END   *********** --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ROLLBACK;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W
    ,retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h
    ,in_file_id    IN         NUMBER            -- �t�@�C��ID
    ,iv_fmt_ptn    IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  )
  IS
--
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    lv_errbuf          VARCHAR2(5000);                               -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
    -- �R���J�����g�w�b�_���b�Z�[�W�o��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );

    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,in_file_id  => in_file_id         -- �t�@�C��ID
      ,iv_fmt_ptn  => iv_fmt_ptn         -- �t�H�[�}�b�g�p�^�[��
    );

    retcode := lv_retcode;
    errbuf  := lv_errbuf;
--
  END main;
--
END XXCSO010A07C;
/
