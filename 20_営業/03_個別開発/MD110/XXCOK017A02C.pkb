CREATE OR REPLACE PACKAGE BODY XXCOK017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOK017A02C (body)
 * Description      : BM�{�U���Е��S��s�萔���̐U��
 * MD.050           : BM�{�U���Е��S��s�萔���̐U�� (MD050_COK_017A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������             (A-1)
 *  get_pmt_amt            �U���z���̎擾     (A-2)
 *                         ��s�萔������W�v   (A-3)
 *  create_cr_data         ����ʎd��̍쐬     (A-4)
 *  create_dr_data         �U�֌��d��̍쐬     (A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/06/13    1.0   T.Ishiwata       main�V�K�쐬
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
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK017A02C';      -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name          CONSTANT VARCHAR2(10)  := 'XXCCP';             -- XXCCP
  cv_appl_name_sqlgl          CONSTANT VARCHAR2(10)  := 'SQLGL';             -- SQLGL
  cv_appl_name_xxcok          CONSTANT VARCHAR2(10)  := 'XXCOK';             -- XXCOK
--
  -- ���b�Z�[�W�R�[�h
  cv_target_rec_msg           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';      -- �Ώی������b�Z�[�W
  cv_success_rec_msg          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';      -- �����������b�Z�[�W
  cv_error_rec_msg            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';      -- �G���[�������b�Z�[�W
  cv_normal_msg               CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';      -- ����I�����b�Z�[�W
  cv_error_msg                CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';      -- �G���[�I���S���[���o�b�N
  cv_no_parameter_msg         CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';      -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_cok_10496            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10496';      -- ���̓p�����[�^�o�̓��b�Z�[�W
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';      -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cok_00005            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00005';      -- �]�ƈ��擾�G���[���b�Z�[�W
  cv_msg_cok_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';      -- ��v���ԏ��擾�G���[���b�Z�[�W
  cv_msg_cok_00012            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00012';      -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cok_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';      -- �O���[�vID�擾�G���[���b�Z�[�W
  cv_msg_cok_00025            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';      -- �`�[�ԍ��擾�G���[���b�Z�[�W
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';      -- �Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_cok_00042            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';      -- ��v���Ԗ��I�[�v���G���[���b�Z�[�W
  cv_msg_cok_10497            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10497';      -- �v����������`�F�b�N
  cv_msg_cok_10498            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10498';      -- �U������s�x�XID�擾�G���[
  cv_msg_cok_10499            CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10499';      -- ��s�萔���̎擾�G���[
--
  -- *** �萔(�g�[�N��) ***
  cv_cnt_token                CONSTANT VARCHAR2(30)  := 'COUNT';             -- ����
  cv_tkn_proc_date            CONSTANT VARCHAR2(30)  := 'PROC_DATE';         -- �v���
  cv_tkn_profile              CONSTANT VARCHAR2(30)  := 'PROFILE';           -- �v���t�@�C����
  cv_tkn_user_id              CONSTANT VARCHAR2(30)  := 'USER_ID';           -- ���[�UID
  cv_tkn_bank_name            CONSTANT VARCHAR2(30)  := 'BANK_NAME';         -- ��s��
  cv_tkn_ank_branch           CONSTANT VARCHAR2(30)  := 'BANK_BRANCH';       -- ��s�x�X��
  cv_tkn_slp_code             CONSTANT VARCHAR2(30)  := 'SLIPPER_CODE';      -- �d����R�[�h
  cv_tkn_p_amt                CONSTANT VARCHAR2(30)  := 'P_AMT_TAX_SUM';     -- �U���z���v
--
  -- �v���t�@�C���E�I�v�V������
  cv_prof_org_id              CONSTANT VARCHAR2(50)  := 'ORG_ID';                              -- MO: �c�ƒP��
  cv_prof_setof_id            CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                    -- ��v����ID
  cv_prof_setof_name          CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_NAME';                  -- ��v���떼
  cv_prof_aff1_code           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';            -- ��ЃR�[�h
  cv_prof_aff2_fin            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_FIN';                -- ����R�[�h_�����o����
  cv_prof_aff2_adj            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_ADJ';                -- ����R�[�h_��������
  cv_prof_aff3_vdbm           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_VEND_SALES_COMMISSION';   -- ����Ȗ�_���̋@�̔��萔��
  cv_prof_aff3_fee            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_FEE';                     -- ����Ȗ�_�萔��
  cv_prof_aff4_trfee          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_TRANSFER_FEE';            -- �⏕�Ȗ�_�萔��_�U���萔��
  cv_prof_aff4_elec           CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_VEND_SALES_ELEC_COST';    -- �⏕�Ȗ�_���̋@�̔��萔��_���̓d�C��
  cv_prof_aff4_rebate         CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_VEND_SALES_REBATE';       -- �⏕�Ȗ�_���̋@�̔��萔��_���̃��x�[�g
  cv_prof_aff5_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';          -- �ڋq�R�[�h_�_�~�[�l
  cv_prof_aff6_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF6_COMPANY_DUMMY';           -- ��ƃR�[�h_�_�~�[�l
  cv_prof_aff7_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';      -- �\���R�[�h�P_�_�~�[�l
  cv_prof_aff8_dummy          CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';      -- �\���R�[�h�Q_�_�~�[�l
  cv_prof_gl_ctg_bm           CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_BM';               -- �d��J�e�S��_�̔��萔��
  cv_prof_gl_ctg_cng          CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_CNG';              -- �d��J�e�S��_�U�֓`�[
  cv_prof_gl_src_cok          CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_SOURCE_COK';                -- �d��\�[�X_�ʊJ��
  cv_prof_transf_bank         CONSTANT VARCHAR2(50)  := 'XXCOK1_TRANSFERRING_BANK';            -- �U������s��
  cv_prof_transf_bankb        CONSTANT VARCHAR2(50)  := 'XXCOK1_TRANSFERRING_BANK_BRANCH';     -- �U�����x�X��
  cv_prof_other_tax_code      CONSTANT VARCHAR2(50)  := 'XXCOK1_OTHER_TAX_CODE';               -- �ΏۊO����ŃR�[�h
  cv_prof_bm_tax_rate         CONSTANT VARCHAR2(50)  := 'XXCOK1_BM_TAX';                       -- �̔��萔��_����ŗ�
--
  -- ����
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- ��v���ԃX�e�[�^�X
  cv_closing_status_open      CONSTANT VARCHAR2(1)   := 'O';                -- �I�[�v��
  -- �d��X�e�[�^�X
  cv_je_status_new            CONSTANT VARCHAR2(3)   := 'NEW';              -- �V�K
  -- �c���^�C�v
  cv_balance_type_result      CONSTANT VARCHAR2(1)   := 'A';                -- ����
  -- �ʉ݃R�[�h
  cv_currency_code            CONSTANT VARCHAR2(3)   := 'JPY';              -- JPY(���{�~)
  -- �����N
  cn_rank_number              CONSTANT NUMBER        := 1;
  -- ��s�萔���}�X�^����
  cv_code_one                 CONSTANT VARCHAR2(3)   := 'ONE';              -- �����s/����x�X
  cv_code_other               CONSTANT VARCHAR2(5)   := 'OTHER';            -- ���̑���s
  cv_code_all                 CONSTANT VARCHAR2(3)   := 'ALL';              -- �S�x�X
--
  
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���������擾�l
  gd_process_date                  DATE                                  DEFAULT NULL;  -- �Ɩ��������t
  gd_gl_date                       DATE                                  DEFAULT NULL;  -- �v���
  gn_prof_org_id                   NUMBER                                DEFAULT NULL;  -- �c�ƒP��ID
  gn_prof_set_of_books_id          NUMBER                                DEFAULT NULL;  -- ��v����ID
  gv_prof_set_of_books_name        VARCHAR2(100)                         DEFAULT NULL;  -- ��v���떼
  gv_prof_aff1_company_code        VARCHAR2(100)                         DEFAULT NULL;  -- ��ЃR�[�h
  gv_prof_aff2_dept_fin            VARCHAR2(100)                         DEFAULT NULL;  -- ����R�[�h_�����o����
  gv_prof_aff2_dept_adj            VARCHAR2(100)                         DEFAULT NULL;  -- ����R�[�h_��������
  gv_prof_aff3_fee                 VARCHAR2(100)                         DEFAULT NULL;  -- ����Ȗ�_�萔��
  gv_prof_aff3_bm                  VARCHAR2(100)                         DEFAULT NULL;  -- ����Ȗ�_���̋@�̔��萔��
  gv_prof_aff4_transfer_fee        VARCHAR2(100)                         DEFAULT NULL;  -- �⏕�Ȗ�_�萔��_�U���萔��
  gv_prof_aff4_elec_cost           VARCHAR2(100)                         DEFAULT NULL;  -- �⏕�Ȗ�_���̋@�̔��萔��_���̓d�C��
  gv_prof_aff4_rebate              VARCHAR2(100)                         DEFAULT NULL;  -- �⏕�Ȗ�_���̋@�̔��萔��_���̃��x�[�g
  gv_prof_aff5_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- �ڋq�R�[�h_�_�~�[�l
  gv_prof_aff6_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- ��ƃR�[�h_�_�~�[�l
  gv_prof_aff7_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- �\���R�[�h�P_�_�~�[�l
  gv_prof_aff8_dummy               VARCHAR2(100)                         DEFAULT NULL;  -- �\���R�[�h�Q_�_�~�[�l
  gv_prof_gl_category_bm           VARCHAR2(100)                         DEFAULT NULL;  -- �d��J�e�S��_�̔��萔��
  gv_prof_gl_category_cng          VARCHAR2(100)                         DEFAULT NULL;  -- �d��J�e�S��_�U�֓`�[
  gv_prof_gl_source_cok            VARCHAR2(100)                         DEFAULT NULL;  -- �d��\�[�X_�ʊJ��
  gv_prof_transf_bank              VARCHAR2(100)                         DEFAULT NULL;  -- �U������s��
  gv_prof_transf_bankb             VARCHAR2(100)                         DEFAULT NULL;  -- �U�����x�X��
  gv_prof_other_tax_code           VARCHAR2(100)                         DEFAULT NULL;  -- �ΏۊO����ŃR�[�h
  gn_group_id                      NUMBER                                DEFAULT NULL;  -- �O���[�vID
  gv_batch_name                    VARCHAR2(100)                         DEFAULT NULL;  -- �o�b�`��
  gv_s_batch_name                  VARCHAR2(100)                         DEFAULT NULL;  -- �����p�o�b�`��
  gn_period_year                   NUMBER                                DEFAULT NULL;  -- ��v�N�x
  gv_period_name                   VARCHAR2(100)                         DEFAULT NULL;  -- ��v���Ԗ�
  gv_closing_status                VARCHAR2(100)                         DEFAULT NULL;  -- ��v�X�e�[�^�X
  gt_user_name                     fnd_user.user_name%TYPE               DEFAULT NULL;  -- �]�ƈ��ԍ�
  gt_section                       per_all_people_f.attribute28%TYPE     DEFAULT NULL;  -- �������_CD
  gt_bank_branch_id                ap_bank_branches.bank_branch_id%TYPE  DEFAULT NULL;  -- ��s�x�XID
  gn_bank_charge_sum               NUMBER                                DEFAULT 0;     -- ��s�萔��(���v)
  gt_slip_number                   VARCHAR2(150)                         DEFAULT NULL;  -- �`�[�ԍ�
  gn_bm_tax_rate                   NUMBER                                DEFAULT 0;     -- �̔��萔��_����ŗ�
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ��s�萔���J�[�\��
  CURSOR bank_charge_cur
  IS
    -- VDBM�{�U���z�i���Е��S�j
    -- ��s�萔�����܂܂Ȃ��d����
    WITH  bm_gl_je  AS (
            SELECT    gjl.attribute3    AS org_slip_number  -- �`�[�ԍ�
                    , gjl.attribute7    AS supplier_code    -- �d����CD
                    , gcc.segment2      AS base_code        -- ����CD
                    , gcc.segment5      AS customer_code    -- �ڋqCD
            FROM      gl_je_batches        gjb   -- GL�d��o�b�`
                    , gl_je_sources_vl     gjsv  -- GL�d��\�[�X
                    , gl_je_categories_vl  gjcv  -- GL�d��J�e�S��
                    , gl_sets_of_books     gsob  -- GL��v����
                    , gl_je_headers        gjh   -- GL�d��w�b�_
                    , gl_je_lines          gjl   -- GL�d�󖾍�
                    , gl_code_combinations gcc   -- AFF����Ȗڑg����
            WHERE     gsob.name                   =  gv_prof_set_of_books_name  -- ��v���떼
              AND     gjb.set_of_books_id         =  gsob.set_of_books_id
              AND     gjb.name                    LIKE gv_s_batch_name          -- �d��o�b�`��
              AND     gjh.je_batch_id             =  gjb.je_batch_id
              AND     gjh.set_of_books_id         =  gjb.set_of_books_id
              AND     gjsv.user_je_source_name    =  gv_prof_gl_source_cok      -- �d��\�[�X��
              AND     gjh.je_source               =  gjsv.je_source_name
              AND     gjcv.user_je_category_name  =  gv_prof_gl_category_bm     -- �d��J�e�S����
              AND     gjh.je_category             =  gjcv.je_category_name
              AND     gjl.je_header_id            =  gjh.je_header_id
              AND     gjl.code_combination_id     =  gcc.code_combination_id
              AND     gcc.chart_of_accounts_id    =  gsob.chart_of_accounts_id
              AND     gcc.segment1                =  gv_prof_aff1_company_code  -- AFF���    �F�ɓ���
              AND     gcc.segment3                =  gv_prof_aff3_bm            -- AFF����ȖځF���̋@�̔��萔��
              AND     gcc.segment4                IN( gv_prof_aff4_rebate       -- AFF�⏕�ȖځF���̋@���x�[�g
                                                    , gv_prof_aff4_elec_cost    -- AFF�⏕�ȖځF���̋@�d�C��
                                                  )
              AND     gcc.segment7                =  gv_prof_aff7_dummy         -- AFF�\��1
              AND     gcc.segment8                =  gv_prof_aff8_dummy         -- AFF�\��2
              -- ��s�萔�����܂ގd����
              AND     NOT EXISTS (  SELECT 'X'
                                    FROM    gl_je_lines           gjl2 -- GL�d�󖾍�
                                          , gl_code_combinations  gcc2 -- AFF����Ȗڑg����
                                    WHERE   gjl2.je_header_id         =  gjh.je_header_id
                                      AND   gcc2.code_combination_id  =  gjl2.code_combination_id
                                      AND   gcc2.chart_of_accounts_id =  gcc.chart_of_accounts_id    -- AFF�̌nID
                                      AND   gcc2.segment1             =  gv_prof_aff1_company_code   -- AFF���    �F�ɓ���
                                      AND   gcc2.segment2             =  gv_prof_aff2_dept_fin       -- AFF����    �F�����o����
                                      AND   gcc2.segment3             =  gv_prof_aff3_fee            -- AFF����ȖځF�萔��
                                      AND   gcc2.segment4             =  gv_prof_aff4_transfer_fee   -- AFF�⏕�ȖځF�U���萔��
                                      AND   gcc2.segment5             =  gv_prof_aff5_dummy          -- AFF�ڋq    �F��`�Ȃ�
                                      AND   gcc2.segment6             =  gv_prof_aff6_dummy          -- AFF���    �F��`�Ȃ�
                                      AND   gcc2.segment7             =  gv_prof_aff7_dummy          -- AFF�\��1
                                      AND   gcc2.segment8             =  gv_prof_aff8_dummy          -- AFF�\��2
                      )
              AND     gjh.period_name   =  gv_period_name             -- ��v����
            GROUP BY  gjl.attribute3    -- �`�[�ԍ�
                    , gjl.attribute7    -- �d����CD
                    , gcc.segment2      -- AFF����CD
                    , gcc.segment5      -- AFF�ڋqCD
          )
          -- �U���萔�����܂܂Ȃ��d����(�U�����z���t��)
        , xbb_rank  AS (
            SELECT    xbb.supplier_code                     AS supplier_code    -- �d����CD
                    , je.base_code                          AS base_code        -- ����CD
                    , xbb.cust_code                         AS cust_code        -- �ڋqCD
                    , xbb.org_slip_number                   AS org_slip_number  -- �`�[�ԍ�
                    , NVL( SUM( xbb.payment_amt_tax ), 0 )  AS payment_amt_tax  -- �x�����z
                    , RANK() OVER( PARTITION BY xbb.supplier_code
                                   ORDER BY NVL( SUM( xbb.payment_amt_tax ), 0 ) DESC NULLS LAST
                                          , xbb.cust_code                        ASC
                                          , je.base_code                         ASC
                                          , MAX( xbb.bm_balance_id )             DESC
                                     )                      AS rank             -- �x�����z����ԑ�������
            FROM      xxcok_backmargin_balance xbb -- �̎�c��
                    , bm_gl_je                      je  -- �U���萔�����܂܂Ȃ��d����
            WHERE     xbb.supplier_code   =  je.supplier_code
              AND     xbb.cust_code       =  je.customer_code
              AND     xbb.org_slip_number =  je.org_slip_number
            GROUP BY  xbb.supplier_code   -- �d����CD
                    , je.base_code        -- ����CD
                    , xbb.cust_code       -- �ڋqCD
                    , xbb.org_slip_number -- �`�[�ԍ�
          )
    SELECT    rank.supplier_code         AS supplier_code     -- �d����CD
            , rank.base_code             AS dept_code         -- ����CD
            , SUM(xbbs.payment_amt_tax)  AS p_amt_tax_sum     -- �U���z���v
    FROM  xbb_rank                 rank  -- �U���萔�����܂܂Ȃ��d����(�U�����z���t��)
         ,xxcok_backmargin_balance xbbs  -- �̎�c���e�[�u��(���v�Z�o�p)
    WHERE rank.rank             =  cn_rank_number
      AND rank.supplier_code    =  xbbs.supplier_code
      AND rank.org_slip_number  =  xbbs.org_slip_number
    GROUP BY
      rank.supplier_code
    , rank.base_code    
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ��s�萔�����R�[�h�^
  bank_charge_rec bank_charge_cur%ROWTYPE;
  --
  TYPE bc_dept_sum_rtype IS RECORD(
     dept_code      bank_charge_rec.dept_code%TYPE                  -- ����R�[�h
    ,bank_charge    ap_bank_charge_lines.bank_charge_standard%TYPE  -- ��s�萔��
  );
  -- �e�[�u���^�̒�`
  TYPE bank_charge_v_ttype IS TABLE OF bc_dept_sum_rtype INDEX BY VARCHAR2(100);
  --
  bank_charge_v_tab                bank_charge_v_ttype;
  --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_gl_date    IN  VARCHAR2,     --   1.���̓p�����[�^�F�v���
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
    cv_yyyymmdd_format  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t�^����
    cv_percent          CONSTANT VARCHAR2(1)   := '%';           -- ��������
--
    -- *** ���[�J���ϐ� ***
    lv_outmsg           VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode          BOOLEAN         DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��߂�l
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
    --���̓p�����[�^�����b�Z�[�W�o��
    --==============================================================
    lv_outmsg := xxccp_common_pkg.get_msg(
                    cv_appl_name_xxcok
                  , cv_msg_cok_10496
                  , cv_tkn_proc_date
                  , iv_gl_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_outmsg          -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- �o�͋敪
                  , lv_outmsg          -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
--
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    gd_process_date :=  xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- �v���t�@�C���擾(�c�ƒP��ID)
    --==================================================
    gn_prof_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF( gn_prof_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��v����ID)
    --==================================================
    gn_prof_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_setof_id ) );
    IF( gn_prof_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_setof_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��v���떼)
    --==================================================
    gv_prof_set_of_books_name := FND_PROFILE.VALUE( cv_prof_setof_name );
    IF( gv_prof_set_of_books_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_setof_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��ЃR�[�h)
    --==================================================
    gv_prof_aff1_company_code := FND_PROFILE.VALUE( cv_prof_aff1_code );
    IF( gv_prof_aff1_company_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff1_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(����R�[�h_�����o����)
    --==================================================
    gv_prof_aff2_dept_fin := FND_PROFILE.VALUE( cv_prof_aff2_fin );
    IF( gv_prof_aff2_dept_fin IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff2_fin
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(����R�[�h_��������)
    --==================================================
    gv_prof_aff2_dept_adj := FND_PROFILE.VALUE( cv_prof_aff2_adj );
    IF( gv_prof_aff2_dept_adj IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff2_adj
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(����Ȗ�_���̋@�̔��萔��)
    --==================================================
    gv_prof_aff3_bm := FND_PROFILE.VALUE( cv_prof_aff3_vdbm );
    IF( gv_prof_aff3_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff3_vdbm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(����Ȗ�_�萔��)
    --==================================================
    gv_prof_aff3_fee := FND_PROFILE.VALUE( cv_prof_aff3_fee );
    IF( gv_prof_aff3_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff3_fee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�⏕�Ȗ�_���̋@�̔��萔��_���̓d�C��)
    --==================================================
    gv_prof_aff4_elec_cost := FND_PROFILE.VALUE( cv_prof_aff4_elec );
    IF( gv_prof_aff4_elec_cost IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_elec
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�⏕�Ȗ�_���̋@�̔��萔��_���̃��x�[�g)
    --==================================================
    gv_prof_aff4_rebate := FND_PROFILE.VALUE( cv_prof_aff4_rebate );
    IF( gv_prof_aff4_rebate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_rebate
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�⏕�Ȗ�_�萔��_�U���萔��)
    --==================================================
    gv_prof_aff4_transfer_fee := FND_PROFILE.VALUE( cv_prof_aff4_trfee );
    IF( gv_prof_aff4_transfer_fee IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff4_trfee
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�ڋq�R�[�h_�_�~�[�l)
    --==================================================
    gv_prof_aff5_dummy := FND_PROFILE.VALUE( cv_prof_aff5_dummy );
    IF( gv_prof_aff5_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff5_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��ƃR�[�h_�_�~�[�l)
    --==================================================
    gv_prof_aff6_dummy := FND_PROFILE.VALUE( cv_prof_aff6_dummy );
    IF( gv_prof_aff6_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff6_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�\���R�[�h�P_�_�~�[�l)
    --==================================================
    gv_prof_aff7_dummy := FND_PROFILE.VALUE( cv_prof_aff7_dummy );
    IF( gv_prof_aff7_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff7_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�\���R�[�h�Q_�_�~�[�l)
    --==================================================
    gv_prof_aff8_dummy := FND_PROFILE.VALUE( cv_prof_aff8_dummy );
    IF( gv_prof_aff8_dummy IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_aff8_dummy
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d��J�e�S��_�̔��萔��)
    --==================================================
    gv_prof_gl_category_bm := FND_PROFILE.VALUE( cv_prof_gl_ctg_bm );
    IF( gv_prof_gl_category_bm IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_ctg_bm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d��J�e�S��_�U�֓`�[)
    --==================================================
    gv_prof_gl_category_cng := FND_PROFILE.VALUE( cv_prof_gl_ctg_cng );
    IF( gv_prof_gl_category_cng IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_ctg_cng
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d��\�[�X_�ʊJ��)
    --==================================================
    gv_prof_gl_source_cok := FND_PROFILE.VALUE( cv_prof_gl_src_cok );
    IF( gv_prof_gl_source_cok IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_gl_src_cok
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�U������s��)
    --==================================================
    gv_prof_transf_bank := FND_PROFILE.VALUE( cv_prof_transf_bank );
    IF( gv_prof_transf_bank IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_transf_bank
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�U�����x�X��)
    --==================================================
    gv_prof_transf_bankb := FND_PROFILE.VALUE( cv_prof_transf_bankb );
    IF( gv_prof_transf_bankb IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_transf_bankb
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�ΏۊO����ŃR�[�h)
    --==================================================
    gv_prof_other_tax_code := FND_PROFILE.VALUE( cv_prof_other_tax_code );
    IF( gv_prof_other_tax_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_other_tax_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�̔��萔��_����ŗ�)
    --==================================================
    gn_bm_tax_rate := TO_NUMBER(FND_PROFILE.VALUE( cv_prof_bm_tax_rate ));
    IF( gn_bm_tax_rate IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_prof_bm_tax_rate
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- �O���[�vID�擾
    --==================================================
    BEGIN
      SELECT TO_NUMBER( gjs.attribute1 ) AS group_id     -- �O���[�vID
      INTO gn_group_id
      FROM gl_je_sources gjs
      WHERE gjs.user_je_source_name = gv_prof_gl_source_cok
        AND gjs.language            = cv_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00024
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
       RAISE global_api_others_expt;
    END;
    IF( gn_group_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00024
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- �o�b�`���擾
    --==================================================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f( gv_prof_gl_category_cng );
--
    --==================================================
    -- �����o�b�`���擾
    --==================================================
    gv_s_batch_name := gv_prof_gl_category_bm || '%'|| gv_prof_gl_source_cok || '%' ;
    --==================================================
    -- �v����擾 / �������`�F�b�N
    --==================================================
    gd_gl_date := TO_DATE(iv_gl_date , cv_yyyymmdd_format);
    --
    -- �v������Ɩ����t��薢�����ł���΃G���[
    IF( gd_process_date < gd_gl_date ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_10497
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- ��v���ԏ��擾
    --==================================================
    BEGIN
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf
      , ov_retcode                => lv_retcode
      , ov_errmsg                 => lv_errmsg
      , in_set_of_books_id        => gn_prof_set_of_books_id  -- ��v����ID
      , iv_application_short_name => cv_appl_name_sqlgl    -- �A�v���P�[�V�����Z�k��
      , id_object_date            => gd_gl_date               -- �v���
      , on_period_year            => gn_period_year           -- ��v�N�x
      , ov_period_name            => gv_period_name           -- ��v���Ԗ�
      , ov_closing_status         => gv_closing_status        -- �X�e�[�^�X
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00011
                      , iv_token_name1          => cv_tkn_proc_date
                      , iv_token_value1         => TO_CHAR( gd_gl_date, cv_yyyymmdd_format )
                      );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
    -- ��v���ԃX�e�[�^�X��OPEN�ȊO�܂���NULL�̏ꍇ
    IF(    ( gv_closing_status <> cv_closing_status_open )
        OR ( gv_closing_status IS NULL                   )
    ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_gl_date, cv_yyyymmdd_format )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==================================================
    -- �]�ƈ��ԍ��擾
    --==================================================
    BEGIN
      SELECT fu.user_name      user_name
           , papf.attribute28  dept_code
      INTO   gt_user_name
           , gt_section
      FROM   fnd_user             fu
           , per_all_people_f     papf
      WHERE  fu.user_id       = cn_created_by
        AND  papf.person_id   = fu.employee_id
        AND  gd_process_date BETWEEN papf.effective_start_date
                                 AND papf.effective_end_date
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_00005
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE global_api_others_expt;
    END;
--
    -- �������_�R�[�h��NULL�̏ꍇ
    IF( gt_section IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00012
                    , iv_token_name1          => cv_tkn_user_id
                    , iv_token_value1         => cn_created_by
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- ��s�x�XID
    --==================================================
    BEGIN
    SELECT abb.bank_branch_id
    INTO   gt_bank_branch_id
    FROM   ap_bank_branches abb
    WHERE  abb.bank_name        = gv_prof_transf_bank
      AND  abb.bank_branch_name = gv_prof_transf_bankb
    ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_name_xxcok
                      , iv_name                 => cv_msg_cok_10498
                      , iv_token_name1          => cv_tkn_bank_name
                      , iv_token_value1         => gv_prof_transf_bank
                      , iv_token_name2          => cv_tkn_ank_branch
                      , iv_token_value2         => gv_prof_transf_bankb
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE global_api_others_expt;
    END;
    --==================================================
    -- �`�[�ԍ��擾
    --==================================================
    gt_slip_number := xxcok_common_pkg.get_slip_number_f( cv_pkg_name );
    IF( gt_slip_number IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_name_xxcok
                    , iv_name                 => cv_msg_cok_00025
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_pmt_amt
   * Description      : �U���z���̎擾 (A-2)
   *                    ��s�萔������W�v (A-3)
   ***********************************************************************************/
  PROCEDURE get_pmt_amt(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pmt_amt'; -- �v���O������
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
    lv_key_str        VARCHAR(100);
    lt_bank_charge_tx ap_bank_charge_lines.bank_charge_standard%TYPE DEFAULT 0;
    lt_bank_charge    NUMBER DEFAULT 0;
    lt_supplier_code  bank_charge_rec.supplier_code%TYPE;
    lt_p_amt_tax_sum  bank_charge_rec.p_amt_tax_sum%TYPE;
    
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
    --==================================================
    -- ��s�萔�����[�v
    --==================================================
    << bank_charge_loop >>
    FOR bank_charge_rec IN bank_charge_cur LOOP
    --
      -- ������
      lt_bank_charge_tx := 0;
      lt_bank_charge    := 0;
      --
      -- ��s�萔���Z�o
      BEGIN
        SELECT /*+ LEADING(abc) */
          abcl.bank_charge_standard     -- �W����s�萔��
        INTO lt_bank_charge_tx
        FROM ap_bank_charges      abc   -- ��s�萔���}�X�^
            ,ap_bank_charge_lines abcl  -- ��s�萔������
        WHERE  abc.transferring_bank_branch_id = gt_bank_branch_id
          AND  abc.bank_charge_id              = abcl.bank_charge_id
          AND  abc.transferring_bank           = cv_code_one
          AND  abc.transferring_branch         = cv_code_one
          AND  abc.receiving_bank              = cv_code_other
          AND  abc.receiving_branch            = cv_code_all
          AND  bank_charge_rec.p_amt_tax_sum  >= NVL( abcl.trans_amount_from, 0 )
          AND  ( ( abcl.trans_amount_to IS NULL )
               OR (( abcl.trans_amount_to IS NOT NULL )
                  AND ( bank_charge_rec.p_amt_tax_sum  < abcl.trans_amount_to )
                  ) 
               )
        ;
        --
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
           lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appl_name_xxcok
                         , iv_name          => cv_msg_cok_10499
                         , iv_token_name1   => cv_tkn_slp_code
                         , iv_token_value1  => bank_charge_rec.supplier_code
                         , iv_token_name2   => cv_tkn_p_amt
                         , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                        );
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE global_process_expt;
        WHEN NO_DATA_FOUND THEN
           lv_errmsg  := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appl_name_xxcok
                         , iv_name          => cv_msg_cok_10499
                         , iv_token_name1   => cv_tkn_slp_code
                         , iv_token_value1  => bank_charge_rec.supplier_code
                         , iv_token_name2   => cv_tkn_p_amt
                         , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                        );
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          RAISE global_process_expt;
      END;
      -- �萔����NULL�̏ꍇ���G���[
      IF( lt_bank_charge_tx IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_name_xxcok
                      , iv_name          => cv_msg_cok_10499
                      , iv_token_name1   => cv_tkn_slp_code
                      , iv_token_value1  => bank_charge_rec.supplier_code
                      , iv_token_name2   => cv_tkn_p_amt
                      , iv_token_value2  => bank_charge_rec.p_amt_tax_sum
                     );
       lv_errbuf  := lv_errmsg;
       RAISE global_process_expt;
      END IF;
      --
      -- �Ŕ��萔���Z�o
      lt_bank_charge := TRUNC(lt_bank_charge_tx / ( 1 + ( gn_bm_tax_rate / 100 ) ));
      --
      -- �L�[���쐬
      lv_key_str := bank_charge_rec.dept_code;
      --
      -- ����ʏW�v�z�񂪂���Ή��Z�B�Ȃ���Δz�񐶐��B
      IF( bank_charge_v_tab.exists(lv_key_str) = TRUE ) THEN
        bank_charge_v_tab(lv_key_str).bank_charge := bank_charge_v_tab(lv_key_str).bank_charge + lt_bank_charge;
      ELSE
        bank_charge_v_tab(lv_key_str).dept_code   := bank_charge_rec.dept_code;
        bank_charge_v_tab(lv_key_str).bank_charge := lt_bank_charge;
      END IF;
      -- �S���升�v�̋�s�萔���Z�o
      gn_bank_charge_sum := gn_bank_charge_sum + lt_bank_charge;
    END LOOP bank_charge_loop;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_pmt_amt;
--
  /**********************************************************************************
   * Procedure Name   : create_cr_data
   * Description      : ����ʎd��̍쐬 (A-4)
   ***********************************************************************************/
  PROCEDURE create_cr_data(
    it_aff2_department  IN  VARCHAR2,     --   ����R�[�h
    it_entered_dr       IN  NUMBER,       --   ��s�萔��
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_cr_data'; -- �v���O������
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
    --��ʉ�vOIF�f�[�^�}������
    INSERT INTO gl_interface(
       status                         -- �X�e�[�^�X
      ,set_of_books_id                -- ��v����ID
      ,accounting_date                -- �d��L�����t
      ,currency_code                  -- �ʉ݃R�[�h
      ,date_created                   -- �V�K�쐬���t
      ,created_by                     -- �V�K�쐬��ID
      ,actual_flag                    -- �c���^�C�v
      ,user_je_category_name          -- �d��J�e�S����
      ,user_je_source_name            -- �d��\�[�X��
      ,segment1                       -- ���
      ,segment2                       -- ����
      ,segment3                       -- ����Ȗ�
      ,segment4                       -- �⏕�Ȗ�
      ,segment5                       -- �ڋq�R�[�h
      ,segment6                       -- ��ƃR�[�h
      ,segment7                       -- �\���P
      ,segment8                       -- �\���Q
      ,entered_dr                     -- �ؕ����z
      ,entered_cr                     -- �ݕ����z
      ,reference1                     -- �o�b�`��
      ,reference4                     -- �d��
      ,period_name                    -- ��v���Ԗ�
      ,group_id                       -- �O���[�vID
      ,attribute1                     -- �ŋ敪
      ,attribute3                     -- �`�[�ԍ�
      ,attribute4                     -- �N�[����
      ,attribute5                     -- �`�[���͎�
      ,context                        -- DFF�R���e�L�X�g
    )VALUES(
       cv_je_status_new               -- �X�e�[�^�X
      ,gn_prof_set_of_books_id        -- ��v����ID
      ,gd_gl_date                     -- �d��L�����t
      ,cv_currency_code               -- �ʉ݃R�[�h
      ,SYSDATE                        -- �V�K�쐬���t
      ,cn_created_by                  -- �V�K�쐬��ID
      ,cv_balance_type_result         -- �c���^�C�v
      ,gv_prof_gl_category_cng        -- �d��J�e�S����
      ,gv_prof_gl_source_cok          -- �d��\�[�X��
      ,gv_prof_aff1_company_code      -- ���
      ,it_aff2_department             -- ����
      ,gv_prof_aff3_fee               -- ����Ȗ�
      ,gv_prof_aff4_transfer_fee      -- �⏕�Ȗ�
      ,gv_prof_aff5_dummy             -- �ڋq�R�[�h
      ,gv_prof_aff6_dummy             -- ��ƃR�[�h
      ,gv_prof_aff7_dummy             -- �\���P
      ,gv_prof_aff8_dummy             -- �\���Q
      ,it_entered_dr
      ,NULL
      ,gv_batch_name                  -- �o�b�`��
      ,gt_slip_number                 -- �d��
      ,gv_period_name                 -- ��v���Ԗ�
      ,gn_group_id                    -- �O���[�vID
      ,gv_prof_other_tax_code         -- �ŋ敪
      ,gt_slip_number                 -- �`�[�ԍ�
      ,gt_section                     -- �N�[����
      ,gt_user_name                   -- �`�[���͎�
      ,gv_prof_set_of_books_name      -- DFF�R���e�L�X�g
     );
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
  END create_cr_data;
--
  /**********************************************************************************
   * Procedure Name   : create_dr_data
   * Description      : �U�֌��d��̍쐬 (A-5)
   ***********************************************************************************/
  PROCEDURE create_dr_data(
    it_entered_cr       IN  NUMBER,       --   ��s�萔�����v
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_dr_data'; -- �v���O������
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
    --��ʉ�vOIF�f�[�^�}������
    INSERT INTO gl_interface(
       status                         -- �X�e�[�^�X
      ,set_of_books_id                -- ��v����ID
      ,accounting_date                -- �d��L�����t
      ,currency_code                  -- �ʉ݃R�[�h
      ,date_created                   -- �V�K�쐬���t
      ,created_by                     -- �V�K�쐬��ID
      ,actual_flag                    -- �c���^�C�v
      ,user_je_category_name          -- �d��J�e�S����
      ,user_je_source_name            -- �d��\�[�X��
      ,segment1                       -- ���
      ,segment2                       -- ����
      ,segment3                       -- ����Ȗ�
      ,segment4                       -- �⏕�Ȗ�
      ,segment5                       -- �ڋq�R�[�h
      ,segment6                       -- ��ƃR�[�h
      ,segment7                       -- �\���P
      ,segment8                       -- �\���Q
      ,entered_dr                     -- �ؕ����z
      ,entered_cr                     -- �ݕ����z
      ,reference1                     -- �o�b�`��
      ,reference4                     -- �d��
      ,period_name                    -- ��v���Ԗ�
      ,group_id                       -- �O���[�vID
      ,attribute1                     -- �ŋ敪
      ,attribute3                     -- �`�[�ԍ�
      ,attribute4                     -- �N�[����
      ,attribute5                     -- �`�[���͎�
      ,context                        -- DFF�R���e�L�X�g
    )VALUES(
       cv_je_status_new               -- �X�e�[�^�X
      ,gn_prof_set_of_books_id        -- ��v����ID
      ,gd_gl_date                     -- �d��L�����t
      ,cv_currency_code               -- �ʉ݃R�[�h
      ,SYSDATE                        -- �V�K�쐬���t
      ,cn_created_by                  -- �V�K�쐬��ID
      ,cv_balance_type_result         -- �c���^�C�v
      ,gv_prof_gl_category_cng        -- �d��J�e�S����
      ,gv_prof_gl_source_cok          -- �d��\�[�X��
      ,gv_prof_aff1_company_code      -- ���
      ,gv_prof_aff2_dept_adj          -- ����
      ,gv_prof_aff3_fee               -- ����Ȗ�
      ,gv_prof_aff4_transfer_fee      -- �⏕�Ȗ�
      ,gv_prof_aff5_dummy             -- �ڋq�R�[�h
      ,gv_prof_aff6_dummy             -- ��ƃR�[�h
      ,gv_prof_aff7_dummy             -- �\���P
      ,gv_prof_aff8_dummy             -- �\���Q
      ,NULL
      ,it_entered_cr
      ,gv_batch_name                  -- �o�b�`��
      ,gt_slip_number                 -- �d��
      ,gv_period_name                 -- ��v���Ԗ�
      ,gn_group_id                    -- �O���[�vID
      ,gv_prof_other_tax_code         -- �ŋ敪
      ,gt_slip_number                 -- �`�[�ԍ�
      ,gt_section                     -- �N�[����
      ,gt_user_name                   -- �`�[���͎�
      ,gv_prof_set_of_books_name      -- DFF�R���e�L�X�g
     );
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
  END create_dr_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_gl_date    IN  VARCHAR2,     --   �v���
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
    lv_end_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_key_str       VARCHAR2(5000) DEFAULT NULL;
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
    -- �������� (A-1)
    -- ===============================
    init(
      iv_gl_date,        -- �v���
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �U���z���̎擾(A-2) / ��s�萔������W�v(A-3)
    -- ===============================
    get_pmt_amt(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
-- 
    -- �����J�E���g
    gn_target_cnt := bank_charge_v_tab.count;
    --
    IF(gn_target_cnt > 0) THEN
      gn_target_cnt := gn_target_cnt + 1;
    END IF;
    -- 1�Ԗڂ̓Y����ݒ�
    lv_key_str := bank_charge_v_tab.first;
    -- �Y�����擾�ł��Ȃ��Ȃ�܂Ń��[�v
    WHILE lv_key_str IS NOT NULL LOOP
      -- ===============================
      -- ����ʎd��̍쐬 (A-4)
      -- ===============================
      create_cr_data(
        bank_charge_v_tab(lv_key_str).dept_code,         -- ����R�[�h
        bank_charge_v_tab(lv_key_str).bank_charge,       -- ��s�萔��
        lv_errbuf,                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                                      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      -- ��ʉ�vOIF�o�^����
      gn_normal_cnt := gn_normal_cnt + 1;
      -- ����̓Y����ݒ�
      lv_key_str := bank_charge_v_tab.next(lv_key_str);
    END LOOP;
    --
    -- ===============================
    -- �U�֌��d��̍쐬 (A-5)
    -- ===============================
    -- ����ʎd��1�����Ȃ��ꍇ�͍쐬���Ȃ��B
    IF( bank_charge_v_tab.count > 0 ) THEN
     create_dr_data(
       gn_bank_charge_sum,                              -- ��s�萔��
       lv_errbuf,                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,                                      -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg);                                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF( lv_retcode = cv_status_error ) THEN
       lv_end_retcode := cv_status_error;
       RAISE global_process_expt;
     END IF;
     -- ��ʉ�vOIF�o�^����
     gn_normal_cnt := gn_normal_cnt + 1;
   END IF;
   --
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_gl_date    IN  VARCHAR2       --   �v���
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
       iv_gl_date  -- ���̓p�����[�^�u�v����v
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt   := 1;
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
END XXCOK017A02C;
/
