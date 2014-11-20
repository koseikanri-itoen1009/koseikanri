CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A04C(body)
 * Description      : ���[�X��v����CSV�o��
 * Version          : 1.00
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
 *  2012/10/24    1.00  SCSK ������a    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_xxccp  CONSTANT VARCHAR2(10) := 'XXCCP';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A04C';   -- �p�b�P�[�W��
  -- �����R�[�h�w��L���t���O �R�[�h�l
  cv_obj_code_param_off     CONSTANT VARCHAR2(1)  := '0';              -- �����R�[�h�̎w�薳��
  cv_obj_code_param_on      CONSTANT VARCHAR2(1)  := '1';              -- �����R�[�h�̎w��L��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_obj_code_param         VARCHAR2(1);               -- �����R�[�h�w��L���t���O
  -- �ȉ��p�����[�^ --
  gv_contract_number        xxcff_contract_headers.contract_number%TYPE;   -- �p�����[�^�F�_��ԍ�
  gv_lease_company          xxcff_contract_headers.lease_company%TYPE;     -- �p�����[�^�F���[�X���
  gv_object_code_01         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h1
  gv_object_code_02         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h2
  gv_object_code_03         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h3
  gv_object_code_04         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h4
  gv_object_code_05         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h5
  gv_object_code_06         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h6
  gv_object_code_07         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h7
  gv_object_code_08         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h8
  gv_object_code_09         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h9
  gv_object_code_10         xxcff_object_headers.object_code%TYPE;         -- �p�����[�^�F�����R�[�h10
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';     -- ��؂蕶��
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';     -- �P��͂ݕ���
    -- ���[�X�敪
    cv_lease_type_orgn      CONSTANT  VARCHAR2(1)   := '1';     -- ���_��
    cv_lease_type_re        CONSTANT  VARCHAR2(1)   := '2';     -- �ă��[�X
    -- ���[�X���
    cv_lease_kind_fin       CONSTANT  VARCHAR2(1)   := '0';     -- FIN���[�X
    cv_lease_kind_op        CONSTANT  VARCHAR2(1)   := '1';     -- OP���[�X
    cv_lease_kind_old_fin   CONSTANT  VARCHAR2(1)   := '2';     -- ��FIN���[�X
    -- ���Y�䒠��
    cv_book_type_code_old   CONSTANT  VARCHAR2(15)  := '�����[�X�䒠';
    cv_book_type_code_fin   CONSTANT  VARCHAR2(15)  := 'FIN���[�X�䒠';
    -- ���Y��v�N�x�E���Y�J�����_�[
    cv_fiscal_year_name     CONSTANT  VARCHAR2(30)  := 'XXCFF_FISCAL_YEAR';
    cv_calendar_type        CONSTANT  VARCHAR2(15)  := 'XXCFF_CALENDAR';
    --
--
    -- *** ���[�J���ϐ� ***
    lv_period_name_from               fa_deprn_periods.period_name%TYPE;        -- �o�͊���(��)
    lv_period_name_to                 fa_deprn_periods.period_name%TYPE;        -- �o�͊���(��)
    ln_period_counter_from            fa_deprn_periods.period_counter%TYPE;     -- ����ID(��)
    ln_period_counter_to              fa_deprn_periods.period_counter%TYPE;     -- ����ID(��)
    ld_fiscal_start_date              DATE;                                     -- ����J�n��
    ld_fiscal_end_date                DATE;                                     -- �����I����
    ld_base_start_date                DATE;                                     -- ��J�n��
--
    -- ===============================================
    -- ���[�J����O����
    -- ===============================================
    err_prm_expt            EXCEPTION;   -- ���̓p�����[�^��O
    err_period_expt         EXCEPTION;   -- ��v���Ԏ擾��O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- ���v���� �擾�J�[�\��
    CURSOR l_base_period_cur
    IS
      SELECT fdpbs.fiscal_year           AS fiscal_year           -- ��v�N�x
           , fdpst.period_name           AS period_name_from      -- ���� ��v���Ԗ�
           , fdpst.period_counter        AS period_counter_from   -- ���� ����ID
           , fdpbs.period_name           AS period_name_to        -- � ��v����
           , fdpbs.period_counter        AS period_counter_to     -- � ����ID
           , ffy.start_date              AS fiscal_start_date     -- ����J�n��
           , ffy.end_date                AS fiscal_end_date       -- �����I����
           , fcp.start_date              AS base_start_date       -- ��J�n��
        FROM (
                SELECT MAX(fdp.period_name) AS max_period_name
                  FROM fa_deprn_periods    fdp
                 WHERE -- ���� �������p����.���Y�䒠�� = FIN���[�X�䒠
                       fdp.book_type_code    = cv_book_type_code_fin
                   AND fdp.period_close_date IS NOT NULL
             ) fdpmx
           , fa_deprn_periods    fdpbs   -- � �������p����
           , fa_deprn_periods    fdpst   -- ���� �������p����
           , fa_fiscal_year      ffy     -- ���Y��v�N�x
           , fa_calendar_periods fcp     -- ���Y�J�����_�[
       WHERE -- � �������p����.���Y�䒠�� = FIN���[�X�䒠
             fdpbs.book_type_code    = cv_book_type_code_fin
             -- � �������p����.��v���Ԗ� = �N���[�Y��v���Ԃ̍ő�
         AND fdpbs.period_name       = fdpmx.max_period_name
             -- ���� �������p����.���Y�䒠�� = FIN���[�X�䒠
         AND fdpst.book_type_code    = cv_book_type_code_fin
             -- ���� �������p����.���Ԕԍ� = 1 ������
         AND fdpst.period_num        = 1
             -- ���� �������p����.��v�N�x = � �������p����.��v�N�x
         AND fdpst.fiscal_year       = fdpbs.fiscal_year
             -- ���Y��v�N�x.��v�N�x      = � �������p����.��v�N�x
         AND ffy.fiscal_year         = fdpbs.fiscal_year
         AND ffy.fiscal_year_name    = cv_fiscal_year_name
             -- ���Y�J�����_�[.��v���Ԗ� = �N���[�Y��v���Ԃ̍ő�
         AND fcp.period_name         = fdpmx.max_period_name
         AND fcp.calendar_type       = cv_calendar_type
    ;
    l_base_period_rec l_base_period_cur%ROWTYPE;
--
    -- =============================================================
    -- ���[�X��v���� �擾�J�[�\�� �p�����[�^.�_��ԍ����w��L��
    -- =============================================================
    CURSOR l_cont_planning_cur
    IS
      SELECT
             cont_head.lease_company                                                     AS lease_company       -- ���[�X�_��w�b�_.���[�X���
           , (  -- ���[�X��Ѓr���[���A���[�X��Ж����擾
                SELECT a.lease_company_name
                  FROM xxcff_lease_company_v a   --���[�X��Ѓr���[
                 WHERE cont_head.lease_company = a.lease_company_code
             )                                                                           AS lease_company_name  -- ���[�X��Ѓr���[.���[�X��Ж�
           , lv_period_name_from                                                         AS period_name_from    -- ���� ��v���Ԗ�
           , lv_period_name_to                                                           AS period_name_to      -- � ��v����
           , cont_head.contract_number                                                   AS contract_number     -- ���[�X�_��w�b�_.�_��ԍ�
           , (  -- ���[�X��ʃr���[���A���[�X��ʖ����擾
                SELECT a.lease_class_name
                  FROM xxcff_lease_class_v a     --���[�X��ʃr���[
                 WHERE cont_head.lease_class = a.lease_class_code
             )                                                                           AS lease_class_name    -- ���[�X��ʃr���[.���[�X��ʖ���
           , -- ���[�X�_��w�b�_.���[�X�敪���敪���𔻒�
             CASE cont_head.lease_type
               WHEN cv_lease_type_orgn  THEN '���_��'
               WHEN cv_lease_type_re    THEN '�ă��[�X'
             END                                                                         AS lease_type_name
           , TO_CHAR( cont_head.lease_start_date , 'yyyy/mm/dd' )                        AS lease_start_date    -- ���[�X�_��w�b�_.���[�X�J�n��
           , TO_CHAR( cont_head.lease_end_date   , 'yyyy/mm/dd' )                        AS lease_end_date      -- ���[�X�_��w�b�_.���[�X�I����
           , cont_head.payment_frequency                                                 AS payment_frequency   -- ���[�X�_��w�b�_.�x����
           , cont_line.second_charge                                                     AS second_charge       -- ���[�X�_�񖾍�.2��ڈȍ~���z���[�X��_���[�X��
           , cont_line.gross_charge                                                      AS gross_charge        -- ���[�X�_�񖾍�.���z���[�X��_���[�X��
           , (  -- �����x�����[�X��               ���[�X�x���v��.���[�X�����W�v         �͈́F����`����� 
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL(pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency          
             )                                                                           AS lcharge_year
           , (  -- ���o�߃��[�X��                 ���[�X�x���v��.���[�X�����W�v         �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS lcharge_future
           , (  -- 1�N�ȓ����o�߃��[�X��          ���[�X�x���v��.���[�X�����W�v         �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_1year
           , (  -- 1�N�����o�߃��[�X��            ���[�X�x���v��.���[�X�����W�v         �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_ov1year
           , (  -- ���[�X�_�񖾍�.�擾���z
                SELECT cont_line_a.original_cost
                  FROM xxcff_contract_lines     cont_line_a
                 WHERE cont_line_a.object_header_id   = obj_head.object_header_id
                   AND cont_line_a.contract_header_id = cont_head.contract_header_id
                   AND cont_line_a.lease_kind        <> cv_lease_kind_op --op���[�X�ȊO
             )                                                                           AS original_cost
                -- ���o�߃��[�X�����c�������z     ���[�X�x���v��.FIN���[�X���c          �͈́F����� ���_
           , NVL( pay_plan_bs.fin_debt_rem , 0 )                                         AS fin_debt_rem
           , (  -- ���o�߃��[�X�x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS fin_interest_due
                -- ���o�߃��[�X����Ŋz           ���[�X�x���v��.FIN���[�X���c_�����   �͈́F����� ���_
           , NVL( pay_plan_bs.fin_tax_debt_rem , 0 )                                     AS fin_tax_debt_rem
           , (  -- 1�N�ȓ����{�z                  ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_1year
           , (  -- 1�N�ȓ��x������                ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_1year
           , (  -- 1�N�ȓ������                  ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_1year
           , (  -- 1�N�����{�z                    ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_ov1year
           , (  -- 1�N���x������                  ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_ov1year
           , (  -- 1�N�������                    ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_ov1year
           , (  -- 1�N��2�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_debt_1to2year
           , (  -- 1�N��2�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_int_due_1to2year
           , (  -- 1�N��2�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_tax_debt_1to2year
            ,(  -- 2�N��3�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_debt_2to3year
           , (  -- 2�N��3�N�ȓ��x������            ���[�X�x���v��.FIN���[�X�x������ ���W�v     �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_int_due_2to3year
           , (  -- 2�N��3�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_tax_debt_2to3year
           , (  -- 3�N��4�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_debt_3to4year
           , (  -- 3�N��4�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
              )                                                                          AS fin_int_due_3to4year
           , (  -- 3�N��4�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_tax_debt_3to4year
           , (  -- 4�N��5�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_4to5year
           , (  -- 4�N��5�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_4to5year
           , (  -- 4�N��5�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_4to5year
           , (  -- 5�N�����{�z                    ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_ov5year
           , (  -- 5�N���x������                  ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_ov5year
           , (  -- 5�N�������                    ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_ov5year
           , NVL( -- �������p�݌v�z�����z
                  (
                     SELECT fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a  -- ���[�X�_�񖾍�
                          , fa_additions_b           fab          -- �W��:���Y�ڍ׏��
                          , fa_deprn_summary         fdsum        -- �W��:�������p�T�}�����
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        -- ���[�X��� ��OP�ȊO
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter       >= ln_period_counter_from
                                  AND fdsum.period_counter       <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_reserve
           , NVL( -- �����c�������z
                  (
                     SELECT fdsum.adjusted_cost - fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                       , cv_book_type_code_fin
                                                                                                       , cv_book_type_code_old
                                                                              )
                                  AND   fdsum.period_counter          >= ln_period_counter_from
                                  AND   fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS bal_amount
           , (  -- �x�����������z                 ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����`�����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 ) 
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS interest_amount
           , NVL( -- �������p�����z
                  (
                     SELECT fdsum.ytd_deprn
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX(period_counter)
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter          >= ln_period_counter_from
                                  AND fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_amount
           , cont_line.second_deduction                                                  AS monthly_deduction -- ���ԃ��[�X��(�T���z)
           , cont_line.gross_deduction                                                   AS gross_deduction   -- ���[�X�����z(�T���z)
           , (  -- �����x�����[�X��(�T���z)       ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����`�����
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS lded_year
           , (  -- ���o�߃��[�X��(�T���z)         ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
             )                                                                           AS lded_future
           , (  -- 1�N�ȓ����o�߃��[�X��(�T���z)  ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_1year
           , (  -- 1�N�����o�߃��[�X��(�T���z)    ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_ov1year
           , -- ���[�X�_�񖾍�.���[�X��ނ�胊�[�X��ޖ��̂𔻒�
             CASE cont_line.lease_kind
               WHEN cv_lease_kind_fin     THEN 'FIN'
               WHEN cv_lease_kind_op      THEN 'OP'
               WHEN cv_lease_kind_old_fin THEN '��FIN'
             END                                                                         AS lease_kind_name   -- ���[�X��ޖ���
           , cont_line.contract_line_num                                                 AS contract_line_num -- ���[�X�_�񖾍�.�_��}��
           , obj_head.object_code                                                        AS object_code       -- ���[�X����.�����R�[�h
           , obj_head.department_code                                                    AS department_code   -- ���[�X����.�Ǘ�����R�[�h
           , (  -- �Ǘ�����r���[���A�Ǘ����喼�̂��擾
                SELECT a.department_name
                  FROM xxcff_department_v a
                 WHERE obj_head.department_code = a.department_code
             )                                                                           AS department_name  -- �Ǘ�����r���[.�Ǘ����喼
           , cont_line.contract_status                                                   AS contract_status  -- ���[�X�_�񖾍�.�_��X�^�[�^�X
           , (  -- �_��X�e�[�^�X�r���[���A�_��X�e�[�^�X���̂��擾
                SELECT a.contract_status_name
                  FROM xxcff_contract_status_v a
                 WHERE cont_line.contract_status = a.contract_status_code
             )                                                                           AS contract_status_name -- �_��X�e�[�^�X�r���[.�_��X�^�[�^�X��
           , obj_head.object_status                                                      AS object_status        -- ���[�X����.�����X�^�[�^�X
           , (  -- �����X�e�[�^�X�r���[���A�����X�e�[�^�X���̂��擾
                SELECT a.object_status_name
                  FROM xxcff_object_status_v a
                 WHERE obj_head.object_status = a.object_status_code
             )                                                                           AS object_status_name   -- �����X�e�[�^�X�r���[.�����X�^�[�^�X��
           , cont_head.re_lease_times                                                    AS cont_re_lease_times  -- �_��w�b�_.�ă��[�X��
           , obj_head.re_lease_times                                                     AS obj_re_lease_times   -- ���[�X����.�ă��[�X��
           , (  --���Y�ԍ��擾
                SELECT fab.asset_number
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
             )                                                                           AS asset_number
           , (  -- ���
                SELECT ffvt.description
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                     , fa_categories_b          fcb
                     , fnd_flex_value_sets      ffvs
                     , fnd_flex_values          ffv
                     , fnd_flex_values_tl       ffvt
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                   AND fab.asset_category_id         = fcb.category_id
                   AND fcb.segment1                  = ffv.flex_value
                   AND ffvs.flex_value_set_name      = 'XXCFF_CATEGORY'
                   AND ffvs.flex_value_set_id        = ffv.flex_value_set_id
                   AND ffv.flex_value_id             = ffvt.flex_value_id
                   AND ffvt.language                 = 'JA'
             )                                                                           AS category_name        -- ���
           , --���N�x���[�X����
             CASE
               -- ���[�X�J�n�������N�x���O
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                 THEN
                   CASE
                      -- ���[�X�I���������N�x���O
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                        THEN 0
                      -- ���[�X�I���������N�x���ł��A��N���ȑO
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_base_start_date   , 'MM')
                             -- ����`���[�X�I���܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( ld_fiscal_start_date ))) + 1
                      -- ���[�X�I��������N������
                      --   �� ���[�X�I�������}���Ă��Ȃ��ꍇ�A�Č_�񂵂Čp������\��������̂œ��N�x�I���ł����Ă�12�ƕ\��
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_base_start_date   , 'MM')
                        THEN 12
                   END
               -- ���[�X�J�n�������N�x��
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                AND   TRUNC( cont_head.lease_start_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 
                   CASE
                      -- ���[�X�I���������N�x
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                             -- ���[�X�J�n���`���[�X�I�����܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                      -- ���[�X�I���������N�x����
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                             -- ���[�X�J�n���`�����܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(ld_fiscal_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                   END
               -- ���[�X�J�n�������N�x����
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 0
             END                                                                         AS lease_mcount
        FROM xxcff_contract_headers   cont_head      -- ���[�X�_��w�b�_
           , xxcff_contract_lines     cont_line      -- ���[�X�_�񖾍�
           , xxcff_object_headers     obj_head       -- ���[�X����
           , ( -- �e�_�񖈂̍ő�ă��[�X��
               SELECT cont_head.contract_number          AS contract_number
                    , cont_head.lease_company            AS lease_company
                    , MAX(cont_head.re_lease_times)      AS re_lease_times
                 FROM xxcff_contract_headers   cont_head      -- ���[�X�_��w�b�_
                WHERE cont_head.contract_number = gv_contract_number
                GROUP BY cont_head.contract_number , cont_head.lease_company
             ) cont_head_max
           , xxcff_pay_planning       pay_plan_st    -- ����F���[�X�x���v��
           , xxcff_pay_planning       pay_plan_bs    -- ��F���[�X�x���v��
       WHERE -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
             cont_head.contract_header_id = cont_line.contract_header_id
             -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
         AND cont_line.object_header_id   = obj_head.object_header_id
             -- �_��̍ő�ă��[�X��
         AND cont_head.contract_number = cont_head_max.contract_number
         AND cont_head.lease_company   = cont_head_max.lease_company
         AND cont_head.re_lease_times  = cont_head_max.re_lease_times
             -- ����F���[�X�x���v��.��v����  += �o�͊���(��)
         AND pay_plan_st.period_name(+)   = lv_period_name_from
             -- ��F���[�X�x���v��.��v����  += �o�͊���(��)
         AND pay_plan_bs.period_name(+)   = lv_period_name_to
             -- ����F���[�X�x���v��.�_�񖾍ד���ID  += ���[�X�_�񖾍�.�_�񖾍ד���ID
         AND pay_plan_st.contract_line_id(+)   = cont_line.contract_line_id
             -- ��F���[�X�x���v��.�_�񖾍ד���ID  += ���[�X�_�񖾍�.�_�񖾍ד���ID
         AND pay_plan_bs.contract_line_id(+)   = cont_line.contract_line_id
             -- ���[�X�_��w�b�_.�_��ԍ� = :�p�����[�^�_��ԍ�
         AND cont_head.contract_number    = gv_contract_number
             -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^���[�X���
         AND ( gv_lease_company IS NULL
             OR
               cont_head.lease_company    = gv_lease_company
             )
             -- �����R�[�h�̎w�肪����ꍇ�́A�����ꂩ�ɍ��v�������
         AND (
               gv_obj_code_param = cv_obj_code_param_off
             OR
               (
                 gv_obj_code_param = cv_obj_code_param_on
                 AND
                 -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
                 obj_head.object_code IN ( gv_object_code_01
                                         , gv_object_code_02
                                         , gv_object_code_03
                                         , gv_object_code_04
                                         , gv_object_code_05
                                         , gv_object_code_06
                                         , gv_object_code_07
                                         , gv_object_code_08
                                         , gv_object_code_09
                                         , gv_object_code_10
                                      )
               )
             )
       ORDER BY cont_head.contract_number
              , obj_head.object_code
    ;
    -- =============================================================
    -- ���[�X��v���� �擾�J�[�\�� �p�����[�^.�_��ԍ������w��
    -- =============================================================
    CURSOR l_no_cont_planning_cur
    IS
      SELECT
             cont_head.lease_company                                                     AS lease_company       -- ���[�X�_��w�b�_.���[�X���
           , (  -- ���[�X��Ѓr���[���A���[�X��Ж����擾
                SELECT a.lease_company_name
                  FROM xxcff_lease_company_v a   --���[�X��Ѓr���[
                 WHERE cont_head.lease_company = a.lease_company_code
             )                                                                           AS lease_company_name  -- ���[�X��Ѓr���[.���[�X��Ж�
           , lv_period_name_from                                                         AS period_name_from    -- ���� ��v���Ԗ�
           , lv_period_name_to                                                           AS period_name_to      -- � ��v����
           , cont_head.contract_number                                                   AS contract_number     -- ���[�X�_��w�b�_.�_��ԍ�
           , (  -- ���[�X��ʃr���[���A���[�X��ʖ����擾
                SELECT a.lease_class_name
                  FROM xxcff_lease_class_v a     --���[�X��ʃr���[
                 WHERE cont_head.lease_class = a.lease_class_code
             )                                                                           AS lease_class_name    -- ���[�X��ʃr���[.���[�X��ʖ���
           , -- ���[�X�_��w�b�_.���[�X�敪���敪���𔻒�
             CASE cont_head.lease_type
               WHEN cv_lease_type_orgn  THEN '���_��'
               WHEN cv_lease_type_re    THEN '�ă��[�X'
             END                                                                         AS lease_type_name
           , TO_CHAR( cont_head.lease_start_date , 'yyyy/mm/dd' )                        AS lease_start_date    -- ���[�X�_��w�b�_.���[�X�J�n��
           , TO_CHAR( cont_head.lease_end_date   , 'yyyy/mm/dd' )                        AS lease_end_date      -- ���[�X�_��w�b�_.���[�X�I����
           , cont_head.payment_frequency                                                 AS payment_frequency   -- ���[�X�_��w�b�_.�x����
           , cont_line.second_charge                                                     AS second_charge       -- ���[�X�_�񖾍�.2��ڈȍ~���z���[�X��_���[�X��
           , cont_line.gross_charge                                                      AS gross_charge        -- ���[�X�_�񖾍�.���z���[�X��_���[�X��
           , (  -- �����x�����[�X��               ���[�X�x���v��.���[�X�����W�v         �͈́F����`����� 
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL(pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency          
             )                                                                           AS lcharge_year
           , (  -- ���o�߃��[�X��                 ���[�X�x���v��.���[�X�����W�v         �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS lcharge_future
           , (  -- 1�N�ȓ����o�߃��[�X��          ���[�X�x���v��.���[�X�����W�v         �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_1year
           , (  -- 1�N�����o�߃��[�X��            ���[�X�x���v��.���[�X�����W�v         �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.lease_charge ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lcharge_fut_ov1year
           , (  -- ���[�X�_�񖾍�.�擾���z
                SELECT cont_line_a.original_cost
                  FROM xxcff_contract_lines     cont_line_a
                 WHERE cont_line_a.object_header_id   = obj_head.object_header_id
                   AND cont_line_a.contract_header_id = cont_head.contract_header_id
                   AND cont_line_a.lease_kind        <> cv_lease_kind_op --op���[�X�ȊO
             )                                                                           AS original_cost
                -- ���o�߃��[�X�����c�������z     ���[�X�x���v��.FIN���[�X���c          �͈́F����� ���_
           , NVL( pay_plan_bs.fin_debt_rem , 0 )                                         AS fin_debt_rem
           , (  -- ���o�߃��[�X�x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  = pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency > pay_plan_bs.payment_frequency
             )                                                                           AS fin_interest_due
                -- ���o�߃��[�X����Ŋz           ���[�X�x���v��.FIN���[�X���c_�����   �͈́F����� ���_
           , NVL( pay_plan_bs.fin_tax_debt_rem , 0 )                                     AS fin_tax_debt_rem
           , (  -- 1�N�ȓ����{�z                  ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_1year
           , (  -- 1�N�ȓ��x������                ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_1year
           , (  -- 1�N�ȓ������                  ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_1year
           , (  -- 1�N�����{�z                    ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_debt_ov1year
           , (  -- 1�N���x������                  ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_int_due_ov1year
           , (  -- 1�N�������                    ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS fin_tax_debt_ov1year
           , (  -- 1�N��2�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_debt_1to2year
           , (  -- 1�N��2�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_int_due_1to2year
           , (  -- 1�N��2�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +13���� �` +24����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 24
             )                                                                           AS fin_tax_debt_1to2year
            ,(  -- 2�N��3�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_debt_2to3year
           , (  -- 2�N��3�N�ȓ��x������            ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_int_due_2to3year
           , (  -- 2�N��3�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +25���� �` +36����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 24
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 36
             )                                                                           AS fin_tax_debt_2to3year
           , (  -- 3�N��4�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_debt_3to4year
           , (  -- 3�N��4�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
              )                                                                          AS fin_int_due_3to4year
           , (  -- 3�N��4�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +37���� �` +48����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 36
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 48
             )                                                                           AS fin_tax_debt_3to4year
           , (  -- 4�N��5�N�ȓ����{�z             ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_4to5year
           , (  -- 4�N��5�N�ȓ��x������           ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_4to5year
           , (  -- 4�N��5�N�ȓ������             ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +49���� �` +60����
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 48
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_4to5year
           , (  -- 5�N�����{�z                    ���[�X�x���v��.FIN���[�X���z���W�v         �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_debt_ov5year
           , (  -- 5�N���x������                  ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_int_due_ov5year
           , (  -- 5�N�������                    ���[�X�x���v��.FIN���[�X���z_����ł��W�v  �͈́F����� +61���� �`
                SELECT NVL( SUM( xpp.fin_tax_debt ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 60
             )                                                                           AS fin_tax_debt_ov5year
           , NVL( -- �������p�݌v�z�����z
                  (
                     SELECT fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a  -- ���[�X�_�񖾍�
                          , fa_additions_b           fab          -- �W��:���Y�ڍ׏��
                          , fa_deprn_summary         fdsum        -- �W��:�������p�T�}�����
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        -- ���[�X��� ��OP�ȊO
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter       >= ln_period_counter_from
                                  AND fdsum.period_counter       <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_reserve
           , NVL( -- �����c�������z
                  (
                     SELECT fdsum.adjusted_cost - fdsum.deprn_reserve
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX( period_counter )
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin
                                                                                                       , cv_book_type_code_fin
                                                                                                       , cv_book_type_code_old
                                                                              )
                                  AND   fdsum.period_counter          >= ln_period_counter_from
                                  AND   fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS bal_amount
           , (  -- �x�����������z                 ���[�X�x���v��.FIN���[�X�x������ ���W�v      �͈́F����`�����
                SELECT NVL( SUM( xpp.fin_interest_due ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 ) 
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS interest_amount
           , NVL( -- �������p�����z
                  (
                     SELECT fdsum.ytd_deprn
                       FROM xxcff_contract_lines     cont_line_a
                          , fa_additions_b           fab
                          , fa_deprn_summary         fdsum
                      WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                        AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                        AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                        AND fdsum.asset_id                = fab.asset_id
                        AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                           , cv_book_type_code_fin
                                                                                           , cv_book_type_code_old
                                                                  )
                        AND fdsum.period_counter          =  
                            (
                               SELECT MAX(period_counter)
                                 FROM xxcff_contract_lines     cont_line_a
                                    , fa_additions_b           fab
                                    , fa_deprn_summary         fdsum
                                WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                                  AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                                  AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                                  AND fdsum.asset_id                = fab.asset_id
                                  AND fdsum.book_type_code          = DECODE( cont_line_a.lease_kind , cv_lease_kind_fin 
                                                                                                     , cv_book_type_code_fin
                                                                                                     , cv_book_type_code_old
                                                                            )
                                  AND fdsum.period_counter          >= ln_period_counter_from
                                  AND fdsum.period_counter          <= ln_period_counter_to
                            )
                  )
                , 0 )                                                                    AS deprn_amount
           , cont_line.second_deduction                                                  AS monthly_deduction -- ���ԃ��[�X��(�T���z)
           , cont_line.gross_deduction                                                   AS gross_deduction   -- ���[�X�����z(�T���z)
           , (  -- �����x�����[�X��(�T���z)       ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����`�����
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >= NVL( pay_plan_st.payment_frequency , 1 )
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency
             )                                                                           AS lded_year
           , (  -- ���o�߃��[�X��(�T���z)         ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� + 1���� �`
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
             )                                                                           AS lded_future
           , (  -- 1�N�ȓ����o�߃��[�X��(�T���z)  ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� + 1���� �` +12����
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency
                   AND xpp.payment_frequency <= pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_1year
           , (  -- 1�N�����o�߃��[�X��(�T���z)    ���[�X�x���v��.���[�X�T���z ���W�v           �͈́F����� +13���� �`
                SELECT NVL( SUM( xpp.lease_deduction ) , 0 )
                  FROM xxcff_pay_planning xpp
                 WHERE xpp.contract_line_id  =  pay_plan_bs.contract_line_id
                   AND xpp.payment_frequency >  pay_plan_bs.payment_frequency + 12
             )                                                                           AS lded_fut_ov1year
           , -- ���[�X�_�񖾍�.���[�X��ނ�胊�[�X��ޖ��̂𔻒�
             CASE cont_line.lease_kind
               WHEN cv_lease_kind_fin     THEN 'FIN'
               WHEN cv_lease_kind_op      THEN 'OP'
               WHEN cv_lease_kind_old_fin THEN '��FIN'
             END                                                                         AS lease_kind_name   -- ���[�X��ޖ���
           , cont_line.contract_line_num                                                 AS contract_line_num -- ���[�X�_�񖾍�.�_��}��
           , obj_head.object_code                                                        AS object_code       -- ���[�X����.�����R�[�h
           , obj_head.department_code                                                    AS department_code   -- ���[�X����.�Ǘ�����R�[�h
           , (  -- �Ǘ�����r���[���A�Ǘ����喼�̂��擾
                SELECT a.department_name
                  FROM xxcff_department_v a
                 WHERE obj_head.department_code = a.department_code
             )                                                                           AS department_name  -- �Ǘ�����r���[.�Ǘ����喼
           , cont_line.contract_status                                                   AS contract_status  -- ���[�X�_�񖾍�.�_��X�^�[�^�X
           , (  -- �_��X�e�[�^�X�r���[���A�_��X�e�[�^�X���̂��擾
                SELECT a.contract_status_name
                  FROM xxcff_contract_status_v a
                 WHERE cont_line.contract_status = a.contract_status_code
             )                                                                           AS contract_status_name -- �_��X�e�[�^�X�r���[.�_��X�^�[�^�X��
           , obj_head.object_status                                                      AS object_status        -- ���[�X����.�����X�^�[�^�X
           , (  -- �����X�e�[�^�X�r���[���A�����X�e�[�^�X���̂��擾
                SELECT a.object_status_name
                  FROM xxcff_object_status_v a
                 WHERE obj_head.object_status = a.object_status_code
             )                                                                           AS object_status_name   -- �����X�e�[�^�X�r���[.�����X�^�[�^�X��
           , cont_head.re_lease_times                                                    AS cont_re_lease_times  -- �_��w�b�_.�ă��[�X��
           , obj_head.re_lease_times                                                     AS obj_re_lease_times   -- ���[�X����.�ă��[�X��
           , (  --���Y�ԍ��擾
                SELECT fab.asset_number
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id )
             )                                                                           AS asset_number
           , (  -- ���
                SELECT ffvt.description
                  FROM xxcff_contract_lines     cont_line_a
                     , fa_additions_b           fab
                     , fa_categories_b          fcb
                     , fnd_flex_value_sets      ffvs
                     , fnd_flex_values          ffv
                     , fnd_flex_values_tl       ffvt
                 WHERE cont_line_a.object_header_id  = obj_head.object_header_id
                   AND cont_line_a.lease_kind       <> cv_lease_kind_op --op�ȊO
                   AND fab.attribute10               = TO_CHAR( cont_line_a.contract_line_id ) 
                   AND fab.asset_category_id         = fcb.category_id
                   AND fcb.segment1                  = ffv.flex_value
                   AND ffvs.flex_value_set_name      = 'XXCFF_CATEGORY'
                   AND ffvs.flex_value_set_id        = ffv.flex_value_set_id
                   AND ffv.flex_value_id             = ffvt.flex_value_id
                   AND ffvt.language                 = 'JA'
             )                                                                           AS category_name        -- ���
           , --���N�x���[�X����
             CASE
               -- ���[�X�J�n�������N�x���O
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                 THEN
                   CASE
                      -- ���[�X�I���������N�x���O
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') <  TRUNC( ld_fiscal_start_date , 'MM')
                        THEN 0
                      -- ���[�X�I���������N�x���ł��A��N���ȑO
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_base_start_date   , 'MM')
                             -- ����`���[�X�I���܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( ld_fiscal_start_date ))) + 1
                      -- ���[�X�I��������N������
                      --   �� ���[�X�I�������}���Ă��Ȃ��ꍇ�A�Č_�񂵂Čp������\��������̂œ��N�x�I���ł����Ă�12�ƕ\��
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_base_start_date   , 'MM')
                        THEN 12
                   END
               -- ���[�X�J�n�������N�x��
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                AND   TRUNC( cont_head.lease_start_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 
                   CASE
                      -- ���[�X�I���������N�x
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >= TRUNC( ld_fiscal_start_date , 'MM')
                       AND   TRUNC( cont_head.lease_end_date , 'MM') <= TRUNC( ld_fiscal_end_date   , 'MM')
                             -- ���[�X�J�n���`���[�X�I�����܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(cont_head.lease_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                      -- ���[�X�I���������N�x����
                      WHEN   TRUNC( cont_head.lease_end_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                             -- ���[�X�J�n���`�����܂ł̌���
                        THEN TRUNC( MONTHS_BETWEEN( TRUNC(ld_fiscal_end_date ), TRUNC( cont_head.lease_start_date ) ) ) + 1
                   END
               -- ���[�X�J�n�������N�x����
               WHEN   TRUNC( cont_head.lease_start_date , 'MM') >  TRUNC( ld_fiscal_end_date   , 'MM')
                 THEN 0
             END                                                                         AS lease_mcount
        FROM xxcff_contract_headers   cont_head      -- ���[�X�_��w�b�_
           , xxcff_contract_lines     cont_line      -- ���[�X�_�񖾍�
           , xxcff_object_headers     obj_head       -- ���[�X����
           , xxcff_pay_planning       pay_plan_st    -- ����F���[�X�x���v��
           , xxcff_pay_planning       pay_plan_bs    -- ��F���[�X�x���v��
       WHERE -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
             cont_head.contract_header_id = cont_line.contract_header_id
             -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
         AND cont_line.object_header_id   = obj_head.object_header_id
             -- ���[�X�_��w�b�_.�ă��[�X�� = ���[�X����.�ă��[�X��
         AND cont_head.re_lease_times = obj_head.re_lease_times
             -- ����F���[�X�x���v��.��v����  += �o�͊���(��)
         AND pay_plan_st.period_name(+)   = lv_period_name_from
             -- ��F���[�X�x���v��.��v����  += �o�͊���(��)
         AND pay_plan_bs.period_name(+)   = lv_period_name_to
             -- ����F���[�X�x���v��.�_�񖾍ד���ID  += ���[�X�_�񖾍�.�_�񖾍ד���ID
         AND pay_plan_st.contract_line_id(+)   = cont_line.contract_line_id
             -- ��F���[�X�x���v��.�_�񖾍ד���ID  += ���[�X�_�񖾍�.�_�񖾍ד���ID
         AND pay_plan_bs.contract_line_id(+)   = cont_line.contract_line_id
             -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^.���[�X���
         AND ( gv_lease_company IS NULL
             OR
               cont_head.lease_company    = gv_lease_company
             )
         AND -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
             obj_head.object_code IN ( gv_object_code_01
                                     , gv_object_code_02
                                     , gv_object_code_03
                                     , gv_object_code_04
                                     , gv_object_code_05
                                     , gv_object_code_06
                                     , gv_object_code_07
                                     , gv_object_code_08
                                     , gv_object_code_09
                                     , gv_object_code_10
                                     )
       ORDER BY cont_head.contract_number
              , obj_head.object_code
    ;
    TYPE l_cont_planning_ttype IS TABLE OF l_cont_planning_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_cont_planning_tab l_cont_planning_ttype;
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
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
--
    -- ===============================================
    -- ���̓p�����[�^.�����R�[�h�`�F�b�N
    -- ===============================================
    -- �p�����[�^.�����R�[�h1�`10�̓��A��ł��w�肳��Ă���ꍇ�͕����R�[�h�w��L���t���O��L��ɂ���B
    gv_obj_code_param := cv_obj_code_param_off;
    IF ( gv_object_code_01 IS NOT NULL ) OR
       ( gv_object_code_02 IS NOT NULL ) OR
       ( gv_object_code_03 IS NOT NULL ) OR
       ( gv_object_code_04 IS NOT NULL ) OR
       ( gv_object_code_05 IS NOT NULL ) OR
       ( gv_object_code_06 IS NOT NULL ) OR
       ( gv_object_code_07 IS NOT NULL ) OR
       ( gv_object_code_08 IS NOT NULL ) OR
       ( gv_object_code_09 IS NOT NULL ) OR
       ( gv_object_code_10 IS NOT NULL )
      THEN
       gv_obj_code_param := cv_obj_code_param_on;
    END IF;
    -- ===============================================
    -- ���[�X��ЁE�����R�[�h�`�F�b�N
    -- ===============================================
    -- �p�����[�^.�����R�[�h1�`10���S�Ė��w��̏ꍇ�A�p�����[�^.�_��ԍ��A�p�����[�^.���[�X��Ђ͋��ɕK�{
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( ( gv_lease_company IS NULL ) OR ( gv_contract_number IS NULL ) ) 
      THEN
        lv_errmsg  := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
        lv_errbuf  := lv_errmsg;
        RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- ���[�X��v���� ���o����
    -- ===============================================
    -- ���v���� �擾�J�[�\��
    OPEN l_base_period_cur;
    FETCH l_base_period_cur INTO l_base_period_rec;
    CLOSE l_base_period_cur;
    --���v���Ԃ��擾�ł��Ȃ��ꍇ
    IF l_base_period_rec.period_name_to IS NULL THEN
      lv_errmsg  := '��v���Ԃ̎擾�Ɏ��s���܂����B';
      lv_errbuf  := lv_errmsg;
      RAISE err_period_expt;
    END IF;
    --
    lv_period_name_from    := l_base_period_rec.period_name_from;     -- �o�͊���(��)
    lv_period_name_to      := l_base_period_rec.period_name_to;       -- �o�͊���(��)
    ln_period_counter_from := l_base_period_rec.period_counter_from;  -- ����ID(��)
    ln_period_counter_to   := l_base_period_rec.period_counter_to;    -- ����ID(��)
    ld_fiscal_start_date   := l_base_period_rec.fiscal_start_date;    -- ����J�n��
    ld_fiscal_end_date     := l_base_period_rec.fiscal_end_date;      -- �����I����
    ld_base_start_date     := l_base_period_rec.base_start_date;      -- �����I����
--
    -- ���[�X��v���� �擾�J�[�\��
    IF gv_contract_number IS NULL THEN
       -- �p�����[�^.�_��ԍ������w��
        OPEN l_no_cont_planning_cur;
        FETCH l_no_cont_planning_cur BULK COLLECT INTO l_cont_planning_tab;
        CLOSE l_no_cont_planning_cur;
    ELSE
       -- �p�����[�^.�_��ԍ����w��L��
        OPEN l_cont_planning_cur;
        FETCH l_cont_planning_cur BULK COLLECT INTO l_cont_planning_tab;
        CLOSE l_cont_planning_cur;
    END IF;
    --���������J�E���g
    gn_target_cnt := l_cont_planning_tab.COUNT;
--
    -- ���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '���[�X��v����'
    );
    -- ���ږ�
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '���[�X���'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X��Ж�'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '�o�͊���(��)'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '�o�͊���(��)'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��NO'                        || cv_enclosed
         || cv_delimit || cv_enclosed || '����'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�敪'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�J�n��'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�I����'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '����'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '���ԃ��[�X��'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�����z'                  || cv_enclosed
         || cv_delimit || cv_enclosed || '�����x�����[�X��'              || cv_enclosed
         || cv_delimit || cv_enclosed || '���o�߃��[�X��'                || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�ȓ����o�߃��[�X��'         || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�����o�߃��[�X��'           || cv_enclosed
         || cv_delimit || cv_enclosed || '�擾���z�����z'                || cv_enclosed
         || cv_delimit || cv_enclosed || '���o�߃��[�X�����c�������z'    || cv_enclosed
         || cv_delimit || cv_enclosed || '���o�߃��[�X�x������'          || cv_enclosed
         || cv_delimit || cv_enclosed || '���o�߃��[�X����Ŋz'          || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�ȓ����{�z'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�ȓ��x������'               || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�ȓ������'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�����{�z'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N���x������'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�������'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N��2�N�ȓ����{�z'            || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N��2�N�ȓ��x������'          || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N��2�N�ȓ������'            || cv_enclosed
         || cv_delimit || cv_enclosed || '2�N��3�N�ȓ����{�z'            || cv_enclosed
         || cv_delimit || cv_enclosed || '2�N��3�N�ȓ��x������'          || cv_enclosed
         || cv_delimit || cv_enclosed || '2�N��3�N�ȓ������'            || cv_enclosed
         || cv_delimit || cv_enclosed || '3�N��4�N�ȓ����{�z'            || cv_enclosed
         || cv_delimit || cv_enclosed || '3�N��4�N�ȓ��x������'          || cv_enclosed
         || cv_delimit || cv_enclosed || '3�N��4�N�ȓ������'            || cv_enclosed
         || cv_delimit || cv_enclosed || '4�N��5�N�ȓ����{�z'            || cv_enclosed
         || cv_delimit || cv_enclosed || '4�N��5�N�ȓ��x������'          || cv_enclosed
         || cv_delimit || cv_enclosed || '4�N��5�N�ȓ������'            || cv_enclosed
         || cv_delimit || cv_enclosed || '5�N�����{�z'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '5�N���x������'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '5�N�������'                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�������p�݌v�z�����z'          || cv_enclosed
         || cv_delimit || cv_enclosed || '�����c�������z'                || cv_enclosed
         || cv_delimit || cv_enclosed || '�x�����������z'                || cv_enclosed
         || cv_delimit || cv_enclosed || '�������p�����z'                || cv_enclosed
         || cv_delimit || cv_enclosed || '���ԃ��[�X��(�T���z)'          || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�����z(�T���z)'          || cv_enclosed
         || cv_delimit || cv_enclosed || '�����x�����[�X��(�T���z)'      || cv_enclosed
         || cv_delimit || cv_enclosed || '���o�߃��[�X��(�T���z)'        || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�ȓ����o�߃��[�X��(�T���z)' || cv_enclosed
         || cv_delimit || cv_enclosed || '1�N�����o�߃��[�X��(�T���z)'   || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X���'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��}��'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '�����R�[�h'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '�Ǘ�����'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '�Ǘ����喼'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��X�e�[�^�X'                || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��X�e�[�^�X��'              || cv_enclosed
         || cv_delimit || cv_enclosed || '�����X�e�[�^�X'                || cv_enclosed
         || cv_delimit || cv_enclosed || '�����X�e�[�^�X��'              || cv_enclosed
         || cv_delimit || cv_enclosed || '(�_��)�ă��[�X��'            || cv_enclosed
         || cv_delimit || cv_enclosed || '(����)�ă��[�X��'            || cv_enclosed
         || cv_delimit || cv_enclosed || '���Y�ԍ�'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '���'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '���N�x���[�X����'              || cv_enclosed
    );
    -- �f�[�^�̏o��
    <<lines_loop>>
    FOR i IN 1 .. l_cont_planning_tab.COUNT LOOP
        -- ���ڒl
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_cont_planning_tab( i ).lease_company          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_company_name     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).period_name_from       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).period_name_to         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_number        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_class_name       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_type_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_start_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_end_date         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).payment_frequency      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).second_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).gross_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_year           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_future         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_fut_1year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lcharge_fut_ov1year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).original_cost          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_rem           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_interest_due       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_rem       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_1year         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_1year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_1year     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_ov1year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_ov1year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_ov1year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_1to2year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_1to2year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_1to2year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_2to3year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_2to3year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_2to3year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_3to4year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_3to4year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_3to4year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_4to5year      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_4to5year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_4to5year  || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_debt_ov5year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_int_due_ov5year    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).fin_tax_debt_ov5year   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).deprn_reserve          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).bal_amount             || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).interest_amount        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).deprn_amount           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).monthly_deduction      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).gross_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_year              || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_future            || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_fut_1year         || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lded_fut_ov1year       || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_kind_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_line_num      || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_code            || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).department_code        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).department_name        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_status        || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).contract_status_name   || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_status          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).object_status_name     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).cont_re_lease_times    || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).obj_re_lease_times     || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).asset_number           || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).category_name          || cv_enclosed
             || cv_delimit || cv_enclosed || l_cont_planning_tab( i ).lease_mcount           || cv_enclosed
        );
        --���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP lines_loop;
--
--
    -- �Ώی����O���̏ꍇ�A�I���X�e�[�^�X���u�x���v�ɂ���
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => '�Ώۃf�[�^�����݂��܂���B'
      );
      ov_retcode := cv_status_warn;
    END IF;
--
--
  EXCEPTION
    -- *** ���̓p�����[�^��O�n���h�� ***
    WHEN err_prm_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
    -- *** ��v���Ԏ擾��O�n���h�� ***
    WHEN err_period_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �ُ팏���J�E���g
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf              OUT VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       --   ���^�[���E�R�[�h    --# �Œ� #
    iv_contract_number  IN  VARCHAR2,       --    1.�_��ԍ�
    iv_lease_company    IN  VARCHAR2,       --    2.���[�X���
    iv_object_code_01   IN  VARCHAR2,       --    3.�����R�[�h1
    iv_object_code_02   IN  VARCHAR2,       --    4.�����R�[�h2
    iv_object_code_03   IN  VARCHAR2,       --    5.�����R�[�h3
    iv_object_code_04   IN  VARCHAR2,       --    6.�����R�[�h4
    iv_object_code_05   IN  VARCHAR2,       --    7.�����R�[�h5
    iv_object_code_06   IN  VARCHAR2,       --    8.�����R�[�h6
    iv_object_code_07   IN  VARCHAR2,       --    9.�����R�[�h7
    iv_object_code_08   IN  VARCHAR2,       --   10.�����R�[�h8
    iv_object_code_09   IN  VARCHAR2,       --   11.�����R�[�h9
    iv_object_code_10   IN  VARCHAR2        --   12.�����R�[�h10
  )
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
    -- �p�����[�^���O���[�o���ϐ��ɐݒ�
    gv_contract_number := iv_contract_number;  -- �_��ԍ�
    gv_lease_company   := iv_lease_company;    -- ���[�X���
    gv_object_code_01  := iv_object_code_01;   -- �����R�[�h1
    gv_object_code_02  := iv_object_code_02;   -- �����R�[�h2
    gv_object_code_03  := iv_object_code_03;   -- �����R�[�h3
    gv_object_code_04  := iv_object_code_04;   -- �����R�[�h4
    gv_object_code_05  := iv_object_code_05;   -- �����R�[�h5
    gv_object_code_06  := iv_object_code_06;   -- �����R�[�h6
    gv_object_code_07  := iv_object_code_07;   -- �����R�[�h7
    gv_object_code_08  := iv_object_code_08;   -- �����R�[�h8
    gv_object_code_09  := iv_object_code_09;   -- �����R�[�h9
    gv_object_code_10  := iv_object_code_10;   -- �����R�[�h10
    -- �v���O�������͍��ڂ��o��
    -- �_��ԍ�
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�_��ԍ��F' || gv_contract_number
    );
    -- ���[�X���
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '���[�X��ЁF' || gv_lease_company
    );
    -- �����R�[�h1
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h1�F' || gv_object_code_01
    );
    -- �����R�[�h2
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h2�F' || gv_object_code_02
    );
    -- �����R�[�h3
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h3�F' || gv_object_code_03
    );
    -- �����R�[�h4
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h4�F' || gv_object_code_04
    );
    -- �����R�[�h5
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h5�F' || gv_object_code_05
    );
    -- �����R�[�h6
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h6�F' || gv_object_code_06
    );
    -- �����R�[�h7
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h7�F' || gv_object_code_07
    );
    -- �����R�[�h8
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h8�F' || gv_object_code_08
    );
    -- �����R�[�h9
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h9�F' || gv_object_code_09
    );
    -- �����R�[�h10
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => '�����R�[�h10�F' || gv_object_code_10
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�G���[�̏ꍇ�A���������N���A
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
END XXCCP008A04C;
/
