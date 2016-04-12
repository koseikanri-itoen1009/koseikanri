create or replace PACKAGE BODY apps.xxccp_common_pkg2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg2(body)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.9
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_process_date          F    DATE   �Ɩ��������擾�֐�
 *  get_working_day           F    DATE   �c�Ɠ����t�擾�֐�
 *  chk_moji                  F    BOOL   �֑������`�F�b�N
 *  blob_to_varchar2          P           BLOB�f�[�^�ϊ�
 *  upload_item_check         P           ���ڃ`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-24    1.0  Naoki.Watanabe   �V�K�쐬
 *  2008-11-11    1.1  Yutaka.Kuboshima �֑������`�F�b�N,BLOB�f�[�^�ϊ�,���ڃ`�F�b�N�֐��ǉ�
 *  2009-01-30    1.2  Yutaka.Kuboshima �֑������`�F�b�N�̔��p�X�y�[�X,�A���_�[�o�[��
 *                                      �֑��������珜�O
 *  2009-02-11    1.3  K.Kanada         [�Ɩ��������擾�֐�]�e�X�g���{�p�Ƀv���t�@�C���l��
 *                                      �Ɩ����t���w��\�Ȃ悤�ɕύX
 *  2009-05-01    1.4  Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *  2009-05-11    1.5  Masayuki.Sano    ��Q�ԍ�T1_0376�Ή�(�_�~�[���t�̓��t�ϊ����A�����w��)
 *  2009-06-25    1.6  Yuuki.Nakamura   ��Q�ԍ�T1_1425�Ή�(���������`�F�b�N�폜)
 *  2009-08-17    1.7  Yutaka.Kuboshima ��Q�ԍ�0000818�Ή�(BLOB�ϊ��֐��C��)
 *  2016-02-05    1.8  K.Kiriu          E_�{�ғ�_13456�Ή�(�֑������`�F�b�N�C��)
 *  2016-04-04    1.9  K.Kiriu          E_�{�ғ�_13456�ǉ��Ή�(�֑������`�F�b�N�C��)
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
  gv_msg_cont CONSTANT VARCHAR2(3) := '.';
--
  -- ===============================
  -- ���ʗ�O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCCP_COMMON_PKG2';  -- �p�b�P�[�W��
--
  gv_cnst_msg_kbn        CONSTANT VARCHAR2(5)   := 'XXCCP';
--
  gv_cnst_msg_com3_001   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10111';  -- ۯ��װ
  gv_cnst_msg_com3_002   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10112';  -- �Ώۃf�[�^�Ȃ�
-- 2009/08/17 Ver1.7 add start by Yutaka.Kuboshima
  gv_cnst_msg_com3_003   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10122';  -- ������ϊ��s�G���[
-- 2009/08/17 Ver1.7 add end by Yutaka.Kuboshima
  -- ���ڃ`�F�b�N
  gv_cnst_msg_com3_para1 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10117';  -- �p�����[�^�G���[(���ږ���)
  gv_cnst_msg_com3_para2 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10118';  -- �p�����[�^�G���[(�K�{�t���O)
  gv_cnst_msg_com3_para3 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10119';  -- �p�����[�^�G���[(���ڑ���)
  gv_cnst_msg_com3_para4 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10120';  -- �p�����[�^�G���[(���ڂ̒���)
  gv_cnst_msg_com3_para5 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10121';  -- �p�����[�^�G���[(���ڂ̒���)
  gv_cnst_msg_com3_date  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10113';  -- DATE�^�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_numb  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';  -- NUMBER�^�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_size  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10115';  -- �T�C�Y�`�F�b�N�G���[���b�Z�[�W
  gv_cnst_msg_com3_null  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10116';  -- �K�{�`�F�b�N�G���[���b�Z�[�W
--
  gv_cnst_tkn_item       CONSTANT VARCHAR2(15)  := 'ITEM';
  gv_cnst_tkn_value      CONSTANT VARCHAR2(15)  := 'VALUE';
  gv_cnst_tkn_value1     CONSTANT VARCHAR2(15)  := 'VALUE1';
  gv_cnst_tkn_value2     CONSTANT VARCHAR2(15)  := 'VALUE2';
--
  gv_cnst_period         CONSTANT VARCHAR2(1)   := '.';                 -- �s���I�h
  gv_cnst_err_msg_space  CONSTANT VARCHAR2(6)   := '      ';            -- �X�y�[�X
--
   /**********************************************************************************
   * Function Name    : get_process_date
   * Description      : �Ɩ����t�擾�֐�
   ***********************************************************************************/
  FUNCTION get_process_date
    RETURN DATE
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_process_date';    -- �v���O������
    cv_profile_name  CONSTANT VARCHAR2(100) := 'XXCCP1_DUMMY_PROCESS_DATE';  -- �v���t�@�C���l
--
    --**���[�J���ϐ�**
    ld_prdate     DATE;           -- �Ɩ����t
    lv_profile    VARCHAR2(100);  -- �v���t�@�C���l
  BEGIN
    lv_profile := FND_PROFILE.VALUE(cv_profile_name);
    IF (lv_profile IS NULL) THEN
      SELECT process_date
      INTO   ld_prdate
      FROM   XXCCP_PROCESS_DATES
      ;
    ELSE
-- 2009-05-11 UPDATE Ver.1.5 By Masayuki.Sano Start
--      ld_prdate := to_date(lv_profile) ;
      ld_prdate := TO_DATE(lv_profile, 'DD-MM-YYYY');
-- 2009-05-11 UPDATE Ver.1.5 By Masayuki.Sano End
    END IF;
    RETURN TRUNC(ld_prdate,'DD');
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN NULL;
  END get_process_date;
--

  /**********************************************************************************
   * Function  Name   : get_working_day
   * Description      : �c�Ɠ����t�擾�֐�
   ***********************************************************************************/
  FUNCTION get_working_day(
              id_date          IN DATE
             ,in_working_day   IN NUMBER
             ,iv_calendar_code IN VARCHAR2 DEFAULT NULL
           )
    RETURN DATE
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_working_day'; -- �v���O������
    cv_profile_name CONSTANT VARCHAR2(100) := 'XXCCP1_WORKING_CALENDAR';
    --
    --**���[�J���ϐ�**
    ld_date      DATE;
    ln_count     NUMBER;
    ln_seq       NUMBER;
    lv_profile   VARCHAR2(100);
  BEGIN
    IF (iv_calendar_code IS NULL) THEN
    --�v���t�@�C���擾
      lv_profile := FND_PROFILE.VALUE(cv_profile_name);
    ELSE
      lv_profile := iv_calendar_code;
    END IF;
    --
    IF (lv_profile IS NULL) THEN
      RETURN NULL;
    END IF;
    ld_date    := TRUNC(id_date,'DD');
    --�p�����[�^�F�c�Ɠ�����0�̏ꍇ
    IF (in_working_day = 0) THEN
      BEGIN
        --
        SELECT bcd.seq_num seq_num
        INTO   ln_seq
        FROM   bom_calendar_dates bcd
        WHERE  bcd.calendar_code = lv_profile
        AND    bcd.calendar_date = ld_date;
        --SEQ_NUM��NULL�̏ꍇ
        IF (ln_seq IS NULL) THEN
          RETURN NULL;
        END IF;
        RETURN ld_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      END;
    END IF;
    --�O����
    ln_count   := 0;
    --���[�v
    WHILE ABS(in_working_day) > ln_count LOOP
      --�p�����[�^�F�c�Ɠ��������̐��̏ꍇ
      IF (in_working_day > 0) THEN
        ld_date := ld_date + 1;
      --�p�����[�^�F�c�Ɠ��������̐��̏ꍇ
      ELSIF (in_working_day < 0) THEN
        ld_date := ld_date - 1;
      END IF;
      BEGIN
        SELECT bcd.seq_num       seq_num
        INTO   ln_seq
        FROM   bom_calendar_dates bcd
        WHERE  bcd.calendar_code = lv_profile
        AND    bcd.calendar_date = ld_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      END;
      --SEQ_NUM��NULL�łȂ��ꍇ
      IF (ln_seq IS NOT NULL) THEN
        ln_count := ln_count + 1;
      END IF;
    END LOOP;
    RETURN ld_date;
--
  EXCEPTION
--
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_working_day;
  --
  /**********************************************************************************
   * Function  Name   : chk_moji
   * Description      : �֑������`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_moji(
    iv_check_char  IN VARCHAR2,
    iv_check_scope IN VARCHAR2)
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100) := 'xxccp_common_pkg2.chk_moji'; -- �v���O������
  --�`�F�b�N�͈�
    cv_chk_scope_machine     CONSTANT VARCHAR2(100) := 'VENDING_MACHINE_SYSTEM';     -- ���̋@�V�X�e���`�F�b�N
    cv_chk_scope_garbled     CONSTANT VARCHAR2(100) := 'GARBLED';                    -- ���������`�F�b�N
  --���̋@�V�X�e���`�F�b�N
  --���p����
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu Start
--    cn_chr_code_tab          CONSTANT NUMBER        := 9;                            -- '	'�̕����R�[�h
--    cn_chr_code_exmark       CONSTANT NUMBER        := 33;                           -- '!'�̕����R�[�h
--    cn_chr_code_plus         CONSTANT NUMBER        := 43;                           -- '+'�̕����R�[�h
--    cn_chr_code_colon        CONSTANT NUMBER        := 58;                           -- ':'�̕����R�[�h
--    cn_chr_code_atmark       CONSTANT NUMBER        := 64;                           -- '@'�̕����R�[�h
--    cn_chr_code_bracket      CONSTANT NUMBER        := 91;                           -- '['�̕����R�[�h
--    cn_chr_code_caret        CONSTANT NUMBER        := 94;                           -- '^'�̕����R�[�h
--    cn_chr_code_acsan        CONSTANT NUMBER        := 96;                           -- '`'�̕����R�[�h
--    cn_chr_code_brace        CONSTANT NUMBER        := 123;                          -- '{'�̕����R�[�h
--    cn_chr_code_tilde        CONSTANT NUMBER        := 126;                          -- '~'�̕����R�[�h
--  --�S�p����
--    cn_chr_code_wavy_line    CONSTANT NUMBER        := 33120;                        -- '0'�̕����R�[�h
--    cn_chr_code_union        CONSTANT NUMBER        := 33214;                        -- '��'�̕����R�[�h
--    cn_chr_code_intersection CONSTANT NUMBER        := 33215;                        -- '��'�̕����R�[�h
--    cn_chr_code_corner       CONSTANT NUMBER        := 33242;                        -- '��'�̕����R�[�h
--    cn_chr_code_vertical     CONSTANT NUMBER        := 33243;                        -- '��'�̕����R�[�h
--    cn_chr_code_combination  CONSTANT NUMBER        := 33247;                        -- '��'�̕����R�[�h
--    cn_chr_code_route        CONSTANT NUMBER        := 33251;                        -- '��'�̕����R�[�h
--    cn_chr_code_because      CONSTANT NUMBER        := 33254;                        -- '��'�̕����R�[�h^
--    cn_chr_code_integration  CONSTANT NUMBER        := 33255;                        -- '��'�̕����R�[�h
--    cn_chr_code_maruone      CONSTANT NUMBER        := 34624;                        -- '�@'�̕����R�[�h
--    cn_chr_code_some         CONSTANT NUMBER        := 33248;                        -- '��'�̕����R�[�h
--    cn_chr_code_difference   CONSTANT NUMBER        := 34713;                        -- '��'�̕����R�[�h
-- 2016-04-04 DELETE Ver.1.9 By K.Kiriu Start
--    cn_ampersand             CONSTANT NUMBER        := 38;                           -- '&'�̕����R�[�h
-- 2016-04-04 DELETE Ver.1.9 By K.Kiriu End
    cn_less_than_sign        CONSTANT NUMBER        := 60;                           -- '<'�̕����R�[�h
    cn_greater_than_sign     CONSTANT NUMBER        := 62;                           -- '>'�̕����R�[�h
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu End
  --���������`�F�b�N
  --���p����
    cn_chr_code_yen_mark     CONSTANT NUMBER        := 92;                           -- '\'�̕����R�[�h
  --�S�p����
    cn_chr_code_over_line    CONSTANT NUMBER        := 33104;                        -- '�P'�̕����R�[�h
    cn_chr_code_darshi       CONSTANT NUMBER        := 33116;                        -- '�\'�̕����R�[�h
    cn_chr_code_backslash    CONSTANT NUMBER        := 33119;                        -- '�_'�̕����R�[�h
    cn_chr_code_parallel     CONSTANT NUMBER        := 33121;                        -- '�a'�̕����R�[�h
    cn_chr_code_three_reader CONSTANT NUMBER        := 33123;                        -- '�c'�̕����R�[�h
    cn_chr_code_two_darshi   CONSTANT NUMBER        := 33148;                        -- '�|'�̕����R�[�h
    cn_chr_code_yen_mark_b   CONSTANT NUMBER        := 33167;                        -- '��'�̕����R�[�h
    cn_chr_code_cent         CONSTANT NUMBER        := 33169;                        -- '��'�̕����R�[�h
    cn_chr_code_pound        CONSTANT NUMBER        := 33170;                        -- '��'�̕����R�[�h
    cn_chr_code_not          CONSTANT NUMBER        := 33226;                        -- '��'�̕����R�[�h
--
    -- *** ���[�J���萔 ***
--
    lv_check_char VARCHAR2(2); -- �`�F�b�N�Ώە���
    ln_check_char NUMBER;      -- �`�F�b�N�Ώە����R�[�h
  BEGIN
--
    --�`�F�b�N�Ώە�����NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    --�`�F�b�N�͈�NULL�`�F�b�N
    ELSIF (iv_check_scope IS NULL) THEN
      RETURN NULL;
    --�`�F�b�N�͈͕s���`�F�b�N
    ELSIF (iv_check_scope NOT IN (cv_chk_scope_machine,cv_chk_scope_garbled)) THEN
      RETURN NULL;
    END IF;
    --�`�F�b�N�Ώە������1�����Â`�F�b�N
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      --�`�F�b�N�Ώە������1�����Âɐ؂���
      lv_check_char := SUBSTR(iv_check_char,ln_position,1);
      --�`�F�b�N�Ώە����𕶎��R�[�h�ɕϊ�
      ln_check_char := ASCII(lv_check_char);
      --���̋@�V�X�e���`�F�b�N�̏ꍇ
      IF (iv_check_scope = cv_chk_scope_machine) THEN
        --�֑������`�F�b�N
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu Start
--        IF ((ln_check_char BETWEEN cn_chr_code_colon AND cn_chr_code_atmark)
--          OR (ln_check_char BETWEEN cn_chr_code_exmark AND cn_chr_code_plus)
--          OR (ln_check_char BETWEEN cn_chr_code_bracket AND cn_chr_code_caret)
--          OR (ln_check_char BETWEEN cn_chr_code_brace AND cn_chr_code_tilde)
--          OR (ln_check_char IN (cn_chr_code_tab,cn_chr_code_acsan))
--          OR (ln_check_char BETWEEN cn_chr_code_maruone AND cn_chr_code_difference)
--          OR (ln_check_char IN (cn_chr_code_some,cn_chr_code_combination,cn_chr_code_integration,
--            cn_chr_code_route,cn_chr_code_vertical,cn_chr_code_corner,cn_chr_code_because,
--              cn_chr_code_intersection,cn_chr_code_union,cn_chr_code_wavy_line)))
-- 2016-04-04 UPDATE Ver.1.9 By K.Kiriu Start
--        IF (ln_check_char IN (cn_ampersand,cn_less_than_sign,cn_greater_than_sign) )
        IF (ln_check_char IN (cn_less_than_sign,cn_greater_than_sign) )
-- 2016-04-04 UPDATE Ver.1.9 By K.Kiriu End
-- 2016-02-05 UPDATE Ver.1.8 By K.Kiriu End
        THEN
          RETURN FALSE;
        END IF;
      --���������`�F�b�N�̏ꍇ
      ELSIF (iv_check_scope = cv_chk_scope_garbled) THEN
-- 2009-06-25 MOD Ver.1.6 By Yuuki.Nakamura Start
/*        --�֑������`�F�b�N
        IF ((ln_check_char IN (cn_chr_code_tilde,cn_chr_code_yen_mark))
          OR (ln_check_char = cn_chr_code_yen_mark)
          OR (ln_check_char BETWEEN cn_chr_code_backslash AND cn_chr_code_parallel)
          OR (ln_check_char IN (cn_chr_code_over_line,cn_chr_code_darshi,cn_chr_code_three_reader,
            cn_chr_code_two_darshi,cn_chr_code_yen_mark_b,cn_chr_code_cent,cn_chr_code_pound,cn_chr_code_not)))
        THEN
          RETURN FALSE;
        END IF;*/
        --���TRUE��Ԃ�
        RETURN TRUE;
-- 2009-06-25 MOD Ver.1.6 By Yuuki.Nakamura End
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END chk_moji;
  --
  /**********************************************************************************
   * Procedure Name   : BLOB�f�[�^�ϊ�
   * Description      : blob_to_varchar2
   ***********************************************************************************/
-- 2009/08/17 Ver1.7 modify start by Yutaka.Kuboshima
-- ===============================
-- �S�ʉ��C
-- ===============================
--
-- �G���[���e�F32000�o�C�g�ȏォ�A2�o�C�g���������݂���ꍇ�A���������G���[����������\��������B
--
-- ���Ή����e
-- �C���O�F�ŏ���BLOB����32000�o�C�g�����o���A ������ɕϊ����Ă����ABLOB��32000�o�C�g�ȏ�̏ꍇ��
--         BLOB���Ȃ��Ȃ�܂�10000�o�C�g�����o���ĕ�����ɕϊ����Ă����B 
--
-- �C����FBLOB������s�R�[�h�܂ł����o���A������ɕϊ����Ă����B(1���R�[�h�����o���ĕ�����ɕϊ�) 
--         BLOB���Ȃ��Ȃ�܂ŏ�L���J��Ԃ��B
--
/*
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- �t�@�C���h�c
    ov_file_data OUT NOCOPY g_file_data_tbl, -- �ϊ���VARCHAR2�f�[�^
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'blob_to_varchar2'; -- �v���O������
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
    lv_line_feed                     VARCHAR2(1);                  -- ���s�R�[�h
    lb_src_lob                       BLOB;                         -- �ǂݍ��ݑΏ�BLOB
    lr_bufb                          RAW(32767);                   -- �i�[�o�b�t�@
    lv_str                           VARCHAR2(32767);              -- �L���X�g�ޔ�
    li_amt                           INTEGER;                      -- �ǂݎ��T�C�Y
    li_pos                           INTEGER;                      -- �ǂݎ��J�n�ʒu
    ln_index                         NUMBER;                       -- �s
    lb_index                         BOOLEAN;                      -- �s�쐬�p��
    ln_length                        NUMBER;                       -- �����ۊǗp
    ln_ieof                          NUMBER;                       -- EOF�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_data -- �t�@�C���f�[�^
    INTO   lb_src_lob
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ������
    ov_file_data.delete;
    lv_line_feed := CHR(13); -- ���s�R�[�h
    li_amt := 32000;         -- �ǂݎ��T�C�Y
    li_pos := 1;             -- �ǂݎ��J�n�ʒu
    ln_ieof := 0;            -- EOF�t���O
    ln_index := 0;           -- �s
    lb_index := TRUE;        -- �s�쐬�p��
--
    -- �o�b�t�@�擾
    DBMS_LOB.READ(lb_src_lob, --�ǂݍ��ݑΏ�BLOB
                  li_amt,     --�ǂݎ��T�C�Y
                  li_pos,     --�ǂݎ��J�n�ʒu
                  lr_bufb);   --�i�[�o�b�t�@
--
    -- VARCHAR2�ɕϊ�
    lv_str := UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
    -- ����o�b�t�@�v�Z
    li_pos := li_pos + li_amt;
    li_amt := 10000;
--
    -- ���s�R�[�h���ɕ���
    <<line_loop>>
    LOOP
--
      -- lv_str�����Ȃ��Ȃ�����A�ǉ��o�b�t�@�ǂݍ��݂��s��
      IF ((LENGTH(lv_str) <= 2000) AND (ln_ieof = 0)) THEN
        BEGIN
          -- �o�b�t�@�̓ǂݎ��
          DBMS_LOB.READ(lb_src_lob,--�ǂݍ��ݑΏ�BLOB
                        li_amt,    --�ǂݎ��T�C�Y
                        li_pos,    --�ǂݎ��J�n�ʒu
                        lr_bufb);  --�i�[�o�b�t�@
--
          -- VARCHAR2�ɕϊ�
          lv_str := lv_str || UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
--
          -- ����o�b�t�@�̎擾�ʒu�v�Z
          li_pos := li_pos + li_amt;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          ln_ieof := -1;
        END;
      END IF;
--
      -- �f�[�^�I��
      EXIT WHEN ((lb_index = FALSE) OR (lv_str IS NULL));
--
      -- �s�ԍ����J�E���g�A�b�v�i�����l�͂P�j
      ln_index := ln_index + 1;
--
      -- ���s�R�[�h�̈ʒu���擾
      ln_length := instr(lv_str,lv_line_feed);
--
      -- ���s�R�[�h�����̏ꍇ
      IF (ln_length = 0) THEN
        ln_length := LENGTH(lv_str);
        lb_index := FALSE;
      END IF;
--
      -- �P�s���̏���ۊ�
      IF (lb_index) THEN
        -- ���s�R�[�h�͂̂������߁Aln_length-1
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length - 1);
      ELSE
        ov_file_data(ln_index) := SUBSTR(lv_str,1,ln_length);
      END IF;
--
      --lv_str�͍���擾�����s�������i���s�R�[�hCRLF�͂̂������߁Aln_length + 2�j
      lv_str := SUBSTR(lv_str,ln_length + 2);
--
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END blob_to_varchar2;
--
*/
  /**********************************************************************************
   * Procedure Name   : BLOB�f�[�^�ϊ�
   * Description      : blob_to_varchar2
   ***********************************************************************************/
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- �t�@�C���h�c
    ov_file_data OUT NOCOPY g_file_data_tbl, -- �ϊ���VARCHAR2�f�[�^
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'blob_to_varchar2'; -- �v���O������
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
    cr_line_feed                     CONSTANT RAW(10)     := UTL_RAW.CAST_TO_RAW(CHR(10)); -- ���s�R�[�h
--
    -- *** ���[�J���ϐ� ***
    lb_src_lob                       BLOB;                         -- �ǂݍ��ݑΏ�BLOB
    lr_bufb                          RAW(32767);                   -- �i�[�o�b�t�@
    lv_str                           VARCHAR2(32767);              -- �L���X�g�ޔ�
    li_amt                           INTEGER;                      -- �ǂݎ��T�C�Y
    li_pos                           INTEGER;                      -- �ǂݎ��J�n�ʒu
    li_index                         INTEGER;                      -- �s
    li_save_pos_line_feed            INTEGER;                      -- ���s�R�[�h�ʒu�ޔ�p
    li_pos_line_feed                 INTEGER;                      -- ���s�R�[�h�ʒu
    li_blob_length                   INTEGER;                      -- BLOB�l�̒���
    lb_eof_flag                      BOOLEAN;                      -- EOF�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    not_cast_varchar2_expt           EXCEPTION;                    -- ������ϊ��s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ϐ�������
    ov_file_data.delete;
    li_amt                := 0;      -- �ǂݎ��T�C�Y
    li_pos                := 0;      -- �ǂݎ��J�n�ʒu
    li_index              := 1;      -- �s
    li_pos_line_feed      := 0;      -- ���s�R�[�h�ʒu
    li_save_pos_line_feed := 0;      -- ���s�R�[�h�ʒu�ޔ�p
    lb_eof_flag           := FALSE;  -- EOF�t���O
--
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_data -- �t�@�C���f�[�^
    INTO   lb_src_lob
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
    --
    -- BLOB�l�̒����擾
    li_blob_length := DBMS_LOB.GETLENGTH(lb_src_lob);
--
    -- 1���R�[�h���ɏ���
    <<line_loop>>
    LOOP
--
      -- ���s�R�[�h�̈ʒu���擾���܂�
      li_pos_line_feed := DBMS_LOB.INSTR(lb_src_lob,                -- �ǂݍ��ݑΏ�BLOB
                                         cr_line_feed,              -- ��������(���s�R�[�h)
                                         li_save_pos_line_feed + 1, -- �J�n�ʒu(�O���s�R�[�h + 1)
                                         1);                        -- �o���ԍ�
      -- ���s�R�[�h�����݂��Ȃ��ꍇ
      IF (li_pos_line_feed = 0) THEN
        -- �ǂݎ��T�C�Y�ݒ�(BLOB�l�̒��� - �O��̉��s�R�[�h�ʒu)
        li_amt := li_blob_length - li_save_pos_line_feed;
        -- EOF�t���O�ݒ�
        lb_eof_flag := TRUE;
      ELSE
        -- �ǂݎ��T�C�Y�ݒ�(���s�R�[�h�͓ǎ��Ȃ����߁A-2(�O��̉��s�R�[�h + ����̉��s�R�[�h)�����Ă��܂�)
        li_amt := li_pos_line_feed - li_save_pos_line_feed - 2;
        -- BLOB�̍Ō�̕��������s�R�[�h�̏ꍇ
        IF (li_pos_line_feed = li_blob_length) THEN
          -- EOF�t���O�ݒ�
          lb_eof_flag := TRUE;
        END IF;
      END IF;
      -- �ǂݎ��T�C�Y��32767�o�C�g���傫���ꍇ
      IF (li_amt > 32767) THEN
        -- ������ϊ����s�\�Ȃ��߃G���[�I��
        RAISE not_cast_varchar2_expt;
      END IF;
      -- �o�b�t�@�ǂݎ��J�n�ʒu�ݒ�(�O��̉��s�R�[�h�ʒu�̎��o�C�g����ǂݎ��J�n)
      li_pos := li_save_pos_line_feed + 1;
      -- �o�b�t�@�擾
      DBMS_LOB.READ(lb_src_lob  --�ǂݍ��ݑΏ�BLOB
                   ,li_amt      --�ǂݎ��T�C�Y
                   ,li_pos      --�ǂݎ��J�n�ʒu
                   ,lr_bufb);   --�i�[�o�b�t�@
      -- VARCHAR2�ɕϊ�
      lv_str := UTL_RAW.CAST_TO_VARCHAR2(lr_bufb);
      -- 1�s���̏���ۊ�
      ov_file_data(li_index) := lv_str;
      -- �I�������FEOF�t���O��TRUE�ɂȂ�܂�
      EXIT WHEN (lb_eof_flag = TRUE);
      -- �s�ԍ����J�E���g�A�b�v�i�����l�͂P�j
      li_index := li_index + 1;
      -- ���s�R�[�h�̈ʒu��ޔ������܂�
      li_save_pos_line_feed := li_pos_line_feed;
--
    END LOOP line_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_001);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_002,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    WHEN not_cast_varchar2_expt THEN                    --*** ������ϊ��s�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_003,
                                            gv_cnst_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
      -- �ϊ���VARCHAR2�f�[�^���폜���܂�
      ov_file_data.delete;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END blob_to_varchar2;
--
-- 2009/08/17 Ver1.7 modify end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : ���ڃ`�F�b�N
   * Description      : upload_item_check
   *
   * �i�⑫�j
   *  �����͍��ځ�
   *  ���ږ��́i���ڂ̓��{�ꖼ�j    �F�K�{�F���ڂ̓��{�ꖼ�̂�ݒ�
   *  ���ڂ̒l                      �F�K�{�F���ڂ̒l��ݒ�
   *  ���ڂ̒���                    �F�C�ӁF���ڑ�����VARCHAR2  �̏ꍇ�A�ő包����ݒ�
   *                                        ���ڑ�����DATE      �̏ꍇ�ANULL��ݒ�
   *                                        ���ڑ�����NUMBER�Ō����w�肪����ꍇ�A�����_�ȉ����܂߂�������ݒ�
   *                                                                    �Ȃ��ꍇ�ANULL��ݒ�
   *  ���ڂ̒����i�����_�ȉ��j      �F�C�ӁF���ڑ�����NUMBER�ȊO�̏ꍇ�ANULL��ݒ�
   *                                        ���ڑ�����NUMBER�Ō����w�肪����ꍇ�A�����_�ȉ��̌�����ݒ�B
   *                                        �i�������̂ݎw��̏ꍇ��0��ݒ�j
   *                                                                    �Ȃ��ꍇ�ANULL��ݒ�
   *  �K�{�t���O�i��L�萔��ݒ�j  �F�K�{�F�K�{�t���O��ݒ�
   *  ���ڑ����i��L�萔��ݒ�j    �F�K�{�F���ڑ�����ݒ�
   *
   * �����^�[���R�[�h��
   * ov_retcode=set_status_normal �̏ꍇ�F���ڃ`�F�b�N�̐���Ƃ���
   * ov_retcode=xxccp_common_pkg.set_status_warn   �̏ꍇ�F���ڃ`�F�b�N�ُ̈�I��
   * ov_retcode=xxccp_common_pkg.set_status_error  �̏ꍇ�F���ڃ`�F�b�N�̃V�X�e���G���[
   *
   ***********************************************************************************/
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,         -- ���ږ��́i���ڂ̓��{�ꖼ�j
    iv_item_value     IN          VARCHAR2,         -- ���ڂ̒l
    in_item_len       IN          NUMBER,           -- ���ڂ̒���
    in_item_decimal   IN          NUMBER,           -- ���ڂ̒����i�����_�ȉ��j
    iv_item_nullflg   IN          VARCHAR2,         -- �K�{�t���O�i��L�萔��ݒ�j
    iv_item_attr      IN          VARCHAR2,         -- ���ڑ����i��L�萔��ݒ�j
    ov_errbuf         OUT NOCOPY  VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY  VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY  VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                   CONSTANT VARCHAR2(100)  := 'upload_item_check'; -- �v���O������
    cn_number_max_l               CONSTANT NUMBER         := 38;                  -- NUMBER�^�ő包��
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
    lv_line_feed                     VARCHAR2(1);                  -- ���s�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���ϐ� ***
    lv_err_message      VARCHAR2(32767);  -- �G���[���b�Z�[�W
    ln_period_col       NUMBER;           -- �s���I�h�ʒu
    ln_tonumber         NUMBER;           -- NUMBER�^�`�F�b�N�p
    ld_todate           DATE;             -- DATE�^�`�F�b�N�p
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ�������
    lv_err_message := NULL;     -- ���b�Z�[�W�̈揉����
    lv_line_feed := CHR(10);    -- ���s�R�[�h
--
    -- **************************************************
    -- *** �p�����[�^�`�F�b�N
    -- **************************************************
    -- �u���ږ��́v�`�F�b�N
    IF (iv_item_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para1,
                                            gv_cnst_tkn_value,
                                            iv_item_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u�K�{�t���O�v�`�F�b�N
    IF ((iv_item_nullflg IS NULL) OR (iv_item_nullflg NOT IN (gv_null_ok, gv_null_ng)) )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para2,
                                            gv_cnst_tkn_value,
                                            iv_item_nullflg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �u���ڑ����v�`�F�b�N
    IF ((iv_item_attr IS NULL) OR (iv_item_attr NOT IN (gv_attr_vc2, gv_attr_num, gv_attr_dat))) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_com3_para3,
                                            gv_cnst_tkn_value,
                                            iv_item_attr);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ������VARCHAR2�̏ꍇ�A�u���ڂ̒����v�`�F�b�N
    IF (iv_item_attr = gv_attr_vc2) THEN
      IF (in_item_len IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_com3_para4,
                                              gv_cnst_tkn_value,
                                              in_item_len);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ������NUMBER�̏ꍇ�A�u���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�`�F�b�N
    IF (iv_item_attr = gv_attr_num) THEN
--
--    �u���ڂ̒����v�Ɓu���ڂ̒����i�����_�ȉ��j�v�̐������`�F�b�N
      IF (((in_item_len IS NULL) AND (in_item_decimal IS NULL))
        OR ((in_item_len IS NOT NULL) AND (in_item_decimal IS NOT NULL)))
      THEN
        NULL;
      ELSE
        -- ���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�̒l������NULL�A����
        -- ���ڂ̒����v�E�u���ڂ̒����i�����_�ȉ��j�v�̒l������NOT NULL �łȂ��ȊO�̏ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_com3_para5,
                                              gv_cnst_tkn_value1,
                                              in_item_len,
                                              gv_cnst_tkn_value2,
                                              in_item_decimal);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- **************************************************
    -- *** �K�{�`�F�b�N
    -- **************************************************
    -- �K�{���ڂ̏ꍇ
    IF (iv_item_nullflg = gv_null_ng) THEN
      IF (iv_item_value IS NULL) THEN
        lv_err_message := lv_err_message
                          || gv_cnst_err_msg_space
                          || gv_cnst_err_msg_space
                          || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                      gv_cnst_msg_com3_null,
                                                      gv_cnst_tkn_item,
                                                      iv_item_name)
                          || lv_line_feed;
      END IF;
    END IF;
--
    --���ڂ̒l���ݒ肳��Ă���ꍇ
    IF (iv_item_value IS NOT NULL) THEN
      -- **************************************************
      -- *** VARCHAR2�^�i�t���[�j�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_vc2) THEN
        -- �T�C�Y�`�F�b�N
        IF (LENGTHB(iv_item_value) > in_item_len) THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END IF;
      END IF;
--
      -- **************************************************
      -- *** �m�t�l�a�d�q�^�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_num) THEN
        BEGIN
          -- TO_NUMBER�ł��Ȃ���΃G���[
          ln_tonumber := TO_NUMBER(iv_item_value);
--
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_numb,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
        END;
--
        -- �����w�肪�Ȃ��ꍇ
        IF in_item_len IS NULL THEN
          -- �s���I�h��������������38�����I�[�o�[�����ꍇ�G���[
          IF (LENGTHB(REPLACE(iv_item_value,gv_cnst_period,NULL))) > cn_number_max_l THEN
            lv_err_message := lv_err_message
                              || gv_cnst_err_msg_space
                              || gv_cnst_err_msg_space
                              || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                          gv_cnst_msg_com3_size,
                                                          gv_cnst_tkn_item,
                                                          iv_item_name)
                              || lv_line_feed;
          END IF;
        ELSE
          -- �s���I�h�̈ʒu���擾
          ln_period_col := INSTRB(iv_item_value, gv_cnst_period);
          -- �s���I�h�����̏ꍇ
          IF (ln_period_col = 0) THEN
            -- �������̌������I�[�o�[���Ă���΃G���[
            IF (LENGTHB(iv_item_value) > (in_item_len - in_item_decimal)) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space
                                || gv_cnst_err_msg_space
                                || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
            END IF;
          -- �s���I�h�L��̏ꍇ
          --   �������������I�[�o�[���͏����_�ȉ��������I�[�o�[���Ă���΃G���[
          ELSIF ((ln_period_col -1 > (in_item_len - in_item_decimal))
            OR (LENGTHB(SUBSTRB(iv_item_value, ln_period_col + 1))) > in_item_decimal) THEN
              lv_err_message := lv_err_message
                                || gv_cnst_err_msg_space
                                || gv_cnst_err_msg_space
                                || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                            gv_cnst_msg_com3_size,
                                                            gv_cnst_tkn_item,
                                                            iv_item_name)
                                || lv_line_feed;
          END IF;
--
        END IF;
--
      END IF;
--
      -- **************************************************
      -- *** �c�`�s�d�^�`�F�b�N
      -- **************************************************
      IF (iv_item_attr = gv_attr_dat) THEN
        ld_todate := FND_DATE.STRING_TO_DATE(iv_item_value, 'RR/MM/DD');
        IF (ld_todate IS NULL) THEN
          lv_err_message := lv_err_message
                            || gv_cnst_err_msg_space
                            || gv_cnst_err_msg_space
                            || xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                                        gv_cnst_msg_com3_date,
                                                        gv_cnst_tkn_item,
                                                        iv_item_name)
                            || lv_line_feed;
        END IF;
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** ���b�Z�[�W�̐��`
    -- **************************************************
    -- ���b�Z�[�W���o�^����Ă���ꍇ
    IF (lv_err_message IS NOT NULL) THEN
      -- �Ō�̉��s�R�[�h���폜��OUT�p�����[�^�ɐݒ�
      ov_errmsg := RTRIM(lv_err_message, lv_line_feed);
      -- ���[�j���O�Ƃ��ďI��
      ov_retcode := xxccp_common_pkg.set_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upload_item_check;
  --
END xxccp_common_pkg2;
/
