CREATE OR REPLACE PACKAGE BODY "APPS"."XX03_DEPTINPUT_GL_CHECK_PKG" 
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004. All rights reserved.
 *
 * Package Name           : xx03_deptinput_gl_check_pkg(body)
 * Description            : �������(GL)�ɂ����ē��̓`�F�b�N���s�����ʊ֐�
 * MD.070                 : �������(GL)���ʊ֐� OCSJ/BFAFIN/MD070/F601/01
 * Version                : 11.5.10.2.12
 *
 * Program List
 *  -------------------------- ---- ----- ------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- ------------------------------------------------
 *  check_deptinput_gl          P          �������(GL)�̃G���[�`�F�b�N
 *  set_account_approval_flag   P          �d�_�Ǘ��`�F�b�N
 *  del_journal_data            P          �d��`�[���R�[�h�̍폜
 *
 * Change Record
 * ------------ -------------- -----------------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -----------------------------------------------------------
 *  2004/11/08   1.0            �V�K�쐬
 *  2005/02/21   1.1            structure�s��Ή�
 *  2005/09/02   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/18   11.5.10.1.5B   ����`�[���ēx�\���ł��Ă��܂��s��Ή�
 *  2005/11/07   11.5.10.1.6    ���͉�ʂł̓`�[��ʎ擾���@�ύX�ɔ����Ή�
 *  2005/12/15   11.5.10.1.6B   ����Ŋz���e�͈̓`�F�b�N�p�J�[�\������
 *                              �ŋ��R�[�h�̗L���`�F�b�N�ǉ�
 *  2006/01/16   11.5.10.1.6C   CF�g�ݍ��킹�}�X�^�擾�G���[��L���ɂ���
 *  2006/01/19   11.5.10.1.6D   ���[�N�e�[�u���ɉ�v���Ԃ�n���悤�ɕύX
 *  2006/01/30   11.5.10.1.6E   ���݌��؃��[���̃`�F�b�N�ŁA���t��GL�v�����
 *                              �n���悤�ύX
 *  2006/02/15   11.5.10.1.6F   �_�u���N���b�N�Ή�,PKG��commit����PROCEDURE�ǉ�
 *  2006/02/18   11.5.10.1.6G   �}�X�^�[���݃`�F�b�N�����{����悤�ɕύX
 *  2006/03/02   11.5.10.1.6H   �G���[�`�F�b�N�e�[�u���̃N���A���W�b�N�̕s�
 *  2006/03/02   11.5.10.1.6I   �}�X�^�[�`�F�b�N�̊e�^�C�~���O�ł̏����̓���
 *  2006/03/03   11.5.10.1.6J   ���F�҂̏��F�����`�F�b�N�s��C��
 *  2006/03/29   11.5.10.2.1    HR�Ή��i�]�ƈ��������R�[�h�Ή��j
 *  2006/04/07   11.5.10.2.2    ���F�҂��Ώۓ`�[�ɑ΂��鏳�F���������邩�̃`�F�b�N�ǉ�
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2�ł̏C���~�X�Ή�
 *  2006/06/22   11.5.10.2.3    �}�X�^�`�F�b�N�pSQL�Ńf�[�^���擾�łȂ���������
 *                              �G���[����������Ă��邱�Ƃ̏C��
 *  2006/12/06   11.5.10.2.6    ��v���ԃ`�F�b�N�pSQL��GL�v��������Ƀf�[�^��
 *                              �擾���Ă���̂��A���̂����Ɏ擾����悤�ɕύX
 *  2007/06/13   11.5.10.2.9    �}�X�^�[�`�F�b�N����C�����̏����R��
 *                              java�ő��݂���`�F�b�N��{�p�b�P�[�W�ɂ��ǉ�
 *  2007/06/18   11.5.10.2.9B   �ݎ؂œ������b�Z�[�W���o�͂��Ă������A���ꂼ��
 *                              �قȂ郁�b�Z�[�W���o�͂���悤�ɏC��
 *  2007/06/22   11.5.10.2.9C   AP/AR�Ə��������킹�邽�ߋ��ʊ֐��Ăяo���O����̒ǉ�
 *  2007/08/10   11.5.10.2.10   �d��z���`�F�b�N�ŃG���[�̎��̃��b�Z�[�W��
 *                              �w�b�_����ץ�ŋ��̂ǂ̔z������\������悤�ɏC��
 *  2007/10/29   11.5.10.2.10B  �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ�
 *  2010/04/05   11.5.10.2.11   [E_�{�ғ�_02174]������̓G���[�`�F�b�N���ʂ��x���̏ꍇ�A
 *                                              ���ʃG���[�`�F�b�N�����s����悤�ɕύX
 *  2013/09/19   11.5.10.2.12   [E_�{�ғ�_10999]���ڐ������`�F�b�N�ǉ�
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_gl
   * Description      : �������(GL)�̃G���[�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_deptinput_gl(
    in_journal_id  IN   NUMBER,    -- 1.�`�F�b�N�Ώێd��`�[ID
    on_error_cnt   OUT  NUMBER,    -- 2.�����S�̂ł̃G���[�t���O
    ov_error_flg   OUT  VARCHAR2,  -- 3.�����S�̂ł̃G���[�t���O
    ov_error_flg1  OUT  VARCHAR2,  -- 4.1�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg1  OUT  VARCHAR2,  -- 5.1�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg2  OUT  VARCHAR2,  -- 6.2�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg2  OUT  VARCHAR2,  -- 7.2�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg3  OUT  VARCHAR2,  -- 8.3�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg3  OUT  VARCHAR2,  -- 9.3�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg4  OUT  VARCHAR2,  -- 10.4�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg4  OUT  VARCHAR2,  -- 11.4�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg5  OUT  VARCHAR2,  -- 12.5�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg5  OUT  VARCHAR2,  -- 13.5�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg6  OUT  VARCHAR2,  -- 14.6�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg6  OUT  VARCHAR2,  -- 15.6�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg7  OUT  VARCHAR2,  -- 16.7�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg7  OUT  VARCHAR2,  -- 17.7�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg8  OUT  VARCHAR2,  -- 18.8�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg8  OUT  VARCHAR2,  -- 19.8�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg9  OUT  VARCHAR2,  -- 20.9�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg9  OUT  VARCHAR2,  -- 21.9�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg10 OUT  VARCHAR2,  -- 22.10�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg10 OUT  VARCHAR2,  -- 23.10�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg11 OUT  VARCHAR2,  -- 24.11�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg11 OUT  VARCHAR2,  -- 25.11�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg12 OUT  VARCHAR2,  -- 26.12�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg12 OUT  VARCHAR2,  -- 27.12�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg13 OUT  VARCHAR2,  -- 28.13�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg13 OUT  VARCHAR2,  -- 29.13�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg14 OUT  VARCHAR2,  -- 30.14�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg14 OUT  VARCHAR2,  -- 31.14�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg15 OUT  VARCHAR2,  -- 32.15�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg15 OUT  VARCHAR2,  -- 33.15�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg16 OUT  VARCHAR2,  -- 34.16�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg16 OUT  VARCHAR2,  -- 35.16�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg17 OUT  VARCHAR2,  -- 36.17�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg17 OUT  VARCHAR2,  -- 37.17�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg18 OUT  VARCHAR2,  -- 38.18�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg18 OUT  VARCHAR2,  -- 39.18�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg19 OUT  VARCHAR2,  -- 40.19�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg19 OUT  VARCHAR2,  -- 41.19�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg20 OUT  VARCHAR2,  -- 42.20�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg20 OUT  VARCHAR2,  -- 43.20�ڂ�RETURN�f�[�^�̃G���[���e
    ov_errbuf      OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.check_deptinput_gl'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ###############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �ʉ݂��擾�ł��Ȃ������ꍇ�̐��x
    cn_curr_precision CONSTANT fnd_currencies.precision%TYPE := 2;
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�t���O�p�z��^�C�v
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
    -- �G���[���b�Z�[�W�p�z��^�C�v
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    errflg_tbl errflg_tbl_type;
    errmsg_tbl errmsg_tbl_type;
    ln_err_cnt NUMBER := 0;    -- �p�����[�^�Y���p�ϐ�
-- ver 11.5.10.2.11 Add Start
    ln_warn_cnt NUMBER := 0;   -- �x������
-- ver 11.5.10.2.11 Add End
    ln_books_id gl_tax_options.set_of_books_id%TYPE;    -- ����ID
    ln_org_id   gl_tax_options.org_id%TYPE;             --�I���OID
    lv_first_flg VARCHAR2(1) := 'Y';  -- 1���ڂ̃��R�[�h���ۂ�
-- ver 11.5.10.1.6H Chg Start
    --ln_check_seq NUMBER;       -- �G���[�`�F�b�N�V�[�P���X�ԍ�
    ln_check_seq NUMBER := 0;  -- �G���[�`�F�b�N�V�[�P���X�ԍ�
-- ver 11.5.10.1.6H Chg End
    ln_cnt NUMBER;             -- ���[�v�J�E���^
    lv_err_status VARCHAR2(1); -- ���ʃG���[�`�F�b�N�X�e�[�^�X
    lv_currency_code VARCHAR2(15); -- �@�\�ʉ݃R�[�h
    lv_chk_currency_code VARCHAR2(15);      -- �`�F�b�N�p�f�[�^�ʉ݃R�[�h
    ln_chk_exchange_rate NUMBER;            -- �`�F�b�N�p�f�[�^���Z���[�g
    lv_chk_exchange_rate_type VARCHAR2(30); -- �`�F�b�N�p�f�[�^���Z���[�g�^�C�v
    ld_chk_gl_date DATE;                    -- �`�F�b�N�p�f�[�^�v���
    lv_chk_orig_journal_num VARCHAR2(150);  -- �`�F�b�N�p�f�[�^�C�����`�[�ԍ�
    lv_attribute2 VARCHAR2(240);            -- �`�F�b�N�p���Z�S���t���O
    -- 2004-12-24:���݌��ؗp�p�����[�^
    lb_retcode BOOLEAN;
    lv_app_short_name VARCHAR2(100) := 'SQLGL';
    lv_key_flex_code VARCHAR2(1000) := 'GL#'; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_NUM, ID_FLEX_STRUCTURE_CODE(�ݒ�:��v:�t���b�N�X�t�B�[���h:�L�[:�Z�O�����g)
    ld_validation_date DATE := SYSDATE;
    ln_segments NUMBER := 8;
    lv_segment_array FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id NUMBER := null;
    ld_data_set NUMBER := -1;
    -- 2006/03/06 Ver11.5.10.1.6J Add Start
    ld_wf_status              VARCHAR2(25);        -- �`�F�b�N�p���[�N�t���[�X�e�[�^�X
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- ������͏��F�҂��X�e�[�^�X
    -- 2006/03/06 Ver11.5.10.1.6J Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- ������͕ۑ��X�e�[�^�X
    cn_wf_status_last   VARCHAR2(25) := '30';      -- ������͍ŏI���右�F�҂��X�e�[�^�X
    -- ver 11.5.10.2.2 Add End
--
-- ver 11.5.10.2.9 Add Start
    ln_chk_total_dr NUMBER;      -- �`�F�b�N�p�f�[�^�ؕ����Z�ύ��v���z
    ln_chk_total_cr NUMBER;      -- �`�F�b�N�p�f�[�^�ݕ����Z�ύ��v���z
    lv_chk_dr_cr    VARCHAR2(2); -- �`�F�b�N�Ώۖ��בݎ؋敪
-- ver 11.5.10.2.9 Add End
--
    -- ver 11.5.10.2.10 Add Start
    lv_je_err_msg       VARCHAR2(14);              -- �z���`�F�b�N�G���[���̒ǉ����b�Z�[�W�R�[�h
    -- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.10B Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- �ʉ݃G���[OK/NG�t���O(���x�`�F�b�N���Ɏg�p)
    ln_currency_precision  NUMBER(1)    := 0;      -- �ʉ݂̐��x(�ʉ݃`�F�b�NOK���ɐ��x���擾)
    lv_amount              VARCHAR2(50) := '';     -- �`�[�ł̋��z���x�擾�p
    ln_amount_precision    NUMBER(1)    := 0;      -- �`�[�ł̋��z�̐��x
    cv_precision_char      VARCHAR2(1)  := '.';    -- �����_�L��
    -- ver 11.5.10.2.10B Add End
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����Ώۃf�[�^�擾�J�[�\��
    CURSOR xx03_xjsjlv_cur
    IS
      SELECT xjsjlv.journal_num as journal_num,
             xjsjlv.line_number as line_number,
             xjsjlv.gl_date as gl_date,
             xjsjlv.invoice_currency_code as invoice_currency_code,
             xjsjlv.code_combination_id as code_combination_id,
             xjsjlv.segment1 as segment1,
             xjsjlv.segment2 as segment2,
             xjsjlv.segment3 as segment3,
             xjsjlv.segment4 as segment4,
             xjsjlv.segment5 as segment5,
             xjsjlv.segment6 as segment6,
             xjsjlv.segment7 as segment7,
             xjsjlv.segment8 as segment8,
             xjsjlv.tax_code as tax_code,
             xjsjlv.incr_decr_reason_code as incr_decr_reason_code,
             xjsjlv.entry_department as entry_department,
             xjsjlv.user_name as user_name,
             xjsjlv.recon_reference as recon_reference,
             xjsjlv.entered_dr as entered_dr,
-- 2005/1/19 Ver11.5.10.1.6D Add Start
--             xjsjlv.entered_cr as entered_cr
             xjsjlv.entered_cr as entered_cr,
             xjsjlv.PERIOD_NAME
-- Ver11.5.10.1.6G Add Start
           , xjsjlv.line_type_lookup_code as line_type_lookup_code
-- Ver11.5.10.1.6G Add End
-- 2005/1/19 Ver11.5.10.1.6D Add End
        FROM xx03_jn_slip_journal_lines_v xjsjlv
       WHERE xjsjlv.journal_id = in_journal_id
       ORDER BY xjsjlv.line_number;
--
    -- ���[�g�J�[�\��
    CURSOR xx03_rate_cur(
      iv_invoice_currency_code IN VARCHAR2, -- 1.�ʉ݃R�[�h
      iv_exchange_rate_type IN VARCHAR2,    -- 2.���[�g�^�C�v
      id_gl_date IN DATE                    -- 3.GL�L����
    ) IS
      SELECT xgdr.conversion_rate as conversion_rate
        FROM xx03_gl_daily_rates_v xgdr
       WHERE xgdr.from_currency = iv_invoice_currency_code
         AND xgdr.conversion_type = iv_exchange_rate_type
         AND xgdr.conversion_date = TRUNC(id_gl_date);
--
    -- �C�����`�[�ԍ��`�F�b�N�J�[�\��
    CURSOR xx03_orig_num_cur(
      iv_orig_journal_num  IN VARCHAR2 -- 1.�C�����`�[�ԍ�
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_journal_slips_v xjsv
--       WHERE xjsv.gl_forword_date IS NULL
--         AND xjsv.orig_journal_num = iv_orig_journal_num
--         AND xjsv.wf_status >= 20
--         AND xjsv.journal_id != in_journal_id;
      -- Ver11.5.10.1.5B 2005/10/18 Change Start
      --SELECT *
      --  FROM xx03_journal_slips xjs
      -- WHERE xjs.gl_forword_date IS NULL
      --   AND xjs.orig_journal_num = iv_orig_journal_num
      --   AND xjs.wf_status >= 20
      --   AND xjs.journal_id != in_journal_id
      --   AND xjs.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM xx03_journal_slips xjs
       WHERE xjs.orig_journal_num = iv_orig_journal_num
         AND xjs.wf_status >= 20
         AND xjs.journal_id != in_journal_id
         AND xjs.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5B 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
-- ver 11.5.10.2.6 Chg Start
    -- ��v���ԃ`�F�b�N�J�[�\��
--    CURSOR xx03_gl_period_status_cur(
--      in_books_id   IN NUMBER,    -- 1.����ID
--      id_gl_date    IN DATE       -- 2.GL�L����
--    ) IS
--      SELECT gps.attribute5 as attribute5,           -- GL������̓X�e�[�^�X
--             gps.adjustment_period_flag as adj_flag, -- �������ԃt���O
--             gps.closing_status as closing_status    -- GL�X�e�[�^�X
---- ver 11.5.10.1.6I Add Start
--           , gps.period_name as period_name          -- ��v���Ԗ���
---- ver 11.5.10.1.6I Add End
--        FROM gl_period_statuses gps
--       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
--         AND gps.set_of_books_id = in_books_id
--         AND gps.start_date <= TRUNC(id_gl_date)
--         AND gps.end_date >= TRUNC(id_gl_date);
    CURSOR xx03_gl_period_status_cur(
      in_books_id     IN NUMBER,    -- 1.����ID
      iv_period_name  IN VARCHAR2   -- 2.��v���Ԗ���
    ) IS
      SELECT gps.attribute5 as attribute5,           -- GL������̓X�e�[�^�X
             gps.adjustment_period_flag as adj_flag, -- �������ԃt���O
             gps.closing_status as closing_status,   -- GL�X�e�[�^�X
             gps.start_date as start_date,           -- �J�n���t
             gps.end_date as end_date                -- �I�����t
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id = in_books_id
         AND gps.period_name = iv_period_name;
-- ver 11.5.10.2.6 Chg End
--
-- ver 11.5.10.2.2 add Start
    -- �\���҂Ə��F�҂̊֌W �`�F�b�N�J�[�\��
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_JOURNAL_SLIPS          XJS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XJS.JOURNAL_ID = in_journal_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XJS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XJS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'SQLGL'   )
      AND  XAPV.PERSON_ID   = XJS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--Ver11.5.10.1.6G Add start
--
    --���F�҃`�F�b�N�J�[�\��
    CURSOR xx03_approver_cur
    IS
-- 2006/03/03 Ver11.5.10.1.6J Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_journal_slips    xjs
--     WHERE xjs.journal_id   = in_journal_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xjs.requestor_person_id;
    SELECT COUNT(1) exist_check
    FROM   xx03_per_peoples_v xppv1
          ,(SELECT paf.supervisor_id
            FROM   xx03_per_peoples_v xppv
                  ,per_assignments_f  paf
            WHERE  xppv.user_id  = XX00_PROFILE_PKG.VALUE('USER_ID')
              -- ver 11.5.10.2.1 Add Start
              AND  SYSDATE BETWEEN paf.effective_start_date
                               AND paf.effective_end_date
              -- ver 11.5.10.2.1 Add End
              AND  paf.person_id = xppv.person_id
            ) xppv2
    WHERE  xppv1.person_id = xppv2.supervisor_id
      AND  EXISTS (SELECT '1'
                   FROM
                     (SELECT XAPV.PERSON_ID
                       FROM XX03_APPROVER_PERSON_V      XAPV
                           ,XX03_JOURNAL_SLIPS          XJS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XJS.JOURNAL_ID = in_journal_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XJS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XJS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'SQLGL'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/03 Ver11.5.10.1.6J Change End
--
    --�K�p�R�[�h�`�F�b�N
    CURSOR xx03_jsl_slt_dr_cur(
      in_line_number IN number     -- 1.���הԍ�
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      AND  XJSL.SLIP_LINE_TYPE_DR      IS NOT NULL;
--
    CURSOR xx03_slip_line_type_dr_cur(
      in_line_number IN number,    -- 1.���הԍ�
      id_gl_date     IN DATE       -- 2.GL�L����
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XJSL.SLIP_LINE_TYPE_DR
      AND  id_gl_date BETWEEN XLXV.START_DATE_ACTIVE
                      AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
    CURSOR xx03_jsl_slt_cr_cur(
      in_line_number IN number     -- 1.���הԍ�
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      AND  XJSL.SLIP_LINE_TYPE_CR      IS NOT NULL;
--
    CURSOR xx03_slip_line_type_cr_cur(
      in_line_number IN number,    -- 1.���הԍ�
      id_gl_date     IN DATE       -- 2.GL�L����
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XJSL.SLIP_LINE_TYPE_CR
      AND  id_gl_date BETWEEN XLXV.START_DATE_ACTIVE
                      AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
--Ver11.5.10.1.6G Add start
--
    -- ���ʃG���[�`�F�b�N���ʎ擾�J�[�\��
    CURSOR xx03_errchk_result_cur
    IS
-- ver 11.5.10.1.6I Chg Start
--      SELECT xei.journal_id as journal_id,
--             xei.line_number as line_number,
--             xlgv.meaning as dr_cr,
--             xei.error_code as error_code,
--             xei.error_message as error_message,
--             xei.status as status
--        FROM xx03_error_info xei,
--             xx03_lookups_gl_v xlgv
--       WHERE xei.check_id = ln_check_seq
--       AND   xlgv.lookup_type = 'GL_DR_CR'
--       AND   xlgv.lookup_code = xei.dr_cr
--      -- Ver11.5.10.1.6C 2006/01/16 Change Start
--       ORDER BY xei.dr_cr, line_number;
--      --UNION ALL
--      --SELECT xei.journal_id as journal_id,
--      --       xei.line_number as line_number,
--      --       ' ',
--      --       xei.error_code as error_code,
--      --       xei.error_message as error_message,
--      --       xei.status as status
--      --  FROM xx03_error_info xei
--      -- WHERE xei.check_id = ln_check_seq
--      -- AND   xei.dr_cr = ' ';
--      -- Ver11.5.10.1.6C 2006/01/16 Change End
      SELECT err_info.journal_id
           , err_info.line_number
           , err_info.dr_cr
           , err_info.error_code
           , err_info.error_message
           , err_info.status
        FROM
      (
        SELECT xei.journal_id    as journal_id
             , xei.line_number   as line_number
             , xlgv.meaning      as dr_cr
             , xei.error_code    as error_code
             , xei.error_message as error_message
             , xei.status        as status
          FROM xx03_error_info xei,
               xx03_lookups_gl_v xlgv
         WHERE xei.check_id = ln_check_seq
         AND   xlgv.lookup_type = 'GL_DR_CR'
         AND   xlgv.lookup_code = xei.dr_cr
        UNION ALL
        SELECT xei.journal_id    as journal_id
             , xei.line_number   as line_number
             , ' '               as dr_cr
             , xei.error_code    as error_code
             , xei.error_message as error_message
             , xei.status        as status
          FROM xx03_error_info xei
         WHERE xei.check_id = ln_check_seq
         AND   xei.dr_cr = ' '
       ) err_info
      ORDER BY dr_cr, line_number;
-- ver 11.5.10.1.6I Chg End
--
    --�ŋ��I�v�V�����\����
    CURSOR gl_tax_options_cur(
      in_books_id        IN  gl_tax_options.set_of_books_id%TYPE,  -- 1.����ID
      in_org_id          IN  gl_tax_options.org_id %TYPE           -- 2.�I���OID
    ) IS
      SELECT a.attribute1,               --���e�͈͗�
             a.attribute2,               --���e�͈͍ő���z
             a.input_rounding_rule_code, --�����[�������K��
             a.output_rounding_rule_code --����[�������K��
      FROM   gl_tax_options a
      WHERE  a.set_of_books_id       =  in_books_id
      AND    a.org_id                =  in_org_id;
--
    --����Ŋz���e�͈̓`�F�b�N�p�J�[�\��
    CURSOR tax_range_check_cur(
      in_journal_id                 IN  xx03_journal_slip_lines.journal_id%TYPE,      -- 1.�`�[ID
      in_books_id                   IN  gl_tax_options.set_of_books_id%TYPE,          -- 2.����ID
      iv_input_rounding_rule_code   IN  gl_tax_options.input_rounding_rule_code%TYPE, -- 3.�����[�������K��
      iv_output_rounding_rule_code  IN  gl_tax_options.output_rounding_rule_code%TYPE -- 4.����[�������K��
    ) IS
    SELECT
      xjsjl.journal_id,  --�`�[ID
      xjsjl.segment1,    --��ЃR�[�h
      xjsjl.tax_code,    --�ŋ敪
    --
      sum(
        case
          when ac.attribute6 is null then --����ŉȖڋ敪��NULL(�{�Ȗڍs)
            case
              when nvl(tc.tax_rate,0) = 0 then
                0 --�ŗ�0%�i��ېŁA�s�ېŁA�ƐŁA�ېőΏۊO�j��0�Ƃ��Čv�Z
              else nvl(xjsjl.entered_dr, xjsjl.entered_cr)
            end
          else 0 --�ŋ��s�͉��Z�����B
        end ) sum_no_tax,   --�ŋ��s�łȂ��s�̍��v
    --
      sum(
        case
          when ac.attribute6 is null then --����ŉȖڋ敪��NULL(�{�Ȗڍs)
          case
            when nvl(tc.tax_rate,0) = 0 then 0 --�ŗ�0%��0�Ƃ��Čv�Z
            else
              case tc.attribute2    --�ŋ敪�}�X�^�̉ېŏW�v�敪
                when '1' then     --�ېŔ���(����)
                  case iv_output_rounding_rule_code --�ϐ�. ����[�������K�� (output_rounding_rule_code)  --����[�������K��
                    when 'N' then   --�l�̌ܓ�
                      round(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                    when 'U' then   --�؂�グ
                      sign( nvl(xjsjl.entered_dr,xjsjl.entered_cr)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
                    (trunc((abs( nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    else        --�؂�̂�(d)
                      trunc(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                  end
                else          --�ېŎd��(����)
                  case  iv_input_rounding_rule_code --�ϐ�.�����[�������K��(input_rounding_rule_code)   --�����[�������K��
                    when 'N' then   --�l�̌ܓ�
                      round(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                    when 'U' then   --�؂�グ
                      sign( nvl(xjsjl.entered_dr,xjsjl.entered_cr)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
                    (trunc((abs( nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    else        --�؂�̂�(d)
                      trunc(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                  end
              end
          end
      else 0 --�ŋ��s�͑ΏۊO
      end
      ) sum_cal_tax,    --�v�Z�ɂ��ŋ��s�̍��v
    --
      sum(
        case
          when ac.attribute6 is not null then   --����ŉȖڋ敪��NOT NULL(�ŋ��s)
            nvl(xjsjl.entered_dr,xjsjl.entered_cr)
          else
            0       --�ŋ��s�łȂ���Ή��Z�����B
        end
      ) sum_tax     --�ŋ��s�̍��v
    FROM xx03_jn_slip_journal_lines_v  xjsjl, --�`�[���׃e�[�u��
         xx03_accounts_v           ac, --����Ȗڃ}�X�^
         xx03_tax_codes_v          tc, --�ŋ敪�}�X�^
         fnd_currencies            fc  --�ʉ݃}�X�^
    WHERE xjsjl.journal_id = in_journal_id
      and xjsjl.segment3   = ac.flex_value
      and xjsjl.tax_code   = tc.name (+)
      and tc.set_of_books_id (+)     = in_books_id --�ϐ�.����ID
      and xjsjl.invoice_currency_code = fc. currency_code (+)
      -- Ver11.5.10.1.6B 2005/12/15 Add Start
      and (tc.start_date    IS NULL or tc.start_date  <= xjsjl.gl_date )
      and (tc.inactive_date IS NULL or tc.inactive_date  >= xjsjl.gl_date)
      -- Ver11.5.10.1.6B 2005/12/15 Add End
    GROUP BY
      xjsjl.journal_id,  --�d��id
      xjsjl.segment1,    --��ЃR�[�h
      xjsjl.tax_code     --�ŋ敪
    ORDER BY
      xjsjl.journal_id,--�d��id
      xjsjl.segment1,  --��ЃR�[�h
      xjsjl.tax_code;  --�ŋ敪
--
-- ver 11.5.10.2.9 Add Start
    -- ver 11.5.10.2.10B Chg Start
    --CURSOR xx03_inv_currency_cur(
    --  iv_currency_code IN VARCHAR2   -- 1.�ʉ݃R�[�h
    --) IS
    --  SELECT COUNT(1) exist_check
    --    FROM fnd_currencies fc
    --   WHERE fc.enabled_flag  = 'Y'
    --     AND fc.currency_flag = 'Y'
    --     AND fc.currency_code = iv_currency_code
    --     AND TRUNC(SYSDATE) BETWEEN NVL(fc.start_date_active, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                            AND NVL(fc.end_date_active  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --
    --�ʉ݃`�F�b�N(���x�`�F�b�N�p�ɐ��x���擾����悤�ɕύX)
    CURSOR xx03_inv_currency_cur(
      iv_currency_code IN VARCHAR2   -- 1.�ʉ݃R�[�h
    ) IS
    SELECT fc.currency_code      CURRENCY_CODE
          ,NVL(fc.precision , 0) PRECISION
      FROM fnd_currencies fc
     WHERE fc.enabled_flag  = 'Y'
       AND fc.currency_flag = 'Y'
       AND fc.currency_code = iv_currency_code
       AND TRUNC(SYSDATE) BETWEEN NVL(fc.start_date_active, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                AND NVL(fc.end_date_active  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10B Chg End
--
    --�ŋ��R�[�h�`�F�b�N
    CURSOR xx03_line_tax_cur(
      in_line_number IN number    -- 1.���הԍ�
     ,iv_drcr_flg    IN VARCHAR2  -- 2.�ݎ؃t���O('DR'or'CR')
     ,id_gl_date     IN DATE      -- 3.GL���t
    ) IS
      SELECT COUNT(1) exist_check
        FROM xx03_journal_slip_lines xjsl
            ,xx03_tax_codes_lov_v    xtclv
       WHERE xjsl.journal_id  = in_journal_id
         AND xjsl.line_number = in_line_number
         AND (    (iv_drcr_flg = 'DR' AND xjsl.tax_code_dr is not null)
               OR (iv_drcr_flg = 'CR' AND xjsl.tax_code_cr is not null) )
         AND xtclv.name       = NVL(xjsl.tax_code_dr ,xjsl.tax_code_cr)
         AND id_gl_date BETWEEN NVL(xtclv.start_date   , TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                            AND NVL(xtclv.inactive_date, TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
    --�@�\�ʉݎ��A���͂Ɗ��Z�ς̈�v�`�F�b�N
    CURSOR xx03_enter_account_cur(
      in_line_number IN number    -- 1.���הԍ�
     ,iv_drcr_flg    IN VARCHAR2  -- 2.�ݎ؃t���O('DR'or'CR')
    ) IS
      SELECT NVL(xjsl.entered_item_amount_dr ,xjsl.entered_item_amount_cr) entered_item_amount
            ,NVL(xjsl.entered_tax_amount_dr  ,xjsl.entered_tax_amount_cr ) entered_tax_amount
            ,NVL(xjsl.accounted_amount_dr    ,xjsl.accounted_amount_cr   ) accounted_amount
        FROM xx03_journal_slip_lines xjsl
       WHERE xjsl.journal_id  = in_journal_id
         AND xjsl.line_number = in_line_number
         AND (    (iv_drcr_flg = 'DR' AND xjsl.entered_amount_dr is not null)
               OR (iv_drcr_flg = 'CR' AND xjsl.entered_amount_cr is not null) );
-- ver 11.5.10.2.9 Add End
--
-- 2013/09/19 ver 11.5.10.2.12 ADD START
    -- ���ڐ������`�F�b�N�J�[�\��
    CURSOR xx03_save_code_chk_cur(
      in_org_id          IN  NUMBER  -- �c�ƒP��ID
    , in_set_of_books_id IN  NUMBER  -- ��v����ID
    )
    IS
      SELECT /*+ LEADING(xjs xjsl) */
             COUNT(1)                AS exist_check
      FROM   xx03_journal_slips      xjs  -- GL������̓w�b�_
           , xx03_journal_slip_lines xjsl -- GL������͖���
      WHERE  xjs.journal_id       = in_journal_id      -- �`�[ID
      AND    xjs.org_id           = in_org_id          -- �c�ƒP��ID
      AND    xjs.set_of_books_id  = in_set_of_books_id -- ��v����ID
      AND    xjs.journal_id       = xjsl.journal_id    -- �`�[ID
      AND (
           ( SUBSTRB( xjs.requestor_person_name, 1, 5 ) <> ( SELECT papf.employee_number AS employee_number         -- �\���Җ�
                                                             FROM   per_all_people_f     papf
                                                             WHERE  papf.person_id = xjs.requestor_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( SUBSTRB( xjs.approver_person_name, 1, 5 )  <> ( SELECT papf.employee_number AS employee_number         -- ���F�Җ�
                                                             FROM   per_all_people_f     papf
                                                             WHERE  papf.person_id = xjs.approver_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( ( xjsl.slip_line_type_dr IS NULL )     AND ( xjsl.slip_line_type_name_dr IS NOT NULL ) )               -- �ؕ� �E�v�R�[�h��
        OR ( ( xjsl.slip_line_type_dr IS NOT NULL ) AND ( xjsl.slip_line_type_name_dr IS NULL ) )                   -- �ؕ� �E�v�R�[�h��
        OR ( xjsl.slip_line_type_dr <> SUBSTRB( xjsl.slip_line_type_name_dr, 1, LENGTHB(xjsl.slip_line_type_dr) ) ) -- �ؕ� �E�v�R�[�h��
        OR ( xjsl.tax_code_dr       <> SUBSTRB( xjsl.tax_name_dr,            1, LENGTHB(xjsl.tax_code_dr) ) )       -- �ؕ� �ŋ��R�[�h��
        OR ( ( xjsl.slip_line_type_cr IS NULL )     AND ( xjsl.slip_line_type_name_cr IS NOT NULL ) )               -- �ݕ� �E�v�R�[�h��
        OR ( ( xjsl.slip_line_type_cr IS NOT NULL ) AND ( xjsl.slip_line_type_name_cr IS NULL ) )                   -- �ݕ� �E�v�R�[�h��
        OR ( xjsl.slip_line_type_cr <> SUBSTRB( xjsl.slip_line_type_name_cr, 1, LENGTHB(xjsl.slip_line_type_cr) ) ) -- �ݕ� �E�v�R�[�h��
        OR ( xjsl.tax_code_cr       <> SUBSTRB( xjsl.tax_name_cr,            1, LENGTHB(xjsl.tax_code_cr) ) )       -- �ݕ� �ŋ��R�[�h��
        OR ( xjsl.segment1 <> SUBSTRB( xjsl.segment1_name, 1, LENGTHB(xjsl.segment1) ) )                            -- AFF ���
        OR ( xjsl.segment2 <> SUBSTRB( xjsl.segment2_name, 1, LENGTHB(xjsl.segment2) ) )                            -- AFF ����
        OR ( xjsl.segment3 <> SUBSTRB( xjsl.segment3_name, 1, LENGTHB(xjsl.segment3) ) )                            -- AFF ����Ȗ�
        OR ( xjsl.segment4 <> SUBSTRB( xjsl.segment4_name, 1, LENGTHB(xjsl.segment4) ) )                            -- AFF �⏕�Ȗ�
        OR ( xjsl.segment5 <> SUBSTRB( xjsl.segment5_name, 1, LENGTHB(xjsl.segment5) ) )                            -- AFF �ڋq
        OR ( xjsl.segment6 <> SUBSTRB( xjsl.segment6_name, 1, LENGTHB(xjsl.segment6) ) )                            -- AFF ���
        OR ( xjsl.segment7 <> SUBSTRB( xjsl.segment7_name, 1, LENGTHB(xjsl.segment7) ) )                            -- AFF �\���P
        OR ( xjsl.segment8 <> SUBSTRB( xjsl.segment8_name, 1, LENGTHB(xjsl.segment8) ) )                            -- AFF �\���Q
          )
      ;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
--
    -- *** ���[�J���E���R�[�h ***
    -- �����Ώۃf�[�^�擾�J�[�\�����R�[�h�^
    xx03_xjsjlv_rec            xx03_xjsjlv_cur%ROWTYPE;
    -- ���[�g�J�[�\�����R�[�h�^
    xx03_rate_rec              xx03_rate_cur%ROWTYPE;
    -- �C�����`�[�ԍ��`�F�b�N�J�[�\�����R�[�h�^
    xx03_orig_num_rec          xx03_orig_num_cur%ROWTYPE;
    -- GL��v���ԃ`�F�b�N�J�[�\�����R�[�h�^
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;
    -- ���ʃG���[�`�F�b�N���ʎ擾���R�[�h�^
    xx03_errchk_result_rec     xx03_errchk_result_cur%ROWTYPE;
    -- �ŋ��I�v�V�����V���g�N���R�[�h�^
    gl_tax_options_rec            gl_tax_options_cur%ROWTYPE;
    -- ����ŋ��e�͈̓`�F�b�N�J�[�\�����R�[�h�^
    tax_range_check_rec           tax_range_check_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add Start
    -- �\����-���F�� �`�F�b�N�J�[�\�����R�[�h�^
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add End
-- Ver11.5.10.1.6G Add Start
    --���F�҃`�F�b�N�J�[�\�����R�[�h�^
    xx03_approver_rec                xx03_approver_cur%ROWTYPE;
    --�K�p�R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    xx03_jsl_slt_dr_rec         xx03_jsl_slt_dr_cur%ROWTYPE;
    xx03_slip_line_type_dr_rec  xx03_slip_line_type_dr_cur%ROWTYPE;
    xx03_jsl_slt_cr_rec         xx03_jsl_slt_cr_cur%ROWTYPE;
    xx03_slip_line_type_cr_rec  xx03_slip_line_type_cr_cur%ROWTYPE;
-- Ver11.5.10.1.6G Add End
--
-- ver 11.5.10.2.9 Add Start
    xx03_inv_currency_rec       xx03_inv_currency_cur%ROWTYPE;
    xx03_line_tax_rec           xx03_line_tax_cur%ROWTYPE;
    xx03_enter_account_rec      xx03_enter_account_cur%ROWTYPE;
-- ver 11.5.10.2.9 Add End
-- 2013/09/19 ver 11.5.10.2.12 ADD START
    -- ���ڐ������`�F�b�N�J�[�\�����R�[�h�^
    xx03_save_code_chk_rec       xx03_save_code_chk_cur%ROWTYPE;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- OUT�p�����[�^������
    FOR ln_cnt IN 0..19 LOOP
      errflg_tbl(ln_cnt) := 'S';
      errmsg_tbl(ln_cnt) := '';
    END LOOP;
--
    -- ����ID�擾
    ln_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- �I���OID�擾
    ln_org_id := xx00_profile_pkg.value ('ORG_ID') ;
--
    -- �����Ώۃf�[�^�擾�J�[�\���I�[�v��
    OPEN xx03_xjsjlv_cur;
    <<xx03_xjsjlv_loop>>
    LOOP
      FETCH xx03_xjsjlv_cur INTO xx03_xjsjlv_rec;
      IF xx03_xjsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          -- 1�����f�[�^���Ȃ��ꍇ
          RAISE NO_DATA_FOUND;
        ELSE
          -- �f�[�^�I��
          EXIT xx03_xjsjlv_loop;
        END IF;
      END IF;
--
      -- 1���ڂɑ΂��Ă̓G���[�`�F�b�N���s
      IF ( lv_first_flg = 'Y' ) THEN
        -- �@�\�ʉ݃R�[�h�擾
        SELECT gsob.currency_code as currency_code
          INTO lv_currency_code
          FROM gl_sets_of_books gsob
         WHERE gsob.set_of_books_id = ln_books_id;
--
        -- �`�F�b�N�p�f�[�^�擾
        SELECT xjsv.invoice_currency_code as invoice_currency_code,
               xjsv.exchange_rate as exchange_rate,
               xjsv.exchange_rate_type as exchange_rate_type,
               xjsv.gl_date as gl_date,
               xjsv.orig_journal_num as orig_journal_num
        --2006/03/06 Ver11.5.10.1.6J add start
             , xjsv.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6J add End
-- ver 11.5.10.2.9 Add Start
             , xjsv.TOTAL_ACCOUNTED_DR
             , xjsv.TOTAL_ACCOUNTED_CR
-- ver 11.5.10.2.9 Add Start
          INTO lv_chk_currency_code,
               ln_chk_exchange_rate,
               lv_chk_exchange_rate_type,
               ld_chk_gl_date,
               lv_chk_orig_journal_num
        --2006/03/06 Ver11.5.10.1.6J add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6J add End
-- ver 11.5.10.2.9 Add Start
             , ln_chk_total_dr
             , ln_chk_total_cr
-- ver 11.5.10.2.9 Add End
-- Ver11.5.10.1.6 2005/11/07 Change Start
--          FROM xx03_journal_slips_v xjsv
          FROM xx03_journal_slips xjsv
-- Ver11.5.10.1.6 2005/11/07 Change End
         WHERE xjsv.journal_id = in_journal_id;
--
        -- �`�F�b�N�p�f�[�^�擾
        SELECT  xdv.attribute2
          INTO  lv_attribute2
          FROM  xx03_entry_person_lov_v  xeplv
               ,xx03_departments_v xdv
         WHERE  xeplv.attribute28 = xdv.flex_value
           AND  xeplv.user_id = XX00_GLOBAL_PKG.USER_ID;
--
        -- ���[�g�`�F�b�N
        IF ( lv_currency_code = lv_chk_currency_code ) THEN
          IF ( ln_chk_exchange_rate IS NOT NULL
               OR  lv_chk_exchange_rate_type IS NOT NULL ) THEN
            -- �ʉ݃R�[�h���@�\�ʉ݂ŁA�����[�g�����[�g�^�C�v�ɓ��͒l����
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14001');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        ELSE
          IF ( ln_chk_exchange_rate IS NULL ) THEN
            -- �ʉ݃R�[�h���@�\�ʉ݂łȂ��A�����[�g�ɓ��͒l�Ȃ�
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14002');
            ln_err_cnt := ln_err_cnt + 1;
          ELSIF ( lv_chk_exchange_rate_type IS NULL ) THEN
            -- �ʉ݃R�[�h���@�\�ʉ݂łȂ��A�����[�g�^�C�v�ɓ��͒l�Ȃ�
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14003');
            ln_err_cnt := ln_err_cnt + 1;
          ELSIF ( lv_chk_exchange_rate_type != 'User' ) THEN
            -- �ʉ݃R�[�h���@�\�ʉ݂łȂ��A�����[�g�A���[�g�^�C�v���ɓ��͒l����A
            -- �����[�g�^�C�v��'User'
            OPEN xx03_rate_cur(
              lv_chk_currency_code,       -- 1.�ʉ݃R�[�h
              lv_chk_exchange_rate_type,  -- 2.���[�g�^�C�v
              ld_chk_gl_date              -- 3.GL�L����
            );
            FETCH xx03_rate_cur INTO xx03_rate_rec;
            IF xx03_rate_cur%NOTFOUND THEN
              -- ���R�[�h���I������Ȃ�����
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              IF ( xx03_rate_rec.conversion_rate != ln_chk_exchange_rate ) THEN
                -- ���[�g�̒l���قȂ�
                errflg_tbl(ln_err_cnt) := 'E';
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
                ln_err_cnt := ln_err_cnt + 1;
              END IF;
            END IF;
            CLOSE xx03_rate_cur;
          ELSE
            -- �ʉ݃R�[�h���@�\�ʉ݂łȂ��A�����[�g�A���[�g�^�C�v���ɓ��͒l����A
            -- �����[�g�^�C�v��'User'�ȊO�̏ꍇ�͓��ɏ����͂Ȃ�
            NULL;
          END IF;
        END IF;
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- �C�����`�[�ԍ����͎��̂݃`�F�b�N����
      IF lv_chk_orig_journal_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- �C�����`�[�ԍ��`�F�b�N
        OPEN xx03_orig_num_cur(
          lv_chk_orig_journal_num  -- 1.�C�����`�[�ԍ�
        );
        FETCH xx03_orig_num_cur INTO xx03_orig_num_rec;
        IF xx03_orig_num_cur%NOTFOUND THEN
          -- ���R�[�h���I������Ȃ�����
          -- ���ɏ����Ȃ�
          NULL;
        ELSE
          -- ���R�[�h���I�����ꂽ
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14149');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_orig_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
-- ver 11.5.10.2.6 Chg Start
        -- ��v���ԃ`�F�b�N
--        OPEN xx03_gl_period_status_cur(
--          ln_books_id,    -- 1.����ID
--          ld_chk_gl_date  -- 2.GL�L����
--        );
--        FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
--        -- �@��v���Ԃƌv�����������Ԃɂ��邩
--        IF xx03_gl_period_status_cur%NOTFOUND THEN
--          -- GL��v���Ԗ���`�G���[
--          errflg_tbl(ln_err_cnt) := 'E';
--          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
--          ln_err_cnt := ln_err_cnt + 1;
---- ver 11.5.10.1.6I Add Start
--        ELSIF xx03_xjsjlv_rec.period_name != xx03_gl_period_status_rec.period_name THEN
--          errflg_tbl(ln_err_cnt) := 'E';
--          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11572');
--          ln_err_cnt := ln_err_cnt + 1;
---- ver 11.5.10.1.6I Add End
        OPEN xx03_gl_period_status_cur(
          ln_books_id,    -- 1.����ID
          xx03_xjsjlv_rec.period_name  -- 2.��v���Ԗ���
        );
        FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
        -- �@�I����v���Ԗ��̂Ɠ����f�[�^�����邩�H
        IF xx03_gl_period_status_cur%NOTFOUND THEN
          -- GL��v���Ԗ���`�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03068');
          ln_err_cnt := ln_err_cnt + 1;
        -- �D�I����v���Ԃ̊J�n�I����GL�L�����������Ă��邩�H
        ELSIF xx03_gl_period_status_rec.start_date > TRUNC(ld_chk_gl_date) OR
              xx03_gl_period_status_rec.end_date   < TRUNC(ld_chk_gl_date) THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11575');
          ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.6 Chg End
        ELSE
          -- �N�[����̕���R�[�h�̌��Z�S���i����Z�O�����g��ATTRIBUTE2�j���hY"�̏ꍇ
          IF lv_attribute2 = 'Y' THEN
            -- �A���͂��ꂽ��v���Ԃ�GL��v���Ԃ̃I�[�v�����Ԃɑ������邩
            IF ( xx03_gl_period_status_rec.closing_status IS NOT NULL AND
                 xx03_gl_period_status_rec.closing_status != 'O' ) THEN
              -- GL��v���Ԗ��I�[�v���G���[
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          -- �N�[����̕���R�[�h�̌��Z�S���i����Z�O�����g��ATTRIBUTE2�j���hN"�̏ꍇ
          ELSE
            -- �B���͂��ꂽ��v���Ԃ�GL��v���Ԃ����GL������͉�v���Ԃ̃I�[�v�����ԂɊY�����邩
            IF ( xx03_gl_period_status_rec.attribute5 IS NOT NULL AND
                 xx03_gl_period_status_rec.attribute5 != 'O' )    OR
               ( xx03_gl_period_status_rec.closing_status IS NOT NULL AND
                 xx03_gl_period_status_rec.closing_status != 'O' ) THEN
              -- GL��v���Ԗ��I�[�v���G���[
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              -- �C��v���Ԃ��������ԂłȂ���
              IF xx03_gl_period_status_rec.adj_flag = 'Y' THEN
                -- GL��v���Ԗ��I�[�v���G���[
                errflg_tbl(ln_err_cnt) := 'E';
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
                ln_err_cnt := ln_err_cnt + 1;
              END IF;
            END IF;
          END IF;
        END IF;
        CLOSE xx03_gl_period_status_cur;
--
        -- ver 11.5.10.2.2 Add Start
        -- ver 11.5.10.2.2B Chg Start
        ---- �\����-���F�҃`�F�b�N(WF_STATUS����ۑ������F�҂����ŏI���F�҂���̎��A���{)
        --IF (   ld_wf_status = cn_wf_status_save
        --    OR ld_wf_status = cn_wf_status_dept
        --    OR ld_wf_status = cn_wf_status_last ) THEN
        -- �\����-���F�҃`�F�b�N(WF_STATUS������F�҂����ŏI���F�҂���̎��A���{)
        IF (   ld_wf_status = cn_wf_status_dept
            OR ld_wf_status = cn_wf_status_last ) THEN
        -- ver 11.5.10.2.2B Chg End
          OPEN xx03_req_app_cur;
          FETCH xx03_req_app_cur INTO xx03_req_app_rec;
          IF xx03_req_app_rec.exist_check = 0 THEN
            -- ���F�҃`�F�b�N�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14160','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_req_app_cur;
        END IF;
        -- ver 11.5.10.2.2 Add End
--
-- Ver11.5.10.1.6G Add start
-- �w�b�_�[�̃}�X�^�[�`�F�b�N���{
        --2006/03/06 Ver11.5.10.1.6J Change Start
        --���F�҃`�F�b�N(WF_STATUS��������͑҂���Ԃ̂Ƃ��̂ݎ��{)
        IF ld_wf_status = cn_wf_status_dept THEN
          OPEN xx03_approver_cur;
          FETCH xx03_approver_cur INTO xx03_approver_rec;
          IF xx03_approver_rec.exist_check = 0 THEN
            -- ���F�҃`�F�b�N�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14154','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_approver_cur;
        END IF;
        --2006/03/06 Ver11.5.10.1.6J Change End
--
-- 2006/02/15 Ver11.5.10.1.6G Add END
--
-- ver 11.5.10.2.9 Add Start
        -- ver 11.5.10.2.10B Chg Start
        ----�ʉ݃}�X�^�`�F�b�N
        --OPEN xx03_inv_currency_cur(lv_chk_currency_code);
        --FETCH xx03_inv_currency_cur INTO xx03_inv_currency_rec;
        --IF xx03_inv_currency_rec.exist_check = 0 THEN
        --  -- �ʉ݃`�F�b�N�G���[
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        --CLOSE xx03_inv_currency_cur;
        --
        --�ʉ݃`�F�b�N(���x�`�F�b�N�p�ɐ��x���擾����悤�ɕύX)
        OPEN xx03_inv_currency_cur(lv_chk_currency_code);
        FETCH xx03_inv_currency_cur INTO xx03_inv_currency_rec;
        IF (xx03_inv_currency_cur%NOTFOUND) THEN
          -- �ʉ݃`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
--
          lb_currency_chk := FALSE;
          ln_currency_precision := 0;
        ELSE
          lb_currency_chk := TRUE;
          ln_currency_precision := xx03_inv_currency_rec.PRECISION;
        END IF;
        CLOSE xx03_inv_currency_cur;
        -- ver 11.5.10.2.10B Chg End
--
        --���Z�ϑݎ؋��z��v�`�F�b�N
        IF ln_chk_total_dr != ln_chk_total_cr THEN
          -- ���Z�ϑݎؕs��v�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11567','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
-- ver 11.5.10.2.9 Add End
--
        -- �ŋ��I�v�V�����\����
        OPEN gl_tax_options_cur(
            ln_books_id,         -- 1.����ID
            ln_org_id            -- 2.�I���OID
        );
        --�ǂݍ���
        FETCH gl_tax_options_cur INTO gl_tax_options_rec;
        IF gl_tax_options_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11542');
          ln_err_cnt := ln_err_cnt + 1;
        ELSE
          -- ����ŋ��e�͈̓J�[�\��
          OPEN tax_range_check_cur(
            in_journal_id,                                -- 1.�`�[ID
            ln_books_id,                                  -- 2.����ID
            gl_tax_options_rec.input_rounding_rule_code,  -- 3.�����[�������K��
            gl_tax_options_rec.output_rounding_rule_code  -- 4.����[�������K��
          );
          <<tax_range_check_loop>>
          LOOP
            FETCH tax_range_check_cur INTO tax_range_check_rec;
            EXIT WHEN tax_range_check_cur%NOTFOUND;
--
            --a)���e�͈͍ő���z�`�F�b�N
            --�ϐ�.���z := ABS(sum_cal_tax  -  sum_tax )
            --�ϐ�.���z >�ϐ�. ���e�͈͍ő���z�̎�
            --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            IF ABS(tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) >
               TO_NUMBER(gl_tax_options_rec.attribute2) THEN
--
              errflg_tbl(ln_err_cnt) := 'W';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03037');
              ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
              ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
            ELSE
--
              --b)���e�͈͗��`�F�b�N
              --�ϐ�.���z := ABS(sum_cal_tax  -  sum_tax )
              --(�ϐ�.���z / sum_no_tax ) * 100 >�ϐ�. ���e�͈͗��̎�
              --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
              IF tax_range_check_rec.sum_no_tax != 0 THEN
                IF ABS ( (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
                   > TO_NUMBER(gl_tax_options_rec.attribute1) THEN
--
                  errflg_tbl(ln_err_cnt) := 'W';
                  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03038');
                  ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
                  ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
                END IF;
              ELSE
                IF tax_range_check_rec.sum_tax != 0 THEN
--
                  errflg_tbl(ln_err_cnt) := 'W';
                  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03043');
                  ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
                  ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
                END IF;
              END IF;
            END IF;
--
          END LOOP tax_range_check_loop;
--
          CLOSE tax_range_check_cur;
        END IF;
        --�J�[�\���̃N���[�Y
        CLOSE gl_tax_options_cur;
--
        --�`�F�b�NID�擾
        SELECT xx03_err_check_s.NEXTVAL
        INTO   ln_check_seq
        FROM   DUAL;
--
        -- 1���ڃt���O�����낷
        lv_first_flg := 'N';
      END IF;
--
      -- �t���b�N�X�E�t�B�[���h�̌n�ԍ��̎擾
      SELECT sob.chart_of_accounts_id
      INTO   ln_structure_number
      FROM   gl_sets_of_books sob
      WHERE  sob.set_of_books_id = xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID');
--
      -- ���݌��؃��[���`�F�b�N���s(�Ώ� : �w�b�_�[�ȊO)
      IF (xx03_xjsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xjsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xjsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xjsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xjsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xjsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xjsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xjsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xjsjlv_rec.segment8;
--
        lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                        application_short_name => lv_app_short_name,
                        key_flex_code => lv_key_flex_code,
                        structure_number => ln_structure_number,
        -- 2006/01/30 Ver11.5.10.1.6E Change Start
        --              validation_date => ld_validation_date,
                        validation_date => ld_chk_gl_date,
        -- 2006/01/30 Ver11.5.10.1.6E Change End
                        n_segments => ln_segments,
                        segments => lv_segment_array,
                        combination_id => on_combination_id,
                        data_set => ld_data_set
        );
--
        IF lb_retcode THEN
          NULL;
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          -- errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11543');
          IF xx03_xjsjlv_rec.entered_dr IS NOT NULL THEN
            errmsg_tbl(ln_err_cnt) := '�ؕ�'||xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          ELSIF xx03_xjsjlv_rec.entered_cr IS NOT NULL THEN
            errmsg_tbl(ln_err_cnt) := '�ݕ�'||xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          ELSE
            errmsg_tbl(ln_err_cnt) := xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
--
-- Ver11.5.10.1.6G Add Start
-- ���ׂ̃}�X�^�[�l�`�F�b�N�����{����
      --���׍s�̂݃`�F�b�N����
      IF xx03_xjsjlv_rec.line_type_lookup_code = 'ITEM' THEN
--
        IF (xx03_xjsjlv_rec.entered_dr IS NOT NULL) THEN
--
          --�K�p�R�[�h���̓`�F�b�N
          OPEN  xx03_jsl_slt_dr_cur(xx03_xjsjlv_rec.line_number);     -- 1.���הԍ�
          FETCH xx03_jsl_slt_dr_cur INTO xx03_jsl_slt_dr_rec;
          CLOSE xx03_jsl_slt_dr_cur;
--
          IF xx03_jsl_slt_dr_rec.exist_check != 0 THEN
            --�K�p�R�[�h���͎��A�}�X�^�`�F�b�N
            OPEN xx03_slip_line_type_dr_cur(
              xx03_xjsjlv_rec.line_number,    -- 1.���הԍ�
              ld_chk_gl_date                  -- 2.GL�L����
            );
            FETCH xx03_slip_line_type_dr_cur INTO xx03_slip_line_type_dr_rec;
            IF xx03_slip_line_type_dr_rec.exist_check = 0 THEN
              -- �K�p�R�[�h�G���[
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11560','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_slip_line_type_dr_cur;
          END IF;
-- ver 11.5.10.2.9 Add Start
          lv_chk_dr_cr := 'DR';
-- ver 11.5.10.2.9 Add End
--
        ELSIF (xx03_xjsjlv_rec.entered_cr IS NOT NULL) THEN
--
          --�K�p�R�[�h���̓`�F�b�N
          OPEN  xx03_jsl_slt_cr_cur(xx03_xjsjlv_rec.line_number);     -- 1.���הԍ�
          FETCH xx03_jsl_slt_cr_cur INTO xx03_jsl_slt_cr_rec;
          CLOSE xx03_jsl_slt_cr_cur;
--
          IF xx03_jsl_slt_cr_rec.exist_check != 0 THEN
            --�K�p�R�[�h���͎��A�}�X�^�`�F�b�N
            OPEN xx03_slip_line_type_cr_cur(
              xx03_xjsjlv_rec.line_number,    -- 1.���הԍ�
              ld_chk_gl_date                  -- 2.GL�L����
            );
            FETCH xx03_slip_line_type_cr_cur INTO xx03_slip_line_type_cr_rec;
            IF xx03_slip_line_type_cr_rec.exist_check = 0 THEN
              -- �K�p�R�[�h�G���[
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11561','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_slip_line_type_cr_cur;
          END IF;
-- ver 11.5.10.2.9 Add Start
          lv_chk_dr_cr := 'CR';
-- ver 11.5.10.2.9 Add End
--
        END IF;
--
-- ver 11.5.10.2.9 Add Start
        --�ŋ��R�[�h�}�X�^�`�F�b�N
        OPEN xx03_line_tax_cur(
          xx03_xjsjlv_rec.line_number    -- 1.���הԍ�
         ,lv_chk_dr_cr                   -- 2.�ݎ؃t���O
         ,ld_chk_gl_date                 -- 3.GL�L����
        );
        FETCH xx03_line_tax_cur INTO xx03_line_tax_rec;
        IF xx03_line_tax_rec.exist_check = 0 THEN
          -- �ŋ��R�[�h�G���[
          errflg_tbl(ln_err_cnt) := 'E';

          IF lv_chk_dr_cr = 'DR' THEN
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11565','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
          ELSE
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11566','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_line_tax_cur;
--
        -- ver 11.5.10.2.10B Add Start
        -- �ʉ݂����������͂���Ă���ꍇ�̓`�F�b�N
        IF lb_currency_chk = TRUE THEN
--
          -- �`�[���z�̐��x���擾
          IF lv_chk_dr_cr = 'DR' THEN
            lv_amount := TO_CHAR(xx03_xjsjlv_rec.entered_dr);
          ELSIF lv_chk_dr_cr = 'CR' THEN
            lv_amount := TO_CHAR(xx03_xjsjlv_rec.entered_cr);
          END IF;
--
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- �`�[���z�̐��x���ʉ݂̐��x�𒴂��Ă���΃G���[
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            IF lv_chk_dr_cr = 'DR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11576','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            ELSIF lv_chk_dr_cr = 'CR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11577','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            END IF;
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
--
        END IF;
        -- ver 11.5.10.2.10B Add End
--
        --�@�\�ʉݎ����͊��Z���z��v�`�F�b�N
        IF lv_currency_code = lv_chk_currency_code THEN
--
          OPEN xx03_enter_account_cur(
            xx03_xjsjlv_rec.line_number    -- 1.���הԍ�
           ,lv_chk_dr_cr                   -- 2.�ݎ؃t���O
          );
          FETCH xx03_enter_account_cur INTO xx03_enter_account_rec;
--
          IF xx03_enter_account_cur%NOTFOUND THEN
            -- ���R�[�h���I������Ȃ�����
            errflg_tbl(ln_err_cnt) := 'E';
-- ver 11.5.10.2.9B Chg Start
--            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            IF lv_chk_dr_cr = 'DR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            ELSE
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11569','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            END IF;
-- ver 11.5.10.2.9B Chg End
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            IF ( xx03_enter_account_rec.accounted_amount !=   xx03_enter_account_rec.entered_item_amount
                                                            + xx03_enter_account_rec.entered_tax_amount ) THEN
              -- ���[�g�̒l���قȂ�
              errflg_tbl(ln_err_cnt) := 'E';
-- ver 11.5.10.2.9B Chg Start
--              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              IF lv_chk_dr_cr = 'DR' THEN
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ELSE
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11569','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              END IF;
-- ver 11.5.10.2.9B Chg End
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          END IF;
          CLOSE xx03_enter_account_cur;
        END IF;
-- ver 11.5.10.2.9 Add End
--
      END IF;
-- Ver11.5.10.1.6G Add End
--
      END IF; -- xx03_xjsjlv_rec.segment1 IS NOT NULL
--
-- 2013/09/19 ver 11.5.10.2.12 ADD START
      -- ���ڐ������`�F�b�N
      OPEN xx03_save_code_chk_cur(
               in_org_id          => ln_org_id    -- �c�ƒP��ID
             , in_set_of_books_id => ln_books_id  -- ��v����ID
           );
      FETCH xx03_save_code_chk_cur INTO xx03_save_code_chk_rec;
      -- ���݃`�F�b�N������1���ł����݂���ꍇ
      IF ( xx03_save_code_chk_rec.exist_check <> 0 ) THEN
        -- ���ڑ���G���[
        errflg_tbl(ln_err_cnt) := 'E';
        errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO', 'APP-XXCFO1-00049');
        ln_err_cnt := ln_err_cnt + 1;
      END IF;
      CLOSE xx03_save_code_chk_cur;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
--
-- ver 11.5.10.2.9 Add Start
      -- ������̓G���[�`�F�b�N�ŃG���[���������ꍇ�͂��̎��_�Ń��[�v�I��
-- ver 11.5.10.2.11 Cng Start
--      IF ( ln_err_cnt > 0 ) THEN
      IF ( ln_err_cnt > 0 ) AND 
         ( ln_err_cnt - ln_warn_cnt <> 0 ) THEN
-- ver 11.5.10.2.11 Cng End
        -- �f�[�^�I��
        EXIT xx03_xjsjlv_loop;
      END IF;
-- ver 11.5.10.2.9 Add End
--
      -- �G���[�`�F�b�N�e�[�u����������
      IF ( xx03_xjsjlv_rec.line_number = 0 ) THEN
        -- Ver11.5.10.1.6C 2006/01/16 Change Start
        -- -- �w�b�_���R�[�h
        --INSERT INTO xx03_error_checks(
        --  CHECK_ID,
        --  JOURNAL_ID,
        --  LINE_NUMBER,
        --  GL_DATE,
        --  PERIOD_NAME,
        --  CURRENCY_CODE,
        --  CODE_COMBINATION_ID,
        --  SEGMENT1,
        --  SEGMENT2,
        --  SEGMENT3,
        --  SEGMENT4,
        --  SEGMENT5,
        --  SEGMENT6,
        --  SEGMENT7,
        --  SEGMENT8,
        --  TAX_CODE,
        --  INCR_DECR_REASON_CODE,
        --  SLIP_NUMBER,
        --  INPUT_DEPARTMENT,
        --  INPUT_USER,
        --  ORIG_SLIP_NUMBER,
        --  RECON_REFERENCE,
        --  ENTERED_DR,
        --  ENTERED_CR,
        --  ATTRIBUTE_CATEGORY,
        --  ATTRIBUTE1,
        --  ATTRIBUTE2,
        --  ATTRIBUTE3,
        --  ATTRIBUTE4,
        --  ATTRIBUTE5,
        --  ATTRIBUTE6,
        --  ATTRIBUTE7,
        --  ATTRIBUTE8,
        --  ATTRIBUTE9,
        --  ATTRIBUTE10,
        --  ATTRIBUTE11,
        --  ATTRIBUTE12,
        --  ATTRIBUTE13,
        --  ATTRIBUTE14,
        --  ATTRIBUTE15,
        --  ATTRIBUTE16,
        --  ATTRIBUTE17,
        --  ATTRIBUTE18,
        --  ATTRIBUTE19,
        --  ATTRIBUTE20,
        --  CREATED_BY,
        --  CREATION_DATE,
        --  LAST_UPDATED_BY,
        --  LAST_UPDATE_DATE,
        --  LAST_UPDATE_LOGIN,
        --  REQUEST_ID,
        --  PROGRAM_APPLICATION_ID,
        --  PROGRAM_UPDATE_DATE,
        --  PROGRAM_ID
        --) VALUES (
        --  ln_check_seq,
        --  xx03_xjsjlv_rec.journal_num,
        --  xx03_xjsjlv_rec.line_number,
        --  xx03_xjsjlv_rec.gl_date,
        --  null,
        --  xx03_xjsjlv_rec.invoice_currency_code,
        --  xx03_xjsjlv_rec.code_combination_id,
        --  xx03_xjsjlv_rec.segment1,
        --  xx03_xjsjlv_rec.segment2,
        --  xx03_xjsjlv_rec.segment3,
        --  xx03_xjsjlv_rec.segment4,
        --  xx03_xjsjlv_rec.segment5,
        --  xx03_xjsjlv_rec.segment6,
        --  xx03_xjsjlv_rec.segment7,
        --  xx03_xjsjlv_rec.segment8,
        --  null,
        --  null,
        --  xx03_xjsjlv_rec.journal_num,
        --  xx03_xjsjlv_rec.entry_department,
        --  xx03_xjsjlv_rec.user_name,
        --  null,
        --  null,
        --  xx03_xjsjlv_rec.entered_dr,
        --  xx03_xjsjlv_rec.entered_cr,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  xx00_global_pkg.user_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.user_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.login_id,
        --  xx00_global_pkg.conc_request_id,
        --  xx00_global_pkg.prog_appl_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.conc_program_id
        --);
        NULL;
        -- Ver11.5.10.1.6C 2006/01/16 Change End
      ELSE
        -- ����(�ŋ�)���R�[�h
        INSERT INTO xx03_error_checks(
          CHECK_ID,
          JOURNAL_ID,
          LINE_NUMBER,
          GL_DATE,
          PERIOD_NAME,
          CURRENCY_CODE,
          CODE_COMBINATION_ID,
          SEGMENT1,
          SEGMENT2,
          SEGMENT3,
          SEGMENT4,
          SEGMENT5,
          SEGMENT6,
          SEGMENT7,
          SEGMENT8,
          TAX_CODE,
          INCR_DECR_REASON_CODE,
          SLIP_NUMBER,
          INPUT_DEPARTMENT,
          INPUT_USER,
          ORIG_SLIP_NUMBER,
          RECON_REFERENCE,
          ENTERED_DR,
          ENTERED_CR,
          ATTRIBUTE_CATEGORY,
          ATTRIBUTE1,
          ATTRIBUTE2,
          ATTRIBUTE3,
          ATTRIBUTE4,
          ATTRIBUTE5,
          ATTRIBUTE6,
          ATTRIBUTE7,
          ATTRIBUTE8,
          ATTRIBUTE9,
          ATTRIBUTE10,
          ATTRIBUTE11,
          ATTRIBUTE12,
          ATTRIBUTE13,
          ATTRIBUTE14,
          ATTRIBUTE15,
          ATTRIBUTE16,
          ATTRIBUTE17,
          ATTRIBUTE18,
          ATTRIBUTE19,
          ATTRIBUTE20,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN,
          REQUEST_ID,
          PROGRAM_APPLICATION_ID,
          PROGRAM_UPDATE_DATE,
          PROGRAM_ID
        ) VALUES (
          ln_check_seq,
          xx03_xjsjlv_rec.journal_num,
          xx03_xjsjlv_rec.line_number,
          xx03_xjsjlv_rec.gl_date,
-- 2005/1/19 Ver11.5.10.1.6D Add Start
--          null,
          xx03_xjsjlv_rec.PERIOD_NAME,
-- 2005/1/19 Ver11.5.10.1.6D Add End
          xx03_xjsjlv_rec.invoice_currency_code,
          xx03_xjsjlv_rec.code_combination_id,
          xx03_xjsjlv_rec.segment1,
          xx03_xjsjlv_rec.segment2,
          xx03_xjsjlv_rec.segment3,
          xx03_xjsjlv_rec.segment4,
          xx03_xjsjlv_rec.segment5,
          xx03_xjsjlv_rec.segment6,
          xx03_xjsjlv_rec.segment7,
          xx03_xjsjlv_rec.segment8,
          xx03_xjsjlv_rec.tax_code,
          xx03_xjsjlv_rec.incr_decr_reason_code,
          xx03_xjsjlv_rec.journal_num,
          xx03_xjsjlv_rec.entry_department,
          xx03_xjsjlv_rec.user_name,
          null,
          xx03_xjsjlv_rec.recon_reference,
          xx03_xjsjlv_rec.entered_dr,
          xx03_xjsjlv_rec.entered_cr,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.login_id,
          xx00_global_pkg.conc_request_id,
          xx00_global_pkg.prog_appl_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.conc_program_id
        );
      END IF;
    END LOOP xx03_xjsjlv_loop;
    CLOSE xx03_xjsjlv_cur;
--
-- ver 11.5.10.2.11 Cng Start
---- ver 11.5.10.2.9C Add Start
--    -- ������̓G���[�`�F�b�N�ŃG���[���Ȃ������ꍇ�̂݋��ʃG���[�`�F�b�N���s
--    IF ( ln_err_cnt <= 0 ) THEN
---- ver 11.5.10.2.9C Add End
    -- ������̓G���[�`�F�b�N�Ő���A�������͌x���̏ꍇ�A���ʃG���[�`�F�N���s
    IF ( ln_err_cnt <= 0 ) OR 
       ( ln_err_cnt > 0 AND ln_err_cnt - ln_warn_cnt <= 0 ) THEN
-- ver 11.5.10.2.11 Cng End
--
    -- ���ʃG���[�`�F�b�N�������s
    lv_err_status := xx03_je_error_check_pkg.je_error_check(ln_check_seq);
--
    IF (lv_err_status != 'S' ) THEN
      -- ���ʃG���[�`�F�b�N���ʎ擾
      OPEN xx03_errchk_result_cur;
      <<xx03_errchk_result_loop>>
      LOOP
        FETCH xx03_errchk_result_cur INTO xx03_errchk_result_rec;
        IF xx03_errchk_result_cur%NOTFOUND THEN
          EXIT xx03_errchk_result_loop;
        END IF;
--
        -- �擾�����G���[�������ɃG���[���z��ɃZ�b�g
        IF ( ln_err_cnt <= 19 ) THEN
          -- Ver11.5.10.1.6C 2006/01/16 Delete Start
          -- -- �s�v�ȃG���[�͍폜
          --IF xx03_errchk_result_rec.line_number = '0' AND
          --   ( xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT1'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT2'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT3'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT4'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT5'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT6'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT7'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT8'))     OR  -- AFF���w��
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03039') OR  -- CF�g�����}�X�^�擾�G���[
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03013',     -- ����Ȗڑg�����G���[
          --                                              'TOK_XX03_NOT_GET_KEY', 'CCID',
          --                                              'TOK_XX03_NOT_GET_VALUE', '')
          --   ) THEN
          --  ln_err_cnt := ln_err_cnt - 1;
          --ELSE
          -- Ver11.5.10.1.6C 2006/01/16 Delete End
            -- �G���[������20���ȉ��̎��̂݃G���[���Z�b�g
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10 Chg Start
--            errmsg_tbl(ln_err_cnt) := xx03_errchk_result_rec.dr_cr ||
--                                      TRUNC(xx03_errchk_result_rec.line_number) || '�F' ||
--                                      xx03_errchk_result_rec.error_message;
            if xx03_errchk_result_rec.line_number = 0 THEN
              lv_je_err_msg := 'APP-XX03-14164';
            elsif (xx03_errchk_result_rec.line_number - TRUNC(xx03_errchk_result_rec.line_number)) = 0.5 THEN
              lv_je_err_msg := 'APP-XX03-14166';
            else
              lv_je_err_msg := 'APP-XX03-14165';
            end if;
            errmsg_tbl(ln_err_cnt) := xx03_errchk_result_rec.dr_cr ||
                                      TRUNC(xx03_errchk_result_rec.line_number) || '�F' ||
                                      xx03_errchk_result_rec.error_message ||
                                      xx00_message_pkg.get_msg('XX03',lv_je_err_msg);
-- ver 11.5.10.2.10 Chg End
          -- Ver11.5.10.1.6C 2006/01/16 Delete Start
          --END IF;
          -- Ver11.5.10.1.6C 2006/01/16 Delete End
        END IF;
        ln_err_cnt := ln_err_cnt + 1;
--
      END LOOP xx03_errchk_result_loop;
      CLOSE xx03_errchk_result_cur;
    END IF;
--
-- ver 11.5.10.2.9C Add Start
    END IF;
-- ver 11.5.10.2.9C Add End
--
-- ver 11.5.10.1.6H Add Start
    IF ln_check_seq != 0 THEN
-- ver 11.5.10.1.6H Add End
      -- �G���[�`�F�b�N�A�G���[���f�[�^�폜
    DELETE FROM xx03_error_checks xec
          WHERE xec.check_id = ln_check_seq;
    DELETE FROM xx03_error_info xei
          WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6H Add Start
    END IF;
-- ver 11.5.10.1.6H Add End
--
    -- OUT�p�����[�^�ݒ�
    ov_error_flg := 'S';
    FOR ln_cnt IN 0..19 LOOP
      IF ( ov_error_flg = 'S' AND errflg_tbl(ln_cnt) != 'S' ) THEN
        -- ���� �� �x��or�G���[
        ov_error_flg := errflg_tbl(ln_cnt);
      ELSIF ( ov_error_flg = 'W' AND errflg_tbl(ln_cnt) = 'E' ) THEN
        -- �x�� �� �G���[
        ov_error_flg := errflg_tbl(ln_cnt);
      END IF;
--
      IF ( ov_error_flg = 'E') THEN
        -- �X�e�[�^�X���G���[�ɂȂ������_�Ń��[�v�͔�����
        EXIT;
      END IF;
    END LOOP;
--
    on_error_cnt := ln_err_cnt;
    ov_error_flg1 := errflg_tbl(0);
    ov_error_msg1 := errmsg_tbl(0);
    ov_error_flg2 := errflg_tbl(1);
    ov_error_msg2 := errmsg_tbl(1);
    ov_error_flg3 := errflg_tbl(2);
    ov_error_msg3 := errmsg_tbl(2);
    ov_error_flg4 := errflg_tbl(3);
    ov_error_msg4 := errmsg_tbl(3);
    ov_error_flg5 := errflg_tbl(4);
    ov_error_msg5 := errmsg_tbl(4);
    ov_error_flg6 := errflg_tbl(5);
    ov_error_msg6 := errmsg_tbl(5);
    ov_error_flg7 := errflg_tbl(6);
    ov_error_msg7 := errmsg_tbl(6);
    ov_error_flg8 := errflg_tbl(7);
    ov_error_msg8 := errmsg_tbl(7);
    ov_error_flg9 := errflg_tbl(8);
    ov_error_msg9 := errmsg_tbl(8);
    ov_error_flg10 := errflg_tbl(9);
    ov_error_msg10 := errmsg_tbl(9);
    ov_error_flg11 := errflg_tbl(10);
    ov_error_msg11 := errmsg_tbl(10);
    ov_error_flg12 := errflg_tbl(11);
    ov_error_msg12 := errmsg_tbl(11);
    ov_error_flg13 := errflg_tbl(12);
    ov_error_msg13 := errmsg_tbl(12);
    ov_error_flg14 := errflg_tbl(13);
    ov_error_msg14 := errmsg_tbl(13);
    ov_error_flg15 := errflg_tbl(14);
    ov_error_msg15 := errmsg_tbl(14);
    ov_error_flg16 := errflg_tbl(15);
    ov_error_msg16 := errmsg_tbl(15);
    ov_error_flg17 := errflg_tbl(16);
    ov_error_msg17 := errmsg_tbl(16);
    ov_error_flg18 := errflg_tbl(17);
    ov_error_msg18 := errmsg_tbl(17);
    ov_error_flg19 := errflg_tbl(18);
    ov_error_msg19 := errmsg_tbl(18);
    ov_error_flg20 := errflg_tbl(19);
    ov_error_msg20 := errmsg_tbl(19);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                --*** �Ώۃf�[�^�Ȃ� ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
      -- ver 11.5.10.2.3 Add Start
      -- OUT�p�����[�^�ݒ�
      ov_error_flg := 'E';
      on_error_cnt := 1;
      ov_error_flg1 := xx00_common_pkg.set_status_error_f;
      ov_error_msg1 := lv_errmsg;
      -- ver 11.5.10.2.3 Add Start
--
      -- �J�[�\���N���[�Y
      IF xx03_xjsjlv_cur%ISOPEN THEN
        CLOSE xx03_xjsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      IF xx03_errchk_result_cur%ISOPEN THEN
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver11.5.10.1.6G Add Start
      IF xx03_approver_cur%ISOPEN THEN
        CLOSE xx03_approver_cur;
      END IF;
      IF xx03_jsl_slt_dr_cur%ISOPEN THEN
        CLOSE xx03_jsl_slt_dr_cur;
      END IF;
      IF xx03_slip_line_type_dr_cur%ISOPEN THEN
        CLOSE xx03_slip_line_type_dr_cur;
      END IF;
      IF xx03_jsl_slt_cr_cur%ISOPEN THEN
        CLOSE xx03_jsl_slt_cr_cur;
      END IF;
      IF xx03_slip_line_type_cr_cur%ISOPEN THEN
        CLOSE xx03_slip_line_type_cr_cur;
      END IF;
-- ver11.5.10.1.6G Add End
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM||':'||ln_check_seq||':'||xx03_xjsjlv_rec.journal_num||':'||xx03_xjsjlv_rec.line_number,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_deptinput_gl;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : �d�_�Ǘ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_journal_id IN  NUMBER,    -- 1.�`�F�b�N�Ώێd��`�[ID
    ov_app_upd    OUT VARCHAR2,  -- 2.�d�_�Ǘ��X�V���e
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.set_account_approval_flag'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ###############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_head_acc_amount NUMBER;       -- ���Z�ώؕ����v���z
    lv_slip_type VARCHAR2(25);       -- �w�b�_�`�[���
    lv_gl_app_flag VARCHAR2(240);    -- GL�d�_�Ǘ��s�v�t���O
    lv_detail_first_flg VARCHAR2(1); -- ���דǍ�1���ڃt���O
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �`�[��ʃ}�X�^���擾�J�[�\��
    CURSOR xx03_slip_type_cur(
      iv_slip_type   IN  VARCHAR2  -- 1.�`�[���
    ) IS
      SELECT xst.attribute1 as attribute1,
             xst.attribute2 as attribute2
        FROM xx03_slip_types_v xst
       WHERE xst.lookup_code = iv_slip_type;
--
    -- �d�󖾍׏��擾�J�[�\��
    CURSOR xx03_detail_info_cur
    IS
      SELECT xav.attribute7 as attribute7
        FROM xx03_journal_slip_lines xjsl,
             xx03_accounts_v xav
       WHERE xjsl.journal_id = in_journal_id
         AND xjsl.segment3 = xav.flex_value;
--
    -- *** ���[�J���E���R�[�h ***
    -- �`�[��ʃ}�X�^���擾�J�[�\�����R�[�h�^
    xx03_slip_type_rec       xx03_slip_type_cur%ROWTYPE;
    -- �d�󖾍׏��擾�J�[�\�����R�[�h�^
    xx03_detail_info_rec     xx03_detail_info_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �߂�l������
    ov_app_upd := 'N';
--
    -- �d��w�b�_���R�[�h�擾
    SELECT ABS(
             ROUND((xjs.total_item_entered_dr + xjs.total_tax_entered_dr) * NVL(xjs.exchange_rate, 1))
           ) as total_accounted_amount,
           xjs.slip_type as slip_type,
           xdv.attribute3 as gl_app_flag
      INTO ln_head_acc_amount,
           lv_slip_type,
           lv_gl_app_flag
      FROM xx03_journal_slips xjs,
           xx03_departments_v xdv
     WHERE xjs.journal_id = in_journal_id
     AND   xjs.entry_department = xdv.flex_value;
--
    -- �N�[���傪GL�d�_�Ǘ��s�v���傩�̔��f
    IF lv_gl_app_flag = 'Y' THEN
      ov_app_upd := 'N';
    ELSE
      -- �`�[��ʃ}�X�^���擾
      OPEN xx03_slip_type_cur(lv_slip_type);
      FETCH xx03_slip_type_cur INTO xx03_slip_type_rec;
      IF xx03_slip_type_cur%NOTFOUND THEN
        RAISE NO_DATA_FOUND;
      ELSE
        IF ( xx03_slip_type_rec.attribute1 = 'Y' ) THEN
          -- attribute1��'Y'�������ꍇ�́Aov_app_upd��'Y'���Z�b�g����RETURN
          ov_app_upd := 'Y';
          CLOSE xx03_slip_type_cur;
          RETURN;
        ELSE
          IF ( ln_head_acc_amount >= xx03_slip_type_rec.attribute2 ) THEN
            -- attribute1��'N'�ŁA����inv_accounted_amount>=attribute2�������ꍇ�́A
            -- ov_app_upd��'Y'���Z�b�g���ARETURN
            ov_app_upd := 'Y';
            CLOSE xx03_slip_type_cur;
            RETURN;
          END IF;
        END IF;
      END IF;
      CLOSE xx03_slip_type_cur;
--
      -- �d�󖾍הz�����R�[�h�擾
      lv_detail_first_flg := 'Y';
      OPEN xx03_detail_info_cur;
      <<xx03_detail_info_loop>>
      LOOP
        FETCH xx03_detail_info_cur INTO xx03_detail_info_rec;
        IF xx03_detail_info_cur%NOTFOUND THEN
          IF ( lv_detail_first_flg = 'Y' ) THEN
            -- 1�����Ȃ������ꍇ�̓G���[
            RAISE NO_DATA_FOUND;
          ELSE
            EXIT xx03_detail_info_loop;
          END IF;
        END IF;
        IF ( lv_detail_first_flg = 'Y' ) THEN
          lv_detail_first_flg := 'N';
        END IF;
--
        IF ( xx03_detail_info_rec.attribute7 = 'Y' ) THEN
          -- attribute7��'Y'�̃��R�[�h������΁Aov_app_upd��'Y'���Z�b�g����RETURN
          ov_app_upd := 'Y';
          CLOSE xx03_detail_info_cur;
          RETURN;
        END IF;
--
      END LOOP xx03_detail_info_loop;
      CLOSE xx03_detail_info_cur;
--
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                --*** �Ώۃf�[�^�Ȃ� ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
--
      -- �J�[�\���N���[�Y
      IF xx03_slip_type_cur%ISOPEN THEN
        CLOSE xx03_slip_type_cur;
      END IF;
      IF xx03_detail_info_cur%ISOPEN THEN
        CLOSE xx03_detail_info_cur;
      END IF;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END set_account_approval_flag;
--
  /**********************************************************************************
   * Procedure Name   : del_journal_data
   * Description      : �d��`�[���R�[�h�̍폜
   ***********************************************************************************/
  PROCEDURE del_journal_data(
    in_journal_id IN  NUMBER,    -- 1.�폜�Ώێd��`�[ID
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --�����g�����U�N�V������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.del_journal_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ###############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- 2005-01-06 ADD START
    cn_wf_status_save CONSTANT xx03_journal_slips.wf_status%TYPE   := '00';
    cn_delete_yes     CONSTANT xx03_journal_slips.delete_flag%TYPE := 'Y';
-- 2005-01-06 ADD END
--
    -- *** ���[�J���ϐ� ***
-- 2005-01-06 ADD START
    lv_wf_status        xx03_journal_slips.wf_status%TYPE;
-- 2005-01-06 ADD END
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- WF�X�e�[�^�X���擾
    SELECT xjs.wf_status
    INTO   lv_wf_status
    FROM   xx03_journal_slips xjs
    WHERE  xjs.journal_id = in_journal_id;
--
    -- �ۑ��`�[�͕����폜���s��
    IF lv_wf_status = cn_wf_status_save THEN
--
        -- �d��`�[���׃��R�[�h�폜
        DELETE FROM xx03_journal_slip_lines xjsl
        WHERE xjsl.journal_id = in_journal_id;
--
        -- �d��`�[�w�b�_���R�[�h�폜
        DELETE FROM xx03_journal_slips xjs
        WHERE xjs.journal_id = in_journal_id;
--
    -- �ۑ��ȊO�̏ꍇ�͘_���폜���s��
    ELSE
        -- �d��`�[�w�b�_���R�[�h�X�V
        UPDATE xx03_journal_slips
        SET    delete_flag = cn_delete_yes
              ,last_update_date = SYSDATE
        WHERE  journal_id = in_journal_id;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
  END del_journal_data;
--
-- ver11.5.10.1.6F Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_gl_input
   * Description      : �������(GL)�̃G���[�`�F�b�N(��ʗp)
   ***********************************************************************************/
  PROCEDURE check_deptinput_gl_input(
    in_journal_id    IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
    on_error_cnt     OUT  NUMBER,    -- 2.�����S�̂ł̃G���[�t���O
    ov_error_flg     OUT  VARCHAR2,  -- 3.�����S�̂ł̃G���[�t���O
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20�ڂ�RETURN�f�[�^�̃G���[���e
    ov_errbuf        OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.check_deptinput_gl_input'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ###############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_error_cnt NUMBER;            -- �d��`�F�b�N�G���[����
    lv_error_flg VARCHAR2(1);       -- �d��`�F�b�N�G���[�t���O
    lv_error_flg1 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O1
    lv_error_msg1 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W1
    lv_error_flg2 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O2
    lv_error_msg2 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W2
    lv_error_flg3 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O3
    lv_error_msg3 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W3
    lv_error_flg4 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O4
    lv_error_msg4 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W4
    lv_error_flg5 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O5
    lv_error_msg5 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W5
    lv_error_flg6 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O6
    lv_error_msg6 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W6
    lv_error_flg7 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O7
    lv_error_msg7 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W7
    lv_error_flg8 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O8
    lv_error_msg8 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W8
    lv_error_flg9 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O9
    lv_error_msg9 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W9
    lv_error_flg10 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O10
    lv_error_msg10 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W10
    lv_error_flg11 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O11
    lv_error_msg11 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W11
    lv_error_flg12 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O12
    lv_error_msg12 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W12
    lv_error_flg13 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O13
    lv_error_msg13 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W13
    lv_error_flg14 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O14
    lv_error_msg14 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W14
    lv_error_flg15 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O15
    lv_error_msg15 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W15
    lv_error_flg16 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O16
    lv_error_msg16 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W16
    lv_error_flg17 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O17
    lv_error_msg17 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W17
    lv_error_flg18 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O18
    lv_error_msg18 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W18
    lv_error_flg19 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O19
    lv_error_msg19 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W19
    lv_error_flg20 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O20
    lv_error_msg20 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W20
    lv_error_msg   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W
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
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --  �d��`�F�b�N�֐��Ăяo��
    xx03_deptinput_gl_check_pkg.check_deptinput_gl(
      in_journal_id,
      ln_error_cnt,
      lv_error_flg,
      lv_error_flg1,
      lv_error_msg1,
      lv_error_flg2,
      lv_error_msg2,
      lv_error_flg3,
      lv_error_msg3,
      lv_error_flg4,
      lv_error_msg4,
      lv_error_flg5,
      lv_error_msg5,
      lv_error_flg6,
      lv_error_msg6,
      lv_error_flg7,
      lv_error_msg7,
      lv_error_flg8,
      lv_error_msg8,
      lv_error_flg9,
      lv_error_msg9,
      lv_error_flg10,
      lv_error_msg10,
      lv_error_flg11,
      lv_error_msg11,
      lv_error_flg12,
      lv_error_msg12,
      lv_error_flg13,
      lv_error_msg13,
      lv_error_flg14,
      lv_error_msg14,
      lv_error_flg15,
      lv_error_msg15,
      lv_error_flg16,
      lv_error_msg16,
      lv_error_flg17,
      lv_error_msg17,
      lv_error_flg18,
      lv_error_msg18,
      lv_error_flg19,
      lv_error_msg19,
      lv_error_flg20,
      lv_error_msg20,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �߂�l�擾
    IF ( lv_error_flg = 'W' ) THEN
      -- �x���̏ꍇ�͐\���\�t���O�Ɍx���Z�b�g
      UPDATE xx03_journal_slips xjs
      SET    xjs.request_enable_flag = 'W'
      WHERE  xjs.journal_id = in_journal_id;
    ELSE
      -- �x���ȊO�̏ꍇ�͐\���\�t���O��'Y'�Z�b�g
      UPDATE xx03_journal_slips xjs
      SET    xjs.request_enable_flag = 'Y'
      WHERE  xjs.journal_id = in_journal_id;
    END IF;
--
    -- �f�[�^�m��
    COMMIT;
--
    -- OUT�p�����[�^�Z�b�g
    on_error_cnt   := ln_error_cnt;
    ov_error_flg   := lv_error_flg;
    ov_error_flg1  := lv_error_flg1;
    ov_error_msg1  := lv_error_msg1;
    ov_error_flg2  := lv_error_flg2;
    ov_error_msg2  := lv_error_msg2;
    ov_error_flg3  := lv_error_flg3;
    ov_error_msg3  := lv_error_msg3;
    ov_error_flg4  := lv_error_flg4;
    ov_error_msg4  := lv_error_msg4;
    ov_error_flg5  := lv_error_flg5;
    ov_error_msg5  := lv_error_msg5;
    ov_error_flg6  := lv_error_flg6;
    ov_error_msg6  := lv_error_msg6;
    ov_error_flg7  := lv_error_flg7;
    ov_error_msg7  := lv_error_msg7;
    ov_error_flg8  := lv_error_flg8;
    ov_error_msg8  := lv_error_msg8;
    ov_error_flg9  := lv_error_flg9;
    ov_error_msg9  := lv_error_msg9;
    ov_error_flg10 := lv_error_flg10;
    ov_error_msg10 := lv_error_msg10;
    ov_error_flg11 := lv_error_flg11;
    ov_error_msg11 := lv_error_msg11;
    ov_error_flg12 := lv_error_flg12;
    ov_error_msg12 := lv_error_msg12;
    ov_error_flg13 := lv_error_flg13;
    ov_error_msg13 := lv_error_msg13;
    ov_error_flg14 := lv_error_flg14;
    ov_error_msg14 := lv_error_msg14;
    ov_error_flg15 := lv_error_flg15;
    ov_error_msg15 := lv_error_msg15;
    ov_error_flg16 := lv_error_flg16;
    ov_error_msg16 := lv_error_msg16;
    ov_error_flg17 := lv_error_flg17;
    ov_error_msg17 := lv_error_msg17;
    ov_error_flg18 := lv_error_flg18;
    ov_error_msg18 := lv_error_msg18;
    ov_error_flg19 := lv_error_flg19;
    ov_error_msg19 := lv_error_msg19;
    ov_error_flg20 := lv_error_flg20;
    ov_error_msg20 := lv_error_msg20;
    ov_errbuf      := lv_errbuf;
    ov_retcode     := lv_retcode;
    ov_errmsg      := lv_errmsg;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_deptinput_gl_input;
-- ver11.5.10.1.6F Add End
--
END xx03_deptinput_gl_check_pkg;
/
