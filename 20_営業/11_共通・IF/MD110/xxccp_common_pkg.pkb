CREATE OR REPLACE PACKAGE BODY XXCCP_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.2
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  set_status_normal               F    VAR    ����X�e�[�^�X�E�Z�b�g�֐�
 *  set_status_error                F    VAR    �G���[�X�e�[�^�X�E�Z�b�g�֐�
 *  set_status_warn                 F    VAR    �x���X�e�[�^�X�E�Z�b�g�֐�
 *  chk_double_byte                 F    BOOL   �S�p�`�F�b�N
 *  char_byte_partition             F    VAR    �o�C�g�����֐�
 *  get_application                 F    NUM    �A�v���P�[�V����ID�擾�֐�
 *  chk_alphabet_kana               F    BOOL   ���p�p�啶���^���p�J�i�啶���`�F�b�N
 *  chk_alphabet_number_only        F    BOOL   ���p�p�����`�F�b�N �t�@���N�V����(�L���s��)
 *  chk_number                      F    BOOL   ���p�����`�F�b�N
 *  put_log_header                  P           �R���J�����g�w�b�_���b�Z�[�W�o�͊֐�
 *  chk_alphabet_number             F    BOOL   ���p�p�����`�F�b�N
 *  chk_tel_format                  F    BOOL   ���p��������уn�C�t���`�F�b�N
 *  chg_double_to_single_byte       F    BOOL   �S�p�J�^�J�i�p�������p�ϊ�
 *  chg_double_to_single_byte_sub   F    VAR    �S�p�J�^�J�i�p�������p�ϊ�(�T�u)
 *  chk_double_byte_kana            F    BOOL   �S�p�J�^�J�i�`�F�b�N
 *  chk_single_byte_kana            F    BOOL   ���p�J�^�J�i�`�F�b�N
 *  get_msg                         F    VAR    ���b�Z�[�W�擾
 *  char_delim_partition            F    VAR    �f���~�^���������֐�
 *  chk_single_byte                 F    BOOL   ���p������`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-01    1.0  Naoki.Watanabe   �V�K�쐬
 *  2009-02-23    1.1  Kanako.Kitagawa  �d�l�ύX�E�o�O�ɂ��C���i�S�p�J�^�J�i�A���p�J�^�J�i�`�F�b�N)
 *  2009-02-25    1.2  Kazuhisa.Baba    �o�O�ɂ��C���i���p�J�^�J�i�`�F�b�N)
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  cv_msg_part CONSTANT VARCHAR2(3)  := ' : ';
  cv_pkg_name CONSTANT VARCHAR2(50) := 'XXCCP_COMMON_PKG';
  cv_period   CONSTANT VARCHAR2(1)  := '.';
--
  /**********************************************************************************
   * Function Name    : set_status_normal
   * Description      : ����X�e�[�^�X�E�Z�b�g�֐�
   ***********************************************************************************/
  FUNCTION set_status_normal
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_normal'; -- �v���O������
--
  BEGIN
    RETURN '0';
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END set_status_normal;
--
--
/**********************************************************************************
   * Function Name    : set_status_error
   * Description      : �G���[�X�e�[�^�X�E�Z�b�g�֐�
   ***********************************************************************************/
  FUNCTION set_status_error
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_error'; -- �v���O������
--
  BEGIN
    RETURN '2';
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END set_status_error;
--
--
/**********************************************************************************
   * Function Name    : set_status_warn
   * Description      : �x���X�e�[�^�X�E�Z�b�g�֐�
   ***********************************************************************************/
  FUNCTION set_status_warn
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_status_warn'; -- �v���O������
--
  BEGIN
    RETURN '1';
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END set_status_warn;
--
--
/**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : �S�p�`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_double_byte(
                           iv_chk_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                          )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_double_byte'; -- �v���O������
--
  BEGIN
    --NULL�`�F�b�N
    IF (iv_chk_char IS NULL) THEN
      RETURN NULL;
    --�S�p�`�F�b�N
    ELSIF (LENGTH(iv_chk_char) * 2 <> LENGTHB(iv_chk_char)) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN FALSE;
  END chk_double_byte;
--
--
/**********************************************************************************
   * Function Name    : char_byte_partition
   * Description      : �o�C�g�����֐�
   ***********************************************************************************/
  FUNCTION char_byte_partition(iv_char      IN VARCHAR2 --������������
                              ,iv_part_byte IN VARCHAR2 --����byte��
                              ,in_part_num  IN NUMBER   --�ԋp�Ώ�INDEX
                              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'char_byte_partition'; -- �v���O������
--
    --�ϐ���`
    lv_string      VARCHAR2(1000);
    lv_string2     VARCHAR2(1000);
    ln_count       NUMBER;
  BEGIN
--
    --NULL�`�F�b�N
    IF  ((iv_char      IS NULL)
      OR (iv_part_byte IS NULL)
      OR (in_part_num  IS NULL)) THEN
      RETURN NULL;
    END IF;
--
    --������������ƕ����o�C�g���̃T�C�Y��r�`�F�b�N
    IF (LENGTHB(iv_char) < iv_part_byte) THEN
      RETURN NULL;
    END IF;
--
    --�O����
    lv_string     := iv_char;
    ln_count      := 0;
    --�������������byte����������byte��
    WHILE LENGTHB(lv_string) > iv_part_byte LOOP
--
      ln_count      := ln_count + 1;
      lv_string2    := SUBSTRB(lv_string
                         , 1, iv_part_byte);
      lv_string     := SUBSTRB(lv_string,iv_part_byte + 1);
--
      --���ʏI������
      IF (ln_count = in_part_num) THEN
          RETURN lv_string2;
      END IF;
    END LOOP;
--
    ln_count       := ln_count + 1;
    lv_string2     := lv_string;
--
    --RETURN�l�̔��f
    IF (ln_count = in_part_num) THEN
      RETURN lv_string2;
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END char_byte_partition;
--
--
/**********************************************************************************
   * Function Name    : get_application
   * Description      : �A�v���P�[�V����ID�̎擾
   ***********************************************************************************/
  FUNCTION get_application(
                           iv_application_name IN VARCHAR2 --�A�v���P�[�V�����Z�k��
                          )
    RETURN NUMBER
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_application'; -- �v���O������
--
    --�A�v���P�[�V����ID�擾�J�[�\����`
    CURSOR application_cur(iv_application_name VARCHAR2)
    IS
      SELECT a.application_id appli_id
      FROM   fnd_application a
      WHERE  application_short_name = iv_application_name
      ;
    application_val application_cur%ROWTYPE; --�J�[�\���ϐ���`
--
  BEGIN
--
    OPEN application_cur(iv_application_name);
    --
    LOOP
      --
      FETCH application_cur INTO application_val;
      EXIT WHEN application_cur%NOTFOUND;
      --
    END LOOP;
    --�A�v���P�[�V����ID���擾�ł��Ȃ������ꍇ
    IF (application_cur%ROWCOUNT = 0) THEN
      RETURN NULL;
    END IF;
    --
    CLOSE application_cur;
    --
    RETURN application_val.appli_id;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_application;
--
--
/**********************************************************************************
   * Function Name    : chk_alphabet_kana
   * Description      : ���p�p�啶���^���p�J�i�啶���`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_alphabet_kana(
                             iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                            )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_alphabet_kana'; --�v���O������
    cn_check_char_a     CONSTANT NUMBER := 97;                         --a�̕����R�[�h
    cn_check_char_z     CONSTANT NUMBER := 122;                        --z�̕����R�[�h
    cn_check_char_kana1 CONSTANT NUMBER := 167;                        --��̕����R�[�h
    cn_check_char_kana2 CONSTANT NUMBER := 175;                        --��̕����R�[�h
--
    -- *** ���[�J���ϐ� ***
    lv_check_char       VARCHAR2(1);
--
  BEGIN
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- �S�p�����������Ă��邩�ǂ����̃`�F�b�N
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
       RETURN FALSE;
    END IF;
--
    -- ��������Â`�F�b�N
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (((ASCII(lv_check_char) >= cn_check_char_a)
        AND (ASCII(lv_check_char) <= cn_check_char_z))
        OR
         ((ASCII(lv_check_char) >= cn_check_char_kana1)
        AND (ASCII(lv_check_char) <= cn_check_char_kana2)))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END chk_alphabet_kana;
--
--
/**********************************************************************************
   * Function Name    : chk_alphabet_number_only
   * Description      : ���p�p�����`�F�b�N �t�@���N�V����(�L���s��)
   ***********************************************************************************/
  FUNCTION chk_alphabet_number_only(
                                    iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                                   )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_alphabet_number_only'; -- �v���O������
    cv_check_char_0       CONSTANT VARCHAR2(1)   := '0';
    cv_check_char_9       CONSTANT VARCHAR2(1)   := '9';
    cv_check_char_A       CONSTANT VARCHAR2(1)   := 'A';
    cv_check_char_Z       CONSTANT VARCHAR2(1)   := 'Z';
    cv_check_char_small_a CONSTANT VARCHAR2(1)   := 'a';
    cv_check_char_small_z CONSTANT VARCHAR2(1)   := 'z';
--
    -- *** ���[�J���ϐ� ***
    lv_check_char   VARCHAR2(1);
--
  BEGIN
--
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    -- �S�p�����������Ă��邩�ǂ����̃`�F�b�N
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
    -- ��������Â`�F�b�N
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (NOT (
            ((lv_check_char >= cv_check_char_0) AND (lv_check_char <= cv_check_char_9))
            OR
            ((lv_check_char >= cv_check_char_A) AND (lv_check_char <= cv_check_char_Z))
            OR
            ((lv_check_char >= cv_check_char_small_a) AND (lv_check_char <= cv_check_char_small_z)) ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END chk_alphabet_number_only;
--
--
/**********************************************************************************
   * Function Name    : chk_number
   * Description      : ���p�����`�F�b�N
   ***********************************************************************************/
  FUNCTION chk_number(
                      iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                     )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_number'; -- �v���O������
    cv_check_char_period  CONSTANT VARCHAR2(1) := '.';
    cv_check_char_space   CONSTANT VARCHAR2(1) := ' ';
    cv_check_char_plus    CONSTANT VARCHAR2(1) := '+';
    cv_check_char_minus   CONSTANT VARCHAR2(1) := '-';
    -- *** ���[�J���ϐ� ***
    ln_convert_temp       NUMBER;   -- �ϊ��`�F�b�N�p�ꎞ�̈�
--
  BEGIN
--
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- ���l�ϊ����s���A��O�����������琔�l�ȊO�̕������܂܂�Ă���Ɣ��f����
    BEGIN
      ln_convert_temp := TO_NUMBER(iv_check_char);
    EXCEPTION
      WHEN OTHERS THEN  -- ��{�I�ɁuINVALID_NUMBER�v����������
        RETURN FALSE;
    END;
--
    -- �s���I�h�A�O��̋󔒁A�v���X�A�}�C�i�X�`�F�b�N
    IF  ((INSTR(iv_check_char,cv_check_char_period) > 0)
      OR (INSTR(iv_check_char,cv_check_char_space) > 0)
      OR (INSTR(iv_check_char,cv_check_char_plus) > 0)
      OR (INSTR(iv_check_char,cv_check_char_minus) > 0))
    THEN
      RETURN FALSE;
    END IF;
--
    RETURN TRUE;
--
    EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END chk_number;
--
  /**********************************************************************************
   * Procedure Name   : put_log_header
   * Description      : �R���J�����g�w�b�_���b�Z�[�W�o�͊֐�
   ***********************************************************************************/
  PROCEDURE put_log_header(
               iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT'  --�o�͋敪
              ,ov_retcode  OUT VARCHAR2 --���^�[���R�[�h
              ,ov_errbuf   OUT VARCHAR2 --�G���[���b�Z�[�W
              ,ov_errmsg   OUT VARCHAR2 --���[�U�[�E�G���[���b�Z�[�W
                          )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'put_log_header'; -- �v���O����
    cv_xxccp1_request_id        CONSTANT VARCHAR2(100) := 'XXCCP1_REQUEST_ID';
    cv_xxccp1_concurrent_name   CONSTANT VARCHAR2(100) := 'XXCCP1_CONCURRENT_NAME';
    cv_xxccp1_user_name         CONSTANT VARCHAR2(100) := 'XXCCP1_USER_NAME';
    cv_xxccp1_resp_name         CONSTANT VARCHAR2(100) := 'XXCCP1_RESP_NAME';
    cv_xxccp1_actual_start_date CONSTANT VARCHAR2(100) := 'XXCCP1_ACTUAL_START_DATE';
    cv_language                 CONSTANT VARCHAR2(100) := USERENV('LANG');
    cv_massage_name1            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10001';
    cv_massage_name2            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10002';
    cv_massage_name3            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10003';
    cv_massage_name7            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10007';
    cv_application_short        CONSTANT VARCHAR2(100) := 'XXCCP';
    cv_colon                    CONSTANT VARCHAR2(100) := '  :  ';
    cv_null_line                CONSTANT VARCHAR2(1)   := ' ';                 -- ��s���b�Z�[�W�p�萔
    -- *** ���[�J���ϐ� ***
    lv_request_id          VARCHAR2(100) := fnd_global.conc_request_id;        -- �v��ID
    lv_user_name           VARCHAR2(100) := fnd_global.user_name;              -- ���[�U��
    lv_resp_id             VARCHAR2(100) := fnd_global.resp_id;                -- �E��ID
    lv_resp_appl_id        VARCHAR2(100) := fnd_global.resp_appl_id;           -- �E�ӃA�v���P�[�V����ID
    lv_responsibility_name VARCHAR2(100);                                      -- �E�Ӗ�
    lv_message             VARCHAR2(1000);
    lv_message2            VARCHAR2(1000);
    lv_message3            VARCHAR2(1000);
    lv_message4            VARCHAR2(1000);
    lv_message5            VARCHAR2(1000);
    -- ============================================
    -- �R���J�����g�̗v��ID���擾����J�[�\�����`
    -- ============================================
    CURSOR concurrent_cur
    IS
      --
      SELECT   fcpt.user_concurrent_program_name program_name                         --�R���J�����g��
              ,TO_CHAR(fcr.actual_start_date , 'YYYY/MM/DD HH24:MI:SS' ) start_date   --�N������
      FROM     fnd_concurrent_requests    fcr    --�v���Ǘ��}�X�^
              ,fnd_concurrent_programs_tl fcpt   --�v���}�X�^
      WHERE    fcr.request_id = lv_request_id
      AND      fcr.program_application_id = fcpt.application_id
      AND      fcr.concurrent_program_id = fcpt.concurrent_program_id
      AND      fcpt.language = cv_language
      ;
      --
    concurrent_cur_v concurrent_cur%ROWTYPE;  --�J�[�\���ϐ����`
    --
    -- ================
    -- ���[�U�[��`��O
    -- ================
    no_data_expt  EXCEPTION; --�R���J�����g���A�N�����Ԃ𐳏�ɂP���擾�ł��Ȃ������ꍇ�̗�O
    no_data_expt2 EXCEPTION; --�E�Ӗ����擾�ł��Ȃ������ꍇ�̗�O
    iv_which_expt EXCEPTION; --�o�͋敪��'OUTPUT','LOG'�ȊO�̏ꍇ�̗�O
--
  BEGIN
--
    OPEN concurrent_cur;
    --
    LOOP
      --
      FETCH concurrent_cur
      INTO  concurrent_cur_v;
      EXIT WHEN concurrent_cur%NOTFOUND;
      --
    END LOOP;
    --
    IF (concurrent_cur%ROWCOUNT = 0) THEN --�R���J�����g���A�N�����Ԃ𐳏�ɂP���擾�ł��Ȃ������ꍇ�̗�O
      RAISE no_data_expt;
    END IF;
    --
    CLOSE concurrent_cur;
    --
    BEGIN
      SELECT  frt.responsibility_name resp_name --�E�Ӗ�
      INTO    lv_responsibility_name
      FROM    fnd_responsibility_tl frt
      WHERE   frt.responsibility_id = lv_resp_id
      AND     frt.application_id = lv_resp_appl_id
      AND     frt.language = cv_language
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN --�E�Ӗ����擾�ł��Ȃ������ꍇ
        RAISE no_data_expt2;
    END;
    --
    lv_message  := FND_PROFILE.VALUE(cv_xxccp1_request_id) || cv_colon||lv_request_id;
    lv_message2 := FND_PROFILE.VALUE(cv_xxccp1_concurrent_name) ||cv_colon||
                   concurrent_cur_v.program_name;
    lv_message3 := FND_PROFILE.VALUE(cv_xxccp1_user_name) || cv_colon||lv_user_name;
    lv_message4 := FND_PROFILE.VALUE(cv_xxccp1_resp_name) || cv_colon||lv_responsibility_name;
    lv_message5 := FND_PROFILE.VALUE(cv_xxccp1_actual_start_date) || cv_colon||
                   concurrent_cur_v.start_date;
    --
    IF (iv_which = 'OUTPUT') THEN
      fnd_file.put_line(fnd_file.output,lv_message);
      fnd_file.put_line(fnd_file.output,lv_message2);
      fnd_file.put_line(fnd_file.output,lv_message3);
      fnd_file.put_line(fnd_file.output,lv_message4);
      fnd_file.put_line(fnd_file.output,lv_message5);
      fnd_file.put_line(fnd_file.output,cv_null_line);
    ELSIF (iv_which = 'LOG') THEN
      fnd_file.put_line(fnd_file.log,lv_message);
      fnd_file.put_line(fnd_file.log,lv_message2);
      fnd_file.put_line(fnd_file.log,lv_message3);
      fnd_file.put_line(fnd_file.log,lv_message4);
      fnd_file.put_line(fnd_file.log,lv_message5);
      fnd_file.put_line(fnd_file.log,cv_null_line);
    ELSE
      RAISE iv_which_expt;
    END IF;
    --
    ov_retcode := xxccp_common_pkg.set_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    --
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN no_data_expt  THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name1
                                            );
--
    WHEN no_data_expt2 THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name2
                                            );
--
    WHEN iv_which_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name7
                                            );
--
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTR(cv_pkg_name||cv_period||cv_prg_name || SQLERRM , 1, 5000);
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application => cv_application_short
                                            ,iv_name        => cv_massage_name3
                                            );
--
--###################################  �Œ蕔 END   #########################################
--
  END put_log_header;
--
  /**********************************************************************************
   * Function Name    : chk_alphabet_number
   * Description      : ���p�p����(�L����)�`�F�b�N �t�@���N�V����
   ***********************************************************************************/
--
  FUNCTION chk_alphabet_number(
                               iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                              )
    RETURN BOOLEAN               -- TRUE,FALSE,NULL
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_alphabet_number'; -- �v���O������
    cv_exclamation CONSTANT VARCHAR2(1) := '!';                     -- ���Q��
    cv_tilde       CONSTANT VARCHAR2(1) := '~';                     -- �`���_
--
    -- *** ���[�J���ϐ� ***
    lv_check_char VARCHAR2(1);
--
  BEGIN
  --
--
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    -- �S�p�����������Ă��邩�ǂ����̃`�F�b�N
    IF (LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
    -- ��������Â`�F�b�N
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      IF (NOT ((lv_check_char >= cv_exclamation) AND (lv_check_char <= cv_tilde))) THEN
        RETURN FALSE;
      END IF;
    END LOOP;
--
    RETURN TRUE;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN FALSE;
--
  END chk_alphabet_number;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : ���p���� �n�C�t���`�F�b�N �t�@���N�V����
   ***********************************************************************************/
--
  FUNCTION chk_tel_format(
                          iv_check_char VARCHAR2 --�`�F�b�N�Ώە�����
                         )
    RETURN BOOLEAN               -- TRUE,FALSE,NULL
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_tel_format'; -- �v���O������
    cv_hyphen     CONSTANT VARCHAR2(1)   := '-';              -- �n�C�t��
--
    -- *** ���[�J���ϐ� ***
    lv_check_string    VARCHAR2(1000);   -- �ϊ���̃`�F�b�N�Ώە�����
--
  BEGIN
--
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
      RETURN NULL;
    END IF;
--
    --�����񂪃n�C�t���݂̂̏ꍇTRUE��ԋp
    IF REPLACE(iv_check_char,cv_hyphen,'') IS NULL THEN
      RETURN TRUE;
    END IF;
--
    -- �n�C�t���̂ݍ폜���āAchk_number�����s����
    RETURN xxccp_common_pkg.chk_number(iv_check_char => REPLACE(iv_check_char
                                                               ,cv_hyphen
                                                               ,''
                                                               )
                                      );
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN FALSE;
--
  END chk_tel_format;
--
--
  /**********************************************************************************
   * Function  Name   : chg_double_to_single_byte_sub
   * Description      : �S�p�J�^�J�i�p�������p�ϊ��v���V�[�W���i�ϊ����jInternal
   ***********************************************************************************/
--
  FUNCTION chg_double_to_single_byte_sub(
                                     iv_check_char IN  VARCHAR2 --�ϊ��Ώە���
                                    )
    RETURN VARCHAR2     -- �ϊ����ʕ���
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'chg_double_to_single_byte_sub';
    cv_dakuten           CONSTANT VARCHAR2(1)   := CHR(222);
    cv_handakuten        CONSTANT VARCHAR2(1)   := CHR(223);
    cn_string_code1_s    CONSTANT NUMBER        := 33600; --�S�p�@�i�̕����R�[�h�j
    cn_string_code1_e    CONSTANT NUMBER        := 33609; --�S�p�I
    cn_string_code1_dif  CONSTANT NUMBER        := 33423; --�ϊ��O�ƕϊ���̕����R�[�h�̍��i�ȉ��ȗ��j
    cn_string_code2_s    CONSTANT NUMBER        := 33610; --�S�p�J
    cn_string_code2_e    CONSTANT NUMBER        := 33633; --�S�p�a
    cn_string_code2_dif  CONSTANT NUMBER        := 33428;
    cn_string_code3_s    CONSTANT NUMBER        := 33637; --�S�p�e
    cn_string_code3_e    CONSTANT NUMBER        := 33640; --�S�p�h
    cn_string_code3_dif  CONSTANT NUMBER        := 33442;
    cn_string_code4_s    CONSTANT NUMBER        := 33641; --�S�p�i
    cn_string_code4_e    CONSTANT NUMBER        := 33645; --�S�p�m
    cn_string_code4_dif  CONSTANT NUMBER        := 33444;
    cn_string_code5_s    CONSTANT NUMBER        := 33646; --�S�p�n
    cn_string_code5_e    CONSTANT NUMBER        := 33660; --�S�p�|
    cn_string_code5_dif  CONSTANT NUMBER        := 33444;
    cn_string_code6_s    CONSTANT NUMBER        := 167;   --�S�p�@
    cn_string_code6_e    CONSTANT NUMBER        := 171;   --�S�p�H
    cn_string_code6_dif  CONSTANT NUMBER        := 10;    
    cn_string_code7_s    CONSTANT NUMBER        := 33661; --�S�p�}
    cn_string_code7_e    CONSTANT NUMBER        := 33666; --�S�p��
    cn_string_code7_dif  CONSTANT NUMBER        := 33454;
    cn_string_code8_s    CONSTANT NUMBER        := 33667; --�S�p��
    cn_string_code8_e    CONSTANT NUMBER        := 33672; --�S�p��
    cn_string_code8_dif  CONSTANT NUMBER        := 33455;
    cn_string_code9_s    CONSTANT NUMBER        := 33673; --�S�p��
    cn_string_code9_e    CONSTANT NUMBER        := 33677; --�S�p��
    cn_string_code9_dif  CONSTANT NUMBER        := 33458;
    cn_string_code10_s   CONSTANT NUMBER        := 33089; --�S�p�A
    cn_string_code10_e   CONSTANT NUMBER        := 33092; --�S�p�D
    cn_string_code10_dif CONSTANT NUMBER        := 33043;
    cn_string_code11_s   CONSTANT NUMBER        := 33376; --�S�p�`
    cn_string_code11_e   CONSTANT NUMBER        := 33401; --�S�p�y
    cn_string_code12_s   CONSTANT NUMBER        := 33409; --�S�p��
    cn_string_code12_e   CONSTANT NUMBER        := 33434; --�S�p��
    cn_string_code13_s   CONSTANT NUMBER        := 33359; --�S�p�O
    cn_string_code13_e   CONSTANT NUMBER        := 33368; --�S�p�X
    cn_string_code14_b   CONSTANT NUMBER        := 33680; --�S�p��
    cn_string_code14_a   CONSTANT NUMBER        := 178;   --���p�
    cn_string_code15_b   CONSTANT NUMBER        := 33681; --�S�p��
    cn_string_code15_a   CONSTANT NUMBER        := 180;   --���p�
    cn_string_code16_b   CONSTANT NUMBER        := 33682; --�S�p��
    cn_string_code16_a   CONSTANT NUMBER        := 181;   --���p�
    cn_string_code17_b   CONSTANT NUMBER        := 33685; --�S�p��
    cn_string_code17_a   CONSTANT NUMBER        := 182;   --���p�
    cn_string_code18_b1  CONSTANT NUMBER        := 33634; --�S�p�b
    cn_string_code18_b2  CONSTANT NUMBER        := 33635; --�S�p�c
    cn_string_code18_b3  CONSTANT NUMBER        := 175;   --���p�
    cn_string_code18_a   CONSTANT NUMBER        := 194;   --���p�
    cn_string_code19_b   CONSTANT NUMBER        := 33636; --�S�p�d
    cn_string_code19_a   CONSTANT NUMBER        := 194;   --���p�
    cn_string_code20_b1  CONSTANT NUMBER        := 33678; --�S�p��
    cn_string_code20_b2  CONSTANT NUMBER        := 33679; --�S�p��
    cn_string_code20_a   CONSTANT NUMBER        := 220;   --���p�
    cn_string_code21_b   CONSTANT NUMBER        := 33683; --�S�p��
    cn_string_code21_a   CONSTANT NUMBER        := 221;   --���p�
    cn_string_code22_b   CONSTANT NUMBER        := 33684; --�S�p��
    cn_string_code22_a   CONSTANT NUMBER        := 179;   --���p�
    cn_string_code23_b   CONSTANT NUMBER        := 33098; --�S�p�J
    cn_string_code23_a   CONSTANT NUMBER        := 222;   --���p�
    cn_string_code24_b   CONSTANT NUMBER        := 33099; --�S�p�K
    cn_string_code24_a   CONSTANT NUMBER        := 223;   --���p�
    cn_string_code25_b1  CONSTANT NUMBER        := 33115; --�S�p�[
    cn_string_code25_b2  CONSTANT NUMBER        := 33116; --�S�p�\
    cn_string_code25_b3  CONSTANT NUMBER        := 176;   --���p�
    cn_string_code25_b4  CONSTANT NUMBER        := 33117; --�S�p�]
    cn_string_code25_b5  CONSTANT NUMBER        := 33120; --�S�p�`
    cn_string_code25_b6  CONSTANT NUMBER        := 33104; --�S�p�P
    cn_string_code25_a   CONSTANT NUMBER        := 45;    --���p-
    cn_string_code26_b1  CONSTANT NUMBER        := 164;   --���p�
    cn_string_code26_b2  CONSTANT NUMBER        := 44;    --���p,
    cn_string_code26_b3  CONSTANT NUMBER        := 161;   --���p�
    cn_string_code26_a   CONSTANT NUMBER        := 46;    --���p.
    cn_string_code27_s   CONSTANT NUMBER        := 97;    --���pa
    cn_string_code27_e   CONSTANT NUMBER        := 122;   --���pz
    cn_string_code28     CONSTANT NUMBER        := 48;    --���p0
    cn_string_code29     CONSTANT NUMBER        := 57;    --���p9
    cn_string_code30     CONSTANT NUMBER        := 65;    --���pA
    cn_string_code31     CONSTANT NUMBER        := 90;    --���pZ
    cn_string_code32     CONSTANT NUMBER        := 177;   --���p�
    cn_string_code33_b   CONSTANT NUMBER        := 33686;  --���p�
    cn_string_code33_a   CONSTANT NUMBER        := 185;   --���p�
                                                                                -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_converted_char VARCHAR2(2);  -- �ϊ����ʕ���
    ln_count          NUMBER;
    ln_count2         NUMBER;
    ln_loop_count     NUMBER;
--
  BEGIN
--
    IF (iv_check_char IN (' ','(',')','-','.')
      OR iv_check_char BETWEEN CHR(cn_string_code28) AND CHR(cn_string_code29)
      OR iv_check_char BETWEEN CHR(cn_string_code30) AND CHR(cn_string_code31)
      OR iv_check_char BETWEEN CHR(cn_string_code32) AND CHR(cn_string_code24_a))
    THEN
      lv_converted_char := iv_check_char;
    --�S�p�A(�@)����I(�H)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code1_s AND cn_string_code1_e)
    THEN
      ln_count      := cn_string_code1_s;
      ln_count2     := cn_string_code1_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --�S�p�J(�K)����`(�a)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code2_s AND cn_string_code2_e)
    THEN
      ln_count      := cn_string_code2_s;
      ln_count2     := cn_string_code2_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          IF MOD(ln_loop_count,2) = 1 THEN
            RETURN CHR(ln_count - ln_count2)||cv_dakuten;
          END IF;
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --�S�p�e(�f)����g(�h)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code3_s AND cn_string_code3_e)
    THEN
      ln_count      := cn_string_code3_s;
      ln_count2     := cn_string_code3_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          IF MOD(ln_loop_count,2) = 1 THEN
            RETURN CHR(ln_count - ln_count2)||cv_dakuten;
          END IF;
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --�S�p�i����m
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code4_s AND cn_string_code4_e)
    THEN
      ln_count      := cn_string_code4_s;
      ln_count2     := cn_string_code4_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --�S�p�n(�o)(�p)����z(�{)(�|)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code5_s AND cn_string_code5_e)
      THEN
        ln_count      := cn_string_code5_s;
        ln_count2     := cn_string_code5_dif;
        ln_loop_count := 0;
        LOOP
          IF ASCII(iv_check_char) = ln_count THEN
            IF (ln_loop_count IN (1,4,7,10,13)) THEN
              RETURN CHR(ln_count - ln_count2)||cv_dakuten;
            ELSIF (ln_loop_count IN (2,5,8,11,14)) THEN
              RETURN CHR(ln_count - ln_count2)||cv_handakuten;
            END IF;
            RETURN CHR(ln_count - ln_count2);
          END IF;
          ln_count      := ln_count +1;
          ln_loop_count := ln_loop_count + 1;
          IF (ln_loop_count NOT IN(3,6,9,12,15)) THEN
          ln_count2 := ln_count2 +1;
          END IF;
        END LOOP;
    --���p�����
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code6_s AND cn_string_code6_e)
    THEN
      ln_count      := cn_string_code6_s;
      ln_count2     := cn_string_code6_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count + ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --�S�p�}���烂
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code7_s AND cn_string_code7_e)
    THEN
      ln_count      := cn_string_code7_s;
      ln_count2     := cn_string_code7_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF (ln_loop_count = 1) THEN
          ln_count      := ln_count +1;
          ln_count2     := ln_count2 +1;
        END IF;
          ln_count      := ln_count +1;
          ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --�S�p��(��)���烈(��)
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code8_s AND cn_string_code8_e)
    THEN
      ln_count      := cn_string_code8_s;
      ln_count2     := cn_string_code8_dif;
      ln_loop_count := 0;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        IF MOD(ln_loop_count,2) = 0 THEN
          ln_count2 := ln_count2 +1;
        END IF;
        ln_count      := ln_count +1;
        ln_loop_count := ln_loop_count + 1;
      END LOOP;
    --�S�p�����烍
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code9_s AND cn_string_code9_e)
    THEN
      ln_count      := cn_string_code9_s;
      ln_count2     := cn_string_code9_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count +1;
      END LOOP;
    --�S�p�u�A�v����u�D�v
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code10_s AND cn_string_code10_e)
    THEN
      ln_count      := cn_string_code10_s;
      ln_count2     := cn_string_code10_dif;
      LOOP
        IF ASCII(iv_check_char) = ln_count THEN
          RETURN CHR(ln_count - ln_count2);
        END IF;
        ln_count      := ln_count + 1;
        ln_count2     := ln_count2 + 1;
      END LOOP;
    --�S�p�`����y
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code10_s AND cn_string_code10_e)
      THEN
        RETURN TO_SINGLE_BYTE(iv_check_char);
    --�S�p�����炚
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code12_s AND cn_string_code12_e)
      THEN
        lv_converted_char := TO_SINGLE_BYTE(iv_check_char);
        RETURN UPPER(lv_converted_char);
    --���pa����z
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code27_s AND cn_string_code27_e)
      THEN
        RETURN UPPER(iv_check_char);
    --�S�p�O����X
    ELSIF (ASCII(iv_check_char) BETWEEN cn_string_code13_s AND cn_string_code13_e) THEN
      RETURN TO_SINGLE_BYTE(iv_check_char);
    --���̑��ϊ�����
    ELSIF(ASCII(iv_check_char) = cn_string_code14_b) THEN --��
      lv_converted_char := CHR(cn_string_code14_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code15_b) THEN --��
      lv_converted_char := CHR(cn_string_code15_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code16_b) THEN --��
      lv_converted_char := CHR(cn_string_code16_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code17_b) THEN --��
      lv_converted_char := CHR(cn_string_code17_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code33_b) THEN --��
      lv_converted_char := CHR(cn_string_code33_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code18_b1)      --�b
      OR (ASCII(iv_check_char) = cn_string_code18_b2)      --�c
      OR (ASCII(iv_check_char) = cn_string_code18_b3)      --�
    THEN
      lv_converted_char := CHR(cn_string_code18_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code19_b) THEN --�d
      lv_converted_char := CHR(cn_string_code19_a)||cv_dakuten; --��
    ELSIF(ASCII(iv_check_char) = cn_string_code20_b1)      --��
      OR (ASCII(iv_check_char) = cn_string_code20_b2)      --��
    THEN
      lv_converted_char := CHR(cn_string_code20_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code21_b) THEN --��
      lv_converted_char := CHR(cn_string_code21_a);          --�
    ELSIF(ASCII(iv_check_char) = cn_string_code22_b) THEN --��
      lv_converted_char := CHR(cn_string_code22_a)||cv_dakuten; --��
    ELSIF(ASCII(iv_check_char) = cn_string_code23_b) THEN --�u�J�v
      lv_converted_char := CHR(cn_string_code23_a);          --�uށv
    ELSIF(ASCII(iv_check_char) = cn_string_code24_b) THEN --�u�K�v
      lv_converted_char := CHR(cn_string_code24_a);          --�u߁v
    ELSIF(ASCII(iv_check_char) = cn_string_code25_b1)     --�u�[�v
      OR (ASCII(iv_check_char) = cn_string_code25_b2)     --�u�\�v
      OR (ASCII(iv_check_char) = cn_string_code25_b3)     --�u��v
      OR (ASCII(iv_check_char) = cn_string_code25_b4)     --�u�]�v
      OR (ASCII(iv_check_char) = cn_string_code25_b5)     --�u�`�v
      OR (ASCII(iv_check_char) = cn_string_code25_b6)     --�u�P�v
    THEN
      lv_converted_char := CHR(cn_string_code25_a);          --�u-�v
    ELSIF(ASCII(iv_check_char) = cn_string_code26_b1)     --�u��v
      OR (ASCII(iv_check_char) = cn_string_code26_b2)     --�u,�v
      OR (ASCII(iv_check_char) = cn_string_code26_b3)     --�u��v
    THEN
      lv_converted_char := CHR(cn_string_code26_a);          --�u.�v
    ELSE
      lv_converted_char := TO_SINGLE_BYTE(iv_check_char);
    END IF;
--
    RETURN lv_converted_char;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
--
  END chg_double_to_single_byte_sub;
--
  /**********************************************************************************
   * Function  Name   : chg_double_to_single_byte
   * Description      : �S�p�J�^�J�i�p�������p�ϊ��v���V�[�W���i�Ăяo�����j
   ***********************************************************************************/
--
  FUNCTION chg_double_to_single_byte(
                                     iv_check_char IN  VARCHAR2 --�ϊ��Ώە�����
                                    )
    RETURN VARCHAR2     -- �ϊ����ʕ�����
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chg_double_to_single_byte';
                                                                                -- �v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_check_char   VARCHAR2(2);
    lv_checked_char VARCHAR2(2);
    lv_cvt_string   VARCHAR2(1000);
--
  BEGIN
--
    --NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
      RETURN iv_check_char;
    END IF;
--
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
       lv_check_char := SUBSTR(iv_check_char
                              ,ln_position
                              ,1
                              );
       lv_checked_char := xxccp_common_pkg.chg_double_to_single_byte_sub(lv_check_char);
       lv_cvt_string := lv_cvt_string||lv_checked_char;
    END LOOP;
  RETURN lv_cvt_string;
--
  EXCEPTION
--
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END chg_double_to_single_byte;
--
  --
  /**********************************************************************************
   * Function  Name   : chk_double_byte_kana
   * Description      : �S�p�J�^�J�i�`�F�b�N
   ***********************************************************************************/
--
  FUNCTION chk_double_byte_kana(
                                iv_check_char IN  VARCHAR2 --�`�F�b�N�Ώە�����
                               )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_double_byte_kana'; -- �v���O������
    cn_string_code1 CONSTANT NUMBER        := 33600; --�S�p�@
    cn_string_code2 CONSTANT NUMBER        := 33684; --�S�p��
    cn_string_code3 CONSTANT NUMBER        := 33685; --�S�p��
    cn_string_code4 CONSTANT NUMBER        := 33686; --�S�p��
    cn_string_code5 CONSTANT NUMBER        := 33115; --�S�p�[
    cn_string_code6 CONSTANT NUMBER        := 33129; --�S�p�i
    cn_string_code7 CONSTANT NUMBER        := 33130; --�S�p�j
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_check_char   VARCHAR2(2);       --�����i�[�p
--
  BEGIN
    --NULL�`�F�b�N
    IF(iv_check_char IS NULL) THEN
      RETURN NULL;
    --���p���������݂���ꍇ�AFALSE
    ELSIF(LENGTH(iv_check_char) * 2 <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
-- 2009/02/23 K.Kitagawa START
    --LOOP�����J�n
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
    --��������Â��o��
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
      --�S�p�J�^�J�i�A�@�A���A�i�A�j�A�[�ł͂Ȃ��ꍇ�AFALSE��Ԃ�
      IF (NOT(
              ((lv_check_char >= CHR(cn_string_code1)) AND (lv_check_char <= CHR(cn_string_code2)))
               OR
              ((lv_check_char = CHR(cn_string_code3)) OR (lv_check_char = CHR(cn_string_code4)))
               OR
              (lv_check_char IN (CHR(cn_string_code5),CHR(cn_string_code6),CHR(cn_string_code7)))
              ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
    --��L�ɍ��v���Ȃ��ꍇ�ATRUE��ԋp
    RETURN TRUE;
-- 2009/02/23 K.Kitagawa END
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
--
  END chk_double_byte_kana;
  --
  /**********************************************************************************
   * Function  Name   : chk_single_byte_kana
   * Description      : ���p�J�^�J�i�`�F�b�N
   ***********************************************************************************/
--
  FUNCTION chk_single_byte_kana(
                                iv_check_char IN  VARCHAR2 --�`�F�b�N�Ώە�����
                               )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_single_byte_kana';  -- �v���O������
    cn_string_code1 CONSTANT NUMBER        := 166; --���p�
    cn_string_code2 CONSTANT NUMBER        := 175; --���p�
    cn_string_code3 CONSTANT NUMBER        := 177; --���p�
    cn_string_code4 CONSTANT NUMBER        := 221; --���p�
--  2009/02/25 Kazuhisa.Baba START
    cn_string_code5 CONSTANT NUMBER        := 222; --���p�
    cn_string_code6 CONSTANT NUMBER        := 223; --���p�
    cn_string_code7 CONSTANT NUMBER        := 176; --���p�
--  2009/02/25 Kazuhisa.Baba END
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_check_char   VARCHAR2(1);       --�����i�[�p
--
  BEGIN
    --NULL�`�F�b�N
    IF(iv_check_char IS NULL) THEN
      RETURN NULL;
    --���p�`�F�b�N
    ELSIF(LENGTH(iv_check_char) <> LENGTHB(iv_check_char)) THEN
      RETURN FALSE;
    END IF;
--
-- 2009/02/23 K.Kitagawa START
    --LOOP�����J�n
    FOR ln_position IN 1..LENGTH(iv_check_char) LOOP
      -- ��������Â��o��
      lv_check_char := SUBSTR(iv_check_char
                             ,ln_position
                             ,1
                             );
--
      --���p�J�^�J�i�ł͂Ȃ��ꍇ�AFALSE��Ԃ�
      IF  (NOT(
              ((lv_check_char >= CHR(cn_string_code1)) AND (lv_check_char <= CHR(cn_string_code2)))
              OR 
              ((lv_check_char >= CHR(cn_string_code3)) AND (lv_check_char <= CHR(cn_string_code4)))
              OR 
              (lv_check_char IN (CHR(cn_string_code5),CHR(cn_string_code6),CHR(cn_string_code7)))
           ))
      THEN
        RETURN FALSE;
      END IF;
    END LOOP;
    --��L�ɍ��v���Ȃ��ꍇ�ATRUE��ԋp
    RETURN TRUE;
-- 2009/02/23 K.Kitagawa END
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
--
  END chk_single_byte_kana;
  --
  --
  /**********************************************************************************
   * Function  Name   : get_msg
   * Description      : ���b�Z�[�W�擾
   ***********************************************************************************/
  FUNCTION get_msg(
                   iv_application    IN VARCHAR2 --�A�v���P�[�V�����Z�k��
                  ,iv_name           IN VARCHAR2 --���b�Z�[�W�R�[�h
                  ,iv_token_name1    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h1
                  ,iv_token_value1   IN VARCHAR2 DEFAULT NULL --�g�[�N���l1
                  ,iv_token_name2    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h2
                  ,iv_token_value2   IN VARCHAR2 DEFAULT NULL --�g�[�N���l2
                  ,iv_token_name3    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h3
                  ,iv_token_value3   IN VARCHAR2 DEFAULT NULL --�g�[�N���l4
                  ,iv_token_name4    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h4
                  ,iv_token_value4   IN VARCHAR2 DEFAULT NULL --�g�[�N���l4
                  ,iv_token_name5    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h5
                  ,iv_token_value5   IN VARCHAR2 DEFAULT NULL --�g�[�N���l5
                  ,iv_token_name6    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h6
                  ,iv_token_value6   IN VARCHAR2 DEFAULT NULL --�g�[�N���l6
                  ,iv_token_name7    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h7
                  ,iv_token_value7   IN VARCHAR2 DEFAULT NULL --�g�[�N���l7
                  ,iv_token_name8    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h8
                  ,iv_token_value8   IN VARCHAR2 DEFAULT NULL --�g�[�N���l8
                  ,iv_token_name9    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h9
                  ,iv_token_value9   IN VARCHAR2 DEFAULT NULL --�g�[�N���l9
                  ,iv_token_name10   IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h10
                  ,iv_token_value10  IN VARCHAR2 DEFAULT NULL --�g�[�N���l10
                 )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msg';
--
  -- *** ���[�J���ϐ� ***
    lv_start_search        NUMBER := 1;
    lv_start_pos           NUMBER;
    lv_end_pos             NUMBER;
    lv_token_end           NUMBER;
    lv_token_name          VARCHAR2(1000);
    lv_token_value         VARCHAR2(2000);
    lv_token_length        NUMBER;
    lv_token_value_length  NUMBER;
    ln_cnt                 NUMBER;
    lv_stringpplication    VARCHAR2(40);
--
  BEGIN
--
    -- �X�^�b�N�Ƀ��b�Z�[�W���Z�b�g
    FND_MESSAGE.SET_NAME(
                         iv_application
                        ,iv_name
                        );
    -- �X�^�b�N�Ƀg�[�N�����Z�b�g
    IF (iv_token_name1 IS NOT NULL)
    THEN
      --�J�E���g�ϐ�������
      ln_cnt := 0;
      <<TOKEN_SET>>
      LOOP
        ln_cnt := ln_cnt + 1;
        -- �g�[�N���̒l��2000�o�C�g�𒴂���ꍇ�A�؎̂�
        IF (ln_cnt = 1) THEN
          lv_token_name := iv_token_name1;
          lv_token_value := SUBSTRB(iv_token_value1,1,2000);
        ELSIF (ln_cnt = 2) THEN
          lv_token_name := iv_token_name2;
          lv_token_value := SUBSTRB(iv_token_value2,1,2000);
        ELSIF (ln_cnt = 3) THEN
          lv_token_name := iv_token_name3;
          lv_token_value := SUBSTRB(iv_token_value3,1,2000);
        ELSIF (ln_cnt = 4) THEN
          lv_token_name := iv_token_name4;
          lv_token_value := SUBSTRB(iv_token_value4,1,2000);
        ELSIF (ln_cnt = 5) THEN
          lv_token_name := iv_token_name5;
          lv_token_value := SUBSTRB(iv_token_value5,1,2000);
        ELSIF (ln_cnt = 6) THEN
          lv_token_name := iv_token_name6;
          lv_token_value := SUBSTRB(iv_token_value6,1,2000);
        ELSIF (ln_cnt = 7) THEN
          lv_token_name := iv_token_name7;
          lv_token_value := SUBSTRB(iv_token_value7,1,2000);
        ELSIF (ln_cnt = 8) THEN
          lv_token_name := iv_token_name8;
          lv_token_value := SUBSTRB(iv_token_value8,1,2000);
        ELSIF (ln_cnt = 9) THEN
          lv_token_name := iv_token_name9;
          lv_token_value := SUBSTRB(iv_token_value9,1,2000);
        ELSIF (ln_cnt = 10) THEN
          lv_token_name := iv_token_name10;
          lv_token_value := SUBSTRB(iv_token_value10,1,2000);
        END IF;
        EXIT WHEN (lv_token_name IS NULL)
               OR (ln_cnt > 10);
        IF (LENGTHB(lv_token_value) > 30) THEN
          FND_MESSAGE.SET_TOKEN(
                                lv_token_name
                               ,lv_token_value
                               ,FALSE
                               );
        ELSE
          FND_MESSAGE.SET_TOKEN(
                                lv_token_name
                               ,lv_token_value
                               ,TRUE
                               );
        END IF;
      END LOOP TOKEN_SET;
    END IF;
    -- �X�^�b�N�̓��e���擾
    RETURN FND_MESSAGE.GET(iv_name);
--
  EXCEPTION
--
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_msg;
  --
  --
  /**********************************************************************************
   * Function  Name   : char_delim_partition
   * Description      : �f���~�^���������֐�
   ***********************************************************************************/
--
  FUNCTION char_delim_partition(iv_char     IN VARCHAR2
                               ,iv_delim    IN VARCHAR2
                               ,in_part_num IN NUMBER
                               )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'char_delim_partition';
    cv_space      CONSTANT VARCHAR2(1) := ' ';
--
  BEGIN
--
    --NULL�`�F�b�N
    IF  ((iv_char      IS NULL)
      OR (iv_delim     IS NULL)
      OR (in_part_num  IS NULL)) THEN
      RETURN NULL;
    END IF;
--
   --�����_�`�F�b�N
   IF (INSTR(TO_CHAR(in_part_num),cv_period) > 0) THEN
     RETURN NULL;
   END IF;
--
    -- �ԋp�Ώ�INDEX�͈̓`�F�b�N
    IF   (in_part_num <= 0) 
      OR (LENGTH(REPLACE(iv_char,iv_delim,cv_space))
        - (LENGTH(REPLACE(iv_char,iv_delim,''))) + 2 <= in_part_num)
    THEN
      RETURN NULL;
    END IF;
--
  --�f���~�^�����`�F�b�N
  IF INSTR(iv_char,iv_delim,1,1) = 0 THEN
    IF in_part_num = 1 THEN
      RETURN iv_char;
    ELSE
      RETURN NULL;
    END IF;
  ELSIF in_part_num = 1 THEN
    RETURN SUBSTR(iv_char,1,INSTR(iv_char,iv_delim,1,in_part_num ) - 1);
  ELSIF INSTR(iv_char,iv_delim,1,in_part_num) = 0 THEN
    --���s�`�F�b�N
    IF INSTR(iv_char,CHR(10),LENGTH(iv_char),1) = LENGTH(iv_char) THEN
      RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim)
                           ,LENGTH(iv_char)
                           - INSTR(iv_char,iv_delim,1,in_part_num - 1) - LENGTH(iv_delim));
    ELSE
      RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim));
    END IF;
  ELSE
    RETURN SUBSTR(iv_char,INSTR(iv_char,iv_delim,1,in_part_num - 1) + LENGTH(iv_delim)
                         ,INSTR(iv_char,iv_delim ,1,in_part_num) 
                         - INSTR(iv_char,iv_delim ,1,in_part_num - 1) - LENGTH(iv_delim));
  END IF;
--
  EXCEPTION
--
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
--
  END char_delim_partition;
--
  /**********************************************************************************
   * Procedure Name   : chk_single_byte
   * Description      : ���p�`�F�b�N
   **********************************************************************************/
  --
  FUNCTION chk_single_byte(
    iv_chk_char IN VARCHAR2             --�`�F�b�N�Ώە�����
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_single_byte'; -- �v���O������
--
  BEGIN
    --NULL�`�F�b�N
    IF (iv_chk_char IS NULL) THEN
      RETURN NULL;
    --���p�`�F�b�N
    ELSIF (LENGTH(iv_chk_char) <> LENGTHB(iv_chk_char)) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
      RETURN FALSE;
  END chk_single_byte;
--
--
END XXCCP_COMMON_PKG;
/
