CREATE OR REPLACE PACKAGE BODY XXCCP009A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A08C(body)
 * Description      : GL�d�󖾍ׁi���|�������j�擾
 * MD.070           : GL�d�󖾍ׁi���|�������j�擾 (MD070_IPO_CCP_009_A08)
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
 *  2014/12/16     1.0  SCSK K.Nakatsu   [E_�{�ғ�_12777]�V�K�쐬
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
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP009A08C'; -- �p�b�P�[�W��
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
    iv_period_name  IN  VARCHAR2,     --   ��v����
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
    -- GL�d�󖾍ׁi���|�������j�擾
    CURSOR artrx_glv_cur
      IS
        SELECT artrx_glv.*
        FROM
          (
          SELECT 
                /*+
                    LEADING(rctlgda rcta gjl gcc)
                    USE_NL (rctlgda rcta)
                    USE_NL (rcta gjl)
                    USE_NL (gjl gcc)
                    INDEX  (rctlgda ra_cust_trx_line_gl_dist_n2)
                    INDEX  (rcta    ra_customer_trx_u1)
                    INDEX  (gjl     gl_je_lines_n3)
                    INDEX  (gcc     gl_code_combinations_u1)
                 */
                 rcta.trx_number                                                AS trx_number             -- ����ԍ�
                ,rcta.cust_trx_type_id                                          AS cust_trx_type_id       -- ����^�C�vID
                ,(SELECT rctta.name
                  FROM ra_cust_trx_types_all rctta
                  WHERE rcta.cust_trx_type_id = rctta.cust_trx_type_id)         AS trx_type               -- ����^�C�v
                ,TO_CHAR(rcta.trx_date,'YYYY/MM/DD')                            AS trx_date               -- �����
                ,TO_CHAR(rctlgda.gl_date,'YYYY/MM/DD')                          AS gl_date                -- ���GL�L����
                ,rcta.bill_to_customer_id                                       AS bill_to_customer_id    -- ������ڋqID
                ,(SELECT hca.account_number
                  FROM hz_cust_accounts hca
                  WHERE rcta.bill_to_customer_id = hca.cust_account_id)         AS bill_to_account_number -- ������ڋq�ԍ�
                ,(SELECT hp.party_name
                  FROM hz_cust_accounts hca
                      ,hz_parties hp
                  WHERE rcta.bill_to_customer_id = hca.cust_account_id
                    AND hca.party_id             = hp.party_id)                 AS bill_to_party_name     -- ������ڋq��
                ,rcta.ship_to_customer_id                                       AS ship_to_customer_id    -- �o�א�ڋqID
                ,(SELECT hca.account_number
                  FROM hz_cust_accounts hca
                  WHERE rcta.ship_to_customer_id = hca.cust_account_id)         AS ship_to_account_number -- �o�א�ڋq�ԍ�
                ,(SELECT hp.party_name
                  FROM hz_cust_accounts hca
                      ,hz_parties hp
                  WHERE rcta.ship_to_customer_id = hca.cust_account_id
                    AND hca.party_id             = hp.party_id)                 AS ship_to_party_name     -- �o�א�ڋq��
                ,rcta.term_id                                                   AS term_id                -- �x������ID
                ,(SELECT rt.description
                  FROM ra_terms rt
                  WHERE rcta.term_id = rt.term_id)                              AS term_description       -- �x������
                ,rcta.interface_header_context                                  AS if_header_context      -- IF�w�b�_�R���e�L�X�g
              --
               ,(SELECT gjc.user_je_category_name
                 FROM gl_je_headers    gjh
                     ,gl_je_categories gjc
                 WHERE gjl.je_header_id     = gjh.je_header_id
                 AND   gjc.je_category_name = gjh.je_category
                 AND ROWNUM = 1)                                                AS user_je_category_name  -- �J�e�S����
               ,(SELECT gjs.user_je_source_name
                 FROM gl_je_headers    gjh
                     ,gl_je_sources    gjs
                 WHERE gjl.je_header_id     = gjh.je_header_id
                 AND   gjs.je_source_name   = gjh.je_source
                 AND ROWNUM = 1)                                                AS user_je_source_name    -- �\�[�X��
               ,gcc.code_combination_id
               ,gcc.segment1
               ,(SELECT a.aff_company_name
                 FROM xxcff_aff_company_v a
                 WHERE gcc.segment1 = a.aff_company_code)                       AS seg1name
               ,gcc.segment2
               ,(SELECT a.aff_department_name
                 FROM xxcff_aff_department_v a
                 WHERE gcc.segment2 = a.aff_department_code)                    AS seg2name
               ,gcc.segment3
               ,(SELECT a.aff_account_name
                 FROM xxcff_aff_account_v a
                 WHERE gcc.segment3 = a.aff_account_code)                       AS seg3name
               ,gcc.segment4
               ,(SELECT a.aff_sub_account_name
                 FROM xxcff_aff_sub_account_v a
                 WHERE gcc.segment4 = a.aff_sub_account_code
                 AND gcc.segment3   = a.aff_account_name)                       AS seg4name
               ,gcc.segment5
               ,(SELECT a.aff_partner_name
                 FROM xxcff_aff_partner_v a
                 WHERE gcc.segment5 = a.aff_partner_code)                       AS seg5name
               ,gcc.segment6
               ,(SELECT a.aff_business_type_name
                 FROM xxcff_aff_business_type_v a
                 WHERE gcc.segment6 = a.aff_business_type_code)                 AS seg6name
               ,gcc.segment7
               ,(SELECT a.aff_project_name
                 FROM xxcff_aff_project_v a
                 WHERE gcc.segment7 = a.aff_project_code)                       AS seg7name
               ,gcc.segment8
               ,(SELECT a.aff_future_name
                 FROM xxcff_aff_future_v a
                 WHERE gcc.segment8 = a.aff_future_code)                        AS seg8name
               ,gcc.detail_posting_allowed_flag                                 AS detail_posting_allowed_flag
               ,gcc.detail_budgeting_allowed_flag                               AS detail_budgeting_allowed_flag
               ,gcc.account_type                                                AS account_type
               ,gcc.enabled_flag                                                AS enabled_flag
               ,gjl.je_header_id                                                AS je_header_id
               ,gjl.je_line_num                                                 AS je_line_num
               ,gjl.last_update_date                                            AS last_update_date
               ,gjl.period_name                                                 AS period_name
               ,gjl.effective_date                                              AS effective_date
               ,gjl.status                                                      AS status
               ,gjl.accounted_dr                                                AS accounted_dr
               ,gjl.accounted_cr                                                AS accounted_cr
               ,gjl.description                                                 AS description
               ,gjl.reference_1                                                 AS reference_1
               ,gjl.reference_2                                                 AS reference_2
               ,gjl.reference_3                                                 AS reference_3
               ,gjl.reference_4                                                 AS reference_4
               ,gjl.reference_5                                                 AS reference_5
               ,gjl.attribute1                                                  AS attribute1
               ,gjl.attribute2                                                  AS attribute2
               ,gjl.attribute3                                                  AS attribute3
               ,gjl.attribute4                                                  AS attribute4
               ,gjl.attribute5                                                  AS attribute5
               ,gjl.attribute6                                                  AS attribute6
               ,gjl.invoice_date                                                AS invoice_date
               ,gjl.tax_code                                                    AS tax_code
               ,gjl.invoice_identifier                                          AS invoice_identifier
               ,gjl.invoice_amount                                              AS invoice_amount
               ,gjl.no1                                                         AS no1
               ,gjl.stat_amount                                                 AS stat_amount
               ,gjl.ignore_rate_flag                                            AS ignore_rate_flag
               ,gjl.context3                                                    AS context3
               ,gjl.ussgl_transaction_code                                      AS ussgl_transaction_code
               ,gjl.subledger_doc_sequence_id                                   AS subledger_doc_sequence_id
               ,gjl.context4                                                    AS context4
               ,gjl.subledger_doc_sequence_value                                AS subledger_doc_sequence_value
               ,gjl.reference_6                                                 AS reference_6
               ,gjl.reference_7                                                 AS reference_7
               ,gjl.gl_sl_link_id                                               AS gl_sl_link_id
               ,gjl.gl_sl_link_table                                            AS gl_sl_link_table
               ,gjl.reference_8                                                 AS reference_8
               ,gjl.reference_9                                                 AS reference_9
               ,gjl.reference_10                                                AS reference_10
               ,gjl.tax_document_identifier                                     AS tax_document_identifier
               ,gjl.tax_document_date                                           AS tax_document_date
               ,gjl.tax_customer_name                                           AS tax_customer_name
               ,gjl.tax_customer_reference                                      AS tax_customer_reference
               ,gjl.tax_registration_number                                     AS tax_registration_number
               ,gjl.tax_line_flag                                               AS tax_line_flag
               ,gjl.tax_group_id                                                AS tax_group_id
          FROM
                ra_cust_trx_line_gl_dist_all rctlgda --����z���e�[�u��
               ,ra_customer_trx_all          rcta    --����w�b�_�e�[�u��
               ,gl_je_lines                  gjl     --�d�󖾍׃e�[�u��
               ,gl_code_combinations         gcc     --����Ȗڑg�ݍ��킹�}�X�^
          WHERE 1=1
          AND rctlgda.gl_date BETWEEN TO_DATE(iv_period_name, 'YYYY-MM')
                                  AND ADD_MONTHS(TO_DATE(iv_period_name, 'YYYY-MM'),1) -1
          AND rctlgda.customer_trx_id    = rcta.customer_trx_id
          AND rcta.doc_sequence_value    = gjl.subledger_doc_sequence_value
          AND rcta.doc_sequence_id       = gjl.subledger_doc_sequence_id
          AND gjl.code_combination_id    = gcc.code_combination_id
          AND rctlgda.account_class      = 'REC'          --�z���^�C�v�����s
          ) artrx_glv
        WHERE 1=1
        AND artrx_glv.reference_9 <> 'INV_REC'          -- ���|�Ǘ��ȊO
        AND artrx_glv.segment3    IN ('11305','14500')  -- ����Ȗځ����|���A��������
        ;
    -- ���R�[�h�^
    artrx_glv_rec  artrx_glv_cur%ROWTYPE;
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- init��
    -- ===============================
    -- ���p�����[�^�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�Ώۊ���: ' || iv_period_name
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    -- ���e�����ŕK�v�ȃv���t�@�C���l�A�N�C�b�N�R�[�h�l���Œ�l�Őݒ�
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- ���ږ��o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"����ԍ�","����^�C�vID","����^�C�v","�����","���GL�L����","������ڋqID","������ڋq�ԍ�","������ڋq��","�o�א�ڋqID","�o�א�ڋq�ԍ�","�o�א�ڋq��","�x������ID","�x������","IF�w�b�_�R���e�L�X�g","�J�e�S����","�\�[�X��","CODE_COMBINATION_ID","SEGMENT1","SEG1NAME","SEGMENT2","SEG2NAME","SEGMENT3","SEG3NAME","SEGMENT4","SEG4NAME","SEGMENT5","SEG5NAME","SEGMENT6","SEG6NAME","SEGMENT7","SEG7NAME","SEGMENT8","SEG8NAME","DETAIL_POSTING_ALLOWED_FLAG","DETAIL_BUDGETING_ALLOWED_FLAG","ACCOUNT_TYPE","ENABLED_FLAG","JE_HEADER_ID","JE_LINE_NUM","LAST_UPDATE_DATE","PERIOD_NAME","EFFECTIVE_DATE","STATUS","ACCOUNTED_DR","ACCOUNTED_CR","DESCRIPTION","REFERENCE_1","REFERENCE_2","REFERENCE_3","REFERENCE_4","REFERENCE_5","ATTRIBUTE1","ATTRIBUTE2","ATTRIBUTE3","ATTRIBUTE4","ATTRIBUTE5","ATTRIBUTE6","INVOICE_DATE","TAX_CODE","INVOICE_IDENTIFIER","INVOICE_AMOUNT","NO1","STAT_AMOUNT","IGNORE_RATE_FLAG","CONTEXT3","USSGL_TRANSACTION_CODE","SUBLEDGER_DOC_SEQUENCE_ID","CONTEXT4","SUBLEDGER_DOC_SEQUENCE_VALUE","REFERENCE_6","REFERENCE_7","GL_SL_LINK_ID","GL_SL_LINK_TABLE","REFERENCE_8","REFERENCE_9","REFERENCE_10","TAX_DOCUMENT_IDENTIFIER","TAX_DOCUMENT_DATE","TAX_CUSTOMER_NAME","TAX_CUSTOMER_REFERENCE","TAX_REGISTRATION_NUMBER","TAX_LINE_FLAG","TAX_GROUP_ID"'
    );
    -- �f�[�^���o��(CSV)
    FOR artrx_glv_rec IN artrx_glv_cur
     LOOP
       --�����Z�b�g
       gn_target_cnt := gn_target_cnt + 1;
       --�ύX���鍀�ڋy�уL�[�����o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| artrx_glv_rec.trx_number                                          || '","'
                       || artrx_glv_rec.cust_trx_type_id                                    || '","'
                       || artrx_glv_rec.trx_type                                            || '","'
                       || artrx_glv_rec.trx_date                                            || '","'
                       || artrx_glv_rec.gl_date                                             || '","'
                       || artrx_glv_rec.bill_to_customer_id                                 || '","'
                       || artrx_glv_rec.bill_to_account_number                              || '","'
                       || artrx_glv_rec.bill_to_party_name                                  || '","'
                       || artrx_glv_rec.ship_to_customer_id                                 || '","'
                       || artrx_glv_rec.ship_to_account_number                              || '","'
                       || artrx_glv_rec.ship_to_party_name                                  || '","'
                       || artrx_glv_rec.term_id                                             || '","'
                       || artrx_glv_rec.term_description                                    || '","'
                       || artrx_glv_rec.if_header_context                                   || '","'
                       || artrx_glv_rec.user_je_category_name                               || '","'
                       || artrx_glv_rec.user_je_source_name                                 || '","'
                       || artrx_glv_rec.code_combination_id                                 || '","'
                       || artrx_glv_rec.segment1                                            || '","'
                       || artrx_glv_rec.seg1name                                            || '","'
                       || artrx_glv_rec.segment2                                            || '","'
                       || artrx_glv_rec.seg2name                                            || '","'
                       || artrx_glv_rec.segment3                                            || '","'
                       || artrx_glv_rec.seg3name                                            || '","'
                       || artrx_glv_rec.segment4                                            || '","'
                       || artrx_glv_rec.seg4name                                            || '","'
                       || artrx_glv_rec.segment5                                            || '","'
                       || artrx_glv_rec.seg5name                                            || '","'
                       || artrx_glv_rec.segment6                                            || '","'
                       || artrx_glv_rec.seg6name                                            || '","'
                       || artrx_glv_rec.segment7                                            || '","'
                       || artrx_glv_rec.seg7name                                            || '","'
                       || artrx_glv_rec.segment8                                            || '","'
                       || artrx_glv_rec.seg8name                                            || '","'
                       || artrx_glv_rec.detail_posting_allowed_flag                         || '","'
                       || artrx_glv_rec.detail_budgeting_allowed_flag                       || '","'
                       || artrx_glv_rec.account_type                                        || '","'
                       || artrx_glv_rec.enabled_flag                                        || '","'
                       || artrx_glv_rec.je_header_id                                        || '","'
                       || artrx_glv_rec.je_line_num                                         || '","'
                       || TO_CHAR(artrx_glv_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS')  || '","'
                       || artrx_glv_rec.period_name                                         || '","'
                       || TO_CHAR(artrx_glv_rec.effective_date, 'YYYY/MM/DD HH24:MI:SS')    || '","'
                       || artrx_glv_rec.status                                              || '","'
                       || artrx_glv_rec.accounted_dr                                        || '","'
                       || artrx_glv_rec.accounted_cr                                        || '","'
                       || artrx_glv_rec.description                                         || '","'
                       || artrx_glv_rec.reference_1                                         || '","'
                       || artrx_glv_rec.reference_2                                         || '","'
                       || artrx_glv_rec.reference_3                                         || '","'
                       || artrx_glv_rec.reference_4                                         || '","'
                       || artrx_glv_rec.reference_5                                         || '","'
                       || artrx_glv_rec.attribute1                                          || '","'
                       || artrx_glv_rec.attribute2                                          || '","'
                       || artrx_glv_rec.attribute3                                          || '","'
                       || artrx_glv_rec.attribute4                                          || '","'
                       || artrx_glv_rec.attribute5                                          || '","'
                       || artrx_glv_rec.attribute6                                          || '","'
                       || TO_CHAR(artrx_glv_rec.invoice_date, 'YYYY/MM/DD HH24:MI:SS')      || '","'
                       || artrx_glv_rec.tax_code                                            || '","'
                       || artrx_glv_rec.invoice_identifier                                  || '","'
                       || artrx_glv_rec.invoice_amount                                      || '","'
                       || artrx_glv_rec.no1                                                 || '","'
                       || artrx_glv_rec.stat_amount                                         || '","'
                       || artrx_glv_rec.ignore_rate_flag                                    || '","'
                       || artrx_glv_rec.context3                                            || '","'
                       || artrx_glv_rec.ussgl_transaction_code                              || '","'
                       || artrx_glv_rec.subledger_doc_sequence_id                           || '","'
                       || artrx_glv_rec.context4                                            || '","'
                       || artrx_glv_rec.subledger_doc_sequence_value                        || '","'
                       || artrx_glv_rec.reference_6                                         || '","'
                       || artrx_glv_rec.reference_7                                         || '","'
                       || artrx_glv_rec.gl_sl_link_id                                       || '","'
                       || artrx_glv_rec.gl_sl_link_table                                    || '","'
                       || artrx_glv_rec.reference_8                                         || '","'
                       || artrx_glv_rec.reference_9                                         || '","'
                       || artrx_glv_rec.reference_10                                        || '","'
                       || artrx_glv_rec.tax_document_identifier                             || '","'
                       || TO_CHAR(artrx_glv_rec.tax_document_date, 'YYYY/MM/DD HH24:MI:SS') || '","'
                       || artrx_glv_rec.tax_customer_name                                   || '","'
                       || artrx_glv_rec.tax_customer_reference                              || '","'
                       || artrx_glv_rec.tax_registration_number                             || '","'
                       || artrx_glv_rec.tax_line_flag                                       || '","'
                       || artrx_glv_rec.tax_group_id                                        || '"'
       );
    END LOOP;
--
    -- �����������Ώی���
    gn_normal_cnt  := gn_target_cnt;
    -- �Ώی���=0�ł���Όx��
    IF (gn_target_cnt = 0) THEN
      gn_warn_cnt    := 1;
      ov_retcode     := cv_status_warn;
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name  IN  VARCHAR2       --   ��v����
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
       iv_period_name -- ��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := 1;
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
END XXCCP009A08C;
/
