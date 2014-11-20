create or replace
PACKAGE BODY XXCCP008A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A01C(body)
 * Description      : ���[�X�_��f�[�^CSV�o��
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_csv_data           CSV�o�͂̎��s                             (A-3)
 *  chk_param              ���̓p�����[�^�`�F�b�N����                (A-2)
 *  init                   ��������                                  (A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/30    1.0   SCSK �ÎR        �V�K�쐬
 *  2013/07/05    1.1   SCSK ����        E_�{�ғ�_10871�Ή� ����ő��őΉ�
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCCP008A01C';   -- �p�b�P�[�W��
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
   * Procedure Name   : out_csv_data
   * Description      : CSV�o�͂̎��s
   **********************************************************************************/
  PROCEDURE out_csv_data(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- �v���O������
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
    cv_date_ymdhms          CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';       --YYYYMMDDHHMISS�^
    cv_date_ymd             CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD';                  --YYYYMMDD�^
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- �_���� �擾�J�[�\��(�p�����[�^.�_��ԍ��w��L��)
    CURSOR l_contract_rec_cur
    IS
      SELECT
         xch.contract_header_id                             AS  h_contract_header_id        -- �w�b�_.�_�����ID
        ,xch.contract_number                                AS  contract_number             -- �w�b�_.�_��ԍ�
        ,xch.lease_class                                    AS  lease_class                 -- �w�b�_.���[�X���
        ,xch.lease_type                                     AS  lease_type                  -- �w�b�_.���[�X�敪
        ,xch.lease_company                                  AS  lease_company               -- �w�b�_.���[�X���
        ,xch.re_lease_times                                 AS  re_lease_times              -- �w�b�_.�ă��[�X��
        ,xch.comments                                       AS  comments                    -- �w�b�_.����
        ,TO_CHAR( xch.contract_date, cv_date_ymd )          AS  contract_date               -- �w�b�_.���[�X�_���
        ,xch.payment_frequency                              AS  payment_frequency           -- �w�b�_.�x����
        ,xch.payment_type                                   AS  payment_type                -- �w�b�_.�p�x
        ,xch.payment_years                                  AS  payment_years               -- �w�b�_.�N��
        ,TO_CHAR( xch.lease_start_date, cv_date_ymd )       AS  lease_start_date            -- �w�b�_.���[�X�J�n��
        ,TO_CHAR( xch.lease_end_date, cv_date_ymd )         AS  lease_end_date              -- �w�b�_.���[�X�I����
        ,TO_CHAR( xch.first_payment_date, cv_date_ymd )     AS  first_payment_date          -- �w�b�_.����x����
        ,TO_CHAR( xch.second_payment_date, cv_date_ymd )    AS  second_payment_date         -- �w�b�_.2��ڎx����
        ,xch.third_payment_date                             AS  third_payment_date          -- �w�b�_.3��ڈȍ~�x����
        ,xch.start_period_name                              AS  start_period_name           -- �w�b�_.��p�v��J�n��v����
        ,xch.lease_payment_flag                             AS  lease_payment_flag          -- �w�b�_.���[�X�x���v�抮���t���O
-- 2013/07/05 Ver.1.1 K.Nakamura MOD Start
--        ,xch.tax_code                                       AS  tax_code                    -- �w�b�_.�ŋ��R�[�h
        ,DECODE(xcl.tax_code, NULL, xch.tax_code,
                                    xcl.tax_code)           AS  tax_code                    -- ����.�ŋ��R�[�h�ANULL�̏ꍇ�̓w�b�_.�ŋ��R�[�h
-- 2013/07/05 Ver.1.1 K.Nakamura MOD End
        ,xch.created_by                                     AS  h_created_by                -- �w�b�_.�쐬��
        ,TO_CHAR( xch.creation_date, cv_date_ymdhms )       AS  h_creation_date             -- �w�b�_.�쐬��
        ,xch.last_updated_by                                AS  h_last_updated_by           -- �w�b�_.�ŏI�X�V��
        ,TO_CHAR( xch.last_update_date, cv_date_ymdhms )    AS  h_last_update_date          -- �w�b�_.�ŏI�X�V��
        ,xch.last_update_login                              AS  h_last_update_login         -- �w�b�_.�ŏI�X�V���O�C��
        ,xch.request_id                                     AS  h_request_id                -- �w�b�_.�v��ID
        ,xch.program_application_id                         AS  h_program_application_id    -- �w�b�_.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xch.program_id                                     AS  h_program_id                -- �w�b�_.�R���J�����g�E�v���O����ID
        ,TO_CHAR( xch.program_update_date, cv_date_ymdhms ) AS  h_program_update_date       -- �w�b�_.�v���O�����X�V��
        ,xcl.contract_line_id                               AS  contract_line_id            -- ����.�_�񖾍ד���ID
        ,xcl.contract_line_num                              AS  contract_line_num           -- ����.�_��}��
        ,xcl.contract_status                                AS  contract_status             -- ����.�_��X�e�[�^�X
        ,xcl.first_charge                                   AS  first_charge                -- ����.���񌎊z���[�X��_���[�X��
        ,xcl.first_tax_charge                               AS  first_tax_charge            -- ����.�������Ŋz_���[�X��
        ,xcl.first_total_charge                             AS  first_total_charge          -- ����.����v_���[�X��
        ,xcl.second_charge                                  AS  second_charge               -- ����.2��ڈȍ~���z���[�X��_���[�X��
        ,xcl.second_tax_charge                              AS  second_tax_charge           -- ����.2��ڈȍ~����Ŋz_���[�X��
        ,xcl.second_total_charge                            AS  second_total_charge         -- ����.2��ڈȍ~�v_���[�X��
        ,xcl.first_deduction                                AS  first_deduction             -- ����.���񌎊z���[�X��_�T���z
        ,xcl.first_tax_deduction                            AS  first_tax_deduction         -- ����.���񌎊z����Ŋz_�T���z
        ,xcl.first_total_deduction                          AS  first_total_deduction       -- ����.����v_�T���z
        ,xcl.second_deduction                               AS  second_deduction            -- ����.2��ڈȍ~���z���[�X��_�T���z
        ,xcl.second_tax_deduction                           AS  second_tax_deduction        -- ����.2��ڈȍ~����Ŋz_�T���z
        ,xcl.second_total_deduction                         AS  second_total_deduction      -- ����.2��ڈȍ~�v_�T���z
        ,xcl.gross_charge                                   AS  gross_charge                -- ����.���z���[�X��_���[�X��
        ,xcl.gross_tax_charge                               AS  gross_tax_charge            -- ����.���z�����_���[�X��
        ,xcl.gross_total_charge                             AS  gross_total_charge          -- ����.���z�v_���[�X��
        ,xcl.gross_deduction                                AS  gross_deduction             -- ����.���z���[�X��_�T���z
        ,xcl.gross_tax_deduction                            AS  gross_tax_deduction         -- ����.���z�����_�T���z
        ,xcl.gross_total_deduction                          AS  gross_total_deduction       -- ����.���z�v_�T���z
        ,xcl.lease_kind                                     AS  lease_kind                  -- ����.���[�X���
        ,xcl.estimated_cash_price                           AS  estimated_cash_price        -- ����.���ό����w�����z
        ,xcl.present_value_discount_rate                    AS  present_value_discount_rate -- ����.���݉��l������
        ,xcl.present_value                                  AS  present_value               -- ����.���݉��l
        ,xcl.life_in_months                                 AS  life_in_months              -- ����.�@��ϗp�N��
        ,xcl.original_cost                                  AS  original_cost               -- ����.�擾���z
        ,xcl.calc_interested_rate                           AS  calc_interested_rate        -- ����.�v�Z���q��
        ,xcl.object_header_id                               AS  object_header_id            -- ����.��������ID
        ,xcl.asset_category                                 AS  asset_category              -- ����.���Y���
        ,TO_CHAR( xcl.expiration_date, cv_date_ymd)         AS  expiration_date             -- ����.������
        ,TO_CHAR( xcl.cancellation_date, cv_date_ymd)       AS  cancellation_date           -- ����.���r����
        ,TO_CHAR( xcl.vd_if_date, cv_date_ymdhms)           AS  vd_if_date                  -- ����.���[�X�_����A�g��
        ,TO_CHAR( xcl.info_sys_if_date, cv_date_ymdhms)     AS  info_sys_if_date            -- ����.���[�X�Ǘ����A�g��
        ,xcl.first_installation_address                     AS  first_installation_address  -- ����.����ݒu�ꏊ
        ,xcl.first_installation_place                       AS  first_installation_place    -- ����.����ݒu��
        ,xcl.created_by                                     AS  l_created_by                -- ����.�쐬��
        ,TO_CHAR( xcl.creation_date, cv_date_ymdhms )       AS  l_creation_date             -- ����.�쐬��
        ,xcl.last_updated_by                                AS  l_last_updated_by           -- ����.�ŏI�X�V��
        ,TO_CHAR( xcl.last_update_date, cv_date_ymdhms )    AS  l_last_update_date          -- ����.�ŏI�X�V��
        ,xcl.last_update_login                              AS  l_last_update_login         -- ����.�ŏI�X�V���O�C��
        ,xcl.request_id                                     AS  l_request_id                -- ����.�v��ID
        ,xcl.program_application_id                         AS  l_program_application_id    -- ����.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xcl.program_id                                     AS  l_program_id                -- ����.�R���J�����g�E�v���O����ID
        ,TO_CHAR( xcl.program_update_date, cv_date_ymdhms ) AS  l_program_update_date       -- ����.�v���O�����X�V��
      FROM
         xxcff_contract_headers xch        --  ���[�X�_��w�b�_
        ,xxcff_contract_lines   xcl        --  ���[�X�_�񖾍�
        ,xxcff_object_headers   xoh        --  ���[�X����
        ,( -- �e�_�񖈂̍ő�ă��[�X��
           SELECT 
              c_head.contract_number          AS contract_number
             ,c_head.lease_company            AS lease_company
             ,MAX(c_head.re_lease_times)      AS re_lease_times
           FROM
             xxcff_contract_headers   c_head      -- ���[�X�_��w�b�_
           WHERE
             c_head.contract_number = gv_contract_number
           GROUP BY
              c_head.contract_number
             ,c_head.lease_company
         ) c_head_max
      WHERE
          -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
          xch.contract_header_id = xcl.contract_header_id
            -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
      AND xcl.object_header_id = xoh.object_header_id
          --  ���[�X�_��w�b�_.�ă��[�X�񐔂��ő�
      AND xch.contract_number = c_head_max.contract_number
      AND xch.lease_company   = c_head_max.lease_company
      AND xch.re_lease_times  = c_head_max.re_lease_times
          -- ���[�X�_��w�b�_.�_��ԍ� = :�p�����[�^�_��ԍ�
      AND xch.contract_number = gv_contract_number
          -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^���[�X���
      AND ( gv_lease_company IS NULL
          OR
            xch.lease_company = gv_lease_company
          )
          -- �����R�[�h�̎w�肪����ꍇ�́A�����ꂩ�ɍ��v�������
      AND (
            gv_obj_code_param = cv_obj_code_param_off
          OR
            (
              gv_obj_code_param = cv_obj_code_param_on
              AND
              -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
              xoh.object_code in ( gv_object_code_01
                                  ,gv_object_code_02
                                  ,gv_object_code_03
                                  ,gv_object_code_04
                                  ,gv_object_code_05
                                  ,gv_object_code_06
                                  ,gv_object_code_07
                                  ,gv_object_code_08
                                  ,gv_object_code_09
                                  ,gv_object_code_10
                                   )
            )
          )
      ORDER BY
         xch.contract_number
        ,xoh.object_code
      ;
--
    -- �_���� �擾�J�[�\��(�p�����[�^.�_��ԍ��w�薳��)
    CURSOR l_no_contract_rec_cur
    IS
      SELECT
         xch.contract_header_id                             AS  h_contract_header_id        -- �w�b�_.�_�����ID
        ,xch.contract_number                                AS  contract_number             -- �w�b�_.�_��ԍ�
        ,xch.lease_class                                    AS  lease_class                 -- �w�b�_.���[�X���
        ,xch.lease_type                                     AS  lease_type                  -- �w�b�_.���[�X�敪
        ,xch.lease_company                                  AS  lease_company               -- �w�b�_.���[�X���
        ,xch.re_lease_times                                 AS  re_lease_times              -- �w�b�_.�ă��[�X��
        ,xch.comments                                       AS  comments                    -- �w�b�_.����
        ,TO_CHAR( xch.contract_date, cv_date_ymd )          AS  contract_date               -- �w�b�_.���[�X�_���
        ,xch.payment_frequency                              AS  payment_frequency           -- �w�b�_.�x����
        ,xch.payment_type                                   AS  payment_type                -- �w�b�_.�p�x
        ,xch.payment_years                                  AS  payment_years               -- �w�b�_.�N��
        ,TO_CHAR( xch.lease_start_date, cv_date_ymd )       AS  lease_start_date            -- �w�b�_.���[�X�J�n��
        ,TO_CHAR( xch.lease_end_date, cv_date_ymd )         AS  lease_end_date              -- �w�b�_.���[�X�I����
        ,TO_CHAR( xch.first_payment_date, cv_date_ymd )     AS  first_payment_date          -- �w�b�_.����x����
        ,TO_CHAR( xch.second_payment_date, cv_date_ymd )    AS  second_payment_date         -- �w�b�_.2��ڎx����
        ,xch.third_payment_date                             AS  third_payment_date          -- �w�b�_.3��ڈȍ~�x����
        ,xch.start_period_name                              AS  start_period_name           -- �w�b�_.��p�v��J�n��v����
        ,xch.lease_payment_flag                             AS  lease_payment_flag          -- �w�b�_.���[�X�x���v�抮���t���O
-- 2013/07/05 Ver.1.1 K.Nakamura MOD Start
--        ,xch.tax_code                                       AS  tax_code                    -- �w�b�_.�ŋ��R�[�h
        ,DECODE(xcl.tax_code, NULL, xch.tax_code,
                                    xcl.tax_code)           AS  tax_code                    -- ����.�ŋ��R�[�h�ANULL�̏ꍇ�̓w�b�_.�ŋ��R�[�h
-- 2013/07/05 Ver.1.1 K.Nakamura MOD End
        ,xch.created_by                                     AS  h_created_by                -- �w�b�_.�쐬��
        ,TO_CHAR( xch.creation_date, cv_date_ymdhms )       AS  h_creation_date             -- �w�b�_.�쐬��
        ,xch.last_updated_by                                AS  h_last_updated_by           -- �w�b�_.�ŏI�X�V��
        ,TO_CHAR( xch.last_update_date, cv_date_ymdhms )    AS  h_last_update_date          -- �w�b�_.�ŏI�X�V��
        ,xch.last_update_login                              AS  h_last_update_login         -- �w�b�_.�ŏI�X�V���O�C��
        ,xch.request_id                                     AS  h_request_id                -- �w�b�_.�v��ID
        ,xch.program_application_id                         AS  h_program_application_id    -- �w�b�_.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xch.program_id                                     AS  h_program_id                -- �w�b�_.�R���J�����g�E�v���O����ID
        ,TO_CHAR( xch.program_update_date, cv_date_ymdhms ) AS  h_program_update_date       -- �w�b�_.�v���O�����X�V��
        ,xcl.contract_line_id                               AS  contract_line_id            -- ����.�_�񖾍ד���ID
        ,xcl.contract_line_num                              AS  contract_line_num           -- ����.�_��}��
        ,xcl.contract_status                                AS  contract_status             -- ����.�_��X�e�[�^�X
        ,xcl.first_charge                                   AS  first_charge                -- ����.���񌎊z���[�X��_���[�X��
        ,xcl.first_tax_charge                               AS  first_tax_charge            -- ����.�������Ŋz_���[�X��
        ,xcl.first_total_charge                             AS  first_total_charge          -- ����.����v_���[�X��
        ,xcl.second_charge                                  AS  second_charge               -- ����.2��ڈȍ~���z���[�X��_���[�X��
        ,xcl.second_tax_charge                              AS  second_tax_charge           -- ����.2��ڈȍ~����Ŋz_���[�X��
        ,xcl.second_total_charge                            AS  second_total_charge         -- ����.2��ڈȍ~�v_���[�X��
        ,xcl.first_deduction                                AS  first_deduction             -- ����.���񌎊z���[�X��_�T���z
        ,xcl.first_tax_deduction                            AS  first_tax_deduction         -- ����.���񌎊z����Ŋz_�T���z
        ,xcl.first_total_deduction                          AS  first_total_deduction       -- ����.����v_�T���z
        ,xcl.second_deduction                               AS  second_deduction            -- ����.2��ڈȍ~���z���[�X��_�T���z
        ,xcl.second_tax_deduction                           AS  second_tax_deduction        -- ����.2��ڈȍ~����Ŋz_�T���z
        ,xcl.second_total_deduction                         AS  second_total_deduction      -- ����.2��ڈȍ~�v_�T���z
        ,xcl.gross_charge                                   AS  gross_charge                -- ����.���z���[�X��_���[�X��
        ,xcl.gross_tax_charge                               AS  gross_tax_charge            -- ����.���z�����_���[�X��
        ,xcl.gross_total_charge                             AS  gross_total_charge          -- ����.���z�v_���[�X��
        ,xcl.gross_deduction                                AS  gross_deduction             -- ����.���z���[�X��_�T���z
        ,xcl.gross_tax_deduction                            AS  gross_tax_deduction         -- ����.���z�����_�T���z
        ,xcl.gross_total_deduction                          AS  gross_total_deduction       -- ����.���z�v_�T���z
        ,xcl.lease_kind                                     AS  lease_kind                  -- ����.���[�X���
        ,xcl.estimated_cash_price                           AS  estimated_cash_price        -- ����.���ό����w�����z
        ,xcl.present_value_discount_rate                    AS  present_value_discount_rate -- ����.���݉��l������
        ,xcl.present_value                                  AS  present_value               -- ����.���݉��l
        ,xcl.life_in_months                                 AS  life_in_months              -- ����.�@��ϗp�N��
        ,xcl.original_cost                                  AS  original_cost               -- ����.�擾���z
        ,xcl.calc_interested_rate                           AS  calc_interested_rate        -- ����.�v�Z���q��
        ,xcl.object_header_id                               AS  object_header_id            -- ����.��������ID
        ,xcl.asset_category                                 AS  asset_category              -- ����.���Y���
        ,TO_CHAR( xcl.expiration_date, cv_date_ymd)         AS  expiration_date             -- ����.������
        ,TO_CHAR( xcl.cancellation_date, cv_date_ymd)       AS  cancellation_date           -- ����.���r����
        ,TO_CHAR( xcl.vd_if_date, cv_date_ymdhms)           AS  vd_if_date                  -- ����.���[�X�_����A�g��
        ,TO_CHAR( xcl.info_sys_if_date, cv_date_ymdhms)     AS  info_sys_if_date            -- ����.���[�X�Ǘ����A�g��
        ,xcl.first_installation_address                     AS  first_installation_address  -- ����.����ݒu�ꏊ
        ,xcl.first_installation_place                       AS  first_installation_place    -- ����.����ݒu��
        ,xcl.created_by                                     AS  l_created_by                -- ����.�쐬��
        ,TO_CHAR( xcl.creation_date, cv_date_ymdhms )       AS  l_creation_date             -- ����.�쐬��
        ,xcl.last_updated_by                                AS  l_last_updated_by           -- ����.�ŏI�X�V��
        ,TO_CHAR( xcl.last_update_date, cv_date_ymdhms )    AS  l_last_update_date          -- ����.�ŏI�X�V��
        ,xcl.last_update_login                              AS  l_last_update_login         -- ����.�ŏI�X�V���O�C��
        ,xcl.request_id                                     AS  l_request_id                -- ����.�v��ID
        ,xcl.program_application_id                         AS  l_program_application_id    -- ����.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xcl.program_id                                     AS  l_program_id                -- ����.�R���J�����g�E�v���O����ID
        ,TO_CHAR( xcl.program_update_date, cv_date_ymdhms ) AS  l_program_update_date       -- ����.�v���O�����X�V��
      FROM
         xxcff_contract_headers xch        --  ���[�X�_��w�b�_
        ,xxcff_contract_lines   xcl        --  ���[�X�_�񖾍�
        ,xxcff_object_headers   xoh        --  ���[�X����
      WHERE
          -- ���[�X�_��w�b�_.�_�����ID = ���[�X�_�񖾍�.�_�����ID
          xch.contract_header_id = xcl.contract_header_id
          -- ���[�X�_�񖾍�.��������ID = ���[�X����.��������ID
      AND xcl.object_header_id = xoh.object_header_id
      AND xoh.re_lease_times = xch.re_lease_times
          -- ���[�X�_��w�b�_.���[�X��� = :�p�����[�^���[�X���
      AND ( gv_lease_company IS NULL
          OR
            xch.lease_company = gv_lease_company
          )
          -- ���[�X����.�����R�[�h �p�����^1�`10�̂����ꂩ
      AND 
          xoh.object_code IN ( gv_object_code_01
                              ,gv_object_code_02
                              ,gv_object_code_03
                              ,gv_object_code_04
                              ,gv_object_code_05
                              ,gv_object_code_06
                              ,gv_object_code_07
                              ,gv_object_code_08
                              ,gv_object_code_09
                              ,gv_object_code_10
                              )
      ORDER BY
         xch.contract_number
        ,xoh.object_code
      ;
--
    TYPE l_contract_rec_ttype IS TABLE OF l_contract_rec_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_contract_rec_tab l_contract_rec_ttype;
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
    -- ���[�X�_���� ���o����
    -- ===============================================
--
    IF gv_contract_number IS NULL THEN
    -- �_����擾(�p�����[�^.�_��ԍ��w�薳��)�J�[�\��
      OPEN l_no_contract_rec_cur;
      FETCH l_no_contract_rec_cur BULK COLLECT INTO l_contract_rec_tab;
      CLOSE l_no_contract_rec_cur;
    ELSE
    -- �_����擾(�p�����[�^.�_��ԍ��w��L��)�J�[�\��
      OPEN l_contract_rec_cur;
      FETCH l_contract_rec_cur BULK COLLECT INTO l_contract_rec_tab;
      CLOSE l_contract_rec_cur;
    END IF;
--
    --���������J�E���g
    gn_target_cnt := l_contract_rec_tab.COUNT;
--
    -- ���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"���[�X�_��f�[�^"'
    );
    -- ���ږ�
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   =>          cv_enclosed || '�_�����ID'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��ԍ�'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X���'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�敪'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X���'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ă��[�X��'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '����'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�_���'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '�x����'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�p�x'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '�N��'                                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�J�n��'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�I����'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '����x����'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڎx����'                                              || cv_enclosed
         || cv_delimit || cv_enclosed || '3��ڈȍ~�x����'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '��p�v��J�n��v����'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�x���v�抮���t���O'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŋ��R�[�h'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V���O�C��'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�v��ID'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O�����A�v���P�[�V����ID'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O����ID'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�v���O�����X�V��'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�_�񖾍ד���ID'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��}��'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�_��X�e�[�^�X'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '���񌎊z���[�X��_���[�X��'                                || cv_enclosed
         || cv_delimit || cv_enclosed || '�������Ŋz_���[�X��'                                    || cv_enclosed
         || cv_delimit || cv_enclosed || '����v_���[�X��'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~���z���[�X��_���[�X��'                           || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~����Ŋz_���[�X��'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~�v_���[�X��'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���񌎊z���[�X��_�T���z'                                  || cv_enclosed
         || cv_delimit || cv_enclosed || '���񌎊z����Ŋz_�T���z'                                  || cv_enclosed
         || cv_delimit || cv_enclosed || '����v_�T���z'                                            || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~���z���[�X��_�T���z'                             || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~����Ŋz_�T���z'                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '2��ڈȍ~�v_�T���z'                                       || cv_enclosed
         || cv_delimit || cv_enclosed || '���z���[�X��_���[�X��'                                    || cv_enclosed
         || cv_delimit || cv_enclosed || '���z�����_���[�X��'                                      || cv_enclosed
         || cv_delimit || cv_enclosed || '���z�v_���[�X��'                                          || cv_enclosed
         || cv_delimit || cv_enclosed || '���z���[�X��_�T���z'                                      || cv_enclosed
         || cv_delimit || cv_enclosed || '���z�����_�T���z'                                        || cv_enclosed
         || cv_delimit || cv_enclosed || '���z�v_�T���z'                                            || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X���'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���ό����w�����z'                                         || cv_enclosed
         || cv_delimit || cv_enclosed || '���݉��l������'                                           || cv_enclosed
         || cv_delimit || cv_enclosed || '���݉��l'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�@��ϗp�N��'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '�擾���z'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�v�Z���q��'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '��������ID'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���Y���'                                                 || cv_enclosed
         || cv_delimit || cv_enclosed || '������'                                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '���r����'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�_����A�g��'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '���[�X�Ǘ����A�g��'                                     || cv_enclosed
         || cv_delimit || cv_enclosed || '����ݒu�ꏊ'                                             || cv_enclosed
         || cv_delimit || cv_enclosed || '����ݒu��'                                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��(���[�X�_�񖾍�)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�쐬��(���[�X�_�񖾍�)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��(���[�X�_�񖾍�)'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V��(���[�X�_�񖾍�)'                               || cv_enclosed
         || cv_delimit || cv_enclosed || '�ŏI�X�V���O�C��(���[�X�_�񖾍�)'                         || cv_enclosed
         || cv_delimit || cv_enclosed || '�v��ID(���[�X�_�񖾍�)'                                   || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O�����A�v���P�[�V����ID(���[�X�_�񖾍�)' || cv_enclosed
         || cv_delimit || cv_enclosed || '�R���J�����g�v���O����ID(���[�X�_�񖾍�)'                 || cv_enclosed
         || cv_delimit || cv_enclosed || '�v���O�����X�V��(���[�X�_�񖾍�)'                         || cv_enclosed
    );
--
    <<lines_loop>>
    FOR i IN 1 .. l_contract_rec_tab.COUNT LOOP
        -- ���ڒl
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   =>          cv_enclosed || l_contract_rec_tab( i ).h_contract_header_id        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_number             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_class                 || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_type                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_company               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).re_lease_times              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).comments                    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_date               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_frequency           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_type                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).payment_years               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_start_date            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_end_date              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_payment_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_payment_date         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).third_payment_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).start_period_name           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_payment_flag          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).tax_code                    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_created_by                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_creation_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_updated_by           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_update_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_last_update_login         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_request_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_application_id    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).h_program_update_date       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_line_id            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_line_num           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).contract_status             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_charge                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_tax_charge            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_total_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_charge               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_tax_charge           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_total_charge         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_deduction             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_tax_deduction         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_total_deduction       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_deduction            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_tax_deduction        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).second_total_deduction      || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_charge                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_tax_charge            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_total_charge          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_deduction             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_tax_deduction         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).gross_total_deduction       || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).lease_kind                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).estimated_cash_price        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).present_value_discount_rate || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).present_value               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).life_in_months              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).original_cost               || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).calc_interested_rate        || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).object_header_id            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).asset_category              || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).expiration_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).cancellation_date           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).vd_if_date                  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).info_sys_if_date            || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_installation_address  || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).first_installation_place    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_created_by                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_creation_date             || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_updated_by           || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_update_date          || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_last_update_login         || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_request_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_application_id    || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_id                || cv_enclosed
             || cv_delimit || cv_enclosed || l_contract_rec_tab( i ).l_program_update_date       || cv_enclosed
        );
        --���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP lines_loop;
--
  EXCEPTION
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : ���̓p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf           OUT   VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    -- ===============================================
    -- ���[�J����O����
    -- ===============================================
    err_prm_expt             EXCEPTION;
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
    -- ===============================================
    -- �����R�[�h�w��L���t���O�X�V
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
--
    -- ===============================================
    -- ��Ѓ��[�X�E�����R�[�h�`�F�b�N
    -- ===============================================
    -- �p�����[�^.�����R�[�h1�`10���S�Ė��w�� ���A�p�����[�^.���[�X��Ђ����w��
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_lease_company IS NULL ) AND
       ( gv_contract_number IS NOT NULL ) THEN
      lv_errmsg  := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- �_��ԍ��E�����R�[�h�`�F�b�N
    -- ===============================================
    -- �p�����[�^.�����R�[�h1�`10���S�Ė��w�� ���A�p�����[�^.�_��ԍ������w��
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_contract_number IS NULL ) AND
       ( gv_lease_company IS NOT NULL ) THEN
      lv_errmsg  := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
    -- ===============================================
    -- �_��ԍ��E�����R�[�h�`�F�b�N
    -- ===============================================
    -- �p�����[�^�S�Ă����w��
    IF ( gv_obj_code_param = cv_obj_code_param_off ) AND
       ( gv_contract_number IS NULL ) AND
       ( gv_lease_company IS NULL ) THEN
      lv_errmsg  := '�����R�[�h�����w�莞�́A�_��ԍ��ƃ��[�X��Ђ��w�肵�ĉ������B';
      lv_errbuf  := lv_errmsg;
      RAISE err_prm_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���̓p�����[�^��O�n���h�� ***
    WHEN err_prm_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number  IN    VARCHAR2,       --   01.�_��ԍ�
    iv_lease_company    IN    VARCHAR2,       --   02.���[�X���
    iv_object_code_01   IN    VARCHAR2,       --   03.�����R�[�h1
    iv_object_code_02   IN    VARCHAR2,       --   04.�����R�[�h2
    iv_object_code_03   IN    VARCHAR2,       --   05.�����R�[�h3
    iv_object_code_04   IN    VARCHAR2,       --   06.�����R�[�h4
    iv_object_code_05   IN    VARCHAR2,       --   07.�����R�[�h5
    iv_object_code_06   IN    VARCHAR2,       --   08.�����R�[�h6
    iv_object_code_07   IN    VARCHAR2,       --   09.�����R�[�h7
    iv_object_code_08   IN    VARCHAR2,       --   10.�����R�[�h8
    iv_object_code_09   IN    VARCHAR2,       --   11.�����R�[�h9
    iv_object_code_10   IN    VARCHAR2,       --   12.�����R�[�h10
    ov_errbuf           OUT   VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================================
    -- �p�����[�^���O���[�o���ϐ��ɐݒ�
    -- ============================================
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
--
    -- ============================================
    -- �R���J�����g�p�����[�^�o�͏���
    -- ============================================
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
    iv_contract_number  IN    VARCHAR2,       --   01.�_��ԍ�
    iv_lease_company    IN    VARCHAR2,       --   02.���[�X���
    iv_object_code_01   IN    VARCHAR2,       --   03.�����R�[�h1
    iv_object_code_02   IN    VARCHAR2,       --   04.�����R�[�h2
    iv_object_code_03   IN    VARCHAR2,       --   05.�����R�[�h3
    iv_object_code_04   IN    VARCHAR2,       --   06.�����R�[�h4
    iv_object_code_05   IN    VARCHAR2,       --   07.�����R�[�h5
    iv_object_code_06   IN    VARCHAR2,       --   08.�����R�[�h6
    iv_object_code_07   IN    VARCHAR2,       --   09.�����R�[�h7
    iv_object_code_08   IN    VARCHAR2,       --   10.�����R�[�h8
    iv_object_code_09   IN    VARCHAR2,       --   11.�����R�[�h9
    iv_object_code_10   IN    VARCHAR2,       --   12.�����R�[�h10
    ov_errbuf           OUT   VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT   VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT   VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--    cv_delimit              CONSTANT  VARCHAR2(10)  := ',';                           -- ��؂蕶��
--    cv_enclosed             CONSTANT  VARCHAR2(2)   := '"';                           -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
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
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
       iv_contract_number         --   01.�_��ԍ�
      ,iv_lease_company           --   02.���[�X���
      ,iv_object_code_01          --   03.�����R�[�h1
      ,iv_object_code_02          --   04.�����R�[�h2
      ,iv_object_code_03          --   05.�����R�[�h3
      ,iv_object_code_04          --   06.�����R�[�h4
      ,iv_object_code_05          --   07.�����R�[�h5
      ,iv_object_code_06          --   08.�����R�[�h6
      ,iv_object_code_07          --   09.�����R�[�h7
      ,iv_object_code_08          --   10.�����R�[�h8
      ,iv_object_code_09          --   11.�����R�[�h9
      ,iv_object_code_10          --   12.�����R�[�h10
      ,lv_errbuf                  --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                 --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D���̓p�����[�^�`�F�b�N����
    -- ============================================
--
    chk_param(
       lv_errbuf                  --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                 --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�DCSV�o�͂̎��s
    -- ============================================
    out_csv_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
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
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := gn_error_cnt + 1;
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_contract_number         --   01.�_��ԍ�
      ,iv_lease_company           --   02.���[�X���
      ,iv_object_code_01          --   03.�����R�[�h1
      ,iv_object_code_02          --   04.�����R�[�h2
      ,iv_object_code_03          --   05.�����R�[�h3
      ,iv_object_code_04          --   06.�����R�[�h4
      ,iv_object_code_05          --   07.�����R�[�h5
      ,iv_object_code_06          --   08.�����R�[�h6
      ,iv_object_code_07          --   09.�����R�[�h7
      ,iv_object_code_08          --   10.�����R�[�h8
      ,iv_object_code_09          --   11.�����R�[�h9
      ,iv_object_code_10          --   12.�����R�[�h10
      ,lv_errbuf                  --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                 --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCCP008A01C;
/