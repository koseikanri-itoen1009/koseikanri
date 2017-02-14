CREATE OR REPLACE PACKAGE BODY xx03_je_error_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : xx03_je_error_check_pkg(body)
 * Description      : �d��G���[�`�F�b�N���ʊ֐�
 * MD.070           : �d��G���[�`�F�b�N���ʊ֐� OCSJ/BFAFIN/MD070/F313
 * Version          : 11.5.10.2.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  je_error_check            �d��G���[�`�F�b�N�F�ďo���v���O�������琧�������A
 *                            �e�G���[�`�F�b�N�T�u�֐����Ăяo���G���[�`�F�b�N���s��
 *                            ���܂��B
 *
 *  ccid_check                CCID�`�F�b�N      �FAFF��DFF�̊e�`�F�b�N�AAFF��DFF�̑g
 *                            �����`�F�b�N���s�Ȃ��܂��B
 *
 *  period_check              GL��v���ԃ`�F�b�N�FGL�L�������I�[�v������Ă��邩�`�F
 *                            �b�N���s�Ȃ��܂��B
 *
 *  aff_dff_check             AFF_DFF�`�F�b�NAFF��DFF�̊e�`�F�b�N�AAFF��DFF�̑g�����`
 *                            �F�b�N���s�Ȃ��܂��B
 *
 *  balance_check             �d��o�����X�`�F�b�N�F�d����̑ݎ؋��z�̍��v����v����
 *                            ���`�F�b�N���s�Ȃ��܂��B
 *
 *  tax_range_check           ����Ŋz���e�͈̓`�F�b�N�F�d����̏���ł����e�͈͓���
 *                            ���邩�`�F�b�N���s�Ȃ��܂��B
 *
 *  cf_balance_check          CF�o�����X�`�F�b�N�F�L���b�V���t���[���d����Ńo�����X
 *                            ���Ă��邩�`�F�b�N���s�Ȃ��܂��B
 *
 *  error_importance_check    �G���[�d��x�`�F�b�N�F���������G���[�̂����ł��d��x��
 *                            �����G���[��I�����܂��B
 *
 *  get_check_id              �V�[�P���X���ŐV�̃`�F�b�NID���擾���܂��B
 *
 *  ins_error_tbl             �G���[���e�[�u���o�͊֐��B
 *
 * Change Record
 * ------------ -------------- ------------ -------------------------------------------------
 *  Date         Ver.           Editor       Description
 * ------------ -------------- ------------ -------------------------------------------------
 *  2004/01/06   1.0            M.Yamamura   �V�K�쐬
 *  2004/01/23   1.1            M.Yamamura   TE070���{���̕s��C��
 *  2004/01/26   1.2            M.Yamamura   TE080���{���̕s��C��
 *  2004/01/29   1.3            M.Yamamura   TE080���{���̕s��C��(cf_balance_check)
 *  2004/02/04   1.4            N.Fujikawa   tax_range_check�ŋ��e�͈͈ᔽ�̍ہA
 *                                           �X�e�[�^�X���x���ɂ���悤�ɂ���
 *  2004/02/12   1.5            N.Fujikawa   1.aff_dff_check�ɂ����āA����Ȗ�DFF�̑����K�{
 *                                             �敪���fY�f�̏ꍇ�̏�����ǉ�
 *                                           2.cf_balance_check�ɂ����āA�Ώۃf�[�^��SQL������
 *                                             �er.incr_decr_reason_code is not null��̏������폜
 *  2004/02/20   1.6            N.Fujikawa   1.DFF�ŋ敪�`�F�b�N�ɂ����āA�ŋ敪��Null�̏ꍇ��
 *                                             �`�F�b�N������ύX
 *                                           2.DFF�ŋ敪�`�F�b�N�ɂ����āA����Ȗڂ̐ŋ敪�K�{�敪
 *                                             �̏�����ύX
 *  2004/02/24   1.7            N.Fujikawa   1.aff_dff_check�ɂ����āACF�g�ݍ��킹�}�X�^�̑���
 *                                             �`�F�b�N�̍ۂɁA�������R��Null�̏ꍇ���l��
 *                                           2.aff_dff_check�ɂ����āA�N�[���傪Null�̏ꍇ��
 *                                             �G���[�ɂ��Ȃ��悤�ɕύX
 *  2004/02/25   1.8            N.Fujikawa   1.tax_range_check�ɂ����āA����ł��܂܂Ȃ��Ă��ǂ�
 *                                             �d��i�ŋ��s���ȊO�̍��v�l�őݎ؃o�����X���Ƃ��
 *                                             ����d��j�́A����ŋ��e�͈͗��`�F�b�N�ŃG���[��
 *                                             �Ƃ��Ȃ��悤�ɕύX
 *  2004/02/26   1.9            N.Fujikawa   1.tax_range_check�ɂ����āA�ʉ݂��擾�ł��Ȃ�������
 *                                             �ɂ͐��x��2�ɂ���悤�ɕύX
 *  2004/02/27   1.10           K.Ikeda      1.tax_range_check�ɂ����āA�ŋ敪Null���`�F�b�N�Ώ�
 *                                             �Ƃ��A�ŗ�0%�̂Ƃ��͐ŋ��s�łȂ��s�̍��v��0�ɂȂ�
 *                                             �悤�ύX
 *                                           2.tax_range_check�ɂ����āA�ŋ��s�łȂ��s�̍��v��0
 *                                             �̂Ƃ��A�ŋ��s�̍��v��0�łȂ���΃G���[�ɂ���悤
 *                                             �ύX
 *                                           3.tax_range_check�̋��e�͈͗��`�F�b�N�ɂ����āA���z
 *                                             �̐�Βl�łȂ����z�̗��̐�Βl�Ŕ��f����悤�ύX
 *  2004/12/09   1.11           H.Umetsu     aff_dff_check�ɂ����āA�G���[���b�Z�[�W����AFF�Z�O
 *                                           �����g���̂����ʂ���擾����悤�ɕύX
 *  2004/12/27   1.12           T.Shigekawa  xx03_error_info�\��dr_cr�J������ǉ��B�ݎ؋敪��
 *                                           �i�[����悤�ɕύX
 *  2005/10/20   11.5.10.1.5    Y.Matsumura  ����Ȗڃ}�X�^�̐ŋ敪�K�{�敪�ƐŃR�[�h�}�X�^��
 *                                           �W�v�敪�̑g�������A2-2,2-null,3-1,3-null,9-1,9-2,
 *                                           null-1,null-2�ŃG���[�ƂȂ�悤�ɏC��
 *  2005/12/15   11.5.10.1.6    A.Okusa      �ŋ��R�[�h�̗L���`�F�b�N�Ή�
 *                                           �ŋ敪�̃}�X�^�`�F�b�N�ɐŋ敪�̗L������ǉ��B
 *                                           ����Ŋz���e�͈̓`�F�b�N�p�J�[�\������
 *                                           �ŋ��R�[�h�̗L���`�F�b�N�ǉ��B
 *  2005/12/28   11.5.10.1.6B   S.Morisawa   AFF�̊e�Z�O�����g�̒l�`�F�b�N�ɂ�����
 *                                           ��]�L�̋��£���Y��̂��̂̂݃`�F�b�NOK�Ƃ��A
 *                                           �Y��ȊO�i�N��j�̏ꍇ�̓G���[�Ƃ��郍�W�b�N��ǉ�
 *  2006/01/16   11.5.10.1.6C   S.Morisawa   1.CF�g�����}�X�^�擾SQL�̏����ɉ�v����ID��ǉ�
 *                                           2.�������RNull�̎���CF�g�����}�X�^�`�F�b�N���s���悤�C��
 *  2005/10/20   11.5.10.1.6D   Y.Matsumura  �ʉ݃`�F�b�N��GL�L�����������Ɋ܂߂�悤�C��
 *  2006/10/04   11.5.10.2.6    S.Morisawa   �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                                           �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2015/03/24   11.5.10.2.7    Y.Shoji      ����Ŋz���e�͈̓`�F�b�N�J�[�\���̉�ЃR�[�h��
 *                                           �Œ�l�F001�i�{�Ёj�ɕύX����B
 *  2015/12/17   11.5.10.2.8    S.Niki       [E_�{�ғ�_13421]aff_dff_check�ɒ��~�ڋq�`�F�b�N�ǉ�
 *  2017/01/31   11.5.10.2.9    Y.Shoji      [E_�{�ғ�_13997]aff_dff_check�̒��~�ڋq�`�F�b�N��
 *                                           �ޑK�Ώیڋq�`�F�b�N�ɕύX�B
 *
 *****************************************************************************************/
--
--
  -- ===============================
  -- *** �O���[�o���萔 ***
  -- ===============================
--
  -- ===============================
  -- �O���[�o���E�J�[�\��
  -- ===============================
  CURSOR xx03_error_checks_cur(
    in_check_id       IN  xx03_error_checks.check_id%TYPE   -- 1.�`�F�b�NID
  )
  IS
    SELECT
      xec.check_id              ,-- �`�F�b�NID
      xec.journal_id            ,-- �d��ID
      xec.line_number           ,-- �s�ԍ�
      xec.gl_date               ,-- GL�L����
      xec.period_name           ,-- GL��v����
      xec.currency_code         ,-- �ʉ�
      xec.code_combination_id   ,-- CCID
      xec.segment1              ,-- ���
      xec.segment2              ,-- ����
      xec.segment3              ,-- ����Ȗ�
      xec.segment4              ,-- �⏕�Ȗ�
      xec.segment5              ,-- �����
      xec.segment6              ,-- ���Ƌ敪
      xec.segment7              ,-- �v���W�F�N�g
      xec.segment8              ,-- �\��
      xec.tax_code              ,-- �ŋ敪
      xec.incr_decr_reason_code ,-- �������R
      xec.slip_number           ,-- �`�[�ԍ�
      xec.input_department      ,-- �N�[����
      xec.input_user            ,-- �`�[���͎�
      xec.orig_slip_number      ,-- �C�����`�[�ԍ�
      xec.recon_reference       ,-- �����Q��
      xec.entered_dr            ,-- �ؕ����z
      xec.entered_cr            ,-- �ݕ����z
-- �ǉ� ver1.12 �J�n
      decode(xec.entered_dr,null,
             decode(xec.entered_cr,null,' ','CR'),
             decode(xec.entered_cr,null,'DR',' ')) as dr_cr, --�ݎ؋敪
-- �ǉ� ver1.12 �I��
      xec.attribute_category    ,-- DFF�J�e�S��
      xec.attribute1            ,-- DFF�\��1
      xec.attribute2            ,-- DFF�\��2
      xec.attribute3            ,-- DFF�\��3
      xec.attribute4            ,-- DFF�\��4
      xec.attribute5            ,-- DFF�\��5
      xec.attribute6            ,-- DFF�\��6
      xec.attribute7            ,-- DFF�\��7
      xec.attribute8            ,-- DFF�\��8
      xec.attribute9            ,-- DFF�\��9
      xec.attribute10           ,-- DFF�\��10
      xec.attribute11           ,-- DFF�\��11
      xec.attribute12           ,-- DFF�\��12
      xec.attribute13           ,-- DFF�\��13
      xec.attribute14           ,-- DFF�\��14
      xec.attribute15           ,-- DFF�\��15
      xec.attribute16           ,-- DFF�\��16
      xec.attribute17           ,-- DFF�\��17
      xec.attribute18           ,-- DFF�\��18
      xec.attribute19           ,-- DFF�\��19
      xec.attribute20           ,-- DFF�\��20
      xec.created_by            ,-- �쐬��
      xec.creation_date         ,-- �쐬��
      xec.last_updated_by       ,-- �ŏI�X�V��
      xec.last_update_date      ,-- �ŏI�X�V��
      xec.last_update_login     ,-- �ŏI���O�C��ID
      xec.request_id            ,-- �v��ID
      xec.program_application_id,-- �v���O�����A�v���P�[�V����ID
      xec.program_update_date   ,-- �v���O�����X�V��
      xec.program_id             -- �v���O����ID
  FROM xx03_error_checks xec
  WHERE xec.check_id = in_check_id
  ;

  --�G���[�o�͊֐�
  FUNCTION ins_error_tbl(
    in_check_id     IN  NUMBER          , --1.�`�F�b�NID
    iv_journal_id   IN  VARCHAR2        , --2.�d��L�[
    in_line_number  IN  NUMBER          , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
    iv_dr_cr        IN  VARCHAR2        , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
    iv_error_code   IN  VARCHAR2        , --5.�G���[�R�[�h
    it_tokeninfo    IN  TOKENINFO_TTYPE , --6.�g�[�N�����
    iv_status       IN  VARCHAR2        , --7.�X�e�[�^�X
    iv_application  IN  VARCHAR2 DEFAULT 'XX03' )
    RETURN VARCHAR2;

--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : je_error_check
   * Description      : �d��G���[�`�F�b�N
   ***********************************************************************************/
  FUNCTION je_error_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.je_error_check'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    --�����`�F�b�N�h�c���݊m�F�p�J�[�\��
    CURSOR xx03_error_info_cur(
          in_check_id         IN  xx03_error_info.check_id%TYPE           -- 1.�`�F�b�NID
    ) IS
    SELECT
      count('X') recs
    FROM
      xx03_error_info
    WHERE
      check_id =in_check_id
    ;
    xx03_error_info_rec           xx03_error_info_cur%ROWTYPE;              --�e�[�u�����R�[�h

    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    chk_para_expt           EXCEPTION;  --�p�����[�^�`�F�b�N��O
    chk_outdata_expt        EXCEPTION;  --�����f�[�^���ݗ�O

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************

    --RETURN cv_status_success;

    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RAISE chk_para_expt;
    END IF;

    --2.  �����`�F�b�N�h�c���݃`�F�b�N
    --�o�͐��xx03_error_info�@ (�G���[���e�[�u��)�Ƀp�����[�^�̃`�F�b�N�h�c�̊������R�[�h
    --�����݂��邩���`�F�b�N���܂��B

    -- 2.�G���[���e�[�u���Ǎ���
    OPEN xx03_error_info_cur(
        in_check_id
    );
    FETCH xx03_error_info_cur INTO xx03_error_info_rec;

    IF xx03_error_info_cur%NOTFOUND THEN
      --COUNT�֐��Ȃ̂ł��蓾�Ȃ��P�[�X
      --�J�[�\���̃N���[�Y
      CLOSE xx03_error_info_cur;
      RETURN cv_status_error;
    ELSE
      IF xx03_error_info_rec.recs != 0  THEN
        --count(�eX�f) > 0 �ł���Ί����f�[�^���ݗ�O(chk_outdata_expt)���Ăт����܂��B

        CLOSE xx03_error_info_cur;
        RAISE chk_outdata_expt;
      END IF;
    END IF;
    CLOSE xx03_error_info_cur;

    --3.  CCID�`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.ccid_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --4.  GL��v���ԃ`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.period_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --5.  AFF�EDFF�`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.aff_dff_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --6.  �d��o�����X�`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.balance_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --7.  ����ŋ��e�͈̓`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.tax_range_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --8.  CF�o�����X�`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.cf_balance_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�֐��߂�R�[�h�Ƀp�����[�^�G���[(�eP�f)���Ԃ��Ă����ꍇ�́A�p�����[�^�Ɉȉ��̒l���
    --�肵�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u����
    --�o�͂��܂��B

    IF lv_ret = cv_status_param_err THEN
      lv_error_code   := 'APP-XX03-03010';
      lt_tokeninfo.DELETE;
      lt_tokeninfo(0).token_name := 'TOK_XX03_PARM_NOT_SPECIFY';
      lt_tokeninfo(0).token_value := 'CHECK_ID';
      lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
          in_check_id                       , --1.�`�F�b�NID
          ' '                               , --2.�d��L�[
          0                                 , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
          ' '                               , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
          lv_error_code   ,                   --5.�G���[�R�[�h
          lt_tokeninfo    ,                   --6.�g�[�N�����
          cv_status_param_err       );
      lt_tokeninfo.DELETE;
    END IF;

    --9.  �G���[�d��x�`�F�b�N�N��
    lv_ret := xx03_je_error_check_pkg.error_importance_check(
        in_check_id      --1.�`�F�b�NID
    );

    --�߂�l�ɃG���[�d��x�`�F�b�N�Ŏ擾�����߂�l��ݒ肵�A�������I�����܂�
    lv_ret_status := lv_ret ;

--
    RETURN lv_ret_status;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN chk_para_expt THEN       --�p�����[�^�`�F�b�N��O
      RETURN cv_status_param_err; --'P'
    WHEN chk_outdata_expt THEN    --�����f�[�^���ݗ�O
      RETURN cv_status_error;     --'E'
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END je_error_check;
--
  /**********************************************************************************
   * Procedure Name   : ccid_check
   * Description      : CCID�`�F�b�N
   ***********************************************************************************/
  FUNCTION ccid_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.ccid_check'; -- �v���O������

    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ln_set_of_books_id              gl_sets_of_books.set_of_books_id%TYPE;      --����ID
    ln_chart_of_accounts_id         gl_sets_of_books.chart_of_accounts_id%TYPE; --����̌nID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --�G���[�`�F�b�N�e�[�u�����R�[�h

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    lv_segment1                     gl_code_combinations.segment1                     %TYPE;--�Z�O�����g1�@�i��Ёj
    lv_segment2                     gl_code_combinations.segment2                     %TYPE;--�Z�O�����g2�@�i����j
    lv_segment3                     gl_code_combinations.segment3                     %TYPE;--�Z�O�����g3�@�i����Ȗځj
    lv_segment4                     gl_code_combinations.segment4                     %TYPE;--�Z�O�����g4�@�i�⏕�Ȗځj
    lv_segment5                     gl_code_combinations.segment5                     %TYPE;--�Z�O�����g5�@�i�����j
    lv_segment6                     gl_code_combinations.segment6                     %TYPE;--�Z�O�����g6�@�i���Ƌ敪�j
    lv_segment7                     gl_code_combinations.segment7                     %TYPE;--�Z�O�����g7�@�i�v���W�F�N�g�j
    lv_segment8                     gl_code_combinations.segment8                     %TYPE;--�Z�O�����g8�@�i�\���j
    lv_enabled_flag                 gl_code_combinations.enabled_flag                 %TYPE;--�g�p�\
    lv_detail_posting_allowed_flag  gl_code_combinations.detail_posting_allowed_flag  %TYPE;--�]�L�̋���
    lv_start_date_active            gl_code_combinations.start_date_active            %TYPE;--�L���J�n��
    lv_end_date_active              gl_code_combinations.end_date_active              %TYPE;--�L���I����
    ln_code_combination_id          gl_code_combinations.code_combination_id          %TYPE;--CCID

    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    local_continue       EXCEPTION;

  --
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
  -- ***********************************************
  -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
  -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2. ����ID�擾
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID');

    -- 3. ����̌nID�擾
    SELECT gsob.chart_of_accounts_id
    INTO   ln_chart_of_accounts_id
    FROM   gl_sets_of_books gsob
    WHERE  gsob.set_of_books_id = ln_set_of_books_id
    ;
    --4.�G���[�`�F�b�N�e�[�u���ǂݍ���
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.�`�F�b�NID
    );

    <<ccid_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN

        --1)GL�L�����`�F�b�N
        --  GL�L������NULL�̏ꍇ�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G
        --  ���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.gl_date IS NULL THEN
          lv_error_code   := 'APP-XX03-03042';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error       );
          lt_tokeninfo.DELETE;

          --�߂�l�X�V
          lv_ret_status := cv_status_error;
          --�����R�[�h���������܂��B
          RAISE local_continue;
        END IF;

        --2)�Z�O�����g�l(SEGMENT�P�`8)�ɒl���ݒ肳��Ă��郌�R�[�h�����肵�܂��B

        IF  xx03_error_checks_rec. segment1 IS NULL AND
            xx03_error_checks_rec. segment2 IS NULL AND
            xx03_error_checks_rec. segment3 IS NULL AND
            xx03_error_checks_rec. segment4 IS NULL AND
            xx03_error_checks_rec. segment5 IS NULL AND
            xx03_error_checks_rec. segment6 IS NULL AND
            xx03_error_checks_rec. segment7 IS NULL AND
            xx03_error_checks_rec. segment8 IS NULL THEN
            --�uCCID�W�J�v�����s���܂��B
          BEGIN
            SELECT
              segment1,                       --�Z�O�����g1�@�i��Ёj
              segment2,                       --�Z�O�����g2�@�i����j
              segment3,                       --�Z�O�����g3�@�i����Ȗځj
              segment4,                       --�Z�O�����g4�@�i�⏕�Ȗځj
              segment5,                       --�Z�O�����g5�@�i�����j
              segment6,                       --�Z�O�����g6�@�i���Ƌ敪�j
              segment7,                       --�Z�O�����g7�@�i�v���W�F�N�g�j
              segment8,                       --�Z�O�����g8�@�i�\���j
              enabled_flag,                   --�g�p�\
              detail_posting_allowed_flag,    --�]�L�̋���
              start_date_active,              --�L���J�n��
              end_date_active                 --�L���I����
            INTO
              lv_segment1,                    --�Z�O�����g1�@�i��Ёj
              lv_segment2,                    --�Z�O�����g2�@�i����j
              lv_segment3,                    --�Z�O�����g3�@�i����Ȗځj
              lv_segment4,                    --�Z�O�����g4�@�i�⏕�Ȗځj
              lv_segment5,                    --�Z�O�����g5�@�i�����j
              lv_segment6,                    --�Z�O�����g6�@�i���Ƌ敪�j
              lv_segment7,                    --�Z�O�����g7�@�i�v���W�F�N�g�j
              lv_segment8,                    --�Z�O�����g8�@�i�\���j
              lv_enabled_flag,                --�g�p�\
              lv_detail_posting_allowed_flag, --�]�L�̋���
              lv_start_date_active,           --�L���J�n��
              lv_end_date_active              --�L���I����
            FROM
              gl_code_combinations  --����Ȗڑg�����e�[�u��
            WHERE
              code_combination_id  =  xx03_error_checks_rec.code_combination_id
            ;
            --�E�f�[�^���ݎ�
            --�ȉ��̏�����S�Ė����������`�F�b�N���܂��B�������Ȃ��ꍇ�́A�G���[��
            --��e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            --�E[2].�g�p�\(ENABLED_FLAG = �eY�f)�B
            --�E[2].�]�L�̋���(DETAIL_POSTING_ALLOWED_FLAG = �eY�f)
            --�E[2].�L���J�n��(START_DATE_ACTIVE)��Null  or�@[2].�L���J�n����[1].GL�L�����B
            --�E[2].�L���I����(END_DATE_ACTIVE)��Null or [2].�L���I������[1].GL�L�����B

            IF NOT ((lv_enabled_flag = 'Y') AND
                    (lv_detail_posting_allowed_flag = 'Y') AND
                    ((lv_start_date_active IS NULL ) OR (lv_start_date_active <= xx03_error_checks_rec.gl_date )) AND
                    ((lv_end_date_active   IS NULL ) OR (lv_end_date_active   >= xx03_error_checks_rec.gl_date ))) THEN

              lv_error_code   := 'APP-XX03-03014';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_INVALID_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_INVALID_VALUE';
              lt_tokeninfo(1).token_value := TO_CHAR(xx03_error_checks_rec.code_combination_id);
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error       );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
            ELSE
              --���펞�A�ȉ������s���G���[�`�F�b�N�e�[�u�����X�V���܂��B
              UPDATE
                xx03_error_checks   --�G���[�`�F�b�N�e�[�u��
              SET
                segment1  = lv_segment1,                    --�Z�O�����g1�@�i��Ёj
                segment2  = lv_segment2,                    --�Z�O�����g2�@�i����j
                segment3  = lv_segment3,                    --�Z�O�����g3�@�i����Ȗځj
                segment4  = lv_segment4,                    --�Z�O�����g4�@�i�⏕�Ȗځj
                segment5  = lv_segment5,                    --�Z�O�����g5�@�i�����j
                segment6  = lv_segment6,                    --�Z�O�����g6�@�i���Ƌ敪�j
                segment7  = lv_segment7,                    --�Z�O�����g7�@�i�v���W�F�N�g�j
                segment8  = lv_segment8                     --�Z�O�����g8�@�i�\���j
              WHERE
                   check_id     = xx03_error_checks_rec.check_id      --�`�F�b�NID
              and  journal_id   = xx03_error_checks_rec.journal_id    --�d��ID
              and  line_number  = xx03_error_checks_rec.line_number   --�s�ԍ�
              ;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --�E�f�[�^�񑶍ݎ�
              --  �G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
              lv_error_code   := 'APP-XX03-03013';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_NOT_GET_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_NOT_GET_VALUE';

              lt_tokeninfo(1).token_value := TO_CHAR(xx03_error_checks_rec.code_combination_id);
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error       );
              lt_tokeninfo.DELETE;

              --�߂�l�X�V
              lv_ret_status := cv_status_error;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        ELSE
            --�u�Z�O�����g�l�`�F�b�N�v
          BEGIN
            SELECT
              code_combination_id,          --CCID
              enabled_flag,                 --�g�p�\
              detail_posting_allowed_flag,  --�]�L�̋���
              start_date_active,            --�L���J�n��
              end_date_active               --�L���I����
            INTO
              ln_code_combination_id,           --CCID
              lv_enabled_flag,                  --�g�p�\
              lv_detail_posting_allowed_flag,   --�]�L�̋���
              lv_start_date_active,             --�L���J�n��
              lv_end_date_active                --�L���I����
            FROM
              gl_code_combinations  --����Ȗڑg�����e�[�u��
            WHERE
              chart_of_accounts_id  = ln_chart_of_accounts_id   --�ϐ�. ����̌nID
              and segment1 = xx03_error_checks_rec.segment1
              and segment2 = xx03_error_checks_rec.segment2
              and segment3 = xx03_error_checks_rec.segment3
              and segment4 = xx03_error_checks_rec.segment4
              and segment5 = xx03_error_checks_rec.segment5
              and segment6 = xx03_error_checks_rec.segment6
              and segment7 = xx03_error_checks_rec.segment7
              and segment8 = xx03_error_checks_rec.segment8
              ;
            --�E�f�[�^���ݎ�
            --  �ȉ��̏�����S�Ė����������`�F�b�N���܂��B�������Ȃ��ꍇ�́A�G���[���e�[�u���o��
            --  �T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            --  �E[2]�f.�g�p�\(ENABLED_FLAG = �eY�f)�B
            --  �E[2]�f.�]�L�̋���(DETAIL_POSTING_ALLOWD_FLAG = �eY�f)
            --  �E[2]�f.�L���J�n��(START_DATE_ACTIVE)��Null  or�@[2]�f.�L���J�n����[1].GL�L�����B
            --  �E[2]�f.�L���I����(END_DATE_ACTIVE)��Null or [2]�f.�L���I������[1].GL�L�����B

            IF NOT ((lv_enabled_flag = 'Y') AND
                    (lv_detail_posting_allowed_flag = 'Y') AND
                    ((lv_start_date_active IS NULL ) OR (lv_start_date_active <= xx03_error_checks_rec.gl_date )) AND
                    ((lv_end_date_active   IS NULL ) OR (lv_end_date_active   >= xx03_error_checks_rec.gl_date ))) THEN

              lv_error_code   := 'APP-XX03-03014';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_INVALID_KEY';
              lt_tokeninfo(0).token_value := 'CCID';
              lt_tokeninfo(1).token_name := 'TOK_XX03_INVALID_VALUE';
              lt_tokeninfo(1).token_value := TO_CHAR(ln_code_combination_id);--�擾��������\��
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error       );
              lt_tokeninfo.DELETE;

              --�߂�l�X�V
              lv_ret_status := cv_status_error;
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --�E�f�[�^�񑶍ݎ�
              --  �����R�[�h���������܂��B
              NULL;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;

        END IF;

      EXCEPTION
        WHEN local_continue THEN
          NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR
            (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP ccid_check_loop;

    --�J�[�\���̃N���[�Y
    CLOSE xx03_error_checks_cur;
--
    RETURN lv_ret_status;
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
  END ccid_check;
--
  /**********************************************************************************
   * Procedure Name   : period_check
   * Description      : GL��v���ԃ`�F�b�N
   ***********************************************************************************/
  FUNCTION period_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.period_check'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ln_application_id               gl_period_statuses.application_id%TYPE;     --�A�v���P�[�V����ID
    ln_set_of_books_id              gl_period_statuses.set_of_books_id%TYPE;    --����ID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --�G���[�`�F�b�N�e�[�u�����R�[�h

    lv_periond_name                 gl_period_statuses.period_name%TYPE;        --��v���Ԗ�
    lv_closing_status               gl_period_statuses.closing_status%TYPE;     --�N���[�W���O�X�e�[�^�X

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l


    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    local_continue       EXCEPTION;
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  GL�A�v���P�[�V����ID�擾
    ln_application_id := xx03_application_pkg.get_application_id_f('SQLGL') ;

    --3.  ����ID�擾
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    --4.�G���[�`�F�b�N�e�[�u���ǂݍ���
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.�`�F�b�NID
    );

    <<period_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN
        --1)[1].GL��v���Ԃ�NULL�ł������ꍇ
        --�uGL�L�����̉�v���Ԑݒ�Ɖ�v���Ԃ̃X�e�[�^�X�`�F�b�N�v�����s���܂��B
        --  �ȊO��
        --�u��v���Ԃ̃X�e�[�^�X�`�F�b�N�v�����s���܂��B

        IF xx03_error_checks_rec.period_name is NULL THEN

          --�uGL�L�����̉�v���Ԑݒ�Ɖ�v���Ԃ̃X�e�[�^�X�`�F�b�N�v

          --1)GL�L�����`�F�b�N
          --  GL�L������NULL�̏ꍇ�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G
          --  ���[���e�[�u�����o�͂��܂��B
          IF xx03_error_checks_rec.gl_date IS NULL THEN
            lv_error_code   := 'APP-XX03-03042';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error       );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
            --�����R�[�h���������܂��B
            RAISE local_continue;
          END IF;

          --1)GL_��v���ԃX�e�[�^�X�e�[�u�����擾���܂��B
          BEGIN
            SELECT
            period_name,                --��v���Ԗ�
            closing_status              --�N���[�W���O�X�e�[�^�X
            INTO
            lv_periond_name,
            lv_closing_status
            FROM  gl_period_statuses
            WHERE
                application_id          =  ln_application_id
            and set_of_books_id         =  ln_set_of_books_id
            and start_date              <= xx03_error_checks_rec.gl_date
            and end_date                >= xx03_error_checks_rec.gl_date
            and adjustment_period_flag  !='Y'  -- �������Ԃł͂Ȃ��B
            ;

            --�f�[�^���ݎ�
            --�ȉ��̏�����S�Ė����������`�F�b�N���܂��B�������Ȃ��ꍇ�́A�G���[���e�[�u���o�̓T�u�֐�
            --(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            --�E�ϐ�.�N���[�W���O�X�e�[�^�X = �I�[�v��(�eO�f) or����t���͉\(�eF�f)

            IF NOT  ( lv_closing_status in ('O','F') ) THEN
              lv_error_code   := 'APP-XX03-03016';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := lv_periond_name;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
              --�����R�[�h���������܂��B
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              --�E�f�[�^�񑶍ݎ�
              --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
              lv_error_code   := 'APP-XX03-03015';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_GL_DATE';
              lt_tokeninfo(0).token_value := TO_CHAR(xx03_error_checks_rec.gl_date,'YYYY/MM/DD');

              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
              --�����R�[�h���������܂��B
              RAISE local_continue;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        ELSE
          --�u��v���Ԃ̃X�e�[�^�X�`�F�b�N�v�����s���܂��B
          --1)GL_��v���ԃX�e�[�^�X�e�[�u�����擾���܂��B
          BEGIN
            SELECT
            closing_status              --�N���[�W���O�X�e�[�^�X
            INTO
            lv_closing_status
            FROM  gl_period_statuses
            WHERE
                application_id          =  ln_application_id
            and set_of_books_id         =  ln_set_of_books_id
            and period_name             =   xx03_error_checks_rec.period_name
            ;

            --�f�[�^���ݎ�
            --�ȉ��̏�����S�Ė����������`�F�b�N���܂��B�������Ȃ��ꍇ�́A�G���[���e�[�u���o�̓T�u�֐�
            --(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            --�E�ϐ�.�N���[�W���O�X�e�[�^�X = �I�[�v��(�eO�f) or����t���͉\(�eF�f)

            IF NOT  ( lv_closing_status in ('O','F') ) THEN
              lv_error_code   := 'APP-XX03-03016';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := xx03_error_checks_rec.period_name;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
              --�����R�[�h���������܂��B
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --�E�f�[�^�񑶍ݎ�
              --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
              lv_error_code   := 'APP-XX03-03017';
              lt_tokeninfo.DELETE;
              lt_tokeninfo(0).token_name := 'TOK_XX03_PERIOD_NAME';
              lt_tokeninfo(0).token_value := xx03_error_checks_rec.period_name;

              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
              --�����R�[�h���������܂��B
              RAISE local_continue;

            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
                (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
          END;
        END IF;
      EXCEPTION
      WHEN local_continue THEN
          NULL;
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR
          (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP period_check_loop;

    --�J�[�\���̃N���[�Y
    CLOSE xx03_error_checks_cur;

--
    RETURN lv_ret_status;
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
  END period_check;
--
  /**********************************************************************************
   * Procedure Name   : aff_dff_check
   * Description      : AFF�EDFF�`�F�b�N
   ***********************************************************************************/
  FUNCTION aff_dff_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.aff_dff_check'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
-- Ver11.5.10.2.8 Add Start
    --���b�Z�[�W
    cv_msg_cust_stop_err            CONSTANT VARCHAR2(30) := 'APP-XX03-03090';  --���~�ڋq�`�F�b�N�G���[���b�Z�[�W
    --�v���t�@�C��
    cv_prof_aff3_change             CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_CHANGE';  --XXCOK:����Ȗ�_�������i�ޑK�j
    --�g�[�N��
    cv_tkn_cust_num                 CONSTANT VARCHAR2(30) := 'TOK_XX03_CUST_NUM';   --�ڋq�R�[�h
-- Ver11.5.10.2.9 Add Start
    cv_tkn_cust_sts                 CONSTANT VARCHAR2(30) := 'TOK_XX03_CUST_STS';   --�ڋq�X�e�[�^�X
    --�Q�ƃ^�C�v�R�[�h
    cv_lkp_chg_ng_cust_sts          CONSTANT VARCHAR2(30) := 'XX03_CHG_NG_CUST_STS';  --�ޑK�ΏۊO�ڋq�X�e�[�^�X
    --�`�F�b�N�p
    cv_flag_n                       CONSTANT VARCHAR2(1)  := 'N';                   --�t���O�FN
-- Ver11.5.10.2.9 Add End
-- Ver11.5.10.2.9 Del Start
--    --�Œ�l
--    cv_cust_status_stop             CONSTANT VARCHAR2(2)  := '90';              --�ڋq�X�e�[�^�X�F90(���~���ٍ�)
-- Ver11.5.10.2.9 Del End
    --�ϐ�
    lt_account_change               xx03_companies_v.flex_value%TYPE;           --����Ȗ�_�������i�ޑK�j
-- Ver11.5.10.2.8 Add End
    ln_set_of_books_id              gl_period_statuses.set_of_books_id%TYPE;    --����ID
    xx03_error_checks_rec           xx03_error_checks_cur%ROWTYPE;              --�G���[�`�F�b�N�e�[�u�����R�[�h

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    lv_is_accounts_exists           boolean;                                    --����Ȗڑ��݃t���O(TRUE:���݁AFALSE:�ȊO)

    ln_set_of_books_name            fnd_descr_flex_col_usage_vl.descriptive_flexfield_name%TYPE;
                                                                                --���떼
    ln_errbuf                       VARCHAR2(5000);                             --�G���[�o�b�t�@
    ln_errmsg                       VARCHAR2(5000);                             --�G���[���b�Z�[�W
    ln_retcode                      VARCHAR2(1);                                --���^�[���R�[�h

    ln_application_id               gl_period_statuses.application_id%TYPE;     --�A�v���P�[�V����ID



    --GL��v����
    CURSOR gl_sets_of_books_cur(
        in_set_of_books_id  IN  gl_sets_of_books.set_of_books_id%TYPE   -- 1.(����ID)
    ) IS
      SELECT
        a.*
      FROM gl_sets_of_books a
      WHERE
          a.set_of_books_id = in_set_of_books_id
      ;

    gl_sets_of_books_rec            gl_sets_of_books_cur%ROWTYPE;             --�e�[�u�����R�[�h

    --��Ѓ}�X�^
    CURSOR xx03_companies_v_cur(
        iv_flex_value       IN  xx03_companies_v.flex_value%TYPE,   -- 1.(���)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_companies_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_companies_v_rec            xx03_companies_v_cur%ROWTYPE;             --�e�[�u�����R�[�h

    --����Ȗڃ}�X�^
    CURSOR xx03_accounts_v_cur(
        iv_flex_value       IN  xx03_accounts_v.flex_value%TYPE,    -- 1.(���)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_accounts_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      ;

    xx03_accounts_v_rec           xx03_accounts_v_cur%ROWTYPE;              --�e�[�u�����R�[�h

    --����}�X�^
    CURSOR xx03_departments_v_cur(
        iv_flex_value       IN  xx03_departments_v.flex_value%TYPE, -- 1.(����)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM  xx03_departments_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_departments_v_rec            xx03_departments_v_cur%ROWTYPE;             --�e�[�u�����R�[�h

    --�⏕�Ȗڃ}�X�^
    CURSOR xx03_sub_accounts_v_cur(
        iv_flex_value       IN  xx03_sub_accounts_v.flex_value%TYPE,-- 1.(�⏕�Ȗ�)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE,     -- 2.GL�L����
        iv_segment3         IN  xx03_error_checks.segment3%TYPE     -- 3.����Ȗ�
    ) IS
      SELECT
        a.*
      FROM xx03_sub_accounts_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND a.parent_flex_value_low = iv_segment3
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;
      xx03_sub_accounts_v_rec           xx03_sub_accounts_v_cur%ROWTYPE;              --�e�[�u�����R�[�h

    --�����}�X�^
    CURSOR xx03_partners_v_cur(
        iv_flex_value       IN  xx03_partners_v.flex_value%TYPE,    -- 1.(�����)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_partners_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_partners_v_rec           xx03_partners_v_cur%ROWTYPE;              --�e�[�u�����R�[�h

    --���Ƌ敪�}�X�^
    CURSOR xx03_business_types_v_cur(
        iv_flex_value       IN  xx03_business_types_v.flex_value%TYPE,    -- 1.(���Ƌ敪)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE            -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_business_types_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_business_types_v_rec           xx03_business_types_v_cur%ROWTYPE;              --�e�[�u�����R�[�h

    --�v���W�F�N�g�}�X�^
    CURSOR xx03_projects_v_cur(
        iv_flex_value       IN  xx03_projects_v.flex_value%TYPE,    -- 1.(�v���W�F�N�g)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_projects_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_projects_v_rec           xx03_projects_v_cur%ROWTYPE;              --�e�[�u�����R�[�h

    --�\���}�X�^
    CURSOR xx03_futures_v_cur(
        iv_flex_value       IN  xx03_futures_v.flex_value%TYPE,     -- 1.(�\��)
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE      -- 2.GL�L����
    ) IS
      SELECT
        a.*
      FROM xx03_futures_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.summary_flag      = 'N'
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND SUBSTRB(a.compiled_value_attributes,3,1) = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_futures_v_rec            xx03_futures_v_cur%ROWTYPE;             --�e�[�u�����R�[�h

  --�ŋ敪�}�X�^
    CURSOR xx03_tax_codes_v_cur(
        -- Ver11.5.10.1.6 2005/12/15 Change Start
        --iv_name             IN  xx03_tax_codes_v.name%TYPE,           -- 1.�ŋ敪
        --in_set_of_books_id  IN  xx03_tax_codes_v.set_of_books_id%TYPE -- 2.����ID
        iv_name             IN  xx03_tax_codes_v.name%TYPE,           -- 1.�ŋ敪
        in_set_of_books_id  IN  xx03_tax_codes_v.set_of_books_id%TYPE,-- 2.����ID
        id_gl_date          IN  xx03_error_checks.gl_date%TYPE        -- 3.GL�L����
        -- Ver11.5.10.1.6 2005/12/15 Change End
    ) IS
      SELECT
        a.*
      FROM xx03_tax_codes_v a
      WHERE
          a.name = iv_name
      AND a.set_of_books_id   = in_set_of_books_id
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      AND (a.start_date    IS NULL or a.start_date     <= id_gl_date )
      AND (a.inactive_date IS NULL or a.inactive_date  >= id_gl_date )
      -- Ver11.5.10.1.6 2005/12/15 Add End
      ;

    xx03_tax_codes_v_rec          xx03_tax_codes_v_cur%ROWTYPE;             --�e�[�u�����R�[�h

  --�������R�}�X�^
    CURSOR xx03_incr_decr_reasons_v_cur(
        iv_ffl_flex_value         IN  xx03_incr_decr_reasons_v.ffl_flex_value%TYPE  -- 1.�������R
    ) IS
      SELECT
        a.*
      FROM xx03_incr_decr_reasons_v a
      WHERE
          a.ffl_flex_value = iv_ffl_flex_value
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND a.summary_flag      = 'N'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_incr_decr_reasons_v_rec    xx03_incr_decr_reasons_v_cur%ROWTYPE;     --�e�[�u�����R�[�h

  --CF�g�����}�X�^
    CURSOR xx03_cf_combinations_cur(
        iv_account_code           IN  xx03_error_checks.segment3%TYPE,              -- 1.����Ȗ�
        iv_incr_decr_reason_code  IN  xx03_error_checks.incr_decr_reason_code%TYPE, -- 2.�������R
        id_gl_date                IN  xx03_error_checks.gl_date%TYPE                -- 3.GL�L����
      ) IS
        SELECT
        a.*
      FROM xx03_cf_combinations a
      WHERE
          a.account_code = iv_account_code
-- �ύX 1.7 BEGIN
--      AND a.incr_decr_reason_code = iv_incr_decr_reason_code
      AND NVL(a.incr_decr_reason_code, '#####') = NVL(iv_incr_decr_reason_code, '#####')
-- �ύX 1.7 END
      AND a.enabled_flag      = 'Y'
      AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      -- Ver11.5.10.1.6C 2006/01/16 Add Start
      AND a.set_of_books_id = xx00_profile_pkg.value ('GL_SET_OF_BKS_ID')
      -- Ver11.5.10.1.6C 2006/01/16 Add End
      ;

    xx03_cf_combinations_rec    xx03_cf_combinations_cur%ROWTYPE;     --�e�[�u�����R�[�h

    --����}�X�^(�N�[���匟���p)
    CURSOR xx03_departments_v_cur2(
        iv_flex_value       IN  xx03_departments_v.flex_value%TYPE  -- 1.(����)
    ) IS
      SELECT
        a.*
      FROM  xx03_departments_v a
      WHERE
          a.flex_value = iv_flex_value
      AND a.enabled_flag      = 'Y'
      -- Ver11.5.10.1.6B 2005/12/28 Add Start
      AND a.summary_flag      = 'N'
      -- Ver11.5.10.1.6B 2005/12/28 Add End
      ;

    xx03_departments_v_rec2   xx03_departments_v_cur2%ROWTYPE;      --�e�[�u�����R�[�h

    --���[�U�}�X�^
    CURSOR xx03_users_v_cur(
        iv_user_name      IN  xx03_error_checks.input_user%TYPE -- 1.�`�[���͎�
    ) IS
      SELECT
        a.*
      FROM  xx03_users_v a
      WHERE
          a.user_name = iv_user_name
--      AND a.enabled_flag      = 'Y'
      ;

    xx03_users_v_rec    xx03_users_v_cur%ROWTYPE;     --�e�[�u�����R�[�h

    --�l�Z�b�g�擾
    CURSOR fnd_descr_flex_col_cur(
        in_application_id           IN  fnd_descr_flex_col_usage_vl.application_id%TYPE,                -- 1.�A�v���P�[�V����ID
        iv_descriptive_flex_context IN  fnd_descr_flex_col_usage_vl.descriptive_flex_context_code%TYPE  -- 2.���떼
    ) IS
      SELECT
        a.*
      FROM  fnd_descr_flex_col_usage_vl a
      WHERE
            a.application_id                = in_application_id
        and a.descriptive_flexfield_name    = 'GL_JE_LINES'
        and a.descriptive_flex_context_code = iv_descriptive_flex_context
        and a.application_column_name       = 'ATTRIBUTE3'
      ;

    fnd_descr_flex_col_rec    fnd_descr_flex_col_cur%ROWTYPE;     --�e�[�u�����R�[�h

    --�`�[�ԍ��ő咷
    CURSOR fnd_flex_value_sets_cur(
        in_flex_value_set_id            IN  fnd_flex_value_sets.flex_value_set_id%TYPE  -- 1.�`�[���͎�
    ) IS
      SELECT
        a.*
      FROM  fnd_flex_value_sets a
      WHERE
          a.flex_value_set_id = in_flex_value_set_id
      ;

    fnd_flex_value_sets_rec   fnd_flex_value_sets_cur%ROWTYPE;      --�e�[�u�����R�[�h

    --�ʉ݃}�X�^
    CURSOR fnd_currencies_cur(
        iv_currency_code      IN  fnd_currencies.currency_code%TYPE -- 1.�ʉ݃R�[�h
      -- ver 11.5.10.2.6 Del Start
      ----2006/03/03 Ver11.5.10.1.6D Start
      -- ,id_gl_date            IN  DATE                              -- 2.GL�L����
      ----2006/03/03 Ver11.5.10.1.6D End
      -- ver 11.5.10.2.6 Del End
    ) IS
      SELECT
        a.*
      FROM  fnd_currencies a
      WHERE
          a.currency_code = iv_currency_code
      AND a.enabled_flag      = 'Y'
      -- 2006/03/03 Ver11.5.10.1.6D add Start
      -- ver 11.5.10.2.6 Chg Start
      --AND (a.start_date_active  IS NULL or a.start_date_active  <= id_gl_date )
      --AND (a.end_date_active    IS NULL or a.end_date_active    >= id_gl_date )
      AND (a.start_date_active  IS NULL or a.start_date_active  <= TRUNC(SYSDATE) )
      AND (a.end_date_active    IS NULL or a.end_date_active    >= TRUNC(SYSDATE) )
      -- ver 11.5.10.2.6 Chg End
      -- 2006/03/03 Ver11.5.10.1.6D add End
      ;

    fnd_currencies_rec    fnd_currencies_cur%ROWTYPE;     --�e�[�u�����R�[�h
-- Ver11.5.10.2.8 Add Start
    --�ڋq�}�X�^
    CURSOR cust_check_cur(
        it_segment5  IN  xx03_error_checks.segment5%TYPE   -- 1.segment5
    ) IS
      SELECT hp.duns_number_c       AS cust_status
-- Ver11.5.10.2.9 Add Start
            ,DECODE(xlxv.lookup_code ,NULL ,'' ,cv_flag_n)
                                    AS chk_cust_flag
-- Ver11.5.10.2.9 Add End
      FROM   hz_cust_accounts hca
            ,hz_parties       hp
-- Ver11.5.10.2.9 Add Start
            ,xx03_lookups_xx03_v xlxv
-- Ver11.5.10.2.9 Add End
      WHERE  hca.party_id       = hp.party_id
-- Ver11.5.10.2.9 Add Start
      AND    xlxv.lookup_type(+) = cv_lkp_chg_ng_cust_sts
      AND    xlxv.lookup_code(+) = hp.duns_number_c
-- Ver11.5.10.2.9 Add End
      AND    hca.account_number = it_segment5
      ;
    --
    cust_check_rec  cust_check_cur%ROWTYPE;     --�e�[�u�����R�[�h
-- Ver11.5.10.2.8 Add End
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
  local_continue       EXCEPTION;


--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  ����ID�擾
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;
-- Ver11.5.10.2.8 Add Start
    --    ����Ȗ�_�������i�ޑK�j�擾
    lt_account_change := xx00_profile_pkg.value (cv_prof_aff3_change) ;
-- Ver11.5.10.2.8 Add End
    --3.�G���[�`�F�b�N�e�[�u���ǂݍ���
     OPEN xx03_error_checks_cur(
        in_check_id         -- 1.�`�F�b�NID
    );

    <<aff_dff_check_loop>>
    LOOP
      FETCH xx03_error_checks_cur INTO xx03_error_checks_rec;
      EXIT WHEN xx03_error_checks_cur%NOTFOUND;

      BEGIN
        -- ����Ȗڑ��݃t���O������
        lv_is_accounts_exists := FALSE;

        --1)GL�L�����`�F�b�N
        --[1].GL�L������NULL�̏ꍇ�A�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���
        --�e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.gl_date IS NULL THEN
          lv_error_code   := 'APP-XX03-03042';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
          --�����R�[�h���������܂��B
          RAISE local_continue;
        END IF;

        --2)AFF�`�F�b�N(���)
        --[1].segment1(���)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment1 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT1');
--          lv_error_code   := 'APP-XX03-03018';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_companies_v_cur(
              xx03_error_checks_rec.segment1,         -- 1.[1].segment1(���)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_companies_v_cur INTO xx03_companies_v_rec;

          IF xx03_companies_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT1');
--            lv_error_code   := 'APP-XX03-03018';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_companies_v_cur;
        END IF;

        --3)AFF�`�F�b�N(����Ȗ�)
        --[1].segment3(����Ȗ�)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment3 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT3');
--          lv_error_code   := 'APP-XX03-03019';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_accounts_v_cur(
              xx03_error_checks_rec.segment3,         -- 1.[1].segment3(����Ȗ�)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_accounts_v_cur INTO xx03_accounts_v_rec;

          IF xx03_accounts_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT3');
--            lv_error_code   := 'APP-XX03-03019';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          ELSE
            --�t���O�ݒ�
            lv_is_accounts_exists := TRUE;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_accounts_v_cur;
        END IF;

        --4)AFF�`�F�b�N(����)
        --[1].segment2(����)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment2 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
--          lv_error_code   := 'APP-XX03-03020';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_departments_v_cur(
              xx03_error_checks_rec.segment2,         -- 1.[1].segment2(����)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_departments_v_cur INTO xx03_departments_v_rec;

          IF xx03_departments_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
--            lv_error_code   := 'APP-XX03-03020';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
-- �C�� 1.1 BEGIN
--
            ELSE
              --���AFF�`�F�b�N(����Ȗ�)�Ń}�X�^���擾�ł����ꍇ�A�擾�����A
              --xx03_accounts_v�ϐ� (���R�[�h�^).attribute1(�Œ蕔��R�[�h)��
              --null�łȂ��ꍇ�ȉ����`�F�b�N���܂��Bxx03_accounts_v�ϐ� (���R
              --�[�h�^).attribute1(�Œ蕔��R�[�h)��[1].segment2(����)�̏ꍇ�A�G
              --���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[��
              --��e�[�u�����o�͂��܂��B

              IF lv_is_accounts_exists AND xx03_accounts_v_rec.attribute1 IS NOT NULL  THEN
                IF xx03_accounts_v_rec.attribute1 != xx03_error_checks_rec.segment2 THEN
                  --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
                  lv_error_code   := 'APP-XX03-03026';
                  lt_tokeninfo.DELETE;
                  lt_tokeninfo(0).token_name := 'TOK_INVAQLID_FIX_DIV';
                  lt_tokeninfo(0).token_value := xx03_accounts_v_rec.attribute1;
-- �ύX 1.11 BEGIN
                  lt_tokeninfo(1).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                  lt_tokeninfo(1).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT2');
                  lt_tokeninfo(2).token_name := 'TOK_INVALID_DIV';
                  lt_tokeninfo(2).token_value := xx03_error_checks_rec.segment2;
--                  lt_tokeninfo(1).token_name := 'TOK_INVALID_DIV';
--                  lt_tokeninfo(1).token_value := xx03_error_checks_rec.segment2;
-- �ύX 1.11 END
                  lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                      xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                      xx03_error_checks_rec.journal_id  , --2.�d��L�[
                      xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                      xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                      lv_error_code   ,                   --5.�G���[�R�[�h
                      lt_tokeninfo    ,                   --6.�g�[�N�����
                      cv_status_error );
                  lt_tokeninfo.DELETE;
                  --�߂�l�X�V
                  lv_ret_status := cv_status_error;
                END IF;
              END IF;
--
-- �C�� 1.1 END
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_departments_v_cur;
        END IF;

        --5)AFF�`�F�b�N(�⏕�Ȗ�)
        --[1].segment4(�⏕�Ȗ�)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment4 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT4');
--          lv_error_code   := 'APP-XX03-03021';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_sub_accounts_v_cur(
              xx03_error_checks_rec.segment4,         -- 1.[1].segment4(�⏕�Ȗ�)
              xx03_error_checks_rec.gl_date,          -- 2.[1].GL�L����
              xx03_error_checks_rec.segment3          -- 3.����Ȗ�
          );
          --�ǂݍ���

          FETCH xx03_sub_accounts_v_cur INTO xx03_sub_accounts_v_rec;

          IF xx03_sub_accounts_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT4');
--            lv_error_code   := 'APP-XX03-03021';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_sub_accounts_v_cur;
        END IF;

        --6)AFF�`�F�b�N(�����)
        --[1].segment5(�����)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B


        IF xx03_error_checks_rec.segment5 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
--          lv_error_code   := 'APP-XX03-03022';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_partners_v_cur(
              xx03_error_checks_rec.segment5,         -- 1.[1].segment5(�����)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_partners_v_cur INTO xx03_partners_v_rec;

          IF xx03_partners_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
--            lv_error_code   := 'APP-XX03-03022';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          ELSE
          --���AFF�`�F�b�N(����Ȗ�)�Ń}�X�^���擾�ł����ꍇ�A�擾�����A
          --xx03_accounts_v�ϐ� (���R�[�h�^).attribute2(�����K�{�t���O)
          --���fN�f�̏ꍇ�Agl_sets_of_books���W�񑊎��R�[�h���擾���A
          --�ȉ����`�F�b�N���܂��B

-- �ύX 1.5 BEGIN
--          �����K�{�敪��'Y'�̏ꍇ�̏������ǉ����܂��̂ŁA
--          xx03_accounts_v_rec.attribute2 = 'N'�̏���������IF��
--          ����͍폜
--            IF lv_is_accounts_exists AND xx03_accounts_v_rec.attribute2 = 'N' THEN
            IF lv_is_accounts_exists THEN
-- �ύX 1.5 END
              OPEN gl_sets_of_books_cur(
                  ln_set_of_books_id          -- 1.����ID
              );
              --�ǂݍ���

              FETCH gl_sets_of_books_cur INTO gl_sets_of_books_rec;

              IF gl_sets_of_books_cur%NOTFOUND THEN
                lv_error_code   := 'APP-XX03-03027';
                lt_tokeninfo.DELETE;
-- �ύX 1.11 BEGIN
                lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
-- �ύX 1.11 END
                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                    xx03_error_checks_rec.journal_id  , --2.�d��L�[
                    xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                    xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                    lv_error_code   ,                   --5.�G���[�R�[�h
                    lt_tokeninfo    ,                   --6.�g�[�N�����
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --�߂�l�X�V
                lv_ret_status := cv_status_error;
              ELSE
                --[1].segment5(�����) �� �ϐ�. �W�񑊎��R�[�h�̏ꍇ�A�G���[���
                --�e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u
                --�����o�͂��܂��B

-- �ύX 1.5 BEGIN
--          �����K�{�敪�ɂ���āA��������ύX
--                IF ( xx03_error_checks_rec.segment5 != gl_sets_of_books_rec.attribute1 ) OR
                IF ((xx03_accounts_v_rec.attribute2 = 'N' AND
                      xx03_error_checks_rec.segment5 != gl_sets_of_books_rec.attribute1)
                    OR
                    (xx03_accounts_v_rec.attribute2 = 'Y' AND
                      xx03_error_checks_rec.segment5 = gl_sets_of_books_rec.attribute1 )) OR
-- �ύX 1.5 END
                   ( xx03_error_checks_rec.segment5 IS NULL     AND gl_sets_of_books_rec.attribute1 IS NOT NULL ) OR
                   ( xx03_error_checks_rec.segment5 IS NOT NULL AND gl_sets_of_books_rec.attribute1 IS NULL     ) THEN
                  lv_error_code   := 'APP-XX03-03027';
                  lt_tokeninfo.DELETE;
-- �ύX 1.11 BEGIN
                  lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
                  lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT5');
-- �ύX 1.11 END
                  lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                      xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                      xx03_error_checks_rec.journal_id  , --2.�d��L�[
                      xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                      xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                      lv_error_code   ,                   --5.�G���[�R�[�h
                      lt_tokeninfo    ,                   --6.�g�[�N�����
                      cv_status_error );
                  lt_tokeninfo.DELETE;
                  --�߂�l�X�V
                  lv_ret_status := cv_status_error;
                END IF;
-- Ver11.5.10.2.8 Add Start
                --segment3(����Ȗ�)���v���t�@�C���u����Ȗ�_�������i�ޑK�j�v�̏ꍇ�A
                --segment5(�����)�ɐݒ肳�ꂽ�ڋq���`�F�b�N���܂��B
                IF ( lt_account_change IS NOT NULL AND xx03_error_checks_rec.segment3 = lt_account_change ) THEN
                  OPEN cust_check_cur(
                      xx03_error_checks_rec.segment5  -- 1.segment5
                  );
                  --�ǂݍ���
                  FETCH cust_check_cur INTO cust_check_rec;
                  --�ڋq�X�e�[�^�X��'90'(���~���ٍ�)�̏ꍇ�A���~�ڋq�Ƃ���
                  --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A
                  --�G���[���e�[�u�����o�͂��܂��B
-- Ver11.5.10.2.9 Mod Start
--                  IF cust_check_rec.cust_status = cv_cust_status_stop THEN
                  IF cust_check_rec.chk_cust_flag = cv_flag_n THEN
-- Ver11.5.10.2.9 Mod End
                    lv_error_code := cv_msg_cust_stop_err;
                    lt_tokeninfo.DELETE;
                    lt_tokeninfo(0).token_name  := cv_tkn_cust_num;                --TOK_XX03_CUST_NUM
                    lt_tokeninfo(0).token_value := xx03_error_checks_rec.segment5; --�ڋq�R�[�h
-- Ver11.5.10.2.9 Add Start
                    lt_tokeninfo(1).token_name  := cv_tkn_cust_sts;                --TOK_XX03_CUST_STS
                    lt_tokeninfo(1).token_value := cust_check_rec.cust_status;     --�ڋq�X�e�[�^�X
-- Ver11.5.10.2.9 Add End
                    lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                       xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                       xx03_error_checks_rec.journal_id  , --2.�d��L�[
                       xx03_error_checks_rec.line_number , --3.�s�ԍ�
                       xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
                       lv_error_code   ,                   --5.�G���[�R�[�h
                       lt_tokeninfo    ,                   --6.�g�[�N�����
                       cv_status_error );
                    lt_tokeninfo.DELETE;
                    --�߂�l�X�V
                    lv_ret_status := cv_status_error;
                  END IF;
                  --�J�[�\���̃N���[�Y
                  CLOSE cust_check_cur;
                END IF;
-- Ver11.5.10.2.8 Add End
              END IF;
              --�J�[�\���̃N���[�Y
              CLOSE gl_sets_of_books_cur;

            END IF;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_partners_v_cur;
        END IF;

        --7)AFF�`�F�b�N(���Ƌ敪)
        --[1].segment6(���Ƌ敪)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment6 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT6');
--          lv_error_code   := 'APP-XX03-03023';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_business_types_v_cur(
              xx03_error_checks_rec.segment6,         -- 1.[1].segment6(���Ƌ敪)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_business_types_v_cur INTO xx03_business_types_v_rec;

          IF xx03_business_types_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT6');
--            lv_error_code   := 'APP-XX03-03023';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_business_types_v_cur;
        END IF;

        --8)AFF�`�F�b�N(�v���W�F�N�g)
        --[1].segment7(�v���W�F�N�g)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment7 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT7');
--          lv_error_code   := 'APP-XX03-03024';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_projects_v_cur(
              xx03_error_checks_rec.segment7,         -- 1.[1].segment7(�v���W�F�N�g)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_projects_v_cur INTO xx03_projects_v_rec;

          IF xx03_projects_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT7');
--            lv_error_code   := 'APP-XX03-03024';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_projects_v_cur;
        END IF;

        --9)AFF�`�F�b�N(�\��)
        --[1].segment8(�\��)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.segment8 IS NULL THEN
-- �ύX 1.11 BEGIN
          lv_error_code := 'APP-XX03-03089';
          lt_tokeninfo.DELETE;
          lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
          lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT8');
--          lv_error_code   := 'APP-XX03-03025';
--          lt_tokeninfo.DELETE;
-- �ύX 1.11 END
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_futures_v_cur(
              xx03_error_checks_rec.segment8,         -- 1.[1].segment7(�v���W�F�N�g)
              xx03_error_checks_rec.gl_date           -- 2.[1].GL�L����
          );
          --�ǂݍ���

          FETCH xx03_futures_v_cur INTO xx03_futures_v_rec;

          IF xx03_futures_v_cur%NOTFOUND THEN
-- �ύX 1.11 BEGIN
            lv_error_code := 'APP-XX03-03089';
            lt_tokeninfo.DELETE;
            lt_tokeninfo(0).token_name := 'TOK_XX03_SEGMENT_PROMPT';
            lt_tokeninfo(0).token_value := xx03_get_prompt_pkg.aff_segment('SEGMENT8');
--            lv_error_code   := 'APP-XX03-03025';
--            lt_tokeninfo.DELETE;
-- �ύX 1.11 END
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_futures_v_cur;
        END IF;

        --10)DFF�`�F�b�N(�ŋ敪)
        --[1].tax_code(�ŋ敪)��NULL�̏ꍇ
        --���AFF�`�F�b�N(����Ȗ�)�Ń}�X�^���擾�ł����ꍇ�A�擾�����A
        --xx03_accounts_v�ϐ� (���R�[�h�^).attribute3(�ŋ敪�K�{�敪)��
        --�f9�f(�ېőΏۊO)�ȊO�̏ꍇ��       --�G���[���e�[�u���o�̓T
        --�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.tax_code IS NULL THEN
-- �ύX 1.6 BEGIN
--          IF lv_is_accounts_exists AND (xx03_accounts_v_rec.attribute3 != '9' or xx03_accounts_v_rec.attribute3 IS NULL)  THEN
          IF lv_is_accounts_exists AND
             (xx03_accounts_v_rec.attribute3 not in('1','9')
              or xx03_accounts_v_rec.attribute3 IS NULL)  THEN
-- �ύX 1.6 END
            lv_error_code   := 'APP-XX03-03028';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_tax_codes_v_cur(
              -- Ver11.5.10.1.6 2005/12/15 Change Start
              --xx03_error_checks_rec.tax_code,         -- 1.[1].tax_code(�ŋ敪)
              --ln_set_of_books_id                      -- 2.����ID
              xx03_error_checks_rec.tax_code,         -- 1.[1].tax_code(�ŋ敪)
              ln_set_of_books_id,                     -- 2.����ID
              xx03_error_checks_rec.gl_date           -- 3.[1].GL�L����
              -- Ver11.5.10.1.6 2005/12/15 Change End
          );
          --�ǂݍ���
          FETCH xx03_tax_codes_v_cur INTO xx03_tax_codes_v_rec;

          --�E�f�[�^�񑶍ݎ�
          --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
          IF xx03_tax_codes_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03028';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          ELSE
            --�E�f�[�^���ݎ�
            --���AFF�`�F�b�N(����Ȗ�)�Ń}�X�^���擾�ł����ꍇ�A
            --�ȉ��̏�����S�Ė����������`�F�b�N���܂��B�������Ȃ��ꍇ�́A
            --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G��
            --�[���e�[�u�����o�͂��܂��B
-- �R�����g�ǉ� 1.6 BEGIN
            --�E�擾�����Axx03_accounts_v�ϐ� (���R�[�h�^).attribute3(�ŋ敪
            --�K�{�敪)=�f1�f(����/����/�ΏۊO�j�̏ꍇ�A�S��OK
-- �R�����g�ǉ� 1.6 END
            --�E�擾�����Axx03_accounts_v�ϐ� (���R�[�h�^).attribute3(�ŋ敪
            --�K�{�敪)=�f2�f(����̏ꍇ�A[1].�ŋ敪= xx03_tax_codes_v�ϐ� (��
            --�R�[�h�^).attribute2(�ېŏW�v�敪)=�f1�f(�ېŔ���)
            --�E�擾�����Axx03_accounts_v�ϐ� (���R�[�h�^).attribute3(�ŋ敪
            --�K�{�敪)=�f3�f(�����̏ꍇ�A[1].�ŋ敪= xx03_tax_codes_v�ϐ� (��
            --�R�[�h�^).attribute2(�ېŏW�v�敪)=�f2�f(�ېŎd��)
-- �R�����g�ǉ� 1.6 BEGIN
            --�E�擾�����Axx03_accounts_v�ϐ� (���R�[�h�^).attribute3(�ŋ敪
            --�K�{�敪)=�f9�f(�ΏۊO�̏ꍇ�A[1].�ŋ敪= xx03_tax_codes_v�ϐ� (��
            --�R�[�h�^).attribute2(�ېŏW�v�敪)=NULL
-- �R�����g�ǉ� 1.6 END
            IF lv_is_accounts_exists  THEN
-- �ύX 1.6 BEGIN
--              IF NOT (( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='2' )) THEN
-- Ver11.5.10.1.5 2005/10/20 Modify Start
--              IF NOT (( xx03_accounts_v_rec.attribute3 = '1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
--                      ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 IS NULL )) THEN
              IF (( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '2' AND xx03_tax_codes_v_rec.attribute2 IS NULL ) OR
                  ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '3' AND xx03_tax_codes_v_rec.attribute2 IS NULL ) OR
                  ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 = '9' AND xx03_tax_codes_v_rec.attribute2 ='2' ) OR
                  ( xx03_accounts_v_rec.attribute3 IS NULL AND xx03_tax_codes_v_rec.attribute2 ='1' ) OR
                  ( xx03_accounts_v_rec.attribute3 IS NULL AND xx03_tax_codes_v_rec.attribute2 ='2' )) THEN
-- Ver11.5.10.1.5 2005/10/20 Modify End
-- �ύX 1.6 END
                lv_error_code   := 'APP-XX03-03029';
                lt_tokeninfo.DELETE;
-- Ver11.5.10.1.5 2005/10/20 Add Start
                lt_tokeninfo(0).token_name := 'TOK_XX03_ACCT_CODE';
                lt_tokeninfo(0).token_value := xx03_accounts_v_rec.FLEX_VALUE;
                lt_tokeninfo(1).token_name := 'TOK_XX03_TAX_CODE';
                lt_tokeninfo(1).token_value := xx03_tax_codes_v_rec.name;
-- Ver11.5.10.1.5 2005/10/20 Add End
                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                    xx03_error_checks_rec.journal_id  , --2.�d��L�[
                    xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                    xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                    lv_error_code   ,                   --5.�G���[�R�[�h
                    lt_tokeninfo    ,                   --6.�g�[�N�����
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --�߂�l�X�V
                lv_ret_status := cv_status_error;
              END IF;
            END IF;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_tax_codes_v_cur;
        END IF;

        --11)DFF�`�F�b�N(�������R)
        --[1].incr_decr_reason_code(�������R)��NULL�̏ꍇ
        --�`�F�b�N���X�L�b�v���܂��B
        --[1].incr_decr_reason_code(�������R)��NULL�ȊO�̏ꍇ
        --�ȉ������s���܂��B
        IF xx03_error_checks_rec.incr_decr_reason_code IS NOT NULL THEN

          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_incr_decr_reasons_v_cur(
              xx03_error_checks_rec.incr_decr_reason_code   -- 1.[1].�������R
          );
          --�ǂݍ���
          FETCH xx03_incr_decr_reasons_v_cur INTO xx03_incr_decr_reasons_v_rec;

          --�E�f�[�^�񑶍ݎ�
          --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
          IF xx03_incr_decr_reasons_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03030';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          ELSE
            --�E�f�[�^���ݎ�
            --�}�X�^�`�F�b�N
            --�J�[�\���̃I�[�v��
            OPEN xx03_cf_combinations_cur(
                xx03_error_checks_rec.segment3,                 -- 1.[1].����Ȗ�
                xx03_error_checks_rec.incr_decr_reason_code,    -- 2.[1].�������R
                xx03_error_checks_rec.gl_date                   -- 3.[1].GL�L����
            );
            --�ǂݍ���
            FETCH xx03_cf_combinations_cur INTO xx03_cf_combinations_rec;
            --�E�f�[�^�񑶍ݎ�
            --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
            IF xx03_cf_combinations_cur%NOTFOUND THEN
              lv_error_code   := 'APP-XX03-03031';
              lt_tokeninfo.DELETE;
              lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                  xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                  xx03_error_checks_rec.journal_id  , --2.�d��L�[
                  xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                  xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                  lv_error_code   ,                   --5.�G���[�R�[�h
                  lt_tokeninfo    ,                   --6.�g�[�N�����
                  cv_status_error );
              lt_tokeninfo.DELETE;
              --�߂�l�X�V
              lv_ret_status := cv_status_error;
            END IF;
            --�J�[�\���̃N���[�Y
            CLOSE xx03_cf_combinations_cur;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_incr_decr_reasons_v_cur;
        -- Ver11.5.10.1.6C 2006/01/16 Add Start
        -- �������R��null�̏ꍇ�͑������R=NULL�̑g���������݂��邩�̃`�F�b�N���K�v
        ELSE
          OPEN xx03_cf_combinations_cur(
              xx03_error_checks_rec.segment3,                 -- 1.[1].����Ȗ�
              xx03_error_checks_rec.incr_decr_reason_code,    -- 2.[1].�������R
              xx03_error_checks_rec.gl_date                   -- 3.[1].GL�L����
          );
          --�ǂݍ���
          FETCH xx03_cf_combinations_cur INTO xx03_cf_combinations_rec;
          --�E�f�[�^�񑶍ݎ�
          --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
          IF xx03_cf_combinations_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03031';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_cf_combinations_cur;
         -- Ver11.5.10.1.6C 2006/01/16 Add End
        END IF;

        --12)DFF�`�F�b�N(�N�[����)
        --[1].input_department(�N�[����)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A�G���[���
        --�e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.input_department IS NULL THEN
-- �ύX 1.7 BEGIN
--          lv_error_code   := 'APP-XX03-03032';
--          lt_tokeninfo.DELETE;
--          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
--              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
--              xx03_error_checks_rec.journal_id  , --2.�d��L�[
--              xx03_error_checks_rec.line_number , --3.�s�ԍ�
--              lv_error_code   ,                   --4.�G���[�R�[�h
--              lt_tokeninfo    ,                   --5.�g�[�N�����
--              cv_status_error );
--          lt_tokeninfo.DELETE;
--          --�߂�l�X�V
--          lv_ret_status := cv_status_error;
          NULL;
-- �ύX 1.7 END
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_departments_v_cur2(
              xx03_error_checks_rec.input_department          -- 1.�N�[����
          );
          --�ǂݍ���

          FETCH xx03_departments_v_cur2 INTO xx03_departments_v_rec2;

          IF xx03_departments_v_cur2%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03032';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_departments_v_cur2;
        END IF;

        --13)DFF�`�F�b�N(�`�[���͎�)
        --[1].input_user(�`�[���͎�)��NULL�̏ꍇ
        --�`�F�b�N���X�L�b�v���܂��B
        --[1]. input_user(�`�[���͎�)��NULL�ȊO�̏ꍇ
        --�ȉ������s���܂��B

        IF xx03_error_checks_rec.input_user IS NOT NULL THEN
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN xx03_users_v_cur(
              xx03_error_checks_rec.input_user          -- 1.�`�[���͎�
          );
          --�ǂݍ���

          FETCH xx03_users_v_cur INTO xx03_users_v_rec;

          IF xx03_users_v_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03033';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE xx03_users_v_cur;
        END IF;

        --14)DFF�`�F�b�N(�`�[�ԍ�)
        --[1].slip_number (�`�[�ԍ�)��NULL�̏ꍇ
        --�`�F�b�N���X�L�b�v���܂��B
        --[1].slip_number (�`�[�ԍ�)��NULL�ȊO�̏ꍇ
        --�ȉ������s���܂��B

        IF xx03_error_checks_rec.slip_number IS NOT NULL THEN

          --���떼�̎擾
          xx03_books_org_name_get_pkg.set_of_books_name(ln_errbuf,ln_retcode,ln_errmsg,ln_set_of_books_name,ln_set_of_books_id);

          --�A�v���P�[�V����ID�̎擾
          ln_application_id := xx03_application_pkg.get_application_id_f('SQLGL');

          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN fnd_descr_flex_col_cur(
              ln_application_id,
              ln_set_of_books_name
          );

          --�ǂݍ���
          FETCH fnd_descr_flex_col_cur INTO fnd_descr_flex_col_rec;

          IF fnd_descr_flex_col_cur%NOTFOUND THEN
            NULL;
          ELSE
            --�}�X�^�`�F�b�N
            --�J�[�\���̃I�[�v��
            OPEN fnd_flex_value_sets_cur(
                fnd_descr_flex_col_rec.flex_value_set_id  -- 1.�Z�b�gID
            );

            --�ǂݍ���
            FETCH fnd_flex_value_sets_cur INTO fnd_flex_value_sets_rec;

            IF fnd_flex_value_sets_cur%NOTFOUND THEN
              NULL;
            ELSE
              --lengthb([1].slip_number (�`�[�ԍ�))  >�ϐ�.�l�ő咷�̂Ƃ�
              --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
              IF LENGTHB(xx03_error_checks_rec.slip_number) > TO_NUMBER(fnd_flex_value_sets_rec.maximum_size) THEN
                lv_error_code   := 'APP-XX03-03034';
                lt_tokeninfo.DELETE;
                lt_tokeninfo(0).token_name := 'TOK_XX03_LEN';
                lt_tokeninfo(0).token_value := fnd_flex_value_sets_rec.maximum_size;

                lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                    xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                    xx03_error_checks_rec.journal_id  , --2.�d��L�[
                    xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                    xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                    lv_error_code   ,                   --5.�G���[�R�[�h
                    lt_tokeninfo    ,                   --6.�g�[�N�����
                    cv_status_error );
                lt_tokeninfo.DELETE;
                --�߂�l�X�V
                lv_ret_status := cv_status_error;
              END IF;
            END IF;
            --�J�[�\���̃N���[�Y
            CLOSE fnd_flex_value_sets_cur;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE fnd_descr_flex_col_cur;
        END IF;

        --15)�ʉ݃`�F�b�N
        --[1].currency_code(�ʉ�)��NULL�̏ꍇ�A�܂��͈ȉ��̌����ɂă}�X�^�񑶍ݎ��A
        --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF xx03_error_checks_rec.currency_code IS NULL THEN
          lv_error_code   := 'APP-XX03-03035';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
              xx03_error_checks_rec.journal_id  , --2.�d��L�[
              xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          lt_tokeninfo.DELETE;
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --�}�X�^�`�F�b�N
          --�J�[�\���̃I�[�v��
          OPEN fnd_currencies_cur(
              xx03_error_checks_rec.currency_code         -- 1.�ʉ݃R�[�h
             -- ver 11.5.10.2.6 Del Start
             ---- 2006/03/03 Ver11.5.10.1.6D add Start
             --,xx03_error_checks_rec.gl_date               -- 2.[1].GL�L����
             ---- 2006/03/03 Ver11.5.10.1.6D add END
             -- ver 11.5.10.2.6 Del End
          );
          --�ǂݍ���

          FETCH fnd_currencies_cur INTO fnd_currencies_rec;

          IF fnd_currencies_cur%NOTFOUND THEN
            lv_error_code   := 'APP-XX03-03035';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                xx03_error_checks_rec.check_id    , --1.�`�F�b�NID
                xx03_error_checks_rec.journal_id  , --2.�d��L�[
                xx03_error_checks_rec.line_number , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                xx03_error_checks_rec.dr_cr       , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            lt_tokeninfo.DELETE;
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
          --�J�[�\���̃N���[�Y
          CLOSE fnd_currencies_cur;
        END IF;

      EXCEPTION
        WHEN local_continue THEN
            NULL;
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR
            (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
      END;

    END LOOP aff_dff_check_loop;

    --�J�[�\���̃N���[�Y
    CLOSE xx03_error_checks_cur;

--
    RETURN lv_ret_status;
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
  END aff_dff_check;
--
  /**********************************************************************************
   * Procedure Name   : balance_check
   * Description      : �d��o�����X�`�F�b�N
   ***********************************************************************************/
  FUNCTION balance_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.balance_check'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    --�o�����X�`�F�b�N�p�J�[�\��
    CURSOR balance_check_cur(
        in_check_id       IN  xx03_error_checks.check_id%TYPE   -- 1.�`�F�b�NID
    ) IS
      SELECT
        a.check_id,                   --�`�F�b�NID
        a.journal_id,                 --�d��ID
        sum( NVL(a.entered_dr,0) ),   --�ؕ����z
        sum( NVL(a.entered_cr,0) )    --�ݕ����z
      FROM
        xx03_error_checks a
      WHERE
        a.check_id  =  in_check_id
      GROUP BY
        a.check_id,    --�`�F�b�NID
        a.journal_id  --�d��ID
      HAVING
        sum(NVL(a.entered_dr,0 ))  !=sum(NVL(a.entered_cr,0) )
      ;

    balance_check_rec           balance_check_cur%ROWTYPE;              --�e�[�u�����R�[�h

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2.�o�����X�`�F�b�N�J�[�\���ǂݍ���
    OPEN balance_check_cur(
      in_check_id         -- 1.�`�F�b�NID
    );

    <<balance_check_loop>>

    lt_tokeninfo.DELETE;

    LOOP
      FETCH balance_check_cur INTO balance_check_rec;
      EXIT WHEN balance_check_cur%NOTFOUND;
        --���R�[�h�����݂���ԁA�G���[���e�[�u���o�̓T�u�֐�
        --(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        lv_error_code   := 'APP-XX03-03036';
        lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
            balance_check_rec.check_id    ,     --1.�`�F�b�NID
            balance_check_rec.journal_id  ,     --2.�d��L�[
            0                             ,     --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
            ' '             ,                   --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
            lv_error_code   ,                   --5.�G���[�R�[�h
            lt_tokeninfo    ,                   --6.�g�[�N�����
            cv_status_error );

        --�߂�l�X�V
        lv_ret_status := cv_status_error;

    END LOOP balance_check_loop;

    CLOSE balance_check_cur;

--
    RETURN lv_ret_status;
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
  END balance_check;
--
  /**********************************************************************************
   * Procedure Name   : tax_range_check
   * Description      : ����Ŋz���e�͈̓`�F�b�N
   ***********************************************************************************/
  FUNCTION tax_range_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.tax_range_check'; -- �v���O������
-- 2015/03/24 Ver11.5.10.2.7 Add Start
    cv_comp_code_001  CONSTANT VARCHAR2(3) := '001';               -- ��ЃR�[�h�F001�i�{�Ёj
-- 2015/03/24 Ver11.5.10.2.7 Add End
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;    --����ID
    ln_org_id                       gl_tax_options.org_id%TYPE;             --�I���OID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

-- �ǉ� 1.9 BEGIN
    cn_curr_precision CONSTANT fnd_currencies.precision%TYPE := 2;              -- �ʉ݂��擾�ł��Ȃ������ꍇ�̐��x
-- �ǉ� 1.9 END

-- �C�� 1.2 BEGIN
--
    ln_check_id_old                 xx03_error_checks.check_id%TYPE;        -- 1.�`�F�b�NID(�u���C�N�L�[)
    ln_journal_id_old               xx03_error_checks.journal_id%TYPE;      -- 2.�d��ID    (�u���C�N�L�[)
--
-- �C�� 1.2 END

    --�ŋ��I�v�V�����\����

    CURSOR gl_tax_options_cur(
        ln_set_of_books_id        IN  gl_tax_options.set_of_books_id%TYPE,  -- 1.����ID
        ln_org_id                 IN  gl_tax_options.org_id %TYPE           -- 2.�I���OID
    ) IS
      SELECT
      a.attribute1,               --���e�͈͗�
      a.attribute2,               --���e�͈͍ő���z
      a.input_rounding_rule_code, --�����[�������K��
      a.output_rounding_rule_code --����[�������K��
      FROM
        gl_tax_options a
      WHERE
          a.set_of_books_id       =  ln_set_of_books_id
      AND a.org_id                =  ln_org_id
      ;

    gl_tax_options_rec            gl_tax_options_cur%ROWTYPE;             --�e�[�u�����R�[�h

    --����Ŋz���e�͈̓`�F�b�N�p�J�[�\��
    CURSOR tax_range_check_cur(
        in_check_id                   IN  xx03_error_checks.check_id%TYPE,              -- 1.�`�F�b�NID
        ln_set_of_books_id            IN  gl_tax_options.set_of_books_id%TYPE,          -- 2.����ID
        iv_input_rounding_rule_code   IN  gl_tax_options.input_rounding_rule_code%TYPE, -- 3.�����[�������K��
        iv_output_rounding_rule_code  IN  gl_tax_options.output_rounding_rule_code%TYPE -- 4.����[�������K��
    ) IS
    SELECT
      er.check_id,    --�`�F�b�Nid
      er.journal_id,  --�d��id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,    --��ЃR�[�h
      cv_comp_code_001,  -- ��ЃR�[�h�F001�i�{�Ёj
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code,    --�ŋ敪
    --
      sum(
        case
          when ac.attribute6 is null then --����ŉȖڋ敪��NULL(�{�Ȗڍs)
            case
-- �ύX 1.10 BEGIN
--              when er.tax_code is null then
--                0 --�ŋ敪��null��0�Ƃ��Čv�Z
              when nvl(tc.tax_rate,0) = 0 then
                0 --�ŗ�0%�i��ېŁA�s�ېŁA�ƐŁA�ېőΏۊO�j��0�Ƃ��Čv�Z
-- �ύX 1.10 END
              else nvl(er.entered_dr,0) - nvl(er.entered_cr,0)
            end
          else 0 --�ŋ��s�͉��Z�����B
        end ) sum_no_tax,   --�ŋ��s�łȂ��s�̍��v
    --
      sum(
        case
          when ac.attribute6 is null then --����ŉȖڋ敪��NULL(�{�Ȗڍs)
          case
-- �ύX 1.10 BEGIN
--            when er.tax_code is null then 0 --�ŋ敪��null��0�Ƃ��Čv�Z
            when nvl(tc.tax_rate,0) = 0 then 0 --�ŗ�0%��0�Ƃ��Čv�Z
-- �ύX 1.10 END
            else
              case tc.attribute2    --�ŋ敪�}�X�^�̉ېŏW�v�敪
                when  '1' then     --�ېŔ���(����)
                  case  iv_output_rounding_rule_code --�ϐ�. ����[�������K�� (output_rounding_rule_code)  --����[�������K��
                    when  'N' then   --�l�̌ܓ�
-- �ύX 1.9 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- �ύX 1.10 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      round(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      round(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- �ύX 1.10 END
-- �ύX 1.9 END
                    when  'U' then   --�؂�グ
-- �ύX 1.9 BEGIN
-- �ύX 1.10 BEGIN
--                      sign( nvl(er.entered_dr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_dr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- �ύX 1.10 END
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) ) -
-- �ύX 1.10 BEGIN
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    (trunc((abs( nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) ) -
--                      sign( nvl(er.entered_cr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_cr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- �ύX 1.10 END
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) )
-- �ύX 1.10 BEGIN
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                      (trunc((abs( nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
-- �ύX 1.10 END
-- �ύX 1.9 END
                    else        --�؂�̂�(d)
-- �ύX 1.9 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- �ύX 1.10 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      trunc(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      trunc(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- �ύX 1.10 END
-- �ύX 1.9 END
                  end
                else          --�ېŎd��(����)
                  case  iv_input_rounding_rule_code --�ϐ�.�����[�������K��(input_rounding_rule_code)   --�����[�������K��
                    when  'N' then   --�l�̌ܓ�
-- �ύX 1.9 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- �ύX 1.10 BEGIN
--                      round(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      round(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      round(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      round(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- �ύX 1.10 END
-- �ύX 1.9 END
                    when  'U' then   --�؂�グ
-- �ύX 1.9 BEGIN
-- �ύX 1.10 BEGIN
--                      sign( nvl(er.entered_dr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_dr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- �ύX 1.10 END
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) ) -
-- �ύX 1.10 BEGIN
--                    (trunc((abs( nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    (trunc((abs( nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) ) -
--                      sign( nvl(er.entered_cr,0)  * ( tc.tax_rate / 100 ) ) *
                      sign( nvl(er.entered_cr,0)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
-- �ύX 1.10 END
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,fc.precision ) )
--                       * power( 10,fc.precision ) ) * power( 0.1,fc.precision ) )
-- �ύX 1.10 BEGIN
--                      (trunc((abs( nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                      (trunc((abs( nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
-- �ύX 1.10 END
-- �ύX 1.9 END
                    else        --�؂�̂�(d)
-- �ύX 1.9 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), fc.precision) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), fc.precision)
-- �ύX 1.10 BEGIN
--                      trunc(nvl(er.entered_dr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision)) -
--                      trunc(nvl(er.entered_cr,0) * ( tc.tax_rate / 100 ), nvl(fc.precision, cn_curr_precision))
                      trunc(nvl(er.entered_dr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision)) -
                      trunc(nvl(er.entered_cr,0) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
-- �ύX 1.10 END
-- �ύX 1.9 END
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
            nvl(er.entered_dr,0) - nvl(er.entered_cr,0)
          else
            0       --�ŋ��s�łȂ���Ή��Z�����B
        end
      ) sum_tax     --�ŋ��s�̍��v
    FROM
      xx03_error_checks   er, --�G���[�`�F�b�N�e�[�u��
      xx03_accounts_v     ac, --����Ȗڃ}�X�^
      xx03_tax_codes_v    tc, --�ŋ敪�}�X�^
      fnd_currencies      fc  --�ʉ݃}�X�^
    WHERE
          er.check_id         = in_check_id
      and er.segment3         = ac.flex_value
      and er.tax_code         = tc.name (+)
-- �ύX 1.10 BEGIN
--      and tc.set_of_books_id  = ln_set_of_books_id --�ϐ�.����ID
      and tc.set_of_books_id (+)  = ln_set_of_books_id --�ϐ�.����ID
-- �ύX 1.10 END
      and er. currency_code   = fc. currency_code (+)
      -- Ver11.5.10.1.6 2005/12/15 Add Start
      and (tc.start_date    IS NULL or tc.start_date  <= er.gl_date )
      and (tc.inactive_date IS NULL or tc.inactive_date  >= er.gl_date)
      -- Ver11.5.10.1.6 2005/12/15 Add End
    GROUP BY
      er.check_id,  --�`�F�b�Nid
      er.journal_id,  --�d��id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,  --��ЃR�[�h
      cv_comp_code_001,  -- ��ЃR�[�h�F001�i�{�Ёj
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code   --�ŋ敪
-- �C�� 1.2 BEGIN
--
    ORDER BY
      er.check_id,  --�`�F�b�Nid
      er.journal_id,--�d��id
-- 2015/03/24 Ver11.5.10.2.7 Add Start
--      er.segment1,  --��ЃR�[�h
      cv_comp_code_001,  -- ��ЃR�[�h�F001�i�{�Ёj
-- 2015/03/24 Ver11.5.10.2.7 Add End
      er.tax_code   --�ŋ敪
--
-- �C�� 1.2 END
    ;

    tax_range_check_rec           tax_range_check_cur%ROWTYPE;              --�e�[�u�����R�[�h

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  ����ID�擾
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    --3.  �I���OID�擾
    ln_org_id := xx00_profile_pkg.value ('ORG_ID') ;

    --4.  �ŋ��I�v�V�����\����

    OPEN gl_tax_options_cur(
        ln_set_of_books_id,         -- 1.����ID
        ln_org_id                   -- 2.�I���OID
    );
    --�ǂݍ���
    FETCH gl_tax_options_cur INTO gl_tax_options_rec;
    IF gl_tax_options_cur%NOTFOUND THEN
      --�߂�l�X�V
      lv_ret_status := cv_status_error;
      RETURN lv_ret_status;
    END IF;
    --�J�[�\���̃N���[�Y
    CLOSE gl_tax_options_cur;

    --5. ����ŋ��e�͈̓J�[�\��
    OPEN tax_range_check_cur(
        in_check_id,                                  -- 1.�`�F�b�NID
        ln_set_of_books_id,                           -- 2.����ID
        gl_tax_options_rec.input_rounding_rule_code,  -- 3.�����[�������K��
        gl_tax_options_rec.output_rounding_rule_code  -- 4.����[�������K��
    );
-- �C�� 1.2 BEGIN
--
    --�G���[�o�͗p�u���C�N�L�[������
    ln_check_id_old        := NULL; -- 1.�`�F�b�NID(�u���C�N�L�[)
    ln_journal_id_old      := NULL; -- 2.�d��ID    (�u���C�N�L�[)
--
-- �C�� 1.2 END

    <<tax_range_check_loop>>
    LOOP
      FETCH tax_range_check_cur INTO tax_range_check_rec;
      EXIT WHEN tax_range_check_cur%NOTFOUND;

      --a)���e�͈͍ő���z�`�F�b�N
      --�ϐ�.���z := ABS(sum_cal_tax  -  sum_tax )
      --�ϐ�.���z >�ϐ�. ���e�͈͍ő���z�̎�
      --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

      IF ABS(tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) >
        TO_NUMBER(gl_tax_options_rec.attribute2) THEN

-- �C�� 1.2 BEGIN
--
        IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL ) OR
           (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN
--
-- �C�� 1.2 END

          lv_error_code   := 'APP-XX03-03037';
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              tax_range_check_rec.check_id    , --1.�`�F�b�NID
              tax_range_check_rec.journal_id  , --2.�d��L�[
              0 ,                               --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              ' '             ,                 --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                 --5.�G���[�R�[�h
              lt_tokeninfo    ,                 --6.�g�[�N�����
-- �C�� 1.4 Begin
--              cv_status_error );
              cv_status_warning );
-- �C�� 1.4 End
          lt_tokeninfo.DELETE;

          --�߂�l�X�V
          lv_ret_status := cv_status_error;
-- �C�� 1.2 BEGIN
--
          --�u���C�N�L�[�ݒ�
          ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.�`�F�b�NID(�u���C�N�L�[)
          ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.�d��ID    (�u���C�N�L�[)
        END IF;
--
-- �C�� 1.2 END

-- �ύX 1.10 BEGIN
--      END IF;
      ELSE
-- �ύX 1.10 END

      --b)���e�͈͗��`�F�b�N
      --�ϐ�.���z := ABS(sum_cal_tax  -  sum_tax )
      --(�ϐ�.���z / sum_no_tax ) * 100�@>�ϐ�. ���e�͈͗��̎�
      --�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

      IF tax_range_check_rec.sum_no_tax != 0 THEN
-- �ύX 1.10 BEGIN
--        IF ( ABS (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
        IF ABS ( (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
-- �ύX 1.10 END
           > TO_NUMBER(gl_tax_options_rec.attribute1) THEN
-- �C�� 1.2 BEGIN
--
          IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL) OR
             (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN

            lv_error_code   := 'APP-XX03-03038';
            lt_tokeninfo.DELETE;
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                tax_range_check_rec.check_id    , --1.�`�F�b�NID
                tax_range_check_rec.journal_id  , --2.�d��L�[
                0 ,                               --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                ' '             ,                 --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                 --5.�G���[�R�[�h
                lt_tokeninfo    ,                 --6.�g�[�N�����
-- �C�� 1.4 Begin
--                cv_status_error );
                cv_status_warning );
-- �C�� 1.4 End
            lt_tokeninfo.DELETE;

            --�߂�l�X�V
            lv_ret_status := cv_status_error;
-- �C�� 1.2 BEGIN
--
            --�u���C�N�L�[�ݒ�
            ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.�`�F�b�NID(�u���C�N�L�[)
            ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.�d��ID    (�u���C�N�L�[)
          END IF;
--
-- �C�� 1.2 END

        END IF;
      ELSE
-- �C�� 1.2 BEGIN
--
-- �ǉ� 1.10 BEGIN
       IF tax_range_check_rec.sum_tax != 0 THEN
-- �ǉ� 1.10 END
        IF (ln_check_id_old IS NULL AND ln_journal_id_old IS NULL) OR
           (ln_check_id_old != tax_range_check_rec.check_id OR ln_journal_id_old != tax_range_check_rec.journal_id ) THEN

-- �ǉ� 1.10 BEGIN
          lv_error_code   := 'APP-XX03-03043';
-- �ǉ� 1.10 END
-- �폜 1.8 BEGIN
--          lv_error_code   := 'APP-XX03-03038';
-- ���� 1.10 BEGIN
          lt_tokeninfo.DELETE;
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              tax_range_check_rec.check_id    , --1.�`�F�b�NID
              tax_range_check_rec.journal_id  , --2.�d��L�[
              0 ,                               --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              ' '             ,                 --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                 --5.�G���[�R�[�h
              lt_tokeninfo    ,                 --6.�g�[�N�����
-- �C�� 1.4 Begin
--              cv_status_error );
              cv_status_warning );
-- �C�� 1.4 End
          lt_tokeninfo.DELETE;

          --�߂�l�X�V
          lv_ret_status := cv_status_error;
-- ���� 1.10 END
-- �폜 1.8 END

          --�u���C�N�L�[�ݒ�
          ln_check_id_old        :=tax_range_check_rec.check_id;    -- 1.�`�F�b�NID(�u���C�N�L�[)
          ln_journal_id_old      :=tax_range_check_rec.journal_id;  -- 2.�d��ID    (�u���C�N�L�[)

        END IF;
-- �ǉ� 1.10 BEGIN
       END IF;
      END IF;
-- �ǉ� 1.10 END
--
-- �C�� 1.2 END
      END IF;

    END LOOP tax_range_check_loop;

    CLOSE tax_range_check_cur;

--
    RETURN lv_ret_status;
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
  END tax_range_check;
--
  /**********************************************************************************
   * Procedure Name   : cf_balance_check
   * Description      : CF�o�����X�`�F�b�N
   ***********************************************************************************/
  FUNCTION cf_balance_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.cf_balance_check'; -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;        --����ID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    --CF�o�����X�`�F�b�N�p�J�[�\��
    CURSOR cf_balance_check_cur(
        in_check_id         IN  xx03_error_checks.check_id%TYPE,            -- 1.�`�F�b�NID
        in_set_of_books_id  IN  xx03_cf_combinations.set_of_books_id%TYPE   -- 2.����ID
    ) IS
    SELECT
      er.check_id,    --�`�F�b�NID
      er.journal_id,   --�d��ID
-- �C�� 1.3 BEGIN
--
--      sum(NVL(er.entered_dr,0)  - NVL(er.entered_cr,0) ) money_diff,  -- ( �ؕ����z -�ݕ����z )
      sum(DECODE(cf.balance_check_flag,'Y',NVL(er.entered_dr,0)  - NVL(er.entered_cr,0),0 ) ) money_diff,  -- ( �ؕ����z -�ݕ����z )
--
-- �C�� 1.3 END
      sum( decode( cf.cf_combination_id,null,-1,0) ) exist_check
    FROM
      xx03_error_checks er,
      xx03_cf_combinations cf
    WHERE
          er.check_id  =  in_check_id
      and er.segment3 = cf.account_code (+)
-- �ύX 1.5 BEGIN
--      and er.incr_decr_reason_code = cf.incr_decr_reason_code(+)
      and nvl(er.incr_decr_reason_code, '#####') =
          nvl(cf.incr_decr_reason_code(+), '#####')
--      and er.incr_decr_reason_code is not null
-- �ύX 1.5 END
      and cf.set_of_books_id (+) = in_set_of_books_id
-- �C�� 1.3 BEGIN
--
--      and cf.balance_check_flag (+) ='Y'
--
-- �C�� 1.3 END
    GROUP  BY
      check_id,    --�`�F�b�NID
      journal_id   --�d��ID
    ;

    cf_balance_check_rec            cf_balance_check_cur%ROWTYPE;             --�e�[�u�����R�[�h

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    --2.  ����ID�擾
    ln_set_of_books_id := xx00_profile_pkg.value ('GL_SET_OF_BKS_ID') ;

    -- 3.CF�o�����X�`�F�b�N�J�[�\���ǂݍ���
    OPEN cf_balance_check_cur(
      in_check_id,        -- 1.�`�F�b�NID,
      ln_set_of_books_id  --2.����ID
    );

    <<cf_balance_check_loop>>
    lt_tokeninfo.DELETE;

    LOOP
      FETCH cf_balance_check_cur INTO cf_balance_check_rec;
      EXIT WHEN cf_balance_check_cur%NOTFOUND;
      --a)CF�g�����}�X�^���݃`�F�b�N
      --exist_check�����̒l�i���W�b�N�ύX�j�̏ꍇ�ACF�g�����}�X�^���擾�ł��Ȃ�����
      --���ׂ��������Ƃ��ăG���[���e�[�u���o�̓T�u�֐�(ins_error
      --_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B

        IF cf_balance_check_rec.exist_check < 0 THEN
          lv_error_code   := 'APP-XX03-03039';
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              cf_balance_check_rec.check_id  ,    --1.�`�F�b�NID
              cf_balance_check_rec.journal_id,    --2.�d��L�[
              0                             ,     --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              ' '             ,                   --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error );
          --�߂�l�X�V
          lv_ret_status := cv_status_error;
        ELSE
          --exist_check��null�łȂ��ꍇ�ŁAsum(er.entered_dr  - er.entered_cr ) ��0
          --�̏ꍇ�G���[���e�[�u���o�̓T�u�֐�(ins_error_tbl)���Ăяo���A�G���[��
          --��e�[�u�����o�͂��܂��B

          IF cf_balance_check_rec.money_diff != 0 THEN
            lv_error_code   := 'APP-XX03-03040';
            lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
                cf_balance_check_rec.check_id  ,    --1.�`�F�b�NID
                cf_balance_check_rec.journal_id,    --2.�d��L�[
                0                             ,     --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
                ' '             ,                   --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
                lv_error_code   ,                   --5.�G���[�R�[�h
                lt_tokeninfo    ,                   --6.�g�[�N�����
                cv_status_error );
            --�߂�l�X�V
            lv_ret_status := cv_status_error;
          END IF;
        END IF;
    END LOOP cf_balance_check_loop;

    CLOSE cf_balance_check_cur;

    RETURN lv_ret_status;
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
  END cf_balance_check;
--
  /**********************************************************************************
   * Procedure Name   : error_importance_check
   * Description      : �G���[�d��x�`�F�b�N
   ***********************************************************************************/
  FUNCTION error_importance_check(
    in_check_id IN NUMBER) -- 1.�`�F�b�NID
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.error_importance_check'; -- �v���O������

    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ln_set_of_books_id              gl_tax_options.set_of_books_id%TYPE;        --����ID

    lt_tokeninfo                    xx03_je_error_check_pkg.TOKENINFO_TTYPE;    --�g�[�N�����
    lv_error_code                   xx03_error_info.error_code%TYPE;            --�G���[�R�[�h
    lv_ret                          xx03_error_info.status%TYPE;                --���^�[���X�e�[�^�X
    lv_ret_status                   xx03_error_info.status%TYPE;                --�߂�l

    --�G���[�d��x�J�[�\���P(�Ώۃ`�F�b�NID���S���擾)
    CURSOR error_importance_check_cur1(
        in_check_id         IN  xx03_error_checks.check_id%TYPE           -- 1.�`�F�b�NID
    ) IS
    SELECT
      count('X') all_recs
    FROM
      xx03_error_info er
    WHERE
      er.check_id  =  in_check_id
    ;
    error_importance_check_rec1           error_importance_check_cur1%ROWTYPE;  --�e�[�u�����R�[�h

    --�G���[�d��x�J�[�\���Q(Max�X�e�[�^�X�擾)
    CURSOR error_importance_check_cur2(
        in_check_id         IN  xx03_error_checks.check_id%TYPE                 -- 1.�`�F�b�NID
    ) IS
    SELECT
      MAX ( TO_NUMBER ( lk.meaning ) ) max_value,
      COUNT(lk.meaning) recs
    FROM
      xx03_error_info er,
      xx03_lookups_xx03_v lk
    WHERE
          er.check_id     =  in_check_id
      and er.status       = lk.lookup_code
      and lk.lookup_type = 'XX03_ERROR_IMPORTANCE'
    ;

    error_importance_check_rec2           error_importance_check_cur2%ROWTYPE;  --�e�[�u�����R�[�h

    --�G���[�d��x�J�[�\���R(�R�[�h�ϊ�)
    CURSOR error_importance_check_cur3(
        in_meaning          IN  NUMBER                                          -- 1.�G���[�d��x
    ) IS
    SELECT
      lookup_code
    FROM
      xx03_lookups_xx03_v lk
    WHERE
        TO_NUMBER( lk.meaning )= in_meaning
    and lk.lookup_type ='XX03_ERROR_IMPORTANCE'
    ;
    error_importance_check_rec3           error_importance_check_cur3%ROWTYPE;  --�e�[�u�����R�[�h

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    --�߂�l������
    lv_ret_status := cv_status_success ;--'S'

    -- 1. �p�����[�^�`�F�b�N
    IF in_check_id IS NULL THEN
      RETURN cv_status_param_err; --'P'
    END IF;

    -- 2.�G���[���e�[�u���Ǎ���
    OPEN error_importance_check_cur1(
        in_check_id
    );

    FETCH error_importance_check_cur1 INTO error_importance_check_rec1;

    IF error_importance_check_cur1%NOTFOUND THEN
      --�ϐ�.���� = 0 �̏ꍇ�́A�߂�l�ɁfS�f��ݒ肵�������I�����܂��B
      --�J�[�\���̃N���[�Y
      CLOSE error_importance_check_cur1;
      RETURN cv_status_success;
    ELSE
      IF error_importance_check_rec1.all_recs = 0THEN
        --�ϐ�.���� = 0 �̏ꍇ�́A�߂�l�ɁfS�f��ݒ肵�������I�����܂��B
        --�J�[�\���̃N���[�Y
        CLOSE error_importance_check_cur1;
        RETURN cv_status_success;
      END IF;
    END IF;
    --�J�[�\���̃N���[�Y
    CLOSE error_importance_check_cur1;

    --3.  �G���[���e�[�u���Ǎ��݁i�ő�d��x�G���[�擾�j
    OPEN error_importance_check_cur2(
        in_check_id
    );

    FETCH error_importance_check_cur2 INTO error_importance_check_rec2;

    IF error_importance_check_cur2%NOTFOUND THEN
      --�ϐ�.���� = 0 �̏ꍇ�́A�߂�l�ɁfE�f��ݒ肵�������I�����܂��B(�ʏ픭�����Ȃ�)
      --�J�[�\���̃N���[�Y
      CLOSE error_importance_check_cur2;
      RETURN cv_status_error;
    ELSE
      --�ϐ�.�����@���ϐ�.�ő�d��x�����̏ꍇ
      --LOOKUP�e�[�u�������񂪎擾�ł��Ȃ������Ƃ��ăG���[���e�[�u���o�̓T�u�֐�
      --(ins_error_tbl)���Ăяo���A�G���[���e�[�u�����o�͂��܂��B
      IF ( error_importance_check_rec2.max_value IS NULL ) or
         ( error_importance_check_rec2.recs != error_importance_check_rec1.all_recs )THEN
          lv_error_code   := 'APP-XX03-03041';
          lv_ret := xx03_je_error_check_pkg.ins_error_tbl(
              in_check_id  ,                      --1.�`�F�b�NID
              ' ',                                --2.�d��L�[
              0                             ,     --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
              ' '             ,                   --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
              lv_error_code   ,                   --5.�G���[�R�[�h
              lt_tokeninfo    ,                   --6.�g�[�N�����
              cv_status_error       );
        CLOSE error_importance_check_cur2;
        RETURN cv_status_error;
      END IF;
    END IF;

    --�J�[�\���̃N���[�Y
    CLOSE error_importance_check_cur2;

    --4.  LOOKUP�e�[�u���ɂ��G���[�R�[�h�ĕϊ�
    OPEN error_importance_check_cur3(
        error_importance_check_rec2.max_value -- 1.�G���[�d��x
    );

    FETCH error_importance_check_cur3 INTO error_importance_check_rec3;

    IF error_importance_check_cur3%NOTFOUND THEN
      --�ϐ�.���� = 0 �̏ꍇ�́A�߂�l�ɁfE�f��ݒ肵�������I�����܂��B(�ʏ픭�����Ȃ�)
      --�J�[�\���̃N���[�Y
      CLOSE error_importance_check_cur3;
      RETURN cv_status_error;
    END IF;

    --�J�[�\���̃N���[�Y
    CLOSE error_importance_check_cur3;

    --5.  �I������
    --�֐��߂�l�ɕϐ�.�G���[�R�[�h��Ԃ��������I�����܂��B

    lv_ret_status := error_importance_check_rec3.lookup_code;
--
    RETURN lv_ret_status;
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
  END error_importance_check;
--
  /**********************************************************************************
   * Procedure Name   : get_check_id
   * Description      : �V�[�P���X���ŐV�̃`�F�b�NID���擾���܂��B
   ***********************************************************************************/
  FUNCTION get_check_id
  RETURN NUMBER IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.get_check_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    ln_check_id         NUMBER;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    SELECT xx03_err_check_s.NEXTVAL
    INTO ln_check_id
    FROM dual;

    RETURN ln_check_id;
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
  END get_check_id;
--
  /**********************************************************************************
   * Procedure Name   : ins_error_tbl
   * Description      : �G���[���e�[�u���o�͊֐�
   ***********************************************************************************/
  FUNCTION ins_error_tbl(
    in_check_id     IN  NUMBER          , --1.�`�F�b�NID
    iv_journal_id   IN  VARCHAR2        , --2.�d��L�[
    in_line_number  IN  NUMBER          , --3.�s�ԍ�
-- �ǉ� ver1.12 �J�n
    iv_dr_cr        IN  VARCHAR2        , --4.�ݎ؋敪
-- �ǉ� ver1.12 �I��
    iv_error_code   IN  VARCHAR2        , --5.�G���[�R�[�h
    it_tokeninfo    IN  TOKENINFO_TTYPE , --6.�g�[�N�����
    iv_status       IN  VARCHAR2        , --7.�X�e�[�^�X
    iv_application  IN  VARCHAR2 DEFAULT 'XX03')
  RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xx03_je_error_check_pkg.pkb.ins_error_tbl'; -- �v���O������


    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    --���ʊ֐��pI/F����
    iv_name           VARCHAR2(1000);
    iv_token_name1    VARCHAR2(1000);
    iv_token_value1   VARCHAR2(1000);
    iv_token_name2    VARCHAR2(1000);
    iv_token_value2   VARCHAR2(1000);
    iv_token_name3    VARCHAR2(1000);
    iv_token_value3   VARCHAR2(1000);
    iv_token_name4    VARCHAR2(1000);
    iv_token_value4   VARCHAR2(1000);
    iv_token_name5    VARCHAR2(1000);
    iv_token_value5   VARCHAR2(1000);
    iv_token_name6    VARCHAR2(1000);
    iv_token_value6   VARCHAR2(1000);
    iv_token_name7    VARCHAR2(1000);
    iv_token_value7   VARCHAR2(1000);
    iv_token_name8    VARCHAR2(1000);
    iv_token_value8   VARCHAR2(1000);
    iv_token_name9    VARCHAR2(1000);
    iv_token_value9   VARCHAR2(1000);
    iv_token_name10   VARCHAR2(1000);
    iv_token_value10  VARCHAR2(1000);

    lv_message        VARCHAR2(2000);

    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    chk_para_expt       EXCEPTION;

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- 1. �p�����[�^�`�F�b�N
    --  �p�����[�^.�`�F�b�NID��NULL or �p�����[�^.�d��L�[��NULL or �p�����[�^.�s�ԍ���NULL�̏ꍇ
    --  �̓p�����[�^�`�F�b�N��O(chk_para_expt)���Ăяo���܂��B

    IF (in_check_id IS NULL) OR (iv_journal_id IS NULL ) OR (in_line_number IS NULL) THEN
      RAISE chk_para_expt;
    END IF;

    -- 2. �G���[���b�Z�[�W�擾
    --  �ȉ��̃p�����[�^���Z�b�g���A���ʊ֐�xx00_message_pkg.get_msg�̖߂�l���G���[���b�Z�[�W��
    --  �ϐ�.�G���[���b�Z�[�W�Ɏ擾���܂��B

    iv_name         :=iv_error_code ; --  ����.�G���[�R�[�h

    IF it_tokeninfo.EXISTS(0) THEN
      iv_token_name1  := it_tokeninfo(0).token_name ; --�g�[�N����
      iv_token_value1 := it_tokeninfo(0).token_value; --�g�[�N���l
    ELSE
      iv_token_name1  :=NULL;
      iv_token_value1 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(1) THEN
      iv_token_name2  := it_tokeninfo(1).token_name ; --�g�[�N����
      iv_token_value2 := it_tokeninfo(1).token_value; --�g�[�N���l
    ELSE
      iv_token_name2  :=NULL;
      iv_token_value2 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(2) THEN
      iv_token_name3  := it_tokeninfo(2).token_name ; --�g�[�N����
      iv_token_value3 := it_tokeninfo(2).token_value; --�g�[�N���l
    ELSE
      iv_token_name3  :=NULL;
      iv_token_value3 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(3) THEN
      iv_token_name4  := it_tokeninfo(3).token_name ; --�g�[�N����
      iv_token_value4 := it_tokeninfo(3).token_value; --�g�[�N���l
    ELSE
      iv_token_name4  :=NULL;
      iv_token_value4 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(4) THEN
      iv_token_name5  := it_tokeninfo(4).token_name ; --�g�[�N����
      iv_token_value5 := it_tokeninfo(4).token_value; --�g�[�N���l
    ELSE
      iv_token_name5  :=NULL;
      iv_token_value5 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(5) THEN
      iv_token_name6  := it_tokeninfo(5).token_name ; --�g�[�N����
      iv_token_value6 := it_tokeninfo(5).token_value; --�g�[�N���l
    ELSE
      iv_token_name6  :=NULL;
      iv_token_value6 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(6) THEN
      iv_token_name7  := it_tokeninfo(6).token_name ; --�g�[�N����
      iv_token_value7 := it_tokeninfo(6).token_value; --�g�[�N���l
    ELSE
      iv_token_name7  :=NULL;
      iv_token_value7 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(7) THEN
      iv_token_name8  := it_tokeninfo(7).token_name ; --�g�[�N����
      iv_token_value8 := it_tokeninfo(7).token_value; --�g�[�N���l
    ELSE
      iv_token_name8  :=NULL;
      iv_token_value8 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(8) THEN
      iv_token_name9  := it_tokeninfo(8).token_name ; --�g�[�N����
      iv_token_value9 := it_tokeninfo(8).token_value; --�g�[�N���l
    ELSE
      iv_token_name9  :=NULL;
      iv_token_value9 :=NULL;
    END IF;
    IF it_tokeninfo.EXISTS(9) THEN
      iv_token_name10  := it_tokeninfo(9).token_name ;  --�g�[�N����
      iv_token_value10 := it_tokeninfo(9).token_value;  --�g�[�N���l
    ELSE
      iv_token_name10  :=NULL;
      iv_token_value10 :=NULL;
    END IF;

    --���ʊ֐�

    lv_message := xx00_message_pkg.get_msg(
      iv_application    ,
      iv_name           ,
      iv_token_name1    ,
      iv_token_value1   ,
      iv_token_name2    ,
      iv_token_value2   ,
      iv_token_name3    ,
      iv_token_value3   ,
      iv_token_name4    ,
      iv_token_value4   ,
      iv_token_name5    ,
      iv_token_value5   ,
      iv_token_name6    ,
      iv_token_value6   ,
      iv_token_name7    ,
      iv_token_value7   ,
      iv_token_name8    ,
      iv_token_value8   ,
      iv_token_name9    ,
      iv_token_value9   ,
      iv_token_name10   ,
      iv_token_value10   );

    INSERT INTO xx03_error_info (
      check_id              ,
      journal_id            ,
      line_number           ,
-- �ǉ� ver1.12 �J�n
      dr_cr                 ,
-- �ǉ� ver1.12 �I��
      error_code            ,
      error_message         ,
      status                ,
      created_by            ,
      creation_date         ,
      last_updated_by       ,
      last_update_date      ,
      last_update_login     ,
      request_id            ,
      program_application_id,
      program_id            ,
      program_update_date
    ) VALUES (
      in_check_id             ,-- check_id
      iv_journal_id           ,-- journal_id
      in_line_number          ,-- line_number
-- �ǉ� ver1.12 �J�n
      iv_dr_cr                ,-- dr_cr
-- �ǉ� ver1.12 �I��
      iv_error_code           ,-- error_code
      lv_message              ,-- error_message
      iv_status               ,-- status
      xx00_global_pkg.created_by            ,-- created_by
      xx00_date_pkg.get_system_datetime_f   ,-- creation_date
      xx00_global_pkg.last_updated_by       ,-- last_updated_by
      xx00_date_pkg.get_system_datetime_f   ,-- last_update_date
      xx00_global_pkg.last_update_login     ,-- last_update_login
      xx00_global_pkg.conc_request_id       ,-- request_id
      xx00_global_pkg.prog_appl_id          ,-- program_application_id
      xx00_global_pkg.conc_program_id       ,-- program_id
      xx00_date_pkg.get_system_datetime_f    -- program_update_date
    );

    RETURN cv_status_success; --����(S)
--
  EXCEPTION
    WHEN chk_para_expt THEN
      RETURN cv_status_param_err; --�p�����[�^�G���[(P)
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END ins_error_tbl;
--

END xx03_je_error_check_pkg;
/
