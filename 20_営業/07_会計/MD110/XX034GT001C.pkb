CREATE OR REPLACE PACKAGE BODY XX034GT001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name     : XX034GT001C(body)
 * Description      : ���F�ϕ�����̓f�[�^��GL�W��I/F�ɓ]����A������͓]�������X�V����
 * MD.050           : ������̓o�b�`����(GL)   OCSJ/BFAFIN/MD050/F602
 * MD.070           : ���F�ώd��̓]�� OCSJ/BFAFIN/MD070/F602/05
 * Version          : 11.5.10.2.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_approval_slip_data �ŏI���F�ώd��f�[�^�̎擾 (A-1)
 *  ins_gl_interface       GLI/F�̍X�V (A-2)
 *  upd_slip_data          GL�]���ώd��f�[�^�̍X�V (A-3)
 *  msg_output             ���ʏo�� (A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/12/17   1.0            �V�K�쐬
 *  2005/03/11   1.1            �s��Ή�(No.393:�[�����Z�Ή�)
 *  2005/04/05   11.5.10.1.0    �s��Ή�(No.460:���͒ʉ݋��z�[���Ή�)
 *  2005/04/26   11.5.10.1.1    �s��Ή�(GL�F�ŗ�0%�̍ۂ̐ŋ����בΉ�)
 *  2005/12/15   11.5.10.1.6    �v����ɂ����ėL���Ȑŋ敪����A����ōs�̊eAFF�l��
 *                              �擾����悤�ɕύX
 *  2006/01/17   11.5.10.1.6B   �x���I�����͎d����v�ス���A���̃X�e�[�W�ɂ��J��
 *                              ���Ȃ��悤�ɏC��
 *  2007/11/26   11.5.10.2.10   �f�[�^�]���Ɠ]���σt���O�X�V�^�C�~���O�̏C��
 *  2023/12/20   11.5.10.2.11   [E_�{�ғ�_19496]�Ή� �O���[�v��Г����Ή�
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
  cv_appr_status      CONSTANT  xx03_journal_slips.wf_status%TYPE := '80';  -- �o�����F�σX�e�[�^�X
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  chk_data_none_expt        EXCEPTION;              -- GL�]���f�[�^���擾�G���[
  get_slip_type_name_expt   EXCEPTION;              -- �d��J�e�S���擾�G���[
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      : GLI/F�̍X�V (A-2)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    i_gl_if_rec       IN gl_interface%ROWTYPE,  -- 1.GL�C���^�[�t�F�[�X���R�[�h(IN)
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- �v���O������
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
    xx00_file_pkg.log(' ');
--
    -- GL�W���C���^�[�t�F�[�X�ւ̑}��
    INSERT INTO gl_interface (
      status,
      set_of_books_id,
      accounting_date,
      currency_code,
      date_created,
      created_by,
      actual_flag,
      user_je_category_name,
      user_je_source_name,
      currency_conversion_date,
      user_currency_conversion_type,
      currency_conversion_rate,
      segment1,
      segment2,
      segment3,
      segment4,
      segment5,
      segment6,
      segment7,
      segment8,
      entered_dr,
      entered_cr,
      accounted_dr,
      accounted_cr,
      reference1,
      reference4,
      reference5,
      reference10,
      period_name,
      group_id,
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
-- Ver11.5.10.2.11 ADD START
      attribute15,
-- Ver11.5.10.2.11 ADD END
      context,
      jgzz_recon_ref
    )
    VALUES (
      i_gl_if_rec.status,
      i_gl_if_rec.set_of_books_id,
      i_gl_if_rec.accounting_date,
      i_gl_if_rec.currency_code,
      i_gl_if_rec.date_created,
      i_gl_if_rec.created_by,
      i_gl_if_rec.actual_flag,
      i_gl_if_rec.user_je_category_name,
      i_gl_if_rec.user_je_source_name,
      i_gl_if_rec.currency_conversion_date,
      i_gl_if_rec.user_currency_conversion_type,
      i_gl_if_rec.currency_conversion_rate,
      i_gl_if_rec.segment1,
      i_gl_if_rec.segment2,
      i_gl_if_rec.segment3,
      i_gl_if_rec.segment4,
      i_gl_if_rec.segment5,
      i_gl_if_rec.segment6,
      i_gl_if_rec.segment7,
      i_gl_if_rec.segment8,
      i_gl_if_rec.entered_dr,
      i_gl_if_rec.entered_cr,
      i_gl_if_rec.accounted_dr,
      i_gl_if_rec.accounted_cr,
      i_gl_if_rec.reference1,
      i_gl_if_rec.reference4,
      i_gl_if_rec.reference5,
      i_gl_if_rec.reference10,
      i_gl_if_rec.period_name,
      i_gl_if_rec.group_id,
      i_gl_if_rec.attribute1,
      i_gl_if_rec.attribute2,
      i_gl_if_rec.attribute3,
      i_gl_if_rec.attribute4,
      i_gl_if_rec.attribute5,
      i_gl_if_rec.attribute6,
      i_gl_if_rec.attribute7,
      i_gl_if_rec.attribute8,
      i_gl_if_rec.attribute9,
      i_gl_if_rec.attribute10,
-- Ver11.5.10.2.11 ADD START
      i_gl_if_rec.attribute15,
-- Ver11.5.10.2.11 ADD END
      i_gl_if_rec.context,
      i_gl_if_rec.jgzz_recon_ref
    );
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
  END ins_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : get_approval_slip_data
   * Description      : �ŏI���F�ώd��`�[�f�[�^�̎擾(A-1)
   ***********************************************************************************/
  PROCEDURE get_approval_slip_data(
    iv_source         IN VARCHAR2,      -- 1.�\�[�X��(IN)
    on_org_id         OUT NUMBER,       -- 2.�I���OID(OUT)
    on_books_id       OUT NUMBER,       -- 3.��v����ID(OUT)
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
    ln_created_by     NUMBER;         -- �쐬�ґޔ�p
    lv_cur_lang       VARCHAR2(4);    -- ���݂̌���R�[�h
    lv_currency_code  xx03_journal_slips.invoice_currency_code%TYPE;
                                                         -- �@�\�ʉ�
    ln_precision      xx03_currencies_v.precision%TYPE;  -- �@�\�ʉ݂̏����_�ȉ�����
    lv_slip_type      xx03_journal_slips.slip_type%TYPE; -- �`�[��ʃR�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_gl_trance_data_cur
    IS
      SELECT    xjs.journal_num             AS journal_num,
                xjs.slip_type               AS slip_type,
                xjs.invoice_currency_code   AS currency_code,
                xjs.exchange_rate           AS exchange_rate,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.exchange_rate_type)   AS exchange_rate_type,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.exchange_rate_type_name) AS exchange_rate_type_name,
                DECODE(xjs.invoice_currency_code,
                  lv_currency_code,
                  NULL,
                  xjs.gl_date)              AS exchange_date,
                xjs.ignore_rate_flag        AS ignore_rate_flag,
                xjs.description             AS description,
                xjs.entry_department        AS entry_department,
                xjs.entry_person_id         AS entry_person_id,
                xjs.orig_journal_num        AS orig_journal_num,
                xjs.period_name             AS period_name,
                xjs.gl_date                 AS gl_date,
                xjs.org_id                  AS org_id,
                xjs.set_of_books_id         AS set_of_books_id,
                xjsl.line_number            AS line_number,
                xjsl.entered_item_amount_dr AS entered_item_amount_dr,
                xjsl.entered_tax_amount_dr  AS entered_tax_amount_dr,
                xjsl.accounted_amount_dr    AS accounted_amount_dr,
                xjsl.entered_item_amount_cr AS entered_item_amount_cr,
                xjsl.entered_tax_amount_cr  AS entered_tax_amount_cr,
                xjsl.accounted_amount_cr    AS accounted_amount_cr,
                NVL(xjsl.tax_code_dr,
                    xjsl.tax_code_cr)       AS tax_code,
                xjsl.description            AS lines_description,
                xjsl.segment1               AS segment1,
                xjsl.segment2               AS segment2,
                xjsl.segment3               AS segment3,
                xjsl.segment4               AS segment4,
                xjsl.segment5               AS segment5,
                xjsl.segment6               AS segment6,
                xjsl.segment7               AS segment7,
                xjsl.segment8               AS segment8,
                xjsl.segment9               AS segment9,
                xjsl.segment10              AS segment10,
                xjsl.incr_decr_reason_code  AS incr_decr_reason_code,
                xjsl.recon_reference        AS recon_reference,
                xjsl.attribute1             AS attribute1,
                xjsl.attribute2             AS attribute2,
                xjsl.attribute3             AS attribute3,
                xjsl.attribute4             AS attribute4,
                xjsl.attribute5             AS attribute5,
                xjsl.attribute6             AS attribute6,
                xjsl.attribute7             AS attribute7,
                xjsl.attribute8             AS attribute8,
                xjsl.attribute9             AS attribute9,
                xjsl.attribute10            AS attribute10,
                xjsl.org_id                 AS lines_org_id,
                SYSDATE                     AS upd_date
                -- ver 11.5.10.2.10 Add Start
               ,xjs.journal_id AS journal_id
                -- ver 11.5.10.2.10 Add End
-- Ver11.5.10.2.11 ADD START
               ,xjs.drafting_company        AS drafting_company
-- Ver11.5.10.2.11 ADD END
      FROM      xx03_journal_slips xjs,
                xx03_journal_slip_lines xjsl
      WHERE     xjs.wf_status = cv_appr_status
      AND       xjs.gl_forword_date IS NULL
      AND       xjs.org_id = on_org_id
      AND       xjs.set_of_books_id = on_books_id
      AND       xjsl.journal_id = xjs.journal_id
      ORDER BY  xjs.journal_id
      -- ver 11.5.10.2.10 Chg Start
      --FOR UPDATE NOWAIT;
      FOR UPDATE OF xjs.journal_id NOWAIT;
      -- ver 11.5.10.2.10 Chg End
--
    -- *** ���[�J���E���R�[�h ***
    -- GL�d��`�[�]���J�[�\�����R�[�h
    get_gl_trance_data_rec get_gl_trance_data_cur%ROWTYPE;
--
    -- GL I/F�w�b�_�[���R�[�h
    l_gl_if_item_rec  gl_interface%ROWTYPE;
    l_gl_if_tax_rec   gl_interface%ROWTYPE;
    l_gl_if_clear     gl_interface%ROWTYPE;
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
--
    -- ��v����ID�̎擾
    on_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- �@�\�ʉ݂̎擾
    SELECT  gsob.currency_code AS currency_code,
            xcv.precision      AS precision
    INTO    lv_currency_code,
            ln_precision
    FROM    gl_sets_of_books gsob,
            xx03_currencies_v xcv
    WHERE   gsob.set_of_books_id = on_books_id
    AND     gsob.currency_code   = xcv.currency_code;
--
    xx00_file_pkg.log('org_id = ' || TO_CHAR(on_org_id));
    xx00_file_pkg.log('books_id = ' || TO_CHAR(on_books_id));
    xx00_file_pkg.log('currency_code = ' || lv_currency_code);
--
    -- GL�d��`�[�]���Ώۃf�[�^���׌����̎擾
    SELECT COUNT(*)
    INTO   on_detail_cnt
    FROM   xx03_journal_slip_lines xjsl
    WHERE  xjsl.journal_id in (
      SELECT  xjs.journal_id
      FROM    xx03_journal_slips xjs
      WHERE   xjs.wf_status = cv_appr_status
      AND     xjs.gl_forword_date IS NULL
      AND     xjs.org_id = on_org_id
      AND     xjs.set_of_books_id = on_books_id);
--
    -- GL�d��`�[�]���Ώۃf�[�^�����̎擾
    SELECT COUNT(*)
    INTO   on_header_cnt
    FROM   xx03_journal_slips xjs
    WHERE  xjs.wf_status = cv_appr_status
    AND    xjs.gl_forword_date IS NULL
    AND    xjs.org_id = on_org_id
    AND    xjs.set_of_books_id = on_books_id;
--
    -- GL�d��`�[�]���J�[�\���I�[�v��
    OPEN get_gl_trance_data_cur;
    -- �ϐ�������
    ln_created_by   := xx00_global_pkg.created_by;
    lv_cur_lang     := xx00_global_pkg.current_language;
    <<get_gl_trance_loop>>
    LOOP
      FETCH get_gl_trance_data_cur INTO get_gl_trance_data_rec;
--
      -- 0������
      IF (get_gl_trance_data_cur%NOTFOUND) THEN
        -- ��������
        IF on_header_cnt < 1 THEN
          RAISE chk_data_none_expt;
        END IF;
        EXIT get_gl_trance_loop;
      END IF;
      od_upd_date := get_gl_trance_data_rec.upd_date;
--
      -- ������
      l_gl_if_item_rec := l_gl_if_clear;
      l_gl_if_tax_rec  := l_gl_if_clear;
--
      -- �d��J�e�S���擾
      BEGIN
        SELECT gjcv.user_je_category_name
        INTO   l_gl_if_item_rec.user_je_category_name
        FROM   gl_je_categories_vl gjcv,
               xx03_slip_types_v   xstv
        WHERE  gjcv.je_category_name = xstv.attribute13
        AND    xstv.lookup_code      = get_gl_trance_data_rec.slip_type;
      EXCEPTION
        WHEN OTHERS THEN
          lv_slip_type := get_gl_trance_data_rec.slip_type;
          RAISE get_slip_type_name_expt;
      END;
--
      -- DFF�R���e�L�X�g(��v���떼)�擾
      SELECT NAME
      INTO   l_gl_if_item_rec.context
      FROM   gl_sets_of_books
      WHERE  set_of_books_id = get_gl_trance_data_rec.set_of_books_id;
--
      -- �O���[�vID�擾
      SELECT TO_NUMBER(attribute1)
      INTO   l_gl_if_item_rec.group_id
      FROM   gl_je_sources_tl
      WHERE  language = lv_cur_lang
      AND    user_je_source_name = iv_source;
--
      -- ���[�g�擾
      IF get_gl_trance_data_rec.currency_code <> lv_currency_code AND
         get_gl_trance_data_rec.exchange_rate_type = cv_us_rate_type THEN
        l_gl_if_item_rec.currency_conversion_rate := get_gl_trance_data_rec.exchange_rate;
      ELSE
        l_gl_if_item_rec.currency_conversion_rate := NULL;
      END IF;
--
      -- �`�[���͎Җ��擾
      SELECT xuv.user_name
      INTO l_gl_if_item_rec.attribute5
      FROM  xx03_users_v xuv
      WHERE xuv.employee_id = get_gl_trance_data_rec.entry_person_id;
--
      -- GL�C���^�[�t�F�[�X���R�[�h�^�ɃZ�b�g(���ʍ���)
      l_gl_if_item_rec.status := 'NEW';
      l_gl_if_item_rec.set_of_books_id := get_gl_trance_data_rec.set_of_books_id;
      l_gl_if_item_rec.accounting_date := get_gl_trance_data_rec.gl_date;
      l_gl_if_item_rec.currency_code   := get_gl_trance_data_rec.currency_code;
      l_gl_if_item_rec.date_created    := get_gl_trance_data_rec.upd_date;
      l_gl_if_item_rec.created_by      := ln_created_by;
      l_gl_if_item_rec.actual_flag     := 'A';
      l_gl_if_item_rec.user_je_source_name := iv_source;
      l_gl_if_item_rec.currency_conversion_date := get_gl_trance_data_rec.exchange_date;
      l_gl_if_item_rec.user_currency_conversion_type := get_gl_trance_data_rec.exchange_rate_type_name;
      l_gl_if_item_rec.reference1  := NULL;
      l_gl_if_item_rec.reference4  := get_gl_trance_data_rec.journal_num;
      l_gl_if_item_rec.reference5  := get_gl_trance_data_rec.description;
      l_gl_if_item_rec.period_name := get_gl_trance_data_rec.period_name;
      l_gl_if_item_rec.attribute1  := get_gl_trance_data_rec.tax_code;
      l_gl_if_item_rec.attribute3  := get_gl_trance_data_rec.journal_num;
      l_gl_if_item_rec.attribute4  := get_gl_trance_data_rec.entry_department;
      l_gl_if_item_rec.attribute6  := get_gl_trance_data_rec.orig_journal_num;
-- Ver11.5.10.2.11 ADD START
      l_gl_if_item_rec.attribute15 := get_gl_trance_data_rec.drafting_company;
-- Ver11.5.10.2.11 ADD END
--
      l_gl_if_tax_rec := l_gl_if_item_rec;
--
      -- GL�C���^�[�t�F�[�X���R�[�h�^�ɃZ�b�g(�{�̍s)
      l_gl_if_item_rec.segment1    := get_gl_trance_data_rec.segment1;
      l_gl_if_item_rec.segment2    := get_gl_trance_data_rec.segment2;
      l_gl_if_item_rec.segment3    := get_gl_trance_data_rec.segment3;
      l_gl_if_item_rec.segment4    := get_gl_trance_data_rec.segment4;
      l_gl_if_item_rec.segment5    := get_gl_trance_data_rec.segment5;
      l_gl_if_item_rec.segment6    := get_gl_trance_data_rec.segment6;
      l_gl_if_item_rec.segment7    := get_gl_trance_data_rec.segment7;
      l_gl_if_item_rec.segment8    := get_gl_trance_data_rec.segment8;
      l_gl_if_item_rec.entered_dr  := get_gl_trance_data_rec.entered_item_amount_dr;
      l_gl_if_item_rec.entered_cr  := get_gl_trance_data_rec.entered_item_amount_cr;
      IF get_gl_trance_data_rec.ignore_rate_flag = 'Y' THEN
        l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.entered_item_amount_dr
                                       * NVL(get_gl_trance_data_rec.exchange_rate,1);
        l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.entered_item_amount_cr
                                       * NVL(get_gl_trance_data_rec.exchange_rate,1);
      ELSE
-- ver 1.1 Change Start
--        l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr
--                                       *(get_gl_trance_data_rec.entered_item_amount_dr
--                                       /(get_gl_trance_data_rec.entered_item_amount_dr
--                                        +get_gl_trance_data_rec.entered_tax_amount_dr));
--        l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr
--                                       *(get_gl_trance_data_rec.entered_item_amount_cr
--                                       /(get_gl_trance_data_rec.entered_item_amount_cr
--                                        +get_gl_trance_data_rec.entered_tax_amount_cr));
        IF (  get_gl_trance_data_rec.entered_item_amount_dr
            + get_gl_trance_data_rec.entered_tax_amount_dr  ) = 0 THEN
-- ver 11.5.10.1.0 Change Start
--          l_gl_if_item_rec.accounted_dr := 0;
          l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr;
-- ver 11.5.10.1.0 Change End
        ELSE
          l_gl_if_item_rec.accounted_dr := get_gl_trance_data_rec.accounted_amount_dr
                                         *(get_gl_trance_data_rec.entered_item_amount_dr
                                         /(get_gl_trance_data_rec.entered_item_amount_dr
                                          +get_gl_trance_data_rec.entered_tax_amount_dr));
        END IF;
        IF (  get_gl_trance_data_rec.entered_item_amount_cr
            + get_gl_trance_data_rec.entered_tax_amount_cr  ) = 0 THEN
--ver 11.5.10.1.0 Change Start
--          l_gl_if_item_rec.accounted_cr := 0;
          l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr;
--ver 11.5.10.1.0 Change End
        ELSE
          l_gl_if_item_rec.accounted_cr := get_gl_trance_data_rec.accounted_amount_cr
                                         *(get_gl_trance_data_rec.entered_item_amount_cr
                                         /(get_gl_trance_data_rec.entered_item_amount_cr
                                          +get_gl_trance_data_rec.entered_tax_amount_cr));
        END IF;
-- ver 1.1 Change End
      END IF;
      l_gl_if_item_rec.accounted_dr   := ROUND(l_gl_if_item_rec.accounted_dr, ln_precision);
      l_gl_if_item_rec.accounted_cr   := ROUND(l_gl_if_item_rec.accounted_cr, ln_precision);
      l_gl_if_item_rec.reference10    := get_gl_trance_data_rec.lines_description;
      l_gl_if_item_rec.attribute2     := get_gl_trance_data_rec.incr_decr_reason_code;
      l_gl_if_item_rec.attribute7     := get_gl_trance_data_rec.attribute7;
      l_gl_if_item_rec.attribute8     := get_gl_trance_data_rec.attribute8;
      l_gl_if_item_rec.attribute9     := get_gl_trance_data_rec.attribute9;
      l_gl_if_item_rec.attribute10    := get_gl_trance_data_rec.attribute10;
      l_gl_if_item_rec.jgzz_recon_ref := get_gl_trance_data_rec.recon_reference;
--
      -- GL�C���^�[�t�F�[�X���R�[�h�^�ɃZ�b�g(����ōs)
      SELECT gcc.segment1 AS segment1,
             gcc.segment2 AS segment2,
             gcc.segment3 AS segment3,
             gcc.segment4 AS segment4,
             gcc.segment5 AS segment5,
             gcc.segment6 AS segment6,
             gcc.segment7 AS segment7,
             gcc.segment8 AS segment8
      INTO   l_gl_if_tax_rec.segment1,
             l_gl_if_tax_rec.segment2,
             l_gl_if_tax_rec.segment3,
             l_gl_if_tax_rec.segment4,
             l_gl_if_tax_rec.segment5,
             l_gl_if_tax_rec.segment6,
             l_gl_if_tax_rec.segment7,
             l_gl_if_tax_rec.segment8
      FROM   xx03_tax_codes_v xtcv,
             gl_code_combinations gcc
      WHERE  xtcv.name = get_gl_trance_data_rec.tax_code
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      AND    get_gl_trance_data_rec.gl_date BETWEEN NVL(xtcv.start_date, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
      AND    NVL(xtcv.inactive_date, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
      -- Ver11.5.10.1.6 2005/12/15 Add End
      AND    xtcv.tax_code_combination_id = gcc.code_combination_id;
--
      l_gl_if_tax_rec.entered_dr     := get_gl_trance_data_rec.entered_tax_amount_dr;
      l_gl_if_tax_rec.entered_cr     := get_gl_trance_data_rec.entered_tax_amount_cr;
      l_gl_if_tax_rec.accounted_dr   := get_gl_trance_data_rec.accounted_amount_dr
                                      - l_gl_if_item_rec.accounted_dr;
      l_gl_if_tax_rec.accounted_cr   := get_gl_trance_data_rec.accounted_amount_cr
                                      - l_gl_if_item_rec.accounted_cr;
      l_gl_if_tax_rec.reference10    := NULL;
      l_gl_if_tax_rec.attribute2     := NULL;
      l_gl_if_tax_rec.attribute7     := NULL;
      l_gl_if_tax_rec.attribute8     := NULL;
      l_gl_if_tax_rec.attribute9     := NULL;
      l_gl_if_tax_rec.attribute10    := NULL;
      l_gl_if_tax_rec.jgzz_recon_ref := NULL;
--
      -- =======================================
      -- GLI/F�̍X�V - �{�̏��̓o�^ (A-2)
      -- =======================================
      ins_gl_interface(
        l_gl_if_item_rec,                         -- 1.GL�C���^�[�t�F�[�X���R�[�h(IN)
        lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =======================================
      -- GLI/F�̍X�V - ����ŏ��̓o�^ (A-2)
      -- =======================================
      --2005.04.26 change start Ver11.5.10.1.1
      IF (l_gl_if_tax_rec.entered_dr IS NULL AND
        l_gl_if_tax_rec.entered_cr <> 0) OR
        (l_gl_if_tax_rec.entered_cr IS NULL AND
        l_gl_if_tax_rec.entered_dr <> 0) THEN
        ins_gl_interface(
          l_gl_if_tax_rec,                          -- 1.GL�C���^�[�t�F�[�X���R�[�h(IN)
          lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END IF;
      --2005.04.26 change end Ver11.5.10.1.1
--
      -- ver 11.5.10.2.10 Add Start
      -- ���펞����
      IF (ov_retcode != xx00_common_pkg.set_status_error_f) AND
         (ov_retcode != xx00_common_pkg.set_status_warn_f ) THEN
        --�d��`�[�f�[�^�̍X�V
        UPDATE  xx03_journal_slips xjs
        SET     xjs.gl_forword_date   = od_upd_date,
                xjs.last_update_date  = od_upd_date,
                xjs.last_updated_by   = xx00_global_pkg.user_id,
                xjs.last_update_login = xx00_global_pkg.last_update_login
        WHERE   xjs.journal_id = get_gl_trance_data_rec.journal_id
        ;
      END IF;
      -- ver 11.5.10.2.10 Add End
--
    END LOOP get_gl_trance_loop;
    CLOSE get_gl_trance_data_cur;
--
    --���O�o��
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_data_none_expt THEN        --*** �]�������Ώۃf�[�^���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01058'));           -- �]�������Ώۃf�[�^���擾�G���[���b�Z�[�W
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
    WHEN get_slip_type_name_expt THEN   --*** �d��J�e�S���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01060',             -- �d��J�e�S���擾�G���[���b�Z�[�W
          'XX03_TOK_SLIP_TYPE',
          lv_slip_type));               -- �`�[��ʃR�[�h
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      -- Ver11.5.10.1.6B Change Start
      --ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
      -- Ver11.5.10.1.6B Change End
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      IF get_gl_trance_data_cur%ISOPEN THEN
        CLOSE get_gl_trance_data_cur;
      END IF;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_approval_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_data
   * Description      : GL�]���ώd��`�[�f�[�^�̍X�V (A-3)
   ***********************************************************************************/
  PROCEDURE upd_slip_data(
    in_org_id         IN  NUMBER,       -- 1.�I���OID(IN)
    in_books_id       IN  NUMBER,       -- 2.��v����ID(IN)
    id_sysdate        IN  DATE,         -- 3.�X�V���t(IN)
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
    --�d��`�[�f�[�^�̍X�V
    UPDATE  xx03_journal_slips xjs
    SET     xjs.gl_forword_date   = id_sysdate,
            xjs.last_update_date  = id_sysdate,
            xjs.last_updated_by   = xx00_global_pkg.user_id,
            xjs.last_update_login = xx00_global_pkg.last_update_login
    WHERE   xjs.wf_status = cv_appr_status
    AND     xjs.gl_forword_date IS NULL
    AND     xjs.org_id = in_org_id
    AND     xjs.set_of_books_id = in_books_id;
--
    --���O�o��
    xx00_file_pkg.log('UPDATE table :xx03_journal_slips');
    xx00_file_pkg.log('org_id = '|| TO_CHAR(in_org_id));
    xx00_file_pkg.log('books_id = '|| TO_CHAR(in_books_id));
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
    in_org_id     IN  NUMBER,       --  1.�I���OID(IN)
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
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' || 
      iv_source);
    xx00_file_pkg.output(' ');
--
    -- �����o��
    xx00_file_pkg.output(
    xx00_message_pkg.get_msg(
      'XX03',
      'APP-XX03-01059',             -- ���F�ώd��]�����ʏo��
      'XX03_TOK_HEAD_CNT',
      in_header_cnt,                -- GL�]������(�w�b�_)
      'XX03_TOK_DETAIL_CNT',
      in_detail_cnt));              -- GL�]������(����)
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
    -- �ŏI���F�ώd��f�[�^�̎擾(A-1)
    -- =======================================
    get_approval_slip_data(
      iv_source,          -- 1.�\�[�X��(OUT)
      ln_org_id,          -- 2.�I���OID(OUT)
      ln_books_id,        -- 3.��v����ID(OUT)
      ln_header_cnt,      -- 4.�w�b�_����(OUT)
      ln_detail_cnt,      -- 5.���׌���(OUT)
      ld_upd_date,        -- 6.�X�V���t(OUT)
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      --(�x������)
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSE
--
      -- ver 11.5.10.2.10 Del Start
      ---- =======================================
      ---- GL�]���ώd��f�[�^�̍X�V (A-3)
      ---- =======================================
      --upd_slip_data(
      --  ln_org_id,            -- 1.�I���OID(IN)
      --  ln_books_id,          -- 2.��v����ID(IN)
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
    -- Ver11.5.10.1.6B Change Start
    --IF (retcode = xx00_common_pkg.set_status_error_f) THEN
    IF (retcode != xx00_common_pkg.set_status_normal_f) THEN
    -- Ver11.5.10.1.6B Change End
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
END XX034GT001C;
/

