CREATE OR REPLACE PACKAGE BODY APPS.XXCCP007A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP007A08C(body)
 * Description      : �o��Z�������R�f�[�^�o��
 * MD.070           : �o��Z�������R�f�[�^�o�� (MD070_IPO_CCP_007_A08)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/12/02    1.0   Y.Shoji          [E_�{�ғ�_13393]�V�K�쐬
 *  2015/12/16    1.1   Y.Shoji          [E_�{�ғ�_13393]����e�X�g��Q�Ή�
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP007A08C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_gl_date_from       IN  VARCHAR2      --    1.GL�L���� FROM
   ,iv_gl_date_to         IN  VARCHAR2      --    2.GL�L���� TO
   ,iv_department_code    IN  VARCHAR2      --    3.����R�[�h
   ,iv_segment3_code1     IN  VARCHAR2      --    4.�o��ȖڃR�[�h�P
   ,iv_segment3_code2     IN  VARCHAR2      --    5.�o��ȖڃR�[�h�Q
   ,iv_segment3_code3     IN  VARCHAR2      --    6.�o��ȖڃR�[�h�R
   ,iv_segment3_code4     IN  VARCHAR2      --    7.�o��ȖڃR�[�h�S
   ,iv_segment3_code5     IN  VARCHAR2      --    8.�o��ȖڃR�[�h�T
   ,iv_segment3_code6     IN  VARCHAR2      --    9.�o��ȖڃR�[�h�U
   ,iv_segment3_code7     IN  VARCHAR2      --   10.�o��ȖڃR�[�h�V
   ,iv_segment3_code8     IN  VARCHAR2      --   11.�o��ȖڃR�[�h�W
   ,iv_segment3_code9     IN  VARCHAR2      --   12.�o��ȖڃR�[�h�X
   ,iv_segment3_code10    IN  VARCHAR2      --   13.�o��ȖڃR�[�h�P�O
   ,ov_errbuf             OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- �p�����[�^�Ȃ�
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
-- 2015.12.15 Ver1.1 Add Start
    cv_invoice_num_oie      CONSTANT VARCHAR2(4)  := 'OIE%';               -- �]�ƈ��o��Z
-- 2015.12.15 Ver1.1 Add End
--
    -- *** ���[�J���ϐ� ***
--
    --==================================================
    -- �o�͗p����
    --==================================================
    lv_period_name               ap.ap_invoice_distributions_all.period_name%TYPE               DEFAULT NULL;  -- ��v����
    lv_gl_date                   VARCHAR2(10)                                                   DEFAULT NULL;  -- GL�L����
    lv_account_code              gl.gl_code_combinations.segment3%TYPE                          DEFAULT NULL;  -- ����Ȗځi�z���j
    lv_account_name              applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- ����Ȗږ�
    lv_sub_account_code          gl.gl_code_combinations.segment4%TYPE                          DEFAULT NULL;  -- �⏕�Ȗځi�z���j
    lv_sub_account_name          applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- �⏕�Ȗږ�
    lv_issued_department_code    ap.ap_invoices_all.attribute3%TYPE                             DEFAULT NULL;  -- �N�[����
    lv_department_code           gl.gl_code_combinations.segment2%TYPE                          DEFAULT NULL;  -- ����i�z���j
    lv_department_name           applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- ���喼�i�z���j
    lv_invoice_num               ap.ap_invoices_all.invoice_num%TYPE                            DEFAULT NULL;  -- �������ԍ�
    lv_invoice_amount            VARCHAR2(15)                                                   DEFAULT NULL;  -- ���������z
    lv_amount                    VARCHAR2(15)                                                   DEFAULT NULL;  -- �z�����z
    lv_description               ap.ap_invoices_all.description%TYPE                            DEFAULT NULL;  -- �������E�v
    lv_dist_description          ap.ap_invoice_distributions_all.description%TYPE               DEFAULT NULL;  -- �������z���E�v
    lv_justification             ap.ap_invoice_distributions_all.justification%TYPE             DEFAULT NULL;  -- �o������R
    lv_vendor_name               po.po_vendors.vendor_name%TYPE                                 DEFAULT NULL;  -- �d���於
    lv_vendor_code               po.po_vendors.segment1%TYPE                                    DEFAULT NULL;  -- �d����R�[�h
    lv_partner_code              gl.gl_code_combinations.segment5%TYPE                          DEFAULT NULL;  -- �ڋq�R�[�h�i�z���j
    lv_partner_name              applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- �ڋq�R�[�h��
    lv_business_type_code        gl.gl_code_combinations.segment6%TYPE                          DEFAULT NULL;  -- ��ƃR�[�h�i�z���j
    lv_business_type_name        applsys.fnd_flex_values_tl.description%TYPE                    DEFAULT NULL;  -- ��ƃR�[�h��
    lv_pay_group                 ap.ap_invoices_all.pay_group_lookup_code%TYPE                  DEFAULT NULL;  -- �x���O���[�v
    lv_pay_curr_invoice_amount   VARCHAR2(15)                                                   DEFAULT NULL;  -- �x���ϊz
    lv_due_date                  VARCHAR2(10)                                                   DEFAULT NULL;  -- �x������
    lv_payment_status_flag       ap.ap_payment_schedules_all.payment_status_flag%TYPE           DEFAULT NULL;  -- �x���X�e�[�^�X
    lv_hold_flag                 ap.ap_payment_schedules_all.hold_flag%TYPE                     DEFAULT NULL;  -- �x���\��ۗ��t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �o��Z�f�[�^���R�[�h�擾
    CURSOR main_cur( iv_gl_date_from    IN VARCHAR2   --    1.GL�L���� FROM
                    ,iv_gl_date_to      IN VARCHAR2   --    2.GL�L���� TO
                    ,iv_department_code IN VARCHAR2   --    3.����R�[�h
                    ,iv_segment3_code1  IN VARCHAR2   --    4.�o��ȖڃR�[�h�P
                    ,iv_segment3_code2  IN VARCHAR2   --    5.�o��ȖڃR�[�h�Q
                    ,iv_segment3_code3  IN VARCHAR2   --    6.�o��ȖڃR�[�h�R
                    ,iv_segment3_code4  IN VARCHAR2   --    7.�o��ȖڃR�[�h�S
                    ,iv_segment3_code5  IN VARCHAR2   --    8.�o��ȖڃR�[�h�T
                    ,iv_segment3_code6  IN VARCHAR2   --    9.�o��ȖڃR�[�h�U
                    ,iv_segment3_code7  IN VARCHAR2   --   10.�o��ȖڃR�[�h�V
                    ,iv_segment3_code8  IN VARCHAR2   --   11.�o��ȖڃR�[�h�W
                    ,iv_segment3_code9  IN VARCHAR2   --   12.�o��ȖڃR�[�h�X
                    ,iv_segment3_code10 IN VARCHAR2   --   13.�o��ȖڃR�[�h�P�O
                   )
    IS
      SELECT
             aida.period_name                                  AS period_name               -- ��v����
            ,aia.gl_date                                       AS gl_date                   -- GL�L����
            ,gcc1.segment3                                     AS account_code              -- ����Ȗځi�z���j
            ,(SELECT a.aff_account_name        AS account_name
              FROM   apps.xxcff_aff_account_v a
              WHERE  gcc1.segment3 = a.aff_account_code)       AS account_name              -- ����Ȗږ�
            ,gcc1.segment4                                     AS sub_account_code          -- �⏕�Ȗځi�z���j
            ,(SELECT a.aff_sub_account_name    AS sub_account_name
              FROM   apps.xxcff_aff_sub_account_v a
              WHERE  gcc1.segment4 = a.aff_sub_account_code
              AND    gcc1.segment3 = a.aff_account_name)       AS sub_account_name          -- �⏕�Ȗږ�
            ,aia.attribute3                                    AS issued_department_code    -- �N�[����
            ,gcc1.segment2                                     AS department_code           -- ����i�z���j
            ,(SELECT a.aff_department_name     AS department_name
              FROM   apps.xxcff_aff_department_v a
              WHERE  gcc1.segment2 = a.aff_department_code)    AS department_name           -- ���喼�i�z���j
            ,aia.invoice_num                                   AS invoice_num               -- �������ԍ�
            ,aia.invoice_amount                                AS invoice_amount            -- ���������z
            ,aida.amount                                       AS amount                    -- �z�����z
            ,aia.description                                   AS description               -- �������E�v
            ,aida.description                                  AS dist_description          -- �������z���E�v
            ,aida.justification                                AS justification             -- �o������R
            ,pv.vendor_name                                    AS vendor_name               -- �d���於
            ,pv.segment1                                       AS vendor_code               -- �d����R�[�h
            ,gcc1.segment5                                     AS partner_code              -- �ڋq�R�[�h�i�z���j
            ,(SELECT a.aff_partner_name        AS partner_name
              FROM   apps.xxcff_aff_partner_v a
              WHERE  gcc1.segment5 = a.aff_partner_code)       AS partner_name              -- �ڋq�R�[�h��
            ,gcc1.segment6                                     AS business_type_code        -- ��ƃR�[�h�i�z���j
            ,(SELECT a.aff_business_type_name  AS business_type_name
              FROM   apps.xxcff_aff_business_type_v a
              WHERE  gcc1.segment6 = a.aff_business_type_code) AS business_type_name        -- ��ƃR�[�h��
            ,aia.pay_group_lookup_code                         AS pay_group                 -- �x���O���[�v
            ,aia.pay_curr_invoice_amount                       AS pay_curr_invoice_amount   -- �x���ϊz
            ,apsa.due_date                                     AS due_date                  -- �x������
            ,apsa.payment_status_flag                          AS payment_status_flag       -- �x���X�e�[�^�X
            ,apsa.hold_flag                                    AS hold_flag                 -- �x���\��ۗ��t���O
      FROM   apps.ap_invoices_all              aia    -- �������e�[�u��
            ,apps.ap_invoice_distributions_all aida   -- �������z���e�[�u��
            ,apps.fnd_lookup_values            flv1   -- �Q�ƕ\
            ,apps.ap_terms_tl                  att    -- �x�������e�[�u��
            ,apps.gl_code_combinations         gcc1   -- ����Ȗڑ̌n
            ,apps.ap_payment_schedules_all     apsa   -- �x���\��e�[�u��
            ,apps.po_vendors                   pv     -- �d����}�X�^
      WHERE  aia.invoice_id                    = aida.invoice_id
      AND    aia.set_of_books_id               = aida.set_of_books_id
      AND    aia.pay_group_lookup_code         = flv1.lookup_code
      AND    flv1.lookup_type                  = 'PAY GROUP'
      AND    flv1.view_application_id          = 201                                     -- PO
      AND    flv1.language                     = userenv('LANG')
      AND    aia.terms_id                      = att.term_id
      AND    flv1.language                     = att.language
      AND    aida.dist_code_combination_id     = gcc1.code_combination_id
      AND    aia.invoice_id                    = apsa.invoice_id
      AND    aia.org_id                        = apsa.org_id
      AND    aia.vendor_id                     = pv.vendor_id
-- 2015.12.15 Ver1.1 Add Start
      AND    aia.invoice_num                   LIKE cv_invoice_num_oie
-- 2015.12.15 Ver1.1 Add End
      AND    aia.gl_date                       BETWEEN TO_DATE(iv_gl_date_from ,'YYYY/MM/DD HH24:MI:SS')
                                               AND     TO_DATE(iv_gl_date_to   ,'YYYY/MM/DD HH24:MI:SS')
                                                                                           -- 1,2.GL�L���� �͈͎w��
      AND    aia.attribute3                    = NVL(iv_department_code , aia.attribute3)  -- 3.����R�[�h
      AND (
            ( iv_segment3_code1             IS NULL
          AND iv_segment3_code2             IS NULL
          AND iv_segment3_code3             IS NULL
          AND iv_segment3_code4             IS NULL
          AND iv_segment3_code5             IS NULL
          AND iv_segment3_code6             IS NULL
          AND iv_segment3_code7             IS NULL
          AND iv_segment3_code8             IS NULL
          AND iv_segment3_code9             IS NULL
          AND iv_segment3_code10            IS NULL
            )
        OR  ( gcc1.segment3                 IN ( iv_segment3_code1       -- 4.�o��ȖڃR�[�h�P
                                                ,iv_segment3_code2       -- 5.�o��ȖڃR�[�h�Q
                                                ,iv_segment3_code3       -- 6.�o��ȖڃR�[�h�R
                                                ,iv_segment3_code4       -- 7.�o��ȖڃR�[�h�S
                                                ,iv_segment3_code5       -- 8.�o��ȖڃR�[�h�T
                                                ,iv_segment3_code6       -- 9.�o��ȖڃR�[�h�U
                                                ,iv_segment3_code7       -- 10.�o��ȖڃR�[�h�V
                                                ,iv_segment3_code8       -- 11.�o��ȖڃR�[�h�W
                                                ,iv_segment3_code9       -- 12.�o��ȖڃR�[�h�X
                                                ,iv_segment3_code10      -- 13.�o��ȖڃR�[�h�P�O
                                               )
            )
          )
      ORDER BY aida.period_name  -- ��v����
              ,aia.gl_date       -- GL�L����
              ,gcc1.segment3     -- ����ȖڃR�[�h
              ,gcc1.segment4     -- �⏕�ȖڃR�[�h
              ,aia.attribute3    -- �N�[����R�[�h
              ,aia.invoice_num   -- �������ԍ�
      ;
    -- ���C���J�[�\�����R�[�h�^
    main_rec  main_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init��
    -- ===============================
    --==============================================================
    -- ���̓p�����[�^�o��
    --==============================================================
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => 'GL�L���� FROM      : ' || iv_gl_date_from
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => 'GL�L���� TO        : ' || iv_gl_date_to
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '����R�[�h         : ' || iv_department_code
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�P   : ' || iv_segment3_code1
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�Q   : ' || iv_segment3_code2
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�R   : ' || iv_segment3_code3
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�S   : ' || iv_segment3_code4
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�T   : ' || iv_segment3_code5
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�U   : ' || iv_segment3_code6
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�V   : ' || iv_segment3_code7
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�W   : ' || iv_segment3_code8
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�X   : ' || iv_segment3_code9
                     );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => '�o��ȖڃR�[�h�P�O : ' || iv_segment3_code10
                     );
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- GL�L����FROM > GL�L����TO �̏ꍇ
    IF ( TO_DATE( iv_gl_date_from, 'YYYY/MM/DD HH24:MI:SS' ) > TO_DATE( iv_gl_date_to, 'YYYY/MM/DD HH24:MI:SS' ) ) THEN
      ov_errbuf  := 'GL�L���� FROM �� GL�L���� TO �ȑO�̓��t���w�肵�ĉ������B';
      ov_retcode := cv_status_error;
    ELSE
--
      -- ===============================
      -- ������
      -- ===============================
--
      -- ���ږ��o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>           '"' || '��v����'                || '"' -- ��v����
                   || ',' || '"' || 'GL�L����'                || '"' -- GL�L����
                   || ',' || '"' || '����Ȗځi�z���j'        || '"' -- ����Ȗځi�z���j
                   || ',' || '"' || '����Ȗږ�'              || '"' -- ����Ȗږ�
                   || ',' || '"' || '�⏕�Ȗځi�z���j'        || '"' -- �⏕�Ȗځi�z���j
                   || ',' || '"' || '�⏕�Ȗږ�'              || '"' -- �⏕�Ȗږ�
                   || ',' || '"' || '�N�[����'                || '"' -- �N�[����
                   || ',' || '"' || '����i�z���j'            || '"' -- ����i�z���j
                   || ',' || '"' || '���喼�i�z���j'          || '"' -- ���喼�i�z���j
                   || ',' || '"' || '�������ԍ�'              || '"' -- �������ԍ�
                   || ',' || '"' || '���������z'              || '"' -- ���������z
                   || ',' || '"' || '�z�����z'                || '"' -- �z�����z
                   || ',' || '"' || '�������E�v'              || '"' -- �������E�v
                   || ',' || '"' || '�������z���E�v'          || '"' -- �������z���E�v
                   || ',' || '"' || '�o������R'            || '"' -- �o������R
                   || ',' || '"' || '�d���於'                || '"' -- �d���於
                   || ',' || '"' || '�d����R�[�h'            || '"' -- �d����R�[�h
                   || ',' || '"' || '�ڋq�R�[�h�i�z���j'      || '"' -- �ڋq�R�[�h�i�z���j
                   || ',' || '"' || '�ڋq�R�[�h��'            || '"' -- �ڋq�R�[�h��
                   || ',' || '"' || '��ƃR�[�h�i�z���j'      || '"' -- ��ƃR�[�h�i�z���j
                   || ',' || '"' || '��ƃR�[�h��'            || '"' -- ��ƃR�[�h��
                   || ',' || '"' || '�x���O���[�v'            || '"' -- �x���O���[�v
                   || ',' || '"' || '�x���ϊz'                || '"' -- �x���ϊz
                   || ',' || '"' || '�x������'                || '"' -- �x������
                   || ',' || '"' || '�x���X�e�[�^�X'          || '"' -- �x���X�e�[�^�X
                   || ',' || '"' || '�x���\��ۗ��t���O'      || '"' -- �x���\��ۗ��t���O
      );
      -- �f�[�^���o��(CSV)
      FOR main_rec IN main_cur( iv_gl_date_from       --    1.GL�L���� FROM
                               ,iv_gl_date_to         --    2.GL�L���� TO
                               ,iv_department_code    --    3.����R�[�h
                               ,iv_segment3_code1     --    4.�o��ȖڃR�[�h�P
                               ,iv_segment3_code2     --    5.�o��ȖڃR�[�h�Q
                               ,iv_segment3_code3     --    6.�o��ȖڃR�[�h�R
                               ,iv_segment3_code4     --    7.�o��ȖڃR�[�h�S
                               ,iv_segment3_code5     --    8.�o��ȖڃR�[�h�T
                               ,iv_segment3_code6     --    9.�o��ȖڃR�[�h�U
                               ,iv_segment3_code7     --   10.�o��ȖڃR�[�h�V
                               ,iv_segment3_code8     --   11.�o��ȖڃR�[�h�W
                               ,iv_segment3_code9     --   12.�o��ȖڃR�[�h�X
                               ,iv_segment3_code10    --   13.�o��ȖڃR�[�h�P�O
                               ) LOOP
        --�����Z�b�g
        gn_target_cnt := gn_target_cnt + 1;
--
        --==================================================
        -- �o�͗p���ڐݒ�
        --==================================================
        lv_period_name               := main_rec.period_name;                            -- ��v����
        lv_gl_date                   := TO_CHAR( main_rec.gl_date, 'YYYY/MM/DD' );       -- GL�L����
        lv_account_code              := main_rec.account_code;                           -- ����Ȗځi�z���j
        lv_account_name              := main_rec.account_name;                           -- ����Ȗږ�
        lv_sub_account_code          := main_rec.sub_account_code;                       -- �⏕�Ȗځi�z���j
        lv_sub_account_name          := main_rec.sub_account_name;                       -- �⏕�Ȗږ�
        lv_issued_department_code    := main_rec.issued_department_code;                 -- �N�[����
        lv_department_code           := main_rec.department_code;                        -- ����i�z���j
        lv_department_name           := main_rec.department_name;                        -- ���喼�i�z���j
        lv_invoice_num               := main_rec.invoice_num;                            -- �������ԍ�
        lv_invoice_amount            := TO_CHAR( main_rec.invoice_amount );              -- ���������z
        lv_amount                    := TO_CHAR( main_rec.amount );                      -- �z�����z
        lv_description               := main_rec.description;                            -- �������E�v
        lv_dist_description          := main_rec.dist_description;                       -- �������z���E�v
        lv_justification             := main_rec.justification;                          -- �o������R
        lv_vendor_name               := main_rec.vendor_name;                            -- �d���於
        lv_vendor_code               := main_rec.vendor_code;                            -- �d����R�[�h
        lv_partner_code              := main_rec.partner_code;                           -- �ڋq�R�[�h�i�z���j
        lv_partner_name              := main_rec.partner_name;                           -- �ڋq�R�[�h��
        lv_business_type_code        := main_rec.business_type_code;                     -- ��ƃR�[�h�i�z���j
        lv_business_type_name        := main_rec.business_type_name;                     -- ��ƃR�[�h��
        lv_pay_group                 := main_rec.pay_group;                              -- �x���O���[�v
        lv_pay_curr_invoice_amount   := TO_CHAR( main_rec.pay_curr_invoice_amount );     -- �x���ϊz
        lv_due_date                  := TO_CHAR( main_rec.due_date, 'YYYY/MM/DD' );      -- �x������
        lv_payment_status_flag       := main_rec.payment_status_flag;                    -- �x���X�e�[�^�X
        lv_hold_flag                 := main_rec.hold_flag;                              -- �x���\��ۗ��t���O
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => 
                               '"' || lv_period_name               || '"' -- ��v����
                     || ',' || '"' || lv_gl_date                   || '"' -- GL�L����
                     || ',' || '"' || lv_account_code              || '"' -- ����Ȗځi�z���j
                     || ',' || '"' || lv_account_name              || '"' -- ����Ȗږ�
                     || ',' || '"' || lv_sub_account_code          || '"' -- �⏕�Ȗځi�z���j
                     || ',' || '"' || lv_sub_account_name          || '"' -- �⏕�Ȗږ�
                     || ',' || '"' || lv_issued_department_code    || '"' -- �N�[����
                     || ',' || '"' || lv_department_code           || '"' -- ����i�z���j
                     || ',' || '"' || lv_department_name           || '"' -- ���喼�i�z���j
                     || ',' || '"' || lv_invoice_num               || '"' -- �������ԍ�
                     || ',' || '"' || lv_invoice_amount            || '"' -- ���������z
                     || ',' || '"' || lv_amount                    || '"' -- �z�����z
                     || ',' || '"' || lv_description               || '"' -- �������E�v
                     || ',' || '"' || lv_dist_description          || '"' -- �������z���E�v
                     || ',' || '"' || lv_justification             || '"' -- �o������R
                     || ',' || '"' || lv_vendor_name               || '"' -- �d���於
                     || ',' || '"' || lv_vendor_code               || '"' -- �d����R�[�h
                     || ',' || '"' || lv_partner_code              || '"' -- �ڋq�R�[�h�i�z���j
                     || ',' || '"' || lv_partner_name              || '"' -- �ڋq�R�[�h��
                     || ',' || '"' || lv_business_type_code        || '"' -- ��ƃR�[�h�i�z���j
                     || ',' || '"' || lv_business_type_name        || '"' -- ��ƃR�[�h��
                     || ',' || '"' || lv_pay_group                 || '"' -- �x���O���[�v
                     || ',' || '"' || lv_pay_curr_invoice_amount   || '"' -- �x���ϊz
                     || ',' || '"' || lv_due_date                  || '"' -- �x������
                     || ',' || '"' || lv_payment_status_flag       || '"' -- �x���X�e�[�^�X
                     || ',' || '"' || lv_hold_flag                 || '"' -- �x���\��ۗ��t���O
        );
      END LOOP;
--
      -- �����������Ώی���
      gn_normal_cnt  := gn_target_cnt;
      -- �Ώی���=0�ł���΃��b�Z�[�W�o��
      IF (gn_target_cnt = 0) THEN
       FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => CHR(10) || '�Ώۃf�[�^�͂���܂���B'
       );
      END IF;
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
    errbuf                OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_gl_date_from       IN  VARCHAR2      --    1.GL�L���� FROM
   ,iv_gl_date_to         IN  VARCHAR2      --    2.GL�L���� TO
   ,iv_department_code    IN  VARCHAR2      --    3.����R�[�h
   ,iv_segment3_code1     IN  VARCHAR2      --    4.�o��ȖڃR�[�h�P
   ,iv_segment3_code2     IN  VARCHAR2      --    5.�o��ȖڃR�[�h�Q
   ,iv_segment3_code3     IN  VARCHAR2      --    6.�o��ȖڃR�[�h�R
   ,iv_segment3_code4     IN  VARCHAR2      --    7.�o��ȖڃR�[�h�S
   ,iv_segment3_code5     IN  VARCHAR2      --    8.�o��ȖڃR�[�h�T
   ,iv_segment3_code6     IN  VARCHAR2      --    9.�o��ȖڃR�[�h�U
   ,iv_segment3_code7     IN  VARCHAR2      --   10.�o��ȖڃR�[�h�V
   ,iv_segment3_code8     IN  VARCHAR2      --   11.�o��ȖڃR�[�h�W
   ,iv_segment3_code9     IN  VARCHAR2      --   12.�o��ȖڃR�[�h�X
   ,iv_segment3_code10    IN  VARCHAR2      --   13.�o��ȖڃR�[�h�P�O
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
       iv_gl_date_from       --    1.GL�L���� FROM
      ,iv_gl_date_to         --    2.GL�L���� TO
      ,iv_department_code    --    3.����R�[�h
      ,iv_segment3_code1     --    4.�o��ȖڃR�[�h�P
      ,iv_segment3_code2     --    5.�o��ȖڃR�[�h�Q
      ,iv_segment3_code3     --    6.�o��ȖڃR�[�h�R
      ,iv_segment3_code4     --    7.�o��ȖڃR�[�h�S
      ,iv_segment3_code5     --    8.�o��ȖڃR�[�h�T
      ,iv_segment3_code6     --    9.�o��ȖڃR�[�h�U
      ,iv_segment3_code7     --   10.�o��ȖڃR�[�h�V
      ,iv_segment3_code8     --   11.�o��ȖڃR�[�h�W
      ,iv_segment3_code9     --   12.�o��ȖڃR�[�h�X
      ,iv_segment3_code10    --   13.�o��ȖڃR�[�h�P�O
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP007A08C;
/