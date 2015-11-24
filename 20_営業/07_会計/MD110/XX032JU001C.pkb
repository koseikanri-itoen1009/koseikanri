CREATE OR REPLACE PACKAGE BODY XX032JU001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX032JU001C(body)
 * Description      : ��ʉ�v�V�X�e����̃f�[�^�ɁA���|�Ǘ��V�X�e���ŕێ�����DFF�̒l���X�V���܂��B
 * MD.050           : AP �d��t�����X�V���� OCSJ/BFAFIN/MD050/F204
 * MD.070           : AP �d��t�����X�V���� OCSJ/BFAFIN/MD070/F204
 * Version          : 11.5.10.1.7
 *
 * Program List
 * ---------------------------------- ----------------------------------------------
 *  Name                              Description
 * ---------------------------------- ----------------------------------------------
 *  get_id                            �֘A�f�[�^�擾(A-1)
 *  get_add_dff_data                  DFF�t���Ώۃf�[�^���o���� (A-2)
 *  get_buying_in_invoices            �d��������DFF�l�X�V(A-3-1)
 *  proc_tax_incr_decr_dff_values     �ŃR�[�h�A�������R�̐ݒ� (A-3-1-1)  2004/03/03 �폜
 *  get_tax_code                      �ŃR�[�h�̎擾 (A-3-1-1-1)
 *  proc_adj_slip_num                 �C�����`�[�ԍ��̐ݒ� (A-3-1-2)      2004/03/03 �폜
 *  proc_detail_desc                  ���דE�v�̐ݒ� (A-3-1-3)            2004/03/03 �폜
 *  proc_slip_num_and_others          �`�[�ԍ��A���̑����ڂ̐ݒ� (A-3-1-4�AA-3-1-5)
 *  proc_app_ref_dff_values           �����Q�Ƃ̐ݒ� (A-3-1-6)            2004/03/03 �폜
 *  proc_dff_values_not_liability     �ŃR�[�h�A�������R�A�\���P�A�\���Q�A
 *                                    �����p�ƍ��̐ݒ� (A-3-1-1�AA-3-1-6) 2004/03/03 �ǉ�
 *  get_payment                       �x��������DFF�l�X�V (A-3-2)
 *  proc_slip_num_journal_name        �`�[�ԍ��A�d�󖼏̂̐ݒ� (A-3-2-1)
 *  proc_detail_desc_unpaid           ���דE�v(�x���F������AP)�̐ݒ� (A-3-2-2)
 *  proc_detail_desc_desposit         ���דE�v(�x���F�a��)�̐ݒ� (A-3-2-3)
 *  proc_adj_slip_num_cancel          �C�����`�[�ԍ�(�x�����)�̐ݒ� (A-3-2-4)  2004/03/03 �폜
 *  upd_journal_data                  �d��f�[�^�̍X�V���� (A-4)
 *  msg_output                        �v���[�t���X�g�o�͏��� (A-5)
 *  upd_reference10                   ���t�@�����X10�X�V(A-6)             2015/10/13 �ǉ�
 *  submain                           ���C�������v���V�[�W��
 *  main                              �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ------------- ---------------- -------------------------------------------------
 *  Date          Ver.          Editor           Description
 * ------------- ------------- ---------------- -------------------------------------------------
 *  2004/01/15    1.0           H.Ogawa           �V�K�쐬
 *  2004/01/27    1.1           H.Ogawa           �P�̃e�X�g��Q�C��
 *  2004/02/10    1.2           H.Ogawa           �����e�X�g��Q�C��
 *  2004/02/24    1.3           H.Ogawa           �V�X�e���e�X�g��Q�C��
 *  2004/03/19    1.4           H.Ogawa           �d���������A�O�����[�����̈ב֍����v�A�����s�̏ꍇ��
 *                                                �Ή���ǉ��B
 *                                                �x�����̒[�������s�̏ꍇ�̑Ή���ǉ��B
 *  2004/03/26    1.5           H.Ogawa           �d���������A�O�������Ŕ�������s�ԍ��������Ȃ�
 *                                                ���������`�[�ɑ΂���DFF�t�������ɑ΂���s��Ώ�
 *  2004/04/20    1.6           H.Ogawa           �x�����A������ID�̎擾���@�̏C��
 *  2004/06/28    1.7           T.Maeda           �x���a���ł��邩�̔��f�����ɗa��(CASH)�̏ꍇ���ǉ�
 *  2005/02/25    1.8           M.Umeda           ��Q268�u�`�[�ԍ��ɘA�g����ԍ����v�ɑΉ�
 *  2005/07/12    11.5.10.1.4   S.Yamada          ���דE�v�̐ݒ�(�x���F�a��)�Ōʎx���ɑΉ�
 *  2005/08/04    11.5.10.1.4B  S.Yamada          �d�󖾍׉Ȗڃ^�C�v��'RECOVERABLE TAX'�A'AP ACCRUAL'�̃f�[�^��
 *                                                �ŃR�[�h�A�������R�A�\���P�A�\���Q�A�����p�ƍ��L�[���ݒ肳���悤�ɏC��
 *  2005/08/19    11.5.10.1.4C  Y.Matsumura       �d�󖾍׉Ȗڃ^�C�v��'FUTURE PAYMENT'�̃f�[�^��(�x���F�a��)
 *                                                �Ƃ��ď��������悤�ɕύX
 *  2006/03/17    11.5.10.1.6   S.Morisawa        CU2��fnd_message.set_token�̈����ɂ�铮���̕ύX��
 *                                                �G���[�ƂȂ�ꍇ�����邽�߁A�����𐳂�������悤�ɏC��
 *  2015/10/13    11.5.10.1.7   Y.Shoji           E_�{�ғ�_13334�Ή� �uA-6�D���t�@�����X10�X�V�v��ǉ�
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
  cv_package_name     CONSTANT VARCHAR2(20) := 'XX032JU001';              --�p�b�P�[�W��
  cv_execite_tbl_name CONSTANT VARCHAR2(20) := 'GL_INTERFACE';            --�����Ώۃe�[�u����
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  get_org_id_expt       EXCEPTION;            -- �I���OID���擾�G���[
  get_books_id_expt     EXCEPTION;            -- ��v����ID���擾�G���[
  warning_status_expt     EXCEPTION;          -- ���[�U�[�G���[�n���h���p
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : �v���[�t���X�g�o�͏��� (A-5)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id                   IN NUMBER,       -- 1.�I���OID(IN)
    in_buyning_cnt              IN NUMBER,       -- 2.�d������������(IN)
    in_payment_cnt              IN NUMBER,       -- 3.�x������(IN)
    iv_journal_source           IN VARCHAR2,     -- 4.�d��\�[�X��(IN)
    iv_buyning_in_invoice       IN VARCHAR2,     -- 5.�d��J�e�S���ʌ���(�d��������)(IN)
    iv_payment_type             IN VARCHAR2,     -- 6.�d��J�e�S���ʌ���(�x��)(IN)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 'XX03_AP_JOURNAL_CATEGORY';
    -- LOOKUP_TYPE�l(����)
    cv_lookup_type_count      CONSTANT VARCHAR2(50) := 'XX03_AP_COUNT';
--
    -- *** ���[�J���ϐ� ***
    lv_msgbuf  VARCHAR2(300);     -- �o�̓��b�Z�[�W
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
    lv_category VARCHAR2(30);     -- ��ʕ\����(�d��J�e�S��)
    lv_count    VARCHAR2(10);     -- ��ʕ\����(����)
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    -- ���b�Z�[�W����ʕ\�������擾
    -- �d��J�e�S��
    lv_category := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-02017'); -- ���b�Z�[�W�敪
    -- ����
    lv_count := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-02018'); -- ���b�Z�[�W�敪
    -- ����I�����̉�ʏo��
    -- ���o�������̕\��
    xx03_header_line_output_pkg.header_line_output_p('AP',
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
    -- 5�s��(�X�V������)
    xx00_message_pkg.set_name('XX00','APP-XX00-00019');
-- ver 11.5.10.1.6 Chg Start
    --xx00_message_pkg.set_token('COUNT',
    --  TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'),
    --  TRUE);
    xx00_message_pkg.set_token('COUNT',
      TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'),
      FALSE);
-- ver 11.5.10.1.6 Chg End
    -- 6�s��(��������  ����)
    xx00_file_pkg.output(RPAD(lv_category,24,' ') || 
      LPAD(lv_count,7,' '));
    -- 7�s��(��������  �d��������)
    xx00_file_pkg.output(RPAD(iv_buyning_in_invoice,24,' ') || 
      TO_CHAR(in_buyning_cnt,'999999'));
    -- 8�s��(��������  �x��)
    xx00_file_pkg.output(RPAD(iv_payment_type,24,' ') || 
      TO_CHAR(in_payment_cnt,'999999'));
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    --���폈����̃��O�o��
    lv_msgbuf := xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-06016'); -- ���b�Z�[�W�敪(���)
    lv_msgbuf := lv_msgbuf || cv_package_name || ' ';
    lv_msgbuf := lv_msgbuf || xx00_message_pkg.get_msg(
      'XX03',  --�A�v���P�[�V�����Z�k��
      'APP-XX03-06019',
      'TOK_TABLE',
      cv_execite_tbl_name,
      'COUNT',
      TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'));
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
  /**********************************************************************************
   * Procedure Name   : get_id
   * Description      : �֘A�f�[�^�擾 (A-1)
   ***********************************************************************************/
  PROCEDURE get_id(
    on_gl_book_id           OUT NUMBER,       --   1.��v���뒠��ID(OUT)
    on_org_id               OUT NUMBER,       --   2.�I���OID(OUT)
    ov_buyning_in_invoice   OUT VARCHAR2,     --   3.�d��J�e�S����(�d��������)(OUT)
    ov_payment_type         OUT VARCHAR2,     --   4.�d��J�e�S����(�x��)(OUT)
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      'XX03_AP_JOURNAL_TYPE'; -- LOOKUP_TYPE�l
    cv_lookup_code_buying   CONSTANT VARCHAR2(50) := 
      'BUYING_IN_INVOICE'; -- LOOKUP_CODE�l(�d��������)
    cv_lookup_code_payment  CONSTANT VARCHAR2(50) := 
      'PAYMENT_TYPE'; -- LOOKUP_CODE�l(�x��)
--
    -- *** ���[�J���ϐ� ***
    lv_category_err_tk    VARCHAR2(50); -- �d��J�e�S�����擾�G���[�g�[�N���l
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
    xx00_file_pkg.log(' ');
    --�I���OID�̎擾
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    --�I���OID�l�̌���
    IF (on_org_id IS NULL) THEN
      -- �I���OID���擾�G���[
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-22001');
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
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06002');
      RAISE get_books_id_expt;
    END IF;
--
    --�d��J�e�S����(�d��������)�̎擾
    SELECT  xlxv.meaning
    INTO    ov_buyning_in_invoice
    FROM  xx03_lookups_xx03_v xlxv
    WHERE xlxv.lookup_type = cv_lookup_type_category
    AND xlxv.enabled_flag = 'Y'
    AND xlxv.lookup_code = cv_lookup_code_buying;
    --�d��J�e�S����(�x��)�̎擾
    SELECT  xlxv.meaning
    INTO    ov_payment_type
    FROM  xx03_lookups_xx03_v xlxv
    WHERE xlxv.lookup_type = cv_lookup_type_category
    AND xlxv.enabled_flag = 'Y'
    AND xlxv.lookup_code = cv_lookup_code_payment;
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
    WHEN NO_DATA_FOUND THEN                       --*** �d��J�e�S�����f�l���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      -- �擾�ł��Ȃ������d��J�e�S���̔��f
      IF ov_buyning_in_invoice IS NULL THEN
        lv_category_err_tk := cv_lookup_code_buying;
        IF ov_payment_type IS NULL THEN
          lv_category_err_tk := lv_category_err_tk || cv_lookup_code_payment;
        END IF;
      ELSE
        lv_category_err_tk := cv_lookup_code_payment;
      END IF;
      -- �G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06013',
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
   * Procedure Name   : get_tax_code
   * Description      : �ŃR�[�h�̎擾 (A-3-1-1-1)
   ***********************************************************************************/
  PROCEDURE get_tax_code(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_tax_code_id              IN NUMBER,      -- 2.�ŃR�[�hID(IN)
    iov_tax_code                IN OUT VARCHAR2, -- 3.�ŃR�[�h(IN OUT)
    in_invoice_id               IN NUMBER,      -- 4.������ID(IN)
    in_dist_line_number         IN NUMBER,      -- 5.���������הԍ�(IN)
    ov_errbuf                   OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tax_code'; -- �v���O������
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_tax_codes_all');
    xx00_file_pkg.log('key tax_id=' || TO_CHAR(in_tax_code_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �ŃR�[�h�}�X�^����ŃR�[�h���擾���Đݒ肷��
    SELECT  name AS tax_name       -- �ŃR�[�h
    INTO    iov_tax_code           -- �ŃR�[�h
    FROM    ap_tax_codes_all atca
    WHERE   atca.tax_id = in_tax_code_id
    AND     atca.org_id = in_org_id;
    -- ���O�o��
    xx00_file_pkg.log('update tax_name=' || TO_CHAR(iov_tax_code));
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �ŃR�[�h�̖��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END get_tax_code;
-- Ver1.3 add start �֐��̓��p���̈גǉ�
  /**********************************************************************************
   * Procedure Name   : proc_dff_values_not_liability
   * Description      : �ŃR�[�h�A�������R�A
   *                    �\���P�A�\���Q�A�����p�ƍ��̐ݒ� (A-3-1-1�AA-3-1-6)
   ***********************************************************************************/
  PROCEDURE proc_dff_values_not_liability(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,      -- 2.������ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.���������הԍ�(IN)
    iov_tax_code                IN OUT VARCHAR2,  -- 4.�ŃR�[�h(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,  -- 5.�������R(IN OUT)
    iov_app_ref                 IN OUT VARCHAR2,  -- 6.�����p�ƍ�(IN OUT)
    iov_reserve1                IN OUT VARCHAR2,  -- 7.�\���P(IN OUT)
    iov_reserve2                IN OUT VARCHAR2,  -- 8.�\���Q(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_dff_values_not_liability'; -- �v���O������
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
    ln_tax_code_id  ap_invoice_distributions_all.tax_code_id%TYPE; -- �ŃR�[�hID
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    -- ���������׈ꗗ����ŃR�[�hID�A�������R�A
    -- �\���P�A�\���Q�A�����p�ƍ����擾����
    -- �ŃR�[�hID���������ڂ͂��̂܂ܐݒ肷��
    SELECT  tax_code_id AS tax_code_id,             -- �ŃR�[�hID
            attribute1 AS increase_and_decrease,    -- �������R
            attribute9 AS reserve1,                 -- �\���P
            attribute10 AS reserve2,                -- �\���Q
            attribute2 AS app_ref                   -- �����p�ƍ�
    INTO    ln_tax_code_id,         -- �ŃR�[�hID
            iov_incr_decr,          -- �������R
            iov_reserve1,           -- �\���P
            iov_reserve2,           -- �\���Q
            iov_app_ref             -- �����p�ƍ�
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number;
--    AND     aida.org_id = in_org_id;
--
    -- �ŃR�[�h�}�X�^����ŃR�[�h���擾����
    -- ���������׈ꗗ����ŃR�[�hID���擾�ł��Ȃ�(NULL������)
    -- �ꍇ�͐ŃR�[�h��NULL���Z�b�g����
    IF ln_tax_code_id IS NOT NULL THEN
      get_tax_code(
        in_org_id,                    -- 1.�I���OID(IN)
        ln_tax_code_id,               -- 2.�ŃR�[�hID(IN)
        iov_tax_code,                 -- 3.�ŃR�[�h(IN OUT)
        in_invoice_id,                -- 4.������ID(IN)
        in_dist_line_number,          -- 5.���������הԍ�(IN)
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
    ELSE
      iov_tax_code := NULL;
    END IF;
    -- ���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
    WHEN NO_DATA_FOUND THEN                       --*** �ŃR�[�h�A�������R�̖��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06004',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06011',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_dff_values_not_liability;
-- Ver1.3 add end �֐��̓��p���̈גǉ�
-- Ver1.3 Del start �֐��̓��p���̈׍폜
  /**********************************************************************************
   * Procedure Name   : proc_tax_incr_decr_dff_values
   * Description      : �ŃR�[�h�A�������R�̐ݒ� (A-3-1-1)
   ***********************************************************************************/
/*
  PROCEDURE proc_tax_incr_decr_dff_values(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,      -- 2.������ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.���������הԍ�(IN)
    iov_tax_code                IN OUT VARCHAR2,   -- 4.�ŃR�[�h(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,   -- 5.�������R(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_tax_incr_decr_dff_values'; -- �v���O������
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
    ln_tax_code_id  ap_invoice_distributions_all.tax_code_id%TYPE; -- �ŃR�[�hID
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoice_distributions_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key distribution_line_number=' || TO_CHAR(in_dist_line_number));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- ���������׈ꗗ����ŃR�[�hID�A�������R���擾���āA
    -- �������R�͑������R�Ƃ��Đݒ肷��
    SELECT  tax_code_id AS tax_code_id,           -- �ŃR�[�hID
            attribute1 AS increase_and_decrease   -- �������R
    INTO    ln_tax_code_id,       -- �ŃR�[�hID
            iov_incr_decr         -- �������R
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number
    AND     aida.org_id = in_org_id;
--
    -- �ŃR�[�h�}�X�^����ŃR�[�h���擾����
    -- Ver1.2 add �d�l�ύX ���������׈ꗗ����ŃR�[�hID���擾�ł��Ȃ�(NULL������)
    -- �ꍇ�͐ŃR�[�h��NULL���Z�b�g����
    IF ln_tax_code_id IS NOT NULL THEN      -- Ver1.2 add
      get_tax_code(
        in_org_id,                    -- 1.�I���OID(IN)
        ln_tax_code_id,               -- 2.�ŃR�[�hID(IN)
        iov_tax_code,                 -- 3.�ŃR�[�h(IN OUT)
        in_invoice_id,                -- 4.������ID(IN)
        in_dist_line_number,          -- 5.���������הԍ�(IN)
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
    ELSE                                    -- Ver1.2 add
      iov_tax_code := NULL;                 -- Ver1.2 add
    END IF;
    -- ���O�o��
    xx00_file_pkg.log('update tax_code_id=' || TO_CHAR(ln_tax_code_id));
    xx00_file_pkg.log('update increase_and_decrease=' || iov_incr_decr);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ���[�U�[�G���[�n���h�� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
    WHEN NO_DATA_FOUND THEN                       --*** �ŃR�[�h�A�������R�̖��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06004',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_tax_incr_decr_dff_values;
*/
-- Ver1.3 Del End
-- Ver1.3 Del start �֐��̓��p���̈׍폜
  /**********************************************************************************
   * Procedure Name   : proc_adj_slip_num
   * Description      : �C�����`�[�ԍ��̐ݒ� (A3-1-2)
   ***********************************************************************************/
/*
  PROCEDURE proc_adj_slip_num(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,      -- 2.������ID(IN)
    iov_adj_slip_num            IN OUT VARCHAR2, -- 3.�C�����`�[�ԍ�(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_adj_slip_num'; -- �v���O������
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
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �������ꗗ����C�����`�[�ԍ����擾���āA������C�����`�[�ԍ��Ƃ��Đݒ肷��
    SELECT  attribute5 AS adj_slip_num    -- �C�����`�[�ԍ�
    INTO    iov_adj_slip_num
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id;
    --���O�o��
    xx00_file_pkg.log('update adj_slip_num=' || iov_adj_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �C�����`�[�ԍ����擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_adj_slip_num;
-- Ver1.3 Del End
-- Ver1.3 Del start �d�l�ύX�ɂ��s�v�̈׍폜
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc
   * Description      : ���דE�v�̐ݒ� (A3-1-3)
   ***********************************************************************************/
/*
  PROCEDURE proc_detail_desc(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,      -- 2.������ID(IN)
    iov_slip_desc               IN OUT VARCHAR2, -- 3.���דE�v(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc'; -- �v���O������
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �������ꗗ���疾�דE�v���擾���āA����𖾍דE�v�Ƃ��Đݒ肷��
    SELECT  attribute5 AS detail_desc   -- ���דE�v
    INTO    iov_slip_desc
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id
    AND     aia.org_id = in_org_id;
    -- ���O�o��
    xx00_file_pkg.log('update detail_desc=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** ���דE�v���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_detail_desc;
*/
-- Ver1.3 Del end
  /**********************************************************************************
   * Procedure Name   : proc_slip_num_and_others
   * Description      : �`�[�ԍ��y�т��̑��̍��ڂ̐ݒ� (A-3-1-4�AA-3-1-5)
   ***********************************************************************************/
  PROCEDURE proc_slip_num_and_others(
    in_org_id                   IN NUMBER,        -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,        -- 2.������ID(IN)
    iov_slip_num                IN OUT VARCHAR2,  -- 3.�`�[�ԍ�(IN OUT)
    iov_je_name                 IN OUT VARCHAR2,  -- 4.�d��(IN OUT)
    iov_dept                    IN OUT VARCHAR2,  -- 5.�N�[����(IN OUT)
    iov_input_user              IN OUT VARCHAR2,  -- 6.���͎�(IN OUT)
--Ver1.3 add Start    �֐������̈גǉ�
    iov_adj_slip_num            IN OUT VARCHAR2,  -- 7.�C�����`�[�ԍ�(IN OUT)
--Ver1.3 add end
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_slip_num_and_others'; -- �v���O������
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
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �������ꗗ����
    -- �������ԍ��A�����ԍ��A�N�[����A���͎ҁA�C�����`�[�ԍ����擾���āA
    -- ������e�X�ݒ肷��
    SELECT  invoice_num AS invoice_num,               -- �������ԍ�
            doc_sequence_value AS doc_sequence_value, -- �����ԍ�
            attribute3 AS department,                 -- �N�[����
            attribute4 AS input_user,                 -- ���͎�
--Ver1.3 add Start    �֐������̈גǉ�
            attribute5 AS adj_slip_num                -- �C�����`�[�ԍ�
--Ver1.3 add End
    INTO    iov_slip_num,        -- �`�[�ԍ�
            iov_je_name,         -- �d��
            iov_dept,            -- �N�[����
            iov_input_user,      -- ���͎�
--Ver1.3 add Start    �֐������̈גǉ�
            iov_adj_slip_num    -- �C�����`�[�ԍ�
--Ver1.3 add end
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id;
    -- ���O�o��
    xx00_file_pkg.log('update slip_num=' || iov_slip_num);
    xx00_file_pkg.log('update je_name=' || iov_je_name);
    xx00_file_pkg.log('update dept=' || iov_dept);
    xx00_file_pkg.log('update input_user=' || iov_input_user);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��y�т��̑��̍��ږ��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06007',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06008',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06009',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06010',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
--Ver1.3 add Start    �֐������̈גǉ�
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
--Ver1.3 add End
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_slip_num_and_others;
-- Ver1.3 Del start �֐��̓��p���̈׍폜
  /**********************************************************************************
   * Procedure Name   : proc_app_ref_dff_values
   * Description      : �����Q�Ƃ̐ݒ� (A-3-1-6)
   ***********************************************************************************/
/*
  PROCEDURE proc_app_ref_dff_values(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_invoice_id               IN NUMBER,      -- 2.������ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.���������הԍ�(IN)
    iov_app_ref                 IN OUT VARCHAR2, -- 4.�����Q��(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_app_ref_dff_values'; -- �v���O������
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
    xx00_file_pkg.log('select ap_invoice_distributions_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key distribution_line_number=' || TO_CHAR(in_dist_line_number));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- ���������׈ꗗ��������Q�Ƃ��擾���Đݒ肷��
    SELECT  attribute2 AS app_ref     -- �����Q��
    INTO    iov_app_ref               -- �����Q��
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number
    AND     aida.org_id = in_org_id;
    -- ���O�o��
    xx00_file_pkg.log('update app_ref=' || iov_app_ref);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �����Q�Ƃ̖��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06011',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_app_ref_dff_values;
*/
-- Ver1.3 Del End
  /**********************************************************************************
   * Procedure Name   : proc_slip_num_journal_name
   * Description      : �`�[�ԍ��A�d�󖼏̂̐ݒ� (A-3-2-1)
   ***********************************************************************************/
  PROCEDURE proc_slip_num_journal_name(
    in_org_id                   IN NUMBER,        -- 1.�I���OID(IN)
    in_check_id                 IN NUMBER,        -- 2.�x���o�b�`�`�F�b�NID(IN)
    in_payment_id               IN NUMBER,        -- 3.�������x��ID(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 4.�d��(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 5.�`�[�ԍ�(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_slip_num_journal_name'; -- �v���O������
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
--Ver1.8 Start Modify
--    ln_check_number  ap_checks_all.check_number%TYPE; -- �x�������ԍ�
    ln_doc_sequence_value ap_checks_all.doc_sequence_value%TYPE;  -- �؜ߔԍ�
--Ver1.8 End Modify
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
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �x���o�b�`��񂩂�x�������ԍ����擾����B
--Ver1.8 Start Modify
--    SELECT  check_number AS check_number  -- �x�������ԍ�
--    INTO    ln_check_number
    SELECT  doc_sequence_value AS doc_sequence_value  -- �؜ߔԍ�
    INTO    ln_doc_sequence_value
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
--Ver1.8 End Modify
--
    -- �x�������ԍ���`�[�ԍ��A�d�󖼏̂Ƃ��Đݒ肷��
--Ver1.8 Start Modify
--    iov_je_name := TO_CHAR(ln_check_number);
--    iov_slip_num := TO_CHAR(ln_check_number);
    iov_je_name := TO_CHAR(ln_doc_sequence_value);
    iov_slip_num := TO_CHAR(ln_doc_sequence_value);
--Ver1.8 End Modify
    -- ���O�o��
    xx00_file_pkg.log('update je_name=' || iov_je_name);
    xx00_file_pkg.log('update slip_num=' || iov_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �`�[�ԍ��A�d�󖼏̖��擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06007',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06010',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_slip_num_journal_name;
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc_unpaid
   * Description      : ���דE�v(�x���F������AP)�̐ݒ� (A-3-2-2)
   ***********************************************************************************/
  PROCEDURE proc_detail_desc_unpaid(
    in_org_id                   IN NUMBER,        -- 1.�I���OID(IN)
    in_payment_id               IN NUMBER,        -- 2.�������x��ID(IN)
    iov_slip_desc               IN OUT VARCHAR2,   -- 3.���דE�v(IN OUT)
-- Ver1.6 change start �������x��ID���琿����ID�����������AGL_INTERFACE�̐�����ID��
--                     ���̂܂܎g�p����
    in_invoice_id               IN NUMBER,        -- 4.������ID(IN)
-- Ver1.6 change end
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc_unpaid'; -- �v���O������
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
    ln_invoice_id   ap_invoices_all.invoice_id%TYPE; -- ������ID
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoice_payments_all');
-- Ver1.6 change start
--    xx00_file_pkg.log('key invoice_payment_id=' || TO_CHAR(in_payment_id));
    xx00_file_pkg.log('key in_invoice_id=' || TO_CHAR(in_invoice_id));
-- Ver1.6 change end
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
-- Ver1.6 delete start ������ID�擾�����͕s�v�̈׍폜
--  -- �������x�����琿�����ԍ����擾���āA����𖾍דE�v�Ƃ��Đݒ肷��
-- Ver1.3 change start �d�l�o�O�C�� 
--    SELECT  TO_CHAR(invoice_id) AS invoice_id  -- �������ԍ�
--    INTO    iov_slip_desc
--    SELECT  aip.invoice_id AS invoice_id  -- ������ID
--    INTO    ln_invoice_id
-- Ver1.3 change end
--    FROM    ap_invoice_payments_all aip
--    WHERE   aip.invoice_payment_id = in_payment_id;
-- Ver1.3 del start �d�l�o�O�C�� 
--    AND     aip.org_id = in_org_id;
-- Ver1.3 del start �d�l�o�O�C�� 
-- Ver1.6 delete end
    -- ������ID���琿�����ԍ����擾
    SELECT  aia.invoice_num AS invoice_num    -- �������ԍ�
    INTO    iov_slip_desc
    FROM    ap_invoices_all aia
-- Ver1.6 change start
--    WHERE   aia.invoice_id = ln_invoice_id;
    WHERE   aia.invoice_id = in_invoice_id;
-- Ver1.6 change end
    -- ���O�o��
    xx00_file_pkg.log('update slip_desc=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** ���דE�v���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_detail_desc_unpaid;
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc_desposit
   * Description      : ���דE�v(�x���F�a��)�̐ݒ� (A-3-2-3)
   ***********************************************************************************/
  PROCEDURE proc_detail_desc_desposit(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_check_id                 IN NUMBER,      -- 2.�x���o�b�`�`�F�b�NID(IN)
    in_payment_id               IN NUMBER,      -- 3.�������x��ID(IN)
    iov_slip_desc               IN OUT VARCHAR2, -- 4.���דE�v(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc_desposit'; -- �v���O������
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
-- Ver11.5.10.1.4 change start
    lv_checkrun_name  ap_checks_all.checkrun_name%TYPE; -- �x���o�b�`��
    ln_check_number   ap_checks_all.check_number%TYPE;  -- �����ԍ�
    ln_checkrun_id    ap_checks_all.checkrun_id%TYPE;   -- �x���o�b�`�h�c
-- Ver11.5.10.1.4 change end
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
    -- ���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
-- Ver11.5.10.1.4 change start
    -- �x���o�b�`��񂩂�x���o�b�`���A�����ԍ��A�x���o�b�`�h�c���擾����B
    SELECT  checkrun_name AS checkrun_name, -- �x���o�b�`��
            check_number  AS check_number,  -- �����ԍ�
            checkrun_id   AS checkrun_id    -- �x���o�b�`�h�c
    INTO    lv_checkrun_name,
            ln_check_number,
            ln_checkrun_id 
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
    -- �x���o�b�`�h�c��NULL�łȂ��ꍇ(�x���o�b�`)�͎x���o�b�`����ݒ肷��B
    -- ����ȊO�̏ꍇ(�ʎx��)�͕����ԍ���ݒ肷��B
    IF (ln_checkrun_id IS NOT NULL) THEN
      iov_slip_desc := lv_checkrun_name;
    ELSE
      iov_slip_desc := TO_CHAR(ln_check_number);
    END IF;
-- Ver11.5.10.1.4 change end
    -- ���O�o��
    xx00_file_pkg.log('update checkrun_name=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** ���דE�v���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_detail_desc_desposit;
-- Ver1.3 Del start �d�l�ύX�ɂ��s�v�̈׍폜
  /**********************************************************************************
   * Procedure Name   : proc_adj_slip_num_cancel
   * Description      : �C�����`�[�ԍ�(�x�����)�̐ݒ� (A-3-2-4)
   ***********************************************************************************/
/*
  PROCEDURE proc_adj_slip_num_cancel(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    in_check_id                 IN NUMBER,      -- 2.�x���o�b�`�`�F�b�NID(IN)
    in_payment_id               IN NUMBER,      -- 3.�������x��ID(IN)
    iov_adj_slip_num            IN OUT VARCHAR2,   -- 4.�C�����`�[�ԍ�(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_adj_slip_num_cancel'; -- �v���O������
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
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- �x���o�b�`��񂩂�x�������ԍ����擾����B
    SELECT  TO_CHAR(check_number) AS check_number  -- �x�������ԍ�
    INTO    iov_adj_slip_num
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
    -- ���O�o��
    xx00_file_pkg.log('update check_number=' || iov_adj_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** �C�����`�[�ԍ����擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
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
  END proc_adj_slip_num_cancel;
*/
-- Ver1.3 Del end
  /**********************************************************************************
   * Procedure Name   : upd_journal_data
   * Description      : �d��f�[�^�̍X�V���� (A-4)
   ***********************************************************************************/
  PROCEDURE upd_journal_data(
    iv_je_name              IN VARCHAR2,    -- 1.�d��(IN)
    iv_slip_desc            IN VARCHAR2,    -- 2.���דE�v(IN)
    iv_tax_code             IN VARCHAR2,    -- 3.�ŃR�[�h(IN)
    iv_incr_decr            IN VARCHAR2,    -- 4.�������R(IN)
    iv_slip_num             IN VARCHAR2,    -- 5.�`�[�ԍ�(IN)
    iv_dept                 IN VARCHAR2,    -- 6.�N�[����(IN)
    iv_input_user           IN VARCHAR2,    -- 7.���͎�(IN)
    iv_adj_slip_num         IN VARCHAR2,    -- 8.�C�����`�[�ԍ�(IN)
    ir_rowid                IN ROWID,       -- 9.ROWID(IN)
    iv_je_soruce            IN VARCHAR2,    -- 10.�d��\�[�X��(IN)
    iv_app_ref              IN VARCHAR2,    -- 11.�����Q��(IN)
--Ver1.2 Add Start  �d�l�ύX�ɂ��ǉ�
    iv_context_name         IN VARCHAR2,    -- 12.��v����(�R���e�L�X�g)��(IN)
--Ver1.2 Add End
--Ver1.3 Add Start  �d�l�ύX�ɂ��ǉ�
    iv_reserve1             IN VARCHAR2,    -- 13.�\���P(IN)
    iv_reserve2             IN VARCHAR2,    -- 14.�\���Q(IN)
--Ver1.3 Add end
    ov_errbuf               OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    xx00_file_pkg.log(' ');
    --GL�C���^�[�t�F�[�X�O���[�vID�擾
    SELECT TO_NUMBER(attribute1)
    INTO   ln_group_id
    FROM   gl_je_sources_tl
    WHERE  user_je_source_name = iv_je_soruce
    AND    language = xx00_global_pkg.current_language;
--
    --GL�C���^�[�t�F�[�X�X�V����
    UPDATE gl_interface
    SET    reference4 = iv_je_name,         -- �d��
           reference10 = iv_slip_desc,      -- ���דE�v
           attribute1 = iv_tax_code,        -- �ŃR�[�h
           attribute2 = iv_incr_decr,       -- �������R
           attribute3 = iv_slip_num,        -- �`�[�ԍ�
           attribute4 = iv_dept,            -- �N�[����
           attribute5 = iv_input_user,      -- ���͎�
           attribute6 = iv_adj_slip_num,    -- �C�����`�[�ԍ�
           jgzz_recon_ref = iv_app_ref,     -- �����Q��
-- Ver.1.3 add �O���[�vID��DFF�ǉ�
           group_id = ln_group_id,          -- �O���[�vID
-- Ver.1.3 add end
-- Ver.1.3 add �\���P�A�\���Q��DFF�ǉ�
           attribute9 = iv_reserve1,        -- �\���P
           attribute10 = iv_reserve2,       -- �\���Q
-- Ver.1.3 add end
-- Ver.1.2 add �d�l�ǉ��@�R���e�L�X�g�l�Ƃ��ĉ�v���떼
           context = iv_context_name        -- �R���e�L�X�g
-- Ver.1.2 add end
    WHERE  ROWID = ir_rowid;
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
  /**********************************************************************************
   * Procedure Name   : get_buying_in_invoices
   * Description      : �d��������DFF�l�X�V (A3-1)
   ***********************************************************************************/
  PROCEDURE get_buying_in_invoices(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    iv_journal_type             IN VARCHAR2,    -- 2.�d�󖾍׉Ȗڃ^�C�v(IN)
    in_entered_dr               IN NUMBER,      -- 3.�ؕ����z(IN)
    in_invoice_id               IN NUMBER,      -- 4.������ID(IN)
    in_dist_line_number         IN NUMBER,      -- 5.���������הԍ�(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 6.�d��(IN OUT)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--    iov_slip_desc               IN OUT VARCHAR2,   -- 7.���דE�v(IN OUT)
--Ver1.3 Del end
    iov_tax_code                IN OUT VARCHAR2,   -- 7.�ŃR�[�h(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,   -- 8.�������R(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 9.�`�[�ԍ�(IN OUT)
    iov_dept                    IN OUT VARCHAR2,   -- 10.�N�[����(IN OUT)
    iov_input_user              IN OUT VARCHAR2,   -- 11.���͎�(IN OUT)
    iov_adj_slip_num            IN OUT VARCHAR2,   -- 12.�C�����`�[�ԍ�(IN OUT)
    iov_app_ref                 IN OUT VARCHAR2,   -- 13.�����p�ƍ��L�[(IN OUT)
--Ver1.3 Add Start  �d�l�ύX�ɂ��ǉ�
    iov_reserve1                IN OUT VARCHAR2,   -- 14.�\���P(IN OUT)
    iov_reserve2                IN OUT VARCHAR2,   -- 15.�\���Q(IN OUT)
--Ver1.3 Add end
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_buying_in_invoices'; -- �v���O������
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
    xx00_file_pkg.log('journal_type=' || iv_journal_type);
    xx00_file_pkg.log('entered_dr=' || TO_CHAR(in_entered_dr));
--Ver1.3 change Start �d�l�ύX�ɂ��ύX
-- ���d�l 2004/03/03
-- �d�󖾍׃J�e�S�����u�d���������v�̏ꍇ�ȉ��̍��ڂ�ݒ肷��
-- �E�`�[�ԍ��A�N�[����A�d�󖼁A���͎ҁA�C�����`�[�ԍ�
-- ���ׂ����s�ȊO�̏ꍇ�A�ȉ��̍��ڂ��ݒ肷��B
-- �E�ŃR�[�h�A�������R�A�\���P�A�\���Q�A�����p�ƍ��L�[(�����Q��)
-- ���ׂ����s�ł��邩�ۂ��͎d�󖾍׉Ȗڃ^�C�v��������AP(LIABILITY)��
-- ������̂����s�Ƃ���B
    -- =============================================================
    -- �`�[�ԍ��A�N�[����A�d�󖼁A���͎ҁA�C�����`�[�ԍ��̐ݒ� 
    -- (A-3-1-2�AA-3-1-4�AA-3-1-5)
      -- ���ݒ肷��DFF�l�𓯂��e�[�u���̓����L�[�ɂ���Č�������̂�
      -- �@�p�t�H�[�}���X����(DB�A�N�Z�X����)�ׁ̈A
      -- �@�ȉ��Q�̊֐�����ɂ܂Ƃ߂�
      --  �Eproc_slip_num_and_others
      --  �Eproc_adj_slip_num
      -- ============================================================
    proc_slip_num_and_others(
      in_org_id,                     -- 1.�I���OID(IN)
      in_invoice_id,                 -- 2.������ID(IN)
      iov_slip_num,                  -- 3.�`�[�ԍ�(IN OUT)
      iov_je_name,                   -- 4.�d��(IN OUT)
      iov_dept,                      -- 5.�N�[����(IN OUT)
      iov_input_user,                -- 6.���͎�(IN OUT)
--Ver1.3 add Start    �֐������̈גǉ�
      iov_adj_slip_num,              -- 7.�C�����`�[�ԍ�(IN OUT)
--Ver1.3 add end
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
--Ver1.4 change start
    -- ���ׂ����s(�d�󖾍׉Ȗڃ^�C�v��������AP)�ȊO���̔��f
    -- 2004/03/19 ���s(LIABILITY)�ȊO�Ɉב֍��v(GAIN)�A�ב֍���(LOSS)�A
    --            �����s(WRITEOFF)�ɂ��ŃR�[�h�A�������R�A�\���P����
    --            �t���̕K�v������(�ł��Ȃ�)�ׁA��L�̍s�ɕt��������
    --            �s��Ȃ�(��p�A����ŁA�O�����ɍs��)�悤�ɔ��f����ύX�B
    --IF iv_journal_type <> 'LIABILITY' THEN
    IF iv_journal_type = 'CHARGE' OR
      iv_journal_type = 'NONRECOVERABLE TAX' OR
-- Ver11.5.10.1.4B add start
      iv_journal_type = 'AP ACCRUAL' OR
      iv_journal_type = 'RECOVERABLE TAX' OR
-- Ver11.5.10.1.4B add end
      iv_journal_type = 'PREPAY' THEN
--Ver1.4 change END
      -- ============================================================
      -- �ŃR�[�h�A�������R(A-3-1-1)�A
      -- �\���P�A�\���Q�A�����p�ƍ��L�[�̐ݒ� (A-3-1-6)
      -- ���ݒ肷��DFF�l�𓯂��e�[�u���̓����L�[�ɂ���Č�������̂�
      -- �@�p�t�H�[�}���X����(DB�A�N�Z�X����)�ׁ̈A
      -- �@�ȉ��Q�̊֐�����ɂ܂Ƃ߂�
      --  �Eproc_tax_incr_decr_dff_values
      --  �Eproc_app_ref_dff_values
      -- ============================================================
--Ver1.5 add start
      -- 2004/03/26 �O�����s���A���������הԍ��������Ȃ��`�[(�����쐬�`�[)��
      --            ���LDFF�t���������s���Ȃ��ׁA���������הԍ������s�̂�
      --            ���LDFF�t���������s���d�l�ǉ�
      IF in_dist_line_number IS NOT NULL THEN
        proc_dff_values_not_liability(
          in_org_id,                    -- 1.�I���OID(IN)
          in_invoice_id,                -- 2.������ID(IN)
          in_dist_line_number,          -- 3.���������הԍ�(IN)
          iov_tax_code,                 -- 4.�ŃR�[�h(IN OUT)
          iov_incr_decr,                -- 5.�������R(IN OUT)
          iov_app_ref,                  -- 6.�����p�ƍ��L�[(IN OUT)
          iov_reserve1,                 -- 7.�\���P(IN OUT)
          iov_reserve2,                 -- 8.�\���Q(IN OUT)
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
--Ver1.5 add End
    END IF;
/*
    -- �d�󖾍׉Ȗڃ^�C�v��������AP�A�O�����ȊO���̔��f
    IF iv_journal_type <> 'LIABILITY' AND iv_journal_type <> 'PREPAY' THEN
      -- =====================================
      -- �ŃR�[�h�A�������R�̐ݒ� (A-3-1-1)
      -- =====================================
      proc_tax_incr_decr_dff_values(
        in_org_id,                    -- 1.�I���OID(IN)
        in_invoice_id,                -- 2.������ID(IN)
        in_dist_line_number,          -- 3.���������הԍ�(IN)
        iov_tax_code,                  -- 4.�ŃR�[�h(IN OUT)
        iov_incr_decr,                 -- 5.�������R(IN OUT)
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
--
    -- �d�󖾍׉Ȗڃ^�C�v���O�����ȊO���ؕ����z��NULL�ł��邩�̔��f
    IF iv_journal_type <> 'PREPAY' AND in_entered_dr IS NULL THEN
      -- =====================================
      -- �C�����`�[�ԍ��̐ݒ� (A-3-1-2)
      -- =====================================
      proc_adj_slip_num(
        in_org_id,                    -- 1.�I���OID(IN)
        in_invoice_id,                -- 2.������ID(IN)
        iov_adj_slip_num,             -- 3.�C�����`�[�ԍ�(IN OUT)
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
    END IF;
--
    -- �d�󖾍׉Ȗڃ^�C�v��������AP�A����ňȊO���ؕ����z��NULL�ł��邩�̔��f
--    IF iv_journal_type <> 'LIABILITY' AND     -- Ver1.2 DEL
      IF iv_journal_type <> 'LIABILITY' AND     -- Ver1.2 change
       iv_journal_type <> 'NONRECOVERABLE TAX' AND 
       in_entered_dr IS NULL THEN
      -- =====================================
      -- ���דE�v�̐ݒ� (A-3-1-3)
      -- =====================================
      proc_detail_desc(
        in_org_id,                    -- 1.�I���OID(IN)
        in_invoice_id,                -- 2.������ID(IN)
        iov_slip_desc,                -- 3.���דE�v(IN OUT)
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
      -- �d�l�ǉ�2004.1.20
      -- =====================================
      -- �����Q�Ƃ̐ݒ� (A-3-1-6)
      -- =====================================
      proc_app_ref_dff_values(
        in_org_id,                    -- 1.�I���OID(IN)
        in_invoice_id,                -- 2.������ID(IN)
        in_dist_line_number,          -- 3.���������הԍ�(IN)
        iov_app_ref,                  -- 4.�����Q��(IN OUT)
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
    END IF;
--
    -- ==============================================
    -- �`�[�ԍ��A���̑����ڂ̐ݒ� (A-3-1-4�AA-3-1-5)
    -- ==============================================
    proc_slip_num_and_others(
      in_org_id,                     -- 1.�I���OID(IN)
      in_invoice_id,                 -- 2.������ID(IN)
      iov_slip_num,                  -- 3.�`�[�ԍ�(IN OUT)
      iov_je_name,                   -- 4.�d��(IN OUT)
      iov_dept,                      -- 5.�N�[����(IN OUT)
      iov_input_user,                -- 6.���͎�(IN OUT)
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
*/
--Ver1.3 change End
    --���O�o��
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
  END get_buying_in_invoices;
  /**********************************************************************************
   * Procedure Name   : get_payment
   * Description      : �x��������DFF�l�X�V (A-3-2)
   ***********************************************************************************/
  PROCEDURE get_payment(
    in_org_id                   IN NUMBER,      -- 1.�I���OID(IN)
    iv_journal_type             IN VARCHAR2,    -- 2.�d�󖾍׉Ȗڃ^�C�v(IN)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--    in_entered_dr               IN NUMBER,      -- 3.�ؕ����z(IN)
--    in_entered_cr               IN NUMBER,      -- 4.�ݕ����z(IN)
--Ver1.3 Del End
    in_payment_id               IN NUMBER,        -- 3.�������x��ID(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 4.�d��(IN OUT)
    iov_slip_desc               IN OUT VARCHAR2,   -- 5.���דE�v(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 6.�`�[�ԍ�(IN OUT)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--    iov_adj_slip_num            IN OUT VARCHAR2,   -- 9.�C�����`�[�ԍ�(IN OUT)
--Ver1.3 Del End
    in_check_id                 IN NUMBER,        -- 7.�x���o�b�`���`�F�b�NID(IN)
--Ver1.6 add Start ������ID��invoice_id(reference22)���g�p����גǉ�
    iv_invoice_id               IN VARCHAR2,      -- 8.������ID(IN)
--Ver1.6 add End
    ov_errbuf                   OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment'; -- �v���O������
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
-- Ver1.2 �d�l�ύX Del Start
--  ln_check_id   ap_invoice_payments_all.check_id%TYPE; -- �x���o�b�`���`�F�b�NID
-- Ver1.2 �d�l�ύX Del End
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
--Ver1.3 change Start �d�l�ύX�ɂ��ύX
-- ���d�l 2004/03/03
-- �d�󖾍׃J�e�S�����u�x���v�̏ꍇ�ȉ��̍��ڂ�ݒ肷��B
-- �E�`�[�ԍ��A�d�󖼁A���דE�v
-- ���ׂ��x���a���s���x�����s���Ŗ��דE�v�ɐݒ肷�鍀�ڂ��قȂ�B
-- �E�x���a���s(�a��)�̏ꍇ�A���דE�v�Ɏx���o�b�`����ݒ肷��B
-- �E�x�����s(�ב֍����v�A�萔���A��)�̏ꍇ�A���דE�v�Ɏx���o�b�`����ݒ肷��B
-- ���ׂ��a���s�ł��邩�ۂ��͎d�󖾍׉Ȗڃ^�C�v���a��(CASH CLEARING)��
-- ������̂�a���s�Ƃ��A�ȊO�����s�Ƃ���B
-- �x���Ǝx������̍s�͔��ʕs�\�̈׋�ʂ����A�a���s�ƍ��s�̏ꍇ��
-- �x���Ɠ��l�Ɉ����B
-- ���d�l 2004/03/19
-- �E�[�������s(ROUNDING)�͗a���s�Ɠ��l�̏������s���B
    -- ==============================================
    -- �`�[�ԍ��A�d�󖼏̂̐ݒ� (A-3-2-1)
    -- ==============================================
    proc_slip_num_journal_name(
      in_org_id,                    -- 1.�I���OID(IN)
--      ln_check_id,                  -- 2.�`�F�b�NID(IN) -- Ver1.2 �d�l�ύX Del 
      in_check_id,                  -- 2.�`�F�b�NID(IN)   -- Ver1.2 �d�l�ύX add 
      in_payment_id,                -- 3.�������x��ID(IN)
      iov_slip_num,                 -- 4.�`�[�ԍ�(IN OUT)
      iov_je_name,                  -- 5.�d��(IN OUT)
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
    -- �x���a��(�d�󖾍׉Ȗڃ^�C�v���a��)�ł��邩�̔��f
--Ver1.4 change start �[�������s�ł���ꍇ�����דE�v�Ɏx���o�b�`����t������ׁA
--                    ���f����ύX
--Ver1.7 change start ���f�����ɗa��(CASH)�̏ꍇ���ǉ�
--    IF iv_journal_type = 'CASH CLEARING' THEN
--    IF iv_journal_type = 'CASH CLEARING' OR iv_journal_type = 'ROUNDING' THEN
    IF iv_journal_type = 'CASH CLEARING' 
       OR iv_journal_type = 'ROUNDING' 
--Ver11.5.10.1.4C Change START
--       OR iv_journal_type = 'CASH' THEN
       OR iv_journal_type = 'CASH'
       OR iv_journal_type = 'FUTURE PAYMENT' THEN
--Ver11.5.10.1.4C Change END
--Ver1.7 change end
--Ver1.4 change END
      -- =====================================
      -- ���דE�v(�x���F�a��)�̐ݒ� (A-3-2-3)
      -- =====================================
      proc_detail_desc_desposit(
        in_org_id,                    -- 1.�I���OID(IN)
--        ln_check_id,                  -- 2.�`�F�b�NID(IN) -- Ver1.2 �d�l�ύX Del 
        in_check_id,                  -- 2.�`�F�b�NID(IN)   -- Ver1.2 �d�l�ύX add 
        in_payment_id,                -- 3.�������x��ID(IN)
        iov_slip_desc,                -- 4.���דE�v(IN OUT)
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
    ELSE
      -- �x�����s�̏���
      -- =========================================
      -- ���דE�v(�x���F��)�̐ݒ� (A-3-2-2)
      -- =========================================
      proc_detail_desc_unpaid(
        in_org_id,                    -- 1.�I���OID(IN)
        in_payment_id,                -- 2.�������x��ID(IN)
        iov_slip_desc,                -- 3.���דE�v(IN OUT)
-- Ver1.6 add start �������x��ID���琿����ID�����������AGL_INTERFACE�̐�����ID��
--                  ���̂܂܎g�p����
        TO_NUMBER(iv_invoice_id),     -- 4.������ID(IN)
-- Ver1.6 add end
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
/*
    xx00_file_pkg.log('journal_type=' || iv_journal_type);
    xx00_file_pkg.log('entered_dr=' || TO_CHAR(in_entered_dr));
    xx00_file_pkg.log('entered_cr=' || TO_CHAR(in_entered_cr));
    xx00_file_pkg.log('select ap_invoice_payments_all');
    xx00_file_pkg.log('key invoice_payment_id=' || TO_CHAR(in_payment_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
*/
-- Ver1.2 �d�l�ύX Del Start
/*
    -- �x���o�b�`���̃`�F�b�NID���擾����B
      SELECT  aip.check_id AS check_id    -- �x���o�b�`ID
      INTO    ln_check_id
      FROM    ap_invoice_payments_all aip
      WHERE   aip.invoice_payment_id = in_payment_id
      AND     aip.org_id = in_org_id;
      xx00_file_pkg.log('get check_id=' || TO_CHAR(ln_check_id));
*/
-- Ver1.2 �d�l�ύX Del End
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del Start
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del End
--
/*
    -- ����(�d�󖾍׉Ȗڃ^�C�v��������AP���ؕ����z��NULL�ł͂Ȃ�)���̔��f
    IF iv_journal_type = 'LIABILITY' AND in_entered_dr IS NOT NULL THEN
      -- =========================================
      -- ���דE�v(�x���F������AP)�̐ݒ� (A-3-2-2)
      -- =========================================
      proc_detail_desc_unpaid(
        in_org_id,                    -- 1.�I���OID(IN)
        in_payment_id,                -- 2.�������x��ID(IN)
        iov_slip_desc,                -- 3.���דE�v(IN OUT)
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
--
    -- �a��(�d�󖾍׉Ȗڃ^�C�v��������AP�ȊO���ݕ����z��NULL�ł͂Ȃ�)���̔��f
    ELSIF iv_journal_type <> 'LIABILITY' AND in_entered_cr IS NOT NULL THEN
      -- =====================================
      -- ���דE�v(�x���F�a��)�̐ݒ� (A-3-2-3)
      -- =====================================
      proc_detail_desc_desposit(
        in_org_id,                    -- 1.�I���OID(IN)
--        ln_check_id,                  -- 2.�`�F�b�NID(IN) -- Ver1.2 �d�l�ύX Del 
        in_check_id,                  -- 2.�`�F�b�NID(IN)   -- Ver1.2 �d�l�ύX add 
        in_payment_id,                -- 3.�������x��ID(IN)
        iov_slip_desc,                -- 4.���דE�v(IN OUT)
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
--
--Ver1.2 add Start 
    -- �d�l�ύX�B�d�󖾍׉Ȗڃ^�C�v��������AP�ȊO�ł���
    -- �ݕ����z��NULL��������0�ł���ꍇ�x������Ƃ���B
    IF iv_journal_type <> 'LIABILITY' AND NVL(in_entered_cr,0) = 0 THEN
      -- =====================================
      -- �C�����`�[�ԍ�(�x�����)�̐ݒ� (A-3-2-4)
      -- =====================================
      proc_adj_slip_num_cancel(
        in_org_id,                    -- 1.�I���OID(IN)
  --      ln_check_id,                  -- 2.�`�F�b�NID(IN) -- Ver1.2 �d�l�ύX Del 
        in_check_id,                  -- 2.�`�F�b�NID(IN)   -- Ver1.2 �d�l�ύX add 
        in_payment_id,                -- 3.�������x��ID(IN)
        iov_adj_slip_num,             -- 4.�C�����`�[�ԍ�(IN OUT)
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
--Ver1.2 add End
--
*/
--Ver1.3 change End
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
-- Ver1.2 �d�l�ύX Del Start
/*
    WHEN NO_DATA_FOUND THEN                       --*** �x���o�b�`�����擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      --�G���[���b�Z�[�W�擾
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --�A�v���P�[�V�����Z�k��
        'APP-XX03-06017'); -- ���b�Z�[�W�敪(�x��)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      IF iv_journal_type = 'LIABILITY' AND in_entered_dr IS NOT NULL THEN
        lv_errbuf := xx00_message_pkg.get_msg(
          'XX03',  --�A�v���P�[�V�����Z�k��
          'APP-XX03-06006',
          'TOK_XX03_DFF_KEY',
          in_payment_id);
      ELSE
        lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
          'XX03',  --�A�v���P�[�V�����Z�k��
          'APP-XX03-06012',
          'TOK_XX03_DFF_KEY',
          in_payment_id);
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# �C�� #
*/
-- Ver1.2 �d�l�ύX Del End
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
  END get_payment;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data
   * Description      : DFF�t���Ώۃf�[�^���o���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data(
    in_gl_book_id           IN NUMBER,       --   1.��v���뒠��ID(IN)
    in_org_id               IN NUMBER,       --   2.�I���OID(IN)
    iv_buyning_in_invoice   IN VARCHAR2,     --   3.�d��J�e�S����(�d��������)(IN)
    iv_payment_type         IN VARCHAR2,     --   4.�d��J�e�S����(�x��)(IN)
    iv_je_soruce            IN VARCHAR2,     --   5.�d��\�[�X��(IN)
    ion_buyning_cnt         IN OUT NUMBER,   --   6.�d��J�e�S���ʌ���(�d��������)(OUT)
    ion_payment_cnt         IN OUT NUMBER,   --   7.�d��J�e�S���ʌ���(�x��)(OUT)
    ov_errbuf               OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data'; -- �v���O������
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
    lv_context_name  gl_interface.context%TYPE;   -- Ver1.2 add �R���e�L�X�g�l
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\��
    CURSOR gl_add_dff_data_cur
    IS
      SELECT  gi.rowid AS row_id,                 -- ROWID
              gi.user_je_category_name 
                AS user_je_category_name,         -- �d��J�e�S����
              gi.reference22 AS invoice_id,       -- ������ID
-- Ver1.2 del Start
--            gi.reference23 AS dist_line_number, -- ���������הԍ�
-- Ver1.2 del End
-- Ver1.2 add Start
              gi.reference23 AS line_number_or_check_id,   -- ���������הԍ�/�x���o�b�`���`�F�b�NID
-- Ver1.2 add End
              gi.reference29 AS payment_id,       -- �������x��ID
              gi.reference30 AS journal_type,     -- �d�󖾍׉Ȗڃ^�C�v
              gi.entered_dr AS entered_dr,        -- �ؕ����z
              gi.entered_cr AS entered_cr,        -- �ݕ����z
              gi.reference4 AS je_name,           -- �d��
              gi.reference10 AS slip_desc,        -- ���דE�v
              gi.attribute1 AS tax_code,          -- �ŃR�[�h
              gi.attribute2 AS incr_decr,         -- �������R
              gi.attribute3 AS slip_num,          -- �`�[�ԍ�
              gi.attribute4 AS dept,              -- �N�[����
              gi.attribute5 AS input_user,        -- ���͎�
              gi.attribute6 AS adj_slip_num,      -- �C�����`�[�ԍ�
-- Ver1.3 add Start   �d�l�ǉ��̈גǉ�
              gi.attribute9 AS reserve1,          -- �\���P
              gi.attribute10 AS reserve2,         -- �\���Q
-- Ver1.3 add Start
              gi.jgzz_recon_ref AS app_ref        -- �����Q��
      FROM    gl_interface gi                         --GL�C���^�[�t�F�[�X
      WHERE   gi.user_je_source_name = iv_je_soruce   --�d��\�[�X���͔��|�Ǘ�
      AND     gi.set_of_books_id = in_gl_book_id      --��v����ID�̓v���t�@�C���̒l
      AND     gi.status = 'NEW'                       --�X�e�[�^�X�͐V�K
      AND     gi.actual_flag = 'A'                    --�\���t���O�͎���
      AND     gi.context IS NULL                      --�R���e�L�X�g�l��NULL
      ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�J�[�\�����R�[�h�^
    gl_add_dff_data_rec gl_add_dff_data_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('source :' || iv_je_soruce);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_BUYING_IN_INVOICE : ' || iv_buyning_in_invoice);
    xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || iv_payment_type);
    xx00_file_pkg.log(' ');
-- Ver1.2 add Start
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
-- Ver1.2 add End
    --GL�C���^�[�t�F�[�XDFF�Z�b�g�l�t���Ώێ擾�̎擾
    --�J�[�\���I�[�v��
    OPEN gl_add_dff_data_cur;
    <<interface_loop>>
    LOOP
      FETCH gl_add_dff_data_cur INTO gl_add_dff_data_rec;
      --GL_INTERFACE�擾�`�F�b�N
      IF gl_add_dff_data_cur%NOTFOUND THEN
          EXIT interface_loop;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec.user_je_category_name);
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del Start
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del End
      -- �d��J�e�S�����̔��f
      IF gl_add_dff_data_rec.user_je_category_name = iv_buyning_in_invoice THEN
        -- ===================================
        -- �d��������DFF�l�Z�b�g�̎擾 (A-3-1)
        -- ===================================
        get_buying_in_invoices(
          in_org_id,                                      -- 1.�I���OID(IN)
          gl_add_dff_data_rec.journal_type,               -- 2.�d�󖾍׉Ȗڃ^�C�v(IN)
          gl_add_dff_data_rec.entered_dr,                 -- 3.�ؕ����z(IN)
          TO_NUMBER(gl_add_dff_data_rec.invoice_id),        -- 4.������ID(IN)
--Ver1.2 change Start
          TO_NUMBER(gl_add_dff_data_rec.line_number_or_check_id),  -- 5.���������הԍ�(IN)
--Ver1.2 change End
          gl_add_dff_data_rec.je_name,                    -- 6.�d��(IN OUT)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--          gl_add_dff_data_rec.slip_desc,                  -- 7.���דE�v(IN OUT)
--Ver1.3 Del end
          gl_add_dff_data_rec.tax_code,                   -- 7.�ŃR�[�h(IN OUT)
          gl_add_dff_data_rec.incr_decr,                  -- 8.�������R(IN OUT)
          gl_add_dff_data_rec.slip_num,                   -- 9.�`�[�ԍ�(IN OUT)
          gl_add_dff_data_rec.dept,                       -- 10.�N�[����(IN OUT)
          gl_add_dff_data_rec.input_user,                 -- 11.���͎�(IN OUT)
          gl_add_dff_data_rec.adj_slip_num,               -- 12.�C�����`�[�ԍ�(IN OUT)
          gl_add_dff_data_rec.app_ref,                    -- 13.�����p�ƍ��L�[(IN OUT)
--Ver1.3 Add Start  �d�l�ύX�ɂ��ǉ�
          gl_add_dff_data_rec.reserve1,                   -- 14.�\���P(IN OUT)
          gl_add_dff_data_rec.reserve2,                   -- 15.�\���Q(IN OUT)
--Ver1.3 Add end
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
        ion_buyning_cnt := ion_buyning_cnt + 1;             -- �d��������DFF���������̌v��
      ELSIF gl_add_dff_data_rec.user_je_category_name = iv_payment_type THEN
        -- ===================================
        -- �x��DFF�l�Z�b�g�̎擾 (A-3-2)
        -- ===================================
        get_payment(
          in_org_id,                                    -- 1.�I���OID(IN)
          gl_add_dff_data_rec.journal_type,             -- 2.�d�󖾍׉Ȗڃ^�C�v(IN)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--          gl_add_dff_data_rec.entered_dr,               -- 3.�ؕ����z(IN)
--          gl_add_dff_data_rec.entered_cr,               -- 4.�ݕ����z(IN)
--Ver1.3 Del End
          gl_add_dff_data_rec.payment_id,               -- 3.�������x��ID(IN)
          gl_add_dff_data_rec.je_name,                  -- 4.�d��(IN OUT)
          gl_add_dff_data_rec.slip_desc,                -- 5.���דE�v(IN OUT)
          gl_add_dff_data_rec.slip_num,                 -- 6.�`�[�ԍ�(IN OUT)
--Ver1.3 Del Start  �d�l�ύX�ɂ��s�v�ƂȂ����̂ō폜
--          gl_add_dff_data_rec.adj_slip_num,             -- 9.�C�����`�[�ԍ�(IN OUT)
--Ver1.3 Del End
--Ver1.2 add Start
          gl_add_dff_data_rec.line_number_or_check_id,  -- 7.�x���o�b�`���`�F�b�NID(IN)
--Ver1.2 add End
--Ver1.6 add Start ������ID��invoice_id(reference22)���g�p����悤�ɕύX
          gl_add_dff_data_rec.invoice_id,               -- 8.������ID(IN)
--Ver1.6 add End
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
        ion_payment_cnt := ion_payment_cnt + 1;           -- �x��DFF���������̌v��
      END IF;
--
      -- ===================================
      -- �d��f�[�^�̍X�V���� (A-4)
      -- ===================================
      upd_journal_data(
        gl_add_dff_data_rec.je_name,          -- 1.�d��(IN)
        gl_add_dff_data_rec.slip_desc,        -- 2.���דE�v(IN)
        gl_add_dff_data_rec.tax_code,         -- 3.�ŃR�[�h(IN)
        gl_add_dff_data_rec.incr_decr,        -- 4.�������R(IN)
        gl_add_dff_data_rec.slip_num,         -- 5.�`�[�ԍ�(IN)
        gl_add_dff_data_rec.dept,             -- 6.�N�[����(IN)
        gl_add_dff_data_rec.input_user,       -- 7.���͎�(IN)
        gl_add_dff_data_rec.adj_slip_num,     -- 8.�C�����`�[�ԍ�(IN)
        gl_add_dff_data_rec.row_id,           -- 9.ROWID(IN)
        iv_je_soruce,                         -- 10.�d��\�[�X��(IN)
        gl_add_dff_data_rec.app_ref,          -- 11.�����Q��(IN)
--Ver1.2 Add Start  �d�l�ύX�ɂ��ǉ�
        lv_context_name,                      -- 12.��v���떼(IN)
--Ver1.2 Add end
--Ver1.3 Add Start  �d�l�ύX�ɂ��ǉ�
        gl_add_dff_data_rec.reserve1,         -- 13.�\���P(IN OUT)
        gl_add_dff_data_rec.reserve2,         -- 14.�\���Q(IN OUT)
--Ver1.3 Add end
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
--
    END LOOP interface_loop;
    --���O�o��
    CLOSE gl_add_dff_data_cur;
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
  END get_add_dff_data;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add Start
  /**********************************************************************************
   * Procedure Name   : upd_reference10
   * Description      : ���t�@�����X10�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_reference10(
    iv_je_source       IN  VARCHAR2,  -- �d��\�[�X��
    in_gl_book_id      IN  NUMBER,    -- ��v���뒠��ID
    iv_payment_type    IN  VARCHAR2,  -- �d��J�e�S����(�x��)
    ov_errbuf          OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_reference10'; -- �v���O������
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
    cv_ref10_ap           CONSTANT VARCHAR2(12) := '_���|���x��_';               -- ���t�@�����X10_���|���x��
    cv_ref25_mfg          CONSTANT VARCHAR2(4)  := 'MFG%';                       -- ���t�@�����X25_�������ԍ�MFG
    cv_ref30_liability    CONSTANT VARCHAR2(10) := 'LIABILITY';                  -- ���t�@�����X30_��
    cv_ref30_discount     CONSTANT VARCHAR2(10) := 'DISCOUNT';                   -- ���t�@�����X30_��s�萔��
    cn_number_1           CONSTANT NUMBER       := 1;
    cn_number_240         CONSTANT NUMBER       := 240;
--
    -- �G���[���b�Z�[�W�p�萔
    cv_msg_kbn_cfo        CONSTANT VARCHAR2(5)  := 'XXCFO';                      -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
    cv_gl_interface_name  CONSTANT VARCHAR2(30) := 'GL�C���^�t�F�[�X�e�[�u��';   -- �G���[���b�Z�[�W�p�e�[�u����
--
    -- ���b�Z�[�W�ԍ�
    cv_msg_cfo1_0019      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';           -- �f�[�^���b�N�G���[���b�Z�[�W
    cv_msg_cfo1_0053      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00053';           -- ���������擾�G���[���b�Z�[�W
    cv_msg_cfo1_0020      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';           -- �f�[�^�X�V�G���[���b�Z�[�W
--
    -- �g�[�N��
    cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';                      -- �g�[�N���F�e�[�u����
    cv_tkn_invoice_num    CONSTANT VARCHAR2(20) := 'INVOICE_NUM';                -- �g�[�N���F�������ԍ�
    cv_tkn_errmsg         CONSTANT VARCHAR2(10) := 'ERRMSG';                     -- �g�[�N���F�G���[���e
--
    -- �X�e�[�^�X�E�R�[�h
    cv_status_normal      CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
    cv_status_warn        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
--
    -- �p�b�P�[�W��
    cv_pkg_name           CONSTANT VARCHAR2(100) := 'XX032JU001C';
--
    cv_msg_part           CONSTANT VARCHAR2(3) := ' : ';
    cv_msg_cont           CONSTANT VARCHAR2(3) := '.';
--
    -- *** ���[�J���ϐ� ***
    ln_count                 NUMBER       DEFAULT 0;           -- ���o�����̃J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
    -- GL�C���^�t�F�[�X�e�[�u���̃��b�N�p�J�[�\��
    CURSOR  gl_interface_lock_cur
    IS
      SELECT gi.rowid         row_id         -- ROWID
            ,gi.reference10   description    -- ���t�@�����X10�i�E�v�j
            ,gi.reference25   invoice_num    -- ���t�@�����X25�i�������ԍ��j
      FROM   gl_interface        gi
      WHERE  gi.user_je_source_name   = iv_je_source        -- �d��\�[�X��
      AND    gi.group_id              = (
                                         SELECT TO_NUMBER(gjst.attribute1)  group_id     -- �O���[�vID
                                         FROM   gl_je_sources_tl      gjst     -- �d��\�[�X�e�[�u��
                                         WHERE  gjst.user_je_source_name = iv_je_source                       -- �d��\�[�X��
                                         AND    gjst.language            = xx00_global_pkg.current_language   -- ����
                                        )                   -- �O���[�vID
      AND    gi.set_of_books_id       = in_gl_book_id       -- ��v����ID
      AND    gi.user_je_category_name = iv_payment_type     -- '�x��'
      AND    gi.reference30           IN (cv_ref30_liability  -- ��
                                         ,cv_ref30_discount)  -- ��s�萔��
      AND    gi.reference25           LIKE cv_ref25_mfg     -- �������ԍ�MFG
      AND    gi.reference10           LIKE cv_ref25_mfg     -- �E�v���������ԍ�MFG
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE gl_interface_lock_ttype IS TABLE OF gl_interface_lock_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gl_interface_lock_tab                    gl_interface_lock_ttype;
--
    TYPE reference10_ttype       IS TABLE OF gl_interface.reference10%TYPE INDEX BY PLS_INTEGER;
    reference10_tab                          reference10_ttype;
--
    TYPE description_ttype       IS TABLE OF ap_invoices_all.description%TYPE INDEX BY PLS_INTEGER;
    description_tab                          description_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- 1.GLIF�e�[�u���̐������ԍ����擾���A�Ώۃf�[�^�����b�N���܂��B
      --�J�[�\���I�[�v��
      OPEN gl_interface_lock_cur;
      -- �o���N�t�F�b�`
      FETCH gl_interface_lock_cur BULK COLLECT INTO gl_interface_lock_tab;
      -- �J�[�\���N���[�Y
      IF ( gl_interface_lock_cur%ISOPEN ) THEN
        CLOSE gl_interface_lock_cur;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo1_0019      -- �f�[�^���b�N�G���[���b�Z�[�W
                                                        ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                        ,cv_gl_interface_name  -- GL�C���^�t�F�[�X�e�[�u��
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
    END;
--
    <<interface_loop>>
    FOR ln_count in 1..gl_interface_lock_tab.COUNT LOOP
      -- 2.1�Ŏ擾�����������ԍ������ɁAAP�������e�[�u������E�v���擾���܂��B
      BEGIN
        SELECT aia.description   description  -- �E�v
        INTO   description_tab(ln_count)
        FROM   ap_invoices_all  aia           -- AP�������e�[�u��
        WHERE  aia.invoice_num = gl_interface_lock_tab(ln_count).invoice_num  -- �������ԍ�
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                               -- 'XXCFO'
                                                        ,cv_msg_cfo1_0053                             -- ���������擾�G���[���b�Z�[�W
                                                        ,cv_tkn_invoice_num                           -- �g�[�N��:�������ԍ�
                                                        ,gl_interface_lock_tab(ln_count).invoice_num  -- �������ԍ�
                                                        )
                               ,1
                               ,5000);
          xx00_file_pkg.output(lv_errmsg);
          ov_retcode := cv_status_warn;
      END;
      -- �E�v���擾�ł���ꍇ
      IF ( description_tab.exists(ln_count) ) THEN
        reference10_tab(ln_count) := SUBSTRB( description_tab(ln_count) || cv_ref10_ap || gl_interface_lock_tab(ln_count).invoice_num
                                             ,cn_number_1
                                             ,cn_number_240);
      -- �E�v���擾�ł��Ȃ��ꍇ
      ELSE
        reference10_tab(ln_count) := gl_interface_lock_tab(ln_count).description;
      END IF;
    END LOOP interface_loop;
--
    BEGIN
      FORALL ln_count IN 1..gl_interface_lock_tab.COUNT
        -- 3.GLIF�e�[�u���̑Ώۃf�[�^�̃��t�@�����X10���X�V���܂��B
        UPDATE gl_interface        gi
        SET    gi.reference10 = reference10_tab(ln_count)  -- ���t�@�����X10
        WHERE  gi.rowid = gl_interface_lock_tab(ln_count).row_id   -- ROWID
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo1_0020      -- �f�[�^�X�V�G���[���b�Z�[�W
                                                      ,cv_tkn_table          -- �g�[�N��'TABLE'
                                                      ,cv_gl_interface_name  -- GL�C���^�t�F�[�X�e�[�u��
                                                      ,cv_tkn_errmsg         -- �g�[�N��'ERRMSG'
                                                      ,SQLERRM               -- SQL�G���[���b�Z�[�W
                                                      )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
    --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
    IF ( gl_interface_lock_cur%ISOPEN ) THEN
      CLOSE   gl_interface_lock_cur;
    END IF;
  END upd_reference10;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_journal_source  IN  VARCHAR2,     -- 1.�d��\�[�X��
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
    ln_org_id               NUMBER(15,0);             -- �I���OID
    lv_buyning_in_invoice   VARCHAR2(30);             -- �d��J�e�S����(�d��������)
    lv_payment_type         VARCHAR2(30);             -- �d��J�e�S����(�x��)
    ln_buyning_cnt          NUMBER := 0;              -- �d��J�e�S���ʌ���(�d��������)
    ln_payment_cnt          NUMBER := 0;              -- �d��J�e�S���ʌ���(�x��)
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
      ln_gl_book_id,          -- 1.��v���뒠��ID(OUT)
      ln_org_id,              -- 2.�I���OID(OUT)
      lv_buyning_in_invoice,  -- 3.�d��J�e�S����(�d��������)(OUT)
      lv_payment_type,        -- 4.�d��J�e�S����(�x��)(OUT)
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- DFF�t���Ώۃf�[�^���o���� (A-2)
    -- ===============================
    get_add_dff_data(
      ln_gl_book_id,          -- 1.��v���뒠��ID(IN)
      ln_org_id,              -- 2.�I���OID(IN)
      lv_buyning_in_invoice,  -- 3.�d��J�e�S����(�d��������)(IN)
      lv_payment_type,        -- 4.�d��J�e�S����(�x��)(IN)
      iv_journal_source,      -- 5.�d��\�[�X��(IN)
      ln_buyning_cnt,         -- 6.�d��J�e�S���ʌ���(�d��������)(IN OUT)
      ln_payment_cnt,         -- 7.�d��J�e�S���ʌ���(�x��)(IN OUT)
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSE
      -- ===============================
      -- �v���[�t���X�g�o�͏��� (A-5)
      -- ===============================
      msg_output(
        ln_org_id,              -- 1.�I���OID(IN)
        ln_buyning_cnt,         -- 2.�d��J�e�S���ʌ���(�d��������)(IN)
        ln_payment_cnt,         -- 3.�d��J�e�S���ʌ���(�x��)(IN)
        iv_journal_source,      -- 4.�d��\�[�X��(IN)
        lv_buyning_in_invoice,  -- 5.�d��J�e�S����(�d��������)(IN)
        lv_payment_type,        -- 6.�d��J�e�S����(�x��)(IN)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add Start
    -- ===============================
    -- ���t�@�����X10�X�V(A-6)
    -- ===============================
    upd_reference10(
      iv_journal_source,  -- �d��\�[�X��
      ln_gl_book_id,      -- ��v���뒠��ID
      lv_payment_type,    -- �d��J�e�S����(�x��)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF ( lv_retcode =  xx00_common_pkg.set_status_warn_f ) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add End
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_je_soruce  IN  VARCHAR2)      -- 1.�d��\�[�X��
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
      iv_je_soruce,     -- 1.�d��\�[�X��
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
END XX032JU001C;
/
