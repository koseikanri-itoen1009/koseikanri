create or replace
PACKAGE BODY XXCFF017A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF017A05C(body)
 * Description      : ���̋@�������p�U��
 * MD.050           : MD050_CFF_017_A05_���̋@�������p�U��
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       ��������                                  (A-1)
 *  get_profile_values         �v���t�@�C���l�擾                        (A-2)
 *  get_period                 ��v���ԃ`�F�b�N                          (A-3)
 *  chk_je_vending_data_exist  �O��쐬�ςݎ��̋@�����d�󑶍݃`�F�b�N    (A-4)
 *  ins_gl_oif_dr              GLOIF�o�^����(�ؕ��f�[�^)                 (A-5)
 *  ins_gl_oif_cr              GLOIF�o�^����(�ݕ��f�[�^)                 (A-6)
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/08/01    1.0   SCSK�쌳�P��     �V�K�쐬
 *  2014/11/07    1.1   SCSK���H���O     E_�{�ғ�_12563
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by    CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
  --*** GL��v���ԃ`�F�b�N�G���[
  chk_gl_period_expt        EXCEPTION;
  --*** ���̋@�����d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
  chk_cnt_gloif_expt        EXCEPTION;
  --*** ���̋@�����d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
  chk_cnt_glhead_expt       EXCEPTION;
  --*** ���[�U���(���O�C�����[�U�A��������)�擾�G���[
  get_login_info_expt       EXCEPTION;
  --*** ��v���떼�擾�G���[
  get_sob_name_expt         EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCFF017A05C';     --�p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff         CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_013a20_m_010    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --�v���t�@�C���擾�G���[
  cv_msg_013a20_m_011    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00038'; --��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_012    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; --GL��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_013    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00218'; --���̋@�����d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
  cv_msg_013a20_m_014    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00219'; --���̋@�����d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
  cv_msg_013a20_m_015    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; --��ʉ�vOIF�쐬���b�Z�[�W
  cv_msg_013a20_m_016    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; --�擾�G���[
  cv_msg_013a20_m_017    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00233'; --���[�X�������l�`�F�b�N�G���[
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_013a20_t_010    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:��ЃR�[�h_�{��
  cv_msg_013a20_t_011    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50255'; --XXCFF:�d��\�[�X_���̋@����
  cv_msg_013a20_t_012    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50258'; --XXCFF:�d��J�e�S��_���̋@�������p�U��
  cv_msg_013a20_t_013    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; --XXCFF:����R�[�h_��������
  cv_msg_013a20_t_014    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50273'; --XXCFF:�䒠��
  cv_msg_013a20_t_015    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; --XXCFF:�`�[�ԍ�_���[�X
  cv_msg_013a20_t_016    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50268'; --XXCFF:����Ȗ�_���̋@���[�X��
  cv_msg_013a20_t_017    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50269'; --XXCFF:�⏕�Ȗ�_���̋@
  cv_msg_013a20_t_018    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50275'; --XXCFF:���[�X����
  cv_msg_013a20_t_019    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; --���O�C��(���[�U��,��������)���
  cv_msg_013a20_t_020    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; --��v���떼
  cv_msg_013a20_t_021    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; --���O�C�����[�UID=
  cv_msg_013a20_t_022    CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; --��v����ID=
--
  -- ***�g�[�N����
  cv_tkn_prof            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type         CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period          CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name        CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val         CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_func_name       CONSTANT VARCHAR2(20) := 'FUNC_NAME';
--
  -- ***�v���t�@�C��
  cv_comp_cd_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';    --��ЃR�[�h_�{��
  cv_je_src_vending      CONSTANT VARCHAR2(30) := 'XXCFF1_JE_SOURCE_VENDING';   --�d��\�[�X_���̋@����
  cv_je_cat_vending      CONSTANT VARCHAR2(30) := 'XXCFF1_JE_CATEGORY_VENDING'; --�d��J�e�S��_���̋@�������p�U��
  cv_dep_cd_chosei       CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';       --����R�[�h_��������
  cv_fixed_assets_books  CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS';  --�䒠��
  cv_slip_num_lease      CONSTANT VARCHAR2(30) := 'XXCFF1_SLIP_NUM_LEASE';      --�`�[�ԍ�_���[�X
  cv_account_vending     CONSTANT VARCHAR2(30) := 'XXCFF1_ACCOUNT_VENDING';     --����Ȗ�_���̋@���[�X��
  cv_sub_account_vending CONSTANT VARCHAR2(30) := 'XXCFF1_SUB_ACCOUNT_VENDING'; --�⏕�Ȗ�_���̋@
  cv_lease_rate          CONSTANT VARCHAR2(30) := 'XXCFF1_LEASE_RATE';          --���[�X����
--
  -- ***�t�@�C���o��
--
  cv_file_type_out       CONSTANT VARCHAR2(10) := 'OUTPUT';                     --���b�Z�[�W�o��
  cv_file_type_log       CONSTANT VARCHAR2(10) := 'LOG';                        --���O�o��
--
  -- ***�_�~�[�l
  cv_ptnr_cd_dammy       CONSTANT VARCHAR2(9)  := '000000000';                  --�ڋq�R�[�h_��`�Ȃ�
  cv_busi_cd_dammy       CONSTANT VARCHAR2(6)  := '000000';                     --��ƃR�[�h_��`�Ȃ�
  cv_project_dammy       CONSTANT VARCHAR2(1)  := '0';                          --�\���P_��`�Ȃ�
  cv_future_dammy        CONSTANT VARCHAR2(1)  := '0';                          --�\���Q_��`�Ȃ�
--
  -- ***�ŃR�[�h
  cv_tax_code            CONSTANT VARCHAR2(4)  := '0000';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_deprn_run_ttype      IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_deprn_run_tab             g_deprn_run_ttype;
  g_book_type_code_tab        g_book_type_code_ttype;
--
  -- ***��������
  -- ��ʉ�vOIF�o�^�����ɂ����錏���o��
  gn_gloif_dr_target_cnt   NUMBER;     -- �Ώی���(�ؕ��f�[�^)
  gn_gloif_cr_target_cnt   NUMBER;     -- �Ώی���(�ݕ��f�[�^)
  gn_gloif_normal_cnt      NUMBER;     -- ���팏��
  gn_gloif_error_cnt       NUMBER;     -- �G���[����
--
  -- �����l���
  g_init_rec      xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name  VARCHAR2(100);
--
  -- ***���[�U���
  -- ���O�C�����[�U
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- �N�[����(��������)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***��v������
  -- ��v���떼
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***�v���t�@�C���l
  gv_comp_cd_itoen         VARCHAR2(100);    -- ��ЃR�[�h_�{��
  gv_je_src_vending        VARCHAR2(100);    -- �d��\�[�X_���̋@����
  gv_je_cat_vending        VARCHAR2(100);    -- �d��J�e�S��_���̋@�������p�U��
  gv_dep_cd_chosei         VARCHAR2(100);    -- ����R�[�h_��������
  gv_fixed_assets_books    VARCHAR2(100);    -- �䒠��
  gv_slip_num_lease        VARCHAR2(100);    -- �`�[�ԍ�_���[�X
  gv_account_vending       VARCHAR2(100);    -- ����Ȗ�_���̋@���[�X��
  gv_sub_account_vending   VARCHAR2(100);    -- �⏕�Ȗ�_���̋@
  gv_lease_rate            VARCHAR2(100);    -- ���[�X����
  gn_lease_rate            NUMBER;           -- ���[�X����
--
  -- ***�J�[�\����`
--
  -- ***�e�[�u���^�z��
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_cr
   * Description      : GLOIF�o�^����(�ݕ��f�[�^) (A-6)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_cr(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_cr'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    INSERT INTO gl_interface(
       status                -- �X�e�[�^�X
      ,set_of_books_id       -- ��v����ID
      ,accounting_date       -- �d��L�����t
      ,currency_code         -- �ʉ݃R�[�h
      ,date_created          -- �V�K�쐬���t
      ,created_by            -- �V�K�쐬��ID
      ,actual_flag           -- �c���^�C�v
      ,user_je_category_name -- �d��J�e�S����
      ,user_je_source_name   -- �d��\�[�X��
      ,segment1              -- ���
      ,segment2              -- ����
      ,segment3              -- �Ȗ�
      ,segment4              -- �⏕�Ȗ�
      ,segment5              -- �ڋq
      ,segment6              -- ���
      ,segment7              -- �\��1
      ,segment8              -- �\��2
      ,entered_dr            -- �ؕ����z
      ,entered_cr            -- �ݕ����z
      ,reference10           -- �d�󖾍דE�v
      ,period_name           -- ��v���Ԗ�
      ,attribute1            -- �ŋ敪
      ,attribute3            -- �`�[�ԍ�
      ,attribute4            -- �N�[����
      ,attribute5            -- �`�[���͎�
      ,context               -- �R���e�L�X�g
    )
    SELECT
       'NEW'                                       AS status                -- �X�e�[�^�X
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- ��v����ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- �d��L�����t
      ,g_init_rec.currency_code                    AS currency_code         -- �ʉ݃R�[�h
      ,cd_creation_date                            AS date_created          -- �V�K�쐬���t
      ,cn_created_by                               AS created_by            -- �V�K�쐬��ID
      ,'A'                                         AS actual_flag           -- �c���^�C�v
      ,gv_je_cat_vending                           AS user_je_category_name -- �d��J�e�S����
      ,gv_je_src_vending                           AS user_je_source_name   -- �d��\�[�X��
      ,summary.segment1                            AS segment1              -- ��ЃR�[�h
      ,gv_dep_cd_chosei                            AS segment2              -- ����R�[�h
      ,gv_account_vending                          AS segment3              -- �ȖڃR�[�h
      ,gv_sub_account_vending                      AS segment4              -- �⏕�ȖڃR�[�h
      ,cv_ptnr_cd_dammy                            AS segment5              -- �ڋq�R�[�h
      ,cv_busi_cd_dammy                            AS segment6              -- ��ƃR�[�h
      ,cv_project_dammy                            AS segment7              -- �\��1
      ,cv_future_dammy                             AS segment8              -- �\��2
      ,0                                           AS entered_dr            -- �ؕ����z
      ,SUM(summary.entered_cr)                     AS entered_cr            -- �ݕ����z
      ,NULL                                        AS reference10           -- �d�󖾍דE�v
      ,gv_period_name                              AS period_name           -- ��v���Ԗ�
      ,cv_tax_code                                 AS attribute1            -- �ŋ敪
      ,gv_slip_num_lease                           AS attribute3            -- �`�[�ԍ�
      ,gt_login_dept_code                          AS attribute4            -- �N�[����
      ,gt_login_user_name                          AS attribute5            -- �`�[���͎�
      ,gt_sob_name                                 AS context               -- ��v���떼
    FROM
      (
       SELECT
          gcc.segment1                                  AS segment1         -- ��ЃR�[�h
         ,TRUNC(xvoh.assets_cost * gn_lease_rate / 100) AS entered_cr       -- �擾���i
       FROM
          fa_additions_b          fab
         ,fa_deprn_detail         fdd
         ,fa_deprn_periods        fdp
         ,fa_distribution_history fdh
         ,gl_code_combinations    gcc
         ,xxcff_vd_object_headers xvoh
       WHERE
           fdd.asset_id            = fab.asset_id
       AND fdd.book_type_code      = gv_fixed_assets_books
       AND fdd.period_counter      = fdp.period_counter
       AND fdd.book_type_code      = fdp.book_type_code
       AND fdh.book_type_code      = gv_fixed_assets_books
       AND fdh.date_ineffective    is null
       AND fdd.distribution_id     = fdh.distribution_id
       AND gcc.code_combination_id = fdh.code_combination_id
       AND fdd.deprn_source_code   = 'D'
       AND fdp.period_name         = gv_period_name
       AND fab.tag_number          = xvoh.object_code
       UNION ALL
       SELECT
          gcc.segment1                             AS segment1              -- ��ЃR�[�h
         ,CASE
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 5 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 12)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 6 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 14)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END = 7 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 18)
            WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
            ELSE
              TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
            END >= 8 THEN
              TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 24)
          END                                      AS entered_cr            -- �擾���i
       FROM
          fa_additions_b          fab
         ,fa_books                fb
         ,fa_distribution_history fdh
         ,gl_code_combinations    gcc
         ,xxcff_vd_object_headers xvoh
       WHERE
           fab.asset_id            = fb.asset_id
       AND fb.book_type_code       = gv_fixed_assets_books
       AND fb.date_ineffective     is null
       AND fdh.date_ineffective    is null
       AND fdh.book_type_code      = gv_fixed_assets_books
       AND fab.asset_id            = fdh.asset_id
       AND gcc.code_combination_id = fdh.code_combination_id
       AND to_char(fb.date_placed_in_service, 'MM') = SUBSTRB(gv_period_name, 6, 2)
       AND fb.cost                 > 0
       AND NOT EXISTS
             (SELECT
                'X'
              FROM
                 fa_deprn_summary fds
                ,fa_deprn_periods fdp
              WHERE 1=1
              AND fds.asset_id       = fab.asset_id
              AND fds.period_counter = fdp.period_counter
              AND fds.book_type_code = fdp.book_type_code
              AND fds.book_type_code = gv_fixed_assets_books
              AND fdp.period_name    = gv_period_name)
       AND fab.tag_number          = xvoh.object_code
      ) summary
    GROUP BY
       summary.segment1        -- ��ЃR�[�h
    ;
--
    -- �����ݒ�
    gn_gloif_cr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END ins_gl_oif_cr;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_dr
   * Description      : GLOIF�o�^����(�ؕ��f�[�^) (A-5)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_dr(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_dr'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    cv_flag_on           CONSTANT VARCHAR2(1)  := 'Y';
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
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
    INSERT INTO gl_interface(
       status                -- �X�e�[�^�X
      ,set_of_books_id       -- ��v����ID
      ,accounting_date       -- �d��L�����t
      ,currency_code         -- �ʉ݃R�[�h
      ,date_created          -- �V�K�쐬���t
      ,created_by            -- �V�K�쐬��ID
      ,actual_flag           -- �c���^�C�v
      ,user_je_category_name -- �d��J�e�S����
      ,user_je_source_name   -- �d��\�[�X��
      ,segment1              -- ���
      ,segment2              -- ����
      ,segment3              -- �Ȗ�
      ,segment4              -- �⏕�Ȗ�
      ,segment5              -- �ڋq
      ,segment6              -- ���
      ,segment7              -- �\��1
      ,segment8              -- �\��2
      ,entered_dr            -- �ؕ����z
      ,entered_cr            -- �ݕ����z
      ,reference10           -- �d�󖾍דE�v
      ,period_name           -- ��v���Ԗ�
      ,attribute1            -- �ŋ敪
      ,attribute3            -- �`�[�ԍ�
      ,attribute4            -- �N�[����
      ,attribute5            -- �`�[���͎�
      ,context               -- �R���e�L�X�g
    )
    SELECT
       'NEW'                                         AS status                -- �X�e�[�^�X
      ,g_init_rec.set_of_books_id                    AS set_of_books_id       -- ��v����ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))   AS accounting_date       -- �d��L�����t
      ,g_init_rec.currency_code                      AS currency_code         -- �ʉ݃R�[�h
      ,cd_creation_date                              AS date_created          -- �V�K�쐬���t
      ,cn_created_by                                 AS created_by            -- �V�K�쐬��ID
      ,'A'                                           AS actual_flag           -- �c���^�C�v
      ,gv_je_cat_vending                             AS user_je_category_name -- �d��J�e�S����
      ,gv_je_src_vending                             AS user_je_source_name   -- �d��\�[�X��
      ,gcc.segment1                                  AS segment1              -- ��ЃR�[�h
      ,xvoh.department_code                          AS segment2              -- ����R�[�h
      ,gv_account_vending                            AS segment3              -- �ȖڃR�[�h
      ,gv_sub_account_vending                        AS segment4              -- �⏕�ȖڃR�[�h
-- 2014/11/07 Ver.1.1 Y.Shouji MOD START
--      ,xvoh.customer_code                            AS segment5              -- �ڋq�R�[�h
      ,(CASE WHEN les_class_v.vd_cust_flag = cv_flag_on THEN
                  xvoh.customer_code ELSE cv_ptnr_cd_dammy END)
                                                     AS segment5              -- �ڋq�R�[�h
-- 2014/11/07 Ver.1.1 Y.Shouji MOD END
      ,cv_busi_cd_dammy                              AS segment6              -- ��ƃR�[�h
      ,cv_project_dammy                              AS segment7              -- �\��1
      ,cv_future_dammy                               AS segment8              -- �\��2
      ,TRUNC(xvoh.assets_cost * gn_lease_rate / 100) AS entered_dr            -- �擾���i
      ,0                                             AS entered_cr            -- �ݕ����z
      ,fab.tag_number                                AS reference10           -- �d�󖾍דE�v
      ,gv_period_name                                AS period_name           -- ��v���Ԗ�
      ,cv_tax_code                                   AS attribute1            -- �ŋ敪
      ,gv_slip_num_lease                             AS attribute3            -- �`�[�ԍ�
      ,gt_login_dept_code                            AS attribute4            -- �N�[����
      ,gt_login_user_name                            AS attribute5            -- �`�[���͎�
      ,gt_sob_name                                   AS context               -- ��v���떼
    FROM
       fa_additions_b          fab
      ,fa_deprn_detail         fdd
      ,fa_deprn_periods        fdp
      ,fa_distribution_history fdh
      ,gl_code_combinations    gcc
      ,xxcff_vd_object_headers xvoh
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
      ,xxcff_lease_class_v     les_class_v   -- ���[�X��ʃr���[
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    WHERE
        fdd.asset_id            = fab.asset_id
    AND fdd.book_type_code      = gv_fixed_assets_books
    AND fdd.period_counter      = fdp.period_counter
    AND fdd.book_type_code      = fdp.book_type_code
    AND fdh.book_type_code      = gv_fixed_assets_books
    AND fdh.date_ineffective    is null
    AND fdd.distribution_id     = fdh.distribution_id
    AND gcc.code_combination_id = fdh.code_combination_id
    AND fdd.deprn_source_code   = 'D'
    AND fdp.period_name         = gv_period_name
    AND fab.tag_number          = xvoh.object_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    AND xvoh.lease_class        = les_class_v.lease_class_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    UNION ALL
    SELECT
       'NEW'                                       AS status                -- �X�e�[�^�X
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- ��v����ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- �d��L�����t
      ,g_init_rec.currency_code                    AS currency_code         -- �ʉ݃R�[�h
      ,cd_creation_date                            AS date_created          -- �V�K�쐬���t
      ,cn_created_by                               AS created_by            -- �V�K�쐬��ID
      ,'A'                                         AS actual_flag           -- �c���^�C�v
      ,gv_je_cat_vending                           AS user_je_category_name -- �d��J�e�S����
      ,gv_je_src_vending                           AS user_je_source_name   -- �d��\�[�X��
      ,gcc.segment1                                AS segment1              -- ��ЃR�[�h
      ,xvoh.department_code                        AS segment2              -- ����R�[�h
      ,gv_account_vending                          AS segment3              -- �ȖڃR�[�h
      ,gv_sub_account_vending                      AS segment4              -- �⏕�ȖڃR�[�h
-- 2014/11/07 Ver.1.1 Y.Shouji MOD START
--      ,xvoh.customer_code                          AS segment5              -- �ڋq�R�[�h
      ,(CASE WHEN les_class_v.vd_cust_flag = cv_flag_on THEN
                  xvoh.customer_code ELSE cv_ptnr_cd_dammy END)
                                                   AS segment5              -- �ڋq�R�[�h
-- 2014/11/07 Ver.1.1 Y.Shouji MOD END
      ,cv_busi_cd_dammy                            AS segment6              -- ��ƃR�[�h
      ,cv_project_dammy                            AS segment7              -- �\��1
      ,cv_future_dammy                             AS segment8              -- �\��2
      ,CASE
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 5 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 12)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 6 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 14)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END = 7 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 18)
         WHEN CASE WHEN TO_CHAR(LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')), 'MMDD') >= TO_CHAR(fb.date_placed_in_service, 'MMDD') THEN
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY'))
         ELSE
           TO_NUMBER(SUBSTRB(gv_period_name, 1, 4)) - TO_NUMBER(TO_CHAR(fb.date_placed_in_service, 'YYYY')) - 1
         END >= 8 THEN
           TRUNC(xvoh.assets_cost * gn_lease_rate / 100 * 12 / 24)
       END                                         AS entered_dr            -- �擾���i
      ,0                                           AS entered_cr            -- �ݕ����z
      ,fab.tag_number                              AS reference10           -- �d�󖾍דE�v
      ,gv_period_name                              AS period_name           -- ��v���Ԗ�
      ,cv_tax_code                                 AS attribute1            -- �ŋ敪
      ,gv_slip_num_lease                           AS attribute3            -- �`�[�ԍ�
      ,gt_login_dept_code                          AS attribute4            -- �N�[����
      ,gt_login_user_name                          AS attribute5            -- �`�[���͎�
      ,gt_sob_name                                 AS context               -- ��v���떼
    FROM
       fa_additions_b          fab
      ,fa_books                fb
      ,fa_distribution_history fdh
      ,gl_code_combinations    gcc
      ,xxcff_vd_object_headers xvoh
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
      ,xxcff_lease_class_v     les_class_v   -- ���[�X��ʃr���[
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    WHERE
        fab.asset_id            = fb.asset_id
    AND fb.book_type_code       = gv_fixed_assets_books
    AND fb.date_ineffective     is null
    AND fdh.date_ineffective    is null
    AND fdh.book_type_code      = gv_fixed_assets_books
    AND fab.asset_id            = fdh.asset_id
    AND gcc.code_combination_id = fdh.code_combination_id
    AND to_char(fb.date_placed_in_service, 'MM') = SUBSTRB(gv_period_name, 6, 2)
    AND fb.cost                 > 0
    AND NOT EXISTS
          (SELECT
              fds.asset_id
             ,fds.deprn_reserve
           FROM
              fa_deprn_summary fds
             ,fa_deprn_periods fdp
           WHERE 1=1
           AND fds.asset_id       = fab.asset_id
           AND fds.period_counter = fdp.period_counter
           AND fds.book_type_code = fdp.book_type_code
           AND fds.book_type_code = gv_fixed_assets_books
           AND fdp.period_name    = gv_period_name)
    AND fab.tag_number          = xvoh.object_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD START
    AND xvoh.lease_class        = les_class_v.lease_class_code
-- 2014/11/07 Ver.1.1 Y.Shouji ADD END
    ;
--
    -- �����ݒ�
    gn_gloif_dr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END ins_gl_oif_dr;
--
  /**********************************************************************************
   * Procedure Name   : chk_je_vending_data_exist
   * Description      : �O��쐬�ςݎ��̋@�����d�󑶍݃`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_je_vending_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_je_vending_data_exist'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    -- ����
    ln_cnt_gloif  NUMBER; -- ��ʉ�vOIF
    ln_cnt_glhead NUMBER; -- �d��w�b�_
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    --======================================
    -- ��ʉ�vOIF ���݃`�F�b�N
    --======================================
    SELECT
      COUNT(gi.set_of_books_id)
    INTO
      ln_cnt_gloif
    FROM
      gl_interface    gi -- ��ʉ�vOIF
    WHERE
        gi.user_je_source_name = gv_je_src_vending
    AND gi.period_name         = gv_period_name
    ;
--
    IF ( NVL(ln_cnt_gloif,0) >= 1 ) THEN
      RAISE chk_cnt_gloif_expt;
    END IF;
--
    --======================================
    -- �d��w�b�_ ���݃`�F�b�N
    --======================================
    SELECT
      COUNT(gjh.je_header_id)
    INTO
      ln_cnt_glhead
    FROM
      gl_je_headers     gjh  -- �d��w�b�_
     ,gl_je_sources_tl  gjst -- �d��\�[�X
    WHERE
        gjh.je_source            = gjst.je_source_name
    AND gjst.language            = USERENV('LANG')
    AND gjst.user_je_source_name = gv_je_src_vending
    AND gjh.period_name          = gv_period_name
    ;
--
    IF ( NVL(ln_cnt_glhead,0) >= 1 ) THEN
      RAISE chk_cnt_glhead_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���̋@�����d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[�n���h�� ***
    WHEN chk_cnt_gloif_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_013  -- ���̋@�����d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���̋@�����d�󑶍݃`�F�b�N(�d��w�b�_)�G���[�n���h�� ***
    WHEN chk_cnt_glhead_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_014  -- ���̋@�����d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END chk_je_vending_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    -- ���Y�䒠��
    lv_book_type_code VARCHAR(100);
    -- ��v���ԃX�e�[�^�X
    lv_closing_status VARCHAR(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_cur
    IS
      SELECT
         fdp.deprn_run        AS deprn_run      -- �������p���s�t���O
        ,fdp.book_type_code   AS book_type_code -- ���Y�䒠��
      FROM
         fa_deprn_periods     fdp   -- �������p����
        ,fa_deprn_detail      fdd   -- �������p�ڍ׏��
      WHERE
          fdd.book_type_code  = gv_fixed_assets_books
      AND fdp.book_type_code  = fdd.book_type_code
      AND fdp.period_counter  = fdd.period_counter
      AND fdp.period_name     = gv_period_name
      ;
--
    -- *** ���[�J���E���R�[�h ***
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
    --======================================
    -- FA��v���ԃ`�F�b�N
    --======================================
    -- �J�[�\���I�[�v��
    OPEN period_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- �������p���s�t���O
                      ,g_book_type_code_tab -- ���Y�䒠��
    ;
    -- �J�[�\���N���[�Y
    CLOSE period_cur;
--
    -- ��v���Ԃ̎擾�������[�����˃G���[
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- �������p�����s����Ă��Ȃ��˃G���[
      IF NVL(g_deprn_run_tab(ln_loop_cnt),'N') <> 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
    --======================================
    -- GL��v���ԃ`�F�b�N
    --======================================
    BEGIN
      -- ��v���ԃX�e�[�^�X�擾
      SELECT
        gps.closing_status
      INTO
        lv_closing_status
      FROM
         fa_book_controls    fbc   -- ���Y�䒠�}�X�^
        ,gl_sets_of_books    gsob  -- ��v����}�X�^
        ,gl_periods          gp    -- ��v�J�����_
        ,gl_period_statuses  gps   -- ��v�J�����_�X�e�[�^�X
        ,fnd_application     fa    -- �A�v���P�[�V����
      WHERE
        EXISTS
          (SELECT
             'X'
           FROM
             fa_deprn_detail     fdd   -- �������p�ڍ׏��
           WHERE
               fdd.book_type_code = gv_fixed_assets_books
           AND fdd.book_type_code = fbc.book_type_code)
        AND fbc.set_of_books_id        = gsob.set_of_books_id
        AND gsob.period_set_name       = gp.period_set_name
        AND gp.period_name             = gv_period_name
        AND gsob.set_of_books_id       = gps.set_of_books_id
        AND gps.period_name            = gp.period_name
        AND gps.application_id         = fa.application_id
        AND fa.application_short_name  = 'SQLGL'
        AND gps.adjustment_period_flag = 'N'
      ;
--
      -- ��v���ԃX�e�[�^�X�擾
      IF ( lv_closing_status NOT IN ('O', 'F') ) THEN
        RAISE chk_gl_period_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE chk_gl_period_expt;
    END;
  EXCEPTION
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type       -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- ���Y�䒠��
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** GL��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_gl_period_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_012  -- GL��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    -- XXCFF:��ЃR�[�h_�{��
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:��ЃR�[�h_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�d��\�[�X_���̋@����
    gv_je_src_vending := FND_PROFILE.VALUE(cv_je_src_vending);
    IF (gv_je_src_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:�d��\�[�X_���̋@����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�d��J�e�S��_���̋@�������p�U��
    gv_je_cat_vending := FND_PROFILE.VALUE(cv_je_cat_vending);
    IF (gv_je_cat_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:�d��J�e�S��_���̋@�������p�U��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:����R�[�h_��������
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_013) -- XXCFF:����R�[�h_��������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠��
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_014) -- XXCFF:�䒠��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�`�[�ԍ�_���[�X
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_015) -- XXCFF:�`�[�ԍ�_���[�X
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:����Ȗ�_���̋@���[�X��
    gv_account_vending := FND_PROFILE.VALUE(cv_account_vending);
    IF (gv_account_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:����Ȗ�_���̋@���[�X��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�⏕�Ȗ�_���̋@
    gv_sub_account_vending := FND_PROFILE.VALUE(cv_sub_account_vending);
    IF (gv_sub_account_vending IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:�⏕�Ȗ�_���̋@
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���[�X����
    gv_lease_rate := FND_PROFILE.VALUE(cv_lease_rate);
    IF (gv_lease_rate IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_018) -- XXCFF:���[�X����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���[�X�����̐��l�`�F�b�N
    BEGIN
      gn_lease_rate := TO_NUMBER(gv_lease_rate);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_013a20_m_017) -- ���[�X�������l�`�F�b�N�G���[
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    ld_base_date  date;         --���
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
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --===========================================
    -- ���[�U���(���O�C�����[�U�A��������)�擾
    --===========================================
    BEGIN
      SELECT
         xuv.user_name   --���O�C�����[�U
        ,ppf.attribute28 --�N�[���� (��������)
      INTO
         gt_login_user_name
        ,gt_login_dept_code
      FROM
         xx03_users_v xuv
        ,per_people_f ppf
      WHERE
          xuv.user_id     = cn_created_by
      AND xuv.employee_id = ppf.person_id
      AND SYSDATE
          BETWEEN ppf.effective_start_date
              AND ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_login_info_expt;
    END;
--
    --===========================================
    -- ��v���떼�̎擾
    --===========================================
    BEGIN
      SELECT
        gsob.name   --��v���떼
      INTO
        gt_sob_name
      FROM
        gl_sets_of_books gsob
      WHERE
        gsob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_sob_name_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���[�U���(���O�C�����[�U�A��������)�擾�G���[�n���h�� ***
    WHEN get_login_info_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- �擾�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                     ,cv_msg_013a20_t_019  -- ���O�C��(���[�U��,��������)���
                                                     ,cv_tkn_key_name      -- �g�[�N��'KEY_NAME'
                                                     ,cv_msg_013a20_t_021  -- ���O�C�����[�UID=
                                                     ,cv_tkn_key_val       -- �g�[�N��'KEY_VAL'
                                                     ,cn_created_by)       -- ���O�C�����[�UID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ��v���떼�擾�G���[�n���h�� ***
    WHEN get_sob_name_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_016         -- �擾�G���[
                                                     ,cv_tkn_table                -- �g�[�N��'TABLE_NAME'
                                                     ,cv_msg_013a20_t_020         -- ��v���떼
                                                     ,cv_tkn_key_name             -- �g�[�N��'KEY_NAME'
                                                     ,cv_msg_013a20_t_022         -- ��v����ID=
                                                     ,cv_tkn_key_val              -- �g�[�N��'KEY_VAL'
                                                     ,g_init_rec.set_of_books_id) -- ��v����ID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- �O���[�o���ϐ��̏�����
    gn_warn_cnt              := 0;
    gn_gloif_dr_target_cnt   := 0;
    gn_gloif_cr_target_cnt   := 0;
    gn_gloif_normal_cnt      := 0;
    gn_gloif_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �O��쐬�ςݎ��̋@�����d�󑶍݃`�F�b�N (A-4)
    -- ============================================
    chk_je_vending_data_exist(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF�o�^����(�ؕ��f�[�^) (A-5)
    -- ====================================
    ins_gl_oif_dr(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF�o�^����(�ݕ��f�[�^) (A-6)
    -- ====================================
    ins_gl_oif_cr(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       -- 1.��v���Ԗ�
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
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --���펞�̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode = cv_status_normal) THEN
      -- �Ώی����𐬌������ɐݒ肷��
      gn_gloif_normal_cnt      := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    --===============================================================
    --�G���[���̏o�͌����ݒ�
    --===============================================================
    ELSE
      -- �����������[���ɃN���A����
      gn_gloif_normal_cnt      := 0;
      -- �G���[�����ɑΏی�����ݒ肷��
      gn_gloif_error_cnt       := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    END IF;
--
    --===============================================================
    --��ʉ�vOIF�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̋@�����d��쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
END XXCFF017A05C;
/
