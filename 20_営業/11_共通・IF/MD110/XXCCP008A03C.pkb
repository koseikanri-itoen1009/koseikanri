CREATE OR REPLACE PACKAGE BODY APPS.XXCCP008A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A03C(body)
 * Description      : ���[�X�x���v��f�[�^CSV�o��
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
 *  2012/10/05    1.00  SCSK ������a    �V�K�쐬
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A03C';   -- �p�b�P�[�W��
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
    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- ��؂蕶��
    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- �P��͂ݕ���
    cv_con_sts_cont         CONSTANT  VARCHAR2(3)   := '202';                         -- �_��X�e�[�^�X�F�_��
    cv_con_sts_re_lease     CONSTANT  VARCHAR2(3)   := '203';                         -- �_��X�e�[�^�X�F�ă��[�X
    cv_date_format          CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';       --YYYYMMDDHHMISS�^
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================================
    -- ���[�J����O����
    -- ===============================================
    err_prm_expt             EXCEPTION;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- �x���v�� �擾�J�[�\��  �p�����[�^.�_��ԍ����w��L��
    CURSOR l_xpay_plan_rec_cur
    IS
      SELECT xppl.contract_line_id                --  ���[�X�x���v��.�_�񖾍ד���ID
      ,      xppl.payment_frequency               --  ���[�X�x���v��.�x����
      ,      xppl.contract_header_id              --  ���[�X�x���v��.�_�����ID
      ,      xppl.period_name                     --  ���[�X�x���v��.��v����
      ,      TO_CHAR( xppl.payment_date , cv_date_format ) AS payment_date
                                                  --  ���[�X�x���v��.�x����
      ,      xppl.lease_charge                    --  ���[�X�x���v��.���[�X��
      ,      xppl.lease_tax_charge                --  ���[�X�x���v��.���[�X��_�����
      ,      xppl.lease_deduction                 --  ���[�X�x���v��.���[�X�T���z
      ,      xppl.lease_tax_deduction             --  ���[�X�x���v��.���[�X�T���z_�����
      ,      xppl.op_charge                       --  ���[�X�x���v��.�n�o���[�X��
      ,      xppl.op_tax_charge                   --  ���[�X�x���v��.�n�o���[�X���z_�����
      ,      xppl.fin_debt                        --  ���[�X�x���v��.�e�h�m���[�X���z
      ,      xppl.fin_tax_debt                    --  ���[�X�x���v��.�e�h�m���[�X���z_�����
      ,      xppl.fin_interest_due                --  ���[�X�x���v��.�e�h�m���[�X�x������
      ,      xppl.fin_debt_rem                    --  ���[�X�x���v��.�e�h�m���[�X���c
      ,      xppl.fin_tax_debt_rem                --  ���[�X�x���v��.�e�h�m���[�X���c_�����
      ,      xppl.accounting_if_flag              --  ���[�X�x���v��.��v�h�e�t���O
      ,      xppl.payment_match_flag              --  ���[�X�x���v��.�ƍ��σt���O
      ,      xppl.created_by                      --  ���[�X�x���v��.�쐬��
      ,      TO_CHAR( xppl.creation_date , cv_date_format ) AS creation_date
                                                  --  ���[�X�x���v��.�쐬��
      ,      xppl.last_updated_by                 --  ���[�X�x���v��.�ŏI�X�V��
      ,      TO_CHAR( xppl.last_update_date , cv_date_format ) AS last_update_date
                                                  --  ���[�X�x���v��.�ŏI�X�V��
      ,      xppl.last_update_login               --  ���[�X�x���v��.�ŏI�X�V���O�C��
      ,      xppl.request_id                      --  ���[�X�x���v��.�v��ID
      ,      xppl.program_application_id          --  ���[�X�x���v��.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,      xppl.program_id                      --  ���[�X�x���v��.�R���J�����g�E�v���O����ID
      ,      TO_CHAR( xppl.program_update_date , cv_date_format ) AS program_update_date
                                                  --  ���[�X�x���v��.�v���O�����X�V��
        FROM xxcff_contract_headers xconhe        --  ���[�X�_��w�b�_
           , xxcff_contract_lines   xconli        --  ���[�X�_�񖾍�
           , xxcff_object_headers   xobjh         --  ���[�X����
           , xxcff_pay_planning     xppl          --  ���[�X�x���v��
           , ( -- �e�_�񖈂̍ő�ă��[�X��
               SELECT c_head.contract_number          AS contract_number
                    , c_head.lease_company            AS lease_company
                    , MAX(c_head.re_lease_times)      AS re_lease_times
                 FROM xxcff_contract_headers   c_head      -- ���[�X�_��w�b�_
                WHERE c_head.contract_number = gv_contract_number
                GROUP BY c_head.contract_number , c_head.lease_company
             ) c_head_max
       WHERE
             -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
             xconhe.contract_header_id = xconli.contract_header_id
             -- ���[�X�_��w�b�_.�_�����ID = ���[�X�x���v��.�_�����ID
         AND xconhe.contract_header_id = xppl.contract_header_id
             -- ���[�X�_�񖾍�.�_�񖾍ד���ID = ���[�X�x���v��.�_�񖾍ד���ID
         AND xconli.contract_line_id = xppl.contract_line_id
             -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
         AND xconli.object_header_id = xobjh.object_header_id
             --  ���[�X�_��w�b�_.�ă��[�X�񐔂��ő�
         AND xconhe.contract_number = c_head_max.contract_number
         AND xconhe.lease_company   = c_head_max.lease_company
         AND xconhe.re_lease_times  = c_head_max.re_lease_times
             -- ���[�X�_��w�b�_.�_��ԍ� = :�p�����[�^�_��ԍ�
         AND xconhe.contract_number = gv_contract_number
             -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^���[�X���
         AND ( gv_lease_company IS NULL
             OR
               xconhe.lease_company = gv_lease_company
             )
             -- �����R�[�h�̎w�肪����ꍇ�́A�����ꂩ�ɍ��v�������
         AND (
               gv_obj_code_param = cv_obj_code_param_off
             OR
               (
                 gv_obj_code_param = cv_obj_code_param_on
                 AND
                 -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
                 xobjh.object_code in ( gv_object_code_01
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
         -- ���[�X�_��w�b�_.�_��ԍ� , ���[�X����.�����R�[�h , ���[�X�x���v��.�x����
       ORDER BY xconhe.contract_number
              , xobjh.object_code
              , xppl.payment_frequency
    ;
    -- �x���v�� �擾�J�[�\��  �p�����[�^.�_��ԍ������w��
    CURSOR l_no_xpay_plan_rec_cur
    IS
      SELECT xppl.contract_line_id                --  ���[�X�x���v��.�_�񖾍ד���ID
      ,      xppl.payment_frequency               --  ���[�X�x���v��.�x����
      ,      xppl.contract_header_id              --  ���[�X�x���v��.�_�����ID
      ,      xppl.period_name                     --  ���[�X�x���v��.��v����
      ,      TO_CHAR( xppl.payment_date , cv_date_format ) AS payment_date
                                                  --  ���[�X�x���v��.�x����
      ,      xppl.lease_charge                    --  ���[�X�x���v��.���[�X��
      ,      xppl.lease_tax_charge                --  ���[�X�x���v��.���[�X��_�����
      ,      xppl.lease_deduction                 --  ���[�X�x���v��.���[�X�T���z
      ,      xppl.lease_tax_deduction             --  ���[�X�x���v��.���[�X�T���z_�����
      ,      xppl.op_charge                       --  ���[�X�x���v��.�n�o���[�X��
      ,      xppl.op_tax_charge                   --  ���[�X�x���v��.�n�o���[�X���z_�����
      ,      xppl.fin_debt                        --  ���[�X�x���v��.�e�h�m���[�X���z
      ,      xppl.fin_tax_debt                    --  ���[�X�x���v��.�e�h�m���[�X���z_�����
      ,      xppl.fin_interest_due                --  ���[�X�x���v��.�e�h�m���[�X�x������
      ,      xppl.fin_debt_rem                    --  ���[�X�x���v��.�e�h�m���[�X���c
      ,      xppl.fin_tax_debt_rem                --  ���[�X�x���v��.�e�h�m���[�X���c_�����
      ,      xppl.accounting_if_flag              --  ���[�X�x���v��.��v�h�e�t���O
      ,      xppl.payment_match_flag              --  ���[�X�x���v��.�ƍ��σt���O
      ,      xppl.created_by                      --  ���[�X�x���v��.�쐬��
      ,      TO_CHAR( xppl.creation_date , cv_date_format ) AS creation_date
                                                  --  ���[�X�x���v��.�쐬��
      ,      xppl.last_updated_by                 --  ���[�X�x���v��.�ŏI�X�V��
      ,      TO_CHAR( xppl.last_update_date , cv_date_format ) AS last_update_date
                                                  --  ���[�X�x���v��.�ŏI�X�V��
      ,      xppl.last_update_login               --  ���[�X�x���v��.�ŏI�X�V���O�C��
      ,      xppl.request_id                      --  ���[�X�x���v��.�v��ID
      ,      xppl.program_application_id          --  ���[�X�x���v��.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,      xppl.program_id                      --  ���[�X�x���v��.�R���J�����g�E�v���O����ID
      ,      TO_CHAR( xppl.program_update_date , cv_date_format ) AS program_update_date
                                                  --  ���[�X�x���v��.�v���O�����X�V��
        FROM xxcff_contract_headers xconhe        --  ���[�X�_��w�b�_
           , xxcff_contract_lines   xconli        --  ���[�X�_�񖾍�
           , xxcff_object_headers   xobjh         --  ���[�X����
           , xxcff_pay_planning     xppl          --  ���[�X�x���v��
       WHERE
             -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
             xconhe.contract_header_id = xconli.contract_header_id
             -- ���[�X�_��w�b�_.�_�����ID = ���[�X�x���v��.�_�����ID
         AND xconhe.contract_header_id = xppl.contract_header_id
             -- ���[�X�_�񖾍�.�_�񖾍ד���ID = ���[�X�x���v��.�_�񖾍ד���ID
         AND xconli.contract_line_id = xppl.contract_line_id
             -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
         AND xconli.object_header_id = xobjh.object_header_id
             -- ���[�X�_��w�b�_.�ă��[�X�� = ���[�X����.�ă��[�X��
         AND xconhe.re_lease_times = xobjh.re_lease_times
             -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^���[�X���
         AND ( gv_lease_company IS NULL
             OR
               xconhe.lease_company = gv_lease_company
             )
         AND -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
             xobjh.object_code in ( gv_object_code_01
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
         -- ���[�X�_��w�b�_.�_��ԍ� , ���[�X����.�����R�[�h , ���[�X�x���v��.�x����
       ORDER BY xconhe.contract_number
              , xobjh.object_code
              , xppl.payment_frequency
    ;
    TYPE l_xpay_plan_rec_ttype IS TABLE OF l_xpay_plan_rec_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_xpay_plan_rec_tab l_xpay_plan_rec_ttype;
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
    -- ���̓p�����[�^�`�F�b�N
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
    -- ���[�X�x���v�� ���o����
    -- ===============================================
    -- ���[�X�x���v����擾�J�[�\��
    IF gv_contract_number IS NULL THEN
       -- �p�����[�^.�_��ԍ������w��
      OPEN l_no_xpay_plan_rec_cur;
      FETCH l_no_xpay_plan_rec_cur BULK COLLECT INTO l_xpay_plan_rec_tab;
      CLOSE l_no_xpay_plan_rec_cur;
    ELSE
       -- �p�����[�^.�_��ԍ����w��L��
      OPEN l_xpay_plan_rec_cur;
      FETCH l_xpay_plan_rec_cur BULK COLLECT INTO l_xpay_plan_rec_tab;
      CLOSE l_xpay_plan_rec_cur;
    END IF;
    --���������J�E���g
    gn_target_cnt := l_xpay_plan_rec_tab.COUNT;
--
    -- ���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"���[�X�x���v��"'
    );
    -- ���ږ�
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '�_�񖾍ד���ID'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '�x����'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�_�����ID'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '��v����'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�x����'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X��'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X��_�����'                          || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�T���z'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�T���z_�����'                      || cv_enclosed
         || cv_delimit || cv_enclosed || '�n�o���[�X��'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '�n�o���[�X���z_�����'                    || cv_enclosed
         || cv_delimit || cv_enclosed || '�e�h�m���[�X���z'                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�e�h�m���[�X���z_�����'                || cv_enclosed
         || cv_delimit || cv_enclosed || '�e�h�m���[�X�x������'                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�e�h�m���[�X���c'                       || cv_enclosed
         || cv_delimit || cv_enclosed || '�e�h�m���[�X���c_�����'                || cv_enclosed
         || cv_delimit || cv_enclosed || '��v�h�e�t���O'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '�ƍ��σt���O'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V���O�C��'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�v��ID'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O�����A�v���P�[�V����ID' || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O����ID'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�v���O�����X�V��'                         || cv_enclosed
    );
--
    <<lines_loop>>
    FOR i IN 1 .. l_xpay_plan_rec_tab.COUNT LOOP
        -- ���ڒl
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_xpay_plan_rec_tab( i ).contract_line_id       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_frequency      || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).contract_header_id     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).period_name            || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_date           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_tax_charge       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).lease_tax_deduction    || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).op_charge              || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).op_tax_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_debt               || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_tax_debt           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_interest_due       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_debt_rem           || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).fin_tax_debt_rem       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).accounting_if_flag     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).payment_match_flag     || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).created_by             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).creation_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_updated_by        || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_update_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).last_update_login      || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).request_id             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_application_id || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_id             || cv_enclosed
             || cv_delimit || cv_enclosed || l_xpay_plan_rec_tab( i ).program_update_date    || cv_enclosed
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
  EXCEPTION
    -- *** ���̓p�����[�^��O�n���h�� ***
    WHEN err_prm_expt THEN
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
END XXCCP008A03C;
/
