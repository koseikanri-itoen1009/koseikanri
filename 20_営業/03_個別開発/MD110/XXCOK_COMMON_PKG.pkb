CREATE OR REPLACE PACKAGE BODY xxcok_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcok_common_pkg(body)
 * Description      : �ʊJ���̈�E���ʊ֐�
 * MD.070           : MD070_IPO_COK_���ʊ֐�
 * Version          : 1.7
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  get_acctg_calendar_p         ��v�J�����_�擾
 *  get_next_year_p              ����v�N�x�擾
 *  get_set_of_books_info_p      ��v������擾
 *  get_close_date_p             ���߁E�x�����擾
 *  get_emp_code_f               �]�ƈ��R�[�h�擾
 *  check_acctg_period_f         ��v���ԃ`�F�b�N
 *  get_operating_day_f          �ғ����擾
 *  get_sales_staff_code_f       �S���c�ƈ��R�[�h�擾
 *  get_wholesale_req_est_p      �≮�������Ϗƍ�
 *  get_companies_code_f         ��ƃR�[�h�擾
 *  get_department_code_f        ��������R�[�h�擾
 *  get_batch_name_f             �o�b�`���擾
 *  get_slip_number_f            �`�[�ԍ��擾
 *  check_year_migration_f       �N���ڍs���m��`�F�b�N
 *  get_code_combination_id_f    CCID�擾
 *  check_code_combination_id_f  CCID�`�F�b�N
 *  put_message_f                ���b�Z�[�W�o��
 *  get_base_code_f              �������_�R�[�h�擾
 *  split_csv_data_p             CSV�����񕪊�
 *  get_wholesale_req_est_type_f �≮���������Ϗ��ˍ��X�e�[�^�X�擾
 *  get_bill_to_cust_code_f      ������ڋq�R�[�h�擾
 *  get_uom_conversion_qty_f     ��P�ʊ��Z���擾
 *  get_directory_path_f         �f�B���N�g���p�X�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   T.OSADA          �V�K�쐬
 *  2009/02/06    1.1   K.YAMAGUCHI      [��QCOK_022] �f�B���N�g���p�X�擾�ǉ�
 *  2009/02/12    1.2   K.IWABUCHI       [��QCOK_029] �≮���������Ϗƍ� �̔��萔���Z�o���@�C��
 *  2009/02/16    1.3   K.IWABUCHI       [��QCOK_034] �≮���������Ϗƍ� �̔����^���Z�o�����ǉ�
 *  2009/02/18    1.4   K.IWABUCHI       [��QCOK_043] �≮���������Ϗƍ� ���Ϗ��擾SQL�\�[�g�C��
 *  2009/02/24    1.5   K.IWABUCHI       [��QCOK_053] ���߁E�x�����擾 ���t�`�F�b�N�ǉ�
 *  2009/02/26    1.6   K.IWABUCHI       [��QCOK_057] SYSDATE���Ɩ����t�ɏC��
 *  2009/03/13    1.7   M.HIRUTA         [��QT1_0020] ��P�ʊ��Z���擾 �敪�����Z�Ή�
 *
 *****************************************************************************************/
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --�p�b�P�[�W��
  cv_pkg_name      CONSTANT VARCHAR2(30) := 'xxcok_common_pkg';
  --�Z�p���[�^
  cv_sepa_period   CONSTANT VARCHAR2(1)  := '.';  -- �s���I�h
  cv_sepa_colon    CONSTANT VARCHAR2(1)  := ':';  -- �R����
--
  /**********************************************************************************
   * Procedure Name   : get_acctg_calendar_p
   * Description      : ��v�J�����_�擾
   ***********************************************************************************/
  PROCEDURE get_acctg_calendar_p(
    ov_errbuf                 OUT VARCHAR2             -- �G���[�o�b�t�@
  , ov_retcode                OUT VARCHAR2             -- ���^�[���R�[�h
  , ov_errmsg                 OUT VARCHAR2             -- �G���[���b�Z�[�W
  , in_set_of_books_id        IN  NUMBER               -- ��v����ID
  , iv_application_short_name IN  VARCHAR2             -- �A�v���P�[�V�����Z�k��
  , id_object_date            IN  DATE                 -- �Ώۓ�
  , iv_adjustment_period_flag IN  VARCHAR2 DEFAULT 'N' -- �����t���O
  , on_period_year            OUT NUMBER               -- ��v�N�x
  , ov_period_name            OUT VARCHAR2             -- ��v���Ԗ�
  , ov_closing_status         OUT VARCHAR2             -- �X�e�[�^�X
  )
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_acctg_calendar_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_retcode        VARCHAR(1);                             -- ���^�[���R�[�h�̕ϐ�
    lt_period_year    gl_period_statuses.period_year%TYPE;    -- ��v�N�x�̕ϐ�
    lt_period_name    gl_period_statuses.period_name%TYPE;    -- ��v���Ԗ��̕ϐ�
    lt_closing_status gl_period_statuses.closing_status%TYPE; -- �X�e�[�^�X�̕ϐ�
--
  BEGIN
    lv_retcode := gv_status_normal;
    --=======================================================================
    --��v�N�x�A��v���Ԗ��A�X�e�[�^�X�̎擾
    --=======================================================================
    SELECT  gps.period_year            AS period_year
          , gps.period_name            AS period_name
          , gps.closing_status         AS closing_status
    INTO    lt_period_year
          , lt_period_name
          , lt_closing_status
    FROM    gl_period_statuses         gps
          , fnd_application            fa
    WHERE   gps.application_id         = fa.application_id
    AND     gps.adjustment_period_flag = iv_adjustment_period_flag
    AND     gps.set_of_books_id        = in_set_of_books_id
    AND     fa.application_short_name  = iv_application_short_name
    AND     gps.start_date            <= id_object_date
    AND     gps.end_date              >= id_object_date;
    --=======================================
    -- �o�̓p�����[�^�Z�b�g
    --=======================================
    ov_errbuf         := NULL;
    ov_retcode        := gv_status_normal;
    ov_errmsg         := NULL;
    on_period_year    := lt_period_year;    -- �ϐ����p�����[�^�ɑ��(��v�N�x)
    ov_period_name    := lt_period_name;    -- �ϐ����p�����[�^�ɑ��(��v���Ԗ�)
    ov_closing_status := lt_closing_status; -- �ϐ����p�����[�^�ɑ��(�X�e�[�^�X)
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_acctg_calendar_p;
--
  /************************************************************************
   * Procedure Name  : get_next_year_p
   * Description     : ����v�N�x�擾
   ************************************************************************/
  PROCEDURE get_next_year_p(
    ov_errbuf           OUT VARCHAR2                              -- �G���[�E�o�b�t�@
  , ov_retcode          OUT VARCHAR2                              -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2                              -- �G���[�E���b�Z�[�W
  , in_set_of_books_id  IN  gl_sets_of_books.set_of_books_id%TYPE -- ��v����ID
  , in_period_year      IN  gl_periods.period_year%TYPE           -- ��v�N�x
  , on_next_period_year OUT gl_periods.period_year%TYPE           -- ����v�N�x
  , od_next_start_date  OUT gl_periods.start_date%TYPE            -- ����v�N�x�����
  )
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_next_year_p'; -- �v���O������
    cn_year     CONSTANT NUMBER       := 1;                 -- 1�N
    cv_no_flag  CONSTANT VARCHAR2(1)  := 'N';               -- �����t���O'N'
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_retcode          VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lt_next_period_year gl_periods.period_year%TYPE; -- ����v�N�x
    lt_next_start_date  gl_periods.start_date%TYPE;  -- ����v�N�x�����
--
  BEGIN
    lv_retcode := gv_status_normal;
    --=====================================================================
    -- ����v�N�x�A����v�N�x������̎擾
    --=====================================================================
    SELECT gp.period_year            AS period_year              -- ��v�N�x
         , MIN( gp.start_date )      AS start_date               -- ��v�N�x�����
    INTO   lt_next_period_year                                   -- ����v�N�x
         , lt_next_start_date                                    -- ����v�N�x�����
    FROM   gl_periods                gp                          -- ��v�J�����_�e�[�u��
         , gl_sets_of_books          gsob                        -- ��v����}�X�^
    WHERE  gp.period_set_name        = gsob.period_set_name
    AND    gsob.set_of_books_id      = in_set_of_books_id
    AND    gp.period_year            = in_period_year + cn_year
    AND    gp.adjustment_period_flag = cv_no_flag
    GROUP BY gp.period_year;
--
    ov_retcode          := lv_retcode;
    ov_errbuf           := NULL;
    ov_errmsg           := NULL;
    on_next_period_year := lt_next_period_year;
    od_next_start_date  := lt_next_start_date;
--
  EXCEPTION
    -- OTHERS��O�n���h��
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_next_year_p;
--
  /**********************************************************************************
   * Procedure Name   : get_set_of_books_info_p
   * Description      : ��v������擾
   ***********************************************************************************/
  PROCEDURE get_set_of_books_info_p(
    ov_errbuf            OUT VARCHAR2 -- �G���[�E�o�b�t�@�i���O�j
  , ov_retcode           OUT VARCHAR2 -- ���^�[���R�[�h
  , ov_errmsg            OUT VARCHAR2 -- �G���[�E���b�Z�[�W�i���[�U�[�j
  , on_set_of_books_id   OUT NUMBER   -- ��v����ID
  , ov_set_of_books_name OUT VARCHAR2 -- ��v���떼
  , on_chart_acct_id     OUT NUMBER   -- ����̌nID
  , ov_period_set_name   OUT VARCHAR2 -- �J�����_��
  , on_aff_segment_cnt   OUT NUMBER   -- AFF�Z�O�����g��`��
  , ov_currency_code     OUT VARCHAR2 -- �@�\�ʉ݃R�[�h
  )
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name         CONSTANT VARCHAR2(30)  := 'get_set_of_books_info_p'; -- �v���O������
    cv_profile_name     CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID';        -- �v���t�@�C���E�I�v�V������
    cv_appli_short_name CONSTANT VARCHAR2(10)  := 'SQLGL';                   -- �A�v���P�[�V�����Z�k��
    cv_id_flex_code     CONSTANT VARCHAR2(5)   := 'GL#';                     -- �t���b�N�X�t�B�[���h�R�[�h
    cv_iv_token_name1   CONSTANT VARCHAR2(7)   := 'PROFILE';                 -- �g�[�N���R�[�h1
    cv_prof_get_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOK1-00003';        -- �v���t�@�C���擾�G���[MSGID
    cv_xxcok            CONSTANT VARCHAR2(10)  := 'XXCOK';                   -- �A�v���P�[�V�����Z�k��
    -- ==============================
    --  ���[�J���ϐ�
    -- ==============================
    lv_set_of_bks_id VARCHAR2(5);    -- ��v����ID
    lv_out_msg       VARCHAR2(2000); -- ���b�Z�[�W�i�[�p�ϐ�
    -- ==============================
    -- ���[�J����O
    -- ==============================
    -- �v���t�@�C���E�I�v�V�����l���擾
    nodata_profile_expt EXCEPTION;
--
  BEGIN
    ov_retcode := gv_status_normal;
    -- ====================================================
    -- �v���t�@�C���E�I�v�V�����l�̎擾
    -- ====================================================
    lv_set_of_bks_id := FND_PROFILE.VALUE( cv_profile_name );
--
    IF( lv_set_of_bks_id IS NULL ) THEN
      RAISE nodata_profile_expt;
    END IF;
    -- ====================================================
    -- ��v������̎擾
    -- ====================================================
    SELECT gsob.set_of_books_id      AS set_of_books_id
         , gsob.name                 AS set_of_books_name
         , gsob.chart_of_accounts_id AS chart_of_accounts_id
         , gsob.period_set_name      AS period_set_name
         , gsob.currency_code        AS currency_code
    INTO   on_set_of_books_id
         , ov_set_of_books_name
         , on_chart_acct_id
         , ov_period_set_name
         , ov_currency_code
    FROM   gl_sets_of_books          gsob
    WHERE  gsob.set_of_books_id      = TO_NUMBER( lv_set_of_bks_id );
    -- ====================================================
    -- AFF�Z�O�����g��`���̎擾
    -- ====================================================
    SELECT COUNT( 'X' )              AS aff_segment_cnt
    INTO   on_aff_segment_cnt
    FROM   fnd_id_flex_segments      fids
         , fnd_application           fa
    WHERE  fids.id_flex_num          = on_chart_acct_id
    AND    fids.id_flex_code         = cv_id_flex_code
    AND    fa.application_short_name = cv_appli_short_name
    AND    fids.application_id       = fa.application_id;
--
  EXCEPTION
    -- �v���t�@�C���E�I�v�V�����l���擾�G���[
    WHEN nodata_profile_expt THEN
      -- �o�̓p�����[�^�ϐ�������
      lv_out_msg := NULL;                                     -- ���b�Z�[�W
      --���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok             -- �A�v���P�[�V�����Z�k��
                    , iv_name         => cv_prof_get_err_msg  -- ���b�Z�[�W�R�[�h
                    , iv_token_name1  => cv_iv_token_name1    -- �g�[�N���R�[�h1
                    , iv_token_value1 => cv_profile_name      -- �g�[�N���l1
                    );
      ov_errbuf  := lv_out_msg;
      ov_retcode := gv_status_error;
      ov_errmsg  := lv_out_msg;
    -- OTHERS�G���[
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_set_of_books_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_close_date_p
   * Description      : ���߁E�x�����擾
   ***********************************************************************************/
  PROCEDURE get_close_date_p(
    ov_errbuf     OUT VARCHAR2          -- ���O�ɏo�͂���G���[�E���b�Z�[�W
  , ov_retcode    OUT VARCHAR2          -- ���^�[���R�[�h
  , ov_errmsg     OUT VARCHAR2          -- ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
  , id_proc_date  IN  DATE DEFAULT NULL -- ������(�Ώۓ�)
  , iv_pay_cond   IN  VARCHAR2          -- �x������(IN)
  , od_close_date OUT DATE              -- ���ߓ�(OUT)
  , od_pay_date   OUT DATE              -- �x����(OUT)
  )
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_close_date_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    ld_proc_date      DATE;         -- �Ώۓ�
    lv_close_day      VARCHAR2(10); -- ���ߓ�
    lv_pay_day        VARCHAR2(10); -- �x����
    lv_site           VARCHAR2(10); -- �T�C�g
    ld_close_date     DATE;         -- ���ߓ��̌���
    ld_pay_date       DATE;         -- �x�����̌���
    lv_chk_close_date VARCHAR2(2);  -- ���ߓ��̌�����(���t�`�F�b�N�p)
    lv_chk_pay_date   VARCHAR2(2);  -- �x�����̌�����(���t�`�F�b�N�p)
    lv_close_year     VARCHAR2(30); -- ���ߓ��i�N���j
    lv_pay_year       VARCHAR2(30); -- �x�����i�N���j
--
  BEGIN
    ov_retcode := gv_status_normal; -- ���^�[���R�[�h������������B
--
    IF( id_proc_date IS NULL ) THEN
      --IN�p�����[�^������=NULL�̏ꍇ
      --�Ώۓ��ɋƖ����t��ݒ�
      ld_proc_date := xxccp_common_pkg2.get_process_date;
    ELSE
      --IN�p�����[�^������<>NULL�̏ꍇ
      --�Ώۓ���IN�p�����[�^�̏�������ݒ�
      ld_proc_date := id_proc_date; -- IN�p�����[�^�̏�������ݒ肷��B
    END IF;
    -- =========================================
    -- �x������XX_YY_ZZ ���󂯎��
    -- XX�F���ߓ�(���ɂ�)
    -- YY�F�x����(���ɂ�)
    -- ZZ�F�T�C�g(�x��������������Ȃ̂����w��)
    -- =========================================
    -- ===============================
    -- ���ߓ�(���ɂ�)�𒊏o����B
    -- ===============================
    lv_close_day := SUBSTR( iv_pay_cond, 1, 2 );
    -- ===============================
    -- �x����(���ɂ�)�𒊏o����B
    -- ===============================
    lv_pay_day   := SUBSTR( iv_pay_cond, 4, 2 );
    -- ===============================
    -- �T�C�g�𒊏o����B
    -- ===============================
    lv_site      := SUBSTR( iv_pay_cond, 7, 2 );
    -- ====================================================================
    -- �x��������00_00_00�������ꍇ�A�����������������t��߂�l�ɐݒ肷��B
    -- ====================================================================
    IF(     ( lv_close_day = '00' )
         AND( lv_pay_day   = '00' )
         AND( lv_site      = '00' )
    ) THEN
      od_close_date  := ld_proc_date;
      od_pay_date    := ld_proc_date;
    -- ====================================================
    -- �x��������00_00_00�łȂ������ꍇ�A�ȉ��̏������s���B
    -- ���ߓ��Ǝx�����̌����̓��t�����߂�B
    -- ====================================================
    ELSE
      ld_close_date := LAST_DAY( ld_proc_date );
      ld_pay_date   := LAST_DAY( ADD_MONTHS( ld_proc_date, TO_NUMBER( lv_site ) ) );
      -- ====================================================
      -- �x������.���ߓ���30�������ꍇ�A���������ƂȂ�B
      -- ====================================================
      IF( lv_close_day = '30' ) THEN
        lv_close_day := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 9, 2 );
      END IF;
      -- ====================================================
      -- �x������.�x������30�������ꍇ�A���������ƂȂ�B
      -- ====================================================
      IF (lv_pay_day = '30') THEN
        lv_pay_day  := SUBSTR (TO_CHAR( ld_pay_date, 'YYYY/MM/DD' ), 9, 2 );
      END IF;
      -- ==================================================================
      -- �x������.���ߓ������ߓ���������̏ꍇ�A���ߓ���������ߓ��Ƃ���B
      -- ==================================================================
      -- ���ߓ������擾
      lv_chk_close_date := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 9, 2 );
      IF ( TO_NUMBER( lv_close_day ) > TO_NUMBER( lv_chk_close_date ) ) THEN
        lv_close_day := lv_chk_close_date;
      END IF;
      -- ==================================================================
      -- �x������.�x�������x������������̏ꍇ�A�x�����������x�����Ƃ���B
      -- ==================================================================
      -- �x���������擾
      lv_chk_pay_date   := SUBSTR( TO_CHAR( ld_pay_date, 'YYYY/MM/DD' ), 9, 2 );
      IF ( TO_NUMBER( lv_pay_day )   > TO_NUMBER( lv_chk_pay_date ) ) THEN
        lv_pay_day   := lv_chk_pay_date;
      END IF;
      -- ===========================================
      -- ���ߓ��Ǝx�����̔N��(YYYY/MM/)�𒊏o����B
      -- ===========================================
      lv_close_year := SUBSTR( TO_CHAR( ld_close_date, 'YYYY/MM/DD' ), 1, 8 );
      lv_pay_year   := SUBSTR( TO_CHAR( ld_pay_date,   'YYYY/MM/DD' ), 1, 8 );
      -- ===============================
      -- ���ߓ��F�N�� + ���ߓ�(���ɂ�)
      -- ===============================
      od_close_date := TO_DATE( ( lv_close_year || lv_close_day ), 'YYYY/MM/DD' );
      -- ========================================================
      -- �x�����F�T�C�g�i�x�����j�𔽉f�����N�� + �x����(���ɂ�)
      -- ========================================================
      od_pay_date   := TO_DATE( ( lv_pay_year || lv_pay_day ), 'YYYY/MM/DD' );
    END IF;
    --=======================================
    -- �o�̓p�����[�^�Z�b�g
    --=======================================
    ov_errbuf    := NULL;
    ov_errmsg    := NULL;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode := gv_status_error;
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_close_date_p;
--
  /******************************************************************************
   *FUNCTION NAME : get_emp_code_f
   *Desctiption   : �]�ƈ��R�[�h�擾
   ******************************************************************************/
  FUNCTION get_emp_code_f(
    in_user_id IN NUMBER --1.���[�UID
  )
  RETURN VARCHAR2        --�]�ƈ��R�[�h
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_emp_code_f'; --�v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    ld_process_date DATE;                      --�Ɩ����t
    lv_emp_code     VARCHAR2(30) DEFAULT NULL; --�]�ƈ��R�[�h
--
  BEGIN
    -- ==========================================
    -- �Ɩ����t�擾
    -- ==========================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
    -- ===========================
    -- �]�ƈ��R�[�h���擾
    -- ===========================
    SELECT papf.employee_number      AS emp_num --�]�ƈ��R�[�h
    INTO   lv_emp_code
    FROM   fnd_user                  fu
         , per_all_people_f          papf
    WHERE  in_user_id                = fu.user_id
    AND    fu.employee_id            = papf.person_id
    AND    ld_process_date BETWEEN fu.start_date
                               AND NVL( fu.end_date, ld_process_date )
    AND    ld_process_date BETWEEN papf.effective_start_date
                               AND NVL( papf.effective_end_date, ld_process_date );
--
    RETURN lv_emp_code; --���[�UID�ɕR�Â��]�ƈ��R�[�h
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_emp_code_f;
--
  /************************************************************************
  * Function Name   : check_acctg_period_f
  * Description     : ��v���ԃ`�F�b�N
  ************************************************************************/
  FUNCTION check_acctg_period_f(
    in_set_of_books_id        IN NUMBER   -- ��v����ID
  , id_proc_date              IN DATE     -- ������(�Ώۓ�)
  , iv_application_short_name IN VARCHAR2 -- �A�v���P�[�V�����Z�k��
  )
  RETURN BOOLEAN                          -- BOOLEAN�^ TRUE/FALSE
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'check_acctg_period_f'; -- �v���O������
    cv_flag     CONSTANT VARCHAR2(1)  := 'N';                    -- �����t���O�̑ΏۊO�̕ϐ�
    cv_open     CONSTANT VARCHAR2(1)  := 'O';                    -- �X�e�[�^�X���I�[�v���̕ϐ�
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lt_closing_status gl_period_statuses.closing_status%TYPE; -- �X�e�[�^�X�̕ϐ�
--
  BEGIN
    --=========================================================================
    --�������ɑΉ������v���Ԃ��I�[�v�����Ă��邩���`�F�b�N
    --=========================================================================
    SELECT gps.closing_status                     closing_status
    INTO   lt_closing_status
    FROM   gl_period_statuses                     gps
         , fnd_application                        fa
    WHERE  gps.application_id                   = fa.application_id                     -- �A�v���P�[�V����ID����v
    AND    fa.application_short_name            = iv_application_short_name             -- �A�v���P�[�V�����Z�k��
    AND    gps.set_of_books_id                  = in_set_of_books_id                    -- ��v����ID����v
    AND    gps.adjustment_period_flag           = cv_flag                               -- �����t���O��'N'
    AND    gps.start_date                      <= id_proc_date                          -- �J�n�����珈����
    AND    gps.end_date                        >= id_proc_date;                         -- ����������I����
--
    IF( lt_closing_status = cv_open ) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_acctg_period_f;
--
  /************************************************************************
   * Function Name   : get_operating_day_f
   * Description     : �ғ����擾
   ************************************************************************/
  FUNCTION get_operating_day_f(
    id_proc_date     IN DATE             -- ������
  , in_days          IN NUMBER           -- ����
  , in_proc_type     IN NUMBER           -- �����敪
  , in_calendar_type IN NUMBER DEFAULT 0 -- �J�����_�[�敪
  )
  RETURN DATE
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_xxcok_code    CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES'; -- COK�p�R�[�h
    cv_sys_cal_code  CONSTANT VARCHAR2(30) := 'SYSTEM_CAL';            -- �V�X�e���J�����_�[�R�[�h
    cn_bef           CONSTANT NUMBER       := 1;                       -- �����敪�F�O
    cn_aft           CONSTANT NUMBER       := 2;                       -- �����敪�F��
    cn_zero          CONSTANT NUMBER       := 0;                       -- IN�p������ �`�F�b�N�l=0
    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_operating_day_f';   -- �v���O������
    cn_cal_type_zero CONSTANT NUMBER       := 0;                       -- �J�����_�[�敪=0(�g�D�p�����[�^)
    cn_cal_type_one  CONSTANT NUMBER       := 1;                       -- �J�����_�[�敪=1(�V�X�e���J�����_)
    -- =======================================================
    -- ���[�J���ϐ�
    -- ===============================================
    lt_operating_day  bom_calendar_dates.calendar_date%TYPE; -- �c�Ɠ��i�߂�l�j
    lt_calendar_code  mtl_parameters.calendar_code%TYPE;     --�J�����_�[�R�[�h
    lt_calendar_date  bom_calendar_dates.calendar_date%TYPE; --���������p�̉c�Ɠ�
    lt_seq_num        bom_calendar_dates.seq_num%TYPE;       --�V�[�P���X�ԍ�
    lt_next_seq_num   bom_calendar_dates.next_seq_num%TYPE;  --�l�N�X�g�V�[�P���X�ԍ�
    lt_prior_seq_num  bom_calendar_dates.prior_seq_num%TYPE; --�O�̃V�[�P���X�ԍ�
    lt_cndtn_seq_num  bom_calendar_dates.seq_num%TYPE;       --���������ݒ�p�V�[�P���X�ԍ�
--
    BEGIN
    -- ==========================================
    -- �v���t�@�C���l���菈��
    -- ==========================================
    IF( in_calendar_type = cn_cal_type_zero ) THEN
      --IN�p�����[�^ �J�����_�[�敪=0(�g�D�p�����[�^)�̏ꍇ
      -- ==========================================
      -- �ғ����J�����_�[�����p�J�����_�[�R�[�h�擾
      -- ==========================================
      SELECT mp.calendar_code     AS calendar_code        -- �J�����_�[�R�[�h
      INTO   lt_calendar_code
      FROM   mtl_parameters       mp
      WHERE  mp.organization_code = FND_PROFILE.VALUE( cv_xxcok_code );
    ELSE
      IF( in_calendar_type = cn_cal_type_one ) THEN
        --IN�p�����[�^ �J�����_�[�敪<>0(�g�D�p�����[�^)�ȊO�̏ꍇ
        --�J�����_�[�R�[�h�ɃV�X�e���J�����_�[�R�[�h��ݒ�
        lt_calendar_code := cv_sys_cal_code;
      END IF;
    END IF;
    -- ==========================================
    -- �ғ����`�F�b�N�p�f�[�^�擾
    --  *CALENDAR_DATE, SEQ_NUM, NEXT_SEQ_NUM,
    --  *PRIOR_SEQ_NUM �擾
    -- ==========================================
    SELECT bcd.calendar_date  AS calendar_date -- �ғ���
         , bcd.seq_num        AS seq_num       -- �V�[�P���X�ԍ�
         , bcd.next_seq_num   AS next_seq_num  -- ���V�[�P���X�ԍ�
         , bcd.prior_seq_num  AS prior_seq_num -- �O�V�[�P���X�ԍ�
    INTO   lt_calendar_date
         , lt_seq_num
         , lt_next_seq_num
         , lt_prior_seq_num
    FROM   bom_calendar_dates bcd           -- �e�[�u���u�ғ����J�����_�v
    WHERE  bcd.calendar_date  = id_proc_date
    AND    bcd.calendar_code  = lt_calendar_code;
    -- ==========================================
    -- �ғ����`�F�b�N�ƌ��������̐ݒ�
    --  * SEQ_NUM��NULL�̏ꍇ �ғ���
    --  * SEQ_NUM=NULL�̏ꍇ  ��ғ���
    -- ==========================================
    -- SEQ_NUM=NULL�̏ꍇ  ��ғ���
    IF( lt_seq_num IS NULL ) THEN
      -- IN�p�����[�^ ����=0�̏ꍇ
      IF( in_days = cn_zero  ) THEN
        --�����敪  = �O�̏ꍇ
        IF( in_proc_type = cn_bef ) THEN
           --==========================================
           --IN�p�� ������ =��ғ��� ����
           --IN�p�������敪=�O       ����
           --IN�p������    =zero �̏ꍇ
           --=>IN�p�� ���������1���O�̉c�Ɠ����擾����
           --==========================================
           lt_cndtn_seq_num := lt_prior_seq_num;
        END IF;
        --�����敪  = ��̏ꍇ
        IF( in_proc_type = cn_aft ) THEN
           --==========================================
           --IN�p�� ������  =��ғ��� ����
           --IN�p�������敪 =��       ����
           --IN�p������     =zero �̏ꍇ
           --=>IN�p�� ���������1����̉c�Ɠ����擾����
           --==========================================
           lt_cndtn_seq_num := lt_next_seq_num;
        END IF;
      ELSE
        -- IN�p�����[�^ ����=0�ȊO�̏ꍇ
        IF( in_days > cn_zero ) THEN
          --==========================================
          --IN�p�� ������  =��ғ��� ����
          --IN�p������=zero�ȏ�̏ꍇ
          --=>IN�p�� ���������IN�p�� ��������̉c�Ɠ����擾����
          --==========================================
          lt_cndtn_seq_num := lt_prior_seq_num + in_days;
        ELSE
          --==========================================
          --IN�p�� ������  =��ғ��� ����
          --IN�p������=zero�ȉ��̏ꍇ
          --=>IN�p�� ���������IN�p�� �������O�̉c�Ɠ����擾����
          --==========================================
          lt_cndtn_seq_num := lt_next_seq_num + in_days;
        END IF;
      END IF;
    -- SEQ_NUM��NULL�̏ꍇ �ғ���
    ELSE
      -- IN�p�����[�^ ����=0 �̏ꍇ
      IF( in_days = cn_zero ) THEN
        --==========================================
        --IN�p�� ������  =�ғ��� ����
        --IN�p�� ����    =zero   �̏ꍇ
        --=>IN�p��������(=�c�Ɠ�)�������擾����
        --==========================================
        lt_cndtn_seq_num := lt_seq_num;
      ELSE
        --==========================================
        --IN�p�� ������  =�ғ��� ����
        --IN�p�� ����    =zero�ȏ�̏ꍇ
        --=>IN�p�� ����������IN�p�� ���������Z�����c�Ɠ����擾����
        --==========================================
        lt_cndtn_seq_num := lt_seq_num + in_days;
      END IF;
    END IF;
    -- ==========================================
    -- �u�c�Ɠ��v���擾����B
    -- ==========================================
    SELECT bcd.calendar_date  AS calendar_date    -- �c�Ɠ�
    INTO   lt_operating_day
    FROM   bom_calendar_dates bcd                 -- �e�[�u���u�ғ����J�����_�v
    WHERE  bcd.calendar_code  = lt_calendar_code  -- �J�����_�[�R�[�h
    AND    bcd.seq_num        = lt_cndtn_seq_num; -- �c�Ɠ��̃V�[�P���X�ԍ�
    -- ===============
    -- �߂�l�ɐݒ�
    -- ===============
    RETURN( lt_operating_day ); -- �c�Ɠ�
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_operating_day_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_sales_staff_code_f
   *Desctiption   : �S���c�ƈ��R�[�h�擾
   ******************************************************************************/
  FUNCTION get_sales_staff_code_f(
    iv_customer_code IN VARCHAR2 -- �ڋq�R�[�h
  , id_proc_date     IN DATE     -- ������
  )
  RETURN VARCHAR2                -- �S���c�ƈ��R�[�h
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_sales_staff_code_f'; -- �v���O������
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lt_sales_staff_code jtf_rs_resource_extns.source_number%TYPE DEFAULT NULL; -- �S���c�ƈ��R�[�h
--
  BEGIN
    -- =======================================================
    -- �S���c�ƈ��R�[�h�̎擾
    -- =======================================================
    SELECT jrre.source_number         AS sales_staff_code -- �S���c�ƈ��R�[�h
    INTO   lt_sales_staff_code
    FROM   hz_cust_accounts           hca                 -- �ڋq�}�X�^
         , hz_organization_profiles   hop                 -- �g�D�v���t�@�C��
         , ego_resource_agv           era                 -- ���\�[�X�r���[
         , jtf_rs_resource_extns      jrre                -- ���\�[�X
         , per_all_people_f           papf                -- �]�ƈ�
    WHERE  hca.account_number          = iv_customer_code -- �ڋq�R�[�h
    AND    hca.party_id                = hop.party_id
    AND    TRUNC( hop.effective_start_date )                          <= TRUNC( id_proc_date )
    AND    TRUNC( NVL( hop.effective_end_date, id_proc_date ) )       >= TRUNC( id_proc_date )
    AND    hop.organization_profile_id = era.organization_profile_id
    AND    TRUNC( NVL( era.resource_s_date, TRUNC( id_proc_date ) ) ) <= TRUNC( id_proc_date )
    AND    TRUNC( NVL( era.resource_e_date, TRUNC( id_proc_date ) ) ) >= TRUNC( id_proc_date )
    AND    jrre.source_number          = era.resource_no
    AND    papf.person_id              = jrre.source_id
    AND    TRUNC( NVL( papf.effective_start_date, id_proc_date ) )    <= TRUNC( id_proc_date )
    AND    TRUNC( NVL( papf.effective_end_date, id_proc_date ) )      >= TRUNC( id_proc_date );
    -- �擾�l��߂�
    RETURN lt_sales_staff_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- �Y�����郌�R�[�h�����݂��Ȃ������ꍇ��NULL��Ԃ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_sales_staff_code_f;
--
  /**********************************************************************************
   * Procedure Name   : get_wholesale_req_est_p
   * Description      : �≮�������Ϗƍ�
   ***********************************************************************************/
  PROCEDURE get_wholesale_req_est_p(
    ov_errbuf                      OUT VARCHAR2 -- �G���[�o�b�t�@
  , ov_retcode                     OUT VARCHAR2 -- ���^�[���R�[�h
  , ov_errmsg                      OUT VARCHAR2 -- �G���[���b�Z�[�W
  , iv_wholesale_code              IN  VARCHAR2 -- �≮�Ǘ��R�[�h
  , iv_sales_outlets_code          IN  VARCHAR2 -- �≮������R�[�h
  , iv_item_code                   IN  VARCHAR2 -- �i�ڃR�[�h
  , in_demand_unit_price           IN  NUMBER   -- �x���P��
  , iv_demand_unit_type            IN  VARCHAR2 -- �����P��
  , iv_selling_month               IN  VARCHAR2 -- ����Ώ۔N��
  , ov_estimated_no                OUT VARCHAR2 -- ���Ϗ�No.
  , on_quote_line_id               OUT NUMBER   -- ����ID
  , ov_emp_code                    OUT VARCHAR2 -- �S���҃R�[�h
  , on_market_amt                  OUT NUMBER   -- ���l
  , on_allowance_amt               OUT NUMBER   -- �l��(���߂�)
  , on_normal_store_deliver_amt    OUT NUMBER   -- �ʏ�X�[
  , on_once_store_deliver_amt      OUT NUMBER   -- ����X�[
  , on_net_selling_price           OUT NUMBER   -- NET���i
  , ov_estimated_type              OUT VARCHAR2 -- ���ϋ敪
  , on_backmargin_amt              OUT NUMBER   -- �̔��萔��
  , on_sales_support_amt           OUT NUMBER   -- �̔����^��
  )
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_wholesale_req_est_p'; -- �v���O������
    cv_quote_type_sale             CONSTANT VARCHAR2(1)  := '1';                       -- ���ώ�� 1:�̔���p
    cv_quote_type_wholesale        CONSTANT VARCHAR2(1)  := '2';                       -- ���ώ�� 2:�����≮��p
    cv_status_decision             CONSTANT VARCHAR2(1)  := '2';                       -- �X�e�[�^�X= 2:�m��
    cv_quote_div_usuall            CONSTANT VARCHAR2(1)  := '1';                       -- ���ϋ敪 1:�ʏ�
    cn_one                         CONSTANT NUMBER       := 1;                         -- ���l:1
    cv_zero                        CONSTANT VARCHAR2(1)  := '0';                       -- ������:0
    cv_organization_cd             CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';   -- COK�p_�g�D�R�[�h
    cv_unit_type_count             CONSTANT VARCHAR2(1)  := '1';                       -- �P���敪:1(�{��)
    cv_unit_type_cs                CONSTANT VARCHAR2(1)  := '2';                       -- �P���敪:2(C/S)
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    ln_count                       NUMBER ;    -- ����
    ln_price_check_on_flg          NUMBER DEFAULT 0; -- �ƍ����ʔ���t���O
    ln_sql_data_not_flg            NUMBER DEFAULT 0; -- 1���ڌ��ϋ敪����t���O
    -- =======================================================
    -- ���[�J��RECORD�^
    -- =======================================================
    --�≮��������1 ���R�[�h��`
    TYPE l_wholesale_req1_rtype    IS RECORD(
      lv_quote_number              xxcso_quote_headers.quote_number             %TYPE -- �����≮�p���σw�b�_�[.���Ϗ��ԍ�
    , lv_employee_number           xxcso_quote_headers.employee_number          %TYPE -- �����≮�p���σw�b�_�[.�S���҃R�[�h
    , lv_quote_div                 xxcso_quote_lines.quote_div                  %TYPE -- �̔���p���ϖ���.���ϋ敪
    , ln_usually_deliv_price       xxcso_quote_lines.usually_deliv_price        %TYPE -- �̔���p���ϖ���.�ʏ�X�[���i
    , ln_this_time_deliv_price     xxcso_quote_lines.this_time_deliv_price      %TYPE -- �̔���p���ϖ���.����X�[���i
    , ln_quote_line_id             xxcso_quote_lines.quote_line_id              %TYPE -- �����≮�p���ϖ���.���ϖ���ID
    , ln_quotation_price           xxcso_quote_lines.quotation_price            %TYPE -- �����≮�p���ϖ���.���l
    , ln_sales_discount_price      xxcso_quote_lines.sales_discount_price       %TYPE -- �����≮�p���ϖ���.����l��
    , ln_usuall_net_price          xxcso_quote_lines.usuall_net_price           %TYPE -- �����≮�p���ϖ���.�ʏ�NET���i
    , ln_this_time_net_price       xxcso_quote_lines.this_time_net_price        %TYPE -- �����≮�p���ϖ���.����NET���i
    );
    --�≮��������2 ���R�[�h��`
    TYPE l_wholesale_req2_rtype    IS RECORD(
      lv_quote_number              xxcso_quote_headers.quote_number             %TYPE -- �����≮�p���σw�b�_�[.���Ϗ��ԍ�
    , lv_employee_number           xxcso_quote_headers.employee_number          %TYPE -- �����≮�p���σw�b�_�[.�S���҃R�[�h
    , lv_quote_div                 xxcso_quote_lines.quote_div                  %TYPE -- �̔���p���ϖ���.���ϋ敪
    , ln_usually_deliv_price       xxcso_quote_lines.usually_deliv_price        %TYPE -- �̔���p���ϖ���.�ʏ�X�[���i
    , ln_this_time_deliv_price     xxcso_quote_lines.this_time_deliv_price      %TYPE -- �̔���p���ϖ���.����X�[���i
    , ln_quote_line_id             xxcso_quote_lines.quote_line_id              %TYPE -- �����≮�p���ϖ���.���ϖ���ID
    , ln_quotation_price           xxcso_quote_lines.quotation_price            %TYPE -- �����≮�p���ϖ���.���l
    , ln_sales_discount_price      xxcso_quote_lines.sales_discount_price       %TYPE -- �����≮�p���ϖ���.����l��
    , ln_usuall_net_price          xxcso_quote_lines.usuall_net_price           %TYPE -- �����≮�p���ϖ���.�ʏ�NET���i
    , ln_this_time_net_price       xxcso_quote_lines.this_time_net_price        %TYPE -- �����≮�p���ϖ���.����NET���i
    , lv_iim_b_case_in_num         ic_item_mst_b.attribute11                    %TYPE -- OPM�i�ڃ}�X�^.�P�[�X���萔�iDFF11)
    );
    -- =======================================================
    -- ���[�J��TABLE�^
    -- =======================================================
    --�≮��������1 ���R�[�h�̌����z�� ��`
    TYPE  l_wholesale_req1_ttype   IS TABLE OF l_wholesale_req1_rtype
      INDEX BY PLS_INTEGER;
    --�≮��������2 ���R�[�h�̌����z�� ��`
    TYPE  l_wholesale_req2_ttype   IS TABLE OF l_wholesale_req2_rtype
      INDEX BY PLS_INTEGER;
    -- =======================================================
    -- ���[�J��PL/SQL�\
    -- =======================================================
    --�≮��������1 �����z��
    l_wholesale_req1_tab           l_wholesale_req1_ttype;
    --�≮��������2 �����z��
    l_wholesale_req2_tab           l_wholesale_req2_ttype;
--
  BEGIN
    -- =======================================================
    -- IN�p�����[�^�i�ڃR�[�hNULL�`�F�b�N
    -- =======================================================
    IF( iv_item_code IS NULL ) THEN
      ln_price_check_on_flg := 0;  --�ƍ����ʔ���t���O  �I�t
    ELSE
      BEGIN
        -- =======================================================
        -- �@SQL
        -- =======================================================
        SELECT   -- �����≮�p���σw�b�_�[.���Ϗ��ԍ�
                 csoqh_wholesale.quote_number                  AS wholesale_quote_number
                 -- �����≮�p���σw�b�_�[.�S���҃R�[�h
               , csoqh_wholesale.employee_number               AS wholesale_employee_number
                 -- �̔���p���ϖ���.���ϋ敪
               , csoql_sale.quote_div                          AS sale_quote_div
                 -- �̔���p���ϖ���.�ʏ�X�[���i
               , NVL( csoql_sale.usually_deliv_price, 0 )      AS sale_usually_deliv_price
                 -- �̔���p���ϖ���.����X�[���i
               , NVL( csoql_sale.this_time_deliv_price, 0 )    AS sale_this_time_deliv_price
                 -- �����≮�p���ϖ���.���ϖ���ID
               , csoql_wholesale.quote_line_id                 AS wholesale_quote_line_id
                 -- �����≮�p���ϖ���.���l
               , NVL( csoql_wholesale.quotation_price, 0 )     AS wholesale_quotation_price
                 -- �����≮�p���ϖ���.����l��
               , NVL( csoql_wholesale.sales_discount_price, 0 )  AS wholesale_sales_discount_price
                 -- �����≮�p���ϖ���.�ʏ�NET���i
               , NVL( csoql_wholesale.usuall_net_price, 0 )    AS wholesale_usuall_net_price
                 -- �����≮�p���ϖ���.����NET���i
               , NVL( csoql_wholesale.this_time_net_price, 0 ) AS wholesale_this_time_net_price
        BULK COLLECT INTO l_wholesale_req1_tab  --�≮��������1 �����z��
        FROM     -- �̔���p���σw�b�_�[
                 xxcso_quote_headers                           csoqh_sale
                 -- �̔���p���ϖ���
               , xxcso_quote_lines                             csoql_sale
                 -- �����≮�p���σw�b�_�[
               , xxcso_quote_headers                           csoqh_wholesale
                 -- �����≮�p���ϖ���
               , xxcso_quote_lines                             csoql_wholesale
                 -- Disc�i�ڃ}�X�^
               , mtl_system_items_b                            msi_b
                 -- �g�D�p�����[�^
               , mtl_parameters                                mp
        WHERE    -- �������o����
                 -- �̔���p���σw�b�_�[�D���σw�b�_�[ID     = �̔���p���ϖ��ׁD���σw�b�_�[ID
                 csoqh_sale.quote_header_id                  = csoql_sale.quote_header_id
                 -- �����≮�p���σw�b�_�[�D���σw�b�_�[ID   = �����≮�p���ϖ��ׁD���σw�b�_�[ID
        AND      csoqh_wholesale.quote_header_id             = csoql_wholesale.quote_header_id
                 -- �̔���p���σw�b�_�[�D���Ϗ��ԍ�         =  �����≮�p���σw�b�_�[�D�Q�ƌ��ϔԍ�
        AND      csoqh_sale.quote_number                     = csoqh_wholesale.reference_quote_number
                 -- �̔���p���ϖ��ׁD���ϖ���ID             = �����≮�p���ρD�Q�Ɨp���ϖ��ׂh�c
        AND      csoql_sale.quote_line_id                    = csoql_wholesale.reference_quote_line_id
                 -- Disc�i�ڃ}�X�^�D�i��ID                   = �̔���p���ϖ��ׁD�i��ID
        AND      msi_b.inventory_item_id                     = csoql_sale.inventory_item_id
                 -- �̔���p���σw�b�_�[�D���ώ��           = '1'(�̔���)
        AND      csoqh_sale.quote_type                       = cv_quote_type_sale
                 -- �̔���p���σw�b�_�[�D�X�e�[�^�X         = '2'(�m��)
        AND      csoqh_sale.status                           = cv_status_decision
                 -- �����≮�p���σw�b�_�[�D���ώ��         = '2'(�����≮)
        AND      csoqh_wholesale.quote_type                  = cv_quote_type_wholesale
                 -- �����≮�p���σw�b�_�[�D�X�e�[�^�X       = '2'(�m��)
        AND      csoqh_wholesale.status                      = cv_status_decision
                 -- Disc�i�ڃ}�X�^�D�g�DID                   = �g�D�p�����[�^�D�g�DID
        AND      msi_b.organization_id                       = mp.organization_id
                 -- �̔���p���σw�b�_�[�D�ڋq�R�[�h         = ���̓p�����[�^�D�≮������R�[�h
        AND      csoqh_sale.account_number                   = iv_sales_outlets_code
                 -- Disc�i�ڃ}�X�^�D�i�ڃR�[�h               = ���̓p�����[�^�D�i�ڃR�[�h
        AND      msi_b.segment1                              = iv_item_code
                 -- �̔���p���ϖ��ׁD���ԁi�J�n�j           <= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_sale.quote_start_date                 <= TO_DATE( iv_selling_month , 'YYYY/MM' )
                 -- �̔���p���ϖ��ׁD���ԁi�I���j           >= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_sale.quote_end_date                   >= TO_DATE( iv_selling_month , 'YYYY/MM' )
                 -- �����≮�p���σw�b�_�[�D�ڋq�R�[�h       = ���̓p�����[�^�D�����≮�R�[�h
        AND      csoqh_wholesale.account_number              = iv_wholesale_code
                 -- �����≮�p���σw�b�_�[�D�P���敪         = ���̓p�����[�^�D�����P��
        AND      csoqh_wholesale.unit_type                   = iv_demand_unit_type
                 -- �����≮�p���ϖ��ׁD���ԁi�J�n�j         <= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_wholesale.quote_start_date            <= TO_DATE( iv_selling_month , 'YYYY/MM' )
                 -- �����≮�p���ϖ��ׁD���ԁi�I���j         >= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_wholesale.quote_end_date              >= TO_DATE( iv_selling_month , 'YYYY/MM' )
                 -- �g�D�p�����[�^�D�g�D�R�[�h               = FND_PROFILE�DVALUE('XXCOK1_ORG_CODE_SALES')
        AND      mp.organization_code                        = FND_PROFILE.VALUE( cv_organization_cd )
        ORDER BY -- �̔���p���ϖ���.���ϋ敪                ����
                 csoql_sale.quote_div                        ASC
                 -- �̔���p���ϖ���.����X�[���i            �~��
               , csoql_sale.this_time_deliv_price            DESC NULLS LAST
                 -- �����≮�p���ϖ���.����NET���i           �~��
               , csoql_wholesale.this_time_net_price         DESC NULLS LAST;
      END;
      -- =======================================================
      -- �≮�������Ϗƍ�1
      -- =======================================================
      << loop_1 >>
      FOR ln_count IN NVL( l_wholesale_req1_tab.FIRST, 0 ) ..NVL( l_wholesale_req1_tab.LAST, 0 ) LOOP
        BEGIN
          -- =======================================================
          -- �A�P���ƍ�
          -- =======================================================
          -- =====================================
          --�@.FETCH�������R�[�h��
          --1����.���ϋ敪<>�u1(�ʏ�)�v�̏ꍇ
          --1���ڂ̌��ϋ敪���u1(�ʏ�)�v�ȊO�̏ꍇ
          -- =====================================
          IF( l_wholesale_req1_tab( cn_one ).lv_quote_div <> cv_quote_div_usuall ) THEN
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            ln_sql_data_not_flg   := 1;  -- 1���ڌ��ϋ敪����t���O
            EXIT loop_1;                        --LOOP �������痣�E
          END IF;
          -- =====================================
          --�@.���ϋ敪=�u1(�ʏ�)�v����
          --�@.���l - �@.����l�� - �@.�ʏ�NET���i
          --   = ���̓p�����[�^.�x���P��
          --     (in_demand_unit_price)�̏ꍇ
          -- =====================================
          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div = cv_quote_div_usuall )
              AND ( in_demand_unit_price
                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
                          - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price   )
                  )
          ) THEN
            --�E�̔��萔�� = �@.���l - �@.����l�� - �@.�ʏ�NET���i
            on_backmargin_amt := l_wholesale_req1_tab( ln_count ).ln_quotation_price
                               - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
                               - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price;
            IF( l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price = 0 ) THEN
              --�E�̔����^�� = 0 ������X�[��0�̏ꍇ��0
              on_sales_support_amt := 0;
            ELSE
              --�E�̔����^�� = �@.�ʏ�X�[ - �@.����X�[
              on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                                   -  l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
            END IF;
            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_usuall_net_price;     -- NET���i
            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_1;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          --�@.���ϋ敪���u1�v�ȊO  ����
          --�@.���l - �@.����l�� - �@.����NET���i
          --= ���̓p�����[�^.�x���P��
          --    (in_demand_unit_price)�̏ꍇ
          -- =====================================
          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price
                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = �@.���l - �@.����l�� - �@.�ʏ�X�[ + �@.����X�[ - �@.����NET���i
            on_backmargin_amt    := l_wholesale_req1_tab( ln_count ).ln_quotation_price
                                  - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
                                  - l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                                  + l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;
            --�E�̔����^�� = �@.�ʏ�X�[ - �@.����X�[
            on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
--
            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;  -- NET���i
            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
--
            ln_price_check_on_flg := 1; --�ƍ����ʔ���t���O  �I��
            EXIT loop_1;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          --�@.���ϋ敪���u1�v�ȊO  ����
          --�@.���l - �@.����l�� - �@.�ʏ�X�[ + �@.����X�[ - �@.����NET���i
          -- = ���̓p�����[�^.�x���P��
          --      (in_demand_unit_price)�̏ꍇ
          -- =====================================
          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price
                      = (   l_wholesale_req1_tab( ln_count ).ln_quotation_price
                          - l_wholesale_req1_tab( ln_count ).ln_sales_discount_price
                          - l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                          + l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = ���̓p�����[�^.�x���P��
            on_backmargin_amt := in_demand_unit_price;
            --�E�̔����^�� = NULL
            on_sales_support_amt := NULL;
            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req1_tab( ln_count ). ln_this_time_net_price; -- NET���i
            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_1;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          --�@.���ϋ敪���u1�v�ȊO  ����
          --�@.�ʏ�X�[ - �@.����X�[
          -- = ���̓p�����[�^.�x���P��
          --      (in_demand_unit_price)�̏ꍇ
          -- =====================================
          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price
                      = (   l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                          - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price  )
                  )
          ) THEN
            --�E�̔��萔�� = NULL
            on_backmargin_amt := NULL;
            --�E�̔����^�� = ���̓p�����[�^.�x���P��
            on_sales_support_amt := in_demand_unit_price;
            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;          -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;         -- ����ID
            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;       -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;       -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price;  -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;   -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price; -- ����X�[
            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;   -- NET���i
            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;             -- ���ϋ敪
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_1;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          --�@.���ϋ敪���u1�v�ȊO ����
          --�@.�ʏ�NET���i - �@.����NET���i
          --= ���̓p�����[�^.�x���P��
          --      (in_demand_unit_price)�̏ꍇ
          -- =====================================
          IF(     ( l_wholesale_req1_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price
                      = (   l_wholesale_req1_tab( ln_count ).ln_usuall_net_price
                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = (�@.����X�[ - �@.����NET���i)
            --             - (�@.�ʏ�X�[ - �@.�ʏ�NET���i)
            on_backmargin_amt    := (   (   l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price
                                          - l_wholesale_req1_tab( ln_count ).ln_this_time_net_price   )
                                      - (   l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                                          - l_wholesale_req1_tab( ln_count ).ln_usuall_net_price      )
                                    );
            --�E�̔����^�� =  �@.�ʏ�X�[ - �@.����X�[
            on_sales_support_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price
                                  - l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;
            ov_estimated_no             := l_wholesale_req1_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req1_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req1_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req1_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req1_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req1_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req1_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req1_tab( ln_count ).ln_this_time_net_price;  -- NET���i
            ov_estimated_type           := l_wholesale_req1_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_1;                       --LOOP �������痣�E
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_price_check_on_flg := 0;
          WHEN OTHERS THEN
            raise_application_error(
              -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
            );
        END;
      END LOOP loop_1; --l_wholesale_req1_tab LOOP END
--
      IF( ln_price_check_on_flg = 0 ) THEN  --�ƍ����ʔ���t���O  �I�t
        -- =======================================================
        -- �BSQL���s
        -- =======================================================
        SELECT   -- �����≮�p���σw�b�_�[.���Ϗ��ԍ�
                 csoqh_wholesale.quote_number                  AS wholesale_quote_number
                 -- �����≮�p���σw�b�_�[.�S���҃R�[�h
               , csoqh_wholesale.employee_number               AS wholesale_employee_number
                 -- �̔���p���ϖ���.���ϋ敪
               , csoql_sale.quote_div                          AS sale_quote_div
                 -- �̔���p���ϖ���.�ʏ�X�[���i
               , NVL( csoql_sale.usually_deliv_price, 0 )      AS sale_usually_deliv_price
                 -- �̔���p���ϖ���.����X�[���i
               , NVL( csoql_sale.this_time_deliv_price, 0 )    AS csoql_sale_this_time_del_price
                 -- �����≮�p���ϖ���.���ϖ���ID
               , csoql_wholesale.quote_line_id                 AS wholesale_quote_line_id
                 -- �����≮�p���ϖ���.���l
               , NVL( csoql_wholesale.quotation_price , 0 )    AS wholesale_quotation_price
                 -- �����≮�p���ϖ���.����l��
               , NVL( csoql_wholesale.sales_discount_price, 0 )  AS wholesale_sales_discount_price
                 -- �����≮�p���ϖ���.�ʏ�NET���i
               , NVL( csoql_wholesale.usuall_net_price, 0 )    AS wholesale_usuall_net_price
                 -- �����≮�p���ϖ��� .����NET���i
               , NVL( csoql_wholesale.this_time_net_price, 0 ) AS wholesale_this_time_net_price
                 -- OPM�i�ڃ}�X�^.�P�[�X���萔�iDFF11)
               , iim_b.attribute11                             AS iim_b_case_in_num
        -- �≮��������2 �����z��
        BULK COLLECT INTO l_wholesale_req2_tab
        FROM     -- ���σw�b�_�[�e�[�u��:�̔���p���σw�b�_�[
                 xxcso_quote_headers     csoqh_sale
                 -- ���ϖ��׃e�[�u��    :�̔���p���ϖ���
               , xxcso_quote_lines     csoql_sale
                 -- ���σw�b�_�[�e�[�u��:�����≮�p���σw�b�_�[
               , xxcso_quote_headers   csoqh_wholesale
                 -- ���ϖ��׃e�[�u��    :�����≮�p���ϖ���
               , xxcso_quote_lines     csoql_wholesale
                 -- Disc�i�ڃ}�X�^      :Disc�i�ڃ}�X�^
               , mtl_system_items_b    msi_b
                 -- OPM�i�ڃ}�X�^       :OPM�i�ڃ}�X�^
               , ic_item_mst_b         iim_b
                 -- �g�D�p�����[�^      :�g�D�p�����[�^
               , mtl_parameters        mp
        WHERE    -- �����o������
                 -- �̔���p���σw�b�_�[�D���σw�b�_�[ID   = �̔���p���ϖ��ׁD���σw�b�_�[ID
                 csoqh_sale.quote_header_id                = csoql_sale.quote_header_id
                 -- �����≮�p���σw�b�_�[�D���σw�b�_�[ID = �����≮�p���ϖ��ׁD���σw�b�_�[ID
        AND      csoqh_wholesale.quote_header_id           = csoql_wholesale.quote_header_id
                 -- �̔���p���σw�b�_�[�D���Ϗ��ԍ�       = �����≮�p���σw�b�_�[�D�Q�ƌ��ϔԍ�
        AND      csoqh_sale.quote_number                   = csoqh_wholesale.reference_quote_number
                 -- �̔���p���ϖ��ׁD���ϖ���ID           = �����≮�p���ρD�Q�Ɨp���ϖ��ׂh�c
        AND      csoql_sale.quote_line_id                  = csoql_wholesale.reference_quote_line_id
                 -- Disc�i�ڃ}�X�^�D�i��ID                 = �̔���p���ϖ��ׁD�i��ID
        AND      msi_b.inventory_item_id                   = csoql_sale.inventory_item_id
                 -- �̔���p���σw�b�_�[�D���ώ��         = '1'(�̔���)
        AND      csoqh_sale.quote_type                     = cv_quote_type_sale
                 -- �̔���p���σw�b�_�[�D�X�e�[�^�X       = '2'(�m��)
        AND      csoqh_sale.status                         = cv_status_decision
                 -- �����≮�p���σw�b�_�[�D���ώ��       = '2'(�����≮)
        AND      csoqh_wholesale.quote_type                =  cv_quote_type_wholesale
                 -- �����≮�p���σw�b�_�[�D�X�e�[�^�X     = '2'(�m��)
        AND      csoqh_wholesale.status                    = cv_status_decision
                 -- OPM�i�ڃ}�X�^�D�i�ڃR�[�h              = Disc�i�ڃ}�X�^�D�i�ڃR�[�h
        AND      iim_b.item_no                             = msi_b.segment1
                 -- Disc�i�ڃ}�X�^�D�g�DID                 = �g�D�p�����[�^�D�g�DID
        AND      msi_b.organization_id                     = mp.organization_id
                 -- �̔���p���σw�b�_�[�D�ڋq�R�[�h       = ���̓p�����[�^�D�≮������R�[�h
        AND      csoqh_sale.account_number                 = iv_sales_outlets_code
                 -- Disc�i�ڃ}�X�^�D�i�ڃR�[�h             = ���̓p�����[�^�D�i�ڃR�[�h
        AND      msi_b.segment1                            = iv_item_code
                 -- �̔���p���ϖ��ׁD���ԁi�J�n�j        <= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_sale.quote_start_date              <= TO_DATE (iv_selling_month , 'YYYY/MM' )
                 -- �̔���p���ϖ��ׁD���ԁi�I���j        >= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_sale.quote_end_date                >= TO_DATE (iv_selling_month , 'YYYY/MM' )
                 -- �����≮�p���σw�b�_�[�D�ڋq�R�[�h     = ���̓p�����[�^�D�����≮�R�[�h
        AND      csoqh_wholesale.account_number            = iv_wholesale_code
                 -- �����≮�p���σw�b�_�[�D�P���敪      <> ���̓p�����[�^�D�����P��
        AND      csoqh_wholesale.unit_type                <> iv_demand_unit_type
                 -- �����≮�p���ϖ��ׁD���ԁi�J�n�j      <= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_wholesale.quote_start_date         <= TO_DATE ( iv_selling_month , 'YYYY/MM' )
                 -- �����≮�p���ϖ��ׁD���ԁi�I���j      >= ���̓p�����[�^�D����Ώ۔N��
        AND      csoql_wholesale.quote_end_date           >= TO_DATE (iv_selling_month , 'YYYY/MM' )
                 -- �g�D�p�����[�^�D�g�D�R�[�h             = FND_PROFILE�DVALUE('XXCOK1_ORG_CODE_SALES')
        AND      mp.organization_code                      = FND_PROFILE.VALUE( cv_organization_cd )
        ORDER BY -- ���\�[�g������
                 -- �̔���p���ϖ���.���ϋ敪              ����
                 csoql_sale.quote_div                      ASC
                 -- �̔���p���ϖ���.����X�[���i          �~��
               , csoql_sale.this_time_deliv_price          DESC NULLS LAST
                 --�����≮�p���ϖ���.����NET���i          �~��
               , csoql_wholesale.this_time_net_price       DESC NULLS LAST;
        -- =======================================================
        -- �≮�������Ϗƍ�2
        -- =======================================================
        << loop_2 >>
        FOR ln_count IN NVL( l_wholesale_req2_tab.FIRST, 0 ) .. NVL( l_wholesale_req2_tab.LAST, 0 ) LOOP
          -- =====================================
          --�B.FETCH�������R�[�h��
          --1����.���ϋ敪<>�u1(�ʏ�)�v�̏ꍇ
          --1���ڂ̌��ϋ敪���u1(�ʏ�)�v�ȊO�̏ꍇ
          -- =====================================
          IF( l_wholesale_req2_tab( cn_one ).lv_quote_div <> cv_quote_div_usuall ) THEN
            ln_price_check_on_flg := 1; --�ƍ����ʔ���t���O  �I��
            ln_sql_data_not_flg   := 1; -- 1���ڌ��ϋ敪����t���O
            EXIT;                       --LOOP �������痣�E
          END IF;
          -- =======================================================
          -- �C���i���̒P�ʕϊ�
          -- =======================================================
          -- =====================================
          -- ���̓p�����[�^�D�����P��(iv_demand_unit_type)
          -- = �u�{�v�̏ꍇ
          -- =====================================
          IF( iv_demand_unit_type = cv_unit_type_count ) THEN
            --���ω��i���̒P�ʕϊ�
            --���l         = �B.���l         �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_quotation_price
              := l_wholesale_req2_tab( ln_count ).ln_quotation_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����l��     = �B.����l��     �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
              := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --�ʏ�NET���i  = �B.�ʏ�NET���i  �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
              := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����NET���i  = �B.����NET���i  �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_this_time_net_price
              := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --�ʏ�X�[���i = �B.�ʏ�NET���i  �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
              := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����X�[���i = �B.����X�[���i �� �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
              := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price /
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
          END IF;
          -- =====================================
          -- ���̓p�����[�^�D�����P��(iv_demand_unit_type)
          --= �uC/S�v�̏ꍇ
          -- =====================================
          IF( iv_demand_unit_type = cv_unit_type_cs ) THEN
            --���ω��i���̒P�ʕϊ�
            --���l         = �B.���l         �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_quotation_price
              := l_wholesale_req2_tab( ln_count ).ln_quotation_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����l��     = �B.����l��     �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
              := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --�ʏ�NET���i  = �B.�ʏ�NET���i  �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
              := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����NET���i  = �B.����NET���i  �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_this_time_net_price
              := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --�ʏ�X�[���i = �B.�ʏ�NET���i  �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
              := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
            --����X�[���i = �B.����X�[���i �~ �B.�P�[�X���萔
            l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
              := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price *
                 l_wholesale_req2_tab( ln_count ).lv_iim_b_case_in_num;
          END IF;
          -- =======================================================
          -- �D�P���ƍ�
          -- =======================================================
          -- =====================================
          -- �B.���ϋ敪=�u1�v����
          -- �C.���l - �C.����l�� - �C.�ʏ�NET���i
          -- = ���̓p�����[�^.�x���P��(in_demand_unit_price)
          -- =====================================
          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div = cv_quote_div_usuall )
              AND ( in_demand_unit_price =
                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
                        - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = �C.���l     - �C.����l�� - �C.�ʏ�NET���i
            on_backmargin_amt :=
              (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
                - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
                - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price );
            IF( l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price = 0 ) THEN
              --�E�̔����^�� = 0 ������X�[��0�̏ꍇ��0
              on_sales_support_amt := 0;
            ELSE
              --�E�̔����^�� = �C.�ʏ�X�[ - �C.����X�[
              on_sales_support_amt :=
                (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                  - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price);
            END IF;
--
            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;          -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;         -- ����ID
            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;       -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;       -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price;  -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;   -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price; -- ����X�[
            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_usuall_net_price;      -- NET���i
            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;             -- ���ϋ敪
--
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_2;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          --�B.���ϋ敪=�u1�v�ȊO ����
          --�C.���l - �C.����l�� - �C.����NET���i
          -- = ���̓p�����[�^.�x���P��(in_demand_unit_price)
          -- =====================================
          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price =
                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
                      )
          ) THEN
            --�E�̔��萔�� = �C.���l - �C.����l�� - �C.�ʏ�X�[ + �C.����X�[ - �C.����NET���i
            on_backmargin_amt :=
              (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
                - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
                - l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                + l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
                - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price );
            --�E�̔����^�� = �C.�ʏ�X�[ - �C.����X�[
            on_sales_support_amt :=
              (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price );
--
            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET���i
            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
--
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_2;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          -- �B.���ϋ敪=�u1�v�ȊO  ����
          -- �C.���l - �C.����l�� - �C.�ʏ�X�[ + �C.����X�[ - �C.����NET���i
          -- = ���̓p�����[�^.�x���P��(in_demand_unit_price)
          -- =====================================
          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price =
                      (   l_wholesale_req2_tab( ln_count ).ln_quotation_price
                        - l_wholesale_req2_tab( ln_count ).ln_sales_discount_price
                        - l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                        + l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = ���̓p�����[�^.�x���P��(in_demand_unit_price)
            on_backmargin_amt := in_demand_unit_price;
            --�E�̔����^�� = NULL
            on_sales_support_amt := NULL;
--
            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET���i
            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
--
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_2;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          -- �B.���ϋ敪=�u1�v�ȊO ����
          -- �C.�ʏ�X�[ - �C.����X�[
          -- = ���̓p�����[�^.�x���P��(in_demand_unit_price)
          -- =====================================
          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price =
                      (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                        - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price )
                  )
          ) THEN
            --�E�̔��萔�� = NULL
            on_backmargin_amt := NULL;
            --�E�̔����^�� = ���̓p�����[�^.�x���P��(in_demand_unit_price)
            on_sales_support_amt := in_demand_unit_price;
--
            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;         -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;        -- ����ID
            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;      -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;      -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price; -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;  -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price;-- ����X�[
            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;  -- NET���i
            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;            -- ���ϋ敪
--
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_2;                       --LOOP �������痣�E
          END IF;
          -- =====================================
          -- �B.���ϋ敪=�u1�v�ȊO ����
          -- �C.�ʏ�NET���i - �C.����NET���i
          -- = ���̓p�����[�^.�x���P��(in_demand_unit_price)
          -- =====================================
          IF(     ( l_wholesale_req2_tab( ln_count ).lv_quote_div <> cv_quote_div_usuall )
              AND ( in_demand_unit_price =
                      (   l_wholesale_req2_tab( ln_count ).ln_usuall_net_price
                        - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price )
                  )
          ) THEN
            --�E�̔��萔�� = (�C.����X�[ - �C.����NET���i) - (�C.�ʏ�X�[ - �C.�ʏ�NET���i)
            on_backmargin_amt :=
              (   (   l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price
                    - l_wholesale_req2_tab( ln_count ).ln_this_time_net_price   )
                - (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                    - l_wholesale_req2_tab( ln_count ).ln_usuall_net_price      )
              );
            --�E�̔����^�� = �C.�ʏ�X�[ - �C.����X�[
            on_sales_support_amt :=
              (   l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price
                - l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price );
--
            ov_estimated_no             := l_wholesale_req2_tab( ln_count ).lv_quote_number;          -- ���Ϗ�No.
            on_quote_line_id            := l_wholesale_req2_tab( ln_count ).ln_quote_line_id;         -- ����ID
            ov_emp_code                 := l_wholesale_req2_tab( ln_count ).lv_employee_number;       -- �S���҃R�[�h
            on_market_amt               := l_wholesale_req2_tab( ln_count ).ln_quotation_price;       -- �ʏ팚�l
            on_allowance_amt            := l_wholesale_req2_tab( ln_count ).ln_sales_discount_price;  -- �l��(���߂�)
            on_normal_store_deliver_amt := l_wholesale_req2_tab( ln_count ).ln_usually_deliv_price;   -- �ʏ�X�[
            on_once_store_deliver_amt   := l_wholesale_req2_tab( ln_count ).ln_this_time_deliv_price; -- ����X�[
            on_net_selling_price        := l_wholesale_req2_tab( ln_count ).ln_this_time_net_price;   -- NET���i
            ov_estimated_type           := l_wholesale_req2_tab( ln_count ).lv_quote_div;             -- ���ϋ敪
--
            ln_price_check_on_flg := 1;  --�ƍ����ʔ���t���O  �I��
            EXIT loop_2;                       --LOOP �������痣�E
          END IF;
        END LOOP; --l_wholesale_req2_tab LOOP END
      END IF;     -- condition IF ln_price_check_on_flg = 0 END
    END IF;     -- condition IF( iv_item_code IS NULL ) THEN
    -- =======================================================
    -- �I������
    -- =======================================================
    IF( ln_price_check_on_flg = 1 ) THEN  --�ƍ����ʔ���t���O  �I��
      --���σf�[�^���擾�ł����ꍇ--
      ov_retcode                  :=  gv_status_normal;
      ov_errbuf                   :=  NULL;
      ov_errmsg                   :=  NULL;
      IF(  ln_sql_data_not_flg = 1 ) THEN          -- 1���ڌ��ϋ敪����
        ov_estimated_type         := cv_zero;  -- ���ϋ敪
      END IF;
    ELSE
      --���σf�[�^���擾�ł��Ȃ������ꍇ--
      ov_estimated_no             := NULL;     -- ���Ϗ�No
      on_quote_line_id            := NULL;     -- ����ID
      ov_emp_code                 := NULL;     -- �S���҃R�[�h
      on_market_amt               := NULL;     -- ���l
      on_allowance_amt            := NULL;     -- �l��(���߂�)
      on_normal_store_deliver_amt := NULL;     -- �ʏ�X�[
      on_once_store_deliver_amt   := NULL;     -- ����X�[
      on_net_selling_price        := NULL;     -- NET���i
      IF( iv_item_code IS NULL ) THEN
        --IN�p�����[�^.�i�ڃR�[�h=NULL�̏ꍇ
        ov_estimated_type         := NULL;     -- ���ϋ敪
      ELSE
        ov_estimated_type         := cv_zero;  -- ���ϋ敪
      END IF;
--
      on_backmargin_amt           := NULL;     -- �̔��萔��
      on_sales_support_amt        := NULL;     -- �̔����^��
      ov_retcode                  := gv_status_normal;
      ov_errbuf                   := NULL;
      ov_errmsg                   := NULL;
    END IF;
--
  EXCEPTION
    --���σf�[�^���擾�ł��Ȃ������ꍇ--
    WHEN NO_DATA_FOUND THEN
      ov_estimated_no             := NULL;     -- ���Ϗ�No
      on_quote_line_id            := NULL;     -- ����ID
      ov_emp_code                 := NULL;     -- �S���҃R�[�h
      on_market_amt               := NULL;     -- ���l
      on_allowance_amt            := NULL;     -- �l��(���߂�)
      on_normal_store_deliver_amt := NULL;     -- �ʏ�X�[
      on_once_store_deliver_amt   := NULL;     -- ����X�[
      on_net_selling_price        := NULL;     -- NET���i
      ov_estimated_type           := cv_zero;  -- ���ϋ敪
      on_backmargin_amt           := NULL;     -- �̔��萔��
      on_sales_support_amt        := NULL;     -- �̔����^��
      ov_retcode                  := gv_status_normal;
      ov_errbuf                   := NULL;
      ov_errmsg                   := NULL;
    WHEN OTHERS THEN
      ov_retcode := gv_status_error;
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_wholesale_req_est_p;
--
  /******************************************************************************
   *FUNCTION NAME : get_wholesale_req_est_type_f
   *Desctiption   : �≮���������Ϗ��ˍ��X�e�[�^�X�擾
   ******************************************************************************/
  FUNCTION get_wholesale_req_est_type_f(
    iv_wholesale_code     IN VARCHAR2 -- �≮�Ǘ��R�[�h
  , iv_sales_outlets_code IN VARCHAR2 -- �≮������R�[�h
  , iv_item_code          IN VARCHAR2 -- �i�ڃR�[�h
  , in_demand_unit_price  IN NUMBER   -- �x���P��
  , iv_demand_unit_type   IN VARCHAR2 -- �����P��
  , iv_selling_month      IN VARCHAR2 -- ����Ώ۔N��
  )
  RETURN VARCHAR2                     -- �X�e�[�^�X
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_wholesale_req_est_type_f';    -- �v���O������
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lv_retcode                  VARCHAR2(1)     DEFAULT gv_status_normal;
    lv_errbuf                   VARCHAR2(32767) DEFAULT NULL;
    lv_errmsg                   VARCHAR2(32767) DEFAULT NULL;
    lt_estimated_no             xxcso_quote_headers.quote_number%TYPE;        -- ���Ϗ�No.
    lt_wholesale_bill_detail_id xxcso_quote_lines.quote_line_id%TYPE;         -- ����ID
    lt_emp_code                 xxcso_quote_headers.employee_number%TYPE;     -- �S���҃R�[�h
    lt_market_amt               xxcso_quote_lines.quotation_price%TYPE;       -- ���l
    lt_allowance_amt            xxcso_quote_lines.sales_discount_price%TYPE;  -- �l��(���߂�)
    lt_normal_store_deliver_amt xxcso_quote_lines.usually_deliv_price%TYPE;   -- �ʏ�X�[
    lt_once_store_deliver_amt   xxcso_quote_lines.this_time_deliv_price%TYPE; -- ����X�[
    lt_net_selling_price        xxcso_quote_lines.usuall_net_price%TYPE;      -- NET���i
    lt_estimated_type           xxcso_quote_lines.quote_div%TYPE;             -- ���ϋ敪
    ln_backmargin_amt           NUMBER;                                       -- �̔��萔��
    ln_sales_support_amt        NUMBER;                                       -- �̔����^��
--
  BEGIN
    -- =======================================================
    -- �≮�������Ϗƍ��ďo
    -- =======================================================
    get_wholesale_req_est_p(
      lv_errbuf                   -- OUT �G���[�o�b�t�@
    , lv_retcode                  -- OUT ���^�[���R�[�h
    , lv_errmsg                   -- OUT �G���[���b�Z�[�W
    , iv_wholesale_code           -- IN �≮�Ǘ��R�[�h
    , iv_sales_outlets_code       -- IN �≮������R�[�h
    , iv_item_code                -- IN �i�ڃR�[�h
    , in_demand_unit_price        -- IN �x���P��
    , iv_demand_unit_type         -- IN �����P��
    , iv_selling_month            -- IN ����Ώ۔N��
    , lt_estimated_no             -- OUT ���Ϗ�No.
    , lt_wholesale_bill_detail_id -- OUT ����ID
    , lt_emp_code                 -- OUT �S���҃R�[�h
    , lt_market_amt               -- OUT ���l
    , lt_allowance_amt            -- OUT �l��(���߂�)
    , lt_normal_store_deliver_amt -- OUT �ʏ�X�[
    , lt_once_store_deliver_amt   -- OUT ����X�[
    , lt_net_selling_price        -- OUT NET���i
    , lt_estimated_type           -- OUT ���ϋ敪
    , ln_backmargin_amt           -- OUT �̔��萔��
    , ln_sales_support_amt        -- OUT �̔����^��
    );
    -- =======================================================
    -- ���ϋ敪��ԋp
    -- =======================================================
    RETURN lt_estimated_type; -- ���ϋ敪��ԋp
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- �Y�����郌�R�[�h�����݂��Ȃ������ꍇ��NULL��Ԃ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_wholesale_req_est_type_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_companies_code_f
   *Desctiption   : ��ƃR�[�h�擾
   ******************************************************************************/
  FUNCTION get_companies_code_f(
    iv_customer_code IN VARCHAR2 -- �ڋq�R�[�h
  )
  RETURN VARCHAR2
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name    CONSTANT  VARCHAR2(30) := 'get_companies_code_f';  -- �v���O������
    cv_lookup_type CONSTANT  VARCHAR2(30) := 'XXCMM_CHAIN_CODE';
    cv_y           CONSTANT  VARCHAR2(1)  := 'Y';
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lt_companies_code fnd_lookup_values.attribute1%TYPE DEFAULT NULL; -- ��ƃR�[�h
--
  BEGIN
    -- =======================================================
    -- ��ƃR�[�h�̎擾
    -- =======================================================
    SELECT flv.attribute1           AS companies_code1
    INTO   lt_companies_code
    FROM   xxcmm_cust_accounts      xca
         , fnd_lookup_values        flv
    WHERE  xca.customer_code        = iv_customer_code
    AND    xca.delivery_chain_code  = flv.lookup_code
    AND    flv.lookup_type          = cv_lookup_type
    AND    flv.language             = USERENV( 'LANG' )
    AND    flv.enabled_flag         = cv_y
    AND    NVL( flv.start_date_active, xxccp_common_pkg2.get_process_date )
             <= xxccp_common_pkg2.get_process_date
    AND    NVL( flv.end_date_active, xxccp_common_pkg2.get_process_date )
             >= xxccp_common_pkg2.get_process_date;
    -- �擾�l��߂�
    RETURN lt_companies_code;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- �Y�����郌�R�[�h�����݂��Ȃ������ꍇ��NULL��Ԃ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_companies_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_department_code_f
   *Desctiption   : ��������R�[�h�擾
   ******************************************************************************/
  FUNCTION get_department_code_f(
    in_user_id IN NUMBER -- ���[�U�[ID
  )
  RETURN VARCHAR2        -- ��������R�[�h
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_department_code_f'; -- �v���O������
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lt_department_code per_all_people_f.attribute28%TYPE DEFAULT NULL; -- ��������R�[�h
    ld_process_date    DATE;                                           -- �Ɩ����t
    lt_employee_id     fnd_user.employee_id%TYPE;                      -- ��������R�[�h
--
  BEGIN
    -- ==========================================
    -- �Ɩ����t�擾
    -- ==========================================
    ld_process_date :=xxccp_common_pkg2.get_process_date;
    -- ==========================================
    -- ���[�U�e�[�u������]�ƈ�ID�擾
    -- ==========================================
    SELECT fu.employee_id AS employee_id   -- �]�ƈ�ID
    INTO   lt_employee_id
    FROM   fnd_user       fu
    WHERE  fu.user_id     = in_user_id
    AND    -- �Ɩ����t���J�n���ȏ�
           -- �����J�n�� = NULL -> �J�n�� = �Ɩ����t�ɕϊ�
           NVL( fu.start_date, ld_process_date ) <= ld_process_date
    AND
           -- �Ɩ����t���I�����ȉ�
           -- �����I���� = NULL -> �I���� = �Ɩ����t�ɕϊ�
           NVL( fu.end_date, ld_process_date ) >= ld_process_date;
    -- ==========================================
    -- �]�ƈ��e�[�u�����畔��R�[�h�擾
    -- ==========================================
    SELECT pap.attribute28    AS department_code   -- ����R�[�h
    INTO   lt_department_code
    FROM   per_all_people_f   pap
    WHERE  pap.person_id      = lt_employee_id
    AND    -- �Ɩ����t���L���J�n���ȏ�
           -- �����L���J�n�� = NULL -> �L���J�n�� = �Ɩ����t�ɕϊ�
           NVL( pap.effective_start_date, ld_process_date ) <= ld_process_date
    AND    -- �Ɩ����t���L���I�����ȉ�
           -- �����L���I���� = NULL -> �L���I���� = �Ɩ����t�ɕϊ�
           NVL( pap.effective_end_date, ld_process_date ) >= ld_process_date;
--
    RETURN lt_department_code;        -- ��������R�[�h
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --��������R�[�h��NULL��ݒ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_department_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_batch_name_f
   *Desctiption   : �o�b�`���擾
   ******************************************************************************/
  FUNCTION get_batch_name_f(
    iv_category_name IN VARCHAR2 -- �d��J�e�S����
  )
  RETURN VARCHAR2                -- �o�b�`��
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_batch_name_f'; -- �v���O������
    cv_space    CONSTANT VARCHAR2(1)  := ' ';                -- ���p�X�y�[�X
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lv_batch_name VARCHAR2(100)  DEFAULT NULL; -- �o�b�`��
--
  BEGIN
    --=======================================
    -- IN �p�����[�^�d��J�e�S���� NULL �`�F�b�N
    --=======================================
    IF( iv_category_name IS NULL ) THEN
      --IN�p�����[�^���d��J�e�S������NULL�̏ꍇ
      --OUT�p�����[�^�ɃV�X�e�����t�̂ݐݒ�
      lv_batch_name  := TO_CHAR( SYSDATE ); -- �o�b�`��
    ELSE
      --IN�p�����[�^���d��J�e�S������NULL�ȊO�ꍇ
      --OUT�p�����[�^�Ɏd��J�e�S����+���p�X�y�[�X+�V�X�e�����t��ݒ�
      lv_batch_name  := iv_category_name || cv_space ||TO_CHAR( SYSDATE ); -- �o�b�`��
    END IF;
--
    RETURN lv_batch_name; -- �o�b�`��
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_batch_name_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_slip_number_f
   *Desctiption   : �`�[�ԍ��擾
   ******************************************************************************/
  FUNCTION get_slip_number_f(
    iv_package_name IN VARCHAR2 -- �p�b�P�[�W��
  )
  RETURN VARCHAR2               -- �o�b�`��
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_slip_number_f';           -- �v���O������
    cv_lookup_type CONSTANT VARCHAR2(30) := 'XXCOK1_SLIP_NUMBER_SEQ_TYPE'; --LOOKUP�^�C�v
    cv_pad_string  CONSTANT VARCHAR2(1)  := '0';                           --�ǉ����镶����:0
    cn_pad_length  CONSTANT NUMBER       :=  8;                            --������̒���
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lv_slip_number   VARCHAR2(30)     DEFAULT NULL;     -- �`�[�ԍ�
    lv_sql_stmt      VARCHAR2(32767)  DEFAULT NULL;     -- ���ISQL�p������
    lt_sequence_id   fnd_lookup_values.attribute1%TYPE; -- �V�[�P���X�擾�p�ϐ�
    lt_slip_num_hdr2 fnd_lookup_values.attribute2%TYPE; -- �V�[�P���X�ԍ���2��
    ln_sequence_nm   NUMBER;                            -- �V�[�P���X�ԍ�
--
  BEGIN
    -- =======================================================
    -- �V�[�P���X�ԍ��쐬�p�ϐ��̎擾
    -- =======================================================
    SELECT flv.attribute1    flv_sequence_id     -- �V�[�P���X�擾�p�ϐ�
         , flv.attribute2    flv_slip_num_hdr2   -- �V�[�P���X�ԍ���2��
    INTO   lt_sequence_id                        -- �V�[�P���X�擾�p�ϐ�
         , lt_slip_num_hdr2                      -- �V�[�P���X�ԍ���2��
    FROM   fnd_lookup_values flv                 -- ���σw�b�_�[�e�[�u��:�̔���p���σw�b�_�[
    WHERE  flv.lookup_type   = cv_lookup_type    -- �V�[�P���X�擾�p�ϐ�
    AND    flv.language      = USERENV( 'LANG' ) -- ����^�C�v
    AND    flv.meaning       = iv_package_name;  -- �p�b�P�[�W��
    -- =======================================================
    -- ���ISQL���̍쐬
    -- =======================================================
    lv_sql_stmt := ( 'SELECT ' || lt_sequence_id || '.NEXTVAL sequence_num  ' || ' FROM DUAL' );
    -- =======================================================
    -- ���ISQL���̎��s
    -- =======================================================
    EXECUTE IMMEDIATE lv_sql_stmt INTO ln_sequence_nm;
    -- =======================================================
    -- �`�[�ԍ��̍쐬
    -- =======================================================
    lv_slip_number := lt_slip_num_hdr2 || LPAD ( ln_sequence_nm, cn_pad_length, cv_pad_string );
    -- =======================================================
    -- �`�[�ԍ� �ԋp
    -- =======================================================
    RETURN lv_slip_number; -- �`�[�ԍ�
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- �f�[�^�����݂��Ȃ�����NULL��ԋp����
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_slip_number_f;
--
  /******************************************************************************
   *FUNCTION NAME : check_year_migration_f
   *Desctiption   : �N���ڍs���m��`�F�b�N
   ******************************************************************************/
  FUNCTION check_year_migration_f(
    in_year IN NUMBER -- �N��
  )
  RETURN BOOLEAN      -- �u�[���l
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name            CONSTANT VARCHAR2(30) := 'check_year_migration_f';     -- �v���O������
    ct_status_decision_a   CONSTANT xxcok_cust_shift_info.status%TYPE := 'A';     -- �X�e�[�^�X=�m��
    ct_shift_type_annual_1 CONSTANT xxcok_cust_shift_info.shift_type%TYPE := '1'; -- �ڍs�敪=�N��
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    ln_count NUMBER ; -- ����
    lb_check BOOLEAN; -- �߂�l
--
  BEGIN
    -- ==========================================
    -- �N���ڍs���m�茏���擾
    -- �Ώۉ�v�N�x = IN�p�����[�^�̔N��  ����
    -- �X�e�[�^�X   = 'A':�m��            ����
    -- �ڍs�敪     = '1':�N��
    -- ==========================================
    SELECT COUNT( 'X' )          AS kensu                 -- ����
    INTO   ln_count                                       -- ����
    FROM   xxcok_cust_shift_info csi                      -- �ڋq�ڍs���e�[�u��
    WHERE  csi.target_acctg_year = in_year
    AND    csi.status            = ct_status_decision_a
    AND    csi.shift_type        = ct_shift_type_annual_1
    AND    ROWNUM                = 1;
    -- ==========================================
    -- �N���ڍs���m�茏���`�F�b�N
    -- ==========================================
    IF( ln_count = 0 ) THEN
      -- ���݂��Ȃ�
      -- �Ώۉ�v�N�x = IN�p�����[�^�̔N��  ����
      -- �X�e�[�^�X   = 'A':�m��            ����
      -- �ڍs�敪     = '1':�N���ɍ��v���郌�R�[�h�Ȃ�
      lb_check := TRUE;  -- ���茋�� =TRUE ��ݒ�
    ELSE
      -- ���݂���
      -- �Ώۉ�v�N�x = IN�p�����[�^�̔N��  ����
      -- �X�e�[�^�X   = 'A':�m��            ����
      -- �ڍs�敪     = '1':�N���ɍ��v���郌�R�[�h����
      lb_check := FALSE; -- ���茋�� =FALSE ��ݒ�
    END IF;
    --���茋��
    RETURN lb_check;     -- ���茋�ʂ����^�[��
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --���݂��Ȃ�
      RETURN TRUE; -- TRUE
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_year_migration_f;
--
  /******************************************************************************
   *FUNCTION NAME : check_code_combination_id_f
   *Desctiption   : CCID���݃`�F�b�N
   ******************************************************************************/
  FUNCTION check_code_combination_id_f(
    iv_segment1 IN VARCHAR2 -- ��ЃR�[�h
  , iv_segment2 IN VARCHAR2 -- ����R�[�h
  , iv_segment3 IN VARCHAR2 -- ����ȖڃR�[�h
  , iv_segment4 IN VARCHAR2 -- �⏕�ȖڃR�[�h
  , iv_segment5 IN VARCHAR2 -- �ڋq�R�[�h
  , iv_segment6 IN VARCHAR2 -- ��ƃR�[�h
  , iv_segment7 IN VARCHAR2 -- �\���P�R�[�h
  , iv_segment8 IN VARCHAR2 -- �\���Q�R�[�h
  )
  RETURN BOOLEAN            -- �u�[���l
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'check_code_combination_id_f'; -- �v���O������
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    ln_count             NUMBER ;                                    -- ����
    lb_check             BOOLEAN;                                    -- �߂�l
    lv_errbuf            VARCHAR2(32767);                            -- �G���[�E�o�b�t�@
    lv_retcode           VARCHAR2(1);                                -- ���^�[���R�[�h
    lv_errmsg            VARCHAR2(32767);                            -- �G���[�E���b�Z�[�W
    lt_set_of_books_id   gl_sets_of_books.set_of_books_id%TYPE;      -- ��v����ID
    lt_set_of_books_name gl_sets_of_books.name%TYPE;                 -- ��v���떼
    lt_chart_acct_id     gl_sets_of_books.chart_of_accounts_id%TYPE; -- ����̌nID
    lt_period_set_name   gl_sets_of_books.period_set_name%TYPE;      -- �J�����_��
    ln_aff_segment_cnt   NUMBER;                                     -- AFF�Z�O�����g��`��
    lt_currency_code     gl_sets_of_books.currency_code%TYPE;        -- �@�\�ʉ݃R�[�h
--
  BEGIN
    -- ==========================================
    -- get_set_of_books_info_p
    -- ��v������擾
    -- ==========================================
    xxcok_common_pkg.get_set_of_books_info_p(
      lv_errbuf            --  �G���[�E�o�b�t�@
    , lv_retcode           --  ���^�[���R�[�h
    , lv_errmsg            --  �G���[�E���b�Z�[�W
    , lt_set_of_books_id   -- ��v����ID
    , lt_set_of_books_name -- ��v���떼
    , lt_chart_acct_id     -- ����̌nID
    , lt_period_set_name   -- �J�����_��
    , ln_aff_segment_cnt   -- AFF�Z�O�����g��`��
    , lt_currency_code     -- �@�\�ʉ݃R�[�h
    );
    -- ==========================================
    -- GL_CODE_COMBINATIONS����
    -- CCID���݃`�F�b�N
    -- ��v������擾
    -- IN�p�����[�^�̏����Ō���
    -- ==========================================
    SELECT COUNT( 'X' )             AS kensu           -- ����
    INTO   ln_count                                    -- ����
    FROM   gl_code_combinations     gcc                -- gl_code_combinations�e�[�u��
    WHERE  gcc.chart_of_accounts_id = lt_chart_acct_id -- ����̌nID
    AND    gcc.segment1             = iv_segment1      -- ��ЃR�[�h
    AND    gcc.segment2             = iv_segment2      -- ����R�[�h
    AND    gcc.segment3             = iv_segment3      -- ����ȖڃR�[�h
    AND    gcc.segment4             = iv_segment4      -- �⏕�ȖڃR�[�h
    AND    gcc.segment5             = iv_segment5      -- �ڋq�R�[�h
    AND    gcc.segment6             = iv_segment6      -- ��ƃR�[�h
    AND    gcc.segment7             = iv_segment7      -- �\���P�R�[�h
    AND    gcc.segment8             = iv_segment8      -- �\���Q�R�[�h
    AND    ROWNUM                   = 1;
    -- ==========================================
    -- CCID���݃`�F�b�N�m�F
    -- ==========================================
    IF( ln_count = 0 ) THEN
      -- ���݂��Ȃ�
      lb_check := FALSE; -- ���茋�� =FALSE ��ݒ�
    ELSE
      -- ���݂���
      lb_check := TRUE;  -- ���茋�� =TRUE ��ݒ�
    END IF;
    --���茋��
    RETURN lb_check;     -- ���茋�ʂ����^�[��
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --���݂��Ȃ�
      RETURN FALSE;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END check_code_combination_id_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_code_combination_id_f
   *Desctiption   : CCID�擾
   ******************************************************************************/
  FUNCTION get_code_combination_id_f(
    id_proc_date IN DATE     -- ������
  , iv_segment1  IN VARCHAR2 -- ��ЃR�[�h
  , iv_segment2  IN VARCHAR2 -- ����R�[�h
  , iv_segment3  IN VARCHAR2 -- ����ȖڃR�[�h
  , iv_segment4  IN VARCHAR2 -- �⏕�ȖڃR�[�h
  , iv_segment5  IN VARCHAR2 -- �ڋq�R�[�h
  , iv_segment6  IN VARCHAR2 -- ��ƃR�[�h
  , iv_segment7  IN VARCHAR2 -- �\���P�R�[�h
  , iv_segment8  IN VARCHAR2 -- �\���Q�R�[�h
  )
  RETURN NUMBER              -- ����Ȗ�ID
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name               CONSTANT VARCHAR2(30) := 'get_code_combination_id_f'; -- �v���O������
    cn_err_on                 CONSTANT NUMBER       := 1;                           -- �G���[�l
    cn_err_off                CONSTANT NUMBER       := 0;                           -- �G���[�l
    cv_application_short_name CONSTANT VARCHAR2(5)  := 'SQLGL';                     -- �A�v���P�[�V�����Z�k��
    cv_key_flex_code          CONSTANT VARCHAR2(3)  := 'GL#';                       -- �t���b�N�X�t�B�[���h�R�[�h
    cn_start                  CONSTANT NUMBER       := 1;                           -- FOR �J�n�l
    cn_end                    CONSTANT NUMBER       := 8;                           -- FOR �I���l
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    ln_ccid                 NUMBER DEFAULT NULL;                        -- ����Ȗ�ID
    ln_in_para_check_flg    NUMBER DEFAULT 0;                           -- ���̓p�����[�^�`�F�b�N�t���O
    lb_exist_check          BOOLEAN;                                    -- �߂�l
    lb_get_cmbntn_id_check  BOOLEAN;                                    -- �߂�l
    lv_errbuf               VARCHAR2(32767);                            --  �G���[�E�o�b�t�@
    lv_retcode              VARCHAR2(1);                                --  ���^�[���R�[�h
    lv_errmsg               VARCHAR2(32767);                            --  �G���[�E���b�Z�[�W
    lt_set_of_books_id      gl_sets_of_books.set_of_books_id%TYPE;      -- ��v����ID
    lt_set_of_books_name    gl_sets_of_books.name%TYPE;                 -- ��v���떼
    lt_chart_acct_id        gl_sets_of_books.chart_of_accounts_id%TYPE; -- ����̌nID
    lt_period_set_name      gl_sets_of_books.period_set_name%TYPE;      -- �J�����_��
    ln_aff_segment_cnt      NUMBER;                                     -- AFF�Z�O�����g��`��
    lt_currency_code        gl_sets_of_books.currency_code%TYPE;        -- �@�\�ʉ݃R�[�h
    l_segments_rec          fnd_flex_ext.SegmentArray;                  -- �Z�O�����g�l�z��
    ln_count                NUMBER;                                     -- �Y����
--
  BEGIN
    -- ==========================================
    -- IN�p�����[�^���͒l�`�F�b�N
    -- ==========================================
    IF(    ( id_proc_date IS NULL )
        OR ( iv_segment1  IS NULL )
        OR ( iv_segment2  IS NULL )
        OR ( iv_segment3  IS NULL )
        OR ( iv_segment4  IS NULL )
        OR ( iv_segment5  IS NULL )
        OR ( iv_segment6  IS NULL )
        OR ( iv_segment7  IS NULL )
        OR ( iv_segment8  IS NULL )
    ) THEN
      -- ������,��ЃR�[�h,����R�[�h,����ȖڃR�[�h,
      -- �⏕�ȖڃR�[�h, �ڋq�R�[�h, ��ƃR�[�h
      -- �\���P�R�[�h, �\���Q�R�[�h��NULL�̏ꍇ
      -- ���̓p�����[�^�`�F�b�N�t���O���I���ݒ�
      ln_in_para_check_flg := cn_err_on;
    END IF;
--
    IF( ln_in_para_check_flg = cn_err_off ) THEN
      --=======================================
      -- CCID���݃`�F�b�N
      --=======================================
      lb_exist_check := xxcok_common_pkg.check_code_combination_id_f(
                          iv_segment1 -- ��ЃR�[�h
                        , iv_segment2 -- ����R�[�h
                        , iv_segment3 -- ����ȖڃR�[�h
                        , iv_segment4 -- �⏕�ȖڃR�[�h
                        , iv_segment5 -- �ڋq�R�[�h
                        , iv_segment6 -- ��ƃR�[�h
                        , iv_segment7 -- �\���P�R�[�h
                        , iv_segment8 -- �\���Q�R�[�h
                        );
      -- ==========================================
      -- get_set_of_books_info_p
      -- ��v������擾
      -- ==========================================
      xxcok_common_pkg.get_set_of_books_info_p(
        lv_errbuf            -- �G���[�E�o�b�t�@
      , lv_retcode           -- ���^�[���R�[�h
      , lv_errmsg            -- �G���[�E���b�Z�[�W
      , lt_set_of_books_id   -- ��v����ID
      , lt_set_of_books_name -- ��v���떼
      , lt_chart_acct_id     -- ����̌nID
      , lt_period_set_name   -- �J�����_��
      , ln_aff_segment_cnt   -- AFF�Z�O�����g��`��
      , lt_currency_code     -- �@�\�ʉ݃R�[�h
      );
     IF( lb_exist_check = TRUE ) THEN
       -- CCID�����݂��Ă���ꍇ
       -- ==========================================
       -- GL_CODE_COMBINATIONS����
       -- CCID�擾
       -- IN�p�����[�^�̏����Ō���
       -- ==========================================
       SELECT code_combination_id      ccid               -- ����Ȗ�ID
       INTO   ln_ccid                                     -- ����Ȗ�ID
       FROM   gl_code_combinations     gcc                -- gl_code_combinations�e�[�u��
       WHERE  gcc.chart_of_accounts_id = lt_chart_acct_id -- ����̌nID
       AND    gcc.segment1             = iv_segment1      -- ��ЃR�[�h
       AND    gcc.segment2             = iv_segment2      -- ����R�[�h
       AND    gcc.segment3             = iv_segment3      -- ����ȖڃR�[�h
       AND    gcc.segment4             = iv_segment4      -- �⏕�ȖڃR�[�h
       AND    gcc.segment5             = iv_segment5      -- �ڋq�R�[�h
       AND    gcc.segment6             = iv_segment6      -- ��ƃR�[�h
       AND    gcc.segment7             = iv_segment7      -- �\���P�R�[�h
       AND    gcc.segment8             = iv_segment8;     -- �\���Q�R�[�h
     ELSE
       -- CCID�����݂��ĂȂ��ꍇ
       -- ==========================================
       -- �Z�O�����g�l�z���IN�p�����[�^iv_segment1�`
       -- iv_segment8��ݒ�
       -- ==========================================
       << segment_loop >>
       FOR ln_count IN cn_start..cn_end LOOP
         CASE ln_count
           WHEN 1   THEN
             l_segments_rec( ln_count ) := iv_segment1;
           WHEN 2   THEN
             l_segments_rec( ln_count ) := iv_segment2;
           WHEN 3   THEN
             l_segments_rec( ln_count ) := iv_segment3;
           WHEN 4   THEN
             l_segments_rec( ln_count ) := iv_segment4;
           WHEN 5   THEN
             l_segments_rec( ln_count ) := iv_segment5;
           WHEN 6   THEN
             l_segments_rec( ln_count ) := iv_segment6;
           WHEN 7   THEN
             l_segments_rec( ln_count ) := iv_segment7;
           WHEN 8   THEN
             l_segments_rec( ln_count ) := iv_segment8;
         END CASE;
       END LOOP segment_loop;
       -- ==========================================
       -- CCID�o�^
       -- ==========================================
       lb_get_cmbntn_id_check := fnd_flex_ext.get_combination_id(
                                   cv_application_short_name -- �A�v���P�[�V�����Z�k��
                                 , cv_key_flex_code          -- �t���b�N�X�t�B�[���h�R�[�h
                                 , lt_chart_acct_id          -- AFF�̌nID
                                 , id_proc_date              -- ����t
                                 , cn_end                    -- �Z�O�����g��
                                 , l_segments_rec            -- �Z�O�����g�l�z��
                                 , ln_ccid                   -- ��������CCID
                                 );
     END IF;
    ELSE
      -- ����Ȗ�ID��NULL��ݒ�
      ln_ccid := NULL;
    END IF;
--
    RETURN ln_ccid;                                                         -- ����Ȗ�ID
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- �߂�l��NULL��ݒ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_code_combination_id_f;
--
  /**********************************************************************************
   * Function Name : put_message_f
   * Description   : ���b�Z�[�W�o��
   ***********************************************************************************/
  FUNCTION put_message_f(
    in_which    IN NUMBER   -- �o�͋敪
  , iv_message  IN VARCHAR2 -- ���b�Z�[�W
  , in_new_line IN NUMBER   -- ���s
  )
  RETURN BOOLEAN            -- �u�[���l
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'put_message_f';  -- �v���O������
    cn_newline_one CONSTANT NUMBER       := 1;                --���s�o�͌���=1
    cv_blank       CONSTANT VARCHAR2(1)  := ' ';              --���p�X�y�[�X
    -- =======================================================
    -- ���[�J���ϐ�
    -- ===============================================
    ln_count NUMBER; --���[�v�ϐ�
--
  BEGIN
    -- IN�p�����[�^�̏o�͋敪,���b�Z�[�W����
    IF( ( in_which = FND_FILE.OUTPUT )
      OR
       ( in_which = FND_FILE.LOG    ) )
    THEN
      -- IN�p�����[�^�̃��b�Z�[�W����
      IF( iv_message IS NOT NULL ) THEN
        -- IN�p�����[�^�̏o�͋敪=FND_FILE.OUTPUT�܂���FND_FILE.LOG�܂���
        -- ���b�Z�[�W��NULL�łȂ��ꍇ
        fnd_file.put_line(
          which => in_which   -- �o�͋敪�Z�b�g
        , buff  => iv_message -- �o�̓��b�Z�[�W�Z�b�g
        );
      END IF;
    ELSE
      -- IN�p�����[�^�̏o�͋敪<>FND_FILE.OUTPUT�܂���FND_FILE.LOG�̏ꍇ
      RETURN FALSE;
    END IF;
    -- ���s�o�͔���
    IF( in_new_line >= cn_newline_one ) THEN
      -- IN�p�����[�^�̉��s�̒l�� ���s���o��
      << newline_loop >>
      FOR ln_count IN 1..in_new_line LOOP
        fnd_file.put_line(
          which => in_which
        , buff  => cv_blank
        );
      END LOOP newline_loop;
    END IF;
--
    RETURN TRUE;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END put_message_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_base_code_f
   *Desctiption   : �������_�R�[�h�擾
   ******************************************************************************/
  FUNCTION get_base_code_f(
    id_proc_date IN DATE   -- ������
  , in_user_id   IN NUMBER -- ���[�U�[ID
  )
  RETURN VARCHAR2          -- �������_�R�[�h
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name CONSTANT VARCHAR2(30) := 'get_base_code_f'; -- �v���O������
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    ld_process_date             DATE;                                                   -- �Ɩ����t
    lt_employee_id              fnd_user.employee_id%TYPE;                              -- ��������R�[�h
    lt_max_object_version_num   per_all_assignments_f.object_version_number%TYPE;       -- �ŐV���R�[�h����ϐ�
    lt_max_effective_start_date per_all_assignments_f.effective_start_date%TYPE;        -- �L���J�n��
    lt_base_code                per_all_assignments_f.ass_attribute5%TYPE DEFAULT NULL; -- �������_�R�[�h
    lt_announce_date            per_all_assignments_f.ass_attribute2%TYPE DEFAULT NULL; -- ���ߓ�
    lt_new_base_code            per_all_assignments_f.ass_attribute5%TYPE DEFAULT NULL; -- ���_�R�[�h�i�V�j
    lt_old_base_code            per_all_assignments_f.ass_attribute6%TYPE DEFAULT NULL; -- ���_�R�[�h�i���j
--
  BEGIN
    -- ==========================================
    -- �Ɩ����t�擾
    -- ==========================================
    ld_process_date :=xxccp_common_pkg2.get_process_date;
    -- ==========================================
    -- ���[�U�e�[�u������]�ƈ�ID�擾
    -- ==========================================
    SELECT fu.employee_id AS employee_id -- �]�ƈ�ID
    INTO   lt_employee_id
    FROM   fnd_user fu
    WHERE  fu.user_id     = in_user_id
    AND    -- �Ɩ����t���J�n���ȏ�
           -- �����J�n�� = NULL -> �J�n�� = �Ɩ����t�ɕϊ�
           NVL( fu.start_date, ld_process_date ) <= ld_process_date
    AND
           -- �Ɩ����t���I�����ȉ�
           -- �����I���� = NULL -> �I���� = �Ɩ����t�ɕϊ�
           NVL( fu.end_date  , ld_process_date ) >= ld_process_date;
    -- ==========================================
    -- PER_ALL_ASSIGNMENTS_F����person_id��
    -- �ŐV���R�[�h�𔻒肷��L�[���擾
    -- ==========================================
    SELECT MAX( paa.object_version_number ) AS object_version_number -- �o�[�W�����ԍ�
    INTO   lt_max_object_version_num
    FROM   per_all_assignments_f            paa
    WHERE  paa.person_id                    = lt_employee_id;
--
    SELECT MAX( paa.effective_start_date )  AS effective_start_date -- �L���J�n��
    INTO   lt_max_effective_start_date
    FROM   per_all_assignments_f            paa
    WHERE  paa.person_id                    = lt_employee_id;
    -- ==========================================
    -- PER_ALL_ASSIGNMENTS_F���甭�ߓ�,
    -- ���_�R�[�h(�V), ���_�R�[�h(��) �擾
    -- ==========================================
    SELECT paa.ass_attribute2        AS announce_date              -- ���ߓ�
         , paa.ass_attribute5        AS new_base_code              -- ���_�R�[�h�i�V�j
         , paa.ass_attribute6        AS old_base_code              -- ���_�R�[�h�i���j
    INTO   lt_announce_date                                        -- ���ߓ�
         , lt_new_base_code                                        -- ���_�R�[�h�i�V�j
         , lt_old_base_code                                        -- ���_�R�[�h�i���j
    FROM   per_all_assignments_f     paa                           -- �A�T�C�����g�e�[�u��
    WHERE  paa.person_id             = lt_employee_id
    AND    paa.object_version_number = lt_max_object_version_num   -- �o�[�W�����ԍ�=MAX(�o�[�W�����ԍ�)
    AND    paa.effective_start_date  = lt_max_effective_start_date -- �L���J�n��=MAX(�L���J�n��)
    AND    -- �Ɩ����t���L���J�n���ȏ�
           -- �����L���J�n�� = NULL -> �L���J�n�� = �Ɩ����t�ɕϊ�
           NVL( paa.effective_start_date, ld_process_date ) <= ld_process_date
    AND    -- �Ɩ����t���L���I�����ȉ�
           -- �����L���I���� = NULL -> �L���I���� = �Ɩ����t�ɕϊ�
           NVL( paa.effective_end_date  , ld_process_date ) >= ld_process_date;
    -- ==========================================
    --���_�R�[�h���菈��
    --IN�p�����[�^:������,���ߓ����r����
    -- ���_�R�[�h(�V)�܂��͋��_�R�[�h(��) ��
    --OUT�p�����[�^�ɐݒ�
    -- ==========================================
    IF( TO_DATE( lt_announce_date  ,'YYYYMMDD' ) <= id_proc_date ) THEN
      --���ߓ� >= IN�p�����[�^:������
      --OUT�p�����[�^:�������_�R�[�h�ɋ��_�R�[�h(�V)��ݒ�
      lt_base_code := lt_new_base_code;
    ELSE
      --���ߓ� >= IN�p�����[�^:������
      --OUT�p�����[�^:�������_�R�[�h�ɋ��_�R�[�h(��)��ݒ�
      lt_base_code := lt_old_base_code;
    END IF;
--
    RETURN lt_base_code;                  -- �������_�R�[�h
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --�������_�R�[�h��NULL��ݒ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_base_code_f;
--
  /**********************************************************************************
   * Procedure Name   : split_csv_data_p
   * Description      : CSV�����񕪊�
   ***********************************************************************************/
  PROCEDURE split_csv_data_p(
    ov_errbuf        OUT VARCHAR2        -- �G���[�o�b�t�@
  , ov_retcode       OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errmsg        OUT VARCHAR2        -- �G���[���b�Z�[�W
  , iv_csv_data      IN  VARCHAR2        -- CSV������
  , on_csv_col_cnt   OUT PLS_INTEGER     -- CSV���ڐ�
  , ov_split_csv_tab OUT g_split_csv_tbl -- CSV�����f�[�^
  )
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name    CONSTANT VARCHAR2(30)  := 'split_csv_data_p'; -- �v���O������
    cv_comma       CONSTANT VARCHAR2(1)   := ',';                --�J���}
    cn_length_zero CONSTANT NUMBER        := 0;                  --������̃J���}�Ȃ��̏ꍇ
    cn_first_char  CONSTANT NUMBER        := 1;                  --1������
    cn_add_value   CONSTANT NUMBER        := 2;                  --������ւ̉��Z�l
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_retcode VARCHAR(1);                   -- ���^�[���R�[�h�̕ϐ�
    lv_line    VARCHAR2(32767) DEFAULT NULL; --1�s�̃f�[�^
    lb_col     BOOLEAN         DEFAULT TRUE; --�J�����쐬�p��
    ln_col     NUMBER          DEFAULT 0;    --�J�����ԍ�
    ln_length  NUMBER;                       --�J���}�̈ʒu
--
  BEGIN
    lv_retcode := gv_status_normal;
    -- IN�p�����[�^��CSV����������[�J���ϐ��Ɋi�[
    lv_line    := iv_csv_data;
    -- ===============================================
    -- 1.CSV������f�[�^����؂蕶���P��(�J���})�ŕ���
    -- ===============================================
    IF( lv_line IS NOT NULL ) THEN
      -- *** ��؂蕶���P��(�J���})�ŕ��� ***
      << comma_loop >>
      LOOP
      --lv_line��NULL�܂��̓J���}�������񒆂ɑ��݂��Ȃ��Ȃ����ꍇ  �I��
      EXIT WHEN ( lb_col = FALSE ) ;
        --�J�����ԍ����J�E���g
        ln_col := ln_col + 1;
        --�J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, cv_comma);
        --�J���}���Ȃ�
        IF ( ln_length = cn_length_zero ) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        --�J���}������
        ELSE
          --�J���}���폜
          ln_length := ln_length - 1;
          lb_col    := TRUE;
        END IF;
        -- *** CSV�`�������ڂ��Ƃɕ������ϐ��Ɋi�[ ***
        IF ( lv_line IS NULL ) THEN
          ov_split_csv_tab( ln_col ) := NULL;
          lb_col    := FALSE;
        ELSE
          ov_split_csv_tab( ln_col ) := SUBSTR( lv_line, cn_first_char, ln_length );
        END IF;
        -- *** �擾�������ڂ�����(�J���}�͂̂������߁Aln_length + 2) ***
        IF ( lb_col = TRUE ) THEN
          --�J���}����̏ꍇ
          lv_line := SUBSTR( lv_line, ln_length + cn_add_value );
        ELSE
          --�J���}�Ȃ��̏ꍇ
          lv_line := SUBSTR( lv_line, ln_length );
        END IF;
      END LOOP comma_loop;
    END IF;
    --=======================================
    -- �o�̓p�����[�^�Z�b�g
    --=======================================
    ov_errbuf      := NULL;
    ov_retcode     := lv_retcode;
    ov_errmsg      := NULL;
    on_csv_col_cnt := ln_col;     -- CSV���ڐ����Z�b�g
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END split_csv_data_p;
--
  /******************************************************************************
   *FUNCTION NAME : get_bill_to_cust_code_f
   *Desctiption   : ������ڋq�R�[�h�擾
   ******************************************************************************/
  FUNCTION get_bill_to_cust_code_f(
    iv_ship_to_cust_code IN VARCHAR2 -- �o�א�ڋq�R�[�h
  )
  RETURN VARCHAR2                    -- ������ڋq�R�[�h
  IS
    -- =======================================================
    -- ���[�J���萔
    -- =======================================================
    cv_prg_name               CONSTANT  VARCHAR2(30) := 'get_bill_to_cust_code_f'; -- �v���O������
    cv_attribute_1            CONSTANT  VARCHAR2(1)  := '1';
    cv_receipt_of_money_2     CONSTANT  VARCHAR2(1)  := '2';                       -- ����
    cv_status_a               CONSTANT  VARCHAR2(1)  := 'A';
    cv_customer_class_code_14 CONSTANT  VARCHAR2(2)  := '14';
    cv_site_use_code_bill_to  CONSTANT  VARCHAR2(7)  := 'BILL_TO';
    -- =======================================================
    -- ���[�J���ϐ�
    -- =======================================================
    lt_request_to_cust_code  hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- ������ڋq�R�[�h
    lt_ship_account_number   hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- �o�א�ڋq�R�[�h
--
  BEGIN
    -- =======================================================
    -- ������ڋq�R�[�h�̎擾
    -- =======================================================
    SELECT bill_account_number
         , ship_account_number
    INTO   lt_request_to_cust_code                                              -- ������ڋq�R�[�h
         , lt_ship_account_number                                               -- �o�א�ڋq�R�[�h
    FROM(
      --�@ ������ڋq�|�o�א�ڋq
      SELECT bill_hzca_1.account_number                AS bill_account_number   -- ������ڋq�}�X�^.
           , ship_hzca_1.account_number                AS ship_account_number   -- �o�א�ڋq�}�X�^.
      FROM   hz_cust_accounts                          bill_hzca_1              -- ������ڋq�}�X�^
           , hz_cust_acct_sites_all                    bill_hasa_1              -- ������ڋq���ݒn
           , hz_cust_site_uses_all                     bill_hsua_1              -- ������ڋq�g�p�ړI
           , hz_customer_profiles                      bill_hzcp_1              -- ������ڋq�v���t�@�C��
           , hz_cust_accounts                          ship_hzca_1              -- �o�א�ڋq�}�X�^
           , hz_cust_acct_sites_all                    ship_hasa_1              -- �o�א�ڋq���ݒn
           , hz_cust_site_uses_all                     ship_hsua_1              -- �o�א�ڋq�g�p�ړI
           , hz_cust_acct_relate_all                   bill_hcar_1              -- �ڋq�֘A�}�X�^(�����֘A)
             --������ڋq�}�X�^.�ڋqID                 = �ڋq�֘A�}�X�^(�����֘A).XXX
      WHERE  bill_hzca_1.cust_account_id               = bill_hcar_1.cust_account_id
             --�ڋq�֘A�}�X�^(�����֘A).XXX            = �o�א�ڋq�}�X�^.XXX
      AND    bill_hcar_1.related_cust_account_id       = ship_hzca_1.cust_account_id
             --������ڋq�}�X�^.XXX                    = '14'
      AND    bill_hzca_1.customer_class_code           = cv_customer_class_code_14
             --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X     = 'A'
      AND    bill_hcar_1.status                        = cv_status_a
             --�ڋq�֘A�}�X�^(�����֘A).�A�g���r���[�g = cv_attribute_1
      AND    bill_hcar_1.attribute1                    = cv_attribute_1
             --������ڋq���ݒn.�g�DID                 = ���O�C�����[�U�̑g�DID
      AND    bill_hasa_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --�o�א�ڋq���ݒn.�g�DID                 = ���O�C�����[�U�̑g�DID
      AND    ship_hasa_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --�ڋq�֘A�}�X�^(�����֘A).�g�DID         = ���O�C�����[�U�̑g�DID
      AND    bill_hcar_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --������ڋq�g�p�ړI.�g�DID               = ���O�C�����[�U�̑g�DID
      AND    bill_hsua_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --�o�א�ڋq�g�p�ړI.�g�DID               = ���O�C�����[�U�̑g�DID
      AND    ship_hsua_1.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --������ڋq�}�X�^.�ڋqID                 = ������ڋq���ݒn.�ڋqID
      AND    bill_hzca_1.cust_account_id               = bill_hasa_1.cust_account_id
             --������ڋq���ݒn.�ڋq���ݒnID           = ������ڋq�g�p�ړI.�ڋq���ݒnID
      AND    bill_hasa_1.cust_acct_site_id             = bill_hsua_1.cust_acct_site_id
             --������ڋq�g�p�ړI.�g�p�ړI             = 'BILL_TO'(������)
      AND    bill_hsua_1.site_use_code                 = cv_site_use_code_bill_to
             --�o�א�ڋq�}�X�^.�ڋqID                 = �o�א�ڋq���ݒn.�ڋqID
      AND    ship_hzca_1.cust_account_id               = ship_hasa_1.cust_account_id
             --�o�א�ڋq�g�p�ړI.�ڋq���ݒnID         = �o�א�ڋq���ݒn.�ڋq���ݒnID
      AND    ship_hsua_1.cust_acct_site_id             = ship_hasa_1.cust_acct_site_id
             --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID       = ������ڋq�g�p�ړI.�g�p�ړIID
      AND    ship_hsua_1.bill_to_site_use_id           = bill_hsua_1.site_use_id
             --������ڋq�v���t�@�C��.�g�p�ړIID       IS NULL
      AND    bill_hzcp_1.site_use_id                   IS NULL
             --������ڋq�}�X�^.�ڋqID                 = ������ڋq�v���t�@�C��.�ڋqID
      AND    bill_hzca_1.cust_account_id               = bill_hzcp_1.cust_account_id
      AND    NOT EXISTS(
               SELECT 'X'
               FROM   hz_cust_acct_relate_all   cash_hcar_1   --�ڋq�֘A�}�X�^(�����֘A)
                      --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X   = �eA�f
               WHERE  cash_hcar_1.status                      = cv_status_a
                      --�ڋq�֘A�}�X�^(�����֘A).�֘A����     = �e2�f (����)
               AND    cash_hcar_1.attribute1                  = cv_receipt_of_money_2
                      --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
               AND    cash_hcar_1.related_cust_account_id     = bill_hzca_1.cust_account_id
               --�ڋq�֘A�}�X�^(�����֘A).�g�DID              = ���O�C�����[�U�̑g�DID
               AND    cash_hcar_1.org_id                      = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             )
      UNION ALL
      SELECT ship_hzca_2.account_number      AS bill_account_number   --������ڋq�R�[�h
           , ship_hzca_2.account_number      AS ship_account_number   --�o�א�ڋq�R�[�h
      FROM   hz_cust_accounts                ship_hzca_2              --�o�א�ڋq�}�X�^  ��������E������܂�
           , hz_cust_acct_sites_all          bill_hasa_2              --������ڋq���ݒn
           , hz_cust_site_uses_all           bill_hsua_2              --������ڋq�g�p�ړI
           , hz_cust_site_uses_all           ship_hsua_2              --�o�א�ڋq�g�p�ړI
           , hz_customer_profiles            bill_hzcp_2              --������ڋq�v���t�@�C��
             --������ڋq���ݒn.�g�DID       = ���O�C�����[�U�̑g�DID
      WHERE  bill_hasa_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --������ڋq�g�p�ړI.�g�DID     = ���O�C�����[�U�̑g�DID
      AND    bill_hsua_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
             --�o�א�ڋq�g�p�ړI.�g�DID     = ���O�C�����[�U�̑g�DID
      AND    ship_hsua_2.org_id              = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
      AND    NOT EXISTS(
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all ex_hcar_2        --�ڋq�֘A�}�X�^
               WHERE   --�ڋq�֘A�}�X�^(�����֘A).�ڋqID        = �o�א�ڋq�}�X�^.�ڋqID
                       (ex_hcar_2.cust_account_id               = ship_hzca_2.cust_account_id
                        --
                        --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               OR       ex_hcar_2.related_cust_account_id       = ship_hzca_2.cust_account_id)
                        --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X   = �eA�f
               AND      ex_hcar_2.status                        = cv_status_a
                        --������ڋq���ݒn.�g�DID               = ���O�C�����[�U�̑g�DID
               AND      ex_hcar_2.org_id                        = TO_NUMBER( fnd_profile.value( 'ORG_ID' ) )
                       )
             --������ڋq�}�X�^.�ڋqID           = ������ڋq���ݒn.�ڋqID
      AND    ship_hzca_2.cust_account_id         = bill_hasa_2.cust_account_id
             --������ڋq���ݒn.�ڋq���ݒnID     = ������ڋq�g�p�ړI.�ڋq���ݒnID
      AND    bill_hasa_2.cust_acct_site_id       = bill_hsua_2.cust_acct_site_id
             --������ڋq���ݒn.�ڋq���ݒnID     = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
      AND    bill_hasa_2.cust_acct_site_id       = ship_hsua_2.cust_acct_site_id
             --������ڋq�g�p�ړI.�g�p�ړI       = 'BILL_TO'(������)
      AND    bill_hsua_2.site_use_code           = cv_site_use_code_bill_to
             --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
      AND    ship_hsua_2.bill_to_site_use_id     = bill_hsua_2.site_use_id
             --������ڋq�v���t�@�C��.�g�p�ړI   IS NULL
      AND    bill_hzcp_2.site_use_id             IS NULL
             --������ڋq�}�X�^.�ڋqID           = ������ڋq�v���t�@�C��.�ڋqID
      AND    ship_hzca_2.cust_account_id         = bill_hzcp_2.cust_account_id
    )
    WHERE ship_account_number = iv_ship_to_cust_code;    --���̓p�����[�^.�o�א�ڋq�R�[�h
    -- =======================================================
    -- ������ڋq�R�[�h�����^�[��
    -- =======================================================
    RETURN lt_request_to_cust_code; -- ������ڋq�R�[�h
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      --NO_DATA_FOUND�̏ꍇ�߂�l��NULL��ݒ�
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
--
  END get_bill_to_cust_code_f;
--
  /******************************************************************************
   *FUNCTION NAME : get_uom_conversion_qty_f
   *Desctiption   : ��P�ʊ��Z���擾
   ******************************************************************************/
  FUNCTION get_uom_conversion_qty_f(
    iv_item_code IN VARCHAR2 -- �i�ڃR�[�h
  , iv_uom_code  IN VARCHAR2 -- �P�ʃR�[�h
  , in_quantity  IN NUMBER   -- ���Z�O����
  )
  RETURN NUMBER              -- ��P�ʊ��Z�㐔��
  IS
  -- =======================================================
  -- ���[�J���萔
  -- =======================================================
    cv_prg_name       CONSTANT VARCHAR2(30) := 'get_uom_conversion_qty_f'; -- �v���O������
    cv_profile_option CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';
  -- =======================================================
  -- ���[�J���ϐ�
  -- =======================================================
    lv_before_uom_code        VARCHAR2(10);       -- ���Z�O�P�ʃR�[�h
    ln_before_quantity        NUMBER;             -- ���Z�O����
    lov_item_code             VARCHAR2(20);       -- �i�ڃR�[�h
    lov_organization_code     VARCHAR2(10);       -- �݌ɑg�D�R�[�h
    lon_inventory_item_id     NUMBER;             -- �i�ڂh�c
    lon_organization_id       NUMBER;             -- �݌ɑg�D�h�c
    lov_after_uom_code        VARCHAR2(10);       -- ���Z��P�ʃR�[�h
    ln_after_quantity         NUMBER;             -- ���Z�㐔��
    ln_content                NUMBER;             -- ����
    lv_errbuf                 VARCHAR2(2000);     -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
    lv_retcode                VARCHAR2(1);        -- ���^�[���E�R�[�h               #�Œ�#
    lv_errmsg                 VARCHAR2(2000);     -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
--
    lt_primary_uom_code       mtl_system_items_b.primary_uom_code%TYPE;
--
  BEGIN
--
    lv_before_uom_code    := iv_uom_code;
    ln_before_quantity    := in_quantity;
    lov_item_code         := iv_item_code;
--
    lov_organization_code := FND_PROFILE.VALUE( cv_profile_option );
--
    -- �i�ڂ̊�P�ʂ��擾
    SELECT msib.primary_uom_code
    INTO   lt_primary_uom_code
    FROM   mtl_system_items_b     msib
         , mtl_parameters         mp
    WHERE  msib.organization_id   = mp.organization_id
      AND  mp.organization_code   = lov_organization_code
      AND  msib.segment1          = lov_item_code
    ;
--
    xxcos_common_pkg.get_uom_cnv(
      iv_before_uom_code        => lv_before_uom_code     -- IN            VARCHAR2 -- ���Z�O�P�ʃR�[�h
    , in_before_quantity        => ln_before_quantity     -- IN            NUMBER   -- ���Z�O����
    , iov_item_code             => lov_item_code          -- IN OUT NOCOPY VARCHAR2 -- �i�ڃR�[�h
    , iov_organization_code     => lov_organization_code  -- IN OUT NOCOPY VARCHAR2 -- �݌ɑg�D�R�[�h
    , ion_inventory_item_id     => lon_inventory_item_id  -- IN OUT        NUMBER   -- �i�ڂh�c
    , ion_organization_id       => lon_organization_id    -- IN OUT        NUMBER   -- �݌ɑg�D�h�c
    , iov_after_uom_code        => lt_primary_uom_code    -- IN OUT NOCOPY VARCHAR2 -- ���Z��P�ʃR�[�h
    , on_after_quantity         => ln_after_quantity      -- OUT    NOCOPY NUMBER   -- ���Z�㐔��
    , on_content                => ln_content             -- OUT    NOCOPY NUMBER   -- ����
    , ov_errbuf                 => lv_errbuf              -- OUT    NOCOPY VARCHAR2 -- �G���[�E���b�Z�[�W�G���[     #�Œ�#
    , ov_retcode                => lv_retcode             -- OUT    NOCOPY VARCHAR2 -- ���^�[���E�R�[�h             #�Œ�#
    , ov_errmsg                 => lv_errmsg              -- OUT    NOCOPY VARCHAR  -- ���[�U�[�E�G���[�E���b�Z�[�W #�Œ�#
    );
--
    RETURN ln_after_quantity;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_uom_conversion_qty_f;
--
  /**********************************************************************************
   * Procedure Name   : get_directory_path_f
   * Description      : �f�B���N�g���p�X�擾
   ***********************************************************************************/
  FUNCTION get_directory_path_f(
    iv_directory_name              IN  VARCHAR2         -- �f�B���N�g����
  )
  RETURN VARCHAR2                                       -- �f�B���N�g���p�X
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_directory_path_f'; -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lt_directory_path              all_directories.directory_path%TYPE DEFAULT NULL;
--
  BEGIN
    SELECT ad.directory_path  AS directory_path
    INTO lt_directory_path
    FROM all_directories      ad
    WHERE directory_name = iv_directory_name
    ;
    RETURN lt_directory_path;
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END get_directory_path_f;
--
END xxcok_common_pkg;
/
