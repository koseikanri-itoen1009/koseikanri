create or replace PACKAGE BODY XX034PT001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX034PT001C(body)
 * Description      : ���F�ϕ�����̓f�[�^��AP�W��I/F�ɓ]����A������͓]�������X�V����
 * MD.050           : ������̓o�b�`����(AP)   OCSJ/BFAFIN/MD050/F212
 * MD.070           : ���F�ώd���搿�����̓]�� OCSJ/BFAFIN/MD070/F406
 * Version          : 11.5.10.2.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  vaild_approval         AP�����F�ώd���搿�����f�[�^�̊m�F (A-1)
 *  get_approval_slip_data �o�����F�ώd���搿�����f�[�^�̎擾 (A-2)
 *  ins_ap_interface       API/F�̍X�V (A-3)
 *  ins_ap_interface_lines AP�C���^�[�t�F�[�X(����)�f�[�^�̎擾�Ƒ}�� (A-2�AA-3)
 *  upd_slip_data          AP�]���ώd���搿�����f�[�^�̍X�V (A-4)
 *  msg_output             ���ʏo�� (A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/02/20   1.0            �V�K�쐬
 *  2004/02/27   1.1            �P�̃e�X�g�s��C��
 *  2005/09/05   11.5.10.1.5    �֓d�t�B�[�h�o�b�N�p�t�H�[�}���X�Ή�
 *  2005/11/29   11.5.10.1.6    �p�t�H�[�}���X�Ή��ɂ��q���g��ύX
 *  2007/11/26   11.5.10.2.10   �f�[�^�]���Ɠ]���σt���O�X�V�^�C�~���O�̏C��
 *  2021/12/17   11.5.10.2.11   [E_�{�ғ�_17678]�Ή� �d�q����ۑ��@�����Ή�
 *  2023/08/09   11.5.10.2.12   [E_�{�ғ�_19332]�Ή� �C���{�C�X�Ή�
 *  2023/12/20   11.5.10.2.13   [E_�{�ғ�_19496]�Ή� ���Љ��Ή�
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
  -- *** �O���[�o���萔 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --���ʏo�͗p���t�`��1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --���ʏo�͗p���t�`��2
  cv_appr_status      CONSTANT  xx03_payment_slips.wf_status%TYPE := '80';  -- �o�����F�σX�e�[�^�X
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  vaild_approval_expt       EXCEPTION;              -- AP�����F���������݃G���[
  chk_data_none_expt        EXCEPTION;              -- AP�]���f�[�^���擾�G���[
--
  /**********************************************************************************
   * Procedure Name   : vaild_approval
   * Description      : AP�����F�d���搿�����f�[�^�̊m�F (A-1)
   ***********************************************************************************/
  PROCEDURE vaild_approval(
    on_org_id         OUT NUMBER,       -- 1.�I���OID(OUT)
    on_books_id       OUT NUMBER,       -- 2.��v����ID(OUT)
    ov_currency_code  OUT VARCHAR2,     -- 3.�@�\�ʉ�(OUT)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'vaild_approval'; -- �v���O������
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
    -- �����������F�X�e�[�^�X
    cv_unappr_status      CONSTANT  VARCHAR2(30) := 'UNAPPROVED';
-- 1.1 add start �����F�X�e�[�^�X�̒ǉ�
    cv_nev_appr_status    CONSTANT  VARCHAR2(30) := 'NEVER APPROVED';
    cv_need_reappr_status CONSTANT  VARCHAR2(30) := 'NEEDS REAPPROVAL';
-- 1.1 add end
    -- ��v���ԃX�e�[�^�X(�I�[�v��)
    cv_gl_status_open   CONSTANT  gl_period_statuses.closing_status%TYPE := 'O';
--
    -- *** ���[�J���ϐ� ***
    ln_app_id         fnd_application.application_id%TYPE;    -- �A�v���P�[�V����ID
    ln_data_cnt       NUMBER;                                 -- �폜�Ώۃf�[�^����
    lv_gl_status      gl_period_statuses.closing_status%TYPE; -- ��v�X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_ap_unappr_data_cur
    IS
      SELECT
--Ver 11.5.10.1.5 2005/09/05 Change Start ��v���Ԃ��I�[�v�����Ă�����̂̂ݎ擾����
--Ver 11.5.10.1.5 2005/09/05 Change Start
--Ver 11.5.10.1.6 Change Start
       /*+ ORDERED INDEX(aia XX03_AP_INVOICES_N1)
                   INDEX(gps GL_PERIOD_STATUSES_N1) */
--       /*+ INDEX(aia XX03_AP_INVOICES_N1) */
--Ver 11.5.10.1.6 Change End
--Ver 11.5.10.1.5 2005/09/05 Change End
      aia.gl_date AS gl_date,    -- �v���
-- 1.1 add start �G���[���̃��O��͗p�ɐ������ԍ���ǉ�
              aia.invoice_num AS invoice_num     -- �������ԍ�
-- 1.1 add end
--Ver 11.5.10.1.6 Change Start
--      FROM    ap_invoices_all aia
----Ver 11.5.10.1.5 2005/09/05 Add Start
--              ,gl_period_statuses  gps
----Ver 11.5.10.1.5 2005/09/05 Add End
      FROM    gl_period_statuses  gps
             ,ap_invoices_all     aia
--Ver 11.5.10.1.6 Change End
      WHERE   aia.org_id = on_org_id
      AND     aia.created_by = xx00_global_pkg.created_by
--Ver 11.5.10.1.5 2005/09/05 Add Start
      AND     gps.application_id = ln_app_id
      AND     gps.set_of_books_id = on_books_id
      AND     aia.set_of_books_id = on_books_id
      AND     aia.gl_date >= gps.start_date
      AND     aia.gl_date < gps.end_date + 1
      AND     gps.adjustment_period_flag  != 'Y'
      AND     gps.closing_status = cv_gl_status_open
--Ver 11.5.10.1.5 2005/09/05 Add End
-- 1.1 change start �����F�X�e�[�^�X�̒ǉ��ɂ��ύX
/*
      AND     cv_unappr_status = ap_invoices_pkg.get_approval_status(
        aia.invoice_id,
        aia.invoice_amount,
        aia.payment_status_flag,
        aia.invoice_type_lookup_code);
*/
      AND (
        cv_unappr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code)
        OR
        cv_nev_appr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code)
        OR
        cv_need_reappr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code));
-- 1.1 change end
--Ver 11.5.10.1.5 2005/09/05 Add End
--
    -- *** ���[�J���E���R�[�h ***
    --�`�F�b�N�Ώێ擾�J�[�\�����R�[�h
    get_ap_unappr_data_rec get_ap_unappr_data_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
--
    -- �I���OID�̎擾
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
    -- ��v����ID�̎擾
    on_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
    -- �A�v���P�[�V����ID�̎擾
    ln_app_id := xx03_application_pkg.get_application_id_f('SQLAP');
    -- �@�\�ʉ݂̎擾
    SELECT  gsob.currency_code AS currency_code
    INTO    ov_currency_code
    FROM    gl_sets_of_books gsob
    WHERE   gsob.set_of_books_id = on_books_id;
--
    -- Ver1.1 add start ���O�o��
    xx00_file_pkg.log('org_id = ' || TO_CHAR(on_org_id));
    xx00_file_pkg.log('books_id = ' || TO_CHAR(on_books_id));
    xx00_file_pkg.log('app_id = ' || TO_CHAR(ln_app_id));
    xx00_file_pkg.log('currency_code = ' || ov_currency_code);
    -- Ver1.1 add end
--
    --�폜�Ώێ擾�J�[�\���I�[�v��
    OPEN get_ap_unappr_data_cur;
    <<get_ap_unappr_loop>>
    LOOP
      FETCH get_ap_unappr_data_cur INTO get_ap_unappr_data_rec;
      -- 0������
      IF (get_ap_unappr_data_cur%NOTFOUND) THEN
        EXIT get_ap_unappr_loop;
--Ver 11.5.10.1.5 2005/09/05 Add Start �ꌏ�ȏ�L��ꍇ�̓G���[�������s��
      ELSE
        RAISE vaild_approval_expt;
--Ver 11.5.10.1.5 2005/09/05 Add End
      END IF;
--Ver 11.5.10.1.5 2005/09/05 Delete Start
/*
      -- �v��������v���ԃX�e�[�^�X�̃`�F�b�N
      SELECT  gps.closing_status
      INTO    lv_gl_status
      FROM    gl_period_statuses gps
      WHERE   gps.application_id = ln_app_id
      AND     gps.set_of_books_id = on_books_id
      AND     get_ap_unappr_data_rec.gl_date BETWEEN gps.start_date AND gps.end_date
      AND     gps.adjustment_period_flag  != 'Y';
      -- ��v�X�e�[�^�X���I�[�v���ł���f�[�^�����݂���ꍇ�G���[���b�Z�[�W���o��
      IF lv_gl_status = cv_gl_status_open THEN
        RAISE vaild_approval_expt;
      END IF;
*/
--Ver 11.5.10.1.5 2005/09/05 Delete End
    END LOOP get_ap_unappr_loop;
    CLOSE get_ap_unappr_data_cur;
--
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN vaild_approval_expt THEN        --*** AP�����F���������݃G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08002',                 -- AP�����F���������݃��b�Z�[�W
-- Ver1.1 add start ���O���b�Z�[�W�̃��b�Z�[�W
          'TOK_XX03_INVOICE_NUM',
          get_ap_unappr_data_rec.invoice_num));
-- Ver1.1 add end
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
  END vaild_approval;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_interface_lines
   * Description      : AP�C���^�[�t�F�[�X(����)�f�[�^�̎擾�Ƒ}�� (A-2�AA-3)
   ***********************************************************************************/
  PROCEDURE ins_ap_interface_lines(
    in_invoice_id     IN NUMBER,        -- 1.������ID(IN)
    in_org_id         IN NUMBER,        -- 2.�I���OID(IN)
    id_upd_date       IN DATE,          -- 3.�w�b�_�[�擾����SYSDATE(IN)
    in_updated_by     IN NUMBER,        -- 4.�ŏI�X�V��(IN)
    in_update_login   IN NUMBER,        -- 5.�ŏI���O�C��(IN)
    in_created_by     IN NUMBER,        -- 6.�쐬��(IN)
    on_detail_cnt    OUT NUMBER,        -- 7.���׌���(OUT)
--Ver1.1 add start ���׃L�[(xx03_payment_slips��invoice_id)�̓n���Y��
    in_key_invoice_id IN NUMBER,        -- 8.���׃L�[������ID(IN)
--Ver1.1 add end
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_interface_lines'; -- �v���O������
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
    cv_tax_code_override
      CONSTANT ap_invoice_lines_interface.tax_code_override_flag%TYPE := 'Y';
    cv_type_header CONSTANT VARCHAR2(100) := 'HEADER';
--
    -- *** ���[�J���ϐ� ***
    ln_line_id      ap_invoice_lines_interface.invoice_line_id%TYPE;  -- ����������ID�擾�p
    ln_detail_cnt   NUMBER  :=0;                                      -- ���׌����v��p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_pay_slip_lines_cur
    IS
      SELECT  xpsjlv.invoice_id AS invoice_id,                        -- ������ID
              xpsjlv.line_number * 10 AS line_number,                 -- ���׍s�ԍ�
              xpsjlv.line_type_lookup_code AS line_type_lookup_code,  -- ���׃^�C�v
              xpsjlv.amount AS amount,                                -- ���׋��z
              xpsjlv.description AS description,                      -- ���������ה��l
              xpsjlv.tax_code AS tax_code,                            -- �ŋ敪
              xpsjlv.code_concatenated AS code_concatenated,          -- ����AFF�l
              xpsjlv.code_combination_id AS ccid,                     -- ����AFF CCID
              xpsjlv.incr_decr_reason_code AS incr_decr_reason,       -- �������R
              xpsjlv.recon_reference AS recon_reference,              -- �����Q��
--Ver11.5.10.2.11 add start
              xps.invoice_ele_data_yes AS invoice_ele_data_yes,       -- �������d�q�f�[�^��̂���
--Ver11.5.10.2.11 add end
--Ver11.5.10.2.12 add start
              xps.invoice_t_num_yes    AS invoice_t_num_yes,          -- �K�i������(�C���{�C�X)����
--Ver11.5.10.2.12 add end
--Ver11.5.10.2.13 add start
              xxcfr_common_pkg.conv_company_code(  -- ��ЃR�[�h�ϊ��֐�
                NVL(xps.drafting_company, '001')   -- �`�[�쐬���
               ,xps.gl_date                        -- �v���
              )                 AS drafting_company,                  -- �`�[�쐬���
--Ver11.5.10.2.13 add end
              xpsjlv.attribute1 AS attribute1,                        -- �\���P
              xpsjlv.attribute2 AS attribute2,                        -- �\���Q
              xpsjlv.attribute3 AS attribute3,                        -- �\���R
              xpsjlv.attribute4 AS attribute4,                        -- �\���S
              xpsjlv.attribute5 AS attribute5,                        -- �\���T
              xpsjlv.attribute6 AS attribute6,                        -- �\���U
              xpsjlv.attribute7 AS attribute7,                        -- �\���V
              xpsjlv.attribute8 AS attribute8                         -- �\���W
      FROM    xx03_pay_slip_journal_lines_v xpsjlv
--Ver11.5.10.2.11 add start
             ,xx03_payment_slips            xps
--Ver11.5.10.2.11 add end
--Ver1.1 change start ���׃L�[(xx03_payment_slips��invoice_id)�ԈႢ
--      WHERE   xpsjlv.invoice_id = in_invoice_id
      WHERE   xpsjlv.invoice_id = in_key_invoice_id
--Ver1.1 change end
      AND     xpsjlv.line_type_lookup_code <> cv_type_header
--Ver11.5.10.2.11 add start
      AND     xps.invoice_id = xpsjlv.invoice_id
--Ver11.5.10.2.11 add end
      ORDER BY xpsjlv.line_number;
--
    -- *** ���[�J���E���R�[�h ***
    -- AP�d���搿�������׃J�[�\�����R�[�h
    get_pay_slip_lines_rec get_pay_slip_lines_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
    --AP�d���搿�������׃J�[�\���I�[�v��
    OPEN get_pay_slip_lines_cur;
    <<get_ap_lines_loop>>
    LOOP
      FETCH get_pay_slip_lines_cur INTO get_pay_slip_lines_rec;
      -- 0������
      IF (get_pay_slip_lines_cur%NOTFOUND) THEN
        EXIT get_ap_lines_loop;
      END IF;
--
      -- ����������ID�̎擾
      SELECT  ap_invoice_lines_interface_s.NEXTVAL
      INTO    ln_line_id
      FROM    DUAL;
--
      -- AP�W���C���^�[�t�F�[�X(����)�ւ̑}��
      INSERT INTO ap_invoice_lines_interface (
        invoice_id,
        invoice_line_id,
        line_number,
        line_type_lookup_code,
        amount,
        description,
        tax_code,
        dist_code_concatenated,
        dist_code_combination_id,
        last_update_date,
        last_updated_by,
        last_update_login,
        creation_date,
        created_by,
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
--Ver11.5.10.2.12 add start
        attribute13,
--Ver11.5.10.2.12 add end
--Ver11.5.10.2.13 add start
        attribute15,
--Ver11.5.10.2.13 add end
        org_id,
        tax_code_override_flag
      )
      VALUES (
--Ver1.1 change start ������͖��ׂ̐�����ID(xx03_payment_slips��invoice_id)�ł͂Ȃ��A
--                    �W���C���^�[�t�F�[�X�w�b�_�[�̐�����ID��ݒ肷��̂�������
--        get_pay_slip_lines_rec.invoice_id,
        in_invoice_id,
--Ver1.1 change end
        ln_line_id,
        get_pay_slip_lines_rec.line_number,
        get_pay_slip_lines_rec.line_type_lookup_code,
        get_pay_slip_lines_rec.amount,
        get_pay_slip_lines_rec.description,
        get_pay_slip_lines_rec.tax_code,
        get_pay_slip_lines_rec.code_concatenated,
        get_pay_slip_lines_rec.ccid,
        id_upd_date,
        in_updated_by,
        in_update_login,
        id_upd_date,
        in_created_by,
        in_org_id,
        get_pay_slip_lines_rec.incr_decr_reason,
        get_pay_slip_lines_rec.recon_reference,
        get_pay_slip_lines_rec.attribute1,
        get_pay_slip_lines_rec.attribute2,
        get_pay_slip_lines_rec.attribute3,
        get_pay_slip_lines_rec.attribute4,
        get_pay_slip_lines_rec.attribute5,
        get_pay_slip_lines_rec.attribute6,
        get_pay_slip_lines_rec.attribute7,
--Ver11.5.10.2.11 change start
--        get_pay_slip_lines_rec.attribute8,
        get_pay_slip_lines_rec.invoice_ele_data_yes,
--Ver11.5.10.2.11 change end
--Ver11.5.10.2.12 add start
        get_pay_slip_lines_rec.invoice_t_num_yes,
--Ver11.5.10.2.12 add end
--Ver11.5.10.2.13 add start
        get_pay_slip_lines_rec.drafting_company,
--Ver11.5.10.2.13 add end
        in_org_id,
        cv_tax_code_override
      );
      ln_detail_cnt := ln_detail_cnt + 1;
    END LOOP get_ap_lines_loop;
    CLOSE get_pay_slip_lines_cur;
--
    on_detail_cnt := ln_detail_cnt;
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
  END ins_ap_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_interface
   * Description      : AP�C���^�[�t�F�[�X(�w�b�_�[)�ւ̑}�� (A-3)
   ***********************************************************************************/
  PROCEDURE ins_ap_interface(
    i_ap_if_rec       IN ap_invoices_interface%ROWTYPE, -- 1.AP�C���^�[�t�F�[�X���R�[�h(IN)
    in_org_id         IN NUMBER,                        -- 2.�I���OID(IN)
    id_upd_date       IN DATE,                          -- 3.�w�b�_�[�擾����SYSDATE(IN)
    in_updated_by     IN NUMBER,                        -- 4.�ŏI�X�V��(IN)
    in_update_login   IN NUMBER,                        -- 5.�ŏI���O�C��(IN)
    in_created_by     IN NUMBER,                        -- 6.�쐬��(IN)
    on_detail_cnt     OUT NUMBER,                       -- 7.���׌���(OUT)
--Ver1.1 add start ���׃L�[(xx03_payment_slips��invoice_id)�̓n���Y��
    in_key_invoice_id IN NUMBER,                        -- 8.���׃L�[������ID(IN)
--Ver1.1 add end
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_interface'; -- �v���O������
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
    ln_detail_cnt   NUMBER := 0;     -- ���׌���
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
    xx00_file_pkg.log(' ');
--
    -- AP�W���C���^�[�t�F�[�X�ւ̑}��
    INSERT INTO ap_invoices_interface (
      invoice_id,
      invoice_num,
      invoice_date,
      vendor_id,
      vendor_site_id,
      invoice_amount,
      invoice_currency_code,
      exchange_rate,
      exchange_rate_type,
      exchange_date,
      terms_id,
      description,
      last_update_date,
      last_updated_by,
      last_update_login,
      creation_date,
      created_by,
      attribute_category,
      attribute2,
      attribute3,
      attribute4,
      attribute5,
      attribute6,
      attribute7,
      attribute8,
      attribute9,
      source,
      payment_method_lookup_code,
      pay_group_lookup_code,
      gl_date,
      org_id,
      prepay_num,
-- Ver1.1 add start �O���[���d��v����̐ݒ�R��Ή�
      prepay_gl_date,
-- Ver1.1 add end
      terms_date
    )
    VALUES (
      i_ap_if_rec.invoice_id,
      i_ap_if_rec.invoice_num,
      i_ap_if_rec.invoice_date,
      i_ap_if_rec.vendor_id,
      i_ap_if_rec.vendor_site_id,
      i_ap_if_rec.invoice_amount,
      i_ap_if_rec.invoice_currency_code,
      i_ap_if_rec.exchange_rate,
      i_ap_if_rec.exchange_rate_type,
      i_ap_if_rec.exchange_date,
      i_ap_if_rec.terms_id,
      i_ap_if_rec.description,
      i_ap_if_rec.last_update_date,
      i_ap_if_rec.last_updated_by,
      i_ap_if_rec.last_update_login,
      i_ap_if_rec.creation_date,
      i_ap_if_rec.created_by,
      i_ap_if_rec.attribute_category,
      i_ap_if_rec.attribute2,
      i_ap_if_rec.attribute3,
      i_ap_if_rec.attribute4,
      i_ap_if_rec.attribute5,
      i_ap_if_rec.attribute6,
      i_ap_if_rec.attribute7,
      i_ap_if_rec.attribute8,
      i_ap_if_rec.attribute9,
      i_ap_if_rec.source,
      i_ap_if_rec.payment_method_lookup_code,
      i_ap_if_rec.pay_group_lookup_code,
      i_ap_if_rec.gl_date,
      i_ap_if_rec.org_id,
      i_ap_if_rec.prepay_num,
-- Ver1.1 add start �O���[���d��v����̐ݒ�R��Ή�
      i_ap_if_rec.gl_date,
-- Ver1.1 add end
      i_ap_if_rec.terms_date
    );
--
    -- ========================================================
    -- �o�����F�ώd���搿�������׃f�[�^�̎擾�ƍX�V (A-2�AA-3)
    -- ========================================================
    ins_ap_interface_lines(
      i_ap_if_rec.invoice_id,         -- 1.������ID(IN)
      in_org_id,                      -- 2.�I���OID(IN)
      id_upd_date,                    -- 3.�w�b�_�[�擾����SYSDATE(IN)
      in_updated_by,                  -- 4.�ŏI�X�V��(IN)
      in_update_login,                -- 5.�ŏI���O�C��(IN)
      in_created_by,                  -- 6.�쐬��(IN)
      ln_detail_cnt,                  -- 7.���׌���(OUT)
--Ver1.1 add start ���׃L�[(xx03_payment_slips��invoice_id)�̓n���Y��
      in_key_invoice_id,              -- 8.���׃L�[������ID(IN)
--Ver1.1 add end
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    on_detail_cnt := ln_detail_cnt;
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
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
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
  END ins_ap_interface;
--
  /**********************************************************************************
   * Procedure Name   : get_approval_slip_data
   * Description      : �o�����F�ώd���搿�����f�[�^�̎擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_approval_slip_data(
    iv_source         IN VARCHAR2,      -- 1.�\�[�X��(IN)
    in_org_id         IN NUMBER,        -- 2.�I���OID(IN)
    iv_currency_code  IN VARCHAR2,      -- 3.�@�\�ʉ�(IN)
    on_header_cnt     OUT NUMBER,       -- 4.�w�b�_����(OUT)
    on_detail_cnt     OUT NUMBER,       -- 5.���׌���(OUT)
    od_upd_date       OUT DATE,         -- 6.�X�V���t(OUT)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_approval_slip_data'; -- �v���O������
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
    cv_us_rate_type     CONSTANT VARCHAR2(10) := 'User';
    cv_pay_lookup_type  CONSTANT xx03_ap_pay_groups_v.lookup_type%TYPE := 'PAY GROUP';
--
    -- *** ���[�J���ϐ� ***
    ln_updated_by     NUMBER;         -- �ŏI�X�V�ґޔ�p
    ln_update_login   NUMBER;         -- �ŏI���O�C���ޔ�p
    ln_created_by     NUMBER;         -- �쐬�ґޔ�p
    lv_cur_lang       VARCHAR2(4);    -- ���݂̌���R�[�h
    ln_detail_cnt     NUMBER;         -- ���׌���
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_ap_trance_data_cur
    IS
      SELECT    xps.invoice_num AS invoice_num,
--Ver1.1 add start ���׃L�[(xx03_payment_slips��invoice_id)�̓n���Y��
                xps.invoice_id AS key_invoice_id,
--Ver1.1 add end
                xps.invoice_date AS invoice_date,
                xps.vendor_id AS vendor_id,
                xps.vendor_site_id AS vendor_site_id,
--Ver1.1 change start ���v���z�̎Z�o�ԈႢ
--                xps.inv_amount AS inv_amount,
                xps.inv_item_amount  AS  inv_item_amount,
                xps.inv_tax_amount  AS  inv_tax_amount,
--Ver1.1 change end ���v���z�̎Z�o�ԈႢ
                xps.invoice_currency_code AS inv_currency_code,
                xps.exchange_rate AS exchange_rate,
                DECODE(xps.invoice_currency_code,
                  iv_currency_code,
                  NULL,
                  xps.exchange_rate_type) AS exchange_rate_type,
                DECODE(xps.invoice_currency_code,
                  iv_currency_code,
                  NULL,
                  xps.gl_date) AS exchange_date,
                xps.terms_id AS terms_id,
                xps.description AS description,
                xps.vendor_invoice_num AS vendor_invoice_num,
                xps.entry_department AS entry_department,
                xps.entry_person_id AS entry_person_id,
                xps.orig_invoice_num AS orig_invoice_num,
                xps.attribute1 AS attribute1,
                xps.attribute2 AS attribute2,
                xps.attribute3 AS attribute3,
                xps.attribute4 AS attribute4,
                xps.pay_group_lookup_code AS pay_group_lookup_code,
                xps.gl_date AS gl_date,
                xps.org_id AS org_id,
                xps.prepay_num AS prepay_num,
                xps.terms_date AS terms_date,
                SYSDATE AS upd_date
      FROM      xx03_payment_slips xps
      WHERE     xps.wf_status = cv_appr_status
      AND       xps.ap_forword_date IS NULL
      AND       xps.org_id = in_org_id
      ORDER BY  xps.invoice_id
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    -- AP�d���搿�����]���J�[�\�����R�[�h
    get_ap_trance_data_rec get_ap_trance_data_cur%ROWTYPE;
    -- AP I/F�w�b�_�[���R�[�h
    l_ap_if_rec ap_invoices_interface%ROWTYPE;
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
    xx00_file_pkg.log(' ');
--
    -- AP�d���搿�����]���J�[�\���I�[�v��
    OPEN get_ap_trance_data_cur;
    -- �ϐ�������
    on_header_cnt := 0;
--Ver1.1 add start �ϐ��������R��
    on_detail_cnt := 0;
--Ver1.1 add end
    ln_updated_by := xx00_global_pkg.last_updated_by;
    ln_update_login := xx00_global_pkg.last_update_login;
    ln_created_by := xx00_global_pkg.created_by;
    lv_cur_lang := xx00_global_pkg.current_language;
    <<get_ap_trance_loop>>
    LOOP
      FETCH get_ap_trance_data_cur INTO get_ap_trance_data_rec;
      -- 0������
      IF (get_ap_trance_data_cur%NOTFOUND) THEN
        -- ��������
        IF on_header_cnt < 1 THEN
          RAISE chk_data_none_expt;
        END IF;
        EXIT get_ap_trance_loop;
      END IF;
      IF on_header_cnt = 0 THEN
        od_upd_date := get_ap_trance_data_rec.upd_date;
      END IF;
      -- AP�C���^�[�t�F�[�X���R�[�h�^�ɃZ�b�g
      -- INVOICE_ID
      SELECT  ap_invoices_interface_s.NEXTVAL
      INTO    l_ap_if_rec.invoice_id
      FROM    DUAL;
      -- INVOICE_NUM
      l_ap_if_rec.invoice_num := get_ap_trance_data_rec.invoice_num;
      -- INVOICE_DATE
      l_ap_if_rec.invoice_date := get_ap_trance_data_rec.invoice_date;
      -- VENDOR_ID
      l_ap_if_rec.vendor_id := get_ap_trance_data_rec.vendor_id;
      -- VENDOR_SITE_ID
      l_ap_if_rec.vendor_site_id := get_ap_trance_data_rec.vendor_site_id;
      -- INVOICE_AMOUNT
--Ver1.1 change start ���v���z�̎Z�o�ԈႢ
--      l_ap_if_rec.invoice_amount := get_ap_trance_data_rec.inv_amount;
      l_ap_if_rec.invoice_amount := get_ap_trance_data_rec.inv_item_amount +
        get_ap_trance_data_rec.inv_tax_amount;
--Ver1.1 change end
      -- INVOICE_CURRENCY_CODE
      l_ap_if_rec.invoice_currency_code := get_ap_trance_data_rec.inv_currency_code;
      -- EXCHANGE_RATE
      IF get_ap_trance_data_rec.inv_currency_code <> iv_currency_code AND
        get_ap_trance_data_rec.exchange_rate_type = cv_us_rate_type THEN
        l_ap_if_rec.exchange_rate := get_ap_trance_data_rec.exchange_rate;
      ELSE
        l_ap_if_rec.exchange_rate := NULL;
      END IF;
      -- EXCHANGE_RATE_TYPE
      l_ap_if_rec.exchange_rate_type := get_ap_trance_data_rec.exchange_rate_type;
      -- EXCHANGE_DATE
      l_ap_if_rec.exchange_date := get_ap_trance_data_rec.exchange_date;
      -- TERMS_ID
      l_ap_if_rec.terms_id := get_ap_trance_data_rec.terms_id;
      -- DESCRIPTION
      l_ap_if_rec.description := get_ap_trance_data_rec.description;
      -- LAST_UPDATE_DATE
      l_ap_if_rec.last_update_date := get_ap_trance_data_rec.upd_date;
      -- LAST_UPDATED_BY
      l_ap_if_rec.last_updated_by := ln_updated_by;
      -- LAST_UPDATE_LOGIN
      l_ap_if_rec.last_update_login := ln_update_login;
      -- CREATION_DATE
      l_ap_if_rec.creation_date := get_ap_trance_data_rec.upd_date;
      -- CREATED_BY
      l_ap_if_rec.created_by := ln_created_by;
      -- ATTRIBUTE_CATEGORY
      l_ap_if_rec.attribute_category := in_org_id;
      -- ATTRIBUTE2
      l_ap_if_rec.attribute2 := get_ap_trance_data_rec.vendor_invoice_num;
      -- ATTRIBUTE3
      l_ap_if_rec.attribute3 := get_ap_trance_data_rec.entry_department;
      -- ATTRIBUTE4
      SELECT xuv.user_name
      INTO l_ap_if_rec.attribute4
      FROM  xx03_users_v xuv
      WHERE xuv.employee_id = get_ap_trance_data_rec.entry_person_id;
      -- ATTRIBUTE5
      l_ap_if_rec.attribute5 := get_ap_trance_data_rec.orig_invoice_num;
      -- ATTRIBUTE6
      l_ap_if_rec.attribute6 := get_ap_trance_data_rec.attribute1;
      -- ATTRIBUTE7
      l_ap_if_rec.attribute7 := get_ap_trance_data_rec.attribute2;
      -- ATTRIBUTE8
      l_ap_if_rec.attribute8 := get_ap_trance_data_rec.attribute3;
      -- ATTRIBUTE9
      l_ap_if_rec.attribute9 := get_ap_trance_data_rec.attribute4;
      -- SOURCE
      l_ap_if_rec.source := iv_source;
      -- PAYMENT_METHOD_LOOKUP_CODE
      SELECT  xapgv.attribute1
      INTO    l_ap_if_rec.payment_method_lookup_code
      FROM    xx03_ap_pay_groups_v xapgv
      WHERE   xapgv.lookup_type = cv_pay_lookup_type
      AND     xapgv.lookup_code = get_ap_trance_data_rec.pay_group_lookup_code
      AND     xapgv.language = lv_cur_lang;
      -- PAY_GROUP_LOOKUP_CODE
      l_ap_if_rec.pay_group_lookup_code := get_ap_trance_data_rec.pay_group_lookup_code;
      -- GL_DATE
      l_ap_if_rec.gl_date := get_ap_trance_data_rec.gl_date;
      -- ORG_ID
      l_ap_if_rec.org_id := get_ap_trance_data_rec.org_id;
      -- PREPAY_NUM
      l_ap_if_rec.prepay_num := get_ap_trance_data_rec.prepay_num;
      -- TERMS_DATE
      SELECT  DECODE(at.attribute1,
                'Y',
                get_ap_trance_data_rec.terms_date,
                NULL)
      INTO    l_ap_if_rec.terms_date
      FROM    ap_terms_tl at
      WHERE   at.term_id = get_ap_trance_data_rec.terms_id
      AND     at.language = lv_cur_lang;
--
      -- =======================================
      -- API/F�̍X�V (A-3)
      -- =======================================
      ins_ap_interface(
        l_ap_if_rec,                              -- 1.AP�C���^�[�t�F�[�X���R�[�h(IN)
        in_org_id,                                -- 2.�I���OID(IN)
        get_ap_trance_data_rec.upd_date,          -- 3.�w�b�_�[�擾����SYSDATE(IN)
        ln_updated_by,                            -- 4.�ŏI�X�V��(IN)
        ln_update_login,                          -- 5.�ŏI���O�C��(IN)
        ln_created_by,                            -- 6.�쐬��(IN)
        ln_detail_cnt,                            -- 7.���׌���(OUT)
--Ver1.1 add start ���׃L�[(xx03_payment_slips��invoice_id)�̓n���Y��
        get_ap_trance_data_rec.key_invoice_id,    -- 8.���׃L�[������ID(IN)
--Ver1.1 add end
        lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- ver 11.5.10.2.10 Add Start
      -- ���펞����
      IF (ov_retcode != xx00_common_pkg.set_status_error_f) AND
         (ov_retcode != xx00_common_pkg.set_status_warn_f ) THEN
        UPDATE  xx03_payment_slips xps
        SET     xps.ap_forword_date = od_upd_date,
                xps.last_update_date = od_upd_date,
                xps.last_updated_by = xx00_global_pkg.user_id,
                xps.last_update_login = xx00_global_pkg.last_update_login
        WHERE   xps.invoice_id = get_ap_trance_data_rec.key_invoice_id
        ;
      END IF;
      -- ver 11.5.10.2.10 Add End
--
      -- �����̃J�E���g
      on_header_cnt := on_header_cnt + 1;
      on_detail_cnt := on_detail_cnt + ln_detail_cnt;
    END LOOP get_ap_trance_loop;
    CLOSE get_ap_trance_data_cur;
--
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_data_none_expt THEN        --*** �]�������Ώۃf�[�^���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08003'));           -- �]�������Ώۃf�[�^���擾�G���[���b�Z�[�W
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      --Ver1.1 change start �X�e�[�^�X�͌x���ɂ���
--      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
      --Ver1.1 change end
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
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
  END get_approval_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_data
   * Description      : AP�]���ώd���搿�����f�[�^�̍X�V (A-4)
   ***********************************************************************************/
  PROCEDURE upd_slip_data(
    in_org_id         IN  NUMBER,       -- 1.�I���OID(IN)
    id_sysdate        IN  DATE,         -- 2.�X�V���t(IN)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_slip_data'; -- �v���O������
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
    --���O�o��
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --�d���搿�����f�[�^�̍X�V
    UPDATE  xx03_payment_slips xps
    SET     xps.ap_forword_date = id_sysdate,
            xps.last_update_date = id_sysdate,
            xps.last_updated_by = xx00_global_pkg.user_id,
            xps.last_update_login = xx00_global_pkg.last_update_login
    WHERE   xps.wf_status = cv_appr_status
    AND     xps.ap_forword_date IS NULL
    AND     xps.org_id = in_org_id;
--
    --���O�o��
    xx00_file_pkg.log('UPDATE table :xx03_payment_slips');
    xx00_file_pkg.log('org_id = '|| TO_CHAR(in_org_id));
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
  END upd_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : ���ʏo�� (A-4)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id     IN  NUMBER,       --  1.�`�F�b�NID(IN)
    in_books_id   IN  NUMBER,       --  2.��v����ID(IN)
    in_header_cnt IN  NUMBER,       --  3.�w�b�_����(IN)
    in_detail_cnt IN  NUMBER,       --  4.���׌���(IN)
    iv_source     IN  VARCHAR2,     --  5.�\�[�X��(IN)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
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
--
    -- �w�b�_�[�o��
    xx03_header_line_output_pkg.header_line_output_p('GL',    -- ��v���떼��\������
      xx00_global_pkg.prog_appl_id,
      in_books_id,                        -- ��v����ID
      in_org_id,                          -- �I���OID
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- �p�����[�^�̃��O�o��
    xx00_file_pkg.output(' ');
--Ver1.1 add Start CD�R��
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
--Ver1.1 add End
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' ||
      iv_source);
    xx00_file_pkg.output(' ');
--
    -- �����o��
    xx00_file_pkg.output(
    xx00_message_pkg.get_msg(
      'XX03',
      'APP-XX03-04004',             -- ���F�ώd���搿�����]�����ʏo��
      'XX03_TOK_HEAD_CNT',
      in_header_cnt,                -- AP�]������(�w�b�_)
      'XX03_TOK_DETAIL_CNT',
      in_detail_cnt));              -- AP�]������(�z��)
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
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
  END msg_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.�\�[�X��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_org_id         NUMBER(15,0);   -- �I���OID
    ln_books_id       gl_sets_of_books.set_of_books_id%TYPE;  -- ��v����ID
    lv_currency_code  gl_sets_of_books.currency_code%TYPE;    -- �@�\�ʉ�
    ln_header_cnt     NUMBER;         -- �w�b�_����
    ln_detail_cnt     NUMBER;         -- ���׌���
    ld_upd_date       DATE;           -- �X�V���t
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
    -- =======================================
    -- AP�����F�d���搿�����f�[�^�̊m�F (A-1)
    -- =======================================
    vaild_approval(
      ln_org_id,          -- 1.�I���OID(OUT)
      ln_books_id,        -- 2.��v����ID(OUT)
      lv_currency_code,   -- 3.�@�\�ʉ�(OUT)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- �o�����F�ώd���搿�����f�[�^�̎擾(A-2)
    -- =======================================
    get_approval_slip_data(
      iv_source,          -- 1.�\�[�X��(IN)
      ln_org_id,          -- 2.�I���OID(IN)
      lv_currency_code,   -- 3.�@�\�ʉ�(IN)
      ln_header_cnt,      -- 4.�w�b�_����(OUT)
      ln_detail_cnt,      -- 5.���׌���(OUT)
      ld_upd_date,        -- 6.�X�V���t(OUT)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    --Ver1.1 add start �x���X�e�[�^�X���A�������f
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSE
--
      -- ver 11.5.10.2.10 Del Start
      ---- =======================================
      ---- AP�]���ώd���搿�����f�[�^�̍X�V (A-4)
      ---- =======================================
      --upd_slip_data(
      --  ln_org_id,            -- 1.�I���OID(IN)
      --  ld_upd_date,          -- 2.�X�V���t(IN)
      --  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      --  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      --  lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --  --(�G���[����)
      --  RAISE global_process_expt;
      --END IF;
      -- ver 11.5.10.2.10 Del End
--
      -- =======================================
      -- ���ʏo�� (A-4)
      -- =======================================
      msg_output(
        ln_org_id,          --  1.�`�F�b�NID(IN)
        ln_books_id,        --  2.��v����ID(IN)
        ln_header_cnt,      --  3.�w�b�_����(IN)
        ln_detail_cnt,      --  4.���׌���(IN)
        iv_source,          --  5.�\�[�X��(IN)
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
    --Ver1.1 add end
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_source     IN  VARCHAR2)      -- 1.�\�[�X��(IN)
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
      iv_source,   -- 1.�\�[�X��(IN)
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
END XX034PT001C;
/
