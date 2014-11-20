CREATE OR REPLACE PACKAGE BODY XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(body)
 * Description      : �̎�c���v�Z����
 * MD.050           : �̔��萔���i���̋@�j�̎x���\��z�i�����c���j���v�Z MD050_COK_014_A03
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  update_bm_bal_resv     �̎�c���ۗ��f�[�^�̍X�V(A-12)
 *  update_cond_bm_support �̎�c���o�^���ʃf�[�^�̍X�V�iA-11�j
 *  insert_bm_bal          �̎�c���v�Z���ʃf�[�^�̓o�^(A-10)
 *  delete_bm_bal_last     �̎�c���O�񏈗��f�[�^�̍폜(A-9)
 *  get_bm_calc_end_date   �̎�c���v�Z�I�����̎擾(A-8)
 *  get_cond_bm_support    �̎�c���v�Z�f�[�^�̎擾(A-7)
 *  set_bm_bal_resv        �̎�c���ۗ����̑ޔ�(A-6)
 *  update_bm_resv_init    �̎�c���ۗ����̏�����(A-5)
 *  get_bm_calc_start_date �̎�c���v�Z�J�n���̎擾(A-4)
 *  get_bm_bal_resv        �̎�c���ۗ��f�[�^�̎擾(A-3)
 *  delete_bm_period_out   �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   A.Yano           �V�K�쐬
 *  2009/02/17    1.1   T.Abe            [��QCOK_041] �̎�c���v�Z�f�[�^�̎擾������0���̏ꍇ�A����I������悤�ɏC��
 *  2009/03/25    1.2   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/05/28    1.3   M.Hiruta         [��QT1_1138] �̎�c���ۗ����̏������Ő������ۗ������������ł���悤�ύX
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOK014A03C';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;         -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;         -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id; -- PROGRAM_ID
  -- �Z�p���[�^
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)   := '.';
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_ccp           CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_app_name_cok           CONSTANT VARCHAR2(5)   := 'XXCOK';
  -- ���b�Z�[�W
  cv_msg_xxccp_90000        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_msg_xxccp_90001        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_msg_xxccp_90002        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_msg_xxccp_90004        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
  cv_msg_xxccp_90006        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N
  cv_msg_xxcok_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';         -- �v���t�@�C���擾�G���[
  cv_msg_xxcok_00022        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00022';         -- �R���J�����g���̓p�����[�^
  cv_msg_xxcok_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00027';         -- �c�Ɠ��擾�G���[
  cv_msg_xxcok_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';         -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok_00051        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00051';         -- �����ʔ̎�̋��o�^���ʃ��b�N�G���[
  cv_msg_xxcok_10296        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10296';         -- �̎�c���ێ����ԊO��񃍃b�N�G���[
  cv_msg_xxcok_10297        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10297';         -- �̎�c���ێ����ԊO���폜�G���[
  cv_msg_xxcok_10298        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10298';         -- �̎�c���O��ۗ���񃍃b�N�G���[
  cv_msg_xxcok_10299        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10299';         -- �̎�c���O��ۗ����X�V�G���[
  cv_msg_xxcok_10300        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10300';         -- �̎�c���v�Z���擾�G���[
  cv_msg_xxcok_10301        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10301';         -- �̎�c���O�񏈗���񃍃b�N�G���[
  cv_msg_xxcok_10302        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10302';         -- �̎�c���O�񏈗����폜�G���[
  cv_msg_xxcok_10303        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10303';         -- �̎�c���v�Z���ʓo�^�G���[
  cv_msg_xxcok_10305        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10305';         -- �����ʔ̎�̋��o�^���ʍX�V�G���[
  cv_msg_xxcok_10306        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10306';         -- �̎�c���ۗ���񃍃b�N�G���[
  cv_msg_xxcok_10307        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10307';         -- �̎�c���ۗ����X�V�G���[
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cv_msg_xxcok_10454        CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10454';         -- ���߁E�x�����擾�G���[
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �g�[�N��
  cv_tkn_count              CONSTANT VARCHAR2(10)  := 'COUNT';                    -- �������b�Z�[�W�p
  cv_tkn_profile_name       CONSTANT VARCHAR2(10)  := 'PROFILE';                  -- �v���t�@�C����
  cv_tkn_business_date      CONSTANT VARCHAR2(20)  := 'BUSINESS_DATE';            -- �Ɩ��������t
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cv_tkn_cust_code          CONSTANT VARCHAR2(10)  := 'CUST_CODE';                -- �ڋq�R�[�h
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �v���t�@�C����
  -- XXCOK:�����ʔ̎�̋��v�Z�������ԁiFrom�j
  cv_bm_support_period_from CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';
  -- XXCOK:�����ʔ̎�̋��v�Z�������ԁiTo�j
  cv_bm_support_period_to   CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SUPPORT_PERIOD_TO';
  -- XXCOK:�̎�̋��v�Z���ʕێ�����
  cv_sales_retention_period CONSTANT VARCHAR2(30)  := 'XXCOK1_SALES_RETENTION_PERIOD';
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- XXCOK:�x������_�f�t�H���g
  cv_default_term_name      CONSTANT VARCHAR2(30)  := 'XXCOK1_DEFAULT_TERM_NAME';
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �A�g�X�e�[�^�X
  cv_interface_status_0     CONSTANT VARCHAR2(1)   := '0';                        -- ������
  cv_interface_status_1     CONSTANT VARCHAR2(1)   := '1';                        -- ������
  -- �t���O
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                        -- �ۗ�
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                        -- �ۗ�����
  -- �����敪
  cn_proc_type              CONSTANT NUMBER        := 1;                          -- �O
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  cn_proc_type_after        CONSTANT NUMBER        := 2;                          -- ��
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �̎�c���e�[�u���o�^�f�[�^
  cn_payment_amt_tax        CONSTANT NUMBER        := 0;                          -- �x���z�i�ō��j
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �_��Ǘ����
  cv_status_1               CONSTANT VARCHAR2(1)   := '1';                        -- �m��
  -- �x�������p��ؕ���
  cv_underbar               CONSTANT VARCHAR2(1)   := '_';                        -- �A���_�[�o�[
  -- �x������_�x����_�_��Ǘ����o�l
  cv_term_this_month        CONSTANT VARCHAR2(2)   := '40';                       -- ����
  cv_term_next_month        CONSTANT VARCHAR2(2)   := '50';                       -- ����
  -- �x������_�x����_�_��Ǘ��ϊ���
  cv_term_this_month_concat CONSTANT VARCHAR2(2)   := '00';                       -- ����
  cv_term_next_month_concat CONSTANT VARCHAR2(2)   := '01';                       -- ����
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt               NUMBER   DEFAULT 0;     -- �Ώی���
  gn_normal_cnt               NUMBER   DEFAULT 0;     -- ���팏��
  gn_error_cnt                NUMBER   DEFAULT 0;     -- �G���[����
  gn_warn_cnt                 NUMBER   DEFAULT 0;     -- �X�L�b�v����
  gd_process_date             DATE     DEFAULT NULL;  -- �Ɩ��������t
  gd_bm_hold_period_date      DATE     DEFAULT NULL;  -- �̎�̋��ێ�������
  -- �v���t�@�C���l
  gn_bm_support_period_from   NUMBER   DEFAULT NULL;  -- �����ʔ̎�̋��v�Z�������ԁiFrom�j
  gn_bm_support_period_to     NUMBER   DEFAULT NULL;  -- �����ʔ̎�̋��v�Z�������ԁiTo�j
  gn_sales_retention_period   NUMBER   DEFAULT NULL;  -- �̎�̋��v�Z���ʕێ�����
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  gv_default_term_name        VARCHAR2(10) DEFAULT NULL;  -- �x������_�f�t�H���g
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- �̎�c���ۗ��f�[�^
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--  CURSOR g_bm_bal_resv_cur
  CURSOR g_bm_bal_resv_cur (
         iv_cust_code IN xxcok_backmargin_balance.cust_code%TYPE -- �ڋq�R�[�h
         )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  IS
    SELECT  xbb.base_code              AS base_code              -- ���_�R�[�h
           ,xbb.supplier_code          AS supplier_code          -- �d����R�[�h
           ,xbb.supplier_site_code     AS supplier_site_code     -- �d����T�C�g�R�[�h
           ,xbb.cust_code              AS cust_code              -- �ڋq�R�[�h
           ,xbb.closing_date           AS closing_date           -- ���ߓ�
           ,xbb.selling_amt_tax        AS selling_amt_tax        -- �̔����z�i�ō��j
           ,xbb.backmargin             AS backmargin             -- �̔��萔���i�Ŕ��j
           ,xbb.backmargin_tax         AS backmargin_tax         -- �̔��萔���i����Ŋz�j
           ,xbb.electric_amt           AS electric_amt           -- �d�C���i�Ŕ��j
           ,xbb.electric_amt_tax       AS electric_amt_tax       -- �d�C���i����Ŋz�j
           ,xbb.tax_code               AS tax_code               -- �ŋ��R�[�h
           ,xbb.expect_payment_date    AS expect_payment_date    -- �x���\���
           ,xbb.expect_payment_amt_tax AS expect_payment_amt_tax -- �x���\��z�i�ō��j
           ,xbb.payment_amt_tax        AS payment_amt_tax        -- �x���z�i�ō��j
           ,xbb.resv_flag              AS resv_flag              -- �ۗ��t���O
           ,xbb.return_flag            AS return_flag            -- �g�ݖ߂��t���O
           ,xbb.publication_date       AS publication_date       -- �ē���������
           ,xbb.fb_interface_status    AS fb_interface_status    -- �A�g�X�e�[�^�X�i�{�U�pFB�j
           ,xbb.fb_interface_date      AS fb_interface_date      -- �A�g���i�{�U�pFB�j
           ,xbb.edi_interface_status   AS edi_interface_status   -- �A�g�X�e�[�^�X�iEDI�x���ē����j
           ,xbb.edi_interface_date     AS edi_interface_date     -- �A�g���iEDI�x���ē����j
           ,xbb.gl_interface_status    AS gl_interface_status    -- �A�g�X�e�[�^�X�iGL�j
           ,xbb.gl_interface_date      AS gl_interface_date      -- �A�g���iGL�j
    FROM    xxcok_backmargin_balance  xbb
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--    WHERE  ( ( xbb.resv_flag   = cv_flag_y )
--           OR( xbb.return_flag = cv_flag_y ) )
    WHERE  xbb.cust_code = iv_cust_code
    AND    ( ( xbb.resv_flag   = cv_flag_y )
           OR( xbb.return_flag = cv_flag_y ) )
  ;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
  -- �̎�c���v�Z�f�[�^
  CURSOR g_cond_bm_cur
  IS
    SELECT xcbs.base_code                            AS base_code           -- ���_�R�[�h
          ,xcbs.supplier_code                        AS supplier_code       -- �d����R�[�h
          ,xcbs.supplier_site_code                   AS supplier_site_code  -- �d����T�C�g�R�[�h
          ,xcbs.delivery_cust_code                   AS delivery_cust_code  -- �ڋq�R�[�h(�[�i��)
          ,xcbs.closing_date                         AS closing_date        -- ���ߓ�
          ,xcbs.expect_payment_date                  AS expect_payment_date -- �x���\���
          ,xcbs.tax_code                             AS tax_code            -- �ŋ��R�[�h
          ,SUM( xcbs.selling_amt_tax )               AS selling_amt_tax     -- ������z�i�ō��j
          ,SUM( NVL( xcbs.cond_bm_amt_no_tax , 0 ) ) AS cond_bm_amt         -- �����ʎ萔���z�i�Ŕ��j
          ,SUM( NVL( xcbs.cond_tax_amt       , 0 ) ) AS cond_tax_amt        -- �����ʏ���Ŋz
          ,SUM( NVL( xcbs.electric_amt_no_tax, 0 ) ) AS electric_amt        -- �d�C��(�Ŕ�)
          ,SUM( NVL( xcbs.electric_tax_amt   , 0 ) ) AS electric_tax_amt    -- �d�C������Ŋz
    FROM   xxcok_cond_bm_support xcbs
    WHERE  xcbs.bm_interface_status = cv_interface_status_0
    GROUP BY xcbs.base_code
            ,xcbs.supplier_code
            ,xcbs.supplier_site_code
            ,xcbs.delivery_cust_code
            ,xcbs.closing_date
            ,xcbs.expect_payment_date
            ,xcbs.tax_code
  ;
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- �_��Ǘ��e�[�u�����擾���[�v
  CURSOR g_managements_cur
  IS
    SELECT xcm.install_account_number AS cust_code           -- �ݒu��ڋq�R�[�h
          ,xcm.close_day_code         AS close_day_code      -- ���ߓ�
          ,xcm.transfer_day_code      AS transfer_day_code   -- �x����
          ,xcm.transfer_month_code    AS transfer_month_code -- �x����
    FROM   xxcso_contract_managements xcm
          ,(
           SELECT MAX( xcm_2.contract_number ) AS contract_number -- �_�񏑔ԍ�
                 ,xcm_2.install_account_id     AS cust_id         -- �ݒu��ڋqID
           FROM   xxcso_contract_managements xcm_2 -- �_��Ǘ��e�[�u��
           WHERE  xcm_2.status = cv_status_1 -- �m���
           AND EXISTS (
                      SELECT 'X'
                      FROM   xxcok_backmargin_balance xbb
                            ,hz_cust_accounts         hca
                      WHERE  xbb.cust_code       = hca.account_number
                      AND    hca.cust_account_id = xcm_2.install_account_id
                      AND    ( ( xbb.resv_flag   = cv_flag_y )
                             OR( xbb.return_flag = cv_flag_y ) )
                      )
           GROUP BY
                  xcm_2.install_account_id
           ) xcm_max
    WHERE  xcm.contract_number    = xcm_max.contract_number
    AND    xcm.install_account_id = xcm_max.cust_id
    AND    xcm.status             = cv_status_1 -- �m���
  ;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  -- ===============================
  -- �O���[�o��TABLE�^
  -- ===============================
  -- �̎�c���ۗ����
  TYPE g_bm_bal_resv_ttype IS TABLE OF g_bm_bal_resv_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- �O���[�o��PL/SQL�\
  -- ===============================
  -- �̎�c���ۗ����
  g_bm_bal_resv_tab    g_bm_bal_resv_ttype;
  -- ===============================
  -- ��O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
--
  no_data_expt                EXCEPTION;    -- �f�[�^�擾��O
  operating_day_expt          EXCEPTION;    -- �c�Ɠ��擾��O
  lock_expt                   EXCEPTION;    -- ���b�N�擾��O
  status_warn_expt            EXCEPTION;    -- �x����O
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : update_bm_bal_resv
   * Description      : �̎�c���ۗ��f�[�^�̍X�V(A-12)
   ***********************************************************************************/
  PROCEDURE update_bm_bal_resv(
     ov_errbuf          OUT VARCHAR2        -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT VARCHAR2        -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'update_bm_bal_resv'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    ln_index                  NUMBER         DEFAULT 0;                    -- �C���f�b�N�X
    -- *** ���[�J���J�[�\�� ***
    -- �̎�c���e�[�u�����b�N�擾
    CURSOR l_bm_update_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.base_code           =  g_bm_bal_resv_tab( ln_index ).base_code
      AND    xbb.supplier_code       =  g_bm_bal_resv_tab( ln_index ).supplier_code
      AND    xbb.supplier_site_code  =  g_bm_bal_resv_tab( ln_index ).supplier_site_code
      AND    xbb.cust_code           =  g_bm_bal_resv_tab( ln_index ).cust_code
      AND    xbb.closing_date        =  g_bm_bal_resv_tab( ln_index ).closing_date
      AND    xbb.expect_payment_date =  g_bm_bal_resv_tab( ln_index ).expect_payment_date
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    <<update_loop>>
    FOR i IN g_bm_bal_resv_tab.FIRST .. g_bm_bal_resv_tab.LAST LOOP
      -- ===============================================
      -- �̎�c���e�[�u���̃��b�N�擾
      -- ===============================================
      OPEN  l_bm_update_lock_cur;
      CLOSE l_bm_update_lock_cur;
--
      BEGIN
        -- ===============================================
        -- �̎�c���ۗ��f�[�^�̍X�V
        -- ===============================================
        UPDATE xxcok_backmargin_balance
        SET    resv_flag              = g_bm_bal_resv_tab( ln_index ).resv_flag    -- �ۗ��t���O
              ,return_flag            = g_bm_bal_resv_tab( ln_index ).return_flag  -- �g�ݖ߂��t���O
              ,last_updated_by        = cn_last_updated_by
              ,last_update_date       = SYSDATE
              ,last_update_login      = cn_last_update_login
              ,request_id             = cn_request_id
              ,program_application_id = cn_program_application_id
              ,program_id             = cn_program_id
              ,program_update_date    = SYSDATE
        WHERE  base_code           =  g_bm_bal_resv_tab( ln_index ).base_code
        AND    supplier_code       =  g_bm_bal_resv_tab( ln_index ).supplier_code
        AND    supplier_site_code  =  g_bm_bal_resv_tab( ln_index ).supplier_site_code
        AND    cust_code           =  g_bm_bal_resv_tab( ln_index ).cust_code
        AND    closing_date        =  g_bm_bal_resv_tab( ln_index ).closing_date
        AND    expect_payment_date =  g_bm_bal_resv_tab( ln_index ).expect_payment_date
        ;
--
      EXCEPTION
        -- *** �̎�c���ۗ����X�V��O�n���h�� ***
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name_cok
                          ,iv_name         => cv_msg_xxcok_10307
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           FND_FILE.OUTPUT
                          ,lv_out_msg
                          ,0
                        );
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
          ov_retcode := cv_status_error;
      END;
      ln_index := ln_index + 1;
--
    END LOOP update_loop;
--
  EXCEPTION
    -- *** �̎�c���ۗ���񃍃b�N��O�n���h�� ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10306
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : update_cond_bm_support
   * Description      : �̎�c���o�^���ʃf�[�^�̍X�V�iA-11�j
   ***********************************************************************************/
  PROCEDURE update_cond_bm_support(
     ov_errbuf               OUT VARCHAR2                                       -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2                                       -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_base_code            IN  xxcok_cond_bm_support.base_code%TYPE           -- �̎�c���v�Z�f�[�^.���_�R�[�h
    ,it_supplier_code        IN  xxcok_cond_bm_support.supplier_code%TYPE       -- �̎�c���v�Z�f�[�^.�d����R�[�h
    ,it_supplier_site_code   IN  xxcok_cond_bm_support.supplier_site_code%TYPE  -- �̎�c���v�Z�f�[�^.�d����T�C�g�R�[�h
    ,it_delivery_cust_code   IN  xxcok_cond_bm_support.delivery_cust_code%TYPE  -- �̎�c���v�Z�f�[�^.�ڋq�R�[�h
    ,it_closing_date         IN  xxcok_cond_bm_support.closing_date%TYPE        -- �̎�c���v�Z�f�[�^.���ߓ�
    ,it_expect_payment_date  IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- �̎�c���ۗ��f�[�^.�x���\���
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'update_cond_bm_support'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- *** ���[�J���J�[�\�� ***
    -- �����ʔ̎�̋��e�[�u�����b�N�擾
    CURSOR l_cond_bm_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_cond_bm_support xcbs
      WHERE  xcbs.base_code            =  it_base_code
      AND    xcbs.supplier_code        =  it_supplier_code
      AND    xcbs.supplier_site_code   =  it_supplier_site_code
      AND    xcbs.delivery_cust_code   =  it_delivery_cust_code
      AND    xcbs.closing_date         =  it_closing_date
      AND    xcbs.expect_payment_date  =  it_expect_payment_date
      AND    xcbs.bm_interface_status  =  cv_interface_status_0
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �����ʔ̎�̋��e�[�u���̃��b�N���擾
    -- ===============================================
    OPEN  l_cond_bm_lock_cur;
    CLOSE l_cond_bm_lock_cur;
--
    BEGIN
      -- ===============================================
      -- �����ʔ̎�̋��e�[�u���̍X�V
      -- ===============================================
      UPDATE xxcok_cond_bm_support
      SET    bm_interface_status    = cv_interface_status_1    -- �A�g�X�e�[�^�X�i�̎�c���j
            ,bm_interface_date      = gd_process_date          -- �A�g���i�̎�c���j
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = SYSDATE
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = SYSDATE
      WHERE  base_code            =  it_base_code
      AND    supplier_code        =  it_supplier_code
      AND    supplier_site_code   =  it_supplier_site_code
      AND    delivery_cust_code   =  it_delivery_cust_code
      AND    closing_date         =  it_closing_date
      AND    expect_payment_date  =  it_expect_payment_date
      AND    bm_interface_status  =  cv_interface_status_0
      ;
--
    EXCEPTION
      -- *** �����ʔ̎�̋��o�^���ʍX�V��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10305
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** �����ʔ̎�̋��o�^���ʃ��b�N��O�n���h�� ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : insert_bm_bal
   * Description      : �̎�c���v�Z���ʃf�[�^�̓o�^(A-10)
   ***********************************************************************************/
  PROCEDURE insert_bm_bal(
     ov_errbuf          OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT VARCHAR2                   -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,i_cond_bm_rec      IN  g_cond_bm_cur%ROWTYPE      -- �̎�c���v�Z�f�[�^
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(15) := 'insert_bm_bal'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;              -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��̖߂�l
    lt_expect_payment_amt_tax xxcok_backmargin_balance.expect_payment_amt_tax%TYPE DEFAULT 0;  -- �x���\��z
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- �x���\��z�i�ō��j
    lt_expect_payment_amt_tax := i_cond_bm_rec.cond_bm_amt  + i_cond_bm_rec.cond_tax_amt +
                                 i_cond_bm_rec.electric_amt + i_cond_bm_rec.electric_tax_amt;
    BEGIN
      -- ===============================================
      -- �̎�c���v�Z���ʃf�[�^�̓o�^
      -- ===============================================
      INSERT INTO xxcok_backmargin_balance(
         bm_balance_id                -- �̎�c��ID
        ,base_code                    -- ���_�R�[�h
        ,supplier_code                -- �d����R�[�h
        ,supplier_site_code           -- �d����T�C�g�R�[�h
        ,cust_code                    -- �ڋq�R�[�h
        ,closing_date                 -- ���ߓ�
        ,selling_amt_tax              -- �̔����z�i�ō��j
        ,backmargin                   -- �̔��萔��
        ,backmargin_tax               -- �̔��萔���i����Ŋz�j
        ,electric_amt                 -- �d�C��
        ,electric_amt_tax             -- �d�C���i����Ŋz�j
        ,tax_code                     -- �ŋ��R�[�h
        ,expect_payment_date          -- �x���\���
        ,expect_payment_amt_tax       -- �x���\��z�i�ō��j
        ,payment_amt_tax              -- �x���z�i�ō��j
        ,resv_flag                    -- �ۗ��t���O
        ,return_flag                  -- �g�ݖ߂��t���O
        ,publication_date             -- �ē���������
        ,fb_interface_status          -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        ,fb_interface_date            -- �A�g���i�{�U�pFB�j
        ,edi_interface_status         -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        ,edi_interface_date           -- �A�g���iEDI�x���ē����j
        ,gl_interface_status          -- �A�g�X�e�[�^�X�iGL�j
        ,gl_interface_date            -- �A�g���iGL�j
        -- WHO�J����
        ,created_by                   -- �쐬��
        ,creation_date                -- �쐬��
        ,last_updated_by              -- �ŏI�X�V��
        ,last_update_date             -- �ŏI�X�V��
        ,last_update_login            -- �ŏI�X�V���O�C��
        ,request_id                   -- �v��ID
        ,program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                   -- �R���J�����g�E�v���O����ID
        ,program_update_date          -- �v���O�����X�V��
      ) VALUES (
         xxcok_backmargin_balance_s01.NEXTVAL   -- �̎�c��ID
        ,i_cond_bm_rec.base_code                -- ���_�R�[�h
        ,i_cond_bm_rec.supplier_code            -- �d����R�[�h
        ,i_cond_bm_rec.supplier_site_code       -- �d����T�C�g�R�[�h
        ,i_cond_bm_rec.delivery_cust_code       -- �ڋq�R�[�h
        ,i_cond_bm_rec.closing_date             -- ���ߓ�
        ,i_cond_bm_rec.selling_amt_tax          -- �̔����z�i�ō��j
        ,i_cond_bm_rec.cond_bm_amt              -- �̔��萔��
        ,i_cond_bm_rec.cond_tax_amt             -- �̔��萔���i����Ŋz�j
        ,i_cond_bm_rec.electric_amt             -- �d�C��
        ,i_cond_bm_rec.electric_tax_amt         -- �d�C���i����Ŋz�j
        ,i_cond_bm_rec.tax_code                 -- �ŋ��R�[�h
        ,i_cond_bm_rec.expect_payment_date      -- �x���\���
        ,lt_expect_payment_amt_tax              -- �x���\��z�i�ō��j
        ,cn_payment_amt_tax                     -- �x���z�i�ō��j
        ,NULL                                   -- �ۗ��t���O
        ,NULL                                   -- �g�ݖ߂��t���O
        ,NULL                                   -- �ē���������
        ,cv_interface_status_0                  -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        ,NULL                                   -- �A�g���i�{�U�pFB�j
        ,cv_interface_status_0                  -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        ,NULL                                   -- �A�g���iEDI�x���ē����j
        ,cv_interface_status_0                  -- �A�g�X�e�[�^�X�iGL�j
        ,NULL                                   -- �A�g���iGL�j
        -- WHO�J����
        ,cn_created_by                          -- �쐬��
        ,SYSDATE                                -- �쐬��
        ,cn_last_updated_by                     -- �ŏI�X�V��
        ,SYSDATE                                -- �ŏI�X�V��
        ,cn_last_update_login                   -- �ŏI�X�V���O�C��
        ,cn_request_id                          -- �v��ID
        ,cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                          -- �R���J�����g�E�v���O����ID
        ,SYSDATE                                -- �v���O�����X�V��
      );
--
    EXCEPTION
      -- *** �̎�c���v�Z���ʓo�^��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10303
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_bm_bal;
--
  /**********************************************************************************
   * Procedure Name   : delete_bm_bal_last
   * Description      : �̎�c���O�񏈗��f�[�^�̍폜(A-9)
   ***********************************************************************************/
  PROCEDURE delete_bm_bal_last(
     ov_errbuf              OUT VARCHAR2                                       -- �G���[�E���b�Z�[�W
    ,ov_retcode             OUT VARCHAR2                                       -- ���^�[���E�R�[�h
    ,ov_errmsg              OUT VARCHAR2                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_base_code           IN  xxcok_cond_bm_support.base_code%TYPE           -- ���_�R�[�h
    ,it_supplier_code       IN  xxcok_cond_bm_support.supplier_code%TYPE       -- �d����R�[�h
    ,it_supplier_site_code  IN  xxcok_cond_bm_support.supplier_site_code%TYPE  -- �d����T�C�g�R�[�h
    ,it_delivery_cust_code  IN  xxcok_cond_bm_support.delivery_cust_code%TYPE  -- �ڋq�R�[�h
    ,it_closing_date        IN  xxcok_cond_bm_support.closing_date%TYPE        -- ���ߓ�
    ,it_expect_payment_date IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- �x���\���
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'delete_bm_bal_last'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- *** ���[�J���J�[�\�� ***
    -- �̎�c���e�[�u�����b�N�擾
    CURSOR l_delete_bm_last_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.base_code           =  it_base_code
      AND    xbb.supplier_code       =  it_supplier_code
      AND    xbb.supplier_site_code  =  it_supplier_site_code
      AND    xbb.cust_code           =  it_delivery_cust_code
      AND    xbb.closing_date        =  it_closing_date
      AND    xbb.expect_payment_date =  it_expect_payment_date
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u���̃��b�N�擾
    -- ===============================================
    OPEN  l_delete_bm_last_lock_cur;
    CLOSE l_delete_bm_last_lock_cur;
--
    BEGIN
      -- ===============================================
      -- �̎�c���O�񏈗��f�[�^�̍폜
      -- ===============================================
      DELETE FROM xxcok_backmargin_balance
      WHERE  base_code           =  it_base_code
      AND    supplier_code       =  it_supplier_code
      AND    supplier_site_code  =  it_supplier_site_code
      AND    cust_code           =  it_delivery_cust_code
      AND    closing_date        =  it_closing_date
      AND    expect_payment_date =  it_expect_payment_date
      ;
--
    EXCEPTION
      -- *** �̎�c���O�񏈗����폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10302
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** �̎�c���O�񏈗���񃍃b�N��O�n���h�� ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10301
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END delete_bm_bal_last;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_calc_end_date
   * Description      : �̎�c���v�Z�I�����̎擾(A-8)
   ***********************************************************************************/
  PROCEDURE get_bm_calc_end_date(
     ov_errbuf          OUT VARCHAR2                                   -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT VARCHAR2                                   -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_closing_date    IN  xxcok_cond_bm_support.closing_date%TYPE    -- �̎�c���v�Z�f�[�^.���ߓ�
    ,od_calc_end_date   OUT DATE                                       -- �̎�c���v�Z�I�����i�c�Ɠ��j
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_bm_calc_end_date'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    ld_operating_day          DATE           DEFAULT NULL;                 -- �̎�c���v�Z�I�����i�c�Ɠ��j
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���v�Z�I�����̎擾
    -- ===============================================
    ld_operating_day := xxcok_common_pkg.get_operating_day_f(
                           it_closing_date           -- ������
                          ,gn_bm_support_period_to   -- ����
                          ,cn_proc_type              -- �����敪
                        );
    IF( ld_operating_day IS NULL ) THEN
      RAISE operating_day_expt;
    END IF;
    -- ===============================================
    -- OUT�p�����[�^�ݒ�
    -- ===============================================
    od_calc_end_date := ld_operating_day;   -- �̎�c���v�Z�I�����i�c�Ɠ��j
--
  EXCEPTION
    -- *** �c�Ɠ��擾��O�n���h�� ***
    WHEN operating_day_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00027
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_calc_end_date;
--
  /**********************************************************************************
   * Procedure Name   : get_cond_bm_support
   * Description      : �̎�c���v�Z�f�[�^�̎擾(A-7)
   ***********************************************************************************/
  PROCEDURE get_cond_bm_support(
     ov_errbuf            OUT VARCHAR2     -- �G���[�E���b�Z�[�W
    ,ov_retcode           OUT VARCHAR2     -- ���^�[���E�R�[�h
    ,ov_errmsg            OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_cond_bm_support'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    ld_calc_end_date          DATE           DEFAULT NULL;                 -- �̎�c���v�Z�I����
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���v�Z�f�[�^�̎擾
    -- ===============================================
    <<main_loop>>
    FOR l_cond_bm_rec IN g_cond_bm_cur LOOP
--
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================================
      -- �̎�c���v�Z�I�����̎擾(A-8)
      -- ===============================================
      get_bm_calc_end_date(
         ov_errbuf               =>   lv_errbuf                      -- �G���[�E���b�Z�[�W
        ,ov_retcode              =>   lv_retcode                     -- ���^�[���E�R�[�h
        ,ov_errmsg               =>   lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,it_closing_date         =>   l_cond_bm_rec.closing_date     -- �̎�c���v�Z�f�[�^.���ߓ�
        ,od_calc_end_date        =>   ld_calc_end_date               -- �̎�c���v�Z�I�����i�c�Ɠ��j
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �̎�c���O�񏈗��f�[�^�̍폜(A-9)
      -- ===============================================
      delete_bm_bal_last(
         ov_errbuf                =>   lv_errbuf                         -- �G���[�E���b�Z�[�W
        ,ov_retcode               =>   lv_retcode                        -- ���^�[���E�R�[�h
        ,ov_errmsg                =>   lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,it_base_code             =>   l_cond_bm_rec.base_code           -- ���_�R�[�h
        ,it_supplier_code         =>   l_cond_bm_rec.supplier_code       -- �d����R�[�h
        ,it_supplier_site_code    =>   l_cond_bm_rec.supplier_site_code  -- �d����T�C�g�R�[�h
        ,it_delivery_cust_code    =>   l_cond_bm_rec.delivery_cust_code  -- �ڋq�R�[�h
        ,it_closing_date          =>   l_cond_bm_rec.closing_date        -- ���ߓ�
        ,it_expect_payment_date   =>   l_cond_bm_rec.expect_payment_date -- �x���\���
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �̎�c���v�Z���ʃf�[�^�̓o�^(A-10)
      -- ===============================================
      insert_bm_bal(
         ov_errbuf                =>   lv_errbuf               -- �G���[�E���b�Z�[�W
        ,ov_retcode               =>   lv_retcode              -- ���^�[���E�R�[�h
        ,ov_errmsg                =>   lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,i_cond_bm_rec            =>   l_cond_bm_rec           -- �̎�c���v�Z�f�[�^
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���팏��
      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- ===============================================
      -- �Ɩ��������t�Ɣ̎�c���v�Z�I��������v����ꍇ
      -- ===============================================
      IF( gd_process_date = ld_calc_end_date ) THEN
        -- ===============================================
        -- �̎�c���o�^���ʃf�[�^�̍X�V(A-11)
        -- ===============================================
        update_cond_bm_support(
           ov_errbuf                =>   lv_errbuf                         -- �G���[�E���b�Z�[�W
          ,ov_retcode               =>   lv_retcode                        -- ���^�[���E�R�[�h
          ,ov_errmsg                =>   lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_base_code             =>   l_cond_bm_rec.base_code           -- ���_�R�[�h
          ,it_supplier_code         =>   l_cond_bm_rec.supplier_code       -- �d����R�[�h
          ,it_supplier_site_code    =>   l_cond_bm_rec.supplier_site_code  -- �d����T�C�g�R�[�h
          ,it_delivery_cust_code    =>   l_cond_bm_rec.delivery_cust_code  -- �ڋq�R�[�h
          ,it_closing_date          =>   l_cond_bm_rec.closing_date        -- ���ߓ�
          ,it_expect_payment_date   =>   l_cond_bm_rec.expect_payment_date -- �x���\���
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP main_loop;
    -- ===============================================
    -- �Ώی�����0���̏ꍇ
    -- ===============================================
    IF( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
  EXCEPTION
    WHEN no_data_expt THEN
      -- *** �̎�c���v�Z���擾��O�n���h�� ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10300
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_warn;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_cond_bm_support;
--
  /**********************************************************************************
   * Procedure Name   : set_bm_bal_resv
   * Description      : �̎�c���ۗ����̑ޔ�(A-6)
   ***********************************************************************************/
  PROCEDURE set_bm_bal_resv(
     ov_errbuf            OUT VARCHAR2                   -- �G���[�E���b�Z�[�W
    ,ov_retcode           OUT VARCHAR2                   -- ���^�[���E�R�[�h
    ,ov_errmsg            OUT VARCHAR2                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,i_bm_bal_resv_rec    IN  g_bm_bal_resv_cur%ROWTYPE  -- �̎�c���ۗ��f�[�^
    ,in_index             IN  NUMBER                     -- �C���f�b�N�X
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'set_bm_bal_resv'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���ۗ����̑ޔ�
    -- ===============================================
    g_bm_bal_resv_tab( in_index ) := i_bm_bal_resv_rec;
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END set_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : update_bm_resv_init
   * Description      : �̎�c���ۗ����̏������iA-5�j
   ***********************************************************************************/
  PROCEDURE update_bm_resv_init(
     ov_errbuf              OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode             OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg              OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    ,it_cust_code           IN  xxcok_backmargin_balance.cust_code%TYPE           -- �̎�c���ۗ�.�ڋq�R�[�h
--    ,it_base_code           IN  xxcok_backmargin_balance.base_code%TYPE           -- �̎�c���ۗ�.���_�R�[�h
--    ,it_supplier_code       IN  xxcok_backmargin_balance.supplier_code%TYPE       -- �̎�c���ۗ�.�d����R�[�h
--    ,it_supplier_site_code  IN  xxcok_backmargin_balance.supplier_site_code%TYPE  -- �̎�c���ۗ�.�d����T�C�g�R�[�h
--    ,it_expect_payment_date IN  xxcok_backmargin_balance.expect_payment_date%TYPE -- �̎�c���ۗ�.�x���\���
--    ,it_resv_flag           IN  xxcok_backmargin_balance.resv_flag%TYPE           -- �̎�c���ۗ�.�ۗ��t���O
--    ,it_return_flag         IN  xxcok_backmargin_balance.return_flag%TYPE         -- �̎�c���ۗ�.�g�ݖ߂��t���O
--    ,id_calc_start_date     IN  DATE                                              -- �̎�c���v�Z�J�n���i�c�Ɠ��j
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'update_bm_resv_init'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- *** ���[�J���J�[�\�� ***
    -- �̎�c���e�[�u�����b�N�擾
    CURSOR l_bm_init_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--      WHERE  xbb.base_code            =  it_base_code
--      AND    xbb.supplier_code        =  it_supplier_code
--      AND    xbb.supplier_site_code   =  it_supplier_site_code
--      AND    xbb.cust_code            =  it_cust_code
--      AND    xbb.closing_date         <  id_calc_start_date
--      AND    xbb.expect_payment_date  =  it_expect_payment_date
--      AND    ( ( xbb.resv_flag        =  it_resv_flag   )
--             OR( xbb.return_flag      =  it_return_flag ) )
      WHERE  xbb.cust_code    = it_cust_code
      AND    ( ( xbb.resv_flag   = cv_flag_y )
             OR( xbb.return_flag = cv_flag_y ) )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u���̃��b�N���擾
    -- ===============================================
    OPEN  l_bm_init_lock_cur;
    CLOSE l_bm_init_lock_cur;
--
    BEGIN
      -- ===============================================
      -- �̎�c���e�[�u���̍X�V�i�������j
      -- ===============================================
      UPDATE xxcok_backmargin_balance
      SET    resv_flag              = NULL        -- �ۗ��t���O
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = SYSDATE
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = SYSDATE
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--      WHERE  base_code            =  it_base_code
--      AND    supplier_code        =  it_supplier_code
--      AND    supplier_site_code   =  it_supplier_site_code
--      AND    cust_code            =  it_cust_code
--      AND    closing_date         <  id_calc_start_date
--      AND    expect_payment_date  =  it_expect_payment_date
--      AND    ( ( resv_flag        =  it_resv_flag   )
--             OR( return_flag      =  it_return_flag ) )
      WHERE  cust_code            =  it_cust_code
      AND    ( ( resv_flag   = cv_flag_y )
             OR( return_flag = cv_flag_y ) )
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
      ;
--
    EXCEPTION
      -- *** �̎�c���O��ۗ����X�V��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10299
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** �̎�c���O��ۗ���񃍃b�N��O�n���h�� ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10298
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_bm_resv_init;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_calc_start_date
   * Description      : �̎�c���v�Z�J�n���̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_bm_calc_start_date(
     ov_errbuf          OUT VARCHAR2                                   -- �G���[�E���b�Z�[�W
    ,ov_retcode         OUT VARCHAR2                                   -- ���^�[���E�R�[�h
    ,ov_errmsg          OUT VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_closing_date    IN  xxcok_backmargin_balance.closing_date%TYPE -- �̎�c���ۗ��f�[�^.���ߓ�
    ,od_calc_start_date OUT DATE                                       -- �̎�c���v�Z�J�n���i�c�Ɠ��j
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'get_bm_calc_start_date'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    ld_operating_day          DATE           DEFAULT NULL;                 -- �̎�c���v�Z�J�n���i�c�Ɠ��j
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���v�Z�J�n���̎擾
    -- ===============================================
    ld_operating_day := xxcok_common_pkg.get_operating_day_f(
                           it_closing_date              -- ������
                          ,gn_bm_support_period_from    -- ����
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--                          ,cn_proc_type                 -- �����敪
                          ,cn_proc_type_after           -- �����敪
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
                        );
    IF( ld_operating_day IS NULL ) THEN
      RAISE operating_day_expt;
    END IF;
    -- ===============================================
    -- OUT�p�����[�^�ݒ�
    -- ===============================================
    od_calc_start_date := ld_operating_day;   -- �̎�c���v�Z�J�n���i�c�Ɠ��j
--
  EXCEPTION
    -- *** �c�Ɠ��擾��O�n���h�� ***
    WHEN operating_day_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00027
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_calc_start_date;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_bal_resv
   * Description      : �̎�c���ۗ��f�[�^�̎擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_bal_resv(
     ov_errbuf             OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode            OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg             OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,ov_resv_update_flag   OUT VARCHAR2      -- �̎�c���ۗ����̏������σt���O
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(20) := 'get_bm_bal_resv';  -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    ld_calc_start_date        DATE           DEFAULT NULL;                 -- �̎�c���v�Z�J�n���i�c�Ɠ��j
    ln_index                  NUMBER         DEFAULT 0;                    -- �C���f�b�N�X
    lv_resv_update_flag       VARCHAR2(1)    DEFAULT cv_flag_y;            -- �̎�c���ۗ��f�[�^�X�V�t���O
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    lv_pay_cond               VARCHAR2(10)   DEFAULT NULL;                 -- �x������
    lv_term_month             VARCHAR2(2)    DEFAULT NULL;                 -- �x������_�x����
    ld_close_date             DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_pay_date               DATE           DEFAULT NULL;                 -- �x�����i�擾���邾���Ŗ��g�p�j
    -- *** ���[�J����O ***
    close_date_err_expt       EXCEPTION;                                   -- ���߁E�x�����擾�擾�G���[
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--    -- ===============================================
--    -- �̎�c���ۗ��f�[�^�̎擾
--    -- ===============================================
--    <<bm_bal_resv_loop>>
--    FOR l_bm_bal_resv_rec IN g_bm_bal_resv_cur LOOP
--      -- ===============================================
--      -- �̎�c���v�Z�J�n���̎擾�iA-4�j
--      -- ===============================================
--      get_bm_calc_start_date(
--         ov_errbuf          =>   lv_errbuf                      -- �G���[�E���b�Z�[�W
--        ,ov_retcode         =>   lv_retcode                     -- ���^�[���E�R�[�h
--        ,ov_errmsg          =>   lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
--        ,it_closing_date    =>   l_bm_bal_resv_rec.closing_date -- �̎�c���ۗ��f�[�^.���ߓ�
--        ,od_calc_start_date =>   ld_calc_start_date             -- �̎�c���v�Z�J�n���i�c�Ɠ��j
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
----
--      -- ===============================================
--      -- �Ɩ��������t�Ɣ̎�c���v�Z�J�n������v�����ꍇ
--      -- ===============================================
--      IF( gd_process_date = ld_calc_start_date ) THEN
--        -- ===============================================
--        -- �̎�c���ۗ����̏������iA-5�j
--        -- ===============================================
--        update_bm_resv_init(
--           ov_errbuf                =>   lv_errbuf                             -- �G���[�E���b�Z�[�W
--          ,ov_retcode               =>   lv_retcode                            -- ���^�[���E�R�[�h
--          ,ov_errmsg                =>   lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
--          ,it_base_code             =>   l_bm_bal_resv_rec.base_code           -- �̎�c���ۗ��f�[�^.���_�R�[�h
--          ,it_supplier_code         =>   l_bm_bal_resv_rec.supplier_code       -- �̎�c���ۗ��f�[�^.�d����R�[�h
--          ,it_supplier_site_code    =>   l_bm_bal_resv_rec.supplier_site_code  -- �̎�c���ۗ��f�[�^.�d����T�C�g�R�[�h
--          ,it_cust_code             =>   l_bm_bal_resv_rec.cust_code           -- �̎�c���ۗ��f�[�^.�ڋq�R�[�h
--          ,it_expect_payment_date   =>   l_bm_bal_resv_rec.expect_payment_date -- �̎�c���ۗ��f�[�^.�x���\���
--          ,it_resv_flag             =>   l_bm_bal_resv_rec.resv_flag           -- �̎�c���ۗ��f�[�^.�ۗ��t���O
--          ,it_return_flag           =>   l_bm_bal_resv_rec.return_flag         -- �̎�c���ۗ��f�[�^.�g�ݖ߂��t���O
--          ,id_calc_start_date       =>   ld_calc_start_date                    -- �̎�c���v�Z�J�n���i�c�Ɠ��j
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- ===============================================
--        -- �̎�c���ۗ����̏������������ꍇ
--        -- ===============================================
--        lv_resv_update_flag := cv_flag_n;
----
--      -- ===============================================
--      -- �Ɩ��������t�Ɣ̎�c���v�Z�J�n������v���Ȃ��ꍇ
--      -- ===============================================
--      ELSE
--        -- ===============================================
--        -- �̎�c���ۗ����̑ޔ��iA-6�j
--        -- ===============================================
--        set_bm_bal_resv(
--           ov_errbuf                =>   lv_errbuf             -- �G���[�E���b�Z�[�W
--          ,ov_retcode               =>   lv_retcode            -- ���^�[���E�R�[�h
--          ,ov_errmsg                =>   lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
--          ,i_bm_bal_resv_rec        =>   l_bm_bal_resv_rec     -- �̎�c���ۗ��f�[�^
--          ,in_index                 =>   ln_index              -- �C���f�b�N�X
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        ln_index := ln_index + 1;
--      END IF;
----
--    END LOOP bm_bal_resv_loop;
--
    -- ===============================================
    -- �_��Ǘ��e�[�u�����̎擾
    -- ===============================================
    <<managements_loop>>
    FOR l_managements_rec IN g_managements_cur LOOP
      -- ===============================================
      -- �x�������`�F�b�N
      -- ===============================================
      -- �_��Ǘ��e�[�u����񂩂�擾�����x�������u���ߓ��v�u�x�����v�u�x�����v�̂����ꂩ��NULL�ł���ꍇ�A
      -- ���ߓ��擾���Ƀf�t�H���g�l���g�p����B
      IF ( ( l_managements_rec.close_day_code      IS NULL ) OR
           ( l_managements_rec.transfer_day_code   IS NULL ) OR
           ( l_managements_rec.transfer_month_code IS NULL ) )
      THEN
        lv_pay_cond := gv_default_term_name;
      ELSE
        -- �擾�����x������ϊ�����B
        IF ( l_managements_rec.transfer_month_code = cv_term_this_month ) THEN
          lv_term_month := cv_term_this_month_concat; -- ����
        ELSE
          lv_term_month := cv_term_next_month_concat; -- ����
        END IF;
--
        lv_pay_cond := l_managements_rec.close_day_code      || cv_underbar ||
                       l_managements_rec.transfer_day_code   || cv_underbar ||
                       lv_term_month;
      END IF;
      -- ===============================================
      -- ���ߓ��擾
      -- ===============================================
      xxcok_common_pkg.get_close_date_p(
         ov_errbuf     => lv_errbuf                                 -- �G���[���b�Z�[�W
        ,ov_retcode    => lv_retcode                                -- ���^�[���E�R�[�h
        ,ov_errmsg     => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W
        ,id_proc_date  => gd_process_date - gn_bm_support_period_to -- ������
        ,iv_pay_cond   => lv_pay_cond                               -- �x������
        ,od_close_date => ld_close_date                             -- ���ߓ�
        ,od_pay_date   => ld_pay_date                               -- �x����
      );
      IF( lv_retcode = cv_status_error ) THEN
        -- ���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10454
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => l_managements_rec.cust_code
                      );
        RAISE close_date_err_expt;
      END IF;
--
      -- ===============================================
      -- �̎�c���v�Z�J�n���̎擾�iA-4�j
      -- ===============================================
      get_bm_calc_start_date(
         ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,it_closing_date    => ld_close_date      -- �̎�c���ۗ��f�[�^.���ߓ�
        ,od_calc_start_date => ld_calc_start_date -- �̎�c���v�Z�J�n���i�c�Ɠ��j
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �Ɩ��������t�Ɣ̎�c���v�Z�J�n������v�����ꍇ
      -- ===============================================
      IF( gd_process_date = ld_calc_start_date ) THEN
        -- ===============================================
        -- �̎�c���ۗ����̏������iA-5�j
        -- ===============================================
        update_bm_resv_init(
           ov_errbuf          => lv_errbuf                   -- �G���[�E���b�Z�[�W
          ,ov_retcode         => lv_retcode                  -- ���^�[���E�R�[�h
          ,ov_errmsg          => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,it_cust_code       => l_managements_rec.cust_code -- �_��Ǘ��e�[�u�����.�ڋq�R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================================
        -- �̎�c���ۗ����̏������������ꍇ
        -- ===============================================
        lv_resv_update_flag := cv_flag_n;
--
      -- ===============================================
      -- �Ɩ��������t�Ɣ̎�c���v�Z�J�n������v���Ȃ��ꍇ
      -- ===============================================
      ELSE
        -- ===============================================
        -- �̎�c���ۗ����̑ޔ��iA-6�j
        -- ===============================================
        <<bm_bal_resv_loop>>
        FOR l_bm_bal_resv_rec IN g_bm_bal_resv_cur (
                                    iv_cust_code => l_managements_rec.cust_code -- �ڋq�R�[�h
                                 )
        LOOP
          set_bm_bal_resv(
             ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W
            ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h
            ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
            ,i_bm_bal_resv_rec  => l_bm_bal_resv_rec     -- �̎�c���ۗ��f�[�^
            ,in_index           => ln_index              -- �C���f�b�N�X
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          ln_index := ln_index + 1;
        END LOOP bm_bal_resv_loop;
      END IF;
    END LOOP managements_loop;
--
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- ===============================================
    -- OUT�p�����[�^�ݒ�
    -- ===============================================
    ov_resv_update_flag := lv_resv_update_flag;
--
  EXCEPTION
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- *** ���߁E�x�����擾�擾��O�n���h�� ***
    WHEN close_date_err_expt THEN
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT -- �o�͋敪
                      ,lv_out_msg      -- ���b�Z�[�W
                      ,0               -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_bm_bal_resv;
--
  /**********************************************************************************
   * Procedure Name   : delete_bm_period_out
   * Description      : �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
   ***********************************************************************************/
  PROCEDURE delete_bm_period_out(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(25) := 'delete_bm_period_out'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- *** ���[�J���J�[�\�� ***
    -- �̎�c���e�[�u�����b�N�擾
    CURSOR l_bm_delete_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance xbb
      WHERE  xbb.closing_date         <  gd_bm_hold_period_date
      AND    xbb.publication_date     IS NOT NULL
      AND    xbb.fb_interface_status  <> cv_interface_status_0
      AND    xbb.gl_interface_status  <> cv_interface_status_0
      AND    xbb.edi_interface_status <> cv_interface_status_0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u���̃��b�N���擾����
    -- ===============================================
    OPEN  l_bm_delete_lock_cur;
    CLOSE l_bm_delete_lock_cur;
--
    BEGIN
      -- ===============================================
      -- �̎�c���ێ����ԊO�f�[�^�̍폜
      -- ===============================================
      DELETE FROM xxcok_backmargin_balance
      WHERE  closing_date         <  gd_bm_hold_period_date
      AND    publication_date     IS NOT NULL
      AND    fb_interface_status  <> cv_interface_status_0
      AND    gl_interface_status  <> cv_interface_status_0
      AND    edi_interface_status <> cv_interface_status_0
      ;
--
    EXCEPTION
      -- *** �̎�c���ێ����ԊO���폜��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_10297
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** �̎�c���ێ����ԊO��񃍃b�N��O�n���h�� ***
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_10296
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END delete_bm_period_out;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf        OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_process_date  IN  VARCHAR2      -- �Ɩ��������t
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name                CONSTANT VARCHAR2(5)  := 'init';            -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                -- �o�̓��b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_nodata_profile          VARCHAR2(30)   DEFAULT NULL;                -- ���擾�̃v���t�@�C����
    -- *** ���[�J����O ***
    nodata_profile_expt        EXCEPTION;         -- �v���t�@�C���l�擾��O
    process_date_expt          EXCEPTION;         -- �Ɩ��������t�擾��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 1. �p�����[�^�o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_msg_xxcok_00022
                    ,iv_token_name1  => cv_tkn_business_date
                    ,iv_token_value1 => iv_process_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,lv_out_msg
                    ,2
                  );
--
    BEGIN
      -- ===============================================
      -- 2. �p�����[�^�ɋƖ��������t���ݒ肳��Ă���ꍇ�A
      --    ���t�^�ɕϊ�
      -- ===============================================
      IF( iv_process_date IS NOT NULL ) THEN
        gd_process_date := FND_DATE.CANONICAL_TO_DATE( iv_process_date );
      ELSE
        -- ===============================================
        -- 3. �p�����[�^�ɋƖ��������t���ݒ肳��Ă��Ȃ��ꍇ�A
        --    �Ɩ��������t���擾
        -- ===============================================
        gd_process_date := xxccp_common_pkg2.get_process_date;
        IF( gd_process_date IS NULL ) THEN
          RAISE process_date_expt;
        END IF;
      END IF;
--
    EXCEPTION
      -- *** �Ɩ��������t�擾��O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_msg_xxcok_00028
                       );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        RAISE process_date_expt;
    END;
--
    -- ===============================================
    -- 4. �v���t�@�C���F�����ʔ̎�̋��v�Z�������ԁiFrom�j���擾
    -- ===============================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_bm_support_period_from ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_nodata_profile := cv_bm_support_period_from;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ===============================================
    -- 5. �v���t�@�C���F�����ʔ̎�̋��v�Z�������ԁiTo�j���擾
    -- ===============================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_bm_support_period_to ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_nodata_profile := cv_bm_support_period_to;
      RAISE nodata_profile_expt;
    END IF;
--
    -- ===============================================
    -- 6. �v���t�@�C���F�̎�̋��v�Z���ʕێ����Ԃ��擾
    -- ===============================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_sales_retention_period ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_nodata_profile := cv_sales_retention_period;
      RAISE nodata_profile_expt;
    END IF;
--
-- Start 2009/05/28 Ver_1.3 T1_1138 M.Hiruta
    -- ===============================================
    -- 7. �v���t�@�C���F�x������_�f�t�H���g���擾
    -- ===============================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_default_term_name );
    IF( gv_default_term_name IS NULL ) THEN
      lv_nodata_profile := cv_default_term_name;
      RAISE nodata_profile_expt;
    END IF;
-- End   2009/05/28 Ver_1.3 T1_1138 M.Hiruta
--
    -- ===============================================
    -- 8. �̎�̋��ێ����������擾
    -- ===============================================
    gd_bm_hold_period_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), -gn_sales_retention_period );
--
  EXCEPTION
    -- *** �v���t�@�C���擾��O�n���h�� ****
    WHEN nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_msg_xxcok_00003
                      ,iv_token_name1  => cv_tkn_profile_name
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ��������t�擾��O�n���h�� ***
    WHEN process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT VARCHAR2      -- �G���[�E���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2      -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_process_date  IN  VARCHAR2      -- �Ɩ��������t
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(10) := 'submain'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000)  DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)     DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000)  DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000)  DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN         DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_resv_update_flag       VARCHAR2(1)     DEFAULT cv_flag_y;            -- �̎�c���ۗ��f�[�^�X�V�t���O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �O���[�o���ϐ��̏�����
    -- ===============================================
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
       ov_errbuf        =>   lv_errbuf         -- �G���[�E���b�Z�[�W
      ,ov_retcode       =>   lv_retcode        -- ���^�[���E�R�[�h
      ,ov_errmsg        =>   lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_process_date  =>   iv_process_date   -- �Ɩ��������t
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
    -- ===============================================
    delete_bm_period_out(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �̎�c���ۗ��f�[�^�̎擾(A-3)
    -- ===============================================
    get_bm_bal_resv(
       ov_errbuf             =>    lv_errbuf            -- �G���[�E���b�Z�[�W
      ,ov_retcode            =>    lv_retcode           -- ���^�[���E�R�[�h
      ,ov_errmsg             =>    lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,ov_resv_update_flag   =>    lv_resv_update_flag  -- �̎�c���ۗ��f�[�^�X�V�t���O
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �̎�c���v�Z�f�[�^�̎擾(A-7)
    -- ===============================================
    get_cond_bm_support(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      RAISE status_warn_expt;
    END IF;
--
    -- ===============================================
    -- �̎�c���ۗ��f�[�^�X�V�t���O��Y�i�ۗ��j����
    -- �̎�c���ۗ��f�[�^������ꍇ
    -- ===============================================
    IF(  ( lv_resv_update_flag     = cv_flag_y )
      AND( g_bm_bal_resv_tab.COUNT > 0         ) )
    THEN
      -- ===============================================
      -- �̎�c���ۗ��f�[�^�̍X�V(A-12)
      -- ===============================================
      update_bm_bal_resv(
         ov_errbuf     =>   lv_errbuf        -- �G���[�E���b�Z�[�W
        ,ov_retcode    =>   lv_retcode       -- ���^�[���E�R�[�h
        ,ov_errmsg     =>   lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** �x�������n���h�� ***
    WHEN status_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_normal;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf          OUT    VARCHAR2       -- �G���[�E���b�Z�[�W
    ,retcode         OUT    VARCHAR2       -- ���^�[���E�R�[�h
    ,iv_process_date IN     VARCHAR2       -- �Ɩ��������t
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name        CONSTANT VARCHAR2(5)   := 'main';           -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;               -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)     DEFAULT cv_status_normal;   -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;               -- �I�����b�Z�[�W
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;               -- �o�̓��b�Z�[�W
    lb_retcode         BOOLEAN         DEFAULT TRUE;               -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf        =>    lv_errbuf        -- �G���[�E���b�Z�[�W
      ,ov_retcode       =>    lv_retcode       -- ���^�[���E�R�[�h
      ,ov_errmsg        =>    lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_process_date  =>    iv_process_date  -- �Ɩ��������t
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_errmsg  --���[�U�[�E�G���[�E���b�Z�[�W
                      ,1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.LOG
                      ,lv_errbuf  --�G���[���b�Z�[�W
                      ,1
                    );
    END IF;
    -- ===============================================
    -- �ُ�I���̏ꍇ�̌����Z�b�g
    -- ===============================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- ���������o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_xxccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    -- ===============================================
    -- �I�����b�Z�[�W
    -- ===============================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    -- ===============================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK014A03C;
/
