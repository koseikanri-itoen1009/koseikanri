CREATE OR REPLACE PACKAGE BODY XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(body)
 * Description      : �̎�c���v�Z����
 * MD.050           : �̔��萔���i���̋@�j�̎x���\��z�i�����c���j���v�Z MD050_COK_014_A03
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  update_xcbs            �̎�̋��A�g���ʂ̍X�V�i���z�m�蕪�j(A-10)
 *  insert_xbb             �̎�c���̓o�^(A-9)
 *  calc_loop              �̎�c���v�Z���[�v(A-8)
 *  delete_xbb             ���m��̎�c���f�[�^�̍폜(A-7)
 *  update_xbb             �x���ۗ��̉���(A-5)
 *  get_calc_period        �v�Z�J�n���E�I�����̎擾(A-4)
 *  reserve_loop           �ۗ����[�v(A-3)
 *  purge_xbb              �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
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
 *  2009/12/12    1.4   K.Yamaguchi      [E_�{�ғ�_00360] ���m��f�[�^�ō폜����Ȃ��f�[�^���c�邽�ߍč쐬
 *  2012/07/09    1.5   K.Onotsuka       [E_�{�ғ�_08365] �̎�c���e�[�u���ɍ��ڒǉ�(�����敪)�������l�F0
 *  2015/03/04    1.6   K.Kiriu          [E_�{�ғ�_12937] PT�Ή�(�q���g��ǉ�)
 *
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK014A03C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ����
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00022                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00022';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00051                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00051';
  cv_msg_cok_10296                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10296';
  cv_msg_cok_10298                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10298';
  cv_msg_cok_10301                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10301';
  cv_msg_cok_10306                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10306';
  cv_msg_cok_10454                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10454';
  cv_msg_cok_10455                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10455';
  -- �g�[�N��
  cv_tkn_business_date             CONSTANT VARCHAR2(30)    := 'BUSINESS_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_close_date                CONSTANT VARCHAR2(30)    := 'CLOSE_DATE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';     -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';       -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOK1_SALES_RETENTION_PERIOD';     -- XXCOK:�̎�̋����ێ�����
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_DEFAULT_TERM_NAME';          -- �x������_�f�t�H���g
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRR/MM/DD';
  -- �����ʔ̎�̋��e�[�u���A�g�X�e�[�^�X
  cv_xcbs_if_status_no             CONSTANT VARCHAR2(1)     := '0'; -- ������
  cv_xcbs_if_status_yes            CONSTANT VARCHAR2(1)     := '1'; -- ������
  cv_xcbs_if_status_off            CONSTANT VARCHAR2(1)     := '2'; -- �s�v
  -- �̎�c���e�[�u���A�g�X�e�[�^�X
  cv_xbb_if_status_no              CONSTANT VARCHAR2(1)     := '0'; -- ������
  -- �x����
  cv_month_type1                   CONSTANT VARCHAR2(2)     := '40'; -- ����
  cv_month_type2                   CONSTANT VARCHAR2(2)     := '50'; -- ����
  -- �T�C�g
  cv_site_type1                    CONSTANT VARCHAR2(2)     := '00'; -- ����
  cv_site_type2                    CONSTANT VARCHAR2(2)     := '01'; -- ����
  -- �_��Ǘ��X�e�[�^�X
  cv_xcm_status_result             CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �����ʔ̎�̋��e�[�u�����z�m��X�e�[�^�X
  cv_xcbs_temp                     CONSTANT VARCHAR2(1)     := '0'; -- ���m��
  cv_xcbs_fix                      CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �c�Ɠ��擾�֐��E�����敪
  cn_proc_type_before              CONSTANT NUMBER          := 1;  -- �O
  cn_proc_type_after               CONSTANT NUMBER          := 2;  -- ��
  -- �̎�c���e�[�u���E�ۗ��t���O
  cv_reserve                       CONSTANT VARCHAR2(1)     := 'Y'; -- �ۗ�
-- 2012/07/06 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD START
  cv_proc_type_default             CONSTANT VARCHAR2(1)     := '0'; -- �����敪�f�t�H���g�l(�o�^�p)
-- 2012/07/06 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD END
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- �X�L�b�v����
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- �̎�����G���[����
  -- ���̓p�����[�^
  gv_param_process_date            VARCHAR2(10)  DEFAULT NULL;   -- �Ɩ��������t
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_bm_support_period_from        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  gn_bm_support_period_to          NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  gn_sales_retention_period        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋����ێ�����
  gv_default_term_name             VARCHAR2(8)   DEFAULT NULL;   -- �x������_�f�t�H���g
  --==================================================
  -- �O���[�o���R���N�V����
  --==================================================
  -- �ۗ����
  TYPE reserve_data_rtype          IS RECORD (
    cust_code       xxcok_backmargin_balance.cust_code%TYPE
  , supplier_code   xxcok_backmargin_balance.supplier_code%TYPE
  );
  TYPE reserve_data_ttype          IS TABLE OF reserve_data_rtype INDEX BY BINARY_INTEGER;
  reserve_data_tab                 reserve_data_ttype;
  --==================================================
  -- ���ʗ�O
  --==================================================
  --*** ���������ʗ�O ***
  global_process_expt              EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                  EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�擾�G���[ ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- �O���[�o����O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
  --*** �x���X�L�b�v ***
  warning_skip_expt                EXCEPTION;
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  -- �ۗ����
  CURSOR reserve_cur
  IS
    SELECT xbb.cust_code                AS cust_code
         , xbb.supplier_code            AS supplier_code
         , ( SELECT ( CASE
                        WHEN (    ( xcm.close_day_code       IS NULL )
                               OR ( xcm.transfer_day_code    IS NULL )
                               OR ( xcm.transfer_month_code  IS NULL )
                             )
                        THEN
                          gv_default_term_name
                        ELSE
                             xcm.close_day_code
                          || '_'
                          || xcm.transfer_day_code
                          || '_'
                          || ( CASE
                                 WHEN xcm.transfer_month_code = cv_month_type1 THEN
                                   cv_site_type1
                                 ELSE
                                   cv_site_type2
                               END
                             )
                      END
                    )
             FROM xxcso_contract_managements  xcm
             WHERE xcm.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                                  FROM xxcso_contract_managements  xcm2
                                                     , hz_cust_accounts            hca
                                                  WHERE xcm2.install_account_id = hca.cust_account_id
                                                    AND xcm2.status             = cv_xcm_status_result
                                                    AND hca.account_number      = xbb.cust_code
                                                )
           )                            AS term_name
    FROM ( SELECT /*+
                    INDEX( xbb XXCOK_BACKMARGIN_BALANCE_N03 )
                  */
                  DISTINCT
                  xbb.cust_code
                , xbb.supplier_code
           FROM xxcok_backmargin_balance xbb
           WHERE xbb.resv_flag   = cv_reserve
         )                xbb
  ;
  -- �̎�̋����
  CURSOR xcbs_data_cur
  IS
    SELECT xcbs.base_code                            AS base_code           -- ���_�R�[�h
         , xcbs.supplier_code                        AS supplier_code       -- �d����R�[�h
         , xcbs.supplier_site_code                   AS supplier_site_code  -- �d����T�C�g�R�[�h
         , xcbs.delivery_cust_code                   AS delivery_cust_code  -- �ڋq�R�[�h(�[�i��)
         , xcbs.closing_date                         AS closing_date        -- ���ߓ�
         , xcbs.expect_payment_date                  AS expect_payment_date -- �x���\���
         , xcbs.tax_code                             AS tax_code            -- �ŋ��R�[�h
         , xcbs.amt_fix_status                       AS amt_fix_status      -- ���z�m��X�e�[�^�X
         , SUM( xcbs.selling_amt_tax )               AS selling_amt_tax     -- ������z�i�ō��j
         , SUM( NVL( xcbs.cond_bm_amt_no_tax , 0 ) ) AS cond_bm_amt         -- �����ʎ萔���z�i�Ŕ��j
         , SUM( NVL( xcbs.cond_tax_amt       , 0 ) ) AS cond_tax_amt        -- �����ʏ���Ŋz
         , SUM( NVL( xcbs.electric_amt_no_tax, 0 ) ) AS electric_amt        -- �d�C��(�Ŕ�)
         , SUM( NVL( xcbs.electric_tax_amt   , 0 ) ) AS electric_tax_amt    -- �d�C������Ŋz
    FROM xxcok_cond_bm_support xcbs
    WHERE xcbs.bm_interface_status = cv_xcbs_if_status_no
    GROUP BY xcbs.base_code
           , xcbs.supplier_code
           , xcbs.supplier_site_code
           , xcbs.delivery_cust_code
           , xcbs.closing_date
           , xcbs.expect_payment_date
           , xcbs.tax_code
           , xcbs.amt_fix_status
  ;
--
  /**********************************************************************************
   * Procedure Name   : update_xcbs
   * Description      : �̎�̋��A�g���ʂ̍X�V�i���z�m�蕪�j(A-10)
   ***********************************************************************************/
  PROCEDURE update_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_xcbs_data_rec                IN  xcbs_data_cur%ROWTYPE        -- �̎�̋���񃌃R�[�h
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xcbs';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbs_update_lock_cur
    IS
-- 2015/03/04 Ver.1.6 [E_�{�ғ�_12937] SCSK K.Kiriu MOD START
--      SELECT xcbs.cond_bm_support_id    AS cond_bm_support_id           -- �����ʔ̎�̋�ID
      SELECT /*+ INDEX( xcbs XXCOK_COND_BM_SUPPORT_N04 ) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id           -- �����ʔ̎�̋�ID
-- 2015/03/04 Ver.1.6 [E_�{�ғ�_12937] SCSK K.Kiriu MOD END
      FROM xxcok_cond_bm_support   xcbs               -- �����ʔ̎�̋��e�[�u��
      WHERE xcbs.base_code            = i_xcbs_data_rec.base_code
        AND xcbs.supplier_code        = i_xcbs_data_rec.supplier_code
        AND xcbs.supplier_site_code   = i_xcbs_data_rec.supplier_site_code
        AND xcbs.delivery_cust_code   = i_xcbs_data_rec.delivery_cust_code
        AND xcbs.closing_date         = i_xcbs_data_rec.closing_date
        AND xcbs.expect_payment_date  = i_xcbs_data_rec.expect_payment_date
        AND xcbs.bm_interface_status  = cv_xcbs_if_status_no
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �����ʔ̎�̋��X�V���[�v
    --==================================================
    << xcbs_update_lock_loop >>
    FOR xcbs_update_lock_rec IN xcbs_update_lock_cur LOOP
      --==================================================
      -- �����ʔ̎�̋��e�[�u���X�V
      --==================================================
      UPDATE xxcok_cond_bm_support      xcbs
      SET xcbs.bm_interface_status      = cv_xcbs_if_status_yes    -- �A�g�X�e�[�^�X�i�̎�c���j
        , xcbs.bm_interface_date        = gd_process_date          -- �A�g���i�̎�c���j
        , xcbs.last_updated_by          = cn_last_updated_by
        , xcbs.last_update_date         = SYSDATE
        , xcbs.last_update_login        = cn_last_update_login
        , xcbs.request_id               = cn_request_id
        , xcbs.program_application_id   = cn_program_application_id
        , xcbs.program_id               = cn_program_id
        , xcbs.program_update_date      = SYSDATE
      WHERE xcbs.cond_bm_support_id = xcbs_update_lock_rec.cond_bm_support_id
      ;
    END LOOP xcbs_update_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : insert_xbb
   * Description      : �̎�c���̓o�^(A-9)
   ***********************************************************************************/
  PROCEDURE insert_xbb(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_xcbs_data_rec                IN  xcbs_data_cur%ROWTYPE
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbb';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lt_resv_flag                   xxcok_backmargin_balance.resv_flag%TYPE DEFAULT NULL; -- �ۗ��t���O
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ۗ��σ`�F�b�N
    --==================================================
    lt_resv_flag := NULL;
    << reserve_check_loop >>
    FOR i IN 1 .. reserve_data_tab.COUNT LOOP
      IF(     ( i_xcbs_data_rec.delivery_cust_code = reserve_data_tab(i).cust_code     )
          AND ( i_xcbs_data_rec.supplier_code      = reserve_data_tab(i).supplier_code )
      ) THEN
        lt_resv_flag := cv_reserve;
        EXIT reserve_check_loop;
      END IF;
    END LOOP reserve_check_loop;
    --==================================================
    -- �̎�c���e�[�u���o�^
    --==================================================
    INSERT INTO xxcok_backmargin_balance(
      bm_balance_id                -- �̎�c��ID
    , base_code                    -- ���_�R�[�h
    , supplier_code                -- �d����R�[�h
    , supplier_site_code           -- �d����T�C�g�R�[�h
    , cust_code                    -- �ڋq�R�[�h
    , closing_date                 -- ���ߓ�
    , selling_amt_tax              -- �̔����z�i�ō��j
    , backmargin                   -- �̔��萔��
    , backmargin_tax               -- �̔��萔���i����Ŋz�j
    , electric_amt                 -- �d�C��
    , electric_amt_tax             -- �d�C���i����Ŋz�j
    , tax_code                     -- �ŋ��R�[�h
    , expect_payment_date          -- �x���\���
    , expect_payment_amt_tax       -- �x���\��z�i�ō��j
    , payment_amt_tax              -- �x���z�i�ō��j
    , resv_flag                    -- �ۗ��t���O
    , return_flag                  -- �g�ݖ߂��t���O
    , publication_date             -- �ē���������
    , fb_interface_status          -- �A�g�X�e�[�^�X�i�{�U�pFB�j
    , fb_interface_date            -- �A�g���i�{�U�pFB�j
    , edi_interface_status         -- �A�g�X�e�[�^�X�iEDI�x���ē����j
    , edi_interface_date           -- �A�g���iEDI�x���ē����j
    , gl_interface_status          -- �A�g�X�e�[�^�X�iGL�j
    , gl_interface_date            -- �A�g���iGL�j
    , amt_fix_status               -- ���z�m��X�e�[�^�X
-- 2012/07/04 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD START
    , proc_type                    -- �����敪
-- 2012/07/04 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD END
    -- WHO�J����
    , created_by                   -- �쐬��
    , creation_date                -- �쐬��
    , last_updated_by              -- �ŏI�X�V��
    , last_update_date             -- �ŏI�X�V��
    , last_update_login            -- �ŏI�X�V���O�C��
    , request_id                   -- �v��ID
    , program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                   -- �R���J�����g�E�v���O����ID
    , program_update_date          -- �v���O�����X�V��
    )
    VALUES (
      xxcok_backmargin_balance_s01.NEXTVAL   -- bm_balance_id
    , i_xcbs_data_rec.base_code              -- base_code
    , i_xcbs_data_rec.supplier_code          -- supplier_code
    , i_xcbs_data_rec.supplier_site_code     -- supplier_site_code
    , i_xcbs_data_rec.delivery_cust_code     -- cust_code
    , i_xcbs_data_rec.closing_date           -- closing_date
    , i_xcbs_data_rec.selling_amt_tax        -- selling_amt_tax
    , i_xcbs_data_rec.cond_bm_amt            -- backmargin
    , i_xcbs_data_rec.cond_tax_amt           -- backmargin_tax
    , i_xcbs_data_rec.electric_amt           -- electric_amt
    , i_xcbs_data_rec.electric_tax_amt       -- electric_amt_tax
    , i_xcbs_data_rec.tax_code               -- tax_code
    , i_xcbs_data_rec.expect_payment_date    -- expect_payment_date
    , i_xcbs_data_rec.cond_bm_amt
    + i_xcbs_data_rec.cond_tax_amt
    + i_xcbs_data_rec.electric_amt
    + i_xcbs_data_rec.electric_tax_amt       -- expect_payment_amt_tax
    , 0                                      -- payment_amt_tax
    , lt_resv_flag                           -- resv_flag
    , NULL                                   -- return_flag
    , NULL                                   -- publication_date
    , cv_xbb_if_status_no                    -- fb_interface_status
    , NULL                                   -- fb_interface_date
    , cv_xbb_if_status_no                    -- edi_interface_status
    , NULL                                   -- edi_interface_date
    , cv_xbb_if_status_no                    -- gl_interface_status
    , NULL                                   -- gl_interface_date
    , i_xcbs_data_rec.amt_fix_status         -- amt_fix_status
-- 2012/07/06 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD START
    , cv_proc_type_default                   -- proc_type
-- 2012/07/06 Ver.1.5 [E_�{�ғ�_08365] SCSK K.Onotsuka ADD END
    -- WHO�J����
    , cn_created_by                          -- created_by
    , SYSDATE                                -- creation_date
    , cn_last_updated_by                     -- last_updated_by
    , SYSDATE                                -- last_update_date
    , cn_last_update_login                   -- last_update_login
    , cn_request_id                          -- request_id
    , cn_program_application_id              -- program_application_id
    , cn_program_id                          -- program_id
    , SYSDATE                                -- program_update_date
    );
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbb;
--
  /**********************************************************************************
   * Procedure Name   : calc_loop
   * Description      : �̎�c���v�Z���[�v(A-8)
   **********************************************************************************/
  PROCEDURE calc_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'calc_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�̋��v�Z���ʂ̎擾(A-8)
    --==================================================
    << main_loop >>
    FOR xcbs_data_rec IN xcbs_data_cur LOOP
      --==================================================
      -- �Ώی����J�E���g
      --==================================================
      gn_target_cnt := gn_target_cnt + 1;
      --==================================================
      -- �̎�c���̓o�^(A-9)
      --==================================================
      insert_xbb(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_xcbs_data_rec             => xcbs_data_rec              -- �̎�̋���񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�̋��A�g���ʂ̍X�V�i���z�m�蕪�j(A-10)
      --==================================================
      IF( xcbs_data_rec.amt_fix_status = cv_xcbs_fix ) THEN
        update_xcbs(
          ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
        , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
        , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_xcbs_data_rec             => xcbs_data_rec              -- �̎�̋���񃌃R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
      END IF;
      --==================================================
      -- ���팏���J�E���g
      --==================================================
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP main_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END calc_loop;
--
  /**********************************************************************************
   * Procedure Name   : delete_xbb
   * Description      : ���m��̎�c���f�[�^�̍폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xbb(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbb';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xbb_delete_lock_cur
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id  -- �̎�c��ID
      FROM xxcok_backmargin_balance     xbb               -- �����ʔ̎�̋��e�[�u��
      WHERE xbb.amt_fix_status    = cv_xcbs_temp -- ���m��
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�c���폜���[�v
    --==================================================
    << xbb_delete_lock_loop >>
    FOR xbb_delete_lock_rec IN xbb_delete_lock_cur LOOP
      --==================================================
      -- �����ʔ̎�̋��f�[�^�폜
      --==================================================
      DELETE
      FROM xxcok_backmargin_balance     xbb
      WHERE xbb.bm_balance_id = xbb_delete_lock_rec.bm_balance_id
      ;
    END LOOP xbb_delete_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10301
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END delete_xbb;
--
  /**********************************************************************************
   * Procedure Name   : update_xbb
   * Description      : �x���ۗ��̉���(A-5)
   ***********************************************************************************/
  PROCEDURE update_xbb(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_reserve_rec                  IN  reserve_cur%ROWTYPE        -- �ۗ���񃌃R�[�h
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xbb';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xbb_update_lock_cur
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id              -- �̎�c��ID
      FROM xxcok_backmargin_balance     xbb                -- �̎�c���e�[�u��
      WHERE xbb.cust_code               = i_reserve_rec.cust_code
        AND xbb.resv_flag               = cv_reserve
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�c���X�V���[�v
    --==================================================
    << xbb_update_lock_loop >>
    FOR xbb_update_lock_rec IN xbb_update_lock_cur LOOP
      --==================================================
      -- �̎�c���e�[�u���X�V
      --==================================================
      UPDATE xxcok_backmargin_balance   xbb
      SET xbb.resv_flag              = NULL
        , xbb.last_updated_by        = cn_last_updated_by
        , xbb.last_update_date       = SYSDATE
        , xbb.last_update_login      = cn_last_update_login
        , xbb.request_id             = cn_request_id
        , xbb.program_application_id = cn_program_application_id
        , xbb.program_id             = cn_program_id
        , xbb.program_update_date    = SYSDATE
      WHERE xbb.bm_balance_id        = xbb_update_lock_rec.bm_balance_id
      ;
    END LOOP xbb_update_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10298
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xbb;
--
  /**********************************************************************************
   * Procedure Name   : get_calc_period
   * Description      : �v�Z�J�n���E�I�����̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_calc_period(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_reserve_rec                  IN  reserve_cur%ROWTYPE        -- �ۗ���񃌃R�[�h
  , od_start_date                  OUT DATE                       -- �v�Z�J�n��
  , od_end_date                    OUT DATE                       -- �v�Z�I����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_calc_period';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_tmp_start_date              DATE           DEFAULT NULL;                 -- �v�Z�J�n���i���j
    ld_close_date                  DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_pay_date                    DATE           DEFAULT NULL;                 -- �x����
    ld_start_date                  DATE           DEFAULT NULL;                 -- �v�Z�J�n��
    ld_end_date                    DATE           DEFAULT NULL;                 -- �v�Z�I����
    --==================================================
    -- ���[�J����O
    --==================================================
    skip_proc_expt                 EXCEPTION; -- �v�Z�ΏۊO�X�L�b�v
    get_close_date_expt            EXCEPTION; -- ���߁E�x�����擾�֐��G���[
    get_operating_day_expt         EXCEPTION; -- �c�Ɠ��擾�֐��G���[
    get_acctg_calendar_expt        EXCEPTION; -- ��v�J�����_�擾�֐��G���[
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �����ʔ̎�̋��v�Z�J�n��(��)�擾
    --==================================================
    ld_tmp_start_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => gd_process_date                             -- IN DATE   ������
      , in_days                  => -1 * gn_bm_support_period_to                -- IN NUMBER ����
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER �����敪
      );
    IF( ld_tmp_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- ���ߎx�����擾
    --==================================================
    xxcok_common_pkg.get_close_date_p(
      ov_errbuf                  => lv_errbuf                                   -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
    , ov_retcode                 => lv_retcode                                  -- OUT VARCHAR2          ���^�[���R�[�h
    , ov_errmsg                  => lv_errmsg                                   -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
    , id_proc_date               => ld_tmp_start_date                           -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
    , iv_pay_cond                => i_reserve_rec.term_name                     -- IN  VARCHAR2          �x������(IN)
    , od_close_date              => ld_close_date                               -- OUT DATE              ���ߓ�(OUT)
    , od_pay_date                => ld_pay_date                                 -- OUT DATE              �x����(OUT)
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE get_close_date_expt;
    END IF;
    --==================================================
    -- �v�Z�J�n���擾
    --==================================================
    ld_start_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => ld_close_date                               -- IN DATE   ������
      , in_days                  => gn_bm_support_period_from                   -- IN NUMBER ����
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER �����敪
      );
    IF( ld_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- �v�Z�I�����擾
    --==================================================
    ld_end_date :=
      xxcok_common_pkg.get_operating_day_f(
        id_proc_date             => ld_close_date                               -- IN DATE   ������
      , in_days                  => gn_bm_support_period_to                     -- IN NUMBER ����
      , in_proc_type             => cn_proc_type_before                         -- IN NUMBER �����敪
      );
    IF( ld_start_date IS NULL ) THEN
      RAISE get_operating_day_expt;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    od_start_date   := ld_start_date;
    od_end_date     := ld_end_date;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���߁E�x�����擾�֐��G���[ ***
    WHEN get_close_date_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10454
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_reserve_rec.cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �c�Ɠ��擾�֐��G���[ ***
    WHEN get_operating_day_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10455
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_reserve_rec.cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_calc_period;
--
  /**********************************************************************************
   * Procedure Name   : reserve_loop
   * Description      : �ۗ����[�v(A-3)
   ***********************************************************************************/
  PROCEDURE reserve_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'reserve_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_start_date                  DATE           DEFAULT NULL;                 -- �v�Z�J�n��
    ld_end_date                    DATE           DEFAULT NULL;                 -- �v�Z�I����
    ln_reserve_data_cnt            BINARY_INTEGER DEFAULT 0;                    -- �ۗ����ێ�����
    -- ���O�o�͗p�ޔ�����
    lt_ship_cust_code              hz_cust_accounts.account_number      %TYPE DEFAULT NULL;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �e�평����
    --==================================================
    reserve_data_tab.DELETE;
    ln_reserve_data_cnt := 0;
    --==================================================
    -- �̎�c���ۗ��f�[�^�̎擾(A-3)
    --==================================================
    << reserve_data_loop >>
    FOR reserve_rec IN reserve_cur LOOP
      DECLARE
        skip_proc_expt        EXCEPTION; -- �����X�L�b�v
      BEGIN
        -- �_���񂪎擾�ł��Ȃ��ꍇ�����X�L�b�v
        IF( reserve_rec.term_name IS NULL ) THEN
          RAISE skip_proc_expt;
        END IF;
        --==================================================
        -- �v�Z�J�n���E�I�����̎擾(A-4)
        --==================================================
        get_calc_period(
          ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
        , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
        , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_reserve_rec               => reserve_rec                -- �ۗ���񃌃R�[�h
        , od_start_date               => ld_start_date              -- �v�Z�J�n��
        , od_end_date                 => ld_end_date                -- �v�Z�I����
        );
fnd_file.put_line( FND_FILE.LOG
                 ,           reserve_rec.cust_code
                   || ',' || reserve_rec.supplier_code
                   || ',' || reserve_rec.term_name
                   || ',' || TO_CHAR( ld_start_date,'RRRR/MM/DD' )
                   || ',' || TO_CHAR( ld_end_date  ,'RRRR/MM/DD' )
                 ); -- debug
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        END IF;
        --==================================================
        -- �x���ۗ��̉���(A-5)
        --==================================================
        IF( gd_process_date = ld_start_date ) THEN
          update_xbb(
            ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_reserve_rec               => reserve_rec                -- �ۗ���񃌃R�[�h
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          END IF;
        --==================================================
        -- �x���ۗ����̕ێ�(A-6)
        --==================================================
        ELSIF(     ( gd_process_date  > ld_start_date )
               AND ( gd_process_date <= ld_end_date   )
        ) THEN
          ln_reserve_data_cnt := ln_reserve_data_cnt + 1;
          reserve_data_tab(ln_reserve_data_cnt).cust_code     := reserve_rec.cust_code;
          reserve_data_tab(ln_reserve_data_cnt).supplier_code := reserve_rec.supplier_code;
        END IF;
      EXCEPTION
        WHEN skip_proc_expt THEN
fnd_file.put_line( FND_FILE.LOG
                 ,           'contract_unknown:'
                   || ':' || reserve_rec.cust_code
                   || ',' || reserve_rec.supplier_code
                 ); -- debug
      END;
    END LOOP reserve_data_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END reserve_loop;
--
  /**********************************************************************************
   * Procedure Name   : purge_xbb
   * Description      : �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
   ***********************************************************************************/
  PROCEDURE purge_xbb(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xbb';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_start_date                  DATE           DEFAULT NULL;                 -- �Ɩ���������
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xbb_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT xbb.bm_balance_id          AS bm_balance_id
      FROM xxcok_backmargin_balance     xbb           -- �̎�c���e�[�u��
      WHERE xbb.publication_date        < id_target_date
        AND xbb.expect_payment_amt_tax  = 0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �������擾
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- �̎�c���e�[�u���̃��b�N
    --==================================================
    FOR xbb_parge_lock_rec IN xbb_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- �̎�c���f�[�^�p�[�W
      --==================================================
      DELETE
      FROM xxcok_backmargin_balance   xbb
      WHERE xbb.bm_balance_id = xbb_parge_lock_rec.bm_balance_id
      ;
    END LOOP;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10296
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xbb;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_date                IN  VARCHAR2        -- �Ɩ��������t
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �Ɩ��������t
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00022
                  , iv_token_name1          => cv_tkn_business_date
                  , iv_token_value1         => iv_process_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg         -- ���b�Z�[�W
                  , in_new_line             => 0                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    --==================================================
    -- �v���O�������͍��ڂ��O���[�o���ϐ��֊i�[
    --==================================================
    gv_param_process_date := iv_process_date;
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    IF( gv_param_process_date IS NOT NULL ) THEN
      gd_process_date := TO_DATE( gv_param_process_date, cv_format_fxrrrrmmdd );
    ELSE
      gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
      IF( gd_process_date IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00028
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
fnd_file.put_line( FND_FILE.LOG, 'For Debug:' || 'gd_process_date' || '�y' || TO_CHAR( gd_process_date, 'RRRR/MM/DD' ) || '�z' ); -- debug
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiFrom�j)
    --==================================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiTo�j)
    --==================================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋����ێ�����)
    --==================================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x������_�f�t�H���g)
    --==================================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_default_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_date                IN  VARCHAR2        -- �Ɩ��������t
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_date         => iv_process_date       -- �Ɩ��������t
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �̎�c���ێ����ԊO�f�[�^�̍폜(A-2)
    --==================================================
    purge_xbb(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �ۗ����[�v(A-3)
    --==================================================
    reserve_loop(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- ���m��̎�c���f�[�^�̍폜(A-7)
    --==================================================
    delete_xbb(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �̎�c���v�Z���[�v(A-8)
    --==================================================
    calc_loop(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_process_date                IN  VARCHAR2        -- �Ɩ��������t
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message               => NULL               -- ���b�Z�[�W
                  , in_new_line              => 1                  -- ���s
                  );
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_date         => iv_process_date       -- �Ɩ��������t
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- �o�͋敪
                    , iv_message               => lv_errmsg           -- ���b�Z�[�W
                    , in_new_line              => 1                   -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK014A03C;
/
