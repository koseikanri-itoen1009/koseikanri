CREATE OR REPLACE PACKAGE BODY XXCFF014A21C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF014A21C(body)
 * Description      : �ʕ\16(4)���[�X���Y
 * MD.050           : �ʕ\16(4)���[�X���Y MD050_CFF_014_A21
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���̓p�����[�^�l���O�o�͏���(A-1)
 *  get_period_name        ��v���ԏ��擾����(A-2)
 *  get_first_period       ��v���Ԋ���擾����(A-3)
 *  get_contract_info      ���[�X�_����擾����(A-4)
 *  get_pay_planning       ���[�X�x���v����擾����(A-5)
 *  out_csv_data           CSV�f�[�^�o�͏���(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   SCS�R��          �V�K�쐬
 *  2009/02/26    1.1   SCS�R��          [��QCFF_064] ��񎞎��Y�뉿�̕s��Ή�
 *  2009/07/17    1.2   SCS����          [�����e�X�g��Q0000417] �x���v��̓����x�����[�X���擾�����C��
 *  2009/07/31    1.3   SCS�n��          [�����e�X�g��Q0000417(�ǉ�)]
 *                                         �E�擾���z�A�������p�݌v�z�̎擾�������C��
 *                                         �E�x�����������z�A�����x�����[�X���i�T���z�j�̎擾�����C��
 *                                         �E���o�߃��[�X�����c�������z�A���o�߃��[�X����Ŋz�A
 *                                           ��񎞃��[�X���c���̎擾���@�C��
 *  2009/08/28    1.4   SCS �n��         [�����e�X�g��Q0001062(PT�Ή�)]
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
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF014A21C'; -- �p�b�P�[�W��
  cv_appl_short_name  CONSTANT VARCHAR2(100) := 'XXCFF';        -- �A�v���P�[�V�����Z�k��
  cv_which            CONSTANT VARCHAR2(100) := 'LOG';          -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W
  cv_msg_no_data      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; -- �Ώۃf�[�^����
  -- ���[�X���
  cv_lease_kind_fin   CONSTANT VARCHAR2(1)   := '0';  -- Fin���[�X
  cv_lease_kind_op    CONSTANT VARCHAR2(1)   := '1';  -- Op���[�X
  cv_lease_kind_qfin  CONSTANT VARCHAR2(1)   := '2';  -- ��Fin���[�X
-- 0000417 2009/07/31 ADD START --
  -- �����p�X�e�[�^�X
  cv_processed        CONSTANT VARCHAR2(9)   := 'PROCESSED'; --������
  -- ��vIF�t���O�X�e�[�^�X
  cv_if_aft           CONSTANT VARCHAR2(1)   := '2'; --�A�g��
  -- �ƍ��σt���O
  cv_match   CONSTANT VARCHAR2(1)            := '1'; --�ƍ���
-- 0000417 2009/07/31 ADD END --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_csv_rtype IS RECORD (
     contract_header_id      xxcff_contract_headers.contract_header_id%TYPE
    ,contract_line_id        xxcff_contract_lines.contract_line_id%TYPE
    ,lease_company           xxcff_contract_headers.lease_company%TYPE -- ���[�X��ЃR�[�h
    ,lease_company_name      VARCHAR2(240) -- ���[�X��Ж�
    ,period_from             VARCHAR2(10) -- �o�͊��ԁi���j
    ,period_to               VARCHAR2(10) -- �o�͊��ԁi���j
    ,contract_number         xxcff_contract_headers.contract_number%TYPE -- �_��No
    ,contract_line_num       xxcff_contract_lines.contract_line_num%TYPE -- �_�񖾍�No
    ,object_code             xxcff_object_headers.object_code%TYPE       -- �����R�[�h
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
    ,original_cost           NUMBER(15) -- �擾���z�����z
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
    ,deprn_reserve           NUMBER(15) -- �������p�݌v�z�����z 
    ,bal_amount              NUMBER(15) -- �����c�������z
    ,interest_amount         NUMBER(15) -- �x�����������z
    ,deprn_amount            NUMBER(15) -- �������p�����z
    ,monthly_deduction       NUMBER(15) -- ���ԃ��[�X���i�T���z�j
    ,gross_deduction         NUMBER(15) -- ���[�X�����z�i�T���z�j
    ,deduction_this_month    NUMBER(15) -- �����x�����[�X���i�T���z�j
    ,deduction_future        NUMBER(15) -- ���o�߃��[�X���i�T���z�j
    ,deduction_1year         NUMBER(15) -- 1�N�ȓ����o�߃��[�X���i�T���z�j
    ,deduction_over_1year    NUMBER(15) -- 1�N�z���o�߃��[�X���i�T���z�j
    ,cancellation_date       xxcff_contract_lines.cancellation_date%TYPE -- ����
    ,cxl_amount              NUMBER(15) -- ��񎞎��Y�뉿
    ,cxl_debt_bal            NUMBER(15) -- ��񎞃��[�X���c��
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : CSV�f�[�^�o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    io_csv_rec    IN OUT g_csv_rtype,  -- 1.CSV�o�̓��R�[�h
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
         AND flv.attribute2 = cv_flag_y
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
    -- ��񎞎��Y�뉿
    IF io_csv_rec.cancellation_date IS NULL THEN
      io_csv_rec.cxl_amount := 0;
    END IF;
    -- CSV�f�[�^�ҏW
    lv_csv_row := 
      cv_double_quat || io_csv_rec.lease_company         || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_company_name    || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.period_from           || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.period_to             || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.contract_number       || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.contract_line_num)      || cv_sep_part ||
      cv_double_quat || io_csv_rec.object_code           || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_class_name      || cv_double_quat || cv_sep_part ||
      cv_double_quat || io_csv_rec.lease_type_name       || cv_double_quat || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.lease_start_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.lease_end_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.payment_frequency)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.monthly_charge)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.gross_charge)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_this_month)|| cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_future)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_1year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_over_1year)|| cv_sep_part ||
      TO_CHAR(io_csv_rec.original_cost)          || cv_sep_part ||
      TO_CHAR(io_csv_rec.lease_charge_debt)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_future)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_future)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_1year)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_1year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_1year)              || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_over_1year)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_over_1year)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_over_1year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_1to2year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_1to2year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_1to2year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_2to3year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_2to3year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_2to3year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_3to4year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_3to4year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_3to4year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_4to5year)     || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_4to5year)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_4to5year)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.principal_over_5year)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_over_5year)    || cv_sep_part ||
      TO_CHAR(io_csv_rec.tax_over_5year)         || cv_sep_part ||
      TO_CHAR(io_csv_rec.deprn_reserve)          || cv_sep_part ||
      TO_CHAR(io_csv_rec.bal_amount)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.interest_amount)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deprn_amount)           || cv_sep_part ||
      TO_CHAR(io_csv_rec.monthly_deduction)      || cv_sep_part ||
      TO_CHAR(io_csv_rec.gross_deduction)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_this_month)   || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_future)       || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_1year)        || cv_sep_part ||
      TO_CHAR(io_csv_rec.deduction_over_1year)   || cv_sep_part ||
      cv_double_quat || TO_CHAR(io_csv_rec.cancellation_date,'YYYY/MM/DD') || cv_double_quat || cv_sep_part ||
      TO_CHAR(io_csv_rec.cxl_amount)             || cv_sep_part ||
      TO_CHAR(io_csv_rec.cxl_debt_bal)
      ;
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
      SELECT xpp.contract_header_id
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
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(id_start_date_now,'YYYY-MM') THEN
--                   xpp.fin_debt_rem
--                 ELSE 0 END) AS lease_charge_debt         -- ���o�߃��[�X�����c�������z
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS lease_charge_debt         -- ���o�߃��[�X�����c�������z
-- 0000417 2009/07/31 MOD END --
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_future           -- ���o�߃��[�X�x�������z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(id_start_date_now,'YYYY-MM') THEN
--                   xpp.fin_tax_debt_rem
--                 ELSE 0 END) AS tax_future                -- ���o�߃��[�X����Ŋz
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_future                -- ���o�߃��[�X����Ŋz
-- 0000417 2009/07/31 MOD END --
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1year           -- 1�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1year            -- 1�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(id_start_date_now,'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1year                 -- 1�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_1year      -- 1�N�z���{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_interest_due
                 ELSE 0 END) AS interest_over_1year       -- 1�N�z�x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   xpp.fin_tax_debt
                 ELSE 0 END) AS tax_over_1year            -- 1�N�z�����
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_1to2year        -- 1�N��2�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_1to2year         -- 1�N��2�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,12),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_1to2year              -- 1�N��2�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_2to3year        -- 2�N��3�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_2to3year         -- 2�N��3�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,24),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_2to3year              -- 2�N��3�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_3to4year        -- 3�N��4�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_3to4year         -- 3�N��4�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,36),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_3to4year              -- 3�N��4�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_debt
                    ELSE 0 END)
                 ELSE 0 END) AS principal_4to5year        -- 4�N��5�N�ȓ����{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_interest_due
                    ELSE 0 END)
                 ELSE 0 END) AS interest_4to5year         -- 4�N��5�N�ȓ��x������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,48),'YYYY-MM') THEN
                   (CASE WHEN xpp.period_name <= TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                      xpp.fin_tax_debt
                    ELSE 0 END)
                 ELSE 0 END) AS tax_4to5year              -- 4�N��5�N�ȓ������
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_debt
                 ELSE 0 END) AS principal_over_5year      -- 5�N�z���{
            ,SUM(CASE WHEN xpp.period_name > TO_CHAR(ADD_MONTHS(id_start_date_now,60),'YYYY-MM') THEN
                   xpp.fin_interest_due
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
                         xpp.fin_interest_due
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
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(ADD_MONTHS(io_csv_rec.cancellation_date,-1),'YYYY-MM') THEN
--                   xpp.fin_debt_rem
--                 ELSE 0 END) AS cxl_debt_bal              -- ��񎞃��[�X���c��
            ,SUM(CASE WHEN xpp.period_name = TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') THEN
                   (CASE WHEN xpp.payment_match_flag = cv_match THEN
                      xpp.fin_debt_rem
                    ELSE
                      xpp.fin_debt_rem + xpp.fin_debt
                    END)
                 ELSE 0 END) AS cxl_debt_bal              -- ��񎞃��[�X���c��
-- 0000417 2009/07/31 MOD END --
        FROM xxcff_pay_planning xpp
       WHERE xpp.contract_line_id = io_csv_rec.contract_line_id
         AND xpp.contract_header_id = io_csv_rec.contract_header_id
-- 0000417 2009/07/17 MOD START --
--         AND NOT (xpp.period_name >= TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') AND
         AND NOT (xpp.period_name > TO_CHAR(io_csv_rec.cancellation_date,'YYYY-MM') AND
-- 0000417 2009/07/17 MOD END --
                  io_csv_rec.cancellation_date IS NOT NULL)
      GROUP BY xpp.contract_header_id
              ,xpp.contract_line_id
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
      io_csv_rec.cxl_debt_bal            := l_rec.cxl_debt_bal;            -- ��񎞃��[�X���c��
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
    iv_book_type_code  IN  VARCHAR2,  --  1.���Y�䒠��
    id_start_date_1st  IN  DATE,      --  2.����J�n��
    id_start_date_now  IN  DATE,      --  3.�����J�n��
    in_fiscal_year     IN  NUMBER,    --  4.��v�N�x
    in_period_num_1st  IN  NUMBER,    --  5.������Ԕԍ�
    in_period_num_now  IN  NUMBER,    --  6.�������Ԕԍ�
    iv_period_from     IN  VARCHAR2,  --  7.�o�͊��ԁi���j
    iv_period_to       IN  VARCHAR2,  --  8.�o�͊��ԁi���j
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
    cd_contract_date_fr CONSTANT DATE   := TO_DATE('2008/04/01','YYYY/MM/DD');
    cd_contract_date_to CONSTANT DATE   := TO_DATE('2008/05/01','YYYY/MM/DD');
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
-- 0000417 2009/08/06 DEL START --
/*
    CURSOR contract_cur
    IS
      SELECT xch.contract_header_id             -- �_�����ID
            ,xcl.contract_line_id               -- �_�񖾍ד���ID
            ,xch.lease_company                  -- ���[�X��ЃR�[�h
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,xcl.contract_line_num              -- �_�񖾍�No
            ,xoh.object_code                    -- �����R�[�h
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
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD END --
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- �擾���z���z
-- 0000417 2009/07/31 MOD START --
--            ,SUM(CASE WHEN xcl.cancellation_date IS NULL THEN
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
-- 0000417 2009/07/31 MOD END --
-- 0000417 2009/07/31 MOD START --
--                      fds.deprn_reserve
                      NVL(fds.deprn_reserve,xcl.original_cost)
-- 0000417 2009/07/31 MOD END --
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_from) >= iv_period_from THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) <= iv_period_to THEN
                      fds.deprn_amount
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_amount    -- �������p�����z
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.second_deduction
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
            ,xcl.cancellation_date              -- ���r����
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.original_cost
                 ELSE 0 END) - SUM(fds.deprn_amount) AS cxl_amount -- ��񎞎��Y�뉿
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
       INNER JOIN xxcff_object_headers xoh    -- ���[�X����
          ON xcl.object_header_id = xoh.object_header_id
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
       WHERE xch.lease_type = cv_lease_type1
         AND xcl.lease_kind = cv_lease_kind_qfin
         AND xch.contract_date >= cd_contract_date_fr
         AND xch.contract_date <  cd_contract_date_to
         AND xcl.contract_line_id = fab.attribute10
         AND fdp.period_name <= iv_period_to
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xoh.object_code
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xcl.cancellation_date
              ,xch.contract_header_id
              ,xcl.contract_line_id
      ORDER BY xcl.cancellation_date DESC
              ,xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xch.lease_start_date
      ;
*/
-- 0000417 2009/08/06 DEL END --
--
-- 0000417 2009/08/06 ADD START --
    CURSOR contract_cur
    IS
      SELECT 
-- 0001062 2009/08/28 ADD START --
            /*+
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              INDEX(FDP FA_DEPRN_PERIODS_U2)
              INDEX(FDS FA_DEPRN_SUMMARY_U1)
              INDEX(FRET FA_RETIREMENTS_N1)
            */
-- 0001062 2009/08/28 ADD END --
             xch.contract_header_id             -- �_�����ID
            ,xcl.contract_line_id               -- �_�񖾍ד���ID
            ,xch.lease_company                  -- ���[�X��ЃR�[�h
            ,(SELECT xlcv.lease_company_name
                FROM xxcff_lease_company_v xlcv
               WHERE xlcv.lease_company_code = xch.lease_company
              ) AS lease_company_name           -- ���[�X���
            ,xch.contract_number                -- �_��No
            ,xcl.contract_line_num              -- �_�񖾍�No
            ,xoh.object_code                    -- �����R�[�h
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
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_charge
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_charge  -- ���ԃ��[�X��
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.gross_charge
                    ELSE 0 END)
                 ELSE 0 END) AS gross_charge    -- ���[�X�����z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.original_cost
                    ELSE 0 END)
                 ELSE 0 END) AS original_cost   -- �擾���z���z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      NVL(fds.deprn_reserve,original_cost)
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_reserve   -- �������p�݌v�z�����z
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_from) >= iv_period_from THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) <= iv_period_to THEN
                      fds.deprn_amount
                    ELSE 0 END)
                 ELSE 0 END) AS deprn_amount    -- �������p�����z
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                      xcl.second_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS monthly_deduction -- ���ԃ��[�X���i�T���z�j
            ,SUM(CASE WHEN fret.retirement_id IS NULL OR
                           fret.status <> cv_processed   THEN
                   (CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.gross_deduction
                    ELSE 0 END)
                 ELSE 0 END) AS gross_deduction -- ���[�X�����z�i�T���z�j
            ,xcl.cancellation_date              -- ���r����
            ,SUM(CASE WHEN NVL(fdp.period_name,iv_period_to) = iv_period_to THEN
                   xcl.original_cost
                 ELSE 0 END) - SUM(fds.deprn_amount) AS cxl_amount -- ��񎞎��Y�뉿
        FROM xxcff_contract_headers xch       -- ���[�X�_��
       INNER JOIN xxcff_contract_lines xcl    -- ���[�X�_�񖾍�
          ON xcl.contract_header_id = xch.contract_header_id
-- 0001062 2009/08/28 ADD START --
         AND xcl.lease_kind         = cv_lease_kind_qfin
-- 0001062 2009/08/28 ADD END --
       INNER JOIN xxcff_object_headers xoh    -- ���[�X����
          ON xcl.object_header_id = xoh.object_header_id
       INNER JOIN fa_additions_b fab           -- ���Y�ڍ׏��
-- 0001062 2009/08/28 MOD START --
--          ON fab.attribute10 = xcl.contract_line_id
          ON fab.attribute10 = to_char(XCL.CONTRACT_LINE_ID)
-- 0001062 2009/08/28 MOD END --
       LEFT JOIN fa_retirements fret  -- �����p
          ON fret.asset_id                  = fab.asset_id
         AND fret.book_type_code            = iv_book_type_code
         AND fret.transaction_header_id_out IS NULL
       INNER JOIN fa_deprn_periods fdp         -- �������p����
          ON fdp.book_type_code = iv_book_type_code
-- 0001062 2009/08/28 ADD START --
         AND fdp.period_name <= iv_period_to
-- 0001062 2009/08/28 ADD END --
       LEFT JOIN fa_deprn_summary fds         -- �������p�T�}��
          ON fds.asset_id = fab.asset_id
         AND fds.book_type_code = fdp.book_type_code
         AND fds.period_counter = fdp.period_counter
         AND fds.deprn_source_code = 'DEPRN'
       WHERE xch.lease_type = cv_lease_type1
-- 0001062 2009/08/28 DEL START --
--         AND xcl.lease_kind = cv_lease_kind_qfin
-- 0001062 2009/08/28 DEL END --
         AND xch.contract_date >= cd_contract_date_fr
         AND xch.contract_date <  cd_contract_date_to
-- 0001062 2009/08/28 DEL START --
--         AND xcl.contract_line_id = fab.attribute10
--         AND fdp.period_name <= iv_period_to
-- 0001062 2009/08/28 DEL END --
      GROUP BY xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xoh.object_code
              ,xch.lease_class
              ,xch.lease_type
              ,xch.lease_start_date
              ,xch.lease_end_date
              ,xch.payment_frequency
              ,xcl.cancellation_date
              ,xch.contract_header_id
              ,xcl.contract_line_id
      ORDER BY xcl.cancellation_date DESC
              ,xch.lease_company
              ,xch.contract_number
              ,xcl.contract_line_num
              ,xch.lease_start_date
      ;
-- 0000417 2009/08/06 ADD START --
--
    contract_rec contract_cur%ROWTYPE;
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
    OPEN contract_cur;
    <<main_loop>>
    LOOP
      FETCH contract_cur INTO contract_rec;
      EXIT WHEN contract_cur%NOTFOUND;
      -- �Ώی����C���N�������g
      gn_target_cnt := gn_target_cnt + 1;
      -- ������
      l_csv_rec := NULL;
      -- �擾�l���i�[
      l_csv_rec.contract_header_id  := contract_rec.contract_header_id;
      l_csv_rec.contract_line_id    := contract_rec.contract_line_id;
      l_csv_rec.lease_company       := contract_rec.lease_company;
      l_csv_rec.lease_company_name  := contract_rec.lease_company_name;
      l_csv_rec.period_from         := iv_period_from;
      l_csv_rec.period_to           := iv_period_to;
      l_csv_rec.contract_number     := contract_rec.contract_number;
      l_csv_rec.contract_line_num   := contract_rec.contract_line_num;
      l_csv_rec.object_code         := contract_rec.object_code;
      l_csv_rec.lease_class_name    := contract_rec.lease_class_name;
      l_csv_rec.lease_type_name     := contract_rec.lease_type_name;
      l_csv_rec.lease_start_date    := contract_rec.lease_start_date;
      l_csv_rec.lease_end_date      := contract_rec.lease_end_date;
      l_csv_rec.payment_frequency   := contract_rec.payment_frequency;
      l_csv_rec.monthly_charge      := contract_rec.monthly_charge;
      l_csv_rec.gross_charge        := contract_rec.gross_charge;
      l_csv_rec.original_cost       := contract_rec.original_cost;
      l_csv_rec.deprn_reserve       := contract_rec.deprn_reserve;
      l_csv_rec.deprn_amount        := contract_rec.deprn_amount;
      l_csv_rec.monthly_deduction   := contract_rec.monthly_deduction;
      l_csv_rec.gross_deduction     := contract_rec.gross_deduction;
      l_csv_rec.bal_amount          := contract_rec.original_cost - contract_rec.deprn_reserve;
      l_csv_rec.cancellation_date   := contract_rec.cancellation_date;
      l_csv_rec.cxl_amount          := contract_rec.cxl_amount;
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
         l_csv_rec
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg);
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      -- ���������C���N�������g
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP main_loop;
    -- �Ώی�����0���������ꍇ�͌x���I��
    IF (contract_cur%ROWCOUNT = 0) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name,cv_msg_no_data);
      ov_retcode := cv_status_warn;
    END IF;
    CLOSE contract_cur;
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
    in_fiscal_year    IN  NUMBER,       -- 1.��v�N�x
    ov_period_from    OUT VARCHAR2,     -- 2.�o�͊��ԁi���j
    on_period_num_1st OUT NUMBER,       -- 3.���Ԕԍ�
    od_start_date_1st OUT DATE,         -- 4.����J�n��
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
            ,xxcff_lease_kind_v xlk   -- ���[�X��ރr���[
       WHERE fbc.book_type_code = xlk.book_type_code
         AND xlk.lease_kind_code = cv_lease_kind_qfin
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
   * Procedure Name   : get_period_name
   * Description      : ��v���ԏ��擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_period_name(
    iv_period_name    IN  VARCHAR2,     -- 1.��v���Ԗ�
    on_fiscal_year    OUT NUMBER,       -- 2.��v�N�x
    ov_period_to      OUT VARCHAR2,     -- 3.�o�͊��ԁi���j
    on_period_num_now OUT NUMBER,       -- 4.���Ԕԍ�
    od_start_date_now OUT DATE,         -- 5.�����J�n��
    ov_book_type_code OUT VARCHAR2,     -- 6.���Y�䒠��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_name'; -- �v���O������
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
    CURSOR period_cur
    IS
      SELECT fdp.fiscal_year AS fiscal_year    -- ��v����
            ,fdp.period_name AS period_to      -- �o�͊��ԁi���j
            ,fdp.period_num  AS period_num     -- ���Ԕԍ�
            ,fcp.start_date  AS start_date_now -- �����J�n��
            ,fbc.book_type_code AS book_type_code -- ���Y�䒠��
        FROM fa_deprn_periods fdp     -- �������p����
            ,fa_calendar_periods fcp  -- ���Y�J�����_
            ,fa_book_controls fbc     -- ���Y�䒠�}�X�^
            ,xxcff_lease_kind_v xlk   -- ���[�X��ރr���[
       WHERE xlk.lease_kind_code = cv_lease_kind_qfin
         AND fdp.book_type_code = xlk.book_type_code
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
    -- �������p���ԏ��擾
    OPEN period_cur;
    FETCH period_cur INTO period_rec;
    CLOSE period_cur;
    -- �߂�l�ݒ�
    on_fiscal_year    := period_rec.fiscal_year;      -- ��v�N�x
    ov_period_to      := period_rec.period_to;        -- �o�͊��ԁi���j
    on_period_num_now := period_rec.period_num;       -- ���Ԕԍ�
    od_start_date_now := period_rec.start_date_now;   -- �����J�n��
    ov_book_type_code := period_rec.book_type_code;   -- ���Y�䒠��
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
  END get_period_name;
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
    -- ============================================
    -- A-2�D��v���ԏ��擾����
    -- ============================================
    get_period_name(
       iv_period_name         -- 1.��v���Ԗ�
      ,lt_fiscal_year         -- 2.��v�N�x
      ,lt_period_to           -- 3.�o�͊��ԁi���j
      ,lt_period_num_now      -- 4.���Ԕԍ�
      ,ld_start_date_now      -- 5.�����J�n��
      ,lt_book_type_code      -- 6.���Y�䒠��
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
       lt_fiscal_year         -- 1.��v�N�x
      ,lt_period_from         -- 2.�o�͊��ԁi���j
      ,lt_period_num_1st      -- 3.���Ԕԍ�
      ,ld_start_date_1st      -- 4.����J�n��
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
    -- A-4�D��v���Ԋ���擾����
    -- ============================================
    get_contract_info(
       lt_book_type_code    --  1.���Y�䒠��
      ,ld_start_date_1st    --  2.����J�n��
      ,ld_start_date_now    --  3.�����J�n��
      ,lt_fiscal_year       --  4.��v�N�x
      ,lt_period_num_1st    --  5.������Ԕԍ�
      ,lt_period_num_now    --  6.�������Ԕԍ�
      ,lt_period_from       --  7.�o�͊��ԁi���j
      ,lt_period_to         --  8.�o�͊��ԁi���j
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
    iv_period_name   IN    VARCHAR2         -- 1.��v���Ԗ�
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
END XXCFF014A21C;
/
