CREATE OR REPLACE PACKAGE BODY XXCFF011A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF011A17C(body)
 * Description      : ���[�X��v��J���f�[�^�o��
 * MD.050           : ���[�X��v��J���f�[�^�o�� MD050_CFF_011_A17
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���̓p�����[�^�l���O�o�͏���(A-1)
 *  chk_period_name        ��v���ԃ`�F�b�N����(A-2)
 *  get_first_period       ��v���Ԋ���擾����(A-3)
 *  get_contract_info      ���[�X�_����擾����(A-4)
 *  get_pay_planning       ���[�X�x���v����擾����(A-5)
 *  out_csv_data           CSV�f�[�^�o�͏���(A-6)
 *  get_asset_info         ���[�X���Y���擾����(A-8)
 *  get_lease_obl_info     ���[�X�����擾����(A-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS�R��          �V�K�쐬
 *  2009/02/18    1.1   SCS�R��          [��QCFF_041] ����A2��ړ����x���̏ꍇ�̕s��Ή�
 *  2009/02/24    1.2   SCS�R��          [��QCFF_054] ���[�X�������̏ꍇ�̕s��Ή�
 *  2009/07/17    1.3   SCS����          [�����e�X�g��Q0000417] �x���v��̓����x�����[�X���擾�����C��
 *  2009/07/31    1.4   SCS�n��          [�����e�X�g��Q0000417(�ǉ�)]
 *                                         �E�擾���z�A�������p�݌v�z�̎擾�������C��
 *                                         �E�x�����������z�A�����x�����[�X���i�T���z�j�̎擾�����C��
 *                                         �E���[�X�_����擾�J�[�\�������[�X��ނŕ���
 *  2009/08/28    1.5   SCS �n��         [�����e�X�g��Q0001061(PT�Ή�)]
 *  2016/09/14    1.6   SCSK �s          E_�{�ғ�_13658�i���̋@�ϗp�N���ύX�Ή��j
 *  2018/03/27    1.7   SCSK ���H        E_�{�ғ�_14830�iIFRS���[�X���Y�Ή��j
 *  2020/04/06    1.8   SCSK �K�q        E_�{�ғ�_16255 (��v����[ �C���Ή�)
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
  no_data_expt               EXCEPTION;     -- �Ώۃf�[�^�Ȃ���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF011A17C'; -- �p�b�P�[�W��
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- �A�v���P�[�V�����Z�k��
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W
  cv_msg_close        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00038'; -- ��v���ԉ��N���[�Y�`�F�b�N�G���[
  cv_msg_no_data      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; -- �Ώۃf�[�^����
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  cv_msg_req_chk      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00108'; -- �K�{�`�F�b�N�G���[
  -- �g�[�N���l
  cv_tkv_com_or_cla   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50327'; -- ���[�X��ЁA���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- �g�[�N��
  cv_tkn_book_type    CONSTANT VARCHAR2(50)  := 'BOOK_TYPE_CODE';   -- ���Y�䒠��
  cv_tkn_period_name  CONSTANT VARCHAR2(50)  := 'PERIOD_NAME';      -- ��v���Ԗ�
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  cv_tkn_input_dta    CONSTANT VARCHAR2(50)  := 'INPUT';            -- �p�����[�^
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- ���[�X���
  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Fin���[�X
  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Op���[�X
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- ��Fin���[�X
  -- ���Y�䒠�敪
  cv_book_class_1     CONSTANT VARCHAR2(1)   := '1';  -- ��v�p
  cv_book_class_2     CONSTANT VARCHAR2(1)   := '2';  -- �@�l�ŗp
-- 2018/03/27 Ver.1.7 Y.Shoji ADD START
  cv_book_class_3     CONSTANT VARCHAR2(1)   := '3';  -- IFRS�p
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  -- �_��X�e�[�^�X
  cv_contr_st_201     CONSTANT VARCHAR2(3)   := '201'; -- �o�^�ς�
-- 0000417 2009/07/31 ADD START --
  -- �����p�X�e�[�^�X
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --������
  -- ��vIF�t���O�X�e�[�^�X
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --�A�g��
-- 0000417 2009/07/31 ADD END --
-- 2018/03/27 Ver.1.7 Y.Shoji ADD START
  cv_format_yyyy_mm   CONSTANT VARCHAR2(7)   := 'YYYY-MM';   --���t�`��:YYYY-MM
  cv_format_mm        CONSTANT VARCHAR2(2)   := 'MM';        --���t�`��:MM
  cv_source_code_dep  CONSTANT VARCHAR2(5)   := 'DEPRN';     --�������p
  cv_lease_type_1     CONSTANT VARCHAR2(1)   := '1';         --���_��
  cv_lease_type_2     CONSTANT VARCHAR2(1)   := '2';         --�ă��[�X
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_csv_rtype IS RECORD (
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--     contract_header_id      xxcff_contract_headers.contract_header_id%TYPE
     contract_line_id        xxcff_contract_lines.contract_line_id%TYPE   -- ���[�X�_�񖾍�ID
    ,object_code             xxcff_object_headers.object_code%TYPE        -- �����R�[�h
    ,lease_type              xxcff_contract_headers.lease_type%TYPE       -- ���[�X�敪
    ,cancellation_date       xxcff_contract_lines.cancellation_date%TYPE  -- ���
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
    ,lease_company           xxcff_contract_headers.lease_company%TYPE -- ���[�X��ЃR�[�h
    ,lease_company_name      VARCHAR2(240) -- ���[�X��Ж�
    ,period_from             VARCHAR2(10) -- �o�͊��ԁi���j
    ,period_to               VARCHAR2(10) -- �o�͊��ԁi���j
    ,contract_number         xxcff_contract_headers.contract_number%TYPE -- �_��No
    ,lease_class_name        VARCHAR2(240) -- ����
    ,lease_type_name         VARCHAR2(240) -- ���[�X�敪
    ,lease_start_date        DATE          -- ���[�X�J�n��
    ,lease_end_date          DATE          -- ���[�X�I����
    ,payment_frequency       xxcff_contract_headers.payment_frequency%TYPE -- ����
    ,monthly_charge          NUMBER(15) -- ���ԃ��[�X��
    ,gross_charge            NUMBER(15) -- ���[�X�����z
    ,lease_charge_this_month NUMBER(15) -- �����x�����[�X��
    ,lease_charge_future     NUMBER(15) -- ���o�߃��[�X��
    ,lease_charge_1year      NUMBER(15) -- 1�N�ȓ����o�߃��[�X��
    ,lease_charge_over_1year NUMBER(15) -- 1�N�z���o�߃��[�X��
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--    ,original_cost           NUMBER(15) -- �擾���z�����z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    ,lease_charge_debt       NUMBER(15) -- ���o�߃��[�X�����c�������z
    ,interest_future         NUMBER(15) -- ���o�߃��[�X�x�������z
    ,tax_future              NUMBER(15) -- ���o�߃��[�X����Ŋz
    ,principal_1year         NUMBER(15) -- 1�N�ȓ����{
    ,interest_1year          NUMBER(15) -- 1�N�ȓ��x������
    ,tax_1year               NUMBER(15) -- 1�N�ȓ������
    ,principal_over_1year    NUMBER(15) -- 1�N�z���{
    ,interest_over_1year     NUMBER(15) -- 1�N�z�x������
    ,tax_over_1year          NUMBER(15) -- 1�N�z�����
    ,principal_1to2year      NUMBER(15) -- 1�N�z2�N�ȓ����{
    ,interest_1to2year       NUMBER(15) -- 1�N�z2�N�ȓ��x������
    ,tax_1to2year            NUMBER(15) -- 1�N�z2�N�ȓ������
    ,principal_2to3year      NUMBER(15) -- 2�N��3�N�ȓ����{
    ,interest_2to3year       NUMBER(15) -- 2�N��3�N�ȓ��x������
    ,tax_2to3year            NUMBER(15) -- 2�N��3�N�ȓ������
    ,principal_3to4year      NUMBER(15) -- 3�N�z4�N�ȓ����{
    ,interest_3to4year       NUMBER(15) -- 3�N�z4�N�ȓ��x������
    ,tax_3to4year            NUMBER(15) -- 3�N�z4�N�ȓ������
    ,principal_4to5year      NUMBER(15) -- 4�N�z5�N�ȓ����{
    ,interest_4to5year       NUMBER(15) -- 4�N�z5�N�ȓ��x������
    ,tax_4to5year            NUMBER(15) -- 4�N�z5�N�ȓ������
    ,principal_over_5year    NUMBER(15) -- 5�N�z���{
    ,interest_over_5year     NUMBER(15) -- 5�N�z�x������
    ,tax_over_5year          NUMBER(15) -- 5�N�z�����
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--    ,deprn_reserve           NUMBER(15) -- �������p�݌v�z�����z 
--    ,bal_amount              NUMBER(15) -- �����c�������z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    ,interest_amount         NUMBER(15) -- �x�����������z
    ,deprn_amount            NUMBER(15) -- �������p�����z
    ,monthly_deduction       NUMBER(15) -- ���ԃ��[�X���i�T���z�j
    ,gross_deduction         NUMBER(15) -- ���[�X�����z�i�T���z�j
    ,deduction_this_month    NUMBER(15) -- �����x�����[�X���i�T���z�j
    ,deduction_future        NUMBER(15) -- ���o�߃��[�X���i�T���z�j
    ,deduction_1year         NUMBER(15) -- 1�N�ȓ����o�߃��[�X���i�T���z�j
    ,deduction_over_1year    NUMBER(15) -- 1�N�z���o�߃��[�X���i�T���z�j
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
     -- ���[�X���Y���
    ,asset_number              fa_additions_b.asset_number%TYPE        -- ���Y�ԍ�
    ,original_cost             fa_books.original_cost%TYPE             -- �����擾���z
    ,cost                      fa_books.cost%TYPE                      -- �擾���z
    ,salvage_value             fa_books.salvage_value%TYPE             -- �c�����z
    ,adjusted_recoverable_cost fa_books.adjusted_recoverable_cost%TYPE -- ���p�Ώۊz
    ,kisyu_boka                NUMBER(15)                              -- ���񒠕뉿�z
    ,year_add_amount_new       NUMBER(15)                              -- ���������z(�V�K�_��)
    ,year_add_amount_old       NUMBER(15)                              -- ���������z(�����_��)
    ,add_amount_new            NUMBER(15)                              -- ���������z(�V�K�_��)
    ,add_amount_old            NUMBER(15)                              -- ���������z(�����_��)
    ,year_dec_amount           NUMBER(15)                              -- ���������z�i���p�I���j
    ,year_del_amount           NUMBER(15)                              -- ���������z�i���j
    ,dec_amount                NUMBER(15)                              -- ���������z�i���p�I���j
    ,delete_amount             NUMBER(15)                              -- ���������z�i���j
    ,deprn_reserve             NUMBER(15)                              -- ���������뉿�z
    ,month_deprn               NUMBER(15)                              -- �������p�݌v�z
    ,ytd_deprn                 fa_deprn_summary.ytd_deprn%TYPE         -- �N���p�݌v�z
    ,total_amount              fa_deprn_summary.deprn_reserve%TYPE     -- ���p�݌v�z
    ,disc_seg                  fa_additions_b.attribute12%TYPE         -- �J���Z�O�����g
    ,area                      fa_additions_b.attribute13%TYPE         -- �ʐ�
     -- ���[�X�����
    ,lease_original_cost       xxcff_contract_lines.original_cost%TYPE -- �擾���z
    ,kisyu_bal_amount          NUMBER(15)                              -- ����c��
    ,lease_year_add_amount_new NUMBER(15)                              -- ���������z�i�V�K�_��j
    ,lease_year_add_amount_old NUMBER(15)                              -- ���������z�i�����_��j
    ,lease_add_amount_new      NUMBER(15)                              -- ���������z�i�V�K�_��j
    ,lease_add_amount_old      NUMBER(15)                              -- ���������z�i�����_��j
    ,lease_year_dec_amount     NUMBER(15)                              -- ���������z�i���ԍρj
    ,lease_year_del_amount     NUMBER(15)                              -- ���������z�i���j
    ,lease_dec_amount          NUMBER(15)                              -- ���������z�i���ԍρj
    ,lease_delete_amount       NUMBER(15)                              -- ���������z�i���j
    ,kimatsu_bal_amount        NUMBER(15)                              -- �����c��
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
  /**********************************************************************************
   * Procedure Name   : get_lease_obl_info
   * Description      : ���[�X�����擾����(A-9)
   ***********************************************************************************/
  PROCEDURE get_lease_obl_info(
    io_csv_rec        IN OUT g_csv_rtype,  -- 1.CSV�o�̓��R�[�h
    ov_errbuf         OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_obl_info'; -- �v���O������
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
    lv_del_period_name     VARCHAR2(7);       -- ���ԍό�
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
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    IF ( io_csv_rec.lease_start_date  < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
      -- 1.����c���̎擾
      BEGIN
        SELECT xpp.fin_debt
             + xpp.fin_debt_rem
             + NVL(xpp.debt_re ,0)
             + NVL(xpp.debt_rem_re ,0)       AS kisyu_bal_amount -- ����c��
        INTO   io_csv_rec.kisyu_bal_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id  =  io_csv_rec.contract_line_id
        AND    xpp.period_name       =  io_csv_rec.period_from
        AND    XPP.payment_frequency <> 1                           -- �x����1��ڂł͂Ȃ�
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.kisyu_bal_amount := 0;
      END;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    ELSE
      io_csv_rec.kisyu_bal_amount := 0;
    END IF;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
--
    -- ���������z�̎擾
    IF (  io_csv_rec.lease_start_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND io_csv_rec.lease_start_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      -- 2.���_��̏ꍇ�A�V�K�_��
      IF ( io_csv_rec.lease_type = cv_lease_type_1) THEN
        io_csv_rec.lease_year_add_amount_new := io_csv_rec.lease_original_cost;
        io_csv_rec.lease_year_add_amount_old := 0;
      -- 3.�ă��[�X�̏ꍇ�A�����_��
      ELSIF ( io_csv_rec.lease_type = cv_lease_type_2) THEN
        io_csv_rec.lease_year_add_amount_new := 0;
        io_csv_rec.lease_year_add_amount_old := io_csv_rec.lease_original_cost;
      END IF;
    ELSE
      io_csv_rec.lease_year_add_amount_new := 0;
      io_csv_rec.lease_year_add_amount_old := 0;
    END IF;
--
    -- ���������z�̎擾
    IF (  io_csv_rec.lease_start_date >= TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)
      AND io_csv_rec.lease_start_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      -- 4.���_��̏ꍇ�A�V�K�_��
      IF ( io_csv_rec.lease_type = cv_lease_type_1) THEN
        io_csv_rec.lease_add_amount_new := io_csv_rec.lease_original_cost;
        io_csv_rec.lease_add_amount_old := 0;
      -- 5.�ă��[�X�̏ꍇ�A�����_��
      ELSIF ( io_csv_rec.lease_type = cv_lease_type_2) THEN
        io_csv_rec.lease_add_amount_new := 0;
        io_csv_rec.lease_add_amount_old := io_csv_rec.lease_original_cost;
      END IF;
    ELSE
      io_csv_rec.lease_add_amount_new := 0;
      io_csv_rec.lease_add_amount_old := 0;
    END IF;
--
    -- 6.���ԍό��̎擾
    BEGIN
      SELECT MAX(xpp.period_name) AS del_period_name
      INTO   lv_del_period_name
      FROM   xxcff_pay_planning xpp
      WHERE  xpp.contract_line_id = io_csv_rec.contract_line_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_del_period_name := NULL;
    END;
--
    -- 7.���������z�i���ԍρj�̎擾
    IF (  TO_DATE(lv_del_period_name ,cv_format_yyyy_mm) >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND TO_DATE(lv_del_period_name ,cv_format_yyyy_mm) <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      io_csv_rec.lease_year_dec_amount := io_csv_rec.kisyu_bal_amount;
    ELSE
      io_csv_rec.lease_year_dec_amount := 0;
    END IF;
--
    -- 8.���������z(���)�̎擾
    IF (  io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
-- 2020/04/06 Ver.1.8 S.Kuwako MOD Start
--      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
      AND io_csv_rec.kisyu_bal_amount  >  0  )  THEN
-- 2020/04/06 Ver.1.8 S.Kuwako MOD End
      io_csv_rec.lease_year_del_amount := io_csv_rec.kisyu_bal_amount;
      -- ���ƍ��ԍς������̏ꍇ�A���ԍς�0�Ƃ���
      io_csv_rec.lease_year_dec_amount := 0;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD Start
    ELSIF ( io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm)
      AND   io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
      AND   io_csv_rec.kisyu_bal_amount   = 0
      AND   io_csv_rec.lease_year_add_amount_new + io_csv_rec.lease_year_add_amount_old > 0 )  THEN
      io_csv_rec.lease_year_del_amount := io_csv_rec.lease_year_add_amount_new + io_csv_rec.lease_year_add_amount_old;
-- 2020/04/06 Ver.1.8 S.Kuwako ADD End
    ELSE
      io_csv_rec.lease_year_del_amount := 0;
    END IF;
--
    -- 9.���������z�i���ԍρj�̎擾
    IF (  lv_del_period_name = io_csv_rec.period_to
      AND io_csv_rec.lease_year_del_amount = 0     ) THEN
      io_csv_rec.lease_dec_amount := io_csv_rec.kisyu_bal_amount;
    ELSE
      io_csv_rec.lease_dec_amount := 0;
    END IF;
--
    -- 10.���������z�i���j�̎擾
    IF (  io_csv_rec.cancellation_date >= TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)
      AND io_csv_rec.cancellation_date <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm)) ) THEN
--
      BEGIN
        SELECT xpp.fin_debt_rem + NVL(xpp.debt_rem_re ,0) AS lease_year_del_amount
        INTO   io_csv_rec.lease_delete_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id = io_csv_rec.contract_line_id
        AND    xpp.period_name      = TO_CHAR(io_csv_rec.cancellation_date ,cv_format_yyyy_mm)
        ;
        -- ���ƍ��ԍς������̏ꍇ�A���ԍς�0�Ƃ���
        io_csv_rec.lease_dec_amount := 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.lease_delete_amount := 0;
      END;
--
    ELSE
      io_csv_rec.lease_delete_amount := 0;
    END IF;
--
    -- 11.�����c���̎擾
    -- -- ���������z�i���j�����݂��Ȃ��ꍇ
    IF (io_csv_rec.lease_year_del_amount = 0) THEN
      BEGIN
        SELECT xpp.fin_debt_rem  + NVL(xpp.debt_rem_re ,0) AS kimatsu_bal_amount -- �����c��
        INTO   io_csv_rec.kimatsu_bal_amount
        FROM   xxcff_pay_planning xpp
        WHERE  xpp.contract_line_id  = io_csv_rec.contract_line_id
        AND    xpp.period_name       = io_csv_rec.period_to
        AND    xpp.payment_frequency = (SELECT MAX(xpp2.payment_frequency)
                                        FROM   xxcff_pay_planning xpp2
                                        WHERE  xpp2.contract_line_id  = io_csv_rec.contract_line_id
                                        AND    xpp2.period_name       = io_csv_rec.period_to)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          io_csv_rec.kimatsu_bal_amount := 0;
      END;
    ELSE
      io_csv_rec.kimatsu_bal_amount := 0;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_lease_obl_info;
--
  /**********************************************************************************
   * Procedure Name   : get_asset_info
   * Description      : ���[�X���Y���擾����(A-8)
   ***********************************************************************************/
  PROCEDURE get_asset_info(
    iv_book_type_code IN     VARCHAR2,     -- 1.���Y�䒠��
    io_csv_rec        IN OUT g_csv_rtype,  -- 2.CSV�o�̓��R�[�h
    ov_errbuf         OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_asset_info'; -- �v���O������
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
    CURSOR asset_cur
    IS
      SELECT
             /*+
               LEADING(main)
             */
             main.asset_number               AS asset_number               -- ���Y�ԍ�
            ,main.original_cost              AS original_cost              -- �����擾���z
            ,main.cost                       AS cost                       -- �擾���z
            ,main.salvage_value              AS salvage_value              -- �c�����z
            ,main.adjusted_recoverable_cost  AS adjusted_recoverable_cost  -- ���p�Ώۊz
            --�ߋ��N�x�̎��Y�����N�x�ȍ~�Ɏ��Y�ǉ������ꍇ�A
            --�ߋ��N�x�̌������p�T�}������͊���뉿�����Ȃ����߁A
            --���������뉿�z�{�N���p�݌v�z�ŎZ�o
            ,CASE
               WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                 AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.ytd_deprn + main.deprn_reserve
               ELSE
                 NVL(kisyu.kisyu_boka, 0)
             END                             AS kisyu_boka                -- ���񒠕뉿�z
            ,CASE
               WHEN (io_csv_rec.lease_type       =  cv_lease_type_1
                 AND main.date_placed_in_service <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_placed_in_service >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS year_add_amount_new       -- ���������z(�V�K�_��)
            ,CASE
               WHEN (io_csv_rec.lease_type       =  cv_lease_type_2
                 AND main.date_placed_in_service <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_placed_in_service >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS year_add_amount_old       -- ���������z(�����_��)
            ,CASE
               WHEN (io_csv_rec.lease_type                            = cv_lease_type_1
                 AND TRUNC(main.date_placed_in_service ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS add_amount_new            -- ���������z(�V�K�_��)
            ,CASE
               WHEN (io_csv_rec.lease_type                            = cv_lease_type_2
                 AND TRUNC(main.date_placed_in_service ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.cost
               ELSE
                 0
             END                             AS add_amount_old            -- ���������z(�����_��)
            ,CASE
               WHEN (main.deprn_reserve = 0
                 AND main.nbv_retired   = 0) THEN
                 CASE
                   WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                     AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                     main.ytd_deprn
                   ELSE
                     NVL(kisyu.kisyu_boka, 0)
                 END
               ELSE
                 0
             END                             AS year_dec_amount           -- ���������z�i���p�I���j
            ,CASE
               WHEN (main.date_retired <= LAST_DAY(TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm))
                 AND main.date_retired >= TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                 main.nbv_retired     -- �����p���뉿�z
               ELSE
                 0
             END                             AS year_del_amount           -- ���������z�i���j
            ,CASE
               WHEN (main.deprn_reserve = 0
                 AND main.nbv_retired   = 0) THEN
                 CASE
                   WHEN (main.period_name = io_csv_rec.period_to) THEN
                     CASE
                       WHEN (NVL(kisyu.kisyu_boka, 0)    = 0
                         AND main.date_placed_in_service < TO_DATE(io_csv_rec.period_from ,cv_format_yyyy_mm) ) THEN
                         main.ytd_deprn
                       ELSE
                         NVL(kisyu.kisyu_boka, 0)
                     END
                   ELSE
                     0
                   END
               ELSE
                 0
             END                             AS dec_amount                -- ���������z�i���p�I���j
            ,CASE
               WHEN (TRUNC(main.date_retired ,cv_format_mm) = TO_DATE(io_csv_rec.period_to ,cv_format_yyyy_mm) ) THEN
                 main.nbv_retired      -- �����p���뉿�z
               ELSE
                 0
             END                             AS delete_amount             -- ���������z�i���j
            ,main.deprn_reserve              AS deprn_reserve             -- ���������뉿�z
            ,CASE
               WHEN (main.period_name = io_csv_rec.period_to) THEN
                 main.month_deprn
               ELSE
                 0
             END                             AS month_deprn               -- �������p�݌v�z
            ,main.ytd_deprn                  AS ytd_deprn                 -- �N���p�݌v�z
            ,main.total_amount               AS total_amount              -- ���p�݌v�z
            ,main.disc_seg                   AS disc_seg                  -- �J���Z�O�����g
            ,main.area                       AS area                      -- �ʐ�
      FROM   (SELECT /*+ LEADING(fdsp)
                         INDEX(fb FA_BOOKS_N1)
                         INDEX(fdp FA_DEPRN_PERIODS_U3)
                     */
                     fdsp_max.asset_id                   AS asset_id                     -- ���YID
                    ,fdsp_max.book_type_code             AS book_type_code               -- ���Y�䒠
                    ,fdsp_max.asset_number               AS asset_number                 -- ���Y�ԍ�
                    ,fb.original_cost                    AS original_cost                -- �����擾���z
                    ,fb.cost                             AS cost                         -- �擾���z
                    ,fb.salvage_value                    AS salvage_value                -- �c�����z
                    ,fb.adjusted_recoverable_cost        AS adjusted_recoverable_cost    -- ���p�Ώۊz
                    ,fb.date_placed_in_service           AS date_placed_in_service       -- ���Ƌ��p��
                    ,CASE
                       WHEN (fb.cost                = 0
                         OR  fdsp_max.deprn_reserve = 0) THEN
                         0
                       ELSE
                         fb.cost - fdsp_max.deprn_reserve
                     END                                 AS deprn_reserve                -- �����뉿�z
                    ,fdsp_max.period_name                AS period_name                  -- ��v����
                    ,ret.date_retired                    AS date_retired                 -- �����p��
                    ,NVL(ret.nbv_retired ,0)             AS nbv_retired                  -- �����p���뉿�z
                    ,fdsp_max.deprn_amount               AS month_deprn                  -- �������p�݌v�z
                    ,fdsp_max.ytd_deprn                  AS ytd_deprn                    -- �N���p�݌v�z
                    ,fdsp_max.deprn_reserve              AS total_amount                 -- ���p�݌v�z
                    ,fdsp_max.disc_seg                   AS disc_seg                     -- �J���Z�O�����g
                    ,fdsp_max.area                       AS area                         -- �ʐ�
              FROM   fa_books                                     fb       -- ���Y�䒠���
                    ,fa_retirements                               ret      -- �����p���
                    ,(SELECT fdp.period_counter             AS period_counter
                            ,fdp.book_type_code             AS book_type_code
                      FROM   fa_deprn_periods fdp     -- �������p����
                      WHERE  fdp.period_num     = 1
                      AND    fdp.period_name    = io_csv_rec.period_from
                      AND    fdp.book_type_code = iv_book_type_code
                     )                                            fdp1     -- �������p���� �N�n
                    ,(SELECT /*+
                                LEADING(fab)
                              */
                             fds.asset_id                   AS asset_id                   -- ���YID
                            ,fab.asset_number               AS asset_number               -- ���Y�ԍ�
                            ,fds.book_type_code             AS book_type_code             -- �䒠
                            ,fdp.period_name                AS period_name                -- ���Ԗ�
                            ,fdp.period_close_date          AS period_close_date          -- ���ԃN���[�Y��
                            ,fds.deprn_reserve              AS deprn_reserve              -- �������p�݌v�z�����z
                            ,fds.deprn_amount               AS deprn_amount               -- ���p�z
                            ,fds.ytd_deprn                  AS ytd_deprn                  -- �N���p�݌v�z
                            ,fab.attribute12                AS disc_seg                   -- �J���Z�O�����g
                            ,fab.attribute13                AS area                       -- �ʐ�
                      FROM   fa_additions_b    fab     -- ���Y�ڍ׏��
                            ,fa_deprn_summary  fds     -- �������p�T�}��
                            ,fa_deprn_periods  fdp     -- �������p����
                            ,(SELECT /*+
                                        LEADING(fab)
                                      */
                                     MAX(fdp.period_counter) period_counter
                              FROM   fa_additions_b    fab     -- ���Y�ڍ׏��
                                    ,fa_deprn_summary  fds     -- �������p�T�}��
                                    ,fa_deprn_periods  fdp     -- �������p����
                              WHERE  fab.attribute10       = TO_CHAR(io_csv_rec.contract_line_id)
                              AND    fab.asset_id          = fds.asset_id
                              AND    fds.book_type_code    = iv_book_type_code
                              AND    fds.book_type_code    = fdp.book_type_code
                              AND    fds.period_counter    = fdp.period_counter
                              AND    fds.deprn_source_code = cv_source_code_dep
                              AND    fdp.period_name       <= io_csv_rec.period_to
                             )                 fdp_max -- �Ώی��ȑO�̌������p���ԍő�̌�
                      WHERE  fab.attribute10                    = TO_CHAR(io_csv_rec.contract_line_id)
                      AND    fab.asset_id                       = fds.asset_id
                      AND    fds.book_type_code                 = iv_book_type_code
                      AND    fds.book_type_code                 = fdp.book_type_code
                      AND    fds.period_counter                 = fdp.period_counter
                      AND    fds.deprn_source_code              = cv_source_code_dep
                      AND    fdp.period_counter                 = fdp_max.period_counter
                     ) fdsp_max                                            -- �Ώی��ȑO�̍ő�̌��̌������p���
              WHERE  NVL(fb.date_ineffective ,fdsp_max.period_close_date) >= fdsp_max.period_close_date
              AND    fb.date_effective                                    <  fdsp_max.period_close_date
              AND    fb.book_type_code                                    =  fdsp_max.book_type_code
              AND    fb.asset_id                                          =  fdsp_max.asset_id
              AND    NVL(fb.period_counter_fully_retired,9999999)         >= fdp1.period_counter               -- ���N�x�ȍ~�̏����p�f�[�^
              AND    fb.book_type_code                                    =  fdp1.book_type_code
              AND    fb.asset_id                                          =  ret.asset_id (+)
              AND    fb.book_type_code                                    =  ret.book_type_code (+)
              AND    fb.transaction_header_id_in                          =  ret.transaction_header_id_in (+)
             ) main                                 -- ���p
            ,(SELECT /*+
                         LEADING(fab)
                     */
                     fab.asset_id                  AS asset_id         -- ���Yid
                    ,fb.book_type_code             AS book_type_code   -- �䒠
                    ,(fb.cost - fds.deprn_reserve) AS kisyu_boka       -- ����뉿
              FROM   fa_additions_b    fab     -- ���Y�ڍ׏��
                    ,fa_books          fb      -- ���Y�䒠���
                    ,fa_deprn_summary  fds     -- �������p�T�}��
                    ,fa_deprn_periods  fdp     -- �������p����
              WHERE  fab.attribute10                   = TO_CHAR(io_csv_rec.contract_line_id)
              AND    fab.asset_id                      = fb.asset_id
              AND    fb.book_type_code                 = iv_book_type_code
              AND    fb.date_effective                 <= fdp.period_close_date
              AND    NVL(fb.date_ineffective ,SYSDATE) >= fdp.period_close_date
              AND    fb.book_type_code                 = fds.book_type_code
              AND    fb.asset_id                       = fds.asset_id
              AND    fds.book_type_code                = fdp.book_type_code
              AND    fds.period_counter                = fdp.period_counter
              AND    fds.deprn_source_code             = cv_source_code_dep
              AND    fdp.period_num                    = 12
              AND    fdp.fiscal_year + 1               = TO_NUMBER(SUBSTR(io_csv_rec.period_from ,1 ,4))
             ) kisyu                                -- ����
      WHERE  main.asset_id           = kisyu.asset_id(+)
      AND    main.book_type_code     = kisyu.book_type_code(+)
      ;
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
    <<asset_loop>>
    FOR l_rec IN asset_cur LOOP
      io_csv_rec.asset_number              := l_rec.asset_number;              -- ���Y�ԍ�
      io_csv_rec.original_cost             := l_rec.original_cost;             -- �����擾���z
      io_csv_rec.cost                      := l_rec.cost;                      -- �擾���z
      io_csv_rec.salvage_value             := l_rec.salvage_value;             -- �c�����z
      io_csv_rec.adjusted_recoverable_cost := l_rec.adjusted_recoverable_cost; -- ���p�Ώۊz
      io_csv_rec.kisyu_boka                := l_rec.kisyu_boka;                -- ���񒠕뉿�z
      io_csv_rec.year_add_amount_new       := l_rec.year_add_amount_new;       -- ���������z(�V�K�_��)
      io_csv_rec.year_add_amount_old       := l_rec.year_add_amount_old;       -- ���������z(�����_��)
      io_csv_rec.add_amount_new            := l_rec.add_amount_new;            -- ���������z(�V�K�_��)
      io_csv_rec.add_amount_old            := l_rec.add_amount_old;            -- ���������z(�����_��)
      io_csv_rec.year_dec_amount           := l_rec.year_dec_amount;           -- ���������z�i���p�I���j
      io_csv_rec.year_del_amount           := l_rec.year_del_amount;           -- ���������z�i���j
      io_csv_rec.dec_amount                := l_rec.dec_amount;                -- ���������z�i���p�I���j
      io_csv_rec.delete_amount             := l_rec.delete_amount;             -- ���������z�i���j
      io_csv_rec.deprn_reserve             := l_rec.deprn_reserve;             -- ���������뉿�z
      io_csv_rec.month_deprn               := l_rec.month_deprn;               -- �������p�݌v�z
      io_csv_rec.ytd_deprn                 := l_rec.ytd_deprn;                 -- �N���p�݌v�z
      io_csv_rec.total_amount              := l_rec.total_amount;              -- ���p�݌v�z
      io_csv_rec.disc_seg                  := l_rec.disc_seg;                  -- �J���Z�O�����g
      io_csv_rec.area                      := l_rec.area;                      -- �ʐ�
    END LOOP asset_loop;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_asset_info;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : CSV�f�[�^�o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    iv_lease_kind IN     VARCHAR2,     -- 1.���[�X���
    io_csv_rec    IN OUT g_csv_rtype,  -- 2.CSV�o�̓��R�[�h
    ov_errbuf     OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- �v���O������
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
    cv_process_date CONSTANT DATE          := xxccp_common_pkg2.get_process_date;
    cv_lookup_type  CONSTANT VARCHAR2(100) := 'XXCFF1_LEASE_CSV_ITEM_NAME';
    cv_flag_y       CONSTANT VARCHAR2(1)   := 'Y';
    cv_sep_part     CONSTANT VARCHAR2(1)   := ',';
    cv_double_quat  CONSTANT VARCHAR2(1)   := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_csv_row VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR csv_header_cur
    IS
      SELECT flv.description
        FROM fnd_lookup_values_vl flv
       WHERE flv.lookup_type = cv_lookup_type
         AND flv.enabled_flag = cv_flag_y
         AND NVL(flv.start_date_active,cv_process_date) <= cv_process_date
         AND NVL(flv.end_date_active,cv_process_date) >= cv_process_date
         AND flv.attribute1 = cv_flag_y
      ORDER BY flv.lookup_code;
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
    -- 1���ڂ̏ꍇCSV�w�b�_�o��
    IF (gn_target_cnt = 1) THEN
      -- �w�b�_�s��ҏW
      <<csv_header_loop>>
      FOR l_rec IN csv_header_cur LOOP
        IF (csv_header_cur%ROWCOUNT > 1) THEN
          lv_csv_row := lv_csv_row ||cv_sep_part;
        END IF;
        lv_csv_row := lv_csv_row || cv_double_quat || l_rec.description || cv_double_quat;
      END LOOP csv_header_loop;
      -- �s����','����菜��
      lv_csv_row := RTRIM(lv_csv_row,cv_sep_part);
      -- OUT�t�@�C���ɏo��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_csv_row
      );
    END IF;
    -- OP���[�X�̏ꍇ�s�v���NULL
    IF iv_lease_kind = cv_lease_kind_op THEN
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.original_cost          := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      io_csv_rec.lease_charge_debt      := NULL;
      io_csv_rec.interest_future        := NULL;
      io_csv_rec.tax_future             := NULL;
      io_csv_rec.principal_1year        := NULL;
      io_csv_rec.interest_1year         := NULL;
      io_csv_rec.tax_1year              := NULL;
      io_csv_rec.principal_over_1year   := NULL;
      io_csv_rec.interest_over_1year    := NULL;
      io_csv_rec.tax_over_1year         := NULL;
      io_csv_rec.principal_1to2year     := NULL;
      io_csv_rec.interest_1to2year      := NULL;
      io_csv_rec.tax_1to2year           := NULL;
      io_csv_rec.principal_2to3year     := NULL;
      io_csv_rec.interest_2to3year      := NULL;
      io_csv_rec.tax_2to3year           := NULL;
      io_csv_rec.principal_3to4year     := NULL;
      io_csv_rec.interest_3to4year      := NULL;
      io_csv_rec.tax_3to4year           := NULL;
      io_csv_rec.principal_4to5year     := NULL;
      io_csv_rec.interest_4to5year      := NULL;
      io_csv_rec.tax_4to5year           := NULL;
      io_csv_rec.principal_over_5year   := NULL;
      io_csv_rec.interest_over_5year    := NULL;
      io_csv_rec.tax_over_5year         := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.deprn_reserve          := NULL;
--      io_csv_rec.bal_amount             := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      io_csv_rec.interest_amount        := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      io_csv_rec.deprn_amount           := NULL;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
    END IF;
    -- CSV�f�[�^�ҏW
    lv_csv_row := 
      cv_double_quat || io_csv_rec.lease_company         || cv_double_quat || cv_sep_part ||                   -- ���[�X��ЃR�[�h
      cv_double_quat || io_csv_rec.lease_company_name    || cv_double_quat || cv_sep_part ||                   -- ���[�X��Ж�
      cv_double_quat || io_csv_rec.period_from           || cv_double_quat || cv_sep_part ||                   -- �o�͊��ԁi���j
      cv_double_quat || io_csv_rec.period_to             || cv_double_quat || cv_sep_part ||                   -- �o�͊��ԁi���j
      cv_double_quat || io_csv_rec.contract_number       || cv_double_quat || cv_sep_part ||                   -- �_��No
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      cv_double_quat || io_csv_rec.object_code           || cv_double_quat || cv_sep_part ||                   -- �����R�[�h
      cv_double_quat || io_csv_rec.asset_number          || cv_double_quat || cv_sep_part ||                   -- ���Y�ԍ�
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      cv_double_quat || io_csv_rec.lease_class_name      || cv_double_quat || cv_sep_part ||                   -- ����
      cv_double_quat || io_csv_rec.lease_type_name       || cv_double_quat || cv_sep_part ||                   -- ���[�X�敪
      cv_double_quat || TO_CHAR(io_csv_rec.lease_start_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||  -- ���[�X�J�n��
      cv_double_quat || TO_CHAR(io_csv_rec.lease_end_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||    -- ���[�X�I����
      TO_CHAR(io_csv_rec.payment_frequency)      || cv_sep_part ||                                             -- ����
      TO_CHAR(io_csv_rec.monthly_charge)         || cv_sep_part ||                                             -- ���ԃ��[�X��
      TO_CHAR(io_csv_rec.gross_charge)           || cv_sep_part ||                                             -- ���[�X�����z
      TO_CHAR(io_csv_rec.lease_charge_this_month)|| cv_sep_part ||                                             -- �����x�����[�X��
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      -- ���[�X���Y
      TO_CHAR(io_csv_rec.original_cost)                  || cv_sep_part ||                                     -- �����擾���z
      TO_CHAR(io_csv_rec.cost)                           || cv_sep_part ||                                     -- �擾���z
      TO_CHAR(io_csv_rec.salvage_value)                  || cv_sep_part ||                                     -- �c�����z
      TO_CHAR(io_csv_rec.adjusted_recoverable_cost)      || cv_sep_part ||                                     -- ���p�Ώۊz
      TO_CHAR(io_csv_rec.kisyu_boka)                     || cv_sep_part ||                                     -- ���񒠕뉿�z
      TO_CHAR(io_csv_rec.year_add_amount_new)            || cv_sep_part ||                                     -- ���������z(�V�K�_��)
      TO_CHAR(io_csv_rec.year_add_amount_old)            || cv_sep_part ||                                     -- ���������z(�����_��)
      TO_CHAR(io_csv_rec.add_amount_new)                 || cv_sep_part ||                                     -- ���������z(�V�K�_��)
      TO_CHAR(io_csv_rec.add_amount_old)                 || cv_sep_part ||                                     -- ���������z(�����_��)
      TO_CHAR(io_csv_rec.year_dec_amount)                || cv_sep_part ||                                     -- ���������z(���p�I��)
      TO_CHAR(io_csv_rec.year_del_amount)                || cv_sep_part ||                                     -- ���������z(���)
      TO_CHAR(io_csv_rec.dec_amount)                     || cv_sep_part ||                                     -- ���������z(���p�I��)
      TO_CHAR(io_csv_rec.delete_amount)                  || cv_sep_part ||                                     -- ���������z(���)
      TO_CHAR(io_csv_rec.deprn_reserve)                  || cv_sep_part ||                                     -- ���������뉿�z
      TO_CHAR(io_csv_rec.month_deprn)                    || cv_sep_part ||                                     -- �������p�݌v�z
      TO_CHAR(io_csv_rec.ytd_deprn)                      || cv_sep_part ||                                     -- �N���p�݌v�z
      TO_CHAR(io_csv_rec.total_amount)                   || cv_sep_part ||                                     -- ���p�݌v�z
      -- ���[�X��
      TO_CHAR(io_csv_rec.kisyu_bal_amount)               || cv_sep_part ||                                     -- ����c��
      TO_CHAR(io_csv_rec.lease_year_add_amount_new)      || cv_sep_part ||                                     -- ���������z(�V�K�_��)
      TO_CHAR(io_csv_rec.lease_year_add_amount_old)      || cv_sep_part ||                                     -- ���������z(�����_��)
      TO_CHAR(io_csv_rec.lease_add_amount_new)           || cv_sep_part ||                                     -- ���������z(�V�K�_��)
      TO_CHAR(io_csv_rec.lease_add_amount_old)           || cv_sep_part ||                                     -- ���������z(�����_��)
      TO_CHAR(io_csv_rec.lease_year_dec_amount)          || cv_sep_part ||                                     -- ���������z(���ԍ�)
      TO_CHAR(io_csv_rec.lease_year_del_amount)          || cv_sep_part ||                                     -- ���������z(���)
      TO_CHAR(io_csv_rec.lease_dec_amount)               || cv_sep_part ||                                     -- ���������z(���ԍ�)
      TO_CHAR(io_csv_rec.lease_delete_amount)            || cv_sep_part ||                                     -- ���������z(���)
      TO_CHAR(io_csv_rec.kimatsu_bal_amount)             || cv_sep_part ||                                     -- �����c��
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      TO_CHAR(io_csv_rec.lease_charge_future)    || cv_sep_part ||                                             -- ���o�߃��[�X��
      TO_CHAR(io_csv_rec.lease_charge_1year)     || cv_sep_part ||                                             -- 1�N�ȓ����o�߃��[�X��
      TO_CHAR(io_csv_rec.lease_charge_over_1year)|| cv_sep_part ||                                             -- 1�N�����o�߃��[�X��
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.original_cost)          || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.lease_charge_debt)      || cv_sep_part ||                                             -- ���o�߃��[�X�����c�������z
      TO_CHAR(io_csv_rec.interest_future)        || cv_sep_part ||                                             -- ���o�߃��[�X�x�������z
      TO_CHAR(io_csv_rec.tax_future)             || cv_sep_part ||                                             -- ���o�߃��[�X����Ŋz
      TO_CHAR(io_csv_rec.principal_1year)        || cv_sep_part ||                                             -- 1�N�ȓ����{�z
      TO_CHAR(io_csv_rec.interest_1year)         || cv_sep_part ||                                             -- 1�N�ȓ��x������
      TO_CHAR(io_csv_rec.tax_1year)              || cv_sep_part ||                                             -- 1�N�ȓ������
      TO_CHAR(io_csv_rec.principal_over_1year)   || cv_sep_part ||                                             -- 1�N�����{�z
      TO_CHAR(io_csv_rec.interest_over_1year)    || cv_sep_part ||                                             -- 1�N���x������
      TO_CHAR(io_csv_rec.tax_over_1year)         || cv_sep_part ||                                             -- 1�N������Ŋz
      TO_CHAR(io_csv_rec.principal_1to2year)     || cv_sep_part ||                                             -- 1�N��2�N�ȓ����{�z
      TO_CHAR(io_csv_rec.interest_1to2year)      || cv_sep_part ||                                             -- 1�N��2�N�ȓ��x������
      TO_CHAR(io_csv_rec.tax_1to2year)           || cv_sep_part ||                                             -- 1�N��2�N�ȓ�����Ŋz
      TO_CHAR(io_csv_rec.principal_2to3year)     || cv_sep_part ||                                             -- 2�N��3�N�ȓ����{�z
      TO_CHAR(io_csv_rec.interest_2to3year)      || cv_sep_part ||                                             -- 2�N��3�N�ȓ��x������
      TO_CHAR(io_csv_rec.tax_2to3year)           || cv_sep_part ||                                             -- 2�N��3�N�ȓ�����Ŋz
      TO_CHAR(io_csv_rec.principal_3to4year)     || cv_sep_part ||                                             -- 3�N��4�N�ȓ����{�z
      TO_CHAR(io_csv_rec.interest_3to4year)      || cv_sep_part ||                                             -- 3�N��4�N�ȓ��x������
      TO_CHAR(io_csv_rec.tax_3to4year)           || cv_sep_part ||                                             -- 3�N��4�N�ȓ�����Ŋz
      TO_CHAR(io_csv_rec.principal_4to5year)     || cv_sep_part ||                                             -- 4�N��5�N�ȓ����{�z
      TO_CHAR(io_csv_rec.interest_4to5year)      || cv_sep_part ||                                             -- 4�N��5�N�ȓ��x������
      TO_CHAR(io_csv_rec.tax_4to5year)           || cv_sep_part ||                                             -- 4�N��5�N�ȓ�����Ŋz
      TO_CHAR(io_csv_rec.principal_over_5year)   || cv_sep_part ||                                             -- 5�N�����{�z
      TO_CHAR(io_csv_rec.interest_over_5year)    || cv_sep_part ||                                             -- 5�N���x������
      TO_CHAR(io_csv_rec.tax_over_5year)         || cv_sep_part ||                                             -- 5�N������Ŋz
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.deprn_reserve)          || cv_sep_part ||
--      TO_CHAR(io_csv_rec.bal_amount)             || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.interest_amount)        || cv_sep_part ||                                             -- �x�����������z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--      TO_CHAR(io_csv_rec.deprn_amount)           || cv_sep_part ||
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
      TO_CHAR(io_csv_rec.monthly_deduction)      || cv_sep_part ||                                             -- ���ԃ��[�X���i�T���z�j
      TO_CHAR(io_csv_rec.gross_deduction)        || cv_sep_part ||                                             -- ���[�X�����z�i�T���z�j
      TO_CHAR(io_csv_rec.deduction_this_month)   || cv_sep_part ||                                             -- �����x�����[�X���i�T���z�j
      TO_CHAR(io_csv_rec.deduction_future)       || cv_sep_part ||                                             -- ���o�߃��[�X���i�T���z�j
      TO_CHAR(io_csv_rec.deduction_1year)        || cv_sep_part ||                                             -- 1�N�ȓ����o�߃��[�X���i�T���z�j
-- 2018/03/27 Ver.1.7 Y.Shoji MODL Start
--      TO_CHAR(io_csv_rec.deduction_over_1year)   ;
      TO_CHAR(io_csv_rec.deduction_over_1year)   || cv_sep_part ||                                             -- 1�N�����o�߃��[�X���i�T���z�j
      cv_double_quat || io_csv_rec.disc_seg      || cv_double_quat || cv_sep_part ||                           -- �J���Z�O�����g
      cv_double_quat || io_csv_rec.area          || cv_double_quat ;                                           -- �ʐ�
-- 2018/03/27 Ver.1.7 Y.Shoji MODL End
    -- OUT�t�@�C���ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csv_row
    );
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_planning
   * Description      : ���[�X�x���v����擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_pay_planning(
    id_start_date_1st IN     DATE,         -- 1.����J�n��
    id_start_date_now IN     DATE,         -- 2.�����J�n��
    io_csv_rec        IN OUT g_csv_rtype,  -- 3.CSV�o�̓��R�[�h
    ov_errbuf         OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_planning'; -- �v���O������
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
    CURSOR planning_cur
    IS
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      SELECT xpp.contract_header_id
      SELECT xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0000417 2009/07/17 ADD START --
          ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/17 ADD END --
-- 0000417 2009/07/17 MOD START --            
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                 (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/17 MOD END --
                    (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                      xpp.lease_charge
                     ELSE 0 END)
-- 0000417 2009/07/17 ADD START --
                  ELSE 0 END)
-- 0000417 2009/07/17 ADD END --
               ELSE 0 END) AS lease_charge_this_month   -- �����x�����[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_future       -- ���o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_charge
                    ELSE 0 END)
                 ELSE 0 END) AS lease_charge_1year        -- 1�N�ȓ����o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_charge
                 ELSE 0 END) AS lease_charge_over_1year   -- 1�N�z���o�߃��[�X��
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS lease_charge_debt         -- ���o�߃��[�X�����c�������z
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_future           -- ���o�߃��[�X�x�������z
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- ���o�߃��[�X����Ŋz
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS principal_over_1year      -- 1�N�z���{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_over_1year       -- 1�N�z�x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_1year            -- 1�N�z�����
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1�N��2�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1�N��2�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1�N��2�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2�N��3�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2�N��3�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2�N��3�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3�N��4�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3�N��4�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3�N��4�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_debt
                      xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4�N��5�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                      xpp.fin_interest_due
                      xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4�N��5�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4�N��5�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_debt
                   xpp.fin_debt + NVL(xpp.debt_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS principal_over_5year      -- 5�N�z���{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                   xpp.fin_interest_due
                   xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                 ELSE 0 END) AS interest_over_5year       -- 5�N�z�x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_5year            -- 5�N�z�����
-- 0000417 2009/07/31 ADD START --
           ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                  (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                     (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
-- 2016/09/14 Ver.1.6 Y.Koh MOD Start
--                        xpp.fin_interest_due
                        xpp.fin_interest_due + NVL(xpp.interest_due_re,0)
-- 2016/09/14 Ver.1.6 Y.Koh MOD End
                      ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                   ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                ELSE 0 END) AS interest_amount           -- �x�����������z
-- 0000417 2009/07/31 ADD START --
           ,SUM(CASE WHEN xpp.accounting_if_flag = cv_if_aft THEN
-- 0000417 2009/07/31 ADD END --
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
                  (CASE WHEN xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM') THEN
-- 0000417 2009/07/31 MOD END --
                     (CASE WHEN xpp.period_name <= TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                        xpp.lease_deduction
                      ELSE 0 END)
-- 0000417 2009/07/31 ADD START --
                   ELSE 0 END)
-- 0000417 2009/07/31 ADD END --
                ELSE 0 END) AS deduction_this_month      -- �����x�����[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_future          -- ���o�߃��[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.lease_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS deduction_1year           -- 1�N�ȓ����o�߃��[�X���i�T���z�j
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.lease_deduction
                 ELSE 0 END) AS deduction_over_1year      -- 1�N�z���o�߃��[�X���i�T���z�j
        FROM xxcff_contract_lines xcl
            ,xxcff_pay_planning xpp
       WHERE xcl.contract_line_id = xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--         AND xcl.contract_header_id = io_csv_rec.contract_header_id
         AND xcl.contract_line_id = io_csv_rec.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(xcl.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
                  xcl.cancellation_date IS NOT NULL)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      GROUP BY xpp.contract_header_id
      GROUP BY xpp.contract_line_id
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
      ;
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
    <<planning_loop>>
    FOR l_rec IN planning_cur LOOP
      io_csv_rec.lease_charge_this_month := l_rec.lease_charge_this_month; -- �����x�����[�X��
      io_csv_rec.lease_charge_future     := l_rec.lease_charge_future;     -- ���o�߃��[�X��
      io_csv_rec.lease_charge_1year      := l_rec.lease_charge_1year;      -- 1�N�ȓ����o�߃��[�X��
      io_csv_rec.lease_charge_over_1year := l_rec.lease_charge_over_1year; -- 1�N�z���o�߃��[�X��
      io_csv_rec.lease_charge_debt       := l_rec.lease_charge_debt;       -- ���o�߃��[�X�����c�������z
      io_csv_rec.interest_future         := l_rec.interest_future;         -- ���o�߃��[�X�x�������z
      io_csv_rec.tax_future              := l_rec.tax_future;              -- ���o�߃��[�X����Ŋz
      io_csv_rec.principal_1year         := l_rec.principal_1year;         -- 1�N�ȓ����{
      io_csv_rec.interest_1year          := l_rec.interest_1year;          -- 1�N�ȓ��x������
      io_csv_rec.tax_1year               := l_rec.tax_1year;               -- 1�N�ȓ������
      io_csv_rec.principal_over_1year    := l_rec.principal_over_1year;    -- 1�N�z���{
      io_csv_rec.interest_over_1year     := l_rec.interest_over_1year;     -- 1�N�z�x������
      io_csv_rec.tax_over_1year          := l_rec.tax_over_1year;          -- 1�N�z�����
      io_csv_rec.principal_1to2year      := l_rec.principal_1to2year;      -- 1�N�z2�N�ȓ����{
      io_csv_rec.interest_1to2year       := l_rec.interest_1to2year;       -- 1�N�z2�N�ȓ��x������
      io_csv_rec.tax_1to2year            := l_rec.tax_1to2year;            -- 1�N�z2�N�ȓ������
      io_csv_rec.principal_2to3year      := l_rec.principal_2to3year;      -- 2�N��3�N�ȓ����{
      io_csv_rec.interest_2to3year       := l_rec.interest_2to3year;       -- 2�N��3�N�ȓ��x������
      io_csv_rec.tax_2to3year            := l_rec.tax_2to3year;            -- 2�N��3�N�ȓ������
      io_csv_rec.principal_3to4year      := l_rec.principal_3to4year;      -- 3�N�z4�N�ȓ����{
      io_csv_rec.interest_3to4year       := l_rec.interest_3to4year;       -- 3�N�z4�N�ȓ��x������
      io_csv_rec.tax_3to4year            := l_rec.tax_3to4year;            -- 3�N�z4�N�ȓ������
      io_csv_rec.principal_4to5year      := l_rec.principal_4to5year;      -- 4�N�z5�N�ȓ����{
      io_csv_rec.interest_4to5year       := l_rec.interest_4to5year;       -- 4�N�z5�N�ȓ��x������
      io_csv_rec.tax_4to5year            := l_rec.tax_4to5year;            -- 4�N�z5�N�ȓ������
      io_csv_rec.principal_over_5year    := l_rec.principal_over_5year;    -- 5�N�z���{
      io_csv_rec.interest_over_5year     := l_rec.interest_over_5year;     -- 5�N�z�x������
      io_csv_rec.tax_over_5year          := l_rec.tax_over_5year;          -- 5�N�z�����
      io_csv_rec.interest_amount         := l_rec.interest_amount;         -- �x�����������z
      io_csv_rec.deduction_this_month    := l_rec.deduction_this_month;    -- �����x�����[�X���i�T���z�j
      io_csv_rec.deduction_future        := l_rec.deduction_future;        -- ���o�߃��[�X���i�T���z�j
      io_csv_rec.deduction_1year         := l_rec.deduction_1year;         -- 1�N�ȓ����o�߃��[�X���i�T���z�j
      io_csv_rec.deduction_over_1year    := l_rec.deduction_over_1year;    -- 1�N�z���o�߃��[�X���i�T���z�j
    END LOOP planning_loop;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_info
   * Description      : ���[�X�_����擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_info(
    iv_lease_company   IN  VARCHAR2,  --  1.���[�X���
    iv_lease_kind      IN  VARCHAR2,  --  2.���[�X���
    id_start_date_1st  IN  DATE,      --  3.����J�n��
    id_start_date_now  IN  DATE,      --  4.�����J�n��
    iv_book_type_code  IN  VARCHAR2,  --  5.���Y�䒠��
    in_fiscal_year     IN  NUMBER,    --  6.��v�N�x
    in_period_num_1st  IN  NUMBER,    --  7.������Ԕԍ�
    in_period_num_now  IN  NUMBER,    --  8.�������Ԕԍ�
    iv_period_from     IN  VARCHAR2,  --  9.�o�͊��ԁi���j
    iv_period_to       IN  VARCHAR2,  -- 10.�o�͊��ԁi���j
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_lease_class     IN  VARCHAR2,  -- 11.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_errbuf          OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_info'; -- �v���O������
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
    cv_lease_type1 CONSTANT VARCHAR2(1) := '1'; -- ���[�X�敪�F���_��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
-- 0000417 2009/08/05 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xch.contract_header_id             -- �_�����ID
            ,xch.lease_company                  -- ���[�X��ЃR�[�h
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- ���[�X���
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- ���[�X�敪
            ,xch.lease_start_date               -- ���[�X�J�n��
            ,xch.lease_end_date                 -- ���[�X�I����
            ,xch.payment_frequency              -- ����
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- �擾���z���z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
--                           xcl.expiration_date IS NULL   THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
-- 0000417 2009/07/31 MOD END --
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
            ,SUM(fds.deprn_amount) AS deprn_amount -- �������p�����z
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
       LEFT JOIN fa_additions_b fab           -- ���Y�ڍ׏��
          ON fab.attribute10 = xcl.contract_line_id
-- 0000417 2009/07/31 ADD START --
       LEFT JOIN fa_retirements fret  -- �����p
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
-- 0000417 2009/07/31 ADD END --
       LEFT JOIN fa_deprn_periods fdp         -- �������p����
          ON fdp.book_type_code = iv_book_type_code
       LEFT JOIN fa_deprn_summary fds         -- �������p�T�}��
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
         AND xch.lease_type = cv_lease_type1
         AND xcl.lease_kind = iv_lease_kind
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xch.contract_header_id
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
      ;
    contract_rec contract_cur%ROWTYPE;
*/
-- 0000417 2009/08/05 DEL END --
--
-- 0000417 2009/08/05 ADD START --
    --FIN�A��FIN���[�X�擾�ΏۃJ�[�\��
    CURSOR contract_cur
    IS
      SELECT
-- 0001061 2009/08/28 ADD START --
             /*+
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--               INDEX(XCH XXCFF_CONTRACT_HEADERS_N04)
               LEADING(XCL)
               USE_NL(XCL XOH)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
               USE_NL(XCH XLCV)
               USE_NL(XCH XLSV)
               USE_NL(XCH XLTV)
               USE_NL(XCH XCL)
               USE_NL(XCL FAB)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--               INDEX(XCL XXCFF_CONTRACT_LINES_U01)
               INDEX(XCL XXCFF_CONTRACT_LINES_N01)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
               INDEX(FDP FA_DEPRN_PERIODS_U2)
               INDEX(FDS FA_DEPRN_SUMMARY_U1)
               INDEX(FRET FA_RETIREMENTS_N1)
             */
-- 0001061 2009/08/28 ADD END --
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--             xch.contract_header_id             -- �_�����ID
             xcl.contract_line_id contract_line_id  -- �_�񖾍�ID
            ,xoh.object_code      object_code       -- �����R�[�h
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
            ,xch.lease_company                  -- ���[�X��ЃR�[�h
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- ���[�X���
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- ���[�X�敪
            ,xch.lease_start_date               -- ���[�X�J�n��
            ,xch.lease_end_date                 -- ���[�X�I����
            ,xch.payment_frequency              -- ����
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
--                           fret.status <> cv_processed   THEN
--                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
--                      xcl.original_cost
--                    ELSE 0 END)
--                 ELSE 0 END) AS original_cost   -- �擾���z���z
--            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
--                           fret.status <> cv_processed   THEN
--                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
--                      NVL(fds.deprn_reserve,original_cost)
--                    ELSE 0 END)
--                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
            ,SUM(fds.deprn_amount) AS deprn_amount -- �������p�����z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
                           fret.date_retired  >= id_start_date_1st OR
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            ,xoh.cancellation_date cancellation_date   -- ����
            ,xch.lease_type        lease_type          -- ���[�X�敪
            ,xcl.original_cost     lease_original_cost -- �擾���z
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
-- 0001061 2009/08/28 ADD START --
         AND xcl.lease_kind         = iv_lease_kind
         AND xcl.contract_status    > cv_contr_st_201
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
       INNER JOIN xxcff_object_headers xoh    -- ���[�X����
          ON xcl.object_header_id   = xoh.object_header_id
         AND (xoh.cancellation_date IS NULL
           OR xoh.cancellation_date >= id_start_date_1st)
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
-- 0001061 2009/08/28 ADD END --
       INNER JOIN fa_additions_b fab           -- ���Y�ڍ׏��
          ON fab.attribute10 = to_char(xcl.contract_line_id)
       LEFT JOIN fa_retirements fret  -- �����p
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- �������p����
          ON fdp.book_type_code = iv_book_type_code
-- 0001061 2009/08/28 ADD START --
         AND fdp.fiscal_year = in_fiscal_year
         AND fdp.period_num >= in_period_num_1st
         AND fdp.period_num <= in_period_num_now
-- 0001061 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- �������p�T�}��
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--         AND xch.lease_type = cv_lease_type1
         AND xch.lease_class   = NVL(iv_lease_class ,xch.lease_class)
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
-- 0001061 2009/08/28 DEL START --
--         AND xcl.lease_kind = iv_lease_kind
--         AND xcl.contract_status > cv_contr_st_201
--         AND fdp.fiscal_year = in_fiscal_year
--         AND fdp.period_num >= in_period_num_1st
--         AND fdp.period_num <= in_period_num_now
-- 0001061 2009/08/28 DEL END --
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--              ,xch.contract_header_id
              ,xcl.contract_line_id
              ,xoh.object_code
              ,xch.lease_type
              ,xcl.original_cost
              ,xoh.cancellation_date
              ,fab.attribute12
              ,fab.attribute13
-- 2018/03/27 Ver.1.7 Y.Shoji MID End
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
              ,xoh.object_code
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ;
--
    --OP���[�X�Ώێ擾�J�[�\��
    CURSOR contract_op_cur
    IS
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--      SELECT xch.contract_header_id             -- �_�����ID
      SELECT /*+
                 LEADING(XCL)
                 USE_NL(XCL XCH)
                 USE_NL(XCL XOH)
                 USE_NL(XCL XPP)
                 INDEX(XCL XXCFF_CONTRACT_LINES_N01)
                 INDEX(XCH XXCFF_CONTRACT_HEADERS)
                 INDEX(XOH XXCFF_OBJECT_HEADERS)
              */
             xcl.contract_line_id               -- �_�񖾍�ID
            ,xoh.object_code                    -- �����R�[�h
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
            ,xch.lease_company                  -- ���[�X��ЃR�[�h
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,(SELECT xlsv.lease_class_name
                FROM xxcff_lease_class_v xlsv
               WHERE xlsv.lease_class_code = xch.lease_class
              ) AS lease_class_name             -- ���[�X���
            ,(SELECT xltv.lease_type_name
                FROM xxcff_lease_type_v xltv
               WHERE xltv.lease_type_code = xch.lease_type
              ) AS lease_type_name              -- ���[�X�敪
            ,xch.lease_start_date               -- ���[�X�J�n��
            ,xch.lease_end_date                 -- ���[�X�I����
            ,xch.payment_frequency              -- ����
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_charge
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_charge
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--            ,NULL AS original_cost   -- �擾���z���z
--            ,NULL AS deprn_reserve   -- �������p�݌v�z�����z
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
            ,NULL AS deprn_amount    -- �������p�����z
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN xcl.cancellation_date IS NULL AND
                           xcl.expiration_date IS NULL   THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            ,xcl.cancellation_date cancellation_date   -- ����
            ,xch.lease_type        lease_type          -- ���[�X�敪
            ,xcl.original_cost     lease_original_cost -- �擾���z
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
       INNER JOIN xxcff_object_headers xoh    -- ���[�X����
          ON xcl.object_header_id  = xoh.object_header_id
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
       WHERE xch.lease_company = NVL(iv_lease_company,xch.lease_company)
         AND xch.lease_type = cv_lease_type1
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
         AND xch.lease_class   = NVL(iv_lease_class ,xch.lease_class)
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
         AND xcl.lease_kind = iv_lease_kind
         AND EXISTS (
             SELECT 'x' FROM xxcff_pay_planning xpp
              WHERE xpp.contract_line_id = xcl.contract_line_id
                AND xpp.period_name >= TO_CHAR(id_start_date_1st,'YYYY-MM')
             )
         AND xcl.contract_status > cv_contr_st_201
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--              ,xch.contract_header_id
              ,xcl.contract_line_id
              ,xoh.object_code
              ,xch.lease_type
              ,xcl.original_cost
              ,xcl.cancellation_date
-- 2018/03/27 Ver.1.7 Y.Shoji MID End
      ORDER BY xch.lease_company
              ,xch.contract_number
              ,xch.lease_start_date
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
              ,xoh.object_code
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ;
    contract_rec contract_cur%ROWTYPE;
-- 0000417 2009/08/05 ADD END --
--
    -- *** ���[�J���E���R�[�h ***
    l_csv_rec  g_csv_rtype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
-- 0000417 2009/08/05 ADD START --
    -- ���[�X��ʂ�FIN���[�X�A��FIN���[�X�̏ꍇ
    IF iv_lease_kind IN (cv_lease_kind_fin,cv_lease_kind_qfin) THEN
-- 0000417 2009/08/05 ADD END --
      OPEN contract_cur;
      <<main_loop>>
      LOOP
        FETCH contract_cur INTO contract_rec;
        EXIT WHEN contract_cur%NOTFOUND;
-- 0000417 2009/08/05 ADD START --
        IF (contract_rec.deprn_amount IS NOT NULL) THEN
-- 0000417 2009/08/05 ADD END --
          -- �Ώی����C���N�������g
          gn_target_cnt := gn_target_cnt + 1;
          -- ������
          l_csv_rec := NULL;
          -- �擾�l���i�[
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--          l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
          l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
          l_csv_rec.object_code         := contract_rec.object_code;
          l_csv_rec.lease_type          := contract_rec.lease_type;
          l_csv_rec.lease_original_cost := contract_rec.lease_original_cost;
          l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
          l_csv_rec.lease_company       := contract_rec.lease_company;
          l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
          l_csv_rec.period_from         := iv_period_from;
          l_csv_rec.period_to           := iv_period_to;
          l_csv_rec.contract_number     := contract_rec.contract_number;
          l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
          l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
          l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
          l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
          l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
          l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
          l_csv_rec.gross_charge        := contract_rec.gross_charge;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.original_cost       := contract_rec.original_cost;
--          l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
--          l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
          l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          -- ============================================
          -- A-5�D���[�X�x���v����擾����
          -- ============================================
          get_pay_planning(
             id_start_date_1st
            ,id_start_date_now
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
          -- ============================================
          -- A-8�D���[�X���Y���擾����
          -- ============================================
          get_asset_info(
             iv_book_type_code
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ============================================
          -- A-9�D���[�X�����擾����
          -- ============================================
          get_lease_obl_info(
             l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
          -- ============================================
          -- A-6�DCSV�f�[�^�o�͏���
          -- ============================================
          out_csv_data(
             iv_lease_kind
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ���������C���N�������g
          gn_normal_cnt := gn_normal_cnt + 1;
-- 0000417 2009/08/05 ADD START --
        END IF;
-- 0000417 2009/08/05 ADD END --
      END LOOP main_loop;
-- 0000417 2009/08/05 ADD START --
      -- �Ώی�����0���������ꍇ�͌x���I��
      IF (contract_cur%ROWCOUNT = 0) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
-- 0000417 2009/08/05 ADD END --
--
-- 0000417 2009/08/05 ADD START --
    IF iv_lease_kind = cv_lease_kind_op THEN
      OPEN contract_op_cur;
      <<main_loop2>>
      LOOP
        FETCH contract_op_cur INTO contract_rec;
        EXIT WHEN contract_op_cur%NOTFOUND;
          -- �Ώی����C���N�������g
          gn_target_cnt := gn_target_cnt + 1;
          -- ������
          l_csv_rec := NULL;
          -- �擾�l���i�[
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--          l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
          l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
          l_csv_rec.object_code         := contract_rec.object_code;
          l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
          l_csv_rec.lease_company       := contract_rec.lease_company;
          l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
          l_csv_rec.period_from         := iv_period_from;
          l_csv_rec.period_to           := iv_period_to;
          l_csv_rec.contract_number     := contract_rec.contract_number;
          l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
          l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
          l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
          l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
          l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
          l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
          l_csv_rec.gross_charge        := contract_rec.gross_charge;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.original_cost       := contract_rec.original_cost;
--          l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
--          l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
          l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL Start
--          l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
-- 2018/03/27 Ver.1.7 Y.Shoji DEL End
          -- ============================================
          -- A-5�D���[�X�x���v����擾����
          -- ============================================
          get_pay_planning(
             id_start_date_1st
            ,id_start_date_now
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ============================================
          -- A-6�DCSV�f�[�^�o�͏���
          -- ============================================
          out_csv_data(
             iv_lease_kind
            ,l_csv_rec
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg);
          IF (lv_retcode != cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
          -- ���������C���N�������g
          gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP main_loop2;
      -- �Ώی�����0���������ꍇ�͌x���I��
      IF (contract_op_cur%ROWCOUNT = 0) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
-- 0000417 2009/08/05 ADD END --
--
-- 0000417 2009/08/05 MOD START --
--    CLOSE contract_cur;
    IF (contract_cur%ISOPEN) THEN
      CLOSE contract_cur;
    END IF;
    IF (contract_op_cur%ISOPEN) THEN
      CLOSE contract_op_cur;
    END IF;
-- 0000417 2009/08/05 MOD END --
--
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
      -- �G���[�����C���N�������g
      gn_error_cnt := gn_error_cnt + 1;
      -- �J�[�\���N���[�Y
      IF (contract_cur%ISOPEN) THEN
        CLOSE contract_cur;
      END IF;
-- 0000417 2009/08/05 ADD START --
      IF (contract_op_cur%ISOPEN) THEN
        CLOSE contract_op_cur;
      END IF;
-- 0000417 2009/08/05 ADD END --
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
  END get_contract_info;
--
  /**********************************************************************************
   * Procedure Name   : get_first_period
   * Description      : ��v���Ԋ���擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_first_period(
    iv_lease_kind     IN  VARCHAR2,     -- 1.���[�X���
    in_fiscal_year    IN  NUMBER,       -- 2.��v�N�x
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_book_type_code IN  VARCHAR2,     -- 3.���Y�䒠��
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_period_from    OUT VARCHAR2,     -- 4.�o�͊��ԁi���j
    on_period_num_1st OUT NUMBER,       -- 5.���Ԕԍ�
    od_start_date_1st OUT DATE,         -- 6.����J�n��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_first_period'; -- �v���O������
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
    cn_period_num_1st CONSTANT NUMBER(1) := 1;  -- ������Ԕԍ�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_1st_cur
    IS
      SELECT fcp.period_name AS period_from    -- �o�͊��ԁi���j
            ,fcp.period_num  AS period_num     -- ���Ԕԍ�
            ,fcp.start_date  AS start_date_1st -- ����J�n��
        FROM fa_calendar_periods fcp  -- ���Y�J�����_
            ,fa_calendar_types fct    -- ���Y�J�����_�^�C�v
            ,fa_fiscal_year ffy       -- ���Y��v�N�x
            ,fa_book_controls fbc     -- ���Y�䒠�}�X�^
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--            ,xxcff_lease_kind_v xlk   -- ���[�X��ރr���[
--       WHERE fbc.book_type_code = xlk.book_type_code
--         AND xlk.lease_kind_code = iv_lease_kind
       WHERE fbc.book_type_code = iv_book_type_code
-- 2018/03/27 Ver.1.7 Y.Shoji MOD END
         AND fbc.deprn_calendar = fcp.calendar_type
         AND ffy.fiscal_year = in_fiscal_year
         AND ffy.fiscal_year_name = fct.fiscal_year_name
         AND fct.calendar_type = fcp.calendar_type
         AND fcp.start_date >= ffy.start_date
         AND fcp.end_date <= ffy.end_date
         AND fcp.period_num = cn_period_num_1st;
    period_1st_rec period_1st_cur%ROWTYPE;
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
    OPEN period_1st_cur;
    FETCH period_1st_cur INTO period_1st_rec;
    CLOSE period_1st_cur;
    -- �߂�l�ݒ�
    ov_period_from    := period_1st_rec.period_from;     -- �o�͊��ԁi���j
    on_period_num_1st := period_1st_rec.period_num;      -- ���Ԕԍ�
    od_start_date_1st := period_1st_rec.start_date_1st;  -- ����J�n��
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_first_period;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_name
   * Description      : ��v���ԃ`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.��v���Ԗ�
    iv_lease_kind     IN  VARCHAR2,     -- 2.���[�X���
    iv_book_class     IN  VARCHAR2,     -- 3.���Y�䒠�敪
    on_fiscal_year    OUT NUMBER,       -- 4.��v�N�x
    ov_period_to      OUT VARCHAR2,     -- 5.�o�͊��ԁi���j
    on_period_num_now OUT NUMBER,       -- 6.���Ԕԍ�
    od_start_date_now OUT DATE,         -- 7.�����J�n��
    ov_book_type_code OUT VARCHAR2,     -- 8.���Y�䒠��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- �v���O������
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
    lt_book_type_code  fa_book_controls.book_type_code%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_cur(
      iv_book_type_code_c VARCHAR2
    )IS
      SELECT fdp.deprn_run   AS deprn_run      -- �������p���s�t���O
            ,fdp.fiscal_year AS fiscal_year    -- ��v����
            ,fdp.period_name AS period_to      -- �o�͊��ԁi���j
            ,fdp.period_num  AS period_num     -- ���Ԕԍ�
            ,fcp.start_date  AS start_date_now -- �����J�n��
        FROM fa_deprn_periods fdp     -- �������p����
            ,fa_calendar_periods fcp  -- ���Y�J�����_
            ,fa_book_controls fbc     -- ���Y�䒠�}�X�^
       WHERE fbc.book_type_code = iv_book_type_code_c
         AND fdp.period_name = iv_period_name
         AND fdp.book_type_code = fbc.book_type_code
         AND fbc.deprn_calendar = fcp.calendar_type
         AND fdp.period_name = fcp.period_name;
    period_rec period_cur%ROWTYPE;
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
    -- ���Y�䒠���擾
    SELECT (CASE iv_book_class
            WHEN cv_book_class_1 THEN xlk.book_type_code
            WHEN cv_book_class_2 THEN xlk.book_type_code_tax
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
            WHEN cv_book_class_3 THEN xlk.book_type_code_ifrs
-- 2018/03/27 Ver.1.7 Y.Shoji ADD END
            ELSE NULL END)
      INTO lt_book_type_code
      FROM xxcff_lease_kind_v xlk
     WHERE xlk.lease_kind_code = iv_lease_kind;
    -- �������p���ԏ��擾
    OPEN period_cur(
      lt_book_type_code
    );
    FETCH period_cur INTO period_rec;
    CLOSE period_cur;
    IF (NVL(period_rec.deprn_run,'N') != 'Y') THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name,cv_msg_close
                     ,cv_tkn_book_type,lt_book_type_code
                     ,cv_tkn_period_name,iv_period_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �߂�l�ݒ�
    on_fiscal_year    := period_rec.fiscal_year;      -- ��v�N�x
    ov_period_to      := period_rec.period_to;        -- �o�͊��ԁi���j
    on_period_num_now := period_rec.period_num;       -- ���Ԕԍ�
    od_start_date_now := period_rec.start_date_now;   -- �����J�n��
    ov_book_type_code := lt_book_type_code;           -- ���Y�䒠��
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** ���ʏ�����O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END chk_period_name;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
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
    xxcff_common1_pkg.put_log_param(
       iv_which    => cv_which     -- �o�͋敪
      ,ov_retcode  => lv_retcode   --���^�[���R�[�h
      ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
      ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name   IN    VARCHAR2,        -- 1.��v���Ԗ�
    iv_lease_kind    IN    VARCHAR2,        -- 2.���[�X���
    iv_book_class    IN    VARCHAR2,        -- 3.���Y�䒠�敪
    iv_lease_company IN    VARCHAR2,        -- 4.���[�X��ЃR�[�h
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    iv_lease_class   IN    VARCHAR2,        -- 5.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    ov_errbuf        OUT   VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT   VARCHAR2,        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT   VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_book_type_code fa_book_controls.book_type_code%TYPE;  -- ���Y�䒠��
    lt_fiscal_year    fa_deprn_periods.fiscal_year%TYPE;     -- ��v�N�x
    lt_period_from    fa_deprn_periods.period_name%TYPE;     -- �o�͊��ԁi���j
    lt_period_to      fa_deprn_periods.period_name%TYPE;     -- �o�͊��ԁi���j
    lt_period_num_1st fa_deprn_periods.period_num%TYPE;      -- ������Ԕԍ�
    lt_period_num_now fa_deprn_periods.period_num%TYPE;      -- �������Ԕԍ�
    ld_start_date_1st DATE;                                  -- ����J�n��
    ld_start_date_now DATE;                                  -- �����J�n��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--    CURSOR <cursor_name>_cur
--    IS
--      SELECT
--      FROM
--      WHERE
--    -- <�J�[�\����>���R�[�h�^
--    <cursor_name>_rec <cursor_name>_cur%ROWTYPE;
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
    -- ============================================
    -- A-1�D���̓p�����[�^�l���O�o�͏���
    -- ============================================
    init(
       lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
    -- ���[�X��Ђƃ��[�X��ʂ�NULL�̏ꍇ
    IF (  iv_lease_company IS NULL
      AND iv_lease_class   IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              cv_appl_short_name
                                             ,cv_msg_req_chk       -- �K�{�`�F�b�N�G���[
                                             ,cv_tkn_input_dta
                                             ,cv_tkv_com_or_cla    -- ���[�X��ЁA���[�X���
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
    -- ============================================
    -- A-2�D��v���ԃ`�F�b�N����
    -- ============================================
    chk_period_name(
       iv_period_name         -- 1.��v���Ԗ�
      ,iv_lease_kind          -- 2.���[�X���
      ,iv_book_class          -- 3.���Y�䒠�敪
      ,lt_fiscal_year         -- 4.��v�N�x
      ,lt_period_to           -- 5.�o�͊��ԁi���j
      ,lt_period_num_now      -- 6.���Ԕԍ�
      ,ld_start_date_now      -- 7.�����J�n��
      ,lt_book_type_code      -- 8.���Y�䒠��
      ,lv_errbuf              --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D��v���Ԋ���擾����
    -- ============================================
    get_first_period(
       iv_lease_kind          -- 1.���[�X���
      ,lt_fiscal_year         -- 2.��v�N�x
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,lt_book_type_code      -- 3.���Y�䒠��
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lt_period_from         -- 4.�o�͊��ԁi���j
      ,lt_period_num_1st      -- 5.���Ԕԍ�
      ,ld_start_date_1st      -- 6.����J�n��
      ,lv_errbuf              --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode != cv_status_normal) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D���[�X�_����擾����
    -- ============================================
    get_contract_info(
       iv_lease_company     --  1.���[�X���
      ,iv_lease_kind        --  2.���[�X���
      ,ld_start_date_1st    --  3.����J�n��
      ,ld_start_date_now    --  4.�����J�n��
      ,lt_book_type_code    --  5.���Y�䒠��
      ,lt_fiscal_year       --  6.��v�N�x
      ,lt_period_num_1st    --  7.������Ԕԍ�
      ,lt_period_num_now    --  8.�������Ԕԍ�
      ,lt_period_from       --  9.�o�͊��ԁi���j
      ,lt_period_to         -- 10.�o�͊��ԁi���j
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,iv_lease_class       -- 11.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lv_errbuf            --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
    errbuf           OUT   VARCHAR2,        --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode          OUT   VARCHAR2,        --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name   IN    VARCHAR2,        -- 1.��v���Ԗ�
    iv_lease_kind    IN    VARCHAR2,        -- 2.���[�X���
    iv_book_class    IN    VARCHAR2,        -- 3.���Y�䒠�敪
-- 2018/03/27 Ver.1.7 Y.Shoji MOD Start
--    iv_lease_company IN    VARCHAR2         -- 4.���[�X��ЃR�[�h
    iv_lease_company IN    VARCHAR2,        -- 4.���[�X��ЃR�[�h
    iv_lease_class   IN    VARCHAR2         -- 5.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji MOD End
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
      ,iv_which   => cv_which
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
       iv_period_name   -- 1.��v���Ԗ�
      ,iv_lease_kind    -- 2.���[�X���
      ,iv_book_class    -- 3.���Y�䒠�敪
      ,iv_lease_company -- 4.���[�X��ЃR�[�h
-- 2018/03/27 Ver.1.7 Y.Shoji ADD Start
      ,iv_lease_class   -- 5.���[�X���
-- 2018/03/27 Ver.1.7 Y.Shoji ADD End
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ============================================
    -- A-7�D�I������
    -- ============================================
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
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
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
END XXCFF011A17C;
/
