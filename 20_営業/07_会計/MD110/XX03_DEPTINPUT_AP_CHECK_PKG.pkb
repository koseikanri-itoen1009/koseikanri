CREATE OR REPLACE PACKAGE BODY xx03_deptinput_ap_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ap_check_pkg(body)
 * Description            : �������(AP)�ɂ����ē��̓`�F�b�N���s�����ʊ֐�
 * MD.070                 : �������(AP)���ʊ֐� OCSJ/BFAFIN/MD070/F409
 * Version                : 11.5.10.2.16
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ap          P          �������(AP)�̃G���[�`�F�b�N
 *  set_account_approval_flag   P          �d�_�Ǘ��`�F�b�N
 *  get_terms_date              P          �x���N�Z���̎Z�o
 *  del_pay_data                P          �x���`�[���R�[�h�̍폜
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/02/09   1.0            �V�K�쐬
 *  2004/02/18   1.1            �P�̃e�X�g�ł̕s��C��
 *  2004/02/19   1.2            �d�l�ύX
 *  2004/02/23   1.3            get_terms_date�̎x���\���SQL���C��
 *  2004/02/26   1.4            �x���`�[���R�[�h�̍폜�v���V�[�W���ǉ�
 *  2004/03/26   1.5            �O���`�[�ԍ��������`�F�b�N�����ǉ�
 *  2004/04/13   1.6            �d�_�Ǘ��̔�����@�ύX
 *  2005/01/17   1.7            ���݌��؃��[���̋@�\����
 *  2005/01/22   1.8            �x���`�[���R�[�h�̍폜�����̕ύX
 *  2005/09/02   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/18   11.5.10.1.5B   ����`�[���ēx�\���ł��Ă��܂��s��Ή�
 *  2006/01/30   11.5.10.1.6    ���݌��؃��[���̃`�F�b�N�ŁA���t��GL�v�����
 *                              �n���悤�ύX
 *  2006/02/15   11.5.10.1.6B   �_�u���N���b�N�Ή�,PKG��commit����PROCEDURE�ǉ�
 *  2006/02/15   11.5.10.1.6C   �}�X�^�[���݃`�F�b�N�����{����悤�ɕύX
 *  2006/03/02   11.5.10.1.6D   �G���[�`�F�b�N�e�[�u���̃N���A���W�b�N�̕s�
 *  2006/03/06   11.5.10.1.6E   ���F�҂̏��F�����`�F�b�N�s��C��
 *  2006/03/29   11.5.10.2.1    HR�Ή��i�]�ƈ��������R�[�h�Ή��j
 *  2006/04/07   11.5.10.2.2    ���F�҂��Ώۓ`�[�ɑ΂��鏳�F���������邩�̃`�F�b�N�ǉ�
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2�ł̏C���~�X�Ή�
 *  2006/06/22   11.5.10.2.3    �}�X�^�`�F�b�N�pSQL�Ńf�[�^���擾�łȂ���������
 *                              �G���[����������Ă��邱�Ƃ̏C��
 *  2006/07/12   11.5.10.2.3B   �U��������`�F�b�N�pSQL�ŕK�{�������̏C��
 *  2006/08/17   11.5.10.2.4    �d����E�T�C�g�̃}�X�^�`�F�b�N�ŗL������
 *                              ���������t�ł͂Ȃ�SYSDATE�Ń`�F�b�N����悤�ɏC��
 *  2006/09/06   11.5.10.2.5    �U��������`�F�b�N�����̕ύX(�d����T�C�g�̎x�����@��
 *                              �d�M�̏ꍇ�̂݌����̗L�����݃`�F�b�N���s�Ȃ�)
 *  2006/10/03   11.5.10.2.6    �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                              �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2007/07/17   11.5.10.2.10   �E�v�R�[�h�`�F�b�N�̏C��(�L�������������͂�OK�Ƃ���)
 *  2007/08/06   11.5.10.2.10B  �x���O���[�v�`�F�b�N�̏C��(�L�������������͂�OK�Ƃ���)
 *  2007/08/10   11.5.10.2.10C  �d��z���`�F�b�N�ŃG���[�̎��̃��b�Z�[�W��
 *                              �w�b�_����ץ�ŋ��̂ǂ̔z������\������悤�ɏC��
 *  2007/08/16   11.5.10.2.10D  ��s�x�X/��s�����̖������͑O���܂ŗL���Ƃ���悤�ɏC��
 *  2007/10/04   11.5.10.2.10E  �U��������`�F�b�N���Ɏx�����@���d�M���ǂ����Ƃ���
 *                              ���f���s���Ă��邪�A�d����T�C�g�̎x�����@�ł͂Ȃ�
 *                              �x���O���[�v��DFF�x�����@���g�p����悤�ɏC��
 *  2007/10/29   11.5.10.2.10F  �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ�
 *  2008/01/07   11.5.10.2.10G  to_date�֐��ɂď����w����s���Ă��Ȃ��ӏ�������
 *                              yyyy/mm/dd�������F���ł��Ȃ��ꍇ�ɃG���[�ƂȂ鎖�̏C��
 *  2012/02/15   11.5.10.2.11   [E_�{�ғ�_09132]�Ή� �E�v�R�[�h��DFF10(�ŃR�[�h)��
 *                              ���͂����ŃR�[�h����v���Ă��邩�`�F�b�N����C��
 *  2013/06/10   11.5.10.2.12   [E_�{�ғ�_10838]�Ή� ��ʕ\���l�Ɠo�^�l�̃`�F�b�N�ǉ�
 *  2016/11/14   11.5.10.2.13   [E_�{�ғ�_13901]�Ή� �g�c���ٔԍ��̌`���`�F�b�N�ǉ�
 *  2018/02/07   11.5.10.2.14   [E_�{�ғ�_14663]�Ή� �g�c���ٔԍ��̌Œ�l�`�F�b�N�C��(SP�Ŏn�܂�ԍ��ɑΉ�)
 *  2021/04/06   11.5.10.2.15   [E_�{�ғ�_16026]�Ή� AP������� ���Ȗڌv�㎞�̐���
 *  2021/12/17   11.5.10.2.16   [E_�{�ғ�_17678]�Ή� �d�q����ۑ��@�����Ή�
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ap
   * Description      : �������(AP)�̃G���[�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_deptinput_ap(
    in_invoice_id  IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
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
      'xx03_deptinput_ap_check_pkg.check_deptinput_ap'; -- �v���O������
--2021/04/06 Ver11.5.10.2.15 ADD START
    cv_dept_fin   CONSTANT VARCHAR2(4)   := '1011';
    cv_corp_def   CONSTANT VARCHAR2(6)   := '000000';
    cv_cust_def   CONSTANT VARCHAR2(9)   := '000000000';
    cv_yes        CONSTANT VARCHAR2(1)   := 'Y';
    cv_z          CONSTANT VARCHAR2(4)   := 'ZZZZ';
    cv_lookup_liabilities_code CONSTANT VARCHAR2(30) := 'XXCFO1_LIABILITIES_CODE';
--2021/04/06 Ver11.5.10.2.15 ADD END
--ver11.5.10.2.16 Add Start
    cv_slip_type  CONSTANT VARCHAR2(5)   := '30000';
--ver11.5.10.2.16 Add End
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
    -- �G���[�t���O�p�z��^�C�v
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
    -- �G���[���b�Z�[�W�p�z��^�C�v
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    errflg_tbl errflg_tbl_type;
    errmsg_tbl errmsg_tbl_type;
    ln_err_cnt NUMBER := 0;    -- �p�����[�^�Y���p�ϐ�
    ln_books_id NUMBER;        -- ����ID
    lv_first_flg VARCHAR2(1) := 'Y';  -- 1���ڂ̃��R�[�h���ۂ�
-- ver 11.5.10.1.6D Chg Start
    --ln_check_seq NUMBER;       -- �G���[�`�F�b�N�V�[�P���X�ԍ�
    ln_check_seq NUMBER := 0;  -- �G���[�`�F�b�N�V�[�P���X�ԍ�
-- ver 11.5.10.1.6D Chg End
    ln_cnt NUMBER;             -- ���[�v�J�E���^
    lv_err_status VARCHAR2(1); -- ���ʃG���[�`�F�b�N�X�e�[�^�X
    lv_currency_code VARCHAR2(15); -- �@�\�ʉ݃R�[�h
    lv_chk_currency_code VARCHAR2(15);      -- �`�F�b�N�p�f�[�^�ʉ݃R�[�h
    ln_chk_exchange_rate NUMBER;            -- �`�F�b�N�p�f�[�^���Z���[�g
    lv_chk_exchange_rate_type VARCHAR2(30); -- �`�F�b�N�p�f�[�^���Z���[�g�^�C�v
    ld_chk_gl_date DATE;                    -- �`�F�b�N�p�f�[�^�v���
    lv_chk_prepay_num VARCHAR2(50);         -- �`�F�b�N�p�f�[�^�O���[���`�[�ԍ�
    lv_chk_orig_invoice_num VARCHAR2(150);  -- �`�F�b�N�p�f�[�^�C�����`�[�ԍ�
    -- 2004/02/19 ADD START
    lv_period_data_flg VARCHAR2(1);         -- ��v���ԃf�[�^�L���t���O
    -- 2004/02/19 ADD END
    -- 2005/01/17:���݌��ؗp�p�����[�^
    lb_retcode BOOLEAN;
    lv_app_short_name VARCHAR2(100) := 'SQLGL'; -- �A�v���P�[�V����'General Ledger'
    lv_key_flex_code VARCHAR2(1000) := 'GL#'; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER := null; -- GL_SETS_OF_BOOKS.CHART_OF_ACCOUNTS_ID,
    ld_validation_date DATE := SYSDATE;
    ln_segments NUMBER := 8;
    lv_segment_array FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id NUMBER := null;
    ld_data_set NUMBER := -1;
    --2006/02/18 Ver11.5.10.1.6C Add START
    ld_chk_invoice_date DATE;                    -- �`�F�b�N�p�f�[�^���������t
    --2006/02/18 Ver11.5.10.1.6C Add END
    -- 2006/03/06 Ver11.5.10.1.6E Add Start
    ld_wf_status              VARCHAR2(25);        -- �`�F�b�N�p���[�N�t���[�X�e�[�^�X
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- ������͏��F�҂��X�e�[�^�X
    -- 2006/03/06 Ver11.5.10.1.6E Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- ������͕ۑ��X�e�[�^�X
    cn_wf_status_last   VARCHAR2(25) := '30';      -- ������͍ŏI���右�F�҂��X�e�[�^�X
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.5 Add Start
    cv_vendor_sites_eft VARCHAR2(3) := 'EFT';      -- �d����T�C�g�̎x�����@�̒l��d�M�
    -- ver 11.5.10.2.5 Add End
--
    -- ver 11.5.10.2.10C Add Start
    lv_je_err_msg       VARCHAR2(14);              -- �z���`�F�b�N�G���[���̒ǉ����b�Z�[�W�R�[�h
    -- ver 11.5.10.2.10C Add End
--
    -- ver 11.5.10.2.10F Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- �ʉ݃G���[OK/NG�t���O(���x�`�F�b�N���Ɏg�p)
    ln_currency_precision  NUMBER(1)    := 0;      -- �ʉ݂̐��x(�ʉ݃`�F�b�NOK���ɐ��x���擾)
    lv_amount              VARCHAR2(50) := '';     -- �`�[�ł̋��z���x�擾�p
    ln_amount_precision    NUMBER(1)    := 0;      -- �`�[�ł̋��z�̐��x
    cv_precision_char      VARCHAR2(1)  := '.';    -- �����_�L��
    -- ver 11.5.10.2.10F Add End
--
--2021/04/06 Ver11.5.10.2.15 ADD START
    ln_count               NUMBER       := 0;
--2021/04/06 Ver11.5.10.2.15 ADD END
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����Ώۃf�[�^�擾�J�[�\��
    CURSOR xx03_xpsjlv_cur
    IS
      SELECT xpsjlv.invoice_num as invoice_num,
             xpsjlv.line_number as line_number,
             xpsjlv.gl_date as gl_date,
             xpsjlv.invoice_currency_code as invoice_currency_code,
             xpsjlv.code_combination_id as code_combination_id,
             xpsjlv.segment1 as segment1,
             xpsjlv.segment2 as segment2,
             xpsjlv.segment3 as segment3,
             xpsjlv.segment4 as segment4,
             xpsjlv.segment5 as segment5,
             xpsjlv.segment6 as segment6,
             xpsjlv.segment7 as segment7,
             xpsjlv.segment8 as segment8,
             xpsjlv.tax_code as tax_code,
             xpsjlv.incr_decr_reason_code as incr_decr_reason_code,
             xpsjlv.entry_department as entry_department,
             xpsjlv.user_name as user_name,
             xpsjlv.recon_reference as recon_reference,
      --2006/02/16 Ver11.5.10.1.6C add START
             --xpsjlv.amount as amount
             xpsjlv.amount as amount,
             xpsjlv.line_type_lookup_code as line_type_lookup_code
      --2006/02/16 Ver11.5.10.1.6C add END
--2016/11/14 Ver11.5.10.2.13 ADD START
            ,xpsjlv.attribute7 as attribute7
--2016/11/14 Ver11.5.10.2.13 ADD END
        FROM xx03_pay_slip_journal_lines_v xpsjlv
       WHERE xpsjlv.invoice_id = in_invoice_id
       ORDER BY xpsjlv.line_number;
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
-- ver1.5 ADD START
    -- �O���[���`�[�ԍ��擾�`�F�b�N�J�[�\��
    CURSOR xx03_prepay_get_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xpsv.prepay_num as prepay_num
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.invoice_id = in_invoice_id;
      SELECT xps.prepay_num as prepay_num
        FROM xx03_payment_slips xps
       WHERE xps.invoice_id = in_invoice_id;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- �O���[���`�[�ԍ��������`�F�b�N�J�[�\��
    CURSOR xx03_prepay_check_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xpsv.invoice_id
--        FROM xx03_payment_slips_v xpsv,
--             xx03_prepayment_lov_v xplv
--       WHERE xpsv.invoice_id = in_invoice_id
--         AND xpsv.prepay_num = xplv.invoice_num
--         AND xpsv.vendor_id = xplv.vendor_id
--         AND xpsv.invoice_currency_code = xplv.invoice_currency_code;
      SELECT xps.invoice_id
        FROM xx03_payment_slips xps,
             xx03_prepayment_lov_v xplv
       WHERE xps.invoice_id = in_invoice_id
         AND xps.prepay_num = xplv.invoice_num
         AND xps.vendor_id = xplv.vendor_id
         AND xps.invoice_currency_code = xplv.invoice_currency_code;
-- Ver11.5.10.1.5 2005/09/02 Change End
-- ver1.5 ADD END
--
    -- �O���[���`�[�ԍ��`�F�b�N�J�[�\��
    CURSOR xx03_prepay_num_cur(
      iv_prepay_num IN VARCHAR2 -- 1.�O���[���`�[�ԍ�
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.ap_forword_date IS NULL
--         AND xpsv.prepay_num = iv_prepay_num
--         AND xpsv.wf_status >= 20
--         AND xpsv.invoice_id != in_invoice_id;
      SELECT *
        FROM xx03_payment_slips xps
       WHERE xps.ap_forword_date IS NULL
         AND xps.prepay_num = iv_prepay_num
         AND xps.wf_status >= 20
         AND xps.invoice_id != in_invoice_id
         AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- �C�����`�[�ԍ��`�F�b�N�J�[�\��
    CURSOR xx03_orig_num_cur(
      iv_orig_invoice_num  IN VARCHAR2 -- 1.�C�����`�[�ԍ�
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.ap_forword_date IS NULL
--         AND xpsv.orig_invoice_num = iv_orig_invoice_num
--         AND xpsv.wf_status >= 20
--         AND xpsv.invoice_id != in_invoice_id;
      -- Ver11.5.10.1.5B 2005/10/18 Change Start
      --SELECT *
      --  FROM xx03_payment_slips xps
      -- WHERE xps.ap_forword_date IS NULL
      --   AND xps.orig_invoice_num = iv_orig_invoice_num
      --   AND xps.wf_status >= 20
      --   AND xps.invoice_id != in_invoice_id
      --   AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM xx03_payment_slips xps
       WHERE xps.orig_invoice_num = iv_orig_invoice_num
         AND xps.wf_status >= 20
         AND xps.invoice_id != in_invoice_id
         AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5B 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- AP��v���ԃ`�F�b�N�J�[�\��
    CURSOR xx03_ap_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.����ID
      id_gl_date    IN DATE       -- 2.GL�L����
    ) IS
      SELECT gps.closing_status as closing_status
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLAP')
         AND gps.set_of_books_id = in_books_id
         AND gps.start_date <= TRUNC(id_gl_date)
         AND gps.end_date >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag = 'N';
--
    -- GL��v���ԃ`�F�b�N�J�[�\��
    CURSOR xx03_gl_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.����ID
      id_gl_date    IN DATE       -- 2.GL�L����
    ) IS
      SELECT gps.attribute1 as attribute1
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id = in_books_id
         AND gps.start_date <= TRUNC(id_gl_date)
         AND gps.end_date >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag = 'N';
--
-- ver 11.5.10.2.2 add Start
    -- �\���҂Ə��F�҂̊֌W �`�F�b�N�J�[�\��
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_PAYMENT_SLIPS          XPS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XPS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XPS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'SQLAP'   )
      AND  XAPV.PERSON_ID   = XPS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--2006/02/15 Ver11.5.10.1.6C add start
--�e�}�X�^�[���݃`�F�b�N
--
    --���F�҃`�F�b�N�J�[�\��
    CURSOR xx03_approver_cur
    IS
-- 2006/03/06 Ver11.5.10.1.6E Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_payment_slips xps
--     WHERE xps.invoice_id = in_invoice_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xps.requestor_person_id;
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
                           ,XX03_PAYMENT_SLIPS          XPS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XPS.INVOICE_ID = in_invoice_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XPS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XPS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'SQLAP'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/06 Ver11.5.10.1.6E Change End
--
    --�d����`�F�b�N�J�[�\��
    CURSOR xx03_vendor_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   PO_VENDORS PV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  PV.VENDOR_ID = XPS.VENDOR_ID
      -- ver 11.5.10.2.4 Add Start
      --AND  XPS.INVOICE_DATE < NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.4 Add End
--
    --�d����T�C�g�`�F�b�N�J�[�\��
    CURSOR xx03_vendor_site_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   PO_VENDOR_SITES_ALL PVS
          ,XX03_PAYMENT_SLIPS  XPS
    WHERE  PVS.ORG_ID             = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  PVS.PAY_SITE_FLAG      = 'Y'
      AND  PVS.AUTO_TAX_CALC_FLAG = 'N'
      AND  PVS.VENDOR_ID      = XPS.VENDOR_ID
      AND  PVS.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
      AND  XPS.INVOICE_ID = in_invoice_id
      -- ver 11.5.10.2.4 Add Start
      --AND  XPS.INVOICE_DATE < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.4 Add End
--
    --�U��������`�F�b�N
    -- ver 11.5.10.2.5 Chg Start
    --CURSOR xx03_bank_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   PO_VENDOR_SITES_ALL      PVS
    --      ,AP_BANK_ACCOUNT_USES_ALL ABAU
    --      ,AP_BANK_ACCOUNTS_ALL     ABA
    --      ,AP_BANK_BRANCHES         ABB
    --      ,XX03_PAYMENT_SLIPS       XPS
    --WHERE  XPS.INVOICE_ID = in_invoice_id
    --  AND  PVS.PAY_SITE_FLAG = 'Y'
    --  AND  PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  PVS.VENDOR_ID      = XPS.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
    --  AND  PVS.VENDOR_ID      = ABAU.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID = ABAU.VENDOR_SITE_ID
    --  AND  ABAU.PRIMARY_FLAG  = 'Y'
    --  -- ver 11.5.10.2.3B Add Start
    --  --AND  XPS.INVOICE_DATE BETWEEN ABAU.START_DATE
    --  --                     AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  AND  XPS.INVOICE_DATE BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                       AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  -- ver 11.5.10.2.3B Add End
    --  AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
    --  AND  XPS.INVOICE_DATE < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
    --  AND  XPS.INVOICE_DATE < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
    --
--
    -- ver 11.5.10.2.10E Chg Start
    --CURSOR xx03_bank_name_cur
    --IS
    --SELECT PVS.PAYMENT_METHOD_LOOKUP_CODE PAYMETHOD
    --      ,AP_BANK.NAME NAME
    --FROM   XX03_PAYMENT_SLIPS       XPS
    --      ,PO_VENDOR_SITES_ALL      PVS
    --      ,(SELECT ABAU.VENDOR_ID      VENDOR_ID
    --              ,ABAU.VENDOR_SITE_ID VENDOR_SITE_ID
    --              -- ver 11.5.10.2.6 Chg Start
    --              --,ABB.BANK_NAME        || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
    --              -- DECODE(ABA.BANK_ACCOUNT_TYPE, '1', '����', '2', '����', '') || ' ' || ABA.BANK_ACCOUNT_NUM
    --              -- NAME
    --              ,NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
    --                                   DECODE(ABA.BANK_ACCOUNT_TYPE ,'1' ,'����' ,'2' ,'����' ,'') || ' ' || ABA.BANK_ACCOUNT_NUM
    --                                  ,null) NAME
    --              -- ver 11.5.10.2.6 Chg End
    --        FROM   XX03_PAYMENT_SLIPS       XPS
    --              ,AP_BANK_ACCOUNT_USES_ALL ABAU
    --              ,AP_BANK_ACCOUNTS_ALL     ABA
    --              ,AP_BANK_BRANCHES         ABB
    --        WHERE  XPS.INVOICE_ID = in_invoice_id
    --          AND  ABAU.VENDOR_ID      = XPS.VENDOR_ID
    --          AND  ABAU.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
    --          AND  ABAU.PRIMARY_FLAG  = 'Y'
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --          --                          AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                                  AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.6 Chg End
    --          AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --          AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg Start
    --          --AND  TRUNC(SYSDATE) <= NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg End
    --          -- ver 11.5.10.2.6 Chg End
    --          AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg Start
    --          --AND  TRUNC(SYSDATE) <= NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg End
    --          -- ver 11.5.10.2.6 Chg End
    --        ) AP_BANK
    --WHERE  XPS.INVOICE_ID = in_invoice_id
    --  AND  PVS.PAY_SITE_FLAG = 'Y'
    --  AND  PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  PVS.VENDOR_ID       = XPS.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID  = XPS.VENDOR_SITE_ID
    --  AND  PVS.VENDOR_ID       = AP_BANK.VENDOR_ID     (+)
    --  AND  PVS.VENDOR_SITE_ID  = AP_BANK.VENDOR_SITE_ID(+)
    --;
    ---- ver 11.5.10.2.5 Chg End
--
    --�U��������擾
    CURSOR xx03_bank_name_cur
    IS
    SELECT NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
                DECODE(ABA.BANK_ACCOUNT_TYPE ,'1' ,'����' ,'2' ,'����' ,'') || ' ' || ABA.BANK_ACCOUNT_NUM
                ,null) NAME
    FROM   XX03_PAYMENT_SLIPS       XPS
          ,AP_BANK_ACCOUNT_USES_ALL ABAU
          ,AP_BANK_ACCOUNTS_ALL     ABA
          ,AP_BANK_BRANCHES         ABB
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  ABAU.VENDOR_ID      = XPS.VENDOR_ID
      AND  ABAU.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
      AND  ABAU.PRIMARY_FLAG  = 'Y'
      AND  TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                              AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
      AND  TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
      AND  TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    ;
--
    --�x�����@�擾
    CURSOR xx03_pay_group_method_cur
    IS
    SELECT FLV.ATTRIBUTE1 PAYMETHOD
    FROM   FND_LOOKUP_VALUES  FLV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  FLV.LOOKUP_TYPE = 'PAY GROUP'
      AND  FLV.LANGUAGE = USERENV('LANG')
      AND  FLV.ENABLED_FLAG = 'Y'
      AND  FLV.LOOKUP_CODE = XPS.PAY_GROUP_LOOKUP_CODE
      AND  TRUNC(SYSDATE) BETWEEN NVL(FLV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                              AND NVL(FLV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
    -- ver 11.5.10.2.10E Chg End
--
    -- ver 11.5.10.2.10F Chg Start
    ----�ʉ݃`�F�b�N
    --CURSOR xx03_currency_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   FND_CURRENCIES     FC
    --      ,XX03_PAYMENT_SLIPS XPS
    --WHERE  XPS.INVOICE_ID   = in_invoice_id
    --  AND  FC.ENABLED_FLAG  = 'Y'
    --  AND  FC.CURRENCY_FLAG = 'Y'
    --  AND  FC.CURRENCY_CODE = XPS.INVOICE_CURRENCY_CODE
    --  -- ver 11.5.10.2.6 Chg Start
    --  --AND  XPS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.6 Chg End
    --
    --�ʉ݃`�F�b�N(���x�`�F�b�N�p�ɐ��x���擾����悤�ɕύX)
    CURSOR xx03_currency_name_cur
    IS
    SELECT FC.CURRENCY_CODE      CURRENCY_CODE
          ,NVL(FC.PRECISION , 0) PRECISION
    FROM   FND_CURRENCIES     FC
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID   = in_invoice_id
      AND  FC.ENABLED_FLAG  = 'Y'
      AND  FC.CURRENCY_FLAG = 'Y'
      AND  FC.CURRENCY_CODE = XPS.INVOICE_CURRENCY_CODE
      AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                              AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10F Chg End
--
    --�x���O���[�v�`�F�b�N
    CURSOR xx03_pay_group_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   FND_LOOKUP_VALUES  FLV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  FLV.LOOKUP_TYPE = 'PAY GROUP'
      AND  FLV.LANGUAGE = USERENV('LANG')
      AND  FLV.ENABLED_FLAG = 'Y'
      AND  FLV.LOOKUP_CODE = XPS.PAY_GROUP_LOOKUP_CODE
      -- ver 11.5.10.2.6 Chg Start
      --AND  XPS.INVOICE_DATE BETWEEN FLV.START_DATE_ACTIVE
      --                          AND NVL(FLV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10B Chg Start
--      AND  TRUNC(SYSDATE) BETWEEN FLV.START_DATE_ACTIVE
--                              AND NVL(FLV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) BETWEEN NVL(FLV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                              AND NVL(FLV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10B Chg End
      -- ver 11.5.10.2.6 Chg End
--
    --�x�������`�F�b�N
    CURSOR xx03_terms_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   AP_TERMS           AT
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID  = in_invoice_id
      AND  AT.ENABLED_FLAG = 'Y'
      AND  AT.TERM_ID = XPS.TERMS_ID
      -- ver 11.5.10.2.6 Chg Start
      --AND  XPS.INVOICE_DATE BETWEEN AT.START_DATE_ACTIVE
      --                          AND NVL(AT.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  NVL(AT.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD')) <= TRUNC(SYSDATE)
      AND  TRUNC(SYSDATE) < NVL(AT.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.6 Chg End
--
    --�K�p�R�[�h�`�F�b�N
    CURSOR xx03_slip_line_type_name_cur(
      in_line_number  IN number,    -- 1.���הԍ�
      id_invoice_date IN DATE       -- 2.���������t
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_PAYMENT_SLIP_LINES XPSL
    WHERE  XPSL.INVOICE_ID   = in_invoice_id
      AND  XPSL.LINE_NUMBER  = in_line_number
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XPSL.SLIP_LINE_TYPE
-- ver 11.5.10.2.10 Chg Start
--      AND  id_invoice_date BETWEEN XLXV.START_DATE_ACTIVE
--                           AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  id_invoice_date BETWEEN NVL(XLXV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                               AND NVL(XLXV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10 Chg Start
--
    --�ŋ��R�[�h�`�F�b�N
    CURSOR xx03_tax_col_cur(
      in_line_number  IN number,    -- 1.���הԍ�
      id_invoice_date IN DATE       -- 2.���������t
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_TAX_CODES_LOV_V    XTCL
          ,XX03_PAYMENT_SLIP_LINES XPSL
    WHERE  XPSL.INVOICE_ID  = in_invoice_id
      AND  XPSL.LINE_NUMBER  = in_line_number
      AND  XTCL.NAME = XPSL.TAX_CODE
      AND  id_invoice_date BETWEEN NVL(XTCL.START_DATE   , TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                          AND NVL(XTCL.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
--2006/02/15 Ver11.5.10.1.6C add End
--2012/02/15 Ver11.5.10.2.11 ADD START
--
    --�ŋ��R�[�h�ύX�`�F�b�N
    CURSOR xx03_tax_chenge_cur(
      in_line_number  IN number,    -- 1.���הԍ�
      id_invoice_date IN DATE       -- 2.���������t
    ) IS
    SELECT xlxv.attribute10                            line_type_tax_code       -- �E�v�R�[�h�ŃR�[�h
          ,xlxv.attribute10 || '-' || atca.description line_type_tax_name       -- �E�v�R�[�h�Ŗ�
          ,xpsl.tax_code                               input_tax_code           -- ���͂����ŃR�[�h
    FROM   xx03_lookups_xx03_v     xlxv
          ,xx03_payment_slip_lines xpsl
          ,ap_tax_codes_all        atca
    WHERE  xpsl.invoice_id   = in_invoice_id
      AND  xpsl.line_number  = in_line_number
      AND  xlxv.language     = USERENV('LANG')
      AND  xlxv.lookup_type  = 'XX03_SLIP_LINE_TYPES'
      AND  xlxv.attribute15  = xx00_profile_pkg.value('ORG_ID')
      AND  xlxv.enabled_flag = 'Y'
      AND  xlxv.lookup_code  = xpsl.slip_line_type
      AND  xlxv.attribute10  = atca.name(+)
      AND  id_invoice_date BETWEEN NVL(xlxv.start_date_active, TO_DATE('1000/01/01','YYYY/MM/DD'))
                               AND NVL(xlxv.end_date_active  , TO_DATE('4712/12/31','YYYY/MM/DD'));
--
--2012/02/15 Ver11.5.10.2.11 ADD END
--
    -- ���ʃG���[�`�F�b�N���ʎ擾�J�[�\��
    CURSOR xx03_errchk_result_cur
    IS
      SELECT xei.journal_id as journal_id,
             xei.line_number as line_number,
             xei.error_code as error_code,
             xei.error_message as error_message,
             xei.status as status
        FROM xx03_error_info xei
       WHERE xei. check_id = ln_check_seq
-- ver11.5.10.1.6B Add Start
       ORDER BY xei.line_number;
-- ver11.5.10.1.6B Add End
--
-- 2013/06/10 Ver11.5.10.2.12 ADD START
    -- ��ʕ\���l-�o�^�l����G���[�`�F�b�N���ʎ擾�J�[�\��
    CURSOR xx03_save_code_chk_cur
    IS
      SELECT /*+ LEADING(xps xpsl) */
             COUNT(1)                AS exist_check
      FROM   xx03_payment_slips      xps
            ,xx03_payment_slip_lines xpsl
      WHERE  xps.org_id     = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND    xps.invoice_id = xpsl.invoice_id
      AND    xps.invoice_id = in_invoice_id
      AND (
           ( SUBSTRB( xps.requestor_person_name, 1, 5 )  <> ( SELECT papf.employee_number      AS employee_number      -- �\���Җ�
                                                              FROM   per_all_people_f          papf
                                                              WHERE  papf.person_id = xps.requestor_person_id
                                                              AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                    AND     papf.effective_end_date ) )
        OR ( SUBSTRB( xps.approver_person_name, 1, 5 )   <> ( SELECT papf.employee_number      AS employee_number      -- ���F�Җ�
                                                              FROM   per_all_people_f          papf
                                                              WHERE  papf.person_id = xps.approver_person_id
                                                              AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                    AND     papf.effective_end_date ) )
        OR ( SUBSTRB( xps.vendor_name, 1, 9 )            <> ( SELECT pv.segment1               AS segment1             -- �d���於
                                                              FROM   po_vendors                pv
                                                              WHERE  pv.vendor_id = xps.vendor_id ) )
        OR ( xps.vendor_site_name                        <> ( SELECT pvs.vendor_site_code      AS vendor_site_code     -- �d����T�C�g��
                                                              FROM   po_vendor_sites_all       pvs
                                                              WHERE  pvs.vendor_site_id = xps.vendor_site_id
                                                              AND    pvs.org_id         = xps.org_id ) )
        OR ( ( xps.exchange_rate_type_name IS NULL )     AND ( xps.exchange_rate_type IS NOT NULL ) )                  -- ���Z���[�g�^�C�v��
        OR ( ( xps.exchange_rate_type_name IS NOT NULL ) AND ( xps.exchange_rate_type IS NULL ) )                      -- ���Z���[�g�^�C�v��
        OR ( xps.exchange_rate_type_name                 <> ( SELECT gdct.user_conversion_type AS user_conversion_type -- ���Z���[�g�^�C�v��
                                                              FROM   gl_daily_conversion_types gdct
                                                              WHERE  gdct.conversion_type = xps.exchange_rate_type ) )
        OR ( xps.terms_name                              <> ( SELECT at.name                   AS name                 -- �x��������
                                                              FROM   ap_terms                  at
                                                              WHERE  at.term_id = xps.terms_id ) )
        OR ( xps.pay_group_lookup_name                   <> ( SELECT flv.meaning               AS meaning              -- �x���O���[�v��
                                                              FROM   fnd_lookup_values         flv
                                                              WHERE  flv.lookup_code  = xps.pay_group_lookup_code
                                                              AND    flv.lookup_type  = 'PAY GROUP'
                                                              AND    flv.language     = USERENV('LANG')
                                                              AND    flv.enabled_flag = 'Y'
                                                              AND    TRUNC(SYSDATE) BETWEEN NVL( flv.start_date_active, TO_DATE('1000/01/01','YYYY/MM/DD') )
                                                              AND                           NVL( flv.end_date_active  , TO_DATE('4712/12/31','YYYY/MM/DD') ) ) )
        OR ( xpsl.slip_line_type <> SUBSTRB( xpsl.slip_line_type_name, 1, LENGTHB(xpsl.slip_line_type) ) )             -- �E�v�R�[�h��
        OR ( xpsl.tax_code <> SUBSTRB( xpsl.tax_name, 1, LENGTHB(xpsl.tax_code) ) )                                    -- �ŋ敪��
        OR ( xpsl.segment1 <> SUBSTRB( xpsl.segment1_name, 1, LENGTHB(xpsl.segment1) ) )                               -- AFF ���
        OR ( xpsl.segment2 <> SUBSTRB( xpsl.segment2_name, 1, LENGTHB(xpsl.segment2) ) )                               -- AFF ����
        OR ( xpsl.segment3 <> SUBSTRB( xpsl.segment3_name, 1, LENGTHB(xpsl.segment3) ) )                               -- AFF ����Ȗ�
        OR ( xpsl.segment4 <> SUBSTRB( xpsl.segment4_name, 1, LENGTHB(xpsl.segment4) ) )                               -- AFF �⏕�Ȗ�
        OR ( xpsl.segment5 <> SUBSTRB( xpsl.segment5_name, 1, LENGTHB(xpsl.segment5) ) )                               -- AFF �ڋq
        OR ( xpsl.segment6 <> SUBSTRB( xpsl.segment6_name, 1, LENGTHB(xpsl.segment6) ) )                               -- AFF ���
        OR ( xpsl.segment7 <> SUBSTRB( xpsl.segment7_name, 1, LENGTHB(xpsl.segment7) ) )                               -- AFF �\���P
        OR ( xpsl.segment8 <> SUBSTRB( xpsl.segment8_name, 1, LENGTHB(xpsl.segment8) ) )                               -- AFF �\���Q
          )
      ;
-- 2013/06/10 Ver11.5.10.2.12 ADD END
-- Ver11.5.10.2.16 ADD START
    -- �������d�q�f�[�^��̃`�F�b�N
    CURSOR xx03_invoice_ele_data_cur
    IS
      SELECT xps.request_date         AS request_date
            ,xps.orig_invoice_num     AS orig_invoice_num
            ,xps.invoice_ele_data_yes AS invoice_ele_data_yes
            ,xps.invoice_ele_data_no  AS invoice_ele_data_no
            ,xps.slip_type            AS slip_type
      FROM   xx03_payment_slips      xps
      WHERE  xps.org_id     = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND    xps.invoice_id = in_invoice_id
    ;
-- Ver11.5.10.2.16 ADD END
--
    -- *** ���[�J���E���R�[�h ***
    -- �����Ώۃf�[�^�擾�J�[�\�����R�[�h�^
    xx03_xpsjlv_rec            xx03_xpsjlv_cur%ROWTYPE;
    -- ���[�g�J�[�\�����R�[�h�^
    xx03_rate_rec              xx03_rate_cur%ROWTYPE;
-- ver1.5 ADD START
    -- �O���[���`�[�ԍ��擾�J�[�\�����R�[�h�^
    xx03_prepay_get_rec        xx03_prepay_get_cur%ROWTYPE;
    -- �O���[���`�[�ԍ��������`�F�b�N�J�[�\�����R�[�h�^
    xx03_prepay_check_rec      xx03_prepay_check_cur%ROWTYPE;
-- ver1.5 ADD END
    -- �O���[���`�[�ԍ��`�F�b�N�J�[�\�����R�[�h�^
    xx03_prepay_num_rec        xx03_prepay_num_cur%ROWTYPE;
    -- �C�����`�[�ԍ��`�F�b�N�J�[�\�����R�[�h�^
    xx03_orig_num_rec          xx03_orig_num_cur%ROWTYPE;
    -- AP��v���ԃ`�F�b�N�J�[�\�����R�[�h�^
    xx03_ap_period_status_rec  xx03_ap_period_status_cur%ROWTYPE;
    -- GL��v���ԃ`�F�b�N�J�[�\�����R�[�h�^
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;
    -- ���ʃG���[�`�F�b�N���ʎ擾���R�[�h�^
    xx03_errchk_result_rec     xx03_errchk_result_cur%ROWTYPE;
    -- ver 11.5.10.2.2 Add Start
    -- �\����-���F�� �`�F�b�N�J�[�\�����R�[�h�^
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
    -- ver 11.5.10.2.2 Add End
-- 2006/02/15 Ver11.5.10.1.6C Add START
    --���F�҃`�F�b�N�J�[�\�����R�[�h�^
    xx03_approver_rec            xx03_approver_cur%ROWTYPE;
    --�d����ID�`�F�b�N�J�[�\�����R�[�h�^
    xx03_vendor_rec              xx03_vendor_cur%ROWTYPE;
    --�d����T�C�g�`�F�b�N�J�[�\�����R�[�h�^
    xx03_vendor_site_rec         xx03_vendor_site_cur%ROWTYPE;
    --�U��������`�F�b�N�J�[�\�����R�[�h�^
    xx03_bank_name_rec           xx03_bank_name_cur%ROWTYPE;
--
    -- ver 11.5.10.2.10E Add Start
    --�x�����@�擾�J�[�\�����R�[�h�^
    xx03_pay_group_method_rec    xx03_pay_group_method_cur%ROWTYPE;
    -- ver 11.5.10.2.10E Add End
--
    --�ʉ݃`�F�b�N�J�[�\�����R�[�h�^
    xx03_currency_name_rec       xx03_currency_name_cur%ROWTYPE;
    --�x���O���[�v�`�F�b�N�J�[�\�����R�[�h�^
    xx03_pay_group_name_rec      xx03_pay_group_name_cur%ROWTYPE;
    --�x�������`�F�b�N�J�[�\�����R�[�h�^
    xx03_terms_name_rec          xx03_terms_name_cur%ROWTYPE;
    --�K�p�R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    xx03_slip_line_type_name_rec xx03_slip_line_type_name_cur%ROWTYPE;
    --�ŋ��R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    xx03_tax_col_rec             xx03_tax_col_cur%ROWTYPE;
-- 2006/02/15 Ver11.5.10.1.6C Add END
-- 2012/02/15 Ver11.5.10.2.11 ADD START
    -- �ŋ��R�[�h�ύX�`�F�b�N�J�[�\�����R�[�h�^
    xx03_tax_chenge_rec          xx03_tax_chenge_cur%ROWTYPE;
-- 2012/02/15 Ver11.5.10.2.11 ADD END
-- 2013/06/10 Ver11.5.10.2.12 ADD START
    -- �`�F�b�N�J�[�\�����R�[�h�^
    xx03_save_code_chk_rec       xx03_save_code_chk_cur%ROWTYPE;
-- 2013/06/10 Ver11.5.10.2.12 ADD START
-- 11.5.10.2.16 ADD START
    xx03_invoice_ele_data_rec    xx03_invoice_ele_data_cur%ROWTYPE;
-- 11.5.10.2.16 ADD END
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
    -- �����Ώۃf�[�^�擾�J�[�\���I�[�v��
    OPEN xx03_xpsjlv_cur;
    <<xx03_xpsjlv_loop>>
    LOOP
      FETCH xx03_xpsjlv_cur INTO xx03_xpsjlv_rec;
      IF xx03_xpsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          -- 1�����f�[�^���Ȃ��ꍇ
          RAISE NO_DATA_FOUND;
        ELSE
          -- �f�[�^�I��
          EXIT xx03_xpsjlv_loop;
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
-- Ver11.5.10.1.5 2005/09/02 Change Start
--        SELECT xpsv.invoice_currency_code as invoice_currency_code,
--               xpsv.exchange_rate as exchange_rate,
--               xpsv.exchange_rate_type as exchange_rate_type,
--               xpsv.gl_date as gl_date,
--               xpsv.prepay_num as prepay_num,
--               xpsv. orig_invoice_num as orig_invoice_num
--          INTO lv_chk_currency_code,
--               ln_chk_exchange_rate,
--               lv_chk_exchange_rate_type,
--               ld_chk_gl_date,
--               lv_chk_prepay_num,
--               lv_chk_orig_invoice_num
--          FROM xx03_payment_slips_v xpsv
--         WHERE xpsv.invoice_id = in_invoice_id;
        SELECT XPS.INVOICE_CURRENCY_CODE  as invoice_currency_code,
               XPS.EXCHANGE_RATE          as exchange_rate,
               XPS.EXCHANGE_RATE_TYPE     as exchange_rate_type,
               XPS.GL_DATE                as gl_date,
        --2006/02/18 Ver11.5.10.1.6C Add START
               XPS.INVOICE_DATE           as invoice_date,
        --2006/02/18 Ver11.5.10.1.6C Add END
               XPS.PREPAY_NUM             as prepay_num,
               XPS.ORIG_INVOICE_NUM       as orig_invoice_num
        --2006/03/06 Ver11.5.10.1.6E add start
             , XPS.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6E add End
        INTO   lv_chk_currency_code,
               ln_chk_exchange_rate,
               lv_chk_exchange_rate_type,
               ld_chk_gl_date,
        --2006/02/18 Ver11.5.10.1.6C Add START
               ld_chk_invoice_date,
        --2006/02/18 Ver11.5.10.1.6C Add END
               lv_chk_prepay_num,
               lv_chk_orig_invoice_num
        --2006/03/06 Ver11.5.10.1.6E add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6E add End
        FROM   XX03_PAYMENT_SLIPS XPS 
        WHERE  XPS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
          AND  XPS.INVOICE_ID = in_invoice_id
        ;
-- Ver11.5.10.1.5 2005/09/02 Change End
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
-- ver1.5 ADD START
        -- �O���[���`�[�ԍ��`�F�b�N
        OPEN xx03_prepay_get_cur();
        FETCH xx03_prepay_get_cur INTO xx03_prepay_get_rec;
        IF (xx03_prepay_get_rec.prepay_num IS NULL) THEN
          -- �O���`�[�w��Ȃ�
          -- ���ɏ����Ȃ�
          NULL;
        ELSE
          -- �O���`�[�w�肠��
          OPEN xx03_prepay_check_cur();
          FETCH xx03_prepay_check_cur INTO xx03_prepay_check_rec;
          IF xx03_prepay_check_cur%NOTFOUND THEN
            -- ���R�[�h���I������Ȃ�����
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14057');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            -- ���R�[�h���I�����ꂽ
            -- ���ɏ����Ȃ�
            NULL;
          END IF;
          CLOSE xx03_prepay_check_cur;
        END IF;
        CLOSE xx03_prepay_get_cur;
-- ver1.5 ADD END
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- �O���[���`�[�ԍ����͎��̂݃`�F�b�N����
      IF lv_chk_prepay_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- �O���[���`�[�ԍ��`�F�b�N
        OPEN xx03_prepay_num_cur(
          lv_chk_prepay_num  -- 1.�O���[���`�[�ԍ�
        );
        FETCH xx03_prepay_num_cur INTO xx03_prepay_num_rec;
        IF xx03_prepay_num_cur%NOTFOUND THEN
          -- ���R�[�h���I������Ȃ�����
          -- ���ɏ����Ȃ�
          NULL;
        ELSE
          -- ���R�[�h���I�����ꂽ
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14005');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_prepay_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- �C�����`�[�ԍ����͎��̂݃`�F�b�N����
      IF lv_chk_orig_invoice_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- �C�����`�[�ԍ��`�F�b�N
        OPEN xx03_orig_num_cur(
          lv_chk_orig_invoice_num  -- 1.�C�����`�[�ԍ�
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
        -- AP��v���ԃ`�F�b�N
        OPEN xx03_ap_period_status_cur(
          ln_books_id,    -- 1.�C�����`�[�ԍ�
          ld_chk_gl_date  -- 2.GL�L����
        );
        FETCH xx03_ap_period_status_cur INTO xx03_ap_period_status_rec;
        IF xx03_ap_period_status_cur%NOTFOUND THEN
-- 2004/02/19 ADD START
          -- ��v���ԃf�[�^�Ȃ�
          lv_period_data_flg := 'N';
-- 2004/02/19 ADD END
          -- AP��v���Ԗ���`�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14009');
          ln_err_cnt := ln_err_cnt + 1;
        ELSE
-- 2004/02/19 ADD START
          -- ��v���ԃf�[�^����
          lv_period_data_flg := 'Y';
-- 2004/02/19 ADD END
          IF ( xx03_ap_period_status_rec.closing_status != 'O' AND
                 xx03_ap_period_status_rec.closing_status != 'F' ) THEN
            -- AP��v���Ԗ��I�[�v���G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14010');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            -- 'O'�A'F'�̎��͓��ɏ����Ȃ�
            NULL;
          END IF;
        END IF;
        CLOSE xx03_ap_period_status_cur;
--
-- 2004/02/19 ADD START
        -- ��v���ԃf�[�^����̎��̂�
        IF ( lv_period_data_flg = 'Y' ) THEN
          -- GL��v���ԃ`�F�b�N
          OPEN xx03_gl_period_status_cur(
            ln_books_id,    -- 1.�C�����`�[�ԍ�
            ld_chk_gl_date  -- 2.GL�L����
          );
          FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
          IF xx03_gl_period_status_cur%NOTFOUND THEN
            -- GL��v���Ԗ���`�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            IF ( xx03_gl_period_status_rec.attribute1 IS NOT NULL AND
                   xx03_gl_period_status_rec.attribute1 != 'O' ) THEN
              -- GL��v���Ԗ��I�[�v���G���[
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              -- 'O'�ANull�̎��͓��ɏ����Ȃ�
              NULL;
            END IF;
          END IF;
          CLOSE xx03_gl_period_status_cur;
        END IF;
-- 2004/02/19 ADD END
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
-- 2006/02/15 Ver11.5.10.1.6C Add START
-- �w�b�_�[�̃}�X�^�[�`�F�b�N���{
        --2006/03/06 Ver11.5.10.1.6E Change Start
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
        --2006/03/06 Ver11.5.10.1.6E Change End
--
        --�d����ID�`�F�b�N
        OPEN xx03_vendor_cur;
        FETCH xx03_vendor_cur INTO xx03_vendor_rec;
        IF xx03_vendor_rec.exist_check = 0 THEN
          -- �d����ID�`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12504','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_vendor_cur;
--
        --�d����T�C�g�`�F�b�N
        OPEN xx03_vendor_site_cur;
        FETCH xx03_vendor_site_cur INTO xx03_vendor_site_rec;
        IF xx03_vendor_site_rec.exist_check = 0 THEN
          -- �d����T�C�g�`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12505','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_vendor_site_cur;
--
        -- ver 11.5.10.2.10E Del Start
        ----�U��������`�F�b�N
        --OPEN xx03_bank_name_cur;
        --FETCH xx03_bank_name_cur INTO xx03_bank_name_rec;
        ---- ver 11.5.10.2.5 Chg Start
        ----IF xx03_bank_name_rec.exist_check = 0 THEN
        ----  -- �U��������`�F�b�N�G���[
        ----  errflg_tbl(ln_err_cnt) := 'E';
        ----  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        ----  ln_err_cnt := ln_err_cnt + 1;
        ----END IF;
        --
        ---- �U��������擾�G���[
        --IF xx03_bank_name_cur%NOTFOUND THEN
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        ---- �U��������`�F�b�N�G���[(�d�M�̏ꍇ�̂ݐU��������K�{)
        --ELSIF xx03_bank_name_rec.PAYMETHOD = cv_vendor_sites_eft
        --    and xx03_bank_name_rec.NAME is NULL THEN
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        ---- ver 11.5.10.2.5 Chg End
        --CLOSE xx03_bank_name_cur;
        ---- ver 11.5.10.2.10E Del End
--
        -- ver 11.5.10.2.10F Chg Start
        ----�ʉ݃`�F�b�N
        --OPEN xx03_currency_name_cur;
        --FETCH xx03_currency_name_cur INTO xx03_currency_name_rec;
        --IF xx03_currency_name_rec.exist_check = 0 THEN
        --  -- �ʉ݃`�F�b�N�G���[
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        --CLOSE xx03_currency_name_cur;
        --
        --�ʉ݃`�F�b�N(���x�`�F�b�N�p�ɐ��x���擾����悤�ɕύX)
        OPEN xx03_currency_name_cur;
        FETCH xx03_currency_name_cur INTO xx03_currency_name_rec;
        IF (xx03_currency_name_cur%NOTFOUND) THEN
          -- �ʉ݃`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
--
          lb_currency_chk := FALSE;
          ln_currency_precision := 0;
        ELSE
          lb_currency_chk := TRUE;
          ln_currency_precision := xx03_currency_name_rec.PRECISION;
        END IF;
        CLOSE xx03_currency_name_cur;
        -- ver 11.5.10.2.10F Chg End
--
        --�x���O���[�v�`�F�b�N
        OPEN xx03_pay_group_name_cur;
        FETCH xx03_pay_group_name_cur INTO xx03_pay_group_name_rec;
        IF xx03_pay_group_name_rec.exist_check = 0 THEN
          -- �x���O���[�v�`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12506','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_pay_group_name_cur;
--
        -- ver 11.5.10.2.10E Add Start
        -- �x�����@�擾
        OPEN xx03_pay_group_method_cur;
        FETCH xx03_pay_group_method_cur INTO xx03_pay_group_method_rec;
--
        -- �x���O���[�v����x�����@���擾�ł����ꍇ�͐U��������`�F�b�N
        IF xx03_pay_group_method_cur%FOUND THEN
          -- �U��������`�F�b�N�G���[(�d�M�̏ꍇ�̂ݐU��������K�{)
          IF xx03_pay_group_method_rec.PAYMETHOD = cv_vendor_sites_eft THEN
            -- �U��������擾�`�F�b�N
            OPEN xx03_bank_name_cur;
            FETCH xx03_bank_name_cur INTO xx03_bank_name_rec;
            IF xx03_bank_name_cur%NOTFOUND THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12516','SLIP_NUM','');
              ln_err_cnt := ln_err_cnt + 1;
            ELSIF xx03_bank_name_rec.NAME IS NULL THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12516','SLIP_NUM','');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_bank_name_cur;
          END IF;
        END IF;
        CLOSE xx03_pay_group_method_cur;
        -- ver 11.5.10.2.10E Add End
--
        --�x�������`�F�b�N
        OPEN xx03_terms_name_cur;
        FETCH xx03_terms_name_cur INTO xx03_terms_name_rec;
        IF xx03_terms_name_rec.exist_check = 0 THEN
          -- �x�������`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12507','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_terms_name_cur;
--
-- 2006/02/15 Ver11.5.10.1.6C Add END
-- Ver11.5.10.2.16 ADD START
        --�������d�q�f�[�^��̃`�F�b�N
        OPEN xx03_invoice_ele_data_cur;
        FETCH xx03_invoice_ele_data_cur INTO xx03_invoice_ele_data_rec;
        IF ( xx03_invoice_ele_data_rec.slip_type <> cv_slip_type ) THEN
          IF ( xx03_invoice_ele_data_rec.invoice_ele_data_yes = 'Y' 
              AND xx03_invoice_ele_data_rec.invoice_ele_data_no = 'N' )
            OR ( xx03_invoice_ele_data_rec.invoice_ele_data_yes = 'N' 
              AND xx03_invoice_ele_data_rec.invoice_ele_data_no = 'Y' )
            OR ( xx03_invoice_ele_data_rec.request_date IS NOT NULL   )
            OR ( xx03_invoice_ele_data_rec.orig_invoice_num IS NOT NULL   ) THEN
            NULL;
          ELSE
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO', 'APP-XXCFO1-00062');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        CLOSE xx03_invoice_ele_data_cur;
-- Ver11.5.10.2.16 ADD END
--
        -- ������̓G���[�`�F�b�N�ŃG���[���Ȃ������ꍇ�̂݃`�F�b�NID�擾
        IF ( ln_err_cnt <= 0 ) THEN
          --�`�F�b�NID�擾
          SELECT xx03_err_check_s.NEXTVAL
          INTO   ln_check_seq
          FROM   DUAL;
        END IF;
--
        -- 1���ڃt���O�����낷
        lv_first_flg := 'N';
      END IF;
--
-- 2005/01/17 Add start
      -- �t���b�N�X�E�t�B�[���h�̌n�ԍ��̎擾
      SELECT   sob.chart_of_accounts_id
        INTO   ln_structure_number
        FROM   gl_sets_of_books sob
       WHERE   xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID')
                 = sob.set_of_books_id;
--
      -- ���݌��؃��[���`�F�b�N���s(�Ώ� : �w�b�_�[�ȊO)
      IF (xx03_xpsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xpsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xpsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xpsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xpsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xpsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xpsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xpsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xpsjlv_rec.segment8;
--
--2021/04/06 Ver11.5.10.2.15 ADD START
        -- ���Ȗڂ��`�F�b�N
        SELECT  COUNT(1)
          INTO  ln_count
          FROM  fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type = cv_lookup_liabilities_code
           AND  flvv.lookup_code = xx03_xpsjlv_rec.segment3
           AND  flvv.enabled_flag  = cv_yes
           AND  NVL( flvv.start_date_active, TRUNC(SYSDATE) ) <= TRUNC(SYSDATE)
           AND  NVL( flvv.end_date_active,   TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
        ;
        -- ���Ȗڂ̏ꍇ�A����A��ƃR�[�h�A�ڋq�R�[�h�̐������`�F�b�N
        IF (ln_count > 0) THEN
          IF (NVL(xx03_xpsjlv_rec.segment2,cv_z) != cv_dept_fin OR
              NVL(xx03_xpsjlv_rec.segment5,cv_z) != cv_cust_def OR
              NVL(xx03_xpsjlv_rec.segment6,cv_z) != cv_corp_def) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO'    ,'APP-XXCFO1-00061'
                                                              ,'SLIP_NUM' ,''
                                                              ,'TOK_COUNT',xx03_xpsjlv_rec.line_number
                                                              ,'TOK_ACCT_CODE' ,xx03_xpsjlv_rec.segment3
                                                              );
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- �G���[���Ȃ��ꍇCCID�擾
        IF ( ln_err_cnt <= 0 ) THEN
--2021/04/06 Ver11.5.10.2.15 ADD END
          lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                          application_short_name => lv_app_short_name,
                          key_flex_code => lv_key_flex_code,
                          structure_number => ln_structure_number,
          -- 2006/01/30 Ver11.5.10.1.6 Change Start
                          --validation_date => ld_validation_date,
                          validation_date => ld_chk_gl_date,
          -- 2006/01/30 Ver11.5.10.1.6 Change End
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
            errmsg_tbl(ln_err_cnt) := FND_FLEX_EXT.GET_MESSAGE;
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
--2021/04/06 Ver11.5.10.2.15 ADD START
        END IF;
--2021/04/06 Ver11.5.10.2.15 ADD END
--
      END IF; -- xx03_xpsjlv_rec.segment1 IS NOT NULL
-- 2005/05/17 Add end
--
-- 2006/02/15 Ver11.5.10.1.6C add START
-- ���ׂ̃}�X�^�[�l�`�F�b�N�����{����
      --�K�p�R�[�h�`�F�b�N
      --���׍s�̂݃`�F�b�N����
      IF xx03_xpsjlv_rec.line_type_lookup_code = 'ITEM' THEN
        OPEN xx03_slip_line_type_name_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.���הԍ�
          ld_chk_invoice_date             -- 2.���������t
        );
        FETCH xx03_slip_line_type_name_cur INTO xx03_slip_line_type_name_rec;
        IF xx03_slip_line_type_name_rec.exist_check = 0 THEN
          -- �K�p�R�[�h�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12508','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_slip_line_type_name_cur;
--
      -- �ŋ��R�[�h�`�F�b�N
         OPEN xx03_tax_col_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.���הԍ�
          ld_chk_invoice_date             -- 2.���������t
        );
        FETCH xx03_tax_col_cur INTO xx03_tax_col_rec;
        IF xx03_tax_col_rec.exist_check = 0 THEN
          -- �ŋ��R�[�h�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14151','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_tax_col_cur;
-- 2012/02/15 Ver11.5.10.2.11 ADD START
--
         -- �ŋ��R�[�h�ύX�`�F�b�N
         OPEN xx03_tax_chenge_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.���הԍ�
          ld_chk_invoice_date             -- 2.���������t
        );
        FETCH xx03_tax_chenge_cur INTO xx03_tax_chenge_rec;
        --
        -- �E�v�R�[�h�̐ŃR�[�h��NULL�Ȃ�΃`�F�b�N���Ȃ�
        IF xx03_tax_chenge_rec.line_type_tax_code IS NOT NULL THEN
          -- �E�v�R�[�h�̐ŃR�[�h�Ɩ��ׂ̐ŃR�[�h���s��v�̏ꍇ
          IF ( xx03_tax_chenge_rec.line_type_tax_code <> xx03_tax_chenge_rec.input_tax_code ) THEN
            -- �ŋ��R�[�h�ύX�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO'    ,'APP-XXCFO1-00041'
                                                              ,'SLIP_NUM' ,''
                                                              ,'TOK_COUNT',xx03_xpsjlv_rec.line_number
                                                              ,'TAX_CODE' ,xx03_tax_chenge_rec.line_type_tax_name
                                                              );
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        CLOSE xx03_tax_chenge_cur;
--
-- 2012/02/15 Ver11.5.10.2.11 ADD END
-- 2013/06/10 Ver11.5.10.2.12 ADD START
        -- ��ʕ\���l-�o�^�l����G���[�`�F�b�N
        OPEN  xx03_save_code_chk_cur;
        FETCH xx03_save_code_chk_cur INTO xx03_save_code_chk_rec;
        -- ����G���[�`�F�b�N��1���ł����݂���ꍇ
        IF ( xx03_save_code_chk_rec.exist_check <> 0 ) THEN
          -- ���ڑ���G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO'    ,'APP-XXCFO1-00046'
                                                            );
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_save_code_chk_cur;
-- 2013/06/10 Ver11.5.10.2.12 ADD END
--
        -- ver 11.5.10.2.10F Add Start
        -- �ʉ݂����������͂���Ă���ꍇ�̓`�F�b�N
        IF lb_currency_chk = TRUE THEN
          -- �`�[���z�̐��x���擾
          lv_amount := TO_CHAR(xx03_xpsjlv_rec.amount);
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- �`�[���z�̐��x���ʉ݂̐��x�𒴂��Ă���΃G���[
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03','APP-XX03-14167','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- ver 11.5.10.2.10F Add End
--2016/11/14 Ver11.5.10.2.13 ADD START
        IF xx03_xpsjlv_rec.attribute7 IS NOT NULL THEN
          --�g�c���ٔԍ��`���`�F�b�N
          DECLARE
            lv_Request_decision  xx03_payment_slip_lines.attribute7%TYPE;
            ln_Request_decision  NUMBER;
          BEGIN
            --�����`�F�b�N
            IF LENGTHB(xx03_xpsjlv_rec.attribute7) <> 11 THEN
              RAISE INVALID_NUMBER;
            END IF;
            --�Œ�l�`�F�b�N
--2018/02/07 Ver11.5.10.2.14 MOD START
--            IF SUBSTRB(xx03_xpsjlv_rec.attribute7,1,2) <> 'DR' THEN
            IF SUBSTRB(xx03_xpsjlv_rec.attribute7,1,2) NOT IN ('DR','SP') THEN
--2018/02/07 Ver11.5.10.2.14 MOD END
              RAISE INVALID_NUMBER;
            END IF;
            --�N�`�F�b�N
            ln_Request_decision := SUBSTRB(xx03_xpsjlv_rec.attribute7,3,4);
            IF ln_Request_decision < 2000 THEN
              RAISE INVALID_NUMBER;
            END IF;
            -- �A�ԃ`�F�b�N
            lv_Request_decision := SUBSTRB(xx03_xpsjlv_rec.attribute7,7,5);
            -- ���l�^�`�F�b�N
            ln_Request_decision := lv_Request_decision;
            -- �����`�F�b�N
            IF ( INSTR(lv_Request_decision, cv_precision_char) <> 0 ) THEN
              RAISE INVALID_NUMBER;
            END IF;
            -- �����`�F�b�N(��1�������l���ǂ����`�F�b�N)
            ln_Request_decision := SUBSTRB(xx03_xpsjlv_rec.attribute7,7,1);
          EXCEPTION
            WHEN INVALID_NUMBER OR VALUE_ERROR THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO','APP-XXCFO1-00054','TOK_REQUEST_DECISION',xx03_xpsjlv_rec.attribute7);
              ln_err_cnt := ln_err_cnt + 1;
          END;
        END IF;
--2016/11/14 Ver11.5.10.2.13 ADD END
      END IF;
--
-- 2006/02/15 Ver11.5.10.1.6C add END
--
      -- ������̓G���[�`�F�b�N�ŃG���[���������ꍇ�͂��̎��_�Ń��[�v�I��
      IF ( ln_err_cnt > 0 ) THEN
        -- �f�[�^�I��
        EXIT xx03_xpsjlv_loop;
      END IF;
--
      -- �G���[�`�F�b�N�e�[�u����������
      IF ( xx03_xpsjlv_rec.line_number = 0 ) THEN
        -- �w�b�_���R�[�h
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
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.line_number,
          xx03_xpsjlv_rec.gl_date,
          null,
          xx03_xpsjlv_rec.invoice_currency_code,
          xx03_xpsjlv_rec.code_combination_id,
          xx03_xpsjlv_rec.segment1,
          xx03_xpsjlv_rec.segment2,
          xx03_xpsjlv_rec.segment3,
          xx03_xpsjlv_rec.segment4,
          xx03_xpsjlv_rec.segment5,
          xx03_xpsjlv_rec.segment6,
          xx03_xpsjlv_rec.segment7,
          xx03_xpsjlv_rec.segment8,
          null,
          null,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.entry_department,
          xx03_xpsjlv_rec.user_name,
          null,
          null,
          null,
          xx03_xpsjlv_rec.amount,
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
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.line_number,
          xx03_xpsjlv_rec.gl_date,
          null,
          xx03_xpsjlv_rec.invoice_currency_code,
          xx03_xpsjlv_rec.code_combination_id,
          xx03_xpsjlv_rec.segment1,
          xx03_xpsjlv_rec.segment2,
          xx03_xpsjlv_rec.segment3,
          xx03_xpsjlv_rec.segment4,
          xx03_xpsjlv_rec.segment5,
          xx03_xpsjlv_rec.segment6,
          xx03_xpsjlv_rec.segment7,
          xx03_xpsjlv_rec.segment8,
          xx03_xpsjlv_rec.tax_code,
          xx03_xpsjlv_rec.incr_decr_reason_code,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.entry_department,
          xx03_xpsjlv_rec.user_name,
          null,
          xx03_xpsjlv_rec.recon_reference,
          xx03_xpsjlv_rec.amount,
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
    END LOOP xx03_xpsjlv_loop;
    CLOSE xx03_xpsjlv_cur;
--
    -- ������̓G���[�`�F�b�N�ŃG���[���Ȃ������ꍇ�̂݋��ʃG���[�`�F�b�N���s
    IF ( ln_err_cnt <= 0 ) THEN
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
            -- �G���[������20���ȉ��̎��̂݃G���[���Z�b�g
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10C Chg Start
--            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '�F' ||
--                                           xx03_errchk_result_rec.error_message;
            if xx03_errchk_result_rec.line_number = 0 THEN
              lv_je_err_msg := 'APP-XX03-14164';
            elsif (xx03_errchk_result_rec.line_number - TRUNC(xx03_errchk_result_rec.line_number)) = 0.5 THEN
              lv_je_err_msg := 'APP-XX03-14166';
            else
              lv_je_err_msg := 'APP-XX03-14165';
            end if;
            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '�F' ||
                                           xx03_errchk_result_rec.error_message ||
                                           xx00_message_pkg.get_msg('XX03',lv_je_err_msg);
-- ver 11.5.10.2.10C Chg End
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
--
        END LOOP xx03_errchk_result_loop;
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver 11.5.10.1.6D Del Start
      ---- �G���[�`�F�b�N�A�G���[���f�[�^�폜
      --DELETE FROM xx03_error_checks xec
      --      WHERE xec.check_id = ln_check_seq;
      --DELETE FROM xx03_error_info xei
      --      WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6D Del End
    END IF;
--
-- ver 11.5.10.1.6D Add Start
    IF ln_check_seq != 0 THEN
      -- �G���[�`�F�b�N�A�G���[���f�[�^�폜
      DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
    END IF;
-- ver 11.5.10.1.6D Add End
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
      IF xx03_xpsjlv_cur%ISOPEN THEN
        CLOSE xx03_xpsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
-- ver1.5 ADD START
      IF xx03_prepay_get_cur%ISOPEN THEN
        CLOSE xx03_prepay_get_cur;
      END IF;
      IF xx03_prepay_check_cur%ISOPEN THEN
        CLOSE xx03_prepay_check_cur;
      END IF;
-- ver1.5 ADD END
      IF xx03_prepay_num_cur%ISOPEN THEN
        CLOSE xx03_prepay_num_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_ap_period_status_cur%ISOPEN THEN
        CLOSE xx03_ap_period_status_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      IF xx03_errchk_result_cur%ISOPEN THEN
        CLOSE xx03_errchk_result_cur;
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
  END check_deptinput_ap;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : �d�_�Ǘ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_invoice_id IN  NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
    ov_app_upd    OUT VARCHAR2,  -- 2.�d�_�Ǘ��X�V���e
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.set_account_approval_flag'; -- �v���O������
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
    ln_head_acc_amount NUMBER;  -- �w�b�_���Z�z
    lv_slip_type VARCHAR2(25);  -- �w�b�_�`�[���
    lv_detail_first_flg VARCHAR2(1);  -- �z���Ǎ�1���ڃt���O
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
    -- �������z�����擾�J�[�\��
    CURSOR xx03_detail_info_cur
    IS
      SELECT xav.attribute7 as attribute7
        FROM xx03_payment_slip_lines xpsl,
             xx03_accounts_v xav
       WHERE xpsl.invoice_id = in_invoice_id
         AND xpsl.segment3 = xav.flex_value;
--
    -- *** ���[�J���E���R�[�h ***
    -- �`�[��ʃ}�X�^���擾�J�[�\�����R�[�h�^
    xx03_slip_type_rec       xx03_slip_type_cur%ROWTYPE;
    -- �������z�����擾�J�[�\�����R�[�h�^
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
    -- �������w�b�_���R�[�h�擾
-- Ver1.6 Update Start
--    SELECT ABS(xps.inv_accounted_amount) as inv_accounted_amount,
    SELECT ABS(
             ROUND((xps.inv_item_amount + xps.inv_tax_amount) * NVL(xps.exchange_rate, 1))
           ) as inv_accounted_amount,
-- Ver1.6 Update End
           xps.slip_type as slip_type
      INTO ln_head_acc_amount,
           lv_slip_type
      FROM xx03_payment_slips xps
     WHERE xps.invoice_id = in_invoice_id;
--
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
    -- �������z�����R�[�h�擾
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
   * Procedure Name   : get_terms_date
   * Description      : �x���N�Z���̎Z�o
   ***********************************************************************************/
  PROCEDURE get_terms_date(
    in_terms_id   IN  NUMBER,    -- 1.�x������
    id_start_date IN  DATE,      -- 2.�x���N�Z��
    id_terms_date IN  DATE,      -- 3.�x���\���
    od_terms_date OUT DATE,      -- 4.�x���\���
    ov_terms_flg  OUT VARCHAR2,  -- 5.�ύX�\�t���O
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.get_terms_date'; -- �v���O������
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
    ln_sequence_num NUMBER;     -- �V�[�P���X
    lv_calendar VARCHAR2(30);   -- ���ʃJ�����_�[
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
    -- �ύX�\�t���O�擾
    SELECT at.attribute1
      INTO ov_terms_flg
      FROM ap_terms_v at
     WHERE at.term_id = in_terms_id;
--
   -- �ύX�\�t���O'Y'�ŁAid_terms_date�ɂȂ�炩�̒l�������Ă����ꍇ��
   -- id_terms_date�̒l��od_terms_date�ɃZ�b�g����RETURN
   IF ( ov_terms_flg = 'Y' AND id_terms_date IS NOT NULL ) THEN
     od_terms_date := id_terms_date;
     RETURN;
   END IF;
--
   -- AP���ԏ��擾
   SELECT atl.sequence_num as sequence_num,
          atl.calendar as calendar
     INTO ln_sequence_num,
          lv_calendar
     FROM ap_terms_lines atl
    WHERE atl.term_id = in_terms_id
      AND rownum = 1
   ORDER BY atl.sequence_num;
--
  IF ( lv_calendar IS NOT NULL ) THEN
    -- ���ʃJ�����_�[���w�肳��Ă����ꍇ�́A���ʃJ�����_�[����x���\������擾
    BEGIN
      SELECT aop.due_date
        INTO od_terms_date
        FROM ap_other_periods aop
       WHERE aop.period_type = lv_calendar
         AND aop.module = 'PAYMENT TERMS'
         AND trunc(id_start_date) between aop.start_date and aop.end_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                --*** �Ώۃf�[�^�Ȃ� ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14008');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14008');
      ov_errmsg := lv_errmsg;                                                           --# �C�� #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# �C�� #
    END;
  ELSE
    -- ���ʃJ�����_�[���w�肳��Ă��Ȃ������ꍇ�́A���W�b�N�Ŏx���\������擾
-- Var1.3 CHANGE START
    SELECT NVL(ATL.FIXED_DATE,
             (DECODE(ATL.DUE_DAYS,
             NULL, TO_DATE(TO_CHAR(ADD_MONTHS(id_start_date,
                 NVL(ATL.DUE_MONTHS_FORWARD, 0) +
                   DECODE(AT.DUE_CUTOFF_DAY, NULL, 0,
              DECODE(GREATEST(LEAST(NVL(AT.DUE_CUTOFF_DAY, 32),
                 TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                    TO_NUMBER(TO_CHAR(id_start_date, 'DD')), 1, 0))),
                       'RRRR/MM') || '/' ||
              TO_CHAR(LEAST(NVL(ATL.DUE_DAY_OF_MONTH, 32),
               TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_start_date,
                 NVL(ATL.DUE_MONTHS_FORWARD, 0) +
               DECODE(AT.DUE_CUTOFF_DAY, NULL, 0,
               DECODE(GREATEST(LEAST(NVL(AT.DUE_CUTOFF_DAY, 32),
                 TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))
                 , 1, 0)))), 'DD'))))
              -- ver 11.5.10.2.10G Chg Start
              --),
              ,'yyyy/mm/dd'),
              -- ver 11.5.10.2.10G Chg End
              id_start_date + NVL(ATL.DUE_DAYS, 0))))
-- Var1.3 CHANGE END
      INTO od_terms_date
      FROM AP_TERMS_V AT,
           AP_TERMS_LINES ATL
     WHERE AT.TERM_ID = in_terms_id
       AND AT.TERM_ID = ATL.TERM_ID
       AND ATL.SEQUENCE_NUM = ln_sequence_num;
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
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_terms_date;
--
-- Var1.4 ADD START
  /**********************************************************************************
   * Procedure Name   : del_pay_data
   * Description      : �x���`�[���R�[�h�̍폜
   ***********************************************************************************/
  PROCEDURE del_pay_data(
    in_invoice_id IN  NUMBER,    -- 1.�폜�Ώې�����ID
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --�����g�����U�N�V������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.del_pay_data'; -- �v���O������
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
    -- 2005-01-22 ADD START (v1.8)
    cn_wf_status_save CONSTANT xx03_payment_slips.wf_status%TYPE   := '00';
    cn_delete_yes     CONSTANT xx03_payment_slips.delete_flag%TYPE := 'Y';
    -- 2005-01-22 ADD END
--
    -- *** ���[�J���ϐ� ***
--
    -- 2005-01-22 ADD START(v.18)
    lv_wf_status        xx03_payment_slips.wf_status%TYPE;
    -- 2005-01-22 ADD END
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
    -- 2005-01-22 ADD START(v.18)
    -- WF�X�e�[�^�X���擾
    SELECT xps.wf_status
    INTO   lv_wf_status
    FROM   xx03_payment_slips xps
    WHERE  xps.invoice_id = in_invoice_id;
    -- 2005-01-22 ADD END
--
    -- 2005-01-22 ADD START(v.18)
    -- �ۑ��`�[�͕����폜���s��
    IF lv_wf_status = cn_wf_status_save THEN
    -- 2005-01-22 ADD END
--
      -- �x���`�[���׃��R�[�h�폜
      DELETE FROM xx03_payment_slip_lines xpsl
      WHERE xpsl.invoice_id = in_invoice_id;
--
      -- �x���`�[�w�b�_���R�[�h�폜
      DELETE FROM xx03_payment_slips xps
      WHERE xps.invoice_id = in_invoice_id;
--
    -- 2005-01-22 ADD START(v.18)
    -- �ۑ��ȊO�̏ꍇ�͘_���폜���s��
    ELSE
        -- �d��`�[�w�b�_���R�[�h�X�V
        UPDATE xx03_payment_slips
        SET    delete_flag = cn_delete_yes
        WHERE  invoice_id = in_invoice_id;
    END IF;
    -- 2005-01-22 ADD END
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
  END del_pay_data;
-- Var1.4 ADD END
--
-- ver11.5.10.1.6B Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ap_input
   * Description      : �������(AP)�̃G���[�`�F�b�N(��ʗp)
   ***********************************************************************************/
  PROCEDURE check_deptinput_ap_input(
    in_invoice_id    IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
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
      'xx03_deptinput_ar_check_pkg.check_deptinput_ar_input'; -- �v���O������
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
    xx03_deptinput_ap_check_pkg.check_deptinput_ap(
      in_invoice_id,
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
      UPDATE xx03_payment_slips xps
      SET    xps.request_enable_flag = 'W'
      WHERE  xps.invoice_id = in_invoice_id;
    ELSE
      -- �x���ȊO�̏ꍇ�͐\���\�t���O��'Y'�Z�b�g
      UPDATE xx03_payment_slips xps
      SET    xps.request_enable_flag = 'Y'
      WHERE  xps.invoice_id = in_invoice_id;
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
  END check_deptinput_ap_input;
-- ver11.5.10.1.6B Add End
--
END xx03_deptinput_ap_check_pkg;
/
