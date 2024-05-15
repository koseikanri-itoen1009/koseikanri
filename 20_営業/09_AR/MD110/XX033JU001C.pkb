CREATE OR REPLACE PACKAGE BODY XX033JU001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX033JU001C(body)
 * Description      : ��ʉ�v�V�X�e����̃f�[�^�ɁA���|�Ǘ��V�X�e���ŕێ�����DFF�̒l���X�V���܂��B
 * MD.050           : AR �d��t�����X�V���� OCSJ/BFAFIN/MD050/F302
 * MD.070           : AR �d��t�����X�V���� OCSJ/BFAFIN/MD070/F306
 * Version          : 11.5.10.2.4
 *
 * Program List
 * ---------------------------------- ----------------------------------------------
 *  Name                              Description
 * ---------------------------------- ----------------------------------------------
 *  get_id                            �֘A�f�[�^�擾(A-1)
 *  get_add_dff_data_1                DFF�t���Ώۃf�[�^���o����    (A2:Sales Invoices)
 *  get_trx_type_1                    �O����������肨��ђ��ߎ擾 (A2-1)
 *  get_add_dff_lines_data_1          ���������׉�v���擾1      (A2-2)
 *  get_ra_customer_trx_lines_all_1   ���������׉�v���擾2      (A2-3)
 *  get_ar_vat_tax_all_1              AR�ŏ��擾                 (A2-4)
 
 *  get_add_dff_data_2                DFF�t���Ώۃf�[�^���o����    (A3:Credit Memos)
 *  get_trx_number                    �����ϐ������ԍ��擾����     (A3-1)
 *  get_add_dff_lines_data_2          ���������׉�v���擾1      (A3-2)
 *  get_ra_customer_trx_lines_all_2   ���������׉�v���擾2      (A3-3)
 *  get_ar_vat_tax_all_2              AR�ŏ��擾 (A3-4)

 *  get_add_dff_data_3                DFF�t���Ώۃf�[�^���o����    (A4:CM Applications)
 
 *  get_add_dff_data_4                DFF�t���Ώۃf�[�^���o����    (A5:Adjistment)
 *  get_ra_customer_rx_all_1          �O����������肨��ђ��ߎ擾1(A5-1)
 *  get_ra_customer_rx_all_2          �O����������肨��ђ��ߎ擾2(A5-2)
 *  get_trx_type_2                    �O����������肨��ђ��ߎ擾 (A5-3)
 *  get_ar_vat_tax_all_3              AR�ŏ��擾                 (A5-4)

 *  get_add_dff_data_5                DFF�t���Ώۃf�[�^���o����    (A6:Trade Receipts)
 *  get_ra_hz_cust_account            �ڋq�w�b�_�[�e�[�u�����ݒ�l�擾���� (A6-1)
 *  get_hz_parties                    �ꌩ�ڋq�o�Ȃ��ꍇ�A�p�[�e�B�e�[�u�����擾���� (A6-2)
 *  get_ar_cash_receipt_his_all_1     ���������ԍ��擾����1        (A6-3)
 *  get_ar_cash_receipts_all          ���������ԍ��擾����2�߂�����(A6-4)

 *  get_add_dff_data_6                DFF�t���Ώۃf�[�^���o����    (A7:Cross Currency)

 *  upd_journal_data                  �d��f�[�^�̍X�V����         (A8)
 *  upd_journal_data_1                �d��f�[�^�̍X�V����(�ŋ敪�Ή�)(A8_1)
 *  msg_output                        �v���[�t���X�g�o�͏���       (A9)
 *  submain                           ���C�������v���V�[�W��
 *  main                              �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ----------- ------------ ------------- -------------------------------------------------
 *  Date        Ver.         Editor        Description
 * ----------- ------------ ------------- -------------------------------------------------
 *  2004/03/26  1.0          N.Iba         �V�K�쐬
 *  2004/05/06  1.1          N.Iba         �����Q�ƍX�V�s���A�������R���Z�b�g����Ă���
 *  2004/05/12  1.2          N.Iba         �ŋ敪�X�V�����C���Ή�
 *  2004/05/19  1.3          N.Iba         �������w�b�_�[�e�[�u�����擾�����ǉ�
 *                                          1.���|���^�����������@'TRADE_ACC'
 *                                          2.�S���ʁ@��v����ID�@�ǉ�
 *  2004/05/25  1.4          N.Iba         �������w�b�_�[�e�[�u�����擾�����ǉ�
 *                                          1.��s�萔���@'TRADE_BANK_CHARGES'
 *  2005/01/31  1.5          K.Hattori     �X�V���e�ύX
 *                                         �ŃR�[�h�A�������R�A�N�[����A�`�[���͎�
 *                                         �����Q�ƁA�\���P�A�\���Q
 *                                         �O����[�����������f�̕ύX
 *  2005/03/07  1.6          M.Marukawa    �N���W�b�g�E�����̎d��t�����̎擾����A�Q�Ɛ�
 *                                         ���(������)���R�[�h�̔z�����R�[�h�ɕύX
 *  2005/03/14  1.7          M.Marukawa    �ߓ�������(���׎d��^�C�v=TRADE_ACTIVITY)�̎d����
 *                                         �t�����W�b�N��ǉ�
 *  2005/06/17  11.5.10.1.3  Y.Matsumura   �������ɕR�Â��Ȃ��N���W�b�g�E�������f�[�^�Ƃ���
 *                                         OM�Ȃǂ�������Ă����ۂɐe���������������Ȃ��悤�ύX
 *  2005/07/14  11.5.10.1.4  S.Yamada      ����`�@�\�ւ̑Ή�
 *                                         �d��J�e�S����Trade Receipts��DFF�t���Ώۃf�[�^���o������
 *                                         �ȉ��̖��׎d��^�C�v��ǉ��B
 *                                         TRADE_CONFIRMATION�ATRADE_REMITTANCE�A
 *                                         TRADE_FACTOR�ATRADE_SHORT_TERM_DEBT
 *  2005/12/15  11.5.10.1.6  A.Okusa       �ŋ敪��NULL�̎���GL_INTERFACE�X�V���W�b�N�폜
 *                                         �ŋ敪��NULL�̎��ɑΏۊO�̐ŋ��R�[�h���擾���鏈�����폜
 *  2006/01/30  11.5.10.1.6B Y.Matsumura   get_trx_type_1����SELECT����ORG_ID�̏�����ǉ�
 *  2006/06/09  11.5.10.2.3  S.Morisawa    gl_add_dff_data_cur_3��SELECT���̒���ID�����̒ǉ�
 *  2024/01/10  11.5.10.2.4  K.Nakagawa    [E_�{�ғ�_19496]�Ή� ���Љ��Ή�
 *
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
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --���ʏo�͗p���t�`��1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --���ʏo�͗p���t�`��2
  cv_package_name     CONSTANT VARCHAR2(20) := 'XX033JU001';              --�p�b�P�[�W��
  cv_execite_tbl_name CONSTANT VARCHAR2(20) := 'GL_INTERFACE';            --�����Ώۃe�[�u����
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  get_org_id_expt       EXCEPTION;            -- �I���OID���擾�G���[
  get_books_id_expt     EXCEPTION;            -- ��v����ID���擾�G���[
  get_xx03_name_id_expt EXCEPTION;            -- XX03_TRX_CODES_V �ŋ敪���擾�G���[
  warning_status_expt   EXCEPTION;            -- ���[�U�[�G���[�n���h���p
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
-- 20050131 V1.5 START
  -- �C���^�C�v
  cv_adjustment_type_c         CONSTANT VARCHAR2(3)  := 'C';  -- �O����[��������
-- 20050131 V1.5 END
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : �v���[�t���X�g�o�͏��� (A9)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    ln_sales_invoices_cnt       IN NUMBER,      -- 2.����������(IN)(���㐿����)
    ln_trade_receipts_cnt       IN NUMBER,      -- 3.����������(IN)(���|�^����������)
    ln_adjustment_cnt           IN NUMBER,      -- 4.����������(IN)(�C��)
    ln_credit_memos_cnt         IN NUMBER,      -- 5.����������(IN)(�N���W�b�g����)
    ln_credit_memo_app_cnt      IN NUMBER,      -- 6.����������(IN)(�N���W�b�g��������)
    ln_cross_currency_cnt       IN NUMBER,      -- 7.����������(IN)(���ݒʉ�)
    iv_journal_source           IN VARCHAR2,    -- 8.�d��\�[�X��(IN)
    lv_sales_invoices           IN VARCHAR2,    -- 9.�d��J�e�S����(���㐿����)(IN)
    lv_trade_receipts           IN VARCHAR2,    -- 10.�d��J�e�S����(���|�^����������)(IN)
    lv_adjustment               IN VARCHAR2,    -- 11.�d��J�e�S����(�C��)(IN)
    lv_credit_memos             IN VARCHAR2,    -- 12.�d��J�e�S����(�N���W�b�g����)(IN)
    lv_credit_memo_applications IN VARCHAR2,    -- 13.�d��J�e�S����(�N���W�b�g��������)(IN)
    lv_cross_currency           IN VARCHAR2,    -- 14.�d��J�e�S����(���ݒʉ�)(IN)
    ov_errbuf                   OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_output'; -- �v���O������
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
    -- LOOKUP_TYPE�l(�d��J�e�S��)
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 'XX03_AR_JOURNAL_CATEGORY';
    -- LOOKUP_TYPE�l(����)
    cv_lookup_type_count      CONSTANT VARCHAR2(50) := 'XX03_AR_COUNT';
--
    -- *** ���[�J���ϐ� ***
    lv_msgbuf  VARCHAR2(5000);     -- �o�̓��b�Z�[�W
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
    lv_category VARCHAR2(100);     -- ��ʕ\����(�d��J�e�S��)
    lv_count    VARCHAR2(100);     -- ��ʕ\����(����)
    lv_count_all NUMBER;          -- (����)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    lv_count_all := (ln_sales_invoices_cnt + ln_trade_receipts_cnt + 
     ln_adjustment_cnt + ln_credit_memos_cnt + ln_credit_memo_app_cnt + ln_cross_currency_cnt);
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    -- ���b�Z�[�W����ʕ\�������擾
    -- �d��J�e�S��
    lv_category := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-03414'); -- ���b�Z�[�W�敪
    -- ����
    lv_count := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-03415'); -- ���b�Z�[�W�敪
    -- ����I�����̉�ʏo��
    -- ���o�������̕\��
    xx03_header_line_output_pkg.header_line_output_p('AR',
      xx00_global_pkg.prog_appl_id,
      0,
      in_org_id,
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- 2�s��(��s)
    xx00_file_pkg.output(' ');
    -- 3�s��(�p�����[�^��)
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' || 
      iv_journal_source);
    xx00_file_pkg.output(xx00_message_pkg.get);
    -- 4�s��(��s)
    xx00_file_pkg.output('');
    -- 5�s��(��������  ����)
    xx00_file_pkg.output(RPAD(lv_category,24,' ') || 
      LPAD(lv_count,7,' '));
    -- 6�s��(��������  ���㐿����)
    xx00_file_pkg.output(RPAD(lv_sales_invoices,24,' ') || 
      TO_CHAR(ln_sales_invoices_cnt,'999999'));
    -- 7�s��(��������  ���|�^����������)
    xx00_file_pkg.output(RPAD(lv_trade_receipts,24,' ') || 
      TO_CHAR(ln_trade_receipts_cnt,'999999'));
    -- 8�s��(��������  �C��)
    xx00_file_pkg.output(RPAD(lv_adjustment,24,' ') || 
      TO_CHAR(ln_adjustment_cnt,'999999'));
    -- 9�s��(��������  �N���W�b�g����)
    xx00_file_pkg.output(RPAD(lv_credit_memos,24,' ') || 
      TO_CHAR(ln_credit_memos_cnt,'999999'));
    -- 10�s��(��������  �N���W�b�g��������)
    xx00_file_pkg.output(RPAD(lv_credit_memo_applications,24,' ') || 
      TO_CHAR(ln_credit_memo_app_cnt,'999999'));
    -- 11�s��(��������  ���ݒʉ�)
    xx00_file_pkg.output(RPAD(lv_cross_currency,24,' ') || 
      TO_CHAR(ln_cross_currency_cnt,'999999'));
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    --���폈����̃��O�o��
    lv_msgbuf := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-07002'); -- ���b�Z�[�W�敪(���)
    lv_msgbuf := lv_msgbuf || cv_package_name || ' ';
    lv_msgbuf := lv_msgbuf || xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-07005',
      'TOK_TABLE',
      cv_execite_tbl_name,
      'COUNT',
      TO_CHAR(lv_count_all,'99999'));
    xx00_file_pkg.log(lv_msgbuf);
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
  END msg_output;
--
--##############################################################################################
------------------------------------------- A2 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_trx_type_1
   * Description      : �O������������肨��ђ��ߎ擾���� [Sales Invoices](A2-1)
   ***********************************************************************************/
  PROCEDURE get_trx_type_1(
    lv_cust_trx_type_id_1       IN  NUMBER,      -- �������^�C�vID(IN)
    lv_type                     OUT VARCHAR2,    -- �������^�C�v(OUT)
    ov_errbuf                   OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_type_1'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_type_1');
    xx00_file_pkg.log('key lv_cust_trx_type_id_1=' || TO_CHAR(lv_cust_trx_type_id_1));
    -- �^�C�v���擾����
    SELECT  rctta.type  AS type                      -- �^�C�v
    INTO    lv_type
    FROM    ra_cust_trx_types_all rctta              -- �������^�C�v
    --2006/01/30 Ver11.5.10.1.6B Add Start
    --WHERE   rctta.cust_trx_type_id  = lv_cust_trx_type_id_1;
    WHERE   rctta.cust_trx_type_id  = lv_cust_trx_type_id_1
     AND    rctta.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    --2006/01/30 Ver11.5.10.1.6B Add End
    -- ���O�o��
    xx00_file_pkg.log('update type=' || lv_type);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03050',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_cust_trx_type_id_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_trx_type_1;
--
-- 20050307 V1.6 START
  /**********************************************************************************
   * Procedure Name   : get_cust_trx_line_gl_dist_dff
   * Description      : �ڋq�������GL�z��DFF�擾���� [����](A3-2)
   **********************************************************************************/
--
  PROCEDURE get_cust_trx_line_gl_dist_dff(
    ln_customer_trx_line_id       IN   NUMBER,              -- ����������ID(IN)
    lv_cust_trx_line_attribute1   OUT  VARCHAR2,            -- �������R(OUT)
    lv_cust_trx_line_attribute2   OUT  VARCHAR2,            -- �����Q��(OUT)
    lv_cust_trx_line_attribute9   OUT  VARCHAR2,            -- �\���P(OUT)
    lv_cust_trx_line_attribute10  OUT  VARCHAR2,            -- �\���Q(OUT)
    ov_errbuf                     OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W  --# �Œ� #
    ov_retcode                    OUT  VARCHAR2,            -- ���^�[���E�R�[�h    --# �Œ� #
    ov_errmsg                     OUT  VARCHAR2)
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx_line_gl_dist_dff'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('  ln_customer_trx_line_id(IN) = ' || TO_CHAR(ln_customer_trx_line_id));
--
    -- �ڋq�������DFF���擾
    SELECT TLD.attribute1   attribute1,                     -- �������R
           TLD.attribute2   attribute2,                     -- �����Q��
           TLD.attribute9   attribute9,                     -- �\���P
           TLD.attribute10  attribute10                     -- �\���Q
    INTO   lv_cust_trx_line_attribute1, 
           lv_cust_trx_line_attribute2,
           lv_cust_trx_line_attribute9,
           lv_cust_trx_line_attribute10
    FROM   ra_cust_trx_line_gl_dist_all  TLD                -- �ڋq�������GL�z���e�[�u��
    WHERE  TLD.customer_trx_line_id = ln_customer_trx_line_id;
--
    -- ���O�o��
    xx00_file_pkg.log('  lv_cust_trx_line_attribute1(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute1));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute2(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute2));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute9(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute9));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute10(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute10));
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(ln_customer_trx_line_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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

   END get_cust_trx_line_gl_dist_dff;
-- 20050307 V1.6 END
--
  /**********************************************************************************
   * Procedure Name   : get_add_dff_lines_data_1
   * Description      : ���������׉�v���擾�����P [Sales Invoices](A2-2)
   **********************************************************************************/
--
  -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
  PROCEDURE get_add_dff_lines_data_1(
   lv_dis_line_number_1           IN VARCHAR2,     -- �������^�C�v�h�c(IN)
   lv_line_attribute1_1           OUT VARCHAR2,    -- �������R(OUT)
   lv_line_attribute2_1           OUT VARCHAR2,    -- �����Q��(OUT)
   lv_line_customer_trx_line_id_1 OUT NUMBER,      -- ����������ID(OUT)
   lv_line_attribute9_1           OUT VARCHAR2,    -- �\���P(OUT)
   lv_line_attribute10_1          OUT VARCHAR2,    -- �\���Q(OUT)
   ov_errbuf                      OUT VARCHAR2,    -- �G���[�E���b�Z�[�W   --# �Œ� #
   ov_retcode                     OUT VARCHAR2,    -- ���^�[���E�R�[�h     --# �Œ� #
   ov_errmsg                      OUT VARCHAR2)
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_lines_data_1'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_lines_data_1');
    xx00_file_pkg.log('key lv_dis_line_number_1=' || TO_CHAR(lv_dis_line_number_1));
    -- �^�C�v���擾����
    -- 20050131 V1.5 �\���P�E�\���Q�̒ǉ�
    SELECT rctlgda.attribute1 AS attribute1,    --�������R
  --       rctlgda.attribute1 AS attribute2,    20040506 �C��
           rctlgda.attribute2 AS attribute2,    --�����Q��
           rctlgda.customer_trx_line_id AS customer_trx_line_id,  --����������ID
           rctlgda.attribute9 AS attribute9,    --�\���P
           rctlgda.attribute10 AS attribute10   --�\���Q
    INTO   lv_line_attribute1_1, 
           lv_line_attribute2_1,
           lv_line_customer_trx_line_id_1,
           lv_line_attribute9_1,
           lv_line_attribute10_1
    FROM   ra_cust_trx_line_gl_dist_all  rctlgda  --���������׉�v���
    WHERE  lv_dis_line_number_1 =  rctlgda.cust_trx_line_gl_dist_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_dis_line_number_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
   END get_add_dff_lines_data_1;
  /**********************************************************************************
   * Procedure Name   : get_ra_cus_trx_lines_all_1
   * Description      : ���������׉�v���擾�����Q [Sales Invoices](A2-3)
   **********************************************************************************/
--
  PROCEDURE get_ra_cus_trx_lines_all_1(
   lv_line_cust_trx_line_id_1 IN VARCHAR2,    -- ����������ID(IN)
   lv_vat_tax_id              OUT NUMBER,     -- ��ID(OUT)
   lv_descripion              OUT VARCHAR2,   -- ���דE�v(OUT)
   ov_errbuf                  OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode                 OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg                  OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_cus_trx_lines_all_1'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_cus_trx_lines_all_1');
    xx00_file_pkg.log('key lv_line_cust_trx_line_id_1=' || TO_CHAR(lv_line_cust_trx_line_id_1));
    -- �^�C�v���擾����
    SELECT  rctla.vat_tax_id AS vat_tax_id,   --��ID
            rctla.description AS description  --���דE�v
    INTO    lv_vat_tax_id,
            lv_descripion
    FROM    ra_customer_trx_lines_all rctla
    WHERE   rctla.customer_trx_line_id  = lv_line_cust_trx_line_id_1;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03053',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_line_cust_trx_line_id_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ra_cus_trx_lines_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_1
   * Description      : AR�Ńe�[�u�����擾���� [Sales Invoices](A2-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_vat_tax_all_1(
   lv_vat_tax_id         IN  NUMBER,      -- ��ID(IN)
   lv_avta_tax_code      OUT VARCHAR2,    -- �ŃR�[�h(OUT)
   ov_errbuf             OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode            OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg             OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_1'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_1');
    xx00_file_pkg.log('key lv_vat_tax_id=' || TO_CHAR(lv_vat_tax_id));
    -- �^�C�v���擾����
    SELECT  avta.tax_code AS tax_code    --�ŃR�[�h
    INTO    lv_avta_tax_code
    FROM    ar_vat_tax_all  avta
    WHERE   avta.vat_tax_id  = lv_vat_tax_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                 --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03054',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_vat_tax_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ar_vat_tax_all_1;
--
--##############################################################################################
------------------------------------------- A3 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_trx_number
   * Description      : �����ϐ������ԍ��̎擾���� [Credit Memo](A3-1)
   ***********************************************************************************/
  PROCEDURE get_trx_number(
    lv_previous_cust_trx_id    IN  VARCHAR2,     -- �e�������h�c(IN)
    lv_trx_number              OUT VARCHAR2,     -- �������ԍ�(OUT)
    ov_errbuf                  OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_number'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_number');
    xx00_file_pkg.log('key lv_previous_cust_trx_id=' || TO_CHAR(lv_previous_cust_trx_id));
    -- �^�C�v���擾����
    SELECT  rcta.trx_number AS trx_number   --�������ԍ�
    INTO    lv_trx_number 
    FROM    ra_customer_trx_all rcta        --�������w�b�_�e�[�u��
    WHERE   lv_previous_cust_trx_id = rcta.customer_trx_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03051',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_previous_cust_trx_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_trx_number;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_lines_data_2
   * Description      : ���������׉�v���擾�����P [Credit Memo](A3-2)
   **********************************************************************************/
--
  -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
  PROCEDURE get_add_dff_lines_data_2(
   lv_dis_line_number_2            IN  VARCHAR2,  -- �������z��ID(IN)
   lv_line_attribute1_2            OUT VARCHAR2,  -- �������R(OUT)
   lv_line_attribute2_2            OUT VARCHAR2,  -- �����Q��(OUT)
   lv_line_customer_trx_line_id_2  OUT NUMBER,    -- ����������ID(OUT)
   lv_line_attribute9_2            OUT VARCHAR2,  -- �\���P(OUT)
   lv_line_attribute10_2           OUT VARCHAR2,  -- �\���Q(OUT)
   ov_errbuf                       OUT VARCHAR2,  -- �G���[�E���b�Z�[�W   --# �Œ� #
   ov_retcode                      OUT VARCHAR2,  -- ���^�[���E�R�[�h     --# �Œ� #
   ov_errmsg                       OUT VARCHAR2)
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_lines_data_2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_lines_data_2');
    xx00_file_pkg.log('key lv_dis_line_number_2=' || TO_CHAR(lv_dis_line_number_2));
    -- �^�C�v���擾����
    -- 20050131 V1.5 �\���P�E�\���Q�̒ǉ�
    SELECT rctlgda.attribute1 AS attribute1,    --�������R
--         rctlgda.attribute1 AS attribute2,    20040506 �C��
           rctlgda.attribute2 AS attribute2,    --�����Q��
           rctlgda.customer_trx_line_id AS customer_trx_line_id,  --����������ID
           rctlgda.attribute9 AS attribute9,    --�\���P
           rctlgda.attribute10 AS attribute10   --�\���Q
    INTO   lv_line_attribute1_2, 
           lv_line_attribute2_2,
           lv_line_customer_trx_line_id_2,
           lv_line_attribute9_2,
           lv_line_attribute10_2
    FROM   ra_cust_trx_line_gl_dist_all  rctlgda  --���������׉�v���
    WHERE  lv_dis_line_number_2 =  rctlgda.cust_trx_line_gl_dist_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_dis_line_number_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
   END get_add_dff_lines_data_2;
  /**********************************************************************************
   * Procedure Name   : get_ra_cus_trx_lines_all_2
   * Description      : ���������׉�v���擾�����Q [Credit Memo](A3-3)
   **********************************************************************************/
--
  PROCEDURE get_ra_cus_trx_lines_all_2(
   lv_line_cust_trx_line_id_2   IN VARCHAR2,   -- ����������ID(IN)
   lv_vat_tax_id_2              OUT NUMBER,    -- ��ID(OUT)
   lv_descripion_2              OUT VARCHAR2,  -- ���דE�v(OUT)
   ov_errbuf                    OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode                   OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg                    OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_cus_trx_lines_all_2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_cus_trx_lines_all_2');
    xx00_file_pkg.log('key lv_line_cust_trx_line_id_2=' || TO_CHAR(lv_line_cust_trx_line_id_2));
    -- �^�C�v���擾����
    SELECT  rctla.vat_tax_id AS vat_tax_id,   --��ID
            rctla.description AS description  --���דE�v
    INTO    lv_vat_tax_id_2,
            lv_descripion_2
    FROM    ra_customer_trx_lines_all rctla
    WHERE   rctla.customer_trx_line_id  = lv_line_cust_trx_line_id_2;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03053',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_line_cust_trx_line_id_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ra_cus_trx_lines_all_2;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_2
   * Description      : AR�Ńe�[�u�����擾���� [Credit Memo](A3-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_vat_tax_all_2(
   lv_vat_tax_id_2         IN  NUMBER,      -- ��ID(IN)
   lv_avta_tax_code_2      OUT VARCHAR2,    -- �ŃR�[�h(OUT)
   ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_2');
    xx00_file_pkg.log('key lv_vat_tax_id_2=' || TO_CHAR(lv_vat_tax_id_2));
    -- �^�C�v���擾����
    SELECT  avta.tax_code AS tax_code    --�ŃR�[�h
    INTO    lv_avta_tax_code_2
    FROM    ar_vat_tax_all  avta
    WHERE   avta.vat_tax_id  = lv_vat_tax_id_2;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03054',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_vat_tax_id_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ar_vat_tax_all_2;
--##############################################################################################
------------------------------------------- A5 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_ra_customer_rx_all_1
   * Description      : �O������������肨��ђ��ߎ擾����_1 [adjustment](A5-1)
   ***********************************************************************************/
  PROCEDURE get_ra_customer_rx_all_1(
    lv_customer_trx_id               IN  NUMBER,    -- �������^�C�vID(IN)
    lv_rcta2_trx_number              OUT VARCHAR2,  -- �������ԍ�(OUT)
    lv_rcta2_attribute5              OUT VARCHAR2,  -- �N�[����(OUT)
    lv_rcta2_attribute6              OUT VARCHAR2,  -- ���͎�(OUT)
    lv_rcta2_initial_cust_trx_id     OUT VARCHAR2,  -- ������(OUT)
    ov_errbuf                        OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                       OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                        OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_customer_rx_all_1'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_customer_rx_all_1');
    xx00_file_pkg.log('key lv_customer_trx_id=' || TO_CHAR(lv_customer_trx_id));
    -- �^�C�v���擾����
    SELECT  rcta2.trx_number  AS trx_number,    --�������ԍ�
            rcta2.attribute5 AS attribute5,     --�N�[����
            rcta2. attribute6 AS attribute6,    --���͎�
            rcta2.initial_customer_trx_id AS initial_customer_trx_id    --������
    INTO    lv_rcta2_trx_number,
            lv_rcta2_attribute5,
            lv_rcta2_attribute6,
            lv_rcta2_initial_cust_trx_id
    FROM    ra_customer_trx_all rcta2           --�������w�b�_�e�[�u��
    WHERE   rcta2.customer_trx_id = lv_customer_trx_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                    --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03055',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_customer_trx_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ra_customer_rx_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ra_customer_rx_all_2
   * Description      : �O������������肨��ђ��ߎ擾����_2 [adjustment](A5-2)
   **********************************************************************************/
--
  PROCEDURE get_ra_customer_rx_all_2(
   lv_initial_customer_trx_id   IN  NUMBER,    -- ������ID(IN)
   lv_cust_trx_type_id          OUT NUMBER,    -- �������^�C�vID(OUT)
   lv_flg_1                     OUT VARCHAR2,  -- ����t���O(OUT)
   ov_errbuf                    OUT VARCHAR2,  -- �G���[�E���b�Z�[�W   --# �Œ� #
   ov_retcode                   OUT VARCHAR2,  -- ���^�[���E�R�[�h     --# �Œ� #
   ov_errmsg                    OUT VARCHAR2)
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_customer_rx_all_2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_customer_rx_all_2');
    xx00_file_pkg.log('key lv_initial_customer_trx_id=' || TO_CHAR(lv_initial_customer_trx_id));
    -- �^�C�v���擾����
    SELECT  rcta3.cust_trx_type_id  AS cust_trx_type_id    --�������^�C�v�h�c
    INTO    lv_cust_trx_type_id 
    FROM    ra_customer_trx_all rcta3                      --�������w�b�_�e�[�u��
    WHERE   rcta3.customer_trx_id =  lv_initial_customer_trx_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
         lv_flg_1 := '1';                         -- ����t���O
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
   END get_ra_customer_rx_all_2;
  /**********************************************************************************
   * Procedure Name   : get_trx_type_2
   * Description      : �O������������肨��ђ��ߎ擾����_3 [adjustment](A5-3)
   **********************************************************************************/
--
  PROCEDURE get_trx_type_2(
   lv_cust_trx_type_id  IN NUMBER,           -- �������^�C�vID(IN)
   lv_type              OUT VARCHAR2,        -- �^�C�v(OUT)
   lv_flg_2             OUT VARCHAR2,        -- ����t���O(OUT)
   ov_errbuf            OUT VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode           OUT VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg            OUT VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_type_2'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_type_2');
    xx00_file_pkg.log('key lv_cust_trx_type_id=' || TO_CHAR(lv_cust_trx_type_id));
    -- �^�C�v���擾����

    SELECT  rctta1.type  AS type              --�^�C�v
    INTO    lv_type 
    FROM    ra_cust_trx_types_all rctta1      --�������^�C�v
    WHERE   rctta1.cust_trx_type_id  =  lv_cust_trx_type_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
         lv_flg_2 := '1';                         -- ����t���O
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
  END get_trx_type_2;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_3
   * Description      : AR�Ńe�[�u�����擾���� [adjustment](A5-4)
   **********************************************************************************/
--
  -- 20050131 V1.5 �p�����[�^�̕ύX
  --                 �iAFF�g����ID�ilv_code_combination_id�j
  --                                                      �� ������ID�iinvoice_id�j�j
  --                �y��
  --               �p�����[�^�̒ǉ��i���׎d��^�C�v�ipayment_id�j�j
  PROCEDURE get_ar_vat_tax_all_3(
   lv_invoice_id         IN  VARCHAR2,   -- ������ID (IN)
   lv_payment_id         IN  VARCHAR2,   -- ���׎d��^�C�v
   lv_xx03_tax_code      IN  VARCHAR2,   -- XX03_TAX_CODES(NAME)(IN)
   lv_tax_code           OUT VARCHAR2,     -- �ŃR�[�h(OUT)
   ov_errbuf             OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode            OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_3'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_3');
--    xx00_file_pkg.log('key lv_code_combination_id=' || TO_CHAR(lv_code_combination_id));
    -- �^�C�v���擾����
-- 20050131 V1.5 START
--    SELECT  avta.tax_code AS tax_code      --�ŃR�[�h
--    INTO    lv_tax_code
--    FROM    ar_vat_tax_all  avta           --AR�Ńe�[�u��
--    WHERE   avta.tax_account_id = lv_code_combination_id;
--
    IF lv_payment_id = 'ADJ_ADJ' OR 
       lv_payment_id = 'ADJ_TAX' OR 
       lv_payment_id = 'ADJ_ADJ_NON_REC_TAX' THEN
         SELECT  avta.tax_code AS tax_code      --�ŃR�[�h
         INTO    lv_tax_code
         FROM    ar_distributions_all ada,       --AR�z��
                 ar_vat_tax_all  avta           --AR�Ńe�[�u��
         WHERE   ada.tax_code_id = avta.vat_tax_id
         AND     ada.source_id   = lv_invoice_id;
    END IF;
--
-- 20050131 V1.5 END
--
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
-- 2004/04/20 �f�[�^NOT FOUND ���̑Ή��i�f�[�^�Ή��j
      lv_tax_code := lv_xx03_tax_code;
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
-- 2004/04/20 �ۗ��i�f�[�^�Ή��j   
--      lv_errbuf := xx00_message_pkg.get_msg(
--        'XX03',  --�A�v���P�[�V�����Z�k��
--        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
--      lv_errbuf := lv_errbuf || cv_package_name || ' ';
--      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
--        'XX03',  --�A�v���P�[�V�����Z�k��
--        'APP-XX03-03054',
--        'TOK_XX03_DFF_KEY',
--        TO_CHAR(lv_code_combination_id));
--      xx00_file_pkg.log(lv_errbuf);
--      ov_errmsg := lv_errmsg;                                                           --# �C�� #
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
--      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
--
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
  END get_ar_vat_tax_all_3;
--##############################################################################################
------------------------------------------- A6 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_ra_hz_cust_account
   * Description      : �ڋq�w�b�_�[�e�[�u�����ݒ�l�擾���� [Trade Receipts] (A6-1)
   ***********************************************************************************/
  PROCEDURE get_ra_hz_cust_account(
    lv_pay_from_customer        IN  VARCHAR2,    -- �x���ڋq(IN)
    lv_hca_account_number       OUT VARCHAR2,    -- �ڋq�ԍ�(OUT)
    lv_hca_party_id             OUT NUMBER,      -- �p�[�e�BID(OUT)
    lv_hca_attribute2           OUT VARCHAR2,    -- �ꌩ�ڋq�敪(OUT)
    ov_errbuf                   OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_hz_cust_account'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_hz_cust_account');
    xx00_file_pkg.log('key lv_pay_from_customer=' || TO_CHAR(lv_pay_from_customer));
    -- �^�C�v���擾����
    SELECT  hca.account_number  AS account_number,  -- �ڋq�ԍ�
            hca.party_id  AS party_id,              -- �p�[�e�B�h�c
            hca.attribute2  AS attribute2           -- �ꌩ�ڋq�敪
    INTO    lv_hca_account_number,
            lv_hca_party_id,  
            lv_hca_attribute2
    FROM    hz_cust_accounts hca                    -- �ڋq
    WHERE   lv_pay_from_customer  =   hca.cust_account_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03058',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_pay_from_customer));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ra_hz_cust_account;
  /**********************************************************************************
   * Procedure Name   : get_hz_parties
   * Description      : �ꌩ�ڋq�o�Ȃ��ꍇ�A�p�[�e�B�e�[�u�����擾����  [Trade Receipts] (A6-2)
   **********************************************************************************/
--
  PROCEDURE get_hz_parties(
   lv_hca_party_id          IN  NUMBER,    -- �p�[�e�BID(IN)
   lv_hp_party_name         OUT VARCHAR2,  -- �p�[�e�B��(OUT)
   ov_errbuf                OUT VARCHAR2,  -- �G���[�E���b�Z�[�W   --# �Œ� #
   ov_retcode               OUT VARCHAR2,  -- ���^�[���E�R�[�h     --# �Œ� #
   ov_errmsg                OUT VARCHAR2)
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_parties'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_hz_parties');
    xx00_file_pkg.log('key lv_hca_party_id=' || TO_CHAR(lv_hca_party_id));
    -- �^�C�v���擾����
    SELECT  hp.party_name  AS party_name     --�p�[�e�B��
    INTO    lv_hp_party_name
    FROM    hz_parties hp                    --�p�[�e�B
    WHERE   lv_hca_party_id = hp.party_id;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03059',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_hca_party_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
   END get_hz_parties;
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_receipt_his_all_1
   * Description      : ���������ԍ��擾�����P [Trade Receipts] (A6-3)
   **********************************************************************************/
--
  PROCEDURE get_ar_cash_receipt_his_all_1(
   lv_invoice_id        IN  VARCHAR2,     -- ����ID(IN)
   lv_acrha_status      OUT VARCHAR2,     -- �X�e�[�^�X(OUT)
   ov_errbuf            OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode           OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg            OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_receipt_his_all_1'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_cash_receipt_his_all_1');
    xx00_file_pkg.log('key lv_invoice_id=' || TO_CHAR(lv_invoice_id));
    -- �^�C�v���擾����
    SELECT  acrha.status AS status             --�X�e�[�^�X
    INTO    lv_acrha_status
    FROM    ar_cash_receipt_history_all acrha --�����������e�[�u��
    WHERE   acrha.cash_receipt_history_id = substr(lv_invoice_id, instr(lv_invoice_id,'C',1)+1);
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03060',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ar_cash_receipt_his_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_receipts_all
   * Description      : ���������ԍ��擾�����Q�߂� [Trade Receipts] (A6-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_cash_receipts_all(
   lv_invoice_id              IN  VARCHAR2,   -- ����ID(IN)
   lv_acra_doc_sequence_value OUT NUMBER,     -- ���������ԍ��߂�(OUT)
   ov_errbuf                  OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ov_retcode                 OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
   ov_errmsg                  OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_receipts_all'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_cash_receipts_all');
    xx00_file_pkg.log('key lv_invoice_id=' || TO_CHAR(lv_invoice_id));
    -- �^�C�v���擾����
    SELECT  acra.doc_sequence_value AS doc_sequence_value  --���������ԍ�
    INTO    lv_acra_doc_sequence_value
    FROM    ar_cash_receipts_all acra                      --�������e�[�u��
    WHERE   acra.cash_receipt_id = substr(lv_invoice_id, instr(lv_invoice_id,'C',1)+1);
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03060',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_ar_cash_receipts_all;
  /**********************************************************************************
   * Procedure Name   : get_id
   * Description      : �֘A�f�[�^�擾 (A-1)
   ***********************************************************************************/
  PROCEDURE get_id(
    on_gl_book_id           OUT NUMBER,       -- 1.��v���뒠��ID(OUT)
    on_org_id               OUT NUMBER,       -- 2.�I���OID(OUT)
    ov_sales_invoices       OUT VARCHAR2,     -- 3.�d��J�e�S����(���㐿����)(OUT)
    ov_trade_receipts       OUT VARCHAR2,     -- 4.�d��J�e�S����(���|�^����������)(OUT)
    ov_adjustment           OUT VARCHAR2,     -- 5.�d��J�e�S����(�C��)(OUT)
    ov_credit_memos         OUT VARCHAR2,     -- 6.�d��J�e�S����(�N���W�b�g����)(OUT)
    ov_credit_memo_applications OUT VARCHAR2, -- 7.�d��J�e�S����(�N���W�b�g��������)(OUT)
    ov_cross_currency       OUT VARCHAR2,     -- 8.�d��J�e�S����(���ݒʉ�)(OUT)
    ov_xx03_tax_code        OUT VARCHAR2,     -- 9.XX03_TAX_CODES_V(NAME)(OUT)
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_id'; -- �v���O������
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
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 
      'XX03_AR_JOURNAL_TYPE'; -- LOOKUP_TYPE�l
    cv_lookup_code_buying   CONSTANT VARCHAR2(50) := 
      'BUYING_IN_INVOICE'; -- LOOKUP_CODE�l(������)
    cv_lookup_code_payment  CONSTANT VARCHAR2(50) := 
      'PAYMENT_TYPE'; -- LOOKUP_CODE�l(�x��)
--
    -- *** ���[�J���ϐ� ***
    lv_category_err_tk    VARCHAR2(50); -- �d��J�e�S�����擾�G���[�g�[�N���l
    -- Ver11.5.10.1.6 2005/12/15 Delete Start
    -- ov_xx03_tax_code_cnt  NUMBER;       -- XX03_TAX_CODES_V(NAME)����
    -- Ver11.5.10.1.6 2005/12/15 Delete End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_id');
    --�I���OID�̎擾
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    --�I���OID�l�̌���
    IF (on_org_id IS NULL) THEN
      -- �I���OID���擾�G���[
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03045');
      RAISE get_org_id_expt;
    END IF;
--
    --��v����ID�̎擾
    on_gl_book_id := TO_NUMBER(xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    --��v����ID�l�̌���
    IF on_gl_book_id IS NULL THEN
      -- ��v����ID���擾�G���[
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03044');
      RAISE get_books_id_expt;
    END IF;
--
    --�d��J�e�S����(���㐿����)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_sales_invoices
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Sales Invoices';
    
    --�d��J�e�S����(���|�^��������)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_trade_receipts
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Trade Receipts';
    
    --�d��J�e�S����(�C��)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_adjustment
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Adjustment';
    
    --�d��J�e�S����(�N���W�b�g����)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_credit_memos
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Credit Memos';
    
    --�d��J�e�S����(�N���W�b�g��������)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_credit_memo_applications
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Credit Memo Applications';
    
    --�d��J�e�S����(���ݒʉ�)�̎擾
    SELECT  gjsv.user_je_category_name
    INTO    ov_cross_currency
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Cross Currency';
    
    -- Ver11.5.10.1.6 2005/12/15 Delete Start
    --20040512 XX03_TAX_CODES_V(NAME) �ǉ� START
    --20040512 XX03_TAX_CODES_V(NAME)�̎擾
    --SELECT  count(xx03_tcv.name)
    --INTO    ov_xx03_tax_code_cnt
    --FROM  xx03_tax_codes_v xx03_tcv
    --WHERE xx03_tcv.attribute1 IS NULL;
    --IF ov_xx03_tax_code_cnt > 1 OR
    --   ov_xx03_tax_code_cnt = 0 THEN
    -- --�����擾�G���[�����i�O�� or �Q���ȏ㑶�݂����ꍇ�j
    --  -- �G���[���b�Z�[�W�擾
    --  lv_category_err_tk := 'ov_xx03_tax_codes_v';
    --  lv_errbuf := xx00_message_pkg.get_msg(
    --    'XX03',  --�A�v���P�[�V�����Z�k��
    --    'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
    --  lv_errbuf := lv_errbuf || cv_package_name || ' ';
    --  lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
    --    'XX03',  --�A�v���P�[�V�����Z�k��
    --    'APP-XX03-03082',
    --    'TOK_XX03_LOOKUP_TYPE',
    --    lv_category_err_tk);  -- ���擾�d��J�e�S����
    --  RAISE get_xx03_name_id_expt;
    --END IF;
    --SELECT  xx03_tax_code.name
    --INTO    ov_xx03_tax_code
    --FROM  xx03_tax_codes_v xx03_tax_code
    --WHERE xx03_tax_code.attribute1 IS NULL;
    -- --20040512 XX03_TAX_CODES_V(NAME) �ǉ� END
    -- Ver11.5.10.1.6 2005/12/15 Delete End
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN get_org_id_expt THEN                       --*** �I���OID���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
--
    WHEN get_books_id_expt THEN                       --*** ��v����ID���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
--
    WHEN get_xx03_name_id_expt THEN                       --*** ��v����ID���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
--
    WHEN NO_DATA_FOUND THEN                       --*** �d��J�e�S�����f�l���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      -- �擾�ł��Ȃ������d��J�e�S���̔��f
      IF ov_sales_invoices IS NULL THEN
        lv_category_err_tk := 'Sales Invoices';
      END IF;
      IF ov_trade_receipts IS NULL THEN
        lv_category_err_tk := 'Trade Receipts';
      END IF;
      IF ov_adjustment IS NULL THEN
        lv_category_err_tk := 'Adjustment';
      END IF;
      IF ov_credit_memos IS NULL THEN
        lv_category_err_tk := 'Credit Memos';
      END IF;
      IF ov_credit_memo_applications IS NULL THEN
        lv_category_err_tk := 'Credit Memo Applications';
      END IF;
      IF ov_cross_currency IS NULL THEN
        lv_category_err_tk := 'Cross Currency';
      END IF;
      -- Ver11.5.10.1.6 2005/12/15 Delete Start
      -- --20040512 XX03_TAX_CODES_V(NAME) �ǉ� START
      --  IF ov_xx03_tax_code IS NULL THEN
      --    lv_category_err_tk := 'ov_xx03_tax_codes_v';
      --  END IF;
      -- --20040512 XX03_TAX_CODES_V(NAME) �ǉ� END
      -- Ver11.5.10.1.6 2005/12/15 Delete End
      -- �G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-07003'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-03082',
        'TOK_XX03_LOOKUP_TYPE',
        lv_category_err_tk);  -- ���擾�d��J�e�S����
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_id;

  /**********************************************************************************
   * Procedure Name   : upd_journal_data
   * Description      : �d��f�[�^�̍X�V���� (A8)
   ***********************************************************************************/
  -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
  PROCEDURE upd_journal_data(
    ir_rowid                IN ROWID,      -- 1.ROWID(IN)
    iv_je_source            IN VARCHAR2,   -- 2.�d��\�[�X��(IN)
    iv_je_name              IN VARCHAR2,   -- 3.�d��(IN)
    iv_group_id             IN NUMBER,     -- 4.�d��(IN)
    iv_context_name         IN VARCHAR2,   -- 5.��v����(�R���e�L�X�g)��(IN)
    iv_trx_number           IN VARCHAR2,   -- 6.�������ԍ�(IN)
    iv_doc_sequence_value   IN VARCHAR2,   -- 7.�����������ԍ�(IN)
    iv_rcta_attribut5       IN VARCHAR2,   -- 8.�N�[����(IN)
    iv_rcta_attribut6       IN VARCHAR2,   -- 9.���͎�(IN)
    iv_avta_tax_code        IN VARCHAR2,   -- 10.�ŃR�[�h(IN)
    iv_line_attribute1_1    IN VARCHAR2,   -- 11.�������R(IN)
    iv_line_attribute2_1    IN VARCHAR2,   -- 12.�����Q��(IN)
    iv_descripion           IN VARCHAR2,   -- 13.���דE�v/����(IN)
    iv_attribute6           IN VARCHAR2,   -- 14.�C�����`�[�ԍ�(IN)
    iv_attribute9           IN VARCHAR2,   -- 15,�\���P(IN)
    iv_attribute10          IN VARCHAR2,   -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
    iv_rctlda_attribute11   IN VARCHAR2,   -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
    ov_errbuf               OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_journal_data'; -- �v���O������
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
    ln_group_id   gl_interface.group_id%TYPE; -- GL�C���^�[�t�F�[�X�O���[�vID
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data');
--
    --GL�C���^�[�t�F�[�X�X�V����
    -- 20050131 V1.5 �\���P�E�\���Q�̒ǉ�
    UPDATE gl_interface
    SET    group_id    = iv_group_id,             -- �O���[�vID
           context     = iv_context_name,         -- �R���e�L�X�g�i��v���떼�j
           reference4  = iv_doc_sequence_value,   -- �d��
           reference10 = iv_descripion,           -- ���דE�v
           jgzz_recon_ref = iv_line_attribute2_1, -- �����Q��
           attribute1  = iv_avta_tax_code,        -- �ŃR�[�h
           attribute2  = iv_line_attribute1_1,    -- �������R
           attribute3  = iv_trx_number,           -- �`�[�ԍ��i�������ԍ��j
           attribute4  = iv_rcta_attribut5,       -- �N�[����
           attribute5  = iv_rcta_attribut6,       -- ���͎�
           attribute6  = iv_attribute6,           -- �C�����`�[�ԍ��i�����������ԍ��j
           attribute9  = iv_attribute9,           -- �\���P
           attribute10 = iv_attribute10           -- �\���Q
-- ver 11.5.10.2.4 Add Start
          ,attribute15 = iv_rctlda_attribute11    -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
    WHERE  ROWID = ir_rowid;
-- 20050131 V1.5 END
--
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
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
  END upd_journal_data;
--
-- 20040512 GL_INTERFACE �ŋ敪�iNULL�j�f�[�^�̑Ή� START
-- GL_INTERFACE�i���|�Ǘ����R�[�h�ɑ΂���t�����X�V��ɐŋ敪�iNULL�j�f�[�^�ɑ΂�
-- XX03_TAX_CODES_V�e�[�u����ATTRIBUTE1 = NULL ������NAME���ڂ��擾���ŋ敪�ɃZ�b�g
  /**********************************************************************************
   * Procedure Name   : upd_journal_data_1
   * Description      : �d��f�[�^�̍X�V���� �ŋ敪�iNULL�j�f�[�^�Ή�(A8_1)
   ***********************************************************************************/
  PROCEDURE upd_journal_data_1(
    lv_xx03_tax_code        IN VARCHAR2,     -- 1.xx03_tax_code(IN)
    lv_journal_source       IN VARCHAR2,     -- 2.�d��\�[�X��(IN)
    ov_errbuf               OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_journal_data_1'; -- �v���O������
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data_1');
--
    --GL�C���^�[�t�F�[�X�X�V����
    UPDATE gl_interface
    SET    attribute1  = lv_xx03_tax_code        -- �ŃR�[�h
    WHERE   user_je_source_name =  lv_journal_source        -- �d��\�[�X��
    AND     status ='NEW'
    AND     actual_flag = 'A'
    AND     attribute1  IS NULL; 
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
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
  END upd_journal_data_1;
-- 20040512 GL_INTERFACE �ŋ敪�iNULL�j�f�[�^�̑Ή� END
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_1
   * Description      : DFF�t���Ώۃf�[�^���o���� [Sales Invoices] (A2)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_1(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_sales_invoices       IN VARCHAR2,     -- 3.�d��J�e�S����(���㐿����)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    ln_sales_invoices_cnt   IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(���㐿����)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_1'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;   -- �R���e�L�X�g�l
    lv_A2_flg                         VARCHAR2(1);     -- �O�������������
    lv_type                           VARCHAR2(20);    -- �^�C�v
    lv_line_attribute1_1              VARCHAR2(150);   -- �������R
    lv_line_attribute2_1              VARCHAR2(150);   -- �����Q��
    lv_vat_tax_id                     NUMBER(15);      -- ��ID
    lv_descripion                     VARCHAR2(240);   -- ���דE�v
    lv_line_customer_trx_line_id_1    NUMBER(15);      -- ����������ID
    lv_avta_tax_code                  VARCHAR2(50);    -- �ŃR�[�h
-- 20050131 V1.5 START
    lv_line_attribute9_1              VARCHAR2(150);   -- �\���P
    lv_line_attribute10_1             VARCHAR2(150);   -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    CURSOR gl_add_dff_data_cur_1
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- �d��J�e�S��-�d��J�e�S��
              gi.reference22 AS invoice_id,                      -- ������ID
              gi.reference23 AS distribution_line_number,        -- ���������הԍ�/�x��ID
              gi.reference29 AS payment_id,                      -- ���׎d��^�C�v
              gi.group_id AS group_id ,                          -- �p�����[�^�O���[�vID
              gi.context AS context ,                            -- ��v���떼
              gi.reference4 AS reference4,                       -- ���o�ςf�k�d��P��
              gi.reference10 AS reference10,                     -- ���o�ϖ��׊T�v
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- ���o�Ϗ����Q��
              gi.attribute1 AS attribute1,                       -- ���o�ϐŋ敪
              gi.attribute2 AS attribute2,                       -- ���o�ϑ������R
              gi.attribute3 AS attribute3,                       -- ���o�ϓ`�[�ԍ�
              gi.attribute4 AS attribute4,                       -- ���o�ϋN�[����
              gi.attribute5 AS attribute5,                       -- ���o�ϓ��͎�
              gi.attribute6 AS attribute6,                       -- ���o�ϏC�����`�[�ԍ�
              rcta.trx_number AS trx_number,                     -- �������ԍ�
              rcta.doc_sequence_value AS doc_sequence_value,     -- �����������ԍ�
              rcta.attribute5 AS rcta_attribut5,                 -- �N�[����
              rcta.attribute6 AS rcta_attribut6,                 -- ���͎�
              rcta.previous_customer_trx_id AS previous_customer_trx_id, --�e�������h�c
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- �������^�C�v�h�c
              rcta.comments AS comments                          -- ����
-- ver 11.5.10.2.4 Add Start
             ,rctlda.attribute11 AS rctlda_attribute11           -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GL�C���^�[�t�F�[�X�e�[�u��
              ra_customer_trx_all rcta                           -- �������w�b�_�e�[�u��
-- ver 11.5.10.2.4 Add Start
             ,ra_cust_trx_line_gl_dist_all rctlda                -- ���������׉�v���
-- ver 11.5.10.2.4 Add End
      WHERE   gi.user_je_source_name =  lv_journal_source        -- �d��\�[�X��
      AND     gi.user_je_category_name = lv_sales_invoices       -- �d��J�e�S����(���㐿����)
      AND     rcta.customer_trx_id = gi.reference22
-- ver 11.5.10.2.4 Add Start
      AND     rctlda.cust_trx_line_gl_dist_id(+) = gi.reference23
-- ver 11.5.10.2.4 Add End
      AND     gi.status ='NEW'
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('INV_REC','INV_REV','INV_TAX'))
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_1 gl_add_dff_data_cur_1%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_sales_invoices);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_1;
    <<interface_loop>>
    LOOP
      FETCH gl_add_dff_data_cur_1 INTO gl_add_dff_data_rec_1;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_1%NOTFOUND THEN
          EXIT interface_loop;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_1.user_je_category_name);

      lv_A2_flg := '0';                                   -- �O������������菉���l
      lv_line_attribute1_1 := '';                         -- �������R�����l
      lv_line_attribute2_1 := '';                         -- �����Q�Ə����l
      lv_descripion := '';                                -- ���דE�v�����l
      lv_avta_tax_code := '';                             -- �ŃR�[�h�����l
      lv_descripion := gl_add_dff_data_rec_1.reference10; -- ���דE�v�Z�b�g�����l
-- 20050131 V1.5 START
      lv_line_attribute9_1 := '';                         -- �\���P�����l
      lv_line_attribute10_1 := '';                        -- �\���Q�����l
-- 20050131 V1.5 END

      -- ==========================================================
      -- �O������������肨��ђ��ߎ擾���� [Sales Invoices](A2-1)
      -- ==========================================================
      -- ���׎d��^�C�v�̔��f
      IF gl_add_dff_data_rec_1.payment_id = 'INV_REC' OR 
         gl_add_dff_data_rec_1.payment_id = 'INV_REV' THEN
        get_trx_type_1(
            gl_add_dff_data_rec_1.cust_trx_type_id,       -- �������^�C�vID(IN)
            lv_type,                                      -- �������^�C�v(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
          --�O����������`�F�b�N����
          IF lv_type = 'DEP' THEN
              lv_A2_flg := '1';                                   -- �O������������肠��
             --���דE�v���ڂ֒��߃Z�b�g����
             lv_descripion := gl_add_dff_data_rec_1.reference10;  -- ���דE�v�Z�b�g�����l
             IF gl_add_dff_data_rec_1.payment_id = 'INV_REV' THEN -- 'INV_REV'�̏ꍇ
                lv_descripion := gl_add_dff_data_rec_1.comments;  -- ���דE�v�Z�b�g
             END IF;
          END IF;
      END IF;
    -- ====================================================
    -- ���������׉�v���擾�����P [Sales Invoices](A2-2)
    -- ====================================================
      IF lv_A2_flg = '0' THEN
        IF gl_add_dff_data_rec_1.payment_id = 'INV_REV' OR 
           gl_add_dff_data_rec_1.payment_id = 'INV_TAX' THEN
          -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
          get_add_dff_lines_data_1(
            gl_add_dff_data_rec_1.distribution_line_number, --���������הԍ�/�x��ID(IN)
            lv_line_attribute1_1,                           -- �������R(OUT)
            lv_line_attribute2_1,                           -- �����Q��(OUT)
            lv_line_customer_trx_line_id_1,                 -- ����������ID(OUT)
            lv_line_attribute9_1,                           -- �\���P(OUT)
            lv_line_attribute10_1,                          -- �\���Q(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --���ʃG���[����
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --���[�U�[�G���[����
                RAISE warning_status_expt;
              END IF;
            END IF;
        -- ====================================================
        -- ���������׉�v���擾�����Q [Sales Invoices](A2-3)
        -- ====================================================
            get_ra_cus_trx_lines_all_1(
              lv_line_customer_trx_line_id_1, -- ����������ID(IN)
              lv_vat_tax_id,                  -- ��ID(OUT)
              lv_descripion,                  -- ���דE�v(OUT)
              lv_errbuf,                      -- �G���[�E���b�Z�[�W          --# �Œ� #
              lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                  --���ʃG���[����
                  RAISE global_process_expt;
                ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                  --���[�U�[�G���[����
                  RAISE warning_status_expt;
                END IF;
              END IF;
             --���דE�v���ڂ֒��߃Z�b�g����
             IF gl_add_dff_data_rec_1.payment_id <> 'INV_REV' THEN  -- 'INV_REV'�ȊO�̏ꍇ
                lv_descripion := gl_add_dff_data_rec_1.reference10; -- ���דE�v�Z�b�g�����l
             END IF;
        -- =================================================
        -- AR�Ńe�[�u�����擾���� [Sales Invoices](A2-4)
        -- =================================================
-- 2004/05/12 �f�[�^NOT FOUND ���̑Ή��i�f�[�^�Ή��j
             lv_avta_tax_code := lv_xx03_tax_code;
             IF lv_vat_tax_id IS NOT NULL THEN
               get_ar_vat_tax_all_1(
               lv_vat_tax_id,                 -- ��ID(IN)
               lv_avta_tax_code,              -- �ŃR�[�h(OUT)
               lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
               lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
               lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
               IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                 IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                   --���ʃG���[����
                   RAISE global_process_expt;
                 ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                   --���[�U�[�G���[����
                   RAISE warning_status_expt;
                 END IF;
               END IF;
             END IF;
        END IF;
      END IF;
        -- ===================================
        -- �d��f�[�^�̍X�V���� (A8)
        -- ===================================
        -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
        upd_journal_data(
          gl_add_dff_data_rec_1.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.�d��\�[�X��(IN)
          gl_add_dff_data_rec_1.user_je_category_name, -- 3.�d��(IN)
          lv_group_id,                                 -- 4.�O���[�vID(IN)
          lv_context_name,                             -- 5.��v���떼(IN)
          gl_add_dff_data_rec_1.trx_number,            -- 6.�`�[�ԍ�(IN)
          gl_add_dff_data_rec_1.doc_sequence_value,    -- 7.�����������ԍ�(IN)
          gl_add_dff_data_rec_1.rcta_attribut5,        -- 8.�N�[����(IN)
          gl_add_dff_data_rec_1.rcta_attribut6,        -- 9.���͎�(IN)
          lv_avta_tax_code,                            -- 10.�ŃR�[�h(IN)
          lv_line_attribute1_1,                        -- 11.�������R(IN)
          lv_line_attribute2_1,                        -- 12.�����Q��(IN)
          lv_descripion,                               -- 13.���דE�v(IN)
          gl_add_dff_data_rec_1.attribute6,            -- 14.�C�����`�[�ԍ�(IN)
          lv_line_attribute9_1,                        -- 15.�\���P(IN)
          lv_line_attribute10_1,                       -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_1.rctlda_attribute11,    -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --���ʃG���[����
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --���[�U�[�G���[����
            RAISE warning_status_expt;
          END IF;
        END IF;
        ln_sales_invoices_cnt := ln_sales_invoices_cnt + 1; -- �d��������DFF���������̌v��
--
    END LOOP interface_loop;
    --���O�o��
    CLOSE gl_add_dff_data_cur_1;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_1;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_2
   * Description      : DFF�t���Ώۃf�[�^���o���� [Credit Memo] (A3)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_2(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_credit_memos         IN VARCHAR2,     -- 3.�d��J�e�S����(�N���W�b�g����)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    ln_credit_memos_cnt     IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(�N���W�b�g����)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_2'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE; -- �R���e�L�X�g�l
    lv_A3_flg  VARCHAR2(1);                          -- ����t���O
    lv_trx_number         VARCHAR2(20);              -- �������ԍ�
    lv_line_attribute1_2  VARCHAR2(150);             -- �������R
    lv_line_attribute2_2  VARCHAR2(150);             -- �����Q��
    lv_vat_tax_id_2       NUMBER(15);                -- ��ID
    lv_descripion_2       VARCHAR2(240);             -- ���דE�v
    lv_line_customer_trx_line_id_2 NUMBER(15);       -- ����������ID
    lv_avta_tax_code_2    VARCHAR2(50);              -- �ŃR�[�h
    lv_vat_tax_id         NUMBER(15);                -- ��ID2
-- 20050131 V1.5 START
    lv_line_attribute9_2  VARCHAR2(150);   -- �\���P
    lv_line_attribute10_2 VARCHAR2(150);   -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    CURSOR gl_add_dff_data_cur_2
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- �d��J�e�S��-�d��J�e�S��
              gi.reference22 AS invoice_id,                      -- ������ID
-- 20050307 V1.6 START
              rctla.customer_trx_line_id AS customer_trx_line_id,-- ����������ID
-- 20050307 V1.6 END
              gi.reference23 AS distribution_line_number,        -- �������z��ID
              gi.reference29 AS payment_id,                      -- ���׎d��^�C�v
              gi.group_id AS group_id ,                          -- �p�����[�^�O���[�vID
              gi.context AS context ,                            -- ��v���떼
              gi.reference4 AS reference4,                       -- ���o�ςf�k�d��P��
              gi.reference10 AS reference10,                     -- ���o�ϖ��׊T�v
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- ���o�Ϗ����Q��
              gi.attribute1 AS attribute1,                       -- ���o�ϐŋ敪
              gi.attribute2 AS attribute2,                       -- ���o�ϑ������R
              gi.attribute3 AS attribute3,                       -- ���o�ϓ`�[�ԍ�
              gi.attribute4 AS attribute4,                       -- ���o�ϋN�[����
              gi.attribute5 AS attribute5,                       -- ���o�ϓ��͎�
              gi.attribute6 AS attribute6,                       -- ���o�ϏC�����`�[�ԍ�
              rcta.trx_number AS trx_number,                     -- �������ԍ�
              rcta.doc_sequence_value AS doc_sequence_value,     -- �����������ԍ�
              rcta.attribute5 AS rcta_attribut5,                 -- �N�[����
              rcta.attribute6 AS rcta_attribut6,                 -- ���͎�
              rcta.previous_customer_trx_id AS previous_customer_trx_id, --�e�������h�c
-- 20050307 V1.6 START
              rctla.previous_customer_trx_line_id AS previous_customer_trx_line_id, --�e����������ID
-- 20050307 V1.6 END
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- �������^�C�v�h�c
              rcta.comments AS comments                          -- ����
-- ver 11.5.10.2.4 Add Start
             ,rctlda_p.attribute11 AS rctlda_attribute11         -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                                   -- GL�C���^�[�t�F�[�X�e�[�u��
              ra_customer_trx_all rcta,                          -- �������w�b�_�e�[�u��
-- 20050307 V1.6 START
              ra_customer_trx_lines_all rctla,                   -- ���������׃e�[�u��
              ra_cust_trx_line_gl_dist_all rctlda                -- ����������GL�z���e�[�u��
-- 20050307 V1.6 END
-- ver 11.5.10.2.4 Add Start
             ,(SELECT rcta2.customer_trx_id     AS customer_trx_id
                     ,MAX(rctlda2.attribute11)  AS attribute11
               FROM   ra_customer_trx_all          rcta2        -- �������w�b�_�e�[�u��(�e)
                     ,ra_cust_trx_line_gl_dist_all rctlda2      -- ����������GL�z���e�[�u��(�e)
               WHERE  rcta2.customer_trx_id = rctlda2.customer_trx_id
               GROUP BY rcta2.customer_trx_id
              ) rctlda_p
-- ver 11.5.10.2.4 Add End
      WHERE   gi.user_je_source_name =  lv_journal_source        -- �d��\�[�X��
      AND     gi.user_je_category_name = lv_credit_memos         -- �d��J�e�S����(�N���W�b�g����)
      AND     rcta.customer_trx_id = gi.reference22
      AND     gi.status ='NEW'     
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('CM_REC','CM_REV','CM_TAX'))
-- 20050307 V1.6 START
      AND     rctlda.cust_trx_line_gl_dist_id = gi.reference23
      AND     rctla.customer_trx_line_id(+) = rctlda.customer_trx_line_id
-- 20050307 V1.6 END
-- ver 11.5.10.2.4 Add Start
      AND     rcta.previous_customer_trx_id = rctlda_p.customer_trx_id(+)
-- ver 11.5.10.2.4 Add End
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_2 gl_add_dff_data_cur_2%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_1');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_credit_memos);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_2;
    <<interface_loop_2>>
    LOOP
      FETCH gl_add_dff_data_cur_2 INTO gl_add_dff_data_rec_2;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_2%NOTFOUND THEN
          EXIT interface_loop_2;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_2.user_je_category_name);

      lv_A3_flg := '0';                                   -- �O������������菉���l
-- 20050131 V1.5 START
      lv_line_attribute9_2 := '';                         -- �\���P�����l
      lv_line_attribute10_2 := '';                        -- �\���Q�����l
-- 20050131 V1.5 END
      -- ==========================================================
      -- �����ϐ������ԍ��̎擾���� [Credit Memo](A3-1)
      -- ==========================================================
      IF gl_add_dff_data_rec_2.previous_customer_trx_id IS  NULL THEN
        lv_trx_number := gl_add_dff_data_rec_2.previous_customer_trx_id;
      ELSE
        get_trx_number(
            gl_add_dff_data_rec_2.previous_customer_trx_id,   -- �e�������h�c(IN)
            lv_trx_number,                 -- �e�������ԍ�(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --���ʃG���[����
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --���[�U�[�G���[����
            RAISE warning_status_expt;
          END IF;
        END IF;
      END IF;
      lv_A3_flg := '1';                                   -- ���肠��
    -- ====================================================
    -- ���������׉�v���擾�����P [Credit Memo](A3-2)
    -- ====================================================
      IF gl_add_dff_data_rec_2.payment_id = 'CM_REV' OR 
         gl_add_dff_data_rec_2.payment_id = 'CM_TAX' THEN
-- 20050307 V1.6 START
--Ver11.5.10.1.3 2005/05/17 Modify START
      --�e������ID��NULL�̏ꍇ�̓v���V�[�W�����Ă΂��Ɋe�ϐ���null��}��
        IF gl_add_dff_data_rec_2.previous_customer_trx_line_id IS NOT NULL THEN
--Ver11.5.10.1.3 2005/05/17 Modify END
          get_cust_trx_line_gl_dist_dff(
            gl_add_dff_data_rec_2.previous_customer_trx_line_id, -- �Q�Ɛ搿��������ID(IN)
            lv_line_attribute1_2,                           -- �������R(OUT)
            lv_line_attribute2_2,                           -- �����Q��(OUT)
            lv_line_attribute9_2,                           -- �\���P(OUT)
            lv_line_attribute10_2,                          -- �\���Q(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        get_add_dff_lines_data_2(
--          gl_add_dff_data_rec_2.distribution_line_number, -- �������z��ID(IN)
--          lv_line_attribute1_2,                           -- �������R(OUT)
--          lv_line_attribute2_2,                           -- �����Q��(OUT)
--          lv_line_customer_trx_line_id_2,                 -- ����������ID(OUT)
--          lv_line_attribute9_2,                           -- �\���P(OUT)
--          lv_line_attribute10_2,                          -- �\���Q(OUT)
--          lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
--          lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
--          lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- 20050307 V1.6 END
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
--Ver11.5.10.1.3 2005/05/17 Add START
        ELSE
          lv_line_attribute1_2  := NULL;                          -- �������R(OUT)
          lv_line_attribute2_2  := NULL;                          -- �����Q��(OUT)
          lv_line_attribute9_2  := NULL;                          -- �\���P(OUT)
          lv_line_attribute10_2 := NULL;                          -- �\���Q(OUT)
        END IF;
--Ver11.5.10.1.3 2005/05/17 Add END
        -- ====================================================
        -- ���������׉�v���擾�����Q [Credit Memo](A3-3)
        -- ====================================================
        get_ra_cus_trx_lines_all_2(
-- 20050307 V1.6 START
          gl_add_dff_data_rec_2.customer_trx_line_id, -- ����������ID(IN)
--          lv_line_customer_trx_line_id_2, -- ����������ID(IN)
-- 20050307 V1.6 END
          lv_vat_tax_id_2,                -- ��ID(OUT)
          lv_descripion_2,                -- ���דE�v(OUT)
          lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
          --���דE�v���ڂ֏����l�Z�b�g����
          IF gl_add_dff_data_rec_2.payment_id <> 'CM_REV' THEN
            lv_descripion_2 := gl_add_dff_data_rec_2.reference10; -- ���דE�v�Z�b�g�����l
          END IF;
        -- =================================================
        -- AR�Ńe�[�u�����擾���� [Credit Memo](A3-4)
        -- =================================================
-- 2004/05/12 �f�[�^NOT FOUND ���̑Ή��i�f�[�^�Ή��j
          lv_avta_tax_code_2 := lv_xx03_tax_code;
          IF lv_vat_tax_id_2 IS NOT NULL THEN
           get_ar_vat_tax_all_2(
             lv_vat_tax_id_2,               -- ��ID(IN)
             lv_avta_tax_code_2,            -- �ŃR�[�h(OUT)
             lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
             lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
             lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
             IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
               IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                 --���ʃG���[����
                 RAISE global_process_expt;
               ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                 --���[�U�[�G���[����
                 RAISE warning_status_expt;
               END IF;
             END IF;
          END IF;
      ELSE
          --'CM_REC' �̏ꍇ
          lv_avta_tax_code_2   := gl_add_dff_data_rec_2.attribute1;     -- �ŃR�[�h
          lv_line_attribute1_2 := gl_add_dff_data_rec_2.attribute2;     -- �������R
          lv_line_attribute2_2 := gl_add_dff_data_rec_2.jgzz_recon_ref; -- �����Q��
          lv_descripion_2      := gl_add_dff_data_rec_2.reference10;    -- ���דE�v
      END IF;
        -- ===================================
        -- �d��f�[�^�̍X�V���� (A8)
        -- ===================================
          -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
          upd_journal_data(
          gl_add_dff_data_rec_2.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.�d��\�[�X��(IN)
          gl_add_dff_data_rec_2.user_je_category_name, -- 3.�d��(IN)
          lv_group_id,                                 -- 4.�O���[�vID(IN)
          lv_context_name,                             -- 5.��v���떼(IN)
          gl_add_dff_data_rec_2.trx_number,            -- 6.�`�[�ԍ�(IN)
          gl_add_dff_data_rec_2.doc_sequence_value,    -- 7.�����������ԍ�(IN)
          gl_add_dff_data_rec_2.rcta_attribut5,        -- 8.�N�[����(IN)
          gl_add_dff_data_rec_2.rcta_attribut6,        -- 9.���͎�(IN)
          lv_avta_tax_code_2,                          -- 10.�ŃR�[�h(IN)
          lv_line_attribute1_2,                        -- 11.�������R(IN)
          lv_line_attribute2_2,                        -- 12.�����Q��(IN)
          lv_descripion_2,                             -- 13.���דE�v(IN)
          lv_trx_number,                               -- 14.�Q�ƌ��`�[�ԍ�(IN)
          lv_line_attribute9_2,                        -- 15.�\���P(IN)
          lv_line_attribute10_2,                       -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_2.rctlda_attribute11,    -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
          ln_credit_memos_cnt := ln_credit_memos_cnt + 1; -- �J�e�S���ʌ���(�N���W�b�g����)�v��
--
    END LOOP interface_loop_2;
    --���O�o��
    CLOSE gl_add_dff_data_cur_2;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_2;
--
--##############################################################################################
------------------------------------------- A4 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_3
   * Description      : DFF�t���Ώۃf�[�^���o���� [CM Applications] (A4)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_3(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_credit_memo_applications IN VARCHAR2, -- 3.�d��J�e�S����(�N���W�b�g�������)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    ln_credit_memo_app_cnt  IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(�N���W�b�g�������)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_3'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;   -- �R���e�L�X�g�l
    lv_A4_flg  VARCHAR2(1);                       -- ����t���O
-- 20050131 V1.5 START
    lv_line_attribute9_3   VARCHAR2(150);   -- �\���P
    lv_line_attribute10_3  VARCHAR2(150);   -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    CURSOR gl_add_dff_data_cur_3
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- �d��J�e�S��-�d��J�e�S��
              gi.reference22 AS invoice_id,                      -- ������ID
              gi.reference23 AS distribution_line_number,        -- ���������הԍ�/�x��ID
              gi.reference24 AS reference24,                     -- �`�[�ԍ�
              gi.reference29 AS payment_id,                      -- ���׎d��^�C�v
              gi.group_id AS group_id ,                          -- �p�����[�^�O���[�vID
              gi.context AS context ,                            -- ��v���떼
              gi.reference4 AS reference4,                       -- ���o�ςf�k�d��P��
              gi.reference10 AS reference10,                     -- ���o�ϖ��׊T�v
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- ���o�Ϗ����Q��
              gi.attribute1 AS attribute1,                       -- ���o�ϐŋ敪
              gi.attribute2 AS attribute2,                       -- ���o�ϑ������R
              gi.attribute3 AS attribute3,                       -- ���o�ϓ`�[�ԍ�
              gi.attribute4 AS attribute4,                       -- ���o�ϋN�[����
              gi.attribute5 AS attribute5,                       -- ���o�ϓ��͎�
              gi.attribute6 AS attribute6,                       -- ���o�ϏC�����`�[�ԍ�
              rcta.trx_number AS trx_number,                     -- �������ԍ�
              rcta.doc_sequence_value AS doc_sequence_value,     -- �����������ԍ�
              rcta.attribute5 AS rcta_attribut5,                 -- �N�[����
              rcta.attribute6 AS rcta_attribut6,                 -- ���͎�
              rcta.previous_customer_trx_id AS previous_customer_trx_id, -- �e�������h�c
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- �������^�C�v�h�c
              rcta.comments AS comments                          -- ����
-- ver 11.5.10.2.4 Add Start
             ,gi.attribute15 AS attribute15                      -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GL�C���^�[�t�F�[�X�e�[�u��
              ra_customer_trx_all rcta                           -- �������w�b�_�e�[�u��
      WHERE   gi.user_je_source_name =  lv_journal_source        -- �d��\�[�X��
      AND     gi.user_je_category_name = lv_credit_memo_applications -- �d��J�e�S����(�b�l���)
      AND     rcta.trx_number = gi.reference24              
      AND     gi.status ='NEW'                                       
      AND     gi.actual_flag = 'A'                                   
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      -- ver 11.5.10.2.3 Add Start
      AND     rcta.set_of_books_id = in_gl_book_id
      -- ver 11.5.10.2.3 Add End
      AND     (gi.reference29 in ('CMAPP_REC','CMAPP_APP'))
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_3 gl_add_dff_data_cur_3%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_3');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_credit_memo_applications);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_3;
    <<interface_loop_3>>
    LOOP
      FETCH gl_add_dff_data_cur_3 INTO gl_add_dff_data_rec_3;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_3%NOTFOUND THEN
          EXIT interface_loop_3;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_3.user_je_category_name);

      lv_A4_flg := '0';                                   -- �O������������菉���l
-- 20050131 V1.5 START
      lv_line_attribute9_3 := '';                         -- �\���P�����l
      lv_line_attribute10_3 := '';                        -- �\���Q�����l
-- 20050131 V1.5 END
      -- ===================================
      -- �d��f�[�^�̍X�V���� (A8)
      -- ===================================
      -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
      upd_journal_data(
          gl_add_dff_data_rec_3.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.�d��\�[�X��(IN)
          gl_add_dff_data_rec_3.user_je_category_name, -- 3.�d��(IN)
          lv_group_id,                                 -- 4.�O���[�vID(IN)
          lv_context_name,                             -- 5.��v���떼(IN)
          gl_add_dff_data_rec_3.trx_number,            -- 6.�`�[�ԍ�(IN)
          gl_add_dff_data_rec_3.doc_sequence_value,    -- 7.�C�����`�[�ԍ�(IN)
          gl_add_dff_data_rec_3.rcta_attribut5,        -- 8.�N�[����(IN)
          gl_add_dff_data_rec_3.rcta_attribut6,        -- 9.���͎�(IN)
          gl_add_dff_data_rec_3.attribute1,            -- 10.�ŃR�[�h(IN)
          gl_add_dff_data_rec_3.attribute2,            -- 11.�������R(IN)
          gl_add_dff_data_rec_3.jgzz_recon_ref,        -- 12.�����Q��(IN)
          gl_add_dff_data_rec_3.reference10,           -- 13.���דE�v(IN)
          gl_add_dff_data_rec_3.attribute6,            -- 14.�C�����`�[�ԍ�(IN)
          lv_line_attribute9_3,                        -- 15.�\���P(IN)
          lv_line_attribute10_3,                       -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_3.attribute15,           -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���ʃG���[����
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���[�U�[�G���[����
          RAISE warning_status_expt;
        END IF;
      END IF;
      ln_credit_memo_app_cnt := ln_credit_memo_app_cnt + 1; -- �J�e�S���ʌ���(CM���)�v��
--
    END LOOP interface_loop_3;
    --���O�o��
    CLOSE gl_add_dff_data_cur_3;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_3;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_4
   * Description      : DFF�t���Ώۃf�[�^���o���� [adjustment] (A5)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_4(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_adjustment           IN VARCHAR2,     -- 3.�d��J�e�S����(�C��)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    ln_adjustment_cnt       IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(�C��)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_4'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;  -- �R���e�L�X�g�l
    lv_A5_flg      VARCHAR2(1);                       -- ����t���O
    lv_trx_number  VARCHAR2(20);                      -- �O�������������
    lv_attribute5  VARCHAR2(150);                     -- �N�[����(OUT)
    lv_attribute6  VARCHAR2(150);                     -- ���͎�(OUT)
    lv_initial_customer_trx_id   NUMBER(15);          -- ������(OUT)
    lv_cust_trx_type_id   NUMBER(15);                 -- �O�������������
    lv_type        VARCHAR2(20);                      -- �^�C�v(OUT)
    lv_tax_code    VARCHAR2(50);                      -- �ŃR�[�h(OUT)
    lv_flg_1       VARCHAR2(1) := '0';                -- ����FLG_1
    lv_flg_2       VARCHAR2(1) := '0';                -- ����FLG_2
    lv_flg_3       VARCHAR2(1) := '0';                -- ����FLG_3

    lv_out_tax_code    VARCHAR2(50);                  -- �ŃR�[�h
    lv_out_attribute1  VARCHAR2(150);                 -- �������R
    lv_out_attribute5  VARCHAR2(150);                 -- �N�[����
    lv_out_attribute6  VARCHAR2(150);                 -- ���͎�
    lv_out_attribute2  VARCHAR2(150);                 -- �����Q��
    lv_out_comments    VARCHAR2(150);                 -- ���דE�v
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                 -- �\���P
    lv_out_attribute10 VARCHAR2(150);                 -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    -- 20050131 V1.5 �d��C���i�\���P�E�\���Q�j�̒ǉ�
    --               �d��C���i�����Q�Ɓj�̕ύX�iattribute6 �� attribute2�j
    CURSOR gl_add_dff_data_cur_4
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- �d��J�e�S��
              gi.reference22 AS invoice_id,                      -- ������ID
              gi.reference23 AS distribution_line_number,        -- ���������הԍ�/�x��ID
              gi.reference29 AS payment_id,                      -- ���׎d��^�C�v
              gi.group_id AS group_id,                           -- �p�����[�^�O���[�vID
              gi.context AS context,                             -- ��v���떼
              gi.reference4 AS reference4,                       -- ���o�ςf�k�d��P��
              gi.reference10 AS reference10,                     -- ���o�ϖ��׊T�v
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- ���o�Ϗ����Q��
              gi.attribute1 AS attribute1,                       -- ���o�ϐŋ敪
              gi.attribute2 AS attribute2,                       -- ���o�ϑ������R
              gi.attribute3 AS attribute3,                       -- ���o�ϓ`�[�ԍ�
              gi.attribute4 AS attribute4,                       -- ���o�ϋN�[����
              gi.attribute5 AS attribute5,                       -- ���o�ϓ��͎�
              gi.attribute6 AS attribute6,                       -- ���o�ϏC�����`�[�ԍ�
              aaa.customer_trx_id AS customer_trx_id,            -- �������w�b�_�h�c
              aaa.comments AS comments,                          -- ����
              aaa.doc_sequence_value AS doc_sequence_value,      -- �����������ԍ�
              aaa.attribute5 AS aaa_attribute1,                  -- �������R
              aaa.attribute2 AS aaa_attribute2,                  -- �����Q��
              gi.code_combination_id AS code_combination_id,     -- AFF�g����ID
              aaa.adjustment_type AS adjustment_type,            -- �C���^�C�v
              aaa.attribute9 AS attribute9,                      -- �\���P
              aaa.attribute10 AS attribute10                     -- �\���Q
-- ver 11.5.10.2.4 Add Start
             ,gi.attribute15 AS attribute15                      -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GL�C���^�[�t�F�[�X�e�[�u��
              ar_adjustments_all aaa                             -- �d��C���e�[�u��
      WHERE   gi.user_je_source_name   = lv_journal_source
      AND     gi.user_je_category_name = lv_Adjustment
      AND     aaa.adjustment_id        = gi.reference22 
      AND     gi.status ='NEW'
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('ADJ_REC','ADJ_ADJ','ADJ_TAX','ADJ_ADJ_NON_REC_TAX'))
      ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_4 gl_add_dff_data_cur_4%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_4');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_Adjustment);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_4;
    <<interface_loop_4>>
    LOOP
      FETCH gl_add_dff_data_cur_4 INTO gl_add_dff_data_rec_4;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_4%NOTFOUND THEN
          EXIT interface_loop_4;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_4.user_je_category_name);
      -- =================================================
      --�����l�̕ҏW
      -- =================================================
        lv_out_tax_code   := gl_add_dff_data_rec_4.attribute1;     -- �ŃR�[�h
        lv_out_attribute1 := gl_add_dff_data_rec_4.attribute2;     -- �������R
        lv_out_attribute5 := gl_add_dff_data_rec_4.attribute4;     -- �N�[����
        lv_out_attribute6 := gl_add_dff_data_rec_4.attribute5;     -- ���͎�
        lv_out_attribute2 := gl_add_dff_data_rec_4.jgzz_recon_ref; -- �����Q��
        lv_out_comments   := gl_add_dff_data_rec_4.reference10;    -- ���דE�v
-- 20050131 V1.5 START
        lv_out_attribute9  := '';                                  -- �\���P
        lv_out_attribute10 := '';                                  -- �\���Q
-- 20050131 V1.5 END
      -- ==========================================================
      -- �O������������肨��ђ��ߎ擾����_1 [adjustment](5-1)
      -- ==========================================================
      get_ra_customer_rx_all_1(
          gl_add_dff_data_rec_4.customer_trx_id,    -- �������^�C�v�h�c(IN)
          lv_trx_number,                            -- �������ԍ�(OUT)
          lv_attribute5,                            -- �N�[����(OUT)
          lv_attribute6,                            -- ���͎�(OUT)
          lv_initial_customer_trx_id,               -- ������(OUT)
          lv_errbuf,                                -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                               -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���ʃG���[����
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���[�U�[�G���[����
          RAISE warning_status_expt;
        END IF;
      END IF;
-- 20050131 V1.5 START
      lv_out_attribute5 := lv_attribute5;     -- �N�[����
      lv_out_attribute6 := lv_attribute6;     -- ���͎�
-- 20050131 V1.5 END
    -- =========================================================
    -- �O������������肨��ђ��ߎ擾����_2  [adjustment](A5-2)
    -- =========================================================
      get_ra_customer_rx_all_2(
        lv_initial_customer_trx_id,   -- ������ID(IN)
        lv_cust_trx_type_id,          -- �������^�C�v�h�c(OUT)
        lv_flg_1,                     -- �O�������������(OUT)
        lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --���ʃG���[����
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --���[�U�[�G���[����
            RAISE warning_status_expt;
          END IF;
        END IF;
        -- =========================================================
        -- �O������������肨��ђ��ߎ擾����_3 [adjustment](A5-3)
        -- =========================================================
        IF lv_flg_1 = '0' THEN 
          get_trx_type_2(
            lv_cust_trx_type_id,           -- �������^�C�v�h�c(IN)
            lv_type,                       -- �^�C�v(OUT)
            lv_flg_2,                      -- �O�������������(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --���[�U�[�G���[����
                RAISE warning_status_expt;
              END IF;
            END IF;
            -- ���� �^�C�v�i�c�d�o�j���菈��
            IF lv_type = 'DEP' THEN
              lv_flg_3 := '1';                         -- �O����[��������
            END IF;
        END IF;
        -- =================================================
        -- AR�Ńe�[�u�����擾���� [adjustment](A5-4)
        -- =================================================
        -- ���׎d��^�C�v�̔��f
        -- 20040512 IF�����őΏۂ�S�ĂƂ���ɏC��
--        IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' OR 
--           gl_add_dff_data_rec_4.payment_id = 'ADJ_TAX' THEN
        -- 20050131 V1.5 �p�����[�^�̕ύX
        --                 �iAFF�g����ID�ilv_code_combination_id�j
        --                                                      �� ������ID�iinvoice_id�j�j
        --                �y��
        --               �p�����[�^�̒ǉ��i���׎d��^�C�v�ipayment_id�j�j
          get_ar_vat_tax_all_3(
            gl_add_dff_data_rec_4.invoice_id,           --  ������ID(IN)
            gl_add_dff_data_rec_4.payment_id,           --  ���׎d��^�C�v(IN)
            lv_xx03_tax_code,              -- XX03_TAX_CODES(NAME)(IN)
            lv_tax_code,                   -- �ŃR�[�h(OUT)
            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --���ʃG���[����
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --���[�U�[�G���[����
                RAISE warning_status_expt;
              END IF;
            END IF;
--        END IF;
        --�O����[���������łȂ��ꍇ�̕ҏW
-- 20050131 V1.5 START
--          IF lv_flg_1 = '1' OR lv_flg_2 = '1' THEN
          IF lv_flg_1 = '1' OR lv_flg_2 = '1' OR
              gl_add_dff_data_rec_4.adjustment_type <> cv_adjustment_type_c THEN
-- 20050131 V1.5 END
            IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' OR 
               gl_add_dff_data_rec_4.payment_id = 'ADJ_TAX' OR 
               gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ_NON_REC_TAX' THEN
                 lv_out_tax_code   := lv_tax_code;     -- �ŃR�[�h
                 lv_out_attribute1 := gl_add_dff_data_rec_4.aaa_attribute1; -- �������R
                 lv_out_attribute2 := gl_add_dff_data_rec_4.aaa_attribute2; -- �����Q��
                 IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' THEN 
                   lv_out_comments   := gl_add_dff_data_rec_4.comments;     -- ���דE�v
-- 20050131 V1.5 START
                   lv_out_attribute9 := gl_add_dff_data_rec_4.attribute9;   -- �\���P
                   lv_out_attribute10 := gl_add_dff_data_rec_4.attribute10; -- �\���Q
-- 20050131 V1.5 END
                 END IF;
             END IF;
          ELSE --�O����[���������̏ꍇ�̕ҏW
-- 20050131 V1.5 START
--            lv_out_attribute5 := lv_attribute5;     -- �N�[����
--            lv_out_attribute6 := lv_attribute6;     -- ���͎�
-- 20050131 V1.5 END
            IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' THEN 
              lv_out_tax_code   := lv_tax_code;     -- �ŃR�[�h
            END IF;
          END IF;
        -- ===================================
        -- �d��f�[�^�̍X�V���� (A8)
        -- ===================================
          -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
          upd_journal_data(
          gl_add_dff_data_rec_4.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.�d��\�[�X��(IN)
          gl_add_dff_data_rec_4.user_je_category_name, -- 3.�d��(IN)
          lv_group_id,                                 -- 4.�O���[�vID(IN)
          lv_context_name,                             -- 5.��v���떼(IN)
          lv_trx_number,                               -- 6.�`�[�ԍ�(IN)
          gl_add_dff_data_rec_4.doc_sequence_value,    -- 7.�C�����`�[�ԍ�(IN)
          lv_out_attribute5,                           -- 8.�N�[����(IN)
          lv_out_attribute6,                           -- 9.���͎�(IN)
          lv_out_tax_code,                             -- 10.�ŃR�[�h(IN)
          lv_out_attribute1,                           -- 11.�������R(IN)
          lv_out_attribute2,                           -- 12.�����Q��(IN)
          lv_out_comments,                             -- 13.���דE�v(IN)
          gl_add_dff_data_rec_4.attribute6,            -- 14.�C�����`�[�ԍ�(IN)
          lv_out_attribute9,                           -- 15.�\���P(IN)
          lv_out_attribute10,                          -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_4.attribute15,           -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
          ln_adjustment_cnt := ln_adjustment_cnt + 1; -- �J�e�S���ʌ���(�N���W�b�g����)�v��
--
    END LOOP interface_loop_4;
    --���O�o��
    CLOSE gl_add_dff_data_cur_4;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_4;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_5
   * Description      : DFF�t���Ώۃf�[�^���o���� [Trade Receipts] (A6)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_5(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_trade_receipts       IN VARCHAR2,     -- 3.�d��J�e�S����(���|�^����������)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    ln_trade_receipts_cnt   IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(���|�^����������)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_5'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;   -- �R���e�L�X�g�l
    lv_A6_flg              VARCHAR2(1);                -- ����t���O
    lv_trx_number          VARCHAR2(20);               -- �O�������������
    lv_pay_from_customer   NUMBER(15);                 -- �x���ڋq
    lv_hca_account_number  VARCHAR2(30);               -- �ڋq�ԍ�(OUT)
    lv_hca_party_id        NUMBER(15);                 -- �p�[�e�BID(OUT)
    lv_hca_attribute2      VARCHAR2(150);              -- �ꌩ�ڋq�敪(OUT)
    lv_acra_attribute1     VARCHAR2(150);              -- �U���˗��l��(OUT)
    lv_hp_party_name       VARCHAR2(360);              -- �p�[�e�B��(OUT)
    lv_acrha_status        VARCHAR2(30);               -- �X�e�[�^�X(OUT)
    lv_acra_doc_sequence_value  NUMBER(15);            -- ���������ԍ�(OUT)
    lv_invoice_id         VARCHAR2(240);               -- ������ID(OUT)
    lv_out_tax_code    VARCHAR2(50);                   -- �ŃR�[�h
    lv_out_attribute1  VARCHAR2(150);                  -- �������R
    lv_out_attribute5  VARCHAR2(150);                  -- �N�[����
    lv_out_attribute6  VARCHAR2(150);                  -- ���͎�
    lv_out_attribute2  VARCHAR2(150);                  -- �����Q��
    lv_out_comments    VARCHAR2(150);                  -- ���דE�v
    lv_out_attribute7  VARCHAR2(150);                  -- �C�����`�[�ԍ�
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                  -- �\���P
    lv_out_attribute10 VARCHAR2(150);                  -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 V1.3 �����ǉ��F'TRADE_ACC'
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    CURSOR gl_add_dff_data_cur_5
    IS
    SELECT  gi.rowid AS row_id,                                 -- ROWID
            gi.user_je_category_name AS user_je_category_name,  -- �d��J�e�S��
            gi.reference22 AS invoice_id,                       -- ������ID
            gi.reference23 AS distribution_line_number,         -- ���������הԍ�/�x��ID
            gi.reference29 AS payment_id,                       -- ���׎d��^�C�v
            gi.group_id AS group_id,                            -- �p�����[�^�O���[�vID
            gi.context AS context,                              -- ��v���떼
            gi.reference4 AS reference4,                        -- ���o�ςf�k�d��P��
            gi.reference10 AS reference10,                      -- ���o�ϖ��׊T�v
            gi.jgzz_recon_ref AS jgzz_recon_ref,                -- ���o�Ϗ����Q��
            gi.attribute1 AS attribute1,                        -- ���o�ϐŋ敪
            gi.attribute2 AS attribute2,                        -- ���o�ϑ������R
            gi.attribute3 AS attribute3,                        -- ���o�ϓ`�[�ԍ�
            gi.attribute4 AS attribute4,                        -- ���o�ϋN�[����
            gi.attribute5 AS attribute5,                        -- ���o�ϓ��͎�
            gi.attribute6 AS attribute6,                        -- ���o�ϏC�����`�[�ԍ�
            gi.reference27 AS reference27,                      -- ������ڋq�h�c
            gi.reference25 AS reference25,                      -- �������ԍ�
            acra.doc_sequence_value AS doc_sequence_value,      -- ���������ԍ�
            acra.pay_from_customer AS pay_from_customer,        -- �x���ڋq
            acra.attribute1 AS acra_attribute1,                 -- �U���˗��l��
            acra.status AS acra_status                          -- �X�e�[�^�X
-- ver 11.5.10.2.4 Add Start
           ,gi.attribute15 AS attribute15                       -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
    FROM    gl_interface gi,                               -- GL�C���^�[�t�F�[�X�e�[�u��
            ar_cash_receipts_all acra                           -- �������e�[�u��
    WHERE   gi.user_je_source_name =  lv_journal_source
    AND     gi.user_je_category_name = lv_trade_receipts
    AND     acra.cash_receipt_id = substr(gi.reference22, 1,instr(gi.reference22,'C',1)-1)  
    AND     gi.status ='NEW'
    AND     gi.actual_flag = 'A'
    AND     gi.context IS NULL
    AND     gi.set_of_books_id = in_gl_book_id
-- 20050311 V1.7 Added 'TRADE_ACTIVITY'
-- 20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
    AND     (gi.reference29 in ('TRADE_CASH','TRADE_UNAPP','TRADE_ACC','TRADE_ACTIVITY','TRADE_UNID',
             'TRADE_REC','TRADE_EXCH_GAIN','TRADE_EXCH_LOSS','TRADE_BANK_CHARGES','TRADE_CONFIRMATION',
             'TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'))
-- 20050714 V11.5.10.1.4 End
-- 20050311 V1.7 End
    ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_5 gl_add_dff_data_cur_5%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_5');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_trade_receipts);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_5;
    <<interface_loop_5>>
    LOOP
      FETCH gl_add_dff_data_cur_5 INTO gl_add_dff_data_rec_5;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_5%NOTFOUND THEN
          EXIT interface_loop_5;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_5.user_je_category_name);
      lv_acra_attribute1 := gl_add_dff_data_rec_5.acra_attribute1; --�U���˗��l��
      lv_A6_flg := '0';                                  -- �O������������菉���l
      lv_hca_attribute2 := '';                           -- NULL
-- 20050131 V1.5 START
      lv_out_attribute9 := '';                           -- �\���P�����l
      lv_out_attribute10 := '';                          -- �\���Q�����l
-- 20050131 V1.5 END
    -- =================================================
    --�����l�̕ҏW
    -- =================================================
      lv_out_tax_code   := gl_add_dff_data_rec_5.attribute1;     -- �ŃR�[�h
      lv_out_attribute1 := gl_add_dff_data_rec_5.attribute2;     -- �������R
      lv_out_attribute5 := gl_add_dff_data_rec_5.attribute4;     -- �N�[����
      lv_out_attribute6 := gl_add_dff_data_rec_5.attribute5;     -- ���͎�
      lv_out_attribute2 := gl_add_dff_data_rec_5.jgzz_recon_ref; -- �����Q��
      lv_out_comments   := gl_add_dff_data_rec_5.reference10;    -- ���דE�v
      lv_out_attribute7 := gl_add_dff_data_rec_5.attribute6;     -- �C�����`�[�ԍ�

  -- ==========================================================
  -- �ڋq�w�b�_�[�e�[�u�����ݒ�l�擾���� [Trade Receipts] (A6-1)
  -- ==========================================================
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V1. ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
      IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN
         IF gl_add_dff_data_rec_5.reference27 IS NOT NULL THEN
          get_ra_hz_cust_account(
            gl_add_dff_data_rec_5.pay_from_customer, --�x���ڋq(IN)
            lv_hca_account_number,                   -- �ڋq�ԍ�(OUT)
            lv_hca_party_id,                         --�p�[�e�BID(OUT)
            lv_hca_attribute2,                       --�ꌩ�ڋq�敪(OUT)
            lv_errbuf,                               -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                              -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --���ʃG���[����
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --���[�U�[�G���[����
              RAISE warning_status_expt;
            END IF;
          END IF;
    -- =========================================================
    -- �ꌩ�ڋq�o�Ȃ��ꍇ�A�p�[�e�B�e�[�u�����擾����  [Trade Receipts] (A6-2)
    -- =========================================================
          IF lv_hca_attribute2 = 'N' THEN
            get_hz_parties(
              lv_hca_party_id,               -- �p�[�e�BID(IN)
              lv_hp_party_name,              -- �p�[�e�B��(OUT)
              lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --���ʃG���[����
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --���[�U�[�G���[����
                RAISE warning_status_expt;
              END IF;
            END IF;
          END IF;
         END IF;
      END IF;
    -- =========================================================
    -- ���������ԍ��擾����1 [Trade Receipts] (A6-3)
    -- =========================================================
--  2004/04/20 �ۗ����� start
--  2004/05/19 �����ǉ� 'TRADE_ACC'
--  2004/05/25 �����ǉ� 'TRADE_BANK_CHARGES'
--        IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR 
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_UNAPP' OR
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_ACC' THEN
--         get_ar_cash_receipt_his_all_1(
--            gl_add_dff_data_rec_5.invoice_id,  --����ID(IN)
--            lv_acrha_status,               -- �X�e�[�^�X(OUT)
--            lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
--            lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
--            lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--              --���ʃG���[����
--              RAISE global_process_expt;
--            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--              --���[�U�[�G���[����
--              RAISE warning_status_expt;
--            END IF;
--          END IF;
    -- =========================================================
    -- ���������ԍ��擾����2 [Trade Receipts] (A6-4)
    -- =========================================================
--          IF lv_acrha_status = 'REVERSED' THEN 
--           get_ar_cash_receipts_all(
--              gl_add_dff_data_rec_5.invoice_id,  --����ID(IN)
--              lv_acra_doc_sequence_value,        -- ���������ԍ��߂�(OUT)
--              lv_errbuf,                         -- �G���[�E���b�Z�[�W           --# �Œ� #
--              lv_retcode,                        -- ���^�[���E�R�[�h             --# �Œ� #
--              lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--                --���ʃG���[����
--                RAISE global_process_expt;
--              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--                --���[�U�[�G���[����
--                RAISE warning_status_expt;
--              END IF;
--            END IF;
--          END IF;
--        END IF;
--  2004/04/20 �ۗ����� end
      --�����߂��̏ꍇ�ҏW
        IF gl_add_dff_data_rec_5.acra_status = 'REV' THEN 
--  2004/04/20 �ۗ����� start/end
--          lv_out_attribute7 := lv_acra_doc_sequence_value;     -- �C�����`�[�ԍ�
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
          IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR 
             gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN 
            IF lv_hca_attribute2 = 'N' THEN
               lv_out_comments := SUBSTRB(lv_hca_account_number||lv_hp_party_name,1,150);
            ELSE
--               lv_out_comments := gl_add_dff_data_rec_5.acra_attribute1; -- ���דE�v
               lv_out_comments := SUBSTRB(lv_hca_account_number||gl_add_dff_data_rec_5.acra_attribute1,1,150); -- ���דE�v
            END IF;
          END IF;
        ELSE
      --�����̏ꍇ�ҏW(�s�������͑ΏۊO)
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
          IF gl_add_dff_data_rec_5.reference27 IS NOT NULL THEN 
            IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR 
               gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN 
              IF lv_hca_attribute2 = 'N' THEN
                 lv_out_comments := SUBSTRB(lv_hca_account_number||lv_hp_party_name,1,150);
              ELSE
--                 lv_out_comments := gl_add_dff_data_rec_5.acra_attribute1; -- ���דE�v
                 lv_out_comments := SUBSTRB(lv_hca_account_number||gl_add_dff_data_rec_5.acra_attribute1,1,150); -- ���דE�v
              END IF;
            END IF;
          END IF;
        END IF;
      --�����������̏ꍇ�ҏW
        IF gl_add_dff_data_rec_5.payment_id = 'TRADE_REC' THEN 
           lv_out_comments := gl_add_dff_data_rec_5.reference25; -- ���דE�v
        END IF;
    -- ===================================
    -- �d��f�[�^�̍X�V���� (A8)
    -- ===================================
        -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
        upd_journal_data(
        gl_add_dff_data_rec_5.row_id,                -- 1.ROWID(IN)
        lv_journal_source,                           -- 2.�d��\�[�X��(IN)
        gl_add_dff_data_rec_5.user_je_category_name, -- 3.�d��(IN)
        lv_group_id,                                 -- 4.�O���[�vID(IN)
        lv_context_name,                             -- 5.��v���떼(IN)
        gl_add_dff_data_rec_5.doc_sequence_value,    -- 6.�`�[�ԍ�(IN)
        gl_add_dff_data_rec_5.doc_sequence_value,    -- 7.GL�d��P��(IN)
        lv_out_attribute5,                           -- 8.�N�[����(IN)
        lv_out_attribute6,                           -- 9.���͎�(IN)
        lv_out_tax_code,                             -- 10.�ŃR�[�h(IN)
        lv_out_attribute1,                           -- 11.�������R(IN)
        lv_out_attribute2,                           -- 12.�����Q��(IN)
        lv_out_comments,                             -- 13.���דE�v(IN)
        lv_out_attribute7,                           -- 14.�C�����`�[�ԍ�(IN)
        lv_out_attribute9,                           -- 15.�\���P(IN)
        lv_out_attribute10,                          -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
        gl_add_dff_data_rec_5.attribute15,           -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
        lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --���ʃG���[����
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --���[�U�[�G���[����
            RAISE warning_status_expt;
          END IF;
        END IF;
      ln_trade_receipts_cnt := ln_trade_receipts_cnt + 1; -- �J�e�S���ʌ���(���|�^����������)
--
    END LOOP interface_loop_5;
    --���O�o��
    CLOSE gl_add_dff_data_cur_5;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_5;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_6
   * Description      : DFF�t���Ώۃf�[�^���o���� [Cross Currency](A7,A7-1)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_6(
    in_gl_book_id           IN NUMBER,       -- 1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       -- 2.�I���OID(IN)
    lv_cross_currency       IN VARCHAR2,     -- 3.�d��J�e�S����(���ݒʉ�)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    lv_cross_currency_cnt   IN OUT NUMBER,   -- 5.�d��J�e�S���ʌ���(���ݒʉ�)(OUT)
    lv_group_id             IN NUMBER,       -- 6.�O���[�vID(IN)
    ov_errbuf               OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_6'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;  -- �R���e�L�X�g�l
    lv_out_tax_code    VARCHAR2(50);                  -- �ŃR�[�h
    lv_out_attribute1  VARCHAR2(150);                 -- �������R
    lv_out_attribute5  VARCHAR2(150);                 -- �N�[����
    lv_out_attribute6  VARCHAR2(150);                 -- ���͎�
    lv_out_attribute2  VARCHAR2(150);                 -- �����Q��
    lv_out_comments    VARCHAR2(150);                 -- ���דE�v
    lv_out_attribute7  VARCHAR2(150);                 -- �C�����`�[�ԍ�
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                  -- �\���P
    lv_out_attribute10 VARCHAR2(150);                  -- �\���Q
-- 20050131 V1.5 END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    -- 20040519 �����ǉ� V1.3 ��v���뒠��ID
    CURSOR gl_add_dff_data_cur_6
    IS
    SELECT  gi.rowid AS row_id,                                 -- ROWID
            gi.user_je_category_name AS user_je_category_name,  -- �d��J�e�S��
            gi.reference22 AS invoice_id,                       -- ������ID
            gi.reference23 AS distribution_line_number,         -- ���������הԍ�/�x��ID
            gi.reference29 AS payment_id,                       -- ���׎d��^�C�v
            gi.group_id AS group_id,                            -- �p�����[�^�O���[�vID
            gi.context AS context,                              -- ��v���떼
            gi.reference4 AS reference4,                        -- ���o�ςf�k�d��P��
            gi.reference10 AS reference10,                      -- ���o�ϖ��׊T�v
            gi.jgzz_recon_ref AS jgzz_recon_ref,                -- ���o�Ϗ����Q��
            gi.attribute1 AS attribute1,                        -- ���o�ϐŋ敪
            gi.attribute2 AS attribute2,                        -- ���o�ϑ������R
            gi.attribute3 AS attribute3,                        -- ���o�ϓ`�[�ԍ�
            gi.attribute4 AS attribute4,                        -- ���o�ϋN�[����
            gi.attribute5 AS attribute5,                        -- ���o�ϓ��͎�
            gi.attribute6 AS attribute6,                        -- ���o�ϏC�����`�[�ԍ�
            gi.reference27 AS reference27,                      -- ������ڋq�h�c
            gi.reference25 AS reference25,                      -- �������ԍ�
            acra.doc_sequence_value AS doc_sequence_value,      -- ���������ԍ�
            acra.pay_from_customer AS pay_from_customer,        -- �x���ڋq
            acra.attribute1 AS acra_attribute1                  -- �U���˗��l��
-- ver 11.5.10.2.4 Add Start
           ,gi.attribute15 AS attribute15                       -- �`�[�쐬���
-- ver 11.5.10.2.4 Add End
    FROM    gl_interface gi,                               -- GL�C���^�[�t�F�[�X�e�[�u��
            ar_cash_receipts_all acra                           -- �������e�[�u��
    WHERE   gi.user_je_source_name =  lv_journal_source
    AND     gi.user_je_category_name = lv_cross_currency
    AND     acra.cash_receipt_id = substr(gi.reference22, 1,instr(gi.reference22,'C',1)-1)  
    AND     gi.status ='NEW'
    AND     gi.actual_flag = 'A'
    AND     gi.context IS NULL
    AND     gi.set_of_books_id = in_gl_book_id
    AND     (gi.reference29 in ('CCURR_UNAPP','CCURR_REC','CCURR_EXCH_GAIN','CCURR_EXCH_LOSS'))
    ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec_6 gl_add_dff_data_cur_6%ROWTYPE;
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_6');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_cross_currency);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      lv_context_name,               -- ��v���떼
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --���ʃG���[����
      RAISE global_process_expt;
    END IF;
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur_6;
    <<interface_loop_6>>
    LOOP
      FETCH gl_add_dff_data_cur_6 INTO gl_add_dff_data_rec_6;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur_6%NOTFOUND THEN
          EXIT interface_loop_6;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_6.user_je_category_name);
    -- =================================================
    --�����l�̕ҏW
    -- =================================================
      lv_out_tax_code   := gl_add_dff_data_rec_6.attribute1;     -- �ŃR�[�h
      lv_out_attribute1 := gl_add_dff_data_rec_6.attribute2;     -- �������R
      lv_out_attribute5 := gl_add_dff_data_rec_6.attribute4;     -- �N�[����
      lv_out_attribute6 := gl_add_dff_data_rec_6.attribute5;     -- ���͎�
      lv_out_attribute2 := gl_add_dff_data_rec_6.jgzz_recon_ref; -- �����Q��
      lv_out_comments   := gl_add_dff_data_rec_6.reference10;    -- ���דE�v
      lv_out_attribute7 := gl_add_dff_data_rec_6.attribute6;     -- �C�����`�[�ԍ�
    --�����ԍ��ҏW
      IF gl_add_dff_data_rec_6.payment_id = 'CCURR_REC' THEN 
         lv_out_comments := gl_add_dff_data_rec_6.reference25; -- ���דE�v
      END IF;
-- 20050131 V1.5 START
      lv_out_attribute9 := '';                                   -- �\���P
      lv_out_attribute10 := '';                                  -- �\���Q
-- 20050131 V1.5 END
    -- ===================================
    -- �d��f�[�^�̍X�V���� (A8)
    -- ===================================
      -- 20050131 V1.5 �p�����[�^�i�\���P�E�\���Q�j�̒ǉ�
      upd_journal_data(
      gl_add_dff_data_rec_6.row_id,                -- 1.ROWID(IN)
      lv_journal_source,                           -- 2.�d��\�[�X��(IN)
      gl_add_dff_data_rec_6.user_je_category_name, -- 3.�d��(IN)
      lv_group_id,                                 -- 4.�O���[�vID(IN)
      lv_context_name,                             -- 5.��v���떼(IN)
      gl_add_dff_data_rec_6.doc_sequence_value,    -- 6.�`�[�ԍ�(IN)
      gl_add_dff_data_rec_6.doc_sequence_value,    -- 7.GL�d��P��(IN)
      lv_out_attribute5,                           -- 8.�N�[����(IN)
      lv_out_attribute6,                           -- 9.���͎�(IN)
      lv_out_tax_code,                             -- 10.�ŃR�[�h(IN)
      lv_out_attribute1,                           -- 11.�������R(IN)
      lv_out_attribute2,                           -- 12.�����Q��(IN)
      lv_out_comments,                             -- 13.���דE�v(IN)
      lv_out_attribute7,                           -- 14.�C�����`�[�ԍ�(IN)
      lv_out_attribute9,                           -- 15.�\���P(IN)
      lv_out_attribute10,                          -- 16.�\���Q(IN)
-- ver 11.5.10.2.4 Add Start
      gl_add_dff_data_rec_6.attribute15,           -- 17.�`�[�쐬���(IN)
-- ver 11.5.10.2.4 Add End
      lv_errbuf,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --���ʃG���[����
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --���[�U�[�G���[����
          RAISE warning_status_expt;
        END IF;
      END IF;
      lv_cross_currency_cnt := lv_cross_currency_cnt + 1; -- �J�e�S���ʌ���(���ݒʉ�)
--
    END LOOP interface_loop_6;
    --���O�o��
    CLOSE gl_add_dff_data_cur_6;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
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
  END get_add_dff_data_6;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_journal_source  IN  VARCHAR2,     -- 1.�d��\�[�X��
    iv_group_id        IN  VARCHAR2,     -- 2.�O���[�vID
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_gl_book_id  gl_interface.set_of_books_id%TYPE; -- ��v���뒠��ID
    ln_org_id                   NUMBER(15,0);     -- �I���OID
    lv_sales_invoices           VARCHAR2(30);     -- �d��J�e�S����(���㐿����)
    lv_trade_receipts           VARCHAR2(30);     -- �d��J�e�S����(���|�^����������)
    lv_adjustment               VARCHAR2(30);     -- �d��J�e�S����(�C��)
    lv_credit_memos             VARCHAR2(30);     -- �d��J�e�S����(�N���W�b�g����)
    lv_credit_memo_applications VARCHAR2(30);     -- �d��J�e�S����(�N���W�b�g��������)
    lv_cross_currency           VARCHAR2(30);     -- �d��J�e�S����(���ݒʉ�)
    ln_sales_invoices_cnt       NUMBER := 0;      -- �d��J�e�S���ʌ���(���㐿����)
    ln_trade_receipts_cnt       NUMBER := 0;      -- �d��J�e�S���ʌ���(���|�^����������)
    ln_adjustment_cnt           NUMBER := 0;      -- �d��J�e�S���ʌ���(�C��)
    ln_credit_memos_cnt         NUMBER := 0;      -- �d��J�e�S���ʌ���(�N���W�b�g����)
    ln_credit_memo_app_cnt      NUMBER := 0;      -- �d��J�e�S���ʌ���(�N���W�b�g��������)
    ln_cross_currency_cnt       NUMBER := 0;      -- �d��J�e�S���ʌ���(���ݒʉ�)
-- 20040512 1.2 START
    lv_xx03_tax_code            VARCHAR2(15);     -- XX03_TAX_CODES_V(NAME)
-- 20040512 1.2 END
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
    -- ===============================
    -- �֘A�f�[�^�擾 (A-1)
    -- ===============================
    get_id(
      ln_gl_book_id,               -- 1.��v���뒠��ID(OUT)
      ln_org_id,                   -- 2.�I���OID(OUT)
      lv_sales_invoices,           -- 3.�d��J�e�S����(���㐿����)(OUT)
      lv_trade_receipts,           -- 4.�d��J�e�S����(���|�^����������)(OUT)
      lv_adjustment,               -- 5.�d��J�e�S����(�C��)(OUT)
      lv_credit_memos,             -- 6.�d��J�e�S����(�N���W�b�g����)(OUT)
      lv_credit_memo_applications, -- 7.�d��J�e�S����(�N���W�b�g��������)(OUT)
      lv_cross_currency,           -- 8.�d��J�e�S����(���ݒʉ�)(OUT)
      lv_xx03_tax_code,            -- 9.XX03_TAX_CODES_V(NAME)(OUT)
      lv_errbuf,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ ���㐿���� ]   A2              ***
    --*********************************************

    -- =================================================
    -- DFF�t���Ώۃf�[�^���o���� [Sales Invoices](A2)
    -- =================================================
    get_add_dff_data_1(
      ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
      ln_org_id,              -- 2.�I���OID(IN)
      lv_sales_invoices,      -- 3.�d��J�e�S����(���㐿����)(IN)
      iv_journal_source,      -- 4.�d��\�[�X��(IN)
      ln_sales_invoices_cnt,  -- 5.�d��J�e�S���ʌ���(���㐿����)
      iv_group_id,            -- 6.�O���[�vID(IN)
      lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSE

    --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ �N���W�b�g���� ]   A3          ***
    --*********************************************
    -- =================================================
    -- DFF�t���Ώۃf�[�^���o���� [Credit Memo](A3)
    -- =================================================
      get_add_dff_data_2(
        ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
        ln_org_id,              -- 2.�I���OID(IN)
        lv_credit_memos,        -- 3.�d��J�e�S����(�N���W�b�g����)(IN)
        iv_journal_source,      -- 4.�d��\�[�X��(IN)
        ln_credit_memos_cnt,    -- 5.�d��J�e�S���ʌ���(�N���W�b�g����)
        iv_group_id,            -- 6.�O���[�vID(IN)
        lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        --(�G���[����)
        RAISE global_process_expt;
      ELSE
    --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ �N���W�b�g�������� ]  A4       ***
    --*********************************************
    -- =================================================
    -- DFF�t���Ώۃf�[�^���o���� [CM Applications](A4)
    -- =================================================
        get_add_dff_data_3(
          ln_gl_book_id,               -- 1.��v���뒠��ID(IN)
          ln_org_id,                   -- 2.�I���OID(IN)
          lv_credit_memo_applications, -- 3.�d��J�e�S����(�N���W�b�g��������)(IN)
          iv_journal_source,           -- 4.�d��\�[�X��(IN)
          ln_credit_memo_app_cnt,      -- 5.�d��J�e�S���ʌ���(�N���W�b�g��������)
          iv_group_id,                 -- 6.�O���[�vID(IN)
          lv_xx03_tax_code,            -- 7.XX03_TAX_CODE(IN)
          lv_errbuf,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,                  -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          --(�G���[����)
          RAISE global_process_expt;
        ELSE
 
    --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ �C�� ]     A5                  ***
    --*********************************************
    -- =================================================
    -- DFF�t���Ώۃf�[�^���o���� [Adjistment](A5)
    -- =================================================
          get_add_dff_data_4(
            ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
            ln_org_id,              -- 2.�I���OID(IN)
            lv_adjustment,          -- 3.�d��J�e�S����(�C��)(IN)
            iv_journal_source,      -- 4.�d��\�[�X��(IN)
            ln_adjustment_cnt,      -- 5.�d��J�e�S���ʌ���(�C��)
            iv_group_id,            -- 6.�O���[�vID(IN)
            lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            --(�G���[����)
            RAISE global_process_expt;
          ELSE
    --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ ���|�^���������� ]    A6       ***
    --*********************************************
    -- =================================================
    -- DFF�t���Ώۃf�[�^���o���� [Trade Receipts](A6)
    -- =================================================
            get_add_dff_data_5(
              ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
              ln_org_id,              -- 2.�I���OID(IN)
              lv_trade_receipts,      -- 3.�d��J�e�S����(���|�^����������)(IN)
              iv_journal_source,      -- 4.�d��\�[�X��(IN)
              ln_trade_receipts_cnt,  -- 5.�d��J�e�S���ʌ���(���|�^����������)
              iv_group_id,            -- 6.�O���[�vID(IN)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              --(�G���[����)
              RAISE global_process_expt;
            ELSE
     --*********************************************
    --***      �d��J�e�S��                     ***
    --***      [ ���ݒʉ� ]          A7         ***
    --*********************************************
    -- ======================================================
    -- DFF�t���Ώۃf�[�^���o���� [Cross Currency](A7,A7-1)
    -- ======================================================
              get_add_dff_data_6(
                ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
                ln_org_id,              -- 2.�I���OID(IN)
                lv_cross_currency,      -- 3.�d��J�e�S����(���ݒʉ�)(IN)
                iv_journal_source,      -- 4.�d��\�[�X��(IN)
                ln_cross_currency_cnt,  -- 5.�d��J�e�S���ʌ���(���ݒʉ�)
                iv_group_id,            -- 6.�O���[�vID(IN)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                --(�G���[����)
                RAISE global_process_expt;
              ELSE
-- Ver11.5.10.1.6 2005/12/15 Delete Start
-- -- 20040512 GL_INTERFACE�X�V�ǉ� START
--    --*********************************************
--    --***      GL_INTERFACE�X�V                 ***
--    --***      [ �ŋ敪�@NULL�Ή� ]   A8_1      ***
--    --*********************************************
--    -- ===================================
--    -- �d��f�[�^�̍X�V���� (A8_1)
--    -- ===================================
--               upd_journal_data_1(
--                 lv_xx03_tax_code,         -- 1.�ŃR�[�h(IN)
--                 iv_journal_source,        -- 2.�d��\�[�X��(IN)
--                 lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
--                 lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
--                 lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--               IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--                 --(�G���[����)
--                 RAISE global_process_expt;
--               ELSE
-- 20040512 GL_INTERFACE�X�V�ǉ� END
-- Ver11.5.10.1.6 2005/12/15 Delete End
    --*********************************************
    --***      �v���[�t���X�g�o�͏���           ***
    --***       A8                              ***
    --*********************************************
                msg_output(
                  ln_org_id,                   -- 1.�I���OID(IN)
                  ln_sales_invoices_cnt,       -- 2.����������(IN)(���㐿����)
                  ln_trade_receipts_cnt,       -- 3.����������(IN)(���|�^����������)
                  ln_adjustment_cnt,           -- 4.����������(IN)(�C��)
                  ln_credit_memos_cnt,         -- 5.����������(IN)(�N���W�b�g����)
                  ln_credit_memo_app_cnt,      -- 6.����������(IN)(�N���W�b�g��������)
                  ln_cross_currency_cnt,       -- 7.����������(IN)(���ݒʉ�)
                  iv_journal_source,           -- 8.�d��\�[�X��(IN)
                  lv_sales_invoices,           -- 9.�d��J�e�S����(���㐿����)(IN)
                  lv_trade_receipts,           -- 10.�d��J�e�S����(���|�^����������)(IN)
                  lv_adjustment,               -- 11.�d��J�e�S����(�C��)(IN)
                  lv_credit_memos,             -- 12.�d��J�e�S����(�N���W�b�g����)(IN)
                  lv_credit_memo_applications, -- 13.�d��J�e�S����(�N���W�b�g��������)(IN)
                  lv_cross_currency,           -- 14.�d��J�e�S����(���ݒʉ�)(IN)
                  ov_errbuf,               --   �G���[�E���b�Z�[�W           --# �Œ� #
                  ov_retcode,              --   ���^�[���E�R�[�h             --# �Œ� #
                  ov_errmsg);              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                  --(�G���[����)
                  RAISE global_process_expt;
                END IF;
               -- Ver11.5.10.1.6 2005/12/15 Delete Start
               --END IF;
               -- Ver11.5.10.1.6 2005/12/15 Delete End
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_je_source  IN  VARCHAR2,      --   1.�d��\�[�X��
    iv_group_id   IN  VARCHAR2)      --   2.�O���[�vID
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
      iv_je_source,     -- 1.�d��\�[�X��
      iv_group_id,      -- 2.�O���[�vID
      lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XX033JU001C;
/
