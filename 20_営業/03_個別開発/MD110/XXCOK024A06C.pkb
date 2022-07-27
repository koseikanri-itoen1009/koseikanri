CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A06C (body)
 * Description      : �̔��T�������d������쐬���A��ʉ�vOIF�ɘA�g���鏈��
 * MD.050           : �̔��T���f�[�^GL�A�g MD050_COK_024_A06
 * Version          : 1.5
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
-- *  roundup                �؏�֐�
 *  init                   A-1.��������
 *  get_data               A-2.�̔��T���f�[�^���o
 *  edit_work_data         A-3.��ʉ�vOIF�W�񏈗�
 *  edit_gl_data           A-4.��ʉ�vOIF�f�[�^�쐬
 *  insert_gl_data         A-5.��ʉ�vOIF�o�^����
-- *  update_deduction_data  A-6.�̔��T�����X�V����
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-7���܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/11/24    1.0   H.Ishii          �V�K�쐬
 *  2021/05/19    1.1   K.Yoshikawa      �O���[�vID�ǉ��Ή�
 *  2021/06/25    1.2   K.Tomie          E_�{�ғ�_17279�Ή�
 *  2021/08/26    1.3   H.Futamura       E_�{�ғ�_17468�Ή�
 *  2022/04/25    1.4   K.Yoshikawa      E_�{�ғ�_18146�Ή�
 *  2022/06/16    1.5   SCSK Y.Koh       E_�{�ғ�_18401�Ή�
 *
 *****************************************************************************************/
--
--###########################  �Œ�O���[�o���萔�錾�� START  ###########################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  �Œ�O���[�o���萔�錾�� END  ############################
--
--###########################  �Œ�O���[�o���ϐ��錾�� START  ###########################
--
  gv_out_msg       VARCHAR2(2000);                       -- �o�̓��b�Z�[�W
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- ��ʉ�vOIF�ɍ쐬��������
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- �̔��T�����̏����ΏۂƂȂ錏��
  gn_error_cnt     NUMBER   DEFAULT 0;                   -- �G���[����
--
--############################  �Œ�O���[�o���ϐ��錾�� END  ############################
--
--##############################  �Œ苤�ʗ�O�錾�� START  ##############################
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
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A06C';                     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                            -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                 -- �Ɩ����t�擾�G���[
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                 -- ���b�N�G���[���b�Z�[�W�i�̔��T��TB�j
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10586';                 -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10587';                 -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_tkn_deduction_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10588';                 -- �̔��T�����
  cv_tkn_gloif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10589';                 -- ��ʉ�vOIF
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10578';                 -- ��v����ID
  cv_pro_bks_nm             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10579';                 -- ��v���떼��
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10580';                 -- ��ЃR�[�h
  cv_pro_dept_fin_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10624';                 -- ����R�[�h�i�����o�����j
  cv_pro_customer_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10625';                 -- �ڋq�R�[�h_�_�~�[�l
  cv_pro_comp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10626';                 -- ��ƃR�[�h_�_�~�[�l
  cv_pro_preliminary1_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10627';                 -- �\���P_�_�~�[�l
  cv_pro_preliminary2_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10628';                 -- �\���Q_�_�~�[�l
  cv_pro_category_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10629';                 -- �d��J�e�S��
  cv_pro_source_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10630';                 -- �d��\�[�X
  cv_sales_deduction        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10650';                 -- �̔��T�����
  cv_period_name_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00059';                 -- ��v���ԏ��擾�G���[���b�Z�[�W
  cv_account_error_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10681';                 -- �ŏ��擾�G���[���b�Z�[�W
  cv_pro_org_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10669';                 -- �g�DID
--2021/05/19 add start
  cv_group_id_msg           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00024';                 -- �O���[�vID�擾�G���[
--2021/05/19 add end
--
  -- �g�[�N��
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';                         -- �v���t�@�C��
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';                      -- �e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';                        -- �L�[����
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';                               -- �t���O�l:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';                               -- �t���O�l:N
  cv_r_flag                 CONSTANT  VARCHAR2(1)  := 'R';                               -- �t���O�l:R
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';                               -- �t���O�l:S
  cv_t_flag                 CONSTANT  VARCHAR2(1)  := 'T';                               -- �t���O�l:T
  cv_u_flag                 CONSTANT  VARCHAR2(1)  := 'U';                               -- �t���O�l:U
  cv_v_flag                 CONSTANT  VARCHAR2(1)  := 'V';                               -- �t���O�l:V
  cv_f_flag                 CONSTANT  VARCHAR2(1)  := 'F';                               -- �t���O�l:F
  cv_dummy_code             CONSTANT  VARCHAR2(5)  := 'DUMMY';                           -- DUMMY�l
  cv_date_format            CONSTANT  VARCHAR2(6)  := 'YYYYMM';                          -- �����t�H�[�}�b�gYYYYMM
  cv_teigaku_code           CONSTANT  VARCHAR2(3)  := '070';                             -- �T���^�C�v_��z�T��
  -- �N�C�b�N�R�[�h
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';      -- �T���f�[�^���
  cv_lookup_tax_conv_code   CONSTANT  VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';    -- ����ŃR�[�h�ϊ��}�X�^
  cv_period_set_name        CONSTANT  VARCHAR2(30) := 'SALES_CALENDAR';                  -- ��v�J�����_
  -- ��ʉ�vOIF�e�[�u���ɐݒ肷��Œ�l
  cv_status                 CONSTANT  VARCHAR2(3)  := 'NEW';                             -- �X�e�[�^�X
  cv_currency_code          CONSTANT  VARCHAR2(3)  := 'JPY';                             -- �ʉ݃R�[�h
  cv_actual_flag            CONSTANT  VARCHAR2(1)  := 'A';                               -- �c���^�C�v
  cv_underbar               CONSTANT  VARCHAR2(1)  := '_';                               -- ���ڋ�؂�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔��T�����[�N�e�[�u����`
  TYPE gr_deductions_exp_rec IS RECORD(
-- 2022/06/16 Ver1.5 MOD Start
      accounting_base           xxcok_condition_lines.accounting_base%TYPE                -- ���_�R�[�h(��z�T��)
--      sales_deduction_id        xxcok_sales_deduction.sales_deduction_id%TYPE             -- �̔��T��ID
--    , accounting_base           xxcok_condition_lines.accounting_base%TYPE                -- ���_�R�[�h(��z�T��)
--    , past_sale_base_code       xxcok_sales_deduction.base_code_from%TYPE                 -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
    , account                   fnd_lookup_values.attribute4%TYPE                         -- ����Ȗ�
    , sub_account               fnd_lookup_values.attribute5%TYPE                         -- �⏕�Ȗ�
    , deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- �T���z
    , tax_code                  xxcok_sales_deduction.tax_code%TYPE                       -- �ŃR�[�h
    , deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- �T���Ŋz
    , corp_code                 fnd_lookup_values.attribute1%TYPE                         -- ��ƃR�[�h
    , customer_code             fnd_lookup_values.attribute4%TYPE                         -- �ڋq�R�[�h
  );
--
  -- ���T�����[�N�e�[�u����`
  TYPE gr_deductions_debt_exp_rec IS RECORD(
      account                   fnd_lookup_values.attribute6%TYPE                         -- ����Ȗ�
    , sub_account               fnd_lookup_values.attribute7%TYPE                         -- �⏕�Ȗ�
    , deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- �T���z
  );
--
-- Ver 1.3 del start
--  -- �̔��T�����b�N�p���[�N�e�[�u����`
--  TYPE gr_deductions_lock_rec IS RECORD(
--      sales_deduction_id        xxcok_sales_deduction.sales_deduction_id%TYPE             -- �̔��T��ID
--  );
-- Ver 1.3 del end
--
  -- ���[�N�e�[�u���^��`
  -- �̔��T���f�[�^
  TYPE g_deductions_exp_ttype       IS TABLE OF gr_deductions_exp_rec INDEX BY BINARY_INTEGER;
    gt_deductions_exp_tbl        g_deductions_exp_ttype;
--
  -- �̔��T�����f�[�^
  TYPE g_deductions_debt_exp_ttype  IS TABLE OF gr_deductions_debt_exp_rec INDEX BY BINARY_INTEGER;
    gt_deductions_debt_exp_tbl   g_deductions_debt_exp_ttype;
--
-- Ver 1.3 del start
--  -- �̔��T�����b�N�p�f�[�^
--  TYPE g_deductions_lock_ttype  IS TABLE OF gr_deductions_lock_rec INDEX BY BINARY_INTEGER;
--    gt_deduction_lock_tbl        g_deductions_lock_ttype;
-- Ver 1.3 del end
--
-- 2022/06/16 Ver1.5 DEL Start
--  -- �̔��T���f�[�^
--  TYPE g_deductions_ttype           IS TABLE OF xxcok_sales_deduction%ROWTYPE INDEX BY BINARY_INTEGER;
--    gt_deduction_tbl             g_deductions_ttype;
-- 2022/06/16 Ver1.5 DEL End
--
-- ��ʉ�vOIF
  TYPE g_gl_oif_ttype               IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_gl_interface_tbl          g_gl_oif_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
  gd_process_date                     DATE;                                         -- �Ɩ����t
  gd_from_date                        DATE;                                         -- �擾�����ƂȂ���t(From)
  gv_period                           VARCHAR2(30);                                 -- ��v����
  gv_set_bks_id                       VARCHAR2(30);                                 -- ��v����ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- ��v���떼��
  gv_company_code                     VARCHAR2(30);                                 -- ��ЃR�[�h
  gv_dept_fin_code                    VARCHAR2(30);                                 -- ����R�[�h�i�����o�����j
  gv_account_code                     VARCHAR2(30);                                 -- ����ȖڃR�[�h_���i�������j
  gv_sub_account_code                 VARCHAR2(30);                                 -- �⏕�ȖڃR�[�h_���i�������j
  gv_customer_code                    VARCHAR2(30);                                 -- �ڋq�R�[�h
  gv_comp_code                        VARCHAR2(30);                                 -- ��ƃR�[�h
  gv_preliminary1_code                VARCHAR2(30);                                 -- �\���P
  gv_preliminary2_code                VARCHAR2(30);                                 -- �\���Q
  gv_category_code                    VARCHAR2(30);                                 -- �d��J�e�S��
  gv_source_code                      VARCHAR2(30);                                 -- �d��\�[�X
  gn_org_id                           NUMBER;                                       -- �g�DID
--2021/05/19 add start
  gn_group_id                         NUMBER         DEFAULT NULL;                  -- �O���[�vID
--2021/05/19 add end
--Ver 1.2 add start
  gv_parallel_group                   VARCHAR2(2);                                  -- GL�A�g�p���������s�O���[�v
--Ver 1.2 add end
--
  CURSOR deductions_data_cur
  IS
-- 2022/06/16 Ver1.5 MOD Start
    SELECT temp.accounting_base             accounting_base
--    SELECT temp.sales_deduction_id          sales_deduction_id
--          ,temp.accounting_base             accounting_base
--          ,temp.past_sale_base_code         past_sale_base_code
-- 2022/06/16 Ver1.5 MOD End
          ,temp.account                     account
          ,temp.sub_account                 sub_account
-- 2022/06/16 Ver1.5 MOD Start
          ,SUM(temp.deduction_amount)       deduction_amount
--          ,temp.deduction_amount            deduction_amount
-- 2022/06/16 Ver1.5 MOD End
          ,temp.tax_code                    tax_code
-- 2022/06/16 Ver1.5 MOD Start
          ,SUM(temp.deduction_tax_amount)   deduction_tax_amount
--          ,temp.deduction_tax_amount        deduction_tax_amount
-- 2022/06/16 Ver1.5 MOD End
          ,temp.corp_code                   corp_code
          ,temp.customer_code               customer_code
    FROM   XXCOK_XXCOK024A06C_TEMP  temp
-- 2022/06/16 Ver1.5 ADD Start
    GROUP BY
           temp.tax_code
          ,temp.accounting_base
          ,temp.account
          ,temp.sub_account
          ,temp.corp_code
          ,temp.customer_code
-- 2022/06/16 Ver1.5 ADD End
    ORDER BY
           temp.tax_code
          ,temp.accounting_base
-- 2022/06/16 Ver1.5 DEL Start
--          ,temp.past_sale_base_code
-- 2022/06/16 Ver1.5 DEL End
          ,temp.account
          ,temp.sub_account
          ,temp.corp_code
          ,temp.customer_code
    ;
--
-- Ver 1.3 del start
--  CURSOR deductions_data_lock_cur
--  IS
----Ver 1.2 mod start
----    SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
--    SELECT /*+ LEADING(flv XSD)
--               INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
--               USE_HASH(XSD)*/
----Ver 1.2 mod end
--           xsd.sales_deduction_id      sales_deduction_id    -- �̔��T��ID
--    FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
----Ver 1.2 mod start
----    WHERE  TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)  -- �����
--          ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h
--    WHERE  flv.lookup_code                          = xsd.data_type                                 -- �f�[�^���
--    AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- �T���f�[�^���
--    AND    flv.enabled_flag                         = cv_y_flag                                     -- �g�p�\�FY
--    AND    flv.language                             = USERENV('LANG')                               -- ����FUSERENV('LANG')
--    AND    flv.attribute13                          = gv_parallel_group                             -- GL�A�g�p���������s�O���[�v
----Ver 1.2 mod end
--    AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                 -- GL�A�g�t���O N�F���A�g�AR�F�đ�
--    AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag       -- �쐬���敪 S:�̔����сAT:������ѐU��(EDI)�AV:������ѐU��(�U�֊���)
--                                                     , cv_u_flag, cv_f_flag)                 -- �쐬���敪 U:�A�b�v���[�h�AF:��z�T��
--    FOR UPDATE OF sales_deduction_id NOWAIT
--    ;
-- Ver 1.3 del end
--
  CURSOR deductions_debt_data_cur
  IS
    SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
           flv.attribute6                                account                -- ����Ȗ�
          ,flv.attribute7                                sub_account            -- �⏕�Ȗ�
          ,SUM(CASE
                 WHEN xsd.gl_if_flag = cv_n_flag THEN
                   xsd.deduction_amount
                 ELSE
                   xsd.deduction_amount * -1
                 END
               )                                         deduction_amount       -- �T���z
    FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
          ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h
    WHERE  flv.lookup_code                          = xsd.data_type                                 -- �f�[�^���
    AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- �T���f�[�^���
    AND    flv.enabled_flag                         = cv_y_flag                                     -- �g�p�\�FY
    AND    flv.language                             = USERENV('LANG')                               -- ����FUSERENV('LANG')
--Ver 1.2 add start
    AND    flv.attribute13                          = gv_parallel_group                             -- GL�A�g�p���������s�O���[�v
--Ver 1.2 add end
    AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- �����
    AND    xsd.gl_if_flag                          IN (cv_n_flag,cv_r_flag)                         -- GL�A�g�t���O N�F���A�g�AR�F�đ�
    AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag              -- �쐬���敪 S:�̔����сAT:������ѐU��(EDI)�AV:������ѐU��(�U�֊���)
                                                     , cv_u_flag, cv_f_flag)                        -- �쐬���敪 U:�A�b�v���[�h�AF:��z�T��
    GROUP BY
           flv.attribute6
          ,flv.attribute7
    ORDER BY
           flv.attribute6
          ,flv.attribute7
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';                     -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_pro_bks_id_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
    cv_pro_bks_nm_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_NAME';               -- ��v���떼��
    cv_pro_company_cd_1         CONSTANT VARCHAR2(40) := 'XXCOK1_AFF1_COMPANY_CODE';         -- XXCOK:��ЃR�[�h
    cv_pro_dept_fin_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF2_DEPT_FIN';             -- XXCOK:����R�[�h_�����o����
    cv_pro_customer_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- XXCOK:�ڋq�R�[�h_�_�~�[�l
    cv_pro_comp_cd_1            CONSTANT VARCHAR2(40) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- XXCOK:��ƃR�[�h_�_�~�[�l
    cv_pro_preliminary1_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- XXCOK:�\���P_�_�~�[�l:0
    cv_pro_preliminary2_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- XXCOK:�\���Q_�_�~�[�l:0
    cv_pro_category_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_GL_CATEGORY_CONDITION1';    -- XXCOK:�d��J�e�S��
    cv_pro_source_cd_1          CONSTANT VARCHAR2(40) := 'XXCOK1_GL_SOURCE_CONDITION';       -- XXCOK:�d��\�[�X_�T���쐬
    cv_pro_org_id_1             CONSTANT VARCHAR2(40) := 'ORG_ID';                           -- XXCOK:�g�DID
    cn_024a06_start_months      CONSTANT NUMBER       := -1;                                 -- XXCOK:�̔��T���f�[�^GL�A�g��v����
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name                   VARCHAR2(50);                                    -- �v���t�@�C����
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    --==================================
    -- �P�D�Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ�̓G���[
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            , cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �Q�D�̔��T���f�[�^GL�A�g��v���Ԏ擾
    --==================================
    --�Ɩ����t���GL�L�������擾
    gd_from_date := LAST_DAY(TRUNC(ADD_MONTHS(gd_process_date, cn_024a06_start_months)));
--
    -- GL�L���������v���Ԃ��擾
    BEGIN
      SELECT gp.period_name  period_name   -- ��v����
      INTO   gv_period
      FROM   gl_periods      gp            -- ��v���ԏ��
      WHERE  gp.period_set_name        = cv_period_set_name -- ��v�J�����_
      AND    gd_from_date        BETWEEN gp.start_date      -- ��v���ԗL���J�n��
                                     AND gp.end_date        -- ��v���ԗL���I����
      AND    gp.adjustment_period_flag = cv_n_flag          -- �����@�ցFN
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
      -- ��v���Ԃ��擾�o���Ȃ��ꍇ
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                              , cv_period_name_msg
                                               );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �R�D�v���t�@�C���擾�F��v����ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( cv_pro_bks_id_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_bks_id                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �S�D�v���t�@�C���擾�F��v���떼��
    -- ===============================
    gv_set_bks_nm := FND_PROFILE.VALUE( cv_pro_bks_nm_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_set_bks_nm IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_bks_nm                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �T�D�v���t�@�C���擾�F��ЃR�[�h
    --==================================
    gv_company_code := FND_PROFILE.VALUE( cv_pro_company_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_company_cd               -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �U�D�v���t�@�C���擾�F����R�[�h�i�����o�����j
    --==================================
    gv_dept_fin_code := FND_PROFILE.VALUE( cv_pro_dept_fin_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_dept_fin_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_dept_fin_cd              -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �V�D�v���t�@�C���擾�F�ڋq�R�[�h_�_�~�[�l
    --==================================
    gv_customer_code := FND_PROFILE.VALUE( cv_pro_customer_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_customer_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_customer_cd              -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �W�D�v���t�@�C���擾�F��ƃR�[�h_�_�~�[�l
    --==================================
    gv_comp_code := FND_PROFILE.VALUE( cv_pro_comp_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_comp_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_comp_cd                  -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �X�D�v���t�@�C���擾�F�\���P_�_�~�[�l
    --==================================
    gv_preliminary1_code := FND_PROFILE.VALUE( cv_pro_preliminary1_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_preliminary1_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_preliminary1_cd          -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�O�D�v���t�@�C���擾�F�\���Q_�_�~�[�l
    --==================================
    gv_preliminary2_code := FND_PROFILE.VALUE( cv_pro_preliminary2_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_preliminary2_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_preliminary2_cd          -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�P�D�v���t�@�C���擾�F�d��J�e�S��
    --==================================
    gv_category_code := FND_PROFILE.VALUE( cv_pro_category_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_category_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_category_cd              -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�Q�D�v���t�@�C���擾�F�d��\�[�X
    --==================================
    gv_source_code := FND_PROFILE.VALUE( cv_pro_source_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_source_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_source_cd                -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�R�D�v���t�@�C���擾�F�g�DID
    --==================================
    gn_org_id := FND_PROFILE.VALUE( cv_pro_org_id_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_org_id                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2021/05/19 add start
--
    --==============================================================
    --�P�S�D�O���[�vID���擾
    --==============================================================
    SELECT gjs.attribute1         AS group_id -- �O���[�vID
    INTO   gn_group_id
    FROM   gl_je_sources             gjs      -- �d��\�[�X�}�X�^
    WHERE  gjs.user_je_source_name = gv_source_code;
--
    IF ( gn_group_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_xxcok_short_nm
                                          , cv_group_id_msg
                                           );
      RAISE global_api_expt;
    END IF;

--2021/05/19 add end
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#################################  �Œ��O������ END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-2.�̔��T���f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
                    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name             VARCHAR2(255);                                  -- �e�[�u����
--
    -- *** ���[�J����O ***
    lock_expt                 EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�G���[
    no_data_expt              EXCEPTION;    -- �Ώۃf�[�^0���G���[
    -- *** ���[�J���E�J�[�\�� (�̔��T���f�[�^���o)***
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    --==================================
    -- �̔��T���f�[�^���o�i�ꎞ�\�ޔ��j
    --==================================
    INSERT INTO XXCOK_XXCOK024A06C_TEMP
    SELECT sales_deduction_id          sales_deduction_id
          ,accounting_base             accounting_base
-- 2022/06/16 Ver1.5 MOD Start
          ,NULL                        past_sale_base_code
--          ,past_sale_base_code         past_sale_base_code
-- 2022/06/16 Ver1.5 MOD End
          ,account                     account
          ,sub_account                 sub_account
          ,deduction_amount            deduction_amount
          ,tax_code                    tax_code
          ,deduction_tax_amount        deduction_tax_amount
          ,corp_code                   corp_code
          ,customer_code               customer_code
    FROM (
          -- �ڋq
--Ver 1.2 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
          SELECT /*+ LEADING(flv XSD xca flv2 flv1)
                     INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
                     USE_HASH(XSD)
                     USE_HASH(flv1)
                     USE_HASH(flv2)*/
--Ver 1.2 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- �̔��T��ID
                ,CASE
-- 2022/06/16 Ver1.5 MOD Start
                   WHEN flv.attribute2 = cv_teigaku_code OR xsd.source_category = cv_u_flag THEN
--                   WHEN flv.attribute2 = cv_teigaku_code THEN
-- 2022/06/16 Ver1.5 MOD End
                     xsd.base_code_from
                   ELSE
-- 2022/06/16 Ver1.5 MOD Start
                     xca.past_sale_base_code
--                     NULL
-- 2022/06/16 Ver1.5 MOD End
                 END                            accounting_base       -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--                ,CASE
--                   WHEN xsd.source_category = cv_u_flag THEN
--                     xsd.base_code_from
--                   ELSE
--                     xca.past_sale_base_code
--                 END                            past_sale_base_code   -- ���_�R�[�h(��z�T���ȊO)�A�쐬���敪���uU:�A�b�v���[�h�v�̏ꍇ�A�U�֌����_
-- 2022/06/16 Ver1.5 DEL End
                ,flv.attribute4                 account               -- ����Ȗ�
                ,flv.attribute5                 sub_account           -- �⏕�Ȗ�
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- �T���z
                ,flv1.attribute1                tax_code              -- �ŃR�[�h
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- �T���Ŋz
                ,NVL(flv2.attribute1,gv_comp_code)     corp_code      -- ��ƃR�[�h
                ,NVL(DECODE(xca.torihiki_form,'2',xsd.customer_code_to,flv2.attribute4),gv_customer_code) customer_code
                                                                        -- �ڋq�R�[�h
          FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
                ,xxcmm_cust_accounts       xca                     -- �ڋq�ǉ����
                ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h(�f�[�^���)
                ,fnd_lookup_values         flv1                    -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
                ,fnd_lookup_values         flv2                    -- �N�C�b�N�R�[�h(�`�F�[��)
          WHERE  xsd.customer_code_to                     = xca.customer_code                             -- �U�֐�ڋq�R�[�h
          AND    flv.lookup_code                          = xsd.data_type                                 -- �f�[�^���
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- �T���f�[�^���
          AND    flv.enabled_flag                         = cv_y_flag                                     -- �g�p�\�FY
          AND    flv.language                             = USERENV('LANG')                               -- ����FUSERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL�A�g�p���������s�O���[�v
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- �ŃR�[�h
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- �g�p�\�FY
          AND    flv1.language                            = USERENV('LANG')                               -- ����FUSERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- �����
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL�A�g�t���O N�F���A�g�AR�F�đ�
          AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag              -- �쐬���敪 S:�̔����сAT:������ѐU��(EDI)�AV:������ѐU��(�U�֊���)
                                                           , cv_u_flag, cv_f_flag)                        -- �쐬���敪 U:�A�b�v���[�h�AF:��z�T��
          AND    flv2.lookup_type(+)                      = 'XXCMM_CHAIN_CODE'                            -- �T���p�`�F�[���R�[�h
          AND    flv2.lookup_code(+)                      = xca.intro_chain_code2                         -- �ڋq�R�[�h
          AND    flv2.language(+)                         = USERENV('LANG')                               -- ����FUSERENV('LANG')
          AND    flv2.enabled_flag(+)                     = cv_y_flag                                     -- �g�p�\�FY
          AND    xsd.customer_code_to                    IS NOT NULL                                      -- �U�֐�ڋq�R�[�h
          UNION ALL
          -- �`�F�[��
--Ver 1.2 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
-- Ver 1.4 mod start
--          SELECT /*+ LEADING(flv XSD flv2 flv1)
--                     INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
--                     USE_HASH(XSD)
--                     USE_HASH(flv1)
--                     USE_HASH(flv2)*/
          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N08)*/
-- Ver 1.4 mod end
--Ver 1.2 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- �̔��T��ID
-- 2022/06/16 Ver1.5 MOD Start
                ,xsd.base_code_from             accounting_base       -- ���_�R�[�h
--                ,CASE
--                   WHEN flv.attribute2 = cv_teigaku_code THEN
--                     xsd.base_code_from
--                   ELSE
--                     NULL
--                 END                            accounting_base       -- ���_�R�[�h(��z�T��)
--                ,xsd.base_code_from             past_sale_base_code   -- �U�֌����_
-- 2022/06/16 Ver1.5 MOD End
                ,flv.attribute4                 account               -- ����Ȗ�
                ,flv.attribute5                 sub_account           -- �⏕�Ȗ�
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- �T���z
                ,flv1.attribute1                tax_code              -- �ŃR�[�h
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- �T���Ŋz
                ,NVL(flv2.attribute1,gv_comp_code)     corp_code      -- ��ƃR�[�h
                ,NVL(flv2.attribute4,gv_customer_code) customer_code  -- �ڋq�R�[�h
          FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
                ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h(�f�[�^���)
                ,fnd_lookup_values         flv1                    -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
                ,fnd_lookup_values         flv2                    -- �N�C�b�N�R�[�h(�`�F�[��)
          WHERE  flv.lookup_code                          = xsd.data_type                                 -- �f�[�^���
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- �T���f�[�^���
          AND    flv.enabled_flag                         = cv_y_flag                                     -- �g�p�\�FY
          AND    flv.language                             = USERENV('LANG')                               -- ����FUSERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL�A�g�p���������s�O���[�v
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- �ŃR�[�h
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- �g�p�\�FY
          AND    flv1.language                            = USERENV('LANG')                               -- ����FUSERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- �����
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL�A�g�t���O N�F���A�g�AR�F�đ�
          AND    xsd.source_category                     IN (cv_u_flag, cv_f_flag)                        -- �쐬���敪 U:�A�b�v���[�h�AF:��z�T��
          AND    flv2.lookup_type                         = 'XXCMM_CHAIN_CODE'                            -- �T���p�`�F�[���R�[�h
          AND    flv2.lookup_code                         = xsd.deduction_chain_code                      -- �`�F�[���R�[�h
          AND    flv2.language                            = USERENV('LANG')                               -- ����FUSERENV('LANG')
          AND    flv2.enabled_flag                        = cv_y_flag                                     -- �g�p�\�FY
          AND    xsd.deduction_chain_code                IS NOT NULL                                      -- �`�F�[���R�[�h
-- Ver 1.4 add start
          AND    xsd.customer_code_to                    IS NULL                                          -- �U�֐�ڋq�R�[�h
-- Ver 1.4 add end
          UNION ALL
          -- ���
-- Ver 1.4 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N08) */
-- Ver 1.4 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- �̔��T��ID
-- 2022/06/16 Ver1.5 MOD Start
                ,xsd.base_code_from             accounting_base       -- ���_�R�[�h
--                ,CASE
--                   WHEN flv.attribute2 = cv_teigaku_code THEN
--                     xsd.base_code_from
--                   ELSE
--                     NULL
--                 END                            accounting_base       -- ���_�R�[�h(��z�T��)
--                ,xsd.base_code_from             past_sale_base_code   -- �U�֌����_
-- 2022/06/16 Ver1.5 MOD End
                ,flv.attribute4                 account               -- ����Ȗ�
                ,flv.attribute5                 sub_account           -- �⏕�Ȗ�
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- �T���z
                ,flv1.attribute1                tax_code              -- �ŃR�[�h
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- �T���Ŋz
                ,xsd.corp_code                  corp_code             -- ��ƃR�[�h
                ,gv_customer_code               customer_code         -- �ڋq�R�[�h
          FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
                ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h(�f�[�^���)
                ,fnd_lookup_values         flv1                    -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
          WHERE  flv.lookup_code                          = xsd.data_type                                 -- �f�[�^���
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- �T���f�[�^���
          AND    flv.enabled_flag                         = cv_y_flag                                     -- �g�p�\�FY
          AND    flv.language                             = USERENV('LANG')                               -- ����FUSERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL�A�g�p���������s�O���[�v
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- �ŃR�[�h
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- �g�p�\�FY
          AND    flv1.language                            = USERENV('LANG')                               -- ����FUSERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- �����
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL�A�g�t���O N�F���A�g�AR�F�đ�
          AND    xsd.source_category                     IN (cv_u_flag, cv_f_flag)                        -- �쐬���敪 U:�A�b�v���[�h�AF:��z�T��
          AND    xsd.corp_code                           IS NOT NULL                                      -- ��ƃR�[�h
-- Ver 1.4 add start
          AND    xsd.deduction_chain_code                IS NULL                                          -- �`�F�[���R�[�h
          AND    xsd.customer_code_to                    IS NULL                                          -- �U�֐�ڋq�R�[�h
-- Ver 1.4 add end
         ) ;

    --==================================
    -- �̔��T���f�[�^���o
    --==================================
    OPEN  deductions_data_cur;
    FETCH deductions_data_cur BULK COLLECT INTO gt_deductions_exp_tbl;
    CLOSE deductions_data_cur;
--
    --==================================
    -- �̔��T���f�[�^_���ȖځE���z�̎擾
    --==================================
    OPEN  deductions_debt_data_cur;
    FETCH deductions_debt_data_cur BULK COLLECT INTO gt_deductions_debt_exp_tbl;
    CLOSE deductions_debt_data_cur;
--
      -- �擾�f�[�^���O���̏ꍇ
    IF ( gt_deductions_exp_tbl.COUNT = 0 OR gt_deductions_debt_exp_tbl.COUNT = 0 ) THEN
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- �A�v���P�[�V�����Z�k��
                                               , iv_name         => cv_tkn_deduction_msg           -- ���b�Z�[�WID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_data_get_msg
                                                );
      lv_errbuf       := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    --==================================
    -- �̔��T���f�[�^�̃��b�N
    --==================================
-- Ver 1.3 del start
--    OPEN  deductions_data_lock_cur;
--    FETCH deductions_data_lock_cur BULK COLLECT INTO gt_deduction_lock_tbl;
--    CLOSE deductions_data_lock_cur;
-- Ver 1.3 del end
--
  EXCEPTION
    -- �f�[�^�擾�G���[�i�f�[�^0���j ***
    WHEN no_data_expt THEN
      ov_retcode := cv_status_warn;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
      );
 --
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- ���b�N�G���[���b�Z�[�W
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- �A�v���P�[�V�����Z�k��
                                               , iv_name         => cv_tkn_deduction_msg           -- ���b�Z�[�WID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_table_lock_msg
                                                );
      lv_errbuf       := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- �J�[�\���N���[�Y
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_gl_data
   * Description      : A-4.��ʉ�vOIF�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE edit_gl_data( ov_errbuf          OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , ov_retcode         OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
                        , ov_errmsg          OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        , in_gl_idx          IN  NUMBER           -- GL OIF �f�[�^�C���f�b�N�X
                        , iv_accounting_base IN  VARCHAR2         -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--                        , iv_base_code       IN  VARCHAR2         -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
                        , iv_gl_segment3     IN  VARCHAR2         -- ����ȖڃR�[�h
                        , iv_gl_segment4     IN  VARCHAR2         -- �⏕�ȖڃR�[�h
                        , iv_tax_code        IN  VARCHAR2         -- �ŃR�[�h
                        , iv_corp_code       IN  VARCHAR2         -- ��ƃR�[�h
                        , iv_customer_code   IN  VARCHAR2         -- �ڋq�R�[�h
                        , in_entered_dr      IN  NUMBER           -- �ؕ����z
                        , in_entered_cr      IN  NUMBER           -- �ݕ����z
                        , in_gl_contact_id   IN  NUMBER           -- GL�R�tID
                        , iv_reference10     IN  VARCHAR2 )       -- reference10
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'edit_gl_data';      -- �v���O������
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCFO';             -- ���ʗ̈�Z�k�A�v����
    cv_ccid_chk_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10052';  -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
--
    -- CCID
    cv_tkn_pro_date    CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';      -- �g�[�N���F������
    cv_tkn_com_code    CONSTANT VARCHAR2(20)  := 'COM_CODE';          -- �g�[�N���F��ЃR�[�h
    cv_tkn_dept_code   CONSTANT VARCHAR2(20)  := 'DEPT_CODE';         -- �g�[�N���F����R�[�h
    cv_tkn_acc_code    CONSTANT VARCHAR2(20)  := 'ACC_CODE';          -- �g�[�N���F����ȖڃR�[�h
    cv_tkn_ass_code    CONSTANT VARCHAR2(20)  := 'ASS_CODE';          -- �g�[�N���F�⏕�ȖڃR�[�h
    cv_tkn_cust_code   CONSTANT VARCHAR2(20)  := 'CUST_CODE';         -- �g�[�N���F�ڋq�R�[�h
    cv_tkn_ent_code    CONSTANT VARCHAR2(20)  := 'ENT_CODE';          -- �g�[�N���F��ƃR�[�h
    cv_tkn_res1_code   CONSTANT VARCHAR2(20)  := 'RES1_CODE';         -- �g�[�N���F�\���P�R�[�h
    cv_tkn_res2_code   CONSTANT VARCHAR2(20)  := 'RES2_CODE';         -- �g�[�N���F�\���Q�R�[�h

--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_ccid_check  NUMBER;
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    --  ��ʉ�vOIF�f�[�^�쐬(A-4)
    --==============================================================
--
    ln_ccid_check := NULL;
    --==============================================================
    -- CCID���݃`�F�b�N
    --==============================================================
    ln_ccid_check := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_process_date                       -- ������
                             , iv_segment1  => gv_company_code                       -- ��ЃR�[�h
-- 2022/06/16 Ver1.5 MOD Start
                             , iv_segment2  => iv_accounting_base                    -- ����R�[�h
--                             , iv_segment2  => NVL(iv_accounting_base,iv_base_code)  -- ����R�[�h
-- 2022/06/16 Ver1.5 MOD End
                             , iv_segment3  => iv_gl_segment3                        -- ����ȖڃR�[�h
                             , iv_segment4  => iv_gl_segment4                        -- �⏕�ȖڃR�[�h
                             , iv_segment5  => iv_customer_code                      -- �ڋq�R�[�h�_�~�[�l
                             , iv_segment6  => iv_corp_code                          -- ��ƃR�[�h�_�~�[�l
                             , iv_segment7  => gv_preliminary1_code                  -- �\��1�_�~�[�l
                             , iv_segment8  => gv_preliminary2_code                  -- �\��2�_�~�[�l
                             );
--
    IF ( ln_ccid_check IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxccp_appl_name
                      , iv_name         => cv_ccid_chk_msg                       -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_pro_date
                      , iv_token_value1 => gd_process_date                       -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => gv_company_code                       -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
-- 2022/06/16 Ver1.5 MOD Start
                      , iv_token_value3 => iv_accounting_base                    -- ����R�[�h
--                      , iv_token_value3 => NVL(iv_accounting_base,iv_base_code)  -- ����R�[�h
-- 2022/06/16 Ver1.5 MOD End
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => iv_gl_segment3                        -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => iv_gl_segment4                        -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => iv_customer_code                      -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => iv_corp_code                          -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_preliminary1_code                  -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_preliminary2_code                  -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ��ʉ�vOIF�̒l�Z�b�g
    gt_gl_interface_tbl( in_gl_idx ).status                := cv_status;                                                -- �X�e�[�^�X
    gt_gl_interface_tbl( in_gl_idx ).set_of_books_id       := TO_NUMBER(gv_set_bks_id);                                 -- ��v����ID
    gt_gl_interface_tbl( in_gl_idx ).accounting_date       := gd_from_date;                                             -- �L����
    gt_gl_interface_tbl( in_gl_idx ).currency_code         := cv_currency_code;                                         -- �ʉ݃R�[�h
    gt_gl_interface_tbl( in_gl_idx ).actual_flag           := cv_actual_flag;                                           -- �c���^�C�v
    gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := gv_category_code;                                         -- �d��J�e�S����
    gt_gl_interface_tbl( in_gl_idx ).user_je_source_name   := gv_source_code;                                           -- �d��\�[�X��
    gt_gl_interface_tbl( in_gl_idx ).segment1              := gv_company_code;                                          -- (���)
--
    -- ���_�R�[�h(��z�T��) ���ݒ肳��Ă��Ȃ��ꍇ�́A���_�R�[�h(��z�T���ȊO)��o�^
-- 2022/06/16 Ver1.5 DEL Start
--    IF iv_accounting_base IS NULL THEN
--      gt_gl_interface_tbl( in_gl_idx ).segment2            := iv_base_code;                                             -- (����)
--    ELSE
-- 2022/06/16 Ver1.5 DEL End
      -- ���_�R�[�h(��z�T��) ���ݒ肳��Ă���ꍇ�́A���_�R�[�h(��z�T��)��o�^
      gt_gl_interface_tbl( in_gl_idx ).segment2            := iv_accounting_base;                                       -- (����)
-- 2022/06/16 Ver1.5 DEL Start
--    END IF;
-- 2022/06/16 Ver1.5 DEL End
--
    gt_gl_interface_tbl( in_gl_idx ).segment3              := iv_gl_segment3;                                           -- (����Ȗ�)
    gt_gl_interface_tbl( in_gl_idx ).segment4              := iv_gl_segment4;                                           -- (�⏕�Ȗ�)
    gt_gl_interface_tbl( in_gl_idx ).segment5              := iv_customer_code;                                         -- (�ڋq�R�[�h)
    gt_gl_interface_tbl( in_gl_idx ).segment6              := iv_corp_code;                                             -- (��ƃR�[�h)
    gt_gl_interface_tbl( in_gl_idx ).segment7              := gv_preliminary1_code;                                     -- (�\���P)
    gt_gl_interface_tbl( in_gl_idx ).segment8              := gv_preliminary2_code;                                     -- (�\���Q)
--
    -- ����T�����z���v���X�̏ꍇ�͂��̂܂ܓo�^
    IF (in_entered_dr >= 0 AND in_entered_cr IS NULL) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_dr;                                            -- �ؕ����z
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_cr;                                            -- �ݕ����z
    -- ����T�����z���}�C�i�X�̏ꍇ�͑ݎ؂����ւ��o�^
    ELSIF (in_entered_dr < 0 AND in_entered_cr IS NULL ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_cr;                                            -- �ؕ����z
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := (in_entered_dr * -1);                                     -- �ݕ����z
    -- ���z���v���X�̏ꍇ�͂��̂܂ܓo�^
    ELSIF (in_entered_dr IS NULL AND in_entered_cr >= 0 ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_dr;                                            -- �ؕ����z
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_cr;                                            -- �ݕ����z
    -- ���z���}�C�i�X�̏ꍇ�͑ݎ؂����֓o�^
    ELSIF (in_entered_dr IS NULL AND in_entered_cr < 0 ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := (in_entered_cr * -1);                                     -- �ؕ����z
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_dr;                                            -- �ݕ����z
    END IF;
--
    gt_gl_interface_tbl( in_gl_idx ).reference1            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- ���t�@�����X1�i�o�b�`���j
    gt_gl_interface_tbl( in_gl_idx ).reference2            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- ���t�@�����X2�i�o�b�`�E�v�j
    gt_gl_interface_tbl( in_gl_idx ).reference4            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- ���t�@�����X4�i�d�󖼁j
    gt_gl_interface_tbl( in_gl_idx ).reference5            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- ���t�@�����X5�i�d�󖼓E�v�j
    gt_gl_interface_tbl( in_gl_idx ).reference10           := iv_reference10;                                           -- ���t�@�����X10�i�d�󖾍דE�v�j
    gt_gl_interface_tbl( in_gl_idx ).period_name           := gv_period;                                                -- ��v����
--2021/05/18 add start
    gt_gl_interface_tbl( in_gl_idx ).group_id              := gn_group_id;                                              -- �O���[�vID
--2021/05/18 add end
    gt_gl_interface_tbl( in_gl_idx ).attribute1            := iv_tax_code;                                              -- ����1�i����ŃR�[�h�j
    gt_gl_interface_tbl( in_gl_idx ).attribute8            := in_gl_contact_id;                                         -- ����8�iGL�R�tID�j
    gt_gl_interface_tbl( in_gl_idx ).context               := gv_set_bks_nm;                                            -- �R���e�L�X�g
    gt_gl_interface_tbl( in_gl_idx ).created_by            := cn_created_by;                                            -- �V�K�쐬��
    gt_gl_interface_tbl( in_gl_idx ).date_created          := cd_creation_date;                                         -- �V�K�쐬��
    gt_gl_interface_tbl( in_gl_idx ).request_id            := cn_request_id;                                            -- �v��ID
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#####################################  �Œ蕔 END  #####################################
--
  END edit_gl_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_work_data
   * Description      : A-3.��ʉ�vOIF�W�񏈗�
   ***********************************************************************************/
  PROCEDURE edit_work_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           -- # �Œ� #
                          , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             -- # �Œ� #
                          , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_work_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_deduction_amount          NUMBER DEFAULT 0;                               -- ����T��:�T���z�W�v���z
    ln_deduction_tax_amount      NUMBER DEFAULT 0;                               -- ���������:�T���Ŋz�W�v���z
    ln_gl_contact_id             NUMBER;                                         -- GL�A�gID
--
    ln_gl_idx                    NUMBER DEFAULT 0;                               -- GL OIF�̃C���f�b�N�X
    ln_loop_index1               NUMBER DEFAULT 0;                               -- ���[�N�e�[�u���̔��T���C���f�b�N�X
    ln_loop_index2               NUMBER DEFAULT 0;                               -- ���[�N�e�[�u���̔��T�����C���f�b�N�X
    ln_loop_cnt                  NUMBER DEFAULT 0;                               -- ��z�T���m�F�p����
    lv_account_code              VARCHAR2(5);                                    -- �ŃR�[�h����Ȗڗp
    lv_sub_account_code          VARCHAR2(5);                                    -- �ŃR�[�h�⏕�Ȗڗp
    lv_debt_account_code         VARCHAR2(5);                                    -- �ŃR�[�h����Ȗڗp
    lv_debt_sub_account_code     VARCHAR2(5);                                    -- �ŃR�[�h�⏕�Ȗڗp
--
    -- �W�v�L�[
    lt_accounting_base           xxcok_condition_lines.accounting_base%TYPE;     -- �W�v�L�[�F���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--    lt_past_sale_base_code       xxcmm_cust_accounts.past_sale_base_code%TYPE;   -- �W�v�L�[�F���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
    lt_account                   fnd_lookup_values.attribute4%TYPE;              -- �W�v�L�[�F����Ȗ�
    lt_sub_account               fnd_lookup_values.attribute5%TYPE;              -- �W�v�L�[�F�⏕�Ȗ�
    lt_tax_code                  xxcok_sales_deduction.tax_code%TYPE;            -- �W�v�L�[�F�ŃR�[�h
    lt_corp_code                 fnd_lookup_values.attribute1%TYPE;              -- �W�v�L�[�F��ƃR�[�h
    lt_customer_code             fnd_lookup_values.attribute4%TYPE;              -- �W�v�L�[�F�ڋq�R�[�h
--
    -- *** ���[�J����O ***
    edit_gl_expt                 EXCEPTION;                                      -- ��ʉ�v�쐬�G���[
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --=====================================
    -- 1.�d��p�^�[���̎擾
    --=====================================
    -- �u���C�N�p�W��L�[�̏�����
    lt_accounting_base      := gt_deductions_exp_tbl(1).accounting_base;      -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--    lt_past_sale_base_code  := gt_deductions_exp_tbl(1).past_sale_base_code;  -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
    lt_account              := gt_deductions_exp_tbl(1).account;              -- ����Ȗ�
    lt_sub_account          := gt_deductions_exp_tbl(1).sub_account;          -- �⏕�Ȗ�
    lt_tax_code             := gt_deductions_exp_tbl(1).tax_code;             -- �ŃR�[�h
    lt_corp_code            := gt_deductions_exp_tbl(1).corp_code;            -- ��ƃR�[�h
    lt_customer_code        := gt_deductions_exp_tbl(1).customer_code;        -- �ڋq�R�[�h
--
    -- �T���z/�����/������ł̃��[�v�X�^�[�g
    <<main_data_loop>>
    FOR ln_loop_index1 IN 1..gt_deductions_exp_tbl.COUNT LOOP
--
      -- ==========================
      --  ���R�[�h�u���C�N����
      -- ==========================
--
      -- ��z�T���̏ꍇ
-- 2022/06/16 Ver1.5 DEL Start
--      IF ( lt_accounting_base IS NOT NULL) THEN
-- 2022/06/16 Ver1.5 DEL End
        -- ���_�R�[�h(��z�T��)/����Ȗ�/�⏕�Ȗ�/�ŃR�[�h�̂����ꂩ���O�����f�[�^�قȂ����ꍇ
        IF ( lt_accounting_base   <> NVL(gt_deductions_exp_tbl(ln_loop_index1).accounting_base,cv_dummy_code) )
          OR  ( lt_account               <> gt_deductions_exp_tbl(ln_loop_index1).account )
          OR  ( lt_sub_account           <> gt_deductions_exp_tbl(ln_loop_index1).sub_account )
          OR  ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code )
          OR  ( lt_corp_code             <> gt_deductions_exp_tbl(ln_loop_index1).corp_code )
          OR  ( lt_customer_code         <> gt_deductions_exp_tbl(ln_loop_index1).customer_code ) THEN

--
          --�̔��T���f�[�^�̏W��(��p)
          ln_gl_idx := ln_gl_idx + 1;
--
          edit_gl_data( ov_errbuf                 => lv_errbuf                 -- �G���[�E���b�Z�[�W
                      , ov_retcode                => lv_retcode                -- ���^�[���E�R�[�h
                      , ov_errmsg                 => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
                      , in_gl_idx                 => ln_gl_idx                 -- GL OIF �f�[�^�C���f�b�N�X
                      , iv_accounting_base        => lt_accounting_base        -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--                      , iv_base_code              => lt_past_sale_base_code    -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
                      , iv_gl_segment3            => lt_account                -- ����ȖڃR�[�h
                      , iv_gl_segment4            => lt_sub_account            -- �⏕�ȖڃR�[�h
                      , iv_tax_code               => lt_tax_code               -- �ŃR�[�h
                      , iv_corp_code              => lt_corp_code              -- ��ƃR�[�h
                      , iv_customer_code          => lt_customer_code          -- �ڋq�R�[�h
                      , in_entered_dr             => ln_deduction_amount       -- �ؕ����z
                      , in_entered_cr             => NULL                      -- �ݕ����z
                      , in_gl_contact_id          => ln_gl_contact_id          -- GL�R�tID
                      , iv_reference10            => gv_category_code || cv_underbar || gv_period
                                                                               -- reference10
                       );
--
--Ver 1.2 add start
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_gl_expt;
          END IF;
--
--Ver 1.2 add end
          --�T���z�W�񏉊���
          ln_deduction_amount := 0;
--
          ln_loop_cnt := 0;
--
        END IF;
--
-- 2022/06/16 Ver1.5 DEL Start
--      -- ��z�T���ȊO�̏ꍇ
--      ELSE
--        -- ���_�R�[�h(��z�T���ȊO)/����Ȗ�/�⏕�Ȗ�/�ŃR�[�h�̂����ꂩ���O�����f�[�^�قȂ����ꍇ
--        IF ( lt_past_sale_base_code   <> gt_deductions_exp_tbl(ln_loop_index1).past_sale_base_code )
--          OR  ( lt_account               <> gt_deductions_exp_tbl(ln_loop_index1).account )
--          OR  ( lt_sub_account           <> gt_deductions_exp_tbl(ln_loop_index1).sub_account )
--          OR  ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code )
--          OR  ( lt_corp_code             <> gt_deductions_exp_tbl(ln_loop_index1).corp_code )
--          OR  ( lt_customer_code         <> gt_deductions_exp_tbl(ln_loop_index1).customer_code ) THEN
----
--          --�̔��T���f�[�^�̏W��(��p)
--          ln_gl_idx := ln_gl_idx + 1;
----
--          edit_gl_data( ov_errbuf                 => lv_errbuf                 -- �G���[�E���b�Z�[�W
--                      , ov_retcode                => lv_retcode                -- ���^�[���E�R�[�h
--                      , ov_errmsg                 => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--                      , in_gl_idx                 => ln_gl_idx                 -- GL OIF �f�[�^�C���f�b�N�X
--                      , iv_accounting_base        => lt_accounting_base        -- ���_�R�[�h(��z�T��)
--                      , iv_base_code              => lt_past_sale_base_code    -- ���_�R�[�h(��z�T���ȊO)
--                      , iv_gl_segment3            => lt_account                -- ����ȖڃR�[�h
--                      , iv_gl_segment4            => lt_sub_account            -- �⏕�ȖڃR�[�h
--                      , iv_tax_code               => lt_tax_code               -- �ŃR�[�h
--                      , iv_corp_code              => lt_corp_code              -- ��ƃR�[�h
--                      , iv_customer_code          => lt_customer_code          -- �ڋq�R�[�h
--                      , in_entered_dr             => ln_deduction_amount       -- �ؕ����z
--                      , in_entered_cr             => NULL                      -- �ݕ����z
--                      , in_gl_contact_id          => ln_gl_contact_id          -- GL�R�tID
--                      , iv_reference10            => gv_category_code || cv_underbar || gv_period
--                                                                               -- reference10
--                       );
----
--          IF ( lv_retcode = cv_status_error ) THEN
--            RAISE edit_gl_expt;
--          END IF;
----
--          --�T���z�W�񏉊���
--          ln_deduction_amount := 0;
----
--          ln_loop_cnt := 0;
----
--        END IF;
----
--      END IF;
-- 2022/06/16 Ver1.5 DEL End
--
      -- �ŃR�[�h���O�����f�[�^�قȂ����ꍇ
      IF ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code ) THEN
--
        --�ŃR�[�h�}�X�^���ŃR�[�h�������n���Ċ���ȖځA�⏕�Ȗڂ��擾
        BEGIN
          SELECT gcc.segment3            -- �Ŋz_����Ȗ�
                ,gcc.segment4            -- �Ŋz_�⏕�Ȗ�
                ,tax.attribute5          -- ���Ŋz_����Ȗ�
                ,tax.attribute6          -- ���Ŋz_�⏕�Ȗ�
          INTO   lv_account_code
                ,lv_sub_account_code
                ,lv_debt_account_code
                ,lv_debt_sub_account_code
          FROM   apps.ap_tax_codes_all     tax  -- AP�ŃR�[�h�}�X�^
                ,apps.gl_code_combinations gcc  -- ����g�����
          WHERE  tax.set_of_books_id     = TO_NUMBER(gv_set_bks_id)       -- SET_OF_BOOKS_ID
          and    tax.org_id              = gn_org_id                      -- ORG_ID
          and    gcc.code_combination_id = tax.tax_code_combination_id    -- ��CCID
          and    tax.name                = lt_tax_code                    -- �ŃR�[�h
          AND    tax.enabled_flag        = cv_y_flag                      -- �L��
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
          -- ����Ȗڂ��擾�o���Ȃ��ꍇ
            lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                  , cv_account_error_msg
                                                   );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        --�̔��T���f�[�^�̏W��(�ŁE��p)
        ln_gl_idx := ln_gl_idx + 1;
--
        edit_gl_data( ov_errbuf                 => lv_errbuf                       -- �G���[�E���b�Z�[�W
                    , ov_retcode                => lv_retcode                      -- ���^�[���E�R�[�h
                    , ov_errmsg                 => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                    , in_gl_idx                 => ln_gl_idx                       -- GL OIF �f�[�^�C���f�b�N�X
-- 2022/06/16 Ver1.5 MOD Start
                    , iv_accounting_base        => gv_dept_fin_code                -- ���_�R�[�h
--                    , iv_accounting_base        => NULL                            -- ���_�R�[�h(��z�T��)
--                    , iv_base_code              => gv_dept_fin_code                -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
                    , iv_gl_segment3            => lv_account_code                 -- ����ȖڃR�[�h
                    , iv_gl_segment4            => lv_sub_account_code             -- �⏕�ȖڃR�[�h
                    , iv_tax_code               => lt_tax_code                     -- �ŃR�[�h
                    , iv_corp_code              => gv_comp_code                    -- ��ƃR�[�h
                    , iv_customer_code          => gv_customer_code                -- �ڋq�R�[�h
                    , in_entered_dr             => ln_deduction_tax_amount         -- �ؕ����z
                    , in_entered_cr             => NULL                            -- �ݕ����z
                    , in_gl_contact_id          => NULL                            -- GL�R�tID
                    , iv_reference10            => '����ōs' || cv_underbar || lt_tax_code
                                                                                   -- reference10
                     );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE edit_gl_expt;
        END IF;
--
        --�̔��T���f�[�^�̏W��(�ŁE����)
        ln_gl_idx := ln_gl_idx + 1;
--
        edit_gl_data( ov_errbuf                 => lv_errbuf                     -- �G���[�E���b�Z�[�W
                    , ov_retcode                => lv_retcode                    -- ���^�[���E�R�[�h
                    , ov_errmsg                 => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
                    , in_gl_idx                 => ln_gl_idx                     -- GL OIF �f�[�^�C���f�b�N�X
-- 2022/06/16 Ver1.5 MOD Start
                    , iv_accounting_base        => gv_dept_fin_code              -- ���_�R�[�h
--                    , iv_accounting_base        => NULL                          -- ���_�R�[�h(��z�T��)
--                    , iv_base_code              => gv_dept_fin_code              -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
                    , iv_gl_segment3            => lv_debt_account_code          -- ����ȖڃR�[�h
                    , iv_gl_segment4            => lv_debt_sub_account_code      -- �⏕�ȖڃR�[�h
                    , iv_tax_code               => NULL                          -- �ŃR�[�h
                    , iv_corp_code              => gv_comp_code                  -- ��ƃR�[�h
                    , iv_customer_code          => gv_customer_code              -- �ڋq�R�[�h
                    , in_entered_dr             => NULL                          -- �ؕ����z
                    , in_entered_cr             => ln_deduction_tax_amount       -- �ݕ����z
                    , in_gl_contact_id          => NULL                          -- GL�R�tID
                    , iv_reference10            => '���ōs' || cv_underbar || lt_tax_code
                                                                                   -- reference10
                     );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE edit_gl_expt;
        END IF;
--
        --����Ŋz�W�񏉊���
        ln_deduction_tax_amount := 0;
--
      END IF;
--
      --�o�͗p���z�̏W��
      -- �T���z�̏W��
      ln_deduction_amount      := NVL(ln_deduction_amount,0)     + NVL(gt_deductions_exp_tbl(ln_loop_index1).deduction_amount,0);
      -- ����Ŋz�̏W��
      ln_deduction_tax_amount  := NVL(ln_deduction_tax_amount,0) + NVL(gt_deductions_exp_tbl(ln_loop_index1).deduction_tax_amount,0);
--
      -- �u���C�N�p�W��L�[�Z�b�g
      lt_accounting_base       := gt_deductions_exp_tbl(ln_loop_index1).accounting_base;       -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--      lt_past_sale_base_code   := gt_deductions_exp_tbl(ln_loop_index1).past_sale_base_code;   -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
      lt_account               := gt_deductions_exp_tbl(ln_loop_index1).account;               -- ����Ȗ�
      lt_sub_account           := gt_deductions_exp_tbl(ln_loop_index1).sub_account;           -- �⏕�Ȗ�
      lt_tax_code              := gt_deductions_exp_tbl(ln_loop_index1).tax_code;              -- �ŃR�[�h
      lt_corp_code             := gt_deductions_exp_tbl(ln_loop_index1).corp_code;             -- ��ƃR�[�h
      lt_customer_code         := gt_deductions_exp_tbl(ln_loop_index1).customer_code;         -- �ڋq�R�[�h
--
-- 2022/06/16 Ver1.5 DEL Start
--      --�����������擾
--      gn_target_cnt             := gn_target_cnt + 1;
--
--      --�X�V�����p�ɔ̔��T��ID�AGL�v�㋒�_���擾
--      gt_deduction_tbl( ln_loop_index1 ).sales_deduction_id := gt_deductions_exp_tbl(ln_loop_index1).sales_deduction_id;
--      gt_deduction_tbl( ln_loop_index1 ).gl_base_code       := NVL(gt_deductions_exp_tbl(ln_loop_index1).accounting_base,
-- 2022/06/16 Ver1.5 DEL End

--
      IF ( ln_loop_cnt = 0 ) THEN
        --GL�R�tID�擾
        SELECT xxcok_gl_interface_seq_s01.NEXTVAL gl_seq
        INTO   ln_gl_contact_id
        FROM   DUAL
        ;
--
        ln_loop_cnt := 1;
--
      END IF;
--
-- 2022/06/16 Ver1.5 DEL Start
--      -- �X�V�����p��GL�R�tID���擾
--      gt_deduction_tbl( ln_loop_index1 ).gl_interface_id := ln_gl_contact_id;
-- 2022/06/16 Ver1.5 DEL End
-- 2022/06/16 Ver1.5 ADD Start
      UPDATE xxcok_sales_deduction     xsd                                                   -- �̔��T�����
      SET    xsd.gl_if_flag             = cv_y_flag                                          -- GL�C���^�t�F�[�X�σt���O
            ,xsd.gl_date                = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              gd_from_date
                                            ELSE
                                              xsd.gl_date
                                          END                                                -- GL�L����
            ,xsd.gl_base_code           = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              gt_deductions_exp_tbl(ln_loop_index1).accounting_base
                                            ELSE
                                              xsd.gl_base_code
                                          END                                                -- GL�v�㋒�_
            ,xsd.cancel_gl_date         = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              xsd.cancel_gl_date
                                            ELSE
                                              gd_from_date
                                          END                                                -- ���GL�L����
            ,xsd.cancel_base_code       = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              xsd.cancel_base_code
                                            ELSE
                                              gt_deductions_exp_tbl(ln_loop_index1).accounting_base
                                          END                                                -- ������v�㋒�_
            ,xsd.gl_interface_id        = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              ln_gl_contact_id
                                            ELSE
                                               xsd.gl_interface_id
                                          END                                                -- GL�R�tID
            ,xsd.cancel_gl_interface_id = CASE
                                            WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                              xsd.cancel_gl_interface_id
                                            ELSE
                                              ln_gl_contact_id
                                            END                                              -- ���GL�R�tID
            ,xsd.last_updated_by        =   cn_last_updated_by                                 -- �ŏI�X�V��
            ,xsd.last_update_date       =   cd_last_update_date                                -- �ŏI�X�V��
            ,xsd.last_update_login      =   cn_last_update_login                               -- �ŏI�X�V���O�C��
            ,xsd.request_id             =   cn_request_id                                      -- �v��ID
            ,xsd.program_application_id =   cn_program_application_id                          -- �R���J�����g�E�v���O�����E�A�v��ID
            ,xsd.program_id             =   cn_program_id                                      -- �R���J�����g�E�v���O����ID
            ,xsd.program_update_date    =   cd_program_update_date                             -- �v���O�����X�V��
      WHERE xsd.sales_deduction_id      IN  ( SELECT  temp.sales_deduction_id sales_deduction_id
                                              FROM    XXCOK_XXCOK024A06C_TEMP  temp
                                              WHERE   temp.tax_code         = gt_deductions_exp_tbl(ln_loop_index1).tax_code
                                              AND     temp.accounting_base  = gt_deductions_exp_tbl(ln_loop_index1).accounting_base
                                              AND     temp.account          = gt_deductions_exp_tbl(ln_loop_index1).account
                                              AND     temp.sub_account      = gt_deductions_exp_tbl(ln_loop_index1).sub_account
                                              AND     temp.corp_code        = gt_deductions_exp_tbl(ln_loop_index1).corp_code
                                              AND     temp.customer_code    = gt_deductions_exp_tbl(ln_loop_index1).customer_code );
--
      gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
-- 2022/06/16 Ver1.5 ADD End
--
    END LOOP main_data_loop ;
--
    --�ŏI���R�[�h�o��
    IF ( gt_deductions_exp_tbl.COUNT > 0 ) THEN
--
      --�̔��T���f�[�^�̏W��
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                 -- �G���[�E���b�Z�[�W
                  , ov_retcode                => lv_retcode                -- ���^�[���E�R�[�h
                  , ov_errmsg                 => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
                  , in_gl_idx                 => ln_gl_idx                 -- GL OIF �f�[�^�C���f�b�N�X
                  , iv_accounting_base        => lt_accounting_base        -- ���_�R�[�h(��z�T��)
-- 2022/06/16 Ver1.5 DEL Start
--                  , iv_base_code              => lt_past_sale_base_code    -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 DEL End
                  , iv_gl_segment3            => lt_account                -- ����ȖڃR�[�h
                  , iv_gl_segment4            => lt_sub_account            -- �⏕�ȖڃR�[�h
                  , iv_tax_code               => lt_tax_code               -- �ŃR�[�h
                  , iv_corp_code              => lt_corp_code              -- ��ƃR�[�h
                  , iv_customer_code          => lt_customer_code          -- �ڋq�R�[�h
                  , in_entered_dr             => ln_deduction_amount       -- �ؕ����z
                  , in_entered_cr             => NULL                      -- �ݕ����z
                  , in_gl_contact_id          => ln_gl_contact_id          -- GL�R�tID
                  , iv_reference10            => gv_category_code || cv_underbar || gv_period
                                                                           -- reference10
                 );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
      --�ŃR�[�h�}�X�^���ŃR�[�h�������n���Ċ���ȖځA�⏕�Ȗڂ��擾
      BEGIN
        SELECT gcc.segment3            -- �Ŋz_����Ȗ�
              ,gcc.segment4            -- �Ŋz_�⏕�Ȗ�
              ,tax.attribute5          -- ���Ŋz_����Ȗ�
              ,tax.attribute6          -- ���Ŋz_�⏕�Ȗ�
        INTO   lv_account_code
              ,lv_sub_account_code
              ,lv_debt_account_code
              ,lv_debt_sub_account_code
        FROM   apps.ap_tax_codes_all     tax  -- AP�ŃR�[�h�}�X�^
              ,apps.gl_code_combinations gcc  -- ����g�����
        WHERE  tax.set_of_books_id     = TO_NUMBER(gv_set_bks_id)       -- SET_OF_BOOKS_ID
        and    tax.org_id              = gn_org_id                      -- ORG_ID
        and    gcc.code_combination_id = tax.tax_code_combination_id    -- ��CCID
        and    tax.name                = lt_tax_code                    -- �ŃR�[�h
        AND    tax.enabled_flag        = cv_y_flag                      -- �L��
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
        -- ����Ȗڂ��擾�o���Ȃ��ꍇ
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                , cv_account_error_msg
                                                 );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      --�̔��T���f�[�^�̏W��
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                       -- �G���[�E���b�Z�[�W
                  , ov_retcode                => lv_retcode                      -- ���^�[���E�R�[�h
                  , ov_errmsg                 => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
                  , in_gl_idx                 => ln_gl_idx                       -- GL OIF �f�[�^�C���f�b�N�X
-- 2022/06/16 Ver1.5 MOD Start
                  , iv_accounting_base        => gv_dept_fin_code                -- ���_�R�[�h
--                  , iv_accounting_base        => NULL                            -- ���_�R�[�h(��z�T��)
--                  , iv_base_code              => gv_dept_fin_code                -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
                  , iv_gl_segment3            => lv_account_code                 -- ����ȖڃR�[�h
                  , iv_gl_segment4            => lv_sub_account_code             -- �⏕�ȖڃR�[�h
                  , iv_tax_code               => lt_tax_code                     -- �ŃR�[�h
                  , iv_corp_code              => gv_comp_code                    -- ��ƃR�[�h
                  , iv_customer_code          => gv_customer_code                -- �ڋq�R�[�h
                  , in_entered_dr             => ln_deduction_tax_amount         -- �ؕ����z
                  , in_entered_cr             => NULL                            -- �ݕ����z
                  , in_gl_contact_id          => NULL                            -- GL�R�tID
                  , iv_reference10            => '����ōs' || cv_underbar || lt_tax_code
                                                                                 -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
      --�̔��T���f�[�^�̏W��
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                     -- �G���[�E���b�Z�[�W
                  , ov_retcode                => lv_retcode                    -- ���^�[���E�R�[�h
                  , ov_errmsg                 => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
                  , in_gl_idx                 => ln_gl_idx                     -- GL OIF �f�[�^�C���f�b�N�X
-- 2022/06/16 Ver1.5 MOD Start
                  , iv_accounting_base        => gv_dept_fin_code              -- ���_�R�[�h
--                  , iv_accounting_base        => NULL                          -- ���_�R�[�h(��z�T��)
--                  , iv_base_code              => gv_dept_fin_code              -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
                  , iv_gl_segment3            => lv_debt_account_code          -- ����ȖڃR�[�h
                  , iv_gl_segment4            => lv_debt_sub_account_code      -- �⏕�ȖڃR�[�h
                  , iv_tax_code               => NULL                          -- �ŃR�[�h
                  , iv_corp_code              => gv_comp_code                  -- ��ƃR�[�h
                  , iv_customer_code          => gv_customer_code              -- �ڋq�R�[�h
                  , in_entered_dr             => NULL                          -- �ؕ����z
                  , in_entered_cr             => ln_deduction_tax_amount       -- �ݕ����z
                  , in_gl_contact_id          => NULL                          -- GL�R�tID
                  , iv_reference10            => '���ōs' || cv_underbar || lt_tax_code
                                                                               -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
    END IF;
--
    -- ���z�̃��[�v�X�^�[�g
    <<debt_data_loop>>
    FOR ln_loop_index2 IN 1..gt_deductions_debt_exp_tbl.COUNT LOOP
--
      --�̔��T���f�[�^�̏W��
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                                                    -- �G���[�E���b�Z�[�W
                  , ov_retcode                => lv_retcode                                                   -- ���^�[���E�R�[�h
                  , ov_errmsg                 => lv_errmsg                                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                  , in_gl_idx                 => ln_gl_idx                                                    -- GL OIF �f�[�^�C���f�b�N�X
-- 2022/06/16 Ver1.5 MOD Start
                  , iv_accounting_base        => gv_dept_fin_code                                             -- ���_�R�[�h
--                  , iv_accounting_base        => NULL                                                         -- ���_�R�[�h(��z�T��)
--                  , iv_base_code              => gv_dept_fin_code                                             -- ���_�R�[�h(��z�T���ȊO)
-- 2022/06/16 Ver1.5 MOD End
                  , iv_gl_segment3            => gt_deductions_debt_exp_tbl(ln_loop_index2).account           -- ����ȖڃR�[�h
                  , iv_gl_segment4            => gt_deductions_debt_exp_tbl(ln_loop_index2).sub_account       -- �⏕�ȖڃR�[�h
                  , iv_tax_code               => NULL                                                         -- �ŃR�[�h
                  , iv_corp_code              => gv_comp_code                                                 -- ��ƃR�[�h
                  , iv_customer_code          => gv_customer_code                                             -- �ڋq�R�[�h
                  , in_entered_dr             => NULL                                                         -- �ؕ����z
                  , in_entered_cr             => gt_deductions_debt_exp_tbl(ln_loop_index2).deduction_amount  -- �ݕ����z
                  , in_gl_contact_id          => NULL                                                         -- GL�R�tID
                  , iv_reference10            => gv_category_code || cv_underbar || gv_period                 -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
    END LOOP debt_data_loop ;
--
    --��ʉ�vOIF�ɍ쐬�����������擾
    gn_normal_cnt := ln_gl_idx;
--
  EXCEPTION
    WHEN edit_gl_expt THEN
--Ver 1.2 del start
--      lv_errbuf  := lv_errmsg;
--Ver 1.2 del end
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
--
  END edit_work_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : A-5.��ʉ�vOIF�o�^����
   ***********************************************************************************/
  PROCEDURE insert_gl_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
                          , ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
                          , ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm           VARCHAR2(255);                -- �e�[�u����
--
    -- *** ���[�J����O ***
    insert_data_expt    EXCEPTION ;                   -- �o�^�����G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_gl_interface_tbl.COUNT
        INSERT INTO
          gl_interface
        VALUES
          gt_gl_interface_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE insert_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm               -- �A�v���Z�k��
                      , iv_name              => cv_tkn_gloif_msg                -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
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
--#####################################  �Œ蕔 END  #####################################
--
  END insert_gl_data;
--
-- 2022/06/16 Ver1.5 DEL Start
--  /***********************************************************************************
--   * Procedure Name   : update_deduction_data
--   * Description      : �̔��T�����X�V����(A-6)
--   ***********************************************************************************/
--  PROCEDURE update_deduction_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
--                                  ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
--                                  ,ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(25) := 'update_deduction_data'; -- �v���O������
----
----############################  �Œ胍�[�J���ϐ��錾�� START  ############################
----
--    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----#####################################  �Œ蕔 END  #####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_loop_cnt         NUMBER DEFAULT 0;      -- ���[�v�J�E���g�p�ϐ�
----
--    -- *** ���[�J����O ***
--    update_data_expt    EXCEPTION ;            -- �X�V�����G���[
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- *** ���[�J���E���R�[�h ***
--  BEGIN
----
----############################  �Œ�X�e�[�^�X�������� START  ############################
----
--    ov_retcode := cv_status_normal;
----
----#####################################  �Œ蕔 END  #####################################
----
--    --==============================================================
--    -- �̔��T�����X�V����
--    --==============================================================
----
--    -- �����Ώۃf�[�^��GL�A�g�t���O���ꊇ�X�V����
--    IF ( gt_deductions_exp_tbl.COUNT > 0 ) THEN
--      -- ����f�[�^�X�V
--      --�đ��̏ꍇ�͎��GL�L�����̍X�V���s��
----
--      BEGIN
--        FORALL ln_loop_cnt IN 1..gt_deduction_tbl.COUNT
--          UPDATE xxcok_sales_deduction     xsd                                                   -- �̔��T�����
--          SET    xsd.gl_if_flag             = cv_y_flag                                          -- GL�C���^�t�F�[�X�σt���O
--                ,xsd.gl_date                = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  gd_from_date
--                                                ELSE
--                                                  xsd.gl_date
--                                              END                                                -- GL�L����
--                ,xsd.gl_base_code           = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  gt_deduction_tbl(ln_loop_cnt).gl_base_code
--                                                ELSE
--                                                  xsd.gl_base_code
--                                              END                                                -- GL�v�㋒�_
--                ,xsd.cancel_gl_date         = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  xsd.cancel_gl_date
--                                                ELSE
--                                                  gd_from_date
--                                              END                                                -- ���GL�L����
--                ,xsd.cancel_base_code       = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  xsd.cancel_base_code
--                                                ELSE
--                                                  gt_deduction_tbl(ln_loop_cnt).gl_base_code
--                                              END                                                -- ������v�㋒�_
--                ,xsd.gl_interface_id        = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  gt_deduction_tbl(ln_loop_cnt).gl_interface_id
--                                                ELSE
--                                                   xsd.gl_interface_id
--                                              END                                                -- GL�R�tID
--                ,xsd.cancel_gl_interface_id = CASE
--                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
--                                                  xsd.cancel_gl_interface_id
--                                                ELSE
--                                                  gt_deduction_tbl(ln_loop_cnt).gl_interface_id
--                                                END                                              -- ���GL�R�tID
--                ,xsd.last_updated_by        = cn_last_updated_by                                 -- �ŏI�X�V��
--                ,xsd.last_update_date       = cd_last_update_date                                -- �ŏI�X�V��
--                ,xsd.last_update_login      = cn_last_update_login                               -- �ŏI�X�V���O�C��
--                ,xsd.request_id             = cn_request_id                                      -- �v��ID
--                ,xsd.program_application_id = cn_program_application_id                          -- �R���J�����g�E�v���O�����E�A�v��ID
--                ,xsd.program_id             = cn_program_id                                      -- �R���J�����g�E�v���O����ID
--                ,xsd.program_update_date    = cd_program_update_date                             -- �v���O�����X�V��
--          WHERE xsd.sales_deduction_id      = gt_deduction_tbl(ln_loop_cnt).sales_deduction_id   -- �̔��T��ID
--          ;
----
--        EXCEPTION
--          WHEN OTHERS THEN
--            lv_errbuf := SQLERRM;
--            RAISE update_data_expt;
--      END;
----
--    END IF;
----
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
----
--  EXCEPTION
--    WHEN update_data_expt THEN
--      -- �X�V�Ɏ��s�����ꍇ
--      -- �G���[�����ݒ�
--      ov_errmsg    := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_xxcok_short_nm
--                        , iv_name         => cv_data_update_msg
--                        , iv_token_name1  => cv_tkn_tbl_nm
--                        , iv_token_value1 => cv_sales_deduction
--                        , iv_token_name2  => cv_tkn_key_data
--                        , iv_token_value2 => gt_deduction_tbl(ln_loop_cnt).sales_deduction_id
--                      );
--      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--      ov_retcode   := cv_status_error;
----
----################################  �Œ��O������ START  ################################
----
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END  #####################################
----
--  END update_deduction_data;
-- 2022/06/16 Ver1.5 DEL End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
                   , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
                   , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
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
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    -- �O���[�o���ϐ��̏�����
    gn_normal_cnt    := 0;                 -- �o�^����
    gn_target_cnt    := 0;                 -- �Ώی���
    gn_error_cnt     := 0;                 -- �G���[����
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
        , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
        , ov_errmsg  => lv_errmsg );         -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�̔��T���f�[�^���o
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
      , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
      , ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �X�e�[�^�X������i�f�[�^��1���ȏ㒊�o�j�ł����A-3�ȍ~�����s����
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================
      -- A-3.��ʉ�vOIF�W�񏈗� (A-4 �����̌ďo���܂�)
      -- ===============================
      edit_work_data(
           ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
         , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
         , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.��ʉ�vOIF�f�[�^�o�^����
      -- ===============================
      insert_gl_data(
            ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
          , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
          , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2022/06/16 Ver1.5 DEL Start
--      -- ===============================
--      -- A-6.�̔��T�����X�V����
--      -- ===============================
--      update_deduction_data(
--          ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
--        , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
--        , ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
--        );
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
-- 2022/06/16 Ver1.5 DEL End
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#####################################  �Œ蕔 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
--Ver 1.2 mod start
--                , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
                , retcode     OUT VARCHAR2               -- ���^�[���E�R�[�h    --# �Œ� #
                , parallel_group IN VARCHAR2 )           -- GL�A�g�p���������s�O���[�v
--Ver 1.2 mod end
                
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- ���ʗ̈�Z�k�A�v����
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �o�^�������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--####################################  �Œ蕔 START  ####################################--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  �Œ蕔 END  #####################################
--
--Ver 1.2 add start
    -- GL�A�g�p���������s�O���[�v�ݒ�
    gv_parallel_group := parallel_group;
--Ver 1.2 add end
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
           , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- A-7.�I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    --�G���[�̏ꍇ�A���������N���A�A�G���[�����ݒ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --�����Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_target_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_success_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_error_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                          , iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
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
--#####################################  �Œ蕔 END  #####################################
--
END XXCOK024A06C;
/
