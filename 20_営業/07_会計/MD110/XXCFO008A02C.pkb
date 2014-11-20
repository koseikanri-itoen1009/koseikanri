CREATE OR REPLACE PACKAGE BODY XXCFO008A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO008A02C(body)
 * Description      : ���������s�a������ƍ��f�[�^�쐬
 * MD.050           : ���������s�a������ƍ��f�[�^�쐬 MD050_CFO_008_A02
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_target_data        �Ώۃf�[�^�擾(A-2)
 *  output_std             �f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/02/12    1.0  SCSK �Γn ���a    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100)      := 'XXCFO008A02C';                       -- �p�b�P�[�W��
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';                             -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';                                -- ���O�o��
--
  -- �����t�H�[�}�b�g
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                         -- ���t�t�H�[�}�b�g�iYYYY/MM/DD�j
  cv_format_date_ym     CONSTANT VARCHAR2(10)  := 'YYYY-MM';                            -- ���t�t�H�[�}�b�g�iYYYY-MM�j
--
  cd_min_date           CONSTANT DATE          := TO_DATE('1900/01/01','YYYY/MM/DD');   -- �ŏ����t
  cd_max_date           CONSTANT DATE          := TO_DATE('9999/12/31','YYYY/MM/DD');   -- �ő���t
  cv_userenv_lang       CONSTANT VARCHAR2(10)  := USERENV('LANG');                      -- ����
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                                  -- �t���O�uY�v
  cv_sqlgl              CONSTANT VARCHAR2(20)  := 'SQLGL';                              -- GL�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo        CONSTANT VARCHAR2(20)  := 'XXCFO';                              -- XXCFO�A�v���P�[�V�����Z�k��
  cv_delimit            CONSTANT VARCHAR2(10)  := ',';                                  -- ��؂蕶��
  cv_enclosed           CONSTANT VARCHAR2(2)   := '"';                                  -- �P��͂ݕ���
  cv_code_001           CONSTANT VARCHAR2(3)   := '001';                                -- �R�[�h�u001�v
  cv_code_002           CONSTANT VARCHAR2(3)   := '002';                                -- �R�[�h�u002�v
  cv_code_003           CONSTANT VARCHAR2(3)   := '003';                                -- �R�[�h�u003�v
--
  -- �v���t�@�C����
  cv_set_of_books_id    CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';                    -- �v���t�@�C���F��v����ID
  cv_sys_cal_code       CONSTANT VARCHAR2(20) := 'XXCFO1_SYS_CAL_CODE';                 -- �v���t�@�C���FXXCFO:�V�X�e���ғ����J�����_�R�[�h
  --
  -- �Q�ƃ^�C�v
  cv_008a02c_cond_mst   CONSTANT VARCHAR2(30)  := 'XXCFO_008A02C_COND_MST';              -- ���������s�a������f�[�^����}�X�^
  cv_type_csv_header    CONSTANT VARCHAR2(100) := 'XXCFO1_CSV_HEADER';                   --�G�N�Z���o�͗p���o��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_prof_err       CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';                    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_no_data_err    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';                    -- �Ώۃf�[�^�擾�G���[���b�Z�[�W
  cv_msg_no_data_err2   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00032';                    -- �f�[�^�擾�G���[���b�Z�[�W
  cv_msg_sale_count     CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00042';                    -- ������z�������b�Z�[�W
  cv_msg_fieldwork_cnt  CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00043';                    -- ���������������b�Z�[�W
  cv_msg_deposit_cnt    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00044';                    -- �a�����z�������b�Z�[�W
  cv_msg_gl_appl_id     CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00045';                    -- GL�A�v���P�[�V����ID���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_prof           CONSTANT VARCHAR2(10) := 'PROF_NAME';
  cv_tkn_data           CONSTANT VARCHAR2(10) := 'DATA';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ����
  gn_sale_amount_cnt        NUMBER;                                        -- ������z����
  gn_fieldwork_amount_cnt   NUMBER;                                        -- ������������
  gn_deposit_amount_cnt     NUMBER;                                        -- �a�����z����
  --
  gn_set_of_books_id        NUMBER;                                        -- ��v����ID
  gv_sys_cal_code           bom_calendar_dates.calendar_code%TYPE;         -- �V�X�e���ғ����J�����_�[�R�[�h
  gn_gl_application_id      fnd_application.application_id%TYPE;           -- GL�A�v���P�[�V����ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �Ώۃf�[�^�擾�J�[�\��
  CURSOR get_target_data_cur(  iv_base_code   gl_code_combinations.segment2%TYPE
                              ,iv_period_name gl_period_statuses.period_name%TYPE
                            )
  IS
    SELECT
       iv_base_code                                     AS  base_code                    -- ���_�R�[�h
      ,TO_CHAR(bcd.calendar_date, cv_format_date_ymd )  AS  calendar_date                -- ���t
      ,sales_v.amount                                   AS  sale_amount                  -- ������z
      ,jissa.amount                                     AS  fieldwork_amount             -- ��������
      ,payment.amount*-1                                AS  deposit_amount               -- �a�����z
    FROM
       bom_calendar_dates   bcd                                  -- �ғ����J�����_�[
      ,gl_period_statuses   gps                                  -- ��v���ԃe�[�u��
      ,(
        SELECT /*+ USE_NL(gjh1 gjl1 gcc1) */
          gjl1.effective_date                                   AS effective_date
         ,SUM(NVL(gjl1.entered_dr,0) - NVL(gjl1.entered_cr,0))  AS amount
        FROM
          gl_je_headers        gjh1
         ,gl_je_lines          gjl1
         ,gl_code_combinations gcc1
         ,fnd_lookup_values    flv1
        WHERE
            gjh1.je_header_id        = gjl1.je_header_id
        AND gjh1.period_name         = gjl1.period_name
        AND gjl1.code_combination_id = gcc1.code_combination_id
        AND flv1.lookup_type         = cv_008a02c_cond_mst                  -- ���������s�a������f�[�^����}�X�^
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv1.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv1.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv1.enabled_flag        = cv_y
        AND flv1.language            = cv_userenv_lang
        AND flv1.lookup_code         = cv_code_001
        AND gjh1.set_of_books_id     = gn_set_of_books_id
        AND gjh1.period_name         = iv_period_name                       -- ��v���ԁiYYYY-MM�j
        AND gcc1.segment1            = flv1.attribute1                      -- ��ЃR�[�h
        AND gcc1.segment2            = iv_base_code                         -- ����R�[�h
        AND gcc1.segment3            = flv1.attribute2                      -- ����ȖځF11104�i�����j
        AND gjh1.je_source           IN (flv1.attribute3, flv1.attribute4)  -- �d��쐬�\�[�X�F4�i�̔����сj�AReceivables�i���|�Ǘ��j
        AND gjh1.actual_flag         = 'A'                       -- ����
        AND gjl1.status              = 'P'                       -- �]�L
        GROUP BY
          gjl1.effective_date
      ) sales_v                                                             -- ������z�C�����C���r���[
      ,(
        SELECT /*+ USE_NL(gjh2 gjl2 gcc2) */
         gjl2.effective_date                                   AS effective_date
        ,SUM(NVL(gjl2.entered_dr,0) - NVL(gjl2.entered_cr,0))   AS amount
        from
          gl_je_headers        gjh2
         ,gl_je_lines          gjl2
         ,gl_code_combinations gcc2
         ,fnd_lookup_values    flv2
        WHERE
            gjh2.je_header_id        = gjl2.je_header_id
        AND gjh2.period_name         = gjl2.period_name
        AND gjl2.code_combination_id = gcc2.code_combination_id
        AND flv2.lookup_type         = cv_008a02c_cond_mst                  -- ���������s�a������f�[�^����}�X�^
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv2.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv2.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv2.enabled_flag        = cv_y
        AND flv2.language            = cv_userenv_lang
        AND flv2.lookup_code         = cv_code_002
        AND gjh2.set_of_books_id     = gn_set_of_books_id
        AND gjh2.period_name         = iv_period_name            -- ��v���ԁiYYYY-MM�j
        AND gcc2.segment1            = flv2.attribute1           -- ��ЃR�[�h
        AND gcc2.segment2            = iv_base_code              -- ����R�[�h
        AND gcc2.segment3            = flv2.attribute2           -- ����ȖځF14917�i���a������������j
        AND gjh2.je_source           = flv2.attribute3           -- �d��쐬�\�[�X�F1�iGL������́j
        AND gjh2.actual_flag         = 'A'                       -- ����
        AND gjl2.status              = 'P'                       -- �]�L
        GROUP BY
          gjl2.effective_date
      ) jissa
      ,(
        SELECT /*+ USE_NL(gjh3 gjl3 gcc3) */
          gjl3.effective_date                                   AS effective_date
         ,SUM(NVL(gjl3.entered_dr,0) - NVL(gjl3.entered_cr,0))  AS amount
        FROM
          gl_je_headers        gjh3
         ,gl_je_lines          gjl3
         ,gl_code_combinations gcc3
         ,fnd_lookup_values    flv3
        WHERE
            gjh3.je_header_id        = gjl3.je_header_id
        AND gjh3.period_name         = gjl3.period_name
        AND gjl3.code_combination_id = gcc3.code_combination_id
        AND flv3.lookup_type         = cv_008a02c_cond_mst                  -- ���������s�a������f�[�^����}�X�^
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    >= NVL(flv3.start_date_active ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND TO_DATE(iv_period_name, cv_format_date_ym) 
                                    <= NVL(flv3.end_date_active   ,TO_DATE(iv_period_name, cv_format_date_ym))
        AND flv3.enabled_flag        = cv_y
        AND flv3.language            = cv_userenv_lang
        AND flv3.lookup_code         = cv_code_003
        AND gjh3.set_of_books_id     = gn_set_of_books_id
        AND gjh3.period_name         = iv_period_name            -- ��v���ԁiYYYY-MM�j
        AND gcc3.segment1            = flv3.attribute1           -- ��ЃR�[�h
        AND gcc3.segment2            = iv_base_code              -- ����R�[�h
        AND gcc3.segment3            = flv3.attribute2           -- ����ȖځF11104�i�����j
        AND gjh3.je_source           = flv3.attribute3           -- �d��쐬�\�[�X�F1�iGL������́j
        AND gjl3.description      LIKE flv3.attribute5           -- %�a������%
        AND gjh3.actual_flag         = 'A'                       -- ����
        AND gjl3.status              = 'P'                       -- �]�L
        GROUP BY
          gjl3.effective_date
      ) payment
    WHERE
        gps.start_date    <= bcd.calendar_date
    AND gps.end_date      >= bcd.calendar_date
    AND bcd.calendar_code  = gv_sys_cal_code
    AND gps.period_name    = iv_period_name                      -- ��v���ԁiYYYY-MM�j
    AND gps.application_id = gn_gl_application_id
    AND bcd.calendar_date  = sales_v.effective_date(+)
    AND bcd.calendar_date  = jissa.effective_date(+)
    AND bcd.calendar_date  = payment.effective_date(+)
    ORDER BY
    bcd.calendar_date
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Ώۃf�[�^�擾�J�[�\�����R�[�h�^
  TYPE g_target_data_ttype IS TABLE OF get_target_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_target_data_tab       g_target_data_ttype;
  
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code   IN VARCHAR2,     --   1.���_�R�[�h
    iv_period_name IN VARCHAR2,     --   2.�Ώ۔N��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    -- �R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,iv_conc_param1  => iv_period_name     -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_base_code       -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
--
    --==============================================================
    -- �v���t�@�C���I�v�V�����l�̎擾
    --==============================================================
    -- �v���t�@�C���F��v����ID
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    -- �擾�G���[��
    IF ( gn_set_of_books_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_prof_err      -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_set_of_books_id); -- �g�[�N���FSET_OF_BOOKS_ID
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �v���t�@�C���FXXCFO:�V�X�e���ғ����J�����_�R�[�h
    gv_sys_cal_code := FND_PROFILE.VALUE( cv_sys_cal_code );
    -- �擾�G���[��
    IF ( gv_sys_cal_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_prof_err      -- ���b�Z�[�W�FAPP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_sys_cal_code);    -- �g�[�N���FXXCFO1_SYS_CAL_CODE
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- GL�A�v���P�[�V����ID�̎擾
    --==============================================================
    BEGIN
      SELECT fa.application_id
      INTO   gn_gl_application_id
      FROM   fnd_application fa
      WHERE  fa.application_short_name = cv_sqlgl
      ;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                           ,iv_name         => cv_msg_no_data_err2  -- ���b�Z�[�W�FAPP-XXCFO1-00032
                                           ,iv_token_name1  => cv_tkn_data          -- �g�[�N���R�[�h
                                           ,iv_token_value1 => cv_msg_gl_appl_id);  -- �g�[�N���FAPP-XXCFO1-00045
      lv_errbuf := SQLERRM;
      --
      RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    iv_base_code   IN VARCHAR2,     --   1.���_�R�[�h
    iv_period_name IN VARCHAR2,     --   2.�Ώ۔N��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �Ώۃf�[�^�擾�J�[�\��
    OPEN  get_target_data_cur( iv_base_code
                              ,iv_period_name
                             );
    FETCH get_target_data_cur BULK COLLECT INTO gt_target_data_tab;
    CLOSE get_target_data_cur;
--
    --�Ώی����Z�b�g
    gn_target_cnt := gt_target_data_tab.COUNT;
    -- �O���x����
    IF ( gt_target_data_tab.COUNT = 0 ) THEN
      gn_warn_cnt := 1;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_msg_no_data_err   -- ���b�Z�[�W�FAPP-XXCFO1-00004
                                            ); 
      ov_errbuf  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF( get_target_data_cur%ISOPEN ) THEN
        CLOSE get_target_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_period_name                  IN     VARCHAR2,  -- 2.�Ώ۔N��
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR get_csv_header_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_userenv_lang
      AND     flv.lookup_type   = cv_type_csv_header
      AND     TO_DATE( iv_period_name, cv_format_date_ym ) 
                               >= NVL( flv.start_date_active, TO_DATE( iv_period_name, cv_format_date_ym ) )
      AND     TO_DATE( iv_period_name, cv_format_date_ym ) 
                               <= NVL( flv.end_date_active,   TO_DATE( iv_period_name, cv_format_date_ym ) )
      AND     flv.enabled_flag  = cv_y
      ORDER BY
              flv.lookup_code
      ;
    --���o��
    TYPE l_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_head_tab l_head_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  get_csv_header_cur;
    FETCH get_csv_header_cur BULK COLLECT INTO lt_head_tab;
    CLOSE get_csv_header_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_target_data_tab.COUNT LOOP
      --�f�[�^��ҏW
      lv_line_data :=     cv_enclosed || gt_target_data_tab(i).base_code           || cv_enclosed  -- ���_�R�[�h
         || cv_delimit || cv_enclosed || gt_target_data_tab(i).calendar_date       || cv_enclosed  -- ���t
         || cv_delimit                || gt_target_data_tab(i).sale_amount                         -- ������z
         || cv_delimit                || gt_target_data_tab(i).fieldwork_amount                    -- ��������
         || cv_delimit                || gt_target_data_tab(i).deposit_amount                      -- �a�����z
      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
      --�e�����̃J�E���g(0�~�ȊO�̏ꍇ�ɃJ�E���g)
      IF ( gt_target_data_tab(i).sale_amount      <> 0 )  THEN
        gn_sale_amount_cnt := gn_sale_amount_cnt + 1;                -- ������z����
      END IF;
      IF ( gt_target_data_tab(i).fieldwork_amount <> 0 )  THEN
        gn_fieldwork_amount_cnt := gn_fieldwork_amount_cnt + 1;      -- ������������
      END IF;
      IF ( gt_target_data_tab(i).deposit_amount   <> 0 )  THEN
        gn_deposit_amount_cnt := gn_deposit_amount_cnt + 1;          -- �a�����z����
      END IF;
--
    END LOOP data_output;
    --
    -- �O���x����
    IF ( gn_sale_amount_cnt + gn_fieldwork_amount_cnt + gn_deposit_amount_cnt = 0 ) THEN
      gn_warn_cnt := 1;
      ov_errmsg  := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- �A�v���P�[�V�����Z�k��
                                            ,iv_name         => cv_msg_no_data_err   -- ���b�Z�[�W�FAPP-XXCFO1-00004
                                            ); 
      ov_errbuf  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF( get_csv_header_cur%ISOPEN ) THEN
        CLOSE get_csv_header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code   IN VARCHAR2,     --   1.���_�R�[�h
    iv_period_name IN VARCHAR2,     --   2.�Ώ۔N��
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    gn_sale_amount_cnt      := 0;
    gn_fieldwork_amount_cnt := 0;
    gn_deposit_amount_cnt   := 0;
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
       iv_base_code       => iv_base_code           -- 1.���_�R�[�h
      ,iv_period_name     => iv_period_name         -- 2.�Ώ۔N��
      ,ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  �Ώۃf�[�^�擾 (A-2)
    -- =====================================================
    get_target_data(
       iv_base_code       => iv_base_code           -- 1.���_�R�[�h
      ,iv_period_name     => iv_period_name         -- 2.�Ώ۔N��
      ,ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- �f�[�^�o�� (A-3)
    -- ===============================
    output_data(
       iv_period_name     => iv_period_name         -- 2.�Ώ۔N��
      ,ov_errbuf          => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����̃J�E���g
      gn_error_cnt := 1;
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    --
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    iv_period_name IN VARCHAR2,      --   1.�Ώ۔N��
    iv_base_code   IN VARCHAR2       --   2.���_�R�[�h
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code    -- ���_�R�[�h
      ,iv_period_name  -- �Ώ۔N��
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --������z�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_sale_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_sale_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�������������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_fieldwork_cnt
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fieldwork_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�a�����z�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_deposit_cnt
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_deposit_amount_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFO008A02C;
/
