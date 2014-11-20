create or replace PACKAGE BODY      xx03_deptinput_ar_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ar_check_pkg(body)
 * Description            : �������(AR)�ɂ����ē��̓`�F�b�N���s�����ʊ֐�
 * MD.070                 : �������(AR)���ʊ֐� OCSJ/BFAFIN/MD070/F702
 * Version                : 11.5.10.2.10D
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ar          P          �������(AR)�̃G���[�i�d��j�`�F�b�N
 *  set_account_approval_flag   P          �d�_�Ǘ��`�F�b�N
 *  get_terms_date              P          �����\����̎Z�o
 *  del_receivable_data         P          �����˗��`�[���R�[�h�̍폜
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2005/01/25   1.0            �V�K�쐬
 *  2005/09/02   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/06   11.5.10.1.5B   �ڋq���Ə��Ɏ��Ə����x���̊���Ȗڂƃv���t�@�C����
 *                              ���݂��邩���`�F�b�N���鏈����ǉ�
 *  2005/10/18   11.5.10.1.5C   ����`�[���ēx�\���ł��Ă��܂��s��Ή�
 *  2005/11/04   11.5.10.1.6    �����\����Z�o���W�b�N�̕s�����C��
 *  2005/11/04   11.5.10.1.6B   �O����̑��݃`�F�b�N�s��C��
 *  2006/01/30   11.5.10.1.6C   ���݌��؃��[���̃`�F�b�N�ŁA���t��GL�v�����n���悤�ύX
 *  2006/02/15   11.5.10.1.6D   �_�u���N���b�N�Ή�,PKG��commit����PROCEDURE�ǉ�
 *  2006/02/15   11.5.10.1.6E   �}�X�^�[���݃`�F�b�N�����{����悤�ɕύX
 *  2006/03/02   11.5.10.1.6F   �G���[�`�F�b�N�e�[�u���̃N���A���W�b�N�̕s�
 *  2006/03/03   11.5.10.1.6G   ������`�[�̏ꍇ�`�[��ʃ`�F�b�N���~�߂�
 *  2006/03/03   11.5.10.1.6H   ���F�҂̏��F�����`�F�b�N�s��C��
 *  2006/03/29   11.5.10.2.1    HR�Ή��i�]�ƈ��������R�[�h�Ή��j
 *  2006/04/07   11.5.10.2.2    ���F�҂��Ώۓ`�[�ɑ΂��鏳�F���������邩�̃`�F�b�N�ǉ�
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2�ł̏C���~�X�Ή�
 *  2006/06/22   11.5.10.2.3    �}�X�^�`�F�b�N�pSQL�Ńf�[�^���擾�łȂ���������
 *                              �G���[����������Ă��邱�Ƃ̏C��
 *  2006/10/03   11.5.10.2.6    �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                              �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2007/08/10   11.5.10.2.10   �d��z���`�F�b�N�ŃG���[�̎��̃��b�Z�[�W��
 *                              �w�b�_����ץ�ŋ��̂ǂ̔z������\������悤�ɏC��
 *  2007/08/16   11.5.10.2.10B  ��s�x�X�̖������͑O���܂ŗL���Ƃ���悤�ɏC��
 *  2007/08/28   11.5.10.2.10C  AR�ʉݗL�����̔�r�Ώۂ͐��������t�Ƃ���C��
 *  2007/10/29   11.5.10.2.10D  �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ�
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ar
   * Description      : �������(AR)�̃G���[�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_deptinput_ar(
    in_receivable_id IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
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
      'xx03_deptinput_ar_check_pkg.check_deptinput_ar'; -- �v���O������
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
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;    -- �G���[�t���O�p�z��^�C�v
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- �G���[���b�Z�[�W�p�z��^�C�v
    errflg_tbl                errflg_tbl_type;
    errmsg_tbl                errmsg_tbl_type;
    ln_err_cnt                NUMBER := 0;         -- �p�����[�^�Y���p�ϐ�
    ln_books_id               NUMBER;              -- ����ID
    lv_first_flg              VARCHAR2(1) := 'Y';  -- 1���ڂ̃��R�[�h���ۂ�
-- ver 11.5.10.1.6F Chg Start
    --ln_check_seq              NUMBER;              -- �G���[�`�F�b�N�V�[�P���X�ԍ�
    ln_check_seq              NUMBER := 0;         -- �G���[�`�F�b�N�V�[�P���X�ԍ�
-- ver 11.5.10.1.6F Chg End
    ln_cnt                    NUMBER;              -- ���[�v�J�E���^
    lv_err_status             VARCHAR2(1);         -- ���ʃG���[�`�F�b�N�X�e�[�^�X
    lv_currency_code          VARCHAR2(15);        -- �@�\�ʉ݃R�[�h
    lv_chk_currency_code      VARCHAR2(15);        -- �`�F�b�N�p�f�[�^�ʉ݃R�[�h
    ln_chk_exchange_rate      NUMBER;              -- �`�F�b�N�p�f�[�^���Z���[�g
    lv_chk_exchange_rate_type VARCHAR2(30);        -- �`�F�b�N�p�f�[�^���Z���[�g�^�C�v
    ld_chk_gl_date            DATE;                -- �`�F�b�N�p�f�[�^�v���
    lv_chk_prerec_num         VARCHAR2(50);        -- �`�F�b�N�p�f�[�^�O��[���`�[�ԍ�
    lv_chk_orig_invoice_num   VARCHAR2(150);       -- �`�F�b�N�p�f�[�^�C�����`�[�ԍ�
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    ln_chk_customer_office_id NUMBER;              -- �`�F�b�N�p�f�[�^�ڋq���Ə�ID
    -- Ver11.5.10.1.5B 2005/10/06 Add End
    lv_period_data_flg        VARCHAR2(1);         -- ��v���ԃf�[�^�L���t���O
    --2006/02/18 Ver11.5.10.1.6E Add START
    ld_chk_invoice_date       DATE;                -- �`�F�b�N�p�f�[�^���������t
    ld_chk_receipt_method_id  NUMBER;              -- �`�F�b�N�p�f�[�^�x�����@
    ld_slip_line_uom          VARCHAR2(25);         -- �`�F�b�N�p�f�[�^�P��
    --2006/02/18 Ver11.5.10.1.6E Add END
    -- 2006/03/06 Ver11.5.10.1.6H Add Start
    ld_wf_status              VARCHAR2(25);        -- �`�F�b�N�p���[�N�t���[�X�e�[�^�X
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- ������͏��F�҂��X�e�[�^�X
    -- 2006/03/06 Ver11.5.10.1.6H Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- ������͕ۑ��X�e�[�^�X
    cn_wf_status_last   VARCHAR2(25) := '30';      -- ������͍ŏI���右�F�҂��X�e�[�^�X
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.10 Add Start
    lv_je_err_msg       VARCHAR2(14);              -- �z���`�F�b�N�G���[���̒ǉ����b�Z�[�W�R�[�h
    -- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.10D Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- �ʉ݃G���[OK/NG�t���O(���x�`�F�b�N���Ɏg�p)
    ln_currency_precision  NUMBER(1)    := 0;      -- �ʉ݂̐��x(�ʉ݃`�F�b�NOK���ɐ��x���擾)
    lv_amount              VARCHAR2(50) := '';     -- �`�[�ł̋��z���x�擾�p
    ln_amount_precision    NUMBER(1)    := 0;      -- �`�[�ł̋��z�̐��x
    cv_precision_char      VARCHAR2(1)  := '.';    -- �����_�L��
    -- ver 11.5.10.2.10D Add End
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����Ώۃf�[�^�擾�J�[�\��
    CURSOR xx03_xrsjlv_cur
    IS
      SELECT xrsjlv.receivable_num        as receivable_num             -- �`�[�ԍ�
           , xrsjlv.line_number           as line_number                -- No
           , xrsjlv.gl_date               as gl_date                    -- �v���
           , xrsjlv.invoice_currency_code as invoice_currency_code      -- �ʉ݃R�[�h
           , xrsjlv.code_combination_id   as code_combination_id        -- �R�[�h�R���r�l�[�V����ID
           , xrsjlv.segment1              as segment1                   --
           , xrsjlv.segment2              as segment2                   --
           , xrsjlv.segment3              as segment3                   --
           , xrsjlv.segment4              as segment4                   --
           , xrsjlv.segment5              as segment5                   --
           , xrsjlv.segment6              as segment6                   --
           , xrsjlv.segment7              as segment7                   --
           , xrsjlv.segment8              as segment8                   --
           , xrsjlv.tax_code              as tax_code                   -- �ŋ敪ID
           , xrsjlv.incr_decr_reason_code as incr_decr_reason_code      -- �������R�R�[�h
           , xrsjlv.entry_department      as entry_department           -- �N�[����
           , xrsjlv.user_name             as user_name                  -- ���[�U�[��
           , xrsjlv.recon_reference       as recon_reference            -- �����Q��
           , xrsjlv.amount                as amount                     -- ���z
      --2006/02/16 Ver11.5.10.1.6E add START
           , xrsjlv.line_type_lookup_code as line_type_lookup_code      -- ���b�N�A�b�v�R�[�h
      --2006/02/16 Ver11.5.10.1.6E add END
        FROM XX03_REC_SLIP_JOURNAL_LINES_V   xrsjlv
       WHERE xrsjlv.RECEIVABLE_ID = in_receivable_id                    -- �`�[ID
       ORDER BY xrsjlv.line_number;
--
    -- ���[�g�J�[�\��
    CURSOR xx03_rate_cur(
      iv_invoice_currency_code IN VARCHAR2,                             -- 1.�ʉ݃R�[�h
      iv_exchange_rate_type    IN VARCHAR2,                             -- 2.���[�g�^�C�v
      id_gl_date               IN DATE                                  -- 3.GL�L����
    ) IS
      SELECT xgdr.conversion_rate as conversion_rate                    -- ���[�g
        FROM xx03_gl_daily_rates_v   xgdr
       WHERE xgdr.from_currency   = iv_invoice_currency_code            -- �ʉ݃R�[�h
         AND xgdr.conversion_type = iv_exchange_rate_type               -- ���[�g�^�C�v
         AND xgdr.conversion_date = TRUNC(id_gl_date);                  -- ���Z��
--
    -- �O��[���`�[�ԍ��擾�`�F�b�N�J�[�\��
    CURSOR xx03_prerec_get_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xrsv.COMMITMENT_NUMBER as COMMITMENT_NUMBER                -- �O��[���`�[�ԍ�
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.RECEIVABLE_ID = RECEIVABLE_ID;                        -- �`�[ID
      SELECT xrs.COMMITMENT_NUMBER as COMMITMENT_NUMBER                 -- �O��[���`�[�ԍ�
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.RECEIVABLE_ID = in_receivable_id;                      -- �`�[ID
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- �O��[���`�[�ԍ��������`�F�b�N�J�[�\��
    CURSOR xx03_prerec_check_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xrsv.RECEIVABLE_ID                                         -- �`�[ID
--        FROM XX03_RECEIVABLE_SLIPS_V      xrsv,
--             XX03_COMMITMENT_NUMBER_LOV_V xcnlv
--       WHERE xrsv.RECEIVABLE_ID         = in_receivable_id              -- �`�[ID
--         AND xrsv.COMMITMENT_NUMBER     = xcnlv.TRX_NUMBER              -- �O��[���`�[�ԍ�
--         AND xrsv.CUSTOMER_ID           = xcnlv.CUSTOMER_NUMBER         -- �ڋqID
--         AND xrsv.INVOICE_CURRENCY_CODE = xcnlv.CURRENCY;               -- �ʉ݃R�[�h
      SELECT xrs.RECEIVABLE_ID                                          -- �`�[ID
        FROM XX03_RECEIVABLE_SLIPS        xrs,
             XX03_COMMITMENT_NUMBER_LOV_V xcnlv
       WHERE xrs.RECEIVABLE_ID         = in_receivable_id               -- �`�[ID
         AND xrs.COMMITMENT_NUMBER     = xcnlv.TRX_NUMBER               -- �O��[���`�[�ԍ�
-- Ver11.5.10.1.6B Chg Start
--         AND xrs.CUSTOMER_ID           = xcnlv.CUSTOMER_NUMBER          -- �ڋqID
         AND xrs.CUSTOMER_ID           = xcnlv.CUST_ACCOUNT_ID          -- �ڋqID
-- Ver11.5.10.1.6B Chg End
         AND xrs.INVOICE_CURRENCY_CODE = xcnlv.CURRENCY;                -- �ʉ݃R�[�h
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- �O��[���`�[�ԍ��`�F�b�N�J�[�\��
    CURSOR xx03_prerec_num_cur(
      iv_prerec_num IN VARCHAR2 -- 1.�O��[���`�[�ԍ�
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.AR_FORWARD_DATE   IS NULL                              -- AR�]����
--         AND xrsv.COMMITMENT_NUMBER =  iv_prerec_num                     -- �O��[���`�[�ԍ�
--         AND xrsv.wf_status         >= 20                                -- WF�X�e�[�^�X
--         AND xrsv.RECEIVABLE_ID     != in_receivable_id;                 -- �`�[ID
      SELECT *
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.AR_FORWARD_DATE   IS NULL                              -- AR�]����
         AND xrs.COMMITMENT_NUMBER =  iv_prerec_num                     -- �O��[���`�[�ԍ�
         AND xrs.wf_status         >= 20                                -- WF�X�e�[�^�X
         AND xrs.RECEIVABLE_ID     != in_receivable_id                  -- �`�[ID
         AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- �C�����`�[�ԍ��`�F�b�N�J�[�\��
    CURSOR xx03_orig_num_cur(
      iv_orig_invoice_num  IN VARCHAR2 -- 1.�C�����`�[�ԍ�
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.AR_FORWARD_DATE  IS NULL
--         AND xrsv.orig_invoice_num =  iv_orig_invoice_num               -- �C�����`�[�ԍ�
--         AND xrsv.wf_status        >= 20                                -- WF�X�e�[�^�X
--         AND xrsv.RECEIVABLE_ID    != in_receivable_id;                 -- �`�[ID
      -- Ver11.5.10.1.5C 2005/10/18 Change Start
      --SELECT *
      --  FROM XX03_RECEIVABLE_SLIPS xrs
      -- WHERE xrs.AR_FORWARD_DATE  IS NULL
      --   AND xrs.orig_invoice_num =  iv_orig_invoice_num                -- �C�����`�[�ԍ�
      --   AND xrs.wf_status        >= 20                                 -- WF�X�e�[�^�X
      --   AND xrs.RECEIVABLE_ID    != in_receivable_id                   -- �`�[ID
      --   AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.orig_invoice_num =  iv_orig_invoice_num                -- �C�����`�[�ԍ�
         AND xrs.wf_status        >= 20                                 -- WF�X�e�[�^�X
         AND xrs.RECEIVABLE_ID    != in_receivable_id                   -- �`�[ID
         AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5C 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- AR��v���ԃ`�F�b�N�J�[�\��
    CURSOR xx03_ar_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.����ID
      id_gl_date    IN DATE       -- 2.GL�L����
    ) IS
      SELECT gps.closing_status as closing_status
        FROM gl_period_statuses gps
       WHERE gps.application_id         =  xx03_application_pkg.get_application_id_f('AR')
         AND gps.set_of_books_id        =  in_books_id
         AND gps.start_date             <= TRUNC(id_gl_date)
         AND gps.end_date               >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag =  'N';
--
    -- GL��v���ԃ`�F�b�N�J�[�\��
    CURSOR xx03_gl_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.����ID
      id_gl_date    IN DATE       -- 2.GL�L����
    ) IS
      SELECT gps.attribute4 as attribute4
        FROM gl_period_statuses gps
       WHERE gps.application_id         = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id        =  in_books_id
         AND gps.start_date             <= TRUNC(id_gl_date)
         AND gps.end_date               >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag =  'N';
--
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    -- �ڋq���Ə��̐�����T�C�g���x���̊���Ȗڑ��݃`�F�b�N�J�[�\��
    CURSOR xx03_site_accounts_cur(
      ln_chk_customer_office_id   IN NUMBER    -- 1.�ڋq���Ə�ID
    ) IS
      SELECT hsuv.gl_id_rec
        FROM hz_cust_site_uses_all hsuv,
             gl_code_combinations gcc
       WHERE hsuv.gl_id_rec             = gcc.code_combination_id
         AND hsuv.cust_acct_site_id     = ln_chk_customer_office_id
         AND hsuv.status                = 'A'
         AND hsuv.site_use_code         = 'BILL_TO';
--
    -- �ڋq���Ə��̌ڋq���ݒn���x���̃v���t�@�C�����݃`�F�b�N�J�[�\��
    CURSOR xx03_site_profile_cur(
      ln_chk_customer_office_id   IN NUMBER    -- 1.�ڋq���Ə�ID
    ) IS
      SELECT hsuv.site_use_id
        FROM hz_cust_site_uses_all hsuv,
             ar_customer_profiles_v acpv
       WHERE hsuv.site_use_id           = acpv.site_use_id
         AND hsuv.cust_acct_site_id     = ln_chk_customer_office_id
         AND hsuv.status                = 'A'
         AND hsuv.site_use_code         = 'BILL_TO';
    -- Ver11.5.10.1.5B 2005/10/06 Add End
--
-- ver 11.5.10.2.2 add Start
    -- �\���҂Ə��F�҂̊֌W �`�F�b�N�J�[�\��
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_RECEIVABLE_SLIPS       XRS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XRS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XRS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'AR'   )
      AND  XAPV.PERSON_ID   = XRS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--2006/02/15 Ver11.5.10.1.6E add start
--�e�}�X�^�[���݃`�F�b�N
--
    --���F�҃`�F�b�N�J�[�\��
    CURSOR xx03_approver_cur
    IS
-- 2006/03/03 Ver11.5.10.1.6H Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_receivable_slips xrs
--     WHERE XRS.RECEIVABLE_ID = in_receivable_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xrs.approver_person_id;
--
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
                           ,XX03_RECEIVABLE_SLIPS       XRS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XRS.RECEIVABLE_ID = in_receivable_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XRS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XRS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'AR'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/03 Ver11.5.10.1.6H Change END
    --�ڋq�`�F�b�N�J�[�\��
    CURSOR xx03_customer_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   HZ_CUST_ACCOUNTS RAA_BILL
          ,XX03_RECEIVABLE_SLIPS XRS
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  RAA_BILL.STATUS = 'A'
      AND  RAA_BILL.CUST_ACCOUNT_ID  = XRS.CUSTOMER_ID;

--
    --�ڋq���Ə��`�F�b�N�J�[�\��
    CURSOR xx03_cust_office_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,AR_ADDRESSES_V         aav
          ,HZ_CUST_SITE_USES_ALL  hsuv
          ,HZ_CUST_ACCOUNTS       hca
          ,HZ_CUST_ACCT_SITES     hcas
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  hca.CUST_ACCOUNT_ID = aav.CUSTOMER_ID
      AND  aav.ADDRESS_ID = hsuv.CUST_ACCT_SITE_ID
      AND  aav.ADDRESS_ID = hcas.CUST_ACCT_SITE_ID
      AND  hca.STATUS         = 'A'
      AND  hsuv.STATUS        = 'A'
      AND  hsuv.SITE_USE_CODE = 'BILL_TO'
      AND  aav.ADDRESS_ID     = XRS.CUSTOMER_OFFICE_ID
      AND  aav.CUSTOMER_ID    = XRS.CUSTOMER_ID;
--
    -- ver 11.5.10.2.10D Chg Start
    ----�ʉ݃`�F�b�N
    --CURSOR xx03_currency_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   XX03_RECEIVABLE_SLIPS XRS
    --      ,FND_CURRENCIES        FC
    --WHERE  XRS.RECEIVABLE_ID = in_receivable_id
    --  AND  FC.ENABLED_FLAG  = 'Y'
    --  AND  FC.CURRENCY_FLAG = 'Y'
    --  AND  FC.CURRENCY_CODE = XRS.INVOICE_CURRENCY_CODE
    --  -- ver 11.5.10.2.6 Chg Start
    --  --AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.10C Chg Start
    --  --AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                        AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                            AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.10C Chg End
    --  -- ver 11.5.10.2.6 Chg End
    --
    --�ʉ݃`�F�b�N(���x�`�F�b�N�p�ɐ��x���擾����悤�ɕύX)
    CURSOR xx03_currency_name_cur
    IS
    SELECT FC.CURRENCY_CODE      CURRENCY_CODE
          ,NVL(FC.PRECISION , 0) PRECISION
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,FND_CURRENCIES        FC
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  FC.ENABLED_FLAG  = 'Y'
      AND  FC.CURRENCY_FLAG = 'Y'
      AND  FC.CURRENCY_CODE = XRS.INVOICE_CURRENCY_CODE
      AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10D Chg End
--
    --�x�����@�`�F�b�N
    CURSOR xx03_receipt_method_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,XX03_RECEIPT_METHOD_LOV_V xrmlv
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
       AND xrmlv.BATCH_SOURCE_ID = XRS.RECEIPT_METHOD_ID
       AND xrmlv.ADDRESS_ID      = XRS.CUSTOMER_OFFICE_ID
       AND xrmlv.CURRENCY_CODE   = XRS.INVOICE_CURRENCY_CODE
       -- ver 11.5.10.2.6 Chg Start
       --AND XRS.INVOICE_DATE BETWEEN xrmlv.REC_START_DATE
       --                     AND nvl(xrmlv.REC_END_DATE  ,TO_DATE('4712/12/31','YYYY/MM/DD'))
       --AND XRS.INVOICE_DATE BETWEEN xrmlv.CUST_START_DATE
       --                     AND nvl(xrmlv.CUST_END_DATE ,TO_DATE('4712/12/31','YYYY/MM/DD'));
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.REC_END_DATE    ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.CUST_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.ARMA_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE <  nvl(xrmlv.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       -- ver 11.5.10.2.10B Chg Start
       --AND XRS.INVOICE_DATE <= nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'));
       -- ver 11.5.10.2.10C Chg Start
       --AND XRS.INVOICE_DATE < nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'));
       AND XRS.INVOICE_DATE < nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.CURRENCY_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.CURRENCY_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       ;
       -- ver 11.5.10.2.10C Chg End
       -- ver 11.5.10.2.10B Chg End
       -- ver 11.5.10.2.6 Chg End
--
    --�x�������`�F�b�N
    CURSOR xx03_terms_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS xrs
          ,RA_TERMS_TL rtt
          ,RA_TERMS_B  rtb
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  rtt.TERM_ID = rtb.TERM_ID
      AND  rtt.LANGUAGE = USERENV('LANG')
      AND  rtt.TERM_ID  = xrs.TERMS_ID
      AND  xrs.INVOICE_DATE BETWEEN rtb.START_DATE_ACTIVE
                            AND NVL(rtb.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
    --����^�C�v�`�F�b�N
    CURSOR xx03_trans_type_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,RA_CUST_TRX_TYPES_ALL RCT
          ,FND_LOOKUP_VALUES     FVL
    WHERE  xrs.RECEIVABLE_ID = in_receivable_id
      AND  RCT.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID')
      AND  RCT.ORG_ID          = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  FVL.LOOKUP_TYPE     = 'XX03_SLIP_TYPES'
      AND  FVL.LANGUAGE        = XX00_GLOBAL_PKG.CURRENT_LANGUAGE
      AND  FVL.ATTRIBUTE15     = RCT.ORG_ID
      AND  FVL.ATTRIBUTE12     = RCT.TYPE
      AND  RCT.CUST_TRX_TYPE_ID = XRS.TRANS_TYPE_ID
      AND  XRS.INVOICE_DATE BETWEEN RCT.START_DATE
                            AND NVL(RCT.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  FVL.LOOKUP_CODE     = XRS.SLIP_TYPE;
--
    --�P�ʃ`�F�b�N
    -- ver 11.5.10.2.6 Chg Start
    --CURSOR xx03_uom_code_cur(
    --  in_line_number IN number    -- 1.���הԍ�
    -- ,id_invoice_date IN date     -- 2.���������t
    --) IS
    CURSOR xx03_uom_code_cur(
      in_line_number IN number    -- 1.���הԍ�
    ) IS
    -- ver 11.5.10.2.6 Chg End
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS_LINE XRSL
          ,MTL_UNITS_OF_MEASURE_VL    MUM
    WHERE  XRSL.RECEIVABLE_ID = in_receivable_id
      AND  XRSL.LINE_NUMBER =  in_line_number
      AND  MUM.UOM_CODE = XRSL.SLIP_LINE_UOM
      -- ver 11.5.10.2.6 Chg Start
      --AND  id_invoice_date < NVL(MUM.DISABLE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(MUM.DISABLE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.6 Chg End
--
    --�ŋ��R�[�h�`�F�b�N
    CURSOR xx03_tax_col_cur(
      in_line_number IN number    -- 1.���הԍ�
     ,id_invoice_date IN date     -- 2.���������t
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS      XRS
          ,XX03_RECEIVABLE_SLIPS_LINE XRSL
          ,XX03_TAX_CLASS_LOV_V       XTCLV
    WHERE  XRSL.RECEIVABLE_ID = in_receivable_id
      AND  XRSL.LINE_NUMBER =  in_line_number
      AND  XTCLV.TAX_CODE = XRSL.TAX_CODE
      AND  id_invoice_date BETWEEN NVL(XTCLV.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                               AND NVL(XTCLV.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
--2006/02/15 Ver11.5.10.1.6E add End
--
    -- ���ʃG���[�`�F�b�N���ʎ擾�J�[�\��
    CURSOR xx03_errchk_result_cur
    IS
      SELECT xei.journal_id    as journal_id,
             xei.line_number   as line_number,
             xei.error_code    as error_code,
             xei.error_message as error_message,
             xei.status        as status
        FROM xx03_error_info xei
       WHERE xei. check_id = ln_check_seq
-- ver11.5.10.1.6D Add Start
       ORDER BY xei.line_number;
-- ver11.5.10.1.6D Add End
--
    -- *** ���[�J���E���R�[�h ***
    xx03_xrsjlv_rec            xx03_xrsjlv_cur          %ROWTYPE;       -- �����Ώۃf�[�^�擾�J�[�\�����R�[�h�^
    xx03_rate_rec              xx03_rate_cur            %ROWTYPE;       -- ���[�g�J�[�\�����R�[�h�^
    xx03_prerec_get_rec        xx03_prerec_get_cur      %ROWTYPE;       -- �O��[���`�[�ԍ��擾�J�[�\�����R�[�h�^
    xx03_prerec_check_rec      xx03_prerec_check_cur    %ROWTYPE;       -- �O��[���`�[�ԍ��������`�F�b�N�J�[�\�����R�[�h�^
    xx03_prerec_num_rec        xx03_prerec_num_cur      %ROWTYPE;       -- �O��[���`�[�ԍ��`�F�b�N�J�[�\�����R�[�h�^
    xx03_orig_num_rec          xx03_orig_num_cur        %ROWTYPE;       -- �C�����`�[�ԍ��`�F�b�N�J�[�\�����R�[�h�^
    xx03_ar_period_status_rec  xx03_ar_period_status_cur%ROWTYPE;       -- AR��v���ԃ`�F�b�N�J�[�\�����R�[�h�^
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;       -- GL��v���ԃ`�F�b�N�J�[�\�����R�[�h�^
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    xx03_site_accounts_rec     xx03_site_accounts_cur   %ROWTYPE;       -- �ڋq���Ə��̐�����T�C�g���x���̊���Ȗڑ��݃`�F�b�N�J�[�\�����R�[�h�^
    xx03_site_profile_rec      xx03_site_profile_cur    %ROWTYPE;       -- �ڋq���Ə��̌ڋq���ݒn���x���̃v���t�@�C�����݃`�F�b�N�J�[�\�����R�[�h�^
    -- Ver11.5.10.1.5B 2005/10/06 Add End
    xx03_errchk_result_rec     xx03_errchk_result_cur   %ROWTYPE;       -- ���ʃG���[�`�F�b�N���ʎ擾���R�[�h�^
-- ver 11.5.10.2.2 Add Start
    -- �\����-���F�� �`�F�b�N�J�[�\�����R�[�h�^
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add End
-- 2006/02/18 Ver11.5.10.1.6E Add START
    --���F�҃`�F�b�N�J�[�\�����R�[�h�^
    xx03_approver_rec            xx03_approver_cur%ROWTYPE;
    --�ڋq�`�F�b�N�J�[�\�����R�[�h�^
    xx03_customer_rec              xx03_customer_cur%ROWTYPE;
    --�ڋq���Ə��`�F�b�N�J�[�\�����R�[�h�^
    xx03_cust_office_rec         xx03_cust_office_cur%ROWTYPE;
    --�ʉ݃`�F�b�N�J�[�\�����R�[�h�^
    xx03_currency_name_rec       xx03_currency_name_cur%ROWTYPE;
    --�x�����@�`�F�b�N�J�[�\�����R�[�h�^
    xx03_receipt_method_name_rec      xx03_receipt_method_name_cur%ROWTYPE;
    --�x�������`�F�b�N�J�[�\�����R�[�h�^
    xx03_terms_name_rec          xx03_terms_name_cur%ROWTYPE;
    --����^�C�v�`�F�b�N�J�[�\�����R�[�h�^
    xx03_trans_type_name_rec           xx03_trans_type_name_cur%ROWTYPE;
    --�P�ʃ`�F�b�N�J�[�\�����R�[�h�^
    xx03_uom_code_rec xx03_uom_code_cur%ROWTYPE;
    --�ŋ��R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    xx03_tax_col_rec             xx03_tax_col_cur%ROWTYPE;
-- 2006/02/18 Ver11.5.10.1.6E Add END

--
    -- ���݌��ؗp�p�����[�^
    lb_retcode          BOOLEAN;
    lv_app_short_name   VARCHAR2(100)  := 'SQLGL';                         -- �A�v���P�[�V����'General Ledger'
    lv_key_flex_code    VARCHAR2(1000) := 'GL#';                        -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER         := null;                         -- GL_SETS_OF_BOOKS.CHART_OF_ACCOUNTS_ID
    ld_validation_date  DATE           := SYSDATE;
    ln_segments         NUMBER         := 8;
    lv_segment_array    FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id   NUMBER         := null;                         -- �R���r�l�[�V����ID
    ld_data_set         NUMBER         := -1;
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
    OPEN xx03_xrsjlv_cur;
    <<xx03_xrsjlv_loop>>
    LOOP
      FETCH xx03_xrsjlv_cur INTO xx03_xrsjlv_rec;
--
      -- 1�����f�[�^���Ȃ��ꍇ
      IF xx03_xrsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          RAISE NO_DATA_FOUND;
        ELSE
          -- �f�[�^�I��
          EXIT xx03_xrsjlv_loop;
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
        SELECT xrsv.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE      -- �ʉ݃R�[�h
             , xrsv.EXCHANGE_RATE         as EXCHANGE_RATE              -- ���[�g
             , xrsv.EXCHANGE_RATE_TYPE    as EXCHANGE_RATE_TYPE         -- ���[�g�^�C�v
             , xrsv.GL_DATE               as GL_DATE                    -- �v���
        --2006/02/18 Ver11.5.10.1.6E Add START
             , xrsv.INVOICE_DATE          as invoice_date               -- ���������t
             , xrsv.RECEIPT_METHOD_ID     as receipt_method_id          -- �x�����@
        --2006/02/18 Ver11.5.10.1.6E Add END
             , xrsv.COMMITMENT_NUMBER     as COMMITMENT_NUMBER          -- �O��[���`�[�ԍ�
             , xrsv.ORIG_INVOICE_NUM      as ORIG_INVOICE_NUM           -- �C�����`�[�ԍ�
             -- Ver11.5.10.1.5B 2005/10/06 Add Start
             , xrsv.CUSTOMER_OFFICE_ID    as CUSTOMER_OFFICE_ID         -- �ڋq���Ə�ID
             -- Ver11.5.10.1.5B 2005/10/06 Add End
        --2006/03/06 Ver11.5.10.1.6H add start
             , xrsv.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6H add End
        INTO   lv_chk_currency_code
             , ln_chk_exchange_rate
             , lv_chk_exchange_rate_type
             , ld_chk_gl_date
        --2006/02/18 Ver11.5.10.1.6E Add START
             , ld_chk_invoice_date
             , ld_chk_receipt_method_id
        --2006/02/18 Ver11.5.10.1.6E Add END
             , lv_chk_prerec_num
             , lv_chk_orig_invoice_num
             -- Ver11.5.10.1.5B 2005/10/06 Add Start
             , ln_chk_customer_office_id
             -- Ver11.5.10.1.5B 2005/10/06 Add End
        --2006/03/06 Ver11.5.10.1.6H add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6H add End
-- Ver11.5.10.1.5 2005/09/02 Change Start
--        FROM   XX03_RECEIVABLE_SLIPS_V xrsv
        FROM   XX03_RECEIVABLE_SLIPS xrsv
-- Ver11.5.10.1.5 2005/09/02 Change End
        WHERE  xrsv.RECEIVABLE_ID = in_receivable_id;                   -- �`�[ID
--
        -- ���[�g�`�F�b�N
        -- �ʉ݃R�[�h���@�\�ʉ݃R�[�h�̂Ƃ�
        IF ( lv_currency_code = lv_chk_currency_code ) THEN
          -- ���[�g�����[�g�^�C�v�ɓ��͒l������΃G���[
          IF ( ln_chk_exchange_rate      IS NOT NULL   OR
               lv_chk_exchange_rate_type IS NOT NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14001');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
--
        -- �@�\�ʉ݃R�[�h�łȂ��Ƃ�
        ELSE
          -- ���[�g�ɓ��͒l���Ȃ���΃G���[
          IF ( ln_chk_exchange_rate IS NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14002');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- ���[�g�^�C�v�ɓ��͒l���Ȃ���΃G���[
          ELSIF ( lv_chk_exchange_rate_type IS NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14003');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- ���[�g�^�C�v��'User'�̂Ƃ�
          ELSIF ( lv_chk_exchange_rate_type != 'User' ) THEN
            OPEN xx03_rate_cur(
              lv_chk_currency_code,       -- 1.�ʉ݃R�[�h
              lv_chk_exchange_rate_type,  -- 2.���[�g�^�C�v
              ld_chk_gl_date              -- 3.GL�L����
            );
--
            FETCH xx03_rate_cur INTO xx03_rate_rec;
            -- �Y�����R�[�h���Ȃ���΃G���[
            IF xx03_rate_cur%NOTFOUND THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
              ln_err_cnt := ln_err_cnt + 1;
--
            -- �Y�����R�[�h������Ƃ�
            ELSE
              -- ���[�g�̒l���قȂ�΃G���[
              IF ( xx03_rate_rec.conversion_rate != ln_chk_exchange_rate ) THEN
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
        -- �O����[���`�[�ԍ��`�F�b�N
        OPEN xx03_prerec_get_cur();
        FETCH xx03_prerec_get_cur INTO xx03_prerec_get_rec;
--
        -- �O��`�[�w��Ȃ�
        IF (xx03_prerec_get_rec.COMMITMENT_NUMBER IS NULL) THEN
          -- ���ɏ����Ȃ�
          NULL;
--
        -- �O��`�[�w�肠��
        ELSE
          OPEN xx03_prerec_check_cur();
          FETCH xx03_prerec_check_cur INTO xx03_prerec_check_rec;
--
          -- �Y�����R�[�h���Ȃ���΃G���[
          IF xx03_prerec_check_cur%NOTFOUND THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14058');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- ���R�[�h���I�����ꂽ
          ELSE
            -- ���ɏ����Ȃ�
            NULL;
          END IF;
          CLOSE xx03_prerec_check_cur;
        END IF;
        CLOSE xx03_prerec_get_cur;
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- �O���[���`�[�ԍ����͎��̂݃`�F�b�N����
      IF lv_chk_prerec_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- �O��[���`�[�ԍ��`�F�b�N
        OPEN xx03_prerec_num_cur(
          lv_chk_prerec_num  -- 1.�O��[���`�[�ԍ�
        );
--
        FETCH xx03_prerec_num_cur INTO xx03_prerec_num_rec;
--
        -- �Y�����R�[�h���I������Ȃ�����
        IF xx03_prerec_num_cur%NOTFOUND THEN
          -- ���ɏ����Ȃ�
          NULL;
--
        -- �Y�����R�[�h������΃G���[
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14059');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_prerec_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- �C�����`�[�ԍ����͎��̂݃`�F�b�N����
      IF lv_chk_orig_invoice_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- �C�����`�[�ԍ��`�F�b�N
        OPEN xx03_orig_num_cur(
          lv_chk_orig_invoice_num  -- 1.�C�����`�[�ԍ�
        );
--
        FETCH xx03_orig_num_cur INTO xx03_orig_num_rec;
--
        -- ���R�[�h���I������Ȃ�����
        IF xx03_orig_num_cur%NOTFOUND THEN
          -- ���ɏ����Ȃ�
          NULL;
--
        -- �Y�����R�[�h������΃G���[
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14149');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_orig_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
        -- AR��v���ԃ`�F�b�N
        OPEN xx03_ar_period_status_cur(
          ln_books_id,    -- 1.�C�����`�[�ԍ�
          ld_chk_gl_date  -- 2.GL�L����
        );
        FETCH xx03_ar_period_status_cur INTO xx03_ar_period_status_rec;
--
        -- ��v���ԃf�[�^�Ȃ��Ȃ�AAR��v���Ԗ���`�G���[
        IF xx03_ar_period_status_cur%NOTFOUND THEN
          lv_period_data_flg := 'N';
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14060');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- ��v���ԃf�[�^����
        ELSE
          lv_period_data_flg := 'Y';
--
          -- AR��v���Ԃ��I�[�v���łȂ���΁A���I�[�v���G���[
          IF ( xx03_ar_period_status_rec.closing_status != 'O'   AND
               xx03_ar_period_status_rec.closing_status != 'F' ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14061');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- 'O'�A'F'�̎��͓��ɏ����Ȃ�
          ELSE
            NULL;
          END IF;
        END IF;
        CLOSE xx03_ar_period_status_cur;
--
        -- ��v���ԃf�[�^����̎��̂�
        IF ( lv_period_data_flg = 'Y' ) THEN
          -- GL��v���ԃ`�F�b�N
          OPEN xx03_gl_period_status_cur(
            ln_books_id,    -- 1.�C�����`�[�ԍ�
            ld_chk_gl_date  -- 2.GL�L����
          );
--
          FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
--
          -- �Y���f�[�^���Ȃ���΁AGL��v���Ԗ���`�G���[
          IF xx03_gl_period_status_cur%NOTFOUND THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- �Y���f�[�^������Ƃ�
          ELSE
            -- GL��v���Ԃ��I�[�v������Ă��Ȃ���΁A���I�[�v���G���[
            IF ( xx03_gl_period_status_rec.attribute4 IS NOT NULL AND
                 xx03_gl_period_status_rec.attribute4 != 'O' )    THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
--
            -- 'O'�ANull�̎��͓��ɏ����Ȃ�
            ELSE
              NULL;
            END IF;
          END IF;
          CLOSE xx03_gl_period_status_cur;
        END IF;
--
        -- Ver11.5.10.1.5B 2005/10/06 Add Start
        -- �ڋq���Ə��̐�����T�C�g���x���̊���Ȗڑ��݃`�F�b�N
        OPEN xx03_site_accounts_cur(
          ln_chk_customer_office_id  -- 1.�ڋq���Ə�ID
        );
--
        FETCH xx03_site_accounts_cur INTO xx03_site_accounts_rec;
--
        -- ���R�[�h���I������Ȃ���΃G���[
        IF xx03_site_accounts_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13058');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- �Y�����R�[�h����
        ELSE
          -- ���ɏ����Ȃ�
          NULL;
        END IF;
        CLOSE xx03_site_accounts_cur;
--
        -- �ڋq���Ə��̌ڋq���ݒn���x���̃v���t�@�C�����݃`�F�b�N
        OPEN xx03_site_profile_cur(
          ln_chk_customer_office_id  -- 1.�ڋq���Ə�ID
        );
--
        FETCH xx03_site_profile_cur INTO xx03_site_profile_rec;
--
        -- ���R�[�h���I������Ȃ���΃G���[
        IF xx03_site_profile_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13059');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- �Y�����R�[�h����
        ELSE
          -- ���ɏ����Ȃ�
          NULL;
        END IF;
        CLOSE xx03_site_profile_cur;
        -- Ver11.5.10.1.5B 2005/10/06 Add End
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
-- 2006/02/18 Ver11.5.10.1.6E Add START
-- �w�b�_�[�̃}�X�^�[�`�F�b�N���{
        --2006/03/06 Ver11.5.10.1.6H Change Start
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
        --2006/03/06 Ver11.5.10.1.6H Change End
--
        --�ڋq�`�F�b�N
        OPEN xx03_customer_cur;
        FETCH xx03_customer_cur INTO xx03_customer_rec;
        IF xx03_customer_rec.exist_check = 0 THEN
          -- �ڋq�`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13061','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_customer_cur;
--
        --�ڋq���Ə��`�F�b�N
        OPEN xx03_cust_office_cur;
        FETCH xx03_cust_office_cur INTO xx03_cust_office_rec;
        IF xx03_cust_office_rec.exist_check = 0 THEN
          -- �ڋq���Ə��`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13062','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_cust_office_cur;
--
        -- ver 11.5.10.2.10D Chg Start
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
        -- ver 11.5.10.2.10D Chg End
--
        --�x�����@�`�F�b�N
        --�x�����@��NULL�łȂ��Ƃ��̂݃`�F�b�N���{
        IF ld_chk_receipt_method_id IS NOT NULL THEN
          OPEN xx03_receipt_method_name_cur;
          FETCH xx03_receipt_method_name_cur INTO xx03_receipt_method_name_rec;
          IF xx03_receipt_method_name_rec.exist_check = 0 THEN
            -- �x�����@�`�F�b�N�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13063','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_receipt_method_name_cur;
        END IF;
--
        --�x�������`�F�b�N
        OPEN xx03_terms_name_cur;
        FETCH xx03_terms_name_cur INTO xx03_terms_name_rec;
        IF xx03_terms_name_rec.exist_check = 0 THEN
          -- �x�������`�F�b�N�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13064','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_terms_name_cur;
--
        --����^�C�v�`�F�b�N
-- ver 11.5.10.1.6G Add Start
        --����`�[�ȊO�̏ꍇ�`�F�b�N����
        IF lv_chk_orig_invoice_num IS NULL THEN
-- ver 11.5.10.1.6G Add End
          OPEN xx03_trans_type_name_cur;
          FETCH xx03_trans_type_name_cur INTO xx03_trans_type_name_rec;
          IF xx03_trans_type_name_rec.exist_check = 0 THEN
            -- ����^�C�v�`�F�b�N�G���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13060','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_trans_type_name_cur;
-- ver 11.5.10.1.6G Add Start
        END IF;
-- ver 11.5.10.1.6G Add End
--
-- 2006/02/18 Ver11.5.10.1.6E Add END
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
      -- �t���b�N�X�E�t�B�[���h�̌n�ԍ��̎擾
      SELECT   sob.chart_of_accounts_id
        INTO   ln_structure_number
        FROM   gl_sets_of_books sob
       WHERE   xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID') = sob.set_of_books_id;
--
      -- ���݌��؃��[���`�F�b�N���s(�Ώ� : �w�b�_�[�ȊO)
      IF (xx03_xrsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xrsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xrsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xrsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xrsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xrsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xrsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xrsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xrsjlv_rec.segment8;
--
        lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                          application_short_name => lv_app_short_name
                        , key_flex_code          => lv_key_flex_code
                        , structure_number       => ln_structure_number
        -- 2006/01/30 Ver11.5.10.1.6C Change Start
        --              , validation_date        => ld_validation_date
                        , validation_date        => ld_chk_gl_date
        -- 2006/01/30 Ver11.5.10.1.6C Change End
                        , n_segments             => ln_segments
                        , segments               => lv_segment_array
                        , combination_id         => on_combination_id
                        , data_set               => ld_data_set
        );
--
        IF lb_retcode THEN
          NULL;
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := FND_FLEX_EXT.GET_MESSAGE;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
      END IF; -- xx03_xrsjlv_rec.segment1 IS NOT NULL
--
-- 2006/02/18 Ver11.5.10.1.6E add START
-- ���ׂ̃}�X�^�[�l�`�F�b�N�����{����
      --�������e�`�F�b�N
      --���׍s�̂݃`�F�b�N����
      IF xx03_xrsjlv_rec.line_type_lookup_code = 'ITEM' THEN
--
      --�P�ʃ`�F�b�N
        --�P�ʂ����͂���Ă���Ƃ��̂݃`�F�b�N���{
        SELECT SLIP_LINE_UOM
        INTO   ld_slip_line_uom
        FROM   XX03_RECEIVABLE_SLIPS_LINE
        WHERE  RECEIVABLE_ID = in_receivable_id
          AND  LINE_NUMBER   = xx03_xrsjlv_rec.line_number;
        IF ld_slip_line_uom IS NOT NULL THEN
          -- ver 11.5.10.2.6 Chg Start
          --OPEN xx03_uom_code_cur(
          --  xx03_xrsjlv_rec.line_number,    -- 1.���הԍ�
          --  ld_chk_invoice_date             -- 2.���������t
          --);
          OPEN xx03_uom_code_cur(xx03_xrsjlv_rec.line_number);  -- 1.���הԍ�
          -- ver 11.5.10.2.6 Chg End
          FETCH xx03_uom_code_cur INTO xx03_uom_code_rec;
          IF xx03_uom_code_rec.exist_check = 0 THEN
            -- �P�ʃG���[
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt)
              := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13066'
                                          ,'SLIP_NUM',''
                                          ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_uom_code_cur;
        END IF;
--
      --�ŋ��R�[�h�`�F�b�N
        OPEN xx03_tax_col_cur(
          xx03_xrsjlv_rec.line_number,    -- 1.���הԍ�
          ld_chk_invoice_date             -- 2.���������t
        );
        FETCH xx03_tax_col_cur INTO xx03_tax_col_rec;
        IF xx03_tax_col_rec.exist_check = 0 THEN
          -- �ŋ��R�[�h�G���[
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt)
            := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14151'
                                        ,'SLIP_NUM',''
                                        ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_tax_col_cur;
--
        -- ver 11.5.10.2.10D Add Start
        -- �ʉ݂����������͂���Ă���ꍇ�̓`�F�b�N
        IF lb_currency_chk = TRUE THEN
          -- �`�[���z�̐��x���擾
          lv_amount := TO_CHAR(xx03_xrsjlv_rec.amount);
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- �`�[���z�̐��x���ʉ݂̐��x�𒴂��Ă���΃G���[
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt)
              := xx00_message_pkg.get_msg('XX03','APP-XX03-14167'
                                          ,'SLIP_NUM',''
                                          ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- ver 11.5.10.2.10D Add End
--
      END IF;
--
-- 2006/02/18 Ver11.5.10.1.6E add END
--
      -- ������̓G���[�`�F�b�N�ŃG���[���������ꍇ�͂��̎��_�Ń��[�v�I��
      IF ( ln_err_cnt > 0 ) THEN
        -- �f�[�^�I��
        EXIT xx03_xrsjlv_loop;
      END IF;
--
      -- �G���[�`�F�b�N�e�[�u����������
      IF ( xx03_xrsjlv_rec.line_number = 0 ) THEN
        -- �w�b�_���R�[�h
        INSERT INTO xx03_error_checks(
            CHECK_ID
          , JOURNAL_ID
          , LINE_NUMBER
          , GL_DATE
          , PERIOD_NAME
          , CURRENCY_CODE
          , CODE_COMBINATION_ID
          , SEGMENT1
          , SEGMENT2
          , SEGMENT3
          , SEGMENT4
          , SEGMENT5
          , SEGMENT6
          , SEGMENT7
          , SEGMENT8
          , TAX_CODE
          , INCR_DECR_REASON_CODE
          , SLIP_NUMBER
          , INPUT_DEPARTMENT
          , INPUT_USER
          , ORIG_SLIP_NUMBER
          , RECON_REFERENCE
          , ENTERED_DR
          , ENTERED_CR
          , ATTRIBUTE_CATEGORY
          , ATTRIBUTE1
          , ATTRIBUTE2
          , ATTRIBUTE3
          , ATTRIBUTE4
          , ATTRIBUTE5
          , ATTRIBUTE6
          , ATTRIBUTE7
          , ATTRIBUTE8
          , ATTRIBUTE9
          , ATTRIBUTE10
          , ATTRIBUTE11
          , ATTRIBUTE12
          , ATTRIBUTE13
          , ATTRIBUTE14
          , ATTRIBUTE15
          , ATTRIBUTE16
          , ATTRIBUTE17
          , ATTRIBUTE18
          , ATTRIBUTE19
          , ATTRIBUTE20
          , CREATED_BY
          , CREATION_DATE
          , LAST_UPDATED_BY
          , LAST_UPDATE_DATE
          , LAST_UPDATE_LOGIN
          , REQUEST_ID
          , PROGRAM_APPLICATION_ID
          , PROGRAM_UPDATE_DATE
          , PROGRAM_ID
        ) VALUES (
            ln_check_seq
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.line_number
          , xx03_xrsjlv_rec.gl_date
          , null
          , xx03_xrsjlv_rec.invoice_currency_code
          , xx03_xrsjlv_rec.code_combination_id
          , xx03_xrsjlv_rec.segment1
          , xx03_xrsjlv_rec.segment2
          , xx03_xrsjlv_rec.segment3
          , xx03_xrsjlv_rec.segment4
          , xx03_xrsjlv_rec.segment5
          , xx03_xrsjlv_rec.segment6
          , xx03_xrsjlv_rec.segment7
          , xx03_xrsjlv_rec.segment8
          , null
          , null
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.entry_department
          , xx03_xrsjlv_rec.user_name
          , null
          , null
          , null
          , xx03_xrsjlv_rec.amount
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.login_id
          , xx00_global_pkg.conc_request_id
          , xx00_global_pkg.prog_appl_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.conc_program_id
        );
      ELSE
        -- ����(�ŋ�)���R�[�h
        INSERT INTO xx03_error_checks(
            CHECK_ID
          , JOURNAL_ID
          , LINE_NUMBER
          , GL_DATE
          , PERIOD_NAME
          , CURRENCY_CODE
          , CODE_COMBINATION_ID
          , SEGMENT1
          , SEGMENT2
          , SEGMENT3
          , SEGMENT4
          , SEGMENT5
          , SEGMENT6
          , SEGMENT7
          , SEGMENT8
          , TAX_CODE
          , INCR_DECR_REASON_CODE
          , SLIP_NUMBER
          , INPUT_DEPARTMENT
          , INPUT_USER
          , ORIG_SLIP_NUMBER
          , RECON_REFERENCE
          , ENTERED_DR
          , ENTERED_CR
          , ATTRIBUTE_CATEGORY
          , ATTRIBUTE1
          , ATTRIBUTE2
          , ATTRIBUTE3
          , ATTRIBUTE4
          , ATTRIBUTE5
          , ATTRIBUTE6
          , ATTRIBUTE7
          , ATTRIBUTE8
          , ATTRIBUTE9
          , ATTRIBUTE10
          , ATTRIBUTE11
          , ATTRIBUTE12
          , ATTRIBUTE13
          , ATTRIBUTE14
          , ATTRIBUTE15
          , ATTRIBUTE16
          , ATTRIBUTE17
          , ATTRIBUTE18
          , ATTRIBUTE19
          , ATTRIBUTE20
          , CREATED_BY
          , CREATION_DATE
          , LAST_UPDATED_BY
          , LAST_UPDATE_DATE
          , LAST_UPDATE_LOGIN
          , REQUEST_ID
          , PROGRAM_APPLICATION_ID
          , PROGRAM_UPDATE_DATE
          , PROGRAM_ID
        ) VALUES (
            ln_check_seq
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.line_number
          , xx03_xrsjlv_rec.gl_date
          , null
          , xx03_xrsjlv_rec.invoice_currency_code
          , xx03_xrsjlv_rec.code_combination_id
          , xx03_xrsjlv_rec.segment1
          , xx03_xrsjlv_rec.segment2
          , xx03_xrsjlv_rec.segment3
          , xx03_xrsjlv_rec.segment4
          , xx03_xrsjlv_rec.segment5
          , xx03_xrsjlv_rec.segment6
          , xx03_xrsjlv_rec.segment7
          , xx03_xrsjlv_rec.segment8
          , xx03_xrsjlv_rec.tax_code
          , xx03_xrsjlv_rec.incr_decr_reason_code
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.entry_department
          , xx03_xrsjlv_rec.user_name
          , null
          , xx03_xrsjlv_rec.recon_reference
          , xx03_xrsjlv_rec.amount
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.login_id
          , xx00_global_pkg.conc_request_id
          , xx00_global_pkg.prog_appl_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.conc_program_id
        );
      END IF;
    END LOOP xx03_xrsjlv_loop;
    CLOSE xx03_xrsjlv_cur;
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
--
          IF xx03_errchk_result_cur%NOTFOUND THEN
            EXIT xx03_errchk_result_loop;
          END IF;
--
          -- �擾�����G���[�������ɃG���[���z��ɃZ�b�g
          IF ( ln_err_cnt <= 19 ) THEN
            -- �G���[������20���ȉ��̎��̂݃G���[���Z�b�g
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10 Chg Start
--            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '�F' ||
--                                            xx03_errchk_result_rec.error_message;
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
-- ver 11.5.10.2.10 Chg End
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
--
        END LOOP xx03_errchk_result_loop;
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver 11.5.10.1.6F Del Start
      ---- �G���[�`�F�b�N�A�G���[���f�[�^�폜
      --DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      --DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6F Del End
    END IF;
--
-- ver 11.5.10.1.6F Add Start
    IF ln_check_seq != 0 THEN
      -- �G���[�`�F�b�N�A�G���[���f�[�^�폜
      DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
    END IF;
-- ver 11.5.10.1.6F Add End
--
    -- OUT�p�����[�^�ݒ�
    ov_error_flg := 'S';
    FOR ln_cnt IN 0..19 LOOP
--
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
    -- �G���[�������Q�O�ȏ�Ȃ�A�G���[�����͂Q�O��Ԃ��B
    IF ln_err_cnt > 20 THEN
      on_error_cnt   := 20;
    ELSE
      on_error_cnt   := ln_err_cnt;
    END IF;
--
    ov_error_flg1  := errflg_tbl(0);
    ov_error_msg1  := errmsg_tbl(0);
    ov_error_flg2  := errflg_tbl(1);
    ov_error_msg2  := errmsg_tbl(1);
    ov_error_flg3  := errflg_tbl(2);
    ov_error_msg3  := errmsg_tbl(2);
    ov_error_flg4  := errflg_tbl(3);
    ov_error_msg4  := errmsg_tbl(3);
    ov_error_flg5  := errflg_tbl(4);
    ov_error_msg5  := errmsg_tbl(4);
    ov_error_flg6  := errflg_tbl(5);
    ov_error_msg6  := errmsg_tbl(5);
    ov_error_flg7  := errflg_tbl(6);
    ov_error_msg7  := errmsg_tbl(6);
    ov_error_flg8  := errflg_tbl(7);
    ov_error_msg8  := errmsg_tbl(7);
    ov_error_flg9  := errflg_tbl(8);
    ov_error_msg9  := errmsg_tbl(8);
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
      IF xx03_xrsjlv_cur%ISOPEN THEN
        CLOSE xx03_xrsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
      IF xx03_prerec_get_cur%ISOPEN THEN
        CLOSE xx03_prerec_get_cur;
      END IF;
      IF xx03_prerec_check_cur%ISOPEN THEN
        CLOSE xx03_prerec_check_cur;
      END IF;
      IF xx03_prerec_num_cur%ISOPEN THEN
        CLOSE xx03_prerec_num_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_ar_period_status_cur%ISOPEN THEN
        CLOSE xx03_ar_period_status_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      -- Ver11.5.10.1.5B 2005/10/06 Add Start
      IF xx03_site_accounts_cur%ISOPEN THEN
        CLOSE xx03_site_accounts_cur;
      END IF;
      IF xx03_site_profile_cur%ISOPEN THEN
        CLOSE xx03_site_profile_cur;
      END IF;
      -- Ver11.5.10.1.5B 2005/10/06 Add End
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
  END check_deptinput_ar;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : �d�_�Ǘ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_receivable_id IN  NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
    ov_app_upd       OUT VARCHAR2,  -- 2.�d�_�Ǘ��X�V���e
    ov_errbuf        OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.set_account_approval_flag'; -- �v���O������
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
    ln_head_acc_amount   NUMBER;                            -- �w�b�_���Z�z
    lv_slip_type         VARCHAR2(25);                      -- �w�b�_�`�[���
    lv_detail_first_flg  VARCHAR2(1);                       -- �z���Ǎ�1���ڃt���O
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �`�[��ʃ}�X�^���擾�J�[�\��
    CURSOR xx03_slip_type_cur(
      iv_slip_type   IN  VARCHAR2  -- 1.�`�[���
    ) IS
      SELECT   xst.attribute1 as attribute1
             , xst.attribute2 as attribute2
        FROM   xx03_slip_types_v xst
       WHERE   xst.lookup_code = iv_slip_type;
--
    -- �������z�����擾�J�[�\��
    CURSOR xx03_detail_info_cur
    IS
      SELECT   xav.attribute7              as attribute7
        FROM   XX03_RECEIVABLE_SLIPS_LINE     xrsl
             , xx03_accounts_v                xav
--     WHERE   xrsl.RECEIVABLE_LINE_ID = in_receivable_id   -- �`�[ID
       WHERE   xrsl.RECEIVABLE_ID      = in_receivable_id   -- �`�[ID
         AND   xrsl.segment3           = xav.flex_value;    -- ����Ȗ�
--
    -- *** ���[�J���E���R�[�h ***
    xx03_slip_type_rec       xx03_slip_type_cur  %ROWTYPE;  -- �`�[��ʃ}�X�^���擾�J�[�\�����R�[�h�^
    xx03_detail_info_rec     xx03_detail_info_cur%ROWTYPE;  -- �������z�����擾�J�[�\�����R�[�h�^
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
    SELECT   ABS(
               ROUND((xrs.INV_ITEM_AMOUNT + xrs.INV_TAX_AMOUNT) * NVL(xrs.EXCHANGE_RATE, 1))
             ) as inv_accounted_amount                         -- ���Z�ύ��v���z[�i�{�̍��v���z �{ ����ō��v���z�j �~ ���[�g]
           , xrs.SLIP_TYPE as SLIP_TYPE                        -- �`�[���
      INTO   ln_head_acc_amount
           , lv_slip_type
      FROM   XX03_RECEIVABLE_SLIPS xrs
     WHERE   xrs.RECEIVABLE_ID = in_receivable_id;             -- �`�[ID
--
    -- �`�[��ʃ}�X�^���擾
    OPEN xx03_slip_type_cur(lv_slip_type);
--
    FETCH xx03_slip_type_cur INTO xx03_slip_type_rec;
--
    -- �`�[��ʃ}�X�^����f�[�^���擾�ł��Ȃ��Ƃ�
    IF xx03_slip_type_cur%NOTFOUND THEN
      RAISE NO_DATA_FOUND;
--
    -- �`�[��ʃ}�X�^����f�[�^���擾�ł����Ƃ�
    ELSE
      -- �o�����F�d�_�Ǘ��L����'Y'�������ꍇ�́A�u�d�_�Ǘ��X�V���e�v��'Y'���Z�b�g����RETURN
      IF ( xx03_slip_type_rec.attribute1 = 'Y' ) THEN
        ov_app_upd := 'Y';
        CLOSE xx03_slip_type_cur;
        RETURN;
--
      -- �o�����F�d�_�Ǘ��L����'N'�������ꍇ
      ELSE
        -- ���Z�ύ��v���z >= �o�����F�Ώۓ`�[���z�̂Ƃ�
        IF ( ln_head_acc_amount >= xx03_slip_type_rec.attribute2 ) THEN
          -- �u�d�_�Ǘ��X�V���e�v��'Y'���Z�b�g���ARETURN
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
--
      -- 1�����Ȃ������ꍇ
      IF xx03_detail_info_cur%NOTFOUND THEN
        -- ����Ȃ�G���[
        IF ( lv_detail_first_flg = 'Y' ) THEN
          RAISE NO_DATA_FOUND;
--
        -- ����łȂ���΃��[�v�𗣒E����B
        ELSE
          EXIT xx03_detail_info_loop;
        END IF;
      END IF;
--
      -- ����t���O��OFF�ɂ���B
      IF ( lv_detail_first_flg = 'Y' ) THEN
        lv_detail_first_flg := 'N';
      END IF;
--
      -- attribute7��'Y'�̃��R�[�h������΁A�u�d�_�Ǘ��X�V���e�v��'Y'���Z�b�g����RETURN
      IF ( xx03_detail_info_rec.attribute7 = 'Y' ) THEN
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
   * Description      : �����\����̎Z�o
   ***********************************************************************************/
  PROCEDURE get_terms_date(
    in_terms_id   IN  NUMBER,    -- 1.�x������
    id_start_date IN  DATE,      -- 2.���������t
    od_terms_date OUT DATE,      -- 3.�����\���
    ov_errbuf     OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.get_terms_date'; -- �v���O������
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

    -- �x���\����Z�o�p
    l_due_cutoff_day       RA_TERMS_VL.DUE_CUTOFF_DAY%TYPE;
    l_due_days             RA_TERMS_LINES.DUE_DAYS%TYPE;
    l_due_date             RA_TERMS_LINES.DUE_DATE%TYPE;
    l_due_day_of_month     RA_TERMS_LINES.DUE_DAY_OF_MONTH%TYPE;
    l_due_months_forward   RA_TERMS_LINES.DUE_MONTHS_FORWARD%TYPE;
    ln_start_day           NUMBER;
    ln_cut_day             NUMBER;
    ln_after_day           NUMBER;
    ld_add_day             DATE;
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
   -- AR���ԏ��擾
   SELECT rtl.sequence_num as sequence_num
     INTO ln_sequence_num
     FROM ra_terms_lines rtl
    WHERE rtl.term_id = in_terms_id
      AND rownum = 1
   ORDER BY rtl.sequence_num;
--
/*
  -- �x���\������擾
    SELECT DECODE(RTL.DUE_DAYS,
         NULL, TO_DATE(TO_CHAR(ADD_MONTHS(id_start_date,
             NVL(RTL.DUE_MONTHS_FORWARD, 0) +
               DECODE(RT.DUE_CUTOFF_DAY, NULL, 0,
          DECODE(GREATEST(LEAST(NVL(RT.DUE_CUTOFF_DAY, 32),
             TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                TO_NUMBER(TO_CHAR(id_start_date, 'DD')), 1, 0))),
                   'YYYY/MM') || '/' ||
          TO_CHAR(LEAST(NVL(RTL.DUE_DAY_OF_MONTH, 32),
           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_start_date,
             NVL(RTL.DUE_MONTHS_FORWARD, 0) +
           DECODE(RT.DUE_CUTOFF_DAY, NULL, 0,
           DECODE(GREATEST(LEAST(NVL(RT.DUE_CUTOFF_DAY, 32),
             TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))
             , 1, 0)))), 'DD')))
          ),'YYYY/MM/DD'
          ),
          id_start_date + NVL(RTL.DUE_DAYS, 0))
    INTO od_terms_date
    FROM RA_TERMS_VL RT,
         RA_TERMS_LINES RTL
   WHERE RT.TERM_ID = in_terms_id
     AND RT.TERM_ID = RTL.TERM_ID
     AND RTL.SEQUENCE_NUM = ln_sequence_num;
*/
--
  -- �x���\����Z�o�ɕK�v�ȍ��ڂ��擾
  SELECT RT.DUE_CUTOFF_DAY       DUE_CUTOFF_DAY
        ,RTL.DUE_DAYS            DUE_DAYS
        ,RTL.DUE_DATE            DUE_DATE
        ,RTL.DUE_DAY_OF_MONTH    DUE_DAY_OF_MONTH
        ,RTL.DUE_MONTHS_FORWARD  DUE_MONTHS_FORWARD
  INTO   l_due_cutoff_day
        ,l_due_days
        ,l_due_date
        ,l_due_day_of_month
        ,l_due_months_forward
  FROM   ( SELECT TERM_ID
                 ,DUE_CUTOFF_DAY
           FROM   RA_TERMS_VL
           WHERE  TERM_ID = in_terms_id         ) RT
        ,( SELECT TERM_ID
                 ,DUE_DAYS
                 ,DUE_DATE
                 ,DUE_DAY_OF_MONTH
                 ,DUE_MONTHS_FORWARD
           FROM   RA_TERMS_LINES
           WHERE  TERM_ID      = in_terms_id
              AND SEQUENCE_NUM = ln_sequence_num) RTL
  WHERE  RT.TERM_ID = RTL.TERM_ID
  ;

  -- ���t�w�肪���͂���Ă���ꍇ�́A���̂܂ܒl���Z�b�g
  IF l_due_date IS NOT NULL THEN
    od_terms_date := l_due_date;

  -- �����w�肪���͂���Ă���ꍇ�́A���̒l�����Z���ăZ�b�g
  ELSIF l_due_days IS NOT NULL THEN
    od_terms_date := id_start_date + l_due_days;

  -- ��L�ȊO�͊e�l���v�Z����
  ELSE

    -- ���͒l�̓��t���擾
    ln_start_day := TO_NUMBER(TO_CHAR(id_start_date,'DD'));
    -- ���͒l�̖���������ɃZ�b�g
    -- Ver11.5.10.1.6 2005/11/04 Change Start
    -- ln_cut_day   := TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date),'DD'));
    ln_cut_day   := TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date),'DD')) + 1;
    -- Ver11.5.10.1.6 2005/11/04 Change End

    -- ���������͂���Ă���ꍇ�͖����Ɣ�r���ĎႢ��������Ƃ���
    IF l_due_cutoff_day IS NOT NULL THEN
      IF l_due_cutoff_day < ln_cut_day THEN
        ln_cut_day := l_due_cutoff_day;
      END IF;
    END IF;

    -- ���͓��ƒ������r���ē��͓����������ȍ~�Ȃ�
    -- ���̌J�z�ɂ���ɂP�����ǉ�����
    IF ln_start_day >= ln_cut_day THEN
      ld_add_day := ADD_MONTHS(id_start_date,NVL(l_due_months_forward,0) + 1);
    ELSE
      ld_add_day := ADD_MONTHS(id_start_date,NVL(l_due_months_forward,0));
    END IF;

    -- ���̌J�z��̖��������[�N�ɃZ�b�g
    ln_after_day := TO_NUMBER(TO_CHAR(LAST_DAY(ld_add_day),'DD'));

    -- �x�����t�����͂���Ă���ꍇ�͖����Ɣ�r���ĎႢ����\����Ƃ���
    IF l_due_day_of_month IS NOT NULL THEN
      IF l_due_day_of_month < ln_after_day THEN
        ln_after_day := l_due_day_of_month;
      END IF;
    END IF;

    -- �\�茎�Ɨ\������A�����\������擾����
    od_terms_date := TO_DATE(TO_CHAR(ld_add_day,'YYYY/MM') || '/' || TO_CHAR(ln_after_day,'00'),'YYYY/MM/DD');

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
      ov_errmsg  := lv_errmsg;                                                           --# �C�� #
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# �C�� #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                  --# �C�� #
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
  /**********************************************************************************
   * Procedure Name   : del_receivable_data
   * Description      : �x���`�[���R�[�h�̍폜
   *                    WF�X�e�[�^�X���u�ۑ��v�Ȃ畨���폜���s���B
   *                    WF�X�e�[�^�X���u�۔F�v�i�u�ۑ��v�ȊO�j�Ȃ�_���폜���s���B
   ***********************************************************************************/
  PROCEDURE del_receivable_data(
    in_receivable_id IN  NUMBER,    -- 1.�폜�Ώې����˗��`�[ID
    ov_errbuf        OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --�����g�����U�N�V������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.del_receivable_data'; -- �v���O������
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
    cn_wf_status_save CONSTANT XX03_RECEIVABLE_SLIPS.wf_status%TYPE   := '00';  -- WF�X�e�[�^�X�F�ۑ�
    cn_delete_yes     CONSTANT XX03_RECEIVABLE_SLIPS.delete_flag%TYPE := 'Y';   -- �폜�t���O�F�_���폜���
--
    -- *** ���[�J���ϐ� ***
    lv_wf_status               XX03_RECEIVABLE_SLIPS.wf_status%TYPE;            -- WF�X�e�[�^�X
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
    SELECT xrs.wf_status
    INTO   lv_wf_status
    FROM   XX03_RECEIVABLE_SLIPS xrs
    WHERE  xrs.RECEIVABLE_ID = in_receivable_id;
--
    -- �ۑ��`�[�iWF�X�e�[�^�X���u�ۑ��v�̂��́j�͕����폜���s��
    IF lv_wf_status = cn_wf_status_save THEN
      -- �d��`�[���׃��R�[�h�폜
      DELETE FROM xx03_receivable_slips_line xrsl
      WHERE xrsl.RECEIVABLE_ID = in_receivable_id;
--
      -- �d��`�[�w�b�_���R�[�h�폜
      DELETE FROM xx03_receivable_slips      xrs
      WHERE xrs.RECEIVABLE_ID = in_receivable_id;
--
    -- �ۑ��ȊO�̏ꍇ�͘_���폜���s��
    ELSE
      -- �d��`�[�w�b�_���R�[�h�X�V
      UPDATE xx03_receivable_slips           xrs
      SET    delete_flag = cn_delete_yes
      WHERE xrs.RECEIVABLE_ID = in_receivable_id;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
  END del_receivable_data;
--
-- ver11.5.10.1.6D Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ar_input
   * Description      : �������(AR)�̃G���[�`�F�b�N(��ʗp)
   ***********************************************************************************/
  PROCEDURE check_deptinput_ar_input(
    in_receivable_id IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
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
    xx03_deptinput_ar_check_pkg.check_deptinput_ar(
      in_receivable_id,
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
      UPDATE xx03_receivable_slips xrs
      SET    xrs.request_enable_flag = 'W'
      WHERE  xrs.receivable_id = in_receivable_id;
    ELSE
      -- �x���ȊO�̏ꍇ�͐\���\�t���O��'Y'�Z�b�g
      UPDATE xx03_receivable_slips xrs
      SET    xrs.request_enable_flag = 'Y'
      WHERE  xrs.receivable_id = in_receivable_id;
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
  END check_deptinput_ar_input;
-- ver11.5.10.1.6D Add End
--
END xx03_deptinput_ar_check_pkg;
